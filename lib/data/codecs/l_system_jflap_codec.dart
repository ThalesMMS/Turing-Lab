import 'dart:convert';
import 'dart:typed_data';

import 'package:xml/xml.dart';

import '../../core/formal_systems/formal_systems.dart';
import '../../core/interoperability/interoperability.dart';
import '../../core/l_systems/l_systems.dart';
import '../../core/messages/structured_message.dart';
import 'hardened_xml.dart';
import 'l_system_jflap_messages.dart';

final class LSystemJflapCodec
    implements DocumentCodecCapability<LSystemDocument> {
  const LSystemJflapCodec();

  static const schema = DocumentSchemaDescriptor(
    id: DocumentSchemaId('turing-lab.l-system'),
    version: DocumentSchemaVersion(1),
  );

  @override
  CodecDescriptor get descriptor => CodecDescriptor(
    codecId: const DocumentCodecId('l-system.jflap-xml.v1'),
    namespace: const CapabilityNamespaceId('codec.l-system.jflap-xml'),
    systemKey: LSystemFormalSystemIds.key,
    formatId: DefaultFormalSystemIds.jflapXmlFormat,
    schemas: DocumentSchemaRange(minimum: 1, maximum: 1),
    directions: const {
      DocumentFormatDirection.importDocument,
      DocumentFormatDirection.exportDocument,
    },
    priority: 100,
    compatibilityOwner: 'JFLAP 7.1 L-system XML',
    canonicalFixtures: const [
      'test/fixtures/interoperability/l_system_canonical.jff',
    ],
    semanticCapabilities: {
      CodecSemanticCapabilityId.tokenVectors,
      CodecSemanticCapabilityId.extensions,
    },
    knownUnsupportedFields: const {
      'native document IDs and revisions',
      'native production IDs',
      'portable token boundaries after JFLAP open/save',
      'native command mappings',
    },
  );

  @override
  CodecSniffResult sniff(DocumentPayload payload) {
    if (payload.bytes.length > descriptor.securityLimits.maximumBytes) {
      return CodecSniffResult.none;
    }
    final source = utf8.decode(payload.bytes, allowMalformed: true);
    if (!source.contains('<structure') ||
        !RegExp(
          r'<type>\s*lsystem\s*</type>',
          caseSensitive: false,
        ).hasMatch(source)) {
      return CodecSniffResult.none;
    }
    return CodecSniffResult(
      confidence: 100,
      detectedSystem: LSystemFormalSystemIds.key,
      detectedSchemaVersion: 1,
    );
  }

  @override
  CodecOutcome<InteroperableDocument<LSystemDocument>> decode(
    DocumentPayload payload,
  ) {
    final parsed = parseHardenedXml(payload, descriptor.securityLimits);
    if (parsed is! CodecSuccess<XmlDocument>) return _forward(parsed);
    try {
      final root = parsed.value.rootElement;
      final type = root.findElements('type').firstOrNull?.innerText.trim();
      if (root.name.local != 'structure') {
        return CodecUnsupported(
          reason: CodecUnsupportedReason.document,
          message: 'This XML document is not a JFLAP L-system.',
          structuredMessage: LSystemJflapMessages.invalidRoot(),
        );
      }
      if (type != 'lsystem') {
        return CodecUnsupported(
          reason: CodecUnsupportedReason.document,
          message: 'This XML document is not a JFLAP L-system.',
          structuredMessage: LSystemJflapMessages.unsupportedDocumentType(
            type ?? '(missing)',
          ),
        );
      }
      final axiomElement = root.findElements('axiom').lastOrNull;
      if (axiomElement == null) {
        return CodecMalformed(
          reason: CodecMalformedReason.missingField,
          message: 'JFLAP L-system XML requires an axiom.',
          structuredMessage: LSystemJflapMessages.missingAxiom(),
        );
      }
      final parameters = <String, String>{};
      final unknownParameters = <String, String>{};
      for (final element in root.findElements('parameter')) {
        final name = element.findElements('name').firstOrNull?.innerText;
        if (name == null || name.isEmpty) continue;
        final value =
            element.findElements('value').firstOrNull?.innerText ?? '';
        parameters[name] = value;
        if (!_knownParameters.contains(name)) unknownParameters[name] = value;
      }
      final variants = <LSystemUnsupportedVariant>{};
      final unsupportedRules = <Map<String, Object?>>[];
      final productions = <LSystemProduction>[];
      final productionIds = <String>{};
      var order = 0;
      for (final element in root.findElements('production')) {
        final left = element.findElements('left').firstOrNull?.innerText ?? '';
        final rights = element
            .findElements('right')
            .map((value) => value.innerText)
            .toList(growable: false);
        if (_isParametric(left) ||
            rights.any(_containsUnsupportedParametricCommand)) {
          variants.add(LSystemUnsupportedVariant.parametric);
          unsupportedRules.add({'left': left, 'rights': rights});
          continue;
        }
        final context = _decodeContext(left);
        for (final right in rights) {
          var id = _productionId(
            context.predecessor,
            right,
            leftContext: context.left,
            rightContext: context.right,
          );
          if (!productionIds.add(id)) {
            id = '$id-${order + 1}';
            productionIds.add(id);
          }
          productions.add(
            LSystemProduction(
              id: id,
              predecessor: context.predecessor,
              successor: LSystemWord(_tokens(right)),
              leftContext: LSystemWord(context.left),
              rightContext: LSystemWord(context.right),
            ),
          );
          order++;
        }
      }
      final extensionMetadata = <String, Object?>{};
      final advancedExtension = parameters['turingLabUnsupported'];
      if (advancedExtension != null) {
        try {
          final decoded = jsonDecode(advancedExtension);
          if (decoded is! Map) {
            throw const FormatException(
              'turingLabUnsupported must contain a JSON object.',
            );
          }
          final typed = decoded.cast<String, Object?>();
          final rawVariants = typed['variants'];
          if (rawVariants is! List) {
            throw const FormatException(
              'turingLabUnsupported variants must be a list.',
            );
          }
          variants.addAll(
            rawVariants.map(
              (value) =>
                  LSystemUnsupportedVariant.values.byName(value as String),
            ),
          );
          final rawMetadata = typed['metadata'];
          if (rawMetadata is Map) {
            extensionMetadata.addAll(rawMetadata.cast<String, Object?>());
          }
        } on FormatException catch (error) {
          throw _LSystemJflapFormatException(
            error.message,
            LSystemJflapMessages.invalidExtension('turingLabUnsupported'),
          );
        } catch (_) {
          throw _LSystemJflapFormatException(
            'Malformed JFLAP L-system XML.',
            LSystemJflapMessages.invalidExtension('turingLabUnsupported'),
          );
        }
      }
      final extensionBag = <String, Object?>{};
      final encodedExtensionBag = parameters['turingLabExtensions'];
      if (encodedExtensionBag != null) {
        try {
          final decoded = jsonDecode(encodedExtensionBag);
          if (decoded is! Map) {
            throw const FormatException(
              'turingLabExtensions must contain a JSON object.',
            );
          }
          extensionBag.addAll(decoded.cast<String, Object?>());
        } on FormatException catch (error) {
          throw _LSystemJflapFormatException(
            error.message,
            LSystemJflapMessages.invalidExtension('turingLabExtensions'),
          );
        } catch (_) {
          throw _LSystemJflapFormatException(
            'Malformed JFLAP L-system XML.',
            LSystemJflapMessages.invalidExtension('turingLabExtensions'),
          );
        }
      }
      var decodedProductions = productions;
      var productionMetadataRestored = false;
      final encodedProductionMetadata =
          parameters['turingLabProductionMetadata'];
      if (encodedProductionMetadata != null) {
        try {
          final decoded = jsonDecode(encodedProductionMetadata);
          if (decoded is! List || decoded.length != productions.length) {
            throw const FormatException(
              'turingLabProductionMetadata must match the native productions.',
            );
          }
          decodedProductions = <LSystemProduction>[];
          for (var index = 0; index < productions.length; index++) {
            final raw = decoded[index];
            if (raw is! Map) {
              throw const FormatException(
                'Turing Lab production metadata entries must be JSON objects.',
              );
            }
            final metadata = raw.cast<String, Object?>();
            final production = productions[index];
            if (metadata['fingerprint'] != _productionFingerprint(production)) {
              throw const FormatException(
                'Native productions no longer match their Turing Lab metadata.',
              );
            }
            final id = metadata['id'];
            final weight = metadata['weight'] ?? 1;
            if (id is! String || id.trim().isEmpty || weight is! num) {
              throw const FormatException(
                'Turing Lab production metadata contains invalid values.',
              );
            }
            if (weight.toDouble() != production.weight) {
              productionMetadataRestored = true;
            }
            decodedProductions.add(
              LSystemProduction(
                id: id,
                predecessor: production.predecessor,
                successor: production.successor,
                leftContext: production.leftContext,
                rightContext: production.rightContext,
                weight: weight.toDouble(),
              ),
            );
          }
        } on FormatException catch (error) {
          throw _LSystemJflapFormatException(
            error.message,
            LSystemJflapMessages.invalidProductionMetadata(
              'turingLabProductionMetadata',
            ),
          );
        } catch (_) {
          throw _LSystemJflapFormatException(
            'Malformed JFLAP L-system XML.',
            LSystemJflapMessages.invalidProductionMetadata(
              'turingLabProductionMetadata',
            ),
          );
        }
      }
      final diagnostics = <CodecDiagnostic>[];
      if (variants.isNotEmpty) {
        final variantNames = variants.map((variant) => variant.name).toList()
          ..sort();
        diagnostics.add(
          CodecDiagnostic(
            code: 'jflap.l-system.advanced-variant-preserved',
            message:
                'Unsupported advanced productions were preserved and disabled.',
            path: r'$.production',
            structuredMessage: LSystemJflapMessages.advancedVariantPreserved(
              variants: variantNames.join(', '),
            ),
          ),
        );
      }
      if (unknownParameters.isNotEmpty) {
        final parameterNames = unknownParameters.keys.toList()..sort();
        diagnostics.add(
          CodecDiagnostic(
            code: 'jflap.l-system.parameters-preserved',
            message: 'Unknown JFLAP drawing parameters were preserved.',
            path: r'$.parameter',
            structuredMessage: LSystemJflapMessages.parametersPreserved(
              parameterNames.join(', '),
            ),
          ),
        );
      }
      if (productionMetadataRestored ||
          parameters.containsKey('turingLabRandomSeed') ||
          parameters.containsKey('turingLabIgnoredContextSymbols')) {
        final restoredFeatures = <String>[
          if (productionMetadataRestored) 'production-metadata',
          if (parameters.containsKey('turingLabRandomSeed')) 'random-seed',
          if (parameters.containsKey('turingLabIgnoredContextSymbols'))
            'ignored-context-symbols',
        ];
        diagnostics.add(
          CodecDiagnostic(
            code: 'jflap.l-system.execution-extension-restored',
            message:
                'Turing Lab rewriting metadata was restored from XML parameters.',
            path: r'$.parameter',
            structuredMessage: LSystemJflapMessages.executionExtensionRestored(
              features: restoredFeatures.join(', '),
            ),
          ),
        );
      }
      final unknownElements = root.children
          .whereType<XmlElement>()
          .where((element) => !_knownElements.contains(element.name.local))
          .map((element) => element.toXmlString())
          .toList(growable: false);
      if (unknownElements.isNotEmpty) {
        diagnostics.add(
          CodecDiagnostic(
            code: 'jflap.l-system.elements-preserved',
            message: 'Unknown JFLAP XML elements were preserved as extensions.',
            path: r'$.structure',
            structuredMessage: LSystemJflapMessages.elementsPreserved(),
          ),
        );
      }
      final turtle = LSystemTurtleSettings(
        angleDegrees: _double(
          parameters['angleIncrement'] ?? parameters['angle'],
          15,
          parameter: 'angleIncrement',
        ),
        stepLength: _double(parameters['distance'], 15, parameter: 'distance'),
        scale: _double(
          parameters['turingLabScale'],
          1,
          parameter: 'turingLabScale',
        ),
        initialHeadingDegrees: _double(
          parameters['turingLabInitialHeading'],
          0,
          parameter: 'turingLabInitialHeading',
        ),
        initialX: _double(
          parameters['turingLabInitialX'],
          0,
          parameter: 'turingLabInitialX',
        ),
        initialY: _double(
          parameters['turingLabInitialY'],
          0,
          parameter: 'turingLabInitialY',
        ),
        lineWidth: _double(parameters['lineWidth'], 1, parameter: 'lineWidth'),
        lineWidthIncrement: _double(
          parameters['turingLabLineWidthIncrement'] ??
              parameters['lineIncrement'],
          1,
          parameter: 'lineWidthIncrement',
        ),
        hueIncrementDegrees: _double(
          parameters['turingLabHueIncrement'] ?? parameters['hueChange'],
          10,
          parameter: 'hueIncrement',
        ),
        initialColorArgb: _colorParameter(
          parameters['turingLabInitialColor'],
          parameters['color'],
          0xff000000,
          parameter: 'turingLabInitialColor',
        ),
        initialPolygonColorArgb: _colorParameter(
          parameters['turingLabInitialPolygonColor'],
          parameters['polygonColor'],
          0xffff0000,
          parameter: 'turingLabInitialPolygonColor',
        ),
      );
      final document = LSystemDocument(
        id: 'jflap-l-system',
        name: 'Imported L-system',
        revision: 0,
        axiom: LSystemWord(_tokens(axiomElement.innerText)),
        productions: decodedProductions,
        iterations: _integer(
          parameters['turingLabIterations'],
          0,
          parameter: 'turingLabIterations',
        ),
        turtle: turtle,
        commandMapping:
            _decodeMapping(parameters['turingLabCommandMapping']) ??
            LSystemCommandMapping.jflap,
        randomSeed: _signedInteger(
          parameters['turingLabRandomSeed'],
          0,
          parameter: 'turingLabRandomSeed',
        ),
        ignoredContextSymbols: _decodeStringSet(
          parameters['turingLabIgnoredContextSymbols'],
        ),
        unsupportedVariants: variants,
        unsupportedMetadata: {
          ...extensionMetadata,
          if (unsupportedRules.isNotEmpty) 'jflapRules': unsupportedRules,
          if (unknownParameters.isNotEmpty)
            'jflapParameters': unknownParameters,
          if (unknownElements.isNotEmpty) 'jflapElements': unknownElements,
        },
      );
      return CodecSuccess(
        value: InteroperableDocument(
          document: document,
          systemKey: LSystemFormalSystemIds.key,
          schema: schema,
          sourceMetadata: const DocumentSourceMetadata(
            application: 'JFLAP',
            applicationVersion: '7.1',
            sourceFormatVersion: '7.1',
          ),
          extensions: DocumentExtensionBag({
            ...extensionBag,
            if (unknownElements.isNotEmpty)
              'jflap.l-system.elements': unknownElements,
          }),
        ),
        fidelity: DocumentFidelity.normalized,
        diagnostics: diagnostics,
      );
    } on _LSystemJflapFormatException catch (error) {
      return CodecMalformed(
        reason: CodecMalformedReason.invalidValue,
        message: error.message,
        cause: error,
        structuredMessage: error.structuredMessage,
      );
    } on FormatException catch (error) {
      return CodecMalformed(
        reason: CodecMalformedReason.invalidValue,
        message: error.message,
        cause: error,
        structuredMessage: LSystemJflapMessages.invalidDocument(),
      );
    } catch (error) {
      return CodecMalformed(
        message: 'Malformed JFLAP L-system XML.',
        cause: error,
        structuredMessage: LSystemJflapMessages.decodeFailed(),
      );
    }
  }

  @override
  CodecOutcome<EncodedDocument> encode(
    InteroperableDocument<LSystemDocument> document, {
    String? filename,
  }) {
    if (document.systemKey != LSystemFormalSystemIds.key ||
        document.schema.id != schema.id ||
        document.schema.version != schema.version) {
      return CodecUnsupported(
        reason: CodecUnsupportedReason.schema,
        message: 'The document is not a supported L-system schema.',
        structuredMessage: document.systemKey != LSystemFormalSystemIds.key
            ? LSystemJflapMessages.requiresLSystemDocument()
            : LSystemJflapMessages.unsupportedSchema(
                document.schema.version.value,
              ),
      );
    }
    try {
      final system = document.document;
      final sortedProductions = system.productions.toList()
        ..sort((left, right) => left.id.compareTo(right.id));
      final builder = XmlBuilder();
      builder
        ..processing('xml', 'version="1.0" encoding="UTF-8"')
        ..element(
          'structure',
          nest: () {
            builder.element('type', nest: 'lsystem');
            builder.element('axiom', nest: _word(system.axiom));
            for (final production in sortedProductions) {
              builder.element(
                'production',
                nest: () {
                  builder.element('left', nest: _encodeLeft(production));
                  builder.element('right', nest: _word(production.successor));
                },
              );
            }
            final parameters = <String, String>{
              'angle': _plain(system.turtle.angleDegrees),
              'angleIncrement': _plain(system.turtle.angleDegrees),
              'distance': _plain(system.turtle.stepLength),
              'lineWidth': _plain(system.turtle.lineWidth),
              'lineIncrement': _plain(system.turtle.lineWidthIncrement),
              'hueChange': _plain(system.turtle.hueIncrementDegrees),
              'color': _encodeNativeColor(system.turtle.initialColorArgb),
              'polygonColor': _encodeNativeColor(
                system.turtle.initialPolygonColorArgb,
              ),
              'turingLabScale': _plain(system.turtle.scale),
              'turingLabInitialHeading': _plain(
                system.turtle.initialHeadingDegrees,
              ),
              'turingLabInitialX': _plain(system.turtle.initialX),
              'turingLabInitialY': _plain(system.turtle.initialY),
              'turingLabLineWidthIncrement': _plain(
                system.turtle.lineWidthIncrement,
              ),
              'turingLabHueIncrement': _plain(
                system.turtle.hueIncrementDegrees,
              ),
              'turingLabInitialColor': _encodeColor(
                system.turtle.initialColorArgb,
              ),
              'turingLabInitialPolygonColor': _encodeColor(
                system.turtle.initialPolygonColorArgb,
              ),
              'turingLabIterations': '${system.iterations}',
              if (system.randomSeed != 0)
                'turingLabRandomSeed': '${system.randomSeed}',
              if (system.ignoredContextSymbols.isNotEmpty)
                'turingLabIgnoredContextSymbols': jsonEncode(
                  system.ignoredContextSymbols.toList()..sort(),
                ),
              'turingLabProductionMetadata': jsonEncode([
                for (final production in sortedProductions)
                  {
                    'fingerprint': _productionFingerprint(production),
                    'id': production.id,
                    'weight': production.weight,
                  },
              ]),
              'turingLabCommandMapping': jsonEncode(
                system.commandMapping.toJson(),
              ),
              if (system.unsupportedVariants.isNotEmpty ||
                  system.unsupportedMetadata.isNotEmpty)
                'turingLabUnsupported': jsonEncode({
                  'variants': [
                    for (final variant in system.unsupportedVariants)
                      variant.name,
                  ],
                  'metadata': system.unsupportedMetadata,
                }),
              if (!document.extensions.isEmpty)
                'turingLabExtensions': jsonEncode(document.extensions.values),
            };
            for (final entry in parameters.entries) {
              builder.element(
                'parameter',
                nest: () {
                  builder.element('name', nest: entry.key);
                  builder.element('value', nest: entry.value);
                },
              );
            }
          },
        );
      final bytes = Uint8List.fromList(
        utf8.encode(builder.buildDocument().toXmlString(pretty: true)),
      );
      final diagnostics = <CodecDiagnostic>[
        if (system.randomSeed != 0 ||
            system.ignoredContextSymbols.isNotEmpty ||
            system.productions.any((production) => production.weight != 1))
          CodecDiagnostic(
            code: 'jflap.l-system.execution-extension',
            message:
                'Seed, ignored context symbols, and weighted choices use Turing Lab XML parameters.',
            path: r'$.parameter',
            structuredMessage: LSystemJflapMessages.executionExtension(),
          ),
        if (system.unsupportedVariants.isNotEmpty)
          CodecDiagnostic(
            code: 'jflap.l-system.advanced-variant-extension',
            message:
                'Unsupported advanced variants were preserved in a Turing Lab extension.',
            path: r'$.parameter.turingLabUnsupported',
            structuredMessage: LSystemJflapMessages.advancedVariantExtension(
              variants: _sortedVariantNames(system.unsupportedVariants),
            ),
          ),
      ];
      return CodecSuccess(
        value: EncodedDocument(
          bytes: bytes,
          mimeType: 'application/xml',
          filename: filename ?? 'l-system.jff',
          schema: schema,
        ),
        fidelity: DocumentFidelity.normalized,
        diagnostics: diagnostics,
      );
    } catch (error) {
      return CodecInternalFailure(
        stage: CodecInternalFailureStage.encode,
        message: 'Could not encode JFLAP L-system XML.',
        cause: error,
        structuredMessage: LSystemJflapMessages.encodeFailed(),
      );
    }
  }
}

