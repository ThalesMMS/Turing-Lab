import 'package:flutter_test/flutter_test.dart';
import 'package:turing_lab/core/algorithms/cfg/cyk_parser_messages.dart';
import 'package:turing_lab/core/algorithms/cfg_toolkit_messages.dart';
import 'package:turing_lab/core/algorithms/dfa_minimizer_messages.dart';
import 'package:turing_lab/core/algorithms/dfa_operations_messages.dart';
import 'package:turing_lab/core/algorithms/fsa_determinizer_messages.dart';
import 'package:turing_lab/core/algorithms/grammar_to_pda/cfg_to_pda_messages.dart';
import 'package:turing_lab/core/algorithms/grammar_parser_messages.dart';
import 'package:turing_lab/core/algorithms/grammar_to_fsa_messages.dart';
import 'package:turing_lab/core/algorithms/language_comparison_step_messages.dart';
import 'package:turing_lab/core/algorithms/lr1_parser_messages.dart';
import 'package:turing_lab/core/algorithms/nfa_to_dfa_messages.dart';
import 'package:turing_lab/core/algorithms/pda_simulation_messages.dart';
import 'package:turing_lab/core/algorithms/pda_simulator_analysis_messages.dart';
import 'package:turing_lab/core/algorithms/tm_messages.dart';
import 'package:turing_lab/core/algorithms/tm_building_block_messages.dart';
import 'package:turing_lab/core/algorithms/fsa_to_grammar_messages.dart';
import 'package:turing_lab/core/algorithms/tm_multi_tape_messages.dart';
import 'package:turing_lab/core/algorithms/tm_to_grammar_messages.dart';
import 'package:turing_lab/core/messages/structured_message.dart';
import 'package:turing_lab/core/models/cyk_step_messages.dart';
import 'package:turing_lab/core/models/dfa_minimization_step_messages.dart';
import 'package:turing_lab/core/models/nfa_to_dfa_step_messages.dart';
import 'package:turing_lab/core/validators/validation_messages.dart';
import 'package:turing_lab/core/algorithms/tm_to_unrestricted_grammar/tm_to_grammar_models.dart';
import 'package:turing_lab/l10n/app_localizations_en.dart';
import 'package:turing_lab/l10n/app_localizations_pt.dart';
import 'package:turing_lab/l10n/app_localizations_structured_messages.dart';

void main() {
  final en = AppLocalizationsEn();
  final pt = AppLocalizationsPt();

  test('resolves the structured diagnostics added in this wave', () {
    final messages = <StructuredMessage>[
      ..._fsaToGrammarMessages(),
      ..._grammarToFsaMessages(),
      ..._dfaMessages(),
      ..._nfaToDfaMessages(),
      ..._pdaMessages(),
      ..._cfgToPdaMessages(),
      ..._dfaStepMessages(),
      ..._nfaStepMessages(),
      ..._cykStepMessages(),
      ..._validationMessages(),
      FsaDeterminizerMessages.failed('NFA input'),
      ..._parserMessages(),
      ..._languageComparisonTraceMessages(),
      ..._tmMessages(),
      ..._tmMultiTapeMessages(),
      ..._tmBuildingBlockMessages(),
      ..._tmToGrammarMessages(),
    ];

    expect(messages, isNotEmpty);
    for (final message in messages) {
      final restored = StructuredMessage.fromJson(message.toJson());
      final english = en.resolveStructuredMessage(restored);
      final portuguese = pt.resolveStructuredMessage(restored);
      expect(restored, message, reason: message.stableCode);
      expect(
        english,
        isNot(contains(message.stableCode)),
        reason: message.stableCode,
      );
      expect(
        portuguese,
        isNot(contains(message.stableCode)),
        reason: message.stableCode,
      );
      expect(english, isNot(portuguese), reason: message.stableCode);
    }
  });
}

List<StructuredMessage> _fsaToGrammarMessages() => [
  FsaToGrammarMessages.emptyAutomaton(),
  FsaToGrammarMessages.missingInitialState(),
  FsaToGrammarMessages.initialStateOutsideSet(),
  FsaToGrammarMessages.acceptingStateOutsideSet(),
];

List<StructuredMessage> _grammarToFsaMessages() => [
  GrammarToFsaMessages.missingNonterminals(),
  GrammarToFsaMessages.undeclaredStartSymbol(),
  GrammarToFsaMessages.leftSideNotSingle('p-left'),
  GrammarToFsaMessages.unknownLeftNonterminal('p-left', 'X'),
  GrammarToFsaMessages.unknownRightNonterminal('p-right', 'X'),
  GrammarToFsaMessages.tooManyRightSymbols('p-long'),
  GrammarToFsaMessages.firstSymbolNotTerminal('p-first'),
  GrammarToFsaMessages.lastSymbolNotNonterminal('p-last'),
];

