import 'dart:math' as math;

import 'package:vector_math/vector_math_64.dart';

import '../annotations/annotations.dart';
import '../models/fsa.dart';
import '../models/fsa_transition.dart';
import '../models/pda.dart';
import '../models/state.dart';
import '../models/tm.dart';
import '../models/tm_building_blocks.dart';
import '../models/transition.dart';
import '../transducers/transducers.dart';

enum AutomatonFragmentKind { fsa, pda, tm, mealy, moore }

enum AutomatonFragmentOperation {
  disconnected,
  connector,
  algebraic,
  replaceDocument,
}

enum ImportedInitialStatePolicy { reject, keepDestination, useImported }

enum PdaConflictResolution { reject, useDestination }

enum AutomatonFragmentDiagnosticSeverity { information, warning, blocking }

enum AutomatonFragmentDiagnosticCode {
  emptyFragment,
  incompatibleDocumentType,
  unsupportedOperation,
  danglingTransition,
  initialStateConflict,
  pdaAcceptanceModeConflict,
  pdaInitialStackSymbolConflict,
  tmTapeCountConflict,
  tmBlankSymbolConflict,
  connectorUnsupported,
  connectorEndpointMissing,
  annotationLimit,
  configurationNormalized,
}

final class AutomatonFragmentDiagnostic {
  const AutomatonFragmentDiagnostic({
    required this.code,
    required this.severity,
    required this.message,
    this.normalized,
    this.transitionId,
    this.connectorKind,
  });

  final AutomatonFragmentDiagnosticCode code;
  final AutomatonFragmentDiagnosticSeverity severity;
  final String message;
  final bool? normalized;
  final String? transitionId;
  final AutomatonFragmentKind? connectorKind;

  bool get isBlocking =>
      severity == AutomatonFragmentDiagnosticSeverity.blocking;
}

final class AutomatonFragmentSourceReference {
  const AutomatonFragmentSourceReference({
    required this.documentId,
    required this.elementId,
  });

  final String documentId;
  final String elementId;
}

final class FsaFragmentConnector {
  FsaFragmentConnector({
    required this.destinationStateId,
    required this.sourceStateId,
    Iterable<String> symbols = const [],
    this.lambdaSymbol,
  }) : symbols = Set<String>.unmodifiable(symbols);

  final String destinationStateId;
  final String sourceStateId;
  final Set<String> symbols;
  final String? lambdaSymbol;
}

final class AutomatonFragmentRequest {
  const AutomatonFragmentRequest({
    required this.destination,
    required this.source,
    this.destinationAnnotations,
    this.sourceAnnotations,
    this.destinationRevision,
    this.selectedStateIds,
    this.selectedTransitionIds,
    this.insertionAnchor,
    this.operation = AutomatonFragmentOperation.disconnected,
    this.initialStatePolicy = ImportedInitialStatePolicy.reject,
    this.pdaAcceptanceResolution = PdaConflictResolution.reject,
    this.pdaInitialStackResolution = PdaConflictResolution.reject,
    this.fsaConnector,
    this.timestamp,
  });

  final Object destination;
  final Object source;
  final DocumentAnnotationCollection? destinationAnnotations;
  final DocumentAnnotationCollection? sourceAnnotations;
  final String? destinationRevision;
  final Set<String>? selectedStateIds;
  final Set<String>? selectedTransitionIds;
  final Vector2? insertionAnchor;
  final AutomatonFragmentOperation operation;
  final ImportedInitialStatePolicy initialStatePolicy;
  final PdaConflictResolution pdaAcceptanceResolution;
  final PdaConflictResolution pdaInitialStackResolution;
  final FsaFragmentConnector? fsaConnector;
  final DateTime? timestamp;
}

final class AutomatonFragmentPlan {
  AutomatonFragmentPlan({
    required this.kind,
    required this.destinationDocumentId,
    required this.sourceDocumentId,
    required this.preview,
    required Map<String, String> stateSourceMap,
    required Map<String, String> transitionSourceMap,
    required Map<String, String> annotationSourceMap,
    required Map<String, String> blockSourceMap,
    required Iterable<AutomatonFragmentDiagnostic> diagnostics,
    required Iterable<String> importedStateIds,
    required Iterable<String> importedTransitionIds,
    this.annotations,
  }) : stateSourceMap = Map<String, String>.unmodifiable(stateSourceMap),
       transitionSourceMap = Map<String, String>.unmodifiable(
         transitionSourceMap,
       ),
       annotationSourceMap = Map<String, String>.unmodifiable(
         annotationSourceMap,
       ),
       blockSourceMap = Map<String, String>.unmodifiable(blockSourceMap),
       diagnostics = List<AutomatonFragmentDiagnostic>.unmodifiable(
         diagnostics,
       ),
       importedStateIds = Set<String>.unmodifiable(importedStateIds),
       importedTransitionIds = Set<String>.unmodifiable(importedTransitionIds);

  final AutomatonFragmentKind kind;
  final String destinationDocumentId;
  final String sourceDocumentId;
  final Object? preview;
  final Map<String, String> stateSourceMap;
  final Map<String, String> transitionSourceMap;
  final Map<String, String> annotationSourceMap;
  final Map<String, String> blockSourceMap;
  final List<AutomatonFragmentDiagnostic> diagnostics;
  final Set<String> importedStateIds;
  final Set<String> importedTransitionIds;
  final DocumentAnnotationCollection? annotations;

  bool get canCommit =>
      preview != null &&
      diagnostics.every((diagnostic) => !diagnostic.isBlocking);

