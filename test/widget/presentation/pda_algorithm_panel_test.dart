import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vector_math/vector_math_64.dart';

import 'package:turing_lab/core/models/pda.dart';
import 'package:turing_lab/core/models/pda_transition.dart';
import 'package:turing_lab/core/models/simulation_highlight.dart';
import 'package:turing_lab/core/models/state.dart' as automaton_state;
import 'package:turing_lab/core/models/transition.dart';
import 'package:turing_lab/core/services/canvas_highlight_coordinator.dart';
import 'package:turing_lab/core/services/highlight_channel.dart';
import 'package:turing_lab/core/result.dart';
import 'package:turing_lab/data/data_sources/examples_asset_data_source.dart';
import 'package:turing_lab/presentation/providers/pda_editor_provider.dart';
import 'package:turing_lab/presentation/widgets/common/algorithm_button.dart';
import 'package:turing_lab/presentation/widgets/pda_algorithm_panel.dart';

class _FakePdaExamplesDataSource extends ExamplesAssetDataSource {
  _FakePdaExamplesDataSource() : example = _buildPdaExample();

  final AssetExample<PDA> example;

  @override
  Future<ListResult<AssetExample<PDA>>> loadAllTypedPdaExamples() async {
    return Success([example]);
  }

  @override
  Future<Result<AssetExample<PDA>>> loadTypedPdaExample(String name) async {
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

class _PdaPanelHarness {
  const _PdaPanelHarness({
    required this.notifier,
    required this.output,
    required this.coordinator,
  });

  final PDAEditorNotifier notifier;
  final _RecordingHighlightChannel output;
  final CanvasHighlightCoordinator coordinator;
}

Future<_PdaPanelHarness> _pumpPdaAlgorithmPanel(
  WidgetTester tester, {
  PDA? initialPda,
}) async {
  final pdaNotifier = PDAEditorNotifier();
  if (initialPda != null) {
    pdaNotifier.setPda(initialPda);
  }
  final examplesDataSource = _FakePdaExamplesDataSource();
  final output = _RecordingHighlightChannel();
  final coordinator = CanvasHighlightCoordinator(
    target: CanvasHighlightTarget(
      kind: AutomatonSurfaceKind.pda,
      surface: Object(),
      documentId: initialPda?.id,
      revision: 0,
    ),
    output: output,
  );
  addTearDown(coordinator.dispose);

  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        pdaEditorProvider.overrideWith((ref) => pdaNotifier),
        canvasHighlightCoordinatorProvider.overrideWithValue(coordinator),
      ],
      child: MaterialApp(
        home: Scaffold(
          body: PDAAlgorithmPanel(
            useExpanded: false,
            examplesDataSource: examplesDataSource,
          ),
        ),
      ),
    ),
  );

  await tester.pump();
  await _pumpUntilFound(tester, find.text('APD - Palíndromo'));

  return _PdaPanelHarness(
    notifier: pdaNotifier,
    output: output,
    coordinator: coordinator,
  );
}

AssetExample<PDA> _buildPdaExample() {
  final start = automaton_state.State(
    id: 'pda/state:start',
    label: 'q0',
    position: Vector2.zero(),
    isInitial: true,
  );
  final accept = automaton_state.State(
    id: 'pda/state:accept',
    label: 'q1',
    position: Vector2(120, 0),
    isAccepting: true,
  );
  final transition = PDATransition(
    id: 't0',
    fromState: start,
    toState: accept,
    label: 'a,Z/Z',
    type: TransitionType.deterministic,
    inputSymbol: 'a',
    popSymbol: 'Z',
    pushSymbol: 'Z',
  );
  final pda = PDA(
    id: 'pda-palindrome',
    name: 'APD - Palíndromo',
    states: {start, accept},
    transitions: {transition},
    alphabet: const {'a'},
    initialState: start,
    acceptingStates: {accept},
    created: DateTime(2026),
    modified: DateTime(2026),
    bounds: const math.Rectangle(0, 0, 400, 300),
    stackAlphabet: const {'Z'},
    initialStackSymbol: 'Z',
  );

  return AssetExample<PDA>(
    name: pda.name,
    description: 'Fake PDA example for widget tests',
    category: ExampleCategory.pda,
    difficultyLevel: DifficultyLevel.easy,
    complexityLevel: ExampleComplexityLevel.low,
    tags: const ['test'],
    payload: pda,
  );
}

