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
import '../models/derivation_tree_node.dart';
import '../models/grammar.dart';
import '../models/grammar_parse_report.dart';
import '../models/ll1_parse_step.dart';
import '../result.dart';
import 'cfg/cyk_parser.dart';
import 'grammar_analyzer.dart';
import 'grammar_input_tokenizer.dart';
import 'grammar_parser_simple_recursive.dart';
import 'grammar_parser_earley.dart';

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

typedef _ParsingStrategy = ParseResult? Function(
  Grammar grammar,
  String inputString,
  Duration timeout,
);

class GrammarParser {
  static const _lrUnavailableMessage =
      'LR parsing is not available because the LR parser is not implemented.';

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
      label: 'LR',
      isAvailable: false,
      unavailableReason: _lrUnavailableMessage,
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
    // Keep the old behavior unchanged.

    // Validate input (symbols and basic invariants)
    final validation = _validateInput(grammar, inputString);
    if (!validation.isSuccess) {
      return Failure(validation.error!);
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
      final onlyDyckTerminals = grammar.terminals.length == 2 &&
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
          return Success(
            ParseResult.failure(
              inputString: inputString,
              errorMessage:
                  'String "$inputString" cannot be derived from grammar',
              executionTime: const Duration(),
            ),
          );
        }
        // Accepted via fast path; optionally attempt to build derivation later
        final parser = SimpleRecursiveDescentParser(grammar);
        final rd = parser.parse(inputString, timeout: timeout);
        if (rd.isSuccess) {
          return rd;
        }
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
      return Success(
        ParseResult.failure(
          inputString: inputString,
          errorMessage: 'String "$inputString" cannot be derived from grammar',
          executionTime: const Duration(),
        ),
      );
    }

    // If accepted, optionally build a derivation using the simple parser (best-effort)
    final parser = SimpleRecursiveDescentParser(grammar);
    final rd = parser.parse(inputString, timeout: timeout);
    if (rd.isSuccess) {
      return rd;
    }

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
    ParsingStrategyHint strategyHint = ParsingStrategyHint.auto,
  }) {
    final startTime = DateTime.now();

    // Validate input (symbols and basic invariants)
    final validation = _validateInput(grammar, inputString);
    if (!validation.isSuccess) {
      return Failure(validation.error!);
    }

    final capability = capabilityFor(strategyHint);
    if (!capability.isAvailable) {
      return Failure(capability.unavailableReason!);
    }

    if (strategyHint != ParsingStrategyHint.auto) {
      final result = _parseString(
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
            message: result.errorMessage ??
                'String "$inputString" cannot be derived from grammar',
            executionTime: elapsed,
            ll1Steps: result.ll1Steps,
          ),
        );
      }

      final allTrees = strategyHint == ParsingStrategyHint.ll
          ? const <DerivationTree>[]
          : _treesFromDerivations(result.derivations, inputString);
      return Success(
        GrammarParseReport.accepted(
          inputString: inputString,
          executionTime: elapsed,
          trees: allTrees.take(maxTrees).toList(growable: false),
          isAmbiguous: allTrees.length > maxTrees,
          ll1Steps: result.ll1Steps,
        ),
      );
    }

    // Dyck-1 fast path (accept/reject only; no trees) for auto mode.
    final dyckDelims = _detectDyck1Delimiters(grammar);
    if (dyckDelims != null) {
      final open = dyckDelims.item1;
      final close = dyckDelims.item2;

      final onlyDyckTerminals = grammar.terminals.length == 2 &&
          grammar.terminals.contains(open) &&
          grammar.terminals.contains(close);

      if (onlyDyckTerminals) {
        final accepted = _fastDyck1Recognize(
          grammar,
          inputString,
          open,
          close,
        );
        final elapsed = DateTime.now().difference(startTime);
        if (!accepted) {
          return Success(
            GrammarParseReport.rejected(
              inputString: inputString,
              farthestPosition: 0,
              expectedSymbols: {open},
              message: 'String "$inputString" cannot be derived from grammar',
              executionTime: elapsed,
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
    final accepted = earley.recognizes(inputString, timeout: timeout);
    if (!accepted) {
      return Success(
        GrammarParseReport.rejected(
          inputString: inputString,
          farthestPosition: 0,
          message: 'String "$inputString" cannot be derived from grammar',
          executionTime: DateTime.now().difference(startTime),
        ),
      );
    }

    // Best-effort tree via recursive descent derivation trace (legacy format).
    final parser = SimpleRecursiveDescentParser(grammar);
    final rd = parser.parse(inputString, timeout: timeout);
    if (rd.isSuccess) {
      final result = rd.data!;
      final allTrees = _treesFromDerivations(result.derivations, inputString);
      return Success(
        GrammarParseReport.accepted(
          inputString: inputString,
          executionTime: DateTime.now().difference(startTime),
          trees: allTrees.take(maxTrees).toList(growable: false),
          isAmbiguous: allTrees.length > maxTrees,
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

  /// Validates the input grammar and string
  static Result<void> _validateInput(Grammar grammar, String inputString) {
    if (grammar.productions.isEmpty) {
      return const Failure('Grammar must have at least one production');
    }

    if (grammar.startSymbol.isEmpty) {
      return const Failure('Grammar must have a start symbol');
    }

    if (!grammar.nonTerminals.contains(grammar.startSymbol)) {
      return const Failure('Start symbol must be a non-terminal');
    }

    final tokens = GrammarInputTokenizer.tokenize(grammar, inputString);
    if (tokens.isFailure) {
      return Failure(tokens.error!);
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
    return ParseResult.failure(
      inputString: inputString,
      errorMessage: failureMessage,
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
        return const [];
      case ParsingStrategyHint.auto:
        return [
          _parseWithBruteForce,
          _parseWithCYK,
        ];
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
    Duration timeout,
  ) {
    final stopwatch = Stopwatch()..start();
    final tableResult = GrammarAnalyzer.buildLL1ParseTable(grammar);
    if (tableResult.isFailure) {
      return ParseResult.failure(
        inputString: inputString,
        errorMessage: tableResult.error!,
        executionTime: stopwatch.elapsed,
      );
    }

    final tokenResult = GrammarInputTokenizer.tokenize(grammar, inputString);
    if (tokenResult.isFailure) {
      return ParseResult.failure(
        inputString: inputString,
        errorMessage: tokenResult.error!,
        executionTime: stopwatch.elapsed,
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
      String? nonTerminal,
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
          expectedTerminals: expected,
          message: message,
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
      );
    }

    final tableReport = tableResult.data!;
    final conflicts = <String>[];
    final nonTerminals = tableReport.value.table.keys.toList()..sort();
    for (final nonTerminal in nonTerminals) {
      final row = tableReport.value.table[nonTerminal]!;
      final terminals = row.keys.toList()..sort();
      for (final terminal in terminals) {
        final cell = row[terminal]!;
        if (cell.length < 2) continue;
        final productions = cell
            .map((right) => right.isEmpty ? 'ε' : right.join(' '))
            .toList()
          ..sort();
        conflicts.add(
          'Conflict at [$nonTerminal, $terminal]: ${productions.join(' vs ')}',
        );
      }
    }
    if (conflicts.isNotEmpty) {
      return reject(
        message: 'Grammar is not LL(1): ${conflicts.join('; ')}.',
        expected: const <String>{},
        nonTerminal: grammar.startSymbol,
      );
    }

    while (stack.isNotEmpty) {
      if (stopwatch.elapsed >= timeout) {
        return reject(
          message: 'LL(1) parsing timed out after ${timeout.inMilliseconds}ms.',
          expected: const <String>{},
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
            expected: const <String>{r'$'},
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
          return reject(message: message, expected: {top});
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

      final row = tableReport.value.table[top] ?? const {};
      final cell = row[lookahead];
      if (cell == null || cell.isEmpty) {
        final expected = row.keys.toList()..sort();
        final expectedText = expected.isEmpty ? 'none' : expected.join(', ');
        return reject(
          message:
              'No production for [$top, $lookahead]; expected one of: $expectedText.',
          expected: expected.toSet(),
          nonTerminal: top,
        );
      }

      if (cell.length != 1) {
        final productions = cell
            .map((right) => right.isEmpty ? 'ε' : right.join(' '))
            .toList()
          ..sort();
        return reject(
          message:
              'Grammar is not LL(1): conflict at [$top, $lookahead]: ${productions.join(' vs ')}.',
          expected: {lookahead},
          nonTerminal: top,
        );
      }

      final production = List<String>.from(cell.single);
      steps.add(
        LL1ParseStep(
          stepNumber: stepNumber++,
          action: LL1ParseAction.expand,
          stack: stackSnapshot,
          remainingInput: remainingSnapshot,
          lookahead: lookahead,
          nonTerminal: top,
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
      expected: const <String>{r'$'},
    );
  }

  /// Parses using brute force (exhaustive search)
  static ParseResult? _parseWithBruteForce(
    Grammar grammar,
    String inputString,
    Duration timeout,
  ) {
    final startTime = DateTime.now();

    // Use a simple recursive descent approach
    final result = _parseWithRecursiveDescent(
      grammar,
      grammar.startSymbol,
      inputString,
      startTime,
      timeout,
    );

    if (result != null) {
      return ParseResult.success(
        inputString: inputString,
        derivations: [result],
        executionTime: DateTime.now().difference(startTime),
      );
    }

    return null;
  }

  /// Parses using recursive descent approach
  static List<String>? _parseWithRecursiveDescent(
    Grammar grammar,
    String nonTerminal,
    String targetString,
    DateTime startTime,
    Duration timeout,
  ) {
    // Check timeout
    if (DateTime.now().difference(startTime) > timeout) {
      return null;
    }

    // If target is empty, check if non-terminal can derive empty string
    if (targetString.isEmpty) {
      if (_canDeriveEmptyStringFromSymbol(grammar, nonTerminal, <String>{})) {
        return [nonTerminal];
      }
      return null;
    }

    // Try all productions for this non-terminal
    for (final production in grammar.productions) {
      if (production.leftSide.isNotEmpty &&
          production.leftSide.first == nonTerminal) {
        // Handle epsilon productions
        if (production.rightSide.isEmpty || production.isLambda) {
          if (targetString.isEmpty) {
            return [nonTerminal];
          }
          continue;
        }

        // Handle terminal productions
        if (production.rightSide.length == 1 &&
            grammar.terminals.contains(production.rightSide.first)) {
          if (targetString == production.rightSide.first) {
            return [nonTerminal, production.rightSide.first];
          }
          continue;
        }

        // Handle non-terminal productions
        if (production.rightSide.length == 1 &&
            grammar.nonTerminals.contains(production.rightSide.first)) {
          final result = _parseWithRecursiveDescent(
            grammar,
            production.rightSide.first,
            targetString,
            startTime,
            timeout,
          );
          if (result != null) {
            return [nonTerminal, ...result];
          }
        }

        // Handle productions with multiple symbols
        if (production.rightSide.length > 1) {
          // Try to split the target string in all possible ways
          final splitResult = GrammarInputTokenizer.splitOffsets(
            grammar,
            targetString,
          );
          if (splitResult.isFailure) continue;
          for (final split in splitResult.data!) {
            final leftPart = targetString.substring(0, split);
            final rightPart = targetString.substring(split);

            if (production.rightSide.length == 2) {
              final leftResult = _parseWithRecursiveDescent(
                grammar,
                production.rightSide[0],
                leftPart,
                startTime,
                timeout,
              );
              final rightResult = _parseWithRecursiveDescent(
                grammar,
                production.rightSide[1],
                rightPart,
                startTime,
                timeout,
              );

              if (leftResult != null && rightResult != null) {
                return [nonTerminal, ...leftResult, ...rightResult];
              }
            }
          }
        }
      }
    }

    return null;
  }

  /// Parses using CYK algorithm
  static ParseResult? _parseWithCYK(
    Grammar grammar,
    String inputString,
    Duration timeout,
  ) {
    final stopwatch = Stopwatch()..start();
    final result = CYKParser.parse(
      grammar,
      inputString,
      timeout: timeout,
    );
    stopwatch.stop();
    if (result.isFailure) {
      return ParseResult.failure(
        inputString: inputString,
        errorMessage: result.error!,
        executionTime: stopwatch.elapsed,
      );
    }
    return result.data!.accepted
        ? ParseResult.success(
            inputString: inputString,
            derivations: const [],
            executionTime: stopwatch.elapsed,
          )
        : ParseResult.failure(
            inputString: inputString,
            errorMessage:
                'String "$inputString" cannot be derived from grammar',
            executionTime: stopwatch.elapsed,
          );
  }

  /// Recursively checks if a symbol can derive empty string
  static bool _canDeriveEmptyStringFromSymbol(
    Grammar grammar,
    String symbol,
    Set<String> visited,
  ) {
    if (visited.contains(symbol)) {
      return false; // Avoid infinite recursion
    }
    visited.add(symbol);

    for (final production in grammar.productions) {
      if (production.leftSide.isNotEmpty &&
          production.leftSide.first == symbol) {
        if (production.rightSide.isEmpty || production.isLambda) {
          return true; // Direct epsilon production
        }

        // Check if all symbols in right side can derive empty string
        bool allCanDeriveEmpty = true;
        for (final rightSymbol in production.rightSide) {
          if (grammar.terminals.contains(rightSymbol)) {
            allCanDeriveEmpty = false;
            break;
          }
          if (!_canDeriveEmptyStringFromSymbol(
            grammar,
            rightSymbol,
            Set.from(visited),
          )) {
            allCanDeriveEmpty = false;
            break;
          }
        }
        if (allCanDeriveEmpty) {
          return true;
        }
      }
    }

    return false;
  }

  /// Tests if a grammar can generate a specific string
  static Result<bool> canGenerate(Grammar grammar, String inputString) {
    final parseResult = parse(grammar, inputString);
    if (!parseResult.isSuccess) {
      return Failure(parseResult.error!);
    }

    return Success(parseResult.data!.accepted);
  }

  /// Tests if a grammar cannot generate a specific string
  static Result<bool> cannotGenerate(Grammar grammar, String inputString) {
    final canGenerateResult = canGenerate(grammar, inputString);
    if (!canGenerateResult.isSuccess) {
      return Failure(canGenerateResult.error!);
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
      for (int length = 0;
          length <= maxLength && generatedStrings.length < maxResults;
          length++) {
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
      return Failure('Error finding generated strings: $e');
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
  final Duration executionTime;
  final int farthestPosition;
  final Set<String> expectedSymbols;
  final List<LL1ParseStep> ll1Steps;

  const ParseResult._({
    required this.inputString,
    required this.accepted,
    required this.derivations,
    this.errorMessage,
    required this.executionTime,
    this.farthestPosition = 0,
    this.expectedSymbols = const <String>{},
    this.ll1Steps = const <LL1ParseStep>[],
  });

  factory ParseResult.success({
    required String inputString,
    required List<List<String>> derivations,
    required Duration executionTime,
    int? farthestPosition,
    Set<String> expectedSymbols = const <String>{},
    List<LL1ParseStep> ll1Steps = const <LL1ParseStep>[],
  }) {
    return ParseResult._(
      inputString: inputString,
      accepted: true,
      derivations: derivations,
      executionTime: executionTime,
      farthestPosition: farthestPosition ?? inputString.length,
      expectedSymbols: Set<String>.unmodifiable(expectedSymbols),
      ll1Steps: List<LL1ParseStep>.unmodifiable(ll1Steps),
    );
  }

  factory ParseResult.failure({
    required String inputString,
    required String errorMessage,
    required Duration executionTime,
    List<List<String>> derivations = const <List<String>>[],
    int farthestPosition = 0,
    Set<String> expectedSymbols = const <String>{},
    List<LL1ParseStep> ll1Steps = const <LL1ParseStep>[],
  }) {
    return ParseResult._(
      inputString: inputString,
      accepted: false,
      derivations: derivations,
      errorMessage: errorMessage,
      executionTime: executionTime,
      farthestPosition: farthestPosition,
      expectedSymbols: Set<String>.unmodifiable(expectedSymbols),
      ll1Steps: List<LL1ParseStep>.unmodifiable(ll1Steps),
    );
  }

  ParseResult copyWith({
    String? inputString,
    bool? accepted,
    List<List<String>>? derivations,
    String? errorMessage,
    Duration? executionTime,
    int? farthestPosition,
    Set<String>? expectedSymbols,
    List<LL1ParseStep>? ll1Steps,
  }) {
    return ParseResult._(
      inputString: inputString ?? this.inputString,
      accepted: accepted ?? this.accepted,
      derivations: derivations ?? this.derivations,
      errorMessage: errorMessage ?? this.errorMessage,
      executionTime: executionTime ?? this.executionTime,
      farthestPosition: farthestPosition ?? this.farthestPosition,
      expectedSymbols: expectedSymbols ?? this.expectedSymbols,
      ll1Steps: ll1Steps ?? this.ll1Steps,
    );
  }
}