  /// Provenance indexed by each new stable element ID.
  Map<String, AutomatonFragmentSourceReference> get provenanceByImportedId =>
      Map.unmodifiable({
        for (final entry in stateSourceMap.entries)
          entry.value: AutomatonFragmentSourceReference(
            documentId: sourceDocumentId,
            elementId: entry.key,
          ),
        for (final entry in transitionSourceMap.entries)
          entry.value: AutomatonFragmentSourceReference(
            documentId: sourceDocumentId,
            elementId: entry.key,
          ),
        for (final entry in annotationSourceMap.entries)
          entry.value: AutomatonFragmentSourceReference(
            documentId: sourceDocumentId,
            elementId: entry.key,
          ),
        for (final entry in blockSourceMap.entries)
          entry.value: AutomatonFragmentSourceReference(
            documentId: sourceDocumentId,
            elementId: entry.key,
          ),
      });
}

abstract final class AutomatonFragmentCombiner {
  static AutomatonFragmentPlan prepare(AutomatonFragmentRequest request) {
    final destination = request.destination;
    final source = request.source;
    if (destination is FSA && source is FSA) {
      return _combineFsa(request, destination, source);
    }
    if (destination is PDA && source is PDA) {
      return _combinePda(request, destination, source);
    }
    if (destination is TM && source is TM) {
      return _combineTm(request, destination, source);
    }
    if (destination is MealyMachine && source is MealyMachine) {
      return _combineMealy(request, destination, source);
    }
    if (destination is MooreMachine && source is MooreMachine) {
      return _combineMoore(request, destination, source);
    }
    return _blocked(
      kind:
          _kindOf(destination) ?? _kindOf(source) ?? AutomatonFragmentKind.fsa,
      destinationId: _documentId(destination),
      sourceId: _documentId(source),
      code: AutomatonFragmentDiagnosticCode.incompatibleDocumentType,
      message: 'Only documents of the same graph model can be combined.',
    );
  }
}

AutomatonFragmentPlan _combineFsa(
  AutomatonFragmentRequest request,
  FSA destination,
  FSA source,
) {
  final prepared = _prepareAutomatonGraph(
    request: request,
    kind: AutomatonFragmentKind.fsa,
    destinationId: destination.id,
    sourceId: source.id,
    destinationStates: destination.states,
    sourceStates: source.states,
    destinationTransitions: destination.fsaTransitions,
    sourceTransitions: source.fsaTransitions,
    cloneTransition: (transition, id, from, to, delta) => transition.copyWith(
      id: id,
      fromState: from,
      toState: to,
      controlPoint: transition.controlPoint + delta,
    ),
  );
  if (!prepared.canContinue) return prepared.blockedPlan;

  final transitions = <Transition>{
    ...destination.transitions,
    ...prepared.transitions,
  };
  final diagnostics = [...prepared.diagnostics];
  if (request.operation == AutomatonFragmentOperation.connector) {
    final connector = request.fsaConnector;
    final from = prepared.statesById[connector?.destinationStateId];
    final importedTarget = prepared.stateSourceMap[connector?.sourceStateId];
    final to = importedTarget == null
        ? null
        : prepared.statesById[importedTarget];
    if (connector == null || from == null || to == null) {
      diagnostics.add(
        const AutomatonFragmentDiagnostic(
          code: AutomatonFragmentDiagnosticCode.connectorEndpointMissing,
          severity: AutomatonFragmentDiagnosticSeverity.blocking,
          message:
              'The connector must reference one destination state and one imported state.',
        ),
      );
    } else {
      final connectorId = _allocateId(
        'connector',
        transitions.map((transition) => transition.id).toSet(),
      );
      transitions.add(
        FSATransition(
          id: connectorId,
          fromState: from,
          toState: to,
          inputSymbols: connector.symbols,
          lambdaSymbol: connector.lambdaSymbol,
        ),
      );
    }
  }

  final states = prepared.statesById.values.toSet();
  final initial = states.where((state) => state.isInitial).firstOrNull;
  final result = destination.copyWith(
    states: states,
    transitions: transitions,
    alphabet: {
      ...destination.alphabet,
      ...source.alphabet,
      ...?request.fsaConnector?.symbols,
    },
    initialState: initial,
    acceptingStates: states.where((state) => state.isAccepting).toSet(),
    modified: request.timestamp ?? DateTime.now(),
    bounds: _automatonBounds(destination.bounds, states),
  );
  return prepared.finish(
    preview: result,
    diagnostics: diagnostics,
    request: request,
  );
}

