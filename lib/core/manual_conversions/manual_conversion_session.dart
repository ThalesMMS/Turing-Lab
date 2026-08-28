import '../educational_content/educational_content_reference.dart';
import '../messages/structured_message.dart';
import 'manual_conversion_content.dart';

enum ManualConversionDirection {
  faToRegex,
  regexToFa,
  faToRegularGrammar,
  regularGrammarToFa,
}

enum ManualConversionActionType {
  normalizeEndpoints,
  selectState,
  submitPairExpression,
  commitElimination,
  createBaseFragment,
  combineUnion,
  combineConcatenation,
  applyKleeneStar,
  applyPlus,
  applyOptional,
  mapState,
  mapNonterminal,
  addTransition,
  addProduction,
  markAccepting,
  markEpsilon,
  complete,
}

enum ManualConversionCertainty { exact, structural, bounded }

enum ManualConversionStatus { active, completed, invalidated }

enum ManualConversionDiagnosticCode {
  sourceChanged,
  sessionComplete,
  actionOutOfOrder,
  actionTypeMismatch,
  invalidPayload,
  nothingToUndo,
  nothingToRedo,
  unsupportedSchema,
  malformedPayload,
}

class ManualConversionSource {
  ManualConversionSource({
    required this.documentId,
    required this.revision,
    required Map<String, Object?> snapshot,
  }) : snapshot = _freezeMap(snapshot);

  final String documentId;
  final int revision;
  final Map<String, Object?> snapshot;

  bool matches({required String documentId, required int revision}) =>
      this.documentId == documentId && this.revision == revision;

  Map<String, Object?> toJson() => {
    'documentId': documentId,
    'revision': revision,
    'snapshot': snapshot,
  };

  factory ManualConversionSource.fromJson(Object? encoded) {
    final map = _objectMap(encoded, 'source');
    final documentId = map['documentId'];
    final revision = map['revision'];
    final snapshot = map['snapshot'];
    if (documentId is! String || revision is! int || snapshot is! Map) {
      throw const FormatException('Malformed manual conversion source.');
    }
    return ManualConversionSource(
      documentId: documentId,
      revision: revision,
      snapshot: Map<String, Object?>.from(snapshot),
    );
  }
}

class ManualConversionEvidence {
  ManualConversionEvidence({
    required this.summary,
    this.certainty = ManualConversionCertainty.structural,
    Iterable<String> provenanceIds = const <String>[],
    this.counterexample,
  }) : provenanceIds = List<String>.unmodifiable(provenanceIds);

  final String summary;
  final ManualConversionCertainty certainty;
  final List<String> provenanceIds;
  final String? counterexample;

  Map<String, Object?> toJson() => {
    'summary': summary,
    'certainty': certainty.name,
    'provenanceIds': provenanceIds,
    'counterexample': counterexample,
  };

  factory ManualConversionEvidence.fromJson(Object? encoded) {
    final map = _objectMap(encoded, 'evidence');
    final summary = map['summary'];
    final certainty = map['certainty'];
    final provenanceIds = map['provenanceIds'];
    final counterexample = map['counterexample'];
    if (summary is! String ||
        certainty is! String ||
        provenanceIds is! List ||
        provenanceIds.any((value) => value is! String) ||
        counterexample is! String?) {
      throw const FormatException('Malformed manual conversion evidence.');
    }
    return ManualConversionEvidence(
      summary: summary,
      certainty: ManualConversionCertainty.values.byName(certainty),
      provenanceIds: provenanceIds.cast<String>(),
      counterexample: counterexample,
    );
  }
}

class ManualConversionRequirement {
  ManualConversionRequirement({
    required this.id,
    required this.contentReference,
    required this.type,
    required this.title,
    required this.instruction,
    required Map<String, Object?> expectedPayload,
    Iterable<Map<String, Object?>> acceptedPayloads = const [],
    Iterable<String> allowedPayloadKeys = const <String>[],
    Iterable<String> provenanceIds = const <String>[],
    Map<String, Object?> supportingData = const <String, Object?>{},
    required this.hint,
    required this.revealExplanation,
    required this.evidence,
  }) : expectedPayload = _freezeMap(expectedPayload),
       acceptedPayloads = List<Map<String, Object?>>.unmodifiable(
         acceptedPayloads.map(_freezeMap),
       ),
       allowedPayloadKeys = Set<String>.unmodifiable(allowedPayloadKeys),
       provenanceIds = List<String>.unmodifiable(provenanceIds),
       supportingData = _freezeMap(supportingData);

