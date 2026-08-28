// Mutable fixture collections verify constructor snapshot behavior.
// ignore_for_file: prefer_const_constructors

import 'package:test/test.dart';
import 'package:turing_lab/core/transducers/transducers.dart';

void main() {
  group('transducer domain contract', () {
    test('Mealy and Moore payload ownership stays structurally distinct', () {
      final mealy = MealyMachine(
        id: const TransducerMachineId('mealy'),
        name: 'Mealy',
        revision: const TransducerRevision(3),
        inputAlphabet: {TransducerInputSymbol('a')},
        outputAlphabet: {TransducerOutputSymbol('x')},
        states: [
          MealyState(
            id: TransducerStateId('q0'),
            label: 'start',
            position: TransducerPoint(10, 20),
            isInitial: true,
          ),
        ],
        transitions: [
          MealyTransition(
            id: TransducerTransitionId('t0'),
            from: TransducerStateId('q0'),
            to: TransducerStateId('q0'),
            input: TransducerInputSymbol('a'),
            output: TransducerOutputWord([TransducerOutputSymbol('x')]),
          ),
        ],
      );
      final moore = MooreMachine(
        id: const TransducerMachineId('moore'),
        name: 'Moore',
        revision: const TransducerRevision(4),
        inputAlphabet: {TransducerInputSymbol('a')},
        outputAlphabet: {TransducerOutputSymbol('x')},
        states: [
          MooreState(
            id: TransducerStateId('q0'),
            label: 'start',
            position: TransducerPoint(10, 20),
            isInitial: true,
            output: TransducerOutputWord([TransducerOutputSymbol('x')]),
          ),
        ],
        transitions: [
          MooreTransition(
            id: TransducerTransitionId('t0'),
            from: TransducerStateId('q0'),
            to: TransducerStateId('q0'),
            input: TransducerInputSymbol('a'),
          ),
        ],
      );

      expect(mealy.states.single, isA<MealyState>());
      expect(mealy.transitions.single.output.values, ['x']);
      expect(moore.states.single.output.values, ['x']);
      expect(moore.transitions.single, isA<MooreTransition>());
      expect(mealy.toJson(), isNot(contains('acceptingStates')));
      expect(moore.toJson(), isNot(contains('acceptingStates')));
    });

    test('constructors snapshot collections and copyWith is immutable', () {
      final states = <MealyState>[
        const MealyState(
          id: TransducerStateId('q1'),
          label: 'one',
          position: TransducerPoint(1, 1),
        ),
        const MealyState(
          id: TransducerStateId('q0'),
          label: 'zero',
          position: TransducerPoint(0, 0),
          isInitial: true,
        ),
      ];
      final machine = MealyMachine(
        id: const TransducerMachineId('m'),
        name: 'snapshot',
        revision: const TransducerRevision(1),
        inputAlphabet: {TransducerInputSymbol('a')},
        outputAlphabet: {},
        states: states,
        transitions: [],
      );
      states.clear();

      expect(machine.states.map((state) => state.id.value), ['q0', 'q1']);
      expect(
        () => machine.states.add(machine.states.first),
        throwsUnsupportedError,
      );

      final changed = machine.copyWith(
        name: 'changed',
        revision: const TransducerRevision(2),
      );
      expect(machine.name, 'snapshot');
      expect(machine.revision.value, 1);
      expect(changed.name, 'changed');
      expect(changed.revision.value, 2);
    });
  });

  group('tokenization contract', () {
    test('uses deterministic maximal munch for Unicode and long symbols', () {
      final outcome = TransducerInputTokenizer.tokenize('ab🙂a', {
        TransducerInputSymbol('a'),
        TransducerInputSymbol('ab'),
        TransducerInputSymbol('🙂'),
      });

      expect(outcome, isA<TransducerTokenizationSuccess>());
      expect((outcome as TransducerTokenizationSuccess).word.values, [
        'ab',
        '🙂',
        'a',
      ]);
    });

    test('prefix-overlap is resolved by maximal munch, unlike JFLAP', () {
      final outcome =
          TransducerInputTokenizer.tokenize('aaa', {
                TransducerInputSymbol('a'),
                TransducerInputSymbol('aa'),
              })
              as TransducerTokenizationSuccess;

      expect(outcome.word.values, ['aa', 'a']);
    });

    test('empty raw input is an empty word and unknown suffix is typed', () {
      final empty =
          TransducerInputTokenizer.tokenize('', {TransducerInputSymbol('a')})
              as TransducerTokenizationSuccess;
      expect(empty.word.symbols, isEmpty);

      final invalid = TransducerInputTokenizer.tokenize('ab?', {
        TransducerInputSymbol('a'),
        TransducerInputSymbol('b'),
      });
      expect(invalid, isA<TransducerTokenizationFailure>());
      expect((invalid as TransducerTokenizationFailure).offset, 2);
      expect(invalid.remaining, '?');

      final unicodeFailure =
          TransducerInputTokenizer.tokenize('🙂?', {
                const TransducerInputSymbol('🙂'),
              })
              as TransducerTokenizationFailure;
      expect(unicodeFailure.offset, 2, reason: 'offset uses UTF-16 code units');
    });

    test('word constructors snapshot symbol lists and preserve boundaries', () {
      final inputSymbols = [const TransducerInputSymbol('ab')];
      final outputSymbols = [const TransducerOutputSymbol('🙂')];
      final input = TransducerInputWord(inputSymbols);
      final output = TransducerOutputWord(outputSymbols);
      inputSymbols.add(const TransducerInputSymbol('c'));
      outputSymbols.clear();

      expect(input.values, ['ab']);
      expect(output.values, ['🙂']);
      expect(input, isNot(TransducerInputWord.fromValues(['a', 'b'])));
      expect(
        input.render(),
        TransducerInputWord.fromValues(['a', 'b']).render(),
      );
      expect(
        () => input.symbols.add(const TransducerInputSymbol('x')),
        throwsUnsupportedError,
      );
      expect(() => output.symbols.clear(), throwsUnsupportedError);
    });

    test('empty output is a zero-symbol word', () {
      expect(TransducerOutputWord.empty.symbols, isEmpty);
      expect(TransducerOutputWord.empty.render(), '');
      expect(
        TransducerOutputWord([
          TransducerOutputSymbol('🙂'),
          TransducerOutputSymbol('ok'),
        ]).values,
        ['🙂', 'ok'],
      );
    });
  });

  group('versioned JSON', () {
    test('round trips Mealy and Moore deterministically', () {
      final mealy = _mealyFixture();
      final moore = _mooreFixture();

      expect(MealyMachine.fromJson(mealy.toJson()).toJson(), mealy.toJson());
      expect(MooreMachine.fromJson(moore.toJson()).toJson(), moore.toJson());
      expect(mealy.toJson()['schema'], {
        'id': 'turing-lab.mealy',
        'version': 1,
      });
      expect(moore.toJson()['schema'], {
        'id': 'turing-lab.moore',
        'version': 1,
      });
    });

    test('rejects malformed or future JSON without partial fallback', () {
      final original = _mealyFixture();
      final before = original.toJson();
      final future = original.toJson();
      future['schema'] = {'id': 'turing-lab.mealy', 'version': 99};

      expect(
        () => MealyMachine.fromJson(future),
        throwsA(
          isA<TransducerDecodeException>()
              .having(
                (error) => error.code,
                'code',
                TransducerDecodeErrorCode.unsupportedVersion,
              )
              .having(
                (error) => error.message,
                'message',
                'transducer.decode.unsupported-version',
              )
              .having((error) => error.source, 'source', 99),
        ),
      );
      expect(
        () => MealyMachine.fromJson({
          ..._mealyFixture().toJson(),
          'states': 'not-a-list',
        }),
        throwsA(
          isA<TransducerDecodeException>()
              .having(
                (error) => error.code,
                'code',
                TransducerDecodeErrorCode.malformedPayload,
              )
              .having(
                (error) => error.message,
                'message',
                'transducer.decode.list-required',
              )
              .having((error) => error.source, 'source', 'states'),
        ),
      );
      expect(original.toJson(), before);
    });
  });
}

