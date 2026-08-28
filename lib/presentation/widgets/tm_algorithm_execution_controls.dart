import 'package:flutter/material.dart';

import '../../l10n/app_localizations_resolver.dart';
import '../../l10n/app_localizations_workflows.dart';
import 'tm_algorithm_execution_controller.dart';
import 'tm_algorithm_inputs.dart';

/// Input and bounded progress for termination and tape-trace execution.
class TMTerminationControls extends StatelessWidget {
  const TMTerminationControls({
    super.key,
    required this.inputs,
    required this.state,
  });

  final TMAlgorithmInputs inputs;
  final TMAlgorithmAnalysisState state;

  @override
  Widget build(BuildContext context) {
    final strings = appLocalizationsOf(context);
    final progress = switch (state.currentFocus) {
      TMAnalysisFocus.termination => state.termination.progress,
      TMAnalysisFocus.tape => state.tape.progress,
      _ => null,
    };
    return Semantics(
      container: true,
      label: strings.localizeWorkflowText(
        'Termination and tape analysis controls',
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          TextField(
            key: const Key('tm-termination-input'),
            controller: inputs.terminationInput,
            enabled: !state.isAnalyzing,
            decoration: InputDecoration(
              labelText: strings.localizeWorkflowText(
                'Execution input for termination and tape analysis',
              ),
              helperText: strings.localizeWorkflowText(
                'Leave empty to analyze the empty string.',
              ),
              border: const OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            strings.localizeWorkflowText(
              'Limits: 10,000 steps, 100,000 configurations, 5 seconds',
            ),
            style: Theme.of(context).textTheme.bodySmall,
          ),
          if (state.isAnalyzing && progress != null) ...[
            const SizedBox(height: 4),
            Semantics(
              liveRegion: true,
              label: strings.localizeWorkflowText(progress),
              child: Text(
                strings.localizeWorkflowText(progress),
                key: const Key('tm-operation-progress'),
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

/// Cancellation action shared by active analysis families.
class TMAnalysisCancelControl extends StatelessWidget {
  const TMAnalysisCancelControl({
    super.key,
    required this.state,
    required this.onCancel,
  });

  final TMAlgorithmAnalysisState state;
  final VoidCallback onCancel;

  @override
  Widget build(BuildContext context) {
    if (!state.isAnalyzing) return const SizedBox.shrink();
    final strings = appLocalizationsOf(context);
    return OutlinedButton.icon(
      key: const Key('tm-analysis-cancel'),
      onPressed: state.cancelRequested ? null : onCancel,
      icon: const Icon(Icons.stop_circle_outlined),
      label: Text(
        strings.localizeWorkflowText(
          state.cancelRequested
              ? 'Cancelling analysis…'
              : state.currentFocus == TMAnalysisFocus.language
                  ? 'Cancel exploration'
                  : 'Cancel analysis',
        ),
      ),
    );
  }
}