  final String id;
  final EducationalContentReference contentReference;
  final ManualConversionActionType type;
  final String title;
  final String instruction;
  final Map<String, Object?> expectedPayload;
  final List<Map<String, Object?>> acceptedPayloads;
  final Set<String> allowedPayloadKeys;
  final List<String> provenanceIds;
  final Map<String, Object?> supportingData;
  final String hint;
  final String revealExplanation;
  final ManualConversionEvidence evidence;

  bool accepts(Map<String, Object?> payload) {
    if (allowedPayloadKeys.isNotEmpty &&
        payload.keys.any((key) => !allowedPayloadKeys.contains(key))) {
      return false;
    }
    return _deepEquals(expectedPayload, payload) ||
        acceptedPayloads.any((candidate) => _deepEquals(candidate, payload));
  }

  Map<String, Object?> toJson() => {
    'id': id,
    'content': contentReference.toJson(),
    'type': type.name,
    'title': title,
    'instruction': instruction,
    'expectedPayload': expectedPayload,
    'acceptedPayloads': acceptedPayloads,
    'allowedPayloadKeys': allowedPayloadKeys.toList()..sort(),
    'provenanceIds': provenanceIds,
    'supportingData': supportingData,
    'hint': hint,
    'revealExplanation': revealExplanation,
    'evidence': evidence.toJson(),
  };

  factory ManualConversionRequirement.fromJson(Object? encoded) {
    final map = _objectMap(encoded, 'requirement');
    final id = map['id'];
    final content = map['content'];
    final type = map['type'];
    final title = map['title'];
    final instruction = map['instruction'];
    final expectedPayload = map['expectedPayload'];
    final acceptedPayloads = map['acceptedPayloads'];
    final allowedPayloadKeys = map['allowedPayloadKeys'];
    final provenanceIds = map['provenanceIds'];
    final supportingData = map['supportingData'] ?? const <String, Object?>{};
    final hint = map['hint'];
    final revealExplanation = map['revealExplanation'];
    if (id is! String ||
        type is! String ||
        title is! String ||
        instruction is! String ||
        expectedPayload is! Map ||
        acceptedPayloads is! List ||
        acceptedPayloads.any((value) => value is! Map) ||
        allowedPayloadKeys is! List ||
        allowedPayloadKeys.any((value) => value is! String) ||
        provenanceIds is! List ||
        provenanceIds.any((value) => value is! String) ||
        supportingData is! Map ||
        hint is! String ||
        revealExplanation is! String) {
      throw const FormatException('Malformed manual conversion requirement.');
    }
    return ManualConversionRequirement(
      id: id,
      contentReference: _manualContentReference(content),
      type: ManualConversionActionType.values.byName(type),
      title: title,
      instruction: instruction,
      expectedPayload: Map<String, Object?>.from(expectedPayload),
      acceptedPayloads: acceptedPayloads
          .map((value) => Map<String, Object?>.from(value as Map))
          .toList(growable: false),
      allowedPayloadKeys: allowedPayloadKeys.cast<String>(),
      provenanceIds: provenanceIds.cast<String>(),
      supportingData: Map<String, Object?>.from(supportingData),
      hint: hint,
      revealExplanation: revealExplanation,
      evidence: ManualConversionEvidence.fromJson(map['evidence']),
    );
  }
}

EducationalContentReference _manualContentReference(Object? encoded) {
  if (encoded == null) return ManualConversionContent.legacy;
  final actual = EducationalContentReference.fromJson(encoded);
  final expected = ManualConversionContent.referenceFor(actual.id);
  if (expected == null || actual != expected) {
    throw const EducationalContentReferenceException(
      EducationalContentReferenceErrorCode.unsupportedContent,
    );
  }
  return actual;
}

