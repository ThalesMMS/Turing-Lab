part of '../grammar_analyzer.dart';

const _internalEpsilon = _InternalEpsilon();

final class _InternalEpsilon {
  const _InternalEpsilon();
}

/// Immutable, deterministic index shared by grammar analyses.
class GrammarAnalysisContext {
  factory GrammarAnalysisContext(Grammar grammar) {
    final terminals = Set<String>.unmodifiable(
      grammar.terminals.toList()..sort(),
    );
    final nonTerminals = Set<String>.unmodifiable(
      grammar.nonterminals.toList()..sort(),
    );
    final productions = List<Production>.unmodifiable(
      grammar.productions.map(_copyProduction).toList()
        ..sort(compareProductions),
    );
    final canonicalGrammar = Grammar(
      id: grammar.id,
      name: grammar.name,
      terminals: terminals,
      nonterminals: nonTerminals,
      startSymbol: grammar.startSymbol,
      productions: Set<Production>.unmodifiable(productions),
      type: grammar.type,
      created: grammar.created,
      modified: grammar.modified,
    );
    return GrammarAnalysisContext._(
      canonicalGrammar,
      terminals,
      nonTerminals,
      productions,
    );
  }

  GrammarAnalysisContext._(
    this._canonicalGrammar,
    this.terminals,
    this.nonTerminals,
    this.productions,
  ) {
    final groupedRights = <String, List<List<String>>>{};
    final groupedProductions = <String, List<Production>>{};
    for (final production in productions) {
      if (production.leftSide.isEmpty) continue;
      final left = production.leftSide.first;
      groupedRights.putIfAbsent(left, () => <List<String>>[]).add(
            List<String>.unmodifiable(normalizedRight(production)),
          );
      groupedProductions
          .putIfAbsent(left, () => <Production>[])
          .add(production);
    }
    productionsByNonTerminal = Map<String, List<List<String>>>.unmodifiable(
      groupedRights.map(
        (key, value) => MapEntry(
          key,
          List<List<String>>.unmodifiable(value),
        ),
      ),
    );
    productionObjectsByNonTerminal = Map<String, List<Production>>.unmodifiable(
      groupedProductions.map(
        (key, value) => MapEntry(
          key,
          List<Production>.unmodifiable(value),
        ),
      ),
    );
  }

  final Grammar _canonicalGrammar;
  final Set<String> terminals;
  final Set<String> nonTerminals;
  final List<Production> productions;
  late final Map<String, List<List<String>>> productionsByNonTerminal;
  late final Map<String, List<Production>> productionObjectsByNonTerminal;

  String get startSymbol => _canonicalGrammar.startSymbol;

  /// Returns a detached immutable copy suitable for transformation output.
  Grammar grammarSnapshot() => _copyGrammar(_canonicalGrammar);

  static Production _copyProduction(Production production) => Production(
        id: production.id,
        leftSide: List<String>.unmodifiable(production.leftSide),
        rightSide: List<String>.unmodifiable(production.rightSide),
        isLambda: production.isLambda,
        order: production.order,
      );

  bool isDeclaredSymbol(String symbol) =>
      terminals.contains(symbol) || nonTerminals.contains(symbol);

  bool isEpsilonToken(String symbol) =>
      !isDeclaredSymbol(symbol) && isEpsilonSymbol(symbol);

  List<String> normalizedRight(Production production) {
    if (production.isLambda ||
        production.rightSide.isEmpty ||
        (production.rightSide.length == 1 &&
            isEpsilonToken(production.rightSide.single))) {
      return const <String>[];
    }
    return List<String>.from(production.rightSide);
  }

  static Grammar _copyGrammar(Grammar grammar) {
    final productions = grammar.productions.map(_copyProduction).toList()
      ..sort(compareProductions);
    return Grammar(
      id: grammar.id,
      name: grammar.name,
      terminals: Set<String>.unmodifiable(grammar.terminals),
      nonterminals: Set<String>.unmodifiable(grammar.nonterminals),
      startSymbol: grammar.startSymbol,
      productions: Set<Production>.unmodifiable(productions),
      type: grammar.type,
      created: grammar.created,
      modified: grammar.modified,
    );
  }

  List<String> orderedNonTerminals() {
    final earliestProductionOrder = <String, int>{};
    for (final production in productions) {
      if (production.leftSide.length != 1) continue;
      final left = production.leftSide.single;
      final current = earliestProductionOrder[left];
      if (current == null || production.order < current) {
        earliestProductionOrder[left] = production.order;
      }
    }

    final ordered = nonTerminals
        .where((symbol) => symbol != startSymbol)
        .toList()
      ..sort((left, right) {
        final leftOrder = earliestProductionOrder[left] ?? 0x7fffffff;
        final rightOrder = earliestProductionOrder[right] ?? 0x7fffffff;
        final orderComparison = leftOrder.compareTo(rightOrder);
        return orderComparison != 0 ? orderComparison : left.compareTo(right);
      });
    if (nonTerminals.contains(startSymbol)) ordered.insert(0, startSymbol);
    return ordered;
  }

  static int compareProductions(Production left, Production right) {
    final orderComparison = left.order.compareTo(right.order);
    if (orderComparison != 0) return orderComparison;
    final idComparison = left.id.compareTo(right.id);
    if (idComparison != 0) return idComparison;
    final leftSideComparison = left.leftSide.join('\u0000').compareTo(
          right.leftSide.join('\u0000'),
        );
    if (leftSideComparison != 0) return leftSideComparison;
    return left.rightSide.join('\u0000').compareTo(
          right.rightSide.join('\u0000'),
        );
  }

  static String formatSymbols(List<String> symbols) =>
      symbols.isEmpty ? 'ε' : symbols.join(' ');

  Set<Object> _firstOfSequence(
    List<String> sequence,
    Map<String, Set<Object>> first,
  ) {
    if (sequence.isEmpty) return {_internalEpsilon};

    final result = <Object>{};
    for (var i = 0; i < sequence.length; i++) {
      final symbol = sequence[i];
      if (isEpsilonToken(symbol)) {
        result.add(_internalEpsilon);
        break;
      }
      if (!first.containsKey(symbol)) {
        result.add(symbol);
        break;
      }
      final source = first[symbol]!;
      result.addAll(source.where((candidate) => candidate != _internalEpsilon));
      if (!source.contains(_internalEpsilon)) break;
      if (i == sequence.length - 1) result.add(_internalEpsilon);
    }
    return result;
  }
}
