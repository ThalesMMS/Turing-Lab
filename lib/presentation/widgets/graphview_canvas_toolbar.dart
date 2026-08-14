//
//  graphview_canvas_toolbar.dart
//  Turing Lab
//
//  Define a barra de ferramentas que controla o canvas de automatos em GraphView,
//  disponibilizando comandos de viewport, botões de desfazer/refazer e atalhos
//  para criação de estados e transições em modos desktop ou mobile.
//  Observa o controlador do canvas para refletir o estado atual das ações,
//  permitindo seleção de ferramentas mutuamente exclusivas e ganchos de limpeza,
//  mensagens de status e fluxos personalizados.
//
//  Thales Matheus Mendonça Santos - October 2025
//
import 'package:flutter/material.dart';

import '../../core/constants/help_content.dart';
import '../../features/canvas/graphview/base_graphview_canvas_controller.dart';
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
    this.onClear,
    this.statusMessage,
    this.layout = GraphViewCanvasToolbarLayout.desktop,
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
  final VoidCallback? onClear;
  final String? statusMessage;
  final GraphViewCanvasToolbarLayout layout;

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
            handler: () => KeyboardShortcutsDialog.show(context),
          ),
        ],
      ),
    ];

    switch (widget.layout) {
      case GraphViewCanvasToolbarLayout.mobile:
        return _MobileToolbar(
          actionGroups: actionGroups,
          statusMessage: widget.statusMessage,
          theme: theme,
        );
      case GraphViewCanvasToolbarLayout.desktop:
        return _DesktopToolbar(
          actionGroups: actionGroups,
          statusMessage: widget.statusMessage,
          theme: theme,
        );
    }
  }
}

enum GraphViewCanvasToolbarLayout { desktop, mobile }

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
                            isMobile: false,
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

class _MobileToolbar extends StatelessWidget {
  const _MobileToolbar({
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

    return Align(
      alignment: Alignment.bottomCenter,
      child: ConstrainedBox(
        constraints: const BoxConstraints(
          maxHeight: 400,
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: FocusTraversalGroup(
            policy: OrderedTraversalPolicy(),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (statusMessage != null && statusMessage!.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: Text(statusMessage!, style: textTheme.bodyMedium),
                  ),
                Flexible(
                  child: Material(
                    elevation: 6,
                    borderRadius: BorderRadius.circular(16),
                    color: colorScheme.surface,
                    child: Scrollbar(
                      child: SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        padding: const EdgeInsets.all(12),
                        child: IntrinsicWidth(
                          child: Wrap(
                            spacing: 12,
                            runSpacing: 12,
                            alignment: WrapAlignment.center,
                            children: [
                              for (final indexedGroupEntry
                                  in actionGroups.asMap().entries) ...[
                                for (final indexedEntry in indexedGroupEntry
                                    .value.actions
                                    .asMap()
                                    .entries)
                                  _buildActionButton(
                                    entry: indexedEntry.value,
                                    groupId: indexedGroupEntry.value.id,
                                    groupIndex: indexedGroupEntry.key,
                                    actionIndex: indexedEntry.key,
                                    colorScheme: colorScheme,
                                    isMobile: true,
                                  ),
                                if (indexedGroupEntry.key <
                                    actionGroups.length - 1)
                                  const SizedBox(width: 24),
                              ],
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
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
  required bool isMobile,
}) {
  final helpContent = kHelpContent[entry.action.helpContentId];
  final traversalIndex = (groupIndex * 100 + actionIndex).toDouble();
  final isDestructive = groupId == _ToolbarGroup.destructive;
  final button = FocusTraversalOrder(
    order: NumericFocusOrder(traversalIndex),
    child: Semantics(
      label: 'Canvas action: ${entry.action.label}',
      hint: entry.action.semanticsHint,
      button: true,
      enabled: entry.handler != null,
      selected: entry.isToggle && entry.isSelected,
      excludeSemantics: true,
      child: isMobile
          ? FilledButton.icon(
              onPressed: entry.handler,
              style: _mobileActionButtonStyle(
                entry: entry,
                isDestructive: isDestructive,
                colorScheme: colorScheme,
              ),
              icon: Icon(entry.action.icon),
              label: Text(entry.action.label),
            )
          : IconButton(
              tooltip: helpContent == null ? entry.action.label : null,
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

ButtonStyle _mobileActionButtonStyle({
  required _ToolbarButtonConfig entry,
  required bool isDestructive,
  required ColorScheme colorScheme,
}) {
  return FilledButton.styleFrom(
    minimumSize: const Size(44, 44),
    padding: const EdgeInsets.symmetric(
      horizontal: 16,
      vertical: 12,
    ),
    backgroundColor: isDestructive
        ? colorScheme.errorContainer
        : entry.isToggle && entry.isSelected
            ? colorScheme.primary
            : entry.isToggle
                ? colorScheme.surfaceContainerHighest
                : colorScheme.surfaceContainerHighest.withValues(alpha: 0.18),
    foregroundColor: isDestructive
        ? colorScheme.onErrorContainer
        : entry.isToggle && entry.isSelected
            ? colorScheme.onPrimary
            : colorScheme.onSurfaceVariant,
    elevation: isDestructive
        ? 0
        : entry.isToggle
            ? 1
            : 0,
    side: isDestructive
        ? BorderSide(
            color: colorScheme.error.withValues(alpha: 0.55),
          )
        : entry.isToggle && !entry.isSelected
            ? BorderSide(
                color: colorScheme.outlineVariant.withValues(alpha: 0.55),
              )
            : null,
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
      label: 'Select',
      helpContentId: 'tool_select',
      semanticsHint: 'Activates selection mode for moving and editing states.'),
  addState(
      icon: Icons.add,
      label: 'Add state',
      helpContentId: 'tool_add_state',
      semanticsHint: 'Adds a new state to the automaton canvas.'),
  transition(
      icon: Icons.arrow_right_alt,
      label: 'Add transition',
      helpContentId: 'tool_add_transition',
      semanticsHint: 'Activates transition mode to connect two states.'),
  undo(
      icon: Icons.undo,
      label: 'Undo',
      helpContentId: 'tool_undo',
      semanticsHint: 'Reverts the most recent canvas change.'),
  redo(
      icon: Icons.redo,
      label: 'Redo',
      helpContentId: 'tool_redo',
      semanticsHint: 'Restores the most recently undone canvas change.'),
  fitContent(
      icon: Icons.fit_screen,
      label: 'Fit to content',
      helpContentId: 'tool_fit_content',
      semanticsHint: 'Zooms and pans to show the full automaton.'),
  resetView(
      icon: Icons.center_focus_strong,
      label: 'Reset view',
      helpContentId: 'tool_reset_view',
      semanticsHint: 'Resets the canvas zoom and pan position.'),
  clear(
      icon: Icons.delete_outline,
      label: 'Clear canvas',
      helpContentId: 'tool_clear',
      semanticsHint: 'Removes all states and transitions from the canvas.'),
  help(
      icon: Icons.help_outline,
      label: 'Help & Shortcuts',
      helpContentId: 'shortcut_canvas_general',
      semanticsHint: 'Opens canvas help and keyboard shortcut information.');

  const _ToolbarAction(
      {required this.icon,
      required this.label,
      required this.helpContentId,
      required this.semanticsHint});

  final IconData icon;
  final String label;
  final String helpContentId;
  final String semanticsHint;
}
