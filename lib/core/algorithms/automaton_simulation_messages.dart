import '../messages/structured_message.dart';

/// Locale-neutral messages emitted by finite-automaton simulation.
///
/// State labels, state sets, and input symbols are carried as typed arguments
/// so the presentation layer can translate the surrounding explanation without
/// changing the formal automaton data.
abstract final class AutomatonSimulationMessages {
  static StructuredMessage dfaRequired() =>
      _message('dfa-required', category: StructuredMessageCategory.validation);

  static StructuredMessage emptyAutomaton() => _message(
    'empty-automaton',
    category: StructuredMessageCategory.validation,
  );

  static StructuredMessage missingInitialState() => _message(
    'missing-initial-state',
    category: StructuredMessageCategory.validation,
  );

  static StructuredMessage initialStateOutsideSet() => _message(
    'initial-state-outside-set',
    category: StructuredMessageCategory.validation,
  );

  static StructuredMessage acceptingStateOutsideSet() => _message(
    'accepting-state-outside-set',
    category: StructuredMessageCategory.validation,
  );

  static StructuredMessage invalidInputSymbol(String symbol) => _message(
    'invalid-input-symbol',
    category: StructuredMessageCategory.validation,
    arguments: {
      'symbol': StructuredMessageArgument.symbol(symbol, role: 'input-symbol'),
    },
  );

  static StructuredMessage noDfaTransition({
    required String state,
    required String symbol,
  }) => _message(
    'no-dfa-transition',
    arguments: {
      'state': StructuredMessageArgument.literal(state, role: 'state-label'),
      'symbol': StructuredMessageArgument.symbol(symbol, role: 'input-symbol'),
    },
  );

  static StructuredMessage rejectedNoAcceptingState() => _message(
    'rejected-no-accepting-state',
    category: StructuredMessageCategory.simulation,
    severity: StructuredMessageSeverity.information,
  );

  static StructuredMessage noNfaTransition(String symbol) => _message(
    'no-nfa-transition',
    category: StructuredMessageCategory.simulation,
    arguments: {
      'symbol': StructuredMessageArgument.symbol(symbol, role: 'input-symbol'),
    },
  );

  static StructuredMessage nfaNotAccepted() => _message(
    'nfa-not-accepted',
    category: StructuredMessageCategory.simulation,
    severity: StructuredMessageSeverity.information,
  );

  static StructuredMessage computationTreeTimeout({required int steps}) =>
      _message(
        'computation-tree-timeout',
        category: StructuredMessageCategory.simulation,
        severity: StructuredMessageSeverity.warning,
        arguments: {
          'steps': StructuredMessageArgument.count(steps, role: 'step-count'),
        },
      );

  static StructuredMessage computationTreeInfiniteLoop({required int steps}) =>
      _message(
        'computation-tree-infinite-loop',
        category: StructuredMessageCategory.simulation,
        severity: StructuredMessageSeverity.warning,
        arguments: {
          'steps': StructuredMessageArgument.count(steps, role: 'step-count'),
        },
      );

  static StructuredMessage nfaTraceTruncated({
    required int maximumNodes,
    required bool epsilonPathLimited,
    required int epsilonPathLimit,
  }) => _message(
    'nfa-trace-truncated',
    category: StructuredMessageCategory.simulation,
    severity: StructuredMessageSeverity.warning,
    arguments: {
      'limit': StructuredMessageArgument.bound(
        epsilonPathLimited ? epsilonPathLimit : maximumNodes,
        role: 'trace-limit',
      ),
      'epsilon-path-limited': StructuredMessageArgument.boolean(
        epsilonPathLimited,
        role: 'epsilon-path-limit',
      ),
    },
  );

  static StructuredMessage dfaFailure(Object error) =>
      _failure('dfa-failure', error);

  static StructuredMessage nfaFailure(Object error) =>
      _failure('nfa-failure', error);

  static StructuredMessage acceptedStringsFailure(Object error) =>
      _failure('accepted-strings-failure', error);

  static StructuredMessage rejectedStringsFailure(Object error) =>
      _failure('rejected-strings-failure', error);

  static StructuredMessage transitionAppliedTitle() =>
      _traceMessage('transition-applied-title');

