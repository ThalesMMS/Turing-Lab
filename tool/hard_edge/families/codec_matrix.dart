final class CodecBoundaryInventoryEntry {
  const CodecBoundaryInventoryEntry({
    required this.id,
    required this.kind,
    required this.sourcePath,
    required this.entryPoints,
    required this.properties,
    required this.evidenceCommand,
  });

  final String id;
  final String kind;
  final String sourcePath;
  final List<String> entryPoints;
  final List<String> properties;
  final String evidenceCommand;

  Map<String, Object?> toJson() => {
        'entryPoints': entryPoints,
        'evidenceCommand': evidenceCommand,
        'id': id,
        'kind': kind,
        'properties': properties,
        'sourcePath': sourcePath,
      };
}

/// Stable inventory of every codec currently exposed by the runtime registry.
///
/// The certification test compares this list with the registry so adding a
/// codec without extending this family fails closed.
const codecIds = <String>[
  'fsa.jflap-xml.v1',
  'fsa.turing-lab-json.v1',
  'grammar.jflap-xml.v1',
  'grammar.turing-lab-json.v1',
  'l-system.jflap-xml.v1',
  'l-system.turing-lab-json.v1',
  'mealy.jflap-xml.v1',
  'mealy.turing-lab-json.v1',
  'moore.jflap-xml.v1',
  'moore.turing-lab-json.v1',
  'pda.jflap-xml.v1',
  'pda.turing-lab-json.v1',
  'pumping-lemma.context-free.jflap.v1',
  'pumping-lemma.context-free.turing-lab-json.v1',
  'pumping-lemma.regular.jflap.v1',
  'pumping-lemma.regular.turing-lab-json.v1',
  'regex.jflap.v1',
  'regex.turing-lab-json.v1',
  'tm.jflap-xml.v1',
  'tm.turing-lab-json.v1',
  'unrestricted-grammar.jflap-xml.v1',
  'unrestricted-grammar.turing-lab-json.v1',
];

