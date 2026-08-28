import 'dart:convert';

import '../../core/formal_systems/formal_systems.dart';
import '../../core/grammar/phrase_structure/phrase_structure.dart';
import '../../core/interoperability/interoperability.dart';
import 'codec_json_security.dart';
import 'codec_utils.dart';

final class UnrestrictedGrammarJsonCodec
    implements DocumentCodecCapability<Object> {
  const UnrestrictedGrammarJsonCodec();

  @override
  CodecDescriptor get descriptor => CodecDescriptor(
        codecId: const DocumentCodecId(
          'unrestricted-grammar.turing-lab-json.v1',
        ),
        namespace: const CapabilityNamespaceId(
          'codec.grammar.unrestricted.turing-lab-json',
        ),
        systemKey: UnrestrictedGrammarCapabilities.systemKey,
        formatId: DefaultFormalSystemIds.turingLabJsonFormat,
        schemas: DocumentSchemaRange(minimum: 1, maximum: 1),
        directions: const {
          DocumentFormatDirection.importDocument,
          DocumentFormatDirection.exportDocument,
        },
        priority: 110,
        compatibilityOwner: 'Turing Lab unrestricted grammar JSON',
        canonicalFixtures: const [
          'test/fixtures/interoperability/unrestricted_grammar_canonical.json',
        ],
        semanticCapabilities: {
          CodecSemanticCapabilityId.tokenVectors,
          CodecSemanticCapabilityId.extensions,
        },
        knownUnsupportedFields: const {},
      );

  @override
  CodecSniffResult sniff(DocumentPayload payload) {
    if (payload.bytes.length > descriptor.securityLimits.maximumBytes) {
      return CodecSniffResult.none;
    }
    try {
      final source = utf8Payload(payload);
      final depth = codecJsonLexicalDepth(source);
      if (depth > descriptor.securityLimits.maximumDepth) {
        return CodecSniffResult.none;
      }
      final decoded = jsonDecode(source);
      if (decoded is! Map) return CodecSniffResult.none;
      final schema = decoded['schema'];
      if (schema is Map &&
          schema['id'] == 'turing-lab.unrestricted-grammar' &&
          schema['version'] == 1) {
        return CodecSniffResult(
          confidence: 100,
          detectedSystem: UnrestrictedGrammarCapabilities.systemKey,
          detectedSchemaVersion: 1,
        );
      }
    } catch (_) {}
    return CodecSniffResult.none;
  }

  @override
  CodecOutcome<InteroperableDocument<Object>> decode(DocumentPayload payload) {
    if (payload.bytes.length > descriptor.securityLimits.maximumBytes) {
      return CodecResourceLimit(
        limit: CodecResourceLimitKind.bytes,
        maximum: descriptor.securityLimits.maximumBytes,
        actual: payload.bytes.length,
      );
    }
    try {
      final source = utf8Payload(payload);
      final depth = codecJsonLexicalDepth(source);
      if (depth > descriptor.securityLimits.maximumDepth) {
        return CodecResourceLimit(
          limit: CodecResourceLimitKind.jsonDepth,
          maximum: descriptor.securityLimits.maximumDepth,
          actual: depth,
        );
      }
      final decoded = jsonDecode(source);
      final entries = codecJsonCollectionEntries(decoded);
      if (entries > descriptor.securityLimits.maximumCollectionEntries) {
        return CodecResourceLimit(
          limit: CodecResourceLimitKind.collectionEntries,
          maximum: descriptor.securityLimits.maximumCollectionEntries,
          actual: entries,
        );
      }
      if (decoded is! Map) {
        return const CodecMalformed(
          reason: CodecMalformedReason.invalidValue,
          message: 'Unrestricted grammar JSON must be an object.',
          location: CodecSourceLocation(path: r'$'),
        );
      }
      final map = Map<String, Object?>.from(decoded);
      final rawSchema = map['schema'];
      if (rawSchema is! Map ||
          rawSchema['id'] is! String ||
          rawSchema['version'] is! int) {
        return const CodecMalformed(
          reason: CodecMalformedReason.invalidValue,
          message: 'Unrestricted grammar schema must contain id and version.',
          location: CodecSourceLocation(path: r'$.schema'),
        );
      }
      if (rawSchema['id'] != UnrestrictedGrammarCapabilities.schema.id.value ||
          !descriptor.schemas.contains(rawSchema['version'] as int)) {
        return CodecUnsupported(
          reason: CodecUnsupportedReason.schema,
          message: 'Unsupported unrestricted grammar schema '
              '${rawSchema['id']}@${rawSchema['version']}.',
        );
      }
      final grammar = UnrestrictedGrammar.fromJson(map);
      final invalid = _invalidGrammar(grammar);
      if (invalid != null) return invalid;
      final known = {
        'schema',
        'id',
        'name',
        'revision',
        'terminals',
        'nonterminals',
        'startSymbol',
        'productions',
      };
      final extensions = <String, Object?>{
        for (final entry in map.entries)
          if (!known.contains(entry.key)) entry.key: entry.value,
      };
      return CodecSuccess(
        value: InteroperableDocument<Object>(
          document: grammar,
          systemKey: UnrestrictedGrammarCapabilities.systemKey,
          schema: UnrestrictedGrammarCapabilities.schema,
          extensions: DocumentExtensionBag(extensions),
        ),
        fidelity: DocumentFidelity.exact,
      );
    } on FormatException catch (error) {
      return CodecMalformed(
        reason: CodecMalformedReason.invalidValue,
        message: error.message,
        location: const CodecSourceLocation(path: r'$'),
        cause: error,
      );
    } catch (error) {
      return CodecMalformed(
        message: 'Malformed unrestricted grammar JSON.',
        cause: error,
      );
    }
  }

  @override
  CodecOutcome<EncodedDocument> encode(
    InteroperableDocument<Object> document, {
    String? filename,
  }) {
    if (document.systemKey != UnrestrictedGrammarCapabilities.systemKey ||
        document.schema != UnrestrictedGrammarCapabilities.schema ||
        document.document is! UnrestrictedGrammar) {
      return const CodecUnsupported(
        reason: CodecUnsupportedReason.document,
        message: 'Expected an unrestricted grammar document.',
      );
    }
    final grammar = document.document as UnrestrictedGrammar;
    final invalid = _invalidGrammar(grammar);
    if (invalid != null) return invalid;
    final payload = <String, Object?>{
      ...grammar.toJson(),
      ...document.extensions.values,
    };
    return CodecSuccess(
      value: EncodedDocument(
        bytes: utf8Bytes('${canonicalJson(payload)}\n'),
        mimeType: 'application/json',
        filename: filenameWithExtension(
          filename,
          'unrestricted-grammar',
          'json',
        ),
        schema: UnrestrictedGrammarCapabilities.schema,
      ),
      fidelity: DocumentFidelity.exact,
    );
  }
}

CodecMalformed<Never>? _invalidGrammar(UnrestrictedGrammar grammar) {
  final report = PhraseGrammarClassifier.classify(grammar);
  if (report.isValid) return null;
  final diagnostic = report.errors.first;
  return CodecMalformed(
    reason: diagnostic.code ==
                PhraseGrammarDiagnosticCode.duplicateProductionId ||
            diagnostic.code == PhraseGrammarDiagnosticCode.duplicateProduction
        ? CodecMalformedReason.duplicateIdentity
        : CodecMalformedReason.invalidValue,
    message: 'Invalid unrestricted grammar: ${diagnostic.code.name}.',
    location: CodecSourceLocation(
      path: diagnostic.productionId == null
          ? r'$.document'
          : r'$.document.productions',
    ),
  );
}
