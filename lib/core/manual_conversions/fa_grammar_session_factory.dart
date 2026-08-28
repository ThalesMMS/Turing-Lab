import 'dart:convert';

import '../educational_content/educational_content_reference.dart';
import '../models/fsa.dart';
import '../models/grammar.dart';
import '../result.dart';
import 'fa_grammar_manual.dart';
import 'manual_conversion_content.dart';
import 'manual_conversion_session.dart';

/// Adapts canonical FA/right-linear-grammar obligations to the shared session.
abstract final class FaGrammarSessionFactory {
  static Result<ManualConversionSession> fromFa({
    required String sessionId,
    required FSA source,
    int? sourceRevision,
  }) {
    final plan = FaGrammarManualOracle.fromFa(source);
    if (plan.isFailure) return ResultFactory.failure(plan.error!);
    return fromPlan(
      sessionId: sessionId,
      plan: plan.data!,
      sourceRevision: sourceRevision,
    );
  }

  static Result<ManualConversionSession> fromRightLinearGrammar({
    required String sessionId,
    required Grammar source,
    int? sourceRevision,
  }) {
    final plan = FaGrammarManualOracle.fromRightLinearGrammar(source);
    if (plan.isFailure) return ResultFactory.failure(plan.error!);
    return fromPlan(
      sessionId: sessionId,
      plan: plan.data!,
      sourceRevision: sourceRevision,
    );
  }

  static Result<ManualConversionSession> fromPlan({
    required String sessionId,
    required FaGrammarManualPlan plan,
    int? sourceRevision,
  }) {
    if (sessionId.isEmpty) {
      return ResultFactory.failure('A manual conversion session needs an ID.');
    }
    if (plan.acceptedActions.isNotEmpty) {
      return ResultFactory.failure(
        'Only a fresh FA/grammar plan can start a shared session.',
      );
    }
    if (sourceRevision != null && sourceRevision < 0) {
      return ResultFactory.failure(
        'A manual conversion source revision cannot be negative.',
      );
    }

    final target = _canonicalArtifact(plan);
    if (target.isFailure) return ResultFactory.failure(target.error!);
    final comparison = switch (plan.direction) {
      FaGrammarManualDirection.faToRightLinearGrammar => plan.compare(
        learnerGrammar: plan.canonicalGrammar,
      ),
      FaGrammarManualDirection.rightLinearGrammarToFa => plan.compare(
        learnerFsa: plan.canonicalFsa,
      ),
    };
    if (comparison.equivalenceStatus !=
        FaGrammarManualEquivalenceStatus.equivalent) {
      return ResultFactory.failure(
        comparison.error ??
            'The canonical FA/grammar conversion is not exactly equivalent.',
      );
    }

    final provenanceIds =
        plan.obligations
            .expand((obligation) => obligation.provenance.sourceIds)
            .toSet()
            .toList()
          ..sort();
    return ResultFactory.success(
      ManualConversionSession.start(
        id: sessionId,
        direction: _direction(plan.direction),
        source: ManualConversionSource(
          documentId: plan.source.documentId,
          revision: sourceRevision ?? sourceRevisionFor(plan),
          snapshot: _sourceSnapshot(plan),
        ),
        requirements: plan.obligations.map(_requirement),
        canonicalArtifact: target.data!,
        completionEvidence: ManualConversionEvidence(
          summary:
              'The canonical result recognizes exactly the source language.',
          certainty: ManualConversionCertainty.exact,
          provenanceIds: provenanceIds,
        ),
      ),
    );
  }

  /// Integer revision consumed by [ManualConversionSource] persistence checks.
  static int sourceRevisionFor(FaGrammarManualPlan plan) {
    final separator = plan.source.revision.lastIndexOf(':');
    final encoded = separator < 0
        ? plan.source.revision
        : plan.source.revision.substring(separator + 1);
    return int.tryParse(encoded, radix: 16) ??
        _stableRevision(plan.source.canonicalJson);
  }

