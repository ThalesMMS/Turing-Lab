import 'package:flutter/material.dart';

import '../../l10n/app_localizations_resolver.dart';
import '../../l10n/app_localizations_workflows.dart';
import '../empty_string_notation.dart';
import 'tm_algorithm_execution_controller.dart';
import 'tm_algorithm_inputs.dart';

/// Input scope and bounded progress for reachability analysis.
class TMReachabilityControls extends StatelessWidget {
  const TMReachabilityControls({
    super.key,
    required this.inputs,
    required this.state,
  });

  final TMAlgorithmInputs inputs;
  final TMAlgorithmAnalysisState state;

  @override
  Widget build(BuildContext context) {
    final strings = appLocalizationsOf(context);
    final progress = state.currentFocus == TMAnalysisFocus.reachability
        ? state.reachability.progress
        : null;
    return Semantics(
      container: true,
      label: strings.localizeWorkflowText('Reachability analysis controls'),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          TextField(
            key: const Key('tm-reachability-inputs'),
            controller: inputs.reachabilityInputs,
            enabled: !state.isAnalyzing,
            decoration: InputDecoration(
              labelText: strings.localizeWorkflowText(
                'Reachability input scope',
              ),
              helperText: EmptyStringNotation.formatTerminology(
                context,
                strings.localizeWorkflowText(
                  'Separate inputs with commas; use ε for the empty string.',
                ),
              ),
              border: const OutlineInputBorder(),
            ),
          ),
          if (state.isAnalyzing && progress != null) ...[
            const SizedBox(height: 4),
            Semantics(
              liveRegion: true,
              label: EmptyStringNotation.format(
                context,
                strings.localizeWorkflowText(progress),
              ),
              child: Text(
                EmptyStringNotation.format(
                  context,
                  strings.localizeWorkflowText(progress),
                ),
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
