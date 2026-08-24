//
//  graphview_canvas_toolbar.dart
//  Turing Lab
//
//  Defines the shared expandable canvas toolbar used by FSA, PDA, and TM.
//  Primary editing tools remain visible while history, viewport, destructive,
//  and support actions expand into the same row or an explicit overflow menu.
//
//  Thales Matheus Mendonça Santos - October 2025
//
import 'package:flutter/material.dart';

import '../../core/constants/help_topic_ids.dart';
import '../../features/canvas/graphview/base_graphview_canvas_controller.dart';
import '../../l10n/app_localizations.dart';
import '../../l10n/app_localizations_resolver.dart';
import 'automaton_canvas_tool.dart';
import 'common/help_navigation.dart';
import 'contextual_help_tooltip.dart';

part 'graphview_canvas_toolbar_group.dart';
part 'graphview_canvas_toolbar_group_config.dart';
part 'graphview_canvas_toolbar_placement.dart';
part 'graphview_canvas_toolbar_widget.dart';

const double _kToolbarButtonExtent = 44;
const double _kWideExpandedToolbarWidth = 760;
const double _kCompactToolbarInlineZoomMinWidth = 312;
const double _kViewportClearance = 8;

class _GraphViewCanvasToolbarState extends State<GraphViewCanvasToolbar> {
  final GlobalKey _surfaceKey = GlobalKey();
  bool _expanded = false;
  bool _geometryReportScheduled = false;
  EdgeInsets? _lastReportedInsets;

  TransformationController? get _transformationController =>
      widget.controller.graphController.transformationController;

  @override
  void initState() {
    super.initState();
    _attachControllerListeners();
  }

