import '../../core/formal_systems/formal_systems.dart';
import '../../core/interoperability/interoperability.dart';
import '../../core/models/fsa.dart';
import '../../core/models/fsa_transition.dart';
import '../../core/models/grammar.dart';
import '../../core/models/production.dart';
import '../../core/models/transition.dart';
import 'fsa_jflap_codec.dart';
import 'grammar_jflap_codec.dart';
import 'pumping_lemma_jflap_codec.dart';
import 'pumping_lemma_json_codec.dart';
import 'pda_jflap_document_codec.dart';
import 'pda_json_document_codec.dart';
import 'regex_jflap_document_codec.dart';
import 'regex_json_document_codec.dart';
import 'tm_jflap_document_codec.dart';
import 'tm_json_document_codec.dart';
import 'versioned_json_document_codec.dart';

abstract final class DefaultDocumentInteroperabilityRegistry {
  static FormalSystemRegistry withBuiltInCodecs(FormalSystemRegistry base) {
    return FormalSystemRegistry(
      modules: base.modules.map(_withBuiltInCodecs),
      formats: base.formats.formats,
    );
  }

  static DocumentInteroperabilityRegistry create({
    FormalSystemRegistry? formalSystems,
  }) {
    final runtime = withBuiltInCodecs(
      formalSystems ?? FormalSystemRegistry.defaultRegistry,
    );
    return DocumentInteroperabilityRegistry.fromFormalSystems(runtime);
  }

  static FormalSystemModule<Object> _withBuiltInCodecs(
    FormalSystemModule<Object> module,
  ) {
    final builtIns = _builtIns[module.descriptor.key];
    if (builtIns == null) return module;
    final descriptor = _descriptorWithCodecFormats(module.descriptor);
    final existingIds =
        module.codecs.map((codec) => codec.descriptor.codecId).toSet();
    final missing = builtIns
        .where((codec) => !existingIds.contains(codec.descriptor.codecId))
        .toList(growable: false);
    if (missing.isEmpty && identical(descriptor, module.descriptor)) {
      return module;
    }
    return _CodecFormalSystemModule(
      base: module,
      descriptor: descriptor,
      codecs: [
        ...module.codecs,
        ...missing,
      ],
    );
  }

  static final Map<FormalSystemKey, List<DocumentCodecCapability<Object>>>
      _builtIns = Map.unmodifiable({
    DefaultFormalSystemIds.fsa: [
      const FsaJflapDocumentCodec(),
      VersionedJsonDocumentCodec(
        systemKey: DefaultFormalSystemIds.fsa,
        schema: const DocumentSchemaDescriptor(
          id: DocumentSchemaId('turing-lab.fsa'),
          version: DocumentSchemaVersion(1),
        ),
        codecId: const DocumentCodecId('fsa.turing-lab-json.v1'),
        namespace: const CapabilityNamespaceId('codec.fsa.turing-lab-json'),
        fixture: 'test/fixtures/interoperability/fsa_canonical.json',
        encodePayload: _encodeFsa,
        decodePayload: (payload) => FSA.fromJson(payload),
        isLegacyPayload: (payload) =>
            payload['states'] is List &&
            payload['transitions'] is List &&
            payload['alphabet'] is List,
        knownPayloadFields: const {
          'id',
          'name',
          'type',
          'states',
          'transitions',
          'alphabet',
          'initialState',
          'acceptingStates',
          'created',
          'modified',
          'bounds',
          'zoomLevel',
          'panOffset',
        },
      ),
    ],
    DefaultFormalSystemIds.grammar: [
      const GrammarJflapDocumentCodec(),
      VersionedJsonDocumentCodec(
        systemKey: DefaultFormalSystemIds.grammar,
        schema: const DocumentSchemaDescriptor(
          id: DocumentSchemaId('turing-lab.grammar'),
          version: DocumentSchemaVersion(1),
        ),
        codecId: const DocumentCodecId('grammar.turing-lab-json.v1'),
        namespace: const CapabilityNamespaceId('codec.grammar.turing-lab-json'),
        fixture: 'test/fixtures/interoperability/grammar_canonical.json',
        encodePayload: _encodeGrammar,
        decodePayload: (payload) => Grammar.fromJson(payload),
        isLegacyPayload: (payload) =>
            payload['productions'] is List &&
            payload['nonterminals'] is List &&
            payload['startSymbol'] is String,
        knownPayloadFields: const {
          'id',
          'name',
          'terminals',
          'nonterminals',
          'startSymbol',
          'productions',
          'type',
          'created',
          'modified',
        },
      ),
    ],
    DefaultFormalSystemIds.pda: [
      const PdaJflapDocumentCodec(),
      PdaJsonDocumentCodec(),
    ],
    DefaultFormalSystemIds.tm: [
      const TmJflapDocumentCodec(),
      TmJsonDocumentCodec(),
    ],
    DefaultFormalSystemIds.regex: [
      const RegexJflapDocumentCodec(),
      RegexJsonDocumentCodec(),
    ],
    DefaultFormalSystemIds.regularPumping: [
      const PumpingLemmaJflapCodec.regular(),
      const PumpingLemmaJsonCodec.regular(),
    ],
    DefaultFormalSystemIds.contextFreePumping: [
      const PumpingLemmaJflapCodec.contextFree(),
      const PumpingLemmaJsonCodec.contextFree(),
    ],
  });

