//
//  grammar_parser.dart
//  Turing Lab
//
//  Coordena estratégias de parsing para gramáticas livres de contexto, incluindo
//  heurísticas rápidas para gramáticas de Dyck, reconhecimento geral via Earley
//  e derivação com análise recursiva. Realiza validações de entrada, seleciona
//  abordagens conforme dicas e encapsula resultados ricos em `ParseResult`.
//
//  Thales Matheus Mendonça Santos - October 2025
//
import '../models/derivation_tree.dart';
import '../models/derivation_tree_node.dart';
import '../models/grammar.dart';
import '../models/grammar_parse_report.dart';
import '../result.dart';
import 'cfg/cyk_parser.dart';
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
  static const _llUnavailableMessage =
      'LL parsing is not available because a complete LL(1) parser with '
      'nullable, FIRST/FOLLOW, and conflict detection is not implemented.';
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
      isAvailable: false,
      unavailableReason: _llUnavailableMessage,
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
        final dyckAccepted = _fastDyck1Recognize(inputString, open, close);
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
            farthestPosition: 0,
            message: result.errorMessage ??
                'String "$inputString" cannot be derived from grammar',
            executionTime: elapsed,
          ),
        );
      }

      final allTrees = _treesFromDerivations(result.derivations, inputString);
      return Success(
        GrammarParseReport.accepted(
          inputString: inputString,
          executionTime: elapsed,
          trees: allTrees.take(maxTrees).toList(growable: false),
          isAmbiguous: allTrees.length > maxTrees,
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
        final accepted = _fastDyck1Recognize(inputString, open, close);
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

    // Validate input string symbols
    for (int i = 0; i < inputString.length; i++) {
      final symbol = inputString[i];
      if (!grammar.terminals.contains(symbol)) {
        return Failure('Input string contains invalid symbol: $symbol');
      }
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
        return const [];
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
  static bool _fastDyck1Recognize(String input, String open, String close) {
    int balance = 0;
    for (int i = 0; i < input.length; i++) {
      final c = input[i];
      if (c == open) {
        balance++;
      } else if (c == close) {
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
          for (int split = 0; split <= targetString.length; split++) {
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

  const ParseResult._({
    required this.inputString,
    required this.accepted,
    required this.derivations,
    this.errorMessage,
    required this.executionTime,
  });

  factory ParseResult.success({
    required String inputString,
    required List<List<String>> derivations,
    required Duration executionTime,
  }) {
    return ParseResult._(
      inputString: inputString,
      accepted: true,
      derivations: derivations,
      executionTime: executionTime,
    );
  }

  factory ParseResult.failure({
    required String inputString,
    required String errorMessage,
    required Duration executionTime,
  }) {
    return ParseResult._(
      inputString: inputString,
      accepted: false,
      derivations: [],
      errorMessage: errorMessage,
      executionTime: executionTime,
    );
  }

  ParseResult copyWith({
    String? inputString,
    bool? accepted,
    List<List<String>>? derivations,
    String? errorMessage,
    Duration? executionTime,
  }) {
    return ParseResult._(
      inputString: inputString ?? this.inputString,
      accepted: accepted ?? this.accepted,
      derivations: derivations ?? this.derivations,
      errorMessage: errorMessage ?? this.errorMessage,
      executionTime: executionTime ?? this.executionTime,
    );
  }
}
