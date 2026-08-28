import 'dart:convert';
import 'dart:math' as math;
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:turing_lab/core/algorithms/tm_block_dependency_analyzer.dart';
import 'package:turing_lab/core/algorithms/tm_block_execution_engine.dart';
import 'package:turing_lab/core/algorithms/tm_block_inline_expander.dart';
import 'package:turing_lab/core/algorithms/tm_execution_analyzer.dart';
import 'package:turing_lab/core/formal_systems/formal_systems.dart';
import 'package:turing_lab/core/interoperability/interoperability.dart';
import 'package:turing_lab/core/messages/structured_message.dart';
import 'package:turing_lab/core/models/state.dart';
import 'package:turing_lab/core/models/tm.dart';
import 'package:turing_lab/core/models/tm_block_execution.dart';
import 'package:turing_lab/core/models/tm_building_blocks.dart';
import 'package:turing_lab/core/models/tm_execution_analysis.dart';
import 'package:turing_lab/core/models/tm_transition.dart';
import 'package:turing_lab/core/models/transition.dart';
import 'package:turing_lab/core/services/tm_block_project_editor.dart';
import 'package:turing_lab/data/codecs/tm_jflap_document_codec.dart';
import 'package:turing_lab/data/codecs/tm_json_document_codec.dart';
import 'package:vector_math/vector_math_64.dart';

