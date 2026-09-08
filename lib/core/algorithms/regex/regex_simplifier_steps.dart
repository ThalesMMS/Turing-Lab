part of 'regex_simplifier.dart';

/// Helper class for step application results
_StepApplicationResult? _applyParenthesesRemovalWithStep(
  String regex,
  int stepNumber,
  int totalRulesApplied,
) {
  // Try outer parentheses removal
  if (regex.length >= 2 && regex[0] == '(') {
    int depth = 0;
    int matchingIndex = -1;

    for (int i = 0; i < regex.length; i++) {
      if (regex[i] == '(') {
        depth++;
      } else if (regex[i] == ')') {
        depth--;
        if (depth == 0) {
          matchingIndex = i;
          break;
        }
      }
    }

    // Outer parentheses wrap entire expression
    if (matchingIndex == regex.length - 1) {
      final newRegex = regex.substring(1, regex.length - 1);
      return _StepApplicationResult(
        newRegex: newRegex,
        step: RegexSimplificationStep.applyRule(
          id: 'step_$stepNumber',
          stepNumber: stepNumber,
          originalRegex: regex,
          simplifiedRegex: newRegex,
          rule: SimplificationRule.redundantParentheses,
          matchedSubexpression: regex,
          replacementSubexpression: newRegex,
          position: 0,
          totalRulesApplied: totalRulesApplied + 1,
        ),
      );
    }

    // Single symbol with operator: (a)* → a*
    if (matchingIndex < regex.length - 1) {
      final afterParen = regex[matchingIndex + 1];
      if (afterParen == '*' || afterParen == '+' || afterParen == '?') {
        final content = regex.substring(1, matchingIndex);
        if (_isSingleSymbol(content)) {
          final newRegex =
              content + afterParen + regex.substring(matchingIndex + 2);
          return _StepApplicationResult(
            newRegex: newRegex,
            step: RegexSimplificationStep.applyRule(
              id: 'step_$stepNumber',
              stepNumber: stepNumber,
              originalRegex: regex,
              simplifiedRegex: newRegex,
              rule: SimplificationRule.redundantParentheses,
              matchedSubexpression: regex.substring(0, matchingIndex + 2),
              replacementSubexpression: content + afterParen,
              position: 0,
              totalRulesApplied: totalRulesApplied + 1,
            ),
          );
        }
      }
    }
  }

  // Try single symbol parentheses removal in the middle
  for (int i = 0; i < regex.length; i++) {
    if (regex[i] == '(') {
      final closeIndex = _findMatchingCloseParen(regex, i);
      if (closeIndex != -1) {
        final content = regex.substring(i + 1, closeIndex);
        final hasOperatorAfter =
            closeIndex + 1 < regex.length &&
            (regex[closeIndex + 1] == '*' ||
                regex[closeIndex + 1] == '+' ||
                regex[closeIndex + 1] == '?');

        if (_isSingleSymbol(content) && !hasOperatorAfter) {
          final newRegex =
              regex.substring(0, i) + content + regex.substring(closeIndex + 1);
          return _StepApplicationResult(
            newRegex: newRegex,
            step: RegexSimplificationStep.applyRule(
              id: 'step_$stepNumber',
              stepNumber: stepNumber,
              originalRegex: regex,
              simplifiedRegex: newRegex,
              rule: SimplificationRule.redundantParentheses,
              matchedSubexpression: '($content)',
              replacementSubexpression: content,
              position: i,
              totalRulesApplied: totalRulesApplied + 1,
            ),
          );
        }
      }
    }
  }

  return null;
}

