import '../formal_systems/formal_systems.dart';
import 'l_system_model.dart';

abstract final class LSystemFormalSystemIds {
  static const key = FormalSystemKey(
    type: FormalSystemTypeId('l-system'),
    variant: FormalSystemVariantId('deterministic-context-free'),
  );
}

final class LSystemFormalSystemModule
    implements FormalSystemModule<LSystemDocument> {
  LSystemFormalSystemModule({
    Iterable<DocumentCodecCapability<LSystemDocument>> codecs = const [],
    this.examples,
  })  : codecs = List.unmodifiable(codecs),
        descriptor = FormalSystemDescriptor(
          key: LSystemFormalSystemIds.key,
          schema: const DocumentSchemaDescriptor(
            id: DocumentSchemaId('turing-lab.l-system'),
            version: DocumentSchemaVersion(1),
          ),
          route: const WorkspaceRouteId('/l-system'),
          category: FormalSystemCategory.grammar,
          localizationNamespace: const CapabilityNamespaceId('formal.l-system'),
          semanticsNamespace: const CapabilityNamespaceId('semantics.l-system'),
          capabilities: const FormalSystemCapabilities(
            editing: SupportedCapability(),
            simulation: SupportedCapability(),
            analysis: SupportedCapability(),
            trace: SupportedCapability(),
            examples: SupportedCapability(),
            help: SupportedCapability(),
            session: SupportedCapability(),
          ),
          formats: const [
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
          ],
        );

  @override
  final FormalSystemDescriptor descriptor;

  @override
  final List<DocumentCodecCapability<LSystemDocument>> codecs;

  @override
  final ExampleCatalogCapability<LSystemDocument>? examples;

  @override
  List<ConversionCapability<LSystemDocument, Object>> get conversions =>
      const [];

  @override
  SessionCapability<LSystemDocument> get session =>
      const _LSystemSessionCapability();
}

final class _LSystemSessionCapability
    implements SessionCapability<LSystemDocument> {
  const _LSystemSessionCapability();

  @override
  CapabilityNamespaceId get namespace =>
      const CapabilityNamespaceId('session.l-system.v1');

  @override
  LSystemDocument decodeSession(
    Map<String, Object?> encoded, {
    required DocumentSchemaDescriptor schema,
  }) {
    if (schema.id.value != 'turing-lab.l-system' || schema.version.value != 1) {
      throw FormatException(
        'Unsupported L-system session schema '
        '${schema.id.value}@${schema.version.value}.',
      );
    }
    return LSystemDocument.fromJson(encoded);
  }

  @override
  Map<String, Object?> encodeSession(LSystemDocument document) =>
      document.toJson();
}
