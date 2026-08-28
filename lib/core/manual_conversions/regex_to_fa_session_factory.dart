import '../educational_content/educational_content_reference.dart';
import '../models/fsa.dart';
import '../models/regex_document.dart';
import 'manual_conversion_session.dart';
import 'manual_conversion_content.dart';
import 'regex_to_fa_manual.dart';

/// Adapts the typed Regex-to-FA oracle to the shared persisted session model.
final class RegexToFaSessionFactory {
  const RegexToFaSessionFactory._();

  static ManualConversionSession create({
    required RegexDocument source,
    required int sourceRevision,
    String? sessionId,
  }) {
    if (sourceRevision < 0) {
      throw ArgumentError.value(sourceRevision, 'sourceRevision');
    }
    final start = RegexToFaManualSession.start(
      sourceDocument: source,
      sourceRevision: sourceRevision,
    );
    final typedStart = start.session;
    if (typedStart == null) {
      throw ArgumentError.value(
        source.source,
        'source',
        start.diagnostics.map((value) => value.message).join(' '),
      );
    }

    final requirements = <ManualConversionRequirement>[];
    final structuralArtifacts = <Map<String, Object?>>[];
    RegexToFaManualSession visit(
      RegexToFaManualSession current,
      String nodeId,
    ) {
      final node = current.ast.nodes[nodeId]!;
      for (final childId in node.childIds) {
        current = visit(current, childId);
      }
      final oracle = current.expectedFragment(nodeId);
      if (!oracle.isSuccess || oracle.fragment == null) {
        throw StateError(
          oracle.diagnostics.map((value) => value.message).join(' '),
        );
      }
      final fragment = oracle.fragment!;
      final payload = _payloadFor(node, fragment);
      final requirement = _requirementFor(node, payload);
      requirements.add(requirement);
      structuralArtifacts.add({
        'requirementId': requirement.id,
        'nodeId': node.id,
        'span': _spanJson(node.span),
        'evidence': requirement.evidence.toJson(),
        'invariants': payload['invariants'],
      });

      final result = _applyExpected(current, node, fragment);
      if (!result.isSuccess) {
        throw StateError(
          result.diagnostics.map((value) => value.message).join(' '),
        );
      }
      return result.session;
    }

    final typed = visit(typedStart, typedStart.ast.rootId);
    final finalFragment = typed.activeFragments[typed.ast.rootId];
    final exact = typed.exactComparison;
    if (!typed.isComplete || finalFragment == null || exact == null) {
      throw StateError('The Regex-to-FA oracle did not complete exactly.');
    }
    if (!exact.isEquivalent) {
      throw StateError(
        'The Regex-to-FA oracle produced a non-equivalent artifact.',
      );
    }

    final provenance = <String>{source.id, ...typed.ast.nodes.keys}.toList()
      ..sort();
    final resolvedId =
        sessionId ??
        'manual.regex-to-fa.${source.id}.$sourceRevision.'
            '${finalFragment.id.split('_').last}';
    return ManualConversionSession.start(
      id: resolvedId,
      direction: ManualConversionDirection.regexToFa,
      source: ManualConversionSource(
        documentId: source.id,
        revision: sourceRevision,
        snapshot: {'document': source.toJson(), 'ast': _astJson(typed.ast)},
      ),
      requirements: requirements,
      canonicalArtifact: {
        'schema': 'turing-lab.regex-to-fa-canonical',
        'version': 1,
        'ast': _astJson(typed.ast),
        'postorderNodeIds': requirements
            .map((requirement) => requirement.expectedPayload['nodeId'])
            .toList(growable: false),
        'structuralEvidence': structuralArtifacts,
        'fsa': finalFragment.toJson(),
        'exactCompletion': {
          'isEquivalent': exact.isEquivalent,
          'counterexample': exact.distinguishingString,
          'oracle': 'LanguageComparator.compareLanguages',
        },
      },
      completionEvidence: ManualConversionEvidence(
        summary:
            'The completed epsilon-NFA is exactly language-equivalent to the source regular expression.',
        certainty: ManualConversionCertainty.exact,
        provenanceIds: provenance,
        counterexample: exact.distinguishingString,
      ),
    );
  }

