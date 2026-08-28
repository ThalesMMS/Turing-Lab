import 'package:turing_lab/core/l_systems/l_systems.dart';
import 'package:turing_lab/core/pumping_lemma/pumping_lemma.dart';
import 'package:turing_lab/core/transducers/transducers.dart';

import '../catalog.dart';
import '../mutation.dart';
import '../runner.dart';
import '../shrinking.dart';
import 'formal_systems_certification.dart';

final class FormalSystemsHardEdgeDescriptor {
  const FormalSystemsHardEdgeDescriptor({
    required this.caseId,
    required this.algorithm,
    required this.property,
    this.expectedInternalOutcome = FormalSystemsCertificationOutcome.verified,
  });

  final String caseId;
  final String algorithm;
  final String property;
  final FormalSystemsCertificationOutcome expectedInternalOutcome;

  Map<String, Object?> fixture({required int seed}) => {
        'caseId': caseId,
        'expectedInternalOutcome': expectedInternalOutcome.name,
        if (_replayPayload(caseId, seed) case final payload?)
          'payload': payload,
        'schema': formalSystemsFixtureSchema,
        'seed': seed,
      };
}

final List<FormalSystemsHardEdgeDescriptor> formalSystemsHardEdgeDescriptors =
    List.unmodifiable(const [
  FormalSystemsHardEdgeDescriptor(
    caseId: 'transducer-analysis',
    algorithm: 'transducer-analyzer-transition-index',
    property: 'transducer.validation-determinism-completeness',
  ),
  FormalSystemsHardEdgeDescriptor(
    caseId: 'transducer-tokenizer',
    algorithm: 'transducer-input-tokenizer',
    property: 'transducer.maximal-munch-unicode',
  ),
  FormalSystemsHardEdgeDescriptor(
    caseId: 'transducer-mealy-oracle',
    algorithm: 'deterministic-mealy-simulator',
    property: 'transducer.independent-output-trace',
  ),
  FormalSystemsHardEdgeDescriptor(
    caseId: 'transducer-moore-oracle',
    algorithm: 'deterministic-moore-simulator',
    property: 'transducer.initial-output-and-prefixes',
  ),
  FormalSystemsHardEdgeDescriptor(
    caseId: 'transducer-trace-async',
    algorithm: 'transducer-sync-async-trace',
    property: 'transducer.trace-retention-equivalence',
  ),
  FormalSystemsHardEdgeDescriptor(
    caseId: 'transducer-batch',
    algorithm: 'transducer-batch-runner',
    property: 'transducer.batch-output-order',
  ),
  FormalSystemsHardEdgeDescriptor(
    caseId: 'transducer-equivalence-exact',
    algorithm: 'transducer-exact-equivalence',
    property: 'transducer.renaming-order-invariance',
  ),
  FormalSystemsHardEdgeDescriptor(
    caseId: 'transducer-equivalence-witness',
    algorithm: 'transducer-exact-equivalence',
    property: 'transducer.shortest-distinguishing-input',
    expectedInternalOutcome: FormalSystemsCertificationOutcome.different,
  ),
  FormalSystemsHardEdgeDescriptor(
    caseId: 'transducer-equivalence-bounded',
    algorithm: 'transducer-bounded-equivalence',
    property: 'transducer.finite-evidence-not-proof',
    expectedInternalOutcome: FormalSystemsCertificationOutcome.inconclusive,
  ),
  FormalSystemsHardEdgeDescriptor(
    caseId: 'transducer-model-graph-serialization',
    algorithm: 'transducer-model-graph-mapping',
    property: 'transducer.serialization-token-boundaries',
  ),
  FormalSystemsHardEdgeDescriptor(
    caseId: 'transducer-resource-outcomes',
    algorithm: 'deterministic-transducer-simulator',
    property: 'transducer.typed-incomplete-cancel-bound-invalid',
  ),
  FormalSystemsHardEdgeDescriptor(
    caseId: 'lsystem-parallel-oracle',
    algorithm: 'l-system-expander',
    property: 'lsystem.parallel-independent-oracle',
  ),
  FormalSystemsHardEdgeDescriptor(
    caseId: 'lsystem-zero-identity-epsilon',
    algorithm: 'l-system-expander',
    property: 'lsystem.zero-identity-epsilon',
  ),
  FormalSystemsHardEdgeDescriptor(
    caseId: 'lsystem-resource-outcomes',
    algorithm: 'l-system-growth-estimator',
    property: 'lsystem.typed-generation-symbol-memory-time-cancel',
  ),
  FormalSystemsHardEdgeDescriptor(
    caseId: 'lsystem-async-retention-stochastic',
    algorithm: 'l-system-async-streaming',
    property: 'lsystem.retention-seed-reproducibility',
  ),
  FormalSystemsHardEdgeDescriptor(
    caseId: 'lsystem-context-unsupported',
    algorithm: 'l-system-context-selector',
    property: 'lsystem.context-and-parametric-boundary',
  ),
  FormalSystemsHardEdgeDescriptor(
    caseId: 'turtle-geometry-oracle',
    algorithm: 'l-system-turtle-interpreter',
    property: 'turtle.geometry-bounds-stack-replay',
  ),
  FormalSystemsHardEdgeDescriptor(
    caseId: 'turtle-invalid-resource-outcomes',
    algorithm: 'l-system-turtle-interpreter',
    property: 'turtle.typed-stack-bound-cancel',
  ),
  FormalSystemsHardEdgeDescriptor(
    caseId: 'turtle-fit',
    algorithm: 'l-system-fit-transform',
    property: 'turtle.negative-bounds-fit',
  ),
  FormalSystemsHardEdgeDescriptor(
    caseId: 'turtle-svg-export',
    algorithm: 'l-system-svg-exporter',
    property: 'turtle.svg-deterministic-replay',
  ),
  FormalSystemsHardEdgeDescriptor(
    caseId: 'pumping-regular-oracle',
    algorithm: 'regular-pumping-decomposition-enumerator',
    property: 'pumping.regular-reconstruction-count',
  ),
  FormalSystemsHardEdgeDescriptor(
    caseId: 'pumping-cfl-oracle',
    algorithm: 'context-free-pumping-decomposition-enumerator',
    property: 'pumping.cfl-simultaneous-reconstruction-count',
  ),
  FormalSystemsHardEdgeDescriptor(
    caseId: 'pumping-typed-boundaries',
    algorithm: 'pumping-decomposition-validator',
    property: 'pumping.theorem-type-and-segment-constraints',
  ),
  FormalSystemsHardEdgeDescriptor(
    caseId: 'pumping-resource-evidence',
    algorithm: 'pumping-word-evidence',
    property: 'pumping.large-exponent-and-finite-evidence',
  ),
  FormalSystemsHardEdgeDescriptor(
    caseId: 'pumping-session-transition-table',
    algorithm: 'pumping-lemma-session-controller',
    property: 'pumping.adversarial-transition-model',
  ),
  FormalSystemsHardEdgeDescriptor(
    caseId: 'pumping-session-retry-restart',
    algorithm: 'pumping-lemma-session-controller',
    property: 'pumping.retry-restart-stale-isolation',
  ),
  FormalSystemsHardEdgeDescriptor(
    caseId: 'pumping-progress-migration',
    algorithm: 'pumping-lemma-progress-migration',
    property: 'pumping.theorem-owned-progress-migration',
  ),
  FormalSystemsHardEdgeDescriptor(
    caseId: 'pumping-document-roundtrip',
    algorithm: 'pumping-lemma-document-codec-model',
    property: 'pumping.typed-session-serialization',
  ),
  FormalSystemsHardEdgeDescriptor(
    caseId: 'pumping-membership-catalog',
    algorithm: 'pumping-lemma-problem-catalog',
    property: 'pumping.bounded-membership-disclosure',
  ),
]);

