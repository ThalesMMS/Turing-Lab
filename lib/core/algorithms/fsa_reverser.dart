//
//  fsa_reverser.dart
//  Turing Lab
//
//  Constructs an epsilon-NFA for the reverse of a finite-automaton language
//  and records clone and transition provenance for the educational UI.
//

import 'dart:math' as math;

import 'package:vector_math/vector_math_64.dart';

import '../models/algorithm_step.dart';
import '../models/fsa.dart';
import '../models/fsa_transition.dart';
import '../messages/structured_message.dart';
import '../models/state.dart';
import '../result.dart';
import '../utils/epsilon_utils.dart';
import 'fsa_reverser_messages.dart';

class FSAReversalResult {
  final FSA resultNFA;
  final Map<String, State> stateClones;
  final Map<String, FSATransition> reversedTransitions;
  final State newInitialState;
  final State newAcceptingState;
  final Set<FSATransition> entryTransitions;
  final List<AlgorithmStep> steps;

  FSAReversalResult({
    required this.resultNFA,
    required Map<String, State> stateClones,
    required Map<String, FSATransition> reversedTransitions,
    required this.newInitialState,
    required this.newAcceptingState,
    required Set<FSATransition> entryTransitions,
    required List<AlgorithmStep> steps,
  }) : stateClones = Map.unmodifiable(stateClones),
       reversedTransitions = Map.unmodifiable(reversedTransitions),
       entryTransitions = Set.unmodifiable(entryTransitions),
       steps = List.unmodifiable(steps);
}

/// Constructs an epsilon-NFA that recognizes `L(operand)^R`.
class FSAReverser {
  static const double _horizontalGap = 160;

  static Result<FSAReversalResult> reverse(FSA operand) {
    try {
      final validationError = _validateOperand(operand);
      if (validationError != null) {
        return Failure(
          validationError.stableCode,
          structuredMessage: validationError,
        );
      }

      final sortedStates = [...operand.states]
        ..sort((first, second) => first.id.compareTo(second.id));
      final maxX = sortedStates
          .map((state) => state.position.x)
          .reduce(math.max);
      const cloneLeft = 40 + _horizontalGap;
      final acceptingIds = operand.acceptingStates
          .map((state) => state.id)
          .toSet();
      final originalInitialId = operand.initialState!.id;
      final stateClones = <String, State>{
        for (var index = 0; index < sortedStates.length; index++)
          sortedStates[index].id: sortedStates[index].copyWith(
            id: 'reverse_s$index',
            position: _reversePosition(
              sortedStates[index].position,
              maxX,
              cloneLeft,
            ),
            isInitial: false,
            isAccepting: sortedStates[index].id == originalInitialId,
          ),
      };

      final reversedTransitions = _reverseTransitions(
        operand,
        stateClones,
        maxX,
        cloneLeft,
      );
      final centerY =
          stateClones.values
              .map((state) => state.position.y)
              .reduce((first, second) => first + second) /
          stateClones.length;
      final newInitial = State(
        id: 'reverse_entry',
        label: 'start',
        position: Vector2(40, centerY),
        isInitial: true,
      );
      final sortedAcceptingIds = [...acceptingIds]..sort();
      final entryTransitions = <FSATransition>{
        for (var index = 0; index < sortedAcceptingIds.length; index++)
          FSATransition.epsilon(
            id: 'reverse_entry_t$index',
            fromState: newInitial,
            toState: stateClones[sortedAcceptingIds[index]]!,
          ),
      };
      final newAccepting = stateClones[originalInitialId]!;
      final states = {newInitial, ...stateClones.values};
      final transitions = {...reversedTransitions.values, ...entryTransitions};
      final result = FSA(
        id: 'reverse_${_stableHash(operand.id)}',
        name: 'Reverse(${operand.name})',
        states: states,
        transitions: transitions,
        alphabet: {
          ...operand.alphabet.where((symbol) => !isEpsilonSymbol(symbol)),
        },
        initialState: newInitial,
        acceptingStates: {newAccepting},
        created: operand.created,
        modified: operand.modified,
        bounds: _boundsFor(states),
      );

      final resultError = _validateResult(result);
      if (resultError != null) {
        return Failure(resultError.stableCode, structuredMessage: resultError);
      }

      return ResultFactory.success(
        FSAReversalResult(
          resultNFA: result,
          stateClones: stateClones,
          reversedTransitions: reversedTransitions,
          newInitialState: newInitial,
          newAcceptingState: newAccepting,
          entryTransitions: entryTransitions,
          steps: _buildSteps(
            stateClones,
            reversedTransitions,
            newInitial,
            newAccepting,
            entryTransitions,
          ),
        ),
      );
    } catch (error) {
      final message = FsaReversalMessages.internalFailure();
      return Failure(message.stableCode, structuredMessage: message);
    }
  }

