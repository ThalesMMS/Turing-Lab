import 'transducer_ids.dart';
import 'transducer_symbols.dart';

enum TransducerDecodeErrorCode {
  malformedPayload,
  schemaMismatch,
  unsupportedVersion,
}

final class TransducerDecodeException extends FormatException {
  const TransducerDecodeException(this.code, String message, [Object? source])
    : super(message, source);

  final TransducerDecodeErrorCode code;
}

final class TransducerPoint {
  const TransducerPoint(this.x, this.y);

  final double x;
  final double y;

  Map<String, Object> toJson() => {'x': x, 'y': y};

  static TransducerPoint fromJson(Object? encoded) {
    final map = _objectMap(encoded, 'position');
    return TransducerPoint(
      _number(map, 'x').toDouble(),
      _number(map, 'y').toDouble(),
    );
  }
}

sealed class TransducerState {
  const TransducerState({
    required this.id,
    required this.label,
    required this.position,
    this.isInitial = false,
  });

  final TransducerStateId id;
  final String label;
  final TransducerPoint position;
  final bool isInitial;

  Map<String, Object?> toJson();
}

final class MealyState extends TransducerState {
  const MealyState({
    required super.id,
    required super.label,
    required super.position,
    super.isInitial,
  });

  MealyState copyWith({
    TransducerStateId? id,
    String? label,
    TransducerPoint? position,
    bool? isInitial,
  }) => MealyState(
    id: id ?? this.id,
    label: label ?? this.label,
    position: position ?? this.position,
    isInitial: isInitial ?? this.isInitial,
  );

  @override
  Map<String, Object?> toJson() => {
    'id': id.value,
    'label': label,
    'position': position.toJson(),
    'isInitial': isInitial,
  };

  static MealyState fromJson(Object? encoded) {
    final map = _objectMap(encoded, 'mealy-state');
    return MealyState(
      id: TransducerStateId(_string(map, 'id')),
      label: _string(map, 'label'),
      position: TransducerPoint.fromJson(map['position']),
      isInitial: _bool(map, 'isInitial'),
    );
  }
}

final class MooreState extends TransducerState {
  const MooreState({
    required super.id,
    required super.label,
    required super.position,
    required this.output,
    super.isInitial,
  });

  final TransducerOutputWord output;

  MooreState copyWith({
    TransducerStateId? id,
    String? label,
    TransducerPoint? position,
    bool? isInitial,
    TransducerOutputWord? output,
  }) => MooreState(
    id: id ?? this.id,
    label: label ?? this.label,
    position: position ?? this.position,
    isInitial: isInitial ?? this.isInitial,
    output: output ?? this.output,
  );

  @override
  Map<String, Object?> toJson() => {
    'id': id.value,
    'label': label,
    'position': position.toJson(),
    'isInitial': isInitial,
    'output': output.values,
  };

  static MooreState fromJson(Object? encoded) {
    final map = _objectMap(encoded, 'moore-state');
    return MooreState(
      id: TransducerStateId(_string(map, 'id')),
      label: _string(map, 'label'),
      position: TransducerPoint.fromJson(map['position']),
      isInitial: _bool(map, 'isInitial'),
      output: TransducerOutputWord.fromValues(_stringList(map, 'output')),
    );
  }
}

sealed class TransducerTransition {
  const TransducerTransition({
    required this.id,
    required this.from,
    required this.to,
    required this.input,
  });

  final TransducerTransitionId id;
  final TransducerStateId from;
  final TransducerStateId to;
  final TransducerInputSymbol input;

  Map<String, Object?> toJson();
}

final class MealyTransition extends TransducerTransition {
  const MealyTransition({
    required super.id,
    required super.from,
    required super.to,
    required super.input,
    required this.output,
  });

  final TransducerOutputWord output;

  @override
  Map<String, Object?> toJson() => {
    'id': id.value,
    'from': from.value,
    'to': to.value,
    'input': input.value,
    'output': output.values,
  };

