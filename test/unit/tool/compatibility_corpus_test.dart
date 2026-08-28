import 'dart:convert';
import 'dart:io';

import 'package:test/test.dart';

import '../../../tool/compatibility_corpus/catalog.dart';
import '../../../tool/compatibility_corpus/manifest.dart';
import '../../../tool/compatibility_corpus/report.dart';
import '../../../tool/compatibility_corpus/runner.dart';

void main() {
  late CompatibilityCodecCatalog catalog;
  late CompatibilityManifest manifest;

  setUpAll(() {
    catalog = CompatibilityCodecCatalog.create();
    manifest = CompatibilityManifest.parse(_manifestSource());
  });

  test('manifest covers every implemented codec and required case role', () {
    expect(catalog.codecs, hasLength(22));
    expect(catalog.validateManifest(manifest), isEmpty);
  });

  test('rejects invalid metadata and a missing semantic oracle', () {
    final invalidMetadata = _manifestJson();
    final defaults = invalidMetadata['defaults'] as Map<String, dynamic>;
    final provenance = defaults['provenance'] as Map<String, dynamic>;
    provenance.remove('license');
    expect(
      () => CompatibilityManifest.parse(jsonEncode(invalidMetadata)),
      throwsFormatException,
    );

    final missingOracle = _manifestJson();
    final cases = missingOracle['cases'] as List<dynamic>;
    (cases.first as Map<String, dynamic>).remove('oracle');
    expect(
      () => CompatibilityManifest.parse(jsonEncode(missingOracle)),
      throwsFormatException,
    );
  });

  test('rejects unsupported schema versions and duplicate fixture IDs', () {
    final future = _manifestJson()..['schemaVersion'] = 2;
    expect(
      () => CompatibilityManifest.parse(jsonEncode(future)),
      throwsFormatException,
    );

    final duplicate = _manifestJson();
    final cases = duplicate['cases'] as List<dynamic>;
    (cases[1] as Map<String, dynamic>)['id'] =
        (cases[0] as Map<String, dynamic>)['id'];
    expect(
      () => CompatibilityManifest.parse(jsonEncode(duplicate)),
      throwsFormatException,
    );
  });

  test('stale fixture checksums fail without decoding stale bytes', () async {
    final stale = _manifestJson();
    final cases = stale['cases'] as List<dynamic>;
    (cases.first as Map<String, dynamic>)['sha256'] =
        List.filled(64, '0').join();
    final result = await _runner(catalog).run(
      CompatibilityManifest.parse(jsonEncode(stale)),
      fixtureId: 'fsa-jflap-canonical',
    );

    expect(result.status, CompatibilityRunStatus.failed);
    expect(result.cases.single.message, contains('checksum is stale'));
  });

  test('approved loss passes and the same unapproved loss fails', () async {
    final approved = await _runner(catalog).run(
      manifest,
      fixtureId: 'regex-jflap-canonical',
    );
    expect(approved.status, CompatibilityRunStatus.passed);
    expect(approved.cases.single.actualFidelity, 'lossy');

    final unapprovedJson = _manifestJson();
    final cases = unapprovedJson['cases'] as List<dynamic>;
    final regex = cases.cast<Map<String, dynamic>>().singleWhere(
          (testCase) => testCase['id'] == 'regex-jflap-canonical',
        );
    (regex['expected'] as Map<String, dynamic>).remove('approvedLosses');
    final unapproved = await _runner(catalog).run(
      CompatibilityManifest.parse(jsonEncode(unapprovedJson)),
      fixtureId: 'regex-jflap-canonical',
    );

    expect(unapproved.status, CompatibilityRunStatus.failed);
    expect(unapproved.cases.single.message, contains('unapproved='));
  });

  test('filters by family and fixture with deterministic report ordering',
      () async {
    final regex = await _runner(catalog).run(manifest, family: 'regex');
    final ids = regex.cases.map((result) => result.testCase.id).toList();
    expect(ids, orderedEquals(ids.toList()..sort()));
    expect(ids, hasLength(5));

    final markdown = const CompatibilityReportWriter().renderMarkdown(regex);
    expect(
      const CompatibilityReportWriter().renderMarkdown(regex),
      markdown,
    );

    final single = await _runner(catalog).run(
      manifest,
      fixtureId: 'regex-json-malformed',
    );
    expect(single.cases.single.testCase.id, 'regex-json-malformed');
  });

  test('timeout is a failure and bounded unknown is never a rejection',
      () async {
    expect(
      CompatibilityRecognition.fromResult(null),
      CompatibilityRecognition.unknown,
    );
    final runner = CompatibilityCorpusRunner(
      repositoryRoot: Directory.current,
      catalog: catalog,
      jobs: 1,
      timeout: const Duration(milliseconds: 1),
      beforeCase: (_) => Future<void>.delayed(const Duration(milliseconds: 50)),
    );
    final result = await runner.run(
      manifest,
      fixtureId: 'fsa-json-canonical',
    );

    expect(result.status, CompatibilityRunStatus.failed);
    expect(result.cases.single.actualOutcome, 'timeout');
  });

  test('missing optional tools are not run and never reported as passing',
      () async {
    final partialJson = _manifestJson();
    final cases = partialJson['cases'] as List<dynamic>;
    (cases.first as Map<String, dynamic>)['requiredTool'] = 'missing-jflap';
    final runner = CompatibilityCorpusRunner(
      repositoryRoot: Directory.current,
      catalog: catalog,
      jobs: 1,
      toolProbe: (_) => false,
    );
    final result = await runner.run(
      CompatibilityManifest.parse(jsonEncode(partialJson)),
      fixtureId: 'fsa-jflap-canonical',
    );

    expect(result.status, CompatibilityRunStatus.incomplete);
    expect(result.cases.single.status, CompatibilityCaseStatus.notRun);
  });

  test('the full offline corpus passes', () async {
    final result = await _runner(catalog).run(manifest);
    expect(result.status, CompatibilityRunStatus.passed);
    expect(result.cases, hasLength(59));
  });
}

CompatibilityCorpusRunner _runner(CompatibilityCodecCatalog catalog) =>
    CompatibilityCorpusRunner(
      repositoryRoot: Directory.current,
      catalog: catalog,
      jobs: 4,
    );

String _manifestSource() => File(
      'test/fixtures/compatibility/manifest.v1.json',
    ).readAsStringSync();

Map<String, dynamic> _manifestJson() =>
    jsonDecode(_manifestSource()) as Map<String, dynamic>;
