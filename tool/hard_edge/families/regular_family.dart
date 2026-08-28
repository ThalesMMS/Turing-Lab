import 'dart:async';
import 'dart:io';

import '../catalog.dart';
import '../domains.dart';
import '../mutation.dart';
import '../runner.dart';
import '../shrinking.dart';
import 'regular_certification.dart';
import 'regular_matrix.dart';

const regularFamilyId = 'regular';
const regularGeneratorVersion = 'regular-v1';
const regularOracleVersion = 'regular-independent-v1';

/// The catalog-facing descriptors kept beside the family implementation.
///
/// The central manifest intentionally remains the integration point. These
/// records make that integration mechanical and keep every property tied to a
/// reproducible family-only command.
final class RegularHardEdgeDescriptor {
  const RegularHardEdgeDescriptor({
    required this.id,
    required this.algorithm,
    required this.property,
    required this.fixture,
    required this.expectedOutcome,
    required this.requiredTool,
  });

  final String id;
  final String algorithm;
  final String property;
  final String fixture;
  final HardEdgeExpectedOutcome expectedOutcome;
  final String? requiredTool;

  String get reproductionCommand =>
      'dart run tool/hard_edge_regular.dart --property $property';
}

final regularHardEdgeDescriptors = <RegularHardEdgeDescriptor>[
  for (final entry in [
    ...regularAlgorithmInventory,
    ...regularProviderInventory,
  ])
    _regularHardEdgeDescriptor(entry),
  const RegularHardEdgeDescriptor(
    id: 'regular-property-resource-outcomes',
    algorithm: 'fsa-simulator',
    property: 'regular.resource-outcomes',
    fixture: 'test/fixtures/hard_edge/regular/resource_outcomes.json',
    expectedOutcome: HardEdgeExpectedOutcome.pass,
    requiredTool: null,
  ),
];

RegularHardEdgeDescriptor _regularHardEdgeDescriptor(
  RegularAlgorithmInventoryEntry entry,
) {
  final property = switch (entry.id) {
    'fsa-simulator' => 'regular.trace-replay',
    _ => entry.properties.first,
  };
  return RegularHardEdgeDescriptor(
    id: 'regular-path-${entry.id}',
    algorithm: entry.id,
    property: property,
    fixture: _fixtureForProperty(property),
    expectedOutcome: HardEdgeExpectedOutcome.pass,
    requiredTool: regularProviderInventory.contains(entry) ? 'flutter' : null,
  );
}

const regularMutationOperatorIds = <String>{
  'flip-initial-acceptance',
  'ignore-epsilon-reachability',
  'skip-dfa-completion',
};

