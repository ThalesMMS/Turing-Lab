import 'dart:convert';
import 'dart:io';
import 'dart:math' as math;
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:turing_lab/core/formal_systems/formal_systems.dart';
import 'package:turing_lab/core/annotations/annotations.dart';
import 'package:turing_lab/core/interoperability/interoperability.dart';
import 'package:turing_lab/core/models/fsa.dart';
import 'package:turing_lab/core/models/fsa_transition.dart';
import 'package:turing_lab/core/models/grammar.dart';
import 'package:turing_lab/core/models/production.dart';
import 'package:turing_lab/core/models/state.dart';
import 'package:turing_lab/data/codecs/default_document_interoperability_registry.dart';
import 'package:turing_lab/data/codecs/fsa_jflap_codec.dart';
import 'package:turing_lab/data/codecs/grammar_jflap_codec.dart';
import 'package:turing_lab/data/codecs/hardened_xml.dart';
import 'package:turing_lab/data/codecs/versioned_json_document_codec.dart';
import 'package:vector_math/vector_math_64.dart';
import 'package:xml/xml.dart';

void main() {
  group('hardened XML', () {
    test('rejects DTD and external entities before parsing', () {
      final outcome = parseHardenedXml(
        _payload(
          '<!DOCTYPE x [<!ENTITY read SYSTEM "file:///etc/passwd">]>'
          '<structure><type>&read;</type></structure>',
        ),
        CodecSecurityLimits(),
      );

      expect(outcome, isA<CodecResourceLimit<XmlDocument>>());
      expect(
        (outcome as CodecResourceLimit<XmlDocument>).limit,
        CodecResourceLimitKind.xmlDtdOrEntity,
      );
    });

    test('reports truncated XML with a source location', () {
      final outcome = parseHardenedXml(
        _payload('<structure><type>fa</type>', sourcePath: 'broken.jff'),
        CodecSecurityLimits(),
      );

      expect(outcome, isA<CodecMalformed<XmlDocument>>());
      final malformed = outcome as CodecMalformed<XmlDocument>;
      expect(malformed.reason, CodecMalformedReason.syntax);
      expect(malformed.location?.path, 'broken.jff');
      expect(malformed.location?.line, isNotNull);
    });

    test('enforces byte, depth, element and collection limits', () {
      expect(
        parseHardenedXml(
          _payload('<a/>'),
          CodecSecurityLimits(maximumBytes: 3),
        ),
        isA<CodecResourceLimit<XmlDocument>>(),
      );
      const deep = '<a><b><c/></b></a>';
      final depth = parseHardenedXml(
        _payload(deep),
        CodecSecurityLimits(maximumDepth: 2),
      );
      expect((depth as CodecResourceLimit<XmlDocument>).limit,
          CodecResourceLimitKind.xmlDepth);
      final elements = parseHardenedXml(
        _payload('<a><b/><c/></a>'),
        CodecSecurityLimits(maximumElements: 2),
      );
      expect((elements as CodecResourceLimit<XmlDocument>).limit,
          CodecResourceLimitKind.xmlElements);
      final unicodeDepth = parseHardenedXml(
        _payload('<á><β><γ/></β></á>'),
        CodecSecurityLimits(maximumDepth: 2),
      );
      expect(
        (unicodeDepth as CodecResourceLimit<XmlDocument>).limit,
        CodecResourceLimitKind.xmlDepth,
      );
    });
  });

  group('JFLAP codecs', () {
    test('FSA derives a stable label while preserving explicit labels', () {
      final first = _fsaDocument(symbols: {'b', 'a'}).document as FSA;
      final transition = first.transitions.single as FSATransition;
      expect(transition.label, 'a,b');

      final custom = FSATransition(
        id: 'custom',
        fromState: first.states.first,
        toState: first.states.last,
        inputSymbols: const {'b', 'a'},
        label: 'custom label',
      );
      expect(custom.label, 'custom label');
    });

    test('detect content even when the filename extension is wrong', () {
      final registry = DefaultDocumentInteroperabilityRegistry.create();
      final fsa = registry.detect(
        _payload(_fsaXml, filename: 'machine.txt'),
      );
      final grammar = registry.detect(
        _payload(_grammarXml, filename: 'grammar.bin'),
      );

      expect(
        (fsa as CodecSuccess<DetectedDocument>).value.descriptor.systemKey,
        DefaultFormalSystemIds.fsa,
      );
      expect(
        (grammar as CodecSuccess<DetectedDocument>).value.descriptor.systemKey,
        DefaultFormalSystemIds.grammar,
      );
    });

    test('FSA preserves nested optional data with provenance', () {
      const codec = FsaJflapDocumentCodec();
      final decoded = codec.decode(_payload(_fsaXmlWithExtensions));

      expect(decoded, isA<CodecSuccess<InteroperableDocument<Object>>>());
      final success = decoded as CodecSuccess<InteroperableDocument<Object>>;
      expect(success.value.extensions.values, contains('rootAttributes'));
      expect(
        success.value.extensions.values,
        contains('transitionChildren.t0'),
      );
      expect(
        success.diagnostics.map((diagnostic) => diagnostic.code),
        contains('jflap.unknown-optional-element'),
      );

      final encoded = codec.encode(success.value);
      final xml = utf8.decode(
        (encoded as CodecSuccess<EncodedDocument>).value.bytes,
      );
      expect(xml, contains('vendor="root"'));
      expect(xml, contains('<custom keep="yes"/>'));
      expect(xml, contains('<note>state note</note>'));
    });

    test('multi-symbol transition does not duplicate extension data', () {
      const codec = FsaJflapDocumentCodec();
      final document = _fsaDocument(
        symbols: {'b', 'a'},
        extensions: DocumentExtensionBag({
          'transitionAttributes.t0': {'vendor': 'once'},
          'transitionChildren.t0': ['<custom/>'],
        }),
      );

      final encoded = codec.encode(document);

      expect(encoded, isA<CodecSuccess<EncodedDocument>>());
      final success = encoded as CodecSuccess<EncodedDocument>;
      final xml = utf8.decode(success.value.bytes);
      expect(RegExp('vendor="once"').allMatches(xml), hasLength(1));
      expect(RegExp('<custom/>').allMatches(xml), hasLength(1));
      expect(
        success.diagnostics.map((diagnostic) => diagnostic.code),
        contains('jflap.multi-symbol-transition-expanded'),
      );
    });

    test('FSA imports and exports JFLAP notes as typed annotations', () {
      const source = '''
<structure>
  <type>fa</type>
  <automaton>
    <state id="0" name="q0"><x>10</x><y>20</y><initial/></state>
    <note><text>Check this state</text><x>30</x><y>40</y></note>
  </automaton>
</structure>''';
      const codec = FsaJflapDocumentCodec();

      final decoded = codec.decode(_payload(source))
          as CodecSuccess<InteroperableDocument<Object>>;
      final annotations = annotationsFromExtensions(decoded.value.extensions)!;

      expect(annotations.annotations.single.text, 'Check this state');
      expect(annotations.annotations.single.x, 30);
      expect(
        decoded.diagnostics.map((diagnostic) => diagnostic.code),
        contains('jflap.notes-normalized'),
      );
      final encoded =
          codec.encode(decoded.value) as CodecSuccess<EncodedDocument>;
      final xml = utf8.decode(encoded.value.bytes);
      expect(xml, contains('<text>Check this state</text>'));
      expect(xml, contains('<x>30</x>'));
      expect(xml, contains('<y>40</y>'));
    });

    test('FSA reports unsupported annotation presentation on JFLAP export', () {
      final base = _fsaDocument();
      final fsa = base.document as FSA;
      final annotations = DocumentAnnotationCollection(
        documentId: fsa.id,
        documentRevision: '1',
        annotations: [
          DocumentAnnotation(
            id: 'note-1',
            documentId: fsa.id,
            documentRevision: '1',
            text: 'Attached warning',
            x: 10,
            y: 20,
            attachment: const AnnotationAttachment(
              type: AnnotationTargetType.state,
              targetId: 'q0',
            ),
            styleRole: AnnotationStyleRole.warning,
            collapsed: true,
            createdAt: DateTime.utc(2026),
            updatedAt: DateTime.utc(2026),
          ),
        ],
      );
      final document = InteroperableDocument<Object>(
        document: fsa,
        systemKey: base.systemKey,
        schema: base.schema,
        extensions: extensionsWithAnnotations(base.extensions, annotations),
      );

      final encoded = const FsaJflapDocumentCodec().encode(document)
          as CodecSuccess<EncodedDocument>;

      expect(encoded.fidelity, DocumentFidelity.lossy);
      expect(
        encoded.diagnostics.map((diagnostic) => diagnostic.code),
        contains('jflap.note-presentation-dropped'),
      );
    });

    test('explicit epsilon aliases require lossy import confirmation', () {
      final source = _fsaXml.replaceFirst('<read>a</read>', '<read>eps</read>');
      final outcome = const FsaJflapDocumentCodec().decode(_payload(source));

      final success = outcome as CodecSuccess<InteroperableDocument<Object>>;
      expect(success.fidelity, DocumentFidelity.lossy);
      expect(
        success.diagnostics.map((diagnostic) => diagnostic.code),
        contains('jflap.explicit-epsilon-alias-interpreted'),
      );
      final transition =
          (success.value.document as FSA).transitions.single as FSATransition;
      expect(transition.isEpsilonTransition, isTrue);
    });

    test('FSA reports non-default editor fields as lossy on export', () {
      final outcome = const FsaJflapDocumentCodec().encode(
        _fsaDocument(
          stateProperties: const {'color': 'blue'},
          controlPoint: Vector2(20, 30),
          transitionLabel: 'display only',
        ),
      );

      final success = outcome as CodecSuccess<EncodedDocument>;
      expect(success.fidelity, DocumentFidelity.lossy);
      expect(
        success.diagnostics.map((diagnostic) => diagnostic.code),
        containsAll({
          'jflap.state-properties-dropped',
          'jflap.transition-control-point-dropped',
          'jflap.transition-display-label-dropped',
        }),
      );
    });

    test('grammar preserves explicit metadata and nested optional data', () {
      const codec = GrammarJflapDocumentCodec();
      final decoded = codec.decode(_payload(_grammarXmlWithExtensions));

      final success = decoded as CodecSuccess<InteroperableDocument<Object>>;
      final grammar = success.value.document as Grammar;
      expect(grammar.startSymbol, 'S');
      expect(grammar.type, GrammarType.contextFree);
      expect(success.value.extensions.values, contains('grammarAttributes'));
      expect(
        success.value.extensions.values,
        contains('productionChildren.p0'),
      );

      final encoded = codec.encode(success.value);
      final xml = utf8.decode(
        (encoded as CodecSuccess<EncodedDocument>).value.bytes,
      );
      expect(xml, contains('vendor="grammar"'));
      expect(xml, contains('<annotation>production</annotation>'));
      expect(xml, contains('<metadata>root</metadata>'));
    });

    test('grammar reports multi-character token boundaries as lossy', () {
      final outcome = const GrammarJflapDocumentCodec().encode(
        _grammarDocument(
          rightSide: const ['identifier'],
          terminals: const {'identifier'},
        ),
      );

      final success = outcome as CodecSuccess<EncodedDocument>;
      expect(success.fidelity, DocumentFidelity.lossy);
      expect(
        success.diagnostics.map((diagnostic) => diagnostic.code),
        contains('jflap.grammar-token-boundaries-lossy'),
      );
    });

    test('unknown grammar type is preserved but interpretation is lossy', () {
      final source = _grammarXmlWithExtensions.replaceFirst(
        'type="contextFree"',
        'type="vendorGrammar"',
      );
      const codec = GrammarJflapDocumentCodec();
      final decoded = codec.decode(_payload(source));

      final success = decoded as CodecSuccess<InteroperableDocument<Object>>;
      expect(success.fidelity, DocumentFidelity.lossy);
      expect(success.value.extensions.values['grammarType'], 'vendorGrammar');
      expect(
        success.diagnostics.map((diagnostic) => diagnostic.code),
        contains('jflap.unknown-grammar-type-preserved'),
      );
      final reencoded = codec.encode(success.value);
      expect(
        utf8.decode((reencoded as CodecSuccess<EncodedDocument>).value.bytes),
        contains('type="vendorGrammar"'),
      );
    });
  });

  group('versioned JSON codecs', () {
    test('canonical envelope round-trips typed annotations', () {
      final base = _fsaDocument();
      final fsa = base.document as FSA;
      final annotations = DocumentAnnotationCollection(
        documentId: fsa.id,
        documentRevision: '1',
        annotations: [
          DocumentAnnotation(
            id: 'note-1',
            documentId: fsa.id,
            documentRevision: '1',
            text: 'JSON note',
            x: 10,
            y: 20,
            createdAt: DateTime.utc(2026),
            updatedAt: DateTime.utc(2026),
          ),
        ],
      );
      final document = InteroperableDocument<Object>(
        document: fsa,
        systemKey: base.systemKey,
        schema: base.schema,
        extensions: extensionsWithAnnotations(base.extensions, annotations),
      );
      final registry = DefaultDocumentInteroperabilityRegistry.create();

      final encoded = registry.encode(
        document,
        format: DefaultFormalSystemIds.turingLabJsonFormat,
      ) as CodecSuccess<EncodedDocument>;
      final decoded = registry.decode(
        DocumentPayload(bytes: encoded.value.bytes, filename: 'fsa.json'),
        expectedSystem: DefaultFormalSystemIds.fsa,
        expectedFormat: DefaultFormalSystemIds.turingLabJsonFormat,
      ) as CodecSuccess<InteroperableDocument<Object>>;

      expect(annotationsFromExtensions(decoded.value.extensions), annotations);
    });

    test('constrained malformed payload returns malformed, not unsupported',
        () {
      final outcome = DefaultDocumentInteroperabilityRegistry.create().decode(
        _payload('{"format":"turing-lab.document","document":'),
        expectedSystem: DefaultFormalSystemIds.fsa,
        expectedFormat: DefaultFormalSystemIds.turingLabJsonFormat,
      );

      expect(outcome, isA<CodecMalformed<InteroperableDocument<Object>>>());
    });

    test('executes a typed contiguous schema migration', () {
      final codec = VersionedJsonDocumentCodec(
        systemKey: DefaultFormalSystemIds.fsa,
        schema: const DocumentSchemaDescriptor(
          id: DocumentSchemaId('turing-lab.fsa'),
          version: DocumentSchemaVersion(2),
        ),
        codecId: const DocumentCodecId('test.migrating-json'),
        namespace: const CapabilityNamespaceId('codec.test.migrating-json'),
        fixture: 'test/fixtures/interoperability/fsa_canonical.json',
        encodePayload: (document) => document as Map<String, Object?>,
        decodePayload: (payload) => payload,
        isLegacyPayload: (_) => false,
        knownPayloadFields: const {'renamed'},
        migrations: [
          CallbackDocumentMigrationStep(
            fromVersion: const DocumentSchemaVersion(1),
            toVersion: const DocumentSchemaVersion(2),
            migrate: (payload) => {
              'renamed': payload['old'],
            },
          ),
        ],
      );
      final envelope = jsonDecode(_jsonEnvelope()) as Map<String, dynamic>;
      final document = envelope['document'] as Map<String, dynamic>;
      document['schema'] = {'id': 'turing-lab.fsa', 'version': 1};
      document['payload'] = {'old': 'value'};

      final outcome = codec.decode(_payload(jsonEncode(envelope)));

      final success = outcome as CodecSuccess<InteroperableDocument<Object>>;
      expect(success.fidelity, DocumentFidelity.normalized);
      expect(success.value.document, {'renamed': 'value'});
      expect(
        success.diagnostics.map((diagnostic) => diagnostic.code),
        contains('json.document-schema-migrated'),
      );

      final oldExport = codec.encode(
        InteroperableDocument<Object>(
          document: const <String, Object?>{'old': 'value'},
          systemKey: DefaultFormalSystemIds.fsa,
          schema: const DocumentSchemaDescriptor(
            id: DocumentSchemaId('turing-lab.fsa'),
            version: DocumentSchemaVersion(1),
          ),
        ),
      );
      expect(oldExport, isA<CodecUnsupported<EncodedDocument>>());
    });

    test('migration validation failures are malformed, not internal', () {
      final codec = VersionedJsonDocumentCodec(
        systemKey: DefaultFormalSystemIds.fsa,
        schema: const DocumentSchemaDescriptor(
          id: DocumentSchemaId('turing-lab.fsa'),
          version: DocumentSchemaVersion(2),
        ),
        codecId: const DocumentCodecId('test.failing-migration-json'),
        namespace:
            const CapabilityNamespaceId('codec.test.failing-migration-json'),
        fixture: 'test/fixtures/interoperability/fsa_canonical.json',
        encodePayload: (document) => document as Map<String, Object?>,
        decodePayload: (payload) => payload,
        isLegacyPayload: (_) => false,
        knownPayloadFields: const {'renamed'},
        migrations: [
          CallbackDocumentMigrationStep(
            fromVersion: const DocumentSchemaVersion(1),
            toVersion: const DocumentSchemaVersion(2),
            migrate: (_) => throw const FormatException('missing old field'),
          ),
        ],
      );
      final envelope = jsonDecode(_jsonEnvelope()) as Map<String, dynamic>;
      final document = envelope['document'] as Map<String, dynamic>;
      document['schema'] = {'id': 'turing-lab.fsa', 'version': 1};

      final outcome = codec.decode(_payload(jsonEncode(envelope)));

      expect(outcome, isA<CodecMalformed<InteroperableDocument<Object>>>());
      expect(
        (outcome as CodecMalformed<InteroperableDocument<Object>>)
            .location
            ?.path,
        r'$.document.payload',
      );
    });

    test('rejects a gapped migration graph at runtime', () {
      expect(
        () => VersionedJsonDocumentCodec(
          systemKey: DefaultFormalSystemIds.fsa,
          schema: const DocumentSchemaDescriptor(
            id: DocumentSchemaId('turing-lab.fsa'),
            version: DocumentSchemaVersion(4),
          ),
          codecId: const DocumentCodecId('test.gapped-json'),
          namespace: const CapabilityNamespaceId('codec.test.gapped-json'),
          fixture: 'test/fixtures/interoperability/fsa_canonical.json',
          encodePayload: (document) => const {},
          decodePayload: (payload) => payload,
          isLegacyPayload: (_) => false,
          knownPayloadFields: const {},
          migrations: [
            CallbackDocumentMigrationStep(
              fromVersion: const DocumentSchemaVersion(1),
              toVersion: const DocumentSchemaVersion(2),
              migrate: (payload) => payload,
            ),
            CallbackDocumentMigrationStep(
              fromVersion: const DocumentSchemaVersion(3),
              toVersion: const DocumentSchemaVersion(4),
              migrate: (payload) => payload,
            ),
          ],
        ),
        throwsArgumentError,
      );
    });

    test('enforces the recursive collection-entry limit', () {
      final registry = DefaultDocumentInteroperabilityRegistry.create();
      final envelope = jsonDecode(_jsonEnvelope()) as Map<String, dynamic>;
      final document = envelope['document'] as Map<String, dynamic>;
      final payload = document['payload'] as Map<String, dynamic>;
      payload['vendorList'] = List<int>.filled(100001, 0);

      final outcome = registry.decode(
        _payload(jsonEncode(envelope)),
        expectedSystem: DefaultFormalSystemIds.fsa,
      );

      expect(
        (outcome as CodecResourceLimit<InteroperableDocument<Object>>).limit,
        CodecResourceLimitKind.collectionEntries,
      );
    });

    test('migrates legacy v1 payload and rejects future envelopes', () {
      final registry = DefaultDocumentInteroperabilityRegistry.create();
      final legacy = registry.decode(
        _payload(jsonEncode((_fsaDocument().document as FSA).toJson())),
        expectedSystem: DefaultFormalSystemIds.fsa,
        expectedFormat: DefaultFormalSystemIds.turingLabJsonFormat,
      );
      expect(
        (legacy as CodecSuccess<InteroperableDocument<Object>>).fidelity,
        DocumentFidelity.normalized,
      );
      expect(
        legacy.diagnostics.map((diagnostic) => diagnostic.code),
        contains('json.legacy-envelope-migrated'),
      );

      final legacyJson = (_fsaDocument().document as FSA).toJson()
        ..['vendorLegacy'] = {'kept': true};
      final legacyWithUnknown = registry.decode(
        _payload(jsonEncode(legacyJson)),
        expectedSystem: DefaultFormalSystemIds.fsa,
        expectedFormat: DefaultFormalSystemIds.turingLabJsonFormat,
      ) as CodecSuccess<InteroperableDocument<Object>>;
      expect(
        legacyWithUnknown.value.extensions.values['json.payload.vendorLegacy'],
        {'kept': true},
      );

      final future = registry.decode(
        _payload(_jsonEnvelope(envelopeVersion: 2)),
        expectedSystem: DefaultFormalSystemIds.fsa,
        expectedFormat: DefaultFormalSystemIds.turingLabJsonFormat,
      );
      expect(future, isA<CodecUnsupported<InteroperableDocument<Object>>>());
      expect(
        (future as CodecUnsupported<InteroperableDocument<Object>>).reason,
        CodecUnsupportedReason.schema,
      );
    });

    test('invalid source and extension types are malformed with paths', () {
      final registry = DefaultDocumentInteroperabilityRegistry.create();
      final invalidSource = registry.decode(
        _payload(_jsonEnvelope(source: 42)),
        expectedSystem: DefaultFormalSystemIds.fsa,
      );
      expect(
          invalidSource, isA<CodecMalformed<InteroperableDocument<Object>>>());
      expect(
        (invalidSource as CodecMalformed<InteroperableDocument<Object>>)
            .location
            ?.path,
        r'$.source',
      );

      final invalidExtensions = registry.decode(
        _payload(_jsonEnvelope(extensions: [])),
        expectedSystem: DefaultFormalSystemIds.fsa,
      );
      expect(
        (invalidExtensions as CodecMalformed<InteroperableDocument<Object>>)
            .location
            ?.path,
        r'$.extensions',
      );

      final invalidExtensionExport = registry.encode(
        _fsaDocument(
          extensions: DocumentExtensionBag({
            'vendor': {1: 'non-string key'},
          }),
        ),
        format: DefaultFormalSystemIds.turingLabJsonFormat,
      );
      expect(
        invalidExtensionExport,
        isA<CodecMalformed<EncodedDocument>>(),
      );
      expect(
        (invalidExtensionExport as CodecMalformed<EncodedDocument>)
            .location
            ?.path,
        r'$.extensions',
      );
    });

    test('preserves and reports unknown envelope, document and payload data',
        () {
      final registry = DefaultDocumentInteroperabilityRegistry.create();
      final envelope = jsonDecode(_jsonEnvelope()) as Map<String, dynamic>;
      envelope['vendorEnvelope'] = {'a': 1};
      final document = envelope['document'] as Map<String, dynamic>;
      document['vendorDocument'] = true;
      final schema = document['schema'] as Map<String, dynamic>;
      schema['vendorSchema'] = 'kept';
      final payload = document['payload'] as Map<String, dynamic>;
      payload['vendorPayload'] = 'kept';
      final source = envelope['source'] as Map<String, dynamic>;
      source['vendorSource'] = 2;

      final outcome = registry.decode(
        _payload(jsonEncode(envelope)),
        expectedSystem: DefaultFormalSystemIds.fsa,
      );

      final success = outcome as CodecSuccess<InteroperableDocument<Object>>;
      expect(success.fidelity, DocumentFidelity.normalized);
      expect(
        success.value.extensions.values['json.payload.vendorPayload'],
        'kept',
      );
      expect(
        success.value.extensions.values['json.schema.vendorSchema'],
        'kept',
      );
      expect(success.value.extensions.values['json.source.vendorSource'], 2);
      expect(
        success.diagnostics
            .where((diagnostic) =>
                diagnostic.code == 'json.unknown-field-preserved')
            .length,
        5,
      );
    });

    test('built-in registry composition is idempotent', () {
      final once = DefaultDocumentInteroperabilityRegistry.withBuiltInCodecs(
        FormalSystemRegistry.defaultRegistry,
      );
      final twice = DefaultDocumentInteroperabilityRegistry.withBuiltInCodecs(
        once,
      );

      for (final module in once.modules) {
        final recomposed = twice.moduleFor(module.descriptor.key)!;
        expect(recomposed, same(module));
        expect(
          recomposed.codecs.map((codec) => codec.descriptor.codecId).toSet(),
          hasLength(recomposed.codecs.length),
        );
      }
    });

    test('canonical FSA JSON is independent of Set insertion order', () {
      final registry = DefaultDocumentInteroperabilityRegistry.create();
      final expected = _encodeJson(registry, _fsaDocument(symbols: {'a', 'b'}));

      for (var seed = 0; seed < 12; seed++) {
        final symbols = ['a', 'b']..shuffle(math.Random(seed));
        final actual = _encodeJson(
          registry,
          _fsaDocument(symbols: symbols.toSet()),
        );
        expect(actual, expected, reason: 'seed $seed');
      }
    });

    test('canonical Grammar JSON is independent of Set insertion order', () {
      final registry = DefaultDocumentInteroperabilityRegistry.create();
      final first = _grammarDocument(
        terminals: {'b', 'a'},
        productions: {
          _production('p1', ['S'], ['b'], 1),
          _production('p0', ['S'], ['a'], 0),
        },
      );
      final second = _grammarDocument(
        terminals: {'a', 'b'},
        productions: {
          _production('p0', ['S'], ['a'], 0),
          _production('p1', ['S'], ['b'], 1),
        },
      );

      expect(_encodeJson(registry, first), _encodeJson(registry, second));
    });

    test('native path and web byte payloads have identical semantics', () {
      final registry = DefaultDocumentInteroperabilityRegistry.create();
      final native = registry.decode(
        _payload(_fsaXml,
            filename: 'machine.jff', sourcePath: r'C:\machine.jff'),
      );
      final web = registry.decode(
        _payload(_fsaXml, filename: 'renamed.bin'),
      );

      final nativeFsa = (native as CodecSuccess<InteroperableDocument<Object>>)
          .value
          .document as FSA;
      final webFsa = (web as CodecSuccess<InteroperableDocument<Object>>)
          .value
          .document as FSA;
      expect(web.fidelity, native.fidelity);
      expect(webFsa.toJson(), nativeFsa.toJson());
    });

    test('all declared canonical fixtures round-trip deterministically', () {
      final registry = DefaultDocumentInteroperabilityRegistry.create();
      for (final descriptor in registry.descriptors) {
        for (final path in descriptor.canonicalFixtures) {
          final bytes = File(path).readAsBytesSync();
          final decoded = registry.decode(
            DocumentPayload(bytes: bytes, filename: path),
            expectedSystem: descriptor.systemKey,
            expectedFormat: descriptor.formatId,
          );
          expect(decoded, isA<CodecSuccess<InteroperableDocument<Object>>>(),
              reason: path);
          final first = registry.encode(
            (decoded as CodecSuccess<InteroperableDocument<Object>>).value,
            format: descriptor.formatId,
          ) as CodecSuccess<EncodedDocument>;
          final reparsed = registry.decode(
            DocumentPayload(bytes: first.value.bytes),
            expectedSystem: descriptor.systemKey,
            expectedFormat: descriptor.formatId,
          ) as CodecSuccess<InteroperableDocument<Object>>;
          final second = registry.encode(
            reparsed.value,
            format: descriptor.formatId,
          ) as CodecSuccess<EncodedDocument>;
          expect(second.value.bytes, first.value.bytes, reason: path);
        }
      }
    });
  });
}

