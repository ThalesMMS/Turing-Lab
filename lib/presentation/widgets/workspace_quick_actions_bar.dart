//
//  workspace_quick_actions_bar.dart
//  Turing Lab
//
//  Fileira de atalhos do workspace ativo (simulação, algoritmos e métricas)
//  renderizada no canto esquerdo da AppBar global, substituindo o antigo
//  menu flutuante sobre o canvas.
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
    final buttons = <Widget>[
      if (actions?.onSimulate case final onSimulate?)
        IconButton(
          tooltip: l10n.workspaceSimulateTooltip,
          icon: const Icon(Icons.play_arrow),
          onPressed: actions!.simulateEnabled ? onSimulate : null,
        ),
      if (actions?.onAlgorithms case final onAlgorithms?)
        IconButton(
          tooltip: l10n.workspaceAlgorithmsTooltip,
          icon: const Icon(Icons.auto_awesome),
          onPressed: actions!.algorithmsEnabled ? onAlgorithms : null,
        ),
      if (actions?.onMetrics case final onMetrics?)
        IconButton(
          tooltip: l10n.workspaceMetricsTooltip,
          icon: const Icon(Icons.bar_chart),
          onPressed: actions!.metricsEnabled ? onMetrics : null,
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
