import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:test/test.dart';

import '../../../tool/hard_edge/catalog.dart';
import '../../../tool/hard_edge/models.dart';
import '../../../tool/hard_edge/mutation.dart';
import '../../../tool/hard_edge/report.dart';
import '../../../tool/hard_edge/runner.dart';

void main() {
  late Directory temporaryRoot;

  setUp(() async {
    temporaryRoot = await Directory.systemTemp.createTemp('hard-edge-test-');
    await File('${temporaryRoot.path}${Platform.pathSeparator}pubspec.yaml')
        .writeAsString('name: hard_edge_test\n');
  });

  tearDown(() async {
    if (temporaryRoot.existsSync()) {
      await temporaryRoot.delete(recursive: true);
    }
  });

  test('strict catalog rejects a stale fixture digest', () async {
    final setup = await _writeCatalog(temporaryRoot, digestOverride: '0' * 64);

    await expectLater(
      HardEdgeCatalog.load(
        repositoryRoot: temporaryRoot,
        manifestFile: setup.manifest,
      ),
      throwsA(
        isA<FormatException>().having(
          (error) => error.message,
          'message',
          contains('digest is stale'),
        ),
      ),
    );
  });

  test('catalog and output paths cannot escape the repository', () {
    expect(
      () => hardEdgePathInside(
        temporaryRoot,
        '../outside.json',
        mustExist: false,
      ),
      throwsFormatException,
    );
  });

  test('canonical paths inside a linked repository remain inside', () async {
    final repository = Directory(
      '${temporaryRoot.path}${Platform.pathSeparator}repository',
    );
    await repository.create();
    final linkedRepository = Link(
      '${temporaryRoot.path}${Platform.pathSeparator}repository-link',
    );
    await linkedRepository.create(repository.path);
    final fixture = File(
      '${repository.path}${Platform.pathSeparator}fixture.json',
    );
    await fixture.writeAsString('{}');
    final canonicalFixture = await fixture.resolveSymbolicLinks();

    final resolved = hardEdgePathInside(
      Directory(linkedRepository.path),
      canonicalFixture,
      mustExist: true,
    );

    expect(await resolved.resolveSymbolicLinks(), canonicalFixture);
  });

  test('output paths cannot escape through a pre-existing directory link',
      () async {
    final outside = await Directory.systemTemp.createTemp('hard-edge-outside-');
    addTearDown(() async {
      if (outside.existsSync()) await outside.delete(recursive: true);
    });
    final linked = Directory(
      '${temporaryRoot.path}${Platform.pathSeparator}linked-output',
    );
    await _createDirectoryLink(linked, outside);

    expect(
      () => hardEdgePathInside(
        temporaryRoot,
        'linked-output/result.json',
        mustExist: false,
      ),
      throwsA(
        isA<FormatException>().having(
          (error) => error.message,
          'message',
          contains('resolves outside the repository'),
        ),
      ),
    );
  });

  test('source kind, licensing, and provenance combinations are strict', () {
    final independent = _caseJson(
      id: 'source-case',
      fixture: 'test/fixtures/hard_edge/case.json',
      digest: '0' * 64,
    );
    final provenance = independent['provenance'] as Map<String, Object?>;
    provenance['independentlyAuthored'] = false;
    expect(
      () => HardEdgeCatalogCase.parse(independent, r'$.case'),
      throwsFormatException,
    );

    final jflap = _caseJson(
      id: 'jflap-case',
      fixture: 'test/fixtures/hard_edge/case.json',
      digest: '0' * 64,
      sourceKind: 'jflapDerived',
    );
    final jflapProvenance = jflap['provenance'] as Map<String, Object?>;
    jflapProvenance['independentlyAuthored'] = false;
    jflapProvenance['jflapVersion'] = '7.1';
    jflap['license'] = 'LicenseRef-JFLAP-7.1';
    jflapProvenance['licenseBasis'] = 'LICENSE_JFLAP.txt';
    expect(
      () => HardEdgeCatalogCase.parse(jflap, r'$.case'),
      throwsFormatException,
    );

    final historical = _caseJson(
      id: 'historical-case',
      fixture: 'test/fixtures/hard_edge/case.json',
      digest: '0' * 64,
      sourceKind: 'historicalRegression',
      regressionIssue: null,
    );
    expect(
      () => HardEdgeCatalogCase.parse(historical, r'$.case'),
      throwsFormatException,
    );

    final invalidLicense = _caseJson(
      id: 'license-case',
      fixture: 'test/fixtures/hard_edge/case.json',
      digest: '0' * 64,
    )..['license'] = 'Made-Up-1.0';
    expect(
      () => HardEdgeCatalogCase.parse(invalidLicense, r'$.case'),
      throwsFormatException,
    );

    jflapProvenance['sourceRevision'] = 'JFLAP 7.1 source release';
    jflapProvenance['sourceSha256'] = 'a' * 64;
    expect(
      HardEdgeCatalogCase.parse(jflap, r'$.case').provenance.sourceRevision,
      'JFLAP 7.1 source release',
    );
  });

  test('bounded evidence is incomplete and never passes', () async {
    final setup = await _writeCatalog(
      temporaryRoot,
      fixture: const {'outcome': 'bounded'},
      expectedOutcome: 'bounded',
    );
    final catalog = await _load(temporaryRoot, setup.manifest);

    final result = await HardEdgeRunner(catalog: catalog).run(
      const HardEdgeRunOptions(),
    );

    expect(result.status, HardEdgeRunStatus.incomplete);
    expect(result.cases.single.status, HardEdgeCaseStatus.incomplete);
    expect(result.cases.single.outcome, HardEdgeExecutionOutcome.bounded);
  });

  test('required local tool fails closed before property execution', () async {
    final setup = await _writeCatalog(
      temporaryRoot,
      requiredTool: 'missing-local-oracle',
    );
    final catalog = await _load(temporaryRoot, setup.manifest);

    await expectLater(
      HardEdgeRunner(
        catalog: catalog,
        toolProbe: (_) => false,
      ).run(const HardEdgeRunOptions()),
      throwsA(
        isA<HardEdgeMissingToolException>().having(
          (error) => error.tool,
          'tool',
          'missing-local-oracle',
        ),
      ),
    );
  });

  test('explicit promotion writes a regression fixture and updates manifest',
      () async {
    final setup = await _writeCatalog(temporaryRoot);
    final catalog = await _load(temporaryRoot, setup.manifest);
    final promotedCase = _caseJson(
      id: 'promoted-regression',
      fixture: 'build/hard-edge/generated.json',
      digest: '0' * 64,
      sourceKind: 'generated',
      regressionIssue: null,
    );
    const failureFixture = {'outcome': 'violation', 'word': 'aa'};
    promotedCase['sha256'] = hardEdgeSha256(
      utf8.encode(canonicalJsonEncode(failureFixture)),
    );
    final failure = File(
      '${temporaryRoot.path}${Platform.pathSeparator}build'
      '${Platform.pathSeparator}hard-edge${Platform.pathSeparator}failure.json',
    );
    await failure.parent.create(recursive: true);
    await failure.writeAsString(
      jsonEncode({
        'schemaVersion': 1,
        'case': promotedCase,
        'fixture': failureFixture,
        'minimalFixture': {'outcome': 'violation', 'word': 'a'},
        'minimized': false,
      }),
    );

    final minimized = await shrinkFailureArtifact(
      repositoryRoot: temporaryRoot,
      failureFile: failure,
      outputPath: 'build/hard-edge/minimized.json',
    );

    final promoted = await promoteFailureArtifact(
      catalog: catalog,
      failureFile: minimized,
      regressionIssue: 334,
    );

    expect(promoted.sourceKind, HardEdgeSourceKind.historicalRegression);
    expect(promoted.regressionIssue, 334);
    final fixture = File(
      '${temporaryRoot.path}${Platform.pathSeparator}'
      '${promoted.fixture.replaceAll('/', Platform.pathSeparator)}',
    );
    expect(fixture.existsSync(), isTrue);
    expect(jsonDecode(await fixture.readAsString()), {
      'outcome': 'violation',
    });
    final updated = HardEdgeManifest.parse(await setup.manifest.readAsString());
    expect(updated.cases.map((value) => value.id),
        contains('promoted-regression'));
    final reloaded = await _load(temporaryRoot, setup.manifest);
    expect(
      reloaded.manifest.cases.map((value) => value.id),
      contains('promoted-regression'),
    );
  });

  test('surviving mutation fails and is recorded in stable reports', () async {
    final setup = await _writeCatalog(
      temporaryRoot,
      mutationStatus: 'survived',
    );
    final catalog = await _load(temporaryRoot, setup.manifest);

    final result = await HardEdgeMutationRunner(catalog: catalog).run();

    expect(result.status, HardEdgeRunStatus.failed);
    expect(result.mutations.single.status, HardEdgeMutationStatus.survived);
    final output = Directory(
      '${temporaryRoot.path}${Platform.pathSeparator}build'
      '${Platform.pathSeparator}reports',
    );
    await const HardEdgeReportWriter().writeMutation(
      result,
      outputDirectory: output,
    );
    final decoded = jsonDecode(
      await File(
        '${output.path}${Platform.pathSeparator}mutation-report.json',
      ).readAsString(),
    ) as Map<String, dynamic>;
    expect(decoded['remotelyVerified'], isFalse);
    expect(decoded['status'], 'failed');
    expect(
      await File(
        '${output.path}${Platform.pathSeparator}mutation-report.md',
      ).readAsString(),
      contains('`survived`'),
    );
  });

  test('report ordering and reproduction command are deterministic', () async {
    final setup = await _writeCatalog(temporaryRoot);
    final catalog = await _load(temporaryRoot, setup.manifest);
    final result = await HardEdgeRunner(catalog: catalog).run(
      const HardEdgeRunOptions(repeats: 2),
    );
    final repeated = await HardEdgeRunner(catalog: catalog).run(
      const HardEdgeRunOptions(repeats: 2),
    );
    const writer = HardEdgeReportWriter();

    expect(result.status, HardEdgeRunStatus.passed);
    expect(result.cases, hasLength(2));
    expect(
      result.cases
          .singleWhere((value) => value.repeatIndex == 0)
          .reproductionCommand,
      contains('--seed 334'),
    );
    expect(writer.renderRunMarkdown(result), writer.renderRunMarkdown(result));
    expect(jsonEncode(result.toJson()), jsonEncode(repeated.toJson()));
    expect(result.toJson()['remotelyVerified'], isFalse);
    expect(
      (result.toJson()['coverage'] as Map)['families'],
      {'framework': 1},
    );
    expect((result.toJson()['coverage'] as Map)['seeds'], {'334': 1});
  });

  test('repeat mode fails when the same seed changes outcome', () async {
    final setup = await _writeCatalog(temporaryRoot);
    final catalog = await _load(temporaryRoot, setup.manifest);
    final result = await HardEdgeRunner(
      catalog: catalog,
      executor: _AlternatingExecutor(),
    ).run(const HardEdgeRunOptions(repeats: 2));

    expect(result.status, HardEdgeRunStatus.failed);
    expect(result.flakyCaseIds, ['framework-case']);
    expect(result.toJson()['flakyCaseIds'], ['framework-case']);
  });

  test('repeat mode rematerializes and detects unstable fixture bytes',
      () async {
    final setup = await _writeCatalog(temporaryRoot);
    final catalog = await _load(temporaryRoot, setup.manifest);
    final result = await HardEdgeRunner(
      catalog: catalog,
      executor: _UnstableMaterializer(),
    ).run(
      const HardEdgeRunOptions(seedStart: 334, repeats: 2),
    );

    expect(result.status, HardEdgeRunStatus.failed);
    expect(result.cases.map((value) => value.outcome),
        everyElement(HardEdgeExecutionOutcome.pass));
    expect(result.flakyCaseIds, ['framework-case-seed-0000014e']);
    expect(
      result.cases.map((value) => value.fixtureFingerprint).toSet(),
      hasLength(2),
    );
  });

  test('case timeout includes asynchronous fixture materialization', () async {
    final setup = await _writeCatalog(temporaryRoot);
    final catalog = await _load(temporaryRoot, setup.manifest);
    final result = await HardEdgeRunner(
      catalog: catalog,
      executor: const _NeverMaterializes(),
    ).run(
      const HardEdgeRunOptions(
        seedStart: 334,
        caseTimeout: Duration(milliseconds: 10),
      ),
    );

    expect(result.status, HardEdgeRunStatus.failed);
    expect(result.cases.single.status, HardEdgeCaseStatus.failed);
    expect(result.cases.single.message, contains('per-case timeout'));
  });

  test('seed ranges materialize deterministic cases instead of only filtering',
      () async {
    final setup = await _writeCatalog(temporaryRoot);
    final catalog = await _load(temporaryRoot, setup.manifest);
    const options = HardEdgeRunOptions(seedStart: 10, seedCount: 3, jobs: 2);

    final first = await HardEdgeRunner(catalog: catalog).run(options);
    final second = await HardEdgeRunner(catalog: catalog).run(options);

    expect(first.status, HardEdgeRunStatus.passed);
    expect(first.cases.map((value) => value.testCase.seed), [10, 11, 12]);
    expect(jsonEncode(first.toJson()), jsonEncode(second.toJson()));
  });
}

