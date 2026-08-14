//
//  tm.dart
//  Turing Lab
//
//  Representação de máquinas de Turing que herda Automaton para manter estados,
//  transições e configuração de canvas, acrescentando alfabeto de fita,
//  símbolo branco e contagem de fitas. Oferece serialização completa, cópias
//  imutáveis e validações específicas que protegem a integridade de símbolos e
//  transições durante importações e simulações.
//
//  Thales Matheus Mendonça Santos - October 2025
//
import 'dart:math' as math;
import 'package:vector_math/vector_math_64.dart';
import 'state.dart';
import 'transition.dart';
import 'tm_transition.dart';
import 'automaton.dart';

const Object _unset = Object();

/// Turing Machine (TM) implementation
class TM extends Automaton {
  /// Tape alphabet symbols (unmodifiable)
  final Set<String> tapeAlphabet;

  /// Blank symbol
  final String blankSymbol;

  /// Number of tapes (always 1 for single-tape TM)
  final int tapeCount;

  TM({
    required super.id,
    required super.name,
    required super.states,
    required super.transitions,
    required super.alphabet,
    super.initialState,
    required super.acceptingStates,
    required super.created,
    required super.modified,
    required super.bounds,
    super.zoomLevel,
    super.panOffset,
    required Set<String> tapeAlphabet,
    this.blankSymbol = 'B',
    this.tapeCount = 1, // Always 1 for single-tape TM
  })  : tapeAlphabet = Set<String>.unmodifiable(tapeAlphabet),
        super(type: AutomatonType.tm);

  /// Creates a copy of this TM with updated properties
  @override
  TM copyWith({
    String? id,
    String? name,
    Set<State>? states,
    Set<Transition>? transitions,
    Set<String>? alphabet,
    Object? initialState = _unset,
    Set<State>? acceptingStates,
    AutomatonType? type,
    DateTime? created,
    DateTime? modified,
    math.Rectangle? bounds,
    double? zoomLevel,
    Vector2? panOffset,
    Set<String>? tapeAlphabet,
    String? blankSymbol,
    int? tapeCount,
  }) {
    return TM(
      id: id ?? this.id,
      name: name ?? this.name,
      states: states ?? this.states,
      transitions: transitions ?? this.transitions,
      alphabet: alphabet ?? this.alphabet,
      initialState:
          initialState == _unset ? this.initialState : initialState as State?,
      acceptingStates: acceptingStates ?? this.acceptingStates,
      created: created ?? this.created,
      modified: modified ?? this.modified,
      bounds: bounds ?? this.bounds,
      zoomLevel: zoomLevel ?? this.zoomLevel,
      panOffset: panOffset ?? this.panOffset,
      tapeAlphabet: tapeAlphabet != null
          ? Set<String>.unmodifiable(tapeAlphabet)
          : this.tapeAlphabet,
      blankSymbol: blankSymbol ?? this.blankSymbol,
      tapeCount: tapeCount ?? this.tapeCount,
    );
  }

