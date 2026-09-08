import 'package:flutter_test/flutter_test.dart';
import 'package:turing_lab/core/algorithms/regex/regex_analyzer.dart';

void main() {
  for (final entry in <String, int>{
    r'\(a\)': 0,
    r'\)(a)': 1,
    '[(]': 0,
    '[)](a)': 1,
    r'([()](a))': 2,
    r'(\[a\])': 1,
    r'(\\(a))': 2,
  }.entries) {
    test('ignores literal delimiters in ${entry.key}', () {
      final result = RegexAnalyzer.computeNestingDepth(entry.key);
      expect(result.isSuccess, isTrue);
      expect(result.data, entry.value);
    });
  }
}
