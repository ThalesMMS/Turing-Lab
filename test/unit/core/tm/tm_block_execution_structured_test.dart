import 'dart:math' as math;

import 'package:flutter_test/flutter_test.dart';
import 'package:turing_lab/core/algorithms/tm_block_execution_engine.dart';
import 'package:turing_lab/core/algorithms/tm_block_inline_expander.dart';
import 'package:turing_lab/core/messages/structured_message.dart';
import 'package:turing_lab/core/models/state.dart';
import 'package:turing_lab/core/models/tm.dart';
import 'package:turing_lab/core/models/tm_block_execution.dart';
import 'package:turing_lab/core/models/tm_building_blocks.dart';
import 'package:turing_lab/core/models/tm_transition.dart';
import 'package:turing_lab/core/models/transition.dart';
import 'package:vector_math/vector_math_64.dart';

void main() {
  State state(String id, {bool initial = false, bool accepting = false}) =>
      State(
        id: id,
        label: id,
        position: Vector2.zero(),
        isInitial: initial,
        isAccepting: accepting,
      );

  TMTransition transition(String id, State from, State to) => TMTransition(
    id: id,
    label: id,
    fromState: from,
    toState: to,
    readSymbol: 'B',
    writeSymbol: 'B',
    direction: TapeDirection.stay,
  );

  TM machine({
    required String id,
    required Iterable<State> states,
    Iterable<Transition> transitions = const [],
    bool accepting = false,
    Map<String, TMBlockDefinition> definitions = const {},
    Iterable<TMBlockInvocationNode> invocations = const [],
  }) {
    final stateSet = states.toSet();
    final initialStates = stateSet.where((candidate) => candidate.isInitial);
    return TM(
      id: id,
      name: id,
      states: stateSet,
      transitions: transitions.toSet(),
      alphabet: const {},
      initialState: initialStates.isEmpty ? null : initialStates.first,
      acceptingStates: accepting
          ? stateSet.where((candidate) => candidate.isAccepting).toSet()
          : const {},
      created: DateTime.utc(2026),
      modified: DateTime.utc(2026),
      bounds: const math.Rectangle<double>(0, 0, 100, 100),
      tapeAlphabet: const {'B'},
      blockDefinitions: definitions,
      blockInvocations: invocations,
    );
  }

  TMBlockProject project() {
    final rootCall = state('root-call', initial: true);
    final rootAccept = state('root-accept', accepting: true);
    final childStart = state('child-start', initial: true);
    final childHalt = state('child-halt');
    final child = TMBlockDefinition(
      id: 'child',
      name: 'Child',
      revision: 1,
      machine: machine(
        id: 'child-machine',
        states: [childStart, childHalt],
        transitions: [transition('child-step', childStart, childHalt)],
      ),
    );
    return TMBlockProject(
      rootMachine: machine(
        id: 'root',
        states: [rootCall, rootAccept],
        transitions: [transition('root-accept', rootCall, rootAccept)],
        accepting: true,
        definitions: {'child': child},
        invocations: [
          const TMBlockInvocationNode(
            id: 'call-child',
            stateId: 'root-call',
            reference: TMBlockReference(blockId: 'child', revision: 1),
          ),
        ],
      ),
    );
  }

  group('TM building-block execution structured messages', () {
    test('attaches locale-neutral payloads to every trace action', () {
      final result = TMBlockExecutionEngine.execute(project(), '');

      expect(result.outcome.name, 'accepted');
      expect(result.trace.map((step) => step.action), [
        TMBlockTraceAction.enterBlock,
        TMBlockTraceAction.transition,
        TMBlockTraceAction.returnFromBlock,
        TMBlockTraceAction.transition,
      ]);
      expect(result.trace.map((step) => step.structuredMessage?.stableCode), [
        'tm.building-blocks.enter-block',
        'tm.building-blocks.transition',
        'tm.building-blocks.return-from-block',
        'tm.building-blocks.transition',
      ]);

      final enter = result.trace[0];
      expect(enter.targetMachineId, 'child');
      expect(
        enter.structuredMessage!.arguments['machine']!.kind,
        StructuredMessageArgumentKind.identifier,
      );
      expect(enter.structuredMessage!.arguments['machine']!.role, 'machine-id');
      expect(enter.structuredMessage!.arguments['machine']!.value, 'child');

      final childTransition = result.trace[1];
      expect(childTransition.transitionId, 'child-step');
      expect(
        childTransition.structuredMessage!.arguments['transition']!.value,
        'child-step',
      );
      expect(
        childTransition.structuredMessage!.arguments['transition']!.role,
        'transition-id',
      );

      final returned = result.trace[2];
      expect(returned.targetMachineId, 'root');
      expect(returned.structuredMessage!.arguments['machine']!.value, 'root');
      expect(result.trace[3].transitionId, 'root-accept');
    });

    test('serializes trace payloads without dropping legacy fields', () {
      final trace = TMBlockExecutionEngine.execute(project(), '').trace;
      final encoded = trace.map((step) => step.toJson()).toList();

      expect(encoded[0]['action'], 'enterBlock');
      expect(encoded[0]['targetMachineId'], 'child');
      expect(encoded[0]['structuredMessage'], isA<Map<String, Object?>>());
      final decoded = StructuredMessage.fromJson(
        Map<String, Object?>.from(encoded[0]['structuredMessage']! as Map),
      );
      expect(decoded, trace[0].structuredMessage);
      expect(encoded[1]['transitionId'], 'child-step');
      expect(encoded[2]['action'], 'returnFromBlock');
      expect(encoded[3]['transitionId'], 'root-accept');
    });

    test('keeps inline expansion diagnostics structured', () {
      final child = TMBlockDefinition(
        id: 'child',
        name: 'Child',
        revision: 1,
        machine: machine(
          id: 'child-machine',
          states: [state('child-start', initial: true)],
        ),
      );
      final rootState = state('root-call', initial: true, accepting: true);
      final project = TMBlockProject(
        rootMachine: machine(
          id: 'root',
          states: [rootState],
          accepting: true,
          definitions: {'child': child},
          invocations: [
            const TMBlockInvocationNode(
              id: 'call-child',
              stateId: 'root-call',
              reference: TMBlockReference(blockId: 'child', revision: 1),
            ),
          ],
        ),
      );

      final result = TMBlockInlineExpander.expand(project);

      expect(result.isSuccess, isFalse);
      expect(result.diagnostics, hasLength(1));
      final diagnostic = result.diagnostics.single;
      expect(diagnostic.message, contains('cannot be inlined'));
      expect(
        diagnostic.structuredMessage?.stableCode,
        'tm.building-blocks.accepting-root-invocation',
      );
      expect(diagnostic.invocationId, 'call-child');
      expect(diagnostic.blockId, 'child');
      expect(
        StructuredMessage.fromJson(diagnostic.structuredMessage!.toJson()),
        diagnostic.structuredMessage,
      );
    });
  });
}
