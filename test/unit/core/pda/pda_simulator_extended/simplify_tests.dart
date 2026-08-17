part of '../pda_simulator_extended_test.dart';

void _runPdaSimplifyTests() {
  group('PDASimulator.simplify', () {
    test('returns success for a valid, already-minimal PDA', () {
      final pda = _pdaAcceptsA();
      final result = PDASimulator.simplify(pda);
      expect(result.isSuccess, true);
    });

    test('simplified PDA has at least the initial state', () {
      final pda = _pdaAcceptsA();
      final result = PDASimulator.simplify(pda);
      expect(result.isSuccess, true);
      expect(result.data!.minimizedPda.states, isNotEmpty);
      expect(result.data!.minimizedPda.initialState, isNotNull);
    });

    test('simplified PDA preserves at least one accepting state', () {
      final pda = _pdaAcceptsA();
      final result = PDASimulator.simplify(pda);
      expect(result.isSuccess, true);
      expect(result.data!.minimizedPda.acceptingStates, isNotEmpty);
    });

    test('removes unreachable states from PDA', () {
      final pda = _pdaWithUnreachableState();
      final result = PDASimulator.simplify(pda);
      expect(result.isSuccess, true);
      final stateIds =
          result.data!.minimizedPda.states.map((s) => s.id).toSet();
      expect(stateIds, isNot(contains('qU')));
    });

    test('reports removed states in summary', () {
      final pda = _pdaWithUnreachableState();
      final result = PDASimulator.simplify(pda);
      expect(result.isSuccess, true);
      final removedIds = result.data!.removedStates.map((s) => s.id).toSet();
      expect(removedIds, contains('qU'));
    });

    test('changed flag is true when states were removed', () {
      final pda = _pdaWithUnreachableState();
      final result = PDASimulator.simplify(pda);
      expect(result.isSuccess, true);
      expect(result.data!.changed, true);
    });

    test('treats FSA transitions as productive reachability edges', () {
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
      final transition = FSATransition(
        id: 'f0',
        fromState: q0,
        toState: q1,
        inputSymbols: const {'a'},
        label: 'a',
      );
      final pda = PDA(
        id: 'mixed',
        name: 'Mixed PDA',
        states: {q0, q1},
        transitions: <Transition>{transition},
        alphabet: const {'a'},
        initialState: q0,
        acceptingStates: {q1},
        created: DateTime.now(),
        modified: DateTime.now(),
        bounds: const math.Rectangle(0, 0, 400, 300),
        stackAlphabet: const {'Z'},
      );

      final result = PDASimulator.simplify(pda);

      expect(result.isSuccess, true);
      expect(result.data!.minimizedPda.initialState?.id, 'q0');
      expect(result.data!.minimizedPda.transitions, hasLength(1));
      expect(
        result.data!.minimizedPda.transitions.single,
        isA<FSATransition>(),
      );
    });

    test('returns failure for empty PDA', () {
      final q0 = State(
        id: 'q0',
        label: 'q0',
        position: Vector2(0, 0),
        isInitial: true,
      );
      final emptyPda = PDA(
        id: 'empty',
        name: 'Empty',
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
      final result = PDASimulator.simplify(emptyPda);
      expect(result.isSuccess, false);
    });

    test('returns failure when PDA has no accepting states', () {
      final q0 = State(
        id: 'q0',
        label: 'q0',
        position: Vector2(0, 0),
        isInitial: true,
      );
      final noAcceptingPda = PDA(
        id: 'no_accept',
        name: 'No accepting states',
        states: {q0},
        transitions: const {},
        alphabet: {'a'},
        initialState: q0,
        acceptingStates: const {},
        stackAlphabet: {'Z'},
        initialStackSymbol: 'Z',
        created: DateTime.now(),
        modified: DateTime.now(),
        bounds: const math.Rectangle(0, 0, 400, 300),
      );
      final result = PDASimulator.simplify(noAcceptingPda);
      expect(result.isSuccess, false);
    });

    test('returns failure when no initial state is defined', () {
      final q0 = State(
        id: 'q0',
        label: 'q0',
        position: Vector2(0, 0),
        isAccepting: true,
      );
      final noInitPda = PDA(
        id: 'no_init',
        name: 'No initial state',
        states: {q0},
        transitions: const {},
        alphabet: {'a'},
        acceptingStates: {q0},
        stackAlphabet: {'Z'},
        initialStackSymbol: 'Z',
        created: DateTime.now(),
        modified: DateTime.now(),
        bounds: const math.Rectangle(0, 0, 400, 300),
      );
      final result = PDASimulator.simplify(noInitPda);
      expect(result.isSuccess, false);
    });
  });

  // =========================================================================
  // PDASimulator.accepts and rejects
  // =========================================================================
}
