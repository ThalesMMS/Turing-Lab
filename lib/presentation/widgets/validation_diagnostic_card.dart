//  validation_diagnostic_card.dart
//  Turing Lab
//
//  UI card for rendering a structured ValidationDiagnostic (summary, details,
//  and suggested fixes). This is used by validation flows to provide actionable
//  feedback and to optionally drive canvas highlight overlays.
//

import 'package:flutter/material.dart';

import '../../core/models/validation_diagnostic.dart';

class ValidationDiagnosticCard extends StatelessWidget {
  const ValidationDiagnosticCard({
    super.key,
    required this.diagnostic,
  });

  final ValidationDiagnostic diagnostic;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final fixes = diagnostic.suggestedFixes;

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
                    diagnostic.summary,
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
            if (diagnostic.details != null &&
                diagnostic.details!.trim().isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Text(
                  diagnostic.details!,
                  style: theme.textTheme.bodyMedium,
                ),
              ),
            if (fixes.isNotEmpty) ...[
              const SizedBox(height: 12),
              Text(
                'Suggested fixes',
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
                              fix.label,
                              style: theme.textTheme.bodyMedium?.copyWith(
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            if (fix.details != null &&
                                fix.details!.trim().isNotEmpty)
                              Padding(
                                padding: const EdgeInsets.only(top: 2),
                                child: Text(
                                  fix.details!,
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
                'Code: ${diagnostic.code}',
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