  static MealyTransition fromJson(Object? encoded) {
    final map = _objectMap(encoded, 'mealy-transition');
    return MealyTransition(
      id: TransducerTransitionId(_string(map, 'id')),
      from: TransducerStateId(_string(map, 'from')),
      to: TransducerStateId(_string(map, 'to')),
      input: TransducerInputSymbol(_string(map, 'input')),
      output: TransducerOutputWord.fromValues(_stringList(map, 'output')),
    );
  }
}

final class MooreTransition extends TransducerTransition {
  const MooreTransition({
    required super.id,
    required super.from,
    required super.to,
    required super.input,
  });

  @override
  Map<String, Object?> toJson() => {
    'id': id.value,
    'from': from.value,
    'to': to.value,
    'input': input.value,
  };

  static MooreTransition fromJson(Object? encoded) {
    final map = _objectMap(encoded, 'moore-transition');
    return MooreTransition(
      id: TransducerTransitionId(_string(map, 'id')),
      from: TransducerStateId(_string(map, 'from')),
      to: TransducerStateId(_string(map, 'to')),
      input: TransducerInputSymbol(_string(map, 'input')),
    );
  }
}

abstract interface class DeterministicFiniteStateTransducer {
  TransducerMachineId get id;
  String get name;
  TransducerRevision get revision;
  Set<TransducerInputSymbol> get inputAlphabet;
  Set<TransducerOutputSymbol> get outputAlphabet;
  List<TransducerState> get states;
  List<TransducerTransition> get transitions;
  String get schemaId;
  Map<String, Object?> toJson();
}

final class MealyMachine implements DeterministicFiniteStateTransducer {
  MealyMachine({
    required this.id,
    required this.name,
    required this.revision,
    required Iterable<TransducerInputSymbol> inputAlphabet,
    required Iterable<TransducerOutputSymbol> outputAlphabet,
    required Iterable<MealyState> states,
    required Iterable<MealyTransition> transitions,
  }) : inputAlphabet = _inputAlphabetSnapshot(inputAlphabet),
       outputAlphabet = _outputAlphabetSnapshot(outputAlphabet),
       states = _stateSnapshot(states),
       transitions = _transitionSnapshot(transitions);

  @override
  final TransducerMachineId id;
  @override
  final String name;
  @override
  final TransducerRevision revision;
  @override
  final Set<TransducerInputSymbol> inputAlphabet;
  @override
  final Set<TransducerOutputSymbol> outputAlphabet;
  @override
  final List<MealyState> states;
  @override
  final List<MealyTransition> transitions;

  @override
  String get schemaId => 'turing-lab.mealy';

  MealyMachine copyWith({
    TransducerMachineId? id,
    String? name,
    TransducerRevision? revision,
    Iterable<TransducerInputSymbol>? inputAlphabet,
    Iterable<TransducerOutputSymbol>? outputAlphabet,
    Iterable<MealyState>? states,
    Iterable<MealyTransition>? transitions,
  }) => MealyMachine(
    id: id ?? this.id,
    name: name ?? this.name,
    revision: revision ?? this.revision,
    inputAlphabet: inputAlphabet ?? this.inputAlphabet,
    outputAlphabet: outputAlphabet ?? this.outputAlphabet,
    states: states ?? this.states,
    transitions: transitions ?? this.transitions,
  );

  @override
  Map<String, Object?> toJson() => _machineJson(
    schemaId: schemaId,
    id: id,
    name: name,
    revision: revision,
    inputAlphabet: inputAlphabet,
    outputAlphabet: outputAlphabet,
    states: states,
    transitions: transitions,
  );

  static MealyMachine fromJson(Map<String, Object?> encoded) {
    final decoded = _decodeMachine(encoded, 'turing-lab.mealy');
    return MealyMachine(
      id: decoded.id,
      name: decoded.name,
      revision: decoded.revision,
      inputAlphabet: decoded.inputAlphabet,
      outputAlphabet: decoded.outputAlphabet,
      states: decoded.states.map(MealyState.fromJson),
      transitions: decoded.transitions.map(MealyTransition.fromJson),
    );
  }
}

