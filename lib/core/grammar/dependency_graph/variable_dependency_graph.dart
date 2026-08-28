import '../../models/grammar.dart';
import '../../models/production.dart';
import '../../messages/structured_message.dart';
import '../phrase_structure/phrase_structure.dart';

enum VariableDependencyMode {
  directOccurrence,
  leftCorner,
  nullableAwareLeftCorner,
}

enum VariableDependencySourceKind { contextFree, unrestricted }

class VariableDependencyContribution {
  const VariableDependencyContribution({
    required this.productionId,
    required this.productionOrder,
    required this.leftPosition,
    required this.rightPosition,
  });

  final String productionId;
  final int productionOrder;
  final int leftPosition;
  final int rightPosition;
}

class VariableDependencyEdge {
  VariableDependencyEdge({
    required this.id,
    required this.from,
    required this.to,
    required Iterable<VariableDependencyContribution> contributions,
  }) : contributions = List<VariableDependencyContribution>.unmodifiable(
         contributions,
       );

  final String id;
  final String from;
  final String to;
  final List<VariableDependencyContribution> contributions;
}

class VariableDependencyCycleWitness {
  VariableDependencyCycleWitness({
    required Iterable<String> variables,
    required Iterable<String> edgeIds,
    required Iterable<String> productionIds,
  }) : variables = List<String>.unmodifiable(variables),
       edgeIds = List<String>.unmodifiable(edgeIds),
       productionIds = List<String>.unmodifiable(productionIds);

  final List<String> variables;
  final List<String> edgeIds;
  final List<String> productionIds;
}

class VariableDependencyPathWitness {
  VariableDependencyPathWitness({
    required Iterable<String> variables,
    required Iterable<String> edgeIds,
    required Iterable<String> productionIds,
  }) : variables = List<String>.unmodifiable(variables),
       edgeIds = List<String>.unmodifiable(edgeIds),
       productionIds = List<String>.unmodifiable(productionIds);

  final List<String> variables;
  final List<String> edgeIds;
  final List<String> productionIds;
}

class VariableDependencyGraphReport {
  VariableDependencyGraphReport({
    required this.sourceGrammarId,
    required this.sourceRevision,
    required this.sourceKind,
    required this.mode,
    required Iterable<String> variables,
    required Iterable<VariableDependencyEdge> edges,
    required Iterable<String> reachableVariables,
    required Iterable<String> productiveVariables,
    required Iterable<List<String>> stronglyConnectedComponents,
    required Iterable<List<String>> componentTopologicalOrder,
    required Iterable<VariableDependencyCycleWitness> cycleWitnesses,
    required Map<String, VariableDependencyPathWitness> reachabilityWitnesses,
    required Iterable<String> sourceVariables,
    required Iterable<String> sinkVariables,
    required this.productivityAvailable,
  }) : variables = List<String>.unmodifiable(variables),
       edges = List<VariableDependencyEdge>.unmodifiable(edges),
       reachableVariables = Set<String>.unmodifiable(reachableVariables),
       productiveVariables = Set<String>.unmodifiable(productiveVariables),
       stronglyConnectedComponents = List<List<String>>.unmodifiable(
         stronglyConnectedComponents.map(List<String>.unmodifiable),
       ),
       componentTopologicalOrder = List<List<String>>.unmodifiable(
         componentTopologicalOrder.map(List<String>.unmodifiable),
       ),
       cycleWitnesses = List<VariableDependencyCycleWitness>.unmodifiable(
         cycleWitnesses,
       ),
       reachabilityWitnesses =
           Map<String, VariableDependencyPathWitness>.unmodifiable(
             reachabilityWitnesses,
           ),
       sourceVariables = Set<String>.unmodifiable(sourceVariables),
       sinkVariables = Set<String>.unmodifiable(sinkVariables);

  final String sourceGrammarId;
  final int sourceRevision;
  final VariableDependencySourceKind sourceKind;
  final VariableDependencyMode mode;
  final List<String> variables;
  final List<VariableDependencyEdge> edges;
  final Set<String> reachableVariables;
  final Set<String> productiveVariables;
  final List<List<String>> stronglyConnectedComponents;
  final List<List<String>> componentTopologicalOrder;
  final List<VariableDependencyCycleWitness> cycleWitnesses;
  final Map<String, VariableDependencyPathWitness> reachabilityWitnesses;
  final Set<String> sourceVariables;
  final Set<String> sinkVariables;
  final bool productivityAvailable;

