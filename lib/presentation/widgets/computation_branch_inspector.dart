import 'package:flutter/material.dart';

import '../../core/models/computation_branch.dart';

/// Responsive inspector for a family-neutral computation graph.
class ComputationBranchInspector extends StatelessWidget {
  const ComputationBranchInspector({
    super.key,
    required this.availability,
    required this.onBranchSelected,
    required this.onNodeSelected,
    this.selectedBranchId,
    this.selectedNodeId,
    this.onBranchHighlightRequested,
    this.labels = const ComputationBranchInspectorLabels(),
  });

  static const narrowBreakpoint = 680.0;

  final ComputationBranchesAvailability availability;
  final ComputationBranchId? selectedBranchId;
  final ComputationBranchNodeId? selectedNodeId;
  final ValueChanged<ComputationBranchId> onBranchSelected;
  final ValueChanged<ComputationBranchNodeId> onNodeSelected;
  final ValueChanged<ComputationBranchId>? onBranchHighlightRequested;
  final ComputationBranchInspectorLabels labels;

  @override
  Widget build(BuildContext context) {
    return switch (availability) {
      ComputationBranchesUnavailable(:final reason) =>
        ComputationBranchesUnavailableNotice(reason: reason, labels: labels),
      ComputationBranchesAvailable(:final graph) => LayoutBuilder(
        builder: (context, constraints) {
          final selection = graph.resolveSelection(
            branchId: selectedBranchId,
            nodeId: selectedNodeId,
          );
          return Semantics(
            container: true,
            label: labels.inspectorSemanticLabel,
            child: constraints.maxWidth < narrowBreakpoint
                ? _NarrowInspector(
                    graph: graph,
                    selection: selection,
                    onBranchSelected: onBranchSelected,
                    onNodeSelected: onNodeSelected,
                    onBranchHighlightRequested: onBranchHighlightRequested,
                    labels: labels,
                  )
                : _WideInspector(
                    graph: graph,
                    selection: selection,
                    onBranchSelected: onBranchSelected,
                    onNodeSelected: onNodeSelected,
                    onBranchHighlightRequested: onBranchHighlightRequested,
                    labels: labels,
                  ),
          );
        },
      ),
    };
  }
}

/// Explains why branch inspection is unavailable without storing prose in core.
class ComputationBranchesUnavailableNotice extends StatelessWidget {
  const ComputationBranchesUnavailableNotice({
    super.key,
    required this.reason,
    this.labels = const ComputationBranchInspectorLabels(),
  });

