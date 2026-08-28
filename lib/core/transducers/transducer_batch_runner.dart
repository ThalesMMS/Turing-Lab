import 'transducer_simulator.dart';
import 'transducer_symbols.dart';

final class TransducerBatchItem {
  const TransducerBatchItem({required this.input, required this.outcome});

  final TransducerInputWord input;
  final TransducerExecutionOutcome outcome;

  TransducerOutputWord get output => outcome.output;
}

final class TransducerBatchReport {
  TransducerBatchReport(Iterable<TransducerBatchItem> items)
      : items = List<TransducerBatchItem>.unmodifiable(items);

  final List<TransducerBatchItem> items;
}

final class TransducerBatchRunner {
  const TransducerBatchRunner(this.simulator);

  final DeterministicTransducerSimulator simulator;

  TransducerBatchReport run(
    Iterable<TransducerInputWord> inputs, {
    bool retainTraces = false,
    int maxSteps = 100000,
    int maxRetainedTraceSteps = 1000,
    TransducerCancellationToken? cancellationToken,
  }) {
    final items = <TransducerBatchItem>[];
    for (final input in inputs) {
      final outcome = simulator.run(
        input,
        options: TransducerSimulationOptions(
          retainTrace: retainTraces,
          maxSteps: maxSteps,
          maxRetainedTraceSteps: maxRetainedTraceSteps,
          cancellationToken: cancellationToken,
        ),
      );
      items.add(TransducerBatchItem(input: input, outcome: outcome));
      if (outcome is TransducerCancelled) break;
    }
    return TransducerBatchReport(items);
  }
}
