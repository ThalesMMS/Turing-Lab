//
//  graphview_canvas_models.dart
//  Turing Lab
//
//  Declares the immutable models used by the GraphView canvas to carry
//  automaton metadata, rendered nodes and edges, plus helper serializations.
//  These structures mediate communication between the domain and the
//  presentation layer during snapshots and exports.
//
//  Thales Matheus Mendonça Santos - October 2025
//
import 'package:collection/collection.dart';

import '../../../core/models/pda_transition.dart';
import '../../../core/models/tm_transition.dart';
import '../../../core/transducers/transducer_symbols.dart';

/// Metadata describing the current automaton rendered in the GraphView canvas.
class GraphViewAutomatonMetadata {
  static const Object _unset = Object();

  const GraphViewAutomatonMetadata({
    required this.id,
    required this.name,
    required this.alphabet,
    this.outputAlphabet = const <String>[],
    this.stackAlphabet = const <String>[],
    this.initialStackSymbol,
    this.tapeAlphabet = const <String>[],
    this.blankSymbol,
    this.tapeCount,
  });

  const GraphViewAutomatonMetadata.empty()
      : id = null,
        name = null,
        alphabet = const <String>[],
        outputAlphabet = const <String>[],
        stackAlphabet = const <String>[],
        initialStackSymbol = null,
        tapeAlphabet = const <String>[],
        blankSymbol = null,
        tapeCount = null;

  final String? id;
  final String? name;
  final List<String> alphabet;
  final List<String> outputAlphabet;
  final List<String> stackAlphabet;
  final String? initialStackSymbol;
  final List<String> tapeAlphabet;
  final String? blankSymbol;
  final int? tapeCount;

  GraphViewAutomatonMetadata copyWith({
    String? id,
    String? name,
    List<String>? alphabet,
    List<String>? outputAlphabet,
    List<String>? stackAlphabet,
    Object? initialStackSymbol = _unset,
    List<String>? tapeAlphabet,
    Object? blankSymbol = _unset,
    Object? tapeCount = _unset,
  }) {
    return GraphViewAutomatonMetadata(
      id: id ?? this.id,
      name: name ?? this.name,
      alphabet: alphabet ?? this.alphabet,
      outputAlphabet: outputAlphabet ?? this.outputAlphabet,
      stackAlphabet: stackAlphabet ?? this.stackAlphabet,
      initialStackSymbol: initialStackSymbol == _unset
          ? this.initialStackSymbol
          : initialStackSymbol as String?,
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
      'outputAlphabet': outputAlphabet,
      'stackAlphabet': stackAlphabet,
      'initialStackSymbol': initialStackSymbol,
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
    final rawStackAlphabet = json['stackAlphabet'];
    final rawOutputAlphabet = json['outputAlphabet'];
    final outputAlphabet = rawOutputAlphabet is List
        ? rawOutputAlphabet.cast<String>()
        : const <String>[];
    final stackAlphabet = rawStackAlphabet is List
        ? rawStackAlphabet.cast<String>()
        : const <String>[];
    final rawTapeAlphabet = json['tapeAlphabet'];
    final tapeAlphabet = rawTapeAlphabet is List
        ? rawTapeAlphabet.cast<String>()
        : const <String>[];
    return GraphViewAutomatonMetadata(
      id: json['id'] as String?,
      name: json['name'] as String?,
      alphabet: alphabet,
      outputAlphabet: outputAlphabet,
      stackAlphabet: stackAlphabet,
      initialStackSymbol: json['initialStackSymbol'] as String?,
      tapeAlphabet: tapeAlphabet,
      blankSymbol: json['blankSymbol'] as String?,
      tapeCount: json['tapeCount'] as int?,
    );
  }
}

/// Node rendered inside the GraphView canvas.
class GraphViewCanvasNode {
  static const Object _unset = Object();

  const GraphViewCanvasNode({
    required this.id,
    required this.label,
    required this.x,
    required this.y,
    required this.isInitial,
    required this.isAccepting,
    this.secondaryLabel,
    this.transducerOutput,
  });

  final String id;
  final String label;
  final double x;
  final double y;
  final bool isInitial;
  final bool isAccepting;
  final String? secondaryLabel;
  final TransducerOutputWord? transducerOutput;

