import 'dart:math' as math;

import 'package:vector_math/vector_math_64.dart';

import '../../models/grammar.dart';
import '../../models/lr1_models.dart';
import '../../models/pda.dart';
import '../../models/pda_acceptance_mode.dart';
import '../../models/pda_transition.dart';
import '../../models/production.dart';
import '../../models/state.dart';
import '../../utils/epsilon_utils.dart';
import '../grammar_analyzer.dart';
import '../lr1_parser.dart';
import 'cfg_to_pda_models.dart';
import 'cfg_to_pda_messages.dart';

abstract final class CfgToPdaConverter {
  static CfgToPdaConstructionReport buildLl(
    Grammar grammar, {
    required int sourceRevision,
  }) {
    final diagnostics = _validate(grammar);
    if (diagnostics.isNotEmpty) {
      return _failure(
        grammar,
        sourceRevision,
        CfgToPdaOrientation.ll,
        CfgToPdaConstructionOutcome.invalidGrammar,
        diagnostics,
      );
    }
    final tableResult = GrammarAnalyzer.buildLL1ParseTable(grammar);
    if (tableResult.isFailure) {
      return _failure(
        grammar,
        sourceRevision,
        CfgToPdaOrientation.ll,
        CfgToPdaConstructionOutcome.prerequisiteUnavailable,
        [
          CfgToPdaDiagnostic(
            code: CfgToPdaDiagnosticCode.llAnalysisFailed,
            detailCode: 'll-analysis-failed',
            structuredMessage: CfgToPdaMessages.llAnalysisFailed(),
          ),
        ],
      );
    }
    final conflicts = tableResult.data!.value.typedConflicts;
    if (conflicts.isNotEmpty) {
      return _failure(
        grammar,
        sourceRevision,
        CfgToPdaOrientation.ll,
        CfgToPdaConstructionOutcome.llConflict,
        [
          for (final conflict in conflicts)
            CfgToPdaDiagnostic(
              code: CfgToPdaDiagnosticCode.llConflict,
              nonTerminal: conflict.nonTerminal,
              lookahead: conflict.lookahead,
              relatedProductionIds:
                  conflict.entries
                      .map((entry) => entry.productionId)
                      .toSet()
                      .toList()
                    ..sort(),
              detailCode: conflict.kind.name,
              structuredMessage: CfgToPdaMessages.llConflict(
                nonTerminal: conflict.nonTerminal,
                lookahead: conflict.lookahead,
                productionIds:
                    (conflict.entries
                            .map((entry) => entry.productionId)
                            .toSet()
                            .toList()
                          ..sort())
                        .join(', '),
              ),
            ),
        ],
      );
    }

    final symbols = <String>{...grammar.terminals, ...grammar.nonterminals};
    final bottom = _SymbolAllocator(symbols).allocate('__TL_BOTTOM__');
    final builder = _ConstructionBuilder(
      grammar: grammar,
      sourceRevision: sourceRevision,
      orientation: CfgToPdaOrientation.ll,
      bottomMarker: bottom,
      assumptions: const {
        CfgToPdaAssumption.contextFreeSource,
        CfgToPdaAssumption.finalStateAfterInput,
        CfgToPdaAssumption.bottomMarkerInitialized,
        CfgToPdaAssumption.llPredictiveConflictFree,
        CfgToPdaAssumption.llTopDownExpansion,
        CfgToPdaAssumption.sampledEvidenceNotProof,
      },
    );
    final initial = builder.addState(
      id: 'll-q-initial',
      label: 'q_init',
      position: Vector2(100, 180),
      isInitial: true,
    );
    final loop = builder.addState(
      id: 'll-q-expand',
      label: 'q_loop',
      position: Vector2(360, 180),
    );
    final accepting = builder.addState(
      id: 'll-q-accept',
      label: 'q_accept',
      position: Vector2(620, 180),
      isAccepting: true,
    );
    builder.addTransitionStep(
      kind: CfgToPdaStepKind.initializeStack,
      from: initial,
      to: loop,
      popSymbol: bottom,
      pushSymbols: [grammar.startSymbol, bottom],
      sources: [CfgToPdaSourceReference(symbol: grammar.startSymbol)],
    );

    final productions = grammar.productions.toList()..sort(_compareProductions);
    for (final production in productions) {
      final right = _productionRightSymbols(production);
      builder.addTransitionStep(
        kind: CfgToPdaStepKind.expandVariable,
        from: loop,
        to: loop,
        popSymbol: production.leftSide.single,
        pushSymbols: right,
        sources: _productionSources(production),
      );
    }
    final terminals =
        grammar.terminals.where((symbol) => !isEpsilonSymbol(symbol)).toList()
          ..sort();
    for (final terminal in terminals) {
      builder.addTransitionStep(
        kind: CfgToPdaStepKind.matchTerminal,
        from: loop,
        to: loop,
        inputSymbol: terminal,
        popSymbol: terminal,
        sources: [CfgToPdaSourceReference(symbol: terminal)],
      );
    }
    builder.addTransitionStep(
      kind: CfgToPdaStepKind.popBottomMarker,
      from: loop,
      to: accepting,
      popSymbol: bottom,
    );
    return builder.finish();
  }

