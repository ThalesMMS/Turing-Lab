//
//  grammar_parser.dart
//  Turing Lab
//
//  Coordinates parsing strategies for context-free grammars, including
//  fast heuristics for Dyck grammars, general recognition via Earley,
//  and derivation with recursive analysis. Validates input, selects
//  approaches from hints, and wraps rich results in `ParseResult`.
//
//  Thales Matheus Mendonça Santos - October 2025
//
import '../models/derivation_tree.dart';
import '../models/brute_force_parse_models.dart';
import '../models/derivation_tree_node.dart';
import '../models/grammar.dart';
import '../models/grammar_parse_report.dart';
import '../models/ll1_parse_step.dart';
import '../models/lr1_models.dart';
import '../messages/structured_message.dart';
import '../result.dart';
import 'cfg/cyk_parser.dart';
import 'brute_force_cfg_parser.dart';
import 'grammar_analyzer.dart';
import 'grammar_input_tokenizer.dart';
import 'lr1_parser.dart';
import 'grammar_parser_simple_recursive.dart';
import 'grammar_parser_earley.dart';
import 'grammar_parser_messages.dart';

/// Parses strings using context-free grammars
enum ParsingStrategyHint { auto, bruteForce, cyk, ll, lr }

class GrammarParserCapability {
  const GrammarParserCapability({
    required this.strategy,
    required this.label,
    required this.isAvailable,
    this.unavailableReason,
  });

  final ParsingStrategyHint strategy;
  final String label;
  final bool isAvailable;
  final String? unavailableReason;
}

typedef _ParsingStrategy =
    ParseResult? Function(
      Grammar grammar,
      String inputString,
      Duration timeout,
    );

class GrammarParser {
  static const capabilities = <GrammarParserCapability>[
    GrammarParserCapability(
      strategy: ParsingStrategyHint.auto,
      label: 'Automatic (Earley)',
      isAvailable: true,
    ),
    GrammarParserCapability(
      strategy: ParsingStrategyHint.bruteForce,
      label: 'Brute force',
      isAvailable: true,
    ),
    GrammarParserCapability(
      strategy: ParsingStrategyHint.cyk,
      label: 'CYK (Cocke-Younger-Kasami)',
      isAvailable: true,
    ),
    GrammarParserCapability(
      strategy: ParsingStrategyHint.ll,
      label: 'LL(1)',
      isAvailable: true,
    ),
    GrammarParserCapability(
      strategy: ParsingStrategyHint.lr,
      label: 'Canonical LR(1)',
      isAvailable: true,
    ),
  ];

  static GrammarParserCapability capabilityFor(ParsingStrategyHint strategy) {
    return capabilities.firstWhere(
      (capability) => capability.strategy == strategy,
      orElse: () => throw ArgumentError.value(
        strategy,
        'strategy',
        'No parser capability is registered',
      ),
    );
  }

  /// Parses a string using a grammar (legacy API).
  static Result<ParseResult> parse(
    Grammar grammar,
    String inputString, {
    Duration timeout = const Duration(seconds: 5),
    ParsingStrategyHint strategyHint = ParsingStrategyHint.auto,
  }) {
    if (strategyHint == ParsingStrategyHint.ll) {
      return parseLL1(grammar, inputString, timeout: timeout);
    }

    // Legacy strategies retain their existing Result failure contract.
    // Validate input (symbols and basic invariants)
    final validation = _validateInput(grammar, inputString);
    if (!validation.isSuccess) {
      return Failure(
        validation.error!,
        structuredMessage: validation.structuredError,
      );
    }

    final capability = capabilityFor(strategyHint);
    if (!capability.isAvailable) {
      return Failure(capability.unavailableReason!);
    }

    if (strategyHint != ParsingStrategyHint.auto) {
      return Success(
        _parseString(
          grammar,
          inputString,
          timeout,
          _resolveStrategies(strategyHint),
          strategyHint,
        ),
      );
    }

    // First, decide acceptance robustly with Earley
    // Fast path: detect Dyck-1 grammar (balanced single-type brackets) and
    // recognize in linear time to handle very long inputs efficiently.
    final dyckDelims = _detectDyck1Delimiters(grammar);
    if (dyckDelims != null) {
      final open = dyckDelims.item1;
      final close = dyckDelims.item2;

      // Ensure grammar uses only these two terminals for safety
      final onlyDyckTerminals =
          grammar.terminals.length == 2 &&
          grammar.terminals.contains(open) &&
          grammar.terminals.contains(close);
      if (onlyDyckTerminals) {
        final dyckAccepted = _fastDyck1Recognize(
          grammar,
          inputString,
          open,
          close,
        );
        if (!dyckAccepted) {
          final message = GrammarParserMessages.inputRejected(inputString);
          return Success(
            ParseResult.failure(
              inputString: inputString,
              errorMessage:
                  'String "$inputString" cannot be derived from grammar',
              structuredMessage: message,
              executionTime: const Duration(),
            ),
          );
        }
        // Accepted via fast path; build a source-grammar witness when the
        // remaining budget allows it without slowing recognition itself.
        final derivation = _bestEffortAutoParse(grammar, inputString, timeout);
        if (derivation != null) return Success(derivation);
        return Success(
          ParseResult.success(
            inputString: inputString,
            derivations: const <List<String>>[],
            executionTime: const Duration(),
          ),
        );
      }
    }

    // Fall back to Earley general recognizer
    final earley = EarleyRecognizer(grammar);
    final accepted = earley.recognizes(inputString, timeout: timeout);
    if (!accepted) {
      // Return a successful result object with accepted=false so callers can
      // assert on acceptance without treating it as an exceptional failure
      final message = GrammarParserMessages.inputRejected(inputString);
      return Success(
        ParseResult.failure(
          inputString: inputString,
          errorMessage: 'String "$inputString" cannot be derived from grammar',
          structuredMessage: message,
          executionTime: const Duration(),
        ),
      );
    }

    // If accepted, build a derivation best-effort. Recursive descent is fast
    // for suitable grammars; bounded brute force covers left-recursive ones.
    final derivation = _bestEffortAutoParse(grammar, inputString, timeout);
    if (derivation != null) return Success(derivation);

    // Fallback: accepted without a derivation trace
    return Success(
      ParseResult.success(
        inputString: inputString,
        derivations: const <List<String>>[],
        executionTime: const Duration(),
      ),
    );
  }

