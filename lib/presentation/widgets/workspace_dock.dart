//
//  workspace_dock.dart
//  Turing Lab
//
//  Wide-screen workspace shell: the canvas fills the pane and every side
//  panel stays collapsed behind an icon rail, so the default view is the
//  canvas alone. Replaces the old always-open multi-column layout used by
//  the desktop and tablet workspaces.
//
//  Thales Matheus Mendonça Santos - August 2026
//
import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../l10n/app_localizations_help.dart';

/// One collapsible panel hosted by [WorkspaceDock].
///
/// The [child] widget is created eagerly by the page but only inflated while
/// the panel is open, so collapsed panels cost nothing beyond the widget
/// object itself.
@immutable
class WorkspaceDockPanel {
  const WorkspaceDockPanel({
    required this.id,
    required this.label,
    required this.icon,
    required this.child,
  });

  /// Stable identifier used to remember which panel is open.
  final String id;

  /// Title shown in the panel header and as the rail button tooltip.
  final String label;

  /// Rail button icon.
  final IconData icon;

  /// Panel body. Rendered inside a scroll view, so it must not expand to
  /// infinite height.
  final Widget child;
}

/// Canvas-first layout for wide viewports.
///
/// Lays out [content] across the whole pane, with an icon rail pinned to the
/// trailing edge. Tapping a rail icon slides its panel in beside the canvas;
/// tapping the active icon (or the panel's close button) collapses it again.
/// Nothing is open until the user asks for it.
class WorkspaceDock extends StatefulWidget {
  const WorkspaceDock({
    super.key,
    required this.content,
    required this.panels,
    this.initialPanelId,
    this.initialPanelWidth = defaultPanelWidth,
    this.contentPadding = const EdgeInsets.fromLTRB(12, 12, 0, 12),
    this.scrollPanels = true,
  });

  /// Width of the always-visible icon rail.
  static const double railWidth = 56;

  /// Width an open panel starts at before the user drags the divider.
  static const double defaultPanelWidth = 380;

  /// Narrowest an open panel may be dragged.
  static const double minPanelWidth = 280;

  /// Widest an open panel may be dragged.
  static const double maxPanelWidth = 620;

  /// Canvas width the dock refuses to eat into when sizing a panel.
  static const double minContentWidth = 320;

  /// Width of the draggable divider between canvas and panel.
  static const double dividerWidth = 8;

  /// Key of the rail button that toggles the panel with [panelId].
  static ValueKey<String> railButtonKey(String panelId) =>
      ValueKey<String>('workspace-dock-rail-$panelId');

  /// Key of the open panel with [panelId].
  static ValueKey<String> panelKey(String panelId) =>
      ValueKey<String>('workspace-dock-panel-$panelId');

  /// Main workspace surface — canvas, editor, or game board.
  final Widget content;

  /// Panels offered by the rail, in rail order. An empty list renders the
  /// content alone, without a rail.
  final List<WorkspaceDockPanel> panels;

  /// Panel opened on first build. Defaults to none, keeping the canvas clear.
  final String? initialPanelId;

  /// Starting width for an open panel.
  final double initialPanelWidth;

  /// Padding around [content].
  final EdgeInsets contentPadding;

  /// Whether panel bodies are wrapped in a scroll view. Panels that manage
  /// their own scrolling pass false.
  final bool scrollPanels;

  @override
  State<WorkspaceDock> createState() => _WorkspaceDockState();
}

class _WorkspaceDockState extends State<WorkspaceDock> {
  String? _openPanelId;
  late double _panelWidth;

  @override
  void initState() {
    super.initState();
    _openPanelId = _resolveInitialPanelId();
    _panelWidth = widget.initialPanelWidth;
  }

  @override
  void didUpdateWidget(covariant WorkspaceDock oldWidget) {
    super.didUpdateWidget(oldWidget);
    // A page can stop offering a panel (for example when the info panel
    // depends on the loaded machine). Collapse instead of rendering a hole.
    if (_openPanelId != null && _panelById(_openPanelId!) == null) {
      _openPanelId = null;
    }
  }

  String? _resolveInitialPanelId() {
    final id = widget.initialPanelId;
    if (id == null) {
      return null;
    }
    return _panelById(id) == null ? null : id;
  }

  WorkspaceDockPanel? _panelById(String id) {
    for (final panel in widget.panels) {
      if (panel.id == id) {
        return panel;
      }
    }
    return null;
  }

  void _togglePanel(String id) {
    setState(() {
      _openPanelId = _openPanelId == id ? null : id;
    });
  }

  void _closePanel() {
    setState(() {
      _openPanelId = null;
    });
  }

  void _resizePanel(double delta, double maxWidth) {
    setState(() {
      // The panel is on the trailing edge, so dragging left widens it.
      _panelWidth = (_panelWidth - delta)
          .clamp(WorkspaceDock.minPanelWidth, maxWidth)
          .toDouble();
    });
  }

