//
//  regex_analyzer.dart
//  Turing Lab
//
//  Analyzes regular expressions to extract complexity metrics, including
//  star height, nesting depth, operator counts, and alphabet size. Uses AST
//  parsing to compute precise metrics and returns typed structures ready
//  for educational visualization.
//
//  Thales Matheus Mendonça Santos - January 2026
//

import 'dart:math' as math;
import '../models/regex_analysis.dart';
import '../result.dart';
import 'regex_to_nfa_converter.dart';

part 'regex_analyzer_helpers.dart';
part 'regex_analyzer_models.dart';

/// Random number generator for sample string generation
final _random = math.Random();

/// Analyzes regular expressions for complexity metrics and structural analysis
///
/// Provides methods to analyze regex expressions and compute:
/// - Star height (maximum nesting of Kleene stars)
/// - Nesting depth (maximum parentheses depth)
/// - Operator counts (union, concatenation, star, plus, question)
/// - Alphabet size and set
///
/// Example usage:
/// ```dart
/// final result = RegexAnalyzer.analyze('(a|b)*c+');
/// if (result.isSuccess) {
///   print('Star height: ${result.data!.starHeight}');
///   print('Complexity: ${result.data!.complexityLevel.displayName}');
/// }
/// ```
class RegexAnalyzer {
  /// Analyzes a regular expression and returns comprehensive metrics
  ///
  /// Parses the regex into an AST and traverses it to compute:
  /// - Complexity metrics (star height, nesting depth, complexity score)
  /// - Structure analysis (operator counts, alphabet size)
  /// - Empty sample list plus empty-string acceptance metadata
  ///
  /// This structural analysis does not generate sample strings. Call
  /// [generateSampleStrings] for sample-only output, or [analyzeWithSamples]
  /// when a single call should return metrics and populated samples together.
  ///
  /// Returns a [Result] containing [RegexAnalysis] on success, or an error
  /// message on failure if the regex is invalid.
  static Result<RegexAnalysis> analyze(
    String regex, {
    Set<String>? contextAlphabet,
  }) {
    try {
      final stopwatch = Stopwatch()..start();

      // Validate and parse the regular expression into AST
      final parseResult = _validateAndParse(regex);
      if (!parseResult.isSuccess) {
        return ResultFactory.failure(parseResult.error!);
      }
      final node = parseResult.data!;

      // Compute complexity metrics from AST
      final starHeight = _computeStarHeight(node);
      final nestingDepth = _computeNestingDepth(regex);
      final operatorCounts = _countOperatorsFromAst(node);
      final alphabet = _extractAlphabet(node, contextAlphabet);

      // Build complexity analysis
      final complexityAnalysis = RegexComplexityAnalysis.fromMetrics(
        starHeight: starHeight,
        nestingDepth: nestingDepth,
        operatorTotal: operatorCounts.values.fold(0, (a, b) => a + b),
        length: regex.length,
      );

      // Build structure analysis
      final structureAnalysis = RegexStructureAnalysis(
        operatorCount: operatorCounts,
        alphabetSize: alphabet.length,
        alphabet: alphabet,
        totalLength: regex.length,
      );

      // analyze() intentionally keeps generated samples empty; callers that
      // need examples should use generateSampleStrings() or analyzeWithSamples().
      final sampleStrings = RegexSampleStrings(
        samples: [],
        shortestString: null,
        acceptsEmptyString: _acceptsEmptyString(node),
      );

      stopwatch.stop();

      final analysis = RegexAnalysis(
        complexityAnalysis: complexityAnalysis,
        structureAnalysis: structureAnalysis,
        sampleStrings: sampleStrings,
        executionTime: stopwatch.elapsed,
      );

      return ResultFactory.success(analysis);
    } catch (e) {
      return ResultFactory.failure('Error analyzing regex: $e');
    }
  }

  /// Computes only the star height of a regex string
  ///
  /// Star height is the maximum nesting level of Kleene star operators.
  /// For example:
  /// - 'a' has star height 0
  /// - 'a*' has star height 1
  /// - '(a*)*' has star height 2
  /// - '((a*)*)*' has star height 3
  ///
  /// Returns a [Result] containing the star height integer on success.
  static Result<int> computeStarHeight(String regex) {
    try {
      final parseResult = _validateAndParse(regex);
      if (!parseResult.isSuccess) {
        return ResultFactory.failure(parseResult.error!);
      }
      return ResultFactory.success(_computeStarHeight(parseResult.data!));
    } catch (e) {
      return ResultFactory.failure('Error computing star height: $e');
    }
  }

  /// Computes only the nesting depth of parentheses in a regex
  ///
  /// Nesting depth is the maximum depth of parentheses in the expression.
  /// For example:
  /// - 'a' has nesting depth 0
  /// - '(a)' has nesting depth 1
  /// - '((a|b))' has nesting depth 2
  /// - '(((a)))' has nesting depth 3
  ///
  /// Returns a [Result] containing the nesting depth integer on success.
  static Result<int> computeNestingDepth(String regex) {
    try {
      final validationResult = _validateRegex(regex);
      if (!validationResult.isSuccess) {
        return ResultFactory.failure(validationResult.error!);
      }

      return ResultFactory.success(_computeNestingDepth(regex));
    } catch (e) {
      return ResultFactory.failure('Error computing nesting depth: $e');
    }
  }

