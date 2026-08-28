//
//  cyk_step.dart
//  Turing Lab
//
//  Defines the detailed step model for the CYK (Cocke-Younger-Kasami)
//  algorithm for parsing context-free grammars in Chomsky Normal Form.
//  Captures parse-table state, processed cells, applied productions,
//  substring splits, and added nonterminals, enabling educational
//  step-by-step visualization of bottom-up parsing.
//
//  Thales Matheus Mendonça Santos - January 2026
//

import 'algorithm_step.dart';
import '../messages/structured_message.dart';
import 'step_explanation.dart';
import 'cyk_step_messages.dart';

/// Represents a single step in CYK parsing algorithm
class CYKStep {
  /// Base algorithm step information
  final AlgorithmStep baseStep;

  /// Type of operation performed in this step
  final CYKStepType stepType;

  /// Current parse table state (row = substring length - 1, col = start position)
  /// Each cell contains a set of non-terminals that can derive that substring
  final List<List<Set<String>>>? tableState;

  /// Current row being processed (substring length - 1)
  final int? currentRow;

  /// Current column being processed (start position in string)
  final int? currentCol;

  /// Substring being analyzed
  final String? substring;

  /// Start token index of the substring in the tokenized input
  final int? substringStart;

  /// Number of grammar tokens in the substring being processed
  final int? substringLength;

  /// Token split point being checked (0 to length-1)
  final int? splitPoint;

  /// Row of left cell in split
  final int? leftRow;

  /// Column of left cell in split
  final int? leftCol;

  /// Row of right cell in split
  final int? rightRow;

  /// Column of right cell in split
  final int? rightCol;

  /// Non-terminals in left cell of split
  final Set<String>? leftNonTerminals;

  /// Non-terminals in right cell of split
  final Set<String>? rightNonTerminals;

  /// Production rule being applied (format: "A → B C")
  final String? production;

  /// Left-hand side of production (the variable being derived)
  final String? productionLeft;

  /// Right-hand side of production (two variables in CNF)
  final List<String>? productionRight;

  /// Non-terminal added to current cell
  final String? addedNonTerminal;

  /// All non-terminals in current cell after update
  final Set<String>? cellNonTerminals;

  /// Terminal symbol matched (for base case)
  final String? terminal;

  /// Whether the string is accepted (start symbol in final cell)
  final bool isAccepted;

  /// Whether any non-terminals were added to the cell
  final bool cellModified;

  const CYKStep._internal({
    required this.baseStep,
    required this.stepType,
    this.tableState,
    this.currentRow,
    this.currentCol,
    this.substring,
    this.substringStart,
    this.substringLength,
    this.splitPoint,
    this.leftRow,
    this.leftCol,
    this.rightRow,
    this.rightCol,
    this.leftNonTerminals,
    this.rightNonTerminals,
    this.production,
    this.productionLeft,
    this.productionRight,
    this.addedNonTerminal,
    this.cellNonTerminals,
    this.terminal,
    required this.isAccepted,
    required this.cellModified,
  });

  factory CYKStep({
    required AlgorithmStep baseStep,
    required CYKStepType stepType,
    List<List<Set<String>>>? tableState,
    int? currentRow,
    int? currentCol,
    String? substring,
    int? substringStart,
    int? substringLength,
    int? splitPoint,
    int? leftRow,
    int? leftCol,
    int? rightRow,
    int? rightCol,
    Set<String>? leftNonTerminals,
    Set<String>? rightNonTerminals,
    String? production,
    String? productionLeft,
    List<String>? productionRight,
    String? addedNonTerminal,
    Set<String>? cellNonTerminals,
    String? terminal,
    bool isAccepted = false,
    bool cellModified = false,
  }) {
    return CYKStep._internal(
      baseStep: baseStep,
      stepType: stepType,
      tableState: tableState != null
          ? List.unmodifiable(
              tableState
                  .map(
                    (row) => List.unmodifiable(
                      row
                          .map((cell) => Set<String>.unmodifiable(cell))
                          .toList(),
                    ),
                  )
                  .toList(),
            )
          : null,
      currentRow: currentRow,
      currentCol: currentCol,
      substring: substring,
      substringStart: substringStart,
      substringLength: substringLength,
      splitPoint: splitPoint,
      leftRow: leftRow,
      leftCol: leftCol,
      rightRow: rightRow,
      rightCol: rightCol,
      leftNonTerminals: leftNonTerminals != null
          ? Set.unmodifiable(leftNonTerminals)
          : null,
      rightNonTerminals: rightNonTerminals != null
          ? Set.unmodifiable(rightNonTerminals)
          : null,
      production: production,
      productionLeft: productionLeft,
      productionRight: productionRight != null
          ? List.unmodifiable(productionRight)
          : null,
      addedNonTerminal: addedNonTerminal,
      cellNonTerminals: cellNonTerminals != null
          ? Set.unmodifiable(cellNonTerminals)
          : null,
      terminal: terminal,
      isAccepted: isAccepted,
      cellModified: cellModified,
    );
  }

