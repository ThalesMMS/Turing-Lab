import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:turing_lab/core/interoperability/interoperability.dart';
import 'package:turing_lab/core/messages/structured_message.dart';
import 'package:turing_lab/l10n/app_localizations.dart';
import 'package:turing_lab/presentation/widgets/document_interoperability_failure_dialog.dart';
import 'package:turing_lab/presentation/widgets/document_interoperability_preview.dart';
import 'package:turing_lab/presentation/widgets/document_interoperability_review_dialog.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('DocumentInteroperabilityReviewDialog', () {
    testWidgets('shows detected metadata and a localized field report', (
      tester,
    ) async {
      final semantics = tester.ensureSemantics();

      await _pumpDialogHarness(
        tester,
        locale: const Locale('pt'),
        preview: DocumentInteroperabilityPreview(
          operation: DocumentInteroperabilityOperation.importDocument,
          fileName: 'entrada-incorreta.txt',
          systemLabel: 'Autômato finito',
          formatLabel: 'XML do JFLAP',
          schemaVersion: 1,
          fidelity: DocumentFidelity.normalized,
          facts: const [
            DocumentInteroperabilityFact(
              label: 'Variante',
              value: 'Múltiplas fitas',
            ),
            DocumentInteroperabilityFact(label: 'Número de fitas', value: '2'),
          ],
          diagnostics: const [
            CodecDiagnostic(
              code: 'jflap.canonical-order',
              message: 'This English codec message must not be primary copy.',
              path: '/structure/automaton/state[2]/x',
              location: CodecSourceLocation(line: 9, column: 7),
              sourceValue: 'private payload',
              disposition: CodecDiagnosticDisposition.normalized,
            ),
          ],
        ),
      );

      await tester.tap(find.text('Open review'));
      await tester.pumpAndSettle();

      expect(find.text('Revisar importação'), findsOneWidget);
      expect(find.text('entrada-incorreta.txt'), findsOneWidget);
      expect(find.text('Autômato finito'), findsOneWidget);
      expect(find.text('XML do JFLAP'), findsOneWidget);
      expect(find.text('Normalizada'), findsOneWidget);
      expect(find.text('Variante'), findsOneWidget);
      expect(find.text('Múltiplas fitas'), findsOneWidget);
      expect(find.text('Número de fitas'), findsOneWidget);
      expect(find.text('Campo normalizado'), findsOneWidget);
      expect(
        find.text('A ordem de estados e transições foi padronizada.'),
        findsOneWidget,
      );
      expect(
        find.textContaining('/structure/automaton/state[2]/x'),
        findsOneWidget,
      );
      expect(find.textContaining('Linha 9, coluna 7'), findsOneWidget);
      expect(find.textContaining('private payload'), findsNothing);
      expect(find.textContaining('oculto por privacidade'), findsOneWidget);
      expect(find.textContaining('This English codec message'), findsNothing);
      final cancelSemantics = tester
          .getSemantics(find.text('Cancelar'))
          .getSemanticsData();
      expect(cancelSemantics.label, 'Cancelar');
      expect(cancelSemantics.flagsCollection.isButton, isTrue);
      expect(cancelSemantics.flagsCollection.isEnabled, ui.Tristate.isTrue);
      expect(cancelSemantics.hasAction(ui.SemanticsAction.tap), isTrue);
      semantics.dispose();
    });

    testWidgets('lossy import requires an explicit destructive action', (
      tester,
    ) async {
      await _pumpDialogHarness(
        tester,
        preview: _preview(fidelity: DocumentFidelity.lossy),
      );

      await tester.tap(find.text('Open review'));
      await tester.pumpAndSettle();

      expect(find.text('Data loss'), findsOneWidget);
      expect(find.text('Import with data loss'), findsOneWidget);
      expect(
        find.textContaining('will be lost if you replace'),
        findsOneWidget,
      );

      await tester.sendKeyEvent(LogicalKeyboardKey.enter);
      await tester.pumpAndSettle();
      expect(find.text('Result: false'), findsOneWidget);
    });

    testWidgets(
      'supports Tab, Shift+Tab, Enter, Escape, and focus restoration',
      (tester) async {
        await _pumpDialogHarness(tester, preview: _preview());
        final trigger = find.text('Open review');

        await tester.tap(trigger);
        await tester.pumpAndSettle();
        await tester.sendKeyEvent(LogicalKeyboardKey.tab);
        await tester.sendKeyDownEvent(LogicalKeyboardKey.shiftLeft);
        await tester.sendKeyEvent(LogicalKeyboardKey.tab);
        await tester.sendKeyUpEvent(LogicalKeyboardKey.shiftLeft);
        await tester.sendKeyEvent(LogicalKeyboardKey.enter);
        await tester.pumpAndSettle();
        expect(find.text('Result: false'), findsOneWidget);

        await tester.tap(trigger);
        await tester.pumpAndSettle();
        await tester.sendKeyEvent(LogicalKeyboardKey.tab);
        await tester.sendKeyEvent(LogicalKeyboardKey.enter);
        await tester.pumpAndSettle();
        expect(find.text('Result: true'), findsOneWidget);

        await tester.tap(trigger);
        await tester.pumpAndSettle();
        await tester.sendKeyEvent(LogicalKeyboardKey.escape);
        await tester.pumpAndSettle();
        expect(find.byType(DocumentInteroperabilityReviewDialog), findsNothing);

        await tester.sendKeyEvent(LogicalKeyboardKey.enter);
        await tester.pumpAndSettle();
        expect(
          find.byType(DocumentInteroperabilityReviewDialog),
          findsOneWidget,
        );
      },
    );

    testWidgets('fits 320px with large text without layout exceptions', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(320, 700);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await _pumpDialogHarness(
        tester,
        textScaler: const TextScaler.linear(2),
        preview: DocumentInteroperabilityPreview(
          operation: DocumentInteroperabilityOperation.exportDocument,
          fileName: 'a-very-long-document-name-that-must-wrap.jff',
          systemLabel: 'Finite-state automaton',
          formatLabel: 'JFLAP XML',
          schemaVersion: 1,
          fidelity: DocumentFidelity.lossy,
          diagnostics: const [
            CodecDiagnostic(
              code: 'field.dropped',
              message: 'Dropped field',
              path: '/a/very/long/path/to/an/unsupported/field',
              disposition: CodecDiagnosticDisposition.dropped,
            ),
          ],
        ),
      );

      await tester.tap(find.text('Open review'));
      await tester.pumpAndSettle();

      expect(find.text('Export with data loss'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  });

  group('DocumentInteroperabilityFailureDialog', () {
    testWidgets('resolves a registry failure in the current locale', (
      tester,
    ) async {
      final message = StructuredMessage(
        namespace: 'interop.registry',
        code: 'encode-failed',
        category: StructuredMessageCategory.interoperability,
        severity: StructuredMessageSeverity.error,
        arguments: {
          'codec': StructuredMessageArgument.identifier(
            'codec.test',
            role: 'codec',
          ),
        },
      );

      await _pumpFailureHarness(
        tester,
        locale: const Locale('pt'),
        outcome: CodecInternalFailure<void>(
          stage: CodecInternalFailureStage.encode,
          message: message.stableCode,
          structuredMessage: message,
        ),
      );

      expect(
        find.text('O codec codec.test não conseguiu codificar o documento.'),
        findsOneWidget,
      );
      expect(find.text(message.stableCode), findsNothing);
    });

    testWidgets('fits a long roadmap failure at 320px and 2x text', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(320, 700);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await _pumpFailureHarness(
        tester,
        textScaler: const TextScaler.linear(2),
        outcome: const CodecUnsupported<void>(
          reason: CodecUnsupportedReason.feature,
          message: 'A long internal message that must not be shown.',
          roadmapIssue: 325,
        ),
        onOpenRoadmapIssue: (_) {},
      );

      expect(find.text('View roadmap issue #325'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('shows malformed source path and position in Portuguese', (
      tester,
    ) async {
      await _pumpFailureHarness(
        tester,
        locale: const Locale('pt'),
        outcome: const CodecMalformed<void>(
          reason: CodecMalformedReason.invalidValue,
          message: 'Raw parser message',
          location: CodecSourceLocation(
            path: '/payload/transitions/3/read',
            line: 21,
            column: 11,
            offset: 420,
          ),
        ),
      );

      expect(find.text('Não foi possível ler o documento'), findsOneWidget);
      expect(
        find.textContaining('/payload/transitions/3/read'),
        findsOneWidget,
      );
      expect(find.textContaining('Linha 21, coluna 11'), findsOneWidget);
      expect(find.textContaining('Raw parser message'), findsNothing);
    });

    testWidgets('offers an actionable roadmap link only when supplied', (
      tester,
    ) async {
      int? openedIssue;
      await _pumpFailureHarness(
        tester,
        outcome: const CodecUnsupported<void>(
          reason: CodecUnsupportedReason.feature,
          message: 'Building blocks are unsupported.',
          roadmapIssue: 325,
        ),
        onOpenRoadmapIssue: (issue) => openedIssue = issue,
      );

      await tester.tap(find.text('View roadmap issue #325'));
      await tester.pumpAndSettle();
      expect(openedIssue, 325);
      expect(
        find.byType(DocumentInteroperabilityFailureDialog<void>),
        findsNothing,
      );
    });
  });
}

DocumentInteroperabilityPreview _preview({
  DocumentFidelity fidelity = DocumentFidelity.exact,
}) {
  return DocumentInteroperabilityPreview(
    operation: DocumentInteroperabilityOperation.importDocument,
    fileName: 'sample.jff',
    systemLabel: 'Finite-state automaton',
    formatLabel: 'JFLAP XML',
    schemaVersion: 1,
    fidelity: fidelity,
  );
}

Future<void> _pumpDialogHarness(
  WidgetTester tester, {
  required DocumentInteroperabilityPreview preview,
  Locale locale = const Locale('en'),
  TextScaler textScaler = TextScaler.noScaling,
}) async {
  await tester.pumpWidget(
    MaterialApp(
      locale: locale,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      builder: (context, child) => MediaQuery(
        data: MediaQuery.of(context).copyWith(textScaler: textScaler),
        child: child!,
      ),
      home: const _ReviewHarnessPlaceholder(),
      routes: {'/review': (_) => _ReviewHarness(preview: preview)},
      initialRoute: '/review',
    ),
  );
}

Future<void> _pumpFailureHarness<T>(
  WidgetTester tester, {
  required CodecOutcome<T> outcome,
  Locale locale = const Locale('en'),
  TextScaler textScaler = TextScaler.noScaling,
  ValueChanged<int>? onOpenRoadmapIssue,
}) async {
  await tester.pumpWidget(
    MaterialApp(
      locale: locale,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      builder: (context, child) => MediaQuery(
        data: MediaQuery.of(context).copyWith(textScaler: textScaler),
        child: child!,
      ),
      home: Builder(
        builder: (context) => Scaffold(
          body: DocumentInteroperabilityFailureDialog<T>(
            outcome: outcome,
            fileName: 'broken.jff',
            onOpenRoadmapIssue: onOpenRoadmapIssue,
          ),
        ),
      ),
    ),
  );
}

class _ReviewHarnessPlaceholder extends StatelessWidget {
  const _ReviewHarnessPlaceholder();

  @override
  Widget build(BuildContext context) => const SizedBox.shrink();
}

class _ReviewHarness extends StatefulWidget {
  const _ReviewHarness({required this.preview});

  final DocumentInteroperabilityPreview preview;

  @override
  State<_ReviewHarness> createState() => _ReviewHarnessState();
}

class _ReviewHarnessState extends State<_ReviewHarness> {
  bool? _result;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            FilledButton(
              autofocus: true,
              onPressed: () async {
                final result = await showDocumentInteroperabilityReviewDialog(
                  context,
                  preview: widget.preview,
                );
                if (mounted) setState(() => _result = result);
              },
              child: const Text('Open review'),
            ),
            Text('Result: $_result'),
          ],
        ),
      ),
    );
  }
}
