//
//  grammar_parse_report.dart
//  Turing Lab
//
//  Structured feedback for grammar parse attempts.
//
import 'derivation_tree.dart';
import 'brute_force_parse_models.dart';
import 'll1_parse_step.dart';
import 'lr1_models.dart';
import '../messages/structured_message.dart';

enum GrammarParseOutcome {
  accepted,
  rejected,
  conflict,
  timedOut,
  cancelled,
  stepLimit,
  boundedUnknown,
  invalidInput,
  tokenizationFailure,
}

/// Structured feedback for a grammar parse attempt.
///
/// This is intentionally UI-friendly and non-throwing: parsers can return
/// partial information (e.g. farthestPosition without expectedSymbols).
class GrammarParseReport {
  final String inputString;

  /// Whether the input is accepted by the grammar.
  final bool accepted;
  final GrammarParseOutcome outcome;

  /// Farthest position (0..inputString.length) reached before failure.
  ///
  /// For accepted inputs, this is typically inputString.length.
  final int farthestPosition;

  /// Symbols expected at [farthestPosition], when known.
  ///
  /// These are typically terminals, but may include non-terminals depending on
  /// the parser.
  final Set<String> expectedSymbols;

  /// Human-readable explanation (especially useful on failure or timeouts).
  final String? message;

  /// Locale-neutral diagnostic for the explanation, when one is available.
  final StructuredMessage? structuredMessage;

  /// Derivation/parse trees on success. For ambiguous parses, parsers may return
  /// multiple trees up to a small cap.
  final List<DerivationTree> trees;

  /// Indicates the parse likely has more than one tree, but was capped.
  final bool isAmbiguous;

  /// Total execution time for the parse attempt.
  final Duration executionTime;

  /// Predictive-parser trace when the selected strategy is LL(1).
  final List<LL1ParseStep> ll1Steps;

  /// Shift-reduce trace when the selected strategy is canonical LR(1).
  final List<LR1ParseStep> lr1Steps;

  /// Bounded search details when the selected strategy is brute force.
  final BruteForceParseResult? bruteForceResult;

  const GrammarParseReport({
    required this.inputString,
    required this.accepted,
    GrammarParseOutcome? outcome,
    required this.farthestPosition,
    required this.expectedSymbols,
    required this.message,
    this.structuredMessage,
    required this.trees,
    required this.isAmbiguous,
    required this.executionTime,
    this.ll1Steps = const <LL1ParseStep>[],
    this.lr1Steps = const <LR1ParseStep>[],
    this.bruteForceResult,
  }) : outcome =
           outcome ??
           (accepted
               ? GrammarParseOutcome.accepted
               : GrammarParseOutcome.rejected);

  factory GrammarParseReport.accepted({
    required String inputString,
    required Duration executionTime,
    List<DerivationTree> trees = const <DerivationTree>[],
    bool isAmbiguous = false,
    List<LL1ParseStep> ll1Steps = const <LL1ParseStep>[],
    List<LR1ParseStep> lr1Steps = const <LR1ParseStep>[],
    BruteForceParseResult? bruteForceResult,
    StructuredMessage? structuredMessage,
  }) {
    return GrammarParseReport(
      inputString: inputString,
      accepted: true,
      outcome: GrammarParseOutcome.accepted,
      farthestPosition: inputString.length,
      expectedSymbols: const <String>{},
      message: null,
      structuredMessage: structuredMessage,
      trees: trees,
      isAmbiguous: isAmbiguous,
      executionTime: executionTime,
      ll1Steps: List<LL1ParseStep>.unmodifiable(ll1Steps),
      lr1Steps: List<LR1ParseStep>.unmodifiable(lr1Steps),
      bruteForceResult: bruteForceResult,
    );
  }

  factory GrammarParseReport.rejected({
    required String inputString,
    required int farthestPosition,
    required Duration executionTime,
    Set<String> expectedSymbols = const <String>{},
    String? message,
    StructuredMessage? structuredMessage,
    List<LL1ParseStep> ll1Steps = const <LL1ParseStep>[],
    List<LR1ParseStep> lr1Steps = const <LR1ParseStep>[],
    BruteForceParseResult? bruteForceResult,
    GrammarParseOutcome outcome = GrammarParseOutcome.rejected,
  }) {
    return GrammarParseReport(
      inputString: inputString,
      accepted: false,
      outcome: outcome,
      farthestPosition: farthestPosition,
      expectedSymbols: expectedSymbols,
      message: message,
      structuredMessage: structuredMessage,
      trees: const <DerivationTree>[],
      isAmbiguous: false,
      executionTime: executionTime,
      ll1Steps: List<LL1ParseStep>.unmodifiable(ll1Steps),
      lr1Steps: List<LR1ParseStep>.unmodifiable(lr1Steps),
      bruteForceResult: bruteForceResult,
    );
  }
}
