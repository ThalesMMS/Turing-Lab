import 'dart:convert';

import '../algorithms/fsa_to_grammar_converter.dart';
import '../algorithms/grammar_to_fsa_converter.dart';
import '../algorithms/language_comparator.dart';
import '../models/fsa.dart';
import '../models/fsa_transition.dart';
import '../models/grammar.dart';
import '../models/production.dart';
import '../result.dart';
import '../utils/epsilon_utils.dart';

/// The two manual correspondence exercises supported by this oracle.
enum FaGrammarManualDirection { faToRightLinearGrammar, rightLinearGrammarToFa }

/// This contract intentionally excludes left-linear grammars.
enum FaGrammarManualOrientation { rightLinear }

enum FaGrammarManualActionKind {
  mapStateToNonterminal,
  mapNonterminalToState,
  mapTransitionToProduction,
  mapProductionToTransition,
  mapAcceptingStateToEpsilon,
  mapEpsilonProductionToAcceptingState,
}

enum FaGrammarManualDiagnosticCode {
  duplicateActionId,
  alreadyCompleted,
  incorrectMapping,
}

enum FaGrammarManualEquivalenceStatus {
  equivalent,
  notEquivalent,
  error,
}

/// A deep, serialized copy of the document used to start an exercise.
class FaGrammarManualSourceSnapshot {
  const FaGrammarManualSourceSnapshot({
    required this.documentId,
    required this.revision,
    required this.canonicalJson,
  });

  final String documentId;
  final String revision;
  final String canonicalJson;
}

/// Links an expected learner step to concrete source and canonical target IDs.
class FaGrammarManualProvenance {
  FaGrammarManualProvenance({
    required this.sourceDocumentId,
    required Iterable<String> sourceIds,
    required Iterable<String> canonicalTargetIds,
  })  : sourceIds = List<String>.unmodifiable(sourceIds.toList()..sort()),
        canonicalTargetIds = List<String>.unmodifiable(
          canonicalTargetIds.toList()..sort(),
        );

  final String sourceDocumentId;
  final List<String> sourceIds;
  final List<String> canonicalTargetIds;
}

class FaGrammarProductionShape {
  FaGrammarProductionShape({
    required Iterable<String> leftSide,
    required Iterable<String> rightSide,
    required this.isEpsilon,
  })  : leftSide = List<String>.unmodifiable(leftSide),
        rightSide = List<String>.unmodifiable(rightSide);

  factory FaGrammarProductionShape.fromProduction(Production production) =>
      FaGrammarProductionShape(
        leftSide: production.leftSide,
        rightSide: production.rightSide,
        isEpsilon: production.isLambda || production.rightSide.isEmpty,
      );

  final List<String> leftSide;
  final List<String> rightSide;
  final bool isEpsilon;

  bool sameAs(FaGrammarProductionShape other) =>
      _sameStrings(leftSide, other.leftSide) &&
      _sameStrings(rightSide, other.rightSide) &&
      isEpsilon == other.isEpsilon;
}

class FaGrammarTransitionShape {
  const FaGrammarTransitionShape({
    required this.fromStateId,
    required this.toStateId,
    required this.inputSymbol,
    required this.isEpsilon,
    required this.toStateIsAccepting,
  });

  final String fromStateId;
  final String toStateId;
  final String inputSymbol;
  final bool isEpsilon;
  final bool toStateIsAccepting;

  bool sameAs(FaGrammarTransitionShape other) =>
      fromStateId == other.fromStateId &&
      toStateId == other.toStateId &&
      inputSymbol == other.inputSymbol &&
      isEpsilon == other.isEpsilon &&
      toStateIsAccepting == other.toStateIsAccepting;
}

/// One canonical correspondence that the learner still needs to provide.
class FaGrammarManualObligation {
  const FaGrammarManualObligation({
    required this.id,
    required this.kind,
    required this.provenance,
    this.stateId,
    this.nonterminal,
    this.production,
    this.transition,
  });

  final String id;
  final FaGrammarManualActionKind kind;
  final FaGrammarManualProvenance provenance;
  final String? stateId;
  final String? nonterminal;
  final FaGrammarProductionShape? production;
  final FaGrammarTransitionShape? transition;

