//
//  automaton_state_update_automaton_test.dart
//  Turing Lab
//
//  Unit tests for AutomatonStateNotifier.updateAutomaton.
//

import 'dart:math' as math;

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vector_math/vector_math_64.dart';

import 'package:turing_lab/core/models/fsa.dart';
import 'package:turing_lab/core/models/state.dart' as automaton_state;
import 'package:turing_lab/presentation/providers/automaton_state_provider.dart';

void main() {
  group('AutomatonStateNotifier', () {
    late ProviderContainer container;

    setUp(() {
      container = ProviderContainer(
        overrides: [
          automatonStateProvider.overrideWith((ref) {
            return AutomatonStateNotifier();
          }),
        ],
      );
    });

    tearDown(() {
      container.dispose();
    });

    test('createAutomaton builds an initial FSA with sequential ids', () async {
      final notifier = container.read(automatonStateProvider.notifier);

      await notifier.createAutomaton(
        name: 'First DFA',
        alphabet: const ['a', 'b'],
      );

      var state = container.read(automatonStateProvider);
      var automaton = state.currentAutomaton!;
      expect(state.isLoading, isFalse);
      expect(state.error, isNull);
      expect(automaton.id, '1');
      expect(automaton.name, 'First DFA');
      expect(automaton.alphabet, {'a', 'b'});
      expect(automaton.states, hasLength(1));
      expect(automaton.initialState?.id, 'q0');
      expect(automaton.initialState?.position, Vector2(100, 100));
      expect(automaton.acceptingStates, isEmpty);

      await notifier.createAutomaton(
        name: 'Second DFA',
        alphabet: const ['0'],
      );

      state = container.read(automatonStateProvider);
      automaton = state.currentAutomaton!;
      expect(automaton.id, '2');
      expect(automaton.name, 'Second DFA');
      expect(automaton.alphabet, {'0'});
    });

    test('createAutomaton reports empty-name failures', () async {
      final notifier = container.read(automatonStateProvider.notifier);

      await notifier.createAutomaton(name: '', alphabet: const ['a']);

      final state = container.read(automatonStateProvider);
      expect(state.currentAutomaton, isNull);
      expect(state.isLoading, isFalse);
      expect(state.error, contains('Automaton name cannot be empty'));
    });

    test('updateAutomaton sets currentAutomaton to the provided automaton', () {
      final notifier = container.read(automatonStateProvider.notifier);

      final q0 = automaton_state.State(
        id: 'q0',
        label: 'q0',
        position: Vector2.zero(),
        isInitial: true,
        isAccepting: true,
      );

      final automaton = FSA(
        id: 'dfa-test',
        name: 'DFA Test',
        states: {q0},
        transitions: const {},
        alphabet: const {'a'},
        initialState: q0,
        acceptingStates: {q0},
        created: DateTime(2026, 1, 1),
        modified: DateTime(2026, 1, 1),
        bounds: const math.Rectangle(0, 0, 400, 300),
      );

      expect(container.read(automatonStateProvider).currentAutomaton, isNull);

      notifier.updateAutomaton(automaton);

      final state = container.read(automatonStateProvider);
      expect(state.currentAutomaton, isNotNull);
      expect(state.currentAutomaton!.id, 'dfa-test');
      expect(state.currentAutomaton, same(automaton));
    });
  });
}
