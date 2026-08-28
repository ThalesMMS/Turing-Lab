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
import '../models/pda_acceptance_mode.dart';
import '../models/pda_transition.dart';
import '../models/tm.dart';
import '../models/tm_acceptance.dart';
import '../models/tm_transition.dart';
import '../models/grammar.dart';
import '../models/validation_diagnostic.dart';
import '../messages/structured_message.dart';
import 'validation_messages.dart';

class ValidationIssue {
  final String code;
  final String message;
  final String? location;

  /// Optional structured diagnostics payload. When present, UI layers can show
  /// actionable suggestions/highlights without parsing [message].
  final ValidationDiagnostic? diagnostic;

  /// Optional locale-neutral semantic message for presentation resolvers.
  final StructuredMessage? structuredMessage;

  const ValidationIssue(
    this.code,
    this.message, {
    this.location,
    this.diagnostic,
    this.structuredMessage,
  });
}

ValidationIssue _structuredIssue(
  String code,
  String message, {
  String? location,
  Map<String, StructuredMessageArgument> arguments = const {},
}) => ValidationIssue(
  code,
  message,
  location: location,
  structuredMessage: ValidationMessages.forCode(code, arguments: arguments),
);

class InputValidators {
  static List<ValidationIssue> validateFSA(FSA fsa) {
    final issues = <ValidationIssue>[];

    // Basic structure validation
    if (fsa.states.isEmpty) {
      issues.add(_structuredIssue('FSA_EMPTY', 'Automaton has no states'));
    }
    if (fsa.initialState == null) {
      issues.add(
        _structuredIssue('FSA_NO_INITIAL', 'Automaton has no initial state'),
      );
    } else if (!fsa.states.contains(fsa.initialState)) {
      issues.add(
        _structuredIssue(
          'FSA_INVALID_INITIAL',
          'Initial state ${fsa.initialState!.id} is not in states set',
          arguments: {
            'state': StructuredMessageArgument.identifier(
              fsa.initialState!.id,
              role: 'state-id',
            ),
          },
        ),
      );
    }

    // Alphabet validation
    if (fsa.alphabet.isEmpty) {
      issues.add(
        _structuredIssue('FSA_EMPTY_ALPHABET', 'Automaton has no alphabet'),
      );
    }

    // State validation
    for (final state in fsa.acceptingStates) {
      if (!fsa.states.contains(state)) {
        issues.add(
          _structuredIssue(
            'FSA_INVALID_ACCEPTING',
            'Accepting state ${state.id} is not in states set',
            arguments: {
              'state': StructuredMessageArgument.identifier(
                state.id,
                role: 'state-id',
              ),
            },
          ),
        );
      }
    }

    // Transition validation
    for (final t in fsa.transitions) {
      if (t is! FSATransition) continue;
      if (!fsa.states.contains(t.fromState)) {
        issues.add(
          _structuredIssue(
            'FSA_BAD_FROM',
            'Transition from unknown state ${t.fromState.id}',
            arguments: {
              'state': StructuredMessageArgument.identifier(
                t.fromState.id,
                role: 'state-id',
              ),
            },
          ),
        );
      }
      if (!fsa.states.contains(t.toState)) {
        issues.add(
          _structuredIssue(
            'FSA_BAD_TO',
            'Transition to unknown state ${t.toState.id}',
            arguments: {
              'state': StructuredMessageArgument.identifier(
                t.toState.id,
                role: 'state-id',
              ),
            },
          ),
        );
      }
      if (!fsa.alphabet.contains(t.symbol)) {
        issues.add(
          _structuredIssue(
            'FSA_BAD_SYMBOL',
            'Transition uses symbol "${t.symbol}" not in alphabet',
            arguments: {
              'symbol': StructuredMessageArgument.symbol(
                t.symbol,
                role: 'input-symbol',
              ),
            },
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
            _structuredIssue(
              'FSA_NONDETERMINISTIC',
              'State $stateId has ${transitions.length} transitions on symbol "$symbol"',
              arguments: {
                'state': StructuredMessageArgument.identifier(
                  stateId,
                  role: 'state-id',
                ),
                'count': StructuredMessageArgument.count(
                  transitions.length,
                  role: 'transition-count',
                ),
                'symbol': StructuredMessageArgument.symbol(
                  symbol,
                  role: 'input-symbol',
                ),
              },
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
      issues.add(_structuredIssue('PDA_EMPTY', 'PDA has no states'));
    }
    if (pda.initialState == null) {
      issues.add(
        _structuredIssue('PDA_NO_INITIAL', 'PDA has no initial state'),
      );
    } else if (!pda.states.contains(pda.initialState)) {
      issues.add(
        _structuredIssue(
          'PDA_INVALID_INITIAL',
          'Initial state ${pda.initialState!.id} is not in states set',
          arguments: {
            'state': StructuredMessageArgument.identifier(
              pda.initialState!.id,
              role: 'state-id',
            ),
          },
        ),
      );
    }
    if (pda.acceptanceMode != PDAAcceptanceMode.emptyStack &&
        pda.acceptingStates.isEmpty) {
      issues.add(
        _structuredIssue('PDA_NO_ACCEPTING', 'PDA has no accepting states'),
      );
    }

    // Alphabet validation
    if (pda.alphabet.isEmpty) {
      issues.add(
        _structuredIssue(
          'PDA_EMPTY_INPUT_ALPHABET',
          'PDA has no input alphabet',
        ),
      );
    }
    if (pda.stackAlphabet.isEmpty) {
      issues.add(
        _structuredIssue(
          'PDA_EMPTY_STACK_ALPHABET',
          'PDA has no stack alphabet',
        ),
      );
    }
    if (!pda.stackAlphabet.contains(pda.initialStackSymbol)) {
      issues.add(
        _structuredIssue(
          'PDA_INVALID_INITIAL_STACK',
          'Initial stack symbol "${pda.initialStackSymbol}" is not in stack alphabet',
          arguments: {
            'symbol': StructuredMessageArgument.symbol(
              pda.initialStackSymbol,
              role: 'stack-symbol',
            ),
          },
        ),
      );
    }

    // State validation
    for (final state in pda.acceptingStates) {
      if (!pda.states.contains(state)) {
        issues.add(
          _structuredIssue(
            'PDA_INVALID_ACCEPTING',
            'Accepting state ${state.id} is not in states set',
            arguments: {
              'state': StructuredMessageArgument.identifier(
                state.id,
                role: 'state-id',
              ),
            },
          ),
        );
      }
    }

    // Transition validation
    for (final t in pda.transitions) {
      if (t is! PDATransition) continue;
      if (!pda.states.contains(t.fromState)) {
        issues.add(
          _structuredIssue(
            'PDA_BAD_FROM',
            'Transition from unknown state ${t.fromState.id}',
            arguments: {
              'state': StructuredMessageArgument.identifier(
                t.fromState.id,
                role: 'state-id',
              ),
            },
          ),
        );
      }
      if (!pda.states.contains(t.toState)) {
        issues.add(
          _structuredIssue(
            'PDA_BAD_TO',
            'Transition to unknown state ${t.toState.id}',
            arguments: {
              'state': StructuredMessageArgument.identifier(
                t.toState.id,
                role: 'state-id',
              ),
            },
          ),
        );
      }
      if (!pda.alphabet.contains(t.inputSymbol) && t.inputSymbol != 'ε') {
        issues.add(
          _structuredIssue(
            'PDA_BAD_INPUT_SYMBOL',
            'Transition uses input symbol "${t.inputSymbol}" not in input alphabet',
            arguments: {
              'symbol': StructuredMessageArgument.symbol(
                t.inputSymbol,
                role: 'input-symbol',
              ),
            },
          ),
        );
      }
      if (!pda.stackAlphabet.contains(t.popSymbol) && t.popSymbol != 'ε') {
        issues.add(
          _structuredIssue(
            'PDA_BAD_STACK_SYMBOL',
            'Transition uses stack symbol "${t.popSymbol}" not in stack alphabet',
            arguments: {
              'symbol': StructuredMessageArgument.symbol(
                t.popSymbol,
                role: 'stack-symbol',
              ),
            },
          ),
        );
      }
      for (final pushSymbol in t.pushSymbols) {
        if (!pda.stackAlphabet.contains(pushSymbol) && pushSymbol != 'ε') {
          issues.add(
            _structuredIssue(
              'PDA_BAD_PUSH_SYMBOL',
              'Transition pushes symbol "$pushSymbol" not in stack alphabet',
              arguments: {
                'symbol': StructuredMessageArgument.symbol(
                  pushSymbol,
                  role: 'stack-symbol',
                ),
              },
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
      issues.add(_structuredIssue('CFG_EMPTY', 'Grammar has no productions'));
    }
    if (grammar.nonTerminals.isEmpty) {
      issues.add(
        _structuredIssue('CFG_NO_NONTERMINALS', 'Grammar has no non-terminals'),
      );
    }
    if (grammar.terminals.isEmpty) {
      issues.add(
        _structuredIssue('CFG_NO_TERMINALS', 'Grammar has no terminals'),
      );
    }

    // Start symbol validation
    if (grammar.startSymbol.isEmpty) {
      issues.add(_structuredIssue('CFG_EMPTY_START', 'Start symbol is empty'));
    } else if (!grammar.nonTerminals.contains(grammar.startSymbol)) {
      issues.add(
        _structuredIssue(
          'CFG_BAD_START',
          'Start symbol "${grammar.startSymbol}" must be a non-terminal',
          arguments: {
            'symbol': StructuredMessageArgument.symbol(
              grammar.startSymbol,
              role: 'start-symbol',
            ),
          },
        ),
      );
    }

    // Production validation
    final productions = grammar.productions.toList();
    for (int i = 0; i < productions.length; i++) {
      final production = productions[i];

      if (production.leftSide.isEmpty) {
        issues.add(
          _structuredIssue(
            'CFG_EMPTY_LEFT',
            'Production $i has empty left side',
            location: 'production[$i]',
            arguments: {
              'production': StructuredMessageArgument.index(
                i,
                role: 'production-index',
              ),
            },
          ),
        );
      } else if (!grammar.nonTerminals.contains(production.leftSide.first)) {
        issues.add(
          _structuredIssue(
            'CFG_BAD_LEFT',
            'Production $i left side "${production.leftSide.first}" is not a non-terminal',
            location: 'production[$i]',
            arguments: {
              'production': StructuredMessageArgument.index(
                i,
                role: 'production-index',
              ),
              'symbol': StructuredMessageArgument.symbol(
                production.leftSide.first,
                role: 'grammar-symbol',
              ),
            },
          ),
        );
      }

      if (production.rightSide.isEmpty) {
        issues.add(
          _structuredIssue(
            'CFG_EMPTY_RIGHT',
            'Production $i has empty right side',
            location: 'production[$i]',
            arguments: {
              'production': StructuredMessageArgument.index(
                i,
                role: 'production-index',
              ),
            },
          ),
        );
      } else {
        for (final symbol in production.rightSide) {
          if (symbol.isNotEmpty &&
              !grammar.nonTerminals.contains(symbol) &&
              !grammar.terminals.contains(symbol)) {
            issues.add(
              _structuredIssue(
                'CFG_BAD_SYMBOL',
                'Production $i contains unknown symbol "$symbol"',
                location: 'production[$i]',
                arguments: {
                  'production': StructuredMessageArgument.index(
                    i,
                    role: 'production-index',
                  ),
                  'symbol': StructuredMessageArgument.symbol(
                    symbol,
                    role: 'grammar-symbol',
                  ),
                },
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
      issues.add(_structuredIssue('TM_EMPTY', 'TM has no states'));
    }
    if (tm.initialState == null) {
      issues.add(_structuredIssue('TM_NO_INITIAL', 'TM has no initial state'));
    } else if (!tm.states.contains(tm.initialState)) {
      issues.add(
        _structuredIssue(
          'TM_INVALID_INITIAL',
          'Initial state ${tm.initialState!.id} is not in states set',
          arguments: {
            'state': StructuredMessageArgument.identifier(
              tm.initialState!.id,
              role: 'state-id',
            ),
          },
        ),
      );
    }
    if (tm.acceptancePolicy == TMAcceptancePolicy.finalState &&
        tm.acceptingStates.isEmpty) {
      issues.add(
        _structuredIssue('TM_NO_ACCEPTING', 'TM has no accepting states'),
      );
    }

    // Alphabet validation
    if (tm.alphabet.isEmpty) {
      issues.add(
        _structuredIssue('TM_EMPTY_INPUT_ALPHABET', 'TM has no input alphabet'),
      );
    }
    if (tm.tapeAlphabet.isEmpty) {
      issues.add(
        _structuredIssue('TM_EMPTY_TAPE_ALPHABET', 'TM has no tape alphabet'),
      );
    }
    if (tm.blankSymbol.isEmpty) {
      issues.add(_structuredIssue('TM_EMPTY_BLANK', 'Blank symbol is empty'));
    } else if (!tm.tapeAlphabet.contains(tm.blankSymbol)) {
      issues.add(
        _structuredIssue(
          'TM_BLANK_NOT_IN_TAPE',
          'Blank symbol "${tm.blankSymbol}" is not in tape alphabet',
          arguments: {
            'symbol': StructuredMessageArgument.symbol(
              tm.blankSymbol,
              role: 'blank-symbol',
            ),
          },
        ),
      );
    }

    // Ensure input alphabet is subset of tape alphabet
    for (final symbol in tm.alphabet) {
      if (!tm.tapeAlphabet.contains(symbol)) {
        issues.add(
          _structuredIssue(
            'TM_INPUT_NOT_IN_TAPE',
            'Input symbol "$symbol" is not in tape alphabet',
            arguments: {
              'symbol': StructuredMessageArgument.symbol(
                symbol,
                role: 'input-symbol',
              ),
            },
          ),
        );
      }
    }

    // State validation
    for (final state in tm.acceptingStates) {
      if (!tm.states.contains(state)) {
        issues.add(
          _structuredIssue(
            'TM_INVALID_ACCEPTING',
            'Accepting state ${state.id} is not in states set',
            arguments: {
              'state': StructuredMessageArgument.identifier(
                state.id,
                role: 'state-id',
              ),
            },
          ),
        );
      }
    }

    // Transition validation
    for (final t in tm.transitions) {
      if (t is! TMTransition) continue;
      if (!tm.states.contains(t.fromState)) {
        issues.add(
          _structuredIssue(
            'TM_BAD_FROM',
            'Transition from unknown state ${t.fromState.id}',
            arguments: {
              'state': StructuredMessageArgument.identifier(
                t.fromState.id,
                role: 'state-id',
              ),
            },
          ),
        );
      }
      if (!tm.states.contains(t.toState)) {
        issues.add(
          _structuredIssue(
            'TM_BAD_TO',
            'Transition to unknown state ${t.toState.id}',
            arguments: {
              'state': StructuredMessageArgument.identifier(
                t.toState.id,
                role: 'state-id',
              ),
            },
          ),
        );
      }
      if (!tm.tapeAlphabet.contains(t.readSymbol)) {
        issues.add(
          _structuredIssue(
            'TM_BAD_READ_SYMBOL',
            'Transition reads symbol "${t.readSymbol}" not in tape alphabet',
            arguments: {
              'symbol': StructuredMessageArgument.symbol(
                t.readSymbol,
                role: 'tape-symbol',
              ),
            },
          ),
        );
      }
      if (!tm.tapeAlphabet.contains(t.writeSymbol)) {
        issues.add(
          _structuredIssue(
            'TM_BAD_WRITE_SYMBOL',
            'Transition writes symbol "${t.writeSymbol}" not in tape alphabet',
            arguments: {
              'symbol': StructuredMessageArgument.symbol(
                t.writeSymbol,
                role: 'tape-symbol',
              ),
            },
          ),
        );
      }
      final direction = t.direction.toString();
      if (direction != 'TapeDirection.left' &&
          direction != 'TapeDirection.right' &&
          direction != 'TapeDirection.stay') {
        issues.add(
          _structuredIssue(
            'TM_BAD_MOVE',
            'Transition has invalid move direction "$direction"',
            arguments: {
              'direction': StructuredMessageArgument.literal(
                direction,
                role: 'move-direction',
              ),
            },
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
      issues.add(_structuredIssue('INPUT_EMPTY', 'Input string is empty'));
    }

    for (int i = 0; i < input.length; i++) {
      final symbol = input[i];
      if (!alphabet.contains(symbol)) {
        issues.add(
          _structuredIssue(
            'INPUT_INVALID_SYMBOL',
            'Input contains invalid symbol "$symbol" at position $i',
            location: 'position[$i]',
            arguments: {
              'symbol': StructuredMessageArgument.symbol(
                symbol,
                role: 'input-symbol',
              ),
              'position': StructuredMessageArgument.index(
                i,
                role: 'input-position',
              ),
            },
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
