//
//  nfa_path_node.dart
//  Turing Lab
//
//  Represents a node in an NFA computation tree, capturing the current
//  state, remaining input, used transition, and child branches. Enables full
//  tracking of nondeterministic paths, dead-end identification, and
//  serialization for tree visualization. Offers helper methods for traversal
//  and acceptance analysis.
//
//  Thales Matheus Mendonça Santos - January 2026
//

import 'dart:collection';

/// Single node in an NFA computation tree representing a branch point
class NFAPathNode {
  /// Current state ID at this node
  final String currentState;

  /// Remaining input string to process
  final String remainingInput;

  /// Input symbol consumed to reach this node (null for epsilon or initial)
  final String? inputSymbol;

  /// Transition description used to reach this node
  final String? transitionUsed;

  /// Step number in the simulation
  final int stepNumber;

  /// Child branches from this node (empty for leaf nodes)
  final List<NFAPathNode> children;

  /// Whether this path leads to acceptance
  final bool isAccepting;

  /// Whether this path is a dead-end (no valid transitions)
  final bool isDeadEnd;

  /// Optional description of this node
  final String? description;

  const NFAPathNode({
    required this.currentState,
    required this.remainingInput,
    this.inputSymbol,
    this.transitionUsed,
    required this.stepNumber,
    this.children = const [],
    this.isAccepting = false,
    this.isDeadEnd = false,
    this.description,
  });

  /// Creates a copy of this path node with updated properties
  NFAPathNode copyWith({
    String? currentState,
    String? remainingInput,
    String? inputSymbol,
    String? transitionUsed,
    int? stepNumber,
    List<NFAPathNode>? children,
    bool? isAccepting,
    bool? isDeadEnd,
    String? description,
  }) {
    return NFAPathNode(
      currentState: currentState ?? this.currentState,
      remainingInput: remainingInput ?? this.remainingInput,
      inputSymbol: inputSymbol ?? this.inputSymbol,
      transitionUsed: transitionUsed ?? this.transitionUsed,
      stepNumber: stepNumber ?? this.stepNumber,
      children: children ?? this.children,
      isAccepting: isAccepting ?? this.isAccepting,
      isDeadEnd: isDeadEnd ?? this.isDeadEnd,
      description: description ?? this.description,
    );
  }

  /// Adds a child node to this path node
  NFAPathNode addChild(NFAPathNode child) {
    return copyWith(children: [...children, child]);
  }

  /// Converts the path node to a JSON representation
  Map<String, dynamic> toJson() {
    return {
      'currentState': currentState,
      'remainingInput': remainingInput,
      'inputSymbol': inputSymbol,
      'transitionUsed': transitionUsed,
      'stepNumber': stepNumber,
      'children': children.map((c) => c.toJson()).toList(),
      'isAccepting': isAccepting,
      'isDeadEnd': isDeadEnd,
      'description': description,
    };
  }

