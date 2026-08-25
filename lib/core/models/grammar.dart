//
//  grammar.dart
//  Turing Lab
//
//  Data structure that models formal grammars with symbol sets, productions,
//  and temporal metadata, offering immutable copies and serialization
//  support. The grammar type is preserved and validated for parsing-algorithm
//  consistency, while rules are checked against declared symbols.
//
//  Thales Matheus Mendonça Santos - October 2025
//
import 'production.dart';

/// Grammar model for formal language theory
class Grammar {
  /// Unique identifier for the grammar
  final String id;

  /// User-defined name for the grammar
  final String name;

  /// Set of terminal symbols
  final Set<String> terminals;

  /// Set of non-terminal symbols
  final Set<String> nonterminals;

  /// Non-terminals (alias for nonterminals)
  Set<String> get nonTerminals => nonterminals;

  /// Grammar start symbol
  final String startSymbol;

  /// Set of production rules
  final Set<Production> productions;

  /// Type of the grammar
  final GrammarType type;

  /// Creation timestamp
  final DateTime created;

  /// Last modification timestamp
  final DateTime modified;

  const Grammar({
    required this.id,
    required this.name,
    required this.terminals,
    required this.nonterminals,
    required this.startSymbol,
    required this.productions,
    required this.type,
    required this.created,
    required this.modified,
  });

  /// Creates a copy of this grammar with updated properties
  Grammar copyWith({
    String? id,
    String? name,
    Set<String>? terminals,
    Set<String>? nonterminals,
    String? startSymbol,
    Set<Production>? productions,
    GrammarType? type,
    DateTime? created,
    DateTime? modified,
  }) {
    return Grammar(
      id: id ?? this.id,
      name: name ?? this.name,
      terminals: terminals ?? this.terminals,
      nonterminals: nonterminals ?? this.nonterminals,
      startSymbol: startSymbol ?? this.startSymbol,
      productions: productions ?? this.productions,
      type: type ?? this.type,
      created: created ?? this.created,
      modified: modified ?? this.modified,
    );
  }

