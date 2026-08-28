import 'dart:convert';
import 'dart:io';
import 'dart:math' as math;

import 'package:turing_lab/core/l_systems/l_systems.dart';
import 'package:turing_lab/core/pumping_lemma/pumping_lemma.dart';
import 'package:turing_lab/core/transducers/transducers.dart';

import '../models.dart';

const formalSystemsFamilyId = 'formal-systems';
const formalSystemsFixtureSchema =
    'turing-lab.hard-edge.formal-systems-property.v1';
const formalSystemsGeneratorVersion = 'formal-systems-hard-edge-v1';
const formalSystemsOracleVersion = 'formal-systems-independent-v1';
const formalSystemsSchemaVersion = 1;

enum FormalSystemsCertificationOutcome {
  verified,
  invalid,
  cancelled,
  boundedUnknown,
  inconclusive,
  different,
}

enum FormalSystemsCertificationStatus { passed, failed }

final class FormalSystemsCertificationRecord {
  const FormalSystemsCertificationRecord({
    required this.id,
    required this.algorithm,
    required this.property,
    required this.seed,
    required this.expected,
    required this.actual,
    required this.evidence,
  });

  final String id;
  final String algorithm;
  final String property;
  final int seed;
  final FormalSystemsCertificationOutcome expected;
  final FormalSystemsCertificationOutcome actual;
  final Map<String, Object?> evidence;

  bool get passed => expected == actual;

  Map<String, Object?> toJson() => {
        'actual': actual.name,
        'algorithm': algorithm,
        'evidence': evidence,
        'expected': expected.name,
        'id': id,
        'passed': passed,
        'property': property,
        'provenance': {
          'independentlyAuthored': true,
          'issue': 339,
          'jflapVersion': '7.1',
          'license': 'Apache-2.0',
        },
        'seed': seed,
      };
}

final class FormalSystemsCertificationReport {
  FormalSystemsCertificationReport({
    required Iterable<FormalSystemsCertificationRecord> records,
    required this.seedStart,
    required this.seedCount,
  }) : records = List<FormalSystemsCertificationRecord>.unmodifiable(records);

  final List<FormalSystemsCertificationRecord> records;
  final int seedStart;
  final int seedCount;

  FormalSystemsCertificationStatus get status => records.every(
        (record) => record.passed,
      )
          ? FormalSystemsCertificationStatus.passed
          : FormalSystemsCertificationStatus.failed;

  bool get passed => status == FormalSystemsCertificationStatus.passed;

  Map<String, Object?> toJson() {
    final algorithms = <String, int>{};
    final properties = <String, int>{};
    for (final record in records) {
      algorithms.update(
        record.algorithm,
        (value) => value + 1,
        ifAbsent: () => 1,
      );
      properties.update(
        record.property,
        (value) => value + 1,
        ifAbsent: () => 1,
      );
    }
    return {
      'coverage': {
        'algorithms': _sortedCounts(algorithms),
        'properties': _sortedCounts(properties),
        'seeds': [
          for (var seed = seedStart; seed < seedStart + seedCount; seed++) seed,
        ],
      },
      'generatorVersion': formalSystemsGeneratorVersion,
      'oracleVersion': formalSystemsOracleVersion,
      'records': records.map((record) => record.toJson()).toList(),
      'remotelyVerified': false,
      'schemaVersion': formalSystemsSchemaVersion,
      'status': status.name,
    };
  }
}

final class FormalSystemsCertificationOptions {
  const FormalSystemsCertificationOptions({
    this.seedStart = 339,
    this.seedCount = 4,
    this.caseFilter,
  });

  final int seedStart;
  final int seedCount;
  final String? caseFilter;

  void validate() {
    if (seedStart < 0 || seedStart > 0xffffffff) {
      throw RangeError.range(seedStart, 0, 0xffffffff, 'seedStart');
    }
    if (seedCount < 1 || seedCount > 64) {
      throw RangeError.range(seedCount, 1, 64, 'seedCount');
    }
    if (seedStart + seedCount - 1 > 0xffffffff) {
      throw const FormatException('Seed range exceeds uint32.');
    }
  }
}

abstract final class FormalSystemsCertification {
  static Future<FormalSystemsCertificationReport> run(
    FormalSystemsCertificationOptions options,
  ) async {
    options.validate();
    final records = <FormalSystemsCertificationRecord>[];
    for (var offset = 0; offset < options.seedCount; offset++) {
      records.addAll(await _runSeed(options.seedStart + offset));
    }
    final filtered = options.caseFilter == null
        ? records
        : records.where((record) => record.id == options.caseFilter).toList();
    if (filtered.isEmpty) {
      throw const FormatException(
        'No formal-systems certification case matched.',
      );
    }
    return FormalSystemsCertificationReport(
      records: filtered,
      seedStart: options.seedStart,
      seedCount: options.seedCount,
    );
  }

