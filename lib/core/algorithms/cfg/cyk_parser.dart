//
//  cyk_parser.dart
//  Turing Lab
//
//  Implements the CYK algorithm for grammars in Chomsky Normal Form,
//  including CNF preparation, dynamic-programming table construction, and
//  optional derivation reconstruction. Handles the empty word, records
//  back-pointers, and returns structured results with a derivation tree
//  when the sentence is accepted.
//
//  Thales Matheus Mendonça Santos - October 2025
//
import '../../models/grammar.dart';
import '../../models/cyk_step.dart';
import '../../result.dart';
import '../grammar_cnf_transformer.dart';
import '../grammar_input_tokenizer.dart';

/// CYK parser for CFGs in CNF. Builds parse table and derivation tree.
class CYKParser {
  static Result<CYKResult> parse(
    Grammar g,
    String input, {
    Duration? timeout,
  }) {
    final stopwatch = Stopwatch()..start();

    Result<CYKResult>? timeoutFailure() {
      if (timeout != null && stopwatch.elapsed >= timeout) {
        return ResultFactory.failure('CYK parsing timed out');
      }
      return null;
    }

    try {
      final initialTimeout = timeoutFailure();
      if (initialTimeout != null) return initialTimeout;

      final tokenResult = GrammarInputTokenizer.tokenize(g, input);
      if (tokenResult.isFailure) {
        return ResultFactory.success(
          const CYKResult(accepted: false, table: [], derivation: null),
        );
      }
      final tokens = tokenResult.data!;

      // Handle empty string using nullable analysis (original grammar)
      if (tokens.isEmpty) {
        final acceptsEmpty = g.nullableNonterminals.contains(g.startSymbol);
        return ResultFactory.success(
          CYKResult(
            accepted: acceptsEmpty,
            table: const [],
            derivation:
                acceptsEmpty ? CYKDerivation.node(g.startSymbol, []) : null,
          ),
        );
      }

      // Convert to CNF for CYK (does not mutate original grammar)
      final cnfG = _toCnfForParsing(g);
      final conversionTimeout = timeoutFailure();
      if (conversionTimeout != null) return conversionTimeout;

      final n = tokens.length;
      final table = List.generate(
        n,
        (i) => List.generate(n, (j) => <String>{}),
      );
      final back = List.generate(
        n,
        (i) => List.generate(n, (j) => <String, CYKBackptr>{}),
      );

      // Precompute productions A→a and A→BC
      final unary = <String, Set<String>>{}; // a -> {A}
      final binary = <(String, String), Set<String>>{}; // (B,C) -> {A}
      for (final p in cnfG.productions) {
        final productionTimeout = timeoutFailure();
        if (productionTimeout != null) return productionTimeout;
        if (p.isLambda) continue;
        if (p.rightSide.length == 1 &&
            cnfG.terminals.contains(p.rightSide.first)) {
          final a = p.rightSide.first;
          (unary[a] ??= <String>{}).add(p.leftSide.first);
        } else if (p.rightSide.length == 2 &&
            cnfG.nonterminals.contains(p.rightSide[0]) &&
            cnfG.nonterminals.contains(p.rightSide[1])) {
          final key = (p.rightSide[0], p.rightSide[1]);
          (binary[key] ??= <String>{}).add(p.leftSide.first);
        }
      }

      // Fill length-1 substrings
      for (int i = 0; i < n; i++) {
        final baseTimeout = timeoutFailure();
        if (baseTimeout != null) return baseTimeout;
        final a = tokens[i].lexeme;
        for (final A in unary[a] ?? const <String>{}) {
          table[i][0].add(A);
          back[i][0][A] = CYKBackptr.leaf(a);
        }
      }

      // Fill longer substrings
      for (int len = 2; len <= n; len++) {
        final lengthTimeout = timeoutFailure();
        if (lengthTimeout != null) return lengthTimeout;
        for (int i = 0; i <= n - len; i++) {
          final j = len - 1; // column width
          for (int split = 1; split < len; split++) {
            final splitTimeout = timeoutFailure();
            if (splitTimeout != null) return splitTimeout;
            final leftWidth = split - 1;
            final rightWidth = len - split - 1;
            for (final B in table[i][leftWidth]) {
              final leftTimeout = timeoutFailure();
              if (leftTimeout != null) return leftTimeout;
              for (final C in table[i + split][rightWidth]) {
                final rightTimeout = timeoutFailure();
                if (rightTimeout != null) return rightTimeout;
                final candidates = binary[(B, C)];
                if (candidates == null) continue;
                for (final A in candidates) {
                  final candidateTimeout = timeoutFailure();
                  if (candidateTimeout != null) return candidateTimeout;
                  if (table[i][j].add(A)) {
                    back[i][j][A] = CYKBackptr.internal(
                      left: (i, leftWidth, B),
                      right: (i + split, rightWidth, C),
                    );
                  }
                }
              }
            }
          }
        }
      }

      final completedTableTimeout = timeoutFailure();
      if (completedTableTimeout != null) return completedTableTimeout;

      final accepted = table[0][n - 1].contains(cnfG.startSymbol);
      CYKDerivation? tree;
      if (accepted) {
        final derivationStartTimeout = timeoutFailure();
        if (derivationStartTimeout != null) return derivationStartTimeout;
        tree = _buildTree(back, 0, n - 1, cnfG.startSymbol);
        final derivationTimeout = timeoutFailure();
        if (derivationTimeout != null) return derivationTimeout;
      }

      final resultAssemblyTimeout = timeoutFailure();
      if (resultAssemblyTimeout != null) return resultAssemblyTimeout;
      return ResultFactory.success(
        CYKResult(accepted: accepted, table: table, derivation: tree),
      );
    } catch (e) {
      return ResultFactory.failure('CYK parse error: $e');
    }
  }

