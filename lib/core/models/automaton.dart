//
//  automaton.dart
//  Turing Lab
//
//  Classe base abstrata que representa autômatos no domínio do aplicativo,
//  mantendo coleções imutáveis de estados, transições, alfabetos e metadados de
//  visualização. Define contratos de clonagem, serialização e validação comum
//  para FSA, PDA e TM, além de oferecer fábricas que instanciam tipos concretos
//  a partir de descrições JSON.
//
//  Thales Matheus Mendonça Santos - October 2025
//
import 'dart:collection';
import 'dart:math' as math;
import 'package:vector_math/vector_math_64.dart';
import 'state.dart';
import 'transition.dart';
import 'fsa.dart';
import 'pda.dart';
import 'tm.dart';

/// Abstract base class for all types of automata
abstract class Automaton {
  /// Unique identifier for the automaton
  final String id;

  /// User-defined name for the automaton
  final String name;

  /// Set of all states in the automaton (unmodifiable)
  final Set<State> states;

  /// Set of all transitions in the automaton (unmodifiable)
  final Set<Transition> transitions;

  /// Input alphabet symbols (unmodifiable)
  final Set<String> alphabet;

  /// Initial state (can be null)
  final State? initialState;

  /// Set of accepting/final states (unmodifiable)
  final Set<State> acceptingStates;

  /// Type of the automaton
  final AutomatonType type;

  /// Creation timestamp
  final DateTime created;

  /// Last modification timestamp
  final DateTime modified;

  /// Bounding rectangle for mobile display
  final math.Rectangle bounds;

  /// Current zoom level (0.5 to 3.0)
  final double zoomLevel;

  /// Pan offset for mobile navigation
  final Vector2 panOffset;

  Automaton({
    required this.id,
    required this.name,
    required Set<State> states,
    required Set<Transition> transitions,
    required Set<String> alphabet,
    this.initialState,
    required Set<State> acceptingStates,
    required this.type,
    required this.created,
    required this.modified,
    required this.bounds,
    this.zoomLevel = 1.0,
    Vector2? panOffset,
  })  : states = Set<State>.unmodifiable(states),
        transitions = Set<Transition>.unmodifiable(transitions),
        alphabet = Set<String>.unmodifiable(alphabet),
        acceptingStates = Set<State>.unmodifiable(acceptingStates),
        panOffset = (panOffset ?? Vector2.zero()).clone();

  /// Creates a copy of this automaton with updated properties
  Automaton copyWith({
    String? id,
    String? name,
    Set<State>? states,
    Set<Transition>? transitions,
    Set<String>? alphabet,
    State? initialState,
    Set<State>? acceptingStates,
    AutomatonType? type,
    DateTime? created,
    DateTime? modified,
    math.Rectangle? bounds,
    double? zoomLevel,
    Vector2? panOffset,
  });

  /// Converts the automaton to a JSON representation
  Map<String, dynamic> toJson();

  /// Creates an automaton from a JSON representation
  static Automaton fromJson(Map<String, dynamic> json) {
    final type = json['type'] as String;

    switch (type) {
      case 'FSA':
        return FSA.fromJson(json);
      case 'PDA':
        return PDA.fromJson(json);
      case 'TM':
        return TM.fromJson(json);
      default:
        throw ArgumentError('Unknown automaton type: $type');
    }
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Automaton &&
        other.id == id &&
        other.name == name &&
        other.type == type;
  }

  @override
  int get hashCode {
    return Object.hash(id, name, type);
  }

  @override
  String toString() {
    return 'Automaton(id: $id, name: $name, type: $type, states: ${states.length}, transitions: ${transitions.length})';
  }

  /// Validates the automaton properties
  List<String> validate() {
    final errors = <String>[];

    if (id.isEmpty) {
      errors.add('Automaton ID cannot be empty');
    }

    if (name.isEmpty) {
      errors.add('Automaton name cannot be empty');
    }

    if (states.isEmpty) {
      errors.add('Automaton must have at least one state');
    }

    if (initialState != null && !states.contains(initialState)) {
      errors.add('Initial state must be in the states set');
    }

    for (final acceptingState in acceptingStates) {
      if (!states.contains(acceptingState)) {
        errors.add(
          'Accepting state ${acceptingState.id} must be in the states set',
        );
      }
    }

    for (final transition in transitions) {
      if (!states.contains(transition.fromState)) {
        errors.add('Transition ${transition.id} references invalid fromState');
      }
      if (!states.contains(transition.toState)) {
        errors.add('Transition ${transition.id} references invalid toState');
      }
    }

    if (zoomLevel < 0.5 || zoomLevel > 3.0) {
      errors.add('Zoom level must be between 0.5 and 3.0');
    }

    return errors;
  }

  /// Checks if the automaton is valid
  bool get isValid => validate().isEmpty;

  /// Gets the number of states
  int get stateCount => states.length;

  /// Gets the number of transitions
  int get transitionCount => transitions.length;

  /// Gets the number of accepting states
  int get acceptingStateCount => acceptingStates.length;

  /// Checks if the automaton has an initial state
  bool get hasInitialState => initialState != null;

  /// Checks if the automaton has accepting states
  bool get hasAcceptingStates => acceptingStates.isNotEmpty;

