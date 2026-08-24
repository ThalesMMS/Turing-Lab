import '../models/tm.dart';
import '../models/tm_execution_analysis.dart';
import '../models/tm_language_explorer_models.dart';
import '../result.dart';
import 'tm_execution_analyzer.dart';

typedef TMLanguageProgressCallback = void Function(
    TMLanguageExplorerProgress progress);

/// Enumerates a bounded shortlex prefix of a TM language.
class TMLanguageExplorer {
  const TMLanguageExplorer._();

  static BigInt countCandidates(Iterable<String> alphabet, int maxLength) {
    if (maxLength < 0) {
      throw ArgumentError.value(maxLength, 'maxLength', 'must be non-negative');
    }
    final alphabetSize = BigInt.from(alphabet.toSet().length);
    var total = BigInt.one;
    var wordsAtLength = BigInt.one;
    for (var length = 1; length <= maxLength; length++) {
      wordsAtLength *= alphabetSize;
      total += wordsAtLength;
    }
    return total;
  }

  static Future<Result<TMLanguageExplorerReport>> explore(
    TM tm, {
    TMLanguageExplorerLimits limits = const TMLanguageExplorerLimits(),
    bool includeTrace = false,
    TMLanguageProgressCallback? onProgress,
    TMLanguageExplorerCancellationToken? cancellationToken,
  }) async {
    final validationError = _validateLimits(limits);
    if (validationError != null) {
      return ResultFactory.failure(validationError);
    }

    final alphabet = tm.alphabet.toSet().toList()..sort();
    final requested = countCandidates(alphabet, limits.maxInputLength);
    final cap = BigInt.from(limits.maxCandidates);
    final planned = requested > cap ? limits.maxCandidates : requested.toInt();
    final truncatedByCap = requested > cap;
    final results = <TMLanguageWordResult>[];
    final stopwatch = Stopwatch()..start();

    void publish([String? input]) {
      onProgress?.call(
        TMLanguageExplorerProgress(
          evaluatedCandidates: results.length,
          plannedCandidates: planned,
          requestedCandidates: requested,
          currentInput: input,
          counts: Map.unmodifiable(_counts(results)),
        ),
      );
    }

    publish();
    var cancelled = cancellationToken?.isCancelled ?? false;
    if (!cancelled) {
      for (final input in _shortlex(alphabet, limits.maxInputLength)) {
        if (results.length >= planned) break;
        if (cancellationToken?.isCancelled == true) {
          cancelled = true;
          break;
        }

        final analysis = await TMExecutionAnalyzer.analyze(
          tm,
          input,
          maxSteps: limits.maxStepsPerInput,
          maxConfigurations: limits.maxConfigurationsPerInput,
          timeout: limits.timeoutPerInput,
          operationsPerBatch: limits.operationsPerBatch,
          includeTrace: includeTrace,
          isCancelled: () => cancellationToken?.isCancelled ?? false,
        );
        results.add(
          TMLanguageWordResult(
            input: input,
            outcome: _classify(analysis.outcome),
            analysis: analysis,
          ),
        );
        publish(input);

        if (analysis.outcome == TMExecutionOutcome.cancelled) {
          cancelled = true;
          break;
        }
        await Future<void>.delayed(Duration.zero);
      }
    }

    stopwatch.stop();
    return ResultFactory.success(
      TMLanguageExplorerReport(
        limits: limits,
        alphabet: alphabet,
        requestedCandidates: requested,
        plannedCandidates: planned,
        results: results,
        cancelled: cancelled,
        truncatedByCandidateCap: truncatedByCap,
        executionTime: stopwatch.elapsed,
      ),
    );
  }

  static String? _validateLimits(TMLanguageExplorerLimits limits) {
    if (limits.maxInputLength < 0) {
      return 'Maximum input length must be non-negative.';
    }
    if (limits.maxCandidates <= 0) {
      return 'Candidate cap must be greater than zero.';
    }
    if (limits.maxStepsPerInput <= 0) {
      return 'Step limit must be greater than zero.';
    }
    if (limits.maxConfigurationsPerInput <= 0) {
      return 'Configuration limit must be greater than zero.';
    }
    if (limits.timeoutPerInput <= Duration.zero) {
      return 'Timeout must be greater than zero.';
    }
    if (limits.operationsPerBatch <= 0) {
      return 'Operations per batch must be greater than zero.';
    }
    return null;
  }

  static Map<TMLanguageOutcome, int> _counts(
    Iterable<TMLanguageWordResult> results,
  ) {
    final counts = {for (final outcome in TMLanguageOutcome.values) outcome: 0};
    for (final result in results) {
      counts[result.outcome] = counts[result.outcome]! + 1;
    }
    return counts;
  }

  static TMLanguageOutcome _classify(TMExecutionOutcome outcome) {
    return switch (outcome) {
      TMExecutionOutcome.accepted => TMLanguageOutcome.accepted,
      TMExecutionOutcome.haltedRejected => TMLanguageOutcome.rejected,
      TMExecutionOutcome.provenCycle => TMLanguageOutcome.provenCycle,
      TMExecutionOutcome.boundedUnknown ||
      TMExecutionOutcome.cancelled ||
      TMExecutionOutcome.invalidMachine =>
        TMLanguageOutcome.inconclusive,
    };
  }

  static Iterable<String> _shortlex(
    List<String> alphabet,
    int maxLength,
  ) sync* {
    yield '';
    for (var length = 1; length <= maxLength; length++) {
      yield* _wordsOfLength(alphabet, '', length);
    }
  }

  static Iterable<String> _wordsOfLength(
    List<String> alphabet,
    String prefix,
    int remaining,
  ) sync* {
    if (remaining == 0) {
      yield prefix;
      return;
    }
    for (final symbol in alphabet) {
      yield* _wordsOfLength(alphabet, '$prefix$symbol', remaining - 1);
    }
  }
}
