import 'package:flutter_test/flutter_test.dart';
import 'package:turing_lab/core/algorithms/language_comparison_messages.dart';
import 'package:turing_lab/core/algorithms/language_comparison_step_messages.dart';
import 'package:turing_lab/core/messages/structured_message.dart';
import 'package:turing_lab/l10n/app_localizations_en.dart';
import 'package:turing_lab/l10n/app_localizations_pt.dart';
import 'package:turing_lab/l10n/app_localizations_structured_messages.dart';

void main() {
  final en = AppLocalizationsEn();
  final pt = AppLocalizationsPt();

  test(
    'language comparison validation messages keep side and localize prose',
    () {
      final cases = <({StructuredMessage message, String en, String pt})>[
        (
          message: LanguageComparisonMessages.emptyStateSet('A'),
          en: 'Automaton A must have at least one state',
          pt: 'O autômato A deve ter pelo menos um estado',
        ),
        (
          message: LanguageComparisonMessages.missingInitialState('B'),
          en: 'Automaton B must have an initial state',
          pt: 'O autômato B deve ter um estado inicial',
        ),
        (
          message: LanguageComparisonMessages.initialStateOutsideSet('A'),
          en: 'The initial state of automaton A must belong to the state set',
          pt: 'O estado inicial do autômato A deve pertencer ao conjunto de estados',
        ),
      ];

      for (final testCase in cases) {
        expect(en.resolveStructuredMessage(testCase.message), testCase.en);
        expect(pt.resolveStructuredMessage(testCase.message), testCase.pt);
      }
    },
  );

  test('invalid argument contracts use the localized stable-code fallback', () {
    final malformed = LanguageComparisonMessages.emptyStateSet('C');

    expect(
      en.resolveStructuredMessage(malformed),
      contains('language.comparison.empty-state-set'),
    );
    expect(
      pt.resolveStructuredMessage(malformed),
      contains('language.comparison.empty-state-set'),
    );
  });

  test(
    'internal comparison failures resolve to the safe localized headline',
    () {
      final message = LanguageComparisonMessages.internalFailure();

      expect(
        en.resolveStructuredMessage(message),
        en.languageComparisonAnalysisFailed,
      );
      expect(
        pt.resolveStructuredMessage(message),
        pt.languageComparisonAnalysisFailed,
      );
    },
  );

  test('language comparison trace messages resolve every localized step', () {
    final cases = <({StructuredMessage message, String en, String pt})>[
      (
        message: LanguageComparisonStepMessages.validation(),
        en: en.languageComparisonDescriptionValidation,
        pt: pt.languageComparisonDescriptionValidation,
      ),
      (
        message: LanguageComparisonStepMessages.initialization(),
        en: en.languageComparisonDescriptionInitialization,
        pt: pt.languageComparisonDescriptionInitialization,
      ),
      (
        message: LanguageComparisonStepMessages.alphabetNormalization(),
        en: en.languageComparisonDescriptionAlphabet,
        pt: pt.languageComparisonDescriptionAlphabet,
      ),
      (
        message: LanguageComparisonStepMessages.nfaToDfa('A'),
        en: en.languageComparisonDescriptionNfaToDfa('A'),
        pt: pt.languageComparisonDescriptionNfaToDfa('A'),
      ),
      (
        message: LanguageComparisonStepMessages.dfaCompletion('B'),
        en: en.languageComparisonDescriptionDfaCompletion('B'),
        pt: pt.languageComparisonDescriptionDfaCompletion('B'),
      ),
      (
        message: LanguageComparisonStepMessages.productConstructionStart(),
        en: en.languageComparisonDescriptionProductStart,
        pt: pt.languageComparisonDescriptionProductStart,
      ),
      (
        message: LanguageComparisonStepMessages.productStateCreated('(q0,q1)'),
        en: en.languageComparisonDescriptionProductState('(q0,q1)'),
        pt: pt.languageComparisonDescriptionProductState('(q0,q1)'),
      ),
      (
        message: LanguageComparisonStepMessages.productTransitionCreated('ε'),
        en: en.languageComparisonDescriptionProductTransition('ε'),
        pt: pt.languageComparisonDescriptionProductTransition('ε'),
      ),
      (
        message: LanguageComparisonStepMessages.productConstructionComplete(),
        en: en.languageComparisonDescriptionProductComplete,
        pt: pt.languageComparisonDescriptionProductComplete,
      ),
      (
        message: LanguageComparisonStepMessages.bfsSearchStart(),
        en: en.languageComparisonDescriptionBfsStart,
        pt: pt.languageComparisonDescriptionBfsStart,
      ),
      (
        message: LanguageComparisonStepMessages.bfsInitialCheck(
          acceptsA: true,
          acceptsB: false,
        ),
        en: en.languageComparisonDescriptionInitialCheck('true'),
        pt: pt.languageComparisonDescriptionInitialCheck('true'),
      ),
      (
        message: LanguageComparisonStepMessages.bfsExplorePair(
          stateA: 'q0',
          stateB: 'q1',
        ),
        en: en.languageComparisonDescriptionExplorePair('q0', 'q1'),
        pt: pt.languageComparisonDescriptionExplorePair('q0', 'q1'),
      ),
      (
        message: LanguageComparisonStepMessages.bfsDistinguishingFound('ab'),
        en: en.languageComparisonDescriptionCounterexample('ab'),
        pt: pt.languageComparisonDescriptionCounterexample('ab'),
      ),
      (
        message: LanguageComparisonStepMessages.bfsComplete(),
        en: en.languageComparisonDescriptionBfsComplete,
        pt: pt.languageComparisonDescriptionBfsComplete,
      ),
      (
        message: LanguageComparisonStepMessages.result(isEquivalent: false),
        en: en.languageComparisonDescriptionResult('false'),
        pt: pt.languageComparisonDescriptionResult('false'),
      ),
      (
        message: LanguageComparisonStepMessages.error(),
        en: en.languageComparisonDescriptionError,
        pt: pt.languageComparisonDescriptionError,
      ),
      (
        message: LanguageComparisonStepMessages.unknown('future-step'),
        en: en.languageComparisonDescriptionUnknown,
        pt: pt.languageComparisonDescriptionUnknown,
      ),
    ];

    for (final testCase in cases) {
      expect(
        en.resolveStructuredMessage(testCase.message),
        testCase.en,
        reason: testCase.message.stableCode,
      );
      expect(
        pt.resolveStructuredMessage(testCase.message),
        testCase.pt,
        reason: testCase.message.stableCode,
      );
    }
  });

  test('trace argument contracts reject malformed structured values', () {
    final malformed = LanguageComparisonStepMessages.nfaToDfa('C');

    expect(
      en.resolveStructuredMessage(malformed),
      contains('language.comparison.trace.nfa-to-dfa'),
    );
    expect(
      pt.resolveStructuredMessage(malformed),
      contains('language.comparison.trace.nfa-to-dfa'),
    );
  });
}
