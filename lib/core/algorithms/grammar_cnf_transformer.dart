//
//  grammar_cnf_transformer.dart
//  Turing Lab
//
//  Implements a best-effort Chomsky Normal Form (CNF) transformation pipeline
//  for context-free grammars.
//
//  The implementation is educational and non-crashing: when preconditions are
//  violated (unknown symbols, malformed productions), it will attempt to
//  continue and emit diagnostics/warnings instead of throwing.
//
import '../models/grammar.dart';
import '../models/grammar_diagnostic.dart';
import '../models/grammar_diagnostic_severity.dart';
import '../models/grammar_transformation_step.dart';
import '../models/production.dart';
import '../messages/structured_message.dart';
import '../result.dart';
import '../utils/epsilon_utils.dart';
import 'grammar_analyzer.dart';
import 'grammar_cnf_messages.dart';

class GrammarCnfTransformationReport {
  final Grammar grammar;
  final List<GrammarTransformationStep> steps;
  final List<GrammarCnfStructuredTransformationStep> structuredSteps;
  final List<GrammarDiagnostic> diagnostics;

  const GrammarCnfTransformationReport({
    required this.grammar,
    this.steps = const [],
    this.structuredSteps = const [],
    this.diagnostics = const [],
  });
}

class GrammarCnfTransformer {
  /// Caps nullable-position subset expansion in ε-removal.
  ///
  /// _GrammarCnfInternals.subsetsOfPositions(nullablePositions) creates one
  /// subset per omitted nullable-symbol combination, and each subset can create
  /// a derived Production through _GrammarCnfInternals.derivedId. Keeping this
  /// bounded prevents one production with many nullablePositions from producing
  /// an exponential number of new leftSide/rightSide variants.
  static const int maxNullableSubsets = 4096;
  static int _fallbackCounter = 0;

