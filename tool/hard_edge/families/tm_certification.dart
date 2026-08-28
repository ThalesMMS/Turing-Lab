import 'dart:io';
import 'dart:math' as math;

import 'package:turing_lab/core/algorithms/tm_block_dependency_analyzer.dart';
import 'package:turing_lab/core/algorithms/tm_block_execution_engine.dart';
import 'package:turing_lab/core/algorithms/tm_block_inline_expander.dart';
import 'package:turing_lab/core/algorithms/tm_execution_analyzer.dart';
import 'package:turing_lab/core/algorithms/tm_execution_kernel.dart';
import 'package:turing_lab/core/algorithms/tm_language_explorer.dart';
import 'package:turing_lab/core/algorithms/tm_multi_tape_execution_analyzer.dart';
import 'package:turing_lab/core/algorithms/tm_reachability_analyzer.dart';
import 'package:turing_lab/core/algorithms/tm_simulator.dart';
import 'package:turing_lab/core/algorithms/tm_space_profiler.dart';
import 'package:turing_lab/core/algorithms/tm_time_profiler.dart';
import 'package:turing_lab/core/algorithms/tm_to_unrestricted_grammar/tm_to_unrestricted_grammar.dart';
import 'package:turing_lab/core/models/state.dart';
import 'package:turing_lab/core/models/tm.dart';
import 'package:turing_lab/core/models/tm_acceptance.dart';
import 'package:turing_lab/core/models/tm_building_blocks.dart';
import 'package:turing_lab/core/models/tm_execution_analysis.dart';
import 'package:turing_lab/core/models/tm_language_explorer_models.dart';
import 'package:turing_lab/core/models/tm_reachability_report.dart';
import 'package:turing_lab/core/models/tm_space_profile.dart';
import 'package:turing_lab/core/models/tm_time_profile.dart';
import 'package:turing_lab/core/models/tm_transition.dart';
import 'package:turing_lab/core/models/transition.dart';
import 'package:turing_lab/core/services/simulation_runner.dart';
import 'package:turing_lab/core/services/simulation_runner_backend_web.dart';
import 'package:turing_lab/core/services/tm_block_project_editor.dart';
import 'package:vector_math/vector_math_64.dart';

import '../generation.dart';
import 'tm_matrix.dart';
import 'tm_oracle.dart';
import 'tm_runtime_parity.dart';

enum TmCertificationStatus { passed, failed, incomplete }

final class TmCertificationCheck {
  const TmCertificationCheck({
    required this.id,
    required this.status,
    required this.message,
    this.evidence = const {},
  });

  final String id;
  final TmCertificationStatus status;
  final String message;
  final Map<String, Object?> evidence;

  Map<String, Object?> toJson() => {
        'evidence': evidence,
        'id': id,
        'message': message,
        'status': status.name,
      };
}

final class TmCertificationOptions {
  const TmCertificationOptions({
    this.seed = 338,
    this.cases = 12,
    this.maximumSteps = 64,
    this.maximumConfigurations = 512,
  });

  final int seed;
  final int cases;
  final int maximumSteps;
  final int maximumConfigurations;

  void validate() {
    if (seed < 0 || seed > 0xffffffff) {
      throw RangeError.range(seed, 0, 0xffffffff, 'seed');
    }
    if (cases <= 0 || cases > 128) {
      throw RangeError.range(cases, 1, 128, 'cases');
    }
    if (maximumSteps <= 0 || maximumSteps > 10000) {
      throw RangeError.range(maximumSteps, 1, 10000, 'maximumSteps');
    }
    if (maximumConfigurations <= 0 || maximumConfigurations > 100000) {
      throw RangeError.range(
        maximumConfigurations,
        1,
        100000,
        'maximumConfigurations',
      );
    }
  }
}

final class TmCertificationReport {
  TmCertificationReport({
    required this.options,
    required Iterable<TmCertificationCheck> checks,
  }) : checks = List<TmCertificationCheck>.unmodifiable(checks);

  final TmCertificationOptions options;
  final List<TmCertificationCheck> checks;

  TmCertificationStatus get status {
    if (checks.any((check) => check.status == TmCertificationStatus.failed)) {
      return TmCertificationStatus.failed;
    }
    if (checks.any(
      (check) => check.status == TmCertificationStatus.incomplete,
    )) {
      return TmCertificationStatus.incomplete;
    }
    return TmCertificationStatus.passed;
  }

  Map<String, Object?> toJson() => {
        'checks': checks.map((check) => check.toJson()).toList(),
        'family': 'tm',
        'inventory':
            tmAlgorithmInventory.map((entry) => entry.toJson()).toList(),
        'options': {
          'cases': options.cases,
          'maximumConfigurations': options.maximumConfigurations,
          'maximumSteps': options.maximumSteps,
          'seed': options.seed,
        },
        'remotelyVerified': false,
        'schemaVersion': 1,
        'status': status.name,
      };

  String toMarkdown() {
    final buffer = StringBuffer()
      ..writeln('# Turing-machine hard-edge certification')
      ..writeln()
      ..writeln('- Status: `${status.name}`')
      ..writeln('- Seed: `${options.seed}`')
      ..writeln('- Generated cases: `${options.cases}`')
      ..writeln('- Remotely verified: `false`')
      ..writeln()
      ..writeln('| Check | Status | Evidence |')
      ..writeln('| --- | --- | --- |');
    for (final check in checks) {
      buffer.writeln(
        '| `${check.id}` | `${check.status.name}` | '
        '${check.message.replaceAll('|', r'\|')} |',
      );
    }
    buffer
      ..writeln()
      ..writeln('## Inventory')
      ..writeln()
      ..writeln('| Algorithm | Source | Properties |')
      ..writeln('| --- | --- | --- |');
    for (final entry in tmAlgorithmInventory) {
      buffer.writeln(
        '| `${entry.id}` | `${entry.sourcePath}` | '
        '${entry.properties.map((property) => '`$property`').join(', ')} |',
      );
    }
    return buffer.toString();
  }
}

final class TmCertificationRunner {
  TmCertificationRunner({required Directory repositoryRoot})
      : repositoryRoot = repositoryRoot.absolute;

  final Directory repositoryRoot;

  Future<TmCertificationReport> run(TmCertificationOptions options) async {
    options.validate();
    final checks = <TmCertificationCheck>[];
    for (final property in tmPropertyIds) {
      await _runCheck(checks, property, () => _check(property, options));
    }
    _attachEntrypointEvidence(checks);
    return TmCertificationReport(options: options, checks: checks);
  }

  void _attachEntrypointEvidence(List<TmCertificationCheck> checks) {
    final passedProperties = checks
        .where((check) => check.status == TmCertificationStatus.passed)
        .map((check) => check.id)
        .toSet();
    final executed = <String>[];
    final missing = <String>[];
    for (final entry in tmAlgorithmInventory) {
      final property = tmEntrypointEvidencePropertyByAlgorithmId[entry.id];
      final probed = tmExecutedEntrypointsByAlgorithmId[entry.id];
      if (property == null || !entry.properties.contains(property)) {
        missing.add('${entry.id}:unmapped');
        continue;
      }
      final declared = entry.entryPoints.toSet();
      if (probed == null || !_setEquals(probed, declared)) {
        final absent = declared.difference(probed ?? const <String>{});
        final stale = (probed ?? const <String>{}).difference(declared);
        missing.add(
          '${entry.id}:entrypoint-drift(absent=${absent.join('|')},'
          'stale=${stale.join('|')})',
        );
        continue;
      }
      if (!passedProperties.contains(property)) {
        missing.add('${entry.id}:$property');
        continue;
      }
      executed.addAll(probed.map((entryPoint) => '${entry.id}::$entryPoint'));
    }
    final inventoryIndex =
        checks.indexWhere((check) => check.id == 'tm.inventory');
    final prior = checks[inventoryIndex];
    checks[inventoryIndex] = TmCertificationCheck(
      id: prior.id,
      status: missing.isEmpty ? prior.status : TmCertificationStatus.failed,
      message: missing.isEmpty
          ? '${prior.message} Executed ${executed.length} linked entry points.'
          : 'Inventory entry-point evidence was incomplete: ${missing.join(', ')}.',
      evidence: {
        ...prior.evidence,
        'executedEntrypoints': executed,
        'missingEntrypointEvidence': missing,
      },
    );
  }

  Future<TmCertificationCheck> runProperty(
    String property,
    TmCertificationOptions options,
  ) async {
    options.validate();
    if (!tmPropertyIds.contains(property)) {
      throw ArgumentError.value(property, 'property', 'is not registered');
    }
    final checks = <TmCertificationCheck>[];
    await _runCheck(checks, property, () => _check(property, options));
    return checks.single;
  }

  Future<_TmEvidence> _check(
    String property,
    TmCertificationOptions options,
  ) =>
      switch (property) {
        'tm.inventory' => _checkInventory(),
        'tm.model-serialization' => _checkModelSerialization(),
        'tm.oracle-parity' => _checkOracleParity(options),
        'tm.runner-parity' => _checkRunnerParity(),
        'tm.outcome-lattice' => _checkOutcomeLattice(),
        'tm.multi-tape-atomicity' => _checkMultiTapeAtomicity(),
        'tm.reachability-language' => _checkReachabilityLanguage(),
        'tm.metrics-trace' => _checkMetrics(),
        'tm.building-blocks' => _checkBuildingBlocks(),
        'tm.grammar-conversion' => _checkGrammarConversion(),
        'tm.trace-replay' => _checkTraceReplay(),
        'tm.generated-shrink' => _checkGeneratedShrink(),
        'tm.mutations' => _checkMutations(),
        _ => throw StateError('Unhandled TM property $property.'),
      };

