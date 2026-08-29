import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

import '../../../tool/localization_literal_scan.dart';

void main() {
  final scanner = LocalizationLiteralScanner();

  test('reports probable interface copy with path and line', () {
    final source = File(
      'test/fixtures/localization_literal_scan/positive.dart.txt',
    ).readAsStringSync();
    final findings = scanner.scanSource(
      path: 'lib/presentation/widgets/example.dart',
      source: source,
    );

    final violations = findings
        .where((finding) => finding.isViolation)
        .toList();
    expect(
      violations.map((finding) => finding.literal),
      containsAll(<String>[
        'Save changes',
        'Raw hardcoded copy',
        'Triple hardcoded\ncopy',
        'Raw triple hardcoded\ncopy',
        'Delete',
        'Save everything',
        'Still hardcoded',
        r'Failure: $reason',
        'Delete everything',
        'Grammar',
      ]),
    );
    expect(violations.first.line, 3);
    expect(violations.first.path, 'lib/presentation/widgets/example.dart');
  });

  test('parses raw, triple, adjacent, and multiline argument literals', () {
    const source = '''
Widget buildRaw() => const Text(r'Raw copy');
Widget buildTriple() => const Text(\'\'\'Triple
copy\'\'\');
Widget buildRawTriple() => const Text(r"""Raw triple
copy""");
Widget buildAdjacent() => const Text('Save ' 'everything');
Widget buildMultiline() => const Text(
  'Delete',
);
''';
    final findings = scanner.scanSource(
      path: 'lib/presentation/widgets/example.dart',
      source: source,
    );

    expect(
      findings
          .where((finding) => finding.isViolation)
          .map((finding) => finding.literal),
      containsAll(<String>[
        'Raw copy',
        'Triple\ncopy',
        'Raw triple\ncopy',
        'Save everything',
        'Delete',
      ]),
    );
  });

  test('classifies language plumbing, identifiers, and notation', () {
    final source = File(
      'test/fixtures/localization_literal_scan/negative.dart.txt',
    ).readAsStringSync();
    final findings = scanner.scanSource(
      path: 'lib/presentation/widgets/example.dart',
      source: source,
    );

    expect(findings.where((finding) => finding.isViolation), isEmpty);
    expect(
      findings.map((finding) => finding.classification),
      containsAll(<LocalizationLiteralClassification>[
        LocalizationLiteralClassification.debugOrInternal,
        LocalizationLiteralClassification.deliberateNotationOrAcronym,
      ]),
    );
  });

  test(
    'classifies typed parse failures and project log wrappers as internal',
    () {
      const source = '''
void parse() {
  throw const FormatException('Malformed serialized vector.');
}
void trace() {
  logCanvasStateMutation('History snapshot captured');
  _logGraphViewCanvas('Canvas synchronized');
}
''';
      final findings = scanner.scanSource(
        path: 'lib/features/canvas/graphview/example.dart',
        source: source,
      );

      expect(findings.where((finding) => finding.isViolation), isEmpty);
      expect(
        findings.map((finding) => finding.classification).toSet(),
        <LocalizationLiteralClassification>{
          LocalizationLiteralClassification.debugOrInternal,
        },
      );
    },
  );

  test('nearby identifiers do not hide user-facing literals', () {
    const source = '''
Widget build() => Column(
  key: const ValueKey('stable-id'),
  children: const [
    Text('Save/load changes'),
    Text('Another hardcoded label'),
  ],
);
''';
    final findings = scanner.scanSource(
      path: 'lib/presentation/widgets/example.dart',
      source: source,
    );

    expect(
      findings
          .where((finding) => finding.isViolation)
          .map((finding) => finding.literal),
      containsAll(<String>['Save/load changes', 'Another hardcoded label']),
    );
  });

  test('flags single-word copy in TextSpan widgets', () {
    const source = "Widget build() => TextSpan(text: 'Settings');";
    final findings = scanner.scanSource(
      path: 'lib/presentation/widgets/example.dart',
      source: source,
    );

    expect(
      findings
          .where((finding) => finding.isViolation)
          .map((finding) => finding.literal),
      contains('Settings'),
    );
  });

  test('localized sibling arguments do not hide user-facing literals', () {
    const source = '''
void showFailure(AppLocalizations l10n) {
  showImportFailure(
    fileName: 'Grammar',
    errorMessage: l10n.errorLoadingGrammar('parser failure'),
  );
}
''';
    final findings = scanner.scanSource(
      path: 'lib/presentation/widgets/example.dart',
      source: source,
    );

    expect(
      findings
          .where((finding) => finding.isViolation)
          .map((finding) => finding.literal),
      contains('Grammar'),
    );
  });

  test('allowlist is exact and enforces its occurrence limit', () {
    final scanner = LocalizationLiteralScanner(
      allowlist: const [
        LocalizationLiteralAllowance(
          path: 'lib/app.dart',
          literal: 'Turing Lab',
          classification:
              LocalizationLiteralClassification.approvedPlatformConstant,
          rationale: 'Canonical product name.',
        ),
      ],
    );
    final findings = scanner.scanSource(
      path: 'lib/app.dart',
      source: "const one = 'Turing Lab';\nconst two = 'Turing Lab';",
    );

    expect(findings.first.isViolation, isFalse);
    expect(findings.last.isViolation, isTrue);
  });

  test('root scopes discover nested Dart files and reject empty roots', () {
    final root = Directory.systemTemp.createTempSync('literal-scope-');
    addTearDown(() => root.deleteSync(recursive: true));
    Directory(
      '${root.path}/lib/presentation/nested',
    ).createSync(recursive: true);
    File(
      '${root.path}/lib/presentation/top.dart',
    ).writeAsStringSync("const value = 'top';");
    File(
      '${root.path}/lib/presentation/nested/child.dart',
    ).writeAsStringSync("const value = 'child';");
    File(
      '${root.path}/lib/presentation/nested/ignored.txt',
    ).writeAsStringSync('ignored');

    expect(
      discoverLocalizationScopeFiles(root, <String, Object?>{
        'roots': <Object?>['lib/presentation'],
      }),
      <String>[
        'lib/presentation/nested/child.dart',
        'lib/presentation/top.dart',
      ],
    );
    expect(
      () => discoverLocalizationScopeFiles(root, const <String, Object?>{}),
      throwsFormatException,
    );
  });

  test('inventory accepts only an unchanged reviewed violation snapshot', () {
    const path = 'lib/presentation/widgets/legacy.dart';
    const source = "Widget build() => const Text('Legacy copy');";
    final violations = scanner
        .scanSource(path: path, source: source)
        .where((finding) => finding.isViolation)
        .toList();
    final inventory = buildLocalizationLiteralInventory(
      sources: const <String, String>{path: source},
      violations: violations,
    );

    final unchanged = auditLocalizationLiteralInventory(
      sources: const <String, String>{path: source},
      violations: violations,
      inventory: inventory,
    );
    expect(unchanged.knownLegacyPaths, <String>{path});
    expect(unchanged.staleEntries, isEmpty);
    expect(unchanged.unapprovedViolations, isEmpty);

    const changedSource =
        "// changed\nWidget build() => const Text('Legacy copy');";
    final changedViolations = scanner
        .scanSource(path: path, source: changedSource)
        .where((finding) => finding.isViolation)
        .toList();
    final changed = auditLocalizationLiteralInventory(
      sources: const <String, String>{path: changedSource},
      violations: changedViolations,
      inventory: inventory,
    );
    expect(changed.knownLegacyPaths, isEmpty);
    expect(changed.staleEntries, <String>['Inventory entry is stale: $path']);
    expect(changed.unapprovedViolations, changedViolations);
  });

  test('inventory source digests are stable across checkout line endings', () {
    const path = 'lib/presentation/widgets/legacy.dart';
    const sourceLf =
        "Widget one() => const Text('Legacy one');\n"
        "Widget two() => const Text('Legacy two');\n";
    final lfViolations = scanner
        .scanSource(path: path, source: sourceLf)
        .where((finding) => finding.isViolation)
        .toList();
    final inventory = buildLocalizationLiteralInventory(
      sources: const <String, String>{path: sourceLf},
      violations: lfViolations,
    );
    final sourceCrlf = sourceLf.replaceAll('\n', '\r\n');
    final crlfViolations = scanner
        .scanSource(path: path, source: sourceCrlf)
        .where((finding) => finding.isViolation)
        .toList();

    final audit = auditLocalizationLiteralInventory(
      sources: <String, String>{path: sourceCrlf},
      violations: crlfViolations,
      inventory: inventory,
    );
    expect(audit.staleEntries, isEmpty);
    expect(audit.unapprovedViolations, isEmpty);
  });

  test('rejects malformed Dart instead of skipping user-facing literals', () {
    expect(
      () => scanner.scanSource(
        path: 'lib/presentation/widgets/example.dart',
        source: "@ Text('Save');",
      ),
      throwsA(isA<FormatException>()),
    );
  });

  test('--write-inventory does not audit the generated snapshot', () async {
    final root = Directory.systemTemp.createTempSync(
      'localization-literal-write-only-',
    );
    addTearDown(() {
      exitCode = 0;
      root.deleteSync(recursive: true);
    });
    File('${root.path}/scope.json').writeAsStringSync(
      jsonEncode({
        'files': ['lib/example.dart'],
      }),
    );
    File(
      '${root.path}/allowlist.json',
    ).writeAsStringSync(jsonEncode({'entries': <Object>[]}));
    Directory('${root.path}/lib').createSync();
    File(
      '${root.path}/lib/example.dart',
    ).writeAsStringSync("Widget build() => const Text('Unapproved copy');");
    final generatedInventory = File('${root.path}/generated.json');

    await runLocalizationLiteralScan([
      '--root',
      root.path,
      '--scope',
      'scope.json',
      '--allowlist',
      'allowlist.json',
      '--write-inventory',
      'generated.json',
      '--json',
      'report.json',
    ]);

    final report =
        jsonDecode(File('${root.path}/report.json').readAsStringSync())
            as Map<String, Object?>;
    expect(report['status'], 'failed');
    expect(report['unapprovedViolationCount'], 1);
    expect(report, isNot(contains('inventory')));
    expect(generatedInventory.existsSync(), isTrue);
    final inventory =
        jsonDecode(generatedInventory.readAsStringSync())
            as Map<String, Object?>;
    final entries = inventory['entries']! as List<Object?>;
    expect(entries, hasLength(1));
    expect(entries.single, containsPair('path', 'lib/example.dart'));
    expect(entries.single, containsPair('violationCount', 1));
    expect(exitCode, 1);
  });
}
