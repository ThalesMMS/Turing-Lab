import 'package:flutter/material.dart';

import '../../core/transducers/transducers.dart';
import 'transducer_workspace_definition.dart';

final class MooreDocumentAdapter
    implements TransducerDocumentAdapter<MooreMachine> {
  const MooreDocumentAdapter();

  @override
  TransducerGraphMapping toGraphMapping(MooreMachine machine) =>
      TransducerGraphMapping.fromMachine(machine);

  @override
  MooreMachine addState(
    MooreMachine machine, {
    required String id,
    required String label,
    required Offset position,
  }) =>
      _next(
        machine,
        states: [
          ...machine.states,
          MooreState(
            id: TransducerStateId(id),
            label: label,
            position: TransducerPoint(position.dx, position.dy),
            output: TransducerOutputWord.empty,
          ),
        ],
      );

  @override
  MooreMachine moveState(
    MooreMachine machine, {
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
  MooreMachine updateState(
    MooreMachine machine, {
    required String id,
    String? label,
    bool? isInitial,
    List<String>? outputTokens,
  }) =>
      _next(
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
              output: state.id.value == id && outputTokens != null
                  ? TransducerOutputWord.fromValues(outputTokens)
                  : null,
            ),
        ],
      );

  @override
  MooreMachine removeState(MooreMachine machine, String id) => _next(
        machine,
        states: machine.states.where((state) => state.id.value != id),
        transitions: machine.transitions.where(
          (transition) =>
              transition.from.value != id && transition.to.value != id,
        ),
      );

  @override
  MooreMachine putTransition(
    MooreMachine machine, {
    required String id,
    required String fromStateId,
    required String toStateId,
    required TransducerTransitionDraft draft,
  }) {
    if (draft.outputTokens != null) {
      throw UnsupportedError('Moore transitions do not emit output.');
    }
    final transition = MooreTransition(
      id: TransducerTransitionId(id),
      from: TransducerStateId(fromStateId),
      to: TransducerStateId(toStateId),
      input: TransducerInputSymbol(draft.input),
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
  MooreMachine removeTransition(MooreMachine machine, String id) => _next(
        machine,
        transitions: machine.transitions
            .where((transition) => transition.id.value != id),
      );

  @override
  MooreMachine mergeGraphMapping(
    MooreMachine machine,
    TransducerGraphMapping mapping,
  ) =>
      _next(
        machine,
        states: mapping.nodes.map((node) {
          final moore = node as MooreGraphNode;
          return MooreState(
            id: moore.id,
            label: moore.label,
            position: moore.position,
            isInitial: moore.isInitial,
            output: moore.output,
          );
        }),
        transitions: mapping.edges.map((edge) {
          final moore = edge as MooreGraphEdge;
          return MooreTransition(
            id: moore.id,
            from: moore.from,
            to: moore.to,
            input: moore.input,
          );
        }),
      );

  @override
  MooreMachine updateAlphabets(
    MooreMachine machine, {
    required Set<TransducerInputSymbol> inputAlphabet,
    required Set<TransducerOutputSymbol> outputAlphabet,
  }) =>
      _next(
        machine,
        inputAlphabet: inputAlphabet,
        outputAlphabet: outputAlphabet,
      );

  MooreMachine _next(
    MooreMachine machine, {
    Iterable<TransducerInputSymbol>? inputAlphabet,
    Iterable<TransducerOutputSymbol>? outputAlphabet,
    Iterable<MooreState>? states,
    Iterable<MooreTransition>? transitions,
  }) =>
      machine.copyWith(
        revision: TransducerRevision(machine.revision.value + 1),
        inputAlphabet: inputAlphabet,
        outputAlphabet: outputAlphabet,
        states: states,
        transitions: transitions,
      );
}
