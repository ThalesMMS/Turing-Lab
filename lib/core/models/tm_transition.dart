//
//  tm_transition.dart
//  Turing Lab
//
//  Models Turing-machine transitions including read, write, move direction,
//  and single-tape metadata. Supports cloning, serialization, and
//  validations that ensure valid symbols and moves consistent with the
//  machine definition.
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

  static String formatVectorLabel({
    required List<String> readSymbols,
    required List<String> writeSymbols,
    required List<TapeDirection> directions,
  }) {
    if (readSymbols.length != writeSymbols.length ||
        readSymbols.length != directions.length) {
      throw ArgumentError('TM operation vectors must have equal lengths.');
    }
    if (readSymbols.length == 1) {
      return formatLabel(
        readSymbol: readSymbols.single,
        writeSymbol: writeSymbols.single,
        direction: directions.single,
      );
    }
    return List<String>.generate(
      readSymbols.length,
      (tape) => 'T${tape + 1}: ${formatLabel(
        readSymbol: readSymbols[tape],
        writeSymbol: writeSymbols[tape],
        direction: directions[tape],
      )}',
      growable: false,
    ).join(' | ');
  }

  /// Ordered symbols read atomically, one for each tape.
  final List<String> readSymbols;

  /// Ordered symbols written atomically, one for each tape.
  final List<String> writeSymbols;

  /// Ordered head movements applied atomically, one for each tape.
  final List<TapeDirection> directions;

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
    String? readSymbol,
    String? writeSymbol,
    TapeDirection? direction,
    Iterable<String>? readSymbols,
    Iterable<String>? writeSymbols,
    Iterable<TapeDirection>? directions,
    this.tapeNumber = 0, // Always 0 for single-tape TM
  })  : readSymbols = List<String>.unmodifiable(
          readSymbols ?? <String>[readSymbol ?? ''],
        ),
        writeSymbols = List<String>.unmodifiable(
          writeSymbols ?? <String>[writeSymbol ?? ''],
        ),
        directions = List<TapeDirection>.unmodifiable(
          directions ?? <TapeDirection>[direction ?? TapeDirection.stay],
        ) {
    if (this.readSymbols.length != this.writeSymbols.length ||
        this.readSymbols.length != this.directions.length) {
      throw ArgumentError(
        'TM transition read, write, and direction vectors must have equal lengths.',
      );
    }
    if (this.readSymbols.isEmpty) {
      throw ArgumentError('TM transition vectors must not be empty.');
    }
  }

  /// Legacy scalar view for the selected tape operation.
  String get readSymbol => readSymbols[_legacyIndex];

  /// Legacy scalar view for the selected tape operation.
  String get writeSymbol => writeSymbols[_legacyIndex];

  /// Legacy scalar view for the selected tape operation.
  TapeDirection get direction => directions[_legacyIndex];

  int get _legacyIndex =>
      tapeNumber >= 0 && tapeNumber < readSymbols.length ? tapeNumber : 0;

  int get operationCount => readSymbols.length;

  /// Resolves the pre-vector legacy representation into one operation per
  /// tape. Legacy transitions addressed one tape by [tapeNumber]; all other
  /// tapes now explicitly read/write blank and stay in place.
  ({
    List<String> readSymbols,
    List<String> writeSymbols,
    List<TapeDirection> directions,
  }) operationsForTapeCount(int tapeCount, String blankSymbol) {
    if (operationCount == tapeCount) {
      return (
        readSymbols: readSymbols,
        writeSymbols: writeSymbols,
        directions: directions,
      );
    }
    if (operationCount != 1 || tapeNumber < 0 || tapeNumber >= tapeCount) {
      throw ArgumentError(
        'TM transition vectors must match the machine tape count.',
      );
    }
    final reads = List<String>.filled(tapeCount, blankSymbol);
    final writes = List<String>.filled(tapeCount, blankSymbol);
    final moves = List<TapeDirection>.filled(tapeCount, TapeDirection.stay);
    reads[tapeNumber] = readSymbols.single;
    writes[tapeNumber] = writeSymbols.single;
    moves[tapeNumber] = directions.single;
    return (
      readSymbols: List<String>.unmodifiable(reads),
      writeSymbols: List<String>.unmodifiable(writes),
      directions: List<TapeDirection>.unmodifiable(moves),
    );
  }

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
    Iterable<String>? readSymbols,
    Iterable<String>? writeSymbols,
    Iterable<TapeDirection>? directions,
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
      readSymbols: readSymbols ??
          (readSymbol == null
              ? this.readSymbols
              : _replaceAt(this.readSymbols, _legacyIndex, readSymbol)),
      writeSymbols: writeSymbols ??
          (writeSymbol == null
              ? this.writeSymbols
              : _replaceAt(this.writeSymbols, _legacyIndex, writeSymbol)),
      directions: directions ??
          (direction == null
              ? this.directions
              : _replaceAt(this.directions, _legacyIndex, direction)),
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
      'readSymbols': readSymbols,
      'writeSymbols': writeSymbols,
      'directions': directions.map((value) => value.name).toList(),
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
      readSymbol: json['readSymbol'] as String?,
      writeSymbol: json['writeSymbol'] as String?,
      direction: _directionFromName(json['direction'] as String?),
      readSymbols: (json['readSymbols'] as List?)?.cast<String>(),
      writeSymbols: (json['writeSymbols'] as List?)?.cast<String>(),
      directions:
          (json['directions'] as List?)?.cast<String>().map(_directionFromName),
      tapeNumber: json['tapeNumber'] as int? ?? 0,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is TMTransition &&
        super == other &&
        _listEquals(other.readSymbols, readSymbols) &&
        _listEquals(other.writeSymbols, writeSymbols) &&
        _listEquals(other.directions, directions) &&
        other.tapeNumber == tapeNumber;
  }

  @override
  int get hashCode {
    return Object.hash(
      super.hashCode,
      Object.hashAll(readSymbols),
      Object.hashAll(writeSymbols),
      Object.hashAll(directions),
      tapeNumber,
    );
  }

  @override
  String toString() {
    return 'TMTransition(id: $id, fromState: ${fromState.id}, toState: ${toState.id}, '
        'read: $readSymbols, write: $writeSymbols, directions: $directions)';
  }

  /// Validates the TM transition properties
  @override
  List<String> validate() {
    final errors = super.validate();

    if (readSymbols.any((symbol) => symbol.isEmpty)) {
      errors.add('TM transition must have read symbol');
    }

    if (writeSymbols.any((symbol) => symbol.isEmpty)) {
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

  bool canReadVector(List<String> symbols) => _listEquals(readSymbols, symbols);

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

List<T> _replaceAt<T>(List<T> values, int index, T value) {
  final result = List<T>.of(values);
  result[index] = value;
  return result;
}

TapeDirection _directionFromName(String? name) =>
    TapeDirection.values.firstWhere(
      (value) => value.name == name,
      orElse: () => TapeDirection.right,
    );

bool _listEquals<T>(List<T> left, List<T> right) {
  if (left.length != right.length) return false;
  for (var index = 0; index < left.length; index++) {
    if (left[index] != right[index]) return false;
  }
  return true;
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
