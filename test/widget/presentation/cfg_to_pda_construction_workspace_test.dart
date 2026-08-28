import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:turing_lab/core/algorithms/grammar_to_pda/cfg_to_pda.dart';
import 'package:turing_lab/core/models/grammar.dart';
import 'package:turing_lab/core/models/pda.dart';
import 'package:turing_lab/core/models/production.dart';
import 'package:turing_lab/l10n/app_localizations.dart';
import 'package:turing_lab/presentation/widgets/cfg_to_pda_construction_workspace.dart';

// feature-localization-contract: automata-conversions-and-fragments
// feature-localization-surface: localized-editor-fields
// feature-localization-surface: responsive-accessibility
void main() {
  testWidgets('guided CFG-to-PDA previews localize their teaching surfaces', (
    tester,
  ) async {
    final semantics = tester.ensureSemantics();
    await tester.binding.setSurfaceSize(const Size(320, 700));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    try {
      for (final orientation in CfgToPdaOrientation.values) {
        await _pumpWorkspace(
          tester,
          grammar: _llGrammar(),
          orientation: orientation,
          locale: const Locale('pt', 'BR'),
          textScaler: const TextScaler.linear(2),
        );

        final suffix = orientation == CfgToPdaOrientation.ll ? 'LL' : 'LR';
        expect(
          find.text('Prévia da construção GLC para AP ($suffix)'),
          findsOneWidget,
        );
        expect(find.text('Premissas da construção'), findsOneWidget);
        expect(find.text('Etapas da construção'), findsOneWidget);
        expect(find.text('Evidência diferencial limitada'), findsOneWidget);
        expect(find.text('Executar verificação amostral'), findsOneWidget);
        expect(find.text('Abrir no editor de AP'), findsOneWidget);
        expect(
          tester.getSemantics(find.text('Etapas da construção')).label,
          contains('Etapas da construção'),
        );
        expect(tester.takeException(), isNull);
      }
    } finally {
      semantics.dispose();
    }
  });

  testWidgets(
    'previews LL steps and synchronizes production/transition sources',
    (tester) async {
      await _useLargeSurface(tester);
      PDA? opened;
      var cancelled = false;
      await _pumpWorkspace(
        tester,
        grammar: _llGrammar(),
        orientation: CfgToPdaOrientation.ll,
        onOpen: (pda) async => opened = pda,
        onCancel: () => cancelled = true,
      );

      expect(find.text('CFG to PDA (LL) construction preview'), findsOneWidget);
      expect(find.text('States: 3'), findsOneWidget);
      expect(find.text('Transitions: 7'), findsOneWidget);
      final expansionStep = find.byKey(const ValueKey('cfg-pda-step-5'));
      await tester.scrollUntilVisible(
        expansionStep,
        120,
        scrollable: find.descendant(
          of: find.byKey(const ValueKey('cfg-pda-step-list')),
          matching: find.byType(Scrollable),
        ),
      );
      await tester.tap(expansionStep);
      await tester.pump();

      final production = tester.widget<ListTile>(
        find.byKey(const ValueKey('cfg-pda-production-tail-more')),
      );
      final transition = tester.widget<ListTile>(
        find.byKey(const ValueKey('cfg-pda-transition-ll-t-0002')),
      );
      expect(production.selected, isTrue);
      expect(transition.selected, isTrue);
      expect(find.textContaining('[plus, identifier, Tail]'), findsOneWidget);

      await tester.ensureVisible(find.byKey(const ValueKey('cfg-pda-open')));
      await tester.tap(find.byKey(const ValueKey('cfg-pda-open')));
      await tester.pump();
      expect(opened, isNotNull);
      expect(opened!.validate(), isEmpty);

      await tester.tap(find.byKey(const ValueKey('cfg-pda-cancel')));
      expect(cancelled, isTrue);
    },
  );

  testWidgets('shows LR item cells and runs bounded differential evidence', (
    tester,
  ) async {
    await _useLargeSurface(tester);
    await _pumpWorkspace(
      tester,
      grammar: _lrGrammar(),
      orientation: CfgToPdaOrientation.lr,
    );

    expect(find.text('CFG to PDA (LR) construction preview'), findsOneWidget);
    final reductionStep = find.byKey(const ValueKey('cfg-pda-step-6'));
    await tester.scrollUntilVisible(
      reductionStep,
      120,
      scrollable: find.descendant(
        of: find.byKey(const ValueKey('cfg-pda-step-list')),
        matching: find.byType(Scrollable),
      ),
    );
    await tester.tap(reductionStep);
    await tester.pump();
    expect(find.textContaining('LR cells:'), findsWidgets);
    expect(
      tester
          .widget<ListTile>(
            find.byKey(const ValueKey('cfg-pda-production-s-cc')),
          )
          .selected,
      isTrue,
    );

    final samples = find.byKey(const ValueKey('cfg-pda-run-samples'));
    await tester.ensureVisible(samples);
    await tester.tap(samples);
    await _waitForText(tester, 'Grammar and PDA accepted this sample.');
    expect(find.text('Grammar and PDA accepted this sample.'), findsWidgets);
    expect(
      find.text(
        'Finite samples can detect a mismatch but cannot prove language equivalence.',
      ),
      findsOneWidget,
    );
  });

  testWidgets('surfaces LL conflicts as typed blocking diagnostics', (
    tester,
  ) async {
    await _useLargeSurface(tester);
    await _pumpWorkspace(
      tester,
      grammar: _llConflictGrammar(),
      orientation: CfgToPdaOrientation.ll,
    );

    expect(find.byKey(const ValueKey('cfg-pda-blocked')), findsOneWidget);
    expect(
      find.text('LL(1) conflicts block the LL construction.'),
      findsOneWidget,
    );
    expect(
      find.text('LL conflict for S with lookahead a: p1, p2.'),
      findsOneWidget,
    );
    expect(find.byKey(const ValueKey('cfg-pda-open')), findsNothing);
  });

  testWidgets('localizes typed LL conflict diagnostics in Portuguese', (
    tester,
  ) async {
    await _useLargeSurface(tester);
    await _pumpWorkspace(
      tester,
      grammar: _llConflictGrammar(),
      orientation: CfgToPdaOrientation.ll,
      locale: const Locale('pt', 'BR'),
    );

    expect(
      find.text('Conflito LL para S com lookahead a: p1, p2.'),
      findsOneWidget,
    );
    expect(find.textContaining('LL(1) [S, a]'), findsNothing);
  });

  testWidgets(
    'invalidates stale previews and does not present generated data',
    (tester) async {
      await _useLargeSurface(tester);
      await _pumpWorkspace(
        tester,
        grammar: _llGrammar(),
        orientation: CfgToPdaOrientation.ll,
        invalidated: true,
        waitForReport: false,
      );

      expect(find.byKey(const ValueKey('cfg-pda-invalidated')), findsOneWidget);
      expect(find.text('States: 3'), findsNothing);
      expect(find.byKey(const ValueKey('cfg-pda-open')), findsNothing);
    },
  );

  testWidgets('supports arrow navigation and 320px at 200 percent text', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(320, 1800));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await _pumpWorkspace(
      tester,
      grammar: _llGrammar(),
      orientation: CfgToPdaOrientation.ll,
      textScaler: const TextScaler.linear(2),
    );

    await tester.sendKeyEvent(LogicalKeyboardKey.arrowRight);
    await tester.pump();
    expect(
      tester
          .widget<ListTile>(find.byKey(const ValueKey('cfg-pda-step-1')))
          .selected,
      isTrue,
    );
    expect(tester.takeException(), isNull);
    expect(
      tester.getSize(find.byKey(const ValueKey('cfg-pda-open'))).height,
      greaterThanOrEqualTo(48),
    );
  });
}

