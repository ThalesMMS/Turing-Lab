import 'dart:convert';

import 'package:xml/xml.dart';
import 'package:xml/xml_events.dart';

import '../../core/interoperability/interoperability.dart';

CodecOutcome<XmlDocument> parseHardenedXml(
  DocumentPayload payload,
  CodecSecurityLimits limits,
) {
  if (payload.bytes.length > limits.maximumBytes) {
    return CodecResourceLimit(
      limit: CodecResourceLimitKind.bytes,
      maximum: limits.maximumBytes,
      actual: payload.bytes.length,
    );
  }
  late final String source;
  try {
    source = utf8.decode(payload.bytes);
  } on FormatException catch (error) {
    return CodecMalformed(
      reason: CodecMalformedReason.invalidUtf8,
      message: 'XML is not valid UTF-8.',
      location: CodecSourceLocation(offset: error.offset),
      cause: error,
    );
  }
  final unsafe = RegExp(
    r'<!\s*(DOCTYPE|ENTITY)\b',
    caseSensitive: false,
  ).firstMatch(source);
  if (unsafe != null) {
    return const CodecResourceLimit(
      limit: CodecResourceLimitKind.xmlDtdOrEntity,
      maximum: 0,
      actual: 1,
    );
  }
  late final ({int maximumDepth, int elements}) shape;
  try {
    shape = _scanShape(source);
  } on XmlFormatException catch (error) {
    return _malformedXml(error, payload);
  }
  if (shape.maximumDepth > limits.maximumDepth) {
    return CodecResourceLimit(
      limit: CodecResourceLimitKind.xmlDepth,
      maximum: limits.maximumDepth,
      actual: shape.maximumDepth,
    );
  }
  if (shape.elements > limits.maximumElements) {
    return CodecResourceLimit(
      limit: CodecResourceLimitKind.xmlElements,
      maximum: limits.maximumElements,
      actual: shape.elements,
    );
  }
  try {
    return CodecSuccess(
      value: XmlDocument.parse(source),
      fidelity: DocumentFidelity.exact,
    );
  } on XmlFormatException catch (error) {
    return _malformedXml(error, payload);
  } catch (error) {
    return CodecMalformed(message: 'Malformed XML document.', cause: error);
  }
}

({int maximumDepth, int elements}) _scanShape(String source) {
  var depth = 0;
  var maximumDepth = 0;
  var elements = 0;
  for (final event in parseEvents(
    source,
    validateNesting: true,
    validateDocument: true,
  )) {
    if (event is XmlEndElementEvent) {
      if (depth > 0) depth--;
      continue;
    }
    if (event is! XmlStartElementEvent) continue;
    elements++;
    depth++;
    if (depth > maximumDepth) maximumDepth = depth;
    if (event.isSelfClosing) depth--;
  }
  return (maximumDepth: maximumDepth, elements: elements);
}

CodecMalformed<XmlDocument> _malformedXml(
  XmlFormatException error,
  DocumentPayload payload,
) =>
    CodecMalformed(
      message: error.message,
      location: CodecSourceLocation(
        offset: error.position,
        line: error.line,
        column: error.column,
        path: payload.sourcePath,
      ),
      cause: error,
    );
