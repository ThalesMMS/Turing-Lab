//
//  step_navigation_controls.dart
//  Turing Lab
//
//  Reusable widget for step-by-step algorithm navigation controls.
//  Provides play/pause buttons, previous/next navigation, a step counter,
//  and a playback-speed slider.
//  Used in educational views of algorithms such as NFA→DFA, DFA
//  minimization, and FA→Regex conversion.
//
//  Thales Matheus Mendonça Santos - January 2026
//
import 'package:flutter/material.dart';

import '../../l10n/app_localizations_resolver.dart';
import '../../core/constants/monospace_typography.dart';
import '../localization/locale_value_formatter.dart';

/// Widget for step-by-step navigation controls
class StepNavigationControls extends StatelessWidget {
  final int currentStepIndex;
  final int totalSteps;
  final bool isPlaying;
  final double playbackSpeed;
  final VoidCallback? onPrevious;
  final VoidCallback? onPlayPause;
  final VoidCallback? onNext;
  final VoidCallback? onReset;
  final ValueChanged<double>? onSpeedChanged;

  const StepNavigationControls({
    super.key,
    required this.currentStepIndex,
    required this.totalSteps,
    required this.isPlaying,
    this.playbackSpeed = 1.0,
    this.onPrevious,
    this.onPlayPause,
    this.onNext,
    this.onReset,
    this.onSpeedChanged,
  });

  @override
  Widget build(BuildContext context) {
    final canGoPrevious = currentStepIndex > 0 && onPrevious != null;
    final canGoNext = currentStepIndex < totalSteps - 1 && onNext != null;
    final l10n = appLocalizationsOf(context);
    final valueFormatter = LocaleValueFormatter.of(context);
    String formatPlaybackSpeed(double value) =>
        '${valueFormatter.decimal(value)}x';
    final formattedPlaybackSpeed = formatPlaybackSpeed(playbackSpeed);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Main navigation row
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Previous button
            IconButton(
              onPressed: canGoPrevious ? onPrevious : null,
              icon: const Icon(Icons.skip_previous),
              tooltip: appLocalizationsOf(context).previousStep,
              iconSize: 32,
            ),
            const SizedBox(width: 8),

            // Play/Pause button
            IconButton(
              onPressed: onPlayPause,
              icon: Icon(isPlaying ? Icons.pause : Icons.play_arrow),
              tooltip: isPlaying
                  ? appLocalizationsOf(context).pause
                  : appLocalizationsOf(context).play,
              iconSize: 40,
              color: Theme.of(context).colorScheme.primary,
            ),
            const SizedBox(width: 8),

            // Next button
            IconButton(
              onPressed: canGoNext ? onNext : null,
              icon: const Icon(Icons.skip_next),
              tooltip: appLocalizationsOf(context).nextStep,
              iconSize: 32,
            ),
            const SizedBox(width: 16),

            // Step counter
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: Theme.of(
                  context,
                ).colorScheme.primaryContainer.withValues(alpha: 0.5),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: Theme.of(
                    context,
                  ).colorScheme.primary.withValues(alpha: 0.3),
                ),
              ),
              child: Text(
                appLocalizationsOf(context).stepNavigationPosition(
                  totalSteps > 0 ? currentStepIndex + 1 : 0,
                  totalSteps,
                ),
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).colorScheme.onPrimaryContainer,
                ),
              ),
            ),

            // Spacer
            const Spacer(),

            // Reset button
            if (onReset != null)
              IconButton(
                onPressed: onReset,
                icon: const Icon(Icons.refresh),
                tooltip: appLocalizationsOf(context).resetToFirstStep,
                iconSize: 24,
              ),
          ],
        ),

        // Speed control
        if (onSpeedChanged != null) ...[
          const SizedBox(height: 12),
          Row(
            children: [
              Icon(
                Icons.speed,
                size: 20,
                color: Theme.of(
                  context,
                ).colorScheme.onSurface.withValues(alpha: 0.6),
              ),
              const SizedBox(width: 8),
              Text(
                appLocalizationsOf(context).speed,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Theme.of(
                    context,
                  ).colorScheme.onSurface.withValues(alpha: 0.7),
                ),
              ),
              Expanded(
                child: MergeSemantics(
                  child: Semantics(
                    label: l10n.selectPlaybackSpeed,
                    child: Slider(
                      value: playbackSpeed,
                      min: 0.25,
                      max: 4.0,
                      divisions: 15,
                      label: formattedPlaybackSpeed,
                      semanticFormatterCallback: formatPlaybackSpeed,
                      onChanged: onSpeedChanged,
                    ),
                  ),
                ),
              ),
              SizedBox(
                width: 40,
                child: Text(
                  formattedPlaybackSpeed,
                  textAlign: TextAlign.right,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    fontFamilyFallback: kMonospaceFontFamilyFallback,
                    color: Theme.of(
                      context,
                    ).colorScheme.onSurface.withValues(alpha: 0.7),
                  ),
                ),
              ),
            ],
          ),
        ],
      ],
    );
  }
}