  /// Parses a string using a grammar and returns a structured parse report.
  static Result<GrammarParseReport> parseWithReport(
    Grammar grammar,
    String inputString, {
    Duration timeout = const Duration(seconds: 5),
    int maxTrees = 3,
    int maxSteps = 100000,
    int maxStates = 10000,
    int maxItems = 100000,
    bool Function()? isCancelled,
    ParsingStrategyHint strategyHint = ParsingStrategyHint.auto,
  }) {
    final startTime = DateTime.now();

    if (strategyHint == ParsingStrategyHint.ll) {
      final result = parseLL1(
        grammar,
        inputString,
        timeout: timeout,
        maxSteps: maxSteps,
        isCancelled: isCancelled,
      ).data!;
      final elapsed = DateTime.now().difference(startTime);
      if (!result.accepted) {
        return Success(
          GrammarParseReport.rejected(
            inputString: inputString,
            farthestPosition: result.farthestPosition,
            expectedSymbols: result.expectedSymbols,
            message: result.errorMessage,
            executionTime: elapsed,
            ll1Steps: result.ll1Steps,
            lr1Steps: result.lr1Steps,
            bruteForceResult: result.bruteForceResult,
            structuredMessage: result.structuredMessage,
            outcome: result.outcome,
          ),
        );
      }
      return Success(
        GrammarParseReport.accepted(
          inputString: inputString,
          executionTime: elapsed,
          ll1Steps: result.ll1Steps,
        ),
      );
    }

    // Validate input (symbols and basic invariants)
    final validation = _validateInput(grammar, inputString);
    if (!validation.isSuccess) {
      return Failure(
        validation.error!,
        structuredMessage: validation.structuredError,
      );
    }

    final capability = capabilityFor(strategyHint);
    if (!capability.isAvailable) {
      return Failure(capability.unavailableReason!);
    }

    if (strategyHint != ParsingStrategyHint.auto) {
      final result = strategyHint == ParsingStrategyHint.lr
          ? _parseWithLR1(
              grammar,
              inputString,
              timeout,
              maxSteps: maxSteps,
              maxStates: maxStates,
              maxItems: maxItems,
              isCancelled: isCancelled,
            )!
          : _parseString(
              grammar,
              inputString,
              timeout,
              _resolveStrategies(strategyHint),
              strategyHint,
            );
      final elapsed = DateTime.now().difference(startTime);
      if (!result.accepted) {
        return Success(
          GrammarParseReport.rejected(
            inputString: inputString,
            farthestPosition: result.farthestPosition,
            expectedSymbols: result.expectedSymbols,
            message:
                result.errorMessage ??
                'String "$inputString" cannot be derived from grammar',
            structuredMessage: result.structuredMessage,
            executionTime: elapsed,
            ll1Steps: result.ll1Steps,
            lr1Steps: result.lr1Steps,
            bruteForceResult: result.bruteForceResult,
            outcome: result.outcome,
          ),
        );
      }

      final bruteTrees =
          result.bruteForceResult?.witnesses
              .map((witness) => witness.tree)
              .toList(growable: false) ??
          const <DerivationTree>[];
      final allTrees = bruteTrees.isNotEmpty
          ? bruteTrees
          : result.tree == null
          ? _treesFromDerivations(result.derivations, inputString)
          : <DerivationTree>[result.tree!];
      return Success(
        GrammarParseReport.accepted(
          inputString: inputString,
          executionTime: elapsed,
          trees: allTrees.take(maxTrees).toList(growable: false),
          isAmbiguous:
              (result.bruteForceResult?.witnessCount ?? 0) > 1 ||
              allTrees.length > maxTrees,
          ll1Steps: result.ll1Steps,
          lr1Steps: result.lr1Steps,
          bruteForceResult: result.bruteForceResult,
          structuredMessage: result.structuredMessage,
        ),
      );
    }

    // Dyck-1 fast path (accept/reject only; no trees) for auto mode.
    final dyckDelims = _detectDyck1Delimiters(grammar);
    if (dyckDelims != null) {
      final open = dyckDelims.item1;
      final close = dyckDelims.item2;

      final onlyDyckTerminals =
          grammar.terminals.length == 2 &&
          grammar.terminals.contains(open) &&
          grammar.terminals.contains(close);

      if (onlyDyckTerminals) {
        final accepted = _fastDyck1Recognize(grammar, inputString, open, close);
        final elapsed = DateTime.now().difference(startTime);
        if (!accepted) {
          final message = GrammarParserMessages.inputRejected(inputString);
          return Success(
            GrammarParseReport.rejected(
              inputString: inputString,
              farthestPosition: 0,
              expectedSymbols: {open},
              message: 'String "$inputString" cannot be derived from grammar',
              executionTime: elapsed,
              structuredMessage: message,
            ),
          );
        }
        final remaining = timeout - DateTime.now().difference(startTime);
        final derivation = remaining <= Duration.zero
            ? null
            : _bestEffortAutoParse(grammar, inputString, remaining);
        if (derivation != null) {
          final trees = _treesForParseResult(derivation);
          return Success(
            GrammarParseReport.accepted(
              inputString: inputString,
              executionTime: DateTime.now().difference(startTime),
              trees: trees.take(maxTrees).toList(growable: false),
              isAmbiguous: (derivation.bruteForceResult?.witnessCount ?? 0) > 1,
            ),
          );
        }
        return Success(
          GrammarParseReport.accepted(
            inputString: inputString,
            executionTime: elapsed,
          ),
        );
      }
    }

    // Robust acceptance via Earley.
    final earley = EarleyRecognizer(grammar);
    final earleyReport = earley.recognizeWithReport(
      inputString,
      timeout: timeout,
    );
    if (!earleyReport.accepted) {
      if (earleyReport.message?.startsWith('Parse timed out') ?? false) {
        return Success(
          GrammarParseReport.rejected(
            inputString: earleyReport.inputString,
            farthestPosition: earleyReport.farthestPosition,
            expectedSymbols: earleyReport.expectedSymbols,
            message: earleyReport.message,
            executionTime: earleyReport.executionTime,
            structuredMessage: earleyReport.structuredMessage,
            outcome: GrammarParseOutcome.timedOut,
          ),
        );
      }
      return Success(earleyReport);
    }

    // Best-effort tree via recursive descent, with a bounded fallback for
    // accepted grammars that contain left recursion.
    final result = _bestEffortAutoParse(grammar, inputString, timeout);
    if (result != null) {
      final allTrees = _treesForParseResult(result);
      return Success(
        GrammarParseReport.accepted(
          inputString: inputString,
          executionTime: DateTime.now().difference(startTime),
          trees: allTrees.take(maxTrees).toList(growable: false),
          isAmbiguous:
              (result.bruteForceResult?.witnessCount ?? 0) > 1 ||
              allTrees.length > maxTrees,
        ),
      );
    }

    return Success(
      GrammarParseReport.accepted(
        inputString: inputString,
        executionTime: DateTime.now().difference(startTime),
      ),
    );
  }