List<StructuredMessage> _dfaMessages() => [
  DfaOperationsMessages.missingInitialState('DFA for complement'),
  DfaOperationsMessages.nondeterministic('DFA'),
  DfaOperationsMessages.epsilonTransitionsNotAllowed('DFA for suffix closure'),
  DfaOperationsMessages.symbolOutsideAlphabet('Operand A', 'x'),
  DfaOperationsMessages.emptyAlphabetWithLabeledTransitions('Operand B'),
  DfaOperationsMessages.bothOperandsMissingInitialState(),
  DfaOperationsMessages.operationFailed('∪'),
  DfaOperationsMessages.epsilonRemovalFailed(),
  DfaMinimizerMessages.emptyDfa(),
  DfaMinimizerMessages.missingInitialState(),
  DfaMinimizerMessages.initialStateOutsideSet(),
  DfaMinimizerMessages.acceptingStateOutsideSet(),
  DfaMinimizerMessages.nondeterministicInput(),
  DfaMinimizerMessages.minimizationFailed(),
  DfaMinimizerMessages.minimizationWithStepsFailed(),
];

List<StructuredMessage> _nfaToDfaMessages() => [
  NfaToDfaMessages.emptyAutomaton(),
  NfaToDfaMessages.missingInitialState(),
  NfaToDfaMessages.initialStateOutsideSet(),
  NfaToDfaMessages.acceptingStateOutsideSet(),
  NfaToDfaMessages.stateLimitExceeded(12),
  NfaToDfaMessages.conversionFailed(error: 'boom', withSteps: true),
];

List<StructuredMessage> _pdaMessages() => [
  PDASimulationMessages.emptyStateSet(),
  PDASimulationMessages.missingInitialState(),
  PDASimulationMessages.initialStateOutsideSet(),
  PDASimulationMessages.acceptingStateOutsideSet(),
  PDASimulationMessages.searchLimitsNegative(),
  PDASimulationMessages.memoryLimitNegative(),
  PDASimulationMessages.configurationsPerBatchInvalid(),
  PDASimulationMessages.simulationFailure(operation: 'search', error: 'boom'),
  PDASimulationMessages.acceptedStringsFailure('boom'),
  PDASimulationMessages.rejectedStringsFailure('boom'),
  PDASimulationMessages.timeout(),
  PDASimulationMessages.infiniteLoop(),
  PDASimulationMessages.configurationLimit(),
  PDASimulationMessages.depthLimit(),
  PDASimulationMessages.memoryLimit(),
  PDASimulationMessages.staleRequest(),
  PDASimulationMessages.rejectedNoAcceptingConfiguration(),
  PDASimulationMessages.transitionTitle(),
  PDASimulationMessages.readInput('a'),
  PDASimulationMessages.stackAction(popSymbol: 'Z', pushSymbol: 'A'),
  PDASimulationMessages.stackTopChange(before: 'Z', after: 'A'),
  PDASimulationMessages.popMatches('Z'),
  PDASimulationMessages.noPop(),
  PDASimulationMessages.pushed('A'),
  PDASimulationMessages.noPush(),
  PDASimulationMessages.epsilonMove(),
  PdaAnalysisMessages.emptyPda(),
  PdaAnalysisMessages.invalidMaxInputLength(),
  PdaAnalysisMessages.invalidTimeout(),
  PdaAnalysisMessages.timedOut(),
  PdaAnalysisMessages.failure('boom'),
];

List<StructuredMessage> _cfgToPdaMessages() => [
  CfgToPdaMessages.emptyGrammar(),
  CfgToPdaMessages.missingStartSymbol(),
  CfgToPdaMessages.undeclaredStartSymbol('S'),
  CfgToPdaMessages.malformedProduction('p1'),
  CfgToPdaMessages.duplicateProductionId('p1'),
  CfgToPdaMessages.undeclaredSymbol(productionId: 'p1', symbol: 'X'),
  CfgToPdaMessages.llAnalysisFailed(),
  CfgToPdaMessages.llConflict(
    nonTerminal: 'S',
    lookahead: 'a',
    productionIds: 'p1 / p2',
  ),
  CfgToPdaMessages.lrConstructionUnavailable(),
  CfgToPdaMessages.lrConflict(
    state: 2,
    lookahead: 'a',
    productionIds: 'p1 / p2',
  ),
  CfgToPdaMessages.outputInvalid(),
];

