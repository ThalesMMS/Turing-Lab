//
//  graphview_canvas_toolbar.dart
//  Turing Lab
//
//  Define a barra de ferramentas que controla o canvas de automatos em GraphView,
//  disponibilizando comandos de viewport, botões de desfazer/refazer e atalhos
//  para criação de estados e transições em workspaces amplos.
//  Observa o controlador do canvas para refletir o estado atual das ações,
//  permitindo seleção de ferramentas mutuamente exclusivas e ganchos de limpeza,
//  mensagens de status e fluxos personalizados.
//
//  Thales Matheus Mendonça Santos - October 2025
//
import 'package:flutter/material.dart';

import '../../core/constants/help_content.dart';
import '../../features/canvas/graphview/base_graphview_canvas_controller.dart';
import '../../l10n/app_localizations.dart';
import '../../l10n/app_localizations_resolver.dart';
import 'automaton_canvas_tool.dart';
import 'contextual_help_tooltip.dart';
import 'keyboard_shortcuts_dialog.dart';

part 'graphview_canvas_toolbar_group.dart';
part 'graphview_canvas_toolbar_group_config.dart';

/// Toolbar exposing viewport commands for the GraphView canvas.
class GraphViewCanvasToolbar extends StatefulWidget {
  const GraphViewCanvasToolbar({
    super.key,
    required this.controller,
    this.enableToolSelection = false,
    this.showSelectionTool = false,
    this.activeTool = AutomatonCanvasTool.selection,
    this.onSelectTool,
    required this.onAddState,
    this.onAddTransition,
    this.onHelp,
    this.onClear,
    this.statusMessage,
  })  : assert(
          !(enableToolSelection && showSelectionTool) || onSelectTool != null,
          'onSelectTool must be provided when the selection tool is visible.',
        ),
        assert(
          !enableToolSelection || onAddTransition != null,
          'onAddTransition must be provided when tool selection is enabled.',
        );

  final BaseGraphViewCanvasController<dynamic, dynamic> controller;
  final bool enableToolSelection;
  final bool showSelectionTool;
  final AutomatonCanvasTool activeTool;
  final VoidCallback? onSelectTool;
  final VoidCallback onAddState;
  final VoidCallback? onAddTransition;
  final VoidCallback? onHelp;
  final VoidCallback? onClear;
  final String? statusMessage;

  @override
  State<GraphViewCanvasToolbar> createState() => _GraphViewCanvasToolbarState();
}

class _GraphViewCanvasToolbarState extends State<GraphViewCanvasToolbar> {
  @override
  void initState() {
    super.initState();
    widget.controller.graphRevision.addListener(_handleControllerChanged);
  }

  @override
  void didUpdateWidget(covariant GraphViewCanvasToolbar oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.controller != widget.controller) {
      oldWidget.controller.graphRevision.removeListener(
        _handleControllerChanged,
      );
      widget.controller.graphRevision.addListener(_handleControllerChanged);
    }
  }

  @override
  void dispose() {
    widget.controller.graphRevision.removeListener(_handleControllerChanged);
    super.dispose();
  }

  void _handleControllerChanged() {
    if (!mounted) {
      return;
    }
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final controller = widget.controller;
    final actionGroups = <_ToolbarGroupConfig>[
      _ToolbarGroupConfig(
        id: _ToolbarGroup.editing,
        actions: [
          if (widget.enableToolSelection && widget.showSelectionTool)
            _ToolbarButtonConfig(
              action: _ToolbarAction.selection,
              handler: widget.onSelectTool,
              isToggle: true,
              isSelected: widget.activeTool == AutomatonCanvasTool.selection,
            ),
          _ToolbarButtonConfig(
            action: _ToolbarAction.addState,
            handler: widget.onAddState,
            isToggle: widget.enableToolSelection,
            isSelected: widget.enableToolSelection &&
                widget.activeTool == AutomatonCanvasTool.addState,
          ),
          if (widget.onAddTransition != null)
            _ToolbarButtonConfig(
              action: _ToolbarAction.transition,
              handler: widget.onAddTransition,
              isToggle: widget.enableToolSelection,
              isSelected: widget.enableToolSelection &&
                  widget.activeTool == AutomatonCanvasTool.transition,
            ),
        ],
      ),
      _ToolbarGroupConfig(
        id: _ToolbarGroup.history,
        actions: [
          _ToolbarButtonConfig(
            action: _ToolbarAction.undo,
            handler: controller.canUndo ? () => controller.undo() : null,
          ),
          _ToolbarButtonConfig(
            action: _ToolbarAction.redo,
            handler: controller.canRedo ? () => controller.redo() : null,
          ),
        ],
      ),
      _ToolbarGroupConfig(
        id: _ToolbarGroup.viewport,
        actions: [
          _ToolbarButtonConfig(
            action: _ToolbarAction.zoomOut,
            handler: controller.zoomOut,
          ),
          _ToolbarButtonConfig(
            action: _ToolbarAction.zoomIn,
            handler: controller.zoomIn,
          ),
          _ToolbarButtonConfig(
            action: _ToolbarAction.fitContent,
            handler: controller.fitToContent,
          ),
          _ToolbarButtonConfig(
            action: _ToolbarAction.resetView,
            handler: controller.resetView,
          ),
        ],
      ),
      if (widget.onClear != null)
        _ToolbarGroupConfig(
          id: _ToolbarGroup.destructive,
          actions: [
            _ToolbarButtonConfig(
              action: _ToolbarAction.clear,
              handler: widget.onClear!,
            ),
          ],
        ),
      _ToolbarGroupConfig(
        id: _ToolbarGroup.help,
        actions: [
          _ToolbarButtonConfig(
            action: _ToolbarAction.help,
            handler: widget.onHelp ??
                () {
                  KeyboardShortcutsDialog.show(context);
                },
          ),
        ],
      ),
    ];

    return _DesktopToolbar(
      actionGroups: actionGroups,
      statusMessage: widget.statusMessage,
      theme: theme,
    );
  }
}