PDA _buildNondeterministicPda() {
  final start = automaton_state.State(
    id: 'pda/state:start',
    label: 'Displayed start',
    position: Vector2.zero(),
    isInitial: true,
  );
  final first = automaton_state.State(
    id: 'pda/state:first',
    label: 'Displayed first',
    position: Vector2(120, 0),
    isAccepting: true,
  );
  final second = automaton_state.State(
    id: 'pda/state:second',
    label: 'Displayed second',
    position: Vector2(120, 120),
  );
  final firstTransition = PDATransition(
    id: 'opaque/pda-edge-a',
    fromState: start,
    toState: first,
    label: 'a, Z/Z',
    inputSymbol: 'a',
    popSymbol: 'Z',
    pushSymbol: 'Z',
  );
  // Whitespace is intentional: transition identifiers must not be trimmed.
  final secondTransition = PDATransition(
    id: ' opaque/pda-edge-b ',
    fromState: start,
    toState: second,
    label: 'a, Z/A',
    inputSymbol: 'a',
    popSymbol: 'Z',
    pushSymbol: 'A',
  );
  return PDA(
    id: 'pda-nondeterministic',
    name: 'Nondeterministic PDA',
    states: {start, first, second},
    transitions: {firstTransition, secondTransition},
    alphabet: const {'a'},
    initialState: start,
    acceptingStates: {first},
    created: DateTime(2026),
    modified: DateTime(2026),
    bounds: const math.Rectangle(0, 0, 400, 300),
    stackAlphabet: const {'Z', 'A'},
    initialStackSymbol: 'Z',
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

Future<void> _pumpUntilHighlightEvent(
  WidgetTester tester,
  _RecordingHighlightChannel output,
  int previousEventCount,
) async {
  for (var attempt = 0; attempt < 80; attempt++) {
    if (output.events.length > previousEventCount) {
      return;
    }
    await tester.pump(const Duration(milliseconds: 50));
  }
  fail('Timed out waiting for an analysis highlight event.');
}

Future<void> _pumpUntilPdaLoaded(
  WidgetTester tester,
  PDAEditorNotifier pdaNotifier,
) async {
  for (var attempt = 0; attempt < 80; attempt++) {
    if (pdaNotifier.state.pda != null) {
      return;
    }
    await tester.pump(const Duration(milliseconds: 50));
  }
  fail('Timed out waiting for PDA example to load');
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('shows empty results before running an analysis', (tester) async {
    await _pumpPdaAlgorithmPanel(tester);

    expect(find.text('No analysis results yet'), findsOneWidget);
    expect(
      find.text('Select an algorithm above to analyze your PDA'),
      findsOneWidget,
    );
  });

  testWidgets('renders PDA actions through AlgorithmButton', (tester) async {
    await _pumpPdaAlgorithmPanel(tester);

    expect(find.byType(AlgorithmButton), findsNWidgets(6));
    expect(find.text('Convert to CFG'), findsOneWidget);
    expect(find.text('Minimize PDA'), findsOneWidget);
    expect(find.text('Check Determinism'), findsOneWidget);
    expect(find.text('Find Reachable States'), findsOneWidget);
    expect(find.text('Language Analysis'), findsOneWidget);
    expect(find.text('Stack Operations'), findsOneWidget);
  });

  testWidgets('PDA action still reports missing editor PDA', (tester) async {
    await _pumpPdaAlgorithmPanel(tester);

    await tester.ensureVisible(find.text('Convert to CFG'));
    await tester.pump();

    await tester.tap(find.text('Convert to CFG'));
    await tester.pump(const Duration(milliseconds: 100));

    expect(
      find.text('Draw a PDA before converting to a grammar.'),
      findsOneWidget,
    );
  });

  testWidgets('loads PDA examples from the configured catalog into the editor',
      (
    tester,
  ) async {
    final harness = await _pumpPdaAlgorithmPanel(tester);

    expect(find.text('APD - Palíndromo'), findsOneWidget);

    await tester.tap(find.text('APD - Palíndromo'));
    await _pumpUntilPdaLoaded(tester, harness.notifier);

    final pda = harness.notifier.state.pda;
    expect(pda, isNotNull);
    expect(pda!.name, equals('APD - Palíndromo'));
    expect(pda.pdaTransitions, isNotEmpty);
    expect(pda.initialStackSymbol, equals('Z'));
  });

  testWidgets('reachable-state analysis emits stable PDA state ids', (
    tester,
  ) async {
    final pda = _buildPdaExample().payload;
    final harness = await _pumpPdaAlgorithmPanel(
      tester,
      initialPda: pda,
    );

    final previousEventCount = harness.output.events.length;
    await tester.ensureVisible(find.text('Find Reachable States'));
    await tester.tap(find.text('Find Reachable States'));
    await _pumpUntilHighlightEvent(
      tester,
      harness.output,
      previousEventCount,
    );

    expect(harness.output.events, isNotEmpty);
    expect(harness.output.events.last!.stateIds, {
      'pda/state:start',
      'pda/state:accept',
    });
    expect(harness.output.events.last!.stateIds, isNot(contains('q0')));
  });

  testWidgets('determinism analysis emits exact conflicting PDA edge ids', (
    tester,
  ) async {
    final pda = _buildNondeterministicPda();
    final harness = await _pumpPdaAlgorithmPanel(
      tester,
      initialPda: pda,
    );

    final previousEventCount = harness.output.events.length;
    await tester.ensureVisible(find.text('Check Determinism'));
    await tester.tap(find.text('Check Determinism'));
    await _pumpUntilHighlightEvent(
      tester,
      harness.output,
      previousEventCount,
    );

    expect(harness.output.events, isNotEmpty);
    expect(harness.output.events.last!.transitionIds, {
      'opaque/pda-edge-a',
      ' opaque/pda-edge-b ',
    });
  });

  testWidgets('disposing an analysis panel restores validation highlight', (
    tester,
  ) async {
    final pda = _buildPdaExample().payload;
    final harness = await _pumpPdaAlgorithmPanel(
      tester,
      initialPda: pda,
    );
    final validation = harness.coordinator.source(
      CanvasHighlightSource.validation,
    );
    addTearDown(validation.dispose);
    final warning = SimulationHighlight(
      transitionIds: const {'persistent-warning'},
    );
    validation.send(warning);

    final previousEventCount = harness.output.events.length;
    await tester.ensureVisible(find.text('Find Reachable States'));
    await tester.tap(find.text('Find Reachable States'));
    await _pumpUntilHighlightEvent(
      tester,
      harness.output,
      previousEventCount,
    );
    expect(harness.output.events.last!.stateIds, isNotEmpty);

    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump();

    expect(harness.output.events.last, warning);
  });
}
