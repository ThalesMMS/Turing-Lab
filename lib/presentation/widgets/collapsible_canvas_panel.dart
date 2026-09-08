//
//  collapsible_canvas_panel.dart
//  Turing Lab
//
//  Keeps an interactive canvas inspector available while allowing its
//  overlay hit-test area to collapse to one explicit control.
//
//  Thales Matheus Mendonça Santos - August 2026
//

import 'package:flutter/material.dart';

import '../../l10n/app_localizations_resolver.dart';

/// Controls whether a [CollapsibleCanvasPanel] exposes its panel body.
class CollapsibleCanvasPanelController extends ChangeNotifier {
  CollapsibleCanvasPanelController({bool expanded = false})
    : _expanded = expanded;

  bool _expanded;

  bool get expanded => _expanded;

  void open() => _setExpanded(true);

  void close() => _setExpanded(false);

  void toggle() => _setExpanded(!_expanded);

  void _setExpanded(bool value) {
    if (_expanded == value) return;
    _expanded = value;
    notifyListeners();
  }
}

class CollapsibleCanvasPanel extends StatefulWidget {
  const CollapsibleCanvasPanel({
    super.key,
    required this.child,
    required this.label,
    required this.icon,
    this.initiallyExpanded = true,
    this.controller,
    this.onDragDelta,
    this.onPanelSizeChanged,
    this.showCollapseButton = false,
  });

  /// Adds an explicit collapse control alongside the existing body-tap gesture.
  final bool showCollapseButton;
  final Widget child;
  final String label;
  final IconData icon;
  final bool initiallyExpanded;
  final CollapsibleCanvasPanelController? controller;
  final ValueChanged<Offset>? onDragDelta;
  final VoidCallback? onPanelSizeChanged;

  @override
  State<CollapsibleCanvasPanel> createState() => _CollapsibleCanvasPanelState();
}

class _CollapsibleCanvasPanelState extends State<CollapsibleCanvasPanel> {
  late final CollapsibleCanvasPanelController _internalController;

  CollapsibleCanvasPanelController get _controller =>
      widget.controller ?? _internalController;

  @override
  void initState() {
    super.initState();
    _internalController = CollapsibleCanvasPanelController(
      expanded: widget.initiallyExpanded,
    );
    _controller.addListener(_handleControllerChanged);
  }

  @override
  void didUpdateWidget(covariant CollapsibleCanvasPanel oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.controller != widget.controller) {
      (oldWidget.controller ?? _internalController).removeListener(
        _handleControllerChanged,
      );
      _controller.addListener(_handleControllerChanged);
    }
  }

  @override
  void dispose() {
    _controller.removeListener(_handleControllerChanged);
    _internalController.dispose();
    super.dispose();
  }

  void _handleControllerChanged() {
    if (!mounted) return;
    setState(() {});
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      widget.onPanelSizeChanged?.call();
    });
  }

  void _toggleExpanded() => _controller.toggle();

  @override
  Widget build(BuildContext context) {
    final l10n = appLocalizationsOf(context);
    final expandTooltip = l10n.expandCanvasPanel(widget.label);
    final collapseTooltip = l10n.collapseCanvasPanel(widget.label);
    final void Function(DragUpdateDetails)? onPanUpdate =
        widget.onDragDelta == null
        ? null
        : (details) => widget.onDragDelta!(details.delta);

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        // Collapsed: only the toggle button is visible.
        Offstage(
          offstage: _controller.expanded,
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
        // Body taps collapse the panel; interactive children such as Clear
        // keep their own actions. The optional button makes collapse explicit.
        // Dragging the body or the button moves the panel.
        Offstage(
          offstage: !_controller.expanded,
          child: GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: _toggleExpanded,
            onPanUpdate: onPanUpdate,
            child: Semantics(
              label: collapseTooltip,
              button: true,
              child: widget.showCollapseButton
                  ? Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        IconButton.filledTonal(
                          tooltip: collapseTooltip,
                          onPressed: _toggleExpanded,
                          icon: const Icon(Icons.expand_less),
                        ),
                        widget.child,
                      ],
                    )
                  : widget.child,
            ),
          ),
        ),
      ],
    );
  }
}
