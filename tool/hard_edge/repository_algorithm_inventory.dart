import 'dart:convert';
import 'dart:io';

const repositoryAlgorithmInventorySchema =
    'turing-lab.repository-algorithm-inventory.v1';

final class AlgorithmOwnershipScope {
  const AlgorithmOwnershipScope({
    required this.id,
    required this.family,
    required this.issue,
    required this.evidenceCommand,
    required this.evidenceRoots,
    required this.regressionFixtureRoot,
    required this.propertyEvidence,
    required this.mutationCommand,
    this.mutationRationale =
        'The owner family runs reviewed semantic mutation operators.',
  });

  final String id;
  final String family;
  final int issue;
  final String evidenceCommand;
  final List<String> evidenceRoots;
  final String regressionFixtureRoot;
  final String propertyEvidence;
  final String mutationCommand;
  final String mutationRationale;

  Map<String, Object?> toJson() => {
        'evidenceCommand': evidenceCommand,
        'family': family,
        'id': id,
        'issue': issue,
        'mutationCommand': mutationCommand,
        'mutationRationale': mutationRationale,
        'propertyEvidence': propertyEvidence,
        'regressionFixtureRoot': regressionFixtureRoot,
      };
}

const repositoryAlgorithmOwnershipScopes = <AlgorithmOwnershipScope>[
  AlgorithmOwnershipScope(
    id: 'regular',
    family: 'regular',
    issue: 335,
    evidenceCommand:
        'flutter test test/unit/tool/hard_edge_regular_family_test.dart test/unit/core/fsa test/unit/core/regex test/unit/core/manual_conversions test/unit/core/algorithms test/unit/providers/algorithm_step_provider_test.dart test/unit/presentation/automaton_providers_integration_test.dart test/unit/presentation/automaton_simulation_stale_test.dart test/unit/providers/regex_editor_provider_test.dart test/widget/presentation/language_comparison_controller_test.dart',
    evidenceRoots: [
      'test/unit/tool/hard_edge_regular_family_test.dart',
      'test/unit/core/fsa',
      'test/unit/core/regex',
      'test/unit/core/manual_conversions',
      'test/unit/core/algorithms',
      'test/unit/providers/algorithm_step_provider_test.dart',
      'test/unit/presentation/automaton_providers_integration_test.dart',
      'test/unit/presentation/automaton_simulation_stale_test.dart',
      'test/unit/providers/regex_editor_provider_test.dart',
      'test/widget/presentation/language_comparison_controller_test.dart',
    ],
    regressionFixtureRoot: 'test/fixtures/hard_edge/regular',
    propertyEvidence:
        'regular family properties and independent automata oracles',
    mutationCommand:
        'dart run tool/hard_edge_regular.dart --property regular.mutations',
  ),
  AlgorithmOwnershipScope(
    id: 'grammar',
    family: 'grammar',
    issue: 336,
    evidenceCommand:
        'flutter test test/unit/tool/grammar_hard_edge_certification_test.dart test/unit/core/grammar test/unit/core/cfg test/unit/core/parsers test/unit/core/algorithms test/unit/data/services/grammar_teaching_session_store_test.dart test/unit/data/unrestricted_grammar_module_test.dart test/widget/presentation/unrestricted_grammar_workspace_test.dart test/widget/presentation/unrestricted_grammar_tm_provenance_test.dart',
    evidenceRoots: [
      'test/unit/tool/grammar_hard_edge_certification_test.dart',
      'test/unit/core/grammar',
      'test/unit/core/cfg',
      'test/unit/core/parsers',
      'test/unit/core/algorithms',
      'test/unit/data/services/grammar_teaching_session_store_test.dart',
      'test/unit/data/unrestricted_grammar_module_test.dart',
      'test/widget/presentation/unrestricted_grammar_workspace_test.dart',
      'test/widget/presentation/unrestricted_grammar_tm_provenance_test.dart',
    ],
    regressionFixtureRoot: 'test/fixtures/hard_edge/grammar',
    propertyEvidence:
        'grammar family differential and bounded derivation oracles',
    mutationCommand: 'dart run tool/hard_edge_grammar_cases.dart mutate',
  ),
  AlgorithmOwnershipScope(
    id: 'pda',
    family: 'pda',
    issue: 337,
    evidenceCommand:
        'flutter test test/unit/tool/hard_edge_pda_family_test.dart test/unit/core/pda test/unit/core/algorithms test/unit/presentation/pda_simulation_provider_test.dart',
    evidenceRoots: [
      'test/unit/tool/hard_edge_pda_family_test.dart',
      'test/unit/core/pda',
      'test/unit/core/algorithms',
      'test/unit/presentation/pda_simulation_provider_test.dart',
    ],
    regressionFixtureRoot: 'test/fixtures/hard_edge/pda',
    propertyEvidence:
        'PDA configuration-search, conversion, and oracle properties',
    mutationCommand: 'dart run tool/hard_edge/families/pda_cases.dart mutate',
  ),
  AlgorithmOwnershipScope(
    id: 'tm',
    family: 'tm',
    issue: 338,
    evidenceCommand:
        'flutter test test/unit/tool/hard_edge_tm_family_test.dart test/unit/core/tm test/unit/core/algorithms test/unit/core/services test/widget/presentation/tm_algorithm_execution_controller_test.dart test/widget/presentation/tm_algorithm_panel_test.dart',
    evidenceRoots: [
      'test/unit/tool/hard_edge_tm_family_test.dart',
      'test/unit/core/tm',
      'test/unit/core/algorithms',
      'test/unit/core/services',
      'test/widget/presentation/tm_algorithm_execution_controller_test.dart',
      'test/widget/presentation/tm_algorithm_panel_test.dart',
    ],
    regressionFixtureRoot: 'test/fixtures/hard_edge/tm',
    propertyEvidence:
        'TM single/multi-tape, building-block, and typed-outcome properties',
    mutationCommand: 'dart run tool/hard_edge_tm.dart --property tm.mutations',
  ),
  AlgorithmOwnershipScope(
    id: 'formal-systems',
    family: 'formal-systems',
    issue: 339,
    evidenceCommand:
        'flutter test test/unit/tool/formal_systems_hard_edge_test.dart test/unit/core/transducers test/unit/core/l_systems test/unit/core/pumping_lemma test/unit/core/formal_systems test/unit/data/default_formal_system_registry_test.dart test/unit/data/moore_registered_module_test.dart test/unit/data/mealy_document_codecs_test.dart test/widget/presentation/l_system_workspace_test.dart test/unit/presentation/moore_workspace_definition_test.dart test/widget/presentation/mealy_workspace_test.dart',
    evidenceRoots: [
      'test/unit/tool/formal_systems_hard_edge_test.dart',
      'test/unit/core/transducers',
      'test/unit/core/l_systems',
      'test/unit/core/pumping_lemma',
      'test/unit/core/formal_systems',
      'test/unit/data/default_formal_system_registry_test.dart',
      'test/unit/data/moore_registered_module_test.dart',
      'test/unit/data/mealy_document_codecs_test.dart',
      'test/widget/presentation/l_system_workspace_test.dart',
      'test/unit/presentation/moore_workspace_definition_test.dart',
      'test/widget/presentation/mealy_workspace_test.dart',
    ],
    regressionFixtureRoot: 'test/fixtures/hard_edge/formal_systems',
    propertyEvidence:
        'transducer, L-system, Pumping Lemma, and registry properties',
    mutationCommand: 'dart run tool/hard_edge_formal_systems.dart mutate',
  ),
  AlgorithmOwnershipScope(
    id: 'codec',
    family: 'codec',
    issue: 340,
    evidenceCommand:
        'flutter test test/unit/tool/hard_edge_codec_family_test.dart test/unit/core/interoperability test/unit/data test/integration/io test/widget/presentation/variable_dependency_graph_workspace_test.dart test/unit/core/models/automaton_json_roundtrip_test.dart',
    evidenceRoots: [
      'test/unit/tool/hard_edge_codec_family_test.dart',
      'test/unit/core/interoperability',
      'test/unit/data',
      'test/integration/io',
      'test/widget/presentation/variable_dependency_graph_workspace_test.dart',
      'test/unit/core/models/automaton_json_roundtrip_test.dart',
    ],
    regressionFixtureRoot: 'test/fixtures/hard_edge/codec',
    propertyEvidence:
        'codec corpus, migration, security, and conversion properties',
    mutationCommand: 'dart run tool/hard_edge/families/codec_cases.dart mutate',
  ),
  AlgorithmOwnershipScope(
    id: 'graph',
    family: 'graph',
    issue: 341,
    evidenceCommand:
        'flutter test test/unit/tool/hard_edge_graph_family_test.dart test/unit/tool/repository_algorithm_inventory_test.dart test/features/canvas/graphview test/unit/core/graph_layout test/widget/presentation/automaton_graphview_canvas_test.dart test/widget/presentation/read_only_fsa_graphview_canvas_test.dart test/integration/algorithms/algorithm_step_mode_e2e_test.dart test/unit/core/algorithm_step_properties_test.dart test/core/services/highlight_channel_test.dart test/core/services/simulation_highlight_service_test.dart test/core/services/canvas_highlight_coordinator_test.dart test/unit/core/services/automaton_diagnostic_highlight_service_test.dart test/unit/core/models/fsa_computation_branch_adapter_test.dart test/unit/presentation/graphview_transducer_canvas_controller_test.dart test/unit/presentation/algorithm_step_renderer_registry_test.dart',
    evidenceRoots: [
      'test/unit/tool/hard_edge_graph_family_test.dart',
      'test/features/canvas/graphview',
      'test/unit/core/graph_layout',
      'test/widget/presentation/automaton_graphview_canvas_test.dart',
      'test/widget/presentation/read_only_fsa_graphview_canvas_test.dart',
      'test/integration/algorithms/algorithm_step_mode_e2e_test.dart',
      'test/unit/tool/repository_algorithm_inventory_test.dart',
      'test/unit/core/algorithm_step_properties_test.dart',
      'test/core/services/highlight_channel_test.dart',
      'test/core/services/simulation_highlight_service_test.dart',
      'test/core/services/canvas_highlight_coordinator_test.dart',
      'test/unit/core/services/automaton_diagnostic_highlight_service_test.dart',
      'test/unit/core/models/fsa_computation_branch_adapter_test.dart',
      'test/unit/presentation/graphview_transducer_canvas_controller_test.dart',
      'test/unit/presentation/algorithm_step_renderer_registry_test.dart',
    ],
    regressionFixtureRoot: 'test/fixtures/hard_edge/graph',
    propertyEvidence:
        'layout, mapping, viewport, history, and rendering properties',
    mutationCommand: 'dart run tool/hard_edge_cases.dart mutate --family graph',
  ),
  AlgorithmOwnershipScope(
    id: 'cross-family',
    family: 'cross-family',
    issue: 342,
    evidenceCommand:
        'flutter test test/unit/core/batch_execution test/unit/tool/cross_family_hard_edge_test.dart',
    evidenceRoots: [
      'test/unit/core/batch_execution',
      'test/unit/tool/cross_family_hard_edge_test.dart',
    ],
    regressionFixtureRoot: 'test/fixtures/hard_edge/repository',
    propertyEvidence:
        'batch versus independent execution and typed-outcome tests',
    mutationCommand: '',
    mutationRationale:
        'The batch layer has no standalone mutation operator yet. Issue #342 owns its consolidated mutation review; direct typed-outcome and batch-versus-single tests remain mandatory.',
  ),
];

