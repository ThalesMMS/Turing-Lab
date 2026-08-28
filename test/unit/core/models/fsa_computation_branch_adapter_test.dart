import 'dart:math' as math;

import 'package:flutter_test/flutter_test.dart';
import 'package:vector_math/vector_math_64.dart';

import 'package:turing_lab/core/algorithms/automaton_simulator.dart';
import 'package:turing_lab/core/models/computation_branch.dart';
import 'package:turing_lab/core/models/fsa_computation_branch_adapter.dart';
import 'package:turing_lab/core/models/fsa.dart';
import 'package:turing_lab/core/models/fsa_transition.dart';
import 'package:turing_lab/core/models/nfa_computation_tree.dart';
import 'package:turing_lab/core/models/nfa_path_node.dart';
import 'package:turing_lab/core/models/simulation_result.dart';
import 'package:turing_lab/core/models/state.dart' as automaton_models;

void main() {
  group('FsaComputationBranchAdapter', () {
    test('preserves stable shared-node and branch identities', () {
      final result = _branchingResult();

      final original = FsaComputationBranchAdapter.adapt(
        result,
        isDeterministic: false,
        stateLabels: const {'q0-id': 'q0', 'q1-id': 'q1', 'q2-id': 'q2'},
      );
      final restored = FsaComputationBranchAdapter.adapt(
        SimulationResult.fromJson(result.toJson()),
        isDeterministic: false,
        stateLabels: const {'q0-id': 'q0', 'q1-id': 'q1', 'q2-id': 'q2'},
      );

      final originalGraph = _graph(original);
      final restoredGraph = _graph(restored);
      expect(
        restoredGraph.nodes.map((node) => node.id),
        originalGraph.nodes.map((node) => node.id),
      );
      expect(
        restoredGraph.branches.map((branch) => branch.id),
        originalGraph.branches.map((branch) => branch.id),
      );
      for (var index = 0; index < originalGraph.branches.length; index++) {
        expect(
          restored
              .highlightForBranch(restoredGraph.branches[index].id)
              .transitionIds,
          original
              .highlightForBranch(originalGraph.branches[index].id)
              .transitionIds,
        );
      }
      expect(originalGraph.nodes, hasLength(3));
      expect(originalGraph.branches, hasLength(2));
      expect(
        originalGraph.branches.map((branch) => branch.outcome),
        [ComputationBranchOutcome.accepted, ComputationBranchOutcome.dead],
      );
    });

    test('keeps initial epsilon-closure branches visible', () {
      final result = _epsilonResult();

      final adapted = FsaComputationBranchAdapter.adapt(
        result,
        isDeterministic: false,
        stateLabels: const {'q0-id': 'q0', 'q1-id': 'q1'},
      );
      final graph = _graph(adapted);

      expect(graph.rootNodeIds, hasLength(1));
      expect(graph.branches, hasLength(2));
      final childNodes = graph.nodes
          .where((node) => node.parentId == graph.rootNodeIds.single)
          .toList();
      expect(childNodes, hasLength(2));
      expect(
        childNodes.map((node) => node.transitionSummary).toSet(),
        {'Initial configuration', 'ε-closure from q0 to q1'},
      );
      expect(
        childNodes.map((node) => node.configurationSummary),
        containsAll(['q0 · "a"', 'q1 · "a"']),
      );
    });

    test('maps timeout, trace bounds, and cycles to typed outcomes', () {
      final timeout = _timeoutResult();
      expect(timeout.isTimeout, isTrue);
      expect(timeout.computationTree!.isTimeout, isTrue);
      final cases = <(SimulationResult, ComputationBranchOutcome)>[
        (timeout, ComputationBranchOutcome.boundedUnknown),
        (_truncatedResult(), ComputationBranchOutcome.boundedUnknown),
        (_cycleResult(), ComputationBranchOutcome.cycle),
      ];

      for (final (result, expected) in cases) {
        final graph = _graph(
          FsaComputationBranchAdapter.adapt(
            result,
            isDeterministic: false,
          ),
        );
        expect(graph.branches.single.outcome, expected);
        expect(graph.nodes.last.outcome, expected);
      }
    });

    test('keeps known terminal outcomes when another frontier is truncated',
        () {
      const cycle = NFAPathNode(
        currentState: 'cycle-id',
        remainingInput: '',
        transitionIds: ['cycle-edge'],
        stepNumber: 1,
        isCycle: true,
      );
      const dead = NFAPathNode(
        currentState: 'dead-id',
        remainingInput: 'a',
        transitionIds: ['dead-edge'],
        stepNumber: 1,
        isDeadEnd: true,
      );
      const accepted = NFAPathNode(
        currentState: 'accepted-id',
        remainingInput: '',
        transitionIds: ['accepted-edge'],
        stepNumber: 1,
        isAccepting: true,
      );
      const frontier = NFAPathNode(
        currentState: 'frontier-id',
        remainingInput: 'a',
        transitionIds: ['frontier-edge'],
        stepNumber: 1,
      );
      const root = NFAPathNode(
        currentState: 'root-id',
        remainingInput: 'a',
        stepNumber: 0,
        children: [cycle, dead, accepted, frontier],
      );
      const message = 'NFA trace truncated after 5 nodes.';
      final adapted = FsaComputationBranchAdapter.adapt(
        SimulationResult.failure(
          inputString: 'a',
          steps: const [],
          errorMessage: message,
          executionTime: Duration.zero,
          computationTree: NFAComputationTree.rejected(
            root: root,
            inputString: 'a',
            totalSteps: 1,
            errorMessage: message,
          ),
        ),
        isDeterministic: false,
      );
      final graph = _graph(adapted);

      expect(
        graph.branches.map((branch) => branch.outcome).toSet(),
        {
          ComputationBranchOutcome.cycle,
          ComputationBranchOutcome.dead,
          ComputationBranchOutcome.accepted,
          ComputationBranchOutcome.boundedUnknown,
        },
      );
      final cycleBranch = graph.branches.singleWhere(
        (branch) => branch.outcome == ComputationBranchOutcome.cycle,
      );
      final deadBranch = graph.branches.singleWhere(
        (branch) => branch.outcome == ComputationBranchOutcome.dead,
      );
      final frontierBranch = graph.branches.singleWhere(
        (branch) => branch.outcome == ComputationBranchOutcome.boundedUnknown,
      );
      expect(
        adapted.highlightForBranch(cycleBranch.id).warningStateIds,
        {'cycle-id'},
      );
      expect(
        adapted.highlightForBranch(deadBranch.id).errorStateIds,
        {'dead-id'},
      );
      expect(
        adapted.highlightForBranch(frontierBranch.id).warningStateIds,
        {'frontier-id'},
      );
    });

    test('explains absent result, deterministic runs, and unrecorded trees',
        () {
      expect(
        FsaComputationBranchAdapter.adapt(
          null,
          isDeterministic: false,
        ).availability,
        isA<ComputationBranchesUnavailable>().having(
          (availability) => availability.reason,
          'reason',
          ComputationBranchesUnavailableReason.simulationNotRun,
        ),
      );
      expect(
        FsaComputationBranchAdapter.adapt(
          _treeLessResult(),
          isDeterministic: true,
        ).availability,
        isA<ComputationBranchesUnavailable>().having(
          (availability) => availability.reason,
          'reason',
          ComputationBranchesUnavailableReason.deterministicExecution,
        ),
      );
      expect(
        FsaComputationBranchAdapter.adapt(
          _treeLessResult(),
          isDeterministic: false,
        ).availability,
        isA<ComputationBranchesUnavailable>().having(
          (availability) => availability.reason,
          'reason',
          ComputationBranchesUnavailableReason.branchesNotRecorded,
        ),
      );
    });

    test('builds read-only branch highlights from stable state ids', () {
      final adapted = FsaComputationBranchAdapter.adapt(
        _branchingResult(),
        isDeterministic: false,
      );
      final graph = _graph(adapted);
      final acceptingBranch = graph.branches.first;
      final deadBranch = graph.branches.last;

      final accepting = adapted.highlightForBranch(acceptingBranch.id);
      final dead = adapted.highlightForBranch(deadBranch.id);

      expect(accepting.stateIds, {'q0-id', 'q1-id'});
      expect(accepting.transitionIds, {'accepting-edge'});
      expect(accepting.warningStateIds, isEmpty);
      expect(accepting.errorStateIds, isEmpty);
      expect(dead.stateIds, {'q0-id', 'q2-id'});
      expect(dead.transitionIds, {'dead-edge'});
      expect(dead.errorStateIds, {'q2-id'});
      expect(adapted.highlightForBranch(null).isEmpty, isTrue);
    });

    test('preserves post-symbol epsilon provenance and highlights its edges',
        () async {
      final simulation = await AutomatonSimulator.simulateNFA(
        _postSymbolEpsilonNfa(),
        'a',
        stepByStep: true,
      );
      expect(simulation.isSuccess, isTrue);
      final adapted = FsaComputationBranchAdapter.adapt(
        simulation.data!,
        isDeterministic: false,
        stateLabels: const {'q0-id': 'q0', 'q1-id': 'q1', 'q2-id': 'q2'},
      );
      final graph = _graph(adapted);
      final q2 = graph.nodes.singleWhere(
        (node) => node.configurationSummary == 'q2 · "ε"',
      );
      final branch = graph.branches.singleWhere(
        (branch) => branch.nodeIds.last == q2.id,
      );

      expect(q2.transitionSummary, 'δ(q0, a) → q1; ε → q2');
      expect(
        adapted.highlightForBranch(branch.id).transitionIds,
        {'symbol-edge', 'epsilon-edge'},
      );
    });

    test('keeps parallel edge identities on otherwise identical branches',
        () async {
      final simulation = await AutomatonSimulator.simulateNFA(
        _parallelSymbolNfa(),
        'a',
        stepByStep: true,
      );
      expect(simulation.isSuccess, isTrue);
      final adapted = FsaComputationBranchAdapter.adapt(
        simulation.data!,
        isDeterministic: false,
      );
      final graph = _graph(adapted);

      expect(graph.branches, hasLength(2));
      expect(
        graph.branches
            .map(
                (branch) => adapted.highlightForBranch(branch.id).transitionIds)
            .toSet(),
        {
          {'parallel-a'},
          {'parallel-b'},
        },
      );
    });

    test('keeps alternate convergent epsilon paths as distinct branches',
        () async {
      final simulation = await AutomatonSimulator.simulateNFA(
        _convergentEpsilonNfa(),
        'a',
        stepByStep: true,
      );
      expect(simulation.isSuccess, isTrue);
      final adapted = FsaComputationBranchAdapter.adapt(
        simulation.data!,
        isDeterministic: false,
        stateLabels: const {
          'q0-id': 'q0',
          'q1-id': 'q1',
          'q2-id': 'q2',
          'q3-id': 'q3',
          'q4-id': 'q4',
        },
      );
      final graph = _graph(adapted);
      final q4NodeIds = graph.nodes
          .where((node) => node.configurationSummary == 'q4 · "ε"')
          .map((node) => node.id)
          .toSet();
      final q4Branches = graph.branches
          .where((branch) => q4NodeIds.contains(branch.nodeIds.last))
          .toList();

      expect(q4Branches, hasLength(2));
      expect(
        q4Branches
            .map(
              (branch) => adapted.highlightForBranch(branch.id).transitionIds,
            )
            .toSet(),
        {
          {'symbol-edge', 'epsilon-left', 'epsilon-left-join'},
          {'symbol-edge', 'epsilon-right', 'epsilon-right-join'},
        },
      );
      expect(
        q4NodeIds
            .map(
              (nodeId) => graph.nodes
                  .firstWhere((node) => node.id == nodeId)
                  .transitionSummary,
            )
            .toSet(),
        {
          'δ(q0, a) → q1; ε → q2 → ε → q4',
          'δ(q0, a) → q1; ε → q3 → ε → q4',
        },
      );
    });

    test('records epsilon cycle closures once with a cycle outcome', () async {
      final simulation = await AutomatonSimulator.simulateNFA(
        _epsilonCycleNfa(),
        'a',
        stepByStep: true,
      );
      expect(simulation.isSuccess, isTrue);
      final adapted = FsaComputationBranchAdapter.adapt(
        simulation.data!,
        isDeterministic: false,
      );
      final graph = _graph(adapted);
      final cycleBranch = graph.branches.singleWhere(
        (branch) => branch.outcome == ComputationBranchOutcome.cycle,
      );

      expect(
        graph.branches.map((branch) => branch.outcome).toSet(),
        {
          ComputationBranchOutcome.accepted,
          ComputationBranchOutcome.cycle,
        },
      );
      expect(
        adapted.highlightForBranch(cycleBranch.id).transitionIds,
        {'symbol-edge', 'epsilon-loop'},
      );
    });

    test('adapts a trace with 9999 terminal branches without eager summaries',
        () {
      final leaves = List<NFAPathNode>.generate(
        9999,
        (index) => NFAPathNode(
          currentState: 'leaf-$index',
          remainingInput: '',
          stepNumber: 1,
          isDeadEnd: true,
        ),
        growable: false,
      );
      final root = NFAPathNode(
        currentState: 'root',
        remainingInput: 'a',
        stepNumber: 0,
        children: leaves,
      );
      final result = SimulationResult.failure(
        inputString: 'a',
        steps: const [],
        errorMessage: 'Input not accepted',
        executionTime: Duration.zero,
        computationTree: NFAComputationTree.rejected(
          root: root,
          inputString: 'a',
          totalSteps: 1,
          errorMessage: 'Input not accepted',
        ),
      );

      final graph = _graph(
        FsaComputationBranchAdapter.adapt(
          result,
          isDeterministic: false,
        ),
      );

      expect(graph.nodes, hasLength(10000));
      expect(graph.branches, hasLength(9999));
      expect(
        graph.branches.every((branch) => branch.summary!.length < 80),
        isTrue,
      );
    });

    test('bounds summaries for deep branches', () {
      var node = const NFAPathNode(
        currentState: 'state-19',
        remainingInput: '',
        stepNumber: 19,
        isDeadEnd: true,
      );
      for (var index = 18; index >= 0; index--) {
        node = NFAPathNode(
          currentState: 'state-$index',
          remainingInput: 'a',
          stepNumber: index,
          children: [node],
        );
      }
      final result = SimulationResult.failure(
        inputString: 'a',
        steps: const [],
        errorMessage: 'Input not accepted',
        executionTime: Duration.zero,
        computationTree: NFAComputationTree.rejected(
          root: node,
          inputString: 'a',
          totalSteps: 19,
          errorMessage: 'Input not accepted',
        ),
      );

      final graph = _graph(
        FsaComputationBranchAdapter.adapt(
          result,
          isDeterministic: false,
        ),
      );

      expect(graph.branches.single.summary, contains('→ … →'));
      expect(graph.branches.single.summary, contains('20 configurations'));
      expect(graph.branches.single.summary!.length, lessThan(100));
    });
  });
}