  Future<void> _runCheck(
    List<TmCertificationCheck> checks,
    String id,
    Future<_TmEvidence> Function() check,
  ) async {
    try {
      final evidence = await check();
      checks.add(
        TmCertificationCheck(
          id: id,
          status: TmCertificationStatus.passed,
          message: evidence.message,
          evidence: evidence.values,
        ),
      );
    } on _TmIncomplete catch (error) {
      checks.add(
        TmCertificationCheck(
          id: id,
          status: TmCertificationStatus.incomplete,
          message: error.message,
        ),
      );
    } catch (error) {
      checks.add(
        TmCertificationCheck(
          id: id,
          status: TmCertificationStatus.failed,
          message: error.toString(),
        ),
      );
    }
  }

  Future<_TmEvidence> _checkInventory() async {
    final ids = <String>{};
    for (final entry in tmAlgorithmInventory) {
      _require(ids.add(entry.id), 'Duplicate inventory ID ${entry.id}.');
      _require(entry.entryPoints.isNotEmpty, '${entry.id} has no entry point.');
      _require(entry.properties.isNotEmpty, '${entry.id} has no property.');
      for (final property in entry.properties) {
        _require(
            tmPropertyIds.contains(property), 'Unknown property $property.');
      }
      final evidenceProperty =
          tmEntrypointEvidencePropertyByAlgorithmId[entry.id];
      final probedEntryPoints = tmExecutedEntrypointsByAlgorithmId[entry.id];
      _require(
        evidenceProperty != null && entry.properties.contains(evidenceProperty),
        '${entry.id} has no linked executable evidence property.',
      );
      _require(
        probedEntryPoints != null &&
            _setEquals(probedEntryPoints, entry.entryPoints.toSet()),
        '${entry.id} executable entry-point evidence drifted.',
      );
      final source = File(
        '${repositoryRoot.path}${Platform.pathSeparator}'
        '${entry.sourcePath.replaceAll('/', Platform.pathSeparator)}',
      );
      _require(
          source.existsSync(), 'Missing inventory source ${entry.sourcePath}.');
    }
    return _TmEvidence(
      'Audited ${tmAlgorithmInventory.length} live TM implementation paths.',
      {'algorithms': tmAlgorithmInventory.length},
    );
  }

  Future<_TmEvidence> _checkModelSerialization() async {
    final machine = _twoTapeTransfer();
    final restored = TM.fromJson(machine.toJson());
    final transition = machine.tmTransitions.single;
    final transitionRoundTrip = TMTransition.fromJson(
      transition.toJson(),
      statesById: {for (final state in machine.states) state.id: state},
    );
    _require(restored.documentVariant == TMDocumentVariant.multiTape,
        'Multi-tape variant was not preserved.');
    _require(restored.tmTransitions.single.readSymbols.join('|') == 'a|B',
        'Operation vectors changed during JSON replay.');
    _require(
      TMTransition.formatLabel(
            readSymbol: 'a',
            writeSymbol: 'B',
            direction: TapeDirection.right,
          ) ==
          'a/B,R',
      'Scalar transition label formatting changed.',
    );
    _require(
      TMTransition.formatVectorLabel(
        readSymbols: const ['a', 'B'],
        writeSymbols: const ['B', 'a'],
        directions: const [TapeDirection.right, TapeDirection.left],
      ).contains('T2:'),
      'Vector label omitted a tape.',
    );
    _require(
      transition.operationsForTapeCount(2, 'B').writeSymbols.join('|') ==
              'B|a' &&
          transitionRoundTrip.readSymbols.join('|') == 'a|B',
      'Transition operation/JSON entry points changed vectors.',
    );
    final paddedA = TMConfigurationSnapshot.canonicalMulti(
      stateId: 'q0',
      headPositions: const [-1, 2],
      tapes: const [
        {-2: 'B', 0: 'a', 5: 'B'},
        {2: 'x'},
      ],
      blankSymbol: 'B',
    );
    final paddedB = TMConfigurationSnapshot.canonicalMulti(
      stateId: 'q0',
      headPositions: const [-1, 2],
      tapes: const [
        {0: 'a'},
        {2: 'x'},
      ],
      blankSymbol: 'B',
    );
    _require(
        paddedA.key == paddedB.key, 'Outer blank padding changed identity.');
    final errors = machine.copyWith(tapeCount: 3).validate();
    _require(errors.any((error) => error.contains('tape count 3')),
        'Vector/tape mismatch was accepted.');
    return const _TmEvidence(
      'JSON vectors, variants, canonical padding, and invalid lengths agree.',
      {'tapes': 2, 'negativeHead': -1},
    );
  }

  Future<_TmEvidence> _checkOracleParity(TmCertificationOptions options) async {
    final oracle = IndependentTmOracle(
      maximumSteps: options.maximumSteps,
      maximumConfigurations: options.maximumConfigurations,
    );
    final compared = <String>[];
    for (var index = 0; index < options.cases; index++) {
      final random = StableRandom.forCase(
        options.seed,
        index,
        streamId: 'tm/oracle-parity/v1',
      );
      final direction = TapeDirection.values[random.nextInt(3)];
      final machine = _generatedDecisionMachine(index, direction);
      const input = ['a'];
      final expected = oracle.run(machine, input);
      final actual = await TMExecutionAnalyzer.analyzeTokens(
        machine,
        input,
        maxSteps: options.maximumSteps,
        maxConfigurations: options.maximumConfigurations,
      );
      _require(
        _oracleOutcome(actual.outcome) == expected.outcome,
        'Oracle mismatch for case $index and ${input.join()}.',
      );
      _requireGeneratedConfigurationAgreement(
        machine,
        expected,
        actual,
        'case $index',
      );
      compared.add(
        '${machine.tapeCount}:${direction.name}:${expected.outcome.name}',
      );
    }
    final ntmCases = <(String, TM, TmOracleOutcome)>[
      (
        'accept-after-reject',
        _acceptingAfterRejectingBranchNtm(),
        TmOracleOutcome.accepted
      ),
      ('accept-and-cycle', _acceptingAndCyclicNtm(), TmOracleOutcome.accepted),
      ('finite-cycle', _finiteCyclicNtm(), TmOracleOutcome.haltedRejected),
    ];
    for (final (label, ntm, outcome) in ntmCases) {
      final expected = oracle.run(ntm, const []);
      final actual = await TMExecutionAnalyzer.analyze(ntm, '');
      _require(
        expected.outcome == outcome &&
            _oracleOutcome(actual.outcome) == outcome,
        'Varied NTM oracle mismatch for $label.',
      );
      compared.add('ntm:$label:${outcome.name}');
    }
    return _TmEvidence(
      'Independent sparse-tape BFS agreed on ${options.cases + ntmCases.length} '
      'write/head/configuration-sensitive DTM and varied NTM cases.',
      {'cases': compared},
    );
  }

  Future<_TmEvidence> _checkRunnerParity() async {
    final machine = _singleSymbolAcceptor();
    final serialized = TM.fromJson(machine.toJson());
    final sync = TMSimulator.simulate(serialized, 'a', stepByStep: true);
    final dtm = TMSimulator.simulateDTM(serialized, 'a', stepByStep: true);
    final cooperative = await TMSimulator.simulateCooperative(
      serialized,
      'a',
      operationsPerBatch: 1,
    );
    final native = await SimulationRunner()
        .runTm(serialized, 'a', stepByStep: true)
        .outcome;
    final web = await createWebSimulationRunnerBackend()
        .runTm(
          serialized,
          'a',
          stepByStep: true,
          timeout: const Duration(seconds: 5),
        )
        .outcome;
    _require(sync.isSuccess && dtm.isSuccess && cooperative.isSuccess,
        'A direct simulator failed.');
    final outcomes = {
      sync.data!.outcome,
      dtm.data!.outcome,
      cooperative.data!.outcome,
      native.result?.outcome,
      web.result?.outcome,
    };
    _require(
        outcomes.length == 1 && outcomes.single == TMExecutionOutcome.accepted,
        'Sync/native/web outcomes diverged: $outcomes.');
    _require(TMSimulator.accepts(machine, 'a').data == true,
        'accepts adapter disagreed.');
    _require(TMSimulator.rejects(machine, '').data == true,
        'rejects adapter disagreed.');
    _require(
      TMSimulator.findAcceptedStrings(machine, 1).data!.contains('a'),
      'Accepted-language adapter omitted a.',
    );
    _require(
      TMSimulator.findRejectedStrings(machine, 1).data!.contains(''),
      'Rejected-language adapter omitted epsilon.',
    );
    _require(TMSimulator.analyzeTM(machine).isSuccess,
        'Structural TM analysis failed.');

    final ntm = _acceptingAndCyclicNtm();
    _require(TMSimulator.simulateNTM(ntm, '').data!.accepted,
        'NTM entry point missed the accepting branch.');
    final nativeLimit = await SimulationRunner()
        .runTm(
          _movingForever(),
          '',
          stepByStep: false,
          timeout: const Duration(microseconds: 1),
        )
        .outcome;
    final webLimit = await createWebSimulationRunnerBackend()
        .runTm(
          _movingForever(),
          '',
          stepByStep: false,
          timeout: const Duration(microseconds: 1),
        )
        .outcome;
    _require(
      nativeLimit.kind == SimulationOutcomeKind.timeout &&
          webLimit.kind == SimulationOutcomeKind.timeout,
      'Native/web limit semantics diverged: '
      '${nativeLimit.kind}/${webLimit.kind}.',
    );
    final stepLimit = await TMExecutionAnalyzer.analyze(
      _movingForever(),
      '',
      maxSteps: 3,
    );
    final configurationLimit = await TMExecutionAnalyzer.analyze(
      _movingForever(),
      '',
      maxSteps: 100,
      maxConfigurations: 2,
    );
    final typedTimeout = await TMExecutionAnalyzer.analyze(
      _movingForever(),
      '',
      maxSteps: 10000,
      timeout: const Duration(microseconds: 1),
    );
    final nativeCancellation = SimulationRunner().runTm(
      _movingForever(),
      '',
      stepByStep: false,
      timeout: const Duration(seconds: 5),
    )..cancel();
    final webCancellation = createWebSimulationRunnerBackend().runTm(
      _movingForever(),
      '',
      stepByStep: false,
      timeout: const Duration(seconds: 5),
    )..cancel();
    final nativeCancel = await nativeCancellation.outcome;
    final webCancel = await webCancellation.outcome;
    final nativeSnapshot = _runtimeSnapshot(
      accepted: native,
      stepLimit: stepLimit,
      configurationLimit: configurationLimit,
      typedTimeout: typedTimeout,
      timeoutKind: nativeLimit.kind,
      cancelKind: nativeCancel.kind,
    );
    final webSnapshot = _runtimeSnapshot(
      accepted: web,
      stepLimit: stepLimit,
      configurationLimit: configurationLimit,
      typedTimeout: typedTimeout,
      timeoutKind: webLimit.kind,
      cancelKind: webCancel.kind,
    );
    _require(
      _mapEquals(nativeSnapshot, tmCanonicalRuntimeSnapshot) &&
          _mapEquals(webSnapshot, tmCanonicalRuntimeSnapshot),
      'Native/web typed runtime snapshots diverged: '
      '$nativeSnapshot/$webSnapshot.',
    );
    return _TmEvidence(
      'Sync, DTM, NTM, native worker, and cooperative web paths agreed on '
      'acceptance and typed step/configuration/timeout/cancel outcomes.',
      {
        'outcome': 'accepted',
        'runners': 5,
        'runtimeSnapshot': nativeSnapshot,
      },
    );
  }

