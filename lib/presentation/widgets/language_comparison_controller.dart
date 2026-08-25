//
//  language_comparison_controller.dart
//  Turing Lab
//
//  Owns the lifecycle of language-equivalence comparisons for a surface.
//  Every comparison is stamped with a request generation, so a slow run that
//  finishes after the inputs changed is discarded instead of replacing the
//  answer for the newer inputs. The controller also refuses a verdict whose
//  witness does not come from the exact automaton revisions that were asked
//  about.
//
//  Thales Matheus Mendonça Santos - August 2026
//
import 'package:flutter/foundation.dart';

import '../../core/models/equivalence_comparison_result.dart';
import '../../core/models/fsa.dart';
import '../../core/models/language_comparison_outcome.dart';

/// Runs one comparison. Implementations may be synchronous or asynchronous.
typedef LanguageComparisonRunner = Future<LanguageComparisonOutcome> Function(
  LanguageComparisonRequest request,
);

/// The two automata a comparison was asked about, at the revision it saw.
@immutable
class LanguageComparisonRequest {
  const LanguageComparisonRequest({
    required this.automatonA,
    required this.automatonB,
  });

  final FSA automatonA;
  final FSA automatonB;

  /// Fingerprint of both inputs.
  ///
  /// Automaton equality only compares id, name and type, so two different
  /// edits of the same document compare equal. The fingerprint adds the
  /// modification timestamp and the state and transition counts, which is what
  /// makes a witness traceable to the revision it was computed from.
  String get revision =>
      '${_revisionOf(automatonA)}|${_revisionOf(automatonB)}';

  /// Whether [result] was computed from exactly the automata of this request.
  bool producedThis(EquivalenceComparisonResult result) {
    return _revisionOf(result.originalAutomaton) == _revisionOf(automatonA) &&
        _revisionOf(result.comparedAutomaton) == _revisionOf(automatonB);
  }

  static String _revisionOf(FSA automaton) {
    return '${automaton.id}@${automaton.modified.microsecondsSinceEpoch}'
        ':${automaton.states.length}/${automaton.transitions.length}';
  }
}

/// Immutable view of what a [LanguageComparisonController] currently holds.
@immutable
class LanguageComparisonSnapshot {
  const LanguageComparisonSnapshot({
    required this.isRunning,
    this.request,
    this.outcome,
  });

  const LanguageComparisonSnapshot.idle()
      : isRunning = false,
        request = null,
        outcome = null;

  /// Whether a comparison is in flight for [request].
  final bool isRunning;

  /// The request the current [outcome] belongs to, or the one being run.
  final LanguageComparisonRequest? request;

  /// The outcome of the newest request that finished, if any.
  ///
  /// Always paired with the [request] that produced it, so a witness can never
  /// be read next to the inputs of a different comparison.
  final LanguageComparisonOutcome? outcome;
}

/// Serializes comparison requests for one surface.
class LanguageComparisonController extends ChangeNotifier {
  LanguageComparisonController({required LanguageComparisonRunner runner})
      : _runner = runner;

  final LanguageComparisonRunner _runner;

  int _generation = 0;
  bool _disposed = false;
  LanguageComparisonSnapshot _snapshot =
      const LanguageComparisonSnapshot.idle();

  LanguageComparisonSnapshot get snapshot => _snapshot;

  /// Number of requests started, also used as the staleness token.
  ///
  /// Exposed so a host can assert that a late completion belonged to an older
  /// generation instead of guessing from timing.
  int get generation => _generation;

  /// Starts a comparison for [request] and publishes its outcome, unless a
  /// newer request was started (or the controller was disposed) in the
  /// meantime.
  Future<void> compare(LanguageComparisonRequest request) async {
    final generation = ++_generation;
    _publish(
      LanguageComparisonSnapshot(isRunning: true, request: request),
    );

    LanguageComparisonOutcome outcome;
    try {
      outcome = await _runner(request);
    } catch (error) {
      outcome = LanguageComparisonFailure(
        reason: LanguageComparisonFailureReason.internalError,
        message: '$error',
      );
    }

    if (_disposed || generation != _generation) {
      return;
    }

    _publish(
      LanguageComparisonSnapshot(
        isRunning: false,
        request: request,
        outcome: _rejectMismatchedWitness(request, outcome),
      ),
    );
  }

  /// Abandons the in-flight comparison without publishing its outcome.
  void cancel() {
    if (!_snapshot.isRunning) {
      return;
    }
    _generation++;
    _publish(
      LanguageComparisonSnapshot(
        isRunning: false,
        request: _snapshot.request,
        outcome: _snapshot.outcome,
      ),
    );
  }

  /// Clears the published outcome and abandons anything in flight.
  void reset() {
    _generation++;
    _publish(const LanguageComparisonSnapshot.idle());
  }

  /// Downgrades a verdict whose automata are not the ones that were asked
  /// about, so a witness can never be shown against a different revision.
  LanguageComparisonOutcome _rejectMismatchedWitness(
    LanguageComparisonRequest request,
    LanguageComparisonOutcome outcome,
  ) {
    if (outcome is! LanguageComparisonCompleted) {
      return outcome;
    }
    if (request.producedThis(outcome.result)) {
      return outcome;
    }
    return const LanguageComparisonFailure(
      reason: LanguageComparisonFailureReason.internalError,
      message: 'Comparison result does not match the requested automaton '
          'revisions',
    );
  }

  void _publish(LanguageComparisonSnapshot snapshot) {
    if (_disposed) {
      return;
    }
    _snapshot = snapshot;
    notifyListeners();
  }

  @override
  void dispose() {
    _disposed = true;
    // Invalidates any in-flight request so its completion is dropped instead
    // of touching a disposed notifier.
    _generation++;
    super.dispose();
  }
}
