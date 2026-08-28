import 'dart:collection';
import 'dart:convert';

import '../models/pda.dart';
import '../models/pda_simplification.dart';
import '../models/pda_transition.dart';
import '../models/state.dart';
import '../models/transition.dart';
import '../messages/structured_message.dart';
import '../result.dart';
import 'pda_simulator.dart';
import 'pda_simplification_messages.dart';

const _ignoredValidationSuffix =
    'Self-loop transitions must have a control point';

/// Conservative, mode-aware reductions for pushdown automata.
///
/// This service deliberately does not claim to compute a globally minimal
/// NPDA. It only removes structurally unreachable control states and, when
/// enabled, quotients control states under strong bisimulation.
class PDASimplifier {
  const PDASimplifier._();

  static Result<PDASimplificationResult> simplify(
    PDA pda, {
    required PDAAcceptanceMode acceptanceMode,
    PDASimplificationOptions options = const PDASimplificationOptions(),
  }) {
    final validationError = _validate(pda, acceptanceMode, options);
    if (validationError != null) {
      return Failure(
        validationError.message.stableCode,
        structuredMessage: validationError.message,
      );
    }

    final validationMessage = PdaSimplificationMessages.validationComplete();
    final phases = <PDASimplificationPhaseResult>[
      PDASimplificationPhaseResult(
        phase: PDASimplificationPhase.validation,
        status: PDASimplificationPhaseStatus.completed,
        description: validationMessage.stableCode,
        descriptionMessage: validationMessage,
      ),
    ];
    final changes = <PDASimplificationChange>[];
    final warnings = <String>[];
    final structuredWarnings = <StructuredMessage>[];
    final originalPda = PDA.fromJson(pda.toJson());

    final reachableStateIds = _structurallyReachableStateIds(pda);
    final unreachableStates =
        pda.states
            .where((state) => !reachableStateIds.contains(state.id))
            .toList()
          ..sort(_compareStates);
    for (final state in unreachableStates) {
      changes.add(
        PDASimplificationChange(
          kind: PDASimplificationChangeKind.removedState,
          reason: PDASimplificationChangeReason.unreachableControlState,
          sourceIds: [state.id],
        ),
      );
    }

    final reachableTransitions = <PDATransition>[];
    final incidentTransitions = <PDATransition>[];
    for (final transition in pda.pdaTransitions) {
      if (reachableStateIds.contains(transition.fromState.id) &&
          reachableStateIds.contains(transition.toState.id)) {
        reachableTransitions.add(transition);
      } else {
        incidentTransitions.add(transition);
      }
    }
    reachableTransitions.sort(_compareTransitions);
    incidentTransitions.sort(_compareTransitions);
    for (final transition in incidentTransitions) {
      changes.add(
        PDASimplificationChange(
          kind: PDASimplificationChangeKind.removedTransition,
          reason: PDASimplificationChangeReason.incidentToUnreachableState,
          sourceIds: [transition.id],
        ),
      );
    }
    final reachabilityMessage = unreachableStates.isEmpty
        ? PdaSimplificationMessages.everyStateReachable()
        : PdaSimplificationMessages.removedUnreachableStates(
            unreachableStates.length,
          );
    phases.add(
      PDASimplificationPhaseResult(
        phase: PDASimplificationPhase.structuralReachability,
        status: PDASimplificationPhaseStatus.completed,
        description: reachabilityMessage.stableCode,
        descriptionMessage: reachabilityMessage,
      ),
    );

    if (options.enableSemanticUsefulness) {
      final warning = PdaSimplificationMessages.semanticUsefulnessUnavailable();
      warnings.add(warning.stableCode);
      structuredWarnings.add(warning);
      phases.add(
        PDASimplificationPhaseResult(
          phase: PDASimplificationPhase.semanticUsefulness,
          status: PDASimplificationPhaseStatus.skipped,
          description: warning.stableCode,
          descriptionMessage: warning,
        ),
      );
    } else {
      final disabled = PdaSimplificationMessages.semanticUsefulnessDisabled();
      phases.add(
        PDASimplificationPhaseResult(
          phase: PDASimplificationPhase.semanticUsefulness,
          status: PDASimplificationPhaseStatus.skipped,
          description: disabled.stableCode,
          descriptionMessage: disabled,
        ),
      );
    }

    final reachableStates =
        pda.states
            .where((state) => reachableStateIds.contains(state.id))
            .toList()
          ..sort(_compareStates);
    final representativeByStateId = <String, String>{
      for (final state in reachableStates) state.id: state.id,
    };

    if (options.enableStrongBisimulation) {
      final blocks = _strongBisimulationBlocks(
        reachableStates,
        reachableTransitions,
        pda,
        acceptanceMode,
      );
      for (final block in blocks.where((block) => block.length > 1)) {
        final representativeId = block.first;
        for (final stateId in block) {
          representativeByStateId[stateId] = representativeId;
        }
        changes.add(
          PDASimplificationChange(
            kind: PDASimplificationChangeKind.mergedState,
            reason: PDASimplificationChangeReason.bisimilarControlStates,
            sourceIds: block,
            representativeId: representativeId,
          ),
        );
      }
      final computed = PdaSimplificationMessages.strongBisimulationComputed();
      phases.add(
        PDASimplificationPhaseResult(
          phase: PDASimplificationPhase.strongBisimulation,
          status: PDASimplificationPhaseStatus.completed,
          description: computed.stableCode,
          descriptionMessage: computed,
        ),
      );
    } else {
      final disabled = PdaSimplificationMessages.strongBisimulationDisabled();
      phases.add(
        PDASimplificationPhaseResult(
          phase: PDASimplificationPhase.strongBisimulation,
          status: PDASimplificationPhaseStatus.skipped,
          description: disabled.stableCode,
          descriptionMessage: disabled,
        ),
      );
    }

    final rebuilt = _rebuild(
      pda,
      acceptanceMode,
      reachableStates,
      reachableTransitions,
      representativeByStateId,
      changes,
    );
    final rebuiltError = _validate(rebuilt, acceptanceMode, options);
    if (rebuiltError != null) {
      final message = PdaSimplificationMessages.invalidRebuiltPda();
      return Failure(message.stableCode, structuredMessage: message);
    }
    final rebuildMessage =
        PdaSimplificationMessages.rebuildValidationComplete();
    phases.add(
      PDASimplificationPhaseResult(
        phase: PDASimplificationPhase.rebuildValidation,
        status: PDASimplificationPhaseStatus.completed,
        description: rebuildMessage.stableCode,
        descriptionMessage: rebuildMessage,
      ),
    );

    PDASampledEvidence? sampledEvidence;
    if (options.boundedCheck case final check?) {
      final comparison = _runBoundedComparison(
        pda,
        rebuilt,
        acceptanceMode,
        check,
      );
      if (comparison.isFailure) {
        return Failure(
          comparison.error!,
          structuredMessage: comparison.structuredError,
        );
      }
      sampledEvidence = comparison.data!;
      final sampleMessage = PdaSimplificationMessages.boundedSamplePassed(
        sampledEvidence.wordsChecked,
      );
      phases.add(
        PDASimplificationPhaseResult(
          phase: PDASimplificationPhase.boundedLanguageCheck,
          status: PDASimplificationPhaseStatus.completed,
          description: sampleMessage.stableCode,
          descriptionMessage: sampleMessage,
        ),
      );
    } else {
      final disabled = PdaSimplificationMessages.boundedComparisonDisabled();
      phases.add(
        PDASimplificationPhaseResult(
          phase: PDASimplificationPhase.boundedLanguageCheck,
          status: PDASimplificationPhaseStatus.skipped,
          description: disabled.stableCode,
          descriptionMessage: disabled,
        ),
      );
    }

    return Success(
      PDASimplificationResult(
        originalPda: originalPda,
        simplifiedPda: rebuilt,
        acceptanceMode: acceptanceMode,
        phases: phases,
        changes: changes,
        warnings: warnings,
        structuredWarnings: structuredWarnings,
        counts: PDASimplificationCounts(
          statesBefore: pda.states.length,
          statesAfter: rebuilt.states.length,
          transitionsBefore: pda.transitions.length,
          transitionsAfter: rebuilt.transitions.length,
        ),
        sampledEvidence: sampledEvidence,
      ),
    );
  }

