//
//  equivalence_comparison_result.dart
//  Turing Lab
//
//  Defines the detailed result of an equivalence comparison between two
//  automata or grammars. Stores the original automata, the equivalence
//  outcome, a distinguishing string (if any), an optional product automaton,
//  algorithm steps, and execution time, enabling a complete educational
//  visualization of language comparison.
//
//  Thales Matheus Mendonça Santos - January 2026
//

import 'fsa.dart';

/// Represents the result of comparing two automata for language equivalence
class EquivalenceComparisonResult {
  /// The first automaton being compared
  final FSA originalAutomaton;

  /// The second automaton being compared
  final FSA comparedAutomaton;

  /// Whether the two automata recognize the same language
  final bool isEquivalent;

  /// A string that distinguishes the two languages (null if equivalent)
  /// This string is accepted by one automaton but not the other
  final String? distinguishingString;

  /// The product automaton constructed during comparison (optional)
  /// States are labeled as (q,p) pairs from the two automata
  final FSA? productAutomaton;

  /// Step-by-step execution trace of the comparison algorithm
  /// Each step contains metadata about the algorithm's progress
  final List<Map<String, dynamic>> steps;

  /// Time taken to execute the comparison algorithm in milliseconds
  final int executionTimeMs;

  /// When this comparison was performed
  final DateTime? timestamp;

  const EquivalenceComparisonResult({
    required this.originalAutomaton,
    required this.comparedAutomaton,
    required this.isEquivalent,
    this.distinguishingString,
    this.productAutomaton,
    this.steps = const [],
    required this.executionTimeMs,
    this.timestamp,
  });

  /// Create an equivalent result
  factory EquivalenceComparisonResult.equivalent({
    required FSA originalAutomaton,
    required FSA comparedAutomaton,
    FSA? productAutomaton,
    List<Map<String, dynamic>> steps = const [],
    required int executionTimeMs,
    DateTime? timestamp,
  }) {
    return EquivalenceComparisonResult(
      originalAutomaton: originalAutomaton,
      comparedAutomaton: comparedAutomaton,
      isEquivalent: true,
      distinguishingString: null,
      productAutomaton: productAutomaton,
      steps: steps,
      executionTimeMs: executionTimeMs,
      timestamp: timestamp,
    );
  }

  /// Create a non-equivalent result with a distinguishing string
  factory EquivalenceComparisonResult.notEquivalent({
    required FSA originalAutomaton,
    required FSA comparedAutomaton,
    required String distinguishingString,
    FSA? productAutomaton,
    List<Map<String, dynamic>> steps = const [],
    required int executionTimeMs,
    DateTime? timestamp,
  }) {
    return EquivalenceComparisonResult(
      originalAutomaton: originalAutomaton,
      comparedAutomaton: comparedAutomaton,
      isEquivalent: false,
      distinguishingString: distinguishingString,
      productAutomaton: productAutomaton,
      steps: steps,
      executionTimeMs: executionTimeMs,
      timestamp: timestamp,
    );
  }
}

/// Additional information about why two automata are not equivalent
class CounterexampleDetails {
  /// The distinguishing string
  final String string;

  /// Whether the string is accepted by the original automaton
  final bool acceptedByOriginal;

  /// Whether the string is accepted by the compared automaton
  final bool acceptedByCompared;

  /// Length of the distinguishing string
  final int length;

  /// Explanation of why this string distinguishes the languages
  final String explanation;

  const CounterexampleDetails({
    required this.string,
    required this.acceptedByOriginal,
    required this.acceptedByCompared,
    required this.length,
    required this.explanation,
  });
}
