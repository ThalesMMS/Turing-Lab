import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vector_math/vector_math_64.dart';

import 'package:turing_lab/core/models/state.dart' as automaton_state;
import 'package:turing_lab/core/models/simulation_highlight.dart';
import 'package:turing_lab/core/models/tm.dart';
import 'package:turing_lab/core/models/tm_transition.dart';
import 'package:turing_lab/core/models/transition.dart';
import 'package:turing_lab/core/services/canvas_highlight_coordinator.dart';
import 'package:turing_lab/core/services/highlight_channel.dart';
import 'package:turing_lab/core/result.dart';
import 'package:turing_lab/data/data_sources/examples_asset_data_source.dart';
import 'package:turing_lab/presentation/providers/tm_editor_provider.dart';
import 'package:turing_lab/presentation/widgets/common/algorithm_button.dart';
import 'package:turing_lab/presentation/widgets/tm_algorithm_panel.dart';

class _FakeTmExamplesDataSource extends ExamplesAssetDataSource {
  _FakeTmExamplesDataSource() : example = _buildTmExample();

  final AssetExample<TM> example;

  @override
  Future<ListResult<AssetExample<TM>>> loadAllTypedTmExamples() async {
    return Success([example]);
  }

  @override
  Future<Result<AssetExample<TM>>> loadTypedTmExample(String name) async {
    return Success(example);
  }
}

class _RecordingHighlightChannel implements HighlightChannel {
  final List<SimulationHighlight?> events = <SimulationHighlight?>[];

  @override
  void clear() => events.add(null);

  @override
  void send(SimulationHighlight highlight) => events.add(highlight);
}

class _TmPanelHarness {
  const _TmPanelHarness({
    required this.notifier,
    required this.output,
    required this.coordinator,
  });

  final TMEditorNotifier notifier;
  final _RecordingHighlightChannel output;
  final CanvasHighlightCoordinator coordinator;
}

Future<_TmPanelHarness> _pumpTmAlgorithmPanel(
  WidgetTester tester, {
  TM? initialTm,
}) async {
  final tmNotifier = TMEditorNotifier();
  if (initialTm != null) {
    tmNotifier.setTm(initialTm);
  }
  final examplesDataSource = _FakeTmExamplesDataSource();
  final output = _RecordingHighlightChannel();
  final coordinator = CanvasHighlightCoordinator(
    target: CanvasHighlightTarget(
      kind: AutomatonSurfaceKind.tm,
      surface: Object(),
      documentId: initialTm?.id,
      revision: 0,
    ),
    output: output,
  );
  addTearDown(coordinator.dispose);

  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        tmEditorProvider.overrideWith((ref) => tmNotifier),
        canvasHighlightCoordinatorProvider.overrideWithValue(coordinator),
      ],
      child: MaterialApp(
        home: Scaffold(
          body: TMAlgorithmPanel(
            useExpanded: false,
            examplesDataSource: examplesDataSource,
          ),
        ),
      ),
    ),
  );

  await tester.pump();
  await _pumpUntilFound(tester, find.text('MT - a^n b^n'));

  return _TmPanelHarness(
    notifier: tmNotifier,
    output: output,
    coordinator: coordinator,
  );
}

AssetExample<TM> _buildTmExample() {
  final start = automaton_state.State(
    id: 'tm/state:start',
    label: 'q0',
    position: Vector2.zero(),
    isInitial: true,
  );
  final accept = automaton_state.State(
    id: 'tm/state:accept',
    label: 'q1',
    position: Vector2(120, 0),
    isAccepting: true,
  );
  final transition = TMTransition(
    id: 't0',
    fromState: start,
    toState: accept,
    label: 'a/a,R',
    type: TransitionType.deterministic,
    readSymbol: 'a',
    writeSymbol: 'a',
    direction: TapeDirection.right,
  );
  final tm = TM(
    id: 'tm-anbn',
    name: 'MT - a^n b^n',
    states: {start, accept},
    transitions: {transition},
    alphabet: const {'a'},
    initialState: start,
    acceptingStates: {accept},
    created: DateTime(2026),
    modified: DateTime(2026),
    bounds: const math.Rectangle(0, 0, 400, 300),
    tapeAlphabet: const {'a', 'B'},
    blankSymbol: 'B',
  );

  return AssetExample<TM>(
    name: tm.name,
    description: 'Fake TM example for widget tests',
    category: ExampleCategory.tm,
    difficultyLevel: DifficultyLevel.easy,
    complexityLevel: ExampleComplexityLevel.low,
    tags: const ['test'],
    payload: tm,
  );
}

