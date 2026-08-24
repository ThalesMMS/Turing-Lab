//
//  regex_pipeline_test.dart
//  Turing Lab
//
//  Tests that validate the regular-expression pipeline through construction of
//  nondeterministic finite automata, covering literals, concatenation,
//  union, Kleene star, and optional operators, and confirming
//  proper handling of invalid parser input.
//
//  Thales Matheus Mendonça Santos - October 2025
//

import 'package:flutter_test/flutter_test.dart';
import 'package:turing_lab/core/algorithms/automaton_simulator.dart';
import 'package:turing_lab/core/algorithms/regex_to_nfa_converter.dart';
import 'package:turing_lab/core/models/fsa.dart';
import 'package:turing_lab/core/result.dart';

Future<bool> _accepts(FSA nfa, String input) async {
  final sim = await AutomatonSimulator.simulateNFA(nfa, input);
  if (!sim.isSuccess) return false;
  return sim.data!.accepted;
}

void _expectStateFlagsMatchRoles(FSA nfa) {
  final initialIds =
      nfa.initialState == null ? <String>{} : <String>{nfa.initialState!.id};
  final acceptingIds = nfa.acceptingStates.map((state) => state.id).toSet();

  expect(
    nfa.states.where((state) => state.isInitial).map((state) => state.id),
    unorderedEquals(initialIds),
  );
  expect(
    nfa.states.where((state) => state.isAccepting).map((state) => state.id),
    unorderedEquals(acceptingIds),
  );
}

