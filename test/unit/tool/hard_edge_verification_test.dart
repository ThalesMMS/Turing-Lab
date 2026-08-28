import 'package:test/test.dart';
import 'package:turing_lab/core/batch_execution/batch_execution_models.dart';

import '../../../tool/hard_edge/oracles.dart';
import '../../../tool/hard_edge/outcomes.dart';
import '../../../tool/hard_edge/resources.dart';
import '../../../tool/hard_edge/verification.dart';

void main() {
  group('shared outcomes', () {
    test('adapts every batch outcome without coercion', () {
      final mapped = <VerificationOutcomeCode>{};
      for (final batch in BatchOutcomeCode.values) {
        final outcome = VerificationOutcomeCode.fromBatch(batch);
        expect(outcome.toBatch(), batch);
        mapped.add(outcome);
      }
      expect(mapped, hasLength(BatchOutcomeCode.values.length));
      expect(VerificationOutcomeCode.rejected.isDefinitive, isTrue);
      expect(VerificationOutcomeCode.boundedUnknown.isInconclusive, isTrue);
      expect(VerificationOutcomeCode.timeout.isInconclusive, isTrue);
      expect(VerificationOutcomeCode.cancelled.isInconclusive, isTrue);
      expect(VerificationOutcomeCode.staleRequest.isInconclusive, isTrue);
    });
  });

  group('typed oracle comparison', () {
    test('small exhaustive oracle preserves tokens and exposes its cap', () {
      final complete = evaluateTokenWords<String>(
        alphabet: const ['ab', 'c'],
        maximumWordLength: 1,
        maximumCases: 3,
        evaluate: (word) => word.join('|'),
      );
      expect(
          complete,
          isA<
              OracleDefinitive<List<ExhaustiveOracleSample<String>>,
                  ExhaustiveOracleEvidence>>());
      final values = (complete as OracleDefinitive<
              List<ExhaustiveOracleSample<String>>, ExhaustiveOracleEvidence>)
          .value;
      expect(values.map((sample) => sample.word), [
        const [],
        const ['ab'],
        const ['c']
      ]);

      final bounded = evaluateTokenWords<bool>(
        alphabet: const ['a', 'b'],
        maximumWordLength: 3,
        maximumCases: 4,
        evaluate: (word) => word.length.isEven,
      );
      expect(
          bounded,
          isA<
              OracleBoundedUnknown<List<ExhaustiveOracleSample<bool>>,
                  ExhaustiveOracleEvidence>>());
      expect(
        (bounded as OracleBoundedUnknown<List<ExhaustiveOracleSample<bool>>,
                ExhaustiveOracleEvidence>)
            .limit
            .partialEvidence,
        isA<List<ExhaustiveOracleSample<bool>>>(),
      );
    });

    const evidence = _Evidence('bounded exploration');
    const limit = ResourceLimitEvidence(
      kind: ResourceLimitKind.frontier,
      observed: 11,
      maximum: 10,
      unit: 'items',
      partialEvidence: ['q0', 'q1'],
    );

    test('reports a mismatch only for two definitive answers', () {
      const left = OracleDefinitive<bool, _Evidence>(
        value: true,
        evidence: _Evidence('left'),
      );
      const right = OracleDefinitive<bool, _Evidence>(
        value: false,
        evidence: _Evidence('right'),
      );
      expect(
        compareOracleResults(left, right, equivalent: (a, b) => a == b),
        isA<DifferentialMismatch<bool, _Evidence>>(),
      );
    });

    test('keeps bounded and not-applicable results inconclusive', () {
      const definitive = OracleDefinitive<bool, _Evidence>(
        value: false,
        evidence: _Evidence('complete'),
      );
      const bounded = OracleBoundedUnknown<bool, _Evidence>(
        limit: limit,
        evidence: evidence,
      );
      const unavailable = OracleNotApplicable<bool, _Evidence>(
        reason: OracleInapplicability.unsupportedDomain,
        evidence: _Evidence('not a CFG'),
      );

      final boundedComparison = compareOracleResults(
        bounded,
        definitive,
        equivalent: (a, b) => a == b,
      );
      expect(
          boundedComparison, isA<DifferentialInconclusive<bool, _Evidence>>());
      expect(
        (boundedComparison as DifferentialInconclusive).reason,
        DifferentialInconclusiveReason.leftBounded,
      );
      expect(
        compareOracleResults(
          definitive,
          unavailable,
          equivalent: (a, b) => a == b,
        ),
        isA<DifferentialInconclusive<bool, _Evidence>>(),
      );
    });
  });

  group('semantic and metamorphic verification', () {
    final canonicalizer = SemanticCanonicalizer<_Machine>(
      recordsOf: (machine) => machine.transitions.map(
        (transition) => SemanticRecord(
          kind: 'transition',
          tokens: transition.tokens,
          attributes: {
            'fromRole': transition.fromRole,
            'toRole': transition.toRole,
          },
        ),
      ),
    );

    test('ignores IDs and insertion order but preserves token boundaries', () {
      const first = _Machine([
        _Transition('t0', 'initial', 'final', ['ab', 'c']),
        _Transition('t1', 'final', 'final', ['x']),
      ]);
      const renamedAndReordered = _Machine([
        _Transition('other-9', 'final', 'final', ['x']),
        _Transition('other-2', 'initial', 'final', ['ab', 'c']),
      ]);
      const retokenized = _Machine([
        _Transition('t0', 'initial', 'final', ['a', 'bc']),
        _Transition('t1', 'final', 'final', ['x']),
      ]);

      expect(canonicalizer.equivalent(first, renamedAndReordered), isTrue);
      expect(canonicalizer.equivalent(first, retokenized), isFalse);
    });

    test('detects an injected semantic defect in a renaming property', () {
      const source = _Machine([
        _Transition('t0', 'initial', 'final', ['a']),
      ]);
      final brokenRename = MetamorphicProperty<_Machine>.semanticPreservation(
        name: 'state renaming',
        canonicalizer: canonicalizer,
        transform: (machine) => _Machine([
          for (final transition in machine.transitions)
            _Transition(
              'renamed-${transition.id}',
              transition.fromRole,
              transition.toRole,
              // Injected defect: renaming also changes a token.
              [...transition.tokens, 'corrupt'],
            ),
        ]),
      );

      expect(
        brokenRename.verify(source).observation,
        isA<PropertyViolated>(),
      );
    });

    test('provides a reusable idempotence property', () {
      final property = MetamorphicProperty<List<int>>.idempotent(
        name: 'sort',
        transform: (values) => [...values]..sort(),
        equivalent: _sameInts,
      );
      expect(property.verify([3, 1, 2]).observation, isA<PropertySatisfied>());
    });
  });

  group('trace replay', () {
    final verifier = TraceReplayVerifier<int, int, bool>(
      apply: (state, action) => action < 0
          ? const ReplayRejected('negative actions are invalid')
          : ReplayApplied(state + action),
      statesEquivalent: (a, b) => a == b,
      resultFromState: (state) => state.isEven,
      resultsEquivalent: (a, b) => a == b,
    );

    test('validates every transition and the final result', () {
      expect(
        verifier.verify(
          initialState: 0,
          steps: const [
            RecordedTraceStep(before: 0, action: 1, after: 1),
            RecordedTraceStep(before: 1, action: 3, after: 4),
          ],
          reportedResult: true,
        ),
        isA<TraceReplayPassed<int, bool>>(),
      );
    });

    test('detects injected corrupt steps and final answers', () {
      final corruptStep = verifier.verify(
        initialState: 0,
        steps: const [RecordedTraceStep(before: 0, action: 1, after: 2)],
        reportedResult: true,
      );
      expect(corruptStep, isA<TraceReplayFailed<int, bool>>());
      expect(
        (corruptStep as TraceReplayFailed).kind,
        TraceReplayFailureKind.afterMismatch,
      );

      final corruptResult = verifier.verify(
        initialState: 0,
        steps: const [RecordedTraceStep(before: 0, action: 1, after: 1)],
        reportedResult: true,
      );
      expect(
        (corruptResult as TraceReplayFailed).kind,
        TraceReplayFailureKind.finalResultMismatch,
      );
    });
  });

  group('resource assertions', () {
    test('reports each count limit with partial evidence', () {
      for (final testCase
          in <(ResourceBudget, ResourceSnapshot, ResourceLimitKind)>[
        (
          ResourceBudget(maxSteps: 2),
          const ResourceSnapshot(steps: 3, partialEvidence: 'trace'),
          ResourceLimitKind.steps,
        ),
        (
          ResourceBudget(maxConfigurations: 2),
          const ResourceSnapshot(configurations: 3),
          ResourceLimitKind.configurations,
        ),
        (
          ResourceBudget(maxFrontier: 2),
          const ResourceSnapshot(frontier: 3),
          ResourceLimitKind.frontier,
        ),
        (
          ResourceBudget(maxMemoryBytes: 2),
          const ResourceSnapshot(memoryBytes: 3),
          ResourceLimitKind.memoryBytes,
        ),
      ]) {
        final result = ResourceAssertions(
          budget: testCase.$1,
          clock: _FakeClock(),
        ).evaluate(testCase.$2);
        expect(result, isA<ResourceLimitReached>());
        expect((result as ResourceLimitReached).evidence.kind, testCase.$3);
      }
    });

    test('uses injected clock, cancellation, and request freshness', () {
      final clock = _FakeClock()..advance(const Duration(milliseconds: 11));
      final timeout = ResourceAssertions(
        budget: ResourceBudget(timeout: const Duration(milliseconds: 10)),
        clock: clock,
      ).evaluate(const ResourceSnapshot());
      expect((timeout as ResourceLimitReached).evidence.kind,
          ResourceLimitKind.timeout);

      final cancellation = MutableCancellationToken()..cancel();
      expect(
        ResourceAssertions(
          budget: ResourceBudget(),
          clock: _FakeClock(),
          cancellation: cancellation,
        ).evaluate(const ResourceSnapshot()),
        isA<ResourceCancelled>(),
      );

      var generation = 2;
      final freshness = GenerationFreshnessProbe(
        expectedGeneration: 1,
        currentGeneration: () => generation,
      );
      expect(
        ResourceAssertions(
          budget: ResourceBudget(),
          clock: _FakeClock(),
          freshness: freshness,
        ).evaluate(const ResourceSnapshot()),
        isA<ResourceStaleRequest>(),
      );
      generation = 1;
      expect(freshness.isStale, isFalse);
    });

    test('detects an injected event-loop stall without wall-clock sleeps',
        () async {
      final clock = _FakeClock();
      final assertions = ResourceAssertions(
        budget: ResourceBudget(
          maxEventLoopDelay: const Duration(milliseconds: 5),
        ),
        clock: clock,
      );
      final result = await assertions.checkEventLoopResponsiveness(
        yieldToEventLoop: () async {
          // Injected stall measured by the fake clock.
          clock.advance(const Duration(milliseconds: 6));
        },
      );
      expect(result, isA<ResourceLimitReached>());
      expect(
        (result as ResourceLimitReached).evidence.kind,
        ResourceLimitKind.eventLoopDelay,
      );
    });
  });
}

final class _Evidence {
  const _Evidence(this.description);

  final String description;
}

final class _Machine {
  const _Machine(this.transitions);

  final List<_Transition> transitions;
}

final class _Transition {
  const _Transition(
    this.id,
    this.fromRole,
    this.toRole,
    this.tokens,
  );

  final String id;
  final String fromRole;
  final String toRole;
  final List<String> tokens;
}

bool _sameInts(List<int> left, List<int> right) {
  if (left.length != right.length) return false;
  for (var index = 0; index < left.length; index++) {
    if (left[index] != right[index]) return false;
  }
  return true;
}

final class _FakeClock implements ElapsedClock {
  Duration _elapsed = Duration.zero;

  @override
  Duration get elapsed => _elapsed;

  void advance(Duration duration) => _elapsed += duration;
}
