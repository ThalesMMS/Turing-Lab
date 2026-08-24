//
//  graphview_tm_mapper_test.dart
//  Turing Lab
//
//  Evaluates GraphViewTmMapper when generating Turing machine graphs, including
//  states, transitions, and tape directions. Simulates multiple tapes and
//  annotations so rendered data matches simulator operations.
//
//  Thales Matheus Mendonça Santos - October 2025
//

import 'dart:math' as math;

import 'package:test/test.dart';
import 'package:vector_math/vector_math_64.dart';

import 'package:turing_lab/core/models/state.dart';
import 'package:turing_lab/core/models/tm.dart';
import 'package:turing_lab/core/models/tm_transition.dart';
import 'package:turing_lab/core/models/transition.dart';
import 'package:turing_lab/features/canvas/graphview/graphview_canvas_models.dart';
import 'package:turing_lab/features/canvas/graphview/graphview_tm_mapper.dart';

void main() {
  group('GraphViewTmMapper', () {
    late State initialState;
    late State acceptingState;
    late TMTransition transition;
    late TM machine;

    setUp(() {
      initialState = State(
        id: 'q0',
        label: 'start',
        position: Vector2.zero(),
        isInitial: true,
        isAccepting: false,
      );
      acceptingState = State(
        id: 'q1',
        label: 'accept',
        position: Vector2(200, 140),
        isInitial: false,
        isAccepting: true,
      );
      transition = TMTransition(
        id: 't0',
        fromState: initialState,
        toState: acceptingState,
        label: 'a/b,R',
        controlPoint: Vector2(32, 28),
        type: TransitionType.deterministic,
        readSymbol: 'a',
        writeSymbol: 'b',
        direction: TapeDirection.right,
      );
      machine = TM(
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
        tapeAlphabet: {'a', 'b', 'X', 'B'},
        blankSymbol: 'B',
        tapeCount: 1,
        panOffset: Vector2.zero(),
        zoomLevel: 1,
      );
    });

    test('toSnapshot encodes TM states and transitions', () {
      final snapshot = GraphViewTmMapper.toSnapshot(machine);

      expect(snapshot.metadata.id, equals('tm-1'));
      expect(snapshot.metadata.name, equals('Sample TM'));
      expect(snapshot.metadata.alphabet, containsAll(['a', 'b']));
      expect(
        snapshot.metadata.tapeAlphabet,
        containsAll(['a', 'b', 'X', 'B']),
      );
      expect(snapshot.metadata.blankSymbol, equals('B'));
      expect(snapshot.metadata.tapeCount, equals(1));

      expect(snapshot.nodes, hasLength(2));
      final nodeIds = snapshot.nodes.map((node) => node.id).toSet();
      expect(nodeIds, containsAll({'q0', 'q1'}));

      final edge = snapshot.edges.single;
      expect(edge.id, equals('t0'));
      expect(edge.readSymbol, equals('a'));
      expect(edge.writeSymbol, equals('b'));
      expect(edge.direction, equals(TapeDirection.right));
      expect(edge.tapeNumber, 0);
    });

    test('round-trips legacy control-point metadata unchanged', () {
      final configured = machine.copyWith(
        transitions: {transition.copyWith(controlPoint: Vector2(73, 91))},
      );

      final snapshot = GraphViewTmMapper.toSnapshot(configured);
      final restored = GraphViewTmMapper.mergeIntoTemplate(
        snapshot,
        configured,
      );

      expect(restored.tmTransitions.single.controlPoint, Vector2(73, 91));
    });

    test('mergeIntoTemplate rebuilds TM from snapshot', () {
      final template = machine.copyWith(
        states: {initialState},
        transitions: {},
        acceptingStates: {initialState},
      );

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
            controlPointX: 24,
            controlPointY: 30,
            readSymbol: 'c',
            writeSymbol: 'd',
            direction: TapeDirection.left,
          ),
        ],
        metadata: GraphViewAutomatonMetadata(
          id: 'tm-1',
          name: 'Updated TM',
          alphabet: ['a', 'b', 'c', 'd'],
        ),
      );

      final rebuilt = GraphViewTmMapper.mergeIntoTemplate(snapshot, template);

      expect(rebuilt.states.length, equals(2));
      final rebuiltInitial = rebuilt.states.firstWhere(
        (state) => state.id == 'q0',
      );
      expect(rebuiltInitial.position.x, closeTo(10, 0.0001));
      expect(rebuiltInitial.position.y, closeTo(20, 0.0001));

      final rebuiltTransition = rebuilt.tmTransitions.single;
      expect(rebuiltTransition.readSymbol, equals('c'));
      expect(rebuiltTransition.writeSymbol, equals('d'));
      expect(rebuiltTransition.direction, equals(TapeDirection.left));
      expect(rebuiltTransition.label, equals('c/d,L'));

      expect(rebuilt.alphabet, containsAll({'a', 'b', 'c', 'd'}));
      expect(rebuilt.initialState?.id, equals('q0'));
      expect(rebuilt.acceptingStates.single.id, equals('q1'));
    });

    test(
      'merge preserves tape alphabet without adding write markers to input alphabet',
      () {
        final template = machine.copyWith(
          alphabet: {'a', 'b'},
          tapeAlphabet: {'a', 'b', 'X', 'B'},
        );

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
              readSymbol: 'a',
              writeSymbol: 'X',
              direction: TapeDirection.right,
            ),
          ],
          metadata: GraphViewAutomatonMetadata(
            id: 'tm-1',
            name: 'Marker TM',
            alphabet: ['a', 'b'],
            tapeAlphabet: ['a', 'b', 'X', 'B'],
            blankSymbol: 'B',
            tapeCount: 1,
          ),
        );

        final rebuilt = GraphViewTmMapper.mergeIntoTemplate(snapshot, template);

        expect(rebuilt.alphabet, containsAll({'a', 'b'}));
        expect(rebuilt.alphabet, hasLength(2));
        expect(rebuilt.alphabet, isNot(contains('X')));
        expect(rebuilt.tapeAlphabet, containsAll({'a', 'b', 'X', 'B'}));
        expect(rebuilt.blankSymbol, 'B');
        expect(rebuilt.validate(), isEmpty);
      },
    );

    test('merge includes resolved blank symbol in fallback tape alphabet', () {
      final template = machine.copyWith(
        tapeAlphabet: {'a', 'b'},
        blankSymbol: 'B',
      );

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
        ],
        edges: [],
        metadata: GraphViewAutomatonMetadata(
          id: 'tm-1',
          name: 'Blank TM',
          alphabet: ['a', 'b'],
          blankSymbol: '_',
        ),
      );

      final rebuilt = GraphViewTmMapper.mergeIntoTemplate(snapshot, template);

      expect(rebuilt.blankSymbol, '_');
      expect(rebuilt.tapeAlphabet, containsAll({'a', 'b', '_'}));
    });

    test(
      'empty snapshot metadata preserves configuration and derives edge symbols',
      () {
        final template = machine.copyWith(
          id: 'stable-machine-id',
          name: 'Imported multi-tape machine',
          alphabet: {'a', 'unused-input'},
          tapeAlphabet: {'a', 'unused-input', 'Y', '_'},
          blankSymbol: '_',
          tapeCount: 3,
        );

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
              readSymbol: 'c',
              writeSymbol: 'X',
              direction: TapeDirection.left,
              tapeNumber: 2,
            ),
          ],
          metadata: GraphViewAutomatonMetadata.empty(),
        );

        final rebuilt = GraphViewTmMapper.mergeIntoTemplate(snapshot, template);

        expect(rebuilt.id, 'stable-machine-id');
        expect(rebuilt.name, 'Imported multi-tape machine');
        expect(rebuilt.alphabet, {'a', 'unused-input'});
        expect(
          rebuilt.tapeAlphabet,
          {'a', 'unused-input', 'Y', '_', 'c', 'X'},
        );
        expect(rebuilt.blankSymbol, '_');
        expect(rebuilt.tapeCount, 3);
        expect(rebuilt.tmTransitions.single.tapeNumber, 2);
        expect(rebuilt.validate(), isEmpty);
      },
    );
  });
}