ComputationBranchGraph _graph(FsaComputationBranches adapted) {
  final availability = adapted.availability;
  expect(availability, isA<ComputationBranchesAvailable>());
  return (availability as ComputationBranchesAvailable).graph;
}

SimulationResult _branchingResult() {
  const accepting = NFAPathNode(
    currentState: 'q1-id',
    remainingInput: '',
    inputSymbol: 'a',
    transitionUsed: 'δ(q0-id, a) → q1-id',
    transitionIds: ['accepting-edge'],
    stepNumber: 1,
    isAccepting: true,
  );
  const dead = NFAPathNode(
    currentState: 'q2-id',
    remainingInput: '',
    inputSymbol: 'a',
    transitionUsed: 'δ(q0-id, a) → q2-id',
    transitionIds: ['dead-edge'],
    stepNumber: 1,
    isDeadEnd: true,
  );
  const root = NFAPathNode(
    currentState: 'q0-id',
    remainingInput: 'a',
    stepNumber: 0,
    children: [accepting, dead],
  );
  return SimulationResult.success(
    inputString: 'a',
    steps: const [],
    executionTime: Duration.zero,
    computationTree: NFAComputationTree.accepted(
      root: root,
      inputString: 'a',
      totalSteps: 1,
    ),
  );
}

SimulationResult _epsilonResult() {
  const q0 = NFAPathNode(
    currentState: 'q0-id',
    remainingInput: 'a',
    stepNumber: 0,
    isDeadEnd: true,
  );
  const q1 = NFAPathNode(
    currentState: 'q1-id',
    remainingInput: 'a',
    stepNumber: 0,
    transitionUsed: 'ε-closure from q0 to q1',
    transitionIds: ['epsilon-edge'],
    isAccepting: true,
  );
  const root = NFAPathNode(
    currentState: '{q0-id,q1-id}',
    remainingInput: 'a',
    stepNumber: 0,
    children: [q0, q1],
    transitionUsed: 'ε-closure of initial state',
    description: 'Initial ε-closure',
  );
  return SimulationResult.success(
    inputString: 'a',
    steps: const [],
    executionTime: Duration.zero,
    computationTree: NFAComputationTree.accepted(
      root: root,
      inputString: 'a',
      totalSteps: 0,
    ),
  );
}