List<StructuredMessage> _dfaStepMessages() => [
  DfaMinimizationStepMessages.initialPartitionTitle(),
  DfaMinimizationStepMessages.initialPartitionExplanation(
    acceptingStates: 'q1',
    nonAcceptingStates: 'q0',
  ),
  DfaMinimizationStepMessages.removeUnreachableTitle(),
  DfaMinimizationStepMessages.removeUnreachableExplanation(
    unreachableStates: 'q2',
    reachableStateCount: 2,
  ),
  DfaMinimizationStepMessages.selectSetTitle(),
  DfaMinimizationStepMessages.selectSetExplanation('q0, q1'),
  DfaMinimizationStepMessages.findPredecessorsTitle('a'),
  DfaMinimizationStepMessages.findPredecessorsExplanation(
    states: 'q0',
    symbol: 'a',
    predecessors: 'q1',
    hasPredecessors: true,
  ),
  DfaMinimizationStepMessages.splitClassTitle(),
  DfaMinimizationStepMessages.splitClassExplanation(
    splitStates: 'q0, q1',
    symbol: 'a',
    intersectionStates: 'q0',
    differenceStates: 'q1',
    oldPartitionSize: 2,
    newPartitionSize: 3,
  ),
  DfaMinimizationStepMessages.noSplitTitle('a'),
  DfaMinimizationStepMessages.noSplitExplanation(states: 'q0, q1', symbol: 'a'),
  DfaMinimizationStepMessages.partitionStableTitle(),
  DfaMinimizationStepMessages.partitionStableExplanation(3),
  DfaMinimizationStepMessages.createMinimizedStateTitle('C0'),
  DfaMinimizationStepMessages.createMinimizedStateExplanation(
    stateId: 'C0',
    equivalenceClass: 'q0, q1',
    isInitial: true,
    isAccepting: false,
  ),
  DfaMinimizationStepMessages.createMinimizedTransitionTitle('a'),
  DfaMinimizationStepMessages.createMinimizedTransitionExplanation(
    fromState: 'C0',
    toState: 'C1',
    symbol: 'a',
  ),
  DfaMinimizationStepMessages.completionTitle(),
  DfaMinimizationStepMessages.completionExplanation(
    originalStateCount: 4,
    minimizedStateCount: 3,
    transitionCount: 6,
    reduction: 1,
  ),
];

List<StructuredMessage> _nfaStepMessages() => [
  NfaToDfaStepMessages.initialEpsilonClosureTitle(),
  NfaToDfaStepMessages.initialEpsilonClosureExplanation(
    initialState: 'q0',
    epsilonClosure: '{q0, q1}',
    containsAcceptingState: true,
  ),
  NfaToDfaStepMessages.initialEpsilonClosureStepTitle(),
  ...NfaToDfaStepMessages.initialEpsilonClosureBullets(
    initialState: 'q0',
    epsilonClosure: '{q0, q1}',
    containsAcceptingState: true,
  ),
  NfaToDfaStepMessages.processSymbolTitle('a'),
  NfaToDfaStepMessages.processSymbolExplanation(
    currentStates: '{q0}',
    symbol: 'a',
    reachableStates: '{q1}',
  ),
  NfaToDfaStepMessages.processSymbolStepTitle(),
  ...NfaToDfaStepMessages.processSymbolBullets(
    currentStates: '{q0}',
    symbol: 'a',
    reachableStates: '{q1}',
  ),
  NfaToDfaStepMessages.epsilonClosureOfReachableTitle(),
  NfaToDfaStepMessages.epsilonClosureOfReachableExplanation(
    reachableStates: '{q1}',
    epsilonClosure: '{q1, q2}',
    isNewState: true,
    containsAcceptingState: true,
  ),
  NfaToDfaStepMessages.epsilonClosureOfReachableStepTitle(),
  ...NfaToDfaStepMessages.epsilonClosureOfReachableBullets(
    reachableStates: '{q1}',
    epsilonClosure: '{q1, q2}',
    isNewState: true,
    containsAcceptingState: true,
  ),
  NfaToDfaStepMessages.createDfaStateTitle('D1'),
  NfaToDfaStepMessages.createDfaStateExplanation(
    dfaStateId: 'D1',
    stateSet: '{q1, q2}',
    isAccepting: true,
  ),
  NfaToDfaStepMessages.createDfaStateStepTitle(),
  ...NfaToDfaStepMessages.createDfaStateBullets(
    stateSet: '{q1, q2}',
    isAccepting: true,
  ),
  NfaToDfaStepMessages.createDfaTransitionTitle('a'),
  NfaToDfaStepMessages.createDfaTransitionExplanation(
    fromDfaStateId: 'D0',
    symbol: 'a',
    toDfaStateId: 'D1',
    fromStates: '{q0}',
    toStates: '{q1}',
  ),
  NfaToDfaStepMessages.createDfaTransitionStepTitle(),
  ...NfaToDfaStepMessages.createDfaTransitionBullets(
    fromStates: '{q0}',
    symbol: 'a',
    toStates: '{q1}',
  ),
  NfaToDfaStepMessages.completionTitle(),
  NfaToDfaStepMessages.completionExplanation(
    totalStates: 2,
    totalTransitions: 1,
    totalAcceptingStates: 1,
  ),
  NfaToDfaStepMessages.completionStepTitle(),
  ...NfaToDfaStepMessages.completionBullets(
    totalStates: 2,
    totalTransitions: 1,
    totalAcceptingStates: 1,
  ),
];

