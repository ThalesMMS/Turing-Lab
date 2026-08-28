import '../../core/formal_systems/formal_systems.dart';
import '../../core/models/fsa.dart';
import '../../core/models/grammar.dart';
import '../../core/models/pda.dart';
import '../../core/models/tm.dart';
import '../../core/pumping_lemma/pumping_lemma.dart';
import '../../core/repositories/active_session_repository.dart';
import '../formal_systems/default_formal_system_registry.dart';

abstract final class ActiveSessionModuleRegistry {
  static final Map<FormalSystemKey, SessionCapability<Object>>
      _sessionCapabilities = Map.unmodifiable({
    DefaultFormalSystemIds.fsa: _JsonSessionCapability<FSA>(
      namespace: const CapabilityNamespaceId('session.fsa'),
      encode: (document) => document.toJson(),
      decode: FSA.fromJson,
    ),
    DefaultFormalSystemIds.grammar: _JsonSessionCapability<Grammar>(
      namespace: const CapabilityNamespaceId('session.grammar'),
      encode: (document) => document.toJson(),
      decode: Grammar.fromJson,
    ),
    DefaultFormalSystemIds.pda: _JsonSessionCapability<PDA>(
      namespace: const CapabilityNamespaceId('session.pda'),
      encode: (document) => document.toJson(),
      decode: PDA.fromJson,
    ),
    DefaultFormalSystemIds.tm: _JsonSessionCapability<TM>(
      namespace: const CapabilityNamespaceId('session.tm'),
      encode: (document) => document.toJson(),
      decode: TM.fromJson,
    ),
    DefaultFormalSystemIds.regex: _JsonSessionCapability<RegexSessionSnapshot>(
      namespace: const CapabilityNamespaceId('session.regex'),
      encode: (document) => document.toJson(),
      decode: RegexSessionSnapshot.fromJson,
    ),
    DefaultFormalSystemIds.regularPumping:
        _JsonSessionCapability<PumpingLemmaDocument>(
      namespace: const CapabilityNamespaceId('session.pumping-lemma.regular'),
      encode: (document) => document.toJson(),
      decode: PumpingLemmaDocument.fromJson,
    ),
    DefaultFormalSystemIds.contextFreePumping:
        _JsonSessionCapability<PumpingLemmaDocument>(
      namespace:
          const CapabilityNamespaceId('session.pumping-lemma.context-free'),
      encode: (document) => document.toJson(),
      decode: PumpingLemmaDocument.fromJson,
    ),
  });

  static final FormalSystemRegistry registry = withBuiltInSessions(
    DefaultFormalSystemRegistry.registry,
  );

  static FormalSystemRegistry withBuiltInSessions(FormalSystemRegistry base) {
    return FormalSystemRegistry(
      modules: base.modules.map(
        (module) => _SessionFormalSystemModule(
          module,
          module.session ?? _sessionCapabilities[module.descriptor.key],
        ),
      ),
      formats: base.formats.formats,
    );
  }
}

final class _SessionFormalSystemModule implements FormalSystemModule<Object> {
  const _SessionFormalSystemModule(this._base, this.session);

  final FormalSystemModule<Object> _base;

  @override
  FormalSystemDescriptor get descriptor => _base.descriptor;

  @override
  List<DocumentCodecCapability<Object>> get codecs => _base.codecs;

  @override
  List<ConversionCapability<Object, Object>> get conversions =>
      _base.conversions;

  @override
  ExampleCatalogCapability<Object>? get examples => _base.examples;

  @override
  final SessionCapability<Object>? session;
}

final class _JsonSessionCapability<TDocument extends Object>
    implements SessionCapability<Object> {
  const _JsonSessionCapability({
    required this.namespace,
    required Map<String, dynamic> Function(TDocument) encode,
    required TDocument Function(Map<String, dynamic>) decode,
  })  : _encode = encode,
        _decode = decode;

  @override
  final CapabilityNamespaceId namespace;
  final Map<String, dynamic> Function(TDocument) _encode;
  final TDocument Function(Map<String, dynamic>) _decode;

  @override
  Map<String, Object?> encodeSession(Object document) {
    if (document is! TDocument) {
      throw FormatException(
        'Session ${namespace.value} cannot encode ${document.runtimeType}',
      );
    }
    return _encode(document);
  }

  @override
  Object decodeSession(
    Map<String, Object?> encoded, {
    required DocumentSchemaDescriptor schema,
  }) {
    return _decode(Map<String, dynamic>.from(encoded));
  }
}