SimulationResult _timeoutResult() {
  const root = NFAPathNode(
    currentState: 'q0-id',
    remainingInput: 'a',
    stepNumber: 0,
  );
  return SimulationResult.timeout(
    inputString: 'a',
    steps: const [],
    executionTime: const Duration(seconds: 5),
    computationTree: NFAComputationTree.timeout(
      root: root,
      inputString: 'a',
      totalSteps: 0,
    ),
  );
}

SimulationResult _truncatedResult() {
  const root = NFAPathNode(
    currentState: 'q0-id',
    remainingInput: 'a',
    stepNumber: 0,
  );
  const message = 'NFA trace truncated after 1 nodes';
  return SimulationResult.failure(
    inputString: 'a',
    steps: const [],
    errorMessage: message,
    executionTime: Duration.zero,
    computationTree: NFAComputationTree.rejected(
      root: root,
      inputString: 'a',
      totalSteps: 0,
      errorMessage: message,
    ),
  );
}

SimulationResult _cycleResult() {
  const root = NFAPathNode(
    currentState: 'q0-id',
    remainingInput: 'a',
    stepNumber: 0,
  );
  return SimulationResult.infiniteLoop(
    inputString: 'a',
    steps: const [],
    executionTime: Duration.zero,
    computationTree: NFAComputationTree.infiniteLoop(
      root: root,
      inputString: 'a',
      totalSteps: 1001,
    ),
  );
}