  static CfgToPdaConstructionReport buildLr(
    Grammar grammar, {
    required int sourceRevision,
    int maxStates = 10000,
    int maxItems = 100000,
    Duration timeout = const Duration(seconds: 5),
  }) {
    final diagnostics = _validate(grammar);
    if (diagnostics.isNotEmpty) {
      return _failure(
        grammar,
        sourceRevision,
        CfgToPdaOrientation.lr,
        CfgToPdaConstructionOutcome.invalidGrammar,
        diagnostics,
      );
    }
    final lrResult = LR1Parser.build(
      grammar,
      maxStates: maxStates,
      maxItems: maxItems,
      timeout: timeout,
    );
    if (!lrResult.isCompleted || lrResult.construction == null) {
      return _failure(
        grammar,
        sourceRevision,
        CfgToPdaOrientation.lr,
        CfgToPdaConstructionOutcome.prerequisiteUnavailable,
        [
          CfgToPdaDiagnostic(
            code: CfgToPdaDiagnosticCode.lrConstructionUnavailable,
            detailCode: lrResult.outcome.name,
            structuredMessage: CfgToPdaMessages.lrConstructionUnavailable(),
          ),
        ],
      );
    }
    final construction = lrResult.construction!;
    if (construction.table.conflicts.isNotEmpty) {
      return _failure(
        grammar,
        sourceRevision,
        CfgToPdaOrientation.lr,
        CfgToPdaConstructionOutcome.lrConflict,
        [
          for (final conflict in construction.table.conflicts)
            CfgToPdaDiagnostic(
              code: CfgToPdaDiagnosticCode.lrConflict,
              lookahead: conflict.lookahead,
              lrState: conflict.state,
              relatedProductionIds:
                  conflict.actions
                      .map((action) => action.productionId)
                      .whereType<String>()
                      .toSet()
                      .toList()
                    ..sort(),
              detailCode: conflict.kind.name,
              structuredMessage: CfgToPdaMessages.lrConflict(
                state: conflict.state,
                lookahead: conflict.lookahead,
                productionIds:
                    (conflict.actions
                            .map((action) => action.productionId)
                            .whereType<String>()
                            .toSet()
                            .toList()
                          ..sort())
                        .join(', '),
              ),
            ),
        ],
      );
    }

    final symbols = <String>{...grammar.terminals, ...grammar.nonterminals};
    final bottom = _SymbolAllocator(symbols).allocate('__TL_BOTTOM__');
    final builder = _ConstructionBuilder(
      grammar: grammar,
      sourceRevision: sourceRevision,
      orientation: CfgToPdaOrientation.lr,
      bottomMarker: bottom,
      assumptions: const {
        CfgToPdaAssumption.contextFreeSource,
        CfgToPdaAssumption.finalStateAfterInput,
        CfgToPdaAssumption.bottomMarkerInitialized,
        CfgToPdaAssumption.lrCanonicalConflictFree,
        CfgToPdaAssumption.lrBottomUpReduction,
        CfgToPdaAssumption.sampledEvidenceNotProof,
      },
    );
    final loop = builder.addState(
      id: 'lr-q-shift-reduce',
      label: 'q_loop',
      position: Vector2(120, 180),
      isInitial: true,
    );
    final checkBottom = builder.addState(
      id: 'lr-q-check-bottom',
      label: 'q_check',
      position: Vector2(560, 180),
    );
    final accepting = builder.addState(
      id: 'lr-q-accept',
      label: 'q_accept',
      position: Vector2(780, 180),
      isAccepting: true,
    );

    final terminals =
        grammar.terminals.where((symbol) => !isEpsilonSymbol(symbol)).toList()
          ..sort();
    for (final terminal in terminals) {
      builder.addTransitionStep(
        kind: CfgToPdaStepKind.shiftTerminal,
        from: loop,
        to: loop,
        inputSymbol: terminal,
        pushSymbols: [terminal],
        sources: _lrShiftSources(construction, terminal),
      );
    }

    final productions = grammar.productions.toList()..sort(_compareProductions);
    for (
      var productionIndex = 0;
      productionIndex < productions.length;
      productionIndex++
    ) {
      final production = productions[productionIndex];
      final right = _productionRightSymbols(production);
      final sources = <CfgToPdaSourceReference>[
        ..._productionSources(production),
        ..._lrReductionSources(construction, production.id),
      ];
      if (right.isEmpty) {
        builder.addTransitionStep(
          kind: CfgToPdaStepKind.reduceProduction,
          from: loop,
          to: loop,
          pushSymbols: [production.leftSide.single],
          sources: sources,
        );
        continue;
      }

      final transitionIds = <String>[];
      var from = loop;
      for (var reverseIndex = 0; reverseIndex < right.length; reverseIndex++) {
        final symbolIndex = right.length - reverseIndex - 1;
        final isLast = reverseIndex == right.length - 1;
        final to = isLast
            ? loop
            : builder.addState(
                id: 'lr-q-reduce-$productionIndex-${reverseIndex + 1}',
                label: 'r_${productionIndex}_${reverseIndex + 1}',
                position: Vector2(
                  300 + (productionIndex % 4) * 110,
                  340 + (productionIndex ~/ 4) * 90,
                ),
              );
        transitionIds.add(
          builder.addTransition(
            from: from,
            to: to,
            popSymbol: right[symbolIndex],
            pushSymbols: isLast
                ? [production.leftSide.single]
                : const <String>[],
          ),
        );
        from = to;
      }
      builder.recordTransitionStep(
        kind: CfgToPdaStepKind.reduceProduction,
        transitionIds: transitionIds,
        sources: sources,
      );
    }

    builder.addTransitionStep(
      kind: CfgToPdaStepKind.acceptStart,
      from: loop,
      to: checkBottom,
      popSymbol: grammar.startSymbol,
      sources: [CfgToPdaSourceReference(symbol: grammar.startSymbol)],
    );
    builder.addTransitionStep(
      kind: CfgToPdaStepKind.popBottomMarker,
      from: checkBottom,
      to: accepting,
      popSymbol: bottom,
    );
    return builder.finish();
  }