  /// Validates and records the learner's next Thompson fragment.
  ///
  /// The typed session remains the authority for structural validation. The
  /// shared session only records the learner payload after that validation has
  /// succeeded, so isomorphic state and transition IDs remain intact.
  static ManualConversionCommandResult applyLearnerFragment({
    required ManualConversionSession session,
    required FSA fragment,
  }) {
    if (session.direction != ManualConversionDirection.regexToFa) {
      return _sharedFailure(
        session,
        'This session does not convert a regular expression to an automaton.',
      );
    }
    final requirement = session.currentRequirement;
    if (requirement == null) {
      return session.apply(
        requirementId: 'regex-to-fa.complete',
        type: ManualConversionActionType.complete,
        payload: const <String, Object?>{},
      );
    }

    final typed = _replayTypedSession(session);
    if (typed == null) {
      return _sharedFailure(
        session,
        'The recorded learner fragments cannot be replayed by the Regex-to-FA oracle.',
        requirementId: requirement.id,
      );
    }
    final nodeId = requirement.expectedPayload['nodeId'];
    if (nodeId is! String) {
      return _sharedFailure(
        session,
        'The current Regex-to-FA requirement has no syntax-tree node.',
        requirementId: requirement.id,
      );
    }
    final node = typed.ast.node(nodeId);
    if (node == null) {
      return _sharedFailure(
        session,
        'The current syntax-tree node is not part of the source snapshot.',
        requirementId: requirement.id,
      );
    }
    if (requirement.type != _sharedActionType(node.kind)) {
      return _sharedFailure(
        session,
        'The current action does not match the syntax-tree node kind.',
        requirementId: requirement.id,
      );
    }
    final expected = typed.expectedFragment(nodeId);
    if (!expected.isSuccess || expected.fragment == null) {
      return _sharedFailure(
        session,
        expected.diagnostics.map((value) => value.message).join(' '),
        requirementId: requirement.id,
      );
    }
    final structural = RegexToFaManualSession.compareStructure(
      fragment,
      expected.fragment!,
    );
    final typedResult = _applyExpected(typed, node, fragment);
    if (!typedResult.isSuccess) {
      return _sharedFailure(
        session,
        typedResult.diagnostics.map((value) => value.message).join(' '),
        requirementId: requirement.id,
      );
    }

    final exact = typedResult.session.exactComparison;
    final isFinal = typedResult.session.isComplete;
    final provenance = <String>{
      node.id,
      'source:${node.span.start}-${node.span.end}',
      ...node.childIds,
      ...fragment.states.map((state) => state.id),
      ...fragment.fsaTransitions.map((transition) => transition.id),
    }.toList()..sort();
    final evidence = ManualConversionEvidence(
      summary: isFinal
          ? 'The learner FSA is structurally valid and exactly language-equivalent to the source regular expression.'
          : 'The learner fragment is structurally isomorphic to the canonical Thompson fragment.',
      certainty: isFinal
          ? ManualConversionCertainty.exact
          : ManualConversionCertainty.structural,
      provenanceIds: provenance,
      counterexample: exact?.distinguishingString,
    );
    final payload = _payloadFor(
      node,
      fragment,
      structuralReason: structural.reason,
    );
    final learnerArtifact = <String, Object?>{
      'schema': 'turing-lab.regex-to-fa-learner-fragment',
      'version': 1,
      'nodeId': node.id,
      'nodeKind': node.kind.name,
      'sourceSpan': _spanJson(node.span),
      'fsa': fragment.toJson(),
      'structuralComparison': {
        'isEquivalent': structural.isEquivalent,
        'reason': structural.reason,
        'oracle': 'RegexToFaManualSession.compareStructure',
      },
      if (isFinal)
        'exactCompletion': {
          'isEquivalent': exact?.isEquivalent == true,
          'counterexample': exact?.distinguishingString,
          'oracle': 'LanguageComparator.compareLanguages',
        },
    };
    return session.applyValidated(
      requirementId: requirement.id,
      type: requirement.type,
      payload: payload,
      validationEvidence: evidence,
      learnerArtifact: learnerArtifact,
    );
  }
}

ManualConversionCommandResult _sharedFailure(
  ManualConversionSession session,
  String message, {
  String? requirementId,
}) {
  return ManualConversionCommandResult(
    session: session,
    diagnostics: [
      ManualConversionDiagnostic(
        code: ManualConversionDiagnosticCode.invalidPayload,
        message: message,
        requirementId: requirementId,
      ),
    ],
  );
}

