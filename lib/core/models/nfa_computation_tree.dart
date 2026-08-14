//
//  nfa_computation_tree.dart
//  Turing Lab
//
//  Modela a árvore de computação completa de um NFA, armazenando o nó raiz,
//  metadados sobre a simulação e oferecendo métodos de travessia, análise
//  de aceitação e estatísticas sobre caminhos. Permite visualização educacional
//  de não determinismo através de estruturas em árvore, rastreamento de becos
//  sem saída e identificação de caminhos de sucesso.
//
//  Thales Matheus Mendonça Santos - January 2026
//

import 'dart:collection';

import 'nfa_path_node.dart';

/// Represents the complete computation tree for an NFA simulation,
/// capturing all non-deterministic execution paths from start to finish.
class NFAComputationTree {
  /// Root node of the computation tree (initial state)
  final NFAPathNode root;

  /// Original input string being processed
  final String inputString;

  /// Whether the NFA accepted the input (at least one accepting path exists)
  final bool accepted;

  /// Optional error message if simulation failed
  final String errorMessage;

  /// Total number of computation steps performed
  final int totalSteps;

  NFAComputationTree._({
    required this.root,
    required this.inputString,
    required this.accepted,
    this.errorMessage = '',
    required this.totalSteps,
  });

  /// Creates a computation tree for a successful NFA simulation
  factory NFAComputationTree.accepted({
    required NFAPathNode root,
    required String inputString,
    required int totalSteps,
  }) {
    return NFAComputationTree._(
      root: root,
      inputString: inputString,
      accepted: true,
      totalSteps: totalSteps,
    );
  }

  /// Creates a computation tree for a rejected NFA simulation
  factory NFAComputationTree.rejected({
    required NFAPathNode root,
    required String inputString,
    required int totalSteps,
    String errorMessage = 'No accepting path found',
  }) {
    return NFAComputationTree._(
      root: root,
      inputString: inputString,
      accepted: false,
      errorMessage: errorMessage,
      totalSteps: totalSteps,
    );
  }

  /// Creates a computation tree for a timed-out simulation
  factory NFAComputationTree.timeout({
    required NFAPathNode root,
    required String inputString,
    required int totalSteps,
  }) {
    return NFAComputationTree._(
      root: root,
      inputString: inputString,
      accepted: false,
      errorMessage: 'Simulation timed out after $totalSteps steps',
      totalSteps: totalSteps,
    );
  }

  /// Creates a computation tree for a simulation that detected infinite loop
  factory NFAComputationTree.infiniteLoop({
    required NFAPathNode root,
    required String inputString,
    required int totalSteps,
  }) {
    return NFAComputationTree._(
      root: root,
      inputString: inputString,
      accepted: false,
      errorMessage: 'Infinite loop detected after $totalSteps steps',
      totalSteps: totalSteps,
    );
  }

  /// Creates a copy of this computation tree with updated properties
  NFAComputationTree copyWith({
    NFAPathNode? root,
    String? inputString,
    bool? accepted,
    String? errorMessage,
    int? totalSteps,
  }) {
    return NFAComputationTree._(
      root: root ?? this.root,
      inputString: inputString ?? this.inputString,
      accepted: accepted ?? this.accepted,
      errorMessage: errorMessage ?? this.errorMessage,
      totalSteps: totalSteps ?? this.totalSteps,
    );
  }

  /// Converts the computation tree to a JSON representation
  Map<String, dynamic> toJson() {
    return {
      'root': root.toJson(),
      'inputString': inputString,
      'accepted': accepted,
      'errorMessage': errorMessage,
      'totalSteps': totalSteps,
    };
  }