  /// Runs only the predictive parser with explicit cancellation and work bounds.
  static Result<ParseResult> parseLL1(
    Grammar grammar,
    String inputString, {
    Duration timeout = const Duration(seconds: 5),
    int maxSteps = 100000,
    bool Function()? isCancelled,
  }) {
    final grammarValidation = _validateGrammar(grammar);
    if (!grammarValidation.isSuccess) {
      return Success(
        ParseResult.failure(
          inputString: inputString,
          errorMessage: grammarValidation.error!,
          structuredMessage: grammarValidation.structuredError,
          executionTime: Duration.zero,
          outcome: GrammarParseOutcome.invalidInput,
        ),
      );
    }
    final tokenization = GrammarInputTokenizer.tokenize(grammar, inputString);
    if (tokenization.isFailure) {
      return Success(
        ParseResult.failure(
          inputString: inputString,
          errorMessage: tokenization.error!,
          structuredMessage: tokenization.structuredError,
          executionTime: Duration.zero,
          outcome: GrammarParseOutcome.tokenizationFailure,
        ),
      );
    }
    if (maxSteps <= 0) {
      final message = GrammarParserMessages.ll1StepLimitInvalid(maxSteps);
      return Success(
        ParseResult.failure(
          inputString: inputString,
          errorMessage: 'The LL(1) step limit must be greater than zero.',
          structuredMessage: message,
          executionTime: Duration.zero,
          outcome: GrammarParseOutcome.stepLimit,
        ),
      );
    }
    return Success(
      _parseWithLL1(
        grammar,
        inputString,
        timeout,
        maxSteps: maxSteps,
        isCancelled: isCancelled,
      )!,
    );
  }

  static List<DerivationTree> _treesFromDerivations(
    List<List<String>> derivations,
    String inputString,
  ) {
    final out = <DerivationTree>[];
    for (final derivation in derivations) {
      if (derivation.isEmpty) continue;
      // The legacy derivation format is a flat list [LHS, ...expansion].
      final root = DerivationTreeNode(
        symbol: derivation.first,
        children: derivation.length == 1
            ? const <DerivationTreeNode>[]
            : derivation
                  .skip(1)
                  .map(
                    (s) => DerivationTreeNode(
                      symbol: s,
                      children: const <DerivationTreeNode>[],
                      // no reliable span info from this parser
                      lexeme: null,
                      start: null,
                      end: null,
                    ),
                  )
                  .toList(growable: false),
        lexeme: null,
        start: null,
        end: null,
      );
      out.add(DerivationTree(root: root, isShallow: true));
    }
    return out;
  }

  static List<DerivationTree> _treesForParseResult(ParseResult result) {
    final bruteTrees =
        result.bruteForceResult?.witnesses
            .map((witness) => witness.tree)
            .toList(growable: false) ??
        const <DerivationTree>[];
    if (bruteTrees.isNotEmpty) return bruteTrees;
    if (result.tree != null) return [result.tree!];
    return _treesFromDerivations(result.derivations, result.inputString);
  }

  /// Converts a CYK back-pointer tree to an original-grammar tree.
  ///
  /// CYK operates on a CNF copy, which can contain synthetic start symbols,
  /// terminal aliases, and binarization nodes. Those nodes are useful for the
  /// algorithm but are not valid productions in the grammar shown to the
  /// learner. If the normalized tree is not directly valid for the source
  /// grammar, use the bounded CFG search only to recover one source-grammar
  /// witness for presentation.
  static DerivationTree? treeFromCykDerivation(
    Grammar grammar,
    String inputString,
    CYKDerivation? derivation, {
    Duration timeout = const Duration(seconds: 5),
  }) {
    if (derivation == null) return null;
    final normalizedTree = derivation.toDerivationTree();
    if (_treeMatchesGrammar(grammar, normalizedTree.root)) {
      return normalizedTree;
    }

    if (timeout <= Duration.zero) return null;
    final sourceResult = BruteForceCFGParser.search(
      grammar,
      inputString,
      limits: BruteForceSearchLimits(resultCap: 1, timeLimit: timeout),
    );
    if (sourceResult.accepted && sourceResult.witnesses.isNotEmpty) {
      return sourceResult.witnesses.first.tree;
    }
    return null;
  }

