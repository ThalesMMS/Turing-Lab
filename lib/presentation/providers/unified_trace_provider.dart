//
//  unified_trace_provider.dart
//  Turing Lab
//
//  Consolida a gestão de traços de simulação para diferentes autômatos,
//  administrando histórico persistido, contexto ativo e estatísticas
//  compartilhadas entre módulos enquanto coordena carregamento lazily, navegação
//  por passos e tratamento de erros de persistência.
//
//  Thales Matheus Mendonça Santos - October 2025
//
import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/models/simulation_result.dart';
import '../../core/models/simulation_step.dart';
import '../../core/repositories/trace_repository.dart';
import '../../injection/data_providers.dart';
import 'trace_step_navigation.dart';

export '../../injection/data_providers.dart' show sharedPreferencesProvider;

Map<String, dynamic> _deepUnmodifiableMap(Map<String, dynamic> source) {
  return Map<String, dynamic>.unmodifiable(
    source.map(
      (key, value) => MapEntry<String, dynamic>(key, _deepFreezeValue(value)),
    ),
  );
}

List<Map<String, dynamic>> _deepUnmodifiableTraceList(
  List<Map<String, dynamic>> traces,
) {
  return List<Map<String, dynamic>>.unmodifiable(
    traces.map(_deepUnmodifiableMap),
  );
}

dynamic _deepFreezeValue(dynamic value) {
  if (value is Map) {
    final map = <String, dynamic>{};
    for (final entry in value.entries) {
      final key = entry.key;
      if (key is! String) {
        return value;
      }
      map[key] = _deepFreezeValue(entry.value);
    }
    return Map<String, dynamic>.unmodifiable(map);
  }

  if (value is List) {
    return List<dynamic>.unmodifiable(value.map(_deepFreezeValue));
  }

  return value;
}

const Object _unset = Object();

/// Unified trace state that can handle traces from any automaton type
class UnifiedTraceState with TraceStepNavigation<UnifiedTraceState> {
  final SimulationResult? currentTrace;
  @override
  final int currentStepIndex;
  final bool isRunning;
  final bool stepByStep;
  final String lastInput;
  final String? automatonType;
  final String? automatonId;
  final List<Map<String, dynamic>> traceHistory;
  final String? errorMessage;
  final Map<String, dynamic> traceStatistics;

  const UnifiedTraceState({
    this.currentTrace,
    this.currentStepIndex = 0,
    this.isRunning = false,
    this.stepByStep = false,
    this.lastInput = '',
    this.automatonType,
    this.automatonId,
    this.traceHistory = const [],
    this.errorMessage,
    this.traceStatistics = const {},
  });

  UnifiedTraceState copyWith({
    Object? currentTrace = _unset,
    int? currentStepIndex,
    bool? isRunning,
    bool? stepByStep,
    String? lastInput,
    Object? automatonType = _unset,
    Object? automatonId = _unset,
    List<Map<String, dynamic>>? traceHistory,
    Object? errorMessage = _unset,
    Map<String, dynamic>? traceStatistics,
  }) {
    return UnifiedTraceState(
      currentTrace: currentTrace == _unset
          ? this.currentTrace
          : currentTrace as SimulationResult?,
      currentStepIndex: currentStepIndex ?? this.currentStepIndex,
      isRunning: isRunning ?? this.isRunning,
      stepByStep: stepByStep ?? this.stepByStep,
      lastInput: lastInput ?? this.lastInput,
      automatonType: automatonType == _unset
          ? this.automatonType
          : automatonType as String?,
      automatonId:
          automatonId == _unset ? this.automatonId : automatonId as String?,
      traceHistory: traceHistory ?? this.traceHistory,
      errorMessage:
          errorMessage == _unset ? this.errorMessage : errorMessage as String?,
      traceStatistics: traceStatistics ?? this.traceStatistics,
    );
  }

  @override
  List<SimulationStep> get steps =>
      currentTrace?.steps ?? const <SimulationStep>[];

  @override
  UnifiedTraceState copyWithStepIndex(int currentStepIndex) {
    return copyWith(currentStepIndex: currentStepIndex);
  }

