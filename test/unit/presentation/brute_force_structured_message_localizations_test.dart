import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:turing_lab/core/algorithms/brute_force_cfg_parser.dart';
import 'package:turing_lab/core/algorithms/brute_force_messages.dart';
import 'package:turing_lab/core/messages/structured_message.dart';
import 'package:turing_lab/core/models/brute_force_parse_models.dart';
import 'package:turing_lab/core/models/grammar.dart';
import 'package:turing_lab/core/models/production.dart';
import 'package:turing_lab/l10n/app_localizations_en.dart';
import 'package:turing_lab/l10n/app_localizations_pt.dart';
import 'package:turing_lab/l10n/app_localizations_structured_messages.dart';

void main() {
  final en = AppLocalizationsEn();
  final pt = AppLocalizationsPt();

  Grammar grammar({
    Set<String> terminals = const {'a'},
    Set<String> nonterminals = const {'S'},
    Iterable<Production> productions = const <Production>[
      Production(id: 'p1', leftSide: ['S'], rightSide: ['a']),
    ],
    String startSymbol = 'S',
  }) => Grammar(
    id: 'brute-force-localization-test',
    name: 'Brute-force localization test',
    terminals: terminals,
    nonterminals: nonterminals,
    startSymbol: startSymbol,
    productions: productions.toSet(),
    type: GrammarType.contextFree,
    created: DateTime(2026),
    modified: DateTime(2026),
  );

  test('resolves bounded brute-force diagnostics in both locales', () {
    final cases = <(StructuredMessage, String, String)>[
      (
        BruteForceMessages.emptyGrammar(),
        'Grammar must have at least one production.',
        'A gramática deve ter pelo menos uma produção.',
      ),
      (
        BruteForceMessages.invalidLimitPositive('max-frontier-size'),
        'Maximum frontier size must be positive.',
        'Tamanho máximo da fronteira deve ser positivo.',
      ),
      (
        BruteForceMessages.overlappingSymbols('A, S'),
        'Grammar symbols cannot be both terminals and non-terminals: A, S.',
        'Os símbolos da gramática não podem ser terminais e não terminais ao mesmo tempo: A, S.',
      ),
      (
        BruteForceMessages.undeclaredSymbol(productionId: 'p1', symbol: 'X'),
        'Production p1 references undeclared symbol "X".',
        'A produção p1 referencia o símbolo não declarado "X".',
      ),
      (
        BruteForceMessages.acceptedAtLimit('depth'),
        'Accepted, but witness enumeration stopped at the depth limit.',
        'Aceita, mas a enumeração de testemunhos parou no limite de profundidade.',
      ),
      (
        BruteForceMessages.boundedAtLimit('time'),
        'No witness was found before the time limit stopped search.',
        'Nenhum testemunho foi encontrado antes de o limite de tempo interromper a busca.',
      ),
      (
        BruteForceMessages.cancelled(),
        'CFG brute-force search was cancelled.',
        'A busca por força bruta de GLC foi cancelada.',
      ),
    ];

    for (final (message, enText, ptText) in cases) {
      expect(
        en.resolveStructuredMessage(message),
        enText,
        reason: message.stableCode,
      );
      expect(
        pt.resolveStructuredMessage(message),
        ptText,
        reason: message.stableCode,
      );
      expect(
        pt.resolveStructuredMessage(message),
        isNot(contains(enText)),
        reason: message.stableCode,
      );
    }
  });

  test('parser exposes locale-neutral diagnostics and persists them', () {
    final result = BruteForceCFGParser.search(grammar(), 'x');

    expect(
      result.structuredMessage?.stableCode,
      'grammar.brute-force.invalid-input-symbol',
    );
    expect(result.message, result.structuredMessage!.stableCode);
    expect(
      en.resolveStructuredMessage(result.structuredMessage!),
      'Input string contains invalid symbol: x.',
    );
    expect(
      pt.resolveStructuredMessage(result.structuredMessage!),
      'A cadeia de entrada contém um símbolo inválido: x.',
    );

    final restored = StructuredMessage.fromJson(
      jsonDecode(jsonEncode(result.structuredMessage!.toJson()))
          as Map<String, Object?>,
    );
    expect(restored, result.structuredMessage);
    expect(result.toJson()['structuredMessage'], isNotNull);
  });

  test('limits expose structured validation', () {
    const limits = BruteForceSearchLimits(maxDepth: -1);
    final message = limits.structuredValidationMessage!;

    expect(
      message.stableCode,
      'grammar.brute-force.invalid-limit-non-negative',
    );
    expect(limits.validate(), message.stableCode);
  });
}
