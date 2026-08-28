import 'dart:convert';

import 'package:collection/collection.dart';
import 'package:xml/xml.dart';

import '../../core/formal_systems/formal_systems.dart';
import '../../core/grammar/phrase_structure/phrase_structure.dart';
import '../../core/interoperability/interoperability.dart';
import 'codec_utils.dart';
import 'hardened_xml.dart';

final class UnrestrictedGrammarJflapCodec
    implements DocumentCodecCapability<Object> {
  const UnrestrictedGrammarJflapCodec();

  @override
  CodecDescriptor get descriptor => CodecDescriptor(
        codecId: const DocumentCodecId('unrestricted-grammar.jflap-xml.v1'),
        namespace: const CapabilityNamespaceId(
          'codec.grammar.unrestricted.jflap-xml',
        ),
        systemKey: UnrestrictedGrammarCapabilities.systemKey,
        formatId: DefaultFormalSystemIds.jflapXmlFormat,
        schemas: DocumentSchemaRange(minimum: 1, maximum: 1),
        directions: const {
          DocumentFormatDirection.importDocument,
          DocumentFormatDirection.exportDocument,
        },
        priority: 120,
        compatibilityOwner: 'JFLAP 7.1 GrammarTransducer',
        canonicalFixtures: const [
          'test/fixtures/interoperability/unrestricted_grammar_canonical.jff',
        ],
        semanticCapabilities: {
          CodecSemanticCapabilityId.tokenVectors,
          CodecSemanticCapabilityId.extensions,
        },
        knownUnsupportedFields: const {
          'standard JFLAP token boundaries',
          'standard JFLAP production IDs and ordering',
          'standard JFLAP declared alphabets and start symbol',
          'standard JFLAP document metadata and revision',
        },
      );

  @override
  CodecSniffResult sniff(DocumentPayload payload) {
    try {
      final prefix = utf8Payload(payload);
      return RegExp(
        r'<type\s*>\s*grammar\s*</type\s*>',
        caseSensitive: false,
      ).hasMatch(prefix.substring(0, prefix.length.clamp(0, 8192)))
          ? CodecSniffResult(
              confidence: 95,
              detectedSystem: UnrestrictedGrammarCapabilities.systemKey,
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
    if (parsed is! CodecSuccess<XmlDocument>) return copyXmlFailure(parsed);
    final root = parsed.value.rootElement;
    final type = root.getElement('type')?.innerText.trim();
    if (root.name.local != 'structure' || type != 'grammar') {
      return const CodecUnsupported(
        reason: CodecUnsupportedReason.document,
        message: 'Expected a JFLAP grammar document.',
      );
    }
    final elements = root.findElements('production').toList();
    if (elements.isEmpty) {
      return const CodecMalformed(
        reason: CodecMalformedReason.missingField,
        message: 'JFLAP grammar contains no productions.',
        location: CodecSourceLocation(path: '/structure/production'),
      );
    }
    final extension = root.findElements('turingLabGrammar').firstOrNull;
    try {
      final declaration =
          extension == null ? null : _decodeDeclaration(extension);
      final provisional = <PhraseStructureProduction>[];
      for (var index = 0; index < elements.length; index++) {
        final element = elements[index];
        final leftElement = element.findElements('left').firstOrNull;
        final rightElement = element.findElements('right').firstOrNull;
        if (leftElement == null || rightElement == null) {
          return CodecMalformed(
            reason: CodecMalformedReason.missingField,
            message: 'Production $index is missing a side.',
            location: CodecSourceLocation(
              path: '/structure/production[$index]',
            ),
          );
        }
        final tokenExtension =
            element.findElements('turingLabTokens').firstOrNull;
        final left = tokenExtension == null
            ? _inferTokens(leftElement.innerText)
            : _decodeTokenSequence(tokenExtension, 'leftTokens');
        final right = tokenExtension == null
            ? _inferTokens(rightElement.innerText)
            : _decodeTokenSequence(tokenExtension, 'rightTokens');
        final structural = '${left.stableKey}->${right.stableKey}';
        provisional.add(PhraseStructureProduction(
          id: tokenExtension?.getAttribute('id') ??
              deterministicContentId('production', structural),
          left: left,
          right: right,
          order: int.tryParse(tokenExtension?.getAttribute('order') ?? '') ?? 0,
        ));
      }
      final productions = extension == null
          ? (provisional
                ..sort((left, right) {
                  final lhs = left.left.compareTo(right.left);
                  return lhs != 0 ? lhs : left.right.compareTo(right.right);
                }))
              .indexed
              .map((entry) => PhraseStructureProduction(
                    id: entry.$2.id,
                    left: entry.$2.left,
                    right: entry.$2.right,
                    order: entry.$1,
                  ))
              .toList()
          : provisional;
      final symbols = productions
          .expand((production) => [
                ...production.left.symbols,
                ...production.right.symbols,
              ])
          .toSet();
      final nonterminals = declaration?.nonterminals ??
          symbols.whereType<NonterminalGrammarSymbol>().toSet();
      final terminals = declaration?.terminals ??
          symbols.whereType<TerminalGrammarSymbol>().toSet();
      final firstNonterminal = productions
          .expand((production) => production.left.symbols)
          .whereType<NonterminalGrammarSymbol>()
          .firstOrNull;
      final start = declaration?.startSymbol ?? firstNonterminal;
      if (start == null) {
        return const CodecMalformed(
          reason: CodecMalformedReason.invalidValue,
          message: 'Could not infer a start nonterminal.',
          location: CodecSourceLocation(path: '/structure/production[0]/left'),
        );
      }
      final grammar = UnrestrictedGrammar(
        id: declaration?.id ??
            deterministicContentId(
                'unrestricted_grammar', utf8Payload(payload)),
        name: declaration?.name ?? 'Imported unrestricted grammar',
        revision: declaration?.revision ?? 0,
        terminals: terminals,
        nonterminals: nonterminals,
        startSymbol: start,
        productions: productions,
      );
      final invalid = _classificationFailure(grammar);
      if (invalid != null) return invalid;
      return CodecSuccess(
        value: InteroperableDocument<Object>(
          document: grammar,
          systemKey: UnrestrictedGrammarCapabilities.systemKey,
          schema: UnrestrictedGrammarCapabilities.schema,
          sourceMetadata: const DocumentSourceMetadata(
            application: 'JFLAP',
            sourceFormatVersion: '7.1',
          ),
        ),
        fidelity: extension == null
            ? DocumentFidelity.normalized
            : DocumentFidelity.exact,
        diagnostics: [
          if (extension == null)
            const CodecDiagnostic(
              code: 'jflap.unrestricted-tokenization-inferred',
              message:
                  'JFLAP text was normalized to Unicode scalar token arrays.',
              disposition: CodecDiagnosticDisposition.normalized,
            ),
        ],
      );
    } on FormatException catch (error) {
      return CodecMalformed(
        reason: CodecMalformedReason.invalidValue,
        message: error.message,
        location: const CodecSourceLocation(path: '/structure'),
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
        document.document is! UnrestrictedGrammar) {
      return const CodecUnsupported(
        reason: CodecUnsupportedReason.document,
        message: 'Expected an unrestricted grammar document.',
      );
    }
    final grammar = document.document as UnrestrictedGrammar;
    final invalid = _classificationFailure(grammar);
    if (invalid != null) return invalid;
    final builder = XmlBuilder();
    builder.processing('xml', 'version="1.0" encoding="UTF-8"');
    builder.element('structure', nest: () {
      builder.element('type', nest: 'grammar');
      builder.element('turingLabGrammar', nest: () {
        builder.attribute('schema', 'turing-lab.unrestricted-grammar@1');
        builder.attribute('id', grammar.id);
        builder.attribute('name', grammar.name);
        builder.attribute('revision', grammar.revision);
        builder.attribute('start', grammar.startSymbol.value);
        builder.element(
          'terminals',
          nest: jsonEncode(
            (grammar.terminals.toList()..sort())
                .map((symbol) => symbol.value)
                .toList(),
          ),
        );
        builder.element(
          'nonterminals',
          nest: jsonEncode(
            (grammar.nonterminals.toList()..sort())
                .map((symbol) => symbol.value)
                .toList(),
          ),
        );
      });
      for (final production in grammar.productions) {
        builder.element('production', nest: () {
          builder.element(
            'left',
            nest: production.left.symbols.map((symbol) => symbol.value).join(),
          );
          if (production.right.isEmpty) {
            builder.element('right', isSelfClosing: true);
          } else {
            builder.element(
              'right',
              nest:
                  production.right.symbols.map((symbol) => symbol.value).join(),
            );
          }
          builder.element('turingLabTokens', nest: () {
            builder.attribute('id', production.id);
            builder.attribute('order', production.order);
            builder.element('leftTokens',
                nest: jsonEncode(production.left.toJson()));
            builder.element(
              'rightTokens',
              nest: jsonEncode(production.right.toJson()),
            );
          });
        });
      }
    });
    final xml = '${builder.buildDocument().toXmlString(pretty: true)}\n';
    return CodecSuccess(
      value: EncodedDocument(
        bytes: utf8Bytes(xml),
        mimeType: 'application/xml',
        filename: filenameWithExtension(
          filename,
          'unrestricted-grammar',
          'jff',
        ),
        schema: UnrestrictedGrammarCapabilities.schema,
      ),
      fidelity: DocumentFidelity.lossy,
      diagnostics: const [
        CodecDiagnostic(
          code: 'jflap.unrestricted-turing-lab-extension-portability',
          message:
              'JFLAP open/save discards Turing Lab token, ID, and metadata extensions.',
          path: '/structure/turingLabGrammar',
          disposition: CodecDiagnosticDisposition.dropped,
        ),
      ],
    );
  }
}

GrammarSymbolSequence _inferTokens(String source) => GrammarSymbolSequence(
      source.runes.map((rune) {
        final value = String.fromCharCode(rune);
        final upper = value.toUpperCase();
        final lower = value.toLowerCase();
        return upper == value && lower != value
            ? NonterminalGrammarSymbol(value)
            : TerminalGrammarSymbol(value);
      }),
    );

({
  String id,
  String name,
  int revision,
  NonterminalGrammarSymbol startSymbol,
  Set<TerminalGrammarSymbol> terminals,
  Set<NonterminalGrammarSymbol> nonterminals,
}) _decodeDeclaration(XmlElement extension) {
  final id = extension.getAttribute('id');
  final name = extension.getAttribute('name');
  final revision = int.tryParse(extension.getAttribute('revision') ?? '');
  final start = extension.getAttribute('start');
  final terminalsElement = extension.getElement('terminals');
  final nonterminalsElement = extension.getElement('nonterminals');
  if (id == null ||
      name == null ||
      revision == null ||
      start == null ||
      terminalsElement == null ||
      nonterminalsElement == null) {
    throw const FormatException('Malformed Turing Lab grammar extension.');
  }
  final terminals = jsonDecode(terminalsElement.innerText);
  final nonterminals = jsonDecode(nonterminalsElement.innerText);
  if (
      terminals is! List ||
      nonterminals is! List ||
      terminals.any((value) => value is! String) ||
      nonterminals.any((value) => value is! String)) {
    throw const FormatException('Malformed Turing Lab grammar extension.');
  }
  return (
    id: id,
    name: name,
    revision: revision,
    startSymbol: NonterminalGrammarSymbol(start),
    terminals: terminals.cast<String>().map(TerminalGrammarSymbol.new).toSet(),
    nonterminals:
        nonterminals.cast<String>().map(NonterminalGrammarSymbol.new).toSet(),
  );
}

GrammarSymbolSequence _decodeTokenSequence(
  XmlElement extension,
  String elementName,
) {
  final element = extension.getElement(elementName);
  if (element == null) {
    throw FormatException('Missing $elementName in Turing Lab token extension.');
  }
  return GrammarSymbolSequence.fromJson(jsonDecode(element.innerText));
}

CodecMalformed<Never>? _classificationFailure(UnrestrictedGrammar grammar) {
  final report = PhraseGrammarClassifier.classify(grammar);
  if (report.isValid) return null;
  final diagnostic = report.errors.first;
  return CodecMalformed(
    reason: CodecMalformedReason.invalidValue,
    message: 'Invalid unrestricted grammar: ${diagnostic.code.name}.',
    location: const CodecSourceLocation(path: '/structure/production'),
  );
}
