import 'dart:collection';
import 'dart:convert';

import 'package:turing_lab/core/models/pda.dart';
import 'package:turing_lab/core/models/pda_acceptance_mode.dart';
import 'package:turing_lab/core/models/pda_transition.dart';

import '../outcomes.dart';
import '../resources.dart';

final class PdaOracleConfiguration {
  PdaOracleConfiguration({
    required this.stateId,
    required this.inputOffset,
    required Iterable<String> stack,
  }) : stack = List<String>.unmodifiable(stack);

  final String stateId;
  final int inputOffset;
  final List<String> stack;

  String get fingerprint => jsonEncode([stateId, inputOffset, stack]);

  Map<String, Object?> toJson() => {
        'inputOffset': inputOffset,
        'stack': stack,
        'stateId': stateId,
      };
}

final class PdaOracleStep {
  const PdaOracleStep({
    required this.transitionId,
    required this.before,
    required this.after,
  });

  final String transitionId;
  final PdaOracleConfiguration before;
  final PdaOracleConfiguration after;

  Map<String, Object?> toJson() => {
        'after': after.toJson(),
        'before': before.toJson(),
        'transitionId': transitionId,
      };
}

final class PdaOracleResult {
  PdaOracleResult({
    required this.outcome,
    required this.exploredConfigurations,
    required this.maximumFrontier,
    required Iterable<PdaOracleStep> witness,
    this.limit,
    this.message,
  }) : witness = List<PdaOracleStep>.unmodifiable(witness);

  final VerificationOutcomeCode outcome;
  final int exploredConfigurations;
  final int maximumFrontier;
  final List<PdaOracleStep> witness;
  final ResourceLimitEvidence? limit;
  final String? message;

  bool get accepted => outcome == VerificationOutcomeCode.accepted;
  bool get isDefinitive =>
      outcome == VerificationOutcomeCode.accepted ||
      outcome == VerificationOutcomeCode.rejected;

  Map<String, Object?> toJson() => {
        'exploredConfigurations': exploredConfigurations,
        if (limit != null)
          'limit': {
            'kind': limit!.kind.name,
            'maximum': limit!.maximum,
            'observed': limit!.observed,
            'unit': limit!.unit,
          },
        'maximumFrontier': maximumFrontier,
        if (message != null) 'message': message,
        'outcome': outcome.name,
        'witness': witness.map((step) => step.toJson()).toList(),
      };
}

enum PdaOracleMutation {
  none,
  ignorePush,
  reversePushOrder,
  omitStackFromConfiguration,
  acceptBeforeInputConsumed,
}

final class PdaExhaustiveExplorer {
  const PdaExhaustiveExplorer();

  PdaOracleResult explore({
    required PDA pda,
    required String input,
    PDAAcceptanceMode? mode,
    ResourceBudget? budget,
    CancellationProbe? cancellation,
    RequestFreshnessProbe? freshness,
    ElapsedClock? clock,
    PdaOracleMutation mutation = PdaOracleMutation.none,
  }) {
    final error = _validate(pda);
    if (error != null) {
      return PdaOracleResult(
        outcome: VerificationOutcomeCode.invalidInput,
        exploredConfigurations: 0,
        maximumFrontier: 0,
        witness: const [],
        message: error,
      );
    }

    final assertions = ResourceAssertions(
      budget: budget ??
          ResourceBudget(
            maxSteps: 1000,
            maxConfigurations: 100000,
            maxFrontier: 100000,
            timeout: const Duration(seconds: 5),
          ),
      clock: clock ?? StopwatchElapsedClock(),
      cancellation: cancellation,
      freshness: freshness,
    );
    final initial = PdaOracleConfiguration(
      stateId: pda.initialState!.id,
      inputOffset: 0,
      stack: [pda.initialStackSymbol],
    );
    final queue =
        Queue<({PdaOracleConfiguration value, List<PdaOracleStep> trace})>()
          ..add((value: initial, trace: const []));
    final seen = <String>{_configurationKey(initial, mutation)};
    final statesById = {for (final state in pda.states) state.id: state};
    final transitionsByState = <String, List<PDATransition>>{};
    for (final transition in pda.pdaTransitions) {
      transitionsByState
          .putIfAbsent(transition.fromState.id, () => [])
          .add(transition);
    }
    for (final transitions in transitionsByState.values) {
      transitions.sort((left, right) => left.id.compareTo(right.id));
    }

    var explored = 0;
    var maximumFrontier = queue.length;
    while (queue.isNotEmpty) {
      final resource = assertions.evaluate(
        ResourceSnapshot(
          steps: explored,
          configurations: seen.length,
          frontier: queue.length,
          memoryBytes: _estimatedMemoryBytes(queue, seen),
          partialEvidence: {'exploredConfigurations': explored},
        ),
      );
      final stopped = _stoppedResult(
        resource,
        explored: explored,
        maximumFrontier: maximumFrontier,
      );
      if (stopped != null) return stopped;

      final current = queue.removeFirst();
      explored++;
      final state = statesById[current.value.stateId]!;
      if (_accepts(
        pda: pda,
        stateId: state.id,
        inputOffset: current.value.inputOffset,
        inputLength: input.length,
        stack: current.value.stack,
        mode: mode ?? pda.acceptanceMode,
        mutation: mutation,
      )) {
        return PdaOracleResult(
          outcome: VerificationOutcomeCode.accepted,
          exploredConfigurations: explored,
          maximumFrontier: maximumFrontier,
          witness: current.trace,
        );
      }

      for (final transition
          in transitionsByState[current.value.stateId] ?? const []) {
        final successor = _apply(
          transition,
          current.value,
          input,
          mutation,
        );
        if (successor == null) continue;
        if (!seen.add(_configurationKey(successor, mutation))) continue;
        queue.add((
          value: successor,
          trace: [
            ...current.trace,
            PdaOracleStep(
              transitionId: transition.id,
              before: current.value,
              after: successor,
            ),
          ],
        ));
      }
      if (queue.length > maximumFrontier) maximumFrontier = queue.length;
    }
    return PdaOracleResult(
      outcome: VerificationOutcomeCode.rejected,
      exploredConfigurations: explored,
      maximumFrontier: maximumFrontier,
      witness: const [],
    );
  }
}

