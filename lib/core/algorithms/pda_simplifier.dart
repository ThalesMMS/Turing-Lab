import 'dart:collection';
import 'dart:convert';

import '../models/pda.dart';
import '../models/pda_simplification.dart';
import '../models/pda_transition.dart';
import '../models/state.dart';
import '../models/transition.dart';
import '../result.dart';
import 'pda_simulator.dart';

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
    if (validationError != null) return Failure(validationError);

    final phases = <PDASimplificationPhaseResult>[
      const PDASimplificationPhaseResult(
        phase: PDASimplificationPhase.validation,
        status: PDASimplificationPhaseStatus.completed,
        description: 'The PDA and its active acceptance mode are valid.',
      ),
    ];
    final changes = <PDASimplificationChange>[];
    final warnings = <String>[];
    final originalPda = PDA.fromJson(pda.toJson());

    final reachableStateIds = _structurallyReachableStateIds(pda);
    final unreachableStates = pda.states
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
    phases.add(
      PDASimplificationPhaseResult(
        phase: PDASimplificationPhase.structuralReachability,
        status: PDASimplificationPhaseStatus.completed,
        description: unreachableStates.isEmpty
            ? 'Every control state is structurally reachable.'
            : 'Removed ${unreachableStates.length} structurally unreachable '
                'control state(s).',
      ),
    );

    if (options.enableSemanticUsefulness) {
      const warning = 'Exact semantic usefulness analysis is unavailable for '
          'general NPDAs; uncertain states were retained.';
      warnings.add(warning);
      phases.add(
        const PDASimplificationPhaseResult(
          phase: PDASimplificationPhase.semanticUsefulness,
          status: PDASimplificationPhaseStatus.skipped,
          description: warning,
        ),
      );
    } else {
      phases.add(
        const PDASimplificationPhaseResult(
          phase: PDASimplificationPhase.semanticUsefulness,
          status: PDASimplificationPhaseStatus.skipped,
          description: 'Semantic usefulness analysis was disabled.',
        ),
      );
    }

    final reachableStates = pda.states
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
      phases.add(
        const PDASimplificationPhaseResult(
          phase: PDASimplificationPhase.strongBisimulation,
          status: PDASimplificationPhaseStatus.completed,
          description: 'Computed the fixed-point strong-bisimulation quotient.',
        ),
      );
    } else {
      phases.add(
        const PDASimplificationPhaseResult(
          phase: PDASimplificationPhase.strongBisimulation,
          status: PDASimplificationPhaseStatus.skipped,
          description: 'Strong-bisimulation quotienting was disabled.',
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
      return Failure('Simplification produced an invalid PDA: $rebuiltError');
    }
    phases.add(
      const PDASimplificationPhaseResult(
        phase: PDASimplificationPhase.rebuildValidation,
        status: PDASimplificationPhaseStatus.completed,
        description: 'The rebuilt PDA passed structural and mode validation.',
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
      if (comparison.isFailure) return Failure(comparison.error!);
      sampledEvidence = comparison.data!;
      phases.add(
        const PDASimplificationPhaseResult(
          phase: PDASimplificationPhase.boundedLanguageCheck,
          status: PDASimplificationPhaseStatus.completed,
          description: 'The requested finite sample had no mismatch.',
        ),
      );
    } else {
      phases.add(
        const PDASimplificationPhaseResult(
          phase: PDASimplificationPhase.boundedLanguageCheck,
          status: PDASimplificationPhaseStatus.skipped,
          description: 'No bounded language comparison was requested.',
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

  static String? _validate(
    PDA pda,
    PDAAcceptanceMode acceptanceMode,
    PDASimplificationOptions options,
  ) {
    // A missing self-loop control point is a canvas-layout concern and does
    // not make the transition relation semantically invalid.
    final errors = pda
        .validate()
        .where(
          (error) => !error
              .endsWith('Self-loop transitions must have a control point'),
        )
        .toList();
    if (pda.initialState == null) {
      errors.add('PDA must define an initial state.');
    }
    if ((acceptanceMode == PDAAcceptanceMode.finalState ||
            acceptanceMode == PDAAcceptanceMode.both) &&
        pda.acceptingStates.isEmpty) {
      errors.add(
        'The selected acceptance mode requires at least one accepting state.',
      );
    }
    if (pda.alphabet.any((symbol) => symbol.isEmpty)) {
      errors.add('The input alphabet must not contain an empty symbol.');
    }
    if (pda.stackAlphabet.any((symbol) => symbol.isEmpty)) {
      errors.add('The stack alphabet must not contain an empty symbol.');
    }
    for (final transition in pda.pdaTransitions) {
      if (!transition.isLambdaInput &&
          !pda.alphabet.contains(transition.inputSymbol)) {
        errors.add(
          'Transition ${transition.id} references an input symbol outside '
          'the PDA alphabet.',
        );
      }
    }
    final transitionIds = <String>{};
    for (final transition in pda.transitions) {
      if (!transitionIds.add(transition.id)) {
        errors.add('Transition IDs must be unique: ${transition.id}.');
      }
    }
    if (options.boundedCheck case final check?) {
      if (check.maxLength < 0) {
        errors.add('Bounded comparison length must not be negative.');
      }
      if (check.alphabet.any((symbol) => symbol.isEmpty)) {
        errors.add('Bounded comparison symbols must not be empty.');
      }
      final unknownSymbols = check.alphabet.difference(pda.alphabet);
      if (unknownSymbols.isNotEmpty) {
        errors.add(
          'Bounded comparison alphabet contains symbols outside the PDA '
          'alphabet: ${unknownSymbols.toList()..sort()}.',
        );
      }
    }
    return errors.isEmpty ? null : errors.join(' ');
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
        final behaviors = (outgoing[state.id] ?? const <PDATransition>[])
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
          .putIfAbsent(
            representativeByStateId[state.id]!,
            () => <String>[],
          )
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
    final acceptingStates =
        rebuiltStates.where((state) => state.isAccepting).toSet();
    return source.copyWith(
      states: rebuiltStates,
      transitions: rebuiltTransitions.cast<Transition>(),
      initialState: rebuiltStateById[source.initialState!.id],
      acceptingStates: acceptingStates,
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
      final simplifiedResult =
          PDASimulator.simulateNPDA(simplified, word, mode: mode);
      if (sourceResult.isFailure || simplifiedResult.isFailure) {
        return Failure(
          'Bounded comparison was inconclusive for "$word": '
          '${sourceResult.error ?? simplifiedResult.error}',
        );
      }
      final sourceSimulation = sourceResult.data!;
      final simplifiedSimulation = simplifiedResult.data!;
      if (_isInconclusive(sourceSimulation.errorMessage) ||
          _isInconclusive(simplifiedSimulation.errorMessage)) {
        return Failure(
          'Bounded comparison reached a simulation limit for "$word".',
        );
      }
      if (sourceSimulation.accepted != simplifiedSimulation.accepted) {
        return Failure(
          'Bounded comparison found an acceptance mismatch for "$word".',
        );
      }
    }
    return Success(
      PDASampledEvidence(
        wordsChecked: words.length,
        description: 'Finite sample comparison passed for ${words.length} '
            'word(s); this sampled evidence is not a proof of equivalence.',
      ),
    );
  }

  static bool _isInconclusive(String? errorMessage) =>
      errorMessage == PDA_SIMULATION_TIMEOUT_ERROR ||
      errorMessage == PDA_SIMULATION_INFINITE_LOOP_ERROR ||
      errorMessage == PDA_SIMULATION_LIMIT_REACHED_ERROR;

  static int _compareStates(State left, State right) =>
      left.id.compareTo(right.id);

  static int _compareTransitions(
    PDATransition left,
    PDATransition right,
  ) =>
      left.id.compareTo(right.id);
}
