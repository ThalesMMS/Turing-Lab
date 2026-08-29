part of '../grammar_analyzer.dart';

class GrammarPredictiveAnalyzer {
  const GrammarPredictiveAnalyzer(this.context);

  final GrammarAnalysisContext context;

  Result<GrammarAnalysisReport<Grammar>> leftFactor() {
    final grammar = context.grammarSnapshot();
    if (context.productions.isEmpty) {
      final message = GrammarAnalysisMessages.emptyProductions();
      return Failure(message.stableCode, structuredMessage: message);
    }

    final grouped = <String, List<List<String>>>{
      for (final entry in context.productionsByNonTerminal.entries)
        entry.key: entry.value
            .map((right) => List<String>.from(right))
            .toList(),
    };
    final newProductions = <Production>[];
    final newNonTerminals = context.nonTerminals.toSet();
    final notes = <String>[];
    final structuredNotes = <StructuredMessage>[];
    final derivations = <String>[];
    final structuredDerivations = <StructuredMessage>[];
    var productionCounter = 0;
    var factoringIndex = 1;
    var changed = false;

    bool updated;
    do {
      updated = false;
      for (final nonTerminal in grouped.keys.toList()) {
        final alternatives = grouped[nonTerminal]!;
        final factoring = _findCommonPrefix(alternatives);
        if (factoring == null) continue;

        changed = true;
        updated = true;
        final prefix = factoring.prefix;
        final toFactor = factoring.alternatives;
        final newSymbol = _generateFactoredSymbol(
          nonTerminal,
          newNonTerminals,
          factoringIndex++,
        );
        newNonTerminals.add(newSymbol);
        notes.add(
          'Introduced non-terminal $newSymbol to factor prefix ${GrammarAnalysisContext.formatSymbols(prefix)} from $nonTerminal.',
        );
        structuredNotes.add(
          GrammarPredictiveMessages.factoringIntroduced(
            nonTerminal: nonTerminal,
            introduced: newSymbol,
            prefix: GrammarAnalysisContext.formatSymbols(prefix),
            productionCount: toFactor.length,
          ),
        );
        grouped[nonTerminal] = [
          ...alternatives.where(
            (alternative) => !toFactor.contains(alternative),
          ),
          [...prefix, newSymbol],
        ];
        grouped[newSymbol] = toFactor
            .map(
              (alternative) => alternative.length == prefix.length
                  ? <String>[]
                  : alternative.sublist(prefix.length),
            )
            .toList();
        derivations.add(
          '$nonTerminal → ${GrammarAnalysisContext.formatSymbols(prefix)}$newSymbol (factored ${toFactor.length} productions)',
        );
        structuredDerivations.add(
          GrammarPredictiveMessages.factoringDerivation(
            nonTerminal: nonTerminal,
            introduced: newSymbol,
            prefix: GrammarAnalysisContext.formatSymbols(prefix),
            productionCount: toFactor.length,
          ),
        );
        for (final alternative in grouped[newSymbol]!) {
          final suffix = alternative.isEmpty ? 'ε' : alternative.join(' ');
          derivations.add('$newSymbol → $suffix (remaining suffix)');
          structuredDerivations.add(
            GrammarPredictiveMessages.factoringSuffix(
              introduced: newSymbol,
              suffix: suffix,
            ),
          );
        }
        break;
      }
    } while (updated);

    if (!changed) {
      notes.add('No common prefixes requiring factoring were found.');
      structuredNotes.add(GrammarPredictiveMessages.noFactoringNeeded());
    }
    for (final entry in grouped.entries) {
      for (final alternative in entry.value) {
        newProductions.add(
          _productionFrom(
            entry.key,
            alternative,
            productionCounter++,
            grammarId: grammar.id,
          ),
        );
      }
      if (entry.value.isEmpty) {
        newProductions.add(
          Production(
            id: '${grammar.id}_fact_$productionCounter',
            leftSide: [entry.key],
            rightSide: const [],
            isLambda: true,
            order: productionCounter++,
          ),
        );
      }
    }

    final transformed = GrammarAnalysisContext(
      grammar.copyWith(
        nonterminals: newNonTerminals,
        productions: newProductions.toSet(),
        modified: DateTime.now(),
      ),
    ).grammarSnapshot();
    return ResultFactory.success(
      GrammarReportComposer.compose(
        value: transformed,
        notes: notes,
        structuredNotes: structuredNotes,
        derivations: derivations,
        structuredDerivations: structuredDerivations,
      ),
    );
  }

