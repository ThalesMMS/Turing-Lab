import 'dart:convert';
import 'dart:io';

import 'package:test/test.dart';

import '../../../tool/hard_edge/cross_family_certification.dart';

void main() {
  test('cross-family matrix uses real paths and preserves typed unknowns',
      () async {
    final matrix = jsonDecode(
      File('test/fixtures/hard_edge/cross_family/matrix.v1.json')
          .readAsStringSync(),
    ) as Map<String, Object?>;
    final rows = (matrix['checks']! as List).cast<Map<String, Object?>>();
    final expected = {
      for (final row in rows)
        row['id']! as String:
            CrossFamilyOutcome.values.byName(row['expectedOutcome']! as String),
    };

    final report = await CrossFamilyCertification.run();

    expect(report.matchesExpectedOutcomes(expected), isTrue,
        reason: const JsonEncoder.withIndent('  ').convert(report.toJson()));
    expect(report.inconclusiveCount, 2);
    expect(report.certificationCount, rows.length - 2);
    expect(report.toJson()['status'], 'incomplete');
    for (final observation in report.observations) {
      final row = rows.singleWhere((item) => item['id'] == observation.id);
      expect(observation.equivalence.name, row['equivalence'],
          reason: observation.id);
      if (observation.outcome == CrossFamilyOutcome.boundedUnknown) {
        expect(observation.certified, isFalse, reason: observation.id);
      }
    }
  });

  test('matrix exercises every declared equivalence relation', () {
    final matrix = jsonDecode(
      File('test/fixtures/hard_edge/cross_family/matrix.v1.json')
          .readAsStringSync(),
    ) as Map<String, Object?>;
    final rows = (matrix['checks']! as List).cast<Map<String, Object?>>();

    expect(
      rows.map((row) => row['equivalence']).toSet(),
      CrossFamilyEquivalence.values.map((value) => value.name).toSet(),
    );
  });
}
