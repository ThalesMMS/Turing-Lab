import 'dart:math' as math;

import 'package:test/test.dart';
import 'package:vector_math/vector_math_64.dart';

import 'package:turing_lab/core/algorithms/pda_normalizer.dart';
import 'package:turing_lab/core/algorithms/pda_simulator.dart';
import 'package:turing_lab/core/algorithms/pda_to_cfg_converter.dart';
import 'package:turing_lab/core/algorithms/grammar_parser.dart';
import 'package:turing_lab/core/models/pda.dart';
import 'package:turing_lab/core/models/pda_transition.dart';
import 'package:turing_lab/core/models/state.dart';

void main() {
  group('PDANormalizer', () {
    test('normalizes an empty-stack PDA with no accepting states', () {
      final source = _emptyStackAnBnPda();

      final result = PDANormalizer.normalize(
        source,
        sourceMode: PDAAcceptanceMode.emptyStack,
        targetForm: PDANormalForm.finalStateAndSinglePop,
      );

      expect(result.isSuccess, isTrue, reason: result.error);
      final report = result.data!;
      expect(report.sourceMode, PDAAcceptanceMode.emptyStack);
      expect(report.targetMode, PDAAcceptanceMode.finalState);
      expect(report.normalizedPda.acceptingStates, hasLength(1));
      expect(
        report.normalizedPda.pdaTransitions,
        everyElement(
          predicate<PDATransition>(
            (transition) => !transition.isLambdaPop,
            'pops exactly one stack symbol',
          ),
        ),
      );

      _expectSameBoundedLanguage(
        source,
        report.normalizedPda,
        sourceMode: PDAAcceptanceMode.emptyStack,
        targetMode: PDAAcceptanceMode.finalState,
        alphabet: const ['a', 'b'],
        maxLength: 4,
      );
    });

    test('converts final-state acceptance with residual stack to empty stack',
        () {
      final source = _finalStateResidualStackPda();

      final result = PDANormalizer.normalize(
        source,
        sourceMode: PDAAcceptanceMode.finalState,
        targetForm: PDANormalForm.emptyStackAndSinglePop,
      );

      expect(result.isSuccess, isTrue, reason: result.error);
      final report = result.data!;
      expect(report.normalizedPda.acceptingStates, isEmpty);
      _expectSameBoundedLanguage(
        source,
        report.normalizedPda,
        sourceMode: PDAAcceptanceMode.finalState,
        targetMode: PDAAcceptanceMode.emptyStack,
        alphabet: const ['a'],
        maxLength: 4,
      );
    });

    test('preserves combined acceptance as final and empty together', () {
      final source = _bothAcceptancePda();

      for (final targetForm in PDANormalForm.values) {
        final result = PDANormalizer.normalize(
          source,
          sourceMode: PDAAcceptanceMode.both,
          targetForm: targetForm,
        );

        expect(result.isSuccess, isTrue, reason: result.error);
        _expectSameBoundedLanguage(
          source,
          result.data!.normalizedPda,
          sourceMode: PDAAcceptanceMode.both,
          targetMode: targetForm.acceptanceMode,
          alphabet: const ['a'],
          maxLength: 3,
        );
      }
    });

    test('replaces lambda pops for empty and non-empty push words', () {
      final source = _lambdaPopPda();

      final result = PDANormalizer.normalize(
        source,
        sourceMode: PDAAcceptanceMode.finalState,
        targetForm: PDANormalForm.finalStateAndSinglePop,
      );

      expect(result.isSuccess, isTrue, reason: result.error);
      final report = result.data!;
      expect(report.replacedTransitionIds, {'push-a', 'push-empty'});
      expect(
        report.normalizedPda.pdaTransitions.any(
          (transition) => transition.isLambdaPop,
        ),
        isFalse,
      );

      final pushAExpansions = report.addedTransitions.where(
        (transition) =>
            report.provenance[transition.id]?.sourceTransitionId == 'push-a',
      );
      expect(pushAExpansions, isNotEmpty);
      for (final transition in pushAExpansions) {
        expect(transition.pushSymbols.first, 'A');
        expect(transition.pushSymbols.last, transition.popSymbol);
      }

      final emptyPushExpansions = report.addedTransitions.where(
        (transition) =>
            report.provenance[transition.id]?.sourceTransitionId ==
            'push-empty',
      );
      expect(emptyPushExpansions, isNotEmpty);
      for (final transition in emptyPushExpansions) {
        expect(transition.pushSymbols, [transition.popSymbol]);
      }
    });

    test('normalizes persisted epsilon aliases used as lambda pops', () {
      final start = _state('start', initial: true);
      final accept = _state('accept', accepting: true, x: 100);
      final source = _pda(
        id: 'epsilon-alias',
        states: {start, accept},
        transitions: {
          PDATransition(
            id: 'epsilon-pop',
            fromState: start,
            toState: accept,
            label: 'a, epsilon/A',
            inputSymbol: 'a',
            popSymbol: 'epsilon',
            pushSymbol: 'A',
            pushSymbols: const ['A'],
          ),
        },
        initial: start,
        accepting: {accept},
        alphabet: const {'a'},
        stackAlphabet: const {'Z', 'A'},
      );

      final result = PDANormalizer.normalize(
        source,
        sourceMode: PDAAcceptanceMode.finalState,
        targetForm: PDANormalForm.finalStateAndSinglePop,
      );

      expect(result.isSuccess, isTrue, reason: result.error);
      expect(result.data!.replacedTransitionIds, {'epsilon-pop'});
      expect(
        PDAtoCFGConverter.convert(result.data!.normalizedPda).isSuccess,
        isTrue,
      );
    });

    test('returns deterministic collision-safe ids and provenance', () {
      final source = _lambdaPopPda(
        collidingIds: true,
      );

      final first = PDANormalizer.normalize(
        source,
        sourceMode: PDAAcceptanceMode.finalState,
        targetForm: PDANormalForm.finalStateAndSinglePop,
      ).data!;
      final second = PDANormalizer.normalize(
        source,
        sourceMode: PDAAcceptanceMode.finalState,
        targetForm: PDANormalForm.finalStateAndSinglePop,
      ).data!;

      final firstStateIds = first.normalizedPda.states.map((state) => state.id);
      final firstTransitionIds =
          first.normalizedPda.pdaTransitions.map((transition) => transition.id);
      expect(firstStateIds.toSet(), hasLength(firstStateIds.length));
      expect(firstTransitionIds.toSet(), hasLength(firstTransitionIds.length));
      expect(
        firstStateIds.toList()..sort(),
        second.normalizedPda.states.map((state) => state.id).toList()..sort(),
      );
      expect(
        firstTransitionIds.toList()..sort(),
        second.normalizedPda.pdaTransitions
            .map((transition) => transition.id)
            .toList()
          ..sort(),
      );
      expect(first.addedStates, isNotEmpty);
      expect(first.addedStackSymbols, hasLength(1));
      for (final state in first.addedStates) {
        expect(first.provenance[state.id]?.description, isNotEmpty);
      }
      for (final transition in first.addedTransitions) {
        expect(first.provenance[transition.id]?.description, isNotEmpty);
      }
    });

    test('does not mutate the source and reports introduced nondeterminism',
        () {
      final source = _finalStateResidualStackPda();
      final sourceJson = source.toJson();

      final result = PDANormalizer.normalize(
        source,
        sourceMode: PDAAcceptanceMode.finalState,
        targetForm: PDANormalForm.emptyStackAndSinglePop,
      );

      expect(result.isSuccess, isTrue, reason: result.error);
      final report = result.data!;
      expect(source.toJson(), sourceJson);
      expect(report.normalizedPda, isNot(same(source)));
      expect(report.sourceWasDeterministic, isTrue);
      expect(report.normalizedIsDeterministic, isFalse);
      expect(report.introducedNondeterminism, isTrue);
      expect(
        report.warnings,
        contains(contains('state and transition count')),
      );
      expect(
        report.warnings,
        contains(contains('non-deterministic')),
      );
      expect(report.normalizedPda.toJson(), isNot(contains('acceptanceMode')));
    });

    test('produces output accepted by the PDA to CFG converter', () {
      final source = _emptyStackAnBnPda();

      final normalization = PDANormalizer.normalize(
        source,
        sourceMode: PDAAcceptanceMode.emptyStack,
        targetForm: PDANormalForm.finalStateAndSinglePop,
      );

      expect(normalization.isSuccess, isTrue, reason: normalization.error);
      final conversion = PDAtoCFGConverter.convert(
        normalization.data!.normalizedPda,
      );
      expect(conversion.isSuccess, isTrue, reason: conversion.error);

      final accepted = GrammarParser.parse(conversion.data!.grammar, 'aabb');
      final rejected = GrammarParser.parse(conversion.data!.grammar, 'aab');
      expect(accepted.isSuccess, isTrue, reason: accepted.error);
      expect(rejected.isSuccess, isTrue, reason: rejected.error);
      expect(accepted.data!.accepted, isTrue);
      expect(rejected.data!.accepted, isFalse);
    });

    test('rejects final-state source semantics without accepting states', () {
      final source = _emptyStackAnBnPda();

      final result = PDANormalizer.normalize(
        source,
        sourceMode: PDAAcceptanceMode.finalState,
        targetForm: PDANormalForm.emptyStackAndSinglePop,
      );

      expect(result.isFailure, isTrue);
      expect(result.error, contains('accepting state'));
    });
  });
}

