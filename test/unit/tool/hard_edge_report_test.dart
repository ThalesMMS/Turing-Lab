import 'dart:convert';
import 'dart:io';

import 'package:test/test.dart';

import '../../../tool/hard_edge/catalog.dart';
import '../../../tool/hard_edge/models.dart';
import '../../../tool/hard_edge/report.dart';
import '../../../tool/hard_edge/runner.dart';

void main() {
  late Directory temporaryRoot;

  setUp(() async {
    temporaryRoot = await Directory.systemTemp.createTemp('hard-edge-report-');
  });

  tearDown(() async {
    if (temporaryRoot.existsSync()) {
      await temporaryRoot.delete(recursive: true);
    }
  });

  test('summary renders unique coverage by family, property, and seed',
      () async {
    final report = File('${temporaryRoot.path}/report.json');
    final output = File('${temporaryRoot.path}/summary.md');
    await report.writeAsString(jsonEncode({
      'status': 'passed',
      'remotelyVerified': false,
      'cases': [
        {'id': 'cfg-7', 'repeatIndex': 0},
        {'id': 'cfg-7', 'repeatIndex': 1},
        {'id': 'fsa-8', 'repeatIndex': 0},
      ],
      'coverage': {
        'families': {'cfg': 1, 'fsa': 1},
        'properties': {'language-equivalence': 2},
        'seeds': {'7': 1, '8': 1},
      },
    }));

    await const HardEdgeReportWriter().renderSummaryFromJson(
      reportFile: report,
      outputFile: output,
    );

    final markdown = await output.readAsString();
    expect(markdown, contains('- Recorded unique cases: `2`'));
    expect(markdown, contains('- Recorded executions: `3`'));
    expect(markdown, contains('## Coverage by family'));
    expect(markdown, contains('| `cfg` | 1 |'));
    expect(markdown, contains('| `fsa` | 1 |'));
    expect(markdown, contains('## Coverage by property'));
    expect(markdown, contains('| `language-equivalence` | 2 |'));
    expect(markdown, contains('## Coverage by seed'));
    expect(markdown, contains('| `7` | 1 |'));
    expect(markdown, contains('| `8` | 1 |'));
  });

  test('failure artifact uses the materialized fixture from the result',
      () async {
    final testCase = _testCase();
    final catalog = HardEdgeCatalog(
      repositoryRoot: temporaryRoot,
      manifestFile: File('${temporaryRoot.path}/manifest.json'),
      manifest: HardEdgeManifest(
        schemaVersion: 1,
        catalogVersion: 'test-v1',
        cases: [testCase],
        mutations: const [],
      ),
    );
    final materializedFixture = {
      'outcome': 'violation',
      'seed': testCase.seed,
      'word': 'generated',
    };
    final materializedFingerprint = hardEdgeSha256(
      utf8.encode(canonicalJsonEncode(materializedFixture)),
    );
    final result = HardEdgeRunResult(
      catalogVersion: 'test-v1',
      status: HardEdgeRunStatus.failed,
      cases: [
        HardEdgeCaseResult(
          testCase: testCase,
          fixture: materializedFixture,
          fixtureFingerprint: materializedFingerprint,
          fixtureMaterialized: true,
          repeatIndex: 0,
          status: HardEdgeCaseStatus.failed,
          outcome: HardEdgeExecutionOutcome.violation,
          message: 'The property was violated.',
          elapsed: Duration.zero,
          reproductionCommand: 'reproduce',
        ),
      ],
      jobs: 1,
      caseTimeout: const Duration(seconds: 1),
    );
    final output = Directory('${temporaryRoot.path}/output');

    await const HardEdgeReportWriter().writeRun(
      result,
      outputDirectory: output,
      catalog: catalog,
    );

    final artifactFile = hardEdgeFailureArtifactFile(
      outputDirectory: output,
      resultCase: result.cases.single,
    );
    expect(artifactFile.path, endsWith('framework-case-repeat-0.json'));
    final artifact =
        jsonDecode(await artifactFile.readAsString()) as Map<String, dynamic>;
    expect(artifact['fixture'], materializedFixture);
    expect((artifact['case'] as Map)['sha256'], materializedFingerprint);
    expect(
        (await readFailureArtifact(artifactFile)).fixture, materializedFixture);
    expect(artifact['minimalFixture'], isNull);
    expect(artifact['minimized'], isFalse);

    final markdown =
        await File('${output.path}/hard-edge-report.md').readAsString();
    expect(markdown, contains('## Replay commands'));
    expect(markdown, contains('replay --fixture ${artifactFile.path}'));
    expect(markdown, contains('## Regeneration commands'));
    expect(markdown, contains('reproduce'));
  });

  test('flaky passed repeats get distinct replay artifacts', () async {
    final testCase = _testCase();
    final results = [
      HardEdgeCaseResult(
        testCase: testCase,
        fixture: const {'outcome': 'pass', 'variant': 0},
        fixtureFingerprint: hardEdgeSha256(
          utf8.encode(
            canonicalJsonEncode(
              const {'outcome': 'pass', 'variant': 0},
            ),
          ),
        ),
        fixtureMaterialized: true,
        repeatIndex: 0,
        status: HardEdgeCaseStatus.passed,
        outcome: HardEdgeExecutionOutcome.pass,
        message: 'First outcome.',
        elapsed: Duration.zero,
        reproductionCommand: 'regenerate-seed-334',
      ),
      HardEdgeCaseResult(
        testCase: testCase,
        fixture: const {'outcome': 'pass', 'variant': 1},
        fixtureFingerprint: hardEdgeSha256(
          utf8.encode(
            canonicalJsonEncode(
              const {'outcome': 'pass', 'variant': 1},
            ),
          ),
        ),
        fixtureMaterialized: true,
        repeatIndex: 1,
        status: HardEdgeCaseStatus.passed,
        outcome: HardEdgeExecutionOutcome.pass,
        message: 'Second outcome.',
        elapsed: Duration.zero,
        reproductionCommand: 'regenerate-seed-334',
      ),
    ];
    final result = HardEdgeRunResult(
      catalogVersion: 'test-v1',
      status: HardEdgeRunStatus.failed,
      cases: results,
      jobs: 1,
      caseTimeout: const Duration(seconds: 1),
      flakyCaseIds: const ['framework-case'],
    );
    final output = Directory('${temporaryRoot.path}/output');

    await const HardEdgeReportWriter().writeRun(
      result,
      outputDirectory: output,
    );

    final first = hardEdgeFailureArtifactFile(
      outputDirectory: output,
      resultCase: results[0],
    );
    final second = hardEdgeFailureArtifactFile(
      outputDirectory: output,
      resultCase: results[1],
    );
    expect(first.path, isNot(second.path));
    expect(first.existsSync(), isTrue);
    expect(second.existsSync(), isTrue);
    expect(
      jsonDecode(await first.readAsString())['fixture'],
      {'outcome': 'pass', 'variant': 0},
    );
    expect(
      jsonDecode(await second.readAsString())['fixture'],
      {'outcome': 'pass', 'variant': 1},
    );

    final markdown =
        await File('${output.path}/hard-edge-report.md').readAsString();
    expect(markdown, contains('replay --fixture ${first.path}'));
    expect(markdown, contains('replay --fixture ${second.path}'));
  });

  test('pre-materialization failure emits regeneration without replay',
      () async {
    final testCase = _testCase();
    final resultCase = HardEdgeCaseResult(
      testCase: testCase,
      fixture: null,
      fixtureFingerprint: hardEdgeSha256(
        utf8.encode(canonicalJsonEncode(null)),
      ),
      fixtureMaterialized: false,
      repeatIndex: 0,
      status: HardEdgeCaseStatus.failed,
      outcome: null,
      message: 'The test runner exceeded its per-case timeout.',
      elapsed: const Duration(seconds: 1),
      reproductionCommand: 'regenerate-timeout-seed-334',
    );
    final result = HardEdgeRunResult(
      catalogVersion: 'test-v1',
      status: HardEdgeRunStatus.failed,
      cases: [resultCase],
      jobs: 1,
      caseTimeout: const Duration(seconds: 1),
    );
    final output = Directory('${temporaryRoot.path}/output');

    await const HardEdgeReportWriter().writeRun(
      result,
      outputDirectory: output,
    );

    expect(
      hardEdgeFailureArtifactFile(
        outputDirectory: output,
        resultCase: resultCase,
      ).existsSync(),
      isFalse,
    );
    final markdown =
        await File('${output.path}/hard-edge-report.md').readAsString();
    expect(markdown, contains('No replayable materialized failure'));
    expect(markdown, contains('regenerate-timeout-seed-334'));
  });
}

HardEdgeCatalogCase _testCase() => HardEdgeCatalogCase(
      id: 'framework-case',
      family: 'framework',
      algorithm: 'synthetic',
      sourceKind: HardEdgeSourceKind.generated,
      seed: 334,
      property: 'property',
      provenance: const HardEdgeProvenance(
        origin: 'test',
        independentlyAuthored: true,
        generator: 'test',
        licenseBasis: 'LICENSE.txt',
      ),
      license: 'Apache-2.0',
      regressionIssue: null,
      platforms: const ['all'],
      sha256: '0' * 64,
      generatorVersion: '1',
      oracleVersion: '1',
      budget: const GenerationBudget(),
      fixture: 'unused-template.json',
      expectedOutcome: HardEdgeExpectedOutcome.pass,
      requiredTool: null,
    );
