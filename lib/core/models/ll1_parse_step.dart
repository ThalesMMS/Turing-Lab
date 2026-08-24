/// Action performed by one step of table-driven LL(1) parsing.
enum LL1ParseAction { expand, match, accept, error }

/// Immutable snapshot of one predictive-parser action.
class LL1ParseStep {
  LL1ParseStep({
    required this.stepNumber,
    required this.action,
    required List<String> stack,
    required List<String> remainingInput,
    required this.lookahead,
    required this.message,
    this.nonTerminal,
    List<String>? production,
    Set<String> expectedTerminals = const <String>{},
  })  : stack = List<String>.unmodifiable(stack),
        remainingInput = List<String>.unmodifiable(remainingInput),
        production =
            production == null ? null : List<String>.unmodifiable(production),
        expectedTerminals = Set<String>.unmodifiable(expectedTerminals);

  final int stepNumber;
  final LL1ParseAction action;

  /// Parser stack from bottom to top. The last item is the current top.
  final List<String> stack;

  /// Unconsumed token stream, including the end marker.
  final List<String> remainingInput;
  final String lookahead;
  final String? nonTerminal;

  /// Right-hand side selected for an expansion. Empty means epsilon.
  final List<String>? production;
  final Set<String> expectedTerminals;
  final String message;

  String? get productionDisplay {
    final left = nonTerminal;
    final right = production;
    if (left == null || right == null) return null;
    return '$left → ${right.isEmpty ? 'ε' : right.join(' ')}';
  }

  String get title {
    switch (action) {
      case LL1ParseAction.expand:
        return 'Expand $nonTerminal';
      case LL1ParseAction.match:
        return 'Match "$lookahead"';
      case LL1ParseAction.accept:
        return 'Accept input';
      case LL1ParseAction.error:
        return 'Parsing error';
    }
  }
}