  @override
  void didUpdateWidget(covariant GraphViewCanvasToolbar oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.controller != widget.controller) {
      _detachControllerListeners(oldWidget.controller);
      _attachControllerListeners();
      _lastReportedInsets = null;
    }
    if (oldWidget.placement != widget.placement) {
      _lastReportedInsets = null;
      _scheduleGeometryReport();
    }
  }

  @override
  void dispose() {
    _detachControllerListeners(widget.controller);
    super.dispose();
  }

  void _attachControllerListeners() {
    widget.controller.graphRevision.addListener(_handleControllerChanged);
    _transformationController?.addListener(_handleControllerChanged);
  }

  void _detachControllerListeners(
    BaseGraphViewCanvasController<dynamic, dynamic> controller,
  ) {
    controller.graphRevision.removeListener(_handleControllerChanged);
    controller.graphController.transformationController?.removeListener(
      _handleControllerChanged,
    );
  }

  void _handleControllerChanged() {
    if (mounted) {
      setState(() {});
    }
  }

  void _toggleExpanded() {
    setState(() {
      _expanded = !_expanded;
    });
    _scheduleGeometryReport();
  }

  void _scheduleGeometryReport() {
    if (_geometryReportScheduled) {
      return;
    }
    _geometryReportScheduled = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _geometryReportScheduled = false;
      if (!mounted) {
        return;
      }
      final viewportBox = context.findRenderObject();
      final surfaceBox = _surfaceKey.currentContext?.findRenderObject();
      if (viewportBox is! RenderBox ||
          surfaceBox is! RenderBox ||
          !viewportBox.hasSize ||
          !surfaceBox.hasSize) {
        return;
      }
      final surfaceOrigin = surfaceBox.localToGlobal(
        Offset.zero,
        ancestor: viewportBox,
      );
      final surfaceRect = surfaceOrigin & surfaceBox.size;
      final insets = switch (widget.placement) {
        CanvasToolbarPlacement.topRight => EdgeInsets.only(
            top: surfaceRect.bottom + _kViewportClearance,
          ),
        CanvasToolbarPlacement.bottomCenter => EdgeInsets.only(
            bottom:
                viewportBox.size.height - surfaceRect.top + _kViewportClearance,
          ),
      };
      if (_lastReportedInsets == insets) {
        return;
      }
      _lastReportedInsets = insets;
      widget.controller.updateViewportInsets(insets);
      widget.onViewportInsetsChanged?.call(insets);
    });
  }

  @override
  Widget build(BuildContext context) {
    _scheduleGeometryReport();
    final placement = widget.placement;
    final alignment = switch (placement) {
      CanvasToolbarPlacement.topRight => Alignment.topRight,
      CanvasToolbarPlacement.bottomCenter => Alignment.bottomCenter,
    };
    final safeAreaMinimum = switch (placement) {
      CanvasToolbarPlacement.topRight => const EdgeInsets.all(12),
      CanvasToolbarPlacement.bottomCenter =>
        const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
    };

    return Align(
      alignment: alignment,
      child: SafeArea(
        minimum: safeAreaMinimum,
        child: LayoutBuilder(
          builder: (context, constraints) {
            final useWideExpandedLayout = _expanded &&
                (!constraints.maxWidth.isFinite ||
                    constraints.maxWidth >= _kWideExpandedToolbarWidth);
            final showCompactInlineZoom = !constraints.maxWidth.isFinite ||
                constraints.maxWidth >= _kCompactToolbarInlineZoomMinWidth;
            final reduceMotion =
                MediaQuery.maybeOf(context)?.disableAnimations ?? false;
            final groups = _buildActionGroups(context);
            final surface = _ToolbarSurface(
              key: _surfaceKey,
              groups: groups,
              expanded: _expanded,
              useWideExpandedLayout: useWideExpandedLayout,
              showCompactInlineZoom: showCompactInlineZoom,
              currentZoomPercent:
                  (widget.controller.currentScale * 100).round(),
              statusMessage: widget.statusMessage,
              onToggleExpanded: _toggleExpanded,
            );

            return NotificationListener<SizeChangedLayoutNotification>(
              onNotification: (_) {
                _scheduleGeometryReport();
                return false;
              },
              child: SizeChangedLayoutNotifier(
                child: FocusTraversalGroup(
                  policy: OrderedTraversalPolicy(),
                  child: reduceMotion
                      ? KeyedSubtree(
                          key: const ValueKey(
                            'canvas-toolbar-reduced-motion',
                          ),
                          child: surface,
                        )
                      : AnimatedSize(
                          key: const ValueKey('canvas-toolbar-animated-size'),
                          alignment: alignment,
                          duration: const Duration(milliseconds: 180),
                          curve: Curves.easeOutCubic,
                          clipBehavior: Clip.none,
                          child: surface,
                        ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  List<_ToolbarGroupConfig> _buildActionGroups(BuildContext context) {
    final controller = widget.controller;
    return [
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
            handler: controller.canUndo ? controller.undo : null,
          ),
          _ToolbarButtonConfig(
            action: _ToolbarAction.redo,
            handler: controller.canRedo ? controller.redo : null,
          ),
        ],
      ),
      _ToolbarGroupConfig(
        id: _ToolbarGroup.viewport,
        actions: [
          _ToolbarButtonConfig(
            action: _ToolbarAction.zoomOut,
            handler: controller.canZoomOut ? controller.zoomOut : null,
          ),
          _ToolbarButtonConfig(
            action: _ToolbarAction.zoomIn,
            handler: controller.canZoomIn ? controller.zoomIn : null,
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
              handler: widget.onClear,
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
                  openHelp(context, topicId: HelpTopicIds.shortcutsCanvas);
                },
          ),
        ],
      ),
    ];
  }
}

class _ToolbarSurface extends StatelessWidget {
  const _ToolbarSurface({
    super.key,
    required this.groups,
    required this.expanded,
    required this.useWideExpandedLayout,
    required this.showCompactInlineZoom,
    required this.currentZoomPercent,
    required this.statusMessage,
    required this.onToggleExpanded,
  });

  final List<_ToolbarGroupConfig> groups;
  final bool expanded;
  final bool useWideExpandedLayout;
  final bool showCompactInlineZoom;
  final int currentZoomPercent;
  final String? statusMessage;
  final VoidCallback onToggleExpanded;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final rowChildren = !expanded
        ? _buildCollapsedChildren(context)
        : useWideExpandedLayout
            ? _buildWideExpandedChildren(context)
            : _buildCompactExpandedChildren(
                context,
                showInlineZoom: showCompactInlineZoom,
              );

    return SizedBox(
      height: 60,
      child: Material(
        key: const ValueKey('canvas-toolbar-surface'),
        color: colorScheme.surfaceContainerHigh,
        elevation: 6,
        shadowColor: colorScheme.shadow.withValues(alpha: 0.24),
        borderRadius: BorderRadius.circular(18),
        clipBehavior: Clip.antiAlias,
        child: Padding(
          padding: const EdgeInsets.all(6),
          child: Row(mainAxisSize: MainAxisSize.min, children: rowChildren),
        ),
      ),
    );
  }

  List<Widget> _buildCollapsedChildren(BuildContext context) {
    final editingGroup = groups.firstWhere(
      (group) => group.id == _ToolbarGroup.editing,
    );
    return [
      _ToolbarActionGroup(config: editingGroup),
      const SizedBox(width: 8),
      _ToolbarChromeButton(
        icon: Icons.open_in_full,
        label: appLocalizationsOf(context).canvasExpandToolbarAction,
        hint: appLocalizationsOf(context).canvasExpandToolbarHint,
        traversalOrder: 900,
        onPressed: onToggleExpanded,
      ),
    ];
  }

  List<Widget> _buildWideExpandedChildren(BuildContext context) {
    final children = <Widget>[];
    for (final group in groups) {
      if (children.isNotEmpty) {
        children.add(const SizedBox(width: 8));
      }
      children.add(
        _ToolbarActionGroup(
          config: group,
          currentZoomPercent:
              group.id == _ToolbarGroup.viewport ? currentZoomPercent : null,
        ),
      );
    }
    if (statusMessage case final message? when message.trim().isNotEmpty) {
      children
        ..add(const SizedBox(width: 8))
        ..add(_ToolbarStatusAffordance(message: message));
    }
    children
      ..add(const SizedBox(width: 8))
      ..add(
        _ToolbarChromeButton(
          icon: Icons.close_fullscreen,
          label: appLocalizationsOf(context).canvasCollapseToolbarAction,
          hint: appLocalizationsOf(context).canvasCollapseToolbarHint,
          traversalOrder: 900,
          onPressed: onToggleExpanded,
        ),
      );
    return children;
  }

  List<Widget> _buildCompactExpandedChildren(
    BuildContext context, {
    required bool showInlineZoom,
  }) {
    final editingGroup = groups.firstWhere(
      (group) => group.id == _ToolbarGroup.editing,
    );
    return [
      _ToolbarActionGroup(config: editingGroup),
      if (showInlineZoom) ...[
        const SizedBox(width: 6),
        _ToolbarZoomLabel(percent: currentZoomPercent),
      ],
      const SizedBox(width: 6),
      _ToolbarOverflowButton(
        groups: groups,
        currentZoomPercent: currentZoomPercent,
        statusMessage: statusMessage,
      ),
      const SizedBox(width: 6),
      _ToolbarChromeButton(
        icon: Icons.close_fullscreen,
        label: appLocalizationsOf(context).canvasCollapseToolbarAction,
        hint: appLocalizationsOf(context).canvasCollapseToolbarHint,
        traversalOrder: 900,
        onPressed: onToggleExpanded,
      ),
    ];
  }
}

class _ToolbarActionGroup extends StatelessWidget {
  const _ToolbarActionGroup({
    required this.config,
    this.currentZoomPercent,
  });

  final _ToolbarGroupConfig config;
  final int? currentZoomPercent;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final children = <Widget>[];
    for (final action in config.actions) {
      if (children.isNotEmpty) {
        children.add(const SizedBox(width: 2));
      }
      children.add(
        _ToolbarActionButton(config: action, group: config.id),
      );
      if (config.id == _ToolbarGroup.viewport &&
          action.action == _ToolbarAction.zoomOut &&
          currentZoomPercent != null) {
        children
          ..add(const SizedBox(width: 2))
          ..add(_ToolbarZoomLabel(percent: currentZoomPercent!));
      }
    }

    return DecoratedBox(
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.56),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: config.id == _ToolbarGroup.help
            ? const EdgeInsets.symmetric(horizontal: 2)
            : const EdgeInsets.all(2),
        child: Row(mainAxisSize: MainAxisSize.min, children: children),
      ),
    );
  }
}

