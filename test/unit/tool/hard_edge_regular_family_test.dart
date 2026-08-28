import 'dart:convert';
import 'dart:io';
import 'dart:math' as math;

import 'package:test/test.dart';
import 'package:turing_lab/core/algorithms/regex_to_nfa_converter.dart';
import 'package:turing_lab/core/models/fsa.dart';
import 'package:turing_lab/core/models/fsa_transition.dart';
import 'package:turing_lab/core/models/state.dart';
import 'package:vector_math/vector_math_64.dart';

import '../../../tool/hard_edge/catalog.dart';
import '../../../tool/hard_edge/families/regular_certification.dart';
import '../../../tool/hard_edge/families/regular_family.dart';
import '../../../tool/hard_edge/families/regular_matrix.dart';
import '../../../tool/hard_edge/families/regular_oracles.dart';
import '../../../tool/hard_edge/models.dart';
import '../../../tool/hard_edge/mutation.dart';
import '../../../tool/hard_edge/oracles.dart';
import '../../../tool/hard_edge/runner.dart';

void main() {
  group('regular independent oracles', () {
    test('epsilon-NFA oracle agrees with the regex AST oracle', () {
      const expression = '(a|b)*abb';
      final node = RegexToNFAConverter.parse(expression)!;
      final automaton = RegexToNFAConverter.convert(expression).data!;

      for (final word in regularTokenWords(const ['a', 'b'], 4)) {
        final oracle = regularOracleAccepts(automaton, word);

        expect(oracle, isA<OracleDefinitive<bool, RegularOracleEvidence>>());
        expect(
          (oracle as OracleDefinitive<bool, RegularOracleEvidence>).value,
          regularRegexOracleAccepts(
            node,
            word,
            contextAlphabet: const {'a', 'b'},
          ),
          reason: 'word=$word',
        );
      }
    });

    test('keeps multi-character alphabet tokens atomic', () {
      final automaton = _singleTokenAutomaton('token');
      final signature = regularLanguageSignature(
        automaton,
        const ['token'],
        const RegularOracleBudget(maximumWordLength: 1),
      );

      expect(
        signature,
        isA<OracleDefinitive<Map<String, bool>, RegularOracleEvidence>>(),
      );
      final values = (signature
              as OracleDefinitive<Map<String, bool>, RegularOracleEvidence>)
          .value;
      expect(values['[]'], isFalse);
      expect(values['["token"]'], isTrue);
    });

    test('reports bounds without coercing them into rejection', () {
      final automaton = RegexToNFAConverter.convert('a*').data!;

      expect(
        regularOracleAccepts(
          automaton,
          const ['a'],
          maximumConfigurations: 1,
        ),
        isA<OracleBoundedUnknown<bool, RegularOracleEvidence>>(),
      );
      expect(
        regularLanguageSignature(
          automaton,
          const ['a', 'b'],
          const RegularOracleBudget(maximumWords: 1),
        ),
        isA<OracleBoundedUnknown<Map<String, bool>, RegularOracleEvidence>>(),
      );
    });

    test('mixed epsilon-symbol edges retain their consuming branch', () {
      final initial = State(
        id: 'q0',
        label: 'q0',
        position: Vector2.zero(),
        isInitial: true,
      );
      final accepting = State(
        id: 'q1',
        label: 'q1',
        position: Vector2(40, 0),
        isAccepting: true,
      );
      final automaton = _automaton(
        id: 'mixed-edge',
        states: {initial, accepting},
        transitions: {
          FSATransition(
            id: 'mixed',
            fromState: initial,
            toState: accepting,
            inputSymbols: const {'ε', 'a'},
          ),
        },
        alphabet: const {'a'},
        initial: initial,
        accepting: {accepting},
      );

      final result = regularOracleAccepts(automaton, const ['a']);

      expect(result, isA<OracleDefinitive<bool, RegularOracleEvidence>>());
      expect(
        (result as OracleDefinitive<bool, RegularOracleEvidence>).value,
        isTrue,
      );
    });
  });

  group('regular certification', () {
    test('the 25-path matrix links every entry to executable evidence', () {
      final entries = [
        ...regularAlgorithmInventory,
        ...regularProviderInventory
      ];

      expect(entries, hasLength(25));
      expect(entries.map((entry) => entry.id).toSet(), hasLength(25));
      for (final entry in entries) {
        expect(entry.entryPoints, isNotEmpty, reason: entry.id);
        expect(entry.properties, isNotEmpty, reason: entry.id);
        expect(entry.evidenceCommand, isNotEmpty, reason: entry.id);
        final commandTarget = entry.evidenceCommand.split(' ').last;
        expect(File(commandTarget).existsSync(), isTrue, reason: entry.id);
      }
    });

    test('the simulator catalog case executes every simulator entry point', () {
      final descriptor = regularHardEdgeDescriptors.singleWhere(
        (descriptor) => descriptor.id == 'regular-path-fsa-simulator',
      );

      expect(descriptor.property, 'regular.trace-replay');
      expect(
        regularHardEdgeDescriptors
            .singleWhere(
              (descriptor) =>
                  descriptor.id == 'regular-property-resource-outcomes',
            )
            .property,
        'regular.resource-outcomes',
      );
    });

    test('POSIX provider process trees kill descendants deepest first', () {
      expect(
        RegularProviderProcessTree.descendantsDeepestFirst(
          const {
            11: 10,
            12: 10,
            13: 11,
            14: 13,
            99: 98,
          },
          10,
        ),
        [14, 13, 11, 12],
      );
    });

    test('catalog fragment is schema-valid with current fixture digests',
        () async {
      final catalog = await HardEdgeCatalog.load(
        repositoryRoot: Directory.current,
        manifestFile: File(
          'test/fixtures/hard_edge/regular/catalog.fragment.json',
        ),
      );

      expect(
        catalog.manifest.cases,
        hasLength(regularHardEdgeDescriptors.length),
      );
      expect(catalog.manifest.mutations, hasLength(3));
      expect(
        catalog.manifest.cases.map((testCase) => testCase.id).toSet(),
        regularHardEdgeDescriptors.map((descriptor) => descriptor.id).toSet(),
      );
      final descriptorsById = {
        for (final descriptor in regularHardEdgeDescriptors)
          descriptor.id: descriptor,
      };
      for (final testCase in catalog.manifest.cases) {
        final descriptor = descriptorsById[testCase.id]!;
        expect(testCase.algorithm, descriptor.algorithm);
        expect(testCase.property, descriptor.property);
        expect(testCase.expectedOutcome, descriptor.expectedOutcome);
        expect(testCase.requiredTool, descriptor.requiredTool);
      }
    });

    test('catalog adapter certifies every algorithm/property descriptor',
        () async {
      final catalog = await HardEdgeCatalog.load(
        repositoryRoot: Directory.current,
        manifestFile: File(
          'test/fixtures/hard_edge/regular/catalog.fragment.json',
        ),
      );
      final executedProviderTests = <String>[];
      final executor = RegularHardEdgeExecutor(
        providerEvidenceRunner: (testPath) async {
          executedProviderTests.add(testPath);
          return 0;
        },
      );

      for (final testCase in catalog.manifest.cases) {
        final fixture = await catalog.fixtureFor(testCase).readAsString();
        final decodedFixture = jsonDecode(fixture);
        final outcome = await executor.execute(testCase, decodedFixture);
        expect(
          outcome.name,
          testCase.expectedOutcome.name,
          reason: '${testCase.algorithm}/${testCase.property}',
        );
      }
      expect(executedProviderTests, hasLength(3));
    });

    test('all core properties pass and reports are deterministic', () async {
      final runner =
          RegularCertificationRunner(repositoryRoot: Directory.current);
      const options = RegularCertificationOptions(cases: 2);

      final first = await runner.run(options);
      final second = await runner.run(options);

      expect(first.status, RegularCertificationStatus.passed);
      expect(first.checks, hasLength(20));
      expect(first.toJson(), second.toJson());
    });

    test('shared executor materializes and executes a generated seed',
        () async {
      final executor = RegularHardEdgeExecutor(
        providerEvidenceRunner: (_) async => 0,
      );
      final testCase = _catalogCase('regular.generated-oracle');
      const fixture = {'family': 'regular'};

      final materialized = await executor.materialize(testCase, fixture, 91);

      expect(materialized, containsPair('seed', 91));
      expect(
        await executor.execute(testCase, materialized),
        HardEdgeExecutionOutcome.pass,
      );
    });

    test('fixture payload and expectations change replay outcome', () async {
      final executor = RegularHardEdgeExecutor(
        providerEvidenceRunner: (_) async => 0,
      );
      final testCase = _catalogCase(
        'regular.regex-oracle',
        algorithm: 'regex-parser-and-converter',
      );
      const valid = <String, Object?>{
        'family': 'regular',
        'property': 'regular.regex-oracle',
        'regex': '[a\\-z]',
        'accepted': ['a', '-', 'z'],
        'rejected': ['b'],
        'expectedStatus': 'passed',
      };

      expect(
        await executor.execute(testCase, valid),
        HardEdgeExecutionOutcome.pass,
      );
      expect(
        await executor.execute(
          testCase,
          {
            ...valid,
            'accepted': const ['a', '-', 'z', 'b']
          },
        ),
        HardEdgeExecutionOutcome.violation,
      );
      expect(
        await executor.execute(
          testCase,
          {...valid, 'expectedStatus': 'failed'},
        ),
        HardEdgeExecutionOutcome.violation,
      );
    });

    test('provider evidence is serialized under parallel catalog jobs',
        () async {
      var active = 0;
      var maximumActive = 0;
      final executor = RegularHardEdgeExecutor(
        providerEvidenceRunner: (_) async {
          active++;
          maximumActive = math.max(maximumActive, active);
          await Future<void>.delayed(const Duration(milliseconds: 10));
          active--;
          return 0;
        },
      );
      final cases = [
        _catalogCase(
          'regular.provider-integration',
          algorithm: 'automaton-algorithm-provider',
          requiredTool: 'flutter',
        ),
        _catalogCase(
          'regular.provider-stale-result',
          algorithm: 'automaton-simulation-provider',
          requiredTool: 'flutter',
        ),
        _catalogCase(
          'regular.provider-stale-result',
          algorithm: 'regex-editor-provider',
          requiredTool: 'flutter',
        ),
      ];

      final outcomes = await Future.wait(
        cases.map(
          (testCase) => executor.execute(
            testCase,
            const {'family': 'regular'},
          ),
        ),
      );

      expect(outcomes, everyElement(HardEdgeExecutionOutcome.pass));
      expect(maximumActive, 1);
    });

    test('failure artifact replays and shrinks through the real executor',
        () async {
      final temp = await Directory.systemTemp.createTemp('regular-replay-');
      addTearDown(() => temp.delete(recursive: true));
      final executor = RegularHardEdgeExecutor(
        providerEvidenceRunner: (_) async => 0,
      );
      final fixture = <String, Object?>{
        ...jsonDecode(
          await File(
            'test/fixtures/hard_edge/regular/shrink_probe.json',
          ).readAsString(),
        ) as Map,
        'expectedMutantKilled': false,
      };
      final testCase = _catalogCase(
        'regular.completion',
        algorithm: 'dfa-completion',
      ).copyWith(
        sha256: hardEdgeSha256(
          utf8.encode(canonicalJsonEncode(fixture)),
        ),
      );
      final failure = File('${temp.path}/failure.json');
      await failure.writeAsString(
        jsonEncode(
          HardEdgeFailureArtifact(
            testCase: testCase,
            fixture: fixture,
            minimalFixture: null,
            minimized: false,
          ).toJson(),
        ),
      );

      final replay = await replayFailureArtifact(
        failureFile: failure,
        executor: executor,
      );
      expect(replay.status, HardEdgeCaseStatus.failed);

      final minimized = await shrinkFailureArtifact(
        repositoryRoot: temp,
        failureFile: failure,
        outputPath: '${temp.path}/minimized.json',
        executor: executor,
        maxAttempts: 64,
        shrinker: regularFailureFixtureShrinker,
        isValid: regularFailureFixtureIsValid,
        isApplicable: regularFailureFixtureIsApplicable,
      );
      final minimizedArtifact = await readFailureArtifact(minimized);
      expect(minimizedArtifact.minimized, isTrue);
      expect(
        await replayFailureArtifact(
          failureFile: minimized,
          executor: executor,
        ).then((result) => result.status),
        HardEdgeCaseStatus.failed,
      );
    });

    test('shared executor enforces the matrix algorithm/property pair',
        () async {
      final executor = RegularHardEdgeExecutor(
        providerEvidenceRunner: (_) async => 0,
      );
      final mismatched = _catalogCase(
        'regular.completion',
        algorithm: 'regex-analyzer',
      );

      await expectLater(
        executor.execute(mismatched, const {'family': 'regular'}),
        throwsA(isA<HardEdgeConfigurationException>()),
      );
      expect(
        await executor.execute(
          _catalogCase(
            'regular.provider-stale-result',
            algorithm: 'automaton-simulation-provider',
            requiredTool: 'flutter',
          ),
          const {'family': 'regular'},
        ),
        HardEdgeExecutionOutcome.pass,
      );
    });

    test('registered mutation probes are killed', () async {
      final executor = RegularHardEdgeMutationExecutor();
      for (final operatorId in regularMutationOperatorIds) {
        final mutation = HardEdgeMutation(
          id: 'regular-$operatorId',
          family: 'regular',
          property: 'regular.mutations',
          operatorId: operatorId,
          fixture: 'test/fixtures/hard_edge/regular/mutation_probes.json',
          sha256: 'a' * 64,
          requiredTool: null,
        );
        expect(
          await executor.execute(mutation, const {
            'family': 'regular',
            'property': 'regular.mutations',
            'operators': [
              'flip-initial-acceptance',
              'ignore-epsilon-reachability',
              'skip-dfa-completion',
            ],
          }),
          HardEdgeMutationStatus.killed,
        );
      }
    });

    test('a mutation probe that is not distinguished survives', () async {
      String? observedOperator;
      final executor = RegularHardEdgeMutationExecutor(
        mutationProbe: (operatorId) {
          observedOperator = operatorId;
          return false;
        },
      );
      final mutation = HardEdgeMutation(
        id: 'regular-survivor',
        family: 'regular',
        property: 'regular.mutations',
        operatorId: 'skip-dfa-completion',
        fixture: 'test/fixtures/hard_edge/regular/mutation_probes.json',
        sha256: 'a' * 64,
        requiredTool: null,
      );

      expect(
        await executor.execute(mutation, const {
          'family': 'regular',
          'property': 'regular.mutations',
          'operators': [
            'flip-initial-acceptance',
            'ignore-epsilon-reachability',
            'skip-dfa-completion',
          ],
        }),
        HardEdgeMutationStatus.survived,
      );
      expect(observedOperator, 'skip-dfa-completion');
    });
  });
}

