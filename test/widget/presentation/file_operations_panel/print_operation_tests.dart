part of '../file_operations_panel_test.dart';

class _RecordingPrintService implements PrintService {
  final List<({Uint8List bytes, String jobName})> jobs = [];
  Object? failure;
  bool _printFinished = false;

  Future<void> waitForCompletion(WidgetTester tester) async {
    final elapsed = Stopwatch()..start();
    while (!_printFinished) {
      if (elapsed.elapsed >= const Duration(seconds: 10)) {
        throw TimeoutException('The print operation did not finish.');
      }
      await tester.runAsync(
        () => Future<void>.delayed(const Duration(milliseconds: 10)),
      );
      await tester.pump();
    }
    // Drain the caller's await continuation, including _printDocument's
    // error feedback and loading-state cleanup, before reporting completion.
    await tester.pump();
  }

  @override
  Future<bool> printPdf(Uint8List bytes, {required String jobName}) async {
    try {
      if (failure != null) throw failure!;
      jobs.add((bytes: bytes, jobName: jobName));
      return true;
    } finally {
      _printFinished = true;
    }
  }
}

void _runFileOperationsPanelPrintTests() {
  group('FileOperationsPanel print', () {
    Future<void> pumpPanel(
      WidgetTester tester,
      FileOperationsPanel panel, {
      Locale? locale,
    }) async {
      await tester.pumpWidget(
        MaterialApp(
          locale: locale,
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: Scaffold(body: SingleChildScrollView(child: panel)),
        ),
      );
      await tester.pump();
    }

    testWidgets('hands the automaton vector to the system print sheet', (
      tester,
    ) async {
      final printer = _RecordingPrintService();
      await pumpPanel(
        tester,
        FileOperationsPanel(
          automaton: _buildSampleAutomaton(),
          printService: printer,
        ),
      );
      final button = find.byKey(
        const ValueKey<String>('print_document_button'),
      );
      expect(button, findsOneWidget);
      expect(find.text('Print'), findsOneWidget);

      await tester.tap(button);
      await printer.waitForCompletion(tester);
      await tester.pump();

      expect(printer.jobs, hasLength(1));
      expect(printer.jobs.single.jobName, 'Sample');
      expect(String.fromCharCodes(printer.jobs.single.bytes.take(5)), '%PDF-');
      expect(find.byType(ErrorBanner), findsNothing);
    });

    testWidgets('prints a text listing for workspaces without a diagram', (
      tester,
    ) async {
      final printer = _RecordingPrintService();
      await pumpPanel(
        tester,
        FileOperationsPanel(
          printService: printer,
          printable: () =>
              const PrintableText(title: 'Regex ε', text: '(a|b)* → ε'),
        ),
        locale: const Locale('pt'),
      );
      expect(find.text('Imprimir'), findsOneWidget);

      await tester.tap(
        find.byKey(const ValueKey<String>('print_document_button')),
      );
      await printer.waitForCompletion(tester);
      await tester.pump();

      expect(printer.jobs.single.jobName, 'Regex ε');
      expect(String.fromCharCodes(printer.jobs.single.bytes.take(5)), '%PDF-');
    });

    testWidgets('hides the command when nothing is printable', (tester) async {
      await pumpPanel(tester, const FileOperationsPanel());
      expect(
        find.byKey(const ValueKey<String>('print_document_button')),
        findsNothing,
      );
    });

    testWidgets('reports a failed print sheet with a retry', (tester) async {
      final printer = _RecordingPrintService()
        ..failure = StateError('no printer');
      await pumpPanel(
        tester,
        FileOperationsPanel(
          automaton: _buildSampleAutomaton(),
          printService: printer,
        ),
      );
      await tester.tap(
        find.byKey(const ValueKey<String>('print_document_button')),
      );
      await printer.waitForCompletion(tester);
      await tester.pump();

      expect(find.byType(ErrorBanner), findsOneWidget);
      expect(find.textContaining('Printing failed'), findsOneWidget);
      expect(printer.jobs, isEmpty);
    });
  });
}
