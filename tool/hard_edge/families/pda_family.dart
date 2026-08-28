import 'dart:convert';
import 'dart:math' as math;

import 'package:turing_lab/core/algorithms/grammar_to_pda/cfg_to_pda.dart';
import 'package:turing_lab/core/algorithms/grammar_to_pda_converter.dart';
import 'package:turing_lab/core/algorithms/pda_language_emptiness_analyzer.dart';
import 'package:turing_lab/core/algorithms/pda_normalizer.dart';
import 'package:turing_lab/core/algorithms/pda_simplifier.dart';
import 'package:turing_lab/core/algorithms/pda_simulation_semantic_variant.dart';
import 'package:turing_lab/core/algorithms/pda_simulator.dart';
import 'package:turing_lab/core/algorithms/pda_to_cfg_converter.dart';
import 'package:turing_lab/core/formal_systems/formal_systems.dart';
import 'package:turing_lab/core/interoperability/interoperability.dart';
import 'package:turing_lab/core/models/grammar.dart';
import 'package:turing_lab/core/models/pda.dart';
import 'package:turing_lab/core/models/pda_transition.dart';
import 'package:turing_lab/core/models/pda_simplification.dart';
import 'package:turing_lab/core/models/production.dart';
import 'package:turing_lab/core/models/state.dart';
import 'package:turing_lab/core/models/step_explanation.dart';
import 'package:turing_lab/core/models/transition.dart';
import 'package:turing_lab/core/simulation_cancelled_exception.dart';
import 'package:turing_lab/data/codecs/pda_jflap_document_codec.dart';
import 'package:turing_lab/data/codecs/pda_json_document_codec.dart';
import 'package:vector_math/vector_math_64.dart';

import '../generation.dart';
import '../models.dart';
import '../outcomes.dart';
import '../resources.dart';
import '../shrinking.dart';
import 'pda_oracle.dart';

const pdaFamilySchema = 'turing-lab.hard-edge.pda-fixture.v1';
const pdaMutationKillThreshold = 4;

final class PdaHardEdgeFixture {
  const PdaHardEdgeFixture({
    required this.id,
    required this.seed,
    required this.property,
    required this.pda,
    required this.input,
    required this.mode,
    required this.expectedOutcome,
    this.propertyPayload = const {},
  });

  final String id;
  final int seed;
  final String property;
  final PDA pda;
  final String input;
  final PDAAcceptanceMode mode;
  final VerificationOutcomeCode expectedOutcome;
  final Map<String, Object?> propertyPayload;

  PdaHardEdgeFixture copyWith({
    String? id,
    PDA? pda,
    String? input,
    String? property,
    int? seed,
    VerificationOutcomeCode? expectedOutcome,
    Map<String, Object?>? propertyPayload,
  }) =>
      PdaHardEdgeFixture(
        id: id ?? this.id,
        seed: seed ?? this.seed,
        property: property ?? this.property,
        pda: pda ?? this.pda,
        input: input ?? this.input,
        mode: mode,
        expectedOutcome: expectedOutcome ?? this.expectedOutcome,
        propertyPayload: propertyPayload ?? this.propertyPayload,
      );

  factory PdaHardEdgeFixture.fromJson(Object? source) {
    if (source is! Map) {
      throw const FormatException('PDA hard-edge fixture must be an object.');
    }
    final json = <String, Object?>{
      for (final entry in source.entries) entry.key.toString(): entry.value,
    };
    if (json['schema'] != pdaFamilySchema ||
        json['id'] is! String ||
        json['seed'] is! int ||
        json['property'] is! String ||
        json['input'] is! String ||
        json['mode'] is! String ||
        json['expectedOutcome'] is! String ||
        json['pda'] is! Map) {
      throw const FormatException('PDA hard-edge fixture has invalid schema.');
    }
    return PdaHardEdgeFixture(
      id: json['id']! as String,
      seed: json['seed']! as int,
      property: json['property']! as String,
      pda: PDA.fromJson(Map<String, dynamic>.from(json['pda']! as Map)),
      input: json['input']! as String,
      mode: PDAAcceptanceMode.values.byName(json['mode']! as String),
      expectedOutcome: VerificationOutcomeCode.values.byName(
        json['expectedOutcome']! as String,
      ),
      propertyPayload: json['propertyPayload'] is Map
          ? Map<String, Object?>.unmodifiable(
              Map<String, Object?>.from(json['propertyPayload']! as Map),
            )
          : const {},
    );
  }

  Map<String, Object?> toJson() => {
        'expectedOutcome': expectedOutcome.name,
        'id': id,
        'input': input,
        'mode': mode.name,
        'pda': _canonicalPdaJson(pda),
        'property': property,
        'propertyPayload': propertyPayload,
        'schema': pdaFamilySchema,
        'seed': seed,
      };
}

final class PdaFixtureGenerator implements DomainGenerator<PdaHardEdgeFixture> {
  const PdaFixtureGenerator();

  @override
  PdaHardEdgeFixture generate(GenerationContext context) {
    final stackToken = context.random.nextBool() ? 'stack-token' : 'β';
    final count = 1 + context.random.nextInt(3);
    final initial = _state('q0', initial: true, x: 0);
    final pop = _state('q1', x: 120);
    final accepting = _state('q2', accepting: true, x: 240);
    final transitions = <PDATransition>{
      _transition(
        id: 'push-a',
        from: initial,
        to: initial,
        input: 'a',
        pop: '',
        push: [stackToken],
        controlPoint: Vector2(30, -30),
      ),
      _transition(
        id: 'first-b',
        from: initial,
        to: pop,
        input: 'b',
        pop: stackToken,
      ),
      _transition(
        id: 'more-b',
        from: pop,
        to: pop,
        input: 'b',
        pop: stackToken,
        controlPoint: Vector2(30, -30),
      ),
      _transition(
        id: 'finish',
        from: pop,
        to: accepting,
        input: '',
        pop: 'bottom',
      ),
    };
    final pda = _pda(
      id: 'generated-pda-${context.caseIndex}',
      states: {initial, pop, accepting},
      transitions: transitions,
      initial: initial,
      accepting: {accepting},
      alphabet: {'a', 'b'},
      stackAlphabet: {'bottom', stackToken},
      mode: PDAAcceptanceMode.both,
    );
    return PdaHardEdgeFixture(
      id: 'pda-${context.seed}-${context.caseIndex}',
      seed: context.seed,
      property: 'oracle-simulator-parity',
      pda: pda,
      input: '${'a' * count}${'b' * count}',
      mode: PDAAcceptanceMode.both,
      expectedOutcome: VerificationOutcomeCode.accepted,
    );
  }
}

GeneratedCase<PdaHardEdgeFixture> generatePdaHardEdgeCase({
  required int seed,
  int caseIndex = 0,
}) =>
    generateCase(
      family: 'pda',
      property: 'oracle-simulator-parity',
      generatorVersion: '1',
      seed: seed,
      caseIndex: caseIndex,
      mode: GenerationMode.valid,
      budget: const GenerationBudget(
        maxStates: 4,
        maxTransitions: 8,
        maxSymbols: 4,
        maxStackDepth: 8,
      ),
      generator: const PdaFixtureGenerator(),
      encodeValue: (value) => value.toJson(),
    );

PdaHardEdgeFixture materializePdaPropertyFixture({
  required String property,
  required int seed,
}) {
  if (!pdaCertificationProperties.contains(property)) {
    throw FormatException('Unknown PDA hard-edge property "$property".');
  }
  final base = generatePdaHardEdgeCase(seed: seed).value;
  PdaHardEdgeFixture metadata(
    PdaHardEdgeFixture fixture, {
    Map<String, Object?> propertyPayload = const {},
  }) =>
      fixture.copyWith(
        id: 'pda-$property-$seed',
        seed: seed,
        property: property,
        propertyPayload: propertyPayload,
      );

  return switch (property) {
    'unicode-prefix-stack-symbols' => metadata(pdaUnicodePrefixFixture()),
    'invalid-model' => metadata(
        _invalidPdaFixture(seed),
        propertyPayload: _invalidDocumentPayload(seed),
      ),
    'shortest-bfs-witness' => metadata(_shortestWitnessFixture(seed)),
    'resource-outcomes' => metadata(
        pdaMutationFixture(PdaOracleMutation.omitStackFromConfiguration),
        propertyPayload: const {
          'maxConfigurations': 0,
          'maxDepth': 0,
          'maxMemoryBytes': 0,
          'timeoutMicroseconds': 0,
        },
      ),
    'cfg-conversions' => metadata(
        base,
        propertyPayload: {
          'llGrammar': _llGrammar().toJson(),
          'lrGrammar': _lrGrammar().toJson(),
          'greibachGrammar': _greibachGrammar().toJson(),
        },
      ),
    'compound-conversions' => metadata(
        base.copyWith(pda: _singlePopConversionPda(), input: 'a'),
        propertyPayload: {'sourceGrammar': _greibachGrammar().toJson()},
      ),
    'bounded-language-evidence' => metadata(
        base,
        propertyPayload: {'llGrammar': _llGrammar().toJson()},
      ),
    'mutation-checks' => metadata(
        base,
        propertyPayload: {
          'mutationFixtures': {
            for (final mutation in PdaOracleMutation.values.skip(1))
              mutation.name:
                  pdaMutationFixture(mutation).copyWith(seed: seed).toJson(),
          },
        },
      ),
    _ => metadata(base),
  };
}

PdaHardEdgeFixture _invalidPdaFixture(int seed) {
  final invalid = PDA(
    id: 'invalid-pda-$seed',
    name: 'Invalid PDA',
    states: const {},
    transitions: const {},
    alphabet: const {},
    acceptingStates: const {},
    created: DateTime.utc(2026, 8, 26),
    modified: DateTime.utc(2026, 8, 26),
    bounds: const math.Rectangle(0.0, 0.0, 400.0, 300.0),
    stackAlphabet: const {},
    initialStackSymbol: '',
  );
  return PdaHardEdgeFixture(
    id: 'pda-invalid-model-$seed',
    seed: seed,
    property: 'invalid-model',
    pda: invalid,
    input: '',
    mode: PDAAcceptanceMode.finalState,
    expectedOutcome: VerificationOutcomeCode.invalidInput,
  );
}

