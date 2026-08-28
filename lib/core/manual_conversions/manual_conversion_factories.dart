import '../algorithms/equivalence_checker.dart';
import '../algorithms/regex_to_nfa_converter.dart';
import '../models/fsa.dart';
import 'fa_to_regex_manual.dart';
import 'manual_conversion_content.dart';
import 'manual_conversion_session.dart';

/// Builds concrete learner sessions from canonical conversion oracles.
final class ManualConversionFactories {
  const ManualConversionFactories._();

  /// Builds a deterministic canonical FA-to-regex construction session.
  ///
  /// The resulting requirements describe one valid elimination order. The
  /// interactive controller may rebuild a session after a learner chooses a
  /// different eliminable state; the underlying oracle accepts any order.
  static ManualConversionSession faToRegex({
    required FSA source,
    required int sourceRevision,
    String? sessionId,
    Iterable<String> eliminationPrefix = const <String>[],
  }) {
    if (sourceRevision < 0) {
      throw ArgumentError.value(sourceRevision, 'sourceRevision');
    }

    final normalized = FaToRegexManualOracle.normalize(source);
    final requirements = <ManualConversionRequirement>[
      _normalizationRequirement(source, normalized),
    ];
    final eliminationArtifacts = <Map<String, Object?>>[];
    final allProvenanceIds = <String>{
      ...source.states.map((state) => state.id),
    };
    final remainingStateIds = normalized.removableStateIds.toList()..sort();
    final eliminationOrder = <String>[];
    for (final stateId in eliminationPrefix) {
      if (!remainingStateIds.remove(stateId)) {
        throw ArgumentError.value(
          eliminationPrefix,
          'eliminationPrefix',
          'State IDs must be unique eliminable source states.',
        );
      }
      eliminationOrder.add(stateId);
    }
    eliminationOrder.addAll(remainingStateIds);
    var current = normalized;

    for (final stateId in eliminationOrder) {
      final inspection = FaToRegexManualOracle.inspectElimination(
        current,
        stateId,
      );
      requirements.add(_selectionRequirement(current, inspection));
      for (final formula in inspection.formulas) {
        requirements.add(_pairRequirement(inspection, formula));
        allProvenanceIds.addAll(_formulaProvenance(inspection, formula));
      }
      requirements.add(_commitRequirement(inspection));
      eliminationArtifacts.add(_inspectionArtifact(inspection));
      current = FaToRegexManualOracle.applyElimination(
        gnfa: current,
        inspection: inspection,
        pairLabels: {
          for (final formula in inspection.formulas)
            formula.pair: formula.expectedExpression,
        },
      );
    }

    final regex = FaToRegexManualOracle.finalRegex(current);
    final exactEquivalent = _isExactlyEquivalent(source, regex);
    if (!exactEquivalent) {
      throw StateError(
        'The FA-to-regex oracle produced a non-equivalent canonical artifact.',
      );
    }
    requirements.add(
      _completionRequirement(regex: regex, provenanceIds: allProvenanceIds),
    );

    final resolvedSessionId =
        sessionId ??
        'manual.fa-to-regex.${source.id}.$sourceRevision.'
            '${normalized.sourceRevision.split('@').last}';
    return ManualConversionSession.start(
      id: resolvedSessionId,
      direction: ManualConversionDirection.faToRegex,
      source: ManualConversionSource(
        documentId: source.id,
        revision: sourceRevision,
        snapshot: {
          'document': _canonicalSourceSnapshot(source),
          'oracleRevision': normalized.sourceRevision,
        },
      ),
      requirements: requirements,
      canonicalArtifact: {
        'schema': 'turing-lab.fa-to-regex-canonical',
        'version': 1,
        'oracleRevision': normalized.sourceRevision,
        'normalizedGnfa': _gnfaArtifact(normalized),
        'eliminationOrder': eliminationOrder,
        'eliminations': eliminationArtifacts,
        'finalGnfa': _gnfaArtifact(current),
        'regex': regex,
        'exactEquivalent': true,
      },
      completionEvidence: ManualConversionEvidence(
        summary:
            'The canonical regex is exactly language-equivalent to the source FSA.',
        certainty: ManualConversionCertainty.exact,
        provenanceIds: allProvenanceIds.toList()..sort(),
      ),
    );
  }

