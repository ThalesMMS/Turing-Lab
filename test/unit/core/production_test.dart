import 'package:flutter_test/flutter_test.dart';
import 'package:turing_lab/core/models/production.dart';

void main() {
  group('Production equality', () {
    test('compares left and right sides by value', () {
      final first = Production(
        id: 'p',
        leftSide: ['S'],
        rightSide: ['A', 'B'],
        order: 1,
      );
      final second = Production(
        id: 'p',
        leftSide: List<String>.of(['S']),
        rightSide: List<String>.of(['A', 'B']),
        order: 1,
      );

      expect(first, second);
      expect(first.hashCode, second.hashCode);
      expect({first, second}, hasLength(1));
      expect({first}.contains(second), isTrue);
    });
  });
}
