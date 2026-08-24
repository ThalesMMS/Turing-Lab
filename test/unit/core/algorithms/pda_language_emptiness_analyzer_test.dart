import 'dart:math' as math;

import 'package:test/test.dart';
import 'package:vector_math/vector_math_64.dart';

import 'package:turing_lab/core/algorithms/pda_language_emptiness_analyzer.dart';
import 'package:turing_lab/core/models/grammar.dart';
import 'package:turing_lab/core/models/pda.dart';
import 'package:turing_lab/core/models/pda_acceptance_mode.dart';
import 'package:turing_lab/core/models/pda_transition.dart';
import 'package:turing_lab/core/models/production.dart';
import 'package:turing_lab/core/models/state.dart';

void main() {
  group('PDALanguageEmptinessAnalyzer', () {
    test('proves empty when every accepting state is unreachable', () {
      final start = _state('start', initial: true);
      final accept = _state('accept', accepting: true);
      final pda = _pda(
        id: 'unreachable-accept',
        states: {start, accept},
        initial: start,
        accepting: {accept},
      );

      final analysis = PDALanguageEmptinessAnalyzer.analyze(
        pda,
        acceptanceMode: PDAAcceptanceMode.finalState,
      );

      expect(analysis, isA<PDALanguageEmptinessProof>());
      final proof = analysis as PDALanguageEmptinessProof;
      expect(proof.isEmpty, isTrue);
      expect(proof.witnessWord, isNull);
      expect(proof.derivation, isEmpty);
      expect(proof.witnessTrace, isNull);
    });

    test('returns epsilon and an accepting replay for an epsilon-only PDA', () {
      final start = _state('start', initial: true, accepting: true);
      final pda = _pda(
        id: 'epsilon-only',
        states: {start},
        initial: start,
        accepting: {start},
      );

      final analysis = PDALanguageEmptinessAnalyzer.analyze(
        pda,
        acceptanceMode: PDAAcceptanceMode.finalState,
      );

      final proof = analysis as PDALanguageEmptinessProof;
      expect(proof.isEmpty, isFalse);
      expect(proof.witnessSymbols, isEmpty);
      expect(proof.witnessWord, '');
      expect(proof.terminalSymbolLength, 0);
      expect(proof.derivation, isNotEmpty);
      expect(proof.witnessTrace?.accepted, isTrue);
    });

    test('finds ab as the shortest word of non-empty a^n b^n', () {
      final pda = _nonEmptyAnBnPda();

      final analysis = PDALanguageEmptinessAnalyzer.analyze(
        pda,
        acceptanceMode: PDAAcceptanceMode.emptyStack,
      );

      final proof = analysis as PDALanguageEmptinessProof;
      expect(proof.isEmpty, isFalse);
      expect(proof.witnessSymbols, ['a', 'b']);
      expect(proof.witnessWord, 'ab');
      expect(proof.derivation.last.after, ['a', 'b']);
      expect(proof.witnessTrace?.accepted, isTrue);
    });

    test('uses deterministic shortlex order between equal-length words', () {
      final start = _state('start', initial: true);
      final accept = _state('accept', accepting: true);
      final pda = _pda(
        id: 'shortlex',
        states: {start, accept},
        initial: start,
        accepting: {accept},
        alphabet: const {'b', 'a'},
        transitions: {
          _transition(
            id: 'read-b',
            from: start,
            to: accept,
            input: 'b',
            pop: 'Z',
          ),
          _transition(
            id: 'read-a',
            from: start,
            to: accept,
            input: 'a',
            pop: 'Z',
          ),
        },
      );

      final first = PDALanguageEmptinessAnalyzer.analyze(
        pda,
        acceptanceMode: PDAAcceptanceMode.finalState,
      ) as PDALanguageEmptinessProof;
      final second = PDALanguageEmptinessAnalyzer.analyze(
        pda,
        acceptanceMode: PDAAcceptanceMode.finalState,
      ) as PDALanguageEmptinessProof;

      expect(first.witnessSymbols, ['a']);
      expect(second.witnessSymbols, first.witnessSymbols);
      expect(
        second.derivation.map((step) => step.productionId),
        first.derivation.map((step) => step.productionId),
      );
    });

    test('supports empty-stack semantics without accepting states', () {
      final start = _state('start', initial: true);
      final pda = _pda(
        id: 'empty-stack-epsilon',
        states: {start},
        initial: start,
        accepting: const {},
        transitions: {
          _transition(
            id: 'empty-stack',
            from: start,
            to: start,
            lambdaInput: true,
            pop: 'Z',
          ),
        },
      );

      final analysis = PDALanguageEmptinessAnalyzer.analyze(
        pda,
        acceptanceMode: PDAAcceptanceMode.emptyStack,
      ) as PDALanguageEmptinessProof;

      expect(analysis.isEmpty, isFalse);
      expect(analysis.witnessWord, '');
      expect(analysis.witnessTrace?.accepted, isTrue);
    });

    test('preserves combined final-state and empty-stack semantics', () {
      final start = _state('start', initial: true);
      final accept = _state('accept', accepting: true);
      final pda = _pda(
        id: 'combined',
        states: {start, accept},
        initial: start,
        accepting: {accept},
        alphabet: const {'a'},
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

      final analysis = PDALanguageEmptinessAnalyzer.analyze(
        pda,
        acceptanceMode: PDAAcceptanceMode.both,
      ) as PDALanguageEmptinessProof;

      expect(analysis.witnessWord, 'a');
      expect(analysis.witnessTrace?.accepted, isTrue);
    });

    test('normalizes lambda-pop transitions before proving a witness', () {
      final start = _state('start', initial: true);
      final accept = _state('accept', accepting: true);
      final pda = _pda(
        id: 'lambda-pop',
        states: {start, accept},
        initial: start,
        accepting: {accept},
        alphabet: const {'a'},
        transitions: {
          _transition(
            id: 'read-without-pop',
            from: start,
            to: accept,
            input: 'a',
            lambdaPop: true,
          ),
        },
      );

      final analysis = PDALanguageEmptinessAnalyzer.analyze(
        pda,
        acceptanceMode: PDAAcceptanceMode.finalState,
      ) as PDALanguageEmptinessProof;

      expect(analysis.witnessWord, 'a');
      expect(analysis.normalization.replacedTransitionIds, {
        'read-without-pop',
      });
      expect(
        analysis.normalizedPda.pdaTransitions
            .every((transition) => !transition.isLambdaPop),
        isTrue,
      );
      expect(analysis.witnessTrace?.accepted, isTrue);
    });

    test('counts multi-character terminals as one grammar symbol', () {
      final start = _state('start', initial: true);
      final accept = _state('accept', accepting: true);
      final pda = _pda(
        id: 'atomic-terminals',
        states: {start, accept},
        initial: start,
        accepting: {accept},
        alphabet: const {'token'},
        transitions: {
          _transition(
            id: 'read-token',
            from: start,
            to: accept,
            input: 'token',
            pop: 'Z',
          ),
        },
      );

      final analysis = PDALanguageEmptinessAnalyzer.analyze(
        pda,
        acceptanceMode: PDAAcceptanceMode.finalState,
      ) as PDALanguageEmptinessProof;

      expect(analysis.witnessSymbols, ['token']);
      expect(analysis.terminalSymbolLength, 1);
      expect(analysis.witnessWord, 'token');
    });

    test('keeps a terminal named S distinct from the CFG start symbol', () {
      final start = _state('start', initial: true);
      final accept = _state('accept', accepting: true);
      final pda = _pda(
        id: 'terminal-start-collision',
        states: {start, accept},
        initial: start,
        accepting: {accept},
        alphabet: const {'S'},
        transitions: {
          _transition(
            id: 'read-S',
            from: start,
            to: accept,
            input: 'S',
            pop: 'Z',
          ),
        },
      );

      final analysis = PDALanguageEmptinessAnalyzer.analyze(
        pda,
        acceptanceMode: PDAAcceptanceMode.finalState,
      ) as PDALanguageEmptinessProof;

      expect(analysis.isEmpty, isFalse);
      expect(analysis.grammar.startSymbol, isNot('S'));
      expect(analysis.witnessSymbols, ['S']);
      expect(analysis.witnessTrace?.accepted, isTrue);
    });

    test('distinguishes cancellation and production limits from emptiness', () {
      final start = _state('start', initial: true, accepting: true);
      final pda = _pda(
        id: 'limited',
        states: {start},
        initial: start,
        accepting: {start},
      );

      final cancelled = PDALanguageEmptinessAnalyzer.analyze(
        pda,
        acceptanceMode: PDAAcceptanceMode.finalState,
        isCancelled: () => true,
      );
      final limited = PDALanguageEmptinessAnalyzer.analyze(
        pda,
        acceptanceMode: PDAAcceptanceMode.finalState,
        limits: const PDALanguageEmptinessLimits(
          maxGeneratedProductions: 1,
        ),
      );

      expect(cancelled, isA<PDALanguageEmptinessFailure>());
      expect(
        (cancelled as PDALanguageEmptinessFailure).kind,
        PDALanguageEmptinessFailureKind.cancelled,
      );
      expect(limited, isA<PDALanguageEmptinessFailure>());
      expect(
        (limited as PDALanguageEmptinessFailure).kind,
        PDALanguageEmptinessFailureKind.resourceLimit,
      );
    });
  });

  group('CFGShortestWitnessAnalyzer', () {
    test('handles productive cycles and ignores unproductive branches', () {
      final instant = DateTime.utc(2026, 1, 1);
      final grammar = Grammar(
        id: 'cyclic',
        name: 'Cyclic grammar',
        terminals: const {'a'},
        nonterminals: const {'S', 'A', 'B', 'U'},
        startSymbol: 'S',
        productions: {
          const Production(
            id: 's-a',
            leftSide: ['S'],
            rightSide: ['A'],
          ),
          const Production(
            id: 'a-b',
            leftSide: ['A'],
            rightSide: ['B'],
          ),
          const Production(
            id: 'b-a',
            leftSide: ['B'],
            rightSide: ['A'],
          ),
          const Production(
            id: 'b-terminal',
            leftSide: ['B'],
            rightSide: ['a'],
          ),
          const Production(
            id: 's-u',
            leftSide: ['S'],
            rightSide: ['U'],
          ),
          const Production(
            id: 'u-u',
            leftSide: ['U'],
            rightSide: ['U'],
          ),
        },
        type: GrammarType.contextFree,
        created: instant,
        modified: instant,
      );

      final analysis = CFGShortestWitnessAnalyzer.analyze(grammar);

      expect(analysis, isA<CFGShortestWitnessProof>());
      final proof = analysis as CFGShortestWitnessProof;
      expect(proof.isEmpty, isFalse);
      expect(proof.witnessSymbols, ['a']);
      expect(proof.productiveNonterminals, containsAll({'S', 'A', 'B'}));
      expect(proof.productiveNonterminals, isNot(contains('U')));
      expect(proof.derivation.last.after, ['a']);
    });
  });
}

PDA _nonEmptyAnBnPda() {
  final push = _state('push', initial: true);
  final pop = _state('pop');
  return _pda(
    id: 'anbn',
    states: {push, pop},
    initial: push,
    accepting: const {},
    alphabet: const {'a', 'b'},
    stackAlphabet: const {'Z', 'A'},
    transitions: {
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
      ),
      _transition(
        id: 'more-b',
        from: pop,
        to: pop,
        input: 'b',
        pop: 'A',
      ),
      _transition(
        id: 'finish',
        from: pop,
        to: pop,
        lambdaInput: true,
        pop: 'Z',
      ),
    },
  );
}

State _state(
  String id, {
  bool initial = false,
  bool accepting = false,
}) {
  return State(
    id: id,
    label: id,
    position: Vector2.zero(),
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
  required State initial,
  required Set<State> accepting,
  Set<PDATransition> transitions = const {},
  Set<String> alphabet = const {},
  Set<String> stackAlphabet = const {'Z'},
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
    bounds: const math.Rectangle(0, 0, 300, 200),
    stackAlphabet: stackAlphabet,
    initialStackSymbol: 'Z',
  );
}
