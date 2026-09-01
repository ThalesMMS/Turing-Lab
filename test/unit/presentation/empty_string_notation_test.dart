import 'package:flutter_test/flutter_test.dart';
import 'package:turing_lab/core/utils/epsilon_utils.dart';
import 'package:turing_lab/presentation/empty_string_notation.dart';

void main() {
  group('empty-string marker formatting', () {
    test('normalizes only supported display preferences', () {
      expect(normalizeEmptyStringDisplaySymbol(kLambdaSymbol), kLambdaSymbol);
      expect(normalizeEmptyStringDisplaySymbol(kEpsilonSymbol), kEpsilonSymbol);
      expect(normalizeEmptyStringDisplaySymbol('unexpected'), kEpsilonSymbol);
      expect(normalizeEmptyStringDisplaySymbol(null), kEpsilonSymbol);
    });

    test('formats canonical markers without rewriting genuine lambda data', () {
      expect(formatEmptyStringMarkers('ε,ϵ,a λx', kLambdaSymbol), 'λ,λ,a λx');
      expect(formatEmptyStringMarkers('ε,ϵ,a λx', kEpsilonSymbol), 'ε,ε,a λx');
    });

    test('handles punctuation, NFA names, PDA labels, and quoted words', () {
      expect(
        formatEmptyStringMarkers('ε-NFA: (ε, Z) → "ε".', kLambdaSymbol),
        'λ-NFA: (λ, Z) → "λ".',
      );
    });
  });

  group('empty-string terminology formatting', () {
    test('switches trusted English terminology in either direction', () {
      expect(
        formatEmptyStringTerminology(
          'Epsilon closure and epsilon transitions',
          kLambdaSymbol,
        ),
        'Lambda closure and lambda transitions',
      );
      expect(
        formatEmptyStringTerminology(
          'Remove Lambda and lambda transitions',
          kEpsilonSymbol,
        ),
        'Remove Epsilon and epsilon transitions',
      );
    });

    test('can preserve explicit epsilon versus lambda comparison copy', () {
      const comparison = 'Both ε (epsilon) and λ (lambda) are accepted.';
      expect(
        formatEmptyStringTerminology(
          comparison,
          kLambdaSymbol,
          preserveComparison: true,
        ),
        comparison,
      );
    });
  });
}
