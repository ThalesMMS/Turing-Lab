import 'dart:convert';
import 'dart:io';

import 'package:crypto/crypto.dart';

import 'models.dart';
import 'mutation.dart';

enum HardEdgeSourceKind {
  independent,
  generated,
  jflapDerived,
  historicalRegression,
}

enum HardEdgeExpectedOutcome {
  pass,
  notApplicable,
  bounded,
  violation,
  invalid,
  conflict,
  cancelled,
}

final class HardEdgeProvenance {
  const HardEdgeProvenance({
    required this.origin,
    required this.independentlyAuthored,
    required this.generator,
    required this.licenseBasis,
    this.jflapVersion,
    this.sourceRevision,
    this.sourceSha256,
  });

  final String origin;
  final bool independentlyAuthored;
  final String generator;
  final String licenseBasis;
  final String? jflapVersion;
  final String? sourceRevision;
  final String? sourceSha256;

  factory HardEdgeProvenance.parse(Object? source, String path) {
    final json = _object(source, path);
    _requireKeys(
      json,
      const {
        'origin',
        'independentlyAuthored',
        'generator',
        'licenseBasis',
        'jflapVersion',
        'sourceRevision',
        'sourceSha256',
      },
      path,
    );
    return HardEdgeProvenance(
      origin: _nonEmptyString(json['origin'], '$path.origin'),
      independentlyAuthored: _boolean(
          json['independentlyAuthored'], '$path.independentlyAuthored'),
      generator: _nonEmptyString(json['generator'], '$path.generator'),
      licenseBasis: _relativePath(json['licenseBasis'], '$path.licenseBasis'),
      jflapVersion: _nullableString(json['jflapVersion'], '$path.jflapVersion'),
      sourceRevision:
          _nullableString(json['sourceRevision'], '$path.sourceRevision'),
      sourceSha256: _nullableDigest(
        json['sourceSha256'],
        '$path.sourceSha256',
      ),
    );
  }

  Map<String, Object?> toJson() => {
        'generator': generator,
        'independentlyAuthored': independentlyAuthored,
        'jflapVersion': jflapVersion,
        'licenseBasis': licenseBasis,
        'origin': origin,
        'sourceRevision': sourceRevision,
        'sourceSha256': sourceSha256,
      };
}

final class HardEdgeCatalogCase {
  HardEdgeCatalogCase({
    required this.id,
    required this.family,
    required this.algorithm,
    required this.sourceKind,
    required this.seed,
    required this.property,
    required this.provenance,
    required this.license,
    required this.regressionIssue,
    required Iterable<String> platforms,
    required this.sha256,
    required this.generatorVersion,
    required this.oracleVersion,
    required this.budget,
    required this.fixture,
    required this.expectedOutcome,
    required this.requiredTool,
  }) : platforms = List<String>.unmodifiable(platforms);

  final String id;
  final String family;
  final String algorithm;
  final HardEdgeSourceKind sourceKind;
  final int seed;
  final String property;
  final HardEdgeProvenance provenance;
  final String license;
  final int? regressionIssue;
  final List<String> platforms;
  final String sha256;
  final String generatorVersion;
  final String oracleVersion;
  final GenerationBudget budget;
  final String fixture;
  final HardEdgeExpectedOutcome expectedOutcome;
  final String? requiredTool;

