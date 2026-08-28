import '../catalog.dart';
import '../mutation.dart';
import '../runner.dart';
import '../shrinking.dart';
import 'grammar_certification.dart';

const grammarHardEdgeFixtureSchema = 'turing-lab.hard-edge.grammar-property.v1';

final class GrammarHardEdgeDescriptor {
  const GrammarHardEdgeDescriptor({
    required this.caseId,
    required this.algorithm,
    required this.property,
    this.expectedInternalOutcome = GrammarCertificationOutcome.verified,
    this.expectedOutcome = HardEdgeExpectedOutcome.pass,
  });

  final String caseId;
  final String algorithm;
  final String property;
  final GrammarCertificationOutcome expectedInternalOutcome;
  final HardEdgeExpectedOutcome expectedOutcome;

  Map<String, Object?> fixture({required int seed}) {
    final counterexample = caseId == 'parser-replay-shrink-fixture'
        ? grammarReplayShrinkCounterexample(seed)
        : null;
    return {
      'caseId': caseId,
      if (counterexample != null) 'counterexample': counterexample.toJson(),
      'expectedInternalOutcome': expectedInternalOutcome.name,
      'maximumWordLength': 3,
      'schema': grammarHardEdgeFixtureSchema,
      'seed': seed,
    };
  }
}

