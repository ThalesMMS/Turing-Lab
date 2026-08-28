//
//  apple_release_harness.dart
//  Turing Lab
//
//  Single harness shared by every Apple release smoke suite. It owns locale,
//  theme, target platform, viewport, safe area, dependency and preference
//  fixtures, exposes bounded waits for explicit conditions, and resets every
//  piece of global test state exactly once on the success and the failure
//  path.
//

import 'dart:collection';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:turing_lab/app.dart';
import 'package:turing_lab/core/repositories/examples_repository.dart';
import 'package:turing_lab/injection/data_providers.dart';
import 'package:turing_lab/injection/dependency_injection.dart';
import 'package:turing_lab/l10n/app_localizations.dart';
import 'package:turing_lab/presentation/providers/workspace_quick_actions_provider.dart';
import 'package:turing_lab/presentation/widgets/workspace_selector.dart';
import 'package:turing_lab/presentation/widgets/workspace_dock.dart';

import 'apple_release_module.dart';
import 'apple_release_shell.dart';
import 'apple_release_target.dart';
import 'apple_release_test_level.dart';

/// Drives the Turing Lab app for the Apple release smoke levels.
///
/// Use [run] rather than constructing the harness directly: it guarantees the
/// teardown runs inside the test body, which is where the Flutter test
/// framework still allows global debug state to be restored.
class AppleReleaseHarness {
  AppleReleaseHarness._(
    this._tester, {
    required this.target,
    required this.level,
    required bool overrideViewport,
  }) : _overrideViewport = overrideViewport;

  /// Upper bound applied to every wait that does not override it.
  static const Duration defaultTimeout = Duration(seconds: 10);

  /// Increment used while polling a pending condition under the headless
  /// runner, where time is faked and a pump is nearly free.
  static const Duration _fakeClockPollInterval = Duration(milliseconds: 32);

  /// Increment used while polling on a live binding, where every pump waits
  /// for a real frame and a 32ms poll would spend minutes on a single wait.
  static const Duration _livePollInterval = Duration(milliseconds: 250);

  /// Longest quiesce window allowed after a test body completes.
  static const Duration _quiesceTimeout = Duration(seconds: 2);

  /// Minimum quiesce window, long enough to flush the workspace autosave
  /// debounce so no timer survives the test body.
  static const Duration _quiesceMinimum = Duration(milliseconds: 480);

  static const int _logCapacity = 240;

  /// Canvas chatter is captured for diagnostics but kept off the console; it
  /// is high volume and would bury the framework's own failure output.
  static const List<String> _mutedLogPrefixes = <String>['[GraphView'];

  /// Every persisted setting is pinned so a default change in
  /// `SettingsModel` cannot silently alter what the smoke suites render.
  static const Map<String, Object> _pinnedPreferences = <String, Object>{
    'settings_theme_mode': 'light',
    'settings_locale_code': 'en',
    'settings_show_grid': true,
    'settings_show_coordinates': false,
    'settings_auto_save': true,
    'settings_show_tooltips': true,
    'settings_grid_size': 20.0,
    'settings_node_size': 30.0,
    'settings_font_size': 14.0,
    'settings_animation_speed': 1.0,
  };

  /// The form factor this run installs and asserts against.
  final AppleReleaseTarget target;

  /// The validation level the calling suite belongs to.
  final AppleReleaseTestLevel level;

  final WidgetTester _tester;
  final bool _overrideViewport;
  final Queue<String> _log = Queue<String>();

  ProviderContainer? _container;
  SemanticsHandle? _semanticsHandle;
  DebugPrintCallback? _originalDebugPrint;
  String _activeLocaleCode = 'en';
  String? _lastConditionError;
  bool _resetCompleted = false;