  Set<String> get unreachableVariables =>
      variables.toSet().difference(reachableVariables);

  Set<String> get nonproductiveVariables => productivityAvailable
      ? variables.toSet().difference(productiveVariables)
      : const <String>{};

  VariableDependencyEdge? edgeById(String id) {
    for (final edge in edges) {
      if (edge.id == id) return edge;
    }
    return null;
  }

  bool sourceMatches(String grammarId, int revision) =>
      sourceGrammarId == grammarId && sourceRevision == revision;

  List<StructuredMessage> accessibleSummaryMessages() {
    final messages = <StructuredMessage>[
      StructuredMessage(
        namespace: 'grammar.dependency-graph',
        code: 'summary-counts',
        category: StructuredMessageCategory.analysis,
        severity: StructuredMessageSeverity.information,
        arguments: {
          'variable-count': StructuredMessageArgument.count(
            variables.length,
            role: 'variable-count',
          ),
          'edge-count': StructuredMessageArgument.count(
            edges.length,
            role: 'edge-count',
          ),
        },
      ),
      StructuredMessage(
        namespace: 'grammar.dependency-graph',
        code: cycleWitnesses.isEmpty
            ? 'no-recursion-cycle'
            : 'recursion-cycle-count',
        category: StructuredMessageCategory.analysis,
        severity: StructuredMessageSeverity.information,
        arguments: cycleWitnesses.isEmpty
            ? const {}
            : {
                'cycle-count': StructuredMessageArgument.count(
                  cycleWitnesses.length,
                  role: 'cycle-count',
                ),
              },
      ),
    ];
    final unreachable = unreachableVariables.toList()..sort();
    for (final variable in unreachable) {
      messages.add(_variableSummaryMessage('unreachable-variable', variable));
    }
    if (productivityAvailable) {
      final nonproductive = nonproductiveVariables.toList()..sort();
      for (final variable in nonproductive) {
        messages.add(
          _variableSummaryMessage('nonproductive-variable', variable),
        );
      }
    }
    return List.unmodifiable(messages);
  }

  static StructuredMessage _variableSummaryMessage(
    String code,
    String variable,
  ) => StructuredMessage(
    namespace: 'grammar.dependency-graph',
    code: code,
    category: StructuredMessageCategory.analysis,
    severity: StructuredMessageSeverity.information,
    arguments: {
      'variable': StructuredMessageArgument.symbol(
        variable,
        role: 'grammar-variable',
      ),
    },
  );
}

abstract final class VariableDependencyGraphAnalyzer {
  static VariableDependencyGraphReport analyzeContextFree(
    Grammar grammar, {
    required int sourceRevision,
    VariableDependencyMode mode = VariableDependencyMode.directOccurrence,
  }) {
    final variables = grammar.nonterminals.toList()..sort();
    final productions = grammar.productions.toList()..sort(_compareProductions);
    final nullable = _nullableVariables(grammar, productions);
    final rawEdges = <_EdgeKey, List<VariableDependencyContribution>>{};

    for (final production in productions) {
      if (production.leftSide.length != 1 ||
          !grammar.nonterminals.contains(production.leftSide.single)) {
        continue;
      }
      final from = production.leftSide.single;
      switch (mode) {
        case VariableDependencyMode.directOccurrence:
          for (var index = 0; index < production.rightSide.length; index++) {
            final symbol = production.rightSide[index];
            if (grammar.nonterminals.contains(symbol)) {
              _addContribution(
                rawEdges,
                from: from,
                to: symbol,
                production: production,
                leftPosition: 0,
                rightPosition: index,
              );
            }
          }
        case VariableDependencyMode.leftCorner:
          if (production.rightSide.isNotEmpty &&
              grammar.nonterminals.contains(production.rightSide.first)) {
            _addContribution(
              rawEdges,
              from: from,
              to: production.rightSide.first,
              production: production,
              leftPosition: 0,
              rightPosition: 0,
            );
          }
        case VariableDependencyMode.nullableAwareLeftCorner:
          for (var index = 0; index < production.rightSide.length; index++) {
            final symbol = production.rightSide[index];
            if (!grammar.nonterminals.contains(symbol)) break;
            _addContribution(
              rawEdges,
              from: from,
              to: symbol,
              production: production,
              leftPosition: 0,
              rightPosition: index,
            );
            if (!nullable.contains(symbol)) break;
          }
      }
    }

    return _buildReport(
      sourceGrammarId: grammar.id,
      sourceRevision: sourceRevision,
      sourceKind: VariableDependencySourceKind.contextFree,
      mode: mode,
      variables: variables,
      rawEdges: rawEdges,
      startSymbol: grammar.startSymbol,
      productiveVariables: grammar.productiveNonterminals,
      canonicalReachableVariables:
          mode == VariableDependencyMode.directOccurrence
          ? grammar.reachableNonterminals
          : null,
      productivityAvailable: true,
    );
  }

