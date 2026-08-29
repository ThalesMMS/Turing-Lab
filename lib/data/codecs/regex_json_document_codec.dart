import 'dart:convert';

import '../../core/algorithms/regex_to_nfa_converter.dart';
import '../../core/formal_systems/formal_systems.dart';
import '../../core/interoperability/interoperability.dart';
import '../../core/models/regex_document.dart';
import 'codec_utils.dart';
import 'regex_json_messages.dart';
import 'versioned_json_document_codec.dart';

/// Canonical, versioned Turing Lab JSON codec for Regex documents.
final class RegexJsonDocumentCodec implements DocumentCodecCapability<Object> {
  RegexJsonDocumentCodec()
    : _delegate = VersionedJsonDocumentCodec(
        systemKey: DefaultFormalSystemIds.regex,
        schema: schema,
        codecId: const DocumentCodecId('regex.turing-lab-json.v1'),
        namespace: const CapabilityNamespaceId('codec.regex.turing-lab-json'),
        fixture: 'test/fixtures/interoperability/regex_canonical.json',
        encodePayload: _encodePayload,
        decodePayload: RegexDocument.fromJson,
        isLegacyPayload: (payload) => payload['currentRegex'] is String,
        knownPayloadFields: const {
          'id',
          'name',
          'source',
          'dialect',
          'tokenization',
          'alphabet',
          'epsilonSymbol',
          'emptyLanguageSymbol',
          'sourceOfTruth',
          'canonicalAst',
        },
        semanticCapabilities: {
          CodecSemanticCapabilityId.tokenVectors,
          CodecSemanticCapabilityId.extensions,
        },
      );

  static const schema = DocumentSchemaDescriptor(
    id: DocumentSchemaId('turing-lab.regex'),
    version: DocumentSchemaVersion(1),
  );

  final VersionedJsonDocumentCodec _delegate;

  @override
  CodecDescriptor get descriptor => _delegate.descriptor;

  @override
  CodecSniffResult sniff(DocumentPayload payload) => _delegate.sniff(payload);

  @override
  CodecOutcome<InteroperableDocument<Object>> decode(DocumentPayload payload) {
    final outcome = _delegate.decode(payload);
    if (outcome is! CodecSuccess<InteroperableDocument<Object>>) return outcome;
    final document = outcome.value.document;
    if (document is! RegexDocument) {
      return CodecInternalFailure(
        stage: CodecInternalFailureStage.decode,
        message: 'Regex JSON decoder returned an unexpected document type.',
        structuredMessage: RegexJsonMessages.unexpectedDecoderType(),
      );
    }
    final validation = _validateDocument(document);
    if (validation != null) return validation;

    final raw = _documentPayload(payload);
    if (raw == null) return outcome;
    if (raw['sourceOfTruth'] case final Object value when value != 'source') {
      return CodecMalformed(
        reason: CodecMalformedReason.invalidValue,
        message: 'Regex sourceOfTruth must be "source".',
        location: const CodecSourceLocation(
          path: r'$.document.payload.sourceOfTruth',
        ),
        structuredMessage: RegexJsonMessages.sourceOfTruthInvalid(),
      );
    }
    if (raw.containsKey('canonicalAst')) {
      final expected = _canonicalAst(document.source);
      if (canonicalJson({'ast': raw['canonicalAst']}) !=
          canonicalJson({'ast': expected})) {
        return CodecMalformed(
          reason: CodecMalformedReason.invalidValue,
          message: 'Regex canonical AST does not match the source expression.',
          location: const CodecSourceLocation(
            path: r'$.document.payload.canonicalAst',
          ),
          structuredMessage: RegexJsonMessages.canonicalAstMismatch(),
        );
      }
    }
    return outcome;
  }

  @override
  CodecOutcome<EncodedDocument> encode(
    InteroperableDocument<Object> document, {
    String? filename,
  }) {
    final value = document.document;
    if (value is! RegexDocument) {
      return CodecUnsupported(
        reason: CodecUnsupportedReason.document,
        message: 'Expected a Regex document.',
        structuredMessage: RegexJsonMessages.expectedRegexDocument(),
      );
    }
    final validation = _validateDocument(value);
    if (validation != null) return _copyFailure(validation);
    return _delegate.encode(document, filename: filename);
  }
}

