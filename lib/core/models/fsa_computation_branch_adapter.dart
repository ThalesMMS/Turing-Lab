//
//  fsa_computation_branch_adapter.dart
//  Turing Lab
//
//  Adapts recorded NFA computation trees to the family-neutral branch model.
//

import 'computation_branch.dart';
import 'nfa_computation_tree.dart';
import 'nfa_path_node.dart';
import 'simulation_highlight.dart';
import 'simulation_result.dart';

/// Read-only FSA branch data plus canvas highlights derived from stable ids.
final class FsaComputationBranches {
  FsaComputationBranches._({
    required this.availability,
    required Map<ComputationBranchNodeId, String> stateIdsByNode,
    required Map<ComputationBranchNodeId, List<String>> transitionIdsByNode,
  }) : _stateIdsByNode = Map.unmodifiable(stateIdsByNode),
       _transitionIdsByNode = Map.unmodifiable(transitionIdsByNode);

  final ComputationBranchesAvailability availability;
  final Map<ComputationBranchNodeId, String> _stateIdsByNode;
  final Map<ComputationBranchNodeId, List<String>> _transitionIdsByNode;

  SimulationHighlight highlightForBranch(ComputationBranchId? branchId) {
    final availability = this.availability;
    if (availability is! ComputationBranchesAvailable || branchId == null) {
      return SimulationHighlight.empty;
    }
    final branch = availability.graph.branch(branchId);
    if (branch == null) return SimulationHighlight.empty;

    final stateIds = <String>{};
    final transitionIds = <String>{};
    for (final nodeId in branch.nodeIds) {
      final stateId = _stateIdsByNode[nodeId];
      if (stateId != null && stateId.isNotEmpty && !_isVirtualState(stateId)) {
        stateIds.add(stateId);
      }
      transitionIds.addAll(_transitionIdsByNode[nodeId] ?? const []);
    }
    final terminalStateId = branch.nodeIds.isEmpty
        ? null
        : _stateIdsByNode[branch.nodeIds.last];
    return SimulationHighlight(
      stateIds: stateIds,
      transitionIds: transitionIds,
      warningStateIds:
          branch.outcome == ComputationBranchOutcome.cycle ||
              branch.outcome == ComputationBranchOutcome.boundedUnknown
          ? {if (terminalStateId != null) terminalStateId}
          : const {},
      errorStateIds:
          branch.outcome == ComputationBranchOutcome.dead ||
              branch.outcome == ComputationBranchOutcome.rejected ||
              branch.outcome == ComputationBranchOutcome.failed
          ? {if (terminalStateId != null) terminalStateId}
          : const {},
    );
  }

  static bool _isVirtualState(String stateId) =>
      stateId.startsWith('{') && stateId.endsWith('}');
}

/// Converts an FSA simulation result without changing the source tree.
abstract final class FsaComputationBranchAdapter {
  static FsaComputationBranches adapt(
    SimulationResult? result, {
    required bool isDeterministic,
    Map<String, String> stateLabels = const {},
  }) {
    if (result == null) {
      return FsaComputationBranches._(
        availability: const ComputationBranchesUnavailable(
          ComputationBranchesUnavailableReason.simulationNotRun,
        ),
        stateIdsByNode: const {},
        transitionIdsByNode: const {},
      );
    }
    final tree = result.computationTree;
    if (tree == null) {
      return FsaComputationBranches._(
        availability: ComputationBranchesUnavailable(
          isDeterministic
              ? ComputationBranchesUnavailableReason.deterministicExecution
              : ComputationBranchesUnavailableReason.branchesNotRecorded,
        ),
        stateIdsByNode: const {},
        transitionIdsByNode: const {},
      );
    }

    final nodes = <ComputationBranchNode>[];
    final branches = <ComputationBranch>[];
    final nodesById = <ComputationBranchNodeId, ComputationBranchNode>{};
    final stateIdsByNode = <ComputationBranchNodeId, String>{};
    final transitionIdsByNode = <ComputationBranchNodeId, List<String>>{};
    const rootId = ComputationBranchNodeId('fsa-node-root');

    void visit(
      NFAPathNode node,
      ComputationBranchNodeId id,
      ComputationBranchNodeId? parentId,
      List<ComputationBranchNodeId> path,
      String structuralPath,
    ) {
      stateIdsByNode[id] = node.currentState;
      transitionIdsByNode[id] = List.unmodifiable(node.transitionIds);
      final childIds = <ComputationBranchNodeId>[
        for (var index = 0; index < node.children.length; index++)
          ComputationBranchNodeId('$id.$index'),
      ];
      final outcome = node.children.isEmpty
          ? _outcomeForLeaf(result, tree, node)
          : null;
      final branchNode = ComputationBranchNode(
        id: id,
        parentId: parentId,
        childIds: childIds,
        configurationSummary: _configurationSummary(node, stateLabels),
        transitionSummary: parentId == null
            ? null
            : _transitionSummary(node, tree.root),
        outcome: outcome,
      );
      nodes.add(branchNode);
      nodesById[id] = branchNode;
      final nextPath = [...path, id];
      if (node.children.isEmpty) {
        branches.add(
          ComputationBranch(
            id: ComputationBranchId('fsa-branch-$structuralPath'),
            nodeIds: nextPath,
            outcome: outcome!,
            summary: _branchSummary(nextPath, nodesById),
          ),
        );
        return;
      }
      for (var index = 0; index < node.children.length; index++) {
        final childStructuralPath = structuralPath.isEmpty
            ? '$index'
            : '$structuralPath.$index';
        visit(
          node.children[index],
          childIds[index],
          id,
          nextPath,
          childStructuralPath,
        );
      }
    }

    visit(tree.root, rootId, null, const [], 'root');
    return FsaComputationBranches._(
      availability: ComputationBranchesAvailable(
        ComputationBranchGraph(
          nodes: nodes,
          branches: branches,
          rootNodeIds: [rootId],
        ),
      ),
      stateIdsByNode: stateIdsByNode,
      transitionIdsByNode: transitionIdsByNode,
    );
  }