class _DesktopToolbar extends StatelessWidget {
  const _DesktopToolbar({
    required this.actionGroups,
    required this.statusMessage,
    required this.theme,
  });

  final List<_ToolbarGroupConfig> actionGroups;
  final String? statusMessage;
  final ThemeData theme;

  @override
  Widget build(BuildContext context) {
    final colorScheme = theme.colorScheme;
    final textTheme = theme.textTheme;
    final l10n = appLocalizationsOf(context);

    return Align(
      alignment: Alignment.topRight,
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: FocusTraversalGroup(
          policy: OrderedTraversalPolicy(),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                decoration: BoxDecoration(
                  color: colorScheme.surface,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.08),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      for (final indexedGroupEntry
                          in actionGroups.asMap().entries) ...[
                        for (final indexedEntry in indexedGroupEntry
                            .value.actions
                            .asMap()
                            .entries) ...[
                          _buildActionButton(
                            entry: indexedEntry.value,
                            groupId: indexedGroupEntry.value.id,
                            groupIndex: indexedGroupEntry.key,
                            actionIndex: indexedEntry.key,
                            colorScheme: colorScheme,
                            l10n: l10n,
                          ),
                          if (indexedEntry.key <
                              indexedGroupEntry.value.actions.length - 1)
                            Container(
                              width: 1,
                              height: 24,
                              margin: const EdgeInsets.symmetric(horizontal: 4),
                              color: colorScheme.outlineVariant.withValues(
                                alpha: 0.35,
                              ),
                            ),
                        ],
                        if (indexedGroupEntry.key < actionGroups.length - 1)
                          Container(
                            width: 1,
                            height: 28,
                            margin: const EdgeInsets.symmetric(horizontal: 8),
                            color: colorScheme.outlineVariant.withValues(
                              alpha: 0.55,
                            ),
                          ),
                      ],
                    ],
                  ),
                ),
              ),
              if (statusMessage != null && statusMessage!.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Text(statusMessage!, style: textTheme.bodySmall),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

Widget _buildActionButton({
  required _ToolbarButtonConfig entry,
  required _ToolbarGroup groupId,
  required int groupIndex,
  required int actionIndex,
  required ColorScheme colorScheme,
  required AppLocalizations l10n,
}) {
  final helpContent = kHelpContent[entry.action.helpContentId];
  final traversalIndex = (groupIndex * 100 + actionIndex).toDouble();
  final isDestructive = groupId == _ToolbarGroup.destructive;
  final actionLabel = entry.action.label(l10n);
  final button = FocusTraversalOrder(
    order: NumericFocusOrder(traversalIndex),
    child: Semantics(
      label: l10n.canvasActionSemantics(actionLabel),
      hint: entry.action.semanticsHint(l10n),
      button: true,
      enabled: entry.handler != null,
      selected: entry.isToggle && entry.isSelected,
      excludeSemantics: true,
      child: IconButton(
        tooltip: helpContent == null ? actionLabel : null,
        icon: Icon(entry.action.icon),
        onPressed: entry.handler,
        style: _desktopActionButtonStyle(
          entry: entry,
          isDestructive: isDestructive,
          colorScheme: colorScheme,
        ),
      ),
    ),
  );

  return helpContent != null
      ? ContextualHelpTooltip(
          helpContent: helpContent,
          child: button,
        )
      : button;
}

ButtonStyle _desktopActionButtonStyle({
  required _ToolbarButtonConfig entry,
  required bool isDestructive,
  required ColorScheme colorScheme,
}) {
  final isToggle = entry.isToggle;
  final isSelected = entry.isSelected;

  return IconButton.styleFrom(
    minimumSize: const Size(44, 44),
    backgroundColor: isDestructive
        ? colorScheme.errorContainer
        : isToggle
            ? (isSelected
                ? colorScheme.primaryContainer
                : colorScheme.surfaceContainerHighest.withValues(alpha: 0.18))
            : null,
    foregroundColor: isDestructive
        ? colorScheme.onErrorContainer
        : isToggle
            ? (isSelected
                ? colorScheme.onPrimaryContainer
                : colorScheme.onSurfaceVariant)
            : null,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(10),
      side: isDestructive
          ? BorderSide(
              color: colorScheme.error.withValues(alpha: 0.55),
            )
          : isToggle && !isSelected
              ? BorderSide(
                  color: colorScheme.outlineVariant.withValues(alpha: 0.55),
                )
              : BorderSide.none,
    ),
  );
}

