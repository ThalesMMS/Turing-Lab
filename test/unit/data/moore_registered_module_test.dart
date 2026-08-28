import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:turing_lab/core/formal_systems/formal_systems.dart';
import 'package:turing_lab/core/interoperability/interoperability.dart';
import 'package:turing_lab/core/models/asset_example.dart';
import 'package:turing_lab/core/transducers/transducers.dart';
import 'package:turing_lab/data/transducers/moore_example_catalog.dart';
import 'package:turing_lab/data/transducers/moore_registered_module.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('Moore catalog loads four valid, distinct scenarios', () async {
    final examples = await MooreExampleCatalog().loadExamples();

    expect(examples, hasLength(4));
    expect(examples.map((example) => example.category).toSet(), {
      ExampleCategory.moore,
    });
    expect(
      examples.map((example) => example.payload.id.value).toSet(),
      hasLength(4),
    );
    expect(examples.map((example) => example.id).toSet(), {
      'asset/moore_parity',
      'asset/moore_vending_control',
      'asset/moore_sequence_detector',
      'asset/moore_partial',
    });
    expect(
      examples.every(
        (example) =>
            TransducerAnalyzer.analyze(example.payload).isStructurallyValid,
      ),
      isTrue,
    );

    final parity = examples.first.payload;
    expect(
      DeterministicTransducerSimulator.moore(parity).runRaw('').output.values,
      ['even'],
    );
    expect(
      DeterministicTransducerSimulator.moore(
        parity,
      ).runRaw('101').output.values,
      ['even', 'odd', 'odd', 'even'],
    );

    final vending = examples[1].payload;
    expect(
      DeterministicTransducerSimulator.moore(vending)
          .run(TransducerInputWord.fromValues(const ['coin', 'vend']))
          .output
          .values,
      ['idle', 'ready', 'idle'],
    );

    final sequence = examples[2].payload;
    expect(
      DeterministicTransducerSimulator.moore(
        sequence,
      ).runRaw('10').output.values,
      ['0', '0', '1'],
    );

    final partial = examples.last.payload;
    final undefined = DeterministicTransducerSimulator.moore(
      partial,
    ).runRaw('aa');
    expect(undefined, isA<TransducerIncomplete>());
    expect(undefined.output.values, ['off', 'on']);
    expect(undefined.processedInputCount, 1);
  });

  test(
    'registered module contributes codecs, examples, and typed session',
    () async {
      final module = createMooreRegisteredModule();

      expect(module.descriptor.key, TransducerFormalSystemIds.moore);
      expect(module.descriptor.route.value, '/moore');
      expect(module.codecs, hasLength(2));
      expect(module.codecs.map((codec) => codec.descriptor.formatId).toSet(), {
        DefaultFormalSystemIds.jflapXmlFormat,
        DefaultFormalSystemIds.turingLabJsonFormat,
      });
      expect(await module.examples!.loadExamples(), hasLength(4));

      final original =
          (await module.examples!.loadExamples()).first.payload as MooreMachine;
      final encoded = module.session!.encodeSession(original);
      final decoded = module.session!.decodeSession(
        encoded,
        schema: module.descriptor.schema,
      );

      expect(decoded, isA<MooreMachine>());
      expect((decoded as MooreMachine).toJson(), original.toJson());
    },
  );

  test('registered codecs detect, decode, and encode both formats', () async {
    final module = createMooreRegisteredModule();
    final registry = DocumentInteroperabilityRegistry.fromFormalSystems(
      FormalSystemRegistry(
        modules: [module],
        formats: FormalSystemRegistry.defaultRegistry.formats.formats,
      ),
    );

    for (final fixture in const [
      'test/fixtures/interoperability/moore_canonical.jff',
      'test/fixtures/interoperability/moore_canonical.json',
    ]) {
      final payload = DocumentPayload(
        bytes: await File(fixture).readAsBytes(),
        filename: fixture,
      );
      final detected = registry.detect(
        payload,
        expectedSystem: TransducerFormalSystemIds.moore,
      );
      expect(detected, isA<CodecSuccess<DetectedDocument>>());

      final decoded = registry.decode(
        payload,
        expectedSystem: TransducerFormalSystemIds.moore,
      );
      expect(decoded, isA<CodecSuccess<InteroperableDocument<Object>>>());
      final document =
          (decoded as CodecSuccess<InteroperableDocument<Object>>).value;
      expect(document.document, isA<MooreMachine>());

      final format = (detected as CodecSuccess<DetectedDocument>)
          .value
          .descriptor
          .formatId;
      final encoded = registry.encode(document, format: format);
      expect(encoded, isA<CodecSuccess<EncodedDocument>>());
    }
  });
}
