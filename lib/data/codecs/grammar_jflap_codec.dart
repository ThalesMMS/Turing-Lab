import 'package:collection/collection.dart';
import 'package:xml/xml.dart';

import '../../core/formal_systems/formal_systems.dart';
import '../../core/interoperability/interoperability.dart';
import '../../core/models/grammar.dart';
import '../../core/models/production.dart';
import 'codec_utils.dart';
import 'grammar_jflap_messages.dart';
import 'hardened_xml.dart';

final class GrammarJflapDocumentCodec
    implements DocumentCodecCapability<Object> {
  const GrammarJflapDocumentCodec();

  @override
  CodecDescriptor get descriptor => CodecDescriptor(
    codecId: const DocumentCodecId('grammar.jflap-xml.v1'),
    namespace: const CapabilityNamespaceId('codec.grammar.jflap-xml'),
    systemKey: DefaultFormalSystemIds.grammar,
    formatId: DefaultFormalSystemIds.jflapXmlFormat,
    schemas: DocumentSchemaRange(minimum: 1, maximum: 1),
    directions: const {
      DocumentFormatDirection.importDocument,
      DocumentFormatDirection.exportDocument,
    },
    priority: 100,
    compatibilityOwner: 'Turing Lab interoperability / JFLAP XML',
    canonicalFixtures: const [
      'test/fixtures/interoperability/grammar_canonical.jff',
    ],
    semanticCapabilities: {
      CodecSemanticCapabilityId.tokenVectors,
      CodecSemanticCapabilityId.extensions,
    },
    knownUnsupportedFields: const {
      'explicit grammar classification',
      'explicit start symbol outside production ordering',
      'multi-character token boundaries',
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
      final grammar =
          RegExp(
            r'<type\s*>\s*grammar\s*</type\s*>',
            caseSensitive: false,
          ).hasMatch(prefix) ||
          RegExp(
            r'''<structure\b[^>]*\btype\s*=\s*["']grammar["']''',
            caseSensitive: false,
          ).hasMatch(prefix);
      return grammar
          ? CodecSniffResult(
              confidence: 100,
              detectedSystem: DefaultFormalSystemIds.grammar,
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
    if (parsed is! CodecSuccess<XmlDocument>) return _copyXmlFailure(parsed);
    final root = parsed.value.rootElement;
    final sourceType =
        root.getElement('type')?.innerText.trim() ??
        root.getAttribute('type')?.trim();
    if (root.name.local != 'structure' ||
        sourceType?.toLowerCase() != 'grammar') {
      return CodecUnsupported(
        reason: CodecUnsupportedReason.document,
        message:
            'JFLAP document type ${sourceType ?? '(missing)'} is not grammar.',
        structuredMessage: GrammarJflapMessages.unsupportedDocumentType(
          sourceType ?? '(missing)',
        ),
      );
    }
    final productionElements = root.findAllElements('production').toList();
    if (productionElements.length >
        descriptor.securityLimits.maximumCollectionEntries) {
      return CodecResourceLimit(
        limit: CodecResourceLimitKind.collectionEntries,
        maximum: descriptor.securityLimits.maximumCollectionEntries,
        actual: productionElements.length,
      );
    }
    if (productionElements.isEmpty) {
      // The structured payload is created at runtime for the presentation
      // boundary, so this constructor cannot be const.
      // ignore: prefer_const_constructors
      return CodecMalformed(
        reason: CodecMalformedReason.missingField,
        message: 'JFLAP grammar contains no productions.',
        location: const CodecSourceLocation(path: '/structure/production'),
        structuredMessage: GrammarJflapMessages.emptyGrammar(),
      );
    }
    final nestedGrammar = root.findElements('grammar').firstOrNull;
    final whitespaceTokenized = nestedGrammar != null;
    final productions = <Production>{};
    final extensions = <String, Object?>{};
    final diagnostics = <CodecDiagnostic>[];
    for (var index = 0; index < productionElements.length; index++) {
      final element = productionElements[index];
      final left = element.findElements('left').firstOrNull;
      final right = element.findElements('right').firstOrNull;
      if (left == null || right == null || left.innerText.trim().isEmpty) {
        return CodecMalformed(
          reason: CodecMalformedReason.missingField,
          message: 'Production $index is missing a non-empty left side.',
          location: CodecSourceLocation(
            path: '/structure/production[$index]/left',
          ),
          structuredMessage: GrammarJflapMessages.missingProductionSide(index),
        );
      }
      final leftTokens = _tokens(left.innerText, whitespaceTokenized);
      final rightTokens = _tokens(right.innerText, whitespaceTokenized);
      productions.add(
        Production(
          id: 'p$index',
          leftSide: leftTokens,
          rightSide: rightTokens,
          isLambda: rightTokens.isEmpty,
          order: index,
        ),
      );
      _preserveAttributes(
        element,
        known: const {},
        key: 'productionAttributes.p$index',
        extensions: extensions,
      );
      _preserveChildren(
        element,
        known: const {'left', 'right'},
        key: 'productionChildren.p$index',
        extensions: extensions,
      );
    }
    final explicitStart = nestedGrammar
        ?.findElements('start')
        .firstOrNull
        ?.innerText
        .trim();
    final startSymbol = explicitStart?.isNotEmpty == true
        ? _tokens(explicitStart!, true).singleOrNull
        : productions.first.leftSide.firstOrNull;
    if (startSymbol == null) {
      // The structured payload is created at runtime for the presentation
      // boundary, so this constructor cannot be const.
      // ignore: prefer_const_constructors
      return CodecMalformed(
        reason: CodecMalformedReason.invalidValue,
        message: 'Grammar start symbol could not be determined.',
        location: const CodecSourceLocation(
          path: '/structure/production[0]/left',
        ),
        structuredMessage: GrammarJflapMessages.startSymbolUndetermined(),
      );
    }
    final nonterminals = <String>{
      startSymbol,
      ...productions.expand((production) => production.leftSide),
    };
    final terminals = productions
        .expand((production) => production.rightSide)
        .where((symbol) => !nonterminals.contains(symbol))
        .toSet();
    final typeName = nestedGrammar?.getAttribute('type');
    final recognizedType = GrammarType.values
        .where((candidate) => candidate.name == typeName)
        .firstOrNull;
    final type = recognizedType ?? GrammarType.contextFree;
    final epoch = DateTime.fromMillisecondsSinceEpoch(0, isUtc: true);
    _preserveAttributes(
      root,
      known: const {'type'},
      key: 'rootAttributes',
      extensions: extensions,
    );
    if (nestedGrammar != null) {
      if (typeName != null && recognizedType == null) {
        extensions['grammarType'] = typeName;
        diagnostics.add(
          CodecDiagnostic(
            code: 'jflap.unknown-grammar-type-preserved',
            message: 'An unknown grammar type was preserved for re-export.',
            path: '/structure/grammar/@type',
            sourceValue: typeName,
            structuredMessage: GrammarJflapMessages.unknownGrammarTypePreserved(
              typeName,
            ),
            disposition: CodecDiagnosticDisposition.dropped,
          ),
        );
      }
      _preserveAttributes(
        nestedGrammar,
        known: const {'type'},
        key: 'grammarAttributes',
        extensions: extensions,
      );
      _preserveChildren(
        nestedGrammar,
        known: const {'start', 'production'},
        key: 'grammarChildren',
        extensions: extensions,
      );
    }
    final knownRoot = {'type', 'grammar', 'production'};
    final unknown = root.childElements
        .where((element) => !knownRoot.contains(element.name.local))
        .map((element) => element.toXmlString())
        .toList();
    if (unknown.isNotEmpty) extensions['rootChildren'] = unknown;
    if (extensions.isNotEmpty) {
      diagnostics.add(
        CodecDiagnostic(
          code: 'jflap.unknown-optional-element',
          message: 'Unknown optional XML data was preserved with provenance.',
          path: 'extensions',
          structuredMessage: GrammarJflapMessages.unknownOptionalElement(
            'extensions',
          ),
        ),
      );
    }
    final source = utf8Payload(payload);
    return CodecSuccess(
      value: InteroperableDocument<Object>(
        document: Grammar(
          id: deterministicContentId('imported_grammar', source),
          name: 'Imported Grammar',
          terminals: terminals,
          nonterminals: nonterminals,
          startSymbol: startSymbol,
          productions: productions,
          type: type,
          created: epoch,
          modified: epoch,
        ),
        systemKey: DefaultFormalSystemIds.grammar,
        schema: descriptorSchema,
        sourceMetadata: const DocumentSourceMetadata(
          application: 'JFLAP',
          sourceFormatVersion: '4+',
        ),
        extensions: DocumentExtensionBag(extensions),
      ),
      fidelity: typeName != null && recognizedType == null
          ? DocumentFidelity.lossy
          : DocumentFidelity.normalized,
      diagnostics: [
        CodecDiagnostic(
          code: 'jflap.grammar-tokenization-normalized',
          message: 'JFLAP grammar text was normalized to token arrays.',
          structuredMessage: GrammarJflapMessages.tokenizationNormalized(),
          disposition: CodecDiagnosticDisposition.normalized,
        ),
        ...diagnostics,
      ],
    );
  }

  @override
  CodecOutcome<EncodedDocument> encode(
    InteroperableDocument<Object> document, {
    String? filename,
  }) {
    if (document.systemKey != DefaultFormalSystemIds.grammar ||
        document.document is! Grammar) {
      return CodecUnsupported(
        reason: CodecUnsupportedReason.document,
        message: 'Grammar JFLAP codec requires a Grammar document.',
        structuredMessage: GrammarJflapMessages.requiresGrammarDocument(),
      );
    }
    if (document.schema.id != descriptorSchema.id ||
        !descriptor.schemas.contains(document.schema.version.value)) {
      return CodecUnsupported(
        reason: CodecUnsupportedReason.schema,
        message: 'Unsupported Grammar schema identity or version.',
        structuredMessage: GrammarJflapMessages.unsupportedSchema(
          document.schema.version.value,
        ),
      );
    }
    final grammar = document.document as Grammar;
    final validation = grammar.validate();
    if (validation.isNotEmpty) {
      return CodecMalformed(
        reason: CodecMalformedReason.invalidValue,
        message: validation.first,
        location: const CodecSourceLocation(path: r'$.document'),
        structuredMessage: GrammarJflapMessages.invalidDocument(),
      );
    }
    final ordered = grammar.productions.toList()
      ..sort((left, right) {
        final startOrder = (left.leftSide.contains(grammar.startSymbol) ? 0 : 1)
            .compareTo(right.leftSide.contains(grammar.startSymbol) ? 0 : 1);
        if (startOrder != 0) return startOrder;
        final order = left.order.compareTo(right.order);
        return order != 0 ? order : left.id.compareTo(right.id);
      });
    final ambiguousTokens =
        ordered
            .expand(
              (production) => [...production.leftSide, ...production.rightSide],
            )
            .where((token) => token.runes.length != 1)
            .toSet()
            .toList()
          ..sort();
    final builder = XmlBuilder();
    builder.processing('xml', 'version="1.0" encoding="UTF-8"');
    builder.element(
      'structure',
      nest: () {
        builder.attribute('type', 'grammar');
        _writeAttributes(builder, document.extensions.values['rootAttributes']);
        builder.element('type', nest: 'grammar');
        final rawExtensions = document.extensions.values['rootChildren'];
        if (rawExtensions is List) {
          for (final xml in rawExtensions.whereType<String>()) {
            builder.xml(xml);
          }
        }
        builder.element(
          'grammar',
          nest: () {
            builder.attribute(
              'type',
              document.extensions.values['grammarType'] as String? ??
                  grammar.type.name,
            );
            _writeAttributes(
              builder,
              document.extensions.values['grammarAttributes'],
            );
            builder.element('start', nest: grammar.startSymbol);
            _writeChildren(
              builder,
              document.extensions.values['grammarChildren'],
            );
            for (final production in ordered) {
              builder.element(
                'production',
                nest: () {
                  _writeAttributes(
                    builder,
                    document
                        .extensions
                        .values['productionAttributes.${production.id}'],
                  );
                  builder.element('left', nest: production.leftSide.join());
                  if (production.rightSide.isEmpty) {
                    builder.element('right', isSelfClosing: true);
                  } else {
                    builder.element('right', nest: production.rightSide.join());
                  }
                  _writeChildren(
                    builder,
                    document
                        .extensions
                        .values['productionChildren.${production.id}'],
                  );
                },
              );
            }
          },
        );
      },
    );
    final xml = builder.buildDocument().toXmlString(pretty: true);
    final lossy =
        ambiguousTokens.isNotEmpty || grammar.type != GrammarType.contextFree;
    return CodecSuccess(
      value: EncodedDocument(
        bytes: utf8Bytes('$xml\n'),
        mimeType: 'application/xml',
        filename: filenameWithExtension(filename, 'grammar', 'jff'),
        schema: descriptorSchema,
      ),
      fidelity: lossy ? DocumentFidelity.lossy : DocumentFidelity.normalized,
      diagnostics: [
        if (ambiguousTokens.isNotEmpty)
          CodecDiagnostic(
            code: 'jflap.grammar-token-boundaries-lossy',
            message:
                'JFLAP XML cannot preserve multi-character token boundaries.',
            path: r'$.productions',
            sourceValue: ambiguousTokens,
            structuredMessage: GrammarJflapMessages.tokenBoundariesLossy(
              ambiguousTokens.join(', '),
            ),
            disposition: CodecDiagnosticDisposition.dropped,
          ),
        if (grammar.type != GrammarType.contextFree)
          CodecDiagnostic(
            code: 'jflap.grammar-classification-lossy',
            message:
                'JFLAP XML does not store the explicit grammar classification.',
            path: r'$.type',
            sourceValue: grammar.type.name,
            structuredMessage: GrammarJflapMessages.classificationLossy(
              grammar.type.name,
            ),
            disposition: CodecDiagnosticDisposition.dropped,
          ),
      ],
    );
  }

  static const descriptorSchema = DocumentSchemaDescriptor(
    id: DocumentSchemaId('turing-lab.grammar'),
    version: DocumentSchemaVersion(1),
  );
}

List<String> _tokens(String value, bool whitespaceTokenized) {
  final trimmed = value.trim();
  if (trimmed.isEmpty) return const [];
  if (whitespaceTokenized && RegExp(r'\s').hasMatch(trimmed)) {
    return trimmed.split(RegExp(r'\s+'));
  }
  return trimmed.runes.map(String.fromCharCode).toList(growable: false);
}

void _preserveAttributes(
  XmlElement element, {
  required Set<String> known,
  required String key,
  required Map<String, Object?> extensions,
}) {
  final values = <String, String>{};
  for (final attribute in element.attributes) {
    if (!known.contains(attribute.name.local)) {
      values[attribute.name.qualified] = attribute.value;
    }
  }
  if (values.isNotEmpty) extensions[key] = values;
}

void _preserveChildren(
  XmlElement element, {
  required Set<String> known,
  required String key,
  required Map<String, Object?> extensions,
}) {
  final values = element.childElements
      .where((child) => !known.contains(child.name.local))
      .map((child) => child.toXmlString())
      .toList(growable: false);
  if (values.isNotEmpty) extensions[key] = values;
}

void _writeAttributes(XmlBuilder builder, Object? raw) {
  if (raw is! Map) return;
  final entries = raw.entries.toList()
    ..sort(
      (left, right) => left.key.toString().compareTo(right.key.toString()),
    );
  for (final entry in entries) {
    builder.attribute(entry.key.toString(), entry.value.toString());
  }
}

void _writeChildren(XmlBuilder builder, Object? raw) {
  if (raw is! List) return;
  for (final value in raw.whereType<String>()) {
    builder.xml(value);
  }
}

CodecOutcome<InteroperableDocument<Object>> _copyXmlFailure(
  CodecOutcome<XmlDocument> outcome,
) {
  return switch (outcome) {
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
    CodecResourceLimit(:final limit, :final maximum, :final actual) =>
      CodecResourceLimit(limit: limit, maximum: maximum, actual: actual),
    CodecInternalFailure(
      :final stage,
      :final message,
      :final cause,
      :final structuredMessage,
    ) =>
      CodecInternalFailure(
        stage: stage,
        message: message,
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
    CodecAmbiguous(:final codecIds) => CodecAmbiguous(codecIds: codecIds),
    CodecSuccess() => throw StateError('Cannot copy successful XML result'),
  };
}