  bool accepts(FaGrammarManualAction action) {
    if (kind != action.kind || stateId != action.stateId) return false;
    if (nonterminal != action.nonterminal) return false;
    final expectedProduction = production;
    if (expectedProduction != null &&
        (action.production == null ||
            !expectedProduction.sameAs(action.production!))) {
      return false;
    }
    final expectedTransition = transition;
    if (expectedTransition != null &&
        (action.transition == null ||
            !expectedTransition.sameAs(action.transition!))) {
      return false;
    }
    return true;
  }
}

/// A proposed learner step. Its stable ID belongs to the session, not the source.
class FaGrammarManualAction {
  const FaGrammarManualAction._({
    required this.id,
    required this.kind,
    this.stateId,
    this.nonterminal,
    this.production,
    this.transition,
  });

  factory FaGrammarManualAction.mapStateToNonterminal({
    required String id,
    required String stateId,
    required String nonterminal,
  }) =>
      FaGrammarManualAction._(
        id: id,
        kind: FaGrammarManualActionKind.mapStateToNonterminal,
        stateId: stateId,
        nonterminal: nonterminal,
      );

  factory FaGrammarManualAction.mapNonterminalToState({
    required String id,
    required String nonterminal,
    required String stateId,
  }) =>
      FaGrammarManualAction._(
        id: id,
        kind: FaGrammarManualActionKind.mapNonterminalToState,
        stateId: stateId,
        nonterminal: nonterminal,
      );

  factory FaGrammarManualAction.mapTransitionToProduction({
    required String id,
    required FaGrammarProductionShape production,
  }) =>
      FaGrammarManualAction._(
        id: id,
        kind: FaGrammarManualActionKind.mapTransitionToProduction,
        production: production,
      );

  factory FaGrammarManualAction.mapProductionToTransition({
    required String id,
    required FaGrammarTransitionShape transition,
  }) =>
      FaGrammarManualAction._(
        id: id,
        kind: FaGrammarManualActionKind.mapProductionToTransition,
        transition: transition,
      );

  factory FaGrammarManualAction.mapAcceptingStateToEpsilon({
    required String id,
    required String stateId,
    required FaGrammarProductionShape production,
  }) =>
      FaGrammarManualAction._(
        id: id,
        kind: FaGrammarManualActionKind.mapAcceptingStateToEpsilon,
        stateId: stateId,
        production: production,
      );

  factory FaGrammarManualAction.mapEpsilonProductionToAcceptingState({
    required String id,
    required String stateId,
  }) =>
      FaGrammarManualAction._(
        id: id,
        kind: FaGrammarManualActionKind.mapEpsilonProductionToAcceptingState,
        stateId: stateId,
      );

  final String id;
  final FaGrammarManualActionKind kind;
  final String? stateId;
  final String? nonterminal;
  final FaGrammarProductionShape? production;
  final FaGrammarTransitionShape? transition;
}

class FaGrammarManualDiagnostic {
  const FaGrammarManualDiagnostic({
    required this.code,
    required this.actionId,
    this.obligation,
  });

  final FaGrammarManualDiagnosticCode code;
  final String actionId;
  final FaGrammarManualObligation? obligation;
}

class FaGrammarManualApplyResult {
  const FaGrammarManualApplyResult({
    required this.plan,
    this.completed,
    this.diagnostic,
  });

  final FaGrammarManualPlan plan;
  final FaGrammarManualObligation? completed;
  final FaGrammarManualDiagnostic? diagnostic;
  bool get isSuccess => completed != null && diagnostic == null;
}

class FaGrammarManualComparisonResult {
  const FaGrammarManualComparisonResult({
    required this.structurallyComplete,
    required this.completedObligations,
    required this.totalObligations,
    required this.equivalenceStatus,
    this.distinguishingString,
    this.error,
  });

  final bool structurallyComplete;
  final int completedObligations;
  final int totalObligations;
  final FaGrammarManualEquivalenceStatus equivalenceStatus;
  final String? distinguishingString;
  final String? error;
}

/// The document assembled exclusively from learner-accepted correspondences.
///
/// The canonical target remains available to the oracle for validation, but is
/// never used as a substitute for missing learner actions here.
class FaGrammarManualLearnerArtifact {
  FaGrammarManualLearnerArtifact._({
    required this.direction,
    required Map<String, String> stateToNonterminal,
    required Map<String, String> nonterminalToState,
    required Iterable<FaGrammarProductionShape> productions,
    required Iterable<FaGrammarTransitionShape> transitions,
    required Iterable<String> acceptingStateIds,
    required this.document,
  })  : stateToNonterminal = Map<String, String>.unmodifiable(
          stateToNonterminal,
        ),
        nonterminalToState = Map<String, String>.unmodifiable(
          nonterminalToState,
        ),
        productions = List<FaGrammarProductionShape>.unmodifiable(productions),
        transitions = List<FaGrammarTransitionShape>.unmodifiable(transitions),
        acceptingStateIds = Set<String>.unmodifiable(acceptingStateIds);

