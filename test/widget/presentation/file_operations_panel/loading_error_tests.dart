part of '../file_operations_panel_test.dart';

void _runFileOperationsPanelLoadingErrorTests(
  _FakeFilePicker Function() fakeFilePicker,
) {
  CodecOperationException accessDenied(String operation) =>
      CodecOperationException(
        compatibilityCode: 'service.file-operations.access-denied',
        structuredMessage: StructuredMessage(
          namespace: 'service.file-operations',
          code: 'access-denied',
          category: StructuredMessageCategory.interoperability,
          severity: StructuredMessageSeverity.error,
          arguments: {
            'operation': StructuredMessageArgument.outcome(
              operation,
              role: 'file-operation',
            ),
          },
        ),
      );

  void configureNativeSaveDestinations(List<String?> paths) {
    if (kIsWeb) return;
    for (final path in paths) {
      fakeFilePicker().enqueueSaveResult(path);
    }
  }

  group('FileOperationsPanel Loading State Tests', () {
    testWidgets(
      'displays loading indicator during operation',
      (tester) async {
        configureNativeSaveDestinations(['/tmp/automaton.jff']);
        final automaton = _buildSampleAutomaton();
        final service = _StubFileOperationsService(
          saveAutomatonResponses: Queue.of([
            const Success<String>('automaton.jff'),
          ]),
          delayMs: 100,
        );

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: FileOperationsPanel(
                automaton: automaton,
                fileService: service,
              ),
            ),
          ),
        );

        // Trigger save operation
        await tester.tap(
          find.text(kIsWeb ? 'Download JFLAP' : 'Save as JFLAP'),
        );
        await tester.pump();

        // Should show loading indicator
        expect(find.byType(CircularProgressIndicator), findsOneWidget);

        // Complete the operation
        await tester.pumpAndSettle();

        // Loading indicator should disappear
        expect(find.byType(CircularProgressIndicator), findsNothing);
      },
      variant: const TargetPlatformVariant(<TargetPlatform>{
        TargetPlatform.macOS,
      }),
    );

    testWidgets(
      'disables buttons during loading',
      (tester) async {
        configureNativeSaveDestinations(['/tmp/automaton.jff']);
        final automaton = _buildSampleAutomaton();
        final service = _StubFileOperationsService(
          saveAutomatonResponses: Queue.of([
            const Success<String>('automaton.jff'),
          ]),
          delayMs: 100,
        );

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: FileOperationsPanel(
                automaton: automaton,
                fileService: service,
              ),
            ),
          ),
        );

        // Trigger save operation
        await tester.tap(
          find.text(kIsWeb ? 'Download JFLAP' : 'Save as JFLAP'),
        );
        await tester.pump();

        // Buttons should be disabled
        final saveButton = tester.widget<ElevatedButton>(
          find.ancestor(
            of: find.text(kIsWeb ? 'Download JFLAP' : 'Save as JFLAP'),
            matching: find.byType(ElevatedButton),
          ),
        );
        expect(saveButton.onPressed, isNull);

        // Complete the operation
        await tester.pumpAndSettle();

        // Buttons should be enabled again
        final enabledButton = tester.widget<ElevatedButton>(
          find.ancestor(
            of: find.text(kIsWeb ? 'Download JFLAP' : 'Save as JFLAP'),
            matching: find.byType(ElevatedButton),
          ),
        );
        expect(enabledButton.onPressed, isNotNull);
      },
      variant: const TargetPlatformVariant(<TargetPlatform>{
        TargetPlatform.macOS,
      }),
    );
  });

  group('FileOperationsPanel Error Handling Tests', () {
    testWidgets(
      'displays error banner on save failure',
      (tester) async {
        configureNativeSaveDestinations(['/tmp/automaton.jff']);
        final automaton = _buildSampleAutomaton();
        final service = _StubFileOperationsService(
          saveAutomatonResponses: Queue.of([
            const Failure<String>('Failed to save automaton: disk full'),
          ]),
        );

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: FileOperationsPanel(
                automaton: automaton,
                fileService: service,
              ),
            ),
          ),
        );

        await tester.tap(
          find.text(kIsWeb ? 'Download JFLAP' : 'Save as JFLAP'),
        );
        await tester.pump();
        await tester.pumpAndSettle();

        expect(find.byType(ErrorBanner), findsOneWidget);
        expect(find.textContaining('Failed to save automaton'), findsOneWidget);
      },
      variant: const TargetPlatformVariant(<TargetPlatform>{
        TargetPlatform.macOS,
      }),
    );

    testWidgets(
      'save failure resolves structured file error in locale',
      (tester) async {
        configureNativeSaveDestinations(['/tmp/automaton.jff']);
        final automaton = _buildSampleAutomaton();
        final message = StructuredMessage(
          namespace: 'service.file-operations',
          code: 'access-denied',
          category: StructuredMessageCategory.interoperability,
          severity: StructuredMessageSeverity.error,
          arguments: {
            'operation': StructuredMessageArgument.outcome(
              'write',
              role: 'file-operation',
            ),
          },
        );
        final service = _StubFileOperationsService(
          saveAutomatonResponses: Queue.of([
            Failure<String>(message.stableCode, structuredMessage: message),
          ]),
        );

        await tester.pumpWidget(
          MaterialApp(
            locale: const Locale('pt'),
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            home: Scaffold(
              body: FileOperationsPanel(
                automaton: automaton,
                fileService: service,
              ),
            ),
          ),
        );

        await tester.tap(find.text('Salvar como JFLAP'));
        await tester.pumpAndSettle();

        expect(
          find.textContaining(
            'O Turing Lab não tem permissão para salvar no local selecionado.',
          ),
          findsOneWidget,
        );
        expect(find.textContaining(message.stableCode), findsNothing);
      },
      variant: const TargetPlatformVariant(<TargetPlatform>{
        TargetPlatform.macOS,
      }),
    );

    testWidgets(
      'retry button retries failed operation',
      (tester) async {
        configureNativeSaveDestinations([
          '/tmp/automaton.jff',
          '/tmp/automaton-retry.jff',
        ]);
        final automaton = _buildSampleAutomaton();
        final service = _StubFileOperationsService(
          saveAutomatonResponses: Queue.of([
            const Failure<String>('Failed to save automaton: network error'),
            const Success<String>('automaton.jff'),
          ]),
        );

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: FileOperationsPanel(
                automaton: automaton,
                fileService: service,
              ),
            ),
          ),
        );

        // First attempt fails
        await tester.tap(
          find.text(kIsWeb ? 'Download JFLAP' : 'Save as JFLAP'),
        );
        await tester.pump();
        await tester.pumpAndSettle();

        expect(find.byType(ErrorBanner), findsOneWidget);
        expect(service.saveAutomatonCallCount, equals(1));

        // Retry the operation
        await tester.tap(find.text('Retry'));
        await tester.pump();
        await tester.pumpAndSettle();

        expect(service.saveAutomatonCallCount, equals(2));
        if (kIsWeb) {
          expect(find.textContaining('Download started'), findsOneWidget);
        } else {
          expect(find.text('Automaton saved successfully'), findsOneWidget);
        }
      },
      variant: const TargetPlatformVariant(<TargetPlatform>{
        TargetPlatform.macOS,
      }),
    );

    testWidgets(
      'dismiss button clears error banner',
      (tester) async {
        configureNativeSaveDestinations(['/tmp/automaton.jff']);
        final automaton = _buildSampleAutomaton();
        final service = _StubFileOperationsService(
          saveAutomatonResponses: Queue.of([
            const Failure<String>('Failed to save automaton: access denied'),
          ]),
        );

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: FileOperationsPanel(
                automaton: automaton,
                fileService: service,
              ),
            ),
          ),
        );

        await tester.tap(
          find.text(kIsWeb ? 'Download JFLAP' : 'Save as JFLAP'),
        );
        await tester.pump();
        await tester.pumpAndSettle();

        expect(find.byType(ErrorBanner), findsOneWidget);

        // Dismiss the error
        await tester.tap(find.text('Dismiss'));
        await tester.pump();

        expect(find.byType(ErrorBanner), findsNothing);
      },
      variant: const TargetPlatformVariant(<TargetPlatform>{
        TargetPlatform.macOS,
      }),
    );

    testWidgets(
      'displays export error correctly',
      (tester) async {
        configureNativeSaveDestinations(['/tmp/automaton.svg']);
        final automaton = _buildSampleAutomaton();
        final service = _StubFileOperationsService(
          exportResponses: Queue.of([
            const Failure<String>('Failed to export automaton: invalid state'),
          ]),
        );

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: FileOperationsPanel(
                automaton: automaton,
                fileService: service,
              ),
            ),
          ),
        );

        await tester.tap(find.text(kIsWeb ? 'Download SVG' : 'Export SVG'));
        await tester.pump();
        await tester.pumpAndSettle();

        expect(find.byType(ErrorBanner), findsOneWidget);
        expect(
          find.textContaining('Failed to export automaton'),
          findsOneWidget,
        );
      },
      variant: const TargetPlatformVariant(<TargetPlatform>{
        TargetPlatform.macOS,
      }),
    );

    testWidgets(
      'handles load failure with error banner for non-critical errors',
      (tester) async {
        final automaton = _buildSampleAutomaton();
        final service = _StubFileOperationsService(
          loadAutomatonResponses: Queue.of([
            const Failure<FSA>('Failed to load automaton: file is empty'),
          ]),
        );

        final file = PlatformFile(
          name: 'empty.jff',
          size: 0,
          bytes: Uint8List(0),
        );
        fakeFilePicker().enqueuePickResult(FilePickerResult([file]));

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: FileOperationsPanel(
                automaton: automaton,
                fileService: service,
              ),
            ),
          ),
        );

        await tester.tap(find.text('Load JFLAP'));
        await tester.pump();
        await tester.pumpAndSettle();

        expect(service.loadAutomatonCallCount, equals(1));
        expect(find.byType(ErrorBanner), findsOneWidget);
      },
    );

    testWidgets('shows permission denied load failures in the error banner', (
      tester,
    ) async {
      final automaton = _buildSampleAutomaton();
      final service = _StubFileOperationsService(
        loadAutomatonResponses: Queue.of([
          const Failure<FSA>(
            'Failed to load automaton from JFLAP format: Turing Lab could not read the selected file. The file may be outside the app sandbox or no longer readable. Pick the file again from the system dialog and try again.',
          ),
        ]),
      );

      final file = PlatformFile(
        name: 'sandboxed.jff',
        size: 3,
        bytes: Uint8List.fromList([1, 2, 3]),
      );
      fakeFilePicker().enqueuePickResult(FilePickerResult([file]));

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: FileOperationsPanel(
              automaton: automaton,
              fileService: service,
            ),
          ),
        ),
      );

      await tester.tap(find.text('Load JFLAP'));
      await tester.pump();
      await tester.pumpAndSettle();

      expect(find.byType(ImportErrorDialog), findsNothing);
      expect(find.byType(ErrorBanner), findsOneWidget);
      expect(
        find.textContaining('could not read the selected file'),
        findsOneWidget,
      );
    });

    testWidgets(
      'shows import error dialog for invalid automaton JSON failures',
      (tester) async {
        final automaton = _buildSampleAutomaton();
        final service = _StubFileOperationsService(
          loadAutomatonResponses: Queue.of([
            const Failure<FSA>('Invalid automaton JSON format'),
          ]),
        );

        final file = PlatformFile(
          name: 'invalid.json',
          size: 10,
          bytes: Uint8List.fromList([123, 125]),
        );
        fakeFilePicker().enqueuePickResult(FilePickerResult([file]));

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: FileOperationsPanel(
                automaton: automaton,
                fileService: service,
              ),
            ),
          ),
        );

        await tester.tap(find.text('Load JSON'));
        await tester.pump();
        await tester.pumpAndSettle();

        expect(service.loadAutomatonCallCount, equals(1));
        expect(find.byType(ImportErrorDialog), findsOneWidget);
      },
    );

    testWidgets('shows inaccessible file dialog for JSON access failures', (
      tester,
    ) async {
      final automaton = _buildSampleAutomaton();
      final service = _StubFileOperationsService(
        loadAutomatonResponses: Queue.of([
          const Failure<FSA>(platformFileInaccessibleErrorCode),
        ]),
      );

      final file = PlatformFile(
        name: 'icloud.json',
        size: 10,
        bytes: Uint8List.fromList([123, 125]),
      );
      fakeFilePicker().enqueuePickResult(FilePickerResult([file]));

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: FileOperationsPanel(
              automaton: automaton,
              fileService: service,
            ),
          ),
        ),
      );

      await tester.tap(find.text('Load JSON'));
      await tester.pump();
      await tester.pumpAndSettle();

      expect(service.loadAutomatonCallCount, equals(1));
      expect(find.byType(ImportErrorDialog), findsOneWidget);
      expect(find.text('File Access Unavailable'), findsOneWidget);
      expect(
        find.textContaining('could not access the selected file'),
        findsOneWidget,
      );
      expect(find.text(platformFileInaccessibleErrorCode), findsNothing);
      expect(find.text('View technical details'), findsNothing);
    });

    testWidgets('localizes structured exceptions raised while loading JFLAP', (
      tester,
    ) async {
      final service = _StubFileOperationsService(
        loadJflapException: accessDenied('read'),
      );
      fakeFilePicker().enqueuePickResult(
        FilePickerResult([
          PlatformFile(
            name: 'denied.jff',
            size: 1,
            bytes: Uint8List.fromList([0]),
          ),
        ]),
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: FileOperationsPanel(
              automaton: _buildSampleAutomaton(),
              fileService: service,
            ),
          ),
        ),
      );
      await tester.tap(find.text('Load JFLAP'));
      await tester.pumpAndSettle();

      expect(
        find.textContaining('does not have permission to read'),
        findsOneWidget,
      );
      expect(
        find.textContaining('service.file-operations.access-denied'),
        findsNothing,
      );
    });

    testWidgets('localizes structured exceptions raised while loading JSON', (
      tester,
    ) async {
      final service = _StubFileOperationsService(
        loadJsonException: accessDenied('read'),
      );
      fakeFilePicker().enqueuePickResult(
        FilePickerResult([
          PlatformFile(
            name: 'denied.json',
            size: 2,
            bytes: Uint8List.fromList([123, 125]),
          ),
        ]),
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: FileOperationsPanel(
              automaton: _buildSampleAutomaton(),
              fileService: service,
            ),
          ),
        ),
      );
      await tester.tap(find.text('Load JSON'));
      await tester.pumpAndSettle();

      expect(
        find.textContaining('does not have permission to read'),
        findsOneWidget,
      );
      expect(
        find.textContaining('service.file-operations.access-denied'),
        findsNothing,
      );
    });

    testWidgets(
      'localizes structured exceptions raised while exporting SVG',
      (tester) async {
        configureNativeSaveDestinations(['/tmp/denied.svg']);
        final service = _StubFileOperationsService(
          exportSvgException: accessDenied('write'),
        );

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: FileOperationsPanel(
                automaton: _buildSampleAutomaton(),
                fileService: service,
              ),
            ),
          ),
        );
        await tester.tap(find.text('Export SVG'));
        await tester.pumpAndSettle();

        expect(
          find.textContaining('does not have permission to save'),
          findsOneWidget,
        );
        expect(
          find.textContaining('service.file-operations.access-denied'),
          findsNothing,
        );
      },
      variant: const TargetPlatformVariant(<TargetPlatform>{
        TargetPlatform.macOS,
      }),
    );

    testWidgets(
      'localizes structured exceptions raised while exporting PNG',
      (tester) async {
        final service = _StubFileOperationsService(
          exportPngException: accessDenied('write'),
        );

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: FileOperationsPanel(
                automaton: _buildSampleAutomaton(),
                fileService: service,
              ),
            ),
          ),
        );
        await tester.tap(find.text('Export PNG'));
        await tester.pumpAndSettle();

        expect(
          find.textContaining('does not have permission to save'),
          findsOneWidget,
        );
        expect(
          find.textContaining('service.file-operations.access-denied'),
          findsNothing,
        );
      },
      variant: const TargetPlatformVariant(<TargetPlatform>{
        TargetPlatform.macOS,
      }),
    );
  });
}
