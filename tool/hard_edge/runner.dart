import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'catalog.dart';
import 'models.dart';
import 'mutation.dart';
import 'shrinking.dart';

enum HardEdgeExecutionOutcome {
  pass,
  notApplicable,
  bounded,
  violation,
  invalid,
  conflict,
  cancelled,
}

enum HardEdgeCaseStatus { passed, failed, incomplete }

enum HardEdgeRunStatus { passed, failed, incomplete }

final class HardEdgeMissingToolException implements Exception {
  const HardEdgeMissingToolException(this.tool);

  final String tool;

  @override
  String toString() => 'Required local tool is unavailable: $tool';
}

final class HardEdgeConfigurationException extends FormatException {
  const HardEdgeConfigurationException(super.message);
}

abstract interface class HardEdgePropertyExecutor {
  Future<HardEdgeExecutionOutcome> execute(
    HardEdgeCatalogCase testCase,
    Object? fixture,
  );
}

abstract interface class HardEdgeGeneratedPropertyExecutor
    implements HardEdgePropertyExecutor {
  Future<Object?> materialize(
    HardEdgeCatalogCase template,
    Object? templateFixture,
    int seed,
  );
}

final class SyntheticPropertyExecutor
    implements HardEdgeGeneratedPropertyExecutor {
  const SyntheticPropertyExecutor();

  @override
  Future<HardEdgeExecutionOutcome> execute(
    HardEdgeCatalogCase testCase,
    Object? fixture,
  ) async {
    if (fixture is! Map) {
      throw const FormatException('Synthetic fixture must be an object.');
    }
    final delayMilliseconds = fixture['delayMilliseconds'];
    if (delayMilliseconds != null) {
      if (delayMilliseconds is! int || delayMilliseconds < 0) {
        throw const FormatException(
          'delayMilliseconds must be a non-negative integer.',
        );
      }
      await Future<void>.delayed(Duration(milliseconds: delayMilliseconds));
    }
    final outcome = fixture['outcome'];
    if (outcome is! String) {
      throw const FormatException('Synthetic fixture must contain outcome.');
    }
    return switch (outcome) {
      'pass' => HardEdgeExecutionOutcome.pass,
      'notApplicable' => HardEdgeExecutionOutcome.notApplicable,
      'bounded' => HardEdgeExecutionOutcome.bounded,
      'violation' => HardEdgeExecutionOutcome.violation,
      'invalid' => HardEdgeExecutionOutcome.invalid,
      'conflict' => HardEdgeExecutionOutcome.conflict,
      'cancelled' => HardEdgeExecutionOutcome.cancelled,
      _ => throw FormatException('Unknown synthetic outcome "$outcome".'),
    };
  }

  @override
  Future<Object?> materialize(
    HardEdgeCatalogCase template,
    Object? templateFixture,
    int seed,
  ) async {
    if (templateFixture is! Map) {
      throw const FormatException('Synthetic fixture must be an object.');
    }
    return <String, Object?>{
      for (final entry in templateFixture.entries)
        entry.key.toString(): entry.value,
      'seed': seed,
    };
  }
}

final class HardEdgeRunOptions {
  const HardEdgeRunOptions({
    this.family,
    this.property,
    this.seedStart,
    this.seedCount,
    this.repeats = 1,
    this.jobs = 1,
    this.caseTimeout = const Duration(seconds: 5),
    this.maximumCases = 10000,
    this.regressionOnly = false,
  });

  static const int maximumSupportedJobs = 4;
  static const int maximumSupportedRepeats = 20;
  static const int hardCaseCap = 10000;
  static const Duration maximumCaseTimeout = Duration(seconds: 60);

  final String? family;
  final String? property;
  final int? seedStart;
  final int? seedCount;
  final int repeats;
  final int jobs;
  final Duration caseTimeout;
  final int maximumCases;
  final bool regressionOnly;

