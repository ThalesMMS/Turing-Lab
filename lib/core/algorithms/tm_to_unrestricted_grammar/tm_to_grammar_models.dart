import '../../grammar/phrase_structure/phrase_structure.dart';
import '../../messages/structured_message.dart';
import '../../models/tm_transition.dart';

enum TMToGrammarOutcome {
  completed,
  invalidMachine,
  unsupportedMachine,
  constructionLimit,
  outputInvalid,
}

enum TMToGrammarDiagnosticSeverity { warning, error }

enum TMToGrammarDiagnosticCode {
  invalidMachine,
  missingInitialState,
  noAcceptingState,
  multiTapeUnsupported,
  buildingBlocksUnsupported,
  blankInInputAlphabet,
  inputOutsideTapeAlphabet,
  constructionLimit,
  outputInvalid,
  unreachableState,
}

enum TMToGrammarProductionFamily {
  initialization,
  inputCell,
  boundaryBlank,
  moveLeft,
  moveRight,
  stay,
  acceptingState,
  cleanupLeft,
  cleanupRight,
}

enum TMToGrammarAssumption {
  singleTape,
  twoWayInfiniteTape,
  finalStateAcceptance,
  deterministicOrNondeterministic,
  atomicTokenSymbols,
  finiteWindowChosenByDerivation,
  sampledEvidenceNotProof,
}

final class TMToGrammarDiagnostic {
  TMToGrammarDiagnostic({
    required this.code,
    required this.severity,
    this.stateId,
    this.transitionId,
    this.symbol,
    this.detailCode,
    Iterable<String> relatedIds = const [],
    this.structuredMessage,
  }) : relatedIds = List<String>.unmodifiable(relatedIds);

  final TMToGrammarDiagnosticCode code;
  final TMToGrammarDiagnosticSeverity severity;
  final String? stateId;
  final String? transitionId;
  final String? symbol;
  final String? detailCode;
  final List<String> relatedIds;

  /// Locale-neutral semantic payload for this conversion diagnostic.
  final StructuredMessage? structuredMessage;
}

final class TMToGrammarSourceReference {
  const TMToGrammarSourceReference({
    this.stateId,
    this.transitionId,
    this.tapeIndex,
    this.readSymbol,
    this.writeSymbol,
    this.direction,
  });

  final String? stateId;
  final String? transitionId;
  final int? tapeIndex;
  final String? readSymbol;
  final String? writeSymbol;
  final TapeDirection? direction;

  Map<String, Object?> toJson() => {
    if (stateId != null) 'stateId': stateId,
    if (transitionId != null) 'transitionId': transitionId,
    if (tapeIndex != null) 'tapeIndex': tapeIndex,
    if (readSymbol != null) 'readSymbol': readSymbol,
    if (writeSymbol != null) 'writeSymbol': writeSymbol,
    if (direction != null) 'direction': direction!.name,
  };
}

final class TMToGrammarProductionProvenance {
  TMToGrammarProductionProvenance({
    required this.productionId,
    required this.family,
    required this.invariantCode,
    Iterable<TMToGrammarSourceReference> sources = const [],
  }) : sources = List<TMToGrammarSourceReference>.unmodifiable(sources);

  final String productionId;
  final TMToGrammarProductionFamily family;
  final String invariantCode;
  final List<TMToGrammarSourceReference> sources;

  Map<String, Object?> toJson() => {
    'productionId': productionId,
    'family': family.name,
    'invariantCode': invariantCode,
    'sources': sources.map((source) => source.toJson()).toList(),
  };
}

final class TMToGrammarConstructionReport {
  TMToGrammarConstructionReport({
    required this.sourceTmId,
    required this.sourceRevision,
    required this.outcome,
    required Iterable<TMToGrammarAssumption> assumptions,
    Iterable<TMToGrammarDiagnostic> diagnostics = const [],
    Iterable<TMToGrammarProductionProvenance> productionProvenance = const [],
    Map<String, String> symbolDescriptions = const {},
    this.grammar,
  }) : assumptions = Set<TMToGrammarAssumption>.unmodifiable(assumptions),
       diagnostics = List<TMToGrammarDiagnostic>.unmodifiable(diagnostics),
       productionProvenance =
           List<TMToGrammarProductionProvenance>.unmodifiable(
             productionProvenance,
           ),
       _provenanceByProductionId =
           Map<String, TMToGrammarProductionProvenance>.unmodifiable({
             for (final provenance in productionProvenance)
               provenance.productionId: provenance,
           }),
       symbolDescriptions = Map<String, String>.unmodifiable(
         symbolDescriptions,
       );