  /// Parses a string with step-by-step information
  static Result<CYKParseResult> parseWithSteps(
    Grammar g,
    String input, {
    Duration? timeout,
  }) {
    final stopwatch = Stopwatch()..start();

    Result<CYKParseResult>? timeoutFailure() {
      if (timeout != null && stopwatch.elapsed >= timeout) {
        return ResultFactory.failure('CYK parsing timed out');
      }
      return null;
    }

    try {
      final initialTimeout = timeoutFailure();
      if (initialTimeout != null) return initialTimeout;

      final tokenResult = GrammarInputTokenizer.tokenize(g, input);
      if (tokenResult.isFailure) {
        stopwatch.stop();
        return ResultFactory.success(
          CYKParseResult(
            accepted: false,
            table: const [],
            derivation: null,
            steps: const [],
            executionTime: stopwatch.elapsed,
          ),
        );
      }
      final tokens = tokenResult.data!;

      final steps = <CYKStep>[];
      int stepCounter = 1;

      // Handle empty string using nullable analysis (original grammar)
      if (tokens.isEmpty) {
        final acceptsEmpty = g.nullableNonterminals.contains(g.startSymbol);
        steps.add(
          CYKStep.initialize(
            id: 'step_$stepCounter',
            stepNumber: stepCounter++,
            inputString: input,
            tableSize: 0,
          ),
        );
        steps.add(
          CYKStep.checkAcceptance(
            id: 'step_$stepCounter',
            stepNumber: stepCounter++,
            inputString: input,
            startSymbol: g.startSymbol,
            finalCellNonTerminals: acceptsEmpty ? {g.startSymbol} : {},
            isAccepted: acceptsEmpty,
          ),
        );

        stopwatch.stop();
        return ResultFactory.success(
          CYKParseResult(
            accepted: acceptsEmpty,
            table: const [],
            derivation:
                acceptsEmpty ? CYKDerivation.node(g.startSymbol, []) : null,
            steps: steps,
            executionTime: stopwatch.elapsed,
          ),
        );
      }

      // Convert to CNF for CYK (does not mutate original grammar)
      final cnfG = _toCnfForParsing(g);
      final conversionTimeout = timeoutFailure();
      if (conversionTimeout != null) return conversionTimeout;

      final n = tokens.length;
      final table = List.generate(
        n,
        (i) => List.generate(n, (j) => <String>{}),
      );
      final back = List.generate(
        n,
        (i) => List.generate(n, (j) => <String, CYKBackptr>{}),
      );

      // Capture initialization step
      steps.add(
        CYKStep.initialize(
          id: 'step_$stepCounter',
          stepNumber: stepCounter++,
          inputString: input,
          tableSize: n,
        ),
      );

      // Precompute productions A→a and A→BC
      final unary = <String, Set<String>>{}; // a -> {A}
      final binary = <(String, String), Set<String>>{}; // (B,C) -> {A}
      for (final p in cnfG.productions) {
        final productionTimeout = timeoutFailure();
        if (productionTimeout != null) return productionTimeout;
        if (p.isLambda) continue;
        if (p.rightSide.length == 1 &&
            cnfG.terminals.contains(p.rightSide.first)) {
          final a = p.rightSide.first;
          (unary[a] ??= <String>{}).add(p.leftSide.first);
        } else if (p.rightSide.length == 2 &&
            cnfG.nonterminals.contains(p.rightSide[0]) &&
            cnfG.nonterminals.contains(p.rightSide[1])) {
          final key = (p.rightSide[0], p.rightSide[1]);
          (binary[key] ??= <String>{}).add(p.leftSide.first);
        }
      }

      // Fill length-1 substrings
      for (int i = 0; i < n; i++) {
        final baseTimeout = timeoutFailure();
        if (baseTimeout != null) return baseTimeout;
        final a = tokens[i].lexeme;
        final derivingVars = unary[a] ?? const <String>{};
        for (final A in derivingVars) {
          table[i][0].add(A);
          back[i][0][A] = CYKBackptr.leaf(a);
        }

        // Capture base case step
        steps.add(
          CYKStep.fillBaseCase(
            id: 'step_$stepCounter',
            stepNumber: stepCounter++,
            position: i,
            terminal: a,
            derivingVariables: Set.from(derivingVars),
          ),
        );
      }

      // Fill longer substrings
      for (int len = 2; len <= n; len++) {
        final lengthTimeout = timeoutFailure();
        if (lengthTimeout != null) return lengthTimeout;
        for (int i = 0; i <= n - len; i++) {
          final cellTimeout = timeoutFailure();
          if (cellTimeout != null) return cellTimeout;
          final j = len - 1; // column width
          final substring =
              tokens.sublist(i, i + len).map((token) => token.lexeme).join();

          // Capture process cell step
          steps.add(
            CYKStep.processCell(
              id: 'step_$stepCounter',
              stepNumber: stepCounter++,
              row: j,
              col: i,
              substring: substring,
              length: len,
            ),
          );

          for (int split = 1; split < len; split++) {
            final splitTimeout = timeoutFailure();
            if (splitTimeout != null) return splitTimeout;
            final leftWidth = split - 1;
            final rightWidth = len - split - 1;
            final leftNTs = Set<String>.from(table[i][leftWidth]);
            final rightNTs = Set<String>.from(table[i + split][rightWidth]);
            final leftSubstring = tokens
                .sublist(i, i + split)
                .map((token) => token.lexeme)
                .join();
            final rightSubstring = tokens
                .sublist(i + split, i + len)
                .map((token) => token.lexeme)
                .join();

            // Capture check split step
            steps.add(
              CYKStep.checkSplit(
                id: 'step_$stepCounter',
                stepNumber: stepCounter++,
                row: j,
                col: i,
                substring: substring,
                substringLength: len,
                splitPoint: split - 1,
                leftSubstring: leftSubstring,
                rightSubstring: rightSubstring,
                leftRow: leftWidth,
                leftCol: i,
                rightRow: rightWidth,
                rightCol: i + split,
                leftNonTerminals: leftNTs,
                rightNonTerminals: rightNTs,
              ),
            );

            for (final B in table[i][leftWidth]) {
              final leftTimeout = timeoutFailure();
              if (leftTimeout != null) return leftTimeout;
              for (final C in table[i + split][rightWidth]) {
                final rightTimeout = timeoutFailure();
                if (rightTimeout != null) return rightTimeout;
                final candidates = binary[(B, C)];
                if (candidates == null) continue;
                for (final A in candidates) {
                  final candidateTimeout = timeoutFailure();
                  if (candidateTimeout != null) return candidateTimeout;
                  if (table[i][j].add(A)) {
                    back[i][j][A] = CYKBackptr.internal(
                      left: (i, leftWidth, B),
                      right: (i + split, rightWidth, C),
                    );

                    // Capture apply production step
                    steps.add(
                      CYKStep.applyProduction(
                        id: 'step_$stepCounter',
                        stepNumber: stepCounter++,
                        row: j,
                        col: i,
                        variable: A,
                        leftVar: B,
                        rightVar: C,
                        substring: substring,
                        substringLength: len,
                      ),
                    );
                  }
                }
              }
            }
          }

          // Capture complete cell step
          steps.add(
            CYKStep.completeCell(
              id: 'step_$stepCounter',
              stepNumber: stepCounter++,
              row: j,
              col: i,
              substring: substring,
              substringLength: len,
              cellNonTerminals: Set.from(table[i][j]),
            ),
          );
        }
      }

      final completedTableTimeout = timeoutFailure();
      if (completedTableTimeout != null) return completedTableTimeout;

      final accepted = table[0][n - 1].contains(cnfG.startSymbol);
      CYKDerivation? tree;
      if (accepted) {
        final derivationStartTimeout = timeoutFailure();
        if (derivationStartTimeout != null) return derivationStartTimeout;
        tree = _buildTree(back, 0, n - 1, cnfG.startSymbol);
        final derivationTimeout = timeoutFailure();
        if (derivationTimeout != null) return derivationTimeout;
      }

      final acceptanceStepTimeout = timeoutFailure();
      if (acceptanceStepTimeout != null) return acceptanceStepTimeout;

      // Capture check acceptance step
      steps.add(
        CYKStep.checkAcceptance(
          id: 'step_$stepCounter',
          stepNumber: stepCounter++,
          inputString: input,
          startSymbol: cnfG.startSymbol,
          finalCellNonTerminals: Set.from(table[0][n - 1]),
          isAccepted: accepted,
        ),
      );

      final completionStepTimeout = timeoutFailure();
      if (completionStepTimeout != null) return completionStepTimeout;

      // Capture completion step
      final totalCells = (n * (n + 1)) ~/ 2;
      steps.add(
        CYKStep.completion(
          id: 'step_$stepCounter',
          stepNumber: stepCounter,
          inputString: input,
          isAccepted: accepted,
          totalCells: totalCells,
          filledCells: totalCells,
        ),
      );

      final resultAssemblyTimeout = timeoutFailure();
      if (resultAssemblyTimeout != null) return resultAssemblyTimeout;

      stopwatch.stop();
      return ResultFactory.success(
        CYKParseResult(
          accepted: accepted,
          table: table,
          derivation: tree,
          steps: steps,
          executionTime: stopwatch.elapsed,
        ),
      );
    } catch (e) {
      return ResultFactory.failure('CYK parse error: $e');
    }
  }

