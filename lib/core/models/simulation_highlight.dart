//
//  simulation_highlight.dart
//  Turing Lab
//
//  Descreve de forma imutável quais estados e transições devem ser destacados em uma simulação de autômato. Garante comparações simples e construção de cópias para que serviços de destaque atualizem a interface sem efeitos colaterais.
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

  /// Creates a new [SimulationHighlight].
  factory SimulationHighlight({
    Set<String> stateIds = const <String>{},
    Set<String> transitionIds = const <String>{},
  }) {
    return SimulationHighlight._(
      Set<String>.unmodifiable(stateIds),
      Set<String>.unmodifiable(transitionIds),
    );
  }

  const SimulationHighlight._(this._stateIds, this._transitionIds);

  /// Empty highlight payload.
  static final SimulationHighlight empty = SimulationHighlight();

  Set<String> get stateIds => _stateIds;

  Set<String> get transitionIds => _transitionIds;

  /// Returns whether the payload does not request any highlight.
  bool get isEmpty => _stateIds.isEmpty && _transitionIds.isEmpty;

  /// Creates a copy with optional overrides.
  SimulationHighlight copyWith({
    Set<String>? stateIds,
    Set<String>? transitionIds,
  }) {
    return SimulationHighlight(
      stateIds: stateIds ?? this.stateIds,
      transitionIds: transitionIds ?? this.transitionIds,
    );
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        other is SimulationHighlight &&
            _setEquality.equals(other._stateIds, _stateIds) &&
            _setEquality.equals(other._transitionIds, _transitionIds);
  }

  @override
  int get hashCode => Object.hash(
      _setEquality.hash(_stateIds), _setEquality.hash(_transitionIds));
}
