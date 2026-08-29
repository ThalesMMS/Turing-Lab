import 'dart:math' as math;

import 'package:flutter_test/flutter_test.dart';
import 'package:turing_lab/core/algorithms/automaton_simulator.dart';
import 'package:turing_lab/core/algorithms/fsa_kleene_star.dart';
import 'package:turing_lab/core/algorithms/regex_to_nfa_converter.dart';
import 'package:turing_lab/core/models/fsa.dart';
import 'package:turing_lab/core/models/fsa_transition.dart';
import 'package:turing_lab/core/models/state.dart';
import 'package:turing_lab/core/messages/structured_message.dart';
import 'package:turing_lab/core/algorithms/fsa_kleene_star_messages.dart';
import 'package:vector_math/vector_math_64.dart';

void main() {
  group('FSAKleeneStar', () {
    test(
      'star of the singleton language a accepts exactly a* in bounds',
      () async {
        final operand = _fromRegex('a');

        final result = FSAKleeneStar.apply(operand);

        expect(result.isSuccess, isTrue, reason: result.error);
        final star = result.data!;
        expect(star.resultNFA.initialState!.isAccepting, isTrue);
        expect(star.entryTransition.isEpsilonTransition, isTrue);
        await _expectLanguage(
          star.resultNFA,
          accepted: {'', 'a', 'aa', 'aaa'},
          rejected: {'b', 'ab', 'ba'},
        );
      },
    );

    test('star of the singleton language ab repeats complete words', () async {
      final result = FSAKleeneStar.apply(_fromRegex('ab'));

      expect(result.isSuccess, isTrue, reason: result.error);
      await _expectLanguage(
        result.data!.resultNFA,
        accepted: {'', 'ab', 'abab', 'ababab'},
        rejected: {'a', 'b', 'aba', 'abb', 'aabb'},
      );
    });

    test('empty-language and epsilon-only stars accept only epsilon', () async {
      final emptyStar = FSAKleeneStar.apply(_emptyLanguage());
      final epsilonStar = FSAKleeneStar.apply(_fromRegex('ε'));

      expect(emptyStar.isSuccess, isTrue, reason: emptyStar.error);
      expect(epsilonStar.isSuccess, isTrue, reason: epsilonStar.error);
      expect(emptyStar.data!.repeatTransitions, isEmpty);
      expect(emptyStar.data!.exitTransitions, isEmpty);
      for (final result in [emptyStar, epsilonStar]) {
        await _expectLanguage(
          result.data!.resultNFA,
          accepted: {''},
          rejected: {'a', 'aa', 'b'},
        );
      }
    });

    test(
      'operand that accepts epsilon still repeats its non-empty words',
      () async {
        final result = FSAKleeneStar.apply(_fromRegex('a?'));

        expect(result.isSuccess, isTrue, reason: result.error);
        await _expectLanguage(
          result.data!.resultNFA,
          accepted: {'', 'a', 'aa', 'aaa'},
          rejected: {'b', 'ab'},
        );
      },
    );

    test(
      'supports existing epsilon transitions and multiple final states',
      () async {
        final operand = _epsilonToMultipleAccepting();

        final result = FSAKleeneStar.apply(operand);

        expect(result.isSuccess, isTrue, reason: result.error);
        expect(result.data!.repeatTransitions, hasLength(2));
        expect(result.data!.exitTransitions, hasLength(2));
        await _expectLanguage(
          result.data!.resultNFA,
          accepted: {'', 'a', 'b', 'ab', 'ba', 'abba'},
          rejected: {'c', 'ac', 'abc'},
        );
      },
    );

    test(
      'does not mutate the operand and reports stable construction steps',
      () async {
        final operand = _epsilonToMultipleAccepting();
        final snapshot = operand.toJson();

        final result = FSAKleeneStar.apply(operand);
        final repeated = FSAKleeneStar.apply(operand);

        expect(result.isSuccess, isTrue, reason: result.error);
        expect(repeated.isSuccess, isTrue, reason: repeated.error);
        final star = result.data!;
        final stateIds = star.resultNFA.states.map((state) => state.id).toSet();
        final transitionIds = star.resultNFA.fsaTransitions
            .map((transition) => transition.id)
            .toSet();
        expect(stateIds, hasLength(star.resultNFA.states.length));
        expect(transitionIds, hasLength(star.resultNFA.transitions.length));
        expect(
          repeated.data!.resultNFA.states.map((state) => state.id).toSet(),
          stateIds,
        );
        expect(
          repeated.data!.resultNFA.fsaTransitions
              .map((transition) => transition.id)
              .toSet(),
          transitionIds,
        );
        expect(repeated.data!.resultNFA.id, star.resultNFA.id);
        expect(star.steps, hasLength(4));
        expect(star.steps[1].properties['createdTransitionIds'], [
          star.entryTransition.id,
        ]);
        expect(
          star.steps[2].properties['createdTransitionIds'],
          containsAll(
            star.repeatTransitions.map((transition) => transition.id),
          ),
        );
        expect(
          star.steps[3].properties['createdTransitionIds'],
          containsAll(star.exitTransitions.map((transition) => transition.id)),
        );
        expect(
          star.stateClones.values.every(
            (state) => !state.isInitial && !state.isAccepting,
          ),
          isTrue,
        );
        expect(
          star.newInitialState.position.x,
          lessThan(
            star.stateClones.values
                .map((state) => state.position.x)
                .reduce(math.min),
          ),
        );
        expect(
          star.newAcceptingState.position.x,
          greaterThan(
            star.stateClones.values
                .map((state) => state.position.x)
                .reduce(math.max),
          ),
        );
        expect(operand.toJson(), snapshot);
      },
    );

    test('uses disjoint ID namespaces for distinct operands', () {
      final aStar = FSAKleeneStar.apply(_fromRegex('a'));
      final bStar = FSAKleeneStar.apply(_fromRegex('b'));

      expect(aStar.isSuccess, isTrue, reason: aStar.error);
      expect(bStar.isSuccess, isTrue, reason: bStar.error);
      final aStateIds = aStar.data!.resultNFA.states
          .map((state) => state.id)
          .toSet();
      final bStateIds = bStar.data!.resultNFA.states
          .map((state) => state.id)
          .toSet();
      final aTransitionIds = aStar.data!.resultNFA.fsaTransitions
          .map((transition) => transition.id)
          .toSet();
      final bTransitionIds = bStar.data!.resultNFA.fsaTransitions
          .map((transition) => transition.id)
          .toSet();

      expect(aStateIds.intersection(bStateIds), isEmpty);
      expect(aTransitionIds.intersection(bTransitionIds), isEmpty);
    });

    test('exposes stable diagnostics and localized step contracts', () {
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
      final failure = FSAKleeneStar.apply(empty);

      expect(failure.error, 'automaton.fsa-kleene-star.empty-operand');
      expect(failure.structuredError?.stableCode, failure.error);

      final success = FSAKleeneStar.apply(_fromRegex('a'));
      expect(success.isSuccess, isTrue, reason: success.error);
      final step = success.data!.steps.first;
      expect(step.title, 'automaton.fsa-kleene-star.clone-title');
      expect(
        StructuredMessage.fromJson(
          Map<String, Object?>.from(
            step.properties[FsaKleeneStarMessages
                    .FSA_KLEENE_STAR_TITLE_MESSAGE_PROPERTY]
                as Map,
          ),
        ).stableCode,
        step.title,
      );
    });

    test(
      'matches regex star construction for representative bounded inputs',
      () async {
        final direct = FSAKleeneStar.apply(_fromRegex('ab'));
        final regex = RegexToNFAConverter.convert('(ab)*');

        expect(direct.isSuccess, isTrue, reason: direct.error);
        expect(regex.isSuccess, isTrue, reason: regex.error);
        for (final input in ['', 'a', 'b', 'ab', 'abab', 'aba', 'abb']) {
          final directSimulation = await AutomatonSimulator.simulateNFA(
            direct.data!.resultNFA,
            input,
          );
          final regexSimulation = await AutomatonSimulator.simulateNFA(
            regex.data!,
            input,
          );
          expect(directSimulation.isSuccess, isTrue);
          expect(regexSimulation.isSuccess, isTrue);
          expect(
            directSimulation.data!.accepted,
            regexSimulation.data!.accepted,
            reason: 'Different result for "$input"',
          );
        }
      },
    );
  });
}