  /// Validates one learner correspondence with the FA/grammar oracle and
  /// records the resulting learner document in the shared session.
  static ManualConversionCommandResult applyLearnerAction({
    required ManualConversionSession session,
    required Map<String, Object?> payload,
  }) {
    final requirement = session.currentRequirement;
    if (requirement == null) {
      return _failure(
        session,
        ManualConversionDiagnosticCode.sessionComplete,
        'The construction is already complete.',
      );
    }
    final restored = _restorePlan(session);
    if (restored.isFailure) {
      return _failure(
        session,
        ManualConversionDiagnosticCode.malformedPayload,
        restored.error!,
        requirementId: requirement.id,
      );
    }
    final plan = restored.data!;
    final obligation = plan.obligations.singleWhere(
      (candidate) => candidate.id == requirement.id,
    );
    final action = _actionFromPayload(
      obligation,
      payload,
      '${session.id}.oracle.${session.cursor + 1}',
    );
    if (action.isFailure) {
      return _failure(
        session,
        ManualConversionDiagnosticCode.invalidPayload,
        action.error!,
        requirementId: requirement.id,
      );
    }
    final applied = plan.apply(action.data!);
    if (!applied.isSuccess || applied.completed?.id != obligation.id) {
      return _failure(
        session,
        ManualConversionDiagnosticCode.invalidPayload,
        'The submitted correspondence does not match the source entity.',
        requirementId: requirement.id,
      );
    }

    final learnerArtifact = applied.plan.learnerArtifact;
    final comparison = applied.plan.compareLearnerConstruction();
    if (applied.plan.isStructurallyComplete &&
        comparison.equivalenceStatus !=
            FaGrammarManualEquivalenceStatus.equivalent) {
      return _failure(
        session,
        ManualConversionDiagnosticCode.invalidPayload,
        comparison.error ??
            'The completed learner document is not language-equivalent.',
        requirementId: requirement.id,
      );
    }
    return session.applyValidated(
      requirementId: requirement.id,
      type: requirement.type,
      payload: payload,
      validationEvidence: _validationEvidence(obligation, comparison),
      learnerArtifact: learnerArtifact.toJson(),
    );
  }

  /// Compares any learner document using the same exact oracle as completion.
  static Result<FaGrammarManualComparisonResult> compareLearnerArtifact({
    required ManualConversionSession session,
    required Map<String, Object?> learnerArtifact,
  }) {
    final restored = _restorePlan(session);
    if (restored.isFailure) {
      return ResultFactory.failure(restored.error!);
    }
    final encodedDocument = learnerArtifact['document'] ?? learnerArtifact;
    if (encodedDocument is! Map) {
      return ResultFactory.failure('The learner artifact has no document.');
    }
    try {
      final document = Map<String, dynamic>.from(encodedDocument);
      final comparison = switch (restored.data!.direction) {
        FaGrammarManualDirection.faToRightLinearGrammar =>
          restored.data!.compare(learnerGrammar: Grammar.fromJson(document)),
        FaGrammarManualDirection.rightLinearGrammarToFa =>
          restored.data!.compare(learnerFsa: FSA.fromJson(document)),
      };
      return ResultFactory.success(comparison);
    } on Object {
      return ResultFactory.failure('The learner document is malformed.');
    }
  }
}

ManualConversionDirection _direction(FaGrammarManualDirection direction) =>
    switch (direction) {
      FaGrammarManualDirection.faToRightLinearGrammar =>
        ManualConversionDirection.faToRegularGrammar,
      FaGrammarManualDirection.rightLinearGrammarToFa =>
        ManualConversionDirection.regularGrammarToFa,
    };

ManualConversionRequirement _requirement(FaGrammarManualObligation obligation) {
  final payload = _payload(obligation);
  final sourceIds = obligation.provenance.sourceIds;
  final targetIds = obligation.provenance.canonicalTargetIds;
  return ManualConversionRequirement(
    id: obligation.id,
    contentReference: _contentReference(obligation.kind),
    type: _actionType(obligation.kind),
    title: _title(obligation.kind),
    instruction: _instruction(obligation),
    expectedPayload: payload,
    allowedPayloadKeys: payload.keys,
    provenanceIds: sourceIds,
    hint: _hint(obligation),
    revealExplanation: _revealExplanation(obligation),
    evidence: ManualConversionEvidence(
      summary: _structuralEvidence(obligation),
      certainty: ManualConversionCertainty.structural,
      provenanceIds: [...sourceIds, ...targetIds],
    ),
  );
}