AutomatonFragmentPlan _combinePda(
  AutomatonFragmentRequest request,
  PDA destination,
  PDA source,
) {
  final semanticDiagnostics = <AutomatonFragmentDiagnostic>[];
  if (destination.acceptanceMode != source.acceptanceMode) {
    final resolved =
        request.pdaAcceptanceResolution == PdaConflictResolution.useDestination;
    semanticDiagnostics.add(
      AutomatonFragmentDiagnostic(
        code: AutomatonFragmentDiagnosticCode.pdaAcceptanceModeConflict,
        severity: resolved
            ? AutomatonFragmentDiagnosticSeverity.warning
            : AutomatonFragmentDiagnosticSeverity.blocking,
        message: resolved
            ? 'Imported PDA acceptance is explicitly normalized to the destination mode.'
            : 'PDA acceptance modes differ and require an explicit conversion plan.',
        normalized: resolved,
      ),
    );
  }
  if (destination.initialStackSymbol != source.initialStackSymbol) {
    final resolved =
        request.pdaInitialStackResolution ==
        PdaConflictResolution.useDestination;
    semanticDiagnostics.add(
      AutomatonFragmentDiagnostic(
        code: AutomatonFragmentDiagnosticCode.pdaInitialStackSymbolConflict,
        severity: resolved
            ? AutomatonFragmentDiagnosticSeverity.warning
            : AutomatonFragmentDiagnosticSeverity.blocking,
        message: resolved
            ? 'Imported PDA stack initialization is explicitly normalized to the destination symbol.'
            : 'PDA initial stack symbols differ and require an explicit conversion plan.',
        normalized: resolved,
      ),
    );
  }
  if (semanticDiagnostics.any((diagnostic) => diagnostic.isBlocking)) {
    return _blockedWithDiagnostics(
      kind: AutomatonFragmentKind.pda,
      destinationId: destination.id,
      sourceId: source.id,
      diagnostics: semanticDiagnostics,
    );
  }
  if (request.operation == AutomatonFragmentOperation.connector) {
    return _blocked(
      kind: AutomatonFragmentKind.pda,
      destinationId: destination.id,
      sourceId: source.id,
      code: AutomatonFragmentDiagnosticCode.connectorUnsupported,
      connectorKind: AutomatonFragmentKind.pda,
      message:
          'PDA connector transitions require a typed stack-operation plan.',
    );
  }
  final prepared = _prepareAutomatonGraph(
    request: request,
    kind: AutomatonFragmentKind.pda,
    destinationId: destination.id,
    sourceId: source.id,
    destinationStates: destination.states,
    sourceStates: source.states,
    destinationTransitions: destination.pdaTransitions,
    sourceTransitions: source.pdaTransitions,
    initialDiagnostics: semanticDiagnostics,
    cloneTransition: (transition, id, from, to, delta) => transition.copyWith(
      id: id,
      fromState: from,
      toState: to,
      controlPoint: transition.controlPoint + delta,
    ),
  );
  if (!prepared.canContinue) return prepared.blockedPlan;
  final states = prepared.statesById.values.toSet();
  final result = destination.copyWith(
    states: states,
    transitions: <Transition>{
      ...destination.transitions,
      ...prepared.transitions,
    },
    alphabet: {...destination.alphabet, ...source.alphabet},
    stackAlphabet: {
      ...destination.stackAlphabet,
      ...source.stackAlphabet,
      destination.initialStackSymbol,
    },
    initialState: states.where((state) => state.isInitial).firstOrNull,
    acceptingStates: states.where((state) => state.isAccepting).toSet(),
    acceptanceMode: destination.acceptanceMode,
    modified: request.timestamp ?? DateTime.now(),
    bounds: _automatonBounds(destination.bounds, states),
  );
  return prepared.finish(preview: result, request: request);
}

AutomatonFragmentPlan _combineTm(
  AutomatonFragmentRequest request,
  TM destination,
  TM source,
) {
  final diagnostics = <AutomatonFragmentDiagnostic>[];
  if (destination.tapeCount != source.tapeCount) {
    diagnostics.add(
      const AutomatonFragmentDiagnostic(
        code: AutomatonFragmentDiagnosticCode.tmTapeCountConflict,
        severity: AutomatonFragmentDiagnosticSeverity.blocking,
        message:
            'Turing machines with different tape counts cannot be combined without an explicit conversion.',
      ),
    );
  }
  if (destination.blankSymbol != source.blankSymbol) {
    diagnostics.add(
      const AutomatonFragmentDiagnostic(
        code: AutomatonFragmentDiagnosticCode.tmBlankSymbolConflict,
        severity: AutomatonFragmentDiagnosticSeverity.blocking,
        message:
            'Turing machines with different blank symbols cannot be combined without an explicit conversion.',
      ),
    );
  }
  if (diagnostics.isNotEmpty) {
    return _blockedWithDiagnostics(
      kind: AutomatonFragmentKind.tm,
      destinationId: destination.id,
      sourceId: source.id,
      diagnostics: diagnostics,
    );
  }
  if (request.operation == AutomatonFragmentOperation.connector) {
    return _blocked(
      kind: AutomatonFragmentKind.tm,
      destinationId: destination.id,
      sourceId: source.id,
      code: AutomatonFragmentDiagnosticCode.connectorUnsupported,
      connectorKind: AutomatonFragmentKind.tm,
      message:
          'TM connector transitions require one operation vector per tape.',
    );
  }
  final prepared = _prepareAutomatonGraph(
    request: request,
    kind: AutomatonFragmentKind.tm,
    destinationId: destination.id,
    sourceId: source.id,
    destinationStates: destination.states,
    sourceStates: source.states,
    destinationTransitions: destination.tmTransitions,
    sourceTransitions: source.tmTransitions,
    cloneTransition: (transition, id, from, to, delta) => transition.copyWith(
      id: id,
      fromState: from,
      toState: to,
      controlPoint: transition.controlPoint + delta,
    ),
  );
  if (!prepared.canContinue) return prepared.blockedPlan;

  final blockResult = _cloneTmBlocks(
    destination: destination,
    source: source,
    importedStateMap: prepared.stateSourceMap,
    includeAllDefinitions:
        prepared.stateSourceMap.length == source.states.length,
  );
  final states = prepared.statesById.values.toSet();
  final result = destination.copyWith(
    states: states,
    transitions: <Transition>{
      ...destination.transitions,
      ...prepared.transitions,
    },
    alphabet: {...destination.alphabet, ...source.alphabet},
    tapeAlphabet: {...destination.tapeAlphabet, ...source.tapeAlphabet},
    initialState: states.where((state) => state.isInitial).firstOrNull,
    acceptingStates: states.where((state) => state.isAccepting).toSet(),
    blockDefinitions: blockResult.definitions,
    blockInvocations: [
      ...destination.blockInvocations,
      ...blockResult.invocations,
    ],
    modified: request.timestamp ?? DateTime.now(),
    bounds: _automatonBounds(destination.bounds, states),
  );
  return prepared.finish(
    preview: result,
    request: request,
    blockSourceMap: blockResult.sourceMap,
  );
}

