import 'dart:convert';

import '../algorithms/brute_force_messages.dart';
import '../messages/structured_message.dart';
import 'derivation_tree.dart';

enum BruteForceDerivationMode { leftmost, rightmost, allPositions }

enum BruteForceParseOutcome {
  accepted,
  rejected,
  boundedUnknown,
  cancelled,
  invalidGrammar,
  invalidInput,
}

enum BruteForceSearchLimit {
  depth,
  frontier,
  exploredNodes,
  retainedStates,
  symbolCount,
  time,
}

enum BruteForcePruneReason {
  terminalCount,
  terminalPrefix,
  terminalSuffix,
  terminalSubsequence,
  minimumYield,
  duplicateWitness,
}

enum BruteForceParseDiagnostic {
  emptyGrammar,
  invalidStartSymbol,
  malformedProduction,
  duplicateProductionId,
  overlappingSymbolDeclaration,
  undeclaredSymbol,
  tokenizationFailure,
  limitReached,
  cancelled,
}

class BruteForceSearchLimits {
  const BruteForceSearchLimits({
    this.maxDepth = 32,
    this.maxFrontierSize = 5000,
    this.maxExploredNodes = 50000,
    this.maxRetainedStates = 20000,
    this.maxSymbolCount = 128,
    this.resultCap = 3,
    this.timeLimit = const Duration(seconds: 5),
    this.operationsPerBatch = 128,
  });

  final int maxDepth;
  final int maxFrontierSize;
  final int maxExploredNodes;
  final int maxRetainedStates;
  final int maxSymbolCount;
  final int resultCap;
  final Duration timeLimit;
  final int operationsPerBatch;

  /// Locale-neutral validation feedback for presentation adapters.
  StructuredMessage? get structuredValidationMessage {
    if (maxDepth < 0) {
      return BruteForceMessages.invalidLimitNonNegative('max-depth');
    }
    if (maxFrontierSize <= 0) {
      return BruteForceMessages.invalidLimitPositive('max-frontier-size');
    }
    if (maxExploredNodes <= 0) {
      return BruteForceMessages.invalidLimitPositive('max-explored-nodes');
    }
    if (maxRetainedStates <= 0) {
      return BruteForceMessages.invalidLimitPositive('max-retained-states');
    }
    if (maxSymbolCount < 0) {
      return BruteForceMessages.invalidLimitNonNegative('max-symbol-count');
    }
    if (resultCap <= 0) {
      return BruteForceMessages.invalidLimitPositive('result-cap');
    }
    if (timeLimit.isNegative) {
      return BruteForceMessages.invalidLimitNonNegative('time-limit');
    }
    if (operationsPerBatch <= 0) {
      return BruteForceMessages.invalidLimitPositive('operations-per-batch');
    }
    return null;
  }

  /// Stable compatibility value retained for non-UI callers.
  String? validate() => structuredValidationMessage?.stableCode;

  Map<String, Object> toJson() => {
    'maxDepth': maxDepth,
    'maxFrontierSize': maxFrontierSize,
    'maxExploredNodes': maxExploredNodes,
    'maxRetainedStates': maxRetainedStates,
    'maxSymbolCount': maxSymbolCount,
    'resultCap': resultCap,
    'timeLimitMilliseconds': timeLimit.inMilliseconds,
    'operationsPerBatch': operationsPerBatch,
  };
}

class BruteForceCancellationToken {
  bool _cancelled = false;

  bool get isCancelled => _cancelled;

  void cancel() => _cancelled = true;
}

class BruteForceDerivationStep {
  BruteForceDerivationStep({
    required this.depth,
    required this.productionId,
    required this.occurrenceIndex,
    required List<String> before,
    required List<String> after,
  }) : before = List<String>.unmodifiable(before),
       after = List<String>.unmodifiable(after);

  final int depth;
  final String productionId;
  final int occurrenceIndex;
  final List<String> before;
  final List<String> after;

  String get stableKey => jsonEncode([productionId, occurrenceIndex, after]);

  Map<String, Object> toJson() => {
    'depth': depth,
    'productionId': productionId,
    'occurrenceIndex': occurrenceIndex,
    'before': before,
    'after': after,
  };
}

class BruteForceDerivationWitness {
  BruteForceDerivationWitness({
    required this.mode,
    required List<BruteForceDerivationStep> steps,
    required this.tree,
  }) : steps = List<BruteForceDerivationStep>.unmodifiable(steps);