Map<String, Object?> _invalidDocumentPayload(int seed) {
  final valid = generatePdaHardEdgeCase(seed: seed).value.pda.toJson();
  final duplicate = Map<String, dynamic>.from(valid);
  final duplicateTransitions = (valid['transitions'] as List)
      .map((item) => Map<String, dynamic>.from(item as Map))
      .toList();
  duplicateTransitions
      .add(Map<String, dynamic>.from(duplicateTransitions.first));
  duplicate['transitions'] = duplicateTransitions;

  final dangling = Map<String, dynamic>.from(valid);
  final danglingTransitions = (valid['transitions'] as List)
      .map((item) => Map<String, dynamic>.from(item as Map))
      .toList();
  danglingTransitions.first['toState'] = 'missing-state';
  dangling['transitions'] = danglingTransitions;
  final staleFrom = _state('stale-from', initial: false, x: 900).toJson();
  final staleTo = _state('stale-to', accepting: false, x: 950).toJson();
  return {
    'duplicateTransitionDocument': duplicate,
    'danglingEndpointDocument': dangling,
    'staleEndpointCopies': {
      'fromState': staleFrom,
      'toState': staleTo,
    },
  };
}

PDA _staleEndpointPda(Map<String, Object?> encodedCopies) {
  final canonicalFrom = _state('stale-from', initial: true, x: 0);
  final canonicalTo = _state('stale-to', accepting: true, x: 120);
  final encodedFrom = encodedCopies['fromState'];
  final encodedTo = encodedCopies['toState'];
  if (encodedFrom is! Map || encodedTo is! Map) {
    throw const FormatException('Stale endpoint fixture is malformed.');
  }
  final staleFrom = State.fromJson(Map<String, dynamic>.from(encodedFrom));
  final staleTo = State.fromJson(Map<String, dynamic>.from(encodedTo));
  return _pda(
    id: 'stale-endpoint-copies',
    states: {canonicalFrom, canonicalTo},
    transitions: {
      _transition(
        id: 'stale-copy-transition',
        from: staleFrom,
        to: staleTo,
        input: 'a',
        pop: '',
      ),
    },
    initial: canonicalFrom,
    accepting: {canonicalTo},
    alphabet: const {'a'},
    stackAlphabet: const {'bottom'},
  );
}

PdaHardEdgeFixture _shortestWitnessFixture(int seed) {
  final initial = _state('w0', initial: true, x: 0);
  final detour = _state('w1', x: 120);
  final accepting = _state('w2', accepting: true, x: 240);
  return PdaHardEdgeFixture(
    id: 'pda-shortest-bfs-witness-$seed',
    seed: seed,
    property: 'shortest-bfs-witness',
    pda: _pda(
      id: 'shortest-bfs-witness',
      states: {initial, detour, accepting},
      transitions: {
        _transition(
          id: 'a-long-first',
          from: initial,
          to: detour,
          input: '',
          pop: '',
        ),
        _transition(
          id: 'b-long-second',
          from: detour,
          to: accepting,
          input: 'a',
          pop: '',
        ),
        _transition(
          id: 'z-short',
          from: initial,
          to: accepting,
          input: 'a',
          pop: '',
        ),
      },
      initial: initial,
      accepting: {accepting},
      alphabet: const {'a'},
      stackAlphabet: const {'bottom'},
    ),
    input: 'a',
    mode: PDAAcceptanceMode.finalState,
    expectedOutcome: VerificationOutcomeCode.accepted,
  );
}

Grammar _fixtureGrammar(PdaHardEdgeFixture fixture, String key) {
  final encoded = fixture.propertyPayload[key];
  if (encoded is! Map) {
    throw FormatException(
      'PDA fixture ${fixture.id} is missing grammar payload "$key".',
    );
  }
  return Grammar.fromJson(Map<String, dynamic>.from(encoded));
}

int _fixtureInt(PdaHardEdgeFixture fixture, String key) {
  final value = fixture.propertyPayload[key];
  if (value is! int) {
    throw FormatException(
      'PDA fixture ${fixture.id} is missing integer payload "$key".',
    );
  }
  return value;
}

PdaHardEdgeFixture _fixtureMutation(
  PdaHardEdgeFixture fixture,
  PdaOracleMutation mutation,
) {
  final encodedFixtures = fixture.propertyPayload['mutationFixtures'];
  final encoded =
      encodedFixtures is Map ? encodedFixtures[mutation.name] : null;
  if (encoded is! Map) {
    throw FormatException(
      'PDA fixture ${fixture.id} is missing mutation payload '
      '"${mutation.name}".',
    );
  }
  return PdaHardEdgeFixture.fromJson(encoded);
}

final class PdaFixtureShrinker implements DomainShrinker<PdaHardEdgeFixture> {
  const PdaFixtureShrinker();

  @override
  Iterable<PdaHardEdgeFixture> candidates(PdaHardEdgeFixture value) sync* {
    for (final payload in _propertyPayloadCandidates(value.propertyPayload)) {
      yield value.copyWith(propertyPayload: payload);
    }
    if (value.input.isNotEmpty) {
      yield value.copyWith(input: '');
      if (value.input.length > 1) {
        yield value.copyWith(
          input: value.input.substring(0, value.input.length ~/ 2),
        );
      }
    }
    final transitions = value.pda.pdaTransitions.toList()
      ..sort((left, right) => left.id.compareTo(right.id));
    for (var index = transitions.length - 1; index >= 0; index--) {
      final reduced = [...transitions]..removeAt(index);
      yield value.copyWith(
        pda: value.pda.copyWith(
          transitions: reduced.map<Transition>((item) => item).toSet(),
        ),
      );
    }
    final removableStates = value.pda.states
        .where(
          (state) =>
              state != value.pda.initialState &&
              !value.pda.acceptingStates.contains(state),
        )
        .toList()
      ..sort((left, right) => left.id.compareTo(right.id));
    for (final removed in removableStates.reversed) {
      final states =
          value.pda.states.where((state) => state != removed).toSet();
      final retainedIds = states.map((state) => state.id).toSet();
      yield value.copyWith(
        pda: value.pda.copyWith(
          states: states,
          transitions: value.pda.pdaTransitions
              .where(
                (transition) =>
                    retainedIds.contains(transition.fromState.id) &&
                    retainedIds.contains(transition.toState.id),
              )
              .map<Transition>((item) => item)
              .toSet(),
        ),
      );
    }
  }

  Iterable<Map<String, Object?>> _propertyPayloadCandidates(
    Map<String, Object?> payload,
  ) sync* {
    final keys = payload.keys.toList()..sort();
    for (final key in keys) {
      final encoded = payload[key];
      if (_grammarPayloadKeys.contains(key) && encoded is Map) {
        try {
          final grammar = Grammar.fromJson(Map<String, dynamic>.from(encoded));
          for (final candidate in _grammarCandidates(grammar)) {
            yield {
              ...payload,
              key: candidate.toJson(),
            };
          }
        } on Object {
          // The family runner reports malformed payloads. A shrinker only
          // proposes candidates that it can decode without changing meaning.
        }
      }
      if (key == 'mutationFixtures' && encoded is Map) {
        final mutationKeys = encoded.keys.whereType<String>().toList()..sort();
        for (final mutationKey in mutationKeys) {
          final nestedJson = encoded[mutationKey];
          if (nestedJson is! Map) continue;
          try {
            final nested = PdaHardEdgeFixture.fromJson(nestedJson);
            for (final candidate in candidates(nested)) {
              yield {
                ...payload,
                key: {
                  ...Map<String, Object?>.from(encoded),
                  mutationKey: candidate.toJson(),
                },
              };
            }
          } on Object {
            // Ignore malformed nested fixtures for the same reason as above.
          }
        }
      }
    }
  }

  Iterable<Grammar> _grammarCandidates(Grammar grammar) sync* {
    final productions = grammar.productions.toList()
      ..sort((left, right) => left.id.compareTo(right.id));
    if (productions.length > 1) {
      for (var index = productions.length - 1; index >= 0; index--) {
        final reduced = [...productions]..removeAt(index);
        yield _compactGrammar(grammar.copyWith(productions: reduced.toSet()));
      }
    }
    for (var index = productions.length - 1; index >= 0; index--) {
      final production = productions[index];
      if (production.rightSide.isEmpty) continue;
      final shorterRightSide = production.rightSide.length == 1
          ? const <String>[]
          : production.rightSide.sublist(
              0,
              production.rightSide.length ~/ 2,
            );
      final replacement = production.copyWith(
        rightSide: shorterRightSide,
        isLambda: shorterRightSide.isEmpty,
      );
      final reduced = [...productions]..[index] = replacement;
      yield _compactGrammar(grammar.copyWith(productions: reduced.toSet()));
    }
  }

  Grammar _compactGrammar(Grammar grammar) {
    final usedSymbols = <String>{
      grammar.startSymbol,
      for (final production in grammar.productions) ...production.leftSide,
      for (final production in grammar.productions) ...production.rightSide,
    };
    return grammar.copyWith(
      terminals: grammar.terminals.intersection(usedSymbols),
      nonterminals: grammar.nonterminals.intersection(usedSymbols)
        ..add(grammar.startSymbol),
    );
  }
}

const _grammarPayloadKeys = {
  'greibachGrammar',
  'llGrammar',
  'lrGrammar',
  'sourceGrammar',
};

enum PdaCertificationStatus { passed, failed, inconclusive }

final class PdaCertificationCheck {
  PdaCertificationCheck({
    required this.id,
    required Iterable<String> algorithmIds,
    required this.status,
    required this.message,
  }) : algorithmIds = List<String>.unmodifiable(algorithmIds);

  final String id;
  final List<String> algorithmIds;
  final PdaCertificationStatus status;
  final String message;

  Map<String, Object?> toJson() => {
        'algorithmIds': algorithmIds,
        'id': id,
        'message': message,
        'status': status.name,
      };
}

final class PdaAlgorithmDescriptor {
  const PdaAlgorithmDescriptor({
    required this.id,
    required this.productionPath,
    required this.certificationCheckIds,
  });

  final String id;
  final String productionPath;
  final List<String> certificationCheckIds;
}