const _knownElements = {'type', 'axiom', 'production', 'parameter'};
const _knownParameters = {
  'angle',
  'angleIncrement',
  'distance',
  'lineWidth',
  'lineIncrement',
  'hueChange',
  'color',
  'polygonColor',
  'turingLabScale',
  'turingLabInitialHeading',
  'turingLabInitialX',
  'turingLabInitialY',
  'turingLabLineWidthIncrement',
  'turingLabHueIncrement',
  'turingLabInitialColor',
  'turingLabInitialPolygonColor',
  'turingLabIterations',
  'turingLabRandomSeed',
  'turingLabIgnoredContextSymbols',
  'turingLabProductionMetadata',
  'turingLabCommandMapping',
  'turingLabUnsupported',
  'turingLabExtensions',
};

List<String> _tokens(String value) => value
    .split(RegExp(r'\s+'))
    .where((token) => token.isNotEmpty)
    .toList(growable: false);

bool _isParametric(String value) =>
    RegExp(r'(^|\s)[^\s()]+\([^)]*\)').hasMatch(value);

bool _containsUnsupportedParametricCommand(String value) => _tokens(value).any((
  token,
) {
  final match = RegExp(r'^([^\s()]+)\([^)]*\)$').firstMatch(token);
  return match != null && !_supportedArgumentCommands.contains(match.group(1));
});

