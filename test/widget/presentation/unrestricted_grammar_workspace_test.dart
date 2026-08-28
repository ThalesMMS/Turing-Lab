import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:turing_lab/core/grammar/phrase_structure/phrase_structure.dart';
import 'package:turing_lab/presentation/providers/workspace_quick_actions_provider.dart';
import 'package:turing_lab/presentation/unrestricted_grammar/unrestricted_grammar_editor_controller.dart';
import 'package:turing_lab/presentation/unrestricted_grammar/unrestricted_grammar_workspace.dart';
import 'package:turing_lab/presentation/unrestricted_grammar/unrestricted_grammar_workspace_strings.dart';
import 'package:turing_lab/presentation/widgets/automaton_workspace_scaffold.dart';
import 'package:turing_lab/presentation/widgets/workspace_dock.dart';

void main() {
  testWidgets('keeps productions primary and preserves token IDs on edit', (
    tester,
  ) async {
    final controller = UnrestrictedGrammarEditorController(_grammar());
    final actions = await _pumpWorkspace(tester, controller: controller);

    expect(
      find.byKey(const ValueKey('unrestricted-grammar-productions-surface')),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey('unrestricted-grammar-left')),
      findsNothing,
    );
    actions.value!.onEdit!();
    await tester.pumpAndSettle();

    await tester.enterText(
      find.byKey(const ValueKey('unrestricted-grammar-name')),
      'Renamed grammar',
    );
    tester
        .widget<FilledButton>(
          find.byKey(const ValueKey('unrestricted-grammar-save-details')),
        )
        .onPressed!();
    await tester.pump();
    expect(controller.grammar.id, 'widget-grammar');
    expect(controller.grammar.name, 'Renamed grammar');
    expect(controller.grammar.productions.single.id, 'p1');

    await tester.enterText(
      find.byKey(const ValueKey('unrestricted-grammar-left')),
      '["n:S","t:a,b"]',
    );
    await tester.enterText(
      find.byKey(const ValueKey('unrestricted-grammar-right')),
      '["t:🙂"]',
    );
    final add = find.byKey(const ValueKey('unrestricted-grammar-add'));
    tester.widget<FilledButton>(add).onPressed!();
    await tester.pump();

    expect(controller.grammar.productions, hasLength(2));
    expect(controller.grammar.productions.last.id, 'p2');
    expect(controller.grammar.productions.last.order, 1);
    expect(controller.grammar.productions.last.left.symbols, [
      const NonterminalGrammarSymbol('S'),
      const TerminalGrammarSymbol('a,b'),
    ]);
    expect(controller.grammar.productions.last.right.symbols, [
      const TerminalGrammarSymbol('🙂'),
    ]);
    controller.undo();
    expect(controller.grammar.productions, hasLength(1));
    controller.redo();
    expect(controller.grammar.productions, hasLength(2));

    await tester.tap(find.byTooltip('Fechar'));
    await tester.pumpAndSettle();
    await tester.tap(
      find.descendant(
        of: find.byKey(const ValueKey('grammar-production-p1')),
        matching: find.byTooltip('Editar produção'),
      ),
    );
    await tester.pumpAndSettle();
    await tester.enterText(
      find.byKey(const ValueKey('unrestricted-grammar-right')),
      '["t:🙂"]',
    );
    tester.widget<FilledButton>(add).onPressed!();
    await tester.pump();
    expect(controller.grammar.productions.first.id, 'p1');
    expect(controller.grammar.productions.first.order, 0);
    expect(
      controller.grammar.productions.first.right.symbols.single.value,
      '🙂',
    );
  });

  testWidgets('opens bounded derivation without an implicit run', (
    tester,
  ) async {
    final controller = UnrestrictedGrammarEditorController(_grammar());
    final actions = await _pumpWorkspace(tester, controller: controller);

    actions.value!.onSimulate!();
    await tester.pumpAndSettle();
    expect(find.text('Derivação encontrada'), findsNothing);
    await tester.enterText(
      find.byKey(const ValueKey('unrestricted-grammar-input')),
      '["a,b"]',
    );
    await tester.tap(find.byKey(const ValueKey('unrestricted-grammar-run')));
    await tester.pumpAndSettle();
    expect(find.text('Derivação encontrada'), findsOneWidget);
    expect(find.textContaining('p1 @ 0'), findsOneWidget);

    await tester.enterText(
      find.byKey(const ValueKey('unrestricted-grammar-max-expanded')),
      '0',
    );
    await tester.tap(find.byKey(const ValueKey('unrestricted-grammar-run')));
    await tester.pumpAndSettle();
    expect(
      find.text('Resultado inconclusivo: limite atingido'),
      findsOneWidget,
    );
    expect(find.textContaining('esgotado sem derivação'), findsNothing);
  });

  testWidgets('fits 320px at 200 percent with localized action semantics', (
    tester,
  ) async {
    final controller = UnrestrictedGrammarEditorController(_grammar());
    await tester.binding.setSurfaceSize(const Size(320, 700));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    final actions = await _pumpWorkspace(
      tester,
      controller: controller,
      textScaler: const TextScaler.linear(2),
      locale: const Locale('en'),
    );

    expect(find.text('Productions'), findsOneWidget);
    expect(tester.takeException(), isNull);
    actions.value!.onSimulate!();
    await tester.pumpAndSettle();
    final run = find.byKey(const ValueKey('unrestricted-grammar-run'));
    expect(tester.getSemantics(run).label, contains('Search for derivation'));
    expect(tester.getSize(run).height, greaterThanOrEqualTo(48));
    expect(tester.takeException(), isNull);
  });

  testWidgets('wide actions swap one dock while productions remain mounted', (
    tester,
  ) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(1200, 800);
    addTearDown(tester.view.resetDevicePixelRatio);
    addTearDown(tester.view.resetPhysicalSize);
    final controller = UnrestrictedGrammarEditorController(_grammar());
    final actions = await _pumpWorkspace(tester, controller: controller);
    final surface = find.byKey(
      const ValueKey('unrestricted-grammar-productions-surface'),
    );

    actions.value!.onEdit!();
    await tester.pumpAndSettle();
    expect(
      find.byKey(WorkspaceDock.panelKey('unrestricted-edit')),
      findsOneWidget,
    );
    expect(surface, findsOneWidget);

    actions.value!.onSimulate!();
    await tester.pumpAndSettle();
    expect(
      find.byKey(
        WorkspaceDock.panelKey(AutomatonWorkspaceScaffold.simulationPanelId),
      ),
      findsOneWidget,
    );
    expect(find.text('Derivação encontrada'), findsNothing);
    expect(
      find.byKey(WorkspaceDock.panelKey('unrestricted-edit')),
      findsNothing,
    );

    actions.value!.onAlgorithms!();
    await tester.pumpAndSettle();
    expect(
      find.byKey(
        WorkspaceDock.panelKey(AutomatonWorkspaceScaffold.algorithmPanelId),
      ),
      findsOneWidget,
    );
    expect(surface, findsOneWidget);
  });

  testWidgets(
    'resize keeps one workspace surface and preserves derivation state and focus',
    (tester) async {
      tester.view.devicePixelRatio = 1;
      tester.view.physicalSize = const Size(1200, 800);
      addTearDown(tester.view.resetDevicePixelRatio);
      addTearDown(tester.view.resetPhysicalSize);
      final triggerFocus = FocusNode(debugLabel: 'Unrestricted action trigger');
      addTearDown(triggerFocus.dispose);
      final controller = UnrestrictedGrammarEditorController(_grammar());
      final originalGrammar = controller.grammar;
      final actions = await _pumpWorkspace(
        tester,
        controller: controller,
        triggerFocus: triggerFocus,
      );

      triggerFocus.requestFocus();
      await tester.pump();
      actions.value!.onEdit!();
      await tester.pumpAndSettle();
      expect(
        find.byKey(WorkspaceDock.panelKey('unrestricted-edit')),
        findsOneWidget,
      );

      tester.view.physicalSize = const Size(430, 800);
      await tester.pumpAndSettle();
      expect(find.byType(WorkspaceDock), findsNothing);

      triggerFocus.requestFocus();
      await tester.pump();
      actions.value!.onSimulate!();
      await tester.pumpAndSettle();
      await tester.enterText(
        find.byKey(const ValueKey('unrestricted-grammar-input')),
        '["a,b"]',
      );

      tester.view.physicalSize = const Size(1200, 800);
      await tester.pumpAndSettle();
      expect(find.byType(DraggableScrollableSheet), findsNothing);
      expect(
        find.byKey(WorkspaceDock.panelKey('unrestricted-edit')),
        findsNothing,
      );
      expect(
        find.byKey(
          WorkspaceDock.panelKey(AutomatonWorkspaceScaffold.simulationPanelId),
        ),
        findsNothing,
      );
      expect(triggerFocus.hasPrimaryFocus, isTrue);

      actions.value!.onSimulate!();
      await tester.pumpAndSettle();
      expect(
        find.byKey(
          WorkspaceDock.panelKey(AutomatonWorkspaceScaffold.simulationPanelId),
        ),
        findsOneWidget,
      );
      expect(
        tester
            .widget<TextField>(
              find.byKey(const ValueKey('unrestricted-grammar-input')),
            )
            .controller
            ?.text,
        '["a,b"]',
      );
      expect(controller.grammar, same(originalGrammar));
    },
  );

  testWidgets('preserves and invalidates a manual derivation across surfaces', (
    tester,
  ) async {
    final controller = UnrestrictedGrammarEditorController(_grammar());
    final actions = await _pumpWorkspace(tester, controller: controller);
    actions.value!.onSimulate!();
    await tester.pumpAndSettle();

    await tester.enterText(
      find.byKey(const ValueKey('unrestricted-grammar-input')),
      '["a,b"]',
    );
    await tester.tap(
      find.byKey(const ValueKey('unrestricted-start-manual-derivation')),
    );
    await tester.pumpAndSettle();
    expect(
      find.byKey(const ValueKey('user-derivation-workspace')),
      findsOneWidget,
    );

    controller.upsertProduction(
      PhraseStructureProduction(
        id: 'p2',
        order: 1,
        left: GrammarSymbolSequence(const [NonterminalGrammarSymbol('S')]),
        right: GrammarSymbolSequence(const [NonterminalGrammarSymbol('S')]),
      ),
    );
    await tester.pump();
    expect(
      find.text('The grammar or target changed. Start a new session.'),
      findsOneWidget,
    );
  });

  testWidgets('opens Algorithms and invalidates the VDG snapshot', (
    tester,
  ) async {
    final controller = UnrestrictedGrammarEditorController(_grammar());
    final actions = await _pumpWorkspace(tester, controller: controller);
    actions.value!.onAlgorithms!();
    await tester.pumpAndSettle();

    await tester.tap(
      find.byKey(const ValueKey('unrestricted-open-variable-dependency-graph')),
    );
    for (var attempt = 0; attempt < 60; attempt++) {
      await tester.runAsync(
        () => Future<void>.delayed(const Duration(milliseconds: 3)),
      );
      await tester.pump(const Duration(milliseconds: 10));
      if (find.byKey(const ValueKey('vdg-viewport')).evaluate().isNotEmpty) {
        break;
      }
    }
    expect(find.byKey(const ValueKey('vdg-viewport')), findsOneWidget);

    controller.upsertProduction(
      PhraseStructureProduction(
        id: 'p2',
        order: 1,
        left: GrammarSymbolSequence(const [NonterminalGrammarSymbol('S')]),
        right: GrammarSymbolSequence(const [NonterminalGrammarSymbol('S')]),
      ),
    );
    await tester.pump();
    expect(find.byKey(const ValueKey('vdg-invalidated')), findsOneWidget);
    expect(find.byKey(const ValueKey('vdg-viewport')), findsNothing);
  });

  test(
    'locale resolver keeps English and Portuguese diagnostics equivalent',
    () {
      const diagnostic = PhraseGrammarDiagnostic(
        code: PhraseGrammarDiagnosticCode.leftSideMissingNonterminal,
        severity: PhraseGrammarDiagnosticSeverity.error,
        productionId: 'p1',
      );
      expect(
        UnrestrictedGrammarWorkspaceStrings.forLocale(
          const Locale('pt', 'BR'),
        ).diagnostic(diagnostic),
        contains('não terminal'),
      );
      expect(
        UnrestrictedGrammarWorkspaceStrings.forLocale(
          const Locale('en'),
        ).diagnostic(diagnostic),
        contains('nonterminal'),
      );
    },
  );
}

