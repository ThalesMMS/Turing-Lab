part of 'regex_simplifier.dart';

int _computeStarHeight(String regex) {
  int maxHeight = 0;
  int currentHeight = 0;
  int parenDepth = 0;
  final starHeightAtDepth = <int, int>{};

  for (int i = 0; i < regex.length; i++) {
    final char = regex[i];
    if (char == '(') {
      currentHeight = 0;
      parenDepth++;
      starHeightAtDepth[parenDepth] = 0;
    } else if (char == ')') {
      currentHeight = 0;
      if (parenDepth > 0) {
        final heightInParen = starHeightAtDepth[parenDepth] ?? 0;
        parenDepth--;
        if (parenDepth > 0) {
          final parentHeight = starHeightAtDepth[parenDepth] ?? 0;
          starHeightAtDepth[parenDepth] = parentHeight > heightInParen
              ? parentHeight
              : heightInParen;
        } else {
          maxHeight = maxHeight > heightInParen ? maxHeight : heightInParen;
        }
      }
    } else if (char == '*') {
      if (parenDepth > 0) {
        final heightInParen = starHeightAtDepth[parenDepth] ?? 0;
        starHeightAtDepth[parenDepth] = heightInParen + 1;
        final newHeight = starHeightAtDepth[parenDepth]!;
        maxHeight = maxHeight > newHeight ? maxHeight : newHeight;
      } else {
        currentHeight++;
        maxHeight = maxHeight > currentHeight ? maxHeight : currentHeight;
      }
    } else {
      currentHeight = 0;
    }
  }

  return maxHeight > 0 ? maxHeight : (regex.contains('*') ? 1 : 0);
}

/// Computes the nesting depth of parentheses
int _computeNestingDepth(String regex) {
  int maxDepth = 0;
  int currentDepth = 0;

  for (int i = 0; i < regex.length; i++) {
    if (regex[i] == '(') {
      currentDepth++;
      if (currentDepth > maxDepth) {
        maxDepth = currentDepth;
      }
    } else if (regex[i] == ')') {
      currentDepth--;
    }
  }

  return maxDepth;
}

/// Counts the number of operators in the regex
int _countOperators(String regex) {
  int count = 0;
  for (int i = 0; i < regex.length; i++) {
    final char = regex[i];
    if (char == '|' || char == '*' || char == '+' || char == '?') {
      count++;
    }
  }
  return count;
}

/// Validates the input regex string
///
/// Performs basic validation to ensure the regex is well-formed:
/// - Non-empty string
/// - Balanced parentheses
///
/// This validation catches structural errors before attempting simplification,
/// preventing runtime errors and providing clear error messages.
Result<void> _validateInput(String regex) {
  if (regex.isEmpty) {
    final message = RegexSimplificationMessages.emptyInput();
    return Failure(message.stableCode, structuredMessage: message);
  }

  // Check for balanced parentheses
  final balanceResult = _checkBalancedParentheses(regex);
  if (!balanceResult.isSuccess) {
    return balanceResult;
  }

  return ResultFactory.success(null);
}

/// Checks if parentheses are balanced in the regex
///
/// Uses a counter-based algorithm:
/// - Increment counter for '('
/// - Decrement counter for ')'
/// - Counter going negative indicates unmatched closing parenthesis
/// - Non-zero final counter indicates unmatched opening parentheses
///
/// Time complexity: O(n) where n is the length of the regex
/// Space complexity: O(1)
Result<void> _checkBalancedParentheses(String regex) {
  int count = 0;
  for (int i = 0; i < regex.length; i++) {
    if (regex[i] == '(') {
      count++;
    } else if (regex[i] == ')') {
      count--;
      if (count < 0) {
        final message = RegexSimplificationMessages.unmatchedClosingParenthesis(
          i,
        );
        return Failure(message.stableCode, structuredMessage: message);
      }
    }
  }

  if (count != 0) {
    final message = RegexSimplificationMessages.unclosedOpeningParentheses(
      count,
    );
    return Failure(message.stableCode, structuredMessage: message);
  }

  return ResultFactory.success(null);
}

/// Removes redundant parentheses from the regex
///
/// Handles three types of redundant parentheses:
/// 1. Outer parentheses: (a) → a, (a|b) → a|b (when they wrap the entire expression and no operator follows)
/// 2. Nested parentheses: ((a)) → (a) → a
/// 3. Redundant parentheses around single symbols in concatenation: (a)(b) → ab
String _removeRedundantParentheses(String regex) {
  if (regex.isEmpty) return regex;

  String result = regex;

  // Step 1: Remove outer parentheses if they wrap the entire expression
  // and are not followed by an operator (*, +, ?)
  result = _removeOuterParentheses(result);

  // Step 2: Remove redundant parentheses around single symbols in concatenation
  // Pattern: (x) where x is a single symbol and not followed by *, +, ?
  result = _removeSingleSymbolParentheses(result);

  return result;
}