  static Future<List<FormalSystemsCertificationRecord>> _runSeed(
    int seed,
  ) async {
    final records = <FormalSystemsCertificationRecord>[];

    void add({
      required String id,
      required String algorithm,
      required String property,
      FormalSystemsCertificationOutcome expected =
          FormalSystemsCertificationOutcome.verified,
      required FormalSystemsCertificationOutcome actual,
      Map<String, Object?> evidence = const {},
    }) {
      records.add(FormalSystemsCertificationRecord(
        id: id,
        algorithm: algorithm,
        property: property,
        seed: seed,
        expected: expected,
        actual: actual,
        evidence: evidence,
      ));
    }

    final mealy = formalSystemsMealyFixture(seed);
    final moore = formalSystemsMooreFixture(seed);
    final mealySimulator = DeterministicTransducerSimulator.mealy(mealy);
    final mooreSimulator = DeterministicTransducerSimulator.moore(moore);
    final analysis = TransducerAnalyzer.analyze(mealy);
    final invalidAnalysis = TransducerAnalyzer.analyze(
      mealy.copyWith(
        transitions: [
          ...mealy.transitions,
          const MealyTransition(
            id: TransducerTransitionId('duplicate-input'),
            from: TransducerStateId('q0'),
            to: TransducerStateId('q0'),
            input: TransducerInputSymbol('a'),
            output: TransducerOutputWord.empty,
          ),
        ],
      ),
    );
    add(
      id: 'transducer-analysis',
      algorithm: 'transducer-analyzer-transition-index',
      property: 'transducer.validation-determinism-completeness',
      actual: analysis.isStructurallyValid &&
              analysis.isDeterministic &&
              analysis.isComplete &&
              !invalidAnalysis.isStructurallyValid &&
              invalidAnalysis.diagnostics.any(
                (diagnostic) =>
                    diagnostic.code ==
                    TransducerDiagnosticCode.nondeterministicTransition,
              )
          ? FormalSystemsCertificationOutcome.verified
          : FormalSystemsCertificationOutcome.invalid,
      evidence: {
        'complete': analysis.isComplete,
        'invalidCodes': invalidAnalysis.diagnostics
            .map((diagnostic) => diagnostic.code.name)
            .toList(),
      },
    );

    final tokenized = TransducerInputTokenizer.tokenize(
      'aa🙂a',
      mealy.inputAlphabet,
    );
    final tokenizationFailure = TransducerInputTokenizer.tokenize(
      'aa?',
      mealy.inputAlphabet,
    );
    add(
      id: 'transducer-tokenizer',
      algorithm: 'transducer-input-tokenizer',
      property: 'transducer.maximal-munch-unicode',
      actual: tokenized is TransducerTokenizationSuccess &&
              _listEquals(tokenized.word.values, const ['aa', '🙂', 'a']) &&
              tokenizationFailure is TransducerTokenizationFailure &&
              tokenizationFailure.offset == 2
          ? FormalSystemsCertificationOutcome.verified
          : FormalSystemsCertificationOutcome.invalid,
      evidence: {
        'tokens': tokenized is TransducerTokenizationSuccess
            ? tokenized.word.values
            : const [],
      },
    );

    final transducerInput = TransducerInputWord.fromValues(['aa', '🙂', 'a']);
    final mealyExpected = independentTransducerRun(mealy, transducerInput);
    final mealyActual = mealySimulator.run(transducerInput);
    add(
      id: 'transducer-mealy-oracle',
      algorithm: 'deterministic-mealy-simulator',
      property: 'transducer.independent-output-trace',
      actual: mealyExpected.completed &&
              mealyActual is TransducerSuccess &&
              _listEquals(mealyActual.output.values, mealyExpected.output) &&
              _traceReplays(mealy, transducerInput, mealyActual)
          ? FormalSystemsCertificationOutcome.verified
          : FormalSystemsCertificationOutcome.different,
      evidence: {
        'actual': mealyActual.output.values,
        'expected': mealyExpected.output,
      },
    );

    final mooreInput = TransducerInputWord.fromValues(['a', 'a']);
    final mooreExpected = independentTransducerRun(moore, mooreInput);
    final mooreActual = mooreSimulator.run(mooreInput);
    add(
      id: 'transducer-moore-oracle',
      algorithm: 'deterministic-moore-simulator',
      property: 'transducer.initial-output-and-prefixes',
      actual: mooreExpected.completed &&
              mooreActual is TransducerSuccess &&
              _listEquals(mooreActual.output.values, mooreExpected.output) &&
              _listEquals(
                  mooreActual.output.values, const ['zero', 'one', 'zero'])
          ? FormalSystemsCertificationOutcome.verified
          : FormalSystemsCertificationOutcome.different,
      evidence: {'output': mooreActual.output.values},
    );

    final longInput = TransducerInputWord.fromValues(List.filled(8, 'a'));
    final synchronous = mealySimulator.run(
      longInput,
      options: const TransducerSimulationOptions(maxRetainedTraceSteps: 2),
    );
    final asynchronous = await mealySimulator.runAsync(
      longInput,
      options: const TransducerSimulationOptions(maxRetainedTraceSteps: 2),
      yieldEvery: 1,
    );
    final partialSimulator = DeterministicTransducerSimulator.mealy(
      mealy.copyWith(
        transitions: mealy.transitions
            .where((transition) => transition.id.value != 'q0-a'),
      ),
    );
    final partialInput = TransducerInputWord.fromValues(const ['a']);
    final boundedInput = TransducerInputWord.fromValues(const ['a']);
    final invalidInputWord = TransducerInputWord.fromValues(const ['?']);
    final cancelledInput = TransducerInputWord.fromValues(const ['a']);
    final invalidSimulator = DeterministicTransducerSimulator.mealy(
      mealy.copyWith(
        states: mealy.states.map((state) => state.copyWith(isInitial: false)),
      ),
    );
    final parityOutcomes =
        <String, (TransducerExecutionOutcome, TransducerExecutionOutcome)>{
      'success': (synchronous, asynchronous),
      'incomplete': (
        partialSimulator.run(partialInput),
        await partialSimulator.runAsync(partialInput, yieldEvery: 1),
      ),
      'bounded': (
        mealySimulator.run(
          boundedInput,
          options: const TransducerSimulationOptions(maxSteps: 0),
        ),
        await mealySimulator.runAsync(
          boundedInput,
          options: const TransducerSimulationOptions(maxSteps: 0),
          yieldEvery: 1,
        ),
      ),
      'invalidInput': (
        mealySimulator.run(invalidInputWord),
        await mealySimulator.runAsync(invalidInputWord, yieldEvery: 1),
      ),
      'invalidMachine': (
        invalidSimulator.run(partialInput),
        await invalidSimulator.runAsync(partialInput, yieldEvery: 1),
      ),
      'cancelled': (
        mealySimulator.run(
          cancelledInput,
          options: TransducerSimulationOptions(
            cancellationToken: TransducerCancellationToken()..cancel(),
          ),
        ),
        await mealySimulator.runAsync(
          cancelledInput,
          options: TransducerSimulationOptions(
            cancellationToken: TransducerCancellationToken()..cancel(),
          ),
          yieldEvery: 1,
        ),
      ),
    };
    add(
      id: 'transducer-trace-async',
      algorithm: 'transducer-sync-async-trace',
      property: 'transducer.trace-retention-equivalence',
      actual: parityOutcomes.values.every(
                (pair) => _executionOutcomesEqual(pair.$1, pair.$2),
              ) &&
              synchronous.traceWasTruncated &&
              asynchronous.traceWasTruncated &&
              synchronous.trace.length == 2 &&
              asynchronous.trace.length == 2 &&
              _executionTracesEqual(synchronous, asynchronous) &&
              synchronous.trace.every(
                (step) => identical(step.remainingInput.source, longInput),
              ) &&
              asynchronous.trace.every(
                (step) => identical(step.remainingInput.source, longInput),
              )
          ? FormalSystemsCertificationOutcome.verified
          : FormalSystemsCertificationOutcome.different,
      evidence: {
        'processed': synchronous.processedInputCount,
        'retainedAsync': asynchronous.trace.length,
        'retainedSync': synchronous.trace.length,
        'typedOutcomes': parityOutcomes.values
            .map((pair) => pair.$1.runtimeType.toString())
            .toSet()
            .toList()
          ..sort(),
      },
    );

    final batch = TransducerBatchRunner(mealySimulator).run([
      TransducerInputWord.empty,
      TransducerInputWord.fromValues(['a']),
      TransducerInputWord.fromValues(['aa']),
    ]);
    add(
      id: 'transducer-batch',
      algorithm: 'transducer-batch-runner',
      property: 'transducer.batch-output-order',
      actual: batch.items.length == 3 &&
              batch.items[0].input.values.isEmpty &&
              _listEquals(batch.items[1].input.values, const ['a']) &&
              _listEquals(batch.items[2].input.values, const ['aa']) &&
              batch.items.every((item) => item.outcome.trace.isEmpty)
          ? FormalSystemsCertificationOutcome.verified
          : FormalSystemsCertificationOutcome.different,
      evidence: {
        'outputs': batch.items.map((item) => item.output.values).toList(),
      },
    );

    final renamed = _renamedMealy(mealy);
    final exact = TransducerEquivalenceComparator.compare(
      mealySimulator,
      DeterministicTransducerSimulator.mealy(renamed),
      semantics: const ExactTransducerComparison(),
    );
    add(
      id: 'transducer-equivalence-exact',
      algorithm: 'transducer-exact-equivalence',
      property: 'transducer.renaming-order-invariance',
      actual: exact.kind == TransducerComparisonKind.equivalent &&
              exact.isExact &&
              exact.witness == null
          ? FormalSystemsCertificationOutcome.verified
          : FormalSystemsCertificationOutcome.different,
      evidence: {'exploredPairs': exact.exploredPairs},
    );

    final different = mealy.copyWith(
      transitions: mealy.transitions.map((transition) {
        if (transition.id.value != 'q0-a') return transition;
        return MealyTransition(
          id: transition.id,
          from: transition.from,
          to: transition.to,
          input: transition.input,
          output: TransducerOutputWord.fromValues(['long']),
        );
      }),
    );
    final witness = TransducerEquivalenceComparator.compare(
      mealySimulator,
      DeterministicTransducerSimulator.mealy(different),
      semantics: const ExactTransducerComparison(),
    );
    add(
      id: 'transducer-equivalence-witness',
      algorithm: 'transducer-exact-equivalence',
      property: 'transducer.shortest-distinguishing-input',
      expected: FormalSystemsCertificationOutcome.different,
      actual: witness.kind == TransducerComparisonKind.different &&
              _listEquals(witness.witness?.values ?? const [], const ['a'])
          ? FormalSystemsCertificationOutcome.different
          : FormalSystemsCertificationOutcome.inconclusive,
      evidence: {'witness': witness.witness?.values},
    );

    final boundedComparison = TransducerEquivalenceComparator.compare(
      mealySimulator,
      mealySimulator,
      semantics: const BoundedTransducerComparison(maxInputLength: 2),
    );
    add(
      id: 'transducer-equivalence-bounded',
      algorithm: 'transducer-bounded-equivalence',
      property: 'transducer.finite-evidence-not-proof',
      expected: FormalSystemsCertificationOutcome.inconclusive,
      actual: boundedComparison.kind == TransducerComparisonKind.inconclusive &&
              !boundedComparison.isExact
          ? FormalSystemsCertificationOutcome.inconclusive
          : FormalSystemsCertificationOutcome.different,
      evidence: {
        'bound': boundedComparison.bound,
        'explored': boundedComparison.exploredPairs,
      },
    );

    final decoded = MealyMachine.fromJson(mealy.toJson());
    final graph = TransducerGraphMapping.fromMachine(mealy);
    add(
      id: 'transducer-model-graph-serialization',
      algorithm: 'transducer-model-graph-mapping',
      property: 'transducer.serialization-token-boundaries',
      actual: canonicalJsonEncode(decoded.toJson()) ==
                  canonicalJsonEncode(mealy.toJson()) &&
              graph.nodes.length == mealy.states.length &&
              graph.edges.length == mealy.transitions.length &&
              graph.edges.whereType<MealyGraphEdge>().every(
                    (edge) => edge.output.values.isNotEmpty,
                  )
          ? FormalSystemsCertificationOutcome.verified
          : FormalSystemsCertificationOutcome.different,
      evidence: {
        'edges': graph.edges.length,
        'nodes': graph.nodes.length,
      },
    );

    final partial = DeterministicTransducerSimulator.mealy(
      mealy.copyWith(
        transitions: mealy.transitions
            .where((transition) => transition.id.value != 'q0-a'),
      ),
    ).run(TransducerInputWord.fromValues(['a']));
    final cancelledToken = TransducerCancellationToken()..cancel();
    final cancelled = mealySimulator.run(
      TransducerInputWord.fromValues(['a']),
      options: TransducerSimulationOptions(cancellationToken: cancelledToken),
    );
    final bounded = mealySimulator.run(
      TransducerInputWord.fromValues(['a']),
      options: const TransducerSimulationOptions(maxSteps: 0),
    );
    final invalidInput = mealySimulator.run(
      TransducerInputWord.fromValues(['?']),
    );
    add(
      id: 'transducer-resource-outcomes',
      algorithm: 'deterministic-transducer-simulator',
      property: 'transducer.typed-incomplete-cancel-bound-invalid',
      actual: partial is TransducerIncomplete &&
              cancelled is TransducerCancelled &&
              bounded is TransducerBounded &&
              invalidInput is TransducerInvalidInput
          ? FormalSystemsCertificationOutcome.verified
          : FormalSystemsCertificationOutcome.invalid,
      evidence: {
        'bounded': bounded.runtimeType.toString(),
        'cancelled': cancelled.runtimeType.toString(),
        'incomplete': partial.runtimeType.toString(),
        'invalid': invalidInput.runtimeType.toString(),
      },
    );

    final system = formalSystemsLSystemFixture(seed);
    final expectedGeneration = independentLSystemExpand(system, 3);
    final expanded = const LSystemExpander().expand(system, generations: 3);
    add(
      id: 'lsystem-parallel-oracle',
      algorithm: 'l-system-expander',
      property: 'lsystem.parallel-independent-oracle',
      actual: expanded is LSystemExpansionCompleted &&
              _listEquals(
                expanded.finalGeneration.word.symbols,
                expectedGeneration,
              ) &&
              _provenanceReplays(system, expanded.retainedGenerations)
          ? FormalSystemsCertificationOutcome.verified
          : FormalSystemsCertificationOutcome.different,
      evidence: {
        'word': expanded.finalGeneration.word.symbols,
        'length': expanded.finalGeneration.word.length,
      },
    );

    final zero = const LSystemExpander().expand(system, generations: 0);
    final identityEpsilon = const LSystemExpander().expand(
      _identityEpsilonLSystem(seed),
      generations: 1,
    );
    add(
      id: 'lsystem-zero-identity-epsilon',
      algorithm: 'l-system-expander',
      property: 'lsystem.zero-identity-epsilon',
      actual: zero is LSystemExpansionCompleted &&
              zero.finalGeneration.index == 0 &&
              identityEpsilon is LSystemExpansionCompleted &&
              _listEquals(
                identityEpsilon.finalGeneration.word.symbols,
                const ['keep'],
              )
          ? FormalSystemsCertificationOutcome.verified
          : FormalSystemsCertificationOutcome.different,
      evidence: {'word': identityEpsilon.finalGeneration.word.symbols},
    );

    LSystemExpansionOutcome limited(LSystemExpansionLimits limits) =>
        const LSystemExpander().expand(system, generations: 3, limits: limits);
    final generationLimit = limited(
      const LSystemExpansionLimits(maximumGenerations: 2),
    );
    final symbolLimit = limited(
      const LSystemExpansionLimits(maximumSymbols: 2),
    );
    final memoryLimit = limited(
      const LSystemExpansionLimits(maximumEstimatedBytes: 16),
    );
    final timeLimit = limited(LSystemExpansionLimits(
      maximumElapsed: Duration.zero,
      elapsedProvider: () => const Duration(microseconds: 1),
    ));
    final cancellationToken = LSystemCancellationToken()..cancel();
    final expansionCancelled = limited(
      LSystemExpansionLimits(cancellationToken: cancellationToken),
    );
    add(
      id: 'lsystem-resource-outcomes',
      algorithm: 'l-system-growth-estimator',
      property: 'lsystem.typed-generation-symbol-memory-time-cancel',
      actual: _expansionBoundIs(
                generationLimit,
                LSystemExpansionBoundKind.generations,
              ) &&
              _expansionBoundIs(
                  symbolLimit, LSystemExpansionBoundKind.symbols) &&
              _expansionBoundIs(
                memoryLimit,
                LSystemExpansionBoundKind.estimatedMemory,
              ) &&
              _expansionBoundIs(
                timeLimit,
                LSystemExpansionBoundKind.elapsedTime,
              ) &&
              expansionCancelled is LSystemExpansionCancelled
          ? FormalSystemsCertificationOutcome.verified
          : FormalSystemsCertificationOutcome.invalid,
      evidence: {
        'cancelled': expansionCancelled.runtimeType.toString(),
        'generation': _expansionBoundName(generationLimit),
        'memory': _expansionBoundName(memoryLimit),
        'symbols': _expansionBoundName(symbolLimit),
        'time': _expansionBoundName(timeLimit),
      },
    );

    final asyncExpansion = await const LSystemExpander().expandAsync(
      system,
      generations: 4,
      limits: const LSystemExpansionLimits(maximumRetainedGenerations: 2),
      yieldEverySymbols: 1,
    );
    final stochastic = _stochasticLSystem(seed);
    final stochasticFirst = const LSystemExpander().expand(
      stochastic,
      generations: 4,
    );
    final stochasticSecond = const LSystemExpander().expand(
      stochastic,
      generations: 4,
    );
    add(
      id: 'lsystem-async-retention-stochastic',
      algorithm: 'l-system-async-streaming',
      property: 'lsystem.retention-seed-reproducibility',
      actual: asyncExpansion is LSystemExpansionCompleted &&
              asyncExpansion.retainedGenerations.length == 2 &&
              stochasticFirst is LSystemExpansionCompleted &&
              stochasticSecond is LSystemExpansionCompleted &&
              stochasticFirst.finalGeneration.word ==
                  stochasticSecond.finalGeneration.word
          ? FormalSystemsCertificationOutcome.verified
          : FormalSystemsCertificationOutcome.different,
      evidence: {
        'retained': asyncExpansion.retainedGenerations
            .map((generation) => generation.index)
            .toList(),
      },
    );

    final context = const LSystemExpander().expand(
      _contextLSystem(seed),
      generations: 1,
    );
    final unsupported = const LSystemExpander().expand(
      _unsupportedLSystem(seed),
      generations: 1,
    );
    add(
      id: 'lsystem-context-unsupported',
      algorithm: 'l-system-context-selector',
      property: 'lsystem.context-and-parametric-boundary',
      actual: context is LSystemExpansionCompleted &&
              _listEquals(
                context.finalGeneration.word.symbols,
                const ['A', 'ignore', 'C'],
              ) &&
              unsupported is LSystemExpansionInvalid &&
              unsupported.diagnostics.any(
                (diagnostic) =>
                    diagnostic.code ==
                    LSystemExpansionDiagnosticCode.unsupportedVariant,
              )
          ? FormalSystemsCertificationOutcome.verified
          : FormalSystemsCertificationOutcome.invalid,
      evidence: {
        'contextWord': context.finalGeneration.word.symbols,
        'unsupported': unsupported.runtimeType.toString(),
      },
    );

    final turtleWord = LSystemWord(
      const ['F', '+', 'F', '[', '+', 'F', ']', 'F'],
    );
    final turtleSettings = LSystemTurtleSettings(
      angleDegrees: 90,
      stepLength: 10,
    );
    final turtle = const LSystemTurtleInterpreter().interpret(
      turtleWord,
      settings: turtleSettings,
      mapping: LSystemCommandMapping.standard,
    );
    final referenceGeometry = independentTurtleReplay(
      turtleWord,
      settings: turtleSettings,
      mapping: LSystemCommandMapping.standard,
    );
    add(
      id: 'turtle-geometry-oracle',
      algorithm: 'l-system-turtle-interpreter',
      property: 'turtle.geometry-bounds-stack-replay',
      actual: turtle is LSystemTurtleCompleted &&
              _doubleListsClose(
                turtle.geometry.segmentCoordinates,
                referenceGeometry.coordinates,
              ) &&
              _boundsClose(turtle.geometry.bounds, referenceGeometry.bounds) &&
              turtle.geometry.maximumBranchDepth == 1
          ? FormalSystemsCertificationOutcome.verified
          : FormalSystemsCertificationOutcome.different,
      evidence: {
        'bounds': turtle is LSystemTurtleCompleted
            ? _boundsJson(turtle.geometry.bounds)
            : null,
      },
    );

    LSystemTurtleOutcome turtleOutcome(
      List<String> symbols, {
      LSystemTurtleLimits limits = const LSystemTurtleLimits(),
    }) =>
        const LSystemTurtleInterpreter().interpret(
          LSystemWord(symbols),
          settings: turtleSettings,
          mapping: LSystemCommandMapping.standard,
          limits: limits,
        );
    final underflow = turtleOutcome(const [']']);
    final unclosed = turtleOutcome(const ['[']);
    final turtleBounded = turtleOutcome(
      const ['F'],
      limits: const LSystemTurtleLimits(maximumSegments: 0),
    );
    final turtleCancellation = LSystemCancellationToken()..cancel();
    final turtleCancelled = turtleOutcome(
      const ['F'],
      limits: LSystemTurtleLimits(cancellationToken: turtleCancellation),
    );
    add(
      id: 'turtle-invalid-resource-outcomes',
      algorithm: 'l-system-turtle-interpreter',
      property: 'turtle.typed-stack-bound-cancel',
      actual: _turtleInvalidHas(
                underflow,
                LSystemTurtleDiagnosticCode.stackUnderflow,
              ) &&
              _turtleInvalidHas(
                unclosed,
                LSystemTurtleDiagnosticCode.unclosedBranch,
              ) &&
              turtleBounded is LSystemTurtleBounded &&
              turtleCancelled is LSystemTurtleCancelled
          ? FormalSystemsCertificationOutcome.verified
          : FormalSystemsCertificationOutcome.invalid,
      evidence: {
        'bounded': turtleBounded.runtimeType.toString(),
        'cancelled': turtleCancelled.runtimeType.toString(),
      },
    );

    final geometry = (turtle as LSystemTurtleCompleted).geometry;
    final fit = LSystemFitTransform.contain(
      geometry.bounds,
      viewportWidth: 320,
      viewportHeight: 200,
      padding: 10,
    );
    add(
      id: 'turtle-fit',
      algorithm: 'l-system-fit-transform',
      property: 'turtle.negative-bounds-fit',
      actual: _geometryFits(geometry.bounds, fit, 320, 200, 10)
          ? FormalSystemsCertificationOutcome.verified
          : FormalSystemsCertificationOutcome.different,
      evidence: {
        'scale': fit.scale,
        'translateX': fit.translateX,
        'translateY': fit.translateY,
      },
    );

    final metadata = LSystemRenderMetadata(
      documentId: system.id,
      sourceRevision: system.revision,
      generation: 3,
      settings: turtleSettings,
    );
    final svgFirst = const LSystemSvgExporter().encode(
      geometry,
      metadata: metadata,
    );
    final svgSecond = const LSystemSvgExporter().encode(
      geometry,
      metadata: metadata,
    );
    final svgText = utf8.decode(svgFirst.bytes);
    add(
      id: 'turtle-svg-export',
      algorithm: 'l-system-svg-exporter',
      property: 'turtle.svg-deterministic-replay',
      actual: _listEquals(svgFirst.bytes, svgSecond.bytes) &&
              RegExp('<path ').allMatches(svgText).length ==
                  geometry.segmentCount &&
              svgText.contains('<metadata>') &&
              svgFirst.width >= geometry.bounds.width &&
              svgFirst.height >= geometry.bounds.height
          ? FormalSystemsCertificationOutcome.verified
          : FormalSystemsCertificationOutcome.different,
      evidence: {
        'bytes': svgFirst.bytes.length,
        'segments': geometry.segmentCount,
      },
    );

    final regular = formalSystemsRegularDecompositionFixture();
    final regularPump = regular.pumpBounded(2, maximumTokens: 32);
    final regularExpected = independentPumpedWord(regular, 2);
    final regularEnumerated = PumpingDecompositionEnumerator.regular(
      witness: regular.word,
      pumpingLength: 3,
    );
    add(
      id: 'pumping-regular-oracle',
      algorithm: 'regular-pumping-decomposition-enumerator',
      property: 'pumping.regular-reconstruction-count',
      actual: regularPump is PumpingWordCompleted &&
              _listEquals(regularPump.tokens, regularExpected) &&
              regularEnumerated.length == _regularDecompositionCount(3)
          ? FormalSystemsCertificationOutcome.verified
          : FormalSystemsCertificationOutcome.different,
      evidence: {
        'count': regularEnumerated.length,
        'word':
            regularPump is PumpingWordCompleted ? regularPump.tokens : const [],
      },
    );

    final contextFree = formalSystemsContextFreeDecompositionFixture();
    final contextFreePump = contextFree.pumpBounded(0, maximumTokens: 32);
    final contextFreeExpected = independentPumpedWord(contextFree, 0);
    final contextFreeEnumerated = PumpingDecompositionEnumerator.contextFree(
      witness: contextFree.word,
      pumpingLength: 3,
    );
    add(
      id: 'pumping-cfl-oracle',
      algorithm: 'context-free-pumping-decomposition-enumerator',
      property: 'pumping.cfl-simultaneous-reconstruction-count',
      actual: contextFreePump is PumpingWordCompleted &&
              _listEquals(contextFreePump.tokens, contextFreeExpected) &&
              contextFreeEnumerated.length ==
                  independentContextFreeDecompositionCount(
                    contextFree.word.length,
                    3,
                  )
          ? FormalSystemsCertificationOutcome.verified
          : FormalSystemsCertificationOutcome.different,
      evidence: {
        'count': contextFreeEnumerated.length,
        'word': contextFreePump is PumpingWordCompleted
            ? contextFreePump.tokens
            : const [],
      },
    );

    final invalidRegular = RegularPumpingDecomposition(
      x: const ['a', 'a'],
      y: const [],
      z: const ['b'],
    );
    var crossTypeRejected = false;
    try {
      PumpingLemmaSession<PumpingDecomposition>(
        sessionId: 'typed-$seed',
        challengeId: 'typed',
        sourceRevision: 'r1',
        theorem: PumpingLemmaTheorem.regular,
        mode: PumpingLemmaMode.challenge,
        role: PumpingLemmaRole.learner,
        targetLanguage: 'tokens',
        pumpingLength: 2,
        witness: contextFree.word,
        decomposition: contextFree,
      );
    } on ArgumentError {
      crossTypeRejected = true;
    }
    add(
      id: 'pumping-typed-boundaries',
      algorithm: 'pumping-decomposition-validator',
      property: 'pumping.theorem-type-and-segment-constraints',
      actual:
          invalidRegular.validate(pumpingLength: 1).toSet().containsAll(const {
                    PumpingDecompositionViolation.emptyPumpedSection,
                    PumpingDecompositionViolation.windowExceedsPumpingLength,
                  }) &&
                  crossTypeRejected
              ? FormalSystemsCertificationOutcome.verified
              : FormalSystemsCertificationOutcome.invalid,
      evidence: {'crossTypeRejected': crossTypeRejected},
    );

    final largePump = regular.pumpBounded(
      0x7fffffffffffffff,
      maximumTokens: 32,
    );
    final finiteEvidence = PumpingLemmaEvidence.bounded(
      observations: const [
        PumpingExponentObservation(exponent: 0, remainsInLanguage: true),
        PumpingExponentObservation(exponent: 1, remainsInLanguage: true),
        PumpingExponentObservation(exponent: 100, remainsInLanguage: true),
      ],
    );
    final counterexampleEvidence = PumpingLemmaEvidence.bounded(
      observations: const [
        PumpingExponentObservation(exponent: 0, remainsInLanguage: false),
      ],
    );
    add(
      id: 'pumping-resource-evidence',
      algorithm: 'pumping-word-evidence',
      property: 'pumping.large-exponent-and-finite-evidence',
      actual: largePump is PumpingWordBounded &&
              !finiteEvidence.provesUniversalClaim &&
              finiteEvidence.certainty ==
                  PumpingEvidenceCertainty.boundedEvidence &&
              counterexampleEvidence.certainty ==
                  PumpingEvidenceCertainty.counterexample &&
              counterexampleEvidence.counterexampleExponent == 0
          ? FormalSystemsCertificationOutcome.verified
          : FormalSystemsCertificationOutcome.invalid,
      evidence: {
        'disclosure': finiteEvidence.disclosureCode,
        'largePump': largePump.runtimeType.toString(),
      },
    );

    final controller = _regularController(seed);
    final transitionStates = <String>[];
    transitionStates.add(_sessionState(controller.state));
    controller.choosePumpingLength(
      expectedSessionId: controller.state.sessionId,
      player: PumpingLemmaPlayer.opponent,
      pumpingLength: 3,
    );
    transitionStates.add(_sessionState(controller.state));
    controller.chooseWitness(
      expectedSessionId: controller.state.sessionId,
      player: PumpingLemmaPlayer.learner,
      witness: regular.word,
      isInLanguage: true,
    );
    transitionStates.add(_sessionState(controller.state));
    controller.chooseDecomposition(
      expectedSessionId: controller.state.sessionId,
      player: PumpingLemmaPlayer.opponent,
      decomposition: regular,
    );
    transitionStates.add(_sessionState(controller.state));
    controller.chooseExponent(
      expectedSessionId: controller.state.sessionId,
      player: PumpingLemmaPlayer.learner,
      exponent: 0,
    );
    transitionStates.add(_sessionState(controller.state));
    controller.recordEvidence(
      expectedSessionId: controller.state.sessionId,
      player: PumpingLemmaPlayer.learner,
      evidence: counterexampleEvidence,
    );
    controller.complete(
      expectedSessionId: controller.state.sessionId,
      scoreDelta: 2,
    );
    transitionStates.add(_sessionState(controller.state));
    add(
      id: 'pumping-session-transition-table',
      algorithm: 'pumping-lemma-session-controller',
      property: 'pumping.adversarial-transition-model',
      actual: _listEquals(transitionStates, const [
                'awaitingPumpingLength:opponent',
                'awaitingWitness:learner',
                'awaitingDecomposition:opponent',
                'awaitingExponent:learner',
                'awaitingEvidence:learner',
                'completed:none',
              ]) &&
              controller.state.score == 2 &&
              controller.state.history.length == 6
          ? FormalSystemsCertificationOutcome.verified
          : FormalSystemsCertificationOutcome.different,
      evidence: {'states': transitionStates},
    );

    final retryController = _regularController(seed + 1);
    retryController.choosePumpingLength(
      expectedSessionId: retryController.state.sessionId,
      player: PumpingLemmaPlayer.opponent,
      pumpingLength: 1,
    );
    retryController.recordRetry(
      expectedSessionId: retryController.state.sessionId,
    );
    final retryScore = retryController.state.score;
    final staleId = retryController.state.sessionId;
    retryController.restart();
    var staleRejected = false;
    try {
      retryController.recordRetry(expectedSessionId: staleId);
    } on StalePumpingLemmaSessionException {
      staleRejected = true;
    }
    add(
      id: 'pumping-session-retry-restart',
      algorithm: 'pumping-lemma-session-controller',
      property: 'pumping.retry-restart-stale-isolation',
      actual: retryScore == 0 &&
              retryController.state.score == 0 &&
              retryController.state.history.isEmpty &&
              staleRejected
          ? FormalSystemsCertificationOutcome.verified
          : FormalSystemsCertificationOutcome.invalid,
      evidence: {
        'newSession': retryController.state.sessionId,
        'staleRejected': staleRejected,
      },
    );

    final migration = PumpingLemmaProgressMigration.migrate({
      'version': 1,
      'challenges': [
        {'id': 'regular.kept', 'theorem': 'regular', 'score': 2},
        {'id': 'cfl.kept', 'theorem': 'contextFree', 'score': 3},
        {'id': 'discarded', 'score': 99},
      ],
    });
    final migrationRoundTrip = PumpingLemmaProgressSnapshot.fromJson(
      migration.snapshot.toJson(),
    );
    add(
      id: 'pumping-progress-migration',
      algorithm: 'pumping-lemma-progress-migration',
      property: 'pumping.theorem-owned-progress-migration',
      actual: migration.requiresUserNotice &&
              _listEquals(
                  migration.discardedChallengeIds, const ['discarded']) &&
              migration.snapshot == migrationRoundTrip &&
              migration.snapshot.regular.challengeScores['regular.kept'] == 2 &&
              migration.snapshot.contextFree.challengeScores['cfl.kept'] == 3
          ? FormalSystemsCertificationOutcome.verified
          : FormalSystemsCertificationOutcome.different,
      evidence: {'discarded': migration.discardedChallengeIds},
    );

    final regularProblem = PumpingLemmaProblemCatalog.regular.first;
    final document = RegularPumpingLemmaDocument(
      problem: regularProblem,
      session: PumpingLemmaSession<RegularPumpingDecomposition>(
        sessionId: 'document-$seed',
        challengeId: regularProblem.id,
        sourceRevision: regularProblem.sourceRevision,
        theorem: PumpingLemmaTheorem.regular,
        mode: PumpingLemmaMode.guidedPractice,
        role: PumpingLemmaRole.learner,
        targetLanguage: regularProblem.languageDescription,
      ),
      progress: PumpingLemmaEnvironmentProgress(
        challengeScores: {regularProblem.id: 1},
      ),
    );
    final restoredDocument = PumpingLemmaDocument.fromJson(document.toJson());
    add(
      id: 'pumping-document-roundtrip',
      algorithm: 'pumping-lemma-document-codec-model',
      property: 'pumping.typed-session-serialization',
      actual: restoredDocument is RegularPumpingLemmaDocument &&
              canonicalJsonEncode(restoredDocument.toJson()) ==
                  canonicalJsonEncode(document.toJson())
          ? FormalSystemsCertificationOutcome.verified
          : FormalSystemsCertificationOutcome.different,
      evidence: {'runtimeType': restoredDocument.runtimeType.toString()},
    );

    final catalogValid = [
      ...PumpingLemmaProblemCatalog.regular,
      ...PumpingLemmaProblemCatalog.contextFree,
    ].every((problem) {
      final accepted = PumpingLemmaProblemCatalog.evaluateCurated(
        problem,
        problem.validationExamples
            .firstWhere((example) => example.expectedMembership)
            .tokens,
      );
      final rejected = PumpingLemmaProblemCatalog.evaluateCurated(
        problem,
        problem.validationExamples
            .firstWhere((example) => !example.expectedMembership)
            .tokens,
      );
      return accepted.isInLanguage == true &&
          rejected.isInLanguage == false &&
          !accepted.provesUniversalClaim;
    });
    add(
      id: 'pumping-membership-catalog',
      algorithm: 'pumping-lemma-problem-catalog',
      property: 'pumping.bounded-membership-disclosure',
      actual: catalogValid
          ? FormalSystemsCertificationOutcome.verified
          : FormalSystemsCertificationOutcome.invalid,
      evidence: {
        'contextFree': PumpingLemmaProblemCatalog.contextFree.length,
        'regular': PumpingLemmaProblemCatalog.regular.length,
      },
    );

    return records;
  }
}

