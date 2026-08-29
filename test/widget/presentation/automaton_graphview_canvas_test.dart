//
//  automaton_graphview_canvas_test.dart
//  Turing Lab
//
//  Comprehensive suite covering AutomatonGraphViewCanvas, including
//  integration with stub providers, a custom controller, and a layout
//  repository under gesture-driven interaction. The tests validate adding
//  and moving states, inline transition editing, and unsupported-layout
//  responses, keeping the UI in sync with automaton state.
//
//  Thales Matheus Mendonça Santos - October 2025
//

import 'dart:math' as math;
import 'dart:ui' show SemanticsFlag;

import 'package:flutter/foundation.dart'
    show debugDefaultTargetPlatformOverride;
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:graphview/graphview_turing_lab.dart';
import 'package:vector_math/vector_math_64.dart';

import 'package:turing_lab/core/models/fsa.dart';
import 'package:turing_lab/core/annotations/annotations.dart';
import 'package:turing_lab/core/formal_systems/formal_systems.dart';
import 'package:turing_lab/core/graph_layout/graph_layout.dart';
import 'package:turing_lab/core/models/fsa_transition.dart';
import 'package:turing_lab/core/models/simulation_highlight.dart';
import 'package:turing_lab/core/models/simulation_step.dart';
import 'package:turing_lab/core/models/state.dart' as automaton_state;
import 'package:turing_lab/core/services/simulation_highlight_service.dart';
import 'package:turing_lab/features/canvas/graphview/graphview_canvas_controller.dart';
import 'package:turing_lab/features/canvas/graphview/graphview_canvas_models.dart';
import 'package:turing_lab/features/canvas/graphview/graphview_highlight_channel.dart';
import 'package:turing_lab/features/canvas/graphview/graphview_label_field_editor.dart';
import 'package:turing_lab/features/canvas/graphview/graphview_link_overlay_utils.dart';
import 'package:turing_lab/features/canvas/graphview/turing_lab_adaptive_edge_renderer.dart';
import 'package:turing_lab/l10n/app_localizations.dart';
import 'package:turing_lab/presentation/providers/automaton_state_provider.dart';
import 'package:turing_lab/presentation/providers/document_annotations_provider.dart';
import 'package:turing_lab/presentation/widgets/automaton_canvas_document_actions.dart';
import 'package:turing_lab/presentation/widgets/automaton_canvas_tool.dart';
import 'package:turing_lab/presentation/widgets/automaton_graphview_canvas.dart';
import 'package:turing_lab/presentation/widgets/graphview_canvas_toolbar.dart';

class _RecordingAutomatonStateNotifier extends AutomatonStateNotifier {
  _RecordingAutomatonStateNotifier() : super();

  final List<Map<String, Object?>> transitionCalls = [];
  final List<String> removedTransitionIds = [];

  @override
  void addOrUpdateTransition({
    required String id,
    required String fromStateId,
    required String toStateId,
    required String label,
    double? controlPointX,
    double? controlPointY,
  }) {
    transitionCalls.add({
      'id': id,
      'fromStateId': fromStateId,
      'toStateId': toStateId,
      'label': label,
      'controlPointX': controlPointX,
      'controlPointY': controlPointY,
    });
    super.addOrUpdateTransition(
      id: id,
      fromStateId: fromStateId,
      toStateId: toStateId,
      label: label,
      controlPointX: controlPointX,
      controlPointY: controlPointY,
    );
  }

  @override
  void removeTransition({required String id}) {
    removedTransitionIds.add(id);
    super.removeTransition(id: id);
  }
}

class _RecordingGraphViewCanvasController extends GraphViewCanvasController {
  _RecordingGraphViewCanvasController({required super.automatonStateNotifier});

  final List<FSA?> synchronizedAutomata = [];
  int addStateAtCallCount = 0;
  Offset? lastAddStateWorldOffset;
  int moveStateCallCount = 0;
  int previewStatePositionCallCount = 0;
  String? lastMoveStateId;
  Offset? lastMoveStatePosition;
  Offset? lastPreviewStatePosition;

  @override
  void synchronize(FSA? automaton) {
    synchronizedAutomata.add(automaton);
    super.synchronize(automaton);
  }

  @override
  void addStateAt(Offset worldPosition) {
    addStateAtCallCount++;
    lastAddStateWorldOffset = worldPosition;
  }

  @override
  void moveState(String id, Offset position) {
    moveStateCallCount++;
    lastMoveStateId = id;
    lastMoveStatePosition = position;
  }

  @override
  void previewStatePosition(String id, Offset position) {
    previewStatePositionCallCount++;
    lastPreviewStatePosition = position;
    super.previewStatePosition(id, position);
  }
}

FSA _singleStateAutomaton(String id) {
  final state = automaton_state.State(
    id: 'A',
    label: 'A',
    position: Vector2(40, 40),
    isInitial: true,
  );
  return FSA(
    id: id,
    name: 'Single state',
    states: {state},
    transitions: const <FSATransition>{},
    alphabet: const <String>{'a'},
    initialState: state,
    acceptingStates: <automaton_state.State>{},
    created: DateTime.utc(2024, 1, 1),
    modified: DateTime.utc(2024, 1, 1),
    bounds: const math.Rectangle<double>(0, 0, 400, 300),
    zoomLevel: 1,
    panOffset: Vector2.zero(),
  );
}

