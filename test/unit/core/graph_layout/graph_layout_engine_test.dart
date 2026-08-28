import 'dart:math' as math;

import 'package:flutter_test/flutter_test.dart';
import 'package:vector_math/vector_math_64.dart';

import 'package:turing_lab/core/annotations/annotations.dart';
import 'package:turing_lab/core/graph_layout/graph_layout.dart';
import 'package:turing_lab/core/models/fsa.dart';
import 'package:turing_lab/core/models/fsa_transition.dart';
import 'package:turing_lab/core/models/pda.dart';
import 'package:turing_lab/core/models/pda_acceptance_mode.dart';
import 'package:turing_lab/core/models/state.dart';
import 'package:turing_lab/core/models/tm.dart';
import 'package:turing_lab/core/models/transition.dart';
import 'package:turing_lab/core/transducers/transducers.dart';

void main() {
  group('GraphLayoutEngine', () {
    test('every constructive algorithm is deterministic and finite', () {
      final graph = _graph(12, disconnected: true);
      const algorithms = <GraphLayoutAlgorithmId>{
        GraphLayoutAlgorithmId.circle,
        GraphLayoutAlgorithmId.twoCircle,
        GraphLayoutAlgorithmId.spiral,
        GraphLayoutAlgorithmId.hierarchical,
        GraphLayoutAlgorithmId.sugiyama,
        GraphLayoutAlgorithmId.componentPacking,
        GraphLayoutAlgorithmId.seededForce,
        GraphLayoutAlgorithmId.seededRandom,
      };

      for (final algorithm in algorithms) {
        final request = GraphLayoutRequest(
          algorithmId: algorithm,
          graph: graph,
          settings: GraphLayoutSettings(seed: 42, maximumIterations: 24),
        );
        final first = GraphLayoutEngine.compute(request);
        final second = GraphLayoutEngine.compute(request);

        expect(first.canApply, isTrue, reason: algorithm.name);
        expect(first.positions, second.positions, reason: algorithm.name);
        expect(
          first.positions.values.every((point) => point.isFinite),
          isTrue,
          reason: algorithm.name,
        );
      }
    });

    test('pins nodes and limits selected-node scope', () {
      final graph = _graph(5);
      final result = GraphLayoutEngine.compute(
        GraphLayoutRequest(
          algorithmId: GraphLayoutAlgorithmId.circle,
          graph: graph,
          settings: GraphLayoutSettings(
            scope: GraphLayoutScope.selectedNodes,
            selectedNodeIds: const {'n0', 'n1', 'n2'},
            pinnedNodeIds: const {'n0'},
          ),
        ),
      );

      expect(result.canApply, isTrue);
      expect(result.positions['n0'], graph.nodes[0].position);
      expect(result.positions['n3'], graph.nodes[3].position);
      expect(result.positions['n4'], graph.nodes[4].position);
      expect(result.positions['n1'], isNot(graph.nodes[1].position));
      expect(result.transform, isNull);
    });

    test('selected-component scope excludes disconnected nodes', () {
      final graph = _graph(6, disconnected: true);
      final result = GraphLayoutEngine.compute(
        GraphLayoutRequest(
          algorithmId: GraphLayoutAlgorithmId.spiral,
          graph: graph,
          settings: GraphLayoutSettings(
            scope: GraphLayoutScope.selectedComponent,
            selectedNodeIds: const {'n0'},
          ),
        ),
      );

      expect(result.canApply, isTrue);
      expect(result.affectedNodeIds, {'n0', 'n1', 'n2'});
      expect(result.positions['n4'], graph.nodes[4].position);
    });

    test('hierarchical layouts tolerate cycles, self-loops, and parallel edges',
        () {
      final graph = GraphLayoutGraph(
        nodes: _graph(4).nodes,
        edges: const [
          GraphLayoutEdge(id: 'a', fromNodeId: 'n0', toNodeId: 'n1'),
          GraphLayoutEdge(id: 'b', fromNodeId: 'n0', toNodeId: 'n1'),
          GraphLayoutEdge(id: 'c', fromNodeId: 'n1', toNodeId: 'n2'),
          GraphLayoutEdge(id: 'd', fromNodeId: 'n2', toNodeId: 'n0'),
          GraphLayoutEdge(id: 'e', fromNodeId: 'n3', toNodeId: 'n3'),
        ],
      );

      for (final algorithm in const [
        GraphLayoutAlgorithmId.hierarchical,
        GraphLayoutAlgorithmId.sugiyama,
      ]) {
        final result = GraphLayoutEngine.compute(
          GraphLayoutRequest(
            algorithmId: algorithm,
            graph: graph,
            settings: GraphLayoutSettings(rootNodeId: 'n0'),
          ),
        );
        expect(result.canApply, isTrue);
        expect(result.positions, hasLength(4));
        expect(
            result.positions.values.every((point) => point.isFinite), isTrue);
      }
    });

    test('empty, single-node, selection, restore, and resource limits are safe',
        () {
      final empty = GraphLayoutEngine.compute(
        GraphLayoutRequest(
          algorithmId: GraphLayoutAlgorithmId.circle,
          graph: GraphLayoutGraph(nodes: const [], edges: const []),
          settings: GraphLayoutSettings(),
        ),
      );
      expect(empty.canApply, isFalse);
      expect(
        empty.diagnostics.map((item) => item.code),
        contains(GraphLayoutDiagnosticCode.emptyGraph),
      );

      final singleGraph = _graph(1);
      final single = GraphLayoutEngine.compute(
        GraphLayoutRequest(
          algorithmId: GraphLayoutAlgorithmId.circle,
          graph: singleGraph,
          settings: GraphLayoutSettings(),
        ),
      );
      expect(single.canApply, isTrue);
      expect(single.positions['n0'], single.metrics.bounds.center);

      final missingSelection = GraphLayoutEngine.compute(
        GraphLayoutRequest(
          algorithmId: GraphLayoutAlgorithmId.circle,
          graph: singleGraph,
          settings: GraphLayoutSettings(scope: GraphLayoutScope.selectedNodes),
        ),
      );
      expect(missingSelection.canApply, isFalse);

      final missingRestore = GraphLayoutEngine.compute(
        GraphLayoutRequest(
          algorithmId: GraphLayoutAlgorithmId.restore,
          graph: singleGraph,
          settings: GraphLayoutSettings(),
        ),
      );
      expect(missingRestore.canApply, isFalse);

      final limited = GraphLayoutEngine.compute(
        GraphLayoutRequest(
          algorithmId: GraphLayoutAlgorithmId.circle,
          graph: _graph(3),
          settings: GraphLayoutSettings(maximumNodes: 2),
        ),
      );
      expect(limited.canApply, isFalse);
      expect(
        limited.diagnostics.map((item) => item.code),
        contains(GraphLayoutDiagnosticCode.resourceLimit),
      );
    });

    test('geometric transforms are reversible and expose an affine transform',
        () {
      final graph = _graph(4);
      final reflected = GraphLayoutEngine.compute(
        GraphLayoutRequest(
          algorithmId: GraphLayoutAlgorithmId.reflectVertical,
          graph: graph,
          settings: GraphLayoutSettings(),
        ),
      );
      final restored = GraphLayoutEngine.compute(
        GraphLayoutRequest(
          algorithmId: GraphLayoutAlgorithmId.reflectVertical,
          graph: GraphLayoutGraph(
            nodes: [
              for (final node in graph.nodes)
                GraphLayoutNode(
                  id: node.id,
                  label: node.label,
                  position: reflected.positions[node.id]!,
                  isInitial: node.isInitial,
                ),
            ],
            edges: graph.edges,
          ),
          settings: GraphLayoutSettings(),
        ),
      );

      expect(reflected.transform, isNotNull);
      for (final node in graph.nodes) {
        expect(restored.positions[node.id]!.x, closeTo(node.position.x, 1e-8));
        expect(restored.positions[node.id]!.y, closeTo(node.position.y, 1e-8));
      }
    });

    test('fit translates a single node without magnifying free coordinates',
        () {
      final result = GraphLayoutEngine.compute(
        GraphLayoutRequest(
          algorithmId: GraphLayoutAlgorithmId.fill,
          graph: _graph(1),
          settings: GraphLayoutSettings(
            targetBounds: const GraphLayoutBounds(
              left: 100,
              top: 200,
              width: 500,
              height: 300,
            ),
          ),
        ),
      );

      expect(result.positions['n0'], const GraphLayoutPoint(350, 350));
      expect(
        result.transform!.apply(const GraphLayoutPoint(10, 20)),
        const GraphLayoutPoint(360, 370),
      );
    });

    test('extreme input positions never produce non-finite output', () {
      final graph = GraphLayoutGraph(
        nodes: const [
          GraphLayoutNode(
            id: 'left',
            label: 'left',
            position: GraphLayoutPoint(-1e300, -1e300),
          ),
          GraphLayoutNode(
            id: 'right',
            label: 'right',
            position: GraphLayoutPoint(1e300, 1e300),
          ),
        ],
        edges: const [],
      );
      final result = GraphLayoutEngine.compute(
        GraphLayoutRequest(
          algorithmId: GraphLayoutAlgorithmId.rotate90,
          graph: graph,
          settings: GraphLayoutSettings(),
        ),
      );

      expect(result.positions.values.every((point) => point.isFinite), isTrue);
      expect(
        result.positions.values.every(
          (point) =>
              point.x.abs() <= GraphLayoutEngine.maximumCoordinateMagnitude &&
              point.y.abs() <= GraphLayoutEngine.maximumCoordinateMagnitude,
        ),
        isTrue,
      );
    });

    test('rejects invalid versions and topology with finite safe output', () {
      final invalidVersion = GraphLayoutEngine.compute(
        GraphLayoutRequest(
          algorithmId: GraphLayoutAlgorithmId.circle,
          algorithmVersion: 2,
          graph: _graph(2),
          settings: GraphLayoutSettings(),
        ),
      );
      expect(invalidVersion.canApply, isFalse);
      expect(
        invalidVersion.diagnostics.map((item) => item.code),
        contains(GraphLayoutDiagnosticCode.unsupportedAlgorithmVersion),
      );

      final invalidTopology = GraphLayoutEngine.compute(
        GraphLayoutRequest(
          algorithmId: GraphLayoutAlgorithmId.circle,
          graph: GraphLayoutGraph(
            nodes: const [
              GraphLayoutNode(
                id: 'node',
                label: 'Node',
                position: GraphLayoutPoint(double.nan, 0),
              ),
            ],
            edges: const [
              GraphLayoutEdge(
                id: 'dangling',
                fromNodeId: 'node',
                toNodeId: 'missing',
              ),
            ],
          ),
          settings: GraphLayoutSettings(),
        ),
      );
      expect(invalidTopology.canApply, isFalse);
      expect(
        invalidTopology.diagnostics.map((item) => item.code),
        contains(GraphLayoutDiagnosticCode.invalidTopology),
      );
      expect(
        invalidTopology.positions.values.every((point) => point.isFinite),
        isTrue,
      );
    });

    test('large constructive layouts remain inside target bounds', () {
      const target = GraphLayoutBounds(
        left: 100,
        top: 200,
        width: 500,
        height: 300,
      );
      final result = GraphLayoutEngine.compute(
        GraphLayoutRequest(
          algorithmId: GraphLayoutAlgorithmId.circle,
          graph: _graph(100),
          settings: GraphLayoutSettings(targetBounds: target),
        ),
      );

      expect(result.canApply, isTrue);
      expect(
        result.positions.values.every(
          (point) =>
              point.x >= target.left &&
              point.x <= target.right &&
              point.y >= target.top &&
              point.y <= target.bottom,
        ),
        isTrue,
      );
    });

    test('cancelable isolate task returns results and can be stopped',
        () async {
      final completed = await GraphLayoutTask.start(
        GraphLayoutRequest(
          algorithmId: GraphLayoutAlgorithmId.circle,
          graph: _graph(3),
          settings: GraphLayoutSettings(),
        ),
      );
      expect((await completed.result).canApply, isTrue);

      final pending = await GraphLayoutTask.start(
        GraphLayoutRequest(
          algorithmId: GraphLayoutAlgorithmId.seededForce,
          graph: _graph(350),
          settings: GraphLayoutSettings(
            maximumNodes: 400,
            maximumIterations: 500,
          ),
        ),
      );
      final cancellation = expectLater(
        pending.result,
        throwsA(isA<GraphLayoutCancelledException>()),
      );
      pending.cancel();
      await cancellation;
    });
  });

  group('GraphLayoutDocumentAdapter', () {
    test('changes only FSA layout data and preserves transition semantics', () {
      final source = _fsa();
      final before = source.toJson();
      final result = GraphLayoutDocumentAdapter.applyPositions(
        source,
        const {
          'q0': GraphLayoutPoint(400, 300),
          'q1': GraphLayoutPoint(600, 300),
        },
      ) as FSA;

      expect(result.states.singleWhere((state) => state.id == 'q0').position,
          Vector2(400, 300));
      expect(result.fsaTransitions.single.inputSymbols, {'a'});
      expect(result.fsaTransitions.single.fromState,
          result.states.singleWhere((state) => state.id == 'q0'));
      expect(result.id, before['id']);
      expect(result.name, before['name']);
      expect(result.alphabet, {'a'});
      expect(result.created, source.created);
      expect(result.modified, source.modified);
    });

    test('preserves PDA, TM, Mealy, and Moore configuration and payloads', () {
      final fsa = _fsa();
      final pda = PDA(
        id: 'pda',
        name: 'PDA',
        states: fsa.states,
        transitions: const {},
        alphabet: const {'a'},
        initialState: fsa.initialState,
        acceptingStates: fsa.acceptingStates,
        created: fsa.created,
        modified: fsa.modified,
        bounds: fsa.bounds,
        stackAlphabet: const {'Z'},
        initialStackSymbol: 'Z',
        acceptanceMode: PDAAcceptanceMode.emptyStack,
      );
      final tm = TM(
        id: 'tm',
        name: 'TM',
        states: fsa.states,
        transitions: const {},
        alphabet: const {'a'},
        initialState: fsa.initialState,
        acceptingStates: fsa.acceptingStates,
        created: fsa.created,
        modified: fsa.modified,
        bounds: fsa.bounds,
        tapeAlphabet: const {'a', '□'},
        blankSymbol: '□',
        tapeCount: 2,
      );
      final mealy = _mealy();
      final moore = _moore();

      final laidOutPda = GraphLayoutDocumentAdapter.applyPositions(
        pda,
        const {'q0': GraphLayoutPoint(20, 30)},
      ) as PDA;
      final laidOutTm = GraphLayoutDocumentAdapter.applyPositions(
        tm,
        const {'q0': GraphLayoutPoint(20, 30)},
      ) as TM;
      final laidOutMealy = GraphLayoutDocumentAdapter.applyPositions(
        mealy,
        const {'m0': GraphLayoutPoint(20, 30)},
      ) as MealyMachine;
      final laidOutMoore = GraphLayoutDocumentAdapter.applyPositions(
        moore,
        const {'m0': GraphLayoutPoint(20, 30)},
      ) as MooreMachine;

      expect(laidOutPda.acceptanceMode, PDAAcceptanceMode.emptyStack);
      expect(laidOutPda.initialStackSymbol, 'Z');
      expect(laidOutTm.tapeCount, 2);
      expect(laidOutTm.blankSymbol, '□');
      expect(laidOutMealy.transitions.single.output.values, ['x']);
      expect(laidOutMealy.revision, mealy.revision);
      expect(laidOutMoore.states.single.output.values, ['x']);
      expect(laidOutMoore.revision, moore.revision);
    });

    test('transforms free annotations only when explicitly requested', () {
      final now = DateTime.utc(2026, 8, 25);
      final collection = DocumentAnnotationCollection(
        documentId: 'doc',
        documentRevision: '1',
        annotations: [
          DocumentAnnotation(
            id: 'free',
            documentId: 'doc',
            documentRevision: '1',
            text: 'Free',
            x: 10,
            y: 20,
            createdAt: now,
            updatedAt: now,
          ),
          DocumentAnnotation(
            id: 'attached',
            documentId: 'doc',
            documentRevision: '1',
            text: 'Attached',
            x: 10,
            y: 20,
            attachment: const AnnotationAttachment(
              type: AnnotationTargetType.state,
              targetId: 'q0',
            ),
            createdAt: now,
            updatedAt: now,
          ),
        ],
      );
      final result = GraphLayoutResult(
        algorithmId: GraphLayoutAlgorithmId.reflectVertical,
        algorithmVersion: 1,
        positions: const {'q0': GraphLayoutPoint(0, 0)},
        diagnostics: const [],
        metrics: const GraphLayoutMetrics(
          nodeCount: 1,
          edgeCount: 0,
          componentCount: 1,
          overlapCount: 0,
          edgeCrossingCount: 0,
          bounds: GraphLayoutBounds(left: 0, top: 0, width: 0, height: 0),
          iterations: 0,
        ),
        affectedNodeIds: const {'q0'},
        transform: const GraphLayoutTransform(
          a: -1,
          b: 0,
          c: 0,
          d: 1,
          tx: 100,
          ty: 0,
        ),
      );

      final unchanged = GraphLayoutDocumentAdapter.applyFreeAnnotationTransform(
        collection,
        result,
        transformFreeAnnotations: false,
      );
      final transformed =
          GraphLayoutDocumentAdapter.applyFreeAnnotationTransform(
        collection,
        result,
        transformFreeAnnotations: true,
      );

      expect(unchanged, same(collection));
      expect(transformed.byId('free')!.x, 90);
      expect(transformed.byId('free')!.y, 20);
      expect(transformed.byId('attached')!.x, 10);
      expect(transformed.byId('attached')!.attachment?.targetId, 'q0');
    });
  });
}

