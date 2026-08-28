import 'dart:collection';

final class LSystemWord {
  factory LSystemWord(Iterable<String> symbols) {
    final values = symbols.toList(growable: false);
    if (values.any((symbol) => symbol.isEmpty)) {
      throw const FormatException('L-system symbols must not be empty.');
    }
    return LSystemWord._(List<String>.unmodifiable(values));
  }

  const LSystemWord._(this.symbols);

  static const empty = LSystemWord._(<String>[]);

  final List<String> symbols;

  int get length => symbols.length;
  bool get isEmpty => symbols.isEmpty;

  @override
  bool operator ==(Object other) =>
      other is LSystemWord && _listEquals(symbols, other.symbols);

  @override
  int get hashCode => Object.hashAll(symbols);
}

final class LSystemProduction {
  factory LSystemProduction({
    required String id,
    required String predecessor,
    required LSystemWord successor,
    LSystemWord leftContext = LSystemWord.empty,
    LSystemWord rightContext = LSystemWord.empty,
    double weight = 1,
  }) {
    if (id.trim().isEmpty ||
        predecessor.isEmpty ||
        !weight.isFinite ||
        weight <= 0) {
      throw const FormatException(
        'Production IDs and predecessors must not be empty, and weights must be positive and finite.',
      );
    }
    return LSystemProduction._(
      id: id,
      predecessor: predecessor,
      successor: successor,
      leftContext: leftContext,
      rightContext: rightContext,
      weight: weight,
    );
  }

  const LSystemProduction._({
    required this.id,
    required this.predecessor,
    required this.successor,
    required this.leftContext,
    required this.rightContext,
    required this.weight,
  });

  final String id;
  final String predecessor;
  final LSystemWord successor;
  final LSystemWord leftContext;
  final LSystemWord rightContext;
  final double weight;

  Map<String, Object?> toJson() => {
        'id': id,
        'predecessor': predecessor,
        'successor': successor.symbols,
        if (!leftContext.isEmpty) 'leftContext': leftContext.symbols,
        if (!rightContext.isEmpty) 'rightContext': rightContext.symbols,
        if (weight != 1) 'weight': weight,
      };

  static LSystemProduction fromJson(Map<String, Object?> json) =>
      LSystemProduction(
        id: _requiredString(json, 'id'),
        predecessor: _requiredString(json, 'predecessor'),
        successor: LSystemWord(_stringList(json['successor'], 'successor')),
        leftContext: LSystemWord(
          _optionalStringList(json['leftContext'], 'leftContext'),
        ),
        rightContext: LSystemWord(
          _optionalStringList(json['rightContext'], 'rightContext'),
        ),
        weight: _optionalNumber(json, 'weight', 1),
      );
}

enum LSystemTurtleCommand {
  drawForward,
  moveForward,
  turnLeft,
  turnRight,
  push,
  pop,
  reverseHeading,
  pitchDown,
  pitchUp,
  rollRight,
  rollLeft,
  increaseLineWidth,
  decreaseLineWidth,
  beginPolygon,
  endPolygon,
  increaseHue,
  decreaseHue,
  increasePolygonHue,
  decreasePolygonHue,
  setDrawColor,
  setPolygonColor,
  setAngleIncrement,
  setLineWidth,
  setLineWidthIncrement,
  setStepLength,
  setHueIncrement,
  ignore,
}

final class LSystemCommandMapping {
  factory LSystemCommandMapping(Map<String, LSystemTurtleCommand> commands) {
    if (commands.keys.any((symbol) => symbol.isEmpty)) {
      throw const FormatException('Command symbols must not be empty.');
    }
    return LSystemCommandMapping._(
      UnmodifiableMapView(Map<String, LSystemTurtleCommand>.from(commands)),
    );
  }

  const LSystemCommandMapping._(this.commands);

