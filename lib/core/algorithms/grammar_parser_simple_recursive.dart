//
//  grammar_parser_simple_recursive.dart
//  Turing Lab
//
//  Provides a simple recursive-descent parser for context-free grammars,
//  validating input and producing step-by-step derivations when the
//  word belongs to the language. Complements other parsers by offering a
//  more direct option for tests and demonstrations.
//
//  Thales Matheus Mendonça Santos - October 2025
//

import '../models/grammar.dart';
import '../models/grammar_parse_report.dart';
import '../result.dart' as turing_lab_result;
import 'grammar_input_tokenizer.dart';
import 'grammar_parser.dart';
import 'grammar_parser_simple_recursive_messages.dart';

/// Simple recursive descent parser for CFG
class SimpleRecursiveDescentParser {
  final Grammar grammar;
  int _farthestPosition = 0;
  bool _timedOut = false;

  SimpleRecursiveDescentParser(this.grammar);

  turing_lab_result.Result<GrammarParseReport> parseWithReport(
    String inputString, {
    Duration timeout = const Duration(seconds: 5),
  }) {
    final start = DateTime.now();

    try {
      // Validate input
      final validationResult = _validateInput(inputString);
      if (!validationResult.isSuccess) {
        return turing_lab_result.Failure(
          validationResult.error!,
          structuredMessage: validationResult.structuredError,
        );
      }

      final result = _parseString(inputString, timeout);
      final elapsed = DateTime.now().difference(start);

      if (result != null) {
        return turing_lab_result.Success(
          GrammarParseReport.accepted(
            inputString: inputString,
            executionTime: elapsed,
          ),
        );
      }

      if (_timedOut) {
        final message = SimpleRecursiveDescentMessages.timedOut();
        return turing_lab_result.Success(
          GrammarParseReport.rejected(
            inputString: inputString,
            farthestPosition: _farthestPosition,
            message: 'Recursive-descent parsing timed out.',
            executionTime: elapsed,
            structuredMessage: message,
            outcome: GrammarParseOutcome.timedOut,
          ),
        );
      }

      final message = SimpleRecursiveDescentMessages.inputRejected(inputString);
      return turing_lab_result.Success(
        GrammarParseReport.rejected(
          inputString: inputString,
          farthestPosition: _farthestPosition,
          message: 'String "$inputString" cannot be derived from grammar',
          executionTime: elapsed,
          structuredMessage: message,
        ),
      );
    } catch (e) {
      final message = SimpleRecursiveDescentMessages.failed();
      return turing_lab_result.Failure(
        'Error parsing string: $e',
        structuredMessage: message,
      );
    }
  }

  /// Parses a string using recursive descent
  turing_lab_result.Result<ParseResult> parse(
    String inputString, {
    Duration timeout = const Duration(seconds: 5),
  }) {
    try {
      final stopwatch = Stopwatch()..start();

      // Validate input
      final validationResult = _validateInput(inputString);
      if (!validationResult.isSuccess) {
        return turing_lab_result.Failure(
          validationResult.error!,
          structuredMessage: validationResult.structuredError,
        );
      }

      // Parse the string
      final result = _parseString(inputString, timeout);
      stopwatch.stop();

      if (result != null) {
        return turing_lab_result.Success(
          ParseResult.success(
            inputString: inputString,
            derivations: [result],
            executionTime: stopwatch.elapsed,
          ),
        );
      } else if (_timedOut) {
        final message = SimpleRecursiveDescentMessages.timedOut();
        return turing_lab_result.Success(
          ParseResult.failure(
            inputString: inputString,
            errorMessage: 'Recursive-descent parsing timed out.',
            executionTime: stopwatch.elapsed,
            farthestPosition: _farthestPosition,
            structuredMessage: message,
            outcome: GrammarParseOutcome.timedOut,
          ),
        );
      } else {
        final message = SimpleRecursiveDescentMessages.inputRejected(
          inputString,
        );
        return turing_lab_result.Failure(
          'String "$inputString" cannot be derived from grammar',
          structuredMessage: message,
        );
      }
    } catch (e) {
      final message = SimpleRecursiveDescentMessages.failed();
      return turing_lab_result.Failure(
        'Error parsing string: $e',
        structuredMessage: message,
      );
    }
  }

