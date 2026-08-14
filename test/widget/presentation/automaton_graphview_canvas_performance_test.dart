import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vector_math/vector_math_64.dart';

import 'package:turing_lab/core/models/fsa.dart';
import 'package:turing_lab/core/models/fsa_transition.dart';
import 'package:turing_lab/core/models/pda.dart';
import 'package:turing_lab/core/models/pda_transition.dart';
import 'package:turing_lab/core/models/simulation_highlight.dart';
import 'package:turing_lab/core/models/state.dart' as automaton_state;
import 'package:turing_lab/core/models/tm.dart';
import 'package:turing_lab/core/models/tm_transition.dart';
import 'package:turing_lab/features/canvas/graphview/graphview_canvas_controller.dart';
import 'package:turing_lab/features/canvas/graphview/graphview_pda_canvas_controller.dart';
import 'package:turing_lab/features/canvas/graphview/graphview_tm_canvas_controller.dart';
import 'package:turing_lab/presentation/providers/automaton_state_provider.dart';
import 'package:turing_lab/presentation/providers/pda_editor_provider.dart';
import 'package:turing_lab/presentation/providers/tm_editor_provider.dart';
import 'package:turing_lab/presentation/widgets/automaton_graphview_canvas.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('AutomatonGraphViewCanvas performance', () {
    test('SimulationHighlight compares by set contents', () {
      final first = SimulationHighlight(
        stateIds: {'q1', 'q2'},
        transitionIds: {'t1'},
      );
      final second = SimulationHighlight(
        stateIds: {'q2', 'q1'},
        transitionIds: {'t1'},
      );
      final different = SimulationHighlight(
        stateIds: {'q2'},
        transitionIds: {'t1'},
      );

      expect(first, equals(second));
      expect(first.hashCode, equals(second.hashCode));
      expect(first, isNot(equals(different)));
    });

    test('large DFA/NFA/PDA/TM synchronization stays bounded', () {
      final fsaNotifier = AutomatonStateNotifier();
      final dfaController = GraphViewCanvasController(
        automatonStateNotifier: fsaNotifier,
      );
      final nfaController = GraphViewCanvasController(
        automatonStateNotifier: fsaNotifier,
      );
      final pdaNotifier = PDAEditorNotifier();
      final pdaController = GraphViewPdaCanvasController(
        editorNotifier: pdaNotifier,
      );
      final tmNotifier = TMEditorNotifier();
      final tmController = GraphViewTmCanvasController(
        editorNotifier: tmNotifier,
      );

      addTearDown(() {
        dfaController.dispose();
        nfaController.dispose();
        pdaController.dispose();
        tmController.dispose();
      });

      final dfa = _createLargeDfa(400);
      final nfa = _createLargeNfa(400);
      final pda = _createLargePda(300);
      final tm = _createLargeTm(300);

      final dfaTime =
          _measureMilliseconds(() => dfaController.synchronize(dfa));
      final nfaTime =
          _measureMilliseconds(() => nfaController.synchronize(nfa));
      final pdaTime =
          _measureMilliseconds(() => pdaController.synchronize(pda));
      final tmTime = _measureMilliseconds(() => tmController.synchronize(tm));

      print(
        'Synchronize benchmark: '
        'DFA=${dfaTime.toStringAsFixed(1)}ms, '
        'NFA=${nfaTime.toStringAsFixed(1)}ms, '
        'PDA=${pdaTime.toStringAsFixed(1)}ms, '
        'TM=${tmTime.toStringAsFixed(1)}ms',
      );

      expect(dfaTime, lessThan(200.0));
      expect(nfaTime, lessThan(200.0));
      expect(pdaTime, lessThan(220.0));
      expect(tmTime, lessThan(220.0));
    });

    test('identical highlight dispatch does not notify twice', () {
      final notifier = AutomatonStateNotifier();
      final controller = GraphViewCanvasController(
        automatonStateNotifier: notifier,
      );
      addTearDown(controller.dispose);

      final automaton = _createLargeNfa(120);
      controller.synchronize(automaton);

      var notifications = 0;
      controller.highlightNotifier.addListener(() {
        notifications++;
      });

      final highlight = SimulationHighlight(
        stateIds: {'q10'},
        transitionIds: {'t10_primary'},
      );

      controller.applyHighlight(highlight);
      controller.applyHighlight(
        SimulationHighlight(
          stateIds: {'q10'},
          transitionIds: {'t10_primary'},
        ),
      );

      expect(notifications, equals(1));
    });

    testWidgets('rapid highlight cycling stays within frame budget', (
      tester,
    ) async {
      final notifier = AutomatonStateNotifier();
      final controller = GraphViewCanvasController(
        automatonStateNotifier: notifier,
      );
      addTearDown(controller.dispose);

      final automaton = _createLargeNfa(240);
      final states = automaton.states.toList(growable: false);
      final transitions = automaton.fsaTransitions.toList(growable: false);

      notifier.updateAutomaton(automaton);
      controller.synchronize(automaton);

      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            home: Scaffold(
              body: AutomatonGraphViewCanvas(
                automaton: automaton,
                canvasKey: GlobalKey(),
                controller: controller,
              ),
            ),
          ),
        ),
      );
      await tester.pump();

      const cycleCount = 45;
      final stopwatch = Stopwatch()..start();
      for (var index = 0; index < cycleCount; index++) {
        controller.applyHighlight(
          SimulationHighlight(
            stateIds: {states[index].id},
            transitionIds: {transitions[index].id},
          ),
        );
        await tester.pump();
      }
      stopwatch.stop();

      controller.clearHighlight();
      await tester.pump();

      final averageCycleMs =
          stopwatch.elapsedMicroseconds / cycleCount / 1000.0;
      print(
        'Highlight benchmark (240-state NFA): '
        '${averageCycleMs.toStringAsFixed(2)}ms/cycle',
      );

      expect(
        averageCycleMs,
        lessThan(80.0),
        reason:
            'Highlight playback should stay below 80ms per cycle in widget tests',
      );
    });
  });
}

