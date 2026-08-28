import '../messages/structured_message.dart';

/// Locale-neutral messages emitted by bounded multi-tape TM execution.
abstract final class TmMultiTapeMessages {
  static StructuredMessage cancelled() =>
      _analysis('cancelled', severity: StructuredMessageSeverity.information);

  static StructuredMessage timeout() =>
      _analysis('timeout', severity: StructuredMessageSeverity.warning);

  static StructuredMessage configurationLimit() => _analysis(
    'configuration-limit',
    severity: StructuredMessageSeverity.warning,
  );

  static StructuredMessage enteredFinalState(String policy) => _analysis(
    'entered-final-state',
    severity: StructuredMessageSeverity.information,
    arguments: {
      'policy': StructuredMessageArgument.outcome(
        policy,
        role: 'acceptance-policy',
      ),
    },
  );

  static StructuredMessage branchEnteredFinalState(String policy) => _analysis(
    'branch-entered-final-state',
    severity: StructuredMessageSeverity.information,
    arguments: {
      'policy': StructuredMessageArgument.outcome(
        policy,
        role: 'acceptance-policy',
      ),
    },
  );

  static StructuredMessage haltedAccepted(String policy) => _analysis(
    'halted-accepted',
    severity: StructuredMessageSeverity.information,
    arguments: {
      'policy': StructuredMessageArgument.outcome(
        policy,
        role: 'acceptance-policy',
      ),
    },
  );

  static StructuredMessage branchHaltedAccepted(String policy) => _analysis(
    'branch-halted-accepted',
    severity: StructuredMessageSeverity.information,
    arguments: {
      'policy': StructuredMessageArgument.outcome(
        policy,
        role: 'acceptance-policy',
      ),
    },
  );

  static StructuredMessage deterministicConflict() =>
      _validation('deterministic-conflict');

  static StructuredMessage deterministicCycle() => _analysis(
    'deterministic-cycle',
    severity: StructuredMessageSeverity.warning,
  );

  static StructuredMessage stepLimit() =>
      _analysis('step-limit', severity: StructuredMessageSeverity.warning);

  static StructuredMessage haltedRejected() => _analysis(
    'halted-rejected',
    severity: StructuredMessageSeverity.information,
  );

  static StructuredMessage everyBranchRejected() => _analysis(
    'every-branch-rejected',
    severity: StructuredMessageSeverity.information,
  );

  static StructuredMessage _validation(String code) => StructuredMessage(
    namespace: 'tm.multi-tape',
    code: code,
    category: StructuredMessageCategory.validation,
    severity: StructuredMessageSeverity.error,
  );

  static StructuredMessage _analysis(
    String code, {
    required StructuredMessageSeverity severity,
    Map<String, StructuredMessageArgument> arguments = const {},
  }) => StructuredMessage(
    namespace: 'tm.multi-tape',
    code: code,
    category: StructuredMessageCategory.analysis,
    severity: severity,
    arguments: arguments,
  );
}
