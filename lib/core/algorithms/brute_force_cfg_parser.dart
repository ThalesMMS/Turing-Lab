import 'dart:async';
import 'dart:collection';
import 'dart:convert';

import '../models/brute_force_parse_models.dart';
import '../models/derivation_tree.dart';
import '../models/derivation_tree_node.dart';
import '../models/grammar.dart';
import '../messages/structured_message.dart';
import '../models/production.dart';
import 'grammar_input_tokenizer.dart';
import 'brute_force_messages.dart';

class BruteForceCFGParser {
  const BruteForceCFGParser._();

  static BruteForceParseResult search(
    Grammar grammar,
    String inputString, {
    BruteForceDerivationMode mode = BruteForceDerivationMode.leftmost,
    BruteForceSearchLimits limits = const BruteForceSearchLimits(),
    BruteForceCancellationToken? cancellationToken,
  }) {
    final setup = _prepare(grammar, inputString, mode, limits);
    if (setup.result != null) return setup.result!;
    final engine = _BruteForceSearchEngine(
      grammar: grammar,
      inputString: inputString,
      target: setup.target!,
      mode: mode,
      limits: limits,
      cancellationToken: cancellationToken,
    );
    while (true) {
      final result = engine.runBatch(limits.operationsPerBatch);
      if (result != null) return result;
    }
  }

  static Future<BruteForceParseResult> searchAsync(
    Grammar grammar,
    String inputString, {
    BruteForceDerivationMode mode = BruteForceDerivationMode.leftmost,
    BruteForceSearchLimits limits = const BruteForceSearchLimits(),
    BruteForceCancellationToken? cancellationToken,
    void Function(BruteForceSearchProgress progress)? onProgress,
  }) async {
    final setup = _prepare(grammar, inputString, mode, limits);
    if (setup.result != null) return setup.result!;
    final engine = _BruteForceSearchEngine(
      grammar: grammar,
      inputString: inputString,
      target: setup.target!,
      mode: mode,
      limits: limits,
      cancellationToken: cancellationToken,
    );
    while (true) {
      final result = engine.runBatch(limits.operationsPerBatch);
      if (result != null) return result;
      onProgress?.call(engine.progress);
      await Future<void>.delayed(Duration.zero);
    }
  }

  static BruteForceBatchResult searchBatch(
    Grammar grammar,
    Iterable<String> inputs, {
    BruteForceDerivationMode mode = BruteForceDerivationMode.leftmost,
    BruteForceSearchLimits limits = const BruteForceSearchLimits(),
    BruteForceCancellationToken? cancellationToken,
    bool retainWitnesses = false,
  }) {
    final items = <BruteForceBatchItem>[];
    for (final input in inputs) {
      final result = search(
        grammar,
        input,
        mode: mode,
        limits: limits,
        cancellationToken: cancellationToken,
      );
      items.add(
        BruteForceBatchItem(
          input: input,
          result: retainWitnesses ? result : result.withoutWitnesses(),
        ),
      );
      if (result.outcome == BruteForceParseOutcome.cancelled) break;
    }
    return BruteForceBatchResult(items);
  }

