//
//  grammar_analyzer.dart
//  Turing Lab
//
//  Oferece rotinas avançadas para analisar e transformar gramáticas, incluindo
//  remoção de recursão à esquerda, fatoração à esquerda e construção de
//  relatórios ricos com notas, derivações e conflitos. Estruturas auxiliares
//  encapsulam tabelas LL(1) e resultados tipados, permitindo futuras extensões
//  de análise.
//
//  Thales Matheus Mendonça Santos - October 2025
//
import '../models/grammar.dart';
import '../models/grammar_diagnostic.dart';
import '../models/grammar_diagnostic_severity.dart';
import '../models/grammar_diagnostics_report.dart';
import '../models/production.dart';
import '../result.dart';
import '../utils/epsilon_utils.dart';

class GrammarAnalysisReport<T> {
  final T value;
  final List<String> notes;
  final List<String> derivations;
  final List<String> conflicts;

  const GrammarAnalysisReport({
    required this.value,
    this.notes = const [],
    this.derivations = const [],
    this.conflicts = const [],
  });
}

class LL1ParseTable {
  final Map<String, Map<String, List<List<String>>>> table;
  final Set<String> terminals;

  const LL1ParseTable({required this.table, required this.terminals});

  Set<String> get nonTerminals => table.keys.toSet();
}

class GrammarAnalyzer {
  static Result<GrammarDiagnosticsReport> validateMalformedProductions(
    Grammar grammar,
  ) {
    final diagnostics = <GrammarDiagnostic>[];

    if (grammar.startSymbol.isEmpty) {
      diagnostics.add(
        const GrammarDiagnostic(
          code: 'grammar.start_symbol_missing',
          severity: GrammarDiagnosticSeverity.error,
          message: 'Grammar has no start symbol.',
        ),
      );
    } else if (!grammar.nonterminals.contains(grammar.startSymbol)) {
      diagnostics.add(
        GrammarDiagnostic(
          code: 'grammar.start_symbol_not_nonterminal',
          severity: GrammarDiagnosticSeverity.error,
          message:
              'Start symbol ${grammar.startSymbol} is not declared as a non-terminal.',
          symbols: [grammar.startSymbol],
        ),
      );
    }

    if (grammar.productions.isEmpty) {
      diagnostics.add(
        const GrammarDiagnostic(
          code: 'grammar.no_productions',
          severity: GrammarDiagnosticSeverity.warning,
          message: 'Grammar has no productions.',
        ),
      );
      return ResultFactory.success(
        GrammarDiagnosticsReport(diagnostics: diagnostics),
      );
    }

    for (final production in grammar.productions) {
      if (production.leftSide.isEmpty) {
        diagnostics.add(
          GrammarDiagnostic(
            code: 'grammar.production_left_side_empty',
            severity: GrammarDiagnosticSeverity.error,
            message: 'Production ${production.id} has an empty left-hand side.',
            productionIds: [production.id],
          ),
        );
        continue;
      }

      if (production.leftSide.length != 1) {
        diagnostics.add(
          GrammarDiagnostic(
            code: 'grammar.production_left_side_not_single_nonterminal',
            severity: GrammarDiagnosticSeverity.error,
            message:
                'Production ${production.id} left-hand side must be exactly one non-terminal for CFG tooling; got ${production.leftSide.join(' ')}.',
            symbols: production.leftSide,
            productionIds: [production.id],
          ),
        );
      } else {
        final left = production.leftSide.first;
        if (left.isEmpty) {
          diagnostics.add(
            GrammarDiagnostic(
              code: 'grammar.production_left_side_empty_symbol',
              severity: GrammarDiagnosticSeverity.error,
              message:
                  'Production ${production.id} left-hand side contains an empty symbol.',
              productionIds: [production.id],
            ),
          );
        } else if (!grammar.nonterminals.contains(left)) {
          diagnostics.add(
            GrammarDiagnostic(
              code: 'grammar.production_left_side_not_nonterminal',
              severity: GrammarDiagnosticSeverity.error,
              message:
                  'Production ${production.id} left-hand side "$left" is not declared as a non-terminal.',
              symbols: [left],
              productionIds: [production.id],
            ),
          );
        }
      }

      for (final symbol in production.rightSide) {
        if (isEpsilonSymbol(symbol)) {
          continue;
        }

        if (grammar.terminals.contains(symbol)) {
          continue;
        }

        if (grammar.nonterminals.contains(symbol)) {
          continue;
        }

        diagnostics.add(
          GrammarDiagnostic(
            code: 'grammar.unknown_symbol',
            severity: GrammarDiagnosticSeverity.warning,
            message:
                'Production ${production.id} references unknown symbol "$symbol".',
            symbols: [symbol],
            productionIds: [production.id],
          ),
        );
      }

      if (production.isLambda && production.rightSide.isNotEmpty) {
        diagnostics.add(
          GrammarDiagnostic(
            code: 'grammar.lambda_production_rhs_not_empty',
            severity: GrammarDiagnosticSeverity.error,
            message:
                'Production ${production.id} is marked as lambda but has a non-empty right-hand side.',
            productionIds: [production.id],
          ),
        );
      }

      if (!production.isLambda && production.rightSide.isEmpty) {
        diagnostics.add(
          GrammarDiagnostic(
            code: 'grammar.production_rhs_empty',
            severity: GrammarDiagnosticSeverity.error,
            message:
                'Production ${production.id} has an empty right-hand side; use ε/λ or mark it as lambda.',
            productionIds: [production.id],
          ),
        );
      }
    }

    return ResultFactory.success(
      GrammarDiagnosticsReport(diagnostics: diagnostics),
    );
  }