  GraphViewCanvasNode copyWith({
    String? id,
    String? label,
    double? x,
    double? y,
    bool? isInitial,
    bool? isAccepting,
    Object? secondaryLabel = _unset,
    Object? transducerOutput = _unset,
  }) {
    return GraphViewCanvasNode(
      id: id ?? this.id,
      label: label ?? this.label,
      x: x ?? this.x,
      y: y ?? this.y,
      isInitial: isInitial ?? this.isInitial,
      isAccepting: isAccepting ?? this.isAccepting,
      secondaryLabel: secondaryLabel == _unset
          ? this.secondaryLabel
          : secondaryLabel as String?,
      transducerOutput: transducerOutput == _unset
          ? this.transducerOutput
          : transducerOutput as TransducerOutputWord?,
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
      'secondaryLabel': secondaryLabel,
      'transducerOutput': transducerOutput?.values,
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
      secondaryLabel: json['secondaryLabel'] as String?,
      transducerOutput: switch (json['transducerOutput']) {
        final List<dynamic> values =>
          TransducerOutputWord.fromValues(values.cast<String>()),
        _ => null,
      },
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
        other.isAccepting == isAccepting &&
        other.secondaryLabel == secondaryLabel &&
        other.transducerOutput == transducerOutput;
  }

  @override
  int get hashCode => Object.hash(
        id,
        label,
        x,
        y,
        isInitial,
        isAccepting,
        secondaryLabel,
        transducerOutput,
      );
}

/// Immutable TM operation vectors stored as one atomic canvas payload.
final class TmGraphViewOperationVectors {
  factory TmGraphViewOperationVectors({
    required Iterable<String> readSymbols,
    required Iterable<String> writeSymbols,
    required Iterable<TapeDirection> directions,
  }) {
    final reads = List<String>.unmodifiable(readSymbols);
    final writes = List<String>.unmodifiable(writeSymbols);
    final moves = List<TapeDirection>.unmodifiable(directions);
    if (reads.isEmpty ||
        reads.length != writes.length ||
        reads.length != moves.length) {
      throw ArgumentError.value(
        [reads.length, writes.length, moves.length],
        'operationVectors',
        'TM operation vectors must have the same non-zero length.',
      );
    }
    return TmGraphViewOperationVectors._(reads, writes, moves);
  }

  const TmGraphViewOperationVectors._(
    this.readSymbols,
    this.writeSymbols,
    this.directions,
  );

  final List<String> readSymbols;
  final List<String> writeSymbols;
  final List<TapeDirection> directions;

  @override
  bool operator ==(Object other) {
    return other is TmGraphViewOperationVectors &&
        const ListEquality<String>().equals(other.readSymbols, readSymbols) &&
        const ListEquality<String>().equals(other.writeSymbols, writeSymbols) &&
        const ListEquality<TapeDirection>()
            .equals(other.directions, directions);
  }

  @override
  int get hashCode => Object.hash(
        const ListEquality<String>().hash(readSymbols),
        const ListEquality<String>().hash(writeSymbols),
        const ListEquality<TapeDirection>().hash(directions),
      );
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
    this.tmOperations,
    this.tapeNumber,
    this.popSymbol,
    this.pushSymbol,
    this.pushSymbols,
    this.isLambdaInput,
    this.isLambdaPop,
    this.isLambdaPush,
    this.transducerOutput,
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
  final TmGraphViewOperationVectors? tmOperations;

  List<String>? get tmReadSymbols => tmOperations?.readSymbols;
  List<String>? get tmWriteSymbols => tmOperations?.writeSymbols;
  List<TapeDirection>? get tmDirections => tmOperations?.directions;
  final int? tapeNumber;
  final String? popSymbol;
  final String? pushSymbol;
  final List<String>? pushSymbols;
  final bool? isLambdaInput;
  final bool? isLambdaPop;
  final bool? isLambdaPush;
  final TransducerOutputWord? transducerOutput;

  /// Whether this transition is an epsilon transition (for FSA).
  bool get isEpsilonTransition {
    return lambdaSymbol != null && lambdaSymbol!.isNotEmpty;
  }

