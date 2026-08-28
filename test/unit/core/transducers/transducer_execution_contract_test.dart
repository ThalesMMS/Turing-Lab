// Mutable fixture collections verify constructor snapshot behavior.
// ignore_for_file: prefer_const_constructors

import 'package:test/test.dart';
import 'package:turing_lab/core/transducers/transducers.dart';

void main() {
  group('shared deterministic simulator', () {
    test('Mealy emits on transitions and preserves stable trace IDs', () {
      final outcome = DeterministicTransducerSimulator.mealy(_mealy())
          .run(TransducerInputWord.fromValues(['a', 'a']));

      expect(outcome, isA<TransducerSuccess>());
      expect(outcome.output.values, ['x', 'x']);
      expect(outcome.trace, hasLength(2));
      expect(outcome.trace.first.sourceStateId.value, 'q0');
      expect(outcome.trace.first.targetStateId.value, 'q1');
      expect(outcome.trace.first.transitionId.value, 't0');
      expect(outcome.trace.first.consumedInput.value, 'a');
      expect(outcome.trace.first.emittedOutput.values, ['x']);
      expect(outcome.trace.first.remainingInput.values, ['a']);
      expect(outcome.trace.last.cumulativeOutput.values, ['x', 'x']);
      expect(outcome.trace.last.remainingInput.isEmpty, isTrue);
      expect(outcome.trace.last.sourceRevision.value, 11);
    });

    test('Moore emits initial and entered-state outputs', () {
      final simulator = DeterministicTransducerSimulator.moore(_moore());
      final empty = simulator.run(TransducerInputWord.empty);
      final one = simulator.run(TransducerInputWord.fromValues(['a']));

      expect(empty, isA<TransducerSuccess>());
      expect(empty.output.values, ['zero']);
      expect(empty.trace, isEmpty);
      expect(one.output.values, ['zero', 'one']);
      expect(one.trace.single.emittedOutput.values, ['one']);
    });

    test('empty transition output emits no symbol', () {
      final machine = _mealy().copyWith(
        transitions: [
          MealyTransition(
            id: TransducerTransitionId('t0'),
            from: TransducerStateId('q0'),
            to: TransducerStateId('q1'),
            input: TransducerInputSymbol('a'),
            output: TransducerOutputWord.empty,
          ),
          MealyTransition(
            id: TransducerTransitionId('t1'),
            from: TransducerStateId('q1'),
            to: TransducerStateId('q0'),
            input: TransducerInputSymbol('a'),
            output: TransducerOutputWord.empty,
          ),
        ],
      );

      final outcome = DeterministicTransducerSimulator.mealy(machine)
          .run(TransducerInputWord.fromValues(['a']));
      expect(outcome.output.symbols, isEmpty);
      expect(outcome.trace.single.emittedOutput.symbols, isEmpty);
    });

    test('distinguishes invalid machine, invalid input, and incomplete run',
        () {
      final invalidMachine = DeterministicTransducerSimulator.mealy(
        _mealy().copyWith(states: []),
      ).run(TransducerInputWord.empty);
      expect(invalidMachine, isA<TransducerInvalidMachine>());

      final invalidInput = DeterministicTransducerSimulator.mealy(_mealy())
          .run(TransducerInputWord.fromValues(['?']));
      expect(invalidInput, isA<TransducerInvalidInput>());

      final incomplete = DeterministicTransducerSimulator.mealy(
        _mealy().copyWith(transitions: []),
      ).run(TransducerInputWord.fromValues(['a']));
      expect(incomplete, isA<TransducerIncomplete>());
      expect(incomplete.processedInputCount, 0);
    });

    test('distinguishes cancellation and step bounds', () {
      final token = TransducerCancellationToken()..cancel();
      final cancelled = DeterministicTransducerSimulator.mealy(_mealy()).run(
        TransducerInputWord.fromValues(['a']),
        options: TransducerSimulationOptions(cancellationToken: token),
      );
      expect(cancelled, isA<TransducerCancelled>());

      final bounded = DeterministicTransducerSimulator.mealy(_mealy()).run(
        TransducerInputWord.fromValues(['a', 'a']),
        options: const TransducerSimulationOptions(maxSteps: 1),
      );
      expect(bounded, isA<TransducerBounded>());
      expect(bounded.processedInputCount, 1);
      expect(bounded.output.values, ['x']);

      final checkpointed = DeterministicTransducerSimulator.mealy(_mealy()).run(
        TransducerInputWord.fromValues(['a', 'a']),
        options: TransducerSimulationOptions(
          cancellationCheckpoint: (processed) => processed == 1,
        ),
      );
      expect(checkpointed, isA<TransducerCancelled>());
      expect(checkpointed.processedInputCount, 1);
    });

    test('long runs bound retained trace without truncating output', () {
      final input = TransducerInputWord.fromValues(
        List<String>.filled(5000, 'a'),
      );
      final outcome = DeterministicTransducerSimulator.mealy(_mealy()).run(
        input,
        options: const TransducerSimulationOptions(
          maxSteps: 5000,
          maxRetainedTraceSteps: 8,
        ),
      );

      expect(outcome, isA<TransducerSuccess>());
      expect(outcome.processedInputCount, 5000);
      expect(outcome.output.symbols, hasLength(5000));
      expect(outcome.trace, hasLength(8));
      expect(outcome.traceWasTruncated, isTrue);
    });

    test('remaining-input trace uses constant-size suffix views', () {
      final input = TransducerInputWord.fromValues(
        List<String>.filled(100000, 'a'),
      );
      final outcome = DeterministicTransducerSimulator.mealy(_mealy()).run(
        input,
        options: const TransducerSimulationOptions(
          maxSteps: 100000,
          maxRetainedTraceSteps: 1000,
        ),
      );

      expect(outcome, isA<TransducerSuccess>());
      expect(outcome.output.symbols, hasLength(100000));
      expect(outcome.trace, hasLength(1000));
      expect(
        outcome.trace.every(
          (step) => identical(step.remainingInput.source, input),
        ),
        isTrue,
      );
      expect(outcome.trace.first.remainingInput.offset, 1);
      expect(outcome.trace.last.remainingInput.offset, 1000);
    });

    test('raw input uses the shared tokenizer', () {
      final outcome = DeterministicTransducerSimulator.mealy(
        _mealy().copyWith(
          inputAlphabet: {TransducerInputSymbol('aa')},
          transitions: [
            MealyTransition(
              id: TransducerTransitionId('long'),
              from: TransducerStateId('q0'),
              to: TransducerStateId('q1'),
              input: TransducerInputSymbol('aa'),
              output: TransducerOutputWord([TransducerOutputSymbol('x')]),
            ),
          ],
        ),
      ).runRaw('aa');

      expect(outcome, isA<TransducerSuccess>());
      expect(outcome.input.values, ['aa']);
    });

    test('cooperative runs preserve synchronous outcome semantics', () async {
      final simulator = DeterministicTransducerSimulator.mealy(_mealy());
      final cases = <({
        TransducerInputWord input,
        TransducerSimulationOptions options,
      })>[
        (
          input: TransducerInputWord.fromValues(['a', 'a']),
          options: const TransducerSimulationOptions(),
        ),
        (
          input: TransducerInputWord.fromValues(['a', 'a']),
          options: const TransducerSimulationOptions(maxSteps: 1),
        ),
        (
          input: TransducerInputWord.fromValues(['?']),
          options: const TransducerSimulationOptions(),
        ),
        (
          input: TransducerInputWord.fromValues(['a']),
          options: TransducerSimulationOptions(
            cancellationCheckpoint: (processed) => processed == 1,
          ),
        ),
      ];

      for (final value in cases) {
        final synchronous = simulator.run(value.input, options: value.options);
        final cooperative = await simulator.runAsync(
          value.input,
          options: value.options,
          yieldEvery: 1,
        );
        expect(cooperative.runtimeType, synchronous.runtimeType);
        expect(
            cooperative.processedInputCount, synchronous.processedInputCount);
        expect(cooperative.output, synchronous.output);
        expect(
          cooperative.trace.map((step) => step.transitionId),
          synchronous.trace.map((step) => step.transitionId),
        );
      }
      final incompleteSimulator = DeterministicTransducerSimulator.mealy(
        _mealy().copyWith(transitions: const []),
      );
      final incompleteInput = TransducerInputWord.fromValues(['a']);
      expect(
        (await incompleteSimulator.runAsync(incompleteInput)).runtimeType,
        incompleteSimulator.run(incompleteInput).runtimeType,
      );
    });
  });

  group('batch runner', () {
    test('returns input/output pairs without retaining traces by default', () {
      final report = TransducerBatchRunner(
        DeterministicTransducerSimulator.mealy(_mealy()),
      ).run([
        TransducerInputWord.empty,
        TransducerInputWord.fromValues(['a']),
        TransducerInputWord.fromValues(['a', 'a']),
      ]);

      expect(report.items, hasLength(3));
      expect(report.items.map((item) => item.output.values), [
        <String>[],
        ['x'],
        ['x', 'x'],
      ]);
      expect(report.items.every((item) => item.outcome.trace.isEmpty), isTrue);
    });

    test('optionally retains traces', () {
      final report = TransducerBatchRunner(
        DeterministicTransducerSimulator.mealy(_mealy()),
      ).run(
        [
          TransducerInputWord.fromValues(['a'])
        ],
        retainTraces: true,
      );
      expect(report.items.single.outcome.trace, hasLength(1));
    });
  });
}

