import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:turing_lab/core/models/tm_execution_analysis.dart';
import 'package:turing_lab/core/models/tm_language_explorer_models.dart';
import 'package:turing_lab/core/models/tm_reachability_report.dart';
import 'package:turing_lab/core/models/tm_space_profile.dart';
import 'package:turing_lab/core/models/tm_time_profile.dart';
import 'package:turing_lab/l10n/app_localizations.dart';
import 'package:turing_lab/presentation/localization/locale_value_formatter.dart';
import 'package:turing_lab/presentation/widgets/tm_language_result_view.dart';
import 'package:turing_lab/presentation/widgets/tm_reachability_result_view.dart';
import 'package:turing_lab/presentation/widgets/tm_space_result_view.dart';
import 'package:turing_lab/presentation/widgets/tm_tape_result_view.dart';
import 'package:turing_lab/presentation/widgets/tm_termination_result_view.dart';
import 'package:turing_lab/presentation/widgets/tm_time_result_view.dart';

void main() {
  test('formats BigInt values beyond native integer range by locale', () {
    const value = '1234567890123456789012345';
    expect(
      LocaleValueFormatter(
        const Locale('en'),
      ).integerBigInt(BigInt.parse(value)),
      '1,234,567,890,123,456,789,012,345',
    );
    expect(
      LocaleValueFormatter(
        const Locale('pt', 'BR'),
      ).integerBigInt(BigInt.parse(value)),
      '1.234.567.890.123.456.789.012.345',
    );
  });

  for (final scenario in const [
    (
      locale: Locale('en'),
      outcome: 'Accepted',
      progress: '12,345 transition(s) • 12,345 configuration(s) explored',
    ),
    (
      locale: Locale('pt', 'BR'),
      outcome: 'Aceita',
      progress: '12.345 transição(ões) • 12.345 configuração(ões) exploradas',
    ),
  ]) {
    testWidgets(
      'localizes language word progress in ${scenario.locale.languageCode}',
      (tester) async {
        final report = TMLanguageExplorerReport(
          limits: const TMLanguageExplorerLimits(),
          alphabet: const ['a'],
          requestedCandidates: BigInt.one,
          plannedCandidates: 1,
          results: [
            TMLanguageWordResult(
              input: 'a',
              outcome: TMLanguageOutcome.accepted,
              analysis: _analysis(),
            ),
          ],
          cancelled: false,
          truncatedByCandidateCap: false,
          executionTime: Duration.zero,
        );
        await _pump(
          tester,
          TMLanguageResultView(
            report: report,
            selectedWord: null,
            selectedTrace: null,
            isLoadingTrace: false,
            onWordSelected: (_) {},
          ),
          scenario.locale,
        );

        expect(
          find.text('${scenario.outcome} • ${scenario.progress}'),
          findsOneWidget,
        );
        if (scenario.locale.languageCode == 'pt') {
          expect(find.textContaining(' steps'), findsNothing);
          expect(find.textContaining(' configurations'), findsNothing);
        }
        expect(tester.takeException(), isNull);
      },
    );
  }

  for (final scenario in const [
    (
      locale: Locale('en'),
      grouped: '12,345',
      duration: '1,234 ms',
      inputLength: 'Input length 12,345',
    ),
    (
      locale: Locale('pt', 'BR'),
      grouped: '12.345',
      duration: '1.234 ms',
      inputLength: 'Comprimento da entrada 12.345',
    ),
  ]) {
    testWidgets(
      'formats TM result counts and durations for ${scenario.locale.languageCode}',
      (tester) async {
        await _pump(
          tester,
          TMLanguageResultView(
            report: _languageReport(),
            selectedWord: null,
            selectedTrace: null,
            isLoadingTrace: false,
            onWordSelected: (_) {},
          ),
          scenario.locale,
        );
        expect(find.text(scenario.duration), findsOneWidget);
        expect(find.text('${scenario.grouped} ms'), findsOneWidget);

        await _pump(
          tester,
          TMTimeResultView(report: _timeReport()),
          scenario.locale,
        );
        expect(find.text(scenario.duration), findsOneWidget);
        expect(find.text('${scenario.grouped} s'), findsOneWidget);
        expect(find.text(scenario.inputLength), findsOneWidget);

        await _pump(
          tester,
          TMSpaceResultView(report: _spaceReport()),
          scenario.locale,
        );
        expect(find.text(scenario.duration), findsOneWidget);
        expect(find.text('${scenario.grouped} ms'), findsOneWidget);

        await _pump(
          tester,
          TMReachabilityResultView(
            report: _reachabilityReport(),
            sourceTm: null,
          ),
          scenario.locale,
        );
        expect(find.text('${scenario.grouped} s'), findsOneWidget);

        await _pump(
          tester,
          TMTerminationResultView(analysis: _analysis()),
          scenario.locale,
        );
        expect(find.text('${scenario.grouped} s'), findsOneWidget);

        await _pump(
          tester,
          TMTapeResultView(analysis: _tapeAnalysis(), sourceTm: null),
          scenario.locale,
        );
        expect(find.text('${scenario.grouped} s'), findsOneWidget);
        expect(find.text(scenario.grouped), findsWidgets);
      },
    );
  }
}