  factory HardEdgeCatalogCase.parse(Object? source, String path) {
    final json = _object(source, path);
    _requireKeys(
      json,
      const {
        'id',
        'family',
        'algorithm',
        'sourceKind',
        'seed',
        'property',
        'provenance',
        'license',
        'regressionIssue',
        'platforms',
        'sha256',
        'generatorVersion',
        'oracleVersion',
        'budget',
        'fixture',
        'expectedOutcome',
        'requiredTool',
      },
      path,
    );
    final seed = _integer(json['seed'], '$path.seed');
    if (seed < 0 || seed > 0xffffffff) {
      throw FormatException('$path.seed must be between 0 and 4294967295.');
    }
    final issue =
        _nullableInteger(json['regressionIssue'], '$path.regressionIssue');
    if (issue != null && issue <= 0) {
      throw FormatException('$path.regressionIssue must be positive.');
    }
    final platforms = _stringList(json['platforms'], '$path.platforms');
    if (platforms.isEmpty) {
      throw FormatException('$path.platforms must not be empty.');
    }
    const supportedPlatforms = {
      'android',
      'ios',
      'web',
      'windows',
      'macos',
      'linux',
      'all',
    };
    for (final platform in platforms) {
      if (!supportedPlatforms.contains(platform)) {
        throw FormatException('$path.platforms contains unknown "$platform".');
      }
    }
    final sourceKind = _enumValue(
      HardEdgeSourceKind.values,
      json['sourceKind'],
      '$path.sourceKind',
    );
    final provenance =
        HardEdgeProvenance.parse(json['provenance'], '$path.provenance');
    final license = _nonEmptyString(json['license'], '$path.license');
    const supportedLicenseBases = {
      'Apache-2.0': 'LICENSE.txt',
      'LicenseRef-JFLAP-7.1': 'LICENSE_JFLAP.txt',
    };
    final expectedLicenseBasis = supportedLicenseBases[license];
    if (expectedLicenseBasis == null) {
      throw FormatException(
        '$path.license must name a registered fixture license: '
        '${supportedLicenseBases.keys.join(', ')}.',
      );
    }
    if (provenance.licenseBasis != expectedLicenseBasis) {
      throw FormatException(
        '$path.provenance.licenseBasis must be $expectedLicenseBasis for '
        '$license.',
      );
    }
    if (platforms.contains('all') && platforms.length != 1) {
      throw FormatException(
          '$path.platforms cannot combine "all" with a platform.');
    }
    switch (sourceKind) {
      case HardEdgeSourceKind.independent:
        if (!provenance.independentlyAuthored ||
            provenance.jflapVersion != null ||
            provenance.sourceRevision != null ||
            provenance.sourceSha256 != null) {
          throw FormatException(
            '$path independent fixtures must be independently authored and '
            'must not claim an external source revision.',
          );
        }
      case HardEdgeSourceKind.generated:
        break;
      case HardEdgeSourceKind.jflapDerived:
        if (provenance.independentlyAuthored ||
            provenance.jflapVersion == null ||
            provenance.sourceRevision == null ||
            provenance.sourceSha256 == null ||
            license != 'LicenseRef-JFLAP-7.1') {
          throw FormatException(
            '$path JFLAP-derived fixtures must record the JFLAP version, '
            'source revision, source SHA-256, and JFLAP license basis, and '
            'must not be marked independently authored.',
          );
        }
      case HardEdgeSourceKind.historicalRegression:
        if (issue == null) {
          throw FormatException(
            '$path historical regressions must name regressionIssue.',
          );
        }
    }
    return HardEdgeCatalogCase(
      id: _identifier(json['id'], '$path.id'),
      family: _identifier(json['family'], '$path.family'),
      algorithm: _identifier(json['algorithm'], '$path.algorithm'),
      sourceKind: sourceKind,
      seed: seed,
      property: _identifier(json['property'], '$path.property'),
      provenance: provenance,
      license: license,
      regressionIssue: issue,
      platforms: platforms,
      sha256: _digest(json['sha256'], '$path.sha256'),
      generatorVersion:
          _nonEmptyString(json['generatorVersion'], '$path.generatorVersion'),
      oracleVersion:
          _nonEmptyString(json['oracleVersion'], '$path.oracleVersion'),
      budget: _generationBudget(json['budget'], '$path.budget'),
      fixture: _relativePath(json['fixture'], '$path.fixture'),
      expectedOutcome: _enumValue(
        HardEdgeExpectedOutcome.values,
        json['expectedOutcome'],
        '$path.expectedOutcome',
      ),
      requiredTool: _nullableString(json['requiredTool'], '$path.requiredTool'),
    );
  }

