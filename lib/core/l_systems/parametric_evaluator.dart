//
//  parametric_evaluator.dart
//  Turing Lab
//
//  Deterministic arithmetic for parametric L-system rules. A parametric
//  symbol is written `name(arg, ...)`; a predecessor binds identifiers
//  (`A(x)`) and a successor evaluates expressions over them (`A(x+1)`).
//  The evaluator understands numbers, bound identifiers, + - * / ^, unary
//  minus and parentheses, and nothing else: no functions, no assignment, no
//  code, so imported documents can never execute anything.
//

enum ParametricEvaluationErrorCode {
  syntax,
  unknownIdentifier,
  divisionByZero,
  nonFinite,
}

final class ParametricEvaluationException implements Exception {
  const ParametricEvaluationException(
    this.code,
    this.expression, [
    this.detail,
  ]);

  final ParametricEvaluationErrorCode code;
  final String expression;
  final String? detail;

  @override
  String toString() =>
      'ParametricEvaluationException(${code.name}, "$expression"'
      '${detail == null ? '' : ', $detail'})';
}

/// A token of the form `name(arg1, arg2, ...)`.
final class ParametricSymbol {
  const ParametricSymbol({required this.name, required this.arguments});

  final String name;
  final List<String> arguments;

  /// Parses `name(args)` when the token has a non-empty name, a single
  /// balanced argument list at its end and no other parentheses. Returns
  /// null for plain symbols.
  static ParametricSymbol? parse(String token) {
    final open = token.indexOf('(');
    if (open <= 0 || !token.endsWith(')')) return null;
    final name = token.substring(0, open);
    if (name.contains(')')) return null;
    final body = token.substring(open + 1, token.length - 1);
    final arguments = <String>[];
    var depth = 0;
    final current = StringBuffer();
    for (final rune in body.runes) {
      final char = String.fromCharCode(rune);
      if (char == '(') depth++;
      if (char == ')') {
        depth--;
        if (depth < 0) return null;
      }
      if (char == ',' && depth == 0) {
        arguments.add(current.toString().trim());
        current.clear();
        continue;
      }
      current.write(char);
    }
    if (depth != 0) return null;
    arguments.add(current.toString().trim());
    if (arguments.length == 1 && arguments.single.isEmpty) {
      return ParametricSymbol(name: name, arguments: const []);
    }
    return ParametricSymbol(name: name, arguments: arguments);
  }

  /// Base name of [token]: `A` for `A(3)`, the token itself otherwise.
  static String baseName(String token) => parse(token)?.name ?? token;

  /// Renders `name(values)` with canonical number formatting.
  static String format(String name, Iterable<num> values) =>
      '$name(${values.map(formatNumber).join(',')})';

  /// Integers print without a fraction; other values keep six significant
  /// digits, so tiny parameters survive as `1e-7` instead of collapsing to
  /// `0`. The output is always parseable by [ParametricEvaluator].
  static String formatNumber(num value) {
    if (value == value.roundToDouble() && value.abs() < 1e15) {
      return value.round().toString();
    }
    if (!value.isFinite) return value.toString();
    final rounded = double.parse(value.toStringAsPrecision(6));
    if (rounded == rounded.roundToDouble() && rounded.abs() < 1e15) {
      return rounded.round().toString();
    }
    return rounded.toString();
  }
}

/// Parses and evaluates one arithmetic expression.
final class ParametricEvaluator {
  const ParametricEvaluator();

  static final _identifier = RegExp(r'^[A-Za-z_][A-Za-z0-9_]*$');

  /// Identifiers the predecessor `A(x, y)` declares, or null when [token] is
  /// not a parametric symbol or any argument is not a plain identifier.
  static List<String>? parameterNames(String token) {
    final symbol = ParametricSymbol.parse(token);
    if (symbol == null) return null;
    if (!symbol.arguments.every(_identifier.hasMatch)) return null;
    if (symbol.arguments.toSet().length != symbol.arguments.length) return null;
    return symbol.arguments;
  }