  static final standard = LSystemCommandMapping({
    'F': LSystemTurtleCommand.drawForward,
    'G': LSystemTurtleCommand.drawForward,
    'f': LSystemTurtleCommand.moveForward,
    '+': LSystemTurtleCommand.turnLeft,
    '-': LSystemTurtleCommand.turnRight,
    '[': LSystemTurtleCommand.push,
    ']': LSystemTurtleCommand.pop,
    '%': LSystemTurtleCommand.reverseHeading,
    '&': LSystemTurtleCommand.pitchDown,
    '^': LSystemTurtleCommand.pitchUp,
    '/': LSystemTurtleCommand.rollRight,
    '*': LSystemTurtleCommand.rollLeft,
    '!': LSystemTurtleCommand.increaseLineWidth,
    '~': LSystemTurtleCommand.decreaseLineWidth,
    '{': LSystemTurtleCommand.beginPolygon,
    '}': LSystemTurtleCommand.endPolygon,
    '#': LSystemTurtleCommand.increaseHue,
    '@': LSystemTurtleCommand.decreaseHue,
    '##': LSystemTurtleCommand.increasePolygonHue,
    '@@': LSystemTurtleCommand.decreasePolygonHue,
    'color': LSystemTurtleCommand.setDrawColor,
    'polygonColor': LSystemTurtleCommand.setPolygonColor,
    'angle': LSystemTurtleCommand.setAngleIncrement,
    'angleIncrement': LSystemTurtleCommand.setAngleIncrement,
    'lineWidth': LSystemTurtleCommand.setLineWidth,
    'lineIncrement': LSystemTurtleCommand.setLineWidthIncrement,
    'distance': LSystemTurtleCommand.setStepLength,
    'hueChange': LSystemTurtleCommand.setHueIncrement,
  });

  /// JFLAP 7.1 uses `g` for drawing and `f` for moving without drawing.
  static final jflap = LSystemCommandMapping({
    'g': LSystemTurtleCommand.drawForward,
    'f': LSystemTurtleCommand.moveForward,
    '+': LSystemTurtleCommand.turnRight,
    '-': LSystemTurtleCommand.turnLeft,
    '[': LSystemTurtleCommand.push,
    ']': LSystemTurtleCommand.pop,
    '%': LSystemTurtleCommand.reverseHeading,
    '&': LSystemTurtleCommand.pitchDown,
    '^': LSystemTurtleCommand.pitchUp,
    '/': LSystemTurtleCommand.rollRight,
    '*': LSystemTurtleCommand.rollLeft,
    '!': LSystemTurtleCommand.increaseLineWidth,
    '~': LSystemTurtleCommand.decreaseLineWidth,
    '{': LSystemTurtleCommand.beginPolygon,
    '}': LSystemTurtleCommand.endPolygon,
    '#': LSystemTurtleCommand.increaseHue,
    '@': LSystemTurtleCommand.decreaseHue,
    '##': LSystemTurtleCommand.increasePolygonHue,
    '@@': LSystemTurtleCommand.decreasePolygonHue,
    'color': LSystemTurtleCommand.setDrawColor,
    'polygonColor': LSystemTurtleCommand.setPolygonColor,
    'angle': LSystemTurtleCommand.setAngleIncrement,
    'angleIncrement': LSystemTurtleCommand.setAngleIncrement,
    'lineWidth': LSystemTurtleCommand.setLineWidth,
    'lineIncrement': LSystemTurtleCommand.setLineWidthIncrement,
    'distance': LSystemTurtleCommand.setStepLength,
    'hueChange': LSystemTurtleCommand.setHueIncrement,
  });

  final Map<String, LSystemTurtleCommand> commands;

  Map<String, Object?> toJson() => {
        for (final entry
            in (commands.entries.toList()
              ..sort((left, right) => left.key.compareTo(right.key))))
          entry.key: entry.value.name,
      };

  static LSystemCommandMapping fromJson(Object? value) {
    final json = _stringMap(value, 'commandMapping');
    return LSystemCommandMapping({
      for (final entry in json.entries)
        entry.key: LSystemTurtleCommand.values.byName(
          _asString(entry.value, 'commandMapping.${entry.key}'),
        ),
    });
  }
}

