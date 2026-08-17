part of graphview;

class GraphView extends StatefulWidget {
  final Graph graph;
  final Algorithm algorithm;
  final Paint? paint;
  final NodeWidgetBuilder builder;
  final bool animated;
  final GraphViewController? controller;
  final bool _isBuilder;

  final Duration? panAnimationDuration;
  final Duration? toggleAnimationDuration;
  final ValueKey? initialNode;
  final bool autoZoomToFit;
  final GraphChildDelegate delegate;
  final bool centerGraph;
  final NodeDraggingConfiguration? nodeDraggingConfig;
  final double minScale;
  final double maxScale;

  GraphView({
    Key? key,
    required this.graph,
    required this.algorithm,
    this.paint,
    required this.builder,
    this.animated = true,
    this.controller,
    this.toggleAnimationDuration,
    this.centerGraph = false,
    this.nodeDraggingConfig,
    this.minScale = 0.01,
    this.maxScale = 10,
  })  : _isBuilder = false,
        autoZoomToFit = false,
        initialNode = null,
        panAnimationDuration = null,
        delegate = GraphChildDelegate(
            graph: graph,
            algorithm: algorithm,
            builder: builder,
            controller: null,
            nodeDraggingConfig: nodeDraggingConfig),
        assert(minScale > 0),
        assert(maxScale >= minScale),
        super(key: key);

  GraphView.builder({
    Key? key,
    required this.graph,
    required this.algorithm,
    this.paint,
    required this.builder,
    this.controller,
    this.animated = true,
    this.initialNode,
    this.autoZoomToFit = false,
    this.panAnimationDuration,
    this.toggleAnimationDuration,
    this.centerGraph = false,
    this.nodeDraggingConfig,
    this.minScale = 0.01,
    this.maxScale = 10,
  })  : _isBuilder = true,
        delegate = GraphChildDelegate(
            graph: graph,
            algorithm: algorithm,
            builder: builder,
            controller: controller,
            centerGraph: centerGraph,
            nodeDraggingConfig: nodeDraggingConfig),
        assert(!(autoZoomToFit && initialNode != null),
            'Cannot use both autoZoomToFit and initialNode together. Choose one.'),
        assert(minScale > 0),
        assert(maxScale >= minScale),
        super(key: key);

  @override
  _GraphViewState createState() => _GraphViewState();
}

class _GraphViewState extends State<GraphView> with TickerProviderStateMixin {
  late TransformationController _transformationController;
  late final AnimationController _panController;
  late final AnimationController _nodeController;
  Animation<Matrix4>? _panAnimation;