EducationalContentReference _contentReference(FaGrammarManualActionKind kind) =>
    switch (kind) {
      FaGrammarManualActionKind.mapStateToNonterminal =>
        ManualConversionContent.faGrammarMapState,
      FaGrammarManualActionKind.mapNonterminalToState =>
        ManualConversionContent.grammarFaMapNonterminal,
      FaGrammarManualActionKind.mapTransitionToProduction =>
        ManualConversionContent.faGrammarAddProduction,
      FaGrammarManualActionKind.mapProductionToTransition =>
        ManualConversionContent.grammarFaAddTransition,
      FaGrammarManualActionKind.mapAcceptingStateToEpsilon =>
        ManualConversionContent.faGrammarAddEpsilon,
      FaGrammarManualActionKind.mapEpsilonProductionToAcceptingState =>
        ManualConversionContent.grammarFaMarkAccepting,
    };

ManualConversionActionType _actionType(FaGrammarManualActionKind kind) =>
    switch (kind) {
      FaGrammarManualActionKind.mapStateToNonterminal =>
        ManualConversionActionType.mapState,
      FaGrammarManualActionKind.mapNonterminalToState =>
        ManualConversionActionType.mapNonterminal,
      FaGrammarManualActionKind.mapTransitionToProduction =>
        ManualConversionActionType.addProduction,
      FaGrammarManualActionKind.mapProductionToTransition =>
        ManualConversionActionType.addTransition,
      FaGrammarManualActionKind.mapAcceptingStateToEpsilon =>
        ManualConversionActionType.markEpsilon,
      FaGrammarManualActionKind.mapEpsilonProductionToAcceptingState =>
        ManualConversionActionType.markAccepting,
    };

Map<String, Object?> _payload(FaGrammarManualObligation obligation) =>
    switch (obligation.kind) {
      FaGrammarManualActionKind.mapStateToNonterminal => {
        'stateId': obligation.stateId,
        'nonterminal': obligation.nonterminal,
      },
      FaGrammarManualActionKind.mapNonterminalToState => {
        'nonterminal': obligation.nonterminal,
        'stateId': obligation.stateId,
      },
      FaGrammarManualActionKind.mapTransitionToProduction => {
        'sourceTransitionIds': obligation.provenance.sourceIds,
        'production': _productionPayload(obligation.production!),
      },
      FaGrammarManualActionKind.mapProductionToTransition => {
        'sourceProductionIds': obligation.provenance.sourceIds,
        'transition': _transitionPayload(obligation.transition!),
      },
      FaGrammarManualActionKind.mapAcceptingStateToEpsilon => {
        'stateId': obligation.stateId,
        'production': _productionPayload(obligation.production!),
      },
      FaGrammarManualActionKind.mapEpsilonProductionToAcceptingState => {
        'sourceProductionIds': obligation.provenance.sourceIds,
        'stateId': obligation.stateId,
        'isAccepting': true,
      },
    };

Map<String, Object?> _productionPayload(FaGrammarProductionShape production) =>
    {
      'leftSide': production.leftSide,
      'rightSide': production.rightSide,
      'isEpsilon': production.isEpsilon,
    };

Map<String, Object?> _transitionPayload(FaGrammarTransitionShape transition) =>
    {
      'fromStateId': transition.fromStateId,
      'toStateId': transition.toStateId,
      'inputSymbol': transition.inputSymbol,
      'isEpsilon': transition.isEpsilon,
      'toStateIsAccepting': transition.toStateIsAccepting,
    };

String _title(FaGrammarManualActionKind kind) => switch (kind) {
  FaGrammarManualActionKind.mapStateToNonterminal =>
    'Map a state to a nonterminal',
  FaGrammarManualActionKind.mapNonterminalToState =>
    'Map a nonterminal to a state',
  FaGrammarManualActionKind.mapTransitionToProduction =>
    'Add the transition production',
  FaGrammarManualActionKind.mapProductionToTransition =>
    'Add the production transition',
  FaGrammarManualActionKind.mapAcceptingStateToEpsilon =>
    'Add an accepting-state epsilon production',
  FaGrammarManualActionKind.mapEpsilonProductionToAcceptingState =>
    'Mark the epsilon-production state as accepting',
};

