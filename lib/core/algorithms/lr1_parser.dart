import '../models/derivation_tree_node.dart';
import '../models/grammar.dart';
import '../models/lr1_models.dart';
import '../models/production.dart';
import '../messages/structured_message.dart';
import '../utils/epsilon_utils.dart';
import 'grammar_analyzer.dart';
import 'grammar_input_tokenizer.dart';
import 'lr1_parser_messages.dart';

class LR1Parser {
  const LR1Parser._();

  static const String endMarker = r'$';

  static LR1ConstructionResult build(
    Grammar grammar, {
    int maxStates = 10000,
    int maxItems = 100000,
    Duration timeout = const Duration(seconds: 5),
    bool Function()? isCancelled,
  }) {
    final stopwatch = Stopwatch()..start();
    final validationError = _validateGrammar(grammar);
    if (validationError != null) {
      return LR1ConstructionResult(
        outcome: LR1ConstructionOutcome.invalidGrammar,
        message: validationError.message,
        structuredMessage: validationError.structuredMessage,
      );
    }

    final firstResult = GrammarAnalyzer.computeFirstSets(grammar);
    if (firstResult.isFailure) {
      return LR1ConstructionResult(
        outcome: LR1ConstructionOutcome.invalidGrammar,
        message: firstResult.error,
        structuredMessage: firstResult.structuredError,
      );
    }
    final firstSets = firstResult.data!.value;
    final augmentedSymbol = _augmentedStartSymbol(grammar);
    final augmentedId = _augmentedProductionId(grammar);
    final augmentedProduction = Production(
      id: augmentedId,
      leftSide: [augmentedSymbol],
      rightSide: [grammar.startSymbol],
      order: -1,
    );
    final productions = <Production>[
      augmentedProduction,
      ...grammar.productions,
    ]..sort(_compareProductions);
    final normalizedRights = <String, List<String>>{
      for (final production in productions)
        _productionKey(production): _normalizedRight(grammar, production),
    };
    final productionsByLeft = <String, List<Production>>{};
    for (final production in productions) {
      productionsByLeft
          .putIfAbsent(production.leftSide.single, () => <Production>[])
          .add(production);
    }

    LR1ConstructionOutcome? closureAbortOutcome;
    String? closureAbortMessage;
    StructuredMessage? closureAbortStructuredMessage;

    bool closureShouldAbort(int itemCount) {
      if (isCancelled?.call() ?? false) {
        closureAbortOutcome = LR1ConstructionOutcome.cancelled;
        closureAbortMessage = 'Canonical LR(1) construction was cancelled.';
        closureAbortStructuredMessage =
            Lr1ParserMessages.constructionCancelled();
        return true;
      }
      if (stopwatch.elapsed >= timeout) {
        closureAbortOutcome = LR1ConstructionOutcome.timeLimit;
        closureAbortMessage =
            'Canonical LR(1) construction timed out after ${timeout.inMilliseconds}ms.';
        closureAbortStructuredMessage = Lr1ParserMessages.constructionTimedOut(
          timeout,
        );
        return true;
      }
      if (itemCount > maxItems) {
        closureAbortOutcome = LR1ConstructionOutcome.itemLimit;
        closureAbortMessage =
            'Canonical LR(1) construction exceeded the item limit.';
        closureAbortStructuredMessage =
            Lr1ParserMessages.constructionItemLimit();
        return true;
      }
      return false;
    }

    List<LR1Item> closure(Iterable<LR1Item> kernel) {
      final items = <String, LR1Item>{
        for (final item in kernel) item.stableKey: item,
      };
      var changed = true;
      while (changed) {
        if (closureShouldAbort(items.length)) break;
        changed = false;
        final snapshot = items.values.toList()..sort(_compareItems);
        for (final item in snapshot) {
          final symbol = item.symbolAfterDot;
          if (symbol == null || !grammar.nonterminals.contains(symbol)) {
            continue;
          }
          final suffix = <String>[
            ...item.rightSide.skip(item.dotPosition + 1),
            item.lookahead,
          ];
          final lookaheads = _firstOfSequence(
            suffix,
            grammar,
            firstSets,
          ).toList()..sort();
          for (final production in productionsByLeft[symbol] ?? const []) {
            final right = normalizedRights[_productionKey(production)]!;
            for (final lookahead in lookaheads) {
              final candidate = LR1Item(
                productionId: production.id,
                leftSide: production.leftSide.single,
                rightSide: right,
                dotPosition: 0,
                lookahead: lookahead,
                productionOrder: production.order,
                isAugmented: production.id == augmentedId,
              );
              if (!items.containsKey(candidate.stableKey)) {
                items[candidate.stableKey] = candidate;
                changed = true;
                if (closureShouldAbort(items.length)) break;
              }
            }
            if (closureAbortOutcome != null) break;
          }
          if (closureAbortOutcome != null) break;
        }
      }
      return items.values.toList()..sort(_compareItems);
    }

    final initialItem = LR1Item(
      productionId: augmentedId,
      leftSide: augmentedSymbol,
      rightSide: [grammar.startSymbol],
      dotPosition: 0,
      lookahead: endMarker,
      productionOrder: -1,
      isAugmented: true,
    );
    final initialItems = closure([initialItem]);
    if (closureAbortOutcome != null) {
      return LR1ConstructionResult(
        outcome: closureAbortOutcome!,
        message: closureAbortMessage,
        structuredMessage: closureAbortStructuredMessage,
      );
    }
    if (initialItems.length > maxItems) {
      return LR1ConstructionResult(
        outcome: LR1ConstructionOutcome.itemLimit,
        message: 'Canonical LR(1) construction exceeded the item limit.',
        structuredMessage: Lr1ParserMessages.constructionItemLimit(),
      );
    }

    final states = <LR1State>[
      LR1State(index: 0, items: initialItems, viablePrefix: const []),
    ];
    final stateByKey = <String, int>{_itemSetKey(initialItems): 0};
    final transitions = <LR1Transition>[];
    var totalItems = initialItems.length;
    var cursor = 0;
    while (cursor < states.length) {
      if (isCancelled?.call() ?? false) {
        return LR1ConstructionResult(
          outcome: LR1ConstructionOutcome.cancelled,
          message: 'Canonical LR(1) construction was cancelled.',
          structuredMessage: Lr1ParserMessages.constructionCancelled(),
        );
      }
      if (stopwatch.elapsed >= timeout) {
        return LR1ConstructionResult(
          outcome: LR1ConstructionOutcome.timeLimit,
          message:
              'Canonical LR(1) construction timed out after ${timeout.inMilliseconds}ms.',
          structuredMessage: Lr1ParserMessages.constructionTimedOut(timeout),
        );
      }
      final state = states[cursor++];
      final symbols =
          state.items
              .map((item) => item.symbolAfterDot)
              .whereType<String>()
              .toSet()
              .toList()
            ..sort();
      for (final symbol in symbols) {
        final sourceItems =
            state.items.where((item) => item.symbolAfterDot == symbol).toList()
              ..sort(_compareItems);
        final targetItems = closure(sourceItems.map((item) => item.advance()));
        if (closureAbortOutcome != null) {
          return LR1ConstructionResult(
            outcome: closureAbortOutcome!,
            message: closureAbortMessage,
            structuredMessage: closureAbortStructuredMessage,
          );
        }
        final key = _itemSetKey(targetItems);
        var target = stateByKey[key];
        if (target == null) {
          if (states.length >= maxStates) {
            return LR1ConstructionResult(
              outcome: LR1ConstructionOutcome.stateLimit,
              message: 'Canonical LR(1) construction exceeded the state limit.',
              structuredMessage: Lr1ParserMessages.constructionStateLimit(),
            );
          }
          if (totalItems + targetItems.length > maxItems) {
            return LR1ConstructionResult(
              outcome: LR1ConstructionOutcome.itemLimit,
              message: 'Canonical LR(1) construction exceeded the item limit.',
              structuredMessage: Lr1ParserMessages.constructionItemLimit(),
            );
          }
          target = states.length;
          stateByKey[key] = target;
          totalItems += targetItems.length;
          states.add(
            LR1State(
              index: target,
              items: targetItems,
              viablePrefix: [...state.viablePrefix, symbol],
            ),
          );
        }
        transitions.add(
          LR1Transition(
            fromState: state.index,
            toState: target,
            symbol: symbol,
            sourceItems: sourceItems,
          ),
        );
      }
    }

    final actionRows = <int, Map<String, List<LR1Action>>>{
      for (final state in states) state.index: <String, List<LR1Action>>{},
    };
    final gotoRows = <int, Map<String, int>>{
      for (final state in states) state.index: <String, int>{},
    };
    final gotoSourceRows = <int, Map<String, List<LR1Item>>>{
      for (final state in states) state.index: <String, List<LR1Item>>{},
    };
    for (final transition in transitions) {
      if (grammar.terminals.contains(transition.symbol)) {
        _placeAction(
          actionRows[transition.fromState]!,
          transition.symbol,
          LR1Action(
            kind: LR1ActionKind.shift,
            targetState: transition.toState,
            sourceItems: transition.sourceItems,
          ),
        );
      } else if (grammar.nonterminals.contains(transition.symbol)) {
        gotoRows[transition.fromState]![transition.symbol] = transition.toState;
        gotoSourceRows[transition.fromState]![transition.symbol] =
            transition.sourceItems;
      }
    }
    for (final state in states) {
      for (final item in state.items.where((item) => item.isComplete)) {
        if (item.isAugmented && item.lookahead == endMarker) {
          _placeAction(
            actionRows[state.index]!,
            endMarker,
            LR1Action(kind: LR1ActionKind.accept, sourceItems: [item]),
          );
          continue;
        }
        if (item.isAugmented) continue;
        _placeAction(
          actionRows[state.index]!,
          item.lookahead,
          LR1Action(
            kind: LR1ActionKind.reduce,
            productionId: item.productionId,
            productionLeftSide: item.leftSide,
            productionRightSide: item.rightSide,
            productionOrder: item.productionOrder,
            sourceItems: [item],
          ),
        );
      }
    }
    final conflicts = <LR1Conflict>[];
    for (final state in states) {
      final row = actionRows[state.index]!;
      for (final lookahead in row.keys.toList()..sort()) {
        final actions = row[lookahead]!..sort(_compareActions);
        if (actions.length <= 1) continue;
        conflicts.add(
          LR1Conflict(
            state: state.index,
            lookahead: lookahead,
            kind: actions.any((action) => action.kind == LR1ActionKind.shift)
                ? LR1ConflictKind.shiftReduce
                : LR1ConflictKind.reduceReduce,
            actions: actions,
            viablePrefix: state.viablePrefix,
          ),
        );
      }
    }

    final table = LR1ParseTable(
      actions: actionRows,
      gotos: gotoRows,
      gotoSources: gotoSourceRows,
      conflicts: conflicts,
      terminals: {...grammar.terminals, endMarker},
      nonTerminals: grammar.nonterminals,
    );
    return LR1ConstructionResult(
      outcome: LR1ConstructionOutcome.completed,
      construction: LR1Construction(
        sourceGrammar: grammar,
        augmentedProduction: augmentedProduction,
        states: states,
        transitions: transitions,
        table: table,
      ),
    );
  }

