//
//  fsa_to_grammar_converter.dart
//  Turing Lab
//
//  Transforms finite automata into regular grammars by assigning
//  nonterminals to states, generating productions labeled by transitions,
//  and adding lambda rules for accepting states. Returns a `Grammar`
//  ready for analysis and conversion modules.
//
//  Thales Matheus Mendonça Santos - October 2025
//
import '../models/fsa.dart';
import '../models/grammar.dart';
import '../models/production.dart';
import '../messages/structured_message.dart';
import '../result.dart';
import '../utils/epsilon_utils.dart';
import 'fsa_to_grammar_messages.dart';

class FSAToGrammarConverter {
  static Grammar convert(FSA fsa) {
    final result = tryConvert(fsa);
    if (!result.isSuccess) {
      throw StateError(result.error!);
    }
    return result.data!;
  }

  static Result<Grammar> tryConvert(FSA fsa) {
    if (fsa.states.isEmpty) {
      return _failure(
        'Automaton must contain at least one state.',
        FsaToGrammarMessages.emptyAutomaton(),
      );
    }
    final initialState = fsa.initialState;
    if (initialState == null) {
      return _failure(
        'Automaton must have an initial state.',
        FsaToGrammarMessages.missingInitialState(),
      );
    }
    if (!fsa.states.contains(initialState)) {
      return _failure(
        'The initial state must belong to the automaton.',
        FsaToGrammarMessages.initialStateOutsideSet(),
      );
    }

    final nonTerminals = <String>{};
    final productions = <Production>{};
    final stateToNonTerminal = <String, String>{};
    int nonTerminalCounter = 0;

    final orderedStates = fsa.states.toList()
      ..sort((left, right) {
        if (left == initialState) return -1;
        if (right == initialState) return 1;
        final idOrder = left.id.compareTo(right.id);
        return idOrder != 0 ? idOrder : left.label.compareTo(right.label);
      });
    for (final state in orderedStates) {
      final nonTerminal = 'A${nonTerminalCounter++}';
      nonTerminals.add(nonTerminal);
      stateToNonTerminal[state.id] = nonTerminal;
    }

    final startSymbol = stateToNonTerminal[initialState.id]!;

    int productionCounter = 0;
    final orderedTransitions = fsa.fsaTransitions.toList()
      ..sort((left, right) {
        final leftKey =
            '${left.fromState.id}\u0000${left.toState.id}\u0000${left.label}\u0000${left.id}';
        final rightKey =
            '${right.fromState.id}\u0000${right.toState.id}\u0000${right.label}\u0000${right.id}';
        return leftKey.compareTo(rightKey);
      });
    for (final transition in orderedTransitions) {
      final fromNonTerminal = stateToNonTerminal[transition.fromState.id]!;
      final toNonTerminal = stateToNonTerminal[transition.toState.id]!;
      final orderedSymbols = transition.acceptedSymbols.toList()..sort();
      for (final symbol in orderedSymbols) {
        productions.add(
          Production(
            id: 'p${productionCounter++}',
            leftSide: [fromNonTerminal],
            rightSide: isEpsilonSymbol(symbol)
                ? [toNonTerminal]
                : [symbol, toNonTerminal],
          ),
        );
      }
    }

    final orderedAcceptingStates = fsa.acceptingStates.toList()
      ..sort((left, right) => left.id.compareTo(right.id));
    for (final acceptingState in orderedAcceptingStates) {
      if (!fsa.states.contains(acceptingState)) {
        return _failure(
          'Every accepting state must belong to the automaton.',
          FsaToGrammarMessages.acceptingStateOutsideSet(),
        );
      }
      final nonTerminal = stateToNonTerminal[acceptingState.id]!;
      productions.add(
        Production.lambda(id: 'p${productionCounter++}', leftSide: nonTerminal),
      );
    }

    return ResultFactory.success(
      Grammar(
        id: '${fsa.id}_grammar',
        name: '${fsa.name} (Grammar)',
        terminals: fsa.alphabet,
        nonterminals: nonTerminals,
        startSymbol: startSymbol,
        productions: productions,
        type: GrammarType.regular,
        created: DateTime.now(),
        modified: DateTime.now(),
      ),
    );
  }

  static Result<T> _failure<T>(String text, StructuredMessage message) =>
      Failure<T>(text, structuredMessage: message);
}