Future<ValueNotifier<WorkspaceQuickActions?>> _pumpWorkspace(
  WidgetTester tester, {
  required UnrestrictedGrammarEditorController controller,
  TextScaler textScaler = TextScaler.noScaling,
  Locale locale = const Locale('pt', 'BR'),
  FocusNode? triggerFocus,
}) async {
  final actions = ValueNotifier<WorkspaceQuickActions?>(null);
  addTearDown(actions.dispose);
  await tester.pumpWidget(
    MaterialApp(
      locale: locale,
      builder: (context, child) => MediaQuery(
        data: MediaQuery.of(context).copyWith(textScaler: textScaler),
        child: child!,
      ),
      home: Scaffold(
        body: Column(
          children: [
            if (triggerFocus != null)
              TextButton(
                focusNode: triggerFocus,
                onPressed: () {},
                child: const Text('Workspace action trigger'),
              ),
            Expanded(
              child: UnrestrictedGrammarWorkspace(
                controller: controller,
                strings: UnrestrictedGrammarWorkspaceStrings.forLocale(locale),
                onQuickActionsChanged: (value) => actions.value = value,
              ),
            ),
          ],
        ),
      ),
    ),
  );
  return actions;
}

UnrestrictedGrammar _grammar() => UnrestrictedGrammar(
  id: 'widget-grammar',
  name: 'Widget grammar',
  revision: 0,
  terminals: const [TerminalGrammarSymbol('a,b'), TerminalGrammarSymbol('🙂')],
  nonterminals: const [NonterminalGrammarSymbol('S')],
  startSymbol: const NonterminalGrammarSymbol('S'),
  productions: [
    PhraseStructureProduction(
      id: 'p1',
      order: 0,
      left: GrammarSymbolSequence(const [NonterminalGrammarSymbol('S')]),
      right: GrammarSymbolSequence(const [TerminalGrammarSymbol('a,b')]),
    ),
  ],
);
