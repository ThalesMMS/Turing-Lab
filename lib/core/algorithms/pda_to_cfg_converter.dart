//
//  pda_to_cfg_converter.dart
//  Turing Lab
//
//  Implementa a transformação clássica de PDA para gramática livre de contexto
//  gerando variáveis estruturadas, produções e descrições textuais. Inclui
//  verificações de pré-condições do autômato, construção de não-terminais
//  especiais e retorno de um relatório pronto para visualização didática.
//
//  Thales Matheus Mendonça Santos - October 2025
//
import '../models/grammar.dart';
import '../models/pda.dart';
import '../models/production.dart';
import '../result.dart';
import '../utils/epsilon_utils.dart';

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
  /// Converts the provided [pda] into a CFG description and structure.
  static Result<PdaToCfgConversion> convert(PDA pda) {
    if (pda.states.isEmpty) {
      return const Failure('Cannot convert an empty PDA to a grammar.');
    }

    if (pda.initialState == null) {
      return const Failure(
        'PDA must define an initial state before conversion.',
      );
    }

    if (pda.acceptingStates.isEmpty) {
      return const Failure(
        'PDA must have at least one accepting state for conversion.',
      );
    }

    final normalizationError = _validatePopNormalized(pda);
    if (normalizationError != null) {
      return Failure(normalizationError);
    }

    final grammar = _buildGrammar(pda);
    if (grammar.productions.isEmpty) {
      return const Failure('No productions could be generated for this PDA.');
    }

    final description = _buildDescription(grammar, pda);
    return Success(
      PdaToCfgConversion(grammar: grammar, description: description),
    );
  }

  static Grammar _buildGrammar(PDA pda) {
    final now = DateTime.now();
    final nonTerminals = <String>{'S'};
    final terminals = <String>{
      ...pda.alphabet.where((symbol) => !isEpsilonSymbol(symbol)),
    };
    final productions = <Production>{};

    final initialState = pda.initialState!;
    var productionCounter = 0;
    final stateLabels = pda.states.map((state) => state.label).toList();

    String variable(String from, String stackSymbol, String to) =>
        '[$from, $stackSymbol, $to]';

    // Start productions
    for (final accept in pda.acceptingStates) {
      final targetVariable = variable(
        initialState.label,
        pda.initialStackSymbol,
        accept.label,
      );
      nonTerminals.add(targetVariable);
      productions.add(
        Production.unit(
          id: 'p$productionCounter',
          leftSide: 'S',
          rightSide: targetVariable,
          order: productionCounter,
        ),
      );
      productionCounter++;
    }

    for (final transition in pda.pdaTransitions) {
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

      final from = transition.fromState.label;
      final to = transition.toState.label;

      if (pushSymbols.isEmpty) {
        final leftVariable = variable(from, pop, to);
        nonTerminals.add(leftVariable);

        final production = input == null
            ? Production.lambda(
                id: 'p$productionCounter',
                leftSide: leftVariable,
                order: productionCounter,
              )
            : Production(
                id: 'p$productionCounter',
                leftSide: [leftVariable],
                rightSide: [input],
                isLambda: false,
                order: productionCounter,
              );
        productions.add(production);
        productionCounter++;
      } else {
        final sequences = _stateLabelSequences(
          stateLabels,
          pushSymbols.length - 1,
        );

        for (final target in stateLabels) {
          final leftVariable = variable(from, pop, target);
          nonTerminals.add(leftVariable);

          for (final sequence in sequences) {
            final rightSide = <String>[];
            if (input != null) {
              rightSide.add(input);
            }

            var currentFrom = to;
            for (var index = 0; index < pushSymbols.length; index++) {
              final stackSymbol = pushSymbols[index];
              final nextTo =
                  index < pushSymbols.length - 1 ? sequence[index] : target;
              final variableName = variable(currentFrom, stackSymbol, nextTo);
              nonTerminals.add(variableName);
              rightSide.add(variableName);
              currentFrom = nextTo;
            }

            productions.add(
              Production(
                id: 'p$productionCounter',
                leftSide: [leftVariable],
                rightSide: rightSide,
                isLambda: false,
                order: productionCounter,
              ),
            );
            productionCounter++;
          }
        }
      }
    }

    return Grammar(
      id: '${pda.id}_cfg',
      name: '${pda.name} (CFG)',
      terminals: terminals,
      nonterminals: nonTerminals,
      startSymbol: 'S',
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
          production.leftSide.length == 1 && production.leftSide.first == 'S',
    )) {
      final right = production.isLambda ? 'λ' : production.rightSide.join(' ');
      buffer.writeln('  S → $right');
    }

    buffer.writeln('');
    buffer.writeln('Transition productions:');
    for (final production in productions.where(
      (production) =>
          production.leftSide.length != 1 || production.leftSide.first != 'S',
    )) {
      final left = production.leftSide.join(' ');
      final right = production.isLambda ? 'λ' : production.rightSide.join(' ');
      buffer.writeln('  $left → $right');
    }

    buffer.writeln('');
    buffer.writeln(
      'Terminals: ${grammar.terminals.isEmpty ? '∅' : grammar.terminals.join(', ')}',
    );
    buffer.writeln('Stack alphabet: ${pda.stackAlphabet.join(', ')}');

    return buffer.toString();
  }

  static String? _validatePopNormalized(PDA pda) {
    for (final transition in pda.pdaTransitions) {
      if (transition.isLambdaPop || isEpsilonSymbol(transition.popSymbol)) {
        return 'PDA to CFG conversion requires every transition to pop '
            'exactly one stack symbol. Transition ${transition.id} uses '
            'a lambda pop; normalize the PDA before conversion.';
      }
    }
    return null;
  }

  static List<List<String>> _stateLabelSequences(
    List<String> stateLabels,
    int length,
  ) {
    if (length <= 0) {
      return [<String>[]];
    }

    final sequences = <List<String>>[];

    void build(List<String> current, int depth) {
      if (depth == length) {
        sequences.add(List<String>.unmodifiable(current));
        return;
      }

      for (final label in stateLabels) {
        current.add(label);
        build(current, depth + 1);
        current.removeLast();
      }
    }

    build(<String>[], 0);
    return sequences;
  }
}
