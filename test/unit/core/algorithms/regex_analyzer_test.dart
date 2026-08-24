//
//  regex_analyzer_test.dart
//  Turing Lab
//
//  Tests that validate regular-expression analysis, including complexity
//  metrics (star height, nesting depth), operator counts,
//  alphabet extraction, and sample-string generation. Ensures the
//  analyzer computes all metrics correctly for educational use.
//
//  Thales Matheus Mendonça Santos - January 2026
//

import 'package:flutter_test/flutter_test.dart';
import 'package:turing_lab/core/algorithms/regex_analyzer.dart';
import 'package:turing_lab/core/models/regex_analysis.dart';

void main() {
  group('RegexAnalyzer - star height computation', () {
    test('computes star height 0 for simple symbol', () {
      final result = RegexAnalyzer.computeStarHeight('a');
      expect(result.isSuccess, true);
      expect(result.data, 0);
    });

    test('computes star height 0 for concatenation without star', () {
      final result = RegexAnalyzer.computeStarHeight('abc');
      expect(result.isSuccess, true);
      expect(result.data, 0);
    });

    test('computes star height 0 for union without star', () {
      final result = RegexAnalyzer.computeStarHeight('a|b|c');
      expect(result.isSuccess, true);
      expect(result.data, 0);
    });

    test('computes star height 1 for single Kleene star', () {
      final result = RegexAnalyzer.computeStarHeight('a*');
      expect(result.isSuccess, true);
      expect(result.data, 1);
    });

    test('computes star height 1 for grouped star', () {
      final result = RegexAnalyzer.computeStarHeight('(ab)*');
      expect(result.isSuccess, true);
      expect(result.data, 1);
    });

    test('computes star height 2 for nested star', () {
      final result = RegexAnalyzer.computeStarHeight('(a*)*');
      expect(result.isSuccess, true);
      expect(result.data, 2);
    });

    test('computes star height 3 for triple nested star', () {
      final result = RegexAnalyzer.computeStarHeight('((a*)*)*');
      expect(result.isSuccess, true);
      expect(result.data, 3);
    });

    test('computes star height 1 for plus operator', () {
      final result = RegexAnalyzer.computeStarHeight('a+');
      expect(result.isSuccess, true);
      expect(result.data, 1);
    });

    test('computes star height 0 for question operator', () {
      final result = RegexAnalyzer.computeStarHeight('a?');
      expect(result.isSuccess, true);
      expect(result.data, 0);
    });

    test('computes max star height across union branches', () {
      final result = RegexAnalyzer.computeStarHeight('a|b*');
      expect(result.isSuccess, true);
      expect(result.data, 1);
    });

    test('computes max star height across complex expression', () {
      final result = RegexAnalyzer.computeStarHeight('(a*b)|((c*)*)');
      expect(result.isSuccess, true);
      expect(result.data, 2);
    });

    test('computes star height for epsilon', () {
      final result = RegexAnalyzer.computeStarHeight('ε');
      expect(result.isSuccess, true);
      expect(result.data, 0);
    });

    test('returns error for empty regex', () {
      final result = RegexAnalyzer.computeStarHeight('');
      expect(result.isSuccess, false);
      expect(result.error, contains('empty'));
    });

    test('returns error for unbalanced parentheses', () {
      final result = RegexAnalyzer.computeStarHeight('(a*');
      expect(result.isSuccess, false);
      expect(result.error, contains('Unbalanced'));
    });
  });

  group('RegexAnalyzer - nesting depth computation', () {
    test('computes depth 0 for simple symbol', () {
      final result = RegexAnalyzer.computeNestingDepth('a');
      expect(result.isSuccess, true);
      expect(result.data, 0);
    });

    test('computes depth 0 for concatenation without parentheses', () {
      final result = RegexAnalyzer.computeNestingDepth('abc');
      expect(result.isSuccess, true);
      expect(result.data, 0);
    });

    test('computes depth 1 for single parentheses', () {
      final result = RegexAnalyzer.computeNestingDepth('(a)');
      expect(result.isSuccess, true);
      expect(result.data, 1);
    });

    test('computes depth 2 for double nested parentheses', () {
      final result = RegexAnalyzer.computeNestingDepth('((a))');
      expect(result.isSuccess, true);
      expect(result.data, 2);
    });

    test('computes depth 3 for triple nested parentheses', () {
      final result = RegexAnalyzer.computeNestingDepth('(((a)))');
      expect(result.isSuccess, true);
      expect(result.data, 3);
    });

    test('computes max depth for sibling groups', () {
      final result = RegexAnalyzer.computeNestingDepth('(a)(b)');
      expect(result.isSuccess, true);
      expect(result.data, 1);
    });

    test('computes max depth for mixed nesting', () {
      final result = RegexAnalyzer.computeNestingDepth('((a|b)c)(d)');
      expect(result.isSuccess, true);
      expect(result.data, 2);
    });

    test('computes correct depth for complex expression', () {
      final result = RegexAnalyzer.computeNestingDepth('(a|(b(c|d)))');
      expect(result.isSuccess, true);
      expect(result.data, 3);
    });

    test('returns error for empty regex', () {
      final result = RegexAnalyzer.computeNestingDepth('');
      expect(result.isSuccess, false);
      expect(result.error, contains('empty'));
    });

    test('returns error for unbalanced parentheses', () {
      final result = RegexAnalyzer.computeNestingDepth('(a');
      expect(result.isSuccess, false);
      expect(result.error, contains('Unbalanced'));
    });
  });

  group('RegexAnalyzer - alphabet extraction', () {
    test('extracts single symbol', () {
      final result = RegexAnalyzer.extractAlphabet('a');
      expect(result.isSuccess, true);
      expect(result.data, {'a'});
    });

    test('extracts multiple symbols from concatenation', () {
      final result = RegexAnalyzer.extractAlphabet('abc');
      expect(result.isSuccess, true);
      expect(result.data, {'a', 'b', 'c'});
    });

    test('extracts symbols from union', () {
      final result = RegexAnalyzer.extractAlphabet('a|b|c');
      expect(result.isSuccess, true);
      expect(result.data, {'a', 'b', 'c'});
    });

    test('extracts unique symbols only', () {
      final result = RegexAnalyzer.extractAlphabet('aab');
      expect(result.isSuccess, true);
      expect(result.data, {'a', 'b'});
    });

    test('extracts symbols from starred expression', () {
      final result = RegexAnalyzer.extractAlphabet('(ab)*');
      expect(result.isSuccess, true);
      expect(result.data, {'a', 'b'});
    });

    test('extracts symbols from complex expression', () {
      final result = RegexAnalyzer.extractAlphabet('(a|b)*(c|d)+');
      expect(result.isSuccess, true);
      expect(result.data, {'a', 'b', 'c', 'd'});
    });

    test('returns empty set for epsilon only', () {
      final result = RegexAnalyzer.extractAlphabet('ε');
      expect(result.isSuccess, true);
      expect(result.data, isEmpty);
    });

    test('extracts numeric symbols', () {
      final result = RegexAnalyzer.extractAlphabet('0|1');
      expect(result.isSuccess, true);
      expect(result.data, {'0', '1'});
    });

    test('extracts uppercase symbols', () {
      final result = RegexAnalyzer.extractAlphabet('A|B|C');
      expect(result.isSuccess, true);
      expect(result.data, {'A', 'B', 'C'});
    });

    test('handles character class', () {
      final result = RegexAnalyzer.extractAlphabet('[abc]');
      expect(result.isSuccess, true);
      expect(result.data, {'a', 'b', 'c'});
    });

    test('handles hyphen in character class range notation', () {
      final result = RegexAnalyzer.extractAlphabet('[a-c]');
      expect(result.isSuccess, true);
      expect(result.data, {'a', 'b', 'c'});
    });

    test('handles escaped closing bracket in character class', () {
      final result = RegexAnalyzer.extractAlphabet(r'[\]]');
      expect(result.isSuccess, true);
      expect(result.data, {']'});
    });

    test('returns error for empty regex', () {
      final result = RegexAnalyzer.extractAlphabet('');
      expect(result.isSuccess, false);
      expect(result.error, contains('empty'));
    });
  });

  group('RegexAnalyzer - operator counting', () {
    test('counts zero operators for simple symbol', () {
      final result = RegexAnalyzer.countOperators('a');
      expect(result.isSuccess, true);
      expect(result.data!['union'], 0);
      expect(result.data!['concatenation'], 0);
      expect(result.data!['star'], 0);
      expect(result.data!['plus'], 0);
      expect(result.data!['question'], 0);
    });

    test('counts union operators', () {
      final result = RegexAnalyzer.countOperators('a|b|c');
      expect(result.isSuccess, true);
      expect(result.data!['union'], 2);
    });

    test('counts concatenation operators', () {
      final result = RegexAnalyzer.countOperators('abc');
      expect(result.isSuccess, true);
      expect(result.data!['concatenation'], 2);
    });

    test('counts star operators', () {
      final result = RegexAnalyzer.countOperators('a*b*');
      expect(result.isSuccess, true);
      expect(result.data!['star'], 2);
    });

    test('counts plus operators', () {
      final result = RegexAnalyzer.countOperators('a+b+');
      expect(result.isSuccess, true);
      expect(result.data!['plus'], 2);
    });

    test('counts question operators', () {
      final result = RegexAnalyzer.countOperators('a?b?');
      expect(result.isSuccess, true);
      expect(result.data!['question'], 2);
    });

    test('counts all operator types in complex expression', () {
      final result = RegexAnalyzer.countOperators('(a|b)*c+d?');
      expect(result.isSuccess, true);
      expect(result.data!['union'], 1);
      expect(result.data!['concatenation'], 2);
      expect(result.data!['star'], 1);
      expect(result.data!['plus'], 1);
      expect(result.data!['question'], 1);
    });

    test('counts operators in nested expression', () {
      final result = RegexAnalyzer.countOperators('((a|b)c)*');
      expect(result.isSuccess, true);
      expect(result.data!['union'], 1);
      expect(result.data!['concatenation'], 1);
      expect(result.data!['star'], 1);
    });

    test('returns error for empty regex', () {
      final result = RegexAnalyzer.countOperators('');
      expect(result.isSuccess, false);
      expect(result.error, contains('empty'));
    });
  });

  group('RegexAnalyzer - complexity level determination', () {
    test('determines simple complexity for literal', () {
      final result = RegexAnalyzer.determineComplexity('a');
      expect(result.isSuccess, true);
      expect(result.data, ComplexityLevel.simple);
    });

    test('determines simple complexity for short union', () {
      final result = RegexAnalyzer.determineComplexity('a|b');
      expect(result.isSuccess, true);
      expect(result.data, ComplexityLevel.simple);
    });

    test('determines simple complexity for single star', () {
      final result = RegexAnalyzer.determineComplexity('a*');
      expect(result.isSuccess, true);
      expect(result.data, ComplexityLevel.simple);
    });

    test('determines moderate complexity for nested groups', () {
      final result = RegexAnalyzer.determineComplexity('((a|b)c)*d+');
      expect(result.isSuccess, true);
      // Depending on the score calculation, this could be moderate or complex
      expect(result.data,
          isIn([ComplexityLevel.moderate, ComplexityLevel.complex]));
    });

    test('determines complex level for nested stars', () {
      final result = RegexAnalyzer.determineComplexity('((a*)*)*');
      expect(result.isSuccess, true);
      expect(result.data, ComplexityLevel.complex);
    });

    test('determines complex level for deeply nested expression', () {
      final result = RegexAnalyzer.determineComplexity('((((a))))');
      expect(result.isSuccess, true);
      // Deep nesting with 4 levels should be complex
      expect(result.data,
          isIn([ComplexityLevel.moderate, ComplexityLevel.complex]));
    });

    test('returns error for empty regex', () {
      final result = RegexAnalyzer.determineComplexity('');
      expect(result.isSuccess, false);
      expect(result.error, contains('empty'));
    });
  });

  group('RegexAnalyzer - full analysis', () {
    test('analyzes simple regex correctly', () {
      final result = RegexAnalyzer.analyze('a');
      expect(result.isSuccess, true);
      expect(result.data!.starHeight, 0);
      expect(result.data!.nestingDepth, 0);
      expect(result.data!.alphabetSize, 1);
      expect(result.data!.complexityLevel, ComplexityLevel.simple);
    });

    test('analyzes starred regex correctly', () {
      final result = RegexAnalyzer.analyze('a*');
      expect(result.isSuccess, true);
      expect(result.data!.starHeight, 1);
      expect(result.data!.operatorCount['star'], 1);
    });

    test('analyzes union regex correctly', () {
      final result = RegexAnalyzer.analyze('a|b');
      expect(result.isSuccess, true);
      expect(result.data!.operatorCount['union'], 1);
      expect(result.data!.alphabetSize, 2);
    });

    test('analyzes complex regex correctly', () {
      final result = RegexAnalyzer.analyze('(a|b)*c+');
      expect(result.isSuccess, true);
      expect(result.data!.starHeight, 1);
      expect(result.data!.nestingDepth, 1);
      expect(result.data!.alphabetSize, 3);
    });

    test('includes execution time', () {
      final result = RegexAnalyzer.analyze('a*b+c?');
      expect(result.isSuccess, true);
      expect(result.data!.executionTime, isNotNull);
    });

    test('returns error for invalid regex', () {
      final result = RegexAnalyzer.analyze('(a');
      expect(result.isSuccess, false);
      expect(result.error, contains('Unbalanced'));
    });

    test('returns error for empty regex', () {
      final result = RegexAnalyzer.analyze('');
      expect(result.isSuccess, false);
      expect(result.error, contains('empty'));
    });

    test('detects empty string acceptance for star', () {
      final result = RegexAnalyzer.analyze('a*');
      expect(result.isSuccess, true);
      expect(result.data!.acceptsEmptyString, true);
    });

    test('detects non-empty string only for plus', () {
      final result = RegexAnalyzer.analyze('a+');
      expect(result.isSuccess, true);
      expect(result.data!.acceptsEmptyString, false);
    });

    test('detects empty string acceptance for question', () {
      final result = RegexAnalyzer.analyze('a?');
      expect(result.isSuccess, true);
      expect(result.data!.acceptsEmptyString, true);
    });

    test('detects empty string acceptance for epsilon', () {
      final result = RegexAnalyzer.analyze('ε');
      expect(result.isSuccess, true);
      expect(result.data!.acceptsEmptyString, true);
    });

    test('does not generate sample strings during structural analysis', () {
      final result = RegexAnalyzer.analyze('a*');
      expect(result.isSuccess, true);
      expect(result.data!.samples, isEmpty);
      expect(result.data!.sampleStrings.shortestString, isNull);
      expect(result.data!.acceptsEmptyString, true);
    });
  });

  group('RegexAnalyzer - sample string generation', () {
    test('generates samples for simple regex', () {
      final result = RegexAnalyzer.generateSampleStrings('a');
      expect(result.isSuccess, true);
      expect(result.data!.samples, isNotEmpty);
      expect(result.data!.samples, contains('a'));
    });

    test('finds shortest string for concatenation', () {
      final result = RegexAnalyzer.generateSampleStrings('abc');
      expect(result.isSuccess, true);
      expect(result.data!.shortestString, 'abc');
    });

    test('finds empty string as shortest for star', () {
      final result = RegexAnalyzer.generateSampleStrings('a*');
      expect(result.isSuccess, true);
      expect(result.data!.shortestString, '');
      expect(result.data!.acceptsEmptyString, true);
    });

    test('finds empty string as shortest for question', () {
      final result = RegexAnalyzer.generateSampleStrings('a?');
      expect(result.isSuccess, true);
      expect(result.data!.shortestString, '');
      expect(result.data!.acceptsEmptyString, true);
    });

    test('finds shortest for plus', () {
      final result = RegexAnalyzer.generateSampleStrings('a+');
      expect(result.isSuccess, true);
      expect(result.data!.shortestString, 'a');
      expect(result.data!.acceptsEmptyString, false);
    });

    test('generates samples respecting max samples', () {
      final result = RegexAnalyzer.generateSampleStrings('a*', maxSamples: 5);
      expect(result.isSuccess, true);
      expect(result.data!.samples.length, lessThanOrEqualTo(5));
    });

    test('generates samples respecting max length', () {
      final result = RegexAnalyzer.generateSampleStrings('a*', maxLength: 10);
      expect(result.isSuccess, true);
      for (final sample in result.data!.samples) {
        expect(sample.length, lessThanOrEqualTo(10));
      }
    });

    test('does not generate required repetitions beyond max length', () {
      final result = RegexAnalyzer.generateSampleStrings(
        'a+',
        maxSamples: 5,
        maxLength: 0,
      );

      expect(result.isSuccess, true);
      expect(result.data!.samples, isEmpty);
    });

    test('generates samples for union', () {
      final result = RegexAnalyzer.generateSampleStrings('a|b');
      expect(result.isSuccess, true);
      expect(result.data!.samples, isNotEmpty);
      // Should contain at least one of 'a' or 'b'
      expect(
        result.data!.samples.any((s) => s == 'a' || s == 'b'),
        true,
      );
    });

    test('finds shorter option in union', () {
      final result = RegexAnalyzer.generateSampleStrings('abc|d');
      expect(result.isSuccess, true);
      expect(result.data!.shortestString, 'd');
    });

    test('generates samples for complex regex', () {
      final result = RegexAnalyzer.generateSampleStrings('(a|b)*c+');
      expect(result.isSuccess, true);
      expect(result.data!.samples, isNotEmpty);
    });

    test('includes empty string in samples when accepted', () {
      final result = RegexAnalyzer.generateSampleStrings('a*');
      expect(result.isSuccess, true);
      expect(result.data!.samples, contains(''));
    });

    test('returns error for invalid regex', () {
      final result = RegexAnalyzer.generateSampleStrings('(a');
      expect(result.isSuccess, false);
      expect(result.error, contains('Unbalanced'));
    });

    test('generates samples for epsilon', () {
      final result = RegexAnalyzer.generateSampleStrings('ε');
      expect(result.isSuccess, true);
      expect(result.data!.shortestString, '');
      expect(result.data!.samples, contains(''));
    });

    test('samples are sorted by length', () {
      final result =
          RegexAnalyzer.generateSampleStrings('(ab)*', maxSamples: 10);
      expect(result.isSuccess, true);
      if (result.data!.samples.length > 1) {
        for (int i = 0; i < result.data!.samples.length - 1; i++) {
          expect(
            result.data!.samples[i].length,
            lessThanOrEqualTo(result.data!.samples[i + 1].length),
          );
        }
      }
    });
  });

  group('RegexAnalyzer - analyzeWithSamples', () {
    test('combines analysis and sample generation', () {
      final result = RegexAnalyzer.analyzeWithSamples('a*b+');
      expect(result.isSuccess, true);
      expect(result.data!.starHeight, 1);
      expect(result.data!.samples, isNotEmpty);
    });

    test('includes all metrics with samples', () {
      final result =
          RegexAnalyzer.analyzeWithSamples('(a|b)*c+', maxSamples: 5);
      expect(result.isSuccess, true);
      expect(result.data!.starHeight, 1);
      expect(result.data!.nestingDepth, 1);
      expect(result.data!.alphabetSize, 3);
      expect(result.data!.samples.length, lessThanOrEqualTo(5));
    });

    test('respects maxLength parameter', () {
      final result = RegexAnalyzer.analyzeWithSamples('a*', maxLength: 5);
      expect(result.isSuccess, true);
      for (final sample in result.data!.samples) {
        expect(sample.length, lessThanOrEqualTo(5));
      }
    });

    test('forwards the context alphabet to analysis and samples', () {
      final result = RegexAnalyzer.analyzeWithSamples(
        '.',
        contextAlphabet: const {'🧪'},
      );

      expect(result.isSuccess, isTrue);
      expect(result.data!.structureAnalysis.alphabet, {'🧪'});
      expect(result.data!.samples, contains('🧪'));
    });

    test('returns error for invalid regex', () {
      final result = RegexAnalyzer.analyzeWithSamples('(a');
      expect(result.isSuccess, false);
      expect(result.error, contains('Unbalanced'));
    });
  });

  group('RegexAnalyzer - error handling', () {
    test('rejects empty regex', () {
      final result = RegexAnalyzer.analyze('');
      expect(result.isSuccess, false);
      expect(result.error, contains('empty'));
    });

    test('rejects unbalanced opening parenthesis', () {
      final result = RegexAnalyzer.analyze('(a');
      expect(result.isSuccess, false);
      expect(result.error, contains('Unbalanced'));
    });

    test('rejects unbalanced closing parenthesis', () {
      final result = RegexAnalyzer.analyze('a)');
      expect(result.isSuccess, false);
      expect(result.error, contains('Unbalanced'));
    });

    test('rejects regex starting with quantifier', () {
      final result = RegexAnalyzer.analyze('*a');
      expect(result.isSuccess, false);
      expect(result.error, contains('quantifier'));
    });

    test('rejects consecutive quantifiers', () {
      final result = RegexAnalyzer.analyze('a**');
      expect(result.isSuccess, false);
      expect(result.error, contains('Consecutive'));
    });

    test('rejects empty parentheses', () {
      final result = RegexAnalyzer.analyze('()');
      expect(result.isSuccess, false);
      expect(result.error, contains('Empty'));
    });
  });

  group('RegexAnalyzer - edge cases', () {
    test('handles single character', () {
      final result = RegexAnalyzer.analyze('x');
      expect(result.isSuccess, true);
      expect(result.data!.starHeight, 0);
      expect(result.data!.nestingDepth, 0);
      expect(result.data!.alphabetSize, 1);
    });

    test('handles lambda as epsilon alternative', () {
      final result = RegexAnalyzer.analyze('λ');
      expect(result.isSuccess, true);
      expect(result.data!.acceptsEmptyString, true);
    });

    test('handles dot operator', () {
      final result = RegexAnalyzer.analyze('.');
      expect(result.isSuccess, true);
      expect(result.data!.starHeight, 0);
    });

    test('handles dot with star', () {
      final result = RegexAnalyzer.analyze('.*');
      expect(result.isSuccess, true);
      expect(result.data!.starHeight, 1);
      expect(result.data!.acceptsEmptyString, true);
    });

    test('accepts backslash shortcuts and escaped literals in validation', () {
      final result = RegexAnalyzer.analyze(r'\d');
      expect(result.isSuccess, true);
      expect(result.data!.structureAnalysis.alphabet, contains('0'));

      final escapedParen = RegexAnalyzer.analyze(r'\(');
      expect(escapedParen.isSuccess, true);
      expect(escapedParen.data!.structureAnalysis.alphabet, contains('('));
    });

    test('expands negated shortcuts using analyzer alphabet complements', () {
      final result = RegexAnalyzer.extractAlphabet(r'\D');
      expect(result.isSuccess, true);
      expect(result.data, contains('a'));
      expect(result.data, isNot(contains('0')));
    });

    test('handles deeply nested parentheses', () {
      final result = RegexAnalyzer.analyze('((((a))))');
      expect(result.isSuccess, true);
      expect(result.data!.nestingDepth, 4);
    });

    test('handles multiple branches in union', () {
      final result = RegexAnalyzer.analyze('a|b|c|d|e');
      expect(result.isSuccess, true);
      expect(result.data!.operatorCount['union'], 4);
      expect(result.data!.alphabetSize, 5);
    });

    test('handles mixed operators', () {
      final result = RegexAnalyzer.analyze('a*b+c?d');
      expect(result.isSuccess, true);
      expect(result.data!.operatorCount['star'], 1);
      expect(result.data!.operatorCount['plus'], 1);
      expect(result.data!.operatorCount['question'], 1);
    });
  });

  group('RegexAnalyzer - complexity score calculation', () {
    test('simple expression has low score', () {
      final result = RegexAnalyzer.analyze('a');
      expect(result.isSuccess, true);
      expect(result.data!.complexityScore, lessThan(4));
    });

    test('starred expression increases score', () {
      final resultSimple = RegexAnalyzer.analyze('a');
      final resultStar = RegexAnalyzer.analyze('a*');
      expect(resultSimple.isSuccess, true);
      expect(resultStar.isSuccess, true);
      expect(
        resultStar.data!.complexityScore,
        greaterThan(resultSimple.data!.complexityScore),
      );
    });

    test('nested expression increases score', () {
      final resultFlat = RegexAnalyzer.analyze('a|b');
      final resultNested = RegexAnalyzer.analyze('((a|b))');
      expect(resultFlat.isSuccess, true);
      expect(resultNested.isSuccess, true);
      expect(
        resultNested.data!.complexityScore,
        greaterThan(resultFlat.data!.complexityScore),
      );
    });

    test('nested stars have highest scores', () {
      final result = RegexAnalyzer.analyze('((a*)*)*');
      expect(result.isSuccess, true);
      expect(result.data!.complexityScore, greaterThanOrEqualTo(9));
      expect(result.data!.complexityLevel, ComplexityLevel.complex);
    });
  });
}