const _supportedArgumentCommands = {
  'g',
  'f',
  '+',
  '-',
  '&',
  '^',
  '/',
  '*',
  '!',
  '~',
  '#',
  '@',
  '##',
  '@@',
  'color',
  'polygonColor',
  'angle',
  'angleIncrement',
  'lineWidth',
  'lineIncrement',
  'distance',
  'hueChange',
};

({List<String> left, String predecessor, List<String> right}) _decodeContext(
  String value,
) {
  final tokens = _tokens(value);
  if (tokens.length == 1) {
    return (left: const [], predecessor: tokens.single, right: const []);
  }
  if (tokens.length < 2) {
    throw _LSystemJflapFormatException(
      'An L-system predecessor must not be empty.',
      LSystemJflapMessages.emptyPredecessor(),
    );
  }
  final center = int.tryParse(tokens.first);
  final context = tokens.sublist(1);
  if (center == null || center < 0 || center >= context.length) {
    throw _LSystemJflapFormatException(
      'Invalid JFLAP context predecessor: $value.',
      LSystemJflapMessages.invalidContextPredecessor(value),
    );
  }
  return (
    left: context.sublist(0, center),
    predecessor: context[center],
    right: context.sublist(center + 1),
  );
}

String _encodeLeft(LSystemProduction production) {
  if (production.leftContext.isEmpty && production.rightContext.isEmpty) {
    return production.predecessor;
  }
  return [
    '${production.leftContext.length}',
    ...production.leftContext.symbols,
    production.predecessor,
    ...production.rightContext.symbols,
  ].join(' ');
}

