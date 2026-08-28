import 'package:flutter_test/flutter_test.dart';
import 'package:turing_lab/core/models/computation_branch.dart';

void main() {
  group('ComputationBranchGraph', () {
    test('keeps typed identities and shared parent-child structure', () {
      final graph = _graph();

      expect(graph.nodes, hasLength(3));
      expect(graph.branches, hasLength(2));
      expect(graph.node(const ComputationBranchNodeId('root'))?.childIds, [
        const ComputationBranchNodeId('accepted'),
        const ComputationBranchNodeId('dead'),
      ]);
      expect(
        graph.node(const ComputationBranchNodeId('accepted'))?.parentId,
        const ComputationBranchNodeId('root'),
      );
      expect(
        graph.branch(const ComputationBranchId('accept'))?.outcome,
        ComputationBranchOutcome.accepted,
      );
    });

    test('resolves stale branch and node selection to recorded identities', () {
      final graph = _graph();

      final selection = graph.resolveSelection(
        branchId: const ComputationBranchId('missing'),
        nodeId: const ComputationBranchNodeId('dead'),
      );

      expect(selection.branchId, const ComputationBranchId('accept'));
      expect(selection.nodeId, const ComputationBranchNodeId('root'));
    });

    test('deduplicates repeated cycle nodes and bounds parent traversal', () {
      final cycle = ComputationBranchGraph(
        nodes: [
          ComputationBranchNode(
            id: const ComputationBranchNodeId('a'),
            parentId: const ComputationBranchNodeId('b'),
            childIds: const [ComputationBranchNodeId('b')],
            configurationSummary: 'A',
          ),
          ComputationBranchNode(
            id: const ComputationBranchNodeId('b'),
            parentId: const ComputationBranchNodeId('a'),
            childIds: const [ComputationBranchNodeId('a')],
            configurationSummary: 'B',
            outcome: ComputationBranchOutcome.cycle,
          ),
        ],
        branches: [
          ComputationBranch(
            id: const ComputationBranchId('cycle'),
            nodeIds: const [
              ComputationBranchNodeId('a'),
              ComputationBranchNodeId('b'),
              ComputationBranchNodeId('a'),
            ],
            outcome: ComputationBranchOutcome.cycle,
          ),
        ],
        rootNodeIds: const [ComputationBranchNodeId('a')],
      );

      expect(cycle.nodesForBranch(cycle.branches.single), hasLength(2));
      expect(cycle.safeDepthOf(const ComputationBranchNodeId('a')), 1);
      expect(cycle.safeDepthOf(const ComputationBranchNodeId('b')), 1);
    });

    test('rejects duplicate stable identities', () {
      expect(
        () => ComputationBranchGraph(
          nodes: [
            ComputationBranchNode(
              id: const ComputationBranchNodeId('same'),
              configurationSummary: 'First',
            ),
            ComputationBranchNode(
              id: const ComputationBranchNodeId('same'),
              configurationSummary: 'Second',
            ),
          ],
          branches: const [],
          rootNodeIds: const [],
        ),
        throwsArgumentError,
      );
    });
  });

  test('contract distinguishes every terminal outcome and availability reason',
      () {
    expect(ComputationBranchOutcome.values, {
      ComputationBranchOutcome.accepted,
      ComputationBranchOutcome.rejected,
      ComputationBranchOutcome.dead,
      ComputationBranchOutcome.boundedUnknown,
      ComputationBranchOutcome.cycle,
      ComputationBranchOutcome.cancelled,
      ComputationBranchOutcome.failed,
    });
    expect(
      const ComputationBranchesUnavailable(
        ComputationBranchesUnavailableReason.branchesNotRecorded,
      ).reason,
      ComputationBranchesUnavailableReason.branchesNotRecorded,
    );
  });
}

ComputationBranchGraph _graph() {
  return ComputationBranchGraph(
    nodes: [
      ComputationBranchNode(
        id: const ComputationBranchNodeId('root'),
        childIds: const [
          ComputationBranchNodeId('accepted'),
          ComputationBranchNodeId('dead'),
        ],
        configurationSummary: 'q0, input ab',
      ),
      ComputationBranchNode(
        id: const ComputationBranchNodeId('accepted'),
        parentId: const ComputationBranchNodeId('root'),
        configurationSummary: 'q1, input consumed',
        transitionSummary: 'Read ab',
        outcome: ComputationBranchOutcome.accepted,
      ),
      ComputationBranchNode(
        id: const ComputationBranchNodeId('dead'),
        parentId: const ComputationBranchNodeId('root'),
        configurationSummary: 'q2, input b',
        transitionSummary: 'Read a',
        outcome: ComputationBranchOutcome.dead,
      ),
    ],
    branches: [
      ComputationBranch(
        id: const ComputationBranchId('accept'),
        nodeIds: const [
          ComputationBranchNodeId('root'),
          ComputationBranchNodeId('accepted'),
        ],
        outcome: ComputationBranchOutcome.accepted,
      ),
      ComputationBranch(
        id: const ComputationBranchId('dead'),
        nodeIds: const [
          ComputationBranchNodeId('root'),
          ComputationBranchNodeId('dead'),
        ],
        outcome: ComputationBranchOutcome.dead,
      ),
    ],
    rootNodeIds: const [ComputationBranchNodeId('root')],
  );
}
