import 'dart:math' as math;

import 'package:test/test.dart';
import 'package:turing_lab/core/algorithms/pda_simulator.dart';
import 'package:turing_lab/core/algorithms/pda_to_cfg_converter.dart';
import 'package:turing_lab/core/models/pda.dart';
import 'package:turing_lab/core/models/pda_transition.dart';
import 'package:turing_lab/core/models/state.dart';
import 'package:vector_math/vector_math_64.dart';

import '../../../tool/hard_edge/families/pda_oracle.dart';
import '../../../tool/hard_edge/families/pda_family.dart';
import '../../../tool/hard_edge/families/pda_executor.dart';
import '../../../tool/hard_edge/catalog.dart';
import '../../../tool/hard_edge/models.dart';
import '../../../tool/hard_edge/mutation.dart';
import '../../../tool/hard_edge/outcomes.dart';
import '../../../tool/hard_edge/resources.dart';
import '../../../tool/hard_edge/runner.dart';

void main() {
  group('independent PDA explorer', () {
    test('covers every epsilon input, pop, and push combination', () {
      for (final lambdaInput in [false, true]) {
        for (final lambdaPop in [false, true]) {
          for (final lambdaPush in [false, true]) {
            final pda = _singleTransitionPda(
              lambdaInput: lambdaInput,
              lambdaPop: lambdaPop,
              lambdaPush: lambdaPush,
            );
            final input = lambdaInput ? '' : 'a';

            final oracle = const PdaExhaustiveExplorer().explore(
              pda: pda,
              input: input,
            );
            final canonical = PDASimulator.simulateNPDA(pda, input);

            expect(
              oracle.outcome,
              VerificationOutcomeCode.accepted,
              reason: 'input=$lambdaInput pop=$lambdaPop push=$lambdaPush',
            );
            expect(canonical.isSuccess, isTrue, reason: canonical.error);
            expect(canonical.data!.accepted, isTrue);
            expect(oracle.witness, hasLength(1));
            expect(
              oracle.witness.single.after.stack,
              [
                if (lambdaPop) 'bottom',
                if (!lambdaPush) 'stack-token',
              ],
            );
          }
        }
      }
    });

    test('keeps final-state, empty-stack, and combined modes distinct', () {
      final residual = _singleTransitionPda(
        lambdaInput: false,
        lambdaPop: true,
        lambdaPush: true,
      );
      final empty = _singleTransitionPda(
        lambdaInput: false,
        lambdaPop: false,
        lambdaPush: true,
      );
      const explorer = PdaExhaustiveExplorer();

      expect(
        explorer
            .explore(
              pda: residual,
              input: 'a',
              mode: PDAAcceptanceMode.finalState,
            )
            .outcome,
        VerificationOutcomeCode.accepted,
      );
      expect(
        explorer
            .explore(
              pda: residual,
              input: 'a',
              mode: PDAAcceptanceMode.emptyStack,
            )
            .outcome,
        VerificationOutcomeCode.rejected,
      );
      for (final mode in [
        PDAAcceptanceMode.finalState,
        PDAAcceptanceMode.emptyStack,
        PDAAcceptanceMode.both,
      ]) {
        expect(
          explorer.explore(pda: empty, input: 'a', mode: mode).outcome,
          VerificationOutcomeCode.accepted,
        );
      }
    });

    test('reports budget, cancellation, and stale request outcomes', () {
      final pda = _epsilonCyclePda();
      const explorer = PdaExhaustiveExplorer();

      final bounded = explorer.explore(
        pda: pda,
        input: 'a',
        budget: ResourceBudget(maxConfigurations: 0),
      );
      expect(bounded.outcome, VerificationOutcomeCode.configurationLimit);

      final genericBound = explorer.explore(
        pda: pda,
        input: 'a',
        budget: ResourceBudget(maxFrontier: 0),
      );
      expect(genericBound.outcome, VerificationOutcomeCode.boundedUnknown);

      final timeout = explorer.explore(
        pda: pda,
        input: 'a',
        budget: ResourceBudget(timeout: Duration.zero),
        clock: const _FixedElapsedClock(Duration(microseconds: 1)),
      );
      expect(timeout.outcome, VerificationOutcomeCode.timeout);

      final memory = explorer.explore(
        pda: pda,
        input: 'a',
        budget: ResourceBudget(maxMemoryBytes: 0),
      );
      expect(memory.outcome, VerificationOutcomeCode.boundedUnknown);
      expect(memory.limit?.kind, ResourceLimitKind.memoryBytes);

      final cancellation = MutableCancellationToken()..cancel();
      expect(
        explorer
            .explore(pda: pda, input: 'a', cancellation: cancellation)
            .outcome,
        VerificationOutcomeCode.cancelled,
      );

      expect(
        explorer
            .explore(
              pda: pda,
              input: 'a',
              freshness: GenerationFreshnessProbe(
                expectedGeneration: 1,
                currentGeneration: () => 2,
              ),
            )
            .outcome,
        VerificationOutcomeCode.staleRequest,
      );
    });

    test('does not merge stacks containing the old key separator', () {
      final initial = _state('q0', initial: true);
      final branch = _state('q1');
      final accepting = _state('q2', accepting: true);
      final pda = _pda(
        states: {initial, branch, accepting},
        transitions: {
          PDATransition(
            id: 'a-dead-atomic-symbol',
            fromState: initial,
            toState: branch,
            label: 'dead',
            inputSymbol: '',
            popSymbol: '',
            pushSymbol: 'A\u0001B',
            pushSymbols: const ['A\u0001B'],
            isLambdaInput: true,
            isLambdaPop: true,
          ),
          PDATransition(
            id: 'b-live-two-symbols',
            fromState: initial,
            toState: branch,
            label: 'live',
            inputSymbol: '',
            popSymbol: '',
            pushSymbol: 'BA',
            pushSymbols: const ['B', 'A'],
            isLambdaInput: true,
            isLambdaPop: true,
          ),
          PDATransition(
            id: 'finish',
            fromState: branch,
            toState: accepting,
            label: 'finish',
            inputSymbol: '',
            popSymbol: 'B',
            pushSymbol: '',
            pushSymbols: const [],
            isLambdaInput: true,
            isLambdaPush: true,
          ),
        },
        initial: initial,
        accepting: {accepting},
        alphabet: const {},
        stackAlphabet: const {'bottom', 'A\u0001B', 'A', 'B'},
      );

      expect(
        const PdaExhaustiveExplorer().explore(pda: pda, input: '').outcome,
        VerificationOutcomeCode.accepted,
      );
      final canonical = PDASimulator.simulateNPDA(pda, '');
      expect(canonical.isSuccess, isTrue, reason: canonical.error);
      expect(canonical.data!.accepted, isTrue);
    });
  });

  group('PDA family certification', () {
    test('fixture generation is deterministic and replayable', () {
      final left = generatePdaHardEdgeCase(seed: 337).value;
      final right = generatePdaHardEdgeCase(seed: 337).value;

      expect(canonicalJsonEncode(left.toJson()),
          canonicalJsonEncode(right.toJson()));
      expect(
        PdaHardEdgeFixture.fromJson(left.toJson()).toJson(),
        left.toJson(),
      );
    });

    test('executes every production algorithm in the matrix', () async {
      final report = await const PdaCertificationRunner().run(seed: 337);

      expect(
        pdaAlgorithmMatrix.map((algorithm) => algorithm.id),
        containsAll(const {
          'transition-validation',
          'pda-analysis',
          'bounded-string-generation',
          'trace-stack-reconstruction',
          'metamorphic-invariance',
          'compound-cfg-pda-cfg',
          'compound-pda-cfg-pda',
          'bounded-language-comparison',
        }),
      );
      expect(
        pdaCertificationProperties,
        containsAll(const {
          'validation-determinism-analysis',
          'trace-reconstruction',
          'invalid-model',
          'metamorphic-renaming-order',
          'compound-conversions',
          'bounded-language-evidence',
          'unicode-prefix-stack-symbols',
          'shortest-bfs-witness',
        }),
      );
      expect(
        report.coveredAlgorithmIds,
        pdaAlgorithmMatrix.map((algorithm) => algorithm.id).toSet(),
      );
      for (final descriptor in pdaHardEdgeCaseDescriptors) {
        final check = report.checks.singleWhere(
          (candidate) => candidate.id == descriptor.property,
        );
        expect(
          check.algorithmIds,
          contains(descriptor.algorithm),
          reason: '${descriptor.algorithm}/${descriptor.property}',
        );
      }
      expect(
        report.checks.where(
          (check) => check.status != PdaCertificationStatus.passed,
        ),
        isEmpty,
        reason: report.toJson().toString(),
      );
    });

    test('exposes granular generated-case and mutation adapters', () async {
      final descriptor = _catalogCase(
        algorithm: 'simulation-sync',
        property: 'oracle-parity',
      );
      const executor = PdaHardEdgePropertyExecutor();
      final fixture = await executor.materialize(descriptor, null, 337);

      expect(
        await executor.execute(descriptor, fixture),
        HardEdgeExecutionOutcome.pass,
      );
      expect(
        pdaHardEdgeCaseDescriptors
            .map((item) => '${item.algorithm}/${item.property}')
            .toSet(),
        hasLength(pdaHardEdgeCaseDescriptors.length),
      );

      final mutation = HardEdgeMutation(
        id: 'pda-ignore-push',
        family: 'pda',
        property: 'mutation-checks',
        operatorId: 'ignore-push',
        fixture: 'test/fixtures/hard_edge/pda/ignore-push.json',
        sha256: '0' * 64,
        requiredTool: null,
      );
      expect(
        await const PdaHardEdgeMutationExecutor().execute(
          mutation,
          pdaMutationFixture(PdaOracleMutation.ignorePush).toJson(),
        ),
        HardEdgeMutationStatus.killed,
      );
      for (final operator in PdaOracleMutation.values.skip(1)) {
        final source = pdaMutationFixture(operator);
        final before = canonicalJsonEncode(source.toJson());
        final evidence = evaluatePdaProductionMutation(source, operator);

        expect(evidence.canonicalProduction, evidence.originalOracle);
        expect(evidence.mutantProduction, isNot(evidence.originalOracle));
        expect(evidence.killed, isTrue);
        expect(canonicalJsonEncode(source.toJson()), before);
      }
      final mutationCheck = await const PdaCertificationRunner().runProperty(
        property: 'mutation-checks',
        fixture: materializePdaPropertyFixture(
          property: 'mutation-checks',
          seed: 337,
        ),
      );
      expect(mutationCheck.message, contains('threshold=4'));
      expect(mutationCheck.message, contains('survivors='));
      expect(mutationCheck.status, PdaCertificationStatus.passed);

      final unicodeCase = _catalogCase(
        algorithm: 'trace-stack-reconstruction',
        property: 'unicode-prefix-stack-symbols',
      );
      final unicodeFixture = PdaHardEdgeFixture.fromJson(
        await executor.materialize(unicodeCase, null, 337),
      );
      expect(unicodeFixture.property, 'unicode-prefix-stack-symbols');
      expect(unicodeFixture.pda.stackAlphabet, containsAll(['αβ', '🧪x']));

      final invalidCase = _catalogCase(
        algorithm: 'transition-validation',
        property: 'invalid-model',
      );
      final invalidFixture = PdaHardEdgeFixture.fromJson(
        await executor.materialize(invalidCase, null, 337),
      );
      expect(invalidFixture.pda.validate(), isNotEmpty);

      final cfgCase = _catalogCase(
        algorithm: 'cfg-pda-differential',
        property: 'cfg-conversions',
      );
      final cfgFixture = PdaHardEdgeFixture.fromJson(
        await executor.materialize(cfgCase, null, 337),
      );
      expect(cfgFixture.propertyPayload['llGrammar'], isA<Map>());

      final resourceCase = _catalogCase(
        algorithm: 'simulation-sync',
        property: 'resource-outcomes',
      );
      final resourceFixture = PdaHardEdgeFixture.fromJson(
        await executor.materialize(resourceCase, null, 337),
      );
      final alteredBudgets = resourceFixture.copyWith(
        propertyPayload: {
          ...resourceFixture.propertyPayload,
          'maxConfigurations': 100,
        },
      );
      expect(
        await executor.execute(resourceCase, alteredBudgets.toJson()),
        HardEdgeExecutionOutcome.violation,
      );

      final shortestCase = _catalogCase(
        algorithm: 'configuration-search',
        property: 'shortest-bfs-witness',
      );
      final shortestFixture = PdaHardEdgeFixture.fromJson(
        await executor.materialize(shortestCase, null, 337),
      );
      expect(shortestFixture.pda.pdaTransitions, hasLength(3));
      expect(
        await executor.execute(shortestCase, shortestFixture.toJson()),
        HardEdgeExecutionOutcome.pass,
      );
    });

    test('PDA shrink candidates are stable and structurally smaller', () {
      final fixture = pdaMutationFixture(PdaOracleMutation.ignorePush);
      final first = pdaFixtureShrinker
          .candidates(fixture)
          .map((candidate) => canonicalJsonEncode(candidate.toJson()))
          .toList();
      final second = pdaFixtureShrinker
          .candidates(fixture)
          .map((candidate) => canonicalJsonEncode(candidate.toJson()))
          .toList();

      expect(first, second);
      expect(first, isNotEmpty);
      expect(
        pdaFixtureShrinker.candidates(fixture).any(
              (candidate) =>
                  candidate.pda.transitions.length <
                  fixture.pda.transitions.length,
            ),
        isTrue,
      );
    });

    test('shrinks conversion grammars and nested mutation fixtures', () {
      final conversion = materializePdaPropertyFixture(
        property: 'compound-conversions',
        seed: 337,
      );
      final sourceProductions = ((conversion.propertyPayload['sourceGrammar']
              as Map)['productions'] as List)
          .length;
      final conversionCandidates =
          pdaFixtureShrinker.candidates(conversion).toList();
      expect(
        conversionCandidates.any((candidate) {
          final grammar = candidate.propertyPayload['sourceGrammar'];
          return grammar is Map &&
              (grammar['productions'] as List).length < sourceProductions;
        }),
        isTrue,
      );

      final mutations = materializePdaPropertyFixture(
        property: 'mutation-checks',
        seed: 337,
      );
      final nested = mutations.propertyPayload['mutationFixtures'] as Map;
      final originalTransitionCount = nested.values.fold<int>(
        0,
        (sum, fixture) =>
            sum +
            ((((fixture as Map)['pda'] as Map)['transitions'] as List).length),
      );
      final mutationCandidates =
          pdaFixtureShrinker.candidates(mutations).toList();
      expect(
        mutationCandidates.any((candidate) {
          final candidateNested =
              candidate.propertyPayload['mutationFixtures'] as Map;
          final count = candidateNested.values.fold<int>(
            0,
            (sum, fixture) =>
                sum +
                ((((fixture as Map)['pda'] as Map)['transitions'] as List)
                    .length),
          );
          return count < originalTransitionCount;
        }),
        isTrue,
      );
    });

    test('central shrink adapter decodes and re-encodes typed fixtures',
        () async {
      final fixture = pdaMutationFixture(PdaOracleMutation.ignorePush);
      final adapter = pdaHardEdgeShrinkAdapter(
        isApplicable: (candidate) => evaluatePdaProductionMutation(
          candidate,
          PdaOracleMutation.ignorePush,
        ).killed,
      );

      expect(await adapter.isValid(fixture.toJson()), isTrue);
      expect(await adapter.isApplicable(fixture.toJson()), isTrue);
      final candidates = adapter.shrinker.candidates(fixture.toJson()).toList();
      expect(candidates, isNotEmpty);
      expect(
        candidates.every((candidate) {
          final decoded = PdaHardEdgeFixture.fromJson(candidate);
          return decoded.property == fixture.property &&
              canonicalJsonEncode(decoded.propertyPayload) ==
                  canonicalJsonEncode(fixture.propertyPayload);
        }),
        isTrue,
      );
      expect(await adapter.isValid(const {'schema': 'wrong'}), isFalse);
    });

    test('preserves Unicode stack tokens that share prefixes in traces',
        () async {
      final fixture = pdaUnicodePrefixFixture();
      final oracle = const PdaExhaustiveExplorer().explore(
        pda: fixture.pda,
        input: fixture.input,
        mode: fixture.mode,
      );

      expect(oracle.outcome, VerificationOutcomeCode.accepted);
      expect(
        oracle.witness.first.after.stack,
        const ['bottom', '🧪x', '🧪', 'αβ', 'α'],
      );
      final production = PDASimulator.simulateNPDA(
        fixture.pda,
        fixture.input,
        mode: fixture.mode,
        stepByStep: true,
      );
      expect(production.isSuccess, isTrue);
      expect(
        production.data!.steps[1].stackTokens,
        const ['bottom', '🧪x', '🧪', 'αβ', 'α'],
      );
      expect(
        await const PdaCertificationRunner().runProperty(
          property: 'unicode-prefix-stack-symbols',
          fixture: fixture,
        ),
        isA<PdaCertificationCheck>().having(
          (check) => check.status,
          'status',
          PdaCertificationStatus.passed,
        ),
      );
    });

    test('keeps invalid, bounded, and compound evidence reportable', () async {
      const runner = PdaCertificationRunner();
      final invalid = await runner.runProperty(
        property: 'invalid-model',
        fixture: materializePdaPropertyFixture(
          property: 'invalid-model',
          seed: 337,
        ),
      );
      final compound = await runner.runProperty(
        property: 'compound-conversions',
        fixture: materializePdaPropertyFixture(
          property: 'compound-conversions',
          seed: 337,
        ),
      );
      final bounded = await runner.runProperty(
        property: 'bounded-language-evidence',
        fixture: materializePdaPropertyFixture(
          property: 'bounded-language-evidence',
          seed: 337,
        ),
      );

      expect(invalid.status, PdaCertificationStatus.passed);
      expect(invalid.message, contains('oracle=invalidInput'));
      expect(invalid.message, contains('duplicateRejected=true'));
      expect(invalid.message, contains('danglingRejected=true'));
      expect(invalid.message, contains('staleEndpointAccepted=true'));
      expect(invalid.message, contains('staleEndpointCanonicalized=true'));
      expect(compound.status, PdaCertificationStatus.passed);
      expect(compound.message, contains('limited=boundedUnknown'));
      expect(
          compound.message, contains('PDA to CFG production limit exceeded'));
      expect(compound.message, contains(PDAtoCFGConverter.cancellationError));
      expect(bounded.status, PdaCertificationStatus.passed);
      expect(bounded.message, contains('limitedDifferential=boundedUnknown'));
    });
  });
}