final class IndependentTransducerResult {
  const IndependentTransducerResult({
    required this.completed,
    required this.output,
  });

  final bool completed;
  final List<String> output;
}

IndependentTransducerResult independentTransducerRun(
  DeterministicFiniteStateTransducer machine,
  TransducerInputWord input,
) {
  final initial = machine.states.where((state) => state.isInitial).toList();
  final stateIds = machine.states.map((state) => state.id).toSet();
  if (initial.length != 1 || stateIds.length != machine.states.length) {
    return const IndependentTransducerResult(completed: false, output: []);
  }
  final transitions = <(TransducerStateId, String), TransducerTransition>{};
  for (final transition in machine.transitions) {
    final key = (transition.from, transition.input.value);
    if (!stateIds.contains(transition.from) ||
        !stateIds.contains(transition.to) ||
        transitions.containsKey(key)) {
      return const IndependentTransducerResult(completed: false, output: []);
    }
    transitions[key] = transition;
  }
  var current = initial.single;
  final output = <String>[
    if (current is MooreState) ...current.output.values,
  ];
  for (final symbol in input.symbols) {
    if (!machine.inputAlphabet.contains(symbol)) {
      return IndependentTransducerResult(completed: false, output: output);
    }
    final transition = transitions[(current.id, symbol.value)];
    if (transition == null) {
      return IndependentTransducerResult(completed: false, output: output);
    }
    current = machine.states.singleWhere((state) => state.id == transition.to);
    if (transition is MealyTransition) {
      output.addAll(transition.output.values);
    } else {
      output.addAll((current as MooreState).output.values);
    }
  }
  return IndependentTransducerResult(completed: true, output: output);
}

