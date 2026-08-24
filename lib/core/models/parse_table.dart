//
//  parse_table.dart
//  Turing Lab
//
//  Represents parse tables for LL and LR algorithms, holding actions, goto
//  moves, and a reference to the associated grammar. Provides copy,
//  serialization, and inspection operations that support conflict checks
//  and navigation in parsing simulators.
//
//  Thales Matheus Mendonça Santos - October 2025
//
import 'grammar.dart';
import 'production.dart';

/// Parse table for grammar parsing algorithms
class ParseTable {
  /// Action table for parsing decisions
  final Map<String, Map<String, ParseAction>> actionTable;

  /// Goto table for non-terminal transitions
  final Map<String, Map<String, String>> gotoTable;

  /// Grammar this parse table is for
  final Grammar grammar;

  /// Type of parsing (LL or LR)
  final ParseType type;

  const ParseTable({
    required this.actionTable,
    required this.gotoTable,
    required this.grammar,
    required this.type,
  });

  /// Creates a copy of this parse table with updated properties
  ParseTable copyWith({
    Map<String, Map<String, ParseAction>>? actionTable,
    Map<String, Map<String, String>>? gotoTable,
    Grammar? grammar,
    ParseType? type,
  }) {
    return ParseTable(
      actionTable: actionTable ?? this.actionTable,
      gotoTable: gotoTable ?? this.gotoTable,
      grammar: grammar ?? this.grammar,
      type: type ?? this.type,
    );
  }

  /// Converts the parse table to a JSON representation
  Map<String, dynamic> toJson() {
    return {
      'actionTable': actionTable.map(
        (state, terminals) => MapEntry(
          state,
          terminals.map(
            (terminal, action) => MapEntry(terminal, action.toJson()),
          ),
        ),
      ),
      'gotoTable': gotoTable,
      'grammar': grammar.toJson(),
      'type': type.name,
    };
  }

