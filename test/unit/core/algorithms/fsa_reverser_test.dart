import 'dart:math' as math;

import 'package:flutter_test/flutter_test.dart';
import 'package:turing_lab/core/algorithms/automaton_simulator.dart';
import 'package:turing_lab/core/algorithms/fsa_reverser.dart';
import 'package:turing_lab/core/algorithms/fsa_reverser_messages.dart';
import 'package:turing_lab/core/algorithms/language_comparator.dart';
import 'package:turing_lab/core/algorithms/regex_to_nfa_converter.dart';
import 'package:turing_lab/core/models/fsa.dart';
import 'package:turing_lab/core/models/fsa_transition.dart';
import 'package:turing_lab/core/models/state.dart';
import 'package:turing_lab/core/messages/structured_message.dart';
import 'package:vector_math/vector_math_64.dart';

void main() {
  group('FSAReverser', () {
    test('reverses an asymmetric language ending in ab', () async {
      final operand = _fromRegex('(a|b)*ab');

      final result = FSAReverser.reverse(operand);

      expect(result.isSuccess, isTrue, reason: result.error);
      final reversed = result.data!.resultNFA;
      await _expectLanguage(
        reversed,
        accepted: {'ba', 'baa', 'bab', 'baab', 'baba'},
        rejected: {'', 'a', 'b', 'ab', 'aba', 'bba'},
      );
      await _expectReversalRelation(operand, reversed, {
        '',
        'a',
        'b',
        'ab',
        'ba',
        'aab',
        'abb',
        'abab',
        'baba',
      });
    });

    test('uses one epsilon entry per former accepting state', () async {
      final operand = _multipleAccepting();

      final result = FSAReverser.reverse(operand);

      expect(result.isSuccess, isTrue, reason: result.error);
      final reversal = result.data!;
      expect(reversal.entryTransitions, hasLength(2));
      expect(
        reversal.entryTransitions
            .map((transition) => transition.toState.id)
            .toSet(),
        {reversal.stateClones['q2']!.id, reversal.stateClones['q3']!.id},
      );
      await _expectLanguage(
        reversal.resultNFA,
        accepted: {'ba', 'c'},
        rejected: {'', 'ab', 'a', 'b', 'ac'},
      );
    });

    test(
      'handles empty, epsilon-only, and universal one-symbol languages',
      () async {
        final empty = FSAReverser.reverse(_emptyLanguage());
        final epsilon = FSAReverser.reverse(_fromRegex('ε'));
        final universal = FSAReverser.reverse(_fromRegex('a*'));

        expect(empty.isSuccess, isTrue, reason: empty.error);
        expect(epsilon.isSuccess, isTrue, reason: epsilon.error);
        expect(universal.isSuccess, isTrue, reason: universal.error);
        expect(empty.data!.entryTransitions, isEmpty);
        await _expectLanguage(
          empty.data!.resultNFA,
          accepted: const {},
          rejected: {'', 'a', 'aa'},
        );
        await _expectLanguage(
          epsilon.data!.resultNFA,
          accepted: {''},
          rejected: {'a', 'aa'},
        );
        await _expectLanguage(
          universal.data!.resultNFA,
          accepted: {'', 'a', 'aa', 'aaa'},
          rejected: {'b', 'ab'},
        );
      },
    );

    test('reverses epsilon transitions with their direction intact', () async {
      final operand = _epsilonAb();

      final result = FSAReverser.reverse(operand);

      expect(result.isSuccess, isTrue, reason: result.error);
      final reversal = result.data!;
      final reversedEpsilon = reversal.reversedTransitions['epsilon']!;
      expect(reversedEpsilon.isEpsilonTransition, isTrue);
      expect(reversedEpsilon.fromState, reversal.stateClones['q1']);
      expect(reversedEpsilon.toState, reversal.stateClones['q0']);
      await _expectLanguage(
        reversal.resultNFA,
        accepted: {'ba'},
        rejected: {'', 'ab', 'a', 'b'},
      );
    });

    test(
      'does not mutate the operand and reports stable construction steps',
      () async {
        final operand = _multipleAccepting();
        final snapshot = operand.toJson();

        final result = FSAReverser.reverse(operand);
        final repeated = FSAReverser.reverse(operand);

        expect(result.isSuccess, isTrue, reason: result.error);
        expect(repeated.isSuccess, isTrue, reason: repeated.error);
        final reversal = result.data!;
        expect(reversal.resultNFA.validate(), isEmpty);
        expect(reversal.steps, hasLength(4));
        expect(reversal.steps[1].title, 'automaton.fsa-reversal.reverse-title');
        expect(
          reversal.steps[2].properties['createdTransitionIds'],
          containsAll(
            reversal.entryTransitions.map((transition) => transition.id),
          ),
        );
        expect(reversal.resultNFA.acceptingStates, {
          reversal.stateClones[operand.initialState!.id],
        });
        expect(
          reversal.newInitialState.position.x,
          lessThan(
            reversal.stateClones.values
                .map((state) => state.position.x)
                .reduce(math.min),
          ),
        );
        expect(
          repeated.data!.resultNFA.states.map((state) => state.id).toSet(),
          reversal.resultNFA.states.map((state) => state.id).toSet(),
        );
        expect(
          repeated.data!.resultNFA.fsaTransitions
              .map((transition) => transition.id)
              .toSet(),
          reversal.resultNFA.fsaTransitions
              .map((transition) => transition.id)
              .toSet(),
        );
        expect(repeated.data!.resultNFA.id, reversal.resultNFA.id);
        expect(operand.toJson(), snapshot);
      },
    );

    test('exposes stable diagnostics and structured construction steps', () {
      final empty = FSA(
        id: 'empty-invalid',
        name: 'Empty invalid',
        states: const {},
        transitions: const {},
        alphabet: const {},
        initialState: null,
        acceptingStates: const {},
        created: DateTime.utc(2026),
        modified: DateTime.utc(2026),
        bounds: const math.Rectangle(0, 0, 800, 600),
      );
      final failure = FSAReverser.reverse(empty);

      expect(failure.error, 'automaton.fsa-reversal.empty-operand');
      expect(failure.structuredError?.stableCode, failure.error);

      final invalidTransition = FsaReversalMessages.invalidTransition('t0');
      expect(
        invalidTransition.stableCode,
        'automaton.fsa-reversal.invalid-transition',
      );
      expect(
        invalidTransition.arguments['transition']?.kind,
        StructuredMessageArgumentKind.identifier,
      );
      expect(invalidTransition.arguments['transition']?.value, 't0');

      final success = FSAReverser.reverse(_multipleAccepting());
      expect(success.isSuccess, isTrue, reason: success.error);
      final reversal = success.data!;
      final step = reversal.steps.first;
      expect(step.title, 'automaton.fsa-reversal.clone-title');
      expect(
        StructuredMessage.fromJson(
          Map<String, Object?>.from(
            step.properties[FsaReversalMessages
                    .FSA_REVERSAL_TITLE_MESSAGE_PROPERTY]
                as Map,
          ),
        ).stableCode,
        step.title,
      );
      expect(
        StructuredMessage.fromJson(
          Map<String, Object?>.from(
            step.properties[FsaReversalMessages
                    .FSA_REVERSAL_EXPLANATION_MESSAGE_PROPERTY]
                as Map,
          ),
        ).stableCode,
        step.explanation,
      );
      expect(
        reversal.steps[2].explanation,
        'automaton.fsa-reversal.entry-explanation',
      );

      final noAccepting = FSAReverser.reverse(_emptyLanguage());
      expect(noAccepting.isSuccess, isTrue, reason: noAccepting.error);
      expect(
        noAccepting.data!.steps[2].explanation,
        'automaton.fsa-reversal.entry-empty-explanation',
      );
    });

    test('double reversal is language-equivalent to the operand', () {
      final operand = _fromRegex('(a|b)*ab');
      final once = FSAReverser.reverse(operand);

      expect(once.isSuccess, isTrue, reason: once.error);
      final twice = FSAReverser.reverse(once.data!.resultNFA);
      expect(twice.isSuccess, isTrue, reason: twice.error);

      final comparison = LanguageComparator.compareLanguages(
        operand,
        twice.data!.resultNFA,
      );
      expect(comparison.isSuccess, isTrue, reason: comparison.error);
      expect(comparison.data!.isEquivalent, isTrue);
      expect(comparison.data!.distinguishingString, isNull);
    });
  });
}

