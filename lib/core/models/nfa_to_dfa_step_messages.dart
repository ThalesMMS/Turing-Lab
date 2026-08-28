import '../messages/structured_message.dart';

const nfaToDfaTitleMessageProperty = 'nfaToDfaTitleMessage';
const nfaToDfaExplanationMessageProperty = 'nfaToDfaExplanationMessage';

// Explicit aliases keep the model-specific naming discoverable alongside the
// shorter property names used by the other algorithm-step models.
const nfaToDfaStepTitleMessageProperty = nfaToDfaTitleMessageProperty;
const nfaToDfaStepExplanationMessageProperty =
    nfaToDfaExplanationMessageProperty;

/// Locale-neutral titles, explanations, and bullets for NFA-to-DFA steps.
///
/// The step model keeps its historical prose for compatibility. These
/// messages carry the same dynamic values as typed arguments so presentation
/// code can resolve the surrounding copy at the active locale.
abstract final class NfaToDfaStepMessages {
  static StructuredMessage initialEpsilonClosureTitle() =>
      _title('initial-epsilon-closure-title');

  static StructuredMessage initialEpsilonClosureExplanation({
    required String initialState,
    required String epsilonClosure,
    required bool containsAcceptingState,
  }) => _explanation(
    'initial-epsilon-closure-explanation',
    arguments: {
      'initial-state': _stateLabel(initialState),
      'epsilon-closure': _stateLabels(epsilonClosure),
      'contains-accepting-state': StructuredMessageArgument.boolean(
        containsAcceptingState,
        role: 'accepting-state-presence',
      ),
    },
  );

  static StructuredMessage initialEpsilonClosureStepTitle() =>
      _step('initial-epsilon-closure-step-title');

  static List<StructuredMessage> initialEpsilonClosureBullets({
    required String initialState,
    required String epsilonClosure,
    required bool containsAcceptingState,
  }) => [
    _bullet('initial-state', arguments: {'state': _stateLabel(initialState)}),
    _bullet(
      'epsilon-closure-reached',
      arguments: {'state-set': _stateLabels(epsilonClosure)},
    ),
    if (containsAcceptingState) _bullet('initial-state-is-accepting'),
  ];

  static StructuredMessage processSymbolTitle(String symbol) => _title(
    'process-symbol-title',
    arguments: {'symbol': _inputSymbol(symbol)},
  );

  static StructuredMessage processSymbolExplanation({
    required String currentStates,
    required String symbol,
    required String reachableStates,
  }) => _explanation(
    'process-symbol-explanation',
    arguments: {
      'current-states': _stateLabels(currentStates),
      'symbol': _inputSymbol(symbol),
      'reachable-states': _stateLabels(reachableStates),
    },
  );

  static StructuredMessage processSymbolStepTitle() =>
      _step('process-symbol-step-title');

  static List<StructuredMessage> processSymbolBullets({
    required String currentStates,
    required String symbol,
    required String reachableStates,
  }) => [
    _bullet(
      'current-dfa-state-set',
      arguments: {'state-set': _stateLabels(currentStates)},
    ),
    _bullet(
      'collect-symbol-destinations',
      arguments: {'symbol': _inputSymbol(symbol)},
    ),
    _bullet(
      'reachable-before-epsilon-closure',
      arguments: {'state-set': _stateLabels(reachableStates)},
    ),
  ];

  static StructuredMessage epsilonClosureOfReachableTitle() =>
      _title('epsilon-closure-of-reachable-title');

  static StructuredMessage epsilonClosureOfReachableExplanation({
    required String reachableStates,
    required String epsilonClosure,
    required bool isNewState,
    required bool containsAcceptingState,
  }) => _explanation(
    'epsilon-closure-of-reachable-explanation',
    arguments: {
      'reachable-states': _stateLabels(reachableStates),
      'epsilon-closure': _stateLabels(epsilonClosure),
      'is-new-state': StructuredMessageArgument.boolean(
        isNewState,
        role: 'new-state',
      ),
      'contains-accepting-state': StructuredMessageArgument.boolean(
        containsAcceptingState,
        role: 'accepting-state-presence',
      ),
    },
  );

  static StructuredMessage epsilonClosureOfReachableStepTitle() =>
      _step('epsilon-closure-of-reachable-step-title');

  static List<StructuredMessage> epsilonClosureOfReachableBullets({
    required String reachableStates,
    required String epsilonClosure,
    required bool isNewState,
    required bool containsAcceptingState,
  }) => [
    _bullet('epsilon-transitions-do-not-consume-input'),
    _bullet(
      'epsilon-closure-reached-from-states',
      arguments: {
        'reachable-states': _stateLabels(reachableStates),
        'epsilon-closure': _stateLabels(epsilonClosure),
      },
    ),
    _bullet(isNewState ? 'new-dfa-state-set' : 'existing-dfa-state-set'),
    if (containsAcceptingState) _bullet('accepting-dfa-state-set'),
  ];

  static StructuredMessage createDfaStateTitle(String dfaStateId) => _title(
    'create-dfa-state-title',
    arguments: {'state': _stateId(dfaStateId)},
  );

