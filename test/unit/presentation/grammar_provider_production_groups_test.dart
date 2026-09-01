import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:turing_lab/core/models/grammar.dart';
import 'package:turing_lab/presentation/providers/grammar_provider.dart';

void main() {
  group('GrammarProvider production groups', () {
    test('adds alternatives atomically with sequential IDs and order', () {
      final provider = GrammarProvider();
      var emissions = 0;
      provider.addListener((_) => emissions++, fireImmediately: false);

      final result = provider.addProductionAlternatives(
        leftSide: const ['A'],
        alternatives: const [
          ProductionAlternativeDraft(rightSide: ['A', 'A']),
          ProductionAlternativeDraft(rightSide: ['A', 'a']),
        ],
      );

      expect(result.changed, isTrue);
      expect(result.addedCount, 2);
      expect(emissions, 1);
      expect(provider.state.productions.map((production) => production.id), [
        'p1',
        'p2',
      ]);
      expect(provider.state.productions.map((production) => production.order), [
        0,
        1,
      ]);
      expect(provider.state.nextProductionId, 3);
    });

    test('ignores existing and repeated alternatives in a batch', () {
      final provider = GrammarProvider()
        ..addProduction(leftSide: const ['A'], rightSide: const ['a']);

      final result = provider.addProductionAlternatives(
        leftSide: const ['A'],
        alternatives: const [
          ProductionAlternativeDraft(rightSide: ['a']),
          ProductionAlternativeDraft(rightSide: ['b']),
          ProductionAlternativeDraft(rightSide: ['b']),
        ],
      );

      expect(result.changed, isTrue);
      expect(result.addedCount, 1);
      expect(result.duplicateCount, 2);
      expect(
        provider.state.productions.map((production) => production.rightSide),
        [
          ['a'],
          ['b'],
        ],
      );
      expect(provider.state.nextProductionId, 3);
    });

    test('rejects an invalid batch without mutating state', () {
      final provider = GrammarProvider()
        ..addProduction(leftSide: const ['S'], rightSide: const ['a']);
      final before = provider.state;

      final result = provider.addProductionAlternatives(
        leftSide: const ['A'],
        alternatives: const [
          ProductionAlternativeDraft(rightSide: ['b']),
          ProductionAlternativeDraft(rightSide: []),
        ],
      );

      expect(result.invalid, isTrue);
      expect(result.changed, isFalse);
      expect(identical(provider.state, before), isTrue);
    });

    test('replaces a group while preserving retained alternative IDs', () {
      final provider = GrammarProvider()
        ..addProductionAlternatives(
          leftSide: const ['A'],
          alternatives: const [
            ProductionAlternativeDraft(rightSide: ['a']),
            ProductionAlternativeDraft(rightSide: ['b']),
          ],
        );

      final result = provider.replaceProductionGroup(
        originalLeftSide: const ['A'],
        leftSide: const ['A'],
        alternatives: const [
          ProductionAlternativeDraft(rightSide: ['a']),
          ProductionAlternativeDraft(rightSide: ['c']),
        ],
      );

      expect(result.changed, isTrue);
      expect(result.addedCount, 1);
      expect(result.removedCount, 1);
      expect(provider.state.productions.map((production) => production.id), [
        'p1',
        'p3',
      ]);
      expect(
        provider.state.productions.map((production) => production.rightSide),
        [
          ['a'],
          ['c'],
        ],
      );
      expect(provider.state.productions.map((production) => production.order), [
        0,
        1,
      ]);
      expect(provider.state.nextProductionId, 4);
    });

    test('merges into an existing left-side group predictably', () {
      final provider = GrammarProvider()
        ..addProduction(leftSide: const ['S'], rightSide: const ['a'])
        ..addProduction(leftSide: const ['A'], rightSide: const ['b']);

      final result = provider.replaceProductionGroup(
        originalLeftSide: const ['S'],
        leftSide: const ['A'],
        alternatives: const [
          ProductionAlternativeDraft(rightSide: ['a']),
          ProductionAlternativeDraft(rightSide: ['b']),
          ProductionAlternativeDraft(rightSide: ['c']),
        ],
      );

      expect(result.changed, isTrue);
      expect(result.duplicateCount, 1);
      expect(provider.state.productions.map((production) => production.id), [
        'p2',
        'p1',
        'p3',
      ]);
      expect(
        provider.state.productions.map((production) => production.leftSide),
        [
          ['A'],
          ['A'],
          ['A'],
        ],
      );
      expect(
        provider.state.productions.map((production) => production.rightSide),
        [
          ['b'],
          ['a'],
          ['c'],
        ],
      );
    });

    test('deletes a complete group and closes order gaps', () {
      final provider = GrammarProvider()
        ..addProduction(leftSide: const ['S'], rightSide: const ['a'])
        ..addProduction(leftSide: const ['A'], rightSide: const ['b'])
        ..addProduction(leftSide: const ['S'], rightSide: const ['c']);

      final removed = provider.deleteProductionGroup(const ['S']);

      expect(removed, 2);
      expect(provider.state.productions, hasLength(1));
      expect(provider.state.productions.single.id, 'p2');
      expect(provider.state.productions.single.order, 0);
      expect(provider.state.nextProductionId, 4);
    });

    test('reorders complete groups atomically and preserves alternatives', () {
      final provider = GrammarProvider()
        ..addProduction(leftSide: const ['S'], rightSide: const ['A', 'B'])
        ..addProduction(leftSide: const ['A'], rightSide: const ['a'])
        ..addProduction(leftSide: const ['S'], rightSide: const ['s'])
        ..addProduction(leftSide: const ['B'], rightSide: const ['b']);
      final originalIds = provider.state.productions
          .map((production) => production.id)
          .toSet();
      final nextId = provider.state.nextProductionId;
      var emissions = 0;
      provider.addListener((_) => emissions++, fireImmediately: false);

      expect(provider.reorderProductionGroup(2, 1), isTrue);

      expect(emissions, 1);
      expect(provider.state.productions.map((production) => production.id), [
        'p1',
        'p3',
        'p4',
        'p2',
      ]);
      expect(
        provider.state.productions.map((production) => production.leftSide),
        [
          ['S'],
          ['S'],
          ['B'],
          ['A'],
        ],
      );
      expect(provider.state.productions.map((production) => production.order), [
        0,
        1,
        2,
        3,
      ]);
      expect(
        provider.state.productions.map((production) => production.id).toSet(),
        originalIds,
      );
      expect(provider.state.nextProductionId, nextId);
    });

    test('rejects no-op and invalid group moves without an emission', () {
      final provider = GrammarProvider()
        ..addProduction(leftSide: const ['S'], rightSide: const ['s'])
        ..addProduction(leftSide: const ['A'], rightSide: const ['a']);
      final before = provider.state;
      var emissions = 0;
      provider.addListener((_) => emissions++, fireImmediately: false);

      expect(provider.reorderProductionGroup(0, 0), isFalse);
      expect(provider.reorderProductionGroup(-1, 0), isFalse);
      expect(provider.reorderProductionGroup(0, 2), isFalse);

      expect(identical(provider.state, before), isTrue);
      expect(emissions, 0);
    });

    test('reordered groups survive native JSON and editor reload', () {
      final provider = GrammarProvider()
        ..addProduction(leftSide: const ['S'], rightSide: const ['s'])
        ..addProduction(leftSide: const ['A'], rightSide: const ['a'])
        ..addProduction(leftSide: const ['B'], rightSide: const ['b'])
        ..reorderProductionGroup(2, 0);
      final encoded = jsonEncode(provider.buildGrammar().toJson());
      final decoded = Grammar.fromJson(
        jsonDecode(encoded) as Map<String, dynamic>,
      );
      final restored = GrammarProvider()..applyGrammar(decoded);

      expect(restored.state.productions.map((production) => production.id), [
        'p3',
        'p1',
        'p2',
      ]);
      expect(restored.state.productions.map((production) => production.order), [
        0,
        1,
        2,
      ]);
      expect(restored.state.nextProductionId, 4);
    });
  });
}
