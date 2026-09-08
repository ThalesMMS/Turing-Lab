//
//  tm_multi_tape_reducer.dart
//  Turing Lab
//
//  Reduces a k-tape Turing machine without building blocks to an equivalent
//  single-tape machine over composite cells. Every composite cell stores the
//  k track symbols plus one head marker per track, and one step of the
//  source machine becomes a rightward read sweep followed by a leftward
//  apply sweep. The construction, its invariants and its budgets are
//  documented in docs/TM_MULTI_TAPE_REDUCTION.md.
//

import 'dart:math' as math;

import 'package:vector_math/vector_math_64.dart';

import '../../messages/structured_message.dart';
import '../../models/state.dart';
import '../../models/tm.dart';
import '../../models/tm_acceptance.dart';
import '../../models/tm_execution_analysis.dart';
import '../../models/tm_transition.dart';
import 'tm_execution_analyzer.dart';
import 'tm_multi_tape_execution_analyzer.dart';
import 'tm_multi_tape_reduction_messages.dart';

enum TMMultiTapeReductionOutcome {
  completed,
  notApplicable,
  invalidMachine,
  unsupportedMachine,
  budgetExceeded,
}

enum TMMultiTapeReductionSeverity { warning, error }

enum TMMultiTapeReductionDiagnosticCode {
  alreadySingleTape,
  invalidMachine,
  missingInitialState,
  buildingBlocksUnsupported,
  acceptancePolicyUnsupported,
  blankInInputAlphabet,
  tapeSymbolBudget,
  stateBudget,
  transitionBudget,
}

/// Phases of the reduced machine. One source step is
/// `read` (rightward) followed by `apply` (leftward), with `excursion` and
/// `resume` handling a head that moves right on the leftward sweep.
enum TMMultiTapePhase {
  initializeFirst,
  initializeRest,
  rewind,
  read,
  apply,
  excursion,
  resume,
}

/// Expansion budgets. The reduced alphabet has `|Γ|^k · 2^k` composite cells
/// and every non-initial state reads all of them, so the limits bound the
/// product rather than the source machine size.
final class TMMultiTapeReductionLimits {
  const TMMultiTapeReductionLimits({
    this.maxTapeSymbols = 2048,
    this.maxStates = 4000,
    this.maxTransitions = 80000,
  });

  final int maxTapeSymbols;
  final int maxStates;
  final int maxTransitions;

  Map<String, Object?> toJson() => {
    'maxTapeSymbols': maxTapeSymbols,
    'maxStates': maxStates,
    'maxTransitions': maxTransitions,
  };
}

/// One composite cell: the symbol of every track and which heads sit on it.
final class TMMultiTapeCell {
  TMMultiTapeCell({
    required Iterable<String> symbols,
    required Iterable<bool> heads,
  }) : symbols = List<String>.unmodifiable(symbols),
       heads = List<bool>.unmodifiable(heads) {
    if (this.symbols.length != this.heads.length || this.symbols.isEmpty) {
      throw ArgumentError(
        'A composite cell needs one symbol and head per tape.',
      );
    }
  }

  final List<String> symbols;
  final List<bool> heads;

  int get tapeCount => symbols.length;
  bool get hasHeads => heads.any((head) => head);
  bool get hasAllHeads => heads.every((head) => head);

  /// Stable textual encoding used as the reduced tape symbol.
  String get symbol => encode(symbols, heads);

  /// Track symbols may themselves contain the separators, so they are
  /// escaped: distinct symbol vectors always encode to distinct strings.
  static String encode(Iterable<String> symbols, Iterable<bool> heads) =>
      '⟨${symbols.map(escapeSymbol).join(',')}'
      '|${heads.map((head) => head ? '1' : '0').join()}⟩';

  static String escapeSymbol(String symbol) => symbol
      .replaceAll(r'\', r'\\')
      .replaceAll(',', r'\,')
      .replaceAll('|', r'\|')
      .replaceAll('⟩', r'\⟩');

  TMMultiTapeCell copyWith({List<String>? symbols, List<bool>? heads}) =>
      TMMultiTapeCell(
        symbols: symbols ?? this.symbols,
        heads: heads ?? this.heads,
      );
}

final class TMMultiTapeReductionDiagnostic {
  const TMMultiTapeReductionDiagnostic({
    required this.code,
    required this.severity,
    this.detail,
    this.count,
    this.limit,
    this.structuredMessage,
  });

  final TMMultiTapeReductionDiagnosticCode code;
  final TMMultiTapeReductionSeverity severity;
  final String? detail;
  final int? count;
  final int? limit;
  final StructuredMessage? structuredMessage;

