//
//  fsa_kleene_star.dart
//  Turing Lab
//
//  Builds a Thompson epsilon-NFA for the Kleene star of a finite automaton and
//  records the generated states and transitions for the educational UI.
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
import 'fsa_kleene_star_messages.dart';

class FSAKleeneStarResult {
  final FSA resultNFA;
  final Map<String, State> stateClones;
  final State newInitialState;
  final State newAcceptingState;
  final FSATransition entryTransition;
  final Set<FSATransition> repeatTransitions;
  final Set<FSATransition> exitTransitions;
  final List<AlgorithmStep> steps;

  FSAKleeneStarResult({
    required this.resultNFA,
    required Map<String, State> stateClones,
    required this.newInitialState,
    required this.newAcceptingState,
    required this.entryTransition,
    required Set<FSATransition> repeatTransitions,
    required Set<FSATransition> exitTransitions,
    required List<AlgorithmStep> steps,
  }) : stateClones = Map.unmodifiable(stateClones),
       repeatTransitions = Set.unmodifiable(repeatTransitions),
       exitTransitions = Set.unmodifiable(exitTransitions),
       steps = List.unmodifiable(steps);
}

/// Constructs an epsilon-NFA that recognizes `L(operand)*`.
class FSAKleeneStar {
  static const double _horizontalGap = 160;

