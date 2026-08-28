//
//  fsa.dart
//  Turing Lab
//
//  Defines the Finite Automaton model, inheriting generic infrastructure and
//  adding serialization, copies, and transition- and determinism-specific
//  validations. Facilitates persistence, import, and analysis of machines by
//  standardizing JSON formats, layout parameters, and simulator integrations.
//
//  Thales Matheus Mendonça Santos - October 2025
//
import 'dart:collection';
import 'dart:math' as math;
import 'package:vector_math/vector_math_64.dart';
import 'state.dart';
import 'transition.dart';
import 'fsa_transition.dart';
import 'automaton.dart';
import '../utils/epsilon_utils.dart';

const Object _unset = Object();

/// Finite State Automaton (FSA) implementation
class FSA extends Automaton {
  FSA({
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
    String? description,
  }) : super(type: AutomatonType.fsa);

  /// Creates a copy of this FSA with updated properties
  @override
  FSA copyWith({
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
  }) {
    return FSA(
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
    );
  }

  /// Converts the FSA to a JSON representation
  @override
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'type': 'FSA',
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
    };
  }

  /// Creates an FSA from a JSON representation
  factory FSA.fromJson(Map<String, dynamic> json) {
    final states = (json['states'] as List)
        .map((s) => State.fromJson(s as Map<String, dynamic>))
        .toSet();
    final statesById = {for (final state in states) state.id: state};

    return FSA(
      id: json['id'] as String,
      name: json['name'] as String,
      states: states,
      transitions: (json['transitions'] as List)
          .map(
            (t) => FSATransition.fromJson(
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
      bounds: _parseBounds(json['bounds'] as Map<String, dynamic>),
      zoomLevel: (json['zoomLevel'] as num?)?.toDouble() ?? 1.0,
      panOffset: _parsePanOffset(json['panOffset'] as Map<String, dynamic>?),
    );
  }

  static math.Rectangle<double> _parseBounds(Map<String, dynamic> boundsJson) {
    final x = (boundsJson['x'] as num).toDouble();
    final y = (boundsJson['y'] as num).toDouble();
    final width = (boundsJson['width'] as num).toDouble();
    final height = (boundsJson['height'] as num).toDouble();

    return math.Rectangle<double>(x, y, width, height);
  }

  static Vector2 _parsePanOffset(Map<String, dynamic>? panOffsetJson) {
    if (panOffsetJson == null) {
      return Vector2.zero();
    }

    final x = (panOffsetJson['x'] as num?)?.toDouble() ?? 0.0;
    final y = (panOffsetJson['y'] as num?)?.toDouble() ?? 0.0;

    return Vector2(x, y);
  }

  /// Validates the FSA properties
  @override
  List<String> validate() {
    final errors = super.validate();

    // Validate FSA-specific properties
    for (final transition in transitions) {
      if (transition is! FSATransition) {
        errors.add('FSA can only contain FSA transitions');
      } else {
        final FSATransition fsaTransition = transition;
        final transitionErrors = fsaTransition.validate();
        errors.addAll(
          transitionErrors.map((e) => 'Transition ${fsaTransition.id}: $e'),
        );
      }
    }

    return errors;
  }

  /// Gets all FSA transitions
  Set<FSATransition> get fsaTransitions {
    return transitions.whereType<FSATransition>().toSet();
  }

  /// Gets all epsilon transitions
  Set<FSATransition> get epsilonTransitions {
    return fsaTransitions.where((t) => t.isEpsilonTransition).toSet();
  }

  /// Gets all deterministic transitions
  Set<FSATransition> get deterministicTransitions {
    return fsaTransitions.where((t) => t.isDeterministic).toSet();
  }

  /// Gets all non-deterministic transitions
  Set<FSATransition> get nondeterministicTransitions {
    return fsaTransitions.where((t) => t.isNondeterministic).toSet();
  }

  /// Checks if the FSA is deterministic
  bool get isDeterministic {
    if (nondeterministicTransitions.isNotEmpty) return false;
    if (hasEpsilonTransitions) return false;

    for (final state in states) {
      final outgoingTransitions = getTransitionsFrom(
        state,
      ).whereType<FSATransition>();
      final seenSymbols = <String>{};

      for (final transition in outgoingTransitions) {
        // If it's an epsilon transition (should be caught by hasEpsilonTransitions, but for safety)
        if (transition.isEpsilonTransition) return false;

        for (final symbol in transition.inputSymbols) {
          if (seenSymbols.contains(symbol)) {
            return false;
          }
          seenSymbols.add(symbol);
        }
      }
    }
    return true;
  }

  /// Checks if the FSA is non-deterministic
  bool get isNondeterministic {
    return !isDeterministic;
  }

  /// Checks if the FSA has epsilon transitions
  bool get hasEpsilonTransitions {
    return epsilonTransitions.isNotEmpty;
  }

  /// Checks if the language recognized by this FSA is finite.
  ///
  /// The language is infinite iff a useful strongly connected component
  /// contains a transition that consumes input. Epsilon transitions count for
  /// reachability and may complete a mixed epsilon/symbol cycle, but an
  /// epsilon-only cycle does not make the language infinite.
  bool get isFiniteLanguage {
    if (initialState == null) return true;

    // Build the complete graph. Malformed dangling endpoints are ignored here;
    // [validate] remains responsible for reporting them.
    final adjacency = <State, Set<State>>{};
    final reverse = <State, Set<State>>{};
    for (final state in states) {
      adjacency[state] = <State>{};
      reverse[state] = <State>{};
    }
    for (final transition in fsaTransitions) {
      if (!states.contains(transition.fromState) ||
          !states.contains(transition.toState)) {
        continue;
      }
      adjacency[transition.fromState]!.add(transition.toState);
      reverse[transition.toState]!.add(transition.fromState);
    }

    final reachable = <State>{};
    final queue = Queue<State>();
    reachable.add(initialState!);
    queue.add(initialState!);
    while (queue.isNotEmpty) {
      final state = queue.removeFirst();
      for (final next in adjacency[state] ?? const <State>{}) {
        if (reachable.add(next)) queue.add(next);
      }
    }
    if (reachable.isEmpty) return true;

    final coReach = <State>{...acceptingStates};
    final stack = <State>[...acceptingStates];
    while (stack.isNotEmpty) {
      final state = stack.removeLast();
      for (final previous in reverse[state] ?? const <State>{}) {
        if (coReach.add(previous)) stack.add(previous);
      }
    }

    final useful = states
        .where((s) => reachable.contains(s) && coReach.contains(s))
        .toSet();
    if (useful.isEmpty) return true;

    // Kosaraju's algorithm, written iteratively so a large imported automaton
    // cannot exhaust the call stack during a model query.
    final visited = <State>{};
    final finishOrder = <State>[];
    for (final start in useful) {
      if (!visited.add(start)) continue;
      final traversal = <(State, bool)>[(start, false)];
      while (traversal.isNotEmpty) {
        final (state, expanded) = traversal.removeLast();
        if (expanded) {
          finishOrder.add(state);
          continue;
        }
        traversal.add((state, true));
        for (final next
            in (adjacency[state] ?? const <State>{}).where(useful.contains)) {
          if (visited.add(next)) traversal.add((next, false));
        }
      }
    }

    final assigned = <State>{};
    for (final start in finishOrder.reversed) {
      if (!assigned.add(start)) continue;
      final component = <State>{start};
      final pending = <State>[start];
      while (pending.isNotEmpty) {
        final state = pending.removeLast();
        for (final previous
            in (reverse[state] ?? const <State>{}).where(useful.contains)) {
          if (assigned.add(previous)) {
            component.add(previous);
            pending.add(previous);
          }
        }
      }
      final hasConsumingCycle = fsaTransitions.any(
        (transition) =>
            transition.consumesInput &&
            component.contains(transition.fromState) &&
            component.contains(transition.toState),
      );
      if (hasConsumingCycle) return false;
    }

    return true;
  }

  /// Gets all transitions from a state that accept a specific symbol
  Set<FSATransition> getTransitionsFromStateOnSymbol(
    State state,
    String symbol,
  ) {
    return fsaTransitions
        .where((t) => t.fromState == state && t.acceptsSymbol(symbol))
        .toSet();
  }

  /// Gets all epsilon transitions from a state
  Set<FSATransition> getEpsilonTransitionsFromState(State state) {
    return fsaTransitions
        .where((t) => t.fromState == state && t.isEpsilonTransition)
        .toSet();
  }

  /// Gets the epsilon closure of a state
  Set<State> getEpsilonClosure(State state) {
    return getEpsilonClosureOfSet({state});
  }

  /// Gets the epsilon closure of a set of states
  Set<State> getEpsilonClosureOfSet(Set<State> states) {
    return computeEpsilonClosure(
      states,
      (state) => getEpsilonTransitionsFromState(
        state,
      ).map((transition) => transition.toState),
    );
  }

  /// Gets all states reachable from a state on a specific symbol
  Set<State> getStatesReachableOnSymbol(State state, String symbol) {
    final reachable = <State>{};
    final transitions = getTransitionsFromStateOnSymbol(state, symbol);

    for (final transition in transitions) {
      reachable.add(transition.toState);
    }

    return reachable;
  }

  /// Gets all states reachable from a set of states on a specific symbol
  Set<State> getStatesReachableOnSymbolFromSet(
    Set<State> states,
    String symbol,
  ) {
    final reachable = <State>{};

    for (final state in states) {
      reachable.addAll(getStatesReachableOnSymbol(state, symbol));
    }

    return reachable;
  }

  /// Creates an empty FSA
  factory FSA.empty({
    required String id,
    required String name,
    math.Rectangle? bounds,
  }) {
    final now = DateTime.now();
    return FSA(
      id: id,
      name: name,
      states: {},
      transitions: {},
      alphabet: {},
      acceptingStates: {},
      created: now,
      modified: now,
      bounds: bounds ?? const math.Rectangle(0, 0, 800, 600),
    );
  }

  /// Creates a simple FSA with one state
  factory FSA.singleState({
    required String id,
    required String name,
    required String stateId,
    required String stateLabel,
    required Vector2 position,
    bool isInitial = false,
    bool isAccepting = false,
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

    return FSA(
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
    );
  }

  /// Creates a simple FSA with two states and one transition
  factory FSA.twoState({
    required String id,
    required String name,
    required String fromStateId,
    required String toStateId,
    required String symbol,
    required Vector2 fromPosition,
    required Vector2 toPosition,
    bool toStateAccepting = true,
    math.Rectangle? bounds,
  }) {
    final now = DateTime.now();
    final fromState = State(
      id: fromStateId,
      label: fromStateId,
      position: fromPosition,
      isInitial: true,
      isAccepting: false,
    );
    final toState = State(
      id: toStateId,
      label: toStateId,
      position: toPosition,
      isInitial: false,
      isAccepting: toStateAccepting,
    );

    final transition = FSATransition.deterministic(
      id: 't1',
      fromState: fromState,
      toState: toState,
      symbol: symbol,
    );

    return FSA(
      id: id,
      name: name,
      states: {fromState, toState},
      transitions: {transition},
      alphabet: {symbol},
      initialState: fromState,
      acceptingStates: toStateAccepting ? {toState} : {},
      created: now,
      modified: now,
      bounds: bounds ?? const math.Rectangle(0, 0, 800, 600),
    );
  }
}