  Map<String, Object?> toJson() => {
        'algorithm': algorithm,
        'expectedOutcome': expectedOutcome.name,
        'family': family,
        'fixture': fixture,
        'generatorVersion': generatorVersion,
        'id': id,
        'license': license,
        'oracleVersion': oracleVersion,
        'budget': budget.toJson(),
        'platforms': platforms,
        'property': property,
        'provenance': provenance.toJson(),
        'regressionIssue': regressionIssue,
        'requiredTool': requiredTool,
        'seed': seed,
        'sha256': sha256,
        'sourceKind': sourceKind.name,
      };

  HardEdgeCatalogCase copyWith({
    String? id,
    int? seed,
    HardEdgeSourceKind? sourceKind,
    String? fixture,
    String? sha256,
  }) =>
      HardEdgeCatalogCase(
        id: id ?? this.id,
        family: family,
        algorithm: algorithm,
        sourceKind: sourceKind ?? this.sourceKind,
        seed: seed ?? this.seed,
        property: property,
        provenance: provenance,
        license: license,
        regressionIssue: regressionIssue,
        platforms: platforms,
        sha256: sha256 ?? this.sha256,
        generatorVersion: generatorVersion,
        oracleVersion: oracleVersion,
        budget: budget,
        fixture: fixture ?? this.fixture,
        expectedOutcome: expectedOutcome,
        requiredTool: requiredTool,
      );
}

final class HardEdgeManifest {
  HardEdgeManifest({
    required this.schemaVersion,
    required this.catalogVersion,
    required Iterable<HardEdgeCatalogCase> cases,
    required Iterable<HardEdgeMutation> mutations,
  })  : cases = List<HardEdgeCatalogCase>.unmodifiable(cases),
        mutations = List<HardEdgeMutation>.unmodifiable(mutations);

  static const int supportedSchemaVersion = 1;

  final int schemaVersion;
  final String catalogVersion;
  final List<HardEdgeCatalogCase> cases;
  final List<HardEdgeMutation> mutations;

  factory HardEdgeManifest.parse(String source) {
    final Object? decoded;
    try {
      decoded = jsonDecode(source);
    } on FormatException catch (error) {
      throw FormatException('Invalid manifest JSON: ${error.message}');
    }
    final json = _object(decoded, r'$');
    _requireKeys(
      json,
      const {'schemaVersion', 'catalogVersion', 'cases', 'mutations'},
      r'$',
    );
    final schemaVersion = _integer(json['schemaVersion'], r'$.schemaVersion');
    if (schemaVersion != supportedSchemaVersion) {
      throw FormatException(
        r'$.schemaVersion must be 1, got '
        '$schemaVersion.',
      );
    }
    final caseSources = _list(json['cases'], r'$.cases');
    final cases = <HardEdgeCatalogCase>[
      for (var index = 0; index < caseSources.length; index++)
        HardEdgeCatalogCase.parse(caseSources[index], r'$.cases[' '$index]'),
    ];
    final mutationSources = _list(json['mutations'], r'$.mutations');
    final mutations = <HardEdgeMutation>[
      for (var index = 0; index < mutationSources.length; index++)
        HardEdgeMutation.parse(
          mutationSources[index],
          r'$.mutations[' '$index]',
        ),
    ];
    _rejectDuplicateIds(cases.map((value) => value.id), r'$.cases');
    _rejectDuplicateIds(mutations.map((value) => value.id), r'$.mutations');
    return HardEdgeManifest(
      schemaVersion: schemaVersion,
      catalogVersion:
          _nonEmptyString(json['catalogVersion'], r'$.catalogVersion'),
      cases: cases,
      mutations: mutations,
    );
  }

