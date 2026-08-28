import 'dart:math' as math;

import 'package:test/test.dart';
import 'package:vector_math/vector_math_64.dart';

import 'package:turing_lab/core/algorithms/pda_simplifier.dart';
import 'package:turing_lab/core/algorithms/pda_simplification_messages.dart';
import 'package:turing_lab/core/models/pda.dart';
import 'package:turing_lab/core/models/pda_acceptance_mode.dart';
import 'package:turing_lab/core/models/pda_simplification.dart';
import 'package:turing_lab/core/models/pda_transition.dart';
import 'package:turing_lab/core/models/state.dart';
import 'package:turing_lab/core/models/transition.dart';
import 'package:turing_lab/core/messages/structured_message.dart';

void main() {
  group('PDASimplifier contract', () {
    test('accepts empty-stack semantics without final states', () {
      final pda = _emptyStackPdaWithUncertainState();

      final result = PDASimplifier.simplify(
        pda,
        acceptanceMode: PDAAcceptanceMode.emptyStack,
        options: const PDASimplificationOptions(
          enableStrongBisimulation: false,
        ),
      );

      expect(result.isSuccess, isTrue, reason: result.error);
      final report = result.data!;
      expect(report.acceptanceMode, PDAAcceptanceMode.emptyStack);
      expect(report.simplifiedPda.acceptanceMode, PDAAcceptanceMode.emptyStack);
      expect(
        report.simplifiedPda.states.map((state) => state.id),
        contains('uncertain'),
        reason: 'semantic uncertainty must retain the state',
      );
      expect(
        report.phase(PDASimplificationPhase.semanticUsefulness).status,
        PDASimplificationPhaseStatus.skipped,
      );
      expect(report.warnings, isNotEmpty);
    });

    test('requires final states only for modes that observe them', () {
      final pda = _emptyStackPdaWithUncertainState();

      for (final mode in [
        PDAAcceptanceMode.finalState,
        PDAAcceptanceMode.both,
      ]) {
        final result = PDASimplifier.simplify(pda, acceptanceMode: mode);
        expect(result.isFailure, isTrue);
        expect(result.error, 'pda.simplification.missing-accepting-state');
        expect(
          result.structuredError,
          PdaSimplificationMessages.missingAcceptingState(mode),
        );
      }
    });

    test('records structural removals with typed reasons and source ids', () {
      final pda = _pdaWithUnreachableState();

      final result = PDASimplifier.simplify(
        pda,
        acceptanceMode: PDAAcceptanceMode.finalState,
      );

      expect(result.isSuccess, isTrue, reason: result.error);
      final report = result.data!;
      expect(
        report.simplifiedPda.states.map((state) => state.id),
        isNot(contains('unreachable')),
      );
      expect(
        report.changes,
        contains(
          isA<PDASimplificationChange>()
              .having(
                (change) => change.kind,
                'kind',
                PDASimplificationChangeKind.removedState,
              )
              .having(
                (change) => change.reason,
                'reason',
                PDASimplificationChangeReason.unreachableControlState,
              )
              .having((change) => change.sourceIds, 'sourceIds', [
                'unreachable',
              ]),
        ),
      );
    });

    test('does not mutate the input PDA', () {
      final pda = _cyclicBisimilarPda();
      final before = pda.toJson();

      final result = PDASimplifier.simplify(
        pda,
        acceptanceMode: PDAAcceptanceMode.finalState,
      );

      expect(result.isSuccess, isTrue, reason: result.error);
      expect(pda.toJson(), before);
      expect(result.data!.simplifiedPda, isNot(same(pda)));
    });

    test('rejects transition symbols outside the declared alphabet', () {
      final pda = _cyclicBisimilarPda().copyWith(alphabet: const {'a', 'b'});

      final result = PDASimplifier.simplify(
        pda,
        acceptanceMode: PDAAcceptanceMode.finalState,
      );

      expect(result.isFailure, isTrue);
      expect(
        result.error,
        'pda.simplification.transition-input-symbol-outside-alphabet',
      );
      expect(result.structuredError, isNotNull);
    });

    test('rejects colliding source transition identifiers', () {
      final source = _cyclicBisimilarPda();
      final collidingTransitions = source.pdaTransitions
          .map(
            (transition) => transition.id == 'branch-right'
                ? transition.copyWith(id: 'branch-left')
                : transition,
          )
          .cast<Transition>()
          .toSet();
      final pda = source.copyWith(transitions: collidingTransitions);

      final result = PDASimplifier.simplify(
        pda,
        acceptanceMode: PDAAcceptanceMode.finalState,
      );

      expect(result.isFailure, isTrue);
      expect(result.error, 'pda.simplification.duplicate-transition-ids');
      expect(result.structuredError, isNotNull);
    });
  });

  group('PDASimplifier strong bisimulation', () {
    test('merges isomorphic cyclic states at a fixed point', () {
      final pda = _cyclicBisimilarPda();

      final result = PDASimplifier.simplify(
        pda,
        acceptanceMode: PDAAcceptanceMode.finalState,
      );

      expect(result.isSuccess, isTrue, reason: result.error);
      final report = result.data!;
      expect(report.simplifiedPda.states, hasLength(3));
      final merge = report.changes.singleWhere(
        (change) =>
            change.reason ==
            PDASimplificationChangeReason.bisimilarControlStates,
      );
      expect(merge.sourceIds, ['left', 'right']);
      expect(merge.representativeId, 'left');
      expect(
        report.phase(PDASimplificationPhase.strongBisimulation).status,
        PDASimplificationPhaseStatus.completed,
      );
    });

    test('does not merge different observable acceptance roles', () {
      final pda = _acceptanceRolePda();

      final result = PDASimplifier.simplify(
        pda,
        acceptanceMode: PDAAcceptanceMode.both,
      );

      expect(result.isSuccess, isTrue, reason: result.error);
      expect(result.data!.simplifiedPda.states, hasLength(3));
      expect(
        result.data!.changes.where(
          (change) =>
              change.reason ==
              PDASimplificationChangeReason.bisimilarControlStates,
        ),
        isEmpty,
      );
    });

    test('uses destination partitions while refining cyclic states', () {
      final pda = _differentDestinationPartitionPda();

      final result = PDASimplifier.simplify(
        pda,
        acceptanceMode: PDAAcceptanceMode.finalState,
      );

      expect(result.isSuccess, isTrue, reason: result.error);
      final remainingIds = result.data!.simplifiedPda.states
          .map((state) => state.id)
          .toSet();
      expect(remainingIds, containsAll({'toward-accept', 'toward-dead'}));
    });

    test('compares input, pop, push order, lambda flags, and destination', () {
      final pda = _differentPayloadPda();

      final result = PDASimplifier.simplify(
        pda,
        acceptanceMode: PDAAcceptanceMode.finalState,
      );

      expect(result.isSuccess, isTrue, reason: result.error);
      final remainingIds = result.data!.simplifiedPda.states
          .map((state) => state.id)
          .toSet();
      expect(
        remainingIds,
        containsAll({'input', 'pop', 'push-order', 'lambda'}),
      );
    });

    test('removes exact duplicate transitions created by a merge', () {
      final pda = _cyclicBisimilarPda();

      final result = PDASimplifier.simplify(
        pda,
        acceptanceMode: PDAAcceptanceMode.finalState,
      );

      expect(result.isSuccess, isTrue, reason: result.error);
      expect(
        result.data!.changes.any(
          (change) =>
              change.reason ==
              PDASimplificationChangeReason.duplicateTransition,
        ),
        isTrue,
      );
      final semanticKeys = result.data!.simplifiedPda.pdaTransitions
          .map(_semanticTransitionKey)
          .toList();
      expect(semanticKeys.toSet(), hasLength(semanticKeys.length));
    });
  });

  group('PDASimplifier determinism and evidence', () {
    test('exposes structured phase, warning, and evidence messages', () {
      final result = PDASimplifier.simplify(
        _cyclicBisimilarPda(),
        acceptanceMode: PDAAcceptanceMode.finalState,
        options: const PDASimplificationOptions(
          boundedCheck: PDABoundedLanguageCheck(alphabet: {'a'}, maxLength: 1),
        ),
      );

      expect(result.isSuccess, isTrue, reason: result.error);
      final report = result.data!;
      final reachability = report.phase(
        PDASimplificationPhase.structuralReachability,
      );
      expect(reachability.descriptionMessage, isNotNull);
      expect(
        reachability.description,
        reachability.descriptionMessage!.stableCode,
      );
      expect(report.structuredWarnings, [
        PdaSimplificationMessages.semanticUsefulnessUnavailable(),
      ]);

      final evidence = report.sampledEvidence!;
      expect(evidence.descriptionMessage, isNotNull);
      expect(evidence.description, evidence.descriptionMessage!.stableCode);
      expect(
        StructuredMessage.fromJson(
          Map<String, Object?>.from(evidence.descriptionMessage!.toJson()),
        ),
        evidence.descriptionMessage,
      );
    });

    test('is independent of state and transition insertion order', () {
      final baseline = PDASimplifier.simplify(
        _cyclicBisimilarPda(),
        acceptanceMode: PDAAcceptanceMode.finalState,
      ).data!;
      for (var seed = 0; seed < 10; seed++) {
        final shuffled = PDASimplifier.simplify(
          _cyclicBisimilarPda(shuffleSeed: seed),
          acceptanceMode: PDAAcceptanceMode.finalState,
        ).data!;

        expect(
          _structuralPdaDescription(shuffled.simplifiedPda),
          _structuralPdaDescription(baseline.simplifiedPda),
          reason: 'seed $seed',
        );
        expect(
          shuffled.changes.map((change) => change.toJson()).toList(),
          baseline.changes.map((change) => change.toJson()).toList(),
          reason: 'seed $seed',
        );
      }
    });

    test('is idempotent', () {
      final first = PDASimplifier.simplify(
        _cyclicBisimilarPda(),
        acceptanceMode: PDAAcceptanceMode.finalState,
      ).data!;

      final second = PDASimplifier.simplify(
        first.simplifiedPda,
        acceptanceMode: PDAAcceptanceMode.finalState,
      );

      expect(second.isSuccess, isTrue, reason: second.error);
      expect(second.data!.changed, isFalse);
      expect(second.data!.simplifiedPda.toJson(), first.simplifiedPda.toJson());
    });

    test('labels bounded comparison as sampled evidence, not proof', () {
      final result = PDASimplifier.simplify(
        _cyclicBisimilarPda(),
        acceptanceMode: PDAAcceptanceMode.finalState,
        options: const PDASimplificationOptions(
          boundedCheck: PDABoundedLanguageCheck(
            alphabet: {'a', 'b', 'c'},
            maxLength: 3,
          ),
        ),
      );

      expect(result.isSuccess, isTrue, reason: result.error);
      final evidence = result.data!.sampledEvidence;
      expect(evidence, isNotNull);
      expect(evidence!.isProof, isFalse);
      expect(evidence.wordsChecked, 40);
      expect(evidence.description.toLowerCase(), contains('sample'));
      expect(
        result.data!.phase(PDASimplificationPhase.boundedLanguageCheck).status,
        PDASimplificationPhaseStatus.completed,
      );
    });

    test('checks bounded samples under every declared acceptance mode', () {
      for (final mode in PDAAcceptanceMode.values) {
        final result = PDASimplifier.simplify(
          _cyclicBisimilarPda(),
          acceptanceMode: mode,
          options: const PDASimplificationOptions(
            boundedCheck: PDABoundedLanguageCheck(
              alphabet: {'a', 'b', 'c'},
              maxLength: 2,
            ),
          ),
        );

        expect(result.isSuccess, isTrue, reason: '$mode: ${result.error}');
        expect(result.data!.sampledEvidence!.wordsChecked, 13);
      }
    });

    test(
      'covers representative PDA languages with sampled regression checks',
      () {
        final cases =
            <({String name, PDA pda, PDAAcceptanceMode mode, int maxLength})>[
              (
                name: 'epsilon',
                pda: _epsilonPda(),
                mode: PDAAcceptanceMode.finalState,
                maxLength: 2,
              ),
              (
                name: 'empty language',
                pda: _emptyLanguagePda(),
                mode: PDAAcceptanceMode.finalState,
                maxLength: 3,
              ),
              (
                name: 'residual-stack final-state acceptance',
                pda: _residualStackFinalStatePda(),
                mode: PDAAcceptanceMode.finalState,
                maxLength: 3,
              ),
              (
                name: 'empty-stack acceptance without finals',
                pda: _emptyStackAcceptancePda(),
                mode: PDAAcceptanceMode.emptyStack,
                maxLength: 3,
              ),
              (
                name: 'a^n b^n with combined acceptance',
                pda: _anbnPda(),
                mode: PDAAcceptanceMode.both,
                maxLength: 4,
              ),
            ];

        for (final testCase in cases) {
          final result = PDASimplifier.simplify(
            testCase.pda,
            acceptanceMode: testCase.mode,
            options: PDASimplificationOptions(
              boundedCheck: PDABoundedLanguageCheck(
                alphabet: testCase.pda.alphabet,
                maxLength: testCase.maxLength,
              ),
            ),
          );

          expect(
            result.isSuccess,
            isTrue,
            reason: '${testCase.name}: ${result.error}',
          );
          expect(result.data!.sampledEvidence, isNotNull);
        }
      },
    );
  });
}

