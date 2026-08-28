import 'package:flutter_test/flutter_test.dart';
import 'package:turing_lab/core/algorithms/grammar_to_fsa_converter.dart';
import 'package:turing_lab/core/algorithms/grammar_to_fsa_messages.dart';
import 'package:turing_lab/core/messages/structured_message.dart';
import 'package:turing_lab/core/models/grammar.dart';
import 'package:turing_lab/core/models/production.dart';
import 'package:turing_lab/l10n/app_localizations_en.dart';
import 'package:turing_lab/l10n/app_localizations_pt.dart';
import 'package:turing_lab/l10n/app_localizations_structured_messages.dart';

void main() {
  final en = AppLocalizationsEn();
  final pt = AppLocalizationsPt();

  test('resolves grammar-to-FSA diagnostics in both locales', () {
    final messages = <StructuredMessage>[
      GrammarToFsaMessages.missingNonterminals(),
      GrammarToFsaMessages.undeclaredStartSymbol(),
      GrammarToFsaMessages.leftSideNotSingle('p-left'),
      GrammarToFsaMessages.unknownLeftNonterminal('p-left', 'X'),
      GrammarToFsaMessages.unknownRightNonterminal('p-right', 'X'),
      GrammarToFsaMessages.tooManyRightSymbols('p-long'),
      GrammarToFsaMessages.firstSymbolNotTerminal('p-first'),
      GrammarToFsaMessages.lastSymbolNotNonterminal('p-last'),
    ];

    for (final message in messages) {
      final restored = StructuredMessage.fromJson(message.toJson());
      expect(restored, message);
      expect(
        en.resolveStructuredMessage(restored),
        isNot(contains(message.stableCode)),
      );
      expect(
        pt.resolveStructuredMessage(restored),
        isNot(contains(message.stableCode)),
      );
      expect(
        en.resolveStructuredMessage(restored),
        isNot(pt.resolveStructuredMessage(restored)),
      );
    }
  });

  test('converter preserves structured validation diagnostics', () {
    final cases = <(Grammar, String)>[
      (_grammar(nonterminals: const {}), 'grammar.to-fsa.missing-nonterminals'),
      (_grammar(startSymbol: 'A'), 'grammar.to-fsa.undeclared-start-symbol'),
      (
        _grammar(
          productions: {
            const Production(
              id: 'p-left',
              leftSide: ['S', 'A'],
              rightSide: ['a'],
            ),
          },
        ),
        'grammar.to-fsa.left-side-not-single',
      ),
      (
        _grammar(
          productions: {
            const Production(
              id: 'p-unknown-left',
              leftSide: ['X'],
              rightSide: ['a'],
            ),
          },
        ),
        'grammar.to-fsa.unknown-left-nonterminal',
      ),
      (
        _grammar(
          terminals: const {'a', 'b'},
          productions: {
            const Production(
              id: 'p-long',
              leftSide: ['S'],
              rightSide: ['a', 'S', 'b'],
            ),
          },
        ),
        'grammar.to-fsa.too-many-right-symbols',
      ),
      (
        _grammar(
          nonterminals: const {'S', 'A'},
          productions: {
            const Production(
              id: 'p-first',
              leftSide: ['S'],
              rightSide: ['A', 'S'],
            ),
          },
        ),
        'grammar.to-fsa.first-symbol-not-terminal',
      ),
      (
        _grammar(
          terminals: const {'a', 'b'},
          productions: {
            const Production(
              id: 'p-last',
              leftSide: ['S'],
              rightSide: ['a', 'b'],
            ),
          },
        ),
        'grammar.to-fsa.last-symbol-not-nonterminal',
      ),
    ];

    for (final (grammar, code) in cases) {
      final result = GrammarToFSAConverter.convert(grammar);
      expect(result.isFailure, isTrue);
      expect(result.structuredError?.stableCode, code);
      expect(result.error, isNotNull);
      expect(
        en.resolveStructuredMessage(result.structuredError!),
        isNot(contains(code)),
      );
      expect(
        pt.resolveStructuredMessage(result.structuredError!),
        isNot(contains(code)),
      );
    }
  });

  test('unknown grammar-to-FSA codes use the stable fallback', () {
    final message = StructuredMessage(
      namespace: 'grammar.to-fsa',
      code: 'future',
      category: StructuredMessageCategory.validation,
      severity: StructuredMessageSeverity.error,
    );

    expect(en.resolveStructuredMessage(message), contains(message.stableCode));
  });
}

Grammar _grammar({
  Set<String> terminals = const {'a'},
  Set<String> nonterminals = const {'S'},
  String startSymbol = 'S',
  Set<Production> productions = const {},
}) => Grammar(
  id: 'grammar-to-fsa-localization',
  name: 'Grammar to FSA localization',
  terminals: terminals,
  nonterminals: nonterminals,
  startSymbol: startSymbol,
  productions: productions,
  type: GrammarType.regular,
  created: DateTime.utc(2026),
  modified: DateTime.utc(2026),
);