final class _FixedElapsedClock implements ElapsedClock {
  const _FixedElapsedClock(this.elapsed);

  @override
  final Duration elapsed;
}

HardEdgeCatalogCase _catalogCase({
  required String algorithm,
  required String property,
}) =>
    HardEdgeCatalogCase(
      id: 'pda-$algorithm-$property',
      family: 'pda',
      algorithm: algorithm,
      sourceKind: HardEdgeSourceKind.generated,
      seed: 337,
      property: property,
      provenance: const HardEdgeProvenance(
        origin: 'independent-generator',
        independentlyAuthored: true,
        generator: 'pda-fixture-v1',
        licenseBasis: 'LICENSE.txt',
      ),
      license: 'Apache-2.0',
      regressionIssue: 337,
      platforms: const ['all'],
      sha256: '0' * 64,
      generatorVersion: '1',
      oracleVersion: 'pda-exhaustive-v1',
      budget: const GenerationBudget(
        maxStates: 4,
        maxTransitions: 8,
        maxSymbols: 4,
        maxStackDepth: 8,
      ),
      fixture: 'test/fixtures/hard_edge/pda/generated.json',
      expectedOutcome: HardEdgeExpectedOutcome.pass,
      requiredTool: null,
    );

PDA _singleTransitionPda({
  required bool lambdaInput,
  required bool lambdaPop,
  required bool lambdaPush,
}) {
  final initial = _state('q0', initial: true);
  final accepting = _state('q1', accepting: true);
  final pushSymbols = lambdaPush ? const <String>[] : ['stack-token'];
  final transition = PDATransition(
    id: 'edge',
    fromState: initial,
    toState: accepting,
    label: 'edge',
    inputSymbol: lambdaInput ? '' : 'a',
    popSymbol: lambdaPop ? '' : 'bottom',
    pushSymbol: pushSymbols.join(),
    pushSymbols: pushSymbols,
    isLambdaInput: lambdaInput,
    isLambdaPop: lambdaPop,
    isLambdaPush: lambdaPush,
  );
  return _pda(
    states: {initial, accepting},
    transitions: {transition},
    initial: initial,
    accepting: {accepting},
    alphabet: {'a'},
    stackAlphabet: {'bottom', 'stack-token'},
  );
}

