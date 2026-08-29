import 'package:flutter/material.dart';

import '../../core/models/grammar.dart';
import '../../core/models/grammar_transformation_step.dart';
import '../../core/messages/structured_message.dart';
import '../../l10n/app_localizations_resolver.dart';
import '../../l10n/app_localizations_structured_messages.dart';
import '../../l10n/app_localizations_workflows.dart';
import '../../core/constants/monospace_typography.dart';

/// Renders a list of [GrammarTransformationStep] entries with optional
/// expand/collapse details.
///
/// This is intentionally lightweight: it focuses on showing the operation name,
/// rationale and (expanded) before/after production lists.
class GrammarTransformationHistory extends StatelessWidget {
  const GrammarTransformationHistory({
    super.key,
    required this.steps,
    required this.onApplyGrammar,
    this.structuredMessages = const [],
  });

  final List<GrammarTransformationStep> steps;
  final ValueChanged<Grammar> onApplyGrammar;
  final List<({StructuredMessage operation, StructuredMessage rationale})>
  structuredMessages;

  @override
  Widget build(BuildContext context) {
    if (steps.isEmpty) {
      return const SizedBox.shrink();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          appLocalizationsOf(context).transformationSteps,
          style: Theme.of(
            context,
          ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 8),
        ...steps.asMap().entries.map(
          (entry) => _StepTile(
            index: entry.key,
            step: entry.value,
            structuredMessage: entry.key < structuredMessages.length
                ? structuredMessages[entry.key]
                : null,
            onApplyGrammar: onApplyGrammar,
          ),
        ),
      ],
    );
  }
}

class _StepTile extends StatelessWidget {
  const _StepTile({
    required this.index,
    required this.step,
    this.structuredMessage,
    required this.onApplyGrammar,
  });

  final int index;
  final GrammarTransformationStep step;
  final ({StructuredMessage operation, StructuredMessage rationale})?
  structuredMessage;
  final ValueChanged<Grammar> onApplyGrammar;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final strings = appLocalizationsOf(context);
    final operation = structuredMessage == null
        ? strings.localizeWorkflowText(step.operation)
        : strings.resolveStructuredMessage(structuredMessage!.operation);
    final rationale = structuredMessage == null
        ? strings.localizeWorkflowText(step.rationale)
        : strings.resolveStructuredMessage(structuredMessage!.rationale);

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ExpansionTile(
        tilePadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
        title: Text('${strings.stepNumber(index + 1)}. $operation'),
        subtitle: rationale.trim().isEmpty ? null : Text(rationale),
        childrenPadding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  appLocalizationsOf(context).applyGrammarStep,
                  style: theme.textTheme.bodySmall,
                ),
              ),
              const SizedBox(width: 8),
              OutlinedButton.icon(
                onPressed: () => onApplyGrammar(step.after),
                icon: const Icon(Icons.check),
                label: Text(appLocalizationsOf(context).apply),
              ),
            ],
          ),
          const SizedBox(height: 12),
          _GrammarSnapshot(
            title: appLocalizationsOf(context).before,
            grammar: step.before,
          ),
          const SizedBox(height: 12),
          _GrammarSnapshot(
            title: appLocalizationsOf(context).after,
            grammar: step.after,
          ),
        ],
      ),
    );
  }
}

class _GrammarSnapshot extends StatelessWidget {
  const _GrammarSnapshot({required this.title, required this.grammar});

  final String title;
  final Grammar grammar;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    final productions = grammar.productions.toList()
      ..sort((a, b) => a.order.compareTo(b.order));

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: theme.textTheme.titleSmall),
        const SizedBox(height: 4),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: theme.colorScheme.surfaceContainerHighest,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Text(
            productions.isEmpty
                ? appLocalizationsOf(context).noProductions
                : productions
                      .map(
                        (p) =>
                            '${p.leftSide.join(' ')} → '
                            '${p.isLambda ? 'ε' : p.rightSide.join(' ')}',
                      )
                      .join('\n'),
            style: theme.textTheme.bodySmall?.copyWith(
              fontFamilyFallback: kMonospaceFontFamilyFallback,
            ),
          ),
        ),
      ],
    );
  }
}
