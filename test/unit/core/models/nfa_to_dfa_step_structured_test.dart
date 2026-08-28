import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:vector_math/vector_math_64.dart';

import 'package:turing_lab/core/messages/structured_message.dart';
import 'package:turing_lab/core/models/nfa_to_dfa_step.dart';
import 'package:turing_lab/core/models/nfa_to_dfa_step_messages.dart';
import 'package:turing_lab/core/models/state.dart';

void main() {
  final q0 = _state('q0');
  final q1 = _state('q1');
  final q2 = _state('q2');

  test('all NFA-to-DFA factories carry structured title and explanation', () {
    final steps = [
      NFAToDFAStep.initialEpsilonClosure(
        id: 'initial',
        stepNumber: 1,
        initialState: q0,
        epsilonClosure: {q0, q1},
        containsAcceptingState: true,
      ),
      NFAToDFAStep.processSymbol(
        id: 'process',
        stepNumber: 2,
        currentStateSet: {q0, q1},
        symbol: 'a',
        reachableStates: {q2},
      ),
      NFAToDFAStep.epsilonClosureOfReachable(
        id: 'closure',
        stepNumber: 3,
        reachableStates: {q2},
        epsilonClosure: {q1, q2},
        containsAcceptingState: true,
        isNewState: true,
      ),
      NFAToDFAStep.createDFAState(
        id: 'state',
        stepNumber: 4,
        nfaStateSet: {q1, q2},
        dfaStateId: 'q1_q2',
        dfaStateLabel: '{q1,q2}',
        isAccepting: true,
      ),
      NFAToDFAStep.createDFATransition(
        id: 'transition',
        stepNumber: 5,
        fromStateSet: {q0},
        fromDfaStateId: 'q0',
        symbol: 'a',
        toStateSet: {q1, q2},
        toDfaStateId: 'q1_q2',
      ),
      NFAToDFAStep.completion(
        id: 'completion',
        stepNumber: 6,
        totalStates: 3,
        totalTransitions: 4,
        totalAcceptingStates: 1,
      ),
    ];

    expect(steps.map((step) => step.titleMessage?.stableCode), [
      'automata.nfa-to-dfa.initial-epsilon-closure-title',
      'automata.nfa-to-dfa.process-symbol-title',
      'automata.nfa-to-dfa.epsilon-closure-of-reachable-title',
      'automata.nfa-to-dfa.create-dfa-state-title',
      'automata.nfa-to-dfa.create-dfa-transition-title',
      'automata.nfa-to-dfa.completion-title',
    ]);
    expect(steps.map((step) => step.explanationMessage?.stableCode), [
      'automata.nfa-to-dfa.initial-epsilon-closure-explanation',
      'automata.nfa-to-dfa.process-symbol-explanation',
      'automata.nfa-to-dfa.epsilon-closure-of-reachable-explanation',
      'automata.nfa-to-dfa.create-dfa-state-explanation',
      'automata.nfa-to-dfa.create-dfa-transition-explanation',
      'automata.nfa-to-dfa.completion-explanation',
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

      final explanation = step.baseStep.stepExplanation;
      expect(explanation, isNotNull);
      expect(explanation!.titleMessage, isNotNull);
      expect(explanation.bulletMessages, isNotEmpty);
      for (final message in [
        step.titleMessage!,
        step.explanationMessage!,
        explanation.titleMessage!,
        ...explanation.bulletMessages,
      ]) {
        expect(StructuredMessage.fromJson(message.toJson()), message);
      }

      final properties = step.toProperties();
      expect(
        StructuredMessage.fromJson(
          Map<String, Object?>.from(
            properties[nfaToDfaTitleMessageProperty]! as Map,
          ),
        ),
        step.titleMessage,
      );
      expect(
        StructuredMessage.fromJson(
          Map<String, Object?>.from(
            properties[nfaToDfaExplanationMessageProperty]! as Map,
          ),
        ),
        step.explanationMessage,
      );
      expect(() => jsonEncode(step.toJson()), returnsNormally);
    }
  });

  test(
    'dynamic arguments preserve symbols, state labels, booleans, and counts',
    () {
      final initial = NFAToDFAStep.initialEpsilonClosure(
        id: 'initial',
        stepNumber: 1,
        initialState: q0,
        epsilonClosure: {q0, q1},
        containsAcceptingState: true,
      );
      expect(
        initial.explanationMessage!.arguments['initial-state']!.value,
        'q0',
      );
      expect(
        initial.explanationMessage!.arguments['initial-state']!.kind,
        StructuredMessageArgumentKind.literal,
      );
      expect(
        initial
            .explanationMessage!
            .arguments['contains-accepting-state']!
            .value,
        isTrue,
      );

      final process = NFAToDFAStep.processSymbol(
        id: 'process',
        stepNumber: 2,
        currentStateSet: {q0},
        symbol: 'a',
        reachableStates: {q1},
      );
      expect(process.titleMessage!.arguments['symbol']!.value, 'a');
      expect(
        process.titleMessage!.arguments['symbol']!.kind,
        StructuredMessageArgumentKind.symbol,
      );
      expect(
        process
            .baseStep
            .stepExplanation!
            .bulletMessages[1]
            .arguments['symbol']!
            .value,
        'a',
      );

      final state = NFAToDFAStep.createDFAState(
        id: 'state',
        stepNumber: 3,
        nfaStateSet: {q0, q1},
        dfaStateId: 'D',
        dfaStateLabel: '{q0,q1}',
        isAccepting: false,
      );
      expect(state.titleMessage!.arguments['state']!.value, 'D');
      expect(
        state.titleMessage!.arguments['state']!.kind,
        StructuredMessageArgumentKind.identifier,
      );
      expect(
        state.explanationMessage!.arguments['is-accepting']!.value,
        isFalse,
      );

      final transition = NFAToDFAStep.createDFATransition(
        id: 'transition',
        stepNumber: 4,
        fromStateSet: {q0},
        fromDfaStateId: 'D0',
        symbol: 'b',
        toStateSet: {q1},
        toDfaStateId: 'D1',
      );
      expect(
        transition.explanationMessage!.arguments['from-state']!.value,
        'D0',
      );
      expect(transition.explanationMessage!.arguments['to-state']!.value, 'D1');
      expect(
        transition.explanationMessage!.arguments['symbol']!.kind,
        StructuredMessageArgumentKind.symbol,
      );

      final completion = NFAToDFAStep.completion(
        id: 'completion',
        stepNumber: 5,
        totalStates: 3,
        totalTransitions: 4,
        totalAcceptingStates: 1,
      );
      expect(completion.explanationMessage!.arguments['state-count']!.value, 3);
      expect(
        completion.explanationMessage!.arguments['state-count']!.kind,
        StructuredMessageArgumentKind.count,
      );
      expect(
        completion
            .baseStep
            .stepExplanation!
            .bulletMessages[0]
            .arguments['count']!
            .value,
        3,
      );
    },
  );

  test(
    'legacy base prose remains unchanged while structured fields serialize',
    () {
      final process = NFAToDFAStep.processSymbol(
        id: 'process',
        stepNumber: 1,
        currentStateSet: {q0, q1},
        symbol: 'a',
        reachableStates: {q2},
      );
      expect(process.baseStep.title, "Process symbol 'a'");
      expect(
        process.baseStep.explanation,
        "From state set {q0, q1}, processing symbol 'a'. "
        "Following NFA transitions on 'a' leads to states: {q2}.",
      );
      expect(process.baseStep.stepExplanation!.titleMessage, isNotNull);
      expect(
        process.baseStep.stepExplanation!.bulletMessages.map(
          (message) => message.stableCode,
        ),
        [
          'automata.nfa-to-dfa.current-dfa-state-set',
          'automata.nfa-to-dfa.collect-symbol-destinations',
          'automata.nfa-to-dfa.reachable-before-epsilon-closure',
        ],
      );

      final roundTrip = NFAToDFAStep.fromJson(process.toJson());
      expect(roundTrip.baseStep.title, process.baseStep.title);
      expect(roundTrip.baseStep.explanation, process.baseStep.explanation);
      expect(roundTrip.titleMessage, process.titleMessage);
      expect(roundTrip.explanationMessage, process.explanationMessage);
      expect(
        roundTrip.baseStep.stepExplanation!.bulletMessages,
        process.baseStep.stepExplanation!.bulletMessages,
      );
    },
  );

  test('conditional bullets follow the legacy branch decisions', () {
    final initial = NFAToDFAStep.initialEpsilonClosure(
      id: 'initial',
      stepNumber: 1,
      initialState: q0,
      epsilonClosure: {q0},
      containsAcceptingState: false,
    );
    expect(initial.baseStep.stepExplanation!.bulletMessages, hasLength(2));

    final closure = NFAToDFAStep.epsilonClosureOfReachable(
      id: 'closure',
      stepNumber: 2,
      reachableStates: {q1},
      epsilonClosure: {q1},
      containsAcceptingState: false,
      isNewState: false,
    );
    expect(
      closure.baseStep.stepExplanation!.bulletMessages.map(
        (message) => message.code,
      ),
      [
        'epsilon-transitions-do-not-consume-input',
        'epsilon-closure-reached-from-states',
        'existing-dfa-state-set',
      ],
    );
  });
}

State _state(String id) => State(id: id, label: id, position: Vector2.zero());