  static LR1ParseResult parse(
    Grammar grammar,
    String inputString, {
    LR1Construction? construction,
    int maxSteps = 100000,
    int maxStates = 10000,
    int maxItems = 100000,
    Duration timeout = const Duration(seconds: 5),
    bool Function()? isCancelled,
  }) {
    final stopwatch = Stopwatch()..start();
    var resolvedConstruction = construction;
    if (resolvedConstruction != null &&
        _grammarSignature(resolvedConstruction.sourceGrammar) !=
            _grammarSignature(grammar)) {
      return LR1ParseResult(
        inputString: inputString,
        outcome: LR1ParseOutcome.tableConstructionFailure,
        steps: const [],
        executionTime: stopwatch.elapsed,
        message:
            'The canonical LR(1) collection belongs to a different grammar revision.',
        structuredMessage: Lr1ParserMessages.staleConstruction(),
      );
    }
    if (resolvedConstruction == null) {
      final built = build(
        grammar,
        maxStates: maxStates,
        maxItems: maxItems,
        timeout: timeout,
        isCancelled: isCancelled,
      );
      if (!built.isCompleted) {
        final outcome = switch (built.outcome) {
          LR1ConstructionOutcome.invalidGrammar =>
            LR1ParseOutcome.invalidGrammar,
          LR1ConstructionOutcome.cancelled => LR1ParseOutcome.cancelled,
          LR1ConstructionOutcome.timeLimit => LR1ParseOutcome.timedOut,
          LR1ConstructionOutcome.stateLimit ||
          LR1ConstructionOutcome.itemLimit => LR1ParseOutcome.resourceLimit,
          LR1ConstructionOutcome.completed =>
            LR1ParseOutcome.tableConstructionFailure,
        };
        return LR1ParseResult(
          inputString: inputString,
          outcome: outcome,
          steps: const [],
          executionTime: stopwatch.elapsed,
          message: built.message,
          structuredMessage: built.structuredMessage,
        );
      }
      resolvedConstruction = built.construction!;
    }
    final tokenResult = GrammarInputTokenizer.tokenize(grammar, inputString);
    if (tokenResult.isFailure) {
      return LR1ParseResult(
        inputString: inputString,
        outcome: LR1ParseOutcome.tokenizationFailure,
        steps: const [],
        executionTime: stopwatch.elapsed,
        message: tokenResult.error,
        structuredMessage: tokenResult.structuredError,
        construction: resolvedConstruction,
      );
    }
    if (resolvedConstruction.table.conflicts.isNotEmpty) {
      final first = resolvedConstruction.table.conflicts.first;
      return LR1ParseResult(
        inputString: inputString,
        outcome: LR1ParseOutcome.conflict,
        steps: [
          LR1ParseStep(
            stepNumber: 1,
            stateStackBefore: const [0],
            symbolStackBefore: const [],
            remainingInput: [
              ...tokenResult.data!.map((token) => token.lexeme),
              endMarker,
            ],
            lookahead: first.lookahead,
            lookupState: first.state,
            stateStackAfter: const [0],
            symbolStackAfter: const [],
            diagnostic: LR1ParseDiagnostic.conflict,
            structuredMessage: Lr1ParserMessages.conflict(
              stateId: first.stateId,
              lookahead: first.lookahead,
            ),
            message:
                '${first.kind.name} conflict at [${first.stateId}, ${first.lookahead}].',
          ),
        ],
        executionTime: stopwatch.elapsed,
        message:
            'Grammar is not deterministic canonical LR(1): conflict at [${first.stateId}, ${first.lookahead}].',
        structuredMessage: Lr1ParserMessages.conflict(
          stateId: first.stateId,
          lookahead: first.lookahead,
        ),
        construction: resolvedConstruction,
      );
    }

    final input = <GrammarInputToken>[
      ...tokenResult.data!,
      GrammarInputToken(
        lexeme: endMarker,
        start: inputString.length,
        end: inputString.length,
      ),
    ];
    final states = <int>[0];
    final symbols = <String>[];
    final nodes = <DerivationTreeNode>[];
    final steps = <LR1ParseStep>[];
    var inputIndex = 0;

    List<String> remainingInput() =>
        input.skip(inputIndex).map((token) => token.lexeme).toList();

    LR1ParseResult reject({
      required LR1ParseOutcome outcome,
      required LR1ParseDiagnostic diagnostic,
      required String message,
      StructuredMessage? structuredMessage,
      Set<String> expected = const {},
    }) {
      final beforeStates = List<int>.from(states);
      final beforeSymbols = List<String>.from(symbols);
      steps.add(
        LR1ParseStep(
          stepNumber: steps.length + 1,
          stateStackBefore: beforeStates,
          symbolStackBefore: beforeSymbols,
          remainingInput: remainingInput(),
          lookahead: input[inputIndex].lexeme,
          lookupState: states.last,
          stateStackAfter: beforeStates,
          symbolStackAfter: beforeSymbols,
          partialTree: nodes.isEmpty ? null : lr1TreeFromNode(nodes.last),
          diagnostic: diagnostic,
          structuredMessage: structuredMessage,
          message: message,
        ),
      );
      return LR1ParseResult(
        inputString: inputString,
        outcome: outcome,
        steps: steps,
        executionTime: stopwatch.elapsed,
        tree: nodes.length == 1 ? lr1TreeFromNode(nodes.single) : null,
        message: message,
        structuredMessage: structuredMessage,
        farthestPosition: input[inputIndex].start,
        expectedTerminals: expected,
        construction: resolvedConstruction,
      );
    }

    while (true) {
      if (isCancelled?.call() ?? false) {
        return reject(
          outcome: LR1ParseOutcome.cancelled,
          diagnostic: LR1ParseDiagnostic.cancelled,
          message: 'Canonical LR(1) parsing was cancelled.',
          structuredMessage: Lr1ParserMessages.cancelled(),
        );
      }
      if (stopwatch.elapsed >= timeout) {
        return reject(
          outcome: LR1ParseOutcome.timedOut,
          diagnostic: LR1ParseDiagnostic.timedOut,
          message:
              'Canonical LR(1) parsing timed out after ${timeout.inMilliseconds}ms.',
          structuredMessage: Lr1ParserMessages.timedOut(timeout),
        );
      }
      if (steps.length >= maxSteps) {
        return reject(
          outcome: LR1ParseOutcome.resourceLimit,
          diagnostic: LR1ParseDiagnostic.resourceLimit,
          message: 'Canonical LR(1) parsing reached the $maxSteps-step limit.',
          structuredMessage: Lr1ParserMessages.stepLimitReached(maxSteps),
        );
      }
      final beforeStates = List<int>.from(states);
      final beforeSymbols = List<String>.from(symbols);
      final lookaheadToken = input[inputIndex];
      final actions = resolvedConstruction.table.actionsAt(
        states.last,
        lookaheadToken.lexeme,
      );
      if (actions.isEmpty) {
        final expected = resolvedConstruction.table.actions[states.last]!.keys
            .toSet();
        return reject(
          outcome: LR1ParseOutcome.rejected,
          diagnostic: LR1ParseDiagnostic.emptyActionCell,
          message: 'No ACTION for [I${states.last}, ${lookaheadToken.lexeme}].',
          structuredMessage: Lr1ParserMessages.emptyActionCell(
            stateId: 'I${states.last}',
            lookahead: lookaheadToken.lexeme,
          ),
          expected: expected,
        );
      }
      if (actions.length != 1) {
        return reject(
          outcome: LR1ParseOutcome.conflict,
          diagnostic: LR1ParseDiagnostic.conflict,
          message:
              'Conflicting ACTION entries at [I${states.last}, ${lookaheadToken.lexeme}].',
          structuredMessage: Lr1ParserMessages.actionConflict(
            stateId: 'I${states.last}',
            lookahead: lookaheadToken.lexeme,
          ),
        );
      }
      final action = actions.single;
      String message;
      StructuredMessage? structuredMessage;
      String? reducedProductionId;
      var popCount = 0;
      switch (action.kind) {
        case LR1ActionKind.shift:
          symbols.add(lookaheadToken.lexeme);
          states.add(action.targetState!);
          nodes.add(
            DerivationTreeNode(
              symbol: lookaheadToken.lexeme,
              lexeme: lookaheadToken.lexeme,
              start: lookaheadToken.start,
              end: lookaheadToken.end,
            ),
          );
          inputIndex++;
          message =
              'Shifted ${lookaheadToken.lexeme} and entered I${action.targetState}.';
          structuredMessage = Lr1ParserMessages.shifted(
            symbol: lookaheadToken.lexeme,
            targetState: 'I${action.targetState}',
          );
          break;
        case LR1ActionKind.reduce:
          final right = action.productionRightSide!;
          popCount = right.length;
          if (states.length <= popCount ||
              symbols.length < popCount ||
              nodes.length < popCount) {
            return reject(
              outcome: LR1ParseOutcome.tableConstructionFailure,
              diagnostic: LR1ParseDiagnostic.invalidParserState,
              message: 'LR(1) reduction would underflow the parser stack.',
              structuredMessage: Lr1ParserMessages.invalidParserState(),
            );
          }
          final children = popCount == 0
              ? const <DerivationTreeNode>[]
              : nodes.sublist(nodes.length - popCount);
          if (popCount > 0) {
            states.removeRange(states.length - popCount, states.length);
            symbols.removeRange(symbols.length - popCount, symbols.length);
            nodes.removeRange(nodes.length - popCount, nodes.length);
          }
          final left = action.productionLeftSide!;
          final target = resolvedConstruction.table.gotoAt(states.last, left);
          if (target == null) {
            return reject(
              outcome: LR1ParseOutcome.tableConstructionFailure,
              diagnostic: LR1ParseDiagnostic.missingGoto,
              message: 'Missing GOTO for [I${states.last}, $left].',
              structuredMessage: Lr1ParserMessages.missingGoto(
                stateId: 'I${states.last}',
                nonTerminal: left,
              ),
            );
          }
          symbols.add(left);
          states.add(target);
          nodes.add(DerivationTreeNode(symbol: left, children: children));
          reducedProductionId = action.productionId;
          message =
              'Reduced by ${action.productionId}: $left → ${right.isEmpty ? 'ε' : right.join(' ')}.';
          structuredMessage = Lr1ParserMessages.reduced(
            productionId: action.productionId ?? '',
            leftSide: left,
            rightSide: right.isEmpty ? 'ε' : right.join(' '),
          );
          break;
        case LR1ActionKind.accept:
          message = 'Accepted on the completed augmented start item.';
          structuredMessage = Lr1ParserMessages.accepted();
          break;
      }
      final partialTree = nodes.isEmpty ? null : lr1TreeFromNode(nodes.last);
      steps.add(
        LR1ParseStep(
          stepNumber: steps.length + 1,
          stateStackBefore: beforeStates,
          symbolStackBefore: beforeSymbols,
          remainingInput: input
              .skip(
                action.kind == LR1ActionKind.shift
                    ? inputIndex - 1
                    : inputIndex,
              )
              .map((token) => token.lexeme)
              .toList(),
          lookahead: lookaheadToken.lexeme,
          lookupState: beforeStates.last,
          action: action,
          reducedProductionId: reducedProductionId,
          popCount: popCount,
          stateStackAfter: states,
          symbolStackAfter: symbols,
          partialTree: partialTree,
          structuredMessage: structuredMessage,
          message: message,
        ),
      );
      if (action.kind == LR1ActionKind.accept) {
        stopwatch.stop();
        return LR1ParseResult(
          inputString: inputString,
          outcome: LR1ParseOutcome.accepted,
          steps: steps,
          executionTime: stopwatch.elapsed,
          tree: nodes.length == 1 ? lr1TreeFromNode(nodes.single) : null,
          farthestPosition: inputString.length,
          construction: resolvedConstruction,
        );
      }
    }
  }