  /// Converts the grammar to a JSON representation
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'terminals': terminals.toList(),
      'nonterminals': nonterminals.toList(),
      'startSymbol': startSymbol,
      'productions': productions.map((p) => p.toJson()).toList(),
      'type': type.name,
      'created': created.toIso8601String(),
      'modified': modified.toIso8601String(),
    };
  }

  /// Creates a grammar from a JSON representation
  factory Grammar.fromJson(Map<String, dynamic> json) {
    return Grammar(
      id: json['id'] as String,
      name: json['name'] as String,
      terminals: Set<String>.from(json['terminals'] as List),
      nonterminals: Set<String>.from(json['nonterminals'] as List),
      startSymbol: json['startSymbol'] as String,
      productions: (json['productions'] as List)
          .map((p) => Production.fromJson(p as Map<String, dynamic>))
          .toSet(),
      type: GrammarType.values.firstWhere(
        (e) => e.name == json['type'],
        orElse: () => GrammarType.contextFree,
      ),
      created: DateTime.parse(json['created'] as String),
      modified: DateTime.parse(json['modified'] as String),
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Grammar &&
        other.id == id &&
        other.name == name &&
        other.type == type;
  }

  @override
  int get hashCode {
    return Object.hash(id, name, type);
  }

  @override
  String toString() {
    return 'Grammar(id: $id, name: $name, type: $type, productions: ${productions.length})';
  }

  /// Validates the grammar properties
  ///
  /// Note: this legacy validation returns plain strings and is kept for
  /// backward compatibility. Prefer GrammarAnalyzer.validateMalformedProductions
  /// for typed, non-throwing diagnostics suitable for UI display.
  List<String> validate() {
    final errors = <String>[];

    if (id.isEmpty) {
      errors.add('Grammar ID cannot be empty');
    }

    if (name.isEmpty) {
      errors.add('Grammar name cannot be empty');
    }

    if (startSymbol.isEmpty) {
      errors.add('Grammar must have a start symbol');
    }

    if (!nonterminals.contains(startSymbol)) {
      errors.add('Start symbol must be a non-terminal');
    }

    if (productions.isEmpty) {
      errors.add('Grammar must have at least one production');
    }

    for (final production in productions) {
      final productionErrors = production.validate();
      errors.addAll(
        productionErrors.map((e) => 'Production ${production.id}: $e'),
      );

      // Validate production symbols
      for (final symbol in production.leftSide) {
        if (!nonterminals.contains(symbol)) {
          errors.add(
            'Production ${production.id} references undefined non-terminal: $symbol',
          );
        }
      }

      for (final symbol in production.rightSide) {
        // Skip epsilon/lambda meta-symbols
        if (symbol == 'ε' ||
            symbol == 'λ' ||
            symbol.isEmpty ||
            symbol == 'epsilon') {
          continue;
        }
        if (!terminals.contains(symbol) && !nonterminals.contains(symbol)) {
          errors.add(
            'Production ${production.id} references undefined symbol: $symbol',
          );
        }
      }
    }

    return errors;
  }

  /// Checks if the grammar is valid
  bool get isValid => validate().isEmpty;

  /// Gets the number of productions
  int get productionCount => productions.length;

  /// Gets the number of terminals
  int get terminalCount => terminals.length;

  /// Gets the number of non-terminals
  int get nonterminalCount => nonterminals.length;

  /// Gets all symbols (terminals and non-terminals)
  Set<String> get allSymbols => terminals.union(nonterminals);

  /// Gets all productions with a specific left-hand side
  Set<Production> getProductionsFor(String nonterminal) {
    return productions.where((p) => p.leftSide.contains(nonterminal)).toSet();
  }

  /// Gets all productions that produce a specific symbol
  Set<Production> getProductionsProducing(String symbol) {
    return productions.where((p) => p.rightSide.contains(symbol)).toSet();
  }

  /// Gets all productions that start with a specific symbol
  Set<Production> getProductionsStartingWith(String symbol) {
    return productions
        .where((p) => p.rightSide.isNotEmpty && p.rightSide.first == symbol)
        .toSet();
  }

  /// Gets all productions that end with a specific symbol
  Set<Production> getProductionsEndingWith(String symbol) {
    return productions
        .where((p) => p.rightSide.isNotEmpty && p.rightSide.last == symbol)
        .toSet();
  }

  /// Gets all lambda productions
  Set<Production> get lambdaProductions {
    return productions.where((p) => p.isLambda).toSet();
  }

  /// Gets all non-lambda productions
  Set<Production> get nonLambdaProductions {
    return productions.where((p) => !p.isLambda).toSet();
  }

  /// Gets all productions with a specific length on the right-hand side
  Set<Production> getProductionsWithRightSideLength(int length) {
    return productions.where((p) => p.rightSide.length == length).toSet();
  }

  /// Gets all productions with a specific length on the left-hand side
  Set<Production> getProductionsWithLeftSideLength(int length) {
    return productions.where((p) => p.leftSide.length == length).toSet();
  }

  /// Checks if the grammar has lambda productions
  bool get hasLambdaProductions => lambdaProductions.isNotEmpty;

  /// Checks if the grammar has unit productions
  bool get hasUnitProductions {
    return productions.any(
      (p) =>
          p.rightSide.length == 1 && nonterminals.contains(p.rightSide.first),
    );
  }

  /// Checks if the grammar has left recursion
  bool get hasLeftRecursion {
    for (final production in productions) {
      if (production.rightSide.isNotEmpty &&
          production.leftSide.contains(production.rightSide.first)) {
        return true;
      }
    }
    return false;
  }

  /// Checks if the grammar has right recursion
  bool get hasRightRecursion {
    for (final production in productions) {
      if (production.rightSide.isNotEmpty &&
          production.leftSide.contains(production.rightSide.last)) {
        return true;
      }
    }
    return false;
  }

  /// Gets all non-terminals that can derive lambda
  Set<String> get nullableNonterminals {
    final nullable = <String>{};
    bool changed = true;

    while (changed) {
      changed = false;
      for (final production in productions) {
        if (production.isLambda) {
          if (nullable.add(production.leftSide.first)) {
            changed = true;
          }
        } else if (production.rightSide.every(
          (symbol) => nullable.contains(symbol),
        )) {
          if (nullable.add(production.leftSide.first)) {
            changed = true;
          }
        }
      }
    }

    return nullable;
  }

  /// Gets all non-terminals that can derive terminal strings
  Set<String> get productiveNonterminals {
    final productive = <String>{};
    bool changed = true;

    while (changed) {
      changed = false;
      for (final production in productions) {
        if (production.rightSide.every(
          (symbol) => terminals.contains(symbol) || productive.contains(symbol),
        )) {
          if (productive.add(production.leftSide.first)) {
            changed = true;
          }
        }
      }
    }

    return productive;
  }

  /// Gets all non-terminals that are reachable from the start symbol
  Set<String> get reachableNonterminals {
    final reachable = <String>{startSymbol};
    bool changed = true;

    while (changed) {
      changed = false;
      for (final production in productions) {
        if (production.leftSide.any((symbol) => reachable.contains(symbol))) {
          for (final symbol in production.rightSide) {
            if (nonterminals.contains(symbol) && reachable.add(symbol)) {
              changed = true;
            }
          }
        }
      }
    }

    return reachable;
  }

  /// Gets all non-terminals that are useful (productive and reachable)
  Set<String> get usefulNonterminals {
    return productiveNonterminals.intersection(reachableNonterminals);
  }

  /// Gets all non-terminals that are useless
  Set<String> get uselessNonterminals {
    return nonterminals.difference(usefulNonterminals);
  }

  /// Checks if the grammar is reduced (no useless non-terminals)
  bool get isReduced => uselessNonterminals.isEmpty;

  /// Creates an empty grammar
  factory Grammar.empty({
    required String id,
    required String name,
    required GrammarType type,
  }) {
    final now = DateTime.now();
    return Grammar(
      id: id,
      name: name,
      terminals: {},
      nonterminals: {},
      startSymbol: '',
      productions: {},
      type: type,
      created: now,
      modified: now,
    );
  }

  /// Creates a simple regular grammar
  factory Grammar.simpleRegular({required String id, required String name}) {
    final now = DateTime.now();
    const production1 = Production(
      id: 'p1',
      leftSide: ['S'],
      rightSide: ['a', 'A'],
      isLambda: false,
      order: 1,
    );
    const production2 = Production(
      id: 'p2',
      leftSide: ['A'],
      rightSide: ['b'],
      isLambda: false,
      order: 2,
    );

    return Grammar(
      id: id,
      name: name,
      terminals: {'a', 'b'},
      nonterminals: {'S', 'A'},
      startSymbol: 'S',
      productions: {production1, production2},
      type: GrammarType.regular,
      created: now,
      modified: now,
    );
  }

  /// Creates a simple context-free grammar
  factory Grammar.simpleContextFree({
    required String id,
    required String name,
  }) {
    final now = DateTime.now();
    const production1 = Production(
      id: 'p1',
      leftSide: ['S'],
      rightSide: ['a', 'S', 'b'],
      isLambda: false,
      order: 1,
    );
    const production2 = Production(
      id: 'p2',
      leftSide: ['S'],
      rightSide: [],
      isLambda: true,
      order: 2,
    );

    return Grammar(
      id: id,
      name: name,
      terminals: {'a', 'b'},
      nonterminals: {'S'},
      startSymbol: 'S',
      productions: {production1, production2},
      type: GrammarType.contextFree,
      created: now,
      modified: now,
    );
  }
}

