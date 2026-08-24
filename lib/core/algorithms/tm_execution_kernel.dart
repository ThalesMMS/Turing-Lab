import 'dart:math' as math;

import '../models/simulation_step.dart';
import '../models/state.dart';
import '../models/tm.dart';
import '../models/tm_execution_analysis.dart';
import '../models/tm_transition.dart';

/// Shared single-tape transition primitives for bounded TM analyses.
///
/// Search policies (deterministic execution, BFS, limits, and witnesses) live
/// in their respective analyzers, while configuration identity and transition
/// application stay identical here.
class TMExecutionKernel {
  const TMExecutionKernel._();

  static Map<int, String> initialTape(String input, String blankSymbol) {
    return {
      for (var index = 0; index < input.length; index++)
        if (input[index] != blankSymbol) index: input[index],
    };
  }

  static TMConfigurationSnapshot snapshot({
    required String stateId,
    required int headPosition,
    required Map<int, String> tape,
    required String blankSymbol,
  }) {
    return TMConfigurationSnapshot.canonical(
      stateId: stateId,
      headPosition: headPosition,
      tape: tape,
      blankSymbol: blankSymbol,
    );
  }

  static List<TMTransition> transitionsFor(
    TM tm,
    State state,
    String symbol,
  ) {
    return tm.getTransitionsFromStateOnSymbol(state, symbol).toList()
      ..sort((a, b) => a.id.compareTo(b.id));
  }

  static Map<int, String> applyTransitionTape(
    Map<int, String> source,
    int head,
    TMTransition transition,
    String blankSymbol,
  ) {
    final tape = Map<int, String>.from(source);
    write(tape, head, transition.writeSymbol, blankSymbol);
    return tape;
  }

  static void write(
    Map<int, String> tape,
    int head,
    String symbol,
    String blankSymbol,
  ) {
    if (symbol == blankSymbol) {
      tape.remove(head);
    } else {
      tape[head] = symbol;
    }
  }

  static int moveHead(int head, TapeDirection direction) => switch (direction) {
        TapeDirection.left => head - 1,
        TapeDirection.right => head + 1,
        TapeDirection.stay => head,
      };

  static SimulationStep simulationStep({
    required State fromState,
    required TMTransition transition,
    required String readSymbol,
    required Map<int, String> tape,
    required int step,
    required int head,
  }) {
    final sortedCells = tape.entries.toList()
      ..sort((a, b) => a.key.compareTo(b.key));
    final tapeText =
        sortedCells.map((entry) => '${entry.key}:${entry.value}').join(' ');
    return SimulationStep.tm(
      currentState: transition.toState.id,
      remainingInput: '',
      tapeContents: tapeText,
      usedTransition: '${fromState.id},$readSymbol → '
          '${transition.toState.id},${transition.writeSymbol},'
          '${transition.direction.symbol}',
      stepNumber: step,
      headPosition: head,
      consumedInput: readSymbol,
    );
  }
}

/// Mutable, streaming accumulator for metrics from one concrete TM branch.
///
/// It retains only tape-sized maps and counters. Trace snapshots remain an
/// independent opt-in concern of the execution analyzer.
class TMTraceMetricsAccumulator {
  TMTraceMetricsAccumulator({
    required this.blankSymbol,
    required Map<int, String> initialTape,
  })  : _initialTape = Map<int, String>.from(initialTape),
        _finalTape = Map<int, String>.from(initialTape) {
    _visitedCells.add(0);
    _touch(0, 0);
    _maximumSimultaneousNonBlankCells = initialTape.length;
  }

  TMTraceMetricsAccumulator._({
    required this.blankSymbol,
    required Map<int, String> initialTape,
    required Map<int, String> finalTape,
    required Map<String, int> readCounts,
    required Map<String, int> writeCountsByOldSymbol,
    required Map<String, int> writeCountsByNewSymbol,
    required int changedWrites,
    required Map<String, int> movementCounts,
    required int headReversals,
    required int minimumHeadPosition,
    required int maximumHeadPosition,
    required Set<int> visitedCells,
    required int maximumSimultaneousNonBlankCells,
    required Map<String, int> transitionExecutionCounts,
    required Map<int, List<int>> cellTouchRanges,
    required TapeDirection? previousMovement,
  })  : _initialTape = initialTape,
        _finalTape = finalTape,
        _readCounts = readCounts,
        _writeCountsByOldSymbol = writeCountsByOldSymbol,
        _writeCountsByNewSymbol = writeCountsByNewSymbol,
        _changedWrites = changedWrites,
        _movementCounts = movementCounts,
        _headReversals = headReversals,
        _minimumHeadPosition = minimumHeadPosition,
        _maximumHeadPosition = maximumHeadPosition,
        _visitedCells = visitedCells,
        _maximumSimultaneousNonBlankCells = maximumSimultaneousNonBlankCells,
        _transitionExecutionCounts = transitionExecutionCounts,
        _cellTouchRanges = cellTouchRanges,
        _previousMovement = previousMovement;

  final String blankSymbol;
  final Map<int, String> _initialTape;
  final Map<int, String> _finalTape;
  Map<String, int> _readCounts = {};
  Map<String, int> _writeCountsByOldSymbol = {};
  Map<String, int> _writeCountsByNewSymbol = {};
  int _changedWrites = 0;
  Map<String, int> _movementCounts = {};
  int _headReversals = 0;
  int _minimumHeadPosition = 0;
  int _maximumHeadPosition = 0;
  Set<int> _visitedCells = {};
  int _maximumSimultaneousNonBlankCells = 0;
  Map<String, int> _transitionExecutionCounts = {};
  Map<int, List<int>> _cellTouchRanges = {};
  TapeDirection? _previousMovement;

