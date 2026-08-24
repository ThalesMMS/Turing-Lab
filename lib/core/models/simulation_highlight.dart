//
//  simulation_highlight.dart
//  Turing Lab
//
//  Immutably describes which states and transitions should be highlighted in
//  an automaton simulation. Guarantees simple comparisons and copy
//  construction so highlight services can update the UI without side
//  effects.
//
//  Thales Matheus Mendonça Santos - October 2025
//

import 'package:collection/collection.dart';

// Intentionally kept as a small manual value object instead of Freezed:
// this payload only needs const construction plus explicit set-based equality,
// and the manual implementation avoids generated-code churn for a tiny model.
/// Immutable payload describing which canvas elements should be highlighted.
class SimulationHighlight {
  static const SetEquality<String> _setEquality = SetEquality<String>();

  /// Set of state identifiers to highlight.
  final Set<String> _stateIds;

  /// Set of transition identifiers to highlight.
  final Set<String> _transitionIds;

  /// States highlighted as bounded or cautionary evidence.
  final Set<String> _warningStateIds;

  /// States highlighted as exact negative or error evidence.
  final Set<String> _errorStateIds;

  /// Creates a new [SimulationHighlight].
  factory SimulationHighlight({
    Set<String> stateIds = const <String>{},
    Set<String> transitionIds = const <String>{},
    Set<String> warningStateIds = const <String>{},
    Set<String> errorStateIds = const <String>{},
  }) {
    return SimulationHighlight._(
      Set<String>.unmodifiable(stateIds),
      Set<String>.unmodifiable(transitionIds),
      Set<String>.unmodifiable(warningStateIds),
      Set<String>.unmodifiable(errorStateIds),
    );
  }

  const SimulationHighlight._(
    this._stateIds,
    this._transitionIds,
    this._warningStateIds,
    this._errorStateIds,
  );

  /// Empty highlight payload.
  static final SimulationHighlight empty = SimulationHighlight();

  Set<String> get stateIds => _stateIds;

  Set<String> get transitionIds => _transitionIds;

  Set<String> get warningStateIds => _warningStateIds;

  Set<String> get errorStateIds => _errorStateIds;

  /// Returns whether the payload does not request any highlight.
  bool get isEmpty =>
      _stateIds.isEmpty &&
      _transitionIds.isEmpty &&
      _warningStateIds.isEmpty &&
      _errorStateIds.isEmpty;

  /// Creates a copy with optional overrides.
  SimulationHighlight copyWith({
    Set<String>? stateIds,
    Set<String>? transitionIds,
    Set<String>? warningStateIds,
    Set<String>? errorStateIds,
  }) {
    return SimulationHighlight(
      stateIds: stateIds ?? this.stateIds,
      transitionIds: transitionIds ?? this.transitionIds,
      warningStateIds: warningStateIds ?? this.warningStateIds,
      errorStateIds: errorStateIds ?? this.errorStateIds,
    );
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        other is SimulationHighlight &&
            _setEquality.equals(other._stateIds, _stateIds) &&
            _setEquality.equals(other._transitionIds, _transitionIds) &&
            _setEquality.equals(other._warningStateIds, _warningStateIds) &&
            _setEquality.equals(other._errorStateIds, _errorStateIds);
  }

  @override
  int get hashCode => Object.hash(
        _setEquality.hash(_stateIds),
        _setEquality.hash(_transitionIds),
        _setEquality.hash(_warningStateIds),
        _setEquality.hash(_errorStateIds),
      );
}
