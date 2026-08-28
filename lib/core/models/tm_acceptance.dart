/// Acceptance criteria supported by Turing-machine execution.
enum TMAcceptancePolicy {
  finalState,
  halting,
  finalStateOrHalting;

  bool get acceptsFinalState =>
      this == finalState || this == finalStateOrHalting;

  bool get acceptsHalting => this == halting || this == finalStateOrHalting;

  static TMAcceptancePolicy parse(
    Object? value, {
    TMAcceptancePolicy fallback = TMAcceptancePolicy.finalState,
  }) {
    if (value is! String) return fallback;
    return TMAcceptancePolicy.values.firstWhere(
      (policy) => policy.name == value,
      orElse: () => fallback,
    );
  }
}

/// Why bounded TM execution produced its semantic outcome.
enum TMAcceptanceReason {
  enteredFinalState,
  haltedInFinalState,
  haltedOutsideFinalState,
  reachableConfigurationsExhausted,
  deterministicCycle,
  stepLimit,
  configurationLimit,
  timeout,
  cancelled,
  invalidMachine,
}

/// A conclusive acceptance decision for one concrete configuration.
class TMAcceptanceDecision {
  const TMAcceptanceDecision({
    required this.accepted,
    required this.reason,
  });

  final bool accepted;
  final TMAcceptanceReason reason;
}

/// Applies a policy without coupling it to one execution engine.
abstract final class TMAcceptancePolicyEvaluator {
  static TMAcceptanceDecision? evaluate({
    required TMAcceptancePolicy policy,
    required bool isFinalState,
    required bool isHalted,
  }) {
    if (isFinalState && policy.acceptsFinalState) {
      return const TMAcceptanceDecision(
        accepted: true,
        reason: TMAcceptanceReason.enteredFinalState,
      );
    }
    if (!isHalted) return null;
    if (policy.acceptsHalting) {
      return TMAcceptanceDecision(
        accepted: true,
        reason: isFinalState
            ? TMAcceptanceReason.haltedInFinalState
            : TMAcceptanceReason.haltedOutsideFinalState,
      );
    }
    return TMAcceptanceDecision(
      accepted: false,
      reason: isFinalState
          ? TMAcceptanceReason.haltedInFinalState
          : TMAcceptanceReason.haltedOutsideFinalState,
    );
  }
}