  static Result<GrammarDiagnosticsReport> detectUnreachableNonTerminals(
    Grammar grammar,
  ) {
    // Existing reachability diagnostics.

    final diagnostics = <GrammarDiagnostic>[];

    if (grammar.startSymbol.isEmpty) {
      diagnostics.add(
        const GrammarDiagnostic(
          code: 'grammar.start_symbol_missing',
          severity: GrammarDiagnosticSeverity.error,
          message: 'Grammar has no start symbol; unreachable analysis skipped.',
        ),
      );
      return ResultFactory.success(
        GrammarDiagnosticsReport(diagnostics: diagnostics),
      );
    }

    if (!grammar.nonterminals.contains(grammar.startSymbol)) {
      diagnostics.add(
        GrammarDiagnostic(
          code: 'grammar.start_symbol_not_nonterminal',
          severity: GrammarDiagnosticSeverity.error,
          message:
              'Start symbol ${grammar.startSymbol} is not declared as a non-terminal; unreachable analysis may be inaccurate.',
          symbols: [grammar.startSymbol],
        ),
      );
    }

    final visited = <String>{};
    final queue = <String>[];
    final warnedUnknownSymbols = <String>{};
    queue.add(grammar.startSymbol);

    final productionsByNonTerminal = _groupProductions(grammar);

    while (queue.isNotEmpty) {
      final current = queue.removeLast();
      if (!visited.add(current)) continue;

      final alternatives = productionsByNonTerminal[current];
      if (alternatives == null) {
        continue;
      }

      for (final rhs in alternatives) {
        for (final symbol in rhs) {
          if (isEpsilonSymbol(symbol)) continue;

          if (grammar.nonterminals.contains(symbol)) {
            if (!visited.contains(symbol)) {
              queue.add(symbol);
            }
            continue;
          }

          if (grammar.terminals.contains(symbol)) {
            continue;
          }

          if (warnedUnknownSymbols.add(symbol)) {
            diagnostics.add(
              GrammarDiagnostic(
                code: 'grammar.unknown_symbol',
                severity: GrammarDiagnosticSeverity.warning,
                message:
                    'Production references unknown symbol "$symbol"; treating as terminal for reachability purposes.',
                symbols: [symbol],
              ),
            );
          }
        }
      }
    }

    final unreachable =
        grammar.nonterminals.where((nt) => !visited.contains(nt));
    final unreachableList = unreachable.toList()..sort();

    if (unreachableList.isNotEmpty) {
      diagnostics.add(
        GrammarDiagnostic(
          code: 'grammar.unreachable_nonterminal',
          severity: GrammarDiagnosticSeverity.warning,
          message:
              'Found ${unreachableList.length} unreachable non-terminal(s): ${unreachableList.join(', ')}.',
          symbols: unreachableList,
        ),
      );
    }

    return ResultFactory.success(
      GrammarDiagnosticsReport(diagnostics: diagnostics),
    );
  }

