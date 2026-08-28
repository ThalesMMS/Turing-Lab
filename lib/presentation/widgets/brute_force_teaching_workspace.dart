import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../core/constants/monospace_typography.dart';
import '../../core/grammar/teaching/grammar_teaching_content.dart';
import '../../core/models/brute_force_parse_models.dart';
import '../../l10n/app_localizations.dart';
import '../../l10n/app_localizations_resolver.dart';
import '../../l10n/app_localizations_workflows.dart';
import '../content/grammar_teaching_content_copy.dart';
import '../localization/locale_value_formatter.dart';
import 'derivation_tree_view.dart';

class BruteForceTeachingWorkspace extends StatefulWidget {
  const BruteForceTeachingWorkspace({super.key, required this.result});

  final BruteForceParseResult result;
  static final contentReference = GrammarTeachingContent.bruteForceSearch;

  @override
  State<BruteForceTeachingWorkspace> createState() =>
      _BruteForceTeachingWorkspaceState();
}

class _BruteForceTeachingWorkspaceState
    extends State<BruteForceTeachingWorkspace> {
  int _witnessIndex = 0;
  int _stepIndex = 0;

  @override
  void didUpdateWidget(BruteForceTeachingWorkspace oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!identical(oldWidget.result, widget.result)) {
      _witnessIndex = 0;
      _stepIndex = 0;
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = appLocalizationsOf(context);
    final result = widget.result;
    final statistics = result.statistics;
    final witness = result.witnesses.isEmpty
        ? null
        : result.witnesses[_witnessIndex.clamp(0, result.witnesses.length - 1)];
    final content = GrammarTeachingContentCopies.resolve(
      reference: BruteForceTeachingWorkspace.contentReference,
      languageCode: Localizations.localeOf(context).languageCode,
      arguments: {
        'limits': result.limit?.name,
        'witness': witness?.depth,
        'prunedCounts': {
          for (final entry in statistics.prunedByReason.entries)
            entry.key.name: entry.value,
        },
      },
    );

    return Semantics(
      container: true,
      label: content.title,
      hint: content.accessibleDescription,
      child: Card.outlined(
        key: const ValueKey('brute-force-teaching-workspace'),
        margin: EdgeInsets.zero,
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Text(
                      content.title,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  IconButton(
                    tooltip: l10n.localizeWorkflowText('Copy JSON report'),
                    onPressed: () => _copyReport(context),
                    icon: const Icon(Icons.copy),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Text(content.instruction),
              const SizedBox(height: 8),
              _StatisticsGrid(result: result),
              if (statistics.prunedByReason.isNotEmpty) ...[
                const SizedBox(height: 12),
                Text(
                  l10n.localizeWorkflowText('Pruned by reason'),
                  style: Theme.of(
                    context,
                  ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 6),
                Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: statistics.prunedByReason.entries
                      .where((entry) => entry.value > 0)
                      .map(
                        (entry) => Chip(
                          visualDensity: VisualDensity.compact,
                          label: Text(
                            '${l10n.localizeWorkflowText(_pruneReasonLabel(entry.key))}: '
                            '${LocaleValueFormatter.of(context).integer(entry.value)}',
                          ),
                        ),
                      )
                      .toList(growable: false),
                ),
              ],
              if (witness != null) ...[
                const SizedBox(height: 16),
                if (result.witnesses.length > 1)
                  DropdownButtonFormField<int>(
                    key: const ValueKey('brute-force-witness-selector'),
                    initialValue: _witnessIndex,
                    isExpanded: true,
                    decoration: InputDecoration(
                      border: const OutlineInputBorder(),
                      labelText: l10n.localizeWorkflowText(
                        'Derivation witness',
                      ),
                    ),
                    items: List.generate(
                      result.witnesses.length,
                      (index) => DropdownMenuItem(
                        value: index,
                        child: Text(
                          _witnessLabel(
                            l10n,
                            LocaleValueFormatter.of(context),
                            index,
                            result.witnesses[index].depth,
                          ),
                        ),
                      ),
                    ),
                    onChanged: (value) {
                      if (value == null) return;
                      setState(() {
                        _witnessIndex = value;
                        _stepIndex = 0;
                      });
                    },
                  ),
                if (result.witnesses.length > 1) const SizedBox(height: 12),
                _DerivationStepper(
                  witness: witness,
                  stepIndex: _stepIndex,
                  onChanged: (value) => setState(() => _stepIndex = value),
                ),
                const SizedBox(height: 12),
                Material(
                  type: MaterialType.transparency,
                  child: ExpansionTile(
                    tilePadding: EdgeInsets.zero,
                    title: Text(
                      l10n.localizeWorkflowText('Selected derivation tree'),
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    children: [
                      DerivationTreeView(
                        tree: witness.tree,
                        initiallyExpanded: true,
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _copyReport(BuildContext context) async {
    await Clipboard.setData(
      ClipboardData(
        text: const JsonEncoder.withIndent(
          '  ',
        ).convert(widget.result.toJson()),
      ),
    );
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          appLocalizationsOf(
            context,
          ).localizeWorkflowText('Structured report copied'),
        ),
      ),
    );
  }
}

class _StatisticsGrid extends StatelessWidget {
  const _StatisticsGrid({required this.result});

  final BruteForceParseResult result;

  @override
  Widget build(BuildContext context) {
    final l10n = appLocalizationsOf(context);
    final formatter = LocaleValueFormatter.of(context);
    final stats = result.statistics;
    final values = <(String, String)>[
      ('Explored', formatter.integer(stats.exploredNodes)),
      ('Generated', formatter.integer(stats.generatedNodes)),
      (
        'Frontier / peak',
        '${formatter.integer(stats.frontierSize)} / ${formatter.integer(stats.frontierPeak)}',
      ),
      ('Depth', formatter.integer(stats.currentDepth)),
      ('Pruned', formatter.integer(stats.prunedNodes)),
      ('Witnesses', formatter.integer(result.witnessCount)),
      ('Elapsed', _formatDuration(formatter, stats.executionTime)),
      if (result.limit != null)
        (
          'Reached limit',
          l10n.localizeWorkflowText(_searchLimitLabel(result.limit!)),
        ),
    ];
    return LayoutBuilder(
      builder: (context, constraints) {
        final columns = constraints.maxWidth >= 720
            ? 4
            : constraints.maxWidth >= 400
            ? 2
            : 1;
        final width = (constraints.maxWidth - ((columns - 1) * 8)) / columns;
        return Wrap(
          spacing: 8,
          runSpacing: 8,
          children: values
              .map(
                (value) => SizedBox(
                  width: width,
                  child: Semantics(
                    label:
                        '${l10n.localizeWorkflowText(value.$1)}: ${value.$2}',
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        color: Theme.of(
                          context,
                        ).colorScheme.surfaceContainerHighest,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(8),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              l10n.localizeWorkflowText(value.$1),
                              style: Theme.of(context).textTheme.labelSmall,
                            ),
                            Text(
                              value.$2,
                              style: Theme.of(context).textTheme.titleSmall
                                  ?.copyWith(fontWeight: FontWeight.w700),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              )
              .toList(growable: false),
        );
      },
    );
  }

  static String _formatDuration(
    LocaleValueFormatter formatter,
    Duration duration,
  ) {
    if (duration.inMilliseconds < 1) {
      return '${formatter.integer(duration.inMicroseconds)} μs';
    }
    if (duration.inSeconds < 1) {
      return '${formatter.integer(duration.inMilliseconds)} ms';
    }
    return '${formatter.decimal(duration.inMilliseconds / 1000)} s';
  }
}

class _DerivationStepper extends StatelessWidget {
  const _DerivationStepper({
    required this.witness,
    required this.stepIndex,
    required this.onChanged,
  });

  final BruteForceDerivationWitness witness;
  final int stepIndex;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) {
    final l10n = appLocalizationsOf(context);
    final formatter = LocaleValueFormatter.of(context);
    if (witness.steps.isEmpty) {
      return Text(
        l10n.localizeWorkflowText('The start symbol is the witness.'),
      );
    }
    final step = witness.steps[stepIndex];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            IconButton(
              tooltip: l10n.localizeWorkflowText('Previous derivation step'),
              onPressed: stepIndex == 0 ? null : () => onChanged(stepIndex - 1),
              icon: const Icon(Icons.chevron_left),
            ),
            Expanded(
              child: Text(
                l10n.localizeWorkflowText(
                  'Step ${formatter.integer(stepIndex + 1)} of '
                  '${formatter.integer(witness.steps.length)} • '
                  'production ${step.productionId}',
                ),
                textAlign: TextAlign.center,
                style: Theme.of(
                  context,
                ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600),
              ),
            ),
            IconButton(
              tooltip: l10n.localizeWorkflowText('Next derivation step'),
              onPressed: stepIndex == witness.steps.length - 1
                  ? null
                  : () => onChanged(stepIndex + 1),
              icon: const Icon(Icons.chevron_right),
            ),
            IconButton(
              tooltip: l10n.localizeWorkflowText('Reset derivation'),
              onPressed: stepIndex == 0 ? null : () => onChanged(0),
              icon: const Icon(Icons.replay),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Text(
          l10n.localizeWorkflowText('Before'),
          style: Theme.of(context).textTheme.labelMedium,
        ),
        const SizedBox(height: 4),
        _SententialForm(
          symbols: step.before,
          highlightedIndex: step.occurrenceIndex,
        ),
        const SizedBox(height: 8),
        Text(
          l10n.localizeWorkflowText('After'),
          style: Theme.of(context).textTheme.labelMedium,
        ),
        const SizedBox(height: 4),
        _SententialForm(symbols: step.after),
      ],
    );
  }
}

String _witnessLabel(
  AppLocalizations l10n,
  LocaleValueFormatter formatter,
  int index,
  int depth,
) => l10n.localizeWorkflowText(
  'Witness ${formatter.integer(index + 1)} • '
  '${formatter.integer(depth)} steps',
);

String _searchLimitLabel(BruteForceSearchLimit limit) => switch (limit) {
  BruteForceSearchLimit.depth => 'depth',
  BruteForceSearchLimit.frontier => 'frontier',
  BruteForceSearchLimit.exploredNodes => 'explored nodes',
  BruteForceSearchLimit.retainedStates => 'retained states',
  BruteForceSearchLimit.symbolCount => 'symbol count',
  BruteForceSearchLimit.time => 'time',
};

String _pruneReasonLabel(BruteForcePruneReason reason) => switch (reason) {
  BruteForcePruneReason.terminalCount => 'terminal count',
  BruteForcePruneReason.terminalPrefix => 'terminal prefix',
  BruteForcePruneReason.terminalSuffix => 'terminal suffix',
  BruteForcePruneReason.terminalSubsequence => 'terminal subsequence',
  BruteForcePruneReason.minimumYield => 'minimum yield',
  BruteForcePruneReason.duplicateWitness => 'duplicate witness',
};

class _SententialForm extends StatelessWidget {
  const _SententialForm({required this.symbols, this.highlightedIndex});

  final List<String> symbols;
  final int? highlightedIndex;

  @override
  Widget build(BuildContext context) {
    final display = symbols.isEmpty ? const ['ε'] : symbols;
    return Wrap(
      spacing: 4,
      runSpacing: 4,
      children: List.generate(
        display.length,
        (index) => Chip(
          backgroundColor: index == highlightedIndex
              ? Theme.of(context).colorScheme.primaryContainer
              : null,
          label: Text(
            display[index],
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              fontFamilyFallback: kMonospaceFontFamilyFallback,
              fontWeight: index == highlightedIndex ? FontWeight.w700 : null,
            ),
          ),
        ),
      ),
    );
  }
}
