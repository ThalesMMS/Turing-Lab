import 'package:flutter_test/flutter_test.dart';
import 'package:turing_lab/core/grammar/phrase_structure/phrase_structure.dart';
import 'package:turing_lab/data/grammar/unrestricted_grammar_example_catalog.dart';
import 'package:turing_lab/presentation/content/unrestricted_grammar_example_content_copy.dart';

void main() {
  test(
    'covers all three shipped stable ids in English and Portuguese',
    () async {
      final examples = await const UnrestrictedGrammarExampleCatalog()
          .loadExamples();
      final expectedIds = examples.map((example) => example.id).toList();

      expect(UnrestrictedGrammarExampleContentCopies.ids, expectedIds);
      expect(expectedIds, hasLength(3));
      for (final id in expectedIds) {
        final en = UnrestrictedGrammarExampleContentCopies.resolve(
          id: id,
          languageCode: 'en',
        );
        final pt = UnrestrictedGrammarExampleContentCopies.resolve(
          id: id,
          languageCode: 'pt-BR',
        );
        for (final copy in [en, pt]) {
          expect(copy.title, isNotEmpty);
          expect(copy.summary, isNotEmpty);
          expect(copy.learningObjective, isNotEmpty);
          expect(copy.limitation, isNotEmpty);
          expect(copy.accessibleDescription, isNotEmpty);
          expect(copy.semanticLabel, contains(copy.accessibleDescription));
        }
        expect(pt.summary, isNot(en.summary));
        expect(pt.learningObjective, isNot(en.learningObjective));
        expect(pt.accessibleDescription, isNot(en.accessibleDescription));
      }
    },
  );

  test('fails closed for an unknown stable id', () {
    expect(
      () => UnrestrictedGrammarExampleContentCopies.resolve(
        id: 'unrestricted-grammar.unknown',
        languageCode: 'en',
      ),
      throwsA(
        isA<StateError>().having(
          (error) => error.message,
          'message',
          'unrestricted-grammar-example.copy-id',
        ),
      ),
    );
  });

  test('resolving localized copy does not change formal payloads', () async {
    final examples = await const UnrestrictedGrammarExampleCatalog()
        .loadExamples();
    final before = [
      for (final example in examples)
        (example.payload as UnrestrictedGrammar).toJson(),
    ];

    for (final example in examples) {
      UnrestrictedGrammarExampleContentCopies.resolve(
        id: example.id,
        languageCode: 'en',
      );
      UnrestrictedGrammarExampleContentCopies.resolve(
        id: example.id,
        languageCode: 'pt-BR',
      );
    }

    expect([
      for (final example in examples)
        (example.payload as UnrestrictedGrammar).toJson(),
    ], before);
  });
}