  Future<_TmEvidence> _checkOutcomeLattice() async {
    final accepted = await TMExecutionAnalyzer.analyze(_blankAcceptor(), '');
    final rejected = await TMExecutionAnalyzer.analyze(_rejector(), '');
    final cycle = await TMExecutionAnalyzer.analyze(_stationaryCycle(), '');
    final bounded = await TMExecutionAnalyzer.analyze(
      _movingForever(),
      '',
      maxSteps: 3,
    );
    final configurationBound = await TMExecutionAnalyzer.analyze(
      _movingForever(),
      '',
      maxSteps: 100,
      maxConfigurations: 2,
    );
    final timeout = await TMExecutionAnalyzer.analyze(
      _movingForever(),
      '',
      maxSteps: 10000,
      timeout: const Duration(microseconds: 1),
    );
    final cancelled = await TMExecutionAnalyzer.analyze(
      _movingForever(),
      '',
      isCancelled: () => true,
    );
    final invalid = await TMExecutionAnalyzer.analyze(
      _machine(id: 'invalid', states: const []),
      '',
    );
    final outcomes = {
      accepted.outcome,
      rejected.outcome,
      cycle.outcome,
      bounded.outcome,
      cancelled.outcome,
      invalid.outcome,
    };
    _require(outcomes.length == 6, 'Typed outcome categories collapsed.');
    _require(
        timeout.outcome == TMExecutionOutcome.boundedUnknown &&
            timeout.limit == TMExecutionLimit.timeout,
        'Timeout became rejection.');
    _require(bounded.limit == TMExecutionLimit.steps, 'Step bound was lost.');
    _require(
      configurationBound.outcome == TMExecutionOutcome.boundedUnknown &&
          configurationBound.limit == TMExecutionLimit.configurations,
      'Configuration bound became rejection or a step limit.',
    );
    final finalStateDecision = TMAcceptancePolicyEvaluator.evaluate(
      policy: TMAcceptancePolicy.finalState,
      isFinalState: true,
      isHalted: false,
    );
    final haltingDecision = TMAcceptancePolicyEvaluator.evaluate(
      policy: TMAcceptancePolicy.halting,
      isFinalState: false,
      isHalted: true,
    );
    final rejectedDecision = TMAcceptancePolicyEvaluator.evaluate(
      policy: TMAcceptancePolicy.finalState,
      isFinalState: false,
      isHalted: true,
    );
    _require(
      finalStateDecision?.accepted == true &&
          haltingDecision?.accepted == true &&
          rejectedDecision?.accepted == false,
      'Acceptance policy evaluation collapsed final-state and halting rules.',
    );
    final finiteNtm = await TMExecutionAnalyzer.analyze(_finiteCyclicNtm(), '');
    _require(
      finiteNtm.outcome == TMExecutionOutcome.haltedRejected &&
          finiteNtm.repeatedConfigurationsObserved > 0,
      'Finite NTM rejection did not exhaust repeated configurations.',
    );
    return const _TmEvidence(
      'Accepted, rejected, cycle, bounded, timeout, cancelled, and invalid stayed distinct.',
      {'typedOutcomes': 7},
    );
  }

  Future<_TmEvidence> _checkMultiTapeAtomicity() async {
    final machine = _twoTapeTransfer();
    final source = TMExecutionKernel.initialTapesTokens(const ['a'], 'B', 2);
    final heads = [0, 0];
    final transition = machine.tmTransitions.single;
    final readVector = TMExecutionKernel.readVector(source, heads, 'B');
    final initialSnapshot = TMExecutionKernel.snapshotMulti(
      stateId: machine.initialState!.id,
      headPositions: heads,
      tapes: source,
      blankSymbol: 'B',
    );
    _require(
      TMExecutionKernel.transitionsForVector(
                  machine, machine.initialState!, readVector)
              .single
              .id ==
          transition.id,
      'Complete read vector did not enable the transition.',
    );
    _require(
      TMExecutionKernel.transitionsForVector(
          machine, machine.initialState!, ['a', 'x']).isEmpty,
      'A partial vector match enabled the transition.',
    );
    final applied = TMExecutionKernel.applyTransition(
      sourceTapes: source,
      sourceHeads: heads,
      transition: transition,
      blankSymbol: 'B',
    );
    _require(source[0][0] == 'a' && source[1].isEmpty,
        'Atomic application mutated its input tapes.');
    _require(applied.tapes[0].isEmpty && applied.tapes[1][0] == 'a',
        'Atomic writes did not update both tapes.');
    _require(
        applied.heads.join(',') == '1,-1', 'Head vectors were not atomic.');
    _require(
      initialSnapshot.headPositions.join(',') == '0,0' &&
          TMExecutionKernel.moveHead(0, TapeDirection.left) == -1,
      'Snapshot or unbounded head movement entry point diverged.',
    );
    final metricsAccumulator = TMTraceMetricsAccumulator(
      blankSymbol: 'B',
      initialTape: const {0: 'a'},
    )..record(
        transition: _transition(
          'metric-write',
          machine.initialState!,
          machine.acceptingStates.single,
          read: 'a',
          write: 'x',
          direction: TapeDirection.left,
        ),
        oldSymbol: 'a',
        headBefore: 0,
        headAfter: -1,
        step: 1,
      );
    final directMetrics = metricsAccumulator.finish(
      tm: _singleSymbolAcceptor(),
      branchSelection: TMExecutionBranchSelection.deterministic,
      retainedTraceSnapshots: 1,
    );
    _require(
      directMetrics.changedWrites == 1 &&
          directMetrics.minimumHeadPosition == -1,
      'Direct trace-metrics accumulator entry point was not write/head aware.',
    );
    final analyzed = await TMExecutionAnalyzer.analyze(machine, 'a');
    _require(analyzed.outcome == TMExecutionOutcome.accepted,
        'Two-tape execution did not accept.');
    final direct = await TMMultiTapeExecutionAnalyzer.analyze(
      machine,
      'a',
      maxSteps: 8,
      maxConfigurations: 32,
      timeout: const Duration(seconds: 1),
      operationsPerBatch: 4,
      includeTrace: true,
    );
    final directTokens = await TMMultiTapeExecutionAnalyzer.analyzeTokens(
      machine,
      'a',
      const ['a'],
      maxSteps: 8,
      maxConfigurations: 32,
      timeout: const Duration(seconds: 1),
      operationsPerBatch: 4,
      includeTrace: true,
    );
    _require(
      direct.outcome == TMExecutionOutcome.accepted &&
          direct.multiTapeTrace.length == 1 &&
          directTokens.outcome == direct.outcome,
      'Direct multi-tape analyzer path diverged.',
    );

    final threeTape = await TMMultiTapeExecutionAnalyzer.analyze(
      _threeTapeWriter(),
      '',
      maxSteps: 8,
      maxConfigurations: 32,
      timeout: const Duration(seconds: 1),
      operationsPerBatch: 4,
      includeTrace: true,
    );
    final finalThreeTape = threeTape.multiTapeTrace.last.configuration;
    _require(
      threeTape.outcome == TMExecutionOutcome.accepted &&
          finalThreeTape.nonBlankCellsByTape.length == 3 &&
          finalThreeTape.nonBlankCellsByTape[0][0] == 'x' &&
          finalThreeTape.nonBlankCellsByTape[1][0] == 'y' &&
          finalThreeTape.nonBlankCellsByTape[2][0] == 'z',
      'Three-tape writes were not applied atomically.',
    );
    final repeatedMulti = await TMMultiTapeExecutionAnalyzer.analyze(
      _stationaryMultiTapeCycle(),
      '',
      maxSteps: 8,
      maxConfigurations: 32,
      timeout: const Duration(seconds: 1),
      operationsPerBatch: 4,
      includeTrace: false,
    );
    _require(
      repeatedMulti.outcome == TMExecutionOutcome.provenCycle &&
          repeatedMulti.repeatedConfigurationsObserved > 0,
      'Multi-tape configuration identity did not detect a stationary cycle.',
    );

    final single = _singleSymbolAcceptor();
    final oneTapeVector = _vectorizedCopy(single);
    final scalarResult = await TMExecutionAnalyzer.analyze(single, 'a');
    final vectorResult = await TMExecutionAnalyzer.analyze(oneTapeVector, 'a');
    _require(
        scalarResult.outcome == vectorResult.outcome &&
            scalarResult.stepsExecuted == vectorResult.stepsExecuted,
        'k=1 vector execution diverged from scalar semantics.');
    return const _TmEvidence(
      'Two-tape reads/writes/moves were atomic and k=1 collapsed exactly.',
      {
        'headPositions': [1, -1],
        'tapeCounts': [1, 2]
      },
    );
  }