List<StructuredMessage> _cykStepMessages() => [
  CykStepMessages.initializeTitle(),
  CykStepMessages.initializeExplanation(inputString: 'a b', tableSize: 2),
  CykStepMessages.initializeStepTitle(),
  CykStepMessages.initializeInputBullet(inputString: 'a b', tableSize: 2),
  CykStepMessages.initializeTableBullet(),
  CykStepMessages.fillBaseCaseTitle('a'),
  CykStepMessages.fillBaseCaseExplanation(
    position: 0,
    terminal: 'a',
    derivingVariables: 'A, B',
    hasDerivingVariables: true,
  ),
  CykStepMessages.fillBaseCaseStepTitle('a'),
  CykStepMessages.fillBaseCaseFragmentBullet(position: 0, terminal: 'a'),
  CykStepMessages.fillBaseCaseProductionBullet(),
  CykStepMessages.fillBaseCaseEmptyBullet('a'),
  CykStepMessages.fillBaseCaseAddedBullet('A, B'),
  CykStepMessages.processCellTitle(row: 1, col: 0),
  CykStepMessages.processCellExplanation(
    row: 1,
    col: 0,
    substring: 'a b',
    length: 2,
  ),
  CykStepMessages.processCellStepTitle('a b'),
  CykStepMessages.processCellLocationBullet(row: 1, col: 0, length: 2),
  CykStepMessages.processCellSplitBullet(),
  CykStepMessages.checkSplitTitle(1),
  CykStepMessages.checkSplitExplanation(
    substring: 'a b',
    leftSubstring: 'a',
    rightSubstring: 'b',
    leftRow: 0,
    leftCol: 0,
    rightRow: 0,
    rightCol: 1,
    leftNonTerminals: 'A',
    rightNonTerminals: 'B',
  ),
  CykStepMessages.checkSplitStepTitle(leftSubstring: 'a', rightSubstring: 'b'),
  CykStepMessages.checkSplitLeftBullet(row: 0, col: 0, variables: 'A'),
  CykStepMessages.checkSplitRightBullet(row: 0, col: 1, variables: 'B'),
  CykStepMessages.checkSplitProductionBullet(row: 1, col: 0),
  CykStepMessages.applyProductionTitle(
    variable: 'S',
    leftVariable: 'A',
    rightVariable: 'B',
  ),
  CykStepMessages.applyProductionExplanation(
    row: 1,
    col: 0,
    variable: 'S',
    leftVariable: 'A',
    rightVariable: 'B',
    substring: 'a b',
  ),
  CykStepMessages.applyProductionStepTitle(
    variable: 'S',
    leftVariable: 'A',
    rightVariable: 'B',
  ),
  CykStepMessages.applyProductionCombineBullet(),
  CykStepMessages.applyProductionDerivationBullet(
    leftVariable: 'A',
    rightVariable: 'B',
    variable: 'S',
    substring: 'a b',
  ),
  CykStepMessages.applyProductionAddBullet(row: 1, col: 0, variable: 'S'),
  CykStepMessages.completeCellTitle(row: 1, col: 0),
  CykStepMessages.completeCellExplanation(
    row: 1,
    col: 0,
    substring: 'a b',
    nonTerminals: 'S',
    hasNonTerminals: true,
  ),
  CykStepMessages.completeCellStepTitle(row: 1, col: 0),
  CykStepMessages.completeCellSubstringBullet('a b'),
  CykStepMessages.completeCellEmptyBullet(),
  CykStepMessages.completeCellNonTerminalsBullet('S'),
  CykStepMessages.checkAcceptanceTitle(),
  CykStepMessages.checkAcceptanceExplanation(
    inputString: 'a b',
    startSymbol: 'S',
    finalNonTerminals: 'S',
    hasFinalNonTerminals: true,
    isAccepted: true,
  ),
  CykStepMessages.checkAcceptanceStepTitle(),
  CykStepMessages.checkAcceptanceFinalCellBullet('S'),
  CykStepMessages.checkAcceptanceAcceptedBullet('S'),
  CykStepMessages.checkAcceptanceRejectedBullet('S'),
  CykStepMessages.completionTitle(),
  CykStepMessages.completionExplanation(
    inputString: 'a b',
    totalCells: 3,
    filledCells: 2,
    isAccepted: true,
  ),
  CykStepMessages.completionStepTitle(),
  CykStepMessages.completionFilledCellsBullet(totalCells: 3, filledCells: 2),
  CykStepMessages.completionAcceptedBullet(),
  CykStepMessages.completionRejectedBullet(),
];