  /// Launches the app for [target], runs [body], and resets all global state.
  ///
  /// The reset happens in a `finally` inside the test body rather than in
  /// `addTearDown` because the framework verifies foundation debug variables
  /// (including `debugPrint`) before tear-down callbacks run.
  static Future<void> run(
    WidgetTester tester, {
    required AppleReleaseTarget target,
    required AppleReleaseTestLevel level,
    required Future<void> Function(AppleReleaseHarness harness) body,
    Map<String, Object> preferences = const <String, Object>{},
    ExamplesRepository? examplesRepository,
    bool overrideViewport = true,
    bool enableSemantics = false,
  }) async {
    if (!level.runsUnderFlutterTest &&
        tester.binding is AutomatedTestWidgetsFlutterBinding) {
      throw StateError(
        '${level.id} ${level.title} must not run under the headless Flutter '
        'test runner, because its prerequisites cannot be satisfied there. '
        'Run it with:\n  ${level.command}',
      );
    }

    final harness = AppleReleaseHarness._(
      tester,
      target: target,
      level: level,
      overrideViewport: overrideViewport,
    );
    try {
      await harness._launch(
        preferences: preferences,
        examplesRepository: examplesRepository,
        enableSemantics: enableSemantics,
      );
      await body(harness);
      await harness._quiesce();
      harness.expectNoUntrackedException('completing the ${level.id} case');
    } finally {
      await harness._reset();
    }
  }

  /// Localizations for the locale the app is currently expected to render.
  AppLocalizations get localizations => localizationsFor(_activeLocaleCode);

  /// Provider container owned by the current run.
  ProviderContainer get container {
    final container = _container;
    if (container == null) {
      throw StateError('The Apple release harness is not running.');
    }
    return container;
  }

  /// Localizations for an explicit locale code.
  AppLocalizations localizationsFor(String localeCode) =>
      lookupAppLocalizations(Locale(localeCode));

  /// Logical size currently reported to the app.
  Size get logicalSize {
    final view = _tester.view;
    return view.physicalSize / view.devicePixelRatio;
  }

  /// Shell `HomePage` renders at the live viewport width.
  AppleReleaseShell get shell => AppleReleaseShell.forWidth(logicalSize.width);

  /// Finder for the navigation shell that must be mounted for [shell].
  Finder get shellFinder => find.byType(WorkspaceSelector);

  /// Finder for [text] rendered inside an `AppBar`.
  Finder appBarText(String text) =>
      find.descendant(of: find.byType(AppBar), matching: find.text(text));

  /// Finder for the `AppBar` action carrying [icon].
  Finder appBarAction(IconData icon) => find.descendant(
    of: find.byType(AppBar),
    matching: find.widgetWithIcon(IconButton, icon),
  );

  // ---------------------------------------------------------------------
  // Bounded waits
  // ---------------------------------------------------------------------

  /// Pumps until [condition] holds, failing with diagnostics after [timeout].
  ///
  /// [description] must name the condition being waited on; it is quoted back
  /// in the failure message.
  Future<void> waitUntil(
    bool Function() condition, {
    required String description,
    Duration timeout = defaultTimeout,
  }) async {
    _lastConditionError = null;
    await _tester.pump();
    if (_evaluate(condition)) {
      return;
    }

    final interval = _pollInterval;
    final steps = (timeout.inMicroseconds / interval.inMicroseconds).ceil();
    for (var step = 0; step < steps; step++) {
      await _tester.pump(interval);
      if (_evaluate(condition)) {
        return;
      }
    }

    throw TestFailure(
      _diagnostics(
        'Timed out after ${timeout.inMilliseconds}ms waiting for '
        '$description.',
        pending: description,
        takePendingException: true,
      ),
    );
  }

  /// Pumps until [condition] holds while allowing isolate-backed work to run.
  ///
  /// `compute` and platform-adjacent futures cannot finish while a headless
  /// widget test advances only its fake clock. Each poll therefore yields a
  /// short, bounded slice of real time before pumping the resulting frame.
  Future<void> waitUntilAsync(
    bool Function() condition, {
    required String description,
    Duration timeout = defaultTimeout,
  }) async {
    _lastConditionError = null;
    const interval = Duration(milliseconds: 20);
    final steps = (timeout.inMicroseconds / interval.inMicroseconds).ceil();
    for (var step = 0; step <= steps; step++) {
      await _tester.pump();
      if (_evaluate(condition)) {
        return;
      }
      if (step == steps) {
        break;
      }
      await _tester.runAsync(() => Future<void>.delayed(interval));
    }

    throw TestFailure(
      _diagnostics(
        'Timed out after ${timeout.inMilliseconds}ms waiting for '
        '$description.',
        pending: description,
        takePendingException: true,
      ),
    );
  }

