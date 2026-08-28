import '../messages/structured_message.dart';

/// Locale-neutral messages emitted by the single-tape TM simulator.
abstract final class TmSimulationMessages {
  static StructuredMessage emptyMachine() => _validation('empty-machine');

  static StructuredMessage missingInitialState() =>
      _validation('missing-initial-state');

  static StructuredMessage initialStateOutsideSet() =>
      _validation('initial-state-outside-set');

  static StructuredMessage acceptingStateOutsideSet() =>
      _validation('accepting-state-outside-set');

  static StructuredMessage invalidInputSymbol(String symbol) => _validation(
    'invalid-input-symbol',
    arguments: {
      'symbol': StructuredMessageArgument.symbol(symbol, role: 'input-symbol'),
    },
  );

  static StructuredMessage operationsPerBatchInvalid() =>
      _validation('operations-per-batch-invalid');

  static StructuredMessage nondeterministicConflict({
    required int count,
    required String state,
    required String symbol,
  }) => _simulation(
    'nondeterministic-conflict',
    arguments: {
      'count': StructuredMessageArgument.count(count, role: 'transition-count'),
      'state': StructuredMessageArgument.identifier(state, role: 'state-id'),
      'symbol': StructuredMessageArgument.symbol(symbol, role: 'tape-symbol'),
    },
  );

  static StructuredMessage rejectedNoAcceptingConfiguration() => _simulation(
    'rejected-no-accepting-configuration',
    severity: StructuredMessageSeverity.information,
  );

  static StructuredMessage inputNotAccepted() => _simulation(
    'input-not-accepted',
    severity: StructuredMessageSeverity.information,
  );

  static StructuredMessage timeout() =>
      _simulation('timeout', severity: StructuredMessageSeverity.warning);

  static StructuredMessage infiniteLoop() =>
      _simulation('infinite-loop', severity: StructuredMessageSeverity.warning);

  static StructuredMessage stepLimit() =>
      _simulation('step-limit', severity: StructuredMessageSeverity.warning);

  static StructuredMessage configurationLimit() => _simulation(
    'configuration-limit',
    severity: StructuredMessageSeverity.warning,
  );

  static StructuredMessage simulationFailure({
    required String mode,
    required Object error,
  }) => _simulation(
    '$mode-failure',
    arguments: {
      'error': StructuredMessageArgument.literal(
        error.toString(),
        role: 'error-detail',
      ),
    },
  );

  static StructuredMessage acceptedStringsFailure(Object error) =>
      _analysisFailure('accepted-strings-failure', error);

  static StructuredMessage rejectedStringsFailure(Object error) =>
      _analysisFailure('rejected-strings-failure', error);

  static StructuredMessage analysisFailure(Object error) =>
      _analysisFailure('analysis-failure', error);

  static StructuredMessage transitionTitle() => _trace('transition-title');

  static StructuredMessage readSymbol({
    required String symbol,
    required int position,
    required String state,
  }) => _trace(
    'read-symbol',
    arguments: {
      'symbol': StructuredMessageArgument.symbol(symbol, role: 'tape-symbol'),
      'position': StructuredMessageArgument.index(
        position,
        role: 'tape-position',
      ),
      'state': StructuredMessageArgument.identifier(state, role: 'state-id'),
    },
  );

  static StructuredMessage appliedRule({
    required String fromState,
    required String readSymbol,
    required String toState,
    required String writeSymbol,
    required String direction,
  }) => _trace(
    'applied-rule',
    arguments: {
      'from-state': StructuredMessageArgument.identifier(
        fromState,
        role: 'state-id',
      ),
      'read-symbol': StructuredMessageArgument.symbol(
        readSymbol,
        role: 'tape-symbol',
      ),
      'to-state': StructuredMessageArgument.identifier(
        toState,
        role: 'state-id',
      ),
      'write-symbol': StructuredMessageArgument.symbol(
        writeSymbol,
        role: 'tape-symbol',
      ),
      'direction': StructuredMessageArgument.literal(
        direction,
        role: 'tape-direction',
      ),
    },
  );

