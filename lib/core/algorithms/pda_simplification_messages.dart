import '../messages/structured_message.dart';
import '../models/pda_acceptance_mode.dart';

/// Locale-neutral diagnostics and progress messages emitted by PDA
/// simplification.
abstract final class PdaSimplificationMessages {
  static StructuredMessage emptyPda() => _validation('empty-pda');

  static StructuredMessage missingInitialState() =>
      _validation('missing-initial-state');

  static StructuredMessage initialStateOutsideSet() =>
      _validation('initial-state-outside-set');

  static StructuredMessage acceptingStateOutsideSet() =>
      _validation('accepting-state-outside-set');

  static StructuredMessage missingAcceptingState(PDAAcceptanceMode mode) =>
      _validation(
        'missing-accepting-state',
        arguments: {
          'mode': StructuredMessageArgument.outcome(
            _acceptanceModeValue(mode),
            role: 'acceptance-mode',
          ),
        },
      );

  static StructuredMessage invalidPda() => _validation('invalid-pda');

  static StructuredMessage nonPdaTransition() =>
      _validation('non-pda-transition');

  static StructuredMessage transitionEndpointOutsideSet(String transitionId) =>
      _validation(
        'transition-endpoint-outside-set',
        arguments: {
          'transition': StructuredMessageArgument.identifier(
            transitionId,
            role: 'transition-id',
          ),
        },
      );

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

  static StructuredMessage inputAlphabetSymbolEmpty() =>
      _validation('input-alphabet-empty-symbol');

  static StructuredMessage stackAlphabetSymbolEmpty() =>
      _validation('stack-alphabet-empty-symbol');

  static StructuredMessage transitionInputSymbolOutsideAlphabet(
    String transitionId,
    String symbol,
  ) => _validation(
    'transition-input-symbol-outside-alphabet',
    arguments: {
      'transition': StructuredMessageArgument.identifier(
        transitionId,
        role: 'transition-id',
      ),
      'symbol': StructuredMessageArgument.symbol(symbol, role: 'input-symbol'),
    },
  );

  static StructuredMessage duplicateTransitionIds(String transitionId) =>
      _validation(
        'duplicate-transition-ids',
        arguments: {
          'transition': StructuredMessageArgument.identifier(
            transitionId,
            role: 'transition-id',
          ),
        },
      );

  static StructuredMessage boundedLengthNegative() =>
      _validation('bounded-length-negative');

  static StructuredMessage boundedSymbolsEmpty() =>
      _validation('bounded-symbols-empty');

  static StructuredMessage boundedSymbolOutsideAlphabet(String symbol) =>
      _validation(
        'bounded-symbol-outside-alphabet',
        arguments: {
          'symbol': StructuredMessageArgument.symbol(
            symbol,
            role: 'input-symbol',
          ),
        },
      );

  static StructuredMessage validationComplete() =>
      _phase('validation-complete');

  static StructuredMessage everyStateReachable() =>
      _phase('every-state-reachable');

  static StructuredMessage removedUnreachableStates(int count) => _phase(
    'removed-unreachable-states',
    arguments: {
      'count': StructuredMessageArgument.count(
        count,
        role: 'removed-state-count',
      ),
    },
  );

  static StructuredMessage semanticUsefulnessUnavailable() =>
      _warning('semantic-usefulness-unavailable');

  static StructuredMessage semanticUsefulnessDisabled() =>
      _phase('semantic-usefulness-disabled');

  static StructuredMessage strongBisimulationComputed() =>
      _phase('strong-bisimulation-computed');

  static StructuredMessage strongBisimulationDisabled() =>
      _phase('strong-bisimulation-disabled');

  static StructuredMessage rebuildValidationComplete() =>
      _phase('rebuild-validation-complete');

  static StructuredMessage boundedSamplePassed(int count) => _phase(
    'bounded-sample-passed',
    arguments: {
      'count': StructuredMessageArgument.count(
        count,
        role: 'sampled-word-count',
      ),
    },
  );

  static StructuredMessage boundedComparisonDisabled() =>
      _phase('bounded-comparison-disabled');

  static StructuredMessage invalidRebuiltPda() =>
      _analysis('invalid-rebuilt-pda');

  static StructuredMessage boundedComparisonInconclusive(String word) =>
      _analysis(
        'bounded-comparison-inconclusive',
        arguments: {
          'word': StructuredMessageArgument.literal(word, role: 'input-word'),
        },
      );

  static StructuredMessage boundedComparisonSimulationLimit(String word) =>
      _analysis(
        'bounded-comparison-simulation-limit',
        arguments: {
          'word': StructuredMessageArgument.literal(word, role: 'input-word'),
        },
      );

  static StructuredMessage boundedComparisonAcceptanceMismatch(String word) =>
      _analysis(
        'bounded-comparison-acceptance-mismatch',
        arguments: {
          'word': StructuredMessageArgument.literal(word, role: 'input-word'),
        },
      );

  static String _acceptanceModeValue(PDAAcceptanceMode mode) => switch (mode) {
    PDAAcceptanceMode.finalState => 'final-state',
    PDAAcceptanceMode.emptyStack => 'empty-stack',
    PDAAcceptanceMode.both => 'both',
  };

  static StructuredMessage _validation(
    String code, {
    Map<String, StructuredMessageArgument> arguments = const {},
  }) => _message(
    code,
    category: StructuredMessageCategory.validation,
    severity: StructuredMessageSeverity.error,
    arguments: arguments,
  );

  static StructuredMessage _phase(
    String code, {
    Map<String, StructuredMessageArgument> arguments = const {},
  }) => _message(
    code,
    category: StructuredMessageCategory.transformation,
    severity: StructuredMessageSeverity.information,
    arguments: arguments,
  );

  static StructuredMessage _warning(
    String code, {
    Map<String, StructuredMessageArgument> arguments = const {},
  }) => _message(
    code,
    category: StructuredMessageCategory.analysis,
    severity: StructuredMessageSeverity.warning,
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
    namespace: 'pda.simplification',
    code: code,
    category: category,
    severity: severity,
    arguments: arguments,
  );
}
