import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:turing_lab/core/algorithms/regex_to_nfa_converter.dart';
import 'package:turing_lab/core/models/regex_document.dart';
import 'package:turing_lab/presentation/providers/regex_editor_provider.dart';

void main() {
  group('RegexEditorNotifier', () {
    late ProviderContainer container;
    late RegexEditorNotifier notifier;

    setUp(() {
      container = ProviderContainer();
      notifier = container.read(regexEditorProvider.notifier);
    });

    tearDown(() {
      container.dispose();
    });

    test('validateRegex stores valid input and clears stale test state',
        () async {
      notifier.validateRegex('(a|b)*');
      await notifier.testStringMatch('abb');

      notifier.validateRegex('a(b|c)');

      final state = container.read(regexEditorProvider);
      expect(state.currentRegex, 'a(b|c)');
      expect(state.isValid, true);
      expect(state.hasTested, false);
      expect(state.errorMessage, isEmpty);
    });

    test('validateRegex rejects unbalanced parentheses', () {
      notifier.validateRegex('(ab');

      final state = container.read(regexEditorProvider);
      expect(state.currentRegex, '(ab');
      expect(state.isValid, false);
      expect(state.errorMessage, contains('position 1'));
      expect(state.validationDiagnostic?.position, 0);
      expect(
        state.validationDiagnostic?.category,
        RegexValidationCategory.delimiter,
      );
    });

    test('testStringMatch records accepted and rejected inputs', () async {
      notifier.validateRegex('a*');

      await notifier.testStringMatch('aaa');
      var state = container.read(regexEditorProvider);
      expect(state.testString, 'aaa');
      expect(state.hasTested, true);
      expect(state.matches, true);
      expect(state.errorMessage, isEmpty);

      await notifier.testStringMatch('b');
      state = container.read(regexEditorProvider);
      expect(state.testString, 'b');
      expect(state.hasTested, true);
      expect(state.matches, false);

      notifier.validateRegex('(ab');
      await notifier.testStringMatch('a');
      state = container.read(regexEditorProvider);
      expect(state.canRunRegexOperation, false);
      expect(state.testString, 'a');
      expect(state.hasTested, false);
      expect(state.matches, false);
      expect(state.errorMessage, contains('position 1'));
    });

    test('testStringMatch ignores stale async results', () async {
      notifier.validateRegex('a*');

      final staleRequest = notifier.testStringMatch('aaa');
      notifier.validateRegex('b*');
      await notifier.testStringMatch('a');
      await staleRequest;

      final state = container.read(regexEditorProvider);
      expect(state.currentRegex, 'b*');
      expect(state.testString, 'a');
      expect(state.hasTested, true);
      expect(state.matches, false);
    });

    test('compareRegexEquivalence records equivalent and distinct regexes', () {
      notifier.compareRegexEquivalence('a|b', 'b|a');
      var state = container.read(regexEditorProvider);
      expect(state.equivalenceResult, true);
      expect(
        state.equivalenceMessage,
        'The regular expressions are equivalent.',
      );

      notifier.compareRegexEquivalence('a', 'b');
      state = container.read(regexEditorProvider);
      expect(state.equivalenceResult, false);
      expect(
        state.equivalenceMessage,
        'The regular expressions are not equivalent.',
      );
    });

    test('convertToDfa returns a completed DFA for valid current regex', () {
      notifier.validateRegex('a|b');

      final result = notifier.convertToDfa();

      expect(result.isSuccess, true);
      expect(result.data, isNotNull);
      expect(result.data!.states, isNotEmpty);
      expect(result.data!.initialState, isNotNull);
      expect(result.data!.acceptingStates, isNotEmpty);
    });

    test('clearInputs resets editor results and settings that depend on input',
        () {
      notifier.validateRegex('a*');
      notifier.setSimplifyOutput(false);
      notifier.runSimplificationWithSteps();
      notifier.compareRegexEquivalence('a', 'a');

      notifier.clearInputs();

      final state = container.read(regexEditorProvider);
      expect(state.currentRegex, isEmpty);
      expect(state.testString, isEmpty);
      expect(state.isValid, false);
      expect(state.simplifyOutput, false);
      expect(state.simplificationResult, isNull);
      expect(state.equivalenceResult, isNull);
      expect(state.equivalenceMessage, isEmpty);
    });

    test('canonical parser rejects malformed expressions with source spans',
        () {
      final cases = <String, int>{
        'a\\': 1,
        'a|': 1,
        '|a': 0,
        'a**': 2,
        'a++': 2,
        'a??': 2,
        '[z-a]': 1,
        '[ab': 0,
        '()': 1,
      };

      for (final entry in cases.entries) {
        notifier.validateRegex(entry.key);
        final state = container.read(regexEditorProvider);
        final converterValidation = RegexToNFAConverter.validate(entry.key);
        final conversion = RegexToNFAConverter.convert(entry.key);

        expect(state.isValid, isFalse, reason: entry.key);
        expect(state.canRunRegexOperation, isFalse, reason: entry.key);
        expect(state.validationDiagnostic?.position, entry.value,
            reason: entry.key);
        expect(state.validationDiagnostic?.length, greaterThan(0),
            reason: entry.key);
        expect(converterValidation.isValid, isFalse, reason: entry.key);
        expect(conversion.isSuccess, isFalse, reason: entry.key);
      }
    });

    test('canonical parser keeps advanced expressions enabled', () {
      const validExpressions = [
        r'\d',
        '[a-z]',
        r'\*',
        '(a|b)+',
        'a?',
        '.',
      ];

      for (final regex in validExpressions) {
        notifier.validateRegex(regex);
        final state = container.read(regexEditorProvider);
        final conversion = RegexToNFAConverter.convert(
          regex,
          contextAlphabet: container.read(regexEditorProvider).resolvedAlphabet,
        );

        expect(state.isValid, isTrue, reason: regex);
        expect(state.validationDiagnostic, isNull, reason: regex);
        expect(state.canRunRegexOperation, isTrue, reason: regex);
        expect(conversion.isSuccess, isTrue, reason: regex);
      }
    });

    test('resolved alphabet preserves non-BMP characters', () {
      notifier.setAlphabet('a🧪');

      expect(
        container.read(regexEditorProvider).resolvedAlphabet,
        {'a', '🧪'},
      );
    });

    test('document replacement preserves identity and invalidates derived data',
        () {
      notifier.validateRegex('a*');
      notifier.runComplexityAnalysis();
      final generation = container.read(regexEditorProvider).documentGeneration;

      notifier.replaceDocument(
        RegexDocument(
          id: 'imported-regex',
          name: 'Imported regex',
          source: '(β|a)*',
          alphabet: const ['β', 'a'],
        ),
      );

      final state = container.read(regexEditorProvider);
      expect(state.documentId, 'imported-regex');
      expect(state.documentName, 'Imported regex');
      expect(state.documentGeneration, greaterThan(generation));
      expect(state.currentRegex, '(β|a)*');
      expect(state.alphabet, 'βa');
      expect(state.isValid, isTrue);
      expect(state.regexAnalysis, isNull);
      final rebuilt = notifier.buildDocument();
      expect(rebuilt.id, 'imported-regex');
      expect(rebuilt.source, '(β|a)*');
      expect(rebuilt.alphabet, ['β', 'a']);
    });

    test('changing the source regex invalidates every derived result',
        () async {
      notifier.validateRegex('a*');
      await notifier.testStringMatch('aaa');
      notifier.compareRegexEquivalence('a*', 'a*');
      notifier.runSimplificationWithSteps();
      notifier.runComplexityAnalysis();
      notifier.runSampleGeneration();

      notifier.validateRegex('b');

      final state = container.read(regexEditorProvider);
      expect(state.currentRegex, 'b');
      expect(state.matches, isFalse);
      expect(state.hasTested, isFalse);
      expect(state.equivalenceResult, isNull);
      expect(state.equivalenceMessage, isEmpty);
      expect(state.simplificationResult, isNull);
      expect(state.showSimplificationSteps, isFalse);
      expect(state.selectedStepIndex, 0);
      expect(state.regexAnalysis, isNull);
      expect(state.showAnalysisDetails, isFalse);
      expect(state.sampleStrings, isNull);
      expect(state.showSampleStringsDetails, isFalse);
    });

    test('changing only test input preserves unrelated regex results',
        () async {
      notifier.validateRegex('a*');
      notifier.runSimplificationWithSteps();
      notifier.runComplexityAnalysis();
      notifier.runSampleGeneration();

      final pendingMatch = notifier.testStringMatch('aaa');
      var state = container.read(regexEditorProvider);
      expect(state.matches, isFalse);
      expect(state.hasTested, isFalse);
      expect(state.simplificationResult, isNotNull);
      expect(state.regexAnalysis, isNotNull);
      expect(state.sampleStrings, isNotNull);

      await pendingMatch;
      state = container.read(regexEditorProvider);
      expect(state.hasTested, isTrue);
      expect(state.matches, isTrue);
      expect(state.simplificationResult, isNotNull);
      expect(state.regexAnalysis, isNotNull);
      expect(state.sampleStrings, isNotNull);
    });

    test('all universe-dependent operations share the configured alphabet',
        () async {
      notifier.setAlphabet('a1! ');

      final cases = <String, Map<String, bool>>{
        '.': {'!': true},
        r'\D': {'a': true, '1': false},
        r'\W': {'!': true, 'a': false},
        r'\S': {'a': true, ' ': false},
      };

      for (final entry in cases.entries) {
        notifier.validateRegex(entry.key);
        expect(notifier.convertToNfa().isSuccess, isTrue, reason: entry.key);
        expect(notifier.convertToDfa().isSuccess, isTrue, reason: entry.key);
        expect(notifier.runSampleGeneration(maxSamples: 4).isSuccess, isTrue,
            reason: entry.key);
        for (final expectation in entry.value.entries) {
          await notifier.testStringMatch(expectation.key);
          expect(
            container.read(regexEditorProvider).matches,
            expectation.value,
            reason: '${entry.key} on ${expectation.key}',
          );
        }
      }
    });

    test('empty configured alphabet disables operations', () {
      notifier.setAlphabet('');
      notifier.validateRegex('.');

      expect(container.read(regexEditorProvider).canRunRegexOperation, isFalse);
      expect(notifier.convertToNfa().isFailure, isTrue);
    });
  });
}
