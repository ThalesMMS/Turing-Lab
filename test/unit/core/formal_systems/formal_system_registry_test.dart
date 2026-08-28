import 'dart:async';

import 'package:test/test.dart';
import 'package:turing_lab/core/formal_systems/formal_systems.dart';
import 'package:turing_lab/core/models/asset_example.dart';

void main() {
  group('default formal-system registry', () {
    test('publishes the workspaces in stable order', () {
      final registry = FormalSystemRegistry.defaultRegistry;

      expect(
        registry.descriptors.map((descriptor) => descriptor.key),
        [
          DefaultFormalSystemIds.fsa,
          DefaultFormalSystemIds.grammar,
          DefaultFormalSystemIds.pda,
          DefaultFormalSystemIds.tm,
          DefaultFormalSystemIds.regex,
          DefaultFormalSystemIds.regularPumping,
          DefaultFormalSystemIds.contextFreePumping,
        ],
      );
      expect(
        registry.descriptors.map((descriptor) => descriptor.route.value),
        [
          '/fsa',
          '/grammar',
          '/pda',
          '/tm',
          '/regex',
          '/pumping-lemma/regular',
          '/pumping-lemma/context-free',
        ],
      );
    });

    test('uses stable schemas, variants, and global document formats', () {
      final registry = FormalSystemRegistry.defaultRegistry;

      expect(
        registry.descriptorFor(DefaultFormalSystemIds.tm)?.key.variant.value,
        'single-tape',
      );
      expect(
        registry.descriptorFor(DefaultFormalSystemIds.pda)?.key.variant.value,
        'single-stack',
      );
      expect(
        registry
            .descriptorFor(DefaultFormalSystemIds.pumping)
            ?.key
            .variant
            .value,
        'regular',
      );
      expect(
        registry.descriptorFor(DefaultFormalSystemIds.fsa)?.schema.id.value,
        'turing-lab.fsa',
      );
      expect(
        registry
            .descriptorFor(DefaultFormalSystemIds.fsa)
            ?.schema
            .version
            .value,
        1,
      );
      expect(
        registry.formats.formats.map((format) => format.id.value),
        ['jflap-xml', 'png', 'svg', 'turing-lab-json'],
      );
      expect(
        registry.formats.forExtension('.CFG')?.id,
        DefaultFormalSystemIds.jflapXmlFormat,
      );
    });

    test('filters typed capabilities and format directions', () {
      final registry = FormalSystemRegistry.defaultRegistry;

      expect(
        registry.availableFor(FormalSystemCapability.session).map((d) => d.key),
        [
          DefaultFormalSystemIds.fsa,
          DefaultFormalSystemIds.grammar,
          DefaultFormalSystemIds.pda,
          DefaultFormalSystemIds.tm,
          DefaultFormalSystemIds.regex,
          DefaultFormalSystemIds.regularPumping,
          DefaultFormalSystemIds.contextFreePumping,
        ],
      );
      expect(
        registry
            .modulesSupportingFormat(
              DefaultFormalSystemIds.jflapXmlFormat,
              DocumentFormatDirection.importDocument,
            )
            .map((module) => module.descriptor.key),
        [
          DefaultFormalSystemIds.fsa,
          DefaultFormalSystemIds.grammar,
          DefaultFormalSystemIds.regex,
          DefaultFormalSystemIds.regularPumping,
          DefaultFormalSystemIds.contextFreePumping,
        ],
      );
      expect(
        registry.modulesSupportingFormat(
          DefaultFormalSystemIds.pngFormat,
          DocumentFormatDirection.importDocument,
        ),
        isEmpty,
      );
      expect(
        registry
            .modulesSupportingFormat(
              DefaultFormalSystemIds.pngFormat,
              DocumentFormatDirection.exportDocument,
            )
            .single
            .descriptor
            .key,
        DefaultFormalSystemIds.fsa,
      );
    });

    test('has non-colliding conversion edges with registered targets', () {
      final registry = FormalSystemRegistry.defaultRegistry;
      final edges = registry.descriptors
          .expand((descriptor) => descriptor.conversions)
          .toList();

      expect(
          edges.map((edge) => edge.stableKey).toSet(), hasLength(edges.length));
      expect(
        edges.every((edge) => registry.descriptorFor(edge.target) != null),
        isTrue,
      );
    });
  });

  group('capability availability', () {
    test('is typed and exposes explicit enabled semantics', () {
      const supported = SupportedCapability();
      const experimental = ExperimentalCapability();
      const unavailable = UnavailableCapability();
      const legacy = LegacyOnlyCapability();

      expect(supported.status, CapabilityStatus.supported);
      expect(experimental.status, CapabilityStatus.experimental);
      expect(unavailable.status, CapabilityStatus.unavailable);
      expect(legacy.status, CapabilityStatus.legacyOnly);
      expect(supported.isEnabled, isTrue);
      expect(experimental.isEnabled, isTrue);
      expect(unavailable.isEnabled, isFalse);
      expect(legacy.isEnabled, isFalse);
    });
  });

  group('registry extension', () {
    test('accepts a typed test-only module without central switches', () async {
      final sample = _SampleModule();
      final sampleFormat = DocumentFormatDescriptor(
        id: _SampleModule.formatId,
        extensions: const {'sample'},
      );
      final registry = FormalSystemRegistry(
        modules: <FormalSystemModule<Object>>[
          ...DefaultFormalSystemModules.modules,
          sample,
        ],
        formats: [...DefaultFormalSystemModules.formats, sampleFormat],
      );

      expect(registry.moduleFor(_SampleModule.key), same(sample));
      expect(
        registry.descriptorForRoute(const WorkspaceRouteId('/sample'))?.key,
        _SampleModule.key,
      );
      expect(
        registry
            .descriptorForSchema(const DocumentSchemaId('test.sample'))
            ?.key,
        _SampleModule.key,
      );
      expect(registry.formatFor(_SampleModule.formatId), same(sampleFormat));

      final example = (await sample.examples.loadExamples()).single;
      expect(example.name, 'Sample');
      expect(example.category, ExampleCategory.dfa);
      expect(example.difficultyLevel, DifficultyLevel.easy);
      expect(example.complexityLevel, ExampleComplexityLevel.low);
      expect(example.tags, ['test-only']);
      expect(example.payload, {'value': 'example'});

      final encoded = sample.session.encodeSession({'value': 'session'});
      expect(
        sample.session.decodeSession(encoded, schema: sample.descriptor.schema),
        {'value': 'session'},
      );
    });
  });

  group('configuration validation', () {
    test('aggregates every duplicate namespace deterministically', () {
      final firstModule = _duplicateModule();
      final secondModule = _duplicateModule();
      final firstFormat = DocumentFormatDescriptor(
        id: const DocumentFormatId('duplicate-format'),
        extensions: const {'dup'},
      );
      final secondFormat = DocumentFormatDescriptor(
        id: const DocumentFormatId('duplicate-format'),
        extensions: const {'.DUP'},
      );

      final forward = _configurationError(
        modules: [firstModule, secondModule],
        formats: [firstFormat, secondFormat],
      );
      final reversed = _configurationError(
        modules: [secondModule, firstModule],
        formats: [secondFormat, firstFormat],
      );

      expect(forward.toString(), reversed.toString());
      expect(
        forward.issues.map((issue) => issue.code),
        containsAll({
          FormalSystemConfigurationIssueCode.duplicateFormalSystemKey,
          FormalSystemConfigurationIssueCode.duplicateRoute,
          FormalSystemConfigurationIssueCode.duplicateSchema,
          FormalSystemConfigurationIssueCode.duplicateFormat,
          FormalSystemConfigurationIssueCode.duplicateExtension,
          FormalSystemConfigurationIssueCode.duplicateConversionEdge,
          FormalSystemConfigurationIssueCode.duplicateLocalizationNamespace,
          FormalSystemConfigurationIssueCode.duplicateSemanticsNamespace,
          FormalSystemConfigurationIssueCode.duplicateExampleNamespace,
          FormalSystemConfigurationIssueCode.duplicateSessionNamespace,
        }),
      );
      expect(
        forward.issues,
        orderedEquals(forward.issues.toList()..sort()),
      );
    });

    test('runtime validation rejects invalid and unresolved configuration', () {
      final descriptor = FormalSystemDescriptor(
        key: const FormalSystemKey(
          type: FormalSystemTypeId('invalid'),
          variant: FormalSystemVariantId(''),
        ),
        schema: const DocumentSchemaDescriptor(
          id: DocumentSchemaId('invalid.schema'),
          version: DocumentSchemaVersion(0),
        ),
        route: const WorkspaceRouteId('invalid-route'),
        category: FormalSystemCategory.automaton,
        localizationNamespace: const CapabilityNamespaceId('invalid.locale'),
        semanticsNamespace: const CapabilityNamespaceId('invalid.semantics'),
        capabilities: const FormalSystemCapabilities(),
        formats: const [
          DocumentFormatSupport(formatId: DocumentFormatId('missing-format')),
        ],
        conversions: const [
          ConversionEdge(
            id: ConversionEdgeId('missing-target'),
            source: FormalSystemKey(
              type: FormalSystemTypeId('invalid'),
              variant: FormalSystemVariantId(''),
            ),
            target: FormalSystemKey(
              type: FormalSystemTypeId('missing'),
              variant: FormalSystemVariantId('standard'),
            ),
          ),
        ],
      );

      final error = _configurationError(
        modules: [DescriptorFormalSystemModule(descriptor)],
        formats: const [],
      );

      expect(
        error.issues.map((issue) => issue.code),
        containsAll({
          FormalSystemConfigurationIssueCode.invalidIdentifier,
          FormalSystemConfigurationIssueCode.invalidSchemaVersion,
          FormalSystemConfigurationIssueCode.invalidRoute,
          FormalSystemConfigurationIssueCode.unknownFormat,
          FormalSystemConfigurationIssueCode.unknownConversionTarget,
        }),
      );
    });

    test('rejects empty operational capability namespaces', () {
      final descriptor = _validDescriptor(
        key: const FormalSystemKey(
          type: FormalSystemTypeId('empty-capability-namespace'),
          variant: FormalSystemVariantId('test'),
        ),
      );
      final error = _configurationError(
        modules: [
          _CapabilityModule(
            DescriptorFormalSystemModule(descriptor),
            examples: const _EmptyNamespaceExamples(),
            session: const _EmptyNamespaceSession(),
          ),
        ],
        formats: const [],
      );

      expect(
        error.issues
            .where(
              (issue) =>
                  issue.code ==
                  FormalSystemConfigurationIssueCode.invalidIdentifier,
            )
            .length,
        2,
      );
    });
  });
}

