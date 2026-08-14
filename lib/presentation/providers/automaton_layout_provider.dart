//
//  automaton_layout_provider.dart
//  Turing Lab
//
//  Gerencia operações de layout automático para autômatos, aplicando
//  posicionamento espacial diretamente sobre FSA e coordenando com
//  AutomatonStateProvider.
//
//  Thales Matheus Mendonça Santos - January 2026
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../features/layout/fsa_layout_service.dart';
import 'automaton_state_provider.dart';

/// State for layout operations
class LayoutOperationState {
  final bool isLoading;
  final String? error;

  const LayoutOperationState({this.isLoading = false, this.error});

  static const _unset = Object();

  LayoutOperationState copyWith({bool? isLoading, Object? error = _unset}) {
    return LayoutOperationState(
      isLoading: isLoading ?? this.isLoading,
      error: error == _unset ? this.error : error as String?,
    );
  }

  /// Clear all state and reset to initial
  LayoutOperationState clear() {
    return const LayoutOperationState();
  }

  /// Clear only error state
  LayoutOperationState clearError() {
    return copyWith(error: null);
  }
}

/// Provider for automaton layout operations
class AutomatonLayoutNotifier extends StateNotifier<LayoutOperationState> {
  final Ref ref;
  final FsaLayoutService _layoutService = const FsaLayoutService();

  AutomatonLayoutNotifier(this.ref) : super(const LayoutOperationState()) {
    // Listen to automaton state changes and clear errors when automaton changes
    ref.listen<AutomatonStateProviderState>(automatonStateProvider, (
      previous,
      next,
    ) {
      // Clear layout errors when the automaton changes
      if (previous?.currentAutomaton?.id != next.currentAutomaton?.id) {
        state = state.clearError();
      }
    });
  }

  /// Applies auto layout to the current automaton
  Future<void> applyAutoLayout() async {
    final currentAutomaton = ref.read(automatonStateProvider).currentAutomaton;
    if (currentAutomaton == null) return;

    state = state.copyWith(isLoading: true, error: null);

    try {
      final updatedFsa = _layoutService.applyAutoLayout(currentAutomaton);
      ref.read(automatonStateProvider.notifier).updateAutomaton(updatedFsa);
      state = state.copyWith(isLoading: false);
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: 'Error applying auto layout: $e',
      );
    }
  }

  /// Clears any error messages
  void clearError() {
    state = state.clearError();
  }
}

/// Provider registration for automaton layout operations
final automatonLayoutProvider =
    StateNotifierProvider<AutomatonLayoutNotifier, LayoutOperationState>(
  AutomatonLayoutNotifier.new,
);
