import 'package:flutter_test/flutter_test.dart';
import 'package:turing_lab/core/transducers/transducers.dart';
import 'package:turing_lab/presentation/transducers/transducer_editor_state.dart';

void main() {
  test('an execution without trace clears the previous active trace index', () {
    final notifier = TransducerEditorNotifier<MealyMachine>(_machine());
    notifier.setExecution(
      TransducerSuccess(
        input: TransducerInputWord.fromValues(const ['a']),
        output: TransducerOutputWord.fromValues(const ['x']),
        trace: [_step()],
        processedInputCount: 1,
      ),
    );
    expect(notifier.state.activeTraceIndex, 0);

    notifier.setExecution(
      TransducerInvalidInput(
        input: TransducerInputWord.fromValues(const ['?']),
        invalidSymbol: const TransducerInputSymbol('?'),
      ),
    );

    expect(notifier.state.activeTraceIndex, isNull);
    expect(notifier.state.lastExecution, isA<TransducerInvalidInput>());
  });
}

MealyMachine _machine() => MealyMachine(
      id: const TransducerMachineId('machine'),
      name: 'Machine',
      revision: const TransducerRevision(1),
      inputAlphabet: const [TransducerInputSymbol('a')],
      outputAlphabet: const [TransducerOutputSymbol('x')],
      states: const [
        MealyState(
          id: TransducerStateId('q0'),
          label: 'q0',
          position: TransducerPoint(0, 0),
          isInitial: true,
        ),
      ],
      transitions: const [],
    );

TransducerExecutionStep _step() => TransducerExecutionStep(
      index: 0,
      sourceStateId: const TransducerStateId('q0'),
      targetStateId: const TransducerStateId('q0'),
      transitionId: const TransducerTransitionId('t0'),
      consumedInput: const TransducerInputSymbol('a'),
      emittedOutput: TransducerOutputWord.fromValues(const ['x']),
      cumulativeOutput: TransducerOutputWord.fromValues(const ['x']),
      remainingInput: TransducerInputSuffix(TransducerInputWord.empty, 0),
      sourceRevision: const TransducerRevision(1),
    );