  static ({String message, StructuredMessage structuredMessage})?
  _validateGrammar(Grammar grammar) {
    if (grammar.productions.isEmpty) {
      return (
        message: 'Grammar must have at least one production.',
        structuredMessage: Lr1ParserMessages.invalidGrammar(),
      );
    }
    if (!grammar.nonterminals.contains(grammar.startSymbol)) {
      return (
        message: 'The start symbol must be a declared non-terminal.',
        structuredMessage: Lr1ParserMessages.missingStartSymbol(),
      );
    }
    final ids = <String>{};
    for (final production in grammar.productions) {
      if (production.leftSide.length != 1 ||
          !grammar.nonterminals.contains(production.leftSide.single)) {
        return (
          message:
              'Canonical LR(1) requires one declared non-terminal on every production LHS.',
          structuredMessage: Lr1ParserMessages.malformedProduction(),
        );
      }
      if (!ids.add(production.id)) {
        return (
          message:
              'Canonical LR(1) requires unique production IDs; duplicate "${production.id}".',
          structuredMessage: Lr1ParserMessages.duplicateProductionId(
            production.id,
          ),
        );
      }
      for (final symbol in _normalizedRight(grammar, production)) {
        if (!grammar.terminals.contains(symbol) &&
            !grammar.nonterminals.contains(symbol)) {
          return (
            message:
                'Production ${production.id} references undeclared symbol "$symbol".',
            structuredMessage: Lr1ParserMessages.undeclaredSymbol(
              productionId: production.id,
              symbol: symbol,
            ),
          );
        }
      }
    }
    return null;
  }