List<StructuredMessage> _validationMessages() => [
  ValidationMessages.forCode('FSA_EMPTY'),
  ValidationMessages.forCode('FSA_NO_INITIAL'),
  ValidationMessages.forCode(
    'FSA_INVALID_INITIAL',
    arguments: {
      'state': StructuredMessageArgument.identifier('q1', role: 'state-id'),
    },
  ),
  ValidationMessages.forCode('FSA_EMPTY_ALPHABET'),
  ValidationMessages.forCode(
    'FSA_INVALID_ACCEPTING',
    arguments: {
      'state': StructuredMessageArgument.identifier('q2', role: 'state-id'),
    },
  ),
  ValidationMessages.forCode(
    'FSA_BAD_FROM',
    arguments: {
      'state': StructuredMessageArgument.identifier('q3', role: 'state-id'),
    },
  ),
  ValidationMessages.forCode(
    'FSA_BAD_TO',
    arguments: {
      'state': StructuredMessageArgument.identifier('q4', role: 'state-id'),
    },
  ),
  ValidationMessages.forCode(
    'FSA_BAD_SYMBOL',
    arguments: {
      'symbol': StructuredMessageArgument.symbol('x', role: 'input-symbol'),
    },
  ),
  ValidationMessages.forCode(
    'FSA_NONDETERMINISTIC',
    arguments: {
      'state': StructuredMessageArgument.identifier('q0', role: 'state-id'),
      'count': StructuredMessageArgument.count(2, role: 'transition-count'),
      'symbol': StructuredMessageArgument.symbol('a', role: 'input-symbol'),
    },
  ),
  ValidationMessages.forCode('PDA_EMPTY'),
  ValidationMessages.forCode('PDA_NO_INITIAL'),
  ValidationMessages.forCode(
    'PDA_INVALID_INITIAL',
    arguments: {
      'state': StructuredMessageArgument.identifier('q1', role: 'state-id'),
    },
  ),
  ValidationMessages.forCode('PDA_NO_ACCEPTING'),
  ValidationMessages.forCode('PDA_EMPTY_INPUT_ALPHABET'),
  ValidationMessages.forCode('PDA_EMPTY_STACK_ALPHABET'),
  ValidationMessages.forCode(
    'PDA_INVALID_INITIAL_STACK',
    arguments: {
      'symbol': StructuredMessageArgument.symbol('Z', role: 'stack-symbol'),
    },
  ),
  ValidationMessages.forCode(
    'PDA_INVALID_ACCEPTING',
    arguments: {
      'state': StructuredMessageArgument.identifier('q2', role: 'state-id'),
    },
  ),
  ValidationMessages.forCode(
    'PDA_BAD_FROM',
    arguments: {
      'state': StructuredMessageArgument.identifier('q3', role: 'state-id'),
    },
  ),
  ValidationMessages.forCode(
    'PDA_BAD_TO',
    arguments: {
      'state': StructuredMessageArgument.identifier('q4', role: 'state-id'),
    },
  ),
  ValidationMessages.forCode(
    'PDA_BAD_INPUT_SYMBOL',
    arguments: {
      'symbol': StructuredMessageArgument.symbol('x', role: 'input-symbol'),
    },
  ),
  ValidationMessages.forCode(
    'PDA_BAD_STACK_SYMBOL',
    arguments: {
      'symbol': StructuredMessageArgument.symbol('X', role: 'stack-symbol'),
    },
  ),
  ValidationMessages.forCode(
    'PDA_BAD_PUSH_SYMBOL',
    arguments: {
      'symbol': StructuredMessageArgument.symbol('Y', role: 'stack-symbol'),
    },
  ),
];