class _ToolbarActionButton extends StatelessWidget {
  const _ToolbarActionButton({required this.config, required this.group});

  final _ToolbarButtonConfig config;
  final _ToolbarGroup group;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final l10n = appLocalizationsOf(context);
    final actionLabel = config.action.label(l10n);
    final isDestructive = group == _ToolbarGroup.destructive;
    final button = FocusTraversalOrder(
      order: NumericFocusOrder(config.action.traversalOrder),
      child: Semantics(
        label: l10n.canvasActionSemantics(actionLabel),
        hint: config.action.semanticsHint(l10n),
        button: true,
        enabled: config.handler != null,
        toggled: config.isToggle ? config.isSelected : null,
        excludeSemantics: true,
        child: IconButton(
          tooltip: null,
          icon: Icon(config.action.icon),
          onPressed: config.handler,
          style: _toolbarActionButtonStyle(
            config: config,
            isDestructive: isDestructive,
            colorScheme: colorScheme,
          ),
        ),
      ),
    );
    return ContextualHelpTooltip(message: actionLabel, child: button);
  }
}

class _ToolbarChromeButton extends StatelessWidget {
  const _ToolbarChromeButton({
    required this.icon,
    required this.label,
    required this.hint,
    required this.traversalOrder,
    required this.onPressed,
  });

