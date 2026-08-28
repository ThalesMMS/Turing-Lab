import 'dart:convert';

import 'package:turing_lab/core/interoperability/interoperability.dart';

enum CompatibilityCaseRole {
  minimal,
  representative,
  complex,
  edgeValid,
  malformed,
  unsupportedFeature,
}

enum CompatibilityExpectedOutcome {
  success,
  malformed,
  unsupported,
  resourceLimit,
}

enum CompatibilityDimension {
  exact,
  equivalent,
  different,
  lossy,
  importOnly,
  exportOnly,
  unsupported,
  notApplicable,
}

enum CompatibilityOracleKind {
  outcome,
  roundTrip,
  modelFacts,
  fsaAcceptance,
  regexAcceptance,
  mealyOutput,
  mooreOutput,
}

enum CompatibilityMutation { futureSchema }

final class CompatibilityProvenance {
  const CompatibilityProvenance({
    required this.origin,
    required this.license,
    required this.independentlyAuthored,
    required this.jflapVersion,
    required this.generator,
  });

  final String origin;
  final String license;
  final bool independentlyAuthored;
  final String jflapVersion;
  final String generator;

  factory CompatibilityProvenance.fromJson(Object? value, String path) {
    final json = _object(value, path);
    return CompatibilityProvenance(
      origin: _string(json, 'origin', path),
      license: _string(json, 'license', path),
      independentlyAuthored: _bool(json, 'independentlyAuthored', path),
      jflapVersion: _string(json, 'jflapVersion', path),
      generator: _string(json, 'generator', path),
    );
  }

  Map<String, Object?> toJson() => {
        'origin': origin,
        'license': license,
        'independentlyAuthored': independentlyAuthored,
        'jflapVersion': jflapVersion,
        'generator': generator,
      };
}

final class CompatibilityExpectation {
  CompatibilityExpectation({
    required this.outcome,
    required this.fidelity,
    required Iterable<String> diagnosticCodes,
    required Map<String, int> approvedLosses,
    required Iterable<String> unsupportedCapabilities,
    required Map<String, CompatibilityDimension> dimensions,
  })  : diagnosticCodes = List.unmodifiable(diagnosticCodes),
        approvedLosses = Map.unmodifiable(approvedLosses),
        unsupportedCapabilities = List.unmodifiable(unsupportedCapabilities),
        dimensions = Map.unmodifiable(dimensions);

  final CompatibilityExpectedOutcome outcome;
  final DocumentFidelity? fidelity;
  final List<String> diagnosticCodes;
  final Map<String, int> approvedLosses;
  final List<String> unsupportedCapabilities;
  final Map<String, CompatibilityDimension> dimensions;

  factory CompatibilityExpectation.fromJson(Object? value, String path) {
    final json = _object(value, path);
    final outcome = _enumValue(
      CompatibilityExpectedOutcome.values,
      _string(json, 'outcome', path),
      '$path.outcome',
    );
    final rawFidelity = json['fidelity'];
    final fidelity = rawFidelity == null
        ? null
        : _enumValue(
            DocumentFidelity.values,
            _nonEmptyString(rawFidelity, '$path.fidelity'),
            '$path.fidelity',
          );
    if (outcome == CompatibilityExpectedOutcome.success && fidelity == null) {
      throw FormatException('$path.fidelity is required for success cases.');
    }
    if (outcome != CompatibilityExpectedOutcome.success && fidelity != null) {
      throw FormatException(
        '$path.fidelity is only valid for success cases.',
      );
    }
    final losses = <String, int>{};
    final rawLosses = json['approvedLosses'] ?? const <Object?>[];
    if (rawLosses is! List) {
      throw FormatException('$path.approvedLosses must be an array.');
    }
    for (var index = 0; index < rawLosses.length; index++) {
      final lossPath = '$path.approvedLosses[$index]';
      final loss = _object(rawLosses[index], lossPath);
      final code = _string(loss, 'code', lossPath);
      final issue = _integer(loss, 'issue', lossPath);
      if (issue <= 0) {
        throw FormatException('$lossPath.issue must be positive.');
      }
      if (losses.containsKey(code)) {
        throw FormatException('$path has duplicate approved loss $code.');
      }
      losses[code] = issue;
    }
    final dimensions = <String, CompatibilityDimension>{};
    final rawDimensions = _object(json['dimensions'], '$path.dimensions');
    for (final name in const ['structural', 'semantic', 'visual', 'metadata']) {
      dimensions[name] = _enumValue(
        CompatibilityDimension.values,
        _string(rawDimensions, name, '$path.dimensions'),
        '$path.dimensions.$name',
      );
    }
    return CompatibilityExpectation(
      outcome: outcome,
      fidelity: fidelity,
      diagnosticCodes: _strings(
        json['diagnosticCodes'] ?? const <Object?>[],
        '$path.diagnosticCodes',
      ),
      approvedLosses: losses,
      unsupportedCapabilities: _strings(
        json['unsupportedCapabilities'] ?? const <Object?>[],
        '$path.unsupportedCapabilities',
      ),
      dimensions: dimensions,
    );
  }

