import '../../models/pda.dart';
import '../../models/pda_acceptance_mode.dart';
import '../../messages/structured_message.dart';

enum CfgToPdaOrientation { ll, lr }

enum CfgToPdaConstructionOutcome {
  completed,
  invalidGrammar,
  llConflict,
  lrConflict,
  prerequisiteUnavailable,
  outputInvalid,
}

enum CfgToPdaDiagnosticCode {
  emptyGrammar,
  missingStartSymbol,
  undeclaredStartSymbol,
  malformedProduction,
  duplicateProductionId,
  undeclaredSymbol,
  llAnalysisFailed,
  llConflict,
  lrConstructionUnavailable,
  lrConflict,
  outputInvalid,
}

enum CfgToPdaAssumption {
  contextFreeSource,
  finalStateAfterInput,
  bottomMarkerInitialized,
  llPredictiveConflictFree,
  llTopDownExpansion,
  lrCanonicalConflictFree,
  lrBottomUpReduction,
  sampledEvidenceNotProof,
}

enum CfgToPdaStepKind {
  createState,
  initializeStack,
  expandVariable,
  matchTerminal,
  shiftTerminal,
  reduceProduction,
  acceptStart,
  popBottomMarker,
}

enum CfgToPdaSourceSide { left, right }

class CfgToPdaDiagnostic {
  CfgToPdaDiagnostic({
    required this.code,
    this.productionId,
    this.symbol,
    this.nonTerminal,
    this.lookahead,
    this.lrState,
    Iterable<String> relatedProductionIds = const [],
    this.detailCode,
    this.structuredMessage,
  }) : relatedProductionIds = List<String>.unmodifiable(relatedProductionIds);

  final CfgToPdaDiagnosticCode code;
  final String? productionId;
  final String? symbol;
  final String? nonTerminal;
  final String? lookahead;
  final int? lrState;
  final List<String> relatedProductionIds;
  final String? detailCode;

  /// Locale-neutral replacement for any presentation text derived from this
  /// diagnostic. The legacy enum and detail fields remain unchanged.
  final StructuredMessage? structuredMessage;
}

class CfgToPdaSourceReference {
  CfgToPdaSourceReference({
    this.productionId,
    this.symbol,
    this.symbolPosition,
    this.side,
    this.lrState,
    this.lookahead,
    Iterable<String> lrItemKeys = const [],
  }) : lrItemKeys = List<String>.unmodifiable(lrItemKeys);

  final String? productionId;
  final String? symbol;
  final int? symbolPosition;
  final CfgToPdaSourceSide? side;
  final int? lrState;
  final String? lookahead;
  final List<String> lrItemKeys;
}

class CfgToPdaStep {
  CfgToPdaStep({
    required this.index,
    required this.kind,
    Iterable<String> stateIds = const [],
    Iterable<String> transitionIds = const [],
    Iterable<CfgToPdaSourceReference> sources = const [],
  }) : stateIds = List<String>.unmodifiable(stateIds),
       transitionIds = List<String>.unmodifiable(transitionIds),
       sources = List<CfgToPdaSourceReference>.unmodifiable(sources);

  final int index;
  final CfgToPdaStepKind kind;
  final List<String> stateIds;
  final List<String> transitionIds;
  final List<CfgToPdaSourceReference> sources;
}

class CfgToPdaTransitionProvenance {
  CfgToPdaTransitionProvenance({
    required this.transitionId,
    required this.stepIndex,
    required this.kind,
    Iterable<CfgToPdaSourceReference> sources = const [],
  }) : sources = List<CfgToPdaSourceReference>.unmodifiable(sources);

  final String transitionId;
  final int stepIndex;
  final CfgToPdaStepKind kind;
  final List<CfgToPdaSourceReference> sources;
}

class CfgToPdaConstructionReport {
  CfgToPdaConstructionReport({
    required this.sourceGrammarId,
    required this.sourceRevision,
    required this.orientation,
    required this.outcome,
    required this.acceptanceMode,
    required Iterable<CfgToPdaAssumption> assumptions,
    Iterable<CfgToPdaDiagnostic> diagnostics = const [],
    Iterable<CfgToPdaStep> steps = const [],
    Iterable<CfgToPdaTransitionProvenance> transitionProvenance = const [],
    this.pda,
  }) : assumptions = Set<CfgToPdaAssumption>.unmodifiable(assumptions),
       diagnostics = List<CfgToPdaDiagnostic>.unmodifiable(diagnostics),
       steps = List<CfgToPdaStep>.unmodifiable(steps),
       transitionProvenance = List<CfgToPdaTransitionProvenance>.unmodifiable(
         transitionProvenance,
       );

  final String sourceGrammarId;
  final int sourceRevision;
  final CfgToPdaOrientation orientation;
  final CfgToPdaConstructionOutcome outcome;
  final PDAAcceptanceMode acceptanceMode;
  final Set<CfgToPdaAssumption> assumptions;
  final List<CfgToPdaDiagnostic> diagnostics;
  final List<CfgToPdaStep> steps;
  final List<CfgToPdaTransitionProvenance> transitionProvenance;
  final PDA? pda;

  bool get isCompleted =>
      outcome == CfgToPdaConstructionOutcome.completed && pda != null;

  CfgToPdaTransitionProvenance? provenanceFor(String transitionId) {
    for (final provenance in transitionProvenance) {
      if (provenance.transitionId == transitionId) return provenance;
    }
    return null;
  }
}

enum CfgToPdaSampleOutcome {
  matchingAcceptance,
  matchingRejection,
  mismatch,
  boundedUnknown,
}

class CfgToPdaSampleEvidence {
  const CfgToPdaSampleEvidence({
    required this.input,
    required this.outcome,
    this.grammarAccepted,
    this.pdaAccepted,
    this.detailCode,
  });

  final String input;
  final CfgToPdaSampleOutcome outcome;
  final bool? grammarAccepted;
  final bool? pdaAccepted;
  final String? detailCode;
}

class CfgToPdaDifferentialReport {
  CfgToPdaDifferentialReport({
    required Iterable<CfgToPdaSampleEvidence> samples,
  }) : samples = List<CfgToPdaSampleEvidence>.unmodifiable(samples);

  final List<CfgToPdaSampleEvidence> samples;

  bool get isProof => false;
  bool get hasMismatch =>
      samples.any((sample) => sample.outcome == CfgToPdaSampleOutcome.mismatch);
}
