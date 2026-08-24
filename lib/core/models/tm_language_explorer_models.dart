import 'dart:collection';

import 'tm_execution_analysis.dart';

enum TMLanguageOutcome { accepted, rejected, provenCycle, inconclusive }

class TMLanguageExplorerLimits {
  const TMLanguageExplorerLimits({
    this.maxInputLength = 3,
    this.maxCandidates = 100,
    this.maxStepsPerInput = 10000,
    this.maxConfigurationsPerInput = 100000,
    this.timeoutPerInput = const Duration(seconds: 5),
    this.operationsPerBatch = 250,
  });

  final int maxInputLength;
  final int maxCandidates;
  final int maxStepsPerInput;
  final int maxConfigurationsPerInput;
  final Duration timeoutPerInput;
  final int operationsPerBatch;
}

class TMLanguageWordResult {
  const TMLanguageWordResult({
    required this.input,
    required this.outcome,
    required this.analysis,
  });

  final String input;
  final TMLanguageOutcome outcome;
  final TMExecutionAnalysis analysis;
}

class TMLanguageExplorerProgress {
  const TMLanguageExplorerProgress({
    required this.evaluatedCandidates,
    required this.plannedCandidates,
    required this.requestedCandidates,
    required this.counts,
    this.currentInput,
  });

  final int evaluatedCandidates;
  final int plannedCandidates;
  final BigInt requestedCandidates;
  final String? currentInput;
  final Map<TMLanguageOutcome, int> counts;

  double get fraction =>
      plannedCandidates == 0 ? 1 : evaluatedCandidates / plannedCandidates;
}

class TMLanguageExplorerReport {
  TMLanguageExplorerReport({
    required this.limits,
    required Iterable<String> alphabet,
    required this.requestedCandidates,
    required this.plannedCandidates,
    required Iterable<TMLanguageWordResult> results,
    required this.cancelled,
    required this.truncatedByCandidateCap,
    required this.executionTime,
  })  : alphabet = List.unmodifiable(alphabet),
        results = List.unmodifiable(results);

  final TMLanguageExplorerLimits limits;
  final List<String> alphabet;
  final BigInt requestedCandidates;
  final int plannedCandidates;
  final List<TMLanguageWordResult> results;
  final bool cancelled;
  final bool truncatedByCandidateCap;
  final Duration executionTime;

  int count(TMLanguageOutcome outcome) =>
      results.where((result) => result.outcome == outcome).length;

  List<TMLanguageWordResult> resultsFor(TMLanguageOutcome outcome) =>
      UnmodifiableListView(
        results.where((result) => result.outcome == outcome),
      );

  bool get isPartial =>
      cancelled ||
      truncatedByCandidateCap ||
      results.any(
        (result) => result.outcome == TMLanguageOutcome.inconclusive,
      );
}

class TMLanguageExplorerCancellationToken {
  bool _cancelled = false;

  bool get isCancelled => _cancelled;

  void cancel() {
    _cancelled = true;
  }
}
