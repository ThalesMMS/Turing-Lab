//
//  regex_sample_generation_acceptance_test.dart
//  Turing Lab
//
//  Acceptance tests that verify generated sample strings actually match
//  their source regular expressions. Uses regex-to-NFA conversion and
//  automaton simulation to validate each generated sample.
//
//  Thales Matheus Mendonça Santos - January 2026
//

import 'package:flutter_test/flutter_test.dart';
import 'package:turing_lab/core/algorithms/regex_analyzer.dart';
import 'package:turing_lab/core/algorithms/regex_to_nfa_converter.dart';
import 'package:turing_lab/core/algorithms/automaton_simulator.dart';

void main() {
  group('Sample String Generation Acceptance Tests', () {
    /// Helper function that validates all generated samples match the regex
    Future<void> validateSamplesMatchRegex(
      String regex, {
      int maxSamples = 10,
      int maxLength = 20,
    }) async {
      // Generate sample strings
      final samplesResult = RegexAnalyzer.generateSampleStrings(
        regex,
        maxSamples: maxSamples,
        maxLength: maxLength,
      );
      expect(
        samplesResult.isSuccess,
        true,
        reason:
            'Failed to generate samples for "$regex": ${samplesResult.error}',
      );
      expect(samplesResult.data!.samples, isNotEmpty,
          reason: 'No samples generated for "$regex"');

      // Convert regex to NFA
      final nfaResult = RegexToNFAConverter.convert(regex);
      expect(
        nfaResult.isSuccess,
        true,
        reason: 'Failed to convert "$regex" to NFA: ${nfaResult.error}',
      );

      final nfa = nfaResult.data!;

      // Validate each sample matches the regex
      for (final sample in samplesResult.data!.samples) {
        final simResult = await AutomatonSimulator.simulate(nfa, sample);
        expect(
          simResult.isSuccess,
          true,
          reason:
              'Simulation failed for sample "$sample" from regex "$regex": ${simResult.error}',
        );
        expect(
          simResult.data!.accepted,
          true,
          reason:
              'Sample "$sample" was generated but NOT accepted by regex "$regex"',
        );
      }
    }

    test('a*b+ generates samples matching pattern (e.g., b, ab, aab, abbb)',
        () async {
      // This is the key acceptance criterion from the spec
      await validateSamplesMatchRegex('a*b+');

      // Also verify we get the expected structure of samples
      final result = RegexAnalyzer.generateSampleStrings('a*b+');
      expect(result.isSuccess, true);

      // Verify shortest string is 'b' (a* = 0 a's, b+ = 1 b)
      expect(result.data!.shortestString, 'b');

      // Verify samples exist and follow the pattern
      for (final sample in result.data!.samples) {
        // Sample should be zero or more 'a's followed by one or more 'b's
        expect(
          RegExp(r'^a*b+$').hasMatch(sample),
          true,
          reason: 'Sample "$sample" does not match pattern a*b+',
        );
      }
    });

    test('simple symbol generates matching samples', () async {
      await validateSamplesMatchRegex('a');
    });

    test('concatenation generates matching samples', () async {
      await validateSamplesMatchRegex('abc');
    });

    test('union generates matching samples', () async {
      await validateSamplesMatchRegex('a|b');
    });

    test('Kleene star generates matching samples', () async {
      await validateSamplesMatchRegex('a*');

      // Verify empty string is included for star
      final result = RegexAnalyzer.generateSampleStrings('a*');
      expect(result.data!.samples, contains(''));
    });

    test('plus generates matching samples', () async {
      await validateSamplesMatchRegex('a+');

      // Verify shortest string is 'a' (at least one)
      final result = RegexAnalyzer.generateSampleStrings('a+');
      expect(result.data!.shortestString, 'a');
    });

    test('question generates matching samples', () async {
      await validateSamplesMatchRegex('a?');

      // Verify empty string is included for question
      final result = RegexAnalyzer.generateSampleStrings('a?');
      expect(result.data!.samples, contains(''));
    });

    test('(a|b)* generates matching samples', () async {
      await validateSamplesMatchRegex('(a|b)*');

      // Verify samples only contain a's and b's
      final result = RegexAnalyzer.generateSampleStrings('(a|b)*');
      for (final sample in result.data!.samples) {
        expect(
          RegExp(r'^[ab]*$').hasMatch(sample),
          true,
          reason: 'Sample "$sample" contains invalid characters for (a|b)*',
        );
      }
    });

    test('(ab)+ generates matching samples', () async {
      await validateSamplesMatchRegex('(ab)+');

      // Verify samples are concatenations of 'ab'
      final result = RegexAnalyzer.generateSampleStrings('(ab)+');
      for (final sample in result.data!.samples) {
        expect(
          sample.length % 2,
          0,
          reason: 'Sample "$sample" should have even length for (ab)+',
        );
        expect(
          RegExp(r'^(ab)+$').hasMatch(sample),
          true,
          reason: 'Sample "$sample" does not match pattern (ab)+',
        );
      }
    });

    test('a*b*c* generates matching samples', () async {
      await validateSamplesMatchRegex('a*b*c*');

      // Verify samples follow the pattern
      final result = RegexAnalyzer.generateSampleStrings('a*b*c*');
      for (final sample in result.data!.samples) {
        expect(
          RegExp(r'^a*b*c*$').hasMatch(sample),
          true,
          reason: 'Sample "$sample" does not match pattern a*b*c*',
        );
      }
    });

    test('(a|b)*c+ generates matching samples', () async {
      await validateSamplesMatchRegex('(a|b)*c+');
    });

    test('((a|b)*c)+d? generates matching samples', () async {
      await validateSamplesMatchRegex('((a|b)*c)+d?');
    });

    test('a(b|c)*d generates matching samples', () async {
      await validateSamplesMatchRegex('a(b|c)*d');

      // Verify samples start with 'a' and end with 'd'
      final result = RegexAnalyzer.generateSampleStrings('a(b|c)*d');
      for (final sample in result.data!.samples) {
        expect(sample.startsWith('a'), true);
        expect(sample.endsWith('d'), true);
      }
    });

    test('epsilon generates only empty string', () async {
      final result = RegexAnalyzer.generateSampleStrings('ε');
      expect(result.isSuccess, true);
      expect(result.data!.samples, contains(''));
      expect(result.data!.shortestString, '');
      expect(result.data!.acceptsEmptyString, true);
    });

    test('nested stars (a*)* generates matching samples', () async {
      await validateSamplesMatchRegex('(a*)*');

      // All samples should only contain 'a's
      final result = RegexAnalyzer.generateSampleStrings('(a*)*');
      for (final sample in result.data!.samples) {
        expect(
          RegExp(r'^a*$').hasMatch(sample),
          true,
          reason: 'Sample "$sample" should only contain a\'s for (a*)*',
        );
      }
    });

    test('character classes [abc] generate matching samples', () async {
      await validateSamplesMatchRegex('[abc]');

      // Verify samples are single characters from the class
      final result = RegexAnalyzer.generateSampleStrings('[abc]');
      for (final sample in result.data!.samples) {
        expect(
          {'a', 'b', 'c'},
          contains(sample),
          reason: 'Sample "$sample" should be one of a, b, c',
        );
      }
    });

    test('character class with star [abc]* generates matching samples',
        () async {
      await validateSamplesMatchRegex('[abc]*');
    });

    test('complex nested expression generates matching samples', () async {
      await validateSamplesMatchRegex('((a|b)c)*d+');
    });

    test('samples are sorted by length', () {
      final result =
          RegexAnalyzer.generateSampleStrings('(ab)*', maxSamples: 10);
      expect(result.isSuccess, true);

      final samples = result.data!.samples;
      for (int i = 0; i < samples.length - 1; i++) {
        expect(
          samples[i].length,
          lessThanOrEqualTo(samples[i + 1].length),
          reason:
              'Samples not sorted by length: "${samples[i]}" before "${samples[i + 1]}"',
        );
      }
    });

    test('respects maxLength constraint', () async {
      final result = RegexAnalyzer.generateSampleStrings(
        'a*',
        maxLength: 5,
        maxSamples: 20,
      );
      expect(result.isSuccess, true);

      for (final sample in result.data!.samples) {
        expect(
          sample.length,
          lessThanOrEqualTo(5),
          reason: 'Sample "$sample" exceeds maxLength of 5',
        );
      }
    });

    test('respects maxSamples constraint', () {
      final result = RegexAnalyzer.generateSampleStrings(
        '(a|b)*',
        maxSamples: 5,
      );
      expect(result.isSuccess, true);
      expect(
        result.data!.samples.length,
        lessThanOrEqualTo(5),
        reason: 'Generated more than maxSamples',
      );
    });

    test('0*1+ generates binary pattern samples', () async {
      await validateSamplesMatchRegex('0*1+');

      final result = RegexAnalyzer.generateSampleStrings('0*1+');
      expect(result.data!.shortestString, '1');

      for (final sample in result.data!.samples) {
        expect(
          RegExp(r'^0*1+$').hasMatch(sample),
          true,
          reason: 'Sample "$sample" does not match binary pattern 0*1+',
        );
      }
    });

    test('(0|1)* generates all binary strings', () async {
      await validateSamplesMatchRegex('(0|1)*');

      final result = RegexAnalyzer.generateSampleStrings('(0|1)*');
      expect(result.data!.samples, contains(''));

      for (final sample in result.data!.samples) {
        expect(
          RegExp(r'^[01]*$').hasMatch(sample),
          true,
          reason: 'Sample "$sample" should be a binary string',
        );
      }
    });

    test('dot operator generates various characters', () async {
      final result = RegexAnalyzer.generateSampleStrings('.');
      expect(result.isSuccess, true);
      expect(result.data!.samples, isNotEmpty);

      // Each sample should be a single character
      for (final sample in result.data!.samples) {
        expect(sample.length, 1);
      }
    });

    test('analyzeWithSamples returns validated samples', () async {
      final result = RegexAnalyzer.analyzeWithSamples('a*b+');
      expect(result.isSuccess, true);
      expect(result.data!.samples, isNotEmpty);

      // Convert to NFA and validate
      final nfaResult = RegexToNFAConverter.convert('a*b+');
      expect(nfaResult.isSuccess, true);

      for (final sample in result.data!.samples) {
        final simResult =
            await AutomatonSimulator.simulate(nfaResult.data!, sample);
        expect(simResult.isSuccess, true);
        expect(simResult.data!.accepted, true,
            reason: 'Sample "$sample" should be accepted');
      }
    });
  });
}