FormalSystemConfigurationException _configurationError({
  required List<FormalSystemModule<Object>> modules,
  required List<DocumentFormatDescriptor> formats,
}) {
  try {
    FormalSystemRegistry(modules: modules, formats: formats);
    fail('Expected invalid registry configuration to throw.');
  } on FormalSystemConfigurationException catch (error) {
    return error;
  }
}

FormalSystemModule<Object> _duplicateModule() {
  const key = FormalSystemKey(
    type: FormalSystemTypeId('duplicate'),
    variant: FormalSystemVariantId('standard'),
  );
  final descriptor = FormalSystemDescriptor(
    key: key,
    schema: const DocumentSchemaDescriptor(
      id: DocumentSchemaId('duplicate.schema'),
      version: DocumentSchemaVersion(1),
    ),
    route: const WorkspaceRouteId('/duplicate'),
    category: FormalSystemCategory.automaton,
    localizationNamespace: const CapabilityNamespaceId('duplicate.locale'),
    semanticsNamespace: const CapabilityNamespaceId('duplicate.semantics'),
    capabilities: const FormalSystemCapabilities(),
    conversions: const [
      ConversionEdge(
        id: ConversionEdgeId('duplicate-edge'),
        source: key,
        target: FormalSystemKey(
          type: FormalSystemTypeId('missing'),
          variant: FormalSystemVariantId('standard'),
        ),
      ),
    ],
  );
  return _CapabilityModule(
    DescriptorFormalSystemModule(descriptor),
    examples: const _DuplicateExamples(),
    session: const _DuplicateSession(),
  );
}

