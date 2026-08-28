import 'dart:async';
import 'dart:io';

import 'package:test/test.dart';
import 'package:turing_lab/core/graph_layout/graph_layout.dart';

import '../../../tool/hard_edge/catalog.dart';
import '../../../tool/hard_edge/families/graph_family.dart';
import '../../../tool/hard_edge/models.dart';
import '../../../tool/hard_edge/mutation.dart';
import '../../../tool/hard_edge/runner.dart';
import '../../../tool/hard_edge/shrinking.dart';

void main() {
  group('graph hard-edge family', () {
    test('matrix registers every layout plus validation and canvas contracts',
        () {
      expect(graphLayoutPropertyByAlgorithm.keys.toSet(),
          GraphLayoutAlgorithmId.values.toSet());
      expect(
        graphHardEdgeDescriptors.map((item) => item.id).toSet(),
        hasLength(graphHardEdgeDescriptors.length),
      );
      expect(graphHardEdgeDescriptors, hasLength(23));
      expect(
        graphHardEdgeDescriptors
            .where((item) => item.requiredTool == 'flutter')
            .map((item) => item.property),
        {
          'graph.document-adapter',
          'graph.canvas-contracts',
          'graph.viewport-invalid-matrix',
          'graph.performance-benchmark',
        },
      );
      expect(
        graphBoundaryInventory.map((item) => item.id).toSet(),
        hasLength(graphBoundaryInventory.length),
      );
      final properties = graphHardEdgeDescriptors
          .map((descriptor) => descriptor.property)
          .toSet();
      for (final boundary in graphBoundaryInventory) {
        expect(File(boundary.sourcePath).existsSync(), isTrue,
            reason: boundary.id);
        expect(boundary.entryPoints, isNotEmpty, reason: boundary.id);
        expect(properties.containsAll(boundary.properties), isTrue,
            reason: boundary.id);
        final source = File(boundary.sourcePath).readAsStringSync();
        for (final entryPoint in boundary.entryPoints) {
          expect(
            source,
            contains(entryPoint.split('.').last),
            reason: '${boundary.id}: $entryPoint',
          );
        }
      }

      final discovered = <String>{
        for (final root in graphBoundaryDiscoveryRoots)
          for (final entity in Directory(root).listSync(recursive: true))
            if (entity is File && entity.path.endsWith('.dart'))
              entity.path.replaceAll('\\', '/'),
      };
      final classified = <String>{
        ...graphBoundaryInventory.map((entry) => entry.sourcePath),
        ...graphBoundarySupportSourceAllowlist,
      }.where(
        (path) => graphBoundaryDiscoveryRoots.any(
          (root) => path.startsWith('$root/'),
        ),
      );
      expect(discovered, classified.toSet());
    });

    test('all pure graph properties pass their deterministic fixtures',
        () async {
      final executor = GraphHardEdgePropertyExecutor(
        evidenceRunner: (_, __) async => 0,
      );
      for (final descriptor in graphHardEdgeDescriptors) {
        final testCase = _case(descriptor);
        final outcome = await executor.execute(
          testCase,
          graphHardEdgeFixture(property: descriptor.property),
        );
        expect(
          outcome,
          HardEdgeExecutionOutcome.pass,
          reason: '${descriptor.algorithm}/${descriptor.property}',
        );
      }
    });

    test('generated seeds are materialized and affect seeded layouts',
        () async {
      final descriptor = graphHardEdgeDescriptors.singleWhere(
        (item) => item.property == 'graph.layout-seeded-random',
      );
      final executor = GraphHardEdgePropertyExecutor(
        evidenceRunner: (_, __) async => 0,
      );
      final fixture = graphHardEdgeFixture(property: descriptor.property);

      final materialized = await executor.materialize(
        _case(descriptor),
        fixture,
        9876,
      );

      expect(materialized, containsPair('seed', 9876));
      expect(
        await executor.execute(_case(descriptor), materialized),
        HardEdgeExecutionOutcome.pass,
      );
    });

    test('generated Flutter evidence is explicitly not applicable', () async {
      final descriptor = graphHardEdgeDescriptors.singleWhere(
        (item) => item.property == 'graph.canvas-contracts',
      );
      final executor = GraphHardEdgePropertyExecutor(
        evidenceRunner: (_, __) async => 0,
      );
      final fixture = graphHardEdgeFixture(property: descriptor.property);
      final generated = await executor.materialize(
        _case(descriptor),
        fixture,
        999,
      );

      expect(
        await executor.execute(_case(descriptor), generated),
        HardEdgeExecutionOutcome.notApplicable,
      );
      expect(graphFailureFixtureIsApplicable(generated), isFalse);
      expect(graphFailureFixtureIsApplicable(fixture), isFalse);
    });

    test('generated event history is injected, replayed, and applicable',
        () async {
      final descriptor = graphHardEdgeDescriptors.singleWhere(
        (item) => item.property == 'graph.event-history-replay',
      );
      final executor = GraphHardEdgePropertyExecutor(
        evidenceRunner: (_, __) async => 0,
      );
      final fixture = graphHardEdgeFixture(property: descriptor.property);
      final generated = await executor.materialize(
        _case(descriptor),
        fixture,
        9876,
      );

      expect((generated as Map)['events'], isNot((fixture as Map)['events']));
      expect(graphFailureFixtureIsApplicable(generated), isTrue);
      expect(
        await executor.execute(_case(descriptor), generated),
        HardEdgeExecutionOutcome.pass,
      );
      expect(
        graphEventHistoryReplay(generated).toJson(),
        graphEventHistoryReplay(generated).toJson(),
      );
    });

    test('evidence timeout terminates and awaits child and grandchild',
        () async {
      final temporary = await Directory.systemTemp.createTemp(
        'turing-lab-graph-evidence-',
      );
      addTearDown(() => temporary.delete(recursive: true));
      final child = File(
        '${temporary.path}${Platform.pathSeparator}grandchild.dart',
      );
      final parent =
          File('${temporary.path}${Platform.pathSeparator}hang.dart');
      final pidFile = File('${temporary.path}${Platform.pathSeparator}pid.txt');
      final sentinel =
          File('${temporary.path}${Platform.pathSeparator}survived.txt');
      await child.writeAsString('''
import 'dart:async';
import 'dart:io';

Future<void> main(List<String> arguments) async {
  await Future<void>.delayed(const Duration(seconds: 2));
  File(arguments[0]).writeAsStringSync('descendant survived timeout');
  await Future<void>.delayed(const Duration(minutes: 5));
}
''');
      await parent.writeAsString('''
import 'dart:async';
import 'dart:io';

Future<void> main(List<String> arguments) async {
  final child = await Process.start(
    Platform.resolvedExecutable,
    [arguments[0], arguments[2]],
  );
  File(arguments[1]).writeAsStringSync(child.pid.toString());
  await Future<void>.delayed(const Duration(minutes: 5));
}
''');
      final stopwatch = Stopwatch()..start();

      await expectLater(
        runGraphEvidenceProcessForCertification(
          executable: _dartExecutableForTest(),
          arguments: [parent.path, child.path, pidFile.path, sentinel.path],
          timeout: const Duration(milliseconds: 750),
        ),
        throwsA(isA<TimeoutException>()),
      );

      expect(stopwatch.elapsed, lessThan(const Duration(seconds: 5)));
      expect(pidFile.existsSync(), isTrue);
      final descendantPid = int.parse(pidFile.readAsStringSync());
      expect(
        await graphEvidenceProcessIsRunningForCertification(descendantPid),
        isFalse,
      );
      await Future<void>.delayed(const Duration(milliseconds: 2500));
      expect(sentinel.existsSync(), isFalse);
    });

    test('Flutter evidence is serialized under parallel catalog jobs',
        () async {
      var active = 0;
      var maximumActive = 0;
      final visited = <List<String>>[];
      final executor = GraphHardEdgePropertyExecutor(
        evidenceRunner: (paths, timeout) async {
          expect(timeout, graphEvidenceTimeout);
          active++;
          if (active > maximumActive) maximumActive = active;
          visited.add(paths);
          await Future<void>.delayed(const Duration(milliseconds: 5));
          active--;
          return 0;
        },
      );
      final evidence = graphHardEdgeDescriptors
          .where((item) => item.requiredTool == 'flutter')
          .toList(growable: false);

      final outcomes = await Future.wait([
        for (final descriptor in evidence)
          executor.execute(
            _case(descriptor),
            graphHardEdgeFixture(property: descriptor.property),
          ),
      ]);

      expect(outcomes, everyElement(HardEdgeExecutionOutcome.pass));
      expect(maximumActive, 1);
      expect(visited, hasLength(evidence.length));
    });

    test('all layout, mapping, and history mutation probes are killed',
        () async {
      const executor = GraphHardEdgeMutationExecutor();
      for (final operator in graphMutationOperatorIds) {
        final result = await executor.execute(
          _mutation(operator),
          graphHardEdgeFixture(property: 'graph.mutations'),
        );
        expect(result, HardEdgeMutationStatus.killed, reason: operator);
      }
    });

    test('shrinker removes graph edges and nodes without dangling endpoints',
        () {
      final source = graphHardEdgeFixture(property: 'graph.layout-circle');
      final candidates = const GraphFailureFixtureShrinker()
          .candidates(source)
          .toList(growable: false);

      expect(candidates, isNotEmpty);
      expect(candidates, everyElement(predicate(graphFailureFixtureIsValid)));
      expect(
        candidates,
        contains(predicate<Object?>(
          (value) =>
              (value as Map)['nodes'].length < (source as Map)['nodes'].length,
        )),
      );
    });

    test('event shrink preserves failure signature and reaches a local minimum',
        () async {
      final descriptor = graphHardEdgeDescriptors.singleWhere(
        (item) => item.property == 'graph.event-history-replay',
      );
      final executor = GraphHardEdgePropertyExecutor(
        evidenceRunner: (_, __) async => 0,
      );
      final generated = await executor.materialize(
        _case(descriptor),
        graphHardEdgeFixture(property: descriptor.property),
        341,
      ) as Map<String, Object?>;
      final events = (generated['events'] as List).cast<Object?>();
      final failing = <String, Object?>{
        ...generated,
        'events': [
          ...events,
          const {
            'type': 'assertLabel',
            'nodeId': 'n0',
            'label': 'impossible-label',
          },
        ],
      };
      final failureSignature =
          graphEventHistoryReplay(failing).failureSignature;
      expect(failureSignature, isNotNull);
      final source = GeneratedCase<Object?>(
        family: graphFamilyId,
        property: descriptor.property,
        generatorVersion: graphGeneratorVersion,
        seed: 341,
        caseIndex: 0,
        mode: GenerationMode.boundaryValid,
        budget: _case(descriptor).budget,
        value: failing,
        encodeValue: (value) => value,
      );

      final result = shrinkFailure<Object?>(
        source: source,
        shrinker: const GraphFailureFixtureShrinker(),
        stillFails: (candidate) =>
            graphEventHistoryReplay(candidate).failureSignature ==
            failureSignature,
        isValid: graphFailureFixtureIsValid,
        isApplicable: graphFailureFixtureIsApplicable,
      );

      expect(result.acceptedCandidates, greaterThan(0));
      expect(
        graphEventHistoryReplay(result.minimalValue).failureSignature,
        failureSignature,
      );
      expect((result.minimalValue as Map)['events'], hasLength(1));
      expect(
        const GraphFailureFixtureShrinker()
            .candidates(result.minimalValue)
            .where(graphFailureFixtureIsValid)
            .where(graphFailureFixtureIsApplicable)
            .every(
              (candidate) =>
                  graphEventHistoryReplay(candidate).failureSignature !=
                  failureSignature,
            ),
        isTrue,
      );
    });

    test('fixture property mismatch fails closed', () async {
      final descriptor = graphHardEdgeDescriptors.first;
      final executor = GraphHardEdgePropertyExecutor(
        evidenceRunner: (_, __) async => 0,
      );

      expect(
        () => executor.execute(
          _case(descriptor),
          graphHardEdgeFixture(property: 'graph.fill'),
        ),
        throwsFormatException,
      );
    });
  });
}