class ManualConversionAction {
  ManualConversionAction({
    required this.id,
    required this.requirementId,
    required this.type,
    required Map<String, Object?> payload,
    this.revealed = false,
    this.validatedExternally = false,
    this.validationEvidence,
    Map<String, Object?>? learnerArtifact,
  }) : payload = _freezeMap(payload),
       learnerArtifact = learnerArtifact == null
           ? null
           : _freezeMap(learnerArtifact) {
    final hasEvidence = validationEvidence != null;
    final hasArtifact = this.learnerArtifact != null;
    if ((validatedExternally && (!hasEvidence || !hasArtifact)) ||
        (!validatedExternally && (hasEvidence || hasArtifact))) {
      throw ArgumentError(
        'Externally validated actions need evidence and a learner artifact.',
      );
    }
  }

  final String id;
  final String requirementId;
  final ManualConversionActionType type;
  final Map<String, Object?> payload;
  final bool revealed;
  final bool validatedExternally;
  final ManualConversionEvidence? validationEvidence;
  final Map<String, Object?>? learnerArtifact;

  Map<String, Object?> toJson() => {
    'id': id,
    'requirementId': requirementId,
    'type': type.name,
    'payload': payload,
    'revealed': revealed,
    'validatedExternally': validatedExternally,
    'validationEvidence': validationEvidence?.toJson(),
    'learnerArtifact': learnerArtifact,
  };

  factory ManualConversionAction.fromJson(Object? encoded) {
    final map = _objectMap(encoded, 'action');
    final id = map['id'];
    final requirementId = map['requirementId'];
    final type = map['type'];
    final payload = map['payload'];
    final revealed = map['revealed'];
    final validatedExternally = map['validatedExternally'] ?? false;
    final validationEvidence = map['validationEvidence'];
    final learnerArtifact = map['learnerArtifact'];
    if (id is! String ||
        requirementId is! String ||
        type is! String ||
        payload is! Map ||
        revealed is! bool ||
        validatedExternally is! bool ||
        validationEvidence is! Map? ||
        learnerArtifact is! Map?) {
      throw const FormatException('Malformed manual conversion action.');
    }
    return ManualConversionAction(
      id: id,
      requirementId: requirementId,
      type: ManualConversionActionType.values.byName(type),
      payload: Map<String, Object?>.from(payload),
      revealed: revealed,
      validatedExternally: validatedExternally,
      validationEvidence: validationEvidence == null
          ? null
          : ManualConversionEvidence.fromJson(validationEvidence),
      learnerArtifact: learnerArtifact == null
          ? null
          : Map<String, Object?>.from(learnerArtifact),
    );
  }
}

class ManualConversionDiagnostic {
  const ManualConversionDiagnostic({
    required this.code,
    required this.message,
    this.requirementId,
    this.structuredMessage,
  });

  final ManualConversionDiagnosticCode code;
  final String message;
  final String? requirementId;
  final StructuredMessage? structuredMessage;
}

class ManualConversionCommandResult {
  const ManualConversionCommandResult({
    required this.session,
    this.diagnostics = const <ManualConversionDiagnostic>[],
  });

  final ManualConversionSession session;
  final List<ManualConversionDiagnostic> diagnostics;
  bool get isSuccess => diagnostics.isEmpty;
}

class ManualConversionRestoreResult {
  const ManualConversionRestoreResult({
    this.session,
    this.diagnostics = const <ManualConversionDiagnostic>[],
  });

  final ManualConversionSession? session;
  final List<ManualConversionDiagnostic> diagnostics;
  bool get isSuccess => session != null && diagnostics.isEmpty;
}

class ManualConversionSession {
  ManualConversionSession._({
    required this.id,
    required this.direction,
    required this.source,
    required Iterable<ManualConversionRequirement> requirements,
    required Iterable<ManualConversionAction> actions,
    required this.cursor,
    required this.status,
    required Map<String, Object?> canonicalArtifact,
    required this.completionEvidence,
    this.parentSessionId,
    this.parentCursor,
  }) : requirements = List<ManualConversionRequirement>.unmodifiable(
         requirements,
       ),
       actions = List<ManualConversionAction>.unmodifiable(actions),
       canonicalArtifact = _freezeMap(canonicalArtifact) {
    if (cursor < 0 || cursor > this.actions.length) {
      throw ArgumentError.value(cursor, 'cursor');
    }
    final requirementIds = this.requirements.map((value) => value.id).toSet();
    if (requirementIds.length != this.requirements.length) {
      throw ArgumentError('Requirement IDs must be unique.');
    }
    if (this.actions.length > this.requirements.length) {
      throw ArgumentError('Actions cannot outnumber requirements.');
    }
    for (var index = 0; index < this.actions.length; index++) {
      final action = this.actions[index];
      final requirement = this.requirements[index];
      if (action.requirementId != requirement.id ||
          action.type != requirement.type ||
          (!action.validatedExternally &&
              !requirement.accepts(action.payload))) {
        throw ArgumentError(
          'Action ${action.id} does not match its requirement.',
        );
      }
    }
    final expectedStatus = cursor == this.requirements.length
        ? ManualConversionStatus.completed
        : ManualConversionStatus.active;
    if (status != ManualConversionStatus.invalidated &&
        status != expectedStatus) {
      throw ArgumentError('Session status does not match its cursor.');
    }
  }