FSA _fromRegex(String regex) {
  final result = RegexToNFAConverter.convert(regex);
  expect(result.isSuccess, isTrue, reason: result.error);
  return result.data!;
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

FSA _epsilonToMultipleAccepting() {
  final initial = State(
    id: 'q0',
    label: 'q0',
    position: Vector2(40, 100),
    isInitial: true,
  );
  final branch = State(id: 'q1', label: 'q1', position: Vector2(140, 100));
  final acceptA = State(
    id: 'q2',
    label: 'q2',
    position: Vector2(260, 60),
    isAccepting: true,
  );
  final acceptB = State(
    id: 'q3',
    label: 'q3',
    position: Vector2(260, 140),
    isAccepting: true,
  );
  return _automaton(
    id: 'epsilon-multiple',
    states: {initial, branch, acceptA, acceptB},
    transitions: {
      FSATransition.epsilon(id: 'epsilon', fromState: initial, toState: branch),
      FSATransition.deterministic(
        id: 'a',
        fromState: branch,
        toState: acceptA,
        symbol: 'a',
      ),
      FSATransition.deterministic(
        id: 'b',
        fromState: branch,
        toState: acceptB,
        symbol: 'b',
      ),
    },
    alphabet: {'ε', 'a', 'b'},
    initialState: initial,
    acceptingStates: {acceptA, acceptB},
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