  @override
  void initState() {
    super.initState();

    _transformationController = widget.controller?.transformationController ??
        TransformationController(_resetMatrix());

    _panController = AnimationController(
      vsync: this,
      duration:
          widget.panAnimationDuration ?? const Duration(milliseconds: 600),
    );

    _nodeController = AnimationController(
      vsync: this,
      duration:
          widget.toggleAnimationDuration ?? const Duration(milliseconds: 600),
    );

    widget.controller?._attach(this);

    if (widget.autoZoomToFit || widget.initialNode != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (widget.autoZoomToFit) {
          zoomToFit();
        } else if (widget.initialNode != null) {
          jumpToNodeUsingKey(widget.initialNode!, false);
        }
      });
    }
  }

  @override
  void didUpdateWidget(covariant GraphView oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (oldWidget.controller == widget.controller) return;

    final previousController = oldWidget.controller;
    final nextController = widget.controller;
    final previousTransformationController = _transformationController;
    final previousMatrix = previousTransformationController.value.clone();
    final nextTransformationController =
        nextController?.transformationController;

    previousController?._detach(this);

    _transformationController = nextTransformationController ??
        TransformationController(previousMatrix);
    if (nextTransformationController != null) {
      nextTransformationController.value = previousMatrix;
    }
    nextController?._attach(this);

    // Same single-owner rule as dispose(): a previous external controller
    // keeps ownership of its TransformationController.
    final shouldDisposePrevious = previousController == null;
    if (shouldDisposePrevious &&
        !identical(
          previousTransformationController,
          _transformationController,
        )) {
      previousTransformationController.dispose();
    }
  }

  @override
  void dispose() {
    widget.controller?._detach(this);
    _panController.dispose();
    _nodeController.dispose();
    // Only dispose a TransformationController this State created itself. An
    // external GraphViewController owns its own controller and may outlive
    // this view; disposing it here double-disposes when the owner cleans up.
    if (widget.controller == null) {
      _transformationController.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final view = GraphViewWidget(
      paint: widget.paint,
      nodeAnimationController: _nodeController,
      enableAnimation: widget.animated,
      delegate: widget.delegate,
    );

    if (widget._isBuilder) {
      return InteractiveViewer.builder(
          transformationController: _transformationController,
          boundaryMargin: EdgeInsets.all(double.infinity),
          minScale: widget.minScale,
          maxScale: widget.maxScale,
          builder: (context, viewport) {
            return view;
          });
    }

    return view;
  }

  void jumpToNodeUsingKey(ValueKey key, bool animated) {
    final node = widget.graph.nodes.firstWhereOrNull((n) => n.key == key);
    if (node == null) return;

    jumpToNode(node, animated);
  }

  void jumpToNode(Node node, bool animated) {
    final nodeCenter = Offset(
        node.position.dx + node.width / 2, node.position.dy + node.height / 2);

    jumpToOffset(nodeCenter, animated);
  }

  void jumpToOffset(Offset offset, bool animated) {
    final renderBox = context.findRenderObject() as RenderBox?;
    if (renderBox == null) return;

    final viewport = renderBox.size;
    final center = Offset(viewport.width / 2, viewport.height / 2);

    final currentScale = _transformationController.value.getMaxScaleOnAxis();

    final scaledNodeCenter = offset * currentScale;
    final translation = center - scaledNodeCenter;

    final target = Matrix4.identity()
      // ignore: deprecated_member_use
      ..translate(translation.dx, translation.dy)
      // ignore: deprecated_member_use
      ..scale(currentScale);

    if (animated) {
      animateToMatrix(target);
    } else {
      _transformationController.value = target;
    }
  }

  Matrix4 _resetMatrix() {
    final scale = 1.0.clamp(widget.minScale, widget.maxScale).toDouble();
    return Matrix4.diagonal3Values(scale, scale, 1);
  }

  void resetView() => animateToMatrix(_resetMatrix());

  void zoomToFit() {
    var graph = widget.delegate.getVisibleGraphOnly();
    final renderBox = context.findRenderObject() as RenderBox?;
    if (renderBox == null) return;

    final vp = renderBox.size;
    final bounds = graph.calculateGraphBounds();

    const paddingFactor = 0.95;
    final scaleX = (vp.width / bounds.width) * paddingFactor;
    final scaleY = (vp.height / bounds.height) * paddingFactor;
    final scale =
        min(scaleX, scaleY).clamp(widget.minScale, widget.maxScale).toDouble();

    final scaledWidth = bounds.width * scale;
    final scaledHeight = bounds.height * scale;

    final centerOffset = Offset(
        (vp.width - scaledWidth) * 0.5 - bounds.left * scale,
        (vp.height - scaledHeight) * 0.5 - bounds.top * scale);

    final target = Matrix4.identity()
      // ignore: deprecated_member_use
      ..translate(centerOffset.dx, centerOffset.dy)
      // ignore: deprecated_member_use
      ..scale(scale);
    animateToMatrix(target);
  }

  void animateToMatrix(Matrix4 target) {
    _panController.reset();
    _panAnimation = Matrix4Tween(
            begin: _transformationController.value, end: target)
        .animate(CurvedAnimation(parent: _panController, curve: Curves.linear));
    _panAnimation!.addListener(_onPanTick);
    _panController.forward();
  }

  void _onPanTick() {
    if (_panAnimation == null) return;
    _transformationController.value = _panAnimation!.value;
    if (!_panController.isAnimating) {
      _panAnimation!.removeListener(_onPanTick);
      _panAnimation = null;
      _panController.reset();
    }
  }

  void forceRecalculation() {
    // Invalidate the delegate's cached graph
    widget.delegate._needsRecalculation = true;

    setState(() {});
  }
}
