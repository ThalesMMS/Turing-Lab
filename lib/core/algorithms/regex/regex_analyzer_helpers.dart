part of 'regex_analyzer.dart';

// ============================================================
// Private helper methods
// ============================================================

final Set<String> _regexAnalyzerDigits = List.generate(
  10,
  (i) => String.fromCharCode('0'.codeUnitAt(0) + i),
).toSet();
final Set<String> _regexAnalyzerLowercase = List.generate(
  26,
  (i) => String.fromCharCode('a'.codeUnitAt(0) + i),
).toSet();
final Set<String> _regexAnalyzerUppercase = List.generate(
  26,
  (i) => String.fromCharCode('A'.codeUnitAt(0) + i),
).toSet();
final Set<String> _regexAnalyzerWordChars = {
  '_',
  ..._regexAnalyzerLowercase,
  ..._regexAnalyzerUppercase,
  ..._regexAnalyzerDigits,
};
final Set<String> _regexAnalyzerWhitespaceChars = {' '};
final Set<String> _regexAnalyzerAllChars = {
  ..._regexAnalyzerWordChars,
  ..._regexAnalyzerWhitespaceChars,
};

/// Validates [regex] and parses it into an AST node.
///
/// Returns a [Result] with the [RegexNode] on success, or an error if
/// the regex is syntactically invalid or cannot be parsed.
Result<RegexNode> _validateAndParse(String regex) {
  final validationResult = _validateRegex(regex);
  if (!validationResult.isSuccess) {
    return ResultFactory.failure(validationResult.error!);
  }
  final node = _parseRegex(regex);
  if (node == null) {
    return ResultFactory.failure('Invalid regular expression syntax');
  }
  return ResultFactory.success(node);
}

/// Validates the regular expression syntax
Result<void> _validateRegex(String regex) {
  if (regex.isEmpty) {
    return ResultFactory.failure('Regular expression cannot be empty');
  }

  // Check for balanced parentheses
  int parenCount = 0;
  var escaped = false;
  var inCharClass = false;
  for (int i = 0; i < regex.length; i++) {
    final char = regex[i];
    if (escaped) {
      escaped = false;
      continue;
    }
    if (char == '\\') {
      escaped = true;
      continue;
    }
    if (char == '[') {
      inCharClass = true;
      continue;
    }
    if (char == ']') {
      inCharClass = false;
      continue;
    }
    if (inCharClass) {
      continue;
    }
    if (char == '(') {
      parenCount++;
    } else if (char == ')') {
      parenCount--;
      if (parenCount < 0) {
        return ResultFactory.failure(
          'Unbalanced parentheses: closing parenthesis at position $i '
          'has no matching opening parenthesis',
        );
      }
    }
  }

  if (parenCount != 0) {
    return ResultFactory.failure(
      'Unbalanced parentheses: $parenCount unclosed opening parenthesis(es)',
    );
  }

  if (inCharClass) {
    return ResultFactory.failure('Character class is not closed');
  }

  // Check for invalid characters (allow epsilon literal ε)
  final validChars = RegExp(r'[a-zA-Z0-9\\\(\)\[\]\|\*\+\?\.|ε∅λ]');
  inCharClass = false;
  for (int i = 0; i < regex.length; i++) {
    final char = regex[i];
    if (char == '[') {
      inCharClass = true;
    } else if (char == ']') {
      inCharClass = false;
    }
    if (char == '-' && inCharClass) {
      continue;
    }
    if (!validChars.hasMatch(char)) {
      return ResultFactory.failure(
        'Invalid character in regular expression: $char',
      );
    }
  }

  // Check operator placement
  const quantifiers = {'*', '+', '?'};
  if (regex.isNotEmpty && quantifiers.contains(regex[0])) {
    return ResultFactory.failure('Regex cannot start with a quantifier');
  }

  inCharClass = false;
  for (int i = 1; i < regex.length; i++) {
    final curr = regex[i];
    if (curr == '[') {
      inCharClass = true;
      continue;
    }
    if (curr == ']') {
      inCharClass = false;
      continue;
    }
    if (inCharClass || regex[i - 1] == '\\') {
      continue;
    }
    final prev = regex[i - 1];

    // Reject consecutive quantifiers
    if (quantifiers.contains(prev) && quantifiers.contains(curr)) {
      return ResultFactory.failure('Consecutive quantifiers are not allowed');
    }

    // Union operator cannot be at ends
    if (curr == '|' && (i == 0 || i == regex.length - 1)) {
      return ResultFactory.failure('Union operator cannot be at ends');
    }

    // Empty parentheses
    if (curr == ')' && prev == '(') {
      return ResultFactory.failure('Empty parentheses are not allowed');
    }
  }

  return ResultFactory.success(null);
}