  /// Creates an initialization step
  factory CYKStep.initialize({
    required String id,
    required int stepNumber,
    required String inputString,
    required int tableSize,
  }) {
    final titleMessage = CykStepMessages.initializeTitle();
    final explanationMessage = CykStepMessages.initializeExplanation(
      inputString: inputString,
      tableSize: tableSize,
    );
    return CYKStep(
      baseStep: _cykBaseStep(
        id: id,
        stepNumber: stepNumber,
        title: 'Initialize CYK table',
        explanation:
            'Initializing CYK parse table for input string "$inputString" ($tableSize tokens). '
            'The table is a triangular matrix where cell [i][j] will contain all non-terminals '
            'that can derive the substring of i+1 tokens starting at token position j.',
        stepExplanation: StepExplanation(
          title: 'Initialize CYK table',
          bullets: [
            'Input: "$inputString" ($tableSize tokens).',
            'We create an empty triangular table: cell [i][j] stores non-terminals that derive the substring of i+1 tokens starting at token position j.',
          ],
          categories: const [ExplanationCategory.grammarDerivation],
        ),
        titleMessage: titleMessage,
        explanationMessage: explanationMessage,
        stepExplanationTitleMessage: CykStepMessages.initializeStepTitle(),
        bulletMessages: [
          CykStepMessages.initializeInputBullet(
            inputString: inputString,
            tableSize: tableSize,
          ),
          CykStepMessages.initializeTableBullet(),
        ],
      ),
      stepType: CYKStepType.initialize,
    );
  }

  /// Creates a step for filling a base case cell
  factory CYKStep.fillBaseCase({
    required String id,
    required int stepNumber,
    required int position,
    required String terminal,
    required Set<String> derivingVariables,
  }) {
    final varList = derivingVariables.isEmpty
        ? 'none'
        : derivingVariables.join(', ');
    final structuredVarList = derivingVariables.isEmpty ? '' : varList;
    final titleMessage = CykStepMessages.fillBaseCaseTitle(terminal);
    final explanationMessage = CykStepMessages.fillBaseCaseExplanation(
      position: position,
      terminal: terminal,
      derivingVariables: structuredVarList,
      hasDerivingVariables: derivingVariables.isNotEmpty,
    );
    return CYKStep(
      baseStep: _cykBaseStep(
        id: id,
        stepNumber: stepNumber,
        title: 'Fill base case for "$terminal"',
        explanation:
            'Processing terminal "$terminal" at position $position. '
            'Looking for productions of the form A → "$terminal". '
            '${derivingVariables.isEmpty ? "No variables produce this terminal." : "Variables that derive this terminal: $varList."}',
        stepExplanation: StepExplanation(
          title: 'Match terminal "$terminal"',
          bullets: [
            'Sentential form fragment: "$terminal" at input position $position.',
            'We add every variable A such that there is a production A → "$terminal".',
            if (derivingVariables.isEmpty)
              'No variable derives "$terminal", so this cell stays empty.'
            else
              'Added variables: $varList.',
          ],
          categories: const [ExplanationCategory.grammarDerivation],
          highlights: [
            HighlightTarget(
              type: HighlightTargetType.productionSpan,
              data: {'terminal': terminal},
            ),
          ],
        ),
        titleMessage: titleMessage,
        explanationMessage: explanationMessage,
        stepExplanationTitleMessage: CykStepMessages.fillBaseCaseStepTitle(
          terminal,
        ),
        bulletMessages: [
          CykStepMessages.fillBaseCaseFragmentBullet(
            position: position,
            terminal: terminal,
          ),
          CykStepMessages.fillBaseCaseProductionBullet(),
          if (derivingVariables.isEmpty)
            CykStepMessages.fillBaseCaseEmptyBullet(terminal)
          else
            CykStepMessages.fillBaseCaseAddedBullet(structuredVarList),
        ],
      ),
      stepType: CYKStepType.fillBaseCase,
      currentRow: 0,
      currentCol: position,
      substring: terminal,
      substringStart: position,
      substringLength: 1,
      terminal: terminal,
      cellNonTerminals: derivingVariables,
      cellModified: derivingVariables.isNotEmpty,
    );
  }

