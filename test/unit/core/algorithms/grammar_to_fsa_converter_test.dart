import 'package:flutter_test/flutter_test.dart';
import 'package:turing_lab/core/algorithms/automaton_simulator.dart';
import 'package:turing_lab/core/algorithms/grammar_to_fsa_converter.dart';
import 'package:turing_lab/core/models/fsa_transition.dart';
import 'package:turing_lab/core/models/grammar.dart';
import 'package:turing_lab/core/models/production.dart';

void main() {
  group('GrammarToFSAConverter', () {
    test(
      'keeps transition endpoints canonical when a state becomes accepting',
      () async {
        final now = DateTime.utc(2024, 1, 1);
        final grammar = Grammar(
          id: 'a_star',
          name: 'a star',
          terminals: const {'a'},
          nonterminals: const {'S'},
          startSymbol: 'S',
          productions: {
            const Production(
              id: 'p0',
              leftSide: ['S'],
              rightSide: ['a', 'S'],
              order: 0,
            ),
            const Production(
              id: 'p1',
              leftSide: ['S'],
              rightSide: [],
              isLambda: true,
              order: 1,
            ),
          },
          type: GrammarType.regular,
          created: now,
          modified: now,
        );

        final result = GrammarToFSAConverter.convert(grammar);

        expect(result.isSuccess, isTrue);
        final fsa = result.data!;
        final start = fsa.initialState!;
        final loop = fsa.transitions.whereType<FSATransition>().single;
        expect(start.isAccepting, isTrue);
        expect(loop.fromState, equals(start));
        expect(loop.toState, equals(start));

        final emptyResult = await AutomatonSimulator.simulateNFA(fsa, '');
        final aResult = await AutomatonSimulator.simulateNFA(fsa, 'a');
        final aaaResult = await AutomatonSimulator.simulateNFA(fsa, 'aaa');

        expect(emptyResult.isSuccess, isTrue);
        expect(aResult.isSuccess, isTrue);
        expect(aaaResult.isSuccess, isTrue);
        expect(emptyResult.data!.accepted, isTrue);
        expect(aResult.data!.accepted, isTrue);
        expect(aaaResult.data!.accepted, isTrue);
      },
    );

    test('converts an epsilon-derived unit production to an epsilon edge',
        () async {
      final now = DateTime.utc(2024, 1, 1);
      final grammar = Grammar(
        id: 'epsilon-unit',
        name: 'Epsilon unit',
        terminals: const {'a'},
        nonterminals: const {'S', 'A'},
        startSymbol: 'S',
        productions: {
          const Production(
            id: 'p0',
            leftSide: ['S'],
            rightSide: ['A'],
            order: 0,
          ),
          const Production(
            id: 'p1',
            leftSide: ['A'],
            rightSide: ['a', 'A'],
            order: 1,
          ),
          const Production(
            id: 'p2',
            leftSide: ['A'],
            rightSide: [],
            isLambda: true,
            order: 2,
          ),
        },
        type: GrammarType.regular,
        created: now,
        modified: now,
      );

      final result = GrammarToFSAConverter.convert(grammar);

      expect(result.isSuccess, isTrue);
      expect(
        result.data!.fsaTransitions.any((transition) =>
            transition.fromState.id == 'S' &&
            transition.toState.id == 'A' &&
            transition.isEpsilonTransition),
        isTrue,
      );
      final empty = await AutomatonSimulator.simulateNFA(result.data!, '');
      final repeated =
          await AutomatonSimulator.simulateNFA(result.data!, 'aaa');
      expect(empty.data!.accepted, isTrue);
      expect(repeated.data!.accepted, isTrue);
    });

    test('converts a production-free regular grammar as the empty language',
        () async {
      final now = DateTime.utc(2024, 1, 1);
      final grammar = Grammar(
        id: 'empty-language',
        name: 'Empty language',
        terminals: const {'a'},
        nonterminals: const {'S'},
        startSymbol: 'S',
        productions: const {},
        type: GrammarType.regular,
        created: now,
        modified: now,
      );

      final result = GrammarToFSAConverter.convert(grammar);

      expect(result.isSuccess, isTrue);
      expect(result.data!.states, hasLength(1));
      expect(result.data!.transitions, isEmpty);
      expect(result.data!.acceptingStates, isEmpty);
      final empty = await AutomatonSimulator.simulateNFA(result.data!, '');
      final symbol = await AutomatonSimulator.simulateNFA(result.data!, 'a');
      expect(empty.data!.accepted, isFalse);
      expect(symbol.data!.accepted, isFalse);
    });
  });
}
