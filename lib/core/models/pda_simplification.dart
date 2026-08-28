import 'pda.dart';
import 'pda_acceptance_mode.dart';
import '../messages/structured_message.dart';

/// Individually reportable phases of the conservative PDA simplifier.
enum PDASimplificationPhase {
  validation,
  structuralReachability,
  semanticUsefulness,
  strongBisimulation,
  rebuildValidation,
  boundedLanguageCheck,
}

enum PDASimplificationPhaseStatus { completed, skipped }

enum PDASimplificationChangeKind {
  removedState,
  mergedState,
  removedTransition,
}

enum PDASimplificationChangeReason {
  unreachableControlState,
  incidentToUnreachableState,
  bisimilarControlStates,
  duplicateTransition,
}

/// Optional sampled comparison. It is evidence, never a language-equivalence
/// proof.
class PDABoundedLanguageCheck {
  final Set<String> alphabet;
  final int maxLength;

  const PDABoundedLanguageCheck({
    required this.alphabet,
    required this.maxLength,
  });
}

class PDASimplificationOptions {
  final bool enableSemanticUsefulness;
  final bool enableStrongBisimulation;
  final PDABoundedLanguageCheck? boundedCheck;

  const PDASimplificationOptions({
    this.enableSemanticUsefulness = true,
    this.enableStrongBisimulation = true,
    this.boundedCheck,
  });
}

class PDASimplificationPhaseResult {
  final PDASimplificationPhase phase;
  final PDASimplificationPhaseStatus status;
  final String description;
  final StructuredMessage? descriptionMessage;

  const PDASimplificationPhaseResult({
    required this.phase,
    required this.status,
    required this.description,
    this.descriptionMessage,
  });

  Map<String, Object?> toJson() => {
    'phase': phase.name,
    'status': status.name,
    'description': description,
    if (descriptionMessage != null)
      'descriptionMessage': descriptionMessage!.toJson(),
  };
}

class PDASimplificationChange {
  final PDASimplificationChangeKind kind;
  final PDASimplificationChangeReason reason;
  final List<String> sourceIds;
  final String? representativeId;

  PDASimplificationChange({
    required this.kind,
    required this.reason,
    required Iterable<String> sourceIds,
    this.representativeId,
  }) : sourceIds = List<String>.unmodifiable(
         sourceIds.toSet().toList()..sort(),
       );

  Map<String, Object?> toJson() => {
    'kind': kind.name,
    'reason': reason.name,
    'sourceIds': sourceIds,
    if (representativeId != null) 'representativeId': representativeId,
  };
}

class PDASimplificationCounts {
  final int statesBefore;
  final int statesAfter;
  final int transitionsBefore;
  final int transitionsAfter;

  const PDASimplificationCounts({
    required this.statesBefore,
    required this.statesAfter,
    required this.transitionsBefore,
    required this.transitionsAfter,
  });

  int get statesRemoved => statesBefore - statesAfter;
  int get transitionsRemoved => transitionsBefore - transitionsAfter;

  Map<String, Object?> toJson() => {
    'statesBefore': statesBefore,
    'statesAfter': statesAfter,
    'transitionsBefore': transitionsBefore,
    'transitionsAfter': transitionsAfter,
  };
}

class PDASampledEvidence {
  final int wordsChecked;
  final String description;
  final StructuredMessage? descriptionMessage;

  const PDASampledEvidence({
    required this.wordsChecked,
    required this.description,
    this.descriptionMessage,
  });

  /// A finite sample cannot prove equivalence of two general NPDAs.
  bool get isProof => false;

  Map<String, Object?> toJson() => {
    'wordsChecked': wordsChecked,
    'description': description,
    if (descriptionMessage != null)
      'descriptionMessage': descriptionMessage!.toJson(),
    'isProof': false,
  };
}

class PDASimplificationResult {
  final PDA originalPda;
  final PDA simplifiedPda;
  final PDAAcceptanceMode acceptanceMode;
  final List<PDASimplificationPhaseResult> phases;
  final List<PDASimplificationChange> changes;
  final List<String> warnings;
  final List<StructuredMessage> structuredWarnings;
  final PDASimplificationCounts counts;
  final PDASampledEvidence? sampledEvidence;

  PDASimplificationResult({
    required this.originalPda,
    required this.simplifiedPda,
    required this.acceptanceMode,
    required Iterable<PDASimplificationPhaseResult> phases,
    required Iterable<PDASimplificationChange> changes,
    required Iterable<String> warnings,
    required this.counts,
    this.sampledEvidence,
    Iterable<StructuredMessage> structuredWarnings = const [],
  }) : phases = List.unmodifiable(phases),
       changes = List.unmodifiable(changes),
       warnings = List.unmodifiable(warnings),
       structuredWarnings = List.unmodifiable(structuredWarnings);

  bool get changed => changes.isNotEmpty;

  PDASimplificationPhaseResult phase(PDASimplificationPhase phase) =>
      phases.singleWhere((result) => result.phase == phase);
}