  Future<_TmEvidence> _checkReachabilityLanguage() async {
    final q0 = _state('q0', initial: true);
    final direct = _state('direct');
    final guarded = _state('guarded');
    final machine = _machine(
      id: 'reachability',
      states: [q0, direct, guarded],
      alphabet: const {'a'},
      tapeAlphabet: const {'a', 'B'},
      transitions: [
        _transition('z-direct', q0, direct, read: 'B'),
        _transition('never', q0, guarded, read: 'a'),
      ],
    );
    final reachability = await TMReachabilityAnalyzer.analyze(
      machine,
      inputs: const [''],
    );
    _require(reachability.status == TMReachabilityStatus.complete,
        'Reachability did not complete.');
    _require(
        reachability.structurallyReachableStateIds.contains('guarded') &&
            !reachability.reachedWithinBoundsStateIds.contains('guarded'),
        'Structural and semantic reachability collapsed.');
    _require(reachability.witnessesByStateId['direct']?.step == 1,
        'BFS did not retain the shortest witness.');

    final language = await TMLanguageExplorer.explore(
      _languageOutcomeMachine(),
      limits: const TMLanguageExplorerLimits(
        maxInputLength: 1,
        maxCandidates: 5,
        maxStepsPerInput: 3,
      ),
    );
    _require(
      TMReachabilityAnalyzer.structurallyReachableStateIds(machine)
              .contains('guarded') &&
          TMLanguageExplorer.countCandidates(const ['a'], 1) == BigInt.from(2),
      'Declared reachability/language counting entry points diverged.',
    );
    _require(language.isSuccess, language.error ?? 'Language explorer failed.');
    final classes =
        language.data!.results.map((result) => result.outcome).toSet();
    _require(
        classes.containsAll({
          TMLanguageOutcome.accepted,
          TMLanguageOutcome.rejected,
          TMLanguageOutcome.provenCycle,
          TMLanguageOutcome.inconclusive,
        }),
        'Language exploration merged a typed outcome.');
    return const _TmEvidence(
      'Structural/semantic reachability and four language outcomes remained separate.',
      {'languageOutcomes': 4},
    );
  }

  Future<_TmEvidence> _checkMetrics() async {
    final machine = _rightScanner();
    final execution = await TMExecutionAnalyzer.analyze(machine, 'aaa');
    _require(execution.outcome == TMExecutionOutcome.accepted,
        'Metric witness did not accept.');
    _require(execution.stepsExecuted == 4, 'Transition count was not four.');
    _require(execution.traceMetrics?.readCounts['a'] == 3,
        'Read counters lost input symbols.');
    _require(execution.traceMetrics?.movementCounts['right'] == 3,
        'Movement counters lost right moves.');
    _require(execution.spaceMetrics?.maximumVisitedSpan == 4,
        'Visited tape span was not four.');

    final space = await TMSpaceProfiler.profile(
      machine,
      limits: const TMSpaceProfileLimits(maxInputLength: 2),
    );
    _require(
        space.isSuccess && space.data!.rows[2].maximumVisitedSpan?.value == 3,
        'Space profile invariant failed.');
    final time = await TMTimeProfiler.profile(
      machine,
      bounds: const TMTimeProfileBounds(maxLength: 2),
    );
    _require(time.status == TMTimeProfileStatus.complete,
        'Time profile was incomplete.');
    _require(
        time.rows.map((row) => row.maximumTransitionSteps).join(',') == '1,2,3',
        'Time profile did not count transitions directly.');
    const profileLimits = TMSpaceProfileLimits(
      maxInputLength: 2,
      maxCandidatesPerLength: 2,
    );
    _require(
      TMSpaceProfiler.countCandidatesForLength(const ['a', 'b'], 2) ==
              BigInt.from(4) &&
          TMSpaceProfiler.countCandidatesThroughLength(
                const ['a', 'b'],
                2,
              ) ==
              BigInt.from(7) &&
          TMSpaceProfiler.countScheduledCandidates(
                const ['a', 'b'],
                profileLimits,
              ) ==
              5,
      'Space profiler candidate accounting diverged.',
    );
    final plan = TMTimeProfiler.plan(
      machine,
      bounds: const TMTimeProfileBounds(
        maxLength: 2,
        maxCandidatesPerLength: 2,
      ),
    );
    _require(
      plan.isValid && plan.plannedCandidateCount == 3 && plan.rows.length == 3,
      'Time profiler planning did not preserve bounded candidate counts.',
    );
    return const _TmEvidence(
      'Trace counters, visited span, space profile, and transition time agreed.',
      {'input': 'aaa', 'steps': 4, 'visitedSpan': 4},
    );
  }

  Future<_TmEvidence> _checkBuildingBlocks() async {
    final project = _sharedTapeProject();
    final dependencies = TMBlockDependencyAnalyzer.analyze(project);
    _require(dependencies.isValid, 'Valid block dependency graph failed.');
    final nested = TMBlockExecutionEngine.execute(project, '0');
    _require(
        nested.outcome == TMExecutionOutcome.accepted &&
            nested.finalTapes.single[0] == '1',
        'Nested execution did not share tape contents.');
    _require(
        nested.metrics.blockEntries == 1 && nested.metrics.blockReturns == 1,
        'Call/return metrics were not retained.');
    final expandedA = TMBlockInlineExpander.expand(project);
    final expandedB = TMBlockInlineExpander.expand(project);
    _require(
        expandedA.isSuccess && expandedB.isSuccess, 'Inline expansion failed.');
    _require(
      _sortedStateIds(expandedA.machine!) ==
          _sortedStateIds(expandedB.machine!),
      'Inline IDs were nondeterministic.',
    );
    final flat = await TMExecutionAnalyzer.analyze(expandedA.machine!, '0');
    _require(flat.outcome == nested.outcome,
        'Inline expansion changed block semantics.');
    _require(
      expandedA.stateSources.values.any(
        (source) =>
            source.machineId == 'writer' &&
            source.invocationPath.join('/') == 'call-writer',
      ),
      'Inline expansion omitted invocation source provenance.',
    );

    final nestedProject = _nestedProject();
    final nestedResult = TMBlockExecutionEngine.execute(nestedProject, '0');
    final nestedExpansion = TMBlockInlineExpander.expand(nestedProject);
    _require(
      nestedResult.outcome == TMExecutionOutcome.accepted &&
          nestedResult.metrics.maximumCallDepth == 2 &&
          nestedResult.metrics.blockEntries == 2 &&
          nestedResult.metrics.blockReturns == 2 &&
          nestedExpansion.isSuccess &&
          nestedExpansion.stateSources.values.any(
            (source) =>
                source.machineId == 'inner' &&
                source.invocationPath.length == 2,
          ),
      'Nested call/return or depth-two source mapping diverged.',
    );

    final recursive = _recursiveProject();
    final recursiveReport = TMBlockDependencyAnalyzer.analyze(recursive);
    final recursiveExecution = TMBlockExecutionEngine.execute(recursive, '');
    _require(
        !recursiveReport.isValid &&
            recursiveExecution.outcome == TMExecutionOutcome.invalidMachine,
        'Direct recursion policy was not enforced.');
    final indirect = _indirectRecursiveProject();
    _require(
      !TMBlockDependencyAnalyzer.analyze(indirect).isValid &&
          TMBlockExecutionEngine.execute(indirect, '').outcome ==
              TMExecutionOutcome.invalidMachine,
      'Indirect recursion policy was not enforced.',
    );
    final invalidReferences = _invalidReferenceProject();
    final invalidCodes = TMBlockDependencyAnalyzer.analyze(invalidReferences)
        .diagnostics
        .map((diagnostic) => diagnostic.code)
        .toSet();
    _require(
      invalidCodes.contains(TMBlockDiagnosticCode.missingReference) &&
          invalidCodes.contains(TMBlockDiagnosticCode.revisionMismatch),
      'Missing and stale building-block references were not distinguished.',
    );

    final editor = TMBlockProjectEditor(project);
    _require(
      editor
          .upsertInvocation(
            ownerMachineId: project.rootMachine.id,
            invocation: project.rootInvocations.single,
          )
          .isSuccess,
      'Invocation upsert entry point failed on an unchanged valid node.',
    );
    _require(
      editor.renameDefinition('writer', 'Writer renamed').isSuccess,
      'Block rename failed.',
    );
    final replacement = editor.project.definitions['writer']!.machine.copyWith(
      name: 'Writer replacement',
    );
    _require(
      editor.replaceDefinitionMachine('writer', replacement).isSuccess &&
          editor.project.definitions['writer']!.revision == 2 &&
          editor.project.rootInvocations.single.reference.revision == 2,
      'Block replacement did not update revisioned references atomically.',
    );
    _require(
      editor.deleteDefinition('writer').errorCode ==
          TMBlockEditErrorCode.referencedBlock,
      'Referenced block deletion did not require an explicit resolution.',
    );
    _require(
      editor
              .deleteDefinition(
                'writer',
                resolution: TMBlockDeleteResolution.detachInvocations,
              )
              .isSuccess &&
          editor.project.definitions.isEmpty &&
          editor.undo().project.definitions.containsKey('writer') &&
          editor.redo().project.definitions.isEmpty,
      'Delete/undo/redo did not preserve project history.',
    );
    _require(
      TMBlockExecutionEngine.execute(project, '0', maxSteps: 1).outcome ==
          TMExecutionOutcome.boundedUnknown,
      'Nested step limit was not preserved.',
    );
    _require(
      TMBlockExecutionEngine.execute(project, '0', isCancelled: () => true)
              .outcome ==
          TMExecutionOutcome.cancelled,
      'Nested cancellation was not preserved.',
    );
    return const _TmEvidence(
      'Calls shared tape/head state, inline expansion agreed, and recursion was rejected.',
      {'blockEntries': 1, 'blockReturns': 1},
    );
  }

