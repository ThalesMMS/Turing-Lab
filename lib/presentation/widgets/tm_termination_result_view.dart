import 'package:flutter/material.dart';

import '../../core/models/simulation_step.dart';
import '../../core/models/tm_execution_analysis.dart';
import '../../l10n/app_localizations_resolver.dart';
import '../../l10n/app_localizations_structured_messages.dart';
import '../../l10n/app_localizations_workflows.dart';
import '../localization/locale_value_formatter.dart';
import 'tm_algorithm_execution_controller.dart';
import 'tm_algorithm_presentation_primitives.dart';

/// Presents bounded termination outcomes and repeated-configuration evidence.
class TMTerminationResultView extends StatelessWidget {
  const TMTerminationResultView({super.key, required this.analysis});

  final TMExecutionAnalysis analysis;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final l10n = appLocalizationsOf(context);
    final valueFormatter = LocaleValueFormatter.of(context);
    final outcomeLabel = switch (analysis.outcome) {
      TMExecutionOutcome.accepted => 'Accepted',
      TMExecutionOutcome.haltedRejected => 'Halted and rejected',
      TMExecutionOutcome.provenCycle => 'Proven cycle',
      TMExecutionOutcome.boundedUnknown => 'Inconclusive within limits',
      TMExecutionOutcome.cancelled => 'Cancelled',
      TMExecutionOutcome.invalidMachine => 'Invalid machine or input',
    };
    final positive = analysis.outcome == TMExecutionOutcome.accepted;
    final warning =
        analysis.outcome == TMExecutionOutcome.provenCycle ||
        analysis.outcome == TMExecutionOutcome.boundedUnknown;
    final cycle = analysis.cycle;
    final cycleTrace = cycle == null
        ? const <SimulationStep>[]
        : analysis.trace
              .where(
                (step) =>
                    step.stepNumber >= cycle.startStep &&
                    step.stepNumber <= cycle.startStep + cycle.period,
              )
              .toList(growable: false);
    final analysisMessage = analysis.structuredMessage == null
        ? l10n.localizeWorkflowText(analysis.message)
        : l10n.resolveStructuredMessage(analysis.structuredMessage!);

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
          buildTMFocusBanner(context, TMAnalysisFocus.termination),
          const SizedBox(height: 12),
          buildTMStatusMessage(
            context,
            message:
                '${l10n.localizeWorkflowText(outcomeLabel)}. $analysisMessage',
            isPositive: positive,
            isWarning: warning,
          ),
          const SizedBox(height: 8),
          buildTMMetricRow(
            context,
            'Input',
            analysis.input.isEmpty ? 'ε' : analysis.input,
          ),
          buildTMMetricRow(
            context,
            'Conclusion',
            analysis.isExact ? 'Exact for this input' : 'Bounded',
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
            'Step limit',
            valueFormatter.integer(analysis.maxSteps),
          ),
          buildTMMetricRow(
            context,
            'Configuration limit',
            valueFormatter.integer(analysis.maxConfigurations),
          ),
          buildTMMetricRow(
            context,
            'Time limit',
            '${valueFormatter.integer(analysis.timeout.inSeconds)} s',
          ),
          if (analysis.limit != null)
            buildTMMetricRow(
              context,
              'Limit reached',
              analysis.limit!.name,
              isWarning: true,
            ),
          if (cycle != null) ...[
            buildTMMetricRow(
              context,
              'Cycle start',
              localizeTMInteger(
                valueFormatter,
                (marker) => l10n.localizeWorkflowText('Step $marker'),
                cycle.startStep,
              ),
              isWarning: true,
            ),
            buildTMMetricRow(
              context,
              'Cycle period',
              '${valueFormatter.integer(cycle.period)} transition(s)',
              isWarning: true,
            ),
            buildTMMetricRow(
              context,
              'Repeated state',
              cycle.configuration.stateId,
              isWarning: true,
            ),
            buildTMMetricRow(
              context,
              'Repeated head position',
              valueFormatter.integer(cycle.configuration.headPosition),
              isWarning: true,
            ),
            buildTMChipList(
              context,
              label: 'Repeated nonblank tape cells',
              values: [
                for (final entry in cycle.configuration.nonBlankCells.entries)
                  '${valueFormatter.integer(entry.key)}: ${entry.value}',
              ],
              isWarning: true,
            ),
            if (cycleTrace.isNotEmpty)
              Material(
                color: Colors.transparent,
                child: ExpansionTile(
                  key: const Key('tm-cycle-trace'),
                  tilePadding: EdgeInsets.zero,
                  title: Text(appLocalizationsOf(context).repeatedCycleTrace),
                  subtitle: Text(
                    localizeTMInteger(
                      valueFormatter,
                      appLocalizationsOf(context).retainedConfigurations,
                      cycleTrace.length,
                    ),
                  ),
                  children: [
                    for (final step in cycleTrace)
                      ListTile(
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
                          '${step.usedTransition ?? appLocalizationsOf(context).initialConfiguration}\n'
                          '${localizeTMInteger(valueFormatter, (marker) => appLocalizationsOf(context).headTapeSubtitle(marker, step.tapeContents.isEmpty ? '∅' : step.tapeContents), step.headPosition ?? 0)}',
                        ),
                      ),
                  ],
                ),
              ),
          ],
          if (analysis.repeatedConfigurationsObserved > 0)
            buildTMMetricRow(
              context,
              'Repeated NTM configurations observed',
              valueFormatter.integer(analysis.repeatedConfigurationsObserved),
            ),
        ],
      ),
    );
  }
}
