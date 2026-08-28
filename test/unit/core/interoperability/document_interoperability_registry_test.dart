import 'dart:typed_data';
import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:turing_lab/core/formal_systems/formal_systems.dart';
import 'package:turing_lab/core/interoperability/interoperability.dart';
import 'package:turing_lab/core/messages/structured_message.dart';

void main() {
  group('DocumentInteroperabilityRegistry', () {
    test('rejects duplicate deterministic routing signatures', () {
      final first = _FakeCodec(
        codecId: 'test.one',
        namespace: 'codec.test.one',
      );
      final second = _FakeCodec(
        codecId: 'test.two',
        namespace: 'codec.test.two',
      );

      expect(
        () => DocumentInteroperabilityRegistry.fromFormalSystems(
          _registryWithFsaCodecs([first, second]),
        ),
        throwsArgumentError,
      );
    });

    test('reports equal-confidence sniffing as sorted ambiguity', () {
      final first = _FakeCodec(
        codecId: 'test.z',
        namespace: 'codec.test.z',
        priority: 101,
      );
      final second = _FakeCodec(
        codecId: 'test.a',
        namespace: 'codec.test.a',
        priority: 101,
        schemaMaximum: 2,
      );
      final registry = DocumentInteroperabilityRegistry.fromFormalSystems(
        _registryWithFsaCodecs([first, second]),
      );

      final outcome = registry.detect(_payload('{}'));

      expect(outcome, isA<CodecAmbiguous<DetectedDocument>>());
      expect(
        (outcome as CodecAmbiguous<DetectedDocument>).codecIds.map(
          (id) => id.value,
        ),
        ['test.a', 'test.z'],
      );
    });

    test('a throwing sniffer cannot block a later valid codec', () {
      final broken = _FakeCodec(
        codecId: 'test.broken-sniff',
        namespace: 'codec.test.broken-sniff',
        priority: 102,
        throwOnSniff: true,
      );
      final valid = _FakeCodec(
        codecId: 'test.valid-sniff',
        namespace: 'codec.test.valid-sniff',
        priority: 101,
        schemaMaximum: 2,
      );
      final registry = DocumentInteroperabilityRegistry.fromFormalSystems(
        _registryWithFsaCodecs([broken, valid]),
      );

      final outcome = registry.detect(_payload('{}'));

      expect(outcome, isA<CodecSuccess<DetectedDocument>>());
      expect(
        (outcome as CodecSuccess<DetectedDocument>)
            .value
            .descriptor
            .codecId
            .value,
        'test.valid-sniff',
      );
    });

    test('resource pre-scan fails closed before invoking a codec sniffer', () {
      final codec = _FakeCodec(
        codecId: 'test.prescan',
        namespace: 'codec.test.prescan',
        securityLimits: CodecSecurityLimits(
          maximumDepth: 2,
          maximumCollectionEntries: 2,
        ),
      );
      final registry = DocumentInteroperabilityRegistry.fromFormalSystems(
        _registryWithFsaCodecs([codec]),
      );

      final outcome = registry.detect(_payload('[[[0]]]'));

      expect(outcome, isA<CodecResourceLimit<DetectedDocument>>());
      expect(
        (outcome as CodecResourceLimit<DetectedDocument>).limit,
        CodecResourceLimitKind.jsonDepth,
      );
      expect(codec.sniffCalls, 0);

      final wideCodec = _FakeCodec(
        codecId: 'test.prescan-wide',
        namespace: 'codec.test.prescan-wide',
        securityLimits: CodecSecurityLimits(
          maximumDepth: 8,
          maximumCollectionEntries: 2,
        ),
      );
      final wideOutcome = DocumentInteroperabilityRegistry.fromFormalSystems(
        _registryWithFsaCodecs([wideCodec]),
      ).detect(_payload('[0,0,0]'));
      expect(
        (wideOutcome as CodecResourceLimit<DetectedDocument>).limit,
        CodecResourceLimitKind.collectionEntries,
      );
      expect(wideCodec.sniffCalls, 0);

      final xmlCodec = _FakeCodec(
        codecId: 'test.prescan-xml',
        namespace: 'codec.test.prescan-xml',
        formatId: DefaultFormalSystemIds.jflapXmlFormat,
      );
      final xmlOutcome = DocumentInteroperabilityRegistry.fromFormalSystems(
        _registryWithFsaCodecs([xmlCodec]),
      ).detect(_payload('<!DOCTYPE x><x/>'));
      expect(
        (xmlOutcome as CodecResourceLimit<DetectedDocument>).limit,
        CodecResourceLimitKind.xmlDtdOrEntity,
      );
      expect(xmlCodec.sniffCalls, 0);
    });

    test('rejects lying sniff identity with a typed internal failure', () {
      final codec = _FakeCodec(
        codecId: 'test.lying-sniff',
        namespace: 'codec.test.lying-sniff',
        sniffSystem: DefaultFormalSystemIds.grammar,
      );
      final registry = DocumentInteroperabilityRegistry.fromFormalSystems(
        _registryWithFsaCodecs([codec]),
      );

      final outcome = registry.detect(_payload('{}'));

      expect(outcome, isA<CodecInternalFailure<DetectedDocument>>());
      expect(
        (outcome as CodecInternalFailure<DetectedDocument>).stage,
        CodecInternalFailureStage.sniff,
      );
      expect(
        outcome.structuredMessage?.stableCode,
        'interop.registry.sniff-identity-mismatch',
      );
      expect(
        outcome.structuredMessage?.arguments['codec'],
        StructuredMessageArgument.identifier('test.lying-sniff', role: 'codec'),
      );
    });

    test('rejects lying sniff schema with a typed internal failure', () {
      final codec = _FakeCodec(
        codecId: 'test.lying-schema-sniff',
        namespace: 'codec.test.lying-schema-sniff',
        sniffSchemaVersion: 2,
      );
      final registry = DocumentInteroperabilityRegistry.fromFormalSystems(
        _registryWithFsaCodecs([codec]),
      );

      final outcome = registry.detect(_payload('{}'));

      expect(outcome, isA<CodecInternalFailure<DetectedDocument>>());
      expect(
        (outcome as CodecInternalFailure<DetectedDocument>).stage,
        CodecInternalFailureStage.sniff,
      );
    });

    test('rejects a codec that decodes to a different system identity', () {
      final codec = _FakeCodec(
        codecId: 'test.identity',
        namespace: 'codec.test.identity',
        decodeOutcome: CodecSuccess(
          value: InteroperableDocument<Object>(
            document: Object(),
            systemKey: DefaultFormalSystemIds.grammar,
            schema: const DocumentSchemaDescriptor(
              id: DocumentSchemaId('turing-lab.grammar'),
              version: DocumentSchemaVersion(1),
            ),
          ),
          fidelity: DocumentFidelity.exact,
        ),
      );
      final registry = DocumentInteroperabilityRegistry.fromFormalSystems(
        _registryWithFsaCodecs([codec]),
      );

      final outcome = registry.decode(_payload('{}'));

      expect(outcome, isA<CodecInternalFailure<Object>>());
      expect(
        (outcome as CodecInternalFailure<Object>).stage,
        CodecInternalFailureStage.decode,
      );
    });

    test('rejects a codec that returns an out-of-range schema', () {
      final codec = _FakeCodec(
        codecId: 'test.schema',
        namespace: 'codec.test.schema',
        schemaMaximum: 2,
        decodeOutcome: CodecSuccess(
          value: InteroperableDocument<Object>(
            document: Object(),
            systemKey: DefaultFormalSystemIds.fsa,
            schema: const DocumentSchemaDescriptor(
              id: DocumentSchemaId('turing-lab.fsa'),
              version: DocumentSchemaVersion(3),
            ),
          ),
          fidelity: DocumentFidelity.exact,
        ),
      );
      final registry = DocumentInteroperabilityRegistry.fromFormalSystems(
        _registryWithFsaCodecs([codec]),
      );

      final outcome = registry.decode(_payload('{}'));

      expect(outcome, isA<CodecInternalFailure<Object>>());
      expect(
        (outcome as CodecInternalFailure<Object>).stage,
        CodecInternalFailureStage.decode,
      );
    });

    test('rejects encoded metadata outside the authoritative format', () {
      final codec = _FakeCodec(
        codecId: 'test.output',
        namespace: 'codec.test.output',
        encodeOutcome: CodecSuccess(
          value: EncodedDocument(
            bytes: Uint8List.fromList([1]),
            mimeType: 'text/plain',
            filename: 'wrong.txt',
            schema: _fsaSchema,
          ),
          fidelity: DocumentFidelity.exact,
        ),
      );
      final registry = DocumentInteroperabilityRegistry.fromFormalSystems(
        _registryWithFsaCodecs([codec]),
      );

      final outcome = registry.encode(
        _fsaDocument(),
        format: DefaultFormalSystemIds.turingLabJsonFormat,
      );

      expect(outcome, isA<CodecInternalFailure<EncodedDocument>>());
      expect(
        (outcome as CodecInternalFailure<EncodedDocument>).stage,
        CodecInternalFailureStage.encode,
      );
    });

    test('rejects an encode document with a foreign schema id', () {
      final codec = _FakeCodec(
        codecId: 'test.foreign-schema',
        namespace: 'codec.test.foreign-schema',
      );
      final registry = DocumentInteroperabilityRegistry.fromFormalSystems(
        _registryWithFsaCodecs([codec]),
      );
      final document = InteroperableDocument<Object>(
        document: Object(),
        systemKey: DefaultFormalSystemIds.fsa,
        schema: const DocumentSchemaDescriptor(
          id: DocumentSchemaId('foreign.schema'),
          version: DocumentSchemaVersion(1),
        ),
      );

      final outcome = registry.encode(
        document,
        format: DefaultFormalSystemIds.turingLabJsonFormat,
      );

      expect(outcome, isA<CodecUnsupported<EncodedDocument>>());
      expect(
        (outcome as CodecUnsupported<EncodedDocument>).reason,
        CodecUnsupportedReason.schema,
      );
      expect(
        outcome.structuredMessage?.stableCode,
        'interop.registry.schema-identity-unregistered',
      );
      final persisted = outcome.structuredMessage!.toJson();
      expect(StructuredMessage.fromJson(persisted), outcome.structuredMessage);
    });

    test('reports schema when a route exists but version is unsupported', () {
      final codec = _FakeCodec(
        codecId: 'test.unsupported-version',
        namespace: 'codec.test.unsupported-version',
      );
      final registry = DocumentInteroperabilityRegistry.fromFormalSystems(
        _registryWithFsaCodecs([codec]),
      );
      final document = InteroperableDocument<Object>(
        document: Object(),
        systemKey: DefaultFormalSystemIds.fsa,
        schema: const DocumentSchemaDescriptor(
          id: DocumentSchemaId('turing-lab.fsa'),
          version: DocumentSchemaVersion(2),
        ),
      );

      final outcome = registry.encode(
        document,
        format: DefaultFormalSystemIds.turingLabJsonFormat,
      );

      expect(outcome, isA<CodecUnsupported<EncodedDocument>>());
      expect(
        (outcome as CodecUnsupported<EncodedDocument>).reason,
        CodecUnsupportedReason.schema,
      );
      expect(
        outcome.structuredMessage?.stableCode,
        'interop.registry.export-schema-unavailable',
      );
      expect(
        outcome.structuredMessage?.arguments['schema-version'],
        StructuredMessageArgument.integer(2, role: 'schema-version'),
      );
    });

    test('reports a typed export route when no codec owns the format', () {
      final codec = _FakeCodec(
        codecId: 'test.route',
        namespace: 'codec.test.route',
      );
      final registry = DocumentInteroperabilityRegistry.fromFormalSystems(
        _registryWithFsaCodecs([codec]),
      );

      final outcome = registry.encode(
        _fsaDocument(),
        format: const DocumentFormatId('missing-format'),
      );

      expect(outcome, isA<CodecUnsupported<EncodedDocument>>());
      final unsupported = outcome as CodecUnsupported<EncodedDocument>;
      expect(
        unsupported.structuredMessage?.stableCode,
        'interop.registry.export-route-unavailable',
      );
      expect(
        unsupported.structuredMessage?.arguments.keys,
        containsAll(['system', 'format', 'schema-version']),
      );
    });

    test('runtime value objects reject malformed plugin configuration', () {
      expect(
        () => DocumentSchemaRange(minimum: 0, maximum: 1),
        throwsArgumentError,
      );
      expect(
        () => CodecSecurityLimits(maximumCollectionEntries: 0),
        throwsArgumentError,
      );
      expect(() => CodecSniffResult(confidence: 101), throwsArgumentError);
      expect(
        () => _FakeCodec(codecId: '', namespace: 'codec.valid').descriptor,
        throwsArgumentError,
      );
      expect(
        () => _FakeCodec(
          codecId: 'valid',
          namespace: 'codec.valid',
          fixture: '   ',
        ).descriptor,
        throwsArgumentError,
      );
      expect(
        () => CodecSuccess(
          value: Object(),
          fidelity: DocumentFidelity.exact,
          diagnostics: const [
            CodecDiagnostic(
              code: 'normalized',
              message: 'normalized',
              disposition: CodecDiagnosticDisposition.normalized,
            ),
          ],
        ),
        throwsArgumentError,
      );
      expect(
        () => CodecSuccess(
          value: Object(),
          fidelity: DocumentFidelity.normalized,
          diagnostics: const [
            CodecDiagnostic(
              code: 'dropped',
              message: 'dropped',
              disposition: CodecDiagnosticDisposition.dropped,
            ),
          ],
        ),
        throwsArgumentError,
      );
    });

    test('payloads and extension sidecars are deeply immutable snapshots', () {
      final source = Uint8List.fromList([1, 2]);
      final nestedBytes = Uint8List.fromList([3, 4]);
      final nestedList = <Object?>[nestedBytes];
      final payload = DocumentPayload(bytes: source);
      final encoded = EncodedDocument(
        bytes: source,
        mimeType: 'application/json',
        filename: 'sample.json',
        schema: _fsaSchema,
      );
      final bag = DocumentExtensionBag({'nested': nestedList});

      source[0] = 9;
      nestedBytes[0] = 9;
      nestedList.add('late');
      expect(payload.bytes, [1, 2]);
      expect(encoded.bytes, [1, 2]);
      expect(() => payload.bytes[0] = 8, throwsUnsupportedError);
      expect(() => encoded.bytes[0] = 8, throwsUnsupportedError);
      final frozenList = bag.values['nested'] as List<Object?>;
      expect(frozenList, hasLength(1));
      expect(frozenList.single, [3, 4]);
      expect(() => frozenList.add('mutation'), throwsUnsupportedError);
      expect(
        () => (frozenList.single as Uint8List)[0] = 8,
        throwsUnsupportedError,
      );
    });
  });

  group('document transactions', () {
    test('failed import never mutates the current document', () async {
      var replacements = 0;
      final transaction = DocumentImportTransaction<Object, int>.prepare(
        outcome: const CodecMalformed(message: 'broken'),
        target: CallbackDocumentImportTarget(
          captureCheckpoint: () => 0,
          replace: (_) async => replacements++,
          restoreCheckpoint: (_) {},
        ),
      );

      await expectLater(transaction.commit(), throwsStateError);
      expect(replacements, 0);
    });

    test(
      'lossy import requires consent and preserves the full sidecar',
      () async {
        InteroperableDocument<Object>? replacement;
        final document = _fsaDocument(
          extensions: DocumentExtensionBag({'vendor': 'kept'}),
        );
        final transaction =
            DocumentImportTransaction<
              Object,
              InteroperableDocument<Object>?
            >.prepare(
              outcome: CodecSuccess(
                value: document,
                fidelity: DocumentFidelity.lossy,
              ),
              target: CallbackDocumentImportTarget(
                captureCheckpoint: () => replacement,
                replace: (value) async => replacement = value,
                restoreCheckpoint: (checkpoint) => replacement = checkpoint,
              ),
            );

        await expectLater(transaction.commit(), throwsStateError);
        expect(replacement, isNull);
        await transaction.commit(allowLossy: true);
        expect(replacement, same(document));
        expect(replacement!.extensions.values['vendor'], 'kept');
      },
    );

    test('lossy export writes once only after consent', () async {
      final transport = MemoryDocumentTransport();
      final transaction = DocumentExportTransaction.prepare(
        outcome: CodecSuccess(
          value: EncodedDocument(
            bytes: Uint8List.fromList([1, 2, 3]),
            mimeType: 'application/json',
            filename: 'sample.json',
            schema: _fsaSchema,
          ),
          fidelity: DocumentFidelity.lossy,
        ),
        transport: transport,
        location: 'sample.json',
      );

      await expectLater(transaction.commit(), throwsStateError);
      await expectLater(transport.read('sample.json'), throwsStateError);
      await transaction.commit(allowLossy: true);
      expect((await transport.read('sample.json')).bytes, [1, 2, 3]);
      await expectLater(transaction.commit(allowLossy: true), throwsStateError);
    });

    test('concurrent import commits cannot replace twice', () async {
      final entered = Completer<void>();
      final release = Completer<void>();
      var replacements = 0;
      final transaction = DocumentImportTransaction<Object, int>.prepare(
        outcome: CodecSuccess(
          value: _fsaDocument(),
          fidelity: DocumentFidelity.exact,
        ),
        target: CallbackDocumentImportTarget(
          captureCheckpoint: () => replacements,
          replace: (_) async {
            replacements++;
            entered.complete();
            await release.future;
          },
          restoreCheckpoint: (checkpoint) => replacements = checkpoint,
        ),
      );

      final first = transaction.commit();
      await entered.future;
      await expectLater(transaction.commit(), throwsStateError);
      release.complete();
      await first;
      expect(replacements, 1);
    });

    test(
      'failed partial replacement is restored and remains retryable',
      () async {
        var attempts = 0;
        var editorState = 'original';
        final transaction = DocumentImportTransaction<Object, String>.prepare(
          outcome: CodecSuccess(
            value: _fsaDocument(),
            fidelity: DocumentFidelity.exact,
          ),
          target: CallbackDocumentImportTarget(
            captureCheckpoint: () => editorState,
            replace: (_) async {
              attempts++;
              editorState = attempts == 1 ? 'partially-mutated' : 'replacement';
              if (attempts == 1) throw StateError('replace failed');
            },
            restoreCheckpoint: (checkpoint) => editorState = checkpoint,
          ),
        );

        await expectLater(transaction.commit(), throwsStateError);
        expect(editorState, 'original');
        await transaction.commit();
        expect(attempts, 2);
        expect(editorState, 'replacement');
      },
    );

    test('rollback failure is reported with both typed causes', () async {
      final replaceError = StateError('replace');
      final rollbackError = StateError('rollback');
      final transaction = DocumentImportTransaction<Object, String>.prepare(
        outcome: CodecSuccess(
          value: _fsaDocument(),
          fidelity: DocumentFidelity.exact,
        ),
        target: CallbackDocumentImportTarget(
          captureCheckpoint: () => 'original',
          replace: (_) async => throw replaceError,
          restoreCheckpoint: (_) => throw rollbackError,
        ),
      );

      try {
        await transaction.commit();
        fail('commit should fail');
      } on DocumentImportRollbackFailure catch (failure) {
        expect(failure.replaceError, same(replaceError));
        expect(failure.rollbackError, same(rollbackError));
      }
      await expectLater(transaction.commit(), throwsStateError);
    });

    test('concurrent export commits cannot write twice', () async {
      final entered = Completer<void>();
      final release = Completer<void>();
      var writes = 0;
      final transport = CallbackDocumentTransport(
        read: (_) async => _payload('{}'),
        write: (_, __, ___) async {
          writes++;
          entered.complete();
          await release.future;
        },
      );
      final transaction = DocumentExportTransaction.prepare(
        outcome: CodecSuccess(
          value: EncodedDocument(
            bytes: Uint8List.fromList([1]),
            mimeType: 'application/json',
            filename: 'sample.json',
            schema: _fsaSchema,
          ),
          fidelity: DocumentFidelity.exact,
        ),
        transport: transport,
        location: 'sample.json',
      );

      final first = transaction.commit();
      await entered.future;
      await expectLater(transaction.commit(), throwsStateError);
      release.complete();
      await first;
      expect(writes, 1);
    });
  });
}