  Map<String, Object?> toJson() => {
        'cases': (cases.toList()..sort((a, b) => a.id.compareTo(b.id)))
            .map((value) => value.toJson())
            .toList(),
        'catalogVersion': catalogVersion,
        'mutations': (mutations.toList()..sort((a, b) => a.id.compareTo(b.id)))
            .map((value) => value.toJson())
            .toList(),
        'schemaVersion': schemaVersion,
      };

  HardEdgeManifest copyWith({
    String? catalogVersion,
    Iterable<HardEdgeCatalogCase>? cases,
    Iterable<HardEdgeMutation>? mutations,
  }) =>
      HardEdgeManifest(
        schemaVersion: schemaVersion,
        catalogVersion: catalogVersion ?? this.catalogVersion,
        cases: cases ?? this.cases,
        mutations: mutations ?? this.mutations,
      );
}

final class HardEdgeCatalog {
  HardEdgeCatalog({
    required Directory repositoryRoot,
    required this.manifestFile,
    required this.manifest,
  }) : repositoryRoot = Directory(_normalize(repositoryRoot.path));

  final Directory repositoryRoot;
  final File manifestFile;
  final HardEdgeManifest manifest;

  static Future<HardEdgeCatalog> load({
    required Directory repositoryRoot,
    required File manifestFile,
  }) async {
    final root = Directory(_normalize(repositoryRoot.path));
    final checkedManifest = _inside(root, manifestFile.path, mustExist: true);
    final manifest =
        HardEdgeManifest.parse(await checkedManifest.readAsString());
    final catalog = HardEdgeCatalog(
      repositoryRoot: root,
      manifestFile: checkedManifest,
      manifest: manifest,
    );
    await catalog.validateFixtures();
    return catalog;
  }

  Future<void> validateFixtures() async {
    final validatedLicenseBases = <String>{};
    for (final testCase in manifest.cases) {
      if (validatedLicenseBases.add(testCase.provenance.licenseBasis)) {
        resolve(testCase.provenance.licenseBasis, mustExist: true);
      }
      final fixture = fixtureFor(testCase);
      if (!fixture.existsSync()) {
        throw FormatException(
          'Fixture ${testCase.fixture} for ${testCase.id} does not exist.',
        );
      }
      final actual = sha256.convert(await fixture.readAsBytes()).toString();
      if (actual != testCase.sha256) {
        throw FormatException(
          'Fixture digest is stale for ${testCase.id}: expected '
          '${testCase.sha256}, got $actual.',
        );
      }
    }
    for (final mutation in manifest.mutations) {
      final fixture = resolve(mutation.fixture, mustExist: true);
      if (!fixture.existsSync()) {
        throw FormatException(
          'Mutation fixture ${mutation.fixture} for ${mutation.id} does not exist.',
        );
      }
      final actual = sha256.convert(await fixture.readAsBytes()).toString();
      if (actual != mutation.sha256) {
        throw FormatException(
          'Mutation fixture digest is stale for ${mutation.id}: expected '
          '${mutation.sha256}, got $actual.',
        );
      }
    }
  }

  File fixtureFor(HardEdgeCatalogCase testCase) =>
      resolve(testCase.fixture, mustExist: true);

  File resolve(String relativePath, {required bool mustExist}) =>
      _inside(repositoryRoot, relativePath, mustExist: mustExist);

  Future<void> writeManifest(HardEdgeManifest updated) async {
    final source = '${const JsonEncoder.withIndent('  ').convert(
      _canonicalize(updated.toJson()),
    )}\n';
    final checkedManifest = _inside(
      repositoryRoot,
      manifestFile.path,
      mustExist: true,
    );
    await checkedManifest.writeAsString(source, flush: true);
  }
}

String hardEdgeSha256(List<int> bytes) => sha256.convert(bytes).toString();

File hardEdgePathInside(
  Directory repositoryRoot,
  String path, {
  required bool mustExist,
}) =>
    _inside(repositoryRoot, path, mustExist: mustExist);