const pdaAlgorithmMatrix = <PdaAlgorithmDescriptor>[
  PdaAlgorithmDescriptor(
    id: 'simulation-sync',
    productionPath: 'lib/core/algorithms/pda_simulator.dart',
    certificationCheckIds: [
      'oracle-parity',
      'invalid-model',
      'trace-reconstruction',
      'unicode-prefix-stack-symbols',
      'shortest-bfs-witness',
      'resource-outcomes',
    ],
  ),
  PdaAlgorithmDescriptor(
    id: 'simulation-cooperative',
    productionPath: 'lib/core/algorithms/pda_simulator.dart',
    certificationCheckIds: ['cooperative-parity', 'resource-outcomes'],
  ),
  PdaAlgorithmDescriptor(
    id: 'configuration-search',
    productionPath: 'lib/core/algorithms/pda_simulator_search.dart',
    certificationCheckIds: [
      'oracle-parity',
      'resource-outcomes',
      'invalid-model',
      'trace-reconstruction',
      'unicode-prefix-stack-symbols',
      'shortest-bfs-witness',
    ],
  ),
  PdaAlgorithmDescriptor(
    id: 'normalization',
    productionPath: 'lib/core/algorithms/pda_normalizer.dart',
    certificationCheckIds: [
      'normalization-conversion',
      'validation-determinism-analysis',
    ],
  ),
  PdaAlgorithmDescriptor(
    id: 'simplification',
    productionPath: 'lib/core/algorithms/pda_simplifier.dart',
    certificationCheckIds: ['simplification', 'bounded-language-evidence'],
  ),
  PdaAlgorithmDescriptor(
    id: 'language-emptiness',
    productionPath: 'lib/core/algorithms/pda_language_emptiness_analyzer.dart',
    certificationCheckIds: ['language-emptiness'],
  ),
  PdaAlgorithmDescriptor(
    id: 'pda-to-cfg',
    productionPath: 'lib/core/algorithms/pda_to_cfg_converter.dart',
    certificationCheckIds: ['normalization-conversion'],
  ),
  PdaAlgorithmDescriptor(
    id: 'cfg-to-pda-general-standard-greibach',
    productionPath: 'lib/core/algorithms/grammar_to_pda_converter.dart',
    certificationCheckIds: ['cfg-conversions'],
  ),
  PdaAlgorithmDescriptor(
    id: 'cfg-to-pda-ll-lr',
    productionPath: 'lib/core/algorithms/grammar_to_pda/',
    certificationCheckIds: ['cfg-conversions', 'bounded-language-evidence'],
  ),
  PdaAlgorithmDescriptor(
    id: 'cfg-pda-differential',
    productionPath:
        'lib/core/algorithms/grammar_to_pda/cfg_to_pda_differential_checker.dart',
    certificationCheckIds: ['cfg-conversions', 'bounded-language-evidence'],
  ),
  PdaAlgorithmDescriptor(
    id: 'model-json-round-trip',
    productionPath: 'lib/core/models/pda.dart',
    certificationCheckIds: ['serialization'],
  ),
  PdaAlgorithmDescriptor(
    id: 'document-codecs',
    productionPath: 'lib/data/codecs/pda_*_document_codec.dart',
    certificationCheckIds: ['serialization'],
  ),
  PdaAlgorithmDescriptor(
    id: 'transition-validation',
    productionPath: 'lib/core/models/pda_transition.dart',
    certificationCheckIds: ['validation-determinism-analysis', 'invalid-model'],
  ),
  PdaAlgorithmDescriptor(
    id: 'pda-analysis',
    productionPath: 'lib/core/algorithms/pda_simulator_analysis.dart',
    certificationCheckIds: ['validation-determinism-analysis'],
  ),
  PdaAlgorithmDescriptor(
    id: 'bounded-string-generation',
    productionPath: 'lib/core/algorithms/pda_simulator_generation.dart',
    certificationCheckIds: ['validation-determinism-analysis'],
  ),
  PdaAlgorithmDescriptor(
    id: 'trace-stack-reconstruction',
    productionPath: 'lib/core/algorithms/pda_simulator_search.dart',
    certificationCheckIds: [
      'trace-reconstruction',
      'unicode-prefix-stack-symbols'
    ],
  ),
  PdaAlgorithmDescriptor(
    id: 'metamorphic-invariance',
    productionPath: 'tool/hard_edge/families/pda_family.dart',
    certificationCheckIds: ['metamorphic-renaming-order'],
  ),
  PdaAlgorithmDescriptor(
    id: 'compound-cfg-pda-cfg',
    productionPath: 'lib/core/algorithms/grammar_to_pda_converter.dart',
    certificationCheckIds: ['compound-conversions'],
  ),
  PdaAlgorithmDescriptor(
    id: 'compound-pda-cfg-pda',
    productionPath: 'lib/core/algorithms/pda_to_cfg_converter.dart',
    certificationCheckIds: ['compound-conversions'],
  ),
  PdaAlgorithmDescriptor(
    id: 'bounded-language-comparison',
    productionPath: 'lib/core/algorithms/pda_simplifier.dart',
    certificationCheckIds: ['bounded-language-evidence'],
  ),
];

final class PdaHardEdgeCaseDescriptor {
  const PdaHardEdgeCaseDescriptor({
    required this.algorithm,
    required this.property,
  });

  final String algorithm;
  final String property;
}

final pdaHardEdgeCaseDescriptors = List<PdaHardEdgeCaseDescriptor>.unmodifiable(
  [
    for (final algorithm in pdaAlgorithmMatrix)
      for (final property in algorithm.certificationCheckIds)
        PdaHardEdgeCaseDescriptor(
          algorithm: algorithm.id,
          property: property,
        ),
  ],
);

const pdaCertificationProperties = <String>[
  'oracle-parity',
  'cooperative-parity',
  'normalization-conversion',
  'simplification',
  'language-emptiness',
  'cfg-conversions',
  'serialization',
  'resource-outcomes',
  'mutation-checks',
  'validation-determinism-analysis',
  'trace-reconstruction',
  'invalid-model',
  'metamorphic-renaming-order',
  'compound-conversions',
  'bounded-language-evidence',
  'unicode-prefix-stack-symbols',
  'shortest-bfs-witness',
];

final class PdaCertificationReport {
  PdaCertificationReport({
    required this.seed,
    required Iterable<PdaCertificationCheck> checks,
  }) : checks = List<PdaCertificationCheck>.unmodifiable(checks);

  final int seed;
  final List<PdaCertificationCheck> checks;

  bool get passed => checks.every(
        (check) => check.status == PdaCertificationStatus.passed,
      );

  Set<String> get coveredAlgorithmIds => {
        for (final check in checks) ...check.algorithmIds,
      };

  Map<String, Object?> toJson() => {
        'checks': checks.map((check) => check.toJson()).toList(),
        'coverage': {
          'algorithms': coveredAlgorithmIds.toList()..sort(),
          'properties': checks.map((check) => check.id).toList()..sort(),
          'seeds': [seed],
        },
        'family': 'pda',
        'matrixAlgorithms': pdaAlgorithmMatrix.map((item) => item.id).toList(),
        'passed': passed,
        'remotelyVerified': false,
        'schema': 'turing-lab.hard-edge.pda-report.v1',
        'seed': seed,
      };
}

final class PdaCertificationRunner {
  const PdaCertificationRunner();

  Future<PdaCertificationReport> run({required int seed}) async {
    final checks = <PdaCertificationCheck>[
      for (final property in pdaCertificationProperties)
        await runProperty(
          property: property,
          fixture: materializePdaPropertyFixture(
            property: property,
            seed: seed,
          ),
        ),
    ];
    return PdaCertificationReport(seed: seed, checks: checks);
  }

  Future<PdaCertificationCheck> runProperty({
    required String property,
    required PdaHardEdgeFixture fixture,
  }) async {
    if (fixture.property != property) {
      throw FormatException(
        'PDA fixture ${fixture.id} materializes property '
        '"${fixture.property}", not "$property".',
      );
    }
    return switch (property) {
      'oracle-parity' => _oracleParity(fixture),
      'cooperative-parity' => _cooperativeParity(fixture),
      'normalization-conversion' => _normalizationConversion(fixture),
      'simplification' => _simplification(fixture),
      'language-emptiness' => _languageEmptiness(fixture),
      'cfg-conversions' => _cfgConversions(fixture),
      'serialization' => _serialization(fixture),
      'resource-outcomes' => _resourceOutcomes(fixture),
      'mutation-checks' => _mutationChecks(fixture),
      'validation-determinism-analysis' =>
        _validationDeterminismAnalysis(fixture),
      'trace-reconstruction' => _traceReconstruction(fixture),
      'invalid-model' => _invalidModel(fixture),
      'metamorphic-renaming-order' => _metamorphicRenamingOrder(fixture),
      'compound-conversions' => _compoundConversions(fixture),
      'bounded-language-evidence' => _boundedLanguageEvidence(fixture),
      'unicode-prefix-stack-symbols' => _unicodePrefixStackSymbols(fixture),
      'shortest-bfs-witness' => _shortestBfsWitness(fixture),
      _ => throw FormatException(
          'Unknown PDA hard-edge property "$property".',
        ),
    };
  }

  PdaCertificationCheck _oracleParity(PdaHardEdgeFixture fixture) {
    final oracle = const PdaExhaustiveExplorer().explore(
      pda: fixture.pda,
      input: fixture.input,
      mode: fixture.mode,
    );
    final simulation = PDASimulator.simulateNPDA(
      fixture.pda,
      fixture.input,
      mode: fixture.mode,
      stepByStep: true,
    );
    final canonical = _simulationOutcome(simulation);
    return _check(
      id: 'oracle-parity',
      algorithmIds: const ['simulation-sync', 'configuration-search'],
      passed: oracle.outcome == canonical &&
          oracle.outcome == fixture.expectedOutcome &&
          oracle.witness.isNotEmpty,
      message: 'oracle=${oracle.outcome.name}, canonical=${canonical.name}',
    );
  }

  Future<PdaCertificationCheck> _cooperativeParity(
    PdaHardEdgeFixture fixture,
  ) async {
    final synchronous = PDASimulator.simulateNPDA(
      fixture.pda,
      fixture.input,
      mode: fixture.mode,
    );
    final cooperative = await PDASimulator.simulateCooperative(
      fixture.pda,
      fixture.input,
      mode: fixture.mode,
      configurationsPerBatch: 1,
    );
    final left = _simulationOutcome(synchronous);
    final right = _simulationOutcome(cooperative);
    return _check(
      id: 'cooperative-parity',
      algorithmIds: const ['simulation-cooperative'],
      passed: left == right,
      message: 'sync=${left.name}, cooperative=${right.name}',
    );
  }

