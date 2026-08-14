//
//  conversion_history_provider.dart
//  Turing Lab
//
//  Preserves conversion workflow history (algorithm steps + before/after
//  snapshots) so UI can provide before/after comparisons and step review.
//
//  This is intentionally lightweight and generic: snapshots are stored as
//  JSON-like maps and the provider does not try to interpret them.
//

import 'dart:math';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/models/algorithm_step.dart';
import '../../core/models/conversion_step_history.dart';

class ConversionHistoryState {
  final ConversionHistory? history;
  final bool isLoading;
  final String? error;

  const ConversionHistoryState({
    this.history,
    this.isLoading = false,
    this.error,
  });

  static const _unset = Object();

  ConversionHistoryState copyWith({
    Object? history = _unset,
    bool? isLoading,
    Object? error = _unset,
  }) {
    return ConversionHistoryState(
      history: history == _unset ? this.history : history as ConversionHistory?,
      isLoading: isLoading ?? this.isLoading,
      error: error == _unset ? this.error : error as String?,
    );
  }

  ConversionHistoryState clear() => const ConversionHistoryState();
}

class ConversionHistoryNotifier extends StateNotifier<ConversionHistoryState> {
  ConversionHistoryNotifier() : super(const ConversionHistoryState());

  void startNewSession({
    required AlgorithmType algorithmType,
    Map<String, dynamic>? initialSnapshot,
    String? sessionId,
  }) {
    state = state.copyWith(
      history: ConversionHistory(
        id: sessionId ?? _randomId('conv'),
        algorithmType: algorithmType,
        steps: const [],
        initialSnapshot: initialSnapshot,
        finalSnapshot: null,
      ),
      isLoading: false,
      error: null,
    );
  }

  void setFinalSnapshot(Map<String, dynamic>? snapshot) {
    final history = state.history;
    if (history == null) return;

    state = state.copyWith(history: history.copyWith(finalSnapshot: snapshot));
  }

  void addStep({
    required AlgorithmStep algorithmStep,
    Map<String, dynamic>? beforeSnapshot,
    Map<String, dynamic>? afterSnapshot,
    Map<String, Map<String, dynamic>> auxiliarySnapshots = const {},
    String? stepId,
  }) {
    final history = state.history;
    if (history == null) return;

    final newStepNumber = history.steps.length;
    final entry = ConversionHistoryStep(
      id: stepId ?? _randomId('step'),
      stepNumber: newStepNumber,
      algorithmStep: algorithmStep,
      beforeSnapshot: beforeSnapshot,
      afterSnapshot: afterSnapshot,
      auxiliarySnapshots: auxiliarySnapshots,
      timestamp: DateTime.now(),
    );

    state = state.copyWith(
      history: history.copyWith(steps: [...history.steps, entry]),
      error: null,
    );
  }

  void clear() {
    state = state.clear();
  }

  static String _randomId(String prefix) {
    // Deterministic uniqueness is not required; this is for UI session tracking.
    final r = Random();
    final n = r.nextInt(1 << 32).toRadixString(16).padLeft(8, '0');
    return '$prefix-$n';
  }
}

final conversionHistoryProvider =
    StateNotifierProvider<ConversionHistoryNotifier, ConversionHistoryState>(
  (ref) => ConversionHistoryNotifier(),
);
