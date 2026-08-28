import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/transducers/transducers.dart';

final class TransducerEditorState<
    TMachine extends DeterministicFiniteStateTransducer> {
  static const Object _notProvided = Object();

  const TransducerEditorState({
    required this.document,
    this.lastExecution,
    this.activeTraceIndex,
  });

  final TMachine document;
  final TransducerExecutionOutcome? lastExecution;
  final int? activeTraceIndex;

  TransducerEditorState<TMachine> copyWith({
    TMachine? document,
    TransducerExecutionOutcome? lastExecution,
    Object? activeTraceIndex = _notProvided,
    bool clearExecution = false,
  }) =>
      TransducerEditorState<TMachine>(
        document: document ?? this.document,
        lastExecution:
            clearExecution ? null : (lastExecution ?? this.lastExecution),
        activeTraceIndex: clearExecution
            ? null
            : activeTraceIndex == _notProvided
                ? this.activeTraceIndex
                : activeTraceIndex as int?,
      );
}

class TransducerEditorNotifier<
        TMachine extends DeterministicFiniteStateTransducer>
    extends StateNotifier<TransducerEditorState<TMachine>> {
  TransducerEditorNotifier(TMachine initial)
      : super(TransducerEditorState<TMachine>(document: initial));

  TMachine get document => state.document;

  void replaceDocument(TMachine document) {
    state = state.copyWith(document: document, clearExecution: true);
  }

  void setExecution(TransducerExecutionOutcome outcome) {
    state = state.copyWith(
      lastExecution: outcome,
      activeTraceIndex: outcome.trace.isEmpty ? null : 0,
    );
  }

  void setTraceIndex(int index) {
    final trace = state.lastExecution?.trace ?? const [];
    if (index < 0 || index >= trace.length) return;
    state = state.copyWith(activeTraceIndex: index);
  }

  void clearExecution() => state = state.copyWith(clearExecution: true);
}
