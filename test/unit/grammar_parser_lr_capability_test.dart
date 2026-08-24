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
    test('legacy parse reports LR as unavailable instead of accepting epsilon',
        () {
      final result = GrammarParser.parse(
        grammar,
        '',
        strategyHint: ParsingStrategyHint.lr,
      );

      expect(result.isFailure, isTrue);
      expect(result.error, contains('LR parsing is not available'));
    });

    test('structured parse reports capability failure, not language rejection',
        () {
      final result = GrammarParser.parseWithReport(
        grammar,
        'a',
        strategyHint: ParsingStrategyHint.lr,
      );

      expect(result.isFailure, isTrue);
      expect(result.error, contains('LR parsing is not available'));
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
        },
      );
      expect(
        GrammarParser.capabilityFor(ParsingStrategyHint.ll).unavailableReason,
        isNull,
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