const _fsaSchema = DocumentSchemaDescriptor(
  id: DocumentSchemaId('turing-lab.fsa'),
  version: DocumentSchemaVersion(1),
);

DocumentPayload _payload(String source) => DocumentPayload(
  bytes: Uint8List.fromList(source.codeUnits),
  filename: 'sample.json',
);

InteroperableDocument<Object> _fsaDocument({
  DocumentExtensionBag? extensions,
}) => InteroperableDocument<Object>(
  document: Object(),
  systemKey: DefaultFormalSystemIds.fsa,
  schema: const DocumentSchemaDescriptor(
    id: DocumentSchemaId('turing-lab.fsa'),
    version: DocumentSchemaVersion(1),
  ),
  extensions: extensions,
);

FormalSystemRegistry _registryWithFsaCodecs(
  List<DocumentCodecCapability<Object>> codecs,
) {
  final base = FormalSystemRegistry.defaultRegistry;
  return FormalSystemRegistry(
    modules: base.modules.map(
      (module) => module.descriptor.key == DefaultFormalSystemIds.fsa
          ? _TestModule(module.descriptor, codecs)
          : module,
    ),
    formats: base.formats.formats,
  );
}

final class _TestModule implements FormalSystemModule<Object> {
  const _TestModule(this.descriptor, this.codecs);

