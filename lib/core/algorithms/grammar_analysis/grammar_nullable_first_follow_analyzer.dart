part of '../grammar_analyzer.dart';

class _FirstSetComputation {
  const _FirstSetComputation({
    required this.first,
    required this.notes,
    required this.derivations,
    required this.structuredDerivations,
  });

  final Map<String, Set<Object>> first;
  final List<String> notes;
  final List<String> derivations;
  final List<StructuredMessage> structuredDerivations;
}

class GrammarNullableFirstFollowAnalyzer {
  const GrammarNullableFirstFollowAnalyzer(this.context);

  final GrammarAnalysisContext context;

  Set<String> computeNullableNonTerminals() {
    final nullable = <String>{};
    var changed = true;
    while (changed) {
      changed = false;
      for (final entry in context.productionsByNonTerminal.entries) {
        if (!context.nonTerminals.contains(entry.key)) continue;
        for (final right in entry.value) {
          if (right.isEmpty ||
              right.every(
                (symbol) =>
                    context.isEpsilonToken(symbol) || nullable.contains(symbol),
              )) {
            if (nullable.add(entry.key)) changed = true;
            break;
          }
        }
      }
    }
    return Set<String>.unmodifiable(nullable);
  }

  Result<GrammarAnalysisReport<Map<String, Set<String>>>> computeFirstSets() {
    final computation = _computeFirstSets();
    if (computation.isFailure) {
      return Failure(
        computation.error!,
        structuredMessage: computation.structuredError,
      );
    }
    return ResultFactory.success(_publicFirstReport(computation.data!));
  }

  Result<_FirstSetComputation> _computeFirstSets() {
    if (context.productions.isEmpty) {
      final message = GrammarAnalysisMessages.emptyProductions();
      return Failure(message.stableCode, structuredMessage: message);
    }

    final notes = <String>[];
    final derivations = <String>[];
    final structuredDerivations = <StructuredMessage>[];
    final first = <String, Set<Object>>{};
    for (final terminal in context.terminals) {
      first[terminal] = {terminal};
    }
    for (final nonTerminal in context.nonTerminals) {
      first.putIfAbsent(nonTerminal, () => <Object>{});
    }

    bool changed;
    do {
      changed = false;
      for (final entry in context.productionsByNonTerminal.entries) {
        final left = entry.key;
        if (!context.nonTerminals.contains(left) || !first.containsKey(left)) {
          final message = GrammarAnalysisMessages.firstProductionLhsUndeclared(
            left,
          );
          return Failure(
            'Cannot compute FIRST sets: production LHS "$left" is not a declared non-terminal.',
            structuredMessage: message,
          );
        }
        for (final right in entry.value) {
          if (right.isEmpty) {
            if (first[left]!.add(_internalEpsilon)) {
              changed = true;
              derivations.add(
                'FIRST($left) gains ε due to production $left → ε',
              );
              structuredDerivations.add(
                GrammarAnalysisMessages.firstEpsilonFromEmptyProduction(left),
              );
            }
            continue;
          }

          for (var i = 0; i < right.length; i++) {
            final symbol = right[i];
            if (context.isEpsilonToken(symbol)) {
              if (first[left]!.add(_internalEpsilon)) {
                changed = true;
                derivations.add(
                  'FIRST($left) gains ε because production $left → ${GrammarAnalysisContext.formatSymbols(right)} contains ε',
                );
                structuredDerivations.add(
                  GrammarAnalysisMessages.firstEpsilonFromProduction(
                    left,
                    '$left → ${GrammarAnalysisContext.formatSymbols(right)}',
                  ),
                );
              }
              break;
            }

            if (!context.nonTerminals.contains(symbol)) {
              if (first[left]!.add(symbol)) {
                changed = true;
                derivations.add(
                  'FIRST($left) gains terminal $symbol from production $left → ${GrammarAnalysisContext.formatSymbols(right)}',
                );
                structuredDerivations.add(
                  GrammarAnalysisMessages.firstTerminalFromProduction(
                    left: left,
                    symbol: symbol,
                    production:
                        '$left → ${GrammarAnalysisContext.formatSymbols(right)}',
                  ),
                );
              }
              break;
            }

            final source = first[symbol]!;
            final withoutEpsilon = source
                .where((value) => value != _internalEpsilon)
                .toSet();
            final targetFirst = first[left]!;
            final previousLength = targetFirst.length;
            targetFirst.addAll(withoutEpsilon);
            if (targetFirst.length > previousLength) {
              changed = true;
              derivations.add(
                'FIRST($left) absorbs FIRST($symbol) − {ε} via production $left → ${GrammarAnalysisContext.formatSymbols(right)}',
              );
              structuredDerivations.add(
                GrammarAnalysisMessages.firstAbsorbsFirst(
                  left: left,
                  source: symbol,
                  production:
                      '$left → ${GrammarAnalysisContext.formatSymbols(right)}',
                ),
              );
            }
            if (!source.contains(_internalEpsilon)) break;
            if (i == right.length - 1 && first[left]!.add(_internalEpsilon)) {
              changed = true;
              derivations.add(
                'FIRST($left) gains ε because all symbols in $left → ${GrammarAnalysisContext.formatSymbols(right)} can derive ε',
              );
              structuredDerivations.add(
                GrammarAnalysisMessages.firstEpsilonFromNullableProduction(
                  left: left,
                  production:
                      '$left → ${GrammarAnalysisContext.formatSymbols(right)}',
                ),
              );
            }
          }
        }
      }
    } while (changed);

    notes.add(
      'Computed FIRST sets for ${context.nonTerminals.length} non-terminals.',
    );
    return ResultFactory.success(
      _FirstSetComputation(
        first: first,
        notes: notes,
        derivations: derivations,
        structuredDerivations: structuredDerivations,
      ),
    );
  }

