import '../messages/structured_message.dart';

/// Locale-neutral messages emitted by TM building-block validation and
/// compositional execution.
abstract final class TmBuildingBlockMessages {
  static StructuredMessage duplicateMachineId(String blockName) => _validation(
    'duplicate-machine-id',
    arguments: {
      'block': StructuredMessageArgument.literal(blockName, role: 'block-name'),
    },
  );

  static StructuredMessage emptyBlockName(String blockId) => _validation(
    'empty-block-name',
    arguments: {
      'block': StructuredMessageArgument.identifier(blockId, role: 'block-id'),
    },
  );

  static StructuredMessage duplicateBlockName({
    required String firstBlockId,
    required String secondBlockId,
  }) => _validation(
    'duplicate-block-name',
    arguments: {
      'first-block': StructuredMessageArgument.identifier(
        firstBlockId,
        role: 'block-id',
      ),
      'second-block': StructuredMessageArgument.identifier(
        secondBlockId,
        role: 'block-id',
      ),
    },
  );

  static StructuredMessage missingInitialState(String blockName) => _validation(
    'missing-initial-state',
    arguments: {
      'block': StructuredMessageArgument.literal(blockName, role: 'block-name'),
    },
  );

  static StructuredMessage missingRootInitialState() =>
      _validation('missing-root-initial-state');

  static StructuredMessage tapeCountMismatch({
    required String blockName,
    required int blockTapeCount,
    required int rootTapeCount,
  }) => _validation(
    'tape-count-mismatch',
    arguments: {
      'block': StructuredMessageArgument.literal(blockName, role: 'block-name'),
      'block-tapes': StructuredMessageArgument.count(
        blockTapeCount,
        role: 'block-tape-count',
      ),
      'root-tapes': StructuredMessageArgument.count(
        rootTapeCount,
        role: 'root-tape-count',
      ),
    },
  );

  static StructuredMessage blankSymbolMismatch(String blockName) => _validation(
    'blank-symbol-mismatch',
    arguments: {
      'block': StructuredMessageArgument.literal(blockName, role: 'block-name'),
    },
  );

  static StructuredMessage nestedLibrary(String blockName) => _validation(
    'nested-library',
    arguments: {
      'block': StructuredMessageArgument.literal(blockName, role: 'block-name'),
    },
  );

  static StructuredMessage recursiveDependency(String cycle) => _validation(
    'recursive-dependency',
    arguments: {
      'cycle': StructuredMessageArgument.literal(
        cycle,
        role: 'dependency-cycle',
      ),
    },
  );

  static StructuredMessage duplicateInvocationId(String invocationId) =>
      _validation(
        'duplicate-invocation-id',
        arguments: {
          'invocation': StructuredMessageArgument.identifier(
            invocationId,
            role: 'invocation-id',
          ),
        },
      );

  static StructuredMessage duplicateInvocationState(String stateId) =>
      _validation(
        'duplicate-invocation-state',
        arguments: {
          'state': StructuredMessageArgument.identifier(
            stateId,
            role: 'state-id',
          ),
        },
      );

  static StructuredMessage missingAnchorState(String invocationId) =>
      _validation(
        'missing-anchor-state',
        arguments: {
          'invocation': StructuredMessageArgument.identifier(
            invocationId,
            role: 'invocation-id',
          ),
        },
      );

  static StructuredMessage missingReference({
    required String invocationId,
    required String blockId,
  }) => _validation(
    'missing-reference',
    arguments: {
      'invocation': StructuredMessageArgument.identifier(
        invocationId,
        role: 'invocation-id',
      ),
      'block': StructuredMessageArgument.identifier(blockId, role: 'block-id'),
    },
  );

  static StructuredMessage revisionMismatch({
    required String invocationId,
    required int expectedRevision,
    required String blockName,
    required int actualRevision,
  }) => _validation(
    'revision-mismatch',
    arguments: {
      'invocation': StructuredMessageArgument.identifier(
        invocationId,
        role: 'invocation-id',
      ),
      'expected': StructuredMessageArgument.count(
        expectedRevision,
        role: 'expected-revision',
      ),
      'block': StructuredMessageArgument.literal(blockName, role: 'block-name'),
      'actual': StructuredMessageArgument.count(
        actualRevision,
        role: 'actual-revision',
      ),
    },
  );