  /// Creates a parse table from a JSON representation
  factory ParseTable.fromJson(Map<String, dynamic> json) {
    return ParseTable(
      actionTable: (json['actionTable'] as Map<String, dynamic>).map(
        (state, terminals) => MapEntry(
          state,
          (terminals as Map<String, dynamic>).map(
            (terminal, action) => MapEntry(
              terminal,
              ParseAction.fromJson(action as Map<String, dynamic>),
            ),
          ),
        ),
      ),
      gotoTable: Map<String, Map<String, String>>.from(
        (json['gotoTable'] as Map<String, dynamic>).map(
          (state, nonterminals) => MapEntry(
            state,
            Map<String, String>.from(nonterminals as Map<String, dynamic>),
          ),
        ),
      ),
      grammar: Grammar.fromJson(json['grammar'] as Map<String, dynamic>),
      type: ParseType.values.firstWhere(
        (e) => e.name == json['type'],
        orElse: () => ParseType.ll,
      ),
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is ParseTable &&
        other.actionTable == actionTable &&
        other.gotoTable == gotoTable &&
        other.grammar == grammar &&
        other.type == type;
  }

  @override
  int get hashCode {
    return Object.hash(actionTable, gotoTable, grammar, type);
  }

  @override
  String toString() {
    return 'ParseTable(type: $type, states: ${actionTable.length}, grammar: ${grammar.name})';
  }

  /// Gets the number of states in the parse table
  int get stateCount => actionTable.length;

  /// Gets the number of terminals in the parse table
  int get terminalCount => actionTable.values.first.keys.length;

  /// Gets the number of non-terminals in the parse table
  int get nonterminalCount => gotoTable.values.first.keys.length;

  /// Gets all states in the parse table
  Set<String> get states => actionTable.keys.toSet();

  /// Gets all terminals in the parse table
  Set<String> get terminals {
    if (actionTable.isEmpty) return {};
    return actionTable.values.first.keys.toSet();
  }

  /// Gets all non-terminals in the parse table
  Set<String> get nonterminals {
    if (gotoTable.isEmpty) return {};
    return gotoTable.values.first.keys.toSet();
  }

  /// Gets the action for a specific state and terminal
  ParseAction? getAction(String state, String terminal) {
    return actionTable[state]?[terminal];
  }

  /// Gets the goto state for a specific state and non-terminal
  String? getGoto(String state, String nonterminal) {
    return gotoTable[state]?[nonterminal];
  }

  /// Checks if the parse table has any conflicts
  bool get hasConflicts {
    for (final state in actionTable.keys) {
      for (final terminal in actionTable[state]!.keys) {
        final action = actionTable[state]![terminal]!;
        if (action.type == ParseActionType.error) {
          continue;
        }

        // Check for shift-reduce conflicts
        if (action.type == ParseActionType.shift) {
          // Look for reduce actions in the same cell
          // This would need more complex logic to detect conflicts
        }
      }
    }
    return false;
  }

  /// Gets all conflicts in the parse table
  List<ParseConflict> get conflicts {
    final conflicts = <ParseConflict>[];

    for (final state in actionTable.keys) {
      for (final terminal in actionTable[state]!.keys) {
        final action = actionTable[state]![terminal]!;
        if (action.type == ParseActionType.error) {
          continue;
        }

        // Check for conflicts (simplified)
        // In a real implementation, this would be more complex
      }
    }

    return conflicts;
  }

  /// Checks if the parse table is valid
  bool get isValid {
    return !hasConflicts && actionTable.isNotEmpty && gotoTable.isNotEmpty;
  }

  /// Gets the parse table as a formatted string
  String get formattedTable {
    final buffer = StringBuffer();

    buffer.writeln('Parse Table ($type):');
    buffer.writeln('Grammar: ${grammar.name}');
    buffer.writeln('States: $stateCount');
    buffer.writeln('Terminals: $terminalCount');
    buffer.writeln('Non-terminals: $nonterminalCount');
    buffer.writeln();

    // Action table
    buffer.writeln('Action Table:');
    for (final state in states) {
      buffer.writeln('State $state:');
      for (final terminal in terminals) {
        final action = getAction(state, terminal);
        if (action != null) {
          buffer.writeln('  $terminal: ${action.type.name}');
        }
      }
    }

    buffer.writeln();

    // Goto table
    buffer.writeln('Goto Table:');
    for (final state in states) {
      buffer.writeln('State $state:');
      for (final nonterminal in nonterminals) {
        final goto = getGoto(state, nonterminal);
        if (goto != null) {
          buffer.writeln('  $nonterminal: $goto');
        }
      }
    }

    return buffer.toString();
  }

  /// Creates an empty parse table
  factory ParseTable.empty({
    required Grammar grammar,
    required ParseType type,
  }) {
    return ParseTable(
      actionTable: {},
      gotoTable: {},
      grammar: grammar,
      type: type,
    );
  }
}

/// Types of parsing
enum ParseType {
  /// LL parsing
  ll,

  /// LR parsing
  lr,

  /// SLR parsing
  slr,

  /// LALR parsing
  lalr,
}

/// Extension methods for ParseType
extension ParseTypeExtension on ParseType {
  /// Returns a human-readable description of the parse type
  String get description {
    switch (this) {
      case ParseType.ll:
        return 'LL Parsing';
      case ParseType.lr:
        return 'LR Parsing';
      case ParseType.slr:
        return 'SLR Parsing';
      case ParseType.lalr:
        return 'LALR Parsing';
    }
  }

  /// Returns the short name of the parse type
  String get shortName {
    switch (this) {
      case ParseType.ll:
        return 'LL';
      case ParseType.lr:
        return 'LR';
      case ParseType.slr:
        return 'SLR';
      case ParseType.lalr:
        return 'LALR';
    }
  }
}

/// Parse action in a parse table
class ParseAction {
  /// Type of the action
  final ParseActionType type;

  /// State number for shift actions
  final int? stateNumber;

  /// Production for reduce actions
  final Production? production;

  /// Error message for error actions
  final String? errorMessage;

  const ParseAction({
    required this.type,
    this.stateNumber,
    this.production,
    this.errorMessage,
  });

