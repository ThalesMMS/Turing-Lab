import 'package:flutter_test/flutter_test.dart';
import 'package:turing_lab/data/data_sources/examples_asset_data_source.dart';
import 'package:turing_lab/presentation/content/asset_example_content_copy.dart';

void main() {
  const expectedIds = {
    'asset/afd_binary_divisible_by_3',
    'asset/afd_contains_ab',
    'asset/afd_ends_with_a',
    'asset/afd_parity_ab',
    'asset/afn_lambda_a_or_ab',
    'asset/apda_anb2n',
    'asset/apda_anbn',
    'asset/apda_balanced_parentheses',
    'asset/apda_mirrored_separator',
    'asset/apda_palindrome',
    'asset/glc_anbn',
    'asset/glc_arithmetic_expressions',
    'asset/glc_balanced_parentheses',
    'asset/glc_even_zeros',
    'asset/glc_palindrome',
    'asset/regex_a_star',
    'asset/regex_a_then_b',
    'asset/regex_ab_or_ba_pairs',
    'asset/regex_binary_starts_zero',
    'asset/regex_ends_with_ab',
    'asset/tm_anbn',
    'asset/tm_binary_to_unary',
    'asset/tm_copy_string',
    'asset/tm_increment',
    'asset/tm_multitape_comparison',
    'asset/tm_multitape_copy',
    'asset/tm_multitape_palindrome',
    'asset/tm_multitape_work_tape',
    'asset/tm_palindrome',
  };

  test('covers exactly the twenty-nine bilingual asset examples', () {
    expect(AssetExampleContentCopies.ids.toSet(), expectedIds);

    for (final id in expectedIds) {
      final en = AssetExampleContentCopies.resolve(id: id, languageCode: 'en');
      final pt = AssetExampleContentCopies.resolve(
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
      expect(pt.title, isNot(en.title));
      expect(pt.summary, isNot(en.summary));
      expect(pt.learningObjective, isNot(en.learningObjective));
      expect(pt.limitation, isNot(en.limitation));
      expect(pt.accessibleDescription, isNot(en.accessibleDescription));
    }
  });

  test('does not claim localized content for any other asset id', () {
    expect(
      AssetExampleContentCopies.maybeResolve(
        id: 'asset/not_localized',
        languageCode: 'pt-BR',
      ),
      isNull,
    );
    expect(
      () => AssetExampleContentCopies.resolve(
        id: 'asset/not_localized',
        languageCode: 'en',
      ),
      throwsStateError,
    );
  });

  test(
    'copy resolution preserves all ten PDA and Grammar formal payloads',
    () async {
      const pdaIds = {
        'asset/apda_anb2n',
        'asset/apda_anbn',
        'asset/apda_balanced_parentheses',
        'asset/apda_mirrored_separator',
        'asset/apda_palindrome',
      };
      const grammarIds = {
        'asset/glc_anbn',
        'asset/glc_arithmetic_expressions',
        'asset/glc_balanced_parentheses',
        'asset/glc_even_zeros',
        'asset/glc_palindrome',
      };
      final source = ExamplesAssetDataSource();
      final pdaExamples = (await source.loadAllTypedPdaExamples()).data!;
      final grammarExamples = (await source.loadAllTypedCfgExamples()).data!;

      expect(pdaExamples.map((example) => example.id).toSet(), pdaIds);
      expect(grammarExamples.map((example) => example.id).toSet(), grammarIds);

      for (final example in pdaExamples) {
        final before = example.payload.toJson();
        AssetExampleContentCopies.resolve(id: example.id, languageCode: 'en');
        AssetExampleContentCopies.resolve(
          id: example.id,
          languageCode: 'pt-BR',
        );
        expect(example.payload.toJson(), before, reason: example.id);
      }
      for (final example in grammarExamples) {
        final before = example.payload.toJson();
        AssetExampleContentCopies.resolve(id: example.id, languageCode: 'en');
        AssetExampleContentCopies.resolve(
          id: example.id,
          languageCode: 'pt-BR',
        );
        expect(example.payload.toJson(), before, reason: example.id);
      }
    },
  );

  test('copy resolution preserves all nine TM formal payloads', () async {
    const tmIds = {
      'asset/tm_anbn',
      'asset/tm_binary_to_unary',
      'asset/tm_copy_string',
      'asset/tm_increment',
      'asset/tm_multitape_comparison',
      'asset/tm_multitape_copy',
      'asset/tm_multitape_palindrome',
      'asset/tm_multitape_work_tape',
      'asset/tm_palindrome',
    };
    final source = ExamplesAssetDataSource();
    final examples = (await source.loadAllTypedTmExamples()).data!;
    final assetExamples = examples
        .where((example) => tmIds.contains(example.id))
        .toList(growable: false);

    expect(assetExamples.map((example) => example.id).toSet(), tmIds);
    expect(
      assetExamples.where((example) => example.payload.tapeCount == 1),
      hasLength(5),
    );
    expect(
      assetExamples.where((example) => example.payload.tapeCount == 2),
      hasLength(4),
    );

    for (final example in assetExamples) {
      final before = example.payload.toJson();
      AssetExampleContentCopies.resolve(id: example.id, languageCode: 'en');
      AssetExampleContentCopies.resolve(id: example.id, languageCode: 'pt-BR');
      expect(example.payload.toJson(), before, reason: example.id);
    }
  });
}
