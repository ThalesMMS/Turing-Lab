//
//  collapsible_canvas_panel.dart
//  Turing Lab
//
//  Keeps an interactive mobile canvas inspector available while allowing its
//  overlay hit-test area to collapse to one explicit control.
//
//  Thales Matheus Mendonça Santos - August 2026
//

import 'package:flutter/material.dart';

import '../../l10n/app_localizations_resolver.dart';

class CollapsibleCanvasPanel extends StatefulWidget {
  const CollapsibleCanvasPanel({
    super.key,
    required this.child,
    required this.label,
    required this.icon,
    this.initiallyExpanded = true,
    this.onDragDelta,
    this.onPanelSizeChanged,
  });

  final Widget child;
  final String label;
  final IconData icon;
  final bool initiallyExpanded;
  final ValueChanged<Offset>? onDragDelta;
  final VoidCallback? onPanelSizeChanged;

  @override
  State<CollapsibleCanvasPanel> createState() => _CollapsibleCanvasPanelState();
}

class _CollapsibleCanvasPanelState extends State<CollapsibleCanvasPanel> {
  late bool _expanded;

  @override
  void initState() {
    super.initState();
    _expanded = widget.initiallyExpanded;
  }

  void _toggleExpanded() {
    setState(() => _expanded = !_expanded);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      widget.onPanelSizeChanged?.call();
    });
  }

  @override
  Widget build(BuildContext context) {
    final l10n = appLocalizationsOf(context);
    final expandTooltip = l10n.expandCanvasPanel(widget.label);
    final collapseTooltip = l10n.collapseCanvasPanel(widget.label);
    void Function(DragUpdateDetails)? onPanUpdate = widget.onDragDelta == null
        ? null
        : (details) => widget.onDragDelta!(details.delta);

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        // Collapsed: only the toggle button is visible.
        Offstage(
          offstage: _expanded,
          child: GestureDetector(
            behavior: HitTestBehavior.opaque,
            onPanUpdate: onPanUpdate,
            child: Tooltip(
              message: expandTooltip,
              child: Semantics(
                label: expandTooltip,
                button: true,
                child: IconButton.filledTonal(
                  constraints: const BoxConstraints.tightFor(
                    width: 48,
                    height: 48,
                  ),
                  onPressed: _toggleExpanded,
                  icon: Icon(widget.icon),
                ),
              ),
            ),
          ),
        ),
        // Expanded: the panel itself, with no toggle button. Tapping any
        // non-interactive spot collapses it (interactive children such as
        // Clear win the gesture arena); dragging moves the panel.
        Offstage(
          offstage: !_expanded,
          child: GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: _toggleExpanded,
            onPanUpdate: onPanUpdate,
            child: Semantics(
              label: collapseTooltip,
              button: true,
              child: widget.child,
            ),
          ),
        ),
      ],
    );
  }
}
