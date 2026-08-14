//
//  graphview_canvas_models.dart
//  Turing Lab
//
//  Declara os modelos imutáveis utilizados pelo canvas GraphView para
//  transportar metadados do autômato, nós e arestas renderizadas, além de
//  serializações auxiliares. Essas estruturas intermediam a comunicação entre o
//  domínio e a camada de apresentação durante snapshots e exportações.
//
//  Thales Matheus Mendonça Santos - October 2025
//
import 'package:collection/collection.dart';

import '../../../core/models/tm_transition.dart';

/// Metadata describing the current automaton rendered in the GraphView canvas.
class GraphViewAutomatonMetadata {
  static const Object _unset = Object();

  const GraphViewAutomatonMetadata({
    required this.id,
    required this.name,
    required this.alphabet,
    this.tapeAlphabet = const <String>[],
    this.blankSymbol,
    this.tapeCount,
  });

  const GraphViewAutomatonMetadata.empty()
      : id = null,
        name = null,
        alphabet = const <String>[],
        tapeAlphabet = const <String>[],
        blankSymbol = null,
        tapeCount = null;

  final String? id;
  final String? name;
  final List<String> alphabet;
  final List<String> tapeAlphabet;
  final String? blankSymbol;
  final int? tapeCount;

  GraphViewAutomatonMetadata copyWith({
    String? id,
    String? name,
    List<String>? alphabet,
    List<String>? tapeAlphabet,
    Object? blankSymbol = _unset,
    Object? tapeCount = _unset,
  }) {
    return GraphViewAutomatonMetadata(
      id: id ?? this.id,
      name: name ?? this.name,
      alphabet: alphabet ?? this.alphabet,
      tapeAlphabet: tapeAlphabet ?? this.tapeAlphabet,
      blankSymbol:
          blankSymbol == _unset ? this.blankSymbol : blankSymbol as String?,
      tapeCount: tapeCount == _unset ? this.tapeCount : tapeCount as int?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'alphabet': alphabet,
      'tapeAlphabet': tapeAlphabet,
      'blankSymbol': blankSymbol,
      'tapeCount': tapeCount,
    };
  }

  factory GraphViewAutomatonMetadata.fromJson(Map<String, dynamic>? json) {
    if (json == null) {
      return const GraphViewAutomatonMetadata.empty();
    }
    final rawAlphabet = json['alphabet'];
    final alphabet =
        rawAlphabet is List ? rawAlphabet.cast<String>() : const <String>[];
    final rawTapeAlphabet = json['tapeAlphabet'];
    final tapeAlphabet = rawTapeAlphabet is List
        ? rawTapeAlphabet.cast<String>()
        : const <String>[];
    return GraphViewAutomatonMetadata(
      id: json['id'] as String?,
      name: json['name'] as String?,
      alphabet: alphabet,
      tapeAlphabet: tapeAlphabet,
      blankSymbol: json['blankSymbol'] as String?,
      tapeCount: json['tapeCount'] as int?,
    );
  }
}

/// Node rendered inside the GraphView canvas.
class GraphViewCanvasNode {
  const GraphViewCanvasNode({
    required this.id,
    required this.label,
    required this.x,
    required this.y,
    required this.isInitial,
    required this.isAccepting,
  });

  final String id;
  final String label;
  final double x;
  final double y;
  final bool isInitial;
  final bool isAccepting;

  GraphViewCanvasNode copyWith({
    String? id,
    String? label,
    double? x,
    double? y,
    bool? isInitial,
    bool? isAccepting,
  }) {
    return GraphViewCanvasNode(
      id: id ?? this.id,
      label: label ?? this.label,
      x: x ?? this.x,
      y: y ?? this.y,
      isInitial: isInitial ?? this.isInitial,
      isAccepting: isAccepting ?? this.isAccepting,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'label': label,
      'x': x,
      'y': y,
      'isInitial': isInitial,
      'isAccepting': isAccepting,
    };
  }

