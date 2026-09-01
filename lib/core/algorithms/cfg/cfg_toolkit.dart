//
//  cfg_toolkit.dart
//  Turing Lab
//
//  Groups utilities for manipulating context-free grammars, offering
//  structural reduction, conversion to Chomsky Normal Form (CNF) and
//  Greibach Normal Form (GNF), plus fast checks of those normalizations.
//  Reuses private operations to eliminate lambda and unit productions and
//  to remove useless symbols, producing leaner equivalent grammars for
//  subsequent analyses.
//
//  Thales Matheus Mendonça Santos - October 2025
//
import '../../models/grammar.dart';
import '../../grammar/phrase_structure/phrase_structure.dart';
import '../../models/production.dart';
import '../../result.dart';
import '../cfg_toolkit_messages.dart';

/// Toolkit for context-free grammars: CNF and GNF normalization and checks
class CFGToolkit {
  /// Remove ε-productions (except possibly S→ε), unit productions and useless symbols,
  /// returning an equivalent reduced grammar.
  static Result<Grammar> reduce(Grammar g) {
    try {
      final noLambda = _removeLambdaProductions(g);
      final noUnit = _removeUnitProductions(noLambda);
      final reduced = _removeUselessSymbols(noUnit);
      return ResultFactory.success(reduced);
    } catch (e) {
      final message = CfgToolkitMessages.reduceFailed();
      return Failure('CFG reduce error: $e', structuredMessage: message);
    }
  }

  /// Convert to Chomsky Normal Form (CNF).
  /// Assumes input is context-free.
  static Result<Grammar> toCNF(Grammar g) {
    try {
      // 1) Reduce grammar
      final reduced = (reduce(g).data)!;

      // 2) Ensure start symbol does not appear on right side by introducing S0 → S
      final needsAugment = reduced.productions.any(
        (p) => p.rightSide.contains(reduced.startSymbol),
      );
      final start = needsAugment
          ? '${reduced.startSymbol}0'
          : reduced.startSymbol;
      final nonterminals = {...reduced.nonterminals, if (needsAugment) start};
      final productionIds = _FreshProductionIds(
        reduced.productions.map((production) => production.id),
      );
      final productions = <Production>{
        if (needsAugment)
          Production.unit(
            id: productionIds.allocate('aug'),
            leftSide: start,
            rightSide: reduced.startSymbol,
          ),
        ...reduced.productions,
      };
      var current = reduced.copyWith(
        nonterminals: nonterminals,
        startSymbol: start,
        productions: productions,
      );

      // 3) Break long RHS into binary chain
      current = _binarize(current);

      // 4) Replace terminals in binary rules by introducing new nonterminals
      current = _terminalizeBinary(current);

      return ResultFactory.success(current);
    } catch (e) {
      final message = CfgToolkitMessages.toCnfFailed();
      return Failure('CFG toCNF error: $e', structuredMessage: message);
    }
  }

  /// Convert to Greibach Normal Form (GNF).
  /// Assumes input is context-free.
  static Result<Grammar> toGNF(Grammar g) {
    try {
      // 1) Start by converting to CNF to have a well-structured grammar
      final cnfResult = toCNF(g);
      if (cnfResult.isFailure) {
        return cnfResult;
      }
      var current = cnfResult.data!;

      // 2) Order nonterminals for systematic processing
      final ordered = current.nonterminals.toList()..sort();

      // 3) Transform each production to ensure it starts with a terminal
      current = _transformToGNF(current, ordered);

      return ResultFactory.success(current);
    } catch (e) {
      final message = CfgToolkitMessages.toGnfFailed();
      return Failure('CFG toGNF error: $e', structuredMessage: message);
    }
  }

  /// Check if grammar is in CNF: A→BC or A→a, and S→ε optionally
  static bool isCNF(Grammar g) => PhraseGrammarClassifier.classifyLegacy(
    g,
  ).normalForms.contains(PhraseGrammarNormalForm.weakChomsky);

  /// Check if grammar is in GNF: A→aα where a is terminal and α is nonterminals*
  static bool isGNF(Grammar g) => PhraseGrammarClassifier.classifyLegacy(
    g,
  ).normalForms.contains(PhraseGrammarNormalForm.greibach);

