import 'dart:typed_data';

import '../formal_systems/document_schema.dart';
import '../formal_systems/formal_system_ids.dart';
import '../messages/structured_message.dart';
import 'codec_source.dart';

enum DocumentFidelity { exact, normalized, lossy }

enum CodecDiagnosticDisposition { preserved, normalized, dropped }

final class CodecDiagnostic {
  const CodecDiagnostic({
    required this.code,
    required this.message,
    this.path,
    this.location,
    this.sourceValue,
    this.structuredMessage,
    this.disposition = CodecDiagnosticDisposition.preserved,
  });

  final String code;
  final String message;
  final String? path;
  final CodecSourceLocation? location;
  final Object? sourceValue;

  /// Locale-neutral semantic payload for presentation-boundary resolution.
  ///
  /// [message] remains as a compatibility detail for existing callers. New
  /// diagnostics should provide this payload so a UI does not need to parse or
  /// translate the legacy prose.
  final StructuredMessage? structuredMessage;
  final CodecDiagnosticDisposition disposition;
}

sealed class CodecOutcome<T> {
  const CodecOutcome();

  bool get isSuccess => this is CodecSuccess<T>;
}

final class CodecSuccess<T> extends CodecOutcome<T> {
  factory CodecSuccess({
    required T value,
    required DocumentFidelity fidelity,
    List<CodecDiagnostic> diagnostics = const [],
  }) {
    final dispositions = diagnostics.map(
      (diagnostic) => diagnostic.disposition,
    );
    if ((fidelity == DocumentFidelity.exact &&
            dispositions.any(
              (disposition) =>
                  disposition != CodecDiagnosticDisposition.preserved,
            )) ||
        (fidelity == DocumentFidelity.normalized &&
            dispositions.contains(CodecDiagnosticDisposition.dropped))) {
      throw ArgumentError(
        'Diagnostic dispositions contradict the declared fidelity.',
      );
    }
    return CodecSuccess._(
      value: value,
      fidelity: fidelity,
      diagnostics: List<CodecDiagnostic>.unmodifiable(diagnostics),
    );
  }

  const CodecSuccess._({
    required this.value,
    required this.fidelity,
    required this.diagnostics,
  });

  final T value;
  final DocumentFidelity fidelity;
  final List<CodecDiagnostic> diagnostics;
}

enum CodecUnsupportedReason { document, feature, schema, format, direction }

final class CodecUnsupported<T> extends CodecOutcome<T> {
  const CodecUnsupported({
    required this.reason,
    required this.message,
    this.roadmapIssue,
    this.structuredMessage,
  });

  final CodecUnsupportedReason reason;
  final String message;
  final int? roadmapIssue;
  final StructuredMessage? structuredMessage;
}

final class CodecAmbiguous<T> extends CodecOutcome<T> {
  CodecAmbiguous({required Iterable<DocumentCodecId> codecIds})
    : codecIds = List<DocumentCodecId>.unmodifiable(
        codecIds.toList()
          ..sort((left, right) => left.value.compareTo(right.value)),
      );

  final List<DocumentCodecId> codecIds;
}

enum CodecMalformedReason {
  syntax,
  invalidUtf8,
  missingField,
  invalidValue,
  duplicateIdentity,
}

final class CodecMalformed<T> extends CodecOutcome<T> {
  const CodecMalformed({
    this.reason = CodecMalformedReason.syntax,
    required this.message,
    this.location,
    this.cause,
    this.structuredMessage,
  });

  final CodecMalformedReason reason;
  final String message;
  final CodecSourceLocation? location;
  final Object? cause;
  final StructuredMessage? structuredMessage;
}

enum CodecResourceLimitKind {
  bytes,
  xmlDepth,
  xmlElements,
  xmlDtdOrEntity,
  jsonDepth,
  collectionEntries,
}

final class CodecResourceLimit<T> extends CodecOutcome<T> {
  const CodecResourceLimit({
    required this.limit,
    required this.maximum,
    required this.actual,
  });

  final CodecResourceLimitKind limit;
  final int maximum;
  final int actual;
}

enum CodecInternalFailureStage { sniff, decode, encode, unknown }

final class CodecInternalFailure<T> extends CodecOutcome<T> {
  const CodecInternalFailure({
    this.stage = CodecInternalFailureStage.unknown,
    required this.message,
    this.cause,
    this.structuredMessage,
  });

  final CodecInternalFailureStage stage;
  final String message;
  final Object? cause;
  final StructuredMessage? structuredMessage;
}

/// Locale-neutral exception bridge for synchronous codec APIs.
final class CodecOperationException implements Exception {
  const CodecOperationException({
    required this.compatibilityCode,
    required this.structuredMessage,
  });

  final String compatibilityCode;
  final StructuredMessage structuredMessage;

  @override
  String toString() => compatibilityCode;
}

final class InteroperableDocument<T extends Object> {
  InteroperableDocument({
    required this.document,
    required this.systemKey,
    required this.schema,
    this.sourceMetadata = const DocumentSourceMetadata(),
    DocumentExtensionBag? extensions,
  }) : extensions = extensions ?? DocumentExtensionBag();

  final T document;
  final FormalSystemKey systemKey;
  final DocumentSchemaDescriptor schema;
  final DocumentSourceMetadata sourceMetadata;
  final DocumentExtensionBag extensions;
}

final class EncodedDocument {
  EncodedDocument({
    required Uint8List bytes,
    required this.mimeType,
    required this.filename,
    required this.schema,
  }) : _bytes = Uint8List.fromList(bytes);

  final Uint8List _bytes;
  Uint8List get bytes => _bytes.asUnmodifiableView();
  final String mimeType;
  final String filename;
  final DocumentSchemaDescriptor schema;
}