  static List<CfgToPdaDiagnostic> _validate(Grammar grammar) {
    final diagnostics = <CfgToPdaDiagnostic>[];
    if (grammar.productions.isEmpty) {
      diagnostics.add(
        CfgToPdaDiagnostic(
          code: CfgToPdaDiagnosticCode.emptyGrammar,
          structuredMessage: CfgToPdaMessages.emptyGrammar(),
        ),
      );
    }
    if (grammar.startSymbol.isEmpty) {
      diagnostics.add(
        CfgToPdaDiagnostic(
          code: CfgToPdaDiagnosticCode.missingStartSymbol,
          structuredMessage: CfgToPdaMessages.missingStartSymbol(),
        ),
      );
    } else if (!grammar.nonterminals.contains(grammar.startSymbol)) {
      diagnostics.add(
        CfgToPdaDiagnostic(
          code: CfgToPdaDiagnosticCode.undeclaredStartSymbol,
          symbol: grammar.startSymbol,
          structuredMessage: CfgToPdaMessages.undeclaredStartSymbol(
            grammar.startSymbol,
          ),
        ),
      );
    }
    final declared = <String>{...grammar.terminals, ...grammar.nonterminals};
    final productions = grammar.productions.toList()..sort(_compareProductions);
    final productionIds = <String>{};
    for (final production in productions) {
      if (!productionIds.add(production.id)) {
        diagnostics.add(
          CfgToPdaDiagnostic(
            code: CfgToPdaDiagnosticCode.duplicateProductionId,
            productionId: production.id,
            structuredMessage: CfgToPdaMessages.duplicateProductionId(
              production.id,
            ),
          ),
        );
      }
      if (!production.isValid ||
          production.leftSide.length != 1 ||
          !grammar.nonterminals.contains(production.leftSide.single) ||
          (production.rightSide.any(isEpsilonSymbol) &&
              production.rightSide.length != 1)) {
        diagnostics.add(
          CfgToPdaDiagnostic(
            code: CfgToPdaDiagnosticCode.malformedProduction,
            productionId: production.id,
            structuredMessage: CfgToPdaMessages.malformedProduction(
              production.id,
            ),
          ),
        );
      }
      for (final symbol in production.rightSide) {
        if (isEpsilonSymbol(symbol)) continue;
        if (!declared.contains(symbol)) {
          diagnostics.add(
            CfgToPdaDiagnostic(
              code: CfgToPdaDiagnosticCode.undeclaredSymbol,
              productionId: production.id,
              symbol: symbol,
              structuredMessage: CfgToPdaMessages.undeclaredSymbol(
                productionId: production.id,
                symbol: symbol,
              ),
            ),
          );
        }
      }
    }
    return diagnostics;
  }

