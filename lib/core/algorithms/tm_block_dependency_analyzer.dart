import '../models/tm.dart';
import '../models/tm_building_blocks.dart';
import 'tm_building_block_messages.dart';

/// Validates a compositional TM project and orders its reusable definitions.
class TMBlockDependencyAnalyzer {
  const TMBlockDependencyAnalyzer._();

  static TMBlockDependencyReport analyze(TMBlockProject project) {
    final diagnostics = <TMBlockDiagnostic>[];
    final dependencies = <String, Set<String>>{
      project.rootMachine.id: <String>{},
      for (final id in project.definitions.keys) id: <String>{},
    };

    final normalizedNames = <String, String>{};
    final sortedDefinitions = project.definitions.values.toList()
      ..sort((a, b) => a.id.compareTo(b.id));
    for (final definition in sortedDefinitions) {
      if (definition.id == project.rootMachine.id) {
        diagnostics.add(
          TMBlockDiagnostic(
            code: TMBlockDiagnosticCode.duplicateMachineId,
            severity: TMBlockDiagnosticSeverity.error,
            message: 'Block ${definition.name} reuses the root machine ID.',
            machineId: project.rootMachine.id,
            blockId: definition.id,
            structuredMessage: TmBuildingBlockMessages.duplicateMachineId(
              definition.name,
            ),
          ),
        );
      }
      final normalized = definition.name.trim().toLowerCase();
      final previous = normalizedNames[normalized];
      if (normalized.isEmpty || previous != null) {
        diagnostics.add(
          TMBlockDiagnostic(
            code: TMBlockDiagnosticCode.duplicateBlockName,
            severity: TMBlockDiagnosticSeverity.error,
            message: normalized.isEmpty
                ? 'Block ${definition.id} has an empty display name.'
                : 'Blocks $previous and ${definition.id} have the same name.',
            blockId: definition.id,
            structuredMessage: normalized.isEmpty
                ? TmBuildingBlockMessages.emptyBlockName(definition.id)
                : TmBuildingBlockMessages.duplicateBlockName(
                    firstBlockId: previous!,
                    secondBlockId: definition.id,
                  ),
          ),
        );
      } else {
        normalizedNames[normalized] = definition.id;
      }
      if (definition.machine.initialState == null) {
        diagnostics.add(
          TMBlockDiagnostic(
            code: TMBlockDiagnosticCode.missingInitialState,
            severity: TMBlockDiagnosticSeverity.error,
            message: 'Block ${definition.name} has no initial state.',
            blockId: definition.id,
            structuredMessage: TmBuildingBlockMessages.missingInitialState(
              definition.name,
            ),
          ),
        );
      }
      if (definition.machine.tapeCount != project.rootMachine.tapeCount) {
        diagnostics.add(
          TMBlockDiagnostic(
            code: TMBlockDiagnosticCode.tapeCountMismatch,
            severity: TMBlockDiagnosticSeverity.error,
            message:
                'Block ${definition.name} uses '
                '${definition.machine.tapeCount} tapes; the root uses '
                '${project.rootMachine.tapeCount}.',
            blockId: definition.id,
            structuredMessage: TmBuildingBlockMessages.tapeCountMismatch(
              blockName: definition.name,
              blockTapeCount: definition.machine.tapeCount,
              rootTapeCount: project.rootMachine.tapeCount,
            ),
          ),
        );
      }
      if (definition.machine.blankSymbol != project.rootMachine.blankSymbol) {
        diagnostics.add(
          TMBlockDiagnostic(
            code: TMBlockDiagnosticCode.blankSymbolMismatch,
            severity: TMBlockDiagnosticSeverity.error,
            message: 'Block ${definition.name} uses a different blank symbol.',
            blockId: definition.id,
            structuredMessage: TmBuildingBlockMessages.blankSymbolMismatch(
              definition.name,
            ),
          ),
        );
      }
      if (definition.machine.blockDefinitions.isNotEmpty ||
          definition.machine.blockInvocations.isNotEmpty) {
        diagnostics.add(
          TMBlockDiagnostic(
            code: TMBlockDiagnosticCode.nestedLibrary,
            severity: TMBlockDiagnosticSeverity.error,
            message:
                'Block ${definition.name} contains an embedded library; '
                'nested calls must use the project-level invocation list.',
            blockId: definition.id,
            structuredMessage: TmBuildingBlockMessages.nestedLibrary(
              definition.name,
            ),
          ),
        );
      }
    }

    _validateInvocations(
      project: project,
      ownerId: project.rootMachine.id,
      machine: project.rootMachine,
      invocations: project.rootInvocations,
      dependencies: dependencies,
      diagnostics: diagnostics,
    );
    for (final definition in sortedDefinitions) {
      _validateInvocations(
        project: project,
        ownerId: definition.id,
        machine: definition.machine,
        invocations: definition.invocations,
        dependencies: dependencies,
        diagnostics: diagnostics,
      );
    }

    final cycles = _findCycles(dependencies);
    for (final cycle in cycles) {
      diagnostics.add(
        TMBlockDiagnostic(
          code: TMBlockDiagnosticCode.recursiveDependency,
          severity: TMBlockDiagnosticSeverity.error,
          message: 'Recursive block dependency: ${cycle.join(' -> ')}.',
          machineId: cycle.first,
          blockId: cycle.length > 1 ? cycle[1] : cycle.first,
          structuredMessage: TmBuildingBlockMessages.recursiveDependency(
            cycle.join(' -> '),
          ),
        ),
      );
    }

    return TMBlockDependencyReport(
      dependencies: dependencies,
      topologicalOrder: cycles.isEmpty
          ? _topologicalOrder(dependencies)
          : const [],
      cycles: cycles,
      diagnostics: diagnostics,
    );
  }