  static Result<FSAKleeneStarResult> apply(FSA operand) {
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
      final namespace = 'star_${_stableHash(operand.id)}';
      final minX = sortedStates
          .map((state) => state.position.x)
          .reduce(math.min);
      final cloneOffset = Vector2(40 + _horizontalGap - minX, 0);
      final acceptingIds = operand.acceptingStates
          .map((state) => state.id)
          .toSet();
      final stateClones = <String, State>{
        for (var index = 0; index < sortedStates.length; index++)
          sortedStates[index].id: sortedStates[index].copyWith(
            id: '${namespace}_s$index',
            position: sortedStates[index].position + cloneOffset,
            isInitial: false,
            isAccepting: false,
          ),
      };

      final clonedTransitions = _cloneTransitions(
        operand,
        stateClones,
        cloneOffset,
        namespace,
      );
      final clonedInitial = stateClones[operand.initialState!.id]!;
      final clonedAccepting = [...acceptingIds]
        ..sort((first, second) => first.compareTo(second));
      final centerY =
          sortedStates
              .map((state) => state.position.y + cloneOffset.y)
              .reduce((first, second) => first + second) /
          sortedStates.length;
      final clonedMaxX = stateClones.values
          .map((state) => state.position.x)
          .reduce(math.max);

      final newInitial = State(
        id: '${namespace}_entry',
        label: 'start',
        position: Vector2(40, centerY),
        isInitial: true,
        isAccepting: true,
      );
      final newAccepting = State(
        id: '${namespace}_exit',
        label: 'accept',
        position: Vector2(clonedMaxX + _horizontalGap, centerY),
        isAccepting: true,
      );
      final entryTransition = FSATransition.epsilon(
        id: '${namespace}_entry_t',
        fromState: newInitial,
        toState: clonedInitial,
      );
      final repeatTransitions = <FSATransition>{};
      final exitTransitions = <FSATransition>{};
      for (var index = 0; index < clonedAccepting.length; index++) {
        final source = stateClones[clonedAccepting[index]]!;
        repeatTransitions.add(
          FSATransition.epsilon(
            id: '${namespace}_repeat_t$index',
            fromState: source,
            toState: clonedInitial,
            controlPoint: source == clonedInitial
                ? source.position + Vector2(0, -80)
                : null,
          ),
        );
        exitTransitions.add(
          FSATransition.epsilon(
            id: '${namespace}_exit_t$index',
            fromState: source,
            toState: newAccepting,
          ),
        );
      }

      final states = {newInitial, ...stateClones.values, newAccepting};
      final transitions = {
        ...clonedTransitions,
        entryTransition,
        ...repeatTransitions,
        ...exitTransitions,
      };
      final result = FSA(
        id: namespace,
        name: '${operand.name}*',
        states: states,
        transitions: transitions,
        alphabet: {
          ...operand.alphabet.where((symbol) => !isEpsilonSymbol(symbol)),
        },
        initialState: newInitial,
        acceptingStates: {newInitial, newAccepting},
        created: operand.created,
        modified: operand.modified,
        bounds: _boundsFor(states),
      );

      final resultError = _validateResult(result);
      if (resultError != null) {
        return Failure(resultError.stableCode, structuredMessage: resultError);
      }

      return ResultFactory.success(
        FSAKleeneStarResult(
          resultNFA: result,
          stateClones: stateClones,
          newInitialState: newInitial,
          newAcceptingState: newAccepting,
          entryTransition: entryTransition,
          repeatTransitions: repeatTransitions,
          exitTransitions: exitTransitions,
          steps: _buildSteps(
            stateClones,
            newInitial,
            newAccepting,
            entryTransition,
            repeatTransitions,
            exitTransitions,
          ),
        ),
      );
    } catch (error) {
      final message = FsaKleeneStarMessages.internalFailure();
      return Failure(message.stableCode, structuredMessage: message);
    }
  }

  static StructuredMessage? _validateOperand(FSA operand) {
    if (operand.states.isEmpty) {
      return FsaKleeneStarMessages.emptyOperand();
    }
    final initial = operand.initialState;
    if (initial == null) {
      return FsaKleeneStarMessages.missingInitialState();
    }
    if (!operand.states.contains(initial)) {
      return FsaKleeneStarMessages.initialStateOutsideSet();
    }
    for (final accepting in operand.acceptingStates) {
      if (!operand.states.contains(accepting)) {
        return FsaKleeneStarMessages.acceptingStateOutsideSet();
      }
    }
    for (final transition in operand.transitions) {
      if (transition is! FSATransition) {
        return FsaKleeneStarMessages.nonFsaTransition();
      }
      if (!operand.states.contains(transition.fromState) ||
          !operand.states.contains(transition.toState)) {
        return FsaKleeneStarMessages.unknownTransitionEndpoint();
      }
      final errors = transition
          .validate()
          .where(
            (error) =>
                error != 'Self-loop transitions must have a control point',
          )
          .toList(growable: false);
      if (errors.isNotEmpty) {
        return FsaKleeneStarMessages.invalidTransition(transition.id);
      }
    }
    return null;
  }

  static Set<FSATransition> _cloneTransitions(
    FSA operand,
    Map<String, State> stateClones,
    Vector2 offset,
    String namespace,
  ) {
    final sortedTransitions = [...operand.fsaTransitions]
      ..sort(
        (first, second) =>
            _transitionSortKey(first).compareTo(_transitionSortKey(second)),
      );
    return {
      for (var index = 0; index < sortedTransitions.length; index++)
        sortedTransitions[index].copyWith(
          id: '${namespace}_t$index',
          fromState: stateClones[sortedTransitions[index].fromState.id],
          toState: stateClones[sortedTransitions[index].toState.id],
          controlPoint: _clonedControlPoint(
            sortedTransitions[index],
            stateClones,
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
    Map<String, State> stateClones,
    Vector2 offset,
  ) {
    final controlPoint = transition.controlPoint;
    if (controlPoint.x != 0 || controlPoint.y != 0) {
      return controlPoint + offset;
    }
    if (transition.fromState == transition.toState) {
      return stateClones[transition.fromState.id]!.position + Vector2(0, -80);
    }
    return Vector2.zero();
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
      return FsaKleeneStarMessages.duplicateStateIds();
    }
    final transitionIds = result.fsaTransitions
        .map((transition) => transition.id)
        .toList();
    if (transitionIds.toSet().length != transitionIds.length) {
      return FsaKleeneStarMessages.duplicateTransitionIds();
    }
    final errors = result.validate().where(
      (error) => !error.startsWith('Non-deterministic transition from'),
    );
    if (errors.isNotEmpty) {
      return FsaKleeneStarMessages.invalidResult();
    }
    return null;
  }

  static List<AlgorithmStep> _buildSteps(
    Map<String, State> stateClones,
    State newInitial,
    State newAccepting,
    FSATransition entryTransition,
    Set<FSATransition> repeatTransitions,
    Set<FSATransition> exitTransitions,
  ) {
    final sortedClones = stateClones.entries.toList()
      ..sort((first, second) => first.key.compareTo(second.key));
    final sortedRepeats = [...repeatTransitions]
      ..sort((first, second) => first.id.compareTo(second.id));
    final sortedExits = [...exitTransitions]
      ..sort((first, second) => first.id.compareTo(second.id));
    final cloneTitle = FsaKleeneStarMessages.stepTitle('clone');
    final entryTitle = FsaKleeneStarMessages.stepTitle('entry');
    final repeatTitle = FsaKleeneStarMessages.stepTitle('repeat');
    final exitTitle = FsaKleeneStarMessages.stepTitle('exit');
    return [
      AlgorithmStep(
        id: 'fsa_star_step_0',
        stepNumber: 0,
        title: cloneTitle.stableCode,
        explanation: FsaKleeneStarMessages.cloneExplanation().stableCode,
        type: AlgorithmType.fsaKleeneStar,
        properties: {
          fsaKleeneStarTitleMessageProperty: cloneTitle.toJson(),
          fsaKleeneStarExplanationMessageProperty:
              FsaKleeneStarMessages.cloneExplanation().toJson(),
          'clonedStates': [
            for (final clone in sortedClones)
              '${clone.key} → ${clone.value.id}',
          ],
          'createdStateIds': [for (final clone in sortedClones) clone.value.id],
        },
      ),
      AlgorithmStep(
        id: 'fsa_star_step_1',
        stepNumber: 1,
        title: entryTitle.stableCode,
        explanation: FsaKleeneStarMessages.entryExplanation().stableCode,
        type: AlgorithmType.fsaKleeneStar,
        properties: {
          fsaKleeneStarTitleMessageProperty: entryTitle.toJson(),
          fsaKleeneStarExplanationMessageProperty:
              FsaKleeneStarMessages.entryExplanation().toJson(),
          'createdStateIds': [newInitial.id],
          'entryTransition':
              '${entryTransition.fromState.id} → ${entryTransition.toState.id}',
          'createdTransitionIds': [entryTransition.id],
        },
      ),
      AlgorithmStep(
        id: 'fsa_star_step_2',
        stepNumber: 2,
        title: repeatTitle.stableCode,
        explanation: FsaKleeneStarMessages.repeatExplanation(
          hasAcceptingStates: sortedRepeats.isNotEmpty,
        ).stableCode,
        type: AlgorithmType.fsaKleeneStar,
        properties: {
          fsaKleeneStarTitleMessageProperty: repeatTitle.toJson(),
          fsaKleeneStarExplanationMessageProperty:
              FsaKleeneStarMessages.repeatExplanation(
                hasAcceptingStates: sortedRepeats.isNotEmpty,
              ).toJson(),
          'repeatTransitions': [
            for (final transition in sortedRepeats)
              '${transition.fromState.id} → ${transition.toState.id}',
          ],
          'createdTransitionIds': [
            for (final transition in sortedRepeats) transition.id,
          ],
        },
      ),
      AlgorithmStep(
        id: 'fsa_star_step_3',
        stepNumber: 3,
        title: exitTitle.stableCode,
        explanation: FsaKleeneStarMessages.exitExplanation(
          hasAcceptingStates: sortedExits.isNotEmpty,
        ).stableCode,
        type: AlgorithmType.fsaKleeneStar,
        properties: {
          fsaKleeneStarTitleMessageProperty: exitTitle.toJson(),
          fsaKleeneStarExplanationMessageProperty:
              FsaKleeneStarMessages.exitExplanation(
                hasAcceptingStates: sortedExits.isNotEmpty,
              ).toJson(),
          'createdStateIds': [newAccepting.id],
          'exitTransitions': [
            for (final transition in sortedExits)
              '${transition.fromState.id} → ${transition.toState.id}',
          ],
          'createdTransitionIds': [
            for (final transition in sortedExits) transition.id,
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
}