String _productionId(
  String predecessor,
  String successor, {
  List<String> leftContext = const [],
  List<String> rightContext = const [],
}) {
  final encoded = base64Url
      .encode(
        utf8.encode(
          jsonEncode({
            'left': leftContext,
            'predecessor': predecessor,
            'right': rightContext,
            'successor': successor,
          }),
        ),
      )
      .replaceAll('=', '');
  return 'jflap-$encoded';
}

String _productionFingerprint(LSystemProduction production) => jsonEncode({
  'left': production.leftContext.symbols,
  'predecessor': production.predecessor,
  'right': production.rightContext.symbols,
  'successor': production.successor.symbols,
});

double _double(String? value, double fallback, {required String parameter}) {
  if (value == null) return fallback;
  final parsed = double.tryParse(value);
  if (parsed == null || !parsed.isFinite) {
    throw _LSystemJflapFormatException(
      'Invalid numeric JFLAP parameter: $value.',
      LSystemJflapMessages.invalidParameter(name: parameter, value: value),
    );
  }
  return parsed;
}

int _integer(String? value, int fallback, {required String parameter}) {
  if (value == null) return fallback;
  final parsed = int.tryParse(value);
  if (parsed == null || parsed < 0) {
    throw _LSystemJflapFormatException(
      'Invalid integer JFLAP parameter: $value.',
      LSystemJflapMessages.invalidParameter(name: parameter, value: value),
    );
  }
  return parsed;
}