  static ComputationBranchOutcome _outcomeForLeaf(
    SimulationResult result,
    NFAComputationTree tree,
    NFAPathNode leaf,
  ) {
    if (leaf.isCycle) return ComputationBranchOutcome.cycle;
    if (leaf.isAccepting) return ComputationBranchOutcome.accepted;
    if (leaf.isDeadEnd) return ComputationBranchOutcome.dead;
    if (result.isTimeout || tree.isTimeout || _isTraceBound(result, tree)) {
      return ComputationBranchOutcome.boundedUnknown;
    }
    if (result.isInfiniteLoop || tree.isInfiniteLoop) {
      return ComputationBranchOutcome.cycle;
    }
    if (result.errorMessage.isNotEmpty || tree.errorMessage.isNotEmpty) {
      return ComputationBranchOutcome.rejected;
    }
    return ComputationBranchOutcome.failed;
  }

  static bool _isTraceBound(SimulationResult result, NFAComputationTree tree) =>
      result.errorMessage.toLowerCase().contains('trace truncated') ||
      tree.errorMessage.toLowerCase().contains('trace truncated');

  static String _configurationSummary(
    NFAPathNode node,
    Map<String, String> stateLabels,
  ) {
    final state = stateLabels[node.currentState] ?? node.currentState;
    final remaining = node.remainingInput.isEmpty ? 'ε' : node.remainingInput;
    return '$state · "$remaining"';
  }

  static String? _transitionSummary(NFAPathNode node, NFAPathNode root) {
    final hasInitialEpsilonClosureDescription =
        root.description == 'Initial ε-closure' ||
        root.descriptionMessage?.stableCode ==
            'automaton.simulation.initial-epsilon-closure-description';
    if (hasInitialEpsilonClosureDescription && node.stepNumber == 0) {
      return node.transitionIds.isEmpty
          ? 'Initial configuration'
          : node.transitionUsed ?? 'ε-closure';
    }
    final transition = node.transitionUsed?.trim();
    if (transition != null && transition.isNotEmpty) return transition;
    if (node.inputSymbol == null || node.inputSymbol!.isEmpty) return 'ε';
    return node.inputSymbol;
  }

  static String _branchSummary(
    List<ComputationBranchNodeId> nodeIds,
    Map<ComputationBranchNodeId, ComputationBranchNode> nodesById,
  ) {
    if (nodeIds.length <= 3) {
      return nodeIds
          .map((id) => nodesById[id]?.configurationSummary)
          .whereType<String>()
          .join(' → ');
    }
    final first = nodesById[nodeIds.first]?.configurationSummary ?? '';
    final last = nodesById[nodeIds.last]?.configurationSummary ?? '';
    return '$first → … → $last (${nodeIds.length} configurations)';
  }
}
