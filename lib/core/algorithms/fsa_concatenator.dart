//
//  fsa_concatenator.dart
//  Turing Lab
//
//  Builds the standard epsilon-NFA for the concatenation of two finite
//  automata while retaining clone provenance for the educational UI.
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
import 'fsa_concatenation_messages.dart';

enum FSAConcatenationOperand { left, right }

class FSAStateClone {
  final FSAConcatenationOperand operand;
  final String originalStateId;
  final State clonedState;

  const FSAStateClone({
    required this.operand,
    required this.originalStateId,
    required this.clonedState,
  });
}

class FSAConcatenationResult {
  final FSA resultNFA;
  final List<FSAStateClone> stateClones;
  final Set<FSATransition> epsilonBridges;
  final List<AlgorithmStep> steps;

  FSAConcatenationResult({
    required this.resultNFA,
    required List<FSAStateClone> stateClones,
    required Set<FSATransition> epsilonBridges,
    required List<AlgorithmStep> steps,
  }) : stateClones = List.unmodifiable(stateClones),
       epsilonBridges = Set.unmodifiable(epsilonBridges),
       steps = List.unmodifiable(steps);

  Iterable<FSAStateClone> clonesFor(FSAConcatenationOperand operand) {
    return stateClones.where((clone) => clone.operand == operand);
  }
}

/// Constructs an epsilon-NFA that recognizes `L(left)L(right)`.
class FSAConcatenator {
  static const double _operandGap = 160;

  static Result<FSAConcatenationResult> concatenate(FSA left, FSA right) {
    try {
      final leftError = _validateOperand(left, 'left');
      if (leftError != null) return _failure(leftError);

      final rightError = _validateOperand(right, 'right');
      if (rightError != null) return _failure(rightError);

      final sortedLeftStates = _sortedStates(left);
      final sortedRightStates = _sortedStates(right);
      final rightOffset = Vector2(_rightOffset(left, right), 0);

      final leftStateMap = _cloneStates(
        automaton: left,
        sortedStates: sortedLeftStates,
        operand: FSAConcatenationOperand.left,
        offset: Vector2.zero(),
      );
      final rightStateMap = _cloneStates(
        automaton: right,
        sortedStates: sortedRightStates,
        operand: FSAConcatenationOperand.right,
        offset: rightOffset,
      );

      final stateClones = <FSAStateClone>[
        for (final state in sortedLeftStates)
          FSAStateClone(
            operand: FSAConcatenationOperand.left,
            originalStateId: state.id,
            clonedState: leftStateMap[state.id]!,
          ),
        for (final state in sortedRightStates)
          FSAStateClone(
            operand: FSAConcatenationOperand.right,
            originalStateId: state.id,
            clonedState: rightStateMap[state.id]!,
          ),
      ];

      final transitions = <FSATransition>{
        ..._cloneTransitions(
          automaton: left,
          stateMap: leftStateMap,
          operand: FSAConcatenationOperand.left,
          offset: Vector2.zero(),
        ),
        ..._cloneTransitions(
          automaton: right,
          stateMap: rightStateMap,
          operand: FSAConcatenationOperand.right,
          offset: rightOffset,
        ),
      };

      final rightInitial = rightStateMap[right.initialState!.id]!;
      final sortedLeftAccepting = [...left.acceptingStates]
        ..sort((first, second) => first.id.compareTo(second.id));
      final epsilonBridges = <FSATransition>{};
      for (var index = 0; index < sortedLeftAccepting.length; index++) {
        final source = leftStateMap[sortedLeftAccepting[index].id]!;
        epsilonBridges.add(
          FSATransition.epsilon(
            id: 'concat_bridge_t$index',
            fromState: source,
            toState: rightInitial,
          ),
        );
      }
      transitions.addAll(epsilonBridges);

      final states = {...leftStateMap.values, ...rightStateMap.values};
      final acceptingStates = right.acceptingStates
          .map((state) => rightStateMap[state.id]!)
          .toSet();
      final initialState = leftStateMap[left.initialState!.id]!;
      final result = FSA(
        id: 'concat_${_stableHash('${left.id}\u0000${right.id}')}',
        name: '${left.name} · ${right.name}',
        states: states,
        transitions: transitions,
        alphabet: {
          ...left.alphabet.where((symbol) => !isEpsilonSymbol(symbol)),
          ...right.alphabet.where((symbol) => !isEpsilonSymbol(symbol)),
        },
        initialState: initialState,
        acceptingStates: acceptingStates,
        created: left.created.isBefore(right.created)
            ? left.created
            : right.created,
        modified: left.modified.isAfter(right.modified)
            ? left.modified
            : right.modified,
        bounds: _boundsFor(states),
      );

      final structuralError = _validateResult(result);
      if (structuralError != null) {
        return _failure(structuralError);
      }

      return ResultFactory.success(
        FSAConcatenationResult(
          resultNFA: result,
          stateClones: stateClones,
          epsilonBridges: epsilonBridges,
          steps: _buildSteps(stateClones, epsilonBridges),
        ),
      );
    } catch (error) {
      return _failure(FsaConcatenationMessages.internalFailure());
    }
  }

