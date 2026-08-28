import '../../core/algorithms/tm_execution_analyzer.dart';
import '../../core/algorithms/tm_language_explorer.dart';
import '../../core/algorithms/tm_reachability_analyzer.dart';
import '../../core/algorithms/tm_space_profiler.dart';
import '../../core/algorithms/tm_time_profiler.dart';
import '../../core/models/simulation_highlight.dart';
import '../../core/models/tm.dart';
import '../../core/models/tm_execution_analysis.dart';
import '../../core/models/tm_language_explorer_models.dart';
import '../../core/models/tm_reachability_report.dart';
import 'tm_algorithm_execution_controller.dart';
import 'tm_algorithm_inputs.dart';

/// Executes core analyzers while the controller owns request validity and state.
class TMAlgorithmRunner {
  const TMAlgorithmRunner({required this.execution, required this.inputs});

  static const _maxSteps = 10000;
  static const _maxConfigurations = 100000;
  static const _timeout = Duration(seconds: 5);
  static const _invalidLimitsMessage =
      'Maximum length must be 0 through 20, candidate cap 1 through 10,000, and execution limits positive whole numbers.';

  final TMAlgorithmExecutionController execution;
  final TMAlgorithmInputs inputs;

  Future<void> run(
    TMAnalysisFocus focus,
    TM? tm, {
    required String missingMachineMessage,
    required String Function(int steps, int configurations) progressLabel,
  }) async {
    final request = execution.begin(focus);
    if (tm == null) {
      execution.fail(request, missingMachineMessage);
      return;
    }

    switch (focus) {
      case TMAnalysisFocus.time:
        await _runTime(request, tm);
      case TMAnalysisFocus.termination || TMAnalysisFocus.tape:
        await _runExecution(request, tm, progressLabel);
      case TMAnalysisFocus.reachability:
        await _runReachability(request, tm, progressLabel);
      case TMAnalysisFocus.language:
        await _runLanguage(request, tm);
      case TMAnalysisFocus.space:
        await _runSpace(request, tm);
    }
  }

  Future<void> _runTime(TMAnalysisRequestToken request, TM tm) async {
    final bounds = inputs.timeBounds;
    if (bounds == null) {
      execution.fail(
        request,
        'Enter integer bounds before starting the bounded time profile.',
      );
      return;
    }
    final report = await TMTimeProfiler.profile(
      tm,
      bounds: bounds,
      isCancelled: () => execution.isCancelled(request),
      onProgress: (progress) {
        final input = progress.input.isEmpty ? 'ε' : progress.input;
        execution.updateTimeProgress(
          request,
          TMTimeAnalysisProgress(
            fraction: progress.fraction.clamp(0, 1),
            label: progress.isWitnessReplay
                ? 'Retaining witness trace for $input'
                : 'Profiling length ${progress.inputLength}: $input',
          ),
        );
      },
    );
    execution.completeTime(request, report);
  }

  Future<void> _runExecution(
    TMAnalysisRequestToken request,
    TM tm,
    String Function(int, int) progressLabel,
  ) async {
    final report = await TMExecutionAnalyzer.analyze(
      tm,
      inputs.terminationInput.text,
      maxSteps: _maxSteps,
      maxConfigurations: _maxConfigurations,
      timeout: _timeout,
      isCancelled: () => execution.isCancelled(request),
      onProgress: (steps, configurations) => execution.updateOperationProgress(
        request,
        progressLabel(steps, configurations),
      ),
    );
    if (!execution.isCurrent(request)) return;
    if (request.focus == TMAnalysisFocus.tape) {
      _highlightTapeTrace(report);
      execution.completeTape(request, report);
    } else {
      execution.completeTermination(request, report);
    }
  }

  void _highlightTapeTrace(TMExecutionAnalysis report) {
    if (report.traceMetrics == null) return;
    final highlights = execution.highlights;
    final target = highlights?.target;
    if (target == null) return;
    highlights!.sendFor(
      target,
      SimulationHighlight(
        stateIds: report.trace.map<String>((step) => step.currentState).toSet(),
        transitionIds: report.traceMetrics!.transitionExecutionCounts.keys
            .toSet(),
      ),
    );
  }

  Future<void> _runReachability(
    TMAnalysisRequestToken request,
    TM tm,
    String Function(int, int) progressLabel,
  ) async {
    final report = await TMReachabilityAnalyzer.analyze(
      tm,
      inputs: inputs.reachabilityInputScope,
      maxSteps: _maxSteps,
      maxConfigurations: _maxConfigurations,
      timeout: _timeout,
      isCancelled: () => execution.isCancelled(request),
      onProgress: (transitions, configurations) =>
          execution.updateOperationProgress(
            request,
            progressLabel(transitions, configurations),
          ),
    );
    if (!execution.isCurrent(request)) return;
    if (report.status != TMReachabilityStatus.invalidMachine) {
      final highlights = execution.highlights;
      final target = highlights?.target;
      if (target != null) {
        highlights!.sendFor(
          target,
          SimulationHighlight(
            stateIds: report.reachedWithinBoundsStateIds,
            warningStateIds: report.notObservedWithinBoundsStateIds,
            errorStateIds: report.structurallyUnreachableStateIds,
          ),
        );
      }
    }
    execution.completeReachability(request, report);
  }

  Future<void> _runLanguage(TMAnalysisRequestToken request, TM tm) async {
    final limits = inputs.languageLimits;
    if (limits == null) {
      execution.fail(request, _invalidLimitsMessage);
      return;
    }
    final cancellation = TMLanguageExplorerCancellationToken();
    execution.attachLanguageCancellation(request, cancellation);
    final result = await TMLanguageExplorer.explore(
      tm,
      limits: limits,
      cancellationToken: cancellation,
      onProgress: (progress) =>
          execution.updateLanguageProgress(request, progress),
    );
    if (result.isSuccess) {
      execution.completeLanguage(request, result.data!);
    } else {
      execution.fail(
        request,
        result.error ?? 'Language exploration failed.',
        structuredError: result.structuredError,
      );
    }
  }

  Future<void> _runSpace(TMAnalysisRequestToken request, TM tm) async {
    final limits = inputs.spaceLimits;
    if (limits == null) {
      execution.fail(request, _invalidLimitsMessage);
      return;
    }
    final result = await TMSpaceProfiler.profile(
      tm,
      limits: limits,
      isCancelled: () => execution.isCancelled(request),
      onProgress: (progress) =>
          execution.updateSpaceProgress(request, progress),
    );
    if (result.isSuccess) {
      execution.completeSpace(request, result.data!);
    } else {
      execution.fail(
        request,
        result.error ?? 'Space profiling failed.',
        structuredError: result.structuredError,
      );
    }
  }

  Future<void> selectLanguageWord(TMLanguageWordResult word) async {
    final request = execution.selectLanguageWord(word);
    if (request == null) return;
    final language = execution.state.language;
    final tm = language.sourceTm;
    final limits = language.report?.limits;
    if (tm == null || limits == null) {
      execution.cancelLanguageTraceLoading();
      return;
    }
    final trace = await TMExecutionAnalyzer.analyze(
      tm,
      word.input,
      maxSteps: limits.maxStepsPerInput,
      maxConfigurations: limits.maxConfigurationsPerInput,
      timeout: limits.timeoutPerInput,
      operationsPerBatch: limits.operationsPerBatch,
      includeTrace: true,
    );
    execution.completeLanguageTrace(request, trace);
  }
}