  @override
  final FormalSystemDescriptor descriptor;

  @override
  final List<DocumentCodecCapability<Object>> codecs;

  @override
  List<ConversionCapability<Object, Object>> get conversions => const [];

  @override
  ExampleCatalogCapability<Object>? get examples => null;

  @override
  SessionCapability<Object>? get session => null;
}

final class _FakeCodec implements DocumentCodecCapability<Object> {
  _FakeCodec({
    required String codecId,
    required String namespace,
    this.priority = 100,
    this.schemaMaximum = 1,
    this.fixture = 'test/fixtures/interoperability/fake.json',
    this.throwOnSniff = false,
    this.sniffSystem = DefaultFormalSystemIds.fsa,
    this.sniffSchemaVersion = 1,
    CodecSecurityLimits? securityLimits,
    this.formatId = DefaultFormalSystemIds.turingLabJsonFormat,
    CodecOutcome<InteroperableDocument<Object>>? decodeOutcome,
    CodecOutcome<EncodedDocument>? encodeOutcome,
  }) : _codecId = codecId,
       _namespace = namespace,
       securityLimits = securityLimits ?? CodecSecurityLimits(),
       decodeOutcome =
           decodeOutcome ??
           CodecSuccess(
             value: _fsaDocument(),
             fidelity: DocumentFidelity.exact,
           ),
       encodeOutcome =
           encodeOutcome ??
           CodecSuccess(
             value: EncodedDocument(
               bytes: Uint8List.fromList([123, 125]),
               mimeType: 'application/json',
               filename: 'sample.json',
               schema: _fsaSchema,
             ),
             fidelity: DocumentFidelity.exact,
           );

