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
  });
}