  final BruteForceDerivationMode mode;
  final List<BruteForceDerivationStep> steps;
  final DerivationTree tree;

  int get depth => steps.length;

  List<List<String>> get sententialForms => List<List<String>>.unmodifiable([
    if (steps.isEmpty) <String>[tree.root.symbol] else steps.first.before,
    ...steps.map((step) => step.after),
  ]);

  String get stableKey =>
      jsonEncode(steps.map((step) => step.stableKey).toList(growable: false));

  Map<String, Object> toJson() => {
    'mode': mode.name,
    'steps': steps.map((step) => step.toJson()).toList(growable: false),
    'tree': tree.toJson(),
  };
}

class BruteForceSearchStatistics {
  BruteForceSearchStatistics({
    required this.exploredNodes,
    required this.generatedNodes,
    required this.frontierSize,
    required this.frontierPeak,
    required this.currentDepth,
    required this.retainedStates,
    required Map<BruteForcePruneReason, int> prunedByReason,
    required this.executionTime,
  }) : prunedByReason = Map<BruteForcePruneReason, int>.unmodifiable(
         prunedByReason,
       );

  final int exploredNodes;
  final int generatedNodes;
  final int frontierSize;
  final int frontierPeak;
  final int currentDepth;
  final int retainedStates;
  final Map<BruteForcePruneReason, int> prunedByReason;
  final Duration executionTime;

  int get prunedNodes =>
      prunedByReason.values.fold(0, (sum, count) => sum + count);

  Map<String, Object> toJson() => {
    'exploredNodes': exploredNodes,
    'generatedNodes': generatedNodes,
    'frontierSize': frontierSize,
    'frontierPeak': frontierPeak,
    'currentDepth': currentDepth,
    'retainedStates': retainedStates,
    'prunedByReason': {
      for (final entry in prunedByReason.entries) entry.key.name: entry.value,
    },
    'executionTimeMicroseconds': executionTime.inMicroseconds,
  };
}

class BruteForceSearchProgress {
  const BruteForceSearchProgress({
    required this.statistics,
    required this.witnessCount,
  });

  final BruteForceSearchStatistics statistics;
  final int witnessCount;
}

class BruteForceParseResult {
  BruteForceParseResult({
    required this.inputString,
    required this.mode,
    required this.outcome,
    required this.statistics,
    required List<BruteForceDerivationWitness> witnesses,
    required this.witnessCount,
    this.limit,
    this.diagnostic,
    this.message,
    this.structuredMessage,
  }) : witnesses = List<BruteForceDerivationWitness>.unmodifiable(witnesses);

  final String inputString;
  final BruteForceDerivationMode mode;
  final BruteForceParseOutcome outcome;
  final BruteForceSearchStatistics statistics;
  final List<BruteForceDerivationWitness> witnesses;
  final int witnessCount;
  final BruteForceSearchLimit? limit;
  final BruteForceParseDiagnostic? diagnostic;
  final String? message;
  final StructuredMessage? structuredMessage;

  bool get accepted => outcome == BruteForceParseOutcome.accepted;

  BruteForceParseResult withoutWitnesses() => BruteForceParseResult(
    inputString: inputString,
    mode: mode,
    outcome: outcome,
    statistics: statistics,
    witnesses: const [],
    witnessCount: witnessCount,
    limit: limit,
    diagnostic: diagnostic,
    message: message,
    structuredMessage: structuredMessage,
  );

  Map<String, Object?> toJson() => {
    'inputString': inputString,
    'mode': mode.name,
    'outcome': outcome.name,
    'statistics': statistics.toJson(),
    'witnessCount': witnessCount,
    'witnesses': witnesses
        .map((witness) => witness.toJson())
        .toList(growable: false),
    'limit': limit?.name,
    'diagnostic': diagnostic?.name,
    'message': message,
    if (structuredMessage != null)
      'structuredMessage': structuredMessage!.toJson(),
  };
}

class BruteForceBatchItem {
  const BruteForceBatchItem({required this.input, required this.result});

  final String input;
  final BruteForceParseResult result;
}

class BruteForceBatchResult {
  BruteForceBatchResult(Iterable<BruteForceBatchItem> items)
    : items = List<BruteForceBatchItem>.unmodifiable(items);

  final List<BruteForceBatchItem> items;
}