  /// Waits until [finder] matches at least one widget.
  Future<void> waitFor(
    Finder finder, {
    required String description,
    Duration timeout = defaultTimeout,
  }) {
    return waitUntil(
      () => finder.evaluate().isNotEmpty,
      description: description,
      timeout: timeout,
    );
  }

  /// Waits until [finder] matches no widget.
  Future<void> waitUntilGone(
    Finder finder, {
    required String description,
    Duration timeout = defaultTimeout,
  }) {
    return waitUntil(
      () => finder.evaluate().isEmpty,
      description: description,
      timeout: timeout,
    );
  }

  /// Waits until the frame scheduler is idle.
  ///
  /// This is the bounded replacement for a bare `pumpAndSettle`: it cannot
  /// block indefinitely on a continuously running animation, and it names what
  /// it was waiting for when it gives up.
  Future<void> waitUntilIdle({
    required String description,
    Duration timeout = defaultTimeout,
  }) {
    return waitUntil(
      () => !_tester.binding.hasScheduledFrame,
      description: 'the frame scheduler to go idle after $description',
      timeout: timeout,
    );
  }

  // ---------------------------------------------------------------------
  // Interactions
  // ---------------------------------------------------------------------

  /// Taps [finder] once it is mounted, scrolling it into view when possible.
  Future<void> tap(
    Finder finder, {
    required String description,
    Duration timeout = defaultTimeout,
  }) async {
    await waitFor(
      finder,
      description: 'the tap target for $description',
      timeout: timeout,
    );
    await waitUntilIdle(
      description: 'the pending route or animation before tapping $description',
      timeout: timeout,
    );
    await _scrollIntoView(finder);
    await _tester.tap(finder);
    await _tester.pump();
  }

  /// Taps [target] and waits for [expected] to appear.
  Future<void> tapAndWaitFor(
    Finder target,
    Finder expected, {
    required String description,
    Duration timeout = defaultTimeout,
  }) async {
    await tap(target, description: description, timeout: timeout);
    await waitFor(expected, description: description, timeout: timeout);
    await waitUntilIdle(description: description, timeout: timeout);
  }

  /// Enters [text] in [finder] after waiting for the editable control.
  Future<void> enterText(
    Finder finder,
    String text, {
    required String description,
    Duration timeout = defaultTimeout,
  }) async {
    await waitFor(finder, description: description, timeout: timeout);
    await _scrollIntoView(finder);
    await _tester.enterText(finder, text);
    await _tester.pump();
  }

  /// Opens a workspace panel through the mobile action or wide-screen dock.
  Future<void> openWorkspacePanel({
    required WorkspaceTab workspaceTab,
    required String panelId,
    required String mobileTooltip,
    required Finder panel,
    required String description,
  }) async {
    if (panel.evaluate().isNotEmpty) {
      return;
    }
    final mobileAction = find.descendant(
      of: find.byType(AppBar),
      matching: find.byTooltip(mobileTooltip),
    );
    if (mobileAction.evaluate().isNotEmpty) {
      await tapAndWaitFor(mobileAction.first, panel, description: description);
      return;
    }

    // Wide layouts host panels in the dock. The published quick-action
    // callback opens the mobile bottom sheet, so use the visible dock control.
    await tapAndWaitFor(
      find.byKey(WorkspaceDock.railButtonKey(panelId)).hitTestable(),
      panel,
      description: description,
    );
  }

  /// Closes a workspace panel regardless of its mobile or wide presentation.
  Future<void> closeWorkspacePanel({
    required String panelId,
    required Finder panel,
    required String description,
  }) async {
    if (panel.evaluate().isEmpty) {
      return;
    }
    final sheet = find.byType(BottomSheet);
    if (sheet.evaluate().isNotEmpty) {
      Navigator.of(_tester.element(sheet.first)).pop();
    } else {
      await tap(
        find.byKey(WorkspaceDock.railButtonKey(panelId)).hitTestable(),
        description: description,
      );
    }
    await waitUntilGone(panel, description: description);
    await waitUntilIdle(description: description);
  }

