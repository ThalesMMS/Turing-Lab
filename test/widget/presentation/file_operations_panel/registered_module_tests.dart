part of '../file_operations_panel_test.dart';

void _runRegisteredModuleFileOperationTests(
  _FakeFilePicker Function() fakeFilePicker,
) {
  testWidgets('renders actions contributed by a test-only registered module', (
    tester,
  ) async {
    final semantics = tester.ensureSemantics();
    var exportCount = 0;
    final registry = FormalSystemRegistry(
      modules: const [_RegisteredSampleModule()],
      formats: [
        DocumentFormatDescriptor(
          id: DefaultFormalSystemIds.svgFormat,
          extensions: const {'svg'},
        ),
        DocumentFormatDescriptor(
          id: DefaultFormalSystemIds.turingLabJsonFormat,
          extensions: const {'json'},
        ),
      ],
    );

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: FileOperationsPanel(
            formalSystemRegistry: registry,
            registeredSystemKey: _registeredSampleKey,
            registeredSectionLabel: 'Sample module',
            registeredOperations: [
              RegisteredFileOperation(
                format: DefaultFormalSystemIds.svgFormat,
                direction: DocumentFormatDirection.exportDocument,
                label: 'Export sample',
                icon: Icons.extension,
                onPressed: () => exportCount++,
              ),
              RegisteredFileOperation(
                format: DefaultFormalSystemIds.turingLabJsonFormat,
                direction: DocumentFormatDirection.importDocument,
                label: 'Unsupported sample import',
                icon: Icons.upload_file,
                onPressed: () {},
              ),
            ],
          ),
        ),
      ),
    );

    expect(find.text('Sample module'), findsOneWidget);
    expect(find.text('Export sample'), findsOneWidget);
    expect(find.text('Unsupported sample import'), findsNothing);
    expect(
      tester
          .getSemantics(find.widgetWithText(ElevatedButton, 'Export sample'))
          .label,
      'Export sample',
    );

    await tester.tap(find.text('Export sample'));
    expect(exportCount, 1);
    semantics.dispose();
  });

  testWidgets('hides a registered section when every action is filtered', (
    tester,
  ) async {
    final registry = FormalSystemRegistry(
      modules: const [_RegisteredSampleModule()],
      formats: [
        DocumentFormatDescriptor(
          id: DefaultFormalSystemIds.svgFormat,
          extensions: const {'svg'},
        ),
        DocumentFormatDescriptor(
          id: DefaultFormalSystemIds.turingLabJsonFormat,
          extensions: const {'json'},
        ),
      ],
    );

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: FileOperationsPanel(
            formalSystemRegistry: registry,
            registeredSystemKey: _registeredSampleKey,
            registeredSectionLabel: 'Hidden sample module',
            registeredOperations: [
              RegisteredFileOperation(
                format: DefaultFormalSystemIds.turingLabJsonFormat,
                direction: DocumentFormatDirection.importDocument,
                label: 'Unsupported sample import',
                icon: Icons.upload_file,
                onPressed: () {},
              ),
            ],
          ),
        ),
      ),
    );

    expect(find.text('Hidden sample module'), findsNothing);
    expect(find.text('Unsupported sample import'), findsNothing);
  });

  testWidgets('visual export buttons are the registry-producer intersection', (
    tester,
  ) async {
    final registry = FormalSystemRegistry(
      modules: const [_RegisteredSampleModule()],
      formats: [
        DocumentFormatDescriptor(
          id: DefaultFormalSystemIds.svgFormat,
          extensions: const {'svg'},
        ),
        DocumentFormatDescriptor(
          id: DefaultFormalSystemIds.pngFormat,
          extensions: const {'png'},
        ),
      ],
    );

    Future<VisualExportArtifact> artifact({
      required bool includeAnnotations,
    }) async =>
        VisualExportArtifact(
          bytes: Uint8List.fromList([1]),
          mimeType: 'image/svg+xml',
          filename: 'sample.svg',
          width: 800,
          height: 600,
        );

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: FileOperationsPanel(
            formalSystemRegistry: registry,
            visualExport: VisualExportBinding(
              systemKey: _registeredSampleKey,
              producers: {
                DefaultFormalSystemIds.svgFormat: artifact,
                DefaultFormalSystemIds.pngFormat: artifact,
              },
            ),
          ),
        ),
      ),
    );

    expect(
      find.byKey(const ValueKey<String>('visual_export_svg')),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey<String>('visual_export_png')),
      findsNothing,
    );
  });

  testWidgets('visual export writes producer bytes and forwards note opt-in', (
    tester,
  ) async {
    debugDefaultTargetPlatformOverride = TargetPlatform.macOS;
    final picker = fakeFilePicker();
    picker.enqueueSaveResult('sample.svg');
    final service = _StubFileOperationsService(
      writeBytesResponses: Queue.of([const Success('sample.svg')]),
    );
    var includedAnnotations = false;
    final annotations = DocumentAnnotationCollection(
      documentId: 'sample',
      documentRevision: '1',
      annotations: [
        DocumentAnnotation(
          id: 'note',
          documentId: 'sample',
          documentRevision: '1',
          text: 'Export me',
          x: 10,
          y: 20,
          createdAt: DateTime.utc(2024),
          updatedAt: DateTime.utc(2024),
        ),
      ],
    );
    final registry = FormalSystemRegistry(
      modules: const [_RegisteredSampleModule()],
      formats: [
        DocumentFormatDescriptor(
          id: DefaultFormalSystemIds.svgFormat,
          extensions: const {'svg'},
        ),
      ],
    );

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: FileOperationsPanel(
            fileService: service,
            formalSystemRegistry: registry,
            annotations: annotations,
            visualExport: VisualExportBinding(
              systemKey: _registeredSampleKey,
              producers: {
                DefaultFormalSystemIds.svgFormat: ({
                  required includeAnnotations,
                }) async {
                  includedAnnotations = includeAnnotations;
                  return VisualExportArtifact(
                    bytes: Uint8List.fromList([1, 2, 3]),
                    mimeType: 'image/svg+xml',
                    filename: 'sample.svg',
                    width: 800,
                    height: 600,
                  );
                },
              },
            ),
          ),
        ),
      ),
    );

    await tester.tap(
      find.widgetWithText(SwitchListTile, 'Include notes in visual exports'),
    );
    await tester.tap(
      find.byKey(const ValueKey<String>('visual_export_svg')),
    );
    await tester.pumpAndSettle();
    debugDefaultTargetPlatformOverride = null;

    expect(includedAnnotations, isTrue);
    expect(service.lastWrittenBytes, [1, 2, 3]);
    expect(service.lastWrittenMimeType, 'image/svg+xml');
  });

  test('rejects an empty registered operation label at runtime', () {
    expect(
      () => RegisteredFileOperation(
        format: DefaultFormalSystemIds.svgFormat,
        direction: DocumentFormatDirection.exportDocument,
        label: '   ',
        icon: Icons.extension,
        onPressed: () {},
      ),
      throwsArgumentError,
    );
  });
}

