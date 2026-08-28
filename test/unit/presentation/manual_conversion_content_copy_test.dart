import 'package:flutter_test/flutter_test.dart';
import 'package:turing_lab/core/manual_conversions/manual_conversion_content.dart';
import 'package:turing_lab/core/manual_conversions/manual_conversion_session.dart';
import 'package:turing_lab/presentation/content/manual_conversion_content_copy.dart';

void main() {
  test(
    'covers all 22 shipped manual-conversion references in EN and PT-BR',
    () {
      expect(ManualConversionContentCopies.references, hasLength(22));
      expect(
        ManualConversionContentCopies.references.toSet(),
        ManualConversionContent.shipped.toSet(),
      );

      for (final reference in ManualConversionContent.shipped) {
        final arguments = {
          for (final key in reference.argumentKeys) key: '$key-value',
        };
        final en = ManualConversionContentCopies.resolve(
          reference: reference,
          languageCode: 'en',
          arguments: arguments,
        )!;
        final pt = ManualConversionContentCopies.resolve(
          reference: reference,
          languageCode: 'pt_BR',
          arguments: arguments,
        )!;

        for (final copy in [en, pt]) {
          expect(copy.title, isNotEmpty);
          expect(copy.instruction, isNotEmpty);
          expect(copy.hint, isNotEmpty);
          expect(copy.revealExplanation, isNotEmpty);
          expect(copy.accessibleDescription, isNotEmpty);
          expect(
            '${copy.title}${copy.instruction}${copy.hint}'
            '${copy.revealExplanation}${copy.accessibleDescription}',
            isNot(matches(RegExp(r'\{[A-Za-z][A-Za-z0-9]*\}'))),
          );
        }
        expect(en.title, isNot(pt.title));
        expect(en.accessibleDescription, isNot(pt.accessibleDescription));
      }
    },
  );

  test('does not resolve the compatibility-only legacy reference', () {
    expect(
      ManualConversionContentCopies.resolve(
        reference: ManualConversionContent.legacy,
        languageCode: 'en',
        arguments: const {},
      ),
      isNull,
    );
  });

  test('fails closed when a declared formal argument is unavailable', () {
    expect(
      () => ManualConversionContentCopies.resolve(
        reference: ManualConversionContent.faToRegexComplete,
        languageCode: 'en',
        arguments: const {},
      ),
      throwsA(
        isA<StateError>().having(
          (error) => error.message,
          'code',
          'manual_conversion.copy_argument.regex',
        ),
      ),
    );
  });

  test('resolves pair-expression aliases from formal requirement data', () {
    final requirement = ManualConversionRequirement(
      id: 'pair',
      contentReference: ManualConversionContent.faToRegexPairExpression,
      type: ManualConversionActionType.submitPairExpression,
      title: 'legacy',
      instruction: 'legacy',
      expectedPayload: const {
        'fromStateId': 'q0',
        'toStateId': 'q2',
        'expression': 'a|bc*d',
      },
      supportingData: const {
        'selectedStateId': 'q1',
        'directExpression': 'a',
        'incomingExpression': 'b',
        'loopExpression': 'c',
        'outgoingExpression': 'd',
      },
      hint: 'legacy',
      revealExplanation: 'legacy',
      evidence: ManualConversionEvidence(summary: 'formal evidence'),
    );

    final copy = ManualConversionContentCopies.resolveRequirement(
      requirement: requirement,
      languageCode: 'pt_BR',
    )!;

    expect(copy.title, 'Atualize q0 para q2');
    expect(copy.instruction, contains('q1'));
    expect(copy.revealExplanation, contains('a|bc*d'));
  });
}