  static bool _treeMatchesGrammar(Grammar grammar, DerivationTreeNode node) {
    if (node.symbol == 'ε') return node.children.isEmpty;
    if (grammar.terminals.contains(node.symbol)) {
      return node.children.isEmpty;
    }
    if (!grammar.nonterminals.contains(node.symbol)) return false;

    final childSymbols = node.children.map((child) => child.symbol).toList();
    final matchesProduction = grammar.productions
        .where(
          (production) =>
              production.leftSide.length == 1 &&
              production.leftSide.single == node.symbol,
        )
        .any((production) {
          final rightSide = production.isLambda
              ? const ['ε']
              : production.rightSide;
          return _sameSymbols(childSymbols, rightSide);
        });
    if (!matchesProduction) return false;
    return node.children.every((child) => _treeMatchesGrammar(grammar, child));
  }

  static bool _sameSymbols(List<String> left, List<String> right) {
    if (left.length != right.length) return false;
    for (var index = 0; index < left.length; index++) {
      if (left[index] != right[index]) return false;
    }
    return true;
  }

  static ParseResult? _bestEffortAutoParse(
    Grammar grammar,
    String inputString,
    Duration timeout,
  ) {
    final startedAt = DateTime.now();
    final recursive = SimpleRecursiveDescentParser(
      grammar,
    ).parse(inputString, timeout: timeout);
    if (recursive.isSuccess && recursive.data!.accepted) {
      return recursive.data!;
    }

    final remaining = timeout - DateTime.now().difference(startedAt);
    if (remaining <= Duration.zero) return null;

    final brute = _parseWithBruteForce(grammar, inputString, remaining);
    if (brute?.accepted ?? false) return brute;
    return null;
  }

  /// Validates the input grammar and string
  static Result<void> _validateInput(Grammar grammar, String inputString) {
    final grammarValidation = _validateGrammar(grammar);
    if (grammarValidation.isFailure) return grammarValidation;

    final tokens = GrammarInputTokenizer.tokenize(grammar, inputString);
    if (tokens.isFailure) {
      return Failure(tokens.error!, structuredMessage: tokens.structuredError);
    }

    return const Success(null);
  }

  static Result<void> _validateGrammar(Grammar grammar) {
    if (grammar.productions.isEmpty) {
      final message = GrammarParserMessages.emptyGrammar();
      return Failure(
        'Grammar must have at least one production',
        structuredMessage: message,
      );
    }

    if (grammar.startSymbol.isEmpty) {
      final message = GrammarParserMessages.missingStartSymbol();
      return Failure(
        'Grammar must have a start symbol',
        structuredMessage: message,
      );
    }

    if (!grammar.nonTerminals.contains(grammar.startSymbol)) {
      final message = GrammarParserMessages.startSymbolNotNonterminal();
      return Failure(
        'Start symbol must be a non-terminal',
        structuredMessage: message,
      );
    }

    return const Success(null);
  }

  /// Parses the string using the grammar
  static ParseResult _parseString(
    Grammar grammar,
    String inputString,
    Duration timeout,
    List<_ParsingStrategy> strategies,
    ParsingStrategyHint strategyHint,
  ) {
    final startTime = DateTime.now();

    for (final strategy in strategies) {
      try {
        final result = strategy(grammar, inputString, timeout);
        if (result != null) {
          return result.copyWith(
            executionTime: DateTime.now().difference(startTime),
          );
        }
      } catch (e) {
        // Try next strategy
        continue;
      }
    }

    // If all strategies fail, return failure
    final failureMessage = strategyHint == ParsingStrategyHint.auto
        ? 'All parsing strategies failed'
        : 'Parsing using the ${_strategyDisplayName(strategyHint)} parser failed';
    final structuredMessage = GrammarParserMessages.allStrategiesFailed(
      strategyHint.name,
    );
    return ParseResult.failure(
      inputString: inputString,
      errorMessage: failureMessage,
      structuredMessage: structuredMessage,
      executionTime: DateTime.now().difference(startTime),
    );
  }

  static List<_ParsingStrategy> _resolveStrategies(ParsingStrategyHint hint) {
    switch (hint) {
      case ParsingStrategyHint.bruteForce:
        return [_parseWithBruteForce];
      case ParsingStrategyHint.cyk:
        return [_parseWithCYK];
      case ParsingStrategyHint.ll:
        return [_parseWithLL1];
      case ParsingStrategyHint.lr:
        return [_parseWithLR1];
      case ParsingStrategyHint.auto:
        return [_parseWithBruteForce, _parseWithCYK];
    }
  }

  static String _strategyDisplayName(ParsingStrategyHint hint) {
    switch (hint) {
      case ParsingStrategyHint.bruteForce:
        return 'brute force';
      case ParsingStrategyHint.cyk:
        return 'CYK';
      case ParsingStrategyHint.ll:
        return 'LL';
      case ParsingStrategyHint.lr:
        return 'LR';
      case ParsingStrategyHint.auto:
        return 'auto';
    }
  }