/// Registrable adapter for the shared hard-edge generated-property contract.
final class RegularHardEdgeExecutor
    implements HardEdgeGeneratedPropertyExecutor {
  RegularHardEdgeExecutor({
    Directory? repositoryRoot,
    Future<int> Function(String testPath)? providerEvidenceRunner,
  })  : _providerEvidenceRunner =
            providerEvidenceRunner ?? _runFlutterProviderEvidence,
        _runner = RegularCertificationRunner(
          repositoryRoot: repositoryRoot ?? Directory.current,
        );

  final RegularCertificationRunner _runner;
  final Future<int> Function(String testPath) _providerEvidenceRunner;
  Future<void> _providerQueue = Future<void>.value();

  @override
  Future<HardEdgeExecutionOutcome> execute(
    HardEdgeCatalogCase testCase,
    Object? fixture,
  ) async {
    if (testCase.family != regularFamilyId) {
      throw HardEdgeConfigurationException(
        'Regular executor cannot run family "${testCase.family}".',
      );
    }
    final fixtureSpec = _RegularFixtureSpec.parse(fixture, testCase.property);
    final entry = _inventoryEntryFor(testCase.algorithm);
    if (!entry.properties.contains(testCase.property)) {
      throw HardEdgeConfigurationException(
        'Property "${testCase.property}" does not certify regular algorithm '
        '"${testCase.algorithm}".',
      );
    }
    if (!regularFixturePayloadMatches(testCase.property, fixtureSpec.source)) {
      return HardEdgeExecutionOutcome.violation;
    }
    if (testCase.property == 'regular.completion' &&
        fixtureSpec.source['automaton'] != null) {
      final expectedKilled = fixtureSpec.source['expectedMutantKilled'] ?? true;
      if (expectedKilled is! bool ||
          !regularFailureFixtureIsValid(fixtureSpec.source) ||
          regularFailureFixtureIsApplicable(fixtureSpec.source) !=
              expectedKilled) {
        return HardEdgeExecutionOutcome.violation;
      }
    }
    if (regularProviderInventory.contains(entry)) {
      if (testCase.requiredTool != 'flutter') {
        throw HardEdgeConfigurationException(
          'Provider evidence for "${testCase.algorithm}" requires Flutter.',
        );
      }
      final testPath = entry.evidenceCommand.substring('flutter test '.length);
      final result = await _serializedProviderEvidence(testPath);
      return result == 0
          ? HardEdgeExecutionOutcome.pass
          : HardEdgeExecutionOutcome.violation;
    }
    final check = await _runner.runProperty(
      testCase.property,
      RegularCertificationOptions(
        seed: fixtureSpec.seed ?? testCase.seed,
        cases: fixtureSpec.cases ?? 1,
      ),
    );
    if (fixtureSpec.expectedStatus != null &&
        fixtureSpec.expectedStatus != check.status.name) {
      return HardEdgeExecutionOutcome.violation;
    }
    return switch (check.status) {
      RegularCertificationStatus.passed => HardEdgeExecutionOutcome.pass,
      RegularCertificationStatus.failed => HardEdgeExecutionOutcome.violation,
      RegularCertificationStatus.incomplete => HardEdgeExecutionOutcome.bounded,
    };
  }

  Future<int> _serializedProviderEvidence(String testPath) {
    final result = _providerQueue.then(
      (_) => _providerEvidenceRunner(testPath),
    );
    _providerQueue = result.then<void>((_) {}, onError: (_, __) {});
    return result;
  }

  @override
  Future<Object?> materialize(
    HardEdgeCatalogCase template,
    Object? templateFixture,
    int seed,
  ) async {
    if (template.family != regularFamilyId) {
      throw HardEdgeConfigurationException(
        'Regular executor cannot materialize family "${template.family}".',
      );
    }
    final fixture = _RegularFixtureSpec.parse(
      templateFixture,
      template.property,
    );
    final entry = _inventoryEntryFor(template.algorithm);
    if (!entry.properties.contains(template.property)) {
      throw HardEdgeConfigurationException(
        'Property "${template.property}" does not certify regular algorithm '
        '"${template.algorithm}".',
      );
    }
    return <String, Object?>{
      ...fixture.source,
      'family': regularFamilyId,
      'generatorVersion': regularGeneratorVersion,
      'oracleVersion': regularOracleVersion,
      'property': template.property,
      'seed': seed,
    };
  }
}

Future<int> _runFlutterProviderEvidence(String testPath) async {
  Process? process;
  try {
    final executable = Platform.isWindows ? 'cmd.exe' : 'flutter';
    final arguments = Platform.isWindows
        ? ['/d', '/s', '/c', 'flutter', 'test', testPath]
        : ['test', testPath];
    process = await Process.start(
      executable,
      arguments,
      runInShell: false,
    );
    final output = Future.wait<void>([
      process.stdout.drain<void>(),
      process.stderr.drain<void>(),
    ]);
    try {
      final exitCode = await process.exitCode.timeout(
        const Duration(seconds: 55),
      );
      await output;
      return exitCode;
    } on TimeoutException {
      await _killProviderProcess(process);
      await process.exitCode.timeout(
        const Duration(seconds: 5),
        onTimeout: () => -1,
      );
      await output.timeout(
        const Duration(seconds: 5),
        onTimeout: () => const <void>[],
      );
      return -1;
    }
  } on ProcessException {
    throw const HardEdgeMissingToolException('flutter');
  }
}