class _ToolbarButtonConfig {
  _ToolbarButtonConfig({
    required this.action,
    required this.handler,
    this.isToggle = false,
    this.isSelected = false,
  });

  final _ToolbarAction action;
  final VoidCallback? handler;
  final bool isToggle;
  final bool isSelected;
}

enum _ToolbarAction {
  selection(
    icon: Icons.pan_tool,
    helpContentId: 'tool_select',
  ),
  addState(
    icon: Icons.add,
    helpContentId: 'tool_add_state',
  ),
  transition(
    icon: Icons.arrow_right_alt,
    helpContentId: 'tool_add_transition',
  ),
  undo(
    icon: Icons.undo,
    helpContentId: 'tool_undo',
  ),
  redo(
    icon: Icons.redo,
    helpContentId: 'tool_redo',
  ),
  zoomOut(
    icon: Icons.zoom_out,
    helpContentId: 'tool_zoom_out',
  ),
  zoomIn(
    icon: Icons.zoom_in,
    helpContentId: 'tool_zoom_in',
  ),
  fitContent(
    icon: Icons.fit_screen,
    helpContentId: 'tool_fit_content',
  ),
  resetView(
    icon: Icons.center_focus_strong,
    helpContentId: 'tool_reset_view',
  ),
  clear(
    icon: Icons.delete_outline,
    helpContentId: 'tool_clear',
  ),
  help(
    icon: Icons.help_outline,
    helpContentId: 'shortcut_canvas_general',
  );

  const _ToolbarAction({required this.icon, required this.helpContentId});

  final IconData icon;
  final String helpContentId;

  String label(AppLocalizations l10n) => switch (this) {
        selection => l10n.canvasSelectAction,
        addState => l10n.canvasAddStateAction,
        transition => l10n.canvasAddTransitionAction,
        undo => l10n.canvasUndoAction,
        redo => l10n.canvasRedoAction,
        zoomOut => l10n.canvasZoomOutAction,
        zoomIn => l10n.canvasZoomInAction,
        fitContent => l10n.canvasFitToContentAction,
        resetView => l10n.canvasResetViewAction,
        clear => l10n.canvasClearAction,
        help => l10n.canvasHelpShortcutsAction,
      };

  String semanticsHint(AppLocalizations l10n) => switch (this) {
        selection => l10n.canvasSelectHint,
        addState => l10n.canvasAddStateHint,
        transition => l10n.canvasAddTransitionHint,
        undo => l10n.canvasUndoHint,
        redo => l10n.canvasRedoHint,
        zoomOut => l10n.canvasZoomOutHint,
        zoomIn => l10n.canvasZoomInHint,
        fitContent => l10n.canvasFitToContentHint,
        resetView => l10n.canvasResetViewHint,
        clear => l10n.canvasClearHint,
        help => l10n.canvasHelpShortcutsHint,
      };
}