  static _BruteForceSetup _prepare(
    Grammar grammar,
    String inputString,
    BruteForceDerivationMode mode,
    BruteForceSearchLimits limits,
  ) {
    BruteForceParseResult invalid(
      BruteForceParseOutcome outcome,
      BruteForceParseDiagnostic diagnostic,
      StructuredMessage structuredMessage,
    ) => BruteForceParseResult(
      inputString: inputString,
      mode: mode,
      outcome: outcome,
      statistics: BruteForceSearchStatistics(
        exploredNodes: 0,
        generatedNodes: 0,
        frontierSize: 0,
        frontierPeak: 0,
        currentDepth: 0,
        retainedStates: 0,
        prunedByReason: const {},
        executionTime: Duration.zero,
      ),
      witnesses: const [],
      witnessCount: 0,
      diagnostic: diagnostic,
      message: structuredMessage.stableCode,
      structuredMessage: structuredMessage,
    );

    final limitsError = limits.structuredValidationMessage;
    if (limitsError != null) {
      return _BruteForceSetup(
        result: invalid(
          BruteForceParseOutcome.invalidInput,
          BruteForceParseDiagnostic.limitReached,
          limitsError,
        ),
      );
    }
    if (grammar.productions.isEmpty) {
      return _BruteForceSetup(
        result: invalid(
          BruteForceParseOutcome.invalidGrammar,
          BruteForceParseDiagnostic.emptyGrammar,
          BruteForceMessages.emptyGrammar(),
        ),
      );
    }
    if (!grammar.nonterminals.contains(grammar.startSymbol)) {
      return _BruteForceSetup(
        result: invalid(
          BruteForceParseOutcome.invalidGrammar,
          BruteForceParseDiagnostic.invalidStartSymbol,
          BruteForceMessages.invalidStartSymbol(),
        ),
      );
    }
    final overlappingSymbols = grammar.terminals.intersection(
      grammar.nonterminals,
    );
    if (overlappingSymbols.isNotEmpty) {
      final symbols = overlappingSymbols.toList()..sort();
      return _BruteForceSetup(
        result: invalid(
          BruteForceParseOutcome.invalidGrammar,
          BruteForceParseDiagnostic.overlappingSymbolDeclaration,
          BruteForceMessages.overlappingSymbols(symbols.join(', ')),
        ),
      );
    }
    final productionIds = <String>{};
    for (final production in grammar.productions) {
      if (!production.isValid ||
          production.leftSide.length != 1 ||
          !grammar.nonterminals.contains(production.leftSide.single)) {
        return _BruteForceSetup(
          result: invalid(
            BruteForceParseOutcome.invalidGrammar,
            BruteForceParseDiagnostic.malformedProduction,
            BruteForceMessages.malformedProduction(),
          ),
        );
      }
      if (!productionIds.add(production.id)) {
        return _BruteForceSetup(
          result: invalid(
            BruteForceParseOutcome.invalidGrammar,
            BruteForceParseDiagnostic.duplicateProductionId,
            BruteForceMessages.duplicateProductionId(),
          ),
        );
      }
      for (final symbol in production.rightSide) {
        if (!grammar.terminals.contains(symbol) &&
            !grammar.nonterminals.contains(symbol)) {
          return _BruteForceSetup(
            result: invalid(
              BruteForceParseOutcome.invalidGrammar,
              BruteForceParseDiagnostic.undeclaredSymbol,
              BruteForceMessages.undeclaredSymbol(
                productionId: production.id,
                symbol: symbol,
              ),
            ),
          );
        }
      }
    }
    final tokenized = GrammarInputTokenizer.tokenize(grammar, inputString);
    if (tokenized.isFailure) {
      final invalidSymbol = GrammarInputTokenizer.firstInvalidSymbol(
        grammar,
        inputString,
      );
      return _BruteForceSetup(
        result: invalid(
          BruteForceParseOutcome.invalidInput,
          BruteForceParseDiagnostic.tokenizationFailure,
          invalidSymbol == null
              ? BruteForceMessages.invalidInputSymbol('?')
              : BruteForceMessages.invalidInputSymbol(invalidSymbol),
        ),
      );
    }
    return _BruteForceSetup(target: tokenized.data!);
  }
}

class _BruteForceSetup {
  const _BruteForceSetup({this.target, this.result});

  final List<GrammarInputToken>? target;
  final BruteForceParseResult? result;
}

class _BruteForceSearchEngine {
  _BruteForceSearchEngine({
    required this.grammar,
    required this.inputString,
    required this.target,
    required this.mode,
    required this.limits,
    required this.cancellationToken,
  }) : _targetSymbols = target.map((token) => token.lexeme).toList(),
       _productions = grammar.productions.toList()..sort(_compareProductions),
       _minimumYields = _computeMinimumYields(grammar) {
    final initial = _SearchNode(
      form: [grammar.startSymbol],
      steps: const [],
      pathKeys: const [],
    );
    _queue.add(initial);
    _retainedSignaturesByForm[_formKey(initial.form)] = {
      _pathKey(initial.pathKeys),
    };
    if (initial.form.length > limits.maxSymbolCount) {
      _reachedLimit = BruteForceSearchLimit.symbolCount;
      _queue.clear();
    }
  }

  final Grammar grammar;
  final String inputString;
  final List<GrammarInputToken> target;
  final BruteForceDerivationMode mode;
  final BruteForceSearchLimits limits;
  final BruteForceCancellationToken? cancellationToken;
  final List<String> _targetSymbols;
  final List<Production> _productions;
  final Map<String, int> _minimumYields;
  final ListQueue<_SearchNode> _queue = ListQueue<_SearchNode>();
  final Map<String, Set<String>> _retainedSignaturesByForm = {};
  final Map<BruteForcePruneReason, int> _pruned = {};
  final List<BruteForceDerivationWitness> _witnesses = [];
  final Set<String> _witnessKeys = {};
  final Stopwatch _stopwatch = Stopwatch()..start();

