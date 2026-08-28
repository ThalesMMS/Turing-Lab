import 'dart:async';
import 'dart:convert';

import 'package:test/test.dart';
import 'package:turing_lab/core/batch_execution/batch_execution.dart';
import 'package:turing_lab/core/messages/structured_message.dart';

void main() {
  group('batch request', () {
    test('rejects duplicate IDs, invalid limits, and unknown trace case', () {
      final request = BatchExecutionRequest(
        modelId: 'model',
        modelRevision: 'r1',
        strategyId: 'simulate',
        tokenizationMode: BatchTokenizationMode.rawString,
        cases: [
          BatchInputCase(id: 'same', input: 'a'),
          BatchInputCase(id: 'same', input: 'b'),
        ],
        sharedLimits: const BatchExecutionLimits(maxSteps: 0),
        traceRetention: BatchTraceRetention.selectedCase,
        selectedTraceCaseId: 'missing',
      );

      expect(request.validate(), hasLength(3));
    });

    test('preserves duplicate inputs under distinct stable case IDs', () {
      final request = _request(inputs: const ['a', 'a', '']);

      expect(request.validate(), isEmpty);
      expect(request.cases.map((inputCase) => inputCase.input), ['a', 'a', '']);
      expect(
        request.cases.map((inputCase) => inputCase.id).toSet(),
        hasLength(3),
      );
    });

    test('requires token lists when explicit tokenization is selected', () {
      final request = BatchExecutionRequest(
        modelId: 'model',
        modelRevision: 'r1',
        strategyId: 'simulate',
        tokenizationMode: BatchTokenizationMode.explicitTokens,
        cases: [BatchInputCase(id: 'case', input: 'aa bb')],
      );

      expect(request.validate().map((message) => message.stableCode), [
        'batch.validation.explicit-tokens-required',
      ]);
    });

    test('enforces hard batch, trace, and concurrency caps', () {
      final request = BatchExecutionRequest(
        modelId: 'model',
        modelRevision: 'r1',
        strategyId: 'simulate',
        tokenizationMode: BatchTokenizationMode.rawString,
        cases: [
          for (
            var index = 0;
            index <= BatchExecutionRequest.maxCaseCount;
            index++
          )
            BatchInputCase(id: 'case-$index', input: ''),
        ],
        sharedLimits: const BatchExecutionLimits(
          maxRetainedTraceSteps:
              BatchExecutionLimits.maxRetainedTraceStepsHardCap + 1,
        ),
        maxConcurrency: BatchExecutionRequest.maxSupportedConcurrency + 1,
      );

      final issues = request.validate();
      expect(
        issues.map((message) => message.stableCode),
        everyElement('batch.validation.maximum'),
      );
      expect(issues.map((message) => message.arguments['field']!.value), [
        'maximum-concurrency',
        'batch-size',
        'retained-trace-limit',
      ]);
    });
  });

  group('batch runner', () {
    test(
      'limits concurrency, streams progress, and restores input order',
      () async {
        final executor = _FakeExecutor(
          delays: const {
            'case-0': Duration(milliseconds: 30),
            'case-1': Duration(milliseconds: 5),
            'case-2': Duration(milliseconds: 10),
          },
        );
        final request = _request(inputs: const ['slow', 'fast', 'middle']);
        final handle = const BatchExecutionRunner().start(request, executor);
        final progress = <BatchProgress>[];
        final subscription = handle.progress.listen(progress.add);

        final report = await handle.report;
        await subscription.cancel();

        expect(executor.maximumActive, 2);
        expect(progress, hasLength(3));
        expect(progress.first.result.inputCase.id, 'case-1');
        expect(report.results.map((result) => result.inputCase.id), [
          'case-0',
          'case-1',
          'case-2',
        ]);
        expect(report.results.map((result) => result.outcome), [
          BatchOutcomeCode.accepted,
          BatchOutcomeCode.accepted,
          BatchOutcomeCode.accepted,
        ]);
      },
    );

    test(
      'cancels running and queued work without calling it rejection',
      () async {
        final entered = Completer<void>();
        final executor = _FakeExecutor(
          onExecute: (_, token) async {
            if (!entered.isCompleted) entered.complete();
            while (!token.isCancelled) {
              await Future<void>.delayed(const Duration(milliseconds: 1));
            }
            return BatchCaseExecution(
              outcome: BatchOutcomeCode.cancelled,
              diagnosticCode: 'fake.cancelled',
            );
          },
        );
        final request = _request(
          inputs: const ['a', 'b', 'c'],
          maxConcurrency: 1,
        );
        final handle = const BatchExecutionRunner().start(request, executor);
        await entered.future;
        handle.cancel();

        final report = await handle.report;

        expect(report.results.map((result) => result.outcome).toSet(), {
          BatchOutcomeCode.cancelled,
        });
        expect(report.wasCancelled, isTrue);
      },
    );

    test(
      'reports timeout and stale revisions as inconclusive outcomes',
      () async {
        final timeoutExecutor = _FakeExecutor(
          onExecute: (_, __) async {
            await Future<void>.delayed(const Duration(milliseconds: 50));
            return BatchCaseExecution(outcome: BatchOutcomeCode.accepted);
          },
        );
        final timeoutRequest = _request(
          inputs: const ['a'],
          limits: const BatchExecutionLimits(
            timeout: Duration(milliseconds: 2),
          ),
        );
        final timeout = await const BatchExecutionRunner()
            .start(timeoutRequest, timeoutExecutor)
            .report;

        expect(timeout.results.single.outcome, BatchOutcomeCode.timeout);
        expect(timeout.results.single.outcome.isInconclusive, isTrue);

        final staleExecutor = _FakeExecutor(revision: 'r2');
        final stale = await const BatchExecutionRunner()
            .start(_request(inputs: const ['a']), staleExecutor)
            .report;

        expect(stale.results.single.outcome, BatchOutcomeCode.staleRequest);
        expect(staleExecutor.executions, 0);
      },
    );

    test(
      'retains only failed traces and enforces the hard trace cap',
      () async {
        final executor = _FakeExecutor(
          onExecute: (inputCase, _) async => BatchCaseExecution(
            outcome: inputCase.input == 'ok'
                ? BatchOutcomeCode.accepted
                : BatchOutcomeCode.rejected,
            trace: [
              for (var index = 0; index < 5; index++) {'step': index},
            ],
          ),
        );
        final request = _request(
          inputs: const ['ok', 'failure'],
          traceRetention: BatchTraceRetention.failuresOnly,
          limits: const BatchExecutionLimits(maxRetainedTraceSteps: 2),
        );

        final report = await const BatchExecutionRunner()
            .start(request, executor)
            .report;

        expect(report.results[0].trace, isEmpty);
        expect(report.results[1].trace, hasLength(2));
        expect(report.results[1].diagnosticCode, 'batch.trace-truncated');
      },
    );

    test('stop-on-first-failure cancels queued cases explicitly', () async {
      final executor = _FakeExecutor(
        onExecute: (inputCase, _) async => BatchCaseExecution(
          outcome: inputCase.input == 'bad'
              ? BatchOutcomeCode.rejected
              : BatchOutcomeCode.accepted,
        ),
      );
      final request = _request(
        inputs: const ['bad', 'queued'],
        maxConcurrency: 1,
        stopOnFirstFailure: true,
      );

      final report = await const BatchExecutionRunner()
          .start(request, executor)
          .report;

      expect(report.results[0].outcome, BatchOutcomeCode.rejected);
      expect(report.results[1].outcome, BatchOutcomeCode.cancelled);
      expect(report.results[1].diagnosticCode, 'batch.stopped-after-failure');
    });
  });

  group('batch inputs and reports', () {
    test(
      'generates bounded token words deterministically with an empty word',
      () {
        final generated = BatchInputGenerator.boundedWords(
          alphabet: const ['β', 'aa'],
          maxLength: 2,
          maxCount: 6,
        );

        expect(generated.map((inputCase) => inputCase.tokens), [
          <String>[],
          ['aa'],
          ['β'],
          ['aa', 'aa'],
          ['aa', 'β'],
          ['β', 'aa'],
        ]);
        expect(
          generated.map((inputCase) => inputCase.id).toSet(),
          hasLength(6),
        );
      },
    );

    test(
      'comparison flags exact row differences without claiming equivalence',
      () async {
        final left = await const BatchExecutionRunner()
            .start(_request(inputs: const ['a']), _FakeExecutor())
            .report;
        final right = await const BatchExecutionRunner()
            .start(
              _request(inputs: const ['a']),
              _FakeExecutor(
                onExecute: (_, __) async =>
                    BatchCaseExecution(outcome: BatchOutcomeCode.rejected),
              ),
            )
            .report;

        final comparison = BatchReportComparator.compare(left, right);

        expect(comparison.hasDifferences, isTrue);
        expect(comparison.cases.single.differs, isTrue);
        expect(comparison.provesGeneralEquivalence, isFalse);
      },
    );

    test('multiline parsing preserves whitespace, duplicates, and epsilon', () {
      final inputs = BatchInputGenerator.multiline('a\nε\na\n  \n');

      expect(inputs.map((inputCase) => inputCase.input), ['a', '', 'a', '  ']);
    });

    test(
      'CSV parsing handles IDs, commas, quotes, newlines, and empty input',
      () {
        final inputs = BatchInputFileParser.csv(
          'id,input\r\nfirst,"a,b"\r\nsecond,"a""b"\r\nthird,"line 1\nline 2"\r\nempty,',
        );

        expect(inputs.map((inputCase) => inputCase.id), [
          'first',
          'second',
          'third',
          'empty',
        ]);
        expect(inputs.map((inputCase) => inputCase.input), [
          'a,b',
          'a"b',
          'line 1\nline 2',
          '',
        ]);
        expect(
          () => BatchInputFileParser.csv('id,input\nsame,a\nsame,b'),
          throwsA(isA<BatchInputFormatException>()),
        );
      },
    );

    test('CSV failures preserve typed case IDs for presentation', () {
      Object? failure;
      try {
        BatchInputFileParser.csv('id,input\nsame,a\nsame,b');
      } catch (error) {
        failure = error;
      }

      expect(failure, isA<BatchInputFormatException>());
      final message = (failure! as BatchInputFormatException).structuredMessage;
      expect(message.stableCode, 'batch.import.duplicate-case-id');
      expect(message.arguments['case']!.value, 'same');
    });

    test(
      'JSON and CSV exports contain revision, limits, and escaped rows',
      () async {
        final request = _request(inputs: const ['a,"b"\n']);
        final report = await const BatchExecutionRunner()
            .start(request, _FakeExecutor())
            .report;
        final json = jsonDecode(BatchReportEncoder.json(report));
        final csv = BatchReportEncoder.csv(report);

        expect(json['schema'], {'id': 'turing-lab.batch-report', 'version': 1});
        expect(json['request']['modelRevision'], 'r1');
        expect(json['request']['sharedLimits']['maxSteps'], 10000);
        expect(csv, contains('modelId,modelRevision,strategyId'));
        expect(csv, contains('maxSteps,maxConfigurations,timeoutMicros'));
        expect(csv, contains(',10000,100000,5000000,none,'));
        expect(csv, contains('"a,""b""\n"'));
        expect(csv, contains(',accepted,'));
      },
    );

    test(
      'CSV export preserves a structured-only message without localization',
      () {
        final structuredMessage = StructuredMessage(
          namespace: 'batch.execution',
          code: 'tm-policy-reason',
          category: StructuredMessageCategory.simulation,
          severity: StructuredMessageSeverity.information,
          arguments: {
            'policy': StructuredMessageArgument.outcome(
              'finalStateOrHalting',
              role: 'tm-acceptance-policy',
            ),
            'reason': StructuredMessageArgument.outcome(
              'stepLimit',
              role: 'tm-acceptance-reason',
            ),
          },
        );
        final report = BatchExecutionReport(
          request: _request(inputs: const ['a']),
          results: [
            BatchCaseResult(
              inputCase: BatchInputCase(id: 'case-0', input: 'a'),
              outcome: BatchOutcomeCode.boundedUnknown,
              elapsed: Duration.zero,
              structuredMessage: structuredMessage,
            ),
          ],
          startedAt: DateTime.utc(2026, 8, 26),
          elapsed: Duration.zero,
        );

        final csv = BatchReportEncoder.csv(report);

        expect(csv, contains('message,structuredMessage'));
        expect(csv, contains('batch.execution'));
        expect(csv, contains('tm-policy-reason'));
        expect(csv, contains('finalStateOrHalting'));
        expect(csv, contains('stepLimit'));
        expect(csv, isNot(contains('Política')));
      },
    );
  });
}

