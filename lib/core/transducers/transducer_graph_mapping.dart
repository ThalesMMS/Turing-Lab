import 'transducer_ids.dart';
import 'transducer_models.dart';
import 'transducer_symbols.dart';

sealed class TransducerGraphNode {
  const TransducerGraphNode({
    required this.id,
    required this.label,
    required this.position,
    required this.isInitial,
  });

  final TransducerStateId id;
  final String label;
  final TransducerPoint position;
  final bool isInitial;

  Map<String, Object?> toJson();
}

final class MealyGraphNode extends TransducerGraphNode {
  const MealyGraphNode({
    required super.id,
    required super.label,
    required super.position,
    required super.isInitial,
  });

  @override
  Map<String, Object?> toJson() => {
        'id': id.value,
        'label': label,
        'x': position.x,
        'y': position.y,
        'isInitial': isInitial,
      };
}

final class MooreGraphNode extends TransducerGraphNode {
  const MooreGraphNode({
    required super.id,
    required super.label,
    required super.position,
    required super.isInitial,
    required this.output,
  });

  final TransducerOutputWord output;

  @override
  Map<String, Object?> toJson() => {
        'id': id.value,
        'label': label,
        'x': position.x,
        'y': position.y,
        'isInitial': isInitial,
        'output': output.values,
      };
}

sealed class TransducerGraphEdge {
  const TransducerGraphEdge({
    required this.id,
    required this.from,
    required this.to,
    required this.input,
  });

  final TransducerTransitionId id;
  final TransducerStateId from;
  final TransducerStateId to;
  final TransducerInputSymbol input;

  Map<String, Object?> toJson();
}

final class MealyGraphEdge extends TransducerGraphEdge {
  const MealyGraphEdge({
    required super.id,
    required super.from,
    required super.to,
    required super.input,
    required this.output,
  });

  final TransducerOutputWord output;

  @override
  Map<String, Object?> toJson() => {
        'id': id.value,
        'from': from.value,
        'to': to.value,
        'input': input.value,
        'output': output.values,
      };
}

final class MooreGraphEdge extends TransducerGraphEdge {
  const MooreGraphEdge({
    required super.id,
    required super.from,
    required super.to,
    required super.input,
  });

  @override
  Map<String, Object?> toJson() => {
        'id': id.value,
        'from': from.value,
        'to': to.value,
        'input': input.value,
      };
}

final class TransducerGraphMapping {
  TransducerGraphMapping({
    required Iterable<TransducerGraphNode> nodes,
    required Iterable<TransducerGraphEdge> edges,
  })  : nodes = List<TransducerGraphNode>.unmodifiable(nodes),
        edges = List<TransducerGraphEdge>.unmodifiable(edges);

  final List<TransducerGraphNode> nodes;
  final List<TransducerGraphEdge> edges;

  factory TransducerGraphMapping.fromMachine(
    DeterministicFiniteStateTransducer machine,
  ) =>
      TransducerGraphMapping(
        nodes: machine.states.map(
          (state) => switch (state) {
            MealyState() => MealyGraphNode(
                id: state.id,
                label: state.label,
                position: state.position,
                isInitial: state.isInitial,
              ),
            MooreState(:final output) => MooreGraphNode(
                id: state.id,
                label: state.label,
                position: state.position,
                isInitial: state.isInitial,
                output: output,
              ),
          },
        ),
        edges: machine.transitions.map(
          (transition) => switch (transition) {
            MealyTransition(:final output) => MealyGraphEdge(
                id: transition.id,
                from: transition.from,
                to: transition.to,
                input: transition.input,
                output: output,
              ),
            MooreTransition() => MooreGraphEdge(
                id: transition.id,
                from: transition.from,
                to: transition.to,
                input: transition.input,
              ),
          },
        ),
      );
}
