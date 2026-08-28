import '../messages/structured_message.dart';

const dfaMinimizationTitleMessageProperty = 'dfaMinimizationTitleMessage';
const dfaMinimizationExplanationMessageProperty =
    'dfaMinimizationExplanationMessage';

/// Locale-neutral titles and explanations emitted by DFA minimization steps.
abstract final class DfaMinimizationStepMessages {
  static StructuredMessage initialPartitionTitle() =>
      _step('initial-partition-title');

  static StructuredMessage initialPartitionExplanation({
    required String acceptingStates,
    required String nonAcceptingStates,
  }) => _step(
    'initial-partition-explanation',
    arguments: {
      'accepting-states': _stateLabels(acceptingStates),
      'non-accepting-states': _stateLabels(nonAcceptingStates),
    },
  );

  static StructuredMessage removeUnreachableTitle() =>
      _step('remove-unreachable-title');

  static StructuredMessage removeUnreachableExplanation({
    required String unreachableStates,
    required int reachableStateCount,
  }) => _step(
    'remove-unreachable-explanation',
    arguments: {
      'unreachable-states': _stateLabels(unreachableStates),
      'reachable-state-count': StructuredMessageArgument.count(
        reachableStateCount,
        role: 'reachable-state-count',
      ),
    },
  );

  static StructuredMessage selectSetTitle() => _step('select-set-title');

  static StructuredMessage selectSetExplanation(String states) => _step(
    'select-set-explanation',
    arguments: {'states': _stateLabels(states)},
  );

  static StructuredMessage findPredecessorsTitle(String symbol) => _step(
    'find-predecessors-title',
    arguments: {'symbol': _inputSymbol(symbol)},
  );

  static StructuredMessage findPredecessorsExplanation({
    required String states,
    required String symbol,
    required String predecessors,
    required bool hasPredecessors,
  }) => _step(
    'find-predecessors-explanation',
    arguments: {
      'states': _stateLabels(states),
      'symbol': _inputSymbol(symbol),
      'predecessors': _stateLabels(predecessors),
      'has-predecessors': StructuredMessageArgument.boolean(
        hasPredecessors,
        role: 'predecessor-presence',
      ),
    },
  );

  static StructuredMessage splitClassTitle() => _step('split-class-title');

  static StructuredMessage splitClassExplanation({
    required String splitStates,
    required String symbol,
    required String intersectionStates,
    required String differenceStates,
    required int oldPartitionSize,
    required int newPartitionSize,
  }) => _step(
    'split-class-explanation',
    arguments: {
      'split-states': _stateLabels(splitStates),
      'symbol': _inputSymbol(symbol),
      'intersection-states': _stateLabels(intersectionStates),
      'difference-states': _stateLabels(differenceStates),
      'old-partition-size': StructuredMessageArgument.count(
        oldPartitionSize,
        role: 'partition-size',
      ),
      'new-partition-size': StructuredMessageArgument.count(
        newPartitionSize,
        role: 'partition-size',
      ),
    },
  );

  static StructuredMessage noSplitTitle(String symbol) =>
      _step('no-split-title', arguments: {'symbol': _inputSymbol(symbol)});

  static StructuredMessage noSplitExplanation({
    required String states,
    required String symbol,
  }) => _step(
    'no-split-explanation',
    arguments: {'states': _stateLabels(states), 'symbol': _inputSymbol(symbol)},
  );

  static StructuredMessage partitionStableTitle() =>
      _step('partition-stable-title');

  static StructuredMessage partitionStableExplanation(int partitionSize) =>
      _step(
        'partition-stable-explanation',
        arguments: {
          'partition-size': StructuredMessageArgument.count(
            partitionSize,
            role: 'partition-size',
          ),
        },
      );

  static StructuredMessage createMinimizedStateTitle(String stateId) => _step(
    'create-minimized-state-title',
    arguments: {'state': _stateId(stateId)},
  );

  static StructuredMessage createMinimizedStateExplanation({
    required String stateId,
    required String equivalenceClass,
    required bool isInitial,
    required bool isAccepting,
  }) => _step(
    'create-minimized-state-explanation',
    arguments: {
      'state': _stateId(stateId),
      'equivalence-class': _stateLabels(equivalenceClass),
      'is-initial': StructuredMessageArgument.boolean(
        isInitial,
        role: 'initial-state',
      ),
      'is-accepting': StructuredMessageArgument.boolean(
        isAccepting,
        role: 'accepting-state',
      ),
    },
  );

  static StructuredMessage createMinimizedTransitionTitle(String symbol) =>
      _step(
        'create-minimized-transition-title',
        arguments: {'symbol': _inputSymbol(symbol)},
      );

  static StructuredMessage createMinimizedTransitionExplanation({
    required String fromState,
    required String toState,
    required String symbol,
  }) => _step(
    'create-minimized-transition-explanation',
    arguments: {
      'from-state': _stateId(fromState),
      'to-state': _stateId(toState),
      'symbol': _inputSymbol(symbol),
    },
  );

  static StructuredMessage completionTitle() => _step('completion-title');

  static StructuredMessage completionExplanation({
    required int originalStateCount,
    required int minimizedStateCount,
    required int transitionCount,
    required int reduction,
  }) => _step(
    'completion-explanation',
    arguments: {
      'original-state-count': StructuredMessageArgument.count(
        originalStateCount,
        role: 'state-count',
      ),
      'minimized-state-count': StructuredMessageArgument.count(
        minimizedStateCount,
        role: 'state-count',
      ),
      'transition-count': StructuredMessageArgument.count(
        transitionCount,
        role: 'transition-count',
      ),
      'reduction': StructuredMessageArgument.integer(
        reduction,
        role: 'state-reduction',
      ),
      'has-reduction': StructuredMessageArgument.boolean(
        reduction > 0,
        role: 'state-reduction-presence',
      ),
    },
  );

  static StructuredMessage _step(
    String code, {
    Map<String, StructuredMessageArgument> arguments = const {},
  }) => StructuredMessage(
    namespace: 'automaton.dfa-minimization.step',
    code: code,
    category: StructuredMessageCategory.transformation,
    severity: StructuredMessageSeverity.information,
    arguments: arguments,
  );

  static StructuredMessageArgument _stateLabels(String labels) =>
      StructuredMessageArgument.literal(labels, role: 'state-labels');

  static StructuredMessageArgument _stateId(String id) =>
      StructuredMessageArgument.literal(id, role: 'state-id');

  static StructuredMessageArgument _inputSymbol(String symbol) =>
      StructuredMessageArgument.symbol(symbol, role: 'input-symbol');
}
