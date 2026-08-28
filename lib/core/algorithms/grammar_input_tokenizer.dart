import '../models/grammar.dart';
import '../result.dart';
import '../utils/epsilon_utils.dart';
import 'grammar_input_messages.dart';

class GrammarInputToken {
  const GrammarInputToken({
    required this.lexeme,
    required this.start,
    required this.end,
  });

  final String lexeme;
  final int start;
  final int end;
}

/// Tokenizes raw grammar input with deterministic maximal munch.
class GrammarInputTokenizer {
  const GrammarInputTokenizer._();

  /// Returns the first input code unit that cannot be matched to a terminal.
  ///
  /// This keeps structured parser diagnostics independent of localized error
  /// text while preserving the tokenizer's maximal-munch behavior.
  static String? firstInvalidSymbol(Grammar grammar, String input) {
    if (input.isEmpty) return null;
    final terminals = _sortedTerminals(grammar);
    var position = 0;
    while (position < input.length) {
      final matched = terminals.any(
        (terminal) => input.startsWith(terminal, position),
      );
      if (!matched) return input[position];
      final terminal = terminals.firstWhere(
        (candidate) => input.startsWith(candidate, position),
      );
      position += terminal.length;
    }
    return null;
  }

  static Result<List<GrammarInputToken>> tokenize(
    Grammar grammar,
    String input,
  ) {
    if (input.isEmpty) {
      return const Success(<GrammarInputToken>[]);
    }

    final terminals = _sortedTerminals(grammar);

    final tokens = <GrammarInputToken>[];
    var position = 0;
    while (position < input.length) {
      String? match;
      for (final terminal in terminals) {
        if (input.startsWith(terminal, position)) {
          match = terminal;
          break;
        }
      }

      if (match == null) {
        final message = GrammarInputMessages.invalidSymbol(
          symbol: input[position],
          position: position,
        );
        return Failure(message.stableCode, structuredMessage: message);
      }

      final end = position + match.length;
      tokens.add(GrammarInputToken(lexeme: match, start: position, end: end));
      position = end;
    }

    return Success(List<GrammarInputToken>.unmodifiable(tokens));
  }

  static Result<List<int>> splitOffsets(Grammar grammar, String input) {
    final result = tokenize(grammar, input);
    if (result.isFailure) {
      return Failure(result.error!, structuredMessage: result.structuredError);
    }

    return Success(
      List<int>.unmodifiable(<int>[
        0,
        ...result.data!.map((token) => token.end),
      ]),
    );
  }
}

List<String> _sortedTerminals(Grammar grammar) =>
    grammar.terminals
        .where((terminal) => terminal.isNotEmpty && !isEpsilonSymbol(terminal))
        .toList()
      ..sort((left, right) {
        final lengthComparison = right.length.compareTo(left.length);
        return lengthComparison != 0 ? lengthComparison : left.compareTo(right);
      });