  final IconData icon;
  final String label;
  final String hint;
  final double traversalOrder;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final l10n = appLocalizationsOf(context);
    return FocusTraversalOrder(
      order: NumericFocusOrder(traversalOrder),
      child: Semantics(
        label: l10n.canvasActionSemantics(label),
        hint: hint,
        button: true,
        excludeSemantics: true,
        child: IconButton(
          tooltip: label,
          onPressed: onPressed,
          icon: Icon(icon),
          style: IconButton.styleFrom(
            fixedSize: const Size.square(_kToolbarButtonExtent),
            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            foregroundColor: colorScheme.onSurfaceVariant,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
        ),
      ),
    );
  }
}

class _ToolbarZoomLabel extends StatelessWidget {
  const _ToolbarZoomLabel({required this.percent});

  final int percent;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = appLocalizationsOf(context);
    return Semantics(
      label: l10n.canvasZoomLevel(percent),
      readOnly: true,
      excludeSemantics: true,
      child: ConstrainedBox(
        constraints: const BoxConstraints(minWidth: 54, minHeight: 44),
        child: Center(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 6),
            child: Text(
              '$percent%',
              maxLines: 1,
              style: theme.textTheme.labelMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
                fontFeatures: const [FontFeature.tabularFigures()],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _ToolbarStatusAffordance extends StatelessWidget {
  const _ToolbarStatusAffordance({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: message,
      child: Semantics(
        label: message,
        readOnly: true,
        excludeSemantics: true,
        child: const SizedBox.square(
          dimension: _kToolbarButtonExtent,
          child: Icon(Icons.info_outline),
        ),
      ),
    );
  }
}

class _ToolbarOverflowButton extends StatelessWidget {
  const _ToolbarOverflowButton({
    required this.groups,
    required this.currentZoomPercent,
    required this.statusMessage,
  });

  final List<_ToolbarGroupConfig> groups;
  final int currentZoomPercent;
  final String? statusMessage;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final l10n = appLocalizationsOf(context);
    final overflowGroups = groups
        .where((group) => group.id != _ToolbarGroup.editing)
        .toList(growable: false);

    return FocusTraversalOrder(
      order: const NumericFocusOrder(800),
      child: Semantics(
        label: l10n.canvasActionSemantics(l10n.canvasMoreActions),
        hint: l10n.canvasMoreActionsHint,
        button: true,
        excludeSemantics: true,
        child: SizedBox.square(
          dimension: _kToolbarButtonExtent,
          child: PopupMenuButton<_ToolbarAction>(
            key: const ValueKey('canvas-toolbar-overflow'),
            tooltip: l10n.canvasMoreActions,
            icon: const Icon(Icons.more_horiz),
            padding: EdgeInsets.zero,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
            ),
            onSelected: (action) {
              for (final group in overflowGroups) {
                for (final config in group.actions) {
                  if (config.action == action) {
                    config.handler?.call();
                    return;
                  }
                }
              }
            },
            itemBuilder: (context) {
              final items = <PopupMenuEntry<_ToolbarAction>>[
                PopupMenuItem<_ToolbarAction>(
                  enabled: false,
                  height: _kToolbarButtonExtent,
                  child: Row(
                    children: [
                      const Icon(Icons.zoom_in_map),
                      const SizedBox(width: 12),
                      Text(l10n.canvasZoomLevel(currentZoomPercent)),
                    ],
                  ),
                ),
              ];
              for (var groupIndex = 0;
                  groupIndex < overflowGroups.length;
                  groupIndex++) {
                final group = overflowGroups[groupIndex];
                if (groupIndex > 0) {
                  items.add(const PopupMenuDivider());
                }
                for (final config in group.actions) {
                  final isDestructive = group.id == _ToolbarGroup.destructive;
                  items.add(
                    PopupMenuItem<_ToolbarAction>(
                      value: config.action,
                      enabled: config.handler != null,
                      height: _kToolbarButtonExtent,
                      child: Row(
                        children: [
                          Icon(
                            config.action.icon,
                            color: isDestructive ? colorScheme.error : null,
                          ),
                          const SizedBox(width: 12),
                          Text(
                            config.action.label(l10n),
                            style: isDestructive
                                ? TextStyle(color: colorScheme.error)
                                : null,
                          ),
                        ],
                      ),
                    ),
                  );
                }
              }
              if (statusMessage case final message?
                  when message.trim().isNotEmpty) {
                items
                  ..add(const PopupMenuDivider())
                  ..add(
                    PopupMenuItem<_ToolbarAction>(
                      enabled: false,
                      height: _kToolbarButtonExtent,
                      child: Row(
                        children: [
                          const Icon(Icons.info_outline),
                          const SizedBox(width: 12),
                          Flexible(child: Text(message)),
                        ],
                      ),
                    ),
                  );
              }
              return items;
            },
          ),
        ),
      ),
    );
  }
}

ButtonStyle _toolbarActionButtonStyle({
  required _ToolbarButtonConfig config,
  required bool isDestructive,
  required ColorScheme colorScheme,
}) {
  final isSelected = config.isToggle && config.isSelected;
  return IconButton.styleFrom(
    fixedSize: config.action == _ToolbarAction.help
        ? const Size.square(48)
        : const Size.square(_kToolbarButtonExtent),
    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
    backgroundColor: isDestructive
        ? colorScheme.errorContainer
        : isSelected
            ? colorScheme.primaryContainer
            : Colors.transparent,
    foregroundColor: isDestructive
        ? colorScheme.onErrorContainer
        : isSelected
            ? colorScheme.onPrimaryContainer
            : colorScheme.onSurfaceVariant,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(10),
      side: isDestructive
          ? BorderSide(color: colorScheme.error.withValues(alpha: 0.45))
          : isSelected
              ? BorderSide(
                  color: colorScheme.primary.withValues(alpha: 0.42),
                )
              : BorderSide.none,
    ),
  );
}

class _ToolbarButtonConfig {
  const _ToolbarButtonConfig({
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
  selection(icon: Icons.pan_tool),
  addState(icon: Icons.add),
  transition(icon: Icons.arrow_right_alt),
  undo(icon: Icons.undo),
  redo(icon: Icons.redo),
  zoomOut(icon: Icons.zoom_out),
  zoomIn(icon: Icons.zoom_in),
  fitContent(icon: Icons.fit_screen),
  resetView(icon: Icons.center_focus_strong),
  clear(icon: Icons.delete_outline),
  help(icon: Icons.help_outline);

  const _ToolbarAction({required this.icon});

  final IconData icon;

  double get traversalOrder => index.toDouble();

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