HardEdgeCatalogCase _case(GraphHardEdgeDescriptor descriptor) =>
    HardEdgeCatalogCase(
      id: descriptor.id,
      family: graphFamilyId,
      algorithm: descriptor.algorithm,
      sourceKind: HardEdgeSourceKind.generated,
      seed: 341,
      property: descriptor.property,
      provenance: const HardEdgeProvenance(
        origin: 'Independently authored for Turing Lab issue 341',
        independentlyAuthored: true,
        generator: graphGeneratorVersion,
        licenseBasis: 'LICENSE.txt',
      ),
      license: 'Apache-2.0',
      regressionIssue: 341,
      platforms: const ['all'],
      sha256: '0' * 64,
      generatorVersion: graphGeneratorVersion,
      oracleVersion: graphOracleVersion,
      budget: const GenerationBudget(
        maxStates: 64,
        maxTransitions: 512,
        maxSymbols: 8,
        maxWordLength: 0,
        maxProductions: 0,
        maxStackDepth: 0,
        maxIterations: 256,
      ),
      fixture: 'test/fixtures/hard_edge/graph/case.json',
      expectedOutcome: HardEdgeExpectedOutcome.pass,
      requiredTool: descriptor.requiredTool,
    );

HardEdgeMutation _mutation(String operator) => HardEdgeMutation(
      id: 'graph-$operator',
      family: graphFamilyId,
      property: 'graph.mutations',
      operatorId: operator,
      fixture: 'test/fixtures/hard_edge/graph/mutations.json',
      sha256: '0' * 64,
      requiredTool: null,
    );

String _dartExecutableForTest() {
  final current = File(Platform.resolvedExecutable);
  if (current.uri.pathSegments.last.startsWith('dart')) {
    return current.path;
  }
  final cache = current.parent.parent.parent.parent;
  final candidate = File(
    '${cache.path}${Platform.pathSeparator}dart-sdk'
    '${Platform.pathSeparator}bin${Platform.pathSeparator}'
    'dart${Platform.isWindows ? '.exe' : ''}',
  );
  if (!candidate.existsSync()) {
    throw StateError(
      'Could not locate Dart from ${Platform.resolvedExecutable}.',
    );
  }
  return candidate.path;
}