  /// Creates a step for starting to process a cell
  factory CYKStep.processCell({
    required String id,
    required int stepNumber,
    required int row,
    required int col,
    required String substring,
    required int length,
  }) {
    final titleMessage = CykStepMessages.processCellTitle(row: row, col: col);
    final explanationMessage = CykStepMessages.processCellExplanation(
      row: row,
      col: col,
      substring: substring,
      length: length,
    );
    return CYKStep(
      baseStep: _cykBaseStep(
        id: id,
        stepNumber: stepNumber,
        title: 'Process cell [$row][$col]',
        explanation:
            'Processing substring "$substring" of $length tokens starting at token position $col. '
            'We will try all possible ways to split this substring and check if any productions apply.',
        stepExplanation: StepExplanation(
          title: 'Process substring "$substring"',
          bullets: [
            'We are filling table cell [$row][$col] for a substring of $length tokens.',
            'Try all split points and apply productions A → B C where B derives the left part and C derives the right part.',
          ],
          categories: const [ExplanationCategory.grammarDerivation],
        ),
        titleMessage: titleMessage,
        explanationMessage: explanationMessage,
        stepExplanationTitleMessage: CykStepMessages.processCellStepTitle(
          substring,
        ),
        bulletMessages: [
          CykStepMessages.processCellLocationBullet(
            row: row,
            col: col,
            length: length,
          ),
          CykStepMessages.processCellSplitBullet(),
        ],
      ),
      stepType: CYKStepType.processCell,
      currentRow: row,
      currentCol: col,
      substring: substring,
      substringStart: col,
      substringLength: length,
    );
  }

  /// Creates a step for checking a specific split point
  factory CYKStep.checkSplit({
    required String id,
    required int stepNumber,
    required int row,
    required int col,
    required String substring,
    required int substringLength,
    required int splitPoint,
    required String leftSubstring,
    required String rightSubstring,
    required int leftRow,
    required int leftCol,
    required int rightRow,
    required int rightCol,
    required Set<String> leftNonTerminals,
    required Set<String> rightNonTerminals,
  }) {
    final leftVars = leftNonTerminals.isEmpty
        ? '∅'
        : leftNonTerminals.join(', ');
    final rightVars = rightNonTerminals.isEmpty
        ? '∅'
        : rightNonTerminals.join(', ');
    final structuredLeftVars = leftNonTerminals.isEmpty ? '' : leftVars;
    final structuredRightVars = rightNonTerminals.isEmpty ? '' : rightVars;
    final titleMessage = CykStepMessages.checkSplitTitle(splitPoint);
    final explanationMessage = CykStepMessages.checkSplitExplanation(
      substring: substring,
      leftSubstring: leftSubstring,
      rightSubstring: rightSubstring,
      leftRow: leftRow,
      leftCol: leftCol,
      rightRow: rightRow,
      rightCol: rightCol,
      leftNonTerminals: structuredLeftVars,
      rightNonTerminals: structuredRightVars,
    );
    return CYKStep(
      baseStep: _cykBaseStep(
        id: id,
        stepNumber: stepNumber,
        title: 'Check split at position $splitPoint',
        explanation:
            'Splitting "$substring" into "$leftSubstring" (cell [$leftRow][$leftCol]) and "$rightSubstring" (cell [$rightRow][$rightCol]). '
            'Left cell contains: {$leftVars}. Right cell contains: {$rightVars}. '
            'Looking for productions of the form A → B C where B ∈ left and C ∈ right.',
        stepExplanation: StepExplanation(
          title: 'Try split "$leftSubstring" | "$rightSubstring"',
          bullets: [
            'Left part (cell [$leftRow][$leftCol]) has {$leftVars}.',
            'Right part (cell [$rightRow][$rightCol]) has {$rightVars}.',
            'If we find a production A → B C with B in left and C in right, then add A to cell [$row][$col].',
          ],
          categories: const [ExplanationCategory.grammarDerivation],
        ),
        titleMessage: titleMessage,
        explanationMessage: explanationMessage,
        stepExplanationTitleMessage: CykStepMessages.checkSplitStepTitle(
          leftSubstring: leftSubstring,
          rightSubstring: rightSubstring,
        ),
        bulletMessages: [
          CykStepMessages.checkSplitLeftBullet(
            row: leftRow,
            col: leftCol,
            variables: structuredLeftVars,
          ),
          CykStepMessages.checkSplitRightBullet(
            row: rightRow,
            col: rightCol,
            variables: structuredRightVars,
          ),
          CykStepMessages.checkSplitProductionBullet(row: row, col: col),
        ],
      ),
      stepType: CYKStepType.checkSplit,
      currentRow: row,
      currentCol: col,
      substring: substring,
      substringStart: col,
      substringLength: substringLength,
      splitPoint: splitPoint,
      leftRow: leftRow,
      leftCol: leftCol,
      rightRow: rightRow,
      rightCol: rightCol,
      leftNonTerminals: leftNonTerminals,
      rightNonTerminals: rightNonTerminals,
    );
  }

