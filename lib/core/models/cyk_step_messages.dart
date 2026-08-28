import '../messages/structured_message.dart';

const cykStepTitleMessageProperty = 'cykStepTitleMessage';
const cykStepExplanationMessageProperty = 'cykStepExplanationMessage';

// Short aliases match the naming used by other algorithm-step companions.
const cykTitleMessageProperty = cykStepTitleMessageProperty;
const cykExplanationMessageProperty = cykStepExplanationMessageProperty;

/// Locale-neutral messages emitted by the educational CYK step model.
abstract final class CykStepMessages {
  static StructuredMessage initializeTitle() => _step('initialize-title');

  static StructuredMessage initializeExplanation({
    required String inputString,
    required int tableSize,
  }) => _step(
    'initialize-explanation',
    arguments: {
      'input': _input(inputString),
      'table-size': _count(tableSize, 'token-count'),
    },
  );

  static StructuredMessage initializeStepTitle() =>
      _step('initialize-step-title');

  static StructuredMessage initializeInputBullet({
    required String inputString,
    required int tableSize,
  }) => _step(
    'initialize-input-bullet',
    arguments: {
      'input': _input(inputString),
      'table-size': _count(tableSize, 'token-count'),
    },
  );

  static StructuredMessage initializeTableBullet() =>
      _step('initialize-table-bullet');

  static StructuredMessage fillBaseCaseTitle(String terminal) => _step(
    'fill-base-case-title',
    arguments: {'terminal': _terminal(terminal)},
  );

  static StructuredMessage fillBaseCaseExplanation({
    required int position,
    required String terminal,
    required String derivingVariables,
    required bool hasDerivingVariables,
  }) => _step(
    'fill-base-case-explanation',
    arguments: {
      'position': _index(position, 'input-position'),
      'terminal': _terminal(terminal),
      'variables': _nonterminalList(derivingVariables),
      'has-variables': _boolean(
        hasDerivingVariables,
        'deriving-variable-presence',
      ),
    },
  );

  static StructuredMessage fillBaseCaseStepTitle(String terminal) => _step(
    'fill-base-case-step-title',
    arguments: {'terminal': _terminal(terminal)},
  );

  static StructuredMessage fillBaseCaseFragmentBullet({
    required int position,
    required String terminal,
  }) => _step(
    'fill-base-case-fragment-bullet',
    arguments: {
      'position': _index(position, 'input-position'),
      'terminal': _terminal(terminal),
    },
  );

  static StructuredMessage fillBaseCaseProductionBullet() =>
      _step('fill-base-case-production-bullet');

  static StructuredMessage fillBaseCaseEmptyBullet(String terminal) => _step(
    'fill-base-case-empty-bullet',
    arguments: {'terminal': _terminal(terminal)},
  );

  static StructuredMessage fillBaseCaseAddedBullet(String variables) => _step(
    'fill-base-case-added-bullet',
    arguments: {'variables': _nonterminalList(variables)},
  );

  static StructuredMessage processCellTitle({
    required int row,
    required int col,
  }) => _step(
    'process-cell-title',
    arguments: {
      'row': _index(row, 'table-row'),
      'column': _index(col, 'table-column'),
    },
  );

  static StructuredMessage processCellExplanation({
    required int row,
    required int col,
    required String substring,
    required int length,
  }) => _step(
    'process-cell-explanation',
    arguments: {
      'row': _index(row, 'table-row'),
      'column': _index(col, 'table-column'),
      'substring': _substring(substring),
      'length': _count(length, 'substring-length'),
    },
  );

  static StructuredMessage processCellStepTitle(String substring) => _step(
    'process-cell-step-title',
    arguments: {'substring': _substring(substring)},
  );

  static StructuredMessage processCellLocationBullet({
    required int row,
    required int col,
    required int length,
  }) => _step(
    'process-cell-location-bullet',
    arguments: {
      'row': _index(row, 'table-row'),
      'column': _index(col, 'table-column'),
      'length': _count(length, 'substring-length'),
    },
  );

  static StructuredMessage processCellSplitBullet() =>
      _step('process-cell-split-bullet');

  static StructuredMessage checkSplitTitle(int splitPoint) => _step(
    'check-split-title',
    arguments: {'split-point': _index(splitPoint, 'split-position')},
  );