  /// Dismisses the route containing [routeContent].
  Future<void> dismissRoute(
    Finder routeContent, {
    required String description,
  }) async {
    await waitFor(routeContent, description: description);
    Navigator.of(_tester.element(routeContent.first)).pop();
    await waitUntilGone(routeContent, description: description);
    await waitUntilIdle(description: description);
  }

  /// Scrolls [finder] into view when it sits inside a scrollable.
  ///
  /// Targets outside a scrollable are left alone instead of failing, so the
  /// same call site works for the workspace menu and for the settings list.
  Future<void> _scrollIntoView(Finder finder) async {
    if (finder.hitTestable().evaluate().isNotEmpty) {
      return;
    }
    final elements = finder.evaluate();
    if (elements.length != 1) {
      return;
    }
    final renderObject = elements.single.findRenderObject();
    if (renderObject == null) {
      return;
    }
    var scrollable = Scrollable.maybeOf(elements.single);
    while (scrollable != null) {
      if (scrollable.position.axis == Axis.vertical) {
        await scrollable.position.ensureVisible(renderObject);
      }
      scrollable = Scrollable.maybeOf(scrollable.context);
    }
    await _tester.pump();
  }

  /// Opens [module] through the shell's navigation and waits for its heading.
  Future<void> openModule(AppleReleaseModule module) async {
    final l10n = localizations;
    final label = module.label(l10n);
    final description = module.description(l10n);
    await tap(
      find
          .descendant(
            of: find.byType(WorkspaceSelector),
            matching: find.byIcon(Icons.arrow_drop_down),
          )
          .first,
      description: 'the workspace selector',
    );
    final menuItem = find
        .ancestor(of: find.text(label), matching: find.byType(MenuItemButton))
        .first;
    await waitFor(menuItem, description: 'the $label workspace menu item');
    final menuItemContext = _tester.element(menuItem);
    MenuController.maybeOf(menuItemContext)?.close();
    _tester.widget<MenuItemButton>(menuItem).onPressed?.call();
    await _tester.pump();
    await waitFor(
      shell == AppleReleaseShell.mobile
          ? appBarText(label)
          : appBarText(description),
      description: 'the app bar heading for $label',
    );
    await waitUntilIdle(description: 'opening the $label workspace');
  }

  /// Opens the settings page from the workspace app bar.
  Future<void> openSettings() async {
    await tapAndWaitFor(
      appBarAction(Icons.settings),
      find.byKey(const ValueKey('settings_save_button')),
      description: 'the settings page',
    );
  }

  /// Opens the help catalog from the workspace app bar.
  Future<void> openHelp() async {
    await tapAndWaitFor(
      appBarAction(Icons.help_outline),
      appBarText(localizations.helpPageTitle),
      description: 'the help page',
    );
  }

  /// Selects [localeCode] on the settings page and waits for the new copy.
  Future<void> selectLocale(String localeCode) async {
    final chipKey = ValueKey<String>('settings_language_$localeCode');
    await tap(
      find.byKey(chipKey),
      description: 'the "$localeCode" language chip',
    );
    _activeLocaleCode = localeCode;
    await waitFor(
      appBarText(localizations.settingsPageTitle),
      description: 'the settings title translated into "$localeCode"',
    );
    await waitUntilIdle(description: 'switching the locale to "$localeCode"');
  }

  /// Pops the current route and waits for [expected] to be visible again.
  Future<void> back({
    required Finder expected,
    required String description,
  }) async {
    await _tester.pageBack();
    await waitFor(expected, description: 'returning to $description');
    await waitUntilIdle(description: 'returning to $description');
  }

  /// Brightness currently applied to the workspace shell.
  Brightness get shellBrightness {
    final element = shellFinder.evaluate().first;
    return Theme.of(element).brightness;
  }

  // ---------------------------------------------------------------------
  // Diagnostics
  // ---------------------------------------------------------------------

  /// Builds a report describing where the app currently is.
  ///
  /// Safe to call from a passing path: it never consumes a pending framework
  /// exception, so it cannot hide one from the end-of-test check.
  String describeState({String? pending}) =>
      _diagnostics(null, pending: pending);