  /// Creates a step for applying a production rule
  factory CYKStep.applyProduction({
    required String id,
    required int stepNumber,
    required int row,
    required int col,
    required String variable,
    required String leftVar,
    required String rightVar,
    required String substring,
    required int substringLength,
  }) {
    final titleMessage = CykStepMessages.applyProductionTitle(
      variable: variable,
      leftVariable: leftVar,
      rightVariable: rightVar,
    );
    final explanationMessage = CykStepMessages.applyProductionExplanation(
      row: row,
      col: col,
      variable: variable,
      leftVariable: leftVar,
      rightVariable: rightVar,
      substring: substring,
    );
    return CYKStep(
      baseStep: _cykBaseStep(
        id: id,
        stepNumber: stepNumber,
        title: 'Apply production $variable → $leftVar $rightVar',
        explanation:
            'Found production $variable → $leftVar $rightVar. '
            'Since $leftVar is in the left cell and $rightVar is in the right cell, '
            'we can derive "$substring" using $variable. Adding $variable to cell [$row][$col].',
        stepExplanation: StepExplanation(
          title: 'Apply production $variable → $leftVar $rightVar',
          bullets: [
            'We found a production that can combine the left and right parts.',
            'Because $leftVar derives the left substring and $rightVar derives the right substring, $variable derives "$substring".',
            'Add $variable to table cell [$row][$col].',
          ],
          categories: const [ExplanationCategory.grammarDerivation],
          highlights: [
            HighlightTarget(
              type: HighlightTargetType.productionSpan,
              data: {
                'lhs': variable,
                'rhs': [leftVar, rightVar],
              },
            ),
          ],
        ),
        titleMessage: titleMessage,
        explanationMessage: explanationMessage,
        stepExplanationTitleMessage: CykStepMessages.applyProductionStepTitle(
          variable: variable,
          leftVariable: leftVar,
          rightVariable: rightVar,
        ),
        bulletMessages: [
          CykStepMessages.applyProductionCombineBullet(),
          CykStepMessages.applyProductionDerivationBullet(
            leftVariable: leftVar,
            rightVariable: rightVar,
            variable: variable,
            substring: substring,
          ),
          CykStepMessages.applyProductionAddBullet(
            row: row,
            col: col,
            variable: variable,
          ),
        ],
      ),
      stepType: CYKStepType.applyProduction,
      currentRow: row,
      currentCol: col,
      substring: substring,
      substringStart: col,
      substringLength: substringLength,
      production: '$variable → $leftVar $rightVar',
      productionLeft: variable,
      productionRight: [leftVar, rightVar],
      addedNonTerminal: variable,
      cellModified: true,
    );
  }