  final FaGrammarManualDirection direction;
  final Map<String, String> stateToNonterminal;
  final Map<String, String> nonterminalToState;
  final List<FaGrammarProductionShape> productions;
  final List<FaGrammarTransitionShape> transitions;
  final Set<String> acceptingStateIds;

  /// A partial or complete learner document encoded in the normal model format.
  ///
  /// This is null only until the learner has supplied the mapping needed to
  /// identify the target document's start symbol/state.
  final Map<String, Object?>? document;

  Map<String, Object?> toJson() => {
        'kind': switch (direction) {
          FaGrammarManualDirection.faToRightLinearGrammar => 'grammar',
          FaGrammarManualDirection.rightLinearGrammarToFa => 'fsa',
        },
        'orientation': FaGrammarManualOrientation.rightLinear.name,
        'stateToNonterminal': stateToNonterminal,
        'nonterminalToState': nonterminalToState,
        'productions': productions.map(_productionShapeJson).toList(),
        'transitions': transitions.map(_transitionShapeJson).toList(),
        'acceptingStateIds': acceptingStateIds.toList()..sort(),
        'document': document,
      };
}

/// Immutable progress through one canonical FA/right-linear-grammar exercise.
class FaGrammarManualPlan {
  FaGrammarManualPlan._({
    required this.direction,
    required this.source,
    required Iterable<FaGrammarManualObligation> obligations,
    required Iterable<FaGrammarManualAction> acceptedActions,
    required Iterable<String> completedObligationIds,
    required FSA? sourceFsa,
    required Grammar? sourceGrammar,
    required Grammar? canonicalGrammar,
    required FSA? canonicalFsa,
  })  : obligations = List<FaGrammarManualObligation>.unmodifiable(obligations),
        acceptedActions =
            List<FaGrammarManualAction>.unmodifiable(acceptedActions),
        completedObligationIds =
            Set<String>.unmodifiable(completedObligationIds),
        _sourceFsa = sourceFsa,
        _sourceGrammar = sourceGrammar,
        _canonicalGrammar = canonicalGrammar,
        _canonicalFsa = canonicalFsa;

  final FaGrammarManualDirection direction;
  final FaGrammarManualOrientation orientation =
      FaGrammarManualOrientation.rightLinear;
  final FaGrammarManualSourceSnapshot source;
  final List<FaGrammarManualObligation> obligations;
  final List<FaGrammarManualAction> acceptedActions;
  final Set<String> completedObligationIds;
  final FSA? _sourceFsa;
  final Grammar? _sourceGrammar;
  final Grammar? _canonicalGrammar;
  final FSA? _canonicalFsa;

  Grammar? get canonicalGrammar =>
      _canonicalGrammar == null ? null : _cloneGrammar(_canonicalGrammar);
  FSA? get canonicalFsa =>
      _canonicalFsa == null ? null : _cloneFsa(_canonicalFsa);
  FSA? get sourceFsa => _sourceFsa == null ? null : _cloneFsa(_sourceFsa);
  Grammar? get sourceGrammar =>
      _sourceGrammar == null ? null : _cloneGrammar(_sourceGrammar);