void main() {
  group('TM building-block project', () {
    test('round-trips stable definitions and invocation references', () {
      final project = _sharedTapeProject();

      final restored = TMBlockProject.fromJson(project.toJson());

      expect(restored.schemaVersion, TMBlockProject.currentSchemaVersion);
      expect(restored.tapeSemantics, TMBlockTapeSemantics.shared);
      expect(restored.rootMachine.blockDefinitions.keys, {'scan'});
      expect(restored.rootInvocations.single.id, 'call-scan');
      expect(restored.rootInvocations.single.reference.blockId, 'scan');
      expect(restored.definitions['scan']!.revision, 3);
    });

    test('migrates a standalone flat TM without synthetic blocks', () {
      final machine = _machine(
        id: 'flat',
        states: [_state('q0', initial: true, accepting: true)],
      );

      final project = TMBlockProject.fromFlatMachine(machine);

      expect(project.rootMachine, same(machine));
      expect(project.definitions, isEmpty);
      expect(project.rootInvocations, isEmpty);
    });
  });

  group('TM block dependency validation', () {
    test('produces a deterministic dependency-first order', () {
      final report = TMBlockDependencyAnalyzer.analyze(_nestedProject());

      expect(report.isValid, isTrue);
      expect(report.dependencies['root'], {'outer'});
      expect(report.dependencies['outer'], {'inner'});
      expect(
        report.topologicalOrder.indexOf('inner'),
        lessThan(report.topologicalOrder.indexOf('outer')),
      );
      expect(
        report.topologicalOrder.indexOf('outer'),
        lessThan(report.topologicalOrder.indexOf('root')),
      );
    });

    test('rejects missing, stale, and recursively dependent blocks', () {
      final aState = _state('a0', initial: true);
      final bState = _state('b0', initial: true);
      final a = TMBlockDefinition(
        id: 'a',
        name: 'Same',
        revision: 1,
        machine: _machine(id: 'a-machine', states: [aState]),
        invocations: [_invocation('a-to-b', aState.id, 'b', revision: 2)],
      );
      final b = TMBlockDefinition(
        id: 'b',
        name: 'same',
        revision: 1,
        machine: _machine(id: 'b-machine', states: [bState]),
        invocations: [_invocation('b-to-a', bState.id, 'a')],
      );
      final rootState = _state('root-call', initial: true);
      final root = _machine(
        id: 'root',
        states: [rootState],
        definitions: {'a': a, 'b': b},
        invocations: [_invocation('missing', rootState.id, 'absent')],
      );

      final report = TMBlockDependencyAnalyzer.analyze(
        TMBlockProject(rootMachine: root),
      );
      final codes = report.diagnostics.map((value) => value.code).toSet();

      expect(report.isValid, isFalse);
      expect(codes, contains(TMBlockDiagnosticCode.duplicateBlockName));
      expect(codes, contains(TMBlockDiagnosticCode.missingReference));
      expect(codes, contains(TMBlockDiagnosticCode.revisionMismatch));
      expect(codes, contains(TMBlockDiagnosticCode.recursiveDependency));
      expect(report.cycles, [
        ['a', 'b', 'a'],
      ]);
    });

    test('rejects a block that reuses the root machine identity', () {
      final blockState = _state('block', initial: true);
      final block = TMBlockDefinition(
        id: 'root',
        name: 'Conflicting block',
        revision: 1,
        machine: _machine(id: 'block-machine', states: [blockState]),
      );
      final root = _machine(
        id: 'root',
        states: [_state('root-state', initial: true)],
        definitions: {'root': block},
      );

      final report = TMBlockDependencyAnalyzer.analyze(
        TMBlockProject(rootMachine: root),
      );

      expect(report.isValid, isFalse);
      expect(
        report.diagnostics.map((diagnostic) => diagnostic.code),
        contains(TMBlockDiagnosticCode.duplicateMachineId),
      );
    });
  });

  group('TM block execution', () {
    test('shares tape and head state across call and return', () {
      final result = TMBlockExecutionEngine.execute(_sharedTapeProject(), '0');

      expect(result.outcome, TMExecutionOutcome.accepted);
      expect(result.finalTapes.single, {0: '1'});
      expect(result.finalHeadPositions, [0]);
      expect(result.metrics.transitionSteps, 2);
      expect(result.metrics.blockEntries, 1);
      expect(result.metrics.blockReturns, 1);
      expect(result.metrics.maximumCallDepth, 1);
      expect(result.stepsExecuted, 4);
      expect(result.trace.map((step) => step.action), [
        TMBlockTraceAction.enterBlock,
        TMBlockTraceAction.transition,
        TMBlockTraceAction.returnFromBlock,
        TMBlockTraceAction.transition,
      ]);
      expect(result.trace[1].machineId, 'scan');
      expect(result.trace[1].transitionId, 'scan-write');
      expect(result.trace[1].callStack.single.parentMachineId, 'root');
    });

    test('ignores internal accepting states and returns only on halt', () {
      final result = TMBlockExecutionEngine.execute(
        _sharedTapeProject(internalAccepting: true),
        '0',
      );

      expect(result.outcome, TMExecutionOutcome.accepted);
      expect(result.metrics.blockReturns, 1);
      expect(
        result.trace.where(
          (step) => step.action == TMBlockTraceAction.returnFromBlock,
        ),
        hasLength(1),
      );
    });

    test('executes nested composition with a visible call hierarchy', () {
      final result = TMBlockExecutionEngine.execute(_nestedProject(), '0');

      expect(result.outcome, TMExecutionOutcome.accepted);
      expect(result.metrics.maximumCallDepth, 2);
      expect(result.finalTapes.single, {0: '1'});
      expect(
        result.trace
            .where((step) => step.action == TMBlockTraceAction.enterBlock)
            .map((step) => step.targetMachineId),
        ['outer', 'inner'],
      );
    });

    test('explores nondeterministic submachine branches', () {
      final project = _sharedTapeProject(nondeterministic: true);

      final result = TMBlockExecutionEngine.execute(project, '0');

      expect(result.outcome, TMExecutionOutcome.accepted);
      expect(result.finalTapes.single, {0: '1'});
      expect(result.configurationsExplored, greaterThan(4));
    });

    test('rejects recursive projects before execution', () {
      final state = _state('loop', initial: true);
      final definition = TMBlockDefinition(
        id: 'recursive',
        name: 'Recursive',
        revision: 1,
        machine: _machine(id: 'recursive-machine', states: [state]),
        invocations: [_invocation('self', state.id, 'recursive')],
      );
      final rootState = _state('call', initial: true);
      final root = _machine(
        id: 'root',
        states: [rootState],
        definitions: {'recursive': definition},
        invocations: [_invocation('root-call', rootState.id, 'recursive')],
      );

      final result = TMBlockExecutionEngine.execute(
        TMBlockProject(rootMachine: root),
        '',
      );

      expect(result.outcome, TMExecutionOutcome.invalidMachine);
      expect(
        result.diagnostics.map((value) => value.code),
        contains(TMBlockDiagnosticCode.recursiveDependency),
      );
      expect(result.stepsExecuted, 0);
    });

    test('supports cancellation and explicit bounds in nested execution', () {
      final cancelled = TMBlockExecutionEngine.execute(
        _sharedTapeProject(),
        '0',
        isCancelled: () => true,
      );
      final bounded = TMBlockExecutionEngine.execute(
        _sharedTapeProject(),
        '0',
        maxSteps: 1,
      );

      expect(cancelled.outcome, TMExecutionOutcome.cancelled);
      expect(bounded.outcome, TMExecutionOutcome.boundedUnknown);
      expect(bounded.limit, TMExecutionLimit.steps);
    });

    test(
      'proves an exact cycle with the call stack in configuration identity',
      () {
        final q0 = _state('q0', initial: true);
        final loop = _transition('loop', q0, q0, read: 'B', write: 'B');
        final root = _machine(id: 'root', states: [q0], transitions: [loop]);

        final result = TMBlockExecutionEngine.execute(
          TMBlockProject(rootMachine: root),
          '',
        );

        expect(result.outcome, TMExecutionOutcome.provenCycle);
      },
    );
  });

  group('TM block inline expansion', () {
    test(
      'is deterministic, collision-safe, source-mapped, and equivalent',
      () async {
        final base = _sharedTapeProject();
        final collision = _state('inline:call-scan:state:scan-start');
        final rootWithCollision = base.rootMachine.copyWith(
          states: {...base.rootMachine.states, collision},
        );
        final project = TMBlockProject(rootMachine: rootWithCollision);

        final first = TMBlockInlineExpander.expand(project);
        final second = TMBlockInlineExpander.expand(project);

        expect(first.isSuccess, isTrue);
        expect(first.machine!.blockDefinitions, isEmpty);
        expect(first.machine!.blockInvocations, isEmpty);
        final firstStateIds =
            first.machine!.states.map((state) => state.id).toList()..sort();
        final secondStateIds =
            second.machine!.states.map((state) => state.id).toList()..sort();
        expect(firstStateIds, secondStateIds);
        expect(firstStateIds.toSet(), hasLength(firstStateIds.length));
        expect(firstStateIds, contains('inline:call-scan:state:scan-start#2'));
        final clonedState = first.stateSources.entries.firstWhere(
          (entry) => entry.value.elementId == 'scan-start',
        );
        expect(clonedState.value.machineId, 'scan');
        expect(clonedState.value.invocationPath, ['call-scan']);

        final flatResult = await TMExecutionAnalyzer.analyze(
          first.machine!,
          '0',
        );
        final nestedResult = TMBlockExecutionEngine.execute(project, '0');
        expect(flatResult.outcome, nestedResult.outcome);
      },
    );

    test('expands nested definitions without retaining invocation anchors', () {
      final result = TMBlockInlineExpander.expand(_nestedProject());

      expect(result.isSuccess, isTrue);
      expect(
        result.machine!.states.map((state) => state.id),
        isNot(contains('root-call')),
      );
      expect(
        result.stateSources.values.any(
          (source) =>
              source.machineId == 'inner' && source.invocationPath.length == 2,
        ),
        isTrue,
      );
    });
  });

  group('TM building-block codecs', () {
    test('Turing Lab JSON round-trips a nested project', () {
      final codec = TmJsonDocumentCodec();
      final encoded = codec.encode(_document(_nestedProject().rootMachine));
      expect(encoded, isA<CodecSuccess<EncodedDocument>>());

      final bytes = (encoded as CodecSuccess<EncodedDocument>).value.bytes;
      final decoded = codec.decode(
        DocumentPayload(bytes: bytes, filename: 'nested.json'),
      );

      expect(decoded, isA<CodecSuccess<InteroperableDocument<Object>>>());
      final machine =
          (decoded as CodecSuccess<InteroperableDocument<Object>>)
                  .value
                  .document
              as TM;
      expect(machine.blockDefinitions.keys, {'inner', 'outer'});
      expect(machine.blockInvocations.single.id, 'root-to-outer');
      expect(
        machine.blockDefinitions['outer']!.invocations.single.reference.blockId,
        'inner',
      );
    });

    test('JFLAP XML preserves nested definitions without flattening', () {
      const codec = TmJflapDocumentCodec();
      final encoded = codec.encode(_document(_nestedProject().rootMachine));
      expect(encoded, isA<CodecSuccess<EncodedDocument>>());
      final encodedSuccess = encoded as CodecSuccess<EncodedDocument>;
      expect(encodedSuccess.fidelity, DocumentFidelity.lossy);
      final encodedDocument = encodedSuccess.value;

      final decoded = codec.decode(
        DocumentPayload(bytes: encodedDocument.bytes, filename: 'nested.jff'),
      );

      expect(decoded, isA<CodecSuccess<InteroperableDocument<Object>>>());
      final machine =
          (decoded as CodecSuccess<InteroperableDocument<Object>>)
                  .value
                  .document
              as TM;
      expect(machine.blockDefinitions.keys, {'inner', 'outer'});
      expect(machine.blockInvocations.single.id, 'root-to-outer');
      expect(
        machine.blockDefinitions['outer']!.invocations.single.id,
        'outer-to-inner',
      );
      expect(machine.id, 'root');
      final innerMachine = machine.blockDefinitions['inner']!.machine;
      expect(innerMachine.id, 'inner-machine');
      expect(innerMachine.tmTransitions.single.id, 'inner-write');
      expect(innerMachine.tmTransitions.single.controlPoint, Vector2.zero());
      final result = TMBlockExecutionEngine.execute(
        TMBlockProject(rootMachine: machine),
        '0',
      );
      expect(result.outcome, TMExecutionOutcome.accepted);
    });

    test('JFLAP XML retains an unused block definition', () {
      const codec = TmJflapDocumentCodec();
      final rootState = _state('root', initial: true, accepting: true);
      final leafState = _state('leaf', initial: true, accepting: true);
      final leaf = _machine(id: 'leaf-machine', states: [leafState]);
      final definition = TMBlockDefinition(
        id: 'unused-leaf',
        name: 'Unused leaf',
        revision: 3,
        machine: leaf,
      );
      final root = _machine(
        id: 'root-machine',
        states: [rootState],
        definitions: {'unused-leaf': definition},
      );

      final encoded =
          codec.encode(_document(root)) as CodecSuccess<EncodedDocument>;
      final decoded =
          codec.decode(
                DocumentPayload(
                  bytes: encoded.value.bytes,
                  filename: 'unused.jff',
                ),
              )
              as CodecSuccess<InteroperableDocument<Object>>;
      final restored = decoded.value.document as TM;

      expect(restored.blockInvocations, isEmpty);
      expect(restored.blockDefinitions.keys, {'unused-leaf'});
      expect(restored.blockDefinitions['unused-leaf']!.revision, 3);
      expect(
        restored.blockDefinitions['unused-leaf']!.machine.id,
        'leaf-machine',
      );
    });

    test('JFLAP XML reports unknown building-block metadata as dropped', () {
      const codec = TmJflapDocumentCodec();
      final encoded =
          codec.encode(_document(_nestedProject().rootMachine))
              as CodecSuccess<EncodedDocument>;
      final xml = utf8
          .decode(encoded.value.bytes)
          .replaceFirst('<automaton ', '<automaton vendor="unknown" ');

      final decoded =
          codec.decode(
                DocumentPayload(
                  bytes: Uint8List.fromList(utf8.encode(xml)),
                  filename: 'unknown.jff',
                ),
              )
              as CodecSuccess<InteroperableDocument<Object>>;

      expect(decoded.fidelity, DocumentFidelity.lossy);
      expect(
        decoded.diagnostics.map((diagnostic) => diagnostic.code),
        contains('jflap.tm-building-block-unknown-extension-dropped'),
      );
    });

    test('JFLAP XML rejects unresolved block references explicitly', () {
      const codec = TmJflapDocumentCodec();
      final payload = DocumentPayload(
        filename: 'missing.jff',
        bytes: Uint8List.fromList(
          '''<?xml version="1.0" encoding="UTF-8"?>
<structure>
  <type>turing</type>
  <automaton>
    <block id="0" name="Missing">
      <tag>missing_definition</tag><x>10</x><y>10</y><initial/>
    </block>
  </automaton>
</structure>
'''
              .codeUnits,
        ),
      );

      final decoded = codec.decode(payload);

      expect(decoded, isA<CodecMalformed<InteroperableDocument<Object>>>());
      expect(
        (decoded as CodecMalformed<InteroperableDocument<Object>>).message,
        contains('no submachine definition'),
      );
    });
  });

  group('TM block project editing', () {
    test('returns stable structured failures with typed formal arguments', () {
      TMBlockProjectEditor editor() =>
          TMBlockProjectEditor(_sharedTapeProject());

      final cases =
          <
            ({
              String stableCode,
              Map<String, Object> arguments,
              TMBlockEditResult Function() run,
            })
          >[
            (
              stableCode: 'service.tm-block-editor.duplicate-block-id',
              arguments: const {'block': 'scan'},
              run: () {
                final current = editor();
                return current.createDefinition(
                  current.project.definitions['scan']!,
                );
              },
            ),
            (
              stableCode: 'service.tm-block-editor.duplicate-block-name',
              arguments: const {'name': 'Scan'},
              run: () {
                final current = editor();
                return current.createDefinition(
                  current.project.definitions['scan']!.copyWith(id: 'other'),
                );
              },
            ),
            (
              stableCode: 'service.tm-block-editor.invalid-block-name',
              arguments: const {},
              run: () => editor().renameDefinition('scan', '  '),
            ),
            (
              stableCode: 'service.tm-block-editor.referenced-block',
              arguments: const {'block': 'scan'},
              run: () => editor().deleteDefinition('scan'),
            ),
            (
              stableCode: 'service.tm-block-editor.missing-owner-machine',
              arguments: const {'machine': 'missing-owner'},
              run: () => editor().upsertInvocation(
                ownerMachineId: 'missing-owner',
                invocation: _invocation(
                  'new-call',
                  'call',
                  'scan',
                  revision: 3,
                ),
              ),
            ),
            (
              stableCode: 'service.tm-block-editor.missing-anchor-state',
              arguments: const {'state': 'missing-state', 'machine': 'root'},
              run: () => editor().upsertInvocation(
                ownerMachineId: 'root',
                invocation: _invocation(
                  'new-call',
                  'missing-state',
                  'scan',
                  revision: 3,
                ),
              ),
            ),
            (
              stableCode: 'service.tm-block-editor.state-already-invokes-block',
              arguments: const {'state': 'call'},
              run: () => editor().upsertInvocation(
                ownerMachineId: 'root',
                invocation: _invocation(
                  'other-call',
                  'call',
                  'scan',
                  revision: 3,
                ),
              ),
            ),
            (
              stableCode: 'service.tm-block-editor.duplicate-root-state',
              arguments: const {'state': 'call'},
              run: () => editor().insertRootInvocation(
                anchor: _state('call'),
                invocationId: 'other-call',
                blockId: 'scan',
              ),
            ),
            (
              stableCode: 'service.tm-block-editor.missing-invocation',
              arguments: const {'invocation': 'missing-call'},
              run: () => editor().removeInvocation('root', 'missing-call'),
            ),
            (
              stableCode: 'service.tm-block-editor.nothing-to-undo',
              arguments: const {},
              run: () => editor().undo(),
            ),
            (
              stableCode: 'service.tm-block-editor.nothing-to-redo',
              arguments: const {},
              run: () => editor().redo(),
            ),
            (
              stableCode: 'service.tm-block-editor.missing-block',
              arguments: const {'block': 'missing-block'},
              run: () => editor().renameDefinition('missing-block', 'Missing'),
            ),
          ];

      for (final testCase in cases) {
        final result = testCase.run();
        final message = result.structuredMessage!;

        expect(result.isSuccess, isFalse, reason: testCase.stableCode);
        expect(message.stableCode, testCase.stableCode);
        expect(message.category, StructuredMessageCategory.validation);
        expect(message.severity, StructuredMessageSeverity.error);
        expect(
          message.arguments.map((key, value) => MapEntry(key, value.value)),
          testCase.arguments,
          reason: testCase.stableCode,
        );
        expect(StructuredMessage.fromJson(message.toJson()), message);
        expect(result.compatibilityDetail, isNull);
        expect(result.message, testCase.stableCode);
      }
    });

    test(
      'invalid project keeps analyzer prose only as compatibility detail',
      () {
        final editor = TMBlockProjectEditor(_sharedTapeProject());
        final scanState =
            editor.project.definitions['scan']!.machine.initialState!;

        final result = editor.upsertInvocation(
          ownerMachineId: 'scan',
          invocation: _invocation(
            'recursive',
            scanState.id,
            'scan',
            revision: 3,
          ),
        );

        expect(result.errorCode, TMBlockEditErrorCode.invalidProject);
        expect(
          result.structuredMessage?.stableCode,
          'service.tm-block-editor.invalid-project',
        );
        expect(
          result.structuredMessage?.arguments['diagnostic']?.value,
          TMBlockDiagnosticCode.recursiveDependency.name,
        );
        expect(
          result.compatibilityDetail,
          contains('Recursive block dependency'),
        );
        expect(result.message, result.compatibilityDetail);
      },
    );

    test('rename preserves stable references', () {
      final editor = TMBlockProjectEditor(_sharedTapeProject());

      final result = editor.renameDefinition('scan', 'Scanner');

      expect(result.isSuccess, isTrue);
      expect(result.project.definitions['scan']!.name, 'Scanner');
      expect(result.project.rootInvocations.single.reference.blockId, 'scan');
      expect(result.project.rootInvocations.single.reference.revision, 3);
    });

    test('referenced deletion requires resolution and is undoable', () {
      final editor = TMBlockProjectEditor(_sharedTapeProject());

      final blocked = editor.deleteDefinition('scan');
      expect(blocked.errorCode, TMBlockEditErrorCode.referencedBlock);
      expect(editor.project.definitions, contains('scan'));

      final deleted = editor.deleteDefinition(
        'scan',
        resolution: TMBlockDeleteResolution.detachInvocations,
      );
      expect(deleted.isSuccess, isTrue);
      expect(deleted.project.definitions, isEmpty);
      expect(deleted.project.rootInvocations, isEmpty);
      expect(
        deleted.project.rootMachine.states.map((state) => state.id),
        contains('call'),
      );

      expect(editor.undo().project.definitions, contains('scan'));
      expect(editor.redo().project.definitions, isEmpty);
    });

    test('machine replacement updates revisioned references atomically', () {
      final editor = TMBlockProjectEditor(_sharedTapeProject());
      final replacement = editor.project.definitions['scan']!.machine.copyWith(
        name: 'Updated scan',
      );

      final result = editor.replaceDefinitionMachine('scan', replacement);

      expect(result.isSuccess, isTrue);
      expect(result.project.definitions['scan']!.revision, 4);
      expect(result.project.rootInvocations.single.reference.revision, 4);
    });

    test('duplicate uses a new stable identity and recursion is rejected', () {
      final editor = TMBlockProjectEditor(_sharedTapeProject());
      final duplicate = editor.duplicateDefinition(
        'scan',
        newId: 'scan-copy',
        newName: 'Scan copy',
      );
      expect(duplicate.isSuccess, isTrue);
      expect(duplicate.project.definitions['scan-copy']!.revision, 1);

      final scanState =
          duplicate.project.definitions['scan']!.machine.initialState!;
      final recursive = editor.upsertInvocation(
        ownerMachineId: 'scan',
        invocation: _invocation('recursive', scanState.id, 'scan', revision: 3),
      );
      expect(recursive.errorCode, TMBlockEditErrorCode.invalidProject);
      expect(editor.project.definitions['scan']!.invocations, isEmpty);
    });
  });
}