  Map<String, Object?> toJson() => {
    'code': code.name,
    'severity': severity.name,
    if (detail != null) 'detail': detail,
    if (count != null) 'count': count,
    if (limit != null) 'limit': limit,
    if (structuredMessage != null)
      'structuredMessage': structuredMessage!.toJson(),
  };
}

/// Where a reduced state comes from.
final class TMMultiTapeStateProvenance {
  TMMultiTapeStateProvenance({
    required this.stateId,
    required this.phase,
    this.sourceStateId,
    this.sourceTransitionId,
    Iterable<String?> reads = const [],
    Iterable<int> doneTapes = const [],
    Iterable<int> pendingLeftTapes = const [],
    Iterable<int> pendingRightTapes = const [],
  }) : reads = List<String?>.unmodifiable(reads),
       doneTapes = List<int>.unmodifiable(doneTapes),
       pendingLeftTapes = List<int>.unmodifiable(pendingLeftTapes),
       pendingRightTapes = List<int>.unmodifiable(pendingRightTapes);

  final String stateId;
  final TMMultiTapePhase phase;

  /// Source state simulated by this reduced state, when the phase carries one.
  final String? sourceStateId;

  /// Source transition being applied, for apply/excursion/resume states.
  final String? sourceTransitionId;
  final List<String?> reads;
  final List<int> doneTapes;
  final List<int> pendingLeftTapes;
  final List<int> pendingRightTapes;

  Map<String, Object?> toJson() => {
    'stateId': stateId,
    'phase': phase.name,
    if (sourceStateId != null) 'sourceStateId': sourceStateId,
    if (sourceTransitionId != null) 'sourceTransitionId': sourceTransitionId,
    if (reads.isNotEmpty) 'reads': reads,
    if (doneTapes.isNotEmpty) 'doneTapes': doneTapes,
    if (pendingLeftTapes.isNotEmpty) 'pendingLeftTapes': pendingLeftTapes,
    if (pendingRightTapes.isNotEmpty) 'pendingRightTapes': pendingRightTapes,
  };
}

/// Where a reduced transition comes from. Sweep transitions carry the source
/// state they serve; transitions that write a track carry the source
/// transition and the tapes they applied.
final class TMMultiTapeTransitionProvenance {
  TMMultiTapeTransitionProvenance({
    required this.transitionId,
    required this.phase,
    this.sourceStateId,
    this.sourceTransitionId,
    Iterable<int> appliedTapes = const [],
  }) : appliedTapes = List<int>.unmodifiable(appliedTapes);

  final String transitionId;
  final TMMultiTapePhase phase;
  final String? sourceStateId;
  final String? sourceTransitionId;
  final List<int> appliedTapes;

  Map<String, Object?> toJson() => {
    'transitionId': transitionId,
    'phase': phase.name,
    if (sourceStateId != null) 'sourceStateId': sourceStateId,
    if (sourceTransitionId != null) 'sourceTransitionId': sourceTransitionId,
    if (appliedTapes.isNotEmpty) 'appliedTapes': appliedTapes,
  };
}

final class TMMultiTapeReductionReport {
  TMMultiTapeReductionReport({
    required this.sourceTmId,
    required this.sourceRevision,
    required this.tapeCount,
    required this.outcome,
    required this.limits,
    Iterable<TMMultiTapeReductionDiagnostic> diagnostics = const [],
    this.machine,
    Map<String, TMMultiTapeCell> cells = const {},
    Iterable<TMMultiTapeStateProvenance> stateProvenance = const [],
    Iterable<TMMultiTapeTransitionProvenance> transitionProvenance = const [],
  }) : diagnostics = List<TMMultiTapeReductionDiagnostic>.unmodifiable(
         diagnostics,
       ),
       cells = Map<String, TMMultiTapeCell>.unmodifiable(cells),
       stateProvenance = Map<String, TMMultiTapeStateProvenance>.unmodifiable({
         for (final item in stateProvenance) item.stateId: item,
       }),
       transitionProvenance =
           Map<String, TMMultiTapeTransitionProvenance>.unmodifiable({
             for (final item in transitionProvenance) item.transitionId: item,
           });

  static const schema = 'turing-lab.tm-multi-tape-reduction-report.v1';

  final String sourceTmId;
  final int sourceRevision;
  final int tapeCount;
  final TMMultiTapeReductionOutcome outcome;
  final TMMultiTapeReductionLimits limits;
  final List<TMMultiTapeReductionDiagnostic> diagnostics;

  /// The single-tape machine, present only when [outcome] is completed.
  final TM? machine;

  /// Composite tape symbol → decoded cell.
  final Map<String, TMMultiTapeCell> cells;
  final Map<String, TMMultiTapeStateProvenance> stateProvenance;
  final Map<String, TMMultiTapeTransitionProvenance> transitionProvenance;

  bool get isCompleted =>
      outcome == TMMultiTapeReductionOutcome.completed && machine != null;

  /// Source state ids behind a reduced state id, or the id itself when the
  /// reduction did not run (single-tape sources are their own provenance).
  String? sourceStateFor(String reducedStateId) =>
      stateProvenance[reducedStateId]?.sourceStateId;

  String? sourceTransitionFor(String reducedTransitionId) =>
      transitionProvenance[reducedTransitionId]?.sourceTransitionId;

