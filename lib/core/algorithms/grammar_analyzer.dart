//
//  grammar_analyzer.dart
//  Turing Lab
//
//  Stable facade for deterministic grammar analysis and transformation.
//
//  Thales Matheus Mendonça Santos - October 2025
//
import '../models/grammar.dart';
import '../models/grammar_diagnostic.dart';
import '../models/grammar_diagnostic_severity.dart';
import '../models/grammar_diagnostics_report.dart';
import '../models/grammar_transformation_step.dart';
import '../models/production.dart';
import '../messages/structured_message.dart';
import '../result.dart';
import '../utils/epsilon_utils.dart';
import 'grammar_analysis_messages.dart';
import 'grammar_structural_messages.dart';

part 'grammar_analysis/grammar_ambiguity_analyzer.dart';
part 'grammar_analysis/grammar_analysis_context.dart';
part 'grammar_analysis/grammar_analysis_models.dart';
part 'grammar_analysis/grammar_left_recursion_analyzer.dart';
part 'grammar_analysis/grammar_nullable_first_follow_analyzer.dart';
part 'grammar_analysis/grammar_predictive_analyzer.dart';
part 'grammar_analysis/grammar_report_composer.dart';
part 'grammar_analysis/grammar_structural_analyzer.dart';

/// Backward-compatible entrypoint for grammar analysis operations.
class GrammarAnalyzer {
  const GrammarAnalyzer();

  static Result<GrammarDiagnosticsReport> validateMalformedProductions(
    Grammar grammar,
  ) {
    final context = GrammarAnalysisContext(grammar);
    return GrammarStructuralAnalyzer(context).validateMalformedProductions();
  }

  static Result<GrammarDiagnosticsReport> detectUnreachableNonTerminals(
    Grammar grammar,
  ) {
    final context = GrammarAnalysisContext(grammar);
    return GrammarStructuralAnalyzer(context).detectUnreachableNonTerminals();
  }

  static Result<GrammarDiagnosticsReport> detectUnproductiveNonTerminals(
    Grammar grammar,
  ) {
    final context = GrammarAnalysisContext(grammar);
    return GrammarStructuralAnalyzer(context).detectUnproductiveNonTerminals();
  }

  /// Removes direct and indirect left recursion by ordered substitution.
  static Result<GrammarAnalysisReport<Grammar>> removeLeftRecursion(
    Grammar grammar,
  ) {
    final context = GrammarAnalysisContext(grammar);
    if (context.productions.isEmpty) {
      final message = GrammarAnalysisMessages.emptyProductions();
      return Failure(message.stableCode, structuredMessage: message);
    }
    if (!GrammarLeftRecursionAnalyzer(context).hasLeftCornerCycle()) {
      return ResultFactory.success(
        GrammarReportComposer.compose(
          value: grammar,
          structuredNotes: [GrammarAnalysisMessages.noLeftRecursion()],
        ),
      );
    }
    return GrammarLeftRecursionTransformer(context).removeLeftRecursion();
  }

  @Deprecated('Use removeLeftRecursion, which also handles indirect cycles.')
  static Result<GrammarAnalysisReport<Grammar>> removeDirectLeftRecursion(
    Grammar grammar,
  ) => removeLeftRecursion(grammar);

  static Result<GrammarAnalysisReport<Grammar>> leftFactor(Grammar grammar) {
    final context = GrammarAnalysisContext(grammar);
    return GrammarPredictiveAnalyzer(context).leftFactor();
  }

  // FIRST/FOLLOW/LL(1) reference notes live in docs/reference-deviations.md.
  static Result<GrammarAnalysisReport<Map<String, Set<String>>>>
  computeFirstSets(Grammar grammar) {
    final context = GrammarAnalysisContext(grammar);
    return GrammarNullableFirstFollowAnalyzer(context).computeFirstSets();
  }

  // FIRST/FOLLOW/LL(1) reference notes live in docs/reference-deviations.md.
  static Result<GrammarAnalysisReport<Map<String, Set<String>>>>
  computeFollowSets(Grammar grammar) {
    final context = GrammarAnalysisContext(grammar);
    return GrammarNullableFirstFollowAnalyzer(context).computeFollowSets();
  }

  // FIRST/FOLLOW/LL(1) reference notes live in docs/reference-deviations.md.
  static Result<GrammarAnalysisReport<LL1ParseTable>> buildLL1ParseTable(
    Grammar grammar,
  ) {
    final context = GrammarAnalysisContext(grammar);
    return GrammarPredictiveAnalyzer(context).buildLL1ParseTable();
  }

  /// Legacy LL(1)-based ambiguity indicator.
  ///
  /// Returns `true` when no LL(1) conflicts are found. A `false` value proves
  /// only that the grammar is not LL(1), not that it is ambiguous.
  static Result<GrammarAnalysisReport<bool>> detectAmbiguity(Grammar grammar) {
    final context = GrammarAnalysisContext(grammar);
    return GrammarAmbiguityAnalyzer(context).legacyReport();
  }
}

class ListEquality {
  const ListEquality();

  bool equals(List<Object?> a, List<Object?> b) {
    if (a.length != b.length) {
      return false;
    }
    for (var i = 0; i < a.length; i++) {
      if (a[i] != b[i]) {
        return false;
      }
    }
    return true;
  }
}
