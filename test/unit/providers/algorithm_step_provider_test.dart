//
//  algorithm_step_provider_test.dart
//  Turing Lab
//
//  Unit tests for AlgorithmStepProvider, verifying step navigation,
//  history panel visibility, and state management.
//
//  Thales Matheus Mendonça Santos - January 2026
//

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:turing_lab/core/models/algorithm_step.dart';
import 'package:turing_lab/presentation/providers/algorithm_step_provider.dart';

void main() {
  group('AlgorithmStepProvider', () {
    late ProviderContainer container;

    setUp(() {
      container = ProviderContainer();
    });

    tearDown(() {
      container.dispose();
    });

    group('history', () {
      test('initial state has history panel hidden', () {
        final state = container.read(algorithmStepProvider);
        expect(state.isHistoryVisible, false);
      });

      test('toggleHistory() shows history panel', () {
        final notifier = container.read(algorithmStepProvider.notifier);

        // Initially hidden
        expect(container.read(algorithmStepProvider).isHistoryVisible, false);

        // Toggle to show
        notifier.toggleHistory();
        expect(container.read(algorithmStepProvider).isHistoryVisible, true);
      });

      test('toggleHistory() can hide history panel after showing', () {
        final notifier = container.read(algorithmStepProvider.notifier);

        // Show history
        notifier.toggleHistory();
        expect(container.read(algorithmStepProvider).isHistoryVisible, true);

        // Hide history
        notifier.toggleHistory();
        expect(container.read(algorithmStepProvider).isHistoryVisible, false);
      });

      test('toggleHistory() can be called multiple times', () {
        final notifier = container.read(algorithmStepProvider.notifier);

        // Toggle multiple times
        for (int i = 0; i < 5; i++) {
          notifier.toggleHistory();
          expect(
            container.read(algorithmStepProvider).isHistoryVisible,
            i % 2 == 0, // Odd iterations = visible, even = hidden
          );
        }
      });

      test('copyWith preserves isHistoryVisible when not specified', () {
        const state = AlgorithmStepState(isHistoryVisible: true);
        final newState = state.copyWith(currentStepIndex: 1);

        expect(newState.isHistoryVisible, true);
        expect(newState.currentStepIndex, 1);
      });

      test('copyWith can update isHistoryVisible', () {
        const state = AlgorithmStepState(isHistoryVisible: false);
        final newState = state.copyWith(isHistoryVisible: true);

        expect(newState.isHistoryVisible, true);
      });

      test('clear() resets history panel visibility', () {
        final notifier = container.read(algorithmStepProvider.notifier);

        // Show history and add steps
        notifier.toggleHistory();
        notifier.initializeSteps([
          AlgorithmStep(
            id: 'step1',
            stepNumber: 0,
            title: 'Step 1',
            explanation: 'First step',
            type: AlgorithmType.nfaToDfa,
            timestamp: DateTime(2024, 1, 1),
          ),
        ]);

        expect(container.read(algorithmStepProvider).isHistoryVisible, true);
        expect(container.read(algorithmStepProvider).hasSteps, true);

        // Clear all
        notifier.clearSteps();

        expect(container.read(algorithmStepProvider).isHistoryVisible, false);
        expect(container.read(algorithmStepProvider).hasSteps, false);
      });

      test('history visibility persists through step navigation', () {
        final notifier = container.read(algorithmStepProvider.notifier);

        // Setup steps
        notifier.initializeSteps([
          AlgorithmStep(
            id: 'step1',
            stepNumber: 0,
            title: 'Step 1',
            explanation: 'First step',
            type: AlgorithmType.nfaToDfa,
            timestamp: DateTime(2024, 1, 1),
          ),
          AlgorithmStep(
            id: 'step2',
            stepNumber: 1,
            title: 'Step 2',
            explanation: 'Second step',
            type: AlgorithmType.nfaToDfa,
            timestamp: DateTime(2024, 1, 1),
          ),
        ]);

        // Show history
        notifier.toggleHistory();
        expect(container.read(algorithmStepProvider).isHistoryVisible, true);

        // Navigate steps
        notifier.nextStep();
        expect(container.read(algorithmStepProvider).isHistoryVisible, true);
        expect(container.read(algorithmStepProvider).currentStepIndex, 1);

        notifier.previousStep();
        expect(container.read(algorithmStepProvider).isHistoryVisible, true);
        expect(container.read(algorithmStepProvider).currentStepIndex, 0);
      });
    });

    group('basic functionality', () {
      test('initial state has no steps', () {
        final state = container.read(algorithmStepProvider);
        expect(state.steps, isEmpty);
        expect(state.currentStepIndex, 0);
        expect(state.isPlaying, false);
        expect(state.hasSteps, false);
      });

      test('initializeSteps sets up steps correctly', () {
        final notifier = container.read(algorithmStepProvider.notifier);
        final steps = [
          AlgorithmStep(
            id: 'step1',
            stepNumber: 0,
            title: 'Step 1',
            explanation: 'First step',
            type: AlgorithmType.nfaToDfa,
            timestamp: DateTime(2024, 1, 1),
          ),
          AlgorithmStep(
            id: 'step2',
            stepNumber: 1,
            title: 'Step 2',
            explanation: 'Second step',
            type: AlgorithmType.nfaToDfa,
            timestamp: DateTime(2024, 1, 1),
          ),
        ];

        notifier.initializeSteps(steps);

        final state = container.read(algorithmStepProvider);
        expect(state.steps.length, 2);
        expect(state.currentStepIndex, 0);
        expect(state.hasSteps, true);
      });

      test('nextStep advances to next step', () {
        final notifier = container.read(algorithmStepProvider.notifier);
        notifier.initializeSteps([
          AlgorithmStep(
            id: 'step1',
            stepNumber: 0,
            title: 'Step 1',
            explanation: 'First step',
            type: AlgorithmType.nfaToDfa,
            timestamp: DateTime(2024, 1, 1),
          ),
          AlgorithmStep(
            id: 'step2',
            stepNumber: 1,
            title: 'Step 2',
            explanation: 'Second step',
            type: AlgorithmType.nfaToDfa,
            timestamp: DateTime(2024, 1, 1),
          ),
        ]);

        expect(container.read(algorithmStepProvider).currentStepIndex, 0);

        notifier.nextStep();
        expect(container.read(algorithmStepProvider).currentStepIndex, 1);
      });

      test('previousStep goes back to previous step', () {
        final notifier = container.read(algorithmStepProvider.notifier);
        notifier.initializeSteps([
          AlgorithmStep(
            id: 'step1',
            stepNumber: 0,
            title: 'Step 1',
            explanation: 'First step',
            type: AlgorithmType.nfaToDfa,
            timestamp: DateTime(2024, 1, 1),
          ),
          AlgorithmStep(
            id: 'step2',
            stepNumber: 1,
            title: 'Step 2',
            explanation: 'Second step',
            type: AlgorithmType.nfaToDfa,
            timestamp: DateTime(2024, 1, 1),
          ),
        ]);

        notifier.nextStep();
        expect(container.read(algorithmStepProvider).currentStepIndex, 1);

        notifier.previousStep();
        expect(container.read(algorithmStepProvider).currentStepIndex, 0);
      });
    });
  });
}
