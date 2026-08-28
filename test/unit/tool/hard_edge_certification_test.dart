import 'dart:convert';
import 'dart:io';

import 'package:test/test.dart';

import '../../../tool/hard_edge/catalog.dart';
import '../../../tool/hard_edge/certification.dart';
import '../../../tool/hard_edge/certification_report.dart';
import '../../../tool/hard_edge/cross_family_certification.dart';
import '../../../tool/hard_edge/models.dart';
import '../../../tool/hard_edge/mutation.dart';
import '../../../tool/hard_edge/runner.dart';

void main() {
  late Directory root;

  setUp(() async {
    root = await Directory.systemTemp.createTemp('hard-edge-certification-');
    await Directory('${root.path}/docs/jflap-parity').create(recursive: true);
    await File('${root.path}/docs/jflap-parity/test.json').writeAsString(
      jsonEncode({
        'fragment': 'test',
        'rows': [
          {
            'id': 'test.complete',
            'turingLab': {
              'status': 'complete',
              'issues': [342],
            },
          },
        ],
      }),
    );
  });

  tearDown(() async {
    if (root.existsSync()) await root.delete(recursive: true);
  });

  test('filtered certification runs properties and family mutation threshold',
      () async {
    final catalog = await _catalog(root, mutationStatus: 'killed');
    final report = await _runner(catalog).run(
      const HardEdgeCertificationOptions(
        family: 'framework',
        repeats: 2,
        command: 'certify --family framework --repeat 2',
      ),
    );

    expect(report.status, HardEdgeCertificationStatus.passed);
    expect(
      report.phases.singleWhere((item) => item.name == 'properties').status,
      HardEdgeCertificationStatus.passed,
    );
    expect(
      report.phases.singleWhere((item) => item.name == 'cross-family').status,
      HardEdgeCertificationStatus.skipped,
    );
    expect(report.propertyRun!.cases, hasLength(2));
    expect(report.mutationFamilies.single.thresholdMet, isTrue);
    expect(report.toJson()['remotelyVerified'], isFalse);
    expect(report.jflapParity.statusCounts['complete'], 1);
  });

  test('regression-only with no historical fixture is not_run, never passed',
      () async {
    final report = await _runner(await _catalog(root)).run(
      const HardEdgeCertificationOptions(
        family: 'framework',
        regressionOnly: true,
        command: 'certify --regression-only --family framework',
      ),
    );

    expect(report.status, HardEdgeCertificationStatus.notRun);
    expect(report.propertyRun!.cases, isEmpty);
    expect(
      report.phases.singleWhere((item) => item.name == 'properties').status,
      HardEdgeCertificationStatus.notRun,
    );
    expect(
      report.phases.singleWhere((item) => item.name == 'mutations').status,
      HardEdgeCertificationStatus.skipped,
    );
  });

  test('full certification fails closed when Flutter evidence cannot run',
      () async {
    final report = await _runner(await _catalog(root)).run(
      const HardEdgeCertificationOptions(command: 'certify --full'),
    );

    expect(report.status, HardEdgeCertificationStatus.failed);
    expect(report.hasMissingRequiredPrerequisite, isTrue);
    expect(
      report.prerequisites.singleWhere((item) => item.name == 'flutter').status,
      HardEdgeCertificationStatus.failed,
    );
    expect(
      report.phases
          .singleWhere((item) => item.name == 'inventory-evidence')
          .status,
      HardEdgeCertificationStatus.notRun,
    );
    expect(report.inventoryEvidence, isEmpty);
  });

  test('full certification executes each inventory owner command serially',
      () async {
    final visited = <String>[];
    var active = 0;
    var maximumActive = 0;
    final report = await _runner(
      await _catalog(root),
      flutterAvailable: true,
      inventoryEvidenceRunner: (command, root, timeout, index) async {
        active++;
        if (active > maximumActive) maximumActive = active;
        visited.add(command);
        await Future<void>.delayed(const Duration(milliseconds: 2));
        active--;
        return HardEdgeInventoryEvidenceResult(
          command: command,
          status: HardEdgeCertificationStatus.passed,
          duration: const Duration(milliseconds: 2),
          exitCode: 0,
          message: 'passed',
          stdout: 'ok',
          stderr: '',
          artifact: 'inventory-evidence/01.log',
        );
      },
    ).run(const HardEdgeCertificationOptions(command: 'certify --full'));

    expect(report.status, HardEdgeCertificationStatus.passed);
    expect(visited, ['flutter test owner-suite']);
    expect(maximumActive, 1);
    expect(report.inventoryEvidence, hasLength(1));
    expect(
      report.phases
          .singleWhere((item) => item.name == 'inventory-evidence')
          .status,
      HardEdgeCertificationStatus.passed,
    );
  });

  test('survivor fails the reviewed per-family threshold and is indexed',
      () async {
    final report = await _runner(
      await _catalog(root, mutationStatus: 'survived'),
    ).run(
      const HardEdgeCertificationOptions(
        family: 'framework',
        mutationOnly: true,
        command: 'certify --mutation-only --family framework',
      ),
    );

    expect(report.status, HardEdgeCertificationStatus.failed);
    expect(report.mutationFamilies.single.thresholdMet, isFalse);
    expect(report.mutationFamilies.single.survivorIds, ['framework-mutation']);
  });

  test('reports write JSON, Markdown, and HTML without hiding bounded evidence',
      () async {
    final base = await _runner(await _catalog(root)).run(
      const HardEdgeCertificationOptions(
        family: 'framework',
        command: 'certify --family framework',
      ),
    );
    final bounded = CrossFamilyCertificationReport(const [
      CrossFamilyObservation(
        id: 'bounded-check',
        families: ['grammar'],
        equivalence: CrossFamilyEquivalence.bounded,
        outcome: CrossFamilyOutcome.boundedUnknown,
        properties: ['bounded-evidence'],
        evidence: {'limit': 1},
      ),
    ]);
    final report = HardEdgeCertificationReport(
      status: base.status,
      startedAtUtc: base.startedAtUtc,
      duration: base.duration,
      command: base.command,
      environment: base.environment,
      prerequisites: base.prerequisites,
      phases: base.phases,
      propertyRun: base.propertyRun,
      mutationRun: base.mutationRun,
      mutationFamilies: base.mutationFamilies,
      regressionIndex: base.regressionIndex,
      seedCatalog: base.seedCatalog,
      quarantines: base.quarantines,
      jflapParity: base.jflapParity,
      crossFamily: HardEdgeCrossFamilySummary(
        report: bounded,
        expectedOutcomes: const {
          'bounded-check': CrossFamilyOutcome.boundedUnknown,
        },
        expectedOutcomesMatched: true,
        repeats: 1,
        flaky: false,
        seed: 342,
      ),
      repositoryInventory: base.repositoryInventory,
      repositoryRegressionIndex: base.repositoryRegressionIndex,
      inventoryEvidence: base.inventoryEvidence,
      artifacts: base.artifacts,
    );
    final output = Directory('${root.path}/report');

    await const HardEdgeCertificationReportWriter().write(
      report,
      outputDirectory: output,
    );

    for (final name in [
      'certification-report.json',
      'certification-report.md',
      'certification-report.html',
    ]) {
      expect(File('${output.path}/$name').existsSync(), isTrue);
    }
    final json = jsonDecode(
      await File('${output.path}/certification-report.json').readAsString(),
    ) as Map<String, dynamic>;
    final cross = json['crossFamily'] as Map<String, dynamic>;
    expect(cross['status'], 'passed');
    expect(cross['boundedUnknownCount'], 1);
    expect(
      ((cross['observations'] as List).single as Map)['certified'],
      isFalse,
    );
    final markdown =
        await File('${output.path}/certification-report.md').readAsString();
    expect(markdown, contains('Expected boundedUnknown outcomes: `1`'));
    expect(markdown, contains('remain `certified=false`'));
  });

  test('repository parity reader reports residual status and ownership',
      () async {
    await File('${root.path}/docs/jflap-parity/test.json').writeAsString(
      jsonEncode({
        'fragment': 'test',
        'rows': [
          {
            'id': 'test.partial',
            'turingLab': {
              'status': 'partial',
              'issues': [339],
            },
          },
        ],
      }),
    );

    final summary = await readHardEdgeJflapParity(root);

    expect(summary.totalRows, 1);
    expect(summary.statusCounts['partial'], 1);
    expect(summary.residualGaps.single['ownerIssues'], [339]);
    expect(summary.residualGaps.single['unowned'], isFalse);
  });

  test('default inventory evidence runner captures a bounded local command',
      () async {
    final result = await runHardEdgeInventoryEvidence(
      'dart --version',
      Directory.current,
      const Duration(seconds: 10),
      0,
    );

    expect(result.status, HardEdgeCertificationStatus.passed);
    expect(result.exitCode, 0);
    expect('${result.stdout}${result.stderr}', contains('Dart SDK version'));
    expect(result.artifact, 'inventory-evidence/01.log');
  });
}

