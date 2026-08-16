//
//  graphview_pda_mapper_test.dart
//  Turing Lab
//
//  Valida o GraphViewPdaMapper ao converter autômatos de pilha em estruturas de grafo, assegurando
//  que estados, transições e metadados de pilha sejam preservados. Exercita cenários com múltiplos
//  símbolos e ajustes geométricos para garantir compatibilidade com a renderização do canvas.
//
//  Thales Matheus Mendonça Santos - October 2025
//

import 'dart:math' as math;

import 'package:test/test.dart';
import 'package:vector_math/vector_math_64.dart';

import 'package:turing_lab/core/models/pda.dart';
import 'package:turing_lab/core/models/pda_transition.dart';
import 'package:turing_lab/core/models/state.dart';
import 'package:turing_lab/core/models/transition.dart';
import 'package:turing_lab/features/canvas/graphview/graphview_canvas_models.dart';
import 'package:turing_lab/features/canvas/graphview/graphview_pda_mapper.dart';

void main() {
  group('GraphViewPdaMapper', () {
    late State initialState;
    late State acceptingState;
    late PDATransition transition;
    late PDA basePda;

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
        position: Vector2(180, 120),
        isInitial: false,
        isAccepting: true,
      );
      transition = PDATransition(
        id: 't0',
        fromState: initialState,
        toState: acceptingState,
        label: 'a, Z/AZ',
        controlPoint: Vector2(40, 20),
        type: TransitionType.deterministic,
        inputSymbol: 'a',
        popSymbol: 'Z',
        pushSymbol: 'AZ',
        isLambdaInput: false,
        isLambdaPop: false,
        isLambdaPush: false,
      );
      basePda = PDA(
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
        stackAlphabet: {'Z', 'A'},
        initialStackSymbol: 'Z',
        zoomLevel: 1,
        panOffset: Vector2.zero(),
      );
    });

    test('toSnapshot encodes PDA structure', () {
      final snapshot = GraphViewPdaMapper.toSnapshot(basePda);

      expect(snapshot.metadata.id, equals('pda-1'));
      expect(snapshot.metadata.name, equals('Sample PDA'));
      expect(snapshot.metadata.alphabet, contains('a'));
      expect(snapshot.metadata.stackAlphabet, containsAll({'Z', 'A'}));
      expect(snapshot.metadata.initialStackSymbol, 'Z');

      expect(snapshot.nodes, hasLength(2));
      final nodeIds = snapshot.nodes.map((node) => node.id).toSet();
      expect(nodeIds, containsAll({'q0', 'q1'}));

      final encodedInitial = snapshot.nodes.firstWhere(
        (node) => node.id == 'q0',
      );
      expect(encodedInitial.isInitial, isTrue);
      expect(encodedInitial.x, closeTo(0, 0.0001));
      expect(encodedInitial.y, closeTo(0, 0.0001));

      expect(snapshot.edges, hasLength(1));
      final edge = snapshot.edges.single;
      expect(edge.id, equals('t0'));
      expect(edge.fromStateId, equals('q0'));
      expect(edge.toStateId, equals('q1'));
      expect(edge.readSymbol, equals('a'));
      expect(edge.popSymbol, equals('Z'));
      expect(edge.pushSymbol, equals('AZ'));
      expect(edge.isLambdaInput, isFalse);
      expect(edge.isLambdaPop, isFalse);
      expect(edge.isLambdaPush, isFalse);
    });

    test('mergeIntoTemplate rebuilds PDA from snapshot', () {
      final template = basePda.copyWith(
        states: {initialState},
        transitions: {},
        acceptingStates: {initialState},
      );

      const snapshot = GraphViewAutomatonSnapshot(
        nodes: [
          GraphViewCanvasNode(
            id: 'q0',
            label: 'start',
            x: 12,
            y: 18,
            isInitial: true,
            isAccepting: false,
          ),
          GraphViewCanvasNode(
            id: 'q1',
            label: 'accept',
            x: 200,
            y: 140,
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
            controlPointX: 40,
            controlPointY: 24,
            readSymbol: 'b',
            popSymbol: 'Z',
            pushSymbol: 'X',
            isLambdaInput: false,
            isLambdaPop: true,
            isLambdaPush: false,
          ),
        ],
        metadata: GraphViewAutomatonMetadata(
          id: 'pda-1',
          name: 'Updated PDA',
          alphabet: ['a', 'b'],
        ),
      );

      final rebuilt = GraphViewPdaMapper.mergeIntoTemplate(snapshot, template);

      expect(rebuilt.states.length, equals(2));
      final rebuiltInitial = rebuilt.states.firstWhere(
        (state) => state.id == 'q0',
      );
      final rebuiltAccepting = rebuilt.states.firstWhere(
        (state) => state.id == 'q1',
      );
      expect(rebuiltInitial.position.x, closeTo(12, 0.0001));
      expect(rebuiltInitial.position.y, closeTo(18, 0.0001));
      expect(rebuiltAccepting.isAccepting, isTrue);

      final rebuiltTransition = rebuilt.pdaTransitions.single;
      expect(rebuiltTransition.inputSymbol, equals('b'));
      expect(rebuiltTransition.popSymbol, equals(''));
      expect(rebuiltTransition.pushSymbol, equals('X'));
      expect(rebuiltTransition.isLambdaPop, isTrue);
      expect(rebuiltTransition.label, equals('b, λ/X'));

      expect(rebuilt.alphabet, containsAll({'a', 'b'}));
      expect(rebuilt.stackAlphabet, containsAll({'Z', 'X'}));
      expect(rebuilt.initialState?.id, equals('q0'));
      expect(rebuilt.acceptingStates.single.id, equals('q1'));
    });

    test('preserves atomic push symbols through a canvas snapshot', () {
      final multiSymbolTransition = transition.copyWith(
        pushSymbol: 'S_0Z',
        pushSymbols: ['S_0', 'Z'],
      );
      final pda = basePda.copyWith(
        transitions: {multiSymbolTransition},
        stackAlphabet: {'S_0', 'Z'},
      );

      final snapshot = GraphViewPdaMapper.toSnapshot(pda);
      final rebuilt = GraphViewPdaMapper.mergeIntoTemplate(snapshot, pda);

      expect(snapshot.edges.single.pushSymbols, ['S_0', 'Z']);
      expect(rebuilt.pdaTransitions.single.pushSymbols, ['S_0', 'Z']);
      expect(rebuilt.stackAlphabet, containsAll({'S_0', 'Z'}));
    });

    test('restores unreferenced stack configuration from snapshot metadata',
        () {
      final configured = basePda.copyWith(
        transitions: const {},
        stackAlphabet: {'S_0', 'unused-stack-symbol'},
        initialStackSymbol: 'S_0',
      );
      final template = basePda.copyWith(
        transitions: const {},
        stackAlphabet: {'Z'},
        initialStackSymbol: 'Z',
      );

      final snapshot = GraphViewPdaMapper.toSnapshot(configured);
      final rebuilt = GraphViewPdaMapper.mergeIntoTemplate(snapshot, template);

      expect(rebuilt.stackAlphabet, {'S_0', 'unused-stack-symbol'});
      expect(rebuilt.initialStackSymbol, 'S_0');
      expect(rebuilt.validate(), isEmpty);
    });

    test('clears stale push symbols for an explicit lambda push', () {
      final source = GraphViewPdaMapper.toSnapshot(basePda);
      final snapshot = GraphViewAutomatonSnapshot(
        nodes: source.nodes,
        metadata: source.metadata,
        edges: [
          GraphViewCanvasEdge(
            id: 'lambda-push',
            fromStateId: initialState.id,
            toStateId: acceptingState.id,
            symbols: const [],
            readSymbol: 'a',
            popSymbol: 'Z',
            pushSymbol: 'X',
            pushSymbols: const ['X'],
            isLambdaInput: false,
            isLambdaPop: false,
            isLambdaPush: true,
          ),
        ],
      );

      final rebuilt = GraphViewPdaMapper.mergeIntoTemplate(snapshot, basePda);
      final rebuiltTransition = rebuilt.pdaTransitions.single;

      expect(rebuiltTransition.pushSymbol, isEmpty);
      expect(rebuiltTransition.pushSymbols, isEmpty);
      expect(rebuiltTransition.validate(), isEmpty);
    });

    test('rebuilds stack alphabet from atomic symbols without legacy text', () {
      final source = GraphViewPdaMapper.toSnapshot(basePda);
      final snapshot = GraphViewAutomatonSnapshot(
        nodes: source.nodes,
        metadata: source.metadata,
        edges: [
          GraphViewCanvasEdge(
            id: 'atomic-push',
            fromStateId: initialState.id,
            toStateId: acceptingState.id,
            symbols: const [],
            readSymbol: 'a',
            popSymbol: 'Z',
            pushSymbols: const ['S_0', 'Z'],
            isLambdaInput: false,
            isLambdaPop: false,
            isLambdaPush: false,
          ),
        ],
      );

      final rebuilt = GraphViewPdaMapper.mergeIntoTemplate(snapshot, basePda);

      expect(rebuilt.pdaTransitions.single.pushSymbols, ['S_0', 'Z']);
      expect(rebuilt.stackAlphabet, containsAll({'S_0', 'Z'}));
    });
  });
}
