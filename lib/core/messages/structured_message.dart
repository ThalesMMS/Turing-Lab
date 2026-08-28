import 'package:collection/collection.dart';

final RegExp _stableWireToken = RegExp(r'^[a-z][a-z0-9.-]*$');

/// Semantic family of a user-facing domain message.
enum StructuredMessageCategory {
  simulation('simulation'),
  trace('trace'),
  validation('validation'),
  parsing('parsing'),
  analysis('analysis'),
  transformation('transformation'),
  conversion('conversion'),
  interoperability('interoperability'),
  proof('proof'),
  graph('graph'),
  unknown('unknown');

  const StructuredMessageCategory(this.wireCode);

  final String wireCode;
}

/// Presentation-neutral importance of a domain message.
enum StructuredMessageSeverity {
  information('information'),
  warning('warning'),
  error('error'),
  unknown('unknown');

  const StructuredMessageSeverity(this.wireCode);

  final String wireCode;
}

/// Stable wire type for a message argument.
enum StructuredMessageArgumentKind {
  literal('literal'),
  identifier('identifier'),
  symbol('symbol'),
  integer('integer'),
  count('count'),
  bound('bound'),
  durationMilliseconds('duration-ms'),
  positionIndex('index'),
  number('number'),
  coordinate('coordinate'),
  boolean('boolean'),
  strategy('strategy'),
  outcome('outcome');

  const StructuredMessageArgumentKind(this.wireCode);

  final String wireCode;
}

/// A typed, locale-neutral argument passed to a presentation resolver.
final class StructuredMessageArgument {
  StructuredMessageArgument._({
    required this.kind,
    required Object value,
    this.role,
  }) : value = _freezeValue(value) {
    if (role != null && !_stableWireToken.hasMatch(role!)) {
      throw ArgumentError.value(role, 'role', 'Must be a stable wire token.');
    }
    _validateValue(kind, this.value);
  }

  /// Carries user-authored or formal display text that must never be translated.
  ///
  /// Do not use this kind for developer-authored explanatory prose.
  factory StructuredMessageArgument.literal(String value, {String? role}) =>
      StructuredMessageArgument._(
        kind: StructuredMessageArgumentKind.literal,
        value: value,
        role: role,
      );

  factory StructuredMessageArgument.identifier(
    String value, {
    required String role,
  }) => StructuredMessageArgument._(
    kind: StructuredMessageArgumentKind.identifier,
    value: value,
    role: role,
  );

  factory StructuredMessageArgument.symbol(String value, {String? role}) =>
      StructuredMessageArgument._(
        kind: StructuredMessageArgumentKind.symbol,
        value: value,
        role: role,
      );

  factory StructuredMessageArgument.integer(int value, {String? role}) =>
      StructuredMessageArgument._(
        kind: StructuredMessageArgumentKind.integer,
        value: value,
        role: role,
      );

  factory StructuredMessageArgument.count(int value, {String? role}) =>
      StructuredMessageArgument._(
        kind: StructuredMessageArgumentKind.count,
        value: value,
        role: role,
      );

  factory StructuredMessageArgument.bound(int value, {String? role}) =>
      StructuredMessageArgument._(
        kind: StructuredMessageArgumentKind.bound,
        value: value,
        role: role,
      );

  factory StructuredMessageArgument.duration(Duration value, {String? role}) =>
      StructuredMessageArgument._(
        kind: StructuredMessageArgumentKind.durationMilliseconds,
        value: value.inMilliseconds,
        role: role,
      );

  factory StructuredMessageArgument.index(int value, {String? role}) =>
      StructuredMessageArgument._(
        kind: StructuredMessageArgumentKind.positionIndex,
        value: value,
        role: role,
      );

  factory StructuredMessageArgument.number(num value, {String? role}) =>
      StructuredMessageArgument._(
        kind: StructuredMessageArgumentKind.number,
        value: value,
        role: role,
      );