  var _explored = 0;
  var _generated = 1;
  var _frontierPeak = 1;
  var _retainedStates = 1;
  var _currentDepth = 0;
  BruteForceSearchLimit? _reachedLimit;

  BruteForceSearchProgress get progress => BruteForceSearchProgress(
    statistics: _statistics,
    witnessCount: _witnesses.length,
  );

  BruteForceSearchStatistics get _statistics => BruteForceSearchStatistics(
    exploredNodes: _explored,
    generatedNodes: _generated,
    frontierSize: _queue.length,
    frontierPeak: _frontierPeak,
    currentDepth: _currentDepth,
    retainedStates: _retainedStates,
    prunedByReason: _pruned,
    executionTime: _stopwatch.elapsed,
  );

  BruteForceParseResult? runBatch(int operations) {
    for (var operation = 0; operation < operations; operation++) {
      final terminal = _terminalResultIfAny();
      if (terminal != null) return terminal;
      final node = _queue.removeFirst();
      _currentDepth = node.steps.length;
      if (_sameSymbols(node.form, _targetSymbols)) {
        _recordWitness(node.steps);
        if (_witnesses.length >= limits.resultCap) return _accepted();
        continue;
      }
      final occurrences = _expandableOccurrences(node.form);
      if (occurrences.isEmpty) continue;
      if (node.steps.length >= limits.maxDepth) {
        _reachedLimit ??= BruteForceSearchLimit.depth;
        continue;
      }
      if (_explored >= limits.maxExploredNodes) {
        _reachedLimit ??= BruteForceSearchLimit.exploredNodes;
        return _finishedAtLimit();
      }
      _explored++;
      for (final occurrence in occurrences) {
        final nonTerminal = node.form[occurrence];
        for (final production in _productions.where(
          (candidate) => candidate.leftSide.single == nonTerminal,
        )) {
          final replacement = production.isLambda
              ? const <String>[]
              : production.rightSide;
          final after = <String>[
            ...node.form.take(occurrence),
            ...replacement,
            ...node.form.skip(occurrence + 1),
          ];
          _generated++;
          if (after.length > limits.maxSymbolCount) {
            _reachedLimit ??= BruteForceSearchLimit.symbolCount;
            continue;
          }
          final pruneReason = _soundPruneReason(after);
          if (pruneReason != null) {
            _incrementPrune(pruneReason);
            continue;
          }
          final step = BruteForceDerivationStep(
            depth: node.steps.length + 1,
            productionId: production.id,
            occurrenceIndex: occurrence,
            before: node.form,
            after: after,
          );
          final steps = <BruteForceDerivationStep>[...node.steps, step];
          final pathKeys = <String>[...node.pathKeys, step.stableKey];
          final pathKey = _pathKey(pathKeys);
          if (_sameSymbols(after, _targetSymbols)) {
            _recordWitness(steps);
            if (_witnesses.length >= limits.resultCap) return _accepted();
            continue;
          }
          final formKey = _formKey(after);
          final existingSignatures = _retainedSignaturesByForm[formKey];
          if (existingSignatures?.contains(pathKey) ??
              false || (existingSignatures?.length ?? 0) >= limits.resultCap) {
            _incrementPrune(BruteForcePruneReason.duplicateWitness);
            continue;
          }
          if (_retainedStates >= limits.maxRetainedStates) {
            _reachedLimit ??= BruteForceSearchLimit.retainedStates;
            continue;
          }
          if (_queue.length >= limits.maxFrontierSize) {
            _reachedLimit ??= BruteForceSearchLimit.frontier;
            continue;
          }
          final signatures = existingSignatures ?? <String>{};
          _retainedSignaturesByForm[formKey] = signatures;
          signatures.add(pathKey);
          _retainedStates++;
          _queue.add(
            _SearchNode(form: after, steps: steps, pathKeys: pathKeys),
          );
          if (_queue.length > _frontierPeak) _frontierPeak = _queue.length;
        }
      }
    }
    return _terminalResultIfAny();
  }

