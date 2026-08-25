//
//  language_comparison_semantics.dart
//  Turing Lab
//
//  Stable, locale-independent identifiers and widget keys for the language
//  comparison surface. Screen readers get localized labels while tests and
//  end-to-end automation address the same elements through these keys, so
//  coverage does not depend on display strings or their capitalization.
//
//  Thales Matheus Mendonça Santos - August 2026
//
import 'package:flutter/widgets.dart';

import '../../core/models/language_comparison_outcome.dart';

/// Namespace of the semantic identifiers the comparison surface publishes.
class LanguageComparisonSemantics {
  const LanguageComparisonSemantics._();

  /// Verdict badge: equivalent, not equivalent, inconclusive or error.
  static const String status = 'language-comparison-status';

  /// Distinguishing string that witnesses non-equivalence.
  static const String witness = 'language-comparison-witness';

  /// Explanation shown when the comparison could not decide.
  static const String error = 'language-comparison-error';

  /// State and transition counts of both inputs.
  static const String statistics = 'language-comparison-statistics';

  static const String canvasA = 'language-comparison-canvas-a';
  static const String canvasB = 'language-comparison-canvas-b';
  static const String productCanvas = 'language-comparison-canvas-product';

  /// Row that carries the step position and its two navigation buttons.
  static const String stepNavigation = 'language-comparison-step-navigation';
  static const String previousStep = 'language-comparison-previous-step';
  static const String nextStep = 'language-comparison-next-step';

  /// Card describing the step currently selected.
  static const String selectedStep = 'language-comparison-selected-step';

  /// Key of the verdict badge, carrying the status it is reporting.
  static ValueKey<String> statusKey(LanguageComparisonStatus status) =>
      ValueKey<String>('language-comparison-status-${status.semanticsValue}');

  /// Key of the failure panel, carrying the reason the comparison stopped.
  static ValueKey<String> failureKey(LanguageComparisonFailureReason reason) =>
      ValueKey<String>('language-comparison-failure-${reason.name}');

  /// Key of the automata arrangement, so tests can tell the wide and compact
  /// presentations apart without measuring pixels.
  static ValueKey<String> layoutKey({required bool isStacked}) =>
      ValueKey<String>(
        isStacked
            ? 'language-comparison-layout-stacked'
            : 'language-comparison-layout-side-by-side',
      );

  /// Key of the step card for the step at [index] of the trace.
  static ValueKey<String> stepKey(int index) =>
      ValueKey<String>('language-comparison-step-$index');
}