AutomatonFragmentPlan _combineMealy(
  AutomatonFragmentRequest request,
  MealyMachine destination,
  MealyMachine source,
) {
  if (request.operation == AutomatonFragmentOperation.algebraic ||
      request.operation == AutomatonFragmentOperation.replaceDocument) {
    return _blocked(
      kind: AutomatonFragmentKind.mealy,
      destinationId: destination.id.value,
      sourceId: source.id.value,
      code: AutomatonFragmentDiagnosticCode.unsupportedOperation,
      message:
          'Algebraic operations and document replacement use their dedicated workflows.',
    );
  }
  if (request.operation == AutomatonFragmentOperation.connector) {
    return _blocked(
      kind: AutomatonFragmentKind.mealy,
      destinationId: destination.id.value,
      sourceId: source.id.value,
      code: AutomatonFragmentDiagnosticCode.connectorUnsupported,
      connectorKind: AutomatonFragmentKind.mealy,
      message: 'Mealy connectors require an explicit input/output rule.',
    );
  }
  final selected = _selectedTransducerStates(request, source.states);
  final placement = _placement(
    destination.states.map((state) => state.position),
    selected.map((state) => state.position),
    request.insertionAnchor,
  );
  final stateMap = <String, String>{};
  final reservedStates = destination.states
      .map((state) => state.id.value)
      .toSet();
  final importedStates = <MealyState>[];
  for (final state in selected) {
    final id = _allocateImportedId(
      source.id.value,
      state.id.value,
      reservedStates,
    );
    stateMap[state.id.value] = id;
    importedStates.add(
      state.copyWith(
        id: TransducerStateId(id),
        position: TransducerPoint(
          state.position.x + placement.x,
          state.position.y + placement.y,
        ),
        isInitial: _importedInitial(
          sourceInitial: state.isInitial,
          destinationHasInitial: destination.states.any(
            (item) => item.isInitial,
          ),
          policy: request.initialStatePolicy,
        ),
      ),
    );
  }
  final initialConflict = _initialConflict(
    destination.states.any((state) => state.isInitial),
    selected.any((state) => state.isInitial),
    request.initialStatePolicy,
  );
  if (initialConflict != null) {
    return _blockedWithDiagnostics(
      kind: AutomatonFragmentKind.mealy,
      destinationId: destination.id.value,
      sourceId: source.id.value,
      diagnostics: [initialConflict],
    );
  }
  final destinationStates =
      request.initialStatePolicy == ImportedInitialStatePolicy.useImported &&
          importedStates.any((state) => state.isInitial)
      ? destination.states.map((state) => state.copyWith(isInitial: false))
      : destination.states;
  final transitionMap = <String, String>{};
  final reservedTransitions = destination.transitions
      .map((transition) => transition.id.value)
      .toSet();
  final selectedTransitionIds = request.selectedTransitionIds;
  final importedTransitions = <MealyTransition>[];
  for (final transition in source.transitions) {
    if (!stateMap.containsKey(transition.from.value) ||
        !stateMap.containsKey(transition.to.value) ||
        (selectedTransitionIds != null &&
            !selectedTransitionIds.contains(transition.id.value))) {
      continue;
    }
    final id = _allocateImportedId(
      source.id.value,
      transition.id.value,
      reservedTransitions,
    );
    transitionMap[transition.id.value] = id;
    importedTransitions.add(
      MealyTransition(
        id: TransducerTransitionId(id),
        from: TransducerStateId(stateMap[transition.from.value]!),
        to: TransducerStateId(stateMap[transition.to.value]!),
        input: transition.input,
        output: transition.output,
      ),
    );
  }
  final result = destination.copyWith(
    revision: TransducerRevision(destination.revision.value + 1),
    inputAlphabet: {...destination.inputAlphabet, ...source.inputAlphabet},
    outputAlphabet: {...destination.outputAlphabet, ...source.outputAlphabet},
    states: [...destinationStates, ...importedStates],
    transitions: [...destination.transitions, ...importedTransitions],
  );
  return _finishTransducer(
    request: request,
    kind: AutomatonFragmentKind.mealy,
    destinationId: destination.id.value,
    sourceId: source.id.value,
    preview: result,
    stateMap: stateMap,
    transitionMap: transitionMap,
    placement: placement,
  );
}