List<StructuredMessage> _parserMessages() => [
  CfgToolkitMessages.reduceFailed(),
  CfgToolkitMessages.toCnfFailed(),
  CfgToolkitMessages.toGnfFailed(),
  CykParserMessages.timedOut(),
  CykParserMessages.inputRejected('a'),
  CykParserMessages.parseFailed(),
  GrammarParserMessages.emptyGrammar(),
  GrammarParserMessages.missingStartSymbol(),
  GrammarParserMessages.startSymbolNotNonterminal(),
  GrammarParserMessages.inputRejected('a'),
  GrammarParserMessages.allStrategiesFailed('cyk'),
  GrammarParserMessages.generatedStringsFailed(),
  GrammarParserMessages.ll1StepLimitInvalid(0),
  GrammarParserMessages.ll1Conflict(
    nonTerminal: 'S',
    lookahead: 'a',
    alternatives: 'p1 / p2',
  ),
  GrammarParserMessages.ll1Cancelled(),
  GrammarParserMessages.ll1TimedOut(const Duration(milliseconds: 20)),
  GrammarParserMessages.ll1StepLimitReached(10),
  GrammarParserMessages.ll1TrailingInput(lookahead: 'a', position: 1),
  GrammarParserMessages.ll1UnexpectedEnd('a'),
  GrammarParserMessages.ll1TerminalMismatch(
    expected: 'a',
    found: 'b',
    position: 1,
  ),
  GrammarParserMessages.ll1EmptyTableCell(
    nonTerminal: 'S',
    lookahead: 'a',
    expected: 'a',
  ),
  GrammarParserMessages.ll1EmptyStack(),
  GrammarParserMessages.earleyMalformedProduction(),
  GrammarParserMessages.earleyMissingStartSymbol(),
  GrammarParserMessages.earleyTimedOut(const Duration(milliseconds: 20)),
  GrammarParserMessages.recursiveDescentTimedOut(),
  GrammarParserMessages.recursiveDescentFailed(),
  Lr1ParserMessages.staleConstruction(),
  Lr1ParserMessages.invalidGrammar(),
  Lr1ParserMessages.missingStartSymbol(),
  Lr1ParserMessages.malformedProduction(),
  Lr1ParserMessages.duplicateProductionId('p1'),
  Lr1ParserMessages.undeclaredSymbol(productionId: 'p1', symbol: 'X'),
  Lr1ParserMessages.constructionCancelled(),
  Lr1ParserMessages.constructionTimedOut(const Duration(milliseconds: 20)),
  Lr1ParserMessages.constructionStateLimit(),
  Lr1ParserMessages.constructionItemLimit(),
  Lr1ParserMessages.conflict(stateId: 'I1', lookahead: 'a'),
  Lr1ParserMessages.cancelled(),
  Lr1ParserMessages.timedOut(const Duration(milliseconds: 20)),
  Lr1ParserMessages.stepLimitReached(10),
  Lr1ParserMessages.emptyActionCell(stateId: 'I1', lookahead: 'a'),
  Lr1ParserMessages.actionConflict(stateId: 'I1', lookahead: 'a'),
  Lr1ParserMessages.invalidParserState(),
  Lr1ParserMessages.missingGoto(stateId: 'I1', nonTerminal: 'S'),
  Lr1ParserMessages.shifted(symbol: 'a', targetState: 'I2'),
  Lr1ParserMessages.reduced(productionId: 'p1', leftSide: 'S', rightSide: 'ε'),
  Lr1ParserMessages.accepted(),
];

List<StructuredMessage> _languageComparisonTraceMessages() => [
  LanguageComparisonStepMessages.validation(),
  LanguageComparisonStepMessages.initialization(),
  LanguageComparisonStepMessages.alphabetNormalization(),
  LanguageComparisonStepMessages.nfaToDfa('A'),
  LanguageComparisonStepMessages.dfaCompletion('B'),
  LanguageComparisonStepMessages.productConstructionStart(),
  LanguageComparisonStepMessages.productStateCreated('(q0,q1)'),
  LanguageComparisonStepMessages.productTransitionCreated('a'),
  LanguageComparisonStepMessages.productConstructionComplete(),
  LanguageComparisonStepMessages.bfsSearchStart(),
  LanguageComparisonStepMessages.bfsInitialCheck(
    acceptsA: true,
    acceptsB: false,
  ),
  LanguageComparisonStepMessages.bfsExplorePair(stateA: 'q0', stateB: 'q1'),
  LanguageComparisonStepMessages.bfsDistinguishingFound('ab'),
  LanguageComparisonStepMessages.bfsComplete(),
  LanguageComparisonStepMessages.result(isEquivalent: false),
  LanguageComparisonStepMessages.error(),
  LanguageComparisonStepMessages.unknown('future-step'),
];

