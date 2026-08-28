//
//  algorithm_step_navigator.dart
//  Turing Lab
//
//  Navigation widget for step-by-step educational algorithm views.
//  Offers prev/next buttons, play/pause, a navigation slider, and a
//  step counter (Step X of Y), integrating with AlgorithmStepProvider
//  for centralized state.
//
//  Thales Matheus Mendonça Santos - January 2026
//
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../l10n/app_localizations_resolver.dart';
import '../providers/algorithm_step_provider.dart';

/// Widget for navigating through algorithm execution steps
///
/// Provides step-by-step navigation controls including previous/next buttons,
/// play/pause toggle, step slider, and step counter. Integrates with
/// AlgorithmStepProvider for centralized state management.
class AlgorithmStepNavigator extends ConsumerWidget {
  /// Optional callback when step changes
  final void Function(int stepIndex)? onStepChanged;

  /// Whether to show the step counter
  final bool showStepCounter;

  /// Whether to show the slider
  final bool showSlider;

  const AlgorithmStepNavigator({
    super.key,
    this.onStepChanged,
    this.showStepCounter = true,
    this.showSlider = true,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final stepState = ref.watch(algorithmStepProvider);
    final stepNotifier = ref.read(algorithmStepProvider.notifier);

    // Don't show navigator if there are no steps
    if (!stepState.hasSteps) {
      return const SizedBox.shrink();
    }

    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        border: Border(
          top: BorderSide(
            color: colorScheme.outline.withValues(alpha: 0.2),
            width: 1,
          ),
        ),
        boxShadow: [
          BoxShadow(
            color: colorScheme.shadow.withValues(alpha: 0.1),
            blurRadius: 4,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Step counter
          if (showStepCounter) ...[
            _buildStepCounter(context, stepState, colorScheme, textTheme),
            const SizedBox(height: 12),
          ],

          // Navigation controls
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Previous button
              _buildNavigationButton(
                context: context,
                icon: Icons.skip_previous,
                label: appLocalizationsOf(context).previous,
                onPressed: stepState.hasPreviousStep
                    ? () {
                        stepNotifier.previousStep();
                        _notifyStepChange(stepState.currentStepIndex - 1);
                      }
                    : null,
                colorScheme: colorScheme,
              ),
              const SizedBox(width: 8),

              // Play/Pause button
              _buildPlayPauseButton(
                context: context,
                stepState: stepState,
                stepNotifier: stepNotifier,
                colorScheme: colorScheme,
              ),
              const SizedBox(width: 8),

              // Next button
              _buildNavigationButton(
                context: context,
                icon: Icons.skip_next,
                label: appLocalizationsOf(context).next,
                onPressed: stepState.hasNextStep
                    ? () {
                        stepNotifier.nextStep();
                        _notifyStepChange(stepState.currentStepIndex + 1);
                      }
                    : null,
                colorScheme: colorScheme,
              ),
            ],
          ),

          // Step slider
          if (showSlider && stepState.totalSteps > 1) ...[
            const SizedBox(height: 12),
            _buildStepSlider(context, stepState, stepNotifier, colorScheme),
          ],
        ],
      ),
    );
  }

  /// Builds the step counter display
  Widget _buildStepCounter(
    BuildContext context,
    AlgorithmStepState stepState,
    ColorScheme colorScheme,
    TextTheme textTheme,
  ) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(Icons.pin_drop, size: 18, color: colorScheme.primary),
        const SizedBox(width: 8),
        Text(
          appLocalizationsOf(
            context,
          ).stepOf(stepState.currentStepNumber, stepState.totalSteps),
          style: textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
            color: colorScheme.onSurface,
          ),
        ),
      ],
    );
  }

  /// Builds a navigation button (previous/next)
  Widget _buildNavigationButton({
    required BuildContext context,
    required IconData icon,
    required String label,
    required VoidCallback? onPressed,
    required ColorScheme colorScheme,
  }) {
    return Tooltip(
      message: label,
      child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          backgroundColor: colorScheme.secondaryContainer,
          foregroundColor: colorScheme.onSecondaryContainer,
          disabledBackgroundColor: colorScheme.surfaceContainerHighest
              .withValues(alpha: 0.3),
          disabledForegroundColor: colorScheme.onSurface.withValues(alpha: 0.3),
          elevation: 0,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 20),
            const SizedBox(width: 4),
            Text(label, style: const TextStyle(fontWeight: FontWeight.w600)),
          ],
        ),
      ),
    );
  }

  /// Builds the play/pause button
  Widget _buildPlayPauseButton({
    required BuildContext context,
    required AlgorithmStepState stepState,
    required AlgorithmStepNotifier stepNotifier,
    required ColorScheme colorScheme,
  }) {
    final isPlaying = stepState.isPlaying;
    final canPlay = !stepState.isAtLastStep;

    return Tooltip(
      message: isPlaying
          ? appLocalizationsOf(context).pause
          : appLocalizationsOf(context).play,
      child: ElevatedButton(
        onPressed: canPlay || isPlaying
            ? () {
                stepNotifier.togglePlayPause();
              }
            : null,
        style: ElevatedButton.styleFrom(
          padding: const EdgeInsets.all(16),
          backgroundColor: colorScheme.primaryContainer,
          foregroundColor: colorScheme.onPrimaryContainer,
          disabledBackgroundColor: colorScheme.surfaceContainerHighest
              .withValues(alpha: 0.3),
          disabledForegroundColor: colorScheme.onSurface.withValues(alpha: 0.3),
          elevation: 0,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
        child: Icon(isPlaying ? Icons.pause : Icons.play_arrow, size: 24),
      ),
    );
  }

  /// Builds the step slider
  Widget _buildStepSlider(
    BuildContext context,
    AlgorithmStepState stepState,
    AlgorithmStepNotifier stepNotifier,
    ColorScheme colorScheme,
  ) {
    return Row(
      children: [
        // First step button
        IconButton(
          onPressed: !stepState.isAtFirstStep
              ? () {
                  stepNotifier.jumpToFirstStep();
                  _notifyStepChange(0);
                }
              : null,
          icon: const Icon(Icons.first_page),
          iconSize: 20,
          color: colorScheme.primary,
          disabledColor: colorScheme.onSurface.withValues(alpha: 0.3),
          tooltip: appLocalizationsOf(context).firstStep,
        ),

        // Slider
        Expanded(
          child: SliderTheme(
            data: SliderTheme.of(context).copyWith(
              activeTrackColor: colorScheme.primary,
              inactiveTrackColor: colorScheme.surfaceContainerHighest,
              thumbColor: colorScheme.primary,
              overlayColor: colorScheme.primary.withValues(alpha: 0.2),
              valueIndicatorColor: colorScheme.primary,
              // Derived from the theme so the indicator keeps the app's
              // typography instead of falling back to the default font.
              valueIndicatorTextStyle:
                  (Theme.of(context).textTheme.labelMedium ?? const TextStyle())
                      .copyWith(
                        color: colorScheme.onPrimary,
                        fontWeight: FontWeight.bold,
                      ),
            ),
            child: Semantics(
              slider: true,
              label: appLocalizationsOf(context).timelineScrubber,
              value: appLocalizationsOf(
                context,
              ).stepOf(stepState.currentStepNumber, stepState.totalSteps),
              hint: appLocalizationsOf(context).timelineNavigationHint,
              child: Slider(
                value: stepState.currentStepIndex.toDouble(),
                min: 0,
                max: (stepState.totalSteps - 1).toDouble(),
                divisions: stepState.totalSteps > 1
                    ? stepState.totalSteps - 1
                    : 1,
                label: appLocalizationsOf(
                  context,
                ).stepNumberLabel(stepState.currentStepNumber),
                onChanged: (value) {
                  final newIndex = value.toInt();
                  stepNotifier.jumpToStep(newIndex);
                  _notifyStepChange(newIndex);
                },
              ),
            ),
          ),
        ),

        // Last step button
        IconButton(
          onPressed: !stepState.isAtLastStep
              ? () {
                  stepNotifier.jumpToLastStep();
                  _notifyStepChange(stepState.totalSteps - 1);
                }
              : null,
          icon: const Icon(Icons.last_page),
          iconSize: 20,
          color: colorScheme.primary,
          disabledColor: colorScheme.onSurface.withValues(alpha: 0.3),
          tooltip: appLocalizationsOf(context).lastStep,
        ),
      ],
    );
  }

  /// Notifies the step change callback if provided
  void _notifyStepChange(int stepIndex) {
    onStepChanged?.call(stepIndex);
  }
}