File _inside(Directory root, String path, {required bool mustExist}) {
  final normalizedRoot = _normalize(root.path);
  final resolvedRoot = _resolveExistingPath(normalizedRoot, root.path);
  final candidate = File(path).isAbsolute
      ? File(_normalize(path))
      : File(_normalize('${root.path}${Platform.pathSeparator}$path'));
  final normalizedCandidate = candidate.path;
  if (!_sameOrWithin(normalizedRoot, normalizedCandidate) &&
      !_sameOrWithin(resolvedRoot, normalizedCandidate)) {
    throw FormatException('Path escapes the repository: $path');
  }
  if (mustExist && !candidate.existsSync()) {
    throw FormatException('Required path does not exist: $path');
  }
  final resolvedCandidate = _resolveThroughExistingAncestor(
    normalizedCandidate,
    path,
  );
  if (!_sameOrWithin(resolvedRoot, resolvedCandidate)) {
    throw FormatException('Path resolves outside the repository: $path');
  }
  return File(resolvedCandidate);
}

String _resolveThroughExistingAncestor(String candidate, String displayPath) {
  var ancestor = candidate;
  while (true) {
    final type = FileSystemEntity.typeSync(ancestor, followLinks: false);
    if (type != FileSystemEntityType.notFound) {
      final resolved = _resolveExistingPath(ancestor, displayPath);
      final suffix = candidate.substring(ancestor.length);
      return _normalize('$resolved$suffix');
    }
    final parent = _normalize(File(ancestor).parent.path);
    if (parent == ancestor) {
      throw FormatException('Path cannot be resolved safely: $displayPath');
    }
    ancestor = parent;
  }
}

String _resolveExistingPath(String path, String displayPath) {
  try {
    final type = FileSystemEntity.typeSync(path, followLinks: true);
    return switch (type) {
      FileSystemEntityType.directory =>
        _normalize(Directory(path).resolveSymbolicLinksSync()),
      FileSystemEntityType.file =>
        _normalize(File(path).resolveSymbolicLinksSync()),
      FileSystemEntityType.link =>
        _normalize(Link(path).resolveSymbolicLinksSync()),
      FileSystemEntityType.notFound => throw const FileSystemException(),
      _ => throw const FileSystemException(),
    };
  } on FileSystemException {
    throw FormatException('Path cannot be resolved safely: $displayPath');
  }
}

bool _sameOrWithin(String root, String candidate) {
  final prefix = '$root${Platform.pathSeparator}';
  if (Platform.isWindows) {
    final foldedRoot = root.toLowerCase();
    final foldedCandidate = candidate.toLowerCase();
    return foldedCandidate == foldedRoot ||
        foldedCandidate.startsWith(prefix.toLowerCase());
  }
  return candidate == root || candidate.startsWith(prefix);
}

String _normalize(String path) => File(path)
    .absolute
    .uri
    .normalizePath()
    .toFilePath(windows: Platform.isWindows);

Map<String, Object?> _object(Object? source, String path) {
  if (source is! Map) throw FormatException('$path must be an object.');
  return <String, Object?>{
    for (final entry in source.entries) entry.key.toString(): entry.value,
  };
}

List<Object?> _list(Object? source, String path) {
  if (source is! List) throw FormatException('$path must be an array.');
  return source.cast<Object?>();
}

void _requireKeys(
  Map<String, Object?> json,
  Set<String> expected,
  String path,
) {
  final missing = expected.difference(json.keys.toSet());
  final unknown = json.keys.toSet().difference(expected);
  if (missing.isNotEmpty) {
    throw FormatException(
        '$path is missing keys: ${(missing.toList()..sort()).join(', ')}.');
  }
  if (unknown.isNotEmpty) {
    throw FormatException(
        '$path has unknown keys: ${(unknown.toList()..sort()).join(', ')}.');
  }
}