  Map<String, Object?> toStructuredJson() => {
    'schema': schema,
    'sourceTmId': sourceTmId,
    'sourceRevision': sourceRevision,
    'tapeCount': tapeCount,
    'outcome': outcome.name,
    'limits': limits.toJson(),
    'diagnostics': diagnostics.map((item) => item.toJson()).toList(),
    if (machine != null) ...{
      'counts': {
        'states': machine!.states.length,
        'transitions': machine!.transitions.length,
        'tapeSymbols': machine!.tapeAlphabet.length,
        'compositeCells': cells.length,
        'phases': {
          for (final phase in TMMultiTapePhase.values)
            phase.name: stateProvenance.values
                .where((item) => item.phase == phase)
                .length,
        },
      },
      'machineId': machine!.id,
      'blankSymbol': machine!.blankSymbol,
    },
    'stateProvenance': stateProvenance.values
        .map((item) => item.toJson())
        .toList(),
    'transitionProvenance': transitionProvenance.values
        .map((item) => item.toJson())
        .toList(),
  };
}

abstract final class TMMultiTapeReducer {
  /// Reduces [tm] to a single-tape machine. Single-tape sources return
  /// `notApplicable`; building blocks and non final-state acceptance are
  /// `unsupportedMachine`; invalid machines are `invalidMachine`; and any
  /// [limits] overflow is `budgetExceeded` with the offending counts.
  static TMMultiTapeReductionReport reduce(
    TM tm, {
    required int sourceRevision,
    TMMultiTapeReductionLimits limits = const TMMultiTapeReductionLimits(),
  }) {
    final diagnostics = <TMMultiTapeReductionDiagnostic>[];
    TMMultiTapeReductionReport failure(TMMultiTapeReductionOutcome outcome) =>
        TMMultiTapeReductionReport(
          sourceTmId: tm.id,
          sourceRevision: sourceRevision,
          tapeCount: tm.tapeCount,
          outcome: outcome,
          limits: limits,
          diagnostics: diagnostics,
        );

    if (tm.tapeCount == 1) {
      diagnostics.add(
        _diagnostic(
          TMMultiTapeReductionDiagnosticCode.alreadySingleTape,
          TMMultiTapeReductionSeverity.warning,
        ),
      );
      return failure(TMMultiTapeReductionOutcome.notApplicable);
    }
    var unsupported = false;
    if (tm.blockDefinitions.isNotEmpty || tm.blockInvocations.isNotEmpty) {
      unsupported = true;
      diagnostics.add(
        _diagnostic(
          TMMultiTapeReductionDiagnosticCode.buildingBlocksUnsupported,
          TMMultiTapeReductionSeverity.error,
          detail: ([
            ...tm.blockDefinitions.keys,
            ...tm.blockInvocations.map((invocation) => invocation.id),
          ]..sort()).join(', '),
        ),
      );
    }
    if (tm.acceptancePolicy != TMAcceptancePolicy.finalState) {
      unsupported = true;
      diagnostics.add(
        _diagnostic(
          TMMultiTapeReductionDiagnosticCode.acceptancePolicyUnsupported,
          TMMultiTapeReductionSeverity.error,
          detail: tm.acceptancePolicy.name,
        ),
      );
    }
    var invalid = false;
    final errors = tm.validate();
    for (var index = 0; index < errors.length; index++) {
      invalid = true;
      diagnostics.add(
        _diagnostic(
          TMMultiTapeReductionDiagnosticCode.invalidMachine,
          TMMultiTapeReductionSeverity.error,
          detail: 'tm-validation-$index',
        ),
      );
    }
    final initial = tm.initialState;
    if (initial == null || !tm.states.contains(initial)) {
      invalid = true;
      diagnostics.add(
        _diagnostic(
          TMMultiTapeReductionDiagnosticCode.missingInitialState,
          TMMultiTapeReductionSeverity.error,
        ),
      );
    }
    if (tm.alphabet.contains(tm.blankSymbol)) {
      invalid = true;
      diagnostics.add(
        _diagnostic(
          TMMultiTapeReductionDiagnosticCode.blankInInputAlphabet,
          TMMultiTapeReductionSeverity.error,
          detail: tm.blankSymbol,
        ),
      );
    }
    if (unsupported) {
      return failure(TMMultiTapeReductionOutcome.unsupportedMachine);
    }
    if (invalid) {
      return failure(TMMultiTapeReductionOutcome.invalidMachine);
    }

    final tapeCount = tm.tapeCount;
    final gamma = tm.tapeAlphabet.toList()..sort();
    // Counted exactly: an integer power wraps (or becomes infinite on the
    // web) for large tape counts, and a wrapped value would slip past the
    // budget. The diagnostic saturates when the count does not fit an int.
    final compositeTotal = BigInt.from(gamma.length * 2).pow(tapeCount);
    final compositeCount = compositeTotal.isValidInt
        ? compositeTotal.toInt()
        : double.maxFinite.toInt();
    if (compositeTotal > BigInt.from(limits.maxTapeSymbols)) {
      diagnostics.add(
        _diagnostic(
          TMMultiTapeReductionDiagnosticCode.tapeSymbolBudget,
          TMMultiTapeReductionSeverity.error,
          count: compositeCount,
          limit: limits.maxTapeSymbols,
        ),
      );
      return failure(TMMultiTapeReductionOutcome.budgetExceeded);
    }

    final builder = _ReductionBuilder(tm: tm, gamma: gamma, limits: limits);
    try {
      builder.run(initial!);
    } on _BudgetExceeded catch (error) {
      diagnostics.add(
        _diagnostic(
          error.code,
          TMMultiTapeReductionSeverity.error,
          count: error.count,
          limit: error.limit,
        ),
      );
      return failure(TMMultiTapeReductionOutcome.budgetExceeded);
    }
    return TMMultiTapeReductionReport(
      sourceTmId: tm.id,
      sourceRevision: sourceRevision,
      tapeCount: tapeCount,
      outcome: TMMultiTapeReductionOutcome.completed,
      limits: limits,
      diagnostics: diagnostics,
      machine: builder.buildMachine(),
      cells: builder.cellsBySymbol,
      stateProvenance: builder.stateProvenance,
      transitionProvenance: builder.transitionProvenance,
    );
  }

