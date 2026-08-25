//
//  responsive_harness.dart
//  Turing Lab
//
//  Shared harness for the structural responsive gate. It mounts the real
//  production pages inside the real app shell, applies one entry of the
//  canonical viewport matrix deterministically, restores every faked value on
//  teardown, and fails the test on any framework error - RenderFlex overflow,
//  unbounded constraints, hit-test failures or an exception raised after the
//  final pump.
//
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:turing_lab/injection/data_providers.dart';
import 'package:turing_lab/l10n/app_localizations.dart';
import 'package:turing_lab/presentation/pages/home_page.dart';
import 'package:turing_lab/presentation/providers/home_navigation_provider.dart';
import 'package:turing_lab/presentation/providers/workspace_quick_actions_provider.dart';
import 'package:turing_lab/presentation/theme/app_theme.dart';
import 'package:turing_lab/presentation/widgets/workspace_quick_actions_bar.dart';

import '../widget/presentation/examples_test_helpers.dart';
import 'responsive_viewport_matrix.dart';
import 'responsive_workspaces.dart';

/// Key attached to the widget directly below the root `ProviderScope`, used to
/// reach the container without exposing it through a global.
const Key kResponsiveRootKey = ValueKey('responsive-harness-root');

/// Time a responsive surface is given to stop scheduling frames.
const Duration kResponsiveSettleBudget = Duration(seconds: 15);

/// Collects every [FlutterErrorDetails] the framework reports while a
/// responsive test runs.
///
/// `flutter_test` normally records the *first* framework error and fails at the
/// next pump. That hides the rest of the frame and lets errors raised after the
/// last pump slip through, so the harness takes ownership of
/// [FlutterError.onError] and asserts explicitly instead.
class ResponsiveErrorRecorder {
  ResponsiveErrorRecorder._(this._previousOnError);

  final void Function(FlutterErrorDetails details)? _previousOnError;
  final List<FlutterErrorDetails> _errors = <FlutterErrorDetails>[];

  /// Installs the recorder for the duration of the current test.
  factory ResponsiveErrorRecorder.install() {
    final previousOnError = FlutterError.onError;
    final recorder = ResponsiveErrorRecorder._(previousOnError);
    FlutterError.onError = recorder._record;
    addTearDown(() {
      FlutterError.onError = previousOnError;
    });
    // Registered second so it runs first: a test that forgets to assert, or
    // that provokes an error while the tree is torn down, still fails instead
    // of dropping the report on the floor.
    addTearDown(recorder._failOnUncollectedErrors);
    return recorder;
  }

  void _failOnUncollectedErrors() {
    if (_errors.isEmpty) {
      return;
    }
    fail(_describe('the surface tear-down'));
  }

  void _record(FlutterErrorDetails details) {
    // The framework routes the test's own assertion failures through here too;
    // collecting them would report the same failure a second time from the
    // tear-down check below.
    if (details.exception is! TestFailure) {
      _errors.add(details);
      // The assertion message only carries a summary line per error; the full
      // diagnostics, including the creation location of the offending widget,
      // go to the console so a red gate points straight at the source.
      FlutterError.dumpErrorToConsole(details, forceReport: true);
    }
    if (details.library == 'Flutter test framework') {
      // The binding reports uncaught asynchronous errors through
      // FlutterError.onError and then asserts that its own handler saw them.
      // That single class has to be forwarded, otherwise intercepting the
      // handler turns a real async failure into a confusing binding assert.
      _previousOnError?.call(details);
    }
  }

  /// Fails when anything was reported, quoting every error so a single run
  /// surfaces all offending widgets instead of just the first one.
  void assertClean(WidgetTester tester, String context) {
    final leaked = tester.takeException();
    if (leaked != null) {
      _errors.add(
        FlutterErrorDetails(exception: leaked, library: 'flutter_test'),
      );
    }
    if (_errors.isEmpty) {
      return;
    }
    final report = _describe(context);
    _errors.clear();
    fail(report);
  }

  String _describe(String context) {
    final report = StringBuffer(
      '${_errors.length} framework error(s) escaped during $context:',
    );
    for (final details in _errors) {
      report
        ..writeln()
        ..writeln('- ${details.exception}');
      final description = details.context?.toDescription();
      if (description != null && description.isNotEmpty) {
        report.writeln('  context: $description');
      }
    }
    return report.toString();
  }
}

/// A mounted responsive surface plus the handles a test needs to drive it.
class ResponsiveSurface {
  ResponsiveSurface._({
    required this.tester,
    required this.recorder,
    required ResponsiveViewport viewport,
  }) : _viewport = viewport;

  final WidgetTester tester;
  final ResponsiveErrorRecorder recorder;
  ResponsiveViewport _viewport;

  /// The viewport currently applied, which live resizes keep up to date.
  ResponsiveViewport get viewport => _viewport;

  /// The root Riverpod container of the mounted tree.
  ProviderContainer get container => ProviderScope.containerOf(
        tester.element(find.byKey(kResponsiveRootKey)),
        listen: false,
      );

