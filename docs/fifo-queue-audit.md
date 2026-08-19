# FIFO queue audit

Production breadth-first searches, graph worklists, and simulation configuration
queues use `Queue.removeFirst()`. Run the repository guard with:

```sh
./tool/check_fifo_queues.sh
```

The remaining `removeAt(0)` calls are intentional list operations:

- `regex_analyzer_helpers.dart` and `regex_to_nfa_converter_parser.dart`
  consume token streams while retaining indexed parser lookahead.
- `grammar_parser.dart` consumes a bounded mutable input sequence.
- `cfg/cfg_toolkit.dart` removes the first symbol while rewriting a production
  right-hand side; it is not a queue traversal.

## Benchmark

`dart run benchmark/fifo_queue_benchmark.dart` compares the former list-backed
dequeue with the current queue behavior for an NTM-like branching workload and
a wide graph traversal. The benchmark is intentionally standalone so it can be
run without Flutter startup overhead. Record machine-specific results when
changing queue behavior; timings are not used as a test threshold.

Reference run on 2026-07-12 (Apple Silicon, Dart 3.12.2):

| Workload | `List.removeAt(0)` | `Queue.removeFirst()` |
| --- | ---: | ---: |
| 50,000 branching configurations | 1,935 ms | 1 ms |
| 50,000-node wide traversal | 1,921 ms | 1 ms |
