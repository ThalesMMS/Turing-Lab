//
//  simulation_result_card.dart
//  Turing Lab
//
//  Enhanced simulation-result display with path visualization.
//  Shows acceptance status, run metrics, visited-state sequence, and
//  used transitions in a compact, clear layout. Supports all automaton
//  types (DFA, NFA, PDA, TM).
//
//  Thales Matheus Mendonça Santos - January 2026
//

import 'package:flutter/material.dart';
import '../../../core/models/simulation_result.dart';
import '../../../l10n/app_localizations_resolver.dart';
import '../../../l10n/app_localizations_structured_messages.dart';
import '../../../l10n/app_localizations_workflows.dart';
import '../../../core/constants/monospace_typography.dart';
import '../../localization/locale_value_formatter.dart';

/// Card widget for displaying simulation results with path visualization.
///
/// This widget provides a comprehensive view of automaton simulation results,
/// including acceptance status, execution metrics, and a visual representation
/// of the path taken through the automaton's states.
///
/// Features:
/// - Clear acceptance/rejection status with color coding
/// - Execution time and step count metrics
/// - Path visualization showing state transitions
/// - Transition sequence display
/// - Input consumption visualization
/// - Error message display for failed simulations
/// - Material 3 theming integration
///
/// Example:
/// ```dart
/// SimulationResultCard(
///   result: simulationResult,
///   showPathVisualization: true,
///   onStepTapped: (stepIndex) {
///     // Navigate to specific step
///   },
/// )
/// ```
class SimulationResultCard extends StatelessWidget {
  const SimulationResultCard({
    super.key,
    required this.result,
    this.showPathVisualization = true,
    this.showTransitionSequence = true,
    this.showExecutionMetrics = true,
    this.onStepTapped,
  });

  /// The simulation result to display.
  final SimulationResult result;

  /// Whether to show the path visualization section.
  final bool showPathVisualization;

  /// Whether to show the transition sequence.
  final bool showTransitionSequence;

  /// Whether to show execution metrics (time, steps).
  final bool showExecutionMetrics;