  /// Creates a step for completing cell processing
  factory CYKStep.completeCell({
    required String id,
    required int stepNumber,
    required int row,
    required int col,
    required String substring,
    required int substringLength,
    required Set<String> cellNonTerminals,
  }) {
    final varList = cellNonTerminals.isEmpty
        ? 'none'
        : cellNonTerminals.join(', ');
    final structuredVarList = cellNonTerminals.isEmpty ? '' : varList;
    final titleMessage = CykStepMessages.completeCellTitle(row: row, col: col);
    final explanationMessage = CykStepMessages.completeCellExplanation(
      row: row,
      col: col,
      substring: substring,
      nonTerminals: structuredVarList,
      hasNonTerminals: cellNonTerminals.isNotEmpty,
    );
    return CYKStep(
      baseStep: _cykBaseStep(
        id: id,
        stepNumber: stepNumber,
        title: 'Complete cell [$row][$col]',
        explanation:
            'Finished processing substring "$substring" at cell [$row][$col]. '
            '${cellNonTerminals.isEmpty ? "No non-terminals can derive this substring." : "Non-terminals that can derive this substring: $varList."}',
        stepExplanation: StepExplanation(
          title: 'Cell [$row][$col] complete',
          bullets: [
            'Substring: "$substring".',
            if (cellNonTerminals.isEmpty)
              'No non-terminal derives this substring.'
            else
              'Non-terminals that derive this substring: $varList.',
          ],
          categories: const [ExplanationCategory.grammarDerivation],
        ),
        titleMessage: titleMessage,
        explanationMessage: explanationMessage,
        stepExplanationTitleMessage: CykStepMessages.completeCellStepTitle(
          row: row,
          col: col,
        ),
        bulletMessages: [
          CykStepMessages.completeCellSubstringBullet(substring),
          if (cellNonTerminals.isEmpty)
            CykStepMessages.completeCellEmptyBullet()
          else
            CykStepMessages.completeCellNonTerminalsBullet(structuredVarList),
        ],
      ),
      stepType: CYKStepType.completeCell,
      currentRow: row,
      currentCol: col,
      substring: substring,
      substringStart: col,
      substringLength: substringLength,
      cellNonTerminals: cellNonTerminals,
    );
  }

  /// Creates a step for checking string acceptance
  factory CYKStep.checkAcceptance({
    required String id,
    required int stepNumber,
    required String inputString,
    required String startSymbol,
    required Set<String> finalCellNonTerminals,
    required bool isAccepted,
  }) {
    final varList = finalCellNonTerminals.isEmpty
        ? 'none'
        : finalCellNonTerminals.join(', ');
    final structuredVarList = finalCellNonTerminals.isEmpty ? '' : varList;
    final titleMessage = CykStepMessages.checkAcceptanceTitle();
    final explanationMessage = CykStepMessages.checkAcceptanceExplanation(
      inputString: inputString,
      startSymbol: startSymbol,
      finalNonTerminals: structuredVarList,
      hasFinalNonTerminals: finalCellNonTerminals.isNotEmpty,
      isAccepted: isAccepted,
    );
    return CYKStep(
      baseStep: _cykBaseStep(
        id: id,
        stepNumber: stepNumber,
        title: 'Check acceptance',
        explanation:
            'Checking if input string "$inputString" is accepted. '
            'The top cell of the table contains: {$varList}. '
            '${isAccepted ? "The start symbol $startSymbol is present, so the string IS accepted by the grammar." : "The start symbol $startSymbol is NOT present, so the string is NOT accepted by the grammar."}',
        stepExplanation: StepExplanation(
          title: 'Acceptance check',
          bullets: [
            'Final (top) cell contains: {$varList}.',
            if (isAccepted)
              'Start symbol $startSymbol is present → ACCEPT.'
            else
              'Start symbol $startSymbol is missing → REJECT.',
          ],
          categories: const [ExplanationCategory.grammarDerivation],
        ),
        titleMessage: titleMessage,
        explanationMessage: explanationMessage,
        stepExplanationTitleMessage: CykStepMessages.checkAcceptanceStepTitle(),
        bulletMessages: [
          CykStepMessages.checkAcceptanceFinalCellBullet(structuredVarList),
          if (isAccepted)
            CykStepMessages.checkAcceptanceAcceptedBullet(startSymbol)
          else
            CykStepMessages.checkAcceptanceRejectedBullet(startSymbol),
        ],
      ),
      stepType: CYKStepType.checkAcceptance,
      cellNonTerminals: finalCellNonTerminals,
      isAccepted: isAccepted,
    );
  }