  /// Rebuilds the learner target from accepted actions only.
  FaGrammarManualLearnerArtifact get learnerArtifact {
    final stateToNonterminal = <String, String>{};
    final nonterminalToState = <String, String>{};
    final productions = <FaGrammarProductionShape>[];
    final transitions = <FaGrammarTransitionShape>[];
    final acceptingStateIds = <String>{};
    for (final action in acceptedActions) {
      switch (action.kind) {
        case FaGrammarManualActionKind.mapStateToNonterminal:
          stateToNonterminal[action.stateId!] = action.nonterminal!;
        case FaGrammarManualActionKind.mapNonterminalToState:
          nonterminalToState[action.nonterminal!] = action.stateId!;
        case FaGrammarManualActionKind.mapTransitionToProduction:
        case FaGrammarManualActionKind.mapAcceptingStateToEpsilon:
          productions.add(action.production!);
        case FaGrammarManualActionKind.mapProductionToTransition:
          final transition = action.transition!;
          transitions.add(transition);
          if (transition.toStateIsAccepting) {
            acceptingStateIds.add(transition.toStateId);
          }
        case FaGrammarManualActionKind.mapEpsilonProductionToAcceptingState:
          acceptingStateIds.add(action.stateId!);
      }
    }

    final document = switch (direction) {
      FaGrammarManualDirection.faToRightLinearGrammar =>
        _learnerGrammarJson(stateToNonterminal, productions),
      FaGrammarManualDirection.rightLinearGrammarToFa => _learnerFsaJson(
          nonterminalToState,
          transitions,
          acceptingStateIds,
        ),
    };
    return FaGrammarManualLearnerArtifact._(
      direction: direction,
      stateToNonterminal: stateToNonterminal,
      nonterminalToState: nonterminalToState,
      productions: productions,
      transitions: transitions,
      acceptingStateIds: acceptingStateIds,
      document: document,
    );
  }

  /// Compares the document actually assembled by learner actions.
  FaGrammarManualComparisonResult compareLearnerConstruction() {
    final document = learnerArtifact.document;
    if (document == null) {
      return _comparisonError(
        'The learner construction has no start mapping yet.',
      );
    }
    return switch (direction) {
      FaGrammarManualDirection.faToRightLinearGrammar => compare(
          learnerGrammar: Grammar.fromJson(
            Map<String, dynamic>.from(document),
          ),
        ),
      FaGrammarManualDirection.rightLinearGrammarToFa => compare(
          learnerFsa: FSA.fromJson(Map<String, dynamic>.from(document)),
        ),
    };
  }

  bool get isStructurallyComplete =>
      completedObligationIds.length == obligations.length;

  List<FaGrammarManualObligation> get pendingObligations =>
      List<FaGrammarManualObligation>.unmodifiable(
        obligations.where(
          (obligation) => !completedObligationIds.contains(obligation.id),
        ),
      );

  FaGrammarManualApplyResult apply(FaGrammarManualAction action) {
    if (acceptedActions.any((accepted) => accepted.id == action.id)) {
      return FaGrammarManualApplyResult(
        plan: this,
        diagnostic: FaGrammarManualDiagnostic(
          code: FaGrammarManualDiagnosticCode.duplicateActionId,
          actionId: action.id,
        ),
      );
    }

    FaGrammarManualObligation? match;
    for (final obligation in pendingObligations) {
      if (obligation.accepts(action)) {
        match = obligation;
        break;
      }
    }
    if (match == null) {
      FaGrammarManualObligation? completedMatch;
      for (final obligation in obligations) {
        if (completedObligationIds.contains(obligation.id) &&
            obligation.accepts(action)) {
          completedMatch = obligation;
          break;
        }
      }
      return FaGrammarManualApplyResult(
        plan: this,
        diagnostic: FaGrammarManualDiagnostic(
          code: completedMatch == null
              ? FaGrammarManualDiagnosticCode.incorrectMapping
              : FaGrammarManualDiagnosticCode.alreadyCompleted,
          actionId: action.id,
          obligation: completedMatch,
        ),
      );
    }

    final next = FaGrammarManualPlan._(
      direction: direction,
      source: source,
      obligations: obligations,
      acceptedActions: [...acceptedActions, action],
      completedObligationIds: {...completedObligationIds, match.id},
      sourceFsa: _sourceFsa,
      sourceGrammar: _sourceGrammar,
      canonicalGrammar: _canonicalGrammar,
      canonicalFsa: _canonicalFsa,
    );
    return FaGrammarManualApplyResult(plan: next, completed: match);
  }