AutomatonFragmentPlan _combineMoore(
  AutomatonFragmentRequest request,
  MooreMachine destination,
  MooreMachine source,
) {
  if (request.operation == AutomatonFragmentOperation.algebraic ||
      request.operation == AutomatonFragmentOperation.replaceDocument) {
    return _blocked(
      kind: AutomatonFragmentKind.moore,
      destinationId: destination.id.value,
      sourceId: source.id.value,
      code: AutomatonFragmentDiagnosticCode.unsupportedOperation,
      message:
          'Algebraic operations and document replacement use their dedicated workflows.',
    );
  }
  if (request.operation == AutomatonFragmentOperation.connector) {
    return _blocked(
      kind: AutomatonFragmentKind.moore,
      destinationId: destination.id.value,
      sourceId: source.id.value,
      code: AutomatonFragmentDiagnosticCode.connectorUnsupported,
      connectorKind: AutomatonFragmentKind.moore,
      message: 'Moore connectors require an explicit input rule.',
    );
  }
  final selected = _selectedTransducerStates(request, source.states);
  final placement = _placement(
    destination.states.map((state) => state.position),
    selected.map((state) => state.position),
    request.insertionAnchor,
  );
  final initialConflict = _initialConflict(
    destination.states.any((state) => state.isInitial),
    selected.any((state) => state.isInitial),
    request.initialStatePolicy,
  );
  if (initialConflict != null) {
    return _blockedWithDiagnostics(
      kind: AutomatonFragmentKind.moore,
      destinationId: destination.id.value,
      sourceId: source.id.value,
      diagnostics: [initialConflict],
    );
  }
  final stateMap = <String, String>{};
  final reservedStates = destination.states
      .map((state) => state.id.value)
      .toSet();
  final importedStates = <MooreState>[];
  for (final state in selected) {
    final id = _allocateImportedId(
      source.id.value,
      state.id.value,
      reservedStates,
    );
    stateMap[state.id.value] = id;
    importedStates.add(
      state.copyWith(
        id: TransducerStateId(id),
        position: TransducerPoint(
          state.position.x + placement.x,
          state.position.y + placement.y,
        ),
        isInitial: _importedInitial(
          sourceInitial: state.isInitial,
          destinationHasInitial: destination.states.any(
            (item) => item.isInitial,
          ),
          policy: request.initialStatePolicy,
        ),
      ),
    );
  }
  final destinationStates =
      request.initialStatePolicy == ImportedInitialStatePolicy.useImported &&
          importedStates.any((state) => state.isInitial)
      ? destination.states.map((state) => state.copyWith(isInitial: false))
      : destination.states;
  final transitionMap = <String, String>{};
  final reservedTransitions = destination.transitions
      .map((transition) => transition.id.value)
      .toSet();
  final selectedTransitionIds = request.selectedTransitionIds;
  final importedTransitions = <MooreTransition>[];
  for (final transition in source.transitions) {
    if (!stateMap.containsKey(transition.from.value) ||
        !stateMap.containsKey(transition.to.value) ||
        (selectedTransitionIds != null &&
            !selectedTransitionIds.contains(transition.id.value))) {
      continue;
    }
    final id = _allocateImportedId(
      source.id.value,
      transition.id.value,
      reservedTransitions,
    );
    transitionMap[transition.id.value] = id;
    importedTransitions.add(
      MooreTransition(
        id: TransducerTransitionId(id),
        from: TransducerStateId(stateMap[transition.from.value]!),
        to: TransducerStateId(stateMap[transition.to.value]!),
        input: transition.input,
      ),
    );
  }
  final result = destination.copyWith(
    revision: TransducerRevision(destination.revision.value + 1),
    inputAlphabet: {...destination.inputAlphabet, ...source.inputAlphabet},
    outputAlphabet: {...destination.outputAlphabet, ...source.outputAlphabet},
    states: [...destinationStates, ...importedStates],
    transitions: [...destination.transitions, ...importedTransitions],
  );
  return _finishTransducer(
    request: request,
    kind: AutomatonFragmentKind.moore,
    destinationId: destination.id.value,
    sourceId: source.id.value,
    preview: result,
    stateMap: stateMap,
    transitionMap: transitionMap,
    placement: placement,
  );
}

typedef _TransitionCloner<T extends Transition> =
    T Function(T transition, String id, State from, State to, Vector2 delta);

final class _PreparedAutomatonGraph<T extends Transition> {
  _PreparedAutomatonGraph({
    required this.kind,
    required this.destinationId,
    required this.sourceId,
    required this.statesById,
    required this.transitions,
    required this.stateSourceMap,
    required this.transitionSourceMap,
    required this.importedStateIds,
    required this.importedTransitionIds,
    required this.delta,
    required this.diagnostics,
  });

  final AutomatonFragmentKind kind;
  final String destinationId;
  final String sourceId;
  final Map<String, State> statesById;
  final Set<T> transitions;
  final Map<String, String> stateSourceMap;
  final Map<String, String> transitionSourceMap;
  final Set<String> importedStateIds;
  final Set<String> importedTransitionIds;
  final Vector2 delta;
  final List<AutomatonFragmentDiagnostic> diagnostics;

  bool get canContinue =>
      diagnostics.every((diagnostic) => !diagnostic.isBlocking);

  AutomatonFragmentPlan get blockedPlan => _blockedWithDiagnostics(
    kind: kind,
    destinationId: destinationId,
    sourceId: sourceId,
    diagnostics: diagnostics,
  );

  AutomatonFragmentPlan finish({
    required Object preview,
    required AutomatonFragmentRequest request,
    Iterable<AutomatonFragmentDiagnostic>? diagnostics,
    Map<String, String> blockSourceMap = const {},
  }) {
    final annotations = _mergeAnnotations(
      request: request,
      destinationId: destinationId,
      stateMap: stateSourceMap,
      transitionMap: transitionSourceMap,
      delta: delta,
    );
    final combinedDiagnostics = <AutomatonFragmentDiagnostic>[
      ...(diagnostics ?? this.diagnostics),
      ...annotations.diagnostics,
    ];
    return AutomatonFragmentPlan(
      kind: kind,
      destinationDocumentId: destinationId,
      sourceDocumentId: sourceId,
      preview: combinedDiagnostics.any((diagnostic) => diagnostic.isBlocking)
          ? null
          : preview,
      stateSourceMap: stateSourceMap,
      transitionSourceMap: transitionSourceMap,
      annotationSourceMap: annotations.sourceMap,
      blockSourceMap: blockSourceMap,
      diagnostics: combinedDiagnostics,
      importedStateIds: importedStateIds,
      importedTransitionIds: importedTransitionIds,
      annotations: annotations.collection,
    );
  }
}

