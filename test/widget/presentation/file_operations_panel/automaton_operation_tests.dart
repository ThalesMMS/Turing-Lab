part of '../file_operations_panel_test.dart';

const _fsaJflapExportButtonKey = ValueKey<String>('fsa_jflap_export_button');
const _fsaJflapImportButtonKey = ValueKey<String>('fsa_jflap_import_button');
const _fsaJsonImportButtonKey = ValueKey<String>('fsa_json_import_button');
const _fsaSvgExportButtonKey = ValueKey<String>('fsa_svg_export_button');
const _fsaPngExportButtonKey = ValueKey<String>('fsa_png_export_button');

void _runFileOperationsPanelAutomatonOperationTests(
  _FakeFilePicker Function() fakeFilePicker,
) {
  Future<void> pumpFileOperationsPanel(
    WidgetTester tester, {
    FSA? automaton,
    FileOperationsService? fileService,
    ValueChanged<FSA>? onAutomatonLoaded,
    DocumentAnnotationCollection? annotations,
  }) {
    return tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: FileOperationsPanel(
            automaton: automaton,
            fileService: fileService,
            onAutomatonLoaded: onAutomatonLoaded,
            annotations: annotations,
          ),
        ),
      ),
    );
  }

  Future<void> tapAndSettle(WidgetTester tester, Finder finder) async {
    await tester.tap(finder);
    await tester.pump();
    await tester.pumpAndSettle();
  }

  group('FileOperationsPanel Automaton Operations Tests', () {
    testWidgets('automaton buttons have correct icons', (tester) async {
      final automaton = _buildSampleAutomaton();

      await pumpFileOperationsPanel(tester, automaton: automaton);

      expect(find.byIcon(Icons.save), findsAtLeastNWidgets(1));
      expect(find.byIcon(Icons.folder_open), findsOneWidget);
      expect(find.byIcon(Icons.data_object), findsOneWidget);
      expect(find.byIcon(Icons.upload_file), findsOneWidget);
      expect(find.byIcon(Icons.image), findsOneWidget);
      if (!kIsWeb) {
        expect(find.byIcon(Icons.photo), findsOneWidget);
      }
    });

    testWidgets('save automaton button triggers callback on web', (
      tester,
    ) async {
      final automaton = _buildSampleAutomaton();
      final service = _StubFileOperationsService(
        saveAutomatonResponses: Queue.of([
          const Success<String>('automaton.jff'),
        ]),
      );

      await pumpFileOperationsPanel(
        tester,
        automaton: automaton,
        fileService: service,
      );

      await tapAndSettle(tester, find.byKey(_fsaJflapExportButtonKey));

      expect(service.saveAutomatonCallCount, equals(1));
      expect(find.textContaining('Download started'), findsOneWidget);
    }, skip: !kIsWeb);

    testWidgets(
      'save automaton renders a structured codec failure',
      (tester) async {
        final automaton = _buildSampleAutomaton();
        final service = _StubFileOperationsService(
          saveAutomatonResponses: Queue.of([
            Failure<String>(
              'codec.lossy-export-requires-confirmation',
              structuredMessage: _parserFailureMessage(
                'service.file-operations',
                'lossy-export-requires-confirmation',
              ),
            ),
          ]),
        );
        fakeFilePicker().enqueueSaveResult('/tmp/automaton.jff');

        await pumpFileOperationsPanel(
          tester,
          automaton: automaton,
          fileService: service,
        );
        await tapAndSettle(tester, find.byKey(_fsaJflapExportButtonKey));

        expect(
          find.textContaining(
            'Review and confirm the compatibility changes before exporting '
            'this document.',
          ),
          findsOneWidget,
        );
        expect(
          find.textContaining('codec.lossy-export-requires-confirmation'),
          findsNothing,
        );
      },
      variant: const TargetPlatformVariant(<TargetPlatform>{
        TargetPlatform.windows,
      }),
      skip: kIsWeb,
    );

    testWidgets('save automaton localizes a synchronous codec exception', (
      tester,
    ) async {
      final service = _StubFileOperationsService(
        serializeAutomatonException: CodecOperationException(
          compatibilityCode: 'codec.malformed.invalidValue',
          structuredMessage: _parserFailureMessage(
            'service.file-operations',
            'invalid-model-type',
          ),
        ),
      );

      await pumpFileOperationsPanel(
        tester,
        automaton: _buildSampleAutomaton(),
        fileService: service,
      );
      await tapAndSettle(tester, find.byKey(_fsaJflapExportButtonKey));

      expect(
        find.textContaining(
          'The document contains a different formal-system model than '
          'expected.',
        ),
        findsOneWidget,
      );
      expect(find.textContaining('codec.malformed.invalidValue'), findsNothing);
    }, skip: kIsWeb);

    testWidgets(
      'iOS save automaton passes bytes to the picker',
      (tester) async {
        final automaton = _buildSampleAutomaton();
        final service = _StubFileOperationsService();
        final picker = fakeFilePicker();
        picker.enqueueSaveResult('/tmp/automaton.jff');

        await pumpFileOperationsPanel(
          tester,
          automaton: automaton,
          fileService: service,
        );

        await tapAndSettle(tester, find.byKey(_fsaJflapExportButtonKey));

        expect(service.saveAutomatonCallCount, equals(0));
        expect(picker.lastSaveBytes, isNotNull);
        expect(picker.lastSaveBytes, isNotEmpty);
        expect(find.text('Automaton saved successfully'), findsOneWidget);
      },
      variant: const TargetPlatformVariant(<TargetPlatform>{
        TargetPlatform.iOS,
      }),
      skip: kIsWeb,
    );

    testWidgets('load automaton button triggers callback', (tester) async {
      final automaton = _buildSampleAutomaton();
      bool automatonLoaded = false;
      FSA? loadedAutomatonPayload;

      final service = _StubFileOperationsService(
        loadAutomatonResponses: Queue.of([Success<FSA>(automaton)]),
      );

      final file = PlatformFile(
        name: 'test.jff',
        size: 100,
        bytes: Uint8List.fromList([0, 1, 2]),
      );
      final picker = fakeFilePicker();
      picker.enqueuePickResult(FilePickerResult([file]));

      await pumpFileOperationsPanel(
        tester,
        automaton: automaton,
        fileService: service,
        onAutomatonLoaded: (loadedAutomaton) {
          automatonLoaded = true;
          loadedAutomatonPayload = loadedAutomaton;
        },
      );

      await tapAndSettle(tester, find.byKey(_fsaJflapImportButtonKey));

      expect(service.loadAutomatonCallCount, equals(1));
      expect(automatonLoaded, isTrue);
      expect(loadedAutomatonPayload, same(automaton));
      expect(find.text('Automaton loaded successfully'), findsOneWidget);
    });

    testWidgets('failed to parse json errors open invalid JSON dialog', (
      tester,
    ) async {
      final automaton = _buildSampleAutomaton();
      final service = _StubFileOperationsService(
        loadAutomatonResponses: Queue.of([
          const Failure<FSA>('Failed to parse JSON while importing automaton'),
        ]),
      );

      final file = PlatformFile(
        name: 'broken.json',
        size: 2,
        bytes: Uint8List.fromList([123, 125]),
      );
      final picker = fakeFilePicker();
      picker.enqueuePickResult(FilePickerResult([file]));

      await pumpFileOperationsPanel(
        tester,
        automaton: automaton,
        fileService: service,
      );

      await tapAndSettle(tester, find.byKey(_fsaJsonImportButtonKey));

      expect(find.byType(ImportErrorDialog), findsOneWidget);
      expect(find.text('Invalid JSON Structure'), findsOneWidget);
      expect(find.textContaining('Failed to parse JSON'), findsOneWidget);
    });

    testWidgets('JSON import renders structured failures at the UI boundary', (
      tester,
    ) async {
      final automaton = _buildSampleAutomaton();
      final service = _StubFileOperationsService(
        loadAutomatonResponses: Queue.of([
          Failure<FSA>(
            'codec.requires-interoperability-review',
            structuredMessage: _parserFailureMessage(
              'service.file-operations',
              'interoperability-review-required',
            ),
          ),
        ]),
      );
      final picker = fakeFilePicker();
      picker.enqueuePickResult(
        FilePickerResult([
          PlatformFile(
            name: 'review.json',
            size: 2,
            bytes: Uint8List.fromList([123, 125]),
          ),
        ]),
      );

      await pumpFileOperationsPanel(
        tester,
        automaton: automaton,
        fileService: service,
      );
      await tapAndSettle(tester, find.byKey(_fsaJsonImportButtonKey));

      expect(
        find.textContaining(
          'Review the compatibility changes before importing this document.',
        ),
        findsOneWidget,
      );
      expect(
        find.textContaining('codec.requires-interoperability-review'),
        findsNothing,
      );
    });

    testWidgets(
      'load JFLAP routes version failures to unsupported version dialog',
      (tester) async {
        final automaton = _buildSampleAutomaton();
        final service = _StubFileOperationsService(
          loadAutomatonResponses: Queue.of([
            const Failure<FSA>('Unsupported version: JFLAP schema 8'),
          ]),
        );

        final file = PlatformFile(
          name: 'future.jff',
          size: 3,
          bytes: Uint8List.fromList([0, 1, 2]),
        );
        final picker = fakeFilePicker();
        picker.enqueuePickResult(FilePickerResult([file]));

        await pumpFileOperationsPanel(
          tester,
          automaton: automaton,
          fileService: service,
        );

        await tapAndSettle(tester, find.byKey(_fsaJflapImportButtonKey));

        expect(find.byType(ImportErrorDialog), findsOneWidget);
        expect(find.text('Unsupported File Version'), findsOneWidget);
      },
    );

    testWidgets(
      'load JSON treats inaccessible file payload as a file access error',
      (tester) async {
        final automaton = _buildSampleAutomaton();
        final file = PlatformFile(name: 'empty.json', size: 0);
        final picker = fakeFilePicker();
        picker.enqueuePickResult(FilePickerResult([file]));

        await pumpFileOperationsPanel(tester, automaton: automaton);

        await tapAndSettle(tester, find.byKey(_fsaJsonImportButtonKey));

        expect(find.byType(ImportErrorDialog), findsOneWidget);
        expect(find.text('File Access Unavailable'), findsOneWidget);
        expect(
          find.textContaining('could not access the selected JSON file data'),
          findsOneWidget,
        );
      },
    );

    testWidgets('export automaton as SVG triggers callback on web', (
      tester,
    ) async {
      final automaton = _buildSampleAutomaton();
      final service = _StubFileOperationsService(
        exportResponses: Queue.of([const Success<String>('automaton.svg')]),
      );

      await pumpFileOperationsPanel(
        tester,
        automaton: automaton,
        fileService: service,
      );

      await tapAndSettle(tester, find.byKey(_fsaSvgExportButtonKey));

      expect(service.exportCallCount, equals(1));
      expect(service.lastFsaSvgExport, same(automaton));
      expect(find.textContaining('Download started'), findsOneWidget);
    }, skip: !kIsWeb);

    testWidgets(
      'desktop SVG export uses current FSA model',
      (tester) async {
        final automaton = _buildSampleAutomaton();
        final service = _StubFileOperationsService(
          exportResponses: Queue.of([
            const Success<String>('/tmp/automaton.svg'),
          ]),
        );
        final picker = fakeFilePicker();
        picker.enqueueSaveResult('/tmp/automaton.svg');

        await pumpFileOperationsPanel(
          tester,
          automaton: automaton,
          fileService: service,
        );

        await tapAndSettle(tester, find.byKey(_fsaSvgExportButtonKey));

        expect(service.exportCallCount, equals(1));
        expect(service.lastFsaSvgExport, same(automaton));
        expect(find.text('Automaton exported successfully'), findsOneWidget);
      },
      variant: const TargetPlatformVariant(<TargetPlatform>{
        TargetPlatform.macOS,
      }),
      skip: kIsWeb,
    );

    testWidgets(
      'desktop PNG export writes pre-rendered bytes without rerendering',
      (tester) async {
        final automaton = _buildSampleAutomaton();
        final timestamp = DateTime.utc(2026);
        final annotations = DocumentAnnotationCollection(
          documentId: automaton.id,
          documentRevision: '1',
          annotations: [
            DocumentAnnotation(
              id: 'note-1',
              documentId: automaton.id,
              documentRevision: '1',
              text: 'PNG note',
              x: 10,
              y: 20,
              createdAt: timestamp,
              updatedAt: timestamp,
            ),
          ],
        );
        final service = _StubFileOperationsService(
          exportResponses: Queue.of([
            const Success<String>('/tmp/automaton.png'),
          ]),
        );
        final picker = fakeFilePicker();
        picker.enqueueSaveResult('/tmp/automaton.png');

        await pumpFileOperationsPanel(
          tester,
          automaton: automaton,
          fileService: service,
          annotations: annotations,
        );

        final annotationSwitch = find.widgetWithText(
          SwitchListTile,
          'Include notes in visual exports',
        );
        await tester.ensureVisible(annotationSwitch);
        await tapAndSettle(tester, annotationSwitch);
        await tester.ensureVisible(find.byKey(_fsaPngExportButtonKey));
        await tapAndSettle(tester, find.byKey(_fsaPngExportButtonKey));

        expect(service.exportPngBytesCallCount, equals(1));
        expect(service.lastPngIncludeAnnotations, isTrue);
        expect(service.lastPngAnnotations, same(annotations));
        expect(service.writePngBytesCallCount, equals(1));
        expect(service.exportAutomatonPngCallCount, equals(0));
      },
      variant: const TargetPlatformVariant(<TargetPlatform>{
        TargetPlatform.macOS,
      }),
      skip: kIsWeb,
    );
  });
}
