import 'dart:math' as math;

import 'package:flutter/material.dart';

/// Shared frame used by all automaton transition editors.
class TransitionEditorShell extends StatelessWidget {
  const TransitionEditorShell({
    super.key,
    required this.child,
    this.maxWidth = 360,
  });

  static const double _outerMargin = 24;

  final Widget child;
  final double maxWidth;

  @override
  Widget build(BuildContext context) {
    final mediaQuery = MediaQuery.of(context);
    final availableSize = mediaQuery.size;
    // The label fields autofocus, so the soft keyboard is usually open while
    // this editor is visible. Subtract its inset, otherwise the action row can
    // end up behind the keyboard and become unreachable.
    final verticalInsets =
        mediaQuery.viewInsets.vertical + mediaQuery.viewPadding.vertical;
    final availableWidth = availableSize.width - _outerMargin;
    final availableHeight =
        availableSize.height - verticalInsets - _outerMargin;
    final editorWidth = availableWidth.clamp(0.0, maxWidth).toDouble();
    return Material(
      elevation: 4,
      borderRadius: BorderRadius.circular(8),
      child: SizedBox(
        width: editorWidth,
        child: ConstrainedBox(
          constraints: BoxConstraints(
            maxHeight: math.max(0.0, availableHeight),
          ),
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(12),
            child: child,
          ),
        ),
      ),
    );
  }
}
