import 'dart:async';

import 'batch_execution_models.dart';

final class BatchCancellationToken {
  BatchCancellationToken({BatchCancellationToken? parent}) : _parent = parent;

  final BatchCancellationToken? _parent;
  bool _cancelled = false;

  bool get isCancelled => _cancelled || (_parent?.isCancelled ?? false);

  void cancel() => _cancelled = true;
}

abstract interface class BatchCaseExecutor {
  String get modelId;
  String get modelRevision;
  Set<String> get strategyIds;

  Future<BatchCaseExecution> execute(
    BatchInputCase inputCase, {
    required String strategyId,
    required BatchTokenizationMode tokenizationMode,
    required BatchExecutionLimits limits,
    required bool retainTrace,
    required BatchCancellationToken cancellationToken,
  });
}

final class BatchRunHandle {
  const BatchRunHandle({
    required this.generation,
    required this.progress,
    required this.report,
    required this.cancel,
  });

  final int generation;
  final Stream<BatchProgress> progress;
  final Future<BatchExecutionReport> report;
  final void Function() cancel;
}

final class BatchExecutionRunner {
  const BatchExecutionRunner();

  BatchRunHandle start(
    BatchExecutionRequest request,
    BatchCaseExecutor executor,
  ) {
    final validationIssues = request.validate();
    if (validationIssues.isNotEmpty) {
      throw BatchValidationException(validationIssues);
    }
    if (request.modelId != executor.modelId) {
      throw ArgumentError(
        'Request model ${request.modelId} does not match executor model '
        '${executor.modelId}.',
      );
    }
    if (!executor.strategyIds.contains(request.strategyId)) {
      throw ArgumentError('Unsupported batch strategy ${request.strategyId}.');
    }

    final cancellationToken = BatchCancellationToken();
    final progressController = StreamController<BatchProgress>.broadcast(
      sync: true,
    );
    final report = _run(
      request,
      executor,
      cancellationToken,
      progressController,
    );
    return BatchRunHandle(
      generation: request.generation,
      progress: progressController.stream,
      report: report,
      cancel: cancellationToken.cancel,
    );
  }

  Future<BatchExecutionReport> _run(
    BatchExecutionRequest request,
    BatchCaseExecutor executor,
    BatchCancellationToken cancellationToken,
    StreamController<BatchProgress> progressController,
  ) async {
    final startedAt = DateTime.now().toUtc();
    final runStopwatch = Stopwatch()..start();
    final results = List<BatchCaseResult?>.filled(request.cases.length, null);
    var nextIndex = 0;
    var completed = 0;
    var stopQueuedWork = false;

    Future<void> publish(int index, BatchCaseResult result) async {
      results[index] = result;
      completed++;
      if (!progressController.isClosed) {
        progressController.add(
          BatchProgress(
            generation: request.generation,
            completed: completed,
            total: request.cases.length,
            result: result,
          ),
        );
      }
      if (request.stopOnFirstFailure && !result.outcome.isSuccessful) {
        stopQueuedWork = true;
      }
    }

    Future<void> worker() async {
      while (true) {
        final index = nextIndex++;
        if (index >= request.cases.length) return;
        final inputCase = request.cases[index];
        if (cancellationToken.isCancelled || stopQueuedWork) {
          await publish(
            index,
            _cancelled(
              inputCase,
              stopQueuedWork
                  ? 'batch.stopped-after-failure'
                  : 'batch.cancelled-before-start',
            ),
          );
          continue;
        }
        if (request.modelRevision != executor.modelRevision) {
          await publish(
            index,
            BatchCaseResult(
              inputCase: inputCase,
              outcome: BatchOutcomeCode.staleRequest,
              elapsed: Duration.zero,
              diagnosticCode: 'batch.stale-model-revision',
            ),
          );
          continue;
        }
        await publish(
          index,
          await _executeCase(request, executor, inputCase, cancellationToken),
        );
      }
    }

    try {
      await Future.wait([
        for (
          var workerIndex = 0;
          workerIndex < request.maxConcurrency &&
              workerIndex < request.cases.length;
          workerIndex++
        )
          worker(),
      ]);
      runStopwatch.stop();
      return BatchExecutionReport(
        request: request,
        results: results.cast<BatchCaseResult>(),
        startedAt: startedAt,
        elapsed: runStopwatch.elapsed,
      );
    } finally {
      if (!progressController.isClosed) await progressController.close();
    }
  }

  Future<BatchCaseResult> _executeCase(
    BatchExecutionRequest request,
    BatchCaseExecutor executor,
    BatchInputCase inputCase,
    BatchCancellationToken parentCancellation,
  ) async {
    final stopwatch = Stopwatch()..start();
    final limits = request.limitsFor(inputCase.id);
    final cancellation = BatchCancellationToken(parent: parentCancellation);
    try {
      final execution = await executor
          .execute(
            inputCase,
            strategyId: request.strategyId,
            tokenizationMode: request.tokenizationMode,
            limits: limits,
            retainTrace: request.requestsTraceFor(inputCase.id),
            cancellationToken: cancellation,
          )
          .timeout(
            limits.timeout,
            onTimeout: () {
              cancellation.cancel();
              return BatchCaseExecution(
                outcome: BatchOutcomeCode.timeout,
                diagnosticCode: 'batch.case-timeout',
              );
            },
          );
      stopwatch.stop();
      if (parentCancellation.isCancelled &&
          execution.outcome != BatchOutcomeCode.cancelled) {
        return _cancelled(inputCase, 'batch.cancelled-during-execution');
      }
      var trace = execution.trace;
      var diagnosticCode = execution.diagnosticCode;
      if (trace.length > limits.maxRetainedTraceSteps) {
        trace = trace.take(limits.maxRetainedTraceSteps).toList();
        diagnosticCode ??= 'batch.trace-truncated';
      }
      var result = BatchCaseResult(
        inputCase: inputCase,
        outcome: execution.outcome,
        elapsed: stopwatch.elapsed,
        diagnosticCode: diagnosticCode,
        message: execution.message,
        structuredMessage: execution.structuredMessage,
        output: execution.output,
        metrics: execution.metrics,
        trace: trace,
      );
      if (!request.retainsTraceFor(result)) result = result.withoutTrace();
      return result;
    } catch (error) {
      stopwatch.stop();
      if (parentCancellation.isCancelled || cancellation.isCancelled) {
        return _cancelled(inputCase, 'batch.cancelled-during-execution');
      }
      return BatchCaseResult(
        inputCase: inputCase,
        outcome: BatchOutcomeCode.modelError,
        elapsed: stopwatch.elapsed,
        diagnosticCode: 'batch.executor-failure',
        message: error.toString(),
      );
    }
  }
}

BatchCaseResult _cancelled(BatchInputCase inputCase, String diagnosticCode) =>
    BatchCaseResult(
      inputCase: inputCase,
      outcome: BatchOutcomeCode.cancelled,
      elapsed: Duration.zero,
      diagnosticCode: diagnosticCode,
    );
