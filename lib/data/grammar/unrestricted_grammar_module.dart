import '../../core/formal_systems/formal_systems.dart';
import '../../core/grammar/phrase_structure/phrase_structure.dart';
import '../codecs/unrestricted_grammar_jflap_codec.dart';
import '../codecs/unrestricted_grammar_json_codec.dart';
import 'unrestricted_grammar_example_catalog.dart';

FormalSystemModule<Object> createUnrestrictedGrammarModule() =>
    _UnrestrictedGrammarModule();

final class _UnrestrictedGrammarModule implements FormalSystemModule<Object> {
  _UnrestrictedGrammarModule()
      : descriptor = FormalSystemDescriptor(
          key: UnrestrictedGrammarCapabilities.systemKey,
          schema: UnrestrictedGrammarCapabilities.schema,
          route: const WorkspaceRouteId('/unrestricted-grammar'),
          category: FormalSystemCategory.grammar,
          localizationNamespace: const CapabilityNamespaceId(
            'formal.grammar.unrestricted',
          ),
          semanticsNamespace: const CapabilityNamespaceId(
            'semantics.grammar.unrestricted',
          ),
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
          ],
        );

  @override
  final FormalSystemDescriptor descriptor;

  @override
  List<DocumentCodecCapability<Object>> get codecs => const [
        UnrestrictedGrammarJflapCodec(),
        UnrestrictedGrammarJsonCodec(),
      ];

  @override
  List<ConversionCapability<Object, Object>> get conversions => const [];

  @override
  ExampleCatalogCapability<Object> get examples =>
      const UnrestrictedGrammarExampleCatalog();

  @override
  SessionCapability<Object> get session =>
      const UnrestrictedGrammarSessionCapability();
}

final class UnrestrictedGrammarSessionCapability
    implements SessionCapability<Object> {
  const UnrestrictedGrammarSessionCapability();

  @override
  CapabilityNamespaceId get namespace => const CapabilityNamespaceId(
        'session.grammar.unrestricted.v1',
      );

  @override
  Map<String, Object?> encodeSession(Object document) {
    if (document is! UnrestrictedGrammar) {
      throw const FormatException('Expected an unrestricted grammar.');
    }
    return document.toJson();
  }

  @override
  Object decodeSession(
    Map<String, Object?> encoded, {
    required DocumentSchemaDescriptor schema,
  }) {
    if (schema.id != UnrestrictedGrammarCapabilities.schema.id ||
        schema.version != UnrestrictedGrammarCapabilities.schema.version) {
      throw const FormatException('Unsupported unrestricted grammar session.');
    }
    return UnrestrictedGrammar.fromJson(encoded);
  }
}