  static const schemaId = 'turing-lab.manual-conversion-session';
  static const schemaVersion = 1;

  final String id;
  final ManualConversionDirection direction;
  final ManualConversionSource source;
  final List<ManualConversionRequirement> requirements;
  final List<ManualConversionAction> actions;
  final int cursor;
  final ManualConversionStatus status;
  final Map<String, Object?> canonicalArtifact;
  final ManualConversionEvidence completionEvidence;
  final String? parentSessionId;
  final int? parentCursor;

  bool get canUndo =>
      status != ManualConversionStatus.invalidated && cursor > 0;
  bool get canRedo =>
      status != ManualConversionStatus.invalidated && cursor < actions.length;
  bool get isComplete => status == ManualConversionStatus.completed;
  int get revealedCount =>
      actions.take(cursor).where((action) => action.revealed).length;
  List<ManualConversionAction> get appliedActions =>
      List<ManualConversionAction>.unmodifiable(actions.take(cursor));
  ManualConversionRequirement? get currentRequirement =>
      cursor < requirements.length ? requirements[cursor] : null;
  ManualConversionEvidence? get latestEvidence {
    for (final action in appliedActions.reversed) {
      if (action.validationEvidence != null) return action.validationEvidence;
    }
    return null;
  }

  Map<String, Object?>? get learnerArtifact {
    for (final action in appliedActions.reversed) {
      if (action.learnerArtifact != null) return action.learnerArtifact;
    }
    return null;
  }

  static ManualConversionSession start({
    required String id,
    required ManualConversionDirection direction,
    required ManualConversionSource source,
    required Iterable<ManualConversionRequirement> requirements,
    required Map<String, Object?> canonicalArtifact,
    required ManualConversionEvidence completionEvidence,
  }) {
    final frozenRequirements = List<ManualConversionRequirement>.of(
      requirements,
    );
    return ManualConversionSession._(
      id: id,
      direction: direction,
      source: source,
      requirements: frozenRequirements,
      actions: const [],
      cursor: 0,
      status: frozenRequirements.isEmpty
          ? ManualConversionStatus.completed
          : ManualConversionStatus.active,
      canonicalArtifact: canonicalArtifact,
      completionEvidence: completionEvidence,
    );
  }

  ManualConversionCommandResult apply({
    required String requirementId,
    required ManualConversionActionType type,
    required Map<String, Object?> payload,
  }) {
    if (status == ManualConversionStatus.invalidated) {
      return _failure(
        ManualConversionDiagnosticCode.sourceChanged,
        'The source document changed. Restart or branch from the new revision.',
      );
    }
    final requirement = currentRequirement;
    if (requirement == null) {
      return _failure(
        ManualConversionDiagnosticCode.sessionComplete,
        'The construction is already complete.',
      );
    }
    if (requirement.id != requirementId) {
      return _failure(
        ManualConversionDiagnosticCode.actionOutOfOrder,
        'Complete ${requirement.id} before $requirementId.',
        requirementId: requirement.id,
      );
    }
    if (requirement.type != type) {
      return _failure(
        ManualConversionDiagnosticCode.actionTypeMismatch,
        'This step requires ${requirement.type.name}.',
        requirementId: requirement.id,
      );
    }
    if (!requirement.accepts(payload)) {
      return _failure(
        ManualConversionDiagnosticCode.invalidPayload,
        'The construction does not satisfy this step yet.',
        requirementId: requirement.id,
      );
    }
    return ManualConversionCommandResult(
      session: _append(
        ManualConversionAction(
          id: '$id.action.${cursor + 1}',
          requirementId: requirement.id,
          type: type,
          payload: payload,
        ),
      ),
    );
  }