const formalSystemsMutationOperatorIds = {
  'drop-moore-initial-output',
  'rewrite-lsystem-sequentially',
  'pump-only-one-cfl-segment',
};

final class FormalSystemsHardEdgePropertyExecutor
    implements HardEdgeGeneratedPropertyExecutor {
  const FormalSystemsHardEdgePropertyExecutor();

  @override
  Future<HardEdgeExecutionOutcome> execute(
    HardEdgeCatalogCase testCase,
    Object? fixture,
  ) async {
    if (testCase.family != formalSystemsFamilyId) {
      throw HardEdgeConfigurationException(
        'Formal-systems executor cannot run family "${testCase.family}".',
      );
    }
    final parsed = _FormalSystemsFixture.parse(fixture);
    if (parsed.seed != testCase.seed) {
      throw const FormatException(
        'Formal-systems fixture seed must match catalog seed.',
      );
    }
    final descriptor = _descriptor(parsed.caseId);
    if (descriptor.algorithm != testCase.algorithm ||
        descriptor.property != testCase.property) {
      throw HardEdgeConfigurationException(
        'Formal-systems fixture ${parsed.caseId} does not match '
        '${testCase.algorithm}/${testCase.property}.',
      );
    }
    if (parsed.payload != null && !formalSystemsReplayAgrees(parsed.toJson())) {
      return HardEdgeExecutionOutcome.violation;
    }
    final report = await FormalSystemsCertification.run(
      FormalSystemsCertificationOptions(
        seedStart: parsed.seed,
        seedCount: 1,
        caseFilter: parsed.caseId,
      ),
    );
    final record = report.records.single;
    if (record.algorithm != testCase.algorithm ||
        record.property != testCase.property) {
      throw HardEdgeConfigurationException(
        'Formal-systems case ${parsed.caseId} resolved to '
        '${record.algorithm}/${record.property}.',
      );
    }
    return record.passed && record.actual == parsed.expectedInternalOutcome
        ? HardEdgeExecutionOutcome.pass
        : HardEdgeExecutionOutcome.violation;
  }

  @override
  Future<Object?> materialize(
    HardEdgeCatalogCase template,
    Object? templateFixture,
    int seed,
  ) async {
    final parsed = _FormalSystemsFixture.parse(templateFixture);
    final descriptor = _descriptor(parsed.caseId);
    if (template.algorithm != descriptor.algorithm ||
        template.property != descriptor.property) {
      throw const HardEdgeConfigurationException(
        'Formal-systems template metadata does not match its descriptor.',
      );
    }
    return descriptor.fixture(seed: seed);
  }
}