  /// Uses the documented structural interpretation X → Y for each
  /// nonterminal X on the LHS and nonterminal Y on the RHS.
  static VariableDependencyGraphReport analyzeUnrestricted(
    UnrestrictedGrammar grammar, {
    VariableDependencyMode mode = VariableDependencyMode.directOccurrence,
  }) {
    if (mode != VariableDependencyMode.directOccurrence) {
      throw ArgumentError.value(
        mode,
        'mode',
        'Left-corner modes are defined only for context-free grammars.',
      );
    }
    final variables =
        grammar.nonterminals.map((symbol) => symbol.value).toList()..sort();
    final rawEdges = <_EdgeKey, List<VariableDependencyContribution>>{};
    for (final production in grammar.productions) {
      for (
        var leftIndex = 0;
        leftIndex < production.left.symbols.length;
        leftIndex++
      ) {
        final left = production.left.symbols[leftIndex];
        if (left is! NonterminalGrammarSymbol) continue;
        for (
          var rightIndex = 0;
          rightIndex < production.right.symbols.length;
          rightIndex++
        ) {
          final right = production.right.symbols[rightIndex];
          if (right is! NonterminalGrammarSymbol) continue;
          final key = _EdgeKey(left.value, right.value);
          rawEdges
              .putIfAbsent(key, () => [])
              .add(
                VariableDependencyContribution(
                  productionId: production.id,
                  productionOrder: production.order,
                  leftPosition: leftIndex,
                  rightPosition: rightIndex,
                ),
              );
        }
      }
    }
    return _buildReport(
      sourceGrammarId: grammar.id,
      sourceRevision: grammar.revision,
      sourceKind: VariableDependencySourceKind.unrestricted,
      mode: mode,
      variables: variables,
      rawEdges: rawEdges,
      startSymbol: grammar.startSymbol.value,
      productiveVariables: const <String>{},
      productivityAvailable: false,
    );
  }

  static VariableDependencyGraphReport _buildReport({
    required String sourceGrammarId,
    required int sourceRevision,
    required VariableDependencySourceKind sourceKind,
    required VariableDependencyMode mode,
    required List<String> variables,
    required Map<_EdgeKey, List<VariableDependencyContribution>> rawEdges,
    required String startSymbol,
    required Set<String> productiveVariables,
    Set<String>? canonicalReachableVariables,
    required bool productivityAvailable,
  }) {
    final keys = rawEdges.keys.toList()..sort();
    final edges = <VariableDependencyEdge>[];
    for (var index = 0; index < keys.length; index++) {
      final key = keys[index];
      final contributions = rawEdges[key]!..sort(_compareContributions);
      edges.add(
        VariableDependencyEdge(
          id: 'vdg-e$index',
          from: key.from,
          to: key.to,
          contributions: contributions,
        ),
      );
    }
    final adjacency = {for (final variable in variables) variable: <String>[]};
    final incoming = {for (final variable in variables) variable: 0};
    for (final edge in edges) {
      adjacency[edge.from]!.add(edge.to);
      incoming[edge.to] = incoming[edge.to]! + 1;
    }
    for (final targets in adjacency.values) {
      targets.sort();
    }
    final edgeByKey = {
      for (final edge in edges) _EdgeKey(edge.from, edge.to): edge,
    };
    final pathWitnesses = _reachabilityWitnesses(
      startSymbol,
      variables,
      adjacency,
      edgeByKey,
    );
    final reachable = canonicalReachableVariables ?? pathWitnesses.keys.toSet();
    final components = _stronglyConnectedComponents(variables, adjacency);
    final componentOrder = _topologicalComponents(components, edges);
    final witnesses = <VariableDependencyCycleWitness>[];
    for (final component in components) {
      final hasCycle =
          component.length > 1 ||
          adjacency[component.single]!.contains(component.single);
      if (!hasCycle) continue;
      final cycle = _cycleForComponent(component, adjacency);
      final cycleEdges = [
        for (var index = 0; index < cycle.length - 1; index++)
          edgeByKey[_EdgeKey(cycle[index], cycle[index + 1])]!,
      ];
      witnesses.add(
        VariableDependencyCycleWitness(
          variables: cycle,
          edgeIds: cycleEdges.map((edge) => edge.id),
          productionIds: _productionIds(cycleEdges),
        ),
      );
    }
    witnesses.sort(
      (left, right) => left.variables
          .join('\u0000')
          .compareTo(right.variables.join('\u0000')),
    );
    return VariableDependencyGraphReport(
      sourceGrammarId: sourceGrammarId,
      sourceRevision: sourceRevision,
      sourceKind: sourceKind,
      mode: mode,
      variables: variables,
      edges: edges,
      reachableVariables: reachable,
      productiveVariables: productiveVariables,
      stronglyConnectedComponents: components,
      componentTopologicalOrder: componentOrder,
      cycleWitnesses: witnesses,
      reachabilityWitnesses: pathWitnesses,
      sourceVariables: variables.where((variable) => incoming[variable] == 0),
      sinkVariables: variables.where(
        (variable) => adjacency[variable]!.isEmpty,
      ),
      productivityAvailable: productivityAvailable,
    );
  }

