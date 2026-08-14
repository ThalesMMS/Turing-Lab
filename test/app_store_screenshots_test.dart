import 'dart:io';
import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:turing_lab/app.dart';
import 'package:turing_lab/core/models/fsa.dart';
import 'package:turing_lab/core/models/fsa_transition.dart';
import 'package:turing_lab/core/models/grammar.dart';
import 'package:turing_lab/core/models/state.dart' as automaton_state;
import 'package:turing_lab/data/data_sources/examples_asset_data_source.dart';
import 'package:turing_lab/injection/dependency_injection.dart';
import 'package:turing_lab/presentation/providers/automaton_simulation_provider.dart';
import 'package:turing_lab/presentation/providers/automaton_state_provider.dart';
import 'package:turing_lab/presentation/providers/grammar_provider.dart';
import 'package:turing_lab/presentation/providers/home_navigation_provider.dart';
import 'package:turing_lab/presentation/providers/pda_editor_provider.dart';
import 'package:turing_lab/presentation/providers/tm_editor_provider.dart';
import 'package:turing_lab/presentation/providers/unified_trace_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:vector_math/vector_math_64.dart';

const _outputRoot = 'screenshots/app_store';

final _profiles = <_ScreenshotProfile>[
  const _ScreenshotProfile(
    outputDir: 'iphone-6.9',
    physicalSize: Size(1320, 2868),
    devicePixelRatio: 3.0,
  ),
  const _ScreenshotProfile(
    outputDir: 'iphone-6.5',
    physicalSize: Size(1284, 2778),
    devicePixelRatio: 3.0,
  ),
  const _ScreenshotProfile(
    outputDir: 'iphone-5.5',
    physicalSize: Size(1242, 2208),
    devicePixelRatio: 3.0,
  ),
  const _ScreenshotProfile(
    outputDir: 'ipad-13',
    physicalSize: Size(2048, 2732),
    devicePixelRatio: 2.0,
  ),
  const _ScreenshotProfile(
    outputDir: 'macos',
    physicalSize: Size(2880, 1800),
    devicePixelRatio: 2.2,
  ),
];

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('field entry helper', () {
    testWidgets('rejects generic TextField fallback for non input labels', (
      tester,
    ) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: Column(
              children: [
                TextField(),
                TextField(),
              ],
            ),
          ),
        ),
      );

      expect(
        _enterField(tester, 'Regex Pattern', 'ab*'),
        throwsA(isA<TestFailure>()),
      );
    });

    testWidgets('keeps legacy Input String TextField fallback', (
      tester,
    ) async {
      final firstController = TextEditingController();
      final secondController = TextEditingController();
      addTearDown(firstController.dispose);
      addTearDown(secondController.dispose);

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Column(
              children: [
                TextField(controller: firstController),
                TextField(controller: secondController),
              ],
            ),
          ),
        ),
      );

      await _enterField(tester, 'Input String', 'ba');

      expect(firstController.text, isEmpty);
      expect(secondController.text, equals('ba'));
    });
  });

  for (final profile in _profiles) {
    testWidgets('captures ${profile.outputDir} 01-fsa', (tester) async {
      await _captureForProfile(
        tester,
        profile,
        '01-fsa',
        _prepareFsa,
      );
    });

    testWidgets('captures ${profile.outputDir} 02-grammar', (tester) async {
      await _captureForProfile(
        tester,
        profile,
        '02-grammar',
        _prepareGrammar,
      );
    });

    testWidgets('captures ${profile.outputDir} 03-pda', (tester) async {
      await _captureForProfile(
        tester,
        profile,
        '03-pda',
        _preparePda,
      );
    });

    testWidgets('captures ${profile.outputDir} 04-tm', (tester) async {
      await _captureForProfile(
        tester,
        profile,
        '04-tm',
        _prepareTm,
      );
    });

    testWidgets('captures ${profile.outputDir} 05-regex', (tester) async {
      await _captureForProfile(
        tester,
        profile,
        '05-regex',
        _prepareRegex,
      );
    });
  }
}

class _ScreenshotProfile {
  const _ScreenshotProfile({
    required this.outputDir,
    required this.physicalSize,
    required this.devicePixelRatio,
  });

  final String outputDir;
  final Size physicalSize;
  final double devicePixelRatio;
}