  ManualConversionCommandResult applyValidated({
    required String requirementId,
    required ManualConversionActionType type,
    required Map<String, Object?> payload,
    required ManualConversionEvidence validationEvidence,
    required Map<String, Object?> learnerArtifact,
  }) {
    if (status == ManualConversionStatus.invalidated) {
      return _failure(
        ManualConversionDiagnosticCode.sourceChanged,
        'The source document changed. Restart or branch from the new revision.',
      );
    }
    final requirement = currentRequirement;
    if (requirement == null) {
      return _failure(
        ManualConversionDiagnosticCode.sessionComplete,
        'The construction is already complete.',
      );
    }
    if (requirement.id != requirementId) {
      return _failure(
        ManualConversionDiagnosticCode.actionOutOfOrder,
        'Complete ${requirement.id} before $requirementId.',
        requirementId: requirement.id,
      );
    }
    if (requirement.type != type) {
      return _failure(
        ManualConversionDiagnosticCode.actionTypeMismatch,
        'This step requires ${requirement.type.name}.',
        requirementId: requirement.id,
      );
    }
    return ManualConversionCommandResult(
      session: _append(
        ManualConversionAction(
          id: '$id.action.${cursor + 1}',
          requirementId: requirement.id,
          type: type,
          payload: payload,
          validatedExternally: true,
          validationEvidence: validationEvidence,
          learnerArtifact: learnerArtifact,
        ),
      ),
    );
  }

  ManualConversionCommandResult revealCurrent() {
    if (status == ManualConversionStatus.invalidated) {
      return _failure(
        ManualConversionDiagnosticCode.sourceChanged,
        'The source document changed. Restart or branch from the new revision.',
      );
    }
    final requirement = currentRequirement;
    if (requirement == null) {
      return _failure(
        ManualConversionDiagnosticCode.sessionComplete,
        'The construction is already complete.',
      );
    }
    return ManualConversionCommandResult(
      session: _append(
        ManualConversionAction(
          id: '$id.action.${cursor + 1}',
          requirementId: requirement.id,
          type: requirement.type,
          payload: requirement.expectedPayload,
          revealed: true,
        ),
      ),
    );
  }

  /// Marks the latest applied action as an explicit reveal without discarding
  /// externally validated evidence or the learner artifact it produced.
  ManualConversionSession markLatestActionRevealed() {
    if (cursor == 0) {
      throw StateError('There is no applied action to mark as revealed.');
    }
    final index = cursor - 1;
    final current = actions[index];
    if (current.revealed) return this;
    final updated = ManualConversionAction(
      id: current.id,
      requirementId: current.requirementId,
      type: current.type,
      payload: current.payload,
      revealed: true,
      validatedExternally: current.validatedExternally,
      validationEvidence: current.validationEvidence,
      learnerArtifact: current.learnerArtifact,
    );
    return _copy(
      actions: [...actions.take(index), updated, ...actions.skip(index + 1)],
    );
  }

  ManualConversionCommandResult undo() {
    if (status == ManualConversionStatus.invalidated) {
      return _failure(
        ManualConversionDiagnosticCode.sourceChanged,
        'The source document changed. Restart or branch from the new revision.',
      );
    }
    if (!canUndo) {
      return _failure(
        ManualConversionDiagnosticCode.nothingToUndo,
        'There is no applied action to undo.',
      );
    }
    return ManualConversionCommandResult(session: _copy(cursor: cursor - 1));
  }

  ManualConversionCommandResult redo() {
    if (status == ManualConversionStatus.invalidated) {
      return _failure(
        ManualConversionDiagnosticCode.sourceChanged,
        'The source document changed. Restart or branch from the new revision.',
      );
    }
    if (!canRedo) {
      return _failure(
        ManualConversionDiagnosticCode.nothingToRedo,
        'There is no action to redo.',
      );
    }
    return ManualConversionCommandResult(session: _copy(cursor: cursor + 1));
  }

  ManualConversionSession restart() {
    if (status == ManualConversionStatus.invalidated) return this;
    return _copy(
      actions: const [],
      cursor: 0,
      status: requirements.isEmpty
          ? ManualConversionStatus.completed
          : ManualConversionStatus.active,
    );
  }

