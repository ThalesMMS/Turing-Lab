import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:turing_lab/core/batch_execution/batch_execution.dart';
import 'package:turing_lab/core/messages/structured_message.dart';
import 'package:turing_lab/l10n/app_localizations.dart';
import 'package:turing_lab/presentation/widgets/batch_execution/batch_execution_panel.dart';
import 'package:turing_lab/presentation/widgets/batch_execution/batch_file_service.dart';

// feature-localization-contract: grammar-analysis-parsing-and-teaching
// feature-localization-surface: localized-editor-fields
// feature-localization-surface: responsive-accessibility
// feature-localization-surface: localized-export-picker-titles
void main() {
  testWidgets('localizes batch controls in Portuguese at phone width', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(320, 700));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await _pumpPanel(
      tester,
      executor: _TestExecutor(),
      locale: const Locale('pt'),
      textScaler: const TextScaler.linear(2),
    );

    expect(find.text('Execução em lote'), findsOneWidget);
    expect(find.text('Entradas, um caso por linha'), findsOneWidget);
    expect(
      find.text('Use ε para a palavra vazia. O espaço em branco é preservado.'),
      findsOneWidget,
    );
    expect(find.text('Adicionar caso'), findsOneWidget);
    expect(find.text('Importar TXT/CSV'), findsOneWidget);
    expect(find.text('Comprimento máximo'), findsOneWidget);
    expect(find.text('Máximo de casos'), findsOneWidget);
    expect(find.text('Gerar palavras'), findsOneWidget);
    expect(find.text('Executar lote'), findsOneWidget);
    expect(find.text('Exportar JSON'), findsOneWidget);
    expect(find.text('Exportar CSV'), findsOneWidget);
    expect(find.text('Batch execution'), findsNothing);
    expect(find.text('Generate words'), findsNothing);

    final configuration = find.byKey(const Key('batch-configuration'));
    await tester.ensureVisible(configuration);
    await tester.tap(configuration);
    await tester.pumpAndSettle();
    expect(find.text('Limites e configurações de execução'), findsOneWidget);
    expect(find.text('Estratégia'), findsOneWidget);
    expect(find.text('Tokenização'), findsOneWidget);
    expect(find.text('Reter traços'), findsOneWidget);
    expect(find.text('Concorrência'), findsOneWidget);
    expect(
      find.text('Parar após o primeiro resultado não bem-sucedido'),
      findsOneWidget,
    );
    expect(find.text('Símbolos Unicode'), findsOneWidget);
    expect(find.text('Sem traços'), findsOneWidget);

    await tester.enterText(find.byKey(const Key('batch-inputs')), 'a');
    final run = find.byKey(const Key('batch-run'));
    await tester.ensureVisible(run);
    await tester.tap(run);
    await tester.pumpAndSettle();
    expect(find.text('1 de 1 casos concluídos'), findsOneWidget);
    expect(find.textContaining('Saída: output:a'), findsOneWidget);
    expect(find.textContaining('Batch complete'), findsNothing);
  });

  testWidgets('localizes the keyboard shortcut icon semantics', (tester) async {
    final semantics = tester.ensureSemantics();

    await _pumpPanel(
      tester,
      executor: _TestExecutor(),
      locale: const Locale('pt'),
    );

    expect(
      tester.getSemantics(find.byIcon(Icons.keyboard)).label,
      contains('Atalhos de teclado'),
    );
    expect(
      tester.getSemantics(find.byIcon(Icons.keyboard)).label,
      isNot(contains('Keyboard shortcuts')),
    );
    expect(
      find.byTooltip('Executar: Ctrl+Enter. Cancelar: Escape.'),
      findsOneWidget,
    );
    semantics.dispose();
  });

  testWidgets(
    'formats multiple-run progress counts in English and Portuguese',
    (tester) async {
      final semantics = tester.ensureSemantics();
      final panelKey = GlobalKey();
      final inputs = List<String>.filled(1234, 'a').join('\n');

      await _pumpPanel(
        tester,
        panelKey: panelKey,
        executor: _TestExecutor(),
        locale: const Locale('en'),
      );
      await tester.enterText(find.byKey(const Key('batch-inputs')), inputs);
      await tester.tap(find.byKey(const Key('batch-run')));
      await tester.pumpAndSettle();
      final englishProgress = find.text('1,234 of 1,234 cases complete');
      expect(englishProgress, findsOneWidget);
      expect(find.textContaining('output: 1,234'), findsOneWidget);
      final englishSemantics = tester.getSemantics(englishProgress);
      expect(
        englishSemantics.label,
        contains('Batch progress: 1,234 of 1,234 cases complete'),
      );
      expect(
        englishSemantics.getSemanticsData().flagsCollection.isLiveRegion,
        isTrue,
      );

      await _pumpPanel(
        tester,
        panelKey: panelKey,
        executor: _TestExecutor(),
        locale: const Locale('pt'),
      );
      await tester.pump();
      final portugueseProgress = find.text('1.234 de 1.234 casos concluídos');
      expect(portugueseProgress, findsOneWidget);
      expect(find.textContaining('Saída: 1.234'), findsOneWidget);
      final portugueseSemantics = tester.getSemantics(portugueseProgress);
      expect(
        portugueseSemantics.label,
        contains('Progresso do lote: 1.234 de 1.234 casos concluídos'),
      );
      expect(
        portugueseSemantics.getSemanticsData().flagsCollection.isLiveRegion,
        isTrue,
      );
      semantics.dispose();
    },
  );

  testWidgets('formats transient batch limits in Portuguese', (tester) async {
    await _pumpPanel(
      tester,
      executor: _TestExecutor(),
      alphabet: const {'a'},
      locale: const Locale('pt', 'BR'),
    );
    await tester.enterText(find.byKey(const Key('batch-max-count')), '10001');
    await tester.tap(find.byKey(const Key('batch-generate')));
    await tester.pump();

    expect(
      find.text('A quantidade de casos gerados não pode exceder 10.000.'),
      findsOneWidget,
    );
    expect(find.textContaining('10000'), findsNothing);
  });

  testWidgets('validates an empty batch and executes epsilon and duplicates', (
    tester,
  ) async {
    await _pumpPanel(tester, executor: _TestExecutor());

    await tester.tap(find.byKey(const Key('batch-run')));
    await tester.pump();
    expect(
      find.text('Add at least one case. Use ε for the empty word.'),
      findsOneWidget,
    );

    await tester.enterText(find.byKey(const Key('batch-inputs')), 'ε\na\na');
    await tester.tap(find.byKey(const Key('batch-run')));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('batch-result-line-000001')), findsOneWidget);
    expect(find.byKey(const Key('batch-result-line-000002')), findsOneWidget);
    expect(find.byKey(const Key('batch-result-line-000003')), findsOneWidget);
    expect(find.textContaining('output: 3'), findsOneWidget);

    await tester.tap(find.byTooltip('Remove this case').first);
    await tester.pump();
    expect(find.textContaining('Removed case'), findsOneWidget);
    await tester.tap(find.byKey(const Key('batch-add-case')));
    await tester.pump();
    expect(find.text('Added an empty-word case.'), findsOneWidget);
  });

  testWidgets('imports CSV IDs and exports stable JSON and CSV reports', (
    tester,
  ) async {
    final files = _TestFileService(
      selection: BatchInputFileSelection(
        filename: 'cases.csv',
        bytes: Uint8List.fromList('id,input\nempty,\nquoted,"a,b"\n'.codeUnits),
      ),
    );
    await _pumpPanel(tester, executor: _TestExecutor(), fileService: files);

    await tester.tap(find.byKey(const Key('batch-import')));
    await tester.pumpAndSettle();
    expect(find.textContaining('Imported 2 cases'), findsOneWidget);

    await tester.tap(find.byKey(const Key('batch-run')));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('batch-result-empty')), findsOneWidget);
    expect(find.byKey(const Key('batch-result-quoted')), findsOneWidget);

    await tester.tap(find.byKey(const Key('batch-export-json')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('batch-export-csv')));
    await tester.pumpAndSettle();

    expect(files.saved, hasLength(2));
    expect(files.importDialogTitle, 'Import TXT/CSV');
    expect(files.saved[0].dialogTitle, 'Export JSON');
    expect(files.saved[1].dialogTitle, 'Export CSV');
    expect(files.saved[0].contents, contains('"modelRevision": "revision-1"'));
    expect(files.saved[0].contents, contains('"id": "empty"'));
    expect(files.saved[1].contents, contains(',none,empty,,output'));
    expect(files.saved[1].contents, contains(',none,quoted,"a,b",output'));
  });

  testWidgets('passes localized import and export titles to the file service', (
    tester,
  ) async {
    final files = _TestFileService(
      selection: BatchInputFileSelection(
        filename: 'cases.txt',
        bytes: Uint8List.fromList('a\n'.codeUnits),
      ),
    );
    await _pumpPanel(
      tester,
      executor: _TestExecutor(),
      fileService: files,
      locale: const Locale('pt'),
    );

    await tester.tap(find.byKey(const Key('batch-import')));
    await tester.pumpAndSettle();
    expect(files.importDialogTitle, 'Importar TXT/CSV');

    await tester.tap(find.byKey(const Key('batch-run')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('batch-export-json')));
    await tester.pumpAndSettle();

    expect(files.saved, hasLength(1));
    expect(files.saved.single.dialogTitle, 'Exportar JSON');
  });

  testWidgets('generates bounded words and filters virtualized results', (
    tester,
  ) async {
    await _pumpPanel(
      tester,
      executor: _TestExecutor(),
      alphabet: const {'a', 'b'},
    );

    await tester.tap(find.byKey(const Key('batch-generate')));
    await tester.pump();
    expect(find.text('Generated 31 ordered cases.'), findsOneWidget);

    await tester.tap(find.byKey(const Key('batch-run')));
    await tester.pumpAndSettle();
    expect(find.textContaining('output: 31'), findsOneWidget);

    await tester.enterText(find.byKey(const Key('batch-filter')), 'bbbb');
    await tester.pump();
    expect(
      find.byKey(const Key('batch-result-generated-000031')),
      findsOneWidget,
    );
    expect(
      find.byKey(const Key('batch-result-generated-000001')),
      findsNothing,
    );
  });

  testWidgets('filters localized outcomes and diagnostics in Portuguese', (
    tester,
  ) async {
    await _pumpPanel(
      tester,
      executor: _TestExecutor(
        structuredMessage: StructuredMessage(
          namespace: 'batch.execution',
          code: 'scalar-tokenization-required',
          category: StructuredMessageCategory.simulation,
          severity: StructuredMessageSeverity.error,
        ),
      ),
      locale: const Locale('pt'),
    );
    await tester.enterText(find.byKey(const Key('batch-inputs')), 'a');
    await tester.tap(find.byKey(const Key('batch-run')));
    await tester.pumpAndSettle();

    const result = Key('batch-result-line-000001');
    await tester.enterText(find.byKey(const Key('batch-filter')), 'Saída');
    await tester.pump();
    expect(find.byKey(result), findsOneWidget);

    await tester.enterText(
      find.byKey(const Key('batch-filter')),
      'Este simulador canônico',
    );
    await tester.pump();
    expect(find.byKey(result), findsOneWidget);
  });

  testWidgets('virtualizes a large generated batch under its explicit cap', (
    tester,
  ) async {
    await _pumpPanel(
      tester,
      executor: _TestExecutor(),
      alphabet: const {'a', 'b'},
    );
    await tester.enterText(find.byKey(const Key('batch-max-length')), '9');
    await tester.enterText(find.byKey(const Key('batch-max-count')), '512');
    await tester.tap(find.byKey(const Key('batch-generate')));
    await tester.pump();
    expect(find.text('Generated 512 ordered cases.'), findsOneWidget);

    await tester.tap(find.byKey(const Key('batch-run')));
    await tester.pumpAndSettle();
    expect(find.textContaining('output: 512'), findsOneWidget);
    expect(
      find
          .descendant(
            of: find.byKey(const Key('batch-results')),
            matching: find.byType(ListTile),
          )
          .evaluate()
          .length,
      lessThan(50),
    );
  });

  testWidgets('supports keyboard execution at phone width and 2x text scale', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(320, 640));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await _pumpPanel(
      tester,
      executor: _TestExecutor(),
      textScaler: const TextScaler.linear(2),
    );
    await tester.enterText(find.byKey(const Key('batch-inputs')), '😀');
    await tester.sendKeyDownEvent(LogicalKeyboardKey.controlLeft);
    await tester.sendKeyEvent(LogicalKeyboardKey.enter);
    await tester.sendKeyUpEvent(LogicalKeyboardKey.controlLeft);
    await tester.pumpAndSettle();

    expect(find.textContaining('output: 1'), findsOneWidget);
  });

  testWidgets('passes space-separated multi-character tokens explicitly', (
    tester,
  ) async {
    await _pumpPanel(tester, executor: _TestExecutor());
    await tester.tap(find.byKey(const Key('batch-configuration')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('batch-tokenization')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Explicit tokens').last);
    await tester.pumpAndSettle();

    await tester.enterText(
      find.byKey(const Key('batch-inputs')),
      'first second',
    );
    await tester.tap(find.byKey(const Key('batch-run')));
    await tester.pumpAndSettle();

    expect(find.textContaining('Output: output:first|second'), findsOneWidget);
  });

  testWidgets('cancels in-flight cases and clears stale model results', (
    tester,
  ) async {
    const panelKey = Key('panel');
    await _pumpPanel(
      tester,
      panelKey: panelKey,
      executor: _TestExecutor(delay: const Duration(milliseconds: 60)),
    );
    await tester.enterText(find.byKey(const Key('batch-inputs')), 'a\nb\nc\nd');
    await tester.tap(find.byKey(const Key('batch-run')));
    await tester.pump(const Duration(milliseconds: 10));
    expect(find.text('Cancel batch'), findsOneWidget);
    await tester.tap(find.byKey(const Key('batch-run')));
    await tester.pumpAndSettle();
    expect(find.textContaining('Batch cancelled'), findsOneWidget);
    expect(find.textContaining('cancelled:'), findsOneWidget);

    await _pumpPanel(
      tester,
      panelKey: panelKey,
      executor: _TestExecutor(revision: 'revision-2'),
    );
    expect(
      find.text('Results cleared because the model changed.'),
      findsOneWidget,
    );
    expect(find.byKey(const Key('batch-results')), findsNothing);
  });

  testWidgets('reruns a row with trace and compares only finite evidence', (
    tester,
  ) async {
    await _pumpPanel(
      tester,
      executor: _TestExecutor(),
      comparisonExecutor: _TestExecutor(
        modelId: 'comparison-model',
        outputPrefix: 'different',
      ),
    );
    await tester.enterText(find.byKey(const Key('batch-inputs')), 'a');
    await tester.tap(find.byKey(const Key('batch-run')));
    await tester.pumpAndSettle();

    await tester.tap(find.byTooltip('Rerun with trace'));
    await tester.pumpAndSettle();
    expect(find.text('Trace · line-000001'), findsOneWidget);
    expect(find.textContaining('"input": "a"'), findsOneWidget);
    await tester.tap(find.text('Close'));
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('batch-compare')));
    await tester.pumpAndSettle();
    expect(
      find.text('1 differences found in these finite cases.'),
      findsOneWidget,
    );
    expect(
      find.textContaining('does not prove general equivalence'),
      findsOneWidget,
    );
  });

  testWidgets(
    'resolves structured result messages after a runtime locale switch',
    (tester) async {
      final key = GlobalKey();
      final executor = _TestExecutor(
        structuredMessage: StructuredMessage(
          namespace: 'batch.execution',
          code: 'scalar-tokenization-required',
          category: StructuredMessageCategory.simulation,
          severity: StructuredMessageSeverity.error,
        ),
      );
      await _pumpPanel(
        tester,
        panelKey: key,
        executor: executor,
        locale: const Locale('pt'),
      );
      await tester.enterText(find.byKey(const Key('batch-inputs')), 'a');
      await tester.tap(find.byKey(const Key('batch-run')));
      await tester.pumpAndSettle();
      expect(
        find.textContaining('Este simulador canônico exige tokens escalares'),
        findsOneWidget,
      );

      await _pumpPanel(
        tester,
        panelKey: key,
        executor: executor,
        locale: const Locale('en'),
      );
      await tester.pump();
      expect(
        find.textContaining('This canonical simulator requires Unicode-scalar'),
        findsOneWidget,
      );
    },
  );

  testWidgets('re-resolves validation messages after a runtime locale switch', (
    tester,
  ) async {
    final key = GlobalKey();
    final executor = _TestExecutor(modelId: '');
    await _pumpPanel(
      tester,
      panelKey: key,
      executor: executor,
      locale: const Locale('en'),
    );
    await tester.enterText(find.byKey(const Key('batch-inputs')), 'a');
    await tester.tap(find.byKey(const Key('batch-run')));
    await tester.pump();
    expect(find.text('Model ID must be non-empty.'), findsOneWidget);

    await _pumpPanel(
      tester,
      panelKey: key,
      executor: executor,
      locale: const Locale('pt'),
    );
    await tester.pump();
    expect(find.text('ID do modelo não pode estar vazio.'), findsOneWidget);
    expect(find.text('Model ID must be non-empty.'), findsNothing);
  });

  testWidgets('re-resolves import failures after a runtime locale switch', (
    tester,
  ) async {
    final key = GlobalKey();
    final files = _TestFileService(
      selection: BatchInputFileSelection(
        filename: 'cases.csv',
        bytes: Uint8List.fromList('id,input\nsame,a\nsame,b\n'.codeUnits),
      ),
    );
    await _pumpPanel(
      tester,
      panelKey: key,
      executor: _TestExecutor(),
      fileService: files,
      locale: const Locale('en'),
    );
    await tester.tap(find.byKey(const Key('batch-import')));
    await tester.pump();
    expect(find.text('CSV contains duplicate case ID same.'), findsOneWidget);

    await _pumpPanel(
      tester,
      panelKey: key,
      executor: _TestExecutor(),
      fileService: files,
      locale: const Locale('pt'),
    );
    await tester.pump();
    expect(
      find.text('O CSV contém o ID de caso duplicado same.'),
      findsOneWidget,
    );
    expect(find.text('CSV contains duplicate case ID same.'), findsNothing);
  });
}