  final String _codecId;
  final String _namespace;
  final int priority;
  final int schemaMaximum;
  final String fixture;
  final bool throwOnSniff;
  final FormalSystemKey? sniffSystem;
  final int? sniffSchemaVersion;
  final CodecSecurityLimits securityLimits;
  final DocumentFormatId formatId;
  int sniffCalls = 0;
  final CodecOutcome<InteroperableDocument<Object>> decodeOutcome;
  final CodecOutcome<EncodedDocument> encodeOutcome;

  @override
  CodecDescriptor get descriptor => CodecDescriptor(
    codecId: DocumentCodecId(_codecId),
    namespace: CapabilityNamespaceId(_namespace),
    systemKey: DefaultFormalSystemIds.fsa,
    formatId: formatId,
    schemas: DocumentSchemaRange(minimum: 1, maximum: schemaMaximum),
    directions: const {
      DocumentFormatDirection.importDocument,
      DocumentFormatDirection.exportDocument,
    },
    priority: priority,
    compatibilityOwner: 'test',
    canonicalFixtures: [fixture],
    semanticCapabilities: const {},
    knownUnsupportedFields: const {},
    securityLimits: securityLimits,
  );

  @override
  CodecOutcome<InteroperableDocument<Object>> decode(DocumentPayload payload) =>
      decodeOutcome;

  @override
  CodecOutcome<EncodedDocument> encode(
    InteroperableDocument<Object> document, {
    String? filename,
  }) => encodeOutcome;

  @override
  CodecSniffResult sniff(DocumentPayload payload) {
    sniffCalls++;
    if (throwOnSniff) throw StateError('broken sniffer');
    return CodecSniffResult(
      confidence: 100,
      detectedSystem: sniffSystem,
      detectedSchemaVersion: sniffSchemaVersion,
    );
  }
}