/// Types of grammars
enum GrammarType {
  /// Regular grammar
  regular,

  /// Context-free grammar
  contextFree,

  /// Context-sensitive grammar
  contextSensitive,

  /// Unrestricted grammar
  unrestricted,
}

/// Extension methods for GrammarType
extension GrammarTypeExtension on GrammarType {
  /// Returns a human-readable description of the grammar type
  String get description {
    switch (this) {
      case GrammarType.regular:
        return 'Regular Grammar';
      case GrammarType.contextFree:
        return 'Context-Free Grammar';
      case GrammarType.contextSensitive:
        return 'Context-Sensitive Grammar';
      case GrammarType.unrestricted:
        return 'Unrestricted Grammar';
    }
  }

  /// Returns the short name of the grammar type
  String get shortName {
    switch (this) {
      case GrammarType.regular:
        return 'Regular';
      case GrammarType.contextFree:
        return 'CFG';
      case GrammarType.contextSensitive:
        return 'CSG';
      case GrammarType.unrestricted:
        return 'Unrestricted';
    }
  }

  /// Returns the Chomsky hierarchy level
  int get chomskyLevel {
    switch (this) {
      case GrammarType.regular:
        return 3;
      case GrammarType.contextFree:
        return 2;
      case GrammarType.contextSensitive:
        return 1;
      case GrammarType.unrestricted:
        return 0;
    }
  }

  /// Returns whether this grammar type supports left recursion
  bool get supportsLeftRecursion {
    return this == GrammarType.contextFree ||
        this == GrammarType.contextSensitive ||
        this == GrammarType.unrestricted;
  }

  /// Returns whether this grammar type supports lambda productions
  bool get supportsLambdaProductions {
    return this == GrammarType.contextFree ||
        this == GrammarType.contextSensitive ||
        this == GrammarType.unrestricted;
  }
}