FSA _fromRegex(String regex) {
  final result = RegexToNFAConverter.convert(regex);
  expect(result.isSuccess, isTrue, reason: result.error);
  return result.data!;
}

Future<void> _expectReversalRelation(
  FSA operand,
  FSA reversed,
  Set<String> words,
) async {
  for (final word in words) {
    final originalResult = await AutomatonSimulator.simulateNFA(operand, word);
    final reversedWord = String.fromCharCodes(word.runes.toList().reversed);
    final reversedResult = await AutomatonSimulator.simulateNFA(
      reversed,
      reversedWord,
    );
    expect(originalResult.isSuccess, isTrue, reason: originalResult.error);
    expect(reversedResult.isSuccess, isTrue, reason: reversedResult.error);
    expect(
      reversedResult.data!.accepted,
      originalResult.data!.accepted,
      reason: 'Expected reverse("$word") = "$reversedWord" to match',
    );
  }
}

Future<void> _expectLanguage(
  FSA automaton, {
  required Set<String> accepted,
  required Set<String> rejected,
}) async {
  expect(automaton.validate(), isEmpty);
  for (final input in accepted) {
    final result = await AutomatonSimulator.simulateNFA(automaton, input);
    expect(result.isSuccess, isTrue, reason: result.error);
    expect(result.data!.accepted, isTrue, reason: 'Expected "$input"');
  }
  for (final input in rejected) {
    final result = await AutomatonSimulator.simulateNFA(automaton, input);
    expect(result.isSuccess, isTrue, reason: result.error);
    expect(result.data!.accepted, isFalse, reason: 'Rejected "$input"');
  }
}

