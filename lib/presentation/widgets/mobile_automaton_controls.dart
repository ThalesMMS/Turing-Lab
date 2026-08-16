//
//  mobile_automaton_controls.dart
//  Turing Lab
//
//  Widget que consolida os controles de edição de autômatos em uma superfície
//  otimizada para toque, reunindo ferramentas, histórico e ações de viewport.
//
//  Thales Matheus Mendonça Santos - October 2025
//
import 'package:flutter/material.dart';

import '../../l10n/app_localizations_resolver.dart';
import 'automaton_canvas_tool.dart';

/// Unified control surface for mobile automaton editors.
///
/// Workspace actions remain in the page quick actions; this widget owns only
/// the canvas controls shared by touch editors.
class MobileAutomatonControls extends StatelessWidget {
  const MobileAutomatonControls({
    super.key,
    this.enableToolSelection = false,
    this.showSelectionTool = false,
    this.activeTool = AutomatonCanvasTool.selection,
    this.onSelectTool,
    required this.onHelp,
    required this.onAddState,
    this.onAddTransition,
    this.onZoomIn,
    this.onZoomOut,
    required this.onFitToContent,
    required this.onResetView,
    this.onClear,
    this.onUndo,
    this.onRedo,
    this.statusMessage,
    this.canUndo = false,
    this.canRedo = false,
  })  : assert(
          !(enableToolSelection && showSelectionTool) || onSelectTool != null,
          'onSelectTool must be provided when the selection tool is visible.',
        ),
        assert(
          !enableToolSelection || onAddTransition != null,
          'onAddTransition must be provided when tool selection is enabled.',
        );

  final bool enableToolSelection;
  final bool showSelectionTool;
  final AutomatonCanvasTool activeTool;
  final VoidCallback? onSelectTool;
  final VoidCallback onHelp;
  final VoidCallback onAddState;
  final VoidCallback? onAddTransition;
  final VoidCallback? onZoomIn;
  final VoidCallback? onZoomOut;
  final VoidCallback onFitToContent;
  final VoidCallback onResetView;
  final VoidCallback? onClear;
  final VoidCallback? onUndo;
  final VoidCallback? onRedo;
  final String? statusMessage;
  final bool canUndo;
  final bool canRedo;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final textTheme = theme.textTheme;
    final l10n = appLocalizationsOf(context);

    final canvasActions = <_ControlAction>[
      _ControlAction(
        icon: Icons.help_outline,
        tooltip: l10n.canvasHelpAction,
        onPressed: onHelp,
      ),
      if (onUndo != null)
        _ControlAction(
          icon: Icons.undo,
          tooltip: l10n.canvasUndoAction,
          onPressed: canUndo ? onUndo : null,
        ),
      if (onRedo != null)
        _ControlAction(
          icon: Icons.redo,
          tooltip: l10n.canvasRedoAction,
          onPressed: canRedo ? onRedo : null,
        ),
      if (enableToolSelection && showSelectionTool)
        _ControlAction(
          icon: Icons.pan_tool,
          label: l10n.canvasSelectAction,
          onPressed: onSelectTool,
          isToggle: true,
          isSelected: activeTool == AutomatonCanvasTool.selection,
        ),
      _ControlAction(
        icon: Icons.add,
        tooltip: l10n.canvasAddStateAction,
        onPressed: onAddState,
        isToggle: enableToolSelection,
        isSelected:
            enableToolSelection && activeTool == AutomatonCanvasTool.addState,
      ),
      if (onAddTransition != null)
        _ControlAction(
          icon: Icons.arrow_right_alt,
          label: l10n.canvasAddTransitionAction,
          onPressed: onAddTransition,
          isToggle: enableToolSelection,
          isSelected: enableToolSelection &&
              activeTool == AutomatonCanvasTool.transition,
        ),
      if (onZoomOut != null)
        _ControlAction(
          icon: Icons.zoom_out,
          tooltip: l10n.canvasZoomOutAction,
          onPressed: onZoomOut,
        ),
      if (onZoomIn != null)
        _ControlAction(
          icon: Icons.zoom_in,
          tooltip: l10n.canvasZoomInAction,
          onPressed: onZoomIn,
        ),
      _ControlAction(
        icon: Icons.fit_screen,
        tooltip: l10n.canvasFitToContentAction,
        onPressed: onFitToContent,
      ),
      _ControlAction(
        icon: Icons.center_focus_strong,
        tooltip: l10n.canvasResetViewAction,
        onPressed: onResetView,
      ),
      if (onClear != null)
        _ControlAction(
          icon: Icons.delete_outline,
          tooltip: l10n.canvasClearAction,
          onPressed: onClear,
        ),
    ];

    return Align(
      alignment: Alignment.bottomCenter,
      child: SafeArea(
        minimum: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 560),
          child: Material(
            borderRadius: BorderRadius.circular(20),
            color: colorScheme.surface,
            elevation: 10,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  if (canvasActions.isNotEmpty)
                    Wrap(
                      alignment: WrapAlignment.center,
                      spacing: 8,
                      runSpacing: 8,
                      children: canvasActions
                          .map(
                            (action) => _MobileControlButton(action: action),
                          )
                          .toList(),
                    ),
                  if (statusMessage != null && statusMessage!.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(top: 10),
                      child: Text(
                        statusMessage!,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: textTheme.bodySmall?.copyWith(
                          color: colorScheme.onSurfaceVariant,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _ControlAction {
  const _ControlAction({
    required this.icon,
    this.tooltip,
    this.label,
    required this.onPressed,
    this.isToggle = false,
    this.isSelected = false,
  });

  final IconData icon;

  /// Texto mostrado no Tooltip. Se não vier, caímos para [label] (se houver).
  final String? tooltip;

  final String? label;

  final VoidCallback? onPressed;
  final bool isToggle;
  final bool isSelected;

  String get effectiveTooltip =>
      (tooltip?.trim().isNotEmpty == true) ? tooltip! : (label ?? '');
}

class _MobileControlButton extends StatelessWidget {
  const _MobileControlButton({required this.action});

  final _ControlAction action;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    // Base para todos os ícones (circular, compacto).
    final baseStyle = IconButton.styleFrom(
      padding: const EdgeInsets.all(8),
      visualDensity: VisualDensity.compact,
      minimumSize: const Size.square(40),
      shape: const CircleBorder(),
    );

    // Aplica cores de "toggle selecionado" quando aplicável.
    final bool canPress = action.onPressed != null;
    final bool selected = action.isToggle && action.isSelected && canPress;

    // Cores para estado selecionado vs normal (herda do tema).
    final ButtonStyle effectiveStyle = baseStyle.merge(
      IconButton.styleFrom(
        backgroundColor: selected
            ? colorScheme.secondaryContainer
            : null, // deixa default quando não selecionado
        foregroundColor: selected ? colorScheme.onSecondaryContainer : null,
      ),
    );

    final button = IconButton.filledTonal(
      onPressed: action.onPressed,
      style: effectiveStyle,
      icon: Icon(action.icon),
    );

    // Mantém acessibilidade e tooltip (fallback para label se tooltip não vier).
    final String tip = action.effectiveTooltip;

    return Tooltip(
      message: tip,
      child: Semantics(
        label: tip.isNotEmpty ? tip : null,
        button: true,
        enabled: canPress,
        toggled: action.isToggle ? selected : null,
        child: button,
      ),
    );
  }
}