  static StructuredMessage? _validateOperand(FSA operand) {
    if (operand.states.isEmpty) {
      return FsaReversalMessages.emptyOperand();
    }
    final initial = operand.initialState;
    if (initial == null) {
      return FsaReversalMessages.missingInitialState();
    }
    if (!operand.states.contains(initial)) {
      return FsaReversalMessages.initialStateOutsideSet();
    }
    for (final accepting in operand.acceptingStates) {
      if (!operand.states.contains(accepting)) {
        return FsaReversalMessages.acceptingStateOutsideSet();
      }
    }
    for (final transition in operand.transitions) {
      if (transition is! FSATransition) {
        return FsaReversalMessages.nonFsaTransition();
      }
      if (!operand.states.contains(transition.fromState) ||
          !operand.states.contains(transition.toState)) {
        return FsaReversalMessages.unknownTransitionEndpoint();
      }
      final errors = transition
          .validate()
          .where(
            (error) =>
                error != 'Self-loop transitions must have a control point',
          )
          .toList(growable: false);
      if (errors.isNotEmpty) {
        return FsaReversalMessages.invalidTransition(transition.id);
      }
    }
    return null;
  }

  static Map<String, FSATransition> _reverseTransitions(
    FSA operand,
    Map<String, State> stateClones,
    double maxX,
    double cloneLeft,
  ) {
    final sortedTransitions = [...operand.fsaTransitions]
      ..sort(
        (first, second) =>
            _transitionSortKey(first).compareTo(_transitionSortKey(second)),
      );
    return {
      for (var index = 0; index < sortedTransitions.length; index++)
        sortedTransitions[index].id: sortedTransitions[index].copyWith(
          id: 'reverse_t$index',
          fromState: stateClones[sortedTransitions[index].toState.id],
          toState: stateClones[sortedTransitions[index].fromState.id],
          controlPoint: _reversedControlPoint(
            sortedTransitions[index],
            stateClones,
            maxX,
            cloneLeft,
          ),
        ),
    };
  }

  static String _transitionSortKey(FSATransition transition) {
    final symbols = [...transition.inputSymbols]..sort();
    return '${transition.id}\u0000${transition.fromState.id}\u0000'
        '${transition.toState.id}\u0000${transition.lambdaSymbol ?? ''}\u0000'
        '${symbols.join('\u0000')}\u0000${transition.label}\u0000'
        '${transition.type.name}\u0000${transition.controlPoint.x}\u0000'
        '${transition.controlPoint.y}';
  }

  static Vector2 _reversedControlPoint(
    FSATransition transition,
    Map<String, State> stateClones,
    double maxX,
    double cloneLeft,
  ) {
    final controlPoint = transition.controlPoint;
    if (controlPoint.x != 0 || controlPoint.y != 0) {
      return _reversePosition(controlPoint, maxX, cloneLeft);
    }
    if (transition.fromState == transition.toState) {
      return stateClones[transition.fromState.id]!.position + Vector2(0, -80);
    }
    return Vector2.zero();
  }

  static Vector2 _reversePosition(
    Vector2 position,
    double maxX,
    double cloneLeft,
  ) {
    return Vector2(cloneLeft + maxX - position.x, position.y);
  }

  static math.Rectangle<double> _boundsFor(Set<State> states) {
    final maxX = states.map((state) => state.position.x).reduce(math.max);
    final maxY = states.map((state) => state.position.y).reduce(math.max);
    return math.Rectangle<double>(
      0,
      0,
      math.max(800, maxX + 80),
      math.max(600, maxY + 80),
    );
  }

  static StructuredMessage? _validateResult(FSA result) {
    final stateIds = result.states.map((state) => state.id).toList();
    if (stateIds.toSet().length != stateIds.length) {
      return FsaReversalMessages.duplicateStateIds();
    }
    final transitionIds = result.fsaTransitions
        .map((transition) => transition.id)
        .toList();
    if (transitionIds.toSet().length != transitionIds.length) {
      return FsaReversalMessages.duplicateTransitionIds();
    }
    final errors = result.validate().where(
      (error) => !error.startsWith('Non-deterministic transition from'),
    );
    if (errors.isNotEmpty) {
      return FsaReversalMessages.invalidResult();
    }
    return null;
  }

