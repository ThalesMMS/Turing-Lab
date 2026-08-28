import 'package:flutter_test/flutter_test.dart';
import 'package:turing_lab/core/educational_content/educational_content_reference.dart';
import 'package:turing_lab/core/grammar/teaching/grammar_teaching_content.dart';
import 'package:turing_lab/core/manual_conversions/manual_conversion_content.dart';

void main() {
  test('shipped catalogs expose 31 unique versioned references', () {
    final shipped = <EducationalContentReference>[
      ...ManualConversionContent.shipped,
      ...GrammarTeachingContent.shipped,
    ];

    expect(shipped, hasLength(31));
    expect(shipped.map((reference) => reference.id).toSet(), hasLength(31));
    expect(shipped.every((reference) => reference.version == 1), isTrue);
  });

  test('reference is immutable and has value semantics', () {
    final first = EducationalContentReference(
      id: 'grammar-teaching/sample',
      version: 2,
      argumentKeys: const ['stateId'],
    );
    final second = EducationalContentReference.fromJson(first.toJson());

    expect(second, first);
    expect(second.hashCode, first.hashCode);
    expect(() => second.argumentKeys.add('symbol'), throwsUnsupportedError);
  });

  test('rejects invalid identity, version and argument contracts', () {
    expect(
      () => EducationalContentReference(id: 'unnamespaced', version: 1),
      throwsA(
        isA<EducationalContentReferenceException>().having(
          (error) => error.code,
          'code',
          EducationalContentReferenceErrorCode.invalidId,
        ),
      ),
    );
    expect(
      () => EducationalContentReference(
        id: 'grammar-teaching/sample',
        version: 0,
      ),
      throwsA(
        isA<EducationalContentReferenceException>().having(
          (error) => error.code,
          'code',
          EducationalContentReferenceErrorCode.invalidVersion,
        ),
      ),
    );
    expect(
      () => EducationalContentReference(
        id: 'grammar-teaching/sample',
        version: 1,
        argumentKeys: const [''],
      ),
      throwsA(
        isA<EducationalContentReferenceException>().having(
          (error) => error.code,
          'code',
          EducationalContentReferenceErrorCode.invalidArgumentKey,
        ),
      ),
    );
    expect(
      () => EducationalContentReference(
        id: 'grammar-teaching/sample',
        version: 1,
        argumentKeys: const ['stateId', 'stateId'],
      ),
      throwsA(
        isA<EducationalContentReferenceException>().having(
          (error) => error.code,
          'code',
          EducationalContentReferenceErrorCode.duplicateArgumentKey,
        ),
      ),
    );
  });
}