/// Removes outer parentheses if they wrap the entire expression
/// and are not necessary for grouping
///
/// Algorithm:
/// 1. Find the matching closing parenthesis for the opening '(' at position 0
/// 2. If it matches the last character and no operator follows, remove both
/// 3. Special case: (a)* where a is a single symbol can become a*
///
/// Examples:
/// - (a|b) → a|b (outer parens wrapping entire expression)
/// - (a)* → a* (single symbol with operator can lose parens)
/// - (a|b)* → (a|b)* (complex expression needs parens for operator)
/// - (a)(b) → (a)(b) (not outer parens, handled by _removeSingleSymbolParentheses)
///
/// Time complexity: O(n) for finding matching parenthesis
String _removeOuterParentheses(String regex) {
  if (regex.length < 2) return regex;
  if (regex[0] != '(') return regex;

  // Check if the first parenthesis matches the last one
  // and they wrap the entire expression
  // Uses depth tracking to handle nested parentheses correctly
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

  // If the matching closing parenthesis is the last character
  // and is not followed by an operator, we can remove it
  if (matchingIndex == regex.length - 1) {
    return regex.substring(1, regex.length - 1);
  }

  // If the matching closing parenthesis is followed only by an operator
  // that applies to the whole group, check if we can still remove it
  if (matchingIndex < regex.length - 1) {
    final afterParen = regex[matchingIndex + 1];
    // If followed by *, +, or ?, we need to check the content
    if (afterParen == '*' || afterParen == '+' || afterParen == '?') {
      // Check if the content inside is a single symbol
      final content = regex.substring(1, matchingIndex);
      if (_isSingleSymbol(content)) {
        // (a)* → a* (operator can apply directly to single symbol)
        return content + afterParen + regex.substring(matchingIndex + 2);
      }
    }
  }

  return regex;
}

/// Removes redundant parentheses around single symbols
///
/// Scans the regex left-to-right and identifies parenthesized groups.
/// If a group contains only a single symbol and is not followed by an operator,
/// or if it's a single symbol followed by an operator, the parentheses are removed.
///
/// Examples:
/// - (a)(b) → ab (concatenation of single symbols)
/// - a(b) → ab (single symbol doesn't need parens)
/// - (a)b → ab (single symbol doesn't need parens)
/// - (a)* → a* (single symbol with operator can lose parens)
/// - (a|b) → (a|b) (complex expression keeps parens)
/// - (a|b)* → (a|b)* (complex expression needs parens for operator)
///
/// Time complexity: O(n²) worst case due to nested _findMatchingCloseParen calls
/// Space complexity: O(n) for the StringBuffer
String _removeSingleSymbolParentheses(String regex) {
  final buffer = StringBuffer();
  int i = 0;

  while (i < regex.length) {
    if (regex[i] == '(') {
      // Find the matching closing parenthesis
      final closeIndex = _findMatchingCloseParen(regex, i);
      if (closeIndex == -1) {
        // Shouldn't happen if validation passed, but handle gracefully
        buffer.write(regex[i]);
        i++;
        continue;
      }

      final content = regex.substring(i + 1, closeIndex);

      // Check if followed by an operator
      final hasOperatorAfter =
          closeIndex + 1 < regex.length &&
          (regex[closeIndex + 1] == '*' ||
              regex[closeIndex + 1] == '+' ||
              regex[closeIndex + 1] == '?');

      // Remove parentheses if:
      // 1. Content is a single symbol AND
      // 2. Not followed by an operator (or operator can be applied without parens)
      if (_isSingleSymbol(content) && !hasOperatorAfter) {
        buffer.write(content);
        i = closeIndex + 1;
      } else if (_isSingleSymbol(content) && hasOperatorAfter) {
        // (a)* → a* (operator can apply directly to single symbol)
        buffer.write(content);
        buffer.write(regex[closeIndex + 1]);
        i = closeIndex + 2;
      } else {
        // Keep the parentheses for complex expressions
        buffer.write(regex.substring(i, closeIndex + 1));
        i = closeIndex + 1;
      }
    } else {
      buffer.write(regex[i]);
      i++;
    }
  }

  return buffer.toString();
}

/// Finds the index of the matching closing parenthesis
///
/// Uses depth tracking to handle nested parentheses:
/// - Increment depth for each '('
/// - Decrement depth for each ')'
/// - Return index when depth reaches 0 (matching parenthesis found)
///
/// Time complexity: O(n) where n is the length from openIndex to end
/// Space complexity: O(1)
///
/// Returns -1 if no matching parenthesis is found (shouldn't happen after validation)
int _findMatchingCloseParen(String regex, int openIndex) {
  int depth = 0;
  for (int i = openIndex; i < regex.length; i++) {
    if (regex[i] == '(') {
      depth++;
    } else if (regex[i] == ')') {
      depth--;
      if (depth == 0) {
        return i;
      }
    }
  }
  return -1;
}

/// Checks if a string represents a single symbol (not a complex expression)
///
/// Single symbols include:
/// - Single characters (a, b, 0, 1, etc.)
/// - Epsilon (ε or λ)
/// - Empty string (special case)
///
/// Not single symbols:
/// - Expressions with operators (|, *, +, ?)
/// - Expressions with parentheses
/// - Concatenations (multiple characters)
///
/// Examples:
/// - 'a' → true (single character)
/// - 'ε' → true (epsilon)
/// - 'ab' → false (concatenation)
/// - 'a|b' → false (union)
/// - 'a*' → false (contains operator)
///
/// Time complexity: O(n) where n is the length of s
/// Space complexity: O(1)
bool _isSingleSymbol(String s) {
  if (isEpsilonSymbol(s)) return true;

  if (s.length == 1) {
    return !const {'|', '*', '+', '?', '(', ')'}.contains(s);
  }

  return false;
}