  FaGrammarManualComparisonResult compare({
    FSA? learnerFsa,
    Grammar? learnerGrammar,
  }) {
    Result comparison;
    if (direction == FaGrammarManualDirection.faToRightLinearGrammar) {
      if (learnerGrammar == null || learnerFsa != null) {
        return _comparisonError('Expected one learner grammar.');
      }
      final converted = GrammarToFSAConverter.convert(learnerGrammar);
      if (converted.isFailure) return _comparisonError(converted.error!);
      comparison = LanguageComparator.compareLanguages(
        _sourceFsa!,
        converted.data!,
      );
    } else {
      if (learnerFsa == null || learnerGrammar != null) {
        return _comparisonError('Expected one learner finite automaton.');
      }
      comparison = LanguageComparator.compareLanguages(
        _canonicalFsa!,
        learnerFsa,
      );
    }

    if (comparison.isFailure) return _comparisonError(comparison.error!);
    final result = comparison.data!;
    return FaGrammarManualComparisonResult(
      structurallyComplete: isStructurallyComplete,
      completedObligations: completedObligationIds.length,
      totalObligations: obligations.length,
      equivalenceStatus: result.isEquivalent
          ? FaGrammarManualEquivalenceStatus.equivalent
          : FaGrammarManualEquivalenceStatus.notEquivalent,
      distinguishingString: result.distinguishingString,
    );
  }

  FaGrammarManualComparisonResult _comparisonError(String message) =>
      FaGrammarManualComparisonResult(
        structurallyComplete: isStructurallyComplete,
        completedObligations: completedObligationIds.length,
        totalObligations: obligations.length,
        equivalenceStatus: FaGrammarManualEquivalenceStatus.error,
        error: message,
      );

  Map<String, Object?>? _learnerGrammarJson(
    Map<String, String> stateToNonterminal,
    List<FaGrammarProductionShape> shapes,
  ) {
    final sourceInitialStateId = _sourceFsa!.initialState!.id;
    final startSymbol = stateToNonterminal[sourceInitialStateId];
    if (startSymbol == null) return null;
    final canonical = _canonicalGrammar!;
    final productions = <Production>{};
    for (var index = 0; index < shapes.length; index++) {
      final shape = shapes[index];
      productions.add(
        Production(
          id: 'learner-production-${index + 1}',
          leftSide: shape.leftSide,
          rightSide: shape.rightSide,
          isLambda: shape.isEpsilon,
          order: index,
        ),
      );
    }
    return Grammar(
      id: '${source.documentId}-learner-grammar',
      name: '${canonical.name} (learner)',
      terminals: Set<String>.from(_sourceFsa.alphabet),
      nonterminals: stateToNonterminal.values.toSet(),
      startSymbol: startSymbol,
      productions: productions,
      type: GrammarType.regular,
      created: canonical.created,
      modified: canonical.modified,
    ).toJson();
  }

  Map<String, Object?>? _learnerFsaJson(
    Map<String, String> nonterminalToState,
    List<FaGrammarTransitionShape> shapes,
    Set<String> acceptingStateIds,
  ) {
    final sourceSnapshot = Map<String, Object?>.from(
      jsonDecode(source.canonicalJson) as Map,
    );
    final initialStateId = nonterminalToState[sourceSnapshot['startSymbol']];
    if (initialStateId == null) return null;
    final canonical = _canonicalFsa!;
    final includedStateIds = <String>{
      ...nonterminalToState.values,
      ...acceptingStateIds,
      for (final shape in shapes) shape.fromStateId,
      for (final shape in shapes) shape.toStateId,
    };
    final statesById = {
      for (final state in canonical.states)
        if (includedStateIds.contains(state.id)) state.id: state,
    };
    final initialState = statesById[initialStateId];
    if (initialState == null) return null;
    final transitions = <FSATransition>{};
    for (var index = 0; index < shapes.length; index++) {
      final shape = shapes[index];
      final fromState = statesById[shape.fromStateId];
      final toState = statesById[shape.toStateId];
      if (fromState == null || toState == null) return null;
      transitions.add(
        shape.isEpsilon
            ? FSATransition.epsilon(
                id: 'learner-transition-${index + 1}',
                fromState: fromState,
                toState: toState,
              )
            : FSATransition.deterministic(
                id: 'learner-transition-${index + 1}',
                fromState: fromState,
                toState: toState,
                symbol: shape.inputSymbol,
              ),
      );
    }
    final accepting = statesById.values
        .where((state) => acceptingStateIds.contains(state.id))
        .toSet();
    final alphabet = <String>{
      for (final shape in shapes)
        if (!shape.isEpsilon) shape.inputSymbol,
    };
    return canonical
        .copyWith(
          id: '${source.documentId}-learner-fsa',
          name: '${canonical.name} (learner)',
          states: statesById.values.toSet(),
          transitions: transitions,
          alphabet: alphabet,
          initialState: initialState,
          acceptingStates: accepting,
        )
        .toJson();
  }
}