  /// Rebuilds a FA-to-regex trace around learner-selected elimination states.
  ///
  /// Already accepted actions are replayed against the rebuilt immutable
  /// requirements, preserving reveal evidence and the current cursor.
  static ManualConversionSession rebaseFaToRegexSelection({
    required FSA source,
    required int sourceRevision,
    required ManualConversionSession acceptedSession,
  }) {
    if (acceptedSession.direction != ManualConversionDirection.faToRegex ||
        !acceptedSession.source.matches(
          documentId: source.id,
          revision: sourceRevision,
        )) {
      throw ArgumentError(
        'The accepted session does not belong to this FA-to-regex source.',
      );
    }
    if (acceptedSession.cursor == 0) return acceptedSession;
    final lastAction = acceptedSession.appliedActions.last;
    if (lastAction.type != ManualConversionActionType.selectState) {
      return acceptedSession;
    }
    final requirement =
        acceptedSession.requirements[acceptedSession.cursor - 1];
    if (lastAction.payload['stateId'] ==
        requirement.expectedPayload['stateId']) {
      return acceptedSession;
    }

    final selectedStateIds = acceptedSession.appliedActions
        .where(
          (action) => action.type == ManualConversionActionType.selectState,
        )
        .map((action) => action.payload['stateId'])
        .whereType<String>()
        .toList(growable: false);
    var rebuilt = faToRegex(
      source: source,
      sourceRevision: sourceRevision,
      sessionId: acceptedSession.id,
      eliminationPrefix: selectedStateIds,
    );
    for (final action in acceptedSession.appliedActions) {
      final replay = action.revealed
          ? rebuilt.revealCurrent()
          : action.validatedExternally
          ? rebuilt.applyValidated(
              requirementId: action.requirementId,
              type: action.type,
              payload: action.payload,
              validationEvidence: action.validationEvidence!,
              learnerArtifact: action.learnerArtifact!,
            )
          : rebuilt.apply(
              requirementId: action.requirementId,
              type: action.type,
              payload: action.payload,
            );
      if (!replay.isSuccess) {
        throw StateError(
          'Could not replay ${action.id} after changing elimination order.',
        );
      }
      rebuilt = replay.session;
    }
    return rebuilt;
  }

  /// Validates and records one learner-authored FA-to-regex step.
  static ManualConversionCommandResult applyFaToRegexLearnerStep({
    required FSA source,
    required ManualConversionSession session,
    required Map<String, Object?> payload,
  }) {
    final requirement = session.currentRequirement;
    if (requirement == null) {
      return _faRegexFailure(
        session,
        ManualConversionDiagnosticCode.sessionComplete,
        'The construction is already complete.',
      );
    }
    if (session.status == ManualConversionStatus.invalidated) {
      return _faRegexFailure(
        session,
        ManualConversionDiagnosticCode.sourceChanged,
        'The source document changed. Restart or branch from the new revision.',
      );
    }

    try {
      final replay = _replayFaToRegex(source, session.appliedActions);
      return switch (requirement.type) {
        ManualConversionActionType.normalizeEndpoints => _applyValidatedFaRegex(
          session: session,
          requirement: requirement,
          payload: payload,
          isValid: requirement.accepts(payload),
          message: 'The GNFA endpoints do not match the source automaton.',
          artifact: _faRegexLearnerArtifact(replay.gnfa),
          evidence: requirement.evidence,
        ),
        ManualConversionActionType.selectState => _applyFaRegexSelection(
          session,
          requirement,
          replay,
          payload,
        ),
        ManualConversionActionType.submitPairExpression => _applyFaRegexPair(
          session,
          requirement,
          replay,
          payload,
        ),
        ManualConversionActionType.commitElimination => _applyFaRegexCommit(
          session,
          requirement,
          replay,
          payload,
        ),
        ManualConversionActionType.complete => _applyFaRegexCompletion(
          source,
          session,
          requirement,
          replay,
          payload,
        ),
        _ => _faRegexFailure(
          session,
          ManualConversionDiagnosticCode.actionTypeMismatch,
          'This action is not part of FA-to-regex construction.',
        ),
      };
    } on FaToRegexManualException catch (error) {
      return _faRegexFailure(
        session,
        ManualConversionDiagnosticCode.invalidPayload,
        error.message,
      );
    }
  }
}