int _signedInteger(String? value, int fallback, {required String parameter}) {
  if (value == null) return fallback;
  final parsed = int.tryParse(value);
  if (parsed == null) {
    throw _LSystemJflapFormatException(
      'Invalid integer JFLAP parameter: $value.',
      LSystemJflapMessages.invalidParameter(name: parameter, value: value),
    );
  }
  return parsed;
}

int _colorInteger(String? value, int fallback, {required String parameter}) {
  if (value == null) return fallback;
  final normalized = value.startsWith('#') ? value.substring(1) : value;
  final parsed = int.tryParse(normalized, radix: 16);
  if (parsed == null || (normalized.length != 6 && normalized.length != 8)) {
    throw _LSystemJflapFormatException(
      'Invalid color JFLAP parameter: $value.',
      LSystemJflapMessages.invalidParameter(name: parameter, value: value),
    );
  }
  return normalized.length == 6 ? 0xff000000 | parsed : parsed;
}

int _colorParameter(
  String? exact,
  String? native,
  int fallback, {
  required String parameter,
}) {
  if (exact != null) {
    return _colorInteger(exact, fallback, parameter: parameter);
  }
  if (native == null) return fallback;
  final parsed = parseJflapTurtleColor(native);
  if (parsed == null) {
    throw _LSystemJflapFormatException(
      'Invalid color JFLAP parameter: $native.',
      LSystemJflapMessages.invalidParameter(name: parameter, value: native),
    );
  }
  return parsed;
}

