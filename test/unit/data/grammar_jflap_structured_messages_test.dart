import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:turing_lab/core/formal_systems/formal_systems.dart';
import 'package:turing_lab/core/interoperability/interoperability.dart';
import 'package:turing_lab/core/messages/structured_message.dart';
import 'package:turing_lab/core/models/grammar.dart';
import 'package:turing_lab/core/models/production.dart';
import 'package:turing_lab/data/codecs/grammar_jflap_codec.dart';
import 'package:turing_lab/data/codecs/grammar_jflap_messages.dart';

void main() {
  const codec = GrammarJflapDocumentCodec();

  group('Grammar JFLAP codec structured outcomes', () {
    test('unsupported document type carries a typed source value', () {
      final outcome = codec.decode(
        _payload('<structure><type>fa</type></structure>'),
      );

      expect(outcome, isA<CodecUnsupported<InteroperableDocument<Object>>>());
      final unsupported =
          outcome as CodecUnsupported<InteroperableDocument<Object>>;
      expect(unsupported.message, 'JFLAP document type fa is not grammar.');
      expect(
        unsupported.structuredMessage?.stableCode,
        'codec.grammar-jflap.unsupported-document-type',
      );
      expect(
        unsupported.structuredMessage?.arguments['type'],
        StructuredMessageArgument.literal('fa', role: 'document-type'),
      );
      _expectRoundTrip(unsupported.structuredMessage!);
    });

    test('empty and malformed productions preserve locations and indexes', () {
      final empty = codec.decode(
        _payload('<structure><type>grammar</type></structure>'),
      );
      final emptyMalformed =
          empty as CodecMalformed<InteroperableDocument<Object>>;
      expect(emptyMalformed.reason, CodecMalformedReason.missingField);
      expect(emptyMalformed.message, 'JFLAP grammar contains no productions.');
      expect(emptyMalformed.location?.path, '/structure/production');
      expect(
        emptyMalformed.structuredMessage?.stableCode,
        'codec.grammar-jflap.empty-grammar',
      );

      final missingSide = codec.decode(
        _payload('''
<structure type="grammar"><type>grammar</type>
  <production><right>a</right></production>
</structure>'''),
      );
      final malformed =
          missingSide as CodecMalformed<InteroperableDocument<Object>>;
      expect(
        malformed.message,
        'Production 0 is missing a non-empty left side.',
      );
      expect(malformed.location?.path, '/structure/production[0]/left');
      expect(
        malformed.structuredMessage?.arguments['index'],
        StructuredMessageArgument.index(0, role: 'production-index'),
      );
      _expectRoundTrip(emptyMalformed.structuredMessage!);
      _expectRoundTrip(malformed.structuredMessage!);
    });
  });

  test(
    'import diagnostics carry structured payloads and retain legacy fields',
    () {
      const source = '''
<structure type="grammar" vendor="root">
  <type>grammar</type>
  <metadata>root</metadata>
  <grammar type="vendorGrammar" vendor="grammar">
    <start>S</start>
    <production vendor="production">
      <left>S</left><right>a</right><annotation>production</annotation>
    </production>
  </grammar>
</structure>''';

      final outcome = codec.decode(_payload(source));
      final success = outcome as CodecSuccess<InteroperableDocument<Object>>;

      final tokenization = success.diagnostics.firstWhere(
        (diagnostic) =>
            diagnostic.code == 'jflap.grammar-tokenization-normalized',
      );
      expect(
        tokenization.structuredMessage?.stableCode,
        'codec.grammar-jflap.tokenization-normalized',
      );
      expect(tokenization.disposition, CodecDiagnosticDisposition.normalized);

      final unknownType = success.diagnostics.firstWhere(
        (diagnostic) =>
            diagnostic.code == 'jflap.unknown-grammar-type-preserved',
      );
      expect(unknownType.sourceValue, 'vendorGrammar');
      expect(unknownType.disposition, CodecDiagnosticDisposition.dropped);
      expect(
        unknownType.structuredMessage?.arguments['type'],
        StructuredMessageArgument.literal(
          'vendorGrammar',
          role: 'grammar-type',
        ),
      );

      final unknownElement = success.diagnostics.firstWhere(
        (diagnostic) => diagnostic.code == 'jflap.unknown-optional-element',
      );
      expect(unknownElement.path, 'extensions');
      expect(
        unknownElement.structuredMessage?.arguments['extension'],
        StructuredMessageArgument.literal('extensions', role: 'extension-key'),
      );

      for (final diagnostic in success.diagnostics) {
        expect(diagnostic.structuredMessage, isNotNull);
        _expectRoundTrip(diagnostic.structuredMessage!);
      }
    },
  );

  test('export diagnostics preserve loss details and typed values', () {
    final outcome = codec.encode(_lossyGrammarDocument());
    final success = outcome as CodecSuccess<EncodedDocument>;

    expect(success.fidelity, DocumentFidelity.lossy);
    expect(
      success.diagnostics.map((diagnostic) => diagnostic.code),
      containsAll({
        'jflap.grammar-token-boundaries-lossy',
        'jflap.grammar-classification-lossy',
      }),
    );

    final boundaries = success.diagnostics.firstWhere(
      (diagnostic) => diagnostic.code == 'jflap.grammar-token-boundaries-lossy',
    );
    expect(boundaries.sourceValue, ['identifier']);
    expect(
      boundaries.structuredMessage?.arguments['tokens'],
      StructuredMessageArgument.literal('identifier', role: 'token-list'),
    );

    final classification = success.diagnostics.firstWhere(
      (diagnostic) => diagnostic.code == 'jflap.grammar-classification-lossy',
    );
    expect(classification.sourceValue, 'regular');
    expect(
      classification.structuredMessage?.arguments['classification'],
      StructuredMessageArgument.literal(
        'regular',
        role: 'grammar-classification',
      ),
    );

    for (final diagnostic in success.diagnostics) {
      expect(diagnostic.structuredMessage, isNotNull);
      _expectRoundTrip(diagnostic.structuredMessage!);
    }
  });

  test('unsupported and invalid export outcomes are structured', () {
    final foreign =
        codec.encode(
              InteroperableDocument<Object>(
                document: Object(),
                systemKey: DefaultFormalSystemIds.fsa,
                schema: const DocumentSchemaDescriptor(
                  id: DocumentSchemaId('turing-lab.fsa'),
                  version: DocumentSchemaVersion(1),
                ),
              ),
            )
            as CodecUnsupported<EncodedDocument>;
    expect(foreign.message, 'Grammar JFLAP codec requires a Grammar document.');
    expect(
      foreign.structuredMessage?.stableCode,
      'codec.grammar-jflap.requires-grammar-document',
    );

    final wrongSchema =
        codec.encode(
              InteroperableDocument<Object>(
                document: _validGrammar(),
                systemKey: DefaultFormalSystemIds.grammar,
                schema: const DocumentSchemaDescriptor(
                  id: DocumentSchemaId('turing-lab.grammar'),
                  version: DocumentSchemaVersion(2),
                ),
              ),
            )
            as CodecUnsupported<EncodedDocument>;
    expect(
      wrongSchema.structuredMessage?.arguments['version'],
      StructuredMessageArgument.integer(2, role: 'schema-version'),
    );

    final invalid =
        codec.encode(_invalidGrammarDocument())
            as CodecMalformed<EncodedDocument>;
    expect(invalid.message, 'Grammar ID cannot be empty');
    expect(
      invalid.structuredMessage?.stableCode,
      'codec.grammar-jflap.invalid-document',
    );
    _expectRoundTrip(foreign.structuredMessage!);
    _expectRoundTrip(wrongSchema.structuredMessage!);
    _expectRoundTrip(invalid.structuredMessage!);
  });

  test('companion contracts are stable and round-trippable', () {
    final messages = <StructuredMessage>[
      GrammarJflapMessages.unsupportedDocumentType('fa'),
      GrammarJflapMessages.emptyGrammar(),
      GrammarJflapMessages.missingProductionSide(0),
      GrammarJflapMessages.startSymbolUndetermined(),
      GrammarJflapMessages.unknownGrammarTypePreserved('vendor'),
      GrammarJflapMessages.unknownOptionalElement('extensions'),
      GrammarJflapMessages.tokenizationNormalized(),
      GrammarJflapMessages.requiresGrammarDocument(),
      GrammarJflapMessages.unsupportedSchema(2),
      GrammarJflapMessages.invalidDocument(),
      GrammarJflapMessages.tokenBoundariesLossy('identifier'),
      GrammarJflapMessages.classificationLossy('regular'),
    ];

    expect(messages, everyElement(isA<StructuredMessage>()));
    expect(
      messages.map((message) => message.namespace),
      everyElement(GrammarJflapMessages.namespace),
    );
    for (final message in messages) {
      _expectRoundTrip(message);
    }
  });
}