InteroperableDocument<Object> _document(TM machine) {
  return InteroperableDocument<Object>(
    document: machine,
    systemKey: DefaultFormalSystemIds.tm,
    schema: TmJsonDocumentCodec.schema,
  );
}

TMBlockProject _sharedTapeProject({
  bool internalAccepting = false,
  bool nondeterministic = false,
}) {
  final scanStart = _state('scan-start', initial: true);
  final scanHalt = _state('scan-halt', accepting: internalAccepting);
  final scanTransitions = <TMTransition>[
    _transition('scan-write', scanStart, scanHalt, read: '0', write: '1'),
    if (nondeterministic)
      _transition(
        'scan-reject-branch',
        scanStart,
        scanHalt,
        read: '0',
        write: '0',
        type: TransitionType.nondeterministic,
      ),
  ];
  final scan = TMBlockDefinition(
    id: 'scan',
    name: 'Scan',
    revision: 3,
    machine: _machine(
      id: 'scan-machine',
      states: [scanStart, scanHalt],
      transitions: scanTransitions,
    ),
  );
  final call = _state('call', initial: true);
  final accept = _state('accept', accepting: true);
  final root = _machine(
    id: 'root',
    states: [call, accept],
    transitions: [
      _transition('root-accept', call, accept, read: '1', write: '1'),
    ],
    definitions: {'scan': scan},
    invocations: [_invocation('call-scan', call.id, 'scan', revision: 3)],
  );
  return TMBlockProject(rootMachine: root);
}