FSA _emptyLanguage() {
  final initial = State(
    id: 'q0',
    label: 'q0',
    position: Vector2(40, 100),
    isInitial: true,
  );
  return _automaton(
    id: 'empty',
    states: {initial},
    transitions: const {},
    alphabet: const {},
    initialState: initial,
    acceptingStates: const {},
  );
}

FSA _multipleAccepting() {
  final q0 = State(
    id: 'q0',
    label: 'q0',
    position: Vector2(40, 100),
    isInitial: true,
  );
  final q1 = State(id: 'q1', label: 'q1', position: Vector2(140, 60));
  final q2 = State(
    id: 'q2',
    label: 'q2',
    position: Vector2(260, 60),
    isAccepting: true,
  );
  final q3 = State(
    id: 'q3',
    label: 'q3',
    position: Vector2(260, 140),
    isAccepting: true,
  );
  return _automaton(
    id: 'multiple-accepting',
    states: {q0, q1, q2, q3},
    transitions: {
      FSATransition.deterministic(
        id: 'a',
        fromState: q0,
        toState: q1,
        symbol: 'a',
      ),
      FSATransition.deterministic(
        id: 'b',
        fromState: q1,
        toState: q2,
        symbol: 'b',
      ),
      FSATransition.deterministic(
        id: 'c',
        fromState: q0,
        toState: q3,
        symbol: 'c',
      ),
    },
    alphabet: {'a', 'b', 'c'},
    initialState: q0,
    acceptingStates: {q2, q3},
  );
}

FSA _epsilonAb() {
  final q0 = State(
    id: 'q0',
    label: 'q0',
    position: Vector2(40, 100),
    isInitial: true,
  );
  final q1 = State(id: 'q1', label: 'q1', position: Vector2(140, 100));
  final q2 = State(id: 'q2', label: 'q2', position: Vector2(240, 100));
  final q3 = State(
    id: 'q3',
    label: 'q3',
    position: Vector2(340, 100),
    isAccepting: true,
  );
  return _automaton(
    id: 'epsilon-ab',
    states: {q0, q1, q2, q3},
    transitions: {
      FSATransition.epsilon(id: 'epsilon', fromState: q0, toState: q1),
      FSATransition.deterministic(
        id: 'a',
        fromState: q1,
        toState: q2,
        symbol: 'a',
      ),
      FSATransition.deterministic(
        id: 'b',
        fromState: q2,
        toState: q3,
        symbol: 'b',
      ),
    },
    alphabet: {'ε', 'a', 'b'},
    initialState: q0,
    acceptingStates: {q3},
  );
}

FSA _automaton({
  required String id,
  required Set<State> states,
  required Set<FSATransition> transitions,
  required Set<String> alphabet,
  required State initialState,
  required Set<State> acceptingStates,
}) {
  final timestamp = DateTime.utc(2026);
  return FSA(
    id: id,
    name: id,
    states: states,
    transitions: transitions,
    alphabet: alphabet,
    initialState: initialState,
    acceptingStates: acceptingStates,
    created: timestamp,
    modified: timestamp,
    bounds: const math.Rectangle(0, 0, 800, 600),
  );
}