  /// Creates a computation tree from a JSON representation
  factory NFAComputationTree.fromJson(Map<String, dynamic> json) {
    return NFAComputationTree._(
      root: NFAPathNode.fromJson(json['root'] as Map<String, dynamic>),
      inputString: json['inputString'] as String,
      accepted: json['accepted'] as bool,
      errorMessage: json['errorMessage'] as String? ?? '',
      totalSteps: json['totalSteps'] as int,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is NFAComputationTree &&
        other.root == root &&
        other.inputString == inputString &&
        other.accepted == accepted &&
        other.errorMessage == errorMessage &&
        other.totalSteps == totalSteps;
  }

  @override
  int get hashCode {
    return Object.hash(root, inputString, accepted, errorMessage, totalSteps);
  }

  @override
  String toString() {
    return 'NFAComputationTree(inputString: $inputString, accepted: $accepted, '
        'totalNodes: $totalNodes, totalPaths: $totalPaths, '
        'acceptingPaths: ${acceptingPaths.length})';
  }

  /// Gets all nodes in the tree using breadth-first traversal
  List<NFAPathNode> get allNodes => root.breadthFirstTraversal();

  /// Gets all nodes in the tree using depth-first traversal
  List<NFAPathNode> get allNodesDepthFirst => root.depthFirstTraversal();

  /// Gets all leaf nodes (terminal paths) in the tree
  List<NFAPathNode> get leafNodes => root.collectLeafNodes();

  /// Gets all complete paths from root to accepting leaves
  List<List<NFAPathNode>> get acceptingPaths => root.collectAcceptingPaths();

  /// Gets all complete paths from root to dead-end leaves
  List<List<NFAPathNode>> get deadEndPaths => root.collectDeadEndPaths();

  /// Gets the total number of nodes in the tree
  int get totalNodes => root.countNodes();

  /// Gets the total number of paths (leaf nodes)
  int get totalPaths => leafNodes.length;

  /// Gets the maximum depth of the tree
  int get maxDepth => root.getMaxDepth();

  /// Gets the number of accepting paths
  int get acceptingPathCount => acceptingPaths.length;

  /// Gets the number of dead-end paths
  int get deadEndPathCount => deadEndPaths.length;

  /// Checks if the simulation was successful (accepted and no errors)
  bool get isSuccessful => accepted && errorMessage.isEmpty;

  /// Checks if the simulation failed
  bool get isFailed => !accepted || errorMessage.isNotEmpty;

  /// Checks if the simulation timed out
  bool get isTimeout =>
      errorMessage.contains('timeout') || errorMessage.contains('Timeout');

  /// Checks if the simulation detected an infinite loop
  bool get isInfiniteLoop =>
      errorMessage.contains('infinite loop') ||
      errorMessage.contains('Infinite loop');

  /// Checks if the tree has any branches (non-determinism)
  bool get hasBranches =>
      root.breadthFirstTraversal().any((n) => n.hasBranches);

  /// Gets the maximum branching factor in the tree
  int get maxBranchingFactor {
    int maxBranches = 0;
    for (final node in allNodes) {
      if (node.branchCount > maxBranches) {
        maxBranches = node.branchCount;
      }
    }
    return maxBranches;
  }

  /// Finds a specific node at a given step number
  NFAPathNode? findNodeAtStep(int step) {
    return root.findNodeAtStep(step);
  }

  /// Gets all nodes at a specific depth level
  List<NFAPathNode> getNodesAtDepth(int depth) {
    final nodesAtDepth = <NFAPathNode>[];
    final queue = Queue<({NFAPathNode node, int depth})>()
      ..add((node: root, depth: 0));

    while (queue.isNotEmpty) {
      final current = queue.removeFirst();
      if (current.depth == depth) {
        nodesAtDepth.add(current.node);
      } else if (current.depth < depth) {
        for (final child in current.node.children) {
          queue.add((node: child, depth: current.depth + 1));
        }
      }
    }

    return nodesAtDepth;
  }

  /// Gets a detailed explanation of the computation tree structure.
  ///
  /// This method provides an educational summary of the tree, including
  /// statistics about paths, branches, and outcomes.
  String get analysisReport {
    final buffer = StringBuffer();
    buffer.writeln('NFA Computation Tree Analysis');
    buffer.writeln('=' * 40);
    buffer.writeln('Input: "$inputString"');
    buffer.writeln('Result: ${accepted ? "ACCEPTED" : "REJECTED"}');

    if (errorMessage.isNotEmpty) {
      buffer.writeln('Error: $errorMessage');
    }

    buffer.writeln();
    buffer.writeln('Tree Statistics:');
    buffer.writeln('  Total nodes: $totalNodes');
    buffer.writeln('  Total paths: $totalPaths');
    buffer.writeln('  Maximum depth: $maxDepth');
    buffer.writeln('  Maximum branching factor: $maxBranchingFactor');
    buffer.writeln('  Has non-determinism: ${hasBranches ? "Yes" : "No"}');

    buffer.writeln();
    buffer.writeln('Path Analysis:');
    buffer.writeln('  Accepting paths: $acceptingPathCount');
    buffer.writeln('  Dead-end paths: $deadEndPathCount');

    if (acceptingPaths.isNotEmpty) {
      buffer.writeln();
      buffer.writeln('Accepting Paths:');
      for (int i = 0; i < acceptingPaths.length; i++) {
        final path = acceptingPaths[i];
        buffer.write('  Path ${i + 1}: ');
        buffer.write(path.map((n) => n.currentState).join(' → '));
        buffer.writeln(' (${path.length} steps)');
      }
    }

    if (deadEndPaths.isNotEmpty && deadEndPaths.length <= 5) {
      buffer.writeln();
      buffer.writeln('Dead-end Paths (sample):');
      for (int i = 0; i < deadEndPaths.length.clamp(0, 5); i++) {
        final path = deadEndPaths[i];
        buffer.write('  Path ${i + 1}: ');
        buffer.write(path.map((n) => n.currentState).join(' → '));
        buffer.writeln(' (${path.length} steps)');
      }
    }

    return buffer.toString();
  }

  /// Gets a summary of why the input was rejected (if applicable).
  ///
  /// This method analyzes the computation tree and provides an educational
  /// explanation of the rejection, helping students understand the NFA's
  /// non-deterministic behavior.
  String get rejectionReason {
    // If accepted, no rejection reason
    if (accepted) {
      return '';
    }

    // If there's already a specific error message, use it
    if (errorMessage.isNotEmpty) {
      return errorMessage;
    }

    // Analyze paths to determine rejection reason
    final buffer = StringBuffer();

    if (totalPaths == 0) {
      buffer.write(
        'No computation paths were generated from the initial state.',
      );
    } else if (deadEndPathCount == totalPaths) {
      buffer.write('All $totalPaths computation paths ended in dead-ends. ');
      if (hasBranches) {
        buffer.write(
          'Despite non-deterministic branching, no path reached an accepting state.',
        );
      } else {
        buffer.write(
          'The NFA followed a deterministic path that did not reach an accepting state.',
        );
      }
    } else {
      buffer.write(
        'The NFA explored $totalPaths different computation paths, ',
      );
      buffer.write(
        'but none of them reached an accepting state with all input consumed.',
      );
    }

    return buffer.toString();
  }

  /// Gets a collection of statistics about the computation tree
  Map<String, dynamic> get statistics {
    return {
      'totalNodes': totalNodes,
      'totalPaths': totalPaths,
      'maxDepth': maxDepth,
      'maxBranchingFactor': maxBranchingFactor,
      'acceptingPathCount': acceptingPathCount,
      'deadEndPathCount': deadEndPathCount,
      'hasBranches': hasBranches,
      'accepted': accepted,
      'totalSteps': totalSteps,
    };
  }

  /// Validates the tree structure for consistency
  bool validate() {
    // Check that accepted status matches accepting paths
    final hasAcceptingPaths = acceptingPathCount > 0;
    if (accepted && !hasAcceptingPaths) {
      return false;
    }

    // Check that total steps is non-negative
    if (totalSteps < 0) {
      return false;
    }

    return true;
  }
}
