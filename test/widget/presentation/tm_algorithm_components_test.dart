import 'dart:math' show Rectangle;

import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vector_math/vector_math_64.dart';
import 'package:turing_lab/core/models/state.dart' as automaton_state;
import 'package:turing_lab/core/models/tm.dart';
import 'package:turing_lab/core/models/tm_execution_analysis.dart';
import 'package:turing_lab/core/models/tm_language_explorer_models.dart';
import 'package:turing_lab/core/models/tm_reachability_report.dart';
import 'package:turing_lab/core/models/tm_space_profile.dart';
import 'package:turing_lab/core/models/tm_time_profile.dart';
import 'package:turing_lab/l10n/app_localizations.dart';
import 'package:turing_lab/presentation/widgets/tm_algorithm_execution_controller.dart';
import 'package:turing_lab/presentation/widgets/tm_algorithm_execution_controls.dart';
import 'package:turing_lab/presentation/widgets/tm_algorithm_inputs.dart';
import 'package:turing_lab/presentation/widgets/tm_algorithm_language_controls.dart';
import 'package:turing_lab/presentation/widgets/tm_algorithm_presentation_primitives.dart';
import 'package:turing_lab/presentation/widgets/tm_algorithm_reachability_controls.dart';
import 'package:turing_lab/presentation/widgets/tm_algorithm_space_controls.dart';
import 'package:turing_lab/presentation/widgets/tm_algorithm_state_selector.dart';
import 'package:turing_lab/presentation/widgets/tm_algorithm_time_controls.dart';
import 'package:turing_lab/presentation/widgets/tm_language_result_view.dart';
import 'package:turing_lab/presentation/widgets/tm_reachability_result_view.dart';
import 'package:turing_lab/presentation/widgets/tm_space_result_view.dart';
import 'package:turing_lab/presentation/widgets/tm_tape_result_view.dart';
import 'package:turing_lab/presentation/widgets/tm_termination_result_view.dart';
import 'package:turing_lab/presentation/widgets/tm_time_result_view.dart';

