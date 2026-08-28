import '../../grammar/phrase_structure/phrase_structure.dart';
import '../../models/tm.dart';
import '../../models/tm_transition.dart';
import '../tm_to_grammar_messages.dart';
import 'tm_to_grammar_models.dart';

abstract final class TMToGrammarConverter {
  static const _assumptions = {
    TMToGrammarAssumption.singleTape,
    TMToGrammarAssumption.twoWayInfiniteTape,
    TMToGrammarAssumption.finalStateAcceptance,
    TMToGrammarAssumption.deterministicOrNondeterministic,
    TMToGrammarAssumption.atomicTokenSymbols,
    TMToGrammarAssumption.finiteWindowChosenByDerivation,
    TMToGrammarAssumption.sampledEvidenceNotProof,
  };

  static TMToGrammarConstructionReport build(
    TM tm, {
    required int sourceRevision,
    int maxProductions = 50000,
  }) {
    final diagnostics = _validate(tm);
    final errors = diagnostics.where(
      (diagnostic) =>
          diagnostic.severity == TMToGrammarDiagnosticSeverity.error,
    );
    if (errors.isNotEmpty) {
      final unsupported = errors.any(
        (diagnostic) =>
            diagnostic.code == TMToGrammarDiagnosticCode.multiTapeUnsupported ||
            diagnostic.code ==
                TMToGrammarDiagnosticCode.buildingBlocksUnsupported,
      );
      return _failure(
        tm,
        sourceRevision,
        unsupported
            ? TMToGrammarOutcome.unsupportedMachine
            : TMToGrammarOutcome.invalidMachine,
        diagnostics,
      );
    }

    final terminals = tm.alphabet.toList()..sort();
    final tapeSymbols = tm.tapeAlphabet.toList()..sort();
    final transitions = tm.tmTransitions.toList()
      ..sort((a, b) => a.id.compareTo(b.id));
    final accepting = tm.acceptingStates.toList()
      ..sort((a, b) => a.id.compareTo(b.id));
    final allocator = _SymbolAllocator(terminals);
    final builder = _GrammarBuilder(
      tm: tm,
      sourceRevision: sourceRevision,
      allocator: allocator,
      terminals: terminals,
      maxProductions: maxProductions,
    );

    try {
      final start = allocator.allocate('start');
      final left = allocator.allocate('left-padding-and-input-start');
      final inputTail = allocator.allocate('input-tail');
      final right = allocator.allocate('right-padding');
      final leftBoundary = allocator.allocate('left-boundary');
      final rightBoundary = allocator.allocate('right-boundary');
      final sweepLeft = allocator.allocate('accepting-sweep-left');
      final sweepRight = allocator.allocate('accepting-sweep-right');
      final outputMarkers = <String?, NonterminalGrammarSymbol>{
        null: allocator.allocate('output-padding'),
        for (final terminal in terminals)
          terminal: allocator.allocate('output($terminal)'),
      };
      final cells = <(String?, String), NonterminalGrammarSymbol>{};
      final heads = <(String?, String, String), NonterminalGrammarSymbol>{};

      NonterminalGrammarSymbol cell(String? output, String tape) =>
          cells.putIfAbsent(
            (output, tape),
            () => allocator.allocate(
              'cell(output=${output ?? 'padding'},tape=$tape)',
            ),
          );
      NonterminalGrammarSymbol head(
        String? output,
        String state,
        String tape,
      ) => heads.putIfAbsent(
        (output, state, tape),
        () => allocator.allocate(
          'head(output=${output ?? 'padding'},state=$state,tape=$tape)',
        ),
      );

      final initialState = tm.initialState!;
      builder.add(
        family: TMToGrammarProductionFamily.initialization,
        invariantCode: 'initial-boundaries',
        left: [start],
        right: [leftBoundary, left],
        sources: [TMToGrammarSourceReference(stateId: initialState.id)],
      );
      builder.add(
        family: TMToGrammarProductionFamily.initialization,
        invariantCode: 'initial-empty-input',
        left: [left],
        right: [head(null, initialState.id, tm.blankSymbol), right],
        sources: [TMToGrammarSourceReference(stateId: initialState.id)],
      );
      for (final terminal in terminals) {
        builder.add(
          family: TMToGrammarProductionFamily.inputCell,
          invariantCode: 'initial-first-input-cell',
          left: [left],
          right: [head(terminal, initialState.id, terminal), inputTail],
          sources: [
            TMToGrammarSourceReference(
              stateId: initialState.id,
              readSymbol: terminal,
            ),
          ],
        );
      }
      builder.add(
        family: TMToGrammarProductionFamily.boundaryBlank,
        invariantCode: 'choose-left-blank-padding',
        left: [left],
        right: [cell(null, tm.blankSymbol), left],
      );
      builder.add(
        family: TMToGrammarProductionFamily.initialization,
        invariantCode: 'finish-input',
        left: [inputTail],
        right: [right],
      );
      for (final terminal in terminals) {
        builder.add(
          family: TMToGrammarProductionFamily.inputCell,
          invariantCode: 'append-input-cell',
          left: [inputTail],
          right: [cell(terminal, terminal), inputTail],
          sources: [TMToGrammarSourceReference(readSymbol: terminal)],
        );
      }
      builder.add(
        family: TMToGrammarProductionFamily.initialization,
        invariantCode: 'close-right-boundary',
        left: [right],
        right: [rightBoundary],
      );
      builder.add(
        family: TMToGrammarProductionFamily.boundaryBlank,
        invariantCode: 'choose-right-blank-padding',
        left: [right],
        right: [cell(null, tm.blankSymbol), right],
      );

      final outputs = outputMarkers.keys.toList()
        ..sort((a, b) => (a ?? '').compareTo(b ?? ''));
      for (final transition in transitions) {
        final operation = transition.operationsForTapeCount(1, tm.blankSymbol);
        final read = operation.readSymbols.single;
        final write = operation.writeSymbols.single;
        final direction = operation.directions.single;
        final source = TMToGrammarSourceReference(
          stateId: transition.fromState.id,
          transitionId: transition.id,
          tapeIndex: 0,
          readSymbol: read,
          writeSymbol: write,
          direction: direction,
        );
        switch (direction) {
          case TapeDirection.stay:
            for (final output in outputs) {
              builder.add(
                family: TMToGrammarProductionFamily.stay,
                invariantCode: 'simulate-stay-write-state',
                left: [head(output, transition.fromState.id, read)],
                right: [head(output, transition.toState.id, write)],
                sources: [source],
              );
            }
          case TapeDirection.right:
            for (final output in outputs) {
              for (final neighborOutput in outputs) {
                for (final neighborTape in tapeSymbols) {
                  builder.add(
                    family: TMToGrammarProductionFamily.moveRight,
                    invariantCode: 'simulate-right-write-and-move',
                    left: [
                      head(output, transition.fromState.id, read),
                      cell(neighborOutput, neighborTape),
                    ],
                    right: [
                      cell(output, write),
                      head(neighborOutput, transition.toState.id, neighborTape),
                    ],
                    sources: [source],
                  );
                }
              }
            }
          case TapeDirection.left:
            for (final output in outputs) {
              for (final neighborOutput in outputs) {
                for (final neighborTape in tapeSymbols) {
                  builder.add(
                    family: TMToGrammarProductionFamily.moveLeft,
                    invariantCode: 'simulate-left-write-and-move',
                    left: [
                      cell(neighborOutput, neighborTape),
                      head(output, transition.fromState.id, read),
                    ],
                    right: [
                      head(neighborOutput, transition.toState.id, neighborTape),
                      cell(output, write),
                    ],
                    sources: [source],
                  );
                }
              }
            }
        }
      }

      for (final state in accepting) {
        for (final output in outputs) {
          for (final tape in tapeSymbols) {
            builder.add(
              family: TMToGrammarProductionFamily.acceptingState,
              invariantCode: 'enable-cleanup-only-in-final-state',
              left: [head(output, state.id, tape)],
              right: [sweepLeft, outputMarkers[output]!],
              sources: [TMToGrammarSourceReference(stateId: state.id)],
            );
          }
        }
      }
      for (final output in outputs) {
        for (final tape in tapeSymbols) {
          builder.add(
            family: TMToGrammarProductionFamily.cleanupLeft,
            invariantCode: 'sweep-left-preserving-output-track',
            left: [cell(output, tape), sweepLeft],
            right: [sweepLeft, outputMarkers[output]!],
          );
        }
      }
      builder.add(
        family: TMToGrammarProductionFamily.cleanupLeft,
        invariantCode: 'turn-at-left-boundary',
        left: [leftBoundary, sweepLeft],
        right: [sweepRight],
      );
      for (final output in outputs) {
        final emitted = output == null
            ? const <PhraseGrammarSymbol>[]
            : <PhraseGrammarSymbol>[TerminalGrammarSymbol(output)];
        builder.add(
          family: TMToGrammarProductionFamily.cleanupRight,
          invariantCode: output == null
              ? 'erase-output-padding'
              : 'emit-preserved-input-terminal',
          left: [sweepRight, outputMarkers[output]!],
          right: [...emitted, sweepRight],
        );
        for (final tape in tapeSymbols) {
          builder.add(
            family: TMToGrammarProductionFamily.cleanupRight,
            invariantCode: output == null
                ? 'erase-right-padding-cell'
                : 'emit-right-input-cell',
            left: [sweepRight, cell(output, tape)],
            right: [...emitted, sweepRight],
          );
        }
      }
      builder.add(
        family: TMToGrammarProductionFamily.cleanupRight,
        invariantCode: 'finish-at-right-boundary',
        left: [sweepRight, rightBoundary],
        right: const [],
      );

      return builder.finish(startSymbol: start, diagnostics: diagnostics);
    } on _ConstructionLimitExceeded {
      return _failure(
        tm,
        sourceRevision,
        TMToGrammarOutcome.constructionLimit,
        [
          ...diagnostics,
          _diagnostic(
            code: TMToGrammarDiagnosticCode.constructionLimit,
            severity: TMToGrammarDiagnosticSeverity.error,
            detailCode: 'max-productions-$maxProductions',
            maxProductions: maxProductions,
          ),
        ],
      );
    }
  }

