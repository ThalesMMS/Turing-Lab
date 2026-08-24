//
//  input_validators.dart
//  Turing Lab
//
//  Centralizes static checks for finite automata, pushdown automata, Turing
//  machines, and grammars, ensuring loaded structures satisfy basic
//  constraints before they are simulated or converted. Inspects alphabets,
//  states, transitions, and initial symbols, reporting descriptive issue
//  codes for each inconsistency. Serves as a defense layer that guides
//  corrections in academic object modeling.
//
//  Thales Matheus Mendonça Santos - October 2025
//
import '../models/fsa.dart';
import '../models/fsa_transition.dart';
import '../models/pda.dart';
import '../models/pda_transition.dart';
import '../models/tm.dart';
import '../models/tm_transition.dart';
import '../models/grammar.dart';
import '../models/validation_diagnostic.dart';

class ValidationIssue {
  final String code;
  final String message;
  final String? location;

  /// Optional structured diagnostics payload. When present, UI layers can show
  /// actionable suggestions/highlights without parsing [message].
  final ValidationDiagnostic? diagnostic;

  const ValidationIssue(
    this.code,
    this.message, {
    this.location,
    this.diagnostic,
  });
}

class InputValidators {
  static List<ValidationIssue> validateFSA(FSA fsa) {
    final issues = <ValidationIssue>[];

    // Basic structure validation
    if (fsa.states.isEmpty) {
      issues.add(const ValidationIssue('FSA_EMPTY', 'Automaton has no states'));
    }
    if (fsa.initialState == null) {
      issues.add(
        const ValidationIssue(
          'FSA_NO_INITIAL',
          'Automaton has no initial state',
        ),
      );
    } else if (!fsa.states.contains(fsa.initialState)) {
      issues.add(
        ValidationIssue(
          'FSA_INVALID_INITIAL',
          'Initial state ${fsa.initialState!.id} is not in states set',
        ),
      );
    }

    // Alphabet validation
    if (fsa.alphabet.isEmpty) {
      issues.add(
        const ValidationIssue(
          'FSA_EMPTY_ALPHABET',
          'Automaton has no alphabet',
        ),
      );
    }

    // State validation
    for (final state in fsa.acceptingStates) {
      if (!fsa.states.contains(state)) {
        issues.add(
          ValidationIssue(
            'FSA_INVALID_ACCEPTING',
            'Accepting state ${state.id} is not in states set',
          ),
        );
      }
    }

    // Transition validation
    for (final t in fsa.transitions) {
      if (t is! FSATransition) continue;
      if (!fsa.states.contains(t.fromState)) {
        issues.add(
          ValidationIssue(
            'FSA_BAD_FROM',
            'Transition from unknown state ${t.fromState.id}',
          ),
        );
      }
      if (!fsa.states.contains(t.toState)) {
        issues.add(
          ValidationIssue(
            'FSA_BAD_TO',
            'Transition to unknown state ${t.toState.id}',
          ),
        );
      }
      if (!fsa.alphabet.contains(t.symbol)) {
        issues.add(
          ValidationIssue(
            'FSA_BAD_SYMBOL',
            'Transition uses symbol "${t.symbol}" not in alphabet',
          ),
        );
      }
    }

    // Determinism validation
    final transitionMap = <String, Map<String, List<FSATransition>>>{};
    for (final t in fsa.transitions) {
      if (t is! FSATransition) continue;
      transitionMap.putIfAbsent(t.fromState.id, () => {});
      transitionMap[t.fromState.id]!.putIfAbsent(t.symbol, () => []);
      transitionMap[t.fromState.id]![t.symbol]!.add(t);
    }

    for (final stateId in transitionMap.keys) {
      for (final symbol in transitionMap[stateId]!.keys) {
        final transitions = transitionMap[stateId]![symbol]!;
        if (transitions.length > 1) {
          issues.add(
            ValidationIssue(
              'FSA_NONDETERMINISTIC',
              'State $stateId has ${transitions.length} transitions on symbol "$symbol"',
            ),
          );
        }
      }
    }

    return issues;
  }

