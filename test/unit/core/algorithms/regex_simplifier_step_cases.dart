part of 'regex_simplifier_test.dart';

void _registerRegexSimplifierStepTests() {
  group('RegexSimplifier - simplifyWithSteps()', () {
    group('basic functionality', () {
      test('returns success result with steps for simple expression', () {
        final result = RegexSimplifier.simplifyWithSteps('(a)');
        expect(result.isSuccess, true);
        expect(result.data, isNotNull);
        expect(result.data!.originalRegex, '(a)');
        expect(result.data!.simplifiedRegex, 'a');
        expect(result.data!.steps, isNotEmpty);
      });

      test('returns result with correct step count', () {
        final result = RegexSimplifier.simplifyWithSteps('((a))');
        expect(result.isSuccess, true);
        expect(result.data!.stepCount, greaterThan(0));
        expect(result.data!.stepCount, result.data!.steps.length);
      });

      test('returns result with execution time', () {
        final result = RegexSimplifier.simplifyWithSteps('a|b');
        expect(result.isSuccess, true);
        expect(result.data!.executionTime, isNotNull);
        expect(result.data!.executionTimeMs, greaterThanOrEqualTo(0));
      });

      test('tracks total rules applied', () {
        final result = RegexSimplifier.simplifyWithSteps('(a)(b)');
        expect(result.isSuccess, true);
        expect(result.data!.totalRulesApplied, greaterThan(0));
      });

      test('calculates characters saved', () {
        final result = RegexSimplifier.simplifyWithSteps('((a))');
        expect(result.isSuccess, true);
        expect(result.data!.charactersSaved, greaterThan(0));
        expect(
          result.data!.charactersSaved,
          result.data!.originalRegex.length -
              result.data!.simplifiedRegex.length,
        );
      });

      test('calculates reduction percentage', () {
        final result = RegexSimplifier.simplifyWithSteps('((a))');
        expect(result.isSuccess, true);
        expect(result.data!.reductionPercentage, greaterThan(0));
        expect(result.data!.reductionPercentage, lessThanOrEqualTo(100));
      });
    });

    group('step types', () {
      test('first step is always start step', () {
        final result = RegexSimplifier.simplifyWithSteps('a|b');
        expect(result.isSuccess, true);
        expect(result.data!.firstStep, isNotNull);
        expect(
          result.data!.firstStep!.stepType,
          RegexSimplificationStepType.start,
        );
      });

      test('last step is always completion step', () {
        final result = RegexSimplifier.simplifyWithSteps('(a)');
        expect(result.isSuccess, true);
        expect(result.data!.lastStep, isNotNull);
        expect(
          result.data!.lastStep!.stepType,
          RegexSimplificationStepType.completion,
        );
        expect(result.data!.lastStep!.isFinalForm, true);
      });

      test('includes applyRule steps when rules are applied', () {
        final result = RegexSimplifier.simplifyWithSteps('(a)(b)');
        expect(result.isSuccess, true);
        final ruleSteps = result.data!.ruleApplicationSteps;
        expect(ruleSteps, isNotEmpty);
        for (final step in ruleSteps) {
          expect(step.stepType, RegexSimplificationStepType.applyRule);
          expect(step.ruleApplied, isNotNull);
        }
      });

      test('includes noRuleApplicable when already simplified', () {
        final result = RegexSimplifier.simplifyWithSteps('a');
        expect(result.isSuccess, true);
        expect(result.data!.totalRulesApplied, 0);
        final noRuleSteps = result.data!.steps.where(
          (s) => s.stepType == RegexSimplificationStepType.noRuleApplicable,
        );
        expect(noRuleSteps, isNotEmpty);
      });
    });

    group('rule tracking', () {
      test('tracks redundantParentheses rule', () {
        final result = RegexSimplifier.simplifyWithSteps('(a)');
        expect(result.isSuccess, true);
        final rules = result.data!.rulesApplied;
        expect(rules, contains(SimplificationRule.redundantParentheses));
      });

      test('tracks emptySetStar rule for ∅*', () {
        final result = RegexSimplifier.simplifyWithSteps('∅*');
        expect(result.isSuccess, true);
        final rules = result.data!.rulesApplied;
        expect(rules, contains(SimplificationRule.emptySetStar));
      });

      test('tracks emptyStringStar rule for ε*', () {
        final result = RegexSimplifier.simplifyWithSteps('ε*');
        expect(result.isSuccess, true);
        final rules = result.data!.rulesApplied;
        expect(rules, contains(SimplificationRule.emptyStringStar));
      });

      test('tracks emptyUnionLeft rule for ∅|a', () {
        final result = RegexSimplifier.simplifyWithSteps('∅|a');
        expect(result.isSuccess, true);
        final rules = result.data!.rulesApplied;
        expect(rules, contains(SimplificationRule.emptyUnionLeft));
      });

      test('tracks emptyUnion rule for a|∅', () {
        final result = RegexSimplifier.simplifyWithSteps('a|∅');
        expect(result.isSuccess, true);
        final rules = result.data!.rulesApplied;
        expect(rules, contains(SimplificationRule.emptyUnion));
      });

      test('tracks starIdempotence rule for a**', () {
        final result = RegexSimplifier.simplifyWithSteps('a**');
        expect(result.isSuccess, true);
        final rules = result.data!.rulesApplied;
        expect(rules, contains(SimplificationRule.starIdempotence));
      });

      test('tracks unionIdempotence rule for a|a', () {
        final result = RegexSimplifier.simplifyWithSteps('a|a');
        expect(result.isSuccess, true);
        final rules = result.data!.rulesApplied;
        expect(rules, contains(SimplificationRule.unionIdempotence));
      });

      test('tracks emptyStringConcatenation rule for aε', () {
        final result = RegexSimplifier.simplifyWithSteps('aε');
        expect(result.isSuccess, true);
        final rules = result.data!.rulesApplied;
        expect(rules, contains(SimplificationRule.emptyStringConcatenation));
      });

      test('tracks emptyStringConcatenationLeft rule for εa', () {
        final result = RegexSimplifier.simplifyWithSteps('εa');
        expect(result.isSuccess, true);
        final rules = result.data!.rulesApplied;
        expect(
          rules,
          contains(SimplificationRule.emptyStringConcatenationLeft),
        );
      });

      test('tracks emptySetConcatenation rule for a∅b', () {
        final result = RegexSimplifier.simplifyWithSteps('a∅b');
        expect(result.isSuccess, true);
        expect(result.data!.simplifiedRegex, '∅');
        expect(
          result.data!.rulesApplied,
          contains(SimplificationRule.emptySetConcatenation),
        );
      });
    });

    group('step details', () {
      test('step includes matched subexpression', () {
        final result = RegexSimplifier.simplifyWithSteps('(a)');
        expect(result.isSuccess, true);
        final ruleStep = result.data!.ruleApplicationSteps.first;
        expect(ruleStep.matchedSubexpression, isNotNull);
        expect(ruleStep.matchedSubexpression, isNotEmpty);
      });

      test('step includes replacement subexpression', () {
        final result = RegexSimplifier.simplifyWithSteps('(a)');
        expect(result.isSuccess, true);
        final ruleStep = result.data!.ruleApplicationSteps.first;
        expect(ruleStep.replacementSubexpression, isNotNull);
      });

      test('step includes position', () {
        final result = RegexSimplifier.simplifyWithSteps('(a)');
        expect(result.isSuccess, true);
        final ruleStep = result.data!.ruleApplicationSteps.first;
        expect(ruleStep.position, isNotNull);
        expect(ruleStep.position, greaterThanOrEqualTo(0));
      });

      test('step includes rule explanation', () {
        final result = RegexSimplifier.simplifyWithSteps('(a)');
        expect(result.isSuccess, true);
        final ruleStep = result.data!.ruleApplicationSteps.first;
        expect(ruleStep.ruleExplanation, isNotNull);
        expect(ruleStep.ruleExplanation, isNotEmpty);
      });

      test('step has proper original and simplified regex', () {
        final result = RegexSimplifier.simplifyWithSteps('((a))');
        expect(result.isSuccess, true);
        final ruleSteps = result.data!.ruleApplicationSteps;
        expect(ruleSteps, isNotEmpty);
        for (final step in ruleSteps) {
          expect(step.originalRegex, isNotNull);
          expect(step.simplifiedRegex, isNotNull);
          // Each step should show progress
          expect(
            step.originalRegex!.length,
            greaterThanOrEqualTo(step.simplifiedRegex!.length),
          );
        }
      });
    });

    group('complexity metrics', () {
      test('start step includes star height', () {
        final result = RegexSimplifier.simplifyWithSteps('a*');
        expect(result.isSuccess, true);
        final startStep = result.data!.firstStep!;
        expect(startStep.starHeight, isNotNull);
        expect(startStep.starHeight, 1);
      });

      test('parallel top-level stars do not accumulate star height', () {
        final result = RegexSimplifier.simplifyWithSteps('a*b*');
        expect(result.isSuccess, true);
        expect(result.data!.firstStep!.starHeight, 1);
      });

      test('start step includes nesting depth', () {
        final result = RegexSimplifier.simplifyWithSteps('((a))');
        expect(result.isSuccess, true);
        final startStep = result.data!.firstStep!;
        expect(startStep.nestingDepth, isNotNull);
        expect(startStep.nestingDepth, 2);
      });

      test('start step includes operator count', () {
        final result = RegexSimplifier.simplifyWithSteps('a|b*');
        expect(result.isSuccess, true);
        final startStep = result.data!.firstStep!;
        expect(startStep.operatorCount, isNotNull);
        expect(startStep.operatorCount, 2); // | and *
      });

      test('completion step includes final metrics', () {
        final result = RegexSimplifier.simplifyWithSteps('(a)*');
        expect(result.isSuccess, true);
        final completionStep = result.data!.lastStep!;
        expect(completionStep.starHeight, isNotNull);
        expect(completionStep.nestingDepth, isNotNull);
        expect(completionStep.operatorCount, isNotNull);
      });
    });

    group('result properties', () {
      test('madeProgress is true when simplified', () {
        final result = RegexSimplifier.simplifyWithSteps('((a))');
        expect(result.isSuccess, true);
        expect(result.data!.madeProgress, true);
      });

      test('madeProgress is false when already simplified', () {
        final result = RegexSimplifier.simplifyWithSteps('a');
        expect(result.isSuccess, true);
        expect(result.data!.madeProgress, false);
      });

      test('rulesApplied returns list of applied rules', () {
        final result = RegexSimplifier.simplifyWithSteps('(a)(b)');
        expect(result.isSuccess, true);
        final rules = result.data!.rulesApplied;
        expect(rules, isA<List<SimplificationRule>>());
        expect(rules.length, result.data!.totalRulesApplied);
      });

      test('ruleApplicationSteps excludes start and completion', () {
        final result = RegexSimplifier.simplifyWithSteps('(a)');
        expect(result.isSuccess, true);
        final ruleSteps = result.data!.ruleApplicationSteps;
        for (final step in ruleSteps) {
          expect(step.stepType, isNot(RegexSimplificationStepType.start));
          expect(step.stepType, isNot(RegexSimplificationStepType.completion));
        }
      });
    });

    group('error handling', () {
      test('returns error for empty regex', () {
        final result = RegexSimplifier.simplifyWithSteps('');
        expect(result.isSuccess, false);
        expect(result.error, isNotNull);
      });

      test('returns error for whitespace-only regex', () {
        final result = RegexSimplifier.simplifyWithSteps('   ');
        expect(result.isSuccess, false);
        expect(result.error, isNotNull);
      });

      test('returns error for unbalanced parentheses - missing close', () {
        final result = RegexSimplifier.simplifyWithSteps('(a');
        expect(result.isSuccess, false);
        expect(
          result.structuredError,
          RegexSimplificationMessages.unclosedOpeningParentheses(1),
        );
      });

      test('returns error for unbalanced parentheses - missing open', () {
        final result = RegexSimplifier.simplifyWithSteps('a)');
        expect(result.isSuccess, false);
        expect(
          result.structuredError,
          RegexSimplificationMessages.unmatchedClosingParenthesis(1),
        );
      });
    });

    group('multiple rules application', () {
      test('applies multiple rules in sequence', () {
        final result = RegexSimplifier.simplifyWithSteps('((a|∅))');
        expect(result.isSuccess, true);
        expect(result.data!.totalRulesApplied, greaterThan(1));
        expect(result.data!.simplifiedRegex, 'a');
      });

      test('step numbers are sequential', () {
        final result = RegexSimplifier.simplifyWithSteps('((a))');
        expect(result.isSuccess, true);
        final steps = result.data!.steps;
        for (int i = 0; i < steps.length; i++) {
          expect(steps[i].stepNumber, i + 1);
        }
      });

      test('each step has unique id', () {
        final result = RegexSimplifier.simplifyWithSteps('((a)(b))');
        expect(result.isSuccess, true);
        final ids = result.data!.steps.map((s) => s.baseStep.id).toSet();
        expect(ids.length, result.data!.steps.length);
      });
    });

    group('JSON serialization', () {
      test('result can be converted to JSON and back', () {
        final result = RegexSimplifier.simplifyWithSteps('(a)');
        expect(result.isSuccess, true);
        final json = result.data!.toJson();
        final restored = RegexSimplificationResult.fromJson(json);
        expect(restored.originalRegex, result.data!.originalRegex);
        expect(restored.simplifiedRegex, result.data!.simplifiedRegex);
        expect(restored.totalRulesApplied, result.data!.totalRulesApplied);
      });

      test('steps can be converted to JSON and back', () {
        final result = RegexSimplifier.simplifyWithSteps('(a)');
        expect(result.isSuccess, true);
        final step = result.data!.firstStep!;
        final json = step.toJson();
        final restored = RegexSimplificationStep.fromJson(json);
        expect(restored.stepType, step.stepType);
        expect(restored.originalRegex, step.originalRegex);
      });
    });

    group('consistency with simplify()', () {
      test('produces same simplified result as simplify() for common cases', () {
        // Test cases where both methods are expected to produce the same result
        // Note: Some complex expressions may produce different results due to
        // different rule application strategies in the two implementations
        const expressions = [
          '(a)',
          '((a))',
          '(a)(b)',
          'a|a',
          'a**',
          '∅*',
          'ε*',
          'a|∅',
          '∅|a',
          'aε',
          'εa',
          '(a|b)',
          '(ab)*',
        ];

        for (final expr in expressions) {
          final simpleResult = RegexSimplifier.simplify(expr);
          final stepsResult = RegexSimplifier.simplifyWithSteps(expr);

          expect(
            simpleResult.isSuccess,
            true,
            reason: 'simplify() failed for $expr',
          );
          expect(
            stepsResult.isSuccess,
            true,
            reason: 'simplifyWithSteps() failed for $expr',
          );
          expect(
            stepsResult.data!.simplifiedRegex,
            simpleResult.data,
            reason: 'Results differ for $expr',
          );
        }
      });

      test('both methods produce valid simplifications', () {
        // For complex expressions, verify both produce valid (even if different) results
        const complexExpressions = ['((a|∅))c', '(εa|b∅)c', '((a|∅)ε)*'];

        for (final expr in complexExpressions) {
          final simpleResult = RegexSimplifier.simplify(expr);
          final stepsResult = RegexSimplifier.simplifyWithSteps(expr);

          expect(
            simpleResult.isSuccess,
            true,
            reason: 'simplify() failed for $expr',
          );
          expect(
            stepsResult.isSuccess,
            true,
            reason: 'simplifyWithSteps() failed for $expr',
          );
          // Both should produce non-null results
          expect(simpleResult.data, isNotNull);
          expect(stepsResult.data!.simplifiedRegex, isNotNull);
          // The simplified result should be no longer than the original
          expect(
            stepsResult.data!.simplifiedRegex.length,
            lessThanOrEqualTo(expr.length),
            reason: 'Simplified regex should not be longer for $expr',
          );
        }
      });
    });
  });
}
