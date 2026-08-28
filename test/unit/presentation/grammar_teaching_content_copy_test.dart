import 'package:flutter_test/flutter_test.dart';
import 'package:turing_lab/core/grammar/teaching/grammar_teaching_content.dart';
import 'package:turing_lab/presentation/content/grammar_teaching_content_copy.dart';

void main() {
  test('covers all nine grammar-teaching references in EN and PT-BR', () {
    expect(GrammarTeachingContentCopies.references, hasLength(9));
    expect(
      GrammarTeachingContentCopies.references.toSet(),
      GrammarTeachingContent.shipped.toSet(),
    );

    for (final reference in GrammarTeachingContent.shipped) {
      final arguments = {
        for (final key in reference.argumentKeys) key: '$key-value',
      };
      final en = GrammarTeachingContentCopies.resolve(
        reference: reference,
        languageCode: 'en',
        arguments: arguments,
      );
      final pt = GrammarTeachingContentCopies.resolve(
        reference: reference,
        languageCode: 'pt_BR',
        arguments: arguments,
      );

      for (final copy in [en, pt]) {
        expect(copy.title, isNotEmpty);
        expect(copy.instruction, isNotEmpty);
        expect(copy.accessibleDescription, isNotEmpty);
        expect(
          '${copy.title}${copy.instruction}${copy.accessibleDescription}',
          isNot(matches(RegExp(r'\{[A-Za-z][A-Za-z0-9]*\}'))),
        );
      }
      expect(en.title, isNot(pt.title));
      expect(en.accessibleDescription, isNot(pt.accessibleDescription));
    }
  });

  test('fails closed for an unavailable formal argument', () {
    expect(
      () => GrammarTeachingContentCopies.resolve(
        reference: GrammarTeachingContent.userDerivation,
        languageCode: 'en',
        arguments: const {},
      ),
      throwsA(
        isA<StateError>().having(
          (error) => error.message,
          'code',
          'grammar_teaching.copy_argument.target',
        ),
      ),
    );
  });
}
