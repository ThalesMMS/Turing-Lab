import 'package:flutter/material.dart';

import '../../core/models/tm_language_explorer_models.dart';
import '../../l10n/app_localizations_resolver.dart';
import '../../l10n/app_localizations_structured_messages.dart';
import '../../l10n/app_localizations_workflows.dart';
import 'algorithm_panel_scaffold.dart';
import 'base_simulation_panel.dart';
import 'tm_algorithm_execution_controller.dart';
import 'tm_language_result_view.dart';
import 'tm_reachability_result_view.dart';
import 'tm_space_result_view.dart';
import 'tm_tape_result_view.dart';
import 'tm_termination_result_view.dart';
import 'tm_time_result_view.dart';

/// Selects one focused report widget from the independently retained families.
class TMAlgorithmResultsView extends StatelessWidget {
  const TMAlgorithmResultsView({
    super.key,
    required this.state,
    required this.onLanguageWordSelected,
  });

  final TMAlgorithmAnalysisState state;
  final ValueChanged<TMLanguageWordResult> onLanguageWordSelected;

  @override
  Widget build(BuildContext context) {
    final hasData =
        state.termination.report != null ||
        state.reachability.report != null ||
        state.language.report != null ||
        state.tape.report != null ||
        state.space.report != null ||
        state.time.report != null ||
        state.currentError != null;
    return AlgorithmResultsSection(
      hasResults: hasData,
      emptyBuilder: _buildEmpty,
      resultsBuilder: _buildResults,
    );
  }

  Widget _buildEmpty(BuildContext context) => SimulationEmptyResults(
    icon: Icons.analytics_outlined,
    title: appLocalizationsOf(context).noAnalysisResultsYet,
    message: appLocalizationsOf(context).selectAlgorithmToAnalyzeTm,
  );

  Widget _buildResults(BuildContext context) {
    final error = state.currentError;
    if (error != null) {
      final colors = Theme.of(context).colorScheme;
      final l10n = appLocalizationsOf(context);
      final message = state.currentStructuredError == null
          ? l10n.localizeWorkflowText(error)
          : l10n.resolveStructuredMessage(state.currentStructuredError!);
      return Semantics(
        liveRegion: true,
        label: message,
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: colors.error.withValues(alpha: 0.2)),
            color: colors.errorContainer.withValues(alpha: 0.4),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(Icons.error_outline, color: colors.error),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  message,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: colors.onErrorContainer,
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    }

    return switch (state.currentFocus) {
      TMAnalysisFocus.termination when state.termination.report != null =>
        TMTerminationResultView(analysis: state.termination.report!),
      TMAnalysisFocus.reachability when state.reachability.report != null =>
        TMReachabilityResultView(
          report: state.reachability.report!,
          sourceTm: state.reachability.sourceTm,
        ),
      TMAnalysisFocus.language when state.language.report != null =>
        TMLanguageResultView(
          report: state.language.report!,
          selectedWord: state.language.selectedWord,
          selectedTrace: state.language.selectedTrace,
          isLoadingTrace: state.language.isLoadingTrace,
          onWordSelected: onLanguageWordSelected,
        ),
      TMAnalysisFocus.tape when state.tape.report != null => TMTapeResultView(
        analysis: state.tape.report!,
        sourceTm: state.tape.sourceTm,
      ),
      TMAnalysisFocus.time when state.time.report != null => TMTimeResultView(
        report: state.time.report!,
      ),
      TMAnalysisFocus.space when state.space.report != null =>
        TMSpaceResultView(report: state.space.report!),
      _ => _buildEmpty(context),
    };
  }
}
