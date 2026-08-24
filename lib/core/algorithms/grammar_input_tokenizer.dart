import '../models/grammar.dart';
import '../result.dart';
import '../utils/epsilon_utils.dart';

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

  static Result<List<GrammarInputToken>> tokenize(
    Grammar grammar,
    String input,
  ) {
    if (input.isEmpty) {
      return const Success(<GrammarInputToken>[]);
    }

    final terminals = grammar.terminals
        .where(
          (terminal) => terminal.isNotEmpty && !isEpsilonSymbol(terminal),
        )
        .toList()
      ..sort((left, right) {
        final lengthComparison = right.length.compareTo(left.length);
        return lengthComparison != 0 ? lengthComparison : left.compareTo(right);
      });

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
        return Failure(
          'Input string contains invalid symbol: ${input[position]}',
        );
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
      return Failure(result.error!);
    }

    return Success(
      List<int>.unmodifiable(
          <int>[0, ...result.data!.map((token) => token.end)]),
    );
  }
}