  static _PdaSimplificationValidation? _validate(
    PDA pda,
    PDAAcceptanceMode acceptanceMode,
    PDASimplificationOptions options,
  ) {
    if (pda.states.isEmpty) {
      return _validation(PdaSimplificationMessages.emptyPda());
    }
    final initialState = pda.initialState;
    if (initialState == null) {
      return _validation(PdaSimplificationMessages.missingInitialState());
    }
    if (!pda.states.contains(initialState)) {
      return _validation(PdaSimplificationMessages.initialStateOutsideSet());
    }
    if ((acceptanceMode == PDAAcceptanceMode.finalState ||
            acceptanceMode == PDAAcceptanceMode.both) &&
        pda.acceptingStates.isEmpty) {
      return _validation(
        PdaSimplificationMessages.missingAcceptingState(acceptanceMode),
      );
    }
    if (pda.acceptingStates.any((state) => !pda.states.contains(state))) {
      return _validation(PdaSimplificationMessages.acceptingStateOutsideSet());
    }

    for (final transition in pda.transitions) {
      if (transition is! PDATransition) {
        return _validation(PdaSimplificationMessages.nonPdaTransition());
      }
      if (!pda.states.contains(transition.fromState) ||
          !pda.states.contains(transition.toState)) {
        return _validation(
          PdaSimplificationMessages.transitionEndpointOutsideSet(transition.id),
        );
      }
      final transitionErrors = transition
          .validate()
          .where((error) => !error.endsWith(_ignoredValidationSuffix))
          .toList(growable: false);
      if (transitionErrors.isNotEmpty) {
        return _validation(
          PdaSimplificationMessages.invalidTransition(transition.id),
        );
      }
    }

    // A missing self-loop control point is a canvas-layout concern and does
    // not make the transition relation semantically invalid.
    final errors = pda
        .validate()
        .where((error) => !error.endsWith(_ignoredValidationSuffix))
        .toList();
    if (errors.isNotEmpty) {
      return _validation(PdaSimplificationMessages.invalidPda());
    }
    if (pda.alphabet.any((symbol) => symbol.isEmpty)) {
      return _validation(PdaSimplificationMessages.inputAlphabetSymbolEmpty());
    }
    if (pda.stackAlphabet.any((symbol) => symbol.isEmpty)) {
      return _validation(PdaSimplificationMessages.stackAlphabetSymbolEmpty());
    }
    for (final transition in pda.pdaTransitions) {
      if (!transition.isLambdaInput &&
          !pda.alphabet.contains(transition.inputSymbol)) {
        return _validation(
          PdaSimplificationMessages.transitionInputSymbolOutsideAlphabet(
            transition.id,
            transition.inputSymbol,
          ),
        );
      }
    }
    final transitionIds = <String>{};
    for (final transition in pda.transitions) {
      if (!transitionIds.add(transition.id)) {
        return _validation(
          PdaSimplificationMessages.duplicateTransitionIds(transition.id),
        );
      }
    }
    if (options.boundedCheck case final check?) {
      if (check.maxLength < 0) {
        return _validation(PdaSimplificationMessages.boundedLengthNegative());
      }
      if (check.alphabet.any((symbol) => symbol.isEmpty)) {
        return _validation(PdaSimplificationMessages.boundedSymbolsEmpty());
      }
      final unknownSymbols = check.alphabet.difference(pda.alphabet);
      if (unknownSymbols.isNotEmpty) {
        final symbol = unknownSymbols.toList()..sort();
        return _validation(
          PdaSimplificationMessages.boundedSymbolOutsideAlphabet(symbol.first),
        );
      }
    }
    return null;
  }

