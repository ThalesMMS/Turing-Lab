part of '../grammar_analyzer.dart';

/// Centralizes aggregate report creation without adding presentation behavior.
class GrammarReportComposer {
  const GrammarReportComposer._();

  static GrammarAnalysisReport<T> compose<T>({
    required T value,
    List<String> notes = const [],
    List<StructuredMessage> structuredNotes = const [],
    List<String> derivations = const [],
    List<StructuredMessage> structuredDerivations = const [],
    List<String> conflicts = const [],
    List<StructuredMessage> structuredConflicts = const [],
    List<GrammarTransformationStep> steps = const [],
    List<GrammarAnalysisStructuredTransformationStep> structuredSteps =
        const [],
  }) {
    return GrammarAnalysisReport<T>(
      value: value,
      notes: notes,
      structuredNotes: structuredNotes,
      derivations: derivations,
      structuredDerivations: structuredDerivations,
      conflicts: conflicts,
      structuredConflicts: structuredConflicts,
      steps: steps,
      structuredSteps: structuredSteps,
    );
  }
}