final class FormalSystemsHardEdgeMutationExecutor
    implements HardEdgeMutationExecutor {
  const FormalSystemsHardEdgeMutationExecutor();

  @override
  Future<HardEdgeMutationStatus> execute(
    HardEdgeMutation mutation,
    Object? fixture,
  ) async {
    if (mutation.family != formalSystemsFamilyId) {
      throw HardEdgeConfigurationException(
        'Formal-systems mutation executor cannot run '
        'family "${mutation.family}".',
      );
    }
    final parsed = _FormalSystemsFixture.parse(fixture);
    if (!formalSystemsMutationOperatorIds.contains(mutation.operatorId)) {
      throw HardEdgeConfigurationException(
        'Unknown formal-systems mutation "${mutation.operatorId}".',
      );
    }
    final result = runFormalSystemsMutationProbes(seed: parsed.seed)
        .singleWhere((item) => item.id == mutation.operatorId);
    return result.killed
        ? HardEdgeMutationStatus.killed
        : HardEdgeMutationStatus.survived;
  }
}

final class FormalSystemsFailureFixtureShrinker
    implements DomainShrinker<Object?> {
  const FormalSystemsFailureFixtureShrinker();

  @override
  Iterable<Object?> candidates(Object? value) sync* {
    final parsed = _FormalSystemsFixture.parse(value);
    final payload = parsed.payload;
    if (payload == null) return;
    final sourceReplayAgrees = formalSystemsReplayAgrees(value);
    final rawCandidates = switch (payload['kind']) {
      'transducer' => _transducerCandidates(parsed, payload),
      'l-system' => _lSystemCandidates(parsed, payload),
      'pumping' => _pumpingCandidates(parsed, payload),
      _ => const <Object?>[],
    };
    for (final candidate in rawCandidates) {
      if (formalSystemsFailureFixtureIsValid(candidate) &&
          formalSystemsFailureFixtureIsApplicable(candidate) &&
          formalSystemsReplayAgrees(candidate) == sourceReplayAgrees) {
        yield candidate;
      }
    }
  }
}

