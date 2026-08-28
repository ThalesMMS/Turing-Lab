import 'dart:collection';

import '../messages/structured_message.dart';

enum BatchOutcomeCode {
  accepted,
  rejected,
  output,
  undefinedTransition,
  conflict,
  invalidInput,
  boundedUnknown,
  timeout,
  configurationLimit,
  provenCycle,
  cancelled,
  modelError,
  staleRequest,
}

extension BatchOutcomeCodeClassification on BatchOutcomeCode {
  bool get isSuccessful =>
      this == BatchOutcomeCode.accepted || this == BatchOutcomeCode.output;

  bool get isInconclusive => switch (this) {
    BatchOutcomeCode.boundedUnknown ||
    BatchOutcomeCode.timeout ||
    BatchOutcomeCode.configurationLimit ||
    BatchOutcomeCode.cancelled ||
    BatchOutcomeCode.staleRequest => true,
    _ => false,
  };
}

enum BatchTraceRetention { none, failuresOnly, selectedCase, all }

enum BatchTokenizationMode { rawString, unicodeScalar, explicitTokens }

final class BatchInputCase {
  BatchInputCase({
    required this.id,
    required this.input,
    Iterable<String>? tokens,
  }) : tokens = tokens == null ? null : List<String>.unmodifiable(tokens);

  final String id;
  final String input;
  final List<String>? tokens;

  List<StructuredMessage> validate() {
    final issues = <StructuredMessage>[];
    if (id.trim().isEmpty) issues.add(_nonEmpty('case-id'));
    if (tokens?.any((token) => token.isEmpty) ?? false) {
      issues.add(_nonEmpty('explicit-input-tokens'));
    }
    return issues;
  }

  Map<String, Object?> toJson() => {
    'id': id,
    'input': input,
    if (tokens != null) 'tokens': tokens,
  };
}

final class BatchExecutionLimits {
  static const int maxRetainedTraceStepsHardCap = 10000;

  const BatchExecutionLimits({
    this.maxSteps = 10000,
    this.maxConfigurations = 100000,
    this.timeout = const Duration(seconds: 5),
    this.maxRetainedTraceSteps = 1000,
  });

  final int maxSteps;
  final int maxConfigurations;
  final Duration timeout;
  final int maxRetainedTraceSteps;

  List<StructuredMessage> validate() => [
    if (maxSteps <= 0) _positive('step-limit'),
    if (maxConfigurations <= 0) _positive('configuration-limit'),
    if (timeout <= Duration.zero) _positive('timeout'),
    if (maxRetainedTraceSteps < 0) _nonNegative('retained-trace-limit'),
    if (maxRetainedTraceSteps > maxRetainedTraceStepsHardCap)
      _maximum('retained-trace-limit', maxRetainedTraceStepsHardCap),
  ];

  Map<String, Object?> toJson() => {
    'maxSteps': maxSteps,
    'maxConfigurations': maxConfigurations,
    'timeoutMicros': timeout.inMicroseconds,
    'maxRetainedTraceSteps': maxRetainedTraceSteps,
  };
}

final class BatchExecutionRequest {
  static const int maxCaseCount = 10000;
  static const int maxSupportedConcurrency = 8;

  BatchExecutionRequest({
    required this.modelId,
    required this.modelRevision,
    required this.strategyId,
    required this.tokenizationMode,
    required Iterable<BatchInputCase> cases,
    this.sharedLimits = const BatchExecutionLimits(),
    Map<String, BatchExecutionLimits> perCaseLimits = const {},
    this.traceRetention = BatchTraceRetention.none,
    this.selectedTraceCaseId,
    this.stopOnFirstFailure = false,
    this.maxConcurrency = 2,
    this.generation = 0,
  }) : cases = List<BatchInputCase>.unmodifiable(cases),
       perCaseLimits = Map<String, BatchExecutionLimits>.unmodifiable(
         perCaseLimits,
       );

  final String modelId;
  final String modelRevision;
  final String strategyId;
  final BatchTokenizationMode tokenizationMode;
  final List<BatchInputCase> cases;
  final BatchExecutionLimits sharedLimits;
  final Map<String, BatchExecutionLimits> perCaseLimits;
  final BatchTraceRetention traceRetention;
  final String? selectedTraceCaseId;
  final bool stopOnFirstFailure;
  final int maxConcurrency;
  final int generation;

  BatchExecutionLimits limitsFor(String caseId) =>
      perCaseLimits[caseId] ?? sharedLimits;

