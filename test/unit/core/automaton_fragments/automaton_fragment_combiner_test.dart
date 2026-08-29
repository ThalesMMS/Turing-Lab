import 'dart:math' as math;

import 'package:flutter_test/flutter_test.dart';
import 'package:vector_math/vector_math_64.dart';

import 'package:turing_lab/core/annotations/annotations.dart';
import 'package:turing_lab/core/automaton_fragments/automaton_fragments.dart';
import 'package:turing_lab/core/models/fsa.dart';
import 'package:turing_lab/core/models/fsa_transition.dart';
import 'package:turing_lab/core/models/pda.dart';
import 'package:turing_lab/core/models/pda_acceptance_mode.dart';
import 'package:turing_lab/core/models/pda_transition.dart';
import 'package:turing_lab/core/models/state.dart';
import 'package:turing_lab/core/models/tm.dart';
import 'package:turing_lab/core/models/tm_building_blocks.dart';
import 'package:turing_lab/core/models/tm_transition.dart';
import 'package:turing_lab/core/models/transition.dart';
import 'package:turing_lab/core/transducers/transducers.dart';

void main() {
  group('FSA fragment combination', () {
    test('is deterministic, collision-safe, and does not mutate inputs', () {
      final destination = _fsa('destination', offset: 0);
      final source = _fsa('source', offset: 0);
      final beforeDestination = destination.toJson();
      final beforeSource = source.toJson();
      final request = AutomatonFragmentRequest(
        destination: destination,
        source: source,
        initialStatePolicy: ImportedInitialStatePolicy.keepDestination,
        insertionAnchor: Vector2(200, 300),
        timestamp: DateTime.utc(2026, 8, 25),
      );

      final first = AutomatonFragmentCombiner.prepare(request);
      final second = AutomatonFragmentCombiner.prepare(request);

      expect(first.canCommit, isTrue);
      expect(first.stateSourceMap, second.stateSourceMap);
      expect(first.transitionSourceMap, second.transitionSourceMap);
      expect(
        (first.preview! as FSA).toJson(),
        (second.preview! as FSA).toJson(),
      );
      expect(first.stateSourceMap.values, everyElement(startsWith('import_')));
      expect(first.stateSourceMap.values.toSet().length, 2);
      expect(destination.toJson(), beforeDestination);
      expect(source.toJson(), beforeSource);
      final combined = first.preview! as FSA;
      expect(combined.states, hasLength(4));
      expect(combined.transitions, hasLength(2));
      expect(combined.states.map((state) => state.id).toSet(), hasLength(4));
      expect(
        combined.transitions.map((transition) => transition.id).toSet(),
        hasLength(2),
      );
      expect(
        combined.states.where((state) => state.label == 'q0'),
        hasLength(2),
      );
      expect(combined.states.where((state) => state.isInitial), hasLength(1));
      expect(combined.initialState?.id, 'q0');
      final importedQ0 = combined.states.singleWhere(
        (state) => state.id == first.stateSourceMap['q0'],
      );
      expect(importedQ0.position, Vector2(200, 300));
      expect(first.provenanceByImportedId[importedQ0.id]?.elementId, 'q0');
    });

    test('blocks an empty fragment without changing either input', () {
      final destination = _fsa('destination');
      final source = _emptyFsa('source');
      final before = destination.toJson();

      final plan = AutomatonFragmentCombiner.prepare(
        AutomatonFragmentRequest(destination: destination, source: source),
      );

      expect(plan.canCommit, isFalse);
      expect(plan.preview, isNull);
      expect(
        plan.diagnostics.map((diagnostic) => diagnostic.code),
        contains(AutomatonFragmentDiagnosticCode.emptyFragment),
      );
      expect(destination.toJson(), before);
    });

    test('requires an explicit initial-state decision', () {
      final plan = AutomatonFragmentCombiner.prepare(
        AutomatonFragmentRequest(
          destination: _fsa('destination'),
          source: _fsa('source'),
        ),
      );

      expect(plan.canCommit, isFalse);
      expect(
        plan.diagnostics.map((diagnostic) => diagnostic.code),
        contains(AutomatonFragmentDiagnosticCode.initialStateConflict),
      );
    });

    test(
      'imports a selected induced subgraph without dangling transitions',
      () {
        final source = _fsa('source');
        final plan = AutomatonFragmentCombiner.prepare(
          AutomatonFragmentRequest(
            destination: _emptyFsa('destination'),
            source: source,
            selectedStateIds: const {'q1'},
          ),
        );

        expect(plan.canCommit, isTrue);
        expect(plan.importedStateIds, hasLength(1));
        expect(plan.importedTransitionIds, isEmpty);
        expect((plan.preview! as FSA).transitions, isEmpty);
      },
    );

    test('honors explicit transition selection', () {
      final plan = AutomatonFragmentCombiner.prepare(
        AutomatonFragmentRequest(
          destination: _emptyFsa('destination'),
          source: _fsa('source'),
          selectedTransitionIds: const {},
        ),
      );

      expect(plan.canCommit, isTrue);
      expect(plan.importedStateIds, hasLength(2));
      expect(plan.importedTransitionIds, isEmpty);
    });

    test('stores dangling transition identity outside presentation prose', () {
      const diagnostic = AutomatonFragmentDiagnostic(
        code: AutomatonFragmentDiagnosticCode.danglingTransition,
        severity: AutomatonFragmentDiagnosticSeverity.blocking,
        message: 'compatibility description',
        transitionId: 't0',
      );

      expect(diagnostic.transitionId, 't0');
    });

    test('unions alphabets and preserves an explicit epsilon alias', () {
      final base = _fsa('source');
      final statesById = {for (final state in base.states) state.id: state};
      final source = base.copyWith(
        alphabet: {'b'},
        transitions: <Transition>{
          FSATransition(
            id: 'epsilon',
            fromState: statesById['q0']!,
            toState: statesById['q1']!,
            lambdaSymbol: 'λ',
          ),
        },
      );

      final plan = AutomatonFragmentCombiner.prepare(
        AutomatonFragmentRequest(
          destination: _fsa('destination'),
          source: source,
          initialStatePolicy: ImportedInitialStatePolicy.keepDestination,
        ),
      );

      expect(plan.canCommit, isTrue);
      final result = plan.preview! as FSA;
      expect(result.alphabet, {'a', 'b'});
      final imported = result.fsaTransitions.singleWhere(
        (transition) => transition.id == plan.transitionSourceMap['epsilon'],
      );
      expect(imported.lambdaSymbol, 'λ');
      expect(imported.inputSymbols, isEmpty);
    });

    test('packs deterministically near a negative viewport edge', () {
      final destination = _fsa('destination', offset: -200);
      final request = AutomatonFragmentRequest(
        destination: destination,
        source: _fsa('source'),
        initialStatePolicy: ImportedInitialStatePolicy.keepDestination,
        insertionAnchor: Vector2(-200, -200),
        timestamp: DateTime.utc(2026, 8, 25),
      );

      final first = AutomatonFragmentCombiner.prepare(request);
      final second = AutomatonFragmentCombiner.prepare(request);
      final result = first.preview! as FSA;
      final importedPositions = result.states
          .where((state) => first.importedStateIds.contains(state.id))
          .map((state) => state.position)
          .toList();

      expect(first.canCommit, isTrue);
      expect((second.preview! as FSA).toJson(), result.toJson());
      expect(
        importedPositions.every(
          (imported) => destination.states.every(
            (existing) =>
                (existing.position.x - imported.x).abs() >= 80 ||
                (existing.position.y - imported.y).abs() >= 80,
          ),
        ),
        isTrue,
      );
      expect(result.bounds.left, lessThanOrEqualTo(-200));
      expect(result.bounds.top, lessThanOrEqualTo(-200));
    });

    test('supports an explicit typed FSA connector', () {
      final plan = AutomatonFragmentCombiner.prepare(
        AutomatonFragmentRequest(
          destination: _fsa('destination'),
          source: _fsa('source'),
          operation: AutomatonFragmentOperation.connector,
          initialStatePolicy: ImportedInitialStatePolicy.keepDestination,
          fsaConnector: FsaFragmentConnector(
            destinationStateId: 'q1',
            sourceStateId: 'q0',
            symbols: {'x'},
          ),
        ),
      );

      expect(plan.canCommit, isTrue);
      final combined = plan.preview! as FSA;
      expect(combined.transitions, hasLength(3));
      expect(combined.alphabet, contains('x'));
      expect(
        combined.fsaTransitions
            .singleWhere((item) => item.id == 'connector')
            .toState
            .id,
        plan.stateSourceMap['q0'],
      );
    });

    test('preserves and retargets annotations', () {
      final now = DateTime.utc(2026, 8, 25);
      final sourceNotes = DocumentAnnotationCollection(
        documentId: 'source',
        documentRevision: '1',
        annotations: [
          DocumentAnnotation(
            id: 'note',
            documentId: 'source',
            documentRevision: '1',
            text: 'Unicode αβ',
            x: 10,
            y: 20,
            attachment: const AnnotationAttachment(
              type: AnnotationTargetType.state,
              targetId: 'q1',
            ),
            createdAt: now,
            updatedAt: now,
          ),
        ],
      );
      final destinationNotes = DocumentAnnotationCollection(
        documentId: 'destination',
        documentRevision: '7',
      );

      final plan = AutomatonFragmentCombiner.prepare(
        AutomatonFragmentRequest(
          destination: _emptyFsa('destination'),
          source: _fsa('source'),
          sourceAnnotations: sourceNotes,
          destinationAnnotations: destinationNotes,
          destinationRevision: '7',
          insertionAnchor: Vector2(100, 100),
          timestamp: now,
        ),
      );

      expect(plan.canCommit, isTrue);
      final annotation = plan.annotations!.annotations.single;
      expect(annotation.documentId, 'destination');
      expect(annotation.documentRevision, '7');
      expect(annotation.text, 'Unicode αβ');
      expect(annotation.attachment?.targetId, plan.stateSourceMap['q1']);
      expect(plan.annotationSourceMap['note'], annotation.id);
    });
  });

  group('PDA compatibility', () {
    test('blocks acceptance and initial-stack conflicts by default', () {
      final plan = AutomatonFragmentCombiner.prepare(
        AutomatonFragmentRequest(
          destination: _pda(
            'destination',
            acceptanceMode: PDAAcceptanceMode.finalState,
            initialStackSymbol: 'Z',
          ),
          source: _pda(
            'source',
            acceptanceMode: PDAAcceptanceMode.emptyStack,
            initialStackSymbol: 'S',
          ),
        ),
      );

      expect(plan.canCommit, isFalse);
      expect(
        plan.diagnostics.map((diagnostic) => diagnostic.code),
        containsAll({
          AutomatonFragmentDiagnosticCode.pdaAcceptanceModeConflict,
          AutomatonFragmentDiagnosticCode.pdaInitialStackSymbolConflict,
        }),
      );
      expect(
        plan.diagnostics.map((diagnostic) => diagnostic.normalized).toSet(),
        {false},
      );
    });

    test(
      'requires explicit normalization and retains destination semantics',
      () {
        final plan = AutomatonFragmentCombiner.prepare(
          AutomatonFragmentRequest(
            destination: _pda(
              'destination',
              acceptanceMode: PDAAcceptanceMode.finalState,
              initialStackSymbol: 'Z',
            ),
            source: _pda(
              'source',
              acceptanceMode: PDAAcceptanceMode.emptyStack,
              initialStackSymbol: 'S',
            ),
            initialStatePolicy: ImportedInitialStatePolicy.keepDestination,
            pdaAcceptanceResolution: PdaConflictResolution.useDestination,
            pdaInitialStackResolution: PdaConflictResolution.useDestination,
          ),
        );

        expect(plan.canCommit, isTrue);
        final result = plan.preview! as PDA;
        expect(result.acceptanceMode, PDAAcceptanceMode.finalState);
        expect(result.initialStackSymbol, 'Z');
        expect(result.stackAlphabet, containsAll({'Z', 'S'}));
        expect(
          plan.diagnostics.where(
            (diagnostic) =>
                diagnostic.severity ==
                AutomatonFragmentDiagnosticSeverity.warning,
          ),
          hasLength(2),
        );
        expect(
          plan.diagnostics.map((diagnostic) => diagnostic.normalized).toSet(),
          {true},
        );
      },
    );

    test('identifies the connector kind without parsing prose', () {
      final plan = AutomatonFragmentCombiner.prepare(
        AutomatonFragmentRequest(
          destination: _pda(
            'destination',
            acceptanceMode: PDAAcceptanceMode.finalState,
            initialStackSymbol: 'Z',
          ),
          source: _pda(
            'source',
            acceptanceMode: PDAAcceptanceMode.finalState,
            initialStackSymbol: 'Z',
          ),
          operation: AutomatonFragmentOperation.connector,
          initialStatePolicy: ImportedInitialStatePolicy.keepDestination,
        ),
      );

      final diagnostic = plan.diagnostics.single;
      expect(
        diagnostic.code,
        AutomatonFragmentDiagnosticCode.connectorUnsupported,
      );
      expect(diagnostic.connectorKind, AutomatonFragmentKind.pda);
    });
  });

  group('TM compatibility', () {
    test('blocks tape-count and blank-symbol conflicts', () {
      final plan = AutomatonFragmentCombiner.prepare(
        AutomatonFragmentRequest(
          destination: _tm('destination', tapeCount: 1, blank: 'B'),
          source: _tm('source', tapeCount: 2, blank: '□'),
        ),
      );

      expect(plan.canCommit, isFalse);
      expect(
        plan.diagnostics.map((diagnostic) => diagnostic.code),
        containsAll({
          AutomatonFragmentDiagnosticCode.tmTapeCountConflict,
          AutomatonFragmentDiagnosticCode.tmBlankSymbolConflict,
        }),
      );
    });

    test('clones building-block IDs and rewrites invocation references', () {
      final source = _tmWithBlock('source');
      final plan = AutomatonFragmentCombiner.prepare(
        AutomatonFragmentRequest(
          destination: _tm('destination'),
          source: source,
          initialStatePolicy: ImportedInitialStatePolicy.keepDestination,
        ),
      );

      expect(plan.canCommit, isTrue);
      final result = plan.preview! as TM;
      final clonedBlockId = plan.blockSourceMap['block'];
      expect(clonedBlockId, isNotNull);
      expect(result.blockDefinitions, contains(clonedBlockId));
      expect(result.blockInvocations, hasLength(1));
      expect(result.blockInvocations.single.reference.blockId, clonedBlockId);
      expect(result.blockInvocations.single.stateId, plan.stateSourceMap['q1']);
    });

    test('omits unrelated blocks when importing a selected subgraph', () {
      final source = _tmWithBlock('source').copyWith(
        blockDefinitions: {
          ..._tmWithBlock('source').blockDefinitions,
          'unused': TMBlockDefinition(
            id: 'unused',
            name: 'Unused',
            revision: 1,
            machine: _tm('unused-machine'),
          ),
        },
      );
      final plan = AutomatonFragmentCombiner.prepare(
        AutomatonFragmentRequest(
          destination: _tm('destination'),
          source: source,
          selectedStateIds: const {'q0'},
          initialStatePolicy: ImportedInitialStatePolicy.keepDestination,
        ),
      );

      expect(plan.canCommit, isTrue);
      expect((plan.preview! as TM).blockDefinitions, isEmpty);
      expect(plan.blockSourceMap, isEmpty);
    });
  });

  group('transducer compatibility', () {
    test('combines Mealy machines and preserves output words', () {
      final plan = AutomatonFragmentCombiner.prepare(
        AutomatonFragmentRequest(
          destination: _mealy('destination'),
          source: _mealy('source'),
          initialStatePolicy: ImportedInitialStatePolicy.keepDestination,
        ),
      );

      expect(plan.canCommit, isTrue);
      final result = plan.preview! as MealyMachine;
      expect(result.states, hasLength(4));
      expect(result.transitions, hasLength(2));
      expect(result.transitions.last.output.values, ['out']);
      expect(result.revision.value, 2);
    });

    test('rejects Mealy-to-Moore structural combination', () {
      final plan = AutomatonFragmentCombiner.prepare(
        AutomatonFragmentRequest(
          destination: _mealy('destination'),
          source: _moore('source'),
        ),
      );

      expect(plan.canCommit, isFalse);
      expect(
        plan.diagnostics.single.code,
        AutomatonFragmentDiagnosticCode.incompatibleDocumentType,
      );
    });
  });
}

