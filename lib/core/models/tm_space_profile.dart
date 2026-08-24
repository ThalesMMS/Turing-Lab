import 'tm_execution_analysis.dart';

enum TMSpaceEnumerationMode { exhaustive, sampled }

class TMSpaceProfileLimits {
  const TMSpaceProfileLimits({
    this.maxInputLength = 3,
    this.maxCandidatesPerLength = 100,
    this.maxStepsPerInput = 10000,
    this.maxConfigurationsPerInput = 100000,
    this.timeoutPerInput = const Duration(seconds: 5),
    this.operationsPerBatch = 250,
  });

  final int maxInputLength;
  final int maxCandidatesPerLength;
  final int maxStepsPerInput;
  final int maxConfigurationsPerInput;
  final Duration timeoutPerInput;
  final int operationsPerBatch;
}

class TMSpaceInputProfile {
  const TMSpaceInputProfile({
    required this.input,
    required this.analysis,
    required this.metrics,
  });

  final String input;
  final TMExecutionAnalysis analysis;
  final TMExecutionSpaceMetrics metrics;

  bool get isIncomplete => !analysis.isExact;
}

class TMSpaceMaximum {
  const TMSpaceMaximum({required this.value, required this.witnessInput});

  final int value;
  final String witnessInput;
}

class TMSpaceLengthProfile {
  TMSpaceLengthProfile({
    required this.inputLength,
    required this.requestedCandidates,
    required this.scheduledCandidates,
    required this.enumerationMode,
    required Iterable<TMSpaceInputProfile> inputs,
    required this.cancelled,
  }) : inputs = List.unmodifiable(inputs) {
    TMSpaceMaximum? span;
    TMSpaceMaximum? nonBlank;
    for (final input in this.inputs) {
      if (span == null || input.metrics.maximumVisitedSpan > span.value) {
        span = TMSpaceMaximum(
          value: input.metrics.maximumVisitedSpan,
          witnessInput: input.input,
        );
      }
      if (nonBlank == null ||
          input.metrics.maximumNonBlankCells > nonBlank.value) {
        nonBlank = TMSpaceMaximum(
          value: input.metrics.maximumNonBlankCells,
          witnessInput: input.input,
        );
      }
    }
    maximumVisitedSpan = span;
    maximumNonBlankCells = nonBlank;
  }

  final int inputLength;
  final BigInt requestedCandidates;
  final int scheduledCandidates;
  final TMSpaceEnumerationMode enumerationMode;
  final List<TMSpaceInputProfile> inputs;
  final bool cancelled;
  late final TMSpaceMaximum? maximumVisitedSpan;
  late final TMSpaceMaximum? maximumNonBlankCells;

  int get inconclusiveInputs =>
      inputs.where((input) => input.isIncomplete).length;

  bool get isIncomplete =>
      enumerationMode == TMSpaceEnumerationMode.sampled ||
      cancelled ||
      inconclusiveInputs > 0;
}

class TMSpaceProfileProgress {
  const TMSpaceProfileProgress({
    required this.evaluatedCandidates,
    required this.scheduledCandidates,
    required this.requestedCandidates,
    this.currentInputLength,
    this.currentInput,
  });

  final int evaluatedCandidates;
  final int scheduledCandidates;
  final BigInt requestedCandidates;
  final int? currentInputLength;
  final String? currentInput;

  double get fraction =>
      scheduledCandidates == 0 ? 1 : evaluatedCandidates / scheduledCandidates;
}

class TMSpaceProfileReport {
  TMSpaceProfileReport({
    required this.limits,
    required Iterable<String> alphabet,
    required this.requestedCandidates,
    required this.scheduledCandidates,
    required Iterable<TMSpaceLengthProfile> rows,
    required this.cancelled,
    required this.isNondeterministic,
    required this.executionTime,
  })  : alphabet = List.unmodifiable(alphabet),
        rows = List.unmodifiable(rows);

  final TMSpaceProfileLimits limits;
  final List<String> alphabet;
  final BigInt requestedCandidates;
  final int scheduledCandidates;
  final List<TMSpaceLengthProfile> rows;
  final bool cancelled;
  final bool isNondeterministic;
  final Duration executionTime;

  int get evaluatedCandidates =>
      rows.fold(0, (total, row) => total + row.inputs.length);

  bool get isIncomplete => cancelled || rows.any((row) => row.isIncomplete);
}