  void validate() {
    if (family?.trim().isEmpty == true) {
      throw const FormatException('--family must not be empty.');
    }
    if (property?.trim().isEmpty == true) {
      throw const FormatException('--property must not be empty.');
    }
    if (seedStart != null && (seedStart! < 0 || seedStart! > 0xffffffff)) {
      throw const FormatException(
          '--seed-start must be a 32-bit unsigned integer.');
    }
    if (seedCount != null && (seedCount! <= 0 || seedCount! > hardCaseCap)) {
      throw const FormatException('--seed-count must be between 1 and 10000.');
    }
    if (seedCount != null && seedStart == null) {
      throw const FormatException('--seed-count requires --seed-start.');
    }
    if (repeats <= 0 || repeats > maximumSupportedRepeats) {
      throw const FormatException('--repeat must be between 1 and 20.');
    }
    if (jobs <= 0 || jobs > maximumSupportedJobs) {
      throw const FormatException('--jobs must be between 1 and 4.');
    }
    if (caseTimeout <= Duration.zero || caseTimeout > maximumCaseTimeout) {
      throw const FormatException(
          '--timeout-seconds must be between 1 and 60.');
    }
    if (maximumCases <= 0 || maximumCases > hardCaseCap) {
      throw const FormatException('--max-cases must be between 1 and 10000.');
    }
  }

  bool selects(HardEdgeCatalogCase testCase) {
    if (family != null && testCase.family != family) return false;
    if (property != null && testCase.property != property) return false;
    if (seedStart case final start?) {
      final count = seedCount ?? 1;
      final end = start + count;
      if (testCase.seed < start || testCase.seed >= end) return false;
    }
    return true;
  }

  bool selectsDescriptor(HardEdgeCatalogCase testCase) {
    if (family != null && testCase.family != family) return false;
    if (property != null && testCase.property != property) return false;
    if (regressionOnly &&
        testCase.sourceKind != HardEdgeSourceKind.historicalRegression) {
      return false;
    }
    return true;
  }
}

final class HardEdgeCaseResult {
  const HardEdgeCaseResult({
    required this.testCase,
    required this.repeatIndex,
    required this.status,
    required this.outcome,
    required this.message,
    required this.elapsed,
    required this.reproductionCommand,
    required this.fixture,
    required this.fixtureFingerprint,
    required this.fixtureMaterialized,
  });

  final HardEdgeCatalogCase testCase;
  final int repeatIndex;
  final HardEdgeCaseStatus status;
  final HardEdgeExecutionOutcome? outcome;
  final String message;
  final Duration elapsed;
  final String reproductionCommand;
  final Object? fixture;
  final String fixtureFingerprint;
  final bool fixtureMaterialized;

  Map<String, Object?> toJson() => {
        'algorithm': testCase.algorithm,
        'budget': testCase.budget.toJson(),
        'family': testCase.family,
        'fixture': testCase.fixture,
        'fixtureFingerprint': fixtureFingerprint,
        'fixtureMaterialized': fixtureMaterialized,
        'generatorVersion': testCase.generatorVersion,
        'id': testCase.id,
        'message': message,
        'oracleVersion': testCase.oracleVersion,
        'outcome': outcome?.name,
        'property': testCase.property,
        'repeatIndex': repeatIndex,
        'reproductionCommand': reproductionCommand,
        'seed': testCase.seed,
        'status': status.name,
      };
}

final class HardEdgeRunResult {
  HardEdgeRunResult({
    required this.catalogVersion,
    required this.status,
    required Iterable<HardEdgeCaseResult> cases,
    required this.jobs,
    required this.caseTimeout,
    Iterable<String> flakyCaseIds = const [],
  })  : cases = List<HardEdgeCaseResult>.unmodifiable(cases),
        flakyCaseIds = List<String>.unmodifiable(flakyCaseIds);

  final String catalogVersion;
  final HardEdgeRunStatus status;
  final List<HardEdgeCaseResult> cases;
  final int jobs;
  final Duration caseTimeout;
  final List<String> flakyCaseIds;

