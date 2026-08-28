abstract base class TransducerStableId {
  const TransducerStableId(this.value);

  final String value;

  @override
  bool operator ==(Object other) =>
      other.runtimeType == runtimeType &&
      other is TransducerStableId &&
      other.value == value;

  @override
  int get hashCode => Object.hash(runtimeType, value);

  @override
  String toString() => value;
}

final class TransducerMachineId extends TransducerStableId {
  const TransducerMachineId(super.value);
}

final class TransducerStateId extends TransducerStableId
    implements Comparable<TransducerStateId> {
  const TransducerStateId(super.value);

  @override
  int compareTo(TransducerStateId other) => value.compareTo(other.value);
}

final class TransducerTransitionId extends TransducerStableId
    implements Comparable<TransducerTransitionId> {
  const TransducerTransitionId(super.value);

  @override
  int compareTo(TransducerTransitionId other) => value.compareTo(other.value);
}

final class TransducerRevision {
  const TransducerRevision(this.value);

  final int value;

  @override
  bool operator ==(Object other) =>
      other is TransducerRevision && other.value == value;

  @override
  int get hashCode => value.hashCode;
}
