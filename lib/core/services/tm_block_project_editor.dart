import '../algorithms/tm_block_dependency_analyzer.dart';
import '../messages/structured_message.dart';
import '../models/tm.dart';
import '../models/tm_building_blocks.dart';
import '../models/state.dart';

enum TMBlockDeleteResolution { cancel, detachInvocations }

enum TMBlockEditErrorCode {
  duplicateIdentity,
  duplicateName,
  missingBlock,
  missingOwner,
  missingAnchorState,
  referencedBlock,
  invalidProject,
  nothingToUndo,
  nothingToRedo,
}

class TMBlockEditResult {
  const TMBlockEditResult.success(this.project)
    : errorCode = null,
      structuredMessage = null,
      compatibilityDetail = null;

  const TMBlockEditResult.failure({
    required this.project,
    required this.errorCode,
    required this.structuredMessage,
    this.compatibilityDetail,
  });

  final TMBlockProject project;
  final TMBlockEditErrorCode? errorCode;
  final StructuredMessage? structuredMessage;

  /// Temporary detail from a producer that has not migrated to structured
  /// arguments yet. Presentation code must prefer [structuredMessage].
  final String? compatibilityDetail;

  /// Compatibility surface for callers that still expect a textual result.
  String? get message => compatibilityDetail ?? structuredMessage?.stableCode;

  bool get isSuccess => errorCode == null;
}

/// Transactional project editor for reusable TM definitions and invocations.
class TMBlockProjectEditor {
  TMBlockProjectEditor(this._project, {this.historyLimit = 50}) {
    if (historyLimit < 1) {
      throw ArgumentError.value(historyLimit, 'historyLimit');
    }
  }

  TMBlockProject _project;
  final int historyLimit;
  final List<TMBlockProject> _undo = [];
  final List<TMBlockProject> _redo = [];

  TMBlockProject get project => _project;
  bool get canUndo => _undo.isNotEmpty;
  bool get canRedo => _redo.isNotEmpty;

  TMBlockEditResult createDefinition(TMBlockDefinition definition) {
    if (_project.definitions.containsKey(definition.id) ||
        definition.id == _project.rootMachine.id) {
      return _failure(
        TMBlockEditErrorCode.duplicateIdentity,
        'tm-block-editor.duplicate-block-id',
        arguments: {
          'block': StructuredMessageArgument.identifier(
            definition.id,
            role: 'block-id',
          ),
        },
      );
    }
    if (_project.definitions.values.any(
      (existing) =>
          existing.name.trim().toLowerCase() ==
          definition.name.trim().toLowerCase(),
    )) {
      return _failure(
        TMBlockEditErrorCode.duplicateName,
        'tm-block-editor.duplicate-block-name',
        arguments: {
          'name': StructuredMessageArgument.literal(
            definition.name,
            role: 'block-name',
          ),
        },
      );
    }
    return _commit(
      _project.rootMachine.copyWith(
        blockDefinitions: {..._project.definitions, definition.id: definition},
      ),
    );
  }

  TMBlockEditResult renameDefinition(String blockId, String name) {
    final definition = _project.definitions[blockId];
    if (definition == null) return _missingBlock(blockId);
    final normalized = name.trim().toLowerCase();
    if (normalized.isEmpty ||
        _project.definitions.values.any(
          (existing) =>
              existing.id != blockId &&
              existing.name.trim().toLowerCase() == normalized,
        )) {
      return _failure(
        TMBlockEditErrorCode.duplicateName,
        'tm-block-editor.invalid-block-name',
      );
    }
    return _replaceDefinition(definition.copyWith(name: name.trim()));
  }

  TMBlockEditResult duplicateDefinition(
    String blockId, {
    required String newId,
    required String newName,
  }) {
    final definition = _project.definitions[blockId];
    if (definition == null) return _missingBlock(blockId);
    final invocationIds = <String>{};
    final clonedInvocations = definition.invocations.map((invocation) {
      final base = '$newId:${invocation.id}';
      var id = base;
      var suffix = 2;
      while (!invocationIds.add(id)) {
        id = '$base#$suffix';
        suffix++;
      }
      return invocation.copyWith(id: id);
    });
    return createDefinition(
      TMBlockDefinition(
        id: newId,
        name: newName,
        revision: 1,
        machine: definition.machine.copyWith(
          id: '$newId:machine',
          name: newName,
          blockDefinitions: const {},
          blockInvocations: const [],
        ),
        invocations: clonedInvocations,
      ),
    );
  }