/// Builds canonical, source-backed obligations without mutating either document.
abstract final class FaGrammarManualOracle {
  static Result<FaGrammarManualPlan> fromFa(FSA input) {
    if (input.initialState == null) {
      return ResultFactory.failure(
        'A finite automaton needs an initial state for grammar conversion.',
      );
    }
    final source = _cloneFsa(input);
    final canonical = FSAToGrammarConverter.convert(source);
    final initialState = source.initialState!;
    final stateOrder = source.states.toList()
      ..sort((left, right) {
        if (left.id == right.id) return 0;
        if (left.id == initialState.id) return -1;
        if (right.id == initialState.id) return 1;
        final idOrder = left.id.compareTo(right.id);
        return idOrder != 0 ? idOrder : left.label.compareTo(right.label);
      });
    final stateToNonterminal = <String, String>{
      for (var index = 0; index < stateOrder.length; index++)
        stateOrder[index].id: 'A$index',
    };
    final obligations = <FaGrammarManualObligation>[];

    for (final state in [...source.states]
      ..sort((a, b) => a.id.compareTo(b.id))) {
      final nonterminal = stateToNonterminal[state.id]!;
      obligations.add(
        FaGrammarManualObligation(
          id: _obligationId(
            FaGrammarManualDirection.faToRightLinearGrammar,
            FaGrammarManualActionKind.mapStateToNonterminal,
            state.id,
          ),
          kind: FaGrammarManualActionKind.mapStateToNonterminal,
          stateId: state.id,
          nonterminal: nonterminal,
          provenance: FaGrammarManualProvenance(
            sourceDocumentId: source.id,
            sourceIds: [state.id],
            canonicalTargetIds: [nonterminal],
          ),
        ),
      );
    }

    final transitions = source.fsaTransitions.toList()
      ..sort((a, b) => a.id.compareTo(b.id));
    for (final transition in transitions) {
      final from = stateToNonterminal[transition.fromState.id]!;
      final to = stateToNonterminal[transition.toState.id]!;
      final symbols = transition.acceptedSymbols.toList()..sort();
      for (final symbol in symbols) {
        final epsilon = isEpsilonSymbol(symbol);
        _addTransitionProductionObligation(
          obligations: obligations,
          source: source,
          canonical: canonical,
          transitionId: transition.id,
          discriminator: epsilon ? 'epsilon' : symbol,
          shape: FaGrammarProductionShape(
            leftSide: [from],
            rightSide: epsilon ? [to] : [symbol, to],
            isEpsilon: false,
          ),
        );
      }
    }

    final accepting = source.acceptingStates.toList()
      ..sort((a, b) => a.id.compareTo(b.id));
    for (final state in accepting) {
      final shape = FaGrammarProductionShape(
        leftSide: [stateToNonterminal[state.id]!],
        rightSide: const [],
        isEpsilon: true,
      );
      obligations.add(
        FaGrammarManualObligation(
          id: _obligationId(
            FaGrammarManualDirection.faToRightLinearGrammar,
            FaGrammarManualActionKind.mapAcceptingStateToEpsilon,
            state.id,
          ),
          kind: FaGrammarManualActionKind.mapAcceptingStateToEpsilon,
          stateId: state.id,
          production: shape,
          provenance: FaGrammarManualProvenance(
            sourceDocumentId: source.id,
            sourceIds: [state.id],
            canonicalTargetIds: _matchingProductionIds(canonical, shape),
          ),
        ),
      );
    }

    return ResultFactory.success(
      FaGrammarManualPlan._(
        direction: FaGrammarManualDirection.faToRightLinearGrammar,
        source: _snapshotForFsa(source),
        obligations: obligations,
        acceptedActions: const [],
        completedObligationIds: const {},
        sourceFsa: source,
        sourceGrammar: null,
        canonicalGrammar: canonical,
        canonicalFsa: null,
      ),
    );
  }

