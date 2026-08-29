part of 'tm_messages.dart';

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

  static StructuredMessage acceptanceUnresolved() => _simulation(
    'acceptance-unresolved',
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
