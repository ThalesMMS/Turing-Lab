part of '../file_operations_panel_test.dart';

void _runInteroperabilityFileOperationTests(
  _FakeFilePicker Function() fakeFilePicker,
) {
  final registry = DefaultDocumentInteroperabilityRegistry.create();

  DocumentInteroperabilityBinding binding({
    required FSA current,
    required Future<void> Function(InteroperableDocument<Object>) replace,
  }) {
    return DocumentInteroperabilityBinding(
      registry: registry,
      systemKey: DefaultFormalSystemIds.fsa,
      currentDocument: InteroperableDocument<Object>(
        document: current,
        systemKey: DefaultFormalSystemIds.fsa,
        schema: registry.formalSystems
            .descriptorFor(DefaultFormalSystemIds.fsa)!
            .schema,
      ),
      captureCheckpoint: () => current,
      restoreCheckpoint: (_) {},
      replace: replace,
      systemLabel: (_, key) => key.value,
      formatLabel: (_, format) => format.value,
    );
  }

  Future<void> pumpPanel(
    WidgetTester tester, {
    required DocumentInteroperabilityBinding binding,
    FileOperationsService? service,
    TextScaler textScaler = TextScaler.noScaling,
  }) {
    return tester.pumpWidget(
      MaterialApp(
        builder: (context, child) => MediaQuery(
          data: MediaQuery.of(context).copyWith(textScaler: textScaler),
          child: child!,
        ),
        home: Scaffold(
          body: SingleChildScrollView(
            child: FileOperationsPanel(
              automaton: binding.currentDocument?.document as FSA?,
              interoperability: binding,
              fileService: service,
            ),
          ),
        ),
      ),
    );
  }

  group('FileOperationsPanel interoperability', () {
    testWidgets('previews detected metadata before transactional replacement', (
      tester,
    ) async {
      InteroperableDocument<Object>? replacement;
      final picker = fakeFilePicker();
      picker.enqueuePickResult(
        FilePickerResult([
          PlatformFile(
            name: 'wrong-extension.txt',
            size: _jflapWithUnknownElement.length,
            bytes: Uint8List.fromList(utf8.encode(_jflapWithUnknownElement)),
          ),
        ]),
      );
      await pumpPanel(
        tester,
        binding: binding(
          current: _buildSampleAutomaton(),
          replace: (document) async => replacement = document,
        ),
      );

      await tester.tap(
        find.byKey(
          const ValueKey<String>('interoperability_import_document'),
        ),
      );
      await tester.pumpAndSettle();

      expect(replacement, isNull);
      expect(picker.lastPickType, FileType.any);
      expect(picker.lastPickAllowedExtensions, isNull);
      expect(find.byType(DocumentInteroperabilityReviewDialog), findsOneWidget);
      expect(find.text('wrong-extension.txt'), findsOneWidget);
      expect(find.text('jflap-xml'), findsOneWidget);
      expect(find.text('Normalized'), findsOneWidget);

      await tester.tap(find.text('Replace document'));
      await tester.pumpAndSettle();

      expect(replacement, isNotNull);
      expect(replacement!.document, isA<FSA>());
      expect(replacement!.extensions.isEmpty, isFalse);
      expect(find.text('Document imported successfully.'), findsOneWidget);
    });

    testWidgets('malformed import never invokes replacement', (tester) async {
      var replacementCount = 0;
      final picker = fakeFilePicker();
      picker.enqueuePickResult(
        FilePickerResult([
          PlatformFile(
            name: 'broken.jff',
            size: 8,
            bytes: Uint8List.fromList(utf8.encode('<broken>')),
          ),
        ]),
      );
      await pumpPanel(
        tester,
        binding: binding(
          current: _buildSampleAutomaton(),
          replace: (_) async => replacementCount++,
        ),
      );

      await tester.tap(
        find.byKey(
          const ValueKey<String>('interoperability_import_document'),
        ),
      );
      await tester.pumpAndSettle();

      expect(replacementCount, 0);
      expect(find.text('Document cannot be read'), findsOneWidget);
    });

    testWidgets('failed replacement restores the captured editor checkpoint', (
      tester,
    ) async {
      final original = _buildSampleAutomaton();
      FSA activeDocument = original;
      var restoreCount = 0;
      final picker = fakeFilePicker();
      picker.enqueuePickResult(
        FilePickerResult([
          PlatformFile(
            name: 'replacement.jff',
            size: _jflapWithUnknownElement.length,
            bytes: Uint8List.fromList(utf8.encode(_jflapWithUnknownElement)),
          ),
        ]),
      );
      await pumpPanel(
        tester,
        binding: DocumentInteroperabilityBinding(
          registry: registry,
          systemKey: DefaultFormalSystemIds.fsa,
          currentDocument: InteroperableDocument<Object>(
            document: original,
            systemKey: DefaultFormalSystemIds.fsa,
            schema: registry.formalSystems
                .descriptorFor(DefaultFormalSystemIds.fsa)!
                .schema,
          ),
          captureCheckpoint: () => activeDocument,
          restoreCheckpoint: (checkpoint) {
            activeDocument = checkpoint! as FSA;
            restoreCount++;
          },
          replace: (document) async {
            activeDocument = document.document as FSA;
            throw StateError('Simulated host failure after mutation');
          },
          systemLabel: (_, key) => key.value,
          formatLabel: (_, format) => format.value,
        ),
      );

      await tester.tap(
        find.byKey(
          const ValueKey<String>('interoperability_import_document'),
        ),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.text('Replace document'));
      await tester.pumpAndSettle();

      expect(activeDocument, same(original));
      expect(restoreCount, 1);
      expect(
        find.text('The document operation could not be completed.'),
        findsOneWidget,
      );
    });

    testWidgets(
      'native path fallback decodes the same payload transactionally',
      (tester) async {
        InteroperableDocument<Object>? replacement;
        final bytes = Uint8List.fromList(utf8.encode(_jflapWithUnknownElement));
        final service = _StubFileOperationsService(
          readBytesResponses: Queue.of([Success<Uint8List>(bytes)]),
        );
        final picker = fakeFilePicker();
        picker.enqueuePickResult(
          FilePickerResult([
            PlatformFile(
              name: 'path-only.jff',
              path: r'C:\fixtures\path-only.jff',
              size: bytes.length,
            ),
          ]),
        );
        await pumpPanel(
          tester,
          service: service,
          binding: binding(
            current: _buildSampleAutomaton(),
            replace: (document) async => replacement = document,
          ),
        );

        await tester.tap(
          find.byKey(
            const ValueKey<String>('interoperability_import_document'),
          ),
        );
        await tester.pumpAndSettle();
        expect(service.readBytesCallCount, 1);
        expect(replacement, isNull);

        await tester.tap(find.text('Replace document'));
        await tester.pumpAndSettle();
        expect(replacement?.document, isA<FSA>());
        expect((replacement!.document as FSA).states, hasLength(1));
        expect(replacement!.extensions.isEmpty, isFalse);
      },
      variant: const TargetPlatformVariant(<TargetPlatform>{
        TargetPlatform.macOS,
      }),
      skip: kIsWeb,
    );

    testWidgets(
      'native export writes codec bytes through the generic gateway after review',
      (tester) async {
        final service = _StubFileOperationsService(
          writeBytesResponses: Queue.of([
            const Success<String>(r'C:\exports\automaton.jff'),
          ]),
        );
        final picker = fakeFilePicker();
        picker.enqueueSaveResult(r'C:\exports\automaton.jff');
        await pumpPanel(
          tester,
          service: service,
          binding: binding(
            current: _buildSampleAutomaton(),
            replace: (_) async {},
          ),
        );

        await tester.tap(
          find.byKey(
            const ValueKey<String>('interoperability_export_jflap-xml'),
          ),
        );
        await tester.pumpAndSettle();
        expect(service.writeBytesCallCount, 0);
        expect(
            find.byType(DocumentInteroperabilityReviewDialog), findsOneWidget);

        await tester.tap(find.text('Export file'));
        await tester.pumpAndSettle();
        expect(service.writeBytesCallCount, 1);
        expect(service.lastWrittenBytes, isNotEmpty);
        expect(service.lastWrittenMimeType, 'application/xml');
        expect(find.text('Document exported successfully.'), findsOneWidget);
      },
      variant: const TargetPlatformVariant(<TargetPlatform>{
        TargetPlatform.macOS,
      }),
      skip: kIsWeb,
    );

    testWidgets('lossy import stays nonmutating until explicit confirmation', (
      tester,
    ) async {
      final current = _buildSampleAutomaton();
      final lossyRegistry = _lossyRegistry(current);
      InteroperableDocument<Object>? replacement;
      final picker = fakeFilePicker();
      picker.enqueuePickResult(
        FilePickerResult([
          PlatformFile(
            name: 'lossy.jff',
            size: 3,
            bytes: Uint8List.fromList(const [1, 2, 3]),
          ),
        ]),
      );
      final lossyBinding = DocumentInteroperabilityBinding(
        registry: lossyRegistry,
        systemKey: DefaultFormalSystemIds.fsa,
        currentDocument: InteroperableDocument<Object>(
          document: current,
          systemKey: DefaultFormalSystemIds.fsa,
          schema: lossyRegistry.formalSystems
              .descriptorFor(DefaultFormalSystemIds.fsa)!
              .schema,
        ),
        captureCheckpoint: () => current,
        restoreCheckpoint: (_) {},
        replace: (document) async => replacement = document,
        systemLabel: (_, key) => key.value,
        formatLabel: (_, format) => format.value,
      );
      await pumpPanel(tester, binding: lossyBinding);

      await tester.tap(
        find.byKey(
          const ValueKey<String>('interoperability_import_document'),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('Import with data loss'), findsOneWidget);
      expect(replacement, isNull);

      await tester.tap(find.text('Import with data loss'));
      await tester.pumpAndSettle();
      expect(replacement?.document, same(current));
    });

    testWidgets(
      'lossy export does not write until the explicit loss action',
      (tester) async {
        final current = _buildSampleAutomaton();
        final lossyRegistry = _lossyRegistry(current);
        final service = _StubFileOperationsService(
          writeBytesResponses: Queue.of([
            const Success<String>(r'C:\exports\lossy.jff'),
          ]),
        );
        final picker = fakeFilePicker();
        picker.enqueueSaveResult(r'C:\exports\lossy.jff');
        await pumpPanel(
          tester,
          service: service,
          binding: DocumentInteroperabilityBinding(
            registry: lossyRegistry,
            systemKey: DefaultFormalSystemIds.fsa,
            currentDocument: InteroperableDocument<Object>(
              document: current,
              systemKey: DefaultFormalSystemIds.fsa,
              schema: lossyRegistry.formalSystems
                  .descriptorFor(DefaultFormalSystemIds.fsa)!
                  .schema,
            ),
            captureCheckpoint: () => current,
            restoreCheckpoint: (_) {},
            replace: (_) async {},
            systemLabel: (_, key) => key.value,
            formatLabel: (_, format) => format.value,
          ),
        );

        await tester.tap(
          find.byKey(
            const ValueKey<String>('interoperability_export_jflap-xml'),
          ),
        );
        await tester.pumpAndSettle();
        expect(find.text('Export with data loss'), findsOneWidget);
        expect(service.writeBytesCallCount, 0);

        await tester.tap(find.text('Export with data loss'));
        await tester.pumpAndSettle();
        expect(service.writeBytesCallCount, 1);
      },
      variant: const TargetPlatformVariant(<TargetPlatform>{
        TargetPlatform.macOS,
      }),
      skip: kIsWeb,
    );

    testWidgets(
      'mobile export gives codec bytes to the picker only after review',
      (tester) async {
        final picker = fakeFilePicker();
        picker.enqueueSaveResult('/mobile/automaton.jff');
        await pumpPanel(
          tester,
          binding: binding(
            current: _buildSampleAutomaton(),
            replace: (_) async {},
          ),
        );

        await tester.tap(
          find.byKey(
            const ValueKey<String>('interoperability_export_jflap-xml'),
          ),
        );
        await tester.pumpAndSettle();
        expect(picker.lastSaveBytes, isNull);

        await tester.tap(find.text('Export file'));
        await tester.pumpAndSettle();
        expect(picker.lastSaveBytes, isNotEmpty);
      },
      variant: const TargetPlatformVariant(<TargetPlatform>{
        TargetPlatform.iOS,
      }),
      skip: kIsWeb,
    );

    testWidgets('web and native export use the same codec payload', (
      tester,
    ) async {
      final picker = fakeFilePicker();
      picker.enqueueSaveResult('automaton.jff');
      final service = _StubFileOperationsService(
        writeBytesResponses: Queue.of([
          const Success<String>('automaton.jff'),
        ]),
      );
      await pumpPanel(
        tester,
        service: service,
        binding: binding(
          current: _buildSampleAutomaton(),
          replace: (_) async {},
        ),
      );

      await tester.tap(
        find.byKey(
          const ValueKey<String>('interoperability_export_jflap-xml'),
        ),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.text('Export file'));
      await tester.pumpAndSettle();

      final bytes = picker.lastSaveBytes ?? service.lastWrittenBytes;
      expect(bytes, isNotEmpty);
      expect(utf8.decode(bytes!), contains('<structure'));
    });

    testWidgets('generic actions fit mobile, tablet, and desktop widths', (
      tester,
    ) async {
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      for (final size in const [
        Size(320, 700),
        Size(800, 1000),
        Size(1440, 900),
      ]) {
        tester.view.physicalSize = size;
        tester.view.devicePixelRatio = 1;
        await pumpPanel(
          tester,
          textScaler: size.width == 320
              ? const TextScaler.linear(2)
              : TextScaler.noScaling,
          binding: binding(
            current: _buildSampleAutomaton(),
            replace: (_) async {},
          ),
        );
        expect(
          find.byKey(
            const ValueKey<String>('interoperability_import_document'),
          ),
          findsOneWidget,
        );
        expect(tester.takeException(), isNull, reason: 'viewport $size');
      }
    });
  });
}

DocumentInteroperabilityRegistry _lossyRegistry(FSA decodedDocument) {
  final base = FormalSystemRegistry.defaultRegistry;
  final modules = base.modules.map((module) {
    if (module.descriptor.key != DefaultFormalSystemIds.fsa) return module;
    return _LossyCodecModule(
      base: module,
      codec: _LossyCodec(decodedDocument),
    );
  });
  return DocumentInteroperabilityRegistry.fromFormalSystems(
    FormalSystemRegistry(modules: modules, formats: base.formats.formats),
  );
}

final class _LossyCodecModule implements FormalSystemModule<Object> {
  const _LossyCodecModule({required this.base, required this.codec});

  final FormalSystemModule<Object> base;
  final DocumentCodecCapability<Object> codec;

  @override
  List<DocumentCodecCapability<Object>> get codecs => [codec];

  @override
  List<ConversionCapability<Object, Object>> get conversions =>
      base.conversions;

  @override
  FormalSystemDescriptor get descriptor => base.descriptor;

  @override
  ExampleCatalogCapability<Object>? get examples => base.examples;

  @override
  SessionCapability<Object>? get session => base.session;
}

final class _LossyCodec implements DocumentCodecCapability<Object> {
  _LossyCodec(this.decodedDocument);

  final FSA decodedDocument;

  @override
  CodecDescriptor get descriptor => CodecDescriptor(
        codecId: const DocumentCodecId('test.lossy'),
        namespace: const CapabilityNamespaceId('test.lossy'),
        systemKey: DefaultFormalSystemIds.fsa,
        formatId: DefaultFormalSystemIds.jflapXmlFormat,
        schemas: DocumentSchemaRange(minimum: 1, maximum: 1),
        directions: const {
          DocumentFormatDirection.importDocument,
          DocumentFormatDirection.exportDocument,
        },
        priority: 1000,
        compatibilityOwner: 'Widget test',
        canonicalFixtures: const ['test-only'],
        semanticCapabilities: {},
        knownUnsupportedFields: const {'external-output'},
      );

  @override
  CodecOutcome<InteroperableDocument<Object>> decode(DocumentPayload payload) {
    return CodecSuccess(
      value: InteroperableDocument<Object>(
        document: decodedDocument,
        systemKey: DefaultFormalSystemIds.fsa,
        schema: const DocumentSchemaDescriptor(
          id: DocumentSchemaId('turing-lab.fsa'),
          version: DocumentSchemaVersion(1),
        ),
      ),
      fidelity: DocumentFidelity.lossy,
      diagnostics: const [
        CodecDiagnostic(
          code: 'test.dropped',
          message: 'External output was dropped.',
          path: '/external-output',
          disposition: CodecDiagnosticDisposition.dropped,
        ),
      ],
    );
  }

  @override
  CodecOutcome<EncodedDocument> encode(
    InteroperableDocument<Object> document, {
    String? filename,
  }) {
    return CodecSuccess(
      value: EncodedDocument(
        bytes: Uint8List.fromList(const [1, 2, 3]),
        mimeType: 'application/xml',
        filename: filename ?? 'lossy.jff',
        schema: document.schema,
      ),
      fidelity: DocumentFidelity.lossy,
      diagnostics: const [
        CodecDiagnostic(
          code: 'test.dropped',
          message: 'External output was dropped.',
          path: '/external-output',
          disposition: CodecDiagnosticDisposition.dropped,
        ),
      ],
    );
  }

  @override
  CodecSniffResult sniff(DocumentPayload payload) => CodecSniffResult(
        confidence: 100,
        detectedSystem: DefaultFormalSystemIds.fsa,
        detectedSchemaVersion: 1,
      );
}

const _jflapWithUnknownElement = '''
<structure>
  <type>fa</type>
  <automaton>
    <state id="0" name="q0">
      <x>100</x>
      <y>100</y>
      <initial />
      <final />
      <future-metadata enabled="true" />
    </state>
  </automaton>
</structure>
''';
