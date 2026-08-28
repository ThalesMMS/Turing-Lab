part of '../pda_simulator_extended_test.dart';

void _runPdaAnalysisTests() {
  PDA invalidPdaFixture() {
    return PDA(
      id: 'invalid',
      name: 'Invalid PDA',
      states: const {},
      transitions: const {},
      alphabet: const {},
      initialState: null,
      acceptingStates: const {},
      created: DateTime.utc(2026, 1, 1),
      modified: DateTime.utc(2026, 1, 1),
      bounds: const math.Rectangle(0, 0, 400, 300),
      stackAlphabet: const {'Z'},
    );
  }

  group('PDASimulator.analyzePDA', () {
    test('returns success for valid PDA', () {
      final pda = _pdaAcceptsA();
      final result = PDASimulator.analyzePDA(pda);
      expect(result.isSuccess, true);
    });

    test('reports correct state counts', () {
      final pda =
          _pdaAcceptsA(); // 2 states: q0 (non-accepting), q1 (accepting)
      final result = PDASimulator.analyzePDA(pda);
      expect(result.isSuccess, true);
      expect(result.data!.stateAnalysis.totalStates, 2);
      expect(result.data!.stateAnalysis.acceptingStates, 1);
      expect(result.data!.stateAnalysis.nonAcceptingStates, 1);
    });

    test('reports correct transition counts', () {
      final pda = _pdaAcceptsA(); // 1 PDA transition
      final result = PDASimulator.analyzePDA(pda);
      expect(result.isSuccess, true);
      expect(result.data!.transitionAnalysis.totalTransitions, 1);
      expect(result.data!.transitionAnalysis.pdaTransitions, 1);
      expect(result.data!.transitionAnalysis.fsaTransitions, 0);
    });

    test('reports push operations from transitions', () {
      final pda = _pdaAcceptsA(); // pushes 'Z'
      final result = PDASimulator.analyzePDA(pda);
      expect(result.isSuccess, true);
      expect(result.data!.stackAnalysis.pushOperations, contains('Z'));
    });

    test('reports compound stack operations as full symbols', () {
      final q0 = State(
        id: 'q0',
        label: 'q0',
        position: Vector2.zero(),
        isInitial: true,
      );
      final q1 = State(
        id: 'q1',
        label: 'q1',
        position: Vector2(100, 0),
        isAccepting: true,
      );
      final pda = PDA(
        id: 'compound_stack_symbols',
        name: 'Compound Stack Symbols',
        states: {q0, q1},
        transitions: {
          PDATransition(
            id: 't0',
            fromState: q0,
            toState: q1,
            inputSymbol: '',
            popSymbol: 'BY',
            pushSymbol: 'AZ',
            label: 'ε,BY/AZ',
          ),
        },
        alphabet: const {},
        stackAlphabet: const {'A', 'B', 'Y', 'Z'},
        initialState: q0,
        acceptingStates: {q1},
        initialStackSymbol: 'Z',
        created: DateTime.now(),
        modified: DateTime.now(),
        bounds: const math.Rectangle(0, 0, 400, 300),
      );

      final result = PDASimulator.analyzePDA(pda);

      expect(result.isSuccess, true);
      expect(
        result.data!.stackAnalysis.stackSymbols,
        containsAll({'AZ', 'BY'}),
      );
      expect(result.data!.stackAnalysis.stackSymbols, isNot(contains('A')));
      expect(result.data!.stackAnalysis.stackSymbols, isNot(contains('B')));
    });

    test('reports reachable states from initial state', () {
      final pda = _pdaAcceptsA();
      final result = PDASimulator.analyzePDA(pda);
      expect(result.isSuccess, true);
      final reachable = result.data!.reachabilityAnalysis.reachableStates
          .map((s) => s.id)
          .toSet();
      expect(reachable, contains('q0'));
      expect(reachable, contains('q1'));
    });

    test('identifies unreachable states', () {
      final pda = _pdaWithUnreachableState();
      final result = PDASimulator.analyzePDA(pda);
      expect(result.isSuccess, true);
      final unreachable = result.data!.reachabilityAnalysis.unreachableStates
          .map((s) => s.id)
          .toSet();
      expect(unreachable, contains('qU'));
    });

    test('includes execution time in result', () {
      final pda = _pdaAcceptsA();
      final result = PDASimulator.analyzePDA(pda);
      expect(result.isSuccess, true);
      expect(result.data!.executionTime, isNotNull);
    });

    test('returns error for PDA with no states', () {
      final q0 = State(
        id: 'q0',
        label: 'q0',
        position: Vector2(0, 0),
        isInitial: true,
      );
      final emptyPda = PDA(
        id: 'empty',
        name: 'Empty PDA',
        states: const {},
        transitions: const {},
        alphabet: const {},
        initialState: q0,
        acceptingStates: const {},
        stackAlphabet: {'Z'},
        initialStackSymbol: 'Z',
        created: DateTime.now(),
        modified: DateTime.now(),
        bounds: const math.Rectangle(0, 0, 400, 300),
      );
      final result = PDASimulator.analyzePDA(emptyPda);
      expect(result.isSuccess, false);
      expect(
        result.structuredError?.stableCode,
        'pda.simulation.empty-state-set',
      );
    });

    test('analyzes a^n b^n PDA correctly', () {
      final pda = _pdaAnBn(); // 3 states, 4 transitions
      final result = PDASimulator.analyzePDA(pda);
      expect(result.isSuccess, true);
      expect(result.data!.stateAnalysis.totalStates, 3);
      expect(result.data!.stateAnalysis.acceptingStates, 1);
      expect(result.data!.transitionAnalysis.totalTransitions, 4);
    });
  });

  // =========================================================================
  // PDASimulator.findAcceptedStrings
  // =========================================================================
  group('PDASimulator.findAcceptedStrings', () {
    test('finds accepted strings for simple PDA', () {
      final pda = _pdaAcceptsA();
      final result = PDASimulator.findAcceptedStrings(pda, 2);
      expect(result.isSuccess, true);
      expect(result.data!.toSet(), equals(<String>{'a'}));
    });

    test('does not include rejected strings', () {
      final pda = _pdaAcceptsA();
      final result = PDASimulator.findAcceptedStrings(pda, 2);
      expect(result.isSuccess, true);
      // 'b' is not in alphabet and 'aa' is not accepted by this PDA
      expect(result.data, isNot(contains('b')));
    });

    test('respects maxResults limit', () {
      final pda = _pdaAcceptsA();
      final result = PDASimulator.findAcceptedStrings(pda, 3, maxResults: 1);
      expect(result.isSuccess, true);
      expect(result.data!.length, lessThanOrEqualTo(1));
    });

    test('returns empty set for maxLength 0 if empty string not accepted', () {
      final pda = _pdaAcceptsA(); // only 'a' is accepted
      final result = PDASimulator.findAcceptedStrings(pda, 0);
      expect(result.isSuccess, true);
      expect(result.data, isEmpty);
    });

    test('returns results as a Set (no duplicates)', () {
      final pda = _pdaAcceptsA();
      final result = PDASimulator.findAcceptedStrings(pda, 2);
      expect(result.isSuccess, true);
      expect(result.data!.toSet(), equals(<String>{'a'}));
    });

    test('propagates acceptance failures instead of skipping candidates', () {
      final pda = invalidPdaFixture();

      final result = PDASimulator.findAcceptedStrings(pda, 0);

      expect(result.isSuccess, false);
      expect(result.error, contains('PDA acceptance failed'));
      expect(result.error, contains('pda.simulation.empty-state-set'));
    });
  });

  // =========================================================================
  // PDASimulator.findRejectedStrings
  // =========================================================================
  group('PDASimulator.findRejectedStrings', () {
    test('finds rejected strings for simple PDA', () {
      final pda = _pdaAcceptsA();
      final result = PDASimulator.findRejectedStrings(pda, 2);
      expect(result.isSuccess, true);
      // 'aa' should be rejected since PDA only accepts single 'a'
      expect(result.data, isNotEmpty);
    });

    test('does not include accepted strings', () {
      final pda = _pdaAcceptsA();
      final result = PDASimulator.findRejectedStrings(pda, 1);
      expect(result.isSuccess, true);
      expect(result.data, isNot(contains('a')));
    });

    test('respects maxResults limit', () {
      final pda = _pdaAcceptsA();
      final result = PDASimulator.findRejectedStrings(pda, 3, maxResults: 2);
      expect(result.isSuccess, true);
      expect(result.data!.length, lessThanOrEqualTo(2));
    });

    test('returns results as a Set (no duplicates)', () {
      final pda = _pdaAcceptsA();
      final result = PDASimulator.findRejectedStrings(pda, 2);
      expect(result.isSuccess, true);
      expect(result.data!.toSet(), equals(<String>{'', 'aa'}));
    });

    test('propagates acceptance failures instead of skipping candidates', () {
      final pda = invalidPdaFixture();

      final result = PDASimulator.findRejectedStrings(pda, 0);

      expect(result.isSuccess, false);
      expect(result.error, contains('PDA acceptance failed'));
      expect(result.error, contains('pda.simulation.empty-state-set'));
    });
  });
}
