import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:turing_lab/core/formal_systems/formal_systems.dart';
import 'package:turing_lab/core/interoperability/interoperability.dart';
import 'package:turing_lab/core/l_systems/l_systems.dart';
import 'package:turing_lab/data/codecs/l_system_jflap_codec.dart';
import 'package:turing_lab/data/codecs/l_system_json_codec.dart';

void main() {
  group('JFLAP L-system codec', () {
    test('loads canonical fixture with JFLAP drawing semantics', () {
      final outcome = const LSystemJflapCodec().decode(_fixture('jff'));
      expect(
        outcome,
        isA<CodecSuccess<InteroperableDocument<LSystemDocument>>>(),
      );
      final system =
          (outcome as CodecSuccess<InteroperableDocument<LSystemDocument>>)
              .value
              .document;
      expect(system.axiom.symbols, ['F']);
      expect(system.productions.single.successor.symbols, [
        'F',
        '+',
        'F',
        '-',
        'F',
        '-',
        'F',
        '+',
        'F',
      ]);
      expect(system.iterations, 2);
      expect(system.turtle.angleDegrees, 90);
      expect(
        system.commandMapping.commands['g'],
        LSystemTurtleCommand.drawForward,
      );
    });

    test('round trip preserves deterministic token vectors and settings', () {
      const codec = LSystemJflapCodec();
      final first =
          codec.decode(_fixture('jff'))
              as CodecSuccess<InteroperableDocument<LSystemDocument>>;
      final encoded =
          codec.encode(first.value) as CodecSuccess<EncodedDocument>;
      final second =
          codec.decode(DocumentPayload(bytes: encoded.value.bytes))
              as CodecSuccess<InteroperableDocument<LSystemDocument>>;
      expect(second.value.document.axiom, first.value.document.axiom);
      expect(
        second.value.document.productions.single.successor,
        first.value.document.productions.single.successor,
      );
      expect(
        second.value.document.turtle.toJson(),
        first.value.document.turtle.toJson(),
      );
    });

    test('round trip preserves advanced rewriting and turtle metadata', () {
      final system = LSystemDocument(
        id: 'advanced',
        name: 'Advanced',
        revision: 1,
        axiom: LSystemWord(const ['L', 'A', 'R']),
        productions: [
          LSystemProduction(
            id: 'context-red',
            predecessor: 'A',
            successor: LSystemWord(const ['red']),
            leftContext: LSystemWord(const ['L']),
            rightContext: LSystemWord(const ['R']),
            weight: 2,
          ),
          LSystemProduction(
            id: 'context-blue',
            predecessor: 'A',
            successor: LSystemWord(const ['blue']),
            leftContext: LSystemWord(const ['L']),
            rightContext: LSystemWord(const ['R']),
          ),
        ],
        iterations: 3,
        turtle: LSystemTurtleSettings(
          lineWidthIncrement: 2,
          hueIncrementDegrees: 30,
          initialColorArgb: 0xff336699,
          initialPolygonColorArgb: 0xff663399,
        ),
        commandMapping: LSystemCommandMapping.jflap,
        randomSeed: -17,
        ignoredContextSymbols: const {'+', '-'},
      );
      const codec = LSystemJflapCodec();
      final encoded =
          codec.encode(
                InteroperableDocument(
                  document: system,
                  systemKey: LSystemFormalSystemIds.key,
                  schema: LSystemJflapCodec.schema,
                ),
              )
              as CodecSuccess<EncodedDocument>;
      final decoded =
          codec.decode(DocumentPayload(bytes: encoded.value.bytes))
              as CodecSuccess<InteroperableDocument<LSystemDocument>>;

      expect(decoded.value.document.productions, hasLength(2));
      expect(decoded.value.document.axiom, system.axiom);
      expect(
        {
          for (final value in decoded.value.document.productions)
            value.id: value.toJson(),
        },
        {for (final value in system.productions) value.id: value.toJson()},
      );
      expect(decoded.value.document.iterations, system.iterations);
      expect(decoded.value.document.turtle.toJson(), system.turtle.toJson());
      expect(
        decoded.value.document.commandMapping.toJson(),
        system.commandMapping.toJson(),
      );
      expect(decoded.value.document.randomSeed, system.randomSeed);
      expect(
        decoded.value.document.ignoredContextSymbols,
        system.ignoredContextSymbols,
      );
      expect(
        decoded.diagnostics.map((diagnostic) => diagnostic.code),
        contains('jflap.l-system.execution-extension-restored'),
      );
    });

    test('execution extension reports only active encoded features', () {
      final system = LSystemDocument(
        id: 'weighted-only',
        name: 'Weighted only',
        revision: 1,
        axiom: LSystemWord(const ['A']),
        productions: [
          LSystemProduction(
            id: 'weighted',
            predecessor: 'A',
            successor: LSystemWord(const ['B']),
            weight: 2,
          ),
        ],
        iterations: 1,
        turtle: LSystemTurtleSettings(),
        commandMapping: LSystemCommandMapping.standard,
      );

      final encoded =
          const LSystemJflapCodec().encode(
                InteroperableDocument(
                  document: system,
                  systemKey: LSystemFormalSystemIds.key,
                  schema: LSystemJflapCodec.schema,
                ),
              )
              as CodecSuccess<EncodedDocument>;
      final diagnostic = encoded.diagnostics.singleWhere(
        (candidate) => candidate.code == 'jflap.l-system.execution-extension',
      );

      expect(
        diagnostic.structuredMessage?.arguments['features']?.value,
        'weighted-choices',
      );
    });

    test(
      'executes stochastic and context rules while preserving parametric rules',
      () {
        const source = '''<structure><type>lsystem</type><axiom>A</axiom>
<production><left>A</left><right>B</right><right>C</right></production>
<production><left>1 A B</left><right>D</right></production>
<production><left>F(x)</left><right>F(x+1)</right></production></structure>''';
        final outcome =
            const LSystemJflapCodec().decode(_payload(source))
                as CodecSuccess<InteroperableDocument<LSystemDocument>>;
        expect(outcome.value.document.unsupportedVariants, {
          LSystemUnsupportedVariant.parametric,
        });
        expect(outcome.value.document.productions, hasLength(3));
        expect(
          outcome.value.document.productions.where(
            (production) => production.predecessor == 'A',
          ),
          hasLength(2),
        );
        final contextual = outcome.value.document.productions.singleWhere(
          (production) => production.predecessor == 'B',
        );
        expect(contextual.leftContext.symbols, ['A']);
        expect(contextual.rightContext, isEmpty);
        expect(
          outcome.value.document.unsupportedMetadata['jflapRules'],
          isNotEmpty,
        );
        expect(
          const LSystemExpander().expand(outcome.value.document),
          isA<LSystemExpansionInvalid>(),
        );
      },
    );

    test('rejects malformed, unsafe, and invalid numeric XML typingly', () {
      expect(
        const LSystemJflapCodec().decode(_payload('<structure>')),
        isA<CodecMalformed<InteroperableDocument<LSystemDocument>>>(),
      );
      expect(
        const LSystemJflapCodec().decode(
          _payload('<!DOCTYPE x [<!ENTITY y "z">]><structure/>'),
        ),
        isA<CodecResourceLimit<InteroperableDocument<LSystemDocument>>>(),
      );
      expect(
        const LSystemJflapCodec().decode(
          _payload(
            '<structure><type>lsystem</type><axiom>F</axiom>'
            '<parameter><name>distance</name><value>-1</value></parameter>'
            '</structure>',
          ),
        ),
        isA<CodecMalformed<InteroperableDocument<LSystemDocument>>>(),
      );
    });

    test('imports argument commands without treating them as parametric', () {
      const source = '''<structure><type>lsystem</type><axiom>A</axiom>
<production><left>A</left><right>color(orange) g(2)</right></production>
</structure>''';
      final outcome =
          const LSystemJflapCodec().decode(_payload(source))
              as CodecSuccess<InteroperableDocument<LSystemDocument>>;

      expect(outcome.value.document.unsupportedVariants, isEmpty);
      expect(outcome.value.document.productions.single.successor.symbols, [
        'color(orange)',
        'g(2)',
      ]);
    });

    test('reads and writes native JFLAP turtle parameters and defaults', () {
      const source = '''<structure><type>lsystem</type><axiom>g</axiom>
<parameter><name>angleIncrement</name><value>30</value></parameter>
<parameter><name>lineIncrement</name><value>2</value></parameter>
<parameter><name>hueChange</name><value>45</value></parameter>
<parameter><name>color</name><value>orange</value></parameter>
<parameter><name>polygonColor</name><value>dukeBlue</value></parameter>
</structure>''';
      const codec = LSystemJflapCodec();
      final first =
          codec.decode(_payload(source))
              as CodecSuccess<InteroperableDocument<LSystemDocument>>;

      expect(first.value.document.turtle.angleDegrees, 30);
      expect(first.value.document.turtle.stepLength, 15);
      expect(first.value.document.turtle.lineWidthIncrement, 2);
      expect(first.value.document.turtle.hueIncrementDegrees, 45);
      expect(first.value.document.turtle.initialColorArgb, 0xffffc800);
      expect(first.value.document.turtle.initialPolygonColorArgb, 0xff00009c);

      final encoded =
          codec.encode(first.value) as CodecSuccess<EncodedDocument>;
      final xml = utf8.decode(encoded.value.bytes);
      for (final parameter in [
        'angleIncrement',
        'lineIncrement',
        'hueChange',
        'color',
        'polygonColor',
      ]) {
        expect(xml, contains('<name>$parameter</name>'));
      }
    });

    test('reports the native color parameter that failed to parse', () {
      const source = '''<structure><type>lsystem</type><axiom>F</axiom>
<parameter><name>color</name><value>not-a-color</value></parameter>
</structure>''';
      const codec = LSystemJflapCodec();

      final outcome =
          codec.decode(_payload(source))
              as CodecMalformed<InteroperableDocument<LSystemDocument>>;

      expect(
        outcome.structuredMessage?.stableCode,
        'codec.l-system-jflap.invalid-parameter',
      );
      expect(outcome.structuredMessage?.arguments['parameter']?.value, 'color');
    });
  });

  group('Turing Lab L-system JSON codec', () {
    test('canonical fixture round trips deterministically', () {
      final codec = LSystemJsonCodec();
      final decoded =
          codec.decode(_fixture('json'))
              as CodecSuccess<InteroperableDocument<LSystemDocument>>;
      final first =
          codec.encode(decoded.value) as CodecSuccess<EncodedDocument>;
      final again =
          codec.decode(DocumentPayload(bytes: first.value.bytes))
              as CodecSuccess<InteroperableDocument<LSystemDocument>>;
      final second = codec.encode(again.value) as CodecSuccess<EncodedDocument>;
      expect(second.value.bytes, first.value.bytes);
      expect(again.value.document.axiom.symbols, ['F']);
    });

    test('malformed and future schema fail without a partial document', () {
      final codec = LSystemJsonCodec();
      expect(
        codec.decode(_payload('{bad')),
        isA<CodecMalformed<InteroperableDocument<LSystemDocument>>>(),
      );
      final fixture = jsonDecode(utf8.decode(_fixture('json').bytes)) as Map;
      (fixture['document'] as Map)['schema'] = {
        'id': 'turing-lab.l-system',
        'version': 2,
      };
      expect(
        codec.decode(_payload(jsonEncode(fixture))),
        isA<CodecUnsupported<InteroperableDocument<LSystemDocument>>>(),
      );
    });

    test('unsupported metadata and Unicode boundaries survive exactly', () {
      final system = LSystemDocument(
        id: 'advanced',
        name: 'Advanced',
        revision: 2,
        axiom: LSystemWord(['F(α)', '🌿 branch']),
        productions: const [],
        iterations: 0,
        turtle: LSystemTurtleSettings(),
        commandMapping: LSystemCommandMapping.standard,
        unsupportedVariants: const [LSystemUnsupportedVariant.parametric],
        unsupportedMetadata: const {'source': 'F(α)'},
      );
      final codec = LSystemJsonCodec();
      final encoded =
          codec.encode(
                InteroperableDocument(
                  document: system,
                  systemKey: LSystemFormalSystemIds.key,
                  schema: const DocumentSchemaDescriptor(
                    id: DocumentSchemaId('turing-lab.l-system'),
                    version: DocumentSchemaVersion(1),
                  ),
                ),
              )
              as CodecSuccess<EncodedDocument>;
      final decoded =
          codec.decode(DocumentPayload(bytes: encoded.value.bytes))
              as CodecSuccess<InteroperableDocument<LSystemDocument>>;
      expect(decoded.value.document.toJson(), system.toJson());
    });
  });
}

DocumentPayload _fixture(String extension) => DocumentPayload(
  bytes: File(
    'test/fixtures/interoperability/l_system_canonical.$extension',
  ).readAsBytesSync(),
  filename: 'canonical.$extension',
);

DocumentPayload _payload(String source) =>
    DocumentPayload(bytes: Uint8List.fromList(utf8.encode(source)));
