import 'dart:math' as math;

import 'package:vector_math/vector_math_64.dart';

import '../models/pda.dart';
import '../models/pda_acceptance_mode.dart';
import '../models/pda_transition.dart';
import '../models/state.dart';
import '../models/transition.dart';
import '../messages/structured_message.dart';
import '../result.dart';
import '../utils/epsilon_utils.dart';
import 'pda_normalization_messages.dart';

/// Single-pop normal forms supported by [PDANormalizer].
enum PDANormalForm {
  finalStateAndSinglePop(PDAAcceptanceMode.finalState),
  emptyStackAndSinglePop(PDAAcceptanceMode.emptyStack),
  finalStateAndEmptyStackAndSinglePop(PDAAcceptanceMode.both);

  const PDANormalForm(this.acceptanceMode);

  final PDAAcceptanceMode acceptanceMode;
}

/// Explains why a state or transition was generated during normalization.
class PDANormalizationProvenance {
  const PDANormalizationProvenance({
    required this.generatedId,
    required this.description,
    this.descriptionMessage,
    this.sourceStateId,
    this.sourceTransitionId,
  });

  final String generatedId;

  /// Stable message code kept for callers that still consume a string.
  final String description;

  /// Locale-neutral explanation of why this element was generated.
  final StructuredMessage? descriptionMessage;
  final String? sourceStateId;
  final String? sourceTransitionId;
}

/// Result of a language-preserving PDA normalization.
class PDANormalizationReport {
  PDANormalizationReport({
    required this.normalizedPda,
    required this.sourceMode,
    required this.targetForm,
    required Set<State> addedStates,
    required Set<String> addedStackSymbols,
    required Set<PDATransition> addedTransitions,
    required Set<String> replacedTransitionIds,
    required Map<String, PDANormalizationProvenance> provenance,
    required this.sourceWasDeterministic,
    required this.normalizedIsDeterministic,
    required List<String> warnings,
    Iterable<StructuredMessage> structuredWarnings = const [],
  }) : addedStates = Set<State>.unmodifiable(addedStates),
       addedStackSymbols = Set<String>.unmodifiable(addedStackSymbols),
       addedTransitions = Set<PDATransition>.unmodifiable(addedTransitions),
       replacedTransitionIds = Set<String>.unmodifiable(replacedTransitionIds),
       provenance = Map<String, PDANormalizationProvenance>.unmodifiable(
         provenance,
       ),
       warnings = List<String>.unmodifiable(warnings),
       structuredWarnings = List<StructuredMessage>.unmodifiable(
         structuredWarnings,
       );

  final PDA normalizedPda;
  final PDAAcceptanceMode sourceMode;
  final PDANormalForm targetForm;
  final Set<State> addedStates;
  final Set<String> addedStackSymbols;
  final Set<PDATransition> addedTransitions;
  final Set<String> replacedTransitionIds;
  final Map<String, PDANormalizationProvenance> provenance;
  final bool sourceWasDeterministic;
  final bool normalizedIsDeterministic;

  /// Stable message codes kept for compatibility with existing callers.
  final List<String> warnings;

  /// Locale-neutral warning payloads for localized presentation.
  final List<StructuredMessage> structuredWarnings;

  PDAAcceptanceMode get targetMode => targetForm.acceptanceMode;

  bool get introducedNondeterminism =>
      sourceWasDeterministic && !normalizedIsDeterministic;
}

/// Converts a PDA to a selected acceptance convention while ensuring that
/// every transition pops exactly one stack symbol.
class PDANormalizer {
  const PDANormalizer._();

  static Result<PDANormalizationReport> normalize(
    PDA pda, {
    required PDAAcceptanceMode sourceMode,
    required PDANormalForm targetForm,
  }) {
    final validationMessage = _validateSource(pda, sourceMode);
    if (validationMessage != null) {
      return Failure(
        validationMessage.stableCode,
        structuredMessage: validationMessage,
      );
    }

    final builder = _PDANormalizationBuilder(pda, sourceMode, targetForm);
    return Success(builder.build());
  }