final List<GrammarHardEdgeDescriptor> grammarHardEdgeDescriptors =
    List.unmodifiable([
  const GrammarHardEdgeDescriptor(
    caseId: 'analysis-malformed',
    algorithm: 'grammar-validation',
    property: 'diagnostics.non-crashing',
    expectedOutcome: HardEdgeExpectedOutcome.invalid,
    expectedInternalOutcome: GrammarCertificationOutcome.invalid,
  ),
  const GrammarHardEdgeDescriptor(
    caseId: 'analysis-classification',
    algorithm: 'chomsky-classifier',
    property: 'classification.cfg',
  ),
  const GrammarHardEdgeDescriptor(
    caseId: 'analysis-structural-scc',
    algorithm: 'reachability-productivity-dependency-graph',
    property: 'analysis.scc-witnesses',
  ),
  const GrammarHardEdgeDescriptor(
    caseId: 'analysis-first-follow-ll1',
    algorithm: 'nullable-first-follow-ll1',
    property: 'predictive.fixed-point',
  ),
  const GrammarHardEdgeDescriptor(
    caseId: 'metamorphic-order-renaming',
    algorithm: 'grammar-model-and-parsers',
    property: 'metamorphic.insertion-order-and-symbol-renaming',
  ),
  const GrammarHardEdgeDescriptor(
    caseId: 'analysis-conflicts',
    algorithm: 'll1-lr1-conflict-analysis',
    property: 'conflicts.typed',
    expectedOutcome: HardEdgeExpectedOutcome.conflict,
    expectedInternalOutcome: GrammarCertificationOutcome.conflict,
  ),
  const GrammarHardEdgeDescriptor(
    caseId: 'analysis-ambiguity-incomplete',
    algorithm: 'ambiguity-heuristic',
    property: 'ambiguity.incompleteness-exposed',
  ),
  const GrammarHardEdgeDescriptor(
    caseId: 'transform-left-recursion-factor',
    algorithm: 'left-recursion-removal-left-factoring',
    property: 'transformation.language-preservation',
  ),
  const GrammarHardEdgeDescriptor(
    caseId: 'transform-cnf-gnf',
    algorithm: 'cnf-gnf-transformers',
    property: 'normal-form.language-preservation',
  ),
  const GrammarHardEdgeDescriptor(
    caseId: 'transform-reduce-useless-idempotent',
    algorithm: 'cfg-reduction',
    property: 'reduction.useless-language-and-idempotence',
  ),
  const GrammarHardEdgeDescriptor(
    caseId: 'parser-tokenizer-unicode-overlap',
    algorithm: 'grammar-input-tokenizer',
    property: 'tokenization.maximal-munch-unicode-whitespace',
  ),
  const GrammarHardEdgeDescriptor(
    caseId: 'parser-replay-shrink-fixture',
    algorithm: 'earley-independent-oracle',
    property: 'parser.replay-shrink',
  ),
  const GrammarHardEdgeDescriptor(
    caseId: 'parser-cyk-steps-typed',
    algorithm: 'cyk-parse-with-steps',
    property: 'parser.steps-and-failures-typed',
  ),
  const GrammarHardEdgeDescriptor(
    caseId: 'parser-dispatch-auto-fallback',
    algorithm: 'grammar-parser-dispatch',
    property: 'dispatch.auto-and-explicit-fallback',
  ),
  const GrammarHardEdgeDescriptor(
    caseId: 'parser-earley-malformed-timeout',
    algorithm: 'earley-recognizer',
    property: 'parser.malformed-and-timeout-typed',
  ),
  const GrammarHardEdgeDescriptor(
    caseId: 'analysis-ll1-lr1-boundary',
    algorithm: 'll1-canonical-lr1-capability-boundary',
    property: 'classification.lr1-not-ll1',
  ),
  const GrammarHardEdgeDescriptor(
    caseId: 'parser-ambiguity-multiple-trees',
    algorithm: 'brute-force-all-positions',
    property: 'ambiguity.multiple-derivation-witnesses',
  ),
  const GrammarHardEdgeDescriptor(
    caseId: 'transform-direct-left-recursion-entrypoint',
    algorithm: 'legacy-direct-left-recursion-entrypoint',
    property: 'transformation.deprecated-dispatch-equivalence',
  ),
  for (final input in const [
    'empty',
    'identifier',
    'identifier-identifier',
    'identifier-identifier-identifier',
    '-identifier',
  ])
    for (final parser in const [
      'earley',
      'cyk',
      'll1',
      'lr1',
      'recursive-descent',
      'brute-force',
    ])
      GrammarHardEdgeDescriptor(
        caseId: 'parser-$parser-$input',
        algorithm: parser,
        property: 'parser.differential-oracle',
        expectedInternalOutcome: input == 'empty' || input == '-identifier'
            ? GrammarCertificationOutcome.rejected
            : GrammarCertificationOutcome.accepted,
      ),
  for (final input in const [
    'identifier',
    'identifier-identifier',
    'identifier-identifier-identifier',
  ])
    GrammarHardEdgeDescriptor(
      caseId: 'trace-brute-$input',
      algorithm: 'brute-force-derivation-trace',
      property: 'trace.replay-yield',
    ),
  const GrammarHardEdgeDescriptor(
    caseId: 'lr1-stale-result',
    algorithm: 'canonical-lr1',
    property: 'stale-result.rejected',
    expectedInternalOutcome: GrammarCertificationOutcome.stale,
  ),
  const GrammarHardEdgeDescriptor(
    caseId: 'parser-cancellation',
    algorithm: 'lr1-brute-cancellation',
    property: 'limits.cancellation-typed',
    expectedInternalOutcome: GrammarCertificationOutcome.cancelled,
  ),
  const GrammarHardEdgeDescriptor(
    caseId: 'parser-bounds',
    algorithm: 'lr1-brute-resource-limits',
    property: 'limits.bounded-unknown-typed',
    expectedInternalOutcome: GrammarCertificationOutcome.boundedUnknown,
  ),
  const GrammarHardEdgeDescriptor(
    caseId: 'parser-recursive-timeout',
    algorithm: 'recursive-descent',
    property: 'limits.timeout-typed',
    expectedInternalOutcome: GrammarCertificationOutcome.boundedUnknown,
  ),
  const GrammarHardEdgeDescriptor(
    caseId: 'user-derivation-trace-stale',
    algorithm: 'user-controlled-derivation',
    property: 'derivation.trace-and-stale-revision',
    expectedInternalOutcome: GrammarCertificationOutcome.stale,
  ),
  const GrammarHardEdgeDescriptor(
    caseId: 'unrestricted-bounds-cancellation',
    algorithm: 'unrestricted-bounded-derivation',
    property: 'unrestricted.typed-limits',
  ),
  const GrammarHardEdgeDescriptor(
    caseId: 'conversion-regular-fsa-roundtrip',
    algorithm: 'grammar-fsa-conversions',
    property: 'conversion.bounded-language-roundtrip',
  ),
  const GrammarHardEdgeDescriptor(
    caseId: 'conversion-cfg-pda',
    algorithm: 'cfg-to-pda-ll-lr',
    property: 'conversion.pda-valid-and-source-immutable',
  ),
  const GrammarHardEdgeDescriptor(
    caseId: 'conversion-pda-cfg',
    algorithm: 'pda-to-cfg',
    property: 'conversion.structure-and-cancellation',
  ),
  const GrammarHardEdgeDescriptor(
    caseId: 'conversion-tm-unrestricted-grammar',
    algorithm: 'tm-to-unrestricted-grammar',
    property: 'conversion.construction-limit-typed',
    expectedInternalOutcome: GrammarCertificationOutcome.boundedUnknown,
  ),
]);