  static StructuredMessage? _validateOperand(FSA automaton, String operand) {
    if (automaton.states.isEmpty) {
      return FsaConcatenationMessages.emptyOperand(operand);
    }
    final initial = automaton.initialState;
    if (initial == null) {
      return FsaConcatenationMessages.missingInitialState(operand);
    }
    if (!automaton.states.contains(initial)) {
      return FsaConcatenationMessages.initialStateOutsideSet(operand);
    }
    for (final accepting in automaton.acceptingStates) {
      if (!automaton.states.contains(accepting)) {
        return FsaConcatenationMessages.acceptingStateOutsideSet(operand);
      }
    }
    for (final transition in automaton.transitions) {
      if (transition is! FSATransition) {
        return FsaConcatenationMessages.nonFsaTransition(operand);
      }
      if (!automaton.states.contains(transition.fromState) ||
          !automaton.states.contains(transition.toState)) {
        return FsaConcatenationMessages.unknownTransitionEndpoint(operand);
      }
      final transitionErrors = transition
          .validate()
          .where(
            (error) =>
                error != 'Self-loop transitions must have a control point',
          )
          .toList(growable: false);
      if (transitionErrors.isNotEmpty) {
        return FsaConcatenationMessages.invalidTransition(
          operand,
          transition.id,
        );
      }
    }
    return null;
  }

  static List<State> _sortedStates(FSA automaton) {
    return [...automaton.states]
      ..sort((first, second) => first.id.compareTo(second.id));
  }

  static Map<String, State> _cloneStates({
    required FSA automaton,
    required List<State> sortedStates,
    required FSAConcatenationOperand operand,
    required Vector2 offset,
  }) {
    final initialId = automaton.initialState!.id;
    final acceptingIds = automaton.acceptingStates
        .map((state) => state.id)
        .toSet();
    final prefix = operand == FSAConcatenationOperand.left ? 'l' : 'r';

    return {
      for (var index = 0; index < sortedStates.length; index++)
        sortedStates[index].id: sortedStates[index].copyWith(
          id: 'concat_${prefix}_s$index',
          position: sortedStates[index].position + offset,
          isInitial:
              operand == FSAConcatenationOperand.left &&
              sortedStates[index].id == initialId,
          isAccepting:
              operand == FSAConcatenationOperand.right &&
              acceptingIds.contains(sortedStates[index].id),
        ),
    };
  }