  /// Creates a completion step
  factory CYKStep.completion({
    required String id,
    required int stepNumber,
    required String inputString,
    required bool isAccepted,
    required int totalCells,
    required int filledCells,
  }) {
    final titleMessage = CykStepMessages.completionTitle();
    final explanationMessage = CykStepMessages.completionExplanation(
      inputString: inputString,
      totalCells: totalCells,
      filledCells: filledCells,
      isAccepted: isAccepted,
    );
    return CYKStep(
      baseStep: _cykBaseStep(
        id: id,
        stepNumber: stepNumber,
        title: 'Parsing complete',
        explanation:
            'CYK parsing completed for input string "$inputString". '
            'Processed $filledCells out of $totalCells cells in the parse table. '
            '${isAccepted ? "The string IS in the language generated by the grammar." : "The string is NOT in the language generated by the grammar."}',
        stepExplanation: StepExplanation(
          title: 'CYK parsing complete',
          bullets: [
            'Filled $filledCells / $totalCells cells.',
            if (isAccepted)
              'Result: ACCEPT (string is generated by the grammar).'
            else
              'Result: REJECT (string is not generated by the grammar).',
          ],
          categories: const [ExplanationCategory.grammarDerivation],
        ),
        titleMessage: titleMessage,
        explanationMessage: explanationMessage,
        stepExplanationTitleMessage: CykStepMessages.completionStepTitle(),
        bulletMessages: [
          CykStepMessages.completionFilledCellsBullet(
            totalCells: totalCells,
            filledCells: filledCells,
          ),
          if (isAccepted)
            CykStepMessages.completionAcceptedBullet()
          else
            CykStepMessages.completionRejectedBullet(),
        ],
      ),
      stepType: CYKStepType.completion,
      isAccepted: isAccepted,
    );
  }

  /// Creates a copy of this step with updated properties
  CYKStep copyWith({
    AlgorithmStep? baseStep,
    CYKStepType? stepType,
    List<List<Set<String>>>? tableState,
    int? currentRow,
    int? currentCol,
    String? substring,
    int? substringStart,
    int? substringLength,
    int? splitPoint,
    int? leftRow,
    int? leftCol,
    int? rightRow,
    int? rightCol,
    Set<String>? leftNonTerminals,
    Set<String>? rightNonTerminals,
    String? production,
    String? productionLeft,
    List<String>? productionRight,
    String? addedNonTerminal,
    Set<String>? cellNonTerminals,
    String? terminal,
    bool? isAccepted,
    bool? cellModified,
  }) {
    return CYKStep(
      baseStep: baseStep ?? this.baseStep,
      stepType: stepType ?? this.stepType,
      tableState: tableState ?? this.tableState,
      currentRow: currentRow ?? this.currentRow,
      currentCol: currentCol ?? this.currentCol,
      substring: substring ?? this.substring,
      substringStart: substringStart ?? this.substringStart,
      substringLength: substringLength ?? this.substringLength,
      splitPoint: splitPoint ?? this.splitPoint,
      leftRow: leftRow ?? this.leftRow,
      leftCol: leftCol ?? this.leftCol,
      rightRow: rightRow ?? this.rightRow,
      rightCol: rightCol ?? this.rightCol,
      leftNonTerminals: leftNonTerminals ?? this.leftNonTerminals,
      rightNonTerminals: rightNonTerminals ?? this.rightNonTerminals,
      production: production ?? this.production,
      productionLeft: productionLeft ?? this.productionLeft,
      productionRight: productionRight ?? this.productionRight,
      addedNonTerminal: addedNonTerminal ?? this.addedNonTerminal,
      cellNonTerminals: cellNonTerminals ?? this.cellNonTerminals,
      terminal: terminal ?? this.terminal,
      isAccepted: isAccepted ?? this.isAccepted,
      cellModified: cellModified ?? this.cellModified,
    );
  }

