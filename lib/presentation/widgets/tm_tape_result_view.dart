import 'package:flutter/material.dart';

import '../../core/models/tm.dart';
import '../../core/models/tm_execution_analysis.dart';
import '../../l10n/app_localizations_resolver.dart';
import '../../l10n/app_localizations_structured_messages.dart';
import '../../l10n/app_localizations_workflows.dart';
import '../empty_string_notation.dart';
import '../localization/locale_value_formatter.dart';
import 'tm_algorithm_execution_controller.dart';
import 'tm_algorithm_presentation_primitives.dart';

/// Presents typed tape metrics, transition counts, and retained traces.
class TMTapeResultView extends StatelessWidget {
  const TMTapeResultView({
    super.key,
    required this.analysis,
    required this.sourceTm,
  });

  final TMExecutionAnalysis analysis;
  final TM? sourceTm;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final l10n = appLocalizationsOf(context);
    final valueFormatter = LocaleValueFormatter.of(context);
    final analysisMessage = analysis.structuredMessage == null
        ? l10n.localizeWorkflowText(analysis.message)
        : l10n.resolveStructuredMessage(analysis.structuredMessage!);
    final metrics = analysis.traceMetrics;
    if (metrics == null) {
      return buildTMStatusMessage(
        context,
        message: analysisMessage,
        isWarning: true,
      );
    }

    List<String> counts(Map<String, int> values) {
      final entries = values.entries.toList()
        ..sort((left, right) => left.key.compareTo(right.key));
      return [
        for (final entry in entries)
          l10n.tmTapeNamedCount(entry.key, valueFormatter.integer(entry.value)),
      ];
    }