bool _isMobile(WidgetTester tester) {
  final view = tester.view;
  return view.physicalSize.width / view.devicePixelRatio < 1024;
}

// Advance one immediate frame, then wait through short and longer transitions
// so layout animations, overlays, and async widget rebuilds reach a stable
// screenshot state without relying on pumpAndSettle hanging indefinitely.
Future<void> _settle(WidgetTester tester) async {
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 250));
  await tester.pump(const Duration(milliseconds: 500));
  await tester.pump(const Duration(milliseconds: 500));
}

Future<void> _writeScreenshot(
  GlobalKey repaintKey,
  String outputPath,
  double pixelRatio,
) async {
  final boundary =
      repaintKey.currentContext!.findRenderObject()! as RenderRepaintBoundary;
  final image = await boundary.toImage(pixelRatio: pixelRatio);
  try {
    final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
    if (byteData == null) {
      throw StateError('Failed to encode screenshot for $outputPath');
    }

    final file = File(outputPath);
    file.parent.createSync(recursive: true);
    file.writeAsBytesSync(byteData.buffer.asUint8List());
  } finally {
    image.dispose();
  }
}

Future<void> _captureForProfile(
  WidgetTester tester,
  _ScreenshotProfile profile,
  String fileName,
  Future<void> Function(WidgetTester tester, ProviderContainer container)
      prepare,
) async {
  await resetDependencies();
  SharedPreferences.setMockInitialValues(const {});
  final prefs = await initializeSharedPreferences();

  final logicalSize = Size(
    profile.physicalSize.width / profile.devicePixelRatio,
    profile.physicalSize.height / profile.devicePixelRatio,
  );
  tester.view
    ..physicalSize = profile.physicalSize
    ..devicePixelRatio = profile.devicePixelRatio;
  await tester.binding.setSurfaceSize(logicalSize);
  addTearDown(() async {
    await tester.binding.setSurfaceSize(null);
    tester.view.resetPhysicalSize();
    tester.view.resetDevicePixelRatio();
  });

  final repaintKey = GlobalKey();
  await tester.pumpWidget(
    ProviderScope(
      overrides: [sharedPreferencesProvider.overrideWithValue(prefs)],
      child: RepaintBoundary(
        key: repaintKey,
        child: SizedBox(
          width: logicalSize.width,
          height: logicalSize.height,
          child: const TuringLabApp(),
        ),
      ),
    ),
  );
  await _settle(tester);

  final materialAppFinder = find.byType(MaterialApp);
  expect(materialAppFinder, findsOneWidget);
  final container = ProviderScope.containerOf(
    tester.element(materialAppFinder),
    listen: false,
  );

  debugPrint('prepare:${profile.outputDir}:$fileName');
  await prepare(tester, container);
  debugPrint('capture:${profile.outputDir}:$fileName');

  FocusManager.instance.primaryFocus?.unfocus();
  await _settle(tester);

  await _writeScreenshot(
    repaintKey,
    '$_outputRoot/${profile.outputDir}/$fileName.png',
    tester.view.devicePixelRatio,
  );

  await tester.pumpWidget(const SizedBox.shrink());
  await tester.pump(const Duration(milliseconds: 100));
}

Future<void> _enterField(
  WidgetTester tester,
  String label,
  String value,
) async {
  final finder = _findEntryField(label);
  expect(finder, findsOneWidget, reason: 'Expected a unique field: $label');
  await tester.ensureVisible(finder);
  await tester.tap(finder);
  await tester.pump();
  await tester.enterText(finder, value);
  await _settle(tester);
}

Finder _findEntryField(String label) {
  var finder = find.bySemanticsLabel(label);
  if (finder.evaluate().isNotEmpty) {
    return finder;
  }

  if (label != 'Input String') {
    return finder;
  }

  finder = find.bySemanticsLabel('Simulation input string');
  if (finder.evaluate().isNotEmpty) {
    return finder;
  }

  return find.byType(TextField).last;
}

Future<void> _tapTooltip(WidgetTester tester, String tooltip) async {
  final finder = find.byWidgetPredicate(
    (widget) =>
        widget is IconButton &&
        widget.tooltip == tooltip &&
        widget.onPressed != null,
  );
  expect(finder, findsOneWidget, reason: 'Missing tooltip target: $tooltip');
  await tester.ensureVisible(finder);
  await tester.tap(finder);
  await _settle(tester);
}