  static TMMultiTapeReductionDiagnostic _diagnostic(
    TMMultiTapeReductionDiagnosticCode code,
    TMMultiTapeReductionSeverity severity, {
    String? detail,
    int? count,
    int? limit,
  }) => TMMultiTapeReductionDiagnostic(
    code: code,
    severity: severity,
    detail: detail,
    count: count,
    limit: limit,
    structuredMessage: TmMultiTapeReductionMessages.fromDiagnostic(
      code: code,
      severity: severity,
      detail: detail,
      count: count,
      limit: limit,
    ),
  );
}

final class _BudgetExceeded implements Exception {
  const _BudgetExceeded(this.code, {required this.count, required this.limit});

  final TMMultiTapeReductionDiagnosticCode code;
  final int count;
  final int limit;
}

/// Identity of a reduced state. Equal keys collapse to one state.
final class _Key {
  _Key(
    this.phase, {
    this.sourceStateId,
    this.sourceTransitionId,
    List<String?> reads = const [],
    Set<int> done = const {},
    Set<int> pendingLeft = const {},
    Set<int> pendingRight = const {},
  }) : reads = List<String?>.unmodifiable(reads),
       done = Set<int>.unmodifiable(done),
       pendingLeft = Set<int>.unmodifiable(pendingLeft),
       pendingRight = Set<int>.unmodifiable(pendingRight),
       canonical = [
         phase.name,
         sourceStateId ?? '',
         sourceTransitionId ?? '',
         // Length-prefixed so multi-character reads never collide.
         reads
             .map((read) => read == null ? '?' : '${read.length}:$read')
             .join(','),
         (done.toList()..sort()).join(','),
         (pendingLeft.toList()..sort()).join(','),
         (pendingRight.toList()..sort()).join(','),
       ].join('\n');

  final TMMultiTapePhase phase;
  final String? sourceStateId;
  final String? sourceTransitionId;
  final List<String?> reads;
  final Set<int> done;
  final Set<int> pendingLeft;
  final Set<int> pendingRight;
  final String canonical;

  @override
  bool operator ==(Object other) =>
      other is _Key && other.canonical == canonical;

  @override
  int get hashCode => canonical.hashCode;
}

final class _Node {
  _Node({required this.key, required this.state});

  final _Key key;
  final State state;
}

final class _CellAction {
  const _CellAction({
    required this.write,
    required this.move,
    required this.next,
    required this.appliedTapes,
  });

  final TMMultiTapeCell write;
  final TapeDirection move;
  final _Key next;
  final List<int> appliedTapes;
}

final class _ReductionBuilder {
  _ReductionBuilder({
    required this.tm,
    required this.gamma,
    required this.limits,
  }) : tapeCount = tm.tapeCount,
       blank = tm.blankSymbol,
       sigma = tm.alphabet.toList()..sort(),
       sourceStates = {for (final state in tm.states) state.id: state},
       sourceTransitions = {
         for (final transition in tm.tmTransitions) transition.id: transition,
       } {
    cells = _enumerateCells();
    cellsBySymbol = {for (final cell in cells) cell.symbol: cell};
    blankCell = TMMultiTapeCell(
      symbols: List<String>.filled(tapeCount, blank),
      heads: List<bool>.filled(tapeCount, false),
    );
  }

  final TM tm;
  final List<String> gamma;
  final TMMultiTapeReductionLimits limits;
  final int tapeCount;
  final String blank;
  final List<String> sigma;
  final Map<String, State> sourceStates;
  final Map<String, TMTransition> sourceTransitions;
  late final List<TMMultiTapeCell> cells;
  late final Map<String, TMMultiTapeCell> cellsBySymbol;
  late final TMMultiTapeCell blankCell;

  final Map<_Key, _Node> nodes = {};
  final List<_Node> worklist = [];
  final List<TMTransition> transitions = [];
  final List<TMMultiTapeStateProvenance> stateProvenance = [];
  final List<TMMultiTapeTransitionProvenance> transitionProvenance = [];

