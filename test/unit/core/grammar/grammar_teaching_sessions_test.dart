import 'package:flutter_test/flutter_test.dart';
import 'package:turing_lab/core/algorithms/grammar_analyzer.dart';
import 'package:turing_lab/core/algorithms/lr1_parser.dart';
import 'package:turing_lab/core/grammar/teaching/grammar_teaching_sessions.dart';
import 'package:turing_lab/core/models/grammar.dart';
import 'package:turing_lab/core/models/production.dart';

void main() {
  group('NormalizationTeachingSession', () {
    test('accepts an equivalent lambda step independent of IDs and order', () {
      final grammar = _normalizationGrammar();
      var session = NormalizationTeachingSession.start(grammar);
      final expected = session.referenceFor(NormalizationTeachingStage.lambda);
      final draft = expected.productions
          .toList()
          .reversed
          .map((production) {
            final right = production.isLambda || production.rightSide.isEmpty
                ? 'ε'
                : production.rightSide.join(' ');
            return '${production.leftSide.single} -> $right';
          })
          .join('\n');

      session = session.updateDraft(draft).validateCurrent();

      expect(
        session.currentDiagnostics.single.code,
        NormalizationTeachingDiagnosticCode.validEquivalent,
      );
      expect(
        session.currentState.completedStages,
        contains(NormalizationTeachingStage.lambda),
      );
    });

    test('distinguishes duplicate, invalid symbol, and out-of-order work', () {
      final grammar = _normalizationGrammar();
      final duplicate = NormalizationTeachingSession.start(
        grammar,
      ).updateDraft('S -> A\nS -> A').validateCurrent();
      expect(
        duplicate.currentDiagnostics.map((item) => item.code),
        contains(NormalizationTeachingDiagnosticCode.duplicate),
      );

      final invalid = NormalizationTeachingSession.start(
        grammar,
      ).updateDraft('S -> Z').validateCurrent();
      expect(
        invalid.currentDiagnostics.map((item) => item.code),
        contains(NormalizationTeachingDiagnosticCode.invalidSymbol),
      );

      final started = NormalizationTeachingSession.start(grammar);
      final unit = started.referenceFor(NormalizationTeachingStage.unit);
      final outOfOrderDraft = _draftFor(unit);
      final outOfOrder = started.updateDraft(outOfOrderDraft).validateCurrent();
      expect(
        outOfOrder.currentDiagnostics.map((item) => item.code),
        contains(NormalizationTeachingDiagnosticCode.outOfOrder),
      );
    });

    test('restores drafts and the undo cursor without mutating references', () {
      final grammar = _normalizationGrammar();
      final original = NormalizationTeachingSession.start(grammar);
      final edited = original
          .updateDraft('S -> A')
          .selectStage(NormalizationTeachingStage.unit)
          .updateDraft('S -> a');
      final undone = edited.undo();

      final restored = NormalizationTeachingSession.restore(
        undone.toJson(),
        grammar: grammar,
      );

      expect(restored.isSuccess, isTrue);
      expect(
        restored.session!.currentState.selectedStage,
        NormalizationTeachingStage.unit,
      );
      expect(restored.session!.canRedo, isTrue);
      expect(
        restored.session!
            .referenceFor(NormalizationTeachingStage.lambda)
            .toJson(),
        original.referenceFor(NormalizationTeachingStage.lambda).toJson(),
      );
    });

    test('rejects a persisted instructional-content contract drift', () {
      final grammar = _normalizationGrammar();
      final json = Map<String, Object?>.from(
        NormalizationTeachingSession.start(grammar).toJson(),
      );
      final content = (json['content'] as List)
          .map((value) => Map<String, Object?>.from(value as Map))
          .toList();
      content.first['version'] = 2;
      json['content'] = content;

      final restored = NormalizationTeachingSession.restore(
        json,
        grammar: grammar,
      );

      expect(restored.isSuccess, isFalse);
      expect(
        restored.diagnostics.single.code,
        NormalizationTeachingDiagnosticCode.invalidPayload,
      );
    });

    test('migrates a schema-v1 payload without content references', () {
      final grammar = _normalizationGrammar();
      final json = Map<String, Object?>.from(
        NormalizationTeachingSession.start(grammar).toJson(),
      )..remove('content');

      final restored = NormalizationTeachingSession.restore(
        json,
        grammar: grammar,
      );

      expect(restored.isSuccess, isTrue);
      expect(restored.session!.toJson(), contains('content'));
    });
  });

  group('ParseTableTeachingSession', () {
    test(
      'keeps the LL reference immutable while editing and undoing a cell',
      () async {
        final grammar = _llConflictGrammar();
        final table = GrammarAnalyzer.buildLL1ParseTable(grammar).data!;
        final originalEntry = table.value
            .entriesAt('S', 'a')
            .first
            .productionId;
        var session = ParseTableTeachingSession.fromLl1(grammar, table.value);
        final conflict = session.references.values.firstWhere(
          (cell) => cell.alternatives.length > 1,
        );

        session = session.editCell(conflict.key, 'wrong');
        expect(session.canUndo, isTrue);
        session = session.chooseAlternative(
          conflict.key,
          conflict.alternatives.first.id,
        );

        expect(
          session.validationFor(conflict.key).code,
          ParseTableTeachingDiagnosticCode.validConflictChoice,
        );
        expect(
          table.value.entriesAt('S', 'a').first.productionId,
          originalEntry,
        );
        expect(session.undo().draftFor(conflict.key), 'wrong');
      },
    );

    test('selects an LR conflict action and restores the teaching session', () {
      final grammar = _lrConflictGrammar();
      final construction = LR1Parser.build(grammar).construction!;
      final conflict = construction.table.conflicts.first;
      var session = ParseTableTeachingSession.fromLr1(grammar, construction);
      final key = ParseTableTeachingCellKey.lrAction(
        conflict.state,
        conflict.lookahead,
      );

      session = session.chooseAlternative(key, conflict.actions.last.stableKey);
      final restored = ParseTableTeachingSession.restoreLr1(
        session.toJson(),
        grammar: grammar,
        construction: construction,
      );

      expect(restored.isSuccess, isTrue);
      expect(
        restored.session!.validationFor(key).code,
        ParseTableTeachingDiagnosticCode.validConflictChoice,
      );
      expect(
        construction.table.actionsAt(conflict.state, conflict.lookahead),
        hasLength(conflict.actions.length),
      );
    });

    test('migrates missing content but rejects present contract drift', () {
      final grammar = _lrConflictGrammar();
      final construction = LR1Parser.build(grammar).construction!;
      final session = ParseTableTeachingSession.fromLr1(grammar, construction);
      final legacyJson = Map<String, Object?>.from(session.toJson())
        ..remove('content');

      final migrated = ParseTableTeachingSession.restoreLr1(
        legacyJson,
        grammar: grammar,
        construction: construction,
      );

      expect(migrated.isSuccess, isTrue);
      expect(migrated.session!.toJson(), contains('content'));

      final driftedJson = Map<String, Object?>.from(session.toJson());
      final content = Map<String, Object?>.from(driftedJson['content'] as Map);
      content['version'] = 2;
      driftedJson['content'] = content;

      final drifted = ParseTableTeachingSession.restoreLr1(
        driftedJson,
        grammar: grammar,
        construction: construction,
      );

      expect(drifted.isSuccess, isFalse);
      expect(
        drifted.diagnostic!.code,
        ParseTableTeachingDiagnosticCode.invalidPayload,
      );
    });
  });
}