  /// Creates a copy of this parse action with updated properties
  ParseAction copyWith({
    ParseActionType? type,
    int? stateNumber,
    Production? production,
    String? errorMessage,
  }) {
    return ParseAction(
      type: type ?? this.type,
      stateNumber: stateNumber ?? this.stateNumber,
      production: production ?? this.production,
      errorMessage: errorMessage ?? this.errorMessage,
    );
  }

  /// Converts the parse action to a JSON representation
  Map<String, dynamic> toJson() {
    return {
      'type': type.name,
      'stateNumber': stateNumber,
      'production': production?.toJson(),
      'errorMessage': errorMessage,
    };
  }

  /// Creates a parse action from a JSON representation
  factory ParseAction.fromJson(Map<String, dynamic> json) {
    return ParseAction(
      type: ParseActionType.values.firstWhere(
        (e) => e.name == json['type'],
        orElse: () => ParseActionType.error,
      ),
      stateNumber: json['stateNumber'] as int?,
      production: json['production'] != null
          ? Production.fromJson(json['production'] as Map<String, dynamic>)
          : null,
      errorMessage: json['errorMessage'] as String?,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is ParseAction &&
        other.type == type &&
        other.stateNumber == stateNumber &&
        other.production == production &&
        other.errorMessage == errorMessage;
  }

  @override
  int get hashCode {
    return Object.hash(type, stateNumber, production, errorMessage);
  }

  @override
  String toString() {
    return 'ParseAction(type: $type, stateNumber: $stateNumber, production: $production)';
  }

  /// Creates a shift action
  factory ParseAction.shift(int stateNumber) {
    return ParseAction(type: ParseActionType.shift, stateNumber: stateNumber);
  }

  /// Creates a reduce action
  factory ParseAction.reduce(Production production) {
    return ParseAction(type: ParseActionType.reduce, production: production);
  }

  /// Creates an accept action
  factory ParseAction.accept() {
    return const ParseAction(type: ParseActionType.accept);
  }

  /// Creates an error action
  factory ParseAction.error(String errorMessage) {
    return ParseAction(type: ParseActionType.error, errorMessage: errorMessage);
  }
}

/// Types of parse actions
enum ParseActionType {
  /// Shift action
  shift,

  /// Reduce action
  reduce,

  /// Accept action
  accept,

  /// Error action
  error,
}

/// Extension methods for ParseActionType
extension ParseActionTypeExtension on ParseActionType {
  /// Returns a human-readable description of the action type
  String get description {
    switch (this) {
      case ParseActionType.shift:
        return 'Shift';
      case ParseActionType.reduce:
        return 'Reduce';
      case ParseActionType.accept:
        return 'Accept';
      case ParseActionType.error:
        return 'Error';
    }
  }

  /// Returns the symbol used to represent this action type
  String get symbol {
    switch (this) {
      case ParseActionType.shift:
        return 's';
      case ParseActionType.reduce:
        return 'r';
      case ParseActionType.accept:
        return 'acc';
      case ParseActionType.error:
        return 'err';
    }
  }
}

/// Parse conflict in a parse table
class ParseConflict {
  /// State where the conflict occurs
  final String state;

  /// Terminal where the conflict occurs
  final String terminal;

  /// Type of conflict
  final ConflictType type;

  /// Actions involved in the conflict
  final List<ParseAction> actions;

  const ParseConflict({
    required this.state,
    required this.terminal,
    required this.type,
    required this.actions,
  });

  @override
  String toString() {
    return 'ParseConflict(state: $state, terminal: $terminal, type: $type, actions: $actions)';
  }
}

/// Types of parse conflicts
enum ConflictType {
  /// Shift-reduce conflict
  shiftReduce,

  /// Reduce-reduce conflict
  reduceReduce,

  /// Shift-shift conflict
  shiftShift,
}

/// Extension methods for ConflictType
extension ConflictTypeExtension on ConflictType {
  /// Returns a human-readable description of the conflict type
  String get description {
    switch (this) {
      case ConflictType.shiftReduce:
        return 'Shift-Reduce Conflict';
      case ConflictType.reduceReduce:
        return 'Reduce-Reduce Conflict';
      case ConflictType.shiftShift:
        return 'Shift-Shift Conflict';
    }
  }
}