  BruteForceParseResult? _terminalResultIfAny() {
    if (cancellationToken?.isCancelled == true) {
      return _result(
        outcome: BruteForceParseOutcome.cancelled,
        diagnostic: BruteForceParseDiagnostic.cancelled,
        structuredMessage: BruteForceMessages.cancelled(),
      );
    }
    if (_stopwatch.elapsed >= limits.timeLimit) {
      _reachedLimit ??= BruteForceSearchLimit.time;
      return _finishedAtLimit();
    }
    if (_queue.isEmpty) {
      if (_witnesses.isNotEmpty) return _accepted();
      if (_reachedLimit != null) return _finishedAtLimit();
      return _result(
        outcome: BruteForceParseOutcome.rejected,
        structuredMessage: BruteForceMessages.rejectedExhausted(),
      );
    }
    return null;
  }

  BruteForceParseResult _finishedAtLimit() {
    if (_witnesses.isNotEmpty) {
      return _accepted(
        structuredMessage: BruteForceMessages.acceptedAtLimit(
          _reachedLimit!.name,
        ),
      );
    }
    return _result(
      outcome: BruteForceParseOutcome.boundedUnknown,
      diagnostic: BruteForceParseDiagnostic.limitReached,
      structuredMessage: BruteForceMessages.boundedAtLimit(_reachedLimit!.name),
    );
  }

  BruteForceParseResult _accepted({StructuredMessage? structuredMessage}) =>
      _result(
        outcome: BruteForceParseOutcome.accepted,
        structuredMessage: structuredMessage,
      );

  BruteForceParseResult _result({
    required BruteForceParseOutcome outcome,
    BruteForceParseDiagnostic? diagnostic,
    String? message,
    StructuredMessage? structuredMessage,
  }) {
    _stopwatch.stop();
    return BruteForceParseResult(
      inputString: inputString,
      mode: mode,
      outcome: outcome,
      statistics: _statistics,
      witnesses: _witnesses,
      witnessCount: _witnesses.length,
      limit: _reachedLimit,
      diagnostic: diagnostic,
      message: structuredMessage?.stableCode ?? message,
      structuredMessage: structuredMessage,
    );
  }

  List<int> _expandableOccurrences(List<String> form) {
    final occurrences = <int>[
      for (var index = 0; index < form.length; index++)
        if (grammar.nonterminals.contains(form[index])) index,
    ];
    if (occurrences.isEmpty) return const [];
    return switch (mode) {
      BruteForceDerivationMode.leftmost => [occurrences.first],
      BruteForceDerivationMode.rightmost => [occurrences.last],
      BruteForceDerivationMode.allPositions => occurrences,
    };
  }

  BruteForcePruneReason? _soundPruneReason(List<String> form) {
    final terminalCount = form.where(grammar.terminals.contains).length;
    if (terminalCount > _targetSymbols.length) {
      return BruteForcePruneReason.terminalCount;
    }
    final firstNonTerminal = form.indexWhere(grammar.nonterminals.contains);
    final prefixEnd = firstNonTerminal == -1 ? form.length : firstNonTerminal;
    final prefix = form.take(prefixEnd).toList();
    if (!_isPrefix(prefix, _targetSymbols)) {
      return BruteForcePruneReason.terminalPrefix;
    }
    final lastNonTerminal = form.lastIndexWhere(grammar.nonterminals.contains);
    final suffix = lastNonTerminal == -1
        ? form
        : form.skip(lastNonTerminal + 1).toList();
    if (!_isSuffix(suffix, _targetSymbols)) {
      return BruteForcePruneReason.terminalSuffix;
    }
    final fixedTerminals = form.where(grammar.terminals.contains).toList();
    if (!_isSubsequence(fixedTerminals, _targetSymbols)) {
      return BruteForcePruneReason.terminalSubsequence;
    }
    var minimumYield = 0;
    for (final symbol in form) {
      if (grammar.terminals.contains(symbol)) {
        minimumYield++;
      } else {
        final minimum = _minimumYields[symbol] ?? _infinity;
        if (minimum == _infinity) {
          return BruteForcePruneReason.minimumYield;
        }
        minimumYield += minimum;
      }
      if (minimumYield > _targetSymbols.length) {
        return BruteForcePruneReason.minimumYield;
      }
    }
    return null;
  }

  void _recordWitness(List<BruteForceDerivationStep> steps) {
    final tree = _buildTree(grammar, target, steps);
    final witness = BruteForceDerivationWitness(
      mode: mode,
      steps: steps,
      tree: tree,
    );
    if (_witnessKeys.add(witness.stableKey)) _witnesses.add(witness);
  }