  static Grammar _removeLambdaProductions(Grammar g) {
    final nullable = g.nullableNonterminals;
    final newProductions = <Production>{};
    for (final p in g.productions) {
      if (p.isLambda) continue;
      // generate all subsets of nullable occurrences in RHS
      final rhs = p.rightSide;
      final positions = <int>[];
      for (var i = 0; i < rhs.length; i++) {
        if (nullable.contains(rhs[i])) positions.add(i);
      }
      if (positions.isEmpty) {
        newProductions.add(p);
        continue;
      }
      final total = 1 << positions.length;
      for (int mask = 0; mask < total; mask++) {
        final newRhs = <String>[];
        for (var i = 0; i < rhs.length; i++) {
          final idx = positions.indexOf(i);
          final drop = idx >= 0 && ((mask >> idx) & 1) == 1;
          if (!drop) newRhs.add(rhs[i]);
        }
        if (newRhs.isEmpty) {
          // Only keep S→ε
          if (p.leftSide.first == g.startSymbol) {
            newProductions.add(
              Production.lambda(id: '${p.id}_eps', leftSide: p.leftSide.first),
            );
          }
        } else {
          newProductions.add(
            Production(
              id: '${p.id}_nl_$mask',
              leftSide: p.leftSide,
              rightSide: newRhs,
            ),
          );
        }
      }
    }
    return g.copyWith(productions: newProductions);
  }

  static Grammar _removeUnitProductions(Grammar g) {
    bool isUnit(Production production) =>
        !production.isLambda &&
        production.leftSide.length == 1 &&
        production.rightSide.length == 1 &&
        g.nonterminals.contains(production.rightSide.single);

    final byLeft = <String, List<Production>>{};
    for (final production in g.productions) {
      if (production.leftSide.length != 1) continue;
      byLeft.putIfAbsent(production.leftSide.single, () => []).add(production);
    }
    for (final productions in byLeft.values) {
      productions.sort((left, right) => left.id.compareTo(right.id));
    }

    final output = <Production>{};
    final shapes = <String>{};
    final productionIds = _FreshProductionIds(
      g.productions.map((production) => production.id),
    );
    final nonterminals = g.nonterminals.toList()..sort();
    for (final source in nonterminals) {
      final closure = <String>{source};
      final queue = <String>[source];
      while (queue.isNotEmpty) {
        final current = queue.removeAt(0);
        for (final production in byLeft[current] ?? const []) {
          if (isUnit(production) && closure.add(production.rightSide.single)) {
            queue.add(production.rightSide.single);
          }
        }
      }
      final targets = closure.toList()..sort();
      for (final target in targets) {
        for (final production in byLeft[target] ?? const []) {
          if (isUnit(production)) continue;
          final shape =
              '$source\u0001${production.rightSide.join('\u0000')}'
              '\u0001${production.isLambda}';
          if (!shapes.add(shape)) continue;
          output.add(
            production.copyWith(
              id: target == source
                  ? production.id
                  : productionIds.allocate('${production.id}_unit_$source'),
              leftSide: [source],
            ),
          );
        }
      }
    }
    return g.copyWith(productions: output);
  }

  static Grammar _removeUselessSymbols(Grammar g) {
    final useful = g.usefulNonterminals;
    final newProds = g.productions
        .where((p) => useful.contains(p.leftSide.first))
        .toSet();
    final newNon = g.nonterminals.intersection(useful);
    return g.copyWith(nonterminals: newNon, productions: newProds);
  }

  static Grammar _binarize(Grammar g) {
    final prods = <Production>{};
    final used = <String>{...g.terminals, ...g.nonterminals};
    final generated = <String>{};
    final productionIds = _FreshProductionIds(
      g.productions.map((production) => production.id),
    );
    var fresh = 0;
    String allocate() {
      while (used.contains('N$fresh')) {
        fresh++;
      }
      final value = 'N${fresh++}';
      used.add(value);
      generated.add(value);
      return value;
    }

    for (final p in g.productions) {
      if (p.isLambda || p.rightSide.length <= 2) {
        prods.add(p);
        continue;
      }
      // A → X1 X2 X3 ... Xk  => A→X1 N0, N0→X2 N1, ..., Nk-3→X(k-1) Xk
      String left = p.leftSide.first;
      final rhs = List<String>.from(p.rightSide);
      while (rhs.length > 2) {
        final n = allocate();
        prods.add(
          Production(
            id: productionIds.allocate('${p.id}_b_$n'),
            leftSide: [left],
            rightSide: [rhs.removeAt(0), n],
          ),
        );
        left = n;
      }
      prods.add(
        Production(
          id: productionIds.allocate('${p.id}_b_end'),
          leftSide: [left],
          rightSide: rhs,
        ),
      );
    }
    final nonterminals = {...g.nonterminals, ...generated};
    return g.copyWith(nonterminals: nonterminals, productions: prods);
  }