  Map<String, Object?> toJson() => {
        'outcome': outcome.name,
        if (fidelity != null) 'fidelity': fidelity!.name,
        'diagnosticCodes': diagnosticCodes,
        'approvedLosses': [
          for (final entry in approvedLosses.entries)
            {'code': entry.key, 'issue': entry.value},
        ],
        'unsupportedCapabilities': unsupportedCapabilities,
        'dimensions': {
          for (final entry in dimensions.entries) entry.key: entry.value.name,
        },
      };
}

final class CompatibilityOracle {
  CompatibilityOracle({
    required this.kind,
    required Map<String, Object?> data,
  }) : data = Map.unmodifiable(data);

  final CompatibilityOracleKind kind;
  final Map<String, Object?> data;

  factory CompatibilityOracle.fromJson(Object? value, String path) {
    final json = _object(value, path);
    final kind = _enumValue(
      CompatibilityOracleKind.values,
      _string(json, 'kind', path),
      '$path.kind',
    );
    return CompatibilityOracle(
      kind: kind,
      data: {
        for (final entry in json.entries)
          if (entry.key != 'kind') entry.key: entry.value,
      },
    );
  }

  Map<String, Object?> toJson() => {'kind': kind.name, ...data};
}

final class CompatibilityEquivalent {
  const CompatibilityEquivalent({
    required this.codecId,
    required this.fixture,
    required this.sha256,
  });

  final String codecId;
  final String fixture;
  final String sha256;

  factory CompatibilityEquivalent.fromJson(Object? value, String path) {
    final json = _object(value, path);
    final checksum = _string(json, 'sha256', path).toLowerCase();
    if (!RegExp(r'^[a-f0-9]{64}$').hasMatch(checksum)) {
      throw FormatException('$path.sha256 must be a SHA-256 hex digest.');
    }
    return CompatibilityEquivalent(
      codecId: _string(json, 'codecId', path),
      fixture: _string(json, 'fixture', path),
      sha256: checksum,
    );
  }

  Map<String, Object?> toJson() => {
        'codecId': codecId,
        'fixture': fixture,
        'sha256': sha256,
      };
}

final class CompatibilityCase {
  CompatibilityCase({
    required this.id,
    required this.family,
    required this.codecId,
    required Iterable<CompatibilityCaseRole> roles,
    required this.fixture,
    required this.sha256,
    required this.provenance,
    required this.expectation,
    required this.oracle,
    this.equivalent,
    this.mutation,
    this.requiredTool,
  }) : roles = Set.unmodifiable(roles);

  final String id;
  final String family;
  final String codecId;
  final Set<CompatibilityCaseRole> roles;
  final String fixture;
  final String sha256;
  final CompatibilityProvenance provenance;
  final CompatibilityExpectation expectation;
  final CompatibilityOracle oracle;
  final CompatibilityEquivalent? equivalent;
  final CompatibilityMutation? mutation;
  final String? requiredTool;

  factory CompatibilityCase.fromJson(Object? value, int index) {
    final path = r'$.cases[' '${index.toString()}]';
    final json = _object(value, path);
    final roles = _strings(json['roles'], '$path.roles')
        .map(
          (role) => _enumValue(
            CompatibilityCaseRole.values,
            role,
            '$path.roles',
          ),
        )
        .toSet();
    if (roles.isEmpty) throw FormatException('$path.roles must not be empty.');
    final checksum = _string(json, 'sha256', path).toLowerCase();
    if (!RegExp(r'^[a-f0-9]{64}$').hasMatch(checksum)) {
      throw FormatException('$path.sha256 must be a SHA-256 hex digest.');
    }
    final requiredTool = json['requiredTool'];
    return CompatibilityCase(
      id: _string(json, 'id', path),
      family: _string(json, 'family', path),
      codecId: _string(json, 'codecId', path),
      roles: roles,
      fixture: _string(json, 'fixture', path),
      sha256: checksum,
      provenance: CompatibilityProvenance.fromJson(
        json['provenance'],
        '$path.provenance',
      ),
      expectation: CompatibilityExpectation.fromJson(
        json['expected'],
        '$path.expected',
      ),
      oracle: CompatibilityOracle.fromJson(
        json['oracle'],
        '$path.oracle',
      ),
      equivalent: json['equivalent'] == null
          ? null
          : CompatibilityEquivalent.fromJson(
              json['equivalent'],
              '$path.equivalent',
            ),
      mutation: json['mutation'] == null
          ? null
          : _enumValue(
              CompatibilityMutation.values,
              _nonEmptyString(json['mutation'], '$path.mutation'),
              '$path.mutation',
            ),
      requiredTool: requiredTool == null
          ? null
          : _nonEmptyString(requiredTool, '$path.requiredTool'),
    );
  }