Future<void> _pump(WidgetTester tester, Widget child, Locale locale) async {
  await tester.pumpWidget(
    MaterialApp(
      locale: locale,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: Scaffold(
        body: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: child,
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

TMLanguageExplorerReport _languageReport() => TMLanguageExplorerReport(
  limits: const TMLanguageExplorerLimits(
    maxInputLength: 12345,
    maxCandidates: 12345,
    maxStepsPerInput: 12345,
    maxConfigurationsPerInput: 12345,
    timeoutPerInput: Duration(milliseconds: 12345),
  ),
  alphabet: const ['a'],
  requestedCandidates: BigInt.from(12345),
  plannedCandidates: 12345,
  results: const [],
  cancelled: false,
  truncatedByCandidateCap: false,
  executionTime: const Duration(milliseconds: 1234),
);

TMTimeProfileReport _timeReport() => TMTimeProfileReport(
  kind: TMTimeProfileKind.deterministicTime,
  status: TMTimeProfileStatus.complete,
  message: 'Complete.',
  plan: TMTimeProfilePlan(
    bounds: const TMTimeProfileBounds(
      maxLength: 12345,
      maxStepsPerCandidate: 12345,
      maxConfigurationsPerCandidate: 12345,
      timeoutPerCandidate: Duration(seconds: 12345),
    ),
    alphabet: const ['a'],
    rows: const [],
    plannedCandidateCount: 12345,
  ),
  rows: [
    TMTimeProfileRow(
      inputLength: 12345,
      possibleCandidateCount: BigInt.from(12345),
      candidateCount: 12345,
      evaluatedCandidateCount: 12345,
      completedCount: 12345,
      provenCycleCount: 0,
      unknownCount: 0,
      cancelledCount: 0,
      invalidCount: 0,
      isSampled: false,
      isComplete: true,
    ),
  ],
  profilingWallClockTime: const Duration(milliseconds: 1234),
);

TMSpaceProfileReport _spaceReport() => TMSpaceProfileReport(
  limits: const TMSpaceProfileLimits(
    maxInputLength: 12345,
    maxCandidatesPerLength: 12345,
    maxStepsPerInput: 12345,
    maxConfigurationsPerInput: 12345,
    timeoutPerInput: Duration(milliseconds: 12345),
  ),
  alphabet: const ['a'],
  requestedCandidates: BigInt.from(12345),
  scheduledCandidates: 12345,
  rows: [
    TMSpaceLengthProfile(
      inputLength: 12345,
      requestedCandidates: BigInt.from(12345),
      scheduledCandidates: 12345,
      enumerationMode: TMSpaceEnumerationMode.exhaustive,
      inputs: const [],
      cancelled: false,
    ),
  ],
  cancelled: false,
  isNondeterministic: false,
  executionTime: const Duration(milliseconds: 1234),
);

TMReachabilityReport _reachabilityReport() => TMReachabilityReport(
  inputs: const [''],
  status: TMReachabilityStatus.complete,
  message: 'Complete.',
  structurallyReachableStateIds: const {},
  structurallyUnreachableStateIds: const {},
  witnessesByStateId: const {},
  configurationsExplored: 12345,
  transitionsExplored: 12345,
  maxSteps: 12345,
  maxConfigurations: 12345,
  timeout: const Duration(seconds: 12345),
  executionTime: const Duration(milliseconds: 1234),
);

TMExecutionAnalysis _analysis() => TMExecutionAnalysis(
  input: 'a',
  outcome: TMExecutionOutcome.accepted,
  message: 'Accepted.',
  stepsExecuted: 12345,
  configurationsExplored: 12345,
  maxSteps: 12345,
  maxConfigurations: 12345,
  timeout: const Duration(seconds: 12345),
  executionTime: const Duration(milliseconds: 1234),
);

TMExecutionAnalysis _tapeAnalysis() => TMExecutionAnalysis(
  input: 'a',
  outcome: TMExecutionOutcome.accepted,
  message: 'Accepted.',
  stepsExecuted: 12345,
  configurationsExplored: 12345,
  maxSteps: 12345,
  maxConfigurations: 12345,
  timeout: const Duration(seconds: 12345),
  executionTime: const Duration(milliseconds: 1234),
  traceMetrics: TMTraceMetrics(
    branchSelection: TMExecutionBranchSelection.deterministic,
    readCounts: const {},
    writeCountsByOldSymbol: const {},
    writeCountsByNewSymbol: const {},
    changedWrites: 12345,
    movementCounts: const {},
    headReversals: 12345,
    minimumHeadPosition: 0,
    maximumHeadPosition: 12345,
    visitedCells: const {0},
    maximumSimultaneousNonBlankCells: 12345,
    transitionExecutionCounts: const {},
    cellTouchRanges: const {},
    tapeDiff: const {},
    definedButNotExecutedTransitionIds: const {},
    retainedTraceSnapshots: 12345,
  ),
);
