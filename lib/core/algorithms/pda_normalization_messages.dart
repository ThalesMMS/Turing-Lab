import '../messages/structured_message.dart';
import '../models/pda_acceptance_mode.dart';

/// Locale-neutral diagnostics and provenance descriptions emitted by PDA
/// normalization.
abstract final class PdaNormalizationMessages {
  static StructuredMessage emptyPda() => _validation('empty-pda');

  static StructuredMessage missingInitialState() =>
      _validation('missing-initial-state');

  static StructuredMessage initialStateOutsideSet() =>
      _validation('initial-state-outside-set');

  static StructuredMessage invalidInitialStackSymbol(String symbol) =>
      _validation(
        'initial-stack-symbol-outside-alphabet',
        arguments: {
          'symbol': StructuredMessageArgument.symbol(
            symbol,
            role: 'stack-symbol',
          ),
        },
      );

  static StructuredMessage missingAcceptingState() =>
      _validation('missing-accepting-state');

  static StructuredMessage acceptingStateOutsideSet() =>
      _validation('accepting-state-outside-set');

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

  static StructuredMessage transitionPopSymbolOutsideAlphabet(
    String transitionId,
    String symbol,
  ) => _validation(
    'transition-pop-symbol-outside-alphabet',
    arguments: {
      'transition': StructuredMessageArgument.identifier(
        transitionId,
        role: 'transition-id',
      ),
      'symbol': StructuredMessageArgument.symbol(symbol, role: 'stack-symbol'),
    },
  );

  static StructuredMessage transitionPushSymbolOutsideAlphabet(
    String transitionId,
    String symbol,
  ) => _validation(
    'transition-push-symbol-outside-alphabet',
    arguments: {
      'transition': StructuredMessageArgument.identifier(
        transitionId,
        role: 'transition-id',
      ),
      'symbol': StructuredMessageArgument.symbol(symbol, role: 'stack-symbol'),
    },
  );

  /// Reports that generated states and transitions may make the result larger.
  static StructuredMessage growthWarning({
    required int addedStates,
    required int addedTransitions,
  }) => _warning(
    'growth-warning',
    arguments: {
      'states': StructuredMessageArgument.count(
        addedStates,
        role: 'generated-state-count',
      ),
      'transitions': StructuredMessageArgument.count(
        addedTransitions,
        role: 'generated-transition-count',
      ),
    },
  );

  static StructuredMessage introducedNondeterminismWarning() =>
      _warning('introduced-nondeterminism');

  static StructuredMessage initialStateDescription(String sourceStateId) =>
      _provenance(
        'initial-state',
        arguments: {
          'state': StructuredMessageArgument.identifier(
            sourceStateId,
            role: 'state-id',
          ),
        },
      );

  static StructuredMessage acceptanceStateDescription() =>
      _provenance('acceptance-state');

  static StructuredMessage drainStateDescription() =>
      _provenance('drain-state');

  static StructuredMessage initializeTransitionDescription(
    String sourceStateId,
  ) => _provenance(
    'initialize-transition',
    arguments: {
      'state': StructuredMessageArgument.identifier(
        sourceStateId,
        role: 'state-id',
      ),
    },
  );

  static StructuredMessage singlePopTransitionDescription(
    String sourceTransitionId,
  ) => _provenance(
    'single-pop-transition',
    arguments: {
      'transition': StructuredMessageArgument.identifier(
        sourceTransitionId,
        role: 'transition-id',
      ),
    },
  );

  static StructuredMessage acceptEmptyTransitionDescription({
    required String sourceStateId,
    required PDAAcceptanceMode targetMode,
  }) => _provenance(
    'accept-empty-transition',
    arguments: {
      'state': StructuredMessageArgument.identifier(
        sourceStateId,
        role: 'state-id',
      ),
      'mode': StructuredMessageArgument.outcome(
        _acceptanceModeValue(targetMode),
        role: 'acceptance-mode',
      ),
    },
  );

  static StructuredMessage enterDrainTransitionDescription(
    String sourceStateId,
  ) => _provenance(
    'enter-drain-transition',
    arguments: {
      'state': StructuredMessageArgument.identifier(
        sourceStateId,
        role: 'state-id',
      ),
    },
  );

  static StructuredMessage drainTransitionDescription() =>
      _provenance('drain-transition');

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

  static StructuredMessage _warning(
    String code, {
    Map<String, StructuredMessageArgument> arguments = const {},
  }) => _message(
    code,
    category: StructuredMessageCategory.analysis,
    severity: StructuredMessageSeverity.warning,
    arguments: arguments,
  );

  static StructuredMessage _provenance(
    String code, {
    Map<String, StructuredMessageArgument> arguments = const {},
  }) => _message(
    code,
    category: StructuredMessageCategory.transformation,
    severity: StructuredMessageSeverity.information,
    arguments: arguments,
  );

  static StructuredMessage _message(
    String code, {
    required StructuredMessageCategory category,
    required StructuredMessageSeverity severity,
    Map<String, StructuredMessageArgument> arguments = const {},
  }) => StructuredMessage(
    namespace: 'pda.normalization',
    code: code,
    category: category,
    severity: severity,
    arguments: arguments,
  );
}