Future<void> _prepareFsa(
  WidgetTester tester,
  ProviderContainer container,
) async {
  final notifier = container.read(automatonStateProvider.notifier);
  notifier.updateAutomaton(_buildFsaExample());
  await _settle(tester);

  if (_isMobile(tester)) {
    await _tapTooltip(tester, 'Simulate');
    await _enterField(tester, 'Input String', 'ba');
    await container
        .read(automatonSimulationProvider.notifier)
        .simulateAutomaton('ba');
    await _settle(tester);
    expect(find.text('Accepted'), findsWidgets);
  }
}

Future<void> _prepareGrammar(
  WidgetTester tester,
  ProviderContainer container,
) async {
  final grammar = container.read(grammarProvider.notifier);
  grammar.createNewGrammar(
    name: 'Balanced Grammar',
    startSymbol: 'S',
    type: GrammarType.contextFree,
  );
  grammar.addProduction(
    leftSide: const ['S'],
    rightSide: const ['a', 'S', 'b'],
  );
  grammar.addProduction(
    leftSide: const ['S'],
    rightSide: const ['a', 'b'],
  );
  container
      .read(homeNavigationProvider.notifier)
      .setIndex(HomeNavigationNotifier.grammarIndex);
  await _settle(tester);
}

Future<void> _preparePda(
  WidgetTester tester,
  ProviderContainer container,
) async {
  final example =
      await ExamplesAssetDataSource().loadTypedPdaExample('APD - a^n b^n');
  expect(example.isSuccess, isTrue);
  container.read(pdaEditorProvider.notifier).setPda(example.data!.payload);
  container.read(homeNavigationProvider.notifier).setIndex(
        HomeNavigationNotifier.pdaIndex,
      );
  await _settle(tester);
}

Future<void> _prepareTm(
  WidgetTester tester,
  ProviderContainer container,
) async {
  final example = await ExamplesAssetDataSource().loadTypedTmExample(
    'MT - Incremento binário',
  );
  expect(example.isSuccess, isTrue);
  container.read(tmEditorProvider.notifier).setTm(example.data!.payload);
  container
      .read(homeNavigationProvider.notifier)
      .setIndex(HomeNavigationNotifier.tmIndex);
  await _settle(tester);
}

Future<void> _prepareRegex(
  WidgetTester tester,
  ProviderContainer container,
) async {
  container
      .read(homeNavigationProvider.notifier)
      .setIndex(HomeNavigationNotifier.regexIndex);
  await _settle(tester);
  final regexInput = find.byKey(const ValueKey('regex_input_field'));
  expect(regexInput, findsOneWidget);
  await tester.enterText(regexInput, '(ab)*a');
  await _settle(tester);
  expect(find.text('Valid regex'), findsWidgets);
  final testStringInput = find.byKey(
    const ValueKey('regex_test_input_field'),
  );
  expect(testStringInput, findsOneWidget);
  await tester.enterText(testStringInput, 'aba');
  await _settle(tester);
  expect(find.text('Matches!'), findsWidgets);
}

FSA _buildFsaExample() {
  final now = DateTime.now();
  final q0 = automaton_state.State(
    id: 'q0',
    label: 'q0',
    position: Vector2(180, 220),
    isInitial: true,
  );
  final q1 = automaton_state.State(
    id: 'q1',
    label: 'q1',
    position: Vector2(560, 220),
    isAccepting: true,
  );

  return FSA(
    id: 'app_store_fsa',
    name: 'Ends with a',
    states: {q0, q1},
    transitions: {
      FSATransition.deterministic(
        id: 't0',
        fromState: q0,
        toState: q1,
        symbol: 'a',
      ),
      FSATransition.deterministic(
        id: 't1',
        fromState: q0,
        toState: q0,
        symbol: 'b',
      ),
      FSATransition.deterministic(
        id: 't2',
        fromState: q1,
        toState: q1,
        symbol: 'a',
      ),
      FSATransition.deterministic(
        id: 't3',
        fromState: q1,
        toState: q0,
        symbol: 'b',
      ),
    },
    alphabet: {'a', 'b'},
    initialState: q0,
    acceptingStates: {q1},
    created: now,
    modified: now,
    bounds: const math.Rectangle<double>(0, 0, 900, 520),
  );
}