/// Parses regex string into AST using the converter's tokenizer
RegexNode? _parseRegex(String regex) {
  try {
    final tokens = _tokenize(regex);
    return _parseExpression(tokens);
  } catch (e) {
    return null;
  }
}

/// Tokenizes the regular expression
List<_RegexToken> _tokenize(String regex) {
  final tokens = <_RegexToken>[];
  int i = 0;

  while (i < regex.length) {
    final char = regex[i];

    switch (char) {
      case '(':
        tokens.add(_RegexToken(type: _TokenType.leftParen, value: char));
        break;
      case ')':
        tokens.add(_RegexToken(type: _TokenType.rightParen, value: char));
        break;
      case '|':
        tokens.add(_RegexToken(type: _TokenType.union, value: char));
        break;
      case '*':
        tokens.add(_RegexToken(type: _TokenType.kleeneStar, value: char));
        break;
      case '+':
        tokens.add(_RegexToken(type: _TokenType.plus, value: char));
        break;
      case '?':
        tokens.add(_RegexToken(type: _TokenType.question, value: char));
        break;
      case '.':
        tokens.add(_RegexToken(type: _TokenType.dot, value: char));
        break;
      case '[':
        // Character class until ']'
        int j = i + 1;
        final buf = StringBuffer();
        while (j < regex.length && regex[j] != ']') {
          if (regex[j] == '\\' && j + 1 < regex.length) {
            buf.write(regex[j]);
            buf.write(regex[j + 1]);
            j += 2;
            continue;
          }
          buf.write(regex[j]);
          j++;
        }
        if (j >= regex.length || regex[j] != ']') {
          tokens.add(_RegexToken(type: _TokenType.symbol, value: char));
        } else {
          tokens.add(
            _RegexToken(type: _TokenType.charClass, value: buf.toString()),
          );
          i = j;
        }
        break;
      case '\\':
        if (i + 1 < regex.length) {
          final next = regex[i + 1];
          if ('dDsSwW'.contains(next)) {
            tokens.add(_RegexToken(type: _TokenType.charShortcut, value: next));
            i++;
            break;
          }
          tokens.add(_RegexToken(type: _TokenType.symbol, value: next));
          i++;
        } else {
          tokens.add(_RegexToken(type: _TokenType.symbol, value: char));
        }
        break;
      default:
        if (char == 'ε' || char == 'λ') {
          tokens.add(_RegexToken(type: _TokenType.epsilon, value: char));
        } else if (char == '∅') {
          tokens.add(_RegexToken(type: _TokenType.emptySet, value: char));
        } else {
          tokens.add(_RegexToken(type: _TokenType.symbol, value: char));
        }
        break;
    }

    i++;
  }

  return tokens;
}

/// Parses the expression from tokens
RegexNode? _parseExpression(List<_RegexToken> tokens) {
  if (tokens.isEmpty) return null;
  return _parseUnion(tokens);
}

/// Parses union expressions (|)
RegexNode? _parseUnion(List<_RegexToken> tokens) {
  var node = _parseConcatenation(tokens);

  while (tokens.isNotEmpty && tokens.first.type == _TokenType.union) {
    tokens.removeAt(0);
    final right = _parseConcatenation(tokens);
    if (right == null) return null;
    node = UnionNode(left: node!, right: right);
  }

  return node;
}

/// Parses concatenation expressions
RegexNode? _parseConcatenation(List<_RegexToken> tokens) {
  var node = _parseUnary(tokens);

  while (tokens.isNotEmpty &&
      tokens.first.type != _TokenType.union &&
      tokens.first.type != _TokenType.rightParen) {
    final right = _parseUnary(tokens);
    if (right == null) return null;
    node = ConcatenationNode(left: node!, right: right);
  }

  return node;
}