  /// Binds the parameters of [predecessor] to the numeric arguments of
  /// [symbol]; null when names or arity differ or an argument does not
  /// evaluate to a number.
  Map<String, double>? bind(String predecessor, String symbol) {
    final names = parameterNames(predecessor);
    final actual = ParametricSymbol.parse(symbol);
    if (names == null || actual == null) return null;
    if (actual.name != ParametricSymbol.baseName(predecessor)) return null;
    if (actual.arguments.length != names.length) return null;
    final bindings = <String, double>{};
    for (var index = 0; index < names.length; index++) {
      final value = tryEvaluate(actual.arguments[index], const {});
      if (value == null) return null;
      bindings[names[index]] = value;
    }
    return bindings;
  }

  /// Evaluates [expression] with [bindings]; throws
  /// [ParametricEvaluationException] on any problem.
  double evaluate(String expression, Map<String, double> bindings) {
    final parser = _Parser(expression, bindings);
    final value = parser.parseExpression();
    parser.expectEnd();
    if (!value.isFinite) {
      throw ParametricEvaluationException(
        ParametricEvaluationErrorCode.nonFinite,
        expression,
      );
    }
    return value;
  }

  /// [evaluate] that returns null instead of throwing.
  double? tryEvaluate(String expression, Map<String, double> bindings) {
    try {
      return evaluate(expression, bindings);
    } on ParametricEvaluationException {
      return null;
    }
  }

  /// Rewrites a successor token: every argument that is an arithmetic
  /// expression over [bindings] is replaced by its value. Arguments that are
  /// not expressions (colors, names) and plain symbols pass through
  /// unchanged, so `color(orange)` keeps working next to `g(x*2)`.
  String rewriteToken(String token, Map<String, double> bindings) {
    final symbol = ParametricSymbol.parse(token);
    if (symbol == null || symbol.arguments.isEmpty) return token;
    final rendered = <String>[];
    var changed = false;
    for (final argument in symbol.arguments) {
      final value = tryEvaluate(argument, bindings);
      if (value == null) {
        rendered.add(argument);
        continue;
      }
      final text = ParametricSymbol.formatNumber(value);
      if (text != argument) changed = true;
      rendered.add(text);
    }
    return changed ? '${symbol.name}(${rendered.join(',')})' : token;
  }
}

final class _Parser {
  _Parser(this.source, this.bindings);

  final String source;
  final Map<String, double> bindings;
  int _position = 0;

  static final _number = RegExp(r'^(\d+\.?\d*|\.\d+)([eE][+-]?\d+)?');
  static final _identifier = RegExp(r'^[A-Za-z_][A-Za-z0-9_]*');

  void _skipSpaces() {
    while (_position < source.length && source[_position] == ' ') {
      _position++;
    }
  }

  String? _peek() {
    _skipSpaces();
    return _position < source.length ? source[_position] : null;
  }

  Never _fail([String? detail]) => throw ParametricEvaluationException(
    ParametricEvaluationErrorCode.syntax,
    source,
    detail,
  );

  void expectEnd() {
    if (_peek() != null) _fail('unexpected "${source[_position]}"');
  }

  double parseExpression() {
    var value = _parseTerm();
    while (true) {
      final next = _peek();
      if (next == '+') {
        _position++;
        value += _parseTerm();
      } else if (next == '-') {
        _position++;
        value -= _parseTerm();
      } else {
        return value;
      }
    }
  }

  double _parseTerm() {
    var value = _parseUnary();
    while (true) {
      final next = _peek();
      if (next == '*') {
        _position++;
        value *= _parseUnary();
      } else if (next == '/') {
        _position++;
        final divisor = _parseUnary();
        if (divisor == 0) {
          throw ParametricEvaluationException(
            ParametricEvaluationErrorCode.divisionByZero,
            source,
          );
        }
        value /= divisor;
      } else {
        return value;
      }
    }
  }

