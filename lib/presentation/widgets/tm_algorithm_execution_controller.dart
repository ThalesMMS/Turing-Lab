import 'dart:convert';

import 'package:flutter/foundation.dart';

import '../../core/messages/structured_message.dart';
import '../../core/models/tm.dart';
import '../../core/models/tm_execution_analysis.dart';
import '../../core/models/tm_language_explorer_models.dart';
import '../../core/models/tm_reachability_report.dart';
import '../../core/models/tm_space_profile.dart';
import '../../core/models/tm_time_profile.dart';
import '../../core/services/canvas_highlight_coordinator.dart';

const _unchanged = Object();

/// Analysis families exposed by the Turing-machine algorithm panel.
enum TMAnalysisFocus { termination, reachability, language, tape, time, space }

/// Exact execution-relevant shape of a Turing machine.
///
/// Canvas coordinates, labels, names, timestamps, and viewport properties are
/// deliberately absent. They can change while an analysis is running without
/// making its mathematical result stale.
@immutable
final class TMSemanticRevision {
  const TMSemanticRevision._(this.signature);

  factory TMSemanticRevision.fromMachine(TM? tm) {
    if (tm == null) return const TMSemanticRevision._('absent');

    final stateIds = tm.states.map((state) => state.id).toList()..sort();
    final acceptingStateIds =
        tm.acceptingStates.map((state) => state.id).toList()..sort();
    final alphabet = tm.alphabet.toList()..sort();
    final tapeAlphabet = tm.tapeAlphabet.toList()..sort();
    final transitions =
        tm.tmTransitions
            .map(
              (transition) => <String, Object>{
                'id': transition.id,
                'from': transition.fromState.id,
                'to': transition.toState.id,
                'read': transition.readSymbol,
                'write': transition.writeSymbol,
                'direction': transition.direction.name,
                'tape': transition.tapeNumber,
              },
            )
            .toList()
          ..sort(
            (left, right) => jsonEncode(left).compareTo(jsonEncode(right)),
          );

    return TMSemanticRevision._(
      jsonEncode(<String, Object?>{
        'states': stateIds,
        'initial': tm.initialState?.id,
        'accepting': acceptingStateIds,
        'alphabet': alphabet,
        'tapeAlphabet': tapeAlphabet,
        'blank': tm.blankSymbol,
        'tapeCount': tm.tapeCount,
        'transitions': transitions,
      }),
    );
  }

  final String signature;

  @override
  bool operator ==(Object other) =>
      other is TMSemanticRevision && other.signature == signature;

  @override
  int get hashCode => signature.hashCode;
}

/// Identity carried by every asynchronous analysis callback.
@immutable
final class TMAnalysisRequestToken {
  const TMAnalysisRequestToken._({
    required this.focus,
    required this.generation,
    required this.sourceRevision,
  });

  final TMAnalysisFocus focus;
  final int generation;
  final TMSemanticRevision sourceRevision;
}

/// Report, progress, and source metadata for one analysis family.
@immutable
class TMAnalysisFamilyState<TReport, TProgress> {
  const TMAnalysisFamilyState({
    this.report,
    this.progress,
    this.error,
    this.structuredError,
    this.sourceTm,
    this.sourceRevision,
  });

  final TReport? report;
  final TProgress? progress;
  final String? error;
  final StructuredMessage? structuredError;
  final TM? sourceTm;
  final TMSemanticRevision? sourceRevision;

  TMAnalysisFamilyState<TReport, TProgress> copyWith({
    Object? report = _unchanged,
    Object? progress = _unchanged,
    Object? error = _unchanged,
    Object? structuredError = _unchanged,
    Object? sourceTm = _unchanged,
    Object? sourceRevision = _unchanged,
  }) {
    return TMAnalysisFamilyState<TReport, TProgress>(
      report: identical(report, _unchanged) ? this.report : report as TReport?,
      progress: identical(progress, _unchanged)
          ? this.progress
          : progress as TProgress?,
      error: identical(error, _unchanged) ? this.error : error as String?,
      structuredError: identical(structuredError, _unchanged)
          ? this.structuredError
          : structuredError as StructuredMessage?,
      sourceTm: identical(sourceTm, _unchanged)
          ? this.sourceTm
          : sourceTm as TM?,
      sourceRevision: identical(sourceRevision, _unchanged)
          ? this.sourceRevision
          : sourceRevision as TMSemanticRevision?,
    );
  }

