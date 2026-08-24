import 'dart:async';

import '../models/tm.dart';
import '../models/tm_execution_analysis.dart';
import '../models/tm_time_profile.dart';
import 'tm_execution_analyzer.dart';

typedef TMTimeProfileProgressCallback = void Function(
    TMTimeProfileProgress progress);

/// Builds a bounded empirical profile without inferring an asymptotic class.
class TMTimeProfiler {
  const TMTimeProfiler._();

  static TMTimeProfilePlan plan(
    TM tm, {
    TMTimeProfileBounds bounds = const TMTimeProfileBounds(),
  }) {
    final validationError = _validateBounds(bounds);
    final alphabet = tm.alphabet.toList()..sort();
    if (validationError != null) {
      return TMTimeProfilePlan(
        bounds: bounds,
        alphabet: alphabet,
        rows: const [],
        plannedCandidateCount: 0,
        validationError: validationError,
      );
    }

    final rows = <TMTimeProfilePlannedRow>[];
    var plannedCandidateCount = 0;
    for (var length = 0; length <= bounds.maxLength; length++) {
      final possible = _possibleCandidateCount(alphabet.length, length);
      final candidateCount =
          possible > BigInt.from(bounds.maxCandidatesPerLength)
              ? bounds.maxCandidatesPerLength
              : possible.toInt();
      final row = TMTimeProfilePlannedRow(
        inputLength: length,
        possibleCandidateCount: possible,
        candidateCount: candidateCount,
        isSampled: possible > BigInt.from(bounds.maxCandidatesPerLength),
      );
      rows.add(row);
      plannedCandidateCount += candidateCount;
    }
    return TMTimeProfilePlan(
      bounds: bounds,
      alphabet: alphabet,
      rows: rows,
      plannedCandidateCount: plannedCandidateCount,
    );
  }

  static Future<TMTimeProfileReport> profile(
    TM tm, {
    TMTimeProfileBounds bounds = const TMTimeProfileBounds(),
    bool Function()? isCancelled,
    TMTimeProfileProgressCallback? onProgress,
  }) async {
    final profilePlan = plan(tm, bounds: bounds);
    final kind = tm.isNondeterministic
        ? TMTimeProfileKind.nondeterministicExploration
        : TMTimeProfileKind.deterministicTime;
    if (!profilePlan.isValid) {
      return TMTimeProfileReport(
        kind: kind,
        status: TMTimeProfileStatus.invalid,
        message: profilePlan.validationError!,
        plan: profilePlan,
        rows: const [],
        profilingWallClockTime: Duration.zero,
      );
    }

    final stopwatch = Stopwatch()..start();
    final rows = <TMTimeProfileRow>[];
    var completedCandidates = 0;
    var wasCancelled = false;
    var invalidMachine = false;

    onProgress?.call(
      TMTimeProfileProgress(
        completedCandidates: 0,
        totalCandidates: profilePlan.plannedCandidateCount,
        inputLength: 0,
        input: '',
      ),
    );

    for (final plannedRow in profilePlan.rows) {
      final accumulator = _ProfileRowAccumulator(plannedRow);
      final inputs = _candidatesForRow(profilePlan.alphabet, plannedRow);
      for (final input in inputs) {
        if (isCancelled?.call() == true) {
          wasCancelled = true;
          break;
        }
        final execution = await TMExecutionAnalyzer.analyze(
          tm,
          input,
          maxSteps: bounds.maxStepsPerCandidate,
          maxConfigurations: bounds.maxConfigurationsPerCandidate,
          timeout: bounds.timeoutPerCandidate,
          operationsPerBatch: bounds.operationsPerBatch,
          includeTrace: false,
          isCancelled: isCancelled,
        );
        accumulator.record(execution, kind);
        completedCandidates++;
        onProgress?.call(
          TMTimeProfileProgress(
            completedCandidates: completedCandidates,
            totalCandidates: profilePlan.plannedCandidateCount,
            inputLength: plannedRow.inputLength,
            input: input,
          ),
        );

        if (execution.outcome == TMExecutionOutcome.cancelled) {
          wasCancelled = true;
          break;
        }
        if (execution.outcome == TMExecutionOutcome.invalidMachine) {
          invalidMachine = true;
          break;
        }
        await Future<void>.delayed(Duration.zero);
      }

      if (!wasCancelled && !invalidMachine) {
        wasCancelled = await accumulator.retainMaximumWitnesses(
          tm,
          kind: kind,
          bounds: bounds,
          completedCandidates: completedCandidates,
          totalCandidates: profilePlan.plannedCandidateCount,
          isCancelled: isCancelled,
          onProgress: onProgress,
        );
      }
      rows.add(accumulator.finish(witnessesComplete: !wasCancelled));
      if (wasCancelled || invalidMachine) break;
    }

    stopwatch.stop();
    final hasIncompleteRows = rows.any((row) => !row.isComplete);
    final status = invalidMachine
        ? TMTimeProfileStatus.invalid
        : wasCancelled
            ? TMTimeProfileStatus.cancelled
            : hasIncompleteRows || rows.length != profilePlan.rows.length
                ? TMTimeProfileStatus.incomplete
                : TMTimeProfileStatus.complete;
    final message = switch (status) {
      TMTimeProfileStatus.complete =>
        'The bounded profile exhaustively resolved every candidate.',
      TMTimeProfileStatus.incomplete =>
        'The bounded profile is incomplete because a row was sampled or an execution remained unknown.',
      TMTimeProfileStatus.cancelled => 'Time profiling was cancelled.',
      TMTimeProfileStatus.invalid =>
        'The machine or one of the profile inputs is invalid.',
    };
    return TMTimeProfileReport(
      kind: kind,
      status: status,
      message: message,
      plan: profilePlan,
      rows: rows,
      profilingWallClockTime: stopwatch.elapsed,
    );
  }

