part of 'regex_analyzer.dart';

/// Token type for internal parsing
enum _TokenType {
  symbol,
  leftParen,
  rightParen,
  union,
  kleeneStar,
  plus,
  question,
  dot,
  charClass,
  charShortcut,
  epsilon,
  emptySet,
}

/// Token for internal parsing
class _RegexToken {
  final _TokenType type;
  final String value;

  const _RegexToken({required this.type, required this.value});
}

/// Internal AST node for empty set (∅)
class _EmptySetNode extends RegexNode {
  const _EmptySetNode();
}
