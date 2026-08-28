import '../models/state.dart';
import '../models/tm.dart';
import '../models/tm_building_blocks.dart';
import '../models/tm_inline_expansion.dart';
import '../models/tm_transition.dart';
import '../models/transition.dart';
import 'tm_building_block_messages.dart';
import 'tm_block_dependency_analyzer.dart';

/// Compiles a nonrecursive building-block project into one flat TM graph.
class TMBlockInlineExpander {
  const TMBlockInlineExpander._();

  static TMInlineExpansionResult expand(TMBlockProject project) {
    final report = TMBlockDependencyAnalyzer.analyze(project);
    final diagnostics = [...report.diagnostics];
    for (final invocation in project.rootInvocations) {
      final state = _stateById(project.rootMachine, invocation.stateId);
      if (state?.isAccepting ?? false) {
        diagnostics.add(
          TMBlockDiagnostic(
            code: TMBlockDiagnosticCode.nestedLibrary,
            severity: TMBlockDiagnosticSeverity.error,
            message:
                'An accepting root invocation cannot be inlined without '
                'changing accept-before-call semantics.',
            machineId: project.rootMachine.id,
            invocationId: invocation.id,
            blockId: invocation.reference.blockId,
            structuredMessage: TmBuildingBlockMessages.acceptingRootInvocation(
              invocationId: invocation.id,
              blockId: invocation.reference.blockId,
            ),
          ),
        );
      }
    }
    if (diagnostics.any(
      (diagnostic) => diagnostic.severity == TMBlockDiagnosticSeverity.error,
    )) {
      return TMInlineExpansionResult.failure(diagnostics: diagnostics);
    }

    final memo = <String, _ExpandedGraph>{};

    _ExpandedGraph expandDefinition(String id) {
      final cached = memo[id];
      if (cached != null) return cached;
      final definition = project.definitions[id]!;
      var graph = _ExpandedGraph.original(definition.machine, id);
      final invocations = definition.invocations.toList()
        ..sort((a, b) => a.id.compareTo(b.id));
      for (final invocation in invocations) {
        graph = _inline(
          parent: graph,
          invocation: invocation,
          child: expandDefinition(invocation.reference.blockId),
        );
      }
      memo[id] = graph;
      return graph;
    }

    var root = _ExpandedGraph.original(
      project.rootMachine,
      project.rootMachine.id,
    );
    final invocations = project.rootInvocations.toList()
      ..sort((a, b) => a.id.compareTo(b.id));
    for (final invocation in invocations) {
      root = _inline(
        parent: root,
        invocation: invocation,
        child: expandDefinition(invocation.reference.blockId),
      );
    }

    final flat = root.machine.copyWith(
      blockDefinitions: const {},
      blockInvocations: const [],
    );
    return TMInlineExpansionResult.success(
      machine: flat,
      stateSources: root.stateSources,
      transitionSources: root.transitionSources,
    );
  }