ManualConversionCommandResult _applyFaRegexSelection(
  ManualConversionSession session,
  ManualConversionRequirement requirement,
  _FaRegexReplay replay,
  Map<String, Object?> payload,
) {
  final stateId = payload['stateId'];
  if (stateId is! String || !requirement.accepts(payload)) {
    return _faRegexFailure(
      session,
      ManualConversionDiagnosticCode.invalidPayload,
      'Choose an internal GNFA state that has not been eliminated.',
    );
  }
  final inspection = FaToRegexManualOracle.inspectElimination(
    replay.gnfa,
    stateId,
  );
  return session.applyValidated(
    requirementId: requirement.id,
    type: requirement.type,
    payload: payload,
    validationEvidence: ManualConversionEvidence(
      summary: 'The selected state is an eliminable internal GNFA state.',
      provenanceIds: [stateId],
    ),
    learnerArtifact: _faRegexLearnerArtifact(
      replay.gnfa,
      inspection: inspection,
    ),
  );
}

ManualConversionCommandResult _applyFaRegexPair(
  ManualConversionSession session,
  ManualConversionRequirement requirement,
  _FaRegexReplay replay,
  Map<String, Object?> payload,
) {
  final fromStateId = payload['fromStateId'];
  final toStateId = payload['toStateId'];
  final expression = payload['expression'];
  final inspection = replay.inspection;
  if (fromStateId is! String ||
      toStateId is! String ||
      expression is! String ||
      inspection == null) {
    return _faRegexFailure(
      session,
      ManualConversionDiagnosticCode.invalidPayload,
      'Enter the affected state pair and its resulting expression.',
    );
  }
  final pair = FaToRegexStatePair(fromStateId, toStateId);
  final validation = FaToRegexManualOracle.validatePairLabel(
    gnfa: replay.gnfa,
    inspection: inspection,
    pair: pair,
    learnerExpression: expression,
  );
  if (!validation.isValid) {
    return _faRegexFailure(
      session,
      ManualConversionDiagnosticCode.invalidPayload,
      validation.message ?? 'The submitted expression is not equivalent.',
    );
  }
  final labels = {...replay.pairLabels, pair: expression.trim()};
  return session.applyValidated(
    requirementId: requirement.id,
    type: requirement.type,
    payload: payload,
    validationEvidence: ManualConversionEvidence(
      summary: validation.isExactTextMatch
          ? 'The pair label matches the canonical elimination formula.'
          : 'The pair label is exactly language-equivalent to the elimination formula.',
      certainty: ManualConversionCertainty.exact,
      provenanceIds: requirement.provenanceIds,
    ),
    learnerArtifact: _faRegexLearnerArtifact(
      replay.gnfa,
      inspection: inspection,
      pairLabels: labels,
    ),
  );
}

ManualConversionCommandResult _applyFaRegexCommit(
  ManualConversionSession session,
  ManualConversionRequirement requirement,
  _FaRegexReplay replay,
  Map<String, Object?> payload,
) {
  final inspection = replay.inspection;
  if (inspection == null || !requirement.accepts(payload)) {
    return _faRegexFailure(
      session,
      ManualConversionDiagnosticCode.invalidPayload,
      'Finish every affected pair label before committing the elimination.',
    );
  }
  final nextGnfa = FaToRegexManualOracle.applyElimination(
    gnfa: replay.gnfa,
    inspection: inspection,
    pairLabels: replay.pairLabels,
  );
  return session.applyValidated(
    requirementId: requirement.id,
    type: requirement.type,
    payload: payload,
    validationEvidence: ManualConversionEvidence(
      summary:
          'Every affected pair is valid, so the selected state can be removed.',
      certainty: ManualConversionCertainty.exact,
      provenanceIds: requirement.provenanceIds,
    ),
    learnerArtifact: _faRegexLearnerArtifact(nextGnfa),
  );
}

