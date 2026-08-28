import 'dart:convert';
import 'dart:io';

import 'package:test/test.dart';

import '../../../tool/hard_edge/catalog.dart';
import '../../../tool/hard_edge/models.dart';
import '../../../tool/hard_edge/runner.dart';
import '../../../tool/hard_edge/shrinking.dart';

void main() {
  late Directory temporaryRoot;

  setUp(() async {
    temporaryRoot = await Directory.systemTemp.createTemp('hard-edge-repro-');
  });

  tearDown(() async {
    if (temporaryRoot.existsSync()) {
      await temporaryRoot.delete(recursive: true);
    }
  });

  test('replay compares the typed expected outcome', () async {
    final failure = await _writeArtifact(
      temporaryRoot,
      HardEdgeFailureArtifact(
        testCase: _testCase(expectedOutcome: HardEdgeExpectedOutcome.invalid),
        fixture: const {'outcome': 'pass'},
        minimalFixture: null,
        minimized: false,
      ),
    );

    final result = await replayFailureArtifact(failureFile: failure);

    expect(result.status, HardEdgeCaseStatus.failed);
    expect(result.message, 'Expected invalid, got pass.');
  });

  test('replay fails closed when its declared tool is unavailable', () async {
    final failure = await _writeArtifact(
      temporaryRoot,
      HardEdgeFailureArtifact(
        testCase: _testCase(requiredTool: 'missing-oracle'),
        fixture: const {'outcome': 'pass'},
        minimalFixture: null,
        minimized: false,
      ),
    );

    await expectLater(
      replayFailureArtifact(
        failureFile: failure,
        toolProbe: (_) => false,
      ),
      throwsA(
        isA<HardEdgeMissingToolException>().having(
          (error) => error.tool,
          'tool',
          'missing-oracle',
        ),
      ),
    );
  });

  test('replay rejects a stale standalone fixture digest', () async {
    final failure = await _writeArtifact(
      temporaryRoot,
      HardEdgeFailureArtifact(
        testCase: _testCase(),
        fixture: const {'outcome': 'pass'},
        minimalFixture: null,
        minimized: false,
      ),
    );
    final decoded = jsonDecode(await failure.readAsString()) as Map;
    decoded['fixture'] = {'outcome': 'violation'};
    await failure.writeAsString(jsonEncode(decoded));

    await expectLater(
      replayFailureArtifact(failureFile: failure),
      throwsA(
        isA<FormatException>().having(
          (error) => error.message,
          'message',
          contains('digest is stale'),
        ),
      ),
    );
  });

  test('shrink revalidates candidates and writes a minimized artifact',
      () async {
    final failure = await _writeArtifact(
      temporaryRoot,
      HardEdgeFailureArtifact(
        testCase: _testCase(),
        fixture: const {'outcome': 'violation', 'word': 'aaaa'},
        minimalFixture: const {'outcome': 'violation', 'word': ''},
        minimized: false,
      ),
    );

    final output = await shrinkFailureArtifact(
      repositoryRoot: temporaryRoot,
      failureFile: failure,
      outputPath: 'build/minimized.json',
      executor: const _NonEmptyWordViolationExecutor(),
    );
    final artifact = await readFailureArtifact(output);

    expect(artifact.minimized, isTrue);
    expect(artifact.minimalFixture, isNull);
    expect(artifact.fixture, {'outcome': 'violation', 'word': 'a'});
    final replay = await replayFailureArtifact(
      failureFile: output,
      executor: const _NonEmptyWordViolationExecutor(),
    );
    expect(replay.status, HardEdgeCaseStatus.failed);
    expect(replay.outcome, HardEdgeExecutionOutcome.violation);
  });

  test('promotion rejects an artifact that was not minimized', () async {
    final failure = await _writeArtifact(
      temporaryRoot,
      HardEdgeFailureArtifact(
        testCase: _testCase(),
        fixture: const {'outcome': 'violation'},
        minimalFixture: null,
        minimized: false,
      ),
    );
    final catalog = HardEdgeCatalog(
      repositoryRoot: temporaryRoot,
      manifestFile: File('${temporaryRoot.path}/manifest.json'),
      manifest: HardEdgeManifest(
        schemaVersion: 1,
        catalogVersion: 'test-v1',
        cases: const [],
        mutations: const [],
      ),
    );

    await expectLater(
      promoteFailureArtifact(
        catalog: catalog,
        failureFile: failure,
        regressionIssue: 334,
      ),
      throwsFormatException,
    );
  });

  test('standalone shrink accepts a family-specific shrinker and predicates',
      () async {
    final failure = await _writeArtifact(
      temporaryRoot,
      HardEdgeFailureArtifact(
        testCase: _testCase(),
        fixture: const {'outcome': 'violation', 'word': 'aaaa'},
        minimalFixture: const {
          'outcome': 'violation',
          'word': 'x',
          'invalid': true,
        },
        minimized: false,
      ),
    );

    final output = await shrinkFailureArtifact(
      repositoryRoot: temporaryRoot,
      failureFile: failure,
      outputPath: 'build/typed-minimized.json',
      executor: const _NonEmptyWordViolationExecutor(),
      shrinker: const _WordPairShrinker(),
      isValid: (fixture) =>
          (fixture as Map)['word'] != '' && fixture['invalid'] != true,
      isApplicable: (fixture) => fixture is Map,
    );

    expect(
      (await readFailureArtifact(output)).fixture,
      {'outcome': 'violation', 'word': 'aa'},
    );
  });
}