  void _incrementPrune(BruteForcePruneReason reason) {
    _pruned[reason] = (_pruned[reason] ?? 0) + 1;
  }
}

class _SearchNode {
  const _SearchNode({
    required this.form,
    required this.steps,
    required this.pathKeys,
  });

  final List<String> form;
  final List<BruteForceDerivationStep> steps;
  final List<String> pathKeys;
}

const _infinity = 1 << 30;

Map<String, int> _computeMinimumYields(Grammar grammar) {
  final minimum = <String, int>{
    for (final nonTerminal in grammar.nonterminals) nonTerminal: _infinity,
  };
  var changed = true;
  while (changed) {
    changed = false;
    for (final production in grammar.productions) {
      var sum = 0;
      var finite = true;
      if (!production.isLambda) {
        for (final symbol in production.rightSide) {
          if (grammar.terminals.contains(symbol)) {
            sum++;
          } else {
            final value = minimum[symbol] ?? _infinity;
            if (value == _infinity) {
              finite = false;
              break;
            }
            sum += value;
          }
        }
      }
      if (finite && sum < minimum[production.leftSide.single]!) {
        minimum[production.leftSide.single] = sum;
        changed = true;
      }
    }
  }
  return minimum;
}

DerivationTree _buildTree(
  Grammar grammar,
  List<GrammarInputToken> target,
  List<BruteForceDerivationStep> steps,
) {
  final root = _MutableTreeNode(grammar.startSymbol);
  final frontier = <_MutableTreeNode>[root];
  final productions = {
    for (final production in grammar.productions) production.id: production,
  };
  for (final step in steps) {
    final production = productions[step.productionId]!;
    final node = frontier[step.occurrenceIndex];
    final replacementChildren = production.isLambda
        ? const <_MutableTreeNode>[]
        : production.rightSide.map(_MutableTreeNode.new).toList();
    node.children = production.isLambda
        ? <_MutableTreeNode>[_MutableTreeNode('ε')]
        : replacementChildren;
    frontier.replaceRange(
      step.occurrenceIndex,
      step.occurrenceIndex + 1,
      replacementChildren,
    );
  }
  var terminalIndex = 0;
  DerivationTreeNode freeze(_MutableTreeNode node) {
    if (node.children.isNotEmpty) {
      return DerivationTreeNode(
        symbol: node.symbol,
        children: node.children.map(freeze).toList(growable: false),
      );
    }
    if (grammar.terminals.contains(node.symbol) &&
        terminalIndex < target.length) {
      final token = target[terminalIndex++];
      return DerivationTreeNode(
        symbol: node.symbol,
        lexeme: token.lexeme,
        start: token.start,
        end: token.end,
      );
    }
    return DerivationTreeNode(symbol: node.symbol);
  }

  return DerivationTree(root: freeze(root), isShallow: false);
}

class _MutableTreeNode {
  _MutableTreeNode(this.symbol);

  final String symbol;
  List<_MutableTreeNode> children = const [];
}

int _compareProductions(Production left, Production right) {
  final order = left.order.compareTo(right.order);
  if (order != 0) return order;
  final id = left.id.compareTo(right.id);
  if (id != 0) return id;
  return left.stringRepresentation.compareTo(right.stringRepresentation);
}

String _formKey(List<String> symbols) => jsonEncode(symbols);

String _pathKey(List<String> steps) => jsonEncode(steps);

bool _sameSymbols(List<String> left, List<String> right) {
  if (left.length != right.length) return false;
  for (var index = 0; index < left.length; index++) {
    if (left[index] != right[index]) return false;
  }
  return true;
}

bool _isPrefix(List<String> prefix, List<String> target) {
  if (prefix.length > target.length) return false;
  for (var index = 0; index < prefix.length; index++) {
    if (prefix[index] != target[index]) return false;
  }
  return true;
}

bool _isSuffix(List<String> suffix, List<String> target) {
  if (suffix.length > target.length) return false;
  final offset = target.length - suffix.length;
  for (var index = 0; index < suffix.length; index++) {
    if (suffix[index] != target[offset + index]) return false;
  }
  return true;
}

bool _isSubsequence(List<String> sequence, List<String> target) {
  var targetIndex = 0;
  for (final symbol in sequence) {
    while (targetIndex < target.length && target[targetIndex] != symbol) {
      targetIndex++;
    }
    if (targetIndex == target.length) return false;
    targetIndex++;
  }
  return true;
}