BatchExecutionRequest _request({
  required List<String> inputs,
  int maxConcurrency = 2,
  bool stopOnFirstFailure = false,
  BatchTraceRetention traceRetention = BatchTraceRetention.none,
  BatchExecutionLimits limits = const BatchExecutionLimits(),
}) => BatchExecutionRequest(
  modelId: 'model',
  modelRevision: 'r1',
  strategyId: 'simulate',
  tokenizationMode: BatchTokenizationMode.unicodeScalar,
  cases: [
    for (var index = 0; index < inputs.length; index++)
      BatchInputCase(id: 'case-$index', input: inputs[index]),
  ],
  sharedLimits: limits,
  traceRetention: traceRetention,
  stopOnFirstFailure: stopOnFirstFailure,
  maxConcurrency: maxConcurrency,
  generation: 4,
);

final class _FakeExecutor implements BatchCaseExecutor {
  _FakeExecutor({this.revision = 'r1', this.delays = const {}, this.onExecute});

  final String revision;
  final Map<String, Duration> delays;
  final Future<BatchCaseExecution> Function(
    BatchInputCase inputCase,
    BatchCancellationToken cancellationToken,
  )?
  onExecute;
  int active = 0;
  int maximumActive = 0;
  int executions = 0;

  @override
  String get modelId => 'model';

  @override
  String get modelRevision => revision;

  @override
  Set<String> get strategyIds => const {'simulate'};

  @override
  Future<BatchCaseExecution> execute(
    BatchInputCase inputCase, {
    required String strategyId,
    required BatchTokenizationMode tokenizationMode,
    required BatchExecutionLimits limits,
    required bool retainTrace,
    required BatchCancellationToken cancellationToken,
  }) async {
    executions++;
    active++;
    if (active > maximumActive) maximumActive = active;
    try {
      final delay = delays[inputCase.id];
      if (delay != null) await Future<void>.delayed(delay);
      final callback = onExecute;
      if (callback != null) return await callback(inputCase, cancellationToken);
      return BatchCaseExecution(
        outcome: BatchOutcomeCode.accepted,
        metrics: const {'steps': 1, 'configurations': 1},
      );
    } finally {
      active--;
    }
  }
}
