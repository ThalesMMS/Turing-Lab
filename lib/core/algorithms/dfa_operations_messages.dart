import '../messages/structured_message.dart';

/// Locale-neutral diagnostics emitted by DFA and epsilon-transition operations.
abstract final class DfaOperationsMessages {
  static StructuredMessage missingInitialState(String context) => _validation(
    'missing-initial-state',
    arguments: {
      'context': StructuredMessageArgument.outcome(
        _contextCode(context),
        role: 'dfa-context',
      ),
    },
  );

  static StructuredMessage nondeterministic(String context) => _validation(
    'nondeterministic',
    arguments: {
      'context': StructuredMessageArgument.outcome(
        _contextCode(context),
        role: 'dfa-context',
      ),
    },
  );

  static StructuredMessage epsilonTransitionsNotAllowed(String context) =>
      _validation(
        'epsilon-transitions-not-allowed',
        arguments: {
          'context': StructuredMessageArgument.outcome(
            _contextCode(context),
            role: 'dfa-context',
          ),
        },
      );

  static StructuredMessage symbolOutsideAlphabet(
    String context,
    String symbol,
  ) => _validation(
    'symbol-outside-alphabet',
    arguments: {
      'context': StructuredMessageArgument.outcome(
        _contextCode(context),
        role: 'dfa-context',
      ),
      'symbol': StructuredMessageArgument.symbol(symbol, role: 'input-symbol'),
    },
  );

  static StructuredMessage emptyAlphabetWithLabeledTransitions(
    String operand,
  ) => _validation(
    'empty-alphabet-with-labeled-transitions',
    arguments: {
      'operand': StructuredMessageArgument.outcome(
        _operandCode(operand),
        role: 'dfa-operand',
      ),
    },
  );

  static StructuredMessage bothOperandsMissingInitialState() =>
      _validation('both-operands-missing-initial-state');

  static StructuredMessage operationFailed(String operation) => _analysis(
    'operation-failed',
    arguments: {
      'operation': StructuredMessageArgument.outcome(
        _operationCode(operation),
        role: 'dfa-operation',
      ),
    },
  );

  static StructuredMessage epsilonRemovalFailed() =>
      _analysis('epsilon-removal-failed');

  static String _contextCode(String context) => switch (context) {
    'DFA' => 'dfa',
    'DFA for complement' => 'complement',
    'DFA for prefix closure' => 'prefix-closure',
    'DFA for suffix closure' => 'suffix-closure',
    'Operand A' => 'operand-a',
    'Operand B' => 'operand-b',
    _ => 'dfa',
  };

  static String _operandCode(String operand) => switch (operand) {
    'Operand A' => 'a',
    'Operand B' => 'b',
    _ => 'unknown',
  };

  static String _operationCode(String operation) => switch (operation) {
    '∪' => 'union',
    '∩' => 'intersection',
    '\\' => 'difference',
    'complement' => 'complement',
    'prefix-closure' => 'prefix-closure',
    'suffix-closure' => 'suffix-closure',
    'remove-lambda' => 'remove-lambda',
    _ => 'unknown',
  };

  static StructuredMessage _validation(
    String code, {
    Map<String, StructuredMessageArgument> arguments = const {},
  }) => _message(
    code,
    category: StructuredMessageCategory.validation,
    arguments: arguments,
  );

  static StructuredMessage _analysis(
    String code, {
    Map<String, StructuredMessageArgument> arguments = const {},
  }) => _message(
    code,
    category: StructuredMessageCategory.analysis,
    arguments: arguments,
  );

  static StructuredMessage _message(
    String code, {
    required StructuredMessageCategory category,
    StructuredMessageSeverity severity = StructuredMessageSeverity.error,
    Map<String, StructuredMessageArgument> arguments = const {},
  }) => StructuredMessage(
    namespace: 'automaton.dfa-operations',
    code: code,
    category: category,
    severity: severity,
    arguments: arguments,
  );
}
