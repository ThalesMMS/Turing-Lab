//
//  tm_transition.dart
//  Turing Lab
//
//  Modela transições de Máquinas de Turing incluindo leitura, escrita, direção
//  de movimento e metadados de fita única.
//  Suporta clonagem, serialização e validações que asseguram símbolos válidos e
//  movimentos coerentes com a definição da máquina.
//
//  Thales Matheus Mendonça Santos - October 2025
//
import 'package:vector_math/vector_math_64.dart';
import 'serialized_state_resolver.dart';
import 'state.dart';
import 'transition.dart';

/// Transition for Turing Machines (TM)
class TMTransition extends Transition {
  /// Formats the canonical label shown for a TM transition.
  static String formatLabel({
    required String readSymbol,
    required String writeSymbol,
    required TapeDirection? direction,
  }) {
    final directionSymbol = direction?.symbol ?? '';
    final read = readSymbol.isEmpty ? '∅' : readSymbol;
    final write = writeSymbol.isEmpty ? '∅' : writeSymbol;
    final suffix = directionSymbol.isEmpty ? '' : ',$directionSymbol';
    return '$read/$write$suffix';
  }

  /// Symbol to read from the tape
  final String readSymbol;

  /// Symbol to write to the tape
  final String writeSymbol;

  /// Direction to move the tape head
  final TapeDirection direction;

  /// Tape number (always 0 for single-tape TM)
  final int tapeNumber;

  /// Head position (alias for direction)
  TapeDirection get headPosition => direction;

  TMTransition({
    required super.id,
    required super.fromState,
    required super.toState,
    required super.label,
    super.controlPoint,
    super.type,
    required this.readSymbol,
    required this.writeSymbol,
    required this.direction,
    this.tapeNumber = 0, // Always 0 for single-tape TM
  });

  /// Creates a copy of this TM transition with updated properties
  @override
  TMTransition copyWith({
    String? id,
    State? fromState,
    State? toState,
    String? label,
    Vector2? controlPoint,
    TransitionType? type,
    String? readSymbol,
    String? writeSymbol,
    TapeDirection? direction,
    int? tapeNumber,
  }) {
    return TMTransition(
      id: id ?? this.id,
      fromState: fromState ?? this.fromState,
      toState: toState ?? this.toState,
      label: label ?? this.label,
      controlPoint: controlPoint ?? this.controlPoint,
      type: type ?? this.type,
      readSymbol: readSymbol ?? this.readSymbol,
      writeSymbol: writeSymbol ?? this.writeSymbol,
      direction: direction ?? this.direction,
      tapeNumber: tapeNumber ?? this.tapeNumber,
    );
  }