final class LSystemTurtleSettings {
  factory LSystemTurtleSettings({
    double angleDegrees = 90,
    double stepLength = 10,
    double scale = 1,
    double initialHeadingDegrees = 0,
    double initialX = 0,
    double initialY = 0,
    double lineWidth = 1,
    double lineWidthIncrement = 1,
    double hueIncrementDegrees = 10,
    int initialColorArgb = 0xff111827,
    int initialPolygonColorArgb = 0xff111827,
  }) {
    final finite = [
      angleDegrees,
      stepLength,
      scale,
      initialHeadingDegrees,
      initialX,
      initialY,
      lineWidth,
      lineWidthIncrement,
      hueIncrementDegrees,
    ];
    if (finite.any((value) => !value.isFinite) ||
        stepLength <= 0 ||
        scale <= 0 ||
        lineWidth <= 0 ||
        lineWidthIncrement <= 0) {
      throw const FormatException(
        'Turtle settings must be finite and lengths must be positive.',
      );
    }
    return LSystemTurtleSettings._(
      angleDegrees: angleDegrees,
      stepLength: stepLength,
      scale: scale,
      initialHeadingDegrees: initialHeadingDegrees,
      initialX: initialX,
      initialY: initialY,
      lineWidth: lineWidth,
      lineWidthIncrement: lineWidthIncrement,
      hueIncrementDegrees: hueIncrementDegrees,
      initialColorArgb: _argb(initialColorArgb, 'initialColorArgb'),
      initialPolygonColorArgb:
          _argb(initialPolygonColorArgb, 'initialPolygonColorArgb'),
    );
  }

  const LSystemTurtleSettings._({
    required this.angleDegrees,
    required this.stepLength,
    required this.scale,
    required this.initialHeadingDegrees,
    required this.initialX,
    required this.initialY,
    required this.lineWidth,
    required this.lineWidthIncrement,
    required this.hueIncrementDegrees,
    required this.initialColorArgb,
    required this.initialPolygonColorArgb,
  });

  final double angleDegrees;
  final double stepLength;
  final double scale;
  final double initialHeadingDegrees;
  final double initialX;
  final double initialY;
  final double lineWidth;
  final double lineWidthIncrement;
  final double hueIncrementDegrees;
  final int initialColorArgb;
  final int initialPolygonColorArgb;

  Map<String, Object?> toJson() => {
        'angleDegrees': angleDegrees,
        'stepLength': stepLength,
        'scale': scale,
        'initialHeadingDegrees': initialHeadingDegrees,
        'initialX': initialX,
        'initialY': initialY,
        'lineWidth': lineWidth,
        if (lineWidthIncrement != 1) 'lineWidthIncrement': lineWidthIncrement,
        if (hueIncrementDegrees != 10)
          'hueIncrementDegrees': hueIncrementDegrees,
        if (initialColorArgb != 0xff111827)
          'initialColorArgb': initialColorArgb,
        if (initialPolygonColorArgb != 0xff111827)
          'initialPolygonColorArgb': initialPolygonColorArgb,
      };

  static LSystemTurtleSettings fromJson(Object? value) {
    final json = _stringMap(value, 'turtle');
    return LSystemTurtleSettings(
      angleDegrees: _number(json, 'angleDegrees'),
      stepLength: _number(json, 'stepLength'),
      scale: _number(json, 'scale'),
      initialHeadingDegrees: _number(json, 'initialHeadingDegrees'),
      initialX: _number(json, 'initialX'),
      initialY: _number(json, 'initialY'),
      lineWidth: _number(json, 'lineWidth'),
      lineWidthIncrement: _optionalNumber(json, 'lineWidthIncrement', 1),
      hueIncrementDegrees: _optionalNumber(json, 'hueIncrementDegrees', 10),
      initialColorArgb: _optionalInteger(json, 'initialColorArgb', 0xff111827),
      initialPolygonColorArgb:
          _optionalInteger(json, 'initialPolygonColorArgb', 0xff111827),
    );
  }
}

enum LSystemUnsupportedVariant { stochastic, parametric, contextSensitive }

