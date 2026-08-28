//
//  validation_issue_to_diagnostic.dart
//  Turing Lab
//
//  Adapter for converting existing ValidationIssue (string-based) into the
//  richer ValidationDiagnostic model used by UI overlays.
//

import '../models/step_explanation.dart' show SuggestedFix;
import '../models/validation_diagnostic.dart';
import 'input_validators.dart';

class ValidationIssueToDiagnostic {
  /// Converts a [ValidationIssue] (legacy) to a structured [ValidationDiagnostic].
  static ValidationDiagnostic fromIssue(ValidationIssue issue) {
    final explicit = issue.diagnostic;
    if (explicit != null) {
      final message = issue.structuredMessage;
      if (message != null && explicit.structuredMessage == null) {
        return explicit.copyWith(structuredMessage: message);
      }
      return explicit;
    }

    final diagnostic = _mapIssue(issue);
    final message = issue.structuredMessage;
    if (message == null) {
      return diagnostic;
    }
    return diagnostic.copyWith(structuredMessage: message);
  }

  static ValidationDiagnostic _mapIssue(ValidationIssue issue) {
    final (summary, details) = _splitMessage(issue.message);

    // Keep mapping conservative: attach fixes/highlights only for codes we can
    // reliably interpret without deeper domain context.
    switch (issue.code) {
      // --- FSA ---
      case 'FSA_EMPTY':
        return ValidationDiagnostic(
          code: issue.code,
          summary: summary,
          details: details,
          location: issue.location,
          suggestedFixes: const [
            SuggestedFix(
              label: 'Add at least one state',
              details:
                  'Create a state on the canvas before adding transitions.',
              actionId: 'canvas.addState',
            ),
          ],
        );

      case 'FSA_NO_INITIAL':
        return ValidationDiagnostic(
          code: issue.code,
          summary: summary,
          details: details,
          location: issue.location,
          suggestedFixes: const [
            SuggestedFix(
              label: 'Mark a start state',
              details: 'Select a state and set it as the initial/start state.',
              actionId: 'canvas.setInitialState',
            ),
          ],
        );

      case 'FSA_INVALID_INITIAL':
        return ValidationDiagnostic(
          code: issue.code,
          summary: summary,
          details: details,
          location: issue.location,
          suggestedFixes: const [
            SuggestedFix(
              label: 'Reassign the start state to an existing state',
              details:
                  'Pick an existing state and mark it as the initial state.',
              actionId: 'canvas.setInitialState',
            ),
          ],
        );

      case 'FSA_EMPTY_ALPHABET':
        return ValidationDiagnostic(
          code: issue.code,
          summary: summary,
          details: details,
          location: issue.location,
          suggestedFixes: const [
            SuggestedFix(
              label: 'Define an alphabet',
              details:
                  'Add at least one symbol to the automaton alphabet before creating transitions.',
              actionId: 'fsa.editAlphabet',
            ),
          ],
        );

      case 'FSA_BAD_SYMBOL':
        return ValidationDiagnostic(
          code: issue.code,
          summary: summary,
          details: details,
          location: issue.location,
          suggestedFixes: const [
            SuggestedFix(
              label: 'Add the symbol to the alphabet',
              details:
                  'Either add the transition symbol to the automaton alphabet, or edit the transition to use an existing symbol.',
              actionId: 'fsa.editAlphabetOrTransition',
            ),
          ],
        );

      case 'FSA_NONDETERMINISTIC':
        return ValidationDiagnostic(
          code: issue.code,
          summary: summary,
          details: details,
          location: issue.location,
          suggestedFixes: const [
            SuggestedFix(
              label: 'Make transitions deterministic',
              details:
                  'For a DFA, each state must have at most one outgoing transition per symbol. Remove or merge duplicates (or switch to NFA simulation).',
              actionId: 'fsa.makeDeterministic',
            ),
          ],
        );

      case 'FSA_INVALID_ACCEPTING':
        return ValidationDiagnostic(
          code: issue.code,
          summary: summary,
          details: details,
          location: issue.location,
          suggestedFixes: const [
            SuggestedFix(
              label: 'Fix accepting state reference',
              details:
                  'An accepting state reference is invalid. Re-select the accepting states from the current set of states.',
              actionId: 'fsa.fixAcceptingStates',
            ),
          ],
        );

      // --- PDA ---
      case 'PDA_EMPTY':
        return ValidationDiagnostic(
          code: issue.code,
          summary: summary,
          details: details,
          location: issue.location,
          suggestedFixes: const [
            SuggestedFix(
              label: 'Add at least one state',
              details:
                  'Create a state on the canvas before adding transitions.',
              actionId: 'canvas.addState',
            ),
          ],
        );

      case 'PDA_NO_INITIAL':
        return ValidationDiagnostic(
          code: issue.code,
          summary: summary,
          details: details,
          location: issue.location,
          suggestedFixes: const [
            SuggestedFix(
              label: 'Mark a start state',
              details: 'Select a state and set it as the initial/start state.',
              actionId: 'canvas.setInitialState',
            ),
          ],
        );

      case 'PDA_NO_ACCEPTING':
        return ValidationDiagnostic(
          code: issue.code,
          summary: summary,
          details: details,
          location: issue.location,
          suggestedFixes: const [
            SuggestedFix(
              label: 'Mark an accepting state',
              details:
                  'If this PDA uses final-state acceptance, mark one or more states as accepting.',
              actionId: 'canvas.toggleAcceptingState',
            ),
          ],
        );

      case 'PDA_EMPTY_INPUT_ALPHABET':
        return ValidationDiagnostic(
          code: issue.code,
          summary: summary,
          details: details,
          location: issue.location,
          suggestedFixes: const [
            SuggestedFix(
              label: 'Define the input alphabet',
              details:
                  'Add at least one input symbol to the PDA alphabet (ε transitions do not need to be in the alphabet).',
              actionId: 'pda.editAlphabet',
            ),
          ],
        );

      case 'PDA_EMPTY_STACK_ALPHABET':
        return ValidationDiagnostic(
          code: issue.code,
          summary: summary,
          details: details,
          location: issue.location,
          suggestedFixes: const [
            SuggestedFix(
              label: 'Define the stack alphabet',
              details:
                  'Add stack symbols (including the bottom marker, if you use one) to the stack alphabet.',
              actionId: 'pda.editStackAlphabet',
            ),
          ],
        );

      case 'PDA_INVALID_INITIAL_STACK':
        return ValidationDiagnostic(
          code: issue.code,
          summary: summary,
          details: details,
          location: issue.location,
          suggestedFixes: const [
            SuggestedFix(
              label: 'Fix the initial stack symbol',
              details:
                  'Choose an initial stack symbol that exists in the stack alphabet (commonly a bottom marker like Z or \$).',
              actionId: 'pda.setInitialStackSymbol',
            ),
          ],
        );

      case 'PDA_BAD_INPUT_SYMBOL':
        return ValidationDiagnostic(
          code: issue.code,
          summary: summary,
          details: details,
          location: issue.location,
          suggestedFixes: const [
            SuggestedFix(
              label: 'Fix the input symbol',
              details:
                  'The transition input symbol must be in the input alphabet, or ε.',
              actionId: 'pda.editTransition',
            ),
          ],
        );

      case 'PDA_BAD_STACK_SYMBOL':
        return ValidationDiagnostic(
          code: issue.code,
          summary: summary,
          details: details,
          location: issue.location,
          suggestedFixes: const [
            SuggestedFix(
              label: 'Fix the stack pop symbol',
              details:
                  'The transition pop symbol must be in the stack alphabet, or ε.',
              actionId: 'pda.editTransition',
            ),
          ],
        );

      case 'PDA_BAD_PUSH_SYMBOL':
        return ValidationDiagnostic(
          code: issue.code,
          summary: summary,
          details: details,
          location: issue.location,
          suggestedFixes: const [
            SuggestedFix(
              label: 'Fix the stack push symbol',
              details:
                  'The transition push symbol must be in the stack alphabet, or ε.',
              actionId: 'pda.editTransition',
            ),
          ],
        );

      // --- TM ---
      case 'TM_EMPTY':
        return ValidationDiagnostic(
          code: issue.code,
          summary: summary,
          details: details,
          location: issue.location,
          suggestedFixes: const [
            SuggestedFix(
              label: 'Add at least one state',
              details:
                  'Create a state on the canvas before adding transitions.',
              actionId: 'canvas.addState',
            ),
          ],
        );

      case 'TM_NO_INITIAL':
        return ValidationDiagnostic(
          code: issue.code,
          summary: summary,
          details: details,
          location: issue.location,
          suggestedFixes: const [
            SuggestedFix(
              label: 'Mark a start state',
              details: 'Select a state and set it as the initial/start state.',
              actionId: 'canvas.setInitialState',
            ),
          ],
        );

      case 'TM_NO_ACCEPTING':
        return ValidationDiagnostic(
          code: issue.code,
          summary: summary,
          details: details,
          location: issue.location,
          suggestedFixes: const [
            SuggestedFix(
              label: 'Mark an accepting (halt) state',
              details:
                  'This TM policy uses final-state acceptance. Mark one or more final states, or select halting acceptance.',
              actionId: 'canvas.toggleAcceptingState',
            ),
          ],
        );

      case 'TM_EMPTY_INPUT_ALPHABET':
        return ValidationDiagnostic(
          code: issue.code,
          summary: summary,
          details: details,
          location: issue.location,
          suggestedFixes: const [
            SuggestedFix(
              label: 'Define the input alphabet',
              details: 'Add input symbols that may appear in the input string.',
              actionId: 'tm.editAlphabet',
            ),
          ],
        );

      case 'TM_EMPTY_TAPE_ALPHABET':
        return ValidationDiagnostic(
          code: issue.code,
          summary: summary,
          details: details,
          location: issue.location,
          suggestedFixes: const [
            SuggestedFix(
              label: 'Define the tape alphabet',
              details:
                  'Add tape symbols (including the blank symbol) used by transitions.',
              actionId: 'tm.editTapeAlphabet',
            ),
          ],
        );

      case 'TM_EMPTY_BLANK':
        return ValidationDiagnostic(
          code: issue.code,
          summary: summary,
          details: details,
          location: issue.location,
          suggestedFixes: const [
            SuggestedFix(
              label: 'Set a blank symbol',
              details:
                  'Choose a single character (commonly "_" or "□") as the blank symbol.',
              actionId: 'tm.setBlankSymbol',
            ),
          ],
        );

      case 'TM_BLANK_NOT_IN_TAPE':
        return ValidationDiagnostic(
          code: issue.code,
          summary: summary,
          details: details,
          location: issue.location,
          suggestedFixes: const [
            SuggestedFix(
              label: 'Add blank symbol to tape alphabet',
              details:
                  'Ensure the blank symbol is included in the tape alphabet.',
              actionId: 'tm.editTapeAlphabet',
            ),
          ],
        );

      case 'TM_INPUT_NOT_IN_TAPE':
        return ValidationDiagnostic(
          code: issue.code,
          summary: summary,
          details: details,
          location: issue.location,
          suggestedFixes: const [
            SuggestedFix(
              label: 'Make input alphabet a subset of tape alphabet',
              details:
                  'Every input symbol must also be present in the tape alphabet.',
              actionId: 'tm.syncAlphabets',
            ),
          ],
        );

      case 'TM_BAD_READ_SYMBOL':
      case 'TM_BAD_WRITE_SYMBOL':
        return ValidationDiagnostic(
          code: issue.code,
          summary: summary,
          details: details,
          location: issue.location,
          suggestedFixes: const [
            SuggestedFix(
              label: 'Fix tape symbols in transition',
              details:
                  'Transition read/write symbols must be part of the tape alphabet.',
              actionId: 'tm.editTransition',
            ),
          ],
        );

      // --- CFG ---
      case 'CFG_EMPTY':
        return ValidationDiagnostic(
          code: issue.code,
          summary: summary,
          details: details,
          location: issue.location,
          suggestedFixes: const [
            SuggestedFix(
              label: 'Add at least one production',
              details:
                  'Create productions like S → aS | ε to define the grammar language.',
              actionId: 'cfg.addProduction',
            ),
          ],
        );

      case 'CFG_EMPTY_START':
        return ValidationDiagnostic(
          code: issue.code,
          summary: summary,
          details: details,
          location: issue.location,
          suggestedFixes: const [
            SuggestedFix(
              label: 'Set the start symbol',
              details:
                  'Choose a start symbol that is one of the grammar non-terminals (commonly S).',
              actionId: 'cfg.setStartSymbol',
            ),
          ],
        );

      case 'CFG_BAD_START':
        return ValidationDiagnostic(
          code: issue.code,
          summary: summary,
          details: details,
          location: issue.location,
          suggestedFixes: const [
            SuggestedFix(
              label: 'Use a non-terminal as start symbol',
              details:
                  'The start symbol must be included in the set of non-terminals.',
              actionId: 'cfg.setStartSymbol',
            ),
          ],
        );

      case 'CFG_EMPTY_LEFT':
      case 'CFG_BAD_LEFT':
      case 'CFG_EMPTY_RIGHT':
      case 'CFG_BAD_SYMBOL':
        return ValidationDiagnostic(
          code: issue.code,
          summary: summary,
          details: details,
          location: issue.location,
          suggestedFixes: const [
            SuggestedFix(
              label: 'Fix the production',
              details:
                  'Ensure the left side starts with a non-terminal and all symbols on the right side are terminals/non-terminals (or ε).',
              actionId: 'cfg.editProduction',
            ),
          ],
        );

      // --- INPUT STRING ---
      case 'INPUT_EMPTY':
        return ValidationDiagnostic(
          code: issue.code,
          summary: summary,
          details: details,
          location: issue.location,
          suggestedFixes: const [
            SuggestedFix(
              label: 'Enter an input string',
              details:
                  'Provide a non-empty input string to simulate, or use ε if you want the empty string (where supported).',
              actionId: 'input.edit',
            ),
          ],
        );

      case 'INPUT_INVALID_SYMBOL':
        return ValidationDiagnostic(
          code: issue.code,
          summary: summary,
          details: details,
          location: issue.location,
          suggestedFixes: const [
            SuggestedFix(
              label: 'Remove or replace the invalid symbol',
              details:
                  'Only symbols in the automaton alphabet are allowed in the input string.',
              actionId: 'input.edit',
            ),
          ],
        );

      default:
        return ValidationDiagnostic(
          code: issue.code,
          summary: summary,
          details: details,
          location: issue.location,
        );
    }
  }

  static (String summary, String? details) _splitMessage(String message) {
    // For now, treat the whole message as summary. If future messages include
    // multi-line details, keep only the first line in summary.
    final lines = message.split('\n');
    if (lines.length <= 1) return (message, null);
    return (lines.first, lines.skip(1).join('\n'));
  }
}
