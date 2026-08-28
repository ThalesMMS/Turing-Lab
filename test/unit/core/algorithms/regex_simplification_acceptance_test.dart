//
//  regex_simplification_acceptance_test.dart
//  Turing Lab
//
//  Acceptance criteria verification for Subtask 5-2:
//  Verify that '(a|∅)ε' simplifies to 'a' with step display
//  showing each rule applied (empty set removal, epsilon removal, parentheses removal)
//
//  Thales Matheus Mendonça Santos - January 2026
//

import 'package:flutter_test/flutter_test.dart';
import 'package:turing_lab/core/algorithms/regex_simplifier.dart';
import 'package:turing_lab/core/models/regex_simplification_step.dart';

void main() {
  group('Acceptance Criteria: Simplification rules with step display', () {
    test('(a|∅)ε simplifies to a', () {
      final result = RegexSimplifier.simplify('(a|∅)ε');
      expect(result.isSuccess, true);
      expect(result.data, 'a');
    });

    test('(a|∅)ε shows step-by-step simplification with rules applied', () {
      final result = RegexSimplifier.simplifyWithSteps('(a|∅)ε');
      expect(result.isSuccess, true);
      expect(result.data, isNotNull);

      final data = result.data!;

      // Verify the final result
      expect(data.originalRegex, '(a|∅)ε');
      expect(data.simplifiedRegex, 'a');

      // Verify that steps were captured
      expect(data.steps, isNotEmpty);
      expect(data.stepCount, greaterThan(1));

      // Verify first step is start
      expect(data.firstStep, isNotNull);
      expect(data.firstStep!.stepType, RegexSimplificationStepType.start);

      // Verify last step is completion
      expect(data.lastStep, isNotNull);
      expect(data.lastStep!.stepType, RegexSimplificationStepType.completion);
      expect(data.lastStep!.isFinalForm, true);

      // Verify rules were applied
      expect(data.totalRulesApplied, greaterThan(0));
      final ruleSteps = data.ruleApplicationSteps;
      expect(ruleSteps, isNotEmpty);

      // Verify each rule step has proper details
      for (final step in ruleSteps) {
        expect(step.ruleApplied, isNotNull);
        expect(step.originalRegex, isNotNull);
        expect(step.simplifiedRegex, isNotNull);
        expect(step.matchedSubexpression, isNotNull);
        expect(step.replacementSubexpression, isNotNull);
        expect(step.ruleExplanation, isNotNull);
        expect(step.ruleExplanation, isNotEmpty);
      }

      // Print step-by-step details for visual verification
      print('\\n=== Simplification of "(a|∅)ε" ===');
      print('Original: ${data.originalRegex}');
      print('Simplified: ${data.simplifiedRegex}');
      print('Total rules applied: ${data.totalRulesApplied}');
      print('Characters saved: ${data.charactersSaved}');
      print('Reduction: ${data.reductionPercentage.toStringAsFixed(1)}%');
      print('\\n--- Steps ---');
      for (final step in data.steps) {
        print('\\nStep ${step.stepNumber}: ${step.title}');
        if (step.appliesRule) {
          print('  Rule: ${step.ruleApplied!.displayName}');
          print('  Before: ${step.originalRegex}');
          print('  After: ${step.simplifiedRegex}');
          print(
            '  Match: "${step.matchedSubexpression}" → "${step.replacementSubexpression}"',
          );
          print('  Explanation: ${step.ruleExplanation}');
        } else {
          print('  ${step.explanation}');
        }
      }
    });

    test('simplification captures empty set removal rule', () {
      final result = RegexSimplifier.simplifyWithSteps('a|∅');
      expect(result.isSuccess, true);

      final rules = result.data!.rulesApplied;
      expect(
        rules,
        contains(SimplificationRule.emptyUnion),
        reason: 'Should capture empty set removal rule (r|∅ → r)',
      );
      expect(result.data!.simplifiedRegex, 'a');
    });

    test('simplification captures epsilon removal rule', () {
      final result = RegexSimplifier.simplifyWithSteps('aε');
      expect(result.isSuccess, true);

      final rules = result.data!.rulesApplied;
      expect(
        rules,
        contains(SimplificationRule.emptyStringConcatenation),
        reason: 'Should capture epsilon concatenation rule (rε → r)',
      );
      expect(result.data!.simplifiedRegex, 'a');
    });

    test('simplification captures parentheses removal rule', () {
      final result = RegexSimplifier.simplifyWithSteps('(a)');
      expect(result.isSuccess, true);

      final rules = result.data!.rulesApplied;
      expect(
        rules,
        contains(SimplificationRule.redundantParentheses),
        reason: 'Should capture parentheses removal rule',
      );
      expect(result.data!.simplifiedRegex, 'a');
    });

    test('each step shows before and after regex transformation', () {
      final result = RegexSimplifier.simplifyWithSteps('((a))');
      expect(result.isSuccess, true);

      final ruleSteps = result.data!.ruleApplicationSteps;
      expect(ruleSteps, isNotEmpty);

      for (final step in ruleSteps) {
        // Each step should show the transformation
        expect(step.originalRegex, isNotNull);
        expect(step.simplifiedRegex, isNotNull);
        // The simplified regex should be different from or equal to original
        // (when no change is made, they might be equal)
        expect(
          step.simplifiedRegex!.length,
          lessThanOrEqualTo(step.originalRegex!.length),
        );
      }
    });

    test('step explanations describe the rule being applied', () {
      final result = RegexSimplifier.simplifyWithSteps('a|∅');
      expect(result.isSuccess, true);

      final ruleSteps = result.data!.ruleApplicationSteps;
      expect(ruleSteps, isNotEmpty);

      final step = ruleSteps.first;
      expect(step.ruleExplanation, isNotEmpty);
      expect(
        step.ruleExplanation,
        step.ruleApplied!.descriptionMessage.stableCode,
      );
      expect(step.ruleExplanationMessage, step.ruleApplied!.descriptionMessage);
    });

    test('complex expression shows multiple rule applications', () {
      // This expression should require multiple rules:
      // 1. Empty set union: (a|∅) → a
      // 2. Epsilon concatenation: aε → a
      // And possibly parentheses removal at various stages
      final result = RegexSimplifier.simplifyWithSteps('(a|∅)ε');
      expect(result.isSuccess, true);

      final ruleSteps = result.data!.ruleApplicationSteps;

      // Should have at least 2 rules applied (empty set and epsilon removal)
      expect(
        ruleSteps.length,
        greaterThanOrEqualTo(2),
        reason: 'Multiple rules should be applied for "(a|∅)ε"',
      );

      // Collect the rules applied
      final rulesApplied = ruleSteps.map((s) => s.ruleApplied!).toSet();

      // Check that we see the expected rules (at least some of them)
      final hasEmptySetRule =
          rulesApplied.contains(SimplificationRule.emptyUnion) ||
          rulesApplied.contains(SimplificationRule.emptyUnionLeft);
      final hasEpsilonRule =
          rulesApplied.contains(SimplificationRule.emptyStringConcatenation) ||
          rulesApplied.contains(
            SimplificationRule.emptyStringConcatenationLeft,
          );

      expect(
        hasEmptySetRule || hasEpsilonRule,
        true,
        reason: 'Should apply empty set and/or epsilon removal rules',
      );
    });
  });
}