const _registeredSampleKey = FormalSystemKey(
  type: FormalSystemTypeId('registered-sample'),
  variant: FormalSystemVariantId('standard'),
);

class _RegisteredSampleModule implements FormalSystemModule<Object> {
  const _RegisteredSampleModule();

  @override
  FormalSystemDescriptor get descriptor => FormalSystemDescriptor(
        key: _registeredSampleKey,
        schema: const DocumentSchemaDescriptor(
          id: DocumentSchemaId('test.registered-sample'),
          version: DocumentSchemaVersion(1),
        ),
        route: const WorkspaceRouteId('/registered-sample'),
        category: FormalSystemCategory.learning,
        localizationNamespace: const CapabilityNamespaceId(
          'test.registered-sample',
        ),
        semanticsNamespace: const CapabilityNamespaceId(
          'semantics.test.registered-sample',
        ),
        capabilities: const FormalSystemCapabilities(
          editing: SupportedCapability(),
        ),
        formats: const [
          DocumentFormatSupport(
            formatId: DefaultFormalSystemIds.svgFormat,
            exportAvailability: SupportedCapability(),
            preferredExtension: 'svg',
          ),
        ],
      );

  @override
  List<DocumentCodecCapability<Object>> get codecs => const [];

  @override
  List<ConversionCapability<Object, Object>> get conversions => const [];

  @override
  ExampleCatalogCapability<Object>? get examples => null;

  @override
  SessionCapability<Object>? get session => null;
}