List<String> independentLSystemExpand(LSystemDocument system, int generations) {
  var word = system.axiom.symbols.toList(growable: false);
  final byPredecessor = <String, LSystemProduction>{};
  for (final production in system.productions) {
    byPredecessor.putIfAbsent(production.predecessor, () => production);
  }
  for (var generation = 0; generation < generations; generation++) {
    word = [
      for (final symbol in word)
        ...(byPredecessor[symbol]?.successor.symbols ?? [symbol]),
    ];
  }
  return List<String>.unmodifiable(word);
}

final class IndependentTurtleGeometry {
  const IndependentTurtleGeometry({
    required this.coordinates,
    required this.bounds,
  });

  final List<double> coordinates;
  final LSystemBounds bounds;
}

IndependentTurtleGeometry independentTurtleReplay(
  LSystemWord word, {
  required LSystemTurtleSettings settings,
  required LSystemCommandMapping mapping,
}) {
  var x = settings.initialX;
  var y = settings.initialY;
  var heading = settings.initialHeadingDegrees;
  var minX = x;
  var maxX = x;
  var minY = y;
  var maxY = y;
  final stack = <(double, double, double)>[];
  final coordinates = <double>[];
  for (final symbol in word.symbols) {
    final command = mapping.commands[symbol] ?? LSystemTurtleCommand.ignore;
    switch (command) {
      case LSystemTurtleCommand.drawForward:
      case LSystemTurtleCommand.moveForward:
        final radians = heading * math.pi / 180;
        final nextX =
            x + math.sin(radians) * settings.stepLength * settings.scale;
        final nextY =
            y - math.cos(radians) * settings.stepLength * settings.scale;
        if (command == LSystemTurtleCommand.drawForward) {
          coordinates.addAll([x, y, nextX, nextY]);
        }
        x = _snap(nextX);
        y = _snap(nextY);
        minX = math.min(minX, x);
        maxX = math.max(maxX, x);
        minY = math.min(minY, y);
        maxY = math.max(maxY, y);
      case LSystemTurtleCommand.turnLeft:
        heading -= settings.angleDegrees;
      case LSystemTurtleCommand.turnRight:
        heading += settings.angleDegrees;
      case LSystemTurtleCommand.push:
        stack.add((x, y, heading));
      case LSystemTurtleCommand.pop:
        final restored = stack.removeLast();
        x = restored.$1;
        y = restored.$2;
        heading = restored.$3;
      default:
        break;
    }
  }
  return IndependentTurtleGeometry(
    coordinates: coordinates,
    bounds: LSystemBounds(minX: minX, minY: minY, maxX: maxX, maxY: maxY),
  );
}