  /// Resizes the live surface without remounting, so the tree has to survive
  /// the transition instead of being rebuilt from scratch.
  Future<void> resizeTo(Size logicalSize, {required String label}) async {
    _viewport = _viewport.resized(logicalSize, name: label);
    tester.view.physicalSize = _viewport.physicalSize;
    await settle();
  }

  /// Pumps until the tree is idle and then keeps pumping briefly, so timers
  /// and post-frame callbacks scheduled by the last frame also run inside the
  /// window the recorder is watching.
  ///
  /// The settle budget is deliberately far below `pumpAndSettle`'s ten-minute
  /// default: a surface that never stops scheduling frames is a responsive
  /// defect, and the gate should report it in seconds rather than stall a
  /// whole matrix sweep on it.
  Future<void> settle() async {
    await tester.pumpAndSettle(
      const Duration(milliseconds: 16),
      EnginePhase.sendSemanticsUpdate,
      kResponsiveSettleBudget,
    );
    await tester.pump(const Duration(milliseconds: 350));
    await tester.pump();
  }

  /// Asserts no framework error escaped, after draining anything the final
  /// pump may still have queued.
  Future<void> assertNoLayoutErrors(String context) async {
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 350));
    recorder.assertClean(tester, context);
  }
}

/// Applies one matrix entry to the test view and registers the restore hooks.
void applyResponsiveViewport(
  WidgetTester tester, {
  required ResponsiveViewport viewport,
  required double textScale,
  required Brightness brightness,
}) {
  final view = tester.view;
  final ratio = viewport.devicePixelRatio;
  view.devicePixelRatio = ratio;
  view.physicalSize = viewport.physicalSize;
  final padding = FakeViewPadding(
    left: viewport.safeArea.left * ratio,
    top: viewport.safeArea.top * ratio,
    right: viewport.safeArea.right * ratio,
    bottom: viewport.safeArea.bottom * ratio,
  );
  view.padding = padding;
  view.viewPadding = padding;
  view.viewInsets = FakeViewPadding.zero;

  final dispatcher = tester.platformDispatcher;
  dispatcher.textScaleFactorTestValue = textScale;
  dispatcher.platformBrightnessTestValue = brightness;

  addTearDown(() {
    view.resetDevicePixelRatio();
    view.resetPhysicalSize();
    view.resetPadding();
    view.resetViewPadding();
    view.resetViewInsets();
    dispatcher.clearTextScaleFactorTestValue();
    dispatcher.clearPlatformBrightnessTestValue();
  });
}

/// Mounts [child] inside the real app shell configured for [viewport].
///
/// The shell mirrors `TuringLabApp`: same themes, same localization delegates.
/// Locale, brightness and platform are injected directly instead of going
/// through the persisted settings so the surface is deterministic.
Future<ResponsiveSurface> pumpResponsiveSurface(
  WidgetTester tester, {
  required ResponsiveViewport viewport,
  required Widget child,
  double textScale = ResponsiveTextScales.standard,
  Locale locale = ResponsiveLocales.english,
  Brightness brightness = Brightness.light,
  List<Override> overrides = const <Override>[],
  FutureOr<void> Function(ProviderContainer container)? prepare,
}) async {
  applyResponsiveViewport(
    tester,
    viewport: viewport,
    textScale: textScale,
    brightness: brightness,
  );

  SharedPreferences.setMockInitialValues(<String, Object>{});
  final preferences = await SharedPreferences.getInstance();

  final recorder = ResponsiveErrorRecorder.install();
  final baseTheme =
      brightness == Brightness.dark ? AppTheme.darkTheme : AppTheme.lightTheme;

  await tester.pumpWidget(
    ProviderScope(
      overrides: <Override>[
        sharedPreferencesProvider.overrideWithValue(preferences),
        examplesRepositoryProvider.overrideWithValue(TestExamplesRepository()),
        ...overrides,
      ],
      child: MaterialApp(
        key: kResponsiveRootKey,
        theme: baseTheme.copyWith(platform: viewport.platform),
        darkTheme: AppTheme.darkTheme.copyWith(platform: viewport.platform),
        themeMode:
            brightness == Brightness.dark ? ThemeMode.dark : ThemeMode.light,
        locale: locale,
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        debugShowCheckedModeBanner: false,
        home: _paneWrap(child, viewport.paneWidth),
      ),
    ),
  );

  final surface = ResponsiveSurface._(
    tester: tester,
    recorder: recorder,
    viewport: viewport,
  );
  await surface.settle();

  if (prepare != null) {
    await prepare(surface.container);
    await surface.settle();
  }

  return surface;
}

/// Mounts the real home shell - app bar, quick actions, navigation and the
/// workspace `PageView` - on [viewport] and selects [workspaceIndex].
Future<ResponsiveSurface> pumpResponsiveHome(
  WidgetTester tester, {
  required ResponsiveViewport viewport,
  int workspaceIndex = HomeNavigationNotifier.fsaIndex,
  double textScale = ResponsiveTextScales.standard,
  Locale locale = ResponsiveLocales.english,
  Brightness brightness = Brightness.light,
  List<Override> overrides = const <Override>[],
  FutureOr<void> Function(ProviderContainer container)? prepare,
}) async {
  return pumpResponsiveSurface(
    tester,
    viewport: viewport,
    child: const HomePage(),
    textScale: textScale,
    locale: locale,
    brightness: brightness,
    overrides: overrides,
    prepare: (container) async {
      container.read(homeNavigationProvider.notifier).setIndex(workspaceIndex);
      if (prepare != null) {
        await prepare(container);
      }
    },
  );
}