_PreparedAutomatonGraph<T> _prepareAutomatonGraph<T extends Transition>({
  required AutomatonFragmentRequest request,
  required AutomatonFragmentKind kind,
  required String destinationId,
  required String sourceId,
  required Iterable<State> destinationStates,
  required Iterable<State> sourceStates,
  required Iterable<T> destinationTransitions,
  required Iterable<T> sourceTransitions,
  required _TransitionCloner<T> cloneTransition,
  Iterable<AutomatonFragmentDiagnostic> initialDiagnostics = const [],
}) {
  final diagnostics = <AutomatonFragmentDiagnostic>[...initialDiagnostics];
  if (request.operation == AutomatonFragmentOperation.algebraic ||
      request.operation == AutomatonFragmentOperation.replaceDocument) {
    diagnostics.add(
      const AutomatonFragmentDiagnostic(
        code: AutomatonFragmentDiagnosticCode.unsupportedOperation,
        severity: AutomatonFragmentDiagnosticSeverity.blocking,
        message:
            'Algebraic operations and document replacement use their dedicated workflows.',
      ),
    );
  }
  final selectedIds = request.selectedStateIds;
  final selected = sourceStates
      .where((state) => selectedIds == null || selectedIds.contains(state.id))
      .toList(growable: false);
  if (selected.isEmpty) {
    diagnostics.add(
      const AutomatonFragmentDiagnostic(
        code: AutomatonFragmentDiagnosticCode.emptyFragment,
        severity: AutomatonFragmentDiagnosticSeverity.blocking,
        message: 'The selected fragment has no states.',
      ),
    );
  }
  final destinationList = destinationStates.toList(growable: false);
  final initialConflict = _initialConflict(
    destinationList.any((state) => state.isInitial),
    selected.any((state) => state.isInitial),
    request.initialStatePolicy,
  );
  if (initialConflict != null) diagnostics.add(initialConflict);

  final delta = _placement(
    destinationList.map((state) => state.position),
    selected.map((state) => state.position),
    request.insertionAnchor,
  );
  final statesById = <String, State>{
    for (final state in destinationList)
      state.id:
          request.initialStatePolicy ==
                  ImportedInitialStatePolicy.useImported &&
              selected.any((candidate) => candidate.isInitial)
          ? state.copyWith(isInitial: false)
          : state,
  };
  final stateMap = <String, String>{};
  final reservedStateIds = statesById.keys.toSet();
  for (final state in selected) {
    final id = _allocateImportedId(sourceId, state.id, reservedStateIds);
    final imported = state.copyWith(
      id: id,
      position: state.position + delta,
      isInitial: _importedInitial(
        sourceInitial: state.isInitial,
        destinationHasInitial: destinationList.any((item) => item.isInitial),
        policy: request.initialStatePolicy,
      ),
    );
    stateMap[state.id] = id;
    statesById[id] = imported;
  }

  final transitions = <T>{};
  final transitionMap = <String, String>{};
  final reservedTransitionIds = destinationTransitions
      .map((transition) => transition.id)
      .toSet();
  final selectedTransitionIds = request.selectedTransitionIds;
  for (final transition in sourceTransitions) {
    final fromId = stateMap[transition.fromState.id];
    final toId = stateMap[transition.toState.id];
    if (fromId == null || toId == null) continue;
    if (selectedTransitionIds != null &&
        !selectedTransitionIds.contains(transition.id)) {
      continue;
    }
    final from = statesById[fromId];
    final to = statesById[toId];
    if (from == null || to == null) {
      diagnostics.add(
        AutomatonFragmentDiagnostic(
          code: AutomatonFragmentDiagnosticCode.danglingTransition,
          severity: AutomatonFragmentDiagnosticSeverity.blocking,
          message:
              'Transition ${transition.id} has an endpoint outside the selected fragment.',
          transitionId: transition.id,
        ),
      );
      continue;
    }
    final id = _allocateImportedId(
      sourceId,
      transition.id,
      reservedTransitionIds,
    );
    transitionMap[transition.id] = id;
    transitions.add(cloneTransition(transition, id, from, to, delta));
  }
  return _PreparedAutomatonGraph<T>(
    kind: kind,
    destinationId: destinationId,
    sourceId: sourceId,
    statesById: statesById,
    transitions: transitions,
    stateSourceMap: stateMap,
    transitionSourceMap: transitionMap,
    importedStateIds: stateMap.values.toSet(),
    importedTransitionIds: transitionMap.values.toSet(),
    delta: delta,
    diagnostics: diagnostics,
  );
}

AutomatonFragmentDiagnostic? _initialConflict(
  bool destinationHasInitial,
  bool sourceHasInitial,
  ImportedInitialStatePolicy policy,
) {
  if (!destinationHasInitial ||
      !sourceHasInitial ||
      policy != ImportedInitialStatePolicy.reject) {
    return null;
  }
  return const AutomatonFragmentDiagnostic(
    code: AutomatonFragmentDiagnosticCode.initialStateConflict,
    severity: AutomatonFragmentDiagnosticSeverity.blocking,
    message:
        'Both fragments declare an initial state. Choose which initial state to retain.',
  );
}

bool _importedInitial({
  required bool sourceInitial,
  required bool destinationHasInitial,
  required ImportedInitialStatePolicy policy,
}) {
  if (!sourceInitial) return false;
  if (!destinationHasInitial) return true;
  return policy == ImportedInitialStatePolicy.useImported;
}

Vector2 _placement(
  Iterable<dynamic> destinationPositions,
  Iterable<dynamic> sourcePositions,
  Vector2? insertionAnchor,
) {
  final destination = destinationPositions.map(_point).toList(growable: false);
  final source = sourcePositions.map(_point).toList(growable: false);
  if (source.isEmpty) return Vector2.zero();
  final sourceMinX = source.map((point) => point.x).reduce(math.min);
  final sourceMinY = source.map((point) => point.y).reduce(math.min);
  final anchor =
      insertionAnchor ??
      (destination.isEmpty
          ? Vector2(80, 80)
          : Vector2(
              destination.map((point) => point.x).reduce(math.min),
              destination.map((point) => point.y).reduce(math.max) + 160,
            ));
  var delta = Vector2(anchor.x - sourceMinX, anchor.y - sourceMinY);
  while (_overlaps(destination, source, delta)) {
    delta += Vector2(80, 80);
  }
  return delta;
}

Vector2 _point(dynamic value) {
  if (value is Vector2) return value.clone();
  if (value is TransducerPoint) return Vector2(value.x, value.y);
  throw ArgumentError.value(value, 'position');
}

bool _overlaps(List<Vector2> destination, List<Vector2> source, Vector2 delta) {
  for (final left in destination) {
    for (final right in source) {
      final placed = right + delta;
      if ((left.x - placed.x).abs() < 80 && (left.y - placed.y).abs() < 80) {
        return true;
      }
    }
  }
  return false;
}