List<String> independentPumpedWord(
  PumpingDecomposition decomposition,
  int exponent,
) {
  if (exponent < 0) throw ArgumentError.value(exponent, 'exponent');
  final output = <String>[];
  for (final segment in decomposition.segments) {
    final repetitions = segment.pumped ? exponent : 1;
    for (var count = 0; count < repetitions; count++) {
      output.addAll(segment.tokens);
    }
  }
  return List<String>.unmodifiable(output);
}

int independentContextFreeDecompositionCount(
    int wordLength, int pumpingLength) {
  var count = 0;
  for (var uEnd = 0; uEnd <= wordLength; uEnd++) {
    final windowEnd = math.min(wordLength, uEnd + pumpingLength);
    for (var vEnd = uEnd; vEnd <= windowEnd; vEnd++) {
      for (var xEnd = vEnd; xEnd <= windowEnd; xEnd++) {
        for (var yEnd = xEnd; yEnd <= windowEnd; yEnd++) {
          if (vEnd != uEnd || yEnd != xEnd) count++;
        }
      }
    }
  }
  return count;
}

MealyMachine formalSystemsMealyFixture(int seed) {
  final input = {
    const TransducerInputSymbol('a'),
    const TransducerInputSymbol('aa'),
    const TransducerInputSymbol('🙂'),
  };
  final output = {
    const TransducerOutputSymbol('x'),
    const TransducerOutputSymbol('long'),
    const TransducerOutputSymbol('emoji'),
  };
  final states = <MealyState>[
    const MealyState(
      id: TransducerStateId('q0'),
      label: 'zero',
      position: TransducerPoint(-10, 0),
      isInitial: true,
    ),
    const MealyState(
      id: TransducerStateId('q1'),
      label: 'one',
      position: TransducerPoint(10, 0),
    ),
  ];
  final transitions = <MealyTransition>[
    _mealyTransition('q0-a', 'q0', 'q1', 'a', const ['x']),
    _mealyTransition('q0-aa', 'q0', 'q0', 'aa', const ['long', 'x']),
    _mealyTransition('q0-emoji', 'q0', 'q0', '🙂', const ['emoji']),
    _mealyTransition('q1-a', 'q1', 'q0', 'a', const ['x']),
    _mealyTransition('q1-aa', 'q1', 'q1', 'aa', const ['long']),
    _mealyTransition('q1-emoji', 'q1', 'q1', '🙂', const ['emoji']),
  ];
  return MealyMachine(
    id: TransducerMachineId('hard-edge-mealy-$seed'),
    name: 'Hard edge Mealy',
    revision: const TransducerRevision(1),
    inputAlphabet: input,
    outputAlphabet: output,
    states: states,
    transitions: transitions,
  );
}

