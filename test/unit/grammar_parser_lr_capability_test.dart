import 'package:flutter_test/flutter_test.dart';
import 'package:turing_lab/core/algorithms/grammar_parser.dart';
import 'package:turing_lab/core/models/grammar.dart';
import 'package:turing_lab/core/models/production.dart';

void main() {
  final now = DateTime(2026);
  final grammar = Grammar(
    id: 's-to-a',
    name: 'S to a',
    terminals: const {'a'},
    nonterminals: const {'S'},
    startSymbol: 'S',
    productions: {
      const Production(id: 'p1', leftSide: ['S'], rightSide: ['a']),
    },
    type: GrammarType.contextFree,
    created: now,
    modified: now,
  );

  group('LR parser capability', () {
    test('legacy parse accepts the language and rejects epsilon', () {
      final accepted = GrammarParser.parse(
        grammar,
        'a',
        strategyHint: ParsingStrategyHint.lr,
      );
      final rejected = GrammarParser.parse(
        grammar,
        '',
        strategyHint: ParsingStrategyHint.lr,
      );

      expect(accepted.isSuccess, isTrue);
      expect(accepted.data!.accepted, isTrue);
      expect(accepted.data!.lr1Steps, isNotEmpty);
      expect(accepted.data!.tree, isNotNull);
      expect(rejected.isSuccess, isTrue);
      expect(rejected.data!.accepted, isFalse);
    });

    test('structured parse returns the canonical LR trace and tree', () {
      final result = GrammarParser.parseWithReport(
        grammar,
        'a',
        strategyHint: ParsingStrategyHint.lr,
      );

      expect(result.isSuccess, isTrue);
      expect(result.data!.accepted, isTrue);
      expect(result.data!.lr1Steps, isNotEmpty);
      expect(result.data!.trees, hasLength(1));
    });
  });

  group('parser strategy registry', () {
    test('advertises only implemented strategies as available', () {
      final available = GrammarParser.capabilities
          .where((capability) => capability.isAvailable)
          .map((capability) => capability.strategy)
          .toSet();

      expect(
        available,
        {
          ParsingStrategyHint.auto,
          ParsingStrategyHint.bruteForce,
          ParsingStrategyHint.cyk,
          ParsingStrategyHint.ll,
          ParsingStrategyHint.lr,
        },
      );
      expect(
        GrammarParser.capabilityFor(ParsingStrategyHint.ll).unavailableReason,
        isNull,
      );
      expect(
        GrammarParser.capabilityFor(ParsingStrategyHint.lr).label,
        'Canonical LR(1)',
      );
    });

    for (final strategy in [
      ParsingStrategyHint.auto,
      ParsingStrategyHint.bruteForce,
      ParsingStrategyHint.cyk,
    ]) {
      test('$strategy gives the same outcome from both entry points', () {
        for (final input in ['a', '']) {
          final legacy = GrammarParser.parse(
            grammar,
            input,
            strategyHint: strategy,
          );
          final report = GrammarParser.parseWithReport(
            grammar,
            input,
            strategyHint: strategy,
          );

          expect(legacy.isSuccess, isTrue);
          expect(report.isSuccess, isTrue);
          expect(report.data!.accepted, legacy.data!.accepted);
        }
      });
    }

    test('CYK reports a configured timeout through ParseResult', () {
      final result = GrammarParser.parse(
        grammar,
        'a',
        strategyHint: ParsingStrategyHint.cyk,
        timeout: Duration.zero,
      );

      expect(result.isSuccess, isTrue);
      expect(result.data!.accepted, isFalse);
      expect(result.data!.errorMessage, contains('timed out'));
    });
  });
}