RegexToFaManualSession? _replayTypedSession(ManualConversionSession shared) {
  final snapshot = shared.source.snapshot['document'];
  if (snapshot is! Map) return null;
  RegexDocument document;
  try {
    document = RegexDocument.fromJson(Map<String, dynamic>.from(snapshot));
  } on Object {
    return null;
  }
  final start = RegexToFaManualSession.start(
    sourceDocument: document,
    sourceRevision: shared.source.revision,
  );
  final initial = start.session;
  if (initial == null) return null;
  var typed = initial;
  for (final action in shared.appliedActions) {
    final nodeId = action.payload['nodeId'];
    final encodedFragment = action.payload['fragment'];
    if (nodeId is! String || encodedFragment is! Map) return null;
    FSA fragment;
    try {
      fragment = FSA.fromJson(Map<String, dynamic>.from(encodedFragment));
    } on Object {
      return null;
    }
    final node = typed.ast.node(nodeId);
    if (node == null) return null;
    final result = _applyExpected(typed, node, fragment);
    if (!result.isSuccess) return null;
    typed = result.session;
  }
  return typed;
}

ManualConversionRequirement _requirementFor(
  RegexToFaAstNodeSnapshot node,
  Map<String, Object?> payload,
) {
  final type = _sharedActionType(node.kind);
  final sourceReference = 'source:${node.span.start}-${node.span.end}';
  final provenance = <String>{
    node.id,
    sourceReference,
    ...node.childIds,
  }.toList()..sort();
  final childInstruction = node.childIds.isEmpty
      ? 'No child fragment is required.'
      : 'Use the completed child fragments ${node.childIds.join(', ')}.';
  return ManualConversionRequirement(
    id: 'regex-to-fa.${node.id}',
    contentReference: _contentReference(node.kind),
    type: type,
    title: _title(node.kind),
    instruction:
        '$childInstruction Submit a fragment that satisfies the canonical entry, acceptance, and transition invariants.',
    expectedPayload: payload,
    allowedPayloadKeys: payload.keys,
    provenanceIds: provenance,
    supportingData: {
      'nodeId': node.id,
      'sourceReference': sourceReference,
      'childIds': node.childIds,
    },
    hint:
        'Inspect syntax node ${node.id} at [$sourceReference]. Check its child order and epsilon entry or exit edges. This hint does not change the learner artifact.',
    revealExplanation:
        'Reveal the canonical Thompson fragment for ${node.id}, including its structural evidence.',
    evidence: ManualConversionEvidence(
      summary:
          'The submitted ${node.kind.name} fragment matches the canonical Thompson structure.',
      certainty: ManualConversionCertainty.structural,
      provenanceIds: provenance,
    ),
  );
}

EducationalContentReference _contentReference(
  RegexToFaAstNodeKind kind,
) => switch (kind) {
  RegexToFaAstNodeKind.symbol => ManualConversionContent.regexToFaSymbol,
  RegexToFaAstNodeKind.dot => ManualConversionContent.regexToFaDot,
  RegexToFaAstNodeKind.epsilon => ManualConversionContent.regexToFaEpsilon,
  RegexToFaAstNodeKind.emptyLanguage =>
    ManualConversionContent.regexToFaEmptyLanguage,
  RegexToFaAstNodeKind.characterSet =>
    ManualConversionContent.regexToFaCharacterSet,
  RegexToFaAstNodeKind.shortcut => ManualConversionContent.regexToFaShortcut,
  RegexToFaAstNodeKind.union => ManualConversionContent.regexToFaUnion,
  RegexToFaAstNodeKind.concatenation =>
    ManualConversionContent.regexToFaConcatenation,
  RegexToFaAstNodeKind.kleeneStar =>
    ManualConversionContent.regexToFaKleeneStar,
  RegexToFaAstNodeKind.plus => ManualConversionContent.regexToFaPlus,
  RegexToFaAstNodeKind.optional => ManualConversionContent.regexToFaOptional,
};

Map<String, Object?> _payloadFor(
  RegexToFaAstNodeSnapshot node,
  FSA fragment, {
  String? structuralReason,
}) {
  final acceptingStateIds =
      fragment.acceptingStates.map((state) => state.id).toList()..sort();
  final alphabet = fragment.alphabet.toList()..sort();
  return {
    'nodeId': node.id,
    'nodeKind': node.kind.name,
    'sourceSpan': _spanJson(node.span),
    'preconditions': {
      'postorderChildNodeIds': node.childIds,
      'childrenComplete': true,
    },
    'invariants': {
      'structurallyEquivalent': true,
      'structuralReason': structuralReason,
      'entryStateId': fragment.initialState!.id,
      'acceptingStateIds': acceptingStateIds,
      'stateCount': fragment.states.length,
      'transitionCount': fragment.fsaTransitions.length,
      'alphabet': alphabet,
    },
    'fragment': fragment.toJson(),
  };
}

