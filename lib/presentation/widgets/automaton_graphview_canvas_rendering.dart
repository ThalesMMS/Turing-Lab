part of 'automaton_graphview_canvas.dart';

class _TransitionEditChoice {
  const _TransitionEditChoice._({required this.createNew, this.edge});

  const _TransitionEditChoice.edit(GraphViewCanvasEdge edge)
      : this._(createNew: false, edge: edge);

  const _TransitionEditChoice.createNew() : this._(createNew: true);

  final bool createNew;
  final GraphViewCanvasEdge? edge;
}

class _CanvasEdgeHit {
  const _CanvasEdgeHit({required this.edge, required this.distance});

  final GraphViewCanvasEdge edge;
  final double distance;
}

class _TransitionPreviewPainter extends CustomPainter {
  const _TransitionPreviewPainter({
    required this.start,
    required this.end,
    required this.color,
  });

  final Offset start;
  final Offset end;
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final delta = end - start;
    final distance = delta.distance;
    if (distance < 1) {
      return;
    }
    final direction = delta / distance;
    final paint = Paint()
      ..color = color.withValues(alpha: 0.8)
      ..strokeWidth = 2
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;
    const dashLength = 8.0;
    const gapLength = 5.0;
    for (var offset = 0.0;
        offset < distance;
        offset += dashLength + gapLength) {
      final dashStart = start + direction * offset;
      final dashEnd =
          start + direction * math.min(offset + dashLength, distance);
      canvas.drawLine(dashStart, dashEnd, paint);
    }

    final normal = Offset(-direction.dy, direction.dx);
    final arrow = Path()
      ..moveTo(end.dx, end.dy)
      ..lineTo(
        end.dx - direction.dx * 12 + normal.dx * 6,
        end.dy - direction.dy * 12 + normal.dy * 6,
      )
      ..moveTo(end.dx, end.dy)
      ..lineTo(
        end.dx - direction.dx * 12 - normal.dx * 6,
        end.dy - direction.dy * 12 - normal.dy * 6,
      );
    canvas.drawPath(arrow, paint);
  }

  @override
  bool shouldRepaint(covariant _TransitionPreviewPainter oldDelegate) {
    return oldDelegate.start != start ||
        oldDelegate.end != end ||
        oldDelegate.color != color;
  }
}

class _GraphViewTransitionOverlayState {
  const _GraphViewTransitionOverlayState({required this.data});

  final AutomatonTransitionOverlayData data;

  _GraphViewTransitionOverlayState copyWith({
    AutomatonTransitionOverlayData? data,
  }) {
    return _GraphViewTransitionOverlayState(
      data: data ?? this.data,
    );
  }
}

class _AutomatonGraphSugiyamaAlgorithm extends SugiyamaAlgorithm {
  _AutomatonGraphSugiyamaAlgorithm({
    required SugiyamaConfiguration configuration,
  }) : super(configuration);

  @override
  Size run(Graph? graph, double shiftX, double shiftY) {
    if (graph == null || graph.nodes.isEmpty) {
      return Size.zero;
    }

    var minX = double.infinity;
    var minY = double.infinity;
    var maxX = double.negativeInfinity;
    var maxY = double.negativeInfinity;

    for (final node in graph.nodes) {
      final position = node.position;

      minX = math.min(minX, position.dx);
      minY = math.min(minY, position.dy);
      maxX = math.max(maxX, position.dx + node.width);
      maxY = math.max(maxY, position.dy + node.height);
    }

    if (minX == double.infinity || minY == double.infinity) {
      return Size.zero;
    }

    final width = (maxX - minX).clamp(0.0, double.infinity) + _kNodeDiameter;
    final height = (maxY - minY).clamp(0.0, double.infinity) + _kNodeDiameter;

    return Size(width, height);
  }

  @override
  void init(Graph? graph) {}

  @override
  void setDimensions(double width, double height) {}
}

class _AutomatonGraphNode extends StatefulWidget {
  const _AutomatonGraphNode({
    required this.nodeId,
    required this.label,
    required this.isInitial,
    required this.isAccepting,
    required this.highlightListenable,
    required this.isTransitionSource,
    required this.isSelected,
    required this.motionPreset,
  });

  final String nodeId;
  final String label;
  final bool isInitial;
  final bool isAccepting;
  final ValueListenable<SimulationHighlight> highlightListenable;
  final bool isTransitionSource;
  final bool isSelected;
  final _CanvasMotionPreset motionPreset;

  @override
  State<_AutomatonGraphNode> createState() => _AutomatonGraphNodeState();
}

class _AutomatonGraphNodeState extends State<_AutomatonGraphNode> {
  late bool _isHighlighted;

  @override
  void initState() {
    super.initState();
    _isHighlighted = _resolveHighlight();
    widget.highlightListenable.addListener(_handleHighlightChanged);
  }

