//
//  grammar_simulation_runner.dart
//  Turing Lab
//
//  Execution entrypoints for the grammar simulation panel. The static
//  functions are plain Dart and run on a background isolate through
//  `compute`, so they only take and return objects that survive isolate
//  transfer. The panel owns request validity (stale results, cancellation),
//  state and localized presentation; nothing here touches widgets or a
//  BuildContext.
//

import 'package:flutter/foundation.dart' show compute;

import '../../../core/algorithms/grammar/brute_force_cfg_parser.dart';
import '../../../core/algorithms/cfg/cyk_parser.dart';
import '../../../core/algorithms/grammar/grammar_analyzer.dart';
import '../../../core/algorithms/grammar/grammar_parser.dart';
import '../../../core/algorithms/grammar/lr1_parser.dart';
import '../../../core/messages/structured_message.dart';
import '../../../core/models/brute_force_parse_models.dart';
import '../../../core/models/derivation_tree.dart';
import '../../../core/models/grammar.dart';
import '../../../core/models/grammar_parse_report.dart';
import '../../../core/models/lr1_models.dart';
import '../../../core/result.dart';

/// Request for the generic parser with a strategy hint.
typedef GrammarParseRequest = ({
  Grammar grammar,
  String inputString,
  ParsingStrategyHint strategyHint,
});

/// Request for the CYK, LL(1) and LR(1) teaching runs.
typedef GrammarInputRequest = ({Grammar grammar, String inputString});

/// CYK outcome plus the derivation tree rebuilt from an accepted derivation.
typedef GrammarCykOutcome = ({
  Result<CYKParseResult> outcome,
  DerivationTree? tree,
});

/// Everything the LL(1) teaching view needs, computed in one background run.
class LL1TeachingRun {
  const LL1TeachingRun({
    required this.grammar,
    required this.firstSets,
    required this.followSets,
    required this.table,
    required this.parse,
  });

  final Grammar grammar;
  final Result<GrammarAnalysisReport<Map<String, Set<String>>>> firstSets;
  final Result<GrammarAnalysisReport<Map<String, Set<String>>>> followSets;
  final Result<GrammarAnalysisReport<LL1ParseTable>> table;
  final Result<GrammarParseReport> parse;
}

/// LR(1) construction and parse, or the construction failure.
class LR1TeachingRun {
  const LR1TeachingRun({
    this.grammar,
    this.construction,
    this.parse,
    this.report,
    this.error,
    this.structuredError,
  });

  final Grammar? grammar;
  final LR1Construction? construction;
  final LR1ParseResult? parse;
  final GrammarParseReport? report;
  final String? error;
  final StructuredMessage? structuredError;

  bool get isComplete =>
      report != null &&
      grammar != null &&
      construction != null &&
      parse != null;
}

class GrammarSimulationRunner {
  const GrammarSimulationRunner();

  /// Wall-clock budget for one CYK table construction.
  static const cykTimeout = Duration(seconds: 5);

  // ---- Background entrypoints (isolate-safe, no UI) ----

  static Result<GrammarParseReport> parseWithReport(
    GrammarParseRequest request,
  ) {
    return GrammarParser.parseWithReport(
      request.grammar,
      request.inputString,
      strategyHint: request.strategyHint,
    );
  }

  static GrammarCykOutcome parseCykWithSteps(GrammarInputRequest request) {
    final outcome = CYKParser.parseWithSteps(
      request.grammar,
      request.inputString,
      timeout: cykTimeout,
    );
    final tree = outcome.isSuccess && outcome.data!.accepted
        ? GrammarParser.treeFromCykDerivation(
            request.grammar,
            request.inputString,
            outcome.data!.derivation,
          )
        : null;
    return (outcome: outcome, tree: tree);
  }

  static LL1TeachingRun parseLl1Workspace(GrammarInputRequest request) {
    return LL1TeachingRun(
      grammar: request.grammar,
      firstSets: GrammarAnalyzer.computeFirstSets(request.grammar),
      followSets: GrammarAnalyzer.computeFollowSets(request.grammar),
      table: GrammarAnalyzer.buildLL1ParseTable(request.grammar),
      parse: GrammarParser.parseWithReport(
        request.grammar,
        request.inputString,
        strategyHint: ParsingStrategyHint.ll,
      ),
    );
  }

  static LR1TeachingRun parseLr1Workspace(GrammarInputRequest request) {
    final constructionResult = LR1Parser.build(request.grammar);
    final construction = constructionResult.construction;
    if (construction == null) {
      return LR1TeachingRun(
        error: constructionResult.message,
        structuredError: constructionResult.structuredMessage,
      );
    }
    final parse = LR1Parser.parse(
      request.grammar,
      request.inputString,
      construction: construction,
    );
    return LR1TeachingRun(
      grammar: request.grammar,
      construction: construction,
      parse: parse,
      report: reportFromLr1Result(request.inputString, parse),
    );
  }