  static StructuredMessage? _validateSource(
    PDA pda,
    PDAAcceptanceMode sourceMode,
  ) {
    if (pda.states.isEmpty) {
      return PdaNormalizationMessages.emptyPda();
    }
    final initialState = pda.initialState;
    if (initialState == null || !pda.states.contains(initialState)) {
      return initialState == null
          ? PdaNormalizationMessages.missingInitialState()
          : PdaNormalizationMessages.initialStateOutsideSet();
    }
    if (pda.initialStackSymbol.isEmpty ||
        !pda.stackAlphabet.contains(pda.initialStackSymbol)) {
      return PdaNormalizationMessages.invalidInitialStackSymbol(
        pda.initialStackSymbol,
      );
    }
    if (sourceMode != PDAAcceptanceMode.emptyStack &&
        pda.acceptingStates.isEmpty) {
      return PdaNormalizationMessages.missingAcceptingState();
    }
    if (pda.acceptingStates.any((state) => !pda.states.contains(state))) {
      return PdaNormalizationMessages.acceptingStateOutsideSet();
    }

    for (final transition in pda.transitions) {
      if (transition is! PDATransition) {
        return PdaNormalizationMessages.nonPdaTransition();
      }
      if (!pda.states.contains(transition.fromState) ||
          !pda.states.contains(transition.toState)) {
        return PdaNormalizationMessages.transitionEndpointOutsideSet(
          transition.id,
        );
      }
      if (!_hasLambdaPop(transition) &&
          !pda.stackAlphabet.contains(transition.popSymbol)) {
        return PdaNormalizationMessages.transitionPopSymbolOutsideAlphabet(
          transition.id,
          transition.popSymbol,
        );
      }
      if (!_hasLambdaPush(transition) &&
          transition.pushSymbols.any(
            (symbol) => !pda.stackAlphabet.contains(symbol),
          )) {
        final symbol = transition.pushSymbols.firstWhere(
          (symbol) => !pda.stackAlphabet.contains(symbol),
        );
        return PdaNormalizationMessages.transitionPushSymbolOutsideAlphabet(
          transition.id,
          symbol,
        );
      }
    }
    return null;
  }
}

class _PDANormalizationBuilder {
  _PDANormalizationBuilder(this.source, this.sourceMode, this.targetForm)
    : targetMode = targetForm.acceptanceMode,
      _usedStateIds = source.states.map((state) => state.id).toSet(),
      _usedStateLabels = source.states.map((state) => state.label).toSet(),
      _usedTransitionIds = source.transitions
          .map((transition) => transition.id)
          .toSet(),
      _sourceWasDeterministic = _isDeterministic(source);

  final PDA source;
  final PDAAcceptanceMode sourceMode;
  final PDANormalForm targetForm;
  final PDAAcceptanceMode targetMode;
  final Set<String> _usedStateIds;
  final Set<String> _usedStateLabels;
  final Set<String> _usedTransitionIds;
  final bool _sourceWasDeterministic;
  final Set<State> _addedStates = <State>{};
  final Set<PDATransition> _addedTransitions = <PDATransition>{};
  final Set<String> _replacedTransitionIds = <String>{};
  final Map<String, PDANormalizationProvenance> _provenance =
      <String, PDANormalizationProvenance>{};
  var _transitionSequence = 0;
  var _generatedStateSequence = 0;

