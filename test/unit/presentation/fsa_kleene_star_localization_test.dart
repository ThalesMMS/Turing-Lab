import 'package:flutter_test/flutter_test.dart';
import 'package:turing_lab/core/algorithms/fsa_kleene_star_messages.dart';
import 'package:turing_lab/l10n/app_localizations_en.dart';
import 'package:turing_lab/l10n/app_localizations_pt.dart';
import 'package:turing_lab/l10n/app_localizations_structured_messages.dart';

void main() {
  final en = AppLocalizationsEn();
  final pt = AppLocalizationsPt();

  test('resolves FSA Kleene-star diagnostics in both locales', () {
    expect(
      en.resolveStructuredMessage(FsaKleeneStarMessages.emptyOperand()),
      en.fsaKleeneStarEmptyOperand,
    );
    expect(
      pt.resolveStructuredMessage(FsaKleeneStarMessages.emptyOperand()),
      pt.fsaKleeneStarEmptyOperand,
    );
    expect(
      en.resolveStructuredMessage(
        FsaKleeneStarMessages.invalidTransition('t0'),
      ),
      'The Kleene-star operand contains an invalid transition: t0.',
    );
    expect(
      pt.resolveStructuredMessage(
        FsaKleeneStarMessages.invalidTransition('t0'),
      ),
      'O operando da estrela de Kleene contém uma transição inválida: t0.',
    );
    expect(
      pt.resolveStructuredMessage(FsaKleeneStarMessages.stepTitle('clone')),
      pt.fsaKleeneStarCloneTitle,
    );
    expect(
      pt.resolveStructuredMessage(
        FsaKleeneStarMessages.repeatExplanation(hasAcceptingStates: false),
      ),
      pt.fsaKleeneStarRepeatEmptyExplanation,
    );
  });

  test('malformed transition arguments use the stable fallback', () {
    final malformed = FsaKleeneStarMessages.invalidTransition('');
    expect(
      en.resolveStructuredMessage(malformed),
      contains('automaton.fsa-kleene-star.invalid-transition'),
    );
  });
}