final class RepositoryAlgorithmInventory {
  RepositoryAlgorithmInventory({
    required Iterable<Map<String, Object?>> entries,
    required Iterable<Map<String, Object?>> exclusions,
  })  : entries = List.unmodifiable(entries),
        exclusions = List.unmodifiable(exclusions);

  final List<Map<String, Object?>> entries;
  final List<Map<String, Object?>> exclusions;

  factory RepositoryAlgorithmInventory.discover(Directory repositoryRoot) {
    final entries = <Map<String, Object?>>[];
    final exclusions = <Map<String, Object?>>[];
    final lib = Directory(_path(repositoryRoot, 'lib'));
    final sources = lib
        .listSync(recursive: true, followLinks: false)
        .whereType<File>()
        .where((file) => file.path.endsWith('.dart'))
        .map((file) => _relative(repositoryRoot, file))
        .toList()
      ..sort();
    for (final sourcePath in sources) {
      final scope = _scopeForPath(sourcePath);
      if (scope == null) continue;
      final source = File(_path(repositoryRoot, sourcePath)).readAsStringSync();
      final symbols = _publicSymbols(source);
      if (symbols.isEmpty) {
        exclusions.add({
          'family': scope.family,
          'issue': scope.issue,
          'rationale':
              'Barrel or private support file with no public production entry point.',
          'sourcePath': sourcePath,
        });
        continue;
      }
      final role = _roleFor(sourcePath);
      final bounded = _hasBoundedContract(sourcePath, source);
      final cancellable = _hasCancellationContract(sourcePath, source);
      final regressionCount = Directory(
        _path(repositoryRoot, scope.regressionFixtureRoot),
      )
          .listSync(recursive: true, followLinks: false)
          .whereType<File>()
          .where((file) => file.path.endsWith('.json'))
          .length;
      final mutationInScope = scope.mutationCommand.isNotEmpty &&
          role != 'model' &&
          role != 'registry' &&
          scope.id != 'cross-family' &&
          !_requiresConsumerMutationEvidence(sourcePath);
      entries.add({
        'cancellation': {
          'applicable': cancellable,
          'rationale': cancellable
              ? 'The production source exposes cancellation, stale-generation, or cooperative execution semantics.'
              : 'The entry point is synchronous and has no cancellation contract.',
        },
        'entryPoints': symbols,
        'evidenceCommand': scope.evidenceCommand,
        'family': scope.family,
        'id': '${scope.id}:${_sourceId(sourcePath)}',
        'issue': scope.issue,
        'limits': {
          'applicable': bounded,
          'rationale': bounded
              ? 'The owner family command exercises the source limit or typed bounded outcome.'
              : 'The source has no independent resource-limit contract.',
        },
        'mutation': {
          'command': scope.mutationCommand,
          'inScope': mutationInScope,
          'rationale': mutationInScope
              ? scope.mutationRationale
              : scope.id == 'cross-family'
                  ? scope.mutationRationale
                  : _requiresConsumerMutationEvidence(sourcePath)
                      ? 'No dedicated mutation seam targets this adapter or orchestration boundary; direct production invariant tests are the honest evidence.'
                      : 'Data-model or registration glue is covered through consumer mutations and invariant tests.',
        },
        'propertyEvidence': scope.propertyEvidence,
        'regressions': {
          'fixtureCount': regressionCount,
          'root': scope.regressionFixtureRoot,
          'rationale':
              'Historical defects use minimized committed fixtures under the owner family root; zero defects must be recorded by that root index.',
        },
        'role': role,
        'sourcePath': sourcePath,
      });
    }
    entries.sort((left, right) =>
        (left['id']! as String).compareTo(right['id']! as String));
    exclusions.sort((left, right) => (left['sourcePath']! as String)
        .compareTo(right['sourcePath']! as String));
    return RepositoryAlgorithmInventory(
      entries: entries,
      exclusions: exclusions,
    );
  }

