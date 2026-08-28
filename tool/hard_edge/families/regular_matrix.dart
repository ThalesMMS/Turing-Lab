final class RegularAlgorithmInventoryEntry {
  const RegularAlgorithmInventoryEntry({
    required this.id,
    required this.sourcePath,
    required this.entryPoints,
    required this.properties,
    this.evidenceCommand = 'dart run tool/hard_edge_regular.dart',
  });

  final String id;
  final String sourcePath;
  final List<String> entryPoints;
  final List<String> properties;
  final String evidenceCommand;

  Map<String, Object?> toJson() => {
        'entryPoints': entryPoints,
        'evidenceCommand': evidenceCommand,
        'id': id,
        'properties': properties,
        'sourcePath': sourcePath,
      };
}

const regularAlgorithmInventory = <RegularAlgorithmInventoryEntry>[
  RegularAlgorithmInventoryEntry(
    id: 'fsa-model',
    sourcePath: 'lib/core/models/fsa.dart',
    entryPoints: [
      'validate',
      'isDeterministic',
      'isFiniteLanguage',
      'getEpsilonClosure',
    ],
    properties: ['regular.model-integrity', 'regular.generated-oracle'],
  ),
  RegularAlgorithmInventoryEntry(
    id: 'fsa-simulator',
    sourcePath: 'lib/core/algorithms/automaton_simulator.dart',
    entryPoints: [
      'simulate',
      'simulateDFA',
      'simulateNFA',
      'accepts',
      'rejects',
      'findAcceptedStrings',
      'findRejectedStrings',
    ],
    properties: [
      'regular.generated-oracle',
      'regular.trace-replay',
      'regular.resource-outcomes',
    ],
  ),
  RegularAlgorithmInventoryEntry(
    id: 'nfa-determinization',
    sourcePath: 'lib/core/algorithms/nfa_to_dfa_converter.dart',
    entryPoints: ['convert', 'convertWithSteps'],
    properties: ['regular.determinization'],
  ),
  RegularAlgorithmInventoryEntry(
    id: 'fsa-determinizer-adapter',
    sourcePath: 'lib/core/algorithms/fsa_determinizer.dart',
    entryPoints: ['determinizeIfNeeded'],
    properties: ['regular.determinization'],
  ),
  RegularAlgorithmInventoryEntry(
    id: 'lambda-removal',
    sourcePath: 'lib/core/algorithms/dfa_operations.dart',
    entryPoints: ['FSAOperations.removeLambdaTransitions'],
    properties: ['regular.lambda-removal'],
  ),
  RegularAlgorithmInventoryEntry(
    id: 'dfa-completion',
    sourcePath: 'lib/core/algorithms/dfa_completer.dart',
    entryPoints: ['complete'],
    properties: ['regular.completion'],
  ),
  RegularAlgorithmInventoryEntry(
    id: 'dfa-minimization',
    sourcePath: 'lib/core/algorithms/dfa_minimizer.dart',
    entryPoints: ['minimize', 'minimizeWithSteps'],
    properties: ['regular.minimization'],
  ),
  RegularAlgorithmInventoryEntry(
    id: 'dfa-boolean-operations',
    sourcePath: 'lib/core/algorithms/dfa_operations.dart',
    entryPoints: ['complement', 'union', 'intersection', 'difference'],
    properties: ['regular.boolean-algebra'],
  ),
  RegularAlgorithmInventoryEntry(
    id: 'dfa-prefix-suffix-closures',
    sourcePath: 'lib/core/algorithms/dfa_operations.dart',
    entryPoints: ['prefixClosure', 'suffixClosure'],
    properties: ['regular.prefix-suffix'],
  ),
  RegularAlgorithmInventoryEntry(
    id: 'fsa-concatenation',
    sourcePath: 'lib/core/algorithms/fsa_concatenator.dart',
    entryPoints: ['concatenate'],
    properties: ['regular.structural-closures'],
  ),
  RegularAlgorithmInventoryEntry(
    id: 'fsa-kleene-star',
    sourcePath: 'lib/core/algorithms/fsa_kleene_star.dart',
    entryPoints: ['apply'],
    properties: ['regular.structural-closures'],
  ),
  RegularAlgorithmInventoryEntry(
    id: 'fsa-reversal',
    sourcePath: 'lib/core/algorithms/fsa_reverser.dart',
    entryPoints: ['reverse'],
    properties: ['regular.structural-closures'],
  ),
  RegularAlgorithmInventoryEntry(
    id: 'exact-equivalence',
    sourcePath: 'lib/core/algorithms/equivalence_checker.dart',
    entryPoints: ['areEquivalent', 'areEquivalentResult'],
    properties: ['regular.equivalence-witness'],
  ),
  RegularAlgorithmInventoryEntry(
    id: 'language-comparison',
    sourcePath: 'lib/core/algorithms/language_comparator.dart',
    entryPoints: ['compareLanguages'],
    properties: ['regular.equivalence-witness'],
  ),
  RegularAlgorithmInventoryEntry(
    id: 'fa-to-regex',
    sourcePath: 'lib/core/algorithms/fa_to_regex_converter.dart',
    entryPoints: ['convert', 'convertWithSteps'],
    properties: ['regular.fa-regex-roundtrip'],
  ),
  RegularAlgorithmInventoryEntry(
    id: 'regex-parser-and-converter',
    sourcePath: 'lib/core/algorithms/regex_to_nfa_converter.dart',
    entryPoints: ['validate', 'parse', 'convert', 'convertWithSteps'],
    properties: ['regular.regex-oracle', 'regular.fa-regex-roundtrip'],
  ),
  RegularAlgorithmInventoryEntry(
    id: 'regex-simplifier',
    sourcePath: 'lib/core/algorithms/regex_simplifier.dart',
    entryPoints: ['simplify', 'simplifyWithSteps'],
    properties: ['regular.regex-simplification'],
  ),
  RegularAlgorithmInventoryEntry(
    id: 'regex-analyzer',
    sourcePath: 'lib/core/algorithms/regex_analyzer.dart',
    entryPoints: [
      'analyze',
      'computeStarHeight',
      'computeNestingDepth',
      'extractAlphabet',
      'countOperators',
      'determineComplexity',
      'generateSampleStrings',
      'analyzeWithSamples',
    ],
    properties: ['regular.regex-analysis'],
  ),
  RegularAlgorithmInventoryEntry(
    id: 'fsa-regular-grammar',
    sourcePath: 'lib/core/algorithms/fsa_to_grammar_converter.dart',
    entryPoints: ['convert', 'tryConvert'],
    properties: ['regular.grammar-roundtrip'],
  ),
  RegularAlgorithmInventoryEntry(
    id: 'regular-grammar-fsa',
    sourcePath: 'lib/core/algorithms/grammar_to_fsa_converter.dart',
    entryPoints: ['convert'],
    properties: ['regular.grammar-roundtrip'],
  ),
  RegularAlgorithmInventoryEntry(
    id: 'fa-regex-manual-oracle',
    sourcePath: 'lib/core/manual_conversions/fa_to_regex_manual.dart',
    entryPoints: [
      'normalize',
      'inspectElimination',
      'validatePairLabel',
      'applyElimination',
      'finalRegex',
    ],
    properties: ['regular.fa-regex-roundtrip'],
  ),
  RegularAlgorithmInventoryEntry(
    id: 'regex-fa-manual-oracle',
    sourcePath: 'lib/core/manual_conversions/regex_to_fa_manual.dart',
    entryPoints: ['start', 'expectedFragment', 'createBase'],
    properties: ['regular.regex-oracle'],
  ),
];

const regularProviderInventory = <RegularAlgorithmInventoryEntry>[
  RegularAlgorithmInventoryEntry(
    id: 'automaton-algorithm-provider',
    sourcePath: 'lib/presentation/providers/automaton_algorithm_provider.dart',
    entryPoints: ['AutomatonAlgorithmNotifier'],
    properties: ['regular.provider-integration'],
    evidenceCommand:
        'flutter test test/unit/presentation/automaton_providers_integration_test.dart',
  ),
  RegularAlgorithmInventoryEntry(
    id: 'automaton-simulation-provider',
    sourcePath: 'lib/presentation/providers/automaton_simulation_provider.dart',
    entryPoints: ['simulateAutomaton'],
    properties: ['regular.provider-stale-result'],
    evidenceCommand:
        'flutter test test/unit/presentation/automaton_simulation_stale_test.dart',
  ),
  RegularAlgorithmInventoryEntry(
    id: 'regex-editor-provider',
    sourcePath: 'lib/presentation/providers/regex_editor_provider.dart',
    entryPoints: ['RegexEditorNotifier'],
    properties: ['regular.provider-stale-result', 'regular.regex-oracle'],
    evidenceCommand:
        'flutter test test/unit/providers/regex_editor_provider_test.dart',
  ),
];