Future<void> _pumpPanel(
  WidgetTester tester, {
  required BatchCaseExecutor executor,
  Key? panelKey,
  Set<String> alphabet = const {},
  BatchCaseExecutor? comparisonExecutor,
  BatchFileService? fileService,
  TextScaler textScaler = TextScaler.noScaling,
  Locale locale = const Locale('en'),
}) {
  return tester.pumpWidget(
    MaterialApp(
      locale: locale,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: Scaffold(
        body: MediaQuery(
          data: MediaQueryData(textScaler: textScaler),
          child: SingleChildScrollView(
            child: BatchExecutionPanel(
              key: panelKey,
              executor: executor,
              alphabet: alphabet,
              comparisonExecutor: comparisonExecutor,
              fileService: fileService,
            ),
          ),
        ),
      ),
    ),
  );
}

final class _TestExecutor implements BatchCaseExecutor {
  _TestExecutor({
    this.modelId = 'test-model',
    this.revision = 'revision-1',
    this.outputPrefix = 'output',
    this.delay = Duration.zero,
    this.structuredMessage,
  });

  @override
  final String modelId;
  final String revision;
  final String outputPrefix;
  final Duration delay;
  final StructuredMessage? structuredMessage;

  @override
  String get modelRevision => revision;

  @override
  Set<String> get strategyIds => const {'canonical'};

