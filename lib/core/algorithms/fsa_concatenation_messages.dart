import '../messages/structured_message.dart';

/// Locale-neutral messages emitted by the FSA concatenation construction.
abstract final class FsaConcatenationMessages {
  static const String FSA_CONCATENATION_TITLE_MESSAGE_PROPERTY =
      'fsaConcatenationTitleMessage';
  static const String FSA_CONCATENATION_EXPLANATION_MESSAGE_PROPERTY =
      'fsaConcatenationExplanationMessage';

  static StructuredMessage emptyOperand(String operand) =>
      _validation('empty-operand', arguments: {'operand': _operand(operand)});

  static StructuredMessage missingInitialState(String operand) => _validation(
    'missing-initial-state',
    arguments: {'operand': _operand(operand)},
  );

  static StructuredMessage initialStateOutsideSet(String operand) =>
      _validation(
        'initial-state-outside-set',
        arguments: {'operand': _operand(operand)},
      );

  static StructuredMessage acceptingStateOutsideSet(String operand) =>
      _validation(
        'accepting-state-outside-set',
        arguments: {'operand': _operand(operand)},
      );

  static StructuredMessage nonFsaTransition(String operand) => _validation(
    'non-fsa-transition',
    arguments: {'operand': _operand(operand)},
  );

  static StructuredMessage unknownTransitionEndpoint(String operand) =>
      _validation(
        'unknown-transition-endpoint',
        arguments: {'operand': _operand(operand)},
      );

  static StructuredMessage invalidTransition(
    String operand,
    String transitionId,
  ) => _validation(
    'invalid-transition',
    arguments: {
      'operand': _operand(operand),
      'transition': StructuredMessageArgument.identifier(
        transitionId,
        role: 'transition-id',
      ),
    },
  );

  static StructuredMessage duplicateStateIds() =>
      _analysis('duplicate-state-ids');

  static StructuredMessage duplicateTransitionIds() =>
      _analysis('duplicate-transition-ids');

  static StructuredMessage invalidResult() => _analysis('invalid-result');

  static StructuredMessage internalFailure() => _analysis('internal-failure');

  static StructuredMessage cloneTitle(String operand) =>
      _step('clone-title', arguments: {'operand': _operand(operand)});

  static StructuredMessage cloneExplanation(String operand) =>
      _step('clone-explanation', arguments: {'operand': _operand(operand)});

  static StructuredMessage connectTitle() => _step('connect-title');

  static StructuredMessage connectExplanation() => _step('connect-explanation');

  static StructuredMessage connectEmptyExplanation() =>
      _step('connect-empty-explanation');

  static StructuredMessageArgument _operand(String operand) =>
      StructuredMessageArgument.outcome(operand, role: 'fsa-operand');

  static StructuredMessage _validation(
    String code, {
    Map<String, StructuredMessageArgument> arguments = const {},
  }) => _message(
    code,
    category: StructuredMessageCategory.validation,
    severity: StructuredMessageSeverity.error,
    arguments: arguments,
  );

  static StructuredMessage _analysis(String code) => _message(
    code,
    category: StructuredMessageCategory.analysis,
    severity: StructuredMessageSeverity.error,
  );

  static StructuredMessage _step(
    String code, {
    Map<String, StructuredMessageArgument> arguments = const {},
  }) => _message(
    code,
    category: StructuredMessageCategory.transformation,
    severity: StructuredMessageSeverity.information,
    arguments: arguments,
  );

  static StructuredMessage _message(
    String code, {
    required StructuredMessageCategory category,
    required StructuredMessageSeverity severity,
    Map<String, StructuredMessageArgument> arguments = const {},
  }) => StructuredMessage(
    namespace: 'automaton.fsa-concatenation',
    code: code,
    category: category,
    severity: severity,
    arguments: arguments,
  );
}