  Map<String, Object?> toJson() {
    final familyCounts = <String, int>{};
    final propertyCounts = <String, int>{};
    final seedCounts = <String, int>{};
    final uniqueCases = <String, HardEdgeCaseResult>{};
    for (final result in cases) {
      uniqueCases.putIfAbsent(result.testCase.id, () => result);
    }
    for (final result in uniqueCases.values) {
      familyCounts.update(
        result.testCase.family,
        (value) => value + 1,
        ifAbsent: () => 1,
      );
      seedCounts.update(
        result.testCase.seed.toString(),
        (value) => value + 1,
        ifAbsent: () => 1,
      );
      propertyCounts.update(
        result.testCase.property,
        (value) => value + 1,
        ifAbsent: () => 1,
      );
    }
    return {
      'caseTimeoutMicros': caseTimeout.inMicroseconds,
      'cases': cases.map((value) => value.toJson()).toList(),
      'catalogVersion': catalogVersion,
      'coverage': {
        'families': _sortedCounts(familyCounts),
        'properties': _sortedCounts(propertyCounts),
        'seeds': _sortedNumericCounts(seedCounts),
      },
      'flakyCaseIds': flakyCaseIds,
      'jobs': jobs,
      'remotelyVerified': false,
      'status': status.name,
    };
  }
}

typedef HardEdgeToolProbe = FutureOr<bool> Function(String tool);

final class HardEdgeRunner {
  HardEdgeRunner({
    required this.catalog,
    HardEdgePropertyExecutor executor = const SyntheticPropertyExecutor(),
    HardEdgeToolProbe? toolProbe,
  })  : _executor = executor,
        _toolProbe = toolProbe ?? localToolAvailable;

  final HardEdgeCatalog catalog;
  final HardEdgePropertyExecutor _executor;
  final HardEdgeToolProbe _toolProbe;

  Future<HardEdgeRunResult> run(HardEdgeRunOptions options) async {
    options.validate();
    final templates = catalog.manifest.cases
        .where(options.selectsDescriptor)
        .toList()
      ..sort(_compareCases);
    final selected = <(HardEdgeCatalogCase, Future<Object?> Function())>[];
    if (options.seedStart case final seedStart?) {
      final generator = _executor;
      if (generator is! HardEdgeGeneratedPropertyExecutor) {
        throw const HardEdgeConfigurationException(
          'Seed ranges require a generated property executor.',
        );
      }
      final seedCount = options.seedCount ?? 1;
      final generatedCount = templates.length * seedCount;
      if (generatedCount > options.maximumCases) {
        throw HardEdgeConfigurationException(
          'Selection contains $generatedCount generated cases, above '
          '--max-cases ${options.maximumCases}.',
        );
      }
      if (seedStart + seedCount - 1 > 0xffffffff) {
        throw const HardEdgeConfigurationException(
          'Seed range exceeds uint32.',
        );
      }
      for (final template in templates) {
        for (var offset = 0; offset < seedCount; offset++) {
          final seed = seedStart + offset;
          final generated = template.copyWith(
            id: '${template.id}-seed-${seed.toRadixString(16).padLeft(8, '0')}',
            seed: seed,
            sourceKind: HardEdgeSourceKind.generated,
          );
          selected.add((
            generated,
            () async => generator.materialize(
                  template,
                  await _readFixture(catalog.fixtureFor(template)),
                  seed,
                ),
          ));
        }
      }
    } else {
      for (final template in templates.where(options.selects)) {
        selected.add((
          template,
          () => _readFixture(catalog.fixtureFor(template)),
        ));
      }
    }
    if (selected.length > options.maximumCases) {
      throw HardEdgeConfigurationException(
        'Selection contains ${selected.length} cases, above --max-cases '
        '${options.maximumCases}.',
      );
    }
    for (final tool in selected
        .map((value) => value.$1.requiredTool)
        .whereType<String>()
        .toSet()) {
      if (!await _toolProbe(tool)) throw HardEdgeMissingToolException(tool);
    }
    final work = <(HardEdgeCatalogCase, Future<Object?> Function(), int)>[];
    for (final (testCase, materialize) in selected) {
      for (var repeat = 0; repeat < options.repeats; repeat++) {
        work.add((testCase, materialize, repeat));
      }
    }
    final ordered = List<HardEdgeCaseResult?>.filled(work.length, null);
    var nextIndex = 0;
    Future<void> worker() async {
      while (true) {
        final index = nextIndex++;
        if (index >= work.length) return;
        final (testCase, materialize, repeat) = work[index];
        ordered[index] = await _runCase(
          testCase,
          materialize,
          repeat,
          options.caseTimeout,
        );
      }
    }

    await Future.wait([
      for (var index = 0; index < options.jobs && index < work.length; index++)
        worker(),
    ]);
    final results = ordered.whereType<HardEdgeCaseResult>().toList();
    final flakyCaseIds = _findFlakyCaseIds(results);
    return HardEdgeRunResult(
      catalogVersion: catalog.manifest.catalogVersion,
      status:
          flakyCaseIds.isEmpty ? _aggregate(results) : HardEdgeRunStatus.failed,
      cases: results,
      jobs: options.jobs,
      caseTimeout: options.caseTimeout,
      flakyCaseIds: flakyCaseIds,
    );
  }