  static List<TMToGrammarDiagnostic> _validate(TM tm) {
    final diagnostics = <TMToGrammarDiagnostic>[];
    final errors = tm.validate();
    for (var index = 0; index < errors.length; index++) {
      diagnostics.add(
        _diagnostic(
          code: TMToGrammarDiagnosticCode.invalidMachine,
          severity: TMToGrammarDiagnosticSeverity.error,
          detailCode: 'tm-validation-$index',
        ),
      );
    }
    if (tm.initialState == null || !tm.states.contains(tm.initialState)) {
      diagnostics.add(
        _diagnostic(
          code: TMToGrammarDiagnosticCode.missingInitialState,
          severity: TMToGrammarDiagnosticSeverity.error,
        ),
      );
    }
    if (tm.tapeCount != 1) {
      diagnostics.add(
        _diagnostic(
          code: TMToGrammarDiagnosticCode.multiTapeUnsupported,
          severity: TMToGrammarDiagnosticSeverity.error,
          detailCode: 'tape-count-${tm.tapeCount}',
          tapeCount: tm.tapeCount,
        ),
      );
    }
    if (tm.blockDefinitions.isNotEmpty || tm.blockInvocations.isNotEmpty) {
      diagnostics.add(
        _diagnostic(
          code: TMToGrammarDiagnosticCode.buildingBlocksUnsupported,
          severity: TMToGrammarDiagnosticSeverity.error,
          relatedIds: [
            ...tm.blockDefinitions.keys,
            ...tm.blockInvocations.map((invocation) => invocation.id),
          ]..sort(),
        ),
      );
    }
    if (tm.alphabet.contains(tm.blankSymbol)) {
      diagnostics.add(
        _diagnostic(
          code: TMToGrammarDiagnosticCode.blankInInputAlphabet,
          severity: TMToGrammarDiagnosticSeverity.error,
          symbol: tm.blankSymbol,
        ),
      );
    }
    final inputSymbols = tm.alphabet.toList()..sort();
    for (final symbol in inputSymbols) {
      if (!tm.tapeAlphabet.contains(symbol)) {
        diagnostics.add(
          _diagnostic(
            code: TMToGrammarDiagnosticCode.inputOutsideTapeAlphabet,
            severity: TMToGrammarDiagnosticSeverity.error,
            symbol: symbol,
          ),
        );
      }
    }
    if (tm.acceptingStates.isEmpty) {
      diagnostics.add(
        _diagnostic(
          code: TMToGrammarDiagnosticCode.noAcceptingState,
          severity: TMToGrammarDiagnosticSeverity.warning,
        ),
      );
    }
    final unreachable = tm.unreachableStates.toList()
      ..sort((a, b) => a.id.compareTo(b.id));
    for (final state in unreachable) {
      diagnostics.add(
        _diagnostic(
          code: TMToGrammarDiagnosticCode.unreachableState,
          severity: TMToGrammarDiagnosticSeverity.warning,
          stateId: state.id,
        ),
      );
    }
    return diagnostics;
  }