  factory GraphViewCanvasNode.fromJson(Map<String, dynamic> json) {
    return GraphViewCanvasNode(
      id: json['id'] as String,
      label: (json['label'] as String?) ?? json['id'] as String,
      x: (json['x'] as num?)?.toDouble() ?? 0,
      y: (json['y'] as num?)?.toDouble() ?? 0,
      isInitial: json['isInitial'] as bool? ?? false,
      isAccepting: json['isAccepting'] as bool? ?? false,
    );
  }

  @override
  bool operator ==(Object other) {
    return other is GraphViewCanvasNode &&
        other.id == id &&
        other.label == label &&
        other.x == x &&
        other.y == y &&
        other.isInitial == isInitial &&
        other.isAccepting == isAccepting;
  }

  @override
  int get hashCode => Object.hash(id, label, x, y, isInitial, isAccepting);
}

/// Directed edge rendered inside the GraphView canvas.
class GraphViewCanvasEdge {
  static const Object _unset = Object();

  const GraphViewCanvasEdge({
    required this.id,
    required this.fromStateId,
    required this.toStateId,
    required this.symbols,
    this.lambdaSymbol,
    this.controlPointX,
    this.controlPointY,
    this.readSymbol,
    this.writeSymbol,
    this.direction,
    this.tapeNumber,
    this.popSymbol,
    this.pushSymbol,
    this.pushSymbols,
    this.isLambdaInput,
    this.isLambdaPop,
    this.isLambdaPush,
  });

  final String id;
  final String fromStateId;
  final String toStateId;
  final List<String> symbols;
  final String? lambdaSymbol;
  final double? controlPointX;
  final double? controlPointY;
  final String? readSymbol;
  final String? writeSymbol;
  final TapeDirection? direction;
  final int? tapeNumber;
  final String? popSymbol;
  final String? pushSymbol;
  final List<String>? pushSymbols;
  final bool? isLambdaInput;
  final bool? isLambdaPop;
  final bool? isLambdaPush;

  /// Indica se esta transição é epsilon (para FSA)
  bool get isEpsilonTransition {
    return lambdaSymbol != null && lambdaSymbol!.isNotEmpty;
  }

  String get label {
    final hasPdaMetadata = popSymbol != null ||
        pushSymbol != null ||
        isLambdaInput != null ||
        isLambdaPop != null ||
        isLambdaPush != null;
    if (hasPdaMetadata) {
      final lambdaInput =
          isLambdaInput ?? (readSymbol == null || readSymbol!.isEmpty);
      final lambdaPop =
          isLambdaPop ?? (popSymbol == null || popSymbol!.isEmpty);
      final lambdaPush =
          isLambdaPush ?? (pushSymbol == null || pushSymbol!.isEmpty);
      final read = lambdaInput ? 'λ' : (readSymbol ?? '');
      final pop = lambdaPop ? 'λ' : (popSymbol ?? '');
      final push = lambdaPush ? 'λ' : (pushSymbol ?? '');
      return '$read, $pop/$push';
    }
    if (lambdaSymbol != null && lambdaSymbol!.isNotEmpty) {
      return lambdaSymbol!;
    }
    if (readSymbol != null || writeSymbol != null || direction != null) {
      final read = (readSymbol ?? '').isEmpty ? '∅' : readSymbol!;
      final write = (writeSymbol ?? '').isEmpty ? '∅' : writeSymbol!;
      final resolvedDirection = direction;
      final directionSymbol = switch (resolvedDirection) {
        TapeDirection.left => 'L',
        TapeDirection.right => 'R',
        TapeDirection.stay => 'S',
        null => '',
      };
      final suffix = directionSymbol.isEmpty ? '' : ',$directionSymbol';
      return '$read/$write$suffix';
    }
    final filtered = symbols.where((symbol) => symbol.isNotEmpty).toList();
    return filtered.join(',');
  }