  static CfgToPdaConstructionReport _failure(
    Grammar grammar,
    int sourceRevision,
    CfgToPdaOrientation orientation,
    CfgToPdaConstructionOutcome outcome,
    List<CfgToPdaDiagnostic> diagnostics,
  ) => CfgToPdaConstructionReport(
    sourceGrammarId: grammar.id,
    sourceRevision: sourceRevision,
    orientation: orientation,
    outcome: outcome,
    acceptanceMode: PDAAcceptanceMode.finalState,
    assumptions: const {
      CfgToPdaAssumption.contextFreeSource,
      CfgToPdaAssumption.finalStateAfterInput,
      CfgToPdaAssumption.sampledEvidenceNotProof,
    },
    diagnostics: diagnostics,
  );

  static List<CfgToPdaSourceReference> _productionSources(
    Production production,
  ) => [
    CfgToPdaSourceReference(
      productionId: production.id,
      symbol: production.leftSide.single,
      symbolPosition: 0,
      side: CfgToPdaSourceSide.left,
    ),
    for (var index = 0; index < production.rightSide.length; index++)
      CfgToPdaSourceReference(
        productionId: production.id,
        symbol: production.rightSide[index],
        symbolPosition: index,
        side: CfgToPdaSourceSide.right,
      ),
  ];

  static List<String> _productionRightSymbols(Production production) =>
      production.isLambda
      ? const <String>[]
      : production.rightSide
            .where((symbol) => !isEpsilonSymbol(symbol))
            .toList();