  Map<String, Object?> toJson() => {
        'entries': entries,
        'exclusions': exclusions,
        'generatedBy': 'tool/build_repository_algorithm_inventory.dart',
        'ownershipScopes': repositoryAlgorithmOwnershipScopes
            .map((scope) => scope.toJson())
            .toList(),
        'remotelyVerified': false,
        'schema': repositoryAlgorithmInventorySchema,
        'summary': {
          'entries': entries.length,
          'excludedSupportFiles': exclusions.length,
          'issues': {
            for (final issue
                in repositoryAlgorithmOwnershipScopes
                    .map((scope) => scope.issue)
                    .toSet()
                    .toList()
                  ..sort())
              '$issue':
                  entries.where((entry) => entry['issue'] == issue).length,
          },
        },
      };

  List<String> validate(Directory repositoryRoot) {
    final issues = <String>[];
    final ids = <String>{};
    final sources = <String>{};
    final reachableByScope = <String, Set<String>>{};
    for (final scope in repositoryAlgorithmOwnershipScopes) {
      if (!Directory(_path(repositoryRoot, scope.regressionFixtureRoot))
          .existsSync()) {
        issues.add('${scope.id}: regression fixture root is missing.');
      }
      final roots = _expandEvidenceRoots(repositoryRoot, scope.evidenceRoots);
      if (roots.isEmpty) {
        issues.add('${scope.id}: evidence command has no existing Dart root.');
      }
      reachableByScope[scope.id] = _reachableImports(repositoryRoot, roots);
      for (final evidenceRoot in scope.evidenceRoots) {
        if (!scope.evidenceCommand.split(' ').contains(evidenceRoot)) {
          issues.add(
            '${scope.id}: evidence root $evidenceRoot is absent from the exact command.',
          );
        }
      }
      if (!scope.evidenceCommand.startsWith('flutter test ')) {
        issues.add('${scope.id}: evidence command must use flutter test.');
      }
      if (scope.mutationCommand.isNotEmpty) {
        final parts = scope.mutationCommand.split(' ');
        if (parts.length < 3 ||
            parts[0] != 'dart' ||
            parts[1] != 'run' ||
            !File(_path(repositoryRoot, parts[2])).existsSync()) {
          issues.add('${scope.id}: mutation command is not executable.');
        }
      }
    }
    for (final entry in entries) {
      final id = entry['id'] as String;
      final sourcePath = entry['sourcePath'] as String;
      final family = entry['family'] as String;
      if (!ids.add(id)) issues.add('$id: duplicate inventory id.');
      if (!sources.add(sourcePath)) {
        issues.add('$sourcePath: source has more than one primary owner.');
      }
      final sourceFile = File(_path(repositoryRoot, sourcePath));
      if (!sourceFile.existsSync()) {
        issues.add('$id: source file is missing.');
        continue;
      }
      final scope = repositoryAlgorithmOwnershipScopes.singleWhere(
        (candidate) => candidate.family == family,
      );
      final source = sourceFile.readAsStringSync();
      final entryPoints = (entry['entryPoints'] as List).cast<String>();
      for (final symbol in entryPoints) {
        if (!RegExp('\\b${RegExp.escape(symbol)}\\b').hasMatch(source)) {
          issues.add('$id: entry point $symbol is absent from source.');
        }
      }
      if (!(reachableByScope[scope.id] ?? const {}).contains(sourcePath)) {
        issues.add(
          '$id: ${scope.evidenceCommand} does not import the production source.',
        );
      }
      final referencePaths = (reachableByScope[scope.id] ?? const <String>{})
          .where((path) => path != sourcePath)
          .where((path) {
        final candidate = File(_path(repositoryRoot, path));
        if (!candidate.existsSync()) return false;
        final text = candidate.readAsStringSync();
        return entryPoints.any(
          (symbol) => RegExp('\\b${RegExp.escape(symbol)}\\b').hasMatch(text),
        );
      }).toList()
        ..sort();
      if (referencePaths.isEmpty) {
        issues.add(
          '$id: the executable evidence graph imports the source but references '
          'none of its public entry points outside the declaration file.',
        );
      }
      if (entry['evidenceCommand'] != scope.evidenceCommand) {
        issues.add('$id: evidence command drifted from owner scope.');
      }
      if (entry['propertyEvidence'] is! String ||
          (entry['propertyEvidence'] as String).isEmpty) {
        issues.add('$id: property/oracle evidence is missing.');
      }
      for (final field in const ['limits', 'cancellation', 'mutation']) {
        if (entry[field] is! Map ||
            (entry[field] as Map)['rationale'] is! String) {
          issues.add('$id: $field review is missing.');
        }
      }
      final regression = entry['regressions'];
      if (regression is! Map ||
          regression['root'] != scope.regressionFixtureRoot ||
          regression['fixtureCount'] is! int ||
          (regression['fixtureCount'] as int) < 1 ||
          regression['rationale'] is! String) {
        issues.add('$id: committed regression evidence is missing.');
      }
    }
    final classified = {...sources};
    classified.addAll(
      exclusions.map((entry) => entry['sourcePath']! as String),
    );
    final discovered = RepositoryAlgorithmInventory.discover(repositoryRoot);
    final currentClassified = {
      ...discovered.entries.map((entry) => entry['sourcePath']! as String),
      ...discovered.exclusions.map((entry) => entry['sourcePath']! as String),
    };
    for (final source in currentClassified.difference(classified)) {
      issues.add('$source: discovered source has no inventory decision.');
    }
    return issues..sort();
  }
}