Future<void> _killProviderProcess(Process process) async {
  if (Platform.isWindows) {
    try {
      await Process.run(
        'taskkill',
        ['/PID', '${process.pid}', '/T', '/F'],
        runInShell: false,
      );
    } on ProcessException {
      process.kill();
    }
  } else {
    await _killPosixProviderProcessTree(process);
  }
}

Future<void> _killPosixProviderProcessTree(Process process) async {
  final rootPid = process.pid;
  final parentByPid = <int, int>{};
  final descendants = <int>{};

  Process.killPid(rootPid, ProcessSignal.sigstop);
  try {
    // Suspending each discovered wave makes the next snapshot stable: neither
    // the Flutter parent nor known Dart children can create another process.
    for (var attempt = 0; attempt < 4; attempt++) {
      parentByPid.addAll(await _readPosixProcessParents());
      final ordered = RegularProviderProcessTree.descendantsDeepestFirst(
        parentByPid,
        rootPid,
      );
      var foundNewDescendant = false;
      for (final pid in ordered) {
        foundNewDescendant = descendants.add(pid) || foundNewDescendant;
        Process.killPid(pid, ProcessSignal.sigstop);
      }
      if (!foundNewDescendant) break;
    }
  } on ProcessException {
    // `ps` is expected on supported POSIX hosts. If it is unavailable, the
    // timed-out provider still fails and the parent is killed below.
  } finally {
    final ordered = RegularProviderProcessTree.descendantsDeepestFirst(
      parentByPid,
      rootPid,
    );
    for (final pid in ordered) {
      if (descendants.contains(pid)) {
        Process.killPid(pid, ProcessSignal.sigkill);
      }
    }
    process.kill(ProcessSignal.sigkill);
  }
}

Future<Map<int, int>> _readPosixProcessParents() async {
  const arguments = ['-A', '-o', 'pid=,ppid='];
  final result = await Process.run('ps', arguments, runInShell: false);
  if (result.exitCode != 0) {
    throw ProcessException(
      'ps',
      arguments,
      'Could not inspect the provider process tree.',
      result.exitCode,
    );
  }

  final parentByPid = <int, int>{};
  for (final line in '${result.stdout}'.split(RegExp(r'\r?\n'))) {
    final fields = line.trim().split(RegExp(r'\s+'));
    if (fields.length != 2) continue;
    final pid = int.tryParse(fields[0]);
    final parentPid = int.tryParse(fields[1]);
    if (pid != null && parentPid != null) {
      parentByPid[pid] = parentPid;
    }
  }
  return parentByPid;
}

/// Pure process-tree ordering used by the POSIX provider timeout cleanup.
final class RegularProviderProcessTree {
  const RegularProviderProcessTree._();

  /// Returns descendants of [rootPid] in deterministic post-order.
  ///
  /// Children therefore precede their parents, which is the safe order for
  /// terminating a process tree without leaving a live descendant behind.
  static List<int> descendantsDeepestFirst(
    Map<int, int> parentByPid,
    int rootPid,
  ) {
    final childrenByPid = <int, List<int>>{};
    for (final MapEntry(key: pid, value: parentPid) in parentByPid.entries) {
      childrenByPid.putIfAbsent(parentPid, () => <int>[]).add(pid);
    }
    for (final children in childrenByPid.values) {
      children.sort();
    }

    final ordered = <int>[];
    final visiting = <int>{rootPid};
    final visited = <int>{};

    void visit(int pid) {
      for (final childPid in childrenByPid[pid] ?? const <int>[]) {
        if (visiting.contains(childPid) || !visited.add(childPid)) continue;
        visiting.add(childPid);
        visit(childPid);
        visiting.remove(childPid);
        ordered.add(childPid);
      }
    }

    visit(rootPid);
    return ordered;
  }
}