  Future<HardEdgeCaseResult> _runCase(
    HardEdgeCatalogCase testCase,
    Future<Object?> Function() materialize,
    int repeat,
    Duration timeout,
  ) async {
    final stopwatch = Stopwatch()..start();
    HardEdgeExecutionOutcome? outcome;
    HardEdgeCaseStatus status;
    String message;
    Object? fixture;
    var fixtureMaterialized = false;
    try {
      outcome = await (() async {
        fixture = await materialize();
        fixtureMaterialized = true;
        return _executor.execute(testCase, fixture);
      })()
          .timeout(timeout);
      (status, message) = _classifyOutcome(testCase, outcome);
    } on TimeoutException {
      status = HardEdgeCaseStatus.failed;
      message = 'The test runner exceeded its per-case timeout.';
    } on FormatException catch (error) {
      status = HardEdgeCaseStatus.failed;
      message = 'Fixture or executor error: ${error.message}';
    } catch (error) {
      status = HardEdgeCaseStatus.failed;
      message = 'Executor threw ${error.runtimeType}: $error';
    }
    stopwatch.stop();
    return HardEdgeCaseResult(
      testCase: testCase,
      repeatIndex: repeat,
      status: status,
      outcome: outcome,
      message: message,
      elapsed: stopwatch.elapsed,
      reproductionCommand: 'dart run tool/hard_edge_cases.dart run --family '
          '${testCase.family} --property ${testCase.property} '
          '--seed ${testCase.seed}',
      fixture: fixture,
      fixtureFingerprint: _fixtureFingerprint(fixture),
      fixtureMaterialized: fixtureMaterialized,
    );
  }
}

final class HardEdgeMutationRunResult {
  HardEdgeMutationRunResult({
    required this.status,
    required Iterable<HardEdgeMutationResult> mutations,
  }) : mutations = List<HardEdgeMutationResult>.unmodifiable(mutations);

  final HardEdgeRunStatus status;
  final List<HardEdgeMutationResult> mutations;

  Map<String, Object?> toJson() => {
        'mutations': mutations.map((value) => value.toJson()).toList(),
        'remotelyVerified': false,
        'status': status.name,
      };
}

final class HardEdgeMutationRunner {
  HardEdgeMutationRunner({
    required this.catalog,
    HardEdgeMutationExecutor executor = const SyntheticMutationExecutor(),
    HardEdgeToolProbe? toolProbe,
  })  : _executor = executor,
        _toolProbe = toolProbe ?? localToolAvailable;

  final HardEdgeCatalog catalog;
  final HardEdgeMutationExecutor _executor;
  final HardEdgeToolProbe _toolProbe;

