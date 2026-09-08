import 'package:flutter/material.dart';

import '../../empty_string_notation.dart';

import '../../../core/models/grammar.dart';
import '../../../core/models/grammar_transformation_step.dart';
import '../../../core/messages/structured_message.dart';
import '../../../l10n/app_localizations_resolver.dart';
import '../../../l10n/app_localizations_structured_messages.dart';
import '../../../l10n/app_localizations_workflows.dart';
import '../../../core/constants/monospace_typography.dart';

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

    final strings = appLocalizationsOf(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Only the count is announced when the history changes, so screen
        // readers hear that new steps arrived without re-reading every step.
        Semantics(
          liveRegion: true,
          label: strings.transformationStepsSummary(steps.length),
          excludeSemantics: true,
          child: Text(
            strings.transformationSteps,
            style: Theme.of(
              context,
            ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
          ),
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

class _StepTile extends StatefulWidget {
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
  State<_StepTile> createState() => _StepTileState();
}

class _StepTileState extends State<_StepTile> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final strings = appLocalizationsOf(context);
    final step = widget.step;
    final structuredMessage = widget.structuredMessage;
    final operation = structuredMessage == null
        ? strings.localizeWorkflowText(step.operation)
        : strings.resolveStructuredMessage(structuredMessage.operation);
    final rationale = structuredMessage == null
        ? strings.localizeWorkflowText(step.rationale)
        : strings.resolveStructuredMessage(structuredMessage.rationale);
    final stepNumber = widget.index + 1;

    // ExpansionTile announces Collapsed/Expanded on its own but exposes no
    // expanded-state flag, so the flag is added here for assistive technology
    // that reports state rather than reading the announcement.
    return Card(
      key: ValueKey('grammar-transformation-step-${step.id}'),
      margin: const EdgeInsets.only(bottom: 8),
      child: Semantics(
        expanded: _expanded,
        child: ExpansionTile(
          tilePadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
          title: Text('${strings.stepNumber(stepNumber)}. $operation'),
          subtitle: rationale.trim().isEmpty ? null : Text(rationale),
          childrenPadding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
          onExpansionChanged: (expanded) =>
              setState(() => _expanded = expanded),
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    strings.applyGrammarStep,
                    style: theme.textTheme.bodySmall,
                  ),
                ),
                const SizedBox(width: 8),
                Semantics(
                  label: strings.applyGrammarStepSemantics(
                    stepNumber,
                    operation,
                  ),
                  excludeSemantics: true,
                  button: true,
                  onTap: () => widget.onApplyGrammar(step.after),
                  child: OutlinedButton.icon(
                    key: ValueKey('apply-grammar-step-${step.id}'),
                    onPressed: () => widget.onApplyGrammar(step.after),
                    icon: const Icon(Icons.check),
                    label: Text(strings.apply),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            _GrammarSnapshot(title: strings.before, grammar: step.before),
            const SizedBox(height: 12),
            _GrammarSnapshot(title: strings.after, grammar: step.after),
          ],
        ),
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

    // Title and productions are read as one item ("Before: S → a ...") so
    // the relation between the snapshot and its heading is never lost.
    return MergeSemantics(
      child: Column(
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
                              '${p.isLambda || p.rightSide.isEmpty ? EmptyStringNotation.symbolOf(context) : p.rightSide.join(' ')}',
                        )
                        .join('\n'),
              style: theme.textTheme.bodySmall?.copyWith(
                fontFamilyFallback: kMonospaceFontFamilyFallback,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