PDA _epsilonCyclePda() {
  final initial = _state('q0', initial: true);
  final cycle = PDATransition.epsilon(
    id: 'cycle',
    fromState: initial,
    toState: initial,
    controlPoint: Vector2(10, -10),
  );
  return _pda(
    states: {initial},
    transitions: {cycle},
    initial: initial,
    accepting: const {},
    alphabet: {'a'},
    stackAlphabet: {'bottom'},
    acceptanceMode: PDAAcceptanceMode.emptyStack,
  );
}

State _state(String id, {bool initial = false, bool accepting = false}) =>
    State(
      id: id,
      label: id,
      position: Vector2.zero(),
      isInitial: initial,
      isAccepting: accepting,
    );

PDA _pda({
  required Set<State> states,
  required Set<PDATransition> transitions,
  required State initial,
  required Set<State> accepting,
  required Set<String> alphabet,
  required Set<String> stackAlphabet,
  PDAAcceptanceMode acceptanceMode = PDAAcceptanceMode.finalState,
}) {
  final timestamp = DateTime.utc(2026, 8, 26);
  return PDA(
    id: 'hard-edge-pda',
    name: 'Hard-edge PDA',
    states: states,
    transitions: transitions,
    alphabet: alphabet,
    initialState: initial,
    acceptingStates: accepting,
    created: timestamp,
    modified: timestamp,
    bounds: const math.Rectangle(0, 0, 400, 300),
    stackAlphabet: stackAlphabet,
    initialStackSymbol: 'bottom',
    acceptanceMode: acceptanceMode,
  );
}
