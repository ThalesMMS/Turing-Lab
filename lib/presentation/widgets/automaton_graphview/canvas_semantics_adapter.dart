import 'package:collection/collection.dart';
import 'package:flutter/material.dart';

import '../../../features/canvas/graphview/base_graphview_canvas_controller.dart';
import '../../../features/canvas/graphview/graphview_canvas_models.dart';
import '../../../l10n/app_localizations.dart';

/// Builds accessibility descriptions from the current rendered snapshot.
class AutomatonGraphViewSemanticsAdapter {
  const AutomatonGraphViewSemanticsAdapter({
    required this.controller,
    required this.localizations,
    required this.selectedTransitionIds,
    this.nodeSemanticsDetails,
    this.edgeSemanticsDetails,
  });

  final BaseGraphViewCanvasController<dynamic, dynamic> controller;
  final AppLocalizations localizations;
  final Set<String> selectedTransitionIds;
  final String? Function(GraphViewCanvasNode node)? nodeSemanticsDetails;
  final String? Function(GraphViewCanvasEdge edge)? edgeSemanticsDetails;

  String viewportLabel() {
    return localizations.canvasViewportSemantics(
      localizations.canvasViewportStateCount(controller.nodes.length),
      localizations.canvasViewportTransitionCount(controller.edges.length),
    );
  }

  String nodeLabel(
    GraphViewCanvasNode node,
    Map<String, int> outgoingCounts,
    Map<String, int> incomingCounts,
  ) {
    final parts = <String>[
      localizations.canvasStateSemantics(
        node.label.isEmpty ? node.id : node.label,
      ),
      if (node.isInitial) localizations.canvasInitialStateSemantics,
      if (node.isAccepting) localizations.canvasAcceptingStateSemantics,
      if (nodeSemanticsDetails?.call(node) case final details?
          when details.trim().isNotEmpty)
        details,
      localizations.canvasOutgoingTransitionCount(outgoingCounts[node.id] ?? 0),
      localizations.canvasIncomingTransitionCount(incomingCounts[node.id] ?? 0),
    ];
    return parts.join(' ');
  }

  Widget transitionLayer() {
    final edges = controller.edges.sortedBy((edge) => edge.id);
    if (edges.isEmpty) {
      return const SizedBox.shrink();
    }
    return IgnorePointer(
      child: Opacity(
        opacity: 0,
        alwaysIncludeSemantics: true,
        child: Column(
          children: [
            for (final edge in edges)
              Semantics(
                label: _edgeLabel(edge),
                child: const SizedBox(width: 1, height: 1),
              ),
          ],
        ),
      ),
    );
  }

  String _edgeLabel(GraphViewCanvasEdge edge) {
    final fromLabel = controller.nodeById(edge.fromStateId)?.label;
    final toLabel = controller.nodeById(edge.toStateId)?.label;
    final from =
        (fromLabel?.isNotEmpty == true) ? fromLabel! : edge.fromStateId;
    final to = (toLabel?.isNotEmpty == true) ? toLabel! : edge.toStateId;
    final label = edge.label.isEmpty
        ? localizations.canvasUnlabeledTransition
        : edge.label;
    return <String>[
      localizations.canvasTransitionSemantics(edge.id, from, to, label),
      if (edgeSemanticsDetails?.call(edge) case final details?
          when details.trim().isNotEmpty)
        details,
      if (selectedTransitionIds.contains(edge.id))
        localizations.canvasSelectedTransitionSemantics,
    ].join(' ');
  }
}