  static Set<String> _structurallyReachableStateIds(PDA pda) {
    final initial = pda.initialState!;
    final reachable = <String>{initial.id};
    final queue = Queue<String>()..add(initial.id);
    final destinations = <String, List<String>>{};
    for (final transition in pda.pdaTransitions) {
      destinations
          .putIfAbsent(transition.fromState.id, () => <String>[])
          .add(transition.toState.id);
    }
    for (final values in destinations.values) {
      values.sort();
    }
    while (queue.isNotEmpty) {
      final stateId = queue.removeFirst();
      for (final destinationId in destinations[stateId] ?? const <String>[]) {
        if (reachable.add(destinationId)) queue.add(destinationId);
      }
    }
    return reachable;
  }

  static List<List<String>> _strongBisimulationBlocks(
    List<State> states,
    List<PDATransition> transitions,
    PDA pda,
    PDAAcceptanceMode acceptanceMode,
  ) {
    var blockByStateId = <String, int>{};
    final roleGroups = <String, List<String>>{};
    for (final state in states) {
      roleGroups
          .putIfAbsent(
            _observableRole(state, pda, acceptanceMode),
            () => <String>[],
          )
          .add(state.id);
    }
    final roleKeys = roleGroups.keys.toList()..sort();
    for (var index = 0; index < roleKeys.length; index++) {
      for (final stateId in roleGroups[roleKeys[index]]!..sort()) {
        blockByStateId[stateId] = index;
      }
    }

    final outgoing = <String, List<PDATransition>>{};
    for (final transition in transitions) {
      outgoing
          .putIfAbsent(transition.fromState.id, () => <PDATransition>[])
          .add(transition);
    }

    while (true) {
      final signatures = <String, String>{};
      for (final state in states) {
        final behaviors =
            (outgoing[state.id] ?? const <PDATransition>[])
                .map(
                  (transition) => jsonEncode([
                    transition.inputSymbol,
                    transition.popSymbol,
                    transition.pushSymbols,
                    transition.isLambdaInput,
                    transition.isLambdaPop,
                    transition.isLambdaPush,
                    blockByStateId[transition.toState.id],
                  ]),
                )
                .toSet()
                .toList()
              ..sort();
        signatures[state.id] = jsonEncode([
          _observableRole(state, pda, acceptanceMode),
          behaviors,
        ]);
      }

      final signatureGroups = <String, List<String>>{};
      for (final state in states) {
        signatureGroups
            .putIfAbsent(signatures[state.id]!, () => <String>[])
            .add(state.id);
      }
      final signatureKeys = signatureGroups.keys.toList()..sort();
      final nextBlockByStateId = <String, int>{};
      for (var index = 0; index < signatureKeys.length; index++) {
        for (final stateId in signatureGroups[signatureKeys[index]]!..sort()) {
          nextBlockByStateId[stateId] = index;
        }
      }

      if (_samePartition(states, blockByStateId, nextBlockByStateId)) {
        blockByStateId = nextBlockByStateId;
        break;
      }
      blockByStateId = nextBlockByStateId;
    }

    final blocks = <int, List<String>>{};
    for (final state in states) {
      blocks
          .putIfAbsent(blockByStateId[state.id]!, () => <String>[])
          .add(state.id);
    }
    final result = blocks.values.map((block) => block..sort()).toList()
      ..sort((left, right) => left.first.compareTo(right.first));
    return result;
  }