bool formalSystemsFailureFixtureIsValid(Object? value) {
  try {
    final parsed = _FormalSystemsFixture.parse(value);
    final descriptor = _descriptor(parsed.caseId);
    if (descriptor.expectedInternalOutcome != parsed.expectedInternalOutcome) {
      return false;
    }
    final payload = parsed.payload;
    if (payload == null) return true;
    switch (payload['kind']) {
      case 'transducer':
        final machine = MealyMachine.fromJson(_map(payload['machine']));
        final input = _strings(payload['input']);
        return TransducerAnalyzer.analyze(machine).isStructurallyValid &&
            input.every(
              (symbol) => machine.inputAlphabet.contains(
                TransducerInputSymbol(symbol),
              ),
            );
      case 'l-system':
        LSystemDocument.fromJson(_map(payload['document']));
        final generations = payload['generations'];
        return generations is int && generations >= 0;
      case 'pumping':
        final decomposition = PumpingDecomposition.fromJson(
          _map(payload['decomposition']),
        );
        final exponent = payload['exponent'];
        final pumpingLength = payload['pumpingLength'];
        final maximumTokens = payload['maximumTokens'];
        return exponent is int &&
            exponent >= 0 &&
            pumpingLength is int &&
            pumpingLength > 0 &&
            maximumTokens is int &&
            maximumTokens >= 0 &&
            decomposition.validate(pumpingLength: pumpingLength).isEmpty;
      default:
        return false;
    }
  } on Object {
    return false;
  }
}

bool formalSystemsFailureFixtureIsApplicable(Object? value) {
  if (!formalSystemsFailureFixtureIsValid(value)) return false;
  final parsed = _FormalSystemsFixture.parse(value);
  final payload = parsed.payload;
  if (payload == null) return true;
  switch (payload['kind']) {
    case 'transducer':
      final machine = MealyMachine.fromJson(_map(payload['machine']));
      return independentTransducerRun(
        machine,
        TransducerInputWord.fromValues(_strings(payload['input'])),
      ).completed;
    case 'l-system':
      return _lSystemReplayOracleIsApplicable(
        LSystemDocument.fromJson(_map(payload['document'])),
        payload['generations']! as int,
      );
    case 'pumping':
      return true;
    default:
      return false;
  }
}

bool formalSystemsReplayAgrees(Object? value) {
  if (!formalSystemsFailureFixtureIsApplicable(value)) return false;
  final parsed = _FormalSystemsFixture.parse(value);
  final payload = parsed.payload;
  if (payload == null) return true;
  switch (payload['kind']) {
    case 'transducer':
      final machine = MealyMachine.fromJson(_map(payload['machine']));
      final input = TransducerInputWord.fromValues(_strings(payload['input']));
      final expected = independentTransducerRun(machine, input);
      final actual = DeterministicTransducerSimulator.mealy(machine).run(input);
      return actual is TransducerSuccess &&
          _iterableEquals(actual.output.values, expected.output);
    case 'l-system':
      final system = LSystemDocument.fromJson(_map(payload['document']));
      final generations = payload['generations']! as int;
      final actual = const LSystemExpander().expand(
        system,
        generations: generations,
      );
      return actual is LSystemExpansionCompleted &&
          _iterableEquals(
            actual.finalGeneration.word.symbols,
            independentLSystemExpand(system, generations),
          );
    case 'pumping':
      final decomposition = PumpingDecomposition.fromJson(
        _map(payload['decomposition']),
      );
      final exponent = payload['exponent']! as int;
      final maximumTokens = payload['maximumTokens']! as int;
      final actual = decomposition.pumpBounded(
        exponent,
        maximumTokens: maximumTokens,
      );
      final expected = _independentPumpingOutcome(
        decomposition,
        exponent,
        maximumTokens,
      );
      if (actual is PumpingWordCompleted && expected is PumpingWordCompleted) {
        return _iterableEquals(actual.tokens, expected.tokens);
      }
      return actual is PumpingWordBounded &&
          expected is PumpingWordBounded &&
          actual.maximumTokens == expected.maximumTokens &&
          actual.minimumRequiredTokens == expected.minimumRequiredTokens;
    default:
      return false;
  }
}

bool _lSystemReplayOracleIsApplicable(
  LSystemDocument document,
  int generations,
) {
  if (generations < 0 ||
      generations > 64 ||
      document.unsupportedVariants.isNotEmpty ||
      document.productions.any(
        (production) =>
            !production.leftContext.isEmpty || !production.rightContext.isEmpty,
      )) {
    return false;
  }
  final predecessors = <String>{};
  if (document.productions.any(
    (production) => !predecessors.add(production.predecessor),
  )) {
    return false;
  }
  const maximumOracleSymbols = 100000;
  if (document.axiom.length > maximumOracleSymbols) return false;
  var counts = <String, int>{};
  for (final symbol in document.axiom.symbols) {
    counts.update(symbol, (value) => value + 1, ifAbsent: () => 1);
  }
  final productions = {
    for (final production in document.productions)
      production.predecessor: production.successor.symbols,
  };
  for (var generation = 0; generation < generations; generation++) {
    final next = <String, int>{};
    var total = 0;
    for (final entry in counts.entries) {
      final successors = productions[entry.key] ?? [entry.key];
      for (final successor in successors) {
        if (entry.value > maximumOracleSymbols - total) return false;
        total += entry.value;
        next.update(
          successor,
          (value) => value + entry.value,
          ifAbsent: () => entry.value,
        );
      }
    }
    counts = next;
  }
  return true;
}