  static List<CfgToPdaSourceReference> _lrShiftSources(
    LR1Construction construction,
    String terminal,
  ) {
    final sources = <CfgToPdaSourceReference>[];
    final states = construction.table.actions.keys.toList()..sort();
    for (final state in states) {
      final row = construction.table.actions[state]!;
      final lookaheads = row.keys.toList()..sort();
      for (final lookahead in lookaheads) {
        for (final action in row[lookahead]!) {
          if (action.kind != LR1ActionKind.shift || lookahead != terminal) {
            continue;
          }
          sources.add(
            CfgToPdaSourceReference(
              symbol: terminal,
              lrState: state,
              lookahead: lookahead,
              lrItemKeys: action.sourceItems.map((item) => item.stableKey),
            ),
          );
        }
      }
    }
    return sources;
  }

  static List<CfgToPdaSourceReference> _lrReductionSources(
    LR1Construction construction,
    String productionId,
  ) {
    final sources = <CfgToPdaSourceReference>[];
    final states = construction.table.actions.keys.toList()..sort();
    for (final state in states) {
      final row = construction.table.actions[state]!;
      final lookaheads = row.keys.toList()..sort();
      for (final lookahead in lookaheads) {
        for (final action in row[lookahead]!) {
          if (action.kind != LR1ActionKind.reduce ||
              action.productionId != productionId) {
            continue;
          }
          sources.add(
            CfgToPdaSourceReference(
              productionId: productionId,
              lrState: state,
              lookahead: lookahead,
              lrItemKeys: action.sourceItems.map((item) => item.stableKey),
            ),
          );
        }
      }
    }
    return sources;
  }

  static int _compareProductions(Production left, Production right) {
    final order = left.order.compareTo(right.order);
    return order != 0 ? order : left.id.compareTo(right.id);
  }
}

final class _ConstructionBuilder {
  _ConstructionBuilder({
    required this.grammar,
    required this.sourceRevision,
    required this.orientation,
    required this.bottomMarker,
    required this.assumptions,
  });

  final Grammar grammar;
  final int sourceRevision;
  final CfgToPdaOrientation orientation;
  final String bottomMarker;
  final Set<CfgToPdaAssumption> assumptions;
  final Map<String, State> _states = {};
  final List<PDATransition> _transitions = [];
  final List<CfgToPdaStep> _steps = [];
  final List<CfgToPdaTransitionProvenance> _provenance = [];
  var _nextTransition = 0;

  State addState({
    required String id,
    required String label,
    required Vector2 position,
    bool isInitial = false,
    bool isAccepting = false,
  }) {
    if (_states.containsKey(id)) throw StateError('Duplicate state ID: $id');
    final state = State(
      id: id,
      label: label,
      position: position,
      isInitial: isInitial,
      isAccepting: isAccepting,
    );
    _states[id] = state;
    _steps.add(
      CfgToPdaStep(
        index: _steps.length,
        kind: CfgToPdaStepKind.createState,
        stateIds: [id],
      ),
    );
    return state;
  }

  String addTransition({
    required State from,
    required State to,
    String inputSymbol = '',
    String popSymbol = '',
    List<String> pushSymbols = const [],
  }) {
    final id =
        '${orientation.name}-t-${_nextTransition.toString().padLeft(4, '0')}';
    _nextTransition++;
    final isLambdaInput = inputSymbol.isEmpty;
    final isLambdaPop = popSymbol.isEmpty;
    final isLambdaPush = pushSymbols.isEmpty;
    _transitions.add(
      PDATransition(
        id: id,
        fromState: from,
        toState: to,
        controlPoint: from == to
            ? from.position + Vector2(0, -90)
            : Vector2.zero(),
        label: PDATransition.formatLabel(
          inputSymbol: inputSymbol,
          popSymbol: popSymbol,
          pushSymbol: pushSymbols.join(),
          isLambdaInput: isLambdaInput,
          isLambdaPop: isLambdaPop,
          isLambdaPush: isLambdaPush,
        ),
        inputSymbol: inputSymbol,
        popSymbol: popSymbol,
        pushSymbol: pushSymbols.join(),
        pushSymbols: pushSymbols,
        isLambdaInput: isLambdaInput,
        isLambdaPop: isLambdaPop,
        isLambdaPush: isLambdaPush,
      ),
    );
    return id;
  }

