//
//  regex_simplifier.dart
//  Turing Lab
//
//  Implementa simplificação de expressões regulares através da aplicação de
//  identidades algébricas e remoção de parênteses desnecessários. Recebe uma
//  expressão regular gerada pelo algoritmo de eliminação de estados e produz
//  uma versão equivalente mais legível, aplicando regras iterativamente até
//  atingir um ponto fixo.
//
//  Thales Matheus Mendonça Santos - January 2026
//
import 'package:collection/collection.dart';

import '../models/regex_simplification_step.dart';
import '../result.dart';
import '../utils/epsilon_utils.dart';

part 'regex_simplifier_steps.dart';
part 'regex_simplifier_parentheses.dart';
part 'regex_simplifier_identities.dart';
part 'regex_simplifier_models.dart';

/// Simplifies regular expressions by applying algebraic identities and removing unnecessary parentheses
class RegexSimplifier {
  /// Simplifies a regular expression to a more readable form
  ///
  /// Applies the following transformations:
  /// - Removes unnecessary parentheses (outer, nested, redundant)
  /// - Applies algebraic identities (∅, ε elimination, idempotence)
  /// - Iterates until a fixed point is reached (no more changes)
  ///
  /// Returns a [Result] containing the simplified regex string on success,
  /// or an error message on failure.
  static Result<String> simplify(String regex) {
    try {
      // Validate input
      final validationResult = _validateInput(regex);
      if (!validationResult.isSuccess) {
        return ResultFactory.failure(validationResult.error!);
      }

      // Handle empty regex
      if (regex.trim().isEmpty) {
        return ResultFactory.failure('Cannot simplify empty regex');
      }

      // Apply simplification rules iteratively
      String simplified = regex;
      String previous;

      // Iterate until fixed point (no more changes)
      do {
        previous = simplified;
        simplified = _removeRedundantParentheses(simplified);
        simplified = _applyAlgebraicIdentities(simplified);
      } while (simplified != previous);

      return ResultFactory.success(simplified);
    } catch (e) {
      return ResultFactory.failure('Error simplifying regex: $e');
    }
  }

  /// Simplifies a regular expression with step-by-step information
  ///
  /// Similar to [simplify], but captures each transformation as a step
  /// with before/after regex and rule explanation. This enables educational
  /// visualization of the simplification process.
  ///
  /// Returns a [Result] containing [RegexSimplificationResult] on success,
  /// which includes the simplified regex, all steps, and execution time.
  static Result<RegexSimplificationResult> simplifyWithSteps(String regex) {
    try {
      final stopwatch = Stopwatch()..start();
      final steps = <RegexSimplificationStep>[];
      int stepCounter = 1;
      int totalRulesApplied = 0;

      // Validate input
      final validationResult = _validateInput(regex);
      if (!validationResult.isSuccess) {
        return ResultFactory.failure(validationResult.error!);
      }

      // Handle empty regex
      if (regex.trim().isEmpty) {
        return ResultFactory.failure('Cannot simplify empty regex');
      }

      // Compute initial complexity metrics
      final initialStarHeight = _computeStarHeight(regex);
      final initialNestingDepth = _computeNestingDepth(regex);
      final initialOperatorCount = _countOperators(regex);

      // Add start step
      steps.add(
        RegexSimplificationStep.start(
          id: 'step_$stepCounter',
          stepNumber: stepCounter++,
          regex: regex,
          starHeight: initialStarHeight,
          nestingDepth: initialNestingDepth,
          operatorCount: initialOperatorCount,
        ),
      );

      // Apply simplification rules iteratively with step capture
      String simplified = regex;
      String previous;

      do {
        previous = simplified;

        // Try to apply parentheses removal rules
        final parenResult = _applyParenthesesRemovalWithStep(
          simplified,
          stepCounter,
          totalRulesApplied,
        );
        if (parenResult != null) {
          simplified = parenResult.newRegex;
          steps.add(parenResult.step);
          stepCounter++;
          totalRulesApplied++;
          continue;
        }

        // Try to apply algebraic identities
        final algebraicResult = _applyAlgebraicIdentityWithStep(
          simplified,
          stepCounter,
          totalRulesApplied,
        );
        if (algebraicResult != null) {
          simplified = algebraicResult.newRegex;
          steps.add(algebraicResult.step);
          stepCounter++;
          totalRulesApplied++;
          continue;
        }
      } while (simplified != previous);

      // Add no-rule-applicable step if we didn't apply any rules
      if (totalRulesApplied == 0) {
        steps.add(
          RegexSimplificationStep.noRuleApplicable(
            id: 'step_$stepCounter',
            stepNumber: stepCounter++,
            regex: simplified,
            totalRulesApplied: totalRulesApplied,
          ),
        );
      }

      // Compute final complexity metrics
      final finalStarHeight = _computeStarHeight(simplified);
      final finalNestingDepth = _computeNestingDepth(simplified);
      final finalOperatorCount = _countOperators(simplified);

      // Add completion step
      steps.add(
        RegexSimplificationStep.completion(
          id: 'step_$stepCounter',
          stepNumber: stepCounter,
          originalRegex: regex,
          finalRegex: simplified,
          totalRulesApplied: totalRulesApplied,
          starHeight: finalStarHeight,
          nestingDepth: finalNestingDepth,
          operatorCount: finalOperatorCount,
        ),
      );

      stopwatch.stop();

      final result = RegexSimplificationResult(
        originalRegex: regex,
        simplifiedRegex: simplified,
        steps: steps,
        executionTime: stopwatch.elapsed,
        totalRulesApplied: totalRulesApplied,
      );

      return ResultFactory.success(result);
    } catch (e) {
      return ResultFactory.failure('Error simplifying regex with steps: $e');
    }
  }
}