PumpingWordOutcome _independentPumpingOutcome(
  PumpingDecomposition decomposition,
  int exponent,
  int maximumTokens,
) {
  var fixedTokens = 0;
  var repeatedTokens = 0;
  for (final segment in decomposition.segments) {
    if (segment.pumped) {
      repeatedTokens += segment.tokens.length;
    } else {
      fixedTokens += segment.tokens.length;
    }
  }
  if (fixedTokens > maximumTokens ||
      repeatedTokens > 0 &&
          exponent > (maximumTokens - fixedTokens) ~/ repeatedTokens) {
    return PumpingWordBounded(
      maximumTokens: maximumTokens,
      minimumRequiredTokens: maximumTokens + 1,
    );
  }
  return PumpingWordCompleted(independentPumpedWord(decomposition, exponent));
}

final class _FormalSystemsFixture {
  const _FormalSystemsFixture({
    required this.caseId,
    required this.seed,
    required this.expectedInternalOutcome,
    required this.payload,
  });

  final String caseId;
  final int seed;
  final FormalSystemsCertificationOutcome expectedInternalOutcome;
  final Map<String, Object?>? payload;

  factory _FormalSystemsFixture.parse(Object? source) {
    final json = _map(source);
    const requiredKeys = {
      'caseId',
      'expectedInternalOutcome',
      'schema',
      'seed',
    };
    if (json.keys.any(
      (key) => !requiredKeys.contains(key) && key != 'payload',
    )) {
      throw const FormatException(
        'Formal-systems fixture contains unknown fields.',
      );
    }
    if (json['schema'] != formalSystemsFixtureSchema ||
        json['caseId'] is! String ||
        json['seed'] is! int ||
        json['expectedInternalOutcome'] is! String) {
      throw const FormatException('Malformed formal-systems fixture.');
    }
    final seed = json['seed']! as int;
    if (seed < 0 || seed > 0xffffffff) {
      throw const FormatException('Formal-systems fixture seed is invalid.');
    }
    return _FormalSystemsFixture(
      caseId: json['caseId']! as String,
      seed: seed,
      expectedInternalOutcome: FormalSystemsCertificationOutcome.values.byName(
        json['expectedInternalOutcome']! as String,
      ),
      payload: json['payload'] == null ? null : _map(json['payload']),
    );
  }

  Map<String, Object?> toJson() => {
        'caseId': caseId,
        'expectedInternalOutcome': expectedInternalOutcome.name,
        if (payload != null) 'payload': payload,
        'schema': formalSystemsFixtureSchema,
        'seed': seed,
      };

  _FormalSystemsFixture copyWith({Map<String, Object?>? payload}) =>
      _FormalSystemsFixture(
        caseId: caseId,
        seed: seed,
        expectedInternalOutcome: expectedInternalOutcome,
        payload: payload ?? this.payload,
      );
}

Map<String, Object?>? _replayPayload(String caseId, int seed) =>
    switch (caseId) {
      'transducer-mealy-oracle' => {
          'kind': 'transducer',
          'input': const ['aa', '🙂', 'a'],
          'machine': formalSystemsMealyFixture(seed).toJson(),
        },
      'lsystem-parallel-oracle' => {
          'kind': 'l-system',
          'document': formalSystemsLSystemFixture(seed).toJson(),
          'generations': 3,
        },
      'pumping-regular-oracle' => {
          'kind': 'pumping',
          'decomposition': formalSystemsRegularDecompositionFixture().toJson(),
          'exponent': 2,
          'maximumTokens': 32,
          'pumpingLength': 3,
        },
      _ => null,
    };

FormalSystemsHardEdgeDescriptor _descriptor(String caseId) {
  for (final descriptor in formalSystemsHardEdgeDescriptors) {
    if (descriptor.caseId == caseId) return descriptor;
  }
  throw FormatException('Unknown formal-systems case "$caseId".');
}