  static TMToGrammarDiagnostic _diagnostic({
    required TMToGrammarDiagnosticCode code,
    required TMToGrammarDiagnosticSeverity severity,
    String? stateId,
    String? transitionId,
    String? symbol,
    String? detailCode,
    Iterable<String> relatedIds = const [],
    int? tapeCount,
    int? maxProductions,
  }) {
    return TMToGrammarDiagnostic(
      code: code,
      severity: severity,
      stateId: stateId,
      transitionId: transitionId,
      symbol: symbol,
      detailCode: detailCode,
      relatedIds: relatedIds,
      structuredMessage: TmToGrammarMessages.fromDiagnostic(
        code: code,
        stateId: stateId,
        symbol: symbol,
        detailCode: detailCode,
        tapeCount: tapeCount,
        relatedIds: relatedIds,
        maxProductions: maxProductions,
      ),
    );
  }

  static TMToGrammarConstructionReport _failure(
    TM tm,
    int sourceRevision,
    TMToGrammarOutcome outcome,
    List<TMToGrammarDiagnostic> diagnostics,
  ) => TMToGrammarConstructionReport(
    sourceTmId: tm.id,
    sourceRevision: sourceRevision,
    outcome: outcome,
    assumptions: _assumptions,
    diagnostics: diagnostics,
  );
}