  @override
  void didUpdateWidget(covariant _AutomatonGraphNode oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.highlightListenable != widget.highlightListenable) {
      oldWidget.highlightListenable.removeListener(_handleHighlightChanged);
      widget.highlightListenable.addListener(_handleHighlightChanged);
    }
    final nextHighlight = _resolveHighlight();
    if (nextHighlight != _isHighlighted) {
      _isHighlighted = nextHighlight;
    }
  }

  @override
  void dispose() {
    widget.highlightListenable.removeListener(_handleHighlightChanged);
    super.dispose();
  }

  bool _resolveHighlight() =>
      widget.highlightListenable.value.stateIds.contains(widget.nodeId);

  void _handleHighlightChanged() {
    final nextHighlight = _resolveHighlight();
    if (nextHighlight == _isHighlighted) {
      return;
    }
    setState(() {
      _isHighlighted = nextHighlight;
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final borderColor = _isHighlighted
        ? theme.colorScheme.primary
        : widget.isTransitionSource
            ? theme.colorScheme.tertiary
            : widget.isSelected
                ? theme.colorScheme.secondary
                : theme.colorScheme.outline;
    final backgroundColor = _isHighlighted
        ? theme.colorScheme.primaryContainer
        : widget.isTransitionSource
            ? theme.colorScheme.tertiaryContainer
            : widget.isSelected
                ? theme.colorScheme.secondaryContainer
                : theme.colorScheme.surface;

    final badgeColor = theme.colorScheme.primary;

    return AnimatedScale(
      duration: widget.motionPreset.highlightDuration,
      curve: widget.motionPreset.highlightCurve,
      scale: _isHighlighted ? widget.motionPreset.highlightScale : 1.0,
      child: SizedBox(
        width: _kNodeDiameter,
        height: _kNodeDiameter,
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            Positioned.fill(
              child: AnimatedContainer(
                duration: widget.motionPreset.highlightDuration,
                curve: widget.motionPreset.highlightCurve,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: backgroundColor,
                  border: Border.all(color: borderColor, width: 3),
                ),
                child: Center(
                  child: Padding(
                    padding: const EdgeInsets.all(4),
                    child: FittedBox(
                      fit: BoxFit.scaleDown,
                      child: Text(
                        widget.label,
                        style: theme.textTheme.titleMedium,
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ),
                ),
              ),
            ),
            if (widget.isInitial)
              Positioned(
                left: -_kInitialArrowSize.width + 1,
                top: _kNodeRadius - (_kInitialArrowSize.height / 2),
                child: CustomPaint(
                  size: _kInitialArrowSize,
                  painter: _InitialStateArrowPainter(color: borderColor),
                ),
              ),
            if (widget.isAccepting)
              Positioned.fill(
                child: Padding(
                  padding: const EdgeInsets.all(8),
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(color: badgeColor, width: 2),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _InitialStateArrowPainter extends CustomPainter {
  const _InitialStateArrowPainter({required this.color});

  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;

    final path = Path()
      ..moveTo(0, 0)
      ..lineTo(size.width, size.height / 2)
      ..lineTo(0, size.height)
      ..close();
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant _InitialStateArrowPainter oldDelegate) {
    return oldDelegate.color != color;
  }
}

typedef _NodeHitTester = GraphViewCanvasNode? Function(Offset globalPosition);
typedef _ToolResolver = AutomatonCanvasTool Function();

class _NodePanGestureRecognizer extends PanGestureRecognizer {
  _NodePanGestureRecognizer({
    required this.hitTester,
    required this.toolResolver,
    this.onDragReleased,
  });

  final _NodeHitTester hitTester;
  final _ToolResolver toolResolver;
  final VoidCallback? onDragReleased;

  int? _activePointer;

  /// Yields a pending one-pointer drag so an ancestor can recognize pinch.
  void cancelForAdditionalPointer(int pointer) {
    final activePointer = _activePointer;
    if (activePointer == null || activePointer == pointer) {
      return;
    }
    resolvePointer(activePointer, GestureDisposition.rejected);
  }

  @override
  void addAllowedPointer(PointerDownEvent event) {
    _debugNodePan(
      '[NodePanRecognizer] addAllowedPointer pointer ${event.pointer} '
      'tool=${toolResolver().name} active=$_activePointer '
      'position=${event.position} dragStart=$dragStartBehavior',
    );
    if (_activePointer != null) {
      _debugNodePan('[NodePanRecognizer] pointer already active -> ignore');
      return;
    }
    final tool = toolResolver();
    if (tool == AutomatonCanvasTool.transition ||
        tool == AutomatonCanvasTool.addState) {
      _debugNodePan('[NodePanRecognizer] tool ${tool.name} -> ignore');
      return;
    }
    final node = hitTester(event.position);
    if (node == null) {
      _debugNodePan('[NodePanRecognizer] no node hit -> ignore');
      return;
    }
    _activePointer = event.pointer;
    _debugNodePan(
      '[NodePanRecognizer] tracking pointer ${event.pointer} '
      'for node ${node.id}',
    );
    super.addAllowedPointer(event);
  }

  @override
  bool hasSufficientGlobalDistanceToAccept(
    PointerDeviceKind pointerDeviceKind,
    double? deviceTouchSlop,
  ) {
    return globalDistanceMoved.abs() >
        computeHitSlop(pointerDeviceKind, gestureSettings);
  }

  @override
  void rejectGesture(int pointer) {
    _debugNodePan('[NodePanRecognizer] rejectGesture pointer=$pointer');
    if (pointer == _activePointer) {
      _activePointer = null;
      onDragReleased?.call();
    }
    super.rejectGesture(pointer);
  }

  @override
  void didStopTrackingLastPointer(int pointer) {
    _debugNodePan('[NodePanRecognizer] didStopTracking pointer=$pointer');
    if (pointer == _activePointer) {
      _activePointer = null;
      onDragReleased?.call();
    }
    super.didStopTrackingLastPointer(pointer);
  }
}

const bool _enablePanDebug = false;

void _debugNodePan(String message) {
  if (kDebugMode && _enablePanDebug) {
    debugPrint(message);
  }
}