  static CYKDerivation _buildTree(
    List<List<Map<String, CYKBackptr>>> back,
    int i,
    int j,
    String A,
  ) {
    final bp = back[i][j][A];
    if (bp == null) return CYKDerivation.node(A, []);
    if (bp.isLeaf) {
      return CYKDerivation.node(A, [CYKDerivation.leaf(bp.leafSymbol!)]);
    }
    final (li, lj, B) = bp.left!;
    final (ri, rj, C) = bp.right!;
    return CYKDerivation.node(A, [
      _buildTree(back, li, lj, B),
      _buildTree(back, ri, rj, C),
    ]);
  }

  static Grammar _toCnfForParsing(Grammar grammar) {
    final result = GrammarCnfTransformer.toCnf(grammar);
    final report = result.data;
    if (report == null) {
      throw StateError(result.error ?? 'CNF conversion failed');
    }
    return report.grammar;
  }
}

class CYKResult {
  final bool accepted;
  final List<List<Set<String>>>
      table; // upper triangular table; table[i][len-1]
  final CYKDerivation? derivation;
  final List<CYKStep>? steps;
  const CYKResult({
    required this.accepted,
    required this.table,
    required this.derivation,
    this.steps,
  });
}

class CYKDerivation {
  final String label; // nonterminal or terminal
  final List<CYKDerivation> children;
  const CYKDerivation._(this.label, this.children);
  factory CYKDerivation.node(String nt, List<CYKDerivation> children) =>
      CYKDerivation._(nt, children);
  factory CYKDerivation.leaf(String t) => CYKDerivation._(t, const []);
  bool get isLeaf => children.isEmpty;
}

