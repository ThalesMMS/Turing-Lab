//
//  grammar_parser_simple_recursive.dart
//  Turing Lab
//
//  Fornece um analisador sintático recursivo simples para gramáticas livres de
//  contexto, validando entradas e produzindo derivações passo a passo quando a
//  palavra pertence à linguagem. Complementa outros parsers ao oferecer uma
//  opção mais direta para testes e demonstrações.
//
//  Thales Matheus Mendonça Santos - October 2025
//

import '../models/grammar.dart';
import '../models/grammar_parse_report.dart';
import '../result.dart' as turing_lab_result;
import 'grammar_parser.dart';

/// Simple recursive descent parser for CFG
class SimpleRecursiveDescentParser {
  final Grammar grammar;
  int _farthestPosition = 0;

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
        return turing_lab_result.Failure(validationResult.error!);
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

      return turing_lab_result.Success(
        GrammarParseReport.rejected(
          inputString: inputString,
          farthestPosition: _farthestPosition,
          message: 'String "$inputString" cannot be derived from grammar',
          executionTime: elapsed,
        ),
      );
    } catch (e) {
      return turing_lab_result.Failure('Error parsing string: $e');
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
        return turing_lab_result.Failure(validationResult.error!);
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
      } else {
        return turing_lab_result.Failure(
          'String "$inputString" cannot be derived from grammar',
        );
      }
    } catch (e) {
      return turing_lab_result.Failure('Error parsing string: $e');
    }
  }

  /// Validates the input string
  turing_lab_result.Result<void> _validateInput(String inputString) {
    // Validate input string symbols
    for (int i = 0; i < inputString.length; i++) {
      final symbol = inputString[i];
      if (!grammar.terminals.contains(symbol)) {
        return turing_lab_result.Failure(
          'Input string contains invalid symbol: $symbol',
        );
      }
    }

    return const turing_lab_result.Success(null);
  }

  /// Parses the string using recursive descent
  List<String>? _parseString(String inputString, Duration timeout) {
    final startTime = DateTime.now();
    _farthestPosition = 0;

    // Handle empty string case
    if (inputString.isEmpty) {
      if (_canDeriveEmptyString(grammar.startSymbol)) {
        return [grammar.startSymbol];
      }
      return null;
    }

    // Try to parse the string
    return _parseNonTerminal(
      grammar.startSymbol,
      inputString,
      startTime,
      timeout,
      0,
    );
  }

  /// Parses a non-terminal against a string
  List<String>? _parseNonTerminal(
    String nonTerminal,
    String inputString,
    DateTime startTime,
    Duration timeout, [
    int offset = 0,
    int depth = 0,
  ]) {
    _recordFarthest(offset);

    // Check timeout
    if (DateTime.now().difference(startTime) > timeout) {
      return null;
    }

    // Prevent infinite recursion (max depth of 10)
    if (depth > 10) {
      return null;
    }

    // If input is empty, check if non-terminal can derive empty string
    if (inputString.isEmpty) {
      if (_canDeriveEmptyString(nonTerminal)) {
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
          if (inputString.isEmpty) {
            return [nonTerminal]; // ok: ε "consumes" nothing at the right point
          } else {
            continue; // there's input to consume, try another production
          }
        }

        // Handle terminal productions
        if (production.rightSide.length == 1 &&
            grammar.terminals.contains(production.rightSide.first)) {
          final terminal = production.rightSide.first;
          if (inputString.startsWith(terminal)) {
            _recordFarthest(offset + terminal.length);
            if (inputString == terminal) {
              return [nonTerminal, terminal];
            }
          }
          continue;
        }

        // Handle non-terminal productions
        if (production.rightSide.length == 1 &&
            grammar.nonTerminals.contains(production.rightSide.first)) {
          final result = _parseNonTerminal(
            production.rightSide.first,
            inputString,
            startTime,
            timeout,
            offset,
            depth + 1,
          );
          if (result != null) {
            return [nonTerminal, ...result];
          }
        }

        // Handle productions with multiple symbols
        if (production.rightSide.length > 1) {
          // Try to split the input string in all possible ways
          for (int split = 0; split <= inputString.length; split++) {
            final leftPart = inputString.substring(0, split);
            final rightPart = inputString.substring(split);

            if (production.rightSide.length == 2) {
              final leftResult = _parseNonTerminal(
                production.rightSide[0],
                leftPart,
                startTime,
                timeout,
                offset,
                depth + 1,
              );
              final rightResult = _parseNonTerminal(
                production.rightSide[1],
                rightPart,
                startTime,
                timeout,
                offset + split,
                depth + 1,
              );

              if (leftResult != null && rightResult != null) {
                return [nonTerminal, ...leftResult, ...rightResult];
              }
            } else if (production.rightSide.length == 3) {
              // Handle productions like S -> (S) or S -> aSa
              final firstSymbol = production.rightSide[0];
              final middleSymbol = production.rightSide[1];
              final lastSymbol = production.rightSide[2];

              // Protection for minimum length
              if (inputString.length >=
                      firstSymbol.length + lastSymbol.length &&
                  inputString.startsWith(firstSymbol) &&
                  inputString.endsWith(lastSymbol)) {
                _recordFarthest(offset + firstSymbol.length);
                final innerString = inputString.substring(
                  firstSymbol.length,
                  inputString.length - lastSymbol.length,
                );
                final innerResult = _parseNonTerminal(
                  middleSymbol,
                  innerString,
                  startTime,
                  timeout,
                  offset + firstSymbol.length,
                  depth + 1,
                );
                if (innerResult != null) {
                  _recordFarthest(offset + inputString.length);
                  return [nonTerminal, firstSymbol, ...innerResult, lastSymbol];
                }
              }

              // If failed, just try the next production
              continue;
            }
          }
        }
      }
    }

    return null;
  }

  void _recordFarthest(int position) {
    if (position > _farthestPosition) {
      _farthestPosition = position;
    }
  }

  /// Checks if a non-terminal can derive the empty string
  bool _canDeriveEmptyString(String nonTerminal) {
    return _canDeriveEmptyStringFromSymbol(nonTerminal, <String>{});
  }

  /// Recursively checks if a symbol can derive empty string
  bool _canDeriveEmptyStringFromSymbol(String symbol, Set<String> visited) {
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
}