/// Parses unary expressions (*, +, ?)
RegexNode? _parseUnary(List<_RegexToken> tokens) {
  var node = _parsePrimary(tokens);

  while (tokens.isNotEmpty) {
    final token = tokens.first;
    switch (token.type) {
      case _TokenType.kleeneStar:
        tokens.removeAt(0);
        node = KleeneStarNode(child: node!);
        break;
      case _TokenType.plus:
        tokens.removeAt(0);
        node = PlusNode(child: node!);
        break;
      case _TokenType.question:
        tokens.removeAt(0);
        node = QuestionNode(child: node!);
        break;
      default:
        return node;
    }
  }

  return node;
}

/// Parses primary expressions (symbols, parentheses)
RegexNode? _parsePrimary(List<_RegexToken> tokens) {
  if (tokens.isEmpty) return null;

  final token = tokens.removeAt(0);

  switch (token.type) {
    case _TokenType.symbol:
      return SymbolNode(symbol: token.value);
    case _TokenType.dot:
      return const DotNode();
    case _TokenType.epsilon:
      return const EpsilonNode();
    case _TokenType.emptySet:
      return const _EmptySetNode();
    case _TokenType.charClass:
      return SetNode(symbols: _parseCharClass(token.value));
    case _TokenType.charShortcut:
      return ShortcutNode(code: token.value);
    case _TokenType.leftParen:
      final node = _parseExpression(tokens);
      if (tokens.isEmpty || tokens.removeAt(0).type != _TokenType.rightParen) {
        return null;
      }
      return node;
    default:
      return null;
  }
}

/// Parses character class content
Set<String> _parseCharClass(String content) {
  final characters = <({String value, bool escaped})>[];
  for (var i = 0; i < content.length; i++) {
    final escaped = content[i] == '\\' && i + 1 < content.length;
    if (escaped) i++;
    characters.add((value: content[i], escaped: escaped));
  }
  final symbols = <String>{};
  int i = 0;
  while (i < characters.length) {
    if (i + 2 < characters.length &&
        characters[i + 1].value == '-' &&
        !characters[i + 1].escaped) {
      final start = characters[i].value.codeUnitAt(0);
      final end = characters[i + 2].value.codeUnitAt(0);
      for (int u = start; u <= end; u++) {
        symbols.add(String.fromCharCode(u));
      }
      i += 3;
      continue;
    }
    symbols.add(characters[i].value);
    i++;
  }
  return symbols;
}

/// Computes star height from AST by recursive traversal
///
/// Star height is defined recursively:
/// - h(ε) = h(∅) = h(a) = 0 for symbol a
/// - h(r|s) = max(h(r), h(s))
/// - h(rs) = max(h(r), h(s))
/// - h(r*) = h(r) + 1
int _computeStarHeight(RegexNode node) {
  return switch (node) {
    EpsilonNode() => 0,
    SymbolNode() => 0,
    DotNode() => 0,
    SetNode() => 0,
    ShortcutNode() => 0,
    _EmptySetNode() => 0,
    UnionNode(:final left, :final right) => math.max(
      _computeStarHeight(left),
      _computeStarHeight(right),
    ),
    ConcatenationNode(:final left, :final right) => math.max(
      _computeStarHeight(left),
      _computeStarHeight(right),
    ),
    KleeneStarNode(:final child) => _computeStarHeight(child) + 1,
    PlusNode(:final child) => _computeStarHeight(child) + 1,
    QuestionNode(:final child) => _computeStarHeight(child),
    _ => 0,
  };
}

/// Computes nesting depth from the raw regex string
///
/// Uses a simple counter algorithm:
/// - Ignore escaped characters and character classes
/// - Increment for each group '('
/// - Decrement for each group ')'
/// - Track maximum depth reached
int _computeNestingDepth(String regex) {
  int maxDepth = 0;
  int currentDepth = 0;
  var escaped = false;
  var inCharClass = false;

  for (int i = 0; i < regex.length; i++) {
    final char = regex[i];
    if (escaped) {
      escaped = false;
      continue;
    }
    if (char == '\\') {
      escaped = true;
      continue;
    }
    if (char == '[') {
      inCharClass = true;
      continue;
    }
    if (char == ']') {
      inCharClass = false;
      continue;
    }
    if (inCharClass) continue;
    if (char == '(') {
      currentDepth++;
      if (currentDepth > maxDepth) {
        maxDepth = currentDepth;
      }
    } else if (char == ')') {
      currentDepth--;
    }
  }

  return maxDepth;
}

