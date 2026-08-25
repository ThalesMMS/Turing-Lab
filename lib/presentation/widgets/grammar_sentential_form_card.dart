//
//  grammar_sentential_form_card.dart
//  Turing Lab
//
//  Lightweight UI helper to render a before/after sentential form comparison
//  for a selected grammar parsing step.
//

import 'package:flutter/material.dart';
import 'package:collection/collection.dart';

import '../../core/models/step_explanation.dart';
import '../../l10n/app_localizations_resolver.dart';
import '../../core/constants/monospace_typography.dart';

class GrammarSententialFormCard extends StatelessWidget {
  final StepExplanation explanation;

  const GrammarSententialFormCard({
    super.key,
    required this.explanation,
  });

  @override
  Widget build(BuildContext context) {
    final target = explanation.highlights
        .where((h) => h.type == HighlightTargetType.sententialFormSpan)
        .firstOrNull;

    if (target == null) {
      return const SizedBox.shrink();
    }

    final before = target.data['before'] as String?;
    final after = target.data['after'] as String?;
    final start = _highlightIndex(target.data['start']);
    final end = _highlightIndex(target.data['end']);

    if (before == null || after == null || start == null || end == null) {
      return const SizedBox.shrink();
    }

    final colorScheme = Theme.of(context).colorScheme;

    return Card(
      elevation: 0,
      color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.35),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.compare_arrows,
                    size: 18, color: colorScheme.primary),
                const SizedBox(width: 8),
                Text(
                  appLocalizationsOf(context).beforeAfter,
                  style: Theme.of(context)
                      .textTheme
                      .titleSmall
                      ?.copyWith(fontWeight: FontWeight.w700),
                ),
              ],
            ),
            const SizedBox(height: 10),
            _buildLabeledForm(
              context,
              label: appLocalizationsOf(context).before,
              text: before,
              highlightStart: start,
              highlightEnd: end,
              highlightColor: colorScheme.primaryContainer,
            ),
            const SizedBox(height: 10),
            _buildLabeledForm(
              context,
              label: appLocalizationsOf(context).after,
              text: after,
              highlightStart: start,
              highlightEnd: end,
              highlightColor: colorScheme.tertiaryContainer,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLabeledForm(
    BuildContext context, {
    required String label,
    required String text,
    required int highlightStart,
    required int highlightEnd,
    required Color highlightColor,
  }) {
    final safeStart = highlightStart.clamp(0, text.length);
    final safeEnd = highlightEnd.clamp(safeStart, text.length);

    final prefix = text.substring(0, safeStart);
    final mid = text.substring(safeStart, safeEnd);
    final suffix = text.substring(safeEnd);

    final baseStyle = Theme.of(context).textTheme.bodyMedium?.copyWith(
        fontFamilyFallback: kMonospaceFontFamilyFallback, height: 1.4);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: Theme.of(context)
              .textTheme
              .labelMedium
              ?.copyWith(fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 4),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surface.withValues(alpha: 0.7),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color:
                  Theme.of(context).colorScheme.outline.withValues(alpha: 0.2),
            ),
          ),
          child: Text.rich(
            TextSpan(
              children: [
                TextSpan(text: prefix, style: baseStyle),
                TextSpan(
                  text: mid.isEmpty ? ' ' : mid,
                  style: baseStyle?.copyWith(
                    backgroundColor: highlightColor,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                TextSpan(text: suffix, style: baseStyle),
              ],
            ),
          ),
        ),
      ],
    );
  }

  int? _highlightIndex(Object? value) {
    if (value is int) return value;
    if (value is double &&
        value.isFinite &&
        value == value.truncateToDouble()) {
      return value.toInt();
    }
    return null;
  }
}
