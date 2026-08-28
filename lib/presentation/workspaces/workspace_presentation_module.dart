import 'package:flutter/material.dart';

import '../../core/formal_systems/formal_systems.dart';
import '../../l10n/app_localizations.dart';
import 'workspace_quick_action.dart';

typedef WorkspaceTextResolver = String Function(AppLocalizations l10n);

@immutable
class WorkspacePresentationModule {
  WorkspacePresentationModule({
    required this.descriptor,
    required this.icon,
    required this.pageBuilder,
    required this.helpTopicId,
    required this.navigationLabel,
    required this.navigationDescription,
    required Iterable<WorkspaceQuickAction> quickActions,
    this.usesCanvasHighlight = false,
  }) : quickActions = Set<WorkspaceQuickAction>.unmodifiable(quickActions);

  final FormalSystemDescriptor descriptor;
  final IconData icon;
  final WidgetBuilder pageBuilder;
  final String helpTopicId;
  final WorkspaceTextResolver navigationLabel;
  final WorkspaceTextResolver navigationDescription;
  final Set<WorkspaceQuickAction> quickActions;
  final bool usesCanvasHighlight;

  FormalSystemKey get key => descriptor.key;
  WorkspaceRouteId get route => descriptor.route;
}