class CYKBackptr {
  final bool isLeaf;
  final String? leafSymbol; // terminal
  final (int, int, String)? left; // (i, j, B)
  final (int, int, String)? right; // (i, j, C)
  const CYKBackptr._(this.isLeaf, this.leafSymbol, this.left, this.right);
  factory CYKBackptr.leaf(String a) => CYKBackptr._(true, a, null, null);
  factory CYKBackptr.internal({
    required (int, int, String) left,
    required (int, int, String) right,
  }) =>
      CYKBackptr._(false, null, left, right);
}

/// Result of CYK parsing with step-by-step information
class CYKParseResult {
  /// Whether the input string is accepted
  final bool accepted;

  /// Parse table
  final List<List<Set<String>>> table;

  /// Derivation tree (if accepted)
  final CYKDerivation? derivation;

  /// Detailed parsing steps
  final List<CYKStep> steps;

  /// Execution time
  final Duration executionTime;

  const CYKParseResult({
    required this.accepted,
    required this.table,
    required this.derivation,
    required this.steps,
    required this.executionTime,
  });

  /// Gets the number of steps
  int get stepCount => steps.length;

  /// Gets the first step
  CYKStep? get firstStep => steps.isNotEmpty ? steps.first : null;

  /// Gets the last step
  CYKStep? get lastStep => steps.isNotEmpty ? steps.last : null;

  /// Gets the execution time in milliseconds
  int get executionTimeMs => executionTime.inMilliseconds;
}