RegexToFaManualCommandResult _applyExpected(
  RegexToFaManualSession session,
  RegexToFaAstNodeSnapshot node,
  FSA fragment,
) {
  return switch (node.kind) {
    RegexToFaAstNodeKind.symbol ||
    RegexToFaAstNodeKind.dot ||
    RegexToFaAstNodeKind.epsilon ||
    RegexToFaAstNodeKind.emptyLanguage ||
    RegexToFaAstNodeKind.characterSet ||
    RegexToFaAstNodeKind.shortcut => session.createBase(
      nodeId: node.id,
      candidate: fragment,
    ),
    RegexToFaAstNodeKind.union => session.combineUnion(
      nodeId: node.id,
      candidate: fragment,
    ),
    RegexToFaAstNodeKind.concatenation => session.combineConcat(
      nodeId: node.id,
      candidate: fragment,
    ),
    RegexToFaAstNodeKind.kleeneStar => session.applyStar(
      nodeId: node.id,
      candidate: fragment,
    ),
    RegexToFaAstNodeKind.plus => session.applyPlus(
      nodeId: node.id,
      candidate: fragment,
    ),
    RegexToFaAstNodeKind.optional => session.applyOptional(
      nodeId: node.id,
      candidate: fragment,
    ),
  };
}

ManualConversionActionType _sharedActionType(RegexToFaAstNodeKind kind) {
  return switch (kind) {
    RegexToFaAstNodeKind.symbol ||
    RegexToFaAstNodeKind.dot ||
    RegexToFaAstNodeKind.epsilon ||
    RegexToFaAstNodeKind.emptyLanguage ||
    RegexToFaAstNodeKind.characterSet ||
    RegexToFaAstNodeKind.shortcut =>
      ManualConversionActionType.createBaseFragment,
    RegexToFaAstNodeKind.union => ManualConversionActionType.combineUnion,
    RegexToFaAstNodeKind.concatenation =>
      ManualConversionActionType.combineConcatenation,
    RegexToFaAstNodeKind.kleeneStar =>
      ManualConversionActionType.applyKleeneStar,
    RegexToFaAstNodeKind.plus => ManualConversionActionType.applyPlus,
    RegexToFaAstNodeKind.optional => ManualConversionActionType.applyOptional,
  };
}

String _title(RegexToFaAstNodeKind kind) {
  return switch (kind) {
    RegexToFaAstNodeKind.symbol => 'Create a symbol fragment',
    RegexToFaAstNodeKind.dot => 'Create a wildcard fragment',
    RegexToFaAstNodeKind.epsilon => 'Create an epsilon fragment',
    RegexToFaAstNodeKind.emptyLanguage => 'Create an empty-language fragment',
    RegexToFaAstNodeKind.characterSet => 'Create a character-class fragment',
    RegexToFaAstNodeKind.shortcut => 'Create a shortcut fragment',
    RegexToFaAstNodeKind.union => 'Combine fragments by union',
    RegexToFaAstNodeKind.concatenation => 'Concatenate fragments',
    RegexToFaAstNodeKind.kleeneStar => 'Apply Kleene star',
    RegexToFaAstNodeKind.plus => 'Apply one-or-more repetition',
    RegexToFaAstNodeKind.optional => 'Apply optional repetition',
  };
}

Map<String, Object?> _astJson(RegexToFaAstSnapshot ast) {
  final nodes = ast.nodes.values.toList()
    ..sort((first, second) => first.id.compareTo(second.id));
  return {
    'source': ast.source,
    'rootId': ast.rootId,
    'nodes': [
      for (final node in nodes)
        {
          'id': node.id,
          'kind': node.kind.name,
          'span': _spanJson(node.span),
          'canonicalExpression': node.canonicalExpression,
          'value': node.value,
          'childIds': node.childIds,
        },
    ],
  };
}

Map<String, Object?> _spanJson(RegexToFaSourceSpan span) => {
  'start': span.start,
  'end': span.end,
};