String _instruction(
  FaGrammarManualObligation obligation,
) => switch (obligation.kind) {
  FaGrammarManualActionKind.mapStateToNonterminal =>
    'Assign ${obligation.stateId} its canonical right-linear nonterminal.',
  FaGrammarManualActionKind.mapNonterminalToState =>
    'Create the canonical state for ${obligation.nonterminal}.',
  FaGrammarManualActionKind.mapTransitionToProduction =>
    'Translate source transition ${obligation.provenance.sourceIds.join(', ')} into one right-linear production.',
  FaGrammarManualActionKind.mapProductionToTransition =>
    'Translate source production ${obligation.provenance.sourceIds.join(', ')} into its finite-automaton transition.',
  FaGrammarManualActionKind.mapAcceptingStateToEpsilon =>
    'Represent accepting state ${obligation.stateId} with an epsilon production.',
  FaGrammarManualActionKind.mapEpsilonProductionToAcceptingState =>
    'Represent source production ${obligation.provenance.sourceIds.join(', ')} by making state ${obligation.stateId} accepting.',
};

String _hint(FaGrammarManualObligation obligation) => switch (obligation.kind) {
  FaGrammarManualActionKind.mapStateToNonterminal =>
    'The initial state supplies the grammar start symbol; every other state still needs one stable nonterminal.',
  FaGrammarManualActionKind.mapNonterminalToState =>
    'The grammar start symbol supplies the initial state; keep every nonterminal mapping stable.',
  FaGrammarManualActionKind.mapTransitionToProduction =>
    'Keep the transition label first and the destination nonterminal last. An epsilon edge has no terminal label.',
  FaGrammarManualActionKind.mapProductionToTransition =>
    'A right-linear terminal leads to the trailing nonterminal, or to the shared accepting sink when none follows.',
  FaGrammarManualActionKind.mapAcceptingStateToEpsilon =>
    'Acceptance of the empty suffix becomes an epsilon production.',
  FaGrammarManualActionKind.mapEpsilonProductionToAcceptingState =>
    'An epsilon production accepts without consuming input.',
};

String _revealExplanation(FaGrammarManualObligation obligation) {
  final targetIds = obligation.provenance.canonicalTargetIds;
  final suffix = targetIds.isEmpty
      ? ''
      : ' Canonical target IDs: ${targetIds.join(', ')}.';
  return '${_structuralEvidence(obligation)}$suffix';
}

String _structuralEvidence(
  FaGrammarManualObligation obligation,
) => switch (obligation.kind) {
  FaGrammarManualActionKind.mapStateToNonterminal =>
    'State ${obligation.stateId} maps to nonterminal ${obligation.nonterminal}.',
  FaGrammarManualActionKind.mapNonterminalToState =>
    'Nonterminal ${obligation.nonterminal} maps to state ${obligation.stateId}.',
  FaGrammarManualActionKind.mapTransitionToProduction =>
    'The submitted production has the canonical source, label, and destination correspondence.',
  FaGrammarManualActionKind.mapProductionToTransition =>
    'The submitted transition has the canonical source, label, and destination correspondence.',
  FaGrammarManualActionKind.mapAcceptingStateToEpsilon =>
    'The epsilon production preserves acceptance at source state ${obligation.stateId}.',
  FaGrammarManualActionKind.mapEpsilonProductionToAcceptingState =>
    'Accepting state ${obligation.stateId} preserves the source epsilon production.',
};

Result<Map<String, Object?>> _canonicalArtifact(FaGrammarManualPlan plan) {
  switch (plan.direction) {
    case FaGrammarManualDirection.faToRightLinearGrammar:
      final grammar = plan.canonicalGrammar;
      if (grammar == null) {
        return ResultFactory.failure('The FA plan has no canonical grammar.');
      }
      return ResultFactory.success({
        'kind': 'grammar',
        'format': 'turing-lab.grammar',
        'orientation': FaGrammarManualOrientation.rightLinear.name,
        'document': grammar.toJson(),
      });
    case FaGrammarManualDirection.rightLinearGrammarToFa:
      final fsa = plan.canonicalFsa;
      if (fsa == null) {
        return ResultFactory.failure('The grammar plan has no canonical FSA.');
      }
      return ResultFactory.success({
        'kind': 'fsa',
        'format': 'turing-lab.fsa',
        'orientation': FaGrammarManualOrientation.rightLinear.name,
        'document': fsa.toJson(),
      });
  }
}

