import 'package:turing_lab/core/algorithms/cfg/cfg_toolkit.dart';
import 'package:turing_lab/core/algorithms/grammar_gnf_messages.dart';
import 'package:turing_lab/core/algorithms/grammar_gnf_transformation_report.dart';
import 'package:turing_lab/core/messages/structured_message.dart';
import 'package:turing_lab/core/models/grammar.dart';
import 'package:turing_lab/core/models/grammar_diagnostic.dart';
import 'package:turing_lab/core/models/grammar_diagnostic_severity.dart';
import 'package:turing_lab/core/models/grammar_gnf_structured_transformation_step.dart';
import 'package:turing_lab/core/models/grammar_transformation_step.dart';

export 'grammar_gnf_transformation_report.dart';

class GrammarGnfTransformer {
  static GrammarGnfTransformationReport toGnf(Grammar grammar) {
    final steps = <GrammarTransformationStep>[];
    final structuredSteps = <GrammarGnfStructuredTransformationStep>[];
    final diagnostics = <GrammarDiagnostic>[];

    final result = CFGToolkit.toGNF(grammar);
    if (result.isFailure || result.data == null) {
      final message = GrammarGnfMessages.transformFailed();
      diagnostics.add(
        _gnfDiagnostic(code: 'gnf_transform_failed', message: message),
      );
      return GrammarGnfTransformationReport(
        grammar: grammar,
        steps: steps,
        structuredSteps: structuredSteps,
        diagnostics: diagnostics,
      );
    }

    final gnfGrammar = result.data!;
    final step = GrammarTransformationStep(
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
    );
    steps.add(step);
    structuredSteps.add(
      GrammarGnfStructuredTransformationStep(
        legacyStep: step,
        operationMessage: GrammarGnfMessages.convertTitle(),
        rationaleMessage: GrammarGnfMessages.convertRationale(),
      ),
    );

    if (!CFGToolkit.isGNF(gnfGrammar)) {
      final message = GrammarGnfMessages.notGnf();
      diagnostics.add(
        _gnfDiagnostic(code: 'gnf_transform_not_gnf', message: message),
      );
    }

    return GrammarGnfTransformationReport(
      grammar: gnfGrammar,
      steps: steps,
      structuredSteps: structuredSteps,
      diagnostics: diagnostics,
    );
  }

  static GrammarDiagnostic _gnfDiagnostic({
    required String code,
    required StructuredMessage message,
  }) => GrammarDiagnostic(
    code: code,
    severity: switch (message.severity) {
      StructuredMessageSeverity.information => GrammarDiagnosticSeverity.info,
      StructuredMessageSeverity.warning => GrammarDiagnosticSeverity.warning,
      StructuredMessageSeverity.error => GrammarDiagnosticSeverity.error,
      StructuredMessageSeverity.unknown => GrammarDiagnosticSeverity.info,
    },
    message: message.stableCode,
    structuredMessage: message,
  );
}