  TMAnalysisFamilyState<TReport, TProgress> clearForRequest(
    TM? tm,
    TMSemanticRevision revision,
  ) {
    return TMAnalysisFamilyState<TReport, TProgress>(
      sourceTm: tm,
      sourceRevision: revision,
    );
  }

  TMAnalysisFamilyState<TReport, TProgress> refreshCosmeticSource(
    TM? tm,
    TMSemanticRevision revision,
  ) {
    if (sourceRevision != revision) return this;
    return copyWith(sourceTm: tm);
  }
}

/// Language report plus its independently retained word selection and trace.
@immutable
final class TMLanguageAnalysisState {
  const TMLanguageAnalysisState({
    this.report,
    this.progress,
    this.error,
    this.structuredError,
    this.sourceTm,
    this.sourceRevision,
    this.selectedWord,
    this.selectedTrace,
    this.isLoadingTrace = false,
    this.traceGeneration = 0,
  });

  final TMLanguageExplorerReport? report;
  final TMLanguageExplorerProgress? progress;
  final String? error;
  final StructuredMessage? structuredError;
  final TM? sourceTm;
  final TMSemanticRevision? sourceRevision;
  final TMLanguageWordResult? selectedWord;
  final TMExecutionAnalysis? selectedTrace;
  final bool isLoadingTrace;
  final int traceGeneration;

  TMLanguageAnalysisState copyWith({
    Object? report = _unchanged,
    Object? progress = _unchanged,
    Object? error = _unchanged,
    Object? structuredError = _unchanged,
    Object? sourceTm = _unchanged,
    Object? sourceRevision = _unchanged,
    Object? selectedWord = _unchanged,
    Object? selectedTrace = _unchanged,
    bool? isLoadingTrace,
    int? traceGeneration,
  }) {
    return TMLanguageAnalysisState(
      report: identical(report, _unchanged)
          ? this.report
          : report as TMLanguageExplorerReport?,
      progress: identical(progress, _unchanged)
          ? this.progress
          : progress as TMLanguageExplorerProgress?,
      error: identical(error, _unchanged) ? this.error : error as String?,
      structuredError: identical(structuredError, _unchanged)
          ? this.structuredError
          : structuredError as StructuredMessage?,
      sourceTm: identical(sourceTm, _unchanged)
          ? this.sourceTm
          : sourceTm as TM?,
      sourceRevision: identical(sourceRevision, _unchanged)
          ? this.sourceRevision
          : sourceRevision as TMSemanticRevision?,
      selectedWord: identical(selectedWord, _unchanged)
          ? this.selectedWord
          : selectedWord as TMLanguageWordResult?,
      selectedTrace: identical(selectedTrace, _unchanged)
          ? this.selectedTrace
          : selectedTrace as TMExecutionAnalysis?,
      isLoadingTrace: isLoadingTrace ?? this.isLoadingTrace,
      traceGeneration: traceGeneration ?? this.traceGeneration,
    );
  }

  TMLanguageAnalysisState clearForRequest(TM? tm, TMSemanticRevision revision) {
    return TMLanguageAnalysisState(
      sourceTm: tm,
      sourceRevision: revision,
      traceGeneration: traceGeneration + 1,
    );
  }

  TMLanguageAnalysisState refreshCosmeticSource(
    TM? tm,
    TMSemanticRevision revision,
  ) {
    if (sourceRevision != revision) return this;
    return copyWith(sourceTm: tm);
  }
}

@immutable
final class TMTimeAnalysisProgress {
  const TMTimeAnalysisProgress({required this.fraction, this.label});

  final double fraction;
  final String? label;
}

/// Immutable snapshot of all independent report families.
@immutable
final class TMAlgorithmAnalysisState {
  const TMAlgorithmAnalysisState({
    this.termination = const TMAnalysisFamilyState(),
    this.reachability = const TMAnalysisFamilyState(),
    this.language = const TMLanguageAnalysisState(),
    this.tape = const TMAnalysisFamilyState(),
    this.time = const TMAnalysisFamilyState(),
    this.space = const TMAnalysisFamilyState(),
    this.currentFocus,
    this.activeRequest,
    this.cancelRequested = false,
  });

