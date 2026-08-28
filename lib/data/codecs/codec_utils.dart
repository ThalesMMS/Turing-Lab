import 'dart:convert';
import 'dart:typed_data';

import 'package:xml/xml.dart';

import '../../core/interoperability/interoperability.dart';

String utf8Payload(DocumentPayload payload) => utf8.decode(payload.bytes);

Uint8List utf8Bytes(String value) => Uint8List.fromList(utf8.encode(value));

String canonicalJson(Map<String, Object?> value) =>
    jsonEncode(_canonicalize(value));

const canonicalIdentityCurrentVersion = 2;
const _maximumExactJavaScriptInteger = 9007199254740991;

/// Canonical identity text for hashes and generated IDs.
///
/// Version 1 is retained byte-for-byte for values representable exactly on
/// every Dart backend. Inputs containing a larger VM integer use a versioned,
/// typed numeric envelope so distinct integers cannot collapse through a
/// `double` conversion.
String canonicalIdentityJson(Object? value) {
  if (!_requiresCanonicalIdentityV2(value)) {
    return canonicalIdentityJsonV1(value);
  }
  return jsonEncode({
    r'$identityVersion': canonicalIdentityCurrentVersion,
    'value': _canonicalizeIdentityV2(value),
  });
}

/// Historical canonical identity representation used before version 2.
String canonicalIdentityJsonV1(Object? value) =>
    jsonEncode(_canonicalizeIdentityV1(value));

int canonicalIdentityVersionFor(Object? value) =>
    _requiresCanonicalIdentityV2(value) ? canonicalIdentityCurrentVersion : 1;

Object? _canonicalizeIdentityV1(Object? value) {
  if (value is num) {
    return '#number:${value.toDouble().toStringAsPrecision(17)}';
  }
  if (value is Map) {
    final entries = value.entries.toList()
      ..sort(
        (left, right) => left.key.toString().compareTo(right.key.toString()),
      );
    return <String, Object?>{
      for (final entry in entries)
        entry.key.toString(): _canonicalizeIdentityV1(entry.value),
    };
  }
  if (value is Set) {
    final values = value.map(_canonicalizeIdentityV1).toList()
      ..sort((left, right) => jsonEncode(left).compareTo(jsonEncode(right)));
    return values;
  }
  if (value is Iterable) {
    return value.map(_canonicalizeIdentityV1).toList(growable: false);
  }
  return value;
}

bool _requiresCanonicalIdentityV2(Object? value) {
  if (value is int) return value.abs() > _maximumExactJavaScriptInteger;
  if (value is Map) {
    return value.entries.any(
      (entry) =>
          _requiresCanonicalIdentityV2(entry.key) ||
          _requiresCanonicalIdentityV2(entry.value),
    );
  }
  if (value is Iterable) return value.any(_requiresCanonicalIdentityV2);
  return false;
}

Object? _canonicalizeIdentityV2(Object? value) {
  if (value is int) {
    return {r'$number': 'integer', 'value': value.toString()};
  }
  if (value is double) {
    if (!value.isFinite) {
      throw const FormatException(
        'Canonical identity numbers must be finite.',
      );
    }
    return {
      r'$number': 'binary64',
      'value': value.toStringAsPrecision(17),
    };
  }
  if (value is Map) {
    final entries = value.entries.toList()
      ..sort(
        (left, right) => left.key.toString().compareTo(right.key.toString()),
      );
    return <String, Object?>{
      for (final entry in entries)
        entry.key.toString(): _canonicalizeIdentityV2(entry.value),
    };
  }
  if (value is Set) {
    final values = value.map(_canonicalizeIdentityV2).toList()
      ..sort((left, right) => jsonEncode(left).compareTo(jsonEncode(right)));
    return values;
  }
  if (value is Iterable) {
    return value.map(_canonicalizeIdentityV2).toList(growable: false);
  }
  return value;
}

Object? _canonicalize(Object? value) {
  if (value is Map) {
    final entries = value.entries.toList();
    if (entries.any((entry) => entry.key is! String)) {
      throw const FormatException('Canonical JSON map keys must be strings.');
    }
    entries.sort(
      (left, right) => (left.key as String).compareTo(right.key as String),
    );
    return <String, Object?>{
      for (final entry in entries)
        entry.key as String: _canonicalize(entry.value),
    };
  }
  if (value is Set) {
    final values = value.map(_canonicalize).toList()
      ..sort((left, right) => jsonEncode(left).compareTo(jsonEncode(right)));
    return values;
  }
  if (value is Iterable) {
    return value.map(_canonicalize).toList(growable: false);
  }
  return value;
}

