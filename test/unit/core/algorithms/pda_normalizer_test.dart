import 'dart:math' as math;

import 'package:test/test.dart';
import 'package:vector_math/vector_math_64.dart';

import 'package:turing_lab/core/algorithms/pda_normalizer.dart';
import 'package:turing_lab/core/algorithms/pda_normalization_messages.dart';
import 'package:turing_lab/core/algorithms/pda_simulator.dart';
import 'package:turing_lab/core/algorithms/pda_to_cfg_converter.dart';
import 'package:turing_lab/core/algorithms/grammar_parser.dart';
import 'package:turing_lab/core/models/pda.dart';
import 'package:turing_lab/core/models/pda_transition.dart';
import 'package:turing_lab/core/models/state.dart';
import 'package:turing_lab/core/models/transition.dart';
import 'package:turing_lab/core/models/fsa_transition.dart';
import 'package:turing_lab/core/messages/structured_message.dart';

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

    test(
      'converts final-state acceptance with residual stack to empty stack',
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
      },
    );

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
      final source = _lambdaPopPda(collidingIds: true);

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
      final firstTransitionIds = first.normalizedPda.pdaTransitions.map(
        (transition) => transition.id,
      );
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

    test(
      'does not mutate the source and reports introduced nondeterminism',
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
        expect(report.warnings, contains('pda.normalization.growth-warning'));
        expect(
          report.warnings,
          contains('pda.normalization.introduced-nondeterminism'),
        );
        expect(report.structuredWarnings, [
          PdaNormalizationMessages.growthWarning(
            addedStates: report.addedStates.length,
            addedTransitions: report.addedTransitions.length,
          ),
          PdaNormalizationMessages.introducedNondeterminismWarning(),
        ]);
        expect(
          report.normalizedPda.acceptanceMode,
          PDAAcceptanceMode.emptyStack,
        );
        expect(
          report.normalizedPda.toJson()['acceptanceMode'],
          PDAAcceptanceMode.emptyStack.name,
        );
      },
    );

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
      expect(result.error, 'pda.normalization.missing-accepting-state');
      expect(
        result.structuredError,
        PdaNormalizationMessages.missingAcceptingState(),
      );
    });

    test('exposes structured validation diagnostics', () {
      final validState = _state('q', initial: true);
      final acceptingState = _state('accept', accepting: true, x: 100);
      final outsideState = _state('outside', x: 100);

      final cases =
          <({PDA pda, PDAAcceptanceMode mode, StructuredMessage message})>[
            (
              pda: PDA.empty(id: 'empty', name: 'Empty'),
              mode: PDAAcceptanceMode.emptyStack,
              message: PdaNormalizationMessages.emptyPda(),
            ),
            (
              pda: _rawPda(
                id: 'missing-initial',
                states: {validState},
                accepting: {validState},
                initial: null,
              ),
              mode: PDAAcceptanceMode.finalState,
              message: PdaNormalizationMessages.missingInitialState(),
            ),
            (
              pda: _rawPda(
                id: 'outside-initial',
                states: {validState},
                accepting: {validState},
                initial: outsideState,
              ),
              mode: PDAAcceptanceMode.finalState,
              message: PdaNormalizationMessages.initialStateOutsideSet(),
            ),
            (
              pda: _rawPda(
                id: 'invalid-initial-stack',
                states: {validState},
                accepting: {validState},
                initial: validState,
                initialStackSymbol: 'X',
              ),
              mode: PDAAcceptanceMode.finalState,
              message: PdaNormalizationMessages.invalidInitialStackSymbol('X'),
            ),
            (
              pda: _rawPda(
                id: 'missing-accepting',
                states: {validState},
                accepting: const {},
                initial: validState,
              ),
              mode: PDAAcceptanceMode.finalState,
              message: PdaNormalizationMessages.missingAcceptingState(),
            ),
            (
              pda: _rawPda(
                id: 'outside-accepting',
                states: {validState},
                accepting: {outsideState},
                initial: validState,
              ),
              mode: PDAAcceptanceMode.finalState,
              message: PdaNormalizationMessages.acceptingStateOutsideSet(),
            ),
            (
              pda: _rawPda(
                id: 'non-pda-transition',
                states: {validState, acceptingState},
                accepting: {acceptingState},
                initial: validState,
                transitions: {
                  FSATransition.deterministic(
                    id: 'fsa-transition',
                    fromState: validState,
                    toState: acceptingState,
                    symbol: 'a',
                  ),
                },
              ),
              mode: PDAAcceptanceMode.finalState,
              message: PdaNormalizationMessages.nonPdaTransition(),
            ),
            (
              pda: _rawPda(
                id: 'outside-endpoint',
                states: {validState, acceptingState},
                accepting: {acceptingState},
                initial: validState,
                transitions: {
                  _transition(
                    id: 'outside-endpoint-transition',
                    from: validState,
                    to: outsideState,
                    pop: 'Z',
                  ),
                },
              ),
              mode: PDAAcceptanceMode.finalState,
              message: PdaNormalizationMessages.transitionEndpointOutsideSet(
                'outside-endpoint-transition',
              ),
            ),
            (
              pda: _rawPda(
                id: 'outside-pop',
                states: {validState, acceptingState},
                accepting: {acceptingState},
                initial: validState,
                transitions: {
                  _transition(
                    id: 'outside-pop-transition',
                    from: validState,
                    to: acceptingState,
                    pop: 'X',
                  ),
                },
              ),
              mode: PDAAcceptanceMode.finalState,
              message:
                  PdaNormalizationMessages.transitionPopSymbolOutsideAlphabet(
                    'outside-pop-transition',
                    'X',
                  ),
            ),
            (
              pda: _rawPda(
                id: 'outside-push',
                states: {validState, acceptingState},
                accepting: {acceptingState},
                initial: validState,
                transitions: {
                  _transition(
                    id: 'outside-push-transition',
                    from: validState,
                    to: acceptingState,
                    pop: 'Z',
                    push: const ['X'],
                  ),
                },
              ),
              mode: PDAAcceptanceMode.finalState,
              message:
                  PdaNormalizationMessages.transitionPushSymbolOutsideAlphabet(
                    'outside-push-transition',
                    'X',
                  ),
            ),
          ];

      for (final testCase in cases) {
        final result = PDANormalizer.normalize(
          testCase.pda,
          sourceMode: testCase.mode,
          targetForm: PDANormalForm.finalStateAndSinglePop,
        );
        expect(result.isFailure, isTrue, reason: result.error);
        expect(result.error, testCase.message.stableCode);
        expect(result.structuredError, testCase.message);
      }
    });

    test('exposes structured warning and provenance messages', () {
      final source = _lambdaPopPda();
      final result = PDANormalizer.normalize(
        source,
        sourceMode: PDAAcceptanceMode.finalState,
        targetForm: PDANormalForm.emptyStackAndSinglePop,
      );

      expect(result.isSuccess, isTrue, reason: result.error);
      final report = result.data!;
      expect(report.structuredWarnings, hasLength(1));
      expect(
        report.structuredWarnings.single,
        PdaNormalizationMessages.growthWarning(
          addedStates: report.addedStates.length,
          addedTransitions: report.addedTransitions.length,
        ),
      );

      final initial = report.provenance.values.singleWhere(
        (entry) => entry.descriptionMessage?.code == 'initial-state',
      );
      expect(initial.description, initial.descriptionMessage!.stableCode);
      expect(
        initial.descriptionMessage,
        PdaNormalizationMessages.initialStateDescription('start'),
      );

      final singlePop = report.provenance.values.firstWhere(
        (entry) => entry.descriptionMessage?.code == 'single-pop-transition',
      );
      expect(
        singlePop.descriptionMessage,
        PdaNormalizationMessages.singlePopTransitionDescription('push-a'),
      );
      expect(
        StructuredMessage.fromJson(singlePop.descriptionMessage!.toJson()),
        singlePop.descriptionMessage,
      );

      final bottomExit = PDANormalizer.normalize(
        _emptyStackAnBnPda(),
        sourceMode: PDAAcceptanceMode.emptyStack,
        targetForm: PDANormalForm.finalStateAndSinglePop,
      );
      expect(bottomExit.isSuccess, isTrue, reason: bottomExit.error);
      expect(
        bottomExit.data!.provenance.values.any(
          (entry) => entry.descriptionMessage?.code == 'acceptance-state',
        ),
        isTrue,
      );
      final acceptEmpty = bottomExit.data!.provenance.values.firstWhere(
        (entry) => entry.descriptionMessage?.code == 'accept-empty-transition',
      );
      expect(
        acceptEmpty.descriptionMessage,
        PdaNormalizationMessages.acceptEmptyTransitionDescription(
          sourceStateId: 'q',
          targetMode: PDAAcceptanceMode.finalState,
        ),
      );

      final drain = PDANormalizer.normalize(
        _finalStateResidualStackPda(),
        sourceMode: PDAAcceptanceMode.finalState,
        targetForm: PDANormalForm.emptyStackAndSinglePop,
      );
      expect(drain.isSuccess, isTrue, reason: drain.error);
      expect(
        drain.data!.provenance.values.any(
          (entry) => entry.descriptionMessage?.code == 'drain-state',
        ),
        isTrue,
      );
      expect(
        drain.data!.provenance.values.any(
          (entry) => entry.descriptionMessage?.code == 'enter-drain-transition',
        ),
        isTrue,
      );
      expect(
        drain.data!.provenance.values.any(
          (entry) => entry.descriptionMessage?.code == 'drain-transition',
        ),
        isTrue,
      );
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
      _transition(id: 'pop-a', from: q, to: q, input: 'b', pop: 'A'),
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
      _transition(id: 'read-a', from: q, to: q, input: 'a', lambdaPop: true),
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

PDA _rawPda({
  required String id,
  required Set<State> states,
  required State? initial,
  required Set<State> accepting,
  Iterable<Transition> transitions = const [],
  Set<String> alphabet = const {'a'},
  Set<String> stackAlphabet = const {'Z'},
  String initialStackSymbol = 'Z',
}) {
  final instant = DateTime.utc(2026, 1, 1);
  return PDA(
    id: id,
    name: id,
    states: states,
    transitions: transitions.toSet(),
    alphabet: alphabet,
    initialState: initial,
    acceptingStates: accepting,
    created: instant,
    modified: instant,
    bounds: const math.Rectangle(0, 0, 400, 300),
    stackAlphabet: stackAlphabet,
    initialStackSymbol: initialStackSymbol,
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
