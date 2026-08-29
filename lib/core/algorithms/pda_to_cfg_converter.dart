//
//  pda_to_cfg_converter.dart
//  Turing Lab
//
//  Implements the classical PDA-to-CFG transformation, generating
//  structured variables, productions, and textual descriptions. Includes
//  automaton precondition checks, construction of special nonterminals,
//  and a report ready for educational visualization.
//
//  Thales Matheus Mendonça Santos - October 2025
//
import '../models/grammar.dart';
import '../models/pda.dart';
import '../models/production.dart';
import '../models/state.dart';
import '../result.dart';
import '../utils/epsilon_utils.dart';
import 'pda_to_cfg_messages.dart';

/// Structured result for PDA → CFG conversions containing both the
/// generated grammar and a textual description.
class PdaToCfgConversion {
  const PdaToCfgConversion({required this.grammar, required this.description});

  /// Grammar generated from the PDA.
  final Grammar grammar;

  /// Human-readable description of the conversion.
  final String description;
}

/// Converts a PDA into a structured CFG using the standard
/// state/stack-variable construction.
class PDAtoCFGConverter {
  static const cancellationError = 'PDA to CFG conversion was cancelled.';
  static const productionLimitErrorPrefix =
      'PDA to CFG production limit exceeded';

  /// Converts the provided [pda] into a CFG description and structure.
  ///
  /// [maxGeneratedProductions] bounds the triple construction before it can
  /// exhaust memory. [isCancelled] is polled while productions and
  /// intermediate-state sequences are generated.
  static Result<PdaToCfgConversion> convert(
    PDA pda, {
    int? maxGeneratedProductions,
    bool Function()? isCancelled,
  }) {
    if (maxGeneratedProductions != null && maxGeneratedProductions <= 0) {
      return Failure(
        'The PDA to CFG production limit must be greater than zero.',
        structuredMessage: PdaToCfgMessages.invalidProductionLimit(),
      );
    }
    if (isCancelled?.call() == true) {
      return Failure(
        cancellationError,
        structuredMessage: PdaToCfgMessages.cancelled(),
      );
    }
    if (pda.states.isEmpty) {
      return Failure(
        'Cannot convert an empty PDA to a grammar.',
        structuredMessage: PdaToCfgMessages.emptyPda(),
      );
    }

    final initialState = pda.initialState;
    if (initialState == null) {
      return Failure(
        'PDA must define an initial state before conversion.',
        structuredMessage: PdaToCfgMessages.missingInitialState(),
      );
    }
    if (!pda.states.contains(initialState)) {
      return Failure(
        'PDA initial state must belong to the PDA state set before conversion.',
        structuredMessage: PdaToCfgMessages.initialStateOutsideSet(),
      );
    }

    if (pda.acceptingStates.isEmpty) {
      return Failure(
        'PDA must have at least one accepting state for conversion.',
        structuredMessage: PdaToCfgMessages.missingAcceptingState(),
      );
    }
    if (pda.acceptingStates.any((state) => !pda.states.contains(state))) {
      return Failure(
        'Every accepting state must belong to the PDA state set before conversion.',
        structuredMessage: PdaToCfgMessages.acceptingStateOutsideSet(),
      );
    }

    for (final transition in pda.pdaTransitions) {
      if (transition.isLambdaPop || isEpsilonSymbol(transition.popSymbol)) {
        return Failure(
          'PDA to CFG conversion requires every transition to pop '
          'exactly one stack symbol. Transition ${transition.id} uses '
          'an epsilon pop; normalize the PDA before conversion.',
          structuredMessage: PdaToCfgMessages.epsilonPop(transition.id),
        );
      }
    }

    Grammar grammar;
    try {
      grammar = _buildGrammar(
        pda,
        maxGeneratedProductions: maxGeneratedProductions,
        isCancelled: isCancelled,
      );
    } on _PdaToCfgCancellation {
      return Failure(
        cancellationError,
        structuredMessage: PdaToCfgMessages.cancelled(),
      );
    } on _PdaToCfgProductionLimit catch (error) {
      return Failure(
        '$productionLimitErrorPrefix (${error.limit}).',
        structuredMessage: PdaToCfgMessages.productionLimit(error.limit),
      );
    }
    if (grammar.productions.isEmpty) {
      return Failure(
        'No productions could be generated for this PDA.',
        structuredMessage: PdaToCfgMessages.noProductions(),
      );
    }

    final description = _buildDescription(grammar, pda);
    return Success(
      PdaToCfgConversion(grammar: grammar, description: description),
    );
  }