  Set<int> get allTapes => {for (var tape = 0; tape < tapeCount; tape++) tape};

  List<TMMultiTapeCell> _enumerateCells() {
    final result = <TMMultiTapeCell>[];
    void symbols(List<String> prefix) {
      if (prefix.length == tapeCount) {
        void heads(List<bool> marks) {
          if (marks.length == tapeCount) {
            result.add(TMMultiTapeCell(symbols: prefix, heads: marks));
            return;
          }
          heads([...marks, false]);
          heads([...marks, true]);
        }

        heads(const []);
        return;
      }
      for (final symbol in gamma) {
        symbols([...prefix, symbol]);
      }
    }

    symbols(const []);
    return result;
  }

  void run(State initial) {
    final start = stateFor(_Key(TMMultiTapePhase.initializeFirst));
    assert(start.id == 'r0');
    while (worklist.isNotEmpty) {
      final node = worklist.removeLast();
      _expand(node, initial);
    }
  }

  State stateFor(_Key key) {
    final existing = nodes[key];
    if (existing != null) return existing.state;
    if (nodes.length >= limits.maxStates) {
      throw _BudgetExceeded(
        TMMultiTapeReductionDiagnosticCode.stateBudget,
        count: nodes.length + 1,
        limit: limits.maxStates,
      );
    }
    final index = nodes.length;
    final sourceState = key.sourceStateId == null
        ? null
        : sourceStates[key.sourceStateId!];
    final accepting =
        key.phase == TMMultiTapePhase.read &&
        key.reads.every((read) => read == null) &&
        sourceState != null &&
        tm.acceptingStates.contains(sourceState);
    final state = State(
      id: 'r$index',
      label: _label(key),
      position: Vector2((index % 8) * 140.0 + 80, (index ~/ 8) * 120.0 + 80),
      isInitial: index == 0,
      isAccepting: accepting,
      type: index == 0
          ? StateType.initial
          : accepting
          ? StateType.accepting
          : StateType.normal,
    );
    final node = _Node(key: key, state: state);
    nodes[key] = node;
    worklist.add(node);
    stateProvenance.add(
      TMMultiTapeStateProvenance(
        stateId: state.id,
        phase: key.phase,
        sourceStateId: key.sourceStateId,
        sourceTransitionId: key.sourceTransitionId,
        reads: key.reads,
        doneTapes: key.done.toList()..sort(),
        pendingLeftTapes: key.pendingLeft.toList()..sort(),
        pendingRightTapes: key.pendingRight.toList()..sort(),
      ),
    );
    return state;
  }

  String _label(_Key key) {
    String tapes(Set<int> set) =>
        (set.toList()..sort()).map((tape) => 'T${tape + 1}').join('');
    return switch (key.phase) {
      TMMultiTapePhase.initializeFirst => 'init',
      TMMultiTapePhase.initializeRest => 'init+',
      TMMultiTapePhase.rewind => 'rewind',
      TMMultiTapePhase.read =>
        '${sourceStates[key.sourceStateId]?.label ?? key.sourceStateId}'
            '·read[${key.reads.map((read) => read ?? '?').join(',')}]',
      TMMultiTapePhase.apply =>
        '${key.sourceTransitionId}·apply{${tapes(key.done)}}'
            '${key.pendingLeft.isEmpty ? '' : '←${tapes(key.pendingLeft)}'}',
      TMMultiTapePhase.excursion =>
        '${key.sourceTransitionId}·mark→${tapes(key.pendingRight)}',
      TMMultiTapePhase.resume => '${key.sourceTransitionId}·resume',
    };
  }

  void _addTransition(
    State from,
    State to, {
    required String read,
    required String write,
    required TapeDirection move,
    required TMMultiTapePhase phase,
    String? sourceStateId,
    String? sourceTransitionId,
    List<int> appliedTapes = const [],
  }) {
    if (transitions.length >= limits.maxTransitions) {
      throw _BudgetExceeded(
        TMMultiTapeReductionDiagnosticCode.transitionBudget,
        count: transitions.length + 1,
        limit: limits.maxTransitions,
      );
    }
    final id = 'r${transitions.length}';
    transitions.add(
      TMTransition(
        id: id,
        fromState: from,
        toState: to,
        // Self-loops need an explicit control point to validate.
        controlPoint: identical(from, to)
            ? Vector2(from.position.x, from.position.y - 70)
            : Vector2.zero(),
        label: TMTransition.formatLabel(
          readSymbol: read,
          writeSymbol: write,
          direction: move,
        ),
        readSymbol: read,
        writeSymbol: write,
        direction: move,
      ),
    );
    transitionProvenance.add(
      TMMultiTapeTransitionProvenance(
        transitionId: id,
        phase: phase,
        sourceStateId: sourceStateId,
        sourceTransitionId: sourceTransitionId,
        appliedTapes: appliedTapes,
      ),
    );
  }