final class LSystemDocument {
  factory LSystemDocument({
    required String id,
    required String name,
    required int revision,
    required LSystemWord axiom,
    required Iterable<LSystemProduction> productions,
    required int iterations,
    required LSystemTurtleSettings turtle,
    required LSystemCommandMapping commandMapping,
    int randomSeed = 0,
    Iterable<String> ignoredContextSymbols = const [],
    Iterable<LSystemUnsupportedVariant> unsupportedVariants = const [],
    Map<String, Object?> unsupportedMetadata = const {},
  }) {
    if (id.trim().isEmpty ||
        name.trim().isEmpty ||
        revision < 0 ||
        iterations < 0) {
      throw const FormatException(
        'Document identity, revision, and iterations are invalid.',
      );
    }
    return LSystemDocument._(
      id: id,
      name: name,
      revision: revision,
      axiom: axiom,
      productions: List<LSystemProduction>.unmodifiable(productions),
      iterations: iterations,
      turtle: turtle,
      commandMapping: commandMapping,
      randomSeed: randomSeed,
      ignoredContextSymbols: Set<String>.unmodifiable(ignoredContextSymbols),
      unsupportedVariants:
          Set<LSystemUnsupportedVariant>.unmodifiable(unsupportedVariants),
      unsupportedMetadata: UnmodifiableMapView({
        for (final entry in unsupportedMetadata.entries)
          entry.key: _freeze(entry.value),
      }),
    );
  }

  const LSystemDocument._({
    required this.id,
    required this.name,
    required this.revision,
    required this.axiom,
    required this.productions,
    required this.iterations,
    required this.turtle,
    required this.commandMapping,
    required this.randomSeed,
    required this.ignoredContextSymbols,
    required this.unsupportedVariants,
    required this.unsupportedMetadata,
  });

  final String id;
  final String name;
  final int revision;
  final LSystemWord axiom;
  final List<LSystemProduction> productions;
  final int iterations;
  final LSystemTurtleSettings turtle;
  final LSystemCommandMapping commandMapping;
  final int randomSeed;
  final Set<String> ignoredContextSymbols;
  final Set<LSystemUnsupportedVariant> unsupportedVariants;
  final Map<String, Object?> unsupportedMetadata;

  Map<String, Object?> toJson() => {
        'schema': {'id': 'turing-lab.l-system', 'version': 1},
        'id': id,
        'name': name,
        'revision': revision,
        'axiom': axiom.symbols,
        'iterations': iterations,
        'productions': [
          for (final production
              in (productions.toList()
                ..sort((left, right) => left.id.compareTo(right.id))))
            production.toJson(),
        ],
        'turtle': turtle.toJson(),
        'commandMapping': commandMapping.toJson(),
        if (randomSeed != 0) 'randomSeed': randomSeed,
        if (ignoredContextSymbols.isNotEmpty)
          'ignoredContextSymbols': ignoredContextSymbols.toList()..sort(),
        'unsupportedVariants': [
          for (final value
              in (unsupportedVariants.toList()
                ..sort((left, right) => left.name.compareTo(right.name))))
            value.name,
        ],
        if (unsupportedMetadata.isNotEmpty)
          'unsupportedMetadata': unsupportedMetadata,
      };

  static LSystemDocument fromJson(Map<String, Object?> json) {
    final schema = _stringMap(json['schema'], 'schema');
    if (schema['id'] != 'turing-lab.l-system' || schema['version'] != 1) {
      throw const FormatException('Unsupported L-system schema.');
    }
    final rawProductions = json['productions'];
    if (rawProductions is! List) {
      throw const FormatException('productions must be a list.');
    }
    final rawVariants = json['unsupportedVariants'] ?? const <Object?>[];
    if (rawVariants is! List) {
      throw const FormatException('unsupportedVariants must be a list.');
    }
    return LSystemDocument(
      id: _requiredString(json, 'id'),
      name: _requiredString(json, 'name'),
      revision: _integer(json, 'revision'),
      axiom: LSystemWord(_stringList(json['axiom'], 'axiom')),
      iterations: _integer(json, 'iterations'),
      productions: rawProductions.map(
        (value) => LSystemProduction.fromJson(
          _stringMap(value, 'production'),
        ),
      ),
      turtle: LSystemTurtleSettings.fromJson(json['turtle']),
      commandMapping: LSystemCommandMapping.fromJson(json['commandMapping']),
      randomSeed: _optionalInteger(json, 'randomSeed', 0),
      ignoredContextSymbols: _optionalStringList(
        json['ignoredContextSymbols'],
        'ignoredContextSymbols',
      ),
      unsupportedVariants: rawVariants.map(
        (value) => LSystemUnsupportedVariant.values.byName(
          _asString(value, 'unsupportedVariant'),
        ),
      ),
      unsupportedMetadata: json['unsupportedMetadata'] == null
          ? const {}
          : _stringMap(json['unsupportedMetadata'], 'unsupportedMetadata'),
    );
  }

