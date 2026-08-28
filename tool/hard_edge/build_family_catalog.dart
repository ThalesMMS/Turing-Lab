import 'dart:convert';
import 'dart:io';

import 'catalog.dart';
import 'models.dart';
import 'mutation.dart';
import 'families/grammar_adapter.dart';
import 'families/grammar_certification.dart';
import 'families/graph_family.dart';
import 'families/codec_family.dart';
import 'families/codec_matrix.dart';
import 'families/codec_mutations.dart';
import 'families/formal_systems_certification.dart';
import 'families/formal_systems_family.dart';
import 'families/pda_executor.dart';
import 'families/pda_family.dart';

Future<void> main() async {
  final root = _repositoryRoot(Directory.current);
  final manifestFile = File(
    '${root.path}${Platform.pathSeparator}'
    'test${Platform.pathSeparator}fixtures${Platform.pathSeparator}'
    'hard_edge${Platform.pathSeparator}manifest.v1.json',
  );
  final base = _frameworkBase(await manifestFile.readAsString());
  final regular = await HardEdgeCatalog.load(
    repositoryRoot: root,
    manifestFile: File(
      '${root.path}${Platform.pathSeparator}'
      'test${Platform.pathSeparator}fixtures${Platform.pathSeparator}'
      'hard_edge${Platform.pathSeparator}regular${Platform.pathSeparator}'
      'catalog.fragment.json',
    ),
  );
  final tm = await HardEdgeCatalog.load(
    repositoryRoot: root,
    manifestFile: File(
      '${root.path}${Platform.pathSeparator}'
      'test${Platform.pathSeparator}fixtures${Platform.pathSeparator}'
      'hard_edge${Platform.pathSeparator}tm${Platform.pathSeparator}'
      'catalog.fragment.json',
    ),
  );

  final cases = <HardEdgeCatalogCase>[
    ...base.cases.where((testCase) => testCase.family == 'framework'),
    ...regular.manifest.cases,
    ...tm.manifest.cases,
  ];
  final mutations = <HardEdgeMutation>[
    ...base.mutations.where((mutation) => mutation.family == 'framework'),
    ...regular.manifest.mutations,
    ...tm.manifest.mutations,
  ];

  await _addGrammarCatalog(root, cases, mutations);
  await _addPdaCatalog(root, cases, mutations);
  await _addFormalSystemsCatalog(root, cases, mutations);
  await _addCodecCatalog(root, cases, mutations);
  await _addGraphCatalog(root, cases, mutations);

  final generated = HardEdgeManifest(
    schemaVersion: HardEdgeManifest.supportedSchemaVersion,
    catalogVersion: '2026.08.26.3',
    cases: cases,
    mutations: mutations,
  );
  final catalog = HardEdgeCatalog(
    repositoryRoot: root,
    manifestFile: manifestFile,
    manifest: generated,
  );
  await catalog.writeManifest(generated);
  await HardEdgeCatalog.load(
    repositoryRoot: root,
    manifestFile: manifestFile,
  );
  stdout.writeln(
    'CATALOG_RESULT passed cases=${cases.length} '
    'mutations=${mutations.length}',
  );
}

Future<void> _addFormalSystemsCatalog(
  Directory root,
  List<HardEdgeCatalogCase> cases,
  List<HardEdgeMutation> mutations,
) async {
  const seed = 339;
  const budget = GenerationBudget(
    maxStates: 16,
    maxTransitions: 64,
    maxSymbols: 32,
    maxWordLength: 32,
    maxProductions: 64,
    maxStackDepth: 64,
    maxIterations: 256,
  );
  const provenance = HardEdgeProvenance(
    origin: 'Independently authored for Turing Lab issue 339',
    independentlyAuthored: true,
    generator: formalSystemsGeneratorVersion,
    licenseBasis: 'LICENSE.txt',
  );
  for (final descriptor in formalSystemsHardEdgeDescriptors) {
    final relative = 'test/fixtures/hard_edge/formal_systems/cases/'
        '${_safeName(descriptor.caseId)}.json';
    final digest = await _writeJsonFixture(
      root,
      relative,
      descriptor.fixture(seed: seed),
    );
    cases.add(
      HardEdgeCatalogCase(
        id: 'formal-systems-${descriptor.caseId}',
        family: formalSystemsFamilyId,
        algorithm: descriptor.algorithm,
        sourceKind: HardEdgeSourceKind.generated,
        seed: seed,
        property: descriptor.property,
        provenance: provenance,
        license: 'Apache-2.0',
        regressionIssue: 339,
        platforms: const ['all'],
        sha256: digest,
        generatorVersion: formalSystemsGeneratorVersion,
        oracleVersion: formalSystemsOracleVersion,
        budget: budget,
        fixture: relative,
        expectedOutcome: HardEdgeExpectedOutcome.pass,
        requiredTool: null,
      ),
    );
  }

  const mutationRelative =
      'test/fixtures/hard_edge/formal_systems/mutation_probes.json';
  final mutationDigest = await _writeJsonFixture(
    root,
    mutationRelative,
    formalSystemsHardEdgeDescriptors.first.fixture(seed: seed),
  );
  for (final operator in formalSystemsMutationOperatorIds) {
    mutations.add(
      HardEdgeMutation(
        id: 'formal-systems-$operator',
        family: formalSystemsFamilyId,
        property: 'formal-systems.mutations',
        operatorId: operator,
        fixture: mutationRelative,
        sha256: mutationDigest,
        requiredTool: null,
      ),
    );
  }
}