String _nonEmptyString(Object? source, String path) {
  if (source is! String || source.trim().isEmpty) {
    throw FormatException('$path must be a non-empty string.');
  }
  return source;
}

String _identifier(Object? source, String path) {
  final value = _nonEmptyString(source, path);
  if (!RegExp(r'^[a-z0-9][a-z0-9._-]*$').hasMatch(value)) {
    throw FormatException('$path must be a stable lower-case identifier.');
  }
  return value;
}

String? _nullableString(Object? source, String path) {
  if (source == null) return null;
  return _nonEmptyString(source, path);
}

int _integer(Object? source, String path) {
  if (source is! int) throw FormatException('$path must be an integer.');
  return source;
}

int? _nullableInteger(Object? source, String path) {
  if (source == null) return null;
  return _integer(source, path);
}

bool _boolean(Object? source, String path) {
  if (source is! bool) throw FormatException('$path must be a boolean.');
  return source;
}

List<String> _stringList(Object? source, String path) {
  final values = _list(source, path);
  final result = <String>[];
  for (var index = 0; index < values.length; index++) {
    result.add(_nonEmptyString(values[index], '$path[$index]'));
  }
  if (result.toSet().length != result.length) {
    throw FormatException('$path must not contain duplicates.');
  }
  return result;
}

GenerationBudget _generationBudget(Object? source, String path) {
  final json = _object(source, path);
  const keys = {
    'maxSymbols',
    'maxWordLength',
    'maxStates',
    'maxTransitions',
    'maxProductions',
    'maxRegexNodes',
    'maxTapeCells',
    'maxStackDepth',
    'maxIterations',
  };
  _requireKeys(json, keys, path);
  int bounded(String key, int hardCap) {
    final value = _integer(json[key], '$path.$key');
    if (value < 0 || value > hardCap) {
      throw FormatException('$path.$key must be between 0 and $hardCap.');
    }
    return value;
  }

  return GenerationBudget(
    maxSymbols: bounded('maxSymbols', 256),
    maxWordLength: bounded('maxWordLength', 10000),
    maxStates: bounded('maxStates', 1000),
    maxTransitions: bounded('maxTransitions', 10000),
    maxProductions: bounded('maxProductions', 10000),
    maxRegexNodes: () {
      final value = bounded('maxRegexNodes', 512);
      if (value == 0) {
        throw FormatException('$path.maxRegexNodes must be positive.');
      }
      return value;
    }(),
    maxTapeCells: bounded('maxTapeCells', 10000),
    maxStackDepth: bounded('maxStackDepth', 10000),
    maxIterations: bounded('maxIterations', 1000),
  );
}

T _enumValue<T extends Enum>(List<T> values, Object? source, String path) {
  final name = _nonEmptyString(source, path);
  for (final value in values) {
    if (value.name == name) return value;
  }
  throw FormatException(
    '$path must be one of ${values.map((value) => value.name).join(', ')}.',
  );
}

String _digest(Object? source, String path) {
  final value = _nonEmptyString(source, path);
  if (!RegExp(r'^[a-f0-9]{64}$').hasMatch(value)) {
    throw FormatException('$path must be a lower-case SHA-256 digest.');
  }
  return value;
}

String? _nullableDigest(Object? source, String path) {
  if (source == null) return null;
  return _digest(source, path);
}

String _relativePath(Object? source, String path) {
  final value = _nonEmptyString(source, path);
  if (File(value).isAbsolute || value.split(RegExp(r'[/\\]+')).contains('..')) {
    throw FormatException('$path must stay inside the repository.');
  }
  return value.replaceAll('\\', '/');
}

void _rejectDuplicateIds(Iterable<String> ids, String path) {
  final seen = <String>{};
  for (final id in ids) {
    if (!seen.add(id)) throw FormatException('$path repeats id "$id".');
  }
}

Object? _canonicalize(Object? value) => jsonDecode(canonicalJsonEncode(value));
