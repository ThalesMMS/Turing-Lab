//
//  graphview_canvas_controller_test.dart
//  Turing Lab
//
//  Tests the base GraphView canvas controller for automata, coordinating
//  providers, layout repositories, and selection updates. Inspects layout, zoom,
//  and transition-sync commands so the visual state matches the logical model.
//
//  Thales Matheus Mendonça Santos - October 2025
//

import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:graphview/graphview_turing_lab.dart';
import 'package:vector_math/vector_math_64.dart';

import 'package:turing_lab/core/constants/automaton_canvas_constants.dart';
import 'package:turing_lab/core/models/fsa.dart';
import 'package:turing_lab/core/models/fsa_transition.dart';
import 'package:turing_lab/core/models/state.dart' as automaton_state;
import 'package:turing_lab/features/canvas/graphview/base_graphview_canvas_controller.dart';
import 'package:turing_lab/features/canvas/graphview/graphview_canvas_controller.dart';
import 'package:turing_lab/presentation/providers/automaton_state_provider.dart';

import 'support/recording_graph_view_controller.dart';

class _RecordingAutomatonStateNotifier extends AutomatonStateNotifier {
  _RecordingAutomatonStateNotifier() : super();

  final List<Map<String, Object?>> addStateCalls = [];
  final List<Map<String, Object?>> updateLabelCalls = [];
  final List<Map<String, Object?>> transitionCalls = [];
  final List<Map<String, Object?>> moveStateCalls = [];

  @override
  void addState({
    required String id,
    required String label,
    required double x,
    required double y,
    bool? isInitial,
    bool? isAccepting,
  }) {
    addStateCalls.add({
      'id': id,
      'label': label,
      'x': x,
      'y': y,
      'isInitial': isInitial,
      'isAccepting': isAccepting,
    });
    super.addState(
      id: id,
      label: label,
      x: x,
      y: y,
      isInitial: isInitial,
      isAccepting: isAccepting,
    );
  }

  @override
  void moveState({required String id, required double x, required double y}) {
    moveStateCalls.add({'id': id, 'x': x, 'y': y});
    super.moveState(id: id, x: x, y: y);
  }

  @override
  void updateStateLabel({required String id, required String label}) {
    updateLabelCalls.add({'id': id, 'label': label});
    super.updateStateLabel(id: id, label: label);
  }

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
}

class _InspectableGraphViewCanvasController extends GraphViewCanvasController {
  _InspectableGraphViewCanvasController({
    required super.automatonStateNotifier,
    super.viewController,
    super.transformationController,
    super.historyLimit,
    super.cacheEvictionThreshold,
  });

  Map<String, Node> get debugGraphNodes => graphNodes;
  Map<String, Edge> get debugGraphEdges => graphEdges;
}

class _CountingGraphObserver implements GraphObserver {
  int notifications = 0;

  @override
  void notifyGraphInvalidated() {
    notifications++;
  }
}

class _RecordingHistoryCompanion implements GraphViewHistoryCompanion {
  int undoCalls = 0;
  int redoCalls = 0;

  @override
  void redo() => redoCalls++;

