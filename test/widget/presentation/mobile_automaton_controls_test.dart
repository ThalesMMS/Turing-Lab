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

import 'package:turing_lab/presentation/widgets/mobile_automaton_controls.dart';
import 'package:turing_lab/presentation/widgets/automaton_canvas_tool.dart';

void main() {
  testWidgets('MobileAutomatonControls surfaces canvas and workspace actions', (
    tester,
  ) async {
    var simulateInvoked = false;
    var algorithmInvoked = false;
    var metricsInvoked = false;
    var addStateInvoked = false;
    var clearInvoked = false;

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: MobileAutomatonControls(
            onAddState: () => addStateInvoked = true,
            onFitToContent: () {},
            onResetView: () {},
            onClear: () => clearInvoked = true,
            onSimulate: () => simulateInvoked = true,
            onAlgorithms: () => algorithmInvoked = true,
            onMetrics: () => metricsInvoked = true,
            statusMessage: '3 states · 2 transitions',
          ),
        ),
      ),
    );

    expect(find.byTooltip('Simulate'), findsOneWidget);
    expect(find.byTooltip('Algorithms'), findsOneWidget);
    expect(find.byTooltip('Metrics'), findsOneWidget);
    expect(find.byTooltip('Add state'), findsOneWidget);
    expect(find.byTooltip('Clear canvas'), findsOneWidget);
    expect(find.text('3 states · 2 transitions'), findsOneWidget);

    await tester.tap(find.byTooltip('Simulate'));
    await tester.pump();
    await tester.tap(find.byTooltip('Algorithms'));
    await tester.pump();
    await tester.tap(find.byTooltip('Metrics'));
    await tester.pump();
    await tester.tap(find.byTooltip('Add state'));
    await tester.pump();
    await tester.tap(find.byTooltip('Clear canvas'));
    await tester.pump();

    expect(simulateInvoked, isTrue);
    expect(algorithmInvoked, isTrue);
    expect(metricsInvoked, isTrue);
    expect(addStateInvoked, isTrue);
    expect(clearInvoked, isTrue);
  });

  testWidgets('disables optional actions when flags are false', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: MobileAutomatonControls(
            onAddState: () {},
            onFitToContent: () {},
            onResetView: () {},
            onSimulate: () {},
            isSimulationEnabled: false,
            onAlgorithms: () {},
            isAlgorithmsEnabled: false,
          ),
        ),
      ),
    );

    final simulateButton = tester.widget<IconButton>(
      find.descendant(
        of: find.byTooltip('Simulate'),
        matching: find.byType(IconButton),
      ),
    );
    final algorithmButton = tester.widget<IconButton>(
      find.descendant(
        of: find.byTooltip('Algorithms'),
        matching: find.byType(IconButton),
      ),
    );

    expect(simulateButton.onPressed, isNull);
    expect(algorithmButton.onPressed, isNull);
    expect(find.byTooltip('Metrics'), findsNothing);
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
}
