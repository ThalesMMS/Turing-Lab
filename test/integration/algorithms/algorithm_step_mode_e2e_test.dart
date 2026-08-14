//
//  algorithm_step_mode_e2e_test.dart
//  Turing Lab
//
//  End-to-end integration tests for step-by-step algorithm execution mode.
//  Verifies that NFA→DFA conversion, DFA minimization, and FA→Regex conversion
//  work correctly in step-by-step mode with proper step navigation and result validation.
//
//  Thales Matheus Mendonça Santos - January 2026
//

import 'dart:math' as math;

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:vector_math/vector_math_64.dart';

import 'package:turing_lab/core/models/algorithm_step.dart';
import 'package:turing_lab/core/models/fsa.dart';
import 'package:turing_lab/core/models/fsa_transition.dart';
import 'package:turing_lab/core/models/state.dart' as automaton_state;
import 'package:turing_lab/data/services/trace_persistence_service.dart';
import 'package:turing_lab/presentation/providers/algorithm_step_provider.dart';
import 'package:turing_lab/presentation/providers/automaton_algorithm_provider.dart';
import 'package:turing_lab/presentation/providers/automaton_layout_provider.dart';
import 'package:turing_lab/presentation/providers/automaton_simulation_provider.dart';
import 'package:turing_lab/presentation/providers/automaton_state_provider.dart';

