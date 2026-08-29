part of 'tm_messages.dart';

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