  @override
  void undo() => undoCalls++;
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('GraphViewCanvasController', () {
    late _RecordingAutomatonStateNotifier provider;
    late GraphViewCanvasController controller;
    late bool controllerDisposed;
    var controllerInitialized = false;

    void recreateController({
      int historyLimit = BaseGraphViewCanvasController.kDefaultHistoryLimit,
      int cacheEvictionThreshold =
          BaseGraphViewCanvasController.kDefaultCacheEvictionThreshold,
      bool inspectable = false,
      TransformationController? transformationController,
      GraphViewController? viewController,
    }) {
      if (controllerInitialized && !controllerDisposed) {
        controller.dispose();
      }
      provider = _RecordingAutomatonStateNotifier();
      controller = inspectable
          ? _InspectableGraphViewCanvasController(
              automatonStateNotifier: provider,
              viewController: viewController,
              transformationController: transformationController,
              historyLimit: historyLimit,
              cacheEvictionThreshold: cacheEvictionThreshold,
            )
          : GraphViewCanvasController(
              automatonStateNotifier: provider,
              viewController: viewController,
              transformationController: transformationController,
              historyLimit: historyLimit,
              cacheEvictionThreshold: cacheEvictionThreshold,
            );
      controllerInitialized = true;
      controllerDisposed = false;
      provider.updateAutomaton(
        FSA(
          id: 'auto',
          name: 'Automaton',
          states: const {},
          transitions: const {},
          alphabet: const {},
          initialState: null,
          acceptingStates: const {},
          created: DateTime.utc(2024, 1, 1),
          modified: DateTime.utc(2024, 1, 1),
          bounds: const math.Rectangle<double>(0, 0, 400, 300),
          panOffset: Vector2.zero(),
          zoomLevel: 1,
        ),
      );
    }

    setUp(() {
      recreateController();
    });

    tearDown(() {
      if (controllerInitialized && !controllerDisposed) {
        controller.dispose();
        controllerDisposed = true;
      }
    });

    test('dispose releases owned transformation before GraphView mounts', () {
      final transformation =
          controller.graphController.transformationController!;

      controller.dispose();
      controllerDisposed = true;

      expect(
        () => transformation.value = Matrix4.identity()
          ..translateByDouble(1.0, 0.0, 0.0, 1.0),
        throwsFlutterError,
      );
    });

    test('dispose leaves caller-owned transformation untouched', () {
      final transformation = TransformationController();
      recreateController(transformationController: transformation);

      controller.dispose();
      controllerDisposed = true;

      expect(
        () => transformation.value = Matrix4.identity()
          ..translateByDouble(1.0, 0.0, 0.0, 1.0),
        returnsNormally,
      );
      transformation.dispose();
    });

    test('rejects a separate transformation with an external view controller',
        () {
      final viewTransformation = TransformationController();
      final conflictingTransformation = TransformationController();
      final viewController = GraphViewController(
        transformationController: viewTransformation,
      );
      addTearDown(viewTransformation.dispose);
      addTearDown(conflictingTransformation.dispose);

      expect(
        () => GraphViewCanvasController(
          automatonStateNotifier: provider,
          viewController: viewController,
          transformationController: conflictingTransformation,
        ),
        throwsAssertionError,
      );
    });

    test('addStateAt generates id and forwards to provider', () {
      controller.addStateAt(const Offset(120, 80));

      expect(provider.addStateCalls, hasLength(1));
      final call = provider.addStateCalls.single;
      expect(call['id'], isNotEmpty);
      expect(call['label'], equals('q0'));
      expect(call['x'], closeTo(72, 0.0001));
      expect(call['y'], closeTo(32, 0.0001));
      expect(call['isInitial'], isNull);
      expect(call['isAccepting'], isNull);
      expect(provider.state.currentAutomaton!.initialState!.id, call['id']);
    });

    test(
      'addStateAtCenter converts viewport centre into world coordinates',
      () {
        final transformation =
            controller.graphController.transformationController;
        expect(transformation, isNotNull);
        controller.updateViewportSize(const Size(800, 600));

        transformation!.value = Matrix4.identity();
        controller.addStateAtCenter();

        expect(provider.addStateCalls, hasLength(1));
        final firstCall = provider.addStateCalls.first;
        expect(firstCall['x'], closeTo(352, 0.0001));
        expect(firstCall['y'], closeTo(252, 0.0001));

        transformation.value = Matrix4.identity()
          ..translateByDouble(150.0, -50.0, 0.0, 1.0)
          ..scaleByDouble(1.5, 1.5, 1.5, 1.0);
        controller.addStateAtCenter();

        expect(provider.addStateCalls, hasLength(2));
        final secondCall = provider.addStateCalls.last;
        expect(secondCall['x'], closeTo((400 - 150) / 1.5 - 48, 0.0001));
        expect(secondCall['y'], closeTo((300 - (-50)) / 1.5 - 48, 0.0001));
      },
    );

    test('addStateAtCenter uses the safe viewport centre', () {
      controller.updateViewportSize(const Size(800, 600));
      controller.updateViewportInsets(const EdgeInsets.only(bottom: 120));

      controller.addStateAtCenter();

      final call = provider.addStateCalls.single;
      expect(call['x'], closeTo(352, 0.0001));
      expect(call['y'], closeTo(192, 0.0001));
    });

    test('exposes the safe viewport in world coordinates', () {
      controller.updateViewportSize(const Size(800, 600));
      controller.updateViewportInsets(
        const EdgeInsets.fromLTRB(100, 50, 200, 150),
      );
      controller.graphController.transformationController!.value =
          Matrix4.identity()
            ..translateByDouble(100.0, -50.0, 0.0, 1.0)
            ..scaleByDouble(2.0, 2.0, 2.0, 1.0);

      final world = controller.safeViewportWorldRect!;

      expect(world.left, closeTo(0, 0.0001));
      expect(world.top, closeTo(50, 0.0001));
      expect(world.right, closeTo(250, 0.0001));
      expect(world.bottom, closeTo(250, 0.0001));
    });

    test('exposes live zoom percentage bounds', () {
      final transformation =
          controller.graphController.transformationController!;

      transformation.value = Matrix4.diagonal3Values(
        kAutomatonCanvasMaxScale,
        kAutomatonCanvasMaxScale,
        1,
      );

      expect(controller.currentScale, kAutomatonCanvasMaxScale);
      expect(controller.canZoomIn, isFalse);
      expect(controller.canZoomOut, isTrue);

      transformation.value = Matrix4.diagonal3Values(
        kAutomatonCanvasMinScale,
        kAutomatonCanvasMinScale,
        1,
      );

      expect(controller.currentScale, kAutomatonCanvasMinScale);
      expect(controller.canZoomIn, isTrue);
      expect(controller.canZoomOut, isFalse);
    });

    test('zoomIn keeps the viewport centre anchored', () {
      final transformation = TransformationController();
      addTearDown(transformation.dispose);
      final viewController = RecordingGraphViewController(transformation);
      recreateController(viewController: viewController);
      controller.updateViewportSize(const Size(800, 600));

      transformation.value = Matrix4.identity()
        ..translateByDouble(-80.0, -60.0, 0.0, 1.0)
        ..scaleByDouble(0.8, 0.8, 0.8, 1.0);
      final before = Matrix4.copy(transformation.value);
      final inverse = Matrix4.copy(before);
      expect(inverse.invert(), isNot(0));
      final worldAtViewportCenter = inverse.transform3(Vector3(400, 300, 0));

      controller.zoomIn();

      expect(viewController.lastTarget, isNotNull);
      final afterCenter = transformation.value.transform3(
        Vector3(
          worldAtViewportCenter.x,
          worldAtViewportCenter.y,
          worldAtViewportCenter.z,
        ),
      );
      expect(afterCenter.x, closeTo(400, 0.0001));
      expect(afterCenter.y, closeTo(300, 0.0001));
      expect(transformation.value.getMaxScaleOnAxis(), closeTo(0.96, 0.0001));
    });

    test('zoomIn keeps the safe viewport centre anchored', () {
      final transformation = TransformationController();
      addTearDown(transformation.dispose);
      final viewController = RecordingGraphViewController(transformation);
      recreateController(viewController: viewController);
      controller.updateViewportSize(const Size(800, 600));
      controller.updateViewportInsets(const EdgeInsets.only(bottom: 120));

      transformation.value = Matrix4.identity()
        ..translateByDouble(-80.0, -60.0, 0.0, 1.0)
        ..scaleByDouble(0.8, 0.8, 0.8, 1.0);
      final inverse = Matrix4.copy(transformation.value);
      expect(inverse.invert(), isNot(0));
      final worldAtSafeCenter = inverse.transform3(Vector3(400, 240, 0));

      controller.zoomIn();

      final afterCenter = transformation.value.transform3(worldAtSafeCenter);
      expect(afterCenter.x, closeTo(400, 0.0001));
      expect(afterCenter.y, closeTo(240, 0.0001));
    });

    test('fitToContent centres graph inside the safe viewport', () {
      final transformation = TransformationController();
      addTearDown(transformation.dispose);
      final viewController = RecordingGraphViewController(transformation);
      recreateController(viewController: viewController);
      controller.updateViewportSize(const Size(800, 600));
      controller.updateViewportInsets(const EdgeInsets.only(bottom: 200));
      controller.addStateAt(const Offset(200, 160));
      final bounds = controller.graph.calculateGraphBounds();
      final contentCenter = Vector3(
        bounds.left + bounds.width / 2,
        bounds.top + bounds.height / 2,
        0,
      );

      controller.fitToContent();

      final renderedCenter = transformation.value.transform3(contentCenter);
      expect(renderedCenter.x, closeTo(400, 0.0001));
      expect(renderedCenter.y, closeTo(200, 0.0001));
    });

    test('fitToContent uses a bounded reset before viewport is known', () {
      final transformation = TransformationController();
      addTearDown(transformation.dispose);
      final viewController = RecordingGraphViewController(transformation);
      recreateController(viewController: viewController);
      controller.addStateAt(const Offset(0, 0));

      controller.fitToContent();

      expect(viewController.zoomToFitCount, 0);
      expect(viewController.lastTarget, isNotNull);
      expect(
        viewController.lastTarget!.getMaxScaleOnAxis(),
        closeTo(1, 0.0001),
      );
    });

    test('moveState forwards coordinates to provider', () {
      controller.addStateAt(const Offset(0, 0));
      final id = provider.addStateCalls.first['id'] as String;

      controller.moveState(id, const Offset(240, 160));

      expect(provider.moveStateCalls, hasLength(1));
      final call = provider.moveStateCalls.single;
      expect(call['id'], equals(id));
      expect(call['x'], closeTo(240, 0.0001));
      expect(call['y'], closeTo(160, 0.0001));
    });

    test('drag previews commit one domain mutation and one undo entry', () {
      controller.addStateAt(const Offset(0, 0));
      final id = provider.addStateCalls.first['id'] as String;
      final revisionBeforeDrag = controller.graphRevision.value;
      final observer = _CountingGraphObserver();
      controller.graph.graphObserver.add(observer);
      addTearDown(() => controller.graph.graphObserver.remove(observer));
      final generationBefore = controller.graph.generation;

      controller.previewStatePosition(id, const Offset(40, 20));

      expect(controller.graph.generation, generationBefore + 1);
      expect(observer.notifications, 1);
      expect(provider.moveStateCalls, isEmpty);

      controller.previewStatePosition(id, const Offset(120, 80));

      expect(provider.moveStateCalls, isEmpty);
      expect(controller.graphRevision.value, revisionBeforeDrag);
      expect(controller.nodePosition(id), const Offset(120, 80));
      expect(observer.notifications, 2);

      final generationBeforeInvalid = controller.graph.generation;
      final notificationsBeforeInvalid = observer.notifications;
      controller.previewStatePosition(id, const Offset(double.nan, 20));
      controller.previewStatePosition(id, const Offset(20, double.infinity));
      expect(controller.nodePosition(id), const Offset(120, 80));
      expect(controller.graph.generation, generationBeforeInvalid);
      expect(observer.notifications, notificationsBeforeInvalid);

      controller.moveState(id, const Offset(120, 80));

      expect(provider.moveStateCalls, hasLength(1));
      expect(controller.undo(), isTrue);
      expect(controller.nodePosition(id), const Offset(-48, -48));
      expect(controller.undo(), isTrue);
      expect(controller.nodeById(id), isNull);
    });

    test('updateStateLabel normalises empty labels', () {
      controller.addStateAt(const Offset(0, 0));
      final id = provider.addStateCalls.first['id'] as String;

      controller.updateStateLabel(id, '');

      expect(provider.updateLabelCalls, hasLength(1));
      expect(provider.updateLabelCalls.single['label'], equals(id));
    });

    test('addOrUpdateTransition sends payload to provider', () {
      controller.addStateAt(const Offset(0, 0));
      controller.addStateAt(const Offset(200, 0));
      final fromId = provider.addStateCalls[0]['id'] as String;
      final toId = provider.addStateCalls[1]['id'] as String;

      controller.addOrUpdateTransition(
        fromStateId: fromId,
        toStateId: toId,
        label: 'a',
        controlPointX: 100,
        controlPointY: -40,
      );

      expect(provider.transitionCalls, hasLength(1));
      final call = provider.transitionCalls.single;
      expect(call['fromStateId'], equals(fromId));
      expect(call['toStateId'], equals(toId));
      expect(call['label'], equals('a'));
      expect(call['controlPointX'], closeTo(100, 0.0001));
      expect(call['controlPointY'], closeTo(-40, 0.0001));
    });

    test(
      'graph edge metadata survives create, edit, undo, redo, and external synchronize',
      () {
        recreateController(inspectable: true);
        controller.addStateAt(const Offset(0, 0));
        controller.addStateAt(const Offset(200, 0));
        final fromId = provider.addStateCalls[0]['id'] as String;
        final toId = provider.addStateCalls[1]['id'] as String;

        controller.addOrUpdateTransition(
          fromStateId: fromId,
          toStateId: toId,
          label: 'a',
          controlPointX: 100,
          controlPointY: -40,
        );

        final createdId = provider.transitionCalls.single['id'] as String;
        final createdEdge = controller.graphEdgeById(createdId);
        expect(createdEdge, isNotNull);
        expect(createdEdge!.label, equals('a'));
        expect(createdEdge.controlPoint, equals(const Offset(100, -40)));

        controller.addOrUpdateTransition(
          transitionId: createdId,
          fromStateId: fromId,
          toStateId: toId,
          label: 'edited',
          controlPointX: 132,
          controlPointY: -12,
        );

        final editedEdge = controller.graphEdgeById(createdId);
        expect(identical(createdEdge, editedEdge), isTrue);
        expect(editedEdge!.label, equals('edited'));
        expect(editedEdge.controlPoint, equals(const Offset(132, -12)));

        expect(controller.undo(), isTrue);
        final undoneEdge = controller.graphEdgeById(createdId);
        expect(undoneEdge, isNotNull);
        expect(undoneEdge!.label, equals('a'));
        expect(undoneEdge.controlPoint, equals(const Offset(100, -40)));

        expect(controller.redo(), isTrue);
        final redoneEdge = controller.graphEdgeById(createdId);
        expect(redoneEdge, isNotNull);
        expect(redoneEdge!.label, equals('edited'));
        expect(redoneEdge.controlPoint, equals(const Offset(132, -12)));

        final currentAutomaton = provider.state.currentAutomaton!;
        final syncTransition = FSATransition(
          id: createdId,
          fromState: currentAutomaton.states.singleWhere(
            (state) => state.id == fromId,
          ),
          toState:
              currentAutomaton.states.singleWhere((state) => state.id == toId),
          label: 's',
          inputSymbols: const {'s'},
          controlPoint: Vector2(168, 24),
        );

        provider.updateAutomaton(
          FSA(
            id: currentAutomaton.id,
            name: currentAutomaton.name,
            states: currentAutomaton.states,
            transitions: {syncTransition},
            alphabet: const {'s'},
            initialState: currentAutomaton.initialState,
            acceptingStates: currentAutomaton.acceptingStates,
            created: currentAutomaton.created,
            modified: currentAutomaton.modified,
            bounds: currentAutomaton.bounds,
            panOffset: currentAutomaton.panOffset,
            zoomLevel: currentAutomaton.zoomLevel,
          ),
        );

        controller.synchronize(provider.state.currentAutomaton);

        final synchronizedEdge = controller.graphEdgeById(createdId);
        expect(synchronizedEdge, isNotNull);
        expect(synchronizedEdge!.label, equals('s'));
        expect(synchronizedEdge.controlPoint, equals(const Offset(168, 24)));
      },
    );

    test('synchronize mirrors provider state into controller caches', () {
      final stateA = automaton_state.State(
        id: 'qa',
        label: 'qa',
        position: Vector2(32, 64),
        isInitial: true,
        isAccepting: false,
      );
      final stateB = automaton_state.State(
        id: 'qb',
        label: 'qb',
        position: Vector2(180, 120),
        isInitial: false,
        isAccepting: true,
      );
      final transition = FSATransition(
        id: 't0',
        fromState: stateA,
        toState: stateB,
        inputSymbols: {'a'},
        label: 'a',
        controlPoint: Vector2(120, 40),
      );

      final automaton = FSA(
        id: 'auto',
        name: 'Automaton',
        states: {stateA, stateB},
        transitions: {transition},
        alphabet: {'a'},
        initialState: stateA,
        acceptingStates: {stateB},
        created: DateTime.utc(2024, 1, 1),
        modified: DateTime.utc(2024, 1, 1),
        bounds: const math.Rectangle<double>(0, 0, 400, 300),
      );

      controller.synchronize(automaton);

      final cachedNode = controller.nodeById('qa');
      expect(cachedNode, isNotNull);
      expect(cachedNode!.x, closeTo(32, 0.0001));
      expect(cachedNode.y, closeTo(64, 0.0001));

      final cachedEdge = controller.edgeById('t0');
      expect(cachedEdge, isNotNull);
      expect(cachedEdge!.fromStateId, equals('qa'));
      expect(cachedEdge.toStateId, equals('qb'));
      expect(cachedEdge.controlPointX, closeTo(120, 0.0001));
      expect(cachedEdge.controlPointY, closeTo(40, 0.0001));
    });

    test('clearCanvas preserves FSA metadata and participates in history', () {
      final initialState = automaton_state.State(
        id: 'q0',
        label: 'start',
        position: Vector2.zero(),
        isInitial: true,
      );
      final acceptingState = automaton_state.State(
        id: 'q1',
        label: 'accept',
        position: Vector2(120, 0),
        isAccepting: true,
      );
      final transition = FSATransition(
        id: 't0',
        fromState: initialState,
        toState: acceptingState,
        inputSymbols: const {'a'},
        label: 'a',
      );
      final automaton = FSA(
        id: 'clear-fsa',
        name: 'Configured FSA',
        states: {initialState, acceptingState},
        transitions: {transition},
        alphabet: const {'a', 'unused'},
        initialState: initialState,
        acceptingStates: {acceptingState},
        created: DateTime.utc(2024, 1, 1),
        modified: DateTime.utc(2024, 1, 1),
        bounds: const math.Rectangle<double>(0, 0, 400, 300),
      );
      provider.updateAutomaton(automaton);
      controller.synchronize(automaton);

      expect(controller.clearCanvas(), isTrue);
      final cleared = provider.state.currentAutomaton;
      expect(cleared, isNotNull);
      expect(cleared!.id, 'clear-fsa');
      expect(cleared.name, 'Configured FSA');
      expect(cleared.alphabet, {'a', 'unused'});
      expect(cleared.states, isEmpty);
      expect(cleared.transitions, isEmpty);
      expect(controller.clearCanvas(), isFalse);

      expect(controller.undo(), isTrue);
      expect(provider.state.currentAutomaton!.states, hasLength(2));
      expect(provider.state.currentAutomaton!.transitions, hasLength(1));

      expect(controller.redo(), isTrue);
      expect(provider.state.currentAutomaton!.states, isEmpty);
      expect(provider.state.currentAutomaton!.transitions, isEmpty);
    });

    test('external synchronize clears undo history and notifies listeners', () {
      final stateA = automaton_state.State(
        id: 'qa',
        label: 'qa',
        position: Vector2(0, 0),
        isInitial: true,
        isAccepting: false,
      );
      final automatonA = FSA(
        id: 'auto_a',
        name: 'Automaton A',
        states: {stateA},
        transitions: const {},
        alphabet: const {'a'},
        initialState: stateA,
        acceptingStates: const {},
        created: DateTime.utc(2024, 1, 1),
        modified: DateTime.utc(2024, 1, 1),
        bounds: const math.Rectangle<double>(0, 0, 400, 300),
      );

      provider.updateAutomaton(automatonA);
      controller.synchronize(automatonA);

      controller.addStateAt(const Offset(120, 80));
      expect(controller.canUndo, isTrue);

      final stateB = automaton_state.State(
        id: 'qb',
        label: 'qb',
        position: Vector2(200, 0),
        isInitial: true,
        isAccepting: false,
      );
      final automatonB = FSA(
        id: 'auto_b',
        name: 'Automaton B',
        states: {stateB},
        transitions: const {},
        alphabet: const {'b'},
        initialState: stateB,
        acceptingStates: const {},
        created: DateTime.utc(2024, 2, 1),
        modified: DateTime.utc(2024, 2, 1),
        bounds: const math.Rectangle<double>(0, 0, 400, 300),
      );

      provider.updateAutomaton(automatonB);
      final revisionBeforeExternalSync = controller.graphRevision.value;
      controller.synchronize(automatonB);

      expect(controller.canUndo, isFalse);
      expect(controller.undo(), isFalse);
      expect(provider.state.currentAutomaton?.id, equals('auto_b'));
      expect(
        controller.graphRevision.value,
        greaterThan(revisionBeforeExternalSync),
      );
    });

    test('domain echoes preserve mutation and restoration history', () {
      controller.addStateAt(const Offset(120, 80));
      expect(controller.canUndo, isTrue);

      controller.synchronize(provider.state.currentAutomaton);

      expect(controller.canUndo, isTrue);
      expect(controller.undo(), isTrue);
      expect(controller.canRedo, isTrue);

      controller.synchronize(provider.state.currentAutomaton);

      expect(controller.canRedo, isTrue);
      expect(controller.redo(), isTrue);
    });

    test('complete replacement and sidecar share one undo/redo entry', () {
      final importedState = automaton_state.State(
        id: 'imported',
        label: 'Imported',
        position: Vector2(120, 80),
        isInitial: true,
      );
      final replacement = provider.state.currentAutomaton!.copyWith(
        states: {importedState},
        initialState: importedState,
      );
      final companion = _RecordingHistoryCompanion();

      controller.replaceDocumentAsMutation(
        replacement,
        companion: companion,
      );

      expect(provider.state.currentAutomaton!.states, {importedState});
      expect(controller.canUndo, isTrue);
      expect(controller.undo(), isTrue);
      expect(provider.state.currentAutomaton!.states, isEmpty);
      expect(companion.undoCalls, 1);
      expect(controller.canUndo, isFalse);
      expect(controller.canRedo, isTrue);

      expect(controller.redo(), isTrue);
      expect(provider.state.currentAutomaton!.states, {importedState});
      expect(companion.redoCalls, 1);
      expect(controller.canUndo, isTrue);
    });

    test('undo preserves an atomic FSA symbol containing a comma', () {
      final initialState = automaton_state.State(
        id: 'q0',
        label: 'q0',
        position: Vector2.zero(),
        isInitial: true,
      );
      final acceptingState = automaton_state.State(
        id: 'q1',
        label: 'q1',
        position: Vector2(120, 0),
        isAccepting: true,
      );
      final transition = FSATransition(
        id: 'comma-transition',
        fromState: initialState,
        toState: acceptingState,
        inputSymbols: const {'a,b'},
        label: 'a,b',
      );
      final automaton = FSA(
        id: 'comma-automaton',
        name: 'Comma symbol',
        states: {initialState, acceptingState},
        transitions: {transition},
        alphabet: const {'a,b'},
        initialState: initialState,
        acceptingStates: {acceptingState},
        created: DateTime.utc(2024, 1, 1),
        modified: DateTime.utc(2024, 1, 1),
        bounds: const math.Rectangle<double>(0, 0, 400, 300),
      );
      provider.updateAutomaton(automaton);
      controller.synchronize(automaton);

      controller.moveState('q0', const Offset(40, 20));
      expect(controller.undo(), isTrue);

      expect(
        provider.state.currentAutomaton!.fsaTransitions.single.inputSymbols,
        {'a,b'},
      );
    });

    test('undo safely discards a snapshot with a dangling edge', () {
      final presentState = automaton_state.State(
        id: 'present',
        label: 'present',
        position: Vector2.zero(),
        isInitial: true,
      );
      final missingState = automaton_state.State(
        id: 'missing',
        label: 'missing',
        position: Vector2(100, 0),
      );
      final danglingTransition = FSATransition(
        id: 'dangling',
        fromState: presentState,
        toState: missingState,
        inputSymbols: const {'a'},
        label: 'a',
      );
      final corruptAutomaton = FSA(
        id: 'corrupt',
        name: 'Corrupt history source',
        states: {presentState},
        transitions: {danglingTransition},
        alphabet: const {'a'},
        initialState: presentState,
        acceptingStates: const {},
        created: DateTime.utc(2024, 1, 1),
        modified: DateTime.utc(2024, 1, 1),
        bounds: const math.Rectangle<double>(0, 0, 400, 300),
      );
      provider.updateAutomaton(corruptAutomaton);
      controller.synchronize(corruptAutomaton);

      controller.addStateAt(const Offset(200, 100));
      final stateIdsBeforeUndo = provider.state.currentAutomaton!.states
          .map((state) => state.id)
          .toSet();

      bool? restored;
      expect(() => restored = controller.undo(), returnsNormally);
      expect(restored, isFalse);
      expect(
        provider.state.currentAutomaton!.states
            .map((state) => state.id)
            .toSet(),
        stateIdsBeforeUndo,
      );
      expect(controller.canRedo, isFalse);
    });

    test('enforces undo history limit by discarding oldest entries', () {
      recreateController(historyLimit: 3);

      controller.addStateAt(const Offset(10, 10));
      controller.addStateAt(const Offset(20, 20));
      controller.addStateAt(const Offset(30, 30));
      controller.addStateAt(const Offset(40, 40));

      expect(controller.undo(), isTrue);
      expect(controller.undo(), isTrue);
      expect(controller.undo(), isTrue);
      expect(controller.undo(), isFalse);
    });

    test('dispose clears caches and history buffers', () {
      controller.addStateAt(const Offset(50, 50));
      controller.addStateAt(const Offset(70, 70));

      expect(controller.canUndo, isTrue);
      expect(controller.nodesCache, isNotEmpty);

      controller.dispose();
      controllerDisposed = true;

      expect(controller.canUndo, isFalse);
      expect(controller.canRedo, isFalse);
      expect(controller.nodesCache, isEmpty);
      expect(controller.edgesCache, isEmpty);
    });

    test('evicts caches when snapshot exceeds configured threshold', () {
      recreateController(cacheEvictionThreshold: 1, inspectable: true);
      final inspectable = controller as _InspectableGraphViewCanvasController;

      final s0_1 = automaton_state.State(
        id: 's0',
        label: 's0',
        position: Vector2.zero(),
      );
      final s1_1 = automaton_state.State(
        id: 's1',
        label: 's1',
        position: Vector2(100, 0),
      );
      provider.updateAutomaton(
        FSA(
          id: 'auto',
          name: 'Automaton',
          states: {s0_1, s1_1},
          transitions: const {},
          alphabet: const {},
          initialState: s0_1,
          acceptingStates: {s1_1},
          created: DateTime.utc(2024, 1, 1),
          modified: DateTime.utc(2024, 1, 1),
          bounds: const math.Rectangle<double>(0, 0, 400, 300),
          panOffset: Vector2.zero(),
          zoomLevel: 1,
        ),
      );
      inspectable.synchronize(provider.state.currentAutomaton);
      final previousNode = inspectable.debugGraphNodes['s0'];
      expect(previousNode, isNotNull);

      final s0_2 = automaton_state.State(
        id: 's0',
        label: 's0',
        position: Vector2.zero(),
      );
      final s1_2 = automaton_state.State(
        id: 's1',
        label: 's1',
        position: Vector2(100, 0),
      );
      final s2_2 = automaton_state.State(
        id: 's2',
        label: 's2',
        position: Vector2(200, 0),
      );
      provider.updateAutomaton(
        FSA(
          id: 'auto',
          name: 'Automaton',
          states: {s0_2, s1_2, s2_2},
          transitions: {
            FSATransition(
              id: 't0',
              fromState: s0_2,
              toState: s1_2,
              symbol: 'a',
            ),
            FSATransition(
              id: 't1',
              fromState: s1_2,
              toState: s2_2,
              symbol: 'b',
            ),
          },
          alphabet: const {'a', 'b'},
          initialState: s0_2,
          acceptingStates: {s2_2},
          created: DateTime.utc(2024, 1, 1),
          modified: DateTime.utc(2024, 1, 1),
          bounds: const math.Rectangle<double>(0, 0, 400, 300),
          panOffset: Vector2.zero(),
          zoomLevel: 1,
        ),
      );

      inspectable.synchronize(provider.state.currentAutomaton);

      final updatedNode = inspectable.debugGraphNodes['s0'];
      expect(updatedNode, isNotNull);
      expect(identical(previousNode, updatedNode), isFalse);
      expect(inspectable.debugGraphEdges.length, equals(2));
      expect(inspectable.nodesCache.length, equals(3));
    });
  });
}
