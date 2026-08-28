import 'package:flutter/material.dart';

import '../../core/models/tm_execution_analysis.dart';
import '../../core/models/tm_language_explorer_models.dart';
import '../../l10n/app_localizations_resolver.dart';
import '../../l10n/app_localizations_structured_messages.dart';
import '../../l10n/app_localizations_workflows.dart';
import '../localization/locale_value_formatter.dart';
import 'tm_algorithm_execution_controller.dart';
import 'tm_algorithm_presentation_primitives.dart';

/// Presents language outcome groups and lazily retained word traces.
class TMLanguageResultView extends StatelessWidget {
  const TMLanguageResultView({
    super.key,
    required this.report,
    required this.selectedWord,
    required this.selectedTrace,
    required this.isLoadingTrace,
    required this.onWordSelected,
  });

  final TMLanguageExplorerReport report;
  final TMLanguageWordResult? selectedWord;
  final TMExecutionAnalysis? selectedTrace;
  final bool isLoadingTrace;
  final ValueChanged<TMLanguageWordResult> onWordSelected;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final valueFormatter = LocaleValueFormatter.of(context);
    final alphabet = report.alphabet.isEmpty ? '∅' : report.alphabet.join(', ');
    final completeness = report.cancelled
        ? 'Cancelled • incomplete'
        : report.truncatedByCandidateCap
        ? 'Sampled • deterministic shortlex prefix'
        : report.count(TMLanguageOutcome.inconclusive) > 0
        ? 'Complete enumeration • bounded outcomes remain'
        : 'Complete';
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
          buildTMFocusBanner(context, TMAnalysisFocus.language),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final outcome in TMLanguageOutcome.values)
                _buildLanguageOutcomeCount(context, report, outcome),
            ],
          ),
          const SizedBox(height: 12),
          buildTMMetricRow(
            context,
            'Evaluated candidates',
            '${valueFormatter.integer(report.results.length)} of ${valueFormatter.integer(report.plannedCandidates)}',
          ),
          buildTMMetricRow(
            context,
            'Requested candidates',
            valueFormatter.integerBigInt(report.requestedCandidates),
          ),
          buildTMMetricRow(context, 'Completeness', completeness),
          buildTMMetricRow(context, 'Input alphabet', alphabet),
          buildTMMetricRow(
            context,
            'Maximum input length',
            valueFormatter.integer(report.limits.maxInputLength),
          ),
          buildTMMetricRow(
            context,
            'Candidate cap',
            valueFormatter.integer(report.limits.maxCandidates),
          ),
          buildTMMetricRow(
            context,
            'Step limit per input',
            valueFormatter.integer(report.limits.maxStepsPerInput),
          ),
          buildTMMetricRow(
            context,
            'Configuration limit per input',
            valueFormatter.integer(report.limits.maxConfigurationsPerInput),
          ),
          buildTMMetricRow(
            context,
            'Time limit per input',
            '${valueFormatter.integer(report.limits.timeoutPerInput.inMilliseconds)} ms',
          ),
          buildTMMetricRow(
            context,
            'Exploration time',
            formatTMAnalysisDuration(context, report.executionTime),
          ),
          if (report.truncatedByCandidateCap)
            buildTMStatusMessage(
              context,
              message:
                  'Candidate cap reached. This report contains the deterministic shortlex prefix only.',
              isWarning: true,
            ),
          if (report.cancelled)
            buildTMStatusMessage(
              context,
              message: appLocalizationsOf(context).explorationCancelledKept,
              isWarning: true,
            ),
          if (report.count(TMLanguageOutcome.inconclusive) > 0)
            buildTMStatusMessage(
              context,
              message:
                  'Some inputs are inconclusive; limits or cancellation do not imply rejection.',
              isWarning: true,
            ),
          const SizedBox(height: 8),
          Text(
            appLocalizationsOf(context).words,
            style: Theme.of(
              context,
            ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 4),
          for (final result in report.results)
            _buildLanguageWordTile(context, result),
          if (report.results.isEmpty)
            Text(appLocalizationsOf(context).noCandidatesEvaluated),
          if (selectedWord != null) ...[
            const Divider(height: 24),
            _buildSelectedLanguageWord(context, selectedWord!),
          ],
        ],
      ),
    );
  }

  Widget _buildLanguageOutcomeCount(
    BuildContext context,
    TMLanguageExplorerReport report,
    TMLanguageOutcome outcome,
  ) {
    final color = _languageOutcomeColor(context, outcome);
    final l10n = appLocalizationsOf(context);
    final valueFormatter = LocaleValueFormatter.of(context);
    final outcomeLabel = l10n.localizeWorkflowText(
      _languageOutcomeLabel(outcome),
    );
    return Container(
      key: Key('tm-language-count-${outcome.name}'),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        border: Border.all(color: color.withValues(alpha: 0.6)),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Text(
        '$outcomeLabel: ${valueFormatter.integer(report.count(outcome))}',
        style: Theme.of(context).textTheme.labelMedium?.copyWith(color: color),
      ),
    );
  }

  Widget _buildLanguageWordTile(
    BuildContext context,
    TMLanguageWordResult result,
  ) {
    final selected = selectedWord?.input == result.input;
    final color = _languageOutcomeColor(context, result.outcome);
    final l10n = appLocalizationsOf(context);
    final valueFormatter = LocaleValueFormatter.of(context);
    final outcomeLabel = l10n.localizeWorkflowText(
      _languageOutcomeLabel(result.outcome),
    );
    return Card(
      key: ValueKey('tm-language-word-${result.input}'),
      color: selected
          ? Theme.of(context).colorScheme.primaryContainer
          : Theme.of(context).colorScheme.surface,
      child: ListTile(
        selected: selected,
        onTap: () => onWordSelected(result),
        leading: Icon(_languageOutcomeIcon(result.outcome), color: color),
        title: Text(result.input.isEmpty ? 'ε' : result.input),
        subtitle: Text(
          '$outcomeLabel • ${_languageProgressText(context, valueFormatter, result.analysis)}',
        ),
        trailing: const Icon(Icons.chevron_right),
      ),
    );
  }

  Widget _buildSelectedLanguageWord(
    BuildContext context,
    TMLanguageWordResult result,
  ) {
    final analysis = result.analysis;
    final trace = selectedTrace?.trace ?? const [];
    final valueFormatter = LocaleValueFormatter.of(context);
    final analysisMessage = analysis.structuredMessage == null
        ? analysis.message
        : appLocalizationsOf(
            context,
          ).resolveStructuredMessage(analysis.structuredMessage!);
    return Column(
      key: const Key('tm-language-selected-word'),
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          'Selected word: ${result.input.isEmpty ? 'ε' : result.input}',
          style: Theme.of(
            context,
          ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 8),
        buildTMMetricRow(
          context,
          'Outcome',
          _languageOutcomeLabel(result.outcome),
        ),
        buildTMStatusMessage(
          context,
          message: analysisMessage,
          isWarning: !analysis.isExact,
        ),
        buildTMMetricRow(
          context,
          'Transitions executed',
          valueFormatter.integer(analysis.stepsExecuted),
        ),
        buildTMMetricRow(
          context,
          'Configurations explored',
          valueFormatter.integer(analysis.configurationsExplored),
        ),
        buildTMMetricRow(
          context,
          'Execution time',
          formatTMAnalysisDuration(context, analysis.executionTime),
        ),
        if (analysis.limit != null)
          buildTMMetricRow(
            context,
            'Limit reached',
            analysis.limit!.name,
            isWarning: true,
          ),
        const SizedBox(height: 8),
        Text(
          'Trace',
          style: Theme.of(
            context,
          ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600),
        ),
        if (isLoadingTrace)
          const Padding(
            padding: EdgeInsets.all(16),
            child: Center(child: CircularProgressIndicator()),
          )
        else if (trace.isEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Text(appLocalizationsOf(context).noTraceRecordedBoundedRun),
          )
        else
          SizedBox(
            height: 220,
            child: ListView.separated(
              key: const Key('tm-language-trace'),
              itemCount: trace.length,
              separatorBuilder: (_, __) => const Divider(height: 1),
              itemBuilder: (context, index) {
                final step = trace[index];
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
                        localizeTMInteger(
                          valueFormatter,
                          (marker) => appLocalizationsOf(
                            context,
                          ).initialConfigurationAtHead(marker),
                          step.headPosition ?? 0,
                        ),
                  ),
                );
              },
            ),
          ),
      ],
    );
  }

  String _languageOutcomeLabel(TMLanguageOutcome outcome) => switch (outcome) {
    TMLanguageOutcome.accepted => 'Accepted',
    TMLanguageOutcome.rejected => 'Halted rejected',
    TMLanguageOutcome.provenCycle => 'Proven cycle',
    TMLanguageOutcome.inconclusive => 'Inconclusive',
  };

  IconData _languageOutcomeIcon(TMLanguageOutcome outcome) => switch (outcome) {
    TMLanguageOutcome.accepted => Icons.check_circle_outline,
    TMLanguageOutcome.rejected => Icons.cancel_outlined,
    TMLanguageOutcome.provenCycle => Icons.loop,
    TMLanguageOutcome.inconclusive => Icons.help_outline,
  };

  Color _languageOutcomeColor(BuildContext context, TMLanguageOutcome outcome) {
    final colors = Theme.of(context).colorScheme;
    return switch (outcome) {
      TMLanguageOutcome.accepted => colors.primary,
      TMLanguageOutcome.rejected => colors.error,
      TMLanguageOutcome.provenCycle => colors.tertiary,
      TMLanguageOutcome.inconclusive => colors.onSurfaceVariant,
    };
  }
}

String _languageProgressText(
  BuildContext context,
  LocaleValueFormatter formatter,
  TMExecutionAnalysis analysis,
) {
  const transitionsMarker = 987654321;
  const configurationsMarker = 123456789;
  final l10n = appLocalizationsOf(context);
  return l10n
      .transitionsConfigurationsProgress(
        transitionsMarker,
        configurationsMarker,
      )
      .replaceFirst(
        '$transitionsMarker',
        formatter.integer(analysis.stepsExecuted),
      )
      .replaceFirst(
        '$configurationsMarker',
        formatter.integer(analysis.configurationsExplored),
      );
}