  static ParseResult? _parseWithLR1(
    Grammar grammar,
    String inputString,
    Duration timeout, {
    int maxSteps = 100000,
    int maxStates = 10000,
    int maxItems = 100000,
    bool Function()? isCancelled,
  }) {
    final result = LR1Parser.parse(
      grammar,
      inputString,
      maxSteps: maxSteps,
      maxStates: maxStates,
      maxItems: maxItems,
      timeout: timeout,
      isCancelled: isCancelled,
    );
    final outcome = switch (result.outcome) {
      LR1ParseOutcome.accepted => GrammarParseOutcome.accepted,
      LR1ParseOutcome.rejected => GrammarParseOutcome.rejected,
      LR1ParseOutcome.invalidGrammar ||
      LR1ParseOutcome.tableConstructionFailure =>
        GrammarParseOutcome.invalidInput,
      LR1ParseOutcome.tokenizationFailure =>
        GrammarParseOutcome.tokenizationFailure,
      LR1ParseOutcome.conflict => GrammarParseOutcome.conflict,
      LR1ParseOutcome.cancelled => GrammarParseOutcome.cancelled,
      LR1ParseOutcome.timedOut => GrammarParseOutcome.timedOut,
      LR1ParseOutcome.resourceLimit => GrammarParseOutcome.stepLimit,
    };
    if (result.accepted) {
      return ParseResult.success(
        inputString: inputString,
        derivations: const <List<String>>[],
        executionTime: result.executionTime,
        farthestPosition: result.farthestPosition,
        lr1Steps: result.steps,
        tree: result.tree,
      );
    }
    return ParseResult.failure(
      inputString: inputString,
      errorMessage: result.message ?? 'Canonical LR(1) parsing failed.',
      executionTime: result.executionTime,
      farthestPosition: result.farthestPosition,
      expectedSymbols: result.expectedTerminals,
      lr1Steps: result.steps,
      structuredMessage: result.structuredMessage,
      outcome: outcome,
    );
  }

  /// Detects if the grammar represents Dyck-1 language S → SS | open S close | ε
  /// Returns the delimiters (open, close) when detected, otherwise null.
  static _Pair<String, String>? _detectDyck1Delimiters(Grammar grammar) {
    final s = grammar.startSymbol;
    // Must have exactly one non-terminal S
    if (grammar.nonTerminals.length != 1 || !grammar.nonTerminals.contains(s)) {
      return null;
    }

    // Look for productions: S→SS, S→open S close, S→ε
    bool hasConcat = false;
    bool hasEps = false;
    String? open;
    String? close;

    for (final p in grammar.productions) {
      if (p.leftSide.isEmpty || p.leftSide.first != s) continue;
      if (p.isLambda || p.rightSide.isEmpty) {
        hasEps = true;
        continue;
      }
      if (p.rightSide.length == 2) {
        if (p.rightSide[0] == s && p.rightSide[1] == s) {
          hasConcat = true;
          continue;
        }
      }
      if (p.rightSide.length == 3) {
        final a = p.rightSide[0];
        final mid = p.rightSide[1];
        final b = p.rightSide[2];
        if (mid == s &&
            grammar.terminals.contains(a) &&
            grammar.terminals.contains(b)) {
          open = a;
          close = b;
          // keep scanning to confirm other rules too
        }
      }
    }

    if (hasConcat && hasEps && open != null && close != null) {
      return _Pair(open, close);
    }
    return null;
  }

  /// Linear-time recognizer for Dyck-1 strings over given delimiters
  static bool _fastDyck1Recognize(
    Grammar grammar,
    String input,
    String open,
    String close,
  ) {
    final tokenResult = GrammarInputTokenizer.tokenize(grammar, input);
    if (tokenResult.isFailure) return false;

    int balance = 0;
    for (final token in tokenResult.data!) {
      if (token.lexeme == open) {
        balance++;
      } else if (token.lexeme == close) {
        balance--;
        if (balance < 0) return false;
      } else {
        // Unknown symbol; reject here (validation should have caught earlier)
        return false;
      }
    }
    return balance == 0;
  }

  /// Tiny tuple helper
  // Placeholder within class removed; see top-level class below.

