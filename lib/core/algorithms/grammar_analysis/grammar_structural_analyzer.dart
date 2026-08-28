part of '../grammar_analyzer.dart';

class GrammarStructuralAnalyzer {
  const GrammarStructuralAnalyzer(this.context);

  final GrammarAnalysisContext context;

  Result<GrammarDiagnosticsReport> validateMalformedProductions() {
    final diagnostics = <GrammarDiagnostic>[];
    final startSymbol = context.startSymbol;

    if (startSymbol.isEmpty) {
      diagnostics.add(
        _structuralDiagnostic(
          code: 'grammar.start_symbol_missing',
          message: GrammarStructuralMessages.startSymbolMissing(),
        ),
      );
    } else if (!context.nonTerminals.contains(startSymbol)) {
      diagnostics.add(
        _structuralDiagnostic(
          code: 'grammar.start_symbol_not_nonterminal',
          message: GrammarStructuralMessages.startSymbolNotNonterminal(
            startSymbol,
          ),
          symbols: [startSymbol],
        ),
      );
    }

    if (context.productions.isEmpty) {
      diagnostics.add(
        _structuralDiagnostic(
          code: 'grammar.no_productions',
          message: GrammarStructuralMessages.noProductions(),
        ),
      );
      return ResultFactory.success(
        GrammarDiagnosticsReport(diagnostics: diagnostics),
      );
    }

    for (final production in context.productions) {
      if (production.leftSide.isEmpty) {
        diagnostics.add(
          _structuralDiagnostic(
            code: 'grammar.production_left_side_empty',
            message: GrammarStructuralMessages.productionLeftSideEmpty(
              production.id,
            ),
            productionIds: [production.id],
          ),
        );
        continue;
      }

      if (production.leftSide.length != 1) {
        diagnostics.add(
          _structuralDiagnostic(
            code: 'grammar.production_left_side_not_single_nonterminal',
            message:
                GrammarStructuralMessages.productionLeftSideNotSingleNonterminal(
                  production.id,
                  production.leftSide.join(' '),
                ),
            symbols: production.leftSide,
            productionIds: [production.id],
          ),
        );
      } else {
        final left = production.leftSide.first;
        if (left.isEmpty) {
          diagnostics.add(
            _structuralDiagnostic(
              code: 'grammar.production_left_side_empty_symbol',
              message: GrammarStructuralMessages.productionLeftSideEmptySymbol(
                production.id,
              ),
              productionIds: [production.id],
            ),
          );
        } else if (!context.nonTerminals.contains(left)) {
          diagnostics.add(
            _structuralDiagnostic(
              code: 'grammar.production_left_side_not_nonterminal',
              message:
                  GrammarStructuralMessages.productionLeftSideNotNonterminal(
                    production.id,
                    left,
                  ),
              symbols: [left],
              productionIds: [production.id],
            ),
          );
        }
      }

      for (final symbol in production.rightSide) {
        if (context.terminals.contains(symbol) ||
            context.nonTerminals.contains(symbol) ||
            context.isEpsilonToken(symbol)) {
          continue;
        }
        diagnostics.add(
          _structuralDiagnostic(
            code: 'grammar.unknown_symbol',
            message:
                GrammarStructuralMessages.productionReferencesUnknownSymbol(
                  production.id,
                  symbol,
                ),
            symbols: [symbol],
            productionIds: [production.id],
          ),
        );
      }

      if (production.isLambda && production.rightSide.isNotEmpty) {
        diagnostics.add(
          _structuralDiagnostic(
            code: 'grammar.lambda_production_rhs_not_empty',
            message: GrammarStructuralMessages.lambdaProductionRhsNotEmpty(
              production.id,
            ),
            productionIds: [production.id],
          ),
        );
      }

      if (!production.isLambda && production.rightSide.isEmpty) {
        diagnostics.add(
          _structuralDiagnostic(
            code: 'grammar.production_rhs_empty',
            message: GrammarStructuralMessages.productionRhsEmpty(
              production.id,
            ),
            productionIds: [production.id],
          ),
        );
      }
    }

    return ResultFactory.success(
      GrammarDiagnosticsReport(diagnostics: diagnostics),
    );
  }

