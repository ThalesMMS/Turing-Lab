//
//  turing_machine_entity.dart
//  Turing Lab
//
//  Modela a entidade de domínio para máquinas de Turing, abrangendo alfabetos,
//  estados, transições e atributos de aceitação necessários para análises
//  formais. Fornece coleções e utilidades de acesso que sustentam simuladores e
//  repositórios especializados.
//
//  Thales Matheus Mendonça Santos - October 2025
//

/// Core domain entity representing a Turing machine
class TuringMachineEntity {
  final String id;
  final String name;
  final Set<String> inputAlphabet;
  final Set<String> tapeAlphabet;
  final String blankSymbol;
  final List<TuringStateEntity> states;
  final List<TuringTransitionEntity> transitions;
  final String initialStateId;
  final Set<String> acceptingStateIds;
  final Set<String> rejectingStateIds;
  final int nextStateIndex;

  const TuringMachineEntity({
    required this.id,
    required this.name,
    required this.inputAlphabet,
    required this.tapeAlphabet,
    required this.blankSymbol,
    required this.states,
    required this.transitions,
    required this.initialStateId,
    required this.acceptingStateIds,
    required this.rejectingStateIds,
    this.nextStateIndex = 0,
  });

  TuringStateEntity? getStateById(String stateId) {
    try {
      return states.firstWhere((state) => state.id == stateId);
    } catch (_) {
      return null;
    }
  }

  Iterable<TuringTransitionEntity> transitionsFrom(String stateId) =>
      transitions.where((transition) => transition.fromStateId == stateId);

  bool get hasStates => states.isNotEmpty;
}

/// Represents a state in a Turing machine
class TuringStateEntity {
  final String id;
  final String name;
  final bool isInitial;
  final bool isAccepting;
  final bool isRejecting;

  const TuringStateEntity({
    required this.id,
    required this.name,
    this.isInitial = false,
    this.isAccepting = false,
    this.isRejecting = false,
  });
}

/// Represents a transition in a Turing machine
class TuringTransitionEntity {
  final String id;
  final String fromStateId;
  final String toStateId;
  final String readSymbol;
  final String writeSymbol;
  final TuringMoveDirection moveDirection;

  const TuringTransitionEntity({
    required this.id,
    required this.fromStateId,
    required this.toStateId,
    required this.readSymbol,
    required this.writeSymbol,
    required this.moveDirection,
  });
}

/// Directions the Turing machine head can move
enum TuringMoveDirection { left, right, stay }
