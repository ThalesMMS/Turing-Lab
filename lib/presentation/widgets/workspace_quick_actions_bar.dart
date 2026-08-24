//
//  workspace_quick_actions_bar.dart
//  Turing Lab
//
//  Shortcut row for the active workspace (simulation, algorithms, and
//  metrics) rendered on the left of the global AppBar, replacing the old
//  floating menu over the canvas.
//
//  Thales Matheus Mendonça Santos - August 2026
//

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../l10n/app_localizations_help.dart';
import '../providers/workspace_quick_actions_provider.dart';

class WorkspaceQuickActionsBar extends ConsumerWidget {
  const WorkspaceQuickActionsBar({super.key, required this.tab});

  final WorkspaceTab tab;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final actions = ref.watch(workspaceQuickActionsProvider(tab));
    final l10n = jflapLocalizationsOf(context);
    if (actions == null) {
      return const SizedBox.shrink();
    }

    final simulationButton = actions.onSimulate == null
        ? null
        : IconButton(
            tooltip: actions.simulateTooltip ?? l10n.workspaceSimulateTooltip,
            icon: const Icon(Icons.play_arrow),
            onPressed: actions.simulateEnabled ? actions.onSimulate : null,
          );
    final algorithmButton = actions.onAlgorithms == null
        ? null
        : IconButton(
            tooltip: l10n.workspaceAlgorithmsTooltip,
            icon: const Icon(Icons.auto_awesome),
            onPressed: actions.algorithmsEnabled ? actions.onAlgorithms : null,
          );
    final buttons = <Widget>[
      if (actions.algorithmsBeforeSimulation && algorithmButton != null)
        algorithmButton,
      if (simulationButton != null) simulationButton,
      if (!actions.algorithmsBeforeSimulation && algorithmButton != null)
        algorithmButton,
      if (actions.onEdit case final onEdit?)
        IconButton(
          tooltip: actions.editTooltip ?? l10n.workspaceEditTooltip,
          icon: const Icon(Icons.edit),
          onPressed: actions.editEnabled ? onEdit : null,
        ),
      if (actions.onMetrics case final onMetrics?)
        IconButton(
          tooltip: l10n.workspaceMetricsTooltip,
          icon: const Icon(Icons.bar_chart),
          onPressed: actions.metricsEnabled ? onMetrics : null,
        ),
    ];
    if (buttons.isEmpty) {
      return const SizedBox.shrink();
    }
    return Align(
      alignment: Alignment.centerLeft,
      child: Row(mainAxisSize: MainAxisSize.min, children: buttons),
    );
  }
}