final class _GrammarBuilder {
  _GrammarBuilder({
    required this.tm,
    required this.sourceRevision,
    required this.allocator,
    required this.terminals,
    required this.maxProductions,
  });

  final TM tm;
  final int sourceRevision;
  final _SymbolAllocator allocator;
  final List<String> terminals;
  final int maxProductions;
  final List<PhraseStructureProduction> _productions = [];
  final List<TMToGrammarProductionProvenance> _provenance = [];
  final Map<String, int> _shapeToIndex = {};

  void add({
    required TMToGrammarProductionFamily family,
    required String invariantCode,
    required List<PhraseGrammarSymbol> left,
    required List<PhraseGrammarSymbol> right,
    List<TMToGrammarSourceReference> sources = const [],
  }) {
    final leftSequence = GrammarSymbolSequence(left);
    final rightSequence = GrammarSymbolSequence(right);
    final shape = '${leftSequence.stableKey}->${rightSequence.stableKey}';
    final existing = _shapeToIndex[shape];
    if (existing != null) {
      final previous = _provenance[existing];
      final merged = <TMToGrammarSourceReference>[...previous.sources];
      for (final source in sources) {
        if (!merged.any(
          (item) => item.toJson().toString() == source.toJson().toString(),
        )) {
          merged.add(source);
        }
      }
      _provenance[existing] = TMToGrammarProductionProvenance(
        productionId: previous.productionId,
        family: previous.family,
        invariantCode: previous.invariantCode,
        sources: merged,
      );
      return;
    }
    if (_productions.length >= maxProductions) {
      throw const _ConstructionLimitExceeded();
    }
    final index = _productions.length;
    final id = 'tmug-p-${index.toString().padLeft(6, '0')}';
    _shapeToIndex[shape] = index;
    _productions.add(
      PhraseStructureProduction(
        id: id,
        left: leftSequence,
        right: rightSequence,
        order: index,
      ),
    );
    _provenance.add(
      TMToGrammarProductionProvenance(
        productionId: id,
        family: family,
        invariantCode: invariantCode,
        sources: sources,
      ),
    );
  }