  factory StructuredMessageArgument.coordinate({
    required num x,
    required num y,
    String? role,
  }) => StructuredMessageArgument._(
    kind: StructuredMessageArgumentKind.coordinate,
    value: <String, Object>{'x': x, 'y': y},
    role: role,
  );

  factory StructuredMessageArgument.boolean(bool value, {String? role}) =>
      StructuredMessageArgument._(
        kind: StructuredMessageArgumentKind.boolean,
        value: value,
        role: role,
      );

  factory StructuredMessageArgument.strategy(String value, {String? role}) =>
      StructuredMessageArgument._(
        kind: StructuredMessageArgumentKind.strategy,
        value: value,
        role: role,
      );

  factory StructuredMessageArgument.outcome(String value, {String? role}) =>
      StructuredMessageArgument._(
        kind: StructuredMessageArgumentKind.outcome,
        value: value,
        role: role,
      );

  final StructuredMessageArgumentKind kind;
  final Object value;
  final String? role;

  Map<String, Object?> toJson() => {
    'kind': kind.wireCode,
    'value': value,
    if (role != null) 'role': role,
  };

  factory StructuredMessageArgument.fromJson(Map<String, Object?> json) {
    final kindName = json['kind'];
    final value = json['value'];
    final role = json['role'];
    if (kindName is! String || value == null || role is! String?) {
      throw const FormatException('Malformed structured-message argument.');
    }
    if (role != null && !_stableWireToken.hasMatch(role)) {
      throw const FormatException('Malformed structured-message role.');
    }
    final kind = _argumentKindFromWire(kindName);
    if (kind == StructuredMessageArgumentKind.identifier && role == null) {
      throw const FormatException(
        'Structured-message identifier arguments require a role.',
      );
    }
    return StructuredMessageArgument._(kind: kind, value: value, role: role);
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is StructuredMessageArgument &&
          other.kind == kind &&
          other.role == role &&
          const DeepCollectionEquality().equals(other.value, value);

  @override
  int get hashCode =>
      Object.hash(kind, role, const DeepCollectionEquality().hash(value));
}

/// Optional source anchor for a structured domain message.
final class StructuredMessageSource {
  StructuredMessageSource({
    required this.kind,
    this.identifier,
    this.path,
    this.index,
  }) {
    if (!_stableWireToken.hasMatch(kind)) {
      throw ArgumentError.value(kind, 'kind', 'Must be a stable wire token.');
    }
    if (index != null && index! < 0) {
      throw ArgumentError.value(index, 'index', 'Must not be negative.');
    }
  }

  final String kind;
  final String? identifier;
  final String? path;
  final int? index;

  Map<String, Object?> toJson() => {
    'kind': kind,
    if (identifier != null) 'identifier': identifier,
    if (path != null) 'path': path,
    if (index != null) 'index': index,
  };

