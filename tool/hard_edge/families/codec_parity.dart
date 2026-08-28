import 'dart:convert';
import 'dart:typed_data';

import 'package:crypto/crypto.dart';
import 'package:turing_lab/core/formal_systems/formal_systems.dart';
import 'package:turing_lab/core/interoperability/interoperability.dart';

final class CodecParityVector {
  const CodecParityVector({
    required this.codecId,
    required this.filename,
    required this.payloadBase64,
    required this.nativeOutcomeSha256,
  });

  final String codecId;
  final String filename;
  final String payloadBase64;
  final String nativeOutcomeSha256;

  Uint8List get payload => Uint8List.fromList(base64Decode(payloadBase64));
}

String codecCanonicalOutcomeSha256(
  DocumentCodecCapability<Object> codec,
  DocumentPayload payload,
) =>
    sha256
        .convert(utf8.encode(codecCanonicalOutcome(codec, payload)))
        .toString();

String codecCanonicalOutcome(
  DocumentCodecCapability<Object> codec,
  DocumentPayload payload,
) {
  final decoded = codec.decode(payload);
  final value = switch (decoded) {
    CodecSuccess<InteroperableDocument<Object>>() => _success(codec, decoded),
    CodecMalformed<InteroperableDocument<Object>>() => {
        'outcome': 'malformed',
        'reason': decoded.reason.name,
      },
    CodecUnsupported<InteroperableDocument<Object>>() => {
        'outcome': 'unsupported',
        'reason': decoded.reason.name,
      },
    CodecResourceLimit<InteroperableDocument<Object>>() => {
        'actual': decoded.actual,
        'limit': decoded.limit.name,
        'maximum': decoded.maximum,
        'outcome': 'resourceLimit',
      },
    CodecAmbiguous<InteroperableDocument<Object>>() => {
        'codecIds': decoded.codecIds.map((id) => id.value).toList()..sort(),
        'outcome': 'ambiguous',
      },
    CodecInternalFailure<InteroperableDocument<Object>>() => {
        'outcome': 'internalFailure',
        'stage': decoded.stage.name,
      },
  };
  return jsonEncode(_canonicalize(value));
}

Map<String, Object?> _success(
  DocumentCodecCapability<Object> codec,
  CodecSuccess<InteroperableDocument<Object>> decoded,
) {
  final encoded = codec.encode(decoded.value);
  return {
    'document': _documentJson(decoded.value.document),
    'encoded': switch (encoded) {
      CodecSuccess<EncodedDocument>() => _encodedObservation(codec, encoded),
      _ => {'outcome': encoded.runtimeType.toString()},
    },
    'extensions': decoded.value.extensions.values,
    'fidelity': decoded.fidelity.name,
    'outcome': 'success',
    'schema': {
      'id': decoded.value.schema.id.value,
      'version': decoded.value.schema.version.value,
    },
    'system': {
      'type': decoded.value.systemKey.type.value,
      'variant': decoded.value.systemKey.variant.value,
    },
  };
}

Map<String, Object?> _encodedObservation(
  DocumentCodecCapability<Object> codec,
  CodecSuccess<EncodedDocument> encoded,
) {
  final replay = codec.decode(
    DocumentPayload(
      bytes: encoded.value.bytes,
      filename: encoded.value.filename,
      mimeType: encoded.value.mimeType,
    ),
  );
  return {
    'fidelity': encoded.fidelity.name,
    'filename': encoded.value.filename,
    'mimeType': encoded.value.mimeType,
    'replay': switch (replay) {
      CodecSuccess<InteroperableDocument<Object>>() => {
          'document': _documentJson(replay.value.document),
          'extensions': replay.value.extensions.values,
          'fidelity': replay.fidelity.name,
          'outcome': 'success',
        },
      _ => {'outcome': replay.runtimeType.toString()},
    },
  };
}

Object? _documentJson(Object document) {
  try {
    return (document as dynamic).toJson();
  } on NoSuchMethodError {
    return document.toString();
  }
}

Object? _canonicalize(Object? value) {
  if (value is num) {
    return value.toDouble().toStringAsPrecision(17);
  }
  if (value is Map) {
    final entries = value.entries.toList()
      ..sort(
        (left, right) => left.key.toString().compareTo(right.key.toString()),
      );
    return <String, Object?>{
      for (final entry in entries)
        entry.key.toString(): _canonicalize(entry.value),
    };
  }
  if (value is Set) {
    final result = value.map(_canonicalize).toList()
      ..sort((left, right) => jsonEncode(left).compareTo(jsonEncode(right)));
    return result;
  }
  if (value is List) return value.map(_canonicalize).toList();
  return value;
}
