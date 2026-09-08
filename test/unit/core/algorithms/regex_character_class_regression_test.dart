import 'package:flutter_test/flutter_test.dart';
import 'package:turing_lab/core/algorithms/regex/regex_analyzer.dart';

void main() {
  for (final entry in <String, Set<String>>{
    r'[a\-z]': {'a', '-', 'z'},
    '[a-c]': {'a', 'b', 'c'},
    '[a-z]': {
      for (var code = 97; code <= 122; code++) String.fromCharCode(code),
    },
    r'[a-\c]': {'a', 'b', 'c'},
    r'[\--0]': {'-', '.', '/', '0'},
    r'[a\-\]]': {'a', '-', ']'},
    r'[a\\z]': {'a', r'\', 'z'},
    r'\[': {'['},
    r'[a\]]': {'a', ']'},
  }.entries) {
    test('character class alphabet preserves escapes in ${entry.key}', () {
      final result = RegexAnalyzer.extractAlphabet(entry.key);
      expect(result.isSuccess, isTrue, reason: result.error);
      expect(result.data, entry.value);
    });
  }

  for (final regex in ['[', '[abc', r'[a\]', '[abc\\']) {
    test('rejects the unterminated character class $regex', () {
      final result = RegexAnalyzer.analyze(regex);
      expect(result.isSuccess, isFalse);
      expect(result.error, 'Character class is not closed');
      expect(RegexAnalyzer.computeNestingDepth(regex).isSuccess, isFalse);
    });
  }
}