  final TMAnalysisFamilyState<TMExecutionAnalysis, String> termination;
  final TMAnalysisFamilyState<TMReachabilityReport, String> reachability;
  final TMLanguageAnalysisState language;
  final TMAnalysisFamilyState<TMExecutionAnalysis, String> tape;
  final TMAnalysisFamilyState<TMTimeProfileReport, TMTimeAnalysisProgress> time;
  final TMAnalysisFamilyState<TMSpaceProfileReport, TMSpaceProfileProgress>
  space;
  final TMAnalysisFocus? currentFocus;
  final TMAnalysisRequestToken? activeRequest;
  final bool cancelRequested;

  bool get isAnalyzing => activeRequest != null;

  String? get currentError => switch (currentFocus) {
    TMAnalysisFocus.termination => termination.error,
    TMAnalysisFocus.reachability => reachability.error,
    TMAnalysisFocus.language => language.error,
    TMAnalysisFocus.tape => tape.error,
    TMAnalysisFocus.time => time.error,
    TMAnalysisFocus.space => space.error,
    null => null,
  };

  StructuredMessage? get currentStructuredError => switch (currentFocus) {
    TMAnalysisFocus.termination => termination.structuredError,
    TMAnalysisFocus.reachability => reachability.structuredError,
    TMAnalysisFocus.language => language.structuredError,
    TMAnalysisFocus.tape => tape.structuredError,
    TMAnalysisFocus.time => time.structuredError,
    TMAnalysisFocus.space => space.structuredError,
    null => null,
  };

  TMAlgorithmAnalysisState copyWith({
    TMAnalysisFamilyState<TMExecutionAnalysis, String>? termination,
    TMAnalysisFamilyState<TMReachabilityReport, String>? reachability,
    TMLanguageAnalysisState? language,
    TMAnalysisFamilyState<TMExecutionAnalysis, String>? tape,
    TMAnalysisFamilyState<TMTimeProfileReport, TMTimeAnalysisProgress>? time,
    TMAnalysisFamilyState<TMSpaceProfileReport, TMSpaceProfileProgress>? space,
    Object? currentFocus = _unchanged,
    Object? activeRequest = _unchanged,
    bool? cancelRequested,
  }) {
    return TMAlgorithmAnalysisState(
      termination: termination ?? this.termination,
      reachability: reachability ?? this.reachability,
      language: language ?? this.language,
      tape: tape ?? this.tape,
      time: time ?? this.time,
      space: space ?? this.space,
      currentFocus: identical(currentFocus, _unchanged)
          ? this.currentFocus
          : currentFocus as TMAnalysisFocus?,
      activeRequest: identical(activeRequest, _unchanged)
          ? this.activeRequest
          : activeRequest as TMAnalysisRequestToken?,
      cancelRequested: cancelRequested ?? this.cancelRequested,
    );
  }

  TMAlgorithmAnalysisState start(TMAnalysisRequestToken request, TM? tm) {
    final revision = request.sourceRevision;
    return switch (request.focus) {
      TMAnalysisFocus.termination => copyWith(
        termination: termination.clearForRequest(tm, revision),
        currentFocus: request.focus,
        activeRequest: request,
        cancelRequested: false,
      ),
      TMAnalysisFocus.reachability => copyWith(
        reachability: reachability.clearForRequest(tm, revision),
        currentFocus: request.focus,
        activeRequest: request,
        cancelRequested: false,
      ),
      TMAnalysisFocus.language => copyWith(
        language: language.clearForRequest(tm, revision),
        currentFocus: request.focus,
        activeRequest: request,
        cancelRequested: false,
      ),
      TMAnalysisFocus.tape => copyWith(
        tape: tape.clearForRequest(tm, revision),
        currentFocus: request.focus,
        activeRequest: request,
        cancelRequested: false,
      ),
      TMAnalysisFocus.time => copyWith(
        time: time.clearForRequest(tm, revision),
        currentFocus: request.focus,
        activeRequest: request,
        cancelRequested: false,
      ),
      TMAnalysisFocus.space => copyWith(
        space: space.clearForRequest(tm, revision),
        currentFocus: request.focus,
        activeRequest: request,
        cancelRequested: false,
      ),
    };
  }

