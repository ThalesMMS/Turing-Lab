//
//  language_comparator_test.dart
//  Turing Lab
//
//  Test suite for LanguageComparator when comparing
//  DFA and NFA languages. Covers equivalence, non-equivalence,
//  distinguishing-string generation, and edge cases. Checks that the product
//  algorithm correctly identifies differences between languages recognized
//  by automata built in different ways.
//
//  Thales Matheus Mendonça Santos - January 2026
//
import 'package:flutter_test/flutter_test.dart';
import 'package:turing_lab/core/models/fsa.dart';
import 'package:turing_lab/core/models/state.dart';
import 'package:turing_lab/core/models/fsa_transition.dart';
import 'package:turing_lab/core/algorithms/language_comparator.dart';
import 'package:vector_math/vector_math_64.dart';
import 'dart:math' as math;

import 'fsa_test_fixtures.dart';

part 'language_comparator_fsa_fixtures_a.dart';
part 'language_comparator_fsa_fixtures_b.dart';

void main() {
  group('Language Comparator Tests', () {
    late FSA dfa1;
    late FSA dfa2;
    late FSA nfa1;
    late FSA nfa2;
    late FSA nonEquivalentDFA;
    late FSA nonEquivalentNFA;

    setUp(() {
      // Test Case 1: Equivalent DFAs - recognizes strings ending in 'a'
      dfa1 = _createDFAEndingInA();
      dfa2 = _createDFAEndingInAAlternative();

      // Test Case 2: Equivalent NFAs - recognizes strings with 'ab'
      nfa1 = _createNFAContainingAB();
      nfa2 = _createNFAContainingABAlternative();

      // Test Case 3: Non-equivalent DFA - recognizes strings ending in 'b'
      nonEquivalentDFA = _createDFAEndingInB();

      // Test Case 4: Non-equivalent NFA - recognizes strings starting with 'a'
      nonEquivalentNFA = _createNFAStartingWithA();
    });

    group('Equivalent DFAs Tests', () {
      test('Equivalent DFAs should be recognized as equivalent', () {
        final result = LanguageComparator.compareLanguages(dfa1, dfa2);

        expect(result.isSuccess, true);
        expect(result.data!.isEquivalent, true);
        expect(result.data!.distinguishingString, null);
        expect(result.data!.productAutomaton, isNotNull);
        expect(result.data!.steps, isNotEmpty);
        expect(result.data!.executionTimeMs, greaterThanOrEqualTo(0));
      });

      test('Same DFA should be equivalent to itself', () {
        final result = LanguageComparator.compareLanguages(dfa1, dfa1);

        expect(result.isSuccess, true);
        expect(result.data!.isEquivalent, true);
        expect(result.data!.distinguishingString, null);
      });

      test('Non-equivalent DFAs should be recognized as non-equivalent', () {
        final result = LanguageComparator.compareLanguages(
          dfa1,
          nonEquivalentDFA,
        );

        expect(result.isSuccess, true);
        expect(result.data!.isEquivalent, false);
        expect(result.data!.distinguishingString, isNotNull);
        expect(result.data!.distinguishingString, isNotEmpty);
      });
    });

    group('Equivalent NFAs Tests', () {
      test('Equivalent NFAs should be recognized as equivalent', () {
        final result = LanguageComparator.compareLanguages(nfa1, nfa2);

        expect(result.isSuccess, true);
        expect(result.data!.isEquivalent, true);
        expect(result.data!.distinguishingString, null);
        expect(result.data!.productAutomaton, isNotNull);
      });

      test('Same NFA should be equivalent to itself', () {
        final result = LanguageComparator.compareLanguages(nfa1, nfa1);

        expect(result.isSuccess, true);
        expect(result.data!.isEquivalent, true);
        expect(result.data!.distinguishingString, null);
      });

      test('Non-equivalent NFAs should be recognized as non-equivalent', () {
        final result = LanguageComparator.compareLanguages(
          nfa1,
          nonEquivalentNFA,
        );

        expect(result.isSuccess, true);
        expect(result.data!.isEquivalent, false);
        expect(result.data!.distinguishingString, isNotNull);
      });
    });

    group('Cross-Type Comparison Tests', () {
      test('DFA and NFA with same language should be equivalent', () {
        final dfaEndingA = _createDFAEndingInA();
        final nfaEndingA = _createNFAEndingInA();

        final result = LanguageComparator.compareLanguages(
          dfaEndingA,
          nfaEndingA,
        );

        expect(result.isSuccess, true);
        expect(result.data!.isEquivalent, true);
        expect(result.data!.distinguishingString, null);
      });

      test('DFA and NFA with different languages should not be equivalent', () {
        final result = LanguageComparator.compareLanguages(
          dfa1,
          nonEquivalentNFA,
        );

        expect(result.isSuccess, true);
        expect(result.data!.isEquivalent, false);
        expect(result.data!.distinguishingString, isNotNull);
      });
    });

    group('Distinguishing String Tests', () {
      test(
        'Distinguishing string should be found for non-equivalent automata',
        () {
          final result = LanguageComparator.compareLanguages(
            dfa1,
            nonEquivalentDFA,
          );

          expect(result.isSuccess, true);
          expect(result.data!.isEquivalent, false);
          expect(result.data!.distinguishingString, isNotNull);
          expect(result.data!.distinguishingString!.length, greaterThan(0));
        },
      );

      test('Empty string should be distinguishing for initial states', () {
        final acceptsEmpty = _createDFAAcceptingEmpty();
        final rejectsEmpty = _createDFARejectingEmpty();

        final result = LanguageComparator.compareLanguages(
          acceptsEmpty,
          rejectsEmpty,
        );

        expect(result.isSuccess, true);
        expect(result.data!.isEquivalent, false);
        expect(result.data!.distinguishingString, '');
      });

      test('Distinguishing string should be minimal', () {
        final simple1 = _createSimpleDFA1();
        final simple2 = _createSimpleDFA2();

        final result = LanguageComparator.compareLanguages(simple1, simple2);

        expect(result.isSuccess, true);
        expect(result.data!.isEquivalent, false);
        expect(result.data!.distinguishingString, isNotNull);
        // BFS ensures we find shortest path
        expect(result.data!.distinguishingString!.length, lessThanOrEqualTo(3));
      });
    });

    group('Product Automaton Tests', () {
      test('Product automaton should be constructed', () {
        final result = LanguageComparator.compareLanguages(dfa1, dfa2);

        expect(result.isSuccess, true);
        expect(result.data!.productAutomaton, isNotNull);
        expect(result.data!.productAutomaton!.states, isNotEmpty);
        expect(result.data!.productAutomaton!.transitions, isNotEmpty);
        expect(result.data!.productAutomaton!.initialState, isNotNull);
      });

      test('Product automaton should have combined alphabet', () {
        final dfaAB = _createDFAWithAlphabet({'a', 'b'});
        final dfaBC = _createDFAWithAlphabet({'b', 'c'});

        final result = LanguageComparator.compareLanguages(dfaAB, dfaBC);

        expect(result.isSuccess, true);
        expect(result.data!.productAutomaton, isNotNull);
        expect(
          result.data!.productAutomaton!.alphabet,
          containsAll({'a', 'b', 'c'}),
        );
      });

      test('Product automaton accepting states mark differences', () {
        final result = LanguageComparator.compareLanguages(
          dfa1,
          nonEquivalentDFA,
        );

        expect(result.isSuccess, true);
        expect(result.data!.productAutomaton, isNotNull);
        // If non-equivalent, there should be at least one accepting state
        // in the product (marking where languages differ)
        expect(result.data!.productAutomaton!.acceptingStates, isNotEmpty);
      });
    });

    group('Edge Cases Tests', () {
      test('Empty automata should fail validation', () {
        final empty1 = _createEmptyAutomaton();
        final empty2 = _createEmptyAutomaton();

        final result = LanguageComparator.compareLanguages(empty1, empty2);

        expect(result.isSuccess, false);
        expect(result.error, contains('must have at least one state'));
      });

      test('Automata without initial state should fail validation', () {
        final noInitial1 = _createNoInitialStateAutomaton();
        final noInitial2 = _createNoInitialStateAutomaton();

        final result = LanguageComparator.compareLanguages(
          noInitial1,
          noInitial2,
        );

        expect(result.isSuccess, false);
        expect(result.error, contains('must have an initial state'));
      });

      test('Automata with initial state not in states should fail', () {
        final invalidInitial = _createInvalidInitialStateAutomaton();
        final valid = _createDFAEndingInA();

        final result = LanguageComparator.compareLanguages(
          invalidInitial,
          valid,
        );

        expect(result.isSuccess, false);
        expect(result.error, contains('must be in the states set'));
      });

      test('Automata with different alphabets should be handled', () {
        final dfaAB = _createDFAWithAlphabet({'a', 'b'});
        final dfaCD = _createDFAWithAlphabet({'c', 'd'});

        final result = LanguageComparator.compareLanguages(dfaAB, dfaCD);

        // Should succeed - alphabets are combined
        expect(result.isSuccess, true);
        expect(result.data!.productAutomaton, isNotNull);
      });

      test('Automata with epsilon transitions should be handled', () {
        final nfaWithEpsilon = _createNFAWithEpsilon();
        final dfa = _createDFAEndingInA();

        final result = LanguageComparator.compareLanguages(nfaWithEpsilon, dfa);

        // Should succeed - NFA is converted to DFA first
        expect(result.isSuccess, true);
      });

      test('NFA determinization failure should fail comparison', () {
        final invalidNfa = createNFAWithInvalidAcceptingState();
        final dfa = _createDFAEndingInA();

        final result = LanguageComparator.compareLanguages(invalidNfa, dfa);

        expect(result.isFailure, true);
        expect(result.error, contains('Failed to determinize automaton A'));
        expect(
          result.error,
          contains('Accepting state must be in the states set'),
        );
      });

      test('Single state accepting automaton should work', () {
        final single1 = _createSingleStateAccepting();
        final single2 = _createSingleStateAccepting();

        final result = LanguageComparator.compareLanguages(single1, single2);

        expect(result.isSuccess, true);
        expect(result.data!.isEquivalent, true);
      });

      test('Single state rejecting automaton should work', () {
        final single1 = _createSingleStateRejecting();
        final single2 = _createSingleStateRejecting();

        final result = LanguageComparator.compareLanguages(single1, single2);

        expect(result.isSuccess, true);
        expect(result.data!.isEquivalent, true);
      });
    });

    group('Algorithm Steps Tests', () {
      test('Steps should be generated for successful comparison', () {
        final result = LanguageComparator.compareLanguages(dfa1, dfa2);

        expect(result.isSuccess, true);
        expect(result.data!.steps, isNotEmpty);
        expect(result.data!.steps.first['type'], equals('validation'));
        expect(result.data!.steps.last['type'], equals('result'));
      });

      test('Steps should include all major phases', () {
        final result = LanguageComparator.compareLanguages(dfa1, dfa2);

        expect(result.isSuccess, true);

        final stepTypes = result.data!.steps.map((s) => s['type']).toList();

        expect(stepTypes, contains('validation'));
        expect(stepTypes, contains('alphabet_normalization'));
        expect(stepTypes, contains('product_construction_start'));
        expect(stepTypes, contains('bfs_search_start'));
        expect(stepTypes, contains('result'));
      });

      test('Steps should include NFA conversion when needed', () {
        final result = LanguageComparator.compareLanguages(nfa1, dfa1);

        expect(result.isSuccess, true);

        final stepTypes = result.data!.steps.map((s) => s['type']).toList();
        expect(stepTypes, contains('nfa_to_dfa'));
      });

      test('Steps should include DFA completion', () {
        final incomplete = _createIncompleteDFA();
        final complete = _createDFAEndingInA();

        final result = LanguageComparator.compareLanguages(
          incomplete,
          complete,
        );

        expect(result.isSuccess, true);

        final stepTypes = result.data!.steps.map((s) => s['type']).toList();
        expect(stepTypes, contains('dfa_completion'));
      });
    });

    group('Performance Tests', () {
      test('Comparison should complete within reasonable time', () {
        final result = LanguageComparator.compareLanguages(dfa1, dfa2);

        expect(result.isSuccess, true);
        expect(
          result.data!.executionTimeMs,
          lessThan(1000),
          reason: 'Comparison should complete within 1 second',
        );
      });

      test('Large automata should complete within reasonable time', () {
        final large1 = _createLargeDFA(10);
        final large2 = _createLargeDFA(10);

        final result = LanguageComparator.compareLanguages(large1, large2);

        expect(result.isSuccess, true);
        expect(
          result.data!.executionTimeMs,
          lessThan(5000),
          reason: 'Large automata comparison should complete within 5 seconds',
        );
      });
    });

    group('Result Metadata Tests', () {
      test('Result should include timestamp', () {
        final result = LanguageComparator.compareLanguages(dfa1, dfa2);

        expect(result.isSuccess, true);
        expect(result.data!.timestamp, isNotNull);
      });

      test('Result should reference original automata', () {
        final result = LanguageComparator.compareLanguages(dfa1, dfa2);

        expect(result.isSuccess, true);
        expect(result.data!.originalAutomaton.id, equals(dfa1.id));
        expect(result.data!.comparedAutomaton.id, equals(dfa2.id));
      });

      test('Execution time should be non-negative', () {
        final result = LanguageComparator.compareLanguages(dfa1, dfa2);

        expect(result.isSuccess, true);
        expect(result.data!.executionTimeMs, greaterThanOrEqualTo(0));
      });
    });
  });
}
