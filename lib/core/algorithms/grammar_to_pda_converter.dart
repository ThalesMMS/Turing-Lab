//
//  grammar_to_pda_converter.dart
//  Turing Lab
//
//  Concentra a conversão de gramáticas livres de contexto em autômatos de
//  pilha, oferecendo validações, análise de viabilidade e estimativas sobre o
//  processo.
//  Implementa a construção padrão CFG→PDA com criação de estados, transições
//  parametrizadas por produções e geração de relatórios estruturados sobre o
//  resultado.
//
//  Thales Matheus Mendonça Santos - October 2025
//
import 'dart:math' as math;
import 'package:vector_math/vector_math_64.dart';
import '../models/grammar.dart';
import '../models/pda.dart';
import '../models/state.dart';
import '../models/pda_transition.dart';
import '../result.dart';
import 'cfg/cfg_toolkit.dart';

/// Converts context-free grammars to pushdown automata
class GrammarToPDAConverter {
  /// Compatibility entrypoint expected by tests: converts a grammar to a PDA
  /// by delegating to [convertGrammarToPDA].
  static Result<PDA> convert(
    Grammar grammar, {
    Duration timeout = const Duration(seconds: 10),
  }) {
    return convertGrammarToPDA(grammar, timeout: timeout);
  }

  /// Checks if a grammar can be converted to PDA
  static bool canConvertToPDA(Grammar grammar) {
    try {
      // Basic validation
      if (grammar.productions.isEmpty) return false;
      if (grammar.startSymbol.isEmpty) return false;

      // Check if all productions are valid for PDA conversion
      for (final production in grammar.productions) {
        if (production.leftSide.isEmpty) return false;
        // Additional validation can be added here
      }

      return true;
    } catch (e) {
      return false;
    }
  }

  /// Analyzes the conversion process
  static Result<GrammarToPDAAnalysis> analyzeConversion(Grammar grammar) {
    try {
      final canConvert = canConvertToPDA(grammar);
      final productionCount = grammar.productions.length;
      final nonTerminalCount = grammar.nonTerminals.length;
      final terminalCount = grammar.terminals.length;

      final analysis = GrammarToPDAAnalysis(
        canConvert: canConvert,
        productionCount: productionCount,
        nonTerminalCount: nonTerminalCount,
        terminalCount: terminalCount,
        estimatedStateCount: productionCount + 2, // Rough estimate
        estimatedTransitionCount: productionCount * 2, // Rough estimate
      );

      return ResultFactory.success(analysis);
    } catch (e) {
      return ResultFactory.failure('Error analyzing conversion: $e');
    }
  }

  /// Converts a grammar to a PDA
  static Result<PDA> convertGrammarToPDA(
    Grammar grammar, {
    Duration timeout = const Duration(seconds: 10),
  }) {
    try {
      final stopwatch = Stopwatch()..start();

      // Validate input
      final validationResult = _validateInput(grammar);
      if (!validationResult.isSuccess) {
        return ResultFactory.failure(validationResult.error!);
      }

      // Handle empty grammar
      if (grammar.productions.isEmpty) {
        return ResultFactory.failure('Cannot convert empty grammar to PDA');
      }

      // Check if grammar has start symbol
      if (grammar.startSymbol.isEmpty) {
        return ResultFactory.failure('Grammar must have a start symbol');
      }

      // Create a simple PDA
      final result = _createStandardPDA(grammar);

      stopwatch.stop();
      if (stopwatch.elapsed > timeout) {
        return ResultFactory.failure('Conversion timed out');
      }

      return ResultFactory.success(result);
    } catch (e) {
      return ResultFactory.failure('Error converting grammar to PDA: $e');
    }
  }

  /// Creates a PDA from grammar using the standard CFG-to-PDA construction
  static PDA _createStandardPDA(Grammar grammar) {
    return _createPDA(grammar, greibach: false);
  }

  static PDA _createGreibachPDA(Grammar grammar) {
    return _createPDA(grammar, greibach: true);
  }