PDA _emptyStackAnBnPda() {
  final q = _state('q', initial: true);
  return _pda(
    id: 'empty-anbn',
    states: {q},
    initial: q,
    accepting: const {},
    alphabet: const {'a', 'b'},
    stackAlphabet: const {'Z', 'A'},
    transitions: {
      _transition(
        id: 'push-a',
        from: q,
        to: q,
        input: 'a',
        lambdaPop: true,
        push: const ['A'],
      ),
      _transition(
        id: 'pop-a',
        from: q,
        to: q,
        input: 'b',
        pop: 'A',
      ),
      _transition(
        id: 'pop-bottom',
        from: q,
        to: q,
        lambdaInput: true,
        pop: 'Z',
      ),
    },
  );
}

PDA _finalStateResidualStackPda() {
  final q = _state('q', initial: true, accepting: true);
  return _pda(
    id: 'final-residual',
    states: {q},
    initial: q,
    accepting: {q},
    alphabet: const {'a'},
    stackAlphabet: const {'Z'},
    transitions: {
      _transition(
        id: 'read-a',
        from: q,
        to: q,
        input: 'a',
        lambdaPop: true,
      ),
    },
  );
}

PDA _bothAcceptancePda() {
  final start = _state('start', initial: true);
  final accept = _state('accept', accepting: true, x: 100);
  return _pda(
    id: 'both',
    states: {start, accept},
    initial: start,
    accepting: {accept},
    alphabet: const {'a'},
    stackAlphabet: const {'Z'},
    transitions: {
      _transition(
        id: 'consume-and-empty',
        from: start,
        to: accept,
        input: 'a',
        pop: 'Z',
      ),
    },
  );
}