PDA _emptyStackPdaWithUncertainState() {
  final start = _state('start', initial: true);
  final uncertain = _state('uncertain', x: 100);
  return _pda(
    id: 'empty-stack',
    states: [start, uncertain],
    transitions: [
      _transition(
        id: 'reach-uncertain',
        from: start,
        to: uncertain,
        input: 'a',
        pop: 'Z',
        push: const ['Z'],
      ),
    ],
    initial: start,
    accepting: const [],
    alphabet: const {'a'},
  );
}

PDA _pdaWithUnreachableState() {
  final start = _state('start', initial: true);
  final accept = _state('accept', accepting: true, x: 100);
  final unreachable = _state('unreachable', x: 200);
  return _pda(
    id: 'unreachable-pda',
    states: [start, accept, unreachable],
    transitions: [
      _transition(id: 'accept-a', from: start, to: accept, input: 'a'),
      _transition(
        id: 'unreachable-loop',
        from: unreachable,
        to: unreachable,
        input: 'a',
      ),
    ],
    initial: start,
    accepting: [accept],
    alphabet: const {'a'},
  );
}

PDA _cyclicBisimilarPda({int? shuffleSeed}) {
  final start = _state('start', initial: true);
  final left = _state('left', x: 100);
  final right = _state('right', x: 200);
  final accept = _state('accept', accepting: true, x: 300);
  final states = [start, left, right, accept];
  final transitions = [
    _transition(id: 'branch-left', from: start, to: left, input: 'a'),
    _transition(id: 'branch-right', from: start, to: right, input: 'a'),
    _transition(id: 'left-loop', from: left, to: left, input: 'b'),
    _transition(id: 'right-loop', from: right, to: right, input: 'b'),
    _transition(id: 'left-accept', from: left, to: accept, input: 'c'),
    _transition(id: 'right-accept', from: right, to: accept, input: 'c'),
  ];
  if (shuffleSeed != null) {
    states.shuffle(math.Random(shuffleSeed));
    transitions.shuffle(math.Random(shuffleSeed + 1000));
  }
  return _pda(
    id: 'cyclic',
    states: states,
    transitions: transitions,
    initial: start,
    accepting: [accept],
    alphabet: const {'a', 'b', 'c'},
  );
}