Iterable<Object?> _transducerCandidates(
  _FormalSystemsFixture fixture,
  Map<String, Object?> payload,
) sync* {
  final input = _strings(payload['input']);
  for (var index = input.length - 1; index >= 0; index--) {
    final candidate = input.toList()..removeAt(index);
    yield fixture.copyWith(payload: {...payload, 'input': candidate}).toJson();
  }
  final machine = MealyMachine.fromJson(_map(payload['machine']));
  for (final transition in machine.transitions.reversed) {
    yield fixture.copyWith(payload: {
      ...payload,
      'machine': machine
          .copyWith(
            transitions:
                machine.transitions.where((item) => item.id != transition.id),
          )
          .toJson(),
    }).toJson();
  }
  for (final state in machine.states.where((item) => !item.isInitial)) {
    yield fixture.copyWith(payload: {
      ...payload,
      'machine': machine
          .copyWith(
            states: machine.states.where((item) => item.id != state.id),
            transitions: machine.transitions.where(
              (item) => item.from != state.id && item.to != state.id,
            ),
          )
          .toJson(),
    }).toJson();
  }
}

Iterable<Object?> _lSystemCandidates(
  _FormalSystemsFixture fixture,
  Map<String, Object?> payload,
) sync* {
  final generations = payload['generations']! as int;
  if (generations > 0) {
    yield fixture.copyWith(
        payload: {...payload, 'generations': generations - 1}).toJson();
  }
  final document = LSystemDocument.fromJson(_map(payload['document']));
  for (var index = document.axiom.length - 1; index >= 0; index--) {
    final symbols = document.axiom.symbols.toList()..removeAt(index);
    yield fixture.copyWith(payload: {
      ...payload,
      'document': _copyLSystem(document, axiom: LSystemWord(symbols)).toJson(),
    }).toJson();
  }
  for (final production in document.productions.reversed) {
    yield fixture.copyWith(payload: {
      ...payload,
      'document': _copyLSystem(
        document,
        productions:
            document.productions.where((item) => item.id != production.id),
      ).toJson(),
    }).toJson();
  }
}

Iterable<Object?> _pumpingCandidates(
  _FormalSystemsFixture fixture,
  Map<String, Object?> payload,
) sync* {
  final exponent = payload['exponent']! as int;
  if (exponent > 0) {
    yield fixture
        .copyWith(payload: {...payload, 'exponent': exponent - 1}).toJson();
  }
  final decomposition = _map(payload['decomposition']);
  final theorem = decomposition['theorem'];
  final fields = theorem == 'regular'
      ? const ['x', 'y', 'z']
      : const ['u', 'v', 'x', 'y', 'z'];
  for (final field in fields) {
    final tokens = _strings(decomposition[field]);
    for (var index = tokens.length - 1; index >= 0; index--) {
      final candidateTokens = tokens.toList()..removeAt(index);
      final candidateDecomposition = {
        ...decomposition,
        field: candidateTokens,
      };
      yield fixture.copyWith(payload: {
        ...payload,
        'decomposition': candidateDecomposition,
      }).toJson();
    }
  }
}

LSystemDocument _copyLSystem(
  LSystemDocument source, {
  LSystemWord? axiom,
  Iterable<LSystemProduction>? productions,
}) =>
    LSystemDocument(
      id: source.id,
      name: source.name,
      revision: source.revision,
      axiom: axiom ?? source.axiom,
      productions: productions ?? source.productions,
      iterations: source.iterations,
      turtle: source.turtle,
      commandMapping: source.commandMapping,
      randomSeed: source.randomSeed,
      ignoredContextSymbols: source.ignoredContextSymbols,
      unsupportedVariants: source.unsupportedVariants,
      unsupportedMetadata: source.unsupportedMetadata,
    );

Map<String, Object?> _map(Object? value) {
  if (value is! Map) throw const FormatException('Expected an object.');
  try {
    return Map<String, Object?>.from(value);
  } on TypeError {
    throw const FormatException('Object keys must be strings.');
  }
}

List<String> _strings(Object? value) {
  if (value is! List || value.any((item) => item is! String)) {
    throw const FormatException('Expected a string list.');
  }
  return List<String>.unmodifiable(value.cast<String>());
}

bool _iterableEquals<T>(Iterable<T> left, Iterable<T> right) {
  final leftValues = left.toList();
  final rightValues = right.toList();
  if (leftValues.length != rightValues.length) return false;
  for (var index = 0; index < leftValues.length; index++) {
    if (leftValues[index] != rightValues[index]) return false;
  }
  return true;
}