Map<String, Object?> _sourceSnapshot(FaGrammarManualPlan plan) {
  final decoded = jsonDecode(plan.source.canonicalJson);
  if (decoded is! Map) {
    throw const FormatException('The FA/grammar source snapshot is malformed.');
  }
  return {
    ...Map<String, Object?>.from(decoded),
    'document': switch (plan.direction) {
      FaGrammarManualDirection.faToRightLinearGrammar =>
        plan.sourceFsa!.toJson(),
      FaGrammarManualDirection.rightLinearGrammarToFa =>
        plan.sourceGrammar!.toJson(),
    },
  };
}

Result<FaGrammarManualPlan> _restorePlan(ManualConversionSession session) {
  final direction = session.direction;
  if (direction != ManualConversionDirection.faToRegularGrammar &&
      direction != ManualConversionDirection.regularGrammarToFa) {
    return ResultFactory.failure(
      'The session is not an FA/regular-grammar construction.',
    );
  }
  final encodedDocument = session.source.snapshot['document'];
  if (encodedDocument is! Map) {
    return ResultFactory.failure(
      'The FA/grammar source snapshot has no restorable document.',
    );
  }
  try {
    final document = Map<String, dynamic>.from(encodedDocument);
    final initial = direction == ManualConversionDirection.faToRegularGrammar
        ? FaGrammarManualOracle.fromFa(FSA.fromJson(document))
        : FaGrammarManualOracle.fromRightLinearGrammar(
            Grammar.fromJson(document),
          );
    if (initial.isFailure) return ResultFactory.failure(initial.error!);
    var plan = initial.data!;
    for (final sharedAction in session.appliedActions) {
      final obligation = plan.obligations.singleWhere(
        (candidate) => candidate.id == sharedAction.requirementId,
      );
      final action = _actionFromPayload(
        obligation,
        sharedAction.payload,
        '${sharedAction.id}.oracle',
      );
      if (action.isFailure) return ResultFactory.failure(action.error!);
      final replay = plan.apply(action.data!);
      if (!replay.isSuccess || replay.completed?.id != obligation.id) {
        return ResultFactory.failure(
          'The saved learner correspondence cannot be replayed.',
        );
      }
      plan = replay.plan;
    }
    return ResultFactory.success(plan);
  } on Object {
    return ResultFactory.failure(
      'The FA/grammar source snapshot is malformed.',
    );
  }
}

Result<FaGrammarManualAction> _actionFromPayload(
  FaGrammarManualObligation obligation,
  Map<String, Object?> payload,
  String actionId,
) {
  try {
    final action = switch (obligation.kind) {
      FaGrammarManualActionKind.mapStateToNonterminal =>
        FaGrammarManualAction.mapStateToNonterminal(
          id: actionId,
          stateId: _string(payload, 'stateId'),
          nonterminal: _string(payload, 'nonterminal'),
        ),
      FaGrammarManualActionKind.mapNonterminalToState =>
        FaGrammarManualAction.mapNonterminalToState(
          id: actionId,
          nonterminal: _string(payload, 'nonterminal'),
          stateId: _string(payload, 'stateId'),
        ),
      FaGrammarManualActionKind.mapTransitionToProduction =>
        FaGrammarManualAction.mapTransitionToProduction(
          id: actionId,
          production: _productionFromPayload(payload['production']),
        ),
      FaGrammarManualActionKind.mapProductionToTransition =>
        FaGrammarManualAction.mapProductionToTransition(
          id: actionId,
          transition: _transitionFromPayload(payload['transition']),
        ),
      FaGrammarManualActionKind.mapAcceptingStateToEpsilon =>
        FaGrammarManualAction.mapAcceptingStateToEpsilon(
          id: actionId,
          stateId: _string(payload, 'stateId'),
          production: _productionFromPayload(payload['production']),
        ),
      FaGrammarManualActionKind.mapEpsilonProductionToAcceptingState =>
        FaGrammarManualAction.mapEpsilonProductionToAcceptingState(
          id: actionId,
          stateId: _string(payload, 'stateId'),
        ),
    };
    return ResultFactory.success(action);
  } on FormatException catch (error) {
    return ResultFactory.failure(error.message);
  }
}