  Future<HardEdgeMutationRunResult> run({
    String? family,
    String? property,
  }) async {
    final selected = catalog.manifest.mutations
        .where((value) => family == null || value.family == family)
        .where((value) => property == null || value.property == property)
        .toList()
      ..sort((left, right) => left.id.compareTo(right.id));
    for (final tool in selected
        .map((value) => value.requiredTool)
        .whereType<String>()
        .toSet()) {
      if (!await _toolProbe(tool)) throw HardEdgeMissingToolException(tool);
    }
    final results = <HardEdgeMutationResult>[];
    for (final mutation in selected) {
      try {
        final fixture = await readMutationFixture(
          catalog.resolve(mutation.fixture, mustExist: true),
        );
        final status = await _executor.execute(mutation, fixture);
        results.add(
          HardEdgeMutationResult(
            mutation: mutation,
            status: status,
            message: switch (status) {
              HardEdgeMutationStatus.killed =>
                'The property killed the mutant.',
              HardEdgeMutationStatus.survived => 'The mutant survived.',
              HardEdgeMutationStatus.notRun => 'The mutant was not applicable.',
            },
          ),
        );
      } catch (error) {
        results.add(
          HardEdgeMutationResult(
            mutation: mutation,
            status: HardEdgeMutationStatus.survived,
            message: 'Mutation executor error: $error',
          ),
        );
      }
    }
    final status = results.any(
      (value) => value.status == HardEdgeMutationStatus.survived,
    )
        ? HardEdgeRunStatus.failed
        : results.isEmpty ||
                results.any(
                  (value) => value.status == HardEdgeMutationStatus.notRun,
                )
            ? HardEdgeRunStatus.incomplete
            : HardEdgeRunStatus.passed;
    return HardEdgeMutationRunResult(status: status, mutations: results);
  }
}

final class HardEdgeFailureArtifact {
  const HardEdgeFailureArtifact({
    required this.testCase,
    required this.fixture,
    required this.minimalFixture,
    required this.minimized,
  });

  final HardEdgeCatalogCase testCase;
  final Object? fixture;
  final Object? minimalFixture;
  final bool minimized;

  factory HardEdgeFailureArtifact.parse(String source) {
    final decoded = jsonDecode(source);
    if (decoded is! Map) {
      throw const FormatException('Failure artifact must be an object.');
    }
    final json = <String, Object?>{
      for (final entry in decoded.entries) entry.key.toString(): entry.value,
    };
    const expected = {
      'schemaVersion',
      'case',
      'fixture',
      'minimalFixture',
      'minimized',
    };
    if (json.keys.toSet().difference(expected).isNotEmpty ||
        expected.difference(json.keys.toSet()).isNotEmpty) {
      throw const FormatException('Failure artifact has an invalid schema.');
    }
    if (json['schemaVersion'] != 1) {
      throw const FormatException('Unsupported failure artifact schema.');
    }
    if (json['minimized'] is! bool) {
      throw const FormatException('Failure artifact minimized must be bool.');
    }
    final testCase = HardEdgeCatalogCase.parse(json['case'], r'$.case');
    final fixture = json['fixture'];
    final fixtureFingerprint = _fixtureFingerprint(fixture);
    if (testCase.sha256 != fixtureFingerprint) {
      throw const FormatException(
        'Failure artifact fixture digest is stale.',
      );
    }
    return HardEdgeFailureArtifact(
      testCase: testCase,
      fixture: fixture,
      minimalFixture: json['minimalFixture'],
      minimized: json['minimized']! as bool,
    );
  }

  Map<String, Object?> toJson() => {
        'case': testCase.toJson(),
        'fixture': fixture,
        'minimized': minimized,
        'minimalFixture': minimalFixture,
        'schemaVersion': 1,
      };
}

Future<HardEdgeFailureArtifact> readFailureArtifact(File file) async {
  try {
    return HardEdgeFailureArtifact.parse(await file.readAsString());
  } on FormatException catch (error) {
    throw FormatException(
        'Invalid failure artifact ${file.path}: ${error.message}');
  }
}