  /// Parses with the standard table-driven LL(1) algorithm recorded in
  /// docs/reference-deviations.md.
  static ParseResult? _parseWithLL1(
    Grammar grammar,
    String inputString,
    Duration timeout, {
    int maxSteps = 100000,
    bool Function()? isCancelled,
  }) {
    final stopwatch = Stopwatch()..start();
    final tableResult = GrammarAnalyzer.buildLL1ParseTable(grammar);
    if (tableResult.isFailure) {
      return ParseResult.failure(
        inputString: inputString,
        errorMessage: tableResult.error!,
        structuredMessage: tableResult.structuredError,
        executionTime: stopwatch.elapsed,
        outcome: GrammarParseOutcome.invalidInput,
      );
    }

    final tokenResult = GrammarInputTokenizer.tokenize(grammar, inputString);
    if (tokenResult.isFailure) {
      return ParseResult.failure(
        inputString: inputString,
        errorMessage: tokenResult.error!,
        structuredMessage: tokenResult.structuredError,
        executionTime: stopwatch.elapsed,
        outcome: GrammarParseOutcome.tokenizationFailure,
      );
    }

    final inputTokens = <GrammarInputToken>[
      ...tokenResult.data!,
      GrammarInputToken(
        lexeme: r'$',
        start: inputString.length,
        end: inputString.length,
      ),
    ];
    final stack = <String>[r'$', grammar.startSymbol];
    final steps = <LL1ParseStep>[];
    final derivations = <List<String>>[];
    var inputIndex = 0;
    var stepNumber = 1;

    List<String> remainingInput() => inputTokens
        .skip(inputIndex)
        .map((token) => token.lexeme)
        .toList(growable: false);

    ParseResult reject({
      required String message,
      required Set<String> expected,
      StructuredMessage? structuredMessage,
      String? nonTerminal,
      String? tableLookahead,
      LL1ParseDiagnostic diagnostic = LL1ParseDiagnostic.invalidParserState,
      GrammarParseOutcome outcome = GrammarParseOutcome.rejected,
    }) {
      final lookahead = inputTokens[inputIndex].lexeme;
      steps.add(
        LL1ParseStep(
          stepNumber: stepNumber,
          action: LL1ParseAction.error,
          stack: stack,
          remainingInput: remainingInput(),
          lookahead: lookahead,
          nonTerminal: nonTerminal,
          tableNonTerminal: nonTerminal,
          tableLookahead: tableLookahead,
          diagnostic: diagnostic,
          expectedTerminals: expected,
          message: message,
          structuredMessage: structuredMessage,
        ),
      );
      return ParseResult.failure(
        inputString: inputString,
        errorMessage: message,
        executionTime: stopwatch.elapsed,
        derivations: derivations,
        farthestPosition: inputTokens[inputIndex].start,
        expectedSymbols: expected,
        ll1Steps: steps,
        structuredMessage: structuredMessage,
        outcome: outcome,
      );
    }

    final tableReport = tableResult.data!;
    final typedConflicts = tableReport.value.typedConflicts;
    if (typedConflicts.isNotEmpty) {
      final firstConflict = typedConflicts.first;
      return reject(
        message:
            'Grammar is not LL(1): ${typedConflicts.map((conflict) => conflict.formalDescription).join('; ')}.',
        structuredMessage: firstConflict.descriptionMessage,
        expected: const <String>{},
        nonTerminal: firstConflict.nonTerminal,
        tableLookahead: firstConflict.lookahead,
        diagnostic: LL1ParseDiagnostic.conflict,
        outcome: GrammarParseOutcome.conflict,
      );
    }

    while (stack.isNotEmpty) {
      if (isCancelled?.call() ?? false) {
        return reject(
          message: 'LL(1) parsing was cancelled.',
          structuredMessage: GrammarParserMessages.ll1Cancelled(),
          expected: const <String>{},
          diagnostic: LL1ParseDiagnostic.cancelled,
          outcome: GrammarParseOutcome.cancelled,
        );
      }
      if (stopwatch.elapsed >= timeout) {
        return reject(
          message: 'LL(1) parsing timed out after ${timeout.inMilliseconds}ms.',
          structuredMessage: GrammarParserMessages.ll1TimedOut(timeout),
          expected: const <String>{},
          diagnostic: LL1ParseDiagnostic.timedOut,
          outcome: GrammarParseOutcome.timedOut,
        );
      }
      if (steps.length >= maxSteps) {
        return reject(
          message: 'LL(1) parsing stopped at the $maxSteps-step limit.',
          structuredMessage: GrammarParserMessages.ll1StepLimitReached(
            maxSteps,
          ),
          expected: const <String>{},
          diagnostic: LL1ParseDiagnostic.stepLimit,
          outcome: GrammarParseOutcome.stepLimit,
        );
      }

      final top = stack.last;
      final lookaheadToken = inputTokens[inputIndex];
      final lookahead = lookaheadToken.lexeme;
      final stackSnapshot = List<String>.from(stack);
      final remainingSnapshot = remainingInput();

      if (top == r'$') {
        if (lookahead != r'$') {
          return reject(
            message:
                'Unexpected trailing input "$lookahead" at position ${lookaheadToken.start}; expected end of input.',
            structuredMessage: GrammarParserMessages.ll1TrailingInput(
              lookahead: lookahead,
              position: lookaheadToken.start,
            ),
            expected: const <String>{r'$'},
            diagnostic: LL1ParseDiagnostic.trailingInput,
          );
        }

        steps.add(
          LL1ParseStep(
            stepNumber: stepNumber,
            action: LL1ParseAction.accept,
            stack: stackSnapshot,
            remainingInput: remainingSnapshot,
            lookahead: lookahead,
            message: 'The parser stack and input both reached the end marker.',
          ),
        );
        stopwatch.stop();
        return ParseResult.success(
          inputString: inputString,
          derivations: derivations,
          executionTime: stopwatch.elapsed,
          farthestPosition: inputString.length,
          ll1Steps: steps,
        );
      }

      if (!grammar.nonterminals.contains(top)) {
        if (top != lookahead) {
          final message = lookahead == r'$'
              ? 'Unexpected end of input; expected "$top".'
              : 'Terminal mismatch at position ${lookaheadToken.start}: expected "$top", found "$lookahead".';
          return reject(
            message: message,
            structuredMessage: lookahead == r'$'
                ? GrammarParserMessages.ll1UnexpectedEnd(top)
                : GrammarParserMessages.ll1TerminalMismatch(
                    expected: top,
                    found: lookahead,
                    position: lookaheadToken.start,
                  ),
            expected: {top},
            diagnostic: lookahead == r'$'
                ? LL1ParseDiagnostic.unexpectedEnd
                : LL1ParseDiagnostic.terminalMismatch,
          );
        }

        steps.add(
          LL1ParseStep(
            stepNumber: stepNumber++,
            action: LL1ParseAction.match,
            stack: stackSnapshot,
            remainingInput: remainingSnapshot,
            lookahead: lookahead,
            expectedTerminals: {top},
            message: 'Matched terminal "$top" and advanced the input.',
          ),
        );
        stack.removeLast();
        inputIndex++;
        continue;
      }

      final row = tableReport.value.entryTable[top] ?? const {};
      final cell = row[lookahead];
      if (cell == null || cell.isEmpty) {
        final expected = row.keys.toList()..sort();
        final expectedText = expected.isEmpty ? 'none' : expected.join(', ');
        return reject(
          message:
              'No production for [$top, $lookahead]; expected one of: $expectedText.',
          structuredMessage: GrammarParserMessages.ll1EmptyTableCell(
            nonTerminal: top,
            lookahead: lookahead,
            expected: expectedText,
          ),
          expected: expected.toSet(),
          nonTerminal: top,
          tableLookahead: lookahead,
          diagnostic: LL1ParseDiagnostic.emptyTableCell,
        );
      }

      if (cell.length != 1) {
        final productions =
            cell
                .map(
                  (entry) =>
                      entry.rightSide.isEmpty ? 'ε' : entry.rightSide.join(' '),
                )
                .toList()
              ..sort();
        return reject(
          message:
              'Grammar is not LL(1): conflict at [$top, $lookahead]: ${productions.join(' vs ')}.',
          structuredMessage: GrammarParserMessages.ll1ConflictCell(
            nonTerminal: top,
            lookahead: lookahead,
            productions: productions.join(' vs '),
          ),
          expected: {lookahead},
          nonTerminal: top,
          tableLookahead: lookahead,
          diagnostic: LL1ParseDiagnostic.conflict,
          outcome: GrammarParseOutcome.conflict,
        );
      }

      final entry = cell.single;
      final production = List<String>.from(entry.rightSide);
      steps.add(
        LL1ParseStep(
          stepNumber: stepNumber++,
          action: LL1ParseAction.expand,
          stack: stackSnapshot,
          remainingInput: remainingSnapshot,
          lookahead: lookahead,
          nonTerminal: top,
          productionId: entry.productionId,
          tableNonTerminal: top,
          tableLookahead: lookahead,
          production: production,
          expectedTerminals: row.keys.toSet(),
          message:
              'Selected $top → ${production.isEmpty ? 'ε' : production.join(' ')} from table[$top, $lookahead].',
        ),
      );
      derivations.add([top, ...production]);
      stack.removeLast();
      for (final symbol in production.reversed) {
        stack.add(symbol);
      }
    }

    return reject(
      message: 'LL(1) parser stopped with an empty stack.',
      structuredMessage: GrammarParserMessages.ll1EmptyStack(),
      expected: const <String>{r'$'},
    );
  }