  static StructuredMessage acceptingRootInvocation({
    required String invocationId,
    required String blockId,
  }) => _validation(
    'accepting-root-invocation',
    arguments: {
      'invocation': StructuredMessageArgument.identifier(
        invocationId,
        role: 'invocation-id',
      ),
      'block': StructuredMessageArgument.identifier(blockId, role: 'block-id'),
    },
  );

  static StructuredMessage invalidProject() => _validation('invalid-project');

  static StructuredMessage cancelled() =>
      _analysis('cancelled', severity: StructuredMessageSeverity.information);

  static StructuredMessage timeout() =>
      _analysis('timeout', severity: StructuredMessageSeverity.warning);

  static StructuredMessage configurationLimit() => _analysis(
    'configuration-limit',
    severity: StructuredMessageSeverity.warning,
  );

  static StructuredMessage callDepthLimit() => _analysis(
    'call-depth-limit',
    severity: StructuredMessageSeverity.warning,
  );

  static StructuredMessage stepLimit() =>
      _analysis('step-limit', severity: StructuredMessageSeverity.warning);

  static StructuredMessage enteredFinalState(String policy) => _analysis(
    'entered-final-state',
    severity: StructuredMessageSeverity.information,
    arguments: {
      'policy': StructuredMessageArgument.outcome(
        policy,
        role: 'acceptance-policy',
      ),
    },
  );

  static StructuredMessage haltedAccepted(String policy) => _analysis(
    'halted-accepted',
    severity: StructuredMessageSeverity.information,
    arguments: {
      'policy': StructuredMessageArgument.outcome(
        policy,
        role: 'acceptance-policy',
      ),
    },
  );

  static StructuredMessage haltedRejected() => _analysis(
    'halted-rejected',
    severity: StructuredMessageSeverity.information,
  );

  static StructuredMessage finiteGraphRejected() => _analysis(
    'finite-graph-rejected',
    severity: StructuredMessageSeverity.information,
  );

  static StructuredMessage repeatedConfiguration() => _analysis(
    'repeated-configuration',
    severity: StructuredMessageSeverity.warning,
  );

  /// Trace label for entering a reusable machine.
  static StructuredMessage enterBlock(String machineId) => _trace(
    'enter-block',
    arguments: {
      'machine': StructuredMessageArgument.identifier(
        machineId,
        role: 'machine-id',
      ),
    },
  );

  /// Trace label for applying a transition in a reusable machine.
  static StructuredMessage transition(String transitionId) => _trace(
    'transition',
    arguments: {
      'transition': StructuredMessageArgument.identifier(
        transitionId,
        role: 'transition-id',
      ),
    },
  );

  /// Trace label for returning to the parent machine.
  static StructuredMessage returnFromBlock(String machineId) => _trace(
    'return-from-block',
    arguments: {
      'machine': StructuredMessageArgument.identifier(
        machineId,
        role: 'machine-id',
      ),
    },
  );

  static StructuredMessage _validation(
    String code, {
    Map<String, StructuredMessageArgument> arguments = const {},
  }) => StructuredMessage(
    namespace: 'tm.building-blocks',
    code: code,
    category: StructuredMessageCategory.validation,
    severity: StructuredMessageSeverity.error,
    arguments: arguments,
  );

  static StructuredMessage _analysis(
    String code, {
    required StructuredMessageSeverity severity,
    Map<String, StructuredMessageArgument> arguments = const {},
  }) => StructuredMessage(
    namespace: 'tm.building-blocks',
    code: code,
    category: StructuredMessageCategory.analysis,
    severity: severity,
    arguments: arguments,
  );

  static StructuredMessage _trace(
    String code, {
    Map<String, StructuredMessageArgument> arguments = const {},
  }) => StructuredMessage(
    namespace: 'tm.building-blocks',
    code: code,
    category: StructuredMessageCategory.trace,
    severity: StructuredMessageSeverity.information,
    arguments: arguments,
  );
}