  Future<_TmEvidence> _checkGrammarConversion() async {
    final machine = _grammarMovementMachine();
    final report = TMToGrammarConverter.build(machine, sourceRevision: 338);
    _require(report.outcome == TMToGrammarOutcome.completed,
        'TM to grammar conversion failed.');
    final families =
        report.productionProvenance.map((item) => item.family).toSet();
    _require(
        families.containsAll({
          TMToGrammarProductionFamily.moveRight,
          TMToGrammarProductionFamily.moveLeft,
          TMToGrammarProductionFamily.stay,
          TMToGrammarProductionFamily.boundaryBlank,
          TMToGrammarProductionFamily.acceptingState,
          TMToGrammarProductionFamily.cleanupLeft,
          TMToGrammarProductionFamily.cleanupRight,
        }),
        'A production family was omitted.');
    _require(
        report.productionProvenance.length ==
            report.grammar!.productions.length,
        'Production provenance was incomplete.');

    final immediate = _blankAcceptor(alphabet: const {'a'});
    final immediateReport = TMToGrammarConverter.build(
      immediate,
      sourceRevision: 338,
    );
    final differential = await TMToGrammarDifferentialChecker.check(
      immediate,
      immediateReport,
      const [
        [],
        ['a'],
      ],
      grammarMaxExpandedForms: 10000,
      grammarMaxVisitedForms: 20000,
    );
    _require(
        !differential.hasMismatch, 'Bounded TM/grammar evidence diverged.');
    _require(!differential.isProof, 'Sampled evidence claimed proof.');
    final unsupported = TMToGrammarConverter.build(
      _twoTapeTransfer(),
      sourceRevision: 338,
    );
    _require(unsupported.outcome == TMToGrammarOutcome.unsupportedMachine,
        'Multi-tape conversion was approximated.');
    return _TmEvidence(
      'All production families had provenance and bounded samples agreed.',
      {'families': families.length, 'samples': differential.samples.length},
    );
  }

  Future<_TmEvidence> _checkTraceReplay() async {
    final machine = _twoTapeTransfer();
    final result = await TMExecutionAnalyzer.analyze(machine, 'a');
    var tapes = TMExecutionKernel.initialTapesTokens(const ['a'], 'B', 2);
    var heads = [0, 0];
    var state = machine.initialState!;
    for (final recorded in result.multiTapeTrace) {
      final read = TMExecutionKernel.readVector(tapes, heads, 'B');
      final transition = TMExecutionKernel.transitionsForVector(
        machine,
        state,
        read,
      ).singleWhere((candidate) => candidate.id == recorded.transitionId);
      final applied = TMExecutionKernel.applyTransition(
        sourceTapes: tapes,
        sourceHeads: heads,
        transition: transition,
        blankSymbol: 'B',
      );
      tapes = applied.tapes;
      heads = applied.heads;
      state = transition.toState;
      _require(
        recorded.configuration.key ==
            TMExecutionKernel.snapshotMulti(
              stateId: state.id,
              headPositions: heads,
              tapes: tapes,
              blankSymbol: 'B',
            ).key,
        'Trace replay diverged at ${transition.id}.',
      );
    }
    _require(state.isAccepting && result.outcome == TMExecutionOutcome.accepted,
        'Trace final state disagreed with the outcome.');
    return const _TmEvidence(
      'Every vector operation replayed to the recorded final configuration.',
      {'steps': 1, 'tapes': 2},
    );
  }

  Future<_TmEvidence> _checkGeneratedShrink() async {
    final fixture = tmShrinkProbeFixture();
    _require(tmFailureFixtureIsValid(fixture), 'Shrink seed was invalid.');
    _require(tmFailureFixtureIsApplicable(fixture),
        'Shrink seed did not kill its mutant.');
    final candidates = tmFailureFixtureCandidates(fixture).toList();
    _require(candidates.isNotEmpty, 'TM shrinker emitted no candidates.');
    _require(
      candidates.any(
        (candidate) =>
            tmFailureFixtureIsValid(candidate) &&
            tmFailureFixtureIsApplicable(candidate),
      ),
      'TM shrinker emitted no valid smaller failure.',
    );
    final minimized = minimizeTmFailureFixture(fixture);
    _require(
      tmFailureFixtureSignature(minimized) ==
          tmFailureFixtureSignature(fixture),
      'TM shrink changed the failure/divergence signature.',
    );
    _require(
      tmFailureFixtureIsMinimal(minimized),
      'TM shrink stopped before a real one-deletion fixed point.',
    );
    return _TmEvidence(
      'Machine/input shrink preserved the exact mutant divergence and reached '
      'a validated one-deletion fixed point.',
      {
        'candidates': candidates.length,
        'minimalInputTokens':
            (_objectMap(minimized)['inputTokens'] as List).length,
        'minimalTransitions':
            (_objectMap(_objectMap(minimized)['machine'])['transitions']
                    as List)
                .length,
        'signature': tmFailureFixtureSignature(minimized),
      },
    );
  }

  Future<_TmEvidence> _checkMutations() async {
    final killed = <String>[];
    final productionPassed = <String>[];
    for (final operator in tmMutationOperatorIds) {
      final probe = await runTmMutationProbe(operator);
      if (probe.productionPassed) productionPassed.add(operator);
      if (probe.killed) killed.add(operator);
    }
    _require(
      productionPassed.length == tmMutationOperatorIds.length,
      'Production failed its oracle/property for '
      '${tmMutationOperatorIds.difference(productionPassed.toSet()).join(', ')}.',
    );
    _require(killed.length == tmMutationOperatorIds.length,
        'Mutation score was ${killed.length}/${tmMutationOperatorIds.length}.');
    return _TmEvidence(
      'Killed all ${killed.length} registered semantic mutants.',
      {'killed': killed, 'minimumScore': tmMutationMinimumScore},
    );
  }
}

final class TmMutationProbeResult {
  const TmMutationProbeResult({
    required this.operatorId,
    required this.productionPassed,
    required this.mutantRejected,
  });

  final String operatorId;
  final bool productionPassed;
  final bool mutantRejected;

  bool get killed => productionPassed && mutantRejected;
}

const tmMutationMinimumScore = 1.0;

const tmMutationOperatorIds = <String>{
  'clamp-left-head-at-zero',
  'partial-multi-tape-read-match',
  'reject-on-first-halted-ntm-branch',
  'skip-building-block-return',
};

Future<bool> tmMutationProbeKilled(String operatorId) async =>
    (await runTmMutationProbe(operatorId)).killed;

Future<TmMutationProbeResult> runTmMutationProbe(String operatorId) async {
  switch (operatorId) {
    case 'clamp-left-head-at-zero':
      final machine = _leftAcceptor();
      final expected = const IndependentTmOracle().run(machine, const []);
      final expectedHead = expected.trace.single.heads.single;
      final productionHead = TMExecutionKernel.moveHead(0, TapeDirection.left);
      final mutantHead = _mutantMoveHeadClampAtZero(0, TapeDirection.left);
      return TmMutationProbeResult(
        operatorId: operatorId,
        productionPassed: expected.outcome == TmOracleOutcome.accepted &&
            productionHead == expectedHead,
        mutantRejected: mutantHead != expectedHead,
      );
    case 'partial-multi-tape-read-match':
      final machine = _twoTapeTransfer();
      const reads = ['a', 'x'];
      final expected = machine.tmTransitions
          .where((transition) => _independentVectorMatch(
                transition,
                reads,
                machine.tapeCount,
                machine.blankSymbol,
              ))
          .map((transition) => transition.id)
          .toSet();
      final production = TMExecutionKernel.transitionsForVector(
        machine,
        machine.initialState!,
        reads,
      ).map((transition) => transition.id).toSet();
      final mutant = _mutantPartialVectorTransitions(
        machine,
        machine.initialState!,
        reads,
      ).map((transition) => transition.id).toSet();
      return TmMutationProbeResult(
        operatorId: operatorId,
        productionPassed: _setEquals(production, expected),
        mutantRejected: !_setEquals(mutant, expected),
      );
    case 'reject-on-first-halted-ntm-branch':
      final machine = _acceptingAfterRejectingBranchNtm();
      final expected = const IndependentTmOracle().run(machine, const []);
      final production = await TMExecutionAnalyzer.analyze(machine, '');
      final mutant = _mutantRejectOnFirstHaltedBranch(machine);
      return TmMutationProbeResult(
        operatorId: operatorId,
        productionPassed: expected.outcome == TmOracleOutcome.accepted &&
            production.outcome == TMExecutionOutcome.accepted,
        mutantRejected: mutant != expected.outcome,
      );
    case 'skip-building-block-return':
      final project = _sharedTapeProject();
      final production = TMBlockExecutionEngine.execute(project, '0');
      final expanded = TMBlockInlineExpander.expand(project);
      final expected = await TMExecutionAnalyzer.analyze(
        expanded.machine!,
        '0',
      );
      final mutant = await _mutantSkipBuildingBlockReturn(project, '0');
      return TmMutationProbeResult(
        operatorId: operatorId,
        productionPassed: expanded.isSuccess &&
            production.outcome == expected.outcome &&
            production.outcome == TMExecutionOutcome.accepted,
        mutantRejected: mutant != expected.outcome,
      );
    default:
      throw ArgumentError.value(operatorId, 'operatorId', 'unknown mutant');
  }
}