PDA _acceptanceRolePda() {
  final start = _state('start', initial: true);
  final normal = _state('normal', x: 100);
  final accept = _state('accept', accepting: true, x: 200);
  return _pda(
    id: 'roles',
    states: [start, normal, accept],
    transitions: [
      _transition(id: 'to-normal', from: start, to: normal, input: 'a'),
      _transition(id: 'to-accept', from: start, to: accept, input: 'a'),
    ],
    initial: start,
    accepting: [accept],
    alphabet: const {'a'},
  );
}

PDA _differentDestinationPartitionPda() {
  final start = _state('start', initial: true);
  final towardAccept = _state('toward-accept', x: 100);
  final towardDead = _state('toward-dead', x: 200);
  final accept = _state('accept', accepting: true, x: 300);
  final dead = _state('dead', x: 400);
  return _pda(
    id: 'destinations',
    states: [start, towardAccept, towardDead, accept, dead],
    transitions: [
      _transition(id: 'branch-1', from: start, to: towardAccept, input: 'a'),
      _transition(id: 'branch-2', from: start, to: towardDead, input: 'a'),
      _transition(id: 'finish-1', from: towardAccept, to: accept, input: 'b'),
      _transition(id: 'finish-2', from: towardDead, to: dead, input: 'b'),
      _transition(id: 'dead-loop', from: dead, to: dead, input: 'a'),
    ],
    initial: start,
    accepting: [accept],
    alphabet: const {'a', 'b'},
  );
}