Future<File> shrinkFailureArtifact({
  required Directory repositoryRoot,
  required File failureFile,
  required String outputPath,
  HardEdgePropertyExecutor executor = const SyntheticPropertyExecutor(),
  HardEdgeToolProbe? toolProbe,
  Duration timeout = const Duration(seconds: 5),
  int maxAttempts = 10000,
  DomainShrinker<Object?>? shrinker,
  FutureOr<bool> Function(Object? fixture)? isValid,
  FutureOr<bool> Function(Object? fixture)? isApplicable,
}) async {
  final checkedFailure =
      hardEdgePathInside(repositoryRoot, failureFile.path, mustExist: true);
  final artifact = await readFailureArtifact(checkedFailure);
  final probe = toolProbe ?? localToolAvailable;
  if (artifact.testCase.requiredTool case final tool?) {
    if (!await probe(tool)) throw HardEdgeMissingToolException(tool);
  }
  final original = await _evaluateFixture(
    testCase: artifact.testCase,
    fixture: artifact.fixture,
    executor: executor,
    timeout: timeout,
    reproductionCommand:
        'dart run tool/hard_edge_cases.dart replay --fixture ${failureFile.path}',
  );
  if (original.status != HardEdgeCaseStatus.failed) {
    throw const FormatException(
      'Failure artifact does not currently reproduce a failure.',
    );
  }

  Future<bool> reproduces(Object? fixture) async {
    final candidate = await _evaluateFixture(
      testCase: artifact.testCase,
      fixture: fixture,
      executor: executor,
      timeout: timeout,
      reproductionCommand: 'shrink-candidate',
    );
    return candidate.status == HardEdgeCaseStatus.failed &&
        candidate.outcome == original.outcome &&
        (original.outcome != null ||
            _failureKind(candidate.message) == _failureKind(original.message));
  }

  Future<bool> allowed(Object? fixture) async =>
      (await isValid?.call(fixture) ?? true) &&
      (await isApplicable?.call(fixture) ?? true);

  if (!await allowed(artifact.fixture)) {
    throw const FormatException(
      'Failure artifact does not satisfy the shrink predicates.',
    );
  }

  var initial = artifact.fixture;
  final preferred = artifact.minimalFixture;
  if (preferred != null &&
      await allowed(preferred) &&
      await reproduces(preferred)) {
    initial = preferred;
  }
  final source = GeneratedCase<Object?>(
    family: artifact.testCase.family,
    property: artifact.testCase.property,
    generatorVersion: artifact.testCase.generatorVersion,
    streamId: '${artifact.testCase.family}/${artifact.testCase.property}/'
        '${artifact.testCase.generatorVersion}',
    seed: artifact.testCase.seed,
    caseIndex: 0,
    mode: GenerationMode.valid,
    budget: artifact.testCase.budget,
    value: initial,
    encodeValue: (value) => value,
  );
  final shrunk = await shrinkFailureAsync<Object?>(
    source: source,
    shrinker: shrinker ??
        JsonValueShrinker(
          preferredCandidate:
              identical(initial, artifact.fixture) ? preferred : null,
        ),
    stillFails: reproduces,
    isValid:
        isValid == null ? null : (candidate) async => await isValid(candidate),
    isApplicable: isApplicable == null
        ? null
        : (candidate) async => await isApplicable(candidate),
    maxAttempts: maxAttempts,
  );
  final minimized = HardEdgeFailureArtifact(
    testCase: artifact.testCase.copyWith(
      sha256: _fixtureFingerprint(shrunk.minimalValue),
    ),
    fixture: shrunk.minimalValue,
    minimalFixture: null,
    minimized: true,
  );
  final output = hardEdgePathInside(
    repositoryRoot,
    outputPath,
    mustExist: false,
  );
  await output.parent.create(recursive: true);
  await output.writeAsString(
    '${const JsonEncoder.withIndent('  ').convert(jsonDecode(canonicalJsonEncode(minimized.toJson())))}\n',
    flush: true,
  );
  return output;
}