double _measureMilliseconds(void Function() action) {
  final stopwatch = Stopwatch()..start();
  action();
  stopwatch.stop();
  return stopwatch.elapsedMicroseconds / 1000.0;
}

FSA _createLargeDfa(int stateCount) {
  final states = _createStates(stateCount);
  final transitions = <FSATransition>{};

  for (var index = 0; index < states.length; index++) {
    final current = states[index];
    final next = states[(index + 1) % states.length];

    transitions.add(
      FSATransition(
        id: 't${index}_primary',
        fromState: current,
        toState: next,
        symbol: 'a',
      ),
    );
    transitions.add(
      FSATransition(
        id: 't${index}_self',
        fromState: current,
        toState: current,
        symbol: 'b',
      ),
    );
  }

  return FSA(
    id: 'large-dfa-$stateCount',
    name: 'Large DFA $stateCount',
    states: states.toSet(),
    transitions: transitions,
    alphabet: const {'a', 'b'},
    initialState: states.first,
    acceptingStates: {states.last},
    created: DateTime.utc(2026, 4, 23),
    modified: DateTime.utc(2026, 4, 23),
    bounds: const math.Rectangle<double>(0, 0, 4000, 4000),
    zoomLevel: 1.0,
    panOffset: Vector2.zero(),
  );
}

FSA _createLargeNfa(int stateCount) {
  final states = _createStates(stateCount);
  final transitions = <FSATransition>{};

  for (var index = 0; index < states.length; index++) {
    final current = states[index];
    final next = states[(index + 1) % states.length];
    final alternate = states[(index + 7) % states.length];

    transitions.add(
      FSATransition(
        id: 't${index}_primary',
        fromState: current,
        toState: next,
        symbol: 'a',
      ),
    );
    transitions.add(
      FSATransition(
        id: 't${index}_alternate',
        fromState: current,
        toState: alternate,
        symbol: 'a',
      ),
    );
    transitions.add(
      FSATransition.epsilon(
        id: 't${index}_epsilon',
        fromState: current,
        toState: states[(index + 13) % states.length],
      ),
    );
  }

  return FSA(
    id: 'large-nfa-$stateCount',
    name: 'Large NFA $stateCount',
    states: states.toSet(),
    transitions: transitions,
    alphabet: const {'a'},
    initialState: states.first,
    acceptingStates: {states.last},
    created: DateTime.utc(2026, 4, 23),
    modified: DateTime.utc(2026, 4, 23),
    bounds: const math.Rectangle<double>(0, 0, 5000, 5000),
    zoomLevel: 1.0,
    panOffset: Vector2.zero(),
  );
}