ManualConversionCommandResult _applyFaRegexCompletion(
  FSA source,
  ManualConversionSession session,
  ManualConversionRequirement requirement,
  _FaRegexReplay replay,
  Map<String, Object?> payload,
) {
  final expression = payload['regex'];
  if (expression is! String || !_isExactlyEquivalent(source, expression)) {
    return _faRegexFailure(
      session,
      ManualConversionDiagnosticCode.invalidPayload,
      'The completed expression is not exactly equivalent to the source FA.',
    );
  }
  return session.applyValidated(
    requirementId: requirement.id,
    type: requirement.type,
    payload: payload,
    validationEvidence: ManualConversionEvidence(
      summary:
          'The learner expression is exactly language-equivalent to the source FA.',
      certainty: ManualConversionCertainty.exact,
      provenanceIds: requirement.provenanceIds,
    ),
    learnerArtifact: {
      'schema': 'turing-lab.fa-to-regex-learner',
      'version': 1,
      'regex': expression,
      'gnfa': _gnfaArtifact(replay.gnfa),
    },
  );
}

ManualConversionCommandResult _applyValidatedFaRegex({
  required ManualConversionSession session,
  required ManualConversionRequirement requirement,
  required Map<String, Object?> payload,
  required bool isValid,
  required String message,
  required Map<String, Object?> artifact,
  required ManualConversionEvidence evidence,
}) {
  if (!isValid) {
    return _faRegexFailure(
      session,
      ManualConversionDiagnosticCode.invalidPayload,
      message,
    );
  }
  return session.applyValidated(
    requirementId: requirement.id,
    type: requirement.type,
    payload: payload,
    validationEvidence: evidence,
    learnerArtifact: artifact,
  );
}

ManualConversionCommandResult _faRegexFailure(
  ManualConversionSession session,
  ManualConversionDiagnosticCode code,
  String message,
) => ManualConversionCommandResult(
  session: session,
  diagnostics: [
    ManualConversionDiagnostic(
      code: code,
      message: message,
      requirementId: session.currentRequirement?.id,
    ),
  ],
);

_FaRegexReplay _replayFaToRegex(
  FSA source,
  Iterable<ManualConversionAction> actions,
) {
  var gnfa = FaToRegexManualOracle.normalize(source);
  FaToRegexEliminationInspection? inspection;
  var labels = <FaToRegexStatePair, String>{};
  for (final action in actions) {
    switch (action.type) {
      case ManualConversionActionType.selectState:
        inspection = FaToRegexManualOracle.inspectElimination(
          gnfa,
          action.payload['stateId']! as String,
        );
        labels = <FaToRegexStatePair, String>{};
      case ManualConversionActionType.submitPairExpression:
        labels[FaToRegexStatePair(
              action.payload['fromStateId']! as String,
              action.payload['toStateId']! as String,
            )] =
            action.payload['expression']! as String;
      case ManualConversionActionType.commitElimination:
        gnfa = FaToRegexManualOracle.applyElimination(
          gnfa: gnfa,
          inspection: inspection!,
          pairLabels: labels,
        );
        inspection = null;
        labels = <FaToRegexStatePair, String>{};
      default:
        break;
    }
  }
  return _FaRegexReplay(gnfa, inspection, labels);
}