  static StructuredMessage checkSplitExplanation({
    required String substring,
    required String leftSubstring,
    required String rightSubstring,
    required int leftRow,
    required int leftCol,
    required int rightRow,
    required int rightCol,
    required String leftNonTerminals,
    required String rightNonTerminals,
  }) => _step(
    'check-split-explanation',
    arguments: {
      'substring': _substring(substring),
      'left-substring': _substring(leftSubstring),
      'right-substring': _substring(rightSubstring),
      'left-row': _index(leftRow, 'table-row'),
      'left-column': _index(leftCol, 'table-column'),
      'right-row': _index(rightRow, 'table-row'),
      'right-column': _index(rightCol, 'table-column'),
      'left-variables': _nonterminalList(leftNonTerminals),
      'right-variables': _nonterminalList(rightNonTerminals),
      'has-left-variables': _boolean(
        leftNonTerminals.isNotEmpty,
        'left-variable-presence',
      ),
      'has-right-variables': _boolean(
        rightNonTerminals.isNotEmpty,
        'right-variable-presence',
      ),
    },
  );

  static StructuredMessage checkSplitStepTitle({
    required String leftSubstring,
    required String rightSubstring,
  }) => _step(
    'check-split-step-title',
    arguments: {
      'left-substring': _substring(leftSubstring),
      'right-substring': _substring(rightSubstring),
    },
  );

  static StructuredMessage checkSplitLeftBullet({
    required int row,
    required int col,
    required String variables,
  }) => _step(
    'check-split-left-bullet',
    arguments: {
      'row': _index(row, 'table-row'),
      'column': _index(col, 'table-column'),
      'variables': _nonterminalList(variables),
      'has-variables': _boolean(variables.isNotEmpty, 'left-variable-presence'),
    },
  );

  static StructuredMessage checkSplitRightBullet({
    required int row,
    required int col,
    required String variables,
  }) => _step(
    'check-split-right-bullet',
    arguments: {
      'row': _index(row, 'table-row'),
      'column': _index(col, 'table-column'),
      'variables': _nonterminalList(variables),
      'has-variables': _boolean(
        variables.isNotEmpty,
        'right-variable-presence',
      ),
    },
  );

  static StructuredMessage checkSplitProductionBullet({
    required int row,
    required int col,
  }) => _step(
    'check-split-production-bullet',
    arguments: {
      'row': _index(row, 'table-row'),
      'column': _index(col, 'table-column'),
    },
  );

  static StructuredMessage applyProductionTitle({
    required String variable,
    required String leftVariable,
    required String rightVariable,
  }) => _step(
    'apply-production-title',
    arguments: {
      'variable': _nonterminal(variable),
      'left-variable': _nonterminal(leftVariable),
      'right-variable': _nonterminal(rightVariable),
    },
  );

  static StructuredMessage applyProductionExplanation({
    required int row,
    required int col,
    required String variable,
    required String leftVariable,
    required String rightVariable,
    required String substring,
  }) => _step(
    'apply-production-explanation',
    arguments: {
      'row': _index(row, 'table-row'),
      'column': _index(col, 'table-column'),
      'variable': _nonterminal(variable),
      'left-variable': _nonterminal(leftVariable),
      'right-variable': _nonterminal(rightVariable),
      'substring': _substring(substring),
    },
  );

  static StructuredMessage applyProductionStepTitle({
    required String variable,
    required String leftVariable,
    required String rightVariable,
  }) => _step(
    'apply-production-step-title',
    arguments: {
      'variable': _nonterminal(variable),
      'left-variable': _nonterminal(leftVariable),
      'right-variable': _nonterminal(rightVariable),
    },
  );

  static StructuredMessage applyProductionCombineBullet() =>
      _step('apply-production-combine-bullet');

  static StructuredMessage applyProductionDerivationBullet({
    required String leftVariable,
    required String rightVariable,
    required String variable,
    required String substring,
  }) => _step(
    'apply-production-derivation-bullet',
    arguments: {
      'left-variable': _nonterminal(leftVariable),
      'right-variable': _nonterminal(rightVariable),
      'variable': _nonterminal(variable),
      'substring': _substring(substring),
    },
  );

  static StructuredMessage applyProductionAddBullet({
    required int row,
    required int col,
    required String variable,
  }) => _step(
    'apply-production-add-bullet',
    arguments: {
      'row': _index(row, 'table-row'),
      'column': _index(col, 'table-column'),
      'variable': _nonterminal(variable),
    },
  );

  static StructuredMessage completeCellTitle({
    required int row,
    required int col,
  }) => _step(
    'complete-cell-title',
    arguments: {
      'row': _index(row, 'table-row'),
      'column': _index(col, 'table-column'),
    },
  );

  static StructuredMessage completeCellExplanation({
    required int row,
    required int col,
    required String substring,
    required String nonTerminals,
    required bool hasNonTerminals,
  }) => _step(
    'complete-cell-explanation',
    arguments: {
      'row': _index(row, 'table-row'),
      'column': _index(col, 'table-column'),
      'substring': _substring(substring),
      'nonterminals': _nonterminalList(nonTerminals),
      'has-nonterminals': _boolean(hasNonTerminals, 'nonterminal-presence'),
    },
  );

