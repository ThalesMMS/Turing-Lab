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
  });

  final Widget child;
  final String label;
  final IconData icon;
  final bool initiallyExpanded;

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

  @override
  Widget build(BuildContext context) {
    final l10n = appLocalizationsOf(context);
    final tooltip = _expanded
        ? l10n.collapseCanvasPanel(widget.label)
        : l10n.expandCanvasPanel(widget.label);

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Tooltip(
          message: tooltip,
          child: Semantics(
            label: tooltip,
            button: true,
            child: IconButton.filledTonal(
              constraints: const BoxConstraints.tightFor(
                width: 48,
                height: 48,
              ),
              onPressed: () => setState(() => _expanded = !_expanded),
              icon: Icon(_expanded ? Icons.unfold_less : widget.icon),
            ),
          ),
        ),
        Offstage(
          offstage: !_expanded,
          child: widget.child,
        ),
      ],
    );
  }
}
