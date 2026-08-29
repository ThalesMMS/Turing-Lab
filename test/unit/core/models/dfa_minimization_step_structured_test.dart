import 'package:flutter_test/flutter_test.dart';
import 'package:vector_math/vector_math_64.dart';

import 'package:turing_lab/core/messages/structured_message.dart';
import 'package:turing_lab/core/models/dfa_minimization_step.dart';
import 'package:turing_lab/core/models/dfa_minimization_step_messages.dart';
import 'package:turing_lab/core/models/state.dart';

void main() {
  State state(String id) => State(id: id, label: id, position: Vector2.zero());

  final q0 = state('q0');
  final q1 = state('q1');
  final q2 = state('q2');

  test('all educational steps carry locale-neutral title and explanation', () {
    final steps = [
      DFAMinimizationStep.initialPartition(
        id: 'initial',
        stepNumber: 1,
        acceptingStates: {q1},
        nonAcceptingStates: {q0},
      ),
      DFAMinimizationStep.removeUnreachable(
        id: 'unreachable',
        stepNumber: 2,
        unreachableStates: {q2},
        reachableStates: {q0, q1},
      ),
      DFAMinimizationStep.selectProcessingSet(
        id: 'select',
        stepNumber: 3,
        currentPartition: [
          {q0},
          {q1},
        ],
        processingSet: {q0},
      ),
      DFAMinimizationStep.findPredecessors(
        id: 'predecessors',
        stepNumber: 4,
        currentPartition: [
          {q0},
          {q1},
        ],
        processingSet: {q0},
        symbol: 'a',
        predecessors: {q1},
      ),
      DFAMinimizationStep.splitClass(
        id: 'split',
        stepNumber: 5,
        currentPartition: [
          {q0, q1},
        ],
        splitSet: {q0, q1},
        intersection: {q0},
        difference: {q1},
        symbol: 'a',
        newPartition: [
          {q0},
          {q1},
        ],
      ),
      DFAMinimizationStep.noSplit(
        id: 'no-split',
        stepNumber: 6,
        currentPartition: [
          {q0, q1},
        ],
        checkedSet: {q0, q1},
        symbol: 'b',
      ),
      DFAMinimizationStep.partitionStable(
        id: 'stable',
        stepNumber: 7,
        finalPartition: [
          {q0},
          {q1},
        ],
      ),
      DFAMinimizationStep.createMinimizedState(
        id: 'state',
        stepNumber: 8,
        stateId: 'q0_min',
        equivalenceClass: {q0, q1},
        isAccepting: true,
        isInitial: true,
      ),
      DFAMinimizationStep.createMinimizedTransition(
        id: 'transition',
        stepNumber: 9,
        fromStateId: 'q0_min',
        toStateId: 'q1_min',
        symbol: 'a',
      ),
      DFAMinimizationStep.completion(
        id: 'completion',
        stepNumber: 10,
        originalStates: 4,
        minimizedStates: 2,
        totalTransitions: 4,
      ),
    ];

    expect(steps.map((step) => step.titleMessage?.stableCode), [
      'automaton.dfa-minimization.step.initial-partition-title',
      'automaton.dfa-minimization.step.remove-unreachable-title',
      'automaton.dfa-minimization.step.select-set-title',
      'automaton.dfa-minimization.step.find-predecessors-title',
      'automaton.dfa-minimization.step.split-class-title',
      'automaton.dfa-minimization.step.no-split-title',
      'automaton.dfa-minimization.step.partition-stable-title',
      'automaton.dfa-minimization.step.create-minimized-state-title',
      'automaton.dfa-minimization.step.create-minimized-transition-title',
      'automaton.dfa-minimization.step.completion-title',
    ]);
    expect(steps.map((step) => step.title), [
      'Create initial partition',
      'Remove unreachable states',
      'Select set to process',
      "Find predecessors on 'a'",
      'Split equivalence class',
      "No split on 'b'",
      'Partition stabilized',
      'Create minimized state q0_min',
      "Create transition on 'a'",
      'Minimization complete',
    ]);

    for (final step in steps) {
      expect(step.titleMessage, isNotNull);
      expect(step.explanationMessage, isNotNull);
      expect(
        step.titleMessage!.category,
        StructuredMessageCategory.transformation,
      );
      expect(
        step.explanationMessage!.severity,
        StructuredMessageSeverity.information,
      );

      final properties = step.toProperties();
      final titleJson = properties[dfaMinimizationTitleMessageProperty];
      final explanationJson =
          properties[dfaMinimizationExplanationMessageProperty];
      expect(titleJson, isA<Map<String, dynamic>>());
      expect(explanationJson, isA<Map<String, dynamic>>());
      expect(
        StructuredMessage.fromJson(
          Map<String, Object?>.from(titleJson! as Map),
        ),
        step.titleMessage,
      );
      expect(
        StructuredMessage.fromJson(
          Map<String, Object?>.from(explanationJson! as Map),
        ),
        step.explanationMessage,
      );
    }
  });

  test('keeps the historical title and explanation text', () {
    final initial = DFAMinimizationStep.initialPartition(
      id: 'initial',
      stepNumber: 1,
      acceptingStates: {q1},
      nonAcceptingStates: {q0},
    );
    expect(initial.title, 'Create initial partition');
    expect(
      initial.explanation,
      'Starting DFA minimization by creating the initial partition. '
      'We split states into two equivalence classes: accepting states {q1} '
      'and non-accepting states {q0}. States in different classes cannot be equivalent.',
    );

    final find = DFAMinimizationStep.findPredecessors(
      id: 'find',
      stepNumber: 2,
      currentPartition: [
        {q0},
        {q1},
      ],
      processingSet: {q0},
      symbol: 'a',
      predecessors: {},
    );
    expect(find.title, "Find predecessors on 'a'");
    expect(
      find.explanation,
      "Finding all states that transition to {q0} on symbol 'a'. "
      'Predecessors: {none}. '
      'No predecessors found, so no split will occur.',
    );

    final completion = DFAMinimizationStep.completion(
      id: 'completion',
      stepNumber: 3,
      originalStates: 4,
      minimizedStates: 2,
      totalTransitions: 4,
    );
    expect(completion.title, 'Minimization complete');
    expect(
      completion.explanation,
      'DFA minimization completed successfully. '
      'Original DFA had 4 state(s), minimized DFA has 2 state(s). '
      'Reduced by 2 state(s). '
      'The minimized DFA has 4 transition(s) and accepts the same language as the original.',
    );
  });

  test('message factories retain formal values as typed arguments', () {
    final message = DfaMinimizationStepMessages.completionExplanation(
      originalStateCount: 4,
      minimizedStateCount: 2,
      transitionCount: 4,
      reduction: 2,
    );

    expect(
      message.arguments['original-state-count']?.kind,
      StructuredMessageArgumentKind.count,
    );
    expect(
      message.arguments['minimized-state-count']?.kind,
      StructuredMessageArgumentKind.count,
    );
    expect(
      message.arguments['transition-count']?.kind,
      StructuredMessageArgumentKind.count,
    );
    expect(
      message.arguments['reduction']?.kind,
      StructuredMessageArgumentKind.integer,
    );
    expect(
      message.arguments['has-reduction']?.kind,
      StructuredMessageArgumentKind.boolean,
    );
    expect(message.arguments['reduction']?.value, 2);
  });
}