  final ComputationBranchesUnavailableReason reason;
  final ComputationBranchInspectorLabels labels;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      container: true,
      label: labels.unavailableSemanticLabel(reason),
      child: Card.outlined(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(
                Icons.account_tree_outlined,
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      labels.unavailableTitle,
                      style: Theme.of(context).textTheme.titleSmall,
                    ),
                    const SizedBox(height: 4),
                    Text(labels.unavailableReason(reason)),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _NarrowInspector extends StatelessWidget {
  const _NarrowInspector({
    required this.graph,
    required this.selection,
    required this.onBranchSelected,
    required this.onNodeSelected,
    required this.onBranchHighlightRequested,
    required this.labels,
  });

  final ComputationBranchGraph graph;
  final ComputationBranchSelection selection;
  final ValueChanged<ComputationBranchId> onBranchSelected;
  final ValueChanged<ComputationBranchNodeId> onNodeSelected;
  final ValueChanged<ComputationBranchId>? onBranchHighlightRequested;
  final ComputationBranchInspectorLabels labels;

  @override
  Widget build(BuildContext context) {
    final branch = graph.branch(selection.branchId);
    final node = graph.node(selection.nodeId);
    return Column(
      key: const ValueKey('computation-branch-inspector-narrow'),
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(labels.title, style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: 12),
        _BranchSelector(
          graph: graph,
          selectedBranch: branch,
          onSelected: onBranchSelected,
          labels: labels,
        ),
        const SizedBox(height: 8),
        Card.outlined(
          clipBehavior: Clip.antiAlias,
          child: ExpansionTile(
            key: const ValueKey('computation-branch-hierarchy-disclosure'),
            initiallyExpanded: true,
            title: Text(labels.hierarchyTitle),
            subtitle: branch == null
                ? null
                : Text(labels.outcomeLabel(branch.outcome)),
            children: [
              _HierarchyList(
                graph: graph,
                branch: branch,
                selectedNodeId: node?.id,
                onNodeSelected: onNodeSelected,
                labels: labels,
              ),
            ],
          ),
        ),
        const SizedBox(height: 8),
        Card.outlined(
          clipBehavior: Clip.antiAlias,
          child: ExpansionTile(
            key: ValueKey(
              'computation-branch-detail-${node?.id.value ?? 'none'}',
            ),
            title: Text(labels.detailsTitle),
            subtitle: node == null ? null : Text(node.configurationSummary),
            childrenPadding: const EdgeInsetsDirectional.fromSTEB(
              16,
              0,
              16,
              16,
            ),
            children: [
              _NodeDetails(
                branch: branch,
                node: node,
                onBranchHighlightRequested: onBranchHighlightRequested,
                labels: labels,
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _WideInspector extends StatelessWidget {
  const _WideInspector({
    required this.graph,
    required this.selection,
    required this.onBranchSelected,
    required this.onNodeSelected,
    required this.onBranchHighlightRequested,
    required this.labels,
  });

  final ComputationBranchGraph graph;
  final ComputationBranchSelection selection;
  final ValueChanged<ComputationBranchId> onBranchSelected;
  final ValueChanged<ComputationBranchNodeId> onNodeSelected;
  final ValueChanged<ComputationBranchId>? onBranchHighlightRequested;
  final ComputationBranchInspectorLabels labels;

  @override
  Widget build(BuildContext context) {
    final branch = graph.branch(selection.branchId);
    final node = graph.node(selection.nodeId);
    return Column(
      key: const ValueKey('computation-branch-inspector-wide'),
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(labels.title, style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: 12),
        _BranchSelector(
          graph: graph,
          selectedBranch: branch,
          onSelected: onBranchSelected,
          labels: labels,
        ),
        const SizedBox(height: 16),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              flex: 2,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    labels.hierarchyTitle,
                    style: Theme.of(context).textTheme.titleSmall,
                  ),
                  const SizedBox(height: 8),
                  Card.outlined(
                    clipBehavior: Clip.antiAlias,
                    child: _HierarchyList(
                      graph: graph,
                      branch: branch,
                      selectedNodeId: node?.id,
                      onNodeSelected: onNodeSelected,
                      labels: labels,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              flex: 3,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    labels.detailsTitle,
                    style: Theme.of(context).textTheme.titleSmall,
                  ),
                  const SizedBox(height: 8),
                  Card.outlined(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: _NodeDetails(
                        branch: branch,
                        node: node,
                        onBranchHighlightRequested: onBranchHighlightRequested,
                        labels: labels,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _BranchSelector extends StatelessWidget {
  const _BranchSelector({
    required this.graph,
    required this.selectedBranch,
    required this.onSelected,
    required this.labels,
  });

  final ComputationBranchGraph graph;
  final ComputationBranch? selectedBranch;
  final ValueChanged<ComputationBranchId> onSelected;
  final ComputationBranchInspectorLabels labels;

  static const maximumDropdownBranches = 500;

  @override
  Widget build(BuildContext context) {
    if (graph.branches.isEmpty) {
      return Text(labels.noBranches);
    }
    if (graph.branches.length > maximumDropdownBranches) {
      return _BranchNavigator(
        graph: graph,
        selectedBranch: selectedBranch,
        onSelected: onSelected,
        labels: labels,
      );
    }
    return Semantics(
      label: labels.branchSelectorLabel,
      value: selectedBranch == null
          ? null
          : labels.branchName(
              graph.branches.indexOf(selectedBranch!),
              selectedBranch!,
            ),
      child: DropdownButtonFormField<ComputationBranchId>(
        key: const ValueKey('computation-branch-selector'),
        initialValue: selectedBranch?.id,
        isExpanded: true,
        decoration: InputDecoration(
          labelText: labels.branchSelectorLabel,
          border: const OutlineInputBorder(),
        ),
        items: [
          for (var index = 0; index < graph.branches.length; index++)
            DropdownMenuItem(
              value: graph.branches[index].id,
              child: Row(
                children: [
                  Icon(_outcomeIcon(graph.branches[index].outcome), size: 18),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      labels.branchOption(
                        labels.branchName(index, graph.branches[index]),
                        labels.outcomeLabel(graph.branches[index].outcome),
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),
        ],
        onChanged: (id) {
          if (id != null && id != selectedBranch?.id) onSelected(id);
        },
      ),
    );
  }
}

class _BranchNavigator extends StatelessWidget {
  const _BranchNavigator({
    required this.graph,
    required this.selectedBranch,
    required this.onSelected,
    required this.labels,
  });

  final ComputationBranchGraph graph;
  final ComputationBranch? selectedBranch;
  final ValueChanged<ComputationBranchId> onSelected;
  final ComputationBranchInspectorLabels labels;

  @override
  Widget build(BuildContext context) {
    final requestedIndex = selectedBranch == null
        ? 0
        : graph.branches.indexWhere(
            (branch) => branch.id == selectedBranch!.id,
          );
    final index = requestedIndex < 0 ? 0 : requestedIndex;
    final branch = graph.branches[index];
    final position = labels.branchPosition(index + 1, graph.branches.length);
    final branchLabel = labels.branchName(index, branch);
    final outcome = labels.outcomeLabel(branch.outcome);

    return Row(
      key: const ValueKey('computation-branch-navigator'),
      children: [
        Tooltip(
          message: labels.previousBranch,
          excludeFromSemantics: true,
          child: IconButton.outlined(
            key: const ValueKey('computation-branch-previous'),
            onPressed: index == 0
                ? null
                : () => onSelected(graph.branches[index - 1].id),
            icon: Icon(
              Icons.chevron_left,
              semanticLabel: labels.previousBranch,
            ),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Semantics(
            liveRegion: true,
            label: labels.branchAnnouncement(position, branchLabel, outcome),
            excludeSemantics: true,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(position, style: Theme.of(context).textTheme.labelLarge),
                Text(
                  labels.branchOption(branchLabel, outcome),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ),
        const SizedBox(width: 8),
        Tooltip(
          message: labels.nextBranch,
          excludeFromSemantics: true,
          child: IconButton.outlined(
            key: const ValueKey('computation-branch-next'),
            onPressed: index == graph.branches.length - 1
                ? null
                : () => onSelected(graph.branches[index + 1].id),
            icon: Icon(Icons.chevron_right, semanticLabel: labels.nextBranch),
          ),
        ),
      ],
    );
  }
}

class _HierarchyList extends StatelessWidget {
  const _HierarchyList({
    required this.graph,
    required this.branch,
    required this.selectedNodeId,
    required this.onNodeSelected,
    required this.labels,
  });

  static const maximumVisibleNodes = 500;

  final ComputationBranchGraph graph;
  final ComputationBranch? branch;
  final ComputationBranchNodeId? selectedNodeId;
  final ValueChanged<ComputationBranchNodeId> onNodeSelected;
  final ComputationBranchInspectorLabels labels;

  @override
  Widget build(BuildContext context) {
    if (branch == null) {
      return Padding(
        padding: const EdgeInsets.all(16),
        child: Text(labels.noBranches),
      );
    }
    final allNodes = graph.nodesForBranch(branch!);
    if (allNodes.isEmpty) {
      return Padding(
        padding: const EdgeInsets.all(16),
        child: Text(labels.noConfigurations),
      );
    }
    final selectedIndex = allNodes.indexWhere(
      (node) => node.id == selectedNodeId,
    );
    final pageStart = selectedIndex < 0
        ? 0
        : (selectedIndex ~/ maximumVisibleNodes) * maximumVisibleNodes;
    final pageEnd = (pageStart + maximumVisibleNodes).clamp(0, allNodes.length);
    final nodes = allNodes.sublist(pageStart, pageEnd);
    final hasMultiplePages = allNodes.length > maximumVisibleNodes;
    final previousPageIndex = pageStart == 0
        ? null
        : (pageStart - maximumVisibleNodes).clamp(0, allNodes.length - 1);
    final nextPageIndex = pageEnd >= allNodes.length ? null : pageEnd;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (hasMultiplePages)
          Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                Tooltip(
                  message: labels.previousConfigurations,
                  excludeFromSemantics: true,
                  child: IconButton.outlined(
                    key: const ValueKey('computation-configurations-previous'),
                    onPressed: previousPageIndex == null
                        ? null
                        : () => onNodeSelected(allNodes[previousPageIndex].id),
                    icon: Icon(
                      Icons.chevron_left,
                      semanticLabel: labels.previousConfigurations,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Semantics(
                    liveRegion: true,
                    label: labels.configurationRange(
                      pageStart + 1,
                      pageEnd,
                      allNodes.length,
                    ),
                    excludeSemantics: true,
                    child: Text(
                      labels.configurationRange(
                        pageStart + 1,
                        pageEnd,
                        allNodes.length,
                      ),
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.labelLarge,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Tooltip(
                  message: labels.nextConfigurations,
                  excludeFromSemantics: true,
                  child: IconButton.outlined(
                    key: const ValueKey('computation-configurations-next'),
                    onPressed: nextPageIndex == null
                        ? null
                        : () => onNodeSelected(allNodes[nextPageIndex].id),
                    icon: Icon(
                      Icons.chevron_right,
                      semanticLabel: labels.nextConfigurations,
                    ),
                  ),
                ),
              ],
            ),
          ),
        for (var index = 0; index < nodes.length; index++)
          _NodeTile(
            graph: graph,
            node: nodes[index],
            index: pageStart + index,
            selected: nodes[index].id == selectedNodeId,
            branchOutcome: pageStart + index == allNodes.length - 1
                ? branch!.outcome
                : null,
            onSelected: onNodeSelected,
            labels: labels,
          ),
      ],
    );
  }
}

class _NodeTile extends StatelessWidget {
  const _NodeTile({
    required this.graph,
    required this.node,
    required this.index,
    required this.selected,
    required this.branchOutcome,
    required this.onSelected,
    required this.labels,
  });

  final ComputationBranchGraph graph;
  final ComputationBranchNode node;
  final int index;
  final bool selected;
  final ComputationBranchOutcome? branchOutcome;
  final ValueChanged<ComputationBranchNodeId> onSelected;
  final ComputationBranchInspectorLabels labels;

  @override
  Widget build(BuildContext context) {
    final outcome = node.outcome ?? branchOutcome;
    final depth = graph.safeDepthOf(node.id).clamp(0, 8);
    final semanticOutcome = outcome == null
        ? ''
        : ', ${labels.outcomeLabel(outcome)}';
    void activate() => onSelected(node.id);

    return Padding(
      padding: EdgeInsetsDirectional.only(start: depth * 12.0),
      child: Semantics(
        key: ValueKey('computation-branch-node-${node.id.value}'),
        button: true,
        selected: selected,
        onTap: activate,
        label:
            '${labels.configurationName(index)}, ${node.configurationSummary}'
            '$semanticOutcome',
        excludeSemantics: true,
        child: ListTile(
          selected: selected,
          focusColor: Theme.of(context).colorScheme.secondaryContainer,
          leading: Icon(
            outcome == null ? Icons.circle_outlined : _outcomeIcon(outcome),
          ),
          title: Text(node.configurationSummary),
          subtitle: node.transitionSummary == null
              ? (outcome == null ? null : Text(labels.outcomeLabel(outcome)))
              : Text(
                  outcome == null
                      ? node.transitionSummary!
                      : '${node.transitionSummary} · '
                            '${labels.outcomeLabel(outcome)}',
                ),
          onTap: activate,
        ),
      ),
    );
  }
}

class _NodeDetails extends StatelessWidget {
  const _NodeDetails({
    required this.branch,
    required this.node,
    required this.onBranchHighlightRequested,
    required this.labels,
  });

  final ComputationBranch? branch;
  final ComputationBranchNode? node;
  final ValueChanged<ComputationBranchId>? onBranchHighlightRequested;
  final ComputationBranchInspectorLabels labels;

  @override
  Widget build(BuildContext context) {
    if (node == null) return Text(labels.selectConfiguration);
    final outcome = node!.outcome ?? branch?.outcome;
    return Semantics(
      container: true,
      label: labels.configurationDetailsSemanticLabel(
        node!.configurationSummary,
        outcome,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _DetailRow(
            label: labels.configurationLabel,
            value: node!.configurationSummary,
          ),
          if (node!.transitionSummary != null) ...[
            const SizedBox(height: 12),
            _DetailRow(
              label: labels.transitionLabel,
              value: node!.transitionSummary!,
            ),
          ],
          if (outcome != null) ...[
            const SizedBox(height: 12),
            _OutcomeBadge(outcome: outcome, labels: labels),
          ],
          if (branch != null && onBranchHighlightRequested != null) ...[
            const SizedBox(height: 16),
            OutlinedButton.icon(
              key: const ValueKey('computation-branch-highlight'),
              onPressed: () => onBranchHighlightRequested!(branch!.id),
              icon: const Icon(Icons.visibility_outlined),
              label: Text(labels.highlightBranch),
            ),
          ],
        ],
      ),
    );
  }
}

class _DetailRow extends StatelessWidget {
  const _DetailRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: Theme.of(context).textTheme.labelMedium),
        const SizedBox(height: 2),
        SelectableText(value),
      ],
    );
  }
}

class _OutcomeBadge extends StatelessWidget {
  const _OutcomeBadge({required this.outcome, required this.labels});

  final ComputationBranchOutcome outcome;
  final ComputationBranchInspectorLabels labels;

  @override
  Widget build(BuildContext context) {
    final label = labels.outcomeLabel(outcome);
    return Semantics(
      label: labels.outcomeSemanticLabel(label),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(_outcomeIcon(outcome), size: 20),
          const SizedBox(width: 8),
          Flexible(child: Text(label)),
        ],
      ),
    );
  }
}

IconData _outcomeIcon(ComputationBranchOutcome outcome) => switch (outcome) {
  ComputationBranchOutcome.accepted => Icons.check_circle_outline,
  ComputationBranchOutcome.rejected => Icons.cancel_outlined,
  ComputationBranchOutcome.dead => Icons.block_outlined,
  ComputationBranchOutcome.boundedUnknown => Icons.more_horiz,
  ComputationBranchOutcome.cycle => Icons.loop,
  ComputationBranchOutcome.cancelled => Icons.pause_circle_outline,
  ComputationBranchOutcome.failed => Icons.error_outline,
};

/// User-facing strings for [ComputationBranchInspector].
///
/// The default English copy keeps the widget usable in isolated tools. Product
/// integrations can pass localized values without changing the core contract.
class ComputationBranchInspectorLabels {
  const ComputationBranchInspectorLabels({
    this.title = 'Computation branches',
    this.inspectorSemanticLabel = 'Computation branch inspector',
    this.branchSelectorLabel = 'Branch',
    this.hierarchyTitle = 'Configurations',
    this.detailsTitle = 'Configuration details',
    this.configurationLabel = 'Configuration',
    this.transitionLabel = 'Transition',
    this.outcomeLabelPrefix = 'Outcome',
    this.highlightBranch = 'Highlight branch',
    this.selectConfiguration = 'Select a configuration to inspect it.',
    this.noBranches = 'No computation branches were recorded.',
    this.noConfigurations = 'This branch has no recorded configurations.',
    this.unavailableTitle = 'Branch inspection unavailable',
    this.branchPrefix = 'Branch',
    this.previousBranch = 'Previous branch',
    this.nextBranch = 'Next branch',
    this.previousConfigurations = 'Previous configurations',
    this.nextConfigurations = 'Next configurations',
    this.configurationPrefix = 'Configuration',
    this.outcomeLabels = const {
      ComputationBranchOutcome.accepted: 'Accepted',
      ComputationBranchOutcome.rejected: 'Rejected',
      ComputationBranchOutcome.dead: 'Dead end',
      ComputationBranchOutcome.boundedUnknown: 'Unknown at execution bound',
      ComputationBranchOutcome.cycle: 'Cycle detected',
      ComputationBranchOutcome.cancelled: 'Cancelled',
      ComputationBranchOutcome.failed: 'Failed',
    },
    this.unavailableReasons = const {
      ComputationBranchesUnavailableReason.simulationNotRun:
          'Run a simulation to inspect its branches.',
      ComputationBranchesUnavailableReason.branchesNotRecorded:
          'This simulation records a trace but not every explored branch.',
      ComputationBranchesUnavailableReason.deterministicExecution:
          'This execution followed one deterministic path.',
      ComputationBranchesUnavailableReason.unsupportedSource:
          'This simulation cannot provide branch data.',
    },
  });

  final String title;
  final String inspectorSemanticLabel;
  final String branchSelectorLabel;
  final String hierarchyTitle;
  final String detailsTitle;
  final String configurationLabel;
  final String transitionLabel;
  final String outcomeLabelPrefix;
  final String highlightBranch;
  final String selectConfiguration;
  final String noBranches;
  final String noConfigurations;
  final String unavailableTitle;
  final String branchPrefix;
  final String previousBranch;
  final String nextBranch;
  final String previousConfigurations;
  final String nextConfigurations;
  final String configurationPrefix;
  final Map<ComputationBranchOutcome, String> outcomeLabels;
  final Map<ComputationBranchesUnavailableReason, String> unavailableReasons;

  String branchName(int index, ComputationBranch branch) =>
      branch.summary?.isNotEmpty == true
      ? branch.summary!
      : '$branchPrefix ${index + 1}';

  String configurationName(int index) => '$configurationPrefix ${index + 1}';

  String branchPosition(int index, int total) =>
      '$branchPrefix $index of $total';

  String configurationRange(int start, int end, int total) =>
      'Configurations $start-$end of $total';

  String outcomeLabel(ComputationBranchOutcome outcome) =>
      outcomeLabels[outcome] ?? outcome.name;

  String unavailableReason(ComputationBranchesUnavailableReason reason) =>
      unavailableReasons[reason] ?? reason.name;

  String configurationDetailsSemanticLabel(
    String configuration,
    ComputationBranchOutcome? outcome,
  ) => outcome == null
      ? '$configurationLabel: $configuration'
      : '$configurationLabel: $configuration, '
            '$outcomeLabelPrefix: ${outcomeLabel(outcome)}';

  String branchOption(String branch, String outcome) => '$branch · $outcome';

  String branchAnnouncement(String position, String branch, String outcome) =>
      '$position. $branch. $outcome.';

  String outcomeSemanticLabel(String outcome) =>
      '$outcomeLabelPrefix: $outcome';

  String unavailableSemanticLabel(
    ComputationBranchesUnavailableReason reason,
  ) => '$unavailableTitle. ${unavailableReason(reason)}';
}
