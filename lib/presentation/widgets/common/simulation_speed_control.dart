//
//  simulation_speed_control.dart
//  Turing Lab
//
//  Widget de controle de velocidade de animação para simulações passo a passo.
//  Provê seleção rápida entre velocidades predefinidas (0.25x, 0.5x, 1x, 2x, 4x)
//  com feedback visual claro e integração com SettingsModel. Garante experiência
//  consistente em todas as visualizações de traços (FA, PDA, TM).
//
//  Thales Matheus Mendonça Santos - January 2026
//

import 'package:flutter/material.dart';

import '../../../l10n/app_localizations.dart';
import '../../../l10n/app_localizations_resolver.dart';

/// Control widget for adjusting simulation animation speed.
///
/// This widget provides a compact interface for selecting animation playback
/// speed during step-by-step simulation. It displays predefined speed options
/// (0.25x, 0.5x, 1x, 2x, 4x) and notifies listeners when the user changes
/// the selected speed.
///
/// Features:
/// - Five predefined speed multipliers for common use cases
/// - Clear visual indication of current selection
/// - Compact chip-based UI suitable for toolbar placement
/// - Accessibility semantics for screen readers
/// - Material 3 theming integration
///
/// Example:
/// ```dart
/// SimulationSpeedControl(
///   currentSpeed: settings.animationSpeed,
///   onSpeedChanged: (speed) {
///     settingsNotifier.updateSpeed(speed);
///   },
/// )
/// ```
class SimulationSpeedControl extends StatelessWidget {
  const SimulationSpeedControl({
    super.key,
    required this.currentSpeed,
    required this.onSpeedChanged,
  })  : assert(currentSpeed > 0, 'currentSpeed must be positive'),
        assert(
          currentSpeed >= 0.25 && currentSpeed <= 4.0,
          'currentSpeed should be between 0.25 and 4.0',
        );

  /// Current animation speed multiplier.
  ///
  /// Expected to be one of the predefined values: 0.25, 0.5, 1.0, 2.0, 4.0.
  /// If the current value doesn't match exactly, the closest option will
  /// be visually highlighted.
  final double currentSpeed;

  /// Callback invoked when the user selects a new speed.
  ///
  /// The callback receives the selected speed multiplier as a parameter.
  final ValueChanged<double> onSpeedChanged;

  /// Available speed options from slowest to fastest.
  static const List<double> _speedOptions = [0.25, 0.5, 1.0, 2.0, 4.0];

  /// Format speed value for display (e.g., "1.0x", "0.5x", "2.0x").
  static String _formatSpeed(double speed) {
    if (speed == speed.toInt()) {
      return '${speed.toInt()}x';
    }
    return '${speed}x';
  }

  /// Get semantic label for a speed value.
  static String _getSpeedLabel(AppLocalizations l10n, double speed) {
    if (speed < 1.0) {
      return l10n.slowSpeed(_formatSpeed(speed));
    } else if (speed == 1.0) {
      return l10n.normalSpeed;
    } else {
      return l10n.fastSpeed(_formatSpeed(speed));
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final l10n = appLocalizationsOf(context);

    return Semantics(
      label: l10n.animationSpeed,
      value: _getSpeedLabel(l10n, currentSpeed),
      hint: l10n.selectPlaybackSpeed,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.speed, size: 16, color: colorScheme.onSurfaceVariant),
          const SizedBox(width: 8),
          Text(
            l10n.speed,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                ),
          ),
          const SizedBox(width: 8),
          ..._speedOptions.map(
            (speed) => _buildSpeedChip(context, speed, colorScheme),
          ),
        ],
      ),
    );
  }

  Widget _buildSpeedChip(
    BuildContext context,
    double speed,
    ColorScheme colorScheme,
  ) {
    // Consider speeds within 0.01 as equal for floating-point comparison
    final isSelected = (speed - currentSpeed).abs() < 0.01;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 2),
      child: Semantics(
        label: _getSpeedLabel(appLocalizationsOf(context), speed),
        selected: isSelected,
        button: true,
        child: InkWell(
          onTap: () => onSpeedChanged(speed),
          borderRadius: BorderRadius.circular(12),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: isSelected
                  ? colorScheme.primaryContainer
                  : colorScheme.surfaceContainerHighest,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: isSelected
                    ? colorScheme.primary
                    : colorScheme.outline.withValues(alpha: 0.3),
                width: isSelected ? 1.5 : 1,
              ),
            ),
            child: Text(
              _formatSpeed(speed),
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    color: isSelected
                        ? colorScheme.onPrimaryContainer
                        : colorScheme.onSurfaceVariant,
                    fontWeight:
                        isSelected ? FontWeight.bold : FontWeight.normal,
                  ),
            ),
          ),
        ),
      ),
    );
  }
}
