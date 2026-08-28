import 'package:flutter_test/flutter_test.dart';
import 'package:turing_lab/data/l_systems/l_system_examples.dart';
import 'package:turing_lab/presentation/content/l_system_example_content_copy.dart';

void main() {
  test('covers all six shipped stable ids in English and Portuguese', () {
    final expectedIds = LSystemExamples.values
        .map((example) => example.id)
        .toList(growable: false);

    expect(LSystemExampleContentCopies.ids, expectedIds);
    expect(expectedIds, hasLength(6));
    for (final id in expectedIds) {
      final en = LSystemExampleContentCopies.resolve(
        id: id,
        languageCode: 'en',
      );
      final pt = LSystemExampleContentCopies.resolve(
        id: id,
        languageCode: 'pt-BR',
      );
      for (final copy in [en, pt]) {
        expect(copy.title, isNotEmpty);
        expect(copy.summary, isNotEmpty);
        expect(copy.learningObjective, isNotEmpty);
        expect(copy.limitation, isNotEmpty);
        expect(copy.accessibleVisualizationDescription, isNotEmpty);
        expect(
          copy.semanticLabel,
          contains(copy.accessibleVisualizationDescription),
        );
      }
      expect(pt.title, isNot(en.title));
      expect(pt.summary, isNot(en.summary));
      expect(
        pt.accessibleVisualizationDescription,
        isNot(en.accessibleVisualizationDescription),
      );
    }
  });

  test('fails closed for an unknown stable id', () {
    expect(
      () => LSystemExampleContentCopies.resolve(
        id: 'l-system.unknown',
        languageCode: 'en',
      ),
      throwsA(
        isA<StateError>().having(
          (error) => error.message,
          'message',
          'l-system-example.copy-id',
        ),
      ),
    );
  });

  test('resolving localized copy does not change formal documents', () {
    final before = [
      for (final example in LSystemExamples.values) example.document.toJson(),
    ];

    for (final example in LSystemExamples.values) {
      LSystemExampleContentCopies.resolve(id: example.id, languageCode: 'en');
      LSystemExampleContentCopies.resolve(
        id: example.id,
        languageCode: 'pt-BR',
      );
    }

    expect([
      for (final example in LSystemExamples.values) example.document.toJson(),
    ], before);
  });
}