Map<String, Object?> _faRegexLearnerArtifact(
  FaToRegexGnfa gnfa, {
  FaToRegexEliminationInspection? inspection,
  Map<FaToRegexStatePair, String> pairLabels = const {},
}) => {
  'schema': 'turing-lab.fa-to-regex-learner',
  'version': 1,
  'gnfa': _gnfaArtifact(gnfa),
  'selectedStateId': inspection?.stateId,
  'pairLabels': [
    for (final entry
        in (pairLabels.entries.toList()
          ..sort((left, right) => left.key.compareTo(right.key))))
      {
        'fromStateId': entry.key.fromStateId,
        'toStateId': entry.key.toStateId,
        'expression': entry.value,
      },
  ],
};

final class _FaRegexReplay {
  const _FaRegexReplay(this.gnfa, this.inspection, this.pairLabels);

  final FaToRegexGnfa gnfa;
  final FaToRegexEliminationInspection? inspection;
  final Map<FaToRegexStatePair, String> pairLabels;
}

Map<String, Object?> _canonicalSourceSnapshot(FSA source) {
  final states = source.states.toList()
    ..sort((left, right) => left.id.compareTo(right.id));
  final transitions = source.fsaTransitions.toList()
    ..sort((left, right) => left.id.compareTo(right.id));
  final acceptingStates = source.acceptingStates.toList()
    ..sort((left, right) => left.id.compareTo(right.id));
  final alphabet = source.alphabet.toList()..sort();
  return {
    'id': source.id,
    'name': source.name,
    'type': 'FSA',
    'states': states.map((state) => state.toJson()).toList(growable: false),
    'transitions': transitions
        .map((transition) => transition.toJson())
        .toList(growable: false),
    'alphabet': alphabet,
    'initialState': source.initialState?.toJson(),
    'acceptingStates': acceptingStates
        .map((state) => state.toJson())
        .toList(growable: false),
    'created': source.created.toIso8601String(),
    'modified': source.modified.toIso8601String(),
    'bounds': {
      'x': source.bounds.left,
      'y': source.bounds.top,
      'width': source.bounds.width,
      'height': source.bounds.height,
    },
    'zoomLevel': source.zoomLevel,
    'panOffset': {'x': source.panOffset.x, 'y': source.panOffset.y},
  };
}

ManualConversionRequirement _normalizationRequirement(
  FSA source,
  FaToRegexGnfa normalized,
) {
  final acceptingStateIds =
      source.acceptingStates.map((state) => state.id).toList()..sort();
  final initialStateId = source.initialState!.id;
  final payload = <String, Object?>{
    'startStateId': normalized.startStateId,
    'finalStateId': normalized.finalStateId,
    'initialStateId': initialStateId,
    'acceptingStateIds': acceptingStateIds,
    'endpointExpression': 'ε',
  };
  return ManualConversionRequirement(
    id: 'fa-to-regex.normalize',
    contentReference: ManualConversionContent.faToRegexNormalize,
    type: ManualConversionActionType.normalizeEndpoints,
    title: 'Normalize the finite automaton as a GNFA',
    instruction:
        'Add protected start and final states, then connect the original endpoints with epsilon labels.',
    expectedPayload: payload,
    allowedPayloadKeys: payload.keys,
    provenanceIds: [initialStateId, ...acceptingStateIds],
    hint:
        'The new start points to source state $initialStateId. Every source accepting state points to the new final state.',
    revealExplanation:
        'Create ${normalized.startStateId} and ${normalized.finalStateId}; use ε on every endpoint bridge.',
    evidence: ManualConversionEvidence(
      summary:
          'Fresh endpoints protect the GNFA boundaries during elimination.',
      certainty: ManualConversionCertainty.structural,
      provenanceIds: [initialStateId, ...acceptingStateIds],
    ),
  );
}