  LSystemDocument copyWith({
    String? id,
    String? name,
    int? revision,
    LSystemWord? axiom,
    Iterable<LSystemProduction>? productions,
    int? iterations,
    LSystemTurtleSettings? turtle,
    LSystemCommandMapping? commandMapping,
    int? randomSeed,
    Iterable<String>? ignoredContextSymbols,
    Iterable<LSystemUnsupportedVariant>? unsupportedVariants,
    Map<String, Object?>? unsupportedMetadata,
  }) =>
      LSystemDocument(
        id: id ?? this.id,
        name: name ?? this.name,
        revision: revision ?? this.revision,
        axiom: axiom ?? this.axiom,
        productions: productions ?? this.productions,
        iterations: iterations ?? this.iterations,
        turtle: turtle ?? this.turtle,
        commandMapping: commandMapping ?? this.commandMapping,
        randomSeed: randomSeed ?? this.randomSeed,
        ignoredContextSymbols:
            ignoredContextSymbols ?? this.ignoredContextSymbols,
        unsupportedVariants: unsupportedVariants ?? this.unsupportedVariants,
        unsupportedMetadata: unsupportedMetadata ?? this.unsupportedMetadata,
      );
}

bool _listEquals(List<Object?> left, List<Object?> right) {
  if (left.length != right.length) return false;
  for (var i = 0; i < left.length; i++) {
    if (left[i] != right[i]) return false;
  }
  return true;
}

String _requiredString(Map<String, Object?> json, String key) =>
    _asString(json[key], key);

String _asString(Object? value, String path) {
  if (value is! String || value.isEmpty) {
    throw FormatException('$path must be a non-empty string.');
  }
  return value;
}

int _integer(Map<String, Object?> json, String key) {
  final value = json[key];
  if (value is! int) throw FormatException('$key must be an integer.');
  return value;
}

int _optionalInteger(Map<String, Object?> json, String key, int fallback) {
  final value = json[key];
  if (value == null) return fallback;
  if (value is! int) throw FormatException('$key must be an integer.');
  return value;
}

double _number(Map<String, Object?> json, String key) {
  final value = json[key];
  if (value is! num) throw FormatException('$key must be a number.');
  return value.toDouble();
}

double _optionalNumber(
  Map<String, Object?> json,
  String key,
  double fallback,
) {
  final value = json[key];
  if (value == null) return fallback;
  if (value is! num) throw FormatException('$key must be a number.');
  return value.toDouble();
}

List<String> _stringList(Object? value, String path) {
  if (value is! List || value.any((element) => element is! String)) {
    throw FormatException('$path must be a list of strings.');
  }
  return value.cast<String>();
}

List<String> _optionalStringList(Object? value, String path) =>
    value == null ? const [] : _stringList(value, path);

int _argb(int value, String path) {
  if (value < 0 || value > 0xffffffff) {
    throw FormatException('$path must be an unsigned 32-bit ARGB value.');
  }
  return value;
}

Map<String, Object?> _stringMap(Object? value, String path) {
  if (value is! Map) throw FormatException('$path must be an object.');
  try {
    return value.cast<String, Object?>();
  } on TypeError {
    throw FormatException('$path must have string keys.');
  }
}

Object? _freeze(Object? value) => switch (value) {
      Map() => UnmodifiableMapView({
          for (final entry in value.entries)
            entry.key.toString(): _freeze(entry.value),
        }),
      List() => List<Object?>.unmodifiable(value.map(_freeze)),
      Set() => Set<Object?>.unmodifiable(value.map(_freeze)),
      _ => value,
    };