final class GrammarHardEdgePropertyExecutor
    implements HardEdgeGeneratedPropertyExecutor {
  const GrammarHardEdgePropertyExecutor();

  @override
  Future<HardEdgeExecutionOutcome> execute(
    HardEdgeCatalogCase testCase,
    Object? fixture,
  ) async {
    if (testCase.family != 'grammar') {
      throw HardEdgeConfigurationException(
        'Grammar executor cannot run family "${testCase.family}".',
      );
    }
    final parsed = _GrammarPropertyFixture.parse(fixture);
    if (parsed.seed != testCase.seed) {
      throw const FormatException(
        'Grammar fixture seed must match catalog seed.',
      );
    }
    if (parsed.caseId == 'parser-replay-shrink-fixture') {
      if (testCase.algorithm != 'earley-independent-oracle' ||
          testCase.property != 'parser.replay-shrink' ||
          parsed.counterexample == null) {
        throw const HardEdgeConfigurationException(
          'Grammar replay/shrink fixture metadata does not match its case.',
        );
      }
      return replayGrammarCounterexample(parsed.counterexample!)
          ? HardEdgeExecutionOutcome.violation
          : HardEdgeExecutionOutcome.pass;
    }
    final report = await GrammarFamilyCertification.run(
      GrammarCertificationOptions(
        seedStart: parsed.seed,
        seedCount: 1,
        maximumWordLength: parsed.maximumWordLength,
        caseFilter: parsed.caseId,
      ),
    );
    final record = report.records.single;
    if (record.algorithm != testCase.algorithm ||
        record.property != testCase.property) {
      throw HardEdgeConfigurationException(
        'Grammar fixture ${parsed.caseId} resolves to '
        '${record.algorithm}/${record.property}, not '
        '${testCase.algorithm}/${testCase.property}.',
      );
    }
    if (!record.definitive) return HardEdgeExecutionOutcome.bounded;
    if (record.actual != parsed.expectedInternalOutcome) {
      return HardEdgeExecutionOutcome.violation;
    }
    if (!record.passed) return HardEdgeExecutionOutcome.violation;
    if (testCase.expectedOutcome == HardEdgeExpectedOutcome.conflict &&
        record.actual == GrammarCertificationOutcome.conflict) {
      return HardEdgeExecutionOutcome.conflict;
    }
    if (testCase.expectedOutcome == HardEdgeExpectedOutcome.invalid &&
        record.actual == GrammarCertificationOutcome.invalid) {
      return HardEdgeExecutionOutcome.invalid;
    }
    return HardEdgeExecutionOutcome.pass;
  }

  @override
  Future<Object?> materialize(
    HardEdgeCatalogCase template,
    Object? templateFixture,
    int seed,
  ) async {
    final parsed = _GrammarPropertyFixture.parse(templateFixture);
    return parsed.copyWith(seed: seed).toJson();
  }
}

