import 'capability_availability.dart';
import 'conversion_capability.dart';
import 'document_format.dart';
import 'document_schema.dart';
import 'formal_system_capabilities.dart';
import 'formal_system_descriptor.dart';
import 'formal_system_ids.dart';
import 'formal_system_module.dart';

abstract final class DefaultFormalSystemIds {
  static const standardVariant = FormalSystemVariantId('standard');
  static const singleStackVariant = FormalSystemVariantId('single-stack');
  static const singleTapeVariant = FormalSystemVariantId('single-tape');
  static const regularVariant = FormalSystemVariantId('regular');
  static const contextFreeVariant = FormalSystemVariantId('context-free');

  static const fsa = FormalSystemKey(
    type: FormalSystemTypeId('fsa'),
    variant: standardVariant,
  );
  static const grammar = FormalSystemKey(
    type: FormalSystemTypeId('grammar'),
    variant: standardVariant,
  );
  static const pda = FormalSystemKey(
    type: FormalSystemTypeId('pda'),
    variant: singleStackVariant,
  );
  static const tm = FormalSystemKey(
    type: FormalSystemTypeId('tm'),
    variant: singleTapeVariant,
  );
  static const regex = FormalSystemKey(
    type: FormalSystemTypeId('regex'),
    variant: standardVariant,
  );
  static const regularPumping = FormalSystemKey(
    type: FormalSystemTypeId('pumping-lemma'),
    variant: regularVariant,
  );
  static const contextFreePumping = FormalSystemKey(
    type: FormalSystemTypeId('pumping-lemma'),
    variant: contextFreeVariant,
  );

  static const pumping = regularPumping;

  static const jflapXmlFormat = DocumentFormatId('jflap-xml');
  static const turingLabJsonFormat = DocumentFormatId('turing-lab-json');
  static const svgFormat = DocumentFormatId('svg');
  static const pngFormat = DocumentFormatId('png');
}

abstract final class DefaultFormalSystemModules {
  static final formats = List<DocumentFormatDescriptor>.unmodifiable([
    DocumentFormatDescriptor(
      id: DefaultFormalSystemIds.jflapXmlFormat,
      extensions: const {'jff', 'cfg'},
      mediaType: 'application/xml',
    ),
    DocumentFormatDescriptor(
      id: DefaultFormalSystemIds.turingLabJsonFormat,
      extensions: const {'json'},
      mediaType: 'application/json',
    ),
    DocumentFormatDescriptor(
      id: DefaultFormalSystemIds.svgFormat,
      extensions: const {'svg'},
      mediaType: 'image/svg+xml',
    ),
    DocumentFormatDescriptor(
      id: DefaultFormalSystemIds.pngFormat,
      extensions: const {'png'},
      mediaType: 'image/png',
    ),
  ]);

  /// Stable historical order used by navigation, persistence, and restoration.
  static final modules = List<FormalSystemModule<Object>>.unmodifiable([
    DescriptorFormalSystemModule(_fsa),
    DescriptorFormalSystemModule(_grammar),
    DescriptorFormalSystemModule(_pda),
    DescriptorFormalSystemModule(_tm),
    DescriptorFormalSystemModule(_regex),
    DescriptorFormalSystemModule(_regularPumping),
    DescriptorFormalSystemModule(_contextFreePumping),
  ]);

