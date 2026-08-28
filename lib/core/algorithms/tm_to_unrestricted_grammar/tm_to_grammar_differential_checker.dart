import '../../grammar/phrase_structure/phrase_structure.dart';
import '../../models/tm.dart';
import '../../models/tm_execution_analysis.dart';
import '../tm_execution_analyzer.dart';
import 'tm_to_grammar_models.dart';

abstract final class TMToGrammarDifferentialChecker {
  static Future<TMToGrammarDifferentialReport> check(
    TM tm,
    TMToGrammarConstructionReport construction,
    Iterable<List<String>> inputs, {
    int tmMaxSteps = 100,
    int tmMaxConfigurations = 5000,
    int grammarMaxExpandedForms = 50000,
    int grammarMaxVisitedForms = 100000,
    int grammarMaxFrontierSize = 25000,
    int grammarMaxSymbolCount = 96,
    Duration perSampleTimeout = const Duration(seconds: 2),
  }) async {
    if (!construction.isCompleted || construction.grammar == null) {
      throw ArgumentError.value(
        construction.outcome,
        'construction',
        'Differential checks require a completed construction.',
      );
    }
    if (construction.sourceTmId != tm.id) {
      throw ArgumentError.value(
        tm.id,
        'tm',
        'The source TM does not match the construction.',
      );
    }
    final unique = <String, List<String>>{};
    for (final input in inputs) {
      final copy = List<String>.unmodifiable(input);
      unique.putIfAbsent(_tokenKey(copy), () => copy);
    }
    final keys = unique.keys.toList()..sort();
    final samples = <TMToGrammarSampleEvidence>[];
    for (final key in keys) {
      final input = unique[key]!;
      if (input.any((symbol) => !tm.alphabet.contains(symbol))) {
        samples.add(
          TMToGrammarSampleEvidence(
            inputTokens: input,
            outcome: TMToGrammarSampleOutcome.invalid,
            detailCode: 'input-symbol-outside-alphabet',
          ),
        );
        continue;
      }
      final tmResult = await TMExecutionAnalyzer.analyzeTokens(
        tm,
        input,
        maxSteps: tmMaxSteps,
        maxConfigurations: tmMaxConfigurations,
        timeout: perSampleTimeout,
        includeTrace: false,
      );
      final tmAccepted = switch (tmResult.outcome) {
        TMExecutionOutcome.accepted => true,
        TMExecutionOutcome.haltedRejected ||
        TMExecutionOutcome.provenCycle =>
          false,
        _ => null,
      };
      if (tmAccepted == null) {
        samples.add(
          TMToGrammarSampleEvidence(
            inputTokens: input,
            outcome: tmResult.outcome == TMExecutionOutcome.invalidMachine
                ? TMToGrammarSampleOutcome.invalid
                : TMToGrammarSampleOutcome.boundedUnknown,
            detailCode: 'tm-${tmResult.outcome.name}',
          ),
        );
        continue;
      }
      final grammarResult = await BoundedDerivationSearch.run(
        grammar: construction.grammar!,
        input: GrammarSymbolSequence(
          input.map(TerminalGrammarSymbol.new),
        ),
        limits: DerivationSearchLimits(
          maxExpandedForms: grammarMaxExpandedForms,
          maxVisitedForms: grammarMaxVisitedForms,
          maxFrontierSize: grammarMaxFrontierSize,
          maxSymbolCount: grammarMaxSymbolCount,
          timeLimit: perSampleTimeout,
        ),
      );
      final grammarAccepted = switch (grammarResult) {
        DerivationAccepted() => true,
        DerivationExhausted() => false,
        _ => null,
      };
      if (grammarAccepted == null) {
        samples.add(
          TMToGrammarSampleEvidence(
            inputTokens: input,
            outcome: grammarResult is DerivationInvalid
                ? TMToGrammarSampleOutcome.invalid
                : TMToGrammarSampleOutcome.boundedUnknown,
            tmAccepted: tmAccepted,
            detailCode: 'grammar-${grammarResult.runtimeType}',
          ),
        );
        continue;
      }
      final matches = tmAccepted == grammarAccepted;
      samples.add(
        TMToGrammarSampleEvidence(
          inputTokens: input,
          outcome: matches
              ? (tmAccepted
                  ? TMToGrammarSampleOutcome.matchingAcceptance
                  : TMToGrammarSampleOutcome.matchingRejection)
              : TMToGrammarSampleOutcome.mismatch,
          tmAccepted: tmAccepted,
          grammarAccepted: grammarAccepted,
        ),
      );
    }
    return TMToGrammarDifferentialReport(samples);
  }

  static String _tokenKey(List<String> tokens) =>
      tokens.map((token) => '${token.length}:$token').join('|');
}
