//
//  pda_simulation_provider.dart
//  Turing Lab
//
//  Orquestra simulações de autômatos de pilha na interface, permitindo alternar
//  entre modos de aceitação, executar passos incrementais e publicar resultados
//  estruturados obtidos da fachada de simulação do domínio para feedback
//  consistente entre widgets e painéis.
//
//  Thales Matheus Mendonça Santos - October 2025
//
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/algorithms/pda_simulator.dart' as pda_core;
import '../../core/models/pda.dart';
import '../../core/models/simulation_step.dart';

typedef PDASimulationResult = pda_core.PDASimulationResult;
typedef PDAAcceptanceMode = pda_core.PDAAcceptanceMode;

const Object _unset = Object();

class PDASimulationState {
  final PDA? pda;
  final PDASimulationResult? result;
  final bool isRunning;
  final bool stepByStep;
  final PDAAcceptanceMode mode;
  final String lastInput;
  final int currentStepIndex;

  const PDASimulationState({
    this.pda,
    this.result,
    this.isRunning = false,
    this.stepByStep = false,
    this.mode = PDAAcceptanceMode.finalState,
    this.lastInput = '',
    this.currentStepIndex = 0,
  });

  PDASimulationState copyWith({
    Object? pda = _unset,
    Object? result = _unset,
    bool? isRunning,
    bool? stepByStep,
    PDAAcceptanceMode? mode,
    String? lastInput,
    int? currentStepIndex,
  }) {
    return PDASimulationState(
      pda: pda == _unset ? this.pda : pda as PDA?,
      result: result == _unset ? this.result : result as PDASimulationResult?,
      isRunning: isRunning ?? this.isRunning,
      stepByStep: stepByStep ?? this.stepByStep,
      mode: mode ?? this.mode,
      lastInput: lastInput ?? this.lastInput,
      currentStepIndex: currentStepIndex ?? this.currentStepIndex,
    );
  }

  /// Gets the current simulation step
  SimulationStep? get currentStep {
    if (result == null || result!.steps.isEmpty) return null;
    if (currentStepIndex < 0 || currentStepIndex >= result!.steps.length) {
      return null;
    }
    return result!.steps[currentStepIndex];
  }

  /// Gets the stack contents at the current step
  String get currentStackContents {
    return currentStep?.stackContents ?? '';
  }

  /// Gets the current state at the current step
  String? get currentState {
    return currentStep?.currentState;
  }

  /// Gets the remaining input at the current step
  String? get currentRemainingInput {
    return currentStep?.remainingInput;
  }

  /// Checks if we can go to the next step
  bool get canGoToNextStep {
    if (result == null || result!.steps.isEmpty) return false;
    return currentStepIndex < result!.steps.length - 1;
  }

  /// Checks if we can go to the previous step
  bool get canGoToPreviousStep {
    return currentStepIndex > 0;
  }

  /// Gets the total number of steps
  int get totalSteps {
    return result?.steps.length ?? 0;
  }
}

class PDASimulationNotifier extends StateNotifier<PDASimulationState> {
  PDASimulationNotifier() : super(const PDASimulationState());

  void setPda(PDA pda) {
    state = state.copyWith(pda: pda, result: null, currentStepIndex: 0);
  }

  void setStepByStep(bool enabled) {
    state = state.copyWith(stepByStep: enabled);
  }

  void setAcceptanceMode(PDAAcceptanceMode mode) {
    state = state.copyWith(mode: mode);
  }

  void setResult(PDASimulationResult result, {int currentStepIndex = 0}) {
    state = state.copyWith(
      result: result,
      currentStepIndex: currentStepIndex,
    );
  }

  Future<void> simulate(String input) async {
    if (state.pda == null) return;
    state = state.copyWith(
      isRunning: true,
      lastInput: input,
      currentStepIndex: 0,
    );

    final result = pda_core.PDASimulator.simulateNPDA(
      state.pda!,
      input,
      mode: state.mode,
      stepByStep: state.stepByStep,
    );

    if (result.isSuccess) {
      state = state.copyWith(
        result: result.data,
        isRunning: false,
        currentStepIndex: 0,
      );
    } else {
      state = state.copyWith(
        isRunning: false,
        currentStepIndex: 0,
        result: PDASimulationResult.failure(
          inputString: input,
          steps: const [],
          errorMessage: result.error ?? 'Unknown simulation error',
          executionTime: const Duration(milliseconds: 0),
        ),
      );
    }
  }

  /// Moves to the next simulation step
  void nextStep() {
    if (state.canGoToNextStep) {
      state = state.copyWith(currentStepIndex: state.currentStepIndex + 1);
    }
  }

  /// Moves to the previous simulation step
  void previousStep() {
    if (state.canGoToPreviousStep) {
      state = state.copyWith(currentStepIndex: state.currentStepIndex - 1);
    }
  }

  /// Jumps to a specific step
  void goToStep(int index) {
    if (state.result != null &&
        index >= 0 &&
        index < state.result!.steps.length) {
      state = state.copyWith(currentStepIndex: index);
    }
  }

  /// Resets to the first step
  void resetToFirstStep() {
    state = state.copyWith(currentStepIndex: 0);
  }

  /// Jumps to the last step
  void goToLastStep() {
    if (state.result != null && state.result!.steps.isNotEmpty) {
      state = state.copyWith(currentStepIndex: state.result!.steps.length - 1);
    }
  }
}

final pdaSimulationProvider =
    StateNotifierProvider<PDASimulationNotifier, PDASimulationState>((ref) {
  return PDASimulationNotifier();
});
