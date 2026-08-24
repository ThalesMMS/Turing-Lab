//
//  fsa_transition.dart
//  Turing Lab
//
//  Finite-automaton transition model that extends Transition and adds input
//  symbol control, epsilon support, and its own serialization. Computes
//  labels and types automatically from the given symbols and validates
//  illegal combinations to keep editor-managed machines consistent.
//
//  Thales Matheus Mendonça Santos - October 2025
//
import 'package:vector_math/vector_math_64.dart';
import 'serialized_state_resolver.dart';
import 'state.dart';
import 'transition.dart';
import '../utils/epsilon_utils.dart';

/// Transition for Finite State Automata (FSA)
class FSATransition extends Transition {
  /// Set of input symbols that trigger this transition (unmodifiable)
  final Set<String> inputSymbols;

  /// Lambda symbol for epsilon transitions (null if not an epsilon transition)
  final String? lambdaSymbol;

  /// Primary symbol for this transition (first symbol from inputSymbols or lambdaSymbol)
  @override
  String get symbol {
    if (lambdaSymbol != null) return lambdaSymbol!;
    return inputSymbols.isNotEmpty ? inputSymbols.first : '';
  }

  FSATransition({
    required super.id,
    required super.fromState,
    required super.toState,
    String? label,
    super.controlPoint,
    TransitionType? type,
    Set<String>? inputSymbols,
    this.lambdaSymbol,
    String? symbol,
  })  : inputSymbols = Set<String>.unmodifiable(
          (inputSymbols ??
                  (symbol != null ? <String>{symbol} : const <String>{}))
              .toSet(),
        ),
        super(
          label: label ??
              (lambdaSymbol != null
                  ? 'ε'
                  : (symbol ??
                      ((inputSymbols != null && inputSymbols.isNotEmpty)
                          ? inputSymbols.join(',')
                          : ''))),
          type: type ??
              (() {
                if (lambdaSymbol != null) return TransitionType.epsilon;
                final count =
                    (inputSymbols ?? (symbol != null ? {symbol} : {})).length;
                return count <= 1
                    ? TransitionType.deterministic
                    : TransitionType.nondeterministic;
              }()),
        );

  static const Object _unset = Object();

  /// Creates a copy of this FSA transition with updated properties.
  ///
  /// [lambdaSymbol] uses a sentinel default so that explicitly passing null
  /// clears the epsilon marker (turning the transition into a symbol
  /// transition), while omitting the argument keeps the current value.
  @override
  FSATransition copyWith({
    String? id,
    State? fromState,
    State? toState,
    String? label,
    Vector2? controlPoint,
    TransitionType? type,
    Set<String>? inputSymbols,
    Object? lambdaSymbol = _unset,
  }) {
    final resolvedLambda =
        lambdaSymbol == _unset ? this.lambdaSymbol : lambdaSymbol as String?;
    final resolvedSymbols = inputSymbols != null
        ? Set<String>.unmodifiable(inputSymbols)
        : this.inputSymbols;
    final symbolsChanged = inputSymbols != null || lambdaSymbol != _unset;
    return FSATransition(
      id: id ?? this.id,
      fromState: fromState ?? this.fromState,
      toState: toState ?? this.toState,
      label: label ?? this.label,
      controlPoint: controlPoint ?? this.controlPoint,
      // When the symbol content changes, derive the type from it again so a
      // cleared lambda stops reporting TransitionType.epsilon.
      type: type ??
          (symbolsChanged
              ? (resolvedLambda != null
                  ? TransitionType.epsilon
                  : resolvedSymbols.length <= 1
                      ? TransitionType.deterministic
                      : TransitionType.nondeterministic)
              : this.type),
      inputSymbols: resolvedSymbols,
      lambdaSymbol: resolvedLambda,
    );
  }