void main() {
  testWidgets('all focused control families instantiate independently', (
    tester,
  ) async {
    final inputs = TMAlgorithmInputs();
    addTearDown(inputs.dispose);
    final tm = TM.empty(id: 'controls', name: 'Controls');
    await _pump(
      tester,
      ListView(
        children: [
          TMTerminationControls(
            inputs: inputs,
            state: const TMAlgorithmAnalysisState(),
          ),
          TMReachabilityControls(
            inputs: inputs,
            state: const TMAlgorithmAnalysisState(),
          ),
          TMTimeProfilerControls(
            tm: tm,
            inputs: inputs,
            state: const TMAlgorithmAnalysisState(),
            onInputsChanged: () {},
          ),
          TMLanguageExplorerControls(
            tm: tm,
            inputs: inputs,
            state: const TMAlgorithmAnalysisState(),
            onInputsChanged: () {},
          ),
          TMSpaceProfilerControls(
            tm: tm,
            inputs: inputs,
            state: const TMAlgorithmAnalysisState(),
            onInputsChanged: () {},
          ),
        ],
      ),
    );

    expect(find.byKey(const Key('tm-termination-input')), findsOneWidget);
    expect(find.byKey(const Key('tm-reachability-inputs')), findsOneWidget);
    expect(find.byKey(const Key('tm-time-profile-max-length')), findsOneWidget);
    expect(find.byKey(const Key('tm-language-max-length')), findsOneWidget);
    expect(find.byKey(const Key('tm-space-max-length')), findsOneWidget);
  });

  testWidgets('major controls expose Portuguese semantic names', (
    tester,
  ) async {
    final inputs = TMAlgorithmInputs();
    addTearDown(inputs.dispose);
    final tm = TM.empty(id: 'pt-controls', name: 'Controles');
    await _pump(
      tester,
      ListView(
        children: [
          TMTerminationControls(
            inputs: inputs,
            state: const TMAlgorithmAnalysisState(),
          ),
          TMReachabilityControls(
            inputs: inputs,
            state: const TMAlgorithmAnalysisState(),
          ),
          TMTimeProfilerControls(
            tm: tm,
            inputs: inputs,
            state: const TMAlgorithmAnalysisState(),
            onInputsChanged: () {},
          ),
          TMLanguageExplorerControls(
            tm: tm,
            inputs: inputs,
            state: const TMAlgorithmAnalysisState(),
            onInputsChanged: () {},
          ),
          TMSpaceProfilerControls(
            tm: tm,
            inputs: inputs,
            state: const TMAlgorithmAnalysisState(),
            onInputsChanged: () {},
          ),
        ],
      ),
      locale: const Locale('pt'),
    );

    expect(
      tester.getSemantics(find.byType(TMTerminationControls)).label,
      contains('Controles de análise de término e fita'),
    );
    expect(
      tester.getSemantics(find.byType(TMReachabilityControls)).label,
      contains('Controles de análise de alcançabilidade'),
    );
    expect(
      tester.getSemantics(find.byType(TMTimeProfilerControls)).label,
      contains('Controles do perfil de tempo'),
    );
    expect(
      tester.getSemantics(find.byType(TMLanguageExplorerControls)).label,
      contains('Limites do explorador de linguagem'),
    );
    expect(
      tester.getSemantics(find.byType(TMSpaceProfilerControls)).label,
      contains('Limites do perfil de espaço'),
    );
  });

  testWidgets('progress rebuilds only its selected regions', (tester) async {
    final controller = TMAlgorithmExecutionController(
      initialTm: TM.empty(id: 'selectors', name: 'Selectors'),
      highlights: null,
    );
    addTearDown(controller.dispose);
    final termination = TMAlgorithmStateSelector<Object>(
      controller: controller,
      select: (state) => (
        state.isAnalyzing,
        state.currentFocus,
        state.termination.progress,
      ),
    );
    final reachability = TMAlgorithmStateSelector<Object>(
      controller: controller,
      select: (state) => (
        state.isAnalyzing,
        state.currentFocus,
        state.reachability.progress,
      ),
    );
    final buttons = TMAlgorithmStateSelector<Object>(
      controller: controller,
      select: (state) => (
        state.isAnalyzing,
        state.currentFocus,
        state.termination.progress,
        state.reachability.progress,
      ),
    );
    final results = TMAlgorithmStateSelector<Object>(
      controller: controller,
      select: (state) => (
        state.currentFocus,
        state.termination.report,
        state.reachability.report,
      ),
    );
    addTearDown(termination.dispose);
    addTearDown(reachability.dispose);
    addTearDown(buttons.dispose);
    addTearDown(results.dispose);
    var stableBuilds = 0;
    var terminationBuilds = 0;
    var reachabilityBuilds = 0;
    var buttonBuilds = 0;
    var resultBuilds = 0;

    await _pump(
      tester,
      Column(
        children: [
          Builder(builder: (_) {
            stableBuilds++;
            return const SizedBox();
          }),
          _counted(termination, () => terminationBuilds++),
          _counted(reachability, () => reachabilityBuilds++),
          _counted(buttons, () => buttonBuilds++),
          _counted(results, () => resultBuilds++),
        ],
      ),
    );
    final request = controller.begin(TMAnalysisFocus.termination);
    await tester.pump();
    final beforeProgress = (
      stableBuilds,
      terminationBuilds,
      reachabilityBuilds,
      buttonBuilds,
      resultBuilds,
    );

    controller.updateOperationProgress(request, 'one batch');
    await tester.pump();

    expect(stableBuilds, beforeProgress.$1);
    expect(terminationBuilds, beforeProgress.$2 + 1);
    expect(reachabilityBuilds, beforeProgress.$3);
    expect(buttonBuilds, beforeProgress.$4 + 1);
    expect(resultBuilds, beforeProgress.$5);
  });

  testWidgets(
      'cosmetic source refresh rebuilds results without rebuilding controls',
      (tester) async {
    final originalState = automaton_state.State(
      id: 'q0',
      label: 'Old label',
      position: Vector2.zero(),
      isInitial: true,
      isAccepting: true,
    );
    final original = _singleStateTm(originalState, name: 'Original');
    final controller = TMAlgorithmExecutionController(
      initialTm: original,
      highlights: null,
    );
    addTearDown(controller.dispose);

    final reachabilityRequest = controller.begin(TMAnalysisFocus.reachability);
    controller.completeReachability(
      reachabilityRequest,
      _reachabilityReport(),
    );
    final tapeRequest = controller.begin(TMAnalysisFocus.tape);
    controller.completeTape(tapeRequest, _tapeAnalysis());

    final reachabilityControls = TMAlgorithmStateSelector<Object>(
      controller: controller,
      select: (state) => (
        state.isAnalyzing,
        state.currentFocus,
        state.reachability.progress,
      ),
    );
    final tapeControls = TMAlgorithmStateSelector<Object>(
      controller: controller,
      select: (state) => (
        state.isAnalyzing,
        state.currentFocus,
        state.tape.progress,
      ),
    );
    final results = TMAlgorithmStateSelector<Object>(
      controller: controller,
      select: (state) => (
        state.currentFocus,
        state.currentError,
        state.reachability.report,
        state.reachability.sourceTm,
        state.tape.report,
        state.tape.sourceTm,
      ),
    );
    addTearDown(reachabilityControls.dispose);
    addTearDown(tapeControls.dispose);
    addTearDown(results.dispose);
    var reachabilityControlBuilds = 0;
    var tapeControlBuilds = 0;
    var resultBuilds = 0;

    await _pump(
      tester,
      Column(
        children: [
          _counted(reachabilityControls, () => reachabilityControlBuilds++),
          _counted(tapeControls, () => tapeControlBuilds++),
          _counted(results, () => resultBuilds++),
        ],
      ),
    );
    final beforeRefresh = (
      reachabilityControlBuilds,
      tapeControlBuilds,
      resultBuilds,
    );
    final renamedState = automaton_state.State(
      id: originalState.id,
      label: 'New label',
      position: Vector2(280, 160),
      isInitial: true,
      isAccepting: true,
    );
    final renamed = _singleStateTm(renamedState, name: 'Renamed');

    controller.observeMachine(renamed);
    await tester.pump();

    expect(controller.state.reachability.sourceTm, same(renamed));
    expect(controller.state.tape.sourceTm, same(renamed));
    expect(reachabilityControlBuilds, beforeRefresh.$1);
    expect(tapeControlBuilds, beforeRefresh.$2);
    expect(resultBuilds, beforeRefresh.$3 + 1);
  });

  testWidgets('cancel control exposes Portuguese analysis action', (
    tester,
  ) async {
    final controller = _controllerWithActive(TMAnalysisFocus.termination);
    addTearDown(controller.dispose);
    var cancellations = 0;

    await _pump(
      tester,
      TMAnalysisCancelControl(
        state: controller.state,
        onCancel: () => cancellations++,
      ),
      locale: const Locale('pt'),
    );

    final cancel = find.byKey(const Key('tm-analysis-cancel'));
    final semantics = tester.getSemantics(cancel);
    expect(semantics.label, contains('Cancelar análise'));
    expect(
      semantics.getSemanticsData().hasAction(SemanticsAction.tap),
      isTrue,
    );
    await tester.tap(cancel);
    expect(cancellations, 1);
  });

  testWidgets('cancel control exposes Portuguese exploration action', (
    tester,
  ) async {
    final controller = _controllerWithActive(TMAnalysisFocus.language);
    addTearDown(controller.dispose);
    var cancellations = 0;

    await _pump(
      tester,
      TMAnalysisCancelControl(
        state: controller.state,
        onCancel: () => cancellations++,
      ),
      locale: const Locale('pt'),
    );

    final cancel = find.byKey(const Key('tm-analysis-cancel'));
    expect(
      tester.getSemantics(cancel).label,
      contains('Cancelar exploração'),
    );
    await tester.tap(cancel);
    expect(cancellations, 1);
  });

  testWidgets('cancel control exposes Portuguese cancelling state', (
    tester,
  ) async {
    final controller = _controllerWithActive(TMAnalysisFocus.termination)
      ..requestCancellation();
    addTearDown(controller.dispose);
    var cancellations = 0;

    await _pump(
      tester,
      TMAnalysisCancelControl(
        state: controller.state,
        onCancel: () => cancellations++,
      ),
      locale: const Locale('pt'),
    );

    final cancel = find.byKey(const Key('tm-analysis-cancel'));
    final semantics = tester.getSemantics(cancel);
    expect(semantics.label, contains('Cancelando análise…'));
    expect(
      semantics.getSemanticsData().hasAction(SemanticsAction.tap),
      isFalse,
    );
    await tester.tap(cancel);
    expect(cancellations, 0);
  });

  testWidgets('termination and language results expose semantic headings', (
    tester,
  ) async {
    await _pump(
      tester,
      TMTerminationResultView(analysis: _analysis('Accepted by final state.')),
      locale: const Locale('pt'),
    );
    expect(
      tester.getSemantics(find.byType(TMAnalysisFocusBanner)).label,
      contains('Foco da análise: Término e ciclos'),
    );

    final word = TMLanguageWordResult(
      input: 'a',
      outcome: TMLanguageOutcome.accepted,
      analysis: _analysis('accepted'),
    );
    TMLanguageWordResult? selected;
    await _pump(
      tester,
      ListView(
        children: [
          TMLanguageResultView(
            report: TMLanguageExplorerReport(
              limits: const TMLanguageExplorerLimits(),
              alphabet: const ['a'],
              requestedCandidates: BigInt.one,
              plannedCandidates: 1,
              results: [word],
              cancelled: false,
              truncatedByCandidateCap: false,
              executionTime: Duration.zero,
            ),
            selectedWord: null,
            selectedTrace: null,
            isLoadingTrace: false,
            onWordSelected: (value) => selected = value,
          ),
        ],
      ),
      locale: const Locale('pt'),
    );
    await tester.tap(find.byKey(const ValueKey('tm-language-word-a')));
    expect(selected, same(word));
    expect(
      tester.getSemantics(find.byType(TMAnalysisFocusBanner)).label,
      contains('Foco da análise: Explorador de linguagem'),
    );
  });

  testWidgets('reachability result is independently instantiable', (
    tester,
  ) async {
    await _pump(
      tester,
      TMReachabilityResultView(
        report: TMReachabilityReport(
          inputs: const [''],
          status: TMReachabilityStatus.complete,
          message: 'Complete.',
          structurallyReachableStateIds: const {},
          structurallyUnreachableStateIds: const {},
          witnessesByStateId: const {},
          configurationsExplored: 1,
          transitionsExplored: 0,
          maxSteps: 10,
          maxConfigurations: 20,
          timeout: const Duration(seconds: 1),
          executionTime: Duration.zero,
        ),
        sourceTm: null,
      ),
      locale: const Locale('pt'),
    );
    expect(find.byType(TMReachabilityResultView), findsOneWidget);
    expect(
      tester.getSemantics(find.byType(TMAnalysisFocusBanner)).label,
      contains(
          'Foco da análise: Alcançabilidade estrutural e semântica limitada'),
    );
  });

  testWidgets('tape result is independently instantiable', (tester) async {
    await _pump(
      tester,
      ListView(
        children: [
          TMTapeResultView(analysis: _tapeAnalysis(), sourceTm: null),
        ],
      ),
      locale: const Locale('pt'),
    );
    expect(find.byType(TMTapeResultView), findsOneWidget);
    expect(
      tester.getSemantics(find.byType(TMAnalysisFocusBanner)).label,
      contains('Foco da análise: Traço da fita'),
    );
  });

  testWidgets('time and space results instantiate independently', (
    tester,
  ) async {
    await _pump(
      tester,
      TMTimeResultView(
        report: TMTimeProfileReport(
          kind: TMTimeProfileKind.deterministicTime,
          status: TMTimeProfileStatus.complete,
          message: 'Complete.',
          plan: TMTimeProfilePlan(
            bounds: const TMTimeProfileBounds(maxLength: 0),
            alphabet: const [],
            rows: const [],
            plannedCandidateCount: 0,
          ),
          rows: const [],
          profilingWallClockTime: Duration.zero,
        ),
      ),
      locale: const Locale('pt'),
    );
    expect(find.byType(TMTimeResultView), findsOneWidget);
    expect(
      tester.getSemantics(find.byType(TMAnalysisFocusBanner)).label,
      contains('Foco da análise: Perfil de tempo'),
    );

    await _pump(
      tester,
      TMSpaceResultView(
        report: TMSpaceProfileReport(
          limits: const TMSpaceProfileLimits(maxInputLength: 0),
          alphabet: const [],
          requestedCandidates: BigInt.zero,
          scheduledCandidates: 0,
          rows: const [],
          cancelled: false,
          isNondeterministic: false,
          executionTime: Duration.zero,
        ),
      ),
      locale: const Locale('pt'),
    );
    expect(find.byType(TMSpaceResultView), findsOneWidget);
    expect(
      tester.getSemantics(find.byType(TMAnalysisFocusBanner)).label,
      contains('Foco da análise: Perfil de espaço'),
    );
  });
}