TMBlockProject _nestedProject() {
  final innerStart = _state('inner-start', initial: true);
  final innerHalt = _state('inner-halt');
  final inner = TMBlockDefinition(
    id: 'inner',
    name: 'Inner',
    revision: 1,
    machine: _machine(
      id: 'inner-machine',
      states: [innerStart, innerHalt],
      transitions: [
        _transition(
          'inner-write',
          innerStart,
          innerHalt,
          read: '0',
          write: '1',
        ),
      ],
    ),
  );
  final outerCall = _state('outer-call', initial: true);
  final outerHalt = _state('outer-halt');
  final outer = TMBlockDefinition(
    id: 'outer',
    name: 'Outer',
    revision: 1,
    machine: _machine(
      id: 'outer-machine',
      states: [outerCall, outerHalt],
      transitions: [
        _transition(
          'outer-finish',
          outerCall,
          outerHalt,
          read: '1',
          write: '1',
        ),
      ],
    ),
    invocations: [_invocation('outer-to-inner', outerCall.id, 'inner')],
  );
  final rootCall = _state('root-call', initial: true);
  final rootAccept = _state('root-accept', accepting: true);
  final root = _machine(
    id: 'root',
    states: [rootCall, rootAccept],
    transitions: [
      _transition('root-finish', rootCall, rootAccept, read: '1', write: '1'),
    ],
    definitions: {'inner': inner, 'outer': outer},
    invocations: [_invocation('root-to-outer', rootCall.id, 'outer')],
  );
  return TMBlockProject(rootMachine: root);
}