  static Result<GrammarCnfTransformationReport> toCnf(
    Grammar input, {
    int maxNewNonTerminals = 200,
    int maxNullableSubsetExpansions = maxNullableSubsets,
  }) {
    _fallbackCounter = 0;
    final steps = <GrammarTransformationStep>[];
    final structuredSteps = <GrammarCnfStructuredTransformationStep>[];
    final diagnostics = <GrammarDiagnostic>[];

    void addStep({
      required String kind,
      required GrammarTransformationStep step,
    }) {
      steps.add(step);
      structuredSteps.add(
        GrammarCnfStructuredTransformationStep(
          legacyStep: step,
          operationMessage: GrammarCnfMessages.stepTitle(kind),
          rationaleMessage: GrammarCnfMessages.stepRationale(kind),
        ),
      );
    }

    // Run non-crashing validation diagnostics first.
    final malformedResult = GrammarAnalyzer.validateMalformedProductions(input);
    if (malformedResult.isSuccess) {
      diagnostics.addAll(malformedResult.data?.diagnostics ?? const []);
    }

    if (input.type != GrammarType.contextFree) {
      diagnostics.add(
        _cnfDiagnostic(
          code: 'cnf.grammar_not_cfg',
          message: GrammarCnfMessages.grammarNotCfg(input.type.name),
        ),
      );
    }

    var current = input;

    // 1) Ensure start symbol does not appear on RHS.
    final startOnRhs = current.productions.any(
      (p) => p.rightSide.contains(current.startSymbol),
    );
    if (startOnRhs && current.startSymbol.isNotEmpty) {
      final before = current;
      final newStart = _freshNonTerminal(
        base: '${current.startSymbol}_0',
        used: current.nonterminals.union(current.terminals),
      );
      if (newStart == null) {
        diagnostics.add(
          _cnfDiagnostic(
            code: 'cnf.start_symbol_rename_failed',
            message: GrammarCnfMessages.startSymbolRenameFailed(),
          ),
        );
      } else {
        final newProductions = current.productions.toSet();
        newProductions.add(
          Production(
            id: _newProductionId('S', newProductions),
            leftSide: [newStart],
            rightSide: [current.startSymbol],
          ),
        );

        current = current.copyWith(
          startSymbol: newStart,
          nonterminals: {...current.nonterminals, newStart},
          productions: newProductions,
          modified: DateTime.now(),
        );

        addStep(
          kind: 'start-symbol',
          step: GrammarTransformationStep(
            id: 'cnf.start_symbol',
            operation: 'Introduce new start symbol',
            rationale:
                'CNF conversion requires the start symbol to not appear on the right-hand side of any production. A fresh start symbol is added with a single unit production to the old start symbol.',
            before: before,
            after: current,
            changedSymbols: {newStart},
          ),
        );
      }
    }

    // 2) Remove ε-productions.
    {
      final before = current;
      final result = _removeEpsilonProductions(
        current,
        maxNullableSubsetExpansions: maxNullableSubsetExpansions,
      );
      current = result.grammar;
      diagnostics.addAll(result.diagnostics);
      if (!_grammarsEqual(before, current)) {
        addStep(
          kind: 'epsilon',
          step: GrammarTransformationStep(
            id: 'cnf.epsilon',
            operation: 'Remove ε-productions',
            rationale:
                'Eliminates ε-productions by computing nullable non-terminals and adding productions with nullable symbols omitted. If the (new) start symbol is nullable, its ε-production is preserved.',
            before: before,
            after: current,
            changedSymbols: result.changedSymbols,
            changedProductionIds: result.changedProductionIds,
          ),
        );
      }
    }

    // 3) Remove unit productions.
    {
      final before = current;
      final result = _removeUnitProductions(current);
      current = result.grammar;
      diagnostics.addAll(result.diagnostics);
      if (!_grammarsEqual(before, current)) {
        addStep(
          kind: 'unit',
          step: GrammarTransformationStep(
            id: 'cnf.unit',
            operation: 'Remove unit productions',
            rationale:
                'Removes productions of the form A → B by computing unit-closure pairs and replacing them with the productions of the target non-terminal.',
            before: before,
            after: current,
            changedSymbols: result.changedSymbols,
            changedProductionIds: result.changedProductionIds,
          ),
        );
      }
    }

    // 4) Remove useless symbols (unreachable + unproductive).
    {
      final before = current;
      final result = _removeUselessSymbols(current);
      current = result.grammar;
      diagnostics.addAll(result.diagnostics);
      if (!_grammarsEqual(before, current)) {
        addStep(
          kind: 'useless',
          step: GrammarTransformationStep(
            id: 'cnf.useless',
            operation: 'Remove useless symbols',
            rationale:
                'Removes unreachable and unproductive non-terminals (and productions referencing them), since they cannot contribute to any derivation from the start symbol.',
            before: before,
            after: current,
            changedSymbols: result.changedSymbols,
            changedProductionIds: result.changedProductionIds,
          ),
        );
      }
    }

    // 5) Replace terminals in long RHS and binarize.
    {
      final before = current;
      final result = _replaceTerminalsAndBinarize(
        current,
        maxNewNonTerminals: maxNewNonTerminals,
      );
      current = result.grammar;
      diagnostics.addAll(result.diagnostics);
      if (!_grammarsEqual(before, current)) {
        addStep(
          kind: 'binarize',
          step: GrammarTransformationStep(
            id: 'cnf.binarize',
            operation: 'Replace terminals and binarize',
            rationale:
                'For any production with length ≥ 2, terminals are replaced by fresh non-terminals so that binary productions only contain non-terminals. Then productions longer than 2 are broken into a chain of binary productions.',
            before: before,
            after: current,
            changedSymbols: result.changedSymbols,
            changedProductionIds: result.changedProductionIds,
          ),
        );
      }
    }

    // Epsilon and unit elimination can reach one structural rule through
    // multiple provenance paths. Production equality includes the ID, so a
    // Set alone does not remove those semantic duplicates. Retain the stable
    // first provenance record before strict normal-form validation.
    current = _deduplicateProductionShapes(current);

    // Final CNF sanity warning (best-effort).
    final cnfViolations = _findCnfViolations(current);
    if (cnfViolations.isNotEmpty) {
      final violationText =
          '${cnfViolations.take(5).join('; ')}${cnfViolations.length > 5 ? '…' : ''}';
      diagnostics.add(
        _cnfDiagnostic(
          code: 'cnf.not_strict_cnf',
          message: GrammarCnfMessages.notStrictCnf(violationText),
        ),
      );
    }

    return ResultFactory.success(
      GrammarCnfTransformationReport(
        grammar: current,
        steps: steps,
        structuredSteps: structuredSteps,
        diagnostics: diagnostics,
      ),
    );
  }