FormalSystemDescriptor _validDescriptor({required FormalSystemKey key}) =>
    FormalSystemDescriptor(
      key: key,
      schema: DocumentSchemaDescriptor(
        id: DocumentSchemaId('${key.type.value}.schema'),
        version: const DocumentSchemaVersion(1),
      ),
      route: WorkspaceRouteId('/${key.type.value}'),
      category: FormalSystemCategory.learning,
      localizationNamespace:
          CapabilityNamespaceId('${key.type.value}.localization'),
      semanticsNamespace: CapabilityNamespaceId('${key.type.value}.semantics'),
      capabilities: const FormalSystemCapabilities(),
    );

final class _CapabilityModule implements FormalSystemModule<Object> {
  const _CapabilityModule(
    this._base, {
    required this.examples,
    required this.session,
  });

  final FormalSystemModule<Object> _base;

  @override
  FormalSystemDescriptor get descriptor => _base.descriptor;

  @override
  List<DocumentCodecCapability<Object>> get codecs => _base.codecs;

  @override
  List<ConversionCapability<Object, Object>> get conversions =>
      _base.conversions;

  @override
  final ExampleCatalogCapability<Object>? examples;

  @override
  final SessionCapability<Object>? session;
}

final class _DuplicateExamples implements ExampleCatalogCapability<Object> {
  const _DuplicateExamples();

