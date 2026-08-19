import 'dart:math' as math;

import 'package:flutter/material.dart';

typedef MovableCanvasPanelBuilder = Widget Function(
  BuildContext context, {
  required ValueChanged<Offset> onDragDelta,
  required VoidCallback onPanelSizeChanged,
});

class MovableCanvasPanelHost extends StatefulWidget {
  const MovableCanvasPanelHost({
    super.key,
    required this.builder,
    this.initialTop = 16,
    this.initialRight = 16,
    this.edgePadding = 8,
    this.initialPosition,
    this.onPositionChanged,
  });

  final MovableCanvasPanelBuilder builder;
  final double initialTop;
  final double initialRight;
  final double edgePadding;

  /// Panel anchor as (distance from the host's right edge, top). The panel is
  /// anchored by its top-right corner — where the collapse toggle sits — so
  /// expanding or collapsing the panel never moves the toggle.
  final Offset? initialPosition;
  final ValueChanged<Offset>? onPositionChanged;

  @override
  State<MovableCanvasPanelHost> createState() => _MovableCanvasPanelHostState();
}

class _MovableCanvasPanelHostState extends State<MovableCanvasPanelHost> {
  final GlobalKey _hostKey = GlobalKey();
  final GlobalKey _panelKey = GlobalKey();
  Size _hostSize = Size.zero;
  late Offset? _position;
  bool _clampScheduled = false;

  @override
  void initState() {
    super.initState();
    _position = widget.initialPosition;
  }

  RenderBox? get _hostBox =>
      _hostKey.currentContext?.findRenderObject() as RenderBox?;

  RenderBox? get _panelBox =>
      _panelKey.currentContext?.findRenderObject() as RenderBox?;

  Offset? _renderedAnchor() {
    final hostBox = _hostBox;
    final panelBox = _panelBox;
    if (hostBox == null || panelBox == null) return null;
    final topLeft = panelBox.localToGlobal(Offset.zero, ancestor: hostBox);
    return Offset(
      hostBox.size.width - topLeft.dx - panelBox.size.width,
      topLeft.dy,
    );
  }

  Offset _clamp(Offset candidate, Size panelSize) {
    final padding = widget.edgePadding;
    final maxX = math.max(
      padding,
      _hostSize.width - panelSize.width - padding,
    );
    final maxY = math.max(
      padding,
      _hostSize.height - panelSize.height - padding,
    );
    return Offset(
      candidate.dx.clamp(padding, maxX).toDouble(),
      candidate.dy.clamp(padding, maxY).toDouble(),
    );
  }

  void _moveBy(Offset delta) {
    final panelBox = _panelBox;
    if (panelBox == null || _hostSize.isEmpty) return;
    final current = _position ?? _renderedAnchor();
    if (current == null) return;
    setState(() {
      _position = _clamp(current + Offset(-delta.dx, delta.dy), panelBox.size);
    });
    widget.onPositionChanged?.call(_position!);
  }

  void _scheduleClamp() {
    if (_clampScheduled) return;
    _clampScheduled = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _clampScheduled = false;
      if (!mounted) return;
      final panelBox = _panelBox;
      final current = _position ?? _renderedAnchor();
      if (panelBox == null || current == null || _hostSize.isEmpty) return;
      final clamped = _clamp(current, panelBox.size);
      if (_position == clamped) return;
      setState(() {
        _position = clamped;
      });
      widget.onPositionChanged?.call(clamped);
    });
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final nextHostSize = constraints.biggest;
        if (_hostSize != nextHostSize) {
          _hostSize = nextHostSize;
          _scheduleClamp();
        }

        final panel = KeyedSubtree(
          key: _panelKey,
          child: widget.builder(
            context,
            onDragDelta: _moveBy,
            onPanelSizeChanged: _scheduleClamp,
          ),
        );

        return Stack(
          key: _hostKey,
          clipBehavior: Clip.none,
          children: [
            Positioned(
              top: _position?.dy ?? widget.initialTop,
              right: _position?.dx ?? widget.initialRight,
              child: panel,
            ),
          ],
        );
      },
    );
  }
}
