//
//  workspace_quick_actions_provider.dart
//  Turing Lab
//
//  Publishes contextual quick actions for the active workspace so the global
//  AppBar can render shortcuts in place of the old floating canvas menu.
//
//  Thales Matheus Mendonça Santos - August 2026
//

import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/formal_systems/formal_systems.dart';
import '../workspaces/workspace_quick_action.dart';

export '../workspaces/legacy_workspace_tab.dart';

/// Quick actions the active workspace exposes to the global app bar.
///
/// A null callback means the workspace does not support that action and its
/// button is hidden. A provided callback with its `enabled` flag false is
/// rendered as a disabled button (e.g. no machine loaded yet), keeping the
/// toolbar discoverable on empty canvases.
@immutable
class WorkspaceQuickActions {
  const WorkspaceQuickActions({
    this.onHelp,
    this.onSimulate,
    this.onAlgorithms,
    this.onEdit,
    this.onMetrics,
    this.onProgress,
    this.onExamples,
    this.simulateTooltip,
    this.algorithmsTooltip,
    this.editTooltip,
    this.examplesTooltip,
    this.simulateEnabled = true,
    this.algorithmsEnabled = true,
    this.editEnabled = true,
    this.metricsEnabled = true,
    this.progressEnabled = true,
    this.progressFocusNode,
    this.examplesEnabled = true,
    this.examplesIcon,
  });

  final VoidCallback? onHelp;
  final VoidCallback? onSimulate;
  final VoidCallback? onAlgorithms;
  final VoidCallback? onEdit;
  final VoidCallback? onMetrics;
  final VoidCallback? onProgress;
  final VoidCallback? onExamples;
  final String? simulateTooltip;
  final String? algorithmsTooltip;
  final String? editTooltip;
  final String? examplesTooltip;
  final bool simulateEnabled;
  final bool algorithmsEnabled;
  final bool editEnabled;
  final bool metricsEnabled;
  final bool progressEnabled;
  final FocusNode? progressFocusNode;
  final bool examplesEnabled;

  /// Overrides the default examples icon (`Icons.school_outlined`) so a
  /// workspace whose examples are its combined Algorithms & Examples surface
  /// can present the shared `Icons.auto_awesome` identity.
  final IconData? examplesIcon;

  WorkspaceQuickActions constrainedTo({
    required FormalSystemCapabilities capabilities,
    required Set<WorkspaceQuickAction> supportedActions,
  }) {
    bool supports(
      WorkspaceQuickAction action,
      FormalSystemCapability capability,
    ) => supportedActions.contains(action) && capabilities.supports(capability);

    return WorkspaceQuickActions(
      onHelp: supports(WorkspaceQuickAction.help, FormalSystemCapability.help)
          ? onHelp
          : null,
      onSimulate:
          supports(
            WorkspaceQuickAction.simulate,
            FormalSystemCapability.simulation,
          )
          ? onSimulate
          : null,
      onAlgorithms:
          supports(
            WorkspaceQuickAction.algorithms,
            FormalSystemCapability.analysis,
          )
          ? onAlgorithms
          : null,
      onEdit:
          supports(WorkspaceQuickAction.edit, FormalSystemCapability.editing)
          ? onEdit
          : null,
      onMetrics:
          supports(WorkspaceQuickAction.metrics, FormalSystemCapability.trace)
          ? onMetrics
          : null,
      onProgress:
          supports(
            WorkspaceQuickAction.progress,
            FormalSystemCapability.analysis,
          )
          ? onProgress
          : null,
      onExamples:
          supports(
            WorkspaceQuickAction.examples,
            FormalSystemCapability.examples,
          )
          ? onExamples
          : null,
      simulateTooltip: simulateTooltip,
      algorithmsTooltip: algorithmsTooltip,
      editTooltip: editTooltip,
      examplesTooltip: examplesTooltip,
      simulateEnabled: simulateEnabled,
      algorithmsEnabled: algorithmsEnabled,
      editEnabled: editEnabled,
      metricsEnabled: metricsEnabled,
      progressEnabled: progressEnabled,
      progressFocusNode: progressFocusNode,
      examplesEnabled: examplesEnabled,
      examplesIcon: examplesIcon,
    );
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        other is WorkspaceQuickActions &&
            other.onHelp == onHelp &&
            other.onSimulate == onSimulate &&
            other.onAlgorithms == onAlgorithms &&
            other.onEdit == onEdit &&
            other.onMetrics == onMetrics &&
            other.onProgress == onProgress &&
            other.onExamples == onExamples &&
            other.simulateTooltip == simulateTooltip &&
            other.algorithmsTooltip == algorithmsTooltip &&
            other.editTooltip == editTooltip &&
            other.examplesTooltip == examplesTooltip &&
            other.simulateEnabled == simulateEnabled &&
            other.algorithmsEnabled == algorithmsEnabled &&
            other.editEnabled == editEnabled &&
            other.metricsEnabled == metricsEnabled &&
            other.progressEnabled == progressEnabled &&
            other.progressFocusNode == progressFocusNode &&
            other.examplesEnabled == examplesEnabled &&
            other.examplesIcon == examplesIcon;
  }

  @override
  int get hashCode => Object.hash(
    onHelp,
    onSimulate,
    onAlgorithms,
    onEdit,
    onMetrics,
    onProgress,
    onExamples,
    simulateTooltip,
    algorithmsTooltip,
    editTooltip,
    examplesTooltip,
    simulateEnabled,
    algorithmsEnabled,
    editEnabled,
    metricsEnabled,
    progressEnabled,
    progressFocusNode,
    examplesEnabled,
    examplesIcon,
  );
}

/// Latest quick actions published by each workspace tab.
final workspaceQuickActionsProvider =
    StateProvider.family<WorkspaceQuickActions?, FormalSystemKey>(
      (ref, key) => null,
    );

void publishWorkspaceQuickActionsForKey(
  WidgetRef ref,
  FormalSystemKey key,
  WorkspaceQuickActions actions,
) {
  final controller = ref.read(workspaceQuickActionsProvider(key).notifier);
  if (controller.state == actions) {
    return;
  }
  WidgetsBinding.instance.addPostFrameCallback((_) {
    if (controller.state == actions) {
      return;
    }
    controller.state = actions;
  });
}