  static StructuredMessage wroteSymbol({
    required String symbol,
    required int position,
  }) => _trace(
    'wrote-symbol',
    arguments: {
      'symbol': StructuredMessageArgument.symbol(symbol, role: 'tape-symbol'),
      'position': StructuredMessageArgument.index(
        position,
        role: 'tape-position',
      ),
    },
  );

  static StructuredMessage movedHead({
    required String direction,
    required int position,
  }) => _trace(
    'moved-head',
    arguments: {
      'direction': StructuredMessageArgument.literal(
        direction,
        role: 'tape-direction',
      ),
      'position': StructuredMessageArgument.index(
        position,
        role: 'tape-position',
      ),
    },
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

  static StructuredMessage _simulation(
    String code, {
    StructuredMessageSeverity severity = StructuredMessageSeverity.error,
    Map<String, StructuredMessageArgument> arguments = const {},
  }) => _message(code, severity: severity, arguments: arguments);

  static StructuredMessage _trace(
    String code, {
    Map<String, StructuredMessageArgument> arguments = const {},
  }) => _message(
    code,
    category: StructuredMessageCategory.trace,
    severity: StructuredMessageSeverity.information,
    arguments: arguments,
  );

  static StructuredMessage _analysisFailure(String code, Object error) =>
      _message(
        code,
        category: StructuredMessageCategory.analysis,
        arguments: {
          'error': StructuredMessageArgument.literal(
            error.toString(),
            role: 'error-detail',
          ),
        },
      );

  static StructuredMessage _message(
    String code, {
    StructuredMessageCategory category = StructuredMessageCategory.simulation,
    StructuredMessageSeverity severity = StructuredMessageSeverity.error,
    Map<String, StructuredMessageArgument> arguments = const {},
  }) => StructuredMessage(
    namespace: 'tm.simulation',
    code: code,
    category: category,
    severity: severity,
    arguments: arguments,
  );
}

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

/// Locale-neutral messages emitted by bounded TM space profiling.
abstract final class TmSpaceProfileMessages {
  static StructuredMessage emptyMachine() => _validation('empty-machine');

  static StructuredMessage missingInitialState() =>
      _validation('missing-initial-state');

  static StructuredMessage maxInputLengthInvalid() =>
      _validation('max-input-length-invalid');

  static StructuredMessage candidateCapInvalid() =>
      _validation('candidate-cap-invalid');

  static StructuredMessage stepLimitInvalid() =>
      _validation('step-limit-invalid');

  static StructuredMessage configurationLimitInvalid() =>
      _validation('configuration-limit-invalid');

  static StructuredMessage timeoutInvalid() => _validation('timeout-invalid');

  static StructuredMessage operationsPerBatchInvalid() =>
      _validation('operations-per-batch-invalid');

  static StructuredMessage missingSpaceMetrics() =>
      _analysis('missing-space-metrics');

  static StructuredMessage _validation(String code) =>
      _message(code, category: StructuredMessageCategory.validation);

  static StructuredMessage _analysis(String code) =>
      _message(code, category: StructuredMessageCategory.analysis);

  static StructuredMessage _message(
    String code, {
    required StructuredMessageCategory category,
    StructuredMessageSeverity severity = StructuredMessageSeverity.error,
  }) => StructuredMessage(
    namespace: 'tm.space-profile',
    code: code,
    category: category,
    severity: severity,
  );
}

/// Locale-neutral messages emitted by bounded TM time profiling.
abstract final class TmTimeProfileMessages {
  static StructuredMessage maxLengthInvalid() =>
      _validation('max-length-invalid');

  static StructuredMessage candidateCapInvalid() =>
      _validation('candidate-cap-invalid');

  static StructuredMessage stepLimitInvalid() =>
      _validation('step-limit-invalid');

  static StructuredMessage configurationLimitInvalid() =>
      _validation('configuration-limit-invalid');

  static StructuredMessage timeoutInvalid() => _validation('timeout-invalid');

  static StructuredMessage operationsPerBatchInvalid() =>
      _validation('operations-per-batch-invalid');

  static StructuredMessage complete() =>
      _analysis('complete', severity: StructuredMessageSeverity.information);

  static StructuredMessage incomplete() =>
      _analysis('incomplete', severity: StructuredMessageSeverity.warning);

  static StructuredMessage cancelled() =>
      _analysis('cancelled', severity: StructuredMessageSeverity.information);

