import '../formal_systems/formal_systems.dart';
import 'transducer_models.dart';

abstract final class TransducerFormalSystemIds {
  static const mealy = FormalSystemKey(
    type: FormalSystemTypeId('transducer'),
    variant: FormalSystemVariantId('mealy'),
  );
  static const moore = FormalSystemKey(
    type: FormalSystemTypeId('transducer'),
    variant: FormalSystemVariantId('moore'),
  );
}

final class TransducerFormalSystemModule<TDocument extends Object>
    implements FormalSystemModule<TDocument> {
  TransducerFormalSystemModule({
    required this.descriptor,
    required this.session,
    this.examples,
    Iterable<DocumentCodecCapability<TDocument>> codecs = const [],
    Iterable<ConversionCapability<TDocument, Object>> conversions = const [],
  }) : codecs = List<DocumentCodecCapability<TDocument>>.unmodifiable(codecs),
       conversions = List<ConversionCapability<TDocument, Object>>.unmodifiable(
         conversions,
       );

  @override
  final FormalSystemDescriptor descriptor;
  @override
  final List<DocumentCodecCapability<TDocument>> codecs;
  @override
  final List<ConversionCapability<TDocument, Object>> conversions;
  @override
  final ExampleCatalogCapability<TDocument>? examples;
  @override
  final SessionCapability<TDocument>? session;
}

abstract final class TransducerFormalSystemModules {
  static final mealy = TransducerFormalSystemModule<MealyMachine>(
    descriptor: FormalSystemDescriptor(
      key: TransducerFormalSystemIds.mealy,
      schema: const DocumentSchemaDescriptor(
        id: DocumentSchemaId('turing-lab.mealy'),
        version: DocumentSchemaVersion(1),
      ),
      route: const WorkspaceRouteId('/mealy'),
      category: FormalSystemCategory.automaton,
      localizationNamespace: const CapabilityNamespaceId(
        'formal.transducer.mealy',
      ),
      semanticsNamespace: const CapabilityNamespaceId(
        'semantics.transducer.mealy',
      ),
      capabilities: _operationalCapabilities,
      formats: _documentFormats,
    ),
    session: _TransducerSessionCapability<MealyMachine>(
      namespace: const CapabilityNamespaceId('session.transducer.mealy.v1'),
      schemaId: 'turing-lab.mealy',
      encode: (machine) => machine.toJson(),
      decode: MealyMachine.fromJson,
    ),
  );

  static final moore = TransducerFormalSystemModule<MooreMachine>(
    descriptor: FormalSystemDescriptor(
      key: TransducerFormalSystemIds.moore,
      schema: const DocumentSchemaDescriptor(
        id: DocumentSchemaId('turing-lab.moore'),
        version: DocumentSchemaVersion(1),
      ),
      route: const WorkspaceRouteId('/moore'),
      category: FormalSystemCategory.automaton,
      localizationNamespace: const CapabilityNamespaceId(
        'formal.transducer.moore',
      ),
      semanticsNamespace: const CapabilityNamespaceId(
        'semantics.transducer.moore',
      ),
      capabilities: _operationalCapabilities,
      formats: _documentFormats,
    ),
    session: _TransducerSessionCapability<MooreMachine>(
      namespace: const CapabilityNamespaceId('session.transducer.moore.v1'),
      schemaId: 'turing-lab.moore',
      encode: (machine) => machine.toJson(),
      decode: MooreMachine.fromJson,
    ),
  );

  static const _operationalCapabilities = FormalSystemCapabilities(
    editing: SupportedCapability(),
    simulation: SupportedCapability(),
    analysis: SupportedCapability(),
    trace: SupportedCapability(),
    examples: SupportedCapability(),
    help: SupportedCapability(),
    session: SupportedCapability(),
  );

  static const _documentFormats = <DocumentFormatSupport>[
    DocumentFormatSupport(
      formatId: DefaultFormalSystemIds.jflapXmlFormat,
      importAvailability: SupportedCapability(),
      exportAvailability: SupportedCapability(),
      preferredExtension: 'jff',
    ),
    DocumentFormatSupport(
      formatId: DefaultFormalSystemIds.turingLabJsonFormat,
      importAvailability: SupportedCapability(),
      exportAvailability: SupportedCapability(),
      preferredExtension: 'json',
    ),
    DocumentFormatSupport(
      formatId: DefaultFormalSystemIds.svgFormat,
      exportAvailability: SupportedCapability(),
      preferredExtension: 'svg',
    ),
    DocumentFormatSupport(
      formatId: DefaultFormalSystemIds.pngFormat,
      exportAvailability: SupportedCapability(),
      preferredExtension: 'png',
    ),
  ];
}

final class _TransducerSessionCapability<TDocument extends Object>
    implements SessionCapability<TDocument> {
  const _TransducerSessionCapability({
    required this.namespace,
    required this.schemaId,
    required Map<String, Object?> Function(TDocument) encode,
    required TDocument Function(Map<String, Object?>) decode,
  }) : _encode = encode,
       _decode = decode;

  @override
  final CapabilityNamespaceId namespace;
  final String schemaId;
  final Map<String, Object?> Function(TDocument) _encode;
  final TDocument Function(Map<String, Object?>) _decode;

  @override
  Map<String, Object?> encodeSession(TDocument document) =>
      Map<String, Object?>.unmodifiable(_encode(document));

  @override
  TDocument decodeSession(
    Map<String, Object?> encoded, {
    required DocumentSchemaDescriptor schema,
  }) {
    if (schema.id.value != schemaId || schema.version.value != 1) {
      throw FormatException('transducer.session.unsupported-schema', {
        'id': schema.id.value,
        'version': schema.version.value,
      });
    }
    return _decode(Map<String, Object?>.from(encoded));
  }
}