  static List<String> _normalizedRight(Grammar grammar, Production production) {
    if (production.isLambda || production.rightSide.isEmpty) return const [];
    if (production.rightSide.length == 1) {
      final symbol = production.rightSide.single;
      final declared =
          grammar.terminals.contains(symbol) ||
          grammar.nonterminals.contains(symbol);
      if (!declared && isEpsilonSymbol(symbol)) return const [];
    }
    return List<String>.from(production.rightSide);
  }

  static Set<String> _firstOfSequence(
    List<String> sequence,
    Grammar grammar,
    Map<String, Set<String>> firstSets,
  ) {
    final result = <String>{};
    var nullablePrefix = true;
    for (final symbol in sequence) {
      if (grammar.terminals.contains(symbol) || symbol == endMarker) {
        result.add(symbol);
        nullablePrefix = false;
        break;
      }
      final first = firstSets[symbol] ?? const <String>{};
      result.addAll(first.where((value) => !isEpsilonSymbol(value)));
      if (!first.any(isEpsilonSymbol)) {
        nullablePrefix = false;
        break;
      }
    }
    if (nullablePrefix) result.add(endMarker);
    return result;
  }

  static String _augmentedStartSymbol(Grammar grammar) {
    var candidate = "${grammar.startSymbol}'";
    while (grammar.terminals.contains(candidate) ||
        grammar.nonterminals.contains(candidate)) {
      candidate = "$candidate'";
    }
    return candidate;
  }