FaGrammarProductionShape _productionFromPayload(Object? encoded) {
  final map = _objectPayload(encoded, 'production');
  final leftSide = map['leftSide'];
  final rightSide = map['rightSide'];
  final isEpsilon = map['isEpsilon'];
  if (leftSide is! List ||
      leftSide.any((value) => value is! String) ||
      rightSide is! List ||
      rightSide.any((value) => value is! String) ||
      isEpsilon is! bool) {
    throw const FormatException('The learner production is malformed.');
  }
  return FaGrammarProductionShape(
    leftSide: leftSide.cast<String>(),
    rightSide: rightSide.cast<String>(),
    isEpsilon: isEpsilon,
  );
}

FaGrammarTransitionShape _transitionFromPayload(Object? encoded) {
  final map = _objectPayload(encoded, 'transition');
  final fromStateId = map['fromStateId'];
  final toStateId = map['toStateId'];
  final inputSymbol = map['inputSymbol'];
  final isEpsilon = map['isEpsilon'];
  final toStateIsAccepting = map['toStateIsAccepting'];
  if (fromStateId is! String ||
      toStateId is! String ||
      inputSymbol is! String ||
      isEpsilon is! bool ||
      toStateIsAccepting is! bool) {
    throw const FormatException('The learner transition is malformed.');
  }
  return FaGrammarTransitionShape(
    fromStateId: fromStateId,
    toStateId: toStateId,
    inputSymbol: inputSymbol,
    isEpsilon: isEpsilon,
    toStateIsAccepting: toStateIsAccepting,
  );
}

Map<String, Object?> _objectPayload(Object? encoded, String label) {
  if (encoded is! Map) {
    throw FormatException('The learner $label is malformed.');
  }
  return Map<String, Object?>.from(encoded);
}

String _string(Map<String, Object?> payload, String key) {
  final value = payload[key];
  if (value is! String || value.isEmpty) {
    throw FormatException('The learner $key is malformed.');
  }
  return value;
}

ManualConversionEvidence _validationEvidence(
  FaGrammarManualObligation obligation,
  FaGrammarManualComparisonResult comparison,
) {
  final exact =
      comparison.equivalenceStatus != FaGrammarManualEquivalenceStatus.error;
  final comparisonSummary = switch (comparison.equivalenceStatus) {
    FaGrammarManualEquivalenceStatus.equivalent =>
      'The current learner document is exactly language-equivalent.',
    FaGrammarManualEquivalenceStatus.notEquivalent =>
      'The accepted partial document is not language-equivalent yet.',
    FaGrammarManualEquivalenceStatus.error =>
      'The accepted mapping is structurally valid; the learner document is still incomplete.',
  };
  return ManualConversionEvidence(
    summary:
        'The submitted correspondence matches its source obligation. '
        '$comparisonSummary',
    certainty: exact
        ? ManualConversionCertainty.exact
        : ManualConversionCertainty.structural,
    provenanceIds: <String>{
      ...obligation.provenance.sourceIds,
      ...obligation.provenance.canonicalTargetIds,
    }.toList()..sort(),
    counterexample: comparison.distinguishingString,
  );
}

ManualConversionCommandResult _failure(
  ManualConversionSession session,
  ManualConversionDiagnosticCode code,
  String message, {
  String? requirementId,
}) {
  return ManualConversionCommandResult(
    session: session,
    diagnostics: [
      ManualConversionDiagnostic(
        code: code,
        message: message,
        requirementId: requirementId,
      ),
    ],
  );
}

int _stableRevision(String value) {
  var hash = 0;
  for (final codeUnit in value.codeUnits) {
    hash = ((hash * 31) + codeUnit) & 0x7fffffff;
  }
  return hash;
}
