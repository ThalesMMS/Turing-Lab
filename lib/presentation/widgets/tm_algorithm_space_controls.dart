import 'package:flutter/material.dart';

import '../../core/algorithms/tm_space_profiler.dart';
import '../../core/models/tm.dart';
import '../../core/models/tm_space_profile.dart';
import '../../l10n/app_localizations_resolver.dart';
import '../../l10n/app_localizations_workflows.dart';
import 'tm_algorithm_execution_controller.dart';
import 'tm_algorithm_inputs.dart';

/// Typed bounds and progress controls for bounded tape-space profiling.
class TMSpaceProfilerControls extends StatelessWidget {
  const TMSpaceProfilerControls({
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
    final maxLength = int.tryParse(inputs.spaceMaxLength.text);
    final candidateCap = int.tryParse(inputs.spaceCandidateCap.text);
    BigInt? requested;
    int? scheduled;
    if (maxLength != null &&
        maxLength >= 0 &&
        candidateCap != null &&
        candidateCap > 0) {
      final alphabet = tm?.alphabet ?? const <String>{};
      requested =
          TMSpaceProfiler.countCandidatesThroughLength(alphabet, maxLength);
      scheduled = TMSpaceProfiler.countScheduledCandidates(
        alphabet,
        TMSpaceProfileLimits(
          maxInputLength: maxLength,
          maxCandidatesPerLength: candidateCap,
        ),
      );
    }
    final progress = state.space.progress;
    final strings = appLocalizationsOf(context);
    return Semantics(
      container: true,
      label: strings.localizeWorkflowText('Space profiler limits'),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          border: Border.all(
            color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.4),
          ),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              strings.localizeWorkflowText('Space profiler limits'),
              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                _field(context, const Key('tm-space-max-length'),
                    inputs.spaceMaxLength, 'Max input length'),
                _field(context, const Key('tm-space-candidate-cap'),
                    inputs.spaceCandidateCap, 'Candidates per length'),
                _field(context, const Key('tm-space-max-steps'),
                    inputs.spaceMaxSteps, 'Steps per input'),
                _field(
                  context,
                  const Key('tm-space-max-configurations'),
                  inputs.spaceMaxConfigurations,
                  'Configurations per input',
                ),
                _field(context, const Key('tm-space-timeout-ms'),
                    inputs.spaceTimeoutMs, 'Timeout per input (ms)'),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              requested == null || scheduled == null
                  ? strings.estimatedCandidatesInvalid
                  : strings.estimatedCandidatesScheduled(
                      '$requested',
                      '$scheduled',
                    ),
              key: const Key('tm-space-candidate-estimate'),
              style: Theme.of(context).textTheme.bodySmall,
            ),
            if (state.isAnalyzing &&
                state.currentFocus == TMAnalysisFocus.space &&
                progress != null) ...[
              const SizedBox(height: 8),
              LinearProgressIndicator(
                key: const Key('tm-space-progress'),
                value: progress.fraction.clamp(0, 1),
              ),
              Text(
                strings.evaluatedOf(
                  progress.evaluatedCandidates,
                  progress.scheduledCandidates,
                ),
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _field(
    BuildContext context,
    Key key,
    TextEditingController controller,
    String label,
  ) =>
      SizedBox(
        width: 170,
        child: TextField(
          key: key,
          controller: controller,
          enabled: !state.isAnalyzing,
          keyboardType: TextInputType.number,
          onChanged: (_) => onInputsChanged(),
          decoration: InputDecoration(
            labelText: appLocalizationsOf(context).localizeWorkflowText(label),
            border: const OutlineInputBorder(),
            isDense: true,
          ),
        ),
      );
}