  double _parseUnary() {
    final next = _peek();
    if (next == '-') {
      _position++;
      return -_parseUnary();
    }
    if (next == '+') {
      _position++;
      return _parseUnary();
    }
    return _parsePower();
  }

  double _parsePower() {
    final base = _parsePrimary();
    if (_peek() == '^') {
      _position++;
      // Right-associative: 2^3^2 = 2^(3^2).
      final exponent = _parseUnary();
      return _pow(base, exponent);
    }
    return base;
  }

  double _pow(double base, double exponent) {
    if (base == 0 && exponent < 0) {
      throw ParametricEvaluationException(
        ParametricEvaluationErrorCode.divisionByZero,
        source,
      );
    }
    if (exponent == exponent.roundToDouble() && exponent.isFinite) {
      // Exponentiation by squaring covers every integral exponent, including
      // negative bases, in O(log n) multiplications.
      var result = 1.0;
      var factor = base;
      var remaining = exponent.abs().round();
      while (remaining > 0) {
        if (remaining.isOdd) {
          result *= factor;
        }
        factor *= factor;
        // Bitwise shifts truncate to 32 bits when compiled to JavaScript.
        remaining ~/= 2;
      }
      return exponent < 0 ? 1 / result : result;
    }
    // Non-integer exponents of negative bases are not real numbers.
    if (base < 0) {
      throw ParametricEvaluationException(
        ParametricEvaluationErrorCode.nonFinite,
        source,
      );
    }
    return _realPow(base, exponent);
  }

  static double _realPow(double base, double exponent) =>
      base == 0 ? 0 : _exp(exponent * _ln(base));

  static double _exp(double x) {
    // dart:math is avoided on purpose to keep this file dependency-free and
    // obviously bounded; the series is evaluated in reduced range.
    // Non-finite inputs would never leave the range reduction; propagate them
    // so the caller reports a non-finite result instead of hanging.
    if (!x.isFinite) {
      return x.isNaN ? double.nan : (x > 0 ? double.infinity : 0);
    }
    var n = 0;
    var value = x;
    while (value.abs() > 0.5) {
      value /= 2;
      n++;
    }
    var sum = 1.0;
    var term = 1.0;
    for (var index = 1; index < 30; index++) {
      term *= value / index;
      sum += term;
    }
    for (var index = 0; index < n; index++) {
      sum *= sum;
    }
    return sum;
  }

  static double _ln(double x) {
    // Infinity never leaves the range reduction below; report it (and NaN)
    // directly so an overflowing base ends in a non-finite result.
    if (!x.isFinite) return x;
    if (x <= 0) return x == 0 ? double.negativeInfinity : double.nan;
    var value = x;
    var exponent = 0;
    while (value > 2) {
      value /= 2;
      exponent++;
    }
    while (value < 1) {
      value *= 2;
      exponent--;
    }
    final y = (value - 1) / (value + 1);
    var sum = 0.0;
    var power = y;
    for (var index = 1; index < 60; index += 2) {
      sum += power / index;
      power *= y * y;
    }
    return 2 * sum + exponent * 0.6931471805599453;
  }

  double _parsePrimary() {
    final next = _peek();
    if (next == null) _fail('unexpected end');
    if (next == '(') {
      _position++;
      final value = parseExpression();
      if (_peek() != ')') _fail('missing ")"');
      _position++;
      return value;
    }
    final rest = source.substring(_position);
    final number = _number.firstMatch(rest);
    if (number != null) {
      _position += number.end;
      return double.parse(number.group(0)!);
    }
    final identifier = _identifier.firstMatch(rest);
    if (identifier != null) {
      final name = identifier.group(0)!;
      _position += identifier.end;
      final bound = bindings[name];
      if (bound == null) {
        throw ParametricEvaluationException(
          ParametricEvaluationErrorCode.unknownIdentifier,
          source,
          name,
        );
      }
      return bound;
    }
    _fail('unexpected "$next"');
  }
}