  static void _addContribution(
    Map<_EdgeKey, List<VariableDependencyContribution>> rawEdges, {
    required String from,
    required String to,
    required Production production,
    required int leftPosition,
    required int rightPosition,
  }) {
    rawEdges
        .putIfAbsent(_EdgeKey(from, to), () => [])
        .add(
          VariableDependencyContribution(
            productionId: production.id,
            productionOrder: production.order,
            leftPosition: leftPosition,
            rightPosition: rightPosition,
          ),
        );
  }

  static Set<String> _nullableVariables(
    Grammar grammar,
    List<Production> productions,
  ) {
    final nullable = <String>{};
    var changed = true;
    while (changed) {
      changed = false;
      for (final production in productions) {
        if (production.leftSide.length != 1 ||
            !grammar.nonterminals.contains(production.leftSide.single)) {
          continue;
        }
        final right = production.isLambda
            ? const <String>[]
            : production.rightSide;
        if (right.every(nullable.contains) &&
            nullable.add(production.leftSide.single)) {
          changed = true;
        }
      }
    }
    return nullable;
  }

  static Map<String, VariableDependencyPathWitness> _reachabilityWitnesses(
    String start,
    List<String> variables,
    Map<String, List<String>> adjacency,
    Map<_EdgeKey, VariableDependencyEdge> edgeByKey,
  ) {
    if (!adjacency.containsKey(start)) return const {};
    final parent = <String, String?>{start: null};
    final parentEdge = <String, VariableDependencyEdge>{};
    final pending = <String>[start];
    while (pending.isNotEmpty) {
      final current = pending.removeAt(0);
      for (final next in adjacency[current]!) {
        if (parent.containsKey(next)) continue;
        parent[next] = current;
        parentEdge[next] = edgeByKey[_EdgeKey(current, next)]!;
        pending.add(next);
      }
    }
    final result = <String, VariableDependencyPathWitness>{};
    for (final target in variables.where(parent.containsKey)) {
      final path = <String>[];
      final edges = <VariableDependencyEdge>[];
      String? current = target;
      while (current != null) {
        path.add(current);
        final edge = parentEdge[current];
        if (edge != null) edges.add(edge);
        current = parent[current];
      }
      result[target] = VariableDependencyPathWitness(
        variables: path.reversed,
        edgeIds: edges.reversed.map((edge) => edge.id),
        productionIds: _productionIds(edges.reversed),
      );
    }
    return result;
  }

  static List<String> _productionIds(Iterable<VariableDependencyEdge> edges) {
    final result = <String>[];
    final seen = <String>{};
    for (final edge in edges) {
      for (final contribution in edge.contributions) {
        if (seen.add(contribution.productionId)) {
          result.add(contribution.productionId);
        }
      }
    }
    return result;
  }