    final branchLabel = switch (metrics.branchSelection) {
      TMExecutionBranchSelection.deterministic =>
        l10n.tmTapeBranchDeterministic,
      TMExecutionBranchSelection.acceptingBranch =>
        l10n.tmTapeBranchAcceptingNtm,
      TMExecutionBranchSelection.rejectingBranch =>
        l10n.tmTapeBranchRejectingNtm,
      TMExecutionBranchSelection.cyclicBranch => l10n.tmTapeBranchCyclicNtm,
      TMExecutionBranchSelection.longestBoundedBranch =>
        l10n.tmTapeBranchLongestBoundedNtm,
    };
    final limitLabel = switch (analysis.limit) {
      TMExecutionLimit.steps => l10n.tmTapeLimitSteps,
      TMExecutionLimit.configurations => l10n.tmTapeLimitConfigurations,
      TMExecutionLimit.timeout => l10n.tmTapeLimitTimeout,
      null => null,
    };
    final diff = metrics.tapeDiff.values.toList()
      ..sort((left, right) => left.position.compareTo(right.position));
    final touches = metrics.cellTouchRanges.entries.toList()
      ..sort((left, right) => left.key.compareTo(right.key));
    final declaredTapeAlphabet = (sourceTm?.tapeAlphabet.toList() ?? <String>[])
      ..sort();

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: colorScheme.outline.withValues(alpha: 0.4)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          buildTMFocusBanner(context, TMAnalysisFocus.tape),
          const SizedBox(height: 12),
          buildTMStatusMessage(
            context,
            message: analysisMessage,
            isPositive: analysis.outcome == TMExecutionOutcome.accepted,
            isWarning:
                analysis.outcome == TMExecutionOutcome.provenCycle ||
                analysis.outcome == TMExecutionOutcome.boundedUnknown,
          ),
          const SizedBox(height: 8),
          buildTMMetricRow(
            context,
            l10n.tmTapeInputLabel,
            analysis.input.isEmpty
                ? EmptyStringNotation.symbolOf(context)
                : analysis.input,
          ),
          buildTMMetricRow(
            context,
            l10n.tmTapeSelectedBranchLabel,
            branchLabel,
          ),
          buildTMMetricRow(
            context,
            l10n.tmTapeConclusionLabel,
            analysis.isExact
                ? l10n.tmTapeConclusionExact
                : l10n.tmTapeConclusionBounded,
          ),
          buildTMMetricRow(
            context,
            l10n.tmTapeExecutedTransitionsLabel,
            valueFormatter.integer(analysis.stepsExecuted),
          ),
          buildTMMetricRow(
            context,
            l10n.tmTapeConfigurationsExploredLabel,
            valueFormatter.integer(analysis.configurationsExplored),
          ),
          buildTMMetricRow(
            context,
            l10n.tmTapeStepLimitLabel,
            valueFormatter.integer(analysis.maxSteps),
          ),
          buildTMMetricRow(
            context,
            l10n.tmTapeConfigurationLimitLabel,
            valueFormatter.integer(analysis.maxConfigurations),
          ),
          buildTMMetricRow(
            context,
            l10n.tmTapeTimeLimitLabel,
            l10n.tmTapeDurationSeconds(
              valueFormatter.integer(analysis.timeout.inSeconds),
            ),
          ),
          if (limitLabel != null)
            buildTMMetricRow(
              context,
              l10n.tmTapeLimitReachedLabel,
              limitLabel,
              isWarning: true,
            ),
          buildTMMetricRow(
            context,
            l10n.tmTapeChangedWritesLabel,
            valueFormatter.integer(metrics.changedWrites),
          ),
          buildTMMetricRow(
            context,
            l10n.tmTapeHeadReversalsLabel,
            valueFormatter.integer(metrics.headReversals),
          ),
          buildTMMetricRow(
            context,
            l10n.tmTapeVisitedHeadIntervalLabel,
            l10n.tmTapeHeadInterval(
              valueFormatter.integer(metrics.minimumHeadPosition),
              valueFormatter.integer(metrics.maximumHeadPosition),
            ),
          ),
          buildTMMetricRow(
            context,
            l10n.tmTapeDistinctCellsVisitedLabel,
            valueFormatter.integer(metrics.distinctCellsVisited),
          ),
          buildTMMetricRow(
            context,
            l10n.tmTapeMaximumNonblankLabel,
            valueFormatter.integer(metrics.maximumSimultaneousNonBlankCells),
          ),
          const SizedBox(height: 8),
          buildTMChipList(
            context,
            label: l10n.tmTapeDeclaredAlphabetLabel,
            values: declaredTapeAlphabet,
          ),
          buildTMChipList(
            context,
            label: l10n.tmTapeReadsBySymbolLabel,
            values: counts(metrics.readCounts),
          ),
          buildTMChipList(
            context,
            label: l10n.tmTapeWritesByOldSymbolLabel,
            values: counts(metrics.writeCountsByOldSymbol),
          ),
          buildTMChipList(
            context,
            label: l10n.tmTapeWritesByNewSymbolLabel,
            values: counts(metrics.writeCountsByNewSymbol),
          ),
          buildTMChipList(
            context,
            label: l10n.tmTapeHeadMovementsLabel,
            values: counts(metrics.movementCounts),
          ),
          buildTMChipList(
            context,
            label: l10n.tmTapeTransitionCountsLabel,
            values: counts(metrics.transitionExecutionCounts),
          ),
          buildTMChipList(
            context,
            label: l10n.tmTapeUnexecutedTransitionsLabel,
            values: metrics.definedButNotExecutedTransitionIds.toList()..sort(),
            isWarning: metrics.definedButNotExecutedTransitionIds.isNotEmpty,
          ),
          buildTMChipList(
            context,
            label: l10n.tmTapeSparseDiffLabel,
            values: [
              for (final change in diff)
                l10n.tmTapeCellDiff(
                  valueFormatter.integer(change.position),
                  change.initialSymbol,
                  change.finalSymbol,
                ),
            ],
          ),
          buildTMChipList(
            context,
            label: l10n.tmTapeCellTouchRangeLabel,
            values: [
              for (final entry in touches)
                l10n.tmTapeCellTouchRange(
                  valueFormatter.integer(entry.key),
                  valueFormatter.integer(entry.value.firstStep),
                  valueFormatter.integer(entry.value.lastStep),
                ),
            ],
          ),
          if (analysis.trace.isNotEmpty) ...[
            const SizedBox(height: 8),
            Material(
              color: Colors.transparent,
              child: ExpansionTile(
                key: const Key('tm-tape-related-trace'),
                tilePadding: EdgeInsets.zero,
                title: Text(appLocalizationsOf(context).relatedExecutionTrace),
                subtitle: Text(
                  localizeTMInteger(
                    valueFormatter,
                    appLocalizationsOf(context).retainedConfigurations,
                    analysis.trace.length,
                  ),
                ),
                children: [
                  SizedBox(
                    height: 260,
                    child: ListView.builder(
                      itemCount: analysis.trace.length,
                      itemBuilder: (context, index) {
                        final step = analysis.trace[index];
                        return ListTile(
                          dense: true,
                          title: Text(
                            localizeTMInteger(
                              valueFormatter,
                              (marker) => appLocalizationsOf(
                                context,
                              ).stepStateTitle(marker, step.currentState),
                              step.stepNumber,
                            ),
                          ),
                          subtitle: Text(
                            l10n.tmTapeTraceSubtitle(
                              step.usedTransition ?? l10n.initialConfiguration,
                              localizeTMInteger(
                                valueFormatter,
                                (marker) => l10n.headTapeSubtitle(
                                  marker,
                                  step.tapeContents.isEmpty
                                      ? '∅'
                                      : step.tapeContents,
                                ),
                                step.headPosition ?? 0,
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}