  static StructuredMessage completeCellStepTitle({
    required int row,
    required int col,
  }) => _step(
    'complete-cell-step-title',
    arguments: {
      'row': _index(row, 'table-row'),
      'column': _index(col, 'table-column'),
    },
  );

  static StructuredMessage completeCellSubstringBullet(String substring) =>
      _step(
        'complete-cell-substring-bullet',
        arguments: {'substring': _substring(substring)},
      );

  static StructuredMessage completeCellEmptyBullet() =>
      _step('complete-cell-empty-bullet');

  static StructuredMessage completeCellNonTerminalsBullet(
    String nonTerminals,
  ) => _step(
    'complete-cell-nonterminals-bullet',
    arguments: {'nonterminals': _nonterminalList(nonTerminals)},
  );

  static StructuredMessage checkAcceptanceTitle() =>
      _step('check-acceptance-title');

  static StructuredMessage checkAcceptanceExplanation({
    required String inputString,
    required String startSymbol,
    required String finalNonTerminals,
    required bool hasFinalNonTerminals,
    required bool isAccepted,
  }) => _step(
    'check-acceptance-explanation',
    arguments: {
      'input': _input(inputString),
      'start-symbol': _startSymbol(startSymbol),
      'nonterminals': _nonterminalList(finalNonTerminals),
      'has-nonterminals': _boolean(hasFinalNonTerminals, 'final-cell-presence'),
      'accepted': _boolean(isAccepted, 'acceptance-result'),
    },
  );

  static StructuredMessage checkAcceptanceStepTitle() =>
      _step('check-acceptance-step-title');

  static StructuredMessage checkAcceptanceFinalCellBullet(
    String nonTerminals,
  ) => _step(
    'check-acceptance-final-cell-bullet',
    arguments: {'nonterminals': _nonterminalList(nonTerminals)},
  );

  static StructuredMessage checkAcceptanceAcceptedBullet(String startSymbol) =>
      _step(
        'check-acceptance-accepted-bullet',
        arguments: {'start-symbol': _startSymbol(startSymbol)},
      );

  static StructuredMessage checkAcceptanceRejectedBullet(String startSymbol) =>
      _step(
        'check-acceptance-rejected-bullet',
        arguments: {'start-symbol': _startSymbol(startSymbol)},
      );

  static StructuredMessage completionTitle() => _step('completion-title');

  static StructuredMessage completionExplanation({
    required String inputString,
    required int totalCells,
    required int filledCells,
    required bool isAccepted,
  }) => _step(
    'completion-explanation',
    arguments: {
      'input': _input(inputString),
      'total-cells': _count(totalCells, 'cell-count'),
      'filled-cells': _count(filledCells, 'filled-cell-count'),
      'accepted': _boolean(isAccepted, 'acceptance-result'),
    },
  );

  static StructuredMessage completionStepTitle() =>
      _step('completion-step-title');

  static StructuredMessage completionFilledCellsBullet({
    required int totalCells,
    required int filledCells,
  }) => _step(
    'completion-filled-cells-bullet',
    arguments: {
      'total-cells': _count(totalCells, 'cell-count'),
      'filled-cells': _count(filledCells, 'filled-cell-count'),
    },
  );

  static StructuredMessage completionAcceptedBullet() =>
      _step('completion-accepted-bullet');

  static StructuredMessage completionRejectedBullet() =>
      _step('completion-rejected-bullet');

  static StructuredMessage _step(
    String code, {
    Map<String, StructuredMessageArgument> arguments = const {},
  }) => StructuredMessage(
    namespace: 'grammar.cyk.step',
    code: code,
    category: StructuredMessageCategory.parsing,
    severity: StructuredMessageSeverity.information,
    arguments: arguments,
  );

  static StructuredMessageArgument _input(String value) =>
      StructuredMessageArgument.literal(value, role: 'input-string');

  static StructuredMessageArgument _terminal(String value) =>
      StructuredMessageArgument.symbol(value, role: 'terminal');

  static StructuredMessageArgument _substring(String value) =>
      StructuredMessageArgument.literal(value, role: 'substring');

  static StructuredMessageArgument _nonterminal(String value) =>
      StructuredMessageArgument.identifier(value, role: 'nonterminal');

  static StructuredMessageArgument _startSymbol(String value) =>
      StructuredMessageArgument.identifier(value, role: 'start-symbol');

  static StructuredMessageArgument _nonterminalList(String value) =>
      StructuredMessageArgument.literal(value, role: 'nonterminal-list');

  static StructuredMessageArgument _index(int value, String role) =>
      StructuredMessageArgument.index(value, role: role);

  static StructuredMessageArgument _count(int value, String role) =>
      StructuredMessageArgument.count(value, role: role);

  static StructuredMessageArgument _boolean(bool value, String role) =>
      StructuredMessageArgument.boolean(value, role: role);
}