  PDANormalizationReport build() {
    final bottomMarker = _freshStackSymbol(
      source.stackAlphabet,
      '${source.initialStackSymbol}_bottom',
    );
    final stackAlphabet = <String>{...source.stackAlphabet, bottomMarker};
    final sourceAcceptingIds = source.acceptingStates
        .map((state) => state.id)
        .toSet();

    final statesBySourceId = <String, State>{};
    final sourceStates = source.states.toList()
      ..sort((left, right) => left.id.compareTo(right.id));
    for (final state in sourceStates) {
      final remainsAccepting =
          sourceMode == PDAAcceptanceMode.finalState &&
          targetMode == PDAAcceptanceMode.finalState &&
          sourceAcceptingIds.contains(state.id);
      statesBySourceId[state.id] = state.copyWith(
        isInitial: false,
        isAccepting: remainsAccepting,
      );
    }

    final nextGeneratedPosition = _generatedPositionFactory(source.states);
    final normalizedInitial = _addState(
      role: 'initial',
      label: 'norm_init',
      position: nextGeneratedPosition(),
      isInitial: true,
      descriptionMessage: PdaNormalizationMessages.initialStateDescription(
        source.initialState!.id,
      ),
      sourceStateId: source.initialState!.id,
    );

    State? acceptanceState;
    if (_usesBottomExit) {
      acceptanceState = _addState(
        role: 'accept',
        label: 'norm_accept',
        position: nextGeneratedPosition(),
        isAccepting: targetMode != PDAAcceptanceMode.emptyStack,
        descriptionMessage:
            PdaNormalizationMessages.acceptanceStateDescription(),
      );
    } else if (_usesDrainState) {
      acceptanceState = _addState(
        role: 'drain',
        label: 'norm_drain',
        position: nextGeneratedPosition(),
        isAccepting: targetMode == PDAAcceptanceMode.both,
        descriptionMessage: PdaNormalizationMessages.drainStateDescription(),
      );
    }

    final transitions = <PDATransition>{};
    transitions.add(
      _addTransition(
        role: 'initialize',
        fromState: normalizedInitial,
        toState: statesBySourceId[source.initialState!.id]!,
        popSymbol: bottomMarker,
        pushSymbols: [source.initialStackSymbol, bottomMarker],
        descriptionMessage:
            PdaNormalizationMessages.initializeTransitionDescription(
              source.initialState!.id,
            ),
        sourceStateId: source.initialState!.id,
      ),
    );

    final sourceTransitions = source.pdaTransitions.toList()
      ..sort(_compareTransitions);
    final sortedStackAlphabet = stackAlphabet.toList()..sort();
    for (final transition in sourceTransitions) {
      final fromState = statesBySourceId[transition.fromState.id]!;
      final toState = statesBySourceId[transition.toState.id]!;
      if (!_hasLambdaPop(transition)) {
        transitions.add(
          transition.copyWith(fromState: fromState, toState: toState),
        );
        continue;
      }

      _replacedTransitionIds.add(transition.id);
      for (final stackTop in sortedStackAlphabet) {
        final pushSymbols = <String>[
          if (!_hasLambdaPush(transition)) ...transition.pushSymbols,
          stackTop,
        ];
        transitions.add(
          _addTransition(
            role: 'single_pop',
            fromState: fromState,
            toState: toState,
            inputSymbol: transition.inputSymbol,
            isLambdaInput: transition.isLambdaInput,
            popSymbol: stackTop,
            pushSymbols: pushSymbols,
            type: transition.type,
            controlPoint: transition.controlPoint,
            descriptionMessage:
                PdaNormalizationMessages.singlePopTransitionDescription(
                  transition.id,
                ),
            sourceTransitionId: transition.id,
          ),
        );
      }
    }

    if (_usesBottomExit) {
      final exitSources = sourceMode == PDAAcceptanceMode.emptyStack
          ? sourceStates
          : sourceStates.where(
              (state) => sourceAcceptingIds.contains(state.id),
            );
      for (final sourceState in exitSources) {
        transitions.add(
          _addTransition(
            role: 'accept_empty',
            fromState: statesBySourceId[sourceState.id]!,
            toState: acceptanceState!,
            popSymbol: bottomMarker,
            pushSymbols: const [],
            descriptionMessage:
                PdaNormalizationMessages.acceptEmptyTransitionDescription(
                  sourceStateId: sourceState.id,
                  targetMode: targetMode,
                ),
            sourceStateId: sourceState.id,
          ),
        );
      }
    } else if (_usesDrainState) {
      final acceptingSources = sourceStates.where(
        (state) => sourceAcceptingIds.contains(state.id),
      );
      for (final sourceState in acceptingSources) {
        for (final stackTop in sortedStackAlphabet) {
          transitions.add(
            _addTransition(
              role: 'enter_drain',
              fromState: statesBySourceId[sourceState.id]!,
              toState: acceptanceState!,
              popSymbol: stackTop,
              pushSymbols: const [],
              descriptionMessage:
                  PdaNormalizationMessages.enterDrainTransitionDescription(
                    sourceState.id,
                  ),
              sourceStateId: sourceState.id,
            ),
          );
        }
      }
      for (final stackTop in sortedStackAlphabet) {
        transitions.add(
          _addTransition(
            role: 'drain',
            fromState: acceptanceState!,
            toState: acceptanceState,
            popSymbol: stackTop,
            pushSymbols: const [],
            controlPoint: Vector2(30, -30),
            descriptionMessage:
                PdaNormalizationMessages.drainTransitionDescription(),
          ),
        );
      }
    }

    final allStates = <State>{...statesBySourceId.values, ..._addedStates};
    final acceptingStates = allStates
        .where((state) => state.isAccepting)
        .toSet();
    final normalizedPda = PDA(
      id: source.id,
      name: source.name,
      states: allStates,
      transitions: transitions
          .map<Transition>((transition) => transition)
          .toSet(),
      alphabet: source.alphabet,
      initialState: normalizedInitial,
      acceptingStates: acceptingStates,
      created: source.created,
      modified: DateTime.now(),
      bounds: _expandedBounds(source.bounds, allStates),
      zoomLevel: source.zoomLevel,
      panOffset: source.panOffset,
      stackAlphabet: stackAlphabet,
      initialStackSymbol: bottomMarker,
      acceptanceMode: targetMode,
    );

    final normalizedIsDeterministic = _isDeterministic(normalizedPda);
    final structuredWarnings = <StructuredMessage>[
      PdaNormalizationMessages.growthWarning(
        addedStates: _addedStates.length,
        addedTransitions: _addedTransitions.length,
      ),
      if (_sourceWasDeterministic && !normalizedIsDeterministic)
        PdaNormalizationMessages.introducedNondeterminismWarning(),
    ];

    return PDANormalizationReport(
      normalizedPda: normalizedPda,
      sourceMode: sourceMode,
      targetForm: targetForm,
      addedStates: _addedStates,
      addedStackSymbols: {bottomMarker},
      addedTransitions: _addedTransitions,
      replacedTransitionIds: _replacedTransitionIds,
      provenance: _provenance,
      sourceWasDeterministic: _sourceWasDeterministic,
      normalizedIsDeterministic: normalizedIsDeterministic,
      warnings: [for (final warning in structuredWarnings) warning.stableCode],
      structuredWarnings: structuredWarnings,
    );
  }