List<StructuredMessage> _tmMessages() => [
  TmSimulationMessages.emptyMachine(),
  TmSimulationMessages.missingInitialState(),
  TmSimulationMessages.initialStateOutsideSet(),
  TmSimulationMessages.acceptingStateOutsideSet(),
  TmSimulationMessages.invalidInputSymbol('x'),
  TmSimulationMessages.operationsPerBatchInvalid(),
  TmSimulationMessages.nondeterministicConflict(
    count: 2,
    state: 'q0',
    symbol: 'a',
  ),
  TmSimulationMessages.rejectedNoAcceptingConfiguration(),
  TmSimulationMessages.inputNotAccepted(),
  TmSimulationMessages.timeout(),
  TmSimulationMessages.infiniteLoop(),
  TmSimulationMessages.stepLimit(),
  TmSimulationMessages.configurationLimit(),
  TmSimulationMessages.simulationFailure(mode: 'dtm', error: 'boom'),
  TmSimulationMessages.simulationFailure(mode: 'ntm', error: 'boom'),
  TmSimulationMessages.simulationFailure(mode: 'simulation', error: 'boom'),
  TmSimulationMessages.acceptedStringsFailure('boom'),
  TmSimulationMessages.rejectedStringsFailure('boom'),
  TmSimulationMessages.analysisFailure('boom'),
  TmSimulationMessages.transitionTitle(),
  TmSimulationMessages.readSymbol(symbol: 'a', position: 0, state: 'q0'),
  TmSimulationMessages.appliedRule(
    fromState: 'q0',
    readSymbol: 'a',
    toState: 'q1',
    writeSymbol: 'b',
    direction: 'L',
  ),
  TmSimulationMessages.wroteSymbol(symbol: 'b', position: 0),
  TmSimulationMessages.movedHead(direction: 'R', position: 1),
  TmExecutionMessages.emptyMachine(),
  TmExecutionMessages.missingInitialState(),
  TmExecutionMessages.stepLimitInvalid(),
  TmExecutionMessages.configurationLimitInvalid(),
  TmExecutionMessages.timeoutInvalid(),
  TmExecutionMessages.operationsPerBatchInvalid(),
  TmExecutionMessages.invalidInputSymbol('x'),
  TmExecutionMessages.invalidMachine('bad'),
  TmExecutionMessages.cancelled(),
  TmExecutionMessages.timeoutBeforeResolution(),
  TmExecutionMessages.enteredFinalState('finalState'),
  TmExecutionMessages.haltedAccepted('halting'),
  TmExecutionMessages.haltedRejected(),
  TmExecutionMessages.deterministicConflict(count: 2, state: 'q0', symbol: 'a'),
  TmExecutionMessages.deterministicStepLimit(),
  TmExecutionMessages.configurationLimit(),
  TmExecutionMessages.deterministicCycle(),
  TmExecutionMessages.branchStepLimit(),
  TmExecutionMessages.everyBranchRejected(),
  TmExecutionMessages.exploredGraphRejected(),
  TmSpaceProfileMessages.emptyMachine(),
  TmSpaceProfileMessages.missingInitialState(),
  TmSpaceProfileMessages.maxInputLengthInvalid(),
  TmSpaceProfileMessages.candidateCapInvalid(),
  TmSpaceProfileMessages.stepLimitInvalid(),
  TmSpaceProfileMessages.configurationLimitInvalid(),
  TmSpaceProfileMessages.timeoutInvalid(),
  TmSpaceProfileMessages.operationsPerBatchInvalid(),
  TmSpaceProfileMessages.missingSpaceMetrics(),
  TmTimeProfileMessages.maxLengthInvalid(),
  TmTimeProfileMessages.candidateCapInvalid(),
  TmTimeProfileMessages.stepLimitInvalid(),
  TmTimeProfileMessages.configurationLimitInvalid(),
  TmTimeProfileMessages.timeoutInvalid(),
  TmTimeProfileMessages.operationsPerBatchInvalid(),
  TmTimeProfileMessages.complete(),
  TmTimeProfileMessages.incomplete(),
  TmTimeProfileMessages.cancelled(),
  TmTimeProfileMessages.invalidMachine(),
  TmReachabilityMessages.emptyMachine(),
  TmReachabilityMessages.invalidInitialState(),
  TmReachabilityMessages.inputsRequired(),
  TmReachabilityMessages.stepLimitInvalid(),
  TmReachabilityMessages.configurationLimitInvalid(),
  TmReachabilityMessages.timeoutInvalid(),
  TmReachabilityMessages.operationsPerBatchInvalid(),
  TmReachabilityMessages.nonTmTransition(),
  TmReachabilityMessages.transitionEndpointOutsideSet('t1'),
  TmReachabilityMessages.inputSymbolOutsideAlphabet(input: 'b', symbol: 'b'),
  TmReachabilityMessages.cancelled(),
  TmReachabilityMessages.timeout(),
  TmReachabilityMessages.configurationLimit(),
  TmReachabilityMessages.stepLimit(),
  TmReachabilityMessages.complete(),
  TmLanguageExplorerMessages.maxInputLengthInvalid(),
  TmLanguageExplorerMessages.candidateCapInvalid(),
  TmLanguageExplorerMessages.stepLimitInvalid(),
  TmLanguageExplorerMessages.configurationLimitInvalid(),
  TmLanguageExplorerMessages.timeoutInvalid(),
  TmLanguageExplorerMessages.operationsPerBatchInvalid(),
];

List<StructuredMessage> _tmMultiTapeMessages() => [
  TmMultiTapeMessages.cancelled(),
  TmMultiTapeMessages.timeout(),
  TmMultiTapeMessages.configurationLimit(),
  TmMultiTapeMessages.enteredFinalState('finalState'),
  TmMultiTapeMessages.branchEnteredFinalState('halting'),
  TmMultiTapeMessages.haltedAccepted('finalStateOrHalting'),
  TmMultiTapeMessages.branchHaltedAccepted('halting'),
  TmMultiTapeMessages.deterministicConflict(),
  TmMultiTapeMessages.deterministicCycle(),
  TmMultiTapeMessages.stepLimit(),
  TmMultiTapeMessages.haltedRejected(),
  TmMultiTapeMessages.everyBranchRejected(),
];