AlgorithmOwnershipScope? _scopeForPath(String path) {
  String? scopeId;
  if (path.startsWith('lib/core/graph_layout/') ||
      path.startsWith('lib/features/canvas/graphview/') ||
      path.startsWith('lib/presentation/widgets/automaton_graphview/') ||
      path ==
          'lib/presentation/transducers/graphview_transducer_canvas_controller.dart' ||
      path ==
          'lib/presentation/widgets/algorithm_step_renderer_registry.dart' ||
      path == 'lib/presentation/widgets/read_only_fsa_graphview_canvas.dart') {
    scopeId = 'graph';
  } else if (path.startsWith('lib/data/codecs/') ||
      path.startsWith('lib/data/converters/') ||
      path.startsWith('lib/core/interoperability/') ||
      path.startsWith('lib/core/parsers/') ||
      path.startsWith('lib/core/automaton_fragments/') ||
      path.startsWith('lib/presentation/widgets/export/') ||
      path.endsWith('/active_session_snapshot_codec.dart')) {
    scopeId = 'codec';
  } else if (path.startsWith('lib/core/batch_execution/')) {
    scopeId = 'cross-family';
  } else if (path == 'lib/core/models/serialized_state_resolver.dart') {
    scopeId = 'codec';
  } else if (path == 'lib/core/models/fsa_computation_branch_adapter.dart') {
    scopeId = 'graph';
  } else if (path.startsWith('lib/core/transducers/') ||
      path.startsWith('lib/core/l_systems/') ||
      path.startsWith('lib/core/pumping_lemma/') ||
      path.startsWith('lib/core/formal_systems/') ||
      path.startsWith('lib/data/transducers/') ||
      path.startsWith('lib/data/l_systems/') ||
      path.startsWith('lib/data/formal_systems/') ||
      path == 'lib/presentation/l_systems/l_system_editor_controller.dart' ||
      path == 'lib/presentation/transducers/mealy_document_adapter.dart' ||
      path == 'lib/presentation/transducers/moore_document_adapter.dart') {
    scopeId = 'formal-systems';
  } else if (path.startsWith('lib/core/grammar/') ||
      path ==
          'lib/presentation/unrestricted_grammar/unrestricted_grammar_editor_controller.dart') {
    scopeId = 'grammar';
  } else if (path ==
      'lib/presentation/widgets/language_comparison_controller.dart') {
    scopeId = 'regular';
  } else if (path == 'lib/presentation/widgets/tm_algorithm_runner.dart' ||
      path ==
          'lib/presentation/widgets/tm_algorithm_execution_controller.dart') {
    scopeId = 'tm';
  } else if (path.startsWith('lib/core/manual_conversions/')) {
    scopeId = 'regular';
  } else if (path.startsWith('lib/core/algorithms/')) {
    final basename = path.split('/').last;
    if (basename.startsWith('tm_') ||
        path.contains('/tm_to_unrestricted_grammar/')) {
      scopeId = 'tm';
    } else if (basename.startsWith('pda_') ||
        basename == 'grammar_to_pda_converter.dart' ||
        path.contains('/grammar_to_pda/')) {
      scopeId = 'pda';
    } else if (basename.startsWith('grammar_') ||
        basename == 'brute_force_cfg_parser.dart' ||
        basename == 'lr1_parser.dart' ||
        path.contains('/cfg/')) {
      scopeId = 'grammar';
    } else {
      scopeId = 'regular';
    }
  } else if (path.startsWith('lib/core/services/')) {
    final basename = path.split('/').last;
    if (basename.startsWith('simulation_runner') ||
        basename == 'tm_block_project_editor.dart') {
      scopeId = 'tm';
    } else if (const {
      'algorithm_step_highlight_extractor.dart',
      'algorithm_step_highlight_service.dart',
      'automaton_diagnostic_highlight_service.dart',
      'canvas_highlight_coordinator.dart',
      'highlight_channel.dart',
      'simulation_highlight_service.dart',
    }.contains(basename)) {
      scopeId = 'graph';
    }
  } else if (path.startsWith('lib/presentation/providers/')) {
    final basename = path.split('/').last;
    if (const {
      'algorithm_step_provider.dart',
      'automaton_algorithm_provider.dart',
      'automaton_simulation_provider.dart',
      'regex_editor_provider.dart',
    }.contains(basename)) {
      scopeId = 'regular';
    } else if (basename == 'pda_simulation_provider.dart') {
      scopeId = 'pda';
    }
  }
  if (scopeId == null) return null;
  return repositoryAlgorithmOwnershipScopes.singleWhere(
    (scope) => scope.id == scopeId,
  );
}