PDA _differentPayloadPda() {
  final start = _state('start', initial: true);
  final input = _state('input', x: 100);
  final pop = _state('pop', x: 200);
  final pushOrder = _state('push-order', x: 300);
  final lambda = _state('lambda', x: 400);
  final accept = _state('accept', accepting: true, x: 500);
  return _pda(
    id: 'payloads',
    states: [start, input, pop, pushOrder, lambda, accept],
    transitions: [
      for (final state in [input, pop, pushOrder, lambda])
        _transition(
          id: 'reach-${state.id}',
          from: start,
          to: state,
          input: 'r',
        ),
      _transition(id: 'by-input', from: input, to: accept, input: 'a'),
      _transition(
        id: 'by-pop',
        from: pop,
        to: accept,
        input: 'b',
        pop: 'A',
        push: const ['A'],
      ),
      _transition(
        id: 'by-push-order',
        from: pushOrder,
        to: accept,
        input: 'b',
        push: const ['A', 'Z'],
      ),
      _transition(id: 'by-lambda', from: lambda, to: accept, lambdaInput: true),
    ],
    initial: start,
    accepting: [accept],
    alphabet: const {'r', 'a', 'b'},
    stackAlphabet: const {'Z', 'A'},
  );
}

PDA _epsilonPda() {
  final start = _state('start', initial: true, accepting: true);
  return _pda(
    id: 'epsilon',
    states: [start],
    transitions: [
      _transition(
        id: 'epsilon-loop',
        from: start,
        to: start,
        lambdaInput: true,
        lambdaPop: true,
        push: const [],
      ),
    ],
    initial: start,
    accepting: [start],
    alphabet: const {},
  );
}