List<StructuredMessage> _tmBuildingBlockMessages() => [
  TmBuildingBlockMessages.duplicateMachineId('block-a'),
  TmBuildingBlockMessages.emptyBlockName('block-a'),
  TmBuildingBlockMessages.duplicateBlockName(
    firstBlockId: 'block-a',
    secondBlockId: 'block-b',
  ),
  TmBuildingBlockMessages.missingInitialState('block-a'),
  TmBuildingBlockMessages.missingRootInitialState(),
  TmBuildingBlockMessages.tapeCountMismatch(
    blockName: 'block-a',
    blockTapeCount: 1,
    rootTapeCount: 2,
  ),
  TmBuildingBlockMessages.blankSymbolMismatch('block-a'),
  TmBuildingBlockMessages.nestedLibrary('block-a'),
  TmBuildingBlockMessages.recursiveDependency('block-a → block-b → block-a'),
  TmBuildingBlockMessages.duplicateInvocationId('call-1'),
  TmBuildingBlockMessages.duplicateInvocationState('q1'),
  TmBuildingBlockMessages.missingAnchorState('call-1'),
  TmBuildingBlockMessages.missingReference(
    invocationId: 'call-1',
    blockId: 'block-a',
  ),
  TmBuildingBlockMessages.revisionMismatch(
    invocationId: 'call-1',
    expectedRevision: 2,
    blockName: 'block-a',
    actualRevision: 1,
  ),
  TmBuildingBlockMessages.acceptingRootInvocation(
    invocationId: 'call-1',
    blockId: 'block-a',
  ),
  TmBuildingBlockMessages.invalidProject(),
  TmBuildingBlockMessages.cancelled(),
  TmBuildingBlockMessages.timeout(),
  TmBuildingBlockMessages.configurationLimit(),
  TmBuildingBlockMessages.callDepthLimit(),
  TmBuildingBlockMessages.stepLimit(),
  TmBuildingBlockMessages.enteredFinalState('finalState'),
  TmBuildingBlockMessages.haltedAccepted('halting'),
  TmBuildingBlockMessages.haltedRejected(),
  TmBuildingBlockMessages.finiteGraphRejected(),
  TmBuildingBlockMessages.repeatedConfiguration(),
];

List<StructuredMessage> _tmToGrammarMessages() => [
  TmToGrammarMessages.fromDiagnostic(
    code: TMToGrammarDiagnosticCode.invalidMachine,
  ),
  TmToGrammarMessages.fromDiagnostic(
    code: TMToGrammarDiagnosticCode.invalidMachine,
    detailCode: 'bad-machine',
  ),
  TmToGrammarMessages.fromDiagnostic(
    code: TMToGrammarDiagnosticCode.missingInitialState,
  ),
  TmToGrammarMessages.fromDiagnostic(
    code: TMToGrammarDiagnosticCode.noAcceptingState,
  ),
  TmToGrammarMessages.fromDiagnostic(
    code: TMToGrammarDiagnosticCode.multiTapeUnsupported,
    tapeCount: 2,
  ),
  TmToGrammarMessages.fromDiagnostic(
    code: TMToGrammarDiagnosticCode.multiTapeUnsupported,
  ),
  TmToGrammarMessages.fromDiagnostic(
    code: TMToGrammarDiagnosticCode.buildingBlocksUnsupported,
    relatedIds: ['block-a', 'block-b'],
  ),
  TmToGrammarMessages.fromDiagnostic(
    code: TMToGrammarDiagnosticCode.buildingBlocksUnsupported,
  ),
  TmToGrammarMessages.fromDiagnostic(
    code: TMToGrammarDiagnosticCode.blankInInputAlphabet,
    symbol: '_',
  ),
  TmToGrammarMessages.fromDiagnostic(
    code: TMToGrammarDiagnosticCode.inputOutsideTapeAlphabet,
    symbol: 'x',
  ),
  TmToGrammarMessages.fromDiagnostic(
    code: TMToGrammarDiagnosticCode.constructionLimit,
    maxProductions: 100,
  ),
  TmToGrammarMessages.fromDiagnostic(
    code: TMToGrammarDiagnosticCode.constructionLimit,
    detailCode: 'limit-reached',
  ),
  TmToGrammarMessages.fromDiagnostic(
    code: TMToGrammarDiagnosticCode.outputInvalid,
    detailCode: 'malformed',
  ),
  TmToGrammarMessages.fromDiagnostic(
    code: TMToGrammarDiagnosticCode.outputInvalid,
  ),
  TmToGrammarMessages.fromDiagnostic(
    code: TMToGrammarDiagnosticCode.unreachableState,
    stateId: 'q2',
  ),
  TmToGrammarMessages.fromDiagnostic(
    code: TMToGrammarDiagnosticCode.unreachableState,
  ),
];