HardEdgeCertificationRunner _runner(
  HardEdgeCatalog catalog, {
  bool flutterAvailable = false,
  HardEdgeInventoryEvidenceRunner? inventoryEvidenceRunner,
}) =>
    HardEdgeCertificationRunner(
      catalog: catalog,
      propertyExecutor: const SyntheticPropertyExecutor(),
      mutationExecutor: const SyntheticMutationExecutor(),
      policy: HardEdgeCertificationPolicy(
        mutationThresholds: const [
          HardEdgeMutationThreshold(
            family: 'framework',
            minimumKillRatio: 1,
            maximumSurvivors: 0,
            rationale: 'Every framework probe must be killed.',
          ),
        ],
        quarantines: const [],
      ),
      environment: HardEdgeCertificationEnvironment(
        revision: 'aabbccdd',
        dirty: false,
        operatingSystem: 'test',
        operatingSystemVersion: '1',
        toolchains: [
          const HardEdgeToolchainRecord(
            name: 'dart',
            status: HardEdgeCertificationStatus.passed,
            version: 'test',
            command: 'dart --version',
            message: 'available',
          ),
          if (flutterAvailable)
            const HardEdgeToolchainRecord(
              name: 'flutter',
              status: HardEdgeCertificationStatus.passed,
              version: 'test',
              command: 'flutter --version --machine',
              message: 'available',
            ),
          const HardEdgeToolchainRecord(
            name: 'git',
            status: HardEdgeCertificationStatus.passed,
            version: 'aabbccdd',
            command: 'git rev-parse HEAD',
            message: 'available',
          ),
        ],
      ),
      toolProbe: (_) => true,
      inventoryLoader: (_) async => const HardEdgeRepositoryInventorySummary(
        entries: 1,
        exclusions: 0,
        validationIssues: [],
        mutationExclusions: [],
        path: 'inventory.json',
        evidenceCommands: ['flutter test owner-suite'],
      ),
      regressionIndexLoader: (_) async => const {
        'schema': 'turing-lab.repository-regression-index.v1',
        'ownerIssue': 342,
        'historicalDefects': <Object?>[],
        'rationale': 'No repository-level regression.',
        'status': 'passed',
      },
      inventoryEvidenceRunner: inventoryEvidenceRunner ??
          (command, root, timeout, index) async =>
              HardEdgeInventoryEvidenceResult(
                command: command,
                status: HardEdgeCertificationStatus.passed,
                duration: const Duration(milliseconds: 1),
                exitCode: 0,
                message: 'passed',
                stdout: 'ok',
                stderr: '',
                artifact: 'inventory-evidence/01.log',
              ),
      crossFamilyRunner: (_) async => HardEdgeCrossFamilySummary(
        report: CrossFamilyCertificationReport(const [
          CrossFamilyObservation(
            id: 'bounded-check',
            families: ['grammar'],
            equivalence: CrossFamilyEquivalence.bounded,
            outcome: CrossFamilyOutcome.boundedUnknown,
            properties: ['bounded-evidence'],
            evidence: {'limit': 1},
          ),
        ]),
        expectedOutcomes: const {
          'bounded-check': CrossFamilyOutcome.boundedUnknown,
        },
        expectedOutcomesMatched: true,
        repeats: 1,
        flaky: false,
        seed: 342,
      ),
    );

