import '../messages/structured_message.dart';

/// Locale-neutral diagnostics emitted by PDA simulation validation.
///
/// The simulator exposes each stable message code through its legacy error
/// string for compatibility with existing callers, while presentation resolves
/// the structured payload for the active locale.
abstract final class PDASimulationMessages {
  static StructuredMessage emptyStateSet() =>
      _validationMessage('empty-state-set');

  static StructuredMessage missingInitialState() =>
      _validationMessage('missing-initial-state');

  static StructuredMessage initialStateOutsideSet() =>
      _validationMessage('initial-state-outside-set');

  static StructuredMessage acceptingStateOutsideSet() =>
      _validationMessage('accepting-state-outside-set');

  static StructuredMessage searchLimitsNegative() =>
      _validationMessage('search-limits-negative');

  static StructuredMessage memoryLimitNegative() =>
      _validationMessage('memory-limit-negative');

  static StructuredMessage configurationsPerBatchInvalid() =>
      _validationMessage('configurations-per-batch-invalid');

  static StructuredMessage simulationFailure({
    required String operation,
    required Object error,
  }) => _failureMessage(
    'simulation-failure',
    arguments: {
      'operation': StructuredMessageArgument.strategy(
        operation,
        role: 'simulation-operation',
      ),
      'error': StructuredMessageArgument.literal(
        error.toString(),
        role: 'error-detail',
      ),
    },
  );

  static StructuredMessage acceptedStringsFailure(Object error) =>
      _failureMessage(
        'accepted-strings-failure',
        arguments: {
          'error': StructuredMessageArgument.literal(
            error.toString(),
            role: 'error-detail',
          ),
        },
      );

  static StructuredMessage rejectedStringsFailure(Object error) =>
      _failureMessage(
        'rejected-strings-failure',
        arguments: {
          'error': StructuredMessageArgument.literal(
            error.toString(),
            role: 'error-detail',
          ),
        },
      );

  static StructuredMessage timeout() => _simulationMessage(
    'timeout',
    severity: StructuredMessageSeverity.warning,
  );

  static StructuredMessage infiniteLoop() => _simulationMessage(
    'infinite-loop',
    severity: StructuredMessageSeverity.warning,
  );

  static StructuredMessage configurationLimit() => _simulationMessage(
    'configuration-limit',
    severity: StructuredMessageSeverity.warning,
  );

  static StructuredMessage depthLimit() => _simulationMessage(
    'depth-limit',
    severity: StructuredMessageSeverity.warning,
  );

  static StructuredMessage memoryLimit() => _simulationMessage(
    'memory-limit',
    severity: StructuredMessageSeverity.warning,
  );

  static StructuredMessage staleRequest() => _simulationMessage(
    'stale-request',
    severity: StructuredMessageSeverity.information,
  );

  static StructuredMessage rejectedNoAcceptingConfiguration() =>
      _simulationMessage(
        'rejected-no-accepting-configuration',
        severity: StructuredMessageSeverity.information,
      );

  static StructuredMessage transitionTitle() =>
      _traceMessage('transition-title');

  static StructuredMessage readInput(String symbol) => _traceMessage(
    'read-input',
    arguments: {
      'symbol': StructuredMessageArgument.symbol(symbol, role: 'input-symbol'),
    },
  );

  static StructuredMessage stackAction({
    required String popSymbol,
    required String pushSymbol,
  }) => _traceMessage(
    'stack-action',
    arguments: {
      'pop': StructuredMessageArgument.symbol(popSymbol, role: 'stack-symbol'),
      'push': StructuredMessageArgument.symbol(
        pushSymbol,
        role: 'stack-symbol',
      ),
    },
  );

  static StructuredMessage stackTopChange({
    required String before,
    required String after,
  }) => _traceMessage(
    'stack-top-change',
    arguments: {
      'before': StructuredMessageArgument.symbol(before, role: 'stack-symbol'),
      'after': StructuredMessageArgument.symbol(after, role: 'stack-symbol'),
    },
  );

  static StructuredMessage popMatches(String symbol) => _traceMessage(
    'pop-matches',
    arguments: {
      'symbol': StructuredMessageArgument.symbol(symbol, role: 'stack-symbol'),
    },
  );

  static StructuredMessage noPop() => _traceMessage('no-pop');

  static StructuredMessage pushed(String symbol) => _traceMessage(
    'pushed',
    arguments: {
      'symbol': StructuredMessageArgument.symbol(symbol, role: 'stack-symbol'),
    },
  );

  static StructuredMessage noPush() => _traceMessage('no-push');

  static StructuredMessage epsilonMove() => _traceMessage('epsilon-move');

  static StructuredMessage _validationMessage(String code) => StructuredMessage(
    namespace: 'pda.simulation',
    code: code,
    category: StructuredMessageCategory.validation,
    severity: StructuredMessageSeverity.error,
  );

  static StructuredMessage _failureMessage(
    String code, {
    Map<String, StructuredMessageArgument> arguments = const {},
  }) => StructuredMessage(
    namespace: 'pda.simulation',
    code: code,
    category: StructuredMessageCategory.analysis,
    severity: StructuredMessageSeverity.error,
    arguments: arguments,
  );

  static StructuredMessage _simulationMessage(
    String code, {
    required StructuredMessageSeverity severity,
  }) => StructuredMessage(
    namespace: 'pda.simulation',
    code: code,
    category: StructuredMessageCategory.simulation,
    severity: severity,
  );

  static StructuredMessage _traceMessage(
    String code, {
    Map<String, StructuredMessageArgument> arguments = const {},
  }) => StructuredMessage(
    namespace: 'pda.simulation',
    code: code,
    category: StructuredMessageCategory.trace,
    severity: StructuredMessageSeverity.information,
    arguments: arguments,
  );
}
