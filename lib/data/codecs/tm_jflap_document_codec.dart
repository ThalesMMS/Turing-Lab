import 'package:xml/xml.dart';

import '../../core/formal_systems/formal_systems.dart';
import '../../core/interoperability/interoperability.dart';
import '../../core/models/tm.dart';
import 'codec_utils.dart';
import 'hardened_xml.dart';
import 'tm/tm_building_block_xml_codec.dart';
import 'tm/tm_jflap_metadata.dart';
import 'tm/tm_jflap_xml_decoder.dart';
import 'tm/tm_jflap_xml_encoder.dart';
import 'tm_jflap_messages.dart';
import 'tm_json_document_codec.dart';

/// Loss-aware JFLAP XML codec for Turing machines and building blocks.
///
/// Facade: sniffing plus document-level dispatch. Classic documents go to
/// [TmJflapXmlDecoder]/[TmJflapXmlEncoder], building-block projects to
/// [TmBuildingBlockXmlCodec]; tape vectors and Turing Lab metadata live in
/// `tm/tm_tape_vector_codec.dart` and `tm/tm_jflap_metadata.dart`.
final class TmJflapDocumentCodec implements DocumentCodecCapability<Object> {
  const TmJflapDocumentCodec();

  @override
  CodecDescriptor get descriptor => CodecDescriptor(
    codecId: const DocumentCodecId('tm.jflap-xml.v1'),
    namespace: const CapabilityNamespaceId('codec.tm.jflap-xml'),
    systemKey: DefaultFormalSystemIds.tm,
    formatId: DefaultFormalSystemIds.jflapXmlFormat,
    schemas: DocumentSchemaRange(minimum: 1, maximum: 1),
    directions: const {
      DocumentFormatDirection.importDocument,
      DocumentFormatDirection.exportDocument,
    },
    priority: 110,
    compatibilityOwner: 'Turing Lab interoperability / JFLAP TM XML',
    canonicalFixtures: const [
      'test/fixtures/interoperability/tm_multi_canonical.jff',
    ],
    semanticCapabilities: {
      CodecSemanticCapabilityId.stateIds,
      CodecSemanticCapabilityId.stateNames,
      CodecSemanticCapabilityId.statePositions,
      CodecSemanticCapabilityId.stateLabels,
      CodecSemanticCapabilityId.initialStates,
      CodecSemanticCapabilityId.acceptingStates,
      CodecSemanticCapabilityId.transitionLabels,
      CodecSemanticCapabilityId.tapeOperations,
      CodecSemanticCapabilityId.buildingBlocks,
      CodecSemanticCapabilityId.extensions,
      CodecSemanticCapabilityId.notes,
    },
    knownUnsupportedFields: const {
      'standard JFLAP document and transition IDs',
      'standard JFLAP declared alphabets and custom blank symbols',
      'standard JFLAP viewport and revision timestamps',
      'JFLAP wildcard, negated, and variable read predicates',
    },
  );

  @override
  CodecSniffResult sniff(DocumentPayload payload) {
    if (payload.bytes.length > descriptor.securityLimits.maximumBytes) {
      return CodecSniffResult.none;
    }
    try {
      final source = utf8Payload(payload);
      final prefix = source.substring(0, source.length.clamp(0, 8192));
      final recognized =
          RegExp(
            r'<type\s*>\s*turing\s*</type\s*>',
            caseSensitive: false,
          ).hasMatch(prefix) ||
          RegExp(
            r'''<structure\b[^>]*\btype\s*=\s*["']turing["']''',
            caseSensitive: false,
          ).hasMatch(prefix);
      return recognized
          ? CodecSniffResult(
              confidence: 100,
              detectedSystem: DefaultFormalSystemIds.tm,
              detectedSchemaVersion: 1,
            )
          : CodecSniffResult.none;
    } catch (_) {
      return CodecSniffResult.none;
    }
  }

  @override
  CodecOutcome<InteroperableDocument<Object>> decode(DocumentPayload payload) {
    final parsed = parseHardenedXml(payload, descriptor.securityLimits);
    if (parsed is! CodecSuccess<XmlDocument>) {
      return TmJflapMetadata.copyXmlFailure(parsed);
    }
    final root = parsed.value.rootElement;
    if (root.name.local != 'structure') {
      return CodecMalformed(
        reason: CodecMalformedReason.invalidValue,
        message: 'JFLAP XML root must be <structure>.',
        location: CodecSourceLocation(path: '/'),
        structuredMessage: TmJflapMessages.invalidRoot(),
      );
    }
    final type =
        root.getElement('type')?.innerText.trim() ??
        root.getAttribute('type')?.trim();
    if (type?.toLowerCase() != 'turing') {
      return CodecUnsupported(
        reason: CodecUnsupportedReason.document,
        message: 'JFLAP document type ${type ?? '(missing)'} is not TM.',
        structuredMessage: TmJflapMessages.unsupportedDocumentType(
          type ?? '(missing)',
        ),
      );
    }
    final hasBuildingBlockExtensions = root.descendants
        .whereType<XmlElement>()
        .any((element) => element.getAttribute('turingLabBlockId') != null);
    if (root.findAllElements('block').isNotEmpty ||
        hasBuildingBlockExtensions) {
      return TmBuildingBlockXmlCodec.decode(root, descriptor);
    }
    return TmJflapXmlDecoder.decode(root, descriptor);
  }

  @override
  CodecOutcome<EncodedDocument> encode(
    InteroperableDocument<Object> document, {
    String? filename,
  }) {
    if (document.systemKey != DefaultFormalSystemIds.tm ||
        document.document is! TM) {
      return CodecUnsupported(
        reason: CodecUnsupportedReason.document,
        message: 'TM JFLAP codec requires a TM document.',
        structuredMessage: TmJflapMessages.requiresTmDocument(),
      );
    }
    if (document.schema != TmJsonDocumentCodec.schema) {
      return CodecUnsupported(
        reason: CodecUnsupportedReason.schema,
        message: 'TM JFLAP codec requires turing-lab.tm schema version 1.',
        structuredMessage: TmJflapMessages.unsupportedSchema(
          document.schema.version.value,
        ),
      );
    }
    final machine = document.document as TM;
    if (machine.blockDefinitions.isNotEmpty ||
        machine.blockInvocations.isNotEmpty) {
      return TmBuildingBlockXmlCodec.encode(
        document,
        machine,
        filename: filename,
      );
    }
    return TmJflapXmlEncoder.encode(document, machine, filename: filename);
  }
}