final class _AlternatingExecutor implements HardEdgePropertyExecutor {
  var _calls = 0;

  @override
  Future<HardEdgeExecutionOutcome> execute(
    HardEdgeCatalogCase testCase,
    Object? fixture,
  ) async =>
      (_calls++).isEven
          ? HardEdgeExecutionOutcome.pass
          : HardEdgeExecutionOutcome.bounded;
}

final class _UnstableMaterializer implements HardEdgeGeneratedPropertyExecutor {
  var _materializations = 0;

  @override
  Future<Object?> materialize(
    HardEdgeCatalogCase template,
    Object? templateFixture,
    int seed,
  ) async =>
      {
        'outcome': 'pass',
        'seed': seed,
        'materialization': _materializations++,
      };

  @override
  Future<HardEdgeExecutionOutcome> execute(
    HardEdgeCatalogCase testCase,
    Object? fixture,
  ) async =>
      HardEdgeExecutionOutcome.pass;
}

final class _NeverMaterializes implements HardEdgeGeneratedPropertyExecutor {
  const _NeverMaterializes();

  @override
  Future<Object?> materialize(
    HardEdgeCatalogCase template,
    Object? templateFixture,
    int seed,
  ) =>
      Completer<Object?>().future;

  @override
  Future<HardEdgeExecutionOutcome> execute(
    HardEdgeCatalogCase testCase,
    Object? fixture,
  ) async =>
      HardEdgeExecutionOutcome.pass;
}