SimulationResult _treeLessResult() => SimulationResult.success(
      inputString: 'a',
      steps: const [],
      executionTime: Duration.zero,
    );

FSA _postSymbolEpsilonNfa() {
  final q0 = automaton_models.State(
    id: 'q0-id',
    label: 'q0',
    position: Vector2.zero(),
    isInitial: true,
  );
  final q1 = automaton_models.State(
    id: 'q1-id',
    label: 'q1',
    position: Vector2(100, 0),
  );
  final q2 = automaton_models.State(
    id: 'q2-id',
    label: 'q2',
    position: Vector2(200, 0),
    isAccepting: true,
  );
  return _nfa(
    states: {q0, q1, q2},
    initial: q0,
    accepting: {q2},
    transitions: {
      FSATransition(
        id: 'symbol-edge',
        fromState: q0,
        toState: q1,
        inputSymbols: const {'a'},
      ),
      FSATransition(
        id: 'epsilon-edge',
        fromState: q1,
        toState: q2,
        lambdaSymbol: 'ε',
      ),
    },
  );
}

FSA _parallelSymbolNfa() {
  final q0 = automaton_models.State(
    id: 'q0-id',
    label: 'q0',
    position: Vector2.zero(),
    isInitial: true,
  );
  final q1 = automaton_models.State(
    id: 'q1-id',
    label: 'q1',
    position: Vector2(100, 0),
    isAccepting: true,
  );
  return _nfa(
    states: {q0, q1},
    initial: q0,
    accepting: {q1},
    transitions: {
      FSATransition(
        id: 'parallel-a',
        fromState: q0,
        toState: q1,
        inputSymbols: const {'a'},
      ),
      FSATransition(
        id: 'parallel-b',
        fromState: q0,
        toState: q1,
        inputSymbols: const {'a'},
      ),
    },
  );
}