final class GrammarHardEdgeMutationExecutor
    implements HardEdgeMutationExecutor {
  const GrammarHardEdgeMutationExecutor();

  @override
  Future<HardEdgeMutationStatus> execute(
    HardEdgeMutation mutation,
    Object? fixture,
  ) async {
    if (mutation.family != 'grammar') {
      throw const FormatException('Grammar mutation family must be grammar.');
    }
    final parsed = _GrammarPropertyFixture.parse(fixture);
    final matches = runGrammarMutationProbes(seed: parsed.seed)
        .where((result) => result.id == mutation.operatorId)
        .toList();
    if (matches.length != 1) {
      throw FormatException(
        'Unknown grammar mutation operator "${mutation.operatorId}".',
      );
    }
    return matches.single.killed
        ? HardEdgeMutationStatus.killed
        : HardEdgeMutationStatus.survived;
  }
}

final class GrammarCounterexampleShrinker
    implements DomainShrinker<GrammarCounterexample> {
  const GrammarCounterexampleShrinker();

  @override
  Iterable<GrammarCounterexample> candidates(
    GrammarCounterexample value,
  ) sync* {
    final runes = value.input.runes.toList();
    for (var index = runes.length - 1; index >= 0; index--) {
      yield GrammarCounterexample(
        grammar: value.grammar,
        input: String.fromCharCodes([...runes]..removeAt(index)),
        seed: value.seed,
        property: value.property,
      );
    }
    final productions = value.grammar.productions.toList()
      ..sort((left, right) => right.id.compareTo(left.id));
    if (productions.length > 1) {
      for (final production in productions) {
        yield GrammarCounterexample(
          grammar: value.grammar.copyWith(
            productions: {...productions}..remove(production),
            modified: value.grammar.modified,
          ),
          input: value.input,
          seed: value.seed,
          property: value.property,
        );
      }
    }
  }
}

/// Central failure-artifact adapter for grammar replay/shrink fixtures.
///
/// Register this for family `grammar` together with
/// [grammarFailureFixtureIsValid] and [grammarFailureFixtureIsApplicable].
final class GrammarFailureFixtureShrinker implements DomainShrinker<Object?> {
  const GrammarFailureFixtureShrinker();

  @override
  Iterable<Object?> candidates(Object? value) sync* {
    final parsed = _GrammarPropertyFixture.parse(value);
    final counterexample = parsed.counterexample;
    if (counterexample == null) return;
    for (final candidate
        in const GrammarCounterexampleShrinker().candidates(counterexample)) {
      yield parsed.copyWith(counterexample: candidate).toJson();
    }
  }
}

bool grammarFailureFixtureIsValid(Object? value) {
  try {
    final parsed = _GrammarPropertyFixture.parse(value);
    final counterexample = parsed.counterexample;
    if (counterexample == null) {
      final descriptor = grammarHardEdgeDescriptors
          .where((item) => item.caseId == parsed.caseId)
          .firstOrNull;
      return descriptor != null &&
          descriptor.expectedInternalOutcome == parsed.expectedInternalOutcome;
    }
    final grammar = counterexample.grammar;
    if (!grammar.nonterminals.contains(grammar.startSymbol) ||
        grammar.productions.isEmpty ||
        grammar.productions.map((production) => production.id).toSet().length !=
            grammar.productions.length) {
      return false;
    }
    final declared = {...grammar.terminals, ...grammar.nonterminals};
    return grammar.productions.every(
      (production) =>
          production.isValid &&
          production.leftSide.length == 1 &&
          grammar.nonterminals.contains(production.leftSide.single) &&
          production.rightSide.every(declared.contains),
    );
  } on Object {
    return false;
  }
}

bool grammarFailureFixtureIsApplicable(Object? value) {
  try {
    final parsed = _GrammarPropertyFixture.parse(value);
    final counterexample = parsed.counterexample;
    if (counterexample == null) {
      return grammarHardEdgeDescriptors.any(
        (descriptor) =>
            descriptor.caseId == parsed.caseId &&
            descriptor.expectedInternalOutcome ==
                parsed.expectedInternalOutcome,
      );
    }
    return counterexample.property == 'parser.replay-shrink' &&
        independentBoundedDerives(
          counterexample.grammar,
          counterexample.input,
        ).definitive;
  } on Object {
    return false;
  }
}

