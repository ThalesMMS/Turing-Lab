part of 'tm_messages.dart';

/// Locale-neutral messages emitted by bounded TM execution analysis.
abstract final class TmExecutionMessages {
  static StructuredMessage emptyMachine() => _validation('empty-machine');

  static StructuredMessage missingInitialState() =>
      _validation('missing-initial-state');

  static StructuredMessage stepLimitInvalid() =>
      _validation('step-limit-invalid');

  static StructuredMessage configurationLimitInvalid() =>
      _validation('configuration-limit-invalid');

  static StructuredMessage timeoutInvalid() => _validation('timeout-invalid');

  static StructuredMessage operationsPerBatchInvalid() =>
      _validation('operations-per-batch-invalid');

  static StructuredMessage invalidInputSymbol(String symbol) => _validation(
    'invalid-input-symbol',
    arguments: {
      'symbol': StructuredMessageArgument.symbol(symbol, role: 'input-symbol'),
    },
  );

  static StructuredMessage invalidMachine(Object detail) => _validation(
    'invalid-machine',
    arguments: {
      'detail': StructuredMessageArgument.literal(
        detail.toString(),
        role: 'error-detail',
      ),
    },
  );

  static StructuredMessage cancelled() =>
      _analysis('cancelled', severity: StructuredMessageSeverity.information);

  static StructuredMessage timeoutBeforeResolution() => _analysis(
    'timeout-before-resolution',
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

  static StructuredMessage haltedRejected() => _analysis(
    'halted-rejected',
    severity: StructuredMessageSeverity.information,
  );

  static StructuredMessage deterministicConflict({
    required int count,
    required String state,
    required String symbol,
  }) => _analysis(
    'deterministic-conflict',
    arguments: {
      'count': StructuredMessageArgument.count(count, role: 'transition-count'),
      'state': StructuredMessageArgument.identifier(state, role: 'state-id'),
      'symbol': StructuredMessageArgument.symbol(symbol, role: 'tape-symbol'),
    },
  );

  static StructuredMessage deterministicStepLimit() =>
      _analysis('step-limit', severity: StructuredMessageSeverity.warning);

  static StructuredMessage configurationLimit() => _analysis(
    'configuration-limit',
    severity: StructuredMessageSeverity.warning,
  );

  static StructuredMessage deterministicCycle() => _analysis(
    'deterministic-cycle',
    severity: StructuredMessageSeverity.warning,
  );

  static StructuredMessage branchStepLimit() => _analysis(
    'branch-step-limit',
    severity: StructuredMessageSeverity.warning,
  );

  static StructuredMessage everyBranchRejected() => _analysis(
    'every-branch-rejected',
    severity: StructuredMessageSeverity.information,
  );

  static StructuredMessage exploredGraphRejected() => _analysis(
    'explored-graph-rejected',
    severity: StructuredMessageSeverity.information,
  );

  static StructuredMessage _validation(
    String code, {
    Map<String, StructuredMessageArgument> arguments = const {},
  }) => _message(
    code,
    category: StructuredMessageCategory.validation,
    severity: StructuredMessageSeverity.error,
    arguments: arguments,
  );

  static StructuredMessage _analysis(
    String code, {
    StructuredMessageSeverity severity = StructuredMessageSeverity.error,
    Map<String, StructuredMessageArgument> arguments = const {},
  }) => _message(
    code,
    category: StructuredMessageCategory.analysis,
    severity: severity,
    arguments: arguments,
  );

  static StructuredMessage _message(
    String code, {
    required StructuredMessageCategory category,
    required StructuredMessageSeverity severity,
    Map<String, StructuredMessageArgument> arguments = const {},
  }) => StructuredMessage(
    namespace: 'tm.execution',
    code: code,
    category: category,
    severity: severity,
    arguments: arguments,
  );
}