  TMBlockEditResult replaceDefinitionMachine(String blockId, TM machine) {
    final definition = _project.definitions[blockId];
    if (definition == null) return _missingBlock(blockId);
    final nextRevision = definition.revision + 1;
    var definitions = {
      ..._project.definitions,
      blockId: definition.copyWith(
        revision: nextRevision,
        machine: machine.copyWith(
          blockDefinitions: const {},
          blockInvocations: const [],
        ),
      ),
    };
    definitions = definitions.map(
      (id, candidate) => MapEntry(
        id,
        candidate.copyWith(
          invocations: _updateRevision(
            candidate.invocations,
            blockId,
            nextRevision,
          ),
        ),
      ),
    );
    final root = _project.rootMachine.copyWith(
      blockDefinitions: definitions,
      blockInvocations: _updateRevision(
        _project.rootInvocations,
        blockId,
        nextRevision,
      ),
    );
    return _commit(root);
  }

  TMBlockEditResult deleteDefinition(
    String blockId, {
    TMBlockDeleteResolution resolution = TMBlockDeleteResolution.cancel,
  }) {
    if (!_project.definitions.containsKey(blockId)) {
      return _missingBlock(blockId);
    }
    final referenced = _allInvocations().any(
      (invocation) => invocation.reference.blockId == blockId,
    );
    if (referenced && resolution == TMBlockDeleteResolution.cancel) {
      return _failure(
        TMBlockEditErrorCode.referencedBlock,
        'tm-block-editor.referenced-block',
        arguments: {
          'block': StructuredMessageArgument.identifier(
            blockId,
            role: 'block-id',
          ),
        },
      );
    }
    final definitions = Map<String, TMBlockDefinition>.from(
      _project.definitions,
    )..remove(blockId);
    final detachedDefinitions = definitions.map(
      (id, definition) => MapEntry(
        id,
        definition.copyWith(
          invocations: definition.invocations.where(
            (node) => node.reference.blockId != blockId,
          ),
        ),
      ),
    );
    return _commit(
      _project.rootMachine.copyWith(
        blockDefinitions: detachedDefinitions,
        blockInvocations: _project.rootInvocations.where(
          (node) => node.reference.blockId != blockId,
        ),
      ),
    );
  }

  TMBlockEditResult upsertInvocation({
    required String ownerMachineId,
    required TMBlockInvocationNode invocation,
  }) {
    final owner = _project.machineFor(ownerMachineId);
    if (owner == null) {
      return _failure(
        TMBlockEditErrorCode.missingOwner,
        'tm-block-editor.missing-owner-machine',
        arguments: {
          'machine': StructuredMessageArgument.identifier(
            ownerMachineId,
            role: 'machine-id',
          ),
        },
      );
    }
    if (!owner.states.any((state) => state.id == invocation.stateId)) {
      return _failure(
        TMBlockEditErrorCode.missingAnchorState,
        'tm-block-editor.missing-anchor-state',
        arguments: {
          'state': StructuredMessageArgument.identifier(
            invocation.stateId,
            role: 'state-id',
          ),
          'machine': StructuredMessageArgument.identifier(
            ownerMachineId,
            role: 'machine-id',
          ),
        },
      );
    }
    final definition = _project.definitions[invocation.reference.blockId];
    if (definition == null) {
      return _missingBlock(invocation.reference.blockId);
    }
    final normalized = invocation.copyWith(
      reference: TMBlockReference(
        blockId: definition.id,
        revision: definition.revision,
      ),
    );
    final current = _project.invocationsFor(ownerMachineId);
    if (current.any(
      (node) => node.id != normalized.id && node.stateId == normalized.stateId,
    )) {
      return _failure(
        TMBlockEditErrorCode.duplicateIdentity,
        'tm-block-editor.state-already-invokes-block',
        arguments: {
          'state': StructuredMessageArgument.identifier(
            normalized.stateId,
            role: 'state-id',
          ),
        },
      );
    }
    final next = [
      ...current.where((node) => node.id != normalized.id),
      normalized,
    ]..sort((a, b) => a.id.compareTo(b.id));
    return _commit(_replaceOwnerInvocations(ownerMachineId, next));
  }

  TMBlockEditResult insertRootInvocation({
    required State anchor,
    required String invocationId,
    required String blockId,
  }) {
    if (_project.rootMachine.states.any((state) => state.id == anchor.id)) {
      return _failure(
        TMBlockEditErrorCode.duplicateIdentity,
        'tm-block-editor.duplicate-root-state',
        arguments: {
          'state': StructuredMessageArgument.identifier(
            anchor.id,
            role: 'state-id',
          ),
        },
      );
    }
    final definition = _project.definitions[blockId];
    if (definition == null) return _missingBlock(blockId);
    final normalizedAnchor = anchor.copyWith(
      isInitial: _project.rootMachine.initialState == null || anchor.isInitial,
    );
    final root = _project.rootMachine.copyWith(
      states: {..._project.rootMachine.states, normalizedAnchor},
      initialState: _project.rootMachine.initialState ?? normalizedAnchor,
      acceptingStates: {
        ..._project.rootMachine.acceptingStates,
        if (normalizedAnchor.isAccepting) normalizedAnchor,
      },
      blockInvocations: [
        ..._project.rootInvocations,
        TMBlockInvocationNode(
          id: invocationId,
          stateId: normalizedAnchor.id,
          reference: TMBlockReference(
            blockId: definition.id,
            revision: definition.revision,
          ),
        ),
      ],
    );
    return _commit(root);
  }