  void _expand(_Node node, State initial) {
    final key = node.key;
    final from = node.state;
    switch (key.phase) {
      case TMMultiTapePhase.initializeFirst:
        // The first input cell also receives every head marker.
        final allHeads = List<bool>.filled(tapeCount, true);
        for (final symbol in sigma) {
          _addTransition(
            from,
            stateFor(_Key(TMMultiTapePhase.initializeRest)),
            read: symbol,
            write: TMMultiTapeCell(
              symbols: [symbol, ...List.filled(tapeCount - 1, blank)],
              heads: allHeads,
            ).symbol,
            move: TapeDirection.right,
            phase: key.phase,
            sourceStateId: initial.id,
          );
        }
        _addTransition(
          from,
          stateFor(_readKey(initial.id)),
          read: blankCell.symbol,
          write: blankCell.copyWith(heads: allHeads).symbol,
          move: TapeDirection.stay,
          phase: key.phase,
          sourceStateId: initial.id,
        );
      case TMMultiTapePhase.initializeRest:
        for (final symbol in sigma) {
          _addTransition(
            from,
            from,
            read: symbol,
            write: TMMultiTapeCell(
              symbols: [symbol, ...List.filled(tapeCount - 1, blank)],
              heads: List<bool>.filled(tapeCount, false),
            ).symbol,
            move: TapeDirection.right,
            phase: key.phase,
            sourceStateId: initial.id,
          );
        }
        _addTransition(
          from,
          stateFor(_Key(TMMultiTapePhase.rewind)),
          read: blankCell.symbol,
          write: blankCell.symbol,
          move: TapeDirection.left,
          phase: key.phase,
          sourceStateId: initial.id,
        );
      case TMMultiTapePhase.rewind:
        // All heads start together on the first cell, so the rewind stops at
        // the only cell carrying markers.
        for (final cell in cells) {
          if (cell.hasAllHeads) {
            _addTransition(
              from,
              stateFor(_readKey(initial.id)),
              read: cell.symbol,
              write: cell.symbol,
              move: TapeDirection.stay,
              phase: key.phase,
              sourceStateId: initial.id,
            );
          } else if (!cell.hasHeads) {
            _addTransition(
              from,
              from,
              read: cell.symbol,
              write: cell.symbol,
              move: TapeDirection.left,
              phase: key.phase,
              sourceStateId: initial.id,
            );
          }
        }
      case TMMultiTapePhase.read:
        final source = sourceStates[key.sourceStateId]!;
        for (final cell in cells) {
          final reads = List<String?>.generate(
            tapeCount,
            (tape) => cell.heads[tape] ? cell.symbols[tape] : key.reads[tape],
          );
          if (reads.any((read) => read == null)) {
            _addTransition(
              from,
              stateFor(
                _Key(
                  TMMultiTapePhase.read,
                  sourceStateId: source.id,
                  reads: reads,
                ),
              ),
              read: cell.symbol,
              write: cell.symbol,
              move: TapeDirection.right,
              phase: key.phase,
              sourceStateId: source.id,
            );
            continue;
          }
          final vector = reads.cast<String>();
          final candidates =
              tm.getTransitionsFromStateOnSymbols(source, vector).toList()
                ..sort((a, b) => a.id.compareTo(b.id));
          for (final transition in candidates) {
            final action = _processCell(
              transition,
              cell,
              done: const {},
              pendingLeft: const {},
            );
            _addTransition(
              from,
              stateFor(action.next),
              read: cell.symbol,
              write: action.write.symbol,
              move: action.move,
              phase: key.phase,
              sourceStateId: source.id,
              sourceTransitionId: transition.id,
              appliedTapes: action.appliedTapes,
            );
          }
        }
      case TMMultiTapePhase.apply:
        final transition = sourceTransitions[key.sourceTransitionId]!;
        for (final cell in cells) {
          final action = _processCell(
            transition,
            cell,
            done: key.done,
            pendingLeft: key.pendingLeft,
          );
          _addTransition(
            from,
            stateFor(action.next),
            read: cell.symbol,
            write: action.write.symbol,
            move: action.move,
            phase: key.phase,
            sourceStateId: transition.fromState.id,
            sourceTransitionId: transition.id,
            appliedTapes: action.appliedTapes,
          );
        }
      case TMMultiTapePhase.excursion:
        final transition = sourceTransitions[key.sourceTransitionId]!;
        final resume = stateFor(
          _Key(
            TMMultiTapePhase.resume,
            sourceTransitionId: transition.id,
            done: key.done,
            pendingLeft: key.pendingLeft,
          ),
        );
        for (final cell in cells) {
          final heads = [
            for (var tape = 0; tape < tapeCount; tape++)
              cell.heads[tape] || key.pendingRight.contains(tape),
          ];
          _addTransition(
            from,
            resume,
            read: cell.symbol,
            write: cell.copyWith(heads: heads).symbol,
            move: TapeDirection.left,
            phase: key.phase,
            sourceStateId: transition.fromState.id,
            sourceTransitionId: transition.id,
            appliedTapes: key.pendingRight.toList()..sort(),
          );
        }
      case TMMultiTapePhase.resume:
        final transition = sourceTransitions[key.sourceTransitionId]!;
        final completed =
            key.done.length == tapeCount && key.pendingLeft.isEmpty;
        final next = stateFor(
          completed
              ? _readKey(transition.toState.id)
              : _Key(
                  TMMultiTapePhase.apply,
                  sourceTransitionId: transition.id,
                  done: key.done,
                  pendingLeft: key.pendingLeft,
                ),
        );
        for (final cell in cells) {
          _addTransition(
            from,
            next,
            read: cell.symbol,
            write: cell.symbol,
            move: completed ? TapeDirection.stay : TapeDirection.left,
            phase: key.phase,
            sourceStateId: transition.fromState.id,
            sourceTransitionId: transition.id,
          );
        }
    }
  }