Future<HardEdgeCatalogCase> promoteFailureArtifact({
  required HardEdgeCatalog catalog,
  required File failureFile,
  required int regressionIssue,
  HardEdgePropertyExecutor executor = const SyntheticPropertyExecutor(),
  HardEdgeToolProbe? toolProbe,
  Duration timeout = const Duration(seconds: 5),
}) async {
  if (regressionIssue <= 0) {
    throw const FormatException('--issue must be a positive integer.');
  }
  final checkedFailure = hardEdgePathInside(
    catalog.repositoryRoot,
    failureFile.path,
    mustExist: true,
  );
  final artifact = await readFailureArtifact(checkedFailure);
  if (!artifact.minimized || artifact.minimalFixture != null) {
    throw const FormatException(
      'Promotion requires a validated minimized failure artifact.',
    );
  }
  final probe = toolProbe ?? localToolAvailable;
  if (artifact.testCase.requiredTool case final tool?) {
    if (!await probe(tool)) throw HardEdgeMissingToolException(tool);
  }
  final replay = await _evaluateFixture(
    testCase: artifact.testCase,
    fixture: artifact.fixture,
    executor: executor,
    timeout: timeout,
    reproductionCommand: 'promotion-validation',
  );
  if (replay.status != HardEdgeCaseStatus.failed) {
    throw const FormatException(
      'Promoted fixture does not currently reproduce a failure.',
    );
  }
  if (catalog.manifest.cases.any((value) => value.id == artifact.testCase.id)) {
    throw FormatException(
      'Catalog already contains case ${artifact.testCase.id}.',
    );
  }
  final relative =
      'test/fixtures/hard_edge/regressions/${artifact.testCase.id}.json';
  final destination = catalog.resolve(relative, mustExist: false);
  if (destination.existsSync()) {
    throw FormatException('Promotion target already exists: $relative');
  }
  await destination.parent.create(recursive: true);
  final bytes = utf8.encode('${canonicalJsonEncode(artifact.fixture)}\n');
  await destination.writeAsBytes(bytes, flush: true);
  final promoted = HardEdgeCatalogCase(
    id: artifact.testCase.id,
    family: artifact.testCase.family,
    algorithm: artifact.testCase.algorithm,
    sourceKind: HardEdgeSourceKind.historicalRegression,
    seed: artifact.testCase.seed,
    property: artifact.testCase.property,
    provenance: artifact.testCase.provenance,
    license: artifact.testCase.license,
    regressionIssue: regressionIssue,
    platforms: artifact.testCase.platforms,
    sha256: hardEdgeSha256(bytes),
    generatorVersion: artifact.testCase.generatorVersion,
    oracleVersion: artifact.testCase.oracleVersion,
    budget: artifact.testCase.budget,
    fixture: relative,
    expectedOutcome: artifact.testCase.expectedOutcome,
    requiredTool: artifact.testCase.requiredTool,
  );
  final cases = [...catalog.manifest.cases, promoted]
    ..sort((left, right) => left.id.compareTo(right.id));
  await catalog.writeManifest(
    catalog.manifest.copyWith(
      catalogVersion:
          '${catalog.manifest.catalogVersion}-regression-$regressionIssue',
      cases: cases,
    ),
  );
  return promoted;
}

Future<HardEdgeCaseResult> replayFailureArtifact({
  required File failureFile,
  HardEdgePropertyExecutor executor = const SyntheticPropertyExecutor(),
  HardEdgeToolProbe? toolProbe,
  Duration timeout = const Duration(seconds: 5),
}) async {
  final artifact = await readFailureArtifact(failureFile);
  final probe = toolProbe ?? localToolAvailable;
  if (artifact.testCase.requiredTool case final tool?) {
    if (!await probe(tool)) throw HardEdgeMissingToolException(tool);
  }
  return _evaluateFixture(
    testCase: artifact.testCase,
    fixture: artifact.fixture,
    executor: executor,
    timeout: timeout,
    reproductionCommand:
        'dart run tool/hard_edge_cases.dart replay --fixture ${failureFile.path}',
  );
}

Future<Object?> _readFixture(File file) async {
  try {
    return jsonDecode(await file.readAsString());
  } on FormatException catch (error) {
    throw FormatException('Invalid fixture ${file.path}: ${error.message}');
  }
}

int _compareCases(HardEdgeCatalogCase left, HardEdgeCatalogCase right) {
  final family = left.family.compareTo(right.family);
  if (family != 0) return family;
  final property = left.property.compareTo(right.property);
  if (property != 0) return property;
  final seed = left.seed.compareTo(right.seed);
  if (seed != 0) return seed;
  return left.id.compareTo(right.id);
}

HardEdgeRunStatus _aggregate(List<HardEdgeCaseResult> results) {
  if (results.any((value) => value.status == HardEdgeCaseStatus.failed)) {
    return HardEdgeRunStatus.failed;
  }
  if (results.isEmpty ||
      results.any((value) => value.status == HardEdgeCaseStatus.incomplete)) {
    return HardEdgeRunStatus.incomplete;
  }
  return HardEdgeRunStatus.passed;
}