  /// Extracts the alphabet (set of symbols) used in a regex
  ///
  /// Returns all distinct terminal symbols that appear in the regex,
  /// excluding operators and special symbols like epsilon.
  ///
  /// Returns a [Result] containing the set of alphabet symbols on success.
  static Result<Set<String>> extractAlphabet(String regex) {
    try {
      final parseResult = _validateAndParse(regex);
      if (!parseResult.isSuccess) {
        return ResultFactory.failure(parseResult.error!);
      }
      return ResultFactory.success(_extractAlphabet(parseResult.data!));
    } catch (e) {
      return ResultFactory.failure('Error extracting alphabet: $e');
    }
  }

  /// Counts operators in a regex expression
  ///
  /// Returns a map with counts for each operator type:
  /// - 'union': count of | operators
  /// - 'concatenation': count of implicit concatenations
  /// - 'star': count of * operators
  /// - 'plus': count of + operators
  /// - 'question': count of ? operators
  ///
  /// Returns a [Result] containing the operator count map on success.
  static Result<Map<String, int>> countOperators(String regex) {
    try {
      final parseResult = _validateAndParse(regex);
      if (!parseResult.isSuccess) {
        return ResultFactory.failure(parseResult.error!);
      }
      return ResultFactory.success(_countOperatorsFromAst(parseResult.data!));
    } catch (e) {
      return ResultFactory.failure('Error counting operators: $e');
    }
  }

  /// Determines the complexity level of a regex based on its metrics
  ///
  /// Returns one of:
  /// - [ComplexityLevel.simple]: Easy expressions with low star height
  /// - [ComplexityLevel.moderate]: Medium complexity expressions
  /// - [ComplexityLevel.complex]: Difficult expressions with high nesting
  ///
  /// Returns a [Result] containing the [ComplexityLevel] on success.
  static Result<ComplexityLevel> determineComplexity(String regex) {
    final analysisResult = analyze(regex);
    if (analysisResult.isFailure) {
      return ResultFactory.failure(analysisResult.error!);
    }
    return ResultFactory.success(analysisResult.data!.complexityLevel);
  }

  /// Generates sample strings that match the regular expression
  ///
  /// Uses AST-based generation to produce sample strings of varying lengths.
  /// Includes edge cases:
  /// - Empty string if the regex accepts it
  /// - Shortest possible string
  /// - Strings of varying lengths (short to medium)
  ///
  /// Parameters:
  /// - [regex]: The regular expression to generate samples for
  /// - [maxSamples]: Maximum number of samples to generate (default: 10)
  /// - [maxLength]: Maximum length for generated strings (default: 20)
  /// - [contextAlphabet]: Universe used to expand wildcard and shortcut nodes
  ///   while generating samples
  ///
  /// Returns a [Result] containing [RegexSampleStrings] on success.
  ///
  /// Example:
  /// ```dart
  /// final result = RegexAnalyzer.generateSampleStrings('a*b+', maxSamples: 5);
  /// if (result.isSuccess) {
  ///   for (final sample in result.data!.samples) {
  ///     print('Sample: "$sample"');
  ///   }
  /// }
  /// ```
  static Result<RegexSampleStrings> generateSampleStrings(
    String regex, {
    int maxSamples = 10,
    int maxLength = 20,
    Set<String>? contextAlphabet,
  }) {
    try {
      final parseResult = _validateAndParse(regex);
      if (!parseResult.isSuccess) {
        return ResultFactory.failure(parseResult.error!);
      }
      final node = parseResult.data!;

      final samples = <String>{};
      final acceptsEmpty = _acceptsEmptyString(node);

      // Add empty string if accepted
      if (acceptsEmpty) {
        samples.add('');
      }

      // Find and add shortest string
      final shortest = _findShortestString(node, contextAlphabet);
      if (shortest != null && shortest.length <= maxLength) {
        samples.add(shortest);
      }

      // Generate random samples until we have enough unique ones
      int attempts = 0;
      final maxAttempts = maxSamples * 10; // Avoid infinite loops

      while (samples.length < maxSamples && attempts < maxAttempts) {
        attempts++;
        final sample = _generateSampleFromNode(
          node,
          maxLength,
          contextAlphabet,
        );
        if (sample != null && sample.length <= maxLength) {
          samples.add(sample);
        }
      }

      // Sort samples by length for better presentation
      final sortedSamples = samples.toList()
        ..sort((a, b) {
          final lenDiff = a.length.compareTo(b.length);
          if (lenDiff != 0) return lenDiff;
          return a.compareTo(b);
        });

      return ResultFactory.success(
        RegexSampleStrings(
          samples: sortedSamples,
          shortestString: shortest,
          acceptsEmptyString: acceptsEmpty,
        ),
      );
    } catch (e) {
      return ResultFactory.failure('Error generating sample strings: $e');
    }
  }

  /// Performs full analysis including sample string generation
  ///
  /// This is a convenience method that combines [analyze] and
  /// [generateSampleStrings] into a single call.
  ///
  /// Returns a [Result] containing [RegexAnalysis] with populated samples.
  static Result<RegexAnalysis> analyzeWithSamples(
    String regex, {
    int maxSamples = 10,
    int maxLength = 20,
    Set<String>? contextAlphabet,
  }) {
    final analysisResult = analyze(regex, contextAlphabet: contextAlphabet);
    if (analysisResult.isFailure) {
      return analysisResult;
    }

    final samplesResult = generateSampleStrings(
      regex,
      maxSamples: maxSamples,
      maxLength: maxLength,
      contextAlphabet: contextAlphabet,
    );
    if (samplesResult.isFailure) {
      return analysisResult; // Return analysis without samples if generation fails
    }

    return ResultFactory.success(
      analysisResult.data!.copyWith(sampleStrings: samplesResult.data),
    );
  }
}
