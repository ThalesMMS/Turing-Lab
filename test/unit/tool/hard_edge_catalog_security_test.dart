import 'dart:io';

import 'package:test/test.dart';

import '../../../tool/hard_edge/catalog.dart';

void main() {
  late Directory repositoryRoot;

  setUp(() async {
    repositoryRoot = await Directory.systemTemp.createTemp(
      'hard-edge-catalog-security-',
    );
  });

  tearDown(() async {
    if (repositoryRoot.existsSync()) {
      await repositoryRoot.delete(recursive: true);
    }
  });

  test('JFLAP provenance requires an exact source revision and digest', () {
    final source = _caseJson(
      sourceKind: 'jflapDerived',
      license: 'LicenseRef-JFLAP-7.1',
      provenance: {
        'origin': 'JFLAP 7.1 source snapshot',
        'independentlyAuthored': false,
        'generator': 'fixture conversion tool',
        'jflapVersion': '7.1',
        'licenseBasis': 'LICENSE_JFLAP.txt',
        'sourceRevision': null,
        'sourceSha256': null,
      },
    );

    expect(
      () => HardEdgeCatalogCase.parse(source, r'$.case'),
      throwsFormatException,
    );

    final provenance = source['provenance'] as Map<String, Object?>;
    provenance['sourceRevision'] = 'JFLAP 7.1 source release, 2009-08-27';
    provenance['sourceSha256'] = 'a' * 64;
    final parsed = HardEdgeCatalogCase.parse(source, r'$.case');

    expect(parsed.provenance.sourceRevision, contains('2009-08-27'));
    expect(parsed.provenance.sourceSha256, 'a' * 64);
  });

  test('fixture licenses must map to their committed license text', () {
    final unknown = _caseJson(license: 'Made-Up-1.0');
    expect(
      () => HardEdgeCatalogCase.parse(unknown, r'$.case'),
      throwsFormatException,
    );

    final mismatched = _caseJson();
    final provenance = mismatched['provenance'] as Map<String, Object?>;
    provenance['licenseBasis'] = 'LICENSE_JFLAP.txt';
    expect(
      () => HardEdgeCatalogCase.parse(mismatched, r'$.case'),
      throwsFormatException,
    );
  });

  test('catalog validation requires the recorded license text to exist',
      () async {
    final testCase = HardEdgeCatalogCase.parse(_caseJson(), r'$.case');
    final catalog = HardEdgeCatalog(
      repositoryRoot: repositoryRoot,
      manifestFile: File(
        '${repositoryRoot.path}${Platform.pathSeparator}manifest.json',
      ),
      manifest: HardEdgeManifest(
        schemaVersion: HardEdgeManifest.supportedSchemaVersion,
        catalogVersion: 'test-v1',
        cases: [testCase],
        mutations: const [],
      ),
    );

    await expectLater(
      catalog.validateFixtures(),
      throwsA(
        isA<FormatException>().having(
          (error) => error.message,
          'message',
          contains('LICENSE.txt'),
        ),
      ),
    );
  });

  test('new output cannot escape through a pre-existing directory link',
      () async {
    final outside = await Directory.systemTemp.createTemp(
      'hard-edge-catalog-outside-',
    );
    final link = Directory(
      '${repositoryRoot.path}${Platform.pathSeparator}linked-output',
    );
    addTearDown(() async {
      if (link.existsSync()) await link.delete();
      if (outside.existsSync()) await outside.delete(recursive: true);
    });
    await _createDirectoryLink(link, outside);

    expect(
      () => hardEdgePathInside(
        repositoryRoot,
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

  test('new output under a real repository directory stays allowed', () async {
    await Directory(
      '${repositoryRoot.path}${Platform.pathSeparator}build',
    ).create();

    final output = hardEdgePathInside(
      repositoryRoot,
      'build/result.json',
      mustExist: false,
    );

    expect(output.path, endsWith('result.json'));
  });
}

Map<String, Object?> _caseJson({
  String sourceKind = 'independent',
  String license = 'Apache-2.0',
  Map<String, Object?>? provenance,
}) =>
    {
      'algorithm': 'catalog-test',
      'budget': {
        'maxIterations': 1,
        'maxProductions': 1,
        'maxRegexNodes': 1,
        'maxStackDepth': 1,
        'maxStates': 1,
        'maxSymbols': 1,
        'maxTapeCells': 1,
        'maxTransitions': 1,
        'maxWordLength': 1,
      },
      'expectedOutcome': 'pass',
      'family': 'framework',
      'fixture': 'test/fixtures/hard_edge/catalog-test.json',
      'generatorVersion': 'test-v1',
      'id': 'catalog-test',
      'license': license,
      'oracleVersion': 'test-v1',
      'platforms': ['all'],
      'property': 'catalog.security',
      'provenance': provenance ??
          {
            'origin': 'Independent catalog test',
            'independentlyAuthored': true,
            'generator': 'catalog test helper',
            'jflapVersion': null,
            'licenseBasis': 'LICENSE.txt',
            'sourceRevision': null,
            'sourceSha256': null,
          },
      'regressionIssue': 334,
      'requiredTool': null,
      'seed': 334,
      'sha256': '0' * 64,
      'sourceKind': sourceKind,
    };

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