  static Grammar _buildGrammar(
    PDA pda, {
    required int? maxGeneratedProductions,
    required bool Function()? isCancelled,
  }) {
    final now = DateTime.now();
    final transitions = pda.pdaTransitions.toList()
      ..sort((left, right) => left.id.compareTo(right.id));
    final terminals = <String>{
      ...pda.alphabet.where((symbol) => !isEpsilonSymbol(symbol)),
      ...transitions
          .where(
            (transition) =>
                !transition.isLambdaInput &&
                !isEpsilonSymbol(transition.inputSymbol),
          )
          .map((transition) => transition.inputSymbol),
    };
    final usedGrammarSymbols = <String>{...terminals};
    String freshNonterminal(String base) {
      var candidate = base;
      var suffix = 0;
      while (!usedGrammarSymbols.add(candidate)) {
        candidate = '${base}_${++suffix}';
      }
      return candidate;
    }

    final startSymbol = freshNonterminal('S');
    final nonTerminals = <String>{startSymbol};
    final productions = <Production>{};

    final initialState = pda.initialState!;
    var productionCounter = 0;
    final states = pda.states.toList()
      ..sort((left, right) => left.id.compareTo(right.id));
    final variables = <(String, String, String), String>{};

    void checkCancellation() {
      if (isCancelled?.call() == true) {
        throw const _PdaToCfgCancellation();
      }
    }

    void addProduction(Production Function(int order) build) {
      checkCancellation();
      final limit = maxGeneratedProductions;
      if (limit != null && productionCounter >= limit) {
        throw _PdaToCfgProductionLimit(limit);
      }
      productions.add(build(productionCounter));
      productionCounter++;
    }

    String variable(State from, String stackSymbol, State to) {
      final key = (from.id, stackSymbol, to.id);
      return variables.putIfAbsent(
        key,
        () => freshNonterminal('[${from.label}, $stackSymbol, ${to.label}]'),
      );
    }

    // Start productions
    final acceptingStates = pda.acceptingStates.toList()
      ..sort((left, right) => left.id.compareTo(right.id));
    for (final accept in acceptingStates) {
      final targetVariable = variable(
        initialState,
        pda.initialStackSymbol,
        accept,
      );
      nonTerminals.add(targetVariable);
      addProduction(
        (order) => Production.unit(
          id: 'p$order',
          leftSide: startSymbol,
          rightSide: targetVariable,
          order: order,
        ),
      );
    }

    for (final transition in transitions) {
      checkCancellation();
      final isLambdaInput =
          transition.isLambdaInput || isEpsilonSymbol(transition.inputSymbol);
      final input = isLambdaInput ? null : transition.inputSymbol;
      if (input != null) {
        terminals.add(input);
      }

      final pop = transition.popSymbol;

      final isLambdaPush =
          transition.isLambdaPush || isEpsilonSymbol(transition.pushSymbol);
      final pushSymbols = isLambdaPush ? <String>[] : transition.pushSymbols;

      final from = transition.fromState;
      final to = transition.toState;

      if (pushSymbols.isEmpty) {
        final leftVariable = variable(from, pop, to);
        nonTerminals.add(leftVariable);

        addProduction(
          (order) => input == null
              ? Production.lambda(
                  id: 'p$order',
                  leftSide: leftVariable,
                  order: order,
                )
              : Production(
                  id: 'p$order',
                  leftSide: [leftVariable],
                  rightSide: [input],
                  isLambda: false,
                  order: order,
                ),
        );
      } else {
        final sequences = _stateSequences(
          states,
          pushSymbols.length - 1,
          isCancelled,
        );

        for (final target in states) {
          checkCancellation();
          final leftVariable = variable(from, pop, target);
          nonTerminals.add(leftVariable);

          for (final sequence in sequences) {
            checkCancellation();
            final rightSide = <String>[];
            if (input != null) {
              rightSide.add(input);
            }

            var currentFrom = to;
            for (var index = 0; index < pushSymbols.length; index++) {
              final stackSymbol = pushSymbols[index];
              final nextTo = index < pushSymbols.length - 1
                  ? sequence[index]
                  : target;
              final variableName = variable(currentFrom, stackSymbol, nextTo);
              nonTerminals.add(variableName);
              rightSide.add(variableName);
              currentFrom = nextTo;
            }

            addProduction(
              (order) => Production(
                id: 'p$order',
                leftSide: [leftVariable],
                rightSide: rightSide,
                isLambda: false,
                order: order,
              ),
            );
          }
        }
      }
    }

    return Grammar(
      id: '${pda.id}_cfg',
      name: '${pda.name} (CFG)',
      terminals: terminals,
      nonterminals: nonTerminals,
      startSymbol: startSymbol,
      productions: productions,
      type: GrammarType.contextFree,
      created: now,
      modified: now,
    );
  }

