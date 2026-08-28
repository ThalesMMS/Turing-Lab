import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:turing_lab/core/manual_conversions/manual_conversion_session.dart';
import 'package:turing_lab/data/services/manual_conversion_session_store.dart';

void main() {
  test('persists and restores a manual construction locally', () async {
    SharedPreferences.setMockInitialValues({});
    final preferences = await SharedPreferences.getInstance();
    final store = ManualConversionSessionStore(preferences);
    final session = ManualConversionSession.start(
      id: 'session',
      direction: ManualConversionDirection.regularGrammarToFa,
      source: ManualConversionSource(
        documentId: 'grammar',
        revision: 2,
        snapshot: const {'start': 'S'},
      ),
      requirements: const [],
      canonicalArtifact: const {
        'states': ['S'],
      },
      completionEvidence: ManualConversionEvidence(
        summary: 'Exact construction.',
        certainty: ManualConversionCertainty.exact,
      ),
    );

    expect(await store.save('grammar-to-fa', session), isTrue);
    final restored = store.load(
      'grammar-to-fa',
      documentId: 'grammar',
      revision: 2,
    );
    expect(restored.isSuccess, isTrue);
    expect(restored.session!.toJson(), session.toJson());

    final stale = store.load(
      'grammar-to-fa',
      documentId: 'grammar',
      revision: 3,
    );
    expect(stale.isSuccess, isFalse);
    expect(
      stale.diagnostics.single.code,
      ManualConversionDiagnosticCode.sourceChanged,
    );
  });

  test('reports malformed persisted values instead of throwing', () async {
    SharedPreferences.setMockInitialValues({
      '${ManualConversionSessionStore.keyPrefix}wrong-type': 42,
      '${ManualConversionSessionStore.keyPrefix}invalid-json': '{not json',
    });
    final preferences = await SharedPreferences.getInstance();
    final store = ManualConversionSessionStore(preferences);

    for (final workspaceKey in ['wrong-type', 'invalid-json']) {
      final restored = store.load(
        workspaceKey,
        documentId: 'grammar',
        revision: 2,
      );
      expect(restored.isSuccess, isFalse);
      expect(
        restored.diagnostics.single.code,
        ManualConversionDiagnosticCode.malformedPayload,
      );
      expect(
        restored.diagnostics.single.structuredMessage?.stableCode,
        'service.manual-conversion-store.malformed-payload',
      );
    }
  });
}