Future<void> _addCodecCatalog(
  Directory root,
  List<HardEdgeCatalogCase> cases,
  List<HardEdgeMutation> mutations,
) async {
  const seed = 340;
  const budget = GenerationBudget(
    maxStates: 16,
    maxTransitions: 64,
    maxSymbols: 32,
    maxWordLength: 32,
    maxProductions: 64,
    maxStackDepth: 80,
    maxIterations: 64,
  );
  const provenance = HardEdgeProvenance(
    origin: 'Independently authored for Turing Lab issue 340',
    independentlyAuthored: true,
    generator: 'codec-fixture-v1',
    licenseBasis: 'LICENSE.txt',
  );
  for (final descriptor in codecHardEdgeCaseDescriptors) {
    final id = 'codec-${_safeName(descriptor.algorithm)}-'
        '${_safeName(descriptor.property)}';
    final relative = 'test/fixtures/hard_edge/codec/cases/$id.json';
    final digest = await _writeJsonFixture(
      root,
      relative,
      materializeCodecPropertyFixture(
        codecId: descriptor.algorithm,
        property: descriptor.property,
        seed: seed,
      ).toJson(),
    );
    cases.add(
      HardEdgeCatalogCase(
        id: id,
        family: 'codec',
        algorithm: descriptor.algorithm,
        sourceKind: HardEdgeSourceKind.generated,
        seed: seed,
        property: descriptor.property,
        provenance: provenance,
        license: 'Apache-2.0',
        regressionIssue: 340,
        platforms: const ['all'],
        sha256: digest,
        generatorVersion: 'codec-fixture-v1',
        oracleVersion: 'codec-production-contract-v1',
        budget: budget,
        fixture: relative,
        expectedOutcome: HardEdgeExpectedOutcome.pass,
        requiredTool: null,
      ),
    );
  }

  const mutationRelative = 'test/fixtures/hard_edge/codec/mutation_probes.json';
  final mutationFile = hardEdgePathInside(
    root,
    mutationRelative,
    mustExist: true,
  );
  final mutationDigest = hardEdgeSha256(await mutationFile.readAsBytes());
  const mutationPropertyByOperator = {
    'accept-future-schema': 'migration-extensions',
    'drop-extension-sidecar': 'migration-extensions',
    'corrupt-transport-copy': 'transport-parity',
    'escalate-fidelity': 'corpus-fidelity',
  };
  for (final operator in codecMutationOperators.keys) {
    mutations.add(
      HardEdgeMutation(
        id: 'codec-$operator',
        family: 'codec',
        property: mutationPropertyByOperator[operator]!,
        operatorId: operator,
        fixture: mutationRelative,
        sha256: mutationDigest,
        requiredTool: null,
      ),
    );
  }
}