  static StructuredMessage invalidMachine() => _analysis('invalid-machine');

  static StructuredMessage _validation(String code) =>
      _message(code, category: StructuredMessageCategory.validation);

  static StructuredMessage _analysis(
    String code, {
    StructuredMessageSeverity severity = StructuredMessageSeverity.error,
  }) => _message(
    code,
    category: StructuredMessageCategory.analysis,
    severity: severity,
  );

  static StructuredMessage _message(
    String code, {
    required StructuredMessageCategory category,
    StructuredMessageSeverity severity = StructuredMessageSeverity.error,
  }) => StructuredMessage(
    namespace: 'tm.time-profile',
    code: code,
    category: category,
    severity: severity,
  );
}

/// Locale-neutral messages emitted by bounded TM reachability analysis.
abstract final class TmReachabilityMessages {
  static StructuredMessage emptyMachine() => _validation('empty-machine');

  static StructuredMessage invalidInitialState() =>
      _validation('invalid-initial-state');

  static StructuredMessage inputsRequired() => _validation('inputs-required');

  static StructuredMessage stepLimitInvalid() =>
      _validation('step-limit-invalid');

  static StructuredMessage configurationLimitInvalid() =>
      _validation('configuration-limit-invalid');

  static StructuredMessage timeoutInvalid() => _validation('timeout-invalid');

  static StructuredMessage operationsPerBatchInvalid() =>
      _validation('operations-per-batch-invalid');

  static StructuredMessage nonTmTransition() =>
      _validation('non-tm-transition');

  static StructuredMessage transitionEndpointOutsideSet(String transition) =>
      _validation(
        'transition-endpoint-outside-set',
        arguments: {
          'transition': StructuredMessageArgument.identifier(
            transition,
            role: 'transition-id',
          ),
        },
      );

  static StructuredMessage inputSymbolOutsideAlphabet({
    required String input,
    required String symbol,
  }) => _validation(
    'input-symbol-outside-alphabet',
    arguments: {
      'input': StructuredMessageArgument.literal(input, role: 'input-word'),
      'symbol': StructuredMessageArgument.symbol(symbol, role: 'input-symbol'),
    },
  );

  static StructuredMessage cancelled() =>
      _analysis('cancelled', severity: StructuredMessageSeverity.information);

  static StructuredMessage timeout() =>
      _analysis('timeout', severity: StructuredMessageSeverity.warning);

  static StructuredMessage configurationLimit() => _analysis(
    'configuration-limit',
    severity: StructuredMessageSeverity.warning,
  );

  static StructuredMessage stepLimit() =>
      _analysis('step-limit', severity: StructuredMessageSeverity.warning);

  static StructuredMessage complete() =>
      _analysis('complete', severity: StructuredMessageSeverity.information);

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
  }) => _message(
    code,
    category: StructuredMessageCategory.analysis,
    severity: severity,
  );

  static StructuredMessage _message(
    String code, {
    required StructuredMessageCategory category,
    StructuredMessageSeverity severity = StructuredMessageSeverity.error,
    Map<String, StructuredMessageArgument> arguments = const {},
  }) => StructuredMessage(
    namespace: 'tm.reachability',
    code: code,
    category: category,
    severity: severity,
    arguments: arguments,
  );
}

/// Locale-neutral messages emitted by bounded TM language exploration.
abstract final class TmLanguageExplorerMessages {
  static StructuredMessage maxInputLengthInvalid() =>
      _validation('max-input-length-invalid');

  static StructuredMessage candidateCapInvalid() =>
      _validation('candidate-cap-invalid');

  static StructuredMessage stepLimitInvalid() =>
      _validation('step-limit-invalid');

  static StructuredMessage configurationLimitInvalid() =>
      _validation('configuration-limit-invalid');

  static StructuredMessage timeoutInvalid() => _validation('timeout-invalid');

  static StructuredMessage operationsPerBatchInvalid() =>
      _validation('operations-per-batch-invalid');

  static StructuredMessage _validation(String code) => StructuredMessage(
    namespace: 'tm.language-explorer',
    code: code,
    category: StructuredMessageCategory.validation,
    severity: StructuredMessageSeverity.error,
  );
}