  PdaCertificationCheck _normalizationConversion(
    PdaHardEdgeFixture fixture,
  ) {
    final normalization = PDANormalizer.normalize(
      fixture.pda,
      sourceMode: fixture.mode,
      targetForm: PDANormalForm.finalStateAndEmptyStackAndSinglePop,
    );
    final conversion = normalization.isSuccess
        ? PDAtoCFGConverter.convert(
            normalization.data!.normalizedPda,
            maxGeneratedProductions: 50000,
          )
        : null;
    final normalizedOutcome = normalization.isSuccess
        ? _simulationOutcome(
            PDASimulator.simulateNPDA(
              normalization.data!.normalizedPda,
              fixture.input,
              mode: normalization.data!.targetMode,
            ),
          )
        : VerificationOutcomeCode.modelError;
    final passed = normalization.isSuccess &&
        conversion!.isSuccess &&
        normalizedOutcome == fixture.expectedOutcome &&
        normalization.data!.provenance.isNotEmpty;
    return _check(
      id: 'normalization-conversion',
      algorithmIds: const ['normalization', 'pda-to-cfg'],
      passed: passed,
      message:
          normalization.error ?? conversion?.error ?? normalizedOutcome.name,
    );
  }

  PdaCertificationCheck _simplification(PdaHardEdgeFixture fixture) {
    final result = PDASimplifier.simplify(
      fixture.pda,
      acceptanceMode: fixture.mode,
    );
    final simplifiedOutcome = result.isSuccess
        ? _simulationOutcome(
            PDASimulator.simulateNPDA(
              result.data!.simplifiedPda,
              fixture.input,
              mode: fixture.mode,
            ),
          )
        : VerificationOutcomeCode.modelError;
    return _check(
      id: 'simplification',
      algorithmIds: const ['simplification'],
      passed: result.isSuccess && simplifiedOutcome == fixture.expectedOutcome,
      message: result.error ?? simplifiedOutcome.name,
    );
  }

  PdaCertificationCheck _languageEmptiness(PdaHardEdgeFixture fixture) {
    final result = PDALanguageEmptinessAnalyzer.analyze(
      fixture.pda,
      acceptanceMode: fixture.mode,
    );
    final passed = result is PDALanguageEmptinessProof &&
        !result.isEmpty &&
        result.witnessTrace?.accepted == true;
    return _check(
      id: 'language-emptiness',
      algorithmIds: const ['language-emptiness'],
      passed: passed,
      message: result.runtimeType.toString(),
    );
  }

  PdaCertificationCheck _cfgConversions(PdaHardEdgeFixture fixture) {
    final llGrammar = _fixtureGrammar(fixture, 'llGrammar');
    final lrGrammar = _fixtureGrammar(fixture, 'lrGrammar');
    final facade = GrammarToPDAConverter.convert(llGrammar);
    final canConvert = GrammarToPDAConverter.canConvertToPDA(llGrammar);
    final analysis = GrammarToPDAConverter.analyzeConversion(llGrammar);
    final general = GrammarToPDAConverter.convertGrammarToPDA(llGrammar);
    final standard =
        GrammarToPDAConverter.convertGrammarToPDAStandard(llGrammar);
    final greibach = GrammarToPDAConverter.convertGrammarToPDAGreibach(
      _fixtureGrammar(fixture, 'greibachGrammar'),
    );
    final legacyCan = GrammarToPDAConverter.canConvertGrammarToPDA(llGrammar);
    final legacyAnalysis =
        GrammarToPDAConverter.analyzeGrammarToPDAConversion(llGrammar);
    final ll = CfgToPdaConverter.buildLl(llGrammar, sourceRevision: 1);
    final lr = CfgToPdaConverter.buildLr(lrGrammar, sourceRevision: 1);
    final llDiff = ll.isCompleted
        ? CfgToPdaDifferentialChecker.check(
            llGrammar,
            ll,
            ['', 'identifier', 'identifierplusidentifier', 'plus'],
          )
        : null;
    final lrDiff = lr.isCompleted
        ? CfgToPdaDifferentialChecker.check(
            lrGrammar,
            lr,
            ['', 'dd', 'cddd', 'c'],
          )
        : null;
    final passed = facade.isSuccess &&
        canConvert &&
        analysis.isSuccess &&
        analysis.data!.canConvert &&
        analysis.data!.productionCount == llGrammar.productions.length &&
        general.isSuccess &&
        standard.isSuccess &&
        greibach.isSuccess &&
        legacyCan.isSuccess &&
        legacyCan.data == true &&
        legacyAnalysis.isSuccess &&
        legacyAnalysis.data?['canConvert'] == true &&
        ll.isCompleted &&
        lr.isCompleted &&
        ll.transitionProvenance.isNotEmpty &&
        lr.transitionProvenance.isNotEmpty &&
        llDiff?.hasMismatch == false &&
        lrDiff?.hasMismatch == false;
    return _check(
      id: 'cfg-conversions',
      algorithmIds: const [
        'cfg-to-pda-general-standard-greibach',
        'cfg-to-pda-ll-lr',
        'cfg-pda-differential',
      ],
      passed: passed,
      message: 'facade=${facade.isSuccess}, can=$canConvert, '
          'analysis=${analysis.isSuccess}, general=${general.isSuccess}, '
          'standard=${standard.isSuccess}, '
          'greibach=${greibach.isSuccess}, ll=${ll.outcome.name}, '
          'lr=${lr.outcome.name}, legacyCan=${legacyCan.isSuccess}, '
          'legacyAnalysis=${legacyAnalysis.isSuccess}',
    );
  }

  PdaCertificationCheck _serialization(PdaHardEdgeFixture fixture) {
    final decoded = PdaHardEdgeFixture.fromJson(
      jsonDecode(canonicalJsonEncode(fixture.toJson())),
    );
    final left = const PdaExhaustiveExplorer().explore(
      pda: fixture.pda,
      input: fixture.input,
      mode: fixture.mode,
    );
    final right = const PdaExhaustiveExplorer().explore(
      pda: decoded.pda,
      input: decoded.input,
      mode: decoded.mode,
    );
    final atomicPushes = decoded.pda.pdaTransitions
        .expand((transition) => transition.pushSymbols)
        .where((symbol) => symbol == 'stack-token')
        .length;
    final source = InteroperableDocument<Object>(
      document: fixture.pda,
      systemKey: DefaultFormalSystemIds.pda,
      schema: PdaJsonDocumentCodec.schema,
      extensions: DocumentExtensionBag(),
    );
    final jsonEncoded = PdaJsonDocumentCodec().encode(source);
    final xmlEncoded = const PdaJflapDocumentCodec().encode(source);
    final jsonDecoded = jsonEncoded is CodecSuccess<EncodedDocument>
        ? PdaJsonDocumentCodec().decode(
            DocumentPayload(
              bytes: jsonEncoded.value.bytes,
              filename: 'hard-edge-pda.json',
            ),
          )
        : null;
    final xmlDecoded = xmlEncoded is CodecSuccess<EncodedDocument>
        ? const PdaJflapDocumentCodec().decode(
            DocumentPayload(
              bytes: xmlEncoded.value.bytes,
              filename: 'hard-edge-pda.jff',
            ),
          )
        : null;
    final codecPdas = [jsonDecoded, xmlDecoded]
        .whereType<CodecSuccess<InteroperableDocument<Object>>>()
        .map((outcome) => outcome.value.document)
        .whereType<PDA>()
        .toList();
    final codecsPreserveOutcome = codecPdas.length == 2 &&
        codecPdas.every(
          (pda) =>
              _simulationOutcome(
                PDASimulator.simulateNPDA(
                  pda,
                  fixture.input,
                  mode: fixture.mode,
                ),
              ) ==
              fixture.expectedOutcome,
        );
    return _check(
      id: 'serialization',
      algorithmIds: const ['model-json-round-trip', 'document-codecs'],
      passed: canonicalJsonEncode(fixture.toJson()) ==
              canonicalJsonEncode(decoded.toJson()) &&
          left.outcome == right.outcome &&
          codecsPreserveOutcome &&
          (fixture.pda.stackAlphabet.contains('stack-token')
              ? atomicPushes > 0
              : true),
      message: 'before=${left.outcome.name}, after=${right.outcome.name}, '
          'codecRoundTrips=${codecPdas.length}',
    );
  }

  Future<PdaCertificationCheck> _resourceOutcomes(
    PdaHardEdgeFixture fixture,
  ) async {
    final pda = fixture;
    final branching = fixture;
    final maxConfigurations = _fixtureInt(fixture, 'maxConfigurations');
    final maxDepth = _fixtureInt(fixture, 'maxDepth');
    final maxMemoryBytes = _fixtureInt(fixture, 'maxMemoryBytes');
    final timeoutBudget = Duration(
      microseconds: _fixtureInt(fixture, 'timeoutMicroseconds'),
    );
    const explorer = PdaExhaustiveExplorer();
    final configured = explorer.explore(
      pda: pda.pda,
      input: pda.input,
      mode: pda.mode,
      budget: ResourceBudget(maxConfigurations: maxConfigurations),
    );
    final bounded = explorer.explore(
      pda: branching.pda,
      input: branching.input,
      mode: branching.mode,
      budget: ResourceBudget(maxSteps: maxDepth),
    );
    final timeout = explorer.explore(
      pda: pda.pda,
      input: pda.input,
      mode: pda.mode,
      budget: ResourceBudget(timeout: timeoutBudget),
      clock: const _FixedElapsedClock(Duration(microseconds: 1)),
    );
    final memory = explorer.explore(
      pda: branching.pda,
      input: branching.input,
      mode: branching.mode,
      budget: ResourceBudget(maxMemoryBytes: maxMemoryBytes),
    );
    final cancelledToken = _AlwaysCancelled();
    final cancelled = explorer.explore(
      pda: pda.pda,
      input: pda.input,
      mode: pda.mode,
      cancellation: cancelledToken,
    );
    final stale = explorer.explore(
      pda: pda.pda,
      input: pda.input,
      mode: pda.mode,
      freshness: const _AlwaysStale(),
    );
    final productionConfigurations = PDASimulator.simulateNPDA(
      branching.pda,
      branching.input,
      mode: branching.mode,
      maxConfigurations: maxConfigurations,
    );
    final productionDepth = PDASimulator.simulateNPDA(
      branching.pda,
      branching.input,
      mode: branching.mode,
      maxDepth: maxDepth,
    );
    final productionTimeout = PDASimulator.simulateNPDA(
      branching.pda,
      branching.input,
      mode: branching.mode,
      timeout: timeoutBudget,
    );
    final productionMemory = PDASimulator.simulateNPDA(
      branching.pda,
      branching.input,
      mode: branching.mode,
      maxMemoryBytes: maxMemoryBytes,
    );
    final productionStale = PDASimulator.simulateNPDA(
      branching.pda,
      branching.input,
      mode: branching.mode,
      isStale: () => true,
    );
    var productionCancelled = false;
    try {
      await PDASimulator.simulateCooperative(
        branching.pda,
        branching.input,
        mode: branching.mode,
        configurationsPerBatch: 1,
        isCancelled: () => true,
      );
    } on SimulationCancelledException {
      productionCancelled = true;
    }
    return _check(
      id: 'resource-outcomes',
      algorithmIds: const [
        'configuration-search',
        'simulation-sync',
        'simulation-cooperative',
      ],
      passed: bounded.outcome == VerificationOutcomeCode.boundedUnknown &&
          configured.outcome == VerificationOutcomeCode.configurationLimit &&
          timeout.outcome == VerificationOutcomeCode.timeout &&
          memory.limit?.kind == ResourceLimitKind.memoryBytes &&
          cancelled.outcome == VerificationOutcomeCode.cancelled &&
          stale.outcome == VerificationOutcomeCode.staleRequest &&
          productionConfigurations.data?.outcome ==
              PDASimulationOutcome.configurationLimit &&
          productionDepth.data?.outcome == PDASimulationOutcome.depthLimit &&
          productionTimeout.data?.outcome == PDASimulationOutcome.timeout &&
          productionMemory.data?.outcome == PDASimulationOutcome.memoryLimit &&
          productionStale.data?.outcome == PDASimulationOutcome.staleRequest &&
          productionCancelled,
      message: '${bounded.outcome.name}, ${configured.outcome.name}, '
          '${timeout.outcome.name}, memoryBytes, ${cancelled.outcome.name}, '
          '${stale.outcome.name}; production='
          '${productionConfigurations.data?.outcome.name},'
          '${productionDepth.data?.outcome.name},'
          '${productionTimeout.data?.outcome.name},'
          '${productionMemory.data?.outcome.name},'
          '${productionStale.data?.outcome.name},cancelled=$productionCancelled',
    );
  }

