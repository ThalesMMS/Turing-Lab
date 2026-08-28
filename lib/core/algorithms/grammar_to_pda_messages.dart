import '../messages/structured_message.dart';

/// Locale-neutral messages emitted by the legacy CFG-to-PDA converter.
///
/// The converter continues to expose its historical strings through the
/// failure result for compatibility. Presentation code should prefer the
/// structured payload and resolve it at the active locale.
abstract final class GrammarToPdaMessages {
  static StructuredMessage emptyGrammar() => _validation('empty-grammar');

  static StructuredMessage missingStartSymbol() =>
      _validation('missing-start-symbol');

  static StructuredMessage undeclaredStartSymbol(String symbol) => _validation(
    'undeclared-start-symbol',
    arguments: {
      'symbol': StructuredMessageArgument.symbol(symbol, role: 'start-symbol'),
    },
  );

  static StructuredMessage duplicateProductionId(String productionId) =>
      _validation(
        'duplicate-production-id',
        arguments: {
          'production': StructuredMessageArgument.identifier(
            productionId,
            role: 'production-id',
          ),
        },
      );

  static StructuredMessage notContextFree() => _validation('not-context-free');

  static StructuredMessage conversionTimedOut(Duration timeout) => _conversion(
    'timed-out',
    arguments: {
      'timeout': StructuredMessageArgument.duration(timeout, role: 'timeout'),
    },
  );

  static StructuredMessage internalConversionFailure() =>
      _conversion('internal-failure');

  static StructuredMessage gnfConversionFailed() =>
      _conversion('gnf-conversion-failed');

  static StructuredMessage invalidGnfResult() =>
      _conversion('invalid-gnf-result');

  static StructuredMessage analysisFailed() => _analysis('failed');

  static StructuredMessage analysisTimedOut(Duration timeout) => _analysis(
    'analysis-timed-out',
    arguments: {
      'timeout': StructuredMessageArgument.duration(timeout, role: 'timeout'),
    },
  );

  static StructuredMessage validateGrammarStep() =>
      _analysisStep('validate-grammar');

  static StructuredMessage createInitialStateStep() =>
      _analysisStep('create-initial-state');

  static StructuredMessage createProcessingStateStep() =>
      _analysisStep('create-processing-state');

  static StructuredMessage createAcceptingStateStep() =>
      _analysisStep('create-accepting-state');

  static StructuredMessage addTransitionsStep() =>
      _analysisStep('add-transitions');

  static StructuredMessage _validation(
    String code, {
    Map<String, StructuredMessageArgument> arguments = const {},
  }) => _message(
    code,
    category: StructuredMessageCategory.validation,
    severity: StructuredMessageSeverity.error,
    arguments: arguments,
  );

  static StructuredMessage _conversion(
    String code, {
    Map<String, StructuredMessageArgument> arguments = const {},
  }) => _message(
    code,
    category: StructuredMessageCategory.conversion,
    severity: StructuredMessageSeverity.error,
    arguments: arguments,
  );

  static StructuredMessage _analysis(
    String code, {
    Map<String, StructuredMessageArgument> arguments = const {},
  }) => _message(
    code,
    category: StructuredMessageCategory.analysis,
    severity: StructuredMessageSeverity.error,
    arguments: arguments,
  );

  static StructuredMessage _analysisStep(String code) => _message(
    code,
    category: StructuredMessageCategory.analysis,
    severity: StructuredMessageSeverity.information,
  );

  static StructuredMessage _message(
    String code, {
    required StructuredMessageCategory category,
    required StructuredMessageSeverity severity,
    Map<String, StructuredMessageArgument> arguments = const {},
  }) => StructuredMessage(
    namespace: 'grammar.to-pda',
    code: code,
    category: category,
    severity: severity,
    arguments: arguments,
  );
}
