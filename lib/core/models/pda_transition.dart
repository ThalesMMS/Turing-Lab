//
//  pda_transition.dart
//  Turing Lab
//
//  Representa transições de PDAs, controlando símbolos de leitura, operações de
//  pilha e marcadores lambda para suportar comportamentos não determinísticos.
//  Disponibiliza clonagem, serialização completa e validações rigorosas sobre
//  consistência de símbolos e estados ligados à transição.
//
//  Thales Matheus Mendonça Santos - October 2025
//
import 'package:collection/collection.dart';
import 'package:vector_math/vector_math_64.dart';
import 'serialized_state_resolver.dart';
import 'state.dart';
import 'transition.dart';

/// Transition for Pushdown Automata (PDA)
class PDATransition extends Transition {
  static const _pushSymbolsEquality = ListEquality<String>();

  /// Input symbol that triggers this transition
  final String inputSymbol;

  /// Symbol to pop from the stack
  final String popSymbol;

  /// Symbol to push onto the stack
  final String pushSymbol;

  /// Ordered, atomic symbols pushed by this transition.
  ///
  /// Legacy transitions without this metadata treat each character in
  /// [pushSymbol] as one stack symbol.
  final List<String> pushSymbols;

  /// Whether the input is lambda (epsilon)
  final bool isLambdaInput;

  /// Whether the pop operation is lambda (epsilon)
  final bool isLambdaPop;

  /// Whether the push operation is lambda (epsilon)
  final bool isLambdaPush;

  /// Read symbol (alias for inputSymbol)
  String get readSymbol => inputSymbol;

  /// Stack pop symbol (alias for popSymbol)
  String get stackPop => popSymbol;

  /// Stack push symbol (alias for pushSymbol)
  String get stackPush => pushSymbol;

  PDATransition({
    required super.id,
    required super.fromState,
    required super.toState,
    required super.label,
    super.controlPoint,
    super.type,
    required this.inputSymbol,
    required this.popSymbol,
    required String pushSymbol,
    List<String>? pushSymbols,
    this.isLambdaInput = false,
    this.isLambdaPop = false,
    this.isLambdaPush = false,
  })  : pushSymbol = pushSymbols?.join() ?? pushSymbol,
        pushSymbols = List<String>.unmodifiable(
          pushSymbols ??
              (pushSymbol.isEmpty ? const <String>[] : pushSymbol.split('')),
        );

  /// Creates a copy of this PDA transition with updated properties
  @override
  PDATransition copyWith({
    String? id,
    State? fromState,
    State? toState,
    String? label,
    Vector2? controlPoint,
    TransitionType? type,
    String? inputSymbol,
    String? popSymbol,
    String? pushSymbol,
    List<String>? pushSymbols,
    bool? isLambdaInput,
    bool? isLambdaPop,
    bool? isLambdaPush,
  }) {
    return PDATransition(
      id: id ?? this.id,
      fromState: fromState ?? this.fromState,
      toState: toState ?? this.toState,
      label: label ?? this.label,
      controlPoint: controlPoint ?? this.controlPoint,
      type: type ?? this.type,
      inputSymbol: inputSymbol ?? this.inputSymbol,
      popSymbol: popSymbol ?? this.popSymbol,
      pushSymbol: pushSymbol ?? this.pushSymbol,
      pushSymbols:
          pushSymbols ?? (pushSymbol == null ? this.pushSymbols : null),
      isLambdaInput: isLambdaInput ?? this.isLambdaInput,
      isLambdaPop: isLambdaPop ?? this.isLambdaPop,
      isLambdaPush: isLambdaPush ?? this.isLambdaPush,
    );
  }