/// Counts operators by traversing the AST
///
/// Returns a map with counts for:
/// - 'union': number of UnionNode instances
/// - 'concatenation': number of ConcatenationNode instances
/// - 'star': number of KleeneStarNode instances
/// - 'plus': number of PlusNode instances
/// - 'question': number of QuestionNode instances
Map<String, int> _countOperatorsFromAst(RegexNode node) {
  final counts = <String, int>{
    'union': 0,
    'concatenation': 0,
    'star': 0,
    'plus': 0,
    'question': 0,
  };

  _countOperatorsRecursive(node, counts);
  return counts;
}

/// Recursive helper for counting operators
void _countOperatorsRecursive(RegexNode node, Map<String, int> counts) {
  switch (node) {
    case UnionNode(:final left, :final right):
      counts['union'] = (counts['union'] ?? 0) + 1;
      _countOperatorsRecursive(left, counts);
      _countOperatorsRecursive(right, counts);
      break;
    case ConcatenationNode(:final left, :final right):
      counts['concatenation'] = (counts['concatenation'] ?? 0) + 1;
      _countOperatorsRecursive(left, counts);
      _countOperatorsRecursive(right, counts);
      break;
    case KleeneStarNode(:final child):
      counts['star'] = (counts['star'] ?? 0) + 1;
      _countOperatorsRecursive(child, counts);
      break;
    case PlusNode(:final child):
      counts['plus'] = (counts['plus'] ?? 0) + 1;
      _countOperatorsRecursive(child, counts);
      break;
    case QuestionNode(:final child):
      counts['question'] = (counts['question'] ?? 0) + 1;
      _countOperatorsRecursive(child, counts);
      break;
    default:
      // Terminal nodes have no operators to count
      break;
  }
}

/// Extracts the alphabet (set of symbols) from the AST
///
/// Traverses the AST and collects all terminal symbols,
/// excluding epsilon and empty set.
Set<String> _extractAlphabet(RegexNode node, [Set<String>? contextAlphabet]) {
  final alphabet = <String>{};
  _extractAlphabetRecursive(node, alphabet, contextAlphabet);
  return alphabet;
}

/// Recursive helper for extracting alphabet
void _extractAlphabetRecursive(
  RegexNode node,
  Set<String> alphabet,
  Set<String>? contextAlphabet,
) {
  switch (node) {
    case SymbolNode(:final symbol):
      alphabet.add(symbol);
      break;
    case SetNode(:final symbols):
      alphabet.addAll(symbols);
      break;
    case ShortcutNode(:final code):
      // Expand shortcut to symbols
      alphabet.addAll(_expandShortcut(code, contextAlphabet));
      break;
    case DotNode():
      // Dot matches any symbol - add common alphabet
      alphabet.addAll(
        contextAlphabet == null || contextAlphabet.isEmpty
            ? {'a', 'b', 'c'}
            : contextAlphabet,
      );
      break;
    case UnionNode(:final left, :final right):
      _extractAlphabetRecursive(left, alphabet, contextAlphabet);
      _extractAlphabetRecursive(right, alphabet, contextAlphabet);
      break;
    case ConcatenationNode(:final left, :final right):
      _extractAlphabetRecursive(left, alphabet, contextAlphabet);
      _extractAlphabetRecursive(right, alphabet, contextAlphabet);
      break;
    case KleeneStarNode(:final child):
      _extractAlphabetRecursive(child, alphabet, contextAlphabet);
      break;
    case PlusNode(:final child):
      _extractAlphabetRecursive(child, alphabet, contextAlphabet);
      break;
    case QuestionNode(:final child):
      _extractAlphabetRecursive(child, alphabet, contextAlphabet);
      break;
    default:
      // EpsilonNode and EmptySetNode don't contribute to alphabet
      break;
  }
}