  static String _observableRole(
    State state,
    PDA pda,
    PDAAcceptanceMode acceptanceMode,
  ) {
    final observesFinalState = acceptanceMode != PDAAcceptanceMode.emptyStack;
    return jsonEncode([
      state.id == pda.initialState!.id,
      observesFinalState && pda.acceptingStates.contains(state),
    ]);
  }

  static bool _samePartition(
    List<State> states,
    Map<String, int> left,
    Map<String, int> right,
  ) {
    for (final first in states) {
      for (final second in states) {
        if ((left[first.id] == left[second.id]) !=
            (right[first.id] == right[second.id])) {
          return false;
        }
      }
    }
    return true;
  }

  static PDA _rebuild(
    PDA source,
    PDAAcceptanceMode acceptanceMode,
    List<State> reachableStates,
    List<PDATransition> reachableTransitions,
    Map<String, String> representativeByStateId,
    List<PDASimplificationChange> changes,
  ) {
    final sourceStateById = {
      for (final state in reachableStates) state.id: state,
    };
    final memberIdsByRepresentative = <String, List<String>>{};
    for (final state in reachableStates) {
      memberIdsByRepresentative
          .putIfAbsent(representativeByStateId[state.id]!, () => <String>[])
          .add(state.id);
    }

    final rebuiltStateById = <String, State>{};
    final observesFinalState = acceptanceMode != PDAAcceptanceMode.emptyStack;
    final representatives = memberIdsByRepresentative.keys.toList()..sort();
    for (final representativeId in representatives) {
      final memberIds = memberIdsByRepresentative[representativeId]!..sort();
      final sourceRepresentative = sourceStateById[representativeId]!;
      final isAccepting = memberIds.any(
        (id) => source.acceptingStates.contains(sourceStateById[id]),
      );
      rebuiltStateById[representativeId] = sourceRepresentative.copyWith(
        isInitial: representativeId == source.initialState!.id,
        isAccepting: observesFinalState
            ? source.acceptingStates.contains(sourceRepresentative)
            : isAccepting,
      );
    }

    final canonicalTransitionByKey = <String, PDATransition>{};
    for (final transition in reachableTransitions) {
      final fromId = representativeByStateId[transition.fromState.id]!;
      final toId = representativeByStateId[transition.toState.id]!;
      final canonical = transition.copyWith(
        fromState: rebuiltStateById[fromId],
        toState: rebuiltStateById[toId],
      );
      final key = _semanticTransitionKey(canonical);
      final existing = canonicalTransitionByKey[key];
      if (existing == null) {
        canonicalTransitionByKey[key] = canonical;
      } else {
        changes.add(
          PDASimplificationChange(
            kind: PDASimplificationChangeKind.removedTransition,
            reason: PDASimplificationChangeReason.duplicateTransition,
            sourceIds: [transition.id],
            representativeId: existing.id,
          ),
        );
      }
    }

    final rebuiltStates = rebuiltStateById.values.toSet();
    final rebuiltTransitions = canonicalTransitionByKey.values.toSet();
    final acceptingStates = rebuiltStates
        .where((state) => state.isAccepting)
        .toSet();
    return source.copyWith(
      states: rebuiltStates,
      transitions: rebuiltTransitions.cast<Transition>(),
      initialState: rebuiltStateById[source.initialState!.id],
      acceptingStates: acceptingStates,
      acceptanceMode: acceptanceMode,
      modified: changes.isEmpty ? source.modified : DateTime.now(),
    );
  }