int _mutantMoveHeadClampAtZero(int head, TapeDirection direction) => math.max(
      0,
      head +
          switch (direction) {
            TapeDirection.left => -1,
            TapeDirection.right => 1,
            TapeDirection.stay => 0,
          },
    );

bool _independentVectorMatch(
  TMTransition transition,
  List<String> reads,
  int tapeCount,
  String blankSymbol,
) {
  final expected =
      transition.operationsForTapeCount(tapeCount, blankSymbol).readSymbols;
  return expected.length == reads.length &&
      List.generate(reads.length, (index) => expected[index] == reads[index])
          .every((matches) => matches);
}

List<TMTransition> _mutantPartialVectorTransitions(
  TM machine,
  State state,
  List<String> reads,
) =>
    machine.tmTransitions.where((transition) {
      if (transition.fromState.id != state.id) return false;
      final expected = transition
          .operationsForTapeCount(machine.tapeCount, machine.blankSymbol)
          .readSymbols;
      return List.generate(
        reads.length,
        (index) => expected[index] == reads[index],
      ).any((matches) => matches);
    }).toList();

TmOracleOutcome _mutantRejectOnFirstHaltedBranch(TM machine) {
  final state = machine.initialState!;
  final reads = List<String>.filled(machine.tapeCount, machine.blankSymbol);
  final enabled = machine.tmTransitions
      .where((transition) =>
          transition.fromState.id == state.id &&
          _independentVectorMatch(
            transition,
            reads,
            machine.tapeCount,
            machine.blankSymbol,
          ))
      .toList()
    ..sort((left, right) => left.id.compareTo(right.id));
  if (enabled.isEmpty) return TmOracleOutcome.haltedRejected;
  return enabled.first.toState.isAccepting
      ? TmOracleOutcome.accepted
      : TmOracleOutcome.haltedRejected;
}

Future<TMExecutionOutcome> _mutantSkipBuildingBlockReturn(
  TMBlockProject project,
  String input,
) async {
  final invocation = project.rootInvocations.single;
  final child = project.definitions[invocation.reference.blockId]!.machine;
  return (await TMExecutionAnalyzer.analyze(child, input)).outcome;
}

bool _setEquals<T>(Set<T> left, Set<T> right) =>
    left.length == right.length && left.containsAll(right);

Map<String, String> _runtimeSnapshot({
  required SimulationOutcome<TMSimulationResult> accepted,
  required TMExecutionAnalysis stepLimit,
  required TMExecutionAnalysis configurationLimit,
  required TMExecutionAnalysis typedTimeout,
  required SimulationOutcomeKind timeoutKind,
  required SimulationOutcomeKind cancelKind,
}) =>
    {
      'accepted.kind': accepted.kind.name,
      'accepted.outcome': accepted.result!.outcome.name,
      'step.outcome': stepLimit.outcome.name,
      'step.limit': stepLimit.limit!.name,
      'configuration.outcome': configurationLimit.outcome.name,
      'configuration.limit': configurationLimit.limit!.name,
      'timeout.kind': timeoutKind.name,
      'timeout.outcome': typedTimeout.outcome.name,
      'timeout.limit': typedTimeout.limit!.name,
      'cancel.kind': cancelKind.name,
    };

bool _mapEquals<K, V>(Map<K, V> left, Map<K, V> right) =>
    left.length == right.length &&
    left.entries.every((entry) => right[entry.key] == entry.value);

Map<String, Object?> tmShrinkProbeFixture() => {
      'family': 'tm',
      'property': 'tm.generated-shrink',
      'operator': 'partial-multi-tape-read-match',
      'inputTokens': ['a', 'a'],
      'machine': _shrinkCounterexampleMachine().toJson(),
    };

Iterable<Object?> tmFailureFixtureCandidates(Object? value) sync* {
  final source = _objectMap(value);
  final machineJson = _objectMap(source['machine']);
  final transitions =
      (machineJson['transitions'] as List?)?.toList() ?? const [];
  final input = (source['inputTokens'] as List?)?.cast<String>() ?? const [];
  for (var removed = 0; removed < input.length; removed++) {
    yield <String, Object?>{
      ...source,
      'inputTokens': [
        for (var index = 0; index < input.length; index++)
          if (index != removed) input[index],
      ],
    };
  }
  for (var removed = 0; removed < transitions.length; removed++) {
    yield <String, Object?>{
      ...source,
      'machine': <String, Object?>{
        ...machineJson,
        'transitions': [
          for (var index = 0; index < transitions.length; index++)
            if (index != removed) transitions[index],
        ],
      },
    };
  }
  final states = (machineJson['states'] as List?)?.toList() ?? const [];
  final initialStateId = _objectMap(machineJson['initialState'])['id'];
  for (final removedState in states) {
    final removedId = _objectMap(removedState)['id'];
    if (removedId == initialStateId) continue;
    yield <String, Object?>{
      ...source,
      'machine': <String, Object?>{
        ...machineJson,
        'states': [
          for (final state in states)
            if (_objectMap(state)['id'] != removedId) state,
        ],
        'transitions': [
          for (final transition in transitions)
            if (_objectMap(transition)['fromState'] != removedId &&
                _objectMap(transition)['toState'] != removedId)
              transition,
        ],
        'acceptingStates': [
          for (final state
              in (machineJson['acceptingStates'] as List?) ?? const [])
            if (_objectMap(state)['id'] != removedId) state,
        ],
      },
    };
  }
  for (final field in const ['alphabet', 'tapeAlphabet']) {
    final symbols = (machineJson[field] as List?)?.toList() ?? const [];
    for (var removed = 0; removed < symbols.length; removed++) {
      if (field == 'tapeAlphabet' &&
          symbols[removed] == machineJson['blankSymbol']) {
        continue;
      }
      yield <String, Object?>{
        ...source,
        'machine': <String, Object?>{
          ...machineJson,
          field: [
            for (var index = 0; index < symbols.length; index++)
              if (index != removed) symbols[index],
          ],
        },
      };
    }
  }
}

bool tmFailureFixtureIsValid(Object? value) {
  final source = _objectMap(value);
  if (source['operator'] != 'partial-multi-tape-read-match' ||
      source['inputTokens'] is! List ||
      source['machine'] is! Map) {
    return false;
  }
  try {
    final machine =
        TM.fromJson(Map<String, dynamic>.from(source['machine']! as Map));
    final input = (source['inputTokens']! as List).cast<String>();
    return machine.validate().isEmpty &&
        machine.tapeCount >= 2 &&
        input.every(machine.alphabet.contains);
  } on Object {
    return false;
  }
}

bool tmFailureFixtureIsApplicable(Object? value) {
  final observation = _tmFailureObservation(value);
  return observation != null &&
      observation.production.isEmpty &&
      observation.mutant.isNotEmpty;
}

({List<String> reads, Set<String> production, Set<String> mutant})?
    _tmFailureObservation(Object? value) {
  if (!tmFailureFixtureIsValid(value)) return null;
  final source = _objectMap(value);
  final machine =
      TM.fromJson(Map<String, dynamic>.from(source['machine']! as Map));
  final input = (source['inputTokens']! as List).cast<String>();
  final tapes = List<Map<int, String>>.generate(
    machine.tapeCount,
    (index) => index == 0
        ? {for (var cell = 0; cell < input.length; cell++) cell: input[cell]}
        : <int, String>{},
  );
  final reads = TMExecutionKernel.readVector(
    tapes,
    List<int>.filled(machine.tapeCount, 0),
    machine.blankSymbol,
  );
  final wrongReads = [...reads]..[reads.length - 1] = '__mismatch__';
  final mutant = _mutantPartialVectorTransitions(
    machine,
    machine.initialState!,
    wrongReads,
  ).map((transition) => transition.id).toSet();
  final production = TMExecutionKernel.transitionsForVector(
    machine,
    machine.initialState!,
    wrongReads,
  ).map((transition) => transition.id).toSet();
  return (reads: wrongReads, production: production, mutant: mutant);
}

String? tmFailureFixtureSignature(Object? value) {
  final observation = _tmFailureObservation(value);
  if (observation == null ||
      observation.production.isNotEmpty ||
      observation.mutant.isEmpty) {
    return null;
  }
  final production = observation.production.toList()..sort();
  final mutant = observation.mutant.toList()..sort();
  return 'partial-multi-tape-read-match:'
      'reads=${observation.reads.join('|')}:'
      'production=${production.join('|')}:'
      'mutant=${mutant.join('|')}';
}

Object? minimizeTmFailureFixture(Object? seed) {
  if (!tmFailureFixtureIsValid(seed) ||
      tmFailureFixtureSignature(seed) == null) {
    throw ArgumentError.value(seed, 'seed', 'must reproduce a valid failure');
  }
  final signature = tmFailureFixtureSignature(seed);
  var current = seed;
  while (true) {
    final smaller = tmFailureFixtureCandidates(current).firstWhere(
      (candidate) =>
          tmFailureFixtureIsValid(candidate) &&
          tmFailureFixtureSignature(candidate) == signature,
      orElse: () => null,
    );
    if (smaller == null) return current;
    current = smaller;
  }
}

bool tmFailureFixtureIsMinimal(Object? value) {
  final signature = tmFailureFixtureSignature(value);
  if (signature == null) return false;
  return !tmFailureFixtureCandidates(value).any(
    (candidate) =>
        tmFailureFixtureIsValid(candidate) &&
        tmFailureFixtureSignature(candidate) == signature,
  );
}