  /// Get traces for current automaton type
  List<Map<String, dynamic>> get tracesForCurrentType {
    if (automatonType == null) return traceHistory;
    return traceHistory
        .where((trace) => trace['automatonType'] == automatonType)
        .toList();
  }

  /// Get traces for current automaton
  List<Map<String, dynamic>> get tracesForCurrentAutomaton {
    if (automatonId == null) return traceHistory;
    return traceHistory
        .where((trace) => trace['automatonId'] == automatonId)
        .toList();
  }
}

/// Unified trace notifier that handles traces across different automaton types
class UnifiedTraceNotifier extends StateNotifier<UnifiedTraceState> {
  final TraceRepository _persistenceService;

  UnifiedTraceNotifier(this._persistenceService)
      : super(const UnifiedTraceState()) {
    _loadTraceHistory();
    _loadTraceStatistics();
    _restoreCurrentTrace();
  }

  /// Set the current automaton context
  void setAutomatonContext({
    required String automatonType,
    String? automatonId,
  }) {
    state = state.copyWith(
      automatonType: automatonType,
      automatonId: automatonId,
    );
    _loadTraceHistory();
  }

  /// Set step-by-step mode
  void setStepByStep(bool enabled) {
    state = state.copyWith(stepByStep: enabled);
  }

  /// Load a trace from history
  Future<void> loadTraceFromHistory(String traceId) async {
    try {
      final traceData = await _persistenceService.getTraceById(traceId);
      if (!mounted) return;
      if (traceData == null) return;

      final traceJson = traceData['trace'] as Map<String, dynamic>;
      final trace = SimulationResult.fromJson(traceJson);

      state = state.copyWith(
        currentTrace: trace,
        currentStepIndex: 0,
        errorMessage: null,
      );
    } catch (e) {
      if (!mounted) return;
      state = state.copyWith(errorMessage: 'Failed to load trace: $e');
    }
  }

  /// Save current trace to history
  Future<void> saveCurrentTraceToHistory() async {
    if (!mounted) return;
    if (state.currentTrace == null) return;

    try {
      await _persistenceService.saveTraceToHistory(
        state.currentTrace!,
        automatonType: state.automatonType,
        automatonId: state.automatonId,
      );
      if (!mounted) return;
      await _loadTraceHistory();
    } catch (e) {
      if (!mounted) return;
      state = state.copyWith(errorMessage: 'Failed to save trace: $e');
    }
  }

  /// Set a new trace (from simulation)
  Future<void> setTrace(SimulationResult trace) async {
    state = state.copyWith(
      currentTrace: trace,
      currentStepIndex: 0,
      errorMessage: null,
    );

    final saveSucceeded = await _saveCurrentTrace();
    if (!mounted || !saveSucceeded) {
      return;
    }

    await saveCurrentTraceToHistory();
  }

  /// Navigate to a specific step
  void navigateToStep(int stepIndex) {
    state = state.navigateToStep(stepIndex);
    unawaited(_saveCurrentTrace());
  }

  /// Navigate to the next step
  void nextStep() {
    state = state.nextStep();
    unawaited(_saveCurrentTrace());
  }

  /// Navigate to the previous step
  void previousStep() {
    state = state.previousStep();
    unawaited(_saveCurrentTrace());
  }

  /// Navigate to the first step
  void firstStep() {
    state = state.firstStep();
    unawaited(_saveCurrentTrace());
  }

  /// Navigate to the last step
  void lastStep() {
    state = state.lastStep();
    unawaited(_saveCurrentTrace());
  }

  /// Clear the current trace
  void clearCurrentTrace() {
    state = state.copyWith(
      currentTrace: null,
      currentStepIndex: 0,
      errorMessage: null,
    );
    _persistenceService.clearCurrentTrace();
  }

  /// Clear all trace history
  Future<void> clearAllTraces() async {
    await _persistenceService.clearAllTraces();
    if (!mounted) return;
    state = state.copyWith(
      traceHistory: [],
      currentTrace: null,
      currentStepIndex: 0,
      errorMessage: null,
    );
  }

  /// Export trace history
  Future<String> exportTraceHistory() async {
    return await _persistenceService.exportTraceHistory();
  }