  GraphViewCanvasEdge copyWith({
    String? id,
    String? fromStateId,
    String? toStateId,
    List<String>? symbols,
    String? lambdaSymbol,
    Object? controlPointX = _unset,
    Object? controlPointY = _unset,
    String? readSymbol,
    String? writeSymbol,
    TapeDirection? direction,
    int? tapeNumber,
    String? popSymbol,
    String? pushSymbol,
    List<String>? pushSymbols,
    bool? isLambdaInput,
    bool? isLambdaPop,
    bool? isLambdaPush,
  }) {
    return GraphViewCanvasEdge(
      id: id ?? this.id,
      fromStateId: fromStateId ?? this.fromStateId,
      toStateId: toStateId ?? this.toStateId,
      symbols: symbols ?? this.symbols,
      lambdaSymbol: lambdaSymbol ?? this.lambdaSymbol,
      controlPointX: controlPointX == _unset
          ? this.controlPointX
          : controlPointX as double?,
      controlPointY: controlPointY == _unset
          ? this.controlPointY
          : controlPointY as double?,
      readSymbol: readSymbol ?? this.readSymbol,
      writeSymbol: writeSymbol ?? this.writeSymbol,
      direction: direction ?? this.direction,
      tapeNumber: tapeNumber ?? this.tapeNumber,
      popSymbol: popSymbol ?? this.popSymbol,
      pushSymbol: pushSymbol ?? this.pushSymbol,
      pushSymbols:
          pushSymbols ?? (pushSymbol == null ? this.pushSymbols : null),
      isLambdaInput: isLambdaInput ?? this.isLambdaInput,
      isLambdaPop: isLambdaPop ?? this.isLambdaPop,
      isLambdaPush: isLambdaPush ?? this.isLambdaPush,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'from': fromStateId,
      'to': toStateId,
      'symbols': symbols.join(','),
      'lambdaSymbol': lambdaSymbol,
      'controlPointX': controlPointX,
      'controlPointY': controlPointY,
      'readSymbol': readSymbol,
      'writeSymbol': writeSymbol,
      'direction': direction?.name,
      'tapeNumber': tapeNumber,
      'popSymbol': popSymbol,
      'pushSymbol': pushSymbol,
      'pushSymbols': pushSymbols,
      'isLambdaInput': isLambdaInput,
      'isLambdaPop': isLambdaPop,
      'isLambdaPush': isLambdaPush,
    };
  }

  factory GraphViewCanvasEdge.fromJson(Map<String, dynamic> json) {
    final rawSymbols = json['symbols'];
    final symbols = rawSymbols is String && rawSymbols.isNotEmpty
        ? rawSymbols.split(',')
        : const <String>[];
    return GraphViewCanvasEdge(
      id: json['id'] as String,
      fromStateId: json['from'] as String,
      toStateId: json['to'] as String,
      symbols: symbols,
      lambdaSymbol: json['lambdaSymbol'] as String?,
      controlPointX: (json['controlPointX'] as num?)?.toDouble(),
      controlPointY: (json['controlPointY'] as num?)?.toDouble(),
      readSymbol: json['readSymbol'] as String?,
      writeSymbol: json['writeSymbol'] as String?,
      direction: (json['direction'] as String?) != null
          ? TapeDirection.values.firstWhere(
              (value) => value.name == json['direction'],
              orElse: () => TapeDirection.right,
            )
          : null,
      tapeNumber: json['tapeNumber'] as int?,
      popSymbol: json['popSymbol'] as String?,
      pushSymbol: json['pushSymbol'] as String?,
      pushSymbols: (json['pushSymbols'] as List?)?.cast<String>(),
      isLambdaInput: json['isLambdaInput'] as bool?,
      isLambdaPop: json['isLambdaPop'] as bool?,
      isLambdaPush: json['isLambdaPush'] as bool?,
    );
  }

  @override
  bool operator ==(Object other) {
    return other is GraphViewCanvasEdge &&
        other.id == id &&
        other.fromStateId == fromStateId &&
        other.toStateId == toStateId &&
        const ListEquality<String>().equals(other.symbols, symbols) &&
        other.lambdaSymbol == lambdaSymbol &&
        other.controlPointX == controlPointX &&
        other.controlPointY == controlPointY &&
        other.readSymbol == readSymbol &&
        other.writeSymbol == writeSymbol &&
        other.direction == direction &&
        other.tapeNumber == tapeNumber &&
        other.popSymbol == popSymbol &&
        other.pushSymbol == pushSymbol &&
        const ListEquality<String>().equals(other.pushSymbols, pushSymbols) &&
        other.isLambdaInput == isLambdaInput &&
        other.isLambdaPop == isLambdaPop &&
        other.isLambdaPush == isLambdaPush;
  }

