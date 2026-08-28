import 'dart:convert';
import 'dart:io';

import 'package:xml/xml.dart';

import '../../compatibility_corpus/catalog.dart';
import '../generation.dart';
import '../models.dart';
import '../shrinking.dart';
import 'codec_matrix.dart';

const codecFamilySchema = 'turing-lab.hard-edge.codec-fixture.v1';
const codecMutationKillThreshold = 4;
const codecAcceptFutureSchemaMutationId = 'accept-future-schema';
const codecDropExtensionSidecarMutationId = 'drop-extension-sidecar';
const codecCorruptTransportCopyMutationId = 'corrupt-transport-copy';
const codecEscalateFidelityMutationId = 'escalate-fidelity';

final class CodecHardEdgeFixture {
  const CodecHardEdgeFixture({
    required this.id,
    required this.seed,
    required this.codecId,
    required this.property,
    required this.payload,
  });

  final String id;
  final int seed;
  final String codecId;
  final String property;
  final Map<String, Object?> payload;

  CodecHardEdgeFixture copyWith({Map<String, Object?>? payload}) =>
      CodecHardEdgeFixture(
        id: id,
        seed: seed,
        codecId: codecId,
        property: property,
        payload: payload ?? this.payload,
      );

  factory CodecHardEdgeFixture.fromJson(Object? source) {
    if (source is! Map) {
      throw const FormatException('Codec hard-edge fixture must be an object.');
    }
    final json = <String, Object?>{
      for (final entry in source.entries) entry.key.toString(): entry.value,
    };
    if (json['schema'] != codecFamilySchema ||
        json['id'] is! String ||
        json['seed'] is! int ||
        json['codecId'] is! String ||
        json['property'] is! String ||
        json['payload'] is! Map) {
      throw const FormatException(
          'Codec hard-edge fixture has invalid schema.');
    }
    final codecId = json['codecId']! as String;
    final property = json['property']! as String;
    if (!codecHardEdgeCaseDescriptors.any(
      (entry) => entry.algorithm == codecId && entry.property == property,
    )) {
      throw FormatException('Unsupported codec property $codecId/$property.');
    }
    final payload = Map<String, Object?>.from(json['payload']! as Map);
    _validateCodecFixturePayload(property, payload);
    return CodecHardEdgeFixture(
      id: json['id']! as String,
      seed: json['seed']! as int,
      codecId: codecId,
      property: property,
      payload: Map<String, Object?>.unmodifiable(payload),
    );
  }

  Map<String, Object?> toJson() => {
        'codecId': codecId,
        'id': id,
        'payload': payload,
        'property': property,
        'schema': codecFamilySchema,
        'seed': seed,
      };
}

void _validateCodecFixturePayload(
  String property,
  Map<String, Object?> payload,
) {
  for (final key in switch (property) {
    'adversarial-security' => const ['depthExcess', 'collectionExcess'],
    'transport-parity' => const ['copyCount'],
    _ => const <String>[],
  }) {
    final value = payload[key];
    if (value != null && (value is! int || value < 1)) {
      throw FormatException('Codec fixture $key must be a positive integer.');
    }
  }
  final sourcePayload = payload['sourcePayloadBase64'];
  if (sourcePayload != null) {
    if (sourcePayload is! String) {
      throw const FormatException('Codec source payload must be base64 text.');
    }
    try {
      base64Decode(sourcePayload);
    } on FormatException {
      throw const FormatException('Codec source payload is invalid base64.');
    }
  }
  if (payload['sourceFilename'] case final filename?) {
    if (filename is! String || filename.isEmpty) {
      throw const FormatException('Codec source filename must not be empty.');
    }
  }
  if (payload['failureSignature'] case final signature?) {
    if (signature is! String || signature.isEmpty) {
      throw const FormatException('Codec failure signature must not be empty.');
    }
  }
}

final class CodecFixtureGenerator
    implements DomainGenerator<CodecHardEdgeFixture> {
  const CodecFixtureGenerator({required this.codecId, required this.property});

  final String codecId;
  final String property;

  @override
  CodecHardEdgeFixture generate(GenerationContext context) {
    final marker =
        context.random.choose(const ['β', '🧪', 'token::value', 'é']);
    final propertyPayload = switch (property) {
      'corpus-fidelity' => <String, Object?>{
          'caseOffset': context.random.nextInt(64),
        },
      'adversarial-security' => <String, Object?>{
          'collectionExcess': 1 + context.random.nextInt(3),
          'depthExcess': 1 + context.random.nextInt(3),
          'malformedMarker': marker,
          'wrongFilename': 'wrong-$marker.extension',
        },
      'transport-parity' => <String, Object?>{
          'copyCount': 1 + context.random.nextInt(3),
        },
      'migration-extensions' => <String, Object?>{
          'extensionTokens': ['multi-token', marker, '🧪'],
          'unknownField': 'x-$marker-${context.random.nextUint32()}',
        },
      _ => const <String, Object?>{},
    };
    return CodecHardEdgeFixture(
      id: 'codec-$codecId-$property-${context.seed}-${context.caseIndex}',
      seed: context.seed,
      codecId: codecId,
      property: property,
      payload: {
        'caseIndex': context.caseIndex,
        ...propertyPayload,
      },
    );
  }
}

