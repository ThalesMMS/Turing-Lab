import 'package:flutter_test/flutter_test.dart';
import 'package:turing_lab/core/algorithms/grammar_cnf_messages.dart';
import 'package:turing_lab/core/algorithms/grammar_gnf_messages.dart';
import 'package:turing_lab/core/algorithms/grammar_to_pda_messages.dart';
import 'package:turing_lab/core/algorithms/pda_normalization_messages.dart';
import 'package:turing_lab/core/algorithms/pda_simplification_messages.dart';
import 'package:turing_lab/core/messages/structured_message.dart';
import 'package:turing_lab/core/models/pda_acceptance_mode.dart';
import 'package:turing_lab/l10n/app_localizations_en.dart';
import 'package:turing_lab/l10n/app_localizations_pt.dart';
import 'package:turing_lab/l10n/app_localizations_structured_messages.dart';

void main() {
  final en = AppLocalizationsEn();
  final pt = AppLocalizationsPt();

  group('CNF structured messages', () {
    test('resolves diagnostics and step payloads in both locales', () {
      final messages = <StructuredMessage>[
        GrammarCnfMessages.grammarNotCfg('regular'),
        GrammarCnfMessages.startSymbolRenameFailed(),
        GrammarCnfMessages.notStrictCnf('RHS length 3'),
        GrammarCnfMessages.nullableSubsetLimitExceeded(
          productionId: 'p1',
          nullablePositionCount: 4,
          subsetCount: 16,
          limit: 8,
        ),
        GrammarCnfMessages.newSymbolLimitReached(5),
        for (final step in const [
          'start-symbol',
          'epsilon',
          'unit',
          'useless',
          'binarize',
        ]) ...[
          GrammarCnfMessages.stepTitle(step),
          GrammarCnfMessages.stepRationale(step),
        ],
      ];

      for (final message in messages) {
        final english = en.resolveStructuredMessage(message);
        final portuguese = pt.resolveStructuredMessage(message);
        expect(english, isNot(contains(message.stableCode)));
        expect(portuguese, isNot(contains(message.stableCode)));
        expect(english, isNotEmpty);
        expect(portuguese, isNotEmpty);
      }

      expect(
        en.resolveStructuredMessage(
          GrammarCnfMessages.grammarNotCfg('regular'),
        ),
        contains('regular'),
      );
      expect(
        pt.resolveStructuredMessage(
          GrammarCnfMessages.grammarNotCfg('contextFree'),
        ),
        contains('livre de contexto'),
      );
    });
  });

  group('PDA normalization structured messages', () {
    test(
      'resolves validation, warning, and provenance payloads in both locales',
      () {
        final messages = <StructuredMessage>[
          PdaNormalizationMessages.emptyPda(),
          PdaNormalizationMessages.missingInitialState(),
          PdaNormalizationMessages.initialStateOutsideSet(),
          PdaNormalizationMessages.invalidInitialStackSymbol('Z'),
          PdaNormalizationMessages.missingAcceptingState(),
          PdaNormalizationMessages.acceptingStateOutsideSet(),
          PdaNormalizationMessages.nonPdaTransition(),
          PdaNormalizationMessages.transitionEndpointOutsideSet('t1'),
          PdaNormalizationMessages.transitionPopSymbolOutsideAlphabet(
            't2',
            'X',
          ),
          PdaNormalizationMessages.transitionPushSymbolOutsideAlphabet(
            't3',
            'Y',
          ),
          PdaNormalizationMessages.growthWarning(
            addedStates: 2,
            addedTransitions: 3,
          ),
          PdaNormalizationMessages.introducedNondeterminismWarning(),
          PdaNormalizationMessages.initialStateDescription('q0'),
          PdaNormalizationMessages.acceptanceStateDescription(),
          PdaNormalizationMessages.drainStateDescription(),
          PdaNormalizationMessages.initializeTransitionDescription('q0'),
          PdaNormalizationMessages.singlePopTransitionDescription('t4'),
          PdaNormalizationMessages.acceptEmptyTransitionDescription(
            sourceStateId: 'q1',
            targetMode: PDAAcceptanceMode.both,
          ),
          PdaNormalizationMessages.enterDrainTransitionDescription('q2'),
          PdaNormalizationMessages.drainTransitionDescription(),
        ];

        for (final message in messages) {
          final english = en.resolveStructuredMessage(message);
          final portuguese = pt.resolveStructuredMessage(message);
          expect(english, isNot(contains(message.stableCode)));
          expect(portuguese, isNot(contains(message.stableCode)));
          expect(english, isNotEmpty);
          expect(portuguese, isNotEmpty);
        }

        final modeMessage =
            PdaNormalizationMessages.acceptEmptyTransitionDescription(
              sourceStateId: 'q1',
              targetMode: PDAAcceptanceMode.emptyStack,
            );
        expect(
          en.resolveStructuredMessage(modeMessage),
          contains('empty stack'),
        );
        expect(
          pt.resolveStructuredMessage(modeMessage),
          contains('pilha vazia'),
        );
      },
    );

    test('keeps a safe fallback for an unknown future code', () {
      final future = StructuredMessage(
        namespace: 'pda.normalization',
        code: 'future-code',
        category: StructuredMessageCategory.validation,
        severity: StructuredMessageSeverity.error,
      );

      expect(en.resolveStructuredMessage(future), contains(future.stableCode));
      expect(pt.resolveStructuredMessage(future), contains(future.stableCode));
    });
  });

  group('GNF structured messages', () {
    test('resolves conversion diagnostics and step copy in both locales', () {
      final messages = [
        GrammarGnfMessages.transformFailed(),
        GrammarGnfMessages.notGnf(),
        GrammarGnfMessages.convertTitle(),
        GrammarGnfMessages.convertRationale(),
      ];

      for (final message in messages) {
        expect(en.resolveStructuredMessage(message), isNot(message.stableCode));
        expect(pt.resolveStructuredMessage(message), isNot(message.stableCode));
      }
    });
  });

  group('Grammar-to-PDA structured messages', () {
    test(
      'resolves validation, timeout, and analysis-step copy in both locales',
      () {
        final messages = <StructuredMessage>[
          GrammarToPdaMessages.emptyGrammar(),
          GrammarToPdaMessages.missingStartSymbol(),
          GrammarToPdaMessages.undeclaredStartSymbol('S'),
          GrammarToPdaMessages.duplicateProductionId('p1'),
          GrammarToPdaMessages.notContextFree(),
          GrammarToPdaMessages.conversionTimedOut(const Duration(seconds: 2)),
          GrammarToPdaMessages.internalConversionFailure(),
          GrammarToPdaMessages.gnfConversionFailed(),
          GrammarToPdaMessages.invalidGnfResult(),
          GrammarToPdaMessages.analysisFailed(),
          GrammarToPdaMessages.analysisTimedOut(const Duration(seconds: 3)),
          GrammarToPdaMessages.validateGrammarStep(),
          GrammarToPdaMessages.createInitialStateStep(),
          GrammarToPdaMessages.createProcessingStateStep(),
          GrammarToPdaMessages.createAcceptingStateStep(),
          GrammarToPdaMessages.addTransitionsStep(),
        ];

        for (final message in messages) {
          expect(
            en.resolveStructuredMessage(message),
            isNot(message.stableCode),
          );
          expect(
            pt.resolveStructuredMessage(message),
            isNot(message.stableCode),
          );
        }

        expect(
          pt.resolveStructuredMessage(
            GrammarToPdaMessages.undeclaredStartSymbol('S'),
          ),
          contains('S'),
        );
      },
    );
  });

  group('PDA simplification structured messages', () {
    test(
      'resolves validation, phases, and bounded evidence in both locales',
      () {
        final messages = <StructuredMessage>[
          PdaSimplificationMessages.emptyPda(),
          PdaSimplificationMessages.missingInitialState(),
          PdaSimplificationMessages.initialStateOutsideSet(),
          PdaSimplificationMessages.acceptingStateOutsideSet(),
          PdaSimplificationMessages.missingAcceptingState(
            PDAAcceptanceMode.finalState,
          ),
          PdaSimplificationMessages.invalidPda(),
          PdaSimplificationMessages.nonPdaTransition(),
          PdaSimplificationMessages.transitionEndpointOutsideSet('t1'),
          PdaSimplificationMessages.invalidTransition('t2'),
          PdaSimplificationMessages.inputAlphabetSymbolEmpty(),
          PdaSimplificationMessages.stackAlphabetSymbolEmpty(),
          PdaSimplificationMessages.transitionInputSymbolOutsideAlphabet(
            't3',
            'x',
          ),
          PdaSimplificationMessages.duplicateTransitionIds('t4'),
          PdaSimplificationMessages.boundedLengthNegative(),
          PdaSimplificationMessages.boundedSymbolsEmpty(),
          PdaSimplificationMessages.boundedSymbolOutsideAlphabet('y'),
          PdaSimplificationMessages.validationComplete(),
          PdaSimplificationMessages.everyStateReachable(),
          PdaSimplificationMessages.removedUnreachableStates(2),
          PdaSimplificationMessages.semanticUsefulnessUnavailable(),
          PdaSimplificationMessages.semanticUsefulnessDisabled(),
          PdaSimplificationMessages.strongBisimulationComputed(),
          PdaSimplificationMessages.strongBisimulationDisabled(),
          PdaSimplificationMessages.rebuildValidationComplete(),
          PdaSimplificationMessages.boundedSamplePassed(3),
          PdaSimplificationMessages.boundedComparisonDisabled(),
          PdaSimplificationMessages.invalidRebuiltPda(),
          PdaSimplificationMessages.boundedComparisonInconclusive('ab'),
          PdaSimplificationMessages.boundedComparisonSimulationLimit('a'),
          PdaSimplificationMessages.boundedComparisonAcceptanceMismatch('b'),
        ];

        for (final message in messages) {
          expect(
            en.resolveStructuredMessage(message),
            isNot(message.stableCode),
          );
          expect(
            pt.resolveStructuredMessage(message),
            isNot(message.stableCode),
          );
        }

        final modeMessage = PdaSimplificationMessages.missingAcceptingState(
          PDAAcceptanceMode.emptyStack,
        );
        expect(
          en.resolveStructuredMessage(modeMessage),
          contains('empty stack'),
        );
        expect(
          pt.resolveStructuredMessage(modeMessage),
          contains('pilha vazia'),
        );
      },
    );
  });
}