  static String? _validateBounds(TMTimeProfileBounds bounds) {
    if (bounds.maxLength < 0) return 'Maximum input length cannot be negative.';
    if (bounds.maxCandidatesPerLength <= 0) {
      return 'Candidate limit per length must be greater than zero.';
    }
    if (bounds.maxStepsPerCandidate <= 0) {
      return 'Step limit per candidate must be greater than zero.';
    }
    if (bounds.maxConfigurationsPerCandidate <= 0) {
      return 'Configuration limit per candidate must be greater than zero.';
    }
    if (bounds.timeoutPerCandidate <= Duration.zero) {
      return 'Timeout per candidate must be greater than zero.';
    }
    if (bounds.operationsPerBatch <= 0) {
      return 'Operations per batch must be greater than zero.';
    }
    return null;
  }

  static BigInt _possibleCandidateCount(int alphabetSize, int length) {
    if (length == 0) return BigInt.one;
    if (alphabetSize == 0) return BigInt.zero;
    return BigInt.from(alphabetSize).pow(length);
  }

  static List<String> _candidatesForRow(
    List<String> alphabet,
    TMTimeProfilePlannedRow row,
  ) {
    if (row.candidateCount == 0) return const [];
    if (row.inputLength == 0) return const [''];
    final lastOrdinal = row.possibleCandidateCount - BigInt.one;
    final denominator = BigInt.from(row.candidateCount - 1);
    return [
      for (var index = 0; index < row.candidateCount; index++)
        _wordAtOrdinal(
          alphabet,
          row.inputLength,
          row.candidateCount == 1
              ? BigInt.zero
              : lastOrdinal * BigInt.from(index) ~/ denominator,
        ),
    ];
  }

  static String _wordAtOrdinal(
    List<String> alphabet,
    int length,
    BigInt ordinal,
  ) {
    final symbols = List<String>.filled(length, alphabet.first);
    final base = BigInt.from(alphabet.length);
    var remaining = ordinal;
    for (var index = length - 1; index >= 0; index--) {
      final digit = (remaining % base).toInt();
      symbols[index] = alphabet[digit];
      remaining ~/= base;
    }
    return symbols.join();
  }
}

class _ProfileRowAccumulator {
  _ProfileRowAccumulator(this.plan);

  final TMTimeProfilePlannedRow plan;
  int evaluatedCandidateCount = 0;
  int completedCount = 0;
  int provenCycleCount = 0;
  int unknownCount = 0;
  int cancelledCount = 0;
  int invalidCount = 0;
  int? minimumTransitionSteps;
  int? maximumTransitionSteps;
  String? maximumTransitionInput;
  int? minimumExplorationDepth;
  int? maximumExplorationDepth;
  String? maximumDepthInput;
  int? minimumConfigurationsExplored;
  int? maximumConfigurationsExplored;
  String? maximumConfigurationsInput;
  TMTimeProfileWitness? maximumTransitionWitness;
  TMTimeProfileWitness? maximumDepthWitness;
  TMTimeProfileWitness? maximumConfigurationsWitness;