  static PDA _createPDA(Grammar grammar, {required bool greibach}) {
    final now = DateTime.now();

    // Create states
    final q0 = State(
      id: 'q0',
      label: 'Initial',
      position: Vector2(100, 100),
      isInitial: true,
      isAccepting: false,
    );

    final q1 = State(
      id: 'q1',
      label: 'Processing',
      position: Vector2(200, 100),
      isInitial: false,
      isAccepting: false,
    );

    final q2 = State(
      id: 'q2',
      label: 'Accepting',
      position: Vector2(300, 100),
      isInitial: false,
      isAccepting: true,
    );

    // Create transitions
    final transitions = <PDATransition>[];
    int transitionId = 1;

    // Transition from q0 to q1: push start symbol onto initial stack symbol
    transitions.add(
      PDATransition(
        id: 't${transitionId++}',
        fromState: q0,
        toState: q1,
        label: 'ε,Z/${grammar.startSymbol}Z',
        inputSymbol: '',
        popSymbol: 'Z',
        pushSymbol: '${grammar.startSymbol}Z',
        pushSymbols: [grammar.startSymbol, 'Z'],
        isLambdaInput: true,
      ),
    );

    // Add transitions for each production A → α
    for (final production in grammar.productions) {
      if (production.leftSide.isNotEmpty) {
        final leftSide = production.leftSide.first; // A
        final rightSide = production.rightSide; // α

        // Create transition: (q1, ε, A) → (q1, α^R)
        // Handle both non-empty and empty right sides
        final isLambdaProduction = rightSide.isEmpty || production.isLambda;
        final inputSymbol =
            greibach && !isLambdaProduction ? rightSide.first : '';
        final pushSymbols = isLambdaProduction
            ? const <String>[]
            : (greibach ? rightSide.skip(1).toList() : rightSide);
        final String pushString;
        if (pushSymbols.isEmpty) {
          // For A → ε, just pop A without pushing anything
          pushString = '';
        } else {
          pushString = pushSymbols.join();
        }

        transitions.add(
          PDATransition(
            id: 't${transitionId++}',
            fromState: q1,
            toState: q1,
            label:
                '${inputSymbol.isEmpty ? 'ε' : inputSymbol},$leftSide/$pushString',
            inputSymbol: inputSymbol,
            popSymbol: leftSide,
            pushSymbol: pushString,
            pushSymbols: pushSymbols,
            isLambdaInput: inputSymbol.isEmpty,
            isLambdaPush: pushSymbols.isEmpty,
          ),
        );
      }
    }

    // Add transitions for each terminal a: (q1, a, a) → (q1, ε)
    if (!greibach) {
      for (final terminal in grammar.terminals) {
        transitions.add(
          PDATransition(
            id: 't${transitionId++}',
            fromState: q1,
            toState: q1,
            label: '$terminal,$terminal/ε',
            inputSymbol: terminal,
            popSymbol: terminal,
            pushSymbol: '',
            isLambdaPush: true,
          ),
        );
      }
    }

    // Transition from q1 to q2: pop initial stack symbol (accept by empty stack)
    transitions.add(
      PDATransition(
        id: 't${transitionId++}',
        fromState: q1,
        toState: q2,
        label: 'ε,Z/ε',
        inputSymbol: '',
        popSymbol: 'Z',
        pushSymbol: '',
        isLambdaInput: true,
        isLambdaPush: true,
      ),
    );

    return PDA(
      id: 'pda_${DateTime.now().millisecondsSinceEpoch}',
      name: greibach ? 'PDA from Grammar (Greibach)' : 'PDA from Grammar',
      states: {q0, q1, q2},
      transitions: transitions.toSet(),
      alphabet: grammar.terminals,
      initialState: q0,
      acceptingStates: {q2},
      created: now,
      modified: now,
      bounds: const math.Rectangle(0, 0, 800, 600),
      stackAlphabet: {
        ...grammar.terminals,
        ...grammar.nonTerminals,
        'Z', // Initial stack symbol
      },
      initialStackSymbol: 'Z',
    );
  }

  /// Validates input grammar
  static Result<void> _validateInput(Grammar grammar) {
    if (grammar.productions.isEmpty) {
      return ResultFactory.failure('Grammar must have at least one production');
    }

    if (grammar.startSymbol.isEmpty) {
      return ResultFactory.failure('Grammar must have a start symbol');
    }

    if (!grammar.nonTerminals.contains(grammar.startSymbol)) {
      return ResultFactory.failure('Start symbol must be a non-terminal');
    }

    return ResultFactory.success(null);
  }

  /// Converts a grammar to a PDA using the standard construction
  static Result<PDA> convertGrammarToPDAStandard(
    Grammar grammar, {
    Duration timeout = const Duration(seconds: 10),
  }) {
    try {
      final stopwatch = Stopwatch()..start();

      // Validate input
      final validationResult = _validateInput(grammar);
      if (!validationResult.isSuccess) {
        return ResultFactory.failure(validationResult.error!);
      }

      // Handle empty grammar
      if (grammar.productions.isEmpty) {
        return ResultFactory.failure('Cannot convert empty grammar to PDA');
      }

      // Check if grammar has start symbol
      if (grammar.startSymbol.isEmpty) {
        return ResultFactory.failure('Grammar must have a start symbol');
      }

      final result = _createStandardPDA(grammar);

      stopwatch.stop();
      if (stopwatch.elapsed > timeout) {
        return ResultFactory.failure('Conversion timed out');
      }

      return ResultFactory.success(result);
    } catch (e) {
      return ResultFactory.failure(
        'Error converting grammar to PDA (standard): $e',
      );
    }
  }