FSA _emptyFsa(String id) {
  final now = DateTime.utc(2026, 8, 25);
  return FSA(
    id: id,
    name: id,
    states: const {},
    transitions: const {},
    alphabet: const {},
    initialState: null,
    acceptingStates: const {},
    created: now,
    modified: now,
    bounds: const math.Rectangle<double>(0, 0, 400, 300),
  );
}

FSA _fsa(String id, {double offset = 0}) {
  final now = DateTime.utc(2026, 8, 25);
  final q0 = State(
    id: 'q0',
    label: 'q0',
    position: Vector2(offset, offset),
    isInitial: true,
  );
  final q1 = State(
    id: 'q1',
    label: 'q1',
    position: Vector2(offset + 100, offset),
    isAccepting: true,
  );
  return FSA(
    id: id,
    name: id,
    states: {q0, q1},
    transitions: <Transition>{
      FSATransition(id: 't0', fromState: q0, toState: q1, inputSymbols: {'a'}),
    },
    alphabet: {'a'},
    initialState: q0,
    acceptingStates: {q1},
    created: now,
    modified: now,
    bounds: const math.Rectangle<double>(0, 0, 400, 300),
  );
}

PDA _pda(
  String id, {
  required PDAAcceptanceMode acceptanceMode,
  required String initialStackSymbol,
}) {
  final now = DateTime.utc(2026, 8, 25);
  final q0 = State(
    id: 'q0',
    label: 'q0',
    position: Vector2.zero(),
    isInitial: true,
  );
  final q1 = State(
    id: 'q1',
    label: 'q1',
    position: Vector2(100, 0),
    isAccepting: true,
  );
  return PDA(
    id: id,
    name: id,
    states: {q0, q1},
    transitions: <Transition>{
      PDATransition(
        id: 't0',
        fromState: q0,
        toState: q1,
        label: 'a, $initialStackSymbol/$initialStackSymbol',
        inputSymbol: 'a',
        popSymbol: initialStackSymbol,
        pushSymbol: initialStackSymbol,
      ),
    },
    alphabet: {'a'},
    initialState: q0,
    acceptingStates: {q1},
    created: now,
    modified: now,
    bounds: const math.Rectangle<double>(0, 0, 400, 300),
    stackAlphabet: {initialStackSymbol},
    initialStackSymbol: initialStackSymbol,
    acceptanceMode: acceptanceMode,
  );
}