final class MooreMachine implements DeterministicFiniteStateTransducer {
  MooreMachine({
    required this.id,
    required this.name,
    required this.revision,
    required Iterable<TransducerInputSymbol> inputAlphabet,
    required Iterable<TransducerOutputSymbol> outputAlphabet,
    required Iterable<MooreState> states,
    required Iterable<MooreTransition> transitions,
  }) : inputAlphabet = _inputAlphabetSnapshot(inputAlphabet),
       outputAlphabet = _outputAlphabetSnapshot(outputAlphabet),
       states = _stateSnapshot(states),
       transitions = _transitionSnapshot(transitions);

  @override
  final TransducerMachineId id;
  @override
  final String name;
  @override
  final TransducerRevision revision;
  @override
  final Set<TransducerInputSymbol> inputAlphabet;
  @override
  final Set<TransducerOutputSymbol> outputAlphabet;
  @override
  final List<MooreState> states;
  @override
  final List<MooreTransition> transitions;

  @override
  String get schemaId => 'turing-lab.moore';

  MooreMachine copyWith({
    TransducerMachineId? id,
    String? name,
    TransducerRevision? revision,
    Iterable<TransducerInputSymbol>? inputAlphabet,
    Iterable<TransducerOutputSymbol>? outputAlphabet,
    Iterable<MooreState>? states,
    Iterable<MooreTransition>? transitions,
  }) => MooreMachine(
    id: id ?? this.id,
    name: name ?? this.name,
    revision: revision ?? this.revision,
    inputAlphabet: inputAlphabet ?? this.inputAlphabet,
    outputAlphabet: outputAlphabet ?? this.outputAlphabet,
    states: states ?? this.states,
    transitions: transitions ?? this.transitions,
  );

  @override
  Map<String, Object?> toJson() => _machineJson(
    schemaId: schemaId,
    id: id,
    name: name,
    revision: revision,
    inputAlphabet: inputAlphabet,
    outputAlphabet: outputAlphabet,
    states: states,
    transitions: transitions,
  );

  static MooreMachine fromJson(Map<String, Object?> encoded) {
    final decoded = _decodeMachine(encoded, 'turing-lab.moore');
    return MooreMachine(
      id: decoded.id,
      name: decoded.name,
      revision: decoded.revision,
      inputAlphabet: decoded.inputAlphabet,
      outputAlphabet: decoded.outputAlphabet,
      states: decoded.states.map(MooreState.fromJson),
      transitions: decoded.transitions.map(MooreTransition.fromJson),
    );
  }
}

Set<TransducerInputSymbol> _inputAlphabetSnapshot(
  Iterable<TransducerInputSymbol> alphabet,
) {
  final sorted = alphabet.toList()..sort();
  return Set<TransducerInputSymbol>.unmodifiable(sorted);
}

Set<TransducerOutputSymbol> _outputAlphabetSnapshot(
  Iterable<TransducerOutputSymbol> alphabet,
) {
  final sorted = alphabet.toList()..sort();
  return Set<TransducerOutputSymbol>.unmodifiable(sorted);
}

List<T> _stateSnapshot<T extends TransducerState>(Iterable<T> states) {
  final sorted = states.toList()
    ..sort((left, right) => left.id.compareTo(right.id));
  return List<T>.unmodifiable(sorted);
}

List<T> _transitionSnapshot<T extends TransducerTransition>(
  Iterable<T> transitions,
) {
  final sorted = transitions.toList()
    ..sort((left, right) => left.id.compareTo(right.id));
  return List<T>.unmodifiable(sorted);
}

Map<String, Object?> _machineJson({
  required String schemaId,
  required TransducerMachineId id,
  required String name,
  required TransducerRevision revision,
  required Set<TransducerInputSymbol> inputAlphabet,
  required Set<TransducerOutputSymbol> outputAlphabet,
  required List<TransducerState> states,
  required List<TransducerTransition> transitions,
}) => {
  'schema': {'id': schemaId, 'version': 1},
  'id': id.value,
  'name': name,
  'revision': revision.value,
  'inputAlphabet': inputAlphabet.map((symbol) => symbol.value).toList(),
  'outputAlphabet': outputAlphabet.map((symbol) => symbol.value).toList(),
  'states': states.map((state) => state.toJson()).toList(),
  'transitions': transitions.map((transition) => transition.toJson()).toList(),
};

