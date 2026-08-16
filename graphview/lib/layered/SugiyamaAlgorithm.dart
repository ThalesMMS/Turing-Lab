part of graphview;

abstract class _SugiyamaAlgorithmState extends LayeredAlgorithmBase {
  @override
  Map<Node, SugiyamaNodeData> get nodeData;

  @override
  Map<Edge, SugiyamaEdgeData> get edgeData;

  List<Node> successorsOf(Node? node);

  List<Node> predecessorsOf(Node? node);

  List<Node> getAdjNodes(Node node, bool downward);

  Node? predecessor(Node? v, bool leftToRight);

  Node? virtualTwinNode(Node node, bool downward);

  int positionOfNode(Node? node);

  int getLayerIndex(Node? node);

  bool isLongEdgeDummy(Node? v);

  Offset getOffset(Graph graph, bool needReverseOrder);

  Offset getPosition(Node node, Offset offset);

  void postStraighten();
}

class SugiyamaAlgorithm extends _SugiyamaAlgorithmState
    with
        SugiyamaLayerAssignment,
        SugiyamaCoordinateAssignment,
        SugiyamaCycleRemoval,
        SugiyamaNodeOrdering {
  final Map<Node, SugiyamaNodeData> _nodeData = {};
  final Map<Edge, SugiyamaEdgeData> _edgeData = {};
  final SugiyamaConfiguration _configuration;

  @override
  EdgeRenderer? renderer;

  SugiyamaAlgorithm(this._configuration) {
    renderer = SugiyamaEdgeRenderer(_nodeData, _edgeData,
        _configuration.bendPointShape, _configuration.addTriangleToEdge);
  }

  @override
  SugiyamaConfiguration get configuration => _configuration;

  @override
  Map<Node, SugiyamaNodeData> get nodeData => _nodeData;

  @override
  Map<Edge, SugiyamaEdgeData> get edgeData => _edgeData;

  @override
  SugiyamaEdgeData createEdgeDataWithBendPoints(List<double> bendPoints) {
    final edgeData = SugiyamaEdgeData();
    edgeData.bendPoints = bendPoints;
    return edgeData;
  }

  @override
  List<double> getBendPointsFromEdgeData(dynamic edgeData) {
    return (edgeData as SugiyamaEdgeData).bendPoints;
  }

  @override
  Size run(Graph? graph, double shiftX, double shiftY) {
    this.graph = copyGraph(graph!);
    reset();
    initSugiyamaData();
    cycleRemoval();
    layerAssignment();
    nodeOrdering(); //expensive operation
    coordinateAssignment(); //expensive operation
    shiftCoordinates(shiftX, shiftY);
    final graphSize = graph.calculateGraphSize();
    denormalize();
    restoreCycle();
    return graphSize;
  }

  void reset() {
    layers.clear();
    stack.clear();
    visited.clear();
    nodeData.clear();
    edgeData.clear();
    nodeCount = 1;
  }

  void initSugiyamaData() {
    for (final node in graph.nodes) {
      node.position = Offset.zero;
      nodeData[node] = SugiyamaNodeData(node.lineType);
    }

    for (final edge in graph.edges) {
      edgeData[edge] = SugiyamaEdgeData();
    }
  }

  @override
  void init(Graph? graph) {
    this.graph = copyGraph(graph!);
    reset();
    initSugiyamaData();
    cycleRemoval();
    layerAssignment();
    nodeOrdering(); //expensive operation
    coordinateAssignment(); //expensive operation
    denormalize();
    restoreCycle();
  }

  @override
  void setDimensions(double width, double height) {}
}