Future<HardEdgeCatalog> _load(Directory root, File manifest) =>
    HardEdgeCatalog.load(repositoryRoot: root, manifestFile: manifest);

Future<_CatalogSetup> _writeCatalog(
  Directory root, {
  Map<String, Object?> fixture = const {'outcome': 'pass'},
  String expectedOutcome = 'pass',
  String? requiredTool,
  String? digestOverride,
  String mutationStatus = 'killed',
}) async {
  await File(
    '${root.path}${Platform.pathSeparator}LICENSE.txt',
  ).writeAsString('Apache License 2.0 test basis\n');
  final fixtureFile = File(
    '${root.path}${Platform.pathSeparator}test${Platform.pathSeparator}fixtures'
    '${Platform.pathSeparator}hard_edge${Platform.pathSeparator}case.json',
  );
  await fixtureFile.parent.create(recursive: true);
  final fixtureBytes = utf8.encode('${jsonEncode(fixture)}\n');
  await fixtureFile.writeAsBytes(fixtureBytes);

  final mutationFile = File(
    '${root.path}${Platform.pathSeparator}test${Platform.pathSeparator}fixtures'
    '${Platform.pathSeparator}hard_edge${Platform.pathSeparator}mutation.json',
  );
  final mutationBytes = utf8.encode(
    '${jsonEncode({'mutationStatus': mutationStatus})}\n',
  );
  await mutationFile.writeAsBytes(mutationBytes);

  final manifest = File(
    '${root.path}${Platform.pathSeparator}test${Platform.pathSeparator}fixtures'
    '${Platform.pathSeparator}hard_edge${Platform.pathSeparator}manifest.v1.json',
  );
  await manifest.writeAsString(
    jsonEncode({
      'schemaVersion': 1,
      'catalogVersion': 'test-v1',
      'cases': [
        _caseJson(
          id: 'framework-case',
          fixture: 'test/fixtures/hard_edge/case.json',
          digest: digestOverride ?? hardEdgeSha256(fixtureBytes),
          expectedOutcome: expectedOutcome,
          requiredTool: requiredTool,
        ),
      ],
      'mutations': [
        {
          'id': 'framework-mutant',
          'family': 'framework',
          'property': 'framework.reproducibility',
          'operatorId': 'force-violation',
          'fixture': 'test/fixtures/hard_edge/mutation.json',
          'sha256': hardEdgeSha256(mutationBytes),
          'requiredTool': null,
        },
      ],
    }),
  );
  return _CatalogSetup(manifest);
}