HardEdgeCatalogCase _catalogCase(
  String property, {
  String algorithm = 'fsa-simulator',
  String? requiredTool,
}) =>
    HardEdgeCatalogCase(
      id: 'regular-generated',
      family: 'regular',
      algorithm: algorithm,
      sourceKind: HardEdgeSourceKind.generated,
      seed: 335,
      property: property,
      provenance: const HardEdgeProvenance(
        origin: 'independently-authored',
        independentlyAuthored: true,
        generator: regularGeneratorVersion,
        licenseBasis: 'LICENSE.txt',
      ),
      license: 'Apache-2.0',
      regressionIssue: 335,
      platforms: const ['all'],
      sha256: 'a' * 64,
      generatorVersion: regularGeneratorVersion,
      oracleVersion: regularOracleVersion,
      budget: const GenerationBudget(
        maxSymbols: 3,
        maxWordLength: 4,
        maxStates: 4,
        maxTransitions: 8,
        maxRegexNodes: 8,
      ),
      fixture: 'test/fixtures/hard_edge/regular/generated_oracle.json',
      expectedOutcome: HardEdgeExpectedOutcome.pass,
      requiredTool: requiredTool,
    );

FSA _singleTokenAutomaton(String token) {
  final initial = State(
    id: 'q0',
    label: 'q0',
    position: Vector2.zero(),
    isInitial: true,
    isAccepting: false,
  );
  final accepting = State(
    id: 'q1',
    label: 'q1',
    position: Vector2(40, 0),
    isInitial: false,
    isAccepting: true,
  );
  final now = DateTime.utc(2026);
  return FSA(
    id: 'single-token',
    name: 'single-token',
    states: {initial, accepting},
    transitions: {
      FSATransition.deterministic(
        id: 't0',
        fromState: initial,
        toState: accepting,
        symbol: token,
      ),
    },
    alphabet: {token},
    initialState: initial,
    acceptingStates: {accepting},
    created: now,
    modified: now,
    bounds: const math.Rectangle(0, 0, 100, 100),
  );
}

FSA _automaton({
  required String id,
  required Set<State> states,
  required Set<FSATransition> transitions,
  required Set<String> alphabet,
  required State initial,
  required Set<State> accepting,
}) {
  final now = DateTime.utc(2026);
  return FSA(
    id: id,
    name: id,
    states: states,
    transitions: transitions,
    alphabet: alphabet,
    initialState: initial,
    acceptingStates: accepting,
    created: now,
    modified: now,
    bounds: const math.Rectangle(0, 0, 100, 100),
  );
}
