import 'package:flutter_test/flutter_test.dart';
import 'package:turing_lab/core/algorithms/grammar_to_pda_converter.dart';
import 'package:turing_lab/core/algorithms/pda_simulator.dart';
import 'package:turing_lab/core/models/grammar.dart';
import 'package:turing_lab/core/models/pda_transition.dart';
import 'package:turing_lab/core/models/production.dart';

void main() {
  test('preserves multi-character grammar symbols on the PDA stack', () {
    final grammar = _grammar(
      id: 'multi-symbol',
      nonterminals: {'S_0', 'T_a'},
      terminals: {'token'},
      startSymbol: 'S_0',
      productions: {
        const Production(id: 'p0', leftSide: ['S_0'], rightSide: ['T_a']),
        const Production(id: 'p1', leftSide: ['T_a'], rightSide: ['token']),
      },
    );

    final conversion = GrammarToPDAConverter.convertGrammarToPDAStandard(
      grammar,
    );

    expect(conversion.isSuccess, isTrue);
    final pda = conversion.data!;
    expect(
      pda.validate().where((error) => error.contains('invalid push symbol')),
      isEmpty,
    );
    final initialPush = pda.pdaTransitions.singleWhere(
      (transition) => transition.fromState.id == 'q0',
    );
    expect(initialPush.pushSymbols, ['S_0', 'Z']);
    expect(
      pda.pdaTransitions
          .singleWhere(
            (transition) => transition.popSymbol == 'S_0',
          )
          .pushSymbols,
      ['T_a'],
    );

    final simulation = PDASimulator.simulateNPDA(
      pda,
      'token',
      mode: PDAAcceptanceMode.emptyStack,
    );
    expect(simulation.isSuccess, isTrue);
    expect(simulation.data!.accepted, isTrue);
  });

  test('serializes symbol boundaries and reads legacy character pushes', () {
    final grammar = _grammar(
      id: 'serialization',
      nonterminals: {'S_0'},
      terminals: {'a'},
      startSymbol: 'S_0',
      productions: {
        const Production(id: 'p0', leftSide: ['S_0'], rightSide: ['a']),
      },
    );
    final pda = GrammarToPDAConverter.convert(grammar).data!;
    final transition = pda.pdaTransitions.singleWhere(
      (candidate) => candidate.fromState.id == 'q0',
    );
    final json = transition.toJson();
    final statesById = {for (final state in pda.states) state.id: state};

    expect(json['pushSymbols'], ['S_0', 'Z']);
    expect(
      PDATransition.fromJson(json, statesById: statesById).pushSymbols,
      ['S_0', 'Z'],
    );

    final legacyJson = Map<String, dynamic>.from(json)..remove('pushSymbols');
    expect(
      PDATransition.fromJson(
        legacyJson,
        statesById: statesById,
      ).pushSymbols,
      transition.pushSymbol.split(''),
    );
  });

  test('Greibach conversion consumes the leading terminal of each rule', () {
    final grammar = _grammar(
      id: 'greibach',
      nonterminals: {'S', 'A', 'B'},
      terminals: {'a', 'b'},
      startSymbol: 'S',
      productions: {
        const Production(id: 'p0', leftSide: ['S'], rightSide: ['A', 'B']),
        const Production(id: 'p1', leftSide: ['A'], rightSide: ['a']),
        const Production(id: 'p2', leftSide: ['B'], rightSide: ['b']),
      },
    );

    final standard = GrammarToPDAConverter.convertGrammarToPDAStandard(
      grammar,
    ).data!;
    final greibach = GrammarToPDAConverter.convertGrammarToPDAGreibach(
      grammar,
    );

    expect(greibach.isSuccess, isTrue);
    expect(
      greibach.data!.validate().where(
            (error) => error.contains('invalid push symbol'),
          ),
      isEmpty,
    );
    final standardRule = standard.pdaTransitions.singleWhere(
      (transition) => transition.popSymbol == 'S',
    );
    final greibachRule = greibach.data!.pdaTransitions.singleWhere(
      (transition) => transition.popSymbol == 'S',
    );
    expect(standardRule.isLambdaInput, isTrue);
    expect(standardRule.pushSymbols, ['A', 'B']);
    expect(greibachRule.inputSymbol, 'a');
    expect(greibachRule.pushSymbols, ['B']);

    final simulation = PDASimulator.simulateNPDA(
      greibach.data!,
      'ab',
      mode: PDAAcceptanceMode.emptyStack,
    );
    expect(simulation.isSuccess, isTrue);
    expect(simulation.data!.accepted, isTrue);
  });
}

Grammar _grammar({
  required String id,
  required Set<String> nonterminals,
  required Set<String> terminals,
  required String startSymbol,
  required Set<Production> productions,
}) {
  final timestamp = DateTime.utc(2026);
  return Grammar(
    id: id,
    name: id,
    nonterminals: nonterminals,
    terminals: terminals,
    startSymbol: startSymbol,
    productions: productions,
    type: GrammarType.contextFree,
    created: timestamp,
    modified: timestamp,
  );
}
