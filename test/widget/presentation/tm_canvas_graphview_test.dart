//
//  tm_canvas_graphview_test.dart
//  Turing Lab
//
//  Bateria de testes de widget que verifica o TMCanvasGraphView, assegurando
//  que o controlador GraphView de máquinas de Turing sincronize estados e
//  transições com o provider Riverpod durante interações típicas de edição.
//  As verificações incluem criação dinâmica de nós, adição de transições e
//  descarte apropriado do controlador ao término de cada cenário.
//
//  Thales Matheus Mendonça Santos - October 2025
//
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:turing_lab/core/constants/automaton_canvas_constants.dart';
import 'package:turing_lab/core/models/tm_transition.dart';
import 'package:turing_lab/features/canvas/graphview/graphview_tm_canvas_controller.dart';
import 'package:turing_lab/features/canvas/graphview/turing_lab_adaptive_edge_renderer.dart';
import 'package:turing_lab/presentation/providers/tm_editor_provider.dart';
import 'package:turing_lab/presentation/widgets/automaton_canvas_tool.dart';
import 'package:turing_lab/presentation/widgets/automaton_graphview_canvas.dart';
import 'package:turing_lab/presentation/widgets/tm_canvas_graphview.dart';
import 'package:turing_lab/presentation/widgets/transition_editors/tm_transition_operations_editor.dart';