  /// Validates the input string
  turing_lab_result.Result<void> _validateInput(String inputString) {
    final result = GrammarInputTokenizer.tokenize(grammar, inputString);
    if (result.isFailure) {
      return turing_lab_result.Failure(
        result.error!,
        structuredMessage: result.structuredError,
      );
    }

    return const turing_lab_result.Success(null);
  }

  /// Parses the string using recursive descent
  List<String>? _parseString(String inputString, Duration timeout) {
    final startTime = DateTime.now();
    _farthestPosition = 0;
    _timedOut = false;
    if (timeout <= Duration.zero) {
      _timedOut = true;
      return null;
    }
    final tokenResult = GrammarInputTokenizer.tokenize(grammar, inputString);
    if (tokenResult.isFailure) return null;
    final tokens = tokenResult.data!;
    final matches = _parseNonTerminal(
      grammar.startSymbol,
      tokens,
      0,
      startTime,
      timeout,
      inputString.length,
      const <String>{},
      0,
    );
    for (final match in matches) {
      if (match.nextToken == tokens.length) return match.derivation;
    }
    return null;
  }

  /// Parses a non-terminal at a token boundary.
  ///
  /// Returning every reachable token boundary lets a caller backtrack across
  /// mixed terminal/non-terminal right-hand sides. The previous implementation
  /// special-cased RHS lengths and treated both symbols of `S -> id Tail` as
  /// non-terminals, rejecting valid grammars with multi-character terminals.
  List<_RecursiveMatch> _parseNonTerminal(
    String nonTerminal,
    List<GrammarInputToken> tokens,
    int tokenIndex,
    DateTime startTime,
    Duration timeout, [
    int inputLength = 0,
    Set<String> active = const <String>{},
    int depth = 0,
  ]) {
    final offset = tokenIndex < tokens.length
        ? tokens[tokenIndex].start
        : inputLength;
    _recordFarthest(offset);
    if (DateTime.now().difference(startTime) > timeout) {
      _timedOut = true;
      return const [];
    }
    final maximumDepth =
        (tokens.length + 1) * (grammar.nonterminals.length + 1) +
        grammar.productions.length;
    if (depth > maximumDepth) return const [];
    final state = '$nonTerminal@$tokenIndex';
    if (active.contains(state)) return const [];
    final nextActive = {...active, state};
    final productions =
        grammar.productions
            .where(
              (production) =>
                  production.leftSide.length == 1 &&
                  production.leftSide.single == nonTerminal,
            )
            .toList()
          ..sort((left, right) {
            final byOrder = left.order.compareTo(right.order);
            return byOrder != 0 ? byOrder : left.id.compareTo(right.id);
          });
    final matches = <_RecursiveMatch>[];

    void parseSequence(
      List<String> symbols,
      int symbolIndex,
      int nextToken,
      List<String> derivation,
    ) {
      if (DateTime.now().difference(startTime) > timeout) {
        _timedOut = true;
        return;
      }
      if (symbolIndex == symbols.length) {
        matches.add(
          _RecursiveMatch(
            nextToken: nextToken,
            derivation: [nonTerminal, ...derivation],
          ),
        );
        return;
      }
      final symbol = symbols[symbolIndex];
      if (grammar.terminals.contains(symbol)) {
        if (nextToken < tokens.length && tokens[nextToken].lexeme == symbol) {
          _recordFarthest(tokens[nextToken].end);
          parseSequence(symbols, symbolIndex + 1, nextToken + 1, [
            ...derivation,
            symbol,
          ]);
        }
        return;
      }
      if (!grammar.nonterminals.contains(symbol)) return;
      for (final child in _parseNonTerminal(
        symbol,
        tokens,
        nextToken,
        startTime,
        timeout,
        inputLength,
        nextActive,
        depth + 1,
      )) {
        parseSequence(symbols, symbolIndex + 1, child.nextToken, [
          ...derivation,
          ...child.derivation,
        ]);
      }
    }

    for (final production in productions) {
      parseSequence(
        production.isLambda ? const [] : production.rightSide,
        0,
        tokenIndex,
        const [],
      );
    }
    return matches;
  }

  void _recordFarthest(int position) {
    if (position > _farthestPosition) {
      _farthestPosition = position;
    }
  }
}

final class _RecursiveMatch {
  const _RecursiveMatch({required this.nextToken, required this.derivation});

  final int nextToken;
  final List<String> derivation;
}
