import 'dart:math' as math;

import 'package:vector_math/vector_math_64.dart';

import '../annotations/annotations.dart';
import '../constants/automaton_canvas_constants.dart';
import '../models/fsa.dart';
import '../models/pda.dart';
import '../models/state.dart';
import '../models/tm.dart';
import '../models/transition.dart';
import '../transducers/transducers.dart';
import 'graph_layout_models.dart';

abstract final class GraphLayoutDocumentAdapter {
  static String? documentId(Object? document) => switch (document) {
        final FSA value => value.id,
        final PDA value => value.id,
        final TM value => value.id,
        final MealyMachine value => value.id.value,
        final MooreMachine value => value.id.value,
        _ => null,
      };

  static String? documentRevision(Object? document) => switch (document) {
        final FSA value => value.modified.toUtc().toIso8601String(),
        final PDA value => value.modified.toUtc().toIso8601String(),
        final TM value => value.modified.toUtc().toIso8601String(),
        final MealyMachine value => '${value.revision.value}',
        final MooreMachine value => '${value.revision.value}',
        _ => null,
      };

  static Object applyPositions(
    Object document,
    Map<String, GraphLayoutPoint> positions,
  ) {
    return switch (document) {
      final FSA value => _applyFsa(value, positions),
      final PDA value => _applyPda(value, positions),
      final TM value => _applyTm(value, positions),
      final MealyMachine value => _applyMealy(value, positions),
      final MooreMachine value => _applyMoore(value, positions),
      _ => throw ArgumentError.value(
          document,
          'document',
          'Unsupported graph document type.',
        ),
    };
  }

  static DocumentAnnotationCollection applyFreeAnnotationTransform(
    DocumentAnnotationCollection collection,
    GraphLayoutResult result, {
    required bool transformFreeAnnotations,
  }) {
    final transform = result.transform;
    if (!transformFreeAnnotations || transform == null) return collection;
    return DocumentAnnotationCollection(
      documentId: collection.documentId,
      documentRevision: collection.documentRevision,
      annotations: [
        for (final annotation in collection.annotations)
          if (annotation.attachment != null)
            annotation
          else
            _transformAnnotation(annotation, transform),
      ],
    );
  }
}

FSA _applyFsa(FSA document, Map<String, GraphLayoutPoint> positions) {
  final states = _remapStates(document.states, positions);
  return document.copyWith(
    states: states.values.toSet(),
    transitions: _remapTransitions(document.transitions, states),
    initialState: document.initialState == null
        ? null
        : states[document.initialState!.id],
    acceptingStates:
        document.acceptingStates.map((state) => states[state.id]!).toSet(),
    bounds: _bounds(document.bounds, states.values),
  );
}

PDA _applyPda(PDA document, Map<String, GraphLayoutPoint> positions) {
  final states = _remapStates(document.states, positions);
  return document.copyWith(
    states: states.values.toSet(),
    transitions: _remapTransitions(document.transitions, states),
    initialState: document.initialState == null
        ? null
        : states[document.initialState!.id],
    acceptingStates:
        document.acceptingStates.map((state) => states[state.id]!).toSet(),
    bounds: _bounds(document.bounds, states.values),
  );
}

TM _applyTm(TM document, Map<String, GraphLayoutPoint> positions) {
  final states = _remapStates(document.states, positions);
  return document.copyWith(
    states: states.values.toSet(),
    transitions: _remapTransitions(document.transitions, states),
    initialState: document.initialState == null
        ? null
        : states[document.initialState!.id],
    acceptingStates:
        document.acceptingStates.map((state) => states[state.id]!).toSet(),
    bounds: _bounds(document.bounds, states.values),
  );
}

MealyMachine _applyMealy(
  MealyMachine document,
  Map<String, GraphLayoutPoint> positions,
) {
  return document.copyWith(
    states: [
      for (final state in document.states)
        if (positions[state.id.value] case final position?)
          state.copyWith(
            position: TransducerPoint(position.x, position.y),
          )
        else
          state,
    ],
  );
}

MooreMachine _applyMoore(
  MooreMachine document,
  Map<String, GraphLayoutPoint> positions,
) {
  return document.copyWith(
    states: [
      for (final state in document.states)
        if (positions[state.id.value] case final position?)
          state.copyWith(
            position: TransducerPoint(position.x, position.y),
          )
        else
          state,
    ],
  );
}

Map<String, State> _remapStates(
  Iterable<State> source,
  Map<String, GraphLayoutPoint> positions,
) {
  return {
    for (final state in source)
      state.id: _remapState(state, positions[state.id]),
  };
}

State _remapState(State state, GraphLayoutPoint? position) => position == null
    ? state
    : state.copyWith(position: Vector2(position.x, position.y));

Set<Transition> _remapTransitions(
  Iterable<Transition> source,
  Map<String, State> states,
) {
  return source
      .map(
        (transition) => transition.copyWith(
          fromState: states[transition.fromState.id],
          toState: states[transition.toState.id],
        ),
      )
      .toSet();
}

math.Rectangle<double> _bounds(
  math.Rectangle<num> fallback,
  Iterable<State> states,
) {
  final values = states.toList(growable: false);
  if (values.isEmpty) {
    return math.Rectangle<double>(
      fallback.left.toDouble(),
      fallback.top.toDouble(),
      fallback.width.toDouble(),
      fallback.height.toDouble(),
    );
  }
  final minX = values.map((state) => state.position.x).reduce(math.min);
  final minY = values.map((state) => state.position.y).reduce(math.min);
  final maxX = values
      .map((state) => state.position.x + kAutomatonStateDiameter)
      .reduce(math.max);
  final maxY = values
      .map((state) => state.position.y + kAutomatonStateDiameter)
      .reduce(math.max);
  return math.Rectangle<double>(minX, minY, maxX - minX, maxY - minY);
}

DocumentAnnotation _transformAnnotation(
  DocumentAnnotation annotation,
  GraphLayoutTransform transform,
) {
  final point = transform.apply(GraphLayoutPoint(annotation.x, annotation.y));
  return annotation.copyWith(x: point.x, y: point.y);
}
