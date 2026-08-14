//
//  fsa_to_grammar_converter.dart
//  Turing Lab
//
//  Responsável por transformar autômatos finitos em gramáticas regulares,
//  atribuindo não terminais a estados, gerando produções rotuladas pelas
//  transições e adicionando regras lambda para estados de aceitação. Retorna
//  objeto `Grammar` pronto para consumo em módulos de análise e conversão.
//
//  Thales Matheus Mendonça Santos - October 2025
//
import '../models/fsa.dart';
import '../models/grammar.dart';
import '../models/production.dart';

class FSAToGrammarConverter {
  static Grammar convert(FSA fsa) {
    final nonTerminals = <String>{};
    final productions = <Production>{};
    final stateToNonTerminal = <String, String>{};
    int nonTerminalCounter = 0;

    for (final state in fsa.states) {
      final nonTerminal = 'A${nonTerminalCounter++}';
      nonTerminals.add(nonTerminal);
      stateToNonTerminal[state.id] = nonTerminal;
    }

    final startSymbol = stateToNonTerminal[fsa.initialState!.id]!;

    int productionCounter = 0;
    for (final transition in fsa.fsaTransitions) {
      final fromNonTerminal = stateToNonTerminal[transition.fromState.id]!;
      final toNonTerminal = stateToNonTerminal[transition.toState.id]!;
      if (transition.isEpsilonTransition) {
        productions.add(
          Production(
            id: 'p${productionCounter++}',
            leftSide: [fromNonTerminal],
            rightSide: [toNonTerminal],
          ),
        );
        continue;
      }
      for (final symbol in transition.inputSymbols) {
        productions.add(
          Production(
            id: 'p${productionCounter++}',
            leftSide: [fromNonTerminal],
            rightSide: [symbol, toNonTerminal],
          ),
        );
      }
    }

    for (final acceptingState in fsa.acceptingStates) {
      final nonTerminal = stateToNonTerminal[acceptingState.id]!;
      productions.add(
        Production.lambda(id: 'p${productionCounter++}', leftSide: nonTerminal),
      );
    }

    return Grammar(
      id: '${fsa.id}_grammar',
      name: '${fsa.name} (Grammar)',
      terminals: fsa.alphabet,
      nonterminals: nonTerminals,
      startSymbol: startSymbol,
      productions: productions,
      type: GrammarType.regular,
      created: DateTime.now(),
      modified: DateTime.now(),
    );
  }
}