  ManualConversionSession branch({required String branchId}) {
    return ManualConversionSession._(
      id: branchId,
      direction: direction,
      source: source,
      requirements: requirements,
      actions: actions.take(cursor),
      cursor: cursor,
      status: status,
      canonicalArtifact: canonicalArtifact,
      completionEvidence: completionEvidence,
      parentSessionId: id,
      parentCursor: cursor,
    );
  }

  ManualConversionSession restartFromNewSource({
    required ManualConversionSession freshSession,
  }) {
    _validateFreshSourceContract(freshSession);
    return ManualConversionSession._(
      id: id,
      direction: direction,
      source: freshSession.source,
      requirements: freshSession.requirements,
      actions: const [],
      cursor: 0,
      status: freshSession.status,
      canonicalArtifact: freshSession.canonicalArtifact,
      completionEvidence: freshSession.completionEvidence,
      parentSessionId: parentSessionId,
      parentCursor: parentCursor,
    );
  }

  ManualConversionSession branchFromNewSource({
    required String branchId,
    required ManualConversionSession freshSession,
  }) {
    _validateFreshSourceContract(freshSession);
    if (branchId.isEmpty) {
      throw ArgumentError.value(branchId, 'branchId', 'Must not be empty.');
    }
    return ManualConversionSession._(
      id: branchId,
      direction: direction,
      source: freshSession.source,
      requirements: freshSession.requirements,
      actions: const [],
      cursor: 0,
      status: freshSession.status,
      canonicalArtifact: freshSession.canonicalArtifact,
      completionEvidence: freshSession.completionEvidence,
      parentSessionId: id,
      parentCursor: cursor,
    );
  }

  ManualConversionSession checkSource({
    required String documentId,
    required int revision,
  }) {
    if (source.matches(documentId: documentId, revision: revision)) return this;
    return _copy(status: ManualConversionStatus.invalidated);
  }

  void _validateFreshSourceContract(ManualConversionSession freshSession) {
    if (freshSession.direction != direction) {
      throw ArgumentError('The replacement session has another direction.');
    }
    if (freshSession.actions.isNotEmpty || freshSession.cursor != 0) {
      throw ArgumentError('The replacement session must be fresh.');
    }
    if (freshSession.status == ManualConversionStatus.invalidated) {
      throw ArgumentError('The replacement source is already invalidated.');
    }
    if (source.matches(
      documentId: freshSession.source.documentId,
      revision: freshSession.source.revision,
    )) {
      throw ArgumentError('The replacement session must use a new source.');
    }
  }

  ManualConversionSession _append(ManualConversionAction action) {
    final nextActions = <ManualConversionAction>[
      ...actions.take(cursor),
      action,
    ];
    final nextCursor = cursor + 1;
    return _copy(
      actions: nextActions,
      cursor: nextCursor,
      status: nextCursor == requirements.length
          ? ManualConversionStatus.completed
          : ManualConversionStatus.active,
    );
  }

  ManualConversionCommandResult _failure(
    ManualConversionDiagnosticCode code,
    String message, {
    String? requirementId,
  }) {
    return ManualConversionCommandResult(
      session: this,
      diagnostics: [
        ManualConversionDiagnostic(
          code: code,
          message: message,
          requirementId: requirementId,
        ),
      ],
    );
  }

  ManualConversionSession _copy({
    Iterable<ManualConversionAction>? actions,
    int? cursor,
    ManualConversionStatus? status,
  }) {
    final resolvedCursor = cursor ?? this.cursor;
    final resolvedStatus =
        status ??
        (this.status == ManualConversionStatus.invalidated
            ? ManualConversionStatus.invalidated
            : resolvedCursor == requirements.length
            ? ManualConversionStatus.completed
            : ManualConversionStatus.active);
    return ManualConversionSession._(
      id: id,
      direction: direction,
      source: source,
      requirements: requirements,
      actions: actions ?? this.actions,
      cursor: resolvedCursor,
      status: resolvedStatus,
      canonicalArtifact: canonicalArtifact,
      completionEvidence: completionEvidence,
      parentSessionId: parentSessionId,
      parentCursor: parentCursor,
    );
  }