const codecBoundaryInventory = <CodecBoundaryInventoryEntry>[
  CodecBoundaryInventoryEntry(
    id: 'typed-codec-registry',
    kind: 'codec',
    sourcePath:
        'lib/core/interoperability/document_interoperability_registry.dart',
    entryPoints: ['sniff', 'decode', 'encode'],
    properties: [
      'corpus-fidelity',
      'adversarial-security',
      'transport-parity',
      'migration-extensions',
    ],
    evidenceCommand:
        'dart run tool/hard_edge/families/codec_cases.dart run --seed 340',
  ),
  CodecBoundaryInventoryEntry(
    id: 'active-session-snapshot',
    kind: 'mapper',
    sourcePath: 'lib/data/services/active_session_snapshot_codec.dart',
    entryPoints: ['encode', 'decode'],
    properties: ['session-versioning', 'transactional-failure'],
    evidenceCommand:
        'flutter test test/unit/data/active_session_persistence_service_test.dart test/unit/presentation/active_session_provider_test.dart',
  ),
  CodecBoundaryInventoryEntry(
    id: 'asset-example-mappers',
    kind: 'mapper',
    sourcePath: 'lib/data/converters/asset_example_converters.dart',
    entryPoints: [
      'convertAssetJsonToFsa',
      'convertAssetJsonToPda',
      'convertAssetJsonToTm',
      'convertAssetJsonToGrammar',
      'convertAssetJsonToRegexPreset',
    ],
    properties: ['example-file-parity', 'transactional-failure'],
    evidenceCommand:
        'flutter test test/unit/data/asset_example_converters_test.dart',
  ),
  CodecBoundaryInventoryEntry(
    id: 'graphview-mappers',
    kind: 'mapper',
    sourcePath: 'lib/features/canvas/graphview',
    entryPoints: ['toSnapshot', 'mergeIntoTemplate'],
    properties: ['endpoint-rebinding', 'semantic-token-vectors'],
    evidenceCommand:
        'flutter test test/features/canvas/graphview/graphview_automaton_mapper_test.dart test/features/canvas/graphview/graphview_pda_mapper_test.dart test/features/canvas/graphview/graphview_tm_mapper_test.dart',
  ),
  CodecBoundaryInventoryEntry(
    id: 'automaton-fragment-combiner',
    kind: 'mapper',
    sourcePath: 'lib/core/automaton_fragments/automaton_fragment_combiner.dart',
    entryPoints: ['prepare'],
    properties: [
      'deterministic-ids',
      'source-immutability',
      'transactional-failure'
    ],
    evidenceCommand:
        'flutter test test/unit/core/automaton_fragments/automaton_fragment_combiner_test.dart',
  ),
  CodecBoundaryInventoryEntry(
    id: 'structured-exports',
    kind: 'export',
    sourcePath: 'lib/presentation/widgets/export',
    entryPoints: [
      'SvgExporter',
      'TransducerVisualExporter.svg',
      'TransducerVisualExporter.png',
      'VariableDependencyGraphExporter.layout',
      'VariableDependencyGraphExporter.toSvg',
    ],
    properties: ['escaping', 'finite-coordinates', 'deterministic-output'],
    evidenceCommand:
        'flutter test test/integration/io/interoperability_roundtrip_test.dart test/unit/presentation/transducer_visual_exporter_test.dart test/unit/core/grammar/variable_dependency_graph_exporter_test.dart',
  ),
  CodecBoundaryInventoryEntry(
    id: 'fsa-regex-conversions',
    kind: 'conversion',
    sourcePath: 'lib/core/algorithms',
    entryPoints: ['FAToRegexConverter.convert', 'RegexToNFAConverter.convert'],
    properties: [
      'bounded-semantics',
      'deterministic-output',
      'source-immutability'
    ],
    evidenceCommand:
        'flutter test test/unit/core/algorithms/fa_to_regex_converter_regression_test.dart test/unit/core/algorithms/regex_to_nfa_converter_steps_test.dart',
  ),
  CodecBoundaryInventoryEntry(
    id: 'fsa-regular-grammar-conversions',
    kind: 'conversion',
    sourcePath: 'lib/core/algorithms',
    entryPoints: [
      'FSAToGrammarConverter.convert',
      'GrammarToFSAConverter.convert'
    ],
    properties: [
      'bounded-semantics',
      'deterministic-output',
      'source-immutability'
    ],
    evidenceCommand:
        'flutter test test/unit/core/algorithms/fsa_to_grammar_converter_test.dart test/unit/core/algorithms/grammar_to_fsa_converter_test.dart',
  ),
  CodecBoundaryInventoryEntry(
    id: 'cfg-pda-conversions',
    kind: 'conversion',
    sourcePath: 'lib/core/algorithms',
    entryPoints: [
      'GrammarToPDAConverter.convertGrammarToPDA',
      'GrammarToPDAConverter.convertGrammarToPDAStandard',
      'GrammarToPDAConverter.convertGrammarToPDAGreibach',
      'CfgToPdaConverter.buildLl',
      'CfgToPdaConverter.buildLr',
      'PDAtoCFGConverter.convert',
    ],
    properties: [
      'bounded-semantics',
      'provenance',
      'limits-cancellation',
      'unknown-is-not-rejection',
    ],
    evidenceCommand:
        'flutter test test/unit/tool/hard_edge_conversion_boundary_test.dart',
  ),
  CodecBoundaryInventoryEntry(
    id: 'tm-unrestricted-grammar-conversion',
    kind: 'conversion',
    sourcePath:
        'lib/core/algorithms/tm_to_unrestricted_grammar/tm_to_grammar_converter.dart',
    entryPoints: ['TMToGrammarConverter.build'],
    properties: ['provenance', 'production-limit', 'source-immutability'],
    evidenceCommand:
        'flutter test test/unit/core/tm/tm_to_unrestricted_grammar_test.dart test/unit/tool/grammar_hard_edge_certification_test.dart',
  ),
];

final codecHardEdgeCaseDescriptors =
    List<({String algorithm, String property})>.unmodifiable([
  for (final codecId in codecIds) ...[
    (algorithm: codecId, property: 'corpus-fidelity'),
    (algorithm: codecId, property: 'adversarial-security'),
    (algorithm: codecId, property: 'transport-parity'),
    if (codecId.contains('turing-lab-json'))
      (algorithm: codecId, property: 'migration-extensions'),
  ],
]);