String _encodeJson(
  DocumentInteroperabilityRegistry registry,
  InteroperableDocument<Object> document,
) {
  final outcome = registry.encode(
    document,
    format: DefaultFormalSystemIds.turingLabJsonFormat,
  );
  return utf8.decode((outcome as CodecSuccess<EncodedDocument>).value.bytes);
}

DocumentPayload _payload(
  String source, {
  String? filename,
  String? sourcePath,
}) =>
    DocumentPayload(
      bytes: Uint8List.fromList(utf8.encode(source)),
      filename: filename,
      sourcePath: sourcePath,
    );

InteroperableDocument<Object> _fsaDocument({
  Set<String> symbols = const {'a'},
  DocumentExtensionBag? extensions,
  Map<String, dynamic> stateProperties = const {},
  Vector2? controlPoint,
  String? transitionLabel,
}) {
  final q0 = State(
    id: 'q0',
    label: 'q0',
    position: Vector2.zero(),
    isInitial: true,
  );
  final q1 = State(
    id: 'q1',
    label: 'q1',
    position: Vector2(100, 0),
    isAccepting: true,
    properties: stateProperties,
  );
  final transition = FSATransition(
    id: 't0',
    fromState: q0,
    toState: q1,
    inputSymbols: symbols,
    controlPoint: controlPoint,
    label: transitionLabel,
  );
  final epoch = DateTime.fromMillisecondsSinceEpoch(0, isUtc: true);
  return InteroperableDocument<Object>(
    document: FSA(
      id: 'fsa',
      name: 'FSA',
      states: {q1, q0},
      transitions: {transition},
      alphabet: symbols,
      initialState: q0,
      acceptingStates: {q1},
      created: epoch,
      modified: epoch,
      bounds: const math.Rectangle<double>(0, 0, 100, 100),
    ),
    systemKey: DefaultFormalSystemIds.fsa,
    schema: const DocumentSchemaDescriptor(
      id: DocumentSchemaId('turing-lab.fsa'),
      version: DocumentSchemaVersion(1),
    ),
    extensions: extensions,
  );
}