String deterministicContentId(String prefix, String source) {
  return '${prefix}_${fnv1a32Hex(source)}';
}

String fnv1a32Hex(String source, [int seed = 0x811c9dc5]) {
  var hash = seed;
  for (final byte in utf8.encode(source)) {
    hash ^= byte;
    // Multiplying two uint32 values is not exact in JavaScript once the
    // intermediate exceeds 53 bits. This equivalent modulo-2^32 form keeps
    // the multiplication below that threshold on every Dart backend.
    hash = ((hash * 0x0193) + ((hash & 0xff) << 24)) & 0xffffffff;
  }
  return hash.toRadixString(16).padLeft(8, '0');
}

String filenameWithExtension(
  String? requested,
  String fallback,
  String extension,
) {
  final base =
      requested?.trim().isNotEmpty == true ? requested!.trim() : fallback;
  return base.toLowerCase().endsWith('.$extension') ? base : '$base.$extension';
}

void preserveXmlChildren(
  XmlElement parent, {
  required Set<String> known,
  required String key,
  required Map<String, Object?> extensions,
  required List<CodecDiagnostic> diagnostics,
}) {
  final unknown = parent.childElements
      .where((element) => !known.contains(element.name.local))
      .map((element) => element.toXmlString())
      .toList(growable: false);
  if (unknown.isEmpty) return;
  extensions[key] = unknown;
  diagnostics.add(CodecDiagnostic(
    code: 'jflap.unknown-optional-element',
    message: 'Unknown optional XML data was preserved.',
    path: key,
  ));
}

void preserveXmlAttributes(
  XmlElement element, {
  required Set<String> known,
  required String key,
  required Map<String, Object?> extensions,
  required List<CodecDiagnostic> diagnostics,
}) {
  final unknown = <String, String>{};
  for (final attribute in element.attributes) {
    if (!known.contains(attribute.name.local)) {
      unknown[attribute.name.qualified] = attribute.value;
    }
  }
  if (unknown.isEmpty) return;
  extensions[key] = unknown;
  diagnostics.add(CodecDiagnostic(
    code: 'jflap.unknown-optional-attribute',
    message: 'Unknown optional XML attributes were preserved.',
    path: key,
  ));
}

void writeXmlExtensions(XmlBuilder builder, Object? raw) {
  if (raw is! List) return;
  for (final value in raw.whereType<String>()) {
    builder.xml(value);
  }
}

void writeXmlAttributes(XmlBuilder builder, Object? raw) {
  if (raw is! Map) return;
  final entries = raw.entries.toList()
    ..sort(
      (left, right) => left.key.toString().compareTo(right.key.toString()),
    );
  for (final entry in entries) {
    builder.attribute(entry.key.toString(), entry.value.toString());
  }
}

String formatXmlNumber(double value) => value == value.roundToDouble()
    ? value.toInt().toString()
    : value.toString();

CodecOutcome<T> copyXmlFailure<T>(CodecOutcome<XmlDocument> outcome) {
  return switch (outcome) {
    CodecMalformed(
      :final reason,
      :final message,
      :final location,
      :final cause,
    ) =>
      CodecMalformed(
        reason: reason,
        message: message,
        location: location,
        cause: cause,
      ),
    CodecResourceLimit(:final limit, :final maximum, :final actual) =>
      CodecResourceLimit(limit: limit, maximum: maximum, actual: actual),
    CodecInternalFailure(:final stage, :final message, :final cause) =>
      CodecInternalFailure(stage: stage, message: message, cause: cause),
    CodecUnsupported(:final reason, :final message, :final roadmapIssue) =>
      CodecUnsupported(
        reason: reason,
        message: message,
        roadmapIssue: roadmapIssue,
      ),
    CodecAmbiguous(:final codecIds) => CodecAmbiguous(codecIds: codecIds),
    CodecSuccess() => throw StateError('Cannot copy a successful XML result.'),
  };
}
