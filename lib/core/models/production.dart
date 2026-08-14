//
//  production.dart
//  Turing Lab
//
//  Modela regras de produção de gramáticas armazenando lados esquerdo e direito, flags de lambda e ordem de exibição. Inclui utilitários de cópia, serialização e comparação que suportam editores e algoritmos que manipulam gramáticas no aplicativo.
//
//  Thales Matheus Mendonça Santos - October 2025
//

import 'package:collection/collection.dart';

const _stringListEquality = ListEquality<String>();

/// Production rule for grammars
class Production {
  /// Unique identifier for the production within the grammar
  final String id;

  /// Left-hand side symbols (support multiple symbols for unrestricted grammars)
  final List<String> leftSide;

  /// Right-hand side symbols
  final List<String> rightSide;

  /// Whether this is a lambda production
  final bool isLambda;

  /// Display order in UI
  final int order;

  const Production({
    required this.id,
    required this.leftSide,
    required this.rightSide,
    this.isLambda = false,
    this.order = 0,
  });

  /// Creates a copy of this production with updated properties
  Production copyWith({
    String? id,
    List<String>? leftSide,
    List<String>? rightSide,
    bool? isLambda,
    int? order,
  }) {
    return Production(
      id: id ?? this.id,
      leftSide: leftSide ?? this.leftSide,
      rightSide: rightSide ?? this.rightSide,
      isLambda: isLambda ?? this.isLambda,
      order: order ?? this.order,
    );
  }