  Result<GrammarDiagnosticsReport> detectUnreachableNonTerminals() {
    final diagnostics = <GrammarDiagnostic>[];
    final startSymbol = context.startSymbol;

    if (startSymbol.isEmpty) {
      diagnostics.add(
        _structuralDiagnostic(
          code: 'grammar.start_symbol_missing',
          message:
              GrammarStructuralMessages.startSymbolMissingForReachability(),
        ),
      );
      return ResultFactory.success(
        GrammarDiagnosticsReport(diagnostics: diagnostics),
      );
    }

    if (!context.nonTerminals.contains(startSymbol)) {
      diagnostics.add(
        _structuralDiagnostic(
          code: 'grammar.start_symbol_not_nonterminal',
          message:
              GrammarStructuralMessages.startSymbolNotNonterminalForReachability(
                startSymbol,
              ),
          symbols: [startSymbol],
        ),
      );
    }

    final visited = <String>{};
    final queue = <String>[startSymbol];
    final warnedUnknownSymbols = <String>{};

    while (queue.isNotEmpty) {
      final current = queue.removeLast();
      if (!visited.add(current)) continue;
      final alternatives = context.productionsByNonTerminal[current];
      if (alternatives == null) continue;

      for (final rhs in alternatives) {
        for (final symbol in rhs) {
          if (context.nonTerminals.contains(symbol)) {
            if (!visited.contains(symbol)) queue.add(symbol);
            continue;
          }
          if (context.terminals.contains(symbol)) continue;
          if (context.isEpsilonToken(symbol)) continue;
          if (warnedUnknownSymbols.add(symbol)) {
            diagnostics.add(
              _structuralDiagnostic(
                code: 'grammar.unknown_symbol',
                message: GrammarStructuralMessages.unknownSymbolForReachability(
                  symbol,
                ),
                symbols: [symbol],
              ),
            );
          }
        }
      }
    }

    final unreachable =
        context.nonTerminals
            .where((symbol) => !visited.contains(symbol))
            .toList()
          ..sort();
    if (unreachable.isNotEmpty) {
      diagnostics.add(
        _structuralDiagnostic(
          code: 'grammar.unreachable_nonterminal',
          message: GrammarStructuralMessages.unreachableNonterminals(
            unreachable.length,
            unreachable.join(', '),
          ),
          symbols: unreachable,
        ),
      );
    }
    return ResultFactory.success(
      GrammarDiagnosticsReport(diagnostics: diagnostics),
    );
  }

  Result<GrammarDiagnosticsReport> detectUnproductiveNonTerminals() {
    final diagnostics = <GrammarDiagnostic>[];
    if (context.productions.isEmpty) {
      diagnostics.add(
        _structuralDiagnostic(
          code: 'grammar.no_productions',
          message: GrammarStructuralMessages.noProductionsForProductivity(),
        ),
      );
      return ResultFactory.success(
        GrammarDiagnosticsReport(diagnostics: diagnostics),
      );
    }

    final productive = <String>{};
    final warnedUnknownSymbols = <String>{};
    var changed = true;
    while (changed) {
      changed = false;
      for (final entry in context.productionsByNonTerminal.entries) {
        final nonTerminal = entry.key;
        if (productive.contains(nonTerminal)) continue;
        for (final rhs in entry.value) {
          var rhsIsProductive = true;
          for (final symbol in rhs) {
            if (context.terminals.contains(symbol) ||
                context.isEpsilonToken(symbol)) {
              continue;
            }
            if (context.nonTerminals.contains(symbol)) {
              if (!productive.contains(symbol)) rhsIsProductive = false;
              continue;
            }
            if (warnedUnknownSymbols.add(symbol)) {
              diagnostics.add(
                _structuralDiagnostic(
                  code: 'grammar.unknown_symbol',
                  message:
                      GrammarStructuralMessages.unknownSymbolForProductivity(
                        symbol,
                      ),
                  symbols: [symbol],
                ),
              );
            }
          }
          if (rhsIsProductive) {
            productive.add(nonTerminal);
            changed = true;
            break;
          }
        }
      }
    }

    final unproductive =
        context.nonTerminals
            .where((symbol) => !productive.contains(symbol))
            .toList()
          ..sort();
    if (unproductive.isNotEmpty) {
      diagnostics.add(
        _structuralDiagnostic(
          code: 'grammar.unproductive_nonterminal',
          message: GrammarStructuralMessages.unproductiveNonterminals(
            unproductive.length,
            unproductive.join(', '),
          ),
          symbols: unproductive,
        ),
      );
      final productionIds = context.productions
          .where(
            (production) =>
                production.leftSide.isNotEmpty &&
                unproductive.contains(production.leftSide.first),
          )
          .map((production) => production.id)
          .toList();
      if (productionIds.isNotEmpty) {
        diagnostics.add(
          _structuralDiagnostic(
            code: 'grammar.unproductive_production',
            message: GrammarStructuralMessages.unproductiveProductions(
              unproductive.join(', '),
            ),
            symbols: unproductive,
            productionIds: productionIds,
          ),
        );
      }
    }
    return ResultFactory.success(
      GrammarDiagnosticsReport(diagnostics: diagnostics),
    );
  }
}

GrammarDiagnostic _structuralDiagnostic({
  required String code,
  required StructuredMessage message,
  List<String> symbols = const [],
  List<String> productionIds = const [],
}) => GrammarDiagnostic(
  code: code,
  severity: switch (message.severity) {
    StructuredMessageSeverity.information => GrammarDiagnosticSeverity.info,
    StructuredMessageSeverity.warning => GrammarDiagnosticSeverity.warning,
    StructuredMessageSeverity.error => GrammarDiagnosticSeverity.error,
    StructuredMessageSeverity.unknown => GrammarDiagnosticSeverity.info,
  },
  message: message.stableCode,
  structuredMessage: message,
  symbols: symbols,
  productionIds: productionIds,
);
