import 'dart:convert';

import 'package:test/test.dart';

import '../../../tool/hard_edge/domains.dart';
import '../../../tool/hard_edge/generation.dart';
import '../../../tool/hard_edge/models.dart';
import '../../../tool/hard_edge/runner.dart';
import '../../../tool/hard_edge/shrinking.dart';

void main() {
  const budget = GenerationBudget(
    maxSymbols: 3,
    maxWordLength: 4,
    maxStates: 3,
    maxTransitions: 5,
    maxProductions: 4,
    maxRegexNodes: 7,
    maxTapeCells: 5,
    maxStackDepth: 4,
    maxIterations: 3,
  );

  GenerationContext context(
    GenerationMode mode, {
    int seed = 42,
    int caseIndex = 0,
  }) =>
      GenerationContext(
        seed: seed,
        caseIndex: caseIndex,
        mode: mode,
        budget: budget,
      );

  group('stable deterministic generation', () {
    test('xorshift32 has a fixed cross-runtime sequence', () {
      final random = StableRandom(1);

      expect(
        [for (var index = 0; index < 5; index++) random.nextUint32()],
        [270369, 67634689, 2647435461, 307599695, 2398689233],
      );
    });

    test('case mixing and shuffling replay exactly', () {
      List<Object> sample() {
        final random = StableRandom.forCase(0xdecafbad, 17);
        return [
          random.nextUint32(),
          random.nextInt(7),
          random.nextBool(),
          random.shuffled(['aa', 'β', '🙂', 'z']),
        ];
      }

      expect(sample(), sample());
      expect(
        StableRandom.forCase(9, 1).nextUint32(),
        isNot(StableRandom.forCase(9, 2).nextUint32()),
      );
    });

    test('generated case JSON and reproduction identity are canonical', () {
      final generated = generateCase<List<String>>(
        family: 'word',
        seed: 19,
        caseIndex: 3,
        mode: GenerationMode.valid,
        budget: budget,
        generator: const WordGenerator(alphabet: ['token', '🙂']),
        encodeValue: (value) => {'tokens': value, 'z': 1, 'a': 2},
      );

      final first = generated.toCanonicalJson();
      final second = generated.toCanonicalJson();
      final decoded = jsonDecode(first) as Map<String, dynamic>;

      expect(first, second);
      expect(generated.id, 'word-00000013-000003');
      expect(
        generated.reproductionCommand,
        'dart run tool/hard_edge_cases.dart run --family word '
        '--property generated-case --seed 19',
      );
      expect(decoded['generatorVersion'], '1');
      expect(decoded['streamId'], 'word/generated-case/1');
      expect(decoded['prng'], {
        'algorithm': 'xorshift32',
        'version': 1,
      });
      expect((decoded['value'] as Map).keys, ['a', 'tokens', 'z']);
      expect((decoded['value'] as Map)['tokens'], everyElement(isA<String>()));
    });

    test('mode changes are explicit and malformed tokens stay visible', () {
      expect(const SymbolGenerator().generate(context(GenerationMode.valid)),
          isNotEmpty);
      expect(
        const SymbolGenerator().generate(
          context(GenerationMode.boundaryValid),
        ),
        'token',
      );
      expect(
        const SymbolGenerator().generate(context(GenerationMode.malformed)),
        '',
      );
      expect(
        const WordGenerator(alphabet: ['multi-token']).generate(
          context(GenerationMode.malformed),
        ),
        contains(''),
      );
    });

    test('stable IDs do not depend on object hash codes', () {
      expect(stableId('state', 12), 'state-000012');
      expect(
        const AutomatonGenerator()
            .generate(context(GenerationMode.valid, seed: 91))
            .toJson(),
        const AutomatonGenerator()
            .generate(context(GenerationMode.valid, seed: 91))
            .toJson(),
      );
    });

    test('family and property paths derive independent stable streams', () {
      GeneratedCase<List<String>> generated(String property) => generateCase(
            family: 'word',
            property: property,
            seed: 91,
            caseIndex: 0,
            mode: GenerationMode.boundaryValid,
            budget: budget,
            generator: const WordGenerator(alphabet: ['a', 'b', 'c']),
            encodeValue: (value) => value,
          );

      expect(generated('alpha').toCanonicalJson(),
          generated('alpha').toCanonicalJson());
      expect(
        StableRandom.forCase(
          91,
          0,
          streamId: 'word/alpha/1',
        ).nextUint32(),
        isNot(
          StableRandom.forCase(
            91,
            0,
            streamId: 'word/beta/1',
          ).nextUint32(),
        ),
      );
    });
  });

  group('domain catalog and rigid budgets', () {
    test('boundary mode reaches each finite budget without flattening tokens',
        () {
      final alphabet = const AlphabetGenerator().generate(
        context(GenerationMode.boundaryValid),
      );
      final word = WordGenerator(alphabet: alphabet).generate(
        context(GenerationMode.boundaryValid),
      );
      final tape = const TapeGenerator().generate(
        context(GenerationMode.boundaryValid),
      );
      final stack = const StackGenerator().generate(
        context(GenerationMode.boundaryValid),
      );
      final regex = RegexAstGenerator(alphabet: alphabet).generate(
        context(GenerationMode.boundaryValid),
      );
      final automaton = const AutomatonGenerator().generate(
        context(GenerationMode.boundaryValid),
      );
      final grammar = const GrammarGenerator().generate(
        context(GenerationMode.boundaryValid),
      );
      final transducer = const TransducerGenerator().generate(
        context(GenerationMode.boundaryValid),
      );
      final lSystem = const LSystemGenerator().generate(
        context(GenerationMode.boundaryValid),
      );

      expect(alphabet, hasLength(budget.maxSymbols));
      expect(word, hasLength(budget.maxWordLength));
      expect(word, everyElement(isA<String>()));
      expect(tape, hasLength(budget.maxTapeCells));
      expect(stack, hasLength(budget.maxStackDepth));
      expect(regex.nodeCount, budget.maxRegexNodes);
      expect(automaton.states, hasLength(budget.maxStates));
      expect(automaton.transitions, hasLength(budget.maxTransitions));
      expect(grammar.productions, hasLength(budget.maxProductions));
      expect(transducer.states, hasLength(budget.maxStates));
      expect(transducer.transitions, hasLength(budget.maxTransitions));
      expect(lSystem.productions, hasLength(budget.maxProductions));
      expect(lSystem.iterations, budget.maxIterations);
    });

    test('all modes stay within every budget over a seed range', () {
      for (final mode in GenerationMode.values) {
        for (var seed = 0; seed < 25; seed++) {
          final automaton = const AutomatonGenerator().generate(
            context(mode, seed: seed),
          );
          final grammar = const GrammarGenerator().generate(
            context(mode, seed: seed),
          );
          final transducer = const TransducerGenerator().generate(
            context(mode, seed: seed),
          );
          final lSystem = const LSystemGenerator().generate(
            context(mode, seed: seed),
          );
          final regex = const RegexAstGenerator().generate(
            context(mode, seed: seed),
          );

          expect(
              automaton.alphabet.length, lessThanOrEqualTo(budget.maxSymbols));
          expect(automaton.states.length, lessThanOrEqualTo(budget.maxStates));
          expect(
            automaton.transitions.length,
            lessThanOrEqualTo(budget.maxTransitions),
          );
          expect(
              grammar.terminals.length, lessThanOrEqualTo(budget.maxSymbols));
          expect(
            grammar.productions.length,
            lessThanOrEqualTo(budget.maxProductions),
          );
          expect(transducer.states.length, lessThanOrEqualTo(budget.maxStates));
          expect(
            transducer.transitions.length,
            lessThanOrEqualTo(budget.maxTransitions),
          );
          expect(
            lSystem.productions.length,
            lessThanOrEqualTo(budget.maxProductions),
          );
          expect(regex.nodeCount, lessThanOrEqualTo(budget.maxRegexNodes));
        }
      }
    });

    test('primitive state, transition, and production generators are typed',
        () {
      final valid = context(GenerationMode.valid);
      final state = const StateGenerator().generate(valid);
      final transition = TransitionGenerator(
        stateIds: [state.id],
        alphabet: const ['multi-token'],
      ).generate(valid);
      final production = const ProductionGenerator(
        nonterminals: ['S'],
        terminals: ['multi-token'],
      ).generate(valid);

      expect(state.id, startsWith('state-'));
      expect(transition.readTokens, anyOf(isEmpty, ['multi-token']));
      expect(production.leftTokens, ['S']);
      expect(production.rightTokens, anyOf(isEmpty, ['multi-token']));
    });

    test('malformed structures carry a deterministic defect', () {
      final automaton = const AutomatonGenerator().generate(
        context(GenerationMode.malformed),
      );
      final grammar = const GrammarGenerator().generate(
        context(GenerationMode.malformed),
      );
      final transducer = const TransducerGenerator().generate(
        context(GenerationMode.malformed),
      );
      final lSystem = const LSystemGenerator().generate(
        context(GenerationMode.malformed),
      );
      final regex = const RegexAstGenerator().generate(
        context(GenerationMode.malformed),
      );

      expect(automaton.malformation, 'dangling-transition-source');
      expect(automaton.transitions.first.fromId, 'missing-state');
      expect(grammar.malformation, 'empty-production-left');
      expect(grammar.productions.first.leftTokens, isEmpty);
      expect(transducer.transitions.first.fromId, 'missing-state');
      expect(lSystem.productions.first.leftTokens, isEmpty);
      expect(regex.kind, GeneratedRegexKind.symbol);
      expect(regex.symbol, isNull);
    });
  });

  group('deterministic domain-aware shrinking', () {
    test('token shrinking minimizes length before token content', () {
      final candidates =
          const TokenListShrinker().candidates(['long', 'β', 'tail']).toList();
      final encoded = candidates.map(jsonEncode).toList();

      expect(candidates.first, isEmpty);
      expect(candidates[1], ['long']);
      expect(encoded, contains(jsonEncode(['long', 'β'])));
      expect(
        encoded.indexOf(jsonEncode(['long', 'β'])),
        lessThan(encoded.indexOf(jsonEncode(['', 'β', 'tail']))),
      );
    });

    test('automata remove states before transitions and symbols', () {
      final automaton = const AutomatonGenerator().generate(
        context(GenerationMode.boundaryValid),
      );
      final candidates =
          const AutomatonShrinker().candidates(automaton).toList();

      expect(candidates.first.states, isEmpty);
      expect(candidates.first.transitions, isEmpty);
      expect(candidates.first.alphabet, automaton.alphabet);
      expect(
        candidates.indexWhere((candidate) => candidate.alphabet.isEmpty),
        greaterThan(
          candidates.indexWhere((candidate) => candidate.transitions.isEmpty),
        ),
      );
    });

    test('grammars remove productions before symbols and right-hand words', () {
      final grammar = const GrammarGenerator().generate(
        context(GenerationMode.boundaryValid),
      );
      final candidates = const GrammarShrinker().candidates(grammar).toList();

      expect(candidates.first.productions, isEmpty);
      expect(candidates.first.terminals, grammar.terminals);
      expect(
        candidates.indexWhere((candidate) => candidate.terminals.isEmpty),
        greaterThan(0),
      );
    });

    test('a shrunk failure emits a standalone fixture and exact command', () {
      final source = GeneratedCase<List<String>>(
        family: 'word',
        seed: 7,
        caseIndex: 2,
        mode: GenerationMode.valid,
        budget: budget,
        value: const ['a', 'multi-token', 'b'],
        encodeValue: (value) => {'outcome': 'violation', 'tokens': value},
      );

      final result = shrinkFailure(
        source: source,
        shrinker: const TokenListShrinker(),
        stillFails: (candidate) => candidate.length >= 2,
      );
      final fixture = jsonDecode(result.toCanonicalFixture()) as Map;
      final standalone = HardEdgeFailureArtifact.parse(
        result.toCanonicalFailureArtifact(
          catalogCase: _catalogCaseJson(
            budget: budget,
            fixture: result.fixtureFilename,
          ),
        ),
      );

      expect(result.minimalValue, hasLength(2));
      expect(result.fixtureFilename,
          'hard-edge-word-00000007-000002-minimized.json');
      expect(
        result.reproductionCommand,
        'dart run tool/hard_edge_cases.dart replay --fixture '
        'hard-edge-word-00000007-000002-minimized.json',
      );
      expect(fixture['seed'], 7);
      expect((fixture['value'] as Map)['tokens'], result.minimalValue);
      expect(
        (standalone.fixture as Map)['tokens'],
        result.minimalValue,
      );
    });

    test('shrinking rejects a source that does not reproduce', () {
      final source = GeneratedCase<List<String>>(
        family: 'word',
        seed: 1,
        caseIndex: 0,
        mode: GenerationMode.valid,
        budget: budget,
        value: const ['a'],
        encodeValue: (value) => value,
      );

      expect(
        () => shrinkFailure(
          source: source,
          shrinker: const TokenListShrinker(),
          stillFails: (_) => false,
        ),
        throwsArgumentError,
      );
    });

    test('shrinking bounds duplicate streams and preserves applicability', () {
      final source = GeneratedCase<List<String>>(
        family: 'word',
        seed: 1,
        caseIndex: 0,
        mode: GenerationMode.valid,
        budget: budget,
        value: const ['a', 'b'],
        encodeValue: (value) => value,
      );
      final duplicate = _DuplicateShrinker(source.value);

      final bounded = shrinkFailure(
        source: source,
        shrinker: duplicate,
        stillFails: (_) => true,
        maxAttempts: 3,
      );
      expect(bounded.attempts, 3);

      final applicable = shrinkFailure(
        source: source,
        shrinker: const TokenListShrinker(),
        stillFails: (_) => true,
        isValid: (candidate) => candidate.isNotEmpty,
        isApplicable: (candidate) => candidate.length >= 2,
      );
      expect(applicable.minimalValue, hasLength(2));
    });

    test('case indexes are uint32 and impossible malformed budgets fail', () {
      expect(
        () => StableRandom.forCase(1, 0x100000000),
        throwsRangeError,
      );
      const zero = GenerationBudget(
        maxSymbols: 0,
        maxWordLength: 0,
        maxStates: 0,
        maxTransitions: 0,
        maxProductions: 0,
        maxRegexNodes: 1,
        maxTapeCells: 0,
        maxStackDepth: 0,
        maxIterations: 0,
      );
      final malformed = GenerationContext(
        seed: 1,
        caseIndex: 0,
        mode: GenerationMode.malformed,
        budget: zero,
      );
      expect(
        () => const AlphabetGenerator().generate(malformed),
        throwsArgumentError,
      );
      expect(
        () => const WordGenerator(alphabet: []).generate(malformed),
        throwsArgumentError,
      );
    });
  });
}

final class _DuplicateShrinker implements DomainShrinker<List<String>> {
  const _DuplicateShrinker(this.value);

  final List<String> value;

  @override
  Iterable<List<String>> candidates(List<String> _) sync* {
    while (true) {
      yield value;
    }
  }
}

Map<String, Object?> _catalogCaseJson({
  required GenerationBudget budget,
  required String fixture,
}) =>
    {
      'algorithm': 'generated-word-check',
      'budget': budget.toJson(),
      'expectedOutcome': 'violation',
      'family': 'word',
      'fixture': fixture,
      'generatorVersion': '1',
      'id': 'word-00000007-000002-minimized',
      'license': 'Apache-2.0',
      'oracleVersion': '1',
      'platforms': ['all'],
      'property': 'generated-case',
      'provenance': {
        'generator': 'hard-edge test generator',
        'independentlyAuthored': true,
        'jflapVersion': null,
        'licenseBasis': 'LICENSE.txt',
        'origin': 'Independently authored test fixture',
        'sourceRevision': null,
        'sourceSha256': null,
      },
      'regressionIssue': 334,
      'requiredTool': null,
      'seed': 7,
      'sha256': '0' * 64,
      'sourceKind': 'generated',
    };