  bool get _usesBottomExit => sourceMode != PDAAcceptanceMode.finalState;

  bool get _usesDrainState =>
      sourceMode == PDAAcceptanceMode.finalState &&
      targetMode != PDAAcceptanceMode.finalState;

  State _addState({
    required String role,
    required String label,
    required Vector2 position,
    required StructuredMessage descriptionMessage,
    bool isInitial = false,
    bool isAccepting = false,
    String? sourceStateId,
  }) {
    final state = State(
      id: _freshStateId(role),
      label: _freshStateLabel(label),
      position: position,
      isInitial: isInitial,
      isAccepting: isAccepting,
      type: isInitial
          ? StateType.initial
          : isAccepting
          ? StateType.accepting
          : StateType.normal,
    );
    _addedStates.add(state);
    _provenance[state.id] = PDANormalizationProvenance(
      generatedId: state.id,
      description: descriptionMessage.stableCode,
      descriptionMessage: descriptionMessage,
      sourceStateId: sourceStateId,
    );
    return state;
  }

  PDATransition _addTransition({
    required String role,
    required State fromState,
    required State toState,
    required String popSymbol,
    required List<String> pushSymbols,
    required StructuredMessage descriptionMessage,
    String inputSymbol = '',
    bool isLambdaInput = true,
    TransitionType type = TransitionType.epsilon,
    Vector2? controlPoint,
    String? sourceStateId,
    String? sourceTransitionId,
  }) {
    final isLambdaPush = pushSymbols.isEmpty;
    final transition = PDATransition(
      id: _freshTransitionId(role),
      fromState: fromState,
      toState: toState,
      label: PDATransition.formatLabel(
        inputSymbol: inputSymbol,
        popSymbol: popSymbol,
        pushSymbol: pushSymbols.join(),
        isLambdaInput: isLambdaInput,
        isLambdaPop: false,
        isLambdaPush: isLambdaPush,
      ),
      controlPoint: controlPoint,
      type: type,
      inputSymbol: inputSymbol,
      popSymbol: popSymbol,
      pushSymbol: pushSymbols.join(),
      pushSymbols: pushSymbols,
      isLambdaInput: isLambdaInput,
      isLambdaPop: false,
      isLambdaPush: isLambdaPush,
    );
    _addedTransitions.add(transition);
    _provenance[transition.id] = PDANormalizationProvenance(
      generatedId: transition.id,
      description: descriptionMessage.stableCode,
      descriptionMessage: descriptionMessage,
      sourceStateId: sourceStateId,
      sourceTransitionId: sourceTransitionId,
    );
    return transition;
  }