  static Result<FaGrammarManualPlan> fromRightLinearGrammar(Grammar input) {
    final source = _cloneGrammar(input);
    final conversion = GrammarToFSAConverter.convert(source);
    if (conversion.isFailure) {
      return ResultFactory.failure(conversion.error!);
    }
    final canonical = conversion.data!;
    final obligations = <FaGrammarManualObligation>[];
    final nonterminals = source.nonterminals.toList()..sort();

    for (final nonterminal in nonterminals) {
      obligations.add(
        FaGrammarManualObligation(
          id: _obligationId(
            FaGrammarManualDirection.rightLinearGrammarToFa,
            FaGrammarManualActionKind.mapNonterminalToState,
            nonterminal,
          ),
          kind: FaGrammarManualActionKind.mapNonterminalToState,
          stateId: nonterminal,
          nonterminal: nonterminal,
          provenance: FaGrammarManualProvenance(
            sourceDocumentId: source.id,
            sourceIds: [nonterminal],
            canonicalTargetIds: [nonterminal],
          ),
        ),
      );
    }

    final productions = source.productions.toList()
      ..sort((a, b) {
        final order = a.order.compareTo(b.order);
        return order != 0 ? order : a.id.compareTo(b.id);
      });
    for (final production in productions) {
      final from = production.leftSide.first;
      if (_isEpsilonProduction(production)) {
        obligations.add(
          FaGrammarManualObligation(
            id: _obligationId(
              FaGrammarManualDirection.rightLinearGrammarToFa,
              FaGrammarManualActionKind.mapEpsilonProductionToAcceptingState,
              production.id,
            ),
            kind:
                FaGrammarManualActionKind.mapEpsilonProductionToAcceptingState,
            stateId: from,
            provenance: FaGrammarManualProvenance(
              sourceDocumentId: source.id,
              sourceIds: [production.id],
              canonicalTargetIds: [from],
            ),
          ),
        );
        continue;
      }

      final firstSymbol = production.rightSide.first;
      final isUnitProduction = production.rightSide.length == 1 &&
          source.nonterminals.contains(firstSymbol);
      final targetId = isUnitProduction
          ? firstSymbol
          : production.rightSide.length == 1
              ? '${source.id}_ACCEPT'
              : production.rightSide.last;
      final shape = FaGrammarTransitionShape(
        fromStateId: from,
        toStateId: targetId,
        inputSymbol: isUnitProduction ? '' : firstSymbol,
        isEpsilon: isUnitProduction,
        toStateIsAccepting:
            canonical.acceptingStates.any((state) => state.id == targetId),
      );
      obligations.add(
        FaGrammarManualObligation(
          id: _obligationId(
            FaGrammarManualDirection.rightLinearGrammarToFa,
            FaGrammarManualActionKind.mapProductionToTransition,
            production.id,
          ),
          kind: FaGrammarManualActionKind.mapProductionToTransition,
          transition: shape,
          provenance: FaGrammarManualProvenance(
            sourceDocumentId: source.id,
            sourceIds: [production.id],
            canonicalTargetIds: _matchingTransitionIds(canonical, shape),
          ),
        ),
      );
    }

    return ResultFactory.success(
      FaGrammarManualPlan._(
        direction: FaGrammarManualDirection.rightLinearGrammarToFa,
        source: _snapshotForGrammar(source),
        obligations: obligations,
        acceptedActions: const [],
        completedObligationIds: const {},
        sourceFsa: null,
        sourceGrammar: source,
        canonicalGrammar: null,
        canonicalFsa: canonical,
      ),
    );
  }
}

void _addTransitionProductionObligation({
  required List<FaGrammarManualObligation> obligations,
  required FSA source,
  required Grammar canonical,
  required String transitionId,
  required String discriminator,
  required FaGrammarProductionShape shape,
}) {
  obligations.add(
    FaGrammarManualObligation(
      id: _obligationId(
        FaGrammarManualDirection.faToRightLinearGrammar,
        FaGrammarManualActionKind.mapTransitionToProduction,
        '$transitionId:$discriminator',
      ),
      kind: FaGrammarManualActionKind.mapTransitionToProduction,
      production: shape,
      provenance: FaGrammarManualProvenance(
        sourceDocumentId: source.id,
        sourceIds: [transitionId],
        canonicalTargetIds: _matchingProductionIds(canonical, shape),
      ),
    ),
  );
}

List<String> _matchingProductionIds(
  Grammar grammar,
  FaGrammarProductionShape shape,
) =>
    grammar.productions
        .where(
          (production) =>
              shape.sameAs(FaGrammarProductionShape.fromProduction(production)),
        )
        .map((production) => production.id)
        .toList();