  static List<List<String>> _stronglyConnectedComponents(
    List<String> variables,
    Map<String, List<String>> adjacency,
  ) {
    var nextIndex = 0;
    final indices = <String, int>{};
    final lowLinks = <String, int>{};
    final stack = <String>[];
    final onStack = <String>{};
    final components = <List<String>>[];

    void visit(String variable) {
      indices[variable] = nextIndex;
      lowLinks[variable] = nextIndex;
      nextIndex++;
      stack.add(variable);
      onStack.add(variable);
      for (final next in adjacency[variable]!) {
        if (!indices.containsKey(next)) {
          visit(next);
          lowLinks[variable] = _minimum(lowLinks[variable]!, lowLinks[next]!);
        } else if (onStack.contains(next)) {
          lowLinks[variable] = _minimum(lowLinks[variable]!, indices[next]!);
        }
      }
      if (lowLinks[variable] != indices[variable]) return;
      final component = <String>[];
      while (stack.isNotEmpty) {
        final member = stack.removeLast();
        onStack.remove(member);
        component.add(member);
        if (member == variable) break;
      }
      component.sort();
      components.add(component);
    }

    for (final variable in variables) {
      if (!indices.containsKey(variable)) visit(variable);
    }
    components.sort((a, b) => a.first.compareTo(b.first));
    return components;
  }

  static List<List<String>> _topologicalComponents(
    List<List<String>> components,
    List<VariableDependencyEdge> edges,
  ) {
    final componentByVariable = <String, int>{};
    for (var index = 0; index < components.length; index++) {
      for (final variable in components[index]) {
        componentByVariable[variable] = index;
      }
    }
    final outgoing = {for (var i = 0; i < components.length; i++) i: <int>{}};
    final incoming = {for (var i = 0; i < components.length; i++) i: 0};
    for (final edge in edges) {
      final from = componentByVariable[edge.from]!;
      final to = componentByVariable[edge.to]!;
      if (from != to && outgoing[from]!.add(to)) {
        incoming[to] = incoming[to]! + 1;
      }
    }
    final ready =
        incoming.entries
            .where((entry) => entry.value == 0)
            .map((entry) => entry.key)
            .toList()
          ..sort((a, b) => components[a].first.compareTo(components[b].first));
    final order = <List<String>>[];
    while (ready.isNotEmpty) {
      final current = ready.removeAt(0);
      order.add(components[current]);
      final targets = outgoing[current]!.toList()
        ..sort((a, b) => components[a].first.compareTo(components[b].first));
      for (final target in targets) {
        incoming[target] = incoming[target]! - 1;
        if (incoming[target] == 0) {
          ready.add(target);
          ready.sort(
            (a, b) => components[a].first.compareTo(components[b].first),
          );
        }
      }
    }
    return order;
  }

  static List<String> _cycleForComponent(
    List<String> component,
    Map<String, List<String>> adjacency,
  ) {
    final allowed = component.toSet();
    final start = component.first;
    final path = <String>[start];
    final visiting = <String>{start};
    bool find(String current) {
      for (final next in adjacency[current]!.where(allowed.contains)) {
        if (next == start) {
          path.add(start);
          return true;
        }
        if (!visiting.add(next)) continue;
        path.add(next);
        if (find(next)) return true;
        path.removeLast();
        visiting.remove(next);
      }
      return false;
    }

    if (find(start)) return path;
    throw StateError('A strongly connected component did not yield a cycle.');
  }

  static int _compareProductions(Production left, Production right) {
    final order = left.order.compareTo(right.order);
    return order != 0 ? order : left.id.compareTo(right.id);
  }

  static int _compareContributions(
    VariableDependencyContribution left,
    VariableDependencyContribution right,
  ) {
    final order = left.productionOrder.compareTo(right.productionOrder);
    if (order != 0) return order;
    final id = left.productionId.compareTo(right.productionId);
    if (id != 0) return id;
    final lhs = left.leftPosition.compareTo(right.leftPosition);
    return lhs != 0 ? lhs : left.rightPosition.compareTo(right.rightPosition);
  }

  static int _minimum(int left, int right) => left < right ? left : right;
}

class _EdgeKey implements Comparable<_EdgeKey> {
  const _EdgeKey(this.from, this.to);

  final String from;
  final String to;

  @override
  int compareTo(_EdgeKey other) {
    final byFrom = from.compareTo(other.from);
    return byFrom != 0 ? byFrom : to.compareTo(other.to);
  }

  @override
  bool operator ==(Object other) =>
      other is _EdgeKey && other.from == from && other.to == to;

  @override
  int get hashCode => Object.hash(from, to);
}