  static bool _grammarsEqual(Grammar a, Grammar b) {
    if (identical(a, b)) return true;
    return a.startSymbol == b.startSymbol &&
        setEquals(a.terminals, b.terminals) &&
        setEquals(a.nonterminals, b.nonterminals) &&
        setEquals(a.productions, b.productions);
  }

  static bool setEquals<T>(Set<T> a, Set<T> b) {
    if (a.length != b.length) return false;
    for (final v in a) {
      if (!b.contains(v)) return false;
    }
    return true;
  }

  static String _newProductionId(String prefix, Set<Production> used) {
    final usedIds = used.map((p) => p.id).toSet();
    var i = 0;
    while (usedIds.contains('$prefix$i')) {
      i++;
    }
    return '$prefix$i';
  }

  static String? _freshNonTerminal({
    required String base,
    required Set<String> used,
  }) {
    if (!used.contains(base)) return base;
    for (var i = 1; i < 1000; i++) {
      final candidate = '${base}_$i';
      if (!used.contains(candidate)) return candidate;
    }
    return null;
  }

  static int _nextFallbackSuffix() => _fallbackCounter++;
}

GrammarDiagnostic _cnfDiagnostic({
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

Grammar _deduplicateProductionShapes(Grammar grammar) {
  final ordered = grammar.productions.toList()
    ..sort((left, right) => left.id.compareTo(right.id));
  final shapes = <String>{};
  final productions = <Production>{};
  for (final production in ordered) {
    final shape =
        '${production.leftSide.join('\u0000')}\u0001'
        '${production.rightSide.join('\u0000')}\u0001${production.isLambda}';
    if (shapes.add(shape)) productions.add(production);
  }
  return grammar.copyWith(productions: productions, modified: grammar.modified);
}

class _TransformResult {
  final Grammar grammar;
  final List<GrammarDiagnostic> diagnostics;
  final Set<String> changedSymbols;
  final Set<String> changedProductionIds;

  const _TransformResult({
    required this.grammar,
    this.diagnostics = const [],
    this.changedSymbols = const {},
    this.changedProductionIds = const {},
  });
}

_TransformResult _removeEpsilonProductions(
  Grammar grammar, {
  int maxNullableSubsetExpansions = GrammarCnfTransformer.maxNullableSubsets,
}) {
  return _removeEpsilonProductionsWithCap(
    grammar,
    maxNullableSubsetExpansions: maxNullableSubsetExpansions,
  );
}

_TransformResult _removeEpsilonProductionsWithCap(
  Grammar grammar, {
  required int maxNullableSubsetExpansions,
}) {
  final diagnostics = <GrammarDiagnostic>[];

  final nullable = <String>{};
  var changed = true;
  while (changed) {
    changed = false;
    for (final p in grammar.productions) {
      if (p.leftSide.length != 1) continue;
      final left = p.leftSide.first;
      if (nullable.contains(left)) continue;

      if (p.isLambda ||
          p.rightSide.every(_GrammarCnfInternals.isNullableSymbol(nullable))) {
        nullable.add(left);
        changed = true;
      }
    }
  }

  final preserveStartEpsilon = nullable.contains(grammar.startSymbol);

  final newProductions = <Production>{};
  final removedIds = <String>{};

  for (final p in grammar.productions) {
    if (p.leftSide.length != 1) {
      newProductions.add(p);
      continue;
    }

    if (p.isLambda) {
      if (p.leftSide.first == grammar.startSymbol && preserveStartEpsilon) {
        newProductions.add(p);
      } else {
        removedIds.add(p.id);
      }
      continue;
    }

    final rhs = p.rightSide;
    final nullablePositions = <int>[];
    for (var i = 0; i < rhs.length; i++) {
      final sym = rhs[i];
      if (nullable.contains(sym)) {
        nullablePositions.add(i);
      }
    }

    // Generate subsets omitting nullable symbols.
    final subsetCount = 1 << nullablePositions.length;
    if (subsetCount > maxNullableSubsetExpansions) {
      diagnostics.add(
        _cnfDiagnostic(
          code: 'cnf.nullable_subset_limit_exceeded',
          message: GrammarCnfMessages.nullableSubsetLimitExceeded(
            productionId: p.id,
            nullablePositionCount: nullablePositions.length,
            subsetCount: subsetCount,
            limit: maxNullableSubsetExpansions,
          ),
          symbols: p.leftSide,
          productionIds: [p.id],
        ),
      );
      newProductions.add(p);
      continue;
    }

    final subsets = _GrammarCnfInternals.subsetsOfPositions(nullablePositions);
    for (final subset in subsets) {
      final filtered = <String>[];
      for (var i = 0; i < rhs.length; i++) {
        if (subset.contains(i)) continue;
        filtered.add(rhs[i]);
      }

      if (filtered.isEmpty) {
        // Only keep empty RHS as ε if it's for start symbol.
        if (p.leftSide.first == grammar.startSymbol && preserveStartEpsilon) {
          newProductions.add(
            Production(
              id: _GrammarCnfInternals.derivedId(p.id, 'eps'),
              leftSide: p.leftSide,
              rightSide: const [],
              isLambda: true,
              order: p.order,
            ),
          );
        }
        continue;
      }

      newProductions.add(
        Production(
          id: _GrammarCnfInternals.derivedId(p.id, 'neps'),
          leftSide: p.leftSide,
          rightSide: filtered,
          isLambda: false,
          order: p.order,
        ),
      );
    }
  }

  final updated = grammar.copyWith(
    productions: newProductions,
    modified: DateTime.now(),
  );

  return _TransformResult(
    grammar: updated,
    diagnostics: diagnostics,
    changedSymbols: nullable,
    changedProductionIds: removedIds,
  );
}

_TransformResult _removeUnitProductions(Grammar grammar) {
  final diagnostics = <GrammarDiagnostic>[];
  final nonterminals = grammar.nonterminals;
  final affectedNonterminals = <String>{};

  bool isUnit(Production p) {
    return p.leftSide.length == 1 &&
        !p.isLambda &&
        p.rightSide.length == 1 &&
        nonterminals.contains(p.rightSide.first);
  }

  final byLeft = <String, List<Production>>{};
  for (final p in grammar.productions) {
    if (p.leftSide.length != 1) continue;
    byLeft.putIfAbsent(p.leftSide.first, () => []).add(p);
  }

  final unitClosures = <String, Set<String>>{};
  for (final A in nonterminals) {
    final closure = <String>{A};
    final queue = <String>[A];
    while (queue.isNotEmpty) {
      final current = queue.removeLast();
      for (final p in byLeft[current] ?? const []) {
        if (!isUnit(p)) continue;
        final B = p.rightSide.first;
        if (closure.add(B)) {
          queue.add(B);
        }
      }
    }
    unitClosures[A] = closure;
  }

  final newProductions = <Production>{};
  final removedIds = <String>{};

  for (final p in grammar.productions) {
    if (isUnit(p)) {
      removedIds.add(p.id);
      if (p.leftSide.isNotEmpty) {
        affectedNonterminals.add(p.leftSide.first);
      }
      affectedNonterminals.add(p.rightSide.first);
      continue;
    }
    newProductions.add(p);
  }

  for (final A in nonterminals) {
    final closure = unitClosures[A] ?? {A};
    if (closure.length > 1) {
      affectedNonterminals.add(A);
      affectedNonterminals.addAll(closure.where((symbol) => symbol != A));
    }
    for (final B in closure) {
      for (final p in byLeft[B] ?? const []) {
        if (isUnit(p)) continue;
        if (p.leftSide.length != 1) continue;
        if (B != A) {
          affectedNonterminals.add(A);
          affectedNonterminals.add(B);
        }
        newProductions.add(
          Production(
            id: _GrammarCnfInternals.derivedId(p.id, 'u_$A'),
            leftSide: [A],
            rightSide: p.rightSide,
            isLambda: p.isLambda,
            order: p.order,
          ),
        );
      }
    }
  }

  return _TransformResult(
    grammar: grammar.copyWith(
      productions: newProductions,
      modified: DateTime.now(),
    ),
    diagnostics: diagnostics,
    changedSymbols: affectedNonterminals,
    changedProductionIds: removedIds,
  );
}

_TransformResult _removeUselessSymbols(Grammar grammar) {
  final diagnostics = <GrammarDiagnostic>[];
  final removedIds = <String>{};

  Grammar removeSymbols(Grammar source, Set<String> symbols) {
    if (symbols.isEmpty) return source;

    final productions = <Production>{};
    for (final production in source.productions) {
      if (production.leftSide.any(symbols.contains) ||
          production.rightSide.any(symbols.contains)) {
        removedIds.add(production.id);
      } else {
        productions.add(production);
      }
    }

    return source.copyWith(
      nonterminals: source.nonterminals.difference(symbols),
      productions: productions,
      modified: source.modified,
    );
  }

  final productiveReport = GrammarAnalyzer.detectUnproductiveNonTerminals(
    grammar,
  );
  final unproductive = <String>{};
  if (productiveReport.isSuccess) {
    for (final d
        in productiveReport.data?.diagnostics ?? const <GrammarDiagnostic>[]) {
      diagnostics.add(d);
      if (d.code == 'grammar.unproductive_nonterminal') {
        unproductive.addAll(d.symbols);
      }
    }
  }

  final productiveGrammar = removeSymbols(grammar, unproductive);
  final reachableReport = GrammarAnalyzer.detectUnreachableNonTerminals(
    productiveGrammar,
  );
  final unreachable = <String>{};
  if (reachableReport.isSuccess) {
    for (final d
        in reachableReport.data?.diagnostics ?? const <GrammarDiagnostic>[]) {
      diagnostics.add(d);
      if (d.code == 'grammar.unreachable_nonterminal') {
        unreachable.addAll(d.symbols);
      }
    }
  }

  final toRemove = unproductive.union(unreachable);
  if (toRemove.isEmpty) {
    return _TransformResult(grammar: grammar, diagnostics: diagnostics);
  }
  final reducedGrammar = removeSymbols(productiveGrammar, unreachable);

  return _TransformResult(
    grammar: reducedGrammar,
    diagnostics: diagnostics,
    changedSymbols: toRemove,
    changedProductionIds: removedIds,
  );
}

_TransformResult _replaceTerminalsAndBinarize(
  Grammar grammar, {
  required int maxNewNonTerminals,
}) {
  final diagnostics = <GrammarDiagnostic>[];

  final usedSymbols = grammar.nonterminals.union(grammar.terminals);
  final terminalMap = <String, String>{};

  final nonterminals = {...grammar.nonterminals};
  final productions = <Production>{};

  String ensureTerminalAlias(String terminal) {
    final existing = terminalMap[terminal];
    if (existing != null) return existing;

    final base = 'T_${terminal.replaceAll(RegExp(r'[^a-zA-Z0-9]+'), '_')}';
    final fresh = GrammarCnfTransformer._freshNonTerminal(
      base: base,
      used: usedSymbols.union(nonterminals).union(terminalMap.values.toSet()),
    );
    if (fresh == null) {
      // Fallback to a random-ish name.
      final candidate = 'T_${terminal.hashCode.abs()}';
      terminalMap[terminal] = candidate;
      nonterminals.add(candidate);
      return candidate;
    }

    terminalMap[terminal] = fresh;
    nonterminals.add(fresh);
    return fresh;
  }

  final usedProductionIds = grammar.productions.map((p) => p.id).toSet();
  int nextId = 0;
  String freshProdId(String prefix) {
    while (usedProductionIds.contains('$prefix$nextId')) {
      nextId++;
    }
    final id = '$prefix$nextId';
    usedProductionIds.add(id);
    nextId++;
    return id;
  }

  // First pass: replace terminals in RHS length >= 2.
  for (final p in grammar.productions) {
    if (p.isLambda) {
      productions.add(p);
      continue;
    }

    if (p.rightSide.length < 2) {
      productions.add(p);
      continue;
    }

    final replaced = <String>[];
    for (final sym in p.rightSide) {
      if (grammar.terminals.contains(sym)) {
        final alias = ensureTerminalAlias(sym);
        replaced.add(alias);
      } else {
        replaced.add(sym);
      }
    }

    productions.add(p.copyWith(rightSide: replaced));
  }

  // Add terminal alias productions (A -> a).
  terminalMap.forEach((terminal, aliasNt) {
    productions.add(
      Production(
        id: freshProdId('t'),
        leftSide: [aliasNt],
        rightSide: [terminal],
      ),
    );
  });

  // Second pass: binarize productions longer than 2.
  final binarized = <Production>{};
  var emittedNewSymbolLimitDiagnostic = false;
  for (final p in productions) {
    if (p.isLambda || p.rightSide.length <= 2) {
      binarized.add(p);
      continue;
    }

    if (p.leftSide.length != 1) {
      // Keep as-is; not CFG-shape.
      binarized.add(p);
      continue;
    }

    final left = p.leftSide.first;
    final rhs = p.rightSide;

    var prevLeft = left;
    for (var i = 0; i < rhs.length - 2; i++) {
      if (nonterminals.length - grammar.nonterminals.length >
          maxNewNonTerminals) {
        if (!emittedNewSymbolLimitDiagnostic) {
          diagnostics.add(
            _cnfDiagnostic(
              code: 'cnf.new_symbol_limit_reached',
              message: GrammarCnfMessages.newSymbolLimitReached(
                maxNewNonTerminals,
              ),
            ),
          );
          emittedNewSymbolLimitDiagnostic = true;
        }
        // Keep the remaining production as-is.
        binarized.add(
          Production(
            id: p.id,
            leftSide: [prevLeft],
            rightSide: rhs.sublist(i),
            order: p.order,
          ),
        );
        prevLeft = '';
        break;
      }

      final freshNt = GrammarCnfTransformer._freshNonTerminal(
        base: 'X_${left}_$i',
        used: usedSymbols.union(nonterminals).union(grammar.terminals),
      );
      final nt =
          freshNt ??
          'X_${left}_${i}_${GrammarCnfTransformer._nextFallbackSuffix()}';
      nonterminals.add(nt);

      binarized.add(
        Production(
          id: freshProdId('b'),
          leftSide: [prevLeft],
          rightSide: [rhs[i], nt],
          order: p.order,
        ),
      );

      prevLeft = nt;
    }

    if (prevLeft.isNotEmpty) {
      binarized.add(
        Production(
          id: freshProdId('b'),
          leftSide: [prevLeft],
          rightSide: rhs.sublist(rhs.length - 2),
          order: p.order,
        ),
      );
    }
  }

  return _TransformResult(
    grammar: grammar.copyWith(
      nonterminals: nonterminals,
      productions: binarized,
      modified: DateTime.now(),
    ),
    diagnostics: diagnostics,
    changedSymbols: nonterminals.difference(grammar.nonterminals),
  );
}

List<String> _findCnfViolations(Grammar grammar) {
  final violations = <String>[];
  for (final p in grammar.productions) {
    if (p.leftSide.length != 1) {
      violations.add('${p.id}: LHS not single non-terminal');
      continue;
    }

    if (p.isLambda) {
      if (p.leftSide.first != grammar.startSymbol) {
        violations.add('${p.id}: ε-production not on start symbol');
      }
      continue;
    }

    if (p.rightSide.length == 1) {
      final sym = p.rightSide.first;
      if (!grammar.terminals.contains(sym)) {
        violations.add('${p.id}: A→a expected terminal');
      }
      continue;
    }

    if (p.rightSide.length == 2) {
      if (!grammar.nonterminals.contains(p.rightSide[0]) ||
          !grammar.nonterminals.contains(p.rightSide[1])) {
        violations.add('${p.id}: A→BC expected non-terminals');
      }
      continue;
    }

    violations.add('${p.id}: RHS length ${p.rightSide.length}');
  }
  return violations;
}

class _GrammarCnfInternals {
  static String derivedId(String base, String suffix) => '${base}_$suffix';

  static bool Function(String) isNullableSymbol(Set<String> nullable) {
    return (String sym) => nullable.contains(sym) || isEpsilonSymbol(sym);
  }

  static List<Set<int>> subsetsOfPositions(List<int> positions) {
    final subsets = <Set<int>>[{}];
    for (final pos in positions) {
      final current = List<Set<int>>.from(subsets);
      for (final s in current) {
        subsets.add({...s, pos});
      }
    }
    return subsets;
  }
}
