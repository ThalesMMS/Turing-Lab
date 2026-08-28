import 'package:flutter_test/flutter_test.dart';
import 'package:turing_lab/presentation/content/tm_block_example_content_copy.dart';

void main() {
  test('provides complete distinct English and Portuguese content', () {
    final en = TMBlockExampleContentCopies.resolve(
      id: TMBlockExampleContentCopies.id,
      languageCode: 'en',
    );
    final pt = TMBlockExampleContentCopies.resolve(
      id: TMBlockExampleContentCopies.id,
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
  });

  test('fails closed for an unknown content id', () {
    expect(
      () => TMBlockExampleContentCopies.resolve(
        id: 'unknown',
        languageCode: 'en',
      ),
      throwsStateError,
    );
  });
}