  /// Import trace history
  Future<void> importTraceHistory(String jsonData) async {
    try {
      await _persistenceService.importTraceHistory(jsonData);
      if (!mounted) return;
      await _loadTraceHistory();
      if (!mounted) return;
      await _loadTraceStatistics();
    } catch (e) {
      if (!mounted) return;
      state = state.copyWith(errorMessage: 'Failed to import traces: $e');
    }
  }

  /// Get trace statistics
  Future<void> refreshTraceStatistics() async {
    await _loadTraceStatistics();
  }

  /// Load trace history from persistence
  Future<void> _loadTraceHistory() async {
    try {
      final history = await _persistenceService.getTraceHistory();
      if (!mounted) return;
      state = state.copyWith(traceHistory: history);
    } catch (e) {
      if (!mounted) return;
      state = state.copyWith(errorMessage: 'Failed to load trace history: $e');
    }
  }

  /// Load trace statistics
  Future<void> _loadTraceStatistics() async {
    try {
      final statistics = await _persistenceService.getTraceStatistics();
      if (!mounted) return;
      state = state.copyWith(traceStatistics: statistics);
    } catch (e) {
      // Statistics loading failure is not critical
    }
  }

  /// Save current trace state for persistence
  Future<bool> _saveCurrentTrace() async {
    if (state.currentTrace == null) {
      return false;
    }

    try {
      await _persistenceService.saveCurrentTrace(
        state.currentTrace!,
        state.currentStepIndex,
      );
      return true;
    } catch (error, stackTrace) {
      debugPrint('Failed to save current trace: $error');
      debugPrintStack(stackTrace: stackTrace);
      if (!mounted) return false;
      state = state.copyWith(
        errorMessage: 'Failed to save current trace: $error',
      );
      return false;
    }
  }

  Future<void> _restoreCurrentTrace() async {
    try {
      final persisted = await _persistenceService.getCurrentTrace();
      if (!mounted) return;
      if (persisted == null) {
        return;
      }

      final traceJson = persisted['trace'];
      if (traceJson is! Map<String, dynamic>) {
        await _persistenceService.clearCurrentTrace();
        return;
      }

      final trace = SimulationResult.fromJson(traceJson);
      final storedStepIndex = persisted['currentStepIndex'];
      final stepIndex = storedStepIndex is int ? storedStepIndex : 0;
      final normalizedStepIndex =
          trace.steps.isEmpty ? 0 : stepIndex.clamp(0, trace.steps.length - 1);

      state = state.copyWith(
        currentTrace: trace,
        currentStepIndex: normalizedStepIndex,
        errorMessage: null,
      );
    } catch (_) {
      await _persistenceService.clearCurrentTrace();
    }
  }

  Map<String, dynamic> get traceStatisticsSnapshot =>
      _deepUnmodifiableMap(state.traceStatistics);

  List<Map<String, dynamic>> get currentAutomatonTracesSnapshot =>
      _deepUnmodifiableTraceList(state.tracesForCurrentAutomaton);

  List<Map<String, dynamic>> get currentTypeTracesSnapshot =>
      _deepUnmodifiableTraceList(state.tracesForCurrentType);
}

final dataTracePersistenceServiceProvider = traceRepositoryProvider;

/// Provider for unified trace state
final unifiedTraceProvider =
    StateNotifierProvider<UnifiedTraceNotifier, UnifiedTraceState>((ref) {
  final persistenceService = ref.watch(dataTracePersistenceServiceProvider);
  return UnifiedTraceNotifier(persistenceService);
});

/// Provider for trace statistics
final traceStatisticsProvider = Provider<Map<String, dynamic>>((ref) {
  final traceState = ref.watch(unifiedTraceProvider);
  return traceState.traceStatistics;
});

/// Provider for current automaton traces
final currentAutomatonTracesProvider = Provider<List<Map<String, dynamic>>>((
  ref,
) {
  final traceState = ref.watch(unifiedTraceProvider);
  return traceState.tracesForCurrentAutomaton;
});

/// Provider for current automaton type traces
final currentTypeTracesProvider = Provider<List<Map<String, dynamic>>>((ref) {
  final traceState = ref.watch(unifiedTraceProvider);
  return traceState.tracesForCurrentType;
});