MooreMachine formalSystemsMooreFixture(int seed) => MooreMachine(
      id: TransducerMachineId('hard-edge-moore-$seed'),
      name: 'Hard edge Moore',
      revision: const TransducerRevision(1),
      inputAlphabet: {const TransducerInputSymbol('a')},
      outputAlphabet: {
        const TransducerOutputSymbol('zero'),
        const TransducerOutputSymbol('one'),
      },
      states: [
        MooreState(
          id: const TransducerStateId('q0'),
          label: 'zero',
          position: const TransducerPoint(0, 0),
          output: TransducerOutputWord.fromValues(const ['zero']),
          isInitial: true,
        ),
        MooreState(
          id: const TransducerStateId('q1'),
          label: 'one',
          position: const TransducerPoint(10, 0),
          output: TransducerOutputWord.fromValues(const ['one']),
        ),
      ],
      transitions: const [
        MooreTransition(
          id: TransducerTransitionId('q0-a'),
          from: TransducerStateId('q0'),
          to: TransducerStateId('q1'),
          input: TransducerInputSymbol('a'),
        ),
        MooreTransition(
          id: TransducerTransitionId('q1-a'),
          from: TransducerStateId('q1'),
          to: TransducerStateId('q0'),
          input: TransducerInputSymbol('a'),
        ),
      ],
    );

LSystemDocument formalSystemsLSystemFixture(int seed) => LSystemDocument(
      id: 'hard-edge-lsystem-$seed',
      name: 'Hard edge L-system',
      revision: 1,
      axiom: LSystemWord(const ['A', 'B', '🙂']),
      productions: [
        LSystemProduction(
          id: 'a-grow',
          predecessor: 'A',
          successor: LSystemWord(const ['A', 'B']),
        ),
        LSystemProduction(
          id: 'b-to-a',
          predecessor: 'B',
          successor: LSystemWord(const ['A']),
        ),
        LSystemProduction(
          id: 'emoji-epsilon',
          predecessor: '🙂',
          successor: LSystemWord.empty,
        ),
      ],
      iterations: 3,
      turtle: LSystemTurtleSettings(),
      commandMapping: LSystemCommandMapping.standard,
      randomSeed: seed,
    );

RegularPumpingDecomposition formalSystemsRegularDecompositionFixture() =>
    RegularPumpingDecomposition(
      x: const ['multi'],
      y: const ['🙂'],
      z: const ['z'],
    );

ContextFreePumpingDecomposition
    formalSystemsContextFreeDecompositionFixture() =>
        ContextFreePumpingDecomposition(
          u: const ['a'],
          v: const ['multi'],
          x: const ['🙂'],
          y: const ['b'],
          z: const ['z'],
        );

final class FormalSystemsMutationResult {
  const FormalSystemsMutationResult({
    required this.id,
    required this.killed,
    required this.productionPassed,
    required this.witness,
  });

  final String id;
  final bool killed;
  final bool productionPassed;
  final String witness;

  Map<String, Object?> toJson() => {
        'id': id,
        'productionPassed': productionPassed,
        'status': killed ? 'killed' : 'survived',
        'witness': witness,
      };
}

enum _FormalSystemsCertificationMutation {
  dropMooreInitialOutput,
  rewriteLSystemSequentially,
  pumpOnlyOneCflSegment,
}

final class _FormalSystemsCertificationAdapter {
  const _FormalSystemsCertificationAdapter([this.mutation]);

  final _FormalSystemsCertificationMutation? mutation;

  TransducerExecutionOutcome runMoore(
    MooreMachine machine,
    TransducerInputWord input,
  ) {
    final result = DeterministicTransducerSimulator.moore(machine).run(input);
    if (mutation !=
            _FormalSystemsCertificationMutation.dropMooreInitialOutput ||
        result is! TransducerSuccess ||
        result.output.symbols.isEmpty) {
      return result;
    }
    return TransducerSuccess(
      input: result.input,
      output: TransducerOutputWord(result.output.symbols.skip(1)),
      trace: result.trace,
      processedInputCount: result.processedInputCount,
    );
  }