  final String sourceTmId;
  final int sourceRevision;
  final TMToGrammarOutcome outcome;
  final Set<TMToGrammarAssumption> assumptions;
  final List<TMToGrammarDiagnostic> diagnostics;
  final List<TMToGrammarProductionProvenance> productionProvenance;
  final Map<String, TMToGrammarProductionProvenance> _provenanceByProductionId;
  final Map<String, String> symbolDescriptions;
  final UnrestrictedGrammar? grammar;

  bool get isCompleted =>
      outcome == TMToGrammarOutcome.completed && grammar != null;

  TMToGrammarProductionProvenance? provenanceFor(String productionId) =>
      _provenanceByProductionId[productionId];

  Map<TMToGrammarProductionFamily, int> get productionCountsByFamily {
    final counts = <TMToGrammarProductionFamily, int>{};
    for (final provenance in productionProvenance) {
      counts.update(provenance.family, (value) => value + 1, ifAbsent: () => 1);
    }
    return Map<TMToGrammarProductionFamily, int>.unmodifiable(counts);
  }

  Map<String, Object?> toStructuredJson() => {
    'schema': 'turing-lab.tm-to-unrestricted-grammar-report.v1',
    'sourceTmId': sourceTmId,
    'sourceRevision': sourceRevision,
    'outcome': outcome.name,
    'assumptions': assumptions.map((value) => value.name).toList()..sort(),
    'diagnostics': [
      for (final diagnostic in diagnostics)
        {
          'code': diagnostic.code.name,
          'severity': diagnostic.severity.name,
          if (diagnostic.stateId != null) 'stateId': diagnostic.stateId,
          if (diagnostic.transitionId != null)
            'transitionId': diagnostic.transitionId,
          if (diagnostic.symbol != null) 'symbol': diagnostic.symbol,
          if (diagnostic.detailCode != null)
            'detailCode': diagnostic.detailCode,
          'relatedIds': diagnostic.relatedIds,
          if (diagnostic.structuredMessage != null)
            'structuredMessage': diagnostic.structuredMessage!.toJson(),
        },
    ],
    'productionProvenance': productionProvenance
        .map((value) => value.toJson())
        .toList(),
    'symbolDescriptions': symbolDescriptions,
    if (grammar != null) ...{
      'counts': {
        'terminals': grammar!.terminals.length,
        'variables': grammar!.nonterminals.length,
        'productions': grammar!.productions.length,
        'productionFamilies': {
          for (final family in TMToGrammarProductionFamily.values)
            family.name: productionCountsByFamily[family] ?? 0,
        },
      },
      'grammar': grammar!.toJson(),
    },
  };
}

enum TMToGrammarSampleOutcome {
  matchingAcceptance,
  matchingRejection,
  mismatch,
  boundedUnknown,
  invalid,
}

final class TMToGrammarSampleEvidence {
  TMToGrammarSampleEvidence({
    required Iterable<String> inputTokens,
    required this.outcome,
    this.tmAccepted,
    this.grammarAccepted,
    this.detailCode,
  }) : inputTokens = List<String>.unmodifiable(inputTokens);

  final List<String> inputTokens;
  final TMToGrammarSampleOutcome outcome;
  final bool? tmAccepted;
  final bool? grammarAccepted;
  final String? detailCode;
}

final class TMToGrammarDifferentialReport {
  TMToGrammarDifferentialReport(Iterable<TMToGrammarSampleEvidence> samples)
    : samples = List<TMToGrammarSampleEvidence>.unmodifiable(samples);

  final List<TMToGrammarSampleEvidence> samples;
  bool get isProof => false;
  bool get hasMismatch => samples.any(
    (sample) => sample.outcome == TMToGrammarSampleOutcome.mismatch,
  );
}