  /// Converts the step to a JSON representation
  Map<String, dynamic> toJson() {
    return {
      'baseStep': baseStep.toJson(),
      'stepType': stepType.name,
      'tableState': tableState
          ?.map((row) => row.map((cell) => cell.toList()).toList())
          .toList(),
      'currentRow': currentRow,
      'currentCol': currentCol,
      'substring': substring,
      'substringStart': substringStart,
      'substringLength': substringLength,
      'splitPoint': splitPoint,
      'leftRow': leftRow,
      'leftCol': leftCol,
      'rightRow': rightRow,
      'rightCol': rightCol,
      'leftNonTerminals': leftNonTerminals?.toList(),
      'rightNonTerminals': rightNonTerminals?.toList(),
      'production': production,
      'productionLeft': productionLeft,
      'productionRight': productionRight,
      'addedNonTerminal': addedNonTerminal,
      'cellNonTerminals': cellNonTerminals?.toList(),
      'terminal': terminal,
      'isAccepted': isAccepted,
      'cellModified': cellModified,
    };
  }

  /// Creates a step from a JSON representation
  factory CYKStep.fromJson(Map<String, dynamic> json) {
    return CYKStep(
      baseStep: AlgorithmStep.fromJson(
        json['baseStep'] as Map<String, dynamic>,
      ),
      stepType: CYKStepType.values.firstWhere(
        (e) => e.name == json['stepType'],
        orElse: () => CYKStepType.initialize,
      ),
      tableState: (json['tableState'] as List?)
          ?.map(
            (row) => (row as List)
                .map((cell) => (cell as List).cast<String>().toSet())
                .toList(),
          )
          .toList(),
      currentRow: json['currentRow'] as int?,
      currentCol: json['currentCol'] as int?,
      substring: json['substring'] as String?,
      substringStart: json['substringStart'] as int?,
      substringLength: json['substringLength'] as int?,
      splitPoint: json['splitPoint'] as int?,
      leftRow: json['leftRow'] as int?,
      leftCol: json['leftCol'] as int?,
      rightRow: json['rightRow'] as int?,
      rightCol: json['rightCol'] as int?,
      leftNonTerminals: (json['leftNonTerminals'] as List?)
          ?.cast<String>()
          .toSet(),
      rightNonTerminals: (json['rightNonTerminals'] as List?)
          ?.cast<String>()
          .toSet(),
      production: json['production'] as String?,
      productionLeft: json['productionLeft'] as String?,
      productionRight: (json['productionRight'] as List?)?.cast<String>(),
      addedNonTerminal: json['addedNonTerminal'] as String?,
      cellNonTerminals: (json['cellNonTerminals'] as List?)
          ?.cast<String>()
          .toSet(),
      terminal: json['terminal'] as String?,
      isAccepted: json['isAccepted'] as bool? ?? false,
      cellModified: json['cellModified'] as bool? ?? false,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is CYKStep &&
        other.baseStep == baseStep &&
        other.stepType == stepType &&
        other.currentRow == currentRow &&
        other.currentCol == currentCol &&
        other.substring == substring &&
        other.production == production &&
        other.isAccepted == isAccepted;
  }

  @override
  int get hashCode {
    return Object.hash(
      baseStep,
      stepType,
      currentRow,
      currentCol,
      substring,
      production,
      isAccepted,
    );
  }

  @override
  String toString() {
    return 'CYKStep(stepNumber: ${baseStep.stepNumber}, '
        'type: ${stepType.name}, title: ${baseStep.title})';
  }

  /// Gets the step number
  int get stepNumber => baseStep.stepNumber;

  /// Gets the step title
  String get title => baseStep.title;

  /// Gets the step explanation
  String get explanation => baseStep.explanation;

  /// Locale-neutral title contract resolved at the presentation boundary.
  StructuredMessage? get titleMessage =>
      _cykMessageProperty(baseStep, cykStepTitleMessageProperty);

  /// Locale-neutral explanation contract resolved at the presentation boundary.
  StructuredMessage? get explanationMessage =>
      _cykMessageProperty(baseStep, cykStepExplanationMessageProperty);

  /// Locale-neutral title for the detailed step explanation.
  StructuredMessage? get stepExplanationTitleMessage =>
      baseStep.stepExplanation?.titleMessage;

  /// Locale-neutral bullets for the detailed step explanation.
  List<StructuredMessage> get stepExplanationBulletMessages =>
      baseStep.stepExplanation?.bulletMessages ?? const [];

  /// Short alias for consumers that treat the detailed explanation as bullets.
  List<StructuredMessage> get bulletMessages => stepExplanationBulletMessages;

  /// Gets cell coordinates as a string
  String? get cellCoordinates {
    if (currentRow != null && currentCol != null) {
      return '[$currentRow][$currentCol]';
    }
    return null;
  }

  /// Gets a summary of the production being applied
  String? get productionSummary {
    if (productionLeft != null &&
        productionRight != null &&
        productionRight!.length == 2) {
      return '$productionLeft → ${productionRight![0]} ${productionRight![1]}';
    }
    return production;
  }

  /// Checks if this step involves a split
  bool get involvesSplit => splitPoint != null;

  /// Checks if this step adds a non-terminal to a cell
  bool get addsNonTerminal => addedNonTerminal != null;

  /// Gets the number of non-terminals in the current cell
  int get cellNonTerminalCount => cellNonTerminals?.length ?? 0;
}

AlgorithmStep _cykBaseStep({
  required String id,
  required int stepNumber,
  required String title,
  required String explanation,
  required StepExplanation stepExplanation,
  required StructuredMessage titleMessage,
  required StructuredMessage explanationMessage,
  required StructuredMessage stepExplanationTitleMessage,
  required List<StructuredMessage> bulletMessages,
}) {
  final structuredStepExplanation = StepExplanation(
    titleMessage: stepExplanationTitleMessage,
    bulletMessages: bulletMessages,
    categories: stepExplanation.categories,
    highlights: stepExplanation.highlights,
    suggestedFixes: stepExplanation.suggestedFixes,
  );
  return AlgorithmStep(
    id: id,
    stepNumber: stepNumber,
    title: title,
    explanation: explanation,
    stepExplanation: structuredStepExplanation,
    type: AlgorithmType.cykParsing,
    properties: {
      cykStepTitleMessageProperty: titleMessage.toJson(),
      cykStepExplanationMessageProperty: explanationMessage.toJson(),
    },
  );
}

StructuredMessage? _cykMessageProperty(AlgorithmStep step, String key) {
  final raw = step.properties[key];
  if (raw is! Map) return null;
  try {
    return StructuredMessage.fromJson(Map<String, Object?>.from(raw));
  } on FormatException {
    return null;
  }
}

/// Types of steps in CYK parsing algorithm
enum CYKStepType {
  /// Initializing the parse table
  initialize,

