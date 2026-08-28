import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:turing_lab/core/models/tm.dart';
import 'package:turing_lab/core/models/tm_execution_analysis.dart';
import 'package:turing_lab/l10n/app_localizations.dart';
import 'package:turing_lab/presentation/widgets/tm_tape_result_view.dart';

void main() {
  for (final scenario in const [
    (
      locale: Locale('en'),
      branchLabel: 'Selected branch',
      branchValue: 'Deterministic execution',
      movements: 'Head movements',
      declaredAlphabet: 'Declared tape alphabet',
      unexecuted: 'Defined but not executed transitions',
      conclusionLabel: 'Conclusion',
      conclusionValue: 'Bounded',
      limitLabel: 'Limit reached',
      limitValue: 'Configuration limit',
    ),
    (
      locale: Locale('pt', 'BR'),
      branchLabel: 'Ramo selecionado',
      branchValue: 'Execução determinística',
      movements: 'Movimentos do cabeçote',
      declaredAlphabet: 'Alfabeto declarado da fita',
      unexecuted: 'Transições definidas mas não executadas',
      conclusionLabel: 'Conclusão',
      conclusionValue: 'Limitado',
      limitLabel: 'Limite atingido',
      limitValue: 'Limite de configurações',
    ),
  ]) {
    testWidgets(
      'localizes tape analysis labels in ${scenario.locale.languageCode} '
      'without translating formal symbols',
      (tester) async {
        tester.view
          ..physicalSize = const Size(900, 2000)
          ..devicePixelRatio = 1;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);
        final semantics = tester.ensureSemantics();

        await tester.pumpWidget(
          MaterialApp(
            locale: scenario.locale,
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            home: Scaffold(
              body: SingleChildScrollView(
                child: TMTapeResultView(
                  analysis: _analysis(),
                  sourceTm: TM.empty(
                    id: 'formal-tm',
                    name: 'M_α',
                    tapeAlphabet: {'a', 'B'},
                  ),
                ),
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();

        expect(find.text(scenario.branchLabel), findsOneWidget);
        expect(find.text(scenario.branchValue), findsOneWidget);
        expect(find.text(scenario.movements), findsOneWidget);
        expect(find.text(scenario.declaredAlphabet), findsOneWidget);
        expect(find.text(scenario.unexecuted), findsOneWidget);
        expect(find.text(scenario.conclusionLabel), findsOneWidget);
        expect(find.text(scenario.conclusionValue), findsOneWidget);
        expect(find.text(scenario.limitLabel), findsOneWidget);
        expect(find.text(scenario.limitValue), findsWidgets);
        expect(
          find.bySemanticsLabel(
            '${scenario.branchLabel}: ${scenario.branchValue}',
          ),
          findsOneWidget,
        );
        expect(find.text('a: 2'), findsWidgets);
        expect(find.textContaining('q,0 → q1'), findsOneWidget);
        expect(find.text('t,1'), findsOneWidget);
        if (scenario.locale.languageCode == 'pt') {
          expect(find.text('Head movements'), findsNothing);
        }
        expect(tester.takeException(), isNull);
        semantics.dispose();
      },
    );
  }
}

TMExecutionAnalysis _analysis() => TMExecutionAnalysis(
  input: 'a',
  outcome: TMExecutionOutcome.boundedUnknown,
  message: 'Bounded.',
  stepsExecuted: 2,
  configurationsExplored: 3,
  maxSteps: 10,
  maxConfigurations: 20,
  timeout: const Duration(seconds: 1),
  executionTime: const Duration(milliseconds: 3),
  limit: TMExecutionLimit.configurations,
  traceMetrics: TMTraceMetrics(
    branchSelection: TMExecutionBranchSelection.deterministic,
    readCounts: const {'a': 2},
    writeCountsByOldSymbol: const {'a': 1},
    writeCountsByNewSymbol: const {'B': 1},
    changedWrites: 1,
    movementCounts: const {'R': 2},
    headReversals: 0,
    minimumHeadPosition: 0,
    maximumHeadPosition: 1,
    visitedCells: const {0, 1},
    maximumSimultaneousNonBlankCells: 1,
    transitionExecutionCounts: const {'t,0': 2},
    cellTouchRanges: const {0: TMTapeCellTouchRange(firstStep: 0, lastStep: 2)},
    tapeDiff: const {
      0: TMTapeCellChange(position: 0, initialSymbol: 'q,0', finalSymbol: 'q1'),
    },
    definedButNotExecutedTransitionIds: const {'t,1'},
    retainedTraceSnapshots: 0,
  ),
);