  int get visitedSpan => _maximumHeadPosition - _minimumHeadPosition + 1;

  int get maximumSimultaneousNonBlankCells => _maximumSimultaneousNonBlankCells;

  TMTraceMetricsAccumulator copy() => TMTraceMetricsAccumulator._(
        blankSymbol: blankSymbol,
        initialTape: Map<int, String>.from(_initialTape),
        finalTape: Map<int, String>.from(_finalTape),
        readCounts: Map<String, int>.from(_readCounts),
        writeCountsByOldSymbol: Map<String, int>.from(_writeCountsByOldSymbol),
        writeCountsByNewSymbol: Map<String, int>.from(_writeCountsByNewSymbol),
        changedWrites: _changedWrites,
        movementCounts: Map<String, int>.from(_movementCounts),
        headReversals: _headReversals,
        minimumHeadPosition: _minimumHeadPosition,
        maximumHeadPosition: _maximumHeadPosition,
        visitedCells: Set<int>.from(_visitedCells),
        maximumSimultaneousNonBlankCells: _maximumSimultaneousNonBlankCells,
        transitionExecutionCounts:
            Map<String, int>.from(_transitionExecutionCounts),
        cellTouchRanges: {
          for (final entry in _cellTouchRanges.entries)
            entry.key: List<int>.from(entry.value),
        },
        previousMovement: _previousMovement,
      );

  void record({
    required TMTransition transition,
    required String oldSymbol,
    required int headBefore,
    required int headAfter,
    required int step,
  }) {
    _increment(_readCounts, oldSymbol);
    _increment(_writeCountsByOldSymbol, oldSymbol);
    _increment(_writeCountsByNewSymbol, transition.writeSymbol);
    if (oldSymbol != transition.writeSymbol) _changedWrites++;

    final movement = switch (transition.direction) {
      TapeDirection.left => 'left',
      TapeDirection.right => 'right',
      TapeDirection.stay => 'stay',
    };
    _increment(_movementCounts, movement);
    final previous = _previousMovement;
    if (transition.direction != TapeDirection.stay) {
      if ((previous == TapeDirection.left &&
              transition.direction == TapeDirection.right) ||
          (previous == TapeDirection.right &&
              transition.direction == TapeDirection.left)) {
        _headReversals++;
      }
      _previousMovement = transition.direction;
    }

    _increment(_transitionExecutionCounts, transition.id);
    _touch(headBefore, step);
    _touch(headAfter, step);
    _minimumHeadPosition = math.min(_minimumHeadPosition, headAfter);
    _maximumHeadPosition = math.max(_maximumHeadPosition, headAfter);
    if (transition.writeSymbol == blankSymbol) {
      _finalTape.remove(headBefore);
    } else {
      _finalTape[headBefore] = transition.writeSymbol;
    }
    _maximumSimultaneousNonBlankCells = math.max(
      _maximumSimultaneousNonBlankCells,
      _finalTape.length,
    );
  }

  TMTraceMetrics finish({
    required TM tm,
    required TMExecutionBranchSelection branchSelection,
    required int retainedTraceSnapshots,
  }) {
    final changedPositions = <int>{
      ..._initialTape.keys,
      ..._finalTape.keys,
    }.where((position) {
      return (_initialTape[position] ?? blankSymbol) !=
          (_finalTape[position] ?? blankSymbol);
    }).toList()
      ..sort();
    final diff = <int, TMTapeCellChange>{
      for (final position in changedPositions)
        position: TMTapeCellChange(
          position: position,
          initialSymbol: _initialTape[position] ?? blankSymbol,
          finalSymbol: _finalTape[position] ?? blankSymbol,
        ),
    };
    final executed = _transitionExecutionCounts.keys.toSet();
    return TMTraceMetrics(
      branchSelection: branchSelection,
      readCounts: _readCounts,
      writeCountsByOldSymbol: _writeCountsByOldSymbol,
      writeCountsByNewSymbol: _writeCountsByNewSymbol,
      changedWrites: _changedWrites,
      movementCounts: _movementCounts,
      headReversals: _headReversals,
      minimumHeadPosition: _minimumHeadPosition,
      maximumHeadPosition: _maximumHeadPosition,
      visitedCells: _visitedCells,
      maximumSimultaneousNonBlankCells: _maximumSimultaneousNonBlankCells,
      transitionExecutionCounts: _transitionExecutionCounts,
      cellTouchRanges: {
        for (final entry in _cellTouchRanges.entries)
          entry.key: TMTapeCellTouchRange(
            firstStep: entry.value.first,
            lastStep: entry.value.last,
          ),
      },
      tapeDiff: diff,
      definedButNotExecutedTransitionIds:
          tm.tmTransitions.map((transition) => transition.id).toSet()
            ..removeAll(executed),
      retainedTraceSnapshots: retainedTraceSnapshots,
    );
  }

  void _touch(int position, int step) {
    _visitedCells.add(position);
    final range = _cellTouchRanges[position];
    if (range == null) {
      _cellTouchRanges[position] = [step, step];
    } else {
      range[1] = step;
    }
  }

  static void _increment(Map<String, int> counts, String key) {
    counts.update(key, (count) => count + 1, ifAbsent: () => 1);
  }
}