  @override
  Future<BatchCaseExecution> execute(
    BatchInputCase inputCase, {
    required String strategyId,
    required BatchTokenizationMode tokenizationMode,
    required BatchExecutionLimits limits,
    required bool retainTrace,
    required BatchCancellationToken cancellationToken,
  }) async {
    if (delay > Duration.zero) await Future<void>.delayed(delay);
    if (cancellationToken.isCancelled) {
      return BatchCaseExecution(outcome: BatchOutcomeCode.cancelled);
    }
    final renderedInput = inputCase.tokens?.join('|') ?? inputCase.input;
    return BatchCaseExecution(
      outcome: BatchOutcomeCode.output,
      structuredMessage: structuredMessage,
      output: ['$outputPrefix:$renderedInput'],
      metrics: const {'steps': 1, 'configurations': 1},
      trace: retainTrace
          ? [
              {'input': inputCase.input},
            ]
          : const [],
    );
  }
}

final class _SavedReport {
  const _SavedReport(this.filename, this.contents, this.dialogTitle);

  final String filename;
  final String contents;
  final String dialogTitle;
}

final class _TestFileService implements BatchFileService {
  _TestFileService({this.selection});

  final BatchInputFileSelection? selection;
  final List<_SavedReport> saved = [];
  String? importDialogTitle;

  @override
  Future<BatchInputFileSelection?> pickInputs({
    required String dialogTitle,
  }) async {
    importDialogTitle = dialogTitle;
    return selection;
  }

  @override
  Future<String?> saveReport({
    required String filename,
    required String contents,
    required String dialogTitle,
  }) async {
    saved.add(_SavedReport(filename, contents, dialogTitle));
    return filename;
  }
}