  bool requestsTraceFor(String caseId) => switch (traceRetention) {
    BatchTraceRetention.none => false,
    BatchTraceRetention.failuresOnly => true,
    BatchTraceRetention.selectedCase => selectedTraceCaseId == caseId,
    BatchTraceRetention.all => true,
  };

  bool retainsTraceFor(BatchCaseResult result) => switch (traceRetention) {
    BatchTraceRetention.none => false,
    BatchTraceRetention.failuresOnly => !result.outcome.isSuccessful,
    BatchTraceRetention.selectedCase =>
      selectedTraceCaseId == result.inputCase.id,
    BatchTraceRetention.all => true,
  };

  List<StructuredMessage> validate() {
    final issues = <StructuredMessage>[
      if (modelId.trim().isEmpty) _nonEmpty('model-id'),
      if (modelRevision.trim().isEmpty) _nonEmpty('model-revision'),
      if (strategyId.trim().isEmpty) _nonEmpty('strategy-id'),
      if (maxConcurrency <= 0) _positive('maximum-concurrency'),
      if (maxConcurrency > maxSupportedConcurrency)
        _maximum('maximum-concurrency', maxSupportedConcurrency),
      if (cases.length > maxCaseCount) _maximum('batch-size', maxCaseCount),
      if (generation < 0) _nonNegative('request-generation'),
      ...sharedLimits.validate(),
    ];
    final ids = <String>{};
    for (var index = 0; index < cases.length; index++) {
      final inputCase = cases[index];
      final caseIssues = inputCase.validate();
      if (caseIssues.isNotEmpty) {
        issues
          ..add(_caseContext(index, inputCase.id))
          ..addAll(caseIssues);
      }
      if (!ids.add(inputCase.id)) {
        issues.add(_caseMessage('duplicate-case-id', inputCase.id));
      }
      if (tokenizationMode == BatchTokenizationMode.explicitTokens &&
          inputCase.tokens == null) {
        issues.add(_caseMessage('explicit-tokens-required', inputCase.id));
      }
      final limitIssues = perCaseLimits[inputCase.id]?.validate() ?? const [];
      if (limitIssues.isNotEmpty) {
        issues
          ..add(_caseContext(index, inputCase.id))
          ..addAll(limitIssues);
      }
    }
    for (final caseId in perCaseLimits.keys) {
      if (!ids.contains(caseId)) {
        issues.add(_caseMessage('unknown-case-limits', caseId));
      }
    }
    if (traceRetention == BatchTraceRetention.selectedCase &&
        (selectedTraceCaseId == null || !ids.contains(selectedTraceCaseId))) {
      issues.add(_message('selected-trace-case-required'));
    }
    return issues;
  }

  Map<String, Object?> toJson() => {
    'modelId': modelId,
    'modelRevision': modelRevision,
    'strategyId': strategyId,
    'tokenizationMode': tokenizationMode.name,
    'cases': cases.map((inputCase) => inputCase.toJson()).toList(),
    'sharedLimits': sharedLimits.toJson(),
    'perCaseLimits': {
      for (final entry in perCaseLimits.entries)
        entry.key: entry.value.toJson(),
    },
    'traceRetention': traceRetention.name,
    'selectedTraceCaseId': selectedTraceCaseId,
    'stopOnFirstFailure': stopOnFirstFailure,
    'maxConcurrency': maxConcurrency,
    'generation': generation,
  };
}

final class BatchCaseExecution {
  BatchCaseExecution({
    required this.outcome,
    this.diagnosticCode,
    this.message,
    this.structuredMessage,
    Iterable<String> output = const [],
    Map<String, num> metrics = const {},
    Iterable<Map<String, Object?>> trace = const [],
  }) : output = List<String>.unmodifiable(output),
       metrics = Map<String, num>.unmodifiable(metrics),
       trace = List<Map<String, Object?>>.unmodifiable(
         trace.map((step) => Map<String, Object?>.unmodifiable(step)),
       );

  final BatchOutcomeCode outcome;
  final String? diagnosticCode;
  final String? message;
  final StructuredMessage? structuredMessage;
  final List<String> output;
  final Map<String, num> metrics;
  final List<Map<String, Object?>> trace;
}

final class BatchCaseResult {
  BatchCaseResult({
    required this.inputCase,
    required this.outcome,
    required this.elapsed,
    this.diagnosticCode,
    this.message,
    this.structuredMessage,
    Iterable<String> output = const [],
    Map<String, num> metrics = const {},
    Iterable<Map<String, Object?>> trace = const [],
  }) : output = List<String>.unmodifiable(output),
       metrics = Map<String, num>.unmodifiable(metrics),
       trace = List<Map<String, Object?>>.unmodifiable(
         trace.map((step) => Map<String, Object?>.unmodifiable(step)),
       );