  static Grammar _terminalizeBinary(Grammar g) {
    final prods = <Production>{};
    final mapping = <String, String>{};
    final used = <String>{...g.terminals, ...g.nonterminals};
    final productionIds = _FreshProductionIds(
      g.productions.map((production) => production.id),
    );
    var k = 0;
    String allocate() {
      while (used.contains('T$k')) {
        k++;
      }
      final value = 'T${k++}';
      used.add(value);
      return value;
    }

    for (final p in g.productions) {
      if (p.rightSide.length == 2) {
        final rhs = <String>[];
        for (final sym in p.rightSide) {
          if (g.terminals.contains(sym)) {
            final t = mapping.putIfAbsent(sym, allocate);
            rhs.add(t);
          } else {
            rhs.add(sym);
          }
        }
        prods.add(
          Production(
            id: productionIds.allocate('${p.id}_tb'),
            leftSide: p.leftSide,
            rightSide: rhs,
          ),
        );
      } else {
        prods.add(p);
      }
    }
    final extraNon = mapping.values.toSet();
    final extraProds = mapping.entries.map(
      (e) => Production.terminal(
        id: productionIds.allocate('m_${e.key}'),
        leftSide: e.value,
        terminal: e.key,
      ),
    );
    prods.addAll(extraProds);
    return g.copyWith(
      nonterminals: {...g.nonterminals, ...extraNon},
      productions: prods,
    );
  }