final class _NonEmptyWordViolationExecutor implements HardEdgePropertyExecutor {
  const _NonEmptyWordViolationExecutor();

  @override
  Future<HardEdgeExecutionOutcome> execute(
    HardEdgeCatalogCase testCase,
    Object? fixture,
  ) async {
    if (fixture is Map &&
        fixture['outcome'] == 'violation' &&
        fixture['word'] is String &&
        (fixture['word'] as String).isNotEmpty) {
      return HardEdgeExecutionOutcome.violation;
    }
    return HardEdgeExecutionOutcome.pass;
  }
}

final class _WordPairShrinker implements DomainShrinker<Object?> {
  const _WordPairShrinker();

  @override
  Iterable<Object?> candidates(Object? value) sync* {
    yield const {'outcome': 'violation', 'word': 'aa'};
  }
}

Future<File> _writeArtifact(
  Directory root,
  HardEdgeFailureArtifact artifact,
) async {
  final file = File('${root.path}/failure.json');
  final json = artifact.toJson();
  final fixture = json['fixture'];
  json['case'] = artifact.testCase
      .copyWith(
        sha256: hardEdgeSha256(
          utf8.encode(canonicalJsonEncode(fixture)),
        ),
      )
      .toJson();
  await file.writeAsString('${jsonEncode(json)}\n');
  return file;
}

HardEdgeCatalogCase _testCase({
  HardEdgeExpectedOutcome expectedOutcome = HardEdgeExpectedOutcome.pass,
  String? requiredTool,
}) =>
    HardEdgeCatalogCase(
      id: 'standalone-case',
      family: 'framework',
      algorithm: 'synthetic-executor',
      sourceKind: HardEdgeSourceKind.generated,
      seed: 334,
      property: 'framework.reproduction',
      provenance: const HardEdgeProvenance(
        origin: 'Independent test fixture',
        independentlyAuthored: true,
        generator: 'test helper',
        licenseBasis: 'LICENSE.txt',
      ),
      license: 'Apache-2.0',
      regressionIssue: null,
      platforms: const ['all'],
      sha256: '0' * 64,
      generatorVersion: 'test-v1',
      oracleVersion: 'test-v1',
      budget: const GenerationBudget(),
      fixture: 'build/failure.json',
      expectedOutcome: expectedOutcome,
      requiredTool: requiredTool,
    );