  /// Converts the production to a JSON representation
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'leftSide': leftSide,
      'rightSide': rightSide,
      'isLambda': isLambda,
      'order': order,
    };
  }

  /// Creates a production from a JSON representation
  factory Production.fromJson(Map<String, dynamic> json) {
    return Production(
      id: json['id'] as String,
      leftSide: List<String>.from(json['leftSide'] as List),
      rightSide: List<String>.from(json['rightSide'] as List),
      isLambda: json['isLambda'] as bool? ?? false,
      order: json['order'] as int? ?? 0,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Production &&
        other.id == id &&
        _stringListEquality.equals(other.leftSide, leftSide) &&
        _stringListEquality.equals(other.rightSide, rightSide) &&
        other.isLambda == isLambda &&
        other.order == order;
  }

  @override
  int get hashCode {
    return Object.hash(
      id,
      _stringListEquality.hash(leftSide),
      _stringListEquality.hash(rightSide),
      isLambda,
      order,
    );
  }

  @override
  String toString() {
    return 'Production(id: $id, leftSide: $leftSide, rightSide: $rightSide, isLambda: $isLambda)';
  }

  /// Validates the production properties
  List<String> validate() {
    final errors = <String>[];

    if (id.isEmpty) {
      errors.add('Production ID cannot be empty');
    }

    if (leftSide.isEmpty) {
      errors.add('Production left side cannot be empty');
    }

    if (isLambda && rightSide.isNotEmpty) {
      errors.add('Lambda production must have empty right side');
    }

    if (!isLambda && rightSide.isEmpty) {
      errors.add('Non-lambda production must have non-empty right side');
    }

    for (final symbol in leftSide) {
      if (symbol.isEmpty) {
        errors.add('Production left side cannot contain empty symbols');
      }
    }

    for (final symbol in rightSide) {
      if (symbol.isEmpty) {
        errors.add('Production right side cannot contain empty symbols');
      }
    }

    return errors;
  }

  /// Checks if the production is valid
  bool get isValid => validate().isEmpty;

  /// Gets the length of the left-hand side
  int get leftSideLength => leftSide.length;

  /// Gets the length of the right-hand side
  int get rightSideLength => rightSide.length;

  /// Gets the total length of the production
  int get totalLength => leftSideLength + rightSideLength;

  /// Gets the first symbol of the left-hand side
  String? get leftSideFirst => leftSide.isNotEmpty ? leftSide.first : null;

  /// Gets the last symbol of the left-hand side
  String? get leftSideLast => leftSide.isNotEmpty ? leftSide.last : null;

  /// Gets the first symbol of the right-hand side
  String? get rightSideFirst => rightSide.isNotEmpty ? rightSide.first : null;

  /// Gets the last symbol of the right-hand side
  String? get rightSideLast => rightSide.isNotEmpty ? rightSide.last : null;

  /// Checks if the production is a unit production
  bool get isUnitProduction {
    return rightSide.length == 1 && !isLambda;
  }

  /// Checks if the production is a terminal production
  bool get isTerminalProduction {
    return rightSide.length == 1 && !isLambda;
  }

  /// Checks if the production is a binary production
  bool get isBinaryProduction {
    return rightSide.length == 2 && !isLambda;
  }

  /// Checks if the production is a unary production
  bool get isUnaryProduction {
    return rightSide.length == 1 && !isLambda;
  }

  /// Checks if the production is a nullary production
  bool get isNullaryProduction {
    return rightSide.isEmpty || isLambda;
  }

  /// Checks if the production has left recursion
  bool get hasLeftRecursion {
    return rightSide.isNotEmpty && leftSide.contains(rightSide.first);
  }

  /// Checks if the production has right recursion
  bool get hasRightRecursion {
    return rightSide.isNotEmpty && leftSide.contains(rightSide.last);
  }

  /// Checks if the production has direct left recursion
  bool get hasDirectLeftRecursion {
    return rightSide.isNotEmpty && leftSide.first == rightSide.first;
  }

  /// Checks if the production has direct right recursion
  bool get hasDirectRightRecursion {
    return rightSide.isNotEmpty && leftSide.first == rightSide.last;
  }

  /// Gets the string representation of the production
  String get stringRepresentation {
    if (isLambda) {
      return '${leftSide.join(' ')} → ε';
    }
    return '${leftSide.join(' ')} → ${rightSide.join(' ')}';
  }

  /// Gets the compact string representation of the production
  String get compactRepresentation {
    if (isLambda) {
      return '${leftSide.join()} → ε';
    }
    return '${leftSide.join()} → ${rightSide.join()}';
  }

  /// Checks if the production can derive a specific string
  bool canDerive(List<String> string) {
    if (isLambda) {
      return string.isEmpty;
    }
    return rightSide == string;
  }

  /// Checks if the production can derive a specific symbol
  bool canDeriveSymbol(String symbol) {
    if (isLambda) {
      return false;
    }
    return rightSide.length == 1 && rightSide.first == symbol;
  }

  /// Checks if the production can derive a string starting with a specific symbol
  bool canDeriveStartingWith(String symbol) {
    if (isLambda) {
      return false;
    }
    return rightSide.isNotEmpty && rightSide.first == symbol;
  }

  /// Checks if the production can derive a string ending with a specific symbol
  bool canDeriveEndingWith(String symbol) {
    if (isLambda) {
      return false;
    }
    return rightSide.isNotEmpty && rightSide.last == symbol;
  }

  /// Checks if the production can derive a string containing a specific symbol
  bool canDeriveContaining(String symbol) {
    if (isLambda) {
      return false;
    }
    return rightSide.contains(symbol);
  }

  /// Gets all symbols in the production
  Set<String> get allSymbols {
    return leftSide.toSet().union(rightSide.toSet());
  }

  /// Gets all symbols on the left-hand side
  Set<String> get leftSideSymbols => leftSide.toSet();

  /// Gets all symbols on the right-hand side
  Set<String> get rightSideSymbols => rightSide.toSet();

  /// Creates a lambda production
  factory Production.lambda({
    required String id,
    required String leftSide,
    int order = 0,
  }) {
    return Production(
      id: id,
      leftSide: [leftSide],
      rightSide: [],
      isLambda: true,
      order: order,
    );
  }

  /// Creates a terminal production
  factory Production.terminal({
    required String id,
    required String leftSide,
    required String terminal,
    int order = 0,
  }) {
    return Production(
      id: id,
      leftSide: [leftSide],
      rightSide: [terminal],
      isLambda: false,
      order: order,
    );
  }

  /// Creates a binary production
  factory Production.binary({
    required String id,
    required String leftSide,
    required String rightFirst,
    required String rightSecond,
    int order = 0,
  }) {
    return Production(
      id: id,
      leftSide: [leftSide],
      rightSide: [rightFirst, rightSecond],
      isLambda: false,
      order: order,
    );
  }

  /// Creates a unit production
  factory Production.unit({
    required String id,
    required String leftSide,
    required String rightSide,
    int order = 0,
  }) {
    return Production(
      id: id,
      leftSide: [leftSide],
      rightSide: [rightSide],
      isLambda: false,
      order: order,
    );
  }

  /// Creates a production from a string representation
  factory Production.fromString({
    required String id,
    required String representation,
    int order = 0,
  }) {
    final parts = representation.split('→');
    if (parts.length != 2) {
      throw ArgumentError('Invalid production format: $representation');
    }

    final leftSide = parts[0]
        .trim()
        .split(RegExp(r'\s+'))
        .where((s) => s.isNotEmpty)
        .toList();
    final rightSideStr = parts[1].trim();

    if (rightSideStr == 'ε' || rightSideStr.isEmpty) {
      return Production.lambda(id: id, leftSide: leftSide.first, order: order);
    }

    final rightSide =
        rightSideStr.split(RegExp(r'\s+')).where((s) => s.isNotEmpty).toList();

    return Production(
      id: id,
      leftSide: leftSide,
      rightSide: rightSide,
      isLambda: false,
      order: order,
    );
  }
}