InteroperableDocument<Object> _grammarDocument({
  List<String> rightSide = const ['a'],
  Set<String> terminals = const {'a'},
  Set<Production>? productions,
}) {
  final epoch = DateTime.fromMillisecondsSinceEpoch(0, isUtc: true);
  return InteroperableDocument<Object>(
    document: Grammar(
      id: 'grammar',
      name: 'Grammar',
      terminals: terminals,
      nonterminals: const {'S'},
      startSymbol: 'S',
      productions: productions ??
          {
            _production('p0', ['S'], rightSide, 0)
          },
      type: GrammarType.contextFree,
      created: epoch,
      modified: epoch,
    ),
    systemKey: DefaultFormalSystemIds.grammar,
    schema: const DocumentSchemaDescriptor(
      id: DocumentSchemaId('turing-lab.grammar'),
      version: DocumentSchemaVersion(1),
    ),
  );
}

Production _production(
  String id,
  List<String> left,
  List<String> right,
  int order,
) =>
    Production(
      id: id,
      leftSide: left,
      rightSide: right,
      isLambda: right.isEmpty,
      order: order,
    );

String _jsonEnvelope({
  int envelopeVersion = 1,
  Object? source = const {'application': 'fixture'},
  Object? extensions = const <String, Object?>{},
}) {
  final payload = (_fsaDocument().document as FSA).toJson();
  return jsonEncode({
    'format': 'turing-lab.document',
    'envelopeVersion': envelopeVersion,
    'document': {
      'type': 'fsa',
      'variant': 'standard',
      'schema': {'id': 'turing-lab.fsa', 'version': 1},
      'payload': payload,
    },
    'source': source,
    'extensions': extensions,
  });
}

