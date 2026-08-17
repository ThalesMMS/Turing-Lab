//
//  pda_canvas_graphview_test.dart
//  Turing Lab
//
//  Suite de testes de widget dedicada ao PDACanvasGraphView, certificando que o
//  controlador GraphView de autômatos de pilha sincronize estados, transições e
//  callbacks com o provider durante interações de edição. Os cenários incluem
//  criação incremental de nós, atualização de transições com símbolos de pilha e
//  descarte correto de recursos após cada execução.
//
//  Thales Matheus Mendonça Santos - October 2025
//
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:turing_lab/core/constants/automaton_canvas_constants.dart';
import 'package:turing_lab/presentation/providers/pda_editor_provider.dart';
import 'package:turing_lab/presentation/widgets/automaton_canvas_tool.dart';
import 'package:turing_lab/presentation/widgets/pda_canvas_graphview.dart';
import 'package:turing_lab/presentation/widgets/pda/stack_drawer.dart';
import 'package:turing_lab/presentation/widgets/pda/stack_operation_preview.dart';
import 'package:turing_lab/presentation/widgets/transition_editors/pda_transition_editor.dart';
import 'package:turing_lab/features/canvas/graphview/graphview_pda_canvas_controller.dart';

Future<void> _pumpPdaCanvas(
  WidgetTester tester, {
  required PDAEditorNotifier notifier,
  required GraphViewPdaCanvasController controller,
  AutomatonCanvasToolController? toolController,
  StackState? currentStack,
  ValueChanged<int>? onModified,
  Size? viewSize,
}) async {
  if (viewSize != null) {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = viewSize;
    addTearDown(tester.view.resetDevicePixelRatio);
    addTearDown(tester.view.resetPhysicalSize);
  }
  await tester.pumpWidget(
    ProviderScope(
      overrides: [pdaEditorProvider.overrideWith((ref) => notifier)],
      child: MaterialApp(
        theme: ThemeData(splashFactory: NoSplash.splashFactory),
        home: Scaffold(
          body: PDACanvasGraphView(
            controller: controller,
            toolController: toolController,
            currentStack: currentStack,
            onPdaModified: (pda) => onModified?.call(pda.states.length),
          ),
        ),
      ),
    ),
  );
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('PDACanvasGraphView', () {
    late PDAEditorNotifier notifier;
    late GraphViewPdaCanvasController controller;

    setUp(() {
      notifier = PDAEditorNotifier();
      controller = GraphViewPdaCanvasController(editorNotifier: notifier);
    });

    tearDown(() {
      controller.dispose();
    });

    testWidgets('renders states and transitions from controller', (
      tester,
    ) async {
      final delivered = <int>[];

      await _pumpPdaCanvas(
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
      expect(delivered, isEmpty);

      controller.addStateAt(const Offset(0, 0));
      await tester.pumpAndSettle();

      expect(find.text('q0'), findsOneWidget);
      expect(delivered, isNotEmpty);

      controller.addStateAt(const Offset(120, 80));
      await tester.pumpAndSettle();

      final states = notifier.state.pda!.states.toList();
      controller.addOrUpdateTransition(
        fromStateId: states.first.id,
        toStateId: states.last.id,
        readSymbol: 'a',
        popSymbol: 'Z',
        pushSymbol: 'AZ',
        isLambdaInput: false,
        isLambdaPop: false,
        isLambdaPush: false,
      );

      await tester.pumpAndSettle();

      // Transition labels are painted via CustomPainter, not rendered as
      // Text widgets. Verify the transition was added to the model instead.
      final transitions = notifier.state.pda!.transitions;
      expect(transitions, hasLength(1));
    });

    testWidgets('commits a beyond-slop touch drag to PDA editor state', (
      tester,
    ) async {
      await _pumpPdaCanvas(
        tester,
        notifier: notifier,
        controller: controller,
      );

      controller.addStateAt(const Offset(40, 40));
      await tester.pumpAndSettle();
      final initialState = notifier.state.pda!.states.single;
      final initialX = initialState.position.x;

      final gesture = await tester.startGesture(
        tester.getCenter(find.text('q0')),
        kind: PointerDeviceKind.touch,
      );
      await gesture.moveBy(const Offset(24, 0));
      await tester.pump();
      await gesture.up();
      await tester.pumpAndSettle();

      final movedState = notifier.state.pda!.states.single;
      expect(movedState.id, initialState.id);
      expect(movedState.position.x, greaterThan(initialX));
    });

    testWidgets('deletes the selected existing PDA transition', (tester) async {
      final toolController = AutomatonCanvasToolController(
        AutomatonCanvasTool.transition,
      );
      addTearDown(toolController.dispose);

      await _pumpPdaCanvas(
        tester,
        notifier: notifier,
        controller: controller,
        toolController: toolController,
      );

      controller.addStateAt(const Offset(0, 0));
      controller.addStateAt(const Offset(120, 80));
      await tester.pumpAndSettle();

      final states = notifier.state.pda!.states.toList();
      const transitionId = 'pda-transition';
      controller.addOrUpdateTransition(
        fromStateId: states.first.id,
        toStateId: states.last.id,
        readSymbol: 'a',
        popSymbol: 'Z',
        pushSymbol: 'AZ',
        isLambdaInput: false,
        isLambdaPop: false,
        isLambdaPush: false,
        transitionId: transitionId,
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('q0'), warnIfMissed: false);
      await tester.pump();
      await tester.tap(find.text('q1'), warnIfMissed: false);
      await tester.pumpAndSettle();

      final existingTransition = find.byKey(
        const ValueKey('automaton-transition-choice-pda-transition'),
      );
      expect(existingTransition, findsOneWidget);
      await tester.tap(existingTransition);
      await tester.pumpAndSettle();

      expect(find.text('Delete'), findsOneWidget);
      await tester.tap(find.text('Delete'));
      await tester.pumpAndSettle();

      expect(notifier.state.pda!.pdaTransitions, isEmpty);
    });

    testWidgets('editing a PDA transition preserves atomic push symbols', (
      tester,
    ) async {
      final toolController = AutomatonCanvasToolController(
        AutomatonCanvasTool.transition,
      );
      addTearDown(toolController.dispose);

      await _pumpPdaCanvas(
        tester,
        notifier: notifier,
        controller: controller,
        toolController: toolController,
      );

      controller.addStateAt(const Offset(100, 100));
      controller.addStateAt(const Offset(300, 100));
      await tester.pumpAndSettle();
      final states = notifier.state.pda!.states.toList();
      controller.addOrUpdateTransition(
        fromStateId: states.first.id,
        toStateId: states.last.id,
        readSymbol: 'a',
        popSymbol: 'Z',
        pushSymbol: 'S_0Z',
        pushSymbols: const ['S_0', 'Z'],
        isLambdaInput: false,
        isLambdaPop: false,
        isLambdaPush: false,
        transitionId: 'atomic-push-transition',
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('q0'), warnIfMissed: false);
      await tester.pump();
      await tester.tap(find.text('q1'), warnIfMissed: false);
      await tester.pumpAndSettle();
      await tester.tap(
        find.byKey(
          const ValueKey(
            'automaton-transition-choice-atomic-push-transition',
          ),
        ),
      );
      await tester.pumpAndSettle();

      await tester.enterText(find.widgetWithText(TextField, 'a'), 'b');
      await tester.tap(find.text('Save'));
      await tester.pumpAndSettle();

      final transition = notifier.state.pda!.pdaTransitions.single;
      expect(transition.inputSymbol, 'b');
      expect(transition.pushSymbol, 'S_0Z');
      expect(transition.pushSymbols, ['S_0', 'Z']);
      expect(notifier.state.pda!.validate(), isEmpty);
    });

    testWidgets('shows the current stack in the PDA transition editor', (
      tester,
    ) async {
      final toolController = AutomatonCanvasToolController(
        AutomatonCanvasTool.transition,
      );
      addTearDown(toolController.dispose);

      await _pumpPdaCanvas(
        tester,
        notifier: notifier,
        controller: controller,
        toolController: toolController,
        currentStack: const StackState(symbols: ['Z']),
      );

      controller.addStateAt(const Offset(100, 100));
      controller.addStateAt(const Offset(300, 100));
      await tester.pumpAndSettle();
      final states = notifier.state.pda!.states.toList();
      controller.addOrUpdateTransition(
        fromStateId: states.first.id,
        toStateId: states.last.id,
        readSymbol: 'a',
        popSymbol: 'Z',
        pushSymbol: 'AZ',
        isLambdaInput: false,
        isLambdaPop: false,
        isLambdaPush: false,
        transitionId: 'preview-transition',
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('q0'), warnIfMissed: false);
      await tester.pump();
      await tester.tap(find.text('q1'), warnIfMissed: false);
      await tester.pumpAndSettle();
      await tester.tap(
        find.byKey(
          const ValueKey('automaton-transition-choice-preview-transition'),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byType(StackOperationPreview), findsOneWidget);
      expect(find.text('Operation Preview'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('new PDA transition defaults to a valid lambda operation', (
      tester,
    ) async {
      final toolController = AutomatonCanvasToolController(
        AutomatonCanvasTool.transition,
      );
      addTearDown(toolController.dispose);

      await _pumpPdaCanvas(
        tester,
        notifier: notifier,
        controller: controller,
        toolController: toolController,
      );

      controller.addStateAt(const Offset(100, 100));
      controller.addStateAt(const Offset(300, 100));
      await tester.pumpAndSettle();

      await tester.tap(find.text('q0'), warnIfMissed: false);
      await tester.pump();
      await tester.tap(find.text('q1'), warnIfMissed: false);
      await tester.pumpAndSettle();

      final lambdaSwitches = tester.widgetList<SwitchListTile>(
        find.byType(SwitchListTile),
      );
      expect(lambdaSwitches, hasLength(3));
      expect(lambdaSwitches.every((toggle) => toggle.value), isTrue);

      await tester.tap(find.text('Save'));
      await tester.pumpAndSettle();

      final transition = notifier.state.pda!.pdaTransitions.single;
      expect(transition.isLambdaInput, isTrue);
      expect(transition.isLambdaPop, isTrue);
      expect(transition.isLambdaPush, isTrue);
      expect(transition.label, 'λ, λ/λ');
      expect(transition.validate(), isEmpty);
    });

    testWidgets('outside tap dismisses PDA editor without editing canvas', (
      tester,
    ) async {
      final toolController = AutomatonCanvasToolController(
        AutomatonCanvasTool.transition,
      );
      addTearDown(toolController.dispose);

      await _pumpPdaCanvas(
        tester,
        notifier: notifier,
        controller: controller,
        toolController: toolController,
      );

      controller.addStateAt(const Offset(200, 200));
      controller.addStateAt(const Offset(320, 200));
      await tester.pumpAndSettle();
      final states = notifier.state.pda!.states.toList();
      controller.addOrUpdateTransition(
        fromStateId: states.first.id,
        toStateId: states.last.id,
        readSymbol: 'a',
        popSymbol: 'Z',
        pushSymbol: 'AZ',
        isLambdaInput: false,
        isLambdaPop: false,
        isLambdaPush: false,
        transitionId: 'dismiss-pda-transition',
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('q0'), warnIfMissed: false);
      await tester.pump();
      await tester.tap(find.text('q1'), warnIfMissed: false);
      await tester.pumpAndSettle();
      await tester.tap(
        find.byKey(
          const ValueKey(
            'automaton-transition-choice-dismiss-pda-transition',
          ),
        ),
      );
      await tester.pumpAndSettle();
      final positionsBefore = [
        for (final state in notifier.state.pda!.states)
          Offset(state.position.x, state.position.y),
      ];

      await tester.tapAt(const Offset(16, 16));
      await tester.pumpAndSettle();

      expect(find.byType(PdaTransitionEditor), findsNothing);
      expect(
        [
          for (final state in notifier.state.pda!.states)
            Offset(state.position.x, state.position.y),
        ],
        positionsBefore,
      );
    });

    testWidgets('keeps PDA transition actions inside a narrow canvas', (
      tester,
    ) async {
      final toolController = AutomatonCanvasToolController(
        AutomatonCanvasTool.transition,
      );
      addTearDown(toolController.dispose);

      await _pumpPdaCanvas(
        tester,
        notifier: notifier,
        controller: controller,
        toolController: toolController,
        viewSize: const Size(320, 700),
      );

      controller.addStateAt(const Offset(100, 350));
      controller.addStateAt(const Offset(220, 350));
      await tester.pumpAndSettle();

      final states = notifier.state.pda!.states.toList();
      controller.addOrUpdateTransition(
        fromStateId: states.first.id,
        toStateId: states.last.id,
        readSymbol: 'a',
        popSymbol: 'Z',
        pushSymbol: 'AZ',
        isLambdaInput: false,
        isLambdaPop: false,
        isLambdaPush: false,
        transitionId: 'narrow-pda-transition',
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('q0'), warnIfMissed: false);
      await tester.pump();
      await tester.tap(find.text('q1'), warnIfMissed: false);
      await tester.pumpAndSettle();
      await tester.tap(
        find.byKey(
          const ValueKey('automaton-transition-choice-narrow-pda-transition'),
        ),
      );
      await tester.pumpAndSettle();

      final editor = find.byType(PdaTransitionEditor);
      final editorBounds = tester.getRect(editor);
      expect(editorBounds.width, 296);
      expect(editorBounds.left, greaterThanOrEqualTo(12));
      expect(editorBounds.right, lessThanOrEqualTo(308));

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
    });
  });
}
