import '../messages/structured_message.dart';

/// Locale-neutral diagnostics emitted while proving PDA language emptiness.
abstract final class PdaLanguageEmptinessMessages {
  static StructuredMessage invalidLimits() => _validation('invalid-limits');

  static StructuredMessage cancelled() => _analysis('cancelled');

  static StructuredMessage witnessReplayFailed() =>
      _analysis('witness-replay-failed');

  static StructuredMessage _validation(String code) => _message(
    code,
    category: StructuredMessageCategory.validation,
    severity: StructuredMessageSeverity.error,
  );

  static StructuredMessage _analysis(String code) => _message(
    code,
    category: StructuredMessageCategory.analysis,
    severity: StructuredMessageSeverity.error,
  );

  static StructuredMessage _message(
    String code, {
    required StructuredMessageCategory category,
    required StructuredMessageSeverity severity,
  }) => StructuredMessage(
    namespace: 'pda.language-emptiness',
    code: code,
    category: category,
    severity: severity,
  );
}

/// Locale-neutral diagnostics emitted by the shortest-witness CFG analysis
/// used by the PDA language-emptiness analyzer.
abstract final class CfgShortestWitnessMessages {
  static StructuredMessage invalidLimits() => _validation('invalid-limits');

  static StructuredMessage missingStartSymbol() =>
      _validation('missing-start-symbol');

  static StructuredMessage overlappingSymbolSets() =>
      _validation('overlapping-symbol-sets');

  static StructuredMessage invalidProductionLeft(String productionId) =>
      _validation(
        'invalid-production-left',
        arguments: {
          'production': StructuredMessageArgument.identifier(
            productionId,
            role: 'production-id',
          ),
        },
      );

  static StructuredMessage inconsistentLambdaMetadata(String productionId) =>
      _validation(
        'inconsistent-lambda-metadata',
        arguments: {
          'production': StructuredMessageArgument.identifier(
            productionId,
            role: 'production-id',
          ),
        },
      );

  static StructuredMessage epsilonMixed(String productionId) => _validation(
    'epsilon-mixed',
    arguments: {
      'production': StructuredMessageArgument.identifier(
        productionId,
        role: 'production-id',
      ),
    },
  );

  static StructuredMessage undeclaredSymbol({
    required String productionId,
    required String symbol,
  }) => _validation(
    'undeclared-symbol',
    arguments: {
      'production': StructuredMessageArgument.identifier(
        productionId,
        role: 'production-id',
      ),
      'symbol': StructuredMessageArgument.symbol(
        symbol,
        role: 'grammar-symbol',
      ),
    },
  );

  static StructuredMessage cancelled() => _analysis('cancelled');

  static StructuredMessage productivityLimit(int limit) => _analysis(
    'productivity-limit',
    arguments: {
      'limit': StructuredMessageArgument.bound(
        limit,
        role: 'fixed-point-update-limit',
      ),
    },
  );

  static StructuredMessage derivationLimit(int limit) => _analysis(
    'derivation-limit',
    arguments: {
      'limit': StructuredMessageArgument.bound(
        limit,
        role: 'derivation-step-limit',
      ),
    },
  );

  static StructuredMessage witnessMismatch() => _analysis('witness-mismatch');

  static StructuredMessage missingProductiveChoice(String symbol) => _analysis(
    'missing-productive-choice',
    arguments: {
      'symbol': StructuredMessageArgument.symbol(
        symbol,
        role: 'grammar-nonterminal',
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

  static StructuredMessage _analysis(
    String code, {
    Map<String, StructuredMessageArgument> arguments = const {},
  }) => _message(
    code,
    category: StructuredMessageCategory.analysis,
    severity: StructuredMessageSeverity.error,
    arguments: arguments,
  );

  static StructuredMessage _message(
    String code, {
    required StructuredMessageCategory category,
    required StructuredMessageSeverity severity,
    Map<String, StructuredMessageArgument> arguments = const {},
  }) => StructuredMessage(
    namespace: 'grammar.shortest-witness',
    code: code,
    category: category,
    severity: severity,
    arguments: arguments,
  );
}
