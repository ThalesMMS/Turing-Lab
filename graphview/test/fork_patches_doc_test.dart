import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

const patchSections = <String, int>{
  '## Edge Rendering Patches': 5,
  '## Performance Patches': 2,
  '## Interaction Patches': 4,
  '## Animation Patches': 3,
  '## API Patches': 5,
};

const appendixCategories = <String>[
  'Edge rendering',
  'Performance',
  'Interaction',
  'Animation',
  'API',
];

const expectedPatchTotal = 19;

List<String> extractSectionLines(String content, String sectionHeader) {
  final lines = content.split('\n');
  var inSection = false;
  final result = <String>[];

  for (final line in lines) {
    if (line.trim() == sectionHeader) {
      inSection = true;
      continue;
    }
    if (inSection && line.startsWith('## ')) {
      break;
    }
    if (inSection) {
      result.add(line);
    }
  }
  return result;
}

List<String> extractTableDataRows(List<String> sectionLines) {
  return sectionLines
      .where((line) =>
          line.trim().startsWith('|') &&
          !line.contains('---') &&
          !line.contains('Patch Name') &&
          !line.contains('Category'))
      .toList();
}

int countPatchTableDataRows(List<String> sectionLines) {
  return extractTableDataRows(sectionLines).length;
}

List<String> extractTableCells(String row) {
  return row
      .split('|')
      .map((cell) => cell.trim())
      .where((cell) => cell.isNotEmpty)
      .toList();
}

String extractStatusToken(String statusCell, String line) {
  final match = RegExp(r'^\*\*(\w+)\*\*$').firstMatch(statusCell.trim());
  expect(
    match,
    isNotNull,
    reason:
        'Status cell must be exactly one bold token, found "$statusCell" in: $line',
  );
  return match!.group(1)!;
}

Set<String> extractStatusMarkers(List<String> sectionLines) {
  final markers = <String>{};
  for (final line in extractTableDataRows(sectionLines)) {
    final columns = line.trim().split('|');
    if (columns.length >= 5) {
      markers.add(extractStatusToken(columns[3], line));
    }
  }
  return markers;
}

class AppendixFilePaths {
  final List<String> sourceFiles;
  final List<String> testFiles;

  AppendixFilePaths({
    required this.sourceFiles,
    required this.testFiles,
  });
}

int extractQuickReferenceCount(String row) {
  final cells = row
      .split('|')
      .map((cell) => cell.trim().replaceAll('*', ''))
      .where((cell) => cell.isNotEmpty)
      .toList();
  expect(
    cells.length,
    greaterThanOrEqualTo(2),
    reason: 'Quick Reference row must have at least two cells: $row',
  );
  return int.parse(cells[1]);
}

AppendixFilePaths extractAppendixFilePaths(String content) {
  final appendixLines =
      extractSectionLines(content, '## File Reference Appendix');
  final pathPattern = RegExp(r'`((?:lib|test)/[^`]+)`');
  final sourceFiles = <String>{};
  final testFiles = <String>{};

  for (final line in extractTableDataRows(appendixLines)) {
    for (final match in pathPattern.allMatches(line)) {
      final path = match.group(1)!;
      if (path.startsWith('lib/')) {
        sourceFiles.add(path);
      } else if (path.startsWith('test/')) {
        testFiles.add(path);
      }
    }
  }

  return AppendixFilePaths(
    sourceFiles: sourceFiles.toList()..sort(),
    testFiles: testFiles.toList()..sort(),
  );
}

