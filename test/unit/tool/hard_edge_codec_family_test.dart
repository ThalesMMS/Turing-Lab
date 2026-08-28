import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:test/test.dart';
import 'package:turing_lab/core/formal_systems/formal_systems.dart';
import 'package:turing_lab/core/interoperability/interoperability.dart';
import 'package:turing_lab/data/codecs/pumping_lemma_json_codec.dart';
import 'package:turing_lab/data/codecs/codec_utils.dart';
import 'package:turing_lab/data/codecs/default_document_interoperability_registry.dart';
import 'package:turing_lab/data/codecs/unrestricted_grammar_json_codec.dart';

import '../../../tool/compatibility_corpus/catalog.dart';
import '../../../tool/hard_edge/families/codec_certification.dart';
import '../../../tool/hard_edge/families/codec_executor.dart';
import '../../../tool/hard_edge/families/codec_family.dart';
import '../../../tool/hard_edge/families/codec_matrix.dart';
import '../../../tool/hard_edge/families/codec_mutations.dart';
import '../../../tool/hard_edge/families/codec_parity.dart';
import '../../../tool/hard_edge/families/codec_parity_vectors.dart';

void main() {
  test('matrix matches every live codec and names every boundary class', () {
    final live = CompatibilityCodecCatalog.create().codecs.keys.toList()
      ..sort();
    expect(codecIds, orderedEquals(live));
    expect(codecBoundaryInventory.map((entry) => entry.kind).toSet(), {
      'codec',
      'mapper',
      'conversion',
      'export',
    });
    expect(
      codecBoundaryInventory
          .expand((entry) => entry.entryPoints)
          .where((entry) => entry.contains('CfgToPdaConverter')),
      hasLength(2),
    );
  });

  test('boundary process-tree ordering is deterministic and child-first', () {
    expect(
      CodecBoundaryProcessTree.descendantsDeepestFirst(
        {11: 10, 12: 10, 13: 11, 10: 13},
        10,
      ),
      [13, 11, 12],
    );
  });

  test('boundary subprocess timeout and cancellation are typed', () async {
    final executable = Platform.isWindows ? 'cmd.exe' : '/bin/sh';
    final arguments = Platform.isWindows
        ? ['/d', '/s', '/c', 'ping 127.0.0.1 -n 30 > nul']
        : ['-c', 'sleep 30 & wait'];
    final timedOut = await runCodecBoundaryProcessForCertification(
      executable: executable,
      arguments: arguments,
      timeout: const Duration(milliseconds: 75),
    );
    expect(timedOut.outcome, CodecBoundaryProcessOutcome.timedOut);
    final cancelled = await runCodecBoundaryProcessForCertification(
      executable: executable,
      arguments: arguments,
      timeout: const Duration(seconds: 5),
      isCancelled: () => true,
    );
    expect(cancelled.outcome, CodecBoundaryProcessOutcome.cancelled);
  });

  test('generated fixtures are deterministic and shrink their real payload',
      () {
    final left = materializeCodecPropertyFixture(
      codecId: 'pda.turing-lab-json.v1',
      property: 'migration-extensions',
      seed: 340,
    );
    final right = materializeCodecPropertyFixture(
      codecId: 'pda.turing-lab-json.v1',
      property: 'migration-extensions',
      seed: 340,
    );
    expect(left.toJson(), right.toJson());
    expect(base64Decode(left.payload['sourcePayloadBase64']! as String),
        isNotEmpty);

    final candidates = const CodecFixtureShrinker().candidates(left);
    expect(candidates, isNotEmpty);
    expect(
      candidates.any(
        (candidate) =>
            jsonEncode(candidate.payload).length <
            jsonEncode(left.payload).length,
      ),
      isTrue,
    );
  });

  test('codec shrink preserves the exact divergence and reaches minimum bytes',
      () async {
    final source = materializeCodecPropertyFixture(
      codecId: 'fsa.turing-lab-json.v1',
      property: 'transport-parity',
      seed: 340,
    ).copyWith(
      payload: {
        ...materializeCodecPropertyFixture(
          codecId: 'fsa.turing-lab-json.v1',
          property: 'transport-parity',
          seed: 340,
        ).payload,
        'sourcePayloadBase64': base64Encode(utf8.encode('{')),
      },
    );
    final runner = CodecCertificationRunner();
    final initial = await runner.runProperty(source);
    expect(initial.status, CodecCertificationStatus.failed);
    final signed = source.copyWith(
      payload: {
        ...source.payload,
        'failureSignature': initial.failureSignature,
      },
    );
    final candidates = const CodecFixtureShrinker().candidates(signed).toList();
    final preserving = <CodecHardEdgeFixture>[];
    for (final candidate in candidates) {
      final check = await runner.runProperty(candidate);
      if (check.failureSignature == initial.failureSignature) {
        preserving.add(candidate);
      }
    }
    expect(preserving, isNotEmpty);
    final minimal = preserving.reduce(
      (left, right) =>
          (left.payload['sourcePayloadBase64']! as String).length <=
                  (right.payload['sourcePayloadBase64']! as String).length
              ? left
              : right,
    );
    expect(minimal.payload['sourcePayloadBase64'], isEmpty);
    expect(const CodecFixtureShrinker().candidates(minimal), isEmpty);

    final adapter = codecHardEdgeShrinkAdapter(isApplicable: (_) => true);
    expect(await adapter.isApplicable(minimal.toJson()), isTrue);

    final committed = CodecHardEdgeFixture.fromJson(
      jsonDecode(
        File('test/fixtures/hard_edge/codec/minimized_transport_failure.json')
            .readAsStringSync(),
      ),
    );
    expect(await adapter.isApplicable(committed.toJson()), isTrue);
    expect(const CodecFixtureShrinker().candidates(committed), isEmpty);
  });

  test('native codec outcomes match the committed parity snapshots', () {
    final catalog = CompatibilityCodecCatalog.create();
    expect(
      codecParityVectors.map((vector) => vector.codecId).toList()..sort(),
      orderedEquals(codecIds),
    );
    for (final vector in codecParityVectors) {
      expect(
        codecCanonicalOutcomeSha256(
          catalog.codecs[vector.codecId]!,
          DocumentPayload(bytes: vector.payload, filename: vector.filename),
        ),
        vector.nativeOutcomeSha256,
        reason: vector.codecId,
      );
    }
  });

  test('generated codec IDs use backend-stable FNV-1a vectors', () {
    expect(fnv1a32Hex(''), '811c9dc5');
    expect(fnv1a32Hex('hello'), '4f9f2cab');
    expect(deterministicContentId('probe', 'hello'), 'probe_4f9f2cab');
  });

  test('canonical identity preserves legacy safe values and large integers',
      () {
    const historical = {'n': 1};
    expect(
      canonicalIdentityJson(historical),
      canonicalIdentityJsonV1(historical),
    );
    expect(canonicalIdentityVersionFor(historical), 1);

    final left = canonicalIdentityJson({'n': 9007199254740992});
    final right = canonicalIdentityJson({'n': 9007199254740993});
    expect(left, isNot(right));
    expect(canonicalIdentityVersionFor({'n': 9007199254740993}), 2);
    expect(left, contains(r'"$identityVersion":2'));
    expect(
      canonicalIdentityJson({'n': 9007199254740992}),
      isNot(canonicalIdentityJson({'n': '9007199254740992'})),
    );
  });

  test(
    'all codec properties pass the approved and generated corpus',
    () async {
      final report = await CodecCertificationRunner().run(seed: 340);
      expect(report.checks, hasLength(codecHardEdgeCaseDescriptors.length));
      expect(
        report.checks.where(
          (check) => check.status != CodecCertificationStatus.passed,
        ),
        isEmpty,
      );
      expect(
        report.boundaryEvidence,
        hasLength(codecBoundaryInventory.length - 1),
      );
      expect(
        report.boundaryEvidence.where((evidence) => !evidence.passed),
        isEmpty,
      );
      for (final evidence in report.boundaryEvidence) {
        final boundary = codecBoundaryInventory.singleWhere(
          (entry) => entry.id == evidence.id,
        );
        expect(
          evidence.entryPoints,
          orderedEquals(boundary.entryPoints),
          reason: 'Every claimed ${boundary.id} entrypoint needs its own '
              'passing boundary evidence.',
        );
      }
    },
    timeout: const Timeout(Duration(minutes: 2)),
  );

  test('custom JSON codecs enforce their declared depth budget', () {
    final codecs = <DocumentCodecCapability<Object>>[
      const PumpingLemmaJsonCodec.regular(),
      const PumpingLemmaJsonCodec.contextFree(),
      const UnrestrictedGrammarJsonCodec(),
    ];
    for (final codec in codecs) {
      final depth = codec.descriptor.securityLimits.maximumDepth + 1;
      final source = '${'[' * depth}0${']' * depth}';
      final outcome = codec.decode(
        DocumentPayload(
          bytes: Uint8List.fromList(utf8.encode(source)),
          filename: 'deep.json',
        ),
      );
      expect(
        outcome,
        isA<CodecResourceLimit<InteroperableDocument<Object>>>().having(
          (value) => value.limit,
          'limit',
          CodecResourceLimitKind.jsonDepth,
        ),
        reason: codec.descriptor.codecId.value,
      );
    }
  });

  test('custom JSON codecs enforce their declared collection budget', () {
    final codecs = <DocumentCodecCapability<Object>>[
      const PumpingLemmaJsonCodec.regular(),
      const PumpingLemmaJsonCodec.contextFree(),
      const UnrestrictedGrammarJsonCodec(),
    ];
    for (final codec in codecs) {
      final entries = codec.descriptor.securityLimits.maximumCollectionEntries;
      final source = jsonEncode({'items': List<int>.filled(entries + 1, 0)});
      final outcome = codec.decode(
        DocumentPayload(
          bytes: Uint8List.fromList(utf8.encode(source)),
          filename: 'wide.json',
        ),
      );
      expect(
        outcome,
        isA<CodecResourceLimit<InteroperableDocument<Object>>>().having(
          (value) => value.limit,
          'limit',
          CodecResourceLimitKind.collectionEntries,
        ),
        reason: codec.descriptor.codecId.value,
      );
    }
  });

  test('JSON sniffers reject over-depth content before decoding', () {
    final codecs = <DocumentCodecCapability<Object>>[
      ...CompatibilityCodecCatalog.create().codecs.values.where(
            (codec) => codec.descriptor.formatId.value == 'turing-lab-json',
          ),
    ];
    for (final codec in codecs) {
      final depth = codec.descriptor.securityLimits.maximumDepth + 1;
      final source = '${'[' * depth}0${']' * depth}';
      expect(
        codec
            .sniff(
              DocumentPayload(
                bytes: Uint8List.fromList(utf8.encode(source)),
                filename: 'deep.json',
              ),
            )
            .confidence,
        0,
        reason: codec.descriptor.codecId.value,
      );
    }
  });

  test('registry import keeps the JSON depth outcome typed', () {
    final registry = DefaultDocumentInteroperabilityRegistry.create();
    const codec = PumpingLemmaJsonCodec.regular();
    final depth = codec.descriptor.securityLimits.maximumDepth + 1;
    final source = '${'[' * depth}0${']' * depth}';
    final outcome = registry.decode(
      DocumentPayload(
        bytes: Uint8List.fromList(utf8.encode(source)),
        filename: 'deep.json',
      ),
      expectedSystem: codec.systemKey,
      expectedFormat: DefaultFormalSystemIds.turingLabJsonFormat,
    );
    expect(
      outcome,
      isA<CodecResourceLimit<InteroperableDocument<Object>>>().having(
        (value) => value.limit,
        'limit',
        CodecResourceLimitKind.jsonDepth,
      ),
    );
  });

  test('pumping JSON preserves unknown extension fields exactly', () {
    for (final codec in <PumpingLemmaJsonCodec>[
      const PumpingLemmaJsonCodec.regular(),
      const PumpingLemmaJsonCodec.contextFree(),
    ]) {
      final fixture = codec.descriptor.canonicalFixtures.single;
      final json = jsonDecode(File(fixture).readAsStringSync()) as Map;
      json['x-hard-edge-extension'] = {
        'tokens': ['multi-token', 'β', '🧪'],
      };
      final outcome = codec.decode(
        DocumentPayload(
          bytes: Uint8List.fromList(utf8.encode(jsonEncode(json))),
          filename: 'historical.json',
        ),
      );
      expect(outcome, isA<CodecSuccess<InteroperableDocument<Object>>>());
      final decoded = outcome as CodecSuccess<InteroperableDocument<Object>>;
      expect(decoded.fidelity, DocumentFidelity.exact);
      expect(
        decoded.value.extensions.values['x-hard-edge-extension'],
        json['x-hard-edge-extension'],
      );
      final encoded =
          codec.encode(decoded.value) as CodecSuccess<EncodedDocument>;
      final replay = jsonDecode(utf8.decode(encoded.value.bytes)) as Map;
      expect(replay['x-hard-edge-extension'], json['x-hard-edge-extension']);
    }
  });

  test('production-adapter mutation threshold kills four of four', () async {
    final evidence = <CodecMutationEvidence>[];
    for (final operator in codecMutationOperators.values) {
      evidence.add(await evaluateCodecProductionMutation(operator));
    }
    expect(codecMutationKillThreshold, 4);
    expect(evidence, hasLength(codecMutationKillThreshold));
    expect(evidence.where((item) => item.killed), hasLength(4));
    expect(evidence.where((item) => !item.killed), isEmpty);
  });
}
