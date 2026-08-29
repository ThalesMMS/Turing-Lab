import 'package:flutter/material.dart';

import '../../../core/models/tm_execution_analysis.dart';
import '../../../core/models/tm_transition.dart';
import '../../../l10n/app_localizations.dart';
import '../../../l10n/app_localizations_resolver.dart';
import '../../localization/locale_value_formatter.dart';

/// Bounded, lazy presentation of one synchronized multi-tape execution trace.
class TMMultiTapeInspector extends StatefulWidget {
  const TMMultiTapeInspector({
    super.key,
    required this.analysis,
    required this.blankSymbol,
  });

  final TMExecutionAnalysis analysis;
  final String blankSymbol;

  @override
  State<TMMultiTapeInspector> createState() => _TMMultiTapeInspectorState();
}

class _TMMultiTapeInspectorState extends State<TMMultiTapeInspector> {
  int _selectedIndex = 0;

  @override
  void didUpdateWidget(covariant TMMultiTapeInspector oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!identical(oldWidget.analysis, widget.analysis)) {
      _selectedIndex = 0;
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = appLocalizationsOf(context);
    final formatter = LocaleValueFormatter.of(context);
    final trace = widget.analysis.multiTapeTrace;
    final selected = trace.isEmpty
        ? null
        : trace[_selectedIndex.clamp(0, trace.length - 1)];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const SizedBox(height: 12),
        Semantics(
          header: true,
          child: Text(
            l10n.tmMultiTapeTraceTitle,
            style: Theme.of(context).textTheme.titleMedium,
          ),
        ),
        const SizedBox(height: 8),
        _MetricsSummary(analysis: widget.analysis, formatter: formatter),
        if (trace.isEmpty)
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Text(l10n.tmMultiTapeNoTransition),
          )
        else ...[
          const SizedBox(height: 8),
          SizedBox(
            height: 176,
            child: ListView.builder(
              key: const Key('tm-multi-tape-trace-list'),
              itemCount: trace.length,
              itemBuilder: (context, index) {
                final step = trace[index];
                return Material(
                  type: MaterialType.transparency,
                  child: ListTile(
                    selected: index == _selectedIndex,
                    title: Text(
                      formatter.inLocalizedTemplate(
                        (value) => l10n.tmMultiTapeStep(
                          value,
                          step.fromStateId,
                          step.toStateId,
                        ),
                        step.step,
                      ),
                    ),
                    subtitle: Text(
                      formatter.inLocalizedTemplate(
                        (value) => l10n.tmMultiTapeAtomicTransition(
                          step.transitionId,
                          value,
                        ),
                        step.readSymbols.length,
                      ),
                    ),
                    onTap: () => setState(() => _selectedIndex = index),
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 8),
          _SelectedConfiguration(
            step: selected!,
            blankSymbol: widget.blankSymbol,
            formatter: formatter,
          ),
        ],
      ],
    );
  }
}

class _MetricsSummary extends StatelessWidget {
  const _MetricsSummary({required this.analysis, required this.formatter});

  final TMExecutionAnalysis analysis;
  final LocaleValueFormatter formatter;

  @override
  Widget build(BuildContext context) {
    final l10n = appLocalizationsOf(context);
    final metrics = analysis.multiTapeMetrics;
    if (metrics == null) return const SizedBox.shrink();
    return Semantics(
      label: l10n.tmMultiTapeSpaceMetricsSemantic,
      child: Card.outlined(
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(l10n.tmMultiTapeSpaceMetricsExplanation),
              const SizedBox(height: 4),
              for (
                var tape = 0;
                tape < metrics.maximumVisitedSpanByTape.length;
                tape++
              )
                Text(_localizedTapeMetrics(l10n, formatter, tape, metrics)),
              Text(
                formatter.inLocalizedTemplate(
                  l10n.tmMultiTapeTotalNonblank,
                  metrics.maximumTotalNonBlankCells,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _localizedTapeMetrics(
    AppLocalizations l10n,
    LocaleValueFormatter formatter,
    int tape,
    TMMultiTapeMetrics metrics,
  ) {
    return formatter.inLocalizedTemplate(
      (span) => formatter.inLocalizedTemplate(
        (nonBlank) => l10n.tmMultiTapeMetrics(tape + 1, span, nonBlank),
        metrics.maximumNonBlankCellsByTape[tape],
      ),
      metrics.maximumVisitedSpanByTape[tape],
    );
  }
}

class _SelectedConfiguration extends StatelessWidget {
  const _SelectedConfiguration({
    required this.step,
    required this.blankSymbol,
    required this.formatter,
  });

  final TMMultiTapeTraceStep step;
  final String blankSymbol;
  final LocaleValueFormatter formatter;

  @override
  Widget build(BuildContext context) {
    final l10n = appLocalizationsOf(context);
    return ConstrainedBox(
      constraints: const BoxConstraints(maxHeight: 420),
      child: ListView.builder(
        key: const Key('tm-multi-tape-inspector'),
        shrinkWrap: true,
        itemCount: step.configuration.headPositions.length,
        itemBuilder: (context, tape) {
          final head = step.configuration.headPositions[tape];
          final cells = step.configuration.nonBlankCellsByTape[tape];
          final operation =
              '${step.readSymbols[tape]} → '
              '${step.writeSymbols[tape]}, ${step.directions[tape].symbol}';
          return Semantics(
            label: formatter.inLocalizedTemplate(
              (value) => l10n.tmMultiTapeConfigurationSemantic(
                tape + 1,
                value,
                operation,
              ),
              head,
            ),
            child: Material(
              type: MaterialType.transparency,
              child: ExpansionTile(
                key: ValueKey('tm-multi-tape-$tape'),
                initiallyExpanded:
                    step.configuration.headPositions.length <= 2 || tape == 0,
                title: Text(
                  formatter.inLocalizedTemplate(
                    l10n.tmMultiTapeTitle,
                    tape + 1,
                  ),
                ),
                subtitle: Text(
                  formatter.inLocalizedTemplate(
                    (value) => l10n.tmMultiTapeHeadSummary(value, operation),
                    head,
                  ),
                ),
                children: [
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
                    child: Row(
                      children: [
                        for (
                          var position = head - 3;
                          position <= head + 3;
                          position++
                        )
                          _TapeCell(
                            position: position,
                            symbol: cells[position] ?? blankSymbol,
                            active: position == head,
                            formatter: formatter,
                          ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

class _TapeCell extends StatelessWidget {
  const _TapeCell({
    required this.position,
    required this.symbol,
    required this.active,
    required this.formatter,
  });

  final int position;
  final String symbol;
  final bool active;
  final LocaleValueFormatter formatter;

  @override
  Widget build(BuildContext context) {
    final l10n = appLocalizationsOf(context);
    final colors = Theme.of(context).colorScheme;
    return Semantics(
      label: formatter.inLocalizedTemplate(
        active
            ? (value) => l10n.tmMultiTapeHeadCellSemantic(value, symbol)
            : (value) => l10n.tmMultiTapeCellSemantic(value, symbol),
        position,
      ),
      child: Container(
        width: 52,
        constraints: const BoxConstraints(minHeight: 52),
        margin: const EdgeInsets.symmetric(horizontal: 2),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: active ? colors.primaryContainer : colors.surfaceContainer,
          border: Border.all(
            color: active ? colors.primary : colors.outlineVariant,
            width: active ? 2 : 1,
          ),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(symbol),
            Text(
              formatter.inLocalizedTemplate(l10n.tmMultiTapePosition, position),
              style: Theme.of(context).textTheme.labelSmall,
            ),
          ],
        ),
      ),
    );
  }
}