  static String _augmentedProductionId(Grammar grammar) {
    final ids = grammar.productions.map((production) => production.id).toSet();
    var candidate = '${grammar.id}:lr1:augmented';
    var suffix = 1;
    while (ids.contains(candidate)) {
      candidate = '${grammar.id}:lr1:augmented:${suffix++}';
    }
    return candidate;
  }

  static void _placeAction(
    Map<String, List<LR1Action>> row,
    String lookahead,
    LR1Action action,
  ) {
    final cell = row.putIfAbsent(lookahead, () => <LR1Action>[]);
    final index = cell.indexWhere(
      (existing) => existing.stableKey == action.stableKey,
    );
    if (index == -1) {
      cell.add(action);
      return;
    }
    final existing = cell[index];
    final sourceItems = <String, LR1Item>{
      for (final item in existing.sourceItems) item.stableKey: item,
      for (final item in action.sourceItems) item.stableKey: item,
    }.values.toList()..sort(_compareItems);
    cell[index] = LR1Action(
      kind: existing.kind,
      targetState: existing.targetState,
      productionId: existing.productionId,
      productionLeftSide: existing.productionLeftSide,
      productionRightSide: existing.productionRightSide,
      productionOrder: existing.productionOrder,
      sourceItems: sourceItems,
    );
  }