  static List<AlgorithmStep> _buildSteps(
    Map<String, State> stateClones,
    Map<String, FSATransition> reversedTransitions,
    State newInitial,
    State newAccepting,
    Set<FSATransition> entryTransitions,
  ) {
    final sortedClones = stateClones.entries.toList()
      ..sort((first, second) => first.key.compareTo(second.key));
    final sortedReversed = reversedTransitions.entries.toList()
      ..sort((first, second) => first.key.compareTo(second.key));
    final sortedEntries = [...entryTransitions]
      ..sort((first, second) => first.id.compareTo(second.id));
    final cloneTitle = FsaReversalMessages.stepTitle('clone');
    final cloneExplanation = FsaReversalMessages.cloneExplanation();
    final reverseTitle = FsaReversalMessages.stepTitle('reverse');
    final reverseExplanation = FsaReversalMessages.reverseExplanation();
    final entryTitle = FsaReversalMessages.stepTitle('entry');
    final entryExplanation = FsaReversalMessages.entryExplanation(
      hasAcceptingStates: sortedEntries.isNotEmpty,
    );
    final acceptingTitle = FsaReversalMessages.stepTitle('accepting');
    final acceptingExplanation = FsaReversalMessages.acceptingExplanation();
    return [
      AlgorithmStep(
        id: 'fsa_reverse_step_0',
        stepNumber: 0,
        title: cloneTitle.stableCode,
        explanation: cloneExplanation.stableCode,
        type: AlgorithmType.fsaReversal,
        properties: {
          fsaReversalTitleMessageProperty: cloneTitle.toJson(),
          fsaReversalExplanationMessageProperty: cloneExplanation.toJson(),
          'clonedStates': [
            for (final clone in sortedClones)
              '${clone.key} → ${clone.value.id}',
          ],
          'createdStateIds': [for (final clone in sortedClones) clone.value.id],
        },
      ),
      AlgorithmStep(
        id: 'fsa_reverse_step_1',
        stepNumber: 1,
        title: reverseTitle.stableCode,
        explanation: reverseExplanation.stableCode,
        type: AlgorithmType.fsaReversal,
        properties: {
          fsaReversalTitleMessageProperty: reverseTitle.toJson(),
          fsaReversalExplanationMessageProperty: reverseExplanation.toJson(),
          'reversedTransitions': [
            for (final transition in sortedReversed)
              _reversedTransitionDescription(transition),
          ],
          'createdTransitionIds': [
            for (final transition in sortedReversed) transition.value.id,
          ],
        },
      ),
      AlgorithmStep(
        id: 'fsa_reverse_step_2',
        stepNumber: 2,
        title: entryTitle.stableCode,
        explanation: entryExplanation.stableCode,
        type: AlgorithmType.fsaReversal,
        properties: {
          fsaReversalTitleMessageProperty: entryTitle.toJson(),
          fsaReversalExplanationMessageProperty: entryExplanation.toJson(),
          'createdStateIds': [newInitial.id],
          'entryTransitions': [
            for (final transition in sortedEntries)
              '${transition.fromState.id} → ${transition.toState.id}',
          ],
          'createdTransitionIds': [
            for (final transition in sortedEntries) transition.id,
          ],
        },
      ),
      AlgorithmStep(
        id: 'fsa_reverse_step_3',
        stepNumber: 3,
        title: acceptingTitle.stableCode,
        explanation: acceptingExplanation.stableCode,
        type: AlgorithmType.fsaReversal,
        properties: {
          fsaReversalTitleMessageProperty: acceptingTitle.toJson(),
          fsaReversalExplanationMessageProperty: acceptingExplanation.toJson(),
          'acceptingStateId': newAccepting.id,
        },
      ),
    ];
  }

  static String _reversedTransitionDescription(
    MapEntry<String, FSATransition> transition,
  ) {
    return '${transition.key} → ${transition.value.id}: '
        '${transition.value.fromState.id} → ${transition.value.toState.id}';
  }

  static String _stableHash(String value) {
    var hash = 0x811c9dc5;
    for (final codeUnit in value.codeUnits) {
      hash ^= codeUnit;
      hash = (hash * 0x01000193) & 0xffffffff;
    }
    return hash.toRadixString(16).padLeft(8, '0');
  }
}
