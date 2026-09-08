part of 'pda_simulator.dart';

/// Validates the input PDA and string
Result<void> _validateInput(PDA pda, String inputString) {
  if (pda.states.isEmpty) {
    final message = PDASimulationMessages.emptyStateSet();
    return Failure(message.stableCode, structuredMessage: message);
  }

  if (pda.initialState == null) {
    final message = PDASimulationMessages.missingInitialState();
    return Failure(message.stableCode, structuredMessage: message);
  }

  if (!pda.states.contains(pda.initialState)) {
    final message = PDASimulationMessages.initialStateOutsideSet();
    return Failure(message.stableCode, structuredMessage: message);
  }

  for (final acceptingState in pda.acceptingStates) {
    if (!pda.states.contains(acceptingState)) {
      final message = PDASimulationMessages.acceptingStateOutsideSet();
      return Failure(message.stableCode, structuredMessage: message);
    }
  }

  // Do not hard-reject unknown input symbols here; allow the
  // simulation to proceed and naturally reject if no transitions
  // match. This aligns with reference semantics and tests.

  return const Success(null);
}