  PdaCertificationCheck _mutationChecks(PdaHardEdgeFixture fixture) {
    final killed = <PdaOracleMutation>[];
    final survivors = <PdaOracleMutation>[];
    for (final mutation in PdaOracleMutation.values.skip(1)) {
      final mutationFixture = _fixtureMutation(fixture, mutation);
      final evidence = evaluatePdaProductionMutation(
        mutationFixture,
        mutation,
      );
      if (evidence.killed) {
        killed.add(mutation);
      } else {
        survivors.add(mutation);
      }
    }
    return _check(
      id: 'mutation-checks',
      algorithmIds: const ['configuration-search'],
      passed: killed.length >= pdaMutationKillThreshold && survivors.isEmpty,
      message: 'threshold=$pdaMutationKillThreshold, '
          'killed=${killed.map((item) => item.name).join(',')}, '
          'survivors=${survivors.map((item) => item.name).join(',')}',
    );
  }

  PdaCertificationCheck _validationDeterminismAnalysis(
    PdaHardEdgeFixture fixture,
  ) {
    final analysis = PDASimulator.analyzePDA(
      fixture.pda,
      maxInputLength: fixture.input.length,
    );
    final accepted = PDASimulator.findAcceptedStrings(
      fixture.pda,
      6,
      maxResults: 256,
    );
    final rejected = PDASimulator.findRejectedStrings(
      fixture.pda,
      2,
      maxResults: 16,
    );
    final deterministic = PDANormalizer.normalize(
      fixture.pda,
      sourceMode: fixture.mode,
      targetForm: PDANormalForm.finalStateAndEmptyStackAndSinglePop,
    );
    final first = fixture.pda.pdaTransitions.toList()
      ..sort((left, right) => left.id.compareTo(right.id));
    final nondeterministicPda = fixture.pda.copyWith(
      transitions: <Transition>{
        ...fixture.pda.transitions,
        first.first.copyWith(id: 'nondeterministic-copy'),
      },
    );
    final nondeterministic = PDANormalizer.normalize(
      nondeterministicPda,
      sourceMode: fixture.mode,
      targetForm: PDANormalForm.finalStateAndEmptyStackAndSinglePop,
    );
    final analyzed = analysis.data;
    final passed = fixture.pda.validate().isEmpty &&
        fixture.pda.pdaTransitions
            .every((transition) => transition.validate().isEmpty) &&
        analysis.isSuccess &&
        analyzed!.stateAnalysis.totalStates == fixture.pda.states.length &&
        analyzed.transitionAnalysis.pdaTransitions ==
            fixture.pda.pdaTransitions.length &&
        analyzed.reachabilityAnalysis.unreachableStates.isEmpty &&
        analyzed.stackAnalysis.pushOperations.isNotEmpty &&
        deterministic.isSuccess &&
        deterministic.data!.sourceWasDeterministic &&
        nondeterministic.isSuccess &&
        !nondeterministic.data!.sourceWasDeterministic &&
        accepted.isSuccess &&
        accepted.data!.contains(fixture.input) &&
        rejected.isSuccess &&
        rejected.data!.contains('');
    return _check(
      id: 'validation-determinism-analysis',
      algorithmIds: const [
        'transition-validation',
        'pda-analysis',
        'bounded-string-generation',
        'normalization',
      ],
      passed: passed,
      message: 'valid=${fixture.pda.validate().isEmpty}, '
          'analysis=${analysis.isSuccess}, '
          'deterministic=${deterministic.data?.sourceWasDeterministic}, '
          'nondeterministic=${nondeterministic.data?.sourceWasDeterministic}, '
          'acceptedGenerated=${accepted.data?.contains(fixture.input)}',
    );
  }

  PdaCertificationCheck _traceReconstruction(PdaHardEdgeFixture fixture) {
    final simulation = PDASimulator.simulateNPDA(
      fixture.pda,
      fixture.input,
      mode: fixture.mode,
      stepByStep: true,
    );
    final oracle = const PdaExhaustiveExplorer().explore(
      pda: fixture.pda,
      input: fixture.input,
      mode: fixture.mode,
    );
    final passed = simulation.isSuccess &&
        simulation.data!.accepted &&
        _traceMatchesOracle(
          fixture.pda,
          simulation.data!,
          oracle,
          fixture.input,
        );
    return _check(
      id: 'trace-reconstruction',
      algorithmIds: const [
        'trace-stack-reconstruction',
        'simulation-sync',
        'configuration-search',
      ],
      passed: passed,
      message: 'steps=${simulation.data?.steps.length}, '
          'witness=${oracle.witness.length}, '
          'outcome=${simulation.data?.accepted}',
    );
  }

  PdaCertificationCheck _invalidModel(PdaHardEdgeFixture fixture) {
    final invalid = fixture.pda;
    final duplicateDocument =
        fixture.propertyPayload['duplicateTransitionDocument'];
    final danglingDocument =
        fixture.propertyPayload['danglingEndpointDocument'];
    final staleEndpointCopies = fixture.propertyPayload['staleEndpointCopies'];
    if (duplicateDocument is! Map ||
        danglingDocument is! Map ||
        staleEndpointCopies is! Map) {
      throw FormatException(
        'PDA fixture ${fixture.id} is missing invalid document payloads.',
      );
    }
    final oracle = const PdaExhaustiveExplorer().explore(
      pda: invalid,
      input: '',
    );
    final simulation = PDASimulator.simulateNPDA(invalid, '');
    final analysis = PDASimulator.analyzePDA(invalid);
    final normalization = PDANormalizer.normalize(
      invalid,
      sourceMode: invalid.acceptanceMode,
      targetForm: PDANormalForm.finalStateAndEmptyStackAndSinglePop,
    );
    final duplicateDecode = PdaJsonDocumentCodec().decode(
      DocumentPayload(
        bytes: utf8.encode(canonicalJsonEncode(duplicateDocument)),
        filename: 'duplicate-transition-id.json',
      ),
    );
    final danglingDecode = PdaJsonDocumentCodec().decode(
      DocumentPayload(
        bytes: utf8.encode(canonicalJsonEncode(danglingDocument)),
        filename: 'dangling-transition-endpoint.json',
      ),
    );
    final staleEndpointPda = _staleEndpointPda(
      Map<String, Object?>.from(staleEndpointCopies),
    );
    final staleTransition = staleEndpointPda.pdaTransitions.single;
    final canonicalFrom = staleEndpointPda.states.singleWhere(
      (state) => state.id == staleTransition.fromState.id,
    );
    final canonicalTo = staleEndpointPda.states.singleWhere(
      (state) => state.id == staleTransition.toState.id,
    );
    final staleCopiesAreDistinct =
        !identical(canonicalFrom, staleTransition.fromState) &&
            !identical(canonicalTo, staleTransition.toState);
    final staleOracle = const PdaExhaustiveExplorer().explore(
      pda: staleEndpointPda,
      input: 'a',
      mode: PDAAcceptanceMode.finalState,
    );
    final staleSimulation = PDASimulator.simulateNPDA(
      staleEndpointPda,
      'a',
      mode: PDAAcceptanceMode.finalState,
    );
    final canonicalized = PDA.fromJson(staleEndpointPda.toJson());
    final canonicalizedTransition = canonicalized.pdaTransitions.single;
    final staleEndpointCanonicalized = identical(
          canonicalizedTransition.fromState,
          canonicalized.states.singleWhere(
            (state) => state.id == canonicalizedTransition.fromState.id,
          ),
        ) &&
        identical(
          canonicalizedTransition.toState,
          canonicalized.states.singleWhere(
            (state) => state.id == canonicalizedTransition.toState.id,
          ),
        );
    final staleEndpointAccepted = staleCopiesAreDistinct &&
        staleOracle.outcome == VerificationOutcomeCode.accepted &&
        staleSimulation.isSuccess &&
        staleSimulation.data!.accepted;
    return _check(
      id: 'invalid-model',
      algorithmIds: const [
        'transition-validation',
        'pda-analysis',
        'simulation-sync',
        'configuration-search',
      ],
      passed: invalid.validate().isNotEmpty &&
          oracle.outcome == VerificationOutcomeCode.invalidInput &&
          simulation.isFailure &&
          analysis.isFailure &&
          normalization.isFailure &&
          duplicateDecode is CodecMalformed &&
          danglingDecode is CodecMalformed &&
          staleEndpointAccepted &&
          staleEndpointCanonicalized,
      message: 'modelErrors=${invalid.validate().length}, '
          'oracle=${oracle.outcome.name}, simulationFailure=${simulation.isFailure}, '
          'analysisFailure=${analysis.isFailure}, '
          'normalizationFailure=${normalization.isFailure}, '
          'duplicateRejected=${duplicateDecode is CodecMalformed}, '
          'danglingRejected=${danglingDecode is CodecMalformed}, '
          'staleEndpointAccepted=$staleEndpointAccepted, '
          'staleEndpointCanonicalized=$staleEndpointCanonicalized',
    );
  }