  static Grammar _transformToGNF(Grammar g, List<String> orderedNonterminals) {
    final prods = Set<Production>.from(g.productions);
    final nonterminals = Set<String>.from(g.nonterminals);
    final terminals = Set<String>.from(g.terminals);
    int freshCounter = 0;

    // Build the CNF terminal-wrapper mapping: T0 → a, T1 → b, etc.
    final terminalWrapperMap = <String, String>{};
    for (final p in g.productions) {
      if (p.rightSide.length == 1 &&
          terminals.contains(p.rightSide.first) &&
          p.leftSide.first != g.startSymbol &&
          !terminals.contains(p.leftSide.first) &&
          nonterminals.contains(p.leftSide.first)) {
        terminalWrapperMap[p.leftSide.first] = p.rightSide.first;
      }
    }

    // Helper: check if a symbol is a terminal (original terminal)
    bool isTerminal(String s) => terminals.contains(s);

    // Helper: get productions for a given nonterminal from the current set
    List<Production> prodsFor(String nt) =>
        prods.where((p) => p.leftSide.first == nt && !p.isLambda).toList();

    // Helper to generate unique IDs
    String freshId(String prefix) => '${prefix}_${freshCounter++}';

    // Step 1: Forward pass - order nonterminals and ensure Ai productions
    // start with Aj (j > i) or a terminal.
    for (var i = 0; i < orderedNonterminals.length; i++) {
      final ai = orderedNonterminals[i];

      // Iteratively substitute until no production for Ai starts with Aj (j < i)
      bool changed = true;
      while (changed) {
        changed = false;
        final aiProds = prodsFor(ai);

        for (final p in aiProds) {
          if (p.rightSide.isEmpty) continue;
          final first = p.rightSide.first;

          // Already starts with terminal - fine
          if (isTerminal(first)) continue;

          // If starts with Aj where j < i, substitute
          final j = orderedNonterminals.indexOf(first);
          if (j >= 0 && j < i) {
            prods.remove(p);
            final ajProds = prodsFor(first);
            for (final sub in ajProds) {
              final newRhs = [...sub.rightSide, ...p.rightSide.sublist(1)];
              prods.add(
                Production(
                  id: freshId('${p.id}_sub'),
                  leftSide: p.leftSide,
                  rightSide: newRhs,
                ),
              );
            }
            changed = true;
            break; // restart the inner loop since prods changed
          }
        }
      }

      // Now eliminate left recursion for Ai (Ai → Ai alpha)
      final aiProdsNow = prodsFor(ai);
      final recursive = <Production>[];
      final nonRecursive = <Production>[];

      for (final p in aiProdsNow) {
        if (p.rightSide.isNotEmpty && p.rightSide.first == ai) {
          recursive.add(p);
        } else {
          nonRecursive.add(p);
        }
      }

      if (recursive.isNotEmpty) {
        final newSym = '${ai}P${freshCounter++}';
        nonterminals.add(newSym);

        // Remove all Ai productions (both recursive and non-recursive)
        for (final p in aiProdsNow) {
          prods.remove(p);
        }

        // For each non-recursive production Ai → beta:
        //   Add Ai → beta and Ai → beta newSym
        for (final nr in nonRecursive) {
          prods.add(
            Production(
              id: freshId('${nr.id}_nr'),
              leftSide: nr.leftSide,
              rightSide: nr.rightSide,
            ),
          );
          prods.add(
            Production(
              id: freshId('${nr.id}_nrp'),
              leftSide: nr.leftSide,
              rightSide: [...nr.rightSide, newSym],
            ),
          );
        }

        // For each recursive production Ai → Ai alpha:
        //   Add newSym → alpha and newSym → alpha newSym
        for (final rec in recursive) {
          final alpha = rec.rightSide.sublist(1);
          prods.add(
            Production(
              id: freshId('${rec.id}_lr1'),
              leftSide: [newSym],
              rightSide: alpha,
            ),
          );
          prods.add(
            Production(
              id: freshId('${rec.id}_lr2'),
              leftSide: [newSym],
              rightSide: [...alpha, newSym],
            ),
          );
        }
      }
    }

    // Step 2: Back-substitution from An down to A1.
    // After the forward pass, An's productions all start with terminals.
    // We go backwards and substitute any leading nonterminal.
    // Also handle the new left-recursion-elimination nonterminals (e.g., AP0).
    // We need to process all nonterminals that have productions.
    final allNonterminalsInProds = prods.map((p) => p.leftSide.first).toSet();

    // Build the processing order: the original ordered list reversed,
    // then any additional nonterminals (from left-recursion elimination).
    final backOrder = orderedNonterminals.reversed.toList();
    final extraNonterminals = allNonterminalsInProds.difference(
      orderedNonterminals.toSet(),
    );
    backOrder.addAll(extraNonterminals);

    // Iterative back-substitution until all productions start with a terminal.
    bool changed = true;
    int safetyLimit = 100; // prevent infinite loops
    while (changed && safetyLimit > 0) {
      changed = false;
      safetyLimit--;

      for (final nt in backOrder) {
        final ntProds = prodsFor(nt);
        for (final p in ntProds) {
          if (p.rightSide.isEmpty) continue;
          final first = p.rightSide.first;
          if (isTerminal(first)) continue;

          // It starts with a nonterminal - substitute it
          final firstProds = prodsFor(first);
          if (firstProds.isEmpty) continue;

          // Only substitute if the target productions are "better"
          // (i.e., at least one starts with a terminal)
          final hasTerminalStart = firstProds.any(
            (q) => q.rightSide.isNotEmpty && isTerminal(q.rightSide.first),
          );
          if (!hasTerminalStart) continue;

          prods.remove(p);
          for (final sub in firstProds) {
            final newRhs = [...sub.rightSide, ...p.rightSide.sublist(1)];
            prods.add(
              Production(
                id: freshId('${p.id}_bk'),
                leftSide: p.leftSide,
                rightSide: newRhs,
              ),
            );
          }
          changed = true;
          break; // restart since prods changed
        }
        if (changed) break;
      }
    }

    // If there are still productions starting with nonterminals, do
    // aggressive iterative substitution (no "hasTerminalStart" check).
    safetyLimit = 100;
    changed = true;
    while (changed && safetyLimit > 0) {
      changed = false;
      safetyLimit--;

      for (final p in prods.toList()) {
        if (p.isLambda || p.rightSide.isEmpty) continue;
        final first = p.rightSide.first;
        if (isTerminal(first)) continue;

        final firstProds = prodsFor(first);
        if (firstProds.isEmpty) continue;

        prods.remove(p);
        for (final sub in firstProds) {
          final newRhs = [...sub.rightSide, ...p.rightSide.sublist(1)];
          prods.add(
            Production(
              id: freshId('${p.id}_ag'),
              leftSide: p.leftSide,
              rightSide: newRhs,
            ),
          );
        }
        changed = true;
        break;
      }
    }

    // Step 3: Inline CNF terminal-wrapper nonterminals.
    // Replace any Tk in the tail (positions 1+) of a production with
    // the actual terminal, but since GNF requires tail to be nonterminals,
    // we only inline Tk when it appears as the FIRST symbol (leading position).
    // Actually, we need to:
    //  - Inline Tk at position 0 (replace with its terminal)
    //  - Keep Tk at positions 1+ as nonterminals (which is valid for GNF since
    //    they ARE nonterminals)
    // BUT: the isGNF checker checks g.terminals.contains(first), so T0 at
    // position 0 would fail. We must inline T0 → a at position 0.
    //
    // Also, terminal-wrapper nonterminals at positions > 0 are fine since
    // they are nonterminals. However, the test in gnf_conversion_test.dart
    // checks gnf.nonterminals.contains(p.rightSide[i]) for i > 0.
    // So we need T0 etc. to stay in the nonterminals set.

    final finalProds = <Production>{};
    for (final p in prods) {
      if (p.isLambda) {
        finalProds.add(p);
        continue;
      }
      if (p.rightSide.isEmpty) continue;

      final first = p.rightSide.first;
      if (!isTerminal(first) && terminalWrapperMap.containsKey(first)) {
        // Inline the terminal wrapper at position 0
        finalProds.add(
          Production(
            id: freshId('${p.id}_tw'),
            leftSide: p.leftSide,
            rightSide: [terminalWrapperMap[first]!, ...p.rightSide.sublist(1)],
          ),
        );
      } else {
        finalProds.add(p);
      }
    }

    // Remove the terminal-wrapper productions (T0 → a, etc.) since they
    // are no longer needed and would fail isGNF (single terminal production
    // is valid GNF only if that nonterminal is used elsewhere, but these
    // are just helpers). Actually, keep them only if they still appear in
    // some production's tail.
    final usedNonterminals = <String>{};
    for (final p in finalProds) {
      if (p.isLambda) continue;
      for (var i = 1; i < p.rightSide.length; i++) {
        if (nonterminals.contains(p.rightSide[i])) {
          usedNonterminals.add(p.rightSide[i]);
        }
      }
    }

    // Keep terminal-wrapper productions only if the wrapper nonterminal
    // is used in the tail of some production. Inline those too.
    final cleanedProds = <Production>{};
    for (final p in finalProds) {
      final lhs = p.leftSide.first;
      if (terminalWrapperMap.containsKey(lhs) &&
          !usedNonterminals.contains(lhs)) {
        // Drop this terminal-wrapper production since it's unused
        continue;
      }
      cleanedProds.add(p);
    }

    // Different substitution paths can produce the same rule with fresh IDs.
    // Keep one stable representative so structural classifiers do not reject
    // an otherwise valid GNF grammar for duplicate production shapes.
    final uniqueShapes = <String>{};
    final uniqueProds = <Production>{};
    final orderedCleanedProds = cleanedProds.toList()
      ..sort((left, right) => left.id.compareTo(right.id));
    for (final production in orderedCleanedProds) {
      final shape =
          '${production.leftSide.join('\u0000')}\u0001'
          '${production.rightSide.join('\u0000')}\u0001'
          '${production.isLambda}';
      if (uniqueShapes.add(shape)) uniqueProds.add(production);
    }

    // Ensure terminals appearing at position 0 after inlining are in the
    // terminal set (they should already be from the original grammar).
    // Also ensure all tail nonterminals are in the nonterminals set.
    return g.copyWith(nonterminals: nonterminals, productions: uniqueProds);
  }
}

final class _FreshProductionIds {
  _FreshProductionIds(Iterable<String> ids) : _used = ids.toSet();

  final Set<String> _used;

  String allocate(String preferred) {
    if (_used.add(preferred)) return preferred;
    var suffix = 1;
    while (!_used.add('$preferred-$suffix')) {
      suffix++;
    }
    return '$preferred-$suffix';
  }
}