  /// Converts the PDA transition to a JSON representation
  @override
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'fromState': fromState.id,
      'toState': toState.id,
      'label': label,
      'controlPoint': {'x': controlPoint.x, 'y': controlPoint.y},
      'type': type.name,
      'transitionType': 'pda',
      'inputSymbol': inputSymbol,
      'popSymbol': popSymbol,
      'pushSymbol': pushSymbol,
      'pushSymbols': pushSymbols,
      'isLambdaInput': isLambdaInput,
      'isLambdaPop': isLambdaPop,
      'isLambdaPush': isLambdaPush,
    };
  }

  /// Creates a PDA transition from a JSON representation
  factory PDATransition.fromJson(
    Map<String, dynamic> json, {
    Map<String, State>? statesById,
  }) {
    final controlPointData =
        (json['controlPoint'] as Map?)?.cast<String, dynamic>();
    final controlPointX = (controlPointData?['x'] as num?)?.toDouble() ?? 0.0;
    final controlPointY = (controlPointData?['y'] as num?)?.toDouble() ?? 0.0;

    return PDATransition(
      id: json['id'] as String,
      fromState: resolveSerializedState(
        json['fromState'],
        statesById,
        'fromState',
        'PDA',
      ),
      toState: resolveSerializedState(
        json['toState'],
        statesById,
        'toState',
        'PDA',
      ),
      label: json['label'] as String,
      controlPoint: Vector2(controlPointX, controlPointY),
      type: TransitionType.values.firstWhere(
        (e) => e.name == json['type'],
        orElse: () => TransitionType.deterministic,
      ),
      inputSymbol: json['inputSymbol'] as String,
      popSymbol: json['popSymbol'] as String,
      pushSymbol: json['pushSymbol'] as String,
      pushSymbols: (json['pushSymbols'] as List?)?.cast<String>(),
      isLambdaInput: json['isLambdaInput'] as bool? ?? false,
      isLambdaPop: json['isLambdaPop'] as bool? ?? false,
      isLambdaPush: json['isLambdaPush'] as bool? ?? false,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is PDATransition &&
        super == other &&
        other.inputSymbol == inputSymbol &&
        other.popSymbol == popSymbol &&
        other.pushSymbol == pushSymbol &&
        _pushSymbolsEquality.equals(other.pushSymbols, pushSymbols) &&
        other.isLambdaInput == isLambdaInput &&
        other.isLambdaPop == isLambdaPop &&
        other.isLambdaPush == isLambdaPush;
  }

  @override
  int get hashCode {
    return Object.hash(
      super.hashCode,
      inputSymbol,
      popSymbol,
      pushSymbol,
      _pushSymbolsEquality.hash(pushSymbols),
      isLambdaInput,
      isLambdaPop,
      isLambdaPush,
    );
  }

  @override
  String toString() {
    return 'PDATransition(id: $id, fromState: ${fromState.id}, toState: ${toState.id}, '
        'input: $inputSymbol, pop: $popSymbol, push: $pushSymbol)';
  }

  /// Validates the PDA transition properties
  @override
  List<String> validate() {
    final errors = super.validate();

    if (inputSymbol.isEmpty && !isLambdaInput) {
      errors.add('PDA transition must have input symbol or be lambda input');
    }

    if (popSymbol.isEmpty && !isLambdaPop) {
      errors.add('PDA transition must have pop symbol or be lambda pop');
    }

    if (pushSymbol.isEmpty && !isLambdaPush) {
      errors.add('PDA transition must have push symbol or be lambda push');
    }

    if (isLambdaInput && inputSymbol.isNotEmpty) {
      errors.add(
        'PDA transition cannot have both input symbol and lambda input',
      );
    }

    if (isLambdaPop && popSymbol.isNotEmpty) {
      errors.add('PDA transition cannot have both pop symbol and lambda pop');
    }

    if (isLambdaPush && pushSymbol.isNotEmpty) {
      errors.add('PDA transition cannot have both push symbol and lambda push');
    }

    if (pushSymbols.any((symbol) => symbol.isEmpty)) {
      errors.add('PDA transition push symbols cannot contain empty values');
    }

    if (pushSymbols.join() != pushSymbol) {
      errors.add('PDA transition push symbols must compose push symbol');
    }

    return errors;
  }

  /// Checks if this transition accepts the given input symbol
  bool acceptsInput(String symbol) {
    return isLambdaInput || inputSymbol == symbol;
  }

  /// Checks if this transition can pop the given symbol from the stack
  bool canPop(String symbol) {
    return isLambdaPop || popSymbol == symbol;
  }

  /// Gets the symbol to push onto the stack (empty string for lambda push)
  String get symbolToPush {
    return isLambdaPush ? '' : pushSymbol;
  }

  /// Gets the symbol to pop from the stack (empty string for lambda pop)
  String get symbolToPop {
    return isLambdaPop ? '' : popSymbol;
  }

  /// Gets the input symbol (empty string for lambda input)
  String get effectiveInputSymbol {
    return isLambdaInput ? '' : inputSymbol;
  }

  /// Checks if this is an epsilon transition (all operations are lambda)
  bool get isEpsilonTransition {
    return isLambdaInput && isLambdaPop && isLambdaPush;
  }

  /// Creates an epsilon transition
  factory PDATransition.epsilon({
    required String id,
    required State fromState,
    required State toState,
    String? label,
    Vector2? controlPoint,
  }) {
    return PDATransition(
      id: id,
      fromState: fromState,
      toState: toState,
      label: label ?? 'ε,ε→ε',
      controlPoint: controlPoint ?? Vector2.zero(),
      type: TransitionType.epsilon,
      inputSymbol: '',
      popSymbol: '',
      pushSymbol: '',
      isLambdaInput: true,
      isLambdaPop: true,
      isLambdaPush: true,
    );
  }

  /// Creates a transition that reads input and pops/pushes stack symbols
  factory PDATransition.readAndStack({
    required String id,
    required State fromState,
    required State toState,
    required String inputSymbol,
    required String popSymbol,
    required String pushSymbol,
    String? label,
    Vector2? controlPoint,
  }) {
    return PDATransition(
      id: id,
      fromState: fromState,
      toState: toState,
      label: label ?? '$inputSymbol,$popSymbol→$pushSymbol',
      controlPoint: controlPoint ?? Vector2.zero(),
      type: TransitionType.deterministic,
      inputSymbol: inputSymbol,
      popSymbol: popSymbol,
      pushSymbol: pushSymbol,
      isLambdaInput: inputSymbol.isEmpty,
      isLambdaPop: popSymbol.isEmpty,
      isLambdaPush: pushSymbol.isEmpty,
    );
  }

  /// Creates a transition that only reads input (no stack operations)
  factory PDATransition.readOnly({
    required String id,
    required State fromState,
    required State toState,
    required String inputSymbol,
    String? label,
    Vector2? controlPoint,
  }) {
    return PDATransition(
      id: id,
      fromState: fromState,
      toState: toState,
      label: label ?? '$inputSymbol,ε→ε',
      controlPoint: controlPoint ?? Vector2.zero(),
      type: TransitionType.deterministic,
      inputSymbol: inputSymbol,
      popSymbol: '',
      pushSymbol: '',
      isLambdaPop: true,
      isLambdaPush: true,
    );
  }

  /// Creates a transition that only operates on the stack (no input)
  factory PDATransition.stackOnly({
    required String id,
    required State fromState,
    required State toState,
    required String popSymbol,
    required String pushSymbol,
    String? label,
    Vector2? controlPoint,
  }) {
    return PDATransition(
      id: id,
      fromState: fromState,
      toState: toState,
      label: label ?? 'ε,$popSymbol→$pushSymbol',
      controlPoint: controlPoint ?? Vector2.zero(),
      type: TransitionType.deterministic,
      inputSymbol: '',
      popSymbol: popSymbol,
      pushSymbol: pushSymbol,
      isLambdaInput: true,
    );
  }
}
