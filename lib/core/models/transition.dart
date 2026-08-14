//
//  transition.dart
//  Turing Lab
//
//  Fornece a abstração base para transições de autômatos, centralizando campos
//  comuns, operações de clonagem e utilidades de serialização dinâmica.
//  Também agrega validações geométricas e auxiliares de cálculo utilizados por
//  renderizadores e algoritmos que manipulam arcos no canvas.
//
//  Thales Matheus Mendonça Santos - October 2025
//
import 'dart:math' as math;
import 'package:vector_math/vector_math_64.dart';
import 'state.dart';
import 'fsa_transition.dart';
import 'pda_transition.dart';
import 'tm_transition.dart';

/// Abstract base class for transitions in an automaton
abstract class Transition {
  /// Unique identifier for the transition within the automaton
  final String id;

  /// Source state of the transition
  final State fromState;

  /// Destination state of the transition
  final State toState;

  /// Display label for the transition
  final String label;

  /// Control point for curved transitions on mobile
  final Vector2 controlPoint;

  /// Type of the transition (deterministic, nondeterministic)
  final TransitionType type;

  /// Primary symbol for this transition (to be overridden by subclasses)
  String get symbol => label;

  Transition({
    required this.id,
    required this.fromState,
    required this.toState,
    required this.label,
    Vector2? controlPoint,
    this.type = TransitionType.deterministic,
  }) : controlPoint = (controlPoint ?? Vector2.zero()).clone();

  /// Creates a copy of this transition with updated properties
  Transition copyWith({
    String? id,
    State? fromState,
    State? toState,
    String? label,
    Vector2? controlPoint,
    TransitionType? type,
  });

  /// Converts the transition to a JSON representation
  Map<String, dynamic> toJson();

  /// Creates a transition from a JSON representation
  static Transition fromJson(
    Map<String, dynamic> json, {
    Map<String, State>? statesById,
  }) {
    final type = json['transitionType'] as String? ?? 'fsa';

    switch (type) {
      case 'fsa':
        return FSATransition.fromJson(json, statesById: statesById);
      case 'pda':
        return PDATransition.fromJson(json, statesById: statesById);
      case 'tm':
        return TMTransition.fromJson(json, statesById: statesById);
      default:
        throw ArgumentError('Unknown transition type: $type');
    }
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Transition &&
        other.id == id &&
        other.fromState == fromState &&
        other.toState == toState &&
        other.label == label &&
        other.controlPoint == controlPoint &&
        other.type == type;
  }

  @override
  int get hashCode {
    return Object.hash(id, fromState, toState, label, controlPoint, type);
  }

  @override
  String toString() {
    return 'Transition(id: $id, fromState: ${fromState.id}, toState: ${toState.id}, '
        'label: $label, type: $type)';
  }

  /// Validates the transition properties
  List<String> validate() {
    final errors = <String>[];

    if (id.isEmpty) {
      errors.add('Transition ID cannot be empty');
    }

    if (label.isEmpty) {
      errors.add('Transition label cannot be empty');
    }

    if (fromState == toState && controlPoint == Vector2.zero()) {
      errors.add('Self-loop transitions must have a control point');
    }

    return errors;
  }

  /// Checks if this transition is a self-loop
  bool get isSelfLoop => fromState == toState;

  /// Calculates the length of the transition arc
  double get arcLength {
    if (isSelfLoop) {
      return 2 * 3.14159 * 20; // Approximate circumference of self-loop
    }
    return fromState.position.distanceTo(toState.position);
  }

  /// Gets the midpoint of the transition
  Vector2 get midpoint {
    if (isSelfLoop) {
      return fromState.position + Vector2(20, 0); // Offset for self-loop
    }
    return (fromState.position + toState.position) / 2;
  }

  /// Gets the angle of the transition
  double get angle {
    final direction = toState.position - fromState.position;
    return math.atan2(direction.y, direction.x);
  }
}

/// Types of transitions
enum TransitionType {
  /// Deterministic transition
  deterministic,

  /// Non-deterministic transition
  nondeterministic,

  /// Epsilon/lambda transition
  epsilon,
}

/// Extension methods for TransitionType
extension TransitionTypeExtension on TransitionType {
  /// Returns a human-readable description of the transition type
  String get description {
    switch (this) {
      case TransitionType.deterministic:
        return 'Deterministic transition';
      case TransitionType.nondeterministic:
        return 'Non-deterministic transition';
      case TransitionType.epsilon:
        return 'Epsilon transition';
    }
  }

  /// Returns whether this transition type allows multiple symbols
  bool get allowsMultipleSymbols {
    return this == TransitionType.nondeterministic;
  }
}