  PdaCertificationCheck _metamorphicRenamingOrder(
    PdaHardEdgeFixture fixture,
  ) {
    final renamed = _renamedFixture(fixture);
    final reordered = fixture.copyWith(
      pda: fixture.pda.copyWith(
        states: fixture.pda.states.toList().reversed.toSet(),
        transitions: fixture.pda.transitions.toList().reversed.toSet(),
      ),
    );
    const explorer = PdaExhaustiveExplorer();
    final source = explorer.explore(
      pda: fixture.pda,
      input: fixture.input,
      mode: fixture.mode,
    );
    final renamedOutcome = explorer.explore(
      pda: renamed.pda,
      input: renamed.input,
      mode: renamed.mode,
    );
    final reorderedOutcome = explorer.explore(
      pda: reordered.pda,
      input: reordered.input,
      mode: reordered.mode,
    );
    final renamedSimulation = _simulationOutcome(
      PDASimulator.simulateNPDA(
        renamed.pda,
        renamed.input,
        mode: renamed.mode,
      ),
    );
    final reorderedSimulation = _simulationOutcome(
      PDASimulator.simulateNPDA(
        reordered.pda,
        reordered.input,
        mode: reordered.mode,
      ),
    );
    return _check(
      id: 'metamorphic-renaming-order',
      algorithmIds: const ['metamorphic-invariance'],
      passed: source.outcome == renamedOutcome.outcome &&
          source.outcome == reorderedOutcome.outcome &&
          source.outcome == renamedSimulation &&
          source.outcome == reorderedSimulation,
      message: 'source=${source.outcome.name}, '
          'renamed=${renamedOutcome.outcome.name}, '
          'reordered=${reorderedOutcome.outcome.name}',
    );
  }

  PdaCertificationCheck _compoundConversions(PdaHardEdgeFixture fixture) {
    final sourceGrammar = _fixtureGrammar(fixture, 'sourceGrammar');
    final cfgPda = GrammarToPDAConverter.convertGrammarToPDA(sourceGrammar);
    final cfgPdaNormalized = cfgPda.isSuccess
        ? PDANormalizer.normalize(
            cfgPda.data!,
            sourceMode: cfgPda.data!.acceptanceMode,
            targetForm: PDANormalForm.finalStateAndEmptyStackAndSinglePop,
          )
        : null;
    final cfgPdaCfg = cfgPdaNormalized?.isSuccess == true
        ? PDAtoCFGConverter.convert(
            cfgPdaNormalized!.data!.normalizedPda,
            maxGeneratedProductions: 50000,
          )
        : null;
    final cfgRoundTrip = cfgPdaCfg?.isSuccess == true
        ? GrammarToPDAConverter.convertGrammarToPDA(
            cfgPdaCfg!.data!.grammar,
          )
        : null;
    final cfgComparison = cfgPda.isSuccess && cfgRoundTrip?.isSuccess == true
        ? _boundedPdaComparison(
            cfgPda.data!,
            cfgRoundTrip!.data!,
            const {'a', 'b'},
            2,
          )
        : const PdaBoundedComparison(
            outcome: PdaBoundedComparisonOutcome.boundedUnknown,
            wordsChecked: 0,
          );

    final sourcePda = fixture.pda;
    final pdaCfg = PDAtoCFGConverter.convert(sourcePda);
    final limitedPdaCfg = PDAtoCFGConverter.convert(
      sourcePda,
      maxGeneratedProductions: 1,
    );
    final cancelledPdaCfg = PDAtoCFGConverter.convert(
      sourcePda,
      isCancelled: () => true,
    );
    final pdaCfgPda = pdaCfg.isSuccess
        ? GrammarToPDAConverter.convertGrammarToPDA(pdaCfg.data!.grammar)
        : null;
    final pdaComparison = pdaCfgPda?.isSuccess == true
        ? _boundedPdaComparison(
            sourcePda,
            pdaCfgPda!.data!,
            const {'a'},
            2,
          )
        : const PdaBoundedComparison(
            outcome: PdaBoundedComparisonOutcome.boundedUnknown,
            wordsChecked: 0,
          );
    final unknown = _boundedPdaComparison(
      sourcePda,
      sourcePda,
      const {'a'},
      1,
      budget: ResourceBudget(maxConfigurations: 0),
    );
    return _check(
      id: 'compound-conversions',
      algorithmIds: const [
        'compound-cfg-pda-cfg',
        'compound-pda-cfg-pda',
      ],
      passed: cfgPdaCfg?.isSuccess == true &&
          pdaCfg.isSuccess &&
          limitedPdaCfg.isFailure &&
          limitedPdaCfg.error!.startsWith(
            PDAtoCFGConverter.productionLimitErrorPrefix,
          ) &&
          cancelledPdaCfg.isFailure &&
          cancelledPdaCfg.error == PDAtoCFGConverter.cancellationError &&
          cfgComparison.outcome == PdaBoundedComparisonOutcome.match &&
          pdaComparison.outcome == PdaBoundedComparisonOutcome.match &&
          unknown.outcome == PdaBoundedComparisonOutcome.boundedUnknown,
      message: 'cfg-pda-cfg=${cfgComparison.outcome.name}, '
          'pda-cfg-pda=${pdaComparison.outcome.name}, '
          'limited=${unknown.outcome.name}, '
          'pdaCfgLimit=${limitedPdaCfg.error}, '
          'pdaCfgCancellation=${cancelledPdaCfg.error}',
    );
  }

  PdaCertificationCheck _boundedLanguageEvidence(
    PdaHardEdgeFixture fixture,
  ) {
    final simplification = PDASimplifier.simplify(
      fixture.pda,
      acceptanceMode: fixture.mode,
      options: PDASimplificationOptions(
        boundedCheck: PDABoundedLanguageCheck(
          alphabet: fixture.pda.alphabet,
          maxLength: 3,
        ),
      ),
    );
    final llGrammar = _fixtureGrammar(fixture, 'llGrammar');
    final ll = CfgToPdaConverter.buildLl(llGrammar, sourceRevision: 1);
    final differential = CfgToPdaDifferentialChecker.check(
      llGrammar,
      ll,
      const ['identifier'],
      maxConfigurations: 0,
    );
    final evidence = simplification.data?.sampledEvidence;
    final unknown = differential.samples.single;
    return _check(
      id: 'bounded-language-evidence',
      algorithmIds: const [
        'bounded-language-comparison',
        'cfg-pda-differential',
        'cfg-to-pda-ll-lr',
        'simplification',
      ],
      passed: simplification.isSuccess &&
          evidence != null &&
          evidence.wordsChecked > 0 &&
          !evidence.isProof &&
          unknown.outcome == CfgToPdaSampleOutcome.boundedUnknown &&
          !differential.hasMismatch,
      message: 'words=${evidence?.wordsChecked}, proof=${evidence?.isProof}, '
          'limitedDifferential=${unknown.outcome.name}',
    );
  }

  PdaCertificationCheck _unicodePrefixStackSymbols(
    PdaHardEdgeFixture fixture,
  ) {
    final oracle = const PdaExhaustiveExplorer().explore(
      pda: fixture.pda,
      input: fixture.input,
      mode: fixture.mode,
    );
    final simulation = PDASimulator.simulateNPDA(
      fixture.pda,
      fixture.input,
      mode: fixture.mode,
      stepByStep: true,
    );
    final pushed = fixture.pda.pdaTransitions
        .singleWhere((transition) => transition.id == 'push-prefix-tokens')
        .pushSymbols;
    return _check(
      id: 'unicode-prefix-stack-symbols',
      algorithmIds: const [
        'trace-stack-reconstruction',
        'simulation-sync',
        'configuration-search',
      ],
      passed: pushed.length == 4 &&
          pushed[0] == 'α' &&
          pushed[1].startsWith(pushed[0]) &&
          pushed[3].startsWith(pushed[2]) &&
          oracle.outcome == VerificationOutcomeCode.accepted &&
          simulation.isSuccess &&
          simulation.data!.accepted &&
          _traceMatchesOracle(
            fixture.pda,
            simulation.data!,
            oracle,
            fixture.input,
          ),
      message: 'tokens=${jsonEncode(pushed)}, '
          'oracle=${oracle.outcome.name}, simulation=${simulation.data?.accepted}',
    );
  }

  PdaCertificationCheck _shortestBfsWitness(PdaHardEdgeFixture fixture) {
    final oracle = const PdaExhaustiveExplorer().explore(
      pda: fixture.pda,
      input: fixture.input,
      mode: fixture.mode,
    );
    final simulation = PDASimulator.simulateNPDA(
      fixture.pda,
      fixture.input,
      mode: fixture.mode,
      stepByStep: true,
    );
    final transitionIds = simulation.data?.steps
            .expand(
              (step) => step.explanation?.highlights ?? const [],
            )
            .where((target) => target.type == HighlightTargetType.transition)
            .map((target) => target.id)
            .toList() ??
        const <String>[];
    return _check(
      id: 'shortest-bfs-witness',
      algorithmIds: const ['configuration-search', 'simulation-sync'],
      passed: oracle.outcome == VerificationOutcomeCode.accepted &&
          oracle.witness.length == 1 &&
          oracle.witness.single.transitionId == 'z-short' &&
          simulation.isSuccess &&
          simulation.data!.accepted &&
          simulation.data!.steps.length == 3 &&
          transitionIds.contains('z-short') &&
          !transitionIds.contains('a-long-first'),
      message: 'oracleTransitions='
          '${oracle.witness.map((item) => item.transitionId).join(',')}, '
          'productionTransitions=${transitionIds.join(',')}',
    );
  }
}

enum PdaBoundedComparisonOutcome { match, mismatch, boundedUnknown }

final class PdaBoundedComparison {
  const PdaBoundedComparison({
    required this.outcome,
    required this.wordsChecked,
    this.counterexample,
  });

  final PdaBoundedComparisonOutcome outcome;
  final int wordsChecked;
  final String? counterexample;
}