TmOracleOutcome _oracleOutcome(TMExecutionOutcome outcome) => switch (outcome) {
      TMExecutionOutcome.accepted => TmOracleOutcome.accepted,
      TMExecutionOutcome.haltedRejected => TmOracleOutcome.haltedRejected,
      TMExecutionOutcome.provenCycle => TmOracleOutcome.provenCycle,
      TMExecutionOutcome.boundedUnknown ||
      TMExecutionOutcome.cancelled =>
        TmOracleOutcome.boundedUnknown,
      TMExecutionOutcome.invalidMachine => TmOracleOutcome.invalidMachine,
    };

TM _generatedDecisionMachine(int index, TapeDirection direction) {
  final q0 = _state('g$index-q0', initial: true);
  final q1 = _state('g$index-q1');
  final accept = _state('g$index-accept', accepting: true);
  final otherDirection = TapeDirection.values[(direction.index + 1) % 3];
  final firstDirections = [direction, otherDirection];
  final firstWrites = [
    if (index.isEven) 'x' else 'y',
    if (index.isEven) 'm' else 'n',
  ];
  final secondReads = <String>[
    if (direction == TapeDirection.stay) firstWrites[0] else 'B',
    if (otherDirection == TapeDirection.stay) firstWrites[1] else 'B',
  ];
  return _machine(
    id: 'generated-$index',
    states: [q0, q1, accept],
    accepting: [accept],
    alphabet: const {'a'},
    tapeAlphabet: const {'a', 'x', 'y', 'm', 'n', 'p', 'q', 'B'},
    tapeCount: 2,
    transitions: [
      TMTransition(
        id: 'g$index-write-move',
        fromState: q0,
        toState: q1,
        label: 'generated-vector-1',
        readSymbols: const ['a', 'B'],
        writeSymbols: firstWrites,
        directions: firstDirections,
      ),
      TMTransition(
        id: 'g$index-observe-config',
        fromState: q1,
        toState: accept,
        label: 'generated-vector-2',
        readSymbols: secondReads,
        writeSymbols: const ['p', 'q'],
        directions: [otherDirection, direction],
      ),
    ],
  );
}

void _requireGeneratedConfigurationAgreement(
  TM machine,
  TmOracleResult expected,
  TMExecutionAnalysis actual,
  String label,
) {
  _require(
    expected.steps == actual.stepsExecuted,
    'Step count diverged for $label: ${expected.steps}/${actual.stepsExecuted}.',
  );
  _require(
    expected.trace.isNotEmpty && actual.multiTapeTrace.isNotEmpty,
    'Configuration trace was absent for $label.',
  );
  final oracleFinal = expected.trace.last;
  final productionFinal = actual.multiTapeTrace.last.configuration;
  final oracleSnapshot = TMConfigurationSnapshot.canonicalMulti(
    stateId: oracleFinal.stateId,
    headPositions: oracleFinal.heads,
    tapes: oracleFinal.tapes,
    blankSymbol: machine.blankSymbol,
  );
  _require(
    productionFinal.key == oracleSnapshot.key,
    'Write/head/final configuration diverged for $label: '
    '${oracleSnapshot.key}/${productionFinal.key}.',
  );
}

TM _singleSymbolAcceptor() {
  final q0 = _state('q0', initial: true);
  final accept = _state('accept', accepting: true);
  return _machine(
    id: 'single-symbol',
    states: [q0, accept],
    accepting: [accept],
    alphabet: const {'a'},
    tapeAlphabet: const {'a', 'B'},
    transitions: [_transition('accept-a', q0, accept, read: 'a')],
  );
}

TM _blankAcceptor({Set<String> alphabet = const {}}) {
  final q0 = _state('q0', initial: true);
  final accept = _state('accept', accepting: true);
  return _machine(
    id: 'blank-acceptor',
    states: [q0, accept],
    accepting: [accept],
    alphabet: alphabet,
    tapeAlphabet: {...alphabet, 'B'},
    transitions: [_transition('accept-blank', q0, accept, read: 'B')],
  );
}

TM _rejector() => _machine(
      id: 'rejector',
      states: [_state('q0', initial: true)],
    );

TM _stationaryCycle() {
  final q0 = _state('q0', initial: true);
  return _machine(
    id: 'cycle',
    states: [q0],
    transitions: [_transition('loop', q0, q0, read: 'B')],
  );
}

TM _movingForever() {
  final q0 = _state('q0', initial: true);
  return _machine(
    id: 'moving',
    states: [q0],
    transitions: [
      _transition(
        'move',
        q0,
        q0,
        read: 'B',
        direction: TapeDirection.right,
      ),
    ],
  );
}

TM _leftAcceptor() {
  final q0 = _state('left-q0', initial: true);
  final accept = _state('left-accept', accepting: true);
  return _machine(
    id: 'left-acceptor',
    states: [q0, accept],
    accepting: [accept],
    transitions: [
      _transition(
        'move-left',
        q0,
        accept,
        read: 'B',
        direction: TapeDirection.left,
      ),
    ],
  );
}

TM _acceptingAfterRejectingBranchNtm() {
  final q0 = _state('branch-q0', initial: true);
  final reject = _state('branch-reject');
  final accept = _state('branch-accept', accepting: true);
  return _machine(
    id: 'accept-after-reject-ntm',
    states: [q0, reject, accept],
    accepting: [accept],
    transitions: [
      _transition(
        'a-reject-first',
        q0,
        reject,
        read: 'B',
        nondeterministic: true,
      ),
      _transition(
        'z-accept-second',
        q0,
        accept,
        read: 'B',
        nondeterministic: true,
      ),
    ],
  );
}

TM _acceptingAndCyclicNtm() {
  final q0 = _state('q0', initial: true);
  final accept = _state('accept', accepting: true);
  return _machine(
    id: 'ntm',
    states: [q0, accept],
    accepting: [accept],
    transitions: [
      _transition('a-cycle', q0, q0, read: 'B', nondeterministic: true),
      _transition('z-accept', q0, accept, read: 'B', nondeterministic: true),
    ],
  );
}

TM _finiteCyclicNtm() {
  final q0 = _state('q0', initial: true);
  return _machine(
    id: 'finite-cyclic-ntm',
    states: [q0],
    transitions: [
      _transition('cycle-a', q0, q0, read: 'B', nondeterministic: true),
      _transition('cycle-b', q0, q0, read: 'B', nondeterministic: true),
    ],
  );
}

TM _twoTapeTransfer() {
  final q0 = _state('q0', initial: true);
  final accept = _state('accept', accepting: true);
  return _machine(
    id: 'two-tape-transfer',
    states: [q0, accept],
    accepting: [accept],
    alphabet: const {'a'},
    tapeAlphabet: const {'a', 'B'},
    tapeCount: 2,
    transitions: [
      TMTransition(
        id: 'transfer',
        fromState: q0,
        toState: accept,
        label: 'transfer',
        readSymbols: const ['a', 'B'],
        writeSymbols: const ['B', 'a'],
        directions: const [TapeDirection.right, TapeDirection.left],
      ),
    ],
  );
}

TM _shrinkCounterexampleMachine() {
  final q0 = _state('q0', initial: true);
  final accept = _state('accept', accepting: true);
  return _machine(
    id: 'two-tape-shrink-counterexample',
    states: [q0, accept],
    accepting: [accept],
    alphabet: const {'a', 'x'},
    tapeAlphabet: const {'a', 'x', 'B'},
    tapeCount: 2,
    transitions: [
      TMTransition(
        id: 'transfer',
        fromState: q0,
        toState: accept,
        label: 'transfer',
        readSymbols: const ['a', 'B'],
        writeSymbols: const ['B', 'a'],
        directions: const [TapeDirection.right, TapeDirection.left],
      ),
      TMTransition(
        id: 'irrelevant-decoy',
        fromState: q0,
        toState: accept,
        label: 'irrelevant-decoy',
        readSymbols: const ['x', 'B'],
        writeSymbols: const ['x', 'B'],
        directions: const [TapeDirection.stay, TapeDirection.stay],
      ),
    ],
  );
}

TM _threeTapeWriter() {
  final q0 = _state('q0', initial: true);
  final accept = _state('accept', accepting: true);
  return _machine(
    id: 'three-tape-writer',
    states: [q0, accept],
    accepting: [accept],
    tapeAlphabet: const {'x', 'y', 'z', 'B'},
    tapeCount: 3,
    transitions: [
      TMTransition(
        id: 'write-vector',
        fromState: q0,
        toState: accept,
        label: 'write-vector',
        readSymbols: const ['B', 'B', 'B'],
        writeSymbols: const ['x', 'y', 'z'],
        directions: const [
          TapeDirection.left,
          TapeDirection.stay,
          TapeDirection.right,
        ],
      ),
    ],
  );
}

TM _stationaryMultiTapeCycle() {
  final q0 = _state('q0', initial: true);
  return _machine(
    id: 'stationary-multi-tape-cycle',
    states: [q0],
    tapeCount: 2,
    transitions: [
      TMTransition(
        id: 'cycle',
        fromState: q0,
        toState: q0,
        label: 'cycle',
        readSymbols: const ['B', 'B'],
        writeSymbols: const ['B', 'B'],
        directions: const [TapeDirection.stay, TapeDirection.stay],
        controlPoint: Vector2(20, -20),
      ),
    ],
  );
}

TM _vectorizedCopy(TM source) => source.copyWith(
      transitions: source.tmTransitions
          .map(
            (transition) => TMTransition(
              id: transition.id,
              fromState: transition.fromState,
              toState: transition.toState,
              label: transition.label,
              type: transition.type,
              readSymbols: [transition.readSymbol],
              writeSymbols: [transition.writeSymbol],
              directions: [transition.direction],
            ),
          )
          .toSet(),
    );

