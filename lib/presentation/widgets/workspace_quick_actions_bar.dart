//
//  workspace_quick_actions_bar.dart
//  Turing Lab
//
//  Shortcut row for the active workspace, rendered on the left of the global
//  AppBar in place of the old floating canvas menu.
//
//  Thales Matheus Mendonça Santos - August 2026
//

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/formal_systems/formal_systems.dart';
import '../../l10n/app_localizations_help.dart';
import '../providers/workspace_quick_actions_provider.dart';
import '../providers/workspace_registry_provider.dart';
import '../workspaces/workspace_quick_action.dart';

class WorkspaceQuickActionsBar extends ConsumerWidget {
  const WorkspaceQuickActionsBar({
    super.key,
    this.tab,
    this.workspaceKey,
    this.collapseMultiple = false,
    this.visibleActions,
  }) : assert((tab == null) != (workspaceKey == null));

  final WorkspaceTab? tab;
  final FormalSystemKey? workspaceKey;
  final bool collapseMultiple;
  final Set<WorkspaceQuickAction>? visibleActions;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final key = workspaceKey ?? tab!.formalSystemKey;
    final module = ref
        .watch(workspacePresentationRegistryProvider)
        .moduleFor(key);
    final publishedActions = ref.watch(workspaceQuickActionsProvider(key));
    final actions = module == null || publishedActions == null
        ? null
        : publishedActions.constrainedTo(
            capabilities: module.descriptor.capabilities,
            supportedActions: visibleActions == null
                ? module.quickActions
                : module.quickActions.intersection(visibleActions!),
          );
    final l10n = jflapLocalizationsOf(context);
    if (actions == null) {
      return const SizedBox.shrink();
    }

    final simulation = actions.onSimulate == null
        ? null
        : _QuickAction(
            label: actions.simulateTooltip ?? l10n.workspaceSimulateTooltip,
            icon: Icons.play_arrow,
            onPressed: actions.simulateEnabled ? actions.onSimulate : null,
          );
    final algorithms = actions.onAlgorithms == null
        ? null
        : _QuickAction(
            label: actions.algorithmsTooltip ?? l10n.workspaceAlgorithmsTooltip,
            icon: Icons.auto_awesome,
            onPressed: actions.algorithmsEnabled ? actions.onAlgorithms : null,
          );
    final actionConfigs = <_QuickAction>[
      if (simulation != null) simulation,
      if (algorithms != null) algorithms,
      if (actions.onEdit != null)
        _QuickAction(
          label: actions.editTooltip ?? l10n.workspaceEditTooltip,
          icon: Icons.edit,
          onPressed: actions.editEnabled ? actions.onEdit : null,
        ),
      if (actions.onMetrics != null)
        _QuickAction(
          label: l10n.workspaceMetricsTooltip,
          icon: Icons.bar_chart,
          onPressed: actions.metricsEnabled ? actions.onMetrics : null,
        ),
      if (actions.onProgress != null)
        _QuickAction(
          key: const ValueKey('workspace-quick-action-progress'),
          label: l10n.progressTitle,
          icon: Icons.bar_chart,
          onPressed: actions.progressEnabled ? actions.onProgress : null,
          focusNode: actions.progressFocusNode,
        ),
      if (actions.onExamples != null)
        _QuickAction(
          key: const ValueKey('workspace-quick-action-examples'),
          label: actions.examplesTooltip ?? l10n.workspaceExamplesTooltip,
          icon: actions.examplesIcon ?? Icons.school_outlined,
          onPressed: actions.examplesEnabled ? actions.onExamples : null,
          explicitSemantics: true,
        ),
    ];
    if (actionConfigs.isEmpty) {
      return const SizedBox.shrink();
    }
    final buttons = collapseMultiple && actionConfigs.length > 1
        ? <Widget>[
            PopupMenuButton<int>(
              key: const ValueKey('workspace-quick-actions-overflow'),
              tooltip: l10n.workspaceMoreActionsTooltip,
              position: PopupMenuPosition.under,
              onSelected: (index) => actionConfigs[index].onPressed?.call(),
              itemBuilder: (context) => [
                for (final entry in actionConfigs.asMap().entries)
                  PopupMenuItem<int>(
                    value: entry.key,
                    enabled: entry.value.onPressed != null,
                    height: 48,
                    child: Row(
                      children: [
                        Icon(entry.value.icon),
                        const SizedBox(width: 12),
                        Flexible(child: Text(entry.value.label)),
                      ],
                    ),
                  ),
              ],
              child: const SizedBox.square(
                dimension: 48,
                child: Icon(Icons.more_horiz),
              ),
            ),
          ]
        : [for (final action in actionConfigs) _QuickActionButton(action)];
    return Align(
      alignment: Alignment.centerLeft,
      child: Row(mainAxisSize: MainAxisSize.min, children: buttons),
    );
  }
}

class _QuickAction {
  const _QuickAction({
    this.key,
    required this.label,
    required this.icon,
    required this.onPressed,
    this.focusNode,
    this.explicitSemantics = false,
  });

  final Key? key;
  final String label;
  final IconData icon;
  final VoidCallback? onPressed;
  final FocusNode? focusNode;
  final bool explicitSemantics;
}

class _QuickActionButton extends StatelessWidget {
  const _QuickActionButton(this.action);

  final _QuickAction action;

  @override
  Widget build(BuildContext context) {
    final button = IconButton(
      focusNode: action.focusNode,
      tooltip: !action.explicitSemantics ? action.label : null,
      icon: Icon(action.icon),
      onPressed: action.onPressed,
    );
    if (!action.explicitSemantics) {
      return KeyedSubtree(key: action.key, child: button);
    }
    return Semantics(
      key: action.key,
      label: action.label,
      button: true,
      enabled: action.onPressed != null,
      onTap: action.onPressed,
      excludeSemantics: true,
      child: Tooltip(message: action.label, child: button),
    );
  }
}