TM _tm(String id, {int tapeCount = 1, String blank = 'B'}) {
  final now = DateTime.utc(2026, 8, 25);
  final q0 = State(
    id: 'q0',
    label: 'q0',
    position: Vector2.zero(),
    isInitial: true,
  );
  final q1 = State(
    id: 'q1',
    label: 'q1',
    position: Vector2(100, 0),
    isAccepting: true,
  );
  return TM(
    id: id,
    name: id,
    states: {q0, q1},
    transitions: <Transition>{
      TMTransition(
        id: 't0',
        fromState: q0,
        toState: q1,
        label: 'move',
        readSymbols: List.filled(tapeCount, blank),
        writeSymbols: List.filled(tapeCount, blank),
        directions: List.filled(tapeCount, TapeDirection.stay),
      ),
    },
    alphabet: const {},
    initialState: q0,
    acceptingStates: {q1},
    created: now,
    modified: now,
    bounds: const math.Rectangle<double>(0, 0, 400, 300),
    tapeAlphabet: {blank},
    blankSymbol: blank,
    tapeCount: tapeCount,
  );
}

TM _tmWithBlock(String id) {
  final base = _tm(id);
  final blockMachine = _tm('block-machine');
  return base.copyWith(
    blockDefinitions: {
      'block': TMBlockDefinition(
        id: 'block',
        name: 'Block',
        revision: 1,
        machine: blockMachine,
      ),
    },
    blockInvocations: const [
      TMBlockInvocationNode(
        id: 'invoke',
        stateId: 'q1',
        reference: TMBlockReference(blockId: 'block', revision: 1),
      ),
    ],
  );
}