const _fsaXml = '''
<structure type="fa">
  <type>fa</type>
  <automaton>
    <state id="q0" name="q0"><x>0</x><y>0</y><initial/></state>
    <state id="q1" name="q1"><x>100</x><y>0</y><final/></state>
    <transition><from>q0</from><to>q1</to><read>a</read></transition>
  </automaton>
</structure>
''';

const _fsaXmlWithExtensions = '''
<structure type="fa" vendor="root">
  <type>fa</type>
  <automaton vendor="automaton">
    <state id="q0" name="q0" color="blue">
      <x>0</x><y>0</y><initial/><note>state note</note>
    </state>
    <state id="q1" name="q1"><x>100</x><y>0</y><final/></state>
    <transition id="t0" vendor="transition">
      <from>q0</from><to>q1</to><read>a</read><custom keep="yes"/>
    </transition>
  </automaton>
</structure>
''';

const _grammarXml = '''
<structure type="grammar">
  <type>grammar</type>
  <production><left>S</left><right>a</right></production>
</structure>
''';

const _grammarXmlWithExtensions = '''
<structure type="grammar" vendor="root">
  <type>grammar</type>
  <metadata>root</metadata>
  <grammar type="contextFree" vendor="grammar">
    <start>S</start>
    <production vendor="production">
      <left>S</left><right>a</right><annotation>production</annotation>
    </production>
  </grammar>
</structure>
''';
