//
//  mobile_automaton_controls_test.dart
//  Turing Lab
//
//  Conjunto de testes de widget que confirma o comportamento do
//  MobileAutomatonControls, cobrindo renderização dos botões principais e
//  habilitação condicional de simulação, algoritmos, métricas e ferramentas do
//  canvas. As verificações monitoram callbacks disparados e mensagens de status
//  para assegurar que o painel móvel responda corretamente a diferentes
//  configurações.
//
//  Thales Matheus Mendonça Santos - October 2025
//
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:turing_lab/l10n/app_localizations.dart';
import 'package:turing_lab/presentation/widgets/mobile_automaton_controls.dart';
import 'package:turing_lab/presentation/widgets/automaton_canvas_tool.dart';

void main() {
  test('canvas tool controller defaults to move', () {
    final controller = AutomatonCanvasToolController();
    addTearDown(controller.dispose);

    expect(controller.activeTool, AutomatonCanvasTool.selection);
  });

  testWidgets('MobileAutomatonControls surfaces canvas actions and status', (
    tester,
  ) async {
    var helpCount = 0;
    var addStateInvoked = false;
    var zoomInInvoked = false;
    var zoomOutInvoked = false;
    var clearInvoked = false;

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: MobileAutomatonControls(
            onHelp: () => helpCount++,
            onAddState: () => addStateInvoked = true,
            onZoomIn: () => zoomInInvoked = true,
            onZoomOut: () => zoomOutInvoked = true,
            onFitToContent: () {},
            onResetView: () {},
            onClear: () => clearInvoked = true,
            statusMessage: '3 states · 2 transitions',
          ),
        ),
      ),
    );

    expect(find.byTooltip('Add state'), findsOneWidget);
    expect(find.byTooltip('Help'), findsOneWidget);
    expect(find.bySemanticsLabel('Help'), findsOneWidget);
    expect(find.byTooltip('Zoom out'), findsOneWidget);
    expect(find.byTooltip('Zoom in'), findsOneWidget);
    expect(find.byTooltip('Clear canvas'), findsOneWidget);
    expect(find.text('3 states · 2 transitions'), findsOneWidget);

    await tester.tap(find.byTooltip('Help'));
    await tester.pump();
    await tester.tap(find.byTooltip('Add state'));
    await tester.pump();
    await tester.tap(find.byTooltip('Zoom out'));
    await tester.pump();
    await tester.tap(find.byTooltip('Zoom in'));
    await tester.pump();
    await tester.tap(find.byTooltip('Clear canvas'));
    await tester.pump();

    expect(helpCount, equals(1));
    expect(addStateInvoked, isTrue);
    expect(zoomOutInvoked, isTrue);
    expect(zoomInInvoked, isTrue);
    expect(clearInvoked, isTrue);
  });

  testWidgets('shows undo and redo buttons with disabled history state', (
    tester,
  ) async {
    var undoCount = 0;
    var redoCount = 0;

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: MobileAutomatonControls(
            onHelp: () {},
            onAddState: () {},
            onFitToContent: () {},
            onResetView: () {},
            onUndo: () => undoCount++,
            onRedo: () => redoCount++,
          ),
        ),
      ),
    );

    final undoButton = tester.widget<IconButton>(
      find.descendant(
        of: find.byTooltip('Undo'),
        matching: find.byType(IconButton),
      ),
    );
    final redoButton = tester.widget<IconButton>(
      find.descendant(
        of: find.byTooltip('Redo'),
        matching: find.byType(IconButton),
      ),
    );

    expect(undoButton.onPressed, isNull);
    expect(redoButton.onPressed, isNull);

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: MobileAutomatonControls(
            onHelp: () {},
            onAddState: () {},
            onFitToContent: () {},
            onResetView: () {},
            onUndo: () => undoCount++,
            canUndo: true,
            onRedo: () => redoCount++,
            canRedo: true,
          ),
        ),
      ),
    );

    await tester.tap(find.byTooltip('Undo'));
    await tester.pump();
    await tester.tap(find.byTooltip('Redo'));
    await tester.pump();

    expect(undoCount, equals(1));
    expect(redoCount, equals(1));
  });

  testWidgets('shows canvas tool toggles when enabled', (tester) async {
    var addStateInvoked = false;
    var transitionInvoked = false;

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: MobileAutomatonControls(
            onHelp: () {},
            enableToolSelection: true,
            activeTool: AutomatonCanvasTool.addState,
            onAddState: () => addStateInvoked = true,
            onAddTransition: () => transitionInvoked = true,
            onFitToContent: () {},
            onResetView: () {},
          ),
        ),
      ),
    );

    expect(find.byTooltip('Select'), findsNothing);
    expect(find.byIcon(Icons.arrow_right_alt), findsOneWidget);

    await tester.tap(find.byTooltip('Add state'));
    await tester.pump();
    await tester.tap(find.byIcon(Icons.arrow_right_alt));
    await tester.pump();

    expect(addStateInvoked, isTrue);
    expect(transitionInvoked, isTrue);
  });

  testWidgets('localizes mobile canvas actions in Portuguese', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        locale: const Locale('pt'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(
          body: MobileAutomatonControls(
            enableToolSelection: true,
            showSelectionTool: true,
            onSelectTool: () {},
            onHelp: () {},
            onAddState: () {},
            onAddTransition: () {},
            onZoomIn: () {},
            onZoomOut: () {},
            onFitToContent: () {},
            onResetView: () {},
            onClear: () {},
            onUndo: () {},
            onRedo: () {},
          ),
        ),
      ),
    );

    for (final tooltip in <String>[
      'Ajuda',
      'Desfazer',
      'Refazer',
      'Selecionar',
      'Adicionar estado',
      'Adicionar transição',
      'Diminuir zoom',
      'Aumentar zoom',
      'Ajustar ao conteúdo',
      'Redefinir visualização',
      'Limpar canvas',
    ]) {
      expect(find.byTooltip(tooltip), findsOneWidget);
    }
  });
}