  @override
  int get hashCode => Object.hash(
        id,
        fromStateId,
        toStateId,
        const ListEquality<String>().hash(symbols),
        lambdaSymbol,
        controlPointX,
        controlPointY,
        readSymbol,
        writeSymbol,
        direction,
        tapeNumber,
        popSymbol,
        pushSymbol,
        const ListEquality<String>().hash(pushSymbols),
        isLambdaInput,
        isLambdaPop,
        isLambdaPush,
      );
}

/// Snapshot of nodes, edges and metadata rendered in the GraphView canvas.
class GraphViewAutomatonSnapshot {
  const GraphViewAutomatonSnapshot({
    required this.nodes,
    required this.edges,
    required this.metadata,
  });

  const GraphViewAutomatonSnapshot.empty()
      : nodes = const <GraphViewCanvasNode>[],
        edges = const <GraphViewCanvasEdge>[],
        metadata = const GraphViewAutomatonMetadata.empty();

  final List<GraphViewCanvasNode> nodes;
  final List<GraphViewCanvasEdge> edges;
  final GraphViewAutomatonMetadata metadata;

  GraphViewAutomatonSnapshot copyWith({
    List<GraphViewCanvasNode>? nodes,
    List<GraphViewCanvasEdge>? edges,
    GraphViewAutomatonMetadata? metadata,
  }) {
    return GraphViewAutomatonSnapshot(
      nodes: nodes ?? this.nodes,
      edges: edges ?? this.edges,
      metadata: metadata ?? this.metadata,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'nodes': nodes.map((node) => node.toJson()).toList(),
      'edges': edges.map((edge) => edge.toJson()).toList(),
      'metadata': metadata.toJson(),
    };
  }

  factory GraphViewAutomatonSnapshot.fromJson(Map<String, dynamic> json) {
    final rawNodes = (json['nodes'] as List?)?.cast<Map>() ?? const [];
    final rawEdges = (json['edges'] as List?)?.cast<Map>() ?? const [];
    return GraphViewAutomatonSnapshot(
      nodes: rawNodes
          .map(
            (node) =>
                GraphViewCanvasNode.fromJson(node.cast<String, dynamic>()),
          )
          .toList(),
      edges: rawEdges
          .map(
            (edge) =>
                GraphViewCanvasEdge.fromJson(edge.cast<String, dynamic>()),
          )
          .toList(),
      metadata: GraphViewAutomatonMetadata.fromJson(
        (json['metadata'] as Map?)?.cast<String, dynamic>(),
      ),
    );
  }

  @override
  bool operator ==(Object other) {
    return other is GraphViewAutomatonSnapshot &&
        const ListEquality<GraphViewCanvasNode>().equals(nodes, other.nodes) &&
        const ListEquality<GraphViewCanvasEdge>().equals(edges, other.edges) &&
        metadata.id == other.metadata.id &&
        metadata.name == other.metadata.name &&
        const ListEquality<String>().equals(
          metadata.alphabet,
          other.metadata.alphabet,
        ) &&
        const ListEquality<String>().equals(
          metadata.tapeAlphabet,
          other.metadata.tapeAlphabet,
        ) &&
        metadata.blankSymbol == other.metadata.blankSymbol &&
        metadata.tapeCount == other.metadata.tapeCount;
  }

  @override
  int get hashCode => Object.hash(
        const ListEquality<GraphViewCanvasNode>().hash(nodes),
        const ListEquality<GraphViewCanvasEdge>().hash(edges),
        metadata.id,
        metadata.name,
        const ListEquality<String>().hash(metadata.alphabet),
        const ListEquality<String>().hash(metadata.tapeAlphabet),
        metadata.blankSymbol,
        metadata.tapeCount,
      );
}