  @override
  CapabilityNamespaceId get namespace =>
      const CapabilityNamespaceId('duplicate.examples');

  @override
  Future<List<AssetExample<Object>>> loadExamples() async => const [];
}

final class _DuplicateSession implements SessionCapability<Object> {
  const _DuplicateSession();

  @override
  CapabilityNamespaceId get namespace =>
      const CapabilityNamespaceId('duplicate.session');

  @override
  Object decodeSession(
    Map<String, Object?> encoded, {
    required DocumentSchemaDescriptor schema,
  }) =>
      encoded;

  @override
  Map<String, Object?> encodeSession(Object document) => const {};
}

final class _EmptyNamespaceExamples
    implements ExampleCatalogCapability<Object> {
  const _EmptyNamespaceExamples();

  @override
  CapabilityNamespaceId get namespace => const CapabilityNamespaceId('');

  @override
  Future<List<AssetExample<Object>>> loadExamples() async => const [];
}

final class _EmptyNamespaceSession implements SessionCapability<Object> {
  const _EmptyNamespaceSession();

  @override
  CapabilityNamespaceId get namespace => const CapabilityNamespaceId('');

  @override
  Object decodeSession(
    Map<String, Object?> encoded, {
    required DocumentSchemaDescriptor schema,
  }) =>
      encoded;

  @override
  Map<String, Object?> encodeSession(Object document) => const {};
}

final class _SampleModule implements FormalSystemModule<Map<String, Object?>> {
  _SampleModule()
      : descriptor = FormalSystemDescriptor(
          key: key,
          schema: const DocumentSchemaDescriptor(
            id: DocumentSchemaId('test.sample'),
            version: DocumentSchemaVersion(1),
          ),
          route: const WorkspaceRouteId('/sample'),
          category: FormalSystemCategory.learning,
          localizationNamespace: const CapabilityNamespaceId('test.sample.ui'),
          semanticsNamespace:
              const CapabilityNamespaceId('test.sample.semantics'),
          capabilities: const FormalSystemCapabilities(
            examples: ExperimentalCapability(),
            session: SupportedCapability(),
          ),
          formats: const [
            DocumentFormatSupport(
              formatId: formatId,
              importAvailability: ExperimentalCapability(),
              exportAvailability: SupportedCapability(),
              preferredExtension: 'sample',
            ),
          ],
        );

  static const key = FormalSystemKey(
    type: FormalSystemTypeId('test-sample'),
    variant: FormalSystemVariantId('test-only'),
  );
  static const formatId = DocumentFormatId('test-sample-json');

  @override
  final FormalSystemDescriptor descriptor;

  @override
  List<DocumentCodecCapability<Map<String, Object?>>> get codecs => const [];

  @override
  List<ConversionCapability<Map<String, Object?>, Object>> get conversions =>
      const [];

  @override
  ExampleCatalogCapability<Map<String, Object?>> get examples =>
      const _SampleExamples();

  @override
  SessionCapability<Map<String, Object?>> get session => const _SampleSession();
}

final class _SampleExamples
    implements ExampleCatalogCapability<Map<String, Object?>> {
  const _SampleExamples();

  @override
  CapabilityNamespaceId get namespace =>
      const CapabilityNamespaceId('test.sample.examples');

  @override
  Future<List<AssetExample<Map<String, Object?>>>> loadExamples() async => [
        AssetExample(
          name: 'Sample',
          description: 'Test-only registry extension.',
          category: ExampleCategory.dfa,
          difficultyLevel: DifficultyLevel.easy,
          complexityLevel: ExampleComplexityLevel.low,
          tags: const ['test-only'],
          payload: const {'value': 'example'},
        ),
      ];
}

final class _SampleSession implements SessionCapability<Map<String, Object?>> {
  const _SampleSession();

  @override
  CapabilityNamespaceId get namespace =>
      const CapabilityNamespaceId('test.sample.session');

  @override
  Map<String, Object?> encodeSession(Map<String, Object?> document) =>
      Map<String, Object?>.unmodifiable(document);

  @override
  Map<String, Object?> decodeSession(
    Map<String, Object?> encoded, {
    required DocumentSchemaDescriptor schema,
  }) =>
      Map<String, Object?>.unmodifiable(encoded);
}