GraphLayoutGraph _graph(int count, {bool disconnected = false}) {
  final nodes = [
    for (var index = 0; index < count; index++)
      GraphLayoutNode(
        id: 'n$index',
        label: 'q$index',
        position: GraphLayoutPoint(index * 40, (index % 3) * 30),
        isInitial: index == 0,
      ),
  ];
  final split = disconnected ? count ~/ 2 : count;
  final edges = <GraphLayoutEdge>[];
  for (var index = 0; index + 1 < count; index++) {
    if (disconnected && index + 1 == split) continue;
    edges.add(
      GraphLayoutEdge(
        id: 'e$index',
        fromNodeId: 'n$index',
        toNodeId: 'n${index + 1}',
      ),
    );
  }
  return GraphLayoutGraph(nodes: nodes, edges: edges);
}

FSA _fsa() {
  final now = DateTime.utc(2026, 8, 25);
  final q0 = State(
    id: 'q0',
    label: 'q0',
    position: Vector2.zero(),
    isInitial: true,
  );
  final q1 = State(
    id: 'q1',
    label: 'q1',
    position: Vector2(100, 0),
    isAccepting: true,
  );
  return FSA(
    id: 'fsa',
    name: 'FSA',
    states: {q0, q1},
    transitions: <Transition>{
      FSATransition(
        id: 't0',
        fromState: q0,
        toState: q1,
        inputSymbols: const {'a'},
      ),
    },
    alphabet: const {'a'},
    initialState: q0,
    acceptingStates: {q1},
    created: now,
    modified: now,
    bounds: const math.Rectangle<double>(0, 0, 400, 300),
  );
}

