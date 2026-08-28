import 'package:flutter_test/flutter_test.dart';
import 'package:turing_lab/core/messages/structured_message.dart';
import 'package:turing_lab/core/pumping_lemma/pumping_lemma.dart';
import 'package:turing_lab/l10n/app_localizations_en.dart';
import 'package:turing_lab/l10n/app_localizations_pt.dart';
import 'package:turing_lab/l10n/app_localizations_structured_messages.dart';
import 'package:turing_lab/presentation/content/pumping_lemma_problem_content_copy.dart';

void main() {
  test(
    'structured pumping messages round-trip and resolve at current locale',
    () {
      final message = PumpingLemmaMessages.witnessMinimumTokens(7);
      final restored = StructuredMessage.fromJson(message.toJson());

      expect(restored, message);
      expect(
        AppLocalizationsEn().resolveStructuredMessage(restored),
        'The witness must contain at least 7 tokens.',
      );
      expect(
        AppLocalizationsPt().resolveStructuredMessage(restored),
        'A testemunha deve conter pelo menos 7 tokens.',
      );
    },
  );

  test('malformed typed arguments use the safe stable-code fallback', () {
    final malformed = StructuredMessage(
      namespace: 'pumping',
      code: 'validation.witness-minimum-tokens',
      category: StructuredMessageCategory.validation,
      severity: StructuredMessageSeverity.error,
      arguments: {
        'minimum': StructuredMessageArgument.literal(
          'seven',
          role: 'minimum-token-count',
        ),
      },
    );

    expect(
      AppLocalizationsEn().resolveStructuredMessage(malformed),
      contains(malformed.stableCode),
    );
    expect(
      AppLocalizationsPt().resolveStructuredMessage(malformed),
      contains(malformed.stableCode),
    );
  });

  test(
    'educational copy is bilingual while core JSON stays locale-neutral',
    () {
      final problem = PumpingLemmaProblemCatalog.regular.first;
      final json = problem.toJson();
      final en = PumpingLemmaProblemContentCopies.resolve(
        id: problem.id,
        languageCode: 'en',
      );
      final pt = PumpingLemmaProblemContentCopies.resolve(
        id: problem.id,
        languageCode: 'pt-BR',
      );

      expect(PumpingLemmaProblemContentCopies.ids, hasLength(26));
      expect(en.title, 'Equal a and b blocks');
      expect(pt.title, 'Blocos iguais de a e b');
      expect(json, isNot(contains('title')));
      expect(json, isNot(contains('learningObjective')));
      expect(json, isNot(contains('hint')));
      expect(json, isNot(contains('explanation')));
      expect(PumpingLemmaProblem.fromJson(json), problem);
    },
  );

  test('legacy imported title remains user-authored custom copy', () {
    final json = {
      ...PumpingLemmaProblemCatalog.regular.first.toJson(),
      'id': 'jflap-regular-user-title',
      'title': 'My imported language',
    };

    final problem = PumpingLemmaProblem.fromJson(json);

    expect(problem.customTitle, 'My imported language');
    expect(problem.toJson()['customTitle'], 'My imported language');
    expect(problem.toJson(), isNot(contains('title')));
  });
}