  List<String>? expandLSystem(LSystemDocument system, int generations) {
    final result = const LSystemExpander().expand(
      system,
      generations: generations,
    );
    if (result is! LSystemExpansionCompleted) return null;
    if (mutation ==
        _FormalSystemsCertificationMutation.rewriteLSystemSequentially) {
      return _mutantSequentialExpand(system, generations);
    }
    return result.finalGeneration.word.symbols;
  }

  PumpingWordOutcome pumpContextFree(
    ContextFreePumpingDecomposition decomposition,
    int exponent, {
    required int maximumTokens,
  }) {
    final result = decomposition.pumpBounded(
      exponent,
      maximumTokens: maximumTokens,
    );
    if (mutation != _FormalSystemsCertificationMutation.pumpOnlyOneCflSegment ||
        result is! PumpingWordCompleted) {
      return result;
    }
    return PumpingWordCompleted([
      ...decomposition.u,
      for (var count = 0; count < exponent; count++) ...decomposition.v,
      ...decomposition.x,
      ...decomposition.y,
      ...decomposition.z,
    ]);
  }
}

List<FormalSystemsMutationResult> runFormalSystemsMutationProbes({
  int seed = 339,
}) {
  final moore = formalSystemsMooreFixture(seed);
  const input = TransducerInputWord.empty;
  final expectedMoore = independentTransducerRun(moore, input).output;
  bool mooreProperty(_FormalSystemsCertificationAdapter adapter) {
    final result = adapter.runMoore(moore, input);
    return result is TransducerSuccess &&
        _listEquals(result.output.values, expectedMoore);
  }

  final mooreProductionPassed =
      mooreProperty(const _FormalSystemsCertificationAdapter());

  final system = formalSystemsLSystemFixture(seed);
  final expectedLSystem = independentLSystemExpand(system, 2);
  bool lSystemProperty(_FormalSystemsCertificationAdapter adapter) {
    final output = adapter.expandLSystem(system, 2);
    return output != null && _listEquals(output, expectedLSystem);
  }

  final lSystemProductionPassed =
      lSystemProperty(const _FormalSystemsCertificationAdapter());

  final cfl = formalSystemsContextFreeDecompositionFixture();
  final expectedPump = independentPumpedWord(cfl, 0);
  bool pumpProperty(_FormalSystemsCertificationAdapter adapter) {
    final result = adapter.pumpContextFree(cfl, 0, maximumTokens: 32);
    return result is PumpingWordCompleted &&
        _listEquals(result.tokens, expectedPump);
  }

  final pumpProductionPassed =
      pumpProperty(const _FormalSystemsCertificationAdapter());
  return [
    FormalSystemsMutationResult(
      id: 'drop-moore-initial-output',
      killed: mooreProductionPassed &&
          !mooreProperty(
            const _FormalSystemsCertificationAdapter(
              _FormalSystemsCertificationMutation.dropMooreInitialOutput,
            ),
          ),
      productionPassed: mooreProductionPassed,
      witness: 'empty-input',
    ),
    FormalSystemsMutationResult(
      id: 'rewrite-lsystem-sequentially',
      killed: lSystemProductionPassed &&
          !lSystemProperty(
            const _FormalSystemsCertificationAdapter(
              _FormalSystemsCertificationMutation.rewriteLSystemSequentially,
            ),
          ),
      productionPassed: lSystemProductionPassed,
      witness: 'generation-2',
    ),
    FormalSystemsMutationResult(
      id: 'pump-only-one-cfl-segment',
      killed: pumpProductionPassed &&
          !pumpProperty(
            const _FormalSystemsCertificationAdapter(
              _FormalSystemsCertificationMutation.pumpOnlyOneCflSegment,
            ),
          ),
      productionPassed: pumpProductionPassed,
      witness: 'i=0',
    ),
  ];
}

Future<void> writeFormalSystemsCertificationReport(
  FormalSystemsCertificationReport report,
  Directory output,
) async {
  await output.create(recursive: true);
  final json = const JsonEncoder.withIndent(' ').convert(report.toJson());
  await File(
          '${output.path}${Platform.pathSeparator}formal-systems-report.json')
      .writeAsString('$json\n', flush: true);
  final markdown = StringBuffer()
    ..writeln('# Formal-systems hard-edge certification')
    ..writeln()
    ..writeln('- Status: `${report.status.name}`')
    ..writeln('- Seeds: `${report.seedStart}` through '
        '`${report.seedStart + report.seedCount - 1}`')
    ..writeln('- Records: `${report.records.length}`')
    ..writeln('- Remotely verified: `false`')
    ..writeln()
    ..writeln('| Case | Algorithm | Property | Expected | Actual |')
    ..writeln('| --- | --- | --- | --- | --- |');
  for (final record in report.records) {
    markdown.writeln('| `${record.id}` | `${record.algorithm}` | '
        '`${record.property}` | `${record.expected.name}` | '
        '`${record.actual.name}` |');
  }
  markdown
    ..writeln()
    ..writeln('Results are local only and were not remotely verified.');
  await File('${output.path}${Platform.pathSeparator}formal-systems-report.md')
      .writeAsString(markdown.toString(), flush: true);
}

MealyTransition _mealyTransition(
  String id,
  String from,
  String to,
  String input,
  List<String> output,
) =>
    MealyTransition(
      id: TransducerTransitionId(id),
      from: TransducerStateId(from),
      to: TransducerStateId(to),
      input: TransducerInputSymbol(input),
      output: TransducerOutputWord.fromValues(output),
    );

MealyMachine _renamedMealy(MealyMachine source) {
  const names = {'q0': 'renamed-zero', 'q1': 'renamed-one'};
  return source.copyWith(
    id: TransducerMachineId('${source.id.value}-renamed'),
    states: source.states.reversed.map(
      (state) => state.copyWith(id: TransducerStateId(names[state.id.value]!)),
    ),
    transitions: source.transitions.reversed.map(
      (transition) => MealyTransition(
        id: TransducerTransitionId('renamed-${transition.id.value}'),
        from: TransducerStateId(names[transition.from.value]!),
        to: TransducerStateId(names[transition.to.value]!),
        input: transition.input,
        output: transition.output,
      ),
    ),
  );
}

bool _traceReplays(
  MealyMachine machine,
  TransducerInputWord input,
  TransducerSuccess outcome,
) {
  var state = machine.states.singleWhere((item) => item.isInitial).id;
  final output = <String>[];
  for (var index = 0; index < outcome.trace.length; index++) {
    final step = outcome.trace[index];
    if (step.index != index ||
        step.sourceStateId != state ||
        step.consumedInput != input.symbols[index] ||
        step.remainingInput.offset != index + 1) {
      return false;
    }
    final transition = machine.transitions.singleWhere(
      (item) => item.id == step.transitionId,
    );
    output.addAll(transition.output.values);
    if (!_listEquals(step.cumulativeOutput.values, output)) return false;
    state = transition.to;
  }
  return outcome.trace.length == input.symbols.length &&
      _listEquals(output, outcome.output.values);
}

bool _executionTracesEqual(
  TransducerExecutionOutcome left,
  TransducerExecutionOutcome right,
) {
  if (left.trace.length != right.trace.length) return false;
  for (var index = 0; index < left.trace.length; index++) {
    final leftStep = left.trace[index];
    final rightStep = right.trace[index];
    if (leftStep.index != rightStep.index ||
        leftStep.sourceStateId != rightStep.sourceStateId ||
        leftStep.targetStateId != rightStep.targetStateId ||
        leftStep.transitionId != rightStep.transitionId ||
        leftStep.consumedInput != rightStep.consumedInput ||
        leftStep.emittedOutput != rightStep.emittedOutput ||
        leftStep.cumulativeOutput != rightStep.cumulativeOutput ||
        leftStep.remainingInput != rightStep.remainingInput ||
        leftStep.sourceRevision != rightStep.sourceRevision) {
      return false;
    }
  }
  return true;
}

