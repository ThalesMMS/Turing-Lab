//
//  batch_parallelism_benchmark_test.dart
//  Turing Lab
//
//  Compares the shared-isolate batch runner with an isolate pool for the
//  grammar executor, whose parser runs synchronously. Reports throughput
//  (wall time) and responsiveness (longest heartbeat stall on the calling
//  isolate) separately for #433, and checks that per-case outcomes are
//  identical and in input order.
//

import 'dart:async';
import 'dart:isolate';

import 'package:flutter_test/flutter_test.dart';
import 'package:turing_lab/core/batch_execution/batch_execution.dart';
import 'package:turing_lab/core/models/grammar.dart';
import 'package:turing_lab/core/models/production.dart';

/// Balanced parentheses: S → (S) | SS | ε, an ambiguous CFG that keeps the
/// Earley parser busy on long inputs.
Grammar _parentheses() => Grammar(
  id: 'parens',
  name: 'Balanced parentheses',
  terminals: const {'(', ')'},
  nonterminals: const {'S'},
  startSymbol: 'S',
  productions: {
    const Production(id: 'p0', leftSide: ['S'], rightSide: ['(', 'S', ')']),
    const Production(id: 'p1', leftSide: ['S'], rightSide: ['S', 'S']),
    const Production(id: 'p2', leftSide: ['S'], rightSide: [], isLambda: true),
  },
  type: GrammarType.contextFree,
  created: DateTime.utc(2026),
  modified: DateTime.utc(2026),
);

List<String> _words(int count) {
  return [
    for (var index = 0; index < count; index++)
      if (index.isEven)
        '(' * (10 + index % 14) + ')' * (10 + index % 14)
      else
        '(' * (10 + index % 14) + ')' * (9 + index % 14),
  ];
}

BatchExecutionRequest _request(
  Grammar grammar,
  List<String> words, {
  required int maxConcurrency,
}) {
  return BatchExecutionRequest(
    modelId: grammar.id,
    modelRevision: GrammarBatchExecutor(grammar).modelRevision,
    strategyId: 'auto',
    tokenizationMode: BatchTokenizationMode.unicodeScalar,
    cases: [
      for (var index = 0; index < words.length; index++)
        BatchInputCase(id: 'case-$index', input: words[index]),
    ],
    maxConcurrency: maxConcurrency,
  );
}

class _Run {
  const _Run(this.label, this.wall, this.stall, this.outcomes);
  final String label;
  final Duration wall;
  final Duration stall;
  final List<BatchOutcomeCode> outcomes;

  @override
  String toString() =>
      '$label: wall=${wall.inMilliseconds}ms '
      'longestStall=${stall.inMilliseconds}ms '
      'accepted=${outcomes.where((o) => o == BatchOutcomeCode.accepted).length}/'
      '${outcomes.length}';
}

Future<_Run> _measure(
  String label,
  Future<List<BatchOutcomeCode>> Function() body,
) async {
  var last = DateTime.now();
  var longest = Duration.zero;
  final heartbeat = Timer.periodic(const Duration(milliseconds: 1), (_) {
    final now = DateTime.now();
    final gap = now.difference(last);
    if (gap > longest) longest = gap;
    last = now;
  });
  final stopwatch = Stopwatch()..start();
  final List<BatchOutcomeCode> outcomes;
  try {
    outcomes = await body();
  } finally {
    stopwatch.stop();
    heartbeat.cancel();
  }
  final trailing = DateTime.now().difference(last);
  if (trailing > longest) longest = trailing;
  return _Run(label, stopwatch.elapsed, longest, outcomes);
}

/// Runs the same executor in [workers] isolates, each taking a contiguous
/// slice of the cases, and merges the reports back in input order.
Future<List<BatchOutcomeCode>> _isolatePool(
  Grammar grammar,
  List<String> words,
  int workers,
) async {
  final slice = (words.length / workers).ceil();
  final futures = <Future<List<BatchOutcomeCode>>>[];
  for (var worker = 0; worker < workers; worker++) {
    final start = worker * slice;
    if (start >= words.length) break;
    final chunk = words.sublist(start, (start + slice).clamp(0, words.length));
    futures.add(
      Isolate.run(() async {
        final report = await const BatchExecutionRunner()
            .start(
              _request(grammar, chunk, maxConcurrency: 1),
              GrammarBatchExecutor(grammar),
            )
            .report;
        return report.results.map((r) => r.outcome).toList();
      }),
    );
  }
  final chunks = await Future.wait(futures);
  return [for (final chunk in chunks) ...chunk];
}

void main() {
  test('500 grammar cases: shared isolate versus isolate pool', () async {
    final grammar = _parentheses();
    final words = _words(500);
    final report = StringBuffer(
      '\n#433 batch parallelism benchmark (500 words, auto strategy)\n',
    );

    Future<List<BatchOutcomeCode>> shared(int concurrency) async {
      final result = await const BatchExecutionRunner()
          .start(
            _request(grammar, words, maxConcurrency: concurrency),
            GrammarBatchExecutor(grammar),
          )
          .report;
      return result.results.map((r) => r.outcome).toList();
    }

    final runs = <_Run>[
      await _measure('shared isolate, concurrency 1', () => shared(1)),
      await _measure('shared isolate, concurrency 4', () => shared(4)),
      await _measure(
        'isolate pool, 2 workers',
        () => _isolatePool(grammar, words, 2),
      ),
      await _measure(
        'isolate pool, 4 workers',
        () => _isolatePool(grammar, words, 4),
      ),
    ];
    for (final run in runs) {
      report.writeln(run);
    }
    // ignore: avoid_print
    print(report);

    final reference = runs.first.outcomes;
    expect(reference.length, words.length);
    expect(reference.where((o) => o == BatchOutcomeCode.accepted).length, 250);
    for (final run in runs.skip(1)) {
      expect(run.outcomes, reference, reason: run.label);
    }
  }, timeout: const Timeout(Duration(minutes: 5)));
}