  TMAlgorithmAnalysisState refreshCosmeticSource(
    TM? tm,
    TMSemanticRevision revision,
  ) {
    return copyWith(
      termination: termination.refreshCosmeticSource(tm, revision),
      reachability: reachability.refreshCosmeticSource(tm, revision),
      language: language.refreshCosmeticSource(tm, revision),
      tape: tape.refreshCosmeticSource(tm, revision),
      time: time.refreshCosmeticSource(tm, revision),
      space: space.refreshCosmeticSource(tm, revision),
    );
  }
}

@immutable
final class TMLanguageTraceRequestToken {
  const TMLanguageTraceRequestToken._({
    required this.generation,
    required this.input,
    required this.sourceRevision,
  });

  final int generation;
  final String input;
  final TMSemanticRevision sourceRevision;
}

/// Owns request identity, cancellation, report state, and analysis highlights.
class TMAlgorithmExecutionController extends ChangeNotifier {
  TMAlgorithmExecutionController({
    required TM? initialTm,
    required CanvasHighlightSourceHandle? highlights,
  }) : _observedTm = initialTm,
       _semanticRevision = TMSemanticRevision.fromMachine(initialTm),
       _highlights = highlights;

  TMAlgorithmAnalysisState _state = const TMAlgorithmAnalysisState();
  TMAlgorithmAnalysisState get state => _state;

  final CanvasHighlightSourceHandle? _highlights;
  CanvasHighlightSourceHandle? get highlights => _highlights;

  TM? _observedTm;
  TMSemanticRevision _semanticRevision;
  TMLanguageExplorerCancellationToken? _languageCancellation;
  int _generation = 0;
  int _traceGeneration = 0;
  bool _disposed = false;

  TMAnalysisRequestToken begin(TMAnalysisFocus focus) {
    _generation++;
    _languageCancellation?.cancel();
    _languageCancellation = null;
    _clearHighlights();
    final request = TMAnalysisRequestToken._(
      focus: focus,
      generation: _generation,
      sourceRevision: _semanticRevision,
    );
    var next = _state.start(request, _observedTm);
    if (focus == TMAnalysisFocus.language) {
      _traceGeneration++;
      next = next.copyWith(
        language: next.language.copyWith(traceGeneration: _traceGeneration),
      );
    }
    _setState(next);
    return request;
  }

  bool observeMachine(TM? tm) {
    if (identical(_observedTm, tm)) return false;
    final revision = TMSemanticRevision.fromMachine(tm);
    _observedTm = tm;
    if (revision == _semanticRevision) {
      _setState(_state.refreshCosmeticSource(tm, revision));
      return true;
    }

    _semanticRevision = revision;
    _generation++;
    _traceGeneration++;
    _languageCancellation?.cancel();
    _languageCancellation = null;
    _clearHighlights();
    _setState(const TMAlgorithmAnalysisState());
    return true;
  }

  void invalidate() {
    _generation++;
    _traceGeneration++;
    _languageCancellation?.cancel();
    _languageCancellation = null;
    _clearHighlights();
    _setState(const TMAlgorithmAnalysisState());
  }

  bool attachLanguageCancellation(
    TMAnalysisRequestToken request,
    TMLanguageExplorerCancellationToken? value,
  ) {
    if (!_accepts(request, TMAnalysisFocus.language)) return false;
    _languageCancellation = value;
    return true;
  }

  void requestCancellation() {
    if (_state.cancelRequested || _state.activeRequest == null) return;
    _languageCancellation?.cancel();
    _setState(_state.copyWith(cancelRequested: true));
  }

  bool isCurrent(TMAnalysisRequestToken request) =>
      !_disposed &&
      identical(_state.activeRequest, request) &&
      request.generation == _generation &&
      request.sourceRevision == _semanticRevision;

  bool isCancelled(TMAnalysisRequestToken request) =>
      _state.cancelRequested || !isCurrent(request);