  // ---- Report adapters ----

  static GrammarParseReport reportFromLr1Result(
    String inputString,
    LR1ParseResult parse,
  ) {
    final outcome = switch (parse.outcome) {
      LR1ParseOutcome.accepted => GrammarParseOutcome.accepted,
      LR1ParseOutcome.rejected => GrammarParseOutcome.rejected,
      LR1ParseOutcome.invalidGrammar ||
      LR1ParseOutcome.tableConstructionFailure =>
        GrammarParseOutcome.invalidInput,
      LR1ParseOutcome.tokenizationFailure =>
        GrammarParseOutcome.tokenizationFailure,
      LR1ParseOutcome.conflict => GrammarParseOutcome.conflict,
      LR1ParseOutcome.cancelled => GrammarParseOutcome.cancelled,
      LR1ParseOutcome.timedOut => GrammarParseOutcome.timedOut,
      LR1ParseOutcome.resourceLimit => GrammarParseOutcome.stepLimit,
    };
    return parse.accepted
        ? GrammarParseReport.accepted(
            inputString: inputString,
            executionTime: parse.executionTime,
            trees: parse.tree == null ? const [] : [parse.tree!],
            lr1Steps: parse.steps,
          )
        : GrammarParseReport.rejected(
            inputString: inputString,
            farthestPosition: parse.farthestPosition,
            executionTime: parse.executionTime,
            expectedSymbols: parse.expectedTerminals,
            message: parse.message,
            structuredMessage: parse.structuredMessage,
            lr1Steps: parse.steps,
            outcome: outcome,
          );
  }

  static GrammarParseReport reportFromCykResult(
    String inputString,
    CYKParseResult cyk,
    DerivationTree? tree,
  ) {
    return GrammarParseReport(
      inputString: inputString,
      accepted: cyk.accepted,
      farthestPosition: cyk.accepted ? inputString.length : 0,
      expectedSymbols: const <String>{},
      message: cyk.message,
      structuredMessage: cyk.structuredMessage,
      trees: tree == null ? const [] : [tree],
      isAmbiguous: false,
      executionTime: cyk.executionTime,
    );
  }

  static GrammarParseReport reportFromBruteForceResult(
    BruteForceParseResult result,
  ) {
    if (result.accepted) {
      return GrammarParseReport.accepted(
        inputString: result.inputString,
        executionTime: result.statistics.executionTime,
        trees: result.witnesses.map((witness) => witness.tree).toList(),
        isAmbiguous: result.witnessCount > 1,
        bruteForceResult: result,
      );
    }
    final outcome = switch (result.outcome) {
      BruteForceParseOutcome.accepted => GrammarParseOutcome.accepted,
      BruteForceParseOutcome.rejected => GrammarParseOutcome.rejected,
      BruteForceParseOutcome.boundedUnknown =>
        GrammarParseOutcome.boundedUnknown,
      BruteForceParseOutcome.cancelled => GrammarParseOutcome.cancelled,
      BruteForceParseOutcome.invalidGrammar ||
      BruteForceParseOutcome.invalidInput => GrammarParseOutcome.invalidInput,
    };
    return GrammarParseReport.rejected(
      inputString: result.inputString,
      farthestPosition: 0,
      executionTime: result.statistics.executionTime,
      message: result.message,
      structuredMessage: result.structuredMessage,
      outcome: outcome,
      bruteForceResult: result,
    );
  }

  // ---- Async runs (background isolate through compute) ----

  Future<Result<GrammarParseReport>> runParse(GrammarParseRequest request) =>
      compute(parseWithReport, request);

  Future<GrammarCykOutcome> runCyk(GrammarInputRequest request) =>
      compute(parseCykWithSteps, request);

  Future<LL1TeachingRun> runLl1(GrammarInputRequest request) =>
      compute(parseLl1Workspace, request);

  Future<LR1TeachingRun> runLr1(GrammarInputRequest request) =>
      compute(parseLr1Workspace, request);

  /// Exhaustive search stays on the main isolate because it reports progress
  /// and honours the cancellation token cooperatively.
  Future<GrammarParseReport> runBruteForce(
    GrammarInputRequest request, {
    required BruteForceDerivationMode mode,
    required BruteForceSearchLimits limits,
    required BruteForceCancellationToken cancellationToken,
    required void Function(BruteForceSearchProgress progress) onProgress,
  }) async {
    final result = await BruteForceCFGParser.searchAsync(
      request.grammar,
      request.inputString,
      mode: mode,
      limits: limits,
      cancellationToken: cancellationToken,
      onProgress: onProgress,
    );
    return reportFromBruteForceResult(result);
  }
}
