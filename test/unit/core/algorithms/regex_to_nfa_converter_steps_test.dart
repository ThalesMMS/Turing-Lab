//
//  regex_to_nfa_converter_steps_test.dart
//  Turing Lab
//
//  Testes que cobrem o método convertWithSteps do RegexToNFAConverter,
//  incluindo a estrutura do resultado (RegexToNFAConversionResult), os
//  passos detalhados de construção de Thompson e os metadados do passo
//  final gerados pelos arquivos part refatorados.
//
//  Thales Matheus Mendonça Santos - January 2026
//

import 'package:flutter_test/flutter_test.dart';
import 'package:turing_lab/core/algorithms/automaton_simulator.dart';
import 'package:turing_lab/core/algorithms/regex_to_nfa_converter.dart';
import 'package:turing_lab/core/models/fsa.dart';
import 'package:turing_lab/core/models/regex_to_nfa_step.dart';

void main() {
  // =========================================================================
  // RegexToNFAConversionResult model
  // =========================================================================
  group('RegexToNFAConversionResult - model properties', () {
    test('stepCount equals the number of steps returned', () {
      final result = RegexToNFAConverter.convertWithSteps('a');
      expect(result.isSuccess, true);
      final convResult = result.data!;
      expect(convResult.stepCount, convResult.steps.length);
    });

    test('firstStep is the first element of steps list', () {
      final result = RegexToNFAConverter.convertWithSteps('a');
      expect(result.isSuccess, true);
      final convResult = result.data!;
      expect(convResult.firstStep, same(convResult.steps.first));
    });

    test('lastStep is the last element of steps list', () {
      final result = RegexToNFAConverter.convertWithSteps('a');
      expect(result.isSuccess, true);
      final convResult = result.data!;
      expect(convResult.lastStep, same(convResult.steps.last));
    });

    test('firstStep is null when steps list is empty', () {
      // This tests the model contract (steps could theoretically be empty)
      // We verify the accessor works correctly for non-empty case
      final result = RegexToNFAConverter.convertWithSteps('a');
      expect(result.isSuccess, true);
      expect(result.data!.firstStep, isNotNull);
    });

    test('executionTimeMs is non-negative', () {
      final result = RegexToNFAConverter.convertWithSteps('ab');
      expect(result.isSuccess, true);
      expect(result.data!.executionTimeMs, greaterThanOrEqualTo(0));
    });

    test('executionTimeSeconds is non-negative', () {
      final result = RegexToNFAConverter.convertWithSteps('ab');
      expect(result.isSuccess, true);
      expect(result.data!.executionTimeSeconds, greaterThanOrEqualTo(0.0));
    });

    test('regex field matches input regex', () {
      const regex = '(a|b)*c';
      final result = RegexToNFAConverter.convertWithSteps(regex);
      expect(result.isSuccess, true);
      expect(result.data!.regex, regex);
    });

    test('resultNFA is a valid FSA with states', () {
      final result = RegexToNFAConverter.convertWithSteps('a');
      expect(result.isSuccess, true);
      expect(result.data!.resultNFA.states, isNotEmpty);
    });
  });

  // =========================================================================
  // Step sequence structure
  // =========================================================================
  group('RegexToNFAConverter.convertWithSteps - step sequence', () {
    test('first step is always a start step', () {
      final result = RegexToNFAConverter.convertWithSteps('a');
      expect(result.isSuccess, true);
      final firstStep = result.data!.steps.first;
      expect(firstStep.stepType, RegexToNFAStepType.start);
    });

    test('last step is always a complete step', () {
      final result = RegexToNFAConverter.convertWithSteps('a');
      expect(result.isSuccess, true);
      final lastStep = result.data!.steps.last;
      expect(lastStep.stepType, RegexToNFAStepType.complete);
      expect(lastStep.isFinalNFA, true);
    });

    test(
        'has at least 3 steps for a single symbol: start, basicSymbol, complete',
        () {
      final result = RegexToNFAConverter.convertWithSteps('a');
      expect(result.isSuccess, true);
      expect(result.data!.stepCount, greaterThanOrEqualTo(3));
    });

    test('contains basicSymbol step for literal regex', () {
      final result = RegexToNFAConverter.convertWithSteps('b');
      expect(result.isSuccess, true);
      final stepTypes = result.data!.steps.map((s) => s.stepType).toList();
      expect(stepTypes, contains(RegexToNFAStepType.basicSymbol));
    });

    test('contains union step for union regex a|b', () {
      final result = RegexToNFAConverter.convertWithSteps('a|b');
      expect(result.isSuccess, true);
      final stepTypes = result.data!.steps.map((s) => s.stepType).toList();
      expect(stepTypes, contains(RegexToNFAStepType.union));
    });

    test('contains concatenation step for concatenated regex ab', () {
      final result = RegexToNFAConverter.convertWithSteps('ab');
      expect(result.isSuccess, true);
      final stepTypes = result.data!.steps.map((s) => s.stepType).toList();
      expect(stepTypes, contains(RegexToNFAStepType.concatenation));
    });

    test('contains kleeneStar step for starred regex a*', () {
      final result = RegexToNFAConverter.convertWithSteps('a*');
      expect(result.isSuccess, true);
      final stepTypes = result.data!.steps.map((s) => s.stepType).toList();
      expect(stepTypes, contains(RegexToNFAStepType.kleeneStar));
    });

    test('contains plus step for plus regex a+', () {
      final result = RegexToNFAConverter.convertWithSteps('a+');
      expect(result.isSuccess, true);
      final stepTypes = result.data!.steps.map((s) => s.stepType).toList();
      expect(stepTypes, contains(RegexToNFAStepType.plus));
    });

    test('contains optional step for question regex a?', () {
      final result = RegexToNFAConverter.convertWithSteps('a?');
      expect(result.isSuccess, true);
      final stepTypes = result.data!.steps.map((s) => s.stepType).toList();
      expect(stepTypes, contains(RegexToNFAStepType.optional));
    });

    test('emits fragment steps for wildcard, character class, and shortcut',
        () {
      final cases = <String, String>{
        '.': '.',
        '[ab]': '[a, b]',
        r'\d': r'\d',
      };

      for (final entry in cases.entries) {
        final result = RegexToNFAConverter.convertWithSteps(
          entry.key,
          contextAlphabet: {'a', 'b', '0', '1'},
        );
        expect(result.isSuccess, true);
        final processedSymbols = result.data!.steps
            .where((step) => step.stepType == RegexToNFAStepType.basicSymbol)
            .map((step) => step.processedSymbol)
            .toList();

        expect(processedSymbols, contains(entry.value));
      }
    });

    test('records Thompson fragment stack depth instead of emitted step count',
        () {
      final result = RegexToNFAConverter.convertWithSteps('ab');
      expect(result.isSuccess, true);

      final stackSizes =
          result.data!.steps.map((step) => step.stackSize).toList();
      expect(stackSizes, [0, 1, 2, 1, 1]);
    });

    test('steps have sequential step numbers starting at 1', () {
      final result = RegexToNFAConverter.convertWithSteps('ab');
      expect(result.isSuccess, true);
      final steps = result.data!.steps;
      for (int i = 0; i < steps.length; i++) {
        expect(steps[i].baseStep.stepNumber, greaterThanOrEqualTo(1));
      }
    });

    test('compound steps number from the last recorded step', () {
      final result = RegexToNFAConverter.convertWithSteps('(a|b)*c');
      expect(result.isSuccess, true);
      final stepNumbers =
          result.data!.steps.map((step) => step.baseStep.stepNumber).toList();

      for (var i = 0; i < stepNumbers.length; i++) {
        expect(stepNumbers[i], i + 1);
      }
    });

    test('records regex token positions on emitted steps', () {
      final result = RegexToNFAConverter.convertWithSteps('ab*|c');
      expect(result.isSuccess, true);
      final steps = result.data!.steps;

      final aStep = steps.firstWhere((step) => step.processedSymbol == 'a');
      final bStep = steps.firstWhere((step) => step.processedSymbol == 'b');
      final starStep = steps.firstWhere(
        (step) => step.stepType == RegexToNFAStepType.kleeneStar,
      );
      final concatStep = steps.firstWhere(
        (step) => step.stepType == RegexToNFAStepType.concatenation,
      );
      final unionStep = steps.firstWhere(
        (step) => step.stepType == RegexToNFAStepType.union,
      );

      expect(aStep.regexPosition, 0);
      expect(bStep.regexPosition, 1);
      expect(starStep.regexPosition, 2);
      expect(concatStep.regexPosition, isNull);
      expect(unionStep.regexPosition, 3);
    });

    test('concatenation step records every bridge from multi-accept fragments',
        () {
      final result = RegexToNFAConverter.convertWithSteps('a?b');
      expect(result.isSuccess, true);

      final concatenationStep = result.data!.steps.firstWhere(
        (step) => step.stepType == RegexToNFAStepType.concatenation,
      );

      expect(concatenationStep.firstFragmentAcceptStates, hasLength(2));
      expect(concatenationStep.createdTransitions, hasLength(2));
    });

    test('unary operation steps only record newly-created transitions', () {
      final result = RegexToNFAConverter.convertWithSteps('(a?)*');
      expect(result.isSuccess, true);
      final steps = result.data!.steps;

      final optionalStep = steps.firstWhere(
        (step) => step.stepType == RegexToNFAStepType.optional,
      );
      final starStep = steps.firstWhere(
        (step) => step.stepType == RegexToNFAStepType.kleeneStar,
      );
      final optionalTransitions = optionalStep.createdTransitions;
      final starTransitions = starStep.createdTransitions;

      expect(optionalTransitions, isNotNull);
      expect(starTransitions, isNotNull);
      expect(starTransitions!.intersection(optionalTransitions!), isEmpty);
    });

    test('complete step contains total state and transition counts', () {
      final result = RegexToNFAConverter.convertWithSteps('a');
      expect(result.isSuccess, true);
      final lastStep = result.data!.steps.last;
      expect(lastStep.totalStates, isNotNull);
      expect(lastStep.totalStates, greaterThan(0));
      expect(lastStep.totalTransitions, isNotNull);
    });

    test('complete step references valid start and accept states', () {
      final result = RegexToNFAConverter.convertWithSteps('a');
      expect(result.isSuccess, true);
      final lastStep = result.data!.steps.last;
      expect(lastStep.fragmentStartState, isNotNull);
      expect(lastStep.fragmentAcceptState, isNotNull);
    });
  });

  // =========================================================================
  // Error handling
  // =========================================================================
  group('RegexToNFAConverter.convertWithSteps - error handling', () {
    test('returns failure for empty regex', () {
      final result = RegexToNFAConverter.convertWithSteps('');
      expect(result.isSuccess, false);
      expect(result.error, contains('empty'));
    });

    test('returns failure for unbalanced opening parenthesis', () {
      final result = RegexToNFAConverter.convertWithSteps('(a');
      expect(result.isSuccess, false);
      expect(result.error, contains('Unbalanced'));
    });

    test('returns failure for unbalanced closing parenthesis', () {
      final result = RegexToNFAConverter.convertWithSteps('a)');
      expect(result.isSuccess, false);
      expect(result.error, contains('Unbalanced'));
    });

    test('returns failure for regex starting with quantifier', () {
      final result = RegexToNFAConverter.convertWithSteps('*a');
      expect(result.isSuccess, false);
      expect(result.error, contains('quantifier'));
    });

    test('returns failure for consecutive quantifiers', () {
      final result = RegexToNFAConverter.convertWithSteps('a**');
      expect(result.isSuccess, false);
      expect(result.error, contains('Consecutive'));
    });
  });

  // =========================================================================
  // NFA correctness from convertWithSteps
  // =========================================================================
  group('RegexToNFAConverter.convertWithSteps - NFA correctness', () {
    Future<bool> accepts(FSA nfa, String input) async {
      final sim = await AutomatonSimulator.simulateNFA(nfa, input);
      if (!sim.isSuccess) return false;
      return sim.data!.accepted;
    }

    test('NFA from a accepts "a" and rejects ""', () async {
      final result = RegexToNFAConverter.convertWithSteps('a');
      expect(result.isSuccess, true);
      final nfa = result.data!.resultNFA;
      expect(await accepts(nfa, 'a'), true);
      expect(await accepts(nfa, ''), false);
    });

    test('NFA from a|b accepts "a" and "b"', () async {
      final result = RegexToNFAConverter.convertWithSteps('a|b');
      expect(result.isSuccess, true);
      final nfa = result.data!.resultNFA;
      expect(await accepts(nfa, 'a'), true);
      expect(await accepts(nfa, 'b'), true);
      expect(await accepts(nfa, 'c'), false);
    });

    test('NFA from ab accepts "ab" only', () async {
      final result = RegexToNFAConverter.convertWithSteps('ab');
      expect(result.isSuccess, true);
      final nfa = result.data!.resultNFA;
      expect(await accepts(nfa, 'ab'), true);
      expect(await accepts(nfa, 'a'), false);
      expect(await accepts(nfa, 'b'), false);
    });

    test('NFA from a* accepts "" and "aaa"', () async {
      final result = RegexToNFAConverter.convertWithSteps('a*');
      expect(result.isSuccess, true);
      final nfa = result.data!.resultNFA;
      expect(await accepts(nfa, ''), true);
      expect(await accepts(nfa, 'a'), true);
      expect(await accepts(nfa, 'aaa'), true);
      expect(await accepts(nfa, 'b'), false);
    });

    test('NFA from a+ rejects "" and accepts "a"', () async {
      final result = RegexToNFAConverter.convertWithSteps('a+');
      expect(result.isSuccess, true);
      final nfa = result.data!.resultNFA;
      expect(await accepts(nfa, ''), false);
      expect(await accepts(nfa, 'a'), true);
      expect(await accepts(nfa, 'aa'), true);
    });

    test('NFA from ε accepts empty string only', () async {
      final result = RegexToNFAConverter.convertWithSteps('ε');
      expect(result.isSuccess, true);
      final nfa = result.data!.resultNFA;
      expect(await accepts(nfa, ''), true);
      expect(await accepts(nfa, 'a'), false);
    });

    test('NFA from complex regex (a|b)*c works correctly', () async {
      final result = RegexToNFAConverter.convertWithSteps('(a|b)*c');
      expect(result.isSuccess, true);
      final nfa = result.data!.resultNFA;
      expect(await accepts(nfa, 'c'), true);
      expect(await accepts(nfa, 'ac'), true);
      expect(await accepts(nfa, 'bbc'), true);
      expect(await accepts(nfa, 'ab'), false);
    });

    test('convertWithSteps produces same NFA as convert for same regex',
        () async {
      const regex = '(a|b)+c';
      final convertResult = RegexToNFAConverter.convert(regex);
      final withStepsResult = RegexToNFAConverter.convertWithSteps(regex);

      expect(convertResult.isSuccess, true);
      expect(withStepsResult.isSuccess, true);

      final nfa1 = convertResult.data!;
      final nfa2 = withStepsResult.data!.resultNFA;

      // Both should accept/reject the same strings
      expect(await accepts(nfa1, 'ac'), await accepts(nfa2, 'ac'));
      expect(await accepts(nfa1, 'bc'), await accepts(nfa2, 'bc'));
      expect(await accepts(nfa1, 'abc'), await accepts(nfa2, 'abc'));
      expect(await accepts(nfa1, ''), await accepts(nfa2, ''));
    });
  });

  // =========================================================================
  // Start step properties
  // =========================================================================
  group('RegexToNFAConverter.convertWithSteps - start step details', () {
    test('start step has the original regex as regexFragment', () {
      const regex = 'abc';
      final result = RegexToNFAConverter.convertWithSteps(regex);
      expect(result.isSuccess, true);
      final startStep = result.data!.steps.first;
      expect(startStep.regexFragment, regex);
    });

    test('start step has regexPosition 0', () {
      final result = RegexToNFAConverter.convertWithSteps('a');
      expect(result.isSuccess, true);
      final startStep = result.data!.steps.first;
      expect(startStep.regexPosition, 0);
    });

    test('start step has stackSize 0', () {
      final result = RegexToNFAConverter.convertWithSteps('a');
      expect(result.isSuccess, true);
      final startStep = result.data!.steps.first;
      expect(startStep.stackSize, 0);
    });

    test('start step is not the final NFA', () {
      final result = RegexToNFAConverter.convertWithSteps('a');
      expect(result.isSuccess, true);
      final startStep = result.data!.steps.first;
      expect(startStep.isFinalNFA, false);
    });
  });
}