  static Result<GrammarDiagnosticsReport> detectUnproductiveNonTerminals(
    Grammar grammar,
  ) {
    final diagnostics = <GrammarDiagnostic>[];

    if (grammar.productions.isEmpty) {
      diagnostics.add(
        const GrammarDiagnostic(
          code: 'grammar.no_productions',
          severity: GrammarDiagnosticSeverity.warning,
          message: 'Grammar has no productions; productivity analysis skipped.',
        ),
      );
      return ResultFactory.success(
        GrammarDiagnosticsReport(diagnostics: diagnostics),
      );
    }

    final productionsByNonTerminal = _groupProductions(grammar);

    final productive = <String>{};
    final warnedUnknownSymbols = <String>{};
    var changed = true;

    while (changed) {
      changed = false;

      for (final entry in productionsByNonTerminal.entries) {
        final nonTerminal = entry.key;
        if (productive.contains(nonTerminal)) continue;

        for (final rhs in entry.value) {
          var rhsIsProductive = true;

          for (final symbol in rhs) {
            if (isEpsilonSymbol(symbol)) {
              continue;
            }

            if (grammar.terminals.contains(symbol)) {
              continue;
            }

            if (grammar.nonterminals.contains(symbol)) {
              if (!productive.contains(symbol)) {
                rhsIsProductive = false;
              }
              continue;
            }

            // Unknown symbol: treat as terminal for productivity, but warn.
            if (warnedUnknownSymbols.add(symbol)) {
              diagnostics.add(
                GrammarDiagnostic(
                  code: 'grammar.unknown_symbol',
                  severity: GrammarDiagnosticSeverity.warning,
                  message:
                      'Production references unknown symbol "$symbol"; treating as terminal for productivity purposes.',
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

    final unproductive = grammar.nonterminals
        .where((nt) => !productive.contains(nt))
        .toList()
      ..sort();

    if (unproductive.isNotEmpty) {
      diagnostics.add(
        GrammarDiagnostic(
          code: 'grammar.unproductive_nonterminal',
          severity: GrammarDiagnosticSeverity.warning,
          message:
              'Found ${unproductive.length} unproductive non-terminal(s): ${unproductive.join(', ')}.',
          symbols: unproductive,
        ),
      );

      final productionIds = <String>[];
      for (final production in grammar.productions) {
        final left =
            production.leftSide.isNotEmpty ? production.leftSide.first : '';
        if (unproductive.contains(left)) {
          productionIds.add(production.id);
        }
      }
      if (productionIds.isNotEmpty) {
        diagnostics.add(
          GrammarDiagnostic(
            code: 'grammar.unproductive_production',
            severity: GrammarDiagnosticSeverity.info,
            message:
                'Productions for unproductive non-terminals cannot derive terminal strings.',
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

  static Result<GrammarAnalysisReport<Grammar>> removeDirectLeftRecursion(
    Grammar grammar,
  ) {
    if (grammar.productions.isEmpty) {
      return ResultFactory.failure('The grammar has no productions.');
    }

    final productionsByNonTerminal = _groupProductions(grammar);
    final newProductions = <Production>[];
    final newNonTerminals = grammar.nonterminals.toSet();
    final notes = <String>[];
    final derivations = <String>[];
    var productionCounter = 0;

    bool changed = false;

    for (final entry in productionsByNonTerminal.entries) {
      final nonTerminal = entry.key;
      final alternatives = entry.value;
      final alpha = <List<String>>[];
      final beta = <List<String>>[];

      for (final alt in alternatives) {
        if (alt.isNotEmpty && alt.first == nonTerminal) {
          alpha.add(alt.sublist(1));
        } else {
          beta.add(alt);
        }
      }

      if (alpha.isEmpty) {
        for (final alt in alternatives) {
          newProductions.add(
            _productionFrom(
              nonTerminal,
              alt,
              productionCounter++,
              grammarId: grammar.id,
            ),
          );
        }
        continue;
      }

      changed = true;
      final prime = _generatePrimeSymbol(nonTerminal, newNonTerminals);
      newNonTerminals.add(prime);
      notes.add(
        'Introduced non-terminal $prime to remove left recursion from $nonTerminal.',
      );

      if (beta.isEmpty) {
        beta.add(<String>[]);
        notes.add(
          'Added implicit ε-production for $nonTerminal to preserve language.',
        );
      }

      for (final betaAlt in beta) {
        final updated = [...betaAlt, prime];
        newProductions.add(
          _productionFrom(
            nonTerminal,
            updated,
            productionCounter++,
            grammarId: grammar.id,
          ),
        );
        derivations.add(
          '$nonTerminal → ${_formatSymbols(betaAlt)}$prime (from β production)',
        );
      }

      for (final alphaAlt in alpha) {
        final updated = [...alphaAlt, prime];
        newProductions.add(
          _productionFrom(
            prime,
            updated,
            productionCounter++,
            grammarId: grammar.id,
          ),
        );
        derivations.add(
          '$prime → ${_formatSymbols(alphaAlt)}$prime (from α production)',
        );
      }

      newProductions.add(
        Production(
          id: '${grammar.id}_rec_$productionCounter',
          leftSide: [prime],
          rightSide: const [],
          isLambda: true,
          order: productionCounter++,
        ),
      );
      derivations.add('$prime → ε (allows termination of recursion)');
    }

    if (!changed) {
      notes.add('No direct left recursion detected.');
    }

    final transformed = grammar.copyWith(
      nonterminals: newNonTerminals,
      productions: newProductions.toSet(),
      modified: DateTime.now(),
    );

    return ResultFactory.success(
      GrammarAnalysisReport<Grammar>(
        value: transformed,
        notes: notes,
        derivations: derivations,
      ),
    );
  }

  static Result<GrammarAnalysisReport<Grammar>> leftFactor(Grammar grammar) {
    if (grammar.productions.isEmpty) {
      return ResultFactory.failure('The grammar has no productions.');
    }

    final grouped = _groupProductions(grammar);
    final newProductions = <Production>[];
    final newNonTerminals = grammar.nonterminals.toSet();
    final notes = <String>[];
    final derivations = <String>[];
    var productionCounter = 0;
    var factoringIndex = 1;

    bool changed = false;

    bool updated;
    do {
      updated = false;
      for (final nonTerminal in grouped.keys.toList()) {
        final alternatives = grouped[nonTerminal]!;
        final factoring = _findCommonPrefix(alternatives);
        if (factoring == null) {
          continue;
        }

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
          'Introduced non-terminal $newSymbol to factor prefix ${_formatSymbols(prefix)} from $nonTerminal.',
        );

        grouped[nonTerminal] = [
          ...alternatives.where((alt) => !toFactor.contains(alt)),
          [...prefix, newSymbol],
        ];

        grouped[newSymbol] = toFactor
            .map(
              (alt) => alt.length == prefix.length
                  ? <String>[]
                  : alt.sublist(prefix.length),
            )
            .toList();

        derivations.add(
          '$nonTerminal → ${_formatSymbols(prefix)}$newSymbol (factored ${toFactor.length} productions)',
        );
        for (final alt in grouped[newSymbol]!) {
          derivations.add(
            '$newSymbol → ${alt.isEmpty ? 'ε' : alt.join(' ')} (remaining suffix)',
          );
        }
        break;
      }
    } while (updated);

    if (!changed) {
      notes.add('No common prefixes requiring factoring were found.');
    }

    for (final entry in grouped.entries) {
      for (final alt in entry.value) {
        newProductions.add(
          _productionFrom(
            entry.key,
            alt,
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

    final transformed = grammar.copyWith(
      nonterminals: newNonTerminals,
      productions: newProductions.toSet(),
      modified: DateTime.now(),
    );

    return ResultFactory.success(
      GrammarAnalysisReport<Grammar>(
        value: transformed,
        notes: notes,
        derivations: derivations,
      ),
    );
  }

  // FIRST/FOLLOW/LL(1) reference notes live in docs/reference-deviations.md.
  static Result<GrammarAnalysisReport<Map<String, Set<String>>>>
      computeFirstSets(Grammar grammar) {
    if (grammar.productions.isEmpty) {
      return ResultFactory.failure('The grammar has no productions.');
    }

    final notes = <String>[];
    final derivations = <String>[];
    final first = <String, Set<String>>{};
    final productions = _groupProductions(grammar);

    for (final terminal in grammar.terminals) {
      first[terminal] = {terminal};
    }

    for (final nonTerminal in grammar.nonterminals) {
      first.putIfAbsent(nonTerminal, () => <String>{});
    }

    bool changed;
    do {
      changed = false;
      for (final entry in productions.entries) {
        final left = entry.key;
        if (!grammar.nonterminals.contains(left) || !first.containsKey(left)) {
          return ResultFactory.failure(
            'Cannot compute FIRST sets: production LHS "$left" is not a declared non-terminal.',
          );
        }
        for (final right in entry.value) {
          if (right.isEmpty) {
            if (first[left]!.add('ε')) {
              changed = true;
              derivations.add(
                'FIRST($left) gains ε due to production $left → ε',
              );
            }
            continue;
          }

          for (var i = 0; i < right.length; i++) {
            final symbol = right[i];
            if (isEpsilonSymbol(symbol)) {
              if (first[left]!.add('ε')) {
                changed = true;
                derivations.add(
                  'FIRST($left) gains ε because production $left → ${_formatSymbols(right)} contains ε',
                );
              }
              break;
            }

            if (!grammar.nonterminals.contains(symbol)) {
              if (first[left]!.add(symbol)) {
                changed = true;
                derivations.add(
                  'FIRST($left) gains terminal $symbol from production $left → ${_formatSymbols(right)}',
                );
              }
              break;
            }

            final source = first[symbol]!;
            final withoutEpsilon = source.where((s) => s != 'ε').toSet();
            final targetFirst = first[left]!;
            final previousLength = targetFirst.length;
            targetFirst.addAll(withoutEpsilon);
            if (targetFirst.length > previousLength) {
              changed = true;
              derivations.add(
                'FIRST($left) absorbs FIRST($symbol) − {ε} via production $left → ${_formatSymbols(right)}',
              );
            }

            if (!source.contains('ε')) {
              break;
            }

            if (i == right.length - 1) {
              if (first[left]!.add('ε')) {
                changed = true;
                derivations.add(
                  'FIRST($left) gains ε because all symbols in $left → ${_formatSymbols(right)} can derive ε',
                );
              }
            }
          }
        }
      }
    } while (changed);

    notes.add(
      'Computed FIRST sets for ${grammar.nonterminals.length} non-terminals.',
    );

    final resultMap = {
      for (final entry in first.entries)
        if (grammar.nonterminals.contains(entry.key)) entry.key: entry.value,
    };

    return ResultFactory.success(
      GrammarAnalysisReport<Map<String, Set<String>>>(
        value: resultMap,
        notes: notes,
        derivations: derivations,
      ),
    );
  }

  // FIRST/FOLLOW/LL(1) reference notes live in docs/reference-deviations.md.
  static Result<GrammarAnalysisReport<Map<String, Set<String>>>>
      computeFollowSets(Grammar grammar) {
    if (grammar.startSymbol.isEmpty ||
        !grammar.nonterminals.contains(grammar.startSymbol)) {
      return ResultFactory.failure(
        'Cannot compute FOLLOW sets: start symbol "${grammar.startSymbol}" is not a declared non-terminal.',
      );
    }

    final firstResult = computeFirstSets(grammar);
    if (firstResult.isFailure) {
      return ResultFactory.failure(firstResult.error!);
    }

    final first = firstResult.data!.value;
    final follow = {for (final nt in grammar.nonterminals) nt: <String>{}};
    final notes = <String>[];
    final derivations = List<String>.from(firstResult.data!.derivations);

    final startFollow = follow[grammar.startSymbol];
    if (startFollow == null) {
      return ResultFactory.failure(
        'Cannot compute FOLLOW sets: start symbol "${grammar.startSymbol}" has no FOLLOW entry.',
      );
    }
    startFollow.add('\$');
    derivations.add(
      'FOLLOW(${grammar.startSymbol}) includes \$ (start symbol).',
    );

    final productions = _groupProductions(grammar);

    bool changed;
    do {
      changed = false;
      for (final entry in productions.entries) {
        final left = entry.key;
        final leftFollow = follow[left];
        if (!grammar.nonterminals.contains(left) || leftFollow == null) {
          return ResultFactory.failure(
            'Cannot compute FOLLOW sets: production LHS "$left" is not a declared non-terminal.',
          );
        }
        for (final right in entry.value) {
          for (var i = 0; i < right.length; i++) {
            final symbol = right[i];
            if (!grammar.nonterminals.contains(symbol)) {
              continue;
            }

            final suffix = right.sublist(i + 1);
            final firstOfSuffix = _firstOfSequence(suffix, first);
            final withoutEpsilon = firstOfSuffix.where((s) => s != 'ε').toSet();
            final targetFollow = follow[symbol]!;
            final previousLength = targetFollow.length;
            targetFollow.addAll(withoutEpsilon);
            if (targetFollow.length > previousLength) {
              changed = true;
              derivations.add(
                "FOLLOW($symbol) gains ${withoutEpsilon.join(', ')} from FIRST of suffix in $left → ${_formatSymbols(right)}",
              );
            }

            if (suffix.isEmpty || firstOfSuffix.contains('ε')) {
              final previousFollowLength = targetFollow.length;
              targetFollow.addAll(leftFollow);
              if (targetFollow.length > previousFollowLength) {
                changed = true;
                derivations.add(
                  'FOLLOW($symbol) absorbs FOLLOW($left) because suffix can derive ε in $left → ${_formatSymbols(right)}',
                );
              }
            }
          }
        }
      }
    } while (changed);

    notes.add(
      'Computed FOLLOW sets for ${grammar.nonterminals.length} non-terminals.',
    );

    return ResultFactory.success(
      GrammarAnalysisReport<Map<String, Set<String>>>(
        value: follow,
        notes: notes,
        derivations: derivations,
      ),
    );
  }

  // FIRST/FOLLOW/LL(1) reference notes live in docs/reference-deviations.md.
  static Result<GrammarAnalysisReport<LL1ParseTable>> buildLL1ParseTable(
    Grammar grammar,
  ) {
    final firstResult = computeFirstSets(grammar);
    if (firstResult.isFailure) {
      return ResultFactory.failure(firstResult.error!);
    }

    final followResult = computeFollowSets(grammar);
    if (followResult.isFailure) {
      return ResultFactory.failure(followResult.error!);
    }

    final first = firstResult.data!.value;
    final follow = followResult.data!.value;
    final table = <String, Map<String, List<List<String>>>>{};
    final derivations = <String>[];
    final conflicts = <String>[];

    final productions = _groupProductions(grammar);
    for (final entry in productions.entries) {
      final left = entry.key;
      if (!grammar.nonterminals.contains(left) || !follow.containsKey(left)) {
        return ResultFactory.failure(
          'Cannot build LL(1) parse table: production LHS "$left" is not a declared non-terminal.',
        );
      }
      table.putIfAbsent(left, () => {});
      for (final right in entry.value) {
        final firstSet = _firstOfSequence(right, first);
        final targets = firstSet.where((symbol) => symbol != 'ε');
        for (final terminal in targets) {
          final row = table[left];
          if (row == null) {
            return ResultFactory.failure(
              'Cannot build LL(1) parse table: missing table row for "$left".',
            );
          }
          final cell = row.putIfAbsent(
            terminal,
            () => <List<String>>[],
          );
          cell.add(right);
          derivations.add(
            'Placed $left → ${_formatSymbols(right)} in table[$left, $terminal].',
          );
          if (cell.length > 1) {
            final conflictDescription =
                'Conflict at [$left, $terminal]: ${cell.map(_formatSymbols).join(' vs ')}';
            if (!conflicts.contains(conflictDescription)) {
              conflicts.add(conflictDescription);
            }
          }
        }

        if (firstSet.contains('ε')) {
          final followSet = follow[left];
          final row = table[left];
          if (followSet == null || row == null) {
            return ResultFactory.failure(
              'Cannot build LL(1) parse table: missing FOLLOW or table entry for "$left".',
            );
          }
          for (final terminal in followSet) {
            final cell = row.putIfAbsent(
              terminal,
              () => <List<String>>[],
            );
            cell.add(const []);
            derivations.add(
              'Placed $left → ε in table[$left, $terminal] using FOLLOW set.',
            );
            if (cell.length > 1) {
              final conflictDescription =
                  'Conflict at [$left, $terminal]: ${cell.map(_formatSymbols).join(' vs ')}';
              if (!conflicts.contains(conflictDescription)) {
                conflicts.add(conflictDescription);
              }
            }
          }
        }
      }
    }

    final terminals = grammar.terminals.union({'\$'});
    return ResultFactory.success(
      GrammarAnalysisReport<LL1ParseTable>(
        value: LL1ParseTable(table: table, terminals: terminals),
        derivations: [
          ...firstResult.data!.derivations,
          ...followResult.data!.derivations,
          ...derivations,
        ],
        conflicts: conflicts,
        notes: [
          'Constructed LL(1) parse table with ${table.length} non-terminals.',
          if (conflicts.isEmpty)
            'No conflicts detected in parse table.'
          else
            '${conflicts.length} conflict(s) detected in parse table.',
        ],
      ),
    );
  }

  /// Educational ambiguity indicator.
  ///
  /// IMPORTANT: LL(1) table conflicts only prove the grammar is *not LL(1)*.
  /// They do *not* prove true ambiguity (multiple parse trees) for all inputs.
  ///
  /// This method returns `true` when the grammar appears LL(1) (no conflicts)
  /// and `false` when conflicts are present.
  static Result<GrammarAnalysisReport<bool>> detectAmbiguity(Grammar grammar) {
    final tableResult = buildLL1ParseTable(grammar);
    if (tableResult.isFailure) {
      return ResultFactory.failure(tableResult.error!);
    }

    final conflicts = tableResult.data!.conflicts;
    final derivations = List<String>.from(tableResult.data!.derivations);

    final isLl1 = conflicts.isEmpty;

    final notes = <String>[
      if (isLl1)
        'No LL(1) conflicts detected (grammar appears LL(1) for this analysis).'
      else
        'LL(1) conflicts detected (grammar is not LL(1)).',
      'Note: Being non-LL(1) does not necessarily mean the grammar is ambiguous; it may still be unambiguous but require a stronger parser (e.g., LR/Earley).',
    ];

    return ResultFactory.success(
      GrammarAnalysisReport<bool>(
        value: isLl1,
        notes: notes,
        conflicts: conflicts,
        derivations: derivations,
      ),
    );
  }

  static Map<String, List<List<String>>> _groupProductions(Grammar grammar) {
    final grouped = <String, List<List<String>>>{};
    for (final production in grammar.productions) {
      if (production.leftSide.isEmpty) {
        continue;
      }
      final left = production.leftSide.first;
      grouped.putIfAbsent(left, () => <List<String>>[]);
      if (production.isLambda || production.rightSide.isEmpty) {
        grouped[left]!.add(<String>[]);
      } else {
        grouped[left]!.add(List<String>.from(production.rightSide));
      }
    }
    return grouped;
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

  static String _generatePrimeSymbol(String base, Set<String> existing) {
    var candidate = "$base'";
    while (existing.contains(candidate)) {
      candidate = "$candidate'";
    }
    return candidate;
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

  static String _formatSymbols(List<String> symbols) {
    if (symbols.isEmpty) {
      return 'ε';
    }
    return symbols.join(' ');
  }

  static Set<String> _firstOfSequence(
    List<String> sequence,
    Map<String, Set<String>> first,
  ) {
    if (sequence.isEmpty) {
      return {'ε'};
    }

    final result = <String>{};
    for (var i = 0; i < sequence.length; i++) {
      final symbol = sequence[i];
      if (isEpsilonSymbol(symbol)) {
        result.add('ε');
        break;
      }

      if (!first.containsKey(symbol)) {
        result.add(symbol);
        break;
      }

      final source = first[symbol]!;
      result.addAll(source.where((s) => s != 'ε'));
      if (!source.contains('ε')) {
        break;
      }

      if (i == sequence.length - 1) {
        result.add('ε');
      }
    }

    return result;
  }
}

class _FactoringResult {
  final List<String> prefix;
  final List<List<String>> alternatives;

  _FactoringResult({required this.prefix, required this.alternatives});
}

_FactoringResult? _findCommonPrefix(List<List<String>> alternatives) {
  if (alternatives.length < 2) {
    return null;
  }

  _FactoringResult? best;

  for (var i = 0; i < alternatives.length; i++) {
    final first = alternatives[i];
    for (var j = i + 1; j < alternatives.length; j++) {
      final second = alternatives[j];
      final prefix = <String>[];
      final length =
          first.length < second.length ? first.length : second.length;
      for (var k = 0; k < length; k++) {
        if (first[k] == second[k]) {
          prefix.add(first[k]);
        } else {
          break;
        }
      }
      if (prefix.isEmpty) {
        continue;
      }

      final group = alternatives
          .where(
            (alt) =>
                alt.length >= prefix.length &&
                const ListEquality().equals(
                  alt.sublist(0, prefix.length),
                  prefix,
                ),
          )
          .toList();

      if (group.length < 2) {
        continue;
      }

      if (best == null || prefix.length > best.prefix.length) {
        best = _FactoringResult(prefix: prefix, alternatives: group);
      }
    }
  }

  return best;
}

class ListEquality {
  const ListEquality();

  bool equals(List<Object?> a, List<Object?> b) {
    if (a.length != b.length) {
      return false;
    }
    for (var i = 0; i < a.length; i++) {
      if (a[i] != b[i]) {
        return false;
      }
    }
    return true;
  }
}