Map<String, Object?> _caseJson({
  required String id,
  required String fixture,
  required String digest,
  String sourceKind = 'independent',
  int? regressionIssue = 334,
  String expectedOutcome = 'pass',
  String? requiredTool,
}) =>
    {
      'id': id,
      'family': 'framework',
      'algorithm': 'synthetic-executor',
      'sourceKind': sourceKind,
      'seed': 334,
      'property': 'framework.reproducibility',
      'provenance': {
        'origin': 'Independent test fixture',
        'independentlyAuthored': true,
        'generator': 'test helper',
        'jflapVersion': null,
        'sourceRevision': null,
        'sourceSha256': null,
        'licenseBasis': 'LICENSE.txt',
      },
      'license': 'Apache-2.0',
      'regressionIssue': regressionIssue,
      'platforms': ['all'],
      'sha256': digest,
      'generatorVersion': 'test-v1',
      'oracleVersion': 'test-v1',
      'budget': {
        'maxIterations': 8,
        'maxProductions': 20,
        'maxRegexNodes': 24,
        'maxStackDepth': 16,
        'maxStates': 8,
        'maxSymbols': 6,
        'maxTapeCells': 24,
        'maxTransitions': 24,
        'maxWordLength': 12,
      },
      'fixture': fixture,
      'expectedOutcome': expectedOutcome,
      'requiredTool': requiredTool,
    };

final class _CatalogSetup {
  const _CatalogSetup(this.manifest);

  final File manifest;
}

Future<void> _createDirectoryLink(
  Directory link,
  Directory target,
) async {
  if (Platform.isWindows) {
    final result = await Process.run(
      'cmd',
      ['/c', 'mklink', '/J', link.path, target.path],
    );
    if (result.exitCode != 0) {
      throw StateError('Could not create test junction: ${result.stderr}');
    }
    return;
  }
  await Link(link.path).create(target.path);
}