  static StructuredMessage createDfaStateExplanation({
    required String dfaStateId,
    required String stateSet,
    required bool isAccepting,
  }) => _explanation(
    'create-dfa-state-explanation',
    arguments: {
      'state': _stateId(dfaStateId),
      'state-set': _stateLabels(stateSet),
      'is-accepting': StructuredMessageArgument.boolean(
        isAccepting,
        role: 'accepting-state',
      ),
    },
  );

  static StructuredMessage createDfaStateStepTitle() =>
      _step('create-dfa-state-step-title');

  static List<StructuredMessage> createDfaStateBullets({
    required String stateSet,
    required bool isAccepting,
  }) => [
    _bullet('subset-construction-distinct-state-sets'),
    _bullet(
      'dfa-state-represents-nfa-set',
      arguments: {'state-set': _stateLabels(stateSet)},
    ),
    _bullet(isAccepting ? 'accepting-dfa-state' : 'non-accepting-dfa-state'),
  ];

  static StructuredMessage createDfaTransitionTitle(String symbol) => _title(
    'create-dfa-transition-title',
    arguments: {'symbol': _inputSymbol(symbol)},
  );

  static StructuredMessage createDfaTransitionExplanation({
    required String fromDfaStateId,
    required String symbol,
    required String toDfaStateId,
    required String fromStates,
    required String toStates,
  }) => _explanation(
    'create-dfa-transition-explanation',
    arguments: {
      'from-state': _stateId(fromDfaStateId),
      'symbol': _inputSymbol(symbol),
      'to-state': _stateId(toDfaStateId),
      'from-states': _stateLabels(fromStates),
      'to-states': _stateLabels(toStates),
    },
  );

  static StructuredMessage createDfaTransitionStepTitle() =>
      _step('create-dfa-transition-step-title');

  static List<StructuredMessage> createDfaTransitionBullets({
    required String fromStates,
    required String symbol,
    required String toStates,
  }) => [
    _bullet(
      'nfa-transition-reachability',
      arguments: {
        'from-states': _stateLabels(fromStates),
        'symbol': _inputSymbol(symbol),
        'to-states': _stateLabels(toStates),
      },
    ),
    _bullet('single-deterministic-transition'),
  ];

  static StructuredMessage completionTitle() => _title('completion-title');

  static StructuredMessage completionExplanation({
    required int totalStates,
    required int totalTransitions,
    required int totalAcceptingStates,
  }) => _explanation(
    'completion-explanation',
    arguments: {
      'state-count': StructuredMessageArgument.count(
        totalStates,
        role: 'dfa-state-count',
      ),
      'transition-count': StructuredMessageArgument.count(
        totalTransitions,
        role: 'dfa-transition-count',
      ),
      'accepting-state-count': StructuredMessageArgument.count(
        totalAcceptingStates,
        role: 'accepting-state-count',
      ),
    },
  );

  static StructuredMessage completionStepTitle() =>
      _step('completion-step-title');

  static List<StructuredMessage> completionBullets({
    required int totalStates,
    required int totalTransitions,
    required int totalAcceptingStates,
  }) => [
    _bullet(
      'created-state-count',
      arguments: {
        'count': StructuredMessageArgument.count(
          totalStates,
          role: 'dfa-state-count',
        ),
      },
    ),
    _bullet(
      'created-transition-count',
      arguments: {
        'count': StructuredMessageArgument.count(
          totalTransitions,
          role: 'dfa-transition-count',
        ),
      },
    ),
    _bullet(
      'marked-accepting-state-count',
      arguments: {
        'count': StructuredMessageArgument.count(
          totalAcceptingStates,
          role: 'accepting-state-count',
        ),
      },
    ),
  ];

  static StructuredMessage _title(
    String code, {
    Map<String, StructuredMessageArgument> arguments = const {},
  }) => _message(code, arguments: arguments);

  static StructuredMessage _explanation(
    String code, {
    Map<String, StructuredMessageArgument> arguments = const {},
  }) => _message(code, arguments: arguments);

  static StructuredMessage _step(
    String code, {
    Map<String, StructuredMessageArgument> arguments = const {},
  }) => _message(code, arguments: arguments);

  static StructuredMessage _bullet(
    String code, {
    Map<String, StructuredMessageArgument> arguments = const {},
  }) => _message(code, arguments: arguments);

  static StructuredMessage _message(
    String code, {
    Map<String, StructuredMessageArgument> arguments = const {},
  }) => StructuredMessage(
    namespace: 'automata.nfa-to-dfa',
    code: code,
    category: StructuredMessageCategory.transformation,
    severity: StructuredMessageSeverity.information,
    arguments: arguments,
  );

  static StructuredMessageArgument _stateLabel(String value) =>
      StructuredMessageArgument.literal(value, role: 'state-label');

  static StructuredMessageArgument _stateLabels(String value) =>
      StructuredMessageArgument.literal(value, role: 'state-labels');

  static StructuredMessageArgument _stateId(String value) =>
      StructuredMessageArgument.identifier(value, role: 'state-id');

  static StructuredMessageArgument _inputSymbol(String value) =>
      StructuredMessageArgument.symbol(value, role: 'input-symbol');
}