Set<String> _decodeStringSet(String? value) {
  if (value == null) return const {};
  try {
    final decoded = jsonDecode(value);
    if (decoded is! List || decoded.any((element) => element is! String)) {
      throw const FormatException(
        'Ignored context symbols must be a JSON string list.',
      );
    }
    return decoded.cast<String>().toSet();
  } on FormatException catch (error) {
    throw _LSystemJflapFormatException(
      error.message,
      LSystemJflapMessages.invalidParameter(
        name: 'turingLabIgnoredContextSymbols',
        value: value,
      ),
    );
  }
}

String _encodeColor(int value) => '#${value.toRadixString(16).padLeft(8, '0')}';

String _encodeNativeColor(int value) =>
    '${(value >> 16) & 0xff},${(value >> 8) & 0xff},${value & 0xff}';

LSystemCommandMapping? _decodeMapping(String? value) {
  if (value == null) return null;
  try {
    final decoded = jsonDecode(value);
    return LSystemCommandMapping.fromJson(decoded);
  } on FormatException catch (error) {
    throw _LSystemJflapFormatException(
      error.message,
      LSystemJflapMessages.invalidCommandMapping(),
    );
  } catch (_) {
    throw _LSystemJflapFormatException(
      'Malformed JFLAP L-system XML.',
      LSystemJflapMessages.invalidCommandMapping(),
    );
  }
}

