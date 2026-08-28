import 'dart:convert';

import '../formal_systems/default_formal_system_modules.dart';
import 'codec_descriptor.dart';
import 'codec_outcome.dart';
import 'codec_source.dart';

final class CodecPayloadPreScanLimit {
  const CodecPayloadPreScanLimit({
    required this.kind,
    required this.maximum,
    required this.actual,
  });

  final CodecResourceLimitKind kind;
  final int maximum;
  final int actual;
}

/// Applies bounded lexical checks before an untrusted codec sniffer runs.
CodecPayloadPreScanLimit? preScanCodecPayload(
  DocumentPayload payload,
  CodecDescriptor descriptor,
) {
  String source;
  try {
    source = utf8.decode(payload.bytes);
  } on FormatException {
    return null;
  }
  if (descriptor.formatId == DefaultFormalSystemIds.turingLabJsonFormat) {
    return _preScanJson(source, descriptor.securityLimits);
  }
  if (descriptor.formatId == DefaultFormalSystemIds.jflapXmlFormat) {
    return _preScanXml(source, descriptor.securityLimits);
  }
  return null;
}

CodecPayloadPreScanLimit? _preScanJson(
  String source,
  CodecSecurityLimits limits,
) {
  var inString = false;
  var escaped = false;
  var maximumDepth = 0;
  var collectionEntries = 0;
  final frames = <String>[];
  final arrayExpectsValue = <bool>[];
  for (var index = 0; index < source.length; index++) {
    final code = source.codeUnitAt(index);
    if (inString) {
      if (escaped) {
        escaped = false;
      } else if (code == 0x5c) {
        escaped = true;
      } else if (code == 0x22) {
        inString = false;
      }
      continue;
    }
    if (code == 0x22) {
      _markArrayValue(frames, arrayExpectsValue, () => collectionEntries++);
      inString = true;
      continue;
    }
    if (code == 0x7b || code == 0x5b) {
      _markArrayValue(frames, arrayExpectsValue, () => collectionEntries++);
      frames.add(String.fromCharCode(code));
      arrayExpectsValue.add(code == 0x5b);
      if (frames.length > maximumDepth) maximumDepth = frames.length;
    } else if (code == 0x7d || code == 0x5d) {
      if (frames.isNotEmpty) {
        frames.removeLast();
        arrayExpectsValue.removeLast();
      }
    } else if (code == 0x3a && frames.isNotEmpty && frames.last == '{') {
      collectionEntries++;
    } else if (code == 0x2c && frames.isNotEmpty && frames.last == '[') {
      arrayExpectsValue[arrayExpectsValue.length - 1] = true;
    } else if (!_isJsonWhitespace(code) && code != 0x2c && code != 0x3a) {
      _markArrayValue(frames, arrayExpectsValue, () => collectionEntries++);
    }
    if (maximumDepth > limits.maximumDepth) {
      return CodecPayloadPreScanLimit(
        kind: CodecResourceLimitKind.jsonDepth,
        maximum: limits.maximumDepth,
        actual: maximumDepth,
      );
    }
    if (collectionEntries > limits.maximumCollectionEntries) {
      return CodecPayloadPreScanLimit(
        kind: CodecResourceLimitKind.collectionEntries,
        maximum: limits.maximumCollectionEntries,
        actual: collectionEntries,
      );
    }
  }
  return null;
}

void _markArrayValue(
  List<String> frames,
  List<bool> arrayExpectsValue,
  void Function() increment,
) {
  if (frames.isEmpty || frames.last != '[' || !arrayExpectsValue.last) {
    return;
  }
  increment();
  arrayExpectsValue[arrayExpectsValue.length - 1] = false;
}

bool _isJsonWhitespace(int code) =>
    code == 0x20 || code == 0x09 || code == 0x0a || code == 0x0d;

CodecPayloadPreScanLimit? _preScanXml(
  String source,
  CodecSecurityLimits limits,
) {
  final upper = source.toUpperCase();
  if (upper.contains('<!DOCTYPE') || upper.contains('<!ENTITY')) {
    return const CodecPayloadPreScanLimit(
      kind: CodecResourceLimitKind.xmlDtdOrEntity,
      maximum: 0,
      actual: 1,
    );
  }
  var depth = 0;
  var elements = 0;
  var cursor = 0;
  while (true) {
    final opening = source.indexOf('<', cursor);
    if (opening < 0) break;
    final closing = source.indexOf('>', opening + 1);
    if (closing < 0) break;
    final tag = source.substring(opening + 1, closing).trim();
    cursor = closing + 1;
    if (tag.isEmpty || tag.startsWith('?') || tag.startsWith('!')) {
      continue;
    }
    if (tag.startsWith('/')) {
      if (depth > 0) depth--;
      continue;
    }
    elements++;
    depth++;
    if (elements > limits.maximumElements) {
      return CodecPayloadPreScanLimit(
        kind: CodecResourceLimitKind.xmlElements,
        maximum: limits.maximumElements,
        actual: elements,
      );
    }
    if (depth > limits.maximumDepth) {
      return CodecPayloadPreScanLimit(
        kind: CodecResourceLimitKind.xmlDepth,
        maximum: limits.maximumDepth,
        actual: depth,
      );
    }
    if (tag.endsWith('/')) depth--;
  }
  return null;
}