  static int _compareProductions(Production left, Production right) {
    final byOrder = left.order.compareTo(right.order);
    if (byOrder != 0) return byOrder;
    final byId = left.id.compareTo(right.id);
    if (byId != 0) return byId;
    final byLeft = left.leftSide
        .join('\u0000')
        .compareTo(right.leftSide.join('\u0000'));
    if (byLeft != 0) return byLeft;
    return left.rightSide
        .join('\u0000')
        .compareTo(right.rightSide.join('\u0000'));
  }

  static int _compareItems(LR1Item left, LR1Item right) =>
      left.stableKey.compareTo(right.stableKey);

  static int _compareActions(LR1Action left, LR1Action right) {
    final rank = <LR1ActionKind, int>{
      LR1ActionKind.shift: 0,
      LR1ActionKind.reduce: 1,
      LR1ActionKind.accept: 2,
    };
    final byKind = rank[left.kind]!.compareTo(rank[right.kind]!);
    return byKind != 0 ? byKind : left.stableKey.compareTo(right.stableKey);
  }

  static String _itemSetKey(List<LR1Item> items) =>
      items.map((item) => item.stableKey).join('\u0001');

  static String _productionKey(Production production) =>
      '${production.id}\u0000${production.order}';

  static String _grammarSignature(Grammar grammar) {
    final terminals = grammar.terminals.toList()..sort();
    final nonTerminals = grammar.nonterminals.toList()..sort();
    final productions = grammar.productions.toList()..sort(_compareProductions);
    return <String>[
      grammar.startSymbol,
      terminals.join('\u0000'),
      nonTerminals.join('\u0000'),
      for (final production in productions)
        [
          production.id,
          production.order,
          production.leftSide.join('\u0000'),
          production.rightSide.join('\u0000'),
          production.isLambda,
        ].join('\u0000'),
    ].join('\u0001');
  }
}
