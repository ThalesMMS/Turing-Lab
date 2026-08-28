import '../../algorithms/grammar_input_tokenizer.dart';
import '../../models/grammar.dart';
import '../../result.dart';
import 'grammar_symbol.dart';
import 'phrase_structure_grammar.dart';
import 'phrase_structure_production.dart';
import 'symbol_sequence.dart';

abstract final class LegacyContextFreeGrammarAdapter {
  /// Returns a deterministic content revision suitable for persisted sessions.
  static int sourceRevision(Grammar grammar) {
    final productions = grammar.productions.toList()
      ..sort((a, b) {
        final order = a.order.compareTo(b.order);
        return order != 0 ? order : a.id.compareTo(b.id);
      });
    final canonical = <String>[
      grammar.startSymbol,
      ...grammar.terminals.toList()..sort(),
      '|',
      ...grammar.nonterminals.toList()..sort(),
      '|',
      for (final production in productions)
        '${production.id}:${production.leftSide.join('\u001f')}:${production.isLambda ? '\u0000' : production.rightSide.join('\u001f')}',
    ].join('\u001e');
    var hash = 0x811c9dc5;
    for (final codeUnit in canonical.codeUnits) {
      hash = ((hash ^ codeUnit) * 0x01000193) & 0x7fffffff;
    }
    return hash;
  }

  static ContextFreeGrammar adapt(Grammar grammar, {required int revision}) {
    if (!grammar.nonterminals.contains(grammar.startSymbol)) {
      throw const FormatException(
        'The start symbol must be a declared non-terminal.',
      );
    }
    final terminals = {
      for (final symbol in grammar.terminals) TerminalGrammarSymbol(symbol),
    };
    final nonterminals = {
      for (final symbol in grammar.nonterminals)
        NonterminalGrammarSymbol(symbol),
    };
    if (grammar.terminals.intersection(grammar.nonterminals).isNotEmpty) {
      throw const FormatException(
        'Terminals and non-terminals must be disjoint.',
      );
    }
    PhraseGrammarSymbol convert(String symbol) {
      if (grammar.terminals.contains(symbol)) {
        return TerminalGrammarSymbol(symbol);
      }
      if (grammar.nonterminals.contains(symbol)) {
        return NonterminalGrammarSymbol(symbol);
      }
      throw FormatException('Undeclared grammar symbol: $symbol');
    }

    return ContextFreeGrammar(
      id: grammar.id,
      name: grammar.name,
      revision: revision,
      terminals: terminals,
      nonterminals: nonterminals,
      startSymbol: NonterminalGrammarSymbol(grammar.startSymbol),
      productions: grammar.productions.map((production) {
        if (!production.isValid ||
            production.leftSide.length != 1 ||
            !grammar.nonterminals.contains(production.leftSide.single)) {
          throw FormatException(
            'Production ${production.id} is not a valid CFG production.',
          );
        }
        return ContextFreeProduction(
          id: production.id,
          left: NonterminalGrammarSymbol(production.leftSide.single),
          right: GrammarSymbolSequence(
            production.isLambda
                ? const <PhraseGrammarSymbol>[]
                : production.rightSide.map(convert),
          ),
          order: production.order,
        );
      }),
    );
  }

  static Result<GrammarSymbolSequence> tokenizeTarget(
    Grammar grammar,
    String input,
  ) {
    final tokenized = GrammarInputTokenizer.tokenize(grammar, input);
    if (tokenized.isFailure) {
      return Failure(
        tokenized.error!,
        structuredMessage: tokenized.structuredError,
      );
    }
    return Success(
      GrammarSymbolSequence(
        tokenized.data!.map((token) => TerminalGrammarSymbol(token.lexeme)),
      ),
    );
  }
}
