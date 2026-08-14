import 'package:turing_lab/core/algorithms/cfg/cfg_toolkit.dart';
import 'package:turing_lab/core/models/grammar.dart';
import 'package:turing_lab/core/models/grammar_diagnostic.dart';
import 'package:turing_lab/core/models/grammar_diagnostic_severity.dart';
import 'package:turing_lab/core/models/grammar_transformation_step.dart';

class GrammarGnfTransformationReport {
  final Grammar grammar;
  final List<GrammarTransformationStep> steps;
  final List<GrammarDiagnostic> diagnostics;

  const GrammarGnfTransformationReport({
    required this.grammar,
    required this.steps,
    required this.diagnostics,
  });
}

class GrammarGnfTransformer {
  static GrammarGnfTransformationReport toGnf(Grammar grammar) {
    final steps = <GrammarTransformationStep>[];
    final diagnostics = <GrammarDiagnostic>[];

    final result = CFGToolkit.toGNF(grammar);
    if (result.isFailure || result.data == null) {
      diagnostics.add(
        GrammarDiagnostic(
          code: 'gnf_transform_failed',
          severity: GrammarDiagnosticSeverity.error,
          message: result.error ?? 'Failed to transform grammar to GNF.',
        ),
      );
      return GrammarGnfTransformationReport(
        grammar: grammar,
        steps: steps,
        diagnostics: diagnostics,
      );
    }

    final gnfGrammar = result.data!;
    steps.add(
      GrammarTransformationStep(
        id: 'gnf.convert',
        operation: 'Convert to Greibach Normal Form (GNF)',
        rationale:
            'Converted grammar to Greibach Normal Form where each production has the form A → aα (a terminal followed by zero or more nonterminals).',
        before: grammar,
        after: gnfGrammar,
        changedSymbols: {
          ...gnfGrammar.nonterminals.where(
            (s) => !grammar.nonterminals.contains(s),
          ),
          ...gnfGrammar.terminals.where((s) => !grammar.terminals.contains(s)),
        },
      ),
    );

    if (!CFGToolkit.isGNF(gnfGrammar)) {
      diagnostics.add(
        const GrammarDiagnostic(
          code: 'gnf_transform_not_gnf',
          severity: GrammarDiagnosticSeverity.warning,
          message:
              'GNF conversion completed but the resulting grammar does not satisfy the strict GNF shape check. This can happen for grammars outside expected preconditions.',
        ),
      );
    }

    return GrammarGnfTransformationReport(
      grammar: gnfGrammar,
      steps: steps,
      diagnostics: diagnostics,
    );
  }
}