Map<String, Object?> _encodePayload(Object value) {
  if (value is! RegexDocument) throw const FormatException('Expected Regex.');
  return {
    ...value.toJson(),
    'sourceOfTruth': 'source',
    'canonicalAst': _canonicalAst(value.source),
  };
}

CodecOutcome<InteroperableDocument<Object>>? _validateDocument(
  RegexDocument document,
) {
  final error = document.validate().firstOrNull;
  if (error != null) {
    return CodecMalformed(
      reason: CodecMalformedReason.invalidValue,
      message: error,
      structuredMessage: RegexJsonMessages.invalidDocument(),
    );
  }
  if (document.epsilonSymbol != 'ε' || document.emptyLanguageSymbol != '∅') {
    return CodecUnsupported(
      reason: CodecUnsupportedReason.document,
      message:
          'This Regex dialect requires ε for epsilon and ∅ for the empty language.',
      structuredMessage: RegexJsonMessages.unsupportedDialect(),
    );
  }
  if (document.source.isNotEmpty &&
      !RegexToNFAConverter.validate(document.source).isValid) {
    return CodecMalformed(
      reason: CodecMalformedReason.invalidValue,
      message: RegexToNFAConverter.validate(
        document.source,
      ).diagnostic!.displayMessage,
      location: const CodecSourceLocation(path: r'$.document.payload.source'),
      structuredMessage: RegexJsonMessages.invalidSource(),
    );
  }
  return null;
}

Object? _canonicalAst(String source) {
  if (source.isEmpty) return null;
  final node = RegexToNFAConverter.parse(source);
  if (node == null) return null;
  return _encodeNode(node);
}

Map<String, Object?> _encodeNode(RegexNode node) => switch (node) {
  SymbolNode(:final symbol) => {'type': 'symbol', 'symbol': symbol},
  DotNode() => {'type': 'wildcard'},
  EpsilonNode() => {'type': 'epsilon'},
  EmptyLanguageNode() => {'type': 'emptyLanguage'},
  SetNode(:final symbols) => {
    'type': 'set',
    'symbols': symbols.toList()..sort(),
  },
  ShortcutNode(:final code) => {'type': 'shortcut', 'code': code},
  UnionNode(:final left, :final right) => {
    'type': 'union',
    'left': _encodeNode(left),
    'right': _encodeNode(right),
  },
  ConcatenationNode(:final left, :final right) => {
    'type': 'concatenation',
    'left': _encodeNode(left),
    'right': _encodeNode(right),
  },
  KleeneStarNode(:final child) => {'type': 'star', 'child': _encodeNode(child)},
  PlusNode(:final child) => {'type': 'plus', 'child': _encodeNode(child)},
  QuestionNode(:final child) => {
    'type': 'question',
    'child': _encodeNode(child),
  },
  _ => throw FormatException('Unknown Regex AST node: ${node.runtimeType}'),
};

Map<String, dynamic>? _documentPayload(DocumentPayload payload) {
  try {
    final root = jsonDecode(utf8Payload(payload));
    if (root is! Map) return null;
    final json = root.cast<String, dynamic>();
    if (json['format'] == VersionedJsonDocumentCodec.envelopeFormat) {
      final document = json['document'];
      if (document is! Map || document['payload'] is! Map) return null;
      return Map<String, dynamic>.from(document['payload'] as Map);
    }
    return json;
  } catch (_) {
    return null;
  }
}

CodecOutcome<EncodedDocument> _copyFailure(
  CodecOutcome<InteroperableDocument<Object>> outcome,
) => switch (outcome) {
  CodecMalformed(
    :final reason,
    :final message,
    :final location,
    :final cause,
    :final structuredMessage,
  ) =>
    CodecMalformed(
      reason: reason,
      message: message,
      location: location,
      cause: cause,
      structuredMessage: structuredMessage,
    ),
  CodecUnsupported(
    :final reason,
    :final message,
    :final roadmapIssue,
    :final structuredMessage,
  ) =>
    CodecUnsupported(
      reason: reason,
      message: message,
      roadmapIssue: roadmapIssue,
      structuredMessage: structuredMessage,
    ),
  _ => CodecInternalFailure(
    stage: CodecInternalFailureStage.encode,
    message: 'Unexpected Regex validation outcome.',
    structuredMessage: RegexJsonMessages.unexpectedValidationOutcome(),
  ),
};

extension on List<String> {
  String? get firstOrNull => isEmpty ? null : first;
}