  /// Converts the FSA transition to a JSON representation
  @override
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'fromState': fromState.id,
      'toState': toState.id,
      'label': label,
      'controlPoint': {'x': controlPoint.x, 'y': controlPoint.y},
      'type': type.name,
      'transitionType': 'fsa',
      'inputSymbols': inputSymbols.toList(),
      'lambdaSymbol': lambdaSymbol,
    };
  }

  /// Creates an FSA transition from a JSON representation
  factory FSATransition.fromJson(
    Map<String, dynamic> json, {
    Map<String, State>? statesById,
  }) {
    final controlPointData =
        (json['controlPoint'] as Map?)?.cast<String, dynamic>();
    final controlPointX = (controlPointData?['x'] as num?)?.toDouble() ?? 0.0;
    final controlPointY = (controlPointData?['y'] as num?)?.toDouble() ?? 0.0;

    return FSATransition(
      id: json['id'] as String,
      fromState: resolveSerializedState(
        json['fromState'],
        statesById,
        'fromState',
        'FSA',
      ),
      toState: resolveSerializedState(
        json['toState'],
        statesById,
        'toState',
        'FSA',
      ),
      label: json['label'] as String,
      controlPoint: Vector2(controlPointX, controlPointY),
      type: TransitionType.values.firstWhere(
        (e) => e.name == json['type'],
        orElse: () => TransitionType.deterministic,
      ),
      inputSymbols: Set<String>.from(json['inputSymbols'] as List),
      lambdaSymbol: json['lambdaSymbol'] as String?,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is FSATransition &&
        super == other &&
        other.inputSymbols == inputSymbols &&
        other.lambdaSymbol == lambdaSymbol;
  }

  @override
  int get hashCode {
    return Object.hash(super.hashCode, inputSymbols, lambdaSymbol);
  }

  @override
  String toString() {
    return 'FSATransition(id: $id, fromState: ${fromState.id}, toState: ${toState.id}, '
        'inputSymbols: $inputSymbols, lambdaSymbol: $lambdaSymbol)';
  }

  /// Validates the FSA transition properties
  @override
  List<String> validate() {
    final errors = super.validate();

    if (inputSymbols.isEmpty && lambdaSymbol == null) {
      errors.add(
        'FSA transition must have input symbols or be an epsilon transition',
      );
    }

    if (lambdaSymbol != null && inputSymbols.isNotEmpty) {
      errors.add(
        'FSA transition cannot have both input symbols and lambda symbol',
      );
    }

    if (lambdaSymbol != null && lambdaSymbol!.isEmpty) {
      errors.add('Lambda symbol cannot be empty');
    }

    for (final symbol in inputSymbols) {
      if (symbol.isEmpty) {
        errors.add('Input symbol cannot be empty');
      }
    }

    return errors;
  }

  /// Checks if this is an epsilon transition
  bool get isEpsilonTransition =>
      lambdaSymbol != null || inputSymbols.any(isEpsilonSymbol);

  /// Checks if this transition accepts the given symbol
  bool acceptsSymbol(String symbol) {
    return isEpsilonSymbol(symbol)
        ? isEpsilonTransition
        : inputSymbols.contains(symbol);
  }

  /// Checks if this transition accepts any of the given symbols
  bool acceptsAnySymbol(Set<String> symbols) {
    return symbols.any(acceptsSymbol);
  }

  /// Gets all symbols that this transition accepts
  Set<String> get acceptedSymbols {
    return {
      for (final symbol in inputSymbols)
        if (isEpsilonSymbol(symbol)) kEpsilonSymbol else symbol,
      if (lambdaSymbol != null) kEpsilonSymbol,
    };
  }

  /// Checks if this transition is deterministic
  bool get isDeterministic {
    return inputSymbols.length == 1 && lambdaSymbol == null;
  }

  /// Checks if this transition is non-deterministic
  bool get isNondeterministic {
    return inputSymbols.length > 1 || isEpsilonTransition;
  }

  /// Creates an epsilon transition
  factory FSATransition.epsilon({
    required String id,
    required State fromState,
    required State toState,
    String? label,
    Vector2? controlPoint,
  }) {
    return FSATransition(
      id: id,
      fromState: fromState,
      toState: toState,
      label: label ?? 'ε',
      controlPoint: controlPoint ?? Vector2.zero(),
      type: TransitionType.epsilon,
      inputSymbols: const {},
      lambdaSymbol: 'ε',
    );
  }

  /// Creates a deterministic transition
  factory FSATransition.deterministic({
    required String id,
    required State fromState,
    required State toState,
    required String symbol,
    String? label,
    Vector2? controlPoint,
  }) {
    return FSATransition(
      id: id,
      fromState: fromState,
      toState: toState,
      label: label ?? symbol,
      controlPoint: controlPoint ?? Vector2.zero(),
      type: TransitionType.deterministic,
      inputSymbols: {symbol},
      lambdaSymbol: null,
    );
  }

  /// Creates a non-deterministic transition
  factory FSATransition.nondeterministic({
    required String id,
    required State fromState,
    required State toState,
    required Set<String> symbols,
    String? label,
    Vector2? controlPoint,
  }) {
    return FSATransition(
      id: id,
      fromState: fromState,
      toState: toState,
      label: label ?? symbols.join(','),
      controlPoint: controlPoint ?? Vector2.zero(),
      type: TransitionType.nondeterministic,
      inputSymbols: symbols,
      lambdaSymbol: null,
    );
  }
}
