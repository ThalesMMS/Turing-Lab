import 'dart:convert';
import 'dart:io';
import 'dart:math' as math;

import 'package:test/test.dart';
import 'package:turing_lab/core/algorithms/tm_execution_analyzer.dart';
import 'package:turing_lab/core/models/state.dart';
import 'package:turing_lab/core/models/tm.dart';
import 'package:turing_lab/core/models/tm_execution_analysis.dart';
import 'package:turing_lab/core/models/tm_transition.dart';
import 'package:turing_lab/core/models/transition.dart';
import 'package:vector_math/vector_math_64.dart';

import '../../../tool/hard_edge/catalog.dart';
import '../../../tool/hard_edge/families/tm_certification.dart';
import '../../../tool/hard_edge/families/tm_family.dart';
import '../../../tool/hard_edge/families/tm_matrix.dart';
import '../../../tool/hard_edge/families/tm_oracle.dart';
import '../../../tool/hard_edge/mutation.dart';
import '../../../tool/hard_edge/runner.dart';

void main() {
  group('TM independent oracle', () {
    test('agrees on acceptance, rejection, cycles, and negative heads',
        () async {
      final cases = [
        (_acceptor(), const ['a']),
        (_rejector(), const <String>[]),
        (_cycle(), const <String>[]),
        (_leftAcceptor(), const <String>[]),
      ];
      const oracle = IndependentTmOracle();

      for (final (machine, input) in cases) {
        final expected = oracle.run(machine, input);
        final actual = await TMExecutionAnalyzer.analyzeTokens(machine, input);
        expect(
          expected.outcome.name,
          switch (actual.outcome) {
            TMExecutionOutcome.accepted => 'accepted',
            TMExecutionOutcome.haltedRejected => 'haltedRejected',
            TMExecutionOutcome.provenCycle => 'provenCycle',
            TMExecutionOutcome.boundedUnknown ||
            TMExecutionOutcome.cancelled =>
              'boundedUnknown',
            TMExecutionOutcome.invalidMachine => 'invalidMachine',
          },
          reason: machine.id,
        );
      }
      expect(oracle.run(_leftAcceptor(), const []).trace.single.heads, [-1]);
    });

    test('does not turn an NTM repeated branch into global nontermination',
        () async {
      final machine = _acceptingAndCyclicNtm();

      expect(
        const IndependentTmOracle().run(machine, const []).outcome,
        TmOracleOutcome.accepted,
      );
      expect(
        (await TMExecutionAnalyzer.analyze(machine, '')).outcome,
        TMExecutionOutcome.accepted,
      );
    });

    test('checks the complete step-limit frontier before returning bounded',
        () async {
      final machine = _acceptingAtLimitAfterTruncatedBranch();

      final oracle = const IndependentTmOracle(maximumSteps: 1).run(
        machine,
        const [],
      );
      final production = await TMExecutionAnalyzer.analyze(
        machine,
        '',
        maxSteps: 1,
      );

      expect(oracle.outcome, TmOracleOutcome.accepted);
      expect(oracle.steps, 1);
      expect(production.outcome, TMExecutionOutcome.accepted);
    });
  });

  group('TM hard-edge family', () {
    test('matrix inventories unique existing live sources', () {
      expect(tmAlgorithmInventory, hasLength(19));
      expect(
        tmAlgorithmInventory.map((entry) => entry.id).toSet(),
        hasLength(tmAlgorithmInventory.length),
      );
      for (final entry in tmAlgorithmInventory) {
        expect(File(entry.sourcePath).existsSync(), isTrue, reason: entry.id);
        expect(entry.entryPoints, isNotEmpty, reason: entry.id);
        expect(entry.properties, everyElement(isIn(tmPropertyIds)));
      }
    });

    test('all 13 properties pass and reports are deterministic', () async {
      final runner = TmCertificationRunner(repositoryRoot: Directory.current);
      const options = TmCertificationOptions(cases: 4);

      final first = await runner.run(options);
      final second = await runner.run(options);

      expect(first.status, TmCertificationStatus.passed);
      expect(first.checks, hasLength(13));
      expect(first.toJson(), second.toJson());
      final inventory =
          first.checks.singleWhere((check) => check.id == 'tm.inventory');
      expect(
        inventory.evidence['executedEntrypoints'],
        hasLength(
          tmAlgorithmInventory.fold<int>(
            0,
            (count, entry) => count + entry.entryPoints.length,
          ),
        ),
      );
      expect(inventory.evidence['missingEntrypointEvidence'], isEmpty);
    });

    test('catalog fragment has current digests and full descriptor coverage',
        () async {
      final catalog = await HardEdgeCatalog.load(
        repositoryRoot: Directory.current,
        manifestFile: File(
          'test/fixtures/hard_edge/tm/catalog.fragment.json',
        ),
      );

      expect(catalog.manifest.cases, hasLength(19));
      expect(catalog.manifest.mutations, hasLength(4));
      expect(
        catalog.manifest.cases.map((testCase) => testCase.id).toSet(),
        tmHardEdgeDescriptors.map((descriptor) => descriptor.id).toSet(),
      );
      final descriptors = {
        for (final descriptor in tmHardEdgeDescriptors)
          descriptor.id: descriptor,
      };
      for (final testCase in catalog.manifest.cases) {
        expect(testCase.algorithm, descriptors[testCase.id]!.algorithm);
        expect(testCase.property, descriptors[testCase.id]!.property);
      }
    });

    test('catalog adapter executes every inventoried descriptor', () async {
      final catalog = await HardEdgeCatalog.load(
        repositoryRoot: Directory.current,
        manifestFile: File(
          'test/fixtures/hard_edge/tm/catalog.fragment.json',
        ),
      );
      final executor = TmHardEdgeExecutor();

      for (final testCase in catalog.manifest.cases) {
        final fixture = jsonDecode(
          await catalog.fixtureFor(testCase).readAsString(),
        );
        expect(
          await executor.execute(testCase, fixture),
          HardEdgeExecutionOutcome.pass,
          reason: '${testCase.algorithm}/${testCase.property}',
        );
      }
    });

    test('fixture scenario and expected status change the verdict', () async {
      final executor = TmHardEdgeExecutor();
      final testCase = (await HardEdgeCatalog.load(
        repositoryRoot: Directory.current,
        manifestFile: File(
          'test/fixtures/hard_edge/tm/catalog.fragment.json',
        ),
      ))
          .manifest
          .cases
          .first;
      const valid = {
        'family': 'tm',
        'scenario': 'core-oracle',
        'expectedStatus': 'passed',
      };

      expect(
        await executor.execute(testCase, valid),
        HardEdgeExecutionOutcome.pass,
      );
      expect(
        await executor.execute(
          testCase,
          {...valid, 'scenario': 'wrong'},
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

    test('external shrink fixture is valid, applicable, and reducible',
        () async {
      final fixture = jsonDecode(
        await File('test/fixtures/hard_edge/tm/shrink_probe.json')
            .readAsString(),
      );

      expect(tmFailureFixtureIsValid(fixture), isTrue);
      expect(tmFailureFixtureIsApplicable(fixture), isTrue);
      final candidates = tmFailureFixtureShrinker.candidates(fixture).toList();
      expect(candidates, isNotEmpty);
      expect(
        candidates.any(
          (candidate) =>
              tmFailureFixtureIsValid(candidate) &&
              tmFailureFixtureIsApplicable(candidate),
        ),
        isTrue,
      );
      final minimized = minimizeTmFailureFixture(fixture);
      expect(
        tmFailureFixtureSignature(minimized),
        tmFailureFixtureSignature(fixture),
      );
      expect(tmFailureFixtureIsMinimal(minimized), isTrue);
      final minimizedMap = minimized! as Map;
      expect(minimizedMap['inputTokens'], ['a']);
      expect(
        ((minimizedMap['machine'] as Map)['transitions'] as List),
        hasLength(1),
      );
      expect((minimizedMap['machine'] as Map)['alphabet'], ['a']);
      expect((minimizedMap['machine'] as Map)['tapeAlphabet'], ['a', 'B']);

      final withDistinctTokens = <String, Object?>{
        ...(fixture as Map).cast<String, Object?>(),
        'inputTokens': ['a', 'x', 'a'],
      };
      final tokenCandidates = tmFailureFixtureCandidates(withDistinctTokens)
          .map((candidate) => (candidate as Map)['inputTokens'])
          .whereType<List>()
          .toList();
      expect(tokenCandidates, contains(equals(['a', 'a'])));
      expect(tokenCandidates, contains(equals(['a', 'x'])));
    });

    test('all registered semantic mutants are killed independently', () async {
      final fixture = jsonDecode(
        await File('test/fixtures/hard_edge/tm/mutation_probes.json')
            .readAsString(),
      );
      final executor = TmHardEdgeMutationExecutor();
      final catalog = await HardEdgeCatalog.load(
        repositoryRoot: Directory.current,
        manifestFile: File(
          'test/fixtures/hard_edge/tm/catalog.fragment.json',
        ),
      );

      for (final mutation in catalog.manifest.mutations) {
        final probe = await runTmMutationProbe(mutation.operatorId);
        expect(probe.productionPassed, isTrue, reason: mutation.operatorId);
        expect(probe.mutantRejected, isTrue, reason: mutation.operatorId);
        expect(
          await executor.execute(mutation, fixture),
          HardEdgeMutationStatus.killed,
          reason: mutation.operatorId,
        );
      }
    });
  });
}

TM _acceptor() {
  final q0 = _state('q0', initial: true);
  final qa = _state('qa', accepting: true);
  return _tm(
    id: 'acceptor',
    states: [q0, qa],
    accepting: [qa],
    alphabet: const {'a'},
    tapeAlphabet: const {'a', 'B'},
    transitions: [_transition('accept', q0, qa, 'a')],
  );
}

TM _rejector() => _tm(
      id: 'rejector',
      states: [_state('q0', initial: true)],
    );

TM _cycle() {
  final q0 = _state('q0', initial: true);
  return _tm(
    id: 'cycle',
    states: [q0],
    transitions: [_transition('loop', q0, q0, 'B')],
  );
}

TM _leftAcceptor() {
  final q0 = _state('q0', initial: true);
  final qa = _state('qa', accepting: true);
  return _tm(
    id: 'left',
    states: [q0, qa],
    accepting: [qa],
    transitions: [
      _transition('left', q0, qa, 'B', direction: TapeDirection.left),
    ],
  );
}

TM _acceptingAndCyclicNtm() {
  final q0 = _state('q0', initial: true);
  final qa = _state('qa', accepting: true);
  return _tm(
    id: 'ntm',
    states: [q0, qa],
    accepting: [qa],
    transitions: [
      _transition('a-cycle', q0, q0, 'B', nondeterministic: true),
      _transition('z-accept', q0, qa, 'B', nondeterministic: true),
    ],
  );
}

TM _acceptingAtLimitAfterTruncatedBranch() {
  final q0 = _state('q0', initial: true);
  final bounded = _state('bounded');
  final accept = _state('accept', accepting: true);
  return _tm(
    id: 'frontier-order',
    states: [q0, bounded, accept],
    accepting: [accept],
    transitions: [
      _transition(
        'a-bounded-first',
        q0,
        bounded,
        'B',
        nondeterministic: true,
      ),
      _transition(
        'z-accept-second',
        q0,
        accept,
        'B',
        nondeterministic: true,
      ),
      _transition(
        'bounded-continues',
        bounded,
        bounded,
        'B',
        nondeterministic: true,
      ),
    ],
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

TMTransition _transition(
  String id,
  State from,
  State to,
  String read, {
  TapeDirection direction = TapeDirection.stay,
  bool nondeterministic = false,
}) =>
    TMTransition(
      id: id,
      fromState: from,
      toState: to,
      label: id,
      readSymbol: read,
      writeSymbol: read,
      direction: direction,
      type: nondeterministic
          ? TransitionType.nondeterministic
          : TransitionType.deterministic,
      controlPoint: from == to ? Vector2(20, -20) : Vector2.zero(),
    );

TM _tm({
  required String id,
  required Iterable<State> states,
  Iterable<TMTransition> transitions = const [],
  Iterable<State> accepting = const [],
  Set<String> alphabet = const {},
  Set<String> tapeAlphabet = const {'B'},
}) {
  final stateSet = states.toSet();
  return TM(
    id: id,
    name: id,
    states: stateSet,
    transitions: transitions.toSet(),
    alphabet: alphabet,
    initialState: stateSet.where((state) => state.isInitial).firstOrNull,
    acceptingStates: accepting.toSet(),
    created: DateTime.utc(2026),
    modified: DateTime.utc(2026),
    bounds: const math.Rectangle(0, 0, 100, 100),
    tapeAlphabet: tapeAlphabet,
  );
}

extension<T> on Iterable<T> {
  T? get firstOrNull => this.isEmpty ? null : first;
}
