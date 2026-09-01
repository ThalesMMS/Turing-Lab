import 'package:flutter/material.dart';

import '../../core/models/tm_time_profile.dart';
import '../../l10n/app_localizations_resolver.dart';
import '../../l10n/app_localizations_structured_messages.dart';
import '../../l10n/app_localizations_workflows.dart';
import '../empty_string_notation.dart';
import '../localization/locale_value_formatter.dart';
import 'tm_algorithm_execution_controller.dart';
import 'tm_algorithm_presentation_primitives.dart';

/// Presents deterministic cost rows or nondeterministic exploration metrics.
class TMTimeResultView extends StatelessWidget {
  const TMTimeResultView({super.key, required this.report});

  final TMTimeProfileReport report;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final l10n = appLocalizationsOf(context);
    final valueFormatter = LocaleValueFormatter.of(context);
    final incomplete =
        report.status == TMTimeProfileStatus.incomplete ||
        report.status == TMTimeProfileStatus.cancelled;
    final invalid = report.status == TMTimeProfileStatus.invalid;
    final kindLabel = report.kind == TMTimeProfileKind.deterministicTime
        ? 'DTM transition-step profile'
        : 'NTM exploration metrics (not deterministic time)';
    final alphabet = report.plan.alphabet.isEmpty
        ? '∅'
        : report.plan.alphabet.join(', ');
    final reportMessage = report.structuredMessage == null
        ? l10n.localizeWorkflowText(report.message)
        : l10n.resolveStructuredMessage(report.structuredMessage!);

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
          buildTMFocusBanner(context, TMAnalysisFocus.time),
          const SizedBox(height: 12),
          buildTMStatusMessage(
            context,
            message: reportMessage,
            isPositive: report.isComplete,
            isWarning: incomplete || invalid,
          ),
          const SizedBox(height: 8),
          buildTMMetricRow(
            context,
            'Profile kind',
            l10n.localizeWorkflowText(kindLabel),
          ),
          buildTMMetricRow(context, 'Input alphabet', alphabet),
          buildTMMetricRow(
            context,
            'Input lengths',
            '${valueFormatter.integer(0)}…${valueFormatter.integer(report.plan.bounds.maxLength)}',
          ),
          buildTMMetricRow(
            context,
            'Planned candidates',
            valueFormatter.integer(report.plan.plannedCandidateCount),
          ),
          buildTMMetricRow(
            context,
            'Transition-step budget per candidate',
            valueFormatter.integer(report.plan.bounds.maxStepsPerCandidate),
          ),
          buildTMMetricRow(
            context,
            'Configuration budget per candidate',
            valueFormatter.integer(
              report.plan.bounds.maxConfigurationsPerCandidate,
            ),
          ),
          buildTMMetricRow(
            context,
            'Time budget per candidate',
            '${valueFormatter.integer(report.plan.bounds.timeoutPerCandidate.inSeconds)} s',
          ),
          buildTMMetricRow(
            context,
            'Profiler device wall-clock (diagnostic)',
            formatTMAnalysisDuration(context, report.profilingWallClockTime),
          ),
          const SizedBox(height: 8),
          buildTMStatusMessage(
            context,
            message:
                'Observed bounded measurements only; no Big-O class is inferred.',
          ),
          const SizedBox(height: 12),
          for (var index = 0; index < report.rows.length; index++) ...[
            _buildTimeProfileRow(
              context,
              report,
              report.rows[index],
              valueFormatter,
            ),
            if (index != report.rows.length - 1) const SizedBox(height: 10),
          ],
        ],
      ),
    );
  }

  Widget _buildTimeProfileRow(
    BuildContext context,
    TMTimeProfileReport report,
    TMTimeProfileRow row,
    LocaleValueFormatter valueFormatter,
  ) {
    final colorScheme = Theme.of(context).colorScheme;
    final sampled = row.isSampled;
    final rowColor = sampled
        ? colorScheme.tertiary
        : row.isComplete
        ? colorScheme.primary
        : colorScheme.error;
    final status = sampled
        ? '${appLocalizationsOf(context).localizeWorkflowText('Sampled')} • '
              '${appLocalizationsOf(context).localizeWorkflowText('Incomplete').toLowerCase()}'
        : row.isComplete
        ? '${appLocalizationsOf(context).localizeWorkflowText('Exhaustive')} • '
              '${appLocalizationsOf(context).localizeWorkflowText('Complete').toLowerCase()}'
        : '${appLocalizationsOf(context).localizeWorkflowText('Exhaustive')} • '
              '${appLocalizationsOf(context).localizeWorkflowText('Incomplete').toLowerCase()}';

    return Container(
      key: Key('tm-time-profile-row-${row.inputLength}'),
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: rowColor.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: rowColor.withValues(alpha: 0.75)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  localizeTMInteger(
                    valueFormatter,
                    (marker) => appLocalizationsOf(
                      context,
                    ).localizeWorkflowText('Input length $marker'),
                    row.inputLength,
                  ),
                  style: Theme.of(
                    context,
                  ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600),
                ),
              ),
              Chip(
                key: Key('tm-time-profile-row-mode-${row.inputLength}'),
                label: Text(status),
                side: BorderSide(color: rowColor),
                backgroundColor: rowColor.withValues(alpha: 0.12),
              ),
            ],
          ),
          buildTMMetricRow(
            context,
            'Candidates evaluated',
            '${valueFormatter.integer(row.evaluatedCandidateCount)} of ${valueFormatter.integer(row.candidateCount)}',
          ),
          if (row.isSampled)
            buildTMMetricRow(
              context,
              'Possible candidates',
              valueFormatter.integerBigInt(row.possibleCandidateCount),
              isWarning: true,
            ),
          buildTMMetricRow(
            context,
            report.kind == TMTimeProfileKind.deterministicTime
                ? 'Halting runs'
                : 'Resolved candidates',
            valueFormatter.integer(row.completedCount),
          ),
          if (row.provenCycleCount > 0)
            buildTMMetricRow(
              context,
              'Proven non-halting cycles',
              valueFormatter.integer(row.provenCycleCount),
              isWarning: true,
            ),
          if (row.unknownCount > 0)
            buildTMMetricRow(
              context,
              'Bounded unknown runs',
              valueFormatter.integer(row.unknownCount),
              isWarning: true,
            ),
          if (row.cancelledCount > 0)
            buildTMMetricRow(
              context,
              'Cancelled runs',
              valueFormatter.integer(row.cancelledCount),
              isWarning: true,
            ),
          if (row.invalidCount > 0)
            buildTMMetricRow(
              context,
              'Invalid runs',
              valueFormatter.integer(row.invalidCount),
              isError: true,
            ),
          if (report.kind == TMTimeProfileKind.deterministicTime) ...[
            buildTMMetricRow(
              context,
              'Minimum halting transition steps',
              row.minimumTransitionSteps == null
                  ? '—'
                  : valueFormatter.integer(row.minimumTransitionSteps!),
            ),
            buildTMMetricRow(
              context,
              'Maximum halting transition steps',
              row.maximumTransitionSteps == null
                  ? '—'
                  : valueFormatter.integer(row.maximumTransitionSteps!),
              highlight: row.maximumTransitionSteps != null,
            ),
            if (row.maximumTransitionWitness != null)
              _buildTimeProfileWitness(
                context,
                row.maximumTransitionWitness!,
                row.inputLength,
                valueFormatter: valueFormatter,
                metricKey: 'transitions',
                title: appLocalizationsOf(context).maximumTransitionStepWitness,
              ),
          ] else ...[
            buildTMMetricRow(
              context,
              'Observed branch depth range',
              _metricRange(
                row.minimumExplorationDepth,
                row.maximumExplorationDepth,
                valueFormatter,
              ),
            ),
            buildTMMetricRow(
              context,
              'Observed configurations explored range',
              _metricRange(
                row.minimumConfigurationsExplored,
                row.maximumConfigurationsExplored,
                valueFormatter,
              ),
            ),
            if (row.maximumDepthWitness != null)
              _buildTimeProfileWitness(
                context,
                row.maximumDepthWitness!,
                row.inputLength,
                valueFormatter: valueFormatter,
                metricKey: 'depth',
                title: appLocalizationsOf(
                  context,
                ).maximumExplorationDepthWitness,
              ),
            if (row.maximumConfigurationsWitness != null)
              _buildTimeProfileWitness(
                context,
                row.maximumConfigurationsWitness!,
                row.inputLength,
                valueFormatter: valueFormatter,
                metricKey: 'configurations',
                title: appLocalizationsOf(
                  context,
                ).maximumExploredConfigurationsWitness,
              ),
          ],
        ],
      ),
    );
  }

  String _metricRange(
    int? minimum,
    int? maximum,
    LocaleValueFormatter valueFormatter,
  ) {
    if (minimum == null || maximum == null) return '—';
    return '${valueFormatter.integer(minimum)}…${valueFormatter.integer(maximum)}';
  }

  Widget _buildTimeProfileWitness(
    BuildContext context,
    TMTimeProfileWitness witness,
    int inputLength, {
    required LocaleValueFormatter valueFormatter,
    required String metricKey,
    required String title,
  }) {
    final input = witness.input.isEmpty
        ? EmptyStringNotation.symbolOf(context)
        : witness.input;
    return Material(
      color: Colors.transparent,
      child: ExpansionTile(
        key: Key('tm-time-witness-$inputLength-$metricKey'),
        tilePadding: EdgeInsets.zero,
        title: Text(title),
        subtitle: Text(
          localizeTMInteger(
            valueFormatter,
            (marker) => appLocalizationsOf(
              context,
            ).inputRetainedConfigurations(input, marker),
            witness.execution.trace.length,
          ),
        ),
        children: [
          SizedBox(
            height: 220,
            child: ListView.builder(
              itemCount: witness.execution.trace.length,
              itemBuilder: (context, index) {
                final step = witness.execution.trace[index];
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
                    step.usedTransition ??
                        appLocalizationsOf(context).initialConfiguration,
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