  /// Creates a path node from a JSON representation
  factory NFAPathNode.fromJson(Map<String, dynamic> json) {
    return NFAPathNode(
      currentState: json['currentState'] as String,
      remainingInput: json['remainingInput'] as String,
      inputSymbol: json['inputSymbol'] as String?,
      transitionUsed: json['transitionUsed'] as String?,
      stepNumber: json['stepNumber'] as int,
      children: (json['children'] as List?)
              ?.map((c) => NFAPathNode.fromJson(c as Map<String, dynamic>))
              .toList() ??
          const [],
      isAccepting: json['isAccepting'] as bool? ?? false,
      isDeadEnd: json['isDeadEnd'] as bool? ?? false,
      description: json['description'] as String?,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is NFAPathNode &&
        other.currentState == currentState &&
        other.remainingInput == remainingInput &&
        other.inputSymbol == inputSymbol &&
        other.transitionUsed == transitionUsed &&
        other.stepNumber == stepNumber &&
        _listEquals(other.children, children) &&
        other.isAccepting == isAccepting &&
        other.isDeadEnd == isDeadEnd &&
        other.description == description;
  }

  @override
  int get hashCode {
    return Object.hash(
      currentState,
      remainingInput,
      inputSymbol,
      transitionUsed,
      stepNumber,
      Object.hashAll(children),
      isAccepting,
      isDeadEnd,
      description,
    );
  }

  @override
  String toString() {
    return 'NFAPathNode(stepNumber: $stepNumber, currentState: $currentState, '
        'remainingInput: $remainingInput, children: ${children.length}, '
        'isAccepting: $isAccepting, isDeadEnd: $isDeadEnd)';
  }

  /// Helper method for comparing lists
  bool _listEquals<T>(List<T> a, List<T> b) {
    if (a.length != b.length) return false;
    for (int i = 0; i < a.length; i++) {
      if (a[i] != b[i]) return false;
    }
    return true;
  }

  /// Checks if this is a leaf node (no children)
  bool get isLeaf => children.isEmpty;

  /// Checks if this node has branches (multiple children)
  bool get hasBranches => children.length > 1;

  /// Gets the number of child branches
  int get branchCount => children.length;

  /// Checks if this is the initial node (step 0)
  bool get isInitial => stepNumber == 0;

  /// Checks if input has been fully consumed
  bool get hasConsumedAllInput => remainingInput.isEmpty;

  /// Gets the number of remaining input symbols
  int get remainingInputLength => remainingInput.length;

  /// Gets the consumed input (reconstructed from remaining)
  String get consumedInput {
    // Note: This is relative to the parent node
    // To get full consumed input, need to traverse from root
    return inputSymbol ?? '';
  }

  /// Checks if this path should be highlighted (accepting or active)
  bool get shouldHighlight => isAccepting || (!isDeadEnd && !isLeaf);

  /// Collects all leaf nodes (terminal paths) in this subtree
  List<NFAPathNode> collectLeafNodes() {
    if (isLeaf) {
      return [this];
    }
    final leaves = <NFAPathNode>[];
    for (final child in children) {
      leaves.addAll(child.collectLeafNodes());
    }
    return leaves;
  }

  /// Collects all accepting paths from this node
  List<List<NFAPathNode>> collectAcceptingPaths() {
    if (isLeaf) {
      return isAccepting
          ? [
              [this],
            ]
          : [];
    }
    final paths = <List<NFAPathNode>>[];
    for (final child in children) {
      final childPaths = child.collectAcceptingPaths();
      for (final path in childPaths) {
        paths.add([this, ...path]);
      }
    }
    return paths;
  }

  /// Collects all dead-end paths from this node
  List<List<NFAPathNode>> collectDeadEndPaths() {
    if (isLeaf) {
      return isDeadEnd
          ? [
              [this],
            ]
          : [];
    }
    final paths = <List<NFAPathNode>>[];
    for (final child in children) {
      final childPaths = child.collectDeadEndPaths();
      for (final path in childPaths) {
        paths.add([this, ...path]);
      }
    }
    return paths;
  }

  /// Counts total nodes in this subtree
  int countNodes() {
    int count = 1; // Count this node
    for (final child in children) {
      count += child.countNodes();
    }
    return count;
  }

  /// Gets the maximum depth of this subtree
  int getMaxDepth() {
    if (isLeaf) return 0;
    int maxChildDepth = 0;
    for (final child in children) {
      final childDepth = child.getMaxDepth();
      if (childDepth > maxChildDepth) {
        maxChildDepth = childDepth;
      }
    }
    return maxChildDepth + 1;
  }

  /// Finds a node at a specific step number
  NFAPathNode? findNodeAtStep(int step) {
    if (stepNumber == step) return this;
    for (final child in children) {
      final found = child.findNodeAtStep(step);
      if (found != null) return found;
    }
    return null;
  }

  /// Traverses the tree in breadth-first order
  List<NFAPathNode> breadthFirstTraversal() {
    final result = <NFAPathNode>[];
    final queue = Queue<NFAPathNode>()..add(this);
    while (queue.isNotEmpty) {
      final node = queue.removeFirst();
      result.add(node);
      queue.addAll(node.children);
    }
    return result;
  }

  /// Traverses the tree in depth-first order
  List<NFAPathNode> depthFirstTraversal() {
    final result = <NFAPathNode>[this];
    for (final child in children) {
      result.addAll(child.depthFirstTraversal());
    }
    return result;
  }
}
