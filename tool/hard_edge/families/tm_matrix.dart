final class TmAlgorithmInventoryEntry {
  const TmAlgorithmInventoryEntry({
    required this.id,
    required this.sourcePath,
    required this.entryPoints,
    required this.properties,
  });

  final String id;
  final String sourcePath;
  final List<String> entryPoints;
  final List<String> properties;

  Map<String, Object?> toJson() => {
        'entryPoints': entryPoints,
        'id': id,
        'properties': properties,
        'sourcePath': sourcePath,
      };
}

const tmAlgorithmInventory = <TmAlgorithmInventoryEntry>[
  TmAlgorithmInventoryEntry(
    id: 'tm-model',
    sourcePath: 'lib/core/models/tm.dart',
    entryPoints: ['validate', 'documentVariant', 'toJson', 'fromJson'],
    properties: ['tm.model-serialization'],
  ),
  TmAlgorithmInventoryEntry(
    id: 'tm-transition',
    sourcePath: 'lib/core/models/tm_transition.dart',
    entryPoints: [
      'formatLabel',
      'formatVectorLabel',
      'operationsForTapeCount',
      'toJson',
      'fromJson',
    ],
    properties: ['tm.model-serialization', 'tm.multi-tape-atomicity'],
  ),
  TmAlgorithmInventoryEntry(
    id: 'tm-acceptance-policy',
    sourcePath: 'lib/core/models/tm_acceptance.dart',
    entryPoints: ['TMAcceptancePolicyEvaluator.evaluate'],
    properties: ['tm.outcome-lattice'],
  ),
  TmAlgorithmInventoryEntry(
    id: 'tm-execution-kernel',
    sourcePath: 'lib/core/algorithms/tm_execution_kernel.dart',
    entryPoints: [
      'initialTapesTokens',
      'snapshotMulti',
      'transitionsForVector',
      'readVector',
      'applyTransition',
      'moveHead',
      'TMTraceMetricsAccumulator',
    ],
    properties: [
      'tm.oracle-parity',
      'tm.multi-tape-atomicity',
      'tm.metrics-trace',
    ],
  ),
  TmAlgorithmInventoryEntry(
    id: 'tm-execution-analyzer',
    sourcePath: 'lib/core/algorithms/tm_execution_analyzer.dart',
    entryPoints: ['analyze', 'analyzeTokens'],
    properties: [
      'tm.oracle-parity',
      'tm.outcome-lattice',
      'tm.trace-replay',
    ],
  ),
  TmAlgorithmInventoryEntry(
    id: 'tm-multi-tape-analyzer',
    sourcePath: 'lib/core/algorithms/tm_multi_tape_execution_analyzer.dart',
    entryPoints: ['analyze', 'analyzeTokens'],
    properties: ['tm.multi-tape-atomicity', 'tm.metrics-trace'],
  ),
  TmAlgorithmInventoryEntry(
    id: 'tm-simulator',
    sourcePath: 'lib/core/algorithms/tm_simulator.dart',
    entryPoints: [
      'simulateDTM',
      'simulateNTM',
      'simulate',
      'simulateCooperative',
      'accepts',
      'rejects',
      'findAcceptedStrings',
      'findRejectedStrings',
      'analyzeTM',
    ],
    properties: ['tm.runner-parity'],
  ),
  TmAlgorithmInventoryEntry(
    id: 'tm-native-runner',
    sourcePath: 'lib/core/services/simulation_runner_backend_native.dart',
    entryPoints: ['SimulationRunner.runTm'],
    properties: ['tm.runner-parity'],
  ),
  TmAlgorithmInventoryEntry(
    id: 'tm-web-cooperative-runner',
    sourcePath: 'lib/core/services/simulation_runner_backend_web.dart',
    entryPoints: ['createWebSimulationRunnerBackend', 'runTm'],
    properties: ['tm.runner-parity'],
  ),
  TmAlgorithmInventoryEntry(
    id: 'tm-reachability',
    sourcePath: 'lib/core/algorithms/tm_reachability_analyzer.dart',
    entryPoints: ['analyze', 'structurallyReachableStateIds'],
    properties: ['tm.reachability-language'],
  ),
  TmAlgorithmInventoryEntry(
    id: 'tm-language-explorer',
    sourcePath: 'lib/core/algorithms/tm_language_explorer.dart',
    entryPoints: ['countCandidates', 'explore'],
    properties: ['tm.reachability-language', 'tm.outcome-lattice'],
  ),
  TmAlgorithmInventoryEntry(
    id: 'tm-space-profiler',
    sourcePath: 'lib/core/algorithms/tm_space_profiler.dart',
    entryPoints: [
      'countCandidatesForLength',
      'countCandidatesThroughLength',
      'countScheduledCandidates',
      'profile',
    ],
    properties: ['tm.metrics-trace'],
  ),
  TmAlgorithmInventoryEntry(
    id: 'tm-time-profiler',
    sourcePath: 'lib/core/algorithms/tm_time_profiler.dart',
    entryPoints: ['plan', 'profile'],
    properties: ['tm.metrics-trace'],
  ),
  TmAlgorithmInventoryEntry(
    id: 'tm-block-dependency',
    sourcePath: 'lib/core/algorithms/tm_block_dependency_analyzer.dart',
    entryPoints: ['analyze'],
    properties: ['tm.building-blocks'],
  ),
  TmAlgorithmInventoryEntry(
    id: 'tm-block-execution',
    sourcePath: 'lib/core/algorithms/tm_block_execution_engine.dart',
    entryPoints: ['execute'],
    properties: ['tm.building-blocks'],
  ),
  TmAlgorithmInventoryEntry(
    id: 'tm-block-inline',
    sourcePath: 'lib/core/algorithms/tm_block_inline_expander.dart',
    entryPoints: ['expand'],
    properties: ['tm.building-blocks'],
  ),
  TmAlgorithmInventoryEntry(
    id: 'tm-block-project-editor',
    sourcePath: 'lib/core/services/tm_block_project_editor.dart',
    entryPoints: [
      'renameDefinition',
      'deleteDefinition',
      'replaceDefinitionMachine',
      'upsertInvocation',
      'undo',
      'redo',
    ],
    properties: ['tm.building-blocks'],
  ),
  TmAlgorithmInventoryEntry(
    id: 'tm-to-unrestricted-grammar',
    sourcePath:
        'lib/core/algorithms/tm_to_unrestricted_grammar/tm_to_grammar_converter.dart',
    entryPoints: ['TMToGrammarConverter.build'],
    properties: ['tm.grammar-conversion'],
  ),
  TmAlgorithmInventoryEntry(
    id: 'tm-grammar-differential',
    sourcePath:
        'lib/core/algorithms/tm_to_unrestricted_grammar/tm_to_grammar_differential_checker.dart',
    entryPoints: ['TMToGrammarDifferentialChecker.check'],
    properties: ['tm.grammar-conversion'],
  ),
];

