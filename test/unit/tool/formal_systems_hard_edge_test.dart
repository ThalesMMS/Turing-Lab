import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:turing_lab/core/interoperability/interoperability.dart';
import 'package:turing_lab/core/pumping_lemma/pumping_lemma.dart';
import 'package:turing_lab/data/codecs/pumping_lemma_json_codec.dart';

import '../../../tool/hard_edge/catalog.dart';
import '../../../tool/hard_edge/families/formal_systems_certification.dart';
import '../../../tool/hard_edge/families/formal_systems_family.dart';
import '../../../tool/hard_edge/models.dart';
import '../../../tool/hard_edge/runner.dart';

void main() {
  group('issue 339 production regressions', () {
    test('large pumping exponents return a typed bound before allocation', () {
      final decomposition = RegularPumpingDecomposition(
        x: const [],
        y: const ['token'],
        z: const [],
      );

      final result = decomposition.pumpBounded(
        0x7fffffffffffffff,
        maximumTokens: 32,
      );

      expect(result, isA<PumpingWordBounded>());
      expect((result as PumpingWordBounded).maximumTokens, 32);
      expect(result.minimumRequiredTokens, 33);
      expect(
        () => decomposition.pump(
          0x7fffffffffffffff,
          maximumTokens: 32,
        ),
        throwsA(isA<PumpingWordLimitException>()),
      );

      final contextFree = ContextFreePumpingDecomposition(
        u: const [],
        v: const ['left'],
        x: const [],
        y: const ['right'],
        z: const [],
      );
      expect(
        contextFree.pumpBounded(
          0x7fffffffffffffff,
          maximumTokens: 32,
        ),
        isA<PumpingWordBounded>(),
      );
    });

    test('session controller returns a bound without advancing the turn', () {
      final decomposition = RegularPumpingDecomposition(
        x: const [],
        y: const ['a'],
        z: const [],
      );
      final controller = PumpingLemmaSessionController.regular(
        initialSession: PumpingLemmaSession<RegularPumpingDecomposition>(
          sessionId: 'bounded-session',
          challengeId: 'bounded',
          sourceRevision: 'r1',
          theorem: PumpingLemmaTheorem.regular,
          mode: PumpingLemmaMode.challenge,
          role: PumpingLemmaRole.learner,
          targetLanguage: 'a*',
          pumpingLength: 1,
          witness: const ['a'],
          decomposition: decomposition,
        ),
        sessionIdFactory: () => 'restart',
      );

      final result = controller.chooseExponent(
        expectedSessionId: controller.state.sessionId,
        player: PumpingLemmaPlayer.learner,
        exponent: defaultMaximumPumpedTokens + 1,
      );

      expect(result, isA<PumpingWordBounded>());
      expect(controller.state.stage, PumpingLemmaStage.awaitingExponent);
      expect(controller.state.pumpExponent, isNull);
      expect(controller.state.history, isEmpty);

      final restored = PumpingLemmaSession<RegularPumpingDecomposition>(
        sessionId: 'restored-bounded',
        challengeId: 'bounded',
        sourceRevision: 'r1',
        theorem: PumpingLemmaTheorem.regular,
        mode: PumpingLemmaMode.challenge,
        role: PumpingLemmaRole.learner,
        targetLanguage: 'a*',
        pumpingLength: 1,
        witness: const ['a'],
        decomposition: decomposition,
        pumpExponent: defaultMaximumPumpedTokens + 1,
      );
      expect(restored.pumpedWordOutcome, isA<PumpingWordBounded>());
      expect(restored.pumpedWord, isNull);

      final decoded = PumpingLemmaSession<RegularPumpingDecomposition>.fromJson(
        restored.toJson(),
      );
      expect(decoded.stage, PumpingLemmaStage.awaitingExponent);
      expect(decoded.pumpExponent, isNull);
      expect(decoded.evidence, isNull);
      expect(decoded.outcome, PumpingLemmaSessionOutcome.inProgress);
    });

    test('JSON codec restores a bounded legacy session at exponent choice', () {
      final problem = PumpingLemmaProblemCatalog.regular.first;
      final decomposition = RegularPumpingDecomposition(
        x: const [],
        y: const ['a'],
        z: const [],
      );
      final legacy = PumpingLemmaSession<RegularPumpingDecomposition>(
        sessionId: 'legacy-bounded',
        challengeId: problem.id,
        sourceRevision: problem.sourceRevision,
        theorem: PumpingLemmaTheorem.regular,
        mode: PumpingLemmaMode.challenge,
        role: PumpingLemmaRole.learner,
        targetLanguage: problem.languageDescription,
        pumpingLength: 1,
        witness: const ['a'],
        decomposition: decomposition,
        pumpExponent: defaultMaximumPumpedTokens + 1,
        stage: PumpingLemmaStage.awaitingEvidence,
      );
      final encoded = jsonEncode({
        'schema': {'id': 'turing-lab.pumping-lemma', 'version': 1},
        'problem': problem.toJson(),
        'session': legacy.toJson(),
        'progress': PumpingLemmaEnvironmentProgress().toJson(),
        'futureSidecar': {'preserve': true},
      });

      final outcome = const PumpingLemmaJsonCodec.regular().decode(
        DocumentPayload(bytes: Uint8List.fromList(utf8.encode(encoded))),
      );

      expect(outcome, isA<CodecSuccess<InteroperableDocument<Object>>>());
      final success = outcome as CodecSuccess<InteroperableDocument<Object>>;
      expect(success.fidelity, DocumentFidelity.normalized);
      expect(
        success.diagnostics.single.code,
        'pumping.session.bounded-exponent-reset',
      );
      final document = success.value.document as RegularPumpingLemmaDocument;
      expect(document.session.stage, PumpingLemmaStage.awaitingExponent);
      expect(document.session.pumpExponent, isNull);
      expect(
        success.value.extensions.values['futureSidecar'],
        {'preserve': true},
      );
    });

    test('JSON codec types a malformed historical session', () {
      final problem = PumpingLemmaProblemCatalog.regular.first;
      final outcome = const PumpingLemmaJsonCodec.regular().decode(
        DocumentPayload(
          bytes: Uint8List.fromList(
            utf8.encode(jsonEncode({
              'schema': {
                'id': 'turing-lab.pumping-lemma',
                'version': 1,
              },
              'problem': problem.toJson(),
              'session': const ['historical-invalid-session'],
              'progress': PumpingLemmaEnvironmentProgress().toJson(),
              'futureSidecar': {'preserve': true},
            })),
          ),
        ),
      );

      expect(
        outcome,
        isA<CodecMalformed<InteroperableDocument<Object>>>(),
      );
    });
  });

  group('issue 339 formal-systems hard-edge family', () {
    test('matrix passes and covers every exported descriptor', () async {
      final report = await FormalSystemsCertification.run(
        const FormalSystemsCertificationOptions(
          seedStart: 339,
          seedCount: 1,
        ),
      );

      expect(
        report.passed,
        isTrue,
        reason: report.records
            .where((record) => !record.passed)
            .map((record) => record.toJson())
            .toList()
            .toString(),
      );
      expect(report.records, hasLength(29));
      expect(
        report.records.map((record) => record.id).toSet(),
        formalSystemsHardEdgeDescriptors
            .map((descriptor) => descriptor.caseId)
            .toSet(),
      );
      expect(
        report.records.every(
          (record) => (record.toJson()['provenance']! as Map)['issue'] == 339,
        ),
        isTrue,
      );
      final parity = report.records.singleWhere(
        (record) => record.id == 'transducer-trace-async',
      );
      expect(
        parity.evidence['typedOutcomes'],
        containsAll(<String>[
          'TransducerBounded',
          'TransducerCancelled',
          'TransducerIncomplete',
          'TransducerInvalidInput',
          'TransducerSuccess',
        ]),
      );
    });

    test('reports are deterministic and semantic mutants are killed', () async {
      final first = await FormalSystemsCertification.run(
        const FormalSystemsCertificationOptions(
          seedStart: 339,
          seedCount: 2,
        ),
      );
      final second = await FormalSystemsCertification.run(
        const FormalSystemsCertificationOptions(
          seedStart: 339,
          seedCount: 2,
        ),
      );
      final mutations = runFormalSystemsMutationProbes(seed: 339);

      expect(first.toJson(), second.toJson());
      expect(mutations, hasLength(3));
      expect(mutations.every((mutation) => mutation.productionPassed), isTrue);
      expect(mutations.every((mutation) => mutation.killed), isTrue);
    });

    test('executor materializes replay fixtures and enforces metadata',
        () async {
      const executor = FormalSystemsHardEdgePropertyExecutor();
      for (final descriptor in formalSystemsHardEdgeDescriptors) {
        final fixture = descriptor.fixture(seed: 339);
        expect(formalSystemsFailureFixtureIsValid(fixture), isTrue);
        expect(formalSystemsFailureFixtureIsApplicable(fixture), isTrue);
        expect(
          await executor.execute(_catalogCase(descriptor), fixture),
          HardEdgeExecutionOutcome.pass,
          reason: descriptor.caseId,
        );
      }
      final replay = formalSystemsHardEdgeDescriptors.singleWhere(
        (descriptor) => descriptor.caseId == 'transducer-mealy-oracle',
      );
      final materialized = await executor.materialize(
        _catalogCase(replay),
        replay.fixture(seed: 339),
        991,
      ) as Map;
      expect(materialized['seed'], 991);
      expect(formalSystemsFailureFixtureIsValid(materialized), isTrue);
    });

    test('domain shrinkers reduce each replay artifact honestly', () {
      const shrinker = FormalSystemsFailureFixtureShrinker();
      for (final caseId in const [
        'transducer-mealy-oracle',
        'lsystem-parallel-oracle',
        'pumping-regular-oracle',
      ]) {
        final descriptor = formalSystemsHardEdgeDescriptors.singleWhere(
          (item) => item.caseId == caseId,
        );
        final source = descriptor.fixture(seed: 339);
        final candidates = shrinker.candidates(source).toList();

        expect(candidates, isNotEmpty, reason: caseId);
        expect(
          candidates.every(formalSystemsFailureFixtureIsValid),
          isTrue,
          reason: caseId,
        );
        expect(
          candidates.every(
            (candidate) =>
                formalSystemsReplayAgrees(candidate) ==
                formalSystemsReplayAgrees(source),
          ),
          isTrue,
          reason: caseId,
        );
        expect(formalSystemsReplayAgrees(source), isTrue, reason: caseId);
      }

      final pumping = formalSystemsHardEdgeDescriptors
          .singleWhere((item) => item.caseId == 'pumping-regular-oracle')
          .fixture(seed: 339);
      final payload = Map<String, Object?>.from(pumping['payload']! as Map);
      final bounded = <String, Object?>{
        ...pumping,
        'payload': {
          ...payload,
          'exponent': defaultMaximumPumpedTokens + 1,
          'maximumTokens': 32,
        },
      };
      expect(formalSystemsFailureFixtureIsApplicable(bounded), isTrue);
      expect(formalSystemsReplayAgrees(bounded), isTrue);
    });

    test('reviewed replay corpus is valid and agrees with independent oracles',
        () async {
      for (final name in const [
        'transducer_unicode_tokens.json',
        'l_system_parallel_epsilon.json',
        'pumping_token_decomposition.json',
      ]) {
        final source = jsonDecode(
          await File('test/fixtures/hard_edge/formal_systems/$name')
              .readAsString(),
        );
        expect(formalSystemsFailureFixtureIsValid(source), isTrue,
            reason: name);
        expect(
          formalSystemsFailureFixtureIsApplicable(source),
          isTrue,
          reason: name,
        );
        expect(formalSystemsReplayAgrees(source), isTrue, reason: name);
      }
    });
  });
}

HardEdgeCatalogCase _catalogCase(FormalSystemsHardEdgeDescriptor descriptor) =>
    HardEdgeCatalogCase(
      id: 'formal-systems-${descriptor.caseId}',
      family: formalSystemsFamilyId,
      algorithm: descriptor.algorithm,
      sourceKind: HardEdgeSourceKind.generated,
      seed: 339,
      property: descriptor.property,
      provenance: const HardEdgeProvenance(
        origin: 'Turing Lab issue #339',
        independentlyAuthored: true,
        generator: formalSystemsGeneratorVersion,
        licenseBasis: 'LICENSE.txt',
      ),
      license: 'Apache-2.0',
      regressionIssue: 339,
      platforms: const ['all'],
      sha256: '0' * 64,
      generatorVersion: formalSystemsGeneratorVersion,
      oracleVersion: formalSystemsOracleVersion,
      budget: const GenerationBudget(
        maxStates: 8,
        maxTransitions: 24,
        maxSymbols: 16,
        maxWordLength: 6,
      ),
      fixture: 'generated-by-family-catalog.json',
      expectedOutcome: HardEdgeExpectedOutcome.pass,
      requiredTool: null,
    );