Future<void> _addGraphCatalog(
  Directory root,
  List<HardEdgeCatalogCase> cases,
  List<HardEdgeMutation> mutations,
) async {
  const seed = 341;
  const budget = GenerationBudget(
    maxStates: 64,
    maxTransitions: 512,
    maxSymbols: 0,
    maxWordLength: 0,
    maxProductions: 0,
    maxStackDepth: 0,
    maxIterations: 256,
  );
  const provenance = HardEdgeProvenance(
    origin: 'Independently authored for Turing Lab issue 341',
    independentlyAuthored: true,
    generator: graphGeneratorVersion,
    licenseBasis: 'LICENSE.txt',
  );
  for (final descriptor in graphHardEdgeDescriptors) {
    final relative = 'test/fixtures/hard_edge/graph/cases/'
        '${_safeName(descriptor.id)}.json';
    final digest = await _writeJsonFixture(
      root,
      relative,
      graphHardEdgeFixture(property: descriptor.property, seed: seed),
    );
    cases.add(
      HardEdgeCatalogCase(
        id: descriptor.id,
        family: graphFamilyId,
        algorithm: descriptor.algorithm,
        sourceKind: HardEdgeSourceKind.generated,
        seed: seed,
        property: descriptor.property,
        provenance: provenance,
        license: 'Apache-2.0',
        regressionIssue: 341,
        platforms: const ['all'],
        sha256: digest,
        generatorVersion: graphGeneratorVersion,
        oracleVersion: graphOracleVersion,
        budget: budget,
        fixture: relative,
        expectedOutcome: HardEdgeExpectedOutcome.pass,
        requiredTool: descriptor.requiredTool,
      ),
    );
  }

  const mutationRelative = 'test/fixtures/hard_edge/graph/mutation_probes.json';
  final mutationDigest = await _writeJsonFixture(
    root,
    mutationRelative,
    graphHardEdgeFixture(property: 'graph.mutations', seed: seed),
  );
  for (final operator in graphMutationOperatorIds) {
    mutations.add(
      HardEdgeMutation(
        id: 'graph-$operator',
        family: graphFamilyId,
        property: 'graph.mutations',
        operatorId: operator,
        fixture: mutationRelative,
        sha256: mutationDigest,
        requiredTool: null,
      ),
    );
  }
}

Future<void> _addGrammarCatalog(
  Directory root,
  List<HardEdgeCatalogCase> cases,
  List<HardEdgeMutation> mutations,
) async {
  const seed = 336;
  const budget = GenerationBudget(
    maxStates: 8,
    maxTransitions: 24,
    maxSymbols: 8,
    maxWordLength: 3,
    maxProductions: 32,
    maxStackDepth: 24,
    maxIterations: 64,
  );
  const provenance = HardEdgeProvenance(
    origin: 'Independently authored for Turing Lab issue 336',
    independentlyAuthored: true,
    generator: 'grammar-hard-edge-v1',
    licenseBasis: 'LICENSE.txt',
  );
  for (final descriptor in grammarHardEdgeDescriptors) {
    final relative = 'test/fixtures/hard_edge/grammar/cases/'
        '${_safeName(descriptor.caseId)}.json';
    final digest = await _writeJsonFixture(
      root,
      relative,
      descriptor.fixture(seed: seed),
    );
    cases.add(
      HardEdgeCatalogCase(
        id: 'grammar-${descriptor.caseId}',
        family: 'grammar',
        algorithm: descriptor.algorithm,
        sourceKind: HardEdgeSourceKind.generated,
        seed: seed,
        property: descriptor.property,
        provenance: provenance,
        license: 'Apache-2.0',
        regressionIssue: 336,
        platforms: const ['all'],
        sha256: digest,
        generatorVersion: 'grammar-hard-edge-v1',
        oracleVersion: 'grammar-independent-derivation-v1',
        budget: budget,
        fixture: relative,
        expectedOutcome: descriptor.expectedOutcome,
        requiredTool: null,
      ),
    );
  }

  final mutationFixture = grammarHardEdgeDescriptors
      .firstWhere(
          (descriptor) => descriptor.caseId == 'analysis-classification')
      .fixture(seed: seed);
  const mutationRelative =
      'test/fixtures/hard_edge/grammar/mutation_probes.json';
  final mutationDigest = await _writeJsonFixture(
    root,
    mutationRelative,
    mutationFixture,
  );
  for (final result in runGrammarMutationProbes(seed: seed)) {
    mutations.add(
      HardEdgeMutation(
        id: 'grammar-${result.id}',
        family: 'grammar',
        property: 'grammar.mutations',
        operatorId: result.id,
        fixture: mutationRelative,
        sha256: mutationDigest,
        requiredTool: null,
      ),
    );
  }
}

