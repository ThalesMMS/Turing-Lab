part of '../grammar_analyzer.dart';

class GrammarAmbiguityAnalyzer {
  const GrammarAmbiguityAnalyzer(this.context);

  final GrammarAnalysisContext context;

  Result<GrammarAnalysisReport<GrammarAmbiguityAssessment>> assess() {
    final tableResult = GrammarPredictiveAnalyzer(context).buildLL1ParseTable();
    if (tableResult.isFailure) {
      return Failure(
        tableResult.error!,
        structuredMessage: tableResult.structuredError,
      );
    }
    final tableReport = tableResult.data!;
    final conflicts = List<String>.from(tableReport.conflicts);
    final appearsLl1 = conflicts.isEmpty;
    final assessment = GrammarAmbiguityAssessment(
      appearsLl1: appearsLl1,
      evidence: GrammarAmbiguityEvidence.ll1ConflictHeuristic,
      isComplete: false,
      limitation: GrammarAmbiguityLimitation.ll1ConflictsDoNotDecideAmbiguity,
      conflicts: List<String>.unmodifiable(conflicts),
    );
    return ResultFactory.success(
      GrammarReportComposer.compose(
        value: assessment,
        notes: [
          if (appearsLl1)
            'No LL(1) conflicts detected (grammar appears LL(1) for this analysis).'
          else
            'LL(1) conflicts detected (grammar is not LL(1)).',
          'Note: Being non-LL(1) does not necessarily mean the grammar is ambiguous; it may still be unambiguous but require a stronger parser (e.g., LR/Earley).',
        ],
        structuredNotes: [
          if (appearsLl1)
            GrammarAmbiguityMessages.noLl1Conflicts()
          else
            GrammarAmbiguityMessages.ll1ConflictsDetected(),
          GrammarAmbiguityMessages.nonLl1DoesNotImplyAmbiguity(),
        ],
        conflicts: conflicts,
        derivations: tableReport.derivations,
        structuredDerivations: tableReport.structuredDerivations,
        structuredConflicts: tableReport.structuredConflicts,
      ),
    );
  }

  Result<GrammarAnalysisReport<bool>> legacyReport() {
    final result = assess();
    if (result.isFailure) {
      return Failure(result.error!, structuredMessage: result.structuredError);
    }
    final report = result.data!;
    return ResultFactory.success(
      GrammarReportComposer.compose(
        value: report.value.appearsLl1,
        notes: report.notes,
        structuredNotes: report.structuredNotes,
        conflicts: report.conflicts,
        derivations: report.derivations,
        structuredDerivations: report.structuredDerivations,
        structuredConflicts: report.structuredConflicts,
      ),
    );
  }
}

abstract final class GrammarAmbiguityMessages {
  static StructuredMessage noLl1Conflicts() => _message(
    'no-ll1-conflicts',
    severity: StructuredMessageSeverity.information,
  );

  static StructuredMessage ll1ConflictsDetected() => _message(
    'll1-conflicts-detected',
    severity: StructuredMessageSeverity.warning,
  );

  static StructuredMessage nonLl1DoesNotImplyAmbiguity() => _message(
    'non-ll1-does-not-imply-ambiguity',
    severity: StructuredMessageSeverity.information,
  );
}

StructuredMessage _message(
  String code, {
  StructuredMessageSeverity severity = StructuredMessageSeverity.warning,
}) => StructuredMessage(
  namespace: 'grammar.ambiguity',
  code: code,
  category: StructuredMessageCategory.analysis,
  severity: severity,
);