PDA _emptyLanguagePda() {
  final start = _state('start', initial: true);
  final accept = _state('accept', accepting: true, x: 100);
  return _pda(
    id: 'empty-language',
    states: [start, accept],
    transitions: [
      _transition(
        id: 'impossible-stack-pop',
        from: start,
        to: accept,
        input: 'a',
        pop: 'A',
        push: const ['A'],
      ),
    ],
    initial: start,
    accepting: [accept],
    alphabet: const {'a'},
    stackAlphabet: const {'Z', 'A'},
  );
}

PDA _residualStackFinalStatePda() {
  final start = _state('start', initial: true);
  final accept = _state('accept', accepting: true, x: 100);
  return _pda(
    id: 'residual-stack',
    states: [start, accept],
    transitions: [
      _transition(
        id: 'leave-residual-stack',
        from: start,
        to: accept,
        input: 'a',
        push: const ['A', 'Z'],
      ),
    ],
    initial: start,
    accepting: [accept],
    alphabet: const {'a'},
    stackAlphabet: const {'Z', 'A'},
  );
}

PDA _emptyStackAcceptancePda() {
  final start = _state('start', initial: true);
  final done = _state('done', x: 100);
  return _pda(
    id: 'empty-stack-language',
    states: [start, done],
    transitions: [
      _transition(
        id: 'empty-stack-on-a',
        from: start,
        to: done,
        input: 'a',
        push: const [],
      ),
    ],
    initial: start,
    accepting: const [],
    alphabet: const {'a'},
  );
}

