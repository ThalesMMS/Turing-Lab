import 'package:flutter/material.dart';

import '../../core/algorithms/tm_language_explorer.dart';
import '../../core/models/tm.dart';
import '../../l10n/app_localizations_resolver.dart';
import '../../l10n/app_localizations_workflows.dart';
import 'tm_algorithm_execution_controller.dart';
import 'tm_algorithm_inputs.dart';

/// Typed bounds and progress controls for shortlex language exploration.
class TMLanguageExplorerControls extends StatelessWidget {
  const TMLanguageExplorerControls({
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
    final maxLength = int.tryParse(inputs.languageMaxLength.text);
    final candidateCap = int.tryParse(inputs.languageCandidateCap.text);
    final requested = maxLength != null && maxLength >= 0
        ? TMLanguageExplorer.countCandidates(
            tm?.alphabet ?? const <String>{},
            maxLength,
          )
        : null;
    final planned =
        requested == null || candidateCap == null || candidateCap <= 0
            ? null
            : requested > BigInt.from(candidateCap)
                ? candidateCap
                : requested.toInt();
    final progress = state.language.progress;
    final strings = appLocalizationsOf(context);
    return Semantics(
      container: true,
      label: strings.localizeWorkflowText('Language explorer limits'),
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
              strings.localizeWorkflowText('Language explorer limits'),
              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                _field(context, const Key('tm-language-max-length'),
                    inputs.languageMaxLength, 'Max input length'),
                _field(context, const Key('tm-language-candidate-cap'),
                    inputs.languageCandidateCap, 'Candidate cap'),
                _field(context, const Key('tm-language-max-steps'),
                    inputs.languageMaxSteps, 'Steps per input'),
                _field(
                  context,
                  const Key('tm-language-max-configurations'),
                  inputs.languageMaxConfigurations,
                  'Configurations per input',
                ),
                _field(context, const Key('tm-language-timeout-ms'),
                    inputs.languageTimeoutMs, 'Timeout per input (ms)'),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              requested == null || planned == null
                  ? strings.estimatedCandidatesInvalid
                  : strings.estimatedCandidatesScheduled(
                      '$requested', '$planned'),
              key: const Key('tm-language-candidate-estimate'),
              style: Theme.of(context).textTheme.bodySmall,
            ),
            if (state.isAnalyzing &&
                state.currentFocus == TMAnalysisFocus.language &&
                progress != null) ...[
              const SizedBox(height: 8),
              LinearProgressIndicator(
                key: const Key('tm-language-progress'),
                value: progress.fraction.clamp(0, 1),
              ),
              Text(
                strings.evaluatedOf(
                  progress.evaluatedCandidates,
                  progress.plannedCandidates,
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