RegularAlgorithmInventoryEntry _inventoryEntryFor(String algorithm) {
  for (final entry in [
    ...regularAlgorithmInventory,
    ...regularProviderInventory,
  ]) {
    if (entry.id == algorithm) return entry;
  }
  throw HardEdgeConfigurationException(
    'Unknown regular algorithm "$algorithm".',
  );
}

String _fixtureForProperty(String property) => switch (property) {
      'regular.model-integrity' ||
      'regular.determinization' =>
        'test/fixtures/hard_edge/regular/epsilon_symbol_cycle.json',
      'regular.completion' =>
        'test/fixtures/hard_edge/regular/shrink_probe.json',
      'regular.regex-oracle' =>
        'test/fixtures/hard_edge/regular/unicode_scalar_range.json',
      'regular.resource-outcomes' =>
        'test/fixtures/hard_edge/regular/resource_outcomes.json',
      'regular.generated-shrink' =>
        'test/fixtures/hard_edge/regular/shrink_probe.json',
      'regular.mutations' =>
        'test/fixtures/hard_edge/regular/mutation_probes.json',
      _ => 'test/fixtures/hard_edge/regular/generated_oracle.json',
    };

/// Mutation adapter for the three pure-Dart probes certified by the family.
final class RegularHardEdgeMutationExecutor
    implements HardEdgeMutationExecutor {
  RegularHardEdgeMutationExecutor({
    bool Function(String operatorId)? mutationProbe,
  }) : _mutationProbe = mutationProbe ?? regularMutationProbeKilled;

  final bool Function(String operatorId) _mutationProbe;

  @override
  Future<HardEdgeMutationStatus> execute(
    HardEdgeMutation mutation,
    Object? fixture,
  ) async {
    if (mutation.family != regularFamilyId) {
      throw HardEdgeConfigurationException(
        'Regular mutation executor cannot run family "${mutation.family}".',
      );
    }
    final fixtureSpec = _RegularFixtureSpec.parse(
      fixture,
      mutation.property,
    );
    if (!regularMutationOperatorIds.contains(mutation.operatorId)) {
      throw HardEdgeConfigurationException(
        'Unknown regular mutation operator "${mutation.operatorId}".',
      );
    }
    if (mutation.property != 'regular.mutations') {
      throw HardEdgeConfigurationException(
        'Property "${mutation.property}" does not certify regular mutations.',
      );
    }
    final operators = fixtureSpec.source['operators'];
    if (operators is! List || !operators.contains(mutation.operatorId)) {
      throw FormatException(
        'Mutation fixture does not register "${mutation.operatorId}".',
      );
    }
    return _mutationProbe(mutation.operatorId)
        ? HardEdgeMutationStatus.killed
        : HardEdgeMutationStatus.survived;
  }
}

/// Domain adapter for central replay/shrink of the incomplete-DFA witness.
final class RegularFailureFixtureShrinker implements DomainShrinker<Object?> {
  const RegularFailureFixtureShrinker();

  @override
  Iterable<Object?> candidates(Object? value) sync* {
    final source = _fixtureMap(value);
    final automaton = _generatedAutomaton(source['automaton']);
    if (automaton == null) return;
    for (final candidate in const AutomatonShrinker().candidates(automaton)) {
      yield <String, Object?>{...source, 'automaton': candidate.toJson()};
    }
  }
}

const DomainShrinker<Object?> regularFailureFixtureShrinker =
    RegularFailureFixtureShrinker();