bool _executionOutcomesEqual(
  TransducerExecutionOutcome left,
  TransducerExecutionOutcome right,
) {
  if (left.runtimeType != right.runtimeType ||
      left.input != right.input ||
      left.output != right.output ||
      left.processedInputCount != right.processedInputCount ||
      left.traceWasTruncated != right.traceWasTruncated ||
      !_executionTracesEqual(left, right)) {
    return false;
  }
  if (left is TransducerSuccess && right is TransducerSuccess) return true;
  if (left is TransducerCancelled && right is TransducerCancelled) return true;
  if (left is TransducerBounded && right is TransducerBounded) {
    return left.maxSteps == right.maxSteps;
  }
  if (left is TransducerIncomplete && right is TransducerIncomplete) {
    return left.stateId == right.stateId && left.nextInput == right.nextInput;
  }
  if (left is TransducerInvalidInput && right is TransducerInvalidInput) {
    return left.invalidSymbol == right.invalidSymbol &&
        _tokenizationFailuresEqual(
          left.tokenizationFailure,
          right.tokenizationFailure,
        );
  }
  if (left is TransducerInvalidMachine && right is TransducerInvalidMachine) {
    return left.analysis.isDeterministic == right.analysis.isDeterministic &&
        left.analysis.isComplete == right.analysis.isComplete &&
        _diagnosticsEqual(
          left.analysis.diagnostics,
          right.analysis.diagnostics,
        );
  }
  return false;
}

bool _tokenizationFailuresEqual(
  TransducerTokenizationFailure? left,
  TransducerTokenizationFailure? right,
) =>
    left == null || right == null
        ? left == right
        : left.offset == right.offset &&
            left.remaining == right.remaining &&
            left.prefix == right.prefix;

bool _diagnosticsEqual(
  List<TransducerDiagnostic> left,
  List<TransducerDiagnostic> right,
) {
  if (left.length != right.length) return false;
  for (var index = 0; index < left.length; index++) {
    if (left[index].code != right[index].code ||
        left[index].severity != right[index].severity ||
        left[index].subject != right[index].subject) {
      return false;
    }
  }
  return true;
}

LSystemDocument _identityEpsilonLSystem(int seed) => LSystemDocument(
      id: 'identity-epsilon-$seed',
      name: 'Identity epsilon',
      revision: 1,
      axiom: LSystemWord(const ['drop', 'keep']),
      productions: [
        LSystemProduction(
          id: 'drop',
          predecessor: 'drop',
          successor: LSystemWord.empty,
        ),
      ],
      iterations: 1,
      turtle: LSystemTurtleSettings(),
      commandMapping: LSystemCommandMapping.standard,
    );

LSystemDocument _stochasticLSystem(int seed) => LSystemDocument(
      id: 'stochastic-$seed',
      name: 'Seeded stochastic',
      revision: 1,
      axiom: LSystemWord(const ['A']),
      productions: [
        LSystemProduction(
          id: 'left',
          predecessor: 'A',
          successor: LSystemWord(const ['A', 'B']),
          weight: 1,
        ),
        LSystemProduction(
          id: 'right',
          predecessor: 'A',
          successor: LSystemWord(const ['B', 'A']),
          weight: 3,
        ),
      ],
      iterations: 4,
      turtle: LSystemTurtleSettings(),
      commandMapping: LSystemCommandMapping.standard,
      randomSeed: seed,
    );

LSystemDocument _contextLSystem(int seed) => LSystemDocument(
      id: 'context-$seed',
      name: 'Context',
      revision: 1,
      axiom: LSystemWord(const ['A', 'ignore', 'B']),
      productions: [
        LSystemProduction(
          id: 'context-b',
          predecessor: 'B',
          leftContext: LSystemWord(const ['A']),
          successor: LSystemWord(const ['C']),
        ),
      ],
      iterations: 1,
      turtle: LSystemTurtleSettings(),
      commandMapping: LSystemCommandMapping.standard,
      randomSeed: seed,
      ignoredContextSymbols: const {'ignore'},
    );

LSystemDocument _unsupportedLSystem(int seed) => LSystemDocument(
      id: 'unsupported-$seed',
      name: 'Unsupported',
      revision: 1,
      axiom: LSystemWord(const ['A']),
      productions: const [],
      iterations: 1,
      turtle: LSystemTurtleSettings(),
      commandMapping: LSystemCommandMapping.standard,
      unsupportedVariants: const {LSystemUnsupportedVariant.parametric},
    );

List<String> _mutantSequentialExpand(LSystemDocument system, int generations) {
  var word = system.axiom.symbols.toList();
  for (var generation = 0; generation < generations; generation++) {
    for (final production in system.productions) {
      word = [
        for (final symbol in word)
          if (symbol == production.predecessor)
            ...production.successor.symbols
          else
            symbol,
      ];
    }
  }
  return word;
}

bool _provenanceReplays(
  LSystemDocument system,
  List<LSystemGeneration> generations,
) {
  final byId = {
    for (final production in system.productions) production.id: production
  };
  for (var index = 1; index < generations.length; index++) {
    final previous = generations[index - 1];
    final current = generations[index];
    final rebuilt = <String>[];
    for (final run in current.provenance) {
      if (run.sourceIndex >= previous.word.length ||
          run.outputStart != rebuilt.length) {
        return false;
      }
      final source = previous.word.symbols[run.sourceIndex];
      final replacement = run.productionId == null
          ? [source]
          : byId[run.productionId]?.successor.symbols;
      if (replacement == null) return false;
      rebuilt.addAll(replacement);
      if (run.outputEnd != rebuilt.length) return false;
    }
    if (!_listEquals(rebuilt, current.word.symbols)) return false;
  }
  return true;
}

bool _expansionBoundIs(
  LSystemExpansionOutcome outcome,
  LSystemExpansionBoundKind kind,
) =>
    outcome is LSystemExpansionBounded && outcome.kind == kind;

String? _expansionBoundName(LSystemExpansionOutcome outcome) =>
    outcome is LSystemExpansionBounded ? outcome.kind.name : null;

bool _turtleInvalidHas(
  LSystemTurtleOutcome outcome,
  LSystemTurtleDiagnosticCode code,
) =>
    outcome is LSystemTurtleInvalid &&
    outcome.diagnostics.any((diagnostic) => diagnostic.code == code);

bool _geometryFits(
  LSystemBounds bounds,
  LSystemFitTransform fit,
  double width,
  double height,
  double padding,
) {
  final points = [
    (bounds.minX, bounds.minY),
    (bounds.minX, bounds.maxY),
    (bounds.maxX, bounds.minY),
    (bounds.maxX, bounds.maxY),
  ];
  return points.every((point) {
    final x = point.$1 * fit.scale + fit.translateX;
    final y = point.$2 * fit.scale + fit.translateY;
    return x >= padding - 1e-9 &&
        x <= width - padding + 1e-9 &&
        y >= padding - 1e-9 &&
        y <= height - padding + 1e-9;
  });
}

Map<String, double> _boundsJson(LSystemBounds bounds) => {
      'maxX': bounds.maxX,
      'maxY': bounds.maxY,
      'minX': bounds.minX,
      'minY': bounds.minY,
    };

bool _boundsClose(LSystemBounds left, LSystemBounds right) =>
    (left.minX - right.minX).abs() < 1e-9 &&
    (left.minY - right.minY).abs() < 1e-9 &&
    (left.maxX - right.maxX).abs() < 1e-9 &&
    (left.maxY - right.maxY).abs() < 1e-9;

bool _doubleListsClose(Iterable<double> left, Iterable<double> right) {
  final leftValues = left.toList();
  final rightValues = right.toList();
  if (leftValues.length != rightValues.length) return false;
  for (var index = 0; index < leftValues.length; index++) {
    if ((leftValues[index] - rightValues[index]).abs() > 1e-9) return false;
  }
  return true;
}

int _regularDecompositionCount(int pumpingLength) =>
    pumpingLength * (pumpingLength + 1) ~/ 2;

PumpingLemmaSessionController<RegularPumpingDecomposition> _regularController(
  int seed,
) =>
    PumpingLemmaSessionController.regular(
      initialSession: PumpingLemmaSession<RegularPumpingDecomposition>(
        sessionId: 'session-$seed',
        challengeId: 'hard-edge',
        sourceRevision: 'issue-339',
        theorem: PumpingLemmaTheorem.regular,
        mode: PumpingLemmaMode.challenge,
        role: PumpingLemmaRole.learner,
        targetLanguage: 'token language',
      ),
      sessionIdFactory: () => 'session-${seed + 1}',
    );

String _sessionState<T extends PumpingDecomposition>(
  PumpingLemmaSession<T> session,
) =>
    '${session.stage.name}:${session.currentPlayer?.name ?? 'none'}';

double _snap(double value) {
  final rounded = value.roundToDouble();
  return (value - rounded).abs() < 1e-12 ? rounded : value;
}

bool _listEquals<T>(Iterable<T> left, Iterable<T> right) {
  final leftValues = left.toList();
  final rightValues = right.toList();
  if (leftValues.length != rightValues.length) return false;
  for (var index = 0; index < leftValues.length; index++) {
    if (leftValues[index] != rightValues[index]) return false;
  }
  return true;
}

Map<String, int> _sortedCounts(Map<String, int> source) => {
      for (final key in (source.keys.toList()..sort())) key: source[key]!,
    };