String _draftFor(Grammar grammar) => grammar.productions
    .map((production) {
      final right = production.isLambda || production.rightSide.isEmpty
          ? 'ε'
          : production.rightSide.join(' ');
      return '${production.leftSide.single} -> $right';
    })
    .join('\n');

Grammar _normalizationGrammar() => Grammar(
  id: 'normalization',
  name: 'Normalization exercise',
  terminals: const {'a', 'b'},
  nonterminals: const {'S', 'A', 'B', 'U'},
  startSymbol: 'S',
  productions: {
    const Production(id: 'p0', leftSide: ['S'], rightSide: ['A', 'B']),
    const Production(id: 'p1', leftSide: ['A'], rightSide: [], isLambda: true),
    const Production(id: 'p2', leftSide: ['A'], rightSide: ['a']),
    const Production(id: 'p3', leftSide: ['B'], rightSide: ['A']),
    const Production(id: 'p4', leftSide: ['B'], rightSide: ['b']),
    const Production(id: 'p5', leftSide: ['U'], rightSide: ['a']),
  },
  type: GrammarType.contextFree,
  created: DateTime.utc(2026),
  modified: DateTime.utc(2026),
);

Grammar _llConflictGrammar() => Grammar(
  id: 'll-conflict',
  name: 'LL conflict',
  terminals: const {'a', 'b', 'c'},
  nonterminals: const {'S', 'A', 'B'},
  startSymbol: 'S',
  productions: {
    const Production(id: 'p0', leftSide: ['S'], rightSide: ['a', 'A']),
    const Production(id: 'p1', leftSide: ['S'], rightSide: ['a', 'B']),
    const Production(id: 'p2', leftSide: ['A'], rightSide: ['b']),
    const Production(id: 'p3', leftSide: ['B'], rightSide: ['c']),
  },
  type: GrammarType.contextFree,
  created: DateTime.utc(2026),
  modified: DateTime.utc(2026),
);

Grammar _lrConflictGrammar() => Grammar(
  id: 'lr-conflict',
  name: 'LR conflict',
  terminals: const {'id', '+'},
  nonterminals: const {'E'},
  startSymbol: 'E',
  productions: {
    const Production(id: 'p0', leftSide: ['E'], rightSide: ['E', '+', 'E']),
    const Production(id: 'p1', leftSide: ['E'], rightSide: ['id']),
  },
  type: GrammarType.contextFree,
  created: DateTime.utc(2026),
  modified: DateTime.utc(2026),
);