List<String> _matchingTransitionIds(
  FSA fsa,
  FaGrammarTransitionShape shape,
) =>
    fsa.fsaTransitions
        .where(
          (transition) =>
              transition.fromState.id == shape.fromStateId &&
              transition.toState.id == shape.toStateId &&
              (shape.isEpsilon
                  ? transition.isEpsilonTransition
                  : transition.inputSymbols.contains(shape.inputSymbol)),
        )
        .map((transition) => transition.id)
        .toList();

bool _isEpsilonProduction(Production production) =>
    production.isLambda ||
    production.rightSide.isEmpty ||
    (production.rightSide.length == 1 &&
        isEpsilonSymbol(production.rightSide.single));

String _obligationId(
  FaGrammarManualDirection direction,
  FaGrammarManualActionKind kind,
  String sourceKey,
) =>
    'fa-grammar:${direction.name}:${kind.name}:${Uri.encodeComponent(sourceKey)}';

FaGrammarManualSourceSnapshot _snapshotForFsa(FSA fsa) {
  final states = fsa.states.toList()..sort((a, b) => a.id.compareTo(b.id));
  final transitions = fsa.fsaTransitions.toList()
    ..sort((a, b) => a.id.compareTo(b.id));
  final canonical = jsonEncode({
    'id': fsa.id,
    'name': fsa.name,
    'alphabet': fsa.alphabet.toList()..sort(),
    'initialStateId': fsa.initialState?.id,
    'acceptingStateIds': fsa.acceptingStates.map((state) => state.id).toList()
      ..sort(),
    'states': [
      for (final state in states)
        {
          'id': state.id,
          'label': state.label,
          'x': state.position.x,
          'y': state.position.y,
          'isInitial': state.isInitial,
          'isAccepting': state.isAccepting,
        },
    ],
    'transitions': [
      for (final transition in transitions)
        {
          'id': transition.id,
          'from': transition.fromState.id,
          'to': transition.toState.id,
          'inputSymbols': transition.inputSymbols.toList()..sort(),
          'lambdaSymbol': transition.lambdaSymbol,
        },
    ],
  });
  return FaGrammarManualSourceSnapshot(
    documentId: fsa.id,
    revision: _revision(canonical),
    canonicalJson: canonical,
  );
}

FaGrammarManualSourceSnapshot _snapshotForGrammar(Grammar grammar) {
  final productions = grammar.productions.toList()
    ..sort((a, b) => a.id.compareTo(b.id));
  final canonical = jsonEncode({
    'id': grammar.id,
    'name': grammar.name,
    'terminals': grammar.terminals.toList()..sort(),
    'nonterminals': grammar.nonterminals.toList()..sort(),
    'startSymbol': grammar.startSymbol,
    'type': grammar.type.name,
    'productions': [
      for (final production in productions)
        {
          'id': production.id,
          'left': production.leftSide,
          'right': production.rightSide,
          'isLambda': production.isLambda,
          'order': production.order,
        },
    ],
  });
  return FaGrammarManualSourceSnapshot(
    documentId: grammar.id,
    revision: _revision(canonical),
    canonicalJson: canonical,
  );
}

String _revision(String canonical) {
  var hash = 0;
  for (final codeUnit in canonical.codeUnits) {
    hash = ((hash * 31) + codeUnit) & 0x7fffffff;
  }
  return '${canonical.length}:${hash.toRadixString(16).padLeft(8, '0')}';
}

FSA _cloneFsa(FSA fsa) => FSA.fromJson(
      (jsonDecode(jsonEncode(fsa.toJson())) as Map).cast<String, dynamic>(),
    );

Grammar _cloneGrammar(Grammar grammar) => Grammar.fromJson(
      (jsonDecode(jsonEncode(grammar.toJson())) as Map).cast<String, dynamic>(),
    );

bool _sameStrings(List<String> left, List<String> right) {
  if (left.length != right.length) return false;
  for (var index = 0; index < left.length; index++) {
    if (left[index] != right[index]) return false;
  }
  return true;
}

Map<String, Object?> _productionShapeJson(
  FaGrammarProductionShape production,
) =>
    {
      'leftSide': production.leftSide,
      'rightSide': production.rightSide,
      'isEpsilon': production.isEpsilon,
    };

Map<String, Object?> _transitionShapeJson(
  FaGrammarTransitionShape transition,
) =>
    {
      'fromStateId': transition.fromStateId,
      'toStateId': transition.toStateId,
      'inputSymbol': transition.inputSymbol,
      'isEpsilon': transition.isEpsilon,
      'toStateIsAccepting': transition.toStateIsAccepting,
    };