  static FormalSystemDescriptor _descriptorWithCodecFormats(
    FormalSystemDescriptor descriptor,
  ) {
    final additions = <DocumentFormatSupport>[];
    if (descriptor.key == DefaultFormalSystemIds.grammar &&
        descriptor.formatSupport(DefaultFormalSystemIds.turingLabJsonFormat) ==
            null) {
      additions.add(
        const DocumentFormatSupport(
          formatId: DefaultFormalSystemIds.turingLabJsonFormat,
          importAvailability: SupportedCapability(),
          exportAvailability: SupportedCapability(),
          preferredExtension: 'json',
        ),
      );
    }
    if (descriptor.key == DefaultFormalSystemIds.tm ||
        descriptor.key == DefaultFormalSystemIds.pda ||
        descriptor.key == DefaultFormalSystemIds.regex) {
      if (descriptor.formatSupport(DefaultFormalSystemIds.jflapXmlFormat) ==
          null) {
        additions.add(
          const DocumentFormatSupport(
            formatId: DefaultFormalSystemIds.jflapXmlFormat,
            importAvailability: SupportedCapability(),
            exportAvailability: SupportedCapability(),
            preferredExtension: 'jff',
          ),
        );
      }
      if (descriptor.formatSupport(
            DefaultFormalSystemIds.turingLabJsonFormat,
          ) ==
          null) {
        additions.add(
          const DocumentFormatSupport(
            formatId: DefaultFormalSystemIds.turingLabJsonFormat,
            importAvailability: SupportedCapability(),
            exportAvailability: SupportedCapability(),
            preferredExtension: 'json',
          ),
        );
      }
    }
    if (additions.isEmpty) {
      return descriptor;
    }
    return FormalSystemDescriptor(
      key: descriptor.key,
      schema: descriptor.schema,
      route: descriptor.route,
      category: descriptor.category,
      localizationNamespace: descriptor.localizationNamespace,
      semanticsNamespace: descriptor.semanticsNamespace,
      capabilities: descriptor.capabilities,
      formats: [
        ...descriptor.formats,
        ...additions,
      ],
      conversions: descriptor.conversions,
    );
  }
}

final class _CodecFormalSystemModule implements FormalSystemModule<Object> {
  _CodecFormalSystemModule({
    required this.base,
    required this.descriptor,
    required List<DocumentCodecCapability<Object>> codecs,
  }) : codecs = List<DocumentCodecCapability<Object>>.unmodifiable(codecs);

  final FormalSystemModule<Object> base;

  @override
  final FormalSystemDescriptor descriptor;

  @override
  final List<DocumentCodecCapability<Object>> codecs;

  @override
  List<ConversionCapability<Object, Object>> get conversions =>
      base.conversions;

  @override
  ExampleCatalogCapability<Object>? get examples => base.examples;

  @override
  SessionCapability<Object>? get session => base.session;
}

Map<String, Object?> _encodeFsa(Object document) {
  if (document is! FSA) throw ArgumentError.value(document, 'document');
  final json = document.toJson();
  final states = document.states.toList()..sort((a, b) => a.id.compareTo(b.id));
  final transitions = document.transitions.toList()
    ..sort((a, b) => a.id.compareTo(b.id));
  final accepting = document.acceptingStates.toList()
    ..sort((a, b) => a.id.compareTo(b.id));
  final alphabet = document.alphabet.toList()..sort();
  return <String, Object?>{
    'id': json['id'],
    'name': json['name'],
    'type': json['type'],
    'states': states.map((state) => state.toJson()).toList(),
    'transitions': transitions.map(_encodeFsaTransition).toList(),
    'alphabet': alphabet,
    'initialState': document.initialState?.toJson(),
    'acceptingStates': accepting.map((state) => state.toJson()).toList(),
    'created': json['created'],
    'modified': json['modified'],
    'bounds': json['bounds'],
    'zoomLevel': json['zoomLevel'],
    'panOffset': json['panOffset'],
  };
}

Map<String, Object?> _encodeGrammar(Object document) {
  if (document is! Grammar) throw ArgumentError.value(document, 'document');
  final terminals = document.terminals.toList()..sort();
  final nonterminals = document.nonterminals.toList()..sort();
  final productions = document.productions.toList()
    ..sort((left, right) {
      final order = left.order.compareTo(right.order);
      return order != 0 ? order : left.id.compareTo(right.id);
    });
  return <String, Object?>{
    'id': document.id,
    'name': document.name,
    'terminals': terminals,
    'nonterminals': nonterminals,
    'startSymbol': document.startSymbol,
    'productions': productions.map(_encodeProduction).toList(),
    'type': document.type.name,
    'created': document.created.toIso8601String(),
    'modified': document.modified.toIso8601String(),
  };
}

Map<String, Object?> _encodeProduction(Production production) =>
    Map<String, Object?>.from(production.toJson());

Map<String, Object?> _encodeFsaTransition(Transition transition) {
  final json = Map<String, Object?>.from(transition.toJson());
  if (transition is FSATransition) {
    final symbols = transition.inputSymbols.toList()..sort();
    json['inputSymbols'] = symbols;
  }
  return json;
}
