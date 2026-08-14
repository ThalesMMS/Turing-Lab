//
//  algorithm_step_highlight_extractor.dart
//  Turing Lab
//
//  Extracts canvas highlight IDs from generic algorithm step properties.
//

import '../models/simulation_highlight.dart';

const List<String> _stateIdKeys = [
  'currentStateIds',
  'epsilonClosureIds',
  'reachableStateIds',
  'nextStateIds',
  'dfaStateId',
  'processingSetIds',
  'predecessorStateIds',
  'splitSetIds',
  'splitIntersectionIds',
  'splitDifferenceIds',
  'equivalenceClassStateIds',
  'equivalenceClassId',
  'createdStateIds',
  'fragmentStartStateId',
  'fragmentAcceptStateId',
];

const List<String> _transitionIdKeys = ['createdTransitionIds'];

SimulationHighlight extractAlgorithmStepHighlight(
  Map<String, dynamic> properties,
) {
  final stateIds = <String>{};
  final transitionIds = <String>{};

  for (final key in _stateIdKeys) {
    _addIds(stateIds, properties[key]);
  }
  for (final key in _transitionIdKeys) {
    _addIds(transitionIds, properties[key]);
  }

  return SimulationHighlight(
    stateIds: Set.unmodifiable(stateIds),
    transitionIds: Set.unmodifiable(transitionIds),
  );
}

void _addIds(Set<String> target, Object? value) {
  if (value == null) return;
  if (value is String) {
    final trimmed = value.trim();
    if (trimmed.isNotEmpty) {
      target.add(trimmed);
    }
    return;
  }
  if (value is Iterable) {
    for (final item in value) {
      _addIds(target, item);
    }
  }
}