int _estimatedMemoryBytes(
  Queue<({PdaOracleConfiguration value, List<PdaOracleStep> trace})> queue,
  Set<String> seen,
) {
  var bytes = 0;
  for (final fingerprint in seen) {
    bytes += utf8.encode(fingerprint).length;
  }
  for (final entry in queue) {
    bytes += utf8.encode(entry.value.stateId).length;
    for (final token in entry.value.stack) {
      bytes += utf8.encode(token).length;
    }
    bytes += entry.trace.length * 8;
  }
  return bytes;
}

String? _validate(PDA pda) {
  if (pda.states.isEmpty) return 'PDA has no states.';
  final initial = pda.initialState;
  if (initial == null || !pda.states.contains(initial)) {
    return 'PDA has no valid initial state.';
  }
  if (pda.initialStackSymbol.isEmpty ||
      !pda.stackAlphabet.contains(pda.initialStackSymbol)) {
    return 'PDA has no valid initial stack symbol.';
  }
  final errors = pda.validate();
  return errors.isEmpty ? null : errors.first;
}

PdaOracleResult? _stoppedResult(
  ResourceCheck resource, {
  required int explored,
  required int maximumFrontier,
}) {
  if (resource is ResourceAvailable) return null;
  if (resource is ResourceCancelled) {
    return PdaOracleResult(
      outcome: VerificationOutcomeCode.cancelled,
      exploredConfigurations: explored,
      maximumFrontier: maximumFrontier,
      witness: const [],
    );
  }
  if (resource is ResourceStaleRequest) {
    return PdaOracleResult(
      outcome: VerificationOutcomeCode.staleRequest,
      exploredConfigurations: explored,
      maximumFrontier: maximumFrontier,
      witness: const [],
    );
  }
  final limit = (resource as ResourceLimitReached).evidence;
  final outcome = switch (limit.kind) {
    ResourceLimitKind.timeout => VerificationOutcomeCode.timeout,
    ResourceLimitKind.configurations =>
      VerificationOutcomeCode.configurationLimit,
    _ => VerificationOutcomeCode.boundedUnknown,
  };
  return PdaOracleResult(
    outcome: outcome,
    exploredConfigurations: explored,
    maximumFrontier: maximumFrontier,
    witness: const [],
    limit: limit,
  );
}

bool _accepts({
  required PDA pda,
  required String stateId,
  required int inputOffset,
  required int inputLength,
  required List<String> stack,
  required PDAAcceptanceMode mode,
  required PdaOracleMutation mutation,
}) {
  final consumed = mutation == PdaOracleMutation.acceptBeforeInputConsumed ||
      inputOffset == inputLength;
  if (!consumed) return false;
  final finalState = pda.acceptingStates.any((state) => state.id == stateId);
  return switch (mode) {
    PDAAcceptanceMode.finalState => finalState,
    PDAAcceptanceMode.emptyStack => stack.isEmpty,
    PDAAcceptanceMode.both => finalState && stack.isEmpty,
  };
}

PdaOracleConfiguration? _apply(
  PDATransition transition,
  PdaOracleConfiguration current,
  String input,
  PdaOracleMutation mutation,
) {
  final lambdaInput =
      transition.isLambdaInput || transition.inputSymbol.isEmpty;
  final lambdaPop = transition.isLambdaPop || transition.popSymbol.isEmpty;
  final lambdaPush = transition.isLambdaPush || transition.pushSymbols.isEmpty;
  if (!lambdaInput &&
      !input.startsWith(transition.inputSymbol, current.inputOffset)) {
    return null;
  }
  if (!lambdaPop &&
      (current.stack.isEmpty || current.stack.last != transition.popSymbol)) {
    return null;
  }

  final nextStack = [...current.stack];
  if (!lambdaPop) nextStack.removeLast();
  if (!lambdaPush && mutation != PdaOracleMutation.ignorePush) {
    final pushed = mutation == PdaOracleMutation.reversePushOrder
        ? transition.pushSymbols
        : transition.pushSymbols.reversed;
    nextStack.addAll(pushed);
  }
  return PdaOracleConfiguration(
    stateId: transition.toState.id,
    inputOffset:
        current.inputOffset + (lambdaInput ? 0 : transition.inputSymbol.length),
    stack: nextStack,
  );
}

String _configurationKey(
  PdaOracleConfiguration configuration,
  PdaOracleMutation mutation,
) {
  if (mutation == PdaOracleMutation.omitStackFromConfiguration) {
    return jsonEncode([configuration.stateId, configuration.inputOffset]);
  }
  return configuration.fingerprint;
}