  Map<String, Object?> toJson() => {
    'schema': schemaId,
    'version': schemaVersion,
    'id': id,
    'direction': direction.name,
    'source': source.toJson(),
    'requirements': requirements.map((value) => value.toJson()).toList(),
    'actions': actions.map((value) => value.toJson()).toList(),
    'cursor': cursor,
    'status': status.name,
    'canonicalArtifact': canonicalArtifact,
    'completionEvidence': completionEvidence.toJson(),
    'parentSessionId': parentSessionId,
    'parentCursor': parentCursor,
  };

  static ManualConversionRestoreResult restore(
    Object? encoded, {
    required String documentId,
    required int revision,
  }) {
    try {
      final map = _objectMap(encoded, 'session');
      if (map['schema'] != schemaId || map['version'] != schemaVersion) {
        return const ManualConversionRestoreResult(
          diagnostics: [
            ManualConversionDiagnostic(
              code: ManualConversionDiagnosticCode.unsupportedSchema,
              message: 'This saved construction uses an unsupported schema.',
            ),
          ],
        );
      }
      final source = ManualConversionSource.fromJson(map['source']);
      if (!source.matches(documentId: documentId, revision: revision)) {
        return const ManualConversionRestoreResult(
          diagnostics: [
            ManualConversionDiagnostic(
              code: ManualConversionDiagnosticCode.sourceChanged,
              message:
                  'The saved construction belongs to another source revision.',
            ),
          ],
        );
      }
      final requirements = map['requirements'];
      final actions = map['actions'];
      final canonicalArtifact = map['canonicalArtifact'];
      final id = map['id'];
      final direction = map['direction'];
      final cursor = map['cursor'];
      final status = map['status'];
      final parentSessionId = map['parentSessionId'];
      final parentCursor = map['parentCursor'];
      if (id is! String ||
          direction is! String ||
          requirements is! List ||
          actions is! List ||
          cursor is! int ||
          status is! String ||
          canonicalArtifact is! Map ||
          parentSessionId is! String? ||
          parentCursor is! int?) {
        throw const FormatException('Malformed manual conversion session.');
      }
      return ManualConversionRestoreResult(
        session: ManualConversionSession._(
          id: id,
          direction: ManualConversionDirection.values.byName(direction),
          source: source,
          requirements: requirements.map(ManualConversionRequirement.fromJson),
          actions: actions.map(ManualConversionAction.fromJson),
          cursor: cursor,
          status: ManualConversionStatus.values.byName(status),
          canonicalArtifact: Map<String, Object?>.from(canonicalArtifact),
          completionEvidence: ManualConversionEvidence.fromJson(
            map['completionEvidence'],
          ),
          parentSessionId: parentSessionId,
          parentCursor: parentCursor,
        ),
      );
    } on Object {
      return const ManualConversionRestoreResult(
        diagnostics: [
          ManualConversionDiagnostic(
            code: ManualConversionDiagnosticCode.malformedPayload,
            message: 'The saved construction is malformed.',
          ),
        ],
      );
    }
  }
}

Map<String, Object?> _objectMap(Object? encoded, String label) {
  if (encoded is! Map) {
    throw FormatException('Manual conversion $label must be an object.');
  }
  return Map<String, Object?>.from(encoded);
}

Map<String, Object?> _freezeMap(Map<String, Object?> source) {
  return Map<String, Object?>.unmodifiable(
    source.map((key, value) => MapEntry(key, _freezeValue(value))),
  );
}

Object? _freezeValue(Object? value) {
  if (value is Map) {
    return _freezeMap(Map<String, Object?>.from(value));
  }
  if (value is Iterable) {
    return List<Object?>.unmodifiable(value.map(_freezeValue));
  }
  return value;
}

bool _deepEquals(Object? left, Object? right) {
  if (identical(left, right)) return true;
  if (left is Map && right is Map) {
    if (left.length != right.length) return false;
    for (final entry in left.entries) {
      if (!right.containsKey(entry.key) ||
          !_deepEquals(entry.value, right[entry.key])) {
        return false;
      }
    }
    return true;
  }
  if (left is Iterable && right is Iterable) {
    final leftValues = left.toList(growable: false);
    final rightValues = right.toList(growable: false);
    if (leftValues.length != rightValues.length) return false;
    for (var index = 0; index < leftValues.length; index++) {
      if (!_deepEquals(leftValues[index], rightValues[index])) return false;
    }
    return true;
  }
  return left == right;
}