Future<void> _pumpUntilFound(WidgetTester tester, Finder finder) async {
  for (var attempt = 0; attempt < 80; attempt++) {
    if (finder.evaluate().isNotEmpty) {
      return;
    }
    await tester.pump(const Duration(milliseconds: 50));
  }
  final visibleText = tester
      .widgetList<Text>(find.byType(Text))
      .map((text) => text.data)
      .whereType<String>()
      .join(' | ');
  fail('Timed out waiting for $finder. Visible text: $visibleText');
}

Future<void> _pumpUntilTmLoaded(
  WidgetTester tester,
  TMEditorNotifier tmNotifier,
) async {
  for (var attempt = 0; attempt < 80; attempt++) {
    if (tmNotifier.state.tm != null) {
      return;
    }
    await tester.pump(const Duration(milliseconds: 50));
  }
  fail('Timed out waiting for TM example to load');
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('editing the TM clears completed analysis state and highlights', (
    tester,
  ) async {
    final tm = _buildTmExample().payload;
    final harness = await _pumpTmAlgorithmPanel(tester, initialTm: tm);
    await tester.enterText(
      find.byKey(const Key('tm-termination-input')),
      'a',
    );

    await tester.ensureVisible(find.text('Tape Trace'));
    await tester.tap(find.text('Tape Trace'));
    await _pumpUntilFound(tester, find.text('Deterministic execution'));
    expect(harness.output.events.last, isNotNull);

    harness.notifier.setTm(tm.copyWith(name: 'Edited TM'));
    await tester.pump();

    expect(find.text('No analysis results yet'), findsOneWidget);
    expect(find.text('Deterministic execution'), findsNothing);
    expect(harness.output.events.last, isNull);
    expect(
      tester
          .widgetList<AlgorithmButton>(find.byType(AlgorithmButton))
          .every((button) => !button.isSelected),
      isTrue,
    );
    expect(find.byKey(const Key('tm-analysis-cancel')), findsNothing);
  });

  testWidgets(
    'replacing the TM during tape analysis discards stale result and highlights',
    (tester) async {
      final harness = await _pumpTmAlgorithmPanel(
        tester,
        initialTm: _buildMovingMachine(),
      );

      await tester.ensureVisible(find.text('Tape Trace'));
      await tester.tap(find.text('Tape Trace'));
      await tester.pump();
      expect(find.byKey(const Key('tm-analysis-cancel')), findsOneWidget);

      final replacement = _buildTmExample().payload.copyWith(
            id: 'replacement-tm',
            name: 'Replacement TM',
          );
      harness.coordinator.retarget(
        CanvasHighlightTarget(
          kind: AutomatonSurfaceKind.tm,
          surface: Object(),
          documentId: replacement.id,
          revision: 1,
        ),
      );
      final eventsBeforeReplacement = harness.output.events.length;
      harness.notifier.setTm(replacement);
      await tester.pump();

      expect(find.text('No analysis results yet'), findsOneWidget);
      expect(find.byKey(const Key('tm-analysis-cancel')), findsNothing);
      for (var attempt = 0; attempt < 80; attempt++) {
        await tester.pump(const Duration(milliseconds: 1));
      }

      expect(find.text('No analysis results yet'), findsOneWidget);
      expect(find.text('Deterministic execution'), findsNothing);
      expect(
        harness.output.events
            .skip(eventsBeforeReplacement)
            .whereType<SimulationHighlight>(),
        isEmpty,
      );
    },
  );

  testWidgets('renders TM actions through AlgorithmButton', (tester) async {
    await _pumpTmAlgorithmPanel(tester);

    expect(find.byType(AlgorithmButton), findsNWidgets(6));
    expect(find.text('Termination and Cycles'), findsOneWidget);
    expect(find.text('Reachability'), findsOneWidget);
    expect(find.text('Language Explorer'), findsOneWidget);
    expect(find.text('Tape Trace'), findsOneWidget);
    expect(find.text('Time Profile'), findsOneWidget);
    expect(find.text('Time Characteristics'), findsNothing);
    expect(find.text('Space Profile'), findsOneWidget);
    expect(find.text('Space Characteristics'), findsNothing);
  });

  testWidgets(
    'six TM actions render distinct bounded contracts without structural aliases',
    (tester) async {
      final tm = _buildTmExample().payload.copyWith(
        alphabet: const {'a', 'b'},
        tapeAlphabet: const {'a', 'b', 'B'},
      );
      await _pumpTmAlgorithmPanel(tester, initialTm: tm);

      void expectNoStructuralAlias() {
        expect(find.text('State Analysis'), findsNothing);
        expect(find.text('Transition Analysis'), findsNothing);
        expect(find.text('Structural analyzer wall-clock'), findsNothing);
        expect(find.text('Tape alphabet'), findsNothing);
      }

      await tester.enterText(
        find.byKey(const Key('tm-termination-input')),
        'a',
      );
      await tester.ensureVisible(find.text('Termination and Cycles'));
      await tester.tap(find.text('Termination and Cycles'));
      await _pumpUntilFound(tester, find.text('Exact for this input'));

      expect(
        find.text('Analysis focus: Termination and Cycles'),
        findsOneWidget,
      );
      expect(find.text('Transitions executed'), findsOneWidget);
      expect(find.text('Step limit'), findsOneWidget);
      expect(find.text('Configuration limit'), findsOneWidget);
      expect(find.text('Time limit'), findsOneWidget);
      expectNoStructuralAlias();

      await tester.enterText(
        find.byKey(const Key('tm-reachability-inputs')),
        'a',
      );
      await tester.ensureVisible(find.text('Reachability'));
      await tester.tap(find.text('Reachability'));
      await _pumpUntilFound(tester, find.text('Complete for this input scope'));

      expect(
        find.text(
          'Analysis focus: Structural and bounded semantic reachability',
        ),
        findsOneWidget,
      );
      expect(
        find.text('Structurally reachable (exact over-approximation)'),
        findsOneWidget,
      );
      expect(find.text('Reached within bounds'), findsOneWidget);
      expect(find.text('Configurations explored'), findsOneWidget);
      expect(find.text('Configuration limit'), findsOneWidget);
      expectNoStructuralAlias();

      await tester.enterText(
        find.byKey(const Key('tm-language-max-length')),
        '1',
      );
      await tester.enterText(
        find.byKey(const Key('tm-language-candidate-cap')),
        '1',
      );
      await tester.ensureVisible(find.text('Language Explorer'));
      await tester.tap(find.text('Language Explorer'));
      await _pumpUntilFound(
        tester,
        find.textContaining('Candidate cap reached'),
      );

      expect(
        find.text('Analysis focus: Language Explorer'),
        findsOneWidget,
      );
      for (final outcome in const [
        'accepted',
        'rejected',
        'provenCycle',
        'inconclusive',
      ]) {
        expect(find.byKey(Key('tm-language-count-$outcome')), findsOneWidget);
      }
      expect(find.text('Evaluated candidates'), findsOneWidget);
      expect(
        tester
            .widget<TextField>(
              find.byKey(const Key('tm-language-max-configurations')),
            )
            .controller!
            .text,
        '100000',
      );
      expectNoStructuralAlias();

      await tester.ensureVisible(find.text('Tape Trace'));
      await tester.tap(find.text('Tape Trace'));
      await _pumpUntilFound(tester, find.text('Deterministic execution'));

      expect(find.text('Analysis focus: Tape Trace'), findsOneWidget);
      expect(find.text('Executed transitions'), findsOneWidget);
      expect(find.text('Distinct cells visited'), findsOneWidget);
      expect(find.text('Maximum simultaneous nonblank cells'), findsOneWidget);
      expect(
        find.text('Limits: 10,000 steps, 100,000 configurations, 5 seconds'),
        findsOneWidget,
      );
      expectNoStructuralAlias();

      await tester.enterText(
        find.byKey(const Key('tm-time-profile-max-length')),
        '1',
      );
      await tester.enterText(
        find.byKey(const Key('tm-time-profile-candidate-cap')),
        '1',
      );
      await tester.ensureVisible(find.text('Time Profile'));
      await tester.tap(find.text('Time Profile'));
      await _pumpUntilFound(tester, find.text('Sampled • incomplete'));

      expect(
        find.text('Analysis focus: Time Profile'),
        findsOneWidget,
      );
      expect(find.text('DTM transition-step profile'), findsOneWidget);
      expect(find.text('Transition-step budget per candidate'), findsOneWidget);
      expect(find.text('Configuration budget per candidate'), findsOneWidget);
      expect(find.text('Time budget per candidate'), findsOneWidget);
      expectNoStructuralAlias();

      await tester.enterText(find.byKey(const Key('tm-space-max-length')), '1');
      await tester.enterText(
        find.byKey(const Key('tm-space-candidate-cap')),
        '1',
      );
      await tester.ensureVisible(find.text('Space Profile'));
      await tester.tap(find.text('Space Profile'));
      await _pumpUntilFound(
        tester,
        find.text('Analysis focus: Space Profile'),
      );

      expect(
        find.text('Analysis focus: Space Profile'),
        findsOneWidget,
      );
      expect(find.text('Sampled'), findsOneWidget);
      expect(find.text('Incomplete'), findsOneWidget);
      expect(find.text('Visited span maximum'), findsNWidgets(2));
      expect(find.text('Maximum nonblank cells'), findsNWidgets(2));
      expect(find.text('Step limit per input'), findsOneWidget);
      expect(find.text('Configuration bound per input'), findsOneWidget);
      expect(find.text('Time limit per input'), findsOneWidget);
      expectNoStructuralAlias();
    },
  );

  testWidgets('time profile shows its plan, bounded rows, and maximum trace', (
    tester,
  ) async {
    final tm = _buildTmExample().payload;
    await _pumpTmAlgorithmPanel(tester, initialTm: tm);

    expect(
      find.byKey(const Key('tm-time-profile-planned-count')),
      findsOneWidget,
    );
    expect(
      find.text(
        'Per candidate: 50,000 transition steps, 100,000 configurations, 5 seconds',
      ),
      findsOneWidget,
    );
    await tester.enterText(
      find.byKey(const Key('tm-time-profile-max-length')),
      '1',
    );
    await tester.ensureVisible(find.text('Time Profile'));
    await tester.tap(find.text('Time Profile'));
    await _pumpUntilFound(tester, find.text('DTM transition-step profile'));

    expect(find.byKey(const Key('tm-time-profile-row-0')), findsOneWidget);
    expect(find.byKey(const Key('tm-time-profile-row-1')), findsOneWidget);
    expect(find.text('Exhaustive • complete'), findsNWidgets(2));
    expect(find.text('Maximum transition-step witness'), findsNWidgets(2));
    expect(
        find.text('Profiler device wall-clock (diagnostic)'), findsOneWidget);
    expect(
      find.text(
          'Observed bounded measurements only; no Big-O class is inferred.'),
      findsOneWidget,
    );

    final witness = find.byKey(const Key('tm-time-witness-1-transitions'));
    await tester.ensureVisible(witness);
    await tester.tap(witness);
    await tester.pumpAndSettle();
    expect(find.text('Step 1 • tm/state:accept'), findsOneWidget);
  });

  testWidgets('sampled time-profile rows are visibly incomplete', (
    tester,
  ) async {
    final source = _buildTmExample().payload;
    final tm = source.copyWith(
      alphabet: const {'a', 'b'},
      tapeAlphabet: const {'a', 'b', 'B'},
    );
    await _pumpTmAlgorithmPanel(tester, initialTm: tm);

    await tester.enterText(
      find.byKey(const Key('tm-time-profile-max-length')),
      '1',
    );
    await tester.enterText(
      find.byKey(const Key('tm-time-profile-candidate-cap')),
      '1',
    );
    await tester.ensureVisible(find.text('Time Profile'));
    await tester.tap(find.text('Time Profile'));
    await _pumpUntilFound(tester, find.text('Sampled • incomplete'));

    expect(find.byKey(const Key('tm-time-profile-row-mode-1')), findsOneWidget);
    expect(find.text('Possible candidates'), findsOneWidget);
    expect(
      find.textContaining('incomplete because a row was sampled'),
      findsOneWidget,
    );
  });

  testWidgets('NTM time profile is labeled as operational exploration', (
    tester,
  ) async {
    final source = _buildTmExample().payload;
    final branch = automaton_state.State(
      id: 'tm/state:branch',
      label: 'q2',
      position: Vector2(120, 80),
    );
    final competingTransition = TMTransition(
      id: 't1',
      fromState: source.initialState!,
      toState: branch,
      label: 'a/a,S',
      type: TransitionType.nondeterministic,
      readSymbol: 'a',
      writeSymbol: 'a',
      direction: TapeDirection.stay,
    );
    final tm = source.copyWith(
      states: {...source.states, branch},
      transitions: {...source.transitions, competingTransition},
    );
    await _pumpTmAlgorithmPanel(tester, initialTm: tm);

    await tester.enterText(
      find.byKey(const Key('tm-time-profile-max-length')),
      '1',
    );
    await tester.ensureVisible(find.text('Time Profile'));
    await tester.tap(find.text('Time Profile'));
    await _pumpUntilFound(
      tester,
      find.text('NTM exploration metrics (not deterministic time)'),
    );

    expect(find.text('Observed branch depth range'), findsNWidgets(2));
    expect(
      find.text('Observed configurations explored range'),
      findsNWidgets(2),
    );
    expect(
      find.byKey(const Key('tm-time-witness-1-depth')),
      findsOneWidget,
    );
    expect(
      find.byKey(const Key('tm-time-witness-1-configurations')),
      findsOneWidget,
    );
    expect(find.text('DTM transition-step profile'), findsNothing);
  });

  testWidgets('time-profile progress remains cancellable during a long run', (
    tester,
  ) async {
    final moving = automaton_state.State(
      id: 'moving',
      label: 'moving',
      position: Vector2.zero(),
      isInitial: true,
    );
    final tm = TM(
      id: 'long-profile',
      name: 'Long profile',
      states: {moving},
      transitions: {
        TMTransition(
          id: 'move',
          fromState: moving,
          toState: moving,
          label: 'B/B,R',
          readSymbol: 'B',
          writeSymbol: 'B',
          direction: TapeDirection.right,
        ),
      },
      alphabet: const {},
      initialState: moving,
      acceptingStates: const {},
      created: DateTime(2026),
      modified: DateTime(2026),
      bounds: const math.Rectangle(0, 0, 400, 300),
      tapeAlphabet: const {'B'},
      blankSymbol: 'B',
    );
    await _pumpTmAlgorithmPanel(tester, initialTm: tm);

    await tester.enterText(
      find.byKey(const Key('tm-time-profile-max-length')),
      '0',
    );
    await tester.ensureVisible(find.text('Time Profile'));
    await tester.tap(find.text('Time Profile'));
    await tester.pump();

    expect(find.byKey(const Key('tm-analysis-cancel')), findsOneWidget);
    expect(find.text('0%'), findsOneWidget);
    await tester.ensureVisible(find.byKey(const Key('tm-analysis-cancel')));
    await tester.tap(find.byKey(const Key('tm-analysis-cancel')));
    await _pumpUntilFound(tester, find.text('Time profiling was cancelled.'));

    expect(find.text('Exhaustive • incomplete'), findsOneWidget);
  });

  testWidgets('TM action still reports missing editor TM', (tester) async {
    await _pumpTmAlgorithmPanel(tester);

    await tester.ensureVisible(find.text('Termination and Cycles'));
    await tester.pump();

    await tester.tap(find.text('Termination and Cycles'));
    await tester.pump();

    expect(
      find.text(
        'No Turing machine available. Draw states and transitions on the canvas to analyze.',
      ),
      findsOneWidget,
    );
  });

  testWidgets('termination action runs a bounded analysis for its input', (
    tester,
  ) async {
    final tm = _buildTmExample().payload;
    await _pumpTmAlgorithmPanel(tester, initialTm: tm);

    await tester.enterText(
      find.byKey(const Key('tm-termination-input')),
      'a',
    );
    await tester.ensureVisible(find.text('Termination and Cycles'));
    await tester.tap(find.text('Termination and Cycles'));
    await _pumpUntilFound(tester, find.textContaining('Accepted.'));

    expect(find.text('Exact for this input'), findsOneWidget);
    expect(find.text('10000'), findsWidgets);
    expect(find.text('100000'), findsWidgets);
    expect(find.text('5 s'), findsOneWidget);
  });

  testWidgets('termination cycle exposes its repeated configuration witness', (
    tester,
  ) async {
    await _pumpTmAlgorithmPanel(
      tester,
      initialTm: _buildStationaryCycleMachine(),
    );

    await tester.enterText(
      find.byKey(const Key('tm-termination-input')),
      'a',
    );
    await tester.ensureVisible(find.text('Termination and Cycles'));
    await tester.tap(find.text('Termination and Cycles'));
    await _pumpUntilFound(tester, find.textContaining('Proven cycle.'));

    expect(find.text('Repeated head position'), findsOneWidget);
    expect(find.text('Repeated nonblank tape cells'), findsOneWidget);
    expect(find.text('0: a'), findsOneWidget);
    expect(find.byKey(const Key('tm-cycle-trace')), findsOneWidget);
  });

  testWidgets('tape action reports executed metrics and reuses its trace', (
    tester,
  ) async {
    final tm = _buildTmExample().payload;
    final harness = await _pumpTmAlgorithmPanel(tester, initialTm: tm);

    await tester.enterText(
      find.byKey(const Key('tm-termination-input')),
      'a',
    );
    await tester.ensureVisible(find.text('Tape Trace'));
    await tester.tap(find.text('Tape Trace'));
    await _pumpUntilFound(tester, find.text('Deterministic execution'));

    expect(find.text('0…1'), findsOneWidget);
    expect(find.text('a: 1'), findsWidgets);
    expect(find.text('right: 1'), findsOneWidget);
    expect(find.text('Declared tape alphabet'), findsOneWidget);
    expect(find.text('Configurations explored'), findsOneWidget);
    expect(find.text('Exact for this input'), findsOneWidget);
    expect(harness.output.events.last?.transitionIds, {'t0'});
    expect(harness.output.events.last?.stateIds, {
      'tm/state:start',
      'tm/state:accept',
    });

    final traceTile = find.byKey(const Key('tm-tape-related-trace'));
    await tester.ensureVisible(traceTile);
    await tester.tap(traceTile);
    await tester.pumpAndSettle();
    expect(find.text('Step 1 • tm/state:accept'), findsOneWidget);
  });

  testWidgets('language explorer exposes limits, counts, and selectable traces',
      (
    tester,
  ) async {
    final tm = _buildTmExample().payload;
    await _pumpTmAlgorithmPanel(tester, initialTm: tm);

    expect(find.byKey(const Key('tm-language-max-length')), findsOneWidget);
    expect(find.byKey(const Key('tm-language-candidate-cap')), findsOneWidget);
    expect(find.byKey(const Key('tm-language-max-steps')), findsOneWidget);
    expect(
      find.byKey(const Key('tm-language-max-configurations')),
      findsOneWidget,
    );
    expect(find.byKey(const Key('tm-language-timeout-ms')), findsOneWidget);
    expect(
      tester
          .widget<Text>(find.byKey(const Key('tm-language-candidate-estimate')))
          .data,
      contains('Estimated candidates: 3'),
    );

    await tester.ensureVisible(find.text('Language Explorer'));
    await tester.tap(find.text('Language Explorer'));
    await _pumpUntilFound(tester, find.text('Accepted: 2'));

    expect(find.text('Halted rejected: 1'), findsOneWidget);
    expect(find.text('Proven cycle: 0'), findsOneWidget);
    expect(find.text('Inconclusive: 0'), findsOneWidget);
    expect(find.text('ε'), findsOneWidget);
    expect(find.text('Completeness'), findsOneWidget);
    expect(find.text('Complete'), findsOneWidget);
    expect(find.text('Input alphabet'), findsOneWidget);
    expect(find.text('Candidate cap'), findsWidgets);

    await tester
        .ensureVisible(find.byKey(const ValueKey('tm-language-word-a')));
    await tester.tap(find.byKey(const ValueKey('tm-language-word-a')));
    await _pumpUntilFound(tester, find.text('Selected word: a'));
    await _pumpUntilFound(tester, find.byKey(const Key('tm-language-trace')));

    expect(find.text('Transitions executed'), findsOneWidget);
    expect(find.text('Configurations explored'), findsOneWidget);
    expect(find.textContaining('Step 0'), findsOneWidget);
  });

  testWidgets('language exploration cancellation keeps a partial report', (
    tester,
  ) async {
    await _pumpTmAlgorithmPanel(tester, initialTm: _buildMovingMachine());

    await tester.enterText(
      find.byKey(const Key('tm-language-max-length')),
      '20',
    );
    await tester.enterText(
      find.byKey(const Key('tm-language-max-steps')),
      '1000000',
    );

    await tester.ensureVisible(find.text('Language Explorer'));
    await tester.tap(find.text('Language Explorer'));
    await tester.pump();
    await _pumpUntilFound(tester, find.byKey(const Key('tm-analysis-cancel')));
    await tester.ensureVisible(find.byKey(const Key('tm-analysis-cancel')));
    await tester.tap(find.byKey(const Key('tm-analysis-cancel')));
    await _pumpUntilFound(
      tester,
      find.text('Exploration cancelled. Evaluated results were kept.'),
    );

    expect(find.text('Halted rejected: 0'), findsOneWidget);
    expect(find.text('Inconclusive: 1'), findsOneWidget);
  });

  testWidgets(
      'space profile exposes bounds, precomputed counts, and both witnesses',
      (tester) async {
    final tm = _buildTmExample().payload;
    await _pumpTmAlgorithmPanel(tester, initialTm: tm);

    expect(find.byKey(const Key('tm-space-max-length')), findsOneWidget);
    expect(find.byKey(const Key('tm-space-candidate-cap')), findsOneWidget);
    expect(find.byKey(const Key('tm-space-max-steps')), findsOneWidget);
    expect(
      find.byKey(const Key('tm-space-max-configurations')),
      findsOneWidget,
    );
    expect(find.byKey(const Key('tm-space-timeout-ms')), findsOneWidget);
    expect(
      tester
          .widget<Text>(find.byKey(const Key('tm-space-candidate-estimate')))
          .data,
      'Estimated candidates: 3; scheduled: 3',
    );

    await tester.ensureVisible(find.text('Space Profile'));
    await tester.tap(find.text('Space Profile'));
    await _pumpUntilFound(tester, find.text('Input length 1'));

    expect(find.text('Visited span maximum'), findsNWidgets(3));
    expect(find.text('Maximum nonblank cells'), findsNWidgets(3));
    expect(find.text('2 cell(s) • witness a'), findsOneWidget);
    expect(find.text('1 cell(s) • witness a'), findsOneWidget);
    expect(find.text('Configuration bound per input'), findsOneWidget);
    expect(find.text('Tape alphabet'), findsNothing);
  });

  testWidgets('space profile distinguishes sampled and incomplete rows', (
    tester,
  ) async {
    final base = _buildTmExample().payload;
    final tm = base.copyWith(
      alphabet: const {'a', 'b'},
      tapeAlphabet: const {'a', 'b', 'B'},
    );
    await _pumpTmAlgorithmPanel(tester, initialTm: tm);

    await tester.enterText(
      find.byKey(const Key('tm-space-max-length')),
      '1',
    );
    await tester.enterText(
      find.byKey(const Key('tm-space-candidate-cap')),
      '1',
    );
    await tester.pump();
    expect(
      find.text('Estimated candidates: 3; scheduled: 2'),
      findsOneWidget,
    );

    await tester.ensureVisible(find.text('Space Profile'));
    await tester.tap(find.text('Space Profile'));
    await _pumpUntilFound(tester, find.text('Input length 1'));

    expect(find.text('Exhaustive'), findsOneWidget);
    expect(find.text('Sampled'), findsOneWidget);
    expect(find.text('Complete'), findsOneWidget);
    expect(find.text('Incomplete'), findsOneWidget);
    expect(find.text('1 of 2'), findsOneWidget);
  });

  testWidgets('space profile labels NTM aggregation and configuration bound', (
    tester,
  ) async {
    await _pumpTmAlgorithmPanel(
      tester,
      initialTm: _buildNondeterministicTm(),
    );
    await tester.enterText(
      find.byKey(const Key('tm-space-max-length')),
      '0',
    );

    await tester.ensureVisible(find.text('Space Profile'));
    await tester.tap(find.text('Space Profile'));
    await _pumpUntilFound(tester, find.text('Input length 0'));

    expect(
      find.text(
        'NTM maxima cover every explored branch configuration within the displayed configuration bound.',
      ),
      findsOneWidget,
    );
    expect(find.text('Configuration bound per input'), findsOneWidget);
    expect(find.text('100000'), findsWidgets);
  });

  testWidgets('loads TM examples from the configured catalog into the editor', (
    tester,
  ) async {
    final harness = await _pumpTmAlgorithmPanel(tester);

    expect(find.text('MT - a^n b^n'), findsOneWidget);

    await tester.tap(find.text('MT - a^n b^n'));
    await _pumpUntilTmLoaded(tester, harness.notifier);

    final tm = harness.notifier.state.tm;
    expect(tm, isNotNull);
    expect(tm!.name, equals('MT - a^n b^n'));
    expect(tm.tmTransitions, hasLength(1));
    expect(tm.blankSymbol, equals('B'));
  });

  testWidgets('reachable-state analysis emits stable TM state ids', (
    tester,
  ) async {
    final tm = _buildTmExample().payload;
    final harness = await _pumpTmAlgorithmPanel(
      tester,
      initialTm: tm,
    );

    await tester.enterText(
      find.byKey(const Key('tm-reachability-inputs')),
      'a',
    );
    await tester.ensureVisible(find.text('Reachability'));
    await tester.tap(find.text('Reachability'));
    await _pumpUntilFound(tester, find.text('Complete for this input scope'));

    expect(harness.output.events, isNotEmpty);
    expect(harness.output.events.last!.stateIds, {
      'tm/state:start',
      'tm/state:accept',
    });
    expect(harness.output.events.last!.warningStateIds, isEmpty);
    expect(harness.output.events.last!.errorStateIds, isEmpty);
    expect(harness.output.events.last!.stateIds, isNot(contains('q0')));

    final witnessTile =
        find.byKey(const Key('tm-reachability-witness-tm/state:accept'));
    await tester.ensureVisible(witnessTile);
    await tester.tap(witnessTile);
    await tester.pumpAndSettle();
    expect(find.text('t0'), findsWidgets);
  });

  testWidgets(
      'reachability distinguishes bounded absence from structural disconnection',
      (tester) async {
    final start = automaton_state.State(
      id: 'start-id',
      label: 'start',
      position: Vector2.zero(),
      isInitial: true,
    );
    final guarded = automaton_state.State(
      id: 'guarded-id',
      label: 'guarded',
      position: Vector2(100, 0),
    );
    final disconnected = automaton_state.State(
      id: 'disconnected-id',
      label: 'disconnected',
      position: Vector2(200, 0),
    );
    final tm = TM(
      id: 'reachability-colors',
      name: 'Reachability colors',
      states: {start, guarded, disconnected},
      transitions: {
        TMTransition(
          id: 'guarded-edge',
          fromState: start,
          toState: guarded,
          label: 'a/a,S',
          readSymbol: 'a',
          writeSymbol: 'a',
          direction: TapeDirection.stay,
        ),
      },
      alphabet: const {'a'},
      initialState: start,
      acceptingStates: const {},
      created: DateTime(2026),
      modified: DateTime(2026),
      bounds: const math.Rectangle(0, 0, 400, 300),
      tapeAlphabet: const {'a', 'B'},
      blankSymbol: 'B',
    );
    final harness = await _pumpTmAlgorithmPanel(tester, initialTm: tm);

    await tester.ensureVisible(find.text('Reachability'));
    await tester.tap(find.text('Reachability'));
    await _pumpUntilFound(tester, find.text('Complete for this input scope'));

    final highlight = harness.output.events.last!;
    expect(highlight.stateIds, {'start-id'});
    expect(highlight.warningStateIds, {'guarded-id'});
    expect(highlight.errorStateIds, {'disconnected-id'});
    expect(
      find.text('Not observed for this input scope'),
      findsOneWidget,
    );
    expect(find.text('Structurally unreachable (exact)'), findsOneWidget);
  });
}

