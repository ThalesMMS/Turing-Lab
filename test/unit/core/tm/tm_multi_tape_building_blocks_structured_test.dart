import 'dart:math' as math;

import 'package:flutter_test/flutter_test.dart';
import 'package:turing_lab/core/algorithms/tm_block_dependency_analyzer.dart';
import 'package:turing_lab/core/algorithms/tm_block_execution_engine.dart';
import 'package:turing_lab/core/algorithms/tm_block_inline_expander.dart';
import 'package:turing_lab/core/algorithms/tm_multi_tape_execution_analyzer.dart';
import 'package:turing_lab/core/algorithms/tm_to_grammar_messages.dart';
import 'package:turing_lab/core/algorithms/tm_to_unrestricted_grammar/tm_to_grammar_converter.dart';
import 'package:turing_lab/core/algorithms/tm_to_unrestricted_grammar/tm_to_grammar_models.dart';
import 'package:turing_lab/core/messages/structured_message.dart';
import 'package:turing_lab/core/models/state.dart';
import 'package:turing_lab/core/models/tm.dart';
import 'package:turing_lab/core/models/tm_acceptance.dart';
import 'package:turing_lab/core/models/tm_building_blocks.dart';
import 'package:turing_lab/core/models/tm_execution_analysis.dart';
import 'package:turing_lab/core/models/tm_transition.dart';
import 'package:turing_lab/core/models/transition.dart';
import 'package:vector_math/vector_math_64.dart';