Future<void> _pumpTmCanvas(
  WidgetTester tester, {
  required TMEditorNotifier notifier,
  required GraphViewTmCanvasController controller,
  AutomatonCanvasToolController? toolController,
  ValueChanged<int>? onModified,
  Size? viewSize,
  ThemeData? theme,
}) async {
  if (viewSize != null) {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = viewSize;
    addTearDown(tester.view.resetDevicePixelRatio);
    addTearDown(tester.view.resetPhysicalSize);
  }
  await tester.pumpWidget(
    ProviderScope(
      overrides: [tmEditorProvider.overrideWith((ref) => notifier)],
      child: MaterialApp(
        theme: theme ?? ThemeData(splashFactory: NoSplash.splashFactory),
        home: Scaffold(
          body: TMCanvasGraphView(
            controller: controller,
            toolController: toolController,
            onTmModified: (tm) => onModified?.call(tm.states.length),
          ),
        ),
      ),
    ),
  );
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('TMCanvasGraphView', () {
    late TMEditorNotifier notifier;
    late GraphViewTmCanvasController controller;

    setUp(() {
      notifier = TMEditorNotifier();
      controller = GraphViewTmCanvasController(editorNotifier: notifier);
    });

    tearDown(() {
      controller.dispose();
    });

    testWidgets('displays TM states and transitions', (tester) async {
      final delivered = <int>[];

      await _pumpTmCanvas(
        tester,
        notifier: notifier,
        controller: controller,
        onModified: delivered.add,
      );

      await tester.pump();
      expect(
        tester
            .widget<InteractiveViewer>(find.byType(InteractiveViewer))
            .maxScale,
        kAutomatonCanvasMaxScale,
      );
      expect(
        tester
            .widget<InteractiveViewer>(find.byType(InteractiveViewer))
            .minScale,
        kAutomatonCanvasMinScale,
      );

      controller.addStateAt(const Offset(0, 0));
      controller.addStateAt(const Offset(140, 80));
      await tester.pumpAndSettle();

      expect(find.text('q0'), findsOneWidget);
      expect(find.text('q1'), findsOneWidget);

      final states = notifier.state.tm!.states.toList();
      controller.addOrUpdateTransition(
        fromStateId: states.first.id,
        toStateId: states.last.id,
        readSymbol: 'a',
        writeSymbol: 'b',
        direction: TapeDirection.right,
      );

      await tester.pumpAndSettle();

      // Transition labels are painted via CustomPainter, not rendered as
      // Text widgets. Verify the transition was added to the model instead.
      final transitions = notifier.state.tm!.transitions;
      expect(transitions, hasLength(1));
      expect(delivered, isNotEmpty);
    });

    testWidgets('groups TM self-loops into one path with a shared label card', (
      tester,
    ) async {
      await _pumpTmCanvas(
        tester,
        notifier: notifier,
        controller: controller,
      );

      controller.addStateAt(const Offset(160, 160));
      await tester.pumpAndSettle();
      final state = notifier.state.tm!.states.single;
      controller.addOrUpdateTransition(
        fromStateId: state.id,
        toStateId: state.id,
        readSymbol: 'a',
        writeSymbol: 'a',
        direction: TapeDirection.right,
        transitionId: 'tm-loop-a',
        controlPointX: 160,
        controlPointY: 40,
      );
      controller.addOrUpdateTransition(
        fromStateId: state.id,
        toStateId: state.id,
        readSymbol: 'Y',
        writeSymbol: 'Y',
        direction: TapeDirection.right,
        transitionId: 'tm-loop-y',
        controlPointX: 160,
        controlPointY: 40,
      );
      await tester.pumpAndSettle();

      final dynamic canvasState = tester.state(
        find.byType(AutomatonGraphViewCanvas),
      );
      final firstLoop = canvasState.debugGeometryForTransition('tm-loop-a')
          as TuringLabEdgeRenderGeometry;
      final secondLoop = canvasState.debugGeometryForTransition('tm-loop-y')
          as TuringLabEdgeRenderGeometry;

      expect(
          identical(firstLoop.pathGeometry, secondLoop.pathGeometry), isTrue);
      expect(firstLoop.labelRect, isNotNull);
      expect(firstLoop.labelRect, secondLoop.labelRect);
    });

    testWidgets('updates a TM route before committing its dragged state', (
      tester,
    ) async {
      await _pumpTmCanvas(
        tester,
        notifier: notifier,
        controller: controller,
      );

      controller.addStateAt(const Offset(40, 40));
      controller.addStateAt(const Offset(260, 40));
      await tester.pumpAndSettle();
      final states = notifier.state.tm!.states.toList();
      final initialState = states.first;
      const transitionId = 'tm-live-drag-transition';
      controller.addOrUpdateTransition(
        fromStateId: initialState.id,
        toStateId: states.last.id,
        readSymbol: 'a',
        writeSymbol: 'b',
        direction: TapeDirection.right,
        transitionId: transitionId,
      );
      await tester.pumpAndSettle();
      final originalPosition = Offset(
        initialState.position.x,
        initialState.position.y,
      );
      final dynamic canvasState = tester.state(
        find.byType(AutomatonGraphViewCanvas),
      );
      final routeBefore = (canvasState.debugGeometryForTransition(transitionId)
              as TuringLabEdgeRenderGeometry)
          .pathGeometry
          .pointAt(0.5);

      final gesture = await tester.startGesture(
        tester.getCenter(find.text('q0')),
        kind: PointerDeviceKind.touch,
      );
      await gesture.moveBy(const Offset(60, 45));
      await tester.pump();
      final routeDuring = (canvasState.debugGeometryForTransition(transitionId)
              as TuringLabEdgeRenderGeometry)
          .pathGeometry
          .pointAt(0.5);
      final domainDuring = notifier.state.tm!.states.firstWhere(
        (state) => state.id == initialState.id,
      );

      expect((routeDuring - routeBefore).distance, greaterThan(20));
      expect(
        Offset(domainDuring.position.x, domainDuring.position.y),
        originalPosition,
      );

      await gesture.up();
      await tester.pumpAndSettle();

      final movedState = notifier.state.tm!.states.firstWhere(
        (state) => state.id == initialState.id,
      );
      expect(movedState.id, initialState.id);
      expect(
        Offset(movedState.position.x, movedState.position.y),
        isNot(originalPosition),
      );
    });

    testWidgets('deletes the selected existing TM transition', (tester) async {
      final toolController = AutomatonCanvasToolController(
        AutomatonCanvasTool.transition,
      );
      addTearDown(toolController.dispose);

      await _pumpTmCanvas(
        tester,
        notifier: notifier,
        controller: controller,
        toolController: toolController,
      );

      controller.addStateAt(const Offset(0, 0));
      controller.addStateAt(const Offset(140, 80));
      await tester.pumpAndSettle();

      final states = notifier.state.tm!.states.toList();
      const transitionId = 'tm-transition';
      controller.addOrUpdateTransition(
        fromStateId: states.first.id,
        toStateId: states.last.id,
        readSymbol: 'a',
        writeSymbol: 'b',
        direction: TapeDirection.right,
        transitionId: transitionId,
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('q0'), warnIfMissed: false);
      await tester.pump();
      await tester.tap(find.text('q1'), warnIfMissed: false);
      await tester.pumpAndSettle();

      final existingTransition = find.byKey(
        const ValueKey('automaton-transition-choice-tm-transition'),
      );
      expect(existingTransition, findsOneWidget);
      await tester.tap(existingTransition);
      await tester.pumpAndSettle();

      expect(find.text('Delete'), findsOneWidget);
      await tester.tap(find.text('Delete'));
      await tester.pumpAndSettle();

      expect(notifier.state.tm!.tmTransitions, isEmpty);
    });

    testWidgets('outside tap dismisses TM editor without editing canvas', (
      tester,
    ) async {
      final toolController = AutomatonCanvasToolController(
        AutomatonCanvasTool.transition,
      );
      addTearDown(toolController.dispose);

      await _pumpTmCanvas(
        tester,
        notifier: notifier,
        controller: controller,
        toolController: toolController,
      );

      controller.addStateAt(const Offset(200, 200));
      controller.addStateAt(const Offset(320, 200));
      await tester.pumpAndSettle();
      final states = notifier.state.tm!.states.toList();
      controller.addOrUpdateTransition(
        fromStateId: states.first.id,
        toStateId: states.last.id,
        readSymbol: 'a',
        writeSymbol: 'b',
        direction: TapeDirection.right,
        transitionId: 'dismiss-tm-transition',
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('q0'), warnIfMissed: false);
      await tester.pump();
      await tester.tap(find.text('q1'), warnIfMissed: false);
      await tester.pumpAndSettle();
      await tester.tap(
        find.byKey(
          const ValueKey('automaton-transition-choice-dismiss-tm-transition'),
        ),
      );
      await tester.pumpAndSettle();
      final positionsBefore = [
        for (final state in notifier.state.tm!.states)
          Offset(state.position.x, state.position.y),
      ];

      await tester.tapAt(const Offset(16, 16));
      await tester.pumpAndSettle();

      expect(find.byType(TmTransitionOperationsEditor), findsNothing);
      expect(
        [
          for (final state in notifier.state.tm!.states)
            Offset(state.position.x, state.position.y),
        ],
        positionsBefore,
      );
    });

    testWidgets('keeps TM transition actions inside a narrow canvas', (
      tester,
    ) async {
      final toolController = AutomatonCanvasToolController(
        AutomatonCanvasTool.transition,
      );
      addTearDown(toolController.dispose);

      await _pumpTmCanvas(
        tester,
        notifier: notifier,
        controller: controller,
        toolController: toolController,
        viewSize: const Size(320, 700),
      );

      controller.addStateAt(const Offset(100, 350));
      controller.addStateAt(const Offset(220, 350));
      await tester.pumpAndSettle();

      final states = notifier.state.tm!.states.toList();
      controller.addOrUpdateTransition(
        fromStateId: states.first.id,
        toStateId: states.last.id,
        readSymbol: 'a',
        writeSymbol: 'b',
        direction: TapeDirection.right,
        transitionId: 'narrow-transition',
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('q0'), warnIfMissed: false);
      await tester.pump();
      await tester.tap(find.text('q1'), warnIfMissed: false);
      await tester.pumpAndSettle();
      await tester.tap(
        find.byKey(
          const ValueKey('automaton-transition-choice-narrow-transition'),
        ),
      );
      await tester.pumpAndSettle();

      expect(
        tester.getSize(find.byType(TmTransitionOperationsEditor)).width,
        296,
      );
      final actionButtons = [
        find.widgetWithText(OutlinedButton, 'Cancel'),
        find.widgetWithText(OutlinedButton, 'Delete'),
        find.widgetWithText(FilledButton, 'Save'),
      ];
      for (final button in actionButtons) {
        expect(button, findsOneWidget);
        final bounds = tester.getRect(button);
        expect(bounds.left, greaterThanOrEqualTo(12));
        expect(bounds.right, lessThanOrEqualTo(308));
        expect(bounds.height, greaterThanOrEqualTo(48));
      }
      final cancelBounds = tester.getRect(actionButtons[0]);
      final deleteBounds = tester.getRect(actionButtons[1]);
      final saveBounds = tester.getRect(actionButtons[2]);
      expect(cancelBounds.bottom, lessThan(deleteBounds.top));
      expect(deleteBounds.bottom, lessThan(saveBounds.top));
    });

    testWidgets('recenters an open TM transition editor after resize', (
      tester,
    ) async {
      final toolController = AutomatonCanvasToolController(
        AutomatonCanvasTool.transition,
      );
      addTearDown(toolController.dispose);

      await _pumpTmCanvas(
        tester,
        notifier: notifier,
        controller: controller,
        toolController: toolController,
        viewSize: const Size(800, 1000),
        theme: ThemeData(splashFactory: NoSplash.splashFactory),
      );

      controller.addStateAt(const Offset(340, 700));
      controller.addStateAt(const Offset(460, 700));
      await tester.pumpAndSettle();

      final states = notifier.state.tm!.states.toList();
      controller.addOrUpdateTransition(
        fromStateId: states.first.id,
        toStateId: states.last.id,
        readSymbol: 'a',
        writeSymbol: 'b',
        direction: TapeDirection.right,
        transitionId: 'resized-transition',
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('q0'), warnIfMissed: false);
      await tester.pump();
      await tester.tap(find.text('q1'), warnIfMissed: false);
      await tester.pumpAndSettle();
      await tester.tap(
        find.byKey(
          const ValueKey('automaton-transition-choice-resized-transition'),
        ),
      );
      await tester.pumpAndSettle();

      final editor = find.byType(TmTransitionOperationsEditor);
      expect(tester.getSize(editor).width, 360);

      tester.view.physicalSize = const Size(320, 1000);
      await tester.pumpAndSettle();

      final editorBounds = tester.getRect(editor);
      expect(editorBounds.width, 296);
      final actionButtons = [
        find.widgetWithText(OutlinedButton, 'Cancel'),
        find.widgetWithText(OutlinedButton, 'Delete'),
        find.widgetWithText(FilledButton, 'Save'),
      ];
      for (final button in actionButtons) {
        expect(button, findsOneWidget);
        final bounds = tester.getRect(button);
        expect(bounds.left, greaterThanOrEqualTo(12));
        expect(bounds.right, lessThanOrEqualTo(308));
        expect(bounds.height, greaterThanOrEqualTo(48));
      }
      expect(editorBounds.left, greaterThanOrEqualTo(12));
      expect(editorBounds.right, lessThanOrEqualTo(308));

      final compactHeight = editorBounds.height + 48;
      tester.view.physicalSize = Size(320, compactHeight);
      await tester.pumpAndSettle();

      final verticallyClampedBounds = tester.getRect(editor);
      expect(verticallyClampedBounds.top, greaterThanOrEqualTo(12));
      expect(
        verticallyClampedBounds.bottom,
        lessThanOrEqualTo(compactHeight - 12),
      );
    });
  });
}