  void record(TMExecutionAnalysis execution, TMTimeProfileKind kind) {
    evaluatedCandidateCount++;
    switch (execution.outcome) {
      case TMExecutionOutcome.accepted:
      case TMExecutionOutcome.haltedRejected:
        completedCount++;
      case TMExecutionOutcome.provenCycle:
        provenCycleCount++;
      case TMExecutionOutcome.boundedUnknown:
        unknownCount++;
      case TMExecutionOutcome.cancelled:
        cancelledCount++;
      case TMExecutionOutcome.invalidMachine:
        invalidCount++;
    }

    if (kind == TMTimeProfileKind.deterministicTime &&
        (execution.outcome == TMExecutionOutcome.accepted ||
            execution.outcome == TMExecutionOutcome.haltedRejected)) {
      if (minimumTransitionSteps == null ||
          execution.stepsExecuted < minimumTransitionSteps!) {
        minimumTransitionSteps = execution.stepsExecuted;
      }
      if (maximumTransitionSteps == null ||
          execution.stepsExecuted > maximumTransitionSteps! ||
          (execution.stepsExecuted == maximumTransitionSteps &&
              execution.input.compareTo(maximumTransitionInput!) < 0)) {
        maximumTransitionSteps = execution.stepsExecuted;
        maximumTransitionInput = execution.input;
      }
    }

    if (kind == TMTimeProfileKind.nondeterministicExploration &&
        execution.outcome != TMExecutionOutcome.cancelled &&
        execution.outcome != TMExecutionOutcome.invalidMachine) {
      if (minimumExplorationDepth == null ||
          execution.stepsExecuted < minimumExplorationDepth!) {
        minimumExplorationDepth = execution.stepsExecuted;
      }
      if (maximumExplorationDepth == null ||
          execution.stepsExecuted > maximumExplorationDepth! ||
          (execution.stepsExecuted == maximumExplorationDepth &&
              execution.input.compareTo(maximumDepthInput!) < 0)) {
        maximumExplorationDepth = execution.stepsExecuted;
        maximumDepthInput = execution.input;
      }
      if (minimumConfigurationsExplored == null ||
          execution.configurationsExplored < minimumConfigurationsExplored!) {
        minimumConfigurationsExplored = execution.configurationsExplored;
      }
      if (maximumConfigurationsExplored == null ||
          execution.configurationsExplored > maximumConfigurationsExplored! ||
          (execution.configurationsExplored == maximumConfigurationsExplored &&
              execution.input.compareTo(maximumConfigurationsInput!) < 0)) {
        maximumConfigurationsExplored = execution.configurationsExplored;
        maximumConfigurationsInput = execution.input;
      }
    }
  }

  Future<bool> retainMaximumWitnesses(
    TM tm, {
    required TMTimeProfileKind kind,
    required TMTimeProfileBounds bounds,
    required int completedCandidates,
    required int totalCandidates,
    bool Function()? isCancelled,
    TMTimeProfileProgressCallback? onProgress,
  }) async {
    final witnessInputs = <String>{
      if (kind == TMTimeProfileKind.deterministicTime &&
          maximumTransitionInput != null)
        maximumTransitionInput!,
      if (kind == TMTimeProfileKind.nondeterministicExploration &&
          maximumDepthInput != null)
        maximumDepthInput!,
      if (kind == TMTimeProfileKind.nondeterministicExploration &&
          maximumConfigurationsInput != null)
        maximumConfigurationsInput!,
    };
    final executions = <String, TMExecutionAnalysis>{};
    for (final input in witnessInputs) {
      if (isCancelled?.call() == true) return true;
      onProgress?.call(
        TMTimeProfileProgress(
          completedCandidates: completedCandidates,
          totalCandidates: totalCandidates,
          inputLength: plan.inputLength,
          input: input,
          isWitnessReplay: true,
        ),
      );
      final execution = await TMExecutionAnalyzer.analyze(
        tm,
        input,
        maxSteps: bounds.maxStepsPerCandidate,
        maxConfigurations: bounds.maxConfigurationsPerCandidate,
        timeout: bounds.timeoutPerCandidate,
        operationsPerBatch: bounds.operationsPerBatch,
        includeTrace: true,
        isCancelled: isCancelled,
      );
      if (execution.outcome == TMExecutionOutcome.cancelled) return true;
      executions[input] = execution;
    }
    if (maximumTransitionInput != null) {
      maximumTransitionWitness = TMTimeProfileWitness(
        input: maximumTransitionInput!,
        execution: executions[maximumTransitionInput!]!,
      );
    }
    if (maximumDepthInput != null) {
      maximumDepthWitness = TMTimeProfileWitness(
        input: maximumDepthInput!,
        execution: executions[maximumDepthInput!]!,
      );
    }
    if (maximumConfigurationsInput != null) {
      maximumConfigurationsWitness = TMTimeProfileWitness(
        input: maximumConfigurationsInput!,
        execution: executions[maximumConfigurationsInput!]!,
      );
    }
    return false;
  }

  TMTimeProfileRow finish({required bool witnessesComplete}) {
    final isComplete = witnessesComplete &&
        !plan.isSampled &&
        evaluatedCandidateCount == plan.candidateCount &&
        unknownCount == 0 &&
        cancelledCount == 0 &&
        invalidCount == 0;
    return TMTimeProfileRow(
      inputLength: plan.inputLength,
      possibleCandidateCount: plan.possibleCandidateCount,
      candidateCount: plan.candidateCount,
      evaluatedCandidateCount: evaluatedCandidateCount,
      completedCount: completedCount,
      provenCycleCount: provenCycleCount,
      unknownCount: unknownCount,
      cancelledCount: cancelledCount,
      invalidCount: invalidCount,
      isSampled: plan.isSampled,
      isComplete: isComplete,
      minimumTransitionSteps: minimumTransitionSteps,
      maximumTransitionSteps: maximumTransitionSteps,
      maximumTransitionWitness: maximumTransitionWitness,
      minimumExplorationDepth: minimumExplorationDepth,
      maximumExplorationDepth: maximumExplorationDepth,
      maximumDepthWitness: maximumDepthWitness,
      minimumConfigurationsExplored: minimumConfigurationsExplored,
      maximumConfigurationsExplored: maximumConfigurationsExplored,
      maximumConfigurationsWitness: maximumConfigurationsWitness,
    );
  }
}