  /// Converts the TM transition to a JSON representation
  @override
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'fromState': fromState.id,
      'toState': toState.id,
      'label': label,
      'controlPoint': {'x': controlPoint.x, 'y': controlPoint.y},
      'type': type.name,
      'transitionType': 'tm',
      'readSymbol': readSymbol,
      'writeSymbol': writeSymbol,
      'direction': direction.name,
      'tapeNumber': tapeNumber,
    };
  }

  /// Creates a TM transition from a JSON representation
  factory TMTransition.fromJson(
    Map<String, dynamic> json, {
    Map<String, State>? statesById,
  }) {
    final controlPointData =
        (json['controlPoint'] as Map?)?.cast<String, dynamic>();
    final controlPointX = (controlPointData?['x'] as num?)?.toDouble() ?? 0.0;
    final controlPointY = (controlPointData?['y'] as num?)?.toDouble() ?? 0.0;

    return TMTransition(
      id: json['id'] as String,
      fromState: resolveSerializedState(
        json['fromState'],
        statesById,
        'fromState',
        'TM',
      ),
      toState: resolveSerializedState(
        json['toState'],
        statesById,
        'toState',
        'TM',
      ),
      label: json['label'] as String,
      controlPoint: Vector2(controlPointX, controlPointY),
      type: TransitionType.values.firstWhere(
        (e) => e.name == json['type'],
        orElse: () => TransitionType.deterministic,
      ),
      readSymbol: json['readSymbol'] as String,
      writeSymbol: json['writeSymbol'] as String,
      direction: TapeDirection.values.firstWhere(
        (e) => e.name == json['direction'],
        orElse: () => TapeDirection.right,
      ),
      tapeNumber: json['tapeNumber'] as int? ?? 0,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is TMTransition &&
        super == other &&
        other.readSymbol == readSymbol &&
        other.writeSymbol == writeSymbol &&
        other.direction == direction &&
        other.tapeNumber == tapeNumber;
  }

  @override
  int get hashCode {
    return Object.hash(
      super.hashCode,
      readSymbol,
      writeSymbol,
      direction,
      tapeNumber,
    );
  }

  @override
  String toString() {
    return 'TMTransition(id: $id, fromState: ${fromState.id}, toState: ${toState.id}, '
        'read: $readSymbol, write: $writeSymbol, direction: $direction, tape: $tapeNumber)';
  }

  /// Validates the TM transition properties
  @override
  List<String> validate() {
    final errors = super.validate();

    if (readSymbol.isEmpty) {
      errors.add('TM transition must have read symbol');
    }

    if (writeSymbol.isEmpty) {
      errors.add('TM transition must have write symbol');
    }

    if (tapeNumber < 0) {
      errors.add('TM transition tape number must be non-negative');
    }

    return errors;
  }

  /// Checks if this transition can read the given symbol
  bool canRead(String symbol) {
    return readSymbol == symbol;
  }

  /// Gets the symbol to write to the tape
  String get symbolToWrite => writeSymbol;

  /// Gets the direction to move the tape head
  TapeDirection get moveDirection => direction;

  /// Checks if this transition moves the tape head left
  bool get movesLeft => direction == TapeDirection.left;

  /// Checks if this transition moves the tape head right
  bool get movesRight => direction == TapeDirection.right;

  /// Checks if this transition keeps the tape head in place
  bool get staysInPlace => direction == TapeDirection.stay;

  /// Creates a transition that reads and writes the same symbol
  factory TMTransition.readWrite({
    required String id,
    required State fromState,
    required State toState,
    required String symbol,
    required TapeDirection direction,
    int tapeNumber = 0,
    String? label,
    Vector2? controlPoint,
  }) {
    return TMTransition(
      id: id,
      fromState: fromState,
      toState: toState,
      label: label ?? '$symbol→$symbol,$direction',
      controlPoint: controlPoint ?? Vector2.zero(),
      type: TransitionType.deterministic,
      readSymbol: symbol,
      writeSymbol: symbol,
      direction: direction,
      tapeNumber: tapeNumber,
    );
  }

  /// Creates a transition that changes the symbol on the tape
  factory TMTransition.changeSymbol({
    required String id,
    required State fromState,
    required State toState,
    required String readSymbol,
    required String writeSymbol,
    required TapeDirection direction,
    int tapeNumber = 0,
    String? label,
    Vector2? controlPoint,
  }) {
    return TMTransition(
      id: id,
      fromState: fromState,
      toState: toState,
      label: label ?? '$readSymbol→$writeSymbol,$direction',
      controlPoint: controlPoint ?? Vector2.zero(),
      type: TransitionType.deterministic,
      readSymbol: readSymbol,
      writeSymbol: writeSymbol,
      direction: direction,
      tapeNumber: tapeNumber,
    );
  }

  /// Creates a transition that only moves the tape head
  factory TMTransition.moveOnly({
    required String id,
    required State fromState,
    required State toState,
    required String symbol,
    required TapeDirection direction,
    int tapeNumber = 0,
    String? label,
    Vector2? controlPoint,
  }) {
    return TMTransition(
      id: id,
      fromState: fromState,
      toState: toState,
      label: label ?? '$symbol→$symbol,$direction',
      controlPoint: controlPoint ?? Vector2.zero(),
      type: TransitionType.deterministic,
      readSymbol: symbol,
      writeSymbol: symbol,
      direction: direction,
      tapeNumber: tapeNumber,
    );
  }
}

/// Direction for tape head movement in Turing machines
enum TapeDirection {
  /// Move tape head left
  left,

  /// Move tape head right
  right,

  /// Keep tape head in place
  stay,
}

/// Extension methods for TapeDirection
extension TapeDirectionExtension on TapeDirection {
  /// Returns a human-readable description of the direction
  String get description {
    switch (this) {
      case TapeDirection.left:
        return 'Left';
      case TapeDirection.right:
        return 'Right';
      case TapeDirection.stay:
        return 'Stay';
    }
  }

  /// Returns the symbol used to represent this direction
  String get symbol {
    switch (this) {
      case TapeDirection.left:
        return 'L';
      case TapeDirection.right:
        return 'R';
      case TapeDirection.stay:
        return 'S';
    }
  }

  /// Returns the opposite direction
  TapeDirection get opposite {
    switch (this) {
      case TapeDirection.left:
        return TapeDirection.right;
      case TapeDirection.right:
        return TapeDirection.left;
      case TapeDirection.stay:
        return TapeDirection.stay;
    }
  }
}