State _state(String id, {bool initial = false, bool accepting = false}) {
  return State(
    id: id,
    label: id,
    position: Vector2(100, 100),
    isInitial: initial,
    isAccepting: accepting,
  );
}

TMTransition _transition(
  String id,
  State from,
  State to, {
  required String read,
  required String write,
  TransitionType type = TransitionType.deterministic,
}) {
  return TMTransition(
    id: id,
    fromState: from,
    toState: to,
    label: TMTransition.formatLabel(
      readSymbol: read,
      writeSymbol: write,
      direction: TapeDirection.stay,
    ),
    readSymbol: read,
    writeSymbol: write,
    direction: TapeDirection.stay,
    type: type,
    controlPoint: from == to ? Vector2(100, 50) : Vector2.zero(),
  );
}

TMBlockInvocationNode _invocation(
  String id,
  String stateId,
  String blockId, {
  int revision = 1,
}) {
  return TMBlockInvocationNode(
    id: id,
    stateId: stateId,
    reference: TMBlockReference(blockId: blockId, revision: revision),
  );
}

TM _machine({
  required String id,
  required List<State> states,
  List<TMTransition> transitions = const [],
  Map<String, TMBlockDefinition> definitions = const {},
  List<TMBlockInvocationNode> invocations = const [],
}) {
  final initial = states.where((state) => state.isInitial).firstOrNull;
  return TM(
    id: id,
    name: id,
    states: states.toSet(),
    transitions: transitions.toSet(),
    alphabet: {'0', '1'},
    initialState: initial,
    acceptingStates: states.where((state) => state.isAccepting).toSet(),
    created: DateTime.utc(2026),
    modified: DateTime.utc(2026),
    bounds: const math.Rectangle(0, 0, 800, 600),
    tapeAlphabet: {'0', '1', 'B'},
    blankSymbol: 'B',
    tapeCount: 1,
    blockDefinitions: definitions,
    blockInvocations: invocations,
  );
}

extension<T> on Iterable<T> {
  T? get firstOrNull => this.isEmpty ? null : first;
}