  static List<ValidationIssue> validatePDA(PDA pda) {
    final issues = <ValidationIssue>[];

    // Basic structure validation
    if (pda.states.isEmpty) {
      issues.add(const ValidationIssue('PDA_EMPTY', 'PDA has no states'));
    }
    if (pda.initialState == null) {
      issues.add(
        const ValidationIssue('PDA_NO_INITIAL', 'PDA has no initial state'),
      );
    } else if (!pda.states.contains(pda.initialState)) {
      issues.add(
        ValidationIssue(
          'PDA_INVALID_INITIAL',
          'Initial state ${pda.initialState!.id} is not in states set',
        ),
      );
    }
    if (pda.acceptingStates.isEmpty) {
      issues.add(
        const ValidationIssue(
          'PDA_NO_ACCEPTING',
          'PDA has no accepting states',
        ),
      );
    }

    // Alphabet validation
    if (pda.alphabet.isEmpty) {
      issues.add(
        const ValidationIssue(
          'PDA_EMPTY_INPUT_ALPHABET',
          'PDA has no input alphabet',
        ),
      );
    }
    if (pda.stackAlphabet.isEmpty) {
      issues.add(
        const ValidationIssue(
          'PDA_EMPTY_STACK_ALPHABET',
          'PDA has no stack alphabet',
        ),
      );
    }
    if (!pda.stackAlphabet.contains(pda.initialStackSymbol)) {
      issues.add(
        ValidationIssue(
          'PDA_INVALID_INITIAL_STACK',
          'Initial stack symbol "${pda.initialStackSymbol}" is not in stack alphabet',
        ),
      );
    }

    // State validation
    for (final state in pda.acceptingStates) {
      if (!pda.states.contains(state)) {
        issues.add(
          ValidationIssue(
            'PDA_INVALID_ACCEPTING',
            'Accepting state ${state.id} is not in states set',
          ),
        );
      }
    }

    // Transition validation
    for (final t in pda.transitions) {
      if (t is! PDATransition) continue;
      if (!pda.states.contains(t.fromState)) {
        issues.add(
          ValidationIssue(
            'PDA_BAD_FROM',
            'Transition from unknown state ${t.fromState.id}',
          ),
        );
      }
      if (!pda.states.contains(t.toState)) {
        issues.add(
          ValidationIssue(
            'PDA_BAD_TO',
            'Transition to unknown state ${t.toState.id}',
          ),
        );
      }
      if (!pda.alphabet.contains(t.inputSymbol) && t.inputSymbol != 'ε') {
        issues.add(
          ValidationIssue(
            'PDA_BAD_INPUT_SYMBOL',
            'Transition uses input symbol "${t.inputSymbol}" not in input alphabet',
          ),
        );
      }
      if (!pda.stackAlphabet.contains(t.popSymbol) && t.popSymbol != 'ε') {
        issues.add(
          ValidationIssue(
            'PDA_BAD_STACK_SYMBOL',
            'Transition uses stack symbol "${t.popSymbol}" not in stack alphabet',
          ),
        );
      }
      for (final pushSymbol in t.pushSymbols) {
        if (!pda.stackAlphabet.contains(pushSymbol) && pushSymbol != 'ε') {
          issues.add(
            ValidationIssue(
              'PDA_BAD_PUSH_SYMBOL',
              'Transition pushes symbol "$pushSymbol" not in stack alphabet',
            ),
          );
        }
      }
    }

    return issues;
  }

  static List<ValidationIssue> validateGrammar(Grammar grammar) {
    final issues = <ValidationIssue>[];

    // Basic structure validation
    if (grammar.productions.isEmpty) {
      issues.add(
        const ValidationIssue('CFG_EMPTY', 'Grammar has no productions'),
      );
    }
    if (grammar.nonTerminals.isEmpty) {
      issues.add(
        const ValidationIssue(
          'CFG_NO_NONTERMINALS',
          'Grammar has no non-terminals',
        ),
      );
    }
    if (grammar.terminals.isEmpty) {
      issues.add(
        const ValidationIssue('CFG_NO_TERMINALS', 'Grammar has no terminals'),
      );
    }

    // Start symbol validation
    if (grammar.startSymbol.isEmpty) {
      issues.add(
        const ValidationIssue('CFG_EMPTY_START', 'Start symbol is empty'),
      );
    } else if (!grammar.nonTerminals.contains(grammar.startSymbol)) {
      issues.add(
        ValidationIssue(
          'CFG_BAD_START',
          'Start symbol "${grammar.startSymbol}" must be a non-terminal',
        ),
      );
    }

    // Production validation
    final productions = grammar.productions.toList();
    for (int i = 0; i < productions.length; i++) {
      final production = productions[i];

      if (production.leftSide.isEmpty) {
        issues.add(
          ValidationIssue(
            'CFG_EMPTY_LEFT',
            'Production $i has empty left side',
            location: 'production[$i]',
          ),
        );
      } else if (!grammar.nonTerminals.contains(production.leftSide.first)) {
        issues.add(
          ValidationIssue(
            'CFG_BAD_LEFT',
            'Production $i left side "${production.leftSide.first}" is not a non-terminal',
            location: 'production[$i]',
          ),
        );
      }

      if (production.rightSide.isEmpty) {
        issues.add(
          ValidationIssue(
            'CFG_EMPTY_RIGHT',
            'Production $i has empty right side',
            location: 'production[$i]',
          ),
        );
      } else {
        for (final symbol in production.rightSide) {
          if (symbol.isNotEmpty &&
              !grammar.nonTerminals.contains(symbol) &&
              !grammar.terminals.contains(symbol)) {
            issues.add(
              ValidationIssue(
                'CFG_BAD_SYMBOL',
                'Production $i contains unknown symbol "$symbol"',
                location: 'production[$i]',
              ),
            );
          }
        }
      }
    }

    return issues;
  }