List<String> _findFlakyCaseIds(List<HardEdgeCaseResult> results) {
  final signatures = <String, Set<String>>{};
  for (final result in results) {
    signatures.putIfAbsent(result.testCase.id, () => <String>{}).add(
          '${result.status.name}:${result.outcome?.name ?? 'runnerError'}:'
          '${result.fixtureFingerprint}:${result.message}',
        );
  }
  return signatures.entries
      .where((entry) => entry.value.length > 1)
      .map((entry) => entry.key)
      .toList()
    ..sort();
}

Map<String, int> _sortedCounts(Map<String, int> counts) => {
      for (final key in counts.keys.toList()..sort()) key: counts[key]!,
    };

Map<String, int> _sortedNumericCounts(Map<String, int> counts) => {
      for (final key
          in counts.keys.toList()
            ..sort(
                (left, right) => int.parse(left).compareTo(int.parse(right))))
        key: counts[key]!,
    };

(HardEdgeCaseStatus, String) _classifyOutcome(
  HardEdgeCatalogCase testCase,
  HardEdgeExecutionOutcome outcome,
) {
  final expected = HardEdgeExecutionOutcome.values.byName(
    testCase.expectedOutcome.name,
  );
  if (outcome == HardEdgeExecutionOutcome.violation) {
    return (HardEdgeCaseStatus.failed, 'The property was violated.');
  }
  if (outcome == HardEdgeExecutionOutcome.notApplicable ||
      outcome == HardEdgeExecutionOutcome.bounded ||
      outcome == HardEdgeExecutionOutcome.cancelled) {
    return (
      HardEdgeCaseStatus.incomplete,
      'The selected property did not produce a definitive result.',
    );
  }
  if (outcome != expected) {
    return (
      HardEdgeCaseStatus.failed,
      'Expected ${expected.name}, got ${outcome.name}.',
    );
  }
  return (
    HardEdgeCaseStatus.passed,
    'The property matched the typed expected outcome.',
  );
}

Future<HardEdgeCaseResult> _evaluateFixture({
  required HardEdgeCatalogCase testCase,
  required Object? fixture,
  required HardEdgePropertyExecutor executor,
  required Duration timeout,
  required String reproductionCommand,
}) async {
  final stopwatch = Stopwatch()..start();
  HardEdgeExecutionOutcome? outcome;
  HardEdgeCaseStatus status;
  String message;
  try {
    outcome = await executor.execute(testCase, fixture).timeout(timeout);
    (status, message) = _classifyOutcome(testCase, outcome);
  } on TimeoutException {
    status = HardEdgeCaseStatus.failed;
    message = 'The test runner exceeded its per-case timeout.';
  } on FormatException catch (error) {
    status = HardEdgeCaseStatus.failed;
    message = 'Fixture or executor error: ${error.message}';
  } catch (error) {
    status = HardEdgeCaseStatus.failed;
    message = 'Executor threw ${error.runtimeType}: $error';
  }
  stopwatch.stop();
  return HardEdgeCaseResult(
    testCase: testCase,
    repeatIndex: 0,
    status: status,
    outcome: outcome,
    message: message,
    elapsed: stopwatch.elapsed,
    reproductionCommand: reproductionCommand,
    fixture: fixture,
    fixtureFingerprint: _fixtureFingerprint(fixture),
    fixtureMaterialized: true,
  );
}

String _fixtureFingerprint(Object? fixture) {
  try {
    return hardEdgeSha256(utf8.encode(canonicalJsonEncode(fixture)));
  } catch (error) {
    return 'unencodable:${error.runtimeType}';
  }
}

String _failureKind(String message) => message.split(':').first;

Future<bool> localToolAvailable(String tool) async {
  if (tool.trim().isEmpty) return false;
  if (tool == 'flutter' && File('/opt/homebrew/bin/flutter').existsSync()) {
    return true;
  }
  final command = Platform.isWindows ? 'where.exe' : 'sh';
  final arguments =
      Platform.isWindows ? [tool] : ['-c', r'command -v "$1"', '_', tool];
  try {
    final result = await Process.run(command, arguments);
    return result.exitCode == 0;
  } on ProcessException {
    return false;
  }
}