List<String> _publicSymbols(String source) {
  final symbols = <String>{};
  final declarations = RegExp(
    r'^(?:(?:abstract|base|final|interface|sealed)\s+)*(?:class|enum|mixin|extension)\s+([A-Za-z]\w*)',
    multiLine: true,
  );
  for (final match in declarations.allMatches(source)) {
    final symbol = match.group(1)!;
    if (!symbol.startsWith('_') && symbol != 'on') symbols.add(symbol);
  }
  final functions = RegExp(
    r'^(?:[A-Za-z][A-Za-z0-9_<>,.? ]*\s+)([a-z][A-Za-z0-9_]*)\s*\(',
    multiLine: true,
  );
  for (final match in functions.allMatches(source)) {
    final symbol = match.group(1)!;
    if (!_nonFunctionWords.contains(symbol)) symbols.add(symbol);
  }
  return symbols.toList()..sort();
}

const _nonFunctionWords = {'if', 'for', 'switch', 'while', 'catch'};

String _roleFor(String path) {
  final name = path.split('/').last.toLowerCase();
  for (final role in const [
    'codec',
    'converter',
    'parser',
    'simulator',
    'analyzer',
    'transformer',
    'layout',
    'renderer',
    'mapper',
    'expander',
    'interpreter',
    'engine',
    'runner',
    'profiler',
    'registry',
  ]) {
    if (name.contains(role)) return role;
  }
  if (name.contains('model') || name.contains('outcome')) return 'model';
  return 'algorithm';
}

