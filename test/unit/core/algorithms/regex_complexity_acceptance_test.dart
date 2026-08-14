//
//  regex_complexity_acceptance_test.dart
//  Turing Lab
//
//  Acceptance tests for regex complexity analysis verifying star height,
//  nesting depth, and complexity level calculations.
//
//  Thales Matheus Mendonça Santos - January 2026
//

import 'package:flutter_test/flutter_test.dart';
import 'package:turing_lab/core/algorithms/regex_analyzer.dart';
import 'package:turing_lab/core/models/regex_analysis.dart';

void main() {
  group('Regex Complexity Analysis - Acceptance Criteria', () {
    group('Star Height Computation', () {
      test('simple symbol has star height 0', () {
        final result = RegexAnalyzer.computeStarHeight('a');
        expect(result.isSuccess, isTrue);
        expect(result.data, equals(0));
      });

      test('a* has star height 1', () {
        final result = RegexAnalyzer.computeStarHeight('a*');
        expect(result.isSuccess, isTrue);
        expect(result.data, equals(1));
      });

      test('(a*)* has star height 2 (nested stars)', () {
        final result = RegexAnalyzer.computeStarHeight('(a*)*');
        expect(result.isSuccess, isTrue);
        expect(result.data, equals(2));
      });

      test('((a*)*)* has star height 3 (deeply nested stars)', () {
        final result = RegexAnalyzer.computeStarHeight('((a*)*)*');
        expect(result.isSuccess, isTrue);
        expect(result.data, equals(3));
      });

      test('(a|b)* has star height 1', () {
        final result = RegexAnalyzer.computeStarHeight('(a|b)*');
        expect(result.isSuccess, isTrue);
        expect(result.data, equals(1));
      });

      test('a*b* has star height 1 (parallel stars, no nesting)', () {
        final result = RegexAnalyzer.computeStarHeight('a*b*');
        expect(result.isSuccess, isTrue);
        expect(result.data, equals(1));
      });

      test('a+ has star height 1 (plus counts as star)', () {
        final result = RegexAnalyzer.computeStarHeight('a+');
        expect(result.isSuccess, isTrue);
        expect(result.data, equals(1));
      });

      test('a? has star height 0 (question mark does not count)', () {
        final result = RegexAnalyzer.computeStarHeight('a?');
        expect(result.isSuccess, isTrue);
        expect(result.data, equals(0));
      });

      test('(a*c)+ has star height 2 (star inside plus)', () {
        // Star inside plus: inner star=1, plus adds 1 = 2
        final result = RegexAnalyzer.computeStarHeight('(a*c)+');
        expect(result.isSuccess, isTrue);
        expect(result.data, equals(2));
      });
    });

    group('Nesting Depth Computation', () {
      test('simple symbol has nesting depth 0', () {
        final result = RegexAnalyzer.computeNestingDepth('a');
        expect(result.isSuccess, isTrue);
        expect(result.data, equals(0));
      });

      test('(a) has nesting depth 1', () {
        final result = RegexAnalyzer.computeNestingDepth('(a)');
        expect(result.isSuccess, isTrue);
        expect(result.data, equals(1));
      });

      test('((a)) has nesting depth 2', () {
        final result = RegexAnalyzer.computeNestingDepth('((a))');
        expect(result.isSuccess, isTrue);
        expect(result.data, equals(2));
      });

      test('(((a))) has nesting depth 3', () {
        final result = RegexAnalyzer.computeNestingDepth('(((a)))');
        expect(result.isSuccess, isTrue);
        expect(result.data, equals(3));
      });

      test('(a)(b) has nesting depth 1 (sequential groups)', () {
        final result = RegexAnalyzer.computeNestingDepth('(a)(b)');
        expect(result.isSuccess, isTrue);
        expect(result.data, equals(1));
      });

      test('((a|b)*c)+ has nesting depth 2', () {
        // Outer ( for +, inner ( for union
        final result = RegexAnalyzer.computeNestingDepth('((a|b)*c)+');
        expect(result.isSuccess, isTrue);
        expect(result.data, equals(2));
      });

      test('(a|b)* has nesting depth 1', () {
        final result = RegexAnalyzer.computeNestingDepth('(a|b)*');
        expect(result.isSuccess, isTrue);
        expect(result.data, equals(1));
      });
    });

    group('Key Acceptance Test Case: ((a|b)*c)+', () {
      // This is the specific test case from the acceptance criteria
      late RegexAnalysis analysis;

      setUpAll(() {
        final result = RegexAnalyzer.analyze('((a|b)*c)+');
        expect(result.isSuccess, isTrue, reason: 'Analysis should succeed');
        analysis = result.data!;
      });

      test('nesting depth shows 2', () {
        // Acceptance criteria: nesting depth shows 2
        expect(analysis.nestingDepth, equals(2));
      });

      test('star height computation is correct', () {
        // The regex ((a|b)*c)+ has:
        // - (a|b) has star height 0
        // - (a|b)* has star height 1 (star adds 1)
        // - (a|b)*c has star height 1 (concatenation takes max)
        // - ((a|b)*c)+ has star height 2 (plus adds 1 to inner max)
        //
        // Note: Plus (r+) is equivalent to rr* so it contains a star.
        // The implementation counts plus as adding to star height.
        expect(analysis.starHeight, equals(2));
      });

      test('complexity analysis is displayed correctly', () {
        // With star height 2 and nesting depth 2, this should be moderate/complex
        expect(
          analysis.complexityLevel,
          anyOf([ComplexityLevel.moderate, ComplexityLevel.complex]),
        );
        expect(analysis.complexityScore, greaterThan(0));
      });

      test('alphabet is extracted correctly', () {
        expect(
            analysis.structureAnalysis.alphabet, containsAll(['a', 'b', 'c']));
        expect(analysis.alphabetSize, equals(3));
      });

      test('operators are counted correctly', () {
        final ops = analysis.operatorCount;
        expect(ops['union'], equals(1)); // a|b
        expect(ops['star'], equals(1)); // (a|b)*
        expect(ops['plus'], equals(1)); // +
        expect(ops['concatenation'], greaterThanOrEqualTo(1)); // *c
      });
    });

    group('Complexity Level Determination', () {
      test('simple regex has simple complexity', () {
        final result = RegexAnalyzer.determineComplexity('a');
        expect(result.isSuccess, isTrue);
        expect(result.data, equals(ComplexityLevel.simple));
      });

      test('a* is simple complexity', () {
        final result = RegexAnalyzer.determineComplexity('a*');
        expect(result.isSuccess, isTrue);
        expect(result.data, equals(ComplexityLevel.simple));
      });

      test('(a|b)* is simple or moderate complexity', () {
        // (a|b)* has star height 1, nesting depth 1, 2 operators
        // Score = (1*3) + (1*2) + (2/2) = 6, which exceeds simple threshold (3)
        // but qualifies for moderate (score <= 8)
        final result = RegexAnalyzer.determineComplexity('(a|b)*');
        expect(result.isSuccess, isTrue);
        expect(
          result.data,
          anyOf([ComplexityLevel.simple, ComplexityLevel.moderate]),
        );
      });

      test('nested stars increase complexity', () {
        final result = RegexAnalyzer.determineComplexity('(a*)*');
        expect(result.isSuccess, isTrue);
        // Star height 2 should be at least moderate
        expect(
          result.data,
          anyOf([ComplexityLevel.moderate, ComplexityLevel.complex]),
        );
      });

      test('deeply nested expression is complex', () {
        final result = RegexAnalyzer.determineComplexity('(((a*)*b)*c)*');
        expect(result.isSuccess, isTrue);
        expect(result.data, equals(ComplexityLevel.complex));
      });
    });

    group('Full Analysis Integration', () {
      test('analyze returns all metrics for simple regex', () {
        final result = RegexAnalyzer.analyze('ab');
        expect(result.isSuccess, isTrue);

        final analysis = result.data!;
        expect(analysis.starHeight, equals(0));
        expect(analysis.nestingDepth, equals(0));
        expect(analysis.complexityLevel, equals(ComplexityLevel.simple));
        expect(analysis.alphabetSize, equals(2));
        expect(analysis.structureAnalysis.alphabet, containsAll(['a', 'b']));
      });

      test('analyze returns all metrics for complex regex', () {
        final result = RegexAnalyzer.analyze('((a|b)*c(d|e)+)*');
        expect(result.isSuccess, isTrue);

        final analysis = result.data!;
        expect(analysis.starHeight, greaterThanOrEqualTo(2));
        expect(analysis.nestingDepth, greaterThanOrEqualTo(2));
        expect(analysis.alphabetSize, equals(5)); // a, b, c, d, e
      });

      test('analyzeWithSamples includes sample strings', () {
        final result = RegexAnalyzer.analyzeWithSamples('a*b');
        expect(result.isSuccess, isTrue);

        final analysis = result.data!;
        expect(analysis.samples, isNotEmpty);
        // All samples should contain 'b' (required)
        for (final sample in analysis.samples) {
          expect(sample.contains('b'), isTrue);
        }
      });
    });

    group('ComplexityLevel Extension Methods', () {
      test('displayName returns human-readable text', () {
        expect(ComplexityLevel.simple.displayName, equals('Simple'));
        expect(ComplexityLevel.moderate.displayName, equals('Moderate'));
        expect(ComplexityLevel.complex.displayName, equals('Complex'));
      });

      test('description provides explanation', () {
        expect(ComplexityLevel.simple.description, contains('Easy'));
        expect(ComplexityLevel.moderate.description, contains('Moderate'));
        expect(ComplexityLevel.complex.description, contains('High'));
      });

      test('colorHint returns valid hex colors', () {
        final hexPattern = RegExp(r'^#[0-9A-Fa-f]{6}$');
        expect(hexPattern.hasMatch(ComplexityLevel.simple.colorHint), isTrue);
        expect(hexPattern.hasMatch(ComplexityLevel.moderate.colorHint), isTrue);
        expect(hexPattern.hasMatch(ComplexityLevel.complex.colorHint), isTrue);
      });

      test('iconHint returns valid icon names', () {
        expect(ComplexityLevel.simple.iconHint, isNotEmpty);
        expect(ComplexityLevel.moderate.iconHint, isNotEmpty);
        expect(ComplexityLevel.complex.iconHint, isNotEmpty);
      });
    });

    group('Edge Cases', () {
      test('empty regex returns error', () {
        final result = RegexAnalyzer.analyze('');
        expect(result.isFailure, isTrue);
      });

      test('epsilon symbol has star height 0', () {
        final result = RegexAnalyzer.analyze('ε');
        expect(result.isSuccess, isTrue);
        expect(result.data!.starHeight, equals(0));
      });

      test('empty set symbol has star height 0', () {
        final result = RegexAnalyzer.analyze('∅');
        expect(result.isSuccess, isTrue);
        expect(result.data!.starHeight, equals(0));
      });

      test('character class has star height 0', () {
        final result = RegexAnalyzer.analyze('[abc]');
        expect(result.isSuccess, isTrue);
        expect(result.data!.starHeight, equals(0));
      });

      test('character class with star has star height 1', () {
        final result = RegexAnalyzer.analyze('[abc]*');
        expect(result.isSuccess, isTrue);
        expect(result.data!.starHeight, equals(1));
      });
    });

    group('JSON Serialization', () {
      test('RegexAnalysis round-trips through JSON', () {
        final result = RegexAnalyzer.analyze('(a|b)*c');
        expect(result.isSuccess, isTrue);

        final original = result.data!;
        final json = original.toJson();
        final restored = RegexAnalysis.fromJson(json);

        expect(restored.starHeight, equals(original.starHeight));
        expect(restored.nestingDepth, equals(original.nestingDepth));
        expect(restored.complexityLevel, equals(original.complexityLevel));
        expect(restored.alphabetSize, equals(original.alphabetSize));
      });

      test('RegexComplexityAnalysis round-trips through JSON', () {
        final original = RegexComplexityAnalysis.fromMetrics(
          starHeight: 2,
          nestingDepth: 3,
          operatorTotal: 5,
          length: 15,
        );

        final json = original.toJson();
        final restored = RegexComplexityAnalysis.fromJson(json);

        expect(restored.starHeight, equals(original.starHeight));
        expect(restored.nestingDepth, equals(original.nestingDepth));
        expect(restored.complexityScore, equals(original.complexityScore));
        expect(restored.complexityLevel, equals(original.complexityLevel));
      });
    });
  });
}