  String get label {
    if (transducerOutput != null) {
      final input = readSymbol ?? symbols.join(',');
      final output = transducerOutput!.symbols.isEmpty
          ? '[]'
          : transducerOutput!.values.join(' · ');
      return '$input / $output';
    }
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
      return PDATransition.formatLabel(
        inputSymbol: readSymbol ?? '',
        popSymbol: popSymbol ?? '',
        pushSymbol: pushSymbol ?? '',
        isLambdaInput: lambdaInput,
        isLambdaPop: lambdaPop,
        isLambdaPush: lambdaPush,
      );
    }
    if (lambdaSymbol != null && lambdaSymbol!.isNotEmpty) {
      return lambdaSymbol!;
    }
    if (tmReadSymbols != null ||
        tmWriteSymbols != null ||
        tmDirections != null) {
      final reads = tmReadSymbols ?? const <String>[];
      final writes = tmWriteSymbols ?? const <String>[];
      final moves = tmDirections ?? const <TapeDirection>[];
      if (reads.length == writes.length && reads.length == moves.length) {
        return List<String>.generate(
          reads.length,
          (index) =>
              'T${index + 1}: ${reads[index]}/${writes[index]},${moves[index].symbol}',
          growable: false,
        ).join(' | ');
      }
    }
    if (readSymbol != null || writeSymbol != null || direction != null) {
      return TMTransition.formatLabel(
        readSymbol: readSymbol ?? '',
        writeSymbol: writeSymbol ?? '',
        direction: direction,
      );
    }
    final filtered = symbols.where((symbol) => symbol.isNotEmpty).toList();
    return filtered.join(',');
  }

  GraphViewCanvasEdge copyWith({
    String? id,
    String? fromStateId,
    String? toStateId,
    List<String>? symbols,
    Object? lambdaSymbol = _unset,
    Object? controlPointX = _unset,
    Object? controlPointY = _unset,
    Object? readSymbol = _unset,
    Object? writeSymbol = _unset,
    Object? direction = _unset,
    Object? tmReadSymbols = _unset,
    Object? tmWriteSymbols = _unset,
    Object? tmDirections = _unset,
    Object? tapeNumber = _unset,
    Object? popSymbol = _unset,
    Object? pushSymbol = _unset,
    Object? pushSymbols = _unset,
    Object? isLambdaInput = _unset,
    Object? isLambdaPop = _unset,
    Object? isLambdaPush = _unset,
    Object? transducerOutput = _unset,
  }) {
    final resolvedPushSymbols = pushSymbols != _unset
        ? pushSymbols as List<String>?
        : pushSymbol == _unset
            ? this.pushSymbols
            : null;
    final resolvedReads = tmReadSymbols == _unset
        ? this.tmReadSymbols
        : tmReadSymbols as List<String>?;
    final resolvedWrites = tmWriteSymbols == _unset
        ? this.tmWriteSymbols
        : tmWriteSymbols as List<String>?;
    final resolvedDirections = tmDirections == _unset
        ? this.tmDirections
        : tmDirections as List<TapeDirection>?;
    final hasAnyTmVector = resolvedReads != null ||
        resolvedWrites != null ||
        resolvedDirections != null;
    if (hasAnyTmVector &&
        (resolvedReads == null ||
            resolvedWrites == null ||
            resolvedDirections == null)) {
      throw ArgumentError(
        'TM read, write, and direction vectors must be changed together.',
      );
    }
    return GraphViewCanvasEdge(
      id: id ?? this.id,
      fromStateId: fromStateId ?? this.fromStateId,
      toStateId: toStateId ?? this.toStateId,
      symbols: symbols ?? this.symbols,
      lambdaSymbol:
          lambdaSymbol == _unset ? this.lambdaSymbol : lambdaSymbol as String?,
      controlPointX: controlPointX == _unset
          ? this.controlPointX
          : controlPointX as double?,
      controlPointY: controlPointY == _unset
          ? this.controlPointY
          : controlPointY as double?,
      readSymbol:
          readSymbol == _unset ? this.readSymbol : readSymbol as String?,
      writeSymbol:
          writeSymbol == _unset ? this.writeSymbol : writeSymbol as String?,
      direction:
          direction == _unset ? this.direction : direction as TapeDirection?,
      tmOperations: hasAnyTmVector
          ? TmGraphViewOperationVectors(
              readSymbols: resolvedReads!,
              writeSymbols: resolvedWrites!,
              directions: resolvedDirections!,
            )
          : null,
      tapeNumber: tapeNumber == _unset ? this.tapeNumber : tapeNumber as int?,
      popSymbol: popSymbol == _unset ? this.popSymbol : popSymbol as String?,
      pushSymbol:
          pushSymbol == _unset ? this.pushSymbol : pushSymbol as String?,
      pushSymbols: resolvedPushSymbols,
      isLambdaInput:
          isLambdaInput == _unset ? this.isLambdaInput : isLambdaInput as bool?,
      isLambdaPop:
          isLambdaPop == _unset ? this.isLambdaPop : isLambdaPop as bool?,
      isLambdaPush:
          isLambdaPush == _unset ? this.isLambdaPush : isLambdaPush as bool?,
      transducerOutput: transducerOutput == _unset
          ? this.transducerOutput
          : transducerOutput as TransducerOutputWord?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'from': fromStateId,
      'to': toStateId,
      'symbols': symbols,
      'lambdaSymbol': lambdaSymbol,
      'controlPointX': controlPointX,
      'controlPointY': controlPointY,
      'readSymbol': readSymbol,
      'writeSymbol': writeSymbol,
      'direction': direction?.name,
      'tmReadSymbols': tmReadSymbols,
      'tmWriteSymbols': tmWriteSymbols,
      'tmDirections': tmDirections?.map((value) => value.name).toList(),
      'tapeNumber': tapeNumber,
      'popSymbol': popSymbol,
      'pushSymbol': pushSymbol,
      'pushSymbols': pushSymbols,
      'isLambdaInput': isLambdaInput,
      'isLambdaPop': isLambdaPop,
      'isLambdaPush': isLambdaPush,
      'transducerOutput': transducerOutput?.values,
    };
  }

