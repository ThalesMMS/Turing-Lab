//
//  computation_branch.dart
//  Turing Lab
//
//  Family-neutral contracts for inspecting branching computations.
//

import 'dart:collection';

/// Stable identity for one recorded configuration in a computation graph.
final class ComputationBranchNodeId {
  const ComputationBranchNodeId(this.value) : assert(value != '');

  final String value;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ComputationBranchNodeId && other.value == value;

  @override
  int get hashCode => value.hashCode;

  @override
  String toString() => value;
}

/// Stable identity for one root-to-terminal computation branch.
final class ComputationBranchId {
  const ComputationBranchId(this.value) : assert(value != '');

  final String value;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ComputationBranchId && other.value == value;

  @override
  int get hashCode => value.hashCode;

  @override
  String toString() => value;
}

/// Terminal state of a recorded branch.
enum ComputationBranchOutcome {
  accepted,
  rejected,
  dead,
  boundedUnknown,
  cycle,
  cancelled,
  failed,
}

/// Why a simulation cannot provide computation branches to inspect.
enum ComputationBranchesUnavailableReason {
  simulationNotRun,
  branchesNotRecorded,
  deterministicExecution,
  unsupportedSource,
}

/// One configuration in a family-neutral computation graph.
///
/// Summaries are opaque display values supplied by the source adapter. The
/// contract does not assign formal-system-specific meaning to either value.
final class ComputationBranchNode {
  ComputationBranchNode({
    required this.id,
    required this.configurationSummary,
    this.parentId,
    List<ComputationBranchNodeId> childIds = const [],
    this.transitionSummary,
    this.outcome,
  }) : childIds = List.unmodifiable(childIds);

  final ComputationBranchNodeId id;
  final ComputationBranchNodeId? parentId;
  final List<ComputationBranchNodeId> childIds;
  final String configurationSummary;
  final String? transitionSummary;
  final ComputationBranchOutcome? outcome;
}

/// An ordered root-to-terminal view over nodes in a computation graph.
final class ComputationBranch {
  ComputationBranch({
    required this.id,
    required List<ComputationBranchNodeId> nodeIds,
    required this.outcome,
    this.summary,
  }) : nodeIds = List.unmodifiable(nodeIds);

  final ComputationBranchId id;
  final List<ComputationBranchNodeId> nodeIds;
  final ComputationBranchOutcome outcome;
  final String? summary;
}

/// Immutable computation graph shared by branch inspectors and adapters.
///
/// Cycles are valid. Lookups and selection resolution never walk recursively,
/// so malformed or bounded source data cannot trap the interface.
final class ComputationBranchGraph {
  ComputationBranchGraph({
    required Iterable<ComputationBranchNode> nodes,
    required Iterable<ComputationBranch> branches,
    required Iterable<ComputationBranchNodeId> rootNodeIds,
  })  : nodes = List.unmodifiable(nodes),
        branches = List.unmodifiable(branches),
        rootNodeIds = List.unmodifiable(rootNodeIds) {
    _nodesById = _indexNodes(this.nodes);
    _branchesById = _indexBranches(this.branches);
  }

  final List<ComputationBranchNode> nodes;
  final List<ComputationBranch> branches;
  final List<ComputationBranchNodeId> rootNodeIds;

  late final Map<ComputationBranchNodeId, ComputationBranchNode> _nodesById;
  late final Map<ComputationBranchId, ComputationBranch> _branchesById;

  static Map<ComputationBranchNodeId, ComputationBranchNode> _indexNodes(
    List<ComputationBranchNode> nodes,
  ) {
    final indexed = <ComputationBranchNodeId, ComputationBranchNode>{};
    for (final node in nodes) {
      if (indexed.containsKey(node.id)) {
        throw ArgumentError.value(node.id, 'nodes', 'Duplicate node identity');
      }
      indexed[node.id] = node;
    }
    return UnmodifiableMapView(indexed);
  }

  static Map<ComputationBranchId, ComputationBranch> _indexBranches(
    List<ComputationBranch> branches,
  ) {
    final indexed = <ComputationBranchId, ComputationBranch>{};
    for (final branch in branches) {
      if (indexed.containsKey(branch.id)) {
        throw ArgumentError.value(
          branch.id,
          'branches',
          'Duplicate branch identity',
        );
      }
      indexed[branch.id] = branch;
    }
    return UnmodifiableMapView(indexed);
  }

  ComputationBranchNode? node(ComputationBranchNodeId? id) =>
      id == null ? null : _nodesById[id];

  ComputationBranch? branch(ComputationBranchId? id) =>
      id == null ? null : _branchesById[id];

  /// Returns the unique, known nodes in [branch], preserving recorded order.
  List<ComputationBranchNode> nodesForBranch(ComputationBranch branch) {
    final seen = <ComputationBranchNodeId>{};
    return List.unmodifiable(
      branch.nodeIds
          .where(seen.add)
          .map(node)
          .whereType<ComputationBranchNode>(),
    );
  }

  /// Resolves stale or absent external selection to a safe visible value.
  ComputationBranchSelection resolveSelection({
    ComputationBranchId? branchId,
    ComputationBranchNodeId? nodeId,
  }) {
    final selectedBranch =
        branch(branchId) ?? (branches.isEmpty ? null : branches.first);
    final visibleNodes = selectedBranch == null
        ? const <ComputationBranchNode>[]
        : nodesForBranch(selectedBranch);
    final requestedNode = node(nodeId);
    final selectedNode = requestedNode != null &&
            (selectedBranch == null ||
                selectedBranch.nodeIds.contains(requestedNode.id))
        ? requestedNode
        : (visibleNodes.isEmpty ? null : visibleNodes.first);
    return ComputationBranchSelection(
      branchId: selectedBranch?.id,
      nodeId: selectedNode?.id,
    );
  }

  /// Calculates indentation without assuming the parent chain is acyclic.
  int safeDepthOf(
    ComputationBranchNodeId id, {
    int maximumDepth = 64,
  }) {
    var depth = 0;
    var current = node(id);
    final visited = <ComputationBranchNodeId>{id};
    while (current?.parentId != null && depth < maximumDepth) {
      final parentId = current!.parentId!;
      if (!visited.add(parentId)) break;
      final parent = node(parentId);
      if (parent == null) break;
      depth += 1;
      current = parent;
    }
    return depth;
  }
}

/// Current branch and node selected by an inspector.
final class ComputationBranchSelection {
  const ComputationBranchSelection({this.branchId, this.nodeId});

  final ComputationBranchId? branchId;
  final ComputationBranchNodeId? nodeId;
}

/// Data state consumed by a computation branch inspector.
sealed class ComputationBranchesAvailability {
  const ComputationBranchesAvailability();
}

final class ComputationBranchesAvailable
    extends ComputationBranchesAvailability {
  const ComputationBranchesAvailable(this.graph);

  final ComputationBranchGraph graph;
}

final class ComputationBranchesUnavailable
    extends ComputationBranchesAvailability {
  const ComputationBranchesUnavailable(this.reason);

  final ComputationBranchesUnavailableReason reason;
}