GeneratedCase<CodecHardEdgeFixture> generateCodecHardEdgeCase({
  required String codecId,
  required String property,
  required int seed,
  int caseIndex = 0,
}) {
  if (!codecHardEdgeCaseDescriptors.any(
    (entry) => entry.algorithm == codecId && entry.property == property,
  )) {
    throw FormatException('Unsupported codec property $codecId/$property.');
  }
  return generateCase(
    family: 'codec',
    property: property,
    generatorVersion: '1',
    seed: seed,
    caseIndex: caseIndex,
    mode: GenerationMode.boundaryValid,
    budget: const GenerationBudget(
      maxStates: 8,
      maxTransitions: 16,
      maxSymbols: 16,
      maxStackDepth: 80,
    ),
    generator: CodecFixtureGenerator(codecId: codecId, property: property),
    encodeValue: (value) => value.toJson(),
  );
}

CodecHardEdgeFixture materializeCodecPropertyFixture({
  required String codecId,
  required String property,
  required int seed,
  Directory? repositoryRoot,
}) {
  final generated = generateCodecHardEdgeCase(
    codecId: codecId,
    property: property,
    seed: seed,
  ).value;
  final catalog = CompatibilityCodecCatalog.create();
  final codec = catalog.codecs[codecId];
  if (codec == null) return generated;
  final fixturePath = codec.descriptor.canonicalFixtures.first;
  final root = repositoryRoot ?? Directory.current;
  final source = File(
    '${root.path}${Platform.pathSeparator}'
    '${fixturePath.replaceAll('/', Platform.pathSeparator)}',
  );
  if (!source.existsSync()) return generated;
  return generated.copyWith(
    payload: {
      ...generated.payload,
      'sourceFilename': source.uri.pathSegments.last,
      'sourcePayloadBase64': base64Encode(source.readAsBytesSync()),
    },
  );
}

final class CodecFixtureShrinker
    implements DomainShrinker<CodecHardEdgeFixture> {
  const CodecFixtureShrinker();

  @override
  Iterable<CodecHardEdgeFixture> candidates(CodecHardEdgeFixture value) sync* {
    final encoded = value.payload['sourcePayloadBase64'];
    final filename = value.payload['sourceFilename'];
    if (encoded is! String || filename is! String) return;
    final bytes = base64Decode(encoded);
    final source = utf8.decode(bytes, allowMalformed: true);
    final candidates = filename.toLowerCase().endsWith('.json')
        ? _jsonPayloadCandidates(source)
        : _xmlPayloadCandidates(source);
    final seen = <String>{encoded};
    for (final candidate in candidates) {
      final candidateEncoded = base64Encode(utf8.encode(candidate));
      if (!seen.add(candidateEncoded)) continue;
      yield value.copyWith(
        payload: {
          ...value.payload,
          'sourcePayloadBase64': candidateEncoded,
        },
      );
    }
  }
}

Iterable<String> _jsonPayloadCandidates(String source) sync* {
  Object? decoded;
  try {
    decoded = jsonDecode(source);
  } on FormatException {
    if (source.isNotEmpty) yield '';
    return;
  }
  for (final candidate in const JsonValueShrinker().candidates(decoded)) {
    yield jsonEncode(candidate);
  }
}

Iterable<String> _xmlPayloadCandidates(String source) sync* {
  XmlDocument document;
  try {
    document = XmlDocument.parse(source);
  } on XmlParserException {
    if (source.isNotEmpty) yield '';
    return;
  }
  final compact = document.toXmlString(pretty: false);
  if (compact.length < source.length) yield compact;
  final elementCount = document.descendants.whereType<XmlElement>().length;
  for (var index = elementCount - 1; index > 0; index--) {
    final clone = XmlDocument.parse(compact);
    final elements = clone.descendants.whereType<XmlElement>().toList();
    if (index >= elements.length) continue;
    elements[index].remove();
    yield clone.toXmlString(pretty: false);
  }
}