final class _GrammarPropertyFixture {
  const _GrammarPropertyFixture({
    required this.caseId,
    required this.seed,
    required this.maximumWordLength,
    required this.expectedInternalOutcome,
    this.counterexample,
  });

  final String caseId;
  final int seed;
  final int maximumWordLength;
  final GrammarCertificationOutcome expectedInternalOutcome;
  final GrammarCounterexample? counterexample;

  factory _GrammarPropertyFixture.parse(Object? source) {
    if (source is! Map) {
      throw const FormatException(
          'Grammar property fixture must be an object.');
    }
    final json = <String, Object?>{
      for (final entry in source.entries) entry.key.toString(): entry.value,
    };
    const requiredKeys = {
      'caseId',
      'expectedInternalOutcome',
      'maximumWordLength',
      'schema',
      'seed',
    };
    const allowedKeys = {...requiredKeys, 'counterexample'};
    if (json.keys.toSet().difference(allowedKeys).isNotEmpty ||
        requiredKeys.difference(json.keys.toSet()).isNotEmpty ||
        json['schema'] != grammarHardEdgeFixtureSchema ||
        json['caseId'] is! String ||
        json['expectedInternalOutcome'] is! String ||
        json['seed'] is! int ||
        json['maximumWordLength'] is! int) {
      throw const FormatException('Invalid grammar property fixture schema.');
    }
    final seed = json['seed']! as int;
    final maximumWordLength = json['maximumWordLength']! as int;
    final expectedInternalOutcome = GrammarCertificationOutcome.values
        .where((outcome) => outcome.name == json['expectedInternalOutcome'])
        .firstOrNull;
    if (expectedInternalOutcome == null) {
      throw const FormatException('Invalid internal grammar outcome.');
    }
    final counterexample = json['counterexample'] == null
        ? null
        : json['counterexample'] is Map
            ? GrammarCounterexample.fromJson(
                Map<String, Object?>.from(json['counterexample']! as Map),
              )
            : throw const FormatException(
                'Grammar counterexample must be an object.',
              );
    if ((json['caseId'] == 'parser-replay-shrink-fixture') !=
        (counterexample != null)) {
      throw const FormatException(
        'Only the grammar replay/shrink case carries a counterexample.',
      );
    }
    if (counterexample != null &&
        (counterexample.seed != seed ||
            counterexample.property != 'parser.replay-shrink')) {
      throw const FormatException(
        'Grammar counterexample metadata must match its fixture.',
      );
    }
    if (seed < 0 || seed > 0xffffffff) {
      throw RangeError.range(seed, 0, 0xffffffff, 'seed');
    }
    if (maximumWordLength < 0 || maximumWordLength > 6) {
      throw RangeError.range(
        maximumWordLength,
        0,
        6,
        'maximumWordLength',
      );
    }
    return _GrammarPropertyFixture(
      caseId: json['caseId']! as String,
      seed: seed,
      maximumWordLength: maximumWordLength,
      expectedInternalOutcome: expectedInternalOutcome,
      counterexample: counterexample,
    );
  }

  _GrammarPropertyFixture copyWith({
    int? seed,
    GrammarCounterexample? counterexample,
  }) =>
      _GrammarPropertyFixture(
        caseId: caseId,
        seed: seed ?? this.seed,
        maximumWordLength: maximumWordLength,
        expectedInternalOutcome: expectedInternalOutcome,
        counterexample: (counterexample ?? this.counterexample) == null
            ? null
            : counterexample ??
                grammarReplayShrinkCounterexample(seed ?? this.seed),
      );

  Map<String, Object?> toJson() => {
        'caseId': caseId,
        if (counterexample != null) 'counterexample': counterexample!.toJson(),
        'expectedInternalOutcome': expectedInternalOutcome.name,
        'maximumWordLength': maximumWordLength,
        'schema': grammarHardEdgeFixtureSchema,
        'seed': seed,
      };
}
