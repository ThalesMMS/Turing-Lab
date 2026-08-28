import 'dart:typed_data';

import '../formal_systems/document_format.dart';

final class DocumentPayload {
  DocumentPayload({
    required Uint8List bytes,
    this.filename,
    this.mimeType,
    this.sourcePath,
  }) : _bytes = Uint8List.fromList(bytes);

  final Uint8List _bytes;
  Uint8List get bytes => _bytes.asUnmodifiableView();
  final String? filename;
  final String? mimeType;
  final String? sourcePath;

  String? get normalizedExtension {
    final name = filename;
    if (name == null) return null;
    final separator = name.lastIndexOf('.');
    if (separator < 0 || separator == name.length - 1) return null;
    return normalizeDocumentExtension(name.substring(separator + 1));
  }
}

final class CodecSourceLocation {
  const CodecSourceLocation({
    this.offset,
    this.line,
    this.column,
    this.path,
  });

  final int? offset;
  final int? line;
  final int? column;
  final String? path;
}

final class DocumentSourceMetadata {
  const DocumentSourceMetadata({
    this.application,
    this.applicationVersion,
    this.sourceFormatVersion,
  });

  final String? application;
  final String? applicationVersion;
  final String? sourceFormatVersion;
}

final class DocumentExtensionBag {
  DocumentExtensionBag([Map<String, Object?> values = const {}])
      : values = Map<String, Object?>.unmodifiable({
          for (final entry in values.entries)
            entry.key: _deepFreeze(entry.value),
        });

  final Map<String, Object?> values;

  bool get isEmpty => values.isEmpty;
}

Object? _deepFreeze(Object? value) {
  if (value is Uint8List) {
    return Uint8List.fromList(value).asUnmodifiableView();
  }
  if (value is Map) {
    return Map<Object?, Object?>.unmodifiable({
      for (final entry in value.entries)
        _deepFreeze(entry.key): _deepFreeze(entry.value),
    });
  }
  if (value is List) {
    return List<Object?>.unmodifiable(value.map(_deepFreeze));
  }
  if (value is Set) {
    return Set<Object?>.unmodifiable(value.map(_deepFreeze));
  }
  return value;
}