  _Key _readKey(String sourceStateId) => _Key(
    TMMultiTapePhase.read,
    sourceStateId: sourceStateId,
    reads: List<String?>.filled(tapeCount, null),
  );

  /// Applies [transition] to every unprocessed head on [cell] during the
  /// leftward sweep, placing markers that arrive from the right first.
  _CellAction _processCell(
    TMTransition transition,
    TMMultiTapeCell cell, {
    required Set<int> done,
    required Set<int> pendingLeft,
  }) {
    final operations = transition.operationsForTapeCount(tapeCount, blank);
    final symbols = List<String>.of(cell.symbols);
    final heads = List<bool>.of(cell.heads);
    final nextDone = {...done, ...pendingLeft};
    for (final tape in pendingLeft) {
      heads[tape] = true;
    }
    final movingRight = <int>{};
    final movingLeft = <int>{};
    final applied = <int>[];
    for (var tape = 0; tape < tapeCount; tape++) {
      if (!cell.heads[tape] || nextDone.contains(tape)) continue;
      applied.add(tape);
      symbols[tape] = operations.writeSymbols[tape];
      switch (operations.directions[tape]) {
        case TapeDirection.stay:
          heads[tape] = true;
        case TapeDirection.right:
          heads[tape] = false;
          movingRight.add(tape);
        case TapeDirection.left:
          heads[tape] = false;
          movingLeft.add(tape);
      }
      nextDone.add(tape);
    }
    final write = TMMultiTapeCell(symbols: symbols, heads: heads);
    if (movingRight.isNotEmpty) {
      return _CellAction(
        write: write,
        move: TapeDirection.right,
        next: _Key(
          TMMultiTapePhase.excursion,
          sourceTransitionId: transition.id,
          done: nextDone,
          pendingLeft: movingLeft,
          pendingRight: movingRight,
        ),
        appliedTapes: applied,
      );
    }
    if (nextDone.length == tapeCount && movingLeft.isEmpty) {
      return _CellAction(
        write: write,
        move: TapeDirection.stay,
        next: _readKey(transition.toState.id),
        appliedTapes: applied,
      );
    }
    return _CellAction(
      write: write,
      move: TapeDirection.left,
      next: _Key(
        TMMultiTapePhase.apply,
        sourceTransitionId: transition.id,
        done: nextDone,
        pendingLeft: movingLeft,
      ),
      appliedTapes: applied,
    );
  }

  TM buildMachine() {
    final states = nodes.values.map((node) => node.state).toSet();
    final initial = nodes.values.first.state;
    final columns = math.min(8, states.length);
    final rows = (states.length / 8).ceil();
    return TM(
      id: '${tm.id}.single-tape',
      name: '${tm.name} (single-tape reduction)',
      states: states,
      transitions: transitions.toSet(),
      alphabet: sigma.toSet(),
      initialState: initial,
      acceptingStates: states.where((state) => state.isAccepting).toSet(),
      created: tm.created,
      modified: tm.modified,
      bounds: math.Rectangle<double>(
        0,
        0,
        columns * 140.0 + 160,
        rows * 120.0 + 160,
      ),
      tapeAlphabet: {...sigma, ...cellsBySymbol.keys},
      blankSymbol: blankCell.symbol,
      tapeCount: 1,
      acceptancePolicy: TMAcceptancePolicy.finalState,
    );
  }
}

enum TMMultiTapeReductionSampleOutcome {
  matchingAcceptance,
  matchingRejection,
  mismatch,
  boundedUnknown,
  invalid,
}

final class TMMultiTapeReductionSample {
  TMMultiTapeReductionSample({
    required Iterable<String> inputTokens,
    required this.outcome,
    this.sourceAccepted,
    this.reducedAccepted,
    this.detailCode,
  }) : inputTokens = List<String>.unmodifiable(inputTokens);

  final List<String> inputTokens;
  final TMMultiTapeReductionSampleOutcome outcome;
  final bool? sourceAccepted;
  final bool? reducedAccepted;
  final String? detailCode;