  static StructuredMessage readSymbol(String symbol) => _traceMessage(
    'read-symbol',
    arguments: {
      'symbol': StructuredMessageArgument.symbol(symbol, role: 'input-symbol'),
    },
  );

  static StructuredMessage transitionDetail({
    required String fromState,
    required String symbol,
    required String toState,
  }) => _traceMessage(
    'transition-detail',
    arguments: {
      'from-state': StructuredMessageArgument.literal(
        fromState,
        role: 'state-label',
      ),
      'symbol': StructuredMessageArgument.symbol(symbol, role: 'input-symbol'),
      'to-state': StructuredMessageArgument.literal(
        toState,
        role: 'state-label',
      ),
    },
  );

  static StructuredMessage computedEpsilonClosureTitle() =>
      _traceMessage('computed-epsilon-closure-title');

  static StructuredMessage epsilonClosureBeforeReading() =>
      _traceMessage('epsilon-closure-before-reading');

  static StructuredMessage epsilonClosureReached({
    required String initialState,
    required String stateSet,
  }) => _traceMessage(
    'epsilon-closure-reached',
    arguments: {
      'initial-state': StructuredMessageArgument.literal(
        initialState,
        role: 'state-label',
      ),
      'state-set': StructuredMessageArgument.literal(
        stateSet,
        role: 'state-set',
      ),
    },
  );

  static StructuredMessage symbolConsumedTitle() =>
      _traceMessage('symbol-consumed-title');

  static StructuredMessage nondeterministicStep() =>
      _traceMessage('nondeterministic-step');

  static StructuredMessage activeSetAfterTransitions({
    required String symbol,
    required String stateSet,
  }) => _traceMessage(
    'active-set-after-transitions',
    arguments: {
      'symbol': StructuredMessageArgument.symbol(symbol, role: 'input-symbol'),
      'state-set': StructuredMessageArgument.literal(
        stateSet,
        role: 'state-set',
      ),
    },
  );

  static StructuredMessage expandedViaEpsilonTitle() =>
      _traceMessage('expanded-via-epsilon-title');

  static StructuredMessage epsilonAfterConsuming(String symbol) =>
      _traceMessage(
        'epsilon-after-consuming',
        arguments: {
          'symbol': StructuredMessageArgument.symbol(
            symbol,
            role: 'input-symbol',
          ),
        },
      );

  static StructuredMessage epsilonClosureExpanded({
    required String before,
    required String after,
  }) => _traceMessage(
    'epsilon-closure-expanded',
    arguments: {
      'before': StructuredMessageArgument.literal(before, role: 'state-set'),
      'after': StructuredMessageArgument.literal(after, role: 'state-set'),
    },
  );

  static StructuredMessage initialStateDescription(String stateId) =>
      _traceMessage(
        'initial-state-description',
        arguments: {
          'state': StructuredMessageArgument.identifier(
            stateId,
            role: 'state-id',
          ),
        },
      );

  static StructuredMessage consumedSymbolDescription({
    required String symbol,
    required String stateId,
  }) => _traceMessage(
    'consumed-symbol-description',
    arguments: {
      'symbol': StructuredMessageArgument.symbol(symbol, role: 'input-symbol'),
      'state': StructuredMessageArgument.identifier(stateId, role: 'state-id'),
    },
  );

  static StructuredMessage initialEpsilonClosureDescription() =>
      _traceMessage('initial-epsilon-closure-description');
}

StructuredMessage _message(
  String code, {
  StructuredMessageCategory category = StructuredMessageCategory.simulation,
  StructuredMessageSeverity severity = StructuredMessageSeverity.error,
  Map<String, StructuredMessageArgument> arguments = const {},
}) => StructuredMessage(
  namespace: 'automaton.simulation',
  code: code,
  category: category,
  severity: severity,
  arguments: arguments,
);

StructuredMessage _traceMessage(
  String code, {
  Map<String, StructuredMessageArgument> arguments = const {},
}) => _message(
  code,
  category: StructuredMessageCategory.trace,
  severity: StructuredMessageSeverity.information,
  arguments: arguments,
);

StructuredMessage _failure(String code, Object error) => _message(
  code,
  arguments: {
    'error': StructuredMessageArgument.literal(
      error.toString(),
      role: 'error-detail',
    ),
  },
);