  Result<GrammarAnalysisReport<LL1ParseTable>> buildLL1ParseTable() {
    final setAnalyzer = GrammarNullableFirstFollowAnalyzer(context);
    final internalFirstResult = setAnalyzer._computeFirstSets();
    if (internalFirstResult.isFailure) {
      return Failure(
        internalFirstResult.error!,
        structuredMessage: internalFirstResult.structuredError,
      );
    }
    final firstComputation = internalFirstResult.data!;
    final firstReport = setAnalyzer._publicFirstReport(firstComputation);
    final followResult = setAnalyzer._computeFollowSets(
      firstComputation,
      firstDerivations: firstReport.derivations,
      firstStructuredDerivations: firstReport.structuredDerivations,
    );
    if (followResult.isFailure) {
      return Failure(
        followResult.error!,
        structuredMessage: followResult.structuredError,
      );
    }

    final first = firstComputation.first;
    final follow = followResult.data!.value;
    final entryTable = <String, Map<String, List<LL1ParseTableEntry>>>{};
    final derivations = <String>[];
    final structuredDerivations = <StructuredMessage>[];
    final conflicts = <String>[];
    final structuredConflicts = <StructuredMessage>[];
    for (final entry in context.productionObjectsByNonTerminal.entries) {
      final left = entry.key;
      if (!context.nonTerminals.contains(left) || !follow.containsKey(left)) {
        final message = GrammarPredictiveMessages.productionLhsUndeclared(left);
        return Failure(
          'Cannot build LL(1) parse table: production LHS "$left" is not a declared non-terminal.',
          structuredMessage: message,
        );
      }
      entryTable.putIfAbsent(left, () => {});
      for (final production in entry.value) {
        final right = context.normalizedRight(production);
        final firstSet = context._firstOfSequence(right, first);
        for (final terminal
            in firstSet
                .where((symbol) => symbol != _internalEpsilon)
                .cast<String>()) {
          final row = entryTable[left];
          if (row == null) {
            final message = GrammarPredictiveMessages.missingTableRow(left);
            return Failure(
              'Cannot build LL(1) parse table: missing table row for "$left".',
              structuredMessage: message,
            );
          }
          _placeProduction(
            row,
            terminal,
            production,
            right,
            LL1TablePlacement.first,
          );
          derivations.add(
            'Placed $left → ${GrammarAnalysisContext.formatSymbols(right)} in table[$left, $terminal].',
          );
          structuredDerivations.add(
            GrammarPredictiveMessages.tablePlacement(
              placement: LL1TablePlacement.first,
              nonTerminal: left,
              production:
                  '$left → ${GrammarAnalysisContext.formatSymbols(right)}',
              lookahead: terminal,
            ),
          );
        }

        if (firstSet.contains(_internalEpsilon)) {
          final followSet = follow[left];
          final row = entryTable[left];
          if (followSet == null || row == null) {
            final message = GrammarPredictiveMessages.missingFollowOrTableEntry(
              left,
            );
            return Failure(
              'Cannot build LL(1) parse table: missing FOLLOW or table entry for "$left".',
              structuredMessage: message,
            );
          }
          for (final terminal in followSet) {
            _placeProduction(
              row,
              terminal,
              production,
              right,
              LL1TablePlacement.follow,
            );
            derivations.add(
              'Placed $left → ${GrammarAnalysisContext.formatSymbols(right)} in table[$left, $terminal] using FOLLOW set.',
            );
            structuredDerivations.add(
              GrammarPredictiveMessages.tablePlacement(
                placement: LL1TablePlacement.follow,
                nonTerminal: left,
                production:
                    '$left → ${GrammarAnalysisContext.formatSymbols(right)}',
                lookahead: terminal,
              ),
            );
          }
        }
      }
    }

    final typedConflicts = <LL1ParseTableConflict>[];
    final table = <String, Map<String, List<List<String>>>>{};
    for (final rowEntry in entryTable.entries) {
      final legacyRow = <String, List<List<String>>>{};
      table[rowEntry.key] = legacyRow;
      for (final cellEntry in rowEntry.value.entries) {
        final entries = cellEntry.value;
        legacyRow[cellEntry.key] = entries
            .map((entry) => List<String>.from(entry.rightSide))
            .toList(growable: false);
        if (entries.length <= 1) continue;
        final conflict = LL1ParseTableConflict(
          nonTerminal: rowEntry.key,
          lookahead: cellEntry.key,
          kind:
              entries.any(
                (entry) => entry.placements.contains(LL1TablePlacement.follow),
              )
              ? LL1ConflictKind.firstFollow
              : LL1ConflictKind.firstFirst,
          entries: entries,
        );
        typedConflicts.add(conflict);
        conflicts.add(conflict.formalDescription);
        structuredConflicts.add(conflict.descriptionMessage);
      }
    }

    final terminals = context.terminals.union({'\$'});
    final tableNotes = <String>[
      'Constructed LL(1) parse table with ${table.length} non-terminals.',
      if (conflicts.isEmpty)
        'No conflicts detected in parse table.'
      else
        '${conflicts.length} conflict(s) detected in parse table.',
    ];
    return ResultFactory.success(
      GrammarReportComposer.compose(
        value: LL1ParseTable(
          table: table,
          terminals: terminals,
          entryTable: entryTable,
          typedConflicts: typedConflicts,
        ),
        derivations: [...followResult.data!.derivations, ...derivations],
        structuredDerivations: [
          ...followResult.data!.structuredDerivations,
          ...structuredDerivations,
        ],
        conflicts: conflicts,
        structuredConflicts: structuredConflicts,
        notes: tableNotes,
        structuredNotes: [
          GrammarPredictiveMessages.tableConstructed(table.length),
          if (conflicts.isEmpty)
            GrammarPredictiveMessages.tableNoConflicts()
          else
            GrammarPredictiveMessages.tableConflictsDetected(conflicts.length),
        ],
      ),
    );
  }