DocumentPayload _payload(String source) => DocumentPayload(
  bytes: Uint8List.fromList(utf8.encode(source)),
  filename: 'grammar.jff',
);

void _expectRoundTrip(StructuredMessage message) {
  expect(StructuredMessage.fromJson(message.toJson()), message);
}

InteroperableDocument<Object> _lossyGrammarDocument() =>
    InteroperableDocument<Object>(
      document: Grammar(
        id: 'grammar',
        name: 'Grammar',
        terminals: const {'identifier'},
        nonterminals: const {'S'},
        startSymbol: 'S',
        productions: {
          const Production(
            id: 'p0',
            leftSide: ['S'],
            rightSide: ['identifier'],
            isLambda: false,
            order: 0,
          ),
        },
        type: GrammarType.regular,
        created: DateTime.utc(2026),
        modified: DateTime.utc(2026),
      ),
      systemKey: DefaultFormalSystemIds.grammar,
      schema: GrammarJflapDocumentCodec.descriptorSchema,
    );

Grammar _validGrammar() => Grammar(
  id: 'grammar',
  name: 'Grammar',
  terminals: const {'a'},
  nonterminals: const {'S'},
  startSymbol: 'S',
  productions: {
    const Production(
      id: 'p0',
      leftSide: ['S'],
      rightSide: ['a'],
      isLambda: false,
      order: 0,
    ),
  },
  type: GrammarType.contextFree,
  created: DateTime.utc(2026),
  modified: DateTime.utc(2026),
);

InteroperableDocument<Object> _invalidGrammarDocument() =>
    InteroperableDocument<Object>(
      document: Grammar(
        id: '',
        name: 'Grammar',
        terminals: const {'a'},
        nonterminals: const {'S'},
        startSymbol: 'S',
        productions: {
          const Production(
            id: 'p0',
            leftSide: ['S'],
            rightSide: ['a'],
            isLambda: false,
            order: 0,
          ),
        },
        type: GrammarType.contextFree,
        created: DateTime.fromMillisecondsSinceEpoch(0, isUtc: true),
        modified: DateTime.fromMillisecondsSinceEpoch(0, isUtc: true),
      ),
      systemKey: DefaultFormalSystemIds.grammar,
      schema: GrammarJflapDocumentCodec.descriptorSchema,
    );
