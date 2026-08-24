//
//  algorithm_step_provider.dart
//  Turing Lab
//
//  Manages step-by-step navigation during educational algorithm
//  execution, letting the user step forward, backward, and pause to
//  understand each automata conversion stage.
//
//  Thales Matheus Mendonça Santos - January 2026
//
import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/models/algorithm_step.dart';
import '../../core/models/simulation_highlight.dart';
import '../../core/services/algorithm_step_highlight_extractor.dart';

/// State for algorithm step navigation
class AlgorithmStepState {
  final List<AlgorithmStep> steps;
  final int currentStepIndex;
  final bool isPlaying;
  final bool isLoading;
  final String? error;
  final bool isHistoryVisible;

  const AlgorithmStepState({
    this.steps = const [],
    this.currentStepIndex = 0,
    this.isPlaying = false,
    this.isLoading = false,
    this.error,
    this.isHistoryVisible = false,
  });

  static const _unset = Object();

  AlgorithmStepState copyWith({
    List<AlgorithmStep>? steps,
    int? currentStepIndex,
    bool? isPlaying,
    bool? isLoading,
    Object? error = _unset,
    bool? isHistoryVisible,
  }) {
    return AlgorithmStepState(
      steps: steps ?? this.steps,
      currentStepIndex: currentStepIndex ?? this.currentStepIndex,
      isPlaying: isPlaying ?? this.isPlaying,
      isLoading: isLoading ?? this.isLoading,
      error: error == _unset ? this.error : error as String?,
      isHistoryVisible: isHistoryVisible ?? this.isHistoryVisible,
    );
  }

  /// Clear all steps and reset to initial state
  AlgorithmStepState clear() {
    return const AlgorithmStepState();
  }

  /// Clear only error state
  AlgorithmStepState clearError() {
    return copyWith(error: null);
  }

  /// Get the current step, if any
  AlgorithmStep? get currentStep {
    if (currentStepIndex >= 0 && currentStepIndex < steps.length) {
      return steps[currentStepIndex];
    }
    return null;
  }

  /// Check if there is a next step
  bool get hasNextStep => currentStepIndex < steps.length - 1;

  /// Check if there is a previous step
  bool get hasPreviousStep => currentStepIndex > 0;

  /// Check if at the first step
  bool get isAtFirstStep => currentStepIndex == 0;

  /// Check if at the last step
  bool get isAtLastStep => currentStepIndex == steps.length - 1;

  /// Check if there are any steps
  bool get hasSteps => steps.isNotEmpty;

  /// Get total number of steps
  int get totalSteps => steps.length;

  /// Get current step number (1-indexed for display)
  int get currentStepNumber => currentStepIndex + 1;

  /// Computes highlight information for the current algorithm step
  SimulationHighlight getCurrentStepHighlight() {
    final step = currentStep;
    if (step == null || step.properties.isEmpty) {
      return SimulationHighlight.empty;
    }

    return extractHighlightFromProperties(step.properties);
  }
}

/// Extracts state and transition IDs from step properties
SimulationHighlight extractHighlightFromProperties(
  Map<String, dynamic> properties,
) {
  return extractAlgorithmStepHighlight(properties);
}

void _logStepEvent(String message) {
  if (kDebugMode) {
    debugPrint('[AlgorithmStepProvider] $message');
  }
}

/// Provider for algorithm step navigation
class AlgorithmStepNotifier extends StateNotifier<AlgorithmStepState> {
  final Ref ref;
  Timer? _autoPlayTimer;

  /// Duration between auto-play steps (2 seconds)
  static const Duration _autoPlayInterval = Duration(seconds: 2);

  AlgorithmStepNotifier(this.ref) : super(const AlgorithmStepState());

  /// Initialize steps for an algorithm execution
  void initializeSteps(List<AlgorithmStep> steps) {
    if (steps.isEmpty) {
      state = state.copyWith(error: 'Cannot initialize with empty steps list');
      return;
    }

    state = state.copyWith(
      steps: steps,
      currentStepIndex: 0,
      isPlaying: false,
      error: null,
    );
  }

