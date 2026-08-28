import '../../core/models/simulation_step.dart';
import '../../core/models/step_explanation.dart';
import '../../core/transducers/transducers.dart';
import 'canvas_simulation_playback_bar.dart';
import 'pda/stack_drawer.dart';
import 'tm/tape_drawer.dart';

/// Annotates the input word for every step of an FSA/PDA simulation, using
/// the remaining input tracked by the simulators: the consumed prefix is
/// struck out and the next symbol to be read is highlighted.
List<CanvasSimulationWord> projectInputWordSteps(List<SimulationStep> steps) {
  if (steps.isEmpty) {
    return const <CanvasSimulationWord>[];
  }
  final original = steps.first.remainingInput;
  return [
    for (final step in steps) _wordFromRemaining(original, step.remainingInput),
  ];
}

CanvasSimulationWord _wordFromRemaining(String original, String remaining) {
  final consumed = original.endsWith(remaining)
      ? original.length - remaining.length
      : (original.length - remaining.length).clamp(0, original.length);
  return [
    for (var i = 0; i < original.length; i++)
      CanvasSimulationWordSymbol(
        original[i],
        i < consumed
            ? CanvasWordSymbolStatus.consumed
            : i == consumed
            ? CanvasWordSymbolStatus.current
            : CanvasWordSymbolStatus.pending,
      ),
  ];
}

/// Annotates the input word for every step of a TM simulation. Turing
/// machines rewrite the tape instead of consuming input, so a position
/// counts as processed once its tape cell no longer matches the original
/// input, and the cell under the head is highlighted.
List<CanvasSimulationWord> projectTapeWordSteps(List<SimulationStep> steps) {
  if (steps.isEmpty) {
    return const <CanvasSimulationWord>[];
  }
  final original = steps.first.tapeContents;
  return [
    for (final step in steps)
      [
        for (var i = 0; i < original.length; i++)
          CanvasSimulationWordSymbol(
            original[i],
            i == step.headPosition
                ? CanvasWordSymbolStatus.current
                : i < step.tapeContents.length &&
                      step.tapeContents[i] != original[i]
                ? CanvasWordSymbolStatus.consumed
                : CanvasWordSymbolStatus.pending,
          ),
      ],
  ];
}

/// Annotates the tokenized input word for every step of a transducer
/// execution trace: each step consumes exactly one token, so tokens before
/// the step are struck out and the token consumed by the step is
/// highlighted.
List<CanvasSimulationWord> projectTransducerInputSteps(
  List<TransducerExecutionStep> trace,
) {
  if (trace.isEmpty) {
    return const <CanvasSimulationWord>[];
  }
  final tokens = trace.first.remainingInput.source.values;
  return [
    for (final step in trace)
      [
        for (var i = 0; i < tokens.length; i++)
          CanvasSimulationWordSymbol(
            tokens[i],
            i < step.index
                ? CanvasWordSymbolStatus.consumed
                : i == step.index
                ? CanvasWordSymbolStatus.current
                : CanvasWordSymbolStatus.pending,
          ),
      ],
  ];
}

StackState projectPdaStackStep(SimulationStep step) {
  return StackState(
    symbols: step.effectiveStackTokens,
    lastOperation: step.usedTransition ?? 'step ${step.stepNumber}',
    operationType: _pdaStackOperationType(step.usedTransition),
  );
}

TapeState projectTmTapeStep(
  SimulationStep step, {
  required String blankSymbol,
}) {
  final highlightedCells = <int>{
    if (step.explanation != null)
      for (final highlight in step.explanation!.highlights)
        if (highlight.type == HighlightTargetType.tapeCell)
          _integerValue(highlight.data['index']) ?? -1,
  }..removeWhere((index) => index < 0);

  String? lastRead;
  String? lastWrite;
  String? lastOperation;
  if (step.usedTransition case final transition?) {
    final parts = transition.split(' → ');
    if (parts.length == 2) {
      final before = parts[0].split(',');
      final after = parts[1].split(',');
      if (before.length >= 2) lastRead = before[1];
      if (after.length >= 2) lastWrite = after[1];
      if (after.length >= 3) lastOperation = after[2];
    }
  }

  return TapeState(
    cells: step.tapeContents.isEmpty ? [] : step.tapeContents.split(''),
    headPosition: step.headPosition ?? 0,
    blankSymbol: blankSymbol,
    lastOperation: lastOperation,
    lastReadSymbol: lastRead,
    lastWriteSymbol: lastWrite,
    highlightedCellIndices: highlightedCells,
  );
}

StackOperationType _pdaStackOperationType(String? transitionLabel) {
  if (transitionLabel == null || transitionLabel.isEmpty) {
    return StackOperationType.none;
  }

  final parts = transitionLabel.split(',');
  if (parts.length < 2) return StackOperationType.none;
  final stackParts = parts[1].split('→');
  if (stackParts.length < 2) return StackOperationType.none;

  final pop = stackParts[0].trim();
  final push = stackParts[1].trim();
  final isPopEpsilon = pop == 'ε' || pop.isEmpty;
  final isPushEpsilon = push == 'ε' || push.isEmpty;

  if (!isPopEpsilon && !isPushEpsilon) return StackOperationType.replace;
  if (!isPopEpsilon) return StackOperationType.pop;
  if (!isPushEpsilon) return StackOperationType.push;
  return StackOperationType.none;
}

int? _integerValue(Object? value) {
  if (value is int) return value;
  if (value is double && value.isFinite && value == value.truncateToDouble()) {
    return value.toInt();
  }
  return null;
}
