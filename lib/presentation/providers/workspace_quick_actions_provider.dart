//
//  workspace_quick_actions_provider.dart
//  Turing Lab
//
//  Publica as ações rápidas (ajuda contextual, simulação, algoritmos e
//  métricas) do workspace ativo para que a AppBar global renderize os
//  atalhos no lugar do antigo menu flutuante sobre o canvas.
//
//  Thales Matheus Mendonça Santos - August 2026
//

import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Workspace tabs hosted by the home page, in navigation order.
enum WorkspaceTab { fsa, grammar, pda, tm, regex, pumping }

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
    this.onMetrics,
    this.simulateEnabled = true,
    this.algorithmsEnabled = true,
    this.metricsEnabled = true,
  });

  final VoidCallback? onHelp;
  final VoidCallback? onSimulate;
  final VoidCallback? onAlgorithms;
  final VoidCallback? onMetrics;
  final bool simulateEnabled;
  final bool algorithmsEnabled;
  final bool metricsEnabled;

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        other is WorkspaceQuickActions &&
            other.onHelp == onHelp &&
            other.onSimulate == onSimulate &&
            other.onAlgorithms == onAlgorithms &&
            other.onMetrics == onMetrics &&
            other.simulateEnabled == simulateEnabled &&
            other.algorithmsEnabled == algorithmsEnabled &&
            other.metricsEnabled == metricsEnabled;
  }

  @override
  int get hashCode => Object.hash(
        onHelp,
        onSimulate,
        onAlgorithms,
        onMetrics,
        simulateEnabled,
        algorithmsEnabled,
        metricsEnabled,
      );
}

/// Latest quick actions published by each workspace tab.
final workspaceQuickActionsProvider =
    StateProvider.family<WorkspaceQuickActions?, WorkspaceTab>(
  (ref, tab) => null,
);

/// Publishes [actions] for [tab] after the current frame, skipping no-op
/// updates. Safe to call from build methods.
void publishWorkspaceQuickActions(
  WidgetRef ref,
  WorkspaceTab tab,
  WorkspaceQuickActions actions,
) {
  final controller = ref.read(workspaceQuickActionsProvider(tab).notifier);
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
