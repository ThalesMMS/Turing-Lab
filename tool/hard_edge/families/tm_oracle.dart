import 'dart:collection';
import 'dart:convert';

import 'package:turing_lab/core/models/tm.dart';
import 'package:turing_lab/core/models/tm_acceptance.dart';
import 'package:turing_lab/core/models/tm_transition.dart';

enum TmOracleOutcome {
  accepted,
  haltedRejected,
  provenCycle,
  boundedUnknown,
  invalidMachine,
}

final class TmOracleTraceStep {
  const TmOracleTraceStep({
    required this.transitionId,
    required this.stateId,
    required this.heads,
    required this.tapes,
  });

  final String transitionId;
  final String stateId;
  final List<int> heads;
  final List<Map<int, String>> tapes;
}

final class TmOracleResult {
  const TmOracleResult({
    required this.outcome,
    required this.steps,
    required this.configurations,
    required this.trace,
  });

  final TmOracleOutcome outcome;
  final int steps;
  final int configurations;
  final List<TmOracleTraceStep> trace;
}

/// Small clarity-first TM interpreter independent of the production kernel.
///
/// It reads only immutable model data. Tape storage, transition selection,
/// canonicalization, BFS, and outcome classification are implemented here.
final class IndependentTmOracle {
  const IndependentTmOracle({
    this.maximumSteps = 64,
    this.maximumConfigurations = 512,
  });

  final int maximumSteps;
  final int maximumConfigurations;