MealyMachine _mealy() => MealyMachine(
      id: const TransducerMachineId('mealy'),
      name: 'Mealy',
      revision: const TransducerRevision(4),
      inputAlphabet: {const TransducerInputSymbol('a')},
      outputAlphabet: {const TransducerOutputSymbol('x')},
      states: const [
        MealyState(
          id: TransducerStateId('m0'),
          label: 'm0',
          position: TransducerPoint(0, 0),
          isInitial: true,
        ),
      ],
      transitions: [
        MealyTransition(
          id: const TransducerTransitionId('loop'),
          from: const TransducerStateId('m0'),
          to: const TransducerStateId('m0'),
          input: const TransducerInputSymbol('a'),
          output: TransducerOutputWord.fromValues(const ['x']),
        ),
      ],
    );

MooreMachine _moore() => MooreMachine(
      id: const TransducerMachineId('moore'),
      name: 'Moore',
      revision: const TransducerRevision(7),
      inputAlphabet: {const TransducerInputSymbol('a')},
      outputAlphabet: {const TransducerOutputSymbol('x')},
      states: [
        MooreState(
          id: const TransducerStateId('m0'),
          label: 'm0',
          position: const TransducerPoint(0, 0),
          isInitial: true,
          output: TransducerOutputWord.fromValues(const ['x']),
        ),
      ],
      transitions: const [],
    );
