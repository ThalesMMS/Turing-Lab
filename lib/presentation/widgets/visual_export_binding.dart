import 'dart:typed_data';

import '../../core/formal_systems/formal_systems.dart';

typedef VisualExportProducer = Future<VisualExportArtifact> Function({
  required bool includeAnnotations,
});

final class VisualExportArtifact {
  VisualExportArtifact({
    required Uint8List bytes,
    required this.mimeType,
    required this.filename,
    required this.width,
    required this.height,
  }) : bytes = Uint8List.fromList(bytes) {
    if (filename.trim().isEmpty || mimeType.trim().isEmpty) {
      throw ArgumentError('Visual export metadata must not be empty.');
    }
    if (width <= 0 || height <= 0) {
      throw ArgumentError('Visual export dimensions must be positive.');
    }
  }

  final Uint8List bytes;
  final String mimeType;
  final String filename;
  final int width;
  final int height;
}

/// Connects a renderable workspace to the formats declared by its registry
/// descriptor. A producer alone never makes a format user-reachable.
final class VisualExportBinding {
  VisualExportBinding({
    required this.systemKey,
    required Map<DocumentFormatId, VisualExportProducer> producers,
  }) : producers = Map<DocumentFormatId, VisualExportProducer>.unmodifiable(
          producers,
        );

  final FormalSystemKey systemKey;
  final Map<DocumentFormatId, VisualExportProducer> producers;

  List<DocumentFormatId> supportedFormats(FormalSystemRegistry registry) {
    final descriptor = registry.descriptorFor(systemKey);
    if (descriptor == null) return const [];
    final formats = producers.keys
        .where(
          (format) =>
              descriptor
                  .formatSupport(format)
                  ?.supports(DocumentFormatDirection.exportDocument) ??
              false,
        )
        .toList()
      ..sort((left, right) => left.value.compareTo(right.value));
    return List<DocumentFormatId>.unmodifiable(formats);
  }
}