/// Applies algebraic identities with step capture
_StepApplicationResult? _applyAlgebraicIdentityWithStep(
  String regex,
  int stepNumber,
  int totalRulesApplied,
) {
  // ∅* → ε
  if (regex.contains('∅*')) {
    final newRegex = regex.replaceFirst('∅*', 'ε');
    return _StepApplicationResult(
      newRegex: newRegex,
      step: RegexSimplificationStep.applyRule(
        id: 'step_$stepNumber',
        stepNumber: stepNumber,
        originalRegex: regex,
        simplifiedRegex: newRegex,
        rule: SimplificationRule.emptySetStar,
        matchedSubexpression: '∅*',
        replacementSubexpression: 'ε',
        position: regex.indexOf('∅*'),
        totalRulesApplied: totalRulesApplied + 1,
      ),
    );
  }

  // ε* → ε
  if (regex.contains('ε*')) {
    final newRegex = regex.replaceFirst('ε*', 'ε');
    return _StepApplicationResult(
      newRegex: newRegex,
      step: RegexSimplificationStep.applyRule(
        id: 'step_$stepNumber',
        stepNumber: stepNumber,
        originalRegex: regex,
        simplifiedRegex: newRegex,
        rule: SimplificationRule.emptyStringStar,
        matchedSubexpression: 'ε*',
        replacementSubexpression: 'ε',
        position: regex.indexOf('ε*'),
        totalRulesApplied: totalRulesApplied + 1,
      ),
    );
  }

  for (var i = 0; i < regex.length; i++) {
    if (regex[i] == '∅') {
      final simplified = _simplifyEmptySetConcatenation(regex);
      if (simplified != regex) {
        final before = i > 0 ? regex[i - 1] : '';
        final after = i < regex.length - 1 ? regex[i + 1] : '';
        final isLeftConcat = before == '' || before == '|' || before == '(';
        return _StepApplicationResult(
          newRegex: simplified,
          step: RegexSimplificationStep.applyRule(
            id: 'step_$stepNumber',
            stepNumber: stepNumber,
            originalRegex: regex,
            simplifiedRegex: simplified,
            rule: isLeftConcat
                ? SimplificationRule.emptySetConcatenationLeft
                : SimplificationRule.emptySetConcatenation,
            matchedSubexpression: isLeftConcat ? '∅$after' : '$before∅',
            replacementSubexpression: '∅',
            position: i,
            totalRulesApplied: totalRulesApplied + 1,
          ),
        );
      }
    }
  }

  // ∅|r → r
  final emptyUnionLeftMatch = RegExp(r'∅\|([^|]+)').firstMatch(regex);
  if (emptyUnionLeftMatch != null &&
      (emptyUnionLeftMatch.start == 0 ||
          '(|'.contains(regex[emptyUnionLeftMatch.start - 1]))) {
    final matched = emptyUnionLeftMatch.group(0)!;
    final replacement = emptyUnionLeftMatch.group(1)!;
    final newRegex = regex.replaceFirst(matched, replacement);
    return _StepApplicationResult(
      newRegex: newRegex,
      step: RegexSimplificationStep.applyRule(
        id: 'step_$stepNumber',
        stepNumber: stepNumber,
        originalRegex: regex,
        simplifiedRegex: newRegex,
        rule: SimplificationRule.emptyUnionLeft,
        matchedSubexpression: matched,
        replacementSubexpression: replacement,
        position: emptyUnionLeftMatch.start,
        totalRulesApplied: totalRulesApplied + 1,
      ),
    );
  }

  // r|∅ → r
  final emptyUnionRightMatch = RegExp(r'([^|]+)\|∅').firstMatch(regex);
  if (emptyUnionRightMatch != null &&
      (emptyUnionRightMatch.end == regex.length ||
          ')|'.contains(regex[emptyUnionRightMatch.end]))) {
    final matched = emptyUnionRightMatch.group(0)!;
    final replacement = emptyUnionRightMatch.group(1)!;
    final newRegex = regex.replaceFirst(matched, replacement);
    return _StepApplicationResult(
      newRegex: newRegex,
      step: RegexSimplificationStep.applyRule(
        id: 'step_$stepNumber',
        stepNumber: stepNumber,
        originalRegex: regex,
        simplifiedRegex: newRegex,
        rule: SimplificationRule.emptyUnion,
        matchedSubexpression: matched,
        replacementSubexpression: replacement,
        position: emptyUnionRightMatch.start,
        totalRulesApplied: totalRulesApplied + 1,
      ),
    );
  }

  // r** → r* (multiple consecutive stars)
  final multipleStarsMatch = RegExp(r'\*{2,}').firstMatch(regex);
  if (multipleStarsMatch != null) {
    final matched = multipleStarsMatch.group(0)!;
    final newRegex = regex.replaceFirst(matched, '*');
    return _StepApplicationResult(
      newRegex: newRegex,
      step: RegexSimplificationStep.applyRule(
        id: 'step_$stepNumber',
        stepNumber: stepNumber,
        originalRegex: regex,
        simplifiedRegex: newRegex,
        rule: SimplificationRule.starIdempotence,
        matchedSubexpression: matched,
        replacementSubexpression: '*',
        position: multipleStarsMatch.start,
        totalRulesApplied: totalRulesApplied + 1,
      ),
    );
  }

  // εr → r or rε → r (epsilon concatenation)
  // Check for ε followed by a symbol (not | or operator)
  for (int i = 0; i < regex.length; i++) {
    if (regex[i] == 'ε') {
      final before = i > 0 ? regex[i - 1] : '';
      final after = i < regex.length - 1 ? regex[i + 1] : '';

      // εr → r (epsilon at start of concatenation)
      if ((before == '' || before == '|' || before == '(') &&
          after != '' &&
          after != '|' &&
          after != ')' &&
          after != '*' &&
          after != '+' &&
          after != '?') {
        final newRegex = regex.substring(0, i) + regex.substring(i + 1);
        return _StepApplicationResult(
          newRegex: newRegex,
          step: RegexSimplificationStep.applyRule(
            id: 'step_$stepNumber',
            stepNumber: stepNumber,
            originalRegex: regex,
            simplifiedRegex: newRegex,
            rule: SimplificationRule.emptyStringConcatenationLeft,
            matchedSubexpression: 'ε$after',
            replacementSubexpression: after,
            position: i,
            totalRulesApplied: totalRulesApplied + 1,
          ),
        );
      }

      // rε → r (epsilon at end of concatenation)
      if ((after == '' || after == '|' || after == ')') &&
          before != '' &&
          before != '|' &&
          before != '(' &&
          before != '*' &&
          before != '+' &&
          before != '?') {
        final newRegex = regex.substring(0, i) + regex.substring(i + 1);
        return _StepApplicationResult(
          newRegex: newRegex,
          step: RegexSimplificationStep.applyRule(
            id: 'step_$stepNumber',
            stepNumber: stepNumber,
            originalRegex: regex,
            simplifiedRegex: newRegex,
            rule: SimplificationRule.emptyStringConcatenation,
            matchedSubexpression: '$beforeε',
            replacementSubexpression: before,
            position: i - 1,
            totalRulesApplied: totalRulesApplied + 1,
          ),
        );
      }
    }
  }

  // r|r → r (union idempotence)
  final segments = _splitIntoConcatenationSegments(regex);
  if (segments.length > 1) {
    final seen = <String>{};
    for (int i = 0; i < segments.length; i++) {
      if (seen.contains(segments[i])) {
        // Found a duplicate
        final duplicateSegment = segments[i];
        final unique = <String>[];
        final seenForUnique = <String>{};
        for (final seg in segments) {
          if (!seenForUnique.contains(seg)) {
            seenForUnique.add(seg);
            unique.add(seg);
          }
        }
        final newRegex = unique.join('|');
        return _StepApplicationResult(
          newRegex: newRegex,
          step: RegexSimplificationStep.applyRule(
            id: 'step_$stepNumber',
            stepNumber: stepNumber,
            originalRegex: regex,
            simplifiedRegex: newRegex,
            rule: SimplificationRule.unionIdempotence,
            matchedSubexpression: '$duplicateSegment|$duplicateSegment',
            replacementSubexpression: duplicateSegment,
            position: 0,
            totalRulesApplied: totalRulesApplied + 1,
          ),
        );
      }
      seen.add(segments[i]);
    }
  }

  return null;
}
