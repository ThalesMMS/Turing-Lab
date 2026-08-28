import 'dart:math' as math;

import '../models/simulation_step.dart';
import '../models/state.dart';
import '../models/step_explanation.dart';
import '../models/tm.dart';
import '../models/tm_execution_analysis.dart';
import '../models/tm_transition.dart';
import 'tm_messages.dart';

/// Shared atomic transition primitives for bounded k-tape TM analyses.
///
/// Search policies (deterministic execution, BFS, limits, and witnesses) live
/// in their respective analyzers, while configuration identity and transition
/// application stay identical here.
class TMExecutionKernel {
  const TMExecutionKernel._();

  static Map<int, String> initialTape(String input, String blankSymbol) {
    return initialTapeTokens(input.split(''), blankSymbol);
  }

  static Map<int, String> initialTapeTokens(
    List<String> inputTokens,
    String blankSymbol,
  ) {
    return {
      for (var index = 0; index < inputTokens.length; index++)
        if (inputTokens[index] != blankSymbol) index: inputTokens[index],
    };
  }

  /// Tape 0 receives the input. Every additional tape starts blank.
  static List<Map<int, String>> initialTapes(
    String input,
    String blankSymbol,
    int tapeCount, {
    List<Map<int, String>>? explicitTapes,
  }) {
    if (tapeCount < 1) throw ArgumentError.value(tapeCount, 'tapeCount');
    if (explicitTapes != null && explicitTapes.length != tapeCount) {
      throw ArgumentError('Explicit initial tapes must match tapeCount.');
    }
    return List<Map<int, String>>.generate(
      tapeCount,
      (index) => explicitTapes == null
          ? (index == 0 ? initialTape(input, blankSymbol) : <int, String>{})
          : Map<int, String>.from(explicitTapes[index]),
      growable: false,
    );
  }

