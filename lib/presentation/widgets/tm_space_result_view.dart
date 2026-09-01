import 'package:flutter/material.dart';

import '../../core/models/tm_space_profile.dart';
import '../../l10n/app_localizations_resolver.dart';
import '../../l10n/app_localizations_workflows.dart';
import '../empty_string_notation.dart';
import '../localization/locale_value_formatter.dart';
import 'tm_algorithm_execution_controller.dart';
import 'tm_algorithm_presentation_primitives.dart';

/// Presents bounded space rows and their typed maximum witnesses.
class TMSpaceResultView extends StatelessWidget {
  const TMSpaceResultView({super.key, required this.report});

  final TMSpaceProfileReport report;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final valueFormatter = LocaleValueFormatter.of(context);
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: colorScheme.outline.withValues(alpha: 0.4)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          buildTMFocusBanner(context, TMAnalysisFocus.space),
          const SizedBox(height: 12),
          buildTMStatusMessage(
            context,
            message: report.isIncomplete
                ? 'The profile is incomplete. Sampled or bounded rows remain labeled below.'
                : 'Every scheduled input completed and every row was exhaustively enumerated.',
            isPositive: !report.isIncomplete,
            isWarning: report.isIncomplete,
          ),
          const SizedBox(height: 8),
          buildTMMetricRow(
            context,
            'Evaluated candidates',
            '${valueFormatter.integer(report.evaluatedCandidates)} of ${valueFormatter.integer(report.scheduledCandidates)}',
          ),
          buildTMMetricRow(
            context,
            'Requested candidates',
            valueFormatter.integerBigInt(report.requestedCandidates),
          ),
          buildTMMetricRow(
            context,
            'Step limit per input',
            valueFormatter.integer(report.limits.maxStepsPerInput),
          ),
          buildTMMetricRow(
            context,
            'Configuration bound per input',
            valueFormatter.integer(report.limits.maxConfigurationsPerInput),
            isWarning: report.isNondeterministic,
          ),
          buildTMMetricRow(
            context,
            'Time limit per input',
            '${valueFormatter.integer(report.limits.timeoutPerInput.inMilliseconds)} ms',
          ),
          buildTMMetricRow(
            context,
            'Profile time',
            formatTMAnalysisDuration(context, report.executionTime),
          ),
          const SizedBox(height: 8),
          Text(
            'The current single tape stores both the original input and work data.',
            style: Theme.of(context).textTheme.bodySmall,
          ),
          if (report.isNondeterministic)
            Text(
              'NTM maxima cover every explored branch configuration within the displayed configuration bound.',
              style: Theme.of(context).textTheme.bodySmall,
            ),
          Text(
            'These observed maxima are a bounded profile, not an asymptotic space-complexity proof.',
            style: Theme.of(context).textTheme.bodySmall,
          ),
          if (report.cancelled)
            buildTMStatusMessage(
              context,
              message: appLocalizationsOf(context).spaceProfilingCancelledKept,
              isWarning: true,
            ),
          const SizedBox(height: 12),
          for (final row in report.rows) ...[
            _buildSpaceLengthCard(context, row, valueFormatter),
            const SizedBox(height: 8),
          ],
          if (report.rows.isEmpty)
            Text(appLocalizationsOf(context).noInputLengthGroupEvaluated),
        ],
      ),
    );
  }

  Widget _buildSpaceLengthCard(
    BuildContext context,
    TMSpaceLengthProfile row,
    LocaleValueFormatter valueFormatter,
  ) {
    final colors = Theme.of(context).colorScheme;
    final sampled = row.enumerationMode == TMSpaceEnumerationMode.sampled;
    return Container(
      key: Key('tm-space-length-${row.inputLength}'),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: row.isIncomplete
              ? colors.tertiary.withValues(alpha: 0.7)
              : colors.outline.withValues(alpha: 0.4),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
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
          const SizedBox(height: 6),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: [
              Chip(
                label: Text(
                  appLocalizationsOf(
                    context,
                  ).localizeWorkflowText(sampled ? 'Sampled' : 'Exhaustive'),
                ),
              ),
              Chip(
                label: Text(
                  appLocalizationsOf(context).localizeWorkflowText(
                    row.isIncomplete ? 'Incomplete' : 'Complete',
                  ),
                ),
              ),
            ],
          ),
          buildTMMetricRow(
            context,
            'Candidate coverage',
            '${valueFormatter.integer(row.inputs.length)} of ${valueFormatter.integerBigInt(row.requestedCandidates)}',
          ),
          buildTMMetricRow(
            context,
            'Visited span maximum',
            _formatSpaceMaximum(
              context,
              row.maximumVisitedSpan,
              valueFormatter,
            ),
            highlight: row.maximumVisitedSpan != null,
          ),
          buildTMMetricRow(
            context,
            'Maximum nonblank cells',
            _formatSpaceMaximum(
              context,
              row.maximumNonBlankCells,
              valueFormatter,
            ),
            highlight: row.maximumNonBlankCells != null,
          ),
          if (row.inconclusiveInputs > 0)
            buildTMMetricRow(
              context,
              'Inconclusive executions',
              valueFormatter.integer(row.inconclusiveInputs),
              isWarning: true,
            ),
          if (sampled)
            Text(
              appLocalizationsOf(context).localizeWorkflowText(
                'The deterministic shortlex prefix was sampled because this length exceeds the candidate cap.',
              ),
              style: Theme.of(
                context,
              ).textTheme.bodySmall?.copyWith(color: colors.onSurfaceVariant),
            ),
        ],
      ),
    );
  }

  String _formatSpaceMaximum(
    BuildContext context,
    TMSpaceMaximum? maximum,
    LocaleValueFormatter valueFormatter,
  ) {
    if (maximum == null) return 'Not observed';
    final witness = maximum.witnessInput.isEmpty
        ? EmptyStringNotation.symbolOf(context)
        : maximum.witnessInput;
    return '${valueFormatter.integer(maximum.value)} cell(s) • witness $witness';
  }
}
