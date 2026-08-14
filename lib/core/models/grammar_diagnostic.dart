//
//  grammar_diagnostic.dart
//  Turing Lab
//
//  Typed, UI-friendly diagnostics for grammar analyses.
//
//  Thales Matheus Mendonça Santos - April 2026
//

import 'grammar_diagnostic_severity.dart';

class GrammarDiagnostic {
  final String code;
  final GrammarDiagnosticSeverity severity;
  final String message;

  /// Affected symbol names (terminals or non-terminals).
  final List<String> symbols;

  /// Affected production ids.
  final List<String> productionIds;

  const GrammarDiagnostic({
    required this.code,
    required this.severity,
    required this.message,
    this.symbols = const [],
    this.productionIds = const [],
  });

  GrammarDiagnostic copyWith({
    String? code,
    GrammarDiagnosticSeverity? severity,
    String? message,
    List<String>? symbols,
    List<String>? productionIds,
  }) {
    return GrammarDiagnostic(
      code: code ?? this.code,
      severity: severity ?? this.severity,
      message: message ?? this.message,
      symbols: symbols ?? this.symbols,
      productionIds: productionIds ?? this.productionIds,
    );
  }

  @override
  String toString() {
    return 'GrammarDiagnostic(code: $code, severity: $severity, message: $message, symbols: $symbols, productionIds: $productionIds)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is GrammarDiagnostic &&
        other.code == code &&
        other.severity == severity &&
        other.message == message &&
        _listEquals(other.symbols, symbols) &&
        _listEquals(other.productionIds, productionIds);
  }

  @override
  int get hashCode {
    return Object.hash(
      code,
      severity,
      message,
      Object.hashAll(symbols),
      Object.hashAll(productionIds),
    );
  }

  static bool _listEquals(List<String> a, List<String> b) {
    if (a.length != b.length) return false;
    for (var i = 0; i < a.length; i++) {
      if (a[i] != b[i]) return false;
    }
    return true;
  }
}
