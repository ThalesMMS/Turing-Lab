import 'dart:convert';
import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vector_math/vector_math_64.dart';

import 'package:turing_lab/core/models/fsa.dart';
import 'package:turing_lab/core/models/fsa_transition.dart';
import 'package:turing_lab/core/models/nfa_computation_tree.dart';
import 'package:turing_lab/core/models/nfa_path_node.dart';
import 'package:turing_lab/core/models/simulation_result.dart';
import 'package:turing_lab/core/models/state.dart' as automaton_models;
import 'package:turing_lab/core/services/simulation_highlight_service.dart';
import 'package:turing_lab/presentation/widgets/simulation_panel.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('FSA computation branch integration', () {
    for (final (width, layoutKey) in [
      (320.0, 'computation-branch-inspector-narrow'),
      (1000.0, 'computation-branch-inspector-wide'),
    ]) {
      testWidgets('opens the shared inspector at ${width.toInt()} px', (
        tester,
      ) async {
        await _setViewport(tester, width);
        await _pumpPanel(
          tester,
          result: _branchingResult(),
          stateLabels: const {
            'q0-id': 'q0',
            'q1-id': 'q1',
            'q2-id': 'q2',
          },
        );

        await _openInspector(tester);

        expect(find.byKey(ValueKey(layoutKey)), findsOneWidget);
        expect(find.text('Computation branches'), findsOneWidget);
        expect(find.textContaining('q0 ·'), findsWidgets);
      });
    }

    testWidgets('opener is semantic, focusable, and keyboard operable', (
      tester,
    ) async {
      await _setViewport(tester, 800);
      final semantics = tester.ensureSemantics();
      var semanticsDisposed = false;
      addTearDown(() {
        if (!semanticsDisposed) semantics.dispose();
      });
      await _pumpPanel(tester, result: _branchingResult());

      final actionFinder = find.byKey(
        const ValueKey('fsa-computation-branches-action'),
      );
      await tester.ensureVisible(actionFinder);
      final action = tester.widget<OutlinedButton>(actionFinder);
      action.focusNode!.requestFocus();
      await tester.pump();

      expect(action.focusNode!.hasFocus, isTrue);
      expect(
        tester
            .getSemantics(actionFinder)
            .getSemanticsData()
            .hasAction(ui.SemanticsAction.tap),
        isTrue,
      );
      expect(
        find.bySemanticsLabel('Inspect computation branches'),
        findsOneWidget,
      );

      await tester.sendKeyEvent(LogicalKeyboardKey.enter);
      await tester.pumpAndSettle();

      expect(find.text('Computation branches'), findsOneWidget);
      expect(
        find.bySemanticsLabel('Hide computation branches'),
        findsOneWidget,
      );
      semantics.dispose();
      semanticsDisposed = true;
    });

    testWidgets('deterministic result explains why no tree is available', (
      tester,
    ) async {
      await _setViewport(tester, 800);
      await _pumpPanel(
        tester,
        result: SimulationResult.success(
          inputString: 'a',
          steps: const [],
          executionTime: Duration.zero,
        ),
        isDeterministic: true,
      );

      await _openInspector(tester);

      expect(find.text('Branch inspection unavailable'), findsOneWidget);
      expect(
        find.text('This execution followed one deterministic path.'),
        findsOneWidget,
      );
    });

    testWidgets('selection and highlighting leave the FSA document unchanged', (
      tester,
    ) async {
      await _setViewport(tester, 800);
      final automaton = _sourceAutomaton();
      final documentSnapshot = jsonEncode(automaton.toJson());
      final result = _branchingResult();
      final resultSnapshot = jsonEncode(result.toJson());
      final highlightService = SimulationHighlightService();
      await _pumpPanel(
        tester,
        result: result,
        highlightService: highlightService,
        stateLabels: {
          for (final state in automaton.states) state.id: state.label,
        },
      );
      await _openInspector(tester);

      final graphSelector = find.byKey(
        const ValueKey('computation-branch-selector'),
      );
      await tester.ensureVisible(graphSelector);
      await tester.tap(graphSelector);
      await tester.pumpAndSettle();
      await tester.tap(find.textContaining('q2 ·').last);
      await tester.pumpAndSettle();

      final highlightAction = find.byKey(
        const ValueKey('computation-branch-highlight'),
      );
      await tester.ensureVisible(highlightAction);
      await tester.tap(highlightAction);
      await tester.pumpAndSettle();

      expect(highlightService.lastHighlight?.stateIds, {'q0-id', 'q2-id'});
      expect(highlightService.lastHighlight?.transitionIds, {'dead-edge'});
      expect(highlightService.lastHighlight?.errorStateIds, {'q2-id'});
      expect(jsonEncode(automaton.toJson()), documentSnapshot);
      expect(jsonEncode(result.toJson()), resultSnapshot);

      await _openInspector(tester);
      expect(highlightService.lastHighlight?.isEmpty ?? true, isTrue);

      await _openInspector(tester);
      await tester.ensureVisible(highlightAction);
      await tester.tap(highlightAction);
      await tester.pumpAndSettle();
      expect(highlightService.lastHighlight?.isEmpty, isFalse);

      await _pumpPanel(
        tester,
        result: null,
        highlightService: highlightService,
        stateLabels: {
          for (final state in automaton.states) state.id: state.label,
        },
      );
      expect(highlightService.lastHighlight?.isEmpty ?? true, isTrue);
      expect(jsonEncode(automaton.toJson()), documentSnapshot);
    });
  });
}