PdaBoundedComparison _boundedPdaComparison(
  PDA left,
  PDA right,
  Set<String> alphabet,
  int maxLength, {
  ResourceBudget? budget,
}) {
  final symbols = alphabet.toList()..sort();
  final words = <String>[''];
  var frontier = <String>[''];
  for (var length = 1; length <= maxLength; length++) {
    final next = <String>[];
    for (final prefix in frontier) {
      for (final symbol in symbols) {
        next.add('$prefix$symbol');
      }
    }
    words.addAll(next);
    frontier = next;
  }
  const explorer = PdaExhaustiveExplorer();
  var checked = 0;
  for (final word in words) {
    final leftResult = explorer.explore(
      pda: left,
      input: word,
      mode: left.acceptanceMode,
      budget: budget,
    );
    final rightResult = explorer.explore(
      pda: right,
      input: word,
      mode: right.acceptanceMode,
      budget: budget,
    );
    if (!leftResult.isDefinitive || !rightResult.isDefinitive) {
      return PdaBoundedComparison(
        outcome: PdaBoundedComparisonOutcome.boundedUnknown,
        wordsChecked: checked,
        counterexample: word,
      );
    }
    checked++;
    if (leftResult.accepted != rightResult.accepted) {
      return PdaBoundedComparison(
        outcome: PdaBoundedComparisonOutcome.mismatch,
        wordsChecked: checked,
        counterexample: word,
      );
    }
  }
  return PdaBoundedComparison(
    outcome: PdaBoundedComparisonOutcome.match,
    wordsChecked: checked,
  );
}

bool _traceMatchesOracle(
  PDA pda,
  PDASimulationResult simulation,
  PdaOracleResult oracle,
  String input,
) {
  if (!simulation.accepted || !oracle.accepted) return false;
  if (simulation.steps.length != oracle.witness.length + 2) return false;
  final transitionsById = {
    for (final transition in pda.pdaTransitions) transition.id: transition,
  };
  final reconstructedStack = <String>[pda.initialStackSymbol];
  final transitionSteps = simulation.steps.skip(1).take(oracle.witness.length);
  for (final pair in transitionSteps.indexed) {
    final index = pair.$1;
    final step = pair.$2;
    final witness = oracle.witness[index];
    final transitionHighlights = step.explanation?.highlights
            .where((target) => target.type == HighlightTargetType.transition)
            .map((target) => target.id)
            .toList() ??
        const <String>[];
    if (!transitionHighlights.contains(witness.transitionId)) return false;
    final transition = transitionsById[witness.transitionId];
    if (transition == null) return false;
    final lambdaPop = transition.isLambdaPop || transition.popSymbol.isEmpty;
    if (!lambdaPop) {
      if (reconstructedStack.isEmpty ||
          reconstructedStack.last != transition.popSymbol) {
        return false;
      }
      reconstructedStack.removeLast();
    }
    final lambdaPush =
        transition.isLambdaPush || transition.pushSymbols.isEmpty;
    if (!lambdaPush) reconstructedStack.addAll(transition.pushSymbols.reversed);
    if (!_sameStrings(reconstructedStack, witness.after.stack) ||
        !_sameStrings(step.stackTokens ?? const [], reconstructedStack) ||
        step.currentState != witness.after.stateId ||
        step.remainingInput != input.substring(witness.after.inputOffset)) {
      return false;
    }
  }
  final finalStep = simulation.steps.last;
  final finalConfiguration = oracle.witness.last.after;
  return finalStep.currentState == finalConfiguration.stateId &&
      finalStep.remainingInput.isEmpty &&
      _sameStrings(
        finalStep.stackTokens ?? const [],
        finalConfiguration.stack,
      ) &&
      finalStep.description != null &&
      finalStep.explanation != null;
}

bool _sameStrings(List<String> left, List<String> right) {
  if (left.length != right.length) return false;
  for (var index = 0; index < left.length; index++) {
    if (left[index] != right[index]) return false;
  }
  return true;
}

PdaHardEdgeFixture _renamedFixture(PdaHardEdgeFixture fixture) {
  final sourceStates = fixture.pda.states.toList()
    ..sort((left, right) => left.id.compareTo(right.id));
  final statesById = <String, State>{};
  for (var index = 0; index < sourceStates.length; index++) {
    final source = sourceStates[index];
    statesById[source.id] = source.copyWith(
      id: 'renamed-state-$index-✓',
      label: 'renamed $index',
    );
  }
  final inputSymbols = fixture.pda.alphabet.toList()..sort();
  final inputRename = <String, String>{
    for (var index = 0; index < inputSymbols.length; index++)
      inputSymbols[index]: 'input-$index-λ',
  };
  final stackSymbols = fixture.pda.stackAlphabet.toList()..sort();
  final stackRename = <String, String>{
    for (var index = 0; index < stackSymbols.length; index++)
      stackSymbols[index]: 'stack-$index-σ',
  };
  final transitions = fixture.pda.pdaTransitions.toList()
    ..sort((left, right) => right.id.compareTo(left.id));
  final renamedTransitions = <Transition>{};
  for (var index = 0; index < transitions.length; index++) {
    final source = transitions[index];
    final renamedPush = source.pushSymbols
        .map((symbol) => stackRename[symbol]!)
        .toList(growable: false);
    renamedTransitions.add(
      source.copyWith(
        id: 'renamed-transition-$index',
        fromState: statesById[source.fromState.id],
        toState: statesById[source.toState.id],
        inputSymbol:
            source.isLambdaInput ? '' : inputRename[source.inputSymbol],
        popSymbol: source.isLambdaPop ? '' : stackRename[source.popSymbol],
        pushSymbols: renamedPush,
        pushSymbol: renamedPush.join(),
      ),
    );
  }
  final renamedPda = PDA(
    id: '${fixture.pda.id}-renamed',
    name: '${fixture.pda.name} renamed',
    states: statesById.values.toList().reversed.toSet(),
    transitions: renamedTransitions,
    alphabet: inputRename.values.toSet(),
    initialState: statesById[fixture.pda.initialState!.id],
    acceptingStates: fixture.pda.acceptingStates
        .map((state) => statesById[state.id]!)
        .toSet(),
    created: fixture.pda.created,
    modified: fixture.pda.modified,
    bounds: fixture.pda.bounds,
    zoomLevel: fixture.pda.zoomLevel,
    panOffset: fixture.pda.panOffset,
    stackAlphabet: stackRename.values.toSet(),
    initialStackSymbol: stackRename[fixture.pda.initialStackSymbol]!,
    acceptanceMode: fixture.mode,
  );
  var renamedInput = fixture.input;
  for (final entry in inputRename.entries) {
    renamedInput = renamedInput.replaceAll(entry.key, entry.value);
  }
  return fixture.copyWith(pda: renamedPda, input: renamedInput);
}

PdaHardEdgeFixture pdaUnicodePrefixFixture() {
  final states = [
    _state('u0', initial: true, x: 0),
    _state('u1', x: 80),
    _state('u2', x: 160),
    _state('u3', x: 240),
    _state('u4', x: 320),
    _state('u5', x: 400),
    _state('u6', accepting: true, x: 480),
  ];
  const tokens = ['α', 'αβ', '🧪', '🧪x'];
  final transitions = <PDATransition>{
    _transition(
      id: 'push-prefix-tokens',
      from: states[0],
      to: states[1],
      input: 'é',
      pop: '',
      push: tokens,
    ),
    _transition(
      id: 'pop-alpha',
      from: states[1],
      to: states[2],
      input: '',
      pop: 'α',
    ),
    _transition(
      id: 'pop-alpha-beta',
      from: states[2],
      to: states[3],
      input: '',
      pop: 'αβ',
    ),
    _transition(
      id: 'pop-test-tube',
      from: states[3],
      to: states[4],
      input: '',
      pop: '🧪',
    ),
    _transition(
      id: 'pop-test-tube-x',
      from: states[4],
      to: states[5],
      input: '',
      pop: '🧪x',
    ),
    _transition(
      id: 'pop-bottom',
      from: states[5],
      to: states[6],
      input: '',
      pop: 'bottom',
    ),
  };
  return PdaHardEdgeFixture(
    id: 'unicode-prefix-stack-symbols',
    seed: 337,
    property: 'unicode-prefix-stack-symbols',
    pda: _pda(
      id: 'unicode-prefix-stack-symbols',
      states: states.toSet(),
      transitions: transitions,
      initial: states.first,
      accepting: {states.last},
      alphabet: const {'é'},
      stackAlphabet: {'bottom', ...tokens},
      mode: PDAAcceptanceMode.both,
    ),
    input: 'é',
    mode: PDAAcceptanceMode.both,
    expectedOutcome: VerificationOutcomeCode.accepted,
  );
}

PDA _singlePopConversionPda() {
  final initial = _state('c0', initial: true, x: 0);
  final accepting = _state('c1', accepting: true, x: 120);
  return _pda(
    id: 'single-pop-conversion',
    states: {initial, accepting},
    transitions: {
      _transition(
        id: 'consume-a',
        from: initial,
        to: accepting,
        input: 'a',
        pop: 'bottom',
      ),
    },
    initial: initial,
    accepting: {accepting},
    alphabet: const {'a'},
    stackAlphabet: const {'bottom'},
    mode: PDAAcceptanceMode.both,
  );
}

PdaCertificationCheck _check({
  required String id,
  required List<String> algorithmIds,
  required bool passed,
  required String message,
}) =>
    PdaCertificationCheck(
      id: id,
      algorithmIds: algorithmIds,
      status: passed
          ? PdaCertificationStatus.passed
          : PdaCertificationStatus.failed,
      message: message,
    );

VerificationOutcomeCode _simulationOutcome(Object result) {
  final simulation = result as dynamic;
  if (simulation.isFailure as bool) {
    return VerificationOutcomeCode.invalidInput;
  }
  final data = simulation.data as PDASimulationResult;
  return switch (data.outcome) {
    PDASimulationOutcome.accepted => VerificationOutcomeCode.accepted,
    PDASimulationOutcome.rejected => VerificationOutcomeCode.rejected,
    PDASimulationOutcome.timeout => VerificationOutcomeCode.timeout,
    PDASimulationOutcome.configurationLimit ||
    PDASimulationOutcome.provenCycle =>
      VerificationOutcomeCode.configurationLimit,
    PDASimulationOutcome.depthLimit ||
    PDASimulationOutcome.memoryLimit =>
      VerificationOutcomeCode.boundedUnknown,
    PDASimulationOutcome.staleRequest => VerificationOutcomeCode.staleRequest,
  };
}