TM _languageOutcomeMachine() {
  final q0 = _state('q0', initial: true);
  final accept = _state('accept', accepting: true);
  final cycle = _state('cycle');
  final moving = _state('moving');
  return _machine(
    id: 'language-outcomes',
    states: [q0, accept, cycle, moving],
    accepting: [accept],
    alphabet: const {'a', 'b', 'c', 'd'},
    tapeAlphabet: const {'a', 'b', 'c', 'd', 'B'},
    transitions: [
      _transition('empty-accept', q0, accept, read: 'B'),
      _transition('a-accept', q0, accept, read: 'a'),
      _transition('c-cycle-start', q0, cycle, read: 'c'),
      _transition('c-cycle', cycle, cycle, read: 'c'),
      _transition('d-move-start', q0, moving,
          read: 'd', direction: TapeDirection.right),
      _transition('d-move', moving, moving,
          read: 'B', direction: TapeDirection.right),
    ],
  );
}

TM _rightScanner() {
  final q0 = _state('q0', initial: true);
  final accept = _state('accept', accepting: true);
  return _machine(
    id: 'right-scanner',
    states: [q0, accept],
    accepting: [accept],
    alphabet: const {'a'},
    tapeAlphabet: const {'a', 'B'},
    transitions: [
      _transition('scan', q0, q0, read: 'a', direction: TapeDirection.right),
      _transition('halt', q0, accept, read: 'B'),
    ],
  );
}

TMBlockProject _sharedTapeProject() {
  final blockStart = _state('block-start', initial: true);
  final blockHalt = _state('block-halt');
  final definition = TMBlockDefinition(
    id: 'writer',
    name: 'Writer',
    revision: 1,
    machine: _machine(
      id: 'writer-machine',
      states: [blockStart, blockHalt],
      alphabet: const {'0', '1'},
      tapeAlphabet: const {'0', '1', 'B'},
      transitions: [
        _transition('write-one', blockStart, blockHalt, read: '0', write: '1'),
      ],
    ),
  );
  final call = _state('call', initial: true);
  final accept = _state('accept', accepting: true);
  final root = _machine(
    id: 'root',
    states: [call, accept],
    accepting: [accept],
    alphabet: const {'0', '1'},
    tapeAlphabet: const {'0', '1', 'B'},
    transitions: [_transition('finish', call, accept, read: '1')],
    definitions: {'writer': definition},
    invocations: [
      TMBlockInvocationNode(
        id: 'call-writer',
        stateId: call.id,
        reference: const TMBlockReference(blockId: 'writer', revision: 1),
      ),
    ],
  );
  return TMBlockProject(rootMachine: root);
}

TMBlockProject _nestedProject() {
  final innerStart = _state('inner-start', initial: true);
  final innerHalt = _state('inner-halt');
  final inner = TMBlockDefinition(
    id: 'inner',
    name: 'Inner',
    revision: 1,
    machine: _machine(
      id: 'inner-machine',
      states: [innerStart, innerHalt],
      alphabet: const {'0', '1'},
      tapeAlphabet: const {'0', '1', 'B'},
      transitions: [
        _transition(
          'inner-write',
          innerStart,
          innerHalt,
          read: '0',
          write: '1',
        ),
      ],
    ),
  );
  final outerCall = _state('outer-call', initial: true);
  final outerHalt = _state('outer-halt');
  final outer = TMBlockDefinition(
    id: 'outer',
    name: 'Outer',
    revision: 1,
    machine: _machine(
      id: 'outer-machine',
      states: [outerCall, outerHalt],
      alphabet: const {'0', '1'},
      tapeAlphabet: const {'0', '1', 'B'},
      transitions: [
        _transition(
          'outer-finish',
          outerCall,
          outerHalt,
          read: '1',
        ),
      ],
    ),
    invocations: [
      _invocation('outer-to-inner', outerCall.id, 'inner'),
    ],
  );
  final rootCall = _state('root-call', initial: true);
  final rootAccept = _state('root-accept', accepting: true);
  return TMBlockProject(
    rootMachine: _machine(
      id: 'nested-root',
      states: [rootCall, rootAccept],
      accepting: [rootAccept],
      alphabet: const {'0', '1'},
      tapeAlphabet: const {'0', '1', 'B'},
      transitions: [
        _transition('root-finish', rootCall, rootAccept, read: '1'),
      ],
      definitions: {'inner': inner, 'outer': outer},
      invocations: [
        _invocation('root-to-outer', rootCall.id, 'outer'),
      ],
    ),
  );
}

TMBlockProject _indirectRecursiveProject() {
  final aState = _state('a-state', initial: true);
  final bState = _state('b-state', initial: true);
  final a = TMBlockDefinition(
    id: 'a',
    name: 'A',
    revision: 1,
    machine: _machine(id: 'a-machine', states: [aState]),
    invocations: [_invocation('a-to-b', aState.id, 'b')],
  );
  final b = TMBlockDefinition(
    id: 'b',
    name: 'B',
    revision: 1,
    machine: _machine(id: 'b-machine', states: [bState]),
    invocations: [_invocation('b-to-a', bState.id, 'a')],
  );
  final rootState = _state('root-call', initial: true);
  return TMBlockProject(
    rootMachine: _machine(
      id: 'indirect-recursive-root',
      states: [rootState],
      definitions: {'a': a, 'b': b},
      invocations: [_invocation('root-to-a', rootState.id, 'a')],
    ),
  );
}

TMBlockProject _invalidReferenceProject() {
  final blockState = _state('block-state', initial: true);
  final definition = TMBlockDefinition(
    id: 'block',
    name: 'Block',
    revision: 2,
    machine: _machine(id: 'block-machine', states: [blockState]),
  );
  final stale = _state('stale', initial: true);
  final missing = _state('missing');
  return TMBlockProject(
    rootMachine: _machine(
      id: 'invalid-reference-root',
      states: [stale, missing],
      definitions: {'block': definition},
      invocations: [
        _invocation('stale-call', stale.id, 'block', revision: 1),
        _invocation('missing-call', missing.id, 'absent'),
      ],
    ),
  );
}

TMBlockProject _recursiveProject() {
  final blockState = _state('recursive-state', initial: true);
  final definition = TMBlockDefinition(
    id: 'recursive',
    name: 'Recursive',
    revision: 1,
    machine: _machine(id: 'recursive-machine', states: [blockState]),
    invocations: [
      TMBlockInvocationNode(
        id: 'self',
        stateId: blockState.id,
        reference: const TMBlockReference(blockId: 'recursive', revision: 1),
      ),
    ],
  );
  final rootState = _state('root-call', initial: true);
  return TMBlockProject(
    rootMachine: _machine(
      id: 'recursive-root',
      states: [rootState],
      definitions: {'recursive': definition},
      invocations: [
        TMBlockInvocationNode(
          id: 'root-to-recursive',
          stateId: rootState.id,
          reference: const TMBlockReference(blockId: 'recursive', revision: 1),
        ),
      ],
    ),
  );
}

TM _grammarMovementMachine() {
  final q0 = _state('q0', initial: true);
  final q1 = _state('q1');
  final q2 = _state('q2');
  final accept = _state('accept', accepting: true);
  return _machine(
    id: 'grammar-movements',
    states: [q0, q1, q2, accept],
    accepting: [accept],
    alphabet: const {'a'},
    tapeAlphabet: const {'a', 'B'},
    transitions: [
      _transition('right', q0, q1, read: 'a', direction: TapeDirection.right),
      _transition('left', q1, q2, read: 'B', direction: TapeDirection.left),
      _transition('stay', q2, accept, read: 'a'),
    ],
  );
}

String _sortedStateIds(TM machine) {
  final ids = machine.states.map((state) => state.id).toList()..sort();
  return ids.join('|');
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
  State to, {
  required String read,
  String? write,
  TapeDirection direction = TapeDirection.stay,
  bool nondeterministic = false,
}) =>
    TMTransition(
      id: id,
      fromState: from,
      toState: to,
      label: id,
      readSymbol: read,
      writeSymbol: write ?? read,
      direction: direction,
      type: nondeterministic
          ? TransitionType.nondeterministic
          : TransitionType.deterministic,
      controlPoint: from == to ? Vector2(20, -20) : Vector2.zero(),
    );

TMBlockInvocationNode _invocation(
  String id,
  String stateId,
  String blockId, {
  int revision = 1,
}) =>
    TMBlockInvocationNode(
      id: id,
      stateId: stateId,
      reference: TMBlockReference(blockId: blockId, revision: revision),
    );

TM _machine({
  required String id,
  required Iterable<State> states,
  Iterable<TMTransition> transitions = const [],
  Iterable<State> accepting = const [],
  Set<String> alphabet = const {},
  Set<String> tapeAlphabet = const {'B'},
  int tapeCount = 1,
  TMAcceptancePolicy acceptancePolicy = TMAcceptancePolicy.finalState,
  Map<String, TMBlockDefinition> definitions = const {},
  Iterable<TMBlockInvocationNode> invocations = const [],
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
    created: DateTime.utc(2026, 8, 26),
    modified: DateTime.utc(2026, 8, 26),
    bounds: const math.Rectangle(0, 0, 640, 480),
    tapeAlphabet: tapeAlphabet,
    blankSymbol: 'B',
    tapeCount: tapeCount,
    acceptancePolicy: acceptancePolicy,
    blockDefinitions: definitions,
    blockInvocations: invocations,
  );
}

Map<String, Object?> _objectMap(Object? value) => value is Map
    ? <String, Object?>{
        for (final entry in value.entries) entry.key.toString(): entry.value,
      }
    : const {};

void _require(bool condition, String message) {
  if (!condition) throw StateError(message);
}

final class _TmEvidence {
  const _TmEvidence(this.message, [this.values = const {}]);

  final String message;
  final Map<String, Object?> values;
}

final class _TmIncomplete implements Exception {
  const _TmIncomplete(this.message);

  final String message;
}

extension<T> on Iterable<T> {
  T? get firstOrNull => isEmpty ? null : first;
}
