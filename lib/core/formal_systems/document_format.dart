import 'capability_availability.dart';
import 'formal_system_configuration.dart';
import 'formal_system_ids.dart';

enum DocumentFormatDirection { importDocument, exportDocument }

final class DocumentFormatDescriptor {
  DocumentFormatDescriptor({
    required this.id,
    required Iterable<String> extensions,
    this.mediaType,
  }) : extensions = Set<String>.unmodifiable(extensions);

  final DocumentFormatId id;
  final Set<String> extensions;
  final String? mediaType;

  Set<String> get normalizedExtensions => Set<String>.unmodifiable(
        extensions.map(normalizeDocumentExtension),
      );
}

final class DocumentFormatSupport {
  const DocumentFormatSupport({
    required this.formatId,
    this.importAvailability = const UnavailableCapability(),
    this.exportAvailability = const UnavailableCapability(),
    this.preferredExtension,
  });

  final DocumentFormatId formatId;
  final CapabilityAvailability importAvailability;
  final CapabilityAvailability exportAvailability;
  final String? preferredExtension;

  CapabilityAvailability availabilityOf(DocumentFormatDirection direction) =>
      switch (direction) {
        DocumentFormatDirection.importDocument => importAvailability,
        DocumentFormatDirection.exportDocument => exportAvailability,
      };

  bool supports(DocumentFormatDirection direction) =>
      availabilityOf(direction).isEnabled;
}

final class DocumentFormatCatalog {
  factory DocumentFormatCatalog(Iterable<DocumentFormatDescriptor> formats) {
    final values = List<DocumentFormatDescriptor>.unmodifiable(formats);
    final issues = validateDocumentFormats(values);
    if (issues.isNotEmpty) {
      throw FormalSystemConfigurationException(issues);
    }
    return DocumentFormatCatalog._validated(values);
  }

  DocumentFormatCatalog._validated(Iterable<DocumentFormatDescriptor> formats)
      : formats = List<DocumentFormatDescriptor>.unmodifiable(
          formats.toList()
            ..sort((left, right) => left.id.value.compareTo(right.id.value)),
        ),
        _byId = Map<DocumentFormatId, DocumentFormatDescriptor>.unmodifiable({
          for (final format in formats) format.id: format,
        });

  final List<DocumentFormatDescriptor> formats;
  final Map<DocumentFormatId, DocumentFormatDescriptor> _byId;

  DocumentFormatDescriptor? operator [](DocumentFormatId id) => _byId[id];

  DocumentFormatDescriptor? forExtension(String extension) {
    final normalized = normalizeDocumentExtension(extension);
    for (final format in formats) {
      if (format.normalizedExtensions.contains(normalized)) return format;
    }
    return null;
  }
}

String normalizeDocumentExtension(String extension) {
  final trimmed = extension.trim().toLowerCase();
  return trimmed.startsWith('.') ? trimmed.substring(1) : trimmed;
}

List<FormalSystemConfigurationIssue> validateDocumentFormats(
  Iterable<DocumentFormatDescriptor> formats,
) {
  final issues = <FormalSystemConfigurationIssue>[];
  final formatsById = <String, List<String>>{};
  final formatsByExtension = <String, List<String>>{};
  for (final format in formats) {
    formatsById.putIfAbsent(format.id.value, () => []).add(format.id.value);
    if (format.id.value.trim().isEmpty) {
      issues.add(FormalSystemConfigurationIssue(
        code: FormalSystemConfigurationIssueCode.invalidIdentifier,
        value: 'document-format',
        owners: const ['document-format'],
      ));
    }
    for (final extension in format.normalizedExtensions) {
      formatsByExtension.putIfAbsent(extension, () => []).add(format.id.value);
      if (extension.isEmpty || extension.contains('.')) {
        issues.add(FormalSystemConfigurationIssue(
          code: FormalSystemConfigurationIssueCode.invalidExtension,
          value: extension,
          owners: [format.id.value],
        ));
      }
    }
  }
  _addDuplicateIssues(
    issues,
    formatsById,
    FormalSystemConfigurationIssueCode.duplicateFormat,
  );
  _addDuplicateIssues(
    issues,
    formatsByExtension,
    FormalSystemConfigurationIssueCode.duplicateExtension,
  );
  return issues..sort();
}

void _addDuplicateIssues(
  List<FormalSystemConfigurationIssue> issues,
  Map<String, List<String>> values,
  FormalSystemConfigurationIssueCode code,
) {
  for (final entry in values.entries) {
    if (entry.value.length < 2) continue;
    issues.add(FormalSystemConfigurationIssue(
      code: code,
      value: entry.key,
      owners: entry.value,
    ));
  }
}