({
  TransducerMachineId id,
  String name,
  TransducerRevision revision,
  List<TransducerInputSymbol> inputAlphabet,
  List<TransducerOutputSymbol> outputAlphabet,
  List<Object?> states,
  List<Object?> transitions,
})
_decodeMachine(Map<String, Object?> encoded, String expectedSchema) {
  final map = Map<String, Object?>.from(encoded);
  final schema = _objectMap(map['schema'], 'schema');
  if (_string(schema, 'id') != expectedSchema) {
    throw TransducerDecodeException(
      TransducerDecodeErrorCode.schemaMismatch,
      'transducer.decode.schema-mismatch',
      schema,
    );
  }
  final version = _integer(schema, 'version');
  if (version != 1) {
    throw TransducerDecodeException(
      TransducerDecodeErrorCode.unsupportedVersion,
      'transducer.decode.unsupported-version',
      version,
    );
  }
  final stateList = _objectList(map, 'states');
  final transitionList = _objectList(map, 'transitions');
  return (
    id: TransducerMachineId(_string(map, 'id')),
    name: _string(map, 'name'),
    revision: TransducerRevision(_integer(map, 'revision')),
    inputAlphabet: _stringList(
      map,
      'inputAlphabet',
    ).map(TransducerInputSymbol.new).toList(),
    outputAlphabet: _stringList(
      map,
      'outputAlphabet',
    ).map(TransducerOutputSymbol.new).toList(),
    states: stateList,
    transitions: transitionList,
  );
}

Map<String, Object?> _objectMap(Object? value, String field) {
  if (value is! Map) {
    throw TransducerDecodeException(
      TransducerDecodeErrorCode.malformedPayload,
      'transducer.decode.object-required',
      field,
    );
  }
  try {
    return Map<String, Object?>.from(value);
  } on TypeError {
    throw TransducerDecodeException(
      TransducerDecodeErrorCode.malformedPayload,
      'transducer.decode.string-keys-required',
      field,
    );
  }
}

String _string(Map<String, Object?> map, String field) {
  final value = map[field];
  if (value is! String) {
    throw TransducerDecodeException(
      TransducerDecodeErrorCode.malformedPayload,
      'transducer.decode.string-required',
      field,
    );
  }
  return value;
}

bool _bool(Map<String, Object?> map, String field) {
  final value = map[field];
  if (value is! bool) {
    throw TransducerDecodeException(
      TransducerDecodeErrorCode.malformedPayload,
      'transducer.decode.boolean-required',
      field,
    );
  }
  return value;
}

num _number(Map<String, Object?> map, String field) {
  final value = map[field];
  if (value is! num) {
    throw TransducerDecodeException(
      TransducerDecodeErrorCode.malformedPayload,
      'transducer.decode.number-required',
      field,
    );
  }
  return value;
}

int _integer(Map<String, Object?> map, String field) {
  final value = map[field];
  if (value is! int) {
    throw TransducerDecodeException(
      TransducerDecodeErrorCode.malformedPayload,
      'transducer.decode.integer-required',
      field,
    );
  }
  return value;
}

List<Object?> _objectList(Map<String, Object?> map, String field) {
  final value = map[field];
  if (value is! List) {
    throw TransducerDecodeException(
      TransducerDecodeErrorCode.malformedPayload,
      'transducer.decode.list-required',
      field,
    );
  }
  return List<Object?>.from(value);
}

List<String> _stringList(Map<String, Object?> map, String field) {
  final values = _objectList(map, field);
  if (values.any((value) => value is! String)) {
    throw TransducerDecodeException(
      TransducerDecodeErrorCode.malformedPayload,
      'transducer.decode.string-list-required',
      field,
    );
  }
  return List<String>.unmodifiable(values.cast<String>());
}
