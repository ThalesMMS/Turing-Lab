import 'package:flutter_test/flutter_test.dart';
import 'package:turing_lab/core/algorithms/pda_to_cfg_messages.dart';
import 'package:turing_lab/core/messages/structured_message.dart';
import 'package:turing_lab/l10n/app_localizations_en.dart';
import 'package:turing_lab/l10n/app_localizations_pt.dart';
import 'package:turing_lab/l10n/app_localizations_structured_messages.dart';

void main() {
  final en = AppLocalizationsEn();
  final pt = AppLocalizationsPt();

  test('resolves PDA-to-CFG validation diagnostics in both locales', () {
    final cases = <({StructuredMessage message, String en, String pt})>[
      (
        message: PdaToCfgMessages.invalidProductionLimit(),
        en: 'The PDA to CFG production limit must be greater than zero.',
        pt: 'O limite de produções da conversão de AP para GLC deve ser maior que zero.',
      ),
      (
        message: PdaToCfgMessages.emptyPda(),
        en: 'Cannot convert an empty PDA to a grammar.',
        pt: 'Não é possível converter um AP vazio em uma gramática.',
      ),
      (
        message: PdaToCfgMessages.missingInitialState(),
        en: 'PDA must define an initial state before conversion.',
        pt: 'O AP deve definir um estado inicial antes da conversão.',
      ),
      (
        message: PdaToCfgMessages.initialStateOutsideSet(),
        en: 'The PDA initial state must belong to the PDA state set before conversion.',
        pt: 'O estado inicial do AP deve pertencer ao conjunto de estados do AP antes da conversão.',
      ),
      (
        message: PdaToCfgMessages.missingAcceptingState(),
        en: 'PDA must have at least one accepting state for conversion.',
        pt: 'O AP deve ter pelo menos um estado de aceitação para a conversão.',
      ),
      (
        message: PdaToCfgMessages.acceptingStateOutsideSet(),
        en: 'Every accepting state must belong to the PDA state set before conversion.',
        pt: 'Todo estado de aceitação deve pertencer ao conjunto de estados do AP antes da conversão.',
      ),
      (
        message: PdaToCfgMessages.cancelled(),
        en: 'PDA-to-CFG conversion was canceled.',
        pt: 'A conversão de AP para GLC foi cancelada.',
      ),
      (
        message: PdaToCfgMessages.noProductions(),
        en: 'No productions could be generated for this PDA.',
        pt: 'Nenhuma produção pôde ser gerada para este AP.',
      ),
    ];

    for (final testCase in cases) {
      expect(en.resolveStructuredMessage(testCase.message), testCase.en);
      expect(pt.resolveStructuredMessage(testCase.message), testCase.pt);
    }
  });

  test('preserves the transition identifier and production bound', () {
    final epsilonPop = PdaToCfgMessages.epsilonPop('transition-7');
    final productionLimit = PdaToCfgMessages.productionLimit(12);

    expect(
      en.resolveStructuredMessage(epsilonPop),
      contains('Transition transition-7 uses an ε-pop.'),
    );
    expect(
      pt.resolveStructuredMessage(epsilonPop),
      contains('A transição transition-7 usa uma remoção ε.'),
    );
    expect(
      en.resolveStructuredMessage(productionLimit),
      'PDA-to-CFG conversion stopped at the 12 production limit.',
    );
    expect(
      pt.resolveStructuredMessage(productionLimit),
      'A conversão de AP para GLC parou no limite de 12 produções.',
    );
  });
}