  /// Converts the TM to a JSON representation
  @override
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'type': 'TM',
      'states': states.map((s) => s.toJson()).toList(),
      'transitions': transitions.map((t) => t.toJson()).toList(),
      'alphabet': alphabet.toList(),
      'initialState': initialState?.toJson(),
      'acceptingStates': acceptingStates.map((s) => s.toJson()).toList(),
      'created': created.toIso8601String(),
      'modified': modified.toIso8601String(),
      'bounds': {
        'x': bounds.left,
        'y': bounds.top,
        'width': bounds.width,
        'height': bounds.height,
      },
      'zoomLevel': zoomLevel,
      'panOffset': {'x': panOffset.x, 'y': panOffset.y},
      'tapeAlphabet': tapeAlphabet.toList(),
      'blankSymbol': blankSymbol,
      'tapeCount': tapeCount,
    };
  }

  /// Creates a TM from a JSON representation
  factory TM.fromJson(Map<String, dynamic> json) {
    final boundsData = (json['bounds'] as Map?)?.cast<String, dynamic>();
    final panOffsetData = (json['panOffset'] as Map?)?.cast<String, dynamic>();
    final states = (json['states'] as List)
        .map((s) => State.fromJson(s as Map<String, dynamic>))
        .toSet();
    final statesById = {for (final state in states) state.id: state};

    return TM(
      id: json['id'] as String,
      name: json['name'] as String,
      states: states,
      transitions: (json['transitions'] as List)
          .map(
            (t) => TMTransition.fromJson(
              t as Map<String, dynamic>,
              statesById: statesById,
            ),
          )
          .toSet(),
      alphabet: Set<String>.from(json['alphabet'] as List),
      initialState: json['initialState'] != null
          ? State.fromJson(json['initialState'] as Map<String, dynamic>)
          : null,
      acceptingStates: (json['acceptingStates'] as List)
          .map((s) => State.fromJson(s as Map<String, dynamic>))
          .toSet(),
      created: DateTime.parse(json['created'] as String),
      modified: DateTime.parse(json['modified'] as String),
      bounds: math.Rectangle(
        (boundsData?['x'] as num?)?.toDouble() ?? 0.0,
        (boundsData?['y'] as num?)?.toDouble() ?? 0.0,
        (boundsData?['width'] as num?)?.toDouble() ?? 0.0,
        (boundsData?['height'] as num?)?.toDouble() ?? 0.0,
      ),
      zoomLevel: (json['zoomLevel'] as num?)?.toDouble() ?? 1.0,
      panOffset: Vector2(
        (panOffsetData?['x'] as num?)?.toDouble() ?? 0.0,
        (panOffsetData?['y'] as num?)?.toDouble() ?? 0.0,
      ),
      tapeAlphabet: Set<String>.from(json['tapeAlphabet'] as List),
      blankSymbol: json['blankSymbol'] as String? ?? 'B',
      tapeCount: json['tapeCount'] as int? ?? 1,
    );
  }

  /// Validates the TM properties
  @override
  List<String> validate() {
    final errors = super.validate();

    // Validate TM-specific properties
    if (tapeAlphabet.isEmpty) {
      errors.add('TM must have a non-empty tape alphabet');
    }

    if (blankSymbol.isEmpty) {
      errors.add('TM must have a blank symbol');
    }

    if (!tapeAlphabet.contains(blankSymbol)) {
      errors.add('Blank symbol must be in the tape alphabet');
    }

    if (tapeCount < 1) {
      errors.add('TM must have at least one tape');
    }

    for (final transition in transitions) {
      if (transition is! TMTransition) {
        errors.add('TM can only contain TM transitions');
      } else {
        final TMTransition tmTransition = transition;
        final transitionErrors = tmTransition.validate();
        errors.addAll(
          transitionErrors.map((e) => 'Transition ${tmTransition.id}: $e'),
        );

        // Validate tape symbols
        if (!tapeAlphabet.contains(tmTransition.readSymbol)) {
          errors.add(
            'Transition ${tmTransition.id} references invalid read symbol',
          );
        }

        if (!tapeAlphabet.contains(tmTransition.writeSymbol)) {
          errors.add(
            'Transition ${tmTransition.id} references invalid write symbol',
          );
        }

        // Validate tape number
        if (tmTransition.tapeNumber >= tapeCount) {
          errors.add(
            'Transition ${tmTransition.id} references invalid tape number',
          );
        }
      }
    }

    return errors;
  }

  /// Gets all TM transitions
  Set<TMTransition> get tmTransitions {
    return transitions.whereType<TMTransition>().toSet();
  }

  /// Gets all transitions for a specific tape
  Set<TMTransition> getTransitionsForTape(int tapeNumber) {
    return tmTransitions.where((t) => t.tapeNumber == tapeNumber).toSet();
  }

  /// Gets all transitions from a state that can read a specific symbol
  Set<TMTransition> getTransitionsFromStateOnSymbol(
    State state,
    String symbol,
  ) {
    return tmTransitions
        .where((t) => t.fromState == state && t.canRead(symbol))
        .toSet();
  }

  /// Gets all transitions from a state that can read a specific symbol on a specific tape
  Set<TMTransition> getTransitionsFromStateOnSymbolAndTape(
    State state,
    String symbol,
    int tapeNumber,
  ) {
    return tmTransitions
        .where(
          (t) =>
              t.fromState == state &&
              t.canRead(symbol) &&
              t.tapeNumber == tapeNumber,
        )
        .toSet();
  }

  /// Gets all transitions that move left
  Set<TMTransition> get leftMovingTransitions {
    return tmTransitions.where((t) => t.movesLeft).toSet();
  }

  /// Gets all transitions that move right
  Set<TMTransition> get rightMovingTransitions {
    return tmTransitions.where((t) => t.movesRight).toSet();
  }

  /// Gets all transitions that stay in place
  Set<TMTransition> get stayTransitions {
    return tmTransitions.where((t) => t.staysInPlace).toSet();
  }

  /// Checks if the TM is deterministic
  bool get isDeterministic {
    for (final state in states) {
      final outgoingTransitions = getTransitionsFrom(state);
      final tapeSymbols = <String, int>{};

      for (final transition in outgoingTransitions) {
        if (transition is TMTransition) {
          final key = '${transition.readSymbol}_${transition.tapeNumber}';
          tapeSymbols[key] = (tapeSymbols[key] ?? 0) + 1;
        }
      }

      if (tapeSymbols.values.any((count) => count > 1)) {
        return false;
      }
    }

    return true;
  }

  /// Checks if the TM is non-deterministic
  bool get isNondeterministic {
    return !isDeterministic;
  }

  /// Gets all symbols that can be read from the tape
  Set<String> get readableSymbols {
    return tmTransitions.map((t) => t.readSymbol).toSet();
  }

  /// Gets all symbols that can be written to the tape
  Set<String> get writableSymbols {
    return tmTransitions.map((t) => t.writeSymbol).toSet();
  }

  /// Creates an empty TM
  factory TM.empty({
    required String id,
    required String name,
    Set<String>? tapeAlphabet,
    String? blankSymbol,
    int? tapeCount,
    math.Rectangle? bounds,
  }) {
    final now = DateTime.now();
    return TM(
      id: id,
      name: name,
      states: {},
      transitions: {},
      alphabet: {},
      acceptingStates: {},
      created: now,
      modified: now,
      bounds: bounds ?? const math.Rectangle(0, 0, 800, 600),
      tapeAlphabet: tapeAlphabet ?? {'0', '1', 'B'},
      blankSymbol: blankSymbol ?? 'B',
      tapeCount: tapeCount ?? 1,
    );
  }

  /// Creates a simple TM with one state
  factory TM.singleState({
    required String id,
    required String name,
    required String stateId,
    required String stateLabel,
    required Vector2 position,
    bool isInitial = false,
    bool isAccepting = false,
    Set<String>? tapeAlphabet,
    String? blankSymbol,
    int? tapeCount,
    math.Rectangle? bounds,
  }) {
    final now = DateTime.now();
    final state = State(
      id: stateId,
      label: stateLabel,
      position: position,
      isInitial: isInitial,
      isAccepting: isAccepting,
    );

    return TM(
      id: id,
      name: name,
      states: {state},
      transitions: {},
      alphabet: {},
      initialState: isInitial ? state : null,
      acceptingStates: isAccepting ? {state} : {},
      created: now,
      modified: now,
      bounds: bounds ?? const math.Rectangle(0, 0, 800, 600),
      tapeAlphabet: tapeAlphabet ?? {'0', '1', 'B'},
      blankSymbol: blankSymbol ?? 'B',
      tapeCount: tapeCount ?? 1,
    );
  }

  /// Creates a simple TM that accepts all strings
  factory TM.acceptAll({
    required String id,
    required String name,
    math.Rectangle? bounds,
  }) {
    final now = DateTime.now();
    final q0 = State(
      id: 'q0',
      label: 'q0',
      position: Vector2(100, 100),
      isInitial: true,
      isAccepting: true,
    );

    return TM(
      id: id,
      name: name,
      states: {q0},
      transitions: {},
      alphabet: {},
      initialState: q0,
      acceptingStates: {q0},
      created: now,
      modified: now,
      bounds: bounds ?? const math.Rectangle(0, 0, 800, 600),
      tapeAlphabet: {'0', '1', 'B'},
      blankSymbol: 'B',
      tapeCount: 1,
    );
  }

  /// Creates a simple TM that rejects all strings
  factory TM.rejectAll({
    required String id,
    required String name,
    math.Rectangle? bounds,
  }) {
    final now = DateTime.now();
    final q0 = State(
      id: 'q0',
      label: 'q0',
      position: Vector2(100, 100),
      isInitial: true,
      isAccepting: false,
    );

    return TM(
      id: id,
      name: name,
      states: {q0},
      transitions: {},
      alphabet: {},
      initialState: q0,
      acceptingStates: {},
      created: now,
      modified: now,
      bounds: bounds ?? const math.Rectangle(0, 0, 800, 600),
      tapeAlphabet: {'0', '1', 'B'},
      blankSymbol: 'B',
      tapeCount: 1,
    );
  }

  /// Creates a TM that copies input to output
  factory TM.copyMachine({
    required String id,
    required String name,
    math.Rectangle? bounds,
  }) {
    final now = DateTime.now();
    final q0 = State(
      id: 'q0',
      label: 'q0',
      position: Vector2(100, 100),
      isInitial: true,
      isAccepting: false,
    );
    final q1 = State(
      id: 'q1',
      label: 'q1',
      position: Vector2(200, 100),
      isInitial: false,
      isAccepting: true,
    );

    final t1 = TMTransition.readWrite(
      id: 't1',
      fromState: q0,
      toState: q0,
      symbol: '0',
      direction: TapeDirection.right,
    );

    final t2 = TMTransition.readWrite(
      id: 't2',
      fromState: q0,
      toState: q0,
      symbol: '1',
      direction: TapeDirection.right,
    );

    final t3 = TMTransition.readWrite(
      id: 't3',
      fromState: q0,
      toState: q1,
      symbol: 'B',
      direction: TapeDirection.stay,
    );

    return TM(
      id: id,
      name: name,
      states: {q0, q1},
      transitions: {t1, t2, t3},
      alphabet: {'0', '1'},
      initialState: q0,
      acceptingStates: {q1},
      created: now,
      modified: now,
      bounds: bounds ?? const math.Rectangle(0, 0, 800, 600),
      tapeAlphabet: {'0', '1', 'B'},
      blankSymbol: 'B',
      tapeCount: 1,
    );
  }

  /// Gets TM transition from state on symbol
  TMTransition? getTMTransitionFromStateOnSymbol(
    String stateId,
    String symbol,
  ) {
    for (final transition in transitions) {
      if (transition is TMTransition) {
        if (transition.fromState.id == stateId &&
            transition.readSymbol == symbol) {
          return transition;
        }
      }
    }
    return null;
  }
}
