import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:turing_lab/core/models/tm_execution_analysis.dart';
import 'package:turing_lab/core/models/tm_transition.dart';
import 'package:turing_lab/l10n/app_localizations.dart';
import 'package:turing_lab/presentation/widgets/tm/multi_tape_inspector.dart';
import 'package:turing_lab/presentation/widgets/transition_editors/tm_transition_operations_editor.dart';

// feature-localization-contract: advanced-tm-workspaces
// feature-localization-surface: localized-multi-tape-workspace
void main() {
  testWidgets('three-tape editor remains usable at 320 px and 200% text', (
    tester,
  ) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(320, 700);
    addTearDown(tester.view.resetDevicePixelRatio);
    addTearDown(tester.view.resetPhysicalSize);
    List<String>? submittedReads;
    List<String>? submittedWrites;
    List<TapeDirection>? submittedDirections;
    await tester.pumpWidget(
      MaterialApp(
        builder: (context, child) => MediaQuery(
          data: MediaQuery.of(
            context,
          ).copyWith(textScaler: const TextScaler.linear(2)),
          child: child!,
        ),
        home: Scaffold(
          body: Center(
            child: TmTransitionOperationsEditor(
              tapeCount: 3,
              initialReads: const ['a', 'B', 'B'],
              initialWrites: const ['a', 'x', 'B'],
              initialDirections: const [
                TapeDirection.right,
                TapeDirection.left,
                TapeDirection.stay,
              ],
              onSubmitVectors:
                  ({
                    required readSymbols,
                    required writeSymbols,
                    required directions,
                  }) {
                    submittedReads = readSymbols;
                    submittedWrites = writeSymbols;
                    submittedDirections = directions;
                  },
              onCancel: () {},
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byKey(const ValueKey('tm-transition-read-2')), findsOneWidget);
    expect(find.text('tape 3'), findsOneWidget);
    expect(tester.takeException(), isNull);

    await tester.scrollUntilVisible(
      find.text('Save'),
      180,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.tap(find.text('Save'));
    await tester.pumpAndSettle();

    expect(submittedReads, ['a', 'B', 'B']);
    expect(submittedWrites, ['a', 'x', 'B']);
    expect(submittedDirections, [
      TapeDirection.right,
      TapeDirection.left,
      TapeDirection.stay,
    ]);
    expect(tester.takeException(), isNull);
  });

  for (final scenario in const [
    (
      locale: Locale('en'),
      title: 'Synchronized multi-tape trace',
      metrics: 'Multi-tape space metrics',
      tapeSemantic: 'Tape 3, head at 0, operation B → B, S',
      headSummary: 'Head 0 · B → B, S',
    ),
    (
      locale: Locale('pt', 'BR'),
      title: 'Rastro sincronizado de múltiplas fitas',
      metrics: 'Métricas de espaço de múltiplas fitas',
      tapeSemantic: 'Fita 3, cabeça em 0, operação B → B, S',
      headSummary: 'Cabeça 0 · B → B, S',
    ),
  ])
    testWidgets('localizes the multi-tape inspector in '
        '${scenario.locale.languageCode} without changing formal operations', (
      tester,
    ) async {
      tester.view.devicePixelRatio = 1;
      tester.view.physicalSize = const Size(320, 700);
      addTearDown(tester.view.resetDevicePixelRatio);
      addTearDown(tester.view.resetPhysicalSize);
      final semantics = tester.ensureSemantics();

      final configuration = TMConfigurationSnapshot.multi(
        stateId: 'q1',
        headPositions: const [1, -1, 0],
        nonBlankCellsByTape: const [
          {0: 'a'},
          {-1: 'x'},
          <int, String>{},
        ],
      );
      final trace = List<TMMultiTapeTraceStep>.generate(
        100,
        (index) => TMMultiTapeTraceStep(
          step: index + 1,
          fromStateId: 'q0',
          toStateId: 'q1',
          transitionId: 't$index',
          readSymbols: const ['a', 'B', 'B'],
          writeSymbols: const ['a', 'x', 'B'],
          directions: const [
            TapeDirection.right,
            TapeDirection.left,
            TapeDirection.stay,
          ],
          configuration: configuration,
        ),
      );
      final analysis = TMExecutionAnalysis(
        input: 'a',
        outcome: TMExecutionOutcome.accepted,
        message: 'Accepted.',
        stepsExecuted: 100,
        configurationsExplored: 101,
        maxSteps: 100,
        maxConfigurations: 1000,
        timeout: const Duration(seconds: 1),
        executionTime: const Duration(milliseconds: 1),
        multiTapeTrace: trace,
        multiTapeMetrics: TMMultiTapeMetrics(
          maximumVisitedSpanByTape: const [2, 2, 1],
          maximumNonBlankCellsByTape: const [1, 1, 0],
          maximumTotalNonBlankCells: 2,
        ),
      );

      await tester.pumpWidget(
        MaterialApp(
          locale: scenario.locale,
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          builder: (context, child) => MediaQuery(
            data: MediaQuery.of(
              context,
            ).copyWith(textScaler: const TextScaler.linear(2)),
            child: child!,
          ),
          home: Scaffold(
            body: SingleChildScrollView(
              child: TMMultiTapeInspector(analysis: analysis, blankSymbol: 'B'),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('tm-multi-tape-trace-list')), findsOneWidget);
      expect(find.text(scenario.title), findsOneWidget);
      expect(find.bySemanticsLabel(scenario.metrics), findsOneWidget);
      expect(find.textContaining('Step 100:'), findsNothing);
      expect(find.bySemanticsLabel(scenario.tapeSemantic), findsOneWidget);
      expect(find.text(scenario.headSummary), findsOneWidget);
      expect(find.textContaining('B → B, S'), findsWidgets);
      expect(tester.takeException(), isNull);
      semantics.dispose();
    });

  testWidgets('formats large multi-tape trace numbers for PT-BR', (
    tester,
  ) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(320, 700);
    addTearDown(tester.view.resetDevicePixelRatio);
    addTearDown(tester.view.resetPhysicalSize);
    final semantics = tester.ensureSemantics();
    final configuration = TMConfigurationSnapshot.multi(
      stateId: 'q1',
      headPositions: const [1000, -1000],
      nonBlankCellsByTape: const [
        {1000: 'a'},
        {-1000: 'x'},
      ],
    );
    final analysis = TMExecutionAnalysis(
      input: 'a',
      outcome: TMExecutionOutcome.accepted,
      message: 'Accepted.',
      stepsExecuted: 1000,
      configurationsExplored: 1001,
      maxSteps: 2000,
      maxConfigurations: 2000,
      timeout: const Duration(seconds: 1),
      executionTime: const Duration(milliseconds: 1),
      multiTapeTrace: [
        TMMultiTapeTraceStep(
          step: 1000,
          fromStateId: 'q0',
          toStateId: 'q1',
          transitionId: 't0',
          readSymbols: const ['a', 'x'],
          writeSymbols: const ['a', 'x'],
          directions: const [TapeDirection.right, TapeDirection.left],
          configuration: configuration,
        ),
      ],
      multiTapeMetrics: TMMultiTapeMetrics(
        maximumVisitedSpanByTape: const [1234, 1234],
        maximumNonBlankCellsByTape: const [1234, 1234],
        maximumTotalNonBlankCells: 1234,
      ),
    );

    await tester.pumpWidget(
      MaterialApp(
        locale: const Locale('pt', 'BR'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(
          body: SingleChildScrollView(
            child: TMMultiTapeInspector(analysis: analysis, blankSymbol: 'B'),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.textContaining('Passo 1.000:'), findsOneWidget);
    expect(
      find.textContaining(
        'intervalo 1.234, máximo de células não brancas 1.234',
      ),
      findsWidgets,
    );
    expect(
      find.bySemanticsLabel('Fita 1, cabeça em 1.000, operação a → a, R'),
      findsOneWidget,
    );
    expect(find.text('1.000'), findsWidgets);
    expect(tester.takeException(), isNull);
    semantics.dispose();
  });
}