  static List<ValidationIssue> validateTM(TM tm) {
    final issues = <ValidationIssue>[];

    // Basic structure validation
    if (tm.states.isEmpty) {
      issues.add(const ValidationIssue('TM_EMPTY', 'TM has no states'));
    }
    if (tm.initialState == null) {
      issues.add(
        const ValidationIssue('TM_NO_INITIAL', 'TM has no initial state'),
      );
    } else if (!tm.states.contains(tm.initialState)) {
      issues.add(
        ValidationIssue(
          'TM_INVALID_INITIAL',
          'Initial state ${tm.initialState!.id} is not in states set',
        ),
      );
    }
    if (tm.acceptingStates.isEmpty) {
      issues.add(
        const ValidationIssue('TM_NO_ACCEPTING', 'TM has no accepting states'),
      );
    }

    // Alphabet validation
    if (tm.alphabet.isEmpty) {
      issues.add(
        const ValidationIssue(
          'TM_EMPTY_INPUT_ALPHABET',
          'TM has no input alphabet',
        ),
      );
    }
    if (tm.tapeAlphabet.isEmpty) {
      issues.add(
        const ValidationIssue(
          'TM_EMPTY_TAPE_ALPHABET',
          'TM has no tape alphabet',
        ),
      );
    }
    if (tm.blankSymbol.isEmpty) {
      issues.add(
        const ValidationIssue('TM_EMPTY_BLANK', 'Blank symbol is empty'),
      );
    } else if (!tm.tapeAlphabet.contains(tm.blankSymbol)) {
      issues.add(
        ValidationIssue(
          'TM_BLANK_NOT_IN_TAPE',
          'Blank symbol "${tm.blankSymbol}" is not in tape alphabet',
        ),
      );
    }

    // Ensure input alphabet is subset of tape alphabet
    for (final symbol in tm.alphabet) {
      if (!tm.tapeAlphabet.contains(symbol)) {
        issues.add(
          ValidationIssue(
            'TM_INPUT_NOT_IN_TAPE',
            'Input symbol "$symbol" is not in tape alphabet',
          ),
        );
      }
    }

    // State validation
    for (final state in tm.acceptingStates) {
      if (!tm.states.contains(state)) {
        issues.add(
          ValidationIssue(
            'TM_INVALID_ACCEPTING',
            'Accepting state ${state.id} is not in states set',
          ),
        );
      }
    }

    // Transition validation
    for (final t in tm.transitions) {
      if (t is! TMTransition) continue;
      if (!tm.states.contains(t.fromState)) {
        issues.add(
          ValidationIssue(
            'TM_BAD_FROM',
            'Transition from unknown state ${t.fromState.id}',
          ),
        );
      }
      if (!tm.states.contains(t.toState)) {
        issues.add(
          ValidationIssue(
            'TM_BAD_TO',
            'Transition to unknown state ${t.toState.id}',
          ),
        );
      }
      if (!tm.tapeAlphabet.contains(t.readSymbol)) {
        issues.add(
          ValidationIssue(
            'TM_BAD_READ_SYMBOL',
            'Transition reads symbol "${t.readSymbol}" not in tape alphabet',
          ),
        );
      }
      if (!tm.tapeAlphabet.contains(t.writeSymbol)) {
        issues.add(
          ValidationIssue(
            'TM_BAD_WRITE_SYMBOL',
            'Transition writes symbol "${t.writeSymbol}" not in tape alphabet',
          ),
        );
      }
      final direction = t.direction.toString();
      if (direction != 'TapeDirection.left' &&
          direction != 'TapeDirection.right' &&
          direction != 'TapeDirection.stay') {
        issues.add(
          ValidationIssue(
            'TM_BAD_MOVE',
            'Transition has invalid move direction "$direction"',
          ),
        );
      }
    }

    return issues;
  }

  /// Validates input string against automaton alphabet
  static List<ValidationIssue> validateInputString(
    String input,
    Set<String> alphabet,
  ) {
    final issues = <ValidationIssue>[];

    if (input.isEmpty) {
      issues.add(const ValidationIssue('INPUT_EMPTY', 'Input string is empty'));
    }

    for (int i = 0; i < input.length; i++) {
      final symbol = input[i];
      if (!alphabet.contains(symbol)) {
        issues.add(
          ValidationIssue(
            'INPUT_INVALID_SYMBOL',
            'Input contains invalid symbol "$symbol" at position $i',
            location: 'position[$i]',
          ),
        );
      }
    }

    return issues;
  }

  /// Gets a summary of validation issues
  static String getValidationSummary(List<ValidationIssue> issues) {
    if (issues.isEmpty) {
      return 'No validation issues found';
    }

    final errorCount = issues
        .where((i) => i.code.contains('_EMPTY') || i.code.contains('_NO_'))
        .length;
    final warningCount = issues.length - errorCount;

    final summary = StringBuffer();
    summary.writeln('Validation found ${issues.length} issue(s):');
    if (errorCount > 0) summary.writeln('  • $errorCount error(s)');
    if (warningCount > 0) summary.writeln('  • $warningCount warning(s)');

    return summary.toString();
  }

  /// Checks if validation issues contain any errors (not just warnings)
  static bool hasErrors(List<ValidationIssue> issues) {
    return issues.any(
      (issue) =>
          issue.code.contains('_EMPTY') ||
          issue.code.contains('_NO_') ||
          issue.code.contains('_INVALID_') ||
          issue.code.contains('_BAD_'),
    );
  }
}