  /// Filling base case cell (single character)
  fillBaseCase,

  /// Starting to process a cell
  processCell,

  /// Checking a specific split point
  checkSplit,

  /// Applying a production rule
  applyProduction,

  /// Completing cell processing
  completeCell,

  /// Checking string acceptance
  checkAcceptance,

  /// Parsing completion
  completion,
}

/// Extension methods for CYKStepType
extension CYKStepTypeExtension on CYKStepType {
  /// Gets a human-readable name for the step type
  String get displayName {
    switch (this) {
      case CYKStepType.initialize:
        return 'Initialize';
      case CYKStepType.fillBaseCase:
        return 'Fill Base Case';
      case CYKStepType.processCell:
        return 'Process Cell';
      case CYKStepType.checkSplit:
        return 'Check Split';
      case CYKStepType.applyProduction:
        return 'Apply Production';
      case CYKStepType.completeCell:
        return 'Complete Cell';
      case CYKStepType.checkAcceptance:
        return 'Check Acceptance';
      case CYKStepType.completion:
        return 'Completion';
    }
  }

  /// Gets a description of what this step type does
  String get description {
    switch (this) {
      case CYKStepType.initialize:
        return 'Initializes the CYK parse table for the input string';
      case CYKStepType.fillBaseCase:
        return 'Fills a base case cell for a single terminal symbol';
      case CYKStepType.processCell:
        return 'Begins processing a cell for a substring of length > 1';
      case CYKStepType.checkSplit:
        return 'Checks a specific split point to find applicable productions';
      case CYKStepType.applyProduction:
        return 'Applies a production rule and adds a non-terminal to the cell';
      case CYKStepType.completeCell:
        return 'Completes processing of a cell with all applicable non-terminals';
      case CYKStepType.checkAcceptance:
        return 'Checks if the start symbol is in the final cell to determine acceptance';
      case CYKStepType.completion:
        return 'Marks the completion of the CYK parsing algorithm';
    }
  }
}
