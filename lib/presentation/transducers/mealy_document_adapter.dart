import 'package:flutter/material.dart';

import '../../core/transducers/transducers.dart';
import 'transducer_workspace_definition.dart';

final class MealyDocumentAdapter
    implements TransducerDocumentAdapter<MealyMachine> {
  const MealyDocumentAdapter();

  @override
  TransducerGraphMapping toGraphMapping(MealyMachine machine) =>
      TransducerGraphMapping.fromMachine(machine);

  @override
  MealyMachine addState(
    MealyMachine machine, {
    required String id,
    required String label,
    required Offset position,
  }) =>
      _next(
        machine,
        states: [
          ...machine.states,
          MealyState(
            id: TransducerStateId(id),
            label: label,
            position: TransducerPoint(position.dx, position.dy),
          ),
        ],
      );

  @override
  MealyMachine moveState(
    MealyMachine machine, {
    required String id,
    required Offset position,
  }) =>
      _next(
        machine,
        states: [
          for (final state in machine.states)
            state.id.value == id
                ? state.copyWith(
                    position: TransducerPoint(position.dx, position.dy),
                  )
                : state,
        ],
      );

  @override
  MealyMachine updateState(
    MealyMachine machine, {
    required String id,
    String? label,
    bool? isInitial,
    List<String>? outputTokens,
  }) {
    if (outputTokens != null) {
      throw UnsupportedError('Mealy states do not emit output.');
    }
    return _next(
      machine,
      states: [
        for (final state in machine.states)
          state.copyWith(
            label: state.id.value == id ? label : null,
            isInitial: isInitial == true
                ? state.id.value == id
                : state.id.value == id
                    ? isInitial
                    : null,
          ),
      ],
    );
  }

  @override
  MealyMachine removeState(MealyMachine machine, String id) => _next(
        machine,
        states: machine.states.where((state) => state.id.value != id),
        transitions: machine.transitions.where(
          (transition) =>
              transition.from.value != id && transition.to.value != id,
        ),
      );

  @override
  MealyMachine putTransition(
    MealyMachine machine, {
    required String id,
    required String fromStateId,
    required String toStateId,
    required TransducerTransitionDraft draft,
  }) {
    final transition = MealyTransition(
      id: TransducerTransitionId(id),
      from: TransducerStateId(fromStateId),
      to: TransducerStateId(toStateId),
      input: TransducerInputSymbol(draft.input),
      output: TransducerOutputWord.fromValues(draft.outputTokens ?? const []),
    );
    return _next(
      machine,
      transitions: [
        ...machine.transitions
            .where((candidate) => candidate.id != transition.id),
        transition,
      ],
    );
  }

  @override
  MealyMachine removeTransition(MealyMachine machine, String id) => _next(
        machine,
        transitions: machine.transitions
            .where((transition) => transition.id.value != id),
      );

  @override
  MealyMachine mergeGraphMapping(
    MealyMachine machine,
    TransducerGraphMapping mapping,
  ) =>
      _next(
        machine,
        states: mapping.nodes.map((node) {
          final mealy = node as MealyGraphNode;
          return MealyState(
            id: mealy.id,
            label: mealy.label,
            position: mealy.position,
            isInitial: mealy.isInitial,
          );
        }),
        transitions: mapping.edges.map((edge) {
          final mealy = edge as MealyGraphEdge;
          return MealyTransition(
            id: mealy.id,
            from: mealy.from,
            to: mealy.to,
            input: mealy.input,
            output: mealy.output,
          );
        }),
      );

  @override
  MealyMachine updateAlphabets(
    MealyMachine machine, {
    required Set<TransducerInputSymbol> inputAlphabet,
    required Set<TransducerOutputSymbol> outputAlphabet,
  }) =>
      _next(
        machine,
        inputAlphabet: inputAlphabet,
        outputAlphabet: outputAlphabet,
      );

  MealyMachine _next(
    MealyMachine machine, {
    Iterable<TransducerInputSymbol>? inputAlphabet,
    Iterable<TransducerOutputSymbol>? outputAlphabet,
    Iterable<MealyState>? states,
    Iterable<MealyTransition>? transitions,
  }) =>
      machine.copyWith(
        revision: TransducerRevision(machine.revision.value + 1),
        inputAlphabet: inputAlphabet,
        outputAlphabet: outputAlphabet,
        states: states,
        transitions: transitions,
      );
}
