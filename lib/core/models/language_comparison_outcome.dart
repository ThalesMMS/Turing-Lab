//
//  language_comparison_outcome.dart
//  Turing Lab
//
//  Sealed outcome of a language-equivalence comparison. A comparison either
//  completes with a verdict backed by the exact automata it inspected, or it
//  reports why it could not decide. A failure carries no automaton, so no
//  surface can derive an equivalent/not-equivalent verdict from a fallback
//  machine after determinization, normalization or conversion gave up.
//
//  Thales Matheus Mendonça Santos - August 2026
//
import 'equivalence_comparison_result.dart';
import '../messages/structured_message.dart';

/// Why a language comparison did not produce a verdict.
enum LanguageComparisonFailureReason {
  /// One of the inputs is not a usable automaton (no states, no initial
  /// state, initial state outside the state set).
  malformedInput,

  /// Determinizing one of the inputs failed.
  determinization,

  /// Alphabet normalization or DFA completion failed.
  normalization,

  /// The product automaton could not be built, typically because a supposedly
  /// deterministic automaton was missing a transition.
  productConstruction,

  /// The comparison exceeded its time budget.
  timeout,

  /// The comparison exceeded the number of product states it may explore.
  stateLimit,

  /// An unexpected error escaped the comparison engine.
  internalError;

  /// Whether the comparison stopped because a budget was exhausted rather than
  /// because the inputs or an internal conversion were invalid.
  ///
  /// Budget exhaustion leaves the question open, so it is reported as
  /// inconclusive; every other reason is a hard error.
  bool get isInconclusive => this == timeout || this == stateLimit;
}

/// Status a comparison surface presents to the user.
enum LanguageComparisonStatus {
  equivalent,
  notEquivalent,
  inconclusive,
  error;

  /// Stable, locale-independent key used by semantic identifiers and tests.
  String get semanticsValue => switch (this) {
    LanguageComparisonStatus.equivalent => 'equivalent',
    LanguageComparisonStatus.notEquivalent => 'not-equivalent',
    LanguageComparisonStatus.inconclusive => 'inconclusive',
    LanguageComparisonStatus.error => 'error',
  };
}

/// Result of running a language comparison to completion or to a stop.
sealed class LanguageComparisonOutcome {
  const LanguageComparisonOutcome();

  LanguageComparisonStatus get status;

  /// Whether this outcome states that the two languages are the same.
  ///
  /// Only a completed comparison can answer this; a failure deliberately
  /// refuses to, which is what keeps a stopped comparison from being read as
  /// an equivalence verdict.
  bool? get isEquivalent => switch (status) {
    LanguageComparisonStatus.equivalent => true,
    LanguageComparisonStatus.notEquivalent => false,
    LanguageComparisonStatus.inconclusive => null,
    LanguageComparisonStatus.error => null,
  };
}

/// A comparison that ran to completion and decided the question.
final class LanguageComparisonCompleted extends LanguageComparisonOutcome {
  const LanguageComparisonCompleted(this.result);

  /// The full comparison record, including the exact automata that were
  /// compared and the witness derived from them.
  final EquivalenceComparisonResult result;

  @override
  LanguageComparisonStatus get status => result.isEquivalent
      ? LanguageComparisonStatus.equivalent
      : LanguageComparisonStatus.notEquivalent;
}

/// A comparison that stopped without deciding the question.
final class LanguageComparisonFailure extends LanguageComparisonOutcome {
  const LanguageComparisonFailure({
    required this.reason,
    this.message,
    this.structuredMessage,
  });

  final LanguageComparisonFailureReason reason;

  /// Legacy engine detail retained for logs and compatibility callers.
  final String? message;

  /// Locale-neutral detail emitted by the comparison engine, when available.
  ///
  /// The presentation layer resolves this identity for the active locale;
  /// formal automaton labels carried as typed arguments remain unchanged.
  final StructuredMessage? structuredMessage;

  @override
  LanguageComparisonStatus get status => reason.isInconclusive
      ? LanguageComparisonStatus.inconclusive
      : LanguageComparisonStatus.error;
}