  static String _semanticTransitionKey(PDATransition transition) => jsonEncode([
    transition.fromState.id,
    transition.toState.id,
    transition.inputSymbol,
    transition.popSymbol,
    transition.pushSymbols,
    transition.isLambdaInput,
    transition.isLambdaPop,
    transition.isLambdaPush,
  ]);

  static Result<PDASampledEvidence> _runBoundedComparison(
    PDA source,
    PDA simplified,
    PDAAcceptanceMode mode,
    PDABoundedLanguageCheck check,
  ) {
    final alphabet = check.alphabet.toList()..sort();
    final words = <String>[''];
    var frontier = <String>[''];
    for (var length = 1; length <= check.maxLength; length++) {
      final next = <String>[];
      for (final prefix in frontier) {
        for (final symbol in alphabet) {
          next.add('$prefix$symbol');
        }
      }
      words.addAll(next);
      frontier = next;
    }

    for (final word in words) {
      final sourceResult = PDASimulator.simulateNPDA(source, word, mode: mode);
      final simplifiedResult = PDASimulator.simulateNPDA(
        simplified,
        word,
        mode: mode,
      );
      if (sourceResult.isFailure || simplifiedResult.isFailure) {
        final message = PdaSimplificationMessages.boundedComparisonInconclusive(
          word,
        );
        return Failure(message.stableCode, structuredMessage: message);
      }
      final sourceSimulation = sourceResult.data!;
      final simplifiedSimulation = simplifiedResult.data!;
      if (sourceSimulation.isInconclusive ||
          simplifiedSimulation.isInconclusive) {
        final message =
            PdaSimplificationMessages.boundedComparisonSimulationLimit(word);
        return Failure(message.stableCode, structuredMessage: message);
      }
      if (sourceSimulation.accepted != simplifiedSimulation.accepted) {
        final message =
            PdaSimplificationMessages.boundedComparisonAcceptanceMismatch(word);
        return Failure(message.stableCode, structuredMessage: message);
      }
    }
    final message = PdaSimplificationMessages.boundedSamplePassed(words.length);
    return Success(
      PDASampledEvidence(
        wordsChecked: words.length,
        description: message.stableCode,
        descriptionMessage: message,
      ),
    );
  }

  static int _compareStates(State left, State right) =>
      left.id.compareTo(right.id);

  static int _compareTransitions(PDATransition left, PDATransition right) =>
      left.id.compareTo(right.id);
}

final class _PdaSimplificationValidation {
  const _PdaSimplificationValidation(this.message);

  final StructuredMessage message;
}

_PdaSimplificationValidation _validation(StructuredMessage message) =>
    _PdaSimplificationValidation(message);