void main() {
  group('Regex→AST→Thompson NFA pipeline', () {
    test('Literal symbol', () async {
      final res = RegexToNFAConverter.convert('a');
      expect(res.isSuccess, true);
      final nfa = res.data!;
      expect(await _accepts(nfa, 'a'), true);
      expect(await _accepts(nfa, ''), false);
      expect(await _accepts(nfa, 'b'), false);
    });

    test('Concatenation', () async {
      final res = RegexToNFAConverter.convert('ab');
      expect(res.isSuccess, true);
      final nfa = res.data!;
      expect(await _accepts(nfa, 'ab'), true);
      expect(await _accepts(nfa, 'a'), false);
      expect(await _accepts(nfa, 'b'), false);
    });

    test('Union', () async {
      final res = RegexToNFAConverter.convert('a|b');
      expect(res.isSuccess, true);
      final nfa = res.data!;
      expect(await _accepts(nfa, 'a'), true);
      expect(await _accepts(nfa, 'b'), true);
      expect(await _accepts(nfa, 'ab'), false);
    });

    test('Composite NFA state flags match the final automaton roles', () {
      for (final regex in const ['ab', 'a|b']) {
        final res = RegexToNFAConverter.convert(regex);
        expect(res.isSuccess, true, reason: regex);
        _expectStateFlagsMatchRoles(res.data!);
      }
    });

    test('Kleene star', () async {
      final res = RegexToNFAConverter.convert('a*');
      expect(res.isSuccess, true);
      final nfa = res.data!;
      expect(await _accepts(nfa, ''), true);
      expect(await _accepts(nfa, 'a'), true);
      expect(await _accepts(nfa, 'aaaa'), true);
      expect(await _accepts(nfa, 'b'), false);
    });

    test('Plus and Question', () async {
      final res = RegexToNFAConverter.convert('a+b?');
      expect(res.isSuccess, true);
      final nfa = res.data!;
      expect(await _accepts(nfa, 'a'), true);
      expect(await _accepts(nfa, 'ab'), true);
      expect(await _accepts(nfa, 'aaab'), true);
      expect(await _accepts(nfa, ''), false);
      expect(await _accepts(nfa, 'b'), false);
    });

    test('Parentheses and precedence', () async {
      final res = RegexToNFAConverter.convert('(ab|c)d');
      expect(res.isSuccess, true);
      final nfa = res.data!;
      expect(await _accepts(nfa, 'abd'), true);
      expect(await _accepts(nfa, 'cd'), true);
      expect(await _accepts(nfa, 'ad'), false);
    });

    test('Epsilon literal', () async {
      final res = RegexToNFAConverter.convert('ε');
      expect(res.isSuccess, true);
      final nfa = res.data!;
      expect(await _accepts(nfa, ''), true);
      expect(await _accepts(nfa, 'a'), false);
    });

    test('Character class', () async {
      final res = RegexToNFAConverter.convert('[abc]');
      expect(res.isSuccess, true);
      final nfa = res.data!;
      expect(await _accepts(nfa, 'a'), true);
      expect(await _accepts(nfa, 'b'), true);
      expect(await _accepts(nfa, 'c'), true);
      expect(await _accepts(nfa, 'd'), false);
    });

    test('Character class ranges and escapes are validated by tokenizer',
        () async {
      final range = RegexToNFAConverter.convert('[a-c]');
      expect(range.isSuccess, true);
      expect(await _accepts(range.data!, 'a'), true);
      expect(await _accepts(range.data!, 'b'), true);
      expect(await _accepts(range.data!, 'c'), true);
      expect(await _accepts(range.data!, 'd'), false);

      final escapedParen = RegexToNFAConverter.convert(r'\(');
      expect(escapedParen.isSuccess, true);
      expect(await _accepts(escapedParen.data!, '('), true);
      expect(await _accepts(escapedParen.data!, ')'), false);
    });

    test('Shortcut complements use the provided context alphabet', () async {
      final digit = RegexToNFAConverter.convert(r'\d');
      expect(digit.isSuccess, true);
      expect(await _accepts(digit.data!, '4'), true);
      expect(await _accepts(digit.data!, 'a'), false);

      final nonDigit = RegexToNFAConverter.convert(
        r'\D',
        contextAlphabet: const {'a', '4'},
      );
      expect(nonDigit.isSuccess, true);
      expect(await _accepts(nonDigit.data!, 'a'), true);
      expect(await _accepts(nonDigit.data!, '4'), false);
    });

    test('Dot requires and uses an explicit alphabet', () async {
      final missingAlphabet = RegexToNFAConverter.convert('.');
      expect(missingAlphabet.isFailure, true);
      expect(missingAlphabet.error, contains('requires a non-empty alphabet'));

      final res = RegexToNFAConverter.convert(
        '.',
        contextAlphabet: const {'a', 'b', 'c', 'd'},
      );
      expect(res.isSuccess, true);
      final nfa = res.data!;
      expect(await _accepts(nfa, 'a'), true);
      expect(await _accepts(nfa, 'b'), true);
      expect(await _accepts(nfa, 'c'), true);
      expect(await _accepts(nfa, 'd'), true);
    });

    test('Complex expression (a|bc)*d', () async {
      final res = RegexToNFAConverter.convert('(a|bc)*d');
      expect(res.isSuccess, true);
      final nfa = res.data!;
      expect(await _accepts(nfa, 'd'), true);
      expect(await _accepts(nfa, 'ad'), true);
      expect(await _accepts(nfa, 'bcd'), true);
      expect(await _accepts(nfa, 'abcad'), true);
      expect(await _accepts(nfa, 'ab'), false);
    });

    test('Integrates via RegexToNFAConverter', () async {
      final Result<FSA> res = RegexToNFAConverter.convert('a(b|c)*');
      expect(res.isSuccess, true);
      final nfa = res.data!;
      expect(await _accepts(nfa, 'a'), true);
      expect(await _accepts(nfa, 'ab'), true);
      expect(await _accepts(nfa, 'accc'), true);
      expect(await _accepts(nfa, ''), false);

      final recognition = await AutomatonSimulator.simulateNFA(nfa, 'accc');
      expect(recognition.data!.computationTree, isNull);
      expect(recognition.data!.steps, isEmpty);
    });
  });
}
