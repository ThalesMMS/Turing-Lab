//
//  graphview_pda_canvas_controller_test.dart
//  Turing Lab
//
//  Evaluates GraphViewPdaCanvasController as the bridge between the PDA editor
//  and the canvas, keeping transitions in sync with the stack. Exercises graph
//  construction, element selection, and safe disposal of associated resources.
//
//  Thales Matheus Mendonça Santos - October 2025
//

import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vector_math/vector_math_64.dart';

import 'package:turing_lab/core/constants/automaton_canvas_constants.dart';
import 'package:turing_lab/core/models/pda.dart';
import 'package:turing_lab/core/models/pda_transition.dart';
import 'package:turing_lab/core/models/state.dart' as automaton_state;
import 'package:turing_lab/core/models/transition.dart';
import 'package:turing_lab/features/canvas/graphview/graphview_canvas_models.dart';
import 'package:turing_lab/features/canvas/graphview/graphview_pda_canvas_controller.dart';
import 'package:turing_lab/presentation/providers/pda_editor_provider.dart';

import 'support/recording_graph_view_controller.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('GraphViewPdaCanvasController', () {
    late PDAEditorNotifier notifier;
    late GraphViewPdaCanvasController controller;

    setUp(() {
      notifier = PDAEditorNotifier();
      controller = GraphViewPdaCanvasController(editorNotifier: notifier);
    });

    tearDown(() {
      controller.dispose();
    });

    PDA buildSamplePda() {
      final initialState = automaton_state.State(
        id: 'q0',
        label: 'start',
        position: Vector2.zero(),
        isInitial: true,
        isAccepting: false,
      );
      final acceptingState = automaton_state.State(
        id: 'q1',
        label: 'accept',
        position: Vector2(160, 120),
        isInitial: false,
        isAccepting: true,
      );
      final transition = PDATransition(
        id: 't0',
        fromState: initialState,
        toState: acceptingState,
        label: 'a, Z/ZZ',
        controlPoint: Vector2(40, 30),
        type: TransitionType.deterministic,
        inputSymbol: 'a',
        popSymbol: 'Z',
        pushSymbol: 'ZZ',
        isLambdaInput: false,
        isLambdaPop: false,
        isLambdaPush: false,
      );
      return PDA(
        id: 'pda-1',
        name: 'Sample PDA',
        states: {initialState, acceptingState},
        transitions: {transition},
        alphabet: {'a'},
        initialState: initialState,
        acceptingStates: {acceptingState},
        created: DateTime.utc(2023, 1, 1),
        modified: DateTime.utc(2023, 1, 1),
        bounds: const math.Rectangle<double>(0, 0, 400, 300),
        stackAlphabet: {'Z'},
        initialStackSymbol: 'Z',
        zoomLevel: 1,
        panOffset: Vector2.zero(),
      );
    }

    test('fitToContent uses the shared 1.75 scale cap', () {
      controller.dispose();
      final transformation = TransformationController();
      addTearDown(transformation.dispose);
      final viewController = RecordingGraphViewController(transformation);
      controller = GraphViewPdaCanvasController(
        editorNotifier: notifier,
        viewController: viewController,
      );
      final pda = buildSamplePda();
      notifier.setPda(pda);
      controller
        ..synchronize(pda)
        ..updateViewportSize(const Size(1000, 800))
        ..fitToContent();

      expect(viewController.lastTarget, isNotNull);
      expect(
        viewController.lastTarget!.getMaxScaleOnAxis(),
        closeTo(kAutomatonCanvasFitMaxScale, 0.0001),
      );
    });

    test('dispose leaves a caller-owned transformation usable', () {
      controller.dispose();
      final transformation = TransformationController();
      controller = GraphViewPdaCanvasController(
        editorNotifier: notifier,
        transformationController: transformation,
      );

      controller.dispose();

      expect(
        () => transformation.value = Matrix4.identity()
          ..translateByDouble(1.0, 0.0, 0.0, 1.0),
        returnsNormally,
      );
      transformation.dispose();
    });

    test('synchronize populates nodes and edges from PDA', () {
      final pda = buildSamplePda();

      controller.synchronize(pda);

      final node = controller.nodeById('q0');
      expect(node, isNotNull);
      expect(node!.label, equals('start'));
      final edge = controller.edgeById('t0');
      expect(edge, isNotNull);
      expect(edge!.readSymbol, equals('a'));
    });

    test('clearCanvas preserves PDA configuration and participates in history',
        () {
      final pda = buildSamplePda().copyWith(
        alphabet: {'a', 'unused-input'},
        stackAlphabet: {'Z', 'S_0', 'unused-stack'},
        initialStackSymbol: 'S_0',
      );
      notifier.setPda(pda);
      controller.synchronize(pda);

      expect(controller.clearCanvas(), isTrue);
      final cleared = notifier.state.pda;
      expect(cleared, isNotNull);
      expect(cleared!.id, 'pda-1');
      expect(cleared.name, 'Sample PDA');
      expect(cleared.alphabet, {'a', 'unused-input'});
      expect(cleared.stackAlphabet, {'Z', 'S_0', 'unused-stack'});
      expect(cleared.initialStackSymbol, 'S_0');
      expect(cleared.states, isEmpty);
      expect(cleared.transitions, isEmpty);
      expect(controller.clearCanvas(), isFalse);

      expect(controller.undo(), isTrue);
      expect(notifier.state.pda!.states, hasLength(2));
      expect(notifier.state.pda!.pdaTransitions, hasLength(1));

      expect(controller.redo(), isTrue);
      expect(notifier.state.pda!.states, isEmpty);
      expect(notifier.state.pda!.transitions, isEmpty);
    });

    test('replacePda is recorded as one undoable operation', () {
      final source = buildSamplePda();
      notifier.setPda(source);
      controller.synchronize(source);
      final replacement = source.copyWith(
        name: 'Simplified PDA',
        transitions: const {},
        alphabet: const {},
        modified: DateTime.utc(2026, 1, 1),
      );

      controller.replacePda(replacement);

      expect(notifier.currentPda, same(replacement));
      expect(controller.canUndo, isTrue);
      expect(controller.undo(), isTrue);
      expect(notifier.currentPda!.name, source.name);
      expect(notifier.currentPda!.pdaTransitions, hasLength(1));
      expect(controller.canUndo, isFalse);
      expect(controller.canRedo, isTrue);
    });

    test('addStateAt inserts state into notifier', () {
      controller.addStateAt(const Offset(24, 48));

      final pda = notifier.state.pda;
      expect(pda, isNotNull);
      expect(pda!.states.length, equals(1));
      final state = pda.states.single;
      expect(state.position.x, closeTo(-24, 0.0001));
      expect(state.position.y, closeTo(0, 0.0001));
      expect(state.label, isNotEmpty);
    });

    test('addStateAt skips used PDA ids and labels after sync', () {
      final firstState = automaton_state.State(
        id: 'state_0',
        label: 'q0',
        position: Vector2.zero(),
        isInitial: true,
        isAccepting: false,
      );
      final laterState = automaton_state.State(
        id: 'state_2',
        label: 'q2',
        position: Vector2(80, 40),
        isInitial: false,
        isAccepting: false,
      );
      final pda = PDA(
        id: 'pda-gapped',
        name: 'Gapped PDA',
        states: {firstState, laterState},
        transitions: const {},
        alphabet: const {},
        initialState: firstState,
        acceptingStates: const {},
        created: DateTime.utc(2023, 1, 1),
        modified: DateTime.utc(2023, 1, 1),
        bounds: const math.Rectangle<double>(0, 0, 400, 300),
        stackAlphabet: const {'Z'},
        initialStackSymbol: 'Z',
        zoomLevel: 1,
        panOffset: Vector2.zero(),
      );
      notifier.setPda(pda);
      controller.synchronize(pda);

      controller.addStateAt(const Offset(24, 48));

      final inserted = notifier.state.pda!.states.singleWhere(
        (state) => state.id == 'state_1',
      );
      expect(inserted.label, equals('q1'));
      expect(inserted.position.x, closeTo(-24, 0.0001));
      expect(inserted.position.y, closeTo(0, 0.0001));
    });

    test('addStateAtCenter maps viewport centre to PDA world coordinates', () {
      final transformation =
          controller.graphController.transformationController;
      expect(transformation, isNotNull);
      controller.updateViewportSize(const Size(700, 500));

      transformation!.value = Matrix4.identity();
      controller.addStateAtCenter();

      var pda = notifier.state.pda;
      expect(pda, isNotNull);
      var states = pda!.states.toList(growable: false);
      expect(states, hasLength(1));
      expect(states.first.position.x, closeTo(302, 0.0001));
      expect(states.first.position.y, closeTo(202, 0.0001));

      transformation.value = Matrix4.identity()
        ..translateByDouble(60.0, 140.0, 0.0, 1.0)
        ..scaleByDouble(1.2, 1.2, 1.2, 1.0);
      controller.addStateAtCenter();

      pda = notifier.state.pda;
      expect(pda, isNotNull);
      states = pda!.states.toList(growable: false);
      expect(states, hasLength(2));
      final newest = states.last;
      expect(newest.position.x, closeTo((350 - 60) / 1.2 - 48, 0.0001));
      expect(newest.position.y, closeTo((250 - 140) / 1.2 - 48, 0.0001));
    });

    test('addOrUpdateTransition writes transition metadata', () {
      controller.addStateAt(const Offset(0, 0));
      controller.addStateAt(const Offset(120, 80));
      final pda = notifier.state.pda!;
      final statesById = {for (final state in pda.states) state.id: state};

      controller.addOrUpdateTransition(
        fromStateId: statesById.keys.first,
        toStateId: statesById.keys.last,
        readSymbol: 'a',
        popSymbol: 'Z',
        pushSymbol: 'S_0Z',
        pushSymbols: const ['S_0', 'Z'],
        isLambdaInput: false,
        isLambdaPop: false,
        isLambdaPush: false,
      );

      final transitionId = notifier.state.pda!.pdaTransitions.single.id;
      controller.addOrUpdateTransition(
        fromStateId: statesById.keys.first,
        toStateId: statesById.keys.last,
        transitionId: transitionId,
        controlPointX: 35,
        controlPointY: 45,
      );

      final updated = notifier.state.pda!;
      expect(updated.pdaTransitions, hasLength(1));
      final transition = updated.pdaTransitions.single;
      expect(transition.inputSymbol, equals('a'));
      expect(transition.popSymbol, equals('Z'));
      expect(transition.pushSymbol, equals('S_0Z'));
      expect(transition.pushSymbols, ['S_0', 'Z']);
      expect(transition.controlPoint, Vector2(35, 45));
      expect(updated.validate(), isEmpty);
    });

    test('removeTransition clears transition from notifier', () {
      final pda = buildSamplePda();
      notifier.setPda(pda);
      controller.synchronize(pda);

      controller.removeTransition('t0');

      final updated = notifier.state.pda!;
      expect(updated.pdaTransitions, isEmpty);
    });

    test('applySnapshotToDomain rebuilds PDA and synchronizes controller', () {
      const snapshot = GraphViewAutomatonSnapshot(
        nodes: [
          GraphViewCanvasNode(
            id: 'q0',
            label: 'start',
            x: 10,
            y: 20,
            isInitial: true,
            isAccepting: false,
          ),
          GraphViewCanvasNode(
            id: 'q1',
            label: 'accept',
            x: 180,
            y: 120,
            isInitial: false,
            isAccepting: true,
          ),
        ],
        edges: [
          GraphViewCanvasEdge(
            id: 't0',
            fromStateId: 'q0',
            toStateId: 'q1',
            symbols: <String>[],
            controlPointX: 42,
            controlPointY: 32,
            readSymbol: 'b',
            popSymbol: 'Z',
            pushSymbol: 'XZ',
            isLambdaInput: false,
            isLambdaPop: false,
            isLambdaPush: false,
          ),
        ],
        metadata: GraphViewAutomatonMetadata(
          id: 'pda-1',
          name: 'Snapshot PDA',
          alphabet: ['a', 'b'],
          stackAlphabet: ['S_0', 'unused-stack-symbol'],
          initialStackSymbol: 'S_0',
        ),
      );

      controller.applySnapshotToDomain(snapshot);

      final rebuilt = notifier.state.pda;
      expect(rebuilt, isNotNull);
      expect(rebuilt!.states.length, equals(2));
      expect(rebuilt.pdaTransitions.single.inputSymbol, equals('b'));
      expect(
          rebuilt.stackAlphabet, containsAll({'S_0', 'unused-stack-symbol'}));
      expect(rebuilt.initialStackSymbol, 'S_0');
      expect(rebuilt.validate(), isEmpty);
      expect(controller.nodeById('q0'), isNotNull);
      expect(controller.edgeById('t0'), isNotNull);
    });
  });
}