  Map<String, Object?> toJson() => {
        'id': id,
        'family': family,
        'codecId': codecId,
        'roles': roles.map((role) => role.name).toList()..sort(),
        'fixture': fixture,
        'sha256': sha256,
        'provenance': provenance.toJson(),
        'expected': expectation.toJson(),
        'oracle': oracle.toJson(),
        if (equivalent != null) 'equivalent': equivalent!.toJson(),
        if (mutation != null) 'mutation': mutation!.name,
        if (requiredTool != null) 'requiredTool': requiredTool,
      };
}

final class CompatibilityManifest {
  CompatibilityManifest({
    required this.schemaVersion,
    required this.corpusVersion,
    required Iterable<CompatibilityCase> cases,
  }) : cases = List.unmodifiable(cases);

  static const supportedSchemaVersion = 1;

  final int schemaVersion;
  final String corpusVersion;
  final List<CompatibilityCase> cases;

  factory CompatibilityManifest.parse(String source) {
    final decoded = jsonDecode(source);
    final json = _object(decoded, r'$');
    final schemaVersion = _integer(json, 'schemaVersion', r'$');
    if (schemaVersion != supportedSchemaVersion) {
      throw FormatException(
        'Unsupported compatibility corpus schema version $schemaVersion.',
      );
    }
    final rawCases = json['cases'];
    if (rawCases is! List) {
      throw const FormatException(r'$.cases must be an array.');
    }
    final defaults = _object(json['defaults'], r'$.defaults');
    final defaultProvenance = _object(
      defaults['provenance'],
      r'$.defaults.provenance',
    );
    final defaultDimensions = _object(
      defaults['dimensions'],
      r'$.defaults.dimensions',
    );
    final rawCapabilities = _object(
      json['codecCapabilities'],
      r'$.codecCapabilities',
    );
    final cases = [
      for (var index = 0; index < rawCases.length; index++)
        CompatibilityCase.fromJson(
          _applyDefaults(
            rawCases[index],
            index,
            defaultProvenance,
            defaultDimensions,
            rawCapabilities,
          ),
          index,
        ),
    ];
    if (cases.isEmpty) {
      throw const FormatException(r'$.cases must not be empty.');
    }
    final ids = <String>{};
    for (final testCase in cases) {
      if (!ids.add(testCase.id)) {
        throw FormatException(
          'Duplicate compatibility fixture id ${testCase.id}.',
        );
      }
    }
    return CompatibilityManifest(
      schemaVersion: schemaVersion,
      corpusVersion: _string(json, 'corpusVersion', r'$'),
      cases: cases,
    );
  }

  Map<String, Object?> toJson() => {
        'schemaVersion': schemaVersion,
        'corpusVersion': corpusVersion,
        'cases': cases.map((testCase) => testCase.toJson()).toList(),
      };
}

Map<String, Object?> _applyDefaults(
  Object? value,
  int index,
  Map<String, Object?> provenance,
  Map<String, Object?> dimensions,
  Map<String, Object?> capabilities,
) {
  final path = r'$.cases[' '${index.toString()}]';
  final testCase = _object(value, path);
  final codecId = _string(testCase, 'codecId', path);
  final expected = _object(testCase['expected'], '$path.expected');
  final outcome = expected['outcome'];
  final resolvedDimensions = expected['dimensions'] ??
      (outcome == CompatibilityExpectedOutcome.success.name
          ? dimensions
          : const {
              'structural': 'notApplicable',
              'semantic': 'notApplicable',
              'visual': 'notApplicable',
              'metadata': 'notApplicable',
            });
  return {
    ...testCase,
    'provenance': testCase['provenance'] ?? provenance,
    'expected': {
      ...expected,
      'diagnosticCodes': expected['diagnosticCodes'] ?? const <Object?>[],
      'approvedLosses': expected['approvedLosses'] ?? const <Object?>[],
      'dimensions': resolvedDimensions,
      'unsupportedCapabilities': expected['unsupportedCapabilities'] ??
          capabilities[codecId] ??
          const <Object?>[],
    },
  };
}

Map<String, Object?> _object(Object? value, String path) {
  if (value is! Map) throw FormatException('$path must be an object.');
  return Map<String, Object?>.from(value);
}

String _string(Map<String, Object?> json, String key, String path) =>
    _nonEmptyString(json[key], '$path.$key');

String _nonEmptyString(Object? value, String path) {
  if (value is! String || value.trim().isEmpty) {
    throw FormatException('$path must be a non-empty string.');
  }
  return value;
}

bool _bool(Map<String, Object?> json, String key, String path) {
  final value = json[key];
  if (value is! bool) throw FormatException('$path.$key must be a boolean.');
  return value;
}

int _integer(Map<String, Object?> json, String key, String path) {
  final value = json[key];
  if (value is! int) throw FormatException('$path.$key must be an integer.');
  return value;
}

List<String> _strings(Object? value, String path) {
  if (value is! List) throw FormatException('$path must be an array.');
  return [
    for (var index = 0; index < value.length; index++)
      _nonEmptyString(value[index], '$path[$index]'),
  ];
}

T _enumValue<T extends Enum>(List<T> values, String raw, String path) {
  for (final value in values) {
    if (value.name == raw) return value;
  }
  throw FormatException('$path has unsupported value $raw.');
}