  static _ExpandedGraph _inline({
    required _ExpandedGraph parent,
    required TMBlockInvocationNode invocation,
    required _ExpandedGraph child,
  }) {
    final anchor = _stateById(parent.machine, invocation.stateId)!;
    final usedStateIds = parent.machine.states.map((state) => state.id).toSet()
      ..remove(anchor.id);
    final childStates = child.machine.states.toList()
      ..sort((a, b) => a.id.compareTo(b.id));
    final childStateIds = <String, String>{};
    final states = parent.machine.states
        .where((state) => state.id != anchor.id)
        .map((state) => state.copyWith())
        .toList();
    final stateById = {for (final state in states) state.id: state};
    final childInitialId = child.machine.initialState!.id;
    for (final source in childStates) {
      final id = _uniqueId(
        'inline:${invocation.id}:state:${source.id}',
        usedStateIds,
      );
      childStateIds[source.id] = id;
      final cloned = source.copyWith(
        id: id,
        label: source.label,
        isInitial: anchor.isInitial && source.id == childInitialId,
        isAccepting: false,
      );
      states.add(cloned);
      stateById[id] = cloned;
    }
    final clonedInitial = stateById[childStateIds[childInitialId]]!;

    final usedTransitionIds = <String>{};
    final transitions = <TMTransition>[];
    final transitionSources = <String, TMInlineSource>{};
    final parentTransitions = parent.machine.tmTransitions.toList()
      ..sort((a, b) => a.id.compareTo(b.id));
    final outgoing = parentTransitions
        .where((transition) => transition.fromState.id == anchor.id)
        .toList();

    for (final transition in parentTransitions) {
      if (transition.fromState.id == anchor.id) continue;
      final from = stateById[transition.fromState.id]!;
      final to = transition.toState.id == anchor.id
          ? clonedInitial
          : stateById[transition.toState.id]!;
      final id = _uniqueId(transition.id, usedTransitionIds);
      transitions.add(
        transition.copyWith(id: id, fromState: from, toState: to),
      );
      transitionSources[id] = parent.transitionSources[transition.id]!;
    }

    final childTransitions = child.machine.tmTransitions.toList()
      ..sort((a, b) => a.id.compareTo(b.id));
    for (final transition in childTransitions) {
      final id = _uniqueId(
        'inline:${invocation.id}:transition:${transition.id}',
        usedTransitionIds,
      );
      transitions.add(
        transition.copyWith(
          id: id,
          fromState: stateById[childStateIds[transition.fromState.id]]!,
          toState: stateById[childStateIds[transition.toState.id]]!,
        ),
      );
      final source = child.transitionSources[transition.id]!;
      transitionSources[id] = TMInlineSource(
        machineId: source.machineId,
        elementId: source.elementId,
        invocationPath: [invocation.id, ...source.invocationPath],
      );
    }

    final childReadsByState = <String, Set<String>>{};
    for (final transition in childTransitions) {
      childReadsByState
          .putIfAbsent(transition.fromState.id, () => <String>{})
          .add(_readKey(transition));
    }
    for (final sourceState in childStates) {
      final from = stateById[childStateIds[sourceState.id]]!;
      final childReads = childReadsByState[sourceState.id] ?? const <String>{};
      for (final parentTransition in outgoing) {
        if (childReads.contains(_readKey(parentTransition))) continue;
        final target = parentTransition.toState.id == anchor.id
            ? clonedInitial
            : stateById[parentTransition.toState.id]!;
        final id = _uniqueId(
          'inline:${invocation.id}:return:${sourceState.id}:'
          '${parentTransition.id}',
          usedTransitionIds,
        );
        transitions.add(
          parentTransition.copyWith(id: id, fromState: from, toState: target),
        );
        transitionSources[id] = parent.transitionSources[parentTransition.id]!;
      }
    }

    final stateSources = <String, TMInlineSource>{};
    for (final state in states) {
      if (!childStateIds.containsValue(state.id)) {
        stateSources[state.id] = parent.stateSources[state.id]!;
      }
    }
    for (final source in childStates) {
      final childSource = child.stateSources[source.id]!;
      stateSources[childStateIds[source.id]!] = TMInlineSource(
        machineId: childSource.machineId,
        elementId: childSource.elementId,
        invocationPath: [invocation.id, ...childSource.invocationPath],
      );
    }

    final stateSet = states.toSet();
    final initial = states.where((state) => state.isInitial).firstOrNull;
    final machine = parent.machine.copyWith(
      states: stateSet,
      transitions: transitions.map<Transition>((value) => value).toSet(),
      initialState: initial,
      acceptingStates: states.where((state) => state.isAccepting).toSet(),
      tapeAlphabet: {
        ...parent.machine.tapeAlphabet,
        ...child.machine.tapeAlphabet,
      },
      alphabet: {...parent.machine.alphabet, ...child.machine.alphabet},
      blockDefinitions: const {},
      blockInvocations: const [],
    );
    return _ExpandedGraph(
      machine: machine,
      stateSources: stateSources,
      transitionSources: transitionSources,
    );
  }

  static String _readKey(TMTransition transition) => transition.readSymbols
      .map((symbol) => '${symbol.length}:$symbol')
      .join('|');

  static String _uniqueId(String preferred, Set<String> used) {
    if (used.add(preferred)) return preferred;
    var suffix = 2;
    while (!used.add('$preferred#$suffix')) {
      suffix++;
    }
    return '$preferred#$suffix';
  }

  static State? _stateById(TM machine, String stateId) {
    for (final state in machine.states) {
      if (state.id == stateId) return state;
    }
    return null;
  }
}

class _ExpandedGraph {
  const _ExpandedGraph({
    required this.machine,
    required this.stateSources,
    required this.transitionSources,
  });

  factory _ExpandedGraph.original(TM machine, String ownerId) {
    return _ExpandedGraph(
      machine: machine,
      stateSources: {
        for (final state in machine.states)
          state.id: TMInlineSource(
            machineId: ownerId,
            elementId: state.id,
            invocationPath: const [],
          ),
      },
      transitionSources: {
        for (final transition in machine.tmTransitions)
          transition.id: TMInlineSource(
            machineId: ownerId,
            elementId: transition.id,
            invocationPath: const [],
          ),
      },
    );
  }

  final TM machine;
  final Map<String, TMInlineSource> stateSources;
  final Map<String, TMInlineSource> transitionSources;
}

extension<T> on Iterable<T> {
  T? get firstOrNull => isEmpty ? null : first;
}
