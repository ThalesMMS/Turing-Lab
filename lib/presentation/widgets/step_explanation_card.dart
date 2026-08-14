//
//  step_explanation_card.dart
//  Turing Lab
//
//  Reusable panel for rendering a structured StepExplanation attached to a
//  simulation/conversion step.
//
import 'package:flutter/material.dart';

import '../../core/models/step_explanation.dart';
import '../../l10n/app_localizations_resolver.dart';
import '../../l10n/app_localizations_workflows.dart';

class StepExplanationCard extends StatelessWidget {
  final StepExplanation? explanation;
  final String? fallbackText;
  final String titleWhenEmpty;

  const StepExplanationCard({
    super.key,
    required this.explanation,
    this.fallbackText,
    this.titleWhenEmpty = 'Explanation',
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final l10n = appLocalizationsOf(context);

    final title = explanation?.title?.trim().isNotEmpty == true
        ? explanation!.title!.trim()
        : titleWhenEmpty;

    final bullets = explanation?.bullets ?? const <String>[];
    final suggestedFixes =
        explanation?.suggestedFixes ?? const <SuggestedFix>[];

    final hasBullets = bullets.isNotEmpty;
    final hasFixes = suggestedFixes.isNotEmpty;
    final hasFallback = (fallbackText?.trim().isNotEmpty ?? false);

    if (!hasBullets && !hasFixes && !hasFallback) {
      return const SizedBox.shrink();
    }

    return Card(
      elevation: 0,
      color: scheme.surfaceContainerHighest,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.info_outline, size: 18, color: scheme.primary),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    l10n.localizeWorkflowText(title),
                    style: theme.textTheme.titleSmall
                        ?.copyWith(fontWeight: FontWeight.w700),
                  ),
                ),
              ],
            ),
            if (hasFallback) ...[
              const SizedBox(height: 8),
              Text(
                l10n.localizeWorkflowText(fallbackText!.trim()),
                style: theme.textTheme.bodyMedium,
              ),
            ],
            if (hasBullets) ...[
              const SizedBox(height: 10),
              ...bullets.map(
                (bullet) => Padding(
                  padding: const EdgeInsets.only(bottom: 6),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Padding(
                        padding: const EdgeInsets.only(top: 3),
                        child: Icon(
                          Icons.circle,
                          size: 7,
                          color: scheme.onSurface.withValues(alpha: 0.6),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          l10n.localizeWorkflowText(bullet),
                          style: theme.textTheme.bodyMedium,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
            if (hasFixes) ...[
              const SizedBox(height: 6),
              Divider(height: 16, color: scheme.outline.withValues(alpha: 0.2)),
              Text(
                l10n.suggestedFixes,
                style: theme.textTheme.labelLarge
                    ?.copyWith(fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 6),
              ...suggestedFixes.map(
                (fix) => Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: _SuggestedFixRow(fix: fix),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _SuggestedFixRow extends StatelessWidget {
  final SuggestedFix fix;

  const _SuggestedFixRow({required this.fix});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final l10n = appLocalizationsOf(context);

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(Icons.lightbulb_outline, size: 18, color: scheme.tertiary),
        const SizedBox(width: 8),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                l10n.localizeWorkflowText(fix.label),
                style: theme.textTheme.bodyMedium
                    ?.copyWith(fontWeight: FontWeight.w600),
              ),
              if (fix.details?.trim().isNotEmpty == true)
                Padding(
                  padding: const EdgeInsets.only(top: 2),
                  child: Text(
                    l10n.localizeWorkflowText(fix.details!.trim()),
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: scheme.onSurface.withValues(alpha: 0.7),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }
}