  static void _placeProduction(
    Map<String, List<LL1ParseTableEntry>> row,
    String terminal,
    Production production,
    List<String> right,
    LL1TablePlacement placement,
  ) {
    final cell = row.putIfAbsent(terminal, () => <LL1ParseTableEntry>[]);
    final existingIndex = cell.indexWhere(
      (entry) =>
          entry.productionId == production.id &&
          entry.productionOrder == production.order,
    );
    if (existingIndex == -1) {
      cell.add(
        LL1ParseTableEntry(
          productionId: production.id,
          leftSide: production.leftSide.first,
          rightSide: right,
          placements: {placement},
          productionOrder: production.order,
        ),
      );
      return;
    }
    final existing = cell[existingIndex];
    cell[existingIndex] = LL1ParseTableEntry(
      productionId: existing.productionId,
      leftSide: existing.leftSide,
      rightSide: existing.rightSide,
      placements: {...existing.placements, placement},
      productionOrder: existing.productionOrder,
    );
  }

  static Production _productionFrom(
    String left,
    List<String> right,
    int counter, {
    required String grammarId,
  }) {
    return Production(
      id: '${grammarId}_$counter',
      leftSide: [left],
      rightSide: right,
      isLambda: right.isEmpty,
      order: counter,
    );
  }

  static String _generateFactoredSymbol(
    String base,
    Set<String> existing,
    int index,
  ) {
    var candidate = '${base}_$index';
    while (existing.contains(candidate)) {
      index++;
      candidate = '${base}_$index';
    }
    return candidate;
  }

  static _FactoringResult? _findCommonPrefix(List<List<String>> alternatives) {
    if (alternatives.length < 2) return null;
    _FactoringResult? best;
    for (var i = 0; i < alternatives.length; i++) {
      final first = alternatives[i];
      for (var j = i + 1; j < alternatives.length; j++) {
        final second = alternatives[j];
        final prefix = <String>[];
        final length = first.length < second.length
            ? first.length
            : second.length;
        for (var k = 0; k < length; k++) {
          if (first[k] != second[k]) break;
          prefix.add(first[k]);
        }
        if (prefix.isEmpty) continue;
        final group = alternatives
            .where(
              (alternative) =>
                  alternative.length >= prefix.length &&
                  _listEquals(alternative.sublist(0, prefix.length), prefix),
            )
            .toList();
        if (group.length < 2) continue;
        if (best == null || prefix.length > best.prefix.length) {
          best = _FactoringResult(prefix: prefix, alternatives: group);
        }
      }
    }
    return best;
  }

  static bool _listEquals(List<String> left, List<String> right) {
    if (left.length != right.length) return false;
    for (var index = 0; index < left.length; index++) {
      if (left[index] != right[index]) return false;
    }
    return true;
  }
}

class _FactoringResult {
  const _FactoringResult({required this.prefix, required this.alternatives});

  final List<String> prefix;
  final List<List<String>> alternatives;
}