ManualConversionRequirement _selectionRequirement(
  FaToRegexGnfa gnfa,
  FaToRegexEliminationInspection inspection,
) {
  final payload = <String, Object?>{'stateId': inspection.stateId};
  return ManualConversionRequirement(
    id: 'fa-to-regex.${inspection.gnfaRevision}.select',
    contentReference: ManualConversionContent.faToRegexSelectState,
    type: ManualConversionActionType.selectState,
    title: 'Select state ${inspection.stateId}',
    instruction:
        'Select the next internal state in this canonical elimination trace.',
    expectedPayload: payload,
    acceptedPayloads: gnfa.removableStateIds.map(
      (stateId) => <String, Object?>{'stateId': stateId},
    ),
    supportingData: {
      'eliminableStateIds': gnfa.removableStateIds.toList()..sort(),
      'protectedStateIds': [gnfa.startStateId, gnfa.finalStateId],
    },
    allowedPayloadKeys: payload.keys,
    provenanceIds: [inspection.stateId],
    hint:
        '${gnfa.startStateId} and ${gnfa.finalStateId} are protected. This trace next removes ${inspection.stateId}.',
    revealExplanation:
        '${inspection.stateId} is internal, so eliminating it preserves both protected endpoints.',
    evidence: ManualConversionEvidence(
      summary: 'The selected state is neither the GNFA start nor final state.',
      provenanceIds: [inspection.stateId],
    ),
  );
}

ManualConversionRequirement _pairRequirement(
  FaToRegexEliminationInspection inspection,
  FaToRegexPairFormula formula,
) {
  final payload = <String, Object?>{
    'fromStateId': formula.pair.fromStateId,
    'toStateId': formula.pair.toStateId,
    'expression': formula.expectedExpression,
  };
  final provenance = _formulaProvenance(inspection, formula);
  return ManualConversionRequirement(
    id: 'fa-to-regex.${formula.id}.pair',
    contentReference: ManualConversionContent.faToRegexPairExpression,
    type: ManualConversionActionType.submitPairExpression,
    title: 'Update ${formula.pair.fromStateId} → ${formula.pair.toStateId}',
    instruction:
        'Enter the label produced by R_ij ∪ R_ik(R_kk)*R_kj for the selected state.',
    expectedPayload: payload,
    allowedPayloadKeys: payload.keys,
    provenanceIds: provenance,
    supportingData: {
      'selectedStateId': inspection.stateId,
      'fromStateId': formula.pair.fromStateId,
      'toStateId': formula.pair.toStateId,
      'directExpression': formula.directExpression,
      'incomingExpression': formula.incomingExpression,
      'loopExpression': formula.loopExpression,
      'outgoingExpression': formula.outgoingExpression,
      'formula': 'R_ij ∪ R_ik(R_kk)*R_kj',
    },
    hint:
        'Inspect the direct edge and the three labels touching ${inspection.stateId}. The hint does not change the construction.',
    revealExplanation:
        'R_ij=${formula.directExpression}, '
        'R_ik=${formula.incomingExpression}, '
        'R_kk=${formula.loopExpression}, '
        'R_kj=${formula.outgoingExpression}; '
        'the resulting label is ${formula.expectedExpression}.',
    evidence: ManualConversionEvidence(
      summary:
          'The pair label follows the GNFA state-elimination identity exactly.',
      certainty: ManualConversionCertainty.exact,
      provenanceIds: provenance,
    ),
  );
}

ManualConversionRequirement _commitRequirement(
  FaToRegexEliminationInspection inspection,
) {
  final payload = <String, Object?>{
    'stateId': inspection.stateId,
    'pairCount': inspection.formulas.length,
  };
  final provenance = <String>{inspection.stateId};
  for (final formula in inspection.formulas) {
    provenance.addAll(_formulaProvenance(inspection, formula));
  }
  final sortedProvenance = provenance.toList()..sort();
  return ManualConversionRequirement(
    id: 'fa-to-regex.${inspection.gnfaRevision}.commit',
    contentReference: ManualConversionContent.faToRegexCommitElimination,
    type: ManualConversionActionType.commitElimination,
    title: 'Commit elimination of ${inspection.stateId}',
    instruction:
        'Remove the selected state after every affected pair label is valid.',
    expectedPayload: payload,
    allowedPayloadKeys: payload.keys,
    provenanceIds: sortedProvenance,
    supportingData: {
      'stateId': inspection.stateId,
      'pairCount': inspection.formulas.length,
    },
    hint:
        'There are ${inspection.formulas.length} affected pair labels in this elimination.',
    revealExplanation:
        'All ${inspection.formulas.length} pair labels are canonical; ${inspection.stateId} can now be removed.',
    evidence: ManualConversionEvidence(
      summary: 'All paths through the removed state remain represented.',
      certainty: ManualConversionCertainty.exact,
      provenanceIds: sortedProvenance,
    ),
  );
}