Future<Offset> _pumpSingleStateCanvas(
  WidgetTester tester, {
  required FSA automaton,
  required _RecordingAutomatonStateNotifier provider,
  required _RecordingGraphViewCanvasController controller,
  required AutomatonCanvasToolController toolController,
  Locale locale = const Locale('en'),
}) async {
  provider.updateAutomaton(automaton);
  controller.synchronize(automaton);
  await tester.pumpWidget(
    MaterialApp(
      theme: ThemeData(splashFactory: NoSplash.splashFactory),
      locale: locale,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: Scaffold(
        body: AutomatonGraphViewCanvas(
          automaton: automaton,
          canvasKey: GlobalKey(),
          controller: controller,
          toolController: toolController,
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
  return tester.getCenter(find.text('A'));
}

Offset _edgePathMidpoint(
  GraphViewCanvasController controller,
  GraphViewCanvasEdge edge,
) {
  final from = controller.nodeById(edge.fromStateId)!;
  final to = controller.nodeById(edge.toStateId)!;
  final start = resolveNodeCenter(from);
  final end = resolveNodeCenter(to);
  final control = resolveLinkAnchorWorld(controller, edge)!;
  return start * 0.25 + control * 0.5 + end * 0.25;
}

TuringLabEdgeRenderGeometry _paintedGeometry(
  WidgetTester tester,
  String transitionId,
) {
  final dynamic state = tester.state(find.byType(AutomatonGraphViewCanvas));
  return state.debugGeometryForTransition(transitionId)
      as TuringLabEdgeRenderGeometry;
}

Offset _worldToViewport(
  GraphViewCanvasController controller,
  Offset worldPosition,
) {
  final transformation =
      controller.graphController.transformationController!.value;
  final vector = transformation.transform3(
    Vector3(worldPosition.dx, worldPosition.dy, 0),
  );
  return Offset(vector.x, vector.y);
}

Color _nodeBackgroundColor(WidgetTester tester, String label) {
  final container = tester.widget<AnimatedContainer>(
    find
        .ancestor(
          of: find.text(label),
          matching: find.byType(AnimatedContainer),
        )
        .first,
  );
  return (container.decoration! as BoxDecoration).color!;
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('AutomatonGraphViewCanvas gestures', () {
    late _RecordingAutomatonStateNotifier provider;
    late _RecordingGraphViewCanvasController controller;
    late AutomatonCanvasToolController toolController;

    setUp(() {
      provider = _RecordingAutomatonStateNotifier();
      controller = _RecordingGraphViewCanvasController(
        automatonStateNotifier: provider,
      );
      toolController = AutomatonCanvasToolController(
        AutomatonCanvasTool.addState,
      );
    });

    tearDown(() {
      controller.dispose();
      toolController.dispose();
    });

    testWidgets(
      'exposes an accessible fragment-import action on editable canvases',
      (tester) async {
        final automaton = _singleStateAutomaton('fragment-destination');
        provider.updateAutomaton(automaton);
        controller.synchronize(automaton);
        final documentActions = AutomatonCanvasDocumentActionsController();
        final semantics = tester.ensureSemantics();
        try {
          await tester.pumpWidget(
            ProviderScope(
              child: MaterialApp(
                home: Scaffold(
                  body: Stack(
                    children: [
                      Positioned.fill(
                        child: AutomatonGraphViewCanvas(
                          automaton: automaton,
                          canvasKey: GlobalKey(),
                          controller: controller,
                          toolController: toolController,
                          documentActionsController: documentActions,
                          annotationConfig:
                              const AutomatonCanvasAnnotationConfig(
                                systemKey: DefaultFormalSystemIds.fsa,
                                documentId: 'fragment-destination',
                                documentRevision: '1',
                              ),
                        ),
                      ),
                      GraphViewCanvasToolbar(
                        controller: controller,
                        onAddState: () {},
                        onImportAutomaton: documentActions.importAutomaton,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          );
          await tester.pumpAndSettle();

          expect(
            find.byKey(const ValueKey('automaton-fragment-import-button')),
            findsNothing,
          );
          await tester.tap(
            find.byKey(const ValueKey('canvas-toolbar-overflow')),
          );
          await tester.pumpAndSettle();
          expect(
            find.byWidgetPredicate(
              (widget) =>
                  widget is Semantics &&
                  widget.properties.label ==
                      'Canvas action: Import automaton' &&
                  widget.properties.hint ==
                      'Previews and combines a compatible automaton with this document.' &&
                  widget.properties.button == true,
            ),
            findsOneWidget,
          );
        } finally {
          semantics.dispose();
        }
      },
    );

    testWidgets('previews, cancels, applies, and undoes a deterministic layout', (
      tester,
    ) async {
      final automaton = _singleStateAutomaton('layout-destination');
      provider.updateAutomaton(automaton);
      controller.synchronize(automaton);
      final documentActions = AutomatonCanvasDocumentActionsController();
      final originalPosition = controller.nodePosition('A');
      final semantics = tester.ensureSemantics();
      try {
        await tester.pumpWidget(
          ProviderScope(
            child: MaterialApp(
              home: Scaffold(
                body: Stack(
                  children: [
                    Positioned.fill(
                      child: AutomatonGraphViewCanvas(
                        automaton: automaton,
                        canvasKey: GlobalKey(),
                        controller: controller,
                        toolController: toolController,
                        documentActionsController: documentActions,
                      ),
                    ),
                    GraphViewCanvasToolbar(
                      controller: controller,
                      onAddState: () {},
                      onArrangeAutomaton: documentActions.arrange,
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();

        expect(
          find.byKey(const ValueKey('automaton-layout-button')),
          findsNothing,
        );
        await tester.tap(find.byKey(const ValueKey('canvas-toolbar-overflow')));
        await tester.pumpAndSettle();
        expect(
          find.byWidgetPredicate(
            (widget) =>
                widget is Semantics &&
                widget.properties.label ==
                    'Canvas action: Arrange automaton states' &&
                widget.properties.hint ==
                    'Previews a layout before applying it to this automaton.' &&
                widget.properties.button == true,
          ),
          findsOneWidget,
        );

        await tester.tap(find.text('Arrange automaton states'));
        await tester.pump();
        await tester.runAsync(
          () => Future<void>.delayed(const Duration(milliseconds: 100)),
        );
        await tester.pump();
        expect(
          find.byKey(const ValueKey('automaton-layout-dialog')),
          findsOneWidget,
        );
        expect(
          tester
              .widget<FilledButton>(
                find.byKey(const ValueKey('layout-apply-button')),
              )
              .onPressed,
          isNotNull,
        );
        expect(controller.nodePosition('A'), isNot(originalPosition));

        await tester.tap(find.byKey(const ValueKey('layout-cancel-button')));
        await tester.pumpAndSettle();
        expect(controller.nodePosition('A'), originalPosition);
        expect(controller.canUndo, isFalse);

        documentActions.arrange();
        await tester.pump();
        await tester.runAsync(
          () => Future<void>.delayed(const Duration(milliseconds: 100)),
        );
        await tester.pump();
        await tester.tap(find.byKey(const ValueKey('layout-apply-button')));
        await tester.pumpAndSettle();

        final arrangedPosition =
            provider.state.currentAutomaton!.states.single.position;
        expect(arrangedPosition, isNot(Vector2(40, 40)));
        expect(controller.canUndo, isTrue);

        documentActions.arrange();
        await tester.pump();
        await tester.runAsync(
          () => Future<void>.delayed(const Duration(milliseconds: 100)),
        );
        await tester.pump();
        tester
            .widget<DropdownButtonFormField<GraphLayoutAlgorithmId>>(
              find.byKey(const ValueKey('layout-algorithm-field')),
            )
            .onChanged!(GraphLayoutAlgorithmId.restore);
        await tester.runAsync(
          () => Future<void>.delayed(const Duration(milliseconds: 100)),
        );
        await tester.pump();
        await tester.tap(find.byKey(const ValueKey('layout-apply-button')));
        await tester.pumpAndSettle();

        expect(
          provider.state.currentAutomaton!.states.single.position,
          Vector2(40, 40),
        );
        expect(controller.undo(), isTrue);
        expect(
          provider.state.currentAutomaton!.states.single.position,
          arrangedPosition,
        );
        expect(controller.undo(), isTrue);
        expect(
          provider.state.currentAutomaton!.states.single.position,
          Vector2(40, 40),
        );
        expect(controller.canUndo, isFalse);
      } finally {
        semantics.dispose();
      }
    });

    testWidgets('affine layout transforms free notes in the same undo entry', (
      tester,
    ) async {
      final automaton = _singleStateAutomaton('layout-annotations');
      provider.updateAutomaton(automaton);
      controller.synchronize(automaton);
      final documentActions = AutomatonCanvasDocumentActionsController();
      final container = ProviderContainer();
      addTearDown(container.dispose);
      final annotations = container.read(documentAnnotationsProvider.notifier);
      annotations.add(
        key: DefaultFormalSystemIds.fsa,
        documentId: automaton.id,
        documentRevision: '1',
        x: 10,
        y: 20,
        text: 'Free note',
      );

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: MaterialApp(
            home: Scaffold(
              body: AutomatonGraphViewCanvas(
                automaton: automaton,
                canvasKey: GlobalKey(),
                controller: controller,
                toolController: toolController,
                documentActionsController: documentActions,
                annotationConfig: AutomatonCanvasAnnotationConfig(
                  systemKey: DefaultFormalSystemIds.fsa,
                  documentId: automaton.id,
                  documentRevision: '1',
                ),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      documentActions.arrange();
      await tester.pump();
      await tester.runAsync(
        () => Future<void>.delayed(const Duration(milliseconds: 100)),
      );
      await tester.pump();
      tester
          .widget<DropdownButtonFormField<GraphLayoutAlgorithmId>>(
            find.byKey(const ValueKey('layout-algorithm-field')),
          )
          .onChanged!(GraphLayoutAlgorithmId.reflectVertical);
      await tester.runAsync(
        () => Future<void>.delayed(const Duration(milliseconds: 100)),
      );
      await tester.pump();

      final transformNotes = find.byKey(
        const ValueKey('layout-transform-free-notes'),
      );
      expect(transformNotes, findsOneWidget);
      await tester.ensureVisible(transformNotes);
      await tester.pump(const Duration(milliseconds: 500));
      await tester.tap(transformNotes);
      await tester.tap(find.byKey(const ValueKey('layout-apply-button')));
      await tester.pumpAndSettle();

      DocumentAnnotation note() => annotationsForDocument(
        container.read(documentAnnotationsProvider),
        DefaultFormalSystemIds.fsa,
        automaton.id,
      )!.annotations.single;

      expect(note().x, closeTo(70, 0.0001));
      expect(note().y, closeTo(20, 0.0001));
      expect(controller.undo(), isTrue);
      expect(note().x, closeTo(10, 0.0001));
      expect(note().y, closeTo(20, 0.0001));
      expect(controller.redo(), isTrue);
      expect(note().x, closeTo(70, 0.0001));
    });

    testWidgets('layout dialog scrolls on a narrow large-text viewport', (
      tester,
    ) async {
      await tester.binding.setSurfaceSize(const Size(320, 700));
      addTearDown(() => tester.binding.setSurfaceSize(null));
      final automaton = _singleStateAutomaton('layout-narrow');
      provider.updateAutomaton(automaton);
      controller.synchronize(automaton);
      final documentActions = AutomatonCanvasDocumentActionsController();

      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            builder: (context, child) => MediaQuery(
              data: MediaQuery.of(
                context,
              ).copyWith(textScaler: const TextScaler.linear(2)),
              child: child!,
            ),
            home: Scaffold(
              body: AutomatonGraphViewCanvas(
                automaton: automaton,
                canvasKey: GlobalKey(),
                controller: controller,
                toolController: toolController,
                documentActionsController: documentActions,
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      documentActions.arrange();
      await tester.pump();
      await tester.runAsync(
        () => Future<void>.delayed(const Duration(milliseconds: 100)),
      );
      await tester.pump(const Duration(milliseconds: 500));

      expect(find.byType(SingleChildScrollView), findsWidgets);
      expect(tester.takeException(), isNull);
      await tester.tap(find.byKey(const ValueKey('layout-cancel-button')));
      await tester.pumpAndSettle();
    });

    testWidgets(
      'delegates taps on empty background to controller when add-state tool is active',
      (tester) async {
        final automaton = FSA(
          id: 'empty',
          name: 'Empty Automaton',
          states: <automaton_state.State>{},
          transitions: const <FSATransition>{},
          alphabet: const <String>{},
          initialState: null,
          acceptingStates: <automaton_state.State>{},
          created: DateTime.utc(2024, 1, 1),
          modified: DateTime.utc(2024, 1, 1),
          bounds: const math.Rectangle<double>(0, 0, 400, 300),
          zoomLevel: 1,
          panOffset: Vector2.zero(),
        );

        provider.updateAutomaton(automaton);
        controller.synchronize(automaton);

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: AutomatonGraphViewCanvas(
                automaton: automaton,
                canvasKey: GlobalKey(),
                controller: controller,
                toolController: toolController,
              ),
            ),
          ),
        );

        await tester.pumpAndSettle();

        await tester.tap(find.byType(AutomatonGraphViewCanvas));
        await tester.pump();

        expect(controller.addStateAtCallCount, equals(1));
        expect(controller.lastAddStateWorldOffset, isNotNull);
      },
    );

    testWidgets('caps FSA canvas zoom at 2x', (tester) async {
      final automaton = FSA(
        id: 'zoom-cap',
        name: 'Zoom cap',
        states: <automaton_state.State>{},
        transitions: const <FSATransition>{},
        alphabet: const <String>{},
        initialState: null,
        acceptingStates: <automaton_state.State>{},
        created: DateTime.utc(2024, 1, 1),
        modified: DateTime.utc(2024, 1, 1),
        bounds: const math.Rectangle<double>(0, 0, 400, 300),
        zoomLevel: 1,
        panOffset: Vector2.zero(),
      );

      provider.updateAutomaton(automaton);
      controller.synchronize(automaton);

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: AutomatonGraphViewCanvas(
              automaton: automaton,
              canvasKey: GlobalKey(),
              controller: controller,
              toolController: toolController,
            ),
          ),
        ),
      );
      await tester.pump();

      expect(
        tester
            .widget<InteractiveViewer>(find.byType(InteractiveViewer))
            .maxScale,
        2.0,
      );
      expect(
        tester
            .widget<InteractiveViewer>(find.byType(InteractiveViewer))
            .minScale,
        0.05,
      );
    });

    testWidgets('double tap edits a state on Android', (tester) async {
      debugDefaultTargetPlatformOverride = TargetPlatform.android;
      addTearDown(() => debugDefaultTargetPlatformOverride = null);
      toolController.setActiveTool(AutomatonCanvasTool.selection);

      final state = automaton_state.State(
        id: 'q0',
        label: 'q0',
        position: Vector2(120, 100),
        isInitial: true,
      );
      final automaton = FSA(
        id: 'android-double-tap',
        name: 'Android double tap',
        states: {state},
        transitions: const <FSATransition>{},
        alphabet: const <String>{},
        initialState: state,
        acceptingStates: <automaton_state.State>{},
        created: DateTime.utc(2024, 1, 1),
        modified: DateTime.utc(2024, 1, 1),
        bounds: const math.Rectangle<double>(0, 0, 400, 300),
        zoomLevel: 1,
        panOffset: Vector2.zero(),
      );

      provider.updateAutomaton(automaton);
      controller.synchronize(automaton);

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: AutomatonGraphViewCanvas(
              automaton: automaton,
              canvasKey: GlobalKey(),
              controller: controller,
              toolController: toolController,
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(
        controller.graphController.transformationController!.value
            .getMaxScaleOnAxis(),
        closeTo(1.0, 0.0001),
      );

      final stateCenter = tester.getCenter(find.text('q0'));
      final firstTap = await tester.startGesture(stateCenter);
      await firstTap.moveBy(const Offset(1, 0));
      await firstTap.up();
      // runAsync burns real time, so keep well inside kDoubleTapTimeout
      // (300ms) or scheduling jitter on CI degrades this into two single taps.
      await tester.runAsync(
        () => Future<void>.delayed(const Duration(milliseconds: 80)),
      );
      final secondTap = await tester.startGesture(stateCenter);
      await secondTap.moveBy(const Offset(1, 0));
      await tester.runAsync(
        () => Future<void>.delayed(const Duration(milliseconds: 50)),
      );
      await secondTap.up();
      await tester.pumpAndSettle();
      debugDefaultTargetPlatformOverride = null;

      expect(find.byType(TextField), findsOneWidget);
      expect(controller.previewStatePositionCallCount, 0);
      expect(controller.moveStateCallCount, 0);
    });

    testWidgets('single tap marks the selected state for semantics', (
      tester,
    ) async {
      final semantics = tester.ensureSemantics();
      try {
        toolController.setActiveTool(AutomatonCanvasTool.selection);
        final automaton = _singleStateAutomaton('selected-state-semantics');
        final center = await _pumpSingleStateCanvas(
          tester,
          automaton: automaton,
          provider: provider,
          controller: controller,
          toolController: toolController,
        );

        await tester.tapAt(center);
        await tester.pump();

        final stateSemantics = tester.getSemantics(
          find.bySemanticsLabel(
            'State A. Initial state. 0 outgoing transitions. '
            '0 incoming transitions.',
          ),
        );
        // Flutter 3.27 does not expose flagsCollection yet.
        // ignore: deprecated_member_use
        expect(stateSemantics.hasFlag(SemanticsFlag.isSelected), isTrue);
      } finally {
        semantics.dispose();
      }
    });

    testWidgets('assistive activation opens the localized state editor', (
      tester,
    ) async {
      final semantics = tester.ensureSemantics();
      try {
        toolController.setActiveTool(AutomatonCanvasTool.selection);
        final automaton = _singleStateAutomaton('assistive-state-editor');
        await _pumpSingleStateCanvas(
          tester,
          automaton: automaton,
          provider: provider,
          controller: controller,
          toolController: toolController,
          locale: const Locale('pt'),
        );

        const stateLabel =
            'Estado A. Estado inicial. 0 transições de saída. '
            '0 transições de entrada.';
        expect(find.bySemanticsLabel(stateLabel), findsOneWidget);

        tester.semantics.tap(find.semantics.byLabel(stateLabel));
        await tester.pumpAndSettle();

        expect(find.text('Rótulo do estado'), findsOneWidget);
        expect(find.text('Estado inicial'), findsOneWidget);
        expect(find.text('Estado de aceitação'), findsOneWidget);
        expect(find.text('Estado final'), findsNothing);
        expect(find.text('Salvar alterações'), findsOneWidget);
        expect(find.text('Fechar'), findsOneWidget);
      } finally {
        semantics.dispose();
      }
    });

    testWidgets('Delete removes the state selected by a single tap', (
      tester,
    ) async {
      toolController.setActiveTool(AutomatonCanvasTool.selection);
      final automaton = _singleStateAutomaton('keyboard-delete-state');
      final center = await _pumpSingleStateCanvas(
        tester,
        automaton: automaton,
        provider: provider,
        controller: controller,
        toolController: toolController,
      );

      await tester.tapAt(center);
      await tester.pump();
      await tester.sendKeyEvent(LogicalKeyboardKey.delete);
      await tester.pumpAndSettle();

      expect(provider.currentAutomaton?.states, isEmpty);
    });

    testWidgets('deleting a state prompts for attached-note handling', (
      tester,
    ) async {
      toolController.setActiveTool(AutomatonCanvasTool.selection);
      final automaton = _singleStateAutomaton('attached-note-delete-state');
      provider.updateAutomaton(automaton);
      controller.synchronize(automaton);
      final annotations = DocumentAnnotationsNotifier()
        ..add(
          key: DefaultFormalSystemIds.fsa,
          documentId: automaton.id,
          documentRevision: '1',
          x: 0,
          y: 0,
          text: 'State invariant',
          attachment: const AnnotationAttachment(
            type: AnnotationTargetType.state,
            targetId: 'A',
            offsetX: 300,
          ),
        );

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            documentAnnotationsProvider.overrideWith((ref) => annotations),
          ],
          child: MaterialApp(
            home: Scaffold(
              body: AutomatonGraphViewCanvas(
                automaton: automaton,
                canvasKey: GlobalKey(),
                controller: controller,
                toolController: toolController,
                annotationConfig: AutomatonCanvasAnnotationConfig(
                  systemKey: DefaultFormalSystemIds.fsa,
                  documentId: automaton.id,
                  documentRevision: '1',
                ),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tapAt(tester.getCenter(find.text('A')));
      await tester.pump();
      await tester.sendKeyEvent(LogicalKeyboardKey.delete);
      await tester.pumpAndSettle();

      expect(find.text('Attached notes'), findsOneWidget);
      expect(provider.currentAutomaton?.states, isNotEmpty);

      await tester.tap(find.text('Detach notes'));
      await tester.pumpAndSettle();

      expect(provider.currentAutomaton?.states, isEmpty);
      expect(
        annotations
            .state[DefaultFormalSystemIds.fsa]!
            .annotations
            .single
            .attachment,
        isNull,
      );
      expect(annotations.canUndo(DefaultFormalSystemIds.fsa), isTrue);
    });

    testWidgets('long press opens state options with a delete action', (
      tester,
    ) async {
      toolController.setActiveTool(AutomatonCanvasTool.selection);
      final automaton = _singleStateAutomaton('long-press-delete-state');
      final center = await _pumpSingleStateCanvas(
        tester,
        automaton: automaton,
        provider: provider,
        controller: controller,
        toolController: toolController,
      );

      await tester.longPressAt(center);
      await tester.pumpAndSettle();

      final delete = find.byKey(const ValueKey('automaton-state-delete-A'));
      expect(delete, findsOneWidget);
      await tester.tap(delete);
      await tester.pumpAndSettle();

      expect(provider.currentAutomaton?.states, isEmpty);
    });

    testWidgets('secondary click opens state options', (tester) async {
      toolController.setActiveTool(AutomatonCanvasTool.selection);
      final automaton = _singleStateAutomaton('secondary-click-state');
      final center = await _pumpSingleStateCanvas(
        tester,
        automaton: automaton,
        provider: provider,
        controller: controller,
        toolController: toolController,
      );

      await tester.tapAt(
        center,
        kind: PointerDeviceKind.mouse,
        buttons: kSecondaryMouseButton,
      );
      await tester.pumpAndSettle();

      expect(find.byType(TextField), findsOneWidget);
      expect(
        find.byKey(const ValueKey('automaton-state-delete-A')),
        findsOneWidget,
      );
    });

    testWidgets('bare canvas shortcuts do not run while editing state text', (
      tester,
    ) async {
      toolController.setActiveTool(AutomatonCanvasTool.selection);
      final automaton = _singleStateAutomaton('focused-text-shortcuts');
      final center = await _pumpSingleStateCanvas(
        tester,
        automaton: automaton,
        provider: provider,
        controller: controller,
        toolController: toolController,
      );

      await tester.longPressAt(center);
      await tester.pumpAndSettle();
      final textField = find.byType(TextField);
      expect(textField, findsOneWidget);
      await tester.tap(textField);
      await tester.pump();

      await tester.sendKeyEvent(LogicalKeyboardKey.keyT);
      await tester.pump();

      expect(toolController.activeTool, AutomatonCanvasTool.selection);
    });

    testWidgets('one-pixel touch jitter neither previews nor commits a node', (
      tester,
    ) async {
      toolController.setActiveTool(AutomatonCanvasTool.selection);
      final center = await _pumpSingleStateCanvas(
        tester,
        automaton: _singleStateAutomaton('touch-jitter'),
        provider: provider,
        controller: controller,
        toolController: toolController,
      );

      final gesture = await tester.startGesture(
        center,
        kind: PointerDeviceKind.touch,
      );
      await gesture.moveBy(const Offset(1, 0));
      await gesture.up();
      await tester.pumpAndSettle();

      expect(controller.previewStatePositionCallCount, 0);
      expect(controller.moveStateCallCount, 0);
    });

    testWidgets('pinch can begin on a node without moving that node', (
      tester,
    ) async {
      toolController.setActiveTool(AutomatonCanvasTool.selection);
      final center = await _pumpSingleStateCanvas(
        tester,
        automaton: _singleStateAutomaton('node-pinch'),
        provider: provider,
        controller: controller,
        toolController: toolController,
      );
      final transformation =
          controller.graphController.transformationController!;
      final initialScale = transformation.value.getMaxScaleOnAxis();

      final first = await tester.startGesture(
        center,
        pointer: 1,
        kind: PointerDeviceKind.touch,
      );
      await tester.pump();
      final second = await tester.startGesture(
        center + const Offset(60, 0),
        pointer: 2,
        kind: PointerDeviceKind.touch,
      );
      await tester.pump();
      await second.moveTo(center + const Offset(90, 0));
      await tester.pump();
      await first.moveTo(center - const Offset(30, 0));
      await tester.pump();
      await second.moveTo(center + const Offset(100, 0));
      await tester.pump();
      final scaleDuringPinch = transformation.value.getMaxScaleOnAxis();
      await first.up();
      await second.up();
      await tester.pumpAndSettle();

      expect(scaleDuringPinch, greaterThan(initialScale));
      expect(controller.previewStatePositionCallCount, 0);
      expect(controller.moveStateCallCount, 0);
    });

    testWidgets('out-and-back touch drag restores preview without a commit', (
      tester,
    ) async {
      toolController.setActiveTool(AutomatonCanvasTool.selection);
      final center = await _pumpSingleStateCanvas(
        tester,
        automaton: _singleStateAutomaton('out-and-back'),
        provider: provider,
        controller: controller,
        toolController: toolController,
      );

      final gesture = await tester.startGesture(
        center,
        kind: PointerDeviceKind.touch,
      );
      await gesture.moveBy(const Offset(24, 0));
      await tester.pump();
      await gesture.moveTo(center + const Offset(1, 0));
      await tester.pump();
      await gesture.up();
      await tester.pumpAndSettle();

      expect(controller.previewStatePositionCallCount, greaterThan(0));
      expect(
        controller.lastPreviewStatePosition,
        offsetMoreOrLessEquals(const Offset(40, 40), epsilon: 0.01),
      );
      expect(controller.moveStateCallCount, 0);
      expect(find.byType(TextField), findsNothing);
    });

    testWidgets('mouse drag above precise hit slop commits once', (
      tester,
    ) async {
      toolController.setActiveTool(AutomatonCanvasTool.selection);
      final center = await _pumpSingleStateCanvas(
        tester,
        automaton: _singleStateAutomaton('precise-mouse-drag'),
        provider: provider,
        controller: controller,
        toolController: toolController,
      );

      final gesture = await tester.startGesture(
        center,
        kind: PointerDeviceKind.mouse,
      );
      await gesture.moveBy(const Offset(2, 0));
      await tester.pump();
      await gesture.up();
      await tester.pumpAndSettle();

      expect(controller.previewStatePositionCallCount, greaterThan(0));
      expect(controller.moveStateCallCount, 1);
    });

    testWidgets(
      'resynchronizes when automaton structure changes with same identity fields',
      (tester) async {
        final canvasKey = GlobalKey();
        final state = automaton_state.State(
          id: 'q0',
          label: 'q0',
          position: Vector2(40, 40),
          isInitial: true,
        );
        final automaton = FSA(
          id: 'same-id',
          name: 'Same Name',
          states: {state},
          transitions: const <FSATransition>{},
          alphabet: const <String>{},
          initialState: state,
          acceptingStates: <automaton_state.State>{},
          created: DateTime.utc(2024, 1, 1),
          modified: DateTime.utc(2024, 1, 1),
          bounds: const math.Rectangle<double>(0, 0, 400, 300),
          zoomLevel: 1,
          panOffset: Vector2.zero(),
        );

        provider.updateAutomaton(automaton);

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: AutomatonGraphViewCanvas(
                automaton: automaton,
                canvasKey: canvasKey,
                controller: controller,
                toolController: toolController,
              ),
            ),
          ),
        );
        await tester.pump();

        final initialSyncCount = controller.synchronizedAutomata.length;
        expect(initialSyncCount, greaterThan(0));

        final movedState = state.copyWith(position: Vector2(180, 120));
        final updatedAutomaton = automaton.copyWith(
          states: {movedState},
          initialState: movedState,
        );

        provider.updateAutomaton(updatedAutomaton);

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: AutomatonGraphViewCanvas(
                automaton: updatedAutomaton,
                canvasKey: canvasKey,
                controller: controller,
                toolController: toolController,
              ),
            ),
          ),
        );
        await tester.pump();

        expect(
          controller.synchronizedAutomata.length,
          greaterThan(initialSyncCount),
        );
        expect(controller.synchronizedAutomata.last, same(updatedAutomaton));
      },
    );

    testWidgets('exposes canvas states and transitions to semantics', (
      tester,
    ) async {
      final semantics = tester.ensureSemantics();
      try {
        final state = automaton_state.State(
          id: 'A',
          label: 'A',
          position: Vector2(40, 40),
          isInitial: true,
        );
        final acceptingState = automaton_state.State(
          id: 'B',
          label: 'B',
          position: Vector2(160, 40),
          isAccepting: true,
        );
        final automaton = FSA(
          id: 'semantic-canvas',
          name: 'Semantic Canvas',
          states: {state, acceptingState},
          transitions: {
            FSATransition(
              id: 't0',
              fromState: state,
              toState: acceptingState,
              inputSymbols: const {'a'},
            ),
          },
          alphabet: const <String>{'a'},
          initialState: state,
          acceptingStates: <automaton_state.State>{acceptingState},
          created: DateTime.utc(2024, 1, 1),
          modified: DateTime.utc(2024, 1, 1),
          bounds: const math.Rectangle<double>(0, 0, 400, 300),
          zoomLevel: 1,
          panOffset: Vector2.zero(),
        );

        provider.updateAutomaton(automaton);
        controller.synchronize(automaton);

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: AutomatonGraphViewCanvas(
                automaton: automaton,
                canvasKey: GlobalKey(),
                controller: controller,
                toolController: toolController,
              ),
            ),
          ),
        );

        await tester.pumpAndSettle();

        expect(
          find.bySemanticsLabel(
            'Automaton canvas viewport. 2 states, 1 transition.',
          ),
          findsOneWidget,
        );
        expect(
          find.bySemanticsLabel(
            'State A. Initial state. 1 outgoing transition. '
            '0 incoming transitions.',
          ),
          findsOneWidget,
        );
        expect(
          find.bySemanticsLabel(
            'State B. Accepting state. 0 outgoing transitions. '
            '1 incoming transition.',
          ),
          findsOneWidget,
        );
        expect(
          find.bySemanticsLabel('Transition t0 from A to B labeled a.'),
          findsOneWidget,
        );
      } finally {
        semantics.dispose();
      }
    });

    testWidgets('supports keyboard shortcuts for core canvas tools', (
      tester,
    ) async {
      final automaton = FSA(
        id: 'keyboard-canvas',
        name: 'Keyboard Canvas',
        states: <automaton_state.State>{},
        transitions: const <FSATransition>{},
        alphabet: const <String>{},
        initialState: null,
        acceptingStates: <automaton_state.State>{},
        created: DateTime.utc(2024, 1, 1),
        modified: DateTime.utc(2024, 1, 1),
        bounds: const math.Rectangle<double>(0, 0, 400, 300),
        zoomLevel: 1,
        panOffset: Vector2.zero(),
      );

      provider.updateAutomaton(automaton);
      controller.synchronize(automaton);

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: AutomatonGraphViewCanvas(
              automaton: automaton,
              canvasKey: GlobalKey(),
              controller: controller,
              toolController: toolController,
            ),
          ),
        ),
      );

      await tester.pump();

      toolController.setActiveTool(AutomatonCanvasTool.selection);
      await tester.sendKeyEvent(LogicalKeyboardKey.keyA);
      await tester.pump();
      expect(controller.addStateAtCallCount, equals(1));
      expect(controller.lastAddStateWorldOffset, const Offset(400, 300));
      expect(toolController.activeTool, AutomatonCanvasTool.addState);

      await tester.sendKeyEvent(LogicalKeyboardKey.keyT);
      await tester.pump();
      expect(toolController.activeTool, AutomatonCanvasTool.transition);

      await tester.sendKeyEvent(LogicalKeyboardKey.keyV);
      await tester.pump();
      expect(toolController.activeTool, AutomatonCanvasTool.selection);
    });

    testWidgets(
      'keeps controller-owned transformation usable after teardown until the '
      'controller is disposed',
      (tester) async {
        final transformation =
            controller.graphController.transformationController!;
        final automaton = FSA(
          id: 'teardown',
          name: 'Teardown Automaton',
          states: <automaton_state.State>{},
          transitions: const <FSATransition>{},
          alphabet: const <String>{},
          initialState: null,
          acceptingStates: <automaton_state.State>{},
          created: DateTime.utc(2024, 1, 1),
          modified: DateTime.utc(2024, 1, 1),
          bounds: const math.Rectangle<double>(0, 0, 400, 300),
          zoomLevel: 1,
          panOffset: Vector2.zero(),
        );

        provider.updateAutomaton(automaton);
        controller.synchronize(automaton);

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: AutomatonGraphViewCanvas(
                automaton: automaton,
                canvasKey: GlobalKey(),
                controller: controller,
                toolController: toolController,
              ),
            ),
          ),
        );

        await tester.pump();
        await tester.pumpWidget(const SizedBox.shrink());

        // The view detaching must not dispose the transformation controller:
        // the canvas controller owns it and may attach another view later.
        expect(
          () => transformation.value = Matrix4.identity(),
          returnsNormally,
        );

        controller.dispose();

        expect(
          () =>
              transformation.value = Matrix4.identity()
                ..translateByDouble(1.0, 0.0, 0.0, 1.0),
          throwsFlutterError,
        );
      },
    );

    for (final tool in [
      AutomatonCanvasTool.addState,
      AutomatonCanvasTool.transition,
    ]) {
      testWidgets(
        "keeps node drags and canvas pan live when ${tool.toString().split('.').last} tool is active",
        (tester) async {
          toolController.setActiveTool(tool);
          final state = automaton_state.State(
            id: 'A',
            label: 'A',
            position: Vector2(40, 40),
            isInitial: true,
          );
          final automaton = FSA(
            id: 'drag',
            name: 'Automaton',
            states: {state},
            transitions: const <FSATransition>{},
            alphabet: const <String>{'a'},
            initialState: state,
            acceptingStates: <automaton_state.State>{},
            created: DateTime.utc(2024, 1, 1),
            modified: DateTime.utc(2024, 1, 1),
            bounds: const math.Rectangle<double>(0, 0, 400, 300),
            zoomLevel: 1,
            panOffset: Vector2.zero(),
          );

          provider.updateAutomaton(automaton);
          controller.synchronize(automaton);

          final canvasKey = GlobalKey();
          await tester.pumpWidget(
            MaterialApp(
              home: Scaffold(
                body: AutomatonGraphViewCanvas(
                  automaton: automaton,
                  canvasKey: canvasKey,
                  controller: controller,
                  toolController: toolController,
                ),
              ),
            ),
          );

          await tester.pumpAndSettle();

          final transformation =
              controller.graphController.transformationController;
          expect(transformation, isNotNull);
          final initialMatrix = List<double>.from(
            transformation!.value.storage,
          );

          // Dragging a state moves it even while a placement tool is active.
          await tester.drag(find.text('A'), const Offset(32, 0));
          await tester.pump();
          expect(controller.moveStateCallCount, equals(1));
          expect(controller.lastMoveStateId, 'A');

          // Dragging empty canvas pans the viewport instead of adding
          // anything.
          await tester.drag(find.byKey(canvasKey), const Offset(48, -16));
          await tester.pump();
          expect(
            List<double>.from(transformation.value.storage),
            isNot(equals(initialMatrix)),
          );
          expect(controller.lastAddStateWorldOffset, isNull);
        },
      );
    }

    testWidgets('disables GraphView interpolation while a node is dragged', (
      tester,
    ) async {
      toolController.setActiveTool(AutomatonCanvasTool.selection);

      final state = automaton_state.State(
        id: 'A',
        label: 'A',
        position: Vector2(40, 40),
        isInitial: true,
      );
      final automaton = FSA(
        id: 'drag-motion',
        name: 'Automaton',
        states: {state},
        transitions: const <FSATransition>{},
        alphabet: const <String>{'a'},
        initialState: state,
        acceptingStates: <automaton_state.State>{},
        created: DateTime.utc(2024, 1, 1),
        modified: DateTime.utc(2024, 1, 1),
        bounds: const math.Rectangle<double>(0, 0, 400, 300),
        zoomLevel: 1,
        panOffset: Vector2.zero(),
      );

      provider.updateAutomaton(automaton);
      controller.synchronize(automaton);

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: AutomatonGraphViewCanvas(
              automaton: automaton,
              canvasKey: GlobalKey(),
              controller: controller,
              toolController: toolController,
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(tester.widget<GraphView>(find.byType(GraphView)).animated, isTrue);

      final gesture = await tester.startGesture(
        tester.getCenter(find.text('A')),
        kind: PointerDeviceKind.touch,
      );
      await gesture.moveBy(const Offset(24, 0));
      await tester.pump();

      expect(controller.previewStatePositionCallCount, greaterThan(0));
      expect(controller.moveStateCallCount, equals(0));
      expect(
        tester.widget<GraphView>(find.byType(GraphView)).animated,
        isFalse,
      );

      await gesture.up();
      await tester.pumpAndSettle();

      expect(controller.moveStateCallCount, equals(1));
      expect(tester.widget<GraphView>(find.byType(GraphView)).animated, isTrue);
    });
  });

  group('AutomatonGraphViewCanvas', () {
    late _RecordingAutomatonStateNotifier provider;
    late GraphViewCanvasController controller;
    late AutomatonCanvasToolController toolController;
    late automaton_state.State stateA;
    late automaton_state.State stateB;

    setUp(() {
      provider = _RecordingAutomatonStateNotifier();
      controller = GraphViewCanvasController(automatonStateNotifier: provider);
      toolController = AutomatonCanvasToolController(
        AutomatonCanvasTool.transition,
      );

      stateA = automaton_state.State(
        id: 'A',
        label: 'A',
        position: Vector2(40, 40),
        isInitial: true,
      );
      stateB = automaton_state.State(
        id: 'B',
        label: 'B',
        position: Vector2(200, 160),
        isAccepting: true,
      );
    });

    tearDown(() {
      controller.dispose();
      toolController.dispose();
    });

    FSA buildAutomaton(Set<FSATransition> transitions) {
      final automaton = FSA(
        id: 'auto',
        name: 'Automaton',
        states: {stateA, stateB},
        transitions: transitions,
        alphabet: const {'a', 'b'},
        initialState: stateA,
        acceptingStates: {stateB},
        created: DateTime.utc(2024, 1, 1),
        modified: DateTime.utc(2024, 1, 1),
        bounds: const math.Rectangle<double>(0, 0, 400, 300),
        zoomLevel: 1,
        panOffset: Vector2.zero(),
      );
      provider.updateAutomaton(automaton);
      controller.synchronize(automaton);
      return automaton;
    }

    Future<void> pumpCanvas(
      WidgetTester tester,
      FSA automaton, {
      GlobalKey? canvasKey,
    }) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: ThemeData(splashFactory: NoSplash.splashFactory),
          home: Scaffold(
            body: AutomatonGraphViewCanvas(
              automaton: automaton,
              canvasKey: canvasKey ?? GlobalKey(),
              controller: controller,
              toolController: toolController,
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
    }

    testWidgets('renders disconnected states without transitions', (
      tester,
    ) async {
      final automaton = buildAutomaton({});

      await pumpCanvas(tester, automaton);

      expect(find.text('A'), findsOneWidget);
      expect(find.text('B'), findsOneWidget);
    });

    testWidgets('transition indicator is centered and advances after source', (
      tester,
    ) async {
      final automaton = buildAutomaton({});
      final canvasKey = GlobalKey();
      await pumpCanvas(tester, automaton, canvasKey: canvasKey);
      final indicator = find.byKey(
        const ValueKey('automaton-transition-mode-indicator'),
      );
      final canvasCenter = tester.getCenter(find.byKey(canvasKey));

      expect(indicator, findsOneWidget);
      expect(tester.getCenter(indicator).dx, closeTo(canvasCenter.dx, 0.1));
      expect(find.text('Add transition...'), findsOneWidget);

      await tester.tap(find.text('A'), warnIfMissed: false);
      await tester.pump();

      expect(find.text('Choose target state'), findsOneWidget);
      expect(
        find.byKey(const ValueKey('automaton-transition-preview')),
        findsOneWidget,
      );
    });

    testWidgets('deleting a transition source clears the pending source', (
      tester,
    ) async {
      final automaton = buildAutomaton({});
      await pumpCanvas(tester, automaton);

      await tester.tap(find.text('A'), warnIfMissed: false);
      await tester.pump();
      expect(find.text('Choose target state'), findsOneWidget);

      await tester.longPress(find.text('A'));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const ValueKey('automaton-state-delete-A')));
      await tester.pumpAndSettle();

      await tester.tap(find.text('B'), warnIfMissed: false);
      await tester.pump();

      expect(find.text('Choose target state'), findsOneWidget);
      expect(
        _nodeBackgroundColor(tester, 'B'),
        Theme.of(tester.element(find.text('B'))).colorScheme.tertiaryContainer,
      );
      expect(provider.currentAutomaton?.transitions, isEmpty);
    });

    testWidgets('transition preview follows hover with a precision cursor', (
      tester,
    ) async {
      final automaton = buildAutomaton({});
      await pumpCanvas(tester, automaton);
      await tester.tap(find.text('A'), warnIfMissed: false);
      await tester.pump();

      final pointerRegion = find.byKey(
        const ValueKey('automaton-canvas-pointer-region'),
      );
      expect(pointerRegion, findsOneWidget);
      expect(
        tester.widget<MouseRegion>(pointerRegion).cursor,
        SystemMouseCursors.precise,
      );

      await tester.sendEventToBinding(
        const PointerHoverEvent(
          position: Offset(320, 220),
          kind: PointerDeviceKind.mouse,
        ),
      );
      await tester.pump();
      final preview = find.byKey(
        const ValueKey('automaton-transition-preview'),
      );
      final firstPainter = tester.widget<CustomPaint>(preview).painter!;

      await tester.sendEventToBinding(
        const PointerHoverEvent(
          position: Offset(480, 360),
          kind: PointerDeviceKind.mouse,
        ),
      );
      await tester.pump();
      final secondPainter = tester.widget<CustomPaint>(preview).painter!;

      expect(secondPainter, isNot(same(firstPainter)));
      expect(secondPainter.shouldRepaint(firstPainter), isTrue);
    });

    testWidgets('transition source stays distinct from simulation highlight', (
      tester,
    ) async {
      final automaton = buildAutomaton({});
      await pumpCanvas(tester, automaton);
      final colors = Theme.of(tester.element(find.text('A'))).colorScheme;

      await tester.tap(find.text('A'), warnIfMissed: false);
      await tester.pump();

      expect(_nodeBackgroundColor(tester, 'A'), colors.tertiaryContainer);

      controller.applyHighlight(SimulationHighlight(stateIds: {'A'}));
      await tester.pump();

      expect(_nodeBackgroundColor(tester, 'A'), colors.primaryContainer);
    });

    testWidgets(
      'warning and error state highlights use distinct canvas tones',
      (tester) async {
        final automaton = buildAutomaton({});
        await pumpCanvas(tester, automaton);
        final colors = Theme.of(tester.element(find.text('A'))).colorScheme;

        controller.applyHighlight(SimulationHighlight(warningStateIds: {'A'}));
        await tester.pump();
        expect(_nodeBackgroundColor(tester, 'A'), colors.tertiaryContainer);

        controller.applyHighlight(SimulationHighlight(errorStateIds: {'A'}));
        await tester.pump();
        expect(_nodeBackgroundColor(tester, 'A'), colors.errorContainer);
      },
    );

    testWidgets('tapping a transition path opens its editor directly', (
      tester,
    ) async {
      toolController.setActiveTool(AutomatonCanvasTool.selection);
      const transitionId = 'direct-edge';
      final transition = FSATransition(
        id: transitionId,
        fromState: stateA,
        toState: stateB,
        label: 'x',
        inputSymbols: const {'x'},
      );
      final automaton = buildAutomaton({transition});
      final canvasKey = GlobalKey();
      await pumpCanvas(tester, automaton, canvasKey: canvasKey);
      final geometry = _paintedGeometry(tester, transitionId);
      final localPosition = _worldToViewport(
        controller,
        geometry.pathGeometry.pointAt(0.45),
      );
      final canvasBox =
          canvasKey.currentContext!.findRenderObject()! as RenderBox;

      await tester.tapAt(canvasBox.localToGlobal(localPosition));
      await tester.pumpAndSettle();

      expect(find.byType(GraphViewLabelFieldEditor), findsOneWidget);
      final field = tester.widget<TextField>(find.byType(TextField));
      expect(field.controller?.text, 'x');
      expect(
        find.byKey(const ValueKey('automaton-transition-choice-direct-edge')),
        findsNothing,
      );
    });

    testWidgets('tapping a transition label opens its editor', (tester) async {
      toolController.setActiveTool(AutomatonCanvasTool.selection);
      const transitionId = 'label-edge';
      final transition = FSATransition(
        id: transitionId,
        fromState: stateA,
        toState: stateB,
        label: 'x',
        inputSymbols: const {'x'},
      );
      final automaton = buildAutomaton({transition});
      final canvasKey = GlobalKey();
      await pumpCanvas(tester, automaton, canvasKey: canvasKey);
      final geometry = _paintedGeometry(tester, transitionId);
      final labelRect = geometry.labelRect;
      expect(labelRect, isNotNull, reason: 'label geometry must be laid out');
      final localPosition = _worldToViewport(controller, labelRect!.center);
      final canvasBox =
          canvasKey.currentContext!.findRenderObject()! as RenderBox;

      await tester.tapAt(canvasBox.localToGlobal(localPosition));
      await tester.pumpAndSettle();

      expect(find.byType(GraphViewLabelFieldEditor), findsOneWidget);
      final field = tester.widget<TextField>(find.byType(TextField));
      expect(field.controller?.text, 'x');
    });

    testWidgets(
      'long-pressing a transition label opens its editor in add-state mode',
      (tester) async {
        toolController.setActiveTool(AutomatonCanvasTool.addState);
        const transitionId = 'label-edge-add-state';
        final transition = FSATransition(
          id: transitionId,
          fromState: stateA,
          toState: stateB,
          label: 'x',
          inputSymbols: const {'x'},
        );
        final automaton = buildAutomaton({transition});
        final canvasKey = GlobalKey();
        await pumpCanvas(tester, automaton, canvasKey: canvasKey);
        final geometry = _paintedGeometry(tester, transitionId);
        final labelRect = geometry.labelRect;
        expect(labelRect, isNotNull);
        final localPosition = _worldToViewport(controller, labelRect!.center);
        final canvasBox =
            canvasKey.currentContext!.findRenderObject()! as RenderBox;

        final nodeCountBefore = controller.nodes.length;
        await tester.longPressAt(canvasBox.localToGlobal(localPosition));
        await tester.pumpAndSettle();

        expect(find.byType(GraphViewLabelFieldEditor), findsOneWidget);
        // The long press never placed a state.
        expect(controller.nodes.length, nodeCountBefore);
      },
    );

    testWidgets('tapping a distant control point does not hit the curve', (
      tester,
    ) async {
      toolController.setActiveTool(AutomatonCanvasTool.selection);
      const transitionId = 'curved-edge';
      final transition = FSATransition(
        id: transitionId,
        fromState: stateA,
        toState: stateB,
        label: 'x',
        inputSymbols: const {'x'},
        controlPoint: Vector2(120, 300),
      );
      final automaton = buildAutomaton({transition});
      final canvasKey = GlobalKey();
      await pumpCanvas(tester, automaton, canvasKey: canvasKey);
      final localPosition = _worldToViewport(
        controller,
        const Offset(120, 300),
      );
      final canvasBox =
          canvasKey.currentContext!.findRenderObject()! as RenderBox;

      await tester.tapAt(canvasBox.localToGlobal(localPosition));
      await tester.pumpAndSettle();

      expect(find.byType(GraphViewLabelFieldEditor), findsNothing);
    });

    testWidgets('tapping parallel transition paths asks which edge to edit', (
      tester,
    ) async {
      toolController.setActiveTool(AutomatonCanvasTool.selection);
      final first = FSATransition(
        id: 'parallel-first',
        fromState: stateA,
        toState: stateB,
        label: 'a',
        inputSymbols: const {'a'},
      );
      final second = FSATransition(
        id: 'parallel-second',
        fromState: stateA,
        toState: stateB,
        label: 'b',
        inputSymbols: const {'b'},
      );
      final automaton = buildAutomaton({first, second});
      final canvasKey = GlobalKey();
      await pumpCanvas(tester, automaton, canvasKey: canvasKey);
      final edge = controller.edgeById('parallel-first')!;
      final localPosition = _worldToViewport(
        controller,
        _edgePathMidpoint(controller, edge),
      );
      final canvasBox =
          canvasKey.currentContext!.findRenderObject()! as RenderBox;

      await tester.tapAt(canvasBox.localToGlobal(localPosition));
      await tester.pumpAndSettle();

      expect(
        find.byKey(
          const ValueKey('automaton-transition-choice-parallel-first'),
        ),
        findsOneWidget,
      );
      expect(
        find.byKey(
          const ValueKey('automaton-transition-choice-parallel-second'),
        ),
        findsOneWidget,
      );
    });

    testWidgets(
      'shows transition editor after jittery taps when transition tool is active',
      (tester) async {
        final automaton = buildAutomaton({});

        await pumpCanvas(tester, automaton);

        final sourceGesture = await tester.startGesture(
          tester.getCenter(find.text('A')),
        );
        await sourceGesture.moveBy(const Offset(1, 1));
        await sourceGesture.up();
        await tester.pump();

        final targetGesture = await tester.startGesture(
          tester.getCenter(find.text('B')),
        );
        await targetGesture.moveBy(const Offset(1, -1));
        await targetGesture.up();
        await tester.pumpAndSettle();

        expect(find.byType(GraphViewLabelFieldEditor), findsOneWidget);
      },
    );

    testWidgets('allows creating a new edge when one already exists', (
      tester,
    ) async {
      const existingId = 'transition_existing';
      final transition = FSATransition(
        id: existingId,
        fromState: stateA,
        toState: stateB,
        label: 'x',
        inputSymbols: const {'x'},
        controlPoint: Vector2(120, 40),
      );
      final automaton = buildAutomaton({transition});

      await pumpCanvas(tester, automaton);

      await tester.tap(find.text('A'));
      await tester.pump();
      await tester.tap(find.text('B'), warnIfMissed: false);
      await tester.pumpAndSettle();

      final createNewFinder = find.byKey(
        const ValueKey('automaton-transition-choice-create-new'),
      );
      expect(createNewFinder, findsOneWidget);
      await tester.tap(createNewFinder);
      await tester.pumpAndSettle();

      final textFieldFinder = find.byType(TextField);
      expect(textFieldFinder, findsOneWidget);
      await tester.enterText(textFieldFinder, 'b');
      await tester.pumpAndSettle();
      await tester.tap(find.text('Save'));
      await tester.pumpAndSettle();

      expect(provider.transitionCalls, hasLength(1));
      final call = provider.transitionCalls.single;
      expect(call['id'], isNot(equals(existingId)));
      expect(call['fromStateId'], equals('A'));
      expect(call['toStateId'], equals('B'));
      expect(call['label'], equals('b'));
    });

    testWidgets('edits an existing transition selected from the dialog', (
      tester,
    ) async {
      const existingId = 'transition_existing';
      final transition = FSATransition(
        id: existingId,
        fromState: stateA,
        toState: stateB,
        label: 'x',
        inputSymbols: const {'x'},
        controlPoint: Vector2(120, 40),
      );
      final automaton = buildAutomaton({transition});

      await pumpCanvas(tester, automaton);

      await tester.tap(find.text('A'));
      await tester.pump();
      await tester.tap(find.text('B'), warnIfMissed: false);
      await tester.pumpAndSettle();

      final existingOptionFinder = find.byKey(
        const ValueKey('automaton-transition-choice-transition_existing'),
      );
      expect(existingOptionFinder, findsOneWidget);
      await tester.tap(existingOptionFinder);
      await tester.pumpAndSettle();

      final textFieldFinder = find.byType(TextField);
      expect(textFieldFinder, findsOneWidget);
      final textField = tester.widget<TextField>(textFieldFinder);
      expect(textField.controller?.text, equals('x'));

      await tester.enterText(textFieldFinder, 'edited');
      await tester.pumpAndSettle();
      await tester.tap(find.text('Save'));
      await tester.pumpAndSettle();

      expect(provider.transitionCalls, hasLength(1));
      final call = provider.transitionCalls.single;
      expect(call['id'], equals(existingId));
      expect(call['label'], equals('edited'));
    });

    testWidgets('deletes only the selected existing transition', (
      tester,
    ) async {
      const existingId = 'transition_existing';
      final transition = FSATransition(
        id: existingId,
        fromState: stateA,
        toState: stateB,
        label: 'x',
        inputSymbols: const {'x'},
        controlPoint: Vector2(120, 40),
      );
      final automaton = buildAutomaton({transition});

      await pumpCanvas(tester, automaton);

      await tester.tap(find.text('A'));
      await tester.pump();
      await tester.tap(find.text('B'), warnIfMissed: false);
      await tester.pumpAndSettle();

      final existingOptionFinder = find.byKey(
        const ValueKey('automaton-transition-choice-transition_existing'),
      );
      expect(existingOptionFinder, findsOneWidget);
      await tester.tap(existingOptionFinder);
      await tester.pumpAndSettle();

      await tester.tap(find.text('Delete'));
      await tester.pumpAndSettle();

      expect(provider.removedTransitionIds, equals([existingId]));
      expect(provider.transitionCalls, isEmpty);
    });

    testWidgets('animates the stable node id emitted by a simulation step', (
      tester,
    ) async {
      stateA = automaton_state.State(
        id: 'node-a-id',
        label: 'A',
        position: Vector2(40, 40),
        isInitial: true,
      );
      stateB = automaton_state.State(
        id: 'node-b-id',
        label: 'B',
        position: Vector2(200, 160),
        isAccepting: true,
      );
      final automaton = buildAutomaton({});

      await pumpCanvas(tester, automaton);

      final stateAScaleFinder = find.ancestor(
        of: find.text('A'),
        matching: find.byType(AnimatedScale),
      );
      final stateBScaleFinder = find.ancestor(
        of: find.text('B'),
        matching: find.byType(AnimatedScale),
      );

      expect(
        tester.widget<AnimatedScale>(stateAScaleFinder).scale,
        equals(1.0),
      );
      expect(
        tester.widget<AnimatedScale>(stateBScaleFinder).scale,
        equals(1.0),
      );

      final service = SimulationHighlightService(
        channel: GraphViewSimulationHighlightChannel(controller),
      );
      service.emitFromSteps([
        const SimulationStep(
          currentState: 'B',
          activeStateIds: {'node-b-id'},
          remainingInput: '',
          stepNumber: 1,
        ),
      ], 0);
      await tester.pumpAndSettle();

      expect(
        tester.widget<AnimatedScale>(stateAScaleFinder).scale,
        equals(1.0),
      );
      expect(
        tester.widget<AnimatedScale>(stateBScaleFinder).scale,
        equals(1.04),
      );

      service.clear();
      await tester.pumpAndSettle();

      expect(
        tester.widget<AnimatedScale>(stateBScaleFinder).scale,
        equals(1.0),
      );
    });

    testWidgets(
      'recomputes grouped transition anchor while dragging before pointer up',
      (tester) async {
        toolController.setActiveTool(AutomatonCanvasTool.selection);

        final transition = FSATransition(
          id: 'transition_drag',
          fromState: stateA,
          toState: stateB,
          label: 'a',
          inputSymbols: const {'a'},
        );
        final automaton = buildAutomaton({transition});

        await pumpCanvas(tester, automaton);

        final edgeBefore = controller.edgeById('transition_drag');
        expect(edgeBefore, isNotNull);
        final anchorBefore = resolveLinkAnchorWorld(controller, edgeBefore!);
        expect(anchorBefore, isNotNull);

        final gesture = await tester.startGesture(
          tester.getCenter(find.text('B'), warnIfMissed: false),
        );
        await gesture.moveBy(const Offset(0, -24));
        await tester.pump();
        await gesture.moveBy(const Offset(0, -72));
        await tester.pump();

        final edgeDuringDrag = controller.edgeById('transition_drag');
        expect(edgeDuringDrag, isNotNull);
        final anchorDuringDrag = resolveLinkAnchorWorld(
          controller,
          edgeDuringDrag!,
        );
        expect(anchorDuringDrag, isNotNull);
        expect((anchorDuringDrag! - anchorBefore!).distance, greaterThan(8));

        await gesture.up();
        await tester.pumpAndSettle();
      },
    );
  });
}