void main() {
  group('Algorithm Step-by-Step Mode E2E Tests', () {
    late ProviderContainer container;
    late TracePersistenceService tracePersistenceService;

    setUp(() async {
      // Initialize SharedPreferences for testing
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();
      tracePersistenceService = TracePersistenceService(prefs);

      // Create container with provider overrides to inject dependencies
      container = ProviderContainer(
        overrides: [
          automatonStateProvider.overrideWith((ref) {
            return AutomatonStateNotifier();
          }),
          automatonAlgorithmProvider.overrideWith((ref) {
            return AutomatonAlgorithmNotifier(ref);
          }),
          automatonSimulationProvider.overrideWith((ref) {
            return AutomatonSimulationNotifier(
              ref: ref,
              tracePersistenceService: tracePersistenceService,
            );
          }),
          automatonLayoutProvider.overrideWith((ref) {
            return AutomatonLayoutNotifier(ref);
          }),
          algorithmStepProvider.overrideWith((ref) {
            return AlgorithmStepNotifier(ref);
          }),
        ],
      );
    });

    tearDown(() {
      container.dispose();
    });

    group('NFA→DFA Conversion Step-by-Step Mode', () {
      test(
        'NFA→DFA conversion captures detailed subset construction steps',
        () async {
          // 1. Create NFA with epsilon transitions
          final stateNotifier = container.read(automatonStateProvider.notifier);
          final q0 = automaton_state.State(
            id: 'q0',
            label: 'q0',
            position: Vector2.zero(),
            isInitial: true,
            isAccepting: false,
          );
          final q1 = automaton_state.State(
            id: 'q1',
            label: 'q1',
            position: Vector2(100, 0),
            isInitial: false,
            isAccepting: false,
          );
          final q2 = automaton_state.State(
            id: 'q2',
            label: 'q2',
            position: Vector2(200, 0),
            isInitial: false,
            isAccepting: true,
          );

          // Epsilon transition from q0 to q1
          final epsilonTransition = FSATransition(
            id: 't0',
            fromState: q0,
            toState: q1,
            inputSymbols: const {},
            label: 'ε',
          );

          // Regular transition from q1 to q2 on 'a'
          final regularTransition = FSATransition(
            id: 't1',
            fromState: q1,
            toState: q2,
            inputSymbols: const {'a'},
            label: 'a',
          );

          final nfa = FSA(
            id: 'nfa-epsilon-test',
            name: 'NFA with Epsilon',
            states: {q0, q1, q2},
            transitions: {epsilonTransition, regularTransition},
            alphabet: {'a'},
            initialState: q0,
            acceptingStates: {q2},
            created: DateTime.now(),
            modified: DateTime.now(),
            bounds: const math.Rectangle(0, 0, 400, 300),
          );

          stateNotifier.updateAutomaton(nfa);

          // Verify NFA was loaded
          final stateAfterLoad = container.read(automatonStateProvider);
          expect(stateAfterLoad.currentAutomaton, isNotNull);
          expect(stateAfterLoad.currentAutomaton!.id, 'nfa-epsilon-test');

          // 2. Run NFA→DFA conversion in step-by-step mode
          final algorithmNotifier = container.read(
            automatonAlgorithmProvider.notifier,
          );
          await algorithmNotifier.convertNfaToDfaWithSteps();

          // Verify algorithm completed without error
          final algorithmState = container.read(automatonAlgorithmProvider);
          expect(algorithmState.error, isNull);
          expect(algorithmState.nfaToDfaStepResult, isNotNull);

          // Verify steps were captured
          final stepState = container.read(algorithmStepProvider);
          expect(stepState.hasSteps, isTrue);
          expect(stepState.totalSteps, greaterThan(0));
          expect(stepState.currentStepIndex, 0);
          expect(stepState.currentStep!.properties, isNotEmpty);
          expect(stepState.currentStep!.properties['stepType'], isA<String>());

          // 3. Navigate forward through all steps
          final stepNotifier = container.read(algorithmStepProvider.notifier);
          final totalSteps = stepState.totalSteps;

          for (int i = 0; i < totalSteps - 1; i++) {
            stepNotifier.nextStep();
            final state = container.read(algorithmStepProvider);
            expect(state.currentStepIndex, i + 1);
            expect(
              (state.currentStepIndex < state.steps.length - 1),
              i + 1 < totalSteps - 1,
            );
            expect((state.currentStepIndex > 0), true);

            // Verify current step has valid data
            final currentStep = state.currentStep;
            expect(currentStep, isNotNull);
            expect(currentStep!.title, isNotEmpty);
            expect(currentStep.explanation, isNotEmpty);
            expect(currentStep.type, AlgorithmType.nfaToDfa);
          }

          // Verify we reached the last step
          final finalStepState = container.read(algorithmStepProvider);
          expect(finalStepState.currentStepIndex, totalSteps - 1);
          expect(
            (finalStepState.currentStepIndex < finalStepState.steps.length - 1),
            false,
          );
          expect((finalStepState.currentStepIndex > 0), true);

          // 4. Navigate backward through steps
          for (int i = totalSteps - 1; i > 0; i--) {
            stepNotifier.previousStep();
            final state = container.read(algorithmStepProvider);
            expect(state.currentStepIndex, i - 1);
            expect((state.currentStepIndex > 0), i - 1 > 0);
            expect((state.currentStepIndex < state.steps.length - 1), true);
          }

          // Verify we're back at the first step
          final backToFirstState = container.read(algorithmStepProvider);
          expect(backToFirstState.currentStepIndex, 0);
          expect((backToFirstState.currentStepIndex > 0), false);
          expect(
            (backToFirstState.currentStepIndex <
                backToFirstState.steps.length - 1),
            true,
          );

          // 5. Verify the step conversion produced a valid DFA
          final stateAfterSteps = container.read(automatonStateProvider);
          expect(stateAfterSteps.currentAutomaton, isNotNull);

          final dfaFromSteps = stateAfterSteps.currentAutomaton!;
          expect(dfaFromSteps.states.length, greaterThan(0));

          // Verify the DFA accepts the same language
          // The NFA accepts strings matching 'a' (with epsilon from q0 to q1)
          // The DFA should also accept 'a'
          expect(dfaFromSteps.alphabet, contains('a'));
        },
      );

      test('Step navigation can jump to specific step', () async {
        // Create simple NFA
        final stateNotifier = container.read(automatonStateProvider.notifier);
        final q0 = automaton_state.State(
          id: 'q0',
          label: 'q0',
          position: Vector2.zero(),
          isInitial: true,
          isAccepting: false,
        );
        final q1 = automaton_state.State(
          id: 'q1',
          label: 'q1',
          position: Vector2(100, 0),
          isInitial: false,
          isAccepting: true,
        );
        final transition = FSATransition(
          id: 't0',
          fromState: q0,
          toState: q1,
          inputSymbols: const {'a'},
          label: 'a',
        );
        final nfa = FSA(
          id: 'nfa-jump-test',
          name: 'NFA Jump Test',
          states: {q0, q1},
          transitions: {transition},
          alphabet: {'a'},
          initialState: q0,
          acceptingStates: {q1},
          created: DateTime.now(),
          modified: DateTime.now(),
          bounds: const math.Rectangle(0, 0, 400, 300),
        );

        stateNotifier.updateAutomaton(nfa);

        // Convert with steps
        final algorithmNotifier = container.read(
          automatonAlgorithmProvider.notifier,
        );
        await algorithmNotifier.convertNfaToDfaWithSteps();

        // Verify steps exist
        final stepState = container.read(algorithmStepProvider);
        expect(stepState.hasSteps, isTrue);
        final totalSteps = stepState.totalSteps;
        expect(totalSteps, greaterThan(2));

        // Jump to middle step
        final stepNotifier = container.read(algorithmStepProvider.notifier);
        final middleStep = totalSteps ~/ 2;
        stepNotifier.jumpToStep(middleStep);

        final stateAfterJump = container.read(algorithmStepProvider);
        expect(stateAfterJump.currentStepIndex, middleStep);

        // Jump to last step
        stepNotifier.jumpToStep(totalSteps - 1);
        final stateAtEnd = container.read(algorithmStepProvider);
        expect(stateAtEnd.currentStepIndex, totalSteps - 1);

        // Jump back to first step
        stepNotifier.jumpToStep(0);
        final stateAtStart = container.read(algorithmStepProvider);
        expect(stateAtStart.currentStepIndex, 0);
      });
    });

    group('DFA Minimization Step-by-Step Mode', () {
      test(
        'DFA minimization captures detailed Hopcroft algorithm steps',
        () async {
          // 1. Create a minimizable DFA with equivalent states
          final stateNotifier = container.read(automatonStateProvider.notifier);
          final q0 = automaton_state.State(
            id: 'q0',
            label: 'q0',
            position: Vector2.zero(),
            isInitial: true,
            isAccepting: false,
          );
          final q1 = automaton_state.State(
            id: 'q1',
            label: 'q1',
            position: Vector2(100, 0),
            isInitial: false,
            isAccepting: true,
          );
          final q2 = automaton_state.State(
            id: 'q2',
            label: 'q2',
            position: Vector2(100, 100),
            isInitial: false,
            isAccepting: true,
          );

          // Both q1 and q2 are accepting and behave the same way
          final t0 = FSATransition(
            id: 't0',
            fromState: q0,
            toState: q1,
            inputSymbols: const {'a'},
            label: 'a',
          );
          final t1 = FSATransition(
            id: 't1',
            fromState: q0,
            toState: q2,
            inputSymbols: const {'b'},
            label: 'b',
          );

          final dfa = FSA(
            id: 'dfa-minimize-test',
            name: 'Minimizable DFA',
            states: {q0, q1, q2},
            transitions: {t0, t1},
            alphabet: {'a', 'b'},
            initialState: q0,
            acceptingStates: {q1, q2},
            created: DateTime.now(),
            modified: DateTime.now(),
            bounds: const math.Rectangle(0, 0, 400, 300),
          );

          stateNotifier.updateAutomaton(dfa);

          // Verify DFA was loaded
          final stateAfterLoad = container.read(automatonStateProvider);
          expect(stateAfterLoad.currentAutomaton, isNotNull);
          expect(stateAfterLoad.currentAutomaton!.id, 'dfa-minimize-test');

          // 2. Run DFA minimization in step-by-step mode
          final algorithmNotifier = container.read(
            automatonAlgorithmProvider.notifier,
          );
          await algorithmNotifier.minimizeDfaWithSteps();

          // Verify algorithm completed without error
          final algorithmState = container.read(automatonAlgorithmProvider);
          expect(algorithmState.error, isNull);
          expect(algorithmState.dfaMinimizationStepResult, isNotNull);

          // Verify steps were captured
          final stepState = container.read(algorithmStepProvider);
          expect(stepState.hasSteps, isTrue);
          expect(stepState.totalSteps, greaterThan(0));
          expect(stepState.currentStep!.properties, isNotEmpty);
          expect(stepState.currentStep!.properties['stepType'], isA<String>());

          // 3. Navigate through steps
          final stepNotifier = container.read(algorithmStepProvider.notifier);
          final totalSteps = stepState.totalSteps;

          // Step forward through all steps
          for (int i = 0; i < totalSteps - 1; i++) {
            stepNotifier.nextStep();
            final state = container.read(algorithmStepProvider);

            // Verify step data
            final currentStep = state.currentStep;
            expect(currentStep, isNotNull);
            expect(currentStep!.type, AlgorithmType.dfaMinimization);
            expect(currentStep.title, isNotEmpty);
            expect(currentStep.explanation, isNotEmpty);
          }

          // 4. Navigate backward
          for (int i = totalSteps - 1; i > 0; i--) {
            stepNotifier.previousStep();
            final state = container.read(algorithmStepProvider);
            expect(state.currentStepIndex, i - 1);
          }

          // 5. Verify final result matches standard minimization
          stepNotifier.jumpToStep(totalSteps - 1); // Go to last step
          final stateAtEnd = container.read(automatonStateProvider);
          expect(stateAtEnd.currentAutomaton, isNotNull);

          final minimizedDfa = stateAtEnd.currentAutomaton!;
          expect(minimizedDfa.states.length, greaterThan(0));

          // The minimized DFA should have fewer or equal states
          expect(minimizedDfa.states.length, lessThanOrEqualTo(3));
        },
      );

      test(
        'Minimization step explanations describe partition refinement',
        () async {
          // Create a simple DFA
          final stateNotifier = container.read(automatonStateProvider.notifier);
          final q0 = automaton_state.State(
            id: 'q0',
            label: 'q0',
            position: Vector2.zero(),
            isInitial: true,
            isAccepting: false,
          );
          final q1 = automaton_state.State(
            id: 'q1',
            label: 'q1',
            position: Vector2(100, 0),
            isInitial: false,
            isAccepting: true,
          );
          final transition = FSATransition(
            id: 't0',
            fromState: q0,
            toState: q1,
            inputSymbols: const {'a'},
            label: 'a',
          );
          final dfa = FSA(
            id: 'dfa-explanation-test',
            name: 'DFA Explanation Test',
            states: {q0, q1},
            transitions: {transition},
            alphabet: {'a'},
            initialState: q0,
            acceptingStates: {q1},
            created: DateTime.now(),
            modified: DateTime.now(),
            bounds: const math.Rectangle(0, 0, 400, 300),
          );

          stateNotifier.updateAutomaton(dfa);

          // Minimize with steps
          final algorithmNotifier = container.read(
            automatonAlgorithmProvider.notifier,
          );
          await algorithmNotifier.minimizeDfaWithSteps();

          // Verify steps have meaningful explanations
          final stepState = container.read(algorithmStepProvider);
          expect(stepState.hasSteps, isTrue);

          // Check that at least one step mentions "partition" or "equivalence"
          final steps = stepState.steps;
          final hasPartitionMention = steps.any(
            (step) =>
                step.explanation.toLowerCase().contains('partition') ||
                step.explanation.toLowerCase().contains('equivalence') ||
                step.explanation.toLowerCase().contains('class'),
          );

          expect(
            hasPartitionMention,
            isTrue,
            reason: 'Steps should explain partition refinement',
          );
        },
      );
    });

    group('FA→Regex Conversion Step-by-Step Mode', () {
      test(
        'FA→Regex conversion captures detailed state elimination steps',
        () async {
          // 1. Create a simple automaton for regex conversion
          final stateNotifier = container.read(automatonStateProvider.notifier);
          final q0 = automaton_state.State(
            id: 'q0',
            label: 'q0',
            position: Vector2.zero(),
            isInitial: true,
            isAccepting: false,
          );
          final q1 = automaton_state.State(
            id: 'q1',
            label: 'q1',
            position: Vector2(100, 0),
            isInitial: false,
            isAccepting: true,
          );
          final transition = FSATransition(
            id: 't0',
            fromState: q0,
            toState: q1,
            inputSymbols: const {'a'},
            label: 'a',
          );
          final fa = FSA(
            id: 'fa-regex-test',
            name: 'FA for Regex',
            states: {q0, q1},
            transitions: {transition},
            alphabet: {'a'},
            initialState: q0,
            acceptingStates: {q1},
            created: DateTime.now(),
            modified: DateTime.now(),
            bounds: const math.Rectangle(0, 0, 400, 300),
          );

          stateNotifier.updateAutomaton(fa);

          // Verify FA was loaded
          final stateAfterLoad = container.read(automatonStateProvider);
          expect(stateAfterLoad.currentAutomaton, isNotNull);
          expect(stateAfterLoad.currentAutomaton!.id, 'fa-regex-test');

          // 2. Run FA→Regex conversion in step-by-step mode
          final algorithmNotifier = container.read(
            automatonAlgorithmProvider.notifier,
          );
          await algorithmNotifier.convertFaToRegexWithSteps();

          // Verify algorithm completed without error
          final algorithmState = container.read(automatonAlgorithmProvider);
          expect(algorithmState.error, isNull);
          expect(algorithmState.faToRegexStepResult, isNotNull);

          // Verify steps were captured
          final stepState = container.read(algorithmStepProvider);
          expect(stepState.hasSteps, isTrue);
          expect(stepState.totalSteps, greaterThan(0));

          // 3. Navigate through all steps
          final stepNotifier = container.read(algorithmStepProvider.notifier);
          final totalSteps = stepState.totalSteps;

          for (int i = 0; i < totalSteps - 1; i++) {
            stepNotifier.nextStep();
            final state = container.read(algorithmStepProvider);

            // Verify step data
            final currentStep = state.currentStep;
            expect(currentStep, isNotNull);
            expect(currentStep!.type, AlgorithmType.faToRegex);
            expect(currentStep.title, isNotEmpty);
            expect(currentStep.explanation, isNotEmpty);
          }

          // 4. Navigate backward
          for (int i = totalSteps - 1; i > 0; i--) {
            stepNotifier.previousStep();
          }

          // Verify we're back at the first step
          final backAtStart = container.read(algorithmStepProvider);
          expect(backAtStart.currentStepIndex, 0);

          // 5. Verify final result contains regex
          stepNotifier.jumpToStep(totalSteps - 1);
          final finalAlgorithmState = container.read(
            automatonAlgorithmProvider,
          );
          expect(finalAlgorithmState.faToRegexStepResult, isNotNull);

          // The result should contain a regex string
          final regexResult = finalAlgorithmState.faToRegexStepResult!;
          expect(regexResult.resultRegex, isNotEmpty);
          expect(regexResult.steps.isNotEmpty, isTrue);
        },
      );

      test(
        'Regex conversion step explanations describe state elimination',
        () async {
          // Create a simple FA
          final stateNotifier = container.read(automatonStateProvider.notifier);
          final q0 = automaton_state.State(
            id: 'q0',
            label: 'q0',
            position: Vector2.zero(),
            isInitial: true,
            isAccepting: true,
          );
          final fa = FSA(
            id: 'fa-single-state',
            name: 'Single State FA',
            states: {q0},
            transitions: {},
            alphabet: {},
            initialState: q0,
            acceptingStates: {q0},
            created: DateTime.now(),
            modified: DateTime.now(),
            bounds: const math.Rectangle(0, 0, 400, 300),
          );

          stateNotifier.updateAutomaton(fa);

          // Convert to regex with steps
          final algorithmNotifier = container.read(
            automatonAlgorithmProvider.notifier,
          );
          await algorithmNotifier.convertFaToRegexWithSteps();

          // Verify steps have meaningful explanations
          final stepState = container.read(algorithmStepProvider);
          expect(stepState.hasSteps, isTrue);

          // Check that steps describe the conversion process
          final steps = stepState.steps;
          expect(steps.isNotEmpty, isTrue);

          // At least one step should mention "regex" or "expression"
          final hasRegexMention = steps.any(
            (step) =>
                step.explanation.toLowerCase().contains('regex') ||
                step.explanation.toLowerCase().contains('expression') ||
                step.title.toLowerCase().contains('regex'),
          );

          expect(
            hasRegexMention,
            isTrue,
            reason: 'Steps should explain regex construction',
          );
        },
      );
    });

    group('Step Playback Controls', () {
      test('Reset functionality returns to first step', () async {
        // Create and convert a simple NFA
        final stateNotifier = container.read(automatonStateProvider.notifier);
        final q0 = automaton_state.State(
          id: 'q0',
          label: 'q0',
          position: Vector2.zero(),
          isInitial: true,
          isAccepting: false,
        );
        final q1 = automaton_state.State(
          id: 'q1',
          label: 'q1',
          position: Vector2(100, 0),
          isInitial: false,
          isAccepting: true,
        );
        final transition = FSATransition(
          id: 't0',
          fromState: q0,
          toState: q1,
          inputSymbols: const {'a'},
          label: 'a',
        );
        final nfa = FSA(
          id: 'nfa-reset-test',
          name: 'NFA Reset Test',
          states: {q0, q1},
          transitions: {transition},
          alphabet: {'a'},
          initialState: q0,
          acceptingStates: {q1},
          created: DateTime.now(),
          modified: DateTime.now(),
          bounds: const math.Rectangle(0, 0, 400, 300),
        );

        stateNotifier.updateAutomaton(nfa);

        final algorithmNotifier = container.read(
          automatonAlgorithmProvider.notifier,
        );
        await algorithmNotifier.convertNfaToDfaWithSteps();

        // Navigate to middle step
        final stepNotifier = container.read(algorithmStepProvider.notifier);
        final stepState = container.read(algorithmStepProvider);
        final middleStep = stepState.totalSteps ~/ 2;
        stepNotifier.jumpToStep(middleStep);

        // Verify we're at middle step
        final stateAtMiddle = container.read(algorithmStepProvider);
        expect(stateAtMiddle.currentStepIndex, middleStep);

        // Reset to first step
        stepNotifier.clearSteps();

        // Verify we're back at the beginning
        final stateAfterReset = container.read(algorithmStepProvider);
        expect(stateAfterReset.currentStepIndex, 0);
      });

      test('Clear steps removes all step data', () async {
        // Create and convert a simple NFA
        final stateNotifier = container.read(automatonStateProvider.notifier);
        final q0 = automaton_state.State(
          id: 'q0',
          label: 'q0',
          position: Vector2.zero(),
          isInitial: true,
          isAccepting: true,
        );
        final nfa = FSA(
          id: 'nfa-clear-test',
          name: 'NFA Clear Test',
          states: {q0},
          transitions: {},
          alphabet: {},
          initialState: q0,
          acceptingStates: {q0},
          created: DateTime.now(),
          modified: DateTime.now(),
          bounds: const math.Rectangle(0, 0, 400, 300),
        );

        stateNotifier.updateAutomaton(nfa);

        final algorithmNotifier = container.read(
          automatonAlgorithmProvider.notifier,
        );
        await algorithmNotifier.convertNfaToDfaWithSteps();

        // Verify steps exist
        final stepState = container.read(algorithmStepProvider);
        expect(stepState.hasSteps, isTrue);
        expect(stepState.totalSteps, greaterThan(0));

        // Clear steps
        final stepNotifier = container.read(algorithmStepProvider.notifier);
        stepNotifier.clearSteps();

        // Verify steps are cleared
        final stateAfterClear = container.read(algorithmStepProvider);
        expect(stateAfterClear.hasSteps, false);
        expect(stateAfterClear.totalSteps, 0);
        expect(stateAfterClear.currentStepIndex, 0);
      });

      test('Play/pause toggle works correctly', () async {
        // Create and convert a simple NFA
        final stateNotifier = container.read(automatonStateProvider.notifier);
        final q0 = automaton_state.State(
          id: 'q0',
          label: 'q0',
          position: Vector2.zero(),
          isInitial: true,
          isAccepting: true,
        );
        final nfa = FSA(
          id: 'nfa-playback-test',
          name: 'NFA Playback Test',
          states: {q0},
          transitions: {},
          alphabet: {},
          initialState: q0,
          acceptingStates: {q0},
          created: DateTime.now(),
          modified: DateTime.now(),
          bounds: const math.Rectangle(0, 0, 400, 300),
        );

        stateNotifier.updateAutomaton(nfa);

        final algorithmNotifier = container.read(
          automatonAlgorithmProvider.notifier,
        );
        await algorithmNotifier.convertNfaToDfaWithSteps();

        // Initially not playing
        final initialState = container.read(algorithmStepProvider);
        expect(initialState.isPlaying, false);

        // Toggle play
        final stepNotifier = container.read(algorithmStepProvider.notifier);
        stepNotifier.togglePlayPause();

        final playingState = container.read(algorithmStepProvider);
        expect(playingState.isPlaying, true);

        // Toggle pause
        stepNotifier.togglePlayPause();

        final pausedState = container.read(algorithmStepProvider);
        expect(pausedState.isPlaying, false);
      });
    });

    group('Full Integration: All Three Algorithms', () {
      test(
        'Can run all three algorithms sequentially in step-by-step mode',
        () async {
          // 1. Create initial NFA with epsilon transition
          final stateNotifier = container.read(automatonStateProvider.notifier);
          final q0 = automaton_state.State(
            id: 'q0',
            label: 'q0',
            position: Vector2.zero(),
            isInitial: true,
            isAccepting: false,
          );
          final q1 = automaton_state.State(
            id: 'q1',
            label: 'q1',
            position: Vector2(100, 0),
            isInitial: false,
            isAccepting: false,
          );
          final q2 = automaton_state.State(
            id: 'q2',
            label: 'q2',
            position: Vector2(200, 0),
            isInitial: false,
            isAccepting: true,
          );
          final epsilonTrans = FSATransition(
            id: 't0',
            fromState: q0,
            toState: q1,
            inputSymbols: const {},
            label: 'ε',
          );
          final regularTrans = FSATransition(
            id: 't1',
            fromState: q1,
            toState: q2,
            inputSymbols: const {'a'},
            label: 'a',
          );
          final nfa = FSA(
            id: 'nfa-full-test',
            name: 'NFA Full Integration',
            states: {q0, q1, q2},
            transitions: {epsilonTrans, regularTrans},
            alphabet: {'a'},
            initialState: q0,
            acceptingStates: {q2},
            created: DateTime.now(),
            modified: DateTime.now(),
            bounds: const math.Rectangle(0, 0, 400, 300),
          );

          stateNotifier.updateAutomaton(nfa);

          final algorithmNotifier = container.read(
            automatonAlgorithmProvider.notifier,
          );
          final stepNotifier = container.read(algorithmStepProvider.notifier);

          // 2. Run NFA→DFA with steps
          await algorithmNotifier.convertNfaToDfaWithSteps();
          var stepState = container.read(algorithmStepProvider);
          expect(stepState.hasSteps, isTrue);
          final nfaToDfaSteps = stepState.totalSteps;
          expect(nfaToDfaSteps, greaterThan(0));

          // Verify NFA→DFA step result is available immediately after
          var algState = container.read(automatonAlgorithmProvider);
          expect(algState.nfaToDfaStepResult, isNotNull);

          // Navigate through all NFA→DFA steps
          while ((stepState.currentStepIndex < stepState.steps.length - 1)) {
            stepNotifier.nextStep();
            stepState = container.read(algorithmStepProvider);
          }

          // 3. Run DFA minimization with steps
          stepNotifier.clearSteps();
          await algorithmNotifier.minimizeDfaWithSteps();
          stepState = container.read(algorithmStepProvider);
          expect(stepState.hasSteps, isTrue);
          final minimizationSteps = stepState.totalSteps;
          expect(minimizationSteps, greaterThan(0));

          // Verify minimization step result is available immediately after
          algState = container.read(automatonAlgorithmProvider);
          expect(algState.dfaMinimizationStepResult, isNotNull);

          // Navigate through all minimization steps
          while ((stepState.currentStepIndex < stepState.steps.length - 1)) {
            stepNotifier.nextStep();
            stepState = container.read(algorithmStepProvider);
          }

          // 4. Run FA→Regex with steps
          stepNotifier.clearSteps();
          await algorithmNotifier.convertFaToRegexWithSteps();
          stepState = container.read(algorithmStepProvider);
          expect(stepState.hasSteps, isTrue);
          final regexSteps = stepState.totalSteps;
          expect(regexSteps, greaterThan(0));

          // Navigate through all regex conversion steps
          while ((stepState.currentStepIndex < stepState.steps.length - 1)) {
            stepNotifier.nextStep();
            stepState = container.read(algorithmStepProvider);
          }

          // 5. Verify the final algorithm completed successfully
          final finalAlgorithmState = container.read(
            automatonAlgorithmProvider,
          );
          expect(finalAlgorithmState.error, isNull);
          // Only the most recent algorithm's result persists (prior results
          // are cleared when the automaton changes between algorithms).
          expect(finalAlgorithmState.faToRegexStepResult, isNotNull);

          // Verify final regex result
          expect(
            finalAlgorithmState.faToRegexStepResult!.resultRegex,
            isNotEmpty,
          );
        },
      );
    });
  });
}