MealyMachine _mealyFixture() => MealyMachine(
  id: const TransducerMachineId('mealy-fixture'),
  name: 'Mealy fixture',
  revision: const TransducerRevision(7),
  inputAlphabet: {TransducerInputSymbol('a'), TransducerInputSymbol('bb')},
  outputAlphabet: {TransducerOutputSymbol('x'), TransducerOutputSymbol('🙂')},
  states: [
    MealyState(
      id: TransducerStateId('q1'),
      label: 'one',
      position: TransducerPoint(20, 10),
    ),
    MealyState(
      id: TransducerStateId('q0'),
      label: 'zero',
      position: TransducerPoint(0, 0),
      isInitial: true,
    ),
  ],
  transitions: [
    MealyTransition(
      id: TransducerTransitionId('t1'),
      from: TransducerStateId('q1'),
      to: TransducerStateId('q0'),
      input: TransducerInputSymbol('bb'),
      output: TransducerOutputWord.empty,
    ),
    MealyTransition(
      id: TransducerTransitionId('t0'),
      from: TransducerStateId('q0'),
      to: TransducerStateId('q1'),
      input: TransducerInputSymbol('a'),
      output: TransducerOutputWord([TransducerOutputSymbol('x')]),
    ),
  ],
);

MooreMachine _mooreFixture() => MooreMachine(
  id: const TransducerMachineId('moore-fixture'),
  name: 'Moore fixture',
  revision: const TransducerRevision(8),
  inputAlphabet: {TransducerInputSymbol('a')},
  outputAlphabet: {TransducerOutputSymbol('x')},
  states: [
    MooreState(
      id: TransducerStateId('q0'),
      label: 'zero',
      position: TransducerPoint(0, 0),
      isInitial: true,
      output: TransducerOutputWord([TransducerOutputSymbol('x')]),
    ),
  ],
  transitions: [
    MooreTransition(
      id: TransducerTransitionId('t0'),
      from: TransducerStateId('q0'),
      to: TransducerStateId('q0'),
      input: TransducerInputSymbol('a'),
    ),
  ],
);