PDA _lambdaPopPda({bool collidingIds = false}) {
  final start = _state(
    collidingIds ? 'lambda-pop/normalization/state/initial' : 'start',
    initial: true,
  );
  final accept = _state('accept', accepting: true, x: 100);
  return _pda(
    id: 'lambda-pop',
    states: {start, accept},
    initial: start,
    accepting: {accept},
    alphabet: const {'a'},
    stackAlphabet: const {'Z', 'A'},
    transitions: {
      _transition(
        id: collidingIds
            ? 'lambda-pop/normalization/transition/0_initialize'
            : 'push-a',
        from: start,
        to: accept,
        input: 'a',
        lambdaPop: true,
        push: const ['A'],
      ),
      _transition(
        id: 'push-empty',
        from: start,
        to: accept,
        lambdaInput: true,
        lambdaPop: true,
      ),
    },
  );
}

State _state(
  String id, {
  bool initial = false,
  bool accepting = false,
  double x = 0,
}) {
  return State(
    id: id,
    label: id,
    position: Vector2(x, 0),
    isInitial: initial,
    isAccepting: accepting,
  );
}

PDATransition _transition({
  required String id,
  required State from,
  required State to,
  String input = '',
  bool lambdaInput = false,
  String pop = '',
  bool lambdaPop = false,
  List<String> push = const [],
}) {
  final lambdaPush = push.isEmpty;
  return PDATransition(
    id: id,
    fromState: from,
    toState: to,
    label: PDATransition.formatLabel(
      inputSymbol: input,
      popSymbol: pop,
      pushSymbol: push.join(),
      isLambdaInput: lambdaInput,
      isLambdaPop: lambdaPop,
      isLambdaPush: lambdaPush,
    ),
    inputSymbol: input,
    popSymbol: pop,
    pushSymbol: push.join(),
    pushSymbols: push,
    isLambdaInput: lambdaInput,
    isLambdaPop: lambdaPop,
    isLambdaPush: lambdaPush,
  );
}

PDA _pda({
  required String id,
  required Set<State> states,
  required Set<PDATransition> transitions,
  required State initial,
  required Set<State> accepting,
  required Set<String> alphabet,
  required Set<String> stackAlphabet,
}) {
  final instant = DateTime.utc(2026, 1, 1);
  return PDA(
    id: id,
    name: id,
    states: states,
    transitions: transitions,
    alphabet: alphabet,
    initialState: initial,
    acceptingStates: accepting,
    created: instant,
    modified: instant,
    bounds: const math.Rectangle(0, 0, 400, 300),
    stackAlphabet: stackAlphabet,
    initialStackSymbol: 'Z',
  );
}

void _expectSameBoundedLanguage(
  PDA source,
  PDA normalized, {
  required PDAAcceptanceMode sourceMode,
  required PDAAcceptanceMode targetMode,
  required List<String> alphabet,
  required int maxLength,
}) {
  for (final word in _words(alphabet, maxLength)) {
    final sourceResult = PDASimulator.simulateNPDA(
      source,
      word,
      mode: sourceMode,
    );
    final normalizedResult = PDASimulator.simulateNPDA(
      normalized,
      word,
      mode: targetMode,
    );
    expect(sourceResult.isSuccess, isTrue, reason: sourceResult.error);
    expect(normalizedResult.isSuccess, isTrue, reason: normalizedResult.error);
    expect(
      normalizedResult.data!.accepted,
      sourceResult.data!.accepted,
      reason: 'language differs for "$word"',
    );
  }
}

Iterable<String> _words(List<String> alphabet, int maxLength) sync* {
  yield '';
  var frontier = <String>[''];
  for (var length = 1; length <= maxLength; length++) {
    final next = <String>[];
    for (final prefix in frontier) {
      for (final symbol in alphabet) {
        final word = '$prefix$symbol';
        next.add(word);
        yield word;
      }
    }
    frontier = next;
  }
}