String _allocateImportedId(
  String documentId,
  String sourceId,
  Set<String> used,
) {
  final prefix = _safeId(documentId);
  return _allocateId('import_${prefix}_${_safeId(sourceId)}', used);
}

String _allocateId(String base, Set<String> used) {
  var candidate = base.isEmpty ? 'imported' : base;
  var suffix = 2;
  while (!used.add(candidate)) {
    candidate = '${base}_$suffix';
    suffix++;
  }
  return candidate;
}

String _safeId(String value) {
  final safe = value.trim().replaceAll(RegExp(r'[^A-Za-z0-9_.-]+'), '_');
  return safe.isEmpty ? 'document' : safe;
}

math.Rectangle<double> _automatonBounds(
  math.Rectangle<num> original,
  Iterable<State> states,
) {
  final values = states.toList(growable: false);
  if (values.isEmpty) {
    return math.Rectangle<double>(
      original.left.toDouble(),
      original.top.toDouble(),
      original.width.toDouble(),
      original.height.toDouble(),
    );
  }
  final minX = math.min(
    original.left.toDouble(),
    values.map((state) => state.position.x).reduce(math.min),
  );
  final minY = math.min(
    original.top.toDouble(),
    values.map((state) => state.position.y).reduce(math.min),
  );
  final maxX = math.max(
    original.right.toDouble(),
    values.map((state) => state.position.x + 80).reduce(math.max),
  );
  final maxY = math.max(
    original.bottom.toDouble(),
    values.map((state) => state.position.y + 80).reduce(math.max),
  );
  return math.Rectangle<double>(minX, minY, maxX - minX, maxY - minY);
}

({
  Map<String, TMBlockDefinition> definitions,
  List<TMBlockInvocationNode> invocations,
  Map<String, String> sourceMap,
})
_cloneTmBlocks({
  required TM destination,
  required TM source,
  required Map<String, String> importedStateMap,
  required bool includeAllDefinitions,
}) {
  final definitions = Map<String, TMBlockDefinition>.of(
    destination.blockDefinitions,
  );
  final selectedInvocations = source.blockInvocations
      .where((invocation) => importedStateMap.containsKey(invocation.stateId))
      .toList(growable: false);
  final requiredBlockIds = includeAllDefinitions
      ? source.blockDefinitions.keys.toSet()
      : _requiredTmBlockIds(source, selectedInvocations);
  final selectedDefinitions = source.blockDefinitions.values
      .where((definition) => requiredBlockIds.contains(definition.id))
      .toList(growable: false);
  final sourceMap = <String, String>{};
  final usedDefinitionIds = definitions.keys.toSet();
  for (final definition in selectedDefinitions) {
    final id = _allocateImportedId(source.id, definition.id, usedDefinitionIds);
    sourceMap[definition.id] = id;
  }
  for (final definition in selectedDefinitions) {
    final id = sourceMap[definition.id]!;
    final machine = definition.machine.copyWith(id: id);
    definitions[id] = definition.copyWith(
      id: id,
      machine: machine,
      invocations: definition.invocations.map(
        (invocation) => invocation.copyWith(
          reference: TMBlockReference(
            blockId:
                sourceMap[invocation.reference.blockId] ??
                invocation.reference.blockId,
            revision: invocation.reference.revision,
          ),
        ),
      ),
    );
  }
  final usedInvocationIds = destination.blockInvocations
      .map((invocation) => invocation.id)
      .toSet();
  final invocations = <TMBlockInvocationNode>[];
  for (final invocation in selectedInvocations) {
    final stateId = importedStateMap[invocation.stateId]!;
    invocations.add(
      invocation.copyWith(
        id: _allocateImportedId(source.id, invocation.id, usedInvocationIds),
        stateId: stateId,
        reference: TMBlockReference(
          blockId:
              sourceMap[invocation.reference.blockId] ??
              invocation.reference.blockId,
          revision: invocation.reference.revision,
        ),
      ),
    );
  }
  return (
    definitions: definitions,
    invocations: invocations,
    sourceMap: sourceMap,
  );
}

Set<String> _requiredTmBlockIds(
  TM source,
  Iterable<TMBlockInvocationNode> rootInvocations,
) {
  final required = <String>{};
  final pending = rootInvocations
      .map((invocation) => invocation.reference.blockId)
      .toList();
  while (pending.isNotEmpty) {
    final blockId = pending.removeLast();
    if (!required.add(blockId)) continue;
    final definition = source.blockDefinitions[blockId];
    if (definition == null) continue;
    pending.addAll(
      definition.invocations.map((invocation) => invocation.reference.blockId),
    );
  }
  return required;
}

List<T> _selectedTransducerStates<T extends TransducerState>(
  AutomatonFragmentRequest request,
  Iterable<T> states,
) => states
    .where(
      (state) =>
          request.selectedStateIds == null ||
          request.selectedStateIds!.contains(state.id.value),
    )
    .toList(growable: false);

AutomatonFragmentPlan _finishTransducer({
  required AutomatonFragmentRequest request,
  required AutomatonFragmentKind kind,
  required String destinationId,
  required String sourceId,
  required Object preview,
  required Map<String, String> stateMap,
  required Map<String, String> transitionMap,
  required Vector2 placement,
}) {
  if (stateMap.isEmpty) {
    return _blocked(
      kind: kind,
      destinationId: destinationId,
      sourceId: sourceId,
      code: AutomatonFragmentDiagnosticCode.emptyFragment,
      message: 'The selected fragment has no states.',
    );
  }
  final annotations = _mergeAnnotations(
    request: request,
    destinationId: destinationId,
    stateMap: stateMap,
    transitionMap: transitionMap,
    delta: placement,
  );
  return AutomatonFragmentPlan(
    kind: kind,
    destinationDocumentId: destinationId,
    sourceDocumentId: sourceId,
    preview: annotations.diagnostics.any((diagnostic) => diagnostic.isBlocking)
        ? null
        : preview,
    stateSourceMap: stateMap,
    transitionSourceMap: transitionMap,
    annotationSourceMap: annotations.sourceMap,
    blockSourceMap: const {},
    diagnostics: annotations.diagnostics,
    importedStateIds: stateMap.values,
    importedTransitionIds: transitionMap.values,
    annotations: annotations.collection,
  );
}