Widget _counted(Listenable listenable, VoidCallback onBuild) {
  return ListenableBuilder(
    listenable: listenable,
    builder: (_, __) {
      onBuild();
      return const SizedBox();
    },
  );
}

Future<void> _pump(
  WidgetTester tester,
  Widget child, {
  Locale locale = const Locale('en'),
}) {
  return tester.pumpWidget(
    MaterialApp(
      locale: locale,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: Scaffold(body: child),
    ),
  );
}

TMExecutionAnalysis _analysis(String message) => TMExecutionAnalysis(
      input: 'a',
      outcome: TMExecutionOutcome.accepted,
      message: message,
      stepsExecuted: 1,
      configurationsExplored: 2,
      maxSteps: 10,
      maxConfigurations: 20,
      timeout: const Duration(seconds: 1),
      executionTime: Duration.zero,
    );

TMExecutionAnalysis _tapeAnalysis() => TMExecutionAnalysis(
      input: 'a',
      outcome: TMExecutionOutcome.accepted,
      message: 'Accepted.',
      stepsExecuted: 1,
      configurationsExplored: 2,
      maxSteps: 10,
      maxConfigurations: 20,
      timeout: const Duration(seconds: 1),
      executionTime: Duration.zero,
      traceMetrics: TMTraceMetrics(
        branchSelection: TMExecutionBranchSelection.deterministic,
        readCounts: const {},
        writeCountsByOldSymbol: const {},
        writeCountsByNewSymbol: const {},
        changedWrites: 0,
        movementCounts: const {},
        headReversals: 0,
        minimumHeadPosition: 0,
        maximumHeadPosition: 0,
        visitedCells: const {0},
        maximumSimultaneousNonBlankCells: 1,
        transitionExecutionCounts: const {},
        cellTouchRanges: const {},
        tapeDiff: const {},
        definedButNotExecutedTransitionIds: const {},
        retainedTraceSnapshots: 0,
      ),
    );

TMAlgorithmExecutionController _controllerWithActive(TMAnalysisFocus focus) {
  final controller = TMAlgorithmExecutionController(
    initialTm: TM.empty(id: 'cancel', name: 'Cancel'),
    highlights: null,
  );
  controller.begin(focus);
  return controller;
}

TMReachabilityReport _reachabilityReport() => TMReachabilityReport(
      inputs: const [''],
      status: TMReachabilityStatus.complete,
      message: 'Complete.',
      structurallyReachableStateIds: const {'q0'},
      structurallyUnreachableStateIds: const {},
      witnessesByStateId: const {},
      configurationsExplored: 1,
      transitionsExplored: 0,
      maxSteps: 10,
      maxConfigurations: 20,
      timeout: const Duration(seconds: 1),
      executionTime: Duration.zero,
    );

TM _singleStateTm(automaton_state.State state, {required String name}) {
  final now = DateTime(2026);
  return TM(
    id: 'tm-source-refresh',
    name: name,
    states: {state},
    transitions: const {},
    alphabet: const {'a'},
    initialState: state,
    acceptingStates: {state},
    created: now,
    modified: now,
    bounds: const Rectangle(0, 0, 800, 600),
    tapeAlphabet: const {'a', 'B'},
  );
}