bool _hasBoundedContract(String path, String source) =>
    RegExp(r'limit|maximum|timeout|bounded|budget', caseSensitive: false)
        .hasMatch('${path.split('/').last}\n$source');

bool _hasCancellationContract(String path, String source) =>
    RegExp(r'cancel|stale', caseSensitive: false)
        .hasMatch('${path.split('/').last}\n$source');

bool _requiresConsumerMutationEvidence(String path) => const {
      'lib/core/models/fsa_computation_branch_adapter.dart',
      'lib/core/models/serialized_state_resolver.dart',
      'lib/core/services/algorithm_step_highlight_extractor.dart',
      'lib/core/services/algorithm_step_highlight_service.dart',
      'lib/core/services/automaton_diagnostic_highlight_service.dart',
      'lib/core/services/canvas_highlight_coordinator.dart',
      'lib/core/services/highlight_channel.dart',
      'lib/core/services/simulation_highlight_service.dart',
      'lib/presentation/l_systems/l_system_editor_controller.dart',
      'lib/presentation/transducers/graphview_transducer_canvas_controller.dart',
      'lib/presentation/transducers/mealy_document_adapter.dart',
      'lib/presentation/transducers/moore_document_adapter.dart',
      'lib/presentation/unrestricted_grammar/unrestricted_grammar_editor_controller.dart',
      'lib/presentation/widgets/algorithm_step_renderer_registry.dart',
      'lib/presentation/widgets/language_comparison_controller.dart',
      'lib/presentation/widgets/tm_algorithm_execution_controller.dart',
      'lib/presentation/widgets/tm_algorithm_runner.dart',
    }.contains(path);

