import '../messages/structured_message.dart';

/// Locale-neutral messages emitted by the FSA Kleene-star construction.
abstract final class FsaKleeneStarMessages {
  static const String FSA_KLEENE_STAR_TITLE_MESSAGE_PROPERTY =
      'fsaKleeneStarTitleMessage';
  static const String FSA_KLEENE_STAR_EXPLANATION_MESSAGE_PROPERTY =
      'fsaKleeneStarExplanationMessage';

  static StructuredMessage emptyOperand() => _validation('empty-operand');

  static StructuredMessage missingInitialState() =>
      _validation('missing-initial-state');

  static StructuredMessage initialStateOutsideSet() =>
      _validation('initial-state-outside-set');

  static StructuredMessage acceptingStateOutsideSet() =>
      _validation('accepting-state-outside-set');

  static StructuredMessage nonFsaTransition() =>
      _validation('non-fsa-transition');

  static StructuredMessage unknownTransitionEndpoint() =>
      _validation('unknown-transition-endpoint');

  static StructuredMessage invalidTransition(String transitionId) =>
      _validation(
        'invalid-transition',
        arguments: {
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

  static StructuredMessage stepTitle(String step) => _step(switch (step) {
    'clone' => 'clone-title',
    'entry' => 'entry-title',
    'repeat' => 'repeat-title',
    'exit' => 'exit-title',
    _ => 'unknown-title',
  });

  static StructuredMessage cloneExplanation() => _step('clone-explanation');

  static StructuredMessage entryExplanation() => _step('entry-explanation');

  static StructuredMessage repeatExplanation({
    required bool hasAcceptingStates,
  }) => _step(
    hasAcceptingStates ? 'repeat-explanation' : 'repeat-empty-explanation',
  );

  static StructuredMessage exitExplanation({
    required bool hasAcceptingStates,
  }) =>
      _step(hasAcceptingStates ? 'exit-explanation' : 'exit-empty-explanation');

  static StructuredMessage _validation(
    String code, {
    Map<String, StructuredMessageArgument> arguments = const {},
  }) => _message(
    code,
    category: StructuredMessageCategory.validation,
    arguments: arguments,
  );

  static StructuredMessage _analysis(String code) =>
      _message(code, category: StructuredMessageCategory.analysis);

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
    StructuredMessageSeverity severity = StructuredMessageSeverity.error,
    Map<String, StructuredMessageArgument> arguments = const {},
  }) => StructuredMessage(
    namespace: 'automaton.fsa-kleene-star',
    code: code,
    category: category,
    severity: severity,
    arguments: arguments,
  );
}
