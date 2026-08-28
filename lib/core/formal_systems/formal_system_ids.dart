/// Base for stable, serialization-safe identifiers used by formal systems.
abstract base class FormalSystemStableId {
  const FormalSystemStableId(this.value);

  final String value;

  @override
  bool operator ==(Object other) =>
      other.runtimeType == runtimeType &&
      other is FormalSystemStableId &&
      other.value == value;

  @override
  int get hashCode => Object.hash(runtimeType, value);

  @override
  String toString() => value;
}

final class FormalSystemTypeId extends FormalSystemStableId {
  const FormalSystemTypeId(super.value);
}

final class FormalSystemVariantId extends FormalSystemStableId {
  const FormalSystemVariantId(super.value);
}

final class DocumentSchemaId extends FormalSystemStableId {
  const DocumentSchemaId(super.value);
}

final class WorkspaceRouteId extends FormalSystemStableId {
  const WorkspaceRouteId(super.value);
}

final class DocumentFormatId extends FormalSystemStableId {
  const DocumentFormatId(super.value);
}

final class DocumentCodecId extends FormalSystemStableId {
  const DocumentCodecId(super.value);
}

final class ConversionEdgeId extends FormalSystemStableId {
  const ConversionEdgeId(super.value);
}

final class CapabilityNamespaceId extends FormalSystemStableId {
  const CapabilityNamespaceId(super.value);
}

final class DocumentSchemaVersion {
  const DocumentSchemaVersion(this.value);

  final int value;

  @override
  bool operator ==(Object other) =>
      other is DocumentSchemaVersion && other.value == value;

  @override
  int get hashCode => value.hashCode;

  @override
  String toString() => '$value';
}

final class FormalSystemKey implements Comparable<FormalSystemKey> {
  const FormalSystemKey({required this.type, required this.variant});

  final FormalSystemTypeId type;
  final FormalSystemVariantId variant;

  String get value => '${type.value}:${variant.value}';

  @override
  int compareTo(FormalSystemKey other) => value.compareTo(other.value);

  @override
  bool operator ==(Object other) =>
      other is FormalSystemKey &&
      other.type == type &&
      other.variant == variant;

  @override
  int get hashCode => Object.hash(type, variant);

  @override
  String toString() => value;
}
