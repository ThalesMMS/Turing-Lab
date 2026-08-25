//
//  app_store_capture_timeout.dart
//  Turing Lab
//
//  Error raised when a bounded capture stage never reaches the state it waits
//  for, carrying the pending condition so diagnostics can name it.
//
//  Thales Matheus Mendonça Santos - August 2026
//

/// Raised when a bounded capture wait exhausts its budget.
class AppStoreCaptureTimeout implements Exception {
  const AppStoreCaptureTimeout({
    required this.stage,
    required this.pending,
    required this.budget,
  });

  /// Name of the capture stage that timed out.
  final String stage;

  /// Condition the stage was still waiting for.
  final String pending;

  /// Human readable description of the exhausted budget.
  final String budget;

  @override
  String toString() =>
      'AppStoreCaptureTimeout in "$stage": $pending (budget: $budget)';
}
