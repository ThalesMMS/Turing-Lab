//
//  graphview_tm_canvas_controller_test.dart
//  Turing Lab
//
//  Verifica o GraphViewTmCanvasController na orquestração do editor de máquinas de Turing,
//  garantindo que o grafo responda a interações e eventos emitidos pelo provider. Analisa seleção
//  de estados, atualização de transições e ciclo de vida do controlador.
//
//  Thales Matheus Mendonça Santos - October 2025
//

import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vector_math/vector_math_64.dart';

import 'package:turing_lab/core/models/state.dart' as automaton_state;
import 'package:turing_lab/core/models/tm.dart';
import 'package:turing_lab/core/models/tm_transition.dart';
import 'package:turing_lab/core/models/transition.dart';
import 'package:turing_lab/features/canvas/graphview/graphview_canvas_models.dart';
import 'package:turing_lab/features/canvas/graphview/graphview_tm_canvas_controller.dart';
import 'package:turing_lab/presentation/providers/tm_editor_provider.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('GraphViewTmCanvasController', () {
    late TMEditorNotifier notifier;
    late GraphViewTmCanvasController controller;

    setUp(() {
      notifier = TMEditorNotifier();
      controller = GraphViewTmCanvasController(editorNotifier: notifier);
    });

    tearDown(() {
      controller.dispose();
    });

    TM buildSampleTm() {
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
        position: Vector2(200, 120),
        isInitial: false,
        isAccepting: true,
      );
      final transition = TMTransition(
        id: 't0',
        fromState: initialState,
        toState: acceptingState,
        label: 'a/b,R',
        controlPoint: Vector2(42, 30),
        type: TransitionType.deterministic,
        readSymbol: 'a',
        writeSymbol: 'b',
        direction: TapeDirection.right,
      );
      return TM(
        id: 'tm-1',
        name: 'Sample TM',
        states: {initialState, acceptingState},
        transitions: {transition},
        alphabet: {'a', 'b'},
        initialState: initialState,
        acceptingStates: {acceptingState},
        created: DateTime.utc(2023, 1, 1),
        modified: DateTime.utc(2023, 1, 1),
        bounds: const math.Rectangle<double>(0, 0, 400, 300),
        tapeAlphabet: {'a', 'b', 'B'},
        blankSymbol: 'B',
        tapeCount: 1,
        panOffset: Vector2.zero(),
        zoomLevel: 1,
      );
    }

    test('synchronize populates TM nodes and edges', () {
      final tm = buildSampleTm();

      controller.synchronize(tm);

      final node = controller.nodeById('q0');
      expect(node, isNotNull);
      expect(node!.label, equals('start'));
      final edge = controller.edgeById('t0');
      expect(edge, isNotNull);
      expect(edge!.readSymbol, equals('a'));
      expect(edge.writeSymbol, equals('b'));
    });

    test('addStateAt inserts state into notifier', () {
      controller.addStateAt(const Offset(12, 24));

      final tm = notifier.state.tm;
      expect(tm, isNotNull);
      expect(tm!.states.length, equals(1));
      final state = tm.states.single;
      expect(state.position.x, closeTo(-36, 0.0001));
      expect(state.position.y, closeTo(-24, 0.0001));
    });

    test('addStateAt skips used TM ids and labels after sync', () {
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
        position: Vector2(100, 60),
        isInitial: false,
        isAccepting: false,
      );
      final tm = TM(
        id: 'tm-gapped',
        name: 'Gapped TM',
        states: {firstState, laterState},
        transitions: const {},
        alphabet: const {},
        initialState: firstState,
        acceptingStates: const {},
        created: DateTime.utc(2023, 1, 1),
        modified: DateTime.utc(2023, 1, 1),
        bounds: const math.Rectangle<double>(0, 0, 400, 300),
        tapeAlphabet: const {'B'},
        blankSymbol: 'B',
        tapeCount: 1,
        panOffset: Vector2.zero(),
        zoomLevel: 1,
      );
      notifier.setTm(tm);
      controller.synchronize(tm);

      controller.addStateAt(const Offset(12, 24));

      final inserted = notifier.state.tm!.states.singleWhere(
        (state) => state.id == 'state_1',
      );
      expect(inserted.label, equals('q1'));
      expect(inserted.position.x, closeTo(-36, 0.0001));
      expect(inserted.position.y, closeTo(-24, 0.0001));
    });

    test('addStateAtCenter resolves world position from viewport centre', () {
      final transformation =
          controller.graphController.transformationController;
      expect(transformation, isNotNull);
      controller.updateViewportSize(const Size(600, 400));

      transformation!.value = Matrix4.identity();
      controller.addStateAtCenter();

      var tm = notifier.state.tm;
      expect(tm, isNotNull);
      var states = tm!.states.toList(growable: false);
      expect(states, hasLength(1));
      expect(states.first.position.x, closeTo(252, 0.0001));
      expect(states.first.position.y, closeTo(152, 0.0001));

      transformation.value = Matrix4.identity()
        ..translateByDouble(-120.0, 80.0, 0.0, 1.0)
        ..scaleByDouble(0.8, 0.8, 0.8, 1.0);
      controller.addStateAtCenter();

      tm = notifier.state.tm;
      expect(tm, isNotNull);
      states = tm!.states.toList(growable: false);
      expect(states, hasLength(2));
      final latest = states.last;
      expect(latest.position.x, closeTo((300 - (-120)) / 0.8 - 48, 0.0001));
      expect(latest.position.y, closeTo((200 - 80) / 0.8 - 48, 0.0001));
    });

    test('addOrUpdateTransition stores TM transition data', () {
      controller.addStateAt(const Offset(0, 0));
      controller.addStateAt(const Offset(160, 100));
      final tm = notifier.state.tm!;
      final stateIds = tm.states.map((state) => state.id).toList();

      controller.addOrUpdateTransition(
        fromStateId: stateIds.first,
        toStateId: stateIds.last,
        readSymbol: '1',
        writeSymbol: '0',
        direction: TapeDirection.left,
      );

      final updated = notifier.state.tm!;
      expect(updated.tmTransitions, hasLength(1));
      final transition = updated.tmTransitions.single;
      expect(transition.readSymbol, equals('1'));
      expect(transition.writeSymbol, equals('0'));
      expect(transition.direction, equals(TapeDirection.left));
    });

    test('removeTransition removes TM transition', () {
      final tm = buildSampleTm();
      notifier.setTm(tm);
      controller.synchronize(tm);

      controller.removeTransition('t0');

      final updated = notifier.state.tm!;
      expect(updated.tmTransitions, isEmpty);
    });

    test('applySnapshotToDomain rebuilds TM and synchronizes controller', () {
      const snapshot = GraphViewAutomatonSnapshot(
        nodes: [
          GraphViewCanvasNode(
            id: 'q0',
            label: 'start',
            x: 20,
            y: 30,
            isInitial: true,
            isAccepting: false,
          ),
          GraphViewCanvasNode(
            id: 'q1',
            label: 'accept',
            x: 200,
            y: 150,
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
            controlPointX: 50,
            controlPointY: 42,
            readSymbol: '0',
            writeSymbol: 'X',
            direction: TapeDirection.stay,
          ),
        ],
        metadata: GraphViewAutomatonMetadata(
          id: 'tm-1',
          name: 'Snapshot TM',
          alphabet: ['0', '1'],
          tapeAlphabet: ['0', '1', 'X', 'B'],
          blankSymbol: 'B',
          tapeCount: 1,
        ),
      );

      controller.applySnapshotToDomain(snapshot);

      final rebuilt = notifier.state.tm;
      expect(rebuilt, isNotNull);
      expect(rebuilt!.states.length, equals(2));
      final transition = rebuilt.tmTransitions.single;
      expect(transition.readSymbol, equals('0'));
      expect(transition.writeSymbol, equals('X'));
      expect(transition.direction, equals(TapeDirection.stay));
      expect(rebuilt.alphabet, containsAll({'0', '1'}));
      expect(rebuilt.alphabet, isNot(contains('X')));
      expect(rebuilt.tapeAlphabet, containsAll({'0', '1', 'X', 'B'}));
      expect(rebuilt.blankSymbol, 'B');
      expect(rebuilt.validate(), isEmpty);
      expect(controller.nodeById('q0'), isNotNull);
      expect(controller.edgeById('t0'), isNotNull);
    });
  });
}
