@TestOn('browser')
library;

import 'package:test/test.dart';
import 'package:turing_lab/core/interoperability/interoperability.dart';

import '../../../tool/compatibility_corpus/catalog.dart';
import '../../../tool/hard_edge/families/codec_matrix.dart';
import '../../../tool/hard_edge/families/codec_parity.dart';
import '../../../tool/hard_edge/families/codec_parity_vectors.dart';

void main() {
  test('all codec outcomes match the committed native VM snapshots', () {
    final catalog = CompatibilityCodecCatalog.create();
    expect(
      codecParityVectors.map((vector) => vector.codecId).toList()..sort(),
      orderedEquals(codecIds),
    );
    for (final vector in codecParityVectors) {
      final codec = catalog.codecs[vector.codecId]!;
      final canonical = codecCanonicalOutcome(
        codec,
        DocumentPayload(bytes: vector.payload, filename: vector.filename),
      );
      final digest = codecCanonicalOutcomeSha256(
        codec,
        DocumentPayload(
          bytes: vector.payload,
          filename: vector.filename,
        ),
      );
      expect(
        digest,
        vector.nativeOutcomeSha256,
        reason: '${vector.codecId}\n$canonical',
      );
    }
  });
}