  TMBlockEditResult removeInvocation(
    String ownerMachineId,
    String invocationId,
  ) {
    final current = _project.invocationsFor(ownerMachineId);
    final next = current.where((node) => node.id != invocationId).toList();
    if (next.length == current.length) {
      return _failure(
        TMBlockEditErrorCode.duplicateIdentity,
        'tm-block-editor.missing-invocation',
        arguments: {
          'invocation': StructuredMessageArgument.identifier(
            invocationId,
            role: 'invocation-id',
          ),
        },
      );
    }
    return _commit(_replaceOwnerInvocations(ownerMachineId, next));
  }

  TMBlockEditResult undo() {
    if (_undo.isEmpty) {
      return _failure(
        TMBlockEditErrorCode.nothingToUndo,
        'tm-block-editor.nothing-to-undo',
      );
    }
    _redo.add(_project);
    _project = _undo.removeLast();
    return TMBlockEditResult.success(_project);
  }

  TMBlockEditResult redo() {
    if (_redo.isEmpty) {
      return _failure(
        TMBlockEditErrorCode.nothingToRedo,
        'tm-block-editor.nothing-to-redo',
      );
    }
    _undo.add(_project);
    _project = _redo.removeLast();
    return TMBlockEditResult.success(_project);
  }

  TMBlockEditResult _replaceDefinition(TMBlockDefinition definition) {
    return _commit(
      _project.rootMachine.copyWith(
        blockDefinitions: {..._project.definitions, definition.id: definition},
      ),
    );
  }

  TM _replaceOwnerInvocations(
    String ownerMachineId,
    List<TMBlockInvocationNode> invocations,
  ) {
    if (ownerMachineId == _project.rootMachine.id) {
      return _project.rootMachine.copyWith(blockInvocations: invocations);
    }
    final definition = _project.definitions[ownerMachineId]!;
    return _project.rootMachine.copyWith(
      blockDefinitions: {
        ..._project.definitions,
        ownerMachineId: definition.copyWith(invocations: invocations),
      },
    );
  }

  TMBlockEditResult _commit(TM root) {
    final next = TMBlockProject(
      rootMachine: root,
      schemaVersion: _project.schemaVersion,
      tapeSemantics: _project.tapeSemantics,
      recursionPolicy: _project.recursionPolicy,
      maximumCallDepth: _project.maximumCallDepth,
    );
    final report = TMBlockDependencyAnalyzer.analyze(next);
    final firstError = report.diagnostics
        .where(
          (diagnostic) =>
              diagnostic.severity == TMBlockDiagnosticSeverity.error,
        )
        .firstOrNull;
    if (firstError != null) {
      return _failure(
        TMBlockEditErrorCode.invalidProject,
        'tm-block-editor.invalid-project',
        arguments: {
          'diagnostic': StructuredMessageArgument.outcome(
            firstError.code.name,
            role: 'tm-block-diagnostic',
          ),
        },
        compatibilityDetail: firstError.message,
      );
    }
    _undo.add(_project);
    if (_undo.length > historyLimit) _undo.removeAt(0);
    _redo.clear();
    _project = next;
    return TMBlockEditResult.success(_project);
  }

  TMBlockEditResult _missingBlock(String blockId) => _failure(
    TMBlockEditErrorCode.missingBlock,
    'tm-block-editor.missing-block',
    arguments: {
      'block': StructuredMessageArgument.identifier(blockId, role: 'block-id'),
    },
  );

  TMBlockEditResult _failure(
    TMBlockEditErrorCode code,
    String messageCode, {
    Map<String, StructuredMessageArgument> arguments = const {},
    String? compatibilityDetail,
  }) => TMBlockEditResult.failure(
    project: _project,
    errorCode: code,
    structuredMessage: StructuredMessage(
      namespace: 'service',
      code: messageCode,
      category: StructuredMessageCategory.validation,
      severity: StructuredMessageSeverity.error,
      arguments: arguments,
    ),
    compatibilityDetail: compatibilityDetail,
  );

  Iterable<TMBlockInvocationNode> _allInvocations() sync* {
    yield* _project.rootInvocations;
    for (final definition in _project.definitions.values) {
      yield* definition.invocations;
    }
  }

  static List<TMBlockInvocationNode> _updateRevision(
    List<TMBlockInvocationNode> invocations,
    String blockId,
    int revision,
  ) {
    return invocations
        .map(
          (invocation) => invocation.reference.blockId == blockId
              ? invocation.copyWith(
                  reference: TMBlockReference(
                    blockId: blockId,
                    revision: revision,
                  ),
                )
              : invocation,
        )
        .toList(growable: false);
  }
}

extension<T> on Iterable<T> {
  T? get firstOrNull => isEmpty ? null : first;
}