  static final _fsa = FormalSystemDescriptor(
    key: DefaultFormalSystemIds.fsa,
    schema: const DocumentSchemaDescriptor(
      id: DocumentSchemaId('turing-lab.fsa'),
      version: DocumentSchemaVersion(1),
    ),
    route: const WorkspaceRouteId('/fsa'),
    category: FormalSystemCategory.automaton,
    localizationNamespace: const CapabilityNamespaceId('formal.fsa'),
    semanticsNamespace: const CapabilityNamespaceId('semantics.fsa'),
    capabilities: _fullCapabilities,
    formats: [
      _readWrite(DefaultFormalSystemIds.jflapXmlFormat, 'jff'),
      _readWrite(DefaultFormalSystemIds.turingLabJsonFormat, 'json'),
      _export(DefaultFormalSystemIds.svgFormat, 'svg'),
      _export(DefaultFormalSystemIds.pngFormat, 'png'),
    ],
    conversions: const [
      ConversionEdge(
        id: ConversionEdgeId('fsa-to-regex'),
        source: DefaultFormalSystemIds.fsa,
        target: DefaultFormalSystemIds.regex,
      ),
      ConversionEdge(
        id: ConversionEdgeId('fsa-to-grammar'),
        source: DefaultFormalSystemIds.fsa,
        target: DefaultFormalSystemIds.grammar,
      ),
    ],
  );

  static final _grammar = FormalSystemDescriptor(
    key: DefaultFormalSystemIds.grammar,
    schema: const DocumentSchemaDescriptor(
      id: DocumentSchemaId('turing-lab.grammar'),
      version: DocumentSchemaVersion(1),
    ),
    route: const WorkspaceRouteId('/grammar'),
    category: FormalSystemCategory.grammar,
    localizationNamespace: const CapabilityNamespaceId('formal.grammar'),
    semanticsNamespace: const CapabilityNamespaceId('semantics.grammar'),
    capabilities: _fullCapabilities,
    formats: [
      _readWrite(DefaultFormalSystemIds.jflapXmlFormat, 'cfg'),
      _export(DefaultFormalSystemIds.svgFormat, 'svg'),
    ],
    conversions: const [
      ConversionEdge(
        id: ConversionEdgeId('right-linear-grammar-to-fsa'),
        source: DefaultFormalSystemIds.grammar,
        target: DefaultFormalSystemIds.fsa,
      ),
      ConversionEdge(
        id: ConversionEdgeId('grammar-to-pda-general'),
        source: DefaultFormalSystemIds.grammar,
        target: DefaultFormalSystemIds.pda,
      ),
      ConversionEdge(
        id: ConversionEdgeId('grammar-to-pda-standard'),
        source: DefaultFormalSystemIds.grammar,
        target: DefaultFormalSystemIds.pda,
      ),
      ConversionEdge(
        id: ConversionEdgeId('grammar-to-pda-greibach'),
        source: DefaultFormalSystemIds.grammar,
        target: DefaultFormalSystemIds.pda,
      ),
    ],
  );

  static final _pda = FormalSystemDescriptor(
    key: DefaultFormalSystemIds.pda,
    schema: const DocumentSchemaDescriptor(
      id: DocumentSchemaId('turing-lab.pda'),
      version: DocumentSchemaVersion(1),
    ),
    route: const WorkspaceRouteId('/pda'),
    category: FormalSystemCategory.automaton,
    localizationNamespace: const CapabilityNamespaceId('formal.pda'),
    semanticsNamespace: const CapabilityNamespaceId('semantics.pda'),
    capabilities: _fullCapabilities,
    formats: [_export(DefaultFormalSystemIds.svgFormat, 'svg')],
    conversions: const [
      ConversionEdge(
        id: ConversionEdgeId('pda-to-grammar'),
        source: DefaultFormalSystemIds.pda,
        target: DefaultFormalSystemIds.grammar,
      ),
    ],
  );

  static final _tm = FormalSystemDescriptor(
    key: DefaultFormalSystemIds.tm,
    schema: const DocumentSchemaDescriptor(
      id: DocumentSchemaId('turing-lab.tm'),
      version: DocumentSchemaVersion(1),
    ),
    route: const WorkspaceRouteId('/tm'),
    category: FormalSystemCategory.automaton,
    localizationNamespace: const CapabilityNamespaceId('formal.tm'),
    semanticsNamespace: const CapabilityNamespaceId('semantics.tm'),
    capabilities: _fullCapabilities,
    formats: [_export(DefaultFormalSystemIds.svgFormat, 'svg')],
  );

