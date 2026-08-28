import '../messages/structured_message.dart';

/// Action performed by one step of table-driven LL(1) parsing.
enum LL1ParseAction { expand, match, accept, error }

/// Machine-readable reason for a rejected or bounded LL(1) run.
enum LL1ParseDiagnostic {
  conflict,
  emptyTableCell,
  terminalMismatch,
  unexpectedEnd,
  trailingInput,
  timedOut,
  cancelled,
  stepLimit,
  invalidParserState,
}

/// Immutable snapshot of one predictive-parser action.
class LL1ParseStep {
  LL1ParseStep({
    required this.stepNumber,
    required this.action,
    required List<String> stack,
    required List<String> remainingInput,
    required this.lookahead,
    required this.message,
    this.structuredMessage,
    this.nonTerminal,
    this.productionId,
    this.tableNonTerminal,
    this.tableLookahead,
    this.diagnostic,
    List<String>? production,
    Set<String> expectedTerminals = const <String>{},
  }) : stack = List<String>.unmodifiable(stack),
       remainingInput = List<String>.unmodifiable(remainingInput),
       production = production == null
           ? null
           : List<String>.unmodifiable(production),
       expectedTerminals = Set<String>.unmodifiable(expectedTerminals);

  final int stepNumber;
  final LL1ParseAction action;

  /// Parser stack from bottom to top. The last item is the current top.
  final List<String> stack;

  /// Unconsumed token stream, including the end marker.
  final List<String> remainingInput;
  final String lookahead;
  final String? nonTerminal;
  final String? productionId;

  /// Table cell consulted by this action, when applicable.
  final String? tableNonTerminal;
  final String? tableLookahead;
  final LL1ParseDiagnostic? diagnostic;

  /// Right-hand side selected for an expansion. Empty means epsilon.
  final List<String>? production;
  final Set<String> expectedTerminals;
  final String message;

  /// Locale-neutral diagnostic for error steps, when one is available.
  final StructuredMessage? structuredMessage;

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