  static Set<FSATransition> _cloneTransitions({
    required FSA automaton,
    required Map<String, State> stateMap,
    required FSAConcatenationOperand operand,
    required Vector2 offset,
  }) {
    final sortedTransitions = [...automaton.fsaTransitions]
      ..sort((first, second) {
        final firstKey = _transitionSortKey(first);
        final secondKey = _transitionSortKey(second);
        return firstKey.compareTo(secondKey);
      });
    final prefix = operand == FSAConcatenationOperand.left ? 'l' : 'r';

    return {
      for (var index = 0; index < sortedTransitions.length; index++)
        sortedTransitions[index].copyWith(
          id: 'concat_${prefix}_t$index',
          fromState: stateMap[sortedTransitions[index].fromState.id],
          toState: stateMap[sortedTransitions[index].toState.id],
          controlPoint: _clonedControlPoint(
            sortedTransitions[index],
            stateMap,
            offset,
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

  static Vector2 _clonedControlPoint(
    FSATransition transition,
    Map<String, State> stateMap,
    Vector2 offset,
  ) {
    final controlPoint = transition.controlPoint;
    if (controlPoint.x != 0 || controlPoint.y != 0) {
      return controlPoint + offset;
    }
    if (transition.fromState == transition.toState) {
      return stateMap[transition.fromState.id]!.position + Vector2(0, -80);
    }
    return Vector2.zero();
  }

  static double _rightOffset(FSA left, FSA right) {
    final leftMaxX = left.states
        .map((state) => state.position.x)
        .reduce(math.max);
    final rightMinX = right.states
        .map((state) => state.position.x)
        .reduce(math.min);
    return math.max(0, leftMaxX + _operandGap - rightMinX);
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
      return FsaConcatenationMessages.duplicateStateIds();
    }
    final transitionIds = result.fsaTransitions
        .map((transition) => transition.id)
        .toList();
    if (transitionIds.toSet().length != transitionIds.length) {
      return FsaConcatenationMessages.duplicateTransitionIds();
    }
    final structuralErrors = result.validate().where(
      (error) => !error.startsWith('Non-deterministic transition from'),
    );
    if (structuralErrors.isNotEmpty) {
      return FsaConcatenationMessages.invalidResult();
    }
    return null;
  }

  static List<AlgorithmStep> _buildSteps(
    List<FSAStateClone> stateClones,
    Set<FSATransition> epsilonBridges,
  ) {
    AlgorithmStep cloneStep(FSAConcatenationOperand operand, int number) {
      final clones = stateClones
          .where((clone) => clone.operand == operand)
          .toList(growable: false);
      final label = operand == FSAConcatenationOperand.left ? 'left' : 'right';
      final title = FsaConcatenationMessages.cloneTitle(label);
      final explanation = FsaConcatenationMessages.cloneExplanation(label);
      return AlgorithmStep(
        id: 'fsa_concat_step_$number',
        stepNumber: number,
        title: title.stableCode,
        explanation: explanation.stableCode,
        type: AlgorithmType.fsaConcatenation,
        properties: {
          FsaConcatenationMessages.FSA_CONCATENATION_TITLE_MESSAGE_PROPERTY:
              title.toJson(),
          FsaConcatenationMessages
              .FSA_CONCATENATION_EXPLANATION_MESSAGE_PROPERTY: explanation
              .toJson(),
          'operand': label,
          'clonedStates': [
            for (final clone in clones)
              '${clone.originalStateId} → ${clone.clonedState.id}',
          ],
          'createdStateIds': [for (final clone in clones) clone.clonedState.id],
        },
      );
    }

    final sortedBridges = [...epsilonBridges]
      ..sort((first, second) => first.id.compareTo(second.id));
    final title = FsaConcatenationMessages.connectTitle();
    final explanation = sortedBridges.isEmpty
        ? FsaConcatenationMessages.connectEmptyExplanation()
        : FsaConcatenationMessages.connectExplanation();
    return [
      cloneStep(FSAConcatenationOperand.left, 0),
      cloneStep(FSAConcatenationOperand.right, 1),
      AlgorithmStep(
        id: 'fsa_concat_step_2',
        stepNumber: 2,
        title: title.stableCode,
        explanation: explanation.stableCode,
        type: AlgorithmType.fsaConcatenation,
        properties: {
          FsaConcatenationMessages.FSA_CONCATENATION_TITLE_MESSAGE_PROPERTY:
              title.toJson(),
          FsaConcatenationMessages
              .FSA_CONCATENATION_EXPLANATION_MESSAGE_PROPERTY: explanation
              .toJson(),
          'epsilonBridges': [
            for (final bridge in sortedBridges)
              '${bridge.fromState.id} → ${bridge.toState.id}',
          ],
          'createdTransitionIds': [
            for (final bridge in sortedBridges) bridge.id,
          ],
        },
      ),
    ];
  }

  static String _stableHash(String value) {
    var hash = 0x811c9dc5;
    for (final codeUnit in value.codeUnits) {
      hash ^= codeUnit;
      hash = (hash * 0x01000193) & 0xffffffff;
    }
    return hash.toRadixString(16).padLeft(8, '0');
  }

  static Result<T> _failure<T>(StructuredMessage message) =>
      Failure(message.stableCode, structuredMessage: message);
}