  String _freshStateId(String role) {
    final base = '${source.id}/normalization/state/$role';
    var candidate = base;
    while (!_usedStateIds.add(candidate)) {
      candidate = '${base}_${++_generatedStateSequence}';
    }
    return candidate;
  }

  String _freshStateLabel(String base) {
    var candidate = base;
    var suffix = 0;
    while (!_usedStateLabels.add(candidate)) {
      candidate = '${base}_${++suffix}';
    }
    return candidate;
  }

  String _freshTransitionId(String role) {
    final base =
        '${source.id}/normalization/transition/${_transitionSequence++}_$role';
    var candidate = base;
    var suffix = 0;
    while (!_usedTransitionIds.add(candidate)) {
      candidate = '${base}_${++suffix}';
    }
    return candidate;
  }
}

String _freshStackSymbol(Set<String> existing, String base) {
  var candidate = base;
  var suffix = 0;
  while (existing.contains(candidate)) {
    candidate = '${base}_${++suffix}';
  }
  return candidate;
}

int _compareTransitions(PDATransition left, PDATransition right) {
  final byId = left.id.compareTo(right.id);
  if (byId != 0) return byId;
  final leftKey =
      '${left.fromState.id}\u0000${left.toState.id}\u0000'
      '${left.inputSymbol}\u0000${left.popSymbol}\u0000${left.pushSymbol}';
  final rightKey =
      '${right.fromState.id}\u0000${right.toState.id}\u0000'
      '${right.inputSymbol}\u0000${right.popSymbol}\u0000${right.pushSymbol}';
  return leftKey.compareTo(rightKey);
}

Vector2 Function() _generatedPositionFactory(Set<State> states) {
  var maxX = 0.0;
  var maxY = 0.0;
  for (final state in states) {
    maxX = math.max(maxX, state.position.x);
    maxY = math.max(maxY, state.position.y);
  }
  var index = 0;
  return () {
    final position = Vector2(maxX + (index * 120), maxY + 120);
    index++;
    return position;
  };
}

math.Rectangle<double> _expandedBounds(
  math.Rectangle<num> sourceBounds,
  Set<State> states,
) {
  var right = sourceBounds.right.toDouble();
  var bottom = sourceBounds.bottom.toDouble();
  for (final state in states) {
    right = math.max(right, state.position.x + 80);
    bottom = math.max(bottom, state.position.y + 80);
  }
  return math.Rectangle<double>(
    sourceBounds.left.toDouble(),
    sourceBounds.top.toDouble(),
    math.max(sourceBounds.width.toDouble(), right - sourceBounds.left),
    math.max(sourceBounds.height.toDouble(), bottom - sourceBounds.top),
  );
}

bool _isDeterministic(PDA pda) {
  final transitionsByState = <String, List<PDATransition>>{};
  for (final transition in pda.pdaTransitions) {
    transitionsByState
        .putIfAbsent(transition.fromState.id, () => <PDATransition>[])
        .add(transition);
  }

  for (final transitions in transitionsByState.values) {
    for (var leftIndex = 0; leftIndex < transitions.length; leftIndex++) {
      final left = transitions[leftIndex];
      for (
        var rightIndex = leftIndex + 1;
        rightIndex < transitions.length;
        rightIndex++
      ) {
        final right = transitions[rightIndex];
        final inputOverlaps =
            left.isLambdaInput ||
            right.isLambdaInput ||
            left.inputSymbol == right.inputSymbol;
        final stackOverlaps =
            _hasLambdaPop(left) ||
            _hasLambdaPop(right) ||
            left.popSymbol == right.popSymbol;
        if (inputOverlaps && stackOverlaps) return false;
      }
    }
  }
  return true;
}

bool _hasLambdaPop(PDATransition transition) =>
    transition.isLambdaPop || isEpsilonSymbol(transition.popSymbol);

bool _hasLambdaPush(PDATransition transition) =>
    transition.isLambdaPush || isEpsilonSymbol(transition.pushSymbol);
