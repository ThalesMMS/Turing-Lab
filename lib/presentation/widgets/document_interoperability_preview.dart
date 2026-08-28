import '../../core/interoperability/interoperability.dart';

enum DocumentInteroperabilityOperation { importDocument, exportDocument }

/// One translated document-specific fact shown in the review dialog.
final class DocumentInteroperabilityFact {
  const DocumentInteroperabilityFact({
    required this.label,
    required this.value,
  });

  final String label;
  final String value;
}

/// Presentation-ready metadata shown before an import or export is committed.
final class DocumentInteroperabilityPreview {
  DocumentInteroperabilityPreview({
    required this.operation,
    required this.fileName,
    required this.systemLabel,
    required this.formatLabel,
    required this.schemaVersion,
    required this.fidelity,
    Iterable<CodecDiagnostic> diagnostics = const [],
    Iterable<DocumentInteroperabilityFact> facts = const [],
  })  : diagnostics = List<CodecDiagnostic>.unmodifiable(diagnostics),
        facts = List<DocumentInteroperabilityFact>.unmodifiable(facts);

  final DocumentInteroperabilityOperation operation;
  final String fileName;
  final String systemLabel;
  final String formatLabel;
  final int schemaVersion;
  final DocumentFidelity fidelity;
  final List<CodecDiagnostic> diagnostics;
  final List<DocumentInteroperabilityFact> facts;

  bool get isLossy => fidelity == DocumentFidelity.lossy;
}