ManualConversionRequirement _completionRequirement({
  required String regex,
  required Set<String> provenanceIds,
}) {
  final payload = <String, Object?>{'regex': regex};
  final sortedProvenance = provenanceIds.toList()..sort();
  return ManualConversionRequirement(
    id: 'fa-to-regex.complete',
    contentReference: ManualConversionContent.faToRegexComplete,
    type: ManualConversionActionType.complete,
    title: 'Extract the regular expression',
    instruction:
        'Read the remaining label from the protected start state to the protected final state.',
    expectedPayload: payload,
    allowedPayloadKeys: payload.keys,
    provenanceIds: sortedProvenance,
    supportingData: const {'formula': 'R_start,final'},
    hint: 'Only the protected GNFA endpoints remain.',
    revealExplanation: 'The remaining start-to-final label is $regex.',
    evidence: ManualConversionEvidence(
      summary: 'The extracted regex is exactly equivalent to the source FSA.',
      certainty: ManualConversionCertainty.exact,
      provenanceIds: sortedProvenance,
    ),
  );
}

List<String> _formulaProvenance(
  FaToRegexEliminationInspection inspection,
  FaToRegexPairFormula formula,
) {
  final values = <String>{
    formula.id,
    inspection.stateId,
    formula.pair.fromStateId,
    formula.pair.toStateId,
  }.toList()..sort();
  return values;
}

Map<String, Object?> _inspectionArtifact(
  FaToRegexEliminationInspection inspection,
) {
  return {
    'stateId': inspection.stateId,
    'gnfaRevision': inspection.gnfaRevision,
    'incomingStateIds': inspection.incomingStateIds,
    'outgoingStateIds': inspection.outgoingStateIds,
    'loopExpression': inspection.loopExpression,
    'formulas': [
      for (final formula in inspection.formulas)
        {
          'id': formula.id,
          'fromStateId': formula.pair.fromStateId,
          'toStateId': formula.pair.toStateId,
          'directExpression': formula.directExpression,
          'incomingExpression': formula.incomingExpression,
          'loopExpression': formula.loopExpression,
          'outgoingExpression': formula.outgoingExpression,
          'bypassExpression': formula.bypassExpression,
          'expectedExpression': formula.expectedExpression,
        },
    ],
  };
}

Map<String, Object?> _gnfaArtifact(FaToRegexGnfa gnfa) {
  final labelEntries = gnfa.labels.entries.toList()
    ..sort((left, right) => left.key.compareTo(right.key));
  return {
    'id': gnfa.id,
    'revision': gnfa.revision,
    'startStateId': gnfa.startStateId,
    'finalStateId': gnfa.finalStateId,
    'states': [
      for (final state in gnfa.states)
        {
          'id': state.id,
          'label': state.label,
          'sourceStateId': state.sourceStateId,
          'isProtected': state.isProtected,
        },
    ],
    'labels': [
      for (final entry in labelEntries)
        {
          'fromStateId': entry.key.fromStateId,
          'toStateId': entry.key.toStateId,
          'expression': entry.value,
        },
    ],
  };
}

bool _isExactlyEquivalent(FSA source, String regex) {
  final converted = RegexToNFAConverter.convert(
    regex,
    contextAlphabet: source.alphabet,
  );
  if (!converted.isSuccess || converted.data == null) return false;
  final sharedAlphabet = <String>{
    ...source.alphabet,
    ...converted.data!.alphabet,
  };
  final result = EquivalenceChecker.areEquivalentResult(
    source.copyWith(alphabet: sharedAlphabet),
    converted.data!.copyWith(alphabet: sharedAlphabet),
  );
  return result.isSuccess && result.data == true;
}
