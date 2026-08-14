import 'dart:math' as math;

import 'package:flutter_test/flutter_test.dart';
import 'package:turing_lab/core/models/automaton.dart';
import 'package:turing_lab/core/models/fsa.dart';
import 'package:turing_lab/core/models/fsa_transition.dart';
import 'package:turing_lab/core/models/pda.dart';
import 'package:turing_lab/core/models/pda_transition.dart';
import 'package:turing_lab/core/models/serialized_state_resolver.dart';
import 'package:turing_lab/core/models/state.dart' as automaton_state;
import 'package:turing_lab/core/models/tm.dart';
import 'package:turing_lab/core/models/tm_transition.dart';
import 'package:vector_math/vector_math_64.dart';

void main() {
  group('Automaton JSON round trips', () {
    test('loads FSA transitions saved with endpoint ids', () {
      final q0 = _state('q0', isInitial: true);
      final q1 = _state('q1', x: 120, isAccepting: true);
      final automaton = FSA(
        id: 'fsa_json',
        name: 'FSA JSON',
        states: {q0, q1},
        transitions: {
          FSATransition(
            id: 't0',
            fromState: q0,
            toState: q1,
            inputSymbols: const {'a'},
          ),
        },
        alphabet: const {'a'},
        initialState: q0,
        acceptingStates: {q1},
        created: DateTime.utc(2026, 1, 1),
        modified: DateTime.utc(2026, 1, 1),
        bounds: const math.Rectangle<double>(0, 0, 400, 300),
        panOffset: Vector2.zero(),
      );

      final loaded = Automaton.fromJson(automaton.toJson()) as FSA;
      final transition = loaded.transitions.whereType<FSATransition>().single;
      final loadedQ0 = loaded.states.singleWhere((state) => state.id == 'q0');
      final loadedQ1 = loaded.states.singleWhere((state) => state.id == 'q1');

      expect(transition.fromState, same(loadedQ0));
      expect(transition.toState, same(loadedQ1));
      expect(transition.inputSymbols, equals({'a'}));
    });

    test('rejects FSA transition endpoint ids missing from statesById', () {
      final q0 = _state('q0', isInitial: true);
      final q1 = _state('q1', x: 120, isAccepting: true);
      final transition = FSATransition(
        id: 't0',
        fromState: q0,
        toState: q1,
        inputSymbols: const {'a'},
      );

      expect(
        () => FSATransition.fromJson(
          transition.toJson(),
          statesById: {q0.id: q0},
        ),
        throwsA(isA<ArgumentError>()),
      );
    });

    test('caches explicitly synthesized serialized states', () {
      final statesById = <String, automaton_state.State>{};

      final first = resolveSerializedState(
        'missing',
        statesById,
        'fromState',
        'test',
        createMissingStateIds: true,
      );
      final second = resolveSerializedState(
        'missing',
        statesById,
        'fromState',
        'test',
        createMissingStateIds: true,
      );

      expect(statesById['missing'], same(first));
      expect(second, same(first));
    });

    test('loads PDA transitions saved with endpoint ids', () {
      final q0 = _state('q0', isInitial: true);
      final q1 = _state('q1', x: 120, isAccepting: true);
      final automaton = PDA(
        id: 'pda_json',
        name: 'PDA JSON',
        states: {q0, q1},
        transitions: {
          PDATransition(
            id: 't0',
            fromState: q0,
            toState: q1,
            label: 'a, Z/Z',
            inputSymbol: 'a',
            popSymbol: 'Z',
            pushSymbol: 'Z',
          ),
        },
        alphabet: const {'a'},
        initialState: q0,
        acceptingStates: {q1},
        created: DateTime.utc(2026, 1, 1),
        modified: DateTime.utc(2026, 1, 1),
        bounds: const math.Rectangle<double>(0, 0, 400, 300),
        panOffset: Vector2.zero(),
        stackAlphabet: const {'Z'},
        initialStackSymbol: 'Z',
      );

      final loaded = Automaton.fromJson(automaton.toJson()) as PDA;
      final transition = loaded.transitions.whereType<PDATransition>().single;
      final loadedQ0 = loaded.states.singleWhere((state) => state.id == 'q0');
      final loadedQ1 = loaded.states.singleWhere((state) => state.id == 'q1');

      expect(transition.fromState, same(loadedQ0));
      expect(transition.toState, same(loadedQ1));
      expect(transition.inputSymbol, equals('a'));
      expect(transition.popSymbol, equals('Z'));
      expect(transition.pushSymbol, equals('Z'));
    });

    test('loads TM transitions saved with endpoint ids', () {
      final q0 = _state('q0', isInitial: true);
      final q1 = _state('q1', x: 120, isAccepting: true);
      final machine = _tm(q0, q1);

      final json = machine.toJson();
      final transitionJson = (json['transitions'] as List).single as Map;
      expect(transitionJson['fromState'], 'q0');
      expect(transitionJson['toState'], 'q1');

      final loaded = TM.fromJson(json);
      final transition = loaded.tmTransitions.single;
      final loadedQ0 = loaded.states.singleWhere((state) => state.id == 'q0');
      final loadedQ1 = loaded.states.singleWhere((state) => state.id == 'q1');

      expect(transition.fromState, same(loadedQ0));
      expect(transition.toState, same(loadedQ1));
    });

    test('canonicalizes legacy nested TM transition endpoints', () {
      final q0 = _state('q0', isInitial: true);
      final q1 = _state('q1', x: 120, isAccepting: true);
      final json = _tm(q0, q1).toJson();
      final transitionJson =
          ((json['transitions'] as List).single as Map).cast<String, dynamic>();
      transitionJson['fromState'] = q0.toJson();
      transitionJson['toState'] = q1.toJson();

      final loaded = TM.fromJson(json);
      final transition = loaded.tmTransitions.single;

      expect(
        transition.fromState,
        same(loaded.states.singleWhere((state) => state.id == 'q0')),
      );
      expect(
        transition.toState,
        same(loaded.states.singleWhere((state) => state.id == 'q1')),
      );
    });

    test('rejects TM transition endpoint ids missing from statesById', () {
      final q0 = _state('q0', isInitial: true);
      final q1 = _state('q1', x: 120, isAccepting: true);
      final transition = _tm(q0, q1).tmTransitions.single;

      expect(
        () => TMTransition.fromJson(
          transition.toJson(),
          statesById: {q0.id: q0},
        ),
        throwsA(isA<ArgumentError>()),
      );
    });
  });
}

TM _tm(automaton_state.State q0, automaton_state.State q1) {
  return TM(
    id: 'tm_json',
    name: 'TM JSON',
    states: {q0, q1},
    transitions: {
      TMTransition(
        id: 't0',
        fromState: q0,
        toState: q1,
        label: '1/0,R',
        readSymbol: '1',
        writeSymbol: '0',
        direction: TapeDirection.right,
      ),
    },
    alphabet: const {'1'},
    initialState: q0,
    acceptingStates: {q1},
    created: DateTime.utc(2026, 1, 1),
    modified: DateTime.utc(2026, 1, 1),
    bounds: const math.Rectangle<double>(0, 0, 400, 300),
    panOffset: Vector2.zero(),
    tapeAlphabet: const {'0', '1', 'B'},
    blankSymbol: 'B',
  );
}

automaton_state.State _state(
  String id, {
  double x = 0,
  bool isInitial = false,
  bool isAccepting = false,
}) {
  return automaton_state.State(
    id: id,
    label: id,
    position: Vector2(x, 0),
    isInitial: isInitial,
    isAccepting: isAccepting,
  );
}
