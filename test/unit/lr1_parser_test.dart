import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:turing_lab/core/algorithms/lr1_parser.dart';
import 'package:turing_lab/core/models/derivation_tree.dart';
import 'package:turing_lab/core/models/derivation_tree_node.dart';
import 'package:turing_lab/core/models/grammar.dart';
import 'package:turing_lab/core/models/lr1_models.dart';
import 'package:turing_lab/core/models/production.dart';
import 'package:turing_lab/core/parsers/grammar_xml_codec.dart';

void main() {
  final now = DateTime(2026);

  Grammar grammar({
    String id = 'lr1-test',
    required Set<String> terminals,
    required Set<String> nonTerminals,
    String start = 'S',
    required Iterable<Production> productions,
  }) {
    return Grammar(
      id: id,
      name: 'LR(1) test grammar',
      terminals: terminals,
      nonterminals: nonTerminals,
      startSymbol: start,
      productions: productions.toSet(),
      type: GrammarType.contextFree,
      created: now,
      modified: now,
    );
  }

  const p = Production.new;

  group('canonical LR(1) construction', () {
    test('uses a collision-safe augmented start and canonical accept item', () {
      final source = grammar(
        terminals: {'a'},
        nonTerminals: {'S', "S'"},
        productions: [
          p(id: 'p1', leftSide: const ['S'], rightSide: const ['a']),
          p(id: 'p2', leftSide: const ["S'"], rightSide: const ['S']),
        ],
      );

      final result = LR1Parser.build(source);
      final construction = result.construction!;

      expect(result.outcome, LR1ConstructionOutcome.completed);
      expect(construction.augmentedProduction.leftSide.single, "S''");
      final accepts = construction.table.actions.values
          .expand((row) => row.entries)
          .where(
            (entry) =>
                entry.key == LR1Parser.endMarker &&
                entry.value.any(
                  (action) => action.kind == LR1ActionKind.accept,
                ),
          );
      expect(accepts, hasLength(1));
      expect(
        construction.states
            .expand((state) => state.items)
            .where((item) => item.isAugmented && item.isComplete)
            .map((item) => item.lookahead),
        [LR1Parser.endMarker],
      );
    });

    test('builds the classic LR(1)-but-not-SLR grammar without conflicts', () {
      final source = grammar(
        terminals: {'id', '*', '='},
        nonTerminals: {'S', 'L', 'R'},
        productions: [
          p(id: 'p1', leftSide: const ['S'], rightSide: const ['L', '=', 'R']),
          p(id: 'p2', leftSide: const ['S'], rightSide: const ['R']),
          p(id: 'p3', leftSide: const ['L'], rightSide: const ['*', 'R']),
          p(id: 'p4', leftSide: const ['L'], rightSide: const ['id']),
          p(id: 'p5', leftSide: const ['R'], rightSide: const ['L']),
        ],
      );

      final construction = LR1Parser.build(source).construction!;

      expect(construction.table.conflicts, isEmpty);
      expect(
        construction.table.gotoSources.values
            .expand((row) => row.values)
            .expand((items) => items),
        isNotEmpty,
      );
      expect(LR1Parser.parse(source, 'id=id').accepted, isTrue);
      expect(LR1Parser.parse(source, '*id=id').accepted, isTrue);
      expect(LR1Parser.parse(source, 'id').accepted, isTrue);
    });

    test('builds and parses the JFLAP grammar fixture', () {
      final xml = File(
        'test/fixtures/interoperability/grammar_lr1_not_slr.jff',
      ).readAsStringSync();
      final decoded = const GrammarXmlCodec().decodeGrammarXml(xml);

      expect(decoded.isSuccess, isTrue);
      final source = decoded.data!;
      final construction = LR1Parser.build(source).construction!;
      expect(construction.table.conflicts, isEmpty);
      expect(LR1Parser.parse(source, 'i=i').accepted, isTrue);
      expect(LR1Parser.parse(source, '*i=i').accepted, isTrue);
      expect(LR1Parser.parse(source, 'i').accepted, isTrue);
    });

    test('reconstructs source-grammar trees for the JFLAP fixture', () {
      final xml = File(
        'test/fixtures/interoperability/grammar_lr1_not_slr.jff',
      ).readAsStringSync();
      final source = const GrammarXmlCodec().decodeGrammarXml(xml).data!;

      for (final input in ['i=i', '*i=i', 'i']) {
        final result = LR1Parser.parse(source, input);

        expect(result.outcome, LR1ParseOutcome.accepted, reason: input);
        expect(result.tree, isNotNull, reason: input);
        _expectSourceTree(source, result.tree!, input);
      }
    });

    test('propagates FIRST(beta lookahead) through nullable chains', () {
      final source = grammar(
        terminals: {'b', 'c'},
        nonTerminals: {'S', 'A', 'B'},
        productions: [
          p(id: 'p1', leftSide: const ['S'], rightSide: const ['A', 'c']),
          p(id: 'p2', leftSide: const ['A'], rightSide: const ['B']),
          p(id: 'p3', leftSide: const ['B'], rightSide: const ['b']),
          p(
            id: 'p4',
            leftSide: const ['B'],
            rightSide: const [],
            isLambda: true,
          ),
        ],
      );

      final initial = LR1Parser.build(source).construction!.states.first;
      final bItems = initial.items.where((item) => item.leftSide == 'B');

      expect(bItems.map((item) => item.lookahead).toSet(), {'c'});
      expect(LR1Parser.parse(source, 'c').accepted, isTrue);
      expect(LR1Parser.parse(source, 'bc').accepted, isTrue);
    });

    test(
      'preserves shift/reduce and reduce/reduce actions with provenance',
      () {
        final shiftReduce = grammar(
          terminals: {'id', '+'},
          nonTerminals: {'E'},
          start: 'E',
          productions: [
            p(
              id: 'p1',
              leftSide: const ['E'],
              rightSide: const ['E', '+', 'E'],
            ),
            p(id: 'p2', leftSide: const ['E'], rightSide: const ['id']),
          ],
        );
        final reduceReduce = grammar(
          terminals: {'a'},
          nonTerminals: {'S', 'A', 'B'},
          productions: [
            p(id: 'p1', leftSide: const ['S'], rightSide: const ['A']),
            p(id: 'p2', leftSide: const ['S'], rightSide: const ['B']),
            p(id: 'p3', leftSide: const ['A'], rightSide: const ['a']),
            p(id: 'p4', leftSide: const ['B'], rightSide: const ['a']),
          ],
        );

        final sr = LR1Parser.build(shiftReduce).construction!.table.conflicts;
        final rr = LR1Parser.build(reduceReduce).construction!.table.conflicts;

        expect(sr, isNotEmpty);
        expect(sr.first.kind, LR1ConflictKind.shiftReduce);
        expect(
          sr.first.actions.expand((action) => action.sourceItems),
          isNotEmpty,
        );
        expect(rr, isNotEmpty);
        expect(rr.first.kind, LR1ConflictKind.reduceReduce);
        expect(
          rr.first.actions
              .map((action) => action.productionId)
              .whereType<String>(),
          containsAll({'p3', 'p4'}),
        );
        expect(
          LR1Parser.parse(shiftReduce, 'id+id').outcome,
          LR1ParseOutcome.conflict,
        );
      },
    );

    test('is deterministic across production insertion orders', () {
      final productions = [
        p(id: 'p1', leftSide: const ['S'], rightSide: const ['A']),
        p(id: 'p2', leftSide: const ['A'], rightSide: const ['a', 'A']),
        p(id: 'p3', leftSide: const ['A'], rightSide: const [], isLambda: true),
      ];
      final forward = grammar(
        terminals: {'a'},
        nonTerminals: {'S', 'A'},
        productions: productions,
      );
      final reversed = grammar(
        terminals: {'a'},
        nonTerminals: {'A', 'S'},
        productions: productions.reversed,
      );

      String signature(LR1Construction construction) => construction.states
          .map((state) => state.items.map((item) => item.stableKey).join('|'))
          .join('\n');

      expect(
        signature(LR1Parser.build(forward).construction!),
        signature(LR1Parser.build(reversed).construction!),
      );
    });

    test('keeps duplicate textual productions distinct by stable ID', () {
      final source = grammar(
        terminals: {'a'},
        nonTerminals: {'S'},
        productions: [
          p(id: 'first', leftSide: const ['S'], rightSide: const ['a']),
          p(id: 'second', leftSide: const ['S'], rightSide: const ['a']),
        ],
      );

      final conflict = LR1Parser.build(
        source,
      ).construction!.table.conflicts.single;

      expect(conflict.kind, LR1ConflictKind.reduceReduce);
      expect(
        conflict.actions.map((action) => action.productionId),
        containsAll({'first', 'second'}),
      );
    });
  });

  group('canonical LR(1) execution', () {
    final source = grammar(
      terminals: {'token🙂'},
      nonTerminals: {'S'},
      productions: [
        p(id: 'p1', leftSide: const ['S'], rightSide: const ['token🙂']),
      ],
    );

    test('rejects epsilon, accepts the token, and reconstructs a tree', () {
      final empty = LR1Parser.parse(source, '');
      final accepted = LR1Parser.parse(source, 'token🙂');

      expect(empty.outcome, LR1ParseOutcome.rejected);
      expect(empty.expectedTerminals, {'token🙂'});
      expect(accepted.outcome, LR1ParseOutcome.accepted);
      expect(accepted.tree!.root.symbol, 'S');
      expect(accepted.tree!.root.children.single.lexeme, 'token🙂');
      expect(
        accepted.steps
            .map((step) => step.action?.kind)
            .whereType<LR1ActionKind>(),
        [LR1ActionKind.shift, LR1ActionKind.reduce, LR1ActionKind.accept],
      );
      final reduction = accepted.steps[1];
      expect(reduction.reducedProductionId, 'p1');
      expect(reduction.popCount, 1);
      expect(reduction.stateStackBefore, hasLength(2));
      expect(reduction.stateStackAfter, hasLength(2));
    });

    test(
      'distinguishes tokenization, cancellation, timeout, and step limits',
      () {
        expect(
          LR1Parser.parse(source, 'x').outcome,
          LR1ParseOutcome.tokenizationFailure,
        );
        expect(
          LR1Parser.parse(source, 'token🙂', isCancelled: () => true).outcome,
          LR1ParseOutcome.cancelled,
        );
        expect(
          LR1Parser.parse(source, 'token🙂', timeout: Duration.zero).outcome,
          LR1ParseOutcome.timedOut,
        );
        expect(
          LR1Parser.parse(source, 'token🙂', maxSteps: 1).outcome,
          LR1ParseOutcome.resourceLimit,
        );
      },
    );

    test('reports construction bounds without a false rejection', () {
      final stateBound = LR1Parser.build(source, maxStates: 1);
      final itemBound = LR1Parser.build(source, maxItems: 1);

      expect(stateBound.outcome, LR1ConstructionOutcome.stateLimit);
      expect(itemBound.outcome, LR1ConstructionOutcome.itemLimit);
      expect(
        LR1Parser.parse(source, 'token🙂', maxStates: 1).outcome,
        LR1ParseOutcome.resourceLimit,
      );
    });

    test('rejects a canonical collection from another grammar revision', () {
      final construction = LR1Parser.build(source).construction!;
      final changed = source.copyWith(
        productions: {
          p(id: 'p2', leftSide: const ['S'], rightSide: const ['other']),
        },
        terminals: {'other'},
      );

      final result = LR1Parser.parse(
        changed,
        'other',
        construction: construction,
      );

      expect(result.outcome, LR1ParseOutcome.tableConstructionFailure);
      expect(result.message, contains('different grammar revision'));
    });

    test('rejects malformed grammars with typed construction outcome', () {
      final malformed = grammar(
        terminals: const {},
        nonTerminals: {'S'},
        productions: const [],
      );

      expect(
        LR1Parser.build(malformed).outcome,
        LR1ConstructionOutcome.invalidGrammar,
      );
      expect(
        LR1Parser.parse(malformed, '').outcome,
        LR1ParseOutcome.invalidGrammar,
      );
    });
  });
}

