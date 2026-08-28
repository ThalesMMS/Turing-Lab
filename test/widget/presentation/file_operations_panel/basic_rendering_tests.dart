part of '../file_operations_panel_test.dart';

void _runFileOperationsPanelBasicRenderingTests() {
  group('FileOperationsPanel Basic Rendering Tests', () {
    testWidgets('displays panel title correctly', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(home: Scaffold(body: FileOperationsPanel())),
      );

      expect(find.byType(FileOperationsPanel), findsOneWidget);
      expect(find.text('File Operations'), findsOneWidget);
      expect(find.byType(Card), findsOneWidget);
    });

    testWidgets('displays automaton section when automaton is provided', (
      tester,
    ) async {
      final automaton = _buildSampleAutomaton();

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(body: FileOperationsPanel(automaton: automaton)),
        ),
      );

      expect(find.text('FSA'), findsOneWidget);
      expect(find.text('Load JFLAP'), findsOneWidget);
      expect(find.text('Load JSON'), findsOneWidget);

      // Check for platform-specific button text
      if (kIsWeb) {
        expect(find.text('Download JFLAP'), findsOneWidget);
        expect(find.text('Download JSON'), findsOneWidget);
        expect(find.text('Download SVG'), findsOneWidget);
      } else {
        expect(find.text('Save as JFLAP'), findsOneWidget);
        expect(find.text('Save as JSON'), findsOneWidget);
        expect(find.text('Export SVG'), findsOneWidget);
        expect(find.text('Export PNG'), findsOneWidget);
      }
    });

    testWidgets('localizes visual export controls in Portuguese', (
      tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(
          locale: const Locale('pt'),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: Scaffold(
            body: FileOperationsPanel(
              automaton: _buildSampleAutomaton(),
              annotations: DocumentAnnotationCollection(
                documentId: 'sample',
                documentRevision: '1',
                annotations: [
                  DocumentAnnotation(
                    id: 'note-1',
                    documentId: 'sample',
                    documentRevision: '1',
                    text: 'Nota formal',
                    x: 10,
                    y: 20,
                    createdAt: DateTime.utc(2026),
                    updatedAt: DateTime.utc(2026),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Operações de arquivo'), findsOneWidget);
      expect(find.text('Exportar SVG'), findsOneWidget);
      if (!kIsWeb) expect(find.text('Exportar PNG'), findsOneWidget);
      expect(
        find.text('Incluir notas nas exportações visuais'),
        findsOneWidget,
      );
      expect(find.text('Include notes in visual exports'), findsNothing);
    });

    testWidgets('displays grammar section when grammar is provided', (
      tester,
    ) async {
      final grammar = _buildSampleGrammar();

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(body: FileOperationsPanel(grammar: grammar)),
        ),
      );

      expect(find.text('Grammar'), findsOneWidget);
      expect(find.text('Load JFLAP'), findsAtLeastNWidgets(1));
      expect(find.text(kIsWeb ? 'Download SVG' : 'Export SVG'), findsOneWidget);

      // Check for platform-specific button text
      if (kIsWeb) {
        expect(find.text('Download JFLAP'), findsOneWidget);
      } else {
        expect(find.text('Save as JFLAP'), findsOneWidget);
      }
    });

    testWidgets('visual annotation export is an explicit opt-in', (
      tester,
    ) async {
      final timestamp = DateTime.utc(2026);
      final annotations = DocumentAnnotationCollection(
        documentId: 'sample',
        documentRevision: '1',
        annotations: [
          DocumentAnnotation(
            id: 'note-1',
            documentId: 'sample',
            documentRevision: '1',
            text: 'Export me',
            x: 10,
            y: 20,
            createdAt: timestamp,
            updatedAt: timestamp,
          ),
        ],
      );
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: FileOperationsPanel(
              automaton: _buildSampleAutomaton(),
              annotations: annotations,
            ),
          ),
        ),
      );

      final switchFinder = find.widgetWithText(
        SwitchListTile,
        'Include notes in visual exports',
      );
      expect(switchFinder, findsOneWidget);
      expect(tester.widget<SwitchListTile>(switchFinder).value, isFalse);
      await tester.tap(switchFinder);
      await tester.pump();
      expect(tester.widget<SwitchListTile>(switchFinder).value, isTrue);
    });

    testWidgets(
      'displays both automaton and grammar sections when both provided',
      (tester) async {
        final automaton = _buildSampleAutomaton();
        final grammar = _buildSampleGrammar();

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: FileOperationsPanel(automaton: automaton, grammar: grammar),
            ),
          ),
        );

        expect(find.text('FSA'), findsOneWidget);
        expect(find.text('Grammar'), findsOneWidget);
        expect(find.text('Load JFLAP'), findsAtLeastNWidgets(2));
      },
    );

    testWidgets(
      'displays no operation buttons when neither automaton nor grammar provided',
      (tester) async {
        await tester.pumpWidget(
          const MaterialApp(home: Scaffold(body: FileOperationsPanel())),
        );

        expect(find.text('File Operations'), findsOneWidget);
        expect(find.text('Automaton'), findsNothing);
        expect(find.text('Grammar'), findsNothing);
        expect(find.text('Load JFLAP'), findsNothing);
      },
    );
  });
}
