import 'dart:math' as math;

import 'package:flutter_test/flutter_test.dart';
import 'package:turing_lab/core/algorithms/automaton_simulator.dart';
import 'package:turing_lab/core/algorithms/fsa_concatenator.dart';
import 'package:turing_lab/core/algorithms/fsa_concatenation_messages.dart';
import 'package:turing_lab/core/algorithms/regex_to_nfa_converter.dart';
import 'package:turing_lab/core/models/fsa.dart';
import 'package:turing_lab/core/models/fsa_transition.dart';
import 'package:turing_lab/core/models/state.dart';
import 'package:turing_lab/core/messages/structured_message.dart';
import 'package:vector_math/vector_math_64.dart';

void main() {
  group('FSAConcatenator', () {
    test('concatenates the singleton languages a and b', () async {
      final left = _literal('a', id: 'left');
      final right = _literal('b', id: 'right');

      final result = FSAConcatenator.concatenate(left, right);

      expect(result.isSuccess, isTrue, reason: result.error);
      final concatenation = result.data!;
      expect(concatenation.resultNFA.alphabet, {'a', 'b'});
      expect(concatenation.resultNFA.validate(), isEmpty);
      expect(concatenation.epsilonBridges, hasLength(1));
      await _expectLanguage(
        concatenation.resultNFA,
        accepted: {'ab'},
        rejected: {'', 'a', 'b', 'aa', 'abb'},
      );
    });

    test('supports epsilon as the identity on either side', () async {
      final language = _literal('a', id: 'language');

      final epsilonThenLanguage = FSAConcatenator.concatenate(
        _epsilon(id: 'epsilon-left'),
        language,
      );
      final languageThenEpsilon = FSAConcatenator.concatenate(
        language,
        _epsilon(id: 'epsilon-right'),
      );

      expect(epsilonThenLanguage.isSuccess, isTrue);
      expect(languageThenEpsilon.isSuccess, isTrue);
      for (final result in [epsilonThenLanguage, languageThenEpsilon]) {
        await _expectLanguage(
          result.data!.resultNFA,
          accepted: {'a'},
          rejected: {'', 'aa', 'b'},
        );
      }
    });

    test('empty language on either side produces the empty language', () async {
      final language = _literal('a', id: 'language');
      final emptyThenLanguage = FSAConcatenator.concatenate(
        _emptyLanguage(id: 'empty-left'),
        language,
      );
      final languageThenEmpty = FSAConcatenator.concatenate(
        language,
        _emptyLanguage(id: 'empty-right'),
      );

      expect(emptyThenLanguage.isSuccess, isTrue);
      expect(emptyThenLanguage.data!.epsilonBridges, isEmpty);
      expect(languageThenEmpty.isSuccess, isTrue);
      for (final result in [emptyThenLanguage, languageThenEmpty]) {
        await _expectLanguage(
          result.data!.resultNFA,
          accepted: const {},
          rejected: {'', 'a', 'aa'},
        );
      }
    });

    test('clones colliding IDs and reports every bridge', () async {
      final left = _multipleAccepting();
      final right = _literal('c', id: 'right', reuseGenericIds: true);
      final leftSnapshot = left.toJson();
      final rightSnapshot = right.toJson();

      final result = FSAConcatenator.concatenate(left, right);
      final repeated = FSAConcatenator.concatenate(left, right);

      expect(result.isSuccess, isTrue, reason: result.error);
      expect(repeated.isSuccess, isTrue, reason: repeated.error);
      final report = result.data!;
      final stateIds = report.resultNFA.states
          .map((state) => state.id)
          .toList();
      final transitionIds = report.resultNFA.fsaTransitions
          .map((transition) => transition.id)
          .toList();
      expect(stateIds.toSet(), hasLength(stateIds.length));
      expect(transitionIds.toSet(), hasLength(transitionIds.length));
      expect(
        repeated.data!.resultNFA.states.map((state) => state.id).toSet(),
        stateIds.toSet(),
      );
      expect(
        repeated.data!.resultNFA.fsaTransitions
            .map((transition) => transition.id)
            .toSet(),
        transitionIds.toSet(),
      );
      expect(repeated.data!.resultNFA.id, report.resultNFA.id);
      expect(report.epsilonBridges, hasLength(2));
      expect(report.stateClones, hasLength(5));
      expect(report.steps, hasLength(3));
      expect(
        report
            .clonesFor(FSAConcatenationOperand.left)
            .every((clone) => !clone.clonedState.isAccepting),
        isTrue,
      );
      expect(
        report.steps.last.properties['createdTransitionIds'],
        containsAll(report.epsilonBridges.map((bridge) => bridge.id)),
      );
      expect(
        report
            .clonesFor(FSAConcatenationOperand.right)
            .every(
              (clone) =>
                  clone.clonedState.position.x >
                  left.states.map((state) => state.position.x).reduce(math.max),
            ),
        isTrue,
      );
      expect(left.toJson(), leftSnapshot);
      expect(right.toJson(), rightSnapshot);
      await _expectLanguage(
        report.resultNFA,
        accepted: {'ac', 'bc'},
        rejected: {'', 'a', 'b', 'c', 'abc'},
      );
    });

    test('exposes stable diagnostics and structured construction steps', () {
      final emptyLeft = FSA.empty(id: 'empty-left', name: 'Empty left');
      final failure = FSAConcatenator.concatenate(
        emptyLeft,
        _literal('b', id: 'right'),
      );

      expect(failure.error, 'automaton.fsa-concatenation.empty-operand');
      expect(
        failure.structuredError,
        FsaConcatenationMessages.emptyOperand('left'),
      );
      expect(failure.structuredError?.arguments['operand']?.value, 'left');

      final success = FSAConcatenator.concatenate(
        _literal('a', id: 'left'),
        _literal('b', id: 'right'),
      );
      expect(success.isSuccess, isTrue, reason: success.error);
      final report = success.data!;
      final cloneStep = report.steps.first;
      expect(cloneStep.title, 'automaton.fsa-concatenation.clone-title');
      expect(
        StructuredMessage.fromJson(
          Map<String, Object?>.from(
            cloneStep.properties[fsaConcatenationTitleMessageProperty] as Map,
          ),
        ),
        FsaConcatenationMessages.cloneTitle('left'),
      );
      expect(
        StructuredMessage.fromJson(
          Map<String, Object?>.from(
            cloneStep.properties[fsaConcatenationExplanationMessageProperty]
                as Map,
          ),
        ).stableCode,
        cloneStep.explanation,
      );
      expect(
        report.steps[2].title,
        'automaton.fsa-concatenation.connect-title',
      );
      expect(
        report.steps[2].explanation,
        'automaton.fsa-concatenation.connect-explanation',
      );

      final emptyLanguageResult = FSAConcatenator.concatenate(
        _emptyLanguage(id: 'empty-language'),
        _literal('b', id: 'right'),
      );
      expect(emptyLanguageResult.isSuccess, isTrue);
      expect(
        emptyLanguageResult.data!.steps[2].explanation,
        'automaton.fsa-concatenation.connect-empty-explanation',
      );
    });

    test(
      'preserves existing epsilon paths and removes epsilon from alphabet',
      () async {
        final result = FSAConcatenator.concatenate(
          _epsilonThenLiteralA(),
          _literal('b', id: 'right'),
        );

        expect(result.isSuccess, isTrue, reason: result.error);
        expect(result.data!.resultNFA.alphabet, {'a', 'b'});
        expect(result.data!.resultNFA.epsilonTransitions, hasLength(2));
        await _expectLanguage(
          result.data!.resultNFA,
          accepted: {'ab'},
          rejected: {'', 'a', 'b'},
        );
      },
    );

    test(
      'matches regex concatenation for representative bounded inputs',
      () async {
        final direct = FSAConcatenator.concatenate(
          _literal('a', id: 'left'),
          _literal('b', id: 'right'),
        );
        final regex = RegexToNFAConverter.convert('ab');

        expect(direct.isSuccess, isTrue);
        expect(regex.isSuccess, isTrue);
        for (final input in ['', 'a', 'b', 'ab', 'aa', 'bb', 'aba']) {
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

FSA _literal(
  String symbol, {
  required String id,
  bool reuseGenericIds = false,
}) {
  final start = State(
    id: reuseGenericIds ? 'q0' : '${id}_q0',
    label: 'q0',
    position: Vector2(40, 100),
    isInitial: true,
  );
  final accept = State(
    id: reuseGenericIds ? 'q1' : '${id}_q1',
    label: 'q1',
    position: Vector2(180, 100),
    isAccepting: true,
  );
  return _automaton(
    id: id,
    states: {start, accept},
    transitions: {
      FSATransition.deterministic(
        id: reuseGenericIds ? 't0' : '${id}_t0',
        fromState: start,
        toState: accept,
        symbol: symbol,
      ),
    },
    alphabet: {symbol},
    initialState: start,
    acceptingStates: {accept},
  );
}

FSA _epsilon({required String id}) {
  final state = State(
    id: '${id}_q0',
    label: 'q0',
    position: Vector2(40, 100),
    isInitial: true,
    isAccepting: true,
  );
  return _automaton(
    id: id,
    states: {state},
    transitions: const {},
    alphabet: const {},
    initialState: state,
    acceptingStates: {state},
  );
}

FSA _emptyLanguage({required String id}) {
  final state = State(
    id: '${id}_q0',
    label: 'q0',
    position: Vector2(40, 100),
    isInitial: true,
  );
  return _automaton(
    id: id,
    states: {state},
    transitions: const {},
    alphabet: const {},
    initialState: state,
    acceptingStates: const {},
  );
}

FSA _multipleAccepting() {
  final start = State(
    id: 'q0',
    label: 'q0',
    position: Vector2(40, 100),
    isInitial: true,
  );
  final acceptA = State(
    id: 'q1',
    label: 'q1',
    position: Vector2(180, 60),
    isAccepting: true,
  );
  final acceptB = State(
    id: 'q2',
    label: 'q2',
    position: Vector2(180, 140),
    isAccepting: true,
  );
  return _automaton(
    id: 'left',
    states: {start, acceptA, acceptB},
    transitions: {
      FSATransition.deterministic(
        id: 't0',
        fromState: start,
        toState: acceptA,
        symbol: 'a',
      ),
      FSATransition.deterministic(
        id: 't1',
        fromState: start,
        toState: acceptB,
        symbol: 'b',
      ),
    },
    alphabet: {'a', 'b'},
    initialState: start,
    acceptingStates: {acceptA, acceptB},
  );
}

FSA _epsilonThenLiteralA() {
  final start = State(
    id: 'q0',
    label: 'q0',
    position: Vector2(40, 100),
    isInitial: true,
  );
  final middle = State(id: 'q1', label: 'q1', position: Vector2(140, 100));
  final accept = State(
    id: 'q2',
    label: 'q2',
    position: Vector2(240, 100),
    isAccepting: true,
  );
  return _automaton(
    id: 'epsilon-path',
    states: {start, middle, accept},
    transitions: {
      FSATransition.epsilon(id: 'epsilon', fromState: start, toState: middle),
      FSATransition.deterministic(
        id: 'a',
        fromState: middle,
        toState: accept,
        symbol: 'a',
      ),
    },
    alphabet: {'ε', 'a'},
    initialState: start,
    acceptingStates: {accept},
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