  factory GraphViewCanvasEdge.fromJson(Map<String, dynamic> json) {
    final rawSymbols = json['symbols'];
    final symbols = rawSymbols is List
        ? rawSymbols.cast<String>()
        : rawSymbols is String && rawSymbols.isNotEmpty
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
      tmOperations: _tmOperationsFromJson(json),
      tapeNumber: json['tapeNumber'] as int?,
      popSymbol: json['popSymbol'] as String?,
      pushSymbol: json['pushSymbol'] as String?,
      pushSymbols: (json['pushSymbols'] as List?)?.cast<String>(),
      isLambdaInput: json['isLambdaInput'] as bool?,
      isLambdaPop: json['isLambdaPop'] as bool?,
      isLambdaPush: json['isLambdaPush'] as bool?,
      transducerOutput: json['transducerOutput'] is List
          ? TransducerOutputWord.fromValues(
              (json['transducerOutput'] as List).cast<String>(),
            )
          : null,
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
        const ListEquality<String>()
            .equals(other.tmReadSymbols, tmReadSymbols) &&
        const ListEquality<String>()
            .equals(other.tmWriteSymbols, tmWriteSymbols) &&
        const ListEquality<TapeDirection>()
            .equals(other.tmDirections, tmDirections) &&
        other.tapeNumber == tapeNumber &&
        other.popSymbol == popSymbol &&
        other.pushSymbol == pushSymbol &&
        const ListEquality<String>().equals(other.pushSymbols, pushSymbols) &&
        other.isLambdaInput == isLambdaInput &&
        other.isLambdaPop == isLambdaPop &&
        other.isLambdaPush == isLambdaPush &&
        other.transducerOutput == transducerOutput;
  }

  @override
  int get hashCode => Object.hashAll([
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
        tmOperations,
        tapeNumber,
        popSymbol,
        pushSymbol,
        const ListEquality<String>().hash(pushSymbols),
        isLambdaInput,
        isLambdaPop,
        isLambdaPush,
        transducerOutput,
      ]);
}

TmGraphViewOperationVectors? _tmOperationsFromJson(
  Map<String, dynamic> json,
) {
  final reads = (json['tmReadSymbols'] as List?)?.cast<String>();
  final writes = (json['tmWriteSymbols'] as List?)?.cast<String>();
  final rawDirections = (json['tmDirections'] as List?)?.cast<String>();
  final hasAny = reads != null || writes != null || rawDirections != null;
  if (!hasAny) {
    return null;
  }
  if (reads == null || writes == null || rawDirections == null) {
    throw const FormatException(
      'TM read, write, and direction vectors must all be present.',
    );
  }
  try {
    return TmGraphViewOperationVectors(
      readSymbols: reads,
      writeSymbols: writes,
      directions: rawDirections.map(
        (name) => TapeDirection.values.firstWhere(
          (value) => value.name == name,
        ),
      ),
    );
  } on StateError catch (error) {
    throw FormatException('Unknown TM tape direction.', error);
  } on ArgumentError catch (error) {
    throw FormatException('Invalid TM operation vectors.', error);
  }
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
          metadata.stackAlphabet,
          other.metadata.stackAlphabet,
        ) &&
        metadata.initialStackSymbol == other.metadata.initialStackSymbol &&
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
        const ListEquality<String>().hash(metadata.stackAlphabet),
        metadata.initialStackSymbol,
        const ListEquality<String>().hash(metadata.tapeAlphabet),
        metadata.blankSymbol,
        metadata.tapeCount,
      );
}