Future<void> _pumpWorkspace(
  WidgetTester tester, {
  required Grammar grammar,
  required CfgToPdaOrientation orientation,
  Future<void> Function(PDA)? onOpen,
  VoidCallback? onCancel,
  bool invalidated = false,
  bool waitForReport = true,
  TextScaler textScaler = TextScaler.noScaling,
  Locale locale = const Locale('en'),
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
            child: CfgToPdaConstructionWorkspace(
              grammar: grammar,
              sourceRevision: 4,
              orientation: orientation,
              invalidated: invalidated,
              onOpen: onOpen ?? (_) async {},
              onCancel: onCancel ?? () {},
            ),
          ),
        ),
      ),
    ),
  );
  if (waitForReport) await _waitForReport(tester);
}

Future<void> _waitForReport(WidgetTester tester) async {
  for (var attempt = 0; attempt < 80; attempt++) {
    await tester.runAsync(
      () => Future<void>.delayed(const Duration(milliseconds: 3)),
    );
    await tester.pump(const Duration(milliseconds: 10));
    if (find.byKey(const ValueKey('cfg-pda-open')).evaluate().isNotEmpty ||
        find.byKey(const ValueKey('cfg-pda-blocked')).evaluate().isNotEmpty) {
      return;
    }
    final error = find.byKey(const ValueKey('cfg-pda-error'));
    if (error.evaluate().isNotEmpty) fail('Construction workspace failed.');
  }
}