  /// Navigate to the next step
  void nextStep() {
    if (!state.hasNextStep) return;

    state = state.copyWith(
      currentStepIndex: state.currentStepIndex + 1,
      error: null,
    );
  }

  /// Navigate to the previous step
  void previousStep() {
    if (!state.hasPreviousStep) return;

    state = state.copyWith(
      currentStepIndex: state.currentStepIndex - 1,
      error: null,
    );
  }

  /// Jump to a specific step by index
  void jumpToStep(int index) {
    if (index < 0 || index >= state.steps.length) {
      state = state.copyWith(error: 'Invalid step index: $index');
      return;
    }

    state = state.copyWith(currentStepIndex: index, error: null);
  }

  /// Jump to the first step
  void jumpToFirstStep() {
    if (!state.hasSteps) return;

    state = state.copyWith(currentStepIndex: 0, error: null);
  }

  /// Jump to the last step
  void jumpToLastStep() {
    if (!state.hasSteps) return;

    state = state.copyWith(
      currentStepIndex: state.steps.length - 1,
      error: null,
    );
  }

  /// Start auto-playing through steps
  void play() {
    if (!state.hasSteps) return;

    state = state.copyWith(isPlaying: true, error: null);
    _startAutoPlay();
  }

  /// Pause auto-playing
  void pause() {
    _stopAutoPlay();
    state = state.copyWith(isPlaying: false, error: null);
  }

  /// Start the auto-play timer
  void _startAutoPlay() {
    _stopAutoPlay();
    _autoPlayTimer = Timer.periodic(_autoPlayInterval, (_) {
      if (state.hasNextStep) {
        nextStep();
        _logStepEvent('Auto-play: advanced to step ${state.currentStepNumber}');
      } else {
        // Reached the last step, pause automatically
        _logStepEvent('Auto-play: reached last step, pausing');
        pause();
      }
    });
  }

  /// Stop the auto-play timer
  void _stopAutoPlay() {
    _autoPlayTimer?.cancel();
    _autoPlayTimer = null;
  }

  /// Toggle play/pause
  void togglePlayPause() {
    if (state.isPlaying) {
      pause();
    } else {
      play();
    }
  }

  /// Toggle history panel visibility
  void toggleHistory() {
    state = state.copyWith(isHistoryVisible: !state.isHistoryVisible);
  }

  /// Reset to initial state
  void reset() {
    _stopAutoPlay();
    state = state.copyWith(currentStepIndex: 0, isPlaying: false, error: null);
  }

  /// Clear all steps and reset
  void clearSteps() {
    _stopAutoPlay();
    state = state.clear();
  }

  /// Clear only error state
  void clearError() {
    state = state.clearError();
  }

  /// Computes highlight information for the current step
  SimulationHighlight computeCurrentStepHighlight() {
    final highlight = state.getCurrentStepHighlight();
    _logStepEvent(
      'Computed highlight for step ${state.currentStepNumber} '
      '(states: ${highlight.stateIds.length}, transitions: ${highlight.transitionIds.length})',
    );
    return highlight;
  }

  /// Gets the highlight for a specific step index
  SimulationHighlight computeStepHighlight(int stepIndex) {
    if (stepIndex < 0 || stepIndex >= state.steps.length) {
      _logStepEvent(
        'Cannot compute highlight for invalid step index: $stepIndex',
      );
      return SimulationHighlight.empty;
    }

    final step = state.steps[stepIndex];
    if (step.properties.isEmpty) {
      return SimulationHighlight.empty;
    }

    final highlight = extractHighlightFromProperties(step.properties);
    _logStepEvent(
      'Computed highlight for step ${stepIndex + 1} '
      '(states: ${highlight.stateIds.length}, transitions: ${highlight.transitionIds.length})',
    );
    return highlight;
  }

  @override
  void dispose() {
    _stopAutoPlay();
    super.dispose();
  }
}

/// Provider registration for algorithm step navigation
final algorithmStepProvider =
    StateNotifierProvider<AlgorithmStepNotifier, AlgorithmStepState>(
  (ref) => AlgorithmStepNotifier(ref),
);