/// Expands character shortcuts to their full set
Set<String> _expandShortcut(String code, [Set<String>? contextAlphabet]) {
  final universe = contextAlphabet == null || contextAlphabet.isEmpty
      ? _regexAnalyzerAllChars
      : contextAlphabet;
  switch (code) {
    case 'd':
      return _regexAnalyzerDigits;
    case 'D':
      return universe.difference(_regexAnalyzerDigits);
    case 'w':
      return _regexAnalyzerWordChars;
    case 'W':
      return universe.difference(_regexAnalyzerWordChars);
    case 's':
      return _regexAnalyzerWhitespaceChars;
    case 'S':
      return universe.difference(_regexAnalyzerWhitespaceChars);
    default:
      return {};
  }
}

/// Determines if the regex accepts the empty string
///
/// A regex accepts ε if:
/// - It is ε
/// - It is r* (Kleene star always accepts ε)
/// - It is r? (optional always accepts ε)
/// - It is r|s where either r or s accepts ε
/// - It is rs where both r and s accept ε
bool _acceptsEmptyString(RegexNode node) {
  return switch (node) {
    EpsilonNode() => true,
    _EmptySetNode() => false,
    SymbolNode() => false,
    DotNode() => false,
    SetNode() => false,
    ShortcutNode() => false,
    KleeneStarNode() => true, // r* always accepts ε
    QuestionNode() => true, // r? always accepts ε
    PlusNode(:final child) => _acceptsEmptyString(child),
    UnionNode(:final left, :final right) =>
      _acceptsEmptyString(left) || _acceptsEmptyString(right),
    ConcatenationNode(:final left, :final right) =>
      _acceptsEmptyString(left) && _acceptsEmptyString(right),
    _ => false,
  };
}

// ============================================================
// Sample String Generation Helpers
// ============================================================

/// Generates a random sample string from an AST node
///
/// Returns null if the node represents an empty language (∅).
/// Uses randomization to produce varied samples.
String? _generateSampleFromNode(
  RegexNode node,
  int maxLength,
  Set<String>? contextAlphabet,
) {
  return _generateSampleRecursive(node, maxLength, 0, contextAlphabet);
}

/// Recursive helper for sample generation with depth tracking
String? _generateSampleRecursive(
  RegexNode node,
  int maxLength,
  int currentLength,
  Set<String>? contextAlphabet,
) {
  // Stop if we've exceeded max length
  if (currentLength > maxLength) {
    return null;
  }

  switch (node) {
    case EpsilonNode():
      return '';

    case _EmptySetNode():
      // Empty set has no valid strings
      return null;

    case SymbolNode(:final symbol):
      if (currentLength + symbol.length > maxLength) return null;
      return symbol;

    case DotNode():
      // Return a random common character for 'any' match
      if (currentLength + 1 > maxLength) return null;
      final symbols =
          contextAlphabet?.toList() ??
          'abcdefghijklmnopqrstuvwxyz0123456789'.split('');
      if (symbols.isEmpty) return null;
      return symbols[_random.nextInt(symbols.length)];

    case SetNode(:final symbols):
      if (symbols.isEmpty) return null;
      final symbolList = symbols
          .where((symbol) => currentLength + symbol.length <= maxLength)
          .toList();
      if (symbolList.isEmpty) return null;
      return symbolList[_random.nextInt(symbolList.length)];

    case ShortcutNode(:final code):
      final expanded = _expandShortcut(code, contextAlphabet);
      if (expanded.isEmpty) return null;
      final expandedList = expanded
          .where((symbol) => currentLength + symbol.length <= maxLength)
          .toList();
      if (expandedList.isEmpty) return null;
      return expandedList[_random.nextInt(expandedList.length)];

    case UnionNode(:final left, :final right):
      // Randomly choose one branch
      final choice = _random.nextBool();
      final first = choice ? left : right;
      final second = choice ? right : left;

      // Try first choice, fallback to second if it fails
      final result = _generateSampleRecursive(
        first,
        maxLength,
        currentLength,
        contextAlphabet,
      );
      if (result != null) return result;
      return _generateSampleRecursive(
        second,
        maxLength,
        currentLength,
        contextAlphabet,
      );

    case ConcatenationNode(:final left, :final right):
      final leftStr = _generateSampleRecursive(
        left,
        maxLength,
        currentLength,
        contextAlphabet,
      );
      if (leftStr == null) return null;
      if (currentLength + leftStr.length > maxLength) return null;

      final rightStr = _generateSampleRecursive(
        right,
        maxLength,
        currentLength + leftStr.length,
        contextAlphabet,
      );
      if (rightStr == null) return null;
      if (currentLength + leftStr.length + rightStr.length > maxLength) {
        return null;
      }

      return leftStr + rightStr;

    case KleeneStarNode(:final child):
      // Generate 0-3 repetitions randomly, biased toward shorter
      final repetitions = _biasedRepetitions(0, 3);
      if (repetitions == 0) return '';

      final buffer = StringBuffer();
      var totalLength = currentLength;

      for (int i = 0; i < repetitions; i++) {
        final part = _generateSampleRecursive(
          child,
          maxLength,
          totalLength,
          contextAlphabet,
        );
        if (part == null) {
          // If we can't generate more, return what we have (at least 0 repetitions)
          break;
        }
        if (totalLength + part.length > maxLength) {
          break;
        }
        buffer.write(part);
        totalLength += part.length;
      }

      return buffer.toString();

    case PlusNode(:final child):
      // Generate 1-4 repetitions randomly, biased toward shorter
      final repetitions = _biasedRepetitions(1, 4);

      final buffer = StringBuffer();
      var totalLength = currentLength;

      for (int i = 0; i < repetitions; i++) {
        final part = _generateSampleRecursive(
          child,
          maxLength,
          totalLength,
          contextAlphabet,
        );
        if (part == null) {
          // For plus, we need at least one, so fail if first fails
          if (i == 0) return null;
          break;
        }
        if (totalLength + part.length > maxLength) {
          if (i == 0) return null;
          break;
        }
        buffer.write(part);
        totalLength += part.length;
      }

      // Plus requires at least one repetition
      if (buffer.isEmpty) return null;
      return buffer.toString();

    case QuestionNode(:final child):
      // 50% chance of empty, 50% chance of child
      if (_random.nextBool()) {
        return '';
      }
      return _generateSampleRecursive(
        child,
        maxLength,
        currentLength,
        contextAlphabet,
      );

    default:
      return null;
  }
}

