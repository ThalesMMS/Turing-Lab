import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:turing_lab/presentation/theme/app_theme.dart';

double _contrastRatio(Color foreground, Color background) {
  final foregroundLuminance = foreground.computeLuminance();
  final backgroundLuminance = background.computeLuminance();
  final lighter = foregroundLuminance > backgroundLuminance
      ? foregroundLuminance
      : backgroundLuminance;
  final darker = foregroundLuminance > backgroundLuminance
      ? backgroundLuminance
      : foregroundLuminance;
  return (lighter + 0.05) / (darker + 0.05);
}

void _expectAaContrast(Color foreground, Color background) {
  expect(_contrastRatio(foreground, background), greaterThanOrEqualTo(4.5));
}

void main() {
  group('AppTheme contrast', () {
    test('light theme keeps small text and snackbar pairs AA compliant', () {
      final theme = AppTheme.lightTheme;
      final colorScheme = theme.colorScheme;

      _expectAaContrast(
        theme.textTheme.bodySmall!.color!,
        colorScheme.surface,
      );
      _expectAaContrast(
        theme.textTheme.labelSmall!.color!,
        colorScheme.surface,
      );
      _expectAaContrast(
        colorScheme.onErrorContainer,
        colorScheme.errorContainer,
      );
      _expectAaContrast(
        colorScheme.onTertiaryContainer,
        colorScheme.tertiaryContainer,
      );
    });

    test('dark theme keeps small text and snackbar pairs AA compliant', () {
      final theme = AppTheme.darkTheme;
      final colorScheme = theme.colorScheme;

      _expectAaContrast(
        theme.textTheme.bodySmall!.color!,
        colorScheme.surface,
      );
      _expectAaContrast(
        theme.textTheme.labelSmall!.color!,
        colorScheme.surface,
      );
      _expectAaContrast(
        colorScheme.onErrorContainer,
        colorScheme.errorContainer,
      );
      _expectAaContrast(
        colorScheme.onTertiaryContainer,
        colorScheme.tertiaryContainer,
      );
    });
  });
}