bool regularFailureFixtureIsValid(Object? value) {
  final source = _fixtureMap(value);
  final automaton = _generatedAutomaton(source['automaton']);
  if (source['operator'] != 'skip-dfa-completion' || automaton == null) {
    return false;
  }
  final stateIds = automaton.states.map((state) => state.id).toSet();
  if (automaton.alphabet.isEmpty ||
      automaton.states.where((state) => state.initial).length != 1 ||
      automaton.alphabet.toSet().length != automaton.alphabet.length) {
    return false;
  }
  final seen = <String>{};
  for (final transition in automaton.transitions) {
    if (!stateIds.contains(transition.fromId) ||
        !stateIds.contains(transition.toId) ||
        transition.readTokens.length != 1 ||
        !automaton.alphabet.contains(transition.readTokens.single) ||
        !seen
            .add('${transition.fromId}\u0000${transition.readTokens.single}')) {
      return false;
    }
  }
  return true;
}

bool regularFailureFixtureIsApplicable(Object? value) {
  if (!regularFailureFixtureIsValid(value)) return false;
  final automaton = _generatedAutomaton(_fixtureMap(value)['automaton'])!;
  final transitions = {
    for (final transition in automaton.transitions)
      '${transition.fromId}\u0000${transition.readTokens.single}',
  };
  return automaton.states.any(
    (state) => automaton.alphabet.any(
      (symbol) => !transitions.contains('${state.id}\u0000$symbol'),
    ),
  );
}

Map<String, Object?> _fixtureMap(Object? value) => value is Map
    ? <String, Object?>{
        for (final entry in value.entries) entry.key.toString(): entry.value,
      }
    : const {};

GeneratedAutomaton? _generatedAutomaton(Object? value) {
  if (value is! Map) return null;
  try {
    final json = _fixtureMap(value);
    final states = (json['states']! as List).map((value) {
      final state = _fixtureMap(value);
      return GeneratedState(
        id: state['id']! as String,
        initial: state['initial']! as bool,
        accepting: state['accepting']! as bool,
      );
    });
    final transitions = (json['transitions']! as List).map((value) {
      final transition = _fixtureMap(value);
      return GeneratedTransition(
        id: transition['id']! as String,
        fromId: transition['fromId']! as String,
        toId: transition['toId']! as String,
        readTokens: (transition['readTokens']! as List).cast<String>(),
      );
    });
    return GeneratedAutomaton(
      id: json['id']! as String,
      alphabet: (json['alphabet']! as List).cast<String>(),
      states: states,
      transitions: transitions,
    );
  } on Object {
    return null;
  }
}

final class _RegularFixtureSpec {
  const _RegularFixtureSpec({
    required this.source,
    required this.seed,
    required this.cases,
    required this.expectedStatus,
  });

  final Map<String, Object?> source;
  final int? seed;
  final int? cases;
  final String? expectedStatus;

  static _RegularFixtureSpec parse(Object? fixture, String property) {
    if (fixture is! Map) {
      throw const FormatException(
        'Regular hard-edge fixture must be an object.',
      );
    }
    final source = <String, Object?>{
      for (final entry in fixture.entries) entry.key.toString(): entry.value,
    };
    final family = source['family'];
    if (family != null && family != regularFamilyId) {
      throw FormatException('Regular fixture has unexpected family "$family".');
    }
    final declaredProperty = source['property'];
    if (declaredProperty != null && declaredProperty != property) {
      throw FormatException(
        'Regular fixture property "$declaredProperty" does not match '
        '"$property".',
      );
    }
    final seed = source['seed'];
    final cases = source['cases'];
    final expectedStatus = source['expectedStatus'];
    if (seed != null && seed is! int) {
      throw const FormatException('Regular fixture seed must be an integer.');
    }
    if (cases != null && cases is! int) {
      throw const FormatException('Regular fixture cases must be an integer.');
    }
    if (expectedStatus != null && expectedStatus is! String) {
      throw const FormatException(
        'Regular fixture expectedStatus must be a string.',
      );
    }
    return _RegularFixtureSpec(
      source: source,
      seed: seed as int?,
      cases: cases as int?,
      expectedStatus: expectedStatus as String?,
    );
  }
}