  final BatchInputCase inputCase;
  final BatchOutcomeCode outcome;
  final Duration elapsed;
  final String? diagnosticCode;
  final String? message;
  final StructuredMessage? structuredMessage;
  final List<String> output;
  final Map<String, num> metrics;
  final List<Map<String, Object?>> trace;

  BatchCaseResult withoutTrace() => BatchCaseResult(
    inputCase: inputCase,
    outcome: outcome,
    elapsed: elapsed,
    diagnosticCode: diagnosticCode,
    message: message,
    structuredMessage: structuredMessage,
    output: output,
    metrics: metrics,
  );

  Map<String, Object?> toJson() => {
    'case': inputCase.toJson(),
    'outcome': outcome.name,
    'diagnosticCode': diagnosticCode,
    'message': message,
    if (structuredMessage != null)
      'structuredMessage': structuredMessage!.toJson(),
    'output': output,
    'metrics': SplayTreeMap<String, num>.of(metrics),
    'elapsedMicros': elapsed.inMicroseconds,
    'traceRetained': trace.isNotEmpty,
    'trace': trace,
  };
}

final class BatchValidationException implements Exception {
  BatchValidationException(Iterable<StructuredMessage> messages)
    : messages = List<StructuredMessage>.unmodifiable(messages);

  final List<StructuredMessage> messages;

  @override
  String toString() => 'Batch request validation failed.';
}

StructuredMessage _message(
  String code, {
  Map<String, StructuredMessageArgument> arguments = const {},
}) => StructuredMessage(
  namespace: 'batch.validation',
  code: code,
  category: StructuredMessageCategory.validation,
  severity: StructuredMessageSeverity.error,
  arguments: arguments,
);

StructuredMessage _fieldMessage(String code, String field) => _message(
  code,
  arguments: {
    'field': StructuredMessageArgument.outcome(field, role: 'validation-field'),
  },
);

StructuredMessage _nonEmpty(String field) => _fieldMessage('non-empty', field);
StructuredMessage _positive(String field) => _fieldMessage('positive', field);
StructuredMessage _nonNegative(String field) =>
    _fieldMessage('non-negative', field);

StructuredMessage _maximum(String field, int bound) => _message(
  'maximum',
  arguments: {
    'field': StructuredMessageArgument.outcome(field, role: 'validation-field'),
    'bound': StructuredMessageArgument.bound(bound),
  },
);

StructuredMessage _caseContext(int index, String caseId) => _message(
  'case-context',
  arguments: {
    'index': StructuredMessageArgument.index(index, role: 'case-index'),
    'case': StructuredMessageArgument.identifier(caseId, role: 'case'),
  },
);

StructuredMessage _caseMessage(String code, String caseId) => _message(
  code,
  arguments: {
    'case': StructuredMessageArgument.identifier(caseId, role: 'case'),
  },
);

final class BatchProgress {
  const BatchProgress({
    required this.generation,
    required this.completed,
    required this.total,
    required this.result,
  });

  final int generation;
  final int completed;
  final int total;
  final BatchCaseResult result;
}

final class BatchExecutionReport {
  BatchExecutionReport({
    required this.request,
    required Iterable<BatchCaseResult> results,
    required this.startedAt,
    required this.elapsed,
  }) : results = List<BatchCaseResult>.unmodifiable(results);

  final BatchExecutionRequest request;
  final List<BatchCaseResult> results;
  final DateTime startedAt;
  final Duration elapsed;

  bool get wasCancelled =>
      results.any((result) => result.outcome == BatchOutcomeCode.cancelled);

  Map<BatchOutcomeCode, int> get outcomeCounts {
    final counts = <BatchOutcomeCode, int>{};
    for (final result in results) {
      counts.update(result.outcome, (count) => count + 1, ifAbsent: () => 1);
    }
    return Map<BatchOutcomeCode, int>.unmodifiable(counts);
  }

  Map<String, Object?> toJson() => {
    'schema': {'id': 'turing-lab.batch-report', 'version': 1},
    'request': request.toJson(),
    'startedAt': startedAt.toUtc().toIso8601String(),
    'elapsedMicros': elapsed.inMicroseconds,
    'outcomeCounts': {
      for (final outcome in BatchOutcomeCode.values)
        if (outcomeCounts.containsKey(outcome))
          outcome.name: outcomeCounts[outcome],
    },
    'results': results.map((result) => result.toJson()).toList(),
  };
}