  /// Parses using brute force (exhaustive search)
  static ParseResult? _parseWithBruteForce(
    Grammar grammar,
    String inputString,
    Duration timeout,
  ) {
    final result = BruteForceCFGParser.search(
      grammar,
      inputString,
      limits: BruteForceSearchLimits(timeLimit: timeout),
    );
    if (result.accepted) {
      final witness = result.witnesses.first;
      return ParseResult.success(
        inputString: inputString,
        derivations: witness.sententialForms,
        executionTime: result.statistics.executionTime,
        tree: witness.tree,
        bruteForceResult: result,
      );
    }
    final outcome = switch (result.outcome) {
      BruteForceParseOutcome.accepted => GrammarParseOutcome.accepted,
      BruteForceParseOutcome.rejected => GrammarParseOutcome.rejected,
      BruteForceParseOutcome.boundedUnknown =>
        GrammarParseOutcome.boundedUnknown,
      BruteForceParseOutcome.cancelled => GrammarParseOutcome.cancelled,
      BruteForceParseOutcome.invalidGrammar ||
      BruteForceParseOutcome.invalidInput => GrammarParseOutcome.invalidInput,
    };
    return ParseResult.failure(
      inputString: inputString,
      errorMessage: result.message ?? 'CFG brute-force search failed.',
      executionTime: result.statistics.executionTime,
      outcome: outcome,
      bruteForceResult: result,
      structuredMessage: result.structuredMessage,
    );
  }

  /// Parses using CYK algorithm
  static ParseResult? _parseWithCYK(
    Grammar grammar,
    String inputString,
    Duration timeout,
  ) {
    final stopwatch = Stopwatch()..start();
    final result = CYKParser.parse(grammar, inputString, timeout: timeout);
    if (result.isFailure) {
      stopwatch.stop();
      return ParseResult.failure(
        inputString: inputString,
        errorMessage: result.error!,
        executionTime: stopwatch.elapsed,
        structuredMessage: result.structuredError,
        outcome: result.error!.contains('timed out')
            ? GrammarParseOutcome.timedOut
            : GrammarParseOutcome.rejected,
      );
    }
    final cykResult = result.data!;
    final remaining = timeout - stopwatch.elapsed;
    final tree = cykResult.derivation == null
        ? null
        : treeFromCykDerivation(
            grammar,
            inputString,
            cykResult.derivation,
            timeout: remaining.isNegative ? Duration.zero : remaining,
          );
    stopwatch.stop();
    return cykResult.accepted
        ? ParseResult.success(
            inputString: inputString,
            derivations: const [],
            executionTime: stopwatch.elapsed,
            tree: tree,
          )
        : ParseResult.failure(
            inputString: inputString,
            errorMessage:
                cykResult.message ??
                'String "$inputString" cannot be derived from grammar',
            structuredMessage: cykResult.structuredMessage,
            executionTime: stopwatch.elapsed,
            outcome: cykResult.outcome,
          );
  }

  /// Tests if a grammar can generate a specific string
  static Result<bool> canGenerate(Grammar grammar, String inputString) {
    final parseResult = parse(grammar, inputString);
    if (!parseResult.isSuccess) {
      return Failure(
        parseResult.error!,
        structuredMessage: parseResult.structuredError,
      );
    }

    return Success(parseResult.data!.accepted);
  }

  /// Tests if a grammar cannot generate a specific string
  static Result<bool> cannotGenerate(Grammar grammar, String inputString) {
    final canGenerateResult = canGenerate(grammar, inputString);
    if (!canGenerateResult.isSuccess) {
      return Failure(
        canGenerateResult.error!,
        structuredMessage: canGenerateResult.structuredError,
      );
    }

    return Success(!canGenerateResult.data!);
  }

  /// Finds all strings of a given length that the grammar can generate
  static Result<Set<String>> findGeneratedStrings(
    Grammar grammar,
    int maxLength, {
    int maxResults = 100,
  }) {
    try {
      final generatedStrings = <String>{};
      final alphabet = grammar.terminals.toList();

      // Generate all possible strings up to maxLength
      for (
        int length = 0;
        length <= maxLength && generatedStrings.length < maxResults;
        length++
      ) {
        _generateStrings(
          grammar,
          alphabet,
          '',
          length,
          generatedStrings,
          maxResults,
        );
      }

      return Success(generatedStrings);
    } catch (e) {
      final message = GrammarParserMessages.generatedStringsFailed();
      return Failure(
        'Error finding generated strings: $e',
        structuredMessage: message,
      );
    }
  }