Future<void> _addPdaCatalog(
  Directory root,
  List<HardEdgeCatalogCase> cases,
  List<HardEdgeMutation> mutations,
) async {
  const seed = 337;
  const budget = GenerationBudget(
    maxStates: 8,
    maxTransitions: 24,
    maxSymbols: 8,
    maxWordLength: 12,
    maxProductions: 10000,
    maxStackDepth: 32,
    maxIterations: 64,
  );
  const provenance = HardEdgeProvenance(
    origin: 'Independently authored for Turing Lab issue 337',
    independentlyAuthored: true,
    generator: 'pda-fixture-v1',
    licenseBasis: 'LICENSE.txt',
  );
  for (final descriptor in pdaHardEdgeCaseDescriptors) {
    final fixtureRelative = 'test/fixtures/hard_edge/pda/cases/'
        '${_safeName(descriptor.algorithm)}--'
        '${_safeName(descriptor.property)}.json';
    final fixture = materializePdaPropertyFixture(
      property: descriptor.property,
      seed: seed,
    );
    final fixtureDigest = await _writeJsonFixture(
      root,
      fixtureRelative,
      fixture.toJson(),
    );
    cases.add(
      HardEdgeCatalogCase(
        id: 'pda-${_safeName(descriptor.algorithm)}-'
            '${_safeName(descriptor.property)}',
        family: 'pda',
        algorithm: descriptor.algorithm,
        sourceKind: HardEdgeSourceKind.generated,
        seed: seed,
        property: descriptor.property,
        provenance: provenance,
        license: 'Apache-2.0',
        regressionIssue: 337,
        platforms: const ['all'],
        sha256: fixtureDigest,
        generatorVersion: 'pda-fixture-v1',
        oracleVersion: 'pda-exhaustive-v1',
        budget: budget,
        fixture: fixtureRelative,
        expectedOutcome: HardEdgeExpectedOutcome.pass,
        requiredTool: null,
      ),
    );
  }

  for (final entry in pdaMutationProbeDescriptors.entries) {
    final relative = 'test/fixtures/hard_edge/pda/mutations/'
        '${_safeName(entry.key)}.json';
    final digest = await _writeJsonFixture(
      root,
      relative,
      pdaMutationFixture(entry.value).toJson(),
    );
    mutations.add(
      HardEdgeMutation(
        id: 'pda-${entry.key}',
        family: 'pda',
        property: 'mutation-checks',
        operatorId: entry.key,
        fixture: relative,
        sha256: digest,
        requiredTool: null,
      ),
    );
  }
}

Future<String> _writeJsonFixture(
  Directory root,
  String relative,
  Object? value,
) async {
  final file = hardEdgePathInside(root, relative, mustExist: false);
  await file.parent.create(recursive: true);
  final bytes = utf8.encode(
    '${const JsonEncoder.withIndent('  ').convert(value)}\n',
  );
  await file.writeAsBytes(bytes, flush: true);
  return hardEdgeSha256(bytes);
}

Directory _repositoryRoot(Directory start) {
  var current = start.absolute;
  while (true) {
    if (File(
      '${current.path}${Platform.pathSeparator}pubspec.yaml',
    ).existsSync()) {
      return current;
    }
    if (current.parent.path == current.path) {
      throw StateError('Could not locate the repository root.');
    }
    current = current.parent;
  }
}

String _safeName(String value) =>
    value.replaceAll(RegExp(r'[^a-z0-9._-]'), '-');

HardEdgeManifest _frameworkBase(String source) {
  final decoded = jsonDecode(source);
  if (decoded is! Map) {
    throw const FormatException('Hard-edge manifest must be an object.');
  }
  final json = <String, Object?>{
    for (final entry in decoded.entries) entry.key.toString(): entry.value,
  };
  final cases = json['cases'];
  final mutations = json['mutations'];
  if (cases is! List || mutations is! List) {
    throw const FormatException(
      'Hard-edge manifest must contain cases and mutations arrays.',
    );
  }
  bool isFramework(Object? value) =>
      value is Map && value['family'] == 'framework';
  return HardEdgeManifest.parse(
    jsonEncode({
      'schemaVersion': json['schemaVersion'],
      'catalogVersion': json['catalogVersion'],
      'cases': cases.where(isFramework).toList(),
      'mutations': mutations.where(isFramework).toList(),
    }),
  );
}