  GrammarAnalysisReport<Map<String, Set<String>>> _publicFirstReport(
    _FirstSetComputation computation,
  ) {
    final resultMap = <String, Set<String>>{
      for (final entry in computation.first.entries)
        if (context.nonTerminals.contains(entry.key))
          entry.key: {
            for (final value in entry.value)
              value == _internalEpsilon ? 'ε' : value as String,
          },
    };
    return GrammarReportComposer.compose(
      value: resultMap,
      notes: computation.notes,
      structuredNotes: [
        GrammarAnalysisMessages.firstSetsComputed(context.nonTerminals.length),
      ],
      derivations: computation.derivations,
      structuredDerivations: computation.structuredDerivations,
    );
  }

  Result<GrammarAnalysisReport<Map<String, Set<String>>>> computeFollowSets({
    GrammarAnalysisReport<Map<String, Set<String>>>? firstReport,
  }) {
    final startSymbol = context.startSymbol;
    if (startSymbol.isEmpty || !context.nonTerminals.contains(startSymbol)) {
      final message = GrammarAnalysisMessages.followStartSymbolUndeclared(
        startSymbol,
      );
      return Failure(
        'Cannot compute FOLLOW sets: start symbol "$startSymbol" is not a declared non-terminal.',
        structuredMessage: message,
      );
    }

    final internalFirstResult = _computeFirstSets();
    if (internalFirstResult.isFailure) {
      return Failure(
        internalFirstResult.error!,
        structuredMessage: internalFirstResult.structuredError,
      );
    }
    final computation = internalFirstResult.data!;
    return _computeFollowSets(
      computation,
      firstDerivations: firstReport?.derivations ?? computation.derivations,
      firstStructuredDerivations: firstReport?.structuredDerivations,
    );
  }

