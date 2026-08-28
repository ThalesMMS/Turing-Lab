import '../messages/structured_message.dart';

/// Locale-neutral messages emitted by the FSA and PDA input validators.
///
/// The legacy validation codes remain the producer-facing API. This companion
/// only supplies their stable wire identity and typed arguments for the
/// presentation layer.
abstract final class ValidationMessages {
  /// Creates a structured payload for an FSA/PDA legacy validation code.
  static StructuredMessage forCode(
    String legacyCode, {
    Map<String, StructuredMessageArgument> arguments = const {},
  }) => StructuredMessage(
    namespace: 'validation',
    code: _wireCode(legacyCode),
    category: StructuredMessageCategory.validation,
    severity: StructuredMessageSeverity.error,
    arguments: arguments,
  );

  static String _wireCode(String legacyCode) => switch (legacyCode) {
    'FSA_EMPTY' => 'fsa-empty',
    'FSA_NO_INITIAL' => 'fsa-no-initial',
    'FSA_INVALID_INITIAL' => 'fsa-invalid-initial',
    'FSA_EMPTY_ALPHABET' => 'fsa-empty-alphabet',
    'FSA_INVALID_ACCEPTING' => 'fsa-invalid-accepting',
    'FSA_BAD_FROM' => 'fsa-bad-from',
    'FSA_BAD_TO' => 'fsa-bad-to',
    'FSA_BAD_SYMBOL' => 'fsa-bad-symbol',
    'FSA_NONDETERMINISTIC' => 'fsa-nondeterministic',
    'PDA_EMPTY' => 'pda-empty',
    'PDA_NO_INITIAL' => 'pda-no-initial',
    'PDA_INVALID_INITIAL' => 'pda-invalid-initial',
    'PDA_NO_ACCEPTING' => 'pda-no-accepting',
    'PDA_EMPTY_INPUT_ALPHABET' => 'pda-empty-input-alphabet',
    'PDA_EMPTY_STACK_ALPHABET' => 'pda-empty-stack-alphabet',
    'PDA_INVALID_INITIAL_STACK' => 'pda-invalid-initial-stack',
    'PDA_INVALID_ACCEPTING' => 'pda-invalid-accepting',
    'PDA_BAD_FROM' => 'pda-bad-from',
    'PDA_BAD_TO' => 'pda-bad-to',
    'PDA_BAD_INPUT_SYMBOL' => 'pda-bad-input-symbol',
    'PDA_BAD_STACK_SYMBOL' => 'pda-bad-stack-symbol',
    'PDA_BAD_PUSH_SYMBOL' => 'pda-bad-push-symbol',
    'TM_EMPTY' => 'tm-empty',
    'TM_NO_INITIAL' => 'tm-no-initial',
    'TM_INVALID_INITIAL' => 'tm-invalid-initial',
    'TM_NO_ACCEPTING' => 'tm-no-accepting',
    'TM_EMPTY_INPUT_ALPHABET' => 'tm-empty-input-alphabet',
    'TM_EMPTY_TAPE_ALPHABET' => 'tm-empty-tape-alphabet',
    'TM_EMPTY_BLANK' => 'tm-empty-blank',
    'TM_BLANK_NOT_IN_TAPE' => 'tm-blank-not-in-tape',
    'TM_INPUT_NOT_IN_TAPE' => 'tm-input-not-in-tape',
    'TM_INVALID_ACCEPTING' => 'tm-invalid-accepting',
    'TM_BAD_FROM' => 'tm-bad-from',
    'TM_BAD_TO' => 'tm-bad-to',
    'TM_BAD_READ_SYMBOL' => 'tm-bad-read-symbol',
    'TM_BAD_WRITE_SYMBOL' => 'tm-bad-write-symbol',
    'TM_BAD_MOVE' => 'tm-bad-move',
    'CFG_EMPTY' => 'cfg-empty',
    'CFG_NO_NONTERMINALS' => 'cfg-no-nonterminals',
    'CFG_NO_TERMINALS' => 'cfg-no-terminals',
    'CFG_EMPTY_START' => 'cfg-empty-start',
    'CFG_BAD_START' => 'cfg-bad-start',
    'CFG_EMPTY_LEFT' => 'cfg-empty-left',
    'CFG_BAD_LEFT' => 'cfg-bad-left',
    'CFG_EMPTY_RIGHT' => 'cfg-empty-right',
    'CFG_BAD_SYMBOL' => 'cfg-bad-symbol',
    'INPUT_EMPTY' => 'input-empty',
    'INPUT_INVALID_SYMBOL' => 'input-invalid-symbol',
    _ => throw ArgumentError.value(
      legacyCode,
      'legacyCode',
      'Unsupported FSA/PDA validation code.',
    ),
  };
}