void _expectSourceTree(Grammar grammar, DerivationTree tree, String input) {
  expect(tree.isShallow, isFalse);

  String visit(DerivationTreeNode node) {
    if (grammar.terminals.contains(node.symbol)) {
      expect(node.children, isEmpty, reason: 'terminal ${node.symbol}');
      return node.lexeme ?? node.symbol;
    }

    expect(
      grammar.nonterminals,
      contains(node.symbol),
      reason: 'unknown tree symbol ${node.symbol}',
    );
    final children = node.children.map((child) => child.symbol).toList();
    final hasProduction = grammar.productions
        .where((production) => production.leftSide.single == node.symbol)
        .any((production) {
          final rightSide = production.isLambda
              ? const ['ε']
              : production.rightSide;
          return _sameSymbols(children, rightSide);
        });
    expect(
      hasProduction,
      isTrue,
      reason: '${node.symbol} -> ${children.join(' ')}',
    );
    return node.children.map(visit).join();
  }

  expect(tree.root.symbol, grammar.startSymbol);
  expect(visit(tree.root), input);
}

bool _sameSymbols(List<String> left, List<String> right) {
  if (left.length != right.length) return false;
  for (var index = 0; index < left.length; index++) {
    if (left[index] != right[index]) return false;
  }
  return true;
}