  Map<String, Object?> toJson() => {
    'input': inputTokens,
    'outcome': outcome.name,
    if (sourceAccepted != null) 'sourceAccepted': sourceAccepted,
    if (reducedAccepted != null) 'reducedAccepted': reducedAccepted,
    if (detailCode != null) 'detailCode': detailCode,
  };
}

/// Bounded differential evidence between a multi-tape source and its
/// reduction. A bounded or timed-out run is `boundedUnknown`: it is neither
/// a rejection nor a proof.
final class TMMultiTapeReductionEvidence {
  TMMultiTapeReductionEvidence(Iterable<TMMultiTapeReductionSample> samples)
    : samples = List<TMMultiTapeReductionSample>.unmodifiable(samples);

  final List<TMMultiTapeReductionSample> samples;
  bool get isProof => false;
  bool get hasMismatch => samples.any(
    (sample) => sample.outcome == TMMultiTapeReductionSampleOutcome.mismatch,
  );
  int countOf(TMMultiTapeReductionSampleOutcome outcome) =>
      samples.where((sample) => sample.outcome == outcome).length;
}

abstract final class TMMultiTapeReductionChecker {
  /// Runs the source machine with the multi-tape analyzer and the reduced
  /// machine with the single-tape analyzer on every input, under explicit
  /// step, configuration and time limits. The reduced machine needs roughly
  /// `2 · (input length + head span)` steps per source step, so
  /// [reducedStepFactor] scales its step budget.
  static Future<TMMultiTapeReductionEvidence> check(
    TM source,
    TMMultiTapeReductionReport reduction,
    Iterable<List<String>> inputs, {
    int sourceMaxSteps = 200,
    int reducedStepFactor = 64,
    int maxConfigurations = 20000,
    Duration perSampleTimeout = const Duration(seconds: 2),
  }) async {
    if (!reduction.isCompleted) {
      throw ArgumentError.value(
        reduction.outcome,
        'reduction',
        'Differential checks require a completed reduction.',
      );
    }
    if (reduction.sourceTmId != source.id) {
      throw ArgumentError.value(source.id, 'source', 'Source mismatch.');
    }
    final reduced = reduction.machine!;
    final unique = <String, List<String>>{};
    for (final input in inputs) {
      unique.putIfAbsent(
        input.map((token) => '${token.length}:$token').join('|'),
        () => List.unmodifiable(input),
      );
    }
    final samples = <TMMultiTapeReductionSample>[];
    for (final key in unique.keys.toList()..sort()) {
      final input = unique[key]!;
      if (input.any((symbol) => !source.alphabet.contains(symbol))) {
        samples.add(
          TMMultiTapeReductionSample(
            inputTokens: input,
            outcome: TMMultiTapeReductionSampleOutcome.invalid,
            detailCode: 'input-symbol-outside-alphabet',
          ),
        );
        continue;
      }
      final sourceRun = await TMMultiTapeExecutionAnalyzer.analyzeTokens(
        source,
        input.join(),
        input,
        maxSteps: sourceMaxSteps,
        maxConfigurations: maxConfigurations,
        timeout: perSampleTimeout,
        operationsPerBatch: 250,
        includeTrace: false,
      );
      final reducedRun = await TMExecutionAnalyzer.analyzeTokens(
        reduced,
        input,
        maxSteps: sourceMaxSteps * reducedStepFactor,
        maxConfigurations: maxConfigurations,
        timeout: perSampleTimeout,
        includeTrace: false,
      );
      final sourceAccepted = _accepted(sourceRun.outcome);
      final reducedAccepted = _accepted(reducedRun.outcome);
      if (sourceAccepted == null || reducedAccepted == null) {
        final invalid =
            sourceRun.outcome == TMExecutionOutcome.invalidMachine ||
            reducedRun.outcome == TMExecutionOutcome.invalidMachine;
        samples.add(
          TMMultiTapeReductionSample(
            inputTokens: input,
            outcome: invalid
                ? TMMultiTapeReductionSampleOutcome.invalid
                : TMMultiTapeReductionSampleOutcome.boundedUnknown,
            sourceAccepted: sourceAccepted,
            reducedAccepted: reducedAccepted,
            detailCode:
                'source-${sourceRun.outcome.name}/reduced-${reducedRun.outcome.name}',
          ),
        );
        continue;
      }
      samples.add(
        TMMultiTapeReductionSample(
          inputTokens: input,
          outcome: sourceAccepted == reducedAccepted
              ? (sourceAccepted
                    ? TMMultiTapeReductionSampleOutcome.matchingAcceptance
                    : TMMultiTapeReductionSampleOutcome.matchingRejection)
              : TMMultiTapeReductionSampleOutcome.mismatch,
          sourceAccepted: sourceAccepted,
          reducedAccepted: reducedAccepted,
        ),
      );
    }
    return TMMultiTapeReductionEvidence(samples);
  }

  static bool? _accepted(TMExecutionOutcome outcome) => switch (outcome) {
    TMExecutionOutcome.accepted => true,
    TMExecutionOutcome.haltedRejected ||
    TMExecutionOutcome.provenCycle => false,
    _ => null,
  };
}
