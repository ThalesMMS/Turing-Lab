import 'package:flutter/material.dart';

import '../../core/formal_systems/formal_systems.dart';
import '../../core/transducers/transducers.dart';
import '../../features/canvas/graphview/graphview_canvas_models.dart';

final class TransducerTransitionDraft {
  TransducerTransitionDraft({
    required this.input,
    Iterable<String>? outputTokens,
  }) : outputTokens = outputTokens == null
            ? null
            : List<String>.unmodifiable(outputTokens);

  final String input;
  final List<String>? outputTokens;
}

abstract interface class TransducerDocumentAdapter<
    TMachine extends DeterministicFiniteStateTransducer> {
  TransducerGraphMapping toGraphMapping(TMachine machine);

  TMachine addState(
    TMachine machine, {
    required String id,
    required String label,
    required Offset position,
  });

  TMachine moveState(
    TMachine machine, {
    required String id,
    required Offset position,
  });

  TMachine updateState(
    TMachine machine, {
    required String id,
    String? label,
    bool? isInitial,
    List<String>? outputTokens,
  });

  TMachine removeState(TMachine machine, String id);

  TMachine putTransition(
    TMachine machine, {
    required String id,
    required String fromStateId,
    required String toStateId,
    required TransducerTransitionDraft draft,
  });

  TMachine removeTransition(TMachine machine, String id);

  TMachine mergeGraphMapping(
    TMachine machine,
    TransducerGraphMapping mapping,
  );

  TMachine updateAlphabets(
    TMachine machine, {
    required Set<TransducerInputSymbol> inputAlphabet,
    required Set<TransducerOutputSymbol> outputAlphabet,
  });
}

/// Isolates the transducer domain graph from the FSA-shaped GraphView snapshot.
///
/// Domain adapters only consume [TransducerGraphMapping]. Acceptance and
/// epsilon fields exist solely at this rendering boundary and are never copied
/// into a transducer machine.
final class TransducerCanvasBridge<
    TMachine extends DeterministicFiniteStateTransducer> {
  const TransducerCanvasBridge({
    required this.adapter,
    required this.emissionRule,
  });

  final TransducerDocumentAdapter<TMachine> adapter;
  final TransducerEmissionRule emissionRule;

  GraphViewAutomatonSnapshot toSnapshot(TMachine machine) {
    final mapping = adapter.toGraphMapping(machine);
    return GraphViewAutomatonSnapshot(
      nodes: mapping.nodes
          .map(
            (node) => GraphViewCanvasNode(
              id: node.id.value,
              label: node.label,
              x: node.position.x,
              y: node.position.y,
              isInitial: node.isInitial,
              isAccepting: false,
              secondaryLabel: switch (node) {
                MooreGraphNode(:final output) => _visualOutput(output),
                MealyGraphNode() => null,
              },
              transducerOutput: switch (node) {
                MooreGraphNode(:final output) => output,
                MealyGraphNode() => null,
              },
            ),
          )
          .toList(growable: false),
      edges: mapping.edges
          .map(
            (edge) => GraphViewCanvasEdge(
              id: edge.id.value,
              fromStateId: edge.from.value,
              toStateId: edge.to.value,
              symbols: <String>[edge.input.value],
              readSymbol: edge.input.value,
              transducerOutput: switch (edge) {
                MealyGraphEdge(:final output) => output,
                MooreGraphEdge() => null,
              },
            ),
          )
          .toList(growable: false),
      metadata: GraphViewAutomatonMetadata(
        id: machine.id.value,
        name: machine.name,
        alphabet: machine.inputAlphabet.map((symbol) => symbol.value).toList(),
        outputAlphabet:
            machine.outputAlphabet.map((symbol) => symbol.value).toList(),
      ),
    );
  }

  TMachine mergeSnapshot(
    TMachine machine,
    GraphViewAutomatonSnapshot snapshot,
  ) {
    final original = adapter.toGraphMapping(machine);
    final nodesById = {for (final node in original.nodes) node.id.value: node};
    final edgesById = {for (final edge in original.edges) edge.id.value: edge};
    final mapping = TransducerGraphMapping(
      nodes: snapshot.nodes.map((node) {
        final previous = nodesById[node.id];
        final common = (
          id: TransducerStateId(node.id),
          label: node.label,
          position: TransducerPoint(node.x, node.y),
          isInitial: node.isInitial,
        );
        if (previous case MooreGraphNode(:final output)) {
          return MooreGraphNode(
            id: common.id,
            label: common.label,
            position: common.position,
            isInitial: common.isInitial,
            output: node.transducerOutput ?? output,
          );
        }
        if (previous is MealyGraphNode || emissionRule is MealyEmissionRule) {
          return MealyGraphNode(
            id: common.id,
            label: common.label,
            position: common.position,
            isInitial: common.isInitial,
          );
        }
        return MooreGraphNode(
          id: common.id,
          label: common.label,
          position: common.position,
          isInitial: common.isInitial,
          output: TransducerOutputWord.empty,
        );
      }),
      edges: snapshot.edges.map((edge) {
        final previous = edgesById[edge.id];
        final input = TransducerInputSymbol(
          edge.readSymbol ?? edge.symbols.single,
        );
        if (previous case MealyGraphEdge(:final output)) {
          return MealyGraphEdge(
            id: TransducerTransitionId(edge.id),
            from: TransducerStateId(edge.fromStateId),
            to: TransducerStateId(edge.toStateId),
            input: input,
            output: edge.transducerOutput ?? output,
          );
        }
        if (previous is MooreGraphEdge || emissionRule is MooreEmissionRule) {
          return MooreGraphEdge(
            id: TransducerTransitionId(edge.id),
            from: TransducerStateId(edge.fromStateId),
            to: TransducerStateId(edge.toStateId),
            input: input,
          );
        }
        return MealyGraphEdge(
          id: TransducerTransitionId(edge.id),
          from: TransducerStateId(edge.fromStateId),
          to: TransducerStateId(edge.toStateId),
          input: input,
          output: edge.transducerOutput ?? TransducerOutputWord.empty,
        );
      }),
    );
    return adapter.mergeGraphMapping(machine, mapping);
  }

  static String _visualOutput(TransducerOutputWord output) =>
      output.values.isEmpty ? '[]' : output.values.join(' · ');
}

typedef TransducerSimulatorFactory<
        TMachine extends DeterministicFiniteStateTransducer>
    = DeterministicTransducerSimulator Function(TMachine machine);

@immutable
final class TransducerWorkspaceDefinition<
    TMachine extends DeterministicFiniteStateTransducer> {
  const TransducerWorkspaceDefinition({
    required this.systemKey,
    required this.schema,
    required this.initialDocument,
    required this.adapter,
    required this.simulator,
    required this.emissionRule,
  });

  final FormalSystemKey systemKey;
  final DocumentSchemaDescriptor schema;
  final TMachine Function() initialDocument;
  final TransducerDocumentAdapter<TMachine> adapter;
  final TransducerSimulatorFactory<TMachine> simulator;
  final TransducerEmissionRule emissionRule;

  TransducerCanvasBridge<TMachine> get canvasBridge => TransducerCanvasBridge(
        adapter: adapter,
        emissionRule: emissionRule,
      );
}
