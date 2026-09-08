import 'package:flutter_test/flutter_test.dart';
import 'package:turing_lab/core/l_systems/parametric_evaluator.dart';

void main() {
  const evaluator = ParametricEvaluator();

  group('ParametricEvaluator.evaluate', () {
    test('respects precedence, associativity and parentheses', () {
      expect(evaluator.evaluate('1 + 2 * 3', const {}), 7);
      expect(evaluator.evaluate('(1 + 2) * 3', const {}), 9);
      expect(evaluator.evaluate('8 / 2 / 2', const {}), 2);
      expect(evaluator.evaluate('2 ^ 3 ^ 2', const {}), 512);
      // Unary minus binds looser than the power, as in mathematics.
      expect(evaluator.evaluate('-2 ^ 2', const {}), -4);
      expect(evaluator.evaluate('(-2) ^ 2', const {}), 4);
      expect(evaluator.evaluate('2 * -3', const {}), -6);
      expect(evaluator.evaluate('10 - 2 - 3', const {}), 5);
      expect(evaluator.evaluate('.5 + 1.25e1', const {}), 13);
    });

    test('binds identifiers and rejects unknown ones', () {
      expect(evaluator.evaluate('x * 0.7 + y', const {'x': 10, 'y': 2}), 9);
      expect(
        () => evaluator.evaluate('x + z', const {'x': 1}),
        throwsA(
          isA<ParametricEvaluationException>().having(
            (e) => e.code,
            'code',
            ParametricEvaluationErrorCode.unknownIdentifier,
          ),
        ),
      );
    });

    test('rejects syntax errors, division by zero and non-finite values', () {
      for (final bad in ['1 +', '(1', '1 2', 'x = 1', '1 ** 2']) {
        expect(
          () => evaluator.evaluate(bad, const {'x': 1}),
          throwsA(
            isA<ParametricEvaluationException>().having(
              (e) => e.code,
              'code',
              ParametricEvaluationErrorCode.syntax,
            ),
          ),
          reason: bad,
        );
      }
      expect(
        () => evaluator.evaluate('1 / (2 - 2)', const {}),
        throwsA(
          isA<ParametricEvaluationException>().having(
            (e) => e.code,
            'code',
            ParametricEvaluationErrorCode.divisionByZero,
          ),
        ),
      );
      expect(
        () => evaluator.evaluate('(-8) ^ 0.5', const {}),
        throwsA(isA<ParametricEvaluationException>()),
      );
      expect(evaluator.tryEvaluate('orange', const {}), isNull);
      // Function calls are not part of the language: the name is an unknown
      // identifier followed by a parenthesised expression.
      expect(evaluator.tryEvaluate('sin(1)', const {}), isNull);
    });

    test('non-integer powers are close to the real value', () {
      expect(evaluator.evaluate('9 ^ 0.5', const {}), closeTo(3, 1e-9));
      expect(evaluator.evaluate('2 ^ -1', const {}), 0.5);
    });

    test(
      'integral exponents retain bits above the JavaScript 32-bit range',
      () {
        expect(
          evaluator.evaluate('1.0000000001 ^ 4294967296', const {}),
          closeTo(1.5364842, 1e-6),
        );
        expect(
          evaluator.evaluate('1.0000000001 ^ -4294967296', const {}),
          closeTo(0.65083566, 1e-6),
        );
      },
    );

    test('integral exponents work beyond 64 and for negative bases', () {
      expect(
        evaluator.evaluate('2 ^ 100', const {}),
        closeTo(1.2676506002282294e30, 1e16),
      );
      expect(
        evaluator.evaluate('(-2) ^ 70', const {}),
        closeTo(1.1805916207174113e21, 1e7),
      );
      expect(
        evaluator.evaluate('(-2) ^ 71', const {}),
        closeTo(-2.3611832414348226e21, 1e7),
      );
      expect(evaluator.evaluate('(-2) ^ -3', const {}), -0.125);
    });

    test(
      'overflowing powers report a non-finite result instead of hanging',
      () {
        expect(
          () => evaluator.evaluate('10 ^ 400', const {}),
          throwsA(
            isA<ParametricEvaluationException>().having(
              (error) => error.code,
              'code',
              ParametricEvaluationErrorCode.nonFinite,
            ),
          ),
        );
        expect(
          () => evaluator.evaluate('10 ^ 400.5', const {}),
          throwsA(
            isA<ParametricEvaluationException>().having(
              (error) => error.code,
              'code',
              ParametricEvaluationErrorCode.nonFinite,
            ),
          ),
        );
        // An infinite base reaches the logarithm range reduction.
        expect(
          () => evaluator.evaluate('(10 ^ 400) ^ 0.5', const {}),
          throwsA(
            isA<ParametricEvaluationException>().having(
              (error) => error.code,
              'code',
              ParametricEvaluationErrorCode.nonFinite,
            ),
          ),
        );
      },
    );
  });

  group('ParametricSymbol', () {
    test('parses names and arguments and formats numbers canonically', () {
      final symbol = ParametricSymbol.parse('A(x*2, (y+1)/3)')!;
      expect(symbol.name, 'A');
      expect(symbol.arguments, ['x*2', '(y+1)/3']);
      expect(ParametricSymbol.parse('A()')!.arguments, isEmpty);
      expect(ParametricSymbol.parse('A'), isNull);
      expect(ParametricSymbol.parse('(x)'), isNull);
      expect(ParametricSymbol.parse('A(x'), isNull);
      expect(ParametricSymbol.baseName('g(12)'), 'g');
      expect(ParametricSymbol.baseName('+'), '+');
      expect(ParametricSymbol.formatNumber(3.0), '3');
      expect(ParametricSymbol.formatNumber(0.7 * 10), '7');
      expect(ParametricSymbol.formatNumber(1 / 3), '0.333333');
      expect(ParametricSymbol.formatNumber(48 * 0.68), '32.64');
      expect(ParametricSymbol.formatNumber(12.3456789), '12.3457');
      expect(ParametricSymbol.formatNumber(1e-7), '1e-7');
      expect(evaluator.evaluate('1e-7 * 2', const {}), 2e-7);
      expect(ParametricSymbol.format('A', [2, 0.5]), 'A(2,0.5)');
    });

    test('binds predecessor parameters to numeric arguments only', () {
      expect(evaluator.bind('A(x)', 'A(3)'), {'x': 3});
      expect(evaluator.bind('A(x,y)', 'A(1+1,4)'), {'x': 2, 'y': 4});
      expect(evaluator.bind('A(x)', 'A(1,2)'), isNull);
      expect(evaluator.bind('A(x)', 'B(1)'), isNull);
      expect(evaluator.bind('A(x)', 'A'), isNull);
      expect(evaluator.bind('A(x)', 'A(orange)'), isNull);
      expect(ParametricEvaluator.parameterNames('A(x,x)'), isNull);
      expect(ParametricEvaluator.parameterNames('A(1)'), isNull);
    });

    test('rewrites successor tokens without touching non-arithmetic ones', () {
      const bindings = {'x': 10.0};
      expect(evaluator.rewriteToken('A(x*0.7)', bindings), 'A(7)');
      expect(evaluator.rewriteToken('g(x)', bindings), 'g(10)');
      expect(
        evaluator.rewriteToken('color(orange)', bindings),
        'color(orange)',
      );
      expect(evaluator.rewriteToken('+', bindings), '+');
      expect(evaluator.rewriteToken('g(3)', const {}), 'g(3)');
      expect(evaluator.rewriteToken('g(1+2)', const {}), 'g(3)');
    });
  });
}