  TmOracleResult run(TM machine, List<String> inputTokens) {
    if (maximumSteps < 0 || maximumConfigurations <= 0) {
      throw ArgumentError('Oracle bounds must be positive.');
    }
    if (machine.initialState == null || machine.validate().isNotEmpty) {
      return const TmOracleResult(
        outcome: TmOracleOutcome.invalidMachine,
        steps: 0,
        configurations: 0,
        trace: [],
      );
    }

    final tapes = List<Map<int, String>>.generate(
      machine.tapeCount,
      (tape) => tape == 0
          ? <int, String>{
              for (var cell = 0; cell < inputTokens.length; cell++)
                if (inputTokens[cell] != machine.blankSymbol)
                  cell: inputTokens[cell],
            }
          : <int, String>{},
      growable: false,
    );
    final initial = _OracleConfiguration(
      stateId: machine.initialState!.id,
      heads: List<int>.filled(machine.tapeCount, 0),
      tapes: tapes,
      depth: 0,
      trace: const [],
    );
    final queue = Queue<_OracleConfiguration>()..add(initial);
    final seen = <String, int>{initial.key(machine.blankSymbol): 0};
    var explored = 0;
    var maximumDepth = 0;
    var truncatedBySteps = false;
    var truncatedTrace = const <TmOracleTraceStep>[];

    while (queue.isNotEmpty) {
      if (explored >= maximumConfigurations) {
        return TmOracleResult(
          outcome: TmOracleOutcome.boundedUnknown,
          steps: maximumDepth,
          configurations: explored,
          trace: queue.first.trace,
        );
      }
      final current = queue.removeFirst();
      explored++;
      maximumDepth =
          current.depth > maximumDepth ? current.depth : maximumDepth;
      final state = machine.states.singleWhere(
        (candidate) => candidate.id == current.stateId,
      );
      if (_acceptsOnEntry(machine.acceptancePolicy, state.isAccepting)) {
        return TmOracleResult(
          outcome: TmOracleOutcome.accepted,
          steps: current.depth,
          configurations: explored,
          trace: current.trace,
        );
      }

      final read = List<String>.generate(
        machine.tapeCount,
        (tape) =>
            current.tapes[tape][current.heads[tape]] ?? machine.blankSymbol,
        growable: false,
      );
      final enabled = machine.tmTransitions
          .where(
            (transition) =>
                transition.fromState.id == current.stateId &&
                _vectorEquals(
                  transition
                      .operationsForTapeCount(
                        machine.tapeCount,
                        machine.blankSymbol,
                      )
                      .readSymbols,
                  read,
                ),
          )
          .toList()
        ..sort((left, right) => left.id.compareTo(right.id));

      if (enabled.isEmpty) {
        if (_acceptsOnHalt(machine.acceptancePolicy, state.isAccepting)) {
          return TmOracleResult(
            outcome: TmOracleOutcome.accepted,
            steps: current.depth,
            configurations: explored,
            trace: current.trace,
          );
        }
        continue;
      }
      if (current.depth >= maximumSteps) {
        truncatedBySteps = true;
        if (truncatedTrace.isEmpty) truncatedTrace = current.trace;
        continue;
      }

      for (final transition in enabled) {
        final operations = transition.operationsForTapeCount(
          machine.tapeCount,
          machine.blankSymbol,
        );
        final nextTapes = current.tapes
            .map((tape) => Map<int, String>.from(tape))
            .toList(growable: false);
        final nextHeads = List<int>.of(current.heads, growable: false);
        for (var tape = 0; tape < machine.tapeCount; tape++) {
          final write = operations.writeSymbols[tape];
          if (write == machine.blankSymbol) {
            nextTapes[tape].remove(nextHeads[tape]);
          } else {
            nextTapes[tape][nextHeads[tape]] = write;
          }
        }
        for (var tape = 0; tape < machine.tapeCount; tape++) {
          nextHeads[tape] += switch (operations.directions[tape]) {
            TapeDirection.left => -1,
            TapeDirection.right => 1,
            TapeDirection.stay => 0,
          };
        }
        final trace = <TmOracleTraceStep>[
          ...current.trace,
          TmOracleTraceStep(
            transitionId: transition.id,
            stateId: transition.toState.id,
            heads: List<int>.unmodifiable(nextHeads),
            tapes: List<Map<int, String>>.unmodifiable(
              nextTapes.map(Map<int, String>.unmodifiable),
            ),
          ),
        ];
        final next = _OracleConfiguration(
          stateId: transition.toState.id,
          heads: nextHeads,
          tapes: nextTapes,
          depth: current.depth + 1,
          trace: trace,
        );
        final key = next.key(machine.blankSymbol);
        final previousDepth = seen[key];
        if (previousDepth != null) {
          if (!machine.isNondeterministic) {
            return TmOracleResult(
              outcome: TmOracleOutcome.provenCycle,
              steps: next.depth,
              configurations: explored,
              trace: trace,
            );
          }
          continue;
        }
        seen[key] = next.depth;
        queue.add(next);
      }
    }

    return TmOracleResult(
      outcome: truncatedBySteps
          ? TmOracleOutcome.boundedUnknown
          : TmOracleOutcome.haltedRejected,
      steps: maximumDepth,
      configurations: explored,
      trace: truncatedBySteps ? truncatedTrace : const [],
    );
  }
}

final class _OracleConfiguration {
  const _OracleConfiguration({
    required this.stateId,
    required this.heads,
    required this.tapes,
    required this.depth,
    required this.trace,
  });

  final String stateId;
  final List<int> heads;
  final List<Map<int, String>> tapes;
  final int depth;
  final List<TmOracleTraceStep> trace;

  String key(String blankSymbol) => jsonEncode([
        stateId,
        heads,
        for (final tape in tapes)
          (tape.entries.where((entry) => entry.value != blankSymbol).toList()
                ..sort((left, right) => left.key.compareTo(right.key)))
              .map((entry) => [entry.key, entry.value])
              .toList(),
      ]);
}

bool _vectorEquals(List<String> left, List<String> right) {
  if (left.length != right.length) return false;
  for (var index = 0; index < left.length; index++) {
    if (left[index] != right[index]) return false;
  }
  return true;
}

bool _acceptsOnEntry(TMAcceptancePolicy policy, bool finalState) =>
    finalState && policy != TMAcceptancePolicy.halting;

bool _acceptsOnHalt(TMAcceptancePolicy policy, bool finalState) =>
    policy == TMAcceptancePolicy.halting ||
    (policy == TMAcceptancePolicy.finalStateOrHalting) ||
    (policy == TMAcceptancePolicy.finalState && finalState);