FSA _convergentEpsilonNfa() {
  final q0 = automaton_models.State(
    id: 'q0-id',
    label: 'q0',
    position: Vector2.zero(),
    isInitial: true,
  );
  final q1 = automaton_models.State(
    id: 'q1-id',
    label: 'q1',
    position: Vector2(100, 0),
  );
  final q2 = automaton_models.State(
    id: 'q2-id',
    label: 'q2',
    position: Vector2(200, -50),
  );
  final q3 = automaton_models.State(
    id: 'q3-id',
    label: 'q3',
    position: Vector2(200, 50),
  );
  final q4 = automaton_models.State(
    id: 'q4-id',
    label: 'q4',
    position: Vector2(300, 0),
    isAccepting: true,
  );
  return _nfa(
    states: {q0, q1, q2, q3, q4},
    initial: q0,
    accepting: {q4},
    transitions: {
      FSATransition(
        id: 'symbol-edge',
        fromState: q0,
        toState: q1,
        inputSymbols: const {'a'},
      ),
      FSATransition(
        id: 'epsilon-left',
        fromState: q1,
        toState: q2,
        lambdaSymbol: 'ε',
      ),
      FSATransition(
        id: 'epsilon-right',
        fromState: q1,
        toState: q3,
        lambdaSymbol: 'ε',
      ),
      FSATransition(
        id: 'epsilon-left-join',
        fromState: q2,
        toState: q4,
        lambdaSymbol: 'ε',
      ),
      FSATransition(
        id: 'epsilon-right-join',
        fromState: q3,
        toState: q4,
        lambdaSymbol: 'ε',
      ),
    },
  );
}

