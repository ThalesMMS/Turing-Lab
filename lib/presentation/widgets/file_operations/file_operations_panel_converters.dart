part of '../file_operations_panel.dart';

extension _FileOperationsPanelConverters on _FileOperationsPanelState {
  Future<Result<FSA>> _loadAutomatonJsonFromPlatformFile(
    PlatformFile file,
  ) async {
    if (file.bytes != null) {
      return _fileService.loadAutomatonFromJsonBytes(file.bytes!);
    }

    final normalizedPath = _normalizedJsonPath(file.path);
    if (normalizedPath != null) {
      return _fileService.loadAutomatonFromJson(normalizedPath);
    }

    return Failure<FSA>(_l10n.jsonUnreadableFileMessage);
  }

  TuringMachineEntity _convertTmToEntity(TM tm) {
    return TuringMachineEntity(
      id: tm.id,
      name: tm.name,
      inputAlphabet: tm.alphabet,
      tapeAlphabet: tm.tapeAlphabet,
      blankSymbol: tm.blankSymbol,
      states: tm.states
          .map(
            (state) => TuringStateEntity(
              id: state.id,
              name: state.label,
              isInitial: state.isInitial,
              isAccepting: state.isAccepting,
            ),
          )
          .toList(),
      transitions: tm.tmTransitions
          .map(
            (transition) => TuringTransitionEntity(
              id: transition.id,
              fromStateId: transition.fromState.id,
              toStateId: transition.toState.id,
              readSymbol: transition.readSymbol,
              writeSymbol: transition.writeSymbol,
              moveDirection: _convertTapeDirection(transition.direction),
            ),
          )
          .toList(),
      initialStateId: tm.initialState?.id ?? '',
      acceptingStateIds: tm.acceptingStates.map((state) => state.id).toSet(),
      rejectingStateIds: const <String>{},
      nextStateIndex: tm.states.length,
    );
  }

  TuringMoveDirection _convertTapeDirection(TapeDirection direction) {
    switch (direction) {
      case TapeDirection.left:
        return TuringMoveDirection.left;
      case TapeDirection.right:
        return TuringMoveDirection.right;
      case TapeDirection.stay:
        return TuringMoveDirection.stay;
    }
  }
}