  Result<GrammarAnalysisReport<Map<String, Set<String>>>> _computeFollowSets(
    _FirstSetComputation computation, {
    required List<String> firstDerivations,
    List<StructuredMessage>? firstStructuredDerivations,
  }) {
    final startSymbol = context.startSymbol;
    final first = computation.first;
    final follow = {
      for (final nonTerminal in context.nonTerminals) nonTerminal: <String>{},
    };
    final notes = <String>[];
    final derivations = List<String>.from(firstDerivations);
    final structuredDerivations = List<StructuredMessage>.from(
      firstStructuredDerivations ?? computation.structuredDerivations,
    );
    final startFollow = follow[startSymbol];
    if (startFollow == null) {
      final message = GrammarAnalysisMessages.followStartSymbolMissingEntry(
        startSymbol,
      );
      return Failure(
        'Cannot compute FOLLOW sets: start symbol "$startSymbol" has no FOLLOW entry.',
        structuredMessage: message,
      );
    }
    startFollow.add('\$');
    derivations.add('FOLLOW($startSymbol) includes \$ (start symbol).');
    structuredDerivations.add(
      GrammarAnalysisMessages.followStartIncludesEndMarker(startSymbol),
    );

    bool changed;
    do {
      changed = false;
      for (final entry in context.productionsByNonTerminal.entries) {
        final left = entry.key;
        final leftFollow = follow[left];
        if (!context.nonTerminals.contains(left) || leftFollow == null) {
          final message = GrammarAnalysisMessages.followProductionLhsUndeclared(
            left,
          );
          return Failure(
            'Cannot compute FOLLOW sets: production LHS "$left" is not a declared non-terminal.',
            structuredMessage: message,
          );
        }
        for (final right in entry.value) {
          for (var i = 0; i < right.length; i++) {
            final symbol = right[i];
            if (!context.nonTerminals.contains(symbol)) continue;
            final suffix = right.sublist(i + 1);
            final firstOfSuffix = context._firstOfSequence(suffix, first);
            final withoutEpsilon = firstOfSuffix
                .where((value) => value != _internalEpsilon)
                .cast<String>()
                .toSet();
            final targetFollow = follow[symbol]!;
            final previousLength = targetFollow.length;
            targetFollow.addAll(withoutEpsilon);
            if (targetFollow.length > previousLength) {
              changed = true;
              derivations.add(
                "FOLLOW($symbol) gains ${withoutEpsilon.join(', ')} from FIRST of suffix in $left → ${GrammarAnalysisContext.formatSymbols(right)}",
              );
              structuredDerivations.add(
                GrammarAnalysisMessages.followGainsFromSuffix(
                  symbol: symbol,
                  gained: withoutEpsilon.join(', '),
                  production:
                      '$left → ${GrammarAnalysisContext.formatSymbols(right)}',
                ),
              );
            }
            if (suffix.isEmpty || firstOfSuffix.contains(_internalEpsilon)) {
              final previousFollowLength = targetFollow.length;
              targetFollow.addAll(leftFollow);
              if (targetFollow.length > previousFollowLength) {
                changed = true;
                derivations.add(
                  'FOLLOW($symbol) absorbs FOLLOW($left) because suffix can derive ε in $left → ${GrammarAnalysisContext.formatSymbols(right)}',
                );
                structuredDerivations.add(
                  GrammarAnalysisMessages.followAbsorbsFollow(
                    symbol: symbol,
                    source: left,
                    production:
                        '$left → ${GrammarAnalysisContext.formatSymbols(right)}',
                  ),
                );
              }
            }
          }
        }
      }
    } while (changed);

    notes.add(
      'Computed FOLLOW sets for ${context.nonTerminals.length} non-terminals.',
    );
    return ResultFactory.success(
      GrammarReportComposer.compose(
        value: follow,
        notes: notes,
        structuredNotes: [
          GrammarAnalysisMessages.followSetsComputed(
            context.nonTerminals.length,
          ),
        ],
        derivations: derivations,
        structuredDerivations: structuredDerivations,
      ),
    );
  }
}