List<String> _expandEvidenceRoots(
  Directory repositoryRoot,
  List<String> roots,
) {
  final result = <String>[];
  for (final root in roots) {
    final type = FileSystemEntity.typeSync(_path(repositoryRoot, root));
    if (type == FileSystemEntityType.file && root.endsWith('.dart')) {
      result.add(root);
    } else if (type == FileSystemEntityType.directory) {
      result.addAll(
        Directory(_path(repositoryRoot, root))
            .listSync(recursive: true, followLinks: false)
            .whereType<File>()
            .where((file) => file.path.endsWith('.dart'))
            .map((file) => _relative(repositoryRoot, file)),
      );
    }
  }
  return result..sort();
}

Set<String> _reachableImports(
  Directory repositoryRoot,
  Iterable<String> roots,
) {
  final reachable = <String>{};
  final pending = roots.toList();
  while (pending.isNotEmpty) {
    final path = pending.removeLast();
    if (!reachable.add(path)) continue;
    final file = File(_path(repositoryRoot, path));
    if (!file.existsSync()) continue;
    final source = file.readAsStringSync();
    final directives = RegExp(
      r'''(?:import|export|part)\s+[^;]+;''',
      multiLine: true,
    );
    final uris = RegExp(r'''['"]([^'"]+)['"]''');
    for (final directive in directives.allMatches(source)) {
      for (final match in uris.allMatches(directive.group(0)!)) {
        final uri = match.group(1)!;
        final resolved = _resolveImport(path, uri);
        if (resolved != null &&
            File(_path(repositoryRoot, resolved)).existsSync()) {
          pending.add(resolved);
        }
      }
    }
  }
  return reachable;
}

String? _resolveImport(String importer, String uri) {
  if (uri.startsWith('dart:')) return null;
  if (uri.startsWith('package:turing_lab/')) {
    return 'lib/${uri.substring('package:turing_lab/'.length)}';
  }
  if (uri.startsWith('package:')) return null;
  final segments = importer.split('/')..removeLast();
  for (final segment in uri.split('/')) {
    if (segment == '..') {
      if (segments.isNotEmpty) segments.removeLast();
    } else if (segment != '.') {
      segments.add(segment);
    }
  }
  return segments.join('/');
}

String _sourceId(String path) => path
    .substring('lib/'.length, path.length - '.dart'.length)
    .replaceAll('/', '.');

String _relative(Directory root, File file) => file.absolute.path
    .substring(root.absolute.path.length + 1)
    .replaceAll('\\', '/');

String _path(Directory root, String relative) =>
    '${root.path}${Platform.pathSeparator}'
    '${relative.replaceAll('/', Platform.pathSeparator)}';

String canonicalInventoryJson(Object? value) =>
    const JsonEncoder.withIndent('  ').convert(value);