  factory StructuredMessageSource.fromJson(Map<String, Object?> json) {
    final kind = json['kind'];
    final identifier = json['identifier'];
    final path = json['path'];
    final index = json['index'];
    if (kind is! String ||
        identifier is! String? ||
        path is! String? ||
        index is! int? ||
        !_stableWireToken.hasMatch(kind) ||
        (index != null && index < 0)) {
      throw const FormatException('Malformed structured-message source.');
    }
    return StructuredMessageSource(
      kind: kind,
      identifier: identifier,
      path: path,
      index: index,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is StructuredMessageSource &&
          other.kind == kind &&
          other.identifier == identifier &&
          other.path == path &&
          other.index == index;

  @override
  int get hashCode => Object.hash(kind, identifier, path, index);
}

/// Stable suggested action that presentation code may choose to expose.
final class StructuredMessageAction {
  StructuredMessageAction({
    required this.code,
    Map<String, StructuredMessageArgument> arguments = const {},
  }) : arguments = _freezeArguments(arguments) {
    if (!_stableWireToken.hasMatch(code)) {
      throw ArgumentError.value(code, 'code', 'Must be a stable wire token.');
    }
  }

  final String code;
  final Map<String, StructuredMessageArgument> arguments;

  Map<String, Object?> toJson() => {
    'code': code,
    'arguments': {
      for (final entry in arguments.entries) entry.key: entry.value.toJson(),
    },
  };

  factory StructuredMessageAction.fromJson(Map<String, Object?> json) {
    final code = json['code'];
    if (code is! String || !_stableWireToken.hasMatch(code)) {
      throw const FormatException('Malformed structured-message action.');
    }
    return StructuredMessageAction(
      code: code,
      arguments: _decodeArguments(json['arguments']),
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is StructuredMessageAction &&
          other.code == code &&
          const MapEquality<String, StructuredMessageArgument>().equals(
            other.arguments,
            arguments,
          );

  @override
  int get hashCode => Object.hash(
    code,
    const MapEquality<String, StructuredMessageArgument>().hash(arguments),
  );
}

/// Versioned, immutable and locale-neutral semantic message.
final class StructuredMessage {
  StructuredMessage({
    required this.namespace,
    required this.code,
    required this.category,
    required this.severity,
    Map<String, StructuredMessageArgument> arguments = const {},
    this.source,
    this.suggestedAction,
  }) : arguments = _freezeArguments(arguments),
       _decodedCategoryWireCode = null,
       _decodedSeverityWireCode = null {
    _validateIdentity(namespace, code);
  }

  StructuredMessage._decoded({
    required this.namespace,
    required this.code,
    required this.category,
    required this.severity,
    required String categoryWireCode,
    required String severityWireCode,
    Map<String, StructuredMessageArgument> arguments = const {},
    this.source,
    this.suggestedAction,
  }) : arguments = _freezeArguments(arguments),
       _decodedCategoryWireCode = categoryWireCode,
       _decodedSeverityWireCode = severityWireCode {
    _validateIdentity(namespace, code);
  }

  static void _validateIdentity(String namespace, String code) {
    if (!_stableWireToken.hasMatch(namespace) ||
        !_stableWireToken.hasMatch(code)) {
      throw ArgumentError('Message namespace and code must be stable tokens.');
    }
  }

  static const schema = 'turing-lab.structured-message';
  static const schemaVersion = 1;

  final String namespace;
  final String code;
  final StructuredMessageCategory category;
  final StructuredMessageSeverity severity;
  final Map<String, StructuredMessageArgument> arguments;
  final StructuredMessageSource? source;
  final StructuredMessageAction? suggestedAction;
  final String? _decodedCategoryWireCode;
  final String? _decodedSeverityWireCode;

  String get stableCode => '$namespace.$code';

  Map<String, Object?> toJson() => {
    'schema': schema,
    'version': schemaVersion,
    'namespace': namespace,
    'code': code,
    'category': _categoryWireCode,
    'severity': _severityWireCode,
    'arguments': {
      for (final entry in arguments.entries) entry.key: entry.value.toJson(),
    },
    if (source != null) 'source': source!.toJson(),
    if (suggestedAction != null) 'suggestedAction': suggestedAction!.toJson(),
  };

  factory StructuredMessage.fromJson(Map<String, Object?> json) {
    if (json['schema'] != schema) {
      throw const FormatException('Unknown structured-message schema.');
    }
    if (json['version'] != schemaVersion) {
      throw FormatException(
        'Unsupported structured-message version: ${json['version']}.',
      );
    }
    final namespace = json['namespace'];
    final code = json['code'];
    final categoryName = json['category'];
    final severityName = json['severity'];
    if (namespace is! String ||
        code is! String ||
        categoryName is! String ||
        severityName is! String ||
        !_stableWireToken.hasMatch(namespace) ||
        !_stableWireToken.hasMatch(code)) {
      throw const FormatException('Malformed structured message.');
    }
    return StructuredMessage._decoded(
      namespace: namespace,
      code: code,
      category: _categoryFromWire(categoryName),
      severity: _severityFromWire(severityName),
      categoryWireCode: categoryName,
      severityWireCode: severityName,
      arguments: _decodeArguments(json['arguments']),
      source: json['source'] is Map
          ? StructuredMessageSource.fromJson(
              Map<String, Object?>.from(json['source']! as Map),
            )
          : null,
      suggestedAction: json['suggestedAction'] is Map
          ? StructuredMessageAction.fromJson(
              Map<String, Object?>.from(json['suggestedAction']! as Map),
            )
          : null,
    );
  }

  /// Creates a locale-neutral marker for a producer that still exposes prose.
  ///
  /// The legacy prose must remain only in a temporary in-memory adapter. It is
  /// deliberately not accepted here and therefore cannot enter persisted JSON.
  factory StructuredMessage.legacyAdapter({
    required String namespace,
    required String code,
    required StructuredMessageCategory category,
    StructuredMessageSeverity severity = StructuredMessageSeverity.error,
    Map<String, StructuredMessageArgument> arguments = const {},
  }) => StructuredMessage(
    namespace: namespace,
    code: code,
    category: category,
    severity: severity,
    arguments: arguments,
  );

  String get _categoryWireCode => _decodedCategoryWireCode ?? category.wireCode;

  String get _severityWireCode => _decodedSeverityWireCode ?? severity.wireCode;

  String get _categoryComparisonWireCode {
    final decoded = _decodedCategoryWireCode;
    if (decoded == null) return category.wireCode;
    return category == StructuredMessageCategory.unknown &&
            decoded != StructuredMessageCategory.unknown.wireCode
        ? decoded
        : category.wireCode;
  }

  String get _severityComparisonWireCode {
    final decoded = _decodedSeverityWireCode;
    if (decoded == null) return severity.wireCode;
    return severity == StructuredMessageSeverity.unknown &&
            decoded != StructuredMessageSeverity.unknown.wireCode
        ? decoded
        : severity.wireCode;
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is StructuredMessage &&
          other.namespace == namespace &&
          other.code == code &&
          other._categoryComparisonWireCode == _categoryComparisonWireCode &&
          other._severityComparisonWireCode == _severityComparisonWireCode &&
          const MapEquality<String, StructuredMessageArgument>().equals(
            other.arguments,
            arguments,
          ) &&
          other.source == source &&
          other.suggestedAction == suggestedAction;

  @override
  int get hashCode => Object.hash(
    namespace,
    code,
    _categoryComparisonWireCode,
    _severityComparisonWireCode,
    const MapEquality<String, StructuredMessageArgument>().hash(arguments),
    source,
    suggestedAction,
  );
}

Map<String, StructuredMessageArgument> _freezeArguments(
  Map<String, StructuredMessageArgument> source,
) {
  for (final key in source.keys) {
    if (!_stableWireToken.hasMatch(key)) {
      throw ArgumentError.value(
        key,
        'arguments',
        'Keys must be stable wire tokens.',
      );
    }
  }
  final entries = source.entries.toList()
    ..sort((left, right) => left.key.compareTo(right.key));
  return Map<String, StructuredMessageArgument>.unmodifiable({
    for (final entry in entries) entry.key: entry.value,
  });
}

Map<String, StructuredMessageArgument> _decodeArguments(Object? encoded) {
  if (encoded == null) return const {};
  if (encoded is! Map) {
    throw const FormatException('Malformed structured-message arguments.');
  }
  final decoded = <String, StructuredMessageArgument>{};
  for (final entry in encoded.entries) {
    if (entry.key is! String ||
        !_stableWireToken.hasMatch(entry.key as String) ||
        entry.value is! Map) {
      throw const FormatException(
        'Malformed structured-message argument entry.',
      );
    }
    decoded[entry.key as String] = StructuredMessageArgument.fromJson(
      Map<String, Object?>.from(entry.value as Map),
    );
  }
  return decoded;
}

Object _freezeValue(Object value) {
  if (value is Map) {
    final frozen = <String, Object>{};
    for (final entry in value.entries) {
      if (entry.key is! String || entry.value == null) {
        throw const FormatException('Malformed structured-message value.');
      }
      frozen[entry.key as String] = _freezeValue(entry.value as Object);
    }
    return Map<String, Object>.unmodifiable(frozen);
  }
  if (value is List) {
    if (value.any((element) => element == null)) {
      throw const FormatException('Malformed structured-message value.');
    }
    return List<Object>.unmodifiable(
      value.map((element) => _freezeValue(element as Object)),
    );
  }
  if (value is String || value is num || value is bool) return value;
  throw const FormatException('Malformed structured-message value.');
}

void _validateValue(StructuredMessageArgumentKind kind, Object value) {
  final valid = switch (kind) {
    StructuredMessageArgumentKind.literal ||
    StructuredMessageArgumentKind.identifier ||
    StructuredMessageArgumentKind.symbol ||
    StructuredMessageArgumentKind.strategy ||
    StructuredMessageArgumentKind.outcome => value is String,
    StructuredMessageArgumentKind.integer => value is int,
    StructuredMessageArgumentKind.count ||
    StructuredMessageArgumentKind.bound ||
    StructuredMessageArgumentKind.durationMilliseconds ||
    StructuredMessageArgumentKind.positionIndex => value is int && value >= 0,
    StructuredMessageArgumentKind.number => value is num && value.isFinite,
    StructuredMessageArgumentKind.coordinate =>
      value is Map &&
          value['x'] is num &&
          (value['x']! as num).isFinite &&
          value['y'] is num &&
          (value['y']! as num).isFinite,
    StructuredMessageArgumentKind.boolean => value is bool,
  };
  if (!valid) {
    throw FormatException(
      'Invalid ${kind.wireCode} structured-message argument.',
    );
  }
}

StructuredMessageArgumentKind _argumentKindFromWire(String wireCode) =>
    switch (wireCode) {
      'literal' => StructuredMessageArgumentKind.literal,
      'identifier' => StructuredMessageArgumentKind.identifier,
      'symbol' => StructuredMessageArgumentKind.symbol,
      'integer' => StructuredMessageArgumentKind.integer,
      'count' => StructuredMessageArgumentKind.count,
      'bound' => StructuredMessageArgumentKind.bound,
      'duration-ms' => StructuredMessageArgumentKind.durationMilliseconds,
      'index' => StructuredMessageArgumentKind.positionIndex,
      'number' => StructuredMessageArgumentKind.number,
      'coordinate' => StructuredMessageArgumentKind.coordinate,
      'boolean' => StructuredMessageArgumentKind.boolean,
      'strategy' => StructuredMessageArgumentKind.strategy,
      'outcome' => StructuredMessageArgumentKind.outcome,
      _ => throw FormatException(
        'Unsupported structured-message argument kind: $wireCode.',
      ),
    };

StructuredMessageCategory _categoryFromWire(String wireCode) =>
    switch (wireCode) {
      'simulation' => StructuredMessageCategory.simulation,
      'trace' => StructuredMessageCategory.trace,
      'validation' => StructuredMessageCategory.validation,
      'parsing' => StructuredMessageCategory.parsing,
      'analysis' => StructuredMessageCategory.analysis,
      'transformation' => StructuredMessageCategory.transformation,
      'conversion' => StructuredMessageCategory.conversion,
      'interoperability' => StructuredMessageCategory.interoperability,
      'proof' => StructuredMessageCategory.proof,
      'graph' => StructuredMessageCategory.graph,
      _ => StructuredMessageCategory.unknown,
    };

StructuredMessageSeverity _severityFromWire(String wireCode) =>
    switch (wireCode) {
      'information' => StructuredMessageSeverity.information,
      'warning' => StructuredMessageSeverity.warning,
      'error' => StructuredMessageSeverity.error,
      _ => StructuredMessageSeverity.unknown,
    };
