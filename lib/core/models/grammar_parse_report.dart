//
//  grammar_parse_report.dart
//  Turing Lab
//
//  Structured feedback for grammar parse attempts.
//
import 'derivation_tree.dart';
import 'll1_parse_step.dart';

/// Structured feedback for a grammar parse attempt.
///
/// This is intentionally UI-friendly and non-throwing: parsers can return
/// partial information (e.g. farthestPosition without expectedSymbols).
class GrammarParseReport {
  final String inputString;

  /// Whether the input is accepted by the grammar.
  final bool accepted;

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

  /// Derivation/parse trees on success. For ambiguous parses, parsers may return
  /// multiple trees up to a small cap.
  final List<DerivationTree> trees;

  /// Indicates the parse likely has more than one tree, but was capped.
  final bool isAmbiguous;

  /// Total execution time for the parse attempt.
  final Duration executionTime;

  /// Predictive-parser trace when the selected strategy is LL(1).
  final List<LL1ParseStep> ll1Steps;

  const GrammarParseReport({
    required this.inputString,
    required this.accepted,
    required this.farthestPosition,
    required this.expectedSymbols,
    required this.message,
    required this.trees,
    required this.isAmbiguous,
    required this.executionTime,
    this.ll1Steps = const <LL1ParseStep>[],
  });

  factory GrammarParseReport.accepted({
    required String inputString,
    required Duration executionTime,
    List<DerivationTree> trees = const <DerivationTree>[],
    bool isAmbiguous = false,
    List<LL1ParseStep> ll1Steps = const <LL1ParseStep>[],
  }) {
    return GrammarParseReport(
      inputString: inputString,
      accepted: true,
      farthestPosition: inputString.length,
      expectedSymbols: const <String>{},
      message: null,
      trees: trees,
      isAmbiguous: isAmbiguous,
      executionTime: executionTime,
      ll1Steps: List<LL1ParseStep>.unmodifiable(ll1Steps),
    );
  }

  factory GrammarParseReport.rejected({
    required String inputString,
    required int farthestPosition,
    required Duration executionTime,
    Set<String> expectedSymbols = const <String>{},
    String? message,
    List<LL1ParseStep> ll1Steps = const <LL1ParseStep>[],
  }) {
    return GrammarParseReport(
      inputString: inputString,
      accepted: false,
      farthestPosition: farthestPosition,
      expectedSymbols: expectedSymbols,
      message: message,
      trees: const <DerivationTree>[],
      isAmbiguous: false,
      executionTime: executionTime,
      ll1Steps: List<LL1ParseStep>.unmodifiable(ll1Steps),
    );
  }
}