/// Mounts a single workspace page inside the production app-bar composition the
/// home shell uses on compact layouts.
///
/// This is how an embedded workspace is reached in the app, and it is the only
/// way to give the page a pane narrower than the window while still driving the
/// real `WorkspaceQuickActionsBar`.
Future<ResponsiveSurface> pumpResponsiveWorkspacePane(
  WidgetTester tester, {
  required ResponsiveViewport viewport,
  required Widget page,
  required WorkspaceTab tab,
  double textScale = ResponsiveTextScales.standard,
  Locale locale = ResponsiveLocales.english,
  Brightness brightness = Brightness.light,
  List<Override> overrides = const <Override>[],
  FutureOr<void> Function(ProviderContainer container)? prepare,
}) {
  return pumpResponsiveSurface(
    tester,
    viewport: viewport,
    textScale: textScale,
    locale: locale,
    brightness: brightness,
    overrides: overrides,
    prepare: prepare,
    child: Scaffold(
      appBar: AppBar(
        leading: WorkspaceQuickActionsBar(tab: tab),
        leadingWidth: 144,
        title: Text(tab.name),
      ),
      body: page,
    ),
  );
}

/// Mounts [workspace] the way [viewport] describes it.
///
/// Window-sized viewports go through the real home shell so navigation, app bar
/// and the workspace `PageView` are the production ones. Pane viewports mount
/// the workspace page directly, because a pane narrower than the window is only
/// reachable by embedding the page.
Future<ResponsiveSurface> pumpResponsiveWorkspace(
  WidgetTester tester, {
  required ResponsiveViewport viewport,
  required ResponsiveWorkspace workspace,
  double textScale = ResponsiveTextScales.standard,
  Locale locale = ResponsiveLocales.english,
  Brightness brightness = Brightness.light,
  List<Override> overrides = const <Override>[],
  FutureOr<void> Function(ProviderContainer container)? prepare,
}) {
  switch (viewport.mount) {
    case ResponsiveMount.window:
      return pumpResponsiveHome(
        tester,
        viewport: viewport,
        workspaceIndex: workspace.navigationIndex,
        textScale: textScale,
        locale: locale,
        brightness: brightness,
        overrides: overrides,
        prepare: prepare,
      );
    case ResponsiveMount.pane:
      return pumpResponsiveWorkspacePane(
        tester,
        viewport: viewport,
        page: workspace.page,
        tab: workspace.tab,
        textScale: textScale,
        locale: locale,
        brightness: brightness,
        overrides: overrides,
        prepare: prepare,
      );
  }
}

Widget _paneWrap(Widget child, double? paneWidth) {
  if (paneWidth == null) {
    return child;
  }
  return Align(
    alignment: Alignment.topLeft,
    child: SizedBox(width: paneWidth, child: child),
  );
}

/// Asserts [finder] resolves to something the user can actually reach: it is in
/// the tree, painted inside the viewport and hit-testable at its centre.
void expectReachable(
  WidgetTester tester,
  Finder finder, {
  required String description,
}) {
  expect(
    finder,
    findsWidgets,
    reason: '$description should be mounted on ${tester.view.physicalSize}',
  );
  expect(
    finder.hitTestable(),
    findsWidgets,
    reason: '$description should be hit-testable, not covered or clipped away',
  );
}

/// Sub-pixel slack allowed when comparing laid-out geometry.
const double _pixelTolerance = 0.5;

/// Asserts an interactive control still honours the documented touch target.
void expectTouchTarget(
  WidgetTester tester,
  Finder finder, {
  required String description,
  double minimum = kResponsiveMinTouchTarget,
}) {
  final size = tester.getSize(finder.first);
  expect(
    size.shortestSide,
    greaterThanOrEqualTo(minimum - _pixelTolerance),
    reason: '$description shrank below the ${minimum}px touch target: $size',
  );
}

/// Asserts every painted box of [finder] stays within the window horizontally.
void expectWithinViewport(
  WidgetTester tester,
  Finder finder, {
  required String description,
}) {
  final view = tester.view;
  final windowWidth = view.physicalSize.width / view.devicePixelRatio;
  final matches = finder.evaluate().length;
  for (var index = 0; index < matches; index++) {
    final rect = tester.getRect(finder.at(index));
    expect(
      rect.left,
      greaterThanOrEqualTo(-_pixelTolerance),
      reason: '$description is clipped past the left edge: $rect',
    );
    expect(
      rect.right,
      lessThanOrEqualTo(windowWidth + _pixelTolerance),
      reason: '$description is clipped past the right edge: $rect',
    );
  }
}
