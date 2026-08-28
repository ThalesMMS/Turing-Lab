import '../messages/structured_message.dart';
import '../models/tm.dart';
import '../models/tm_execution_analysis.dart';
import '../models/tm_space_profile.dart';
import '../result.dart';
import 'tm_execution_analyzer.dart';
import 'tm_messages.dart';

typedef TMSpaceProfileProgressCallback =
    void Function(TMSpaceProfileProgress progress);

/// Profiles observed single-tape space over bounded groups of input words.
class TMSpaceProfiler {
  const TMSpaceProfiler._();

  static BigInt countCandidatesForLength(
    Iterable<String> alphabet,
    int inputLength,
  ) {
    if (inputLength < 0) {
      throw ArgumentError.value(
        inputLength,
        'inputLength',
        'must be non-negative',
      );
    }
    return BigInt.from(alphabet.toSet().length).pow(inputLength);
  }

  static BigInt countCandidatesThroughLength(
    Iterable<String> alphabet,
    int maxInputLength,
  ) {
    if (maxInputLength < 0) {
      throw ArgumentError.value(
        maxInputLength,
        'maxInputLength',
        'must be non-negative',
      );
    }
    var total = BigInt.zero;
    for (var length = 0; length <= maxInputLength; length++) {
      total += countCandidatesForLength(alphabet, length);
    }
    return total;
  }

  static int countScheduledCandidates(
    Iterable<String> alphabet,
    TMSpaceProfileLimits limits,
  ) {
    var total = 0;
    final cap = BigInt.from(limits.maxCandidatesPerLength);
    for (var length = 0; length <= limits.maxInputLength; length++) {
      final requested = countCandidatesForLength(alphabet, length);
      total += requested > cap
          ? limits.maxCandidatesPerLength
          : requested.toInt();
    }
    return total;
  }

  static Future<Result<TMSpaceProfileReport>> profile(
    TM tm, {
    TMSpaceProfileLimits limits = const TMSpaceProfileLimits(),
    TMSpaceProfileProgressCallback? onProgress,
    bool Function()? isCancelled,
  }) async {
    final validationError = _validate(tm, limits);
    if (validationError != null) {
      return Failure(
        validationError.legacy,
        structuredMessage: validationError.structured,
      );
    }

    final alphabet = tm.alphabet.toSet().toList()..sort();
    final requested = countCandidatesThroughLength(
      alphabet,
      limits.maxInputLength,
    );
    final scheduled = countScheduledCandidates(alphabet, limits);
    final rows = <TMSpaceLengthProfile>[];
    final stopwatch = Stopwatch()..start();
    var evaluated = 0;
    var cancelled = false;

    void publish({int? length, String? input}) {
      onProgress?.call(
        TMSpaceProfileProgress(
          evaluatedCandidates: evaluated,
          scheduledCandidates: scheduled,
          requestedCandidates: requested,
          currentInputLength: length,
          currentInput: input,
        ),
      );
    }

    publish();
    for (var length = 0; length <= limits.maxInputLength; length++) {
      if (isCancelled?.call() == true) {
        cancelled = true;
        break;
      }
      final requestedForLength = countCandidatesForLength(alphabet, length);
      final cap = BigInt.from(limits.maxCandidatesPerLength);
      final scheduledForLength = requestedForLength > cap
          ? limits.maxCandidatesPerLength
          : requestedForLength.toInt();
      final inputs = <TMSpaceInputProfile>[];
      var rowCancelled = false;

      for (final input in _wordsOfLength(alphabet, '', length)) {
        if (inputs.length >= scheduledForLength) break;
        if (isCancelled?.call() == true) {
          cancelled = true;
          rowCancelled = true;
          break;
        }
        final analysis = await TMExecutionAnalyzer.analyze(
          tm,
          input,
          maxSteps: limits.maxStepsPerInput,
          maxConfigurations: limits.maxConfigurationsPerInput,
          timeout: limits.timeoutPerInput,
          operationsPerBatch: limits.operationsPerBatch,
          includeTrace: false,
          isCancelled: isCancelled,
        );
        if (analysis.outcome == TMExecutionOutcome.invalidMachine) {
          stopwatch.stop();
          return Failure(
            analysis.message,
            structuredMessage: analysis.structuredMessage,
          );
        }
        final metrics = analysis.spaceMetrics;
        if (metrics == null) {
          stopwatch.stop();
          final message = TmSpaceProfileMessages.missingSpaceMetrics();
          return Failure(
            'Bounded execution did not return tape-space metrics.',
            structuredMessage: message,
          );
        }
        inputs.add(
          TMSpaceInputProfile(
            input: input,
            analysis: analysis,
            metrics: metrics,
          ),
        );
        evaluated++;
        publish(length: length, input: input);

        if (analysis.outcome == TMExecutionOutcome.cancelled) {
          cancelled = true;
          rowCancelled = true;
          break;
        }
        await Future<void>.delayed(Duration.zero);
      }

      rows.add(
        TMSpaceLengthProfile(
          inputLength: length,
          requestedCandidates: requestedForLength,
          scheduledCandidates: scheduledForLength,
          enumerationMode: requestedForLength > cap
              ? TMSpaceEnumerationMode.sampled
              : TMSpaceEnumerationMode.exhaustive,
          inputs: inputs,
          cancelled: rowCancelled,
        ),
      );
      if (cancelled) break;
    }

    stopwatch.stop();
    return ResultFactory.success(
      TMSpaceProfileReport(
        limits: limits,
        alphabet: alphabet,
        requestedCandidates: requested,
        scheduledCandidates: scheduled,
        rows: rows,
        cancelled: cancelled,
        isNondeterministic: tm.isNondeterministic,
        executionTime: stopwatch.elapsed,
      ),
    );
  }

  static ({String legacy, StructuredMessage structured})? _validate(
    TM tm,
    TMSpaceProfileLimits limits,
  ) {
    if (tm.states.isEmpty) {
      return (
        legacy: 'Turing machine must have at least one state.',
        structured: TmSpaceProfileMessages.emptyMachine(),
      );
    }
    if (tm.initialState == null || !tm.states.contains(tm.initialState)) {
      return (
        legacy: 'Turing machine must define a valid initial state.',
        structured: TmSpaceProfileMessages.missingInitialState(),
      );
    }
    if (limits.maxInputLength < 0) {
      return (
        legacy: 'Maximum input length must be non-negative.',
        structured: TmSpaceProfileMessages.maxInputLengthInvalid(),
      );
    }
    if (limits.maxCandidatesPerLength <= 0) {
      return (
        legacy: 'Candidate cap per length must be greater than zero.',
        structured: TmSpaceProfileMessages.candidateCapInvalid(),
      );
    }
    if (limits.maxStepsPerInput <= 0) {
      return (
        legacy: 'Step limit must be greater than zero.',
        structured: TmSpaceProfileMessages.stepLimitInvalid(),
      );
    }
    if (limits.maxConfigurationsPerInput <= 0) {
      return (
        legacy: 'Configuration limit must be greater than zero.',
        structured: TmSpaceProfileMessages.configurationLimitInvalid(),
      );
    }
    if (limits.timeoutPerInput <= Duration.zero) {
      return (
        legacy: 'Timeout must be greater than zero.',
        structured: TmSpaceProfileMessages.timeoutInvalid(),
      );
    }
    if (limits.operationsPerBatch <= 0) {
      return (
        legacy: 'Operations per batch must be greater than zero.',
        structured: TmSpaceProfileMessages.operationsPerBatchInvalid(),
      );
    }
    return null;
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