  /// Converts a grammar to a PDA using Greibach normal form
  static Result<PDA> convertGrammarToPDAGreibach(
    Grammar grammar, {
    Duration timeout = const Duration(seconds: 10),
  }) {
    try {
      final stopwatch = Stopwatch()..start();

      // Validate input
      final validationResult = _validateInput(grammar);
      if (!validationResult.isSuccess) {
        return ResultFactory.failure(validationResult.error!);
      }

      // Handle empty grammar
      if (grammar.productions.isEmpty) {
        return ResultFactory.failure('Cannot convert empty grammar to PDA');
      }

      // Check if grammar has start symbol
      if (grammar.startSymbol.isEmpty) {
        return ResultFactory.failure('Grammar must have a start symbol');
      }

      final gnfResult = CFGToolkit.toGNF(grammar);
      if (!gnfResult.isSuccess || gnfResult.data == null) {
        return ResultFactory.failure(
          gnfResult.error ??
              'Failed to convert grammar to Greibach normal form',
        );
      }
      final gnfGrammar = gnfResult.data!;
      if (!CFGToolkit.isGNF(gnfGrammar)) {
        return ResultFactory.failure(
          'Greibach conversion did not produce a valid GNF grammar',
        );
      }

      final result = _createGreibachPDA(gnfGrammar);

      stopwatch.stop();
      if (stopwatch.elapsed > timeout) {
        return ResultFactory.failure('Conversion timed out');
      }

      return ResultFactory.success(result);
    } catch (e) {
      return ResultFactory.failure(
        'Error converting grammar to PDA (Greibach): $e',
      );
    }
  }

  /// Checks if a grammar can be converted to a PDA
  static Result<bool> canConvertGrammarToPDA(Grammar grammar) {
    try {
      // Validate input
      final validationResult = _validateInput(grammar);
      if (!validationResult.isSuccess) {
        return ResultFactory.failure(validationResult.error!);
      }

      // Check if grammar is context-free
      if (grammar.productions.any((p) => p.leftSide.length > 1)) {
        return ResultFactory.failure('Grammar is not context-free');
      }

      if (grammar.startSymbol.isEmpty) {
        return ResultFactory.failure('Grammar must have a start symbol');
      }

      if (!grammar.nonTerminals.contains(grammar.startSymbol)) {
        return ResultFactory.failure('Start symbol must be a non-terminal');
      }

      return ResultFactory.success(true);
    } catch (e) {
      return ResultFactory.failure(
        'Error checking if grammar can be converted to PDA: $e',
      );
    }
  }

  /// Analyzes the conversion of a grammar to PDA
  static Result<Map<String, dynamic>> analyzeGrammarToPDAConversion(
    Grammar grammar, {
    Duration timeout = const Duration(seconds: 10),
  }) {
    try {
      final stopwatch = Stopwatch()..start();

      // Validate input
      final validationResult = _validateInput(grammar);
      if (!validationResult.isSuccess) {
        return ResultFactory.failure(validationResult.error!);
      }

      // Handle empty grammar
      if (grammar.productions.isEmpty) {
        return ResultFactory.failure(
          'Cannot analyze conversion of empty grammar',
        );
      }

      // Check if grammar has start symbol
      if (grammar.startSymbol.isEmpty) {
        return ResultFactory.failure('Grammar must have a start symbol');
      }

      // Create analysis result
      final finalResult = <String, dynamic>{
        'grammar': grammar.toJson(),
        'canConvert': true,
        'complexity': 'O(n)',
        'steps': [
          'Validate grammar',
          'Create initial state',
          'Create processing state',
          'Create accepting state',
          'Add transitions',
        ],
        'timeout': timeout.inMilliseconds,
        'timestamp': DateTime.now().toIso8601String(),
      };

      stopwatch.stop();
      if (stopwatch.elapsed > timeout) {
        return ResultFactory.failure('Analysis timed out');
      }

      return ResultFactory.success(finalResult);
    } catch (e) {
      return ResultFactory.failure(
        'Error analyzing grammar to PDA conversion: $e',
      );
    }
  }
}

/// Analysis result for grammar to PDA conversion
class GrammarToPDAAnalysis {
  /// Whether the grammar can be converted to PDA
  final bool canConvert;

  /// Number of productions in the grammar
  final int productionCount;

  /// Number of non-terminals
  final int nonTerminalCount;

  /// Number of terminals
  final int terminalCount;

  /// Estimated number of states in the resulting PDA
  final int estimatedStateCount;

  /// Estimated number of transitions in the resulting PDA
  final int estimatedTransitionCount;

  const GrammarToPDAAnalysis({
    required this.canConvert,
    required this.productionCount,
    required this.nonTerminalCount,
    required this.terminalCount,
    required this.estimatedStateCount,
    required this.estimatedTransitionCount,
  });

  @override
  String toString() {
    return 'GrammarToPDAAnalysis(canConvert: $canConvert, '
        'productionCount: $productionCount, '
        'nonTerminalCount: $nonTerminalCount, '
        'terminalCount: $terminalCount, '
        'estimatedStateCount: $estimatedStateCount, '
        'estimatedTransitionCount: $estimatedTransitionCount)';
  }
}
