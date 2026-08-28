import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:turing_lab/core/algorithms/grammar_analyzer.dart';
import 'package:turing_lab/core/algorithms/lr1_parser.dart';
import 'package:turing_lab/core/models/grammar.dart';
import 'package:turing_lab/core/models/production.dart';
import 'package:turing_lab/l10n/app_localizations.dart';
import 'package:turing_lab/presentation/widgets/grammar_normalization_teaching_workspace.dart';
import 'package:turing_lab/presentation/widgets/parse_table_teaching_workspace.dart';

// feature-localization-contract: grammar-analysis-parsing-and-teaching
// feature-localization-surface: localized-editor-fields
// feature-localization-surface: responsive-accessibility
void main() {
  testWidgets(
    'normalization keeps invalid work and exposes semantic feedback',
    (tester) async {
      final semantics = tester.ensureSemantics();
      await _pump(
        tester,
        GrammarNormalizationTeachingWorkspace(grammar: _normalizationGrammar()),
      );

      final field = find.byKey(const ValueKey('normalization-draft'));
      await tester.enterText(field, 'S -> Z');
      await tester.tap(
        find.byKey(const ValueKey('validate-normalization-draft')),
      );
      await tester.pump();

      expect(
        find.byKey(const ValueKey('normalization-diagnostic-invalidSymbol')),
        findsOneWidget,
      );
      expect(tester.widget<TextField>(field).controller!.text, 'S -> Z');
      expect(
        find.bySemanticsLabel('Grammar normalization teaching workspace'),
        findsOneWidget,
      );
      expect(
        find.byKey(const ValueKey('undo-normalization-draft')),
        findsOneWidget,
      );
      semantics.dispose();
    },
  );

  testWidgets(
    'normalization edits refresh diagnostics and undo controls immediately',
    (tester) async {
      await _pump(
        tester,
        GrammarNormalizationTeachingWorkspace(grammar: _normalizationGrammar()),
      );

      final field = find.byKey(const ValueKey('normalization-draft'));
      final validate = find.byKey(
        const ValueKey('validate-normalization-draft'),
      );
      final undo = find.byKey(const ValueKey('undo-normalization-draft'));
      final redo = find.byKey(const ValueKey('redo-normalization-draft'));
      final invalidSymbol = find.byKey(
        const ValueKey('normalization-diagnostic-invalidSymbol'),
      );

      expect(tester.widget<IconButton>(undo).onPressed, isNull);
      expect(tester.widget<IconButton>(redo).onPressed, isNull);

      await tester.enterText(field, 'S -> Z');
      await tester.pump();
      expect(tester.widget<IconButton>(undo).onPressed, isNotNull);
      expect(tester.widget<IconButton>(redo).onPressed, isNull);

      await tester.tap(validate);
      await tester.pump();
      expect(invalidSymbol, findsOneWidget);

      await tester.enterText(field, 'S -> a');
      await tester.pump();
      expect(invalidSymbol, findsNothing);
      expect(tester.widget<IconButton>(undo).onPressed, isNotNull);
      expect(tester.widget<IconButton>(redo).onPressed, isNull);

      await tester.tap(undo);
      await tester.pump();
      expect(invalidSymbol, findsOneWidget);
      expect(tester.widget<IconButton>(redo).onPressed, isNotNull);
    },
  );

  testWidgets('normalization has no overflow at compact width', (tester) async {
    await tester.binding.setSurfaceSize(const Size(360, 800));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await _pump(
      tester,
      GrammarNormalizationTeachingWorkspace(grammar: _normalizationGrammar()),
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets('locale switch preserves the normalization draft and session', (
    tester,
  ) async {
    await _pump(
      tester,
      GrammarNormalizationTeachingWorkspace(grammar: _normalizationGrammar()),
      locale: const Locale('en'),
    );
    final field = find.byKey(const ValueKey('normalization-draft'));
    await tester.enterText(field, 'S -> Z');
    await tester.pump();
    expect(find.text('Remove empty productions'), findsOne);

    await _pump(
      tester,
      GrammarNormalizationTeachingWorkspace(grammar: _normalizationGrammar()),
      locale: const Locale('pt', 'BR'),
    );

    expect(find.text('Remova produções vazias'), findsOne);
    expect(tester.widget<TextField>(field).controller!.text, 'S -> Z');
    expect(find.bySemanticsLabel(RegExp('Remova produções vazias')), findsOne);
  });

  testWidgets('parse-table teaching localizes LL/LR controls and semantics', (
    tester,
  ) async {
    final semantics = tester.ensureSemantics();
    await tester.binding.setSurfaceSize(const Size(320, 700));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    try {
      final llGrammar = _llConflictGrammar();
      final llTable = GrammarAnalyzer.buildLL1ParseTable(llGrammar).data!.value;
      await _pump(
        tester,
        ParseTableTeachingWorkspace.ll1(grammar: llGrammar, table: llTable),
        locale: const Locale('pt', 'BR'),
        textScaler: const TextScaler.linear(2),
      );

      expect(find.text('Pratique a tabela LL(1)'), findsOneWidget);
      expect(find.text('Modo didático'), findsOneWidget);
      expect(find.text('Sua entrada'), findsWidgets);
      expect(find.text('Ocultar respostas geradas'), findsOneWidget);
      expect(
        find.bySemanticsLabel(
          'Ambiente didático editável da tabela de análise',
        ),
        findsOneWidget,
      );
      expect(find.bySemanticsLabel(RegExp('célula da tabela')), findsWidgets);
      expect(
        find.bySemanticsLabel(RegExp('Resposta gerada para')),
        findsWidgets,
      );
      await tester.tap(find.byKey(const ValueKey('parse-table-teaching-mode')));
      await tester.pump();
      final llChoice = find.byKey(const ValueKey('parse-conflict-ll:S:a-p0'));
      await tester.ensureVisible(llChoice);
      await tester.tap(llChoice);
      await tester.pump();
      expect(find.textContaining('Escolha de conflito válida'), findsOneWidget);

      final lrGrammar = _lrConflictGrammar();
      final construction = LR1Parser.build(lrGrammar).construction!;
      await _pump(
        tester,
        ParseTableTeachingWorkspace.lr1(
          grammar: lrGrammar,
          construction: construction,
        ),
        locale: const Locale('pt', 'BR'),
        textScaler: const TextScaler.linear(2),
      );

      expect(find.text('Pratique a tabela LR(1)'), findsOneWidget);
      expect(find.text('Modo didático'), findsOneWidget);
      expect(find.text('Ocultar respostas geradas'), findsOneWidget);
      expect(
        find.bySemanticsLabel(
          'Ambiente didático editável da tabela de análise',
        ),
        findsOneWidget,
      );
      expect(tester.takeException(), isNull);
    } finally {
      semantics.dispose();
    }
  });

  testWidgets(
    'LL teaching mode edits with focus and preserves all conflict answers',
    (tester) async {
      final grammar = _llConflictGrammar();
      final table = GrammarAnalyzer.buildLL1ParseTable(grammar).data!.value;
      final semantics = tester.ensureSemantics();
      await _pump(
        tester,
        ParseTableTeachingWorkspace.ll1(grammar: grammar, table: table),
      );

      await tester.tap(find.byKey(const ValueKey('parse-table-teaching-mode')));
      await tester.pump();
      final cell = find.byKey(const ValueKey('teaching-cell-ll:S:a'));
      final input = find.descendant(
        of: cell,
        matching: find.byType(TextFormField),
      );
      await tester.ensureVisible(input);
      await tester.tap(input);
      await tester.pump();
      expect(FocusManager.instance.primaryFocus, isNotNull);
      await tester.enterText(input, 'p');
      await tester.pump();
      await tester.enterText(input, 'p0');
      await tester.pump();
      expect(FocusManager.instance.primaryFocus, isNotNull);

      final choice = find.byKey(const ValueKey('parse-conflict-ll:S:a-p0'));
      await tester.ensureVisible(choice);
      await tester.tap(choice);
      await tester.pump();

      expect(find.textContaining('Valid conflict choice'), findsOneWidget);
      expect(find.textContaining('p0: S → a A / p1: S → a B'), findsOneWidget);
      expect(
        find.bySemanticsLabel('Editable parse-table teaching workspace'),
        findsOneWidget,
      );
      semantics.dispose();
    },
  );

  testWidgets('parse-table cards stack without overflow on a phone', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(360, 800));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    final grammar = _llConflictGrammar();
    final table = GrammarAnalyzer.buildLL1ParseTable(grammar).data!.value;
    await _pump(
      tester,
      ParseTableTeachingWorkspace.ll1(grammar: grammar, table: table),
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets('LR teaching mode exposes every competing action', (
    tester,
  ) async {
    final grammar = _lrConflictGrammar();
    final construction = LR1Parser.build(grammar).construction!;
    final conflict = construction.table.conflicts.first;
    final action = conflict.actions.first;
    final key = 'lr:action:${conflict.state}:${conflict.lookahead}';
    await _pump(
      tester,
      ParseTableTeachingWorkspace.lr1(
        grammar: grammar,
        construction: construction,
      ),
    );

    await tester.tap(find.byKey(const ValueKey('parse-table-teaching-mode')));
    await tester.pump();
    final choice = find.byKey(
      ValueKey('parse-conflict-$key-${action.stableKey}'),
    );
    await tester.ensureVisible(choice);
    await tester.tap(choice);
    await tester.pump();

    expect(find.textContaining('Valid conflict choice'), findsOneWidget);
    for (final competing in conflict.actions) {
      expect(
        find.byKey(ValueKey('parse-conflict-$key-${competing.stableKey}')),
        findsOneWidget,
      );
    }
  });
}

Future<void> _pump(
  WidgetTester tester,
  Widget child, {
  Locale locale = const Locale('en'),
  TextScaler textScaler = TextScaler.noScaling,
}) async {
  await tester.pumpWidget(
    MaterialApp(
      locale: locale,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: MediaQuery(
        data: MediaQueryData(textScaler: textScaler),
        child: Scaffold(
          body: SingleChildScrollView(
            padding: const EdgeInsets.all(8),
            child: child,
          ),
        ),
      ),
    ),
  );
  await tester.pump();
}

Grammar _normalizationGrammar() => Grammar(
  id: 'normalization-widget',
  name: 'Normalization exercise',
  terminals: const {'a', 'b'},
  nonterminals: const {'S', 'A', 'B'},
  startSymbol: 'S',
  productions: {
    const Production(id: 'p0', leftSide: ['S'], rightSide: ['A', 'B']),
    const Production(id: 'p1', leftSide: ['A'], rightSide: [], isLambda: true),
    const Production(id: 'p2', leftSide: ['A'], rightSide: ['a']),
    const Production(id: 'p3', leftSide: ['B'], rightSide: ['b']),
  },
  type: GrammarType.contextFree,
  created: DateTime.utc(2026),
  modified: DateTime.utc(2026),
);

Grammar _llConflictGrammar() => Grammar(
  id: 'll-widget',
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
  id: 'lr-widget',
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