  /// Recursively generates strings and tests them
  static void _generateStrings(
    Grammar grammar,
    List<String> alphabet,
    String currentString,
    int remainingLength,
    Set<String> generatedStrings,
    int maxResults,
  ) {
    if (generatedStrings.length >= maxResults) return;

    if (remainingLength == 0) {
      final canGenerateResult = canGenerate(grammar, currentString);
      if (canGenerateResult.isSuccess && canGenerateResult.data!) {
        generatedStrings.add(currentString);
      }
      return;
    }

    for (final symbol in alphabet) {
      _generateStrings(
        grammar,
        alphabet,
        currentString + symbol,
        remainingLength - 1,
        generatedStrings,
        maxResults,
      );
    }
  }
}

/// Tiny tuple helper (top-level)
class _Pair<A, B> {
  final A item1;
  final B item2;
  const _Pair(this.item1, this.item2);
}

/// Result of parsing a string with a grammar
class ParseResult {
  final String inputString;
  final bool accepted;
  final List<List<String>> derivations;
  final String? errorMessage;
  final StructuredMessage? structuredMessage;
  final Duration executionTime;
  final int farthestPosition;
  final Set<String> expectedSymbols;
  final List<LL1ParseStep> ll1Steps;
  final List<LR1ParseStep> lr1Steps;
  final DerivationTree? tree;
  final BruteForceParseResult? bruteForceResult;
  final GrammarParseOutcome outcome;

  const ParseResult._({
    required this.inputString,
    required this.accepted,
    required this.derivations,
    this.errorMessage,
    this.structuredMessage,
    required this.executionTime,
    this.farthestPosition = 0,
    this.expectedSymbols = const <String>{},
    this.ll1Steps = const <LL1ParseStep>[],
    this.lr1Steps = const <LR1ParseStep>[],
    this.tree,
    this.bruteForceResult,
    required this.outcome,
  });

  factory ParseResult.success({
    required String inputString,
    required List<List<String>> derivations,
    required Duration executionTime,
    int? farthestPosition,
    Set<String> expectedSymbols = const <String>{},
    List<LL1ParseStep> ll1Steps = const <LL1ParseStep>[],
    List<LR1ParseStep> lr1Steps = const <LR1ParseStep>[],
    DerivationTree? tree,
    BruteForceParseResult? bruteForceResult,
    StructuredMessage? structuredMessage,
  }) {
    return ParseResult._(
      inputString: inputString,
      accepted: true,
      derivations: derivations,
      executionTime: executionTime,
      farthestPosition: farthestPosition ?? inputString.length,
      expectedSymbols: Set<String>.unmodifiable(expectedSymbols),
      ll1Steps: List<LL1ParseStep>.unmodifiable(ll1Steps),
      lr1Steps: List<LR1ParseStep>.unmodifiable(lr1Steps),
      tree: tree,
      bruteForceResult: bruteForceResult,
      structuredMessage: structuredMessage,
      outcome: GrammarParseOutcome.accepted,
    );
  }

  factory ParseResult.failure({
    required String inputString,
    required String errorMessage,
    StructuredMessage? structuredMessage,
    required Duration executionTime,
    List<List<String>> derivations = const <List<String>>[],
    int farthestPosition = 0,
    Set<String> expectedSymbols = const <String>{},
    List<LL1ParseStep> ll1Steps = const <LL1ParseStep>[],
    List<LR1ParseStep> lr1Steps = const <LR1ParseStep>[],
    BruteForceParseResult? bruteForceResult,
    GrammarParseOutcome outcome = GrammarParseOutcome.rejected,
  }) {
    return ParseResult._(
      inputString: inputString,
      accepted: false,
      derivations: derivations,
      errorMessage: errorMessage,
      structuredMessage: structuredMessage,
      executionTime: executionTime,
      farthestPosition: farthestPosition,
      expectedSymbols: Set<String>.unmodifiable(expectedSymbols),
      ll1Steps: List<LL1ParseStep>.unmodifiable(ll1Steps),
      lr1Steps: List<LR1ParseStep>.unmodifiable(lr1Steps),
      bruteForceResult: bruteForceResult,
      outcome: outcome,
    );
  }

  ParseResult copyWith({
    String? inputString,
    bool? accepted,
    List<List<String>>? derivations,
    String? errorMessage,
    StructuredMessage? structuredMessage,
    Duration? executionTime,
    int? farthestPosition,
    Set<String>? expectedSymbols,
    List<LL1ParseStep>? ll1Steps,
    List<LR1ParseStep>? lr1Steps,
    DerivationTree? tree,
    BruteForceParseResult? bruteForceResult,
    GrammarParseOutcome? outcome,
  }) {
    return ParseResult._(
      inputString: inputString ?? this.inputString,
      accepted: accepted ?? this.accepted,
      derivations: derivations ?? this.derivations,
      errorMessage: errorMessage ?? this.errorMessage,
      structuredMessage: structuredMessage ?? this.structuredMessage,
      executionTime: executionTime ?? this.executionTime,
      farthestPosition: farthestPosition ?? this.farthestPosition,
      expectedSymbols: expectedSymbols ?? this.expectedSymbols,
      ll1Steps: ll1Steps ?? this.ll1Steps,
      lr1Steps: lr1Steps ?? this.lr1Steps,
      tree: tree ?? this.tree,
      bruteForceResult: bruteForceResult ?? this.bruteForceResult,
      outcome: outcome ?? this.outcome,
    );
  }
}
