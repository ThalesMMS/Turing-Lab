import '../messages/structured_message.dart';

/// Locale-neutral diagnostics emitted by the PDA-to-CFG converter.
///
/// The converter keeps its legacy English error string for logs and
/// compatibility callers. Presentation code resolves these stable messages
/// into the active locale before showing them to the learner.
abstract final class PdaToCfgMessages {
  static StructuredMessage invalidProductionLimit() =>
      _validation('invalid-production-limit');

  static StructuredMessage cancelled() => _conversion('cancelled');

  static StructuredMessage emptyPda() => _validation('empty-pda');

  static StructuredMessage missingInitialState() =>
      _validation('missing-initial-state');

  static StructuredMessage initialStateOutsideSet() =>
      _validation('initial-state-outside-set');

  static StructuredMessage missingAcceptingState() =>
      _validation('missing-accepting-state');

  static StructuredMessage acceptingStateOutsideSet() =>
      _validation('accepting-state-outside-set');

  static StructuredMessage epsilonPop(String transitionId) => _validation(
    'epsilon-pop',
    arguments: {
      'transition': StructuredMessageArgument.identifier(
        transitionId,
        role: 'transition-id',
      ),
    },
  );

  static StructuredMessage productionLimit(int limit) => _conversion(
    'production-limit',
    arguments: {'limit': StructuredMessageArgument.bound(limit)},
  );

  static StructuredMessage noProductions() => _conversion('no-productions');

  static StructuredMessage _validation(
    String code, {
    Map<String, StructuredMessageArgument> arguments = const {},
  }) => StructuredMessage(
    namespace: 'pda.to-cfg',
    code: code,
    category: StructuredMessageCategory.validation,
    severity: StructuredMessageSeverity.error,
    arguments: arguments,
  );

  static StructuredMessage _conversion(
    String code, {
    Map<String, StructuredMessageArgument> arguments = const {},
  }) => StructuredMessage(
    namespace: 'pda.to-cfg',
    code: code,
    category: StructuredMessageCategory.conversion,
    severity: StructuredMessageSeverity.error,
    arguments: arguments,
  );
}