Future<HardEdgeCatalog> _catalog(
  Directory root, {
  String mutationStatus = 'killed',
}) async {
  const propertyFixture = {'outcome': 'pass'};
  final mutationFixture = {'mutationStatus': mutationStatus};
  final propertyFile = File('${root.path}/property.json');
  final mutationFile = File('${root.path}/mutation.json');
  await propertyFile.writeAsString(jsonEncode(propertyFixture));
  await mutationFile.writeAsString(jsonEncode(mutationFixture));
  final propertyBytes = await propertyFile.readAsBytes();
  final mutationBytes = await mutationFile.readAsBytes();
  return HardEdgeCatalog(
    repositoryRoot: root,
    manifestFile: File('${root.path}/manifest.json'),
    manifest: HardEdgeManifest(
      schemaVersion: 1,
      catalogVersion: 'test-v1',
      cases: [
        HardEdgeCatalogCase(
          id: 'framework-case',
          family: 'framework',
          algorithm: 'synthetic',
          sourceKind: HardEdgeSourceKind.independent,
          seed: 342,
          property: 'framework.property',
          provenance: const HardEdgeProvenance(
            origin: 'test',
            independentlyAuthored: true,
            generator: 'test-v1',
            licenseBasis: 'LICENSE.txt',
          ),
          license: 'Apache-2.0',
          regressionIssue: 342,
          platforms: const ['all'],
          sha256: hardEdgeSha256(propertyBytes),
          generatorVersion: 'test-v1',
          oracleVersion: 'test-v1',
          budget: const GenerationBudget(),
          fixture: 'property.json',
          expectedOutcome: HardEdgeExpectedOutcome.pass,
          requiredTool: null,
        ),
      ],
      mutations: [
        HardEdgeMutation(
          id: 'framework-mutation',
          family: 'framework',
          property: 'framework.mutation',
          operatorId: 'mutate',
          fixture: 'mutation.json',
          sha256: hardEdgeSha256(mutationBytes),
          requiredTool: null,
        ),
      ],
    ),
  );
}
