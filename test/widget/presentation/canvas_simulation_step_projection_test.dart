import 'package:flutter_test/flutter_test.dart';

import 'package:turing_lab/core/models/simulation_step.dart';
import 'package:turing_lab/core/models/step_explanation.dart';
import 'package:turing_lab/presentation/widgets/canvas_simulation_playback_bar.dart';
import 'package:turing_lab/presentation/widgets/canvas_simulation_step_projection.dart';

List<CanvasWordSymbolStatus> _statuses(CanvasSimulationWord word) =>
    [for (final symbol in word) symbol.status];

void main() {
  test('projects PDA stack contents', () {
    const step = SimulationStep(
      currentState: 'q1',
      remainingInput: '',
      stackContents: 'AZ',
      usedTransition: 'a,Z→AZ',
      stepNumber: 2,
    );

    final stack = projectPdaStackStep(step);

    expect(stack.symbols, ['A', 'Z']);
    expect(stack.lastOperation, 'a,Z→AZ');
  });

  test('projects TM tape, head, blank, and highlighted cells', () {
    const step = SimulationStep(
      currentState: 'q1',
      remainingInput: '',
      tapeContents: 'X1',
      usedTransition: 'q0,1 → q1,X,R',
      stepNumber: 2,
      headPosition: 1,
      explanation: StepExplanation(
        highlights: [
          HighlightTarget(
            type: HighlightTargetType.tapeCell,
            data: {'index': 1},
          ),
        ],
      ),
    );

    final tape = projectTmTapeStep(step, blankSymbol: '_');

    expect(tape.cells, ['X', '1']);
    expect(tape.headPosition, 1);
    expect(tape.blankSymbol, '_');
    expect(tape.highlightedCellIndices, {1});
    expect(tape.lastReadSymbol, '1');
    expect(tape.lastWriteSymbol, 'X');
    expect(tape.lastOperation, 'R');
  });

  test('projects FSA/PDA input word consumption from remaining input', () {
    const steps = [
      SimulationStep(currentState: 'q0', remainingInput: 'ab', stepNumber: 0),
      SimulationStep(currentState: 'q1', remainingInput: 'b', stepNumber: 1),
      SimulationStep(currentState: 'q2', remainingInput: '', stepNumber: 2),
    ];

    final words = projectInputWordSteps(steps);

    expect(words, hasLength(3));
    expect([for (final symbol in words.first) symbol.symbol], ['a', 'b']);
    expect(_statuses(words[0]), [
      CanvasWordSymbolStatus.current,
      CanvasWordSymbolStatus.pending,
    ]);
    expect(_statuses(words[1]), [
      CanvasWordSymbolStatus.consumed,
      CanvasWordSymbolStatus.current,
    ]);
    expect(_statuses(words[2]), [
      CanvasWordSymbolStatus.consumed,
      CanvasWordSymbolStatus.consumed,
    ]);
  });

  test('projects TM input word progress from tape rewrites and head', () {
    const steps = [
      SimulationStep(
        currentState: 'q0',
        remainingInput: 'ab',
        tapeContents: 'ab',
        stepNumber: 0,
        headPosition: 0,
      ),
      SimulationStep(
        currentState: 'q1',
        remainingInput: '',
        tapeContents: 'Xb',
        stepNumber: 1,
        headPosition: 1,
      ),
      SimulationStep(
        currentState: 'q2',
        remainingInput: '',
        tapeContents: 'XY',
        stepNumber: 2,
        headPosition: 0,
      ),
    ];

    final words = projectTapeWordSteps(steps);

    expect(words, hasLength(3));
    expect([for (final symbol in words.first) symbol.symbol], ['a', 'b']);
    expect(_statuses(words[0]), [
      CanvasWordSymbolStatus.current,
      CanvasWordSymbolStatus.pending,
    ]);
    expect(_statuses(words[1]), [
      CanvasWordSymbolStatus.consumed,
      CanvasWordSymbolStatus.current,
    ]);
    expect(_statuses(words[2]), [
      CanvasWordSymbolStatus.current,
      CanvasWordSymbolStatus.consumed,
    ]);
  });
}