TM _buildMovingMachine() {
  final start = automaton_state.State(
    id: 'moving-start',
    label: 'q0',
    position: Vector2.zero(),
    isInitial: true,
  );
  return TM(
    id: 'moving',
    name: 'Moving forever',
    states: {start},
    transitions: {
      for (final symbol in const ['a', 'B'])
        TMTransition(
          id: 'move-$symbol',
          fromState: start,
          toState: start,
          label: '$symbol/$symbol,R',
          readSymbol: symbol,
          writeSymbol: symbol,
          direction: TapeDirection.right,
        ),
    },
    alphabet: const {'a'},
    initialState: start,
    acceptingStates: const {},
    created: DateTime(2026),
    modified: DateTime(2026),
    bounds: const math.Rectangle(0, 0, 400, 300),
    tapeAlphabet: const {'a', 'B'},
    blankSymbol: 'B',
  );
}

TM _buildStationaryCycleMachine() {
  final start = automaton_state.State(
    id: 'cycle-start',
    label: 'q0',
    position: Vector2.zero(),
    isInitial: true,
  );
  return TM(
    id: 'stationary-cycle',
    name: 'Stationary cycle',
    states: {start},
    transitions: {
      TMTransition(
        id: 'cycle-a',
        fromState: start,
        toState: start,
        label: 'a/a,S',
        readSymbol: 'a',
        writeSymbol: 'a',
        direction: TapeDirection.stay,
      ),
    },
    alphabet: const {'a'},
    initialState: start,
    acceptingStates: const {},
    created: DateTime(2026),
    modified: DateTime(2026),
    bounds: const math.Rectangle(0, 0, 400, 300),
    tapeAlphabet: const {'a', 'B'},
    blankSymbol: 'B',
  );
}

TM _buildNondeterministicTm() {
  final base = _buildTmExample().payload;
  final alternate = automaton_state.State(
    id: 'tm/state:alternate',
    label: 'q2',
    position: Vector2(120, 100),
  );
  final alternateTransition = TMTransition(
    id: 't1',
    fromState: base.initialState!,
    toState: alternate,
    label: 'a/a,L',
    type: TransitionType.nondeterministic,
    readSymbol: 'a',
    writeSymbol: 'a',
    direction: TapeDirection.left,
  );
  return base.copyWith(
    states: {...base.states, alternate},
    transitions: {...base.transitions, alternateTransition},
  );
}