  /// Callback invoked when a step in the path is tapped.
  final ValueChanged<int>? onStepTapped;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final isAccepted = result.isAccepted;
    final color = isAccepted ? colorScheme.tertiary : colorScheme.error;

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        border: Border.all(color: color.withValues(alpha: 0.3)),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildHeader(context, color, isAccepted),
          if (showExecutionMetrics) ...[
            const SizedBox(height: 8),
            _buildMetrics(context),
          ],
          if (result.errorMessage.isNotEmpty || result.message != null) ...[
            const SizedBox(height: 8),
            _buildErrorMessage(context, colorScheme),
          ],
          if (showPathVisualization && result.steps.isNotEmpty) ...[
            const SizedBox(height: 12),
            _buildPathVisualization(context),
          ],
          if (showTransitionSequence &&
              result.transitionSequence.isNotEmpty) ...[
            const SizedBox(height: 12),
            _buildTransitionSequence(context),
          ],
        ],
      ),
    );
  }

  Widget _buildHeader(BuildContext context, Color color, bool isAccepted) {
    final l10n = appLocalizationsOf(context);
    return Row(
      children: [
        Icon(
          isAccepted ? Icons.check_circle : Icons.cancel,
          color: color,
          size: 20,
        ),
        const SizedBox(width: 8),
        Text(
          isAccepted ? l10n.accepted : l10n.rejected,
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            color: color,
            fontWeight: FontWeight.bold,
          ),
        ),
        const Spacer(),
        if (result.isTimeout)
          Chip(
            label: Text(
              l10n.timeout,
              style: Theme.of(context).textTheme.labelSmall,
            ),
            backgroundColor: color.withValues(alpha: 0.2),
            side: BorderSide.none,
            padding: EdgeInsets.zero,
            visualDensity: VisualDensity.compact,
          ),
        if (result.isInfiniteLoop)
          Chip(
            label: Text(
              l10n.infiniteLoop,
              style: Theme.of(context).textTheme.labelSmall,
            ),
            backgroundColor: color.withValues(alpha: 0.2),
            side: BorderSide.none,
            padding: EdgeInsets.zero,
            visualDensity: VisualDensity.compact,
          ),
      ],
    );
  }

  Widget _buildMetrics(BuildContext context) {
    final l10n = appLocalizationsOf(context);
    final formatter = LocaleValueFormatter.of(context);
    final textTheme = Theme.of(context).textTheme;
    final colorScheme = Theme.of(context).colorScheme;

    return Wrap(
      spacing: 16,
      runSpacing: 4,
      children: [
        _buildMetricChip(
          context,
          icon: Icons.route,
          label: l10n.steps,
          value: formatter.integer(result.stepCount),
          textTheme: textTheme,
          colorScheme: colorScheme,
        ),
        _buildMetricChip(
          context,
          icon: Icons.timer,
          label: l10n.time,
          value: _formatExecutionTime(context, result.executionTime),
          textTheme: textTheme,
          colorScheme: colorScheme,
        ),
        if (result.visitedStates.isNotEmpty)
          _buildMetricChip(
            context,
            icon: Icons.account_tree,
            label: l10n.states,
            value: formatter.integer(result.visitedStates.length),
            textTheme: textTheme,
            colorScheme: colorScheme,
          ),
      ],
    );
  }

  Widget _buildMetricChip(
    BuildContext context, {
    required IconData icon,
    required String label,
    required String value,
    required TextTheme textTheme,
    required ColorScheme colorScheme,
  }) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
          icon,
          size: 14,
          color: colorScheme.onSurface.withValues(alpha: 0.6),
        ),
        const SizedBox(width: 4),
        Text(
          '$label: ',
          style: textTheme.bodySmall?.copyWith(
            color: colorScheme.onSurface.withValues(alpha: 0.6),
          ),
        ),
        Text(
          value,
          style: textTheme.bodySmall?.copyWith(
            fontWeight: FontWeight.bold,
            fontFamilyFallback: kMonospaceFontFamilyFallback,
          ),
        ),
      ],
    );
  }

  Widget _buildErrorMessage(BuildContext context, ColorScheme colorScheme) {
    final l10n = appLocalizationsOf(context);
    final isLegacyFailure =
        result.message?.stableCode == 'simulation.legacy-failure';
    final errorText = result.message == null || isLegacyFailure
        ? l10n.localizeWorkflowText(result.errorMessage)
        : l10n.resolveStructuredMessage(result.message!);
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: colorScheme.errorContainer.withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Row(
        children: [
          Icon(Icons.error_outline, size: 16, color: colorScheme.error),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              errorText,
              style: Theme.of(
                context,
              ).textTheme.bodySmall?.copyWith(color: colorScheme.error),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPathVisualization(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final path = result.path;

    if (path.isEmpty) {
      return const SizedBox.shrink();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(Icons.timeline, size: 16, color: colorScheme.primary),
            const SizedBox(width: 6),
            Text(
              appLocalizationsOf(context).executionPath,
              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.w600,
                color: colorScheme.primary,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        _buildPathSteps(context, path, colorScheme),
      ],
    );
  }

  Widget _buildPathSteps(
    BuildContext context,
    List<String> path,
    ColorScheme colorScheme,
  ) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          for (int i = 0; i < path.length; i++) ...[
            _buildStateChip(
              context,
              state: path[i],
              stepIndex: i,
              isFirst: i == 0,
              isLast: i == path.length - 1,
              colorScheme: colorScheme,
            ),
            if (i < path.length - 1)
              _buildTransitionArrow(context, colorScheme),
          ],
        ],
      ),
    );
  }

  Widget _buildStateChip(
    BuildContext context, {
    required String state,
    required int stepIndex,
    required bool isFirst,
    required bool isLast,
    required ColorScheme colorScheme,
  }) {
    final isAccepted = result.isAccepted && isLast;
    final color = isFirst
        ? colorScheme.primary
        : (isLast
              ? (isAccepted ? colorScheme.tertiary : colorScheme.error)
              : colorScheme.secondary);

    final formattedState = state.isEmpty ? '∅' : state;

    return InkWell(
      onTap: onStepTapped != null ? () => onStepTapped!(stepIndex) : null,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.15),
          border: Border.all(color: color.withValues(alpha: 0.4), width: 1.5),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (isFirst)
              Icon(Icons.play_arrow, size: 14, color: color)
            else if (isLast)
              Icon(
                isAccepted ? Icons.check_circle : Icons.cancel,
                size: 14,
                color: color,
              )
            else
              Icon(Icons.circle, size: 8, color: color),
            const SizedBox(width: 4),
            Text(
              formattedState,
              style: Theme.of(context).textTheme.labelMedium?.copyWith(
                color: color,
                fontWeight: FontWeight.bold,
                fontFamilyFallback: kMonospaceFontFamilyFallback,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTransitionArrow(BuildContext context, ColorScheme colorScheme) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: Icon(
        Icons.arrow_forward,
        size: 16,
        color: colorScheme.onSurface.withValues(alpha: 0.4),
      ),
    );
  }

  Widget _buildTransitionSequence(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final transitions = result.transitionSequence;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(Icons.swap_horiz, size: 16, color: colorScheme.secondary),
            const SizedBox(width: 6),
            Text(
              appLocalizationsOf(context).transitions,
              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.w600,
                color: colorScheme.secondary,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: colorScheme.surfaceContainerHighest,
            borderRadius: BorderRadius.circular(4),
            border: Border.all(
              color: colorScheme.outline.withValues(alpha: 0.2),
            ),
          ),
          child: Wrap(
            spacing: 6,
            runSpacing: 6,
            children: transitions.map((transition) {
              final displayTransition = transition.isEmpty ? 'ε' : transition;
              return Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: colorScheme.secondaryContainer.withValues(alpha: 0.5),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: colorScheme.secondary.withValues(alpha: 0.3),
                  ),
                ),
                child: Text(
                  displayTransition,
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    fontFamilyFallback: kMonospaceFontFamilyFallback,
                    fontWeight: FontWeight.bold,
                    color: colorScheme.onSecondaryContainer,
                  ),
                ),
              );
            }).toList(),
          ),
        ),
      ],
    );
  }

  String _formatExecutionTime(BuildContext context, Duration duration) {
    final formatter = LocaleValueFormatter.of(context);
    if (duration.inMilliseconds < 1) {
      return '${formatter.integer(duration.inMicroseconds)}μs';
    } else if (duration.inMilliseconds < 1000) {
      return '${formatter.integer(duration.inMilliseconds)}ms';
    } else if (duration.inSeconds < 60) {
      final secondsToHundredths = duration.inMilliseconds ~/ 10 / 100;
      return '${formatter.decimal(secondsToHundredths, decimalDigits: 2)}s';
    } else {
      final minutes = duration.inMinutes;
      final seconds = duration.inSeconds % 60;
      return '${formatter.integer(minutes)}m ${formatter.integer(seconds)}s';
    }
  }
}