  TMToGrammarConstructionReport finish({
    required NonterminalGrammarSymbol startSymbol,
    required List<TMToGrammarDiagnostic> diagnostics,
  }) {
    final grammar = UnrestrictedGrammar(
      id: 'tm-to-grammar:${tm.id}',
      name: '${tm.name} — unrestricted grammar',
      revision: sourceRevision,
      terminals: terminals.map(TerminalGrammarSymbol.new),
      nonterminals: allocator.symbols,
      startSymbol: startSymbol,
      productions: _productions,
    );
    final classification = PhraseGrammarClassifier.classify(grammar);
    if (!classification.isValid) {
      final errors = classification.errors.toList();
      return TMToGrammarConstructionReport(
        sourceTmId: tm.id,
        sourceRevision: sourceRevision,
        outcome: TMToGrammarOutcome.outputInvalid,
        assumptions: TMToGrammarConverter._assumptions,
        diagnostics: [
          ...diagnostics,
          for (var index = 0; index < errors.length; index++)
            TMToGrammarConverter._diagnostic(
              code: TMToGrammarDiagnosticCode.outputInvalid,
              severity: TMToGrammarDiagnosticSeverity.error,
              detailCode: 'grammar-validation-$index',
            ),
        ],
        productionProvenance: _provenance,
        symbolDescriptions: allocator.descriptions,
      );
    }
    return TMToGrammarConstructionReport(
      sourceTmId: tm.id,
      sourceRevision: sourceRevision,
      outcome: TMToGrammarOutcome.completed,
      assumptions: TMToGrammarConverter._assumptions,
      diagnostics: diagnostics,
      productionProvenance: _provenance,
      symbolDescriptions: allocator.descriptions,
      grammar: grammar,
    );
  }
}

final class _SymbolAllocator {
  _SymbolAllocator(Iterable<String> terminalNames)
    : _used = Set<String>.from(terminalNames);

  final Set<String> _used;
  final List<NonterminalGrammarSymbol> _symbols = [];
  final Map<String, String> _descriptions = {};
  int _next = 0;

  NonterminalGrammarSymbol allocate(String description) {
    String candidate;
    do {
      candidate = 'TMV${_next.toString().padLeft(6, '0')}';
      _next++;
    } while (!_used.add(candidate));
    final symbol = NonterminalGrammarSymbol(candidate);
    _symbols.add(symbol);
    _descriptions[candidate] = description;
    return symbol;
  }

  List<NonterminalGrammarSymbol> get symbols =>
      List<NonterminalGrammarSymbol>.unmodifiable(_symbols);
  Map<String, String> get descriptions =>
      Map<String, String>.unmodifiable(_descriptions);
}

final class _ConstructionLimitExceeded implements Exception {
  const _ConstructionLimitExceeded();
}