FSA _epsilonCycleNfa() {
  final q0 = automaton_models.State(
    id: 'q0-id',
    label: 'q0',
    position: Vector2.zero(),
    isInitial: true,
  );
  final q1 = automaton_models.State(
    id: 'q1-id',
    label: 'q1',
    position: Vector2(100, 0),
    isAccepting: true,
  );
  return _nfa(
    states: {q0, q1},
    initial: q0,
    accepting: {q1},
    transitions: {
      FSATransition(
        id: 'symbol-edge',
        fromState: q0,
        toState: q1,
        inputSymbols: const {'a'},
      ),
      FSATransition(
        id: 'epsilon-loop',
        fromState: q1,
        toState: q1,
        lambdaSymbol: 'ε',
      ),
    },
  );
}

FSA _nfa({
  required Set<automaton_models.State> states,
  required automaton_models.State initial,
  required Set<automaton_models.State> accepting,
  required Set<FSATransition> transitions,
}) {
  return FSA(
    id: 'adapter-nfa',
    name: 'Adapter NFA',
    states: states,
    transitions: transitions,
    alphabet: const {'a'},
    initialState: initial,
    acceptingStates: accepting,
    created: DateTime.utc(2026),
    modified: DateTime.utc(2026),
    bounds: const math.Rectangle(0, 0, 300, 100),
  );
}