  /// Tape 0 receives the tokenized input. Every additional tape starts blank.
  static List<Map<int, String>> initialTapesTokens(
    List<String> inputTokens,
    String blankSymbol,
    int tapeCount,
  ) {
    if (tapeCount < 1) throw ArgumentError.value(tapeCount, 'tapeCount');
    return List<Map<int, String>>.generate(
      tapeCount,
      (index) => index == 0
          ? initialTapeTokens(inputTokens, blankSymbol)
          : <int, String>{},
      growable: false,
    );
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

  static TMConfigurationSnapshot snapshotMulti({
    required String stateId,
    required List<int> headPositions,
    required List<Map<int, String>> tapes,
    required String blankSymbol,
  }) => TMConfigurationSnapshot.canonicalMulti(
    stateId: stateId,
    headPositions: headPositions,
    tapes: tapes,
    blankSymbol: blankSymbol,
  );

  static List<TMTransition> transitionsFor(TM tm, State state, String symbol) {
    return tm.getTransitionsFromStateOnSymbol(state, symbol).toList()
      ..sort((a, b) => a.id.compareTo(b.id));
  }

  static List<TMTransition> transitionsForVector(
    TM tm,
    State state,
    List<String> symbols,
  ) {
    return tm.getTransitionsFromStateOnSymbols(state, symbols).toList()
      ..sort((a, b) => a.id.compareTo(b.id));
  }

  static List<String> readVector(
    List<Map<int, String>> tapes,
    List<int> heads,
    String blankSymbol,
  ) {
    if (tapes.length != heads.length) {
      throw ArgumentError('Tape and head vectors must have equal lengths.');
    }
    return List<String>.generate(
      tapes.length,
      (index) => tapes[index][heads[index]] ?? blankSymbol,
      growable: false,
    );
  }

  /// Copies every tape before applying all writes and moves as one operation.
  static ({List<Map<int, String>> tapes, List<int> heads}) applyTransition({
    required List<Map<int, String>> sourceTapes,
    required List<int> sourceHeads,
    required TMTransition transition,
    required String blankSymbol,
  }) {
    if (sourceTapes.length != sourceHeads.length) {
      throw ArgumentError(
        'Transition vectors must match the machine tape count.',
      );
    }
    final operations = transition.operationsForTapeCount(
      sourceTapes.length,
      blankSymbol,
    );
    final tapes = sourceTapes
        .map((tape) => Map<int, String>.from(tape))
        .toList(growable: false);
    final heads = List<int>.of(sourceHeads, growable: false);
    for (var tape = 0; tape < tapes.length; tape++) {
      write(
        tapes[tape],
        heads[tape],
        operations.writeSymbols[tape],
        blankSymbol,
      );
    }
    for (var tape = 0; tape < heads.length; tape++) {
      heads[tape] = moveHead(heads[tape], operations.directions[tape]);
    }
    return (tapes: tapes, heads: heads);
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
    final tapeText = sortedCells
        .map((entry) => '${entry.key}:${entry.value}')
        .join(' ');
    final headBefore = switch (transition.direction) {
      TapeDirection.left => head + 1,
      TapeDirection.right => head - 1,
      TapeDirection.stay => head,
    };
    // The existing trace-message schema models positions as non-negative
    // indexes. Keep sparse negative tape coordinates in the legacy formal
    // transition while retaining structured explanations everywhere the
    // schema can represent the position.
    final explanation = headBefore < 0 || head < 0
        ? null
        : _buildTmStepExplanation(
            fromStateId: fromState.id,
            toStateId: transition.toState.id,
            transitionId: transition.id,
            readSymbol: readSymbol,
            writeSymbol: transition.writeSymbol,
            moveDirection: transition.direction,
            headBefore: headBefore,
            headAfter: head,
          );
    return SimulationStep.tm(
      currentState: transition.toState.id,
      remainingInput: '',
      tapeContents: tapeText,
      usedTransition:
          '${fromState.id},$readSymbol → '
          '${transition.toState.id},${transition.writeSymbol},'
          '${transition.direction.symbol}',
      stepNumber: step,
      headPosition: head,
      consumedInput: readSymbol,
      explanation: explanation,
    );
  }

  static StepExplanation _buildTmStepExplanation({
    required String fromStateId,
    required String toStateId,
    required String transitionId,
    required String readSymbol,
    required String writeSymbol,
    required TapeDirection moveDirection,
    required int headBefore,
    required int headAfter,
  }) {
    final highlights = <HighlightTarget>[
      HighlightTarget(type: HighlightTargetType.state, id: toStateId),
      HighlightTarget(type: HighlightTargetType.transition, id: transitionId),
      HighlightTarget(
        type: HighlightTargetType.tapeCell,
        data: {'index': headBefore, 'read': readSymbol, 'write': writeSymbol},
      ),
    ];
    if (headAfter != headBefore) {
      highlights.add(
        HighlightTarget(
          type: HighlightTargetType.tapeCell,
          data: {'index': headAfter},
        ),
      );
    }

    return StepExplanation(
      titleMessage: TmSimulationMessages.transitionTitle(),
      bulletMessages: [
        TmSimulationMessages.readSymbol(
          symbol: readSymbol,
          position: headBefore,
          state: fromStateId,
        ),
        TmSimulationMessages.appliedRule(
          fromState: fromStateId,
          readSymbol: readSymbol,
          toState: toStateId,
          writeSymbol: writeSymbol,
          direction: moveDirection.symbol,
        ),
        TmSimulationMessages.wroteSymbol(
          symbol: writeSymbol,
          position: headBefore,
        ),
        TmSimulationMessages.movedHead(
          direction: moveDirection.symbol,
          position: headAfter,
        ),
      ],
      categories: const [ExplanationCategory.tapeOperation],
      highlights: highlights,
      suggestedFixes: const [],
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
  }) : _initialTape = Map<int, String>.from(initialTape),
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
  }) : _initialTape = initialTape,
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
    transitionExecutionCounts: Map<String, int>.from(
      _transitionExecutionCounts,
    ),
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
    final changedPositions =
        <int>{..._initialTape.keys, ..._finalTape.keys}.where((position) {
          return (_initialTape[position] ?? blankSymbol) !=
              (_finalTape[position] ?? blankSymbol);
        }).toList()..sort();
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