Map<String, Object?> _canonicalPdaJson(PDA pda) {
  final json = pda.toJson();
  (json['states'] as List).sort(
    (left, right) => (left as Map)['id'].compareTo((right as Map)['id']),
  );
  (json['transitions'] as List).sort(
    (left, right) => (left as Map)['id'].compareTo((right as Map)['id']),
  );
  (json['alphabet'] as List).sort();
  (json['stackAlphabet'] as List).sort();
  (json['acceptingStates'] as List).sort(
    (left, right) => (left as Map)['id'].compareTo((right as Map)['id']),
  );
  return json;
}

final class PdaProductionMutationEvidence {
  const PdaProductionMutationEvidence({
    required this.originalOracle,
    required this.canonicalProduction,
    required this.mutantProduction,
  });

  final VerificationOutcomeCode originalOracle;
  final VerificationOutcomeCode canonicalProduction;
  final VerificationOutcomeCode mutantProduction;

  bool get killed =>
      canonicalProduction == originalOracle &&
      mutantProduction != originalOracle;
}

PdaProductionMutationEvidence evaluatePdaProductionMutation(
  PdaHardEdgeFixture source,
  PdaOracleMutation mutation,
) {
  const explorer = PdaExhaustiveExplorer();
  final originalOracle = explorer
      .explore(pda: source.pda, input: source.input, mode: source.mode)
      .outcome;
  final canonicalProduction = _simulationOutcome(
    PDASimulator.simulateNPDA(
      source.pda,
      source.input,
      mode: source.mode,
    ),
  );
  final mutantProduction = _simulationOutcome(
    // The hard-edge campaign is the sole non-test caller of this certification
    // seam. Normal application entrypoints always use canonical semantics.
    // ignore: invalid_use_of_visible_for_testing_member
    PDASimulator.simulateNPDAForCertification(
      source.pda,
      source.input,
      mode: source.mode,
      semanticVariant: _productionSemanticVariant(mutation),
    ),
  );
  return PdaProductionMutationEvidence(
    originalOracle: originalOracle,
    canonicalProduction: canonicalProduction,
    mutantProduction: mutantProduction,
  );
}

PDASimulationSemanticVariant _productionSemanticVariant(
  PdaOracleMutation mutation,
) =>
    switch (mutation) {
      PdaOracleMutation.ignorePush => PDASimulationSemanticVariant.ignorePush,
      PdaOracleMutation.reversePushOrder =>
        PDASimulationSemanticVariant.reversePushOrder,
      PdaOracleMutation.omitStackFromConfiguration =>
        PDASimulationSemanticVariant.omitStackFromConfiguration,
      PdaOracleMutation.acceptBeforeInputConsumed =>
        PDASimulationSemanticVariant.acceptBeforeInputConsumed,
      PdaOracleMutation.none => throw ArgumentError.value(
          mutation,
          'mutation',
          'must name a non-control PDA mutation',
        ),
    };

PdaHardEdgeFixture pdaMutationFixture(PdaOracleMutation mutation) {
  final q0 = _state('q0', initial: true, x: 0);
  final q1 = _state('q1', x: 100);
  final q2 = _state('q2', accepting: true, x: 200);
  PdaHardEdgeFixture fixture(
    String id,
    PDA pda,
    String input,
    VerificationOutcomeCode expected,
  ) =>
      PdaHardEdgeFixture(
        id: id,
        seed: 337,
        property: 'mutation-kill',
        pda: pda,
        input: input,
        mode: PDAAcceptanceMode.finalState,
        expectedOutcome: expected,
      );

  final pushRequired = _pda(
    id: 'push-required',
    states: {q0, q1, q2},
    transitions: {
      _transition(
          id: 'push', from: q0, to: q1, input: 'a', pop: '', push: ['X']),
      _transition(id: 'pop', from: q1, to: q2, input: '', pop: 'X'),
    },
    initial: q0,
    accepting: {q2},
    alphabet: {'a'},
    stackAlphabet: {'bottom', 'X'},
  );
  final orderRequired = _pda(
    id: 'order-required',
    states: {q0, q1, q2},
    transitions: {
      _transition(
        id: 'push-word',
        from: q0,
        to: q1,
        input: 'a',
        pop: 'bottom',
        push: ['X', 'bottom'],
      ),
      _transition(id: 'pop-x', from: q1, to: q2, input: '', pop: 'X'),
    },
    initial: q0,
    accepting: {q2},
    alphabet: {'a'},
    stackAlphabet: {'bottom', 'X'},
  );
  final stackKey = _pda(
    id: 'stack-key',
    states: {q0, q1, q2},
    transitions: {
      _transition(id: 'a-dead', from: q0, to: q1, input: '', pop: ''),
      _transition(
          id: 'b-live', from: q0, to: q1, input: '', pop: '', push: ['X']),
      _transition(id: 'consume', from: q1, to: q2, input: 'a', pop: 'X'),
    },
    initial: q0,
    accepting: {q2},
    alphabet: {'a'},
    stackAlphabet: {'bottom', 'X'},
  );
  final consumeAll = _pda(
    id: 'consume-all',
    states: {q0},
    transitions: const {},
    initial: q0,
    accepting: {q0},
    alphabet: {'a'},
    stackAlphabet: {'bottom'},
  );
  final fixtures = {
    PdaOracleMutation.ignorePush: fixture(
      'ignore-push',
      pushRequired,
      'a',
      VerificationOutcomeCode.accepted,
    ),
    PdaOracleMutation.reversePushOrder: fixture(
      'reverse-push',
      orderRequired,
      'a',
      VerificationOutcomeCode.accepted,
    ),
    PdaOracleMutation.omitStackFromConfiguration: fixture(
      'stack-key',
      stackKey,
      'a',
      VerificationOutcomeCode.accepted,
    ),
    PdaOracleMutation.acceptBeforeInputConsumed: fixture(
      'consume-all',
      consumeAll,
      'a',
      VerificationOutcomeCode.rejected,
    ),
  };
  final selected = fixtures[mutation];
  if (selected == null) {
    throw ArgumentError.value(
      mutation,
      'mutation',
      'must name a non-control PDA mutation',
    );
  }
  return selected;
}

Grammar _llGrammar() => _grammar(
      id: 'll-source',
      terminals: {'identifier', 'plus'},
      nonterminals: {'S', 'Tail'},
      productions: {
        const Production(
          id: 'start',
          leftSide: ['S'],
          rightSide: ['identifier', 'Tail'],
        ),
        const Production(
          id: 'tail-more',
          leftSide: ['Tail'],
          rightSide: ['plus', 'identifier', 'Tail'],
          order: 1,
        ),
        const Production(
          id: 'tail-empty',
          leftSide: ['Tail'],
          rightSide: [],
          isLambda: true,
          order: 2,
        ),
      },
    );

Grammar _lrGrammar() => _grammar(
      id: 'lr-source',
      terminals: {'c', 'd'},
      nonterminals: {'S', 'C'},
      productions: {
        const Production(id: 's-cc', leftSide: ['S'], rightSide: ['C', 'C']),
        const Production(
          id: 'c-c',
          leftSide: ['C'],
          rightSide: ['c', 'C'],
          order: 1,
        ),
        const Production(
          id: 'c-d',
          leftSide: ['C'],
          rightSide: ['d'],
          order: 2,
        ),
      },
    );

Grammar _greibachGrammar() => _grammar(
      id: 'greibach-source',
      terminals: {'a', 'b'},
      nonterminals: {'S'},
      productions: {
        const Production(id: 'more', leftSide: ['S'], rightSide: ['a', 'S']),
        const Production(
          id: 'end',
          leftSide: ['S'],
          rightSide: ['b'],
          order: 1,
        ),
      },
    );

Grammar _grammar({
  required String id,
  required Set<String> terminals,
  required Set<String> nonterminals,
  required Set<Production> productions,
}) =>
    Grammar(
      id: id,
      name: id,
      terminals: terminals,
      nonterminals: nonterminals,
      startSymbol: 'S',
      productions: productions,
      type: GrammarType.contextFree,
      created: DateTime.utc(2026, 8, 26),
      modified: DateTime.utc(2026, 8, 26),
    );

State _state(
  String id, {
  bool initial = false,
  bool accepting = false,
  required double x,
}) =>
    State(
      id: id,
      label: id,
      position: Vector2(x, 100),
      isInitial: initial,
      isAccepting: accepting,
    );

PDATransition _transition({
  required String id,
  required State from,
  required State to,
  required String input,
  required String pop,
  List<String> push = const [],
  Vector2? controlPoint,
}) =>
    PDATransition(
      id: id,
      fromState: from,
      toState: to,
      label: PDATransition.formatLabel(
        inputSymbol: input,
        popSymbol: pop,
        pushSymbol: push.join(),
        isLambdaInput: input.isEmpty,
        isLambdaPop: pop.isEmpty,
        isLambdaPush: push.isEmpty,
      ),
      controlPoint: controlPoint,
      inputSymbol: input,
      popSymbol: pop,
      pushSymbol: push.join(),
      pushSymbols: push,
      isLambdaInput: input.isEmpty,
      isLambdaPop: pop.isEmpty,
      isLambdaPush: push.isEmpty,
    );

PDA _pda({
  required String id,
  required Set<State> states,
  required Set<PDATransition> transitions,
  required State initial,
  required Set<State> accepting,
  required Set<String> alphabet,
  required Set<String> stackAlphabet,
  PDAAcceptanceMode mode = PDAAcceptanceMode.finalState,
}) =>
    PDA(
      id: id,
      name: id,
      states: states,
      transitions: transitions,
      alphabet: alphabet,
      initialState: initial,
      acceptingStates: accepting,
      created: DateTime.utc(2026, 8, 26),
      modified: DateTime.utc(2026, 8, 26),
      bounds: const math.Rectangle(0.0, 0.0, 400.0, 300.0),
      stackAlphabet: stackAlphabet,
      initialStackSymbol: 'bottom',
      acceptanceMode: mode,
    );

final class _AlwaysCancelled implements CancellationProbe {
  @override
  bool get isCancelled => true;
}

final class _FixedElapsedClock implements ElapsedClock {
  const _FixedElapsedClock(this.elapsed);

  @override
  final Duration elapsed;
}

final class _AlwaysStale implements RequestFreshnessProbe {
  const _AlwaysStale();

  @override
  bool get isStale => true;
}
