//
//  automaton_simulation_provider.dart
//  Turing Lab
//
//  Manages finite-automaton simulation operations, coordinating step
//  execution, trace persistence, and simulation history. Integrates the
//  core simulator with presentation services while keeping CRUD state
//  operations in AutomatonStateProvider.
//
//  Thales Matheus Mendonça Santos - January 2026
//
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/algorithms/automaton_simulator.dart';
import '../../core/messages/structured_message.dart';
import '../../core/models/simulation_result.dart';
import '../../core/repositories/trace_repository.dart';
import 'automaton_state_provider.dart';
import 'unified_trace_provider.dart';

/// State for simulation operations
class SimulationState {
  final SimulationResult? simulationResult;
  final List<SimulationResult> simulationHistory;
  final bool isLoading;
  final String? error;
  final StructuredMessage? structuredError;

  const SimulationState({
    this.simulationResult,
    this.simulationHistory = const [],
    this.isLoading = false,
    this.error,
    this.structuredError,
  });

  static const _unset = Object();

  SimulationState copyWith({
    Object? simulationResult = _unset,
    List<SimulationResult>? simulationHistory,
    bool? isLoading,
    Object? error = _unset,
    Object? structuredError = _unset,
  }) {
    return SimulationState(
      simulationResult: simulationResult == _unset
          ? this.simulationResult
          : simulationResult as SimulationResult?,
      simulationHistory: simulationHistory ?? this.simulationHistory,
      isLoading: isLoading ?? this.isLoading,
      error: error == _unset ? this.error : error as String?,
      structuredError: structuredError == _unset
          ? this.structuredError
          : structuredError as StructuredMessage?,
    );
  }

  /// Clear all simulation results
  SimulationState clear() {
    return const SimulationState();
  }

  /// Clear only error state
  SimulationState clearError() {
    return copyWith(error: null, structuredError: null);
  }

  /// Clear simulation results but keep history
  SimulationState clearSimulation() {
    return copyWith(simulationResult: null, simulationHistory: []);
  }
}

/// Provider for automaton simulation operations
class AutomatonSimulationNotifier extends StateNotifier<SimulationState> {
  final Ref ref;
  final TraceRepository _tracePersistenceService;
  int _requestVersion = 0;

  AutomatonSimulationNotifier({
    required this.ref,
    required TraceRepository tracePersistenceService,
  }) : _tracePersistenceService = tracePersistenceService,
       super(const SimulationState()) {
    // Listen to automaton state changes and clear simulation when automaton changes
    ref.listen<AutomatonStateProviderState>(automatonStateProvider, (
      previous,
      next,
    ) {
      // Clear simulation results when the automaton changes
      final previousAutomaton = previous?.currentAutomaton;
      final nextAutomaton = next.currentAutomaton;
      if (!identical(previousAutomaton, nextAutomaton)) {
        _requestVersion++;
        state = state.clear();
      }
    });
  }

  /// Simulates the current automaton with input string
  Future<void> simulateAutomaton(String inputString) async {
    final sourceState = ref.read(automatonStateProvider);
    final currentAutomaton = sourceState.currentAutomaton;
    if (currentAutomaton == null) return;
    final requestVersion = ++_requestVersion;
    final documentGeneration = sourceState.documentGeneration;

    state = state.copyWith(isLoading: true, error: null, structuredError: null);

    try {
      final result = await AutomatonSimulator.simulate(
        currentAutomaton,
        inputString,
        stepByStep: true,
        timeout: const Duration(seconds: 5),
      );

      if (!_isCurrentRequest(requestVersion, documentGeneration)) return;

      if (result.isSuccess) {
        _addSimulationToHistory(result.data!);
        state = state.copyWith(simulationResult: result.data, isLoading: false);
      } else {
        state = state.copyWith(
          isLoading: false,
          error: result.error,
          structuredError: result.structuredError,
        );
      }
    } catch (e) {
      if (!_isCurrentRequest(requestVersion, documentGeneration)) return;
      state = state.copyWith(
        isLoading: false,
        error: 'Error simulating automaton: $e',
        structuredError: null,
      );
    }
  }

  bool _isCurrentRequest(int requestVersion, int documentGeneration) {
    final current = ref.read(automatonStateProvider);
    return requestVersion == _requestVersion &&
        current.documentGeneration == documentGeneration;
  }

  /// Clear simulation results
  void clearSimulation() {
    state = state.clearSimulation();
  }

  /// Add simulation result to history
  void _addSimulationToHistory(SimulationResult result) {
    final newHistory = [...state.simulationHistory, result];
    state = state.copyWith(simulationHistory: newHistory);

    // Also save to trace persistence service
    _tracePersistenceService.saveTraceToHistory(result).catchError((error) {
      // Silently fail - trace persistence is a nice-to-have feature
      debugPrint('Failed to persist simulation trace: $error');
    });
  }

  /// Get simulation result from history
  SimulationResult? getSimulationFromHistory(int index) {
    if (index < 0 || index >= state.simulationHistory.length) return null;
    return state.simulationHistory[index];
  }
}

/// Provider registration for automaton simulation operations
final automatonSimulationProvider =
    StateNotifierProvider<AutomatonSimulationNotifier, SimulationState>((ref) {
      final persistenceService = ref.watch(dataTracePersistenceServiceProvider);
      return AutomatonSimulationNotifier(
        ref: ref,
        tracePersistenceService: persistenceService,
      );
    });