  void addTransitionStep({
    required CfgToPdaStepKind kind,
    required State from,
    required State to,
    String inputSymbol = '',
    String popSymbol = '',
    List<String> pushSymbols = const [],
    List<CfgToPdaSourceReference> sources = const [],
  }) {
    final id = addTransition(
      from: from,
      to: to,
      inputSymbol: inputSymbol,
      popSymbol: popSymbol,
      pushSymbols: pushSymbols,
    );
    recordTransitionStep(kind: kind, transitionIds: [id], sources: sources);
  }

  void recordTransitionStep({
    required CfgToPdaStepKind kind,
    required List<String> transitionIds,
    List<CfgToPdaSourceReference> sources = const [],
  }) {
    final index = _steps.length;
    _steps.add(
      CfgToPdaStep(
        index: index,
        kind: kind,
        transitionIds: transitionIds,
        sources: sources,
      ),
    );
    for (final transitionId in transitionIds) {
      _provenance.add(
        CfgToPdaTransitionProvenance(
          transitionId: transitionId,
          stepIndex: index,
          kind: kind,
          sources: sources,
        ),
      );
    }
  }

  CfgToPdaConstructionReport finish() {
    final stateValues = _states.values.toSet();
    final initial = stateValues.singleWhere((state) => state.isInitial);
    final accepting = stateValues.where((state) => state.isAccepting).toSet();
    final pda = PDA(
      id: 'cfg-pda-${orientation.name}:${grammar.id}',
      name: 'CFG→PDA ${orientation.name.toUpperCase()}',
      states: stateValues,
      transitions: _transitions.toSet(),
      alphabet: grammar.terminals
          .where((symbol) => !isEpsilonSymbol(symbol))
          .toSet(),
      initialState: initial,
      acceptingStates: accepting,
      created: grammar.created,
      modified: grammar.modified,
      bounds: const math.Rectangle(0, 0, 960, 640),
      stackAlphabet: {
        ...grammar.terminals.where((symbol) => !isEpsilonSymbol(symbol)),
        ...grammar.nonterminals,
        bottomMarker,
      },
      initialStackSymbol: bottomMarker,
    );
    final errors = pda.validate();
    if (errors.isNotEmpty) {
      return CfgToPdaConstructionReport(
        sourceGrammarId: grammar.id,
        sourceRevision: sourceRevision,
        orientation: orientation,
        outcome: CfgToPdaConstructionOutcome.outputInvalid,
        acceptanceMode: PDAAcceptanceMode.finalState,
        assumptions: assumptions,
        diagnostics: [
          for (var index = 0; index < errors.length; index++)
            CfgToPdaDiagnostic(
              code: CfgToPdaDiagnosticCode.outputInvalid,
              detailCode: 'pda-validation-$index',
              structuredMessage: CfgToPdaMessages.outputInvalid(),
            ),
        ],
        steps: _steps,
        transitionProvenance: _provenance,
      );
    }
    return CfgToPdaConstructionReport(
      sourceGrammarId: grammar.id,
      sourceRevision: sourceRevision,
      orientation: orientation,
      outcome: CfgToPdaConstructionOutcome.completed,
      acceptanceMode: PDAAcceptanceMode.finalState,
      assumptions: assumptions,
      steps: _steps,
      transitionProvenance: _provenance,
      pda: pda,
    );
  }
}

final class _SymbolAllocator {
  _SymbolAllocator(Iterable<String> reserved) : _used = {...reserved};

  final Set<String> _used;

  String allocate(String base) {
    if (_used.add(base)) return base;
    var suffix = 1;
    while (!_used.add('${base}_$suffix')) {
      suffix++;
    }
    return '${base}_$suffix';
  }
}
