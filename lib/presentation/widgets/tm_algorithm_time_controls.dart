import 'package:flutter/material.dart';

import '../../core/algorithms/tm_time_profiler.dart';
import '../../core/models/tm.dart';
import '../../l10n/app_localizations_resolver.dart';
import '../../l10n/app_localizations_workflows.dart';
import '../localization/locale_value_formatter.dart';
import 'tm_algorithm_execution_controller.dart';
import 'tm_algorithm_inputs.dart';

/// Bounded planning inputs and progress for empirical time profiling.
class TMTimeProfilerControls extends StatelessWidget {
  const TMTimeProfilerControls({
    super.key,
    required this.tm,
    required this.inputs,
    required this.state,
    required this.onInputsChanged,
  });

  final TM? tm;
  final TMAlgorithmInputs inputs;
  final TMAlgorithmAnalysisState state;
  final VoidCallback onInputsChanged;

  @override
  Widget build(BuildContext context) {
    final strings = appLocalizationsOf(context);
    return Semantics(
      container: true,
      label: strings.localizeWorkflowText('Time profiler controls'),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            strings.localizeWorkflowText('Bounded time-profile scope'),
            style: Theme.of(
              context,
            ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: _field(
                  key: const Key('tm-time-profile-max-length'),
                  controller: inputs.profileMaxLength,
                  label: strings.localizeWorkflowText('Maximum input length'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _field(
                  key: const Key('tm-time-profile-candidate-cap'),
                  controller: inputs.profileCandidateCap,
                  label: strings.localizeWorkflowText(
                    'Candidate limit per length',
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          _planSummary(context),
          if (state.isAnalyzing &&
              state.currentFocus == TMAnalysisFocus.time &&
              state.time.progress != null) ...[
            const SizedBox(height: 8),
            LinearProgressIndicator(
              key: const Key('tm-time-profile-progress'),
              value: state.time.progress!.fraction.clamp(0, 1),
              semanticsLabel: state.time.progress!.label == null
                  ? null
                  : strings.localizeWorkflowText(state.time.progress!.label!),
            ),
          ],
        ],
      ),
    );
  }

  Widget _field({
    required Key key,
    required TextEditingController controller,
    required String label,
  }) => TextField(
    key: key,
    controller: controller,
    enabled: !state.isAnalyzing,
    keyboardType: TextInputType.number,
    onChanged: (_) => onInputsChanged(),
    decoration: InputDecoration(
      labelText: label,
      border: const OutlineInputBorder(),
    ),
  );

  Widget _planSummary(BuildContext context) {
    final strings = appLocalizationsOf(context);
    final valueFormatter = LocaleValueFormatter.of(context);
    final bounds = inputs.timeBounds;
    if (bounds == null) {
      return Text(
        strings.localizeWorkflowText(
          'Enter integer bounds to calculate the candidate plan.',
        ),
        style: Theme.of(context).textTheme.bodySmall,
      );
    }
    if (tm == null) {
      return Text(
        strings.localizeWorkflowText(
          'Candidate counts appear after a Turing machine is available.',
        ),
        style: Theme.of(context).textTheme.bodySmall,
      );
    }
    final plan = TMTimeProfiler.plan(tm!, bounds: bounds);
    if (!plan.isValid) {
      return Text(
        strings.localizeWorkflowText(plan.validationError!),
        style: Theme.of(context).textTheme.bodySmall?.copyWith(
          color: Theme.of(context).colorScheme.error,
        ),
      );
    }
    final sampled = strings.localizeWorkflowText('Sampled').toLowerCase();
    final exhaustive = strings.localizeWorkflowText('Exhaustive').toLowerCase();
    final rows = plan.rows
        .map((row) {
          return row.isSampled
              ? 'n=${valueFormatter.integer(row.inputLength)}: '
                    '${valueFormatter.integer(row.candidateCount)}/'
                    '${valueFormatter.integerBigInt(row.possibleCandidateCount)} $sampled'
              : 'n=${valueFormatter.integer(row.inputLength)}: '
                    '${valueFormatter.integer(row.candidateCount)} $exhaustive';
        })
        .join(' • ');
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '${strings.localizeWorkflowText('Planned candidates')}: '
          '${valueFormatter.integer(plan.plannedCandidateCount)}',
          key: const Key('tm-time-profile-planned-count'),
          style: Theme.of(context).textTheme.bodySmall,
        ),
        Text(
          rows,
          key: const Key('tm-time-profile-plan-rows'),
          style: Theme.of(context).textTheme.bodySmall,
        ),
        Text(
          strings.localizeWorkflowText(
            'Per candidate: 50,000 transition steps, 100,000 configurations, 5 seconds',
          ),
          key: const Key('tm-time-profile-budgets'),
          style: Theme.of(context).textTheme.bodySmall,
        ),
      ],
    );
  }
}