  @override
  Widget build(BuildContext context) {
    if (widget.panels.isEmpty) {
      return Padding(
        padding:
            widget.contentPadding.copyWith(right: widget.contentPadding.left),
        child: widget.content,
      );
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        final available = constraints.maxWidth -
            WorkspaceDock.railWidth -
            WorkspaceDock.dividerWidth -
            WorkspaceDock.minContentWidth;
        final maxPanelWidth = math.min(
          WorkspaceDock.maxPanelWidth,
          available.isFinite ? available : WorkspaceDock.maxPanelWidth,
        );
        final canHostPanel = maxPanelWidth >= WorkspaceDock.minPanelWidth;
        final openPanel = canHostPanel && _openPanelId != null
            ? _panelById(_openPanelId!)
            : null;
        final panelWidth = _panelWidth
            .clamp(
              WorkspaceDock.minPanelWidth,
              math.max(WorkspaceDock.minPanelWidth, maxPanelWidth),
            )
            .toDouble();

        return Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(
              child: Padding(
                padding: widget.contentPadding,
                child: widget.content,
              ),
            ),
            if (openPanel != null) ...[
              _DockDivider(
                onDrag: (delta) => _resizePanel(delta, maxPanelWidth),
              ),
              SizedBox(
                key: WorkspaceDock.panelKey(openPanel.id),
                width: panelWidth,
                child: _DockPanelBody(
                  panel: openPanel,
                  scrollable: widget.scrollPanels,
                  onClose: _closePanel,
                ),
              ),
            ],
            _DockRail(
              panels: widget.panels,
              openPanelId: openPanel?.id,
              onToggle: canHostPanel ? _togglePanel : null,
            ),
          ],
        );
      },
    );
  }
}

/// Trailing icon rail. Always visible so the panels stay discoverable even
/// though they start collapsed.
class _DockRail extends StatelessWidget {
  const _DockRail({
    required this.panels,
    required this.openPanelId,
    required this.onToggle,
  });

  final List<WorkspaceDockPanel> panels;
  final String? openPanelId;
  final ValueChanged<String>? onToggle;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = jflapLocalizationsOf(context);

    return Container(
      width: WorkspaceDock.railWidth,
      decoration: BoxDecoration(
        border: Border(
          left: BorderSide(color: theme.colorScheme.outlineVariant),
        ),
      ),
      child: SingleChildScrollView(
        child: Column(
          children: [
            const SizedBox(height: 12),
            for (final panel in panels)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 2),
                child: _DockRailButton(
                  key: WorkspaceDock.railButtonKey(panel.id),
                  panel: panel,
                  selected: panel.id == openPanelId,
                  tooltip: panel.id == openPanelId
                      ? l10n.workspaceDockHidePanel(panel.label)
                      : l10n.workspaceDockShowPanel(panel.label),
                  onPressed:
                      onToggle == null ? null : () => onToggle!(panel.id),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _DockRailButton extends StatelessWidget {
  const _DockRailButton({
    super.key,
    required this.panel,
    required this.selected,
    required this.tooltip,
    required this.onPressed,
  });

  final WorkspaceDockPanel panel;
  final bool selected;
  final String tooltip;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Semantics(
      label: tooltip,
      button: true,
      enabled: onPressed != null,
      selected: selected,
      excludeSemantics: true,
      child: IconButton(
        onPressed: onPressed,
        isSelected: selected,
        tooltip: tooltip,
        icon: Icon(panel.icon),
        style: IconButton.styleFrom(
          foregroundColor: colorScheme.onSurfaceVariant,
          backgroundColor: Colors.transparent,
          highlightColor: colorScheme.primary.withValues(alpha: 0.12),
        ),
        selectedIcon: Icon(panel.icon, color: colorScheme.primary),
      ),
    );
  }
}

/// Card that hosts the open panel, with a header carrying its own close
/// affordance so collapsing never requires hunting for the rail icon again.
class _DockPanelBody extends StatelessWidget {
  const _DockPanelBody({
    required this.panel,
    required this.scrollable,
    required this.onClose,
  });

  final WorkspaceDockPanel panel;
  final bool scrollable;
  final VoidCallback onClose;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = jflapLocalizationsOf(context);

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      // No border of its own: the hosted panels already render bordered
      // cards, and nesting the two reads as a panel inside a panel.
      child: Container(
        decoration: BoxDecoration(
          color: theme.colorScheme.surface,
          borderRadius: BorderRadius.circular(12),
        ),
        clipBehavior: Clip.antiAlias,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Chrome only: every hosted panel already renders its own title,
            // so repeating it here would just add clutter.
            Align(
              alignment: Alignment.centerRight,
              child: Padding(
                padding: const EdgeInsets.only(top: 4, right: 4),
                child: IconButton(
                  onPressed: onClose,
                  tooltip: l10n.workspaceDockHidePanel(panel.label),
                  icon: const Icon(Icons.close),
                  iconSize: 18,
                  visualDensity: VisualDensity.compact,
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ),
            Expanded(
              child: scrollable
                  ? SingleChildScrollView(
                      padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                      child: panel.child,
                    )
                  : Padding(
                      padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                      child: panel.child,
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Draggable divider that trades canvas width for panel width.
class _DockDivider extends StatelessWidget {
  const _DockDivider({required this.onDrag});

  final ValueChanged<double> onDrag;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = jflapLocalizationsOf(context);

    return MouseRegion(
      cursor: SystemMouseCursors.resizeLeftRight,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onHorizontalDragUpdate: (details) => onDrag(details.delta.dx),
        child: Semantics(
          label: l10n.workspaceDockResizePanel,
          child: SizedBox(
            width: WorkspaceDock.dividerWidth,
            child: Center(
              child: Container(
                width: 2,
                height: 32,
                decoration: BoxDecoration(
                  color: theme.colorScheme.outlineVariant,
                  borderRadius: BorderRadius.circular(1),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