Future<void> _setViewport(WidgetTester tester, double width) async {
  tester.view.devicePixelRatio = 1;
  tester.view.physicalSize = Size(width, 1000);
  addTearDown(tester.view.resetDevicePixelRatio);
  addTearDown(tester.view.resetPhysicalSize);
}

Future<void> _pumpPanel(
  WidgetTester tester, {
  required SimulationResult? result,
  bool isDeterministic = false,
  Map<String, String> stateLabels = const {},
  SimulationHighlightService? highlightService,
}) async {
  await tester.pumpWidget(
    MaterialApp(
      home: Scaffold(
        body: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: SimulationPanel(
              onSimulate: (_) {},
              simulationResult: result,
              isDeterministic: isDeterministic,
              computationStateLabels: stateLabels,
              highlightService: highlightService,
            ),
          ),
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

Future<void> _openInspector(WidgetTester tester) async {
  final action = find.byKey(
    const ValueKey('fsa-computation-branches-action'),
  );
  await tester.ensureVisible(action);
  await tester.tap(action);
  await tester.pumpAndSettle();
}

SimulationResult _branchingResult() {
  const accepting = NFAPathNode(
    currentState: 'q1-id',
    remainingInput: '',
    inputSymbol: 'a',
    transitionUsed: 'δ(q0-id, a) → q1-id',
    transitionIds: ['accepting-edge'],
    stepNumber: 1,
    isAccepting: true,
  );
  const dead = NFAPathNode(
    currentState: 'q2-id',
    remainingInput: '',
    inputSymbol: 'a',
    transitionUsed: 'δ(q0-id, a) → q2-id',
    transitionIds: ['dead-edge'],
    stepNumber: 1,
    isDeadEnd: true,
  );
  const root = NFAPathNode(
    currentState: 'q0-id',
    remainingInput: 'a',
    stepNumber: 0,
    children: [accepting, dead],
  );
  return SimulationResult.success(
    inputString: 'a',
    steps: const [],
    executionTime: Duration.zero,
    computationTree: NFAComputationTree.accepted(
      root: root,
      inputString: 'a',
      totalSteps: 1,
    ),
  );
}

FSA _sourceAutomaton() {
  final q0 = automaton_models.State(
    id: 'q0-id',
    label: 'q0',
    position: Vector2.zero(),
    isInitial: true,
  );
  final q1 = automaton_models.State(
    id: 'q1-id',
    label: 'q1',
    position: Vector2(100, 0),
    isAccepting: true,
  );
  final q2 = automaton_models.State(
    id: 'q2-id',
    label: 'q2',
    position: Vector2(100, 100),
  );
  return FSA(
    id: 'fsa-branch-test',
    name: 'Branch test',
    states: {q0, q1, q2},
    transitions: {
      FSATransition(
        id: 't0',
        fromState: q0,
        toState: q1,
        inputSymbols: const {'a'},
      ),
      FSATransition(
        id: 't1',
        fromState: q0,
        toState: q2,
        inputSymbols: const {'a'},
      ),
    },
    alphabet: const {'a'},
    initialState: q0,
    acceptingStates: {q1},
    created: DateTime.utc(2026),
    modified: DateTime.utc(2026),
    bounds: const math.Rectangle(0, 0, 200, 200),
  );
}