PDA _anbnPda() {
  final push = _state('push', initial: true);
  final pop = _state('pop', x: 100);
  final accept = _state('accept', accepting: true, x: 200);
  final unreachable = _state('unreachable', x: 300);
  return _pda(
    id: 'anbn',
    states: [push, pop, accept, unreachable],
    transitions: [
      _transition(
        id: 'first-a',
        from: push,
        to: push,
        input: 'a',
        pop: 'Z',
        push: const ['A', 'Z'],
      ),
      _transition(
        id: 'more-a',
        from: push,
        to: push,
        input: 'a',
        pop: 'A',
        push: const ['A', 'A'],
      ),
      _transition(
        id: 'first-b',
        from: push,
        to: pop,
        input: 'b',
        pop: 'A',
        push: const [],
      ),
      _transition(
        id: 'more-b',
        from: pop,
        to: pop,
        input: 'b',
        pop: 'A',
        push: const [],
      ),
      _transition(
        id: 'finish',
        from: pop,
        to: accept,
        lambdaInput: true,
        pop: 'Z',
        push: const [],
      ),
    ],
    initial: push,
    accepting: [accept],
    alphabet: const {'a', 'b'},
    stackAlphabet: const {'Z', 'A'},
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
  String pop = 'Z',
  bool lambdaPop = false,
  List<String> push = const ['Z'],
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
    popSymbol: lambdaPop ? '' : pop,
    pushSymbol: push.join(),
    pushSymbols: push,
    isLambdaInput: lambdaInput,
    isLambdaPop: lambdaPop,
    isLambdaPush: lambdaPush,
    controlPoint: from == to
        ? Vector2(from.position.x + 24, from.position.y + 24)
        : null,
  );
}

PDA _pda({
  required String id,
  required List<State> states,
  required List<PDATransition> transitions,
  required State initial,
  required List<State> accepting,
  required Set<String> alphabet,
  Set<String> stackAlphabet = const {'Z'},
}) {
  final instant = DateTime.utc(2026, 1, 1);
  return PDA(
    id: id,
    name: id,
    states: states.toSet(),
    transitions: transitions.toSet(),
    alphabet: alphabet,
    initialState: initial,
    acceptingStates: accepting.toSet(),
    created: instant,
    modified: instant,
    bounds: const math.Rectangle(0, 0, 800, 600),
    stackAlphabet: stackAlphabet,
    initialStackSymbol: 'Z',
  );
}

String _semanticTransitionKey(PDATransition transition) {
  return [
    transition.fromState.id,
    transition.toState.id,
    transition.inputSymbol,
    transition.popSymbol,
    transition.pushSymbols.join(','),
    transition.isLambdaInput,
    transition.isLambdaPop,
    transition.isLambdaPush,
  ].join('|');
}

Map<String, Object?> _structuralPdaDescription(PDA pda) {
  final states =
      pda.states
          .map((state) => [state.id, state.isInitial, state.isAccepting])
          .toList()
        ..sort(
          (left, right) =>
              left.first.toString().compareTo(right.first.toString()),
        );
  final transitions = pda.pdaTransitions.map(_semanticTransitionKey).toList()
    ..sort();
  return {
    'states': states,
    'transitions': transitions,
    'initial': pda.initialState?.id,
    'accepting': pda.acceptingStates.map((state) => state.id).toList()..sort(),
    'alphabet': pda.alphabet.toList()..sort(),
    'stackAlphabet': pda.stackAlphabet.toList()..sort(),
  };
}
