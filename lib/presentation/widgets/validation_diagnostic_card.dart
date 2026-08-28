//  validation_diagnostic_card.dart
//  Turing Lab
//
//  UI card for rendering a structured ValidationDiagnostic (summary, details,
//  and suggested fixes). This is used by validation flows to provide actionable
//  feedback and to optionally drive canvas highlight overlays.
//

import 'package:flutter/material.dart';

import '../../core/models/validation_diagnostic.dart';
import '../../l10n/app_localizations_resolver.dart';
import '../../l10n/app_localizations_structured_messages.dart';
import '../../l10n/app_localizations_workflows.dart';

class ValidationDiagnosticCard extends StatelessWidget {
  const ValidationDiagnosticCard({super.key, required this.diagnostic});

  final ValidationDiagnostic diagnostic;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = appLocalizationsOf(context);
    final fixes = diagnostic.suggestedFixes;
    final localizedSummary = diagnostic.structuredMessage == null
        ? diagnostic.summary
        : l10n.resolveStructuredMessage(diagnostic.structuredMessage!);
    final localizedDetails = diagnostic.details == null
        ? null
        : l10n.localizeWorkflowText(diagnostic.details!);

    return Card(
      margin: const EdgeInsets.all(8),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.rule_folder_outlined, size: 18),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    localizedSummary,
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
            if (localizedDetails != null && localizedDetails.trim().isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Text(
                  localizedDetails,
                  style: theme.textTheme.bodyMedium,
                ),
              ),
            if (fixes.isNotEmpty) ...[
              const SizedBox(height: 12),
              Text(
                l10n.suggestedFixes,
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 8),
              ...fixes.map(
                (fix) => Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Padding(
                        padding: EdgeInsets.only(top: 2),
                        child: Icon(Icons.lightbulb_outline, size: 16),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              l10n.localizeWorkflowText(fix.label),
                              style: theme.textTheme.bodyMedium?.copyWith(
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            if (fix.details != null &&
                                l10n
                                    .localizeWorkflowText(fix.details!)
                                    .trim()
                                    .isNotEmpty)
                              Padding(
                                padding: const EdgeInsets.only(top: 2),
                                child: Text(
                                  l10n.localizeWorkflowText(fix.details!),
                                  style: theme.textTheme.bodySmall,
                                ),
                              ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Text(
                l10n.interoperabilityDiagnosticTechnicalCode(diagnostic.code),
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