  static final _regex = FormalSystemDescriptor(
    key: DefaultFormalSystemIds.regex,
    schema: const DocumentSchemaDescriptor(
      id: DocumentSchemaId('turing-lab.regex'),
      version: DocumentSchemaVersion(1),
    ),
    route: const WorkspaceRouteId('/regex'),
    category: FormalSystemCategory.expression,
    localizationNamespace: const CapabilityNamespaceId('formal.regex'),
    semanticsNamespace: const CapabilityNamespaceId('semantics.regex'),
    capabilities: _fullCapabilities,
    formats: [
      _readWrite(DefaultFormalSystemIds.jflapXmlFormat, 'jff'),
      _readWrite(DefaultFormalSystemIds.turingLabJsonFormat, 'json'),
    ],
    conversions: const [
      ConversionEdge(
        id: ConversionEdgeId('regex-to-fsa'),
        source: DefaultFormalSystemIds.regex,
        target: DefaultFormalSystemIds.fsa,
      ),
    ],
  );

  static final _regularPumping = FormalSystemDescriptor(
    key: DefaultFormalSystemIds.regularPumping,
    schema: const DocumentSchemaDescriptor(
      id: DocumentSchemaId('turing-lab.pumping-lemma.regular'),
      version: DocumentSchemaVersion(1),
    ),
    route: const WorkspaceRouteId('/pumping-lemma/regular'),
    category: FormalSystemCategory.learning,
    localizationNamespace:
        const CapabilityNamespaceId('formal.pumping.regular'),
    semanticsNamespace:
        const CapabilityNamespaceId('semantics.pumping.regular'),
    capabilities: const FormalSystemCapabilities(
      editing: SupportedCapability(),
      analysis: SupportedCapability(),
      examples: SupportedCapability(),
      help: SupportedCapability(),
      session: SupportedCapability(),
    ),
    formats: [
      _readWrite(DefaultFormalSystemIds.jflapXmlFormat, 'jff'),
      _readWrite(DefaultFormalSystemIds.turingLabJsonFormat, 'json'),
    ],
  );

  static final _contextFreePumping = FormalSystemDescriptor(
    key: DefaultFormalSystemIds.contextFreePumping,
    schema: const DocumentSchemaDescriptor(
      id: DocumentSchemaId('turing-lab.pumping-lemma.context-free'),
      version: DocumentSchemaVersion(1),
    ),
    route: const WorkspaceRouteId('/pumping-lemma/context-free'),
    category: FormalSystemCategory.learning,
    localizationNamespace:
        const CapabilityNamespaceId('formal.pumping.context-free'),
    semanticsNamespace:
        const CapabilityNamespaceId('semantics.pumping.context-free'),
    capabilities: const FormalSystemCapabilities(
      editing: SupportedCapability(),
      analysis: SupportedCapability(),
      examples: SupportedCapability(),
      help: SupportedCapability(),
      session: SupportedCapability(),
    ),
    formats: [
      _readWrite(DefaultFormalSystemIds.jflapXmlFormat, 'jff'),
      _readWrite(DefaultFormalSystemIds.turingLabJsonFormat, 'json'),
    ],
  );

  static const _fullCapabilities = FormalSystemCapabilities(
    editing: SupportedCapability(),
    simulation: SupportedCapability(),
    analysis: SupportedCapability(),
    trace: SupportedCapability(),
    examples: SupportedCapability(),
    help: SupportedCapability(),
    session: SupportedCapability(),
  );

  static DocumentFormatSupport _readWrite(
    DocumentFormatId format,
    String extension,
  ) =>
      DocumentFormatSupport(
        formatId: format,
        importAvailability: const SupportedCapability(),
        exportAvailability: const SupportedCapability(),
        preferredExtension: extension,
      );

  static DocumentFormatSupport _export(
    DocumentFormatId format,
    String extension,
  ) =>
      DocumentFormatSupport(
        formatId: format,
        exportAvailability: const SupportedCapability(),
        preferredExtension: extension,
      );
}
