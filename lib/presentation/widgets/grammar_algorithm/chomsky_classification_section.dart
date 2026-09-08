//
//  chomsky_classification_section.dart
//  Turing Lab
//
//  Chomsky-hierarchy classification of the edited grammar: the action buttons,
//  the report actions shown next to a result, and the pure formatter that
//  renders a classification report as text. The panel keeps the report state
//  and the clipboard/metadata side effects.
//

import 'package:flutter/material.dart';

import '../../../core/grammar/phrase_structure/phrase_structure.dart';
import '../../../core/models/grammar.dart';
import '../../../l10n/app_localizations.dart';
import '../../../l10n/app_localizations_resolver.dart';
import '../../../l10n/app_localizations_workflows.dart';
import '../../unrestricted_grammar/unrestricted_grammar_workspace_strings.dart';
import '../common/algorithm_button.dart';
import '../common/algorithm_button_config.dart';

class ChomskyClassificationSection extends StatelessWidget {
  const ChomskyClassificationSection({
    super.key,
    required this.isAnalyzing,
    required this.hasProductions,
    required this.onClassify,
    required this.onOpenVariableDependencyGraph,
  });

  final bool isAnalyzing;
  final bool hasProductions;
  final VoidCallback onClassify;
  final VoidCallback onOpenVariableDependencyGraph;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        AlgorithmButton.fromConfig(
          AlgorithmButtonConfig(
            title: appLocalizationsOf(context).classifyGrammarTitle,
            description: appLocalizationsOf(context).classifyGrammarDescription,
            icon: Icons.account_tree_outlined,
            isEnabled: !isAnalyzing,
            isExecuting: false,
            onPressed: onClassify,
          ),
        ),
        const SizedBox(height: 12),
        AlgorithmButton.fromConfig(
          AlgorithmButtonConfig(
            title: appLocalizationsOf(
              context,
            ).localizeWorkflowText('Variable dependency graph'),
            description: appLocalizationsOf(context).localizeWorkflowText(
              'Explore direct and left-corner dependencies with exact production provenance.',
            ),
            icon: Icons.hub_outlined,
            isEnabled: !isAnalyzing && hasProductions,
            onPressed: onOpenVariableDependencyGraph,
          ),
          key: const ValueKey('open-variable-dependency-graph'),
        ),
      ],
    );
  }
}

/// Copy and declared-type actions rendered under a classification result.
class ChomskyClassificationResultActions extends StatelessWidget {
  const ChomskyClassificationResultActions({
    super.key,
    required this.report,
    required this.onCopyReport,
    this.onUpdateDeclaredType,
  });

  final PhraseGrammarClassificationReport report;
  final VoidCallback onCopyReport;

  /// Null when the declared type already matches or cannot be represented.
  final VoidCallback? onUpdateDeclaredType;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        OutlinedButton.icon(
          key: const ValueKey('copy-classification-report'),
          onPressed: onCopyReport,
          icon: const Icon(Icons.copy),
          label: Text(appLocalizationsOf(context).copyClassificationReport),
        ),
        if (onUpdateDeclaredType case final update?)
          FilledButton.tonalIcon(
            key: const ValueKey('update-declared-grammar-type'),
            onPressed: update,
            icon: const Icon(Icons.edit_outlined),
            label: Text(appLocalizationsOf(context).updateDeclaredGrammarType),
          ),
      ],
    );
  }
}

/// Renders a classification report as the plain text shown in the results
/// card. Pure: it only depends on the localized strings and the locale.
class GrammarClassificationFormatter {
  const GrammarClassificationFormatter({
    required this.strings,
    required this.locale,
  });

  final AppLocalizations strings;
  final Locale locale;

  static GrammarType? toLegacyType(
    PhraseGrammarClassification classification,
  ) => switch (classification) {
    PhraseGrammarClassification.regular => GrammarType.regular,
    PhraseGrammarClassification.contextFree => GrammarType.contextFree,
    PhraseGrammarClassification.contextSensitive =>
      GrammarType.contextSensitive,
    PhraseGrammarClassification.unrestricted => GrammarType.unrestricted,
    PhraseGrammarClassification.invalid => null,
  };

  String format(PhraseGrammarClassificationReport report) {
    final workspaceStrings = UnrestrictedGrammarWorkspaceStrings.forLocale(
      locale,
    );
    final normalForms = report.normalForms.isEmpty
        ? workspaceStrings.noNormalForms
        : report.normalForms.map(workspaceStrings.normalForm).join(', ');
    final buffer = StringBuffer()
      ..writeln(strings.classifyGrammarTitle)
      ..writeln()
      ..writeln(
        '${strings.inferredGrammarType}: '
        '${label(report.classification)}',
      )
      ..writeln(
        '${strings.declaredGrammarType}: '
        '${label(report.declaredClassification!)}',
      )
      ..writeln(
        '${workspaceStrings.regularOrientationLabel}: '
        '${workspaceStrings.orientation(report.regularOrientation)}',
      )
      ..writeln('${workspaceStrings.normalFormsLabel}: $normalForms')
      ..writeln()
      ..writeln(strings.grammarStructureNotLanguageClass);
    if (report.diagnostics.isNotEmpty) {
      final diagnosticsHeading = strings.diagnosticsHeading.endsWith(':')
          ? strings.diagnosticsHeading
          : '${strings.diagnosticsHeading}:';
      buffer
        ..writeln()
        ..writeln(diagnosticsHeading);
      for (final diagnostic in report.diagnostics) {
        buffer.writeln('- ${workspaceStrings.diagnostic(diagnostic)}');
      }
    }
    if (report.productionEvidence.isNotEmpty) {
      buffer
        ..writeln()
        ..writeln('${workspaceStrings.productionEvidenceLabel}:');
      for (final evidence in report.productionEvidence) {
        final predicates = evidence.violated
            .map(workspaceStrings.predicate)
            .join(', ');
        buffer.writeln(
          '- ${evidence.productionId}: '
          '${evidence.violated.isEmpty ? workspaceStrings.allPredicatesSatisfied : workspaceStrings.violatesPredicates(predicates)}',
        );
      }
    }
    return buffer.toString();
  }

  String label(PhraseGrammarClassification classification) =>
      switch (classification) {
        PhraseGrammarClassification.regular => strings.grammarCnfTypeRegular,
        PhraseGrammarClassification.contextFree =>
          strings.grammarCnfTypeContextFree,
        PhraseGrammarClassification.contextSensitive =>
          strings.grammarCnfTypeContextSensitive,
        PhraseGrammarClassification.unrestricted =>
          strings.grammarCnfTypeUnrestricted,
        PhraseGrammarClassification.invalid => strings.grammarCnfTypeInvalid,
      };
}