({
  DocumentAnnotationCollection? collection,
  Map<String, String> sourceMap,
  List<AutomatonFragmentDiagnostic> diagnostics,
})
_mergeAnnotations({
  required AutomatonFragmentRequest request,
  required String destinationId,
  required Map<String, String> stateMap,
  required Map<String, String> transitionMap,
  required Vector2 delta,
}) {
  final source = request.sourceAnnotations;
  final destination = request.destinationAnnotations;
  if (source == null) {
    return (
      collection: destination,
      sourceMap: const {},
      diagnostics: const [],
    );
  }
  final revision =
      request.destinationRevision ??
      destination?.documentRevision ??
      'fragment-combine';
  final existing = destination == null
      ? DocumentAnnotationCollection(
          documentId: destinationId,
          documentRevision: revision,
        )
      : destination.documentRevision == revision
      ? destination
      : destination.rebindRevision(revision);
  final wholeDocument = request.selectedStateIds == null;
  final selected = source.annotations
      .where((annotation) {
        final attachment = annotation.attachment;
        if (attachment == null) return true;
        return switch (attachment.type) {
          AnnotationTargetType.state => stateMap.containsKey(
            attachment.targetId,
          ),
          AnnotationTargetType.transition => transitionMap.containsKey(
            attachment.targetId,
          ),
          _ => wholeDocument,
        };
      })
      .toList(growable: false);
  if (existing.annotations.length + selected.length >
      DocumentAnnotationCollection.maximumAnnotations) {
    return (
      collection: destination,
      sourceMap: const {},
      diagnostics: const [
        AutomatonFragmentDiagnostic(
          code: AutomatonFragmentDiagnosticCode.annotationLimit,
          severity: AutomatonFragmentDiagnosticSeverity.blocking,
          message: 'The combined document would exceed the annotation limit.',
        ),
      ],
    );
  }
  final usedIds = existing.annotations
      .map((annotation) => annotation.id)
      .toSet();
  final sourceMap = <String, String>{};
  final imported = <DocumentAnnotation>[];
  final baseLayer = existing.annotations.isEmpty
      ? 0
      : existing.annotations
                .map((annotation) => annotation.zIndex)
                .reduce(math.max) +
            1;
  for (var index = 0; index < selected.length; index++) {
    final annotation = selected[index];
    final id = _allocateImportedId(source.documentId, annotation.id, usedIds);
    sourceMap[annotation.id] = id;
    final attachment = annotation.attachment;
    final targetId = switch (attachment?.type) {
      AnnotationTargetType.state => stateMap[attachment!.targetId],
      AnnotationTargetType.transition => transitionMap[attachment!.targetId],
      _ => attachment?.targetId,
    };
    imported.add(
      annotation.copyWith(
        id: id,
        documentId: destinationId,
        documentRevision: revision,
        x: annotation.x + delta.x,
        y: annotation.y + delta.y,
        attachment: attachment == null || targetId == null
            ? null
            : attachment.copyWith(targetId: targetId),
        zIndex: baseLayer + index,
      ),
    );
  }
  return (
    collection: DocumentAnnotationCollection(
      documentId: destinationId,
      documentRevision: revision,
      annotations: [...existing.annotations, ...imported],
    ),
    sourceMap: sourceMap,
    diagnostics: const [],
  );
}

AutomatonFragmentPlan _blocked({
  required AutomatonFragmentKind kind,
  required String destinationId,
  required String sourceId,
  required AutomatonFragmentDiagnosticCode code,
  required String message,
  AutomatonFragmentKind? connectorKind,
}) => _blockedWithDiagnostics(
  kind: kind,
  destinationId: destinationId,
  sourceId: sourceId,
  diagnostics: [
    AutomatonFragmentDiagnostic(
      code: code,
      severity: AutomatonFragmentDiagnosticSeverity.blocking,
      message: message,
      connectorKind: connectorKind,
    ),
  ],
);

AutomatonFragmentPlan _blockedWithDiagnostics({
  required AutomatonFragmentKind kind,
  required String destinationId,
  required String sourceId,
  required Iterable<AutomatonFragmentDiagnostic> diagnostics,
}) => AutomatonFragmentPlan(
  kind: kind,
  destinationDocumentId: destinationId,
  sourceDocumentId: sourceId,
  preview: null,
  stateSourceMap: const {},
  transitionSourceMap: const {},
  annotationSourceMap: const {},
  blockSourceMap: const {},
  diagnostics: diagnostics,
  importedStateIds: const {},
  importedTransitionIds: const {},
);

AutomatonFragmentKind? _kindOf(Object value) => switch (value) {
  FSA() => AutomatonFragmentKind.fsa,
  PDA() => AutomatonFragmentKind.pda,
  TM() => AutomatonFragmentKind.tm,
  MealyMachine() => AutomatonFragmentKind.mealy,
  MooreMachine() => AutomatonFragmentKind.moore,
  _ => null,
};

String _documentId(Object value) => switch (value) {
  FSA(:final id) || PDA(:final id) || TM(:final id) => id,
  MealyMachine(:final id) || MooreMachine(:final id) => id.value,
  _ => 'unknown',
};

extension<T> on Iterable<T> {
  T? get firstOrNull {
    final iterator = this.iterator;
    return iterator.moveNext() ? iterator.current : null;
  }
}