/// Returns a biased random number of repetitions favoring lower values
int _biasedRepetitions(int min, int max) {
  // Use exponential distribution to bias toward lower values
  final range = max - min + 1;
  final r = _random.nextDouble();
  // Bias toward min: probability decreases exponentially
  final biased = (range * (1 - math.sqrt(r))).floor();
  return min + biased.clamp(0, max - min);
}

/// Finds the shortest string that matches the regex
///
/// Returns null if the regex matches no strings (empty language).
String? _findShortestString(RegexNode node, [Set<String>? contextAlphabet]) {
  switch (node) {
    case EpsilonNode():
      return '';

    case _EmptySetNode():
      return null;

    case SymbolNode(:final symbol):
      return symbol;

    case DotNode():
      return contextAlphabet != null && contextAlphabet.isNotEmpty
          ? contextAlphabet.first
          : 'a';

    case SetNode(:final symbols):
      if (symbols.isEmpty) return null;
      // Return the first symbol (arbitrary but consistent)
      return symbols.first;

    case ShortcutNode(:final code):
      final expanded = _expandShortcut(code, contextAlphabet);
      if (expanded.isEmpty) return null;
      return expanded.first;

    case UnionNode(:final left, :final right):
      final leftShortest = _findShortestString(left, contextAlphabet);
      final rightShortest = _findShortestString(right, contextAlphabet);

      if (leftShortest == null) return rightShortest;
      if (rightShortest == null) return leftShortest;

      // Return the shorter of the two
      return leftShortest.length <= rightShortest.length
          ? leftShortest
          : rightShortest;

    case ConcatenationNode(:final left, :final right):
      final leftShortest = _findShortestString(left, contextAlphabet);
      final rightShortest = _findShortestString(right, contextAlphabet);

      if (leftShortest == null || rightShortest == null) return null;

      return leftShortest + rightShortest;

    case KleeneStarNode():
      // Kleene star can always produce empty string
      return '';

    case PlusNode(:final child):
      // Plus requires at least one repetition
      return _findShortestString(child, contextAlphabet);

    case QuestionNode():
      // Optional can always produce empty string
      return '';

    default:
      return null;
  }
}