  /// Fails when the framework reported an untracked exception during
  /// [context].
  ///
  /// Taking the exception here instead of letting it surface at the end of the
  /// test keeps the report attached to the step that produced it.
  void expectNoUntrackedException(String context) {
    final exception = _tester.takeException();
    if (exception == null) {
      return;
    }
    throw TestFailure(
      _diagnostics(
        'The framework reported an exception while $context.',
        pending: context,
        exception: exception,
      ),
    );
  }

  // ---------------------------------------------------------------------
  // Lifecycle
  // ---------------------------------------------------------------------

  Future<void> _launch({
    required Map<String, Object> preferences,
    required ExamplesRepository? examplesRepository,
    required bool enableSemantics,
  }) async {
    _installLogCapture();
    await resetDependencies();
    SharedPreferences.setMockInitialValues(<String, Object>{
      ..._pinnedPreferences,
      ...preferences,
    });
    final prefs = await initializeSharedPreferences();
    _activeLocaleCode =
        (preferences['settings_locale_code'] as String?) ?? 'en';

    _tester.platformDispatcher
      ..localeTestValue = Locale(_activeLocaleCode)
      ..localesTestValue = <Locale>[Locale(_activeLocaleCode)]
      ..platformBrightnessTestValue = Brightness.light;

    if (_overrideViewport) {
      _tester.view
        ..devicePixelRatio = target.devicePixelRatio
        ..physicalSize = target.physicalSize
        ..viewInsets = FakeViewPadding.zero
        ..padding = FakeViewPadding(
          left: target.safeArea.left * target.devicePixelRatio,
          top: target.safeArea.top * target.devicePixelRatio,
          right: target.safeArea.right * target.devicePixelRatio,
          bottom: target.safeArea.bottom * target.devicePixelRatio,
        );
    }

    if (enableSemantics) {
      _semanticsHandle = _tester.ensureSemantics();
    }

    final container = ProviderContainer(
      overrides: <Override>[
        sharedPreferencesProvider.overrideWithValue(prefs),
        if (examplesRepository != null)
          examplesRepositoryProvider.overrideWithValue(examplesRepository),
      ],
    );
    _container = container;

    await _tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: const TuringLabApp(),
      ),
    );

    await waitFor(
      shellFinder,
      description: 'the ${shell.name} navigation shell on ${target.label}',
    );
    await waitFor(
      shell == AppleReleaseShell.mobile
          ? appBarText(AppleReleaseModule.fsa.label(localizations))
          : appBarText(AppleReleaseModule.fsa.description(localizations)),
      description: 'the first-launch FSA workspace heading',
    );
    await waitUntilIdle(description: 'the first launch of ${target.label}');
  }

  Future<void> _quiesce() async {
    final interval = _pollInterval;
    var elapsed = Duration.zero;
    while (elapsed < _quiesceTimeout) {
      await _tester.pump(interval);
      elapsed += interval;
      if (elapsed >= _quiesceMinimum && !_tester.binding.hasScheduledFrame) {
        return;
      }
    }
  }

  Duration get _pollInterval =>
      _tester.binding is AutomatedTestWidgetsFlutterBinding
      ? _fakeClockPollInterval
      : _livePollInterval;

  Future<void> _reset() async {
    if (_resetCompleted) {
      return;
    }
    _resetCompleted = true;

    _semanticsHandle?.dispose();
    _semanticsHandle = null;

    // Unmount before disposing the uncontrolled container. Pumping another
    // `TuringLabApp` with the same type and key can otherwise reuse the route
    // and workspace state from the previous parameterized case.
    await _tester.pumpWidget(const SizedBox.shrink());
    await _tester.pump();

    // The scope is uncontrolled, so nothing else disposes this container.
    _container?.dispose();
    _container = null;

    // Only the view this harness actually overrode is reset, so a run against
    // a real device viewport is left exactly as it was found.
    if (_overrideViewport) {
      _tester.view.reset();
    }
    _tester.platformDispatcher.clearAllTestValues();

    _restoreLogCapture();
    await resetDependencies();
  }

  // ---------------------------------------------------------------------
  // Internals
  // ---------------------------------------------------------------------

  bool _evaluate(bool Function() condition) {
    try {
      return condition();
    } catch (error) {
      _lastConditionError = error.toString();
      return false;
    }
  }

  void _installLogCapture() {
    if (_originalDebugPrint != null) {
      return;
    }
    final original = debugPrint;
    _originalDebugPrint = original;
    debugPrint = (String? message, {int? wrapWidth}) {
      _recordLog(message);
      if (!_isMuted(message)) {
        original(message, wrapWidth: wrapWidth);
      }
    };
  }

  void _restoreLogCapture() {
    final original = _originalDebugPrint;
    if (original == null) {
      return;
    }
    debugPrint = original;
    _originalDebugPrint = null;
  }

  void _recordLog(String? message) {
    if (message == null) {
      return;
    }
    _log.addLast(message);
    while (_log.length > _logCapacity) {
      _log.removeFirst();
    }
  }

  static bool _isMuted(String? message) {
    if (message == null) {
      return false;
    }
    return _mutedLogPrefixes.any(message.startsWith);
  }

  String _diagnostics(
    String? headline, {
    String? pending,
    Object? exception,
    bool takePendingException = false,
  }) {
    final buffer = StringBuffer();
    if (headline != null) {
      buffer.writeln(headline);
    }
    buffer.writeln('Apple release harness state:');
    buffer.writeln('  level: ${level.id} ${level.title}');
    buffer.writeln('  command: ${level.command}');
    buffer.writeln('  target: $target');
    buffer.writeln('  locale: $_activeLocaleCode');
    buffer.writeln(
      '  viewport: ${logicalSize.width.toStringAsFixed(0)}x'
      '${logicalSize.height.toStringAsFixed(0)} logical, '
      'shell: ${shell.name}',
    );
    if (pending != null) {
      buffer.writeln('  pending condition: $pending');
    }
    if (_lastConditionError != null) {
      buffer.writeln('  condition raised: $_lastConditionError');
    }
    buffer.writeln('  mounted shell: ${_describeShell()}');
    buffer.writeln('  app bar text: ${_describeAppBarText()}');
    buffer.writeln('  top route: ${_describeTopRoute()}');
    buffer.writeln('  open overlays: ${_describeOverlays()}');
    final pendingException =
        exception ?? (takePendingException ? _tester.takeException() : null);
    buffer.writeln(
      '  pending exception: ${_describeException(pendingException)}',
    );
    buffer.writeln('  recent app log:');
    final tail = _log.length <= 20 ? _log : _log.skip(_log.length - 20);
    if (tail.isEmpty) {
      buffer.writeln('    <empty>');
    } else {
      for (final line in tail) {
        buffer.writeln('    $line');
      }
    }
    return buffer.toString();
  }

  String _describeShell() {
    final selectors = find.byType(WorkspaceSelector).evaluate();
    if (selectors.isEmpty) {
      return 'none mounted';
    }
    final compact = selectors
        .where((element) => (element.widget as WorkspaceSelector).compact)
        .length;
    return 'WorkspaceSelector x${selectors.length} (compact x$compact)';
  }

  String _describeAppBarText() {
    try {
      final texts = find
          .descendant(of: find.byType(AppBar), matching: find.byType(Text))
          .evaluate()
          .map((element) => (element.widget as Text).data)
          .whereType<String>()
          .toList();
      return texts.isEmpty ? '<none>' : texts.join(' | ');
    } catch (error) {
      return 'unavailable ($error)';
    }
  }

  String _describeTopRoute() {
    try {
      final scaffolds = find.byType(Scaffold).evaluate().toList();
      if (scaffolds.isEmpty) {
        return 'unknown (no Scaffold mounted)';
      }
      final route = ModalRoute.of(scaffolds.last);
      if (route == null) {
        return 'unknown (no ModalRoute above the last Scaffold)';
      }
      final name = route.settings.name ?? '<unnamed>';
      return '${route.runtimeType} (name: $name, isCurrent: ${route.isCurrent})';
    } catch (error) {
      return 'unavailable ($error)';
    }
  }

  String _describeOverlays() {
    final dialogs = find.byType(Dialog).evaluate().length;
    final sheets = find.byType(BottomSheet).evaluate().length;
    final snackBars = find.byType(SnackBar).evaluate().length;
    return 'dialogs: $dialogs, bottom sheets: $sheets, snack bars: $snackBars';
  }

  String _describeException(Object? exception) {
    return exception == null ? 'none or not inspected' : exception.toString();
  }
}