  /// Gets all states that are not accepting
  Set<State> get nonAcceptingStates {
    return states.where((state) => !acceptingStates.contains(state)).toSet();
  }

  /// Gets all states that are not initial
  Set<State> get nonInitialStates {
    return states.where((state) => state != initialState).toSet();
  }

  /// Gets all transitions from a specific state
  Set<Transition> getTransitionsFrom(State state) {
    return transitions.where((t) => t.fromState == state).toSet();
  }

  /// Gets all transitions to a specific state
  Set<Transition> getTransitionsTo(State state) {
    return transitions.where((t) => t.toState == state).toSet();
  }

  /// Gets all transitions between two states
  Set<Transition> getTransitionsBetween(State from, State to) {
    return transitions
        .where((t) => t.fromState == from && t.toState == to)
        .toSet();
  }

  /// Gets all states reachable from a given state
  Set<State> getReachableStates(State startState) {
    final reachable = <State>{startState};
    final queue = Queue<State>()..add(startState);

    while (queue.isNotEmpty) {
      final current = queue.removeFirst();
      final outgoingTransitions = getTransitionsFrom(current);

      for (final transition in outgoingTransitions) {
        if (!reachable.contains(transition.toState)) {
          reachable.add(transition.toState);
          queue.add(transition.toState);
        }
      }
    }

    return reachable;
  }

  /// Gets all states that can reach a given state
  Set<State> getStatesReaching(State targetState) {
    final reaching = <State>{targetState};
    final queue = Queue<State>()..add(targetState);

    while (queue.isNotEmpty) {
      final current = queue.removeFirst();
      final incomingTransitions = getTransitionsTo(current);

      for (final transition in incomingTransitions) {
        if (!reaching.contains(transition.fromState)) {
          reaching.add(transition.fromState);
          queue.add(transition.fromState);
        }
      }
    }

    return reaching;
  }

  /// Checks if a state is reachable from the initial state
  bool isStateReachable(State state) {
    if (initialState == null) return false;
    return getReachableStates(initialState!).contains(state);
  }

  /// Gets all unreachable states
  Set<State> get unreachableStates {
    if (initialState == null) return states;
    final reachable = getReachableStates(initialState!);
    return states.where((state) => !reachable.contains(state)).toSet();
  }

  /// Gets all dead states (states that cannot reach any accepting state)
  Set<State> get deadStates {
    final dead = <State>{};

    for (final state in states) {
      final reachable = getReachableStates(state);
      final canReachAccepting =
          reachable.intersection(acceptingStates).isNotEmpty;
      if (!canReachAccepting) {
        dead.add(state);
      }
    }

    return dead;
  }

  /// Calculates the center point of all states
  Vector2 get centerPoint {
    if (states.isEmpty) return Vector2.zero();

    double sumX = 0;
    double sumY = 0;

    for (final state in states) {
      sumX += state.position.x;
      sumY += state.position.y;
    }

    return Vector2(sumX / states.length, sumY / states.length);
  }

  /// Calculates the bounding box of all states
  math.Rectangle get statesBoundingBox {
    if (states.isEmpty) return const math.Rectangle(0, 0, 0, 0);

    double minX = double.infinity;
    double minY = double.infinity;
    double maxX = double.negativeInfinity;
    double maxY = double.negativeInfinity;

    for (final state in states) {
      minX = minX < state.position.x ? minX : state.position.x;
      minY = minY < state.position.y ? minY : state.position.y;
      maxX = maxX > state.position.x ? maxX : state.position.x;
      maxY = maxY > state.position.y ? maxY : state.position.y;
    }

    return math.Rectangle(minX, minY, maxX - minX, maxY - minY);
  }

  /// Checks if the automaton is empty (no accepting states or no reachable accepting states)
  bool get isEmpty {
    if (acceptingStates.isEmpty) return true;
    if (initialState == null) return true;
    final reachable = getReachableStates(initialState!);
    return reachable.intersection(acceptingStates).isEmpty;
  }

  /// Checks if the automaton accepts all strings (universal language)
  bool get isUniversal {
    if (initialState == null) return false;
    final reachable = getReachableStates(initialState!);
    return reachable.every((state) => acceptingStates.contains(state));
  }
}

/// Types of automata
enum AutomatonType {
  /// Finite State Automaton
  fsa,

  /// Pushdown Automaton
  pda,

  /// Turing Machine
  tm,
}

/// Extension methods for AutomatonType
extension AutomatonTypeExtension on AutomatonType {
  /// Returns a human-readable description of the automaton type
  String get description {
    switch (this) {
      case AutomatonType.fsa:
        return 'Finite State Automaton';
      case AutomatonType.pda:
        return 'Pushdown Automaton';
      case AutomatonType.tm:
        return 'Turing Machine';
    }
  }

  /// Returns the short name of the automaton type
  String get shortName {
    switch (this) {
      case AutomatonType.fsa:
        return 'FSA';
      case AutomatonType.pda:
        return 'PDA';
      case AutomatonType.tm:
        return 'TM';
    }
  }

  /// Returns whether this automaton type supports stack operations
  bool get hasStack {
    return this == AutomatonType.pda;
  }

  /// Returns whether this automaton type supports tape operations
  bool get hasTape {
    return this == AutomatonType.tm;
  }

  /// Returns whether this automaton type supports output
  bool get hasOutput {
    return this == AutomatonType.tm;
  }
}
