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

  testWidgets('renders TM actions through AlgorithmButton', (tester) async {
    await _pumpTmAlgorithmPanel(tester);

    expect(find.byType(AlgorithmButton), findsNWidgets(6));
    expect(find.text('Check Decidability'), findsOneWidget);
    expect(find.text('Find Reachable States'), findsOneWidget);
    expect(find.text('Language Analysis'), findsOneWidget);
    expect(find.text('Tape Operations'), findsOneWidget);
    expect(find.text('Time Characteristics'), findsOneWidget);
    expect(find.text('Space Characteristics'), findsOneWidget);
  });

  testWidgets('TM action still reports missing editor TM', (tester) async {
    await _pumpTmAlgorithmPanel(tester);

    await tester.ensureVisible(find.text('Check Decidability'));
    await tester.pump();

    await tester.tap(find.text('Check Decidability'));
    await tester.pump();

    expect(
      find.text(
        'No Turing machine available. Draw states and transitions on the canvas to analyze.',
      ),
      findsOneWidget,
    );
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

    await tester.ensureVisible(find.text('Find Reachable States'));
    await tester.tap(find.text('Find Reachable States'));
    await tester.pump();

    expect(harness.output.events, isNotEmpty);
    expect(harness.output.events.last!.stateIds, {
      'tm/state:start',
      'tm/state:accept',
    });
    expect(harness.output.events.last!.stateIds, isNot(contains('q0')));
  });
}