  static void _validateInvocations({
    required TMBlockProject project,
    required String ownerId,
    required TM machine,
    required List<TMBlockInvocationNode> invocations,
    required Map<String, Set<String>> dependencies,
    required List<TMBlockDiagnostic> diagnostics,
  }) {
    final invocationIds = <String>{};
    final stateIds = <String>{};
    final machineStateIds = machine.states.map((state) => state.id).toSet();
    final sorted = invocations.toList()..sort((a, b) => a.id.compareTo(b.id));
    for (final invocation in sorted) {
      if (!invocationIds.add(invocation.id)) {
        diagnostics.add(
          TMBlockDiagnostic(
            code: TMBlockDiagnosticCode.duplicateInvocationId,
            severity: TMBlockDiagnosticSeverity.error,
            message: 'Invocation ID ${invocation.id} is duplicated.',
            machineId: ownerId,
            invocationId: invocation.id,
            structuredMessage: TmBuildingBlockMessages.duplicateInvocationId(
              invocation.id,
            ),
          ),
        );
      }
      if (!stateIds.add(invocation.stateId)) {
        diagnostics.add(
          TMBlockDiagnostic(
            code: TMBlockDiagnosticCode.duplicateInvocationState,
            severity: TMBlockDiagnosticSeverity.error,
            message: 'State ${invocation.stateId} invokes more than one block.',
            machineId: ownerId,
            invocationId: invocation.id,
            structuredMessage: TmBuildingBlockMessages.duplicateInvocationState(
              invocation.stateId,
            ),
          ),
        );
      }
      if (!machineStateIds.contains(invocation.stateId)) {
        diagnostics.add(
          TMBlockDiagnostic(
            code: TMBlockDiagnosticCode.missingAnchorState,
            severity: TMBlockDiagnosticSeverity.error,
            message: 'Invocation ${invocation.id} has no graph state.',
            machineId: ownerId,
            invocationId: invocation.id,
            structuredMessage: TmBuildingBlockMessages.missingAnchorState(
              invocation.id,
            ),
          ),
        );
      }
      final definition = project.definitions[invocation.reference.blockId];
      if (definition == null) {
        diagnostics.add(
          TMBlockDiagnostic(
            code: TMBlockDiagnosticCode.missingReference,
            severity: TMBlockDiagnosticSeverity.error,
            message:
                'Invocation ${invocation.id} references missing block '
                '${invocation.reference.blockId}.',
            machineId: ownerId,
            invocationId: invocation.id,
            blockId: invocation.reference.blockId,
            structuredMessage: TmBuildingBlockMessages.missingReference(
              invocationId: invocation.id,
              blockId: invocation.reference.blockId,
            ),
          ),
        );
        continue;
      }
      dependencies[ownerId]!.add(definition.id);
      if (definition.revision != invocation.reference.revision) {
        diagnostics.add(
          TMBlockDiagnostic(
            code: TMBlockDiagnosticCode.revisionMismatch,
            severity: TMBlockDiagnosticSeverity.error,
            message:
                'Invocation ${invocation.id} expects revision '
                '${invocation.reference.revision}, but ${definition.name} is '
                'revision ${definition.revision}.',
            machineId: ownerId,
            invocationId: invocation.id,
            blockId: definition.id,
            structuredMessage: TmBuildingBlockMessages.revisionMismatch(
              invocationId: invocation.id,
              expectedRevision: invocation.reference.revision,
              blockName: definition.name,
              actualRevision: definition.revision,
            ),
          ),
        );
      }
    }
  }

  static List<List<String>> _findCycles(Map<String, Set<String>> graph) {
    final cycles = <List<String>>[];
    final state = <String, int>{};
    final path = <String>[];
    final seenCycleKeys = <String>{};

    void visit(String node) {
      state[node] = 1;
      path.add(node);
      final nextNodes = graph[node]!.toList()..sort();
      for (final next in nextNodes) {
        if (state[next] == 1) {
          final start = path.indexOf(next);
          final cycle = [...path.sublist(start), next];
          final normalized = _normalizeCycle(cycle);
          final key = normalized.join('\u0000');
          if (seenCycleKeys.add(key)) cycles.add(normalized);
        } else if (state[next] != 2) {
          visit(next);
        }
      }
      path.removeLast();
      state[node] = 2;
    }

    final nodes = graph.keys.toList()..sort();
    for (final node in nodes) {
      if (state[node] == null) visit(node);
    }
    cycles.sort((a, b) => a.join('\u0000').compareTo(b.join('\u0000')));
    return cycles;
  }

  static List<String> _normalizeCycle(List<String> closedCycle) {
    final cycle = closedCycle.sublist(0, closedCycle.length - 1);
    var smallest = 0;
    for (var index = 1; index < cycle.length; index++) {
      if (cycle[index].compareTo(cycle[smallest]) < 0) smallest = index;
    }
    final rotated = [...cycle.sublist(smallest), ...cycle.sublist(0, smallest)];
    return [...rotated, rotated.first];
  }

  static List<String> _topologicalOrder(Map<String, Set<String>> graph) {
    final visited = <String>{};
    final order = <String>[];

    void visit(String node) {
      if (!visited.add(node)) return;
      final dependencies = graph[node]!.toList()..sort();
      for (final dependency in dependencies) {
        visit(dependency);
      }
      order.add(node);
    }

    final nodes = graph.keys.toList()..sort();
    for (final node in nodes) {
      visit(node);
    }
    return order;
  }
}