  bool updateOperationProgress(TMAnalysisRequestToken request, String label) {
    if (!isCurrent(request)) return false;
    switch (request.focus) {
      case TMAnalysisFocus.termination:
        _setState(
          _state.copyWith(
            termination: _state.termination.copyWith(progress: label),
          ),
        );
      case TMAnalysisFocus.reachability:
        _setState(
          _state.copyWith(
            reachability: _state.reachability.copyWith(progress: label),
          ),
        );
      case TMAnalysisFocus.tape:
        _setState(_state.copyWith(tape: _state.tape.copyWith(progress: label)));
      case TMAnalysisFocus.language ||
          TMAnalysisFocus.time ||
          TMAnalysisFocus.space:
        return false;
    }
    return true;
  }

  bool updateLanguageProgress(
    TMAnalysisRequestToken request,
    TMLanguageExplorerProgress progress,
  ) {
    if (!_accepts(request, TMAnalysisFocus.language)) return false;
    _setState(
      _state.copyWith(language: _state.language.copyWith(progress: progress)),
    );
    return true;
  }

  bool updateSpaceProgress(
    TMAnalysisRequestToken request,
    TMSpaceProfileProgress progress,
  ) {
    if (!_accepts(request, TMAnalysisFocus.space)) return false;
    _setState(
      _state.copyWith(space: _state.space.copyWith(progress: progress)),
    );
    return true;
  }

  bool updateTimeProgress(
    TMAnalysisRequestToken request,
    TMTimeAnalysisProgress progress,
  ) {
    if (!_accepts(request, TMAnalysisFocus.time)) return false;
    _setState(_state.copyWith(time: _state.time.copyWith(progress: progress)));
    return true;
  }

  bool completeTermination(
    TMAnalysisRequestToken request,
    TMExecutionAnalysis report,
  ) => _completeExecution(request, report, TMAnalysisFocus.termination);

  bool completeTape(
    TMAnalysisRequestToken request,
    TMExecutionAnalysis report,
  ) => _completeExecution(request, report, TMAnalysisFocus.tape);

  bool _completeExecution(
    TMAnalysisRequestToken request,
    TMExecutionAnalysis report,
    TMAnalysisFocus focus,
  ) {
    if (!_accepts(request, focus)) return false;
    final completed = focus == TMAnalysisFocus.termination
        ? _state.copyWith(
            termination: _state.termination.copyWith(
              report: report,
              progress: null,
              error: null,
              structuredError: null,
              sourceTm: _observedTm,
              sourceRevision: request.sourceRevision,
            ),
          )
        : _state.copyWith(
            tape: _state.tape.copyWith(
              report: report,
              progress: null,
              error: null,
              structuredError: null,
              sourceTm: _observedTm,
              sourceRevision: request.sourceRevision,
            ),
          );
    _setState(_finish(completed));
    return true;
  }

  bool completeReachability(
    TMAnalysisRequestToken request,
    TMReachabilityReport report,
  ) {
    if (!_accepts(request, TMAnalysisFocus.reachability)) return false;
    _setState(
      _finish(
        _state.copyWith(
          reachability: _state.reachability.copyWith(
            report: report,
            progress: null,
            error: null,
            structuredError: null,
            sourceTm: _observedTm,
            sourceRevision: request.sourceRevision,
          ),
        ),
      ),
    );
    return true;
  }

  bool completeLanguage(
    TMAnalysisRequestToken request,
    TMLanguageExplorerReport report,
  ) {
    if (!_accepts(request, TMAnalysisFocus.language)) return false;
    _languageCancellation = null;
    _setState(
      _finish(
        _state.copyWith(
          language: _state.language.copyWith(
            report: report,
            error: null,
            structuredError: null,
            sourceTm: _observedTm,
            sourceRevision: request.sourceRevision,
          ),
        ),
      ),
    );
    return true;
  }

  bool completeSpace(
    TMAnalysisRequestToken request,
    TMSpaceProfileReport report,
  ) {
    if (!_accepts(request, TMAnalysisFocus.space)) return false;
    _setState(
      _finish(
        _state.copyWith(
          space: _state.space.copyWith(
            report: report,
            error: null,
            structuredError: null,
            sourceTm: _observedTm,
            sourceRevision: request.sourceRevision,
          ),
        ),
      ),
    );
    return true;
  }