PDA _createLargePda(int stateCount) {
  final states = _createStates(stateCount);
  final transitions = <PDATransition>{};

  for (var index = 0; index < states.length; index++) {
    final current = states[index];
    final next = states[(index + 1) % states.length];
    final alternate = states[(index + 5) % states.length];

    transitions.add(
      PDATransition(
        id: 'p${index}_push',
        fromState: current,
        toState: next,
        label: 'a,Z→AZ',
        inputSymbol: 'a',
        popSymbol: 'Z',
        pushSymbol: 'AZ',
      ),
    );
    transitions.add(
      PDATransition(
        id: 'p${index}_pop',
        fromState: current,
        toState: alternate,
        label: 'b,A→ε',
        inputSymbol: 'b',
        popSymbol: 'A',
        pushSymbol: '',
        isLambdaPush: true,
      ),
    );
  }

  return PDA(
    id: 'large-pda-$stateCount',
    name: 'Large PDA $stateCount',
    states: states.toSet(),
    transitions: transitions,
    alphabet: const {'a', 'b'},
    initialState: states.first,
    acceptingStates: {states.last},
    created: DateTime.utc(2026, 4, 23),
    modified: DateTime.utc(2026, 4, 23),
    bounds: const math.Rectangle<double>(0, 0, 5000, 5000),
    zoomLevel: 1.0,
    panOffset: Vector2.zero(),
    stackAlphabet: const {'Z', 'A'},
    initialStackSymbol: 'Z',
  );
}

TM _createLargeTm(int stateCount) {
  final states = _createStates(stateCount);
  final transitions = <TMTransition>{};

  for (var index = 0; index < states.length; index++) {
    final current = states[index];
    final next = states[(index + 1) % states.length];
    final alternate = states[(index + 9) % states.length];

    transitions.add(
      TMTransition(
        id: 'm${index}_forward',
        fromState: current,
        toState: next,
        label: '0→1,R',
        readSymbol: '0',
        writeSymbol: '1',
        direction: TapeDirection.right,
      ),
    );
    transitions.add(
      TMTransition(
        id: 'm${index}_rewind',
        fromState: current,
        toState: alternate,
        label: '1→0,L',
        readSymbol: '1',
        writeSymbol: '0',
        direction: TapeDirection.left,
      ),
    );
  }

  return TM(
    id: 'large-tm-$stateCount',
    name: 'Large TM $stateCount',
    states: states.toSet(),
    transitions: transitions,
    alphabet: const {'0', '1'},
    initialState: states.first,
    acceptingStates: {states.last},
    created: DateTime.utc(2026, 4, 23),
    modified: DateTime.utc(2026, 4, 23),
    bounds: const math.Rectangle<double>(0, 0, 5000, 5000),
    zoomLevel: 1.0,
    panOffset: Vector2.zero(),
    tapeAlphabet: const {'0', '1', 'B'},
    blankSymbol: 'B',
  );
}

List<automaton_state.State> _createStates(int count) {
  final states = <automaton_state.State>[];
  final columns = math.max(1, math.sqrt(count).ceil());

  for (var index = 0; index < count; index++) {
    final row = index ~/ columns;
    final column = index % columns;
    states.add(
      automaton_state.State(
        id: 'q$index',
        label: 'q$index',
        position: Vector2(
          80 + (column * 140.0),
          80 + (row * 120.0),
        ),
        isInitial: index == 0,
        isAccepting: index == count - 1,
      ),
    );
  }

  return states;
}