MealyMachine _mealy(String id) => MealyMachine(
  id: TransducerMachineId(id),
  name: id,
  revision: const TransducerRevision(1),
  inputAlphabet: {const TransducerInputSymbol('a')},
  outputAlphabet: {const TransducerOutputSymbol('out')},
  states: const [
    MealyState(
      id: TransducerStateId('q0'),
      label: 'q0',
      position: TransducerPoint(0, 0),
      isInitial: true,
    ),
    MealyState(
      id: TransducerStateId('q1'),
      label: 'q1',
      position: TransducerPoint(100, 0),
    ),
  ],
  transitions: [
    MealyTransition(
      id: const TransducerTransitionId('t0'),
      from: const TransducerStateId('q0'),
      to: const TransducerStateId('q1'),
      input: const TransducerInputSymbol('a'),
      output: TransducerOutputWord.fromValues(const ['out']),
    ),
  ],
);

MooreMachine _moore(String id) => MooreMachine(
  id: TransducerMachineId(id),
  name: id,
  revision: const TransducerRevision(1),
  inputAlphabet: {const TransducerInputSymbol('a')},
  outputAlphabet: {const TransducerOutputSymbol('out')},
  states: [
    MooreState(
      id: const TransducerStateId('q0'),
      label: 'q0',
      position: const TransducerPoint(0, 0),
      isInitial: true,
      output: TransducerOutputWord.fromValues(const ['out']),
    ),
  ],
  transitions: const [],
);
