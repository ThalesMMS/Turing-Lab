import 'dart:math' show Rectangle;

import 'package:flutter_test/flutter_test.dart';
import 'package:vector_math/vector_math_64.dart';
import 'package:turing_lab/core/models/state.dart' as automaton_state;
import 'package:turing_lab/core/models/simulation_highlight.dart';
import 'package:turing_lab/core/models/tm.dart';
import 'package:turing_lab/core/models/tm_execution_analysis.dart';
import 'package:turing_lab/core/models/tm_language_explorer_models.dart';
import 'package:turing_lab/core/services/canvas_highlight_coordinator.dart';
import 'package:turing_lab/core/services/highlight_channel.dart';
import 'package:turing_lab/presentation/widgets/tm_algorithm_execution_controller.dart';

class _RecordingHighlightChannel implements HighlightChannel {
  final events = <SimulationHighlight?>[];

  @override
  void clear() => events.add(null);

  @override
  void send(SimulationHighlight highlight) => events.add(highlight);
}

void main() {
  test('beginning one family preserves unrelated reports and language state',
      () {
    final tm = TM.empty(id: 'tm-a', name: 'TM A');
    final controller = TMAlgorithmExecutionController(
      initialTm: tm,
      highlights: null,
    );
    addTearDown(controller.dispose);

    final terminationRequest = controller.begin(TMAnalysisFocus.termination);
    final termination = _analysis('termination');
    expect(
      controller.completeTermination(terminationRequest, termination),
      isTrue,
    );

    final languageRequest = controller.begin(TMAnalysisFocus.language);
    final progress = TMLanguageExplorerProgress(
      evaluatedCandidates: 1,
      plannedCandidates: 2,
      requestedCandidates: BigInt.two,
      counts: const {TMLanguageOutcome.accepted: 1},
      currentInput: 'a',
    );
    expect(
        controller.updateLanguageProgress(languageRequest, progress), isTrue);
    final word = TMLanguageWordResult(
      input: 'a',
      outcome: TMLanguageOutcome.accepted,
      analysis: _analysis('language'),
    );
    final language = TMLanguageExplorerReport(
      limits: const TMLanguageExplorerLimits(),
      alphabet: const ['a'],
      requestedCandidates: BigInt.two,
      plannedCandidates: 2,
      results: [word],
      cancelled: false,
      truncatedByCandidateCap: false,
      executionTime: Duration.zero,
    );
    expect(controller.completeLanguage(languageRequest, language), isTrue);
    controller.selectLanguageWord(word);

    final reachabilityRequest = controller.begin(TMAnalysisFocus.reachability);

    expect(controller.isCurrent(languageRequest), isFalse);
    expect(controller.isCurrent(reachabilityRequest), isTrue);
    expect(controller.state.termination.report, same(termination));
    expect(controller.state.language.report, same(language));
    expect(controller.state.language.progress, same(progress));
    expect(controller.state.language.selectedWord, same(word));
    expect(controller.state.currentFocus, TMAnalysisFocus.reachability);
  });

  test('cosmetic machine edits preserve results and active request identity',
      () {
    final state = automaton_state.State(
      id: 'q0',
      label: 'old label',
      position: Vector2.zero(),
      isInitial: true,
      isAccepting: true,
    );
    final tm = _singleStateTm(state, name: 'Original');
    final controller = TMAlgorithmExecutionController(
      initialTm: tm,
      highlights: null,
    );
    addTearDown(controller.dispose);

    final completedRequest = controller.begin(TMAnalysisFocus.termination);
    final report = _analysis('kept');
    expect(controller.completeTermination(completedRequest, report), isTrue);

    final activeRequest = controller.begin(TMAnalysisFocus.reachability);
    final moved = automaton_state.State(
      id: state.id,
      label: 'new label',
      position: Vector2(300, 180),
      isInitial: true,
      isAccepting: true,
    );
    final cosmeticEdit = _singleStateTm(moved, name: 'Renamed');

    expect(controller.observeMachine(cosmeticEdit), isTrue);
    expect(controller.isCurrent(activeRequest), isTrue);
    expect(controller.state.termination.report, same(report));
    expect(controller.state.termination.sourceTm, same(cosmeticEdit));
    expect(
      controller.updateOperationProgress(activeRequest, 'still current'),
      isTrue,
    );
  });

  test('document identity edits preserve equivalent results and requests', () {
    final state = automaton_state.State(
      id: 'q0',
      label: 'q0',
      position: Vector2.zero(),
      isInitial: true,
      isAccepting: true,
    );
    final tm = _singleStateTm(state, id: 'document-a', name: 'Machine');
    final controller = TMAlgorithmExecutionController(
      initialTm: tm,
      highlights: null,
    );
    addTearDown(controller.dispose);

    final completedRequest = controller.begin(TMAnalysisFocus.termination);
    final report = _analysis('kept across document identity');
    expect(controller.completeTermination(completedRequest, report), isTrue);
    final activeRequest = controller.begin(TMAnalysisFocus.reachability);
    final replacement = _singleStateTm(
      state,
      id: 'document-b',
      name: 'Machine',
    );

    expect(controller.observeMachine(replacement), isTrue);
    expect(controller.isCurrent(activeRequest), isTrue);
    expect(controller.state.termination.report, same(report));
    expect(controller.state.termination.sourceTm, same(replacement));
  });

  test('semantic edits invalidate reports and reject stale writes', () {
    final tm = TM.empty(id: 'tm-a', name: 'TM A');
    final controller = TMAlgorithmExecutionController(
      initialTm: tm,
      highlights: null,
    );
    addTearDown(controller.dispose);

    final oldRequest = controller.begin(TMAnalysisFocus.termination);
    final semanticEdit = tm.copyWith(alphabet: const {'a'});
    expect(controller.observeMachine(semanticEdit), isTrue);

    expect(controller.isCurrent(oldRequest), isFalse);
    expect(
      controller.updateOperationProgress(oldRequest, 'stale progress'),
      isFalse,
    );
    expect(
      controller.completeTermination(oldRequest, _analysis('stale result')),
      isFalse,
    );
    expect(controller.state.termination.report, isNull);
    expect(controller.state.termination.progress, isNull);
  });

  test('machine replacement cancels work and clears owned highlights once', () {
    final tm = TM.empty(id: 'tm-a', name: 'TM A');
    final replacement = TM
        .empty(
      id: 'tm-b',
      name: 'TM B',
    )
        .copyWith(alphabet: const {'a'});
    final output = _RecordingHighlightChannel();
    final coordinator = CanvasHighlightCoordinator(
      target: CanvasHighlightTarget(
        kind: AutomatonSurfaceKind.tm,
        surface: Object(),
        documentId: tm.id,
        revision: 0,
      ),
      output: output,
    );
    addTearDown(coordinator.dispose);
    final controller = TMAlgorithmExecutionController(
      initialTm: tm,
      highlights: coordinator.source(CanvasHighlightSource.analysis),
    );
    addTearDown(controller.dispose);

    final request = controller.begin(TMAnalysisFocus.language);
    final cancellation = TMLanguageExplorerCancellationToken();
    controller.attachLanguageCancellation(request, cancellation);
    controller.highlights!.send(
      SimulationHighlight(stateIds: const {'q0'}),
    );

    expect(controller.observeMachine(replacement), isTrue);
    expect(controller.observeMachine(replacement), isFalse);

    expect(cancellation.isCancelled, isTrue);
    expect(controller.isCurrent(request), isFalse);
    expect(controller.state.isAnalyzing, isFalse);
    expect(controller.state.currentFocus, isNull);
    expect(output.events.where((event) => event == null), hasLength(1));
  });

  test('cancellation is idempotent and reaches the active explorer token', () {
    final tm = TM.empty(id: 'tm-a', name: 'TM A');
    final controller = TMAlgorithmExecutionController(
      initialTm: tm,
      highlights: null,
    );
    addTearDown(controller.dispose);
    final request = controller.begin(TMAnalysisFocus.language);
    final cancellation = TMLanguageExplorerCancellationToken();
    controller.attachLanguageCancellation(request, cancellation);

    controller.requestCancellation();
    controller.requestCancellation();

    expect(cancellation.isCancelled, isTrue);
    expect(controller.state.cancelRequested, isTrue);
  });
}

TMExecutionAnalysis _analysis(String message) => TMExecutionAnalysis(
      input: '',
      outcome: TMExecutionOutcome.accepted,
      message: message,
      stepsExecuted: 0,
      configurationsExplored: 1,
      maxSteps: 10,
      maxConfigurations: 10,
      timeout: const Duration(seconds: 1),
      executionTime: Duration.zero,
    );

TM _singleStateTm(
  automaton_state.State state, {
  String id = 'tm-cosmetic',
  required String name,
}) {
  final now = DateTime(2026);
  return TM(
    id: id,
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
