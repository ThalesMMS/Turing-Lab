import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';
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

  testWidgets('reorders with localized handle semantics and menu actions', (
    tester,
  ) async {
    final controller = UnrestrictedGrammarEditorController(_orderedGrammar());
    await _pumpWorkspace(
      tester,
      controller: controller,
      locale: const Locale('en'),
    );

    final handle = find.byKey(
      const ValueKey('unrestricted-production-handle-p1'),
    );
    final semantics = tester.getSemantics(handle);
    expect(semantics.label, contains('Reorder production p1'));
    expect(semantics.value, contains('Position 1 of 3'));
    expect(tester.getSize(handle), const Size(48, 48));

    await tester.tap(find.byTooltip('Production actions').first);
    await tester.pumpAndSettle();
    expect(
      tester
          .widget<PopupMenuItem<String>>(
            find.ancestor(
              of: find.text('Move up'),
              matching: find.byType(PopupMenuItem<String>),
            ),
          )
          .enabled,
      isFalse,
    );
    await tester.tap(find.text('Move down'));
    await tester.pumpAndSettle();

    expect(controller.grammar.productions.map((production) => production.id), [
      'p2',
      'p1',
      'p3',
    ]);
    final movedSemantics = tester.getSemantics(handle);
    // Flutter 3.32 compatibility.
    // ignore: deprecated_member_use
    expect(movedSemantics.hasFlag(SemanticsFlag.isFocused), isTrue);
  });

  testWidgets('drags an unrestricted production from last to first', (
    tester,
  ) async {
    final controller = UnrestrictedGrammarEditorController(_orderedGrammar());
    await _pumpWorkspace(tester, controller: controller);

    final lastHandle = find.byKey(
      const ValueKey('unrestricted-production-handle-p3'),
    );
    final firstHandle = find.byKey(
      const ValueKey('unrestricted-production-handle-p1'),
    );
    final gesture = await tester.startGesture(tester.getCenter(lastHandle));
    await tester.pump();
    await gesture.moveTo(tester.getCenter(firstHandle));
    await tester.pump(const Duration(milliseconds: 500));
    await gesture.up();
    await tester.pumpAndSettle();

    expect(controller.grammar.productions.map((production) => production.id), [
      'p3',
      'p1',
      'p2',
    ]);
    expect(controller.grammar.revision, 1);
  });

  testWidgets('auto-scrolls a long production list during handle drag', (
    tester,
  ) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(500, 500);
    addTearDown(tester.view.resetDevicePixelRatio);
    addTearDown(tester.view.resetPhysicalSize);
    final controller = UnrestrictedGrammarEditorController(_orderedGrammar(14));
    await _pumpWorkspace(tester, controller: controller);

    final firstHandle = find.byKey(
      const ValueKey('unrestricted-production-handle-p1'),
    );
    final surface = find.byKey(
      const ValueKey('unrestricted-grammar-productions-surface'),
    );
    final gesture = await tester.startGesture(tester.getCenter(firstHandle));
    await tester.pump();
    await gesture.moveTo(tester.getBottomRight(surface) - const Offset(80, 1));
    for (var frame = 0; frame < 24; frame++) {
      await tester.pump(const Duration(milliseconds: 100));
    }
    final scrollable = tester.state<ScrollableState>(
      find.descendant(of: surface, matching: find.byType(Scrollable)).first,
    );
    expect(scrollable.position.pixels, greaterThan(0));
    await gesture.moveBy(const Offset(0, -1));
    await tester.pump();
    await gesture.moveBy(const Offset(0, 1));
    await tester.pump();
    await gesture.up();
    await tester.pumpAndSettle();

    final movedIndex = controller.grammar.productions.indexWhere(
      (production) => production.id == 'p1',
    );
    expect(movedIndex, greaterThan(0));
    expect(
      controller.grammar.productions.map((production) => production.order),
      List.generate(14, (index) => index),
    );
  });

  testWidgets('localizes unrestricted reorder semantics in Portuguese', (
    tester,
  ) async {
    final controller = UnrestrictedGrammarEditorController(_orderedGrammar());
    await _pumpWorkspace(tester, controller: controller);

    final handle = find.byKey(
      const ValueKey('unrestricted-production-handle-p2'),
    );
    final semantics = tester.getSemantics(handle);
    expect(semantics.label, contains('Reordenar produção p2'));
    expect(semantics.value, contains('Posição 2 de 3'));

    await tester.tap(find.byTooltip('Ações da produção').at(1));
    await tester.pumpAndSettle();
    expect(find.text('Mover para cima'), findsOneWidget);
    expect(find.text('Mover para baixo'), findsOneWidget);
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

  testWidgets('reorder immediately synchronizes the duplicate editor list', (
    tester,
  ) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(1200, 800);
    addTearDown(tester.view.resetDevicePixelRatio);
    addTearDown(tester.view.resetPhysicalSize);
    final controller = UnrestrictedGrammarEditorController(_orderedGrammar());
    final actions = await _pumpWorkspace(tester, controller: controller);
    actions.value!.onEdit!();
    await tester.pumpAndSettle();

    await tester.tap(find.byTooltip('Ações da produção').first);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Mover para baixo'));
    await tester.pumpAndSettle();

    final editorPanel = find.byKey(WorkspaceDock.panelKey('unrestricted-edit'));
    final editorP1 = find.descendant(
      of: editorPanel,
      matching: find.byKey(const ValueKey('grammar-production-p1')),
    );
    final editorP2 = find.descendant(
      of: editorPanel,
      matching: find.byKey(const ValueKey('grammar-production-p2')),
    );
    expect(
      tester.getTopLeft(editorP2).dy,
      lessThan(tester.getTopLeft(editorP1).dy),
    );
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
      expect(
        UnrestrictedGrammarWorkspaceStrings.forLocale(
          const Locale('pt', 'BR'),
        ).reorderProduction('p3'),
        'Reordenar produção p3',
      );
      expect(
        UnrestrictedGrammarWorkspaceStrings.forLocale(
          const Locale('en'),
        ).productionPosition(2, 4),
        'Position 2 of 4',
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

UnrestrictedGrammar _orderedGrammar([int count = 3]) => UnrestrictedGrammar(
  id: 'ordered-widget-grammar',
  name: 'Ordered widget grammar',
  revision: 0,
  terminals: [
    for (var index = 0; index < count; index++)
      TerminalGrammarSymbol('t$index'),
  ],
  nonterminals: const [NonterminalGrammarSymbol('S')],
  startSymbol: const NonterminalGrammarSymbol('S'),
  productions: [
    for (var index = 0; index < count; index++)
      PhraseStructureProduction(
        id: 'p${index + 1}',
        order: index,
        left: GrammarSymbolSequence(const [NonterminalGrammarSymbol('S')]),
        right: GrammarSymbolSequence([TerminalGrammarSymbol('t$index')]),
      ),
  ],
);