MealyMachine _mealy() => MealyMachine(
      id: const TransducerMachineId('mealy'),
      name: 'Mealy',
      revision: const TransducerRevision(11),
      inputAlphabet: {TransducerInputSymbol('a')},
      outputAlphabet: {TransducerOutputSymbol('x')},
      states: [
        MealyState(
          id: TransducerStateId('q0'),
          label: 'zero',
          position: TransducerPoint(0, 0),
          isInitial: true,
        ),
        MealyState(
          id: TransducerStateId('q1'),
          label: 'one',
          position: TransducerPoint(10, 0),
        ),
      ],
      transitions: [
        MealyTransition(
          id: TransducerTransitionId('t0'),
          from: TransducerStateId('q0'),
          to: TransducerStateId('q1'),
          input: TransducerInputSymbol('a'),
          output: TransducerOutputWord([TransducerOutputSymbol('x')]),
        ),
        MealyTransition(
          id: TransducerTransitionId('t1'),
          from: TransducerStateId('q1'),
          to: TransducerStateId('q0'),
          input: TransducerInputSymbol('a'),
          output: TransducerOutputWord([TransducerOutputSymbol('x')]),
        ),
      ],
    );

MooreMachine _moore() => MooreMachine(
      id: const TransducerMachineId('moore'),
      name: 'Moore',
      revision: const TransducerRevision(12),
      inputAlphabet: {TransducerInputSymbol('a')},
      outputAlphabet: {
        TransducerOutputSymbol('zero'),
        TransducerOutputSymbol('one'),
      },
      states: [
        MooreState(
          id: TransducerStateId('q0'),
          label: 'zero',
          position: TransducerPoint(0, 0),
          isInitial: true,
          output: TransducerOutputWord([TransducerOutputSymbol('zero')]),
        ),
        MooreState(
          id: TransducerStateId('q1'),
          label: 'one',
          position: TransducerPoint(10, 0),
          output: TransducerOutputWord([TransducerOutputSymbol('one')]),
        ),
      ],
      transitions: [
        MooreTransition(
          id: TransducerTransitionId('t0'),
          from: TransducerStateId('q0'),
          to: TransducerStateId('q1'),
          input: TransducerInputSymbol('a'),
        ),
        MooreTransition(
          id: TransducerTransitionId('t1'),
          from: TransducerStateId('q1'),
          to: TransducerStateId('q0'),
          input: TransducerInputSymbol('a'),
        ),
      ],
    );