  bool completeTime(
    TMAnalysisRequestToken request,
    TMTimeProfileReport report,
  ) {
    if (!_accepts(request, TMAnalysisFocus.time)) return false;
    _setState(
      _finish(
        _state.copyWith(
          time: _state.time.copyWith(
            report: report,
            progress: const TMTimeAnalysisProgress(fraction: 1),
            error: null,
            structuredError: null,
            sourceTm: _observedTm,
            sourceRevision: request.sourceRevision,
          ),
        ),
      ),
    );
    return true;
  }

  bool fail(
    TMAnalysisRequestToken request,
    String error, {
    StructuredMessage? structuredError,
  }) {
    if (!isCurrent(request)) return false;
    final failed = switch (request.focus) {
      TMAnalysisFocus.termination => _state.copyWith(
        termination: _state.termination.copyWith(
          error: error,
          structuredError: structuredError,
        ),
      ),
      TMAnalysisFocus.reachability => _state.copyWith(
        reachability: _state.reachability.copyWith(
          error: error,
          structuredError: structuredError,
        ),
      ),
      TMAnalysisFocus.language => _state.copyWith(
        language: _state.language.copyWith(
          error: error,
          structuredError: structuredError,
        ),
      ),
      TMAnalysisFocus.tape => _state.copyWith(
        tape: _state.tape.copyWith(
          error: error,
          structuredError: structuredError,
        ),
      ),
      TMAnalysisFocus.time => _state.copyWith(
        time: _state.time.copyWith(
          error: error,
          structuredError: structuredError,
        ),
      ),
      TMAnalysisFocus.space => _state.copyWith(
        space: _state.space.copyWith(
          error: error,
          structuredError: structuredError,
        ),
      ),
    };
    _setState(_finish(failed));
    return true;
  }

  TMLanguageTraceRequestToken? selectLanguageWord(TMLanguageWordResult word) {
    final language = _state.language;
    final revision = language.sourceRevision;
    if (language.report == null || revision == null) return null;
    final generation = ++_traceGeneration;
    _setState(
      _state.copyWith(
        language: language.copyWith(
          selectedWord: word,
          selectedTrace: null,
          isLoadingTrace: true,
          traceGeneration: generation,
        ),
      ),
    );
    return TMLanguageTraceRequestToken._(
      generation: generation,
      input: word.input,
      sourceRevision: revision,
    );
  }

  bool completeLanguageTrace(
    TMLanguageTraceRequestToken request,
    TMExecutionAnalysis trace,
  ) {
    final language = _state.language;
    if (_disposed ||
        language.traceGeneration != request.generation ||
        _traceGeneration != request.generation ||
        language.selectedWord?.input != request.input ||
        language.sourceRevision != request.sourceRevision ||
        _semanticRevision != request.sourceRevision) {
      return false;
    }
    _setState(
      _state.copyWith(
        language: language.copyWith(
          selectedTrace: trace,
          isLoadingTrace: false,
        ),
      ),
    );
    return true;
  }

  void cancelLanguageTraceLoading() {
    final language = _state.language;
    if (!language.isLoadingTrace) return;
    _traceGeneration++;
    _setState(
      _state.copyWith(
        language: language.copyWith(
          isLoadingTrace: false,
          traceGeneration: _traceGeneration,
        ),
      ),
    );
  }

  bool _accepts(TMAnalysisRequestToken request, TMAnalysisFocus focus) =>
      request.focus == focus && isCurrent(request);

  TMAlgorithmAnalysisState _finish(TMAlgorithmAnalysisState value) =>
      value.copyWith(activeRequest: null, cancelRequested: false);

  void _setState(TMAlgorithmAnalysisState value) {
    if (_disposed) return;
    _state = value;
    notifyListeners();
  }

  void _clearHighlights() {
    final target = _highlights?.target;
    if (target != null) _highlights?.clearFor(target);
  }

  @override
  void dispose() {
    if (_disposed) return;
    _disposed = true;
    _generation++;
    _traceGeneration++;
    _languageCancellation?.cancel();
    _languageCancellation = null;
    _highlights?.dispose();
    super.dispose();
  }
}