  static String _buildDescription(Grammar grammar, PDA pda) {
    final buffer = StringBuffer();
    buffer.writeln('Generated CFG from PDA');
    buffer.writeln(
      'Non-terminals of the form [p,A,q] indicate moving from state p',
    );
    buffer.writeln(
      'with stack symbol A on top to state q after consuming a string.',
    );
    buffer.writeln('');

    final productions = grammar.productions.toList()
      ..sort((a, b) => a.order.compareTo(b.order));

    buffer.writeln('Start productions:');
    for (final production in productions.where(
      (production) =>
          production.leftSide.length == 1 &&
          production.leftSide.first == grammar.startSymbol,
    )) {
      final right = production.isLambda
          ? kEpsilonSymbol
          : production.rightSide.join(' ');
      buffer.writeln('  ${grammar.startSymbol} → $right');
    }

    buffer.writeln('');
    buffer.writeln('Transition productions:');
    for (final production in productions.where(
      (production) =>
          production.leftSide.length != 1 ||
          production.leftSide.first != grammar.startSymbol,
    )) {
      final left = production.leftSide.join(' ');
      final right = production.isLambda
          ? kEpsilonSymbol
          : production.rightSide.join(' ');
      buffer.writeln('  $left → $right');
    }

    buffer.writeln('');
    buffer.writeln(
      'Terminals: ${grammar.terminals.isEmpty ? '∅' : grammar.terminals.join(', ')}',
    );
    buffer.writeln('Stack alphabet: ${pda.stackAlphabet.join(', ')}');

    return buffer.toString();
  }

  static Iterable<List<State>> _stateSequences(
    List<State> states,
    int length,
    bool Function()? isCancelled,
  ) sync* {
    if (isCancelled?.call() == true) {
      throw const _PdaToCfgCancellation();
    }
    if (length <= 0) {
      yield const <State>[];
      return;
    }

    for (final state in states) {
      if (isCancelled?.call() == true) {
        throw const _PdaToCfgCancellation();
      }
      for (final suffix in _stateSequences(states, length - 1, isCancelled)) {
        yield <State>[state, ...suffix];
      }
    }
  }
}

class _PdaToCfgCancellation implements Exception {
  const _PdaToCfgCancellation();
}

class _PdaToCfgProductionLimit implements Exception {
  const _PdaToCfgProductionLimit(this.limit);

  final int limit;
}