const tmPropertyIds = <String>{
  'tm.inventory',
  'tm.model-serialization',
  'tm.oracle-parity',
  'tm.runner-parity',
  'tm.outcome-lattice',
  'tm.multi-tape-atomicity',
  'tm.reachability-language',
  'tm.metrics-trace',
  'tm.building-blocks',
  'tm.grammar-conversion',
  'tm.trace-replay',
  'tm.generated-shrink',
  'tm.mutations',
};

/// Property that executes every public entry point of each inventoried path.
///
/// The certification runner only emits inventory execution evidence after the
/// assigned property has passed. Keeping this separate from source discovery
/// makes a newly declared entry point fail the inventory until it has a real
/// runtime probe.
const tmEntrypointEvidencePropertyByAlgorithmId = <String, String>{
  'tm-model': 'tm.model-serialization',
  'tm-transition': 'tm.model-serialization',
  'tm-acceptance-policy': 'tm.outcome-lattice',
  'tm-execution-kernel': 'tm.multi-tape-atomicity',
  'tm-execution-analyzer': 'tm.oracle-parity',
  'tm-multi-tape-analyzer': 'tm.multi-tape-atomicity',
  'tm-simulator': 'tm.runner-parity',
  'tm-native-runner': 'tm.runner-parity',
  'tm-web-cooperative-runner': 'tm.runner-parity',
  'tm-reachability': 'tm.reachability-language',
  'tm-language-explorer': 'tm.reachability-language',
  'tm-space-profiler': 'tm.metrics-trace',
  'tm-time-profiler': 'tm.metrics-trace',
  'tm-block-dependency': 'tm.building-blocks',
  'tm-block-execution': 'tm.building-blocks',
  'tm-block-inline': 'tm.building-blocks',
  'tm-block-project-editor': 'tm.building-blocks',
  'tm-to-unrestricted-grammar': 'tm.grammar-conversion',
  'tm-grammar-differential': 'tm.grammar-conversion',
};

/// Entry points actually invoked by the assigned evidence property.
///
/// This intentionally duplicates the public inventory boundary: adding or
/// renaming an inventory entry point cannot silently inherit a passing marker.
const tmExecutedEntrypointsByAlgorithmId = <String, Set<String>>{
  'tm-model': {'validate', 'documentVariant', 'toJson', 'fromJson'},
  'tm-transition': {
    'formatLabel',
    'formatVectorLabel',
    'operationsForTapeCount',
    'toJson',
    'fromJson',
  },
  'tm-acceptance-policy': {'TMAcceptancePolicyEvaluator.evaluate'},
  'tm-execution-kernel': {
    'initialTapesTokens',
    'snapshotMulti',
    'transitionsForVector',
    'readVector',
    'applyTransition',
    'moveHead',
    'TMTraceMetricsAccumulator',
  },
  'tm-execution-analyzer': {'analyze', 'analyzeTokens'},
  'tm-multi-tape-analyzer': {'analyze', 'analyzeTokens'},
  'tm-simulator': {
    'simulateDTM',
    'simulateNTM',
    'simulate',
    'simulateCooperative',
    'accepts',
    'rejects',
    'findAcceptedStrings',
    'findRejectedStrings',
    'analyzeTM',
  },
  'tm-native-runner': {'SimulationRunner.runTm'},
  'tm-web-cooperative-runner': {
    'createWebSimulationRunnerBackend',
    'runTm',
  },
  'tm-reachability': {'analyze', 'structurallyReachableStateIds'},
  'tm-language-explorer': {'countCandidates', 'explore'},
  'tm-space-profiler': {
    'countCandidatesForLength',
    'countCandidatesThroughLength',
    'countScheduledCandidates',
    'profile',
  },
  'tm-time-profiler': {'plan', 'profile'},
  'tm-block-dependency': {'analyze'},
  'tm-block-execution': {'execute'},
  'tm-block-inline': {'expand'},
  'tm-block-project-editor': {
    'renameDefinition',
    'deleteDefinition',
    'replaceDefinitionMachine',
    'upsertInvocation',
    'undo',
    'redo',
  },
  'tm-to-unrestricted-grammar': {'TMToGrammarConverter.build'},
  'tm-grammar-differential': {'TMToGrammarDifferentialChecker.check'},
};