void main() {
  State testState(String id, {bool initial = false, bool accepting = false}) =>
      State(
        id: id,
        label: id,
        position: Vector2.zero(),
        isInitial: initial,
        isAccepting: accepting,
      );

  TM testMachine({
    required String id,
    required Iterable<State> states,
    Iterable<Transition> transitions = const [],
    bool accepting = false,
    int tapeCount = 1,
    Map<String, TMBlockDefinition> definitions = const {},
    Iterable<TMBlockInvocationNode> invocations = const [],
  }) {
    final stateSet = states.toSet();
    final initialStates = stateSet.where((candidate) => candidate.isInitial);
    final initial = initialStates.isEmpty ? null : initialStates.first;
    final acceptingStates = accepting
        ? stateSet.where((candidate) => candidate.isAccepting).toSet()
        : <State>{};
    return TM(
      id: id,
      name: id,
      states: stateSet,
      transitions: transitions.toSet(),
      alphabet: const {},
      initialState: initial,
      acceptingStates: acceptingStates,
      created: DateTime.utc(2026),
      modified: DateTime.utc(2026),
      bounds: const math.Rectangle<double>(0, 0, 100, 100),
      tapeAlphabet: const {'B'},
      tapeCount: tapeCount,
      blockDefinitions: definitions,
      blockInvocations: invocations,
    );
  }

  TMTransition testTransition(
    String id,
    State from,
    State to,
    List<String> reads,
    List<String> writes,
    List<TapeDirection> directions,
  ) => TMTransition(
    id: id,
    label: id,
    fromState: from,
    toState: to,
    readSymbols: reads,
    writeSymbols: writes,
    directions: directions,
  );

  group('multi-tape structured messages', () {
    test('preserves locale-neutral outcomes and legacy prose', () async {
      final accepted = await TMMultiTapeExecutionAnalyzer.analyze(
        testMachine(
          id: 'accepted',
          tapeCount: 2,
          states: [testState('q0', initial: true, accepting: true)],
          accepting: true,
        ),
        '',
        maxSteps: 10,
        maxConfigurations: 10,
        timeout: const Duration(seconds: 1),
        operationsPerBatch: 1,
        includeTrace: false,
      );
      final rejected = await TMMultiTapeExecutionAnalyzer.analyze(
        testMachine(
          id: 'rejected',
          tapeCount: 2,
          states: [testState('q0', initial: true)],
        ),
        '',
        maxSteps: 10,
        maxConfigurations: 10,
        timeout: const Duration(seconds: 1),
        operationsPerBatch: 1,
        includeTrace: false,
      );

      expect(accepted.outcome, TMExecutionOutcome.accepted);
      expect(
        accepted.structuredMessage?.stableCode,
        'tm.multi-tape.entered-final-state',
      );
      expect(
        accepted.structuredMessage?.arguments['policy']?.value,
        TMAcceptancePolicy.finalState.name,
      );
      expect(accepted.message, contains('entered a final state'));
      expect(
        StructuredMessage.fromJson(accepted.structuredMessage!.toJson()),
        accepted.structuredMessage,
      );

      expect(rejected.outcome, TMExecutionOutcome.haltedRejected);
      expect(
        rejected.structuredMessage?.stableCode,
        'tm.multi-tape.halted-rejected',
      );
      expect(
        rejected.message,
        'The machine halted outside an accepting state.',
      );
    });

    test(
      'marks multi-tape bounds, cancellation, and deterministic cycles',
      () async {
        final machine = testMachine(
          id: 'loop',
          tapeCount: 2,
          states: [testState('q0', initial: true)],
          transitions: [
            testTransition(
              'loop',
              testState('q0', initial: true),
              testState('q0', initial: true),
              ['B', 'B'],
              ['B', 'B'],
              [TapeDirection.stay, TapeDirection.stay],
            ),
          ],
        );
        final cycle = await TMMultiTapeExecutionAnalyzer.analyze(
          machine,
          '',
          maxSteps: 10,
          maxConfigurations: 10,
          timeout: const Duration(seconds: 1),
          operationsPerBatch: 1,
          includeTrace: false,
        );
        final cancelled = await TMMultiTapeExecutionAnalyzer.analyze(
          machine,
          '',
          maxSteps: 10,
          maxConfigurations: 10,
          timeout: const Duration(seconds: 1),
          operationsPerBatch: 1,
          includeTrace: false,
          isCancelled: () => true,
        );
        final bounded = await TMMultiTapeExecutionAnalyzer.analyze(
          machine,
          '',
          maxSteps: 1,
          maxConfigurations: 10,
          timeout: const Duration(seconds: 1),
          operationsPerBatch: 1,
          includeTrace: false,
        );

        expect(cycle.outcome, TMExecutionOutcome.provenCycle);
        expect(
          cycle.structuredMessage?.stableCode,
          'tm.multi-tape.deterministic-cycle',
        );
        expect(cancelled.outcome, TMExecutionOutcome.cancelled);
        expect(
          cancelled.structuredMessage?.stableCode,
          'tm.multi-tape.cancelled',
        );
        expect(bounded.outcome, TMExecutionOutcome.provenCycle);

        final boundedByConfigurations =
            await TMMultiTapeExecutionAnalyzer.analyze(
              testMachine(
                id: 'config-limit',
                tapeCount: 2,
                states: [testState('q0', initial: true), testState('q1')],
                transitions: [
                  testTransition(
                    'advance',
                    testState('q0', initial: true),
                    testState('q1'),
                    ['B', 'B'],
                    ['B', 'B'],
                    [TapeDirection.right, TapeDirection.stay],
                  ),
                ],
              ),
              '',
              maxSteps: 10,
              maxConfigurations: 1,
              timeout: const Duration(seconds: 1),
              operationsPerBatch: 1,
              includeTrace: false,
            );
        expect(
          boundedByConfigurations.structuredMessage?.stableCode,
          'tm.multi-tape.configuration-limit',
        );
      },
    );
  });

  group('building-block structured messages', () {
    test('annotates dependency diagnostics and inline expansion failures', () {
      final firstState = testState('first', initial: true);
      final secondState = testState('second', initial: true);
      final rootState = testState('root', initial: true, accepting: true);
      final project = TMBlockProject(
        rootMachine: testMachine(
          id: 'root',
          states: [rootState],
          accepting: true,
          definitions: {
            'first': TMBlockDefinition(
              id: 'first',
              name: 'Same',
              revision: 1,
              machine: testMachine(id: 'first-machine', states: [firstState]),
            ),
            'second': TMBlockDefinition(
              id: 'second',
              name: 'same',
              revision: 1,
              machine: testMachine(id: 'second-machine', states: [secondState]),
            ),
          },
        ),
      );
      final report = TMBlockDependencyAnalyzer.analyze(project);
      final duplicate = report.diagnostics.firstWhere(
        (diagnostic) =>
            diagnostic.code == TMBlockDiagnosticCode.duplicateBlockName,
      );

      expect(
        duplicate.structuredMessage?.stableCode,
        'tm.building-blocks.duplicate-block-name',
      );
      expect(
        duplicate.structuredMessage?.arguments.keys,
        containsAll(['first-block', 'second-block']),
      );
      expect(duplicate.message, 'Blocks first and second have the same name.');
      expect(
        StructuredMessage.fromJson(duplicate.structuredMessage!.toJson()),
        duplicate.structuredMessage,
      );

      final child = TMBlockDefinition(
        id: 'child',
        name: 'Child',
        revision: 1,
        machine: testMachine(
          id: 'child-machine',
          states: [testState('child-state', initial: true)],
        ),
      );
      final inlineProject = TMBlockProject(
        rootMachine: testMachine(
          id: 'inline-root',
          states: [rootState],
          accepting: true,
          definitions: {'child': child},
          invocations: [
            const TMBlockInvocationNode(
              id: 'call-child',
              stateId: 'root',
              reference: TMBlockReference(blockId: 'child', revision: 1),
            ),
          ],
        ),
      );
      final expansion = TMBlockInlineExpander.expand(inlineProject);
      expect(expansion.isSuccess, isFalse);
      expect(
        expansion.diagnostics.single.structuredMessage?.stableCode,
        'tm.building-blocks.accepting-root-invocation',
      );
    });

    test('annotates execution outcomes and invalid projects', () {
      final accepted = TMBlockExecutionEngine.execute(
        TMBlockProject(
          rootMachine: testMachine(
            id: 'root',
            states: [testState('q0', initial: true, accepting: true)],
            accepting: true,
          ),
        ),
        '',
      );
      final cancelled = TMBlockExecutionEngine.execute(
        TMBlockProject(
          rootMachine: testMachine(
            id: 'root',
            states: [testState('q0', initial: true)],
          ),
        ),
        '',
        isCancelled: () => true,
      );
      final invalid = TMBlockExecutionEngine.execute(
        TMBlockProject(
          rootMachine: testMachine(id: 'root', states: const []),
        ),
        '',
      );

      expect(
        accepted.structuredMessage?.stableCode,
        'tm.building-blocks.entered-final-state',
      );
      expect(
        cancelled.structuredMessage?.stableCode,
        'tm.building-blocks.cancelled',
      );
      expect(
        invalid.structuredMessage?.stableCode,
        'tm.building-blocks.invalid-project',
      );
      expect(invalid.outcome, TMExecutionOutcome.invalidMachine);
      expect(invalid.message, 'The building-block project is invalid.');
    });
  });

  group('TM-to-grammar structured diagnostics', () {
    test('annotates unsupported multi-tape and building-block inputs', () {
      final multi = testMachine(
        id: 'multi',
        tapeCount: 2,
        states: [testState('q0', initial: true, accepting: true)],
        accepting: true,
      );
      final multiReport = TMToGrammarConverter.build(multi, sourceRevision: 1);
      final multiDiagnostic = multiReport.diagnostics.firstWhere(
        (diagnostic) =>
            diagnostic.code == TMToGrammarDiagnosticCode.multiTapeUnsupported,
      );

      expect(
        multiDiagnostic.structuredMessage?.stableCode,
        'tm.to-unrestricted-grammar.multi-tape-unsupported',
      );
      expect(multiDiagnostic.structuredMessage?.arguments['tapes']?.value, 2);

      final block = TMBlockDefinition(
        id: 'block',
        name: 'Block',
        revision: 1,
        machine: testMachine(
          id: 'block-machine',
          states: [testState('block-state', initial: true)],
        ),
      );
      final withBlock = testMachine(
        id: 'with-block',
        states: [testState('q0', initial: true, accepting: true)],
        accepting: true,
        definitions: {'block': block},
      );
      final blockReport = TMToGrammarConverter.build(
        withBlock,
        sourceRevision: 1,
      );
      final blockDiagnostic = blockReport.diagnostics.firstWhere(
        (diagnostic) =>
            diagnostic.code ==
            TMToGrammarDiagnosticCode.buildingBlocksUnsupported,
      );

      expect(
        blockDiagnostic.structuredMessage?.stableCode,
        'tm.to-unrestricted-grammar.building-blocks-unsupported',
      );
      expect(
        blockDiagnostic.structuredMessage?.arguments['blocks']?.value,
        'block',
      );
      expect(
        StructuredMessage.fromJson(blockDiagnostic.structuredMessage!.toJson()),
        blockDiagnostic.structuredMessage,
      );
    });

    test('factory retains diagnostic severity and typed values', () {
      final warning = TmToGrammarMessages.fromDiagnostic(
        code: TMToGrammarDiagnosticCode.unreachableState,
        stateId: 'q-unused',
      );

      expect(warning.category, StructuredMessageCategory.conversion);
      expect(warning.severity, StructuredMessageSeverity.warning);
      expect(
        warning.arguments['state']?.kind,
        StructuredMessageArgumentKind.identifier,
      );
      expect(warning.arguments['state']?.value, 'q-unused');
    });
  });
}