String _word(LSystemWord word) => word.symbols.join(' ');

String _plain(double value) {
  final source = value.toStringAsFixed(8);
  return source.replaceFirst(RegExp(r'\.?0+$'), '');
}

CodecOutcome<T> _forward<T>(CodecOutcome<XmlDocument> outcome) =>
    switch (outcome) {
      CodecMalformed<XmlDocument>() => CodecMalformed(
        reason: outcome.reason,
        message: outcome.message,
        location: outcome.location,
        cause: outcome.cause,
        structuredMessage:
            outcome.structuredMessage ??
            switch (outcome.reason) {
              CodecMalformedReason.invalidUtf8 =>
                LSystemJflapMessages.invalidUtf8(),
              _ => LSystemJflapMessages.malformedXml(),
            },
      ),
      CodecResourceLimit<XmlDocument>() => CodecResourceLimit(
        limit: outcome.limit,
        maximum: outcome.maximum,
        actual: outcome.actual,
      ),
      CodecUnsupported<XmlDocument>() => CodecUnsupported(
        reason: outcome.reason,
        message: outcome.message,
        roadmapIssue: outcome.roadmapIssue,
        structuredMessage: outcome.structuredMessage,
      ),
      CodecAmbiguous<XmlDocument>() => CodecAmbiguous(
        codecIds: outcome.codecIds,
      ),
      CodecInternalFailure<XmlDocument>() => CodecInternalFailure(
        stage: outcome.stage,
        message: outcome.message,
        cause: outcome.cause,
        structuredMessage:
            outcome.structuredMessage ?? LSystemJflapMessages.decodeFailed(),
      ),
      CodecSuccess<XmlDocument>() => throw StateError('Unexpected success.'),
    };

String _sortedVariantNames(Iterable<LSystemUnsupportedVariant> variants) {
  final names = variants.map((variant) => variant.name).toList()..sort();
  return names.join(', ');
}

final class _LSystemJflapFormatException extends FormatException {
  _LSystemJflapFormatException(super.message, this.structuredMessage);

  final StructuredMessage structuredMessage;
}
