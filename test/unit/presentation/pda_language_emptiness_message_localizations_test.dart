import 'package:flutter_test/flutter_test.dart';
import 'package:turing_lab/core/algorithms/pda_language_emptiness_analyzer.dart';
import 'package:turing_lab/core/algorithms/pda_language_emptiness_messages.dart';
import 'package:turing_lab/core/algorithms/pda_cfg_shortest_witness_messages.dart';
import 'package:turing_lab/core/messages/structured_message.dart';
import 'package:turing_lab/core/models/grammar.dart';
import 'package:turing_lab/core/models/pda.dart';
import 'package:turing_lab/core/models/pda_acceptance_mode.dart';
import 'package:turing_lab/l10n/app_localizations_en.dart';
import 'package:turing_lab/l10n/app_localizations_pt.dart';
import 'package:turing_lab/l10n/app_localizations_structured_messages.dart';

void main() {
  final en = AppLocalizationsEn();
  final pt = AppLocalizationsPt();

  test('resolves PDA language-emptiness diagnostics in both locales', () {
    final messages = <({StructuredMessage message, String en, String pt})>[
      (
        message: PdaLanguageEmptinessMessages.invalidLimits(),
        en: 'PDA language-analysis limits must be greater than zero.',
        pt: 'Os limites da análise de vacuidade do AP devem ser maiores que zero.',
      ),
      (
        message: PdaLanguageEmptinessMessages.cancelled(),
        en: 'PDA language-emptiness analysis was cancelled.',
        pt: 'A análise de vacuidade da linguagem do AP foi cancelada.',
      ),
      (
        message: PdaLanguageEmptinessMessages.witnessReplayFailed(),
        en: 'The CFG witness could not be replayed by the source PDA.',
        pt: 'A testemunha da GLC não pôde ser reproduzida pelo AP de origem.',
      ),
      (
        message: CfgShortestWitnessMessages.missingStartSymbol(),
        en: 'The CFG start symbol must be a declared nonterminal.',
        pt: 'O símbolo inicial da GLC deve ser um não terminal declarado.',
      ),
      (
        message: CfgShortestWitnessMessages.productivityLimit(12),
        en: 'CFG productivity update limit exceeded (12).',
        pt: 'O limite de atualizações de produtividade da GLC foi excedido (12).',
      ),
    ];

    for (final testCase in messages) {
      final restored = StructuredMessage.fromJson(testCase.message.toJson());
      expect(en.resolveStructuredMessage(restored), testCase.en);
      expect(pt.resolveStructuredMessage(restored), testCase.pt);
      expect(testCase.en, isNot(testCase.pt));
    }
  });

  test('preserves typed production and grammar-symbol arguments', () {
    final message = CfgShortestWitnessMessages.undeclaredSymbol(
      productionId: 'p-1',
      symbol: 'X',
    );

    expect(
      en.resolveStructuredMessage(message),
      'Production p-1 uses undeclared symbol X.',
    );
    expect(
      pt.resolveStructuredMessage(message),
      'A produção p-1 usa o símbolo não declarado X.',
    );
    expect(
      message.arguments['production']?.kind,
      StructuredMessageArgumentKind.identifier,
    );
    expect(
      message.arguments['symbol']?.kind,
      StructuredMessageArgumentKind.symbol,
    );
  });

  test('analysis failures carry locale-neutral messages', () {
    final pdaFailure =
        PDALanguageEmptinessAnalyzer.analyze(
              PDA.empty(id: 'empty', name: 'Empty'),
              acceptanceMode: PDAAcceptanceMode.finalState,
              limits: const PDALanguageEmptinessLimits(
                maxGeneratedProductions: 0,
              ),
            )
            as PDALanguageEmptinessFailure;
    expect(
      pdaFailure.structuredMessage?.stableCode,
      'pda.language-emptiness.invalid-limits',
    );

    final grammar = Grammar(
      id: 'undeclared-start',
      name: 'Undeclared start',
      terminals: const {'a'},
      nonterminals: const {'A'},
      startSymbol: 'S',
      productions: const {},
      type: GrammarType.contextFree,
      created: DateTime.utc(2026),
      modified: DateTime.utc(2026),
    );
    final cfgFailure = CFGShortestWitnessAnalyzer.analyze(grammar);
    expect(cfgFailure, isA<CFGShortestWitnessFailure>());
    expect(
      (cfgFailure as CFGShortestWitnessFailure).structuredMessage?.stableCode,
      'grammar.shortest-witness.missing-start-symbol',
    );
  });
}