void main() {
  late String content;
  late List<String> lines;

  setUpAll(() {
    final file = File('FORK_PATCHES.md');
    expect(
      file.existsSync(),
      isTrue,
      reason: 'FORK_PATCHES.md must exist at the package root',
    );
    content = file.readAsStringSync();
    lines = content.split('\n');
  });

  group('FORK_PATCHES.md structure', () {
    test('file is non-empty and titled', () {
      expect(content.trim(), isNotEmpty);
      expect(content, contains('# Fork Patches'));
    });

    test('current category section headers are present', () {
      for (final section in patchSections.keys) {
        expect(content, contains(section));
      }
    });

    test('removed algorithm section is not present', () {
      expect(content, isNot(contains('## Algorithm Patches')));
    });

    test('supporting sections are present', () {
      expect(content, contains('## Quick Reference'));
      expect(content, contains('## File Reference Appendix'));
      expect(content, contains('## Migration Cross-References'));
    });
  });

  group('FORK_PATCHES.md status markers', () {
    test('status definitions are present in the preamble', () {
      expect(content, contains('**Required**'));
      expect(content, contains('**Optional**'));
      expect(content, contains('**Experimental**'));
    });

    test('all status markers in patch tables are from the defined set', () {
      final validStatuses = {'Required', 'Optional', 'Experimental'};

      for (final section in patchSections.keys) {
        final markers =
            extractStatusMarkers(extractSectionLines(content, section));
        for (final marker in markers) {
          expect(
            validStatuses,
            contains(marker),
            reason:
                'Section "$section" has unknown status marker "**$marker**"',
          );
        }
      }
    });
  });

  group('FORK_PATCHES.md quick reference counts', () {
    late List<String> quickReferenceLines;

    setUpAll(() {
      quickReferenceLines = extractSectionLines(content, '## Quick Reference');
    });

    for (final entry in patchSections.entries) {
      final category = entry.key
          .replaceAll('## ', '')
          .replaceAll(' Patches', '')
          .replaceAll('Edge Rendering', 'Edge rendering');

      test('Quick Reference table lists $category as ${entry.value} patches',
          () {
        final row = quickReferenceLines.firstWhere(
          (line) => line.contains(category) && !line.contains('---'),
          orElse: () => '',
        );
        expect(extractQuickReferenceCount(row), equals(entry.value));
      });
    }

    test('Quick Reference total is $expectedPatchTotal', () {
      final totalRow = quickReferenceLines.firstWhere(
        (line) => line.contains('Total') && !line.contains('---'),
        orElse: () => '',
      );
      expect(
        extractQuickReferenceCount(totalRow),
        equals(expectedPatchTotal),
      );
    });

    test('individual category counts sum to $expectedPatchTotal', () {
      final total =
          patchSections.values.fold<int>(0, (sum, count) => sum + count);
      expect(total, equals(expectedPatchTotal));
    });
  });

  group('FORK_PATCHES.md section row counts', () {
    for (final entry in patchSections.entries) {
      test('${entry.key} has exactly ${entry.value} patch rows', () {
        final sectionLines = extractSectionLines(content, entry.key);
        expect(countPatchTableDataRows(sectionLines), equals(entry.value));
      });
    }

    test('total patch rows across all sections equals $expectedPatchTotal', () {
      final total = patchSections.keys.fold<int>(
        0,
        (sum, section) =>
            sum +
            countPatchTableDataRows(extractSectionLines(content, section)),
      );
      expect(total, equals(expectedPatchTotal));
    });

    test('each patch section header appears exactly once', () {
      for (final section in patchSections.keys) {
        final occurrences =
            lines.where((line) => line.trim() == section).length;
        expect(
          occurrences,
          equals(1),
          reason: 'Header "$section" must appear exactly once',
        );
      }
    });

    test('document contains no patch rows with empty status cells', () {
      for (final section in patchSections.keys) {
        final sectionLines = extractSectionLines(content, section);
        for (final line in extractTableDataRows(sectionLines)) {
          final columns = line.trim().split('|');
          if (columns.length >= 5) {
            final statusToken = extractStatusToken(columns[3], line);
            expect(
              statusToken,
              isNotEmpty,
              reason:
                  'Status cell must not be empty in section "$section": $line',
            );
          }
        }
      }
    });
  });

  group('FORK_PATCHES.md migration cross-references', () {
    test('MIGRATION.md is referenced and exists', () {
      expect(content, contains('MIGRATION.md'));
      expect(
        File('MIGRATION.md').existsSync(),
        isTrue,
        reason: 'MIGRATION.md must exist since FORK_PATCHES.md links to it',
      );
    });

    test('core migration items are documented', () {
      final migrationSection =
          extractSectionLines(content, '## Migration Cross-References');
      final joined = migrationSection.join('\n');

      expect(joined, contains('Node.Id()'));
      expect(joined, contains('GraphView.builder()'));
      expect(joined, contains('Graph.getNodeUsingId()'));
    });
  });

  group('FORK_PATCHES.md file references', () {
    test('source file references exist on disk', () {
      final sourceFiles = extractAppendixFilePaths(content).sourceFiles;
      expect(sourceFiles, isNotEmpty);

      for (final path in sourceFiles) {
        expect(
          File(path).existsSync(),
          isTrue,
          reason:
              'Source file "$path" referenced in FORK_PATCHES.md must exist',
        );
      }
    });

    test('test file references exist on disk', () {
      final testFiles = extractAppendixFilePaths(content).testFiles;
      expect(testFiles, isNotEmpty);

      for (final path in testFiles) {
        expect(
          File(path).existsSync(),
          isTrue,
          reason: 'Test file "$path" referenced in FORK_PATCHES.md must exist',
        );
      }
    });
  });

  group('FORK_PATCHES.md file reference appendix', () {
    test('appendix contains exactly the retained categories', () {
      final appendixLines =
          extractSectionLines(content, '## File Reference Appendix');
      final categories = extractTableDataRows(appendixLines)
          .map((row) => extractTableCells(row).first)
          .toList();

      expect(categories, equals(appendixCategories));
    });
  });
}