Future<void> _waitForText(WidgetTester tester, String text) async {
  for (var attempt = 0; attempt < 100; attempt++) {
    await tester.runAsync(
      () => Future<void>.delayed(const Duration(milliseconds: 3)),
    );
    await tester.pump(const Duration(milliseconds: 10));
    if (find.text(text).evaluate().isNotEmpty) return;
  }
}

Future<void> _useLargeSurface(WidgetTester tester) async {
  await tester.binding.setSurfaceSize(const Size(1200, 2200));
  addTearDown(() => tester.binding.setSurfaceSize(null));
}

Grammar _llGrammar() => _grammar(
  terminals: {'identifier', 'plus'},
  nonterminals: {'S', 'Tail'},
  productions: {
    const Production(
      id: 'start',
      leftSide: ['S'],
      rightSide: ['identifier', 'Tail'],
    ),
    const Production(
      id: 'tail-more',
      leftSide: ['Tail'],
      rightSide: ['plus', 'identifier', 'Tail'],
      order: 1,
    ),
    const Production(
      id: 'tail-empty',
      leftSide: ['Tail'],
      rightSide: [],
      isLambda: true,
      order: 2,
    ),
  },
);

Grammar _lrGrammar() => _grammar(
  terminals: {'c', 'd'},
  nonterminals: {'S', 'C'},
  productions: {
    const Production(id: 's-cc', leftSide: ['S'], rightSide: ['C', 'C']),
    const Production(
      id: 'c-c',
      leftSide: ['C'],
      rightSide: ['c', 'C'],
      order: 1,
    ),
    const Production(id: 'c-d', leftSide: ['C'], rightSide: ['d'], order: 2),
  },
);

Grammar _llConflictGrammar() => _grammar(
  terminals: {'a'},
  nonterminals: {'S'},
  productions: {
    const Production(id: 'p1', leftSide: ['S'], rightSide: ['a']),
    const Production(
      id: 'p2',
      leftSide: ['S'],
      rightSide: ['a', 'S'],
      order: 1,
    ),
  },
);

Grammar _grammar({
  required Set<String> terminals,
  required Set<String> nonterminals,
  required Set<Production> productions,
}) => Grammar(
  id: 'widget-cfg-pda',
  name: 'Widget CFG to PDA',
  terminals: terminals,
  nonterminals: nonterminals,
  startSymbol: 'S',
  productions: productions,
  type: GrammarType.contextFree,
  created: DateTime.utc(2026),
  modified: DateTime.utc(2026),
);
