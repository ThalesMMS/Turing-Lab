import '../../models/grammar.dart';
import '../../models/grammar_parse_report.dart';
import '../../models/lr1_models.dart';
import '../grammar_parser.dart';
import '../lr1_parser.dart';
import '../pda_simulator.dart';
import 'cfg_to_pda_models.dart';

abstract final class CfgToPdaDifferentialChecker {
  static CfgToPdaDifferentialReport check(
    Grammar grammar,
    CfgToPdaConstructionReport construction,
    Iterable<String> inputs, {
    Duration perSampleTimeout = const Duration(milliseconds: 500),
    int maxDepth = 1000,
    int maxConfigurations = 25000,
  }) {
    if (!construction.isCompleted || construction.pda == null) {
      throw ArgumentError.value(
        construction.outcome,
        'construction',
        'Differential checks require a completed construction.',
      );
    }
    if (construction.sourceGrammarId != grammar.id) {
      throw ArgumentError.value(
        grammar.id,
        'grammar',
        'The source grammar does not match the construction.',
      );
    }
    final uniqueInputs = inputs.toSet().toList()..sort();
    final evidence = <CfgToPdaSampleEvidence>[];
    for (final input in uniqueInputs) {
      final grammarOutcome = _grammarOutcome(
        grammar,
        construction.orientation,
        input,
        perSampleTimeout,
      );
      if (grammarOutcome.$1 == null) {
        evidence.add(
          CfgToPdaSampleEvidence(
            input: input,
            outcome: CfgToPdaSampleOutcome.boundedUnknown,
            detailCode: grammarOutcome.$2,
          ),
        );
        continue;
      }
      final pdaResult = PDASimulator.simulateNPDA(
        construction.pda!,
        input,
        timeout: perSampleTimeout,
        mode: construction.acceptanceMode,
        maxDepth: maxDepth,
        maxConfigurations: maxConfigurations,
      );
      if (pdaResult.isFailure) {
        evidence.add(
          CfgToPdaSampleEvidence(
            input: input,
            outcome: CfgToPdaSampleOutcome.boundedUnknown,
            grammarAccepted: grammarOutcome.$1,
            detailCode: 'pda-simulation-failed',
          ),
        );
        continue;
      }
      final pda = pdaResult.data!;
      if (pda.isInconclusive ||
          pda.outcome == PDASimulationOutcome.provenCycle) {
        evidence.add(
          CfgToPdaSampleEvidence(
            input: input,
            outcome: CfgToPdaSampleOutcome.boundedUnknown,
            grammarAccepted: grammarOutcome.$1,
            detailCode: switch (pda.outcome) {
              PDASimulationOutcome.timeout => 'pda-time-limit',
              PDASimulationOutcome.configurationLimit ||
              PDASimulationOutcome.provenCycle =>
                'pda-configuration-limit',
              PDASimulationOutcome.depthLimit => 'pda-depth-limit',
              PDASimulationOutcome.memoryLimit => 'pda-memory-limit',
              PDASimulationOutcome.staleRequest => 'pda-stale-request',
              _ => 'pda-inconclusive',
            },
          ),
        );
        continue;
      }
      final matches = grammarOutcome.$1 == pda.accepted;
      evidence.add(
        CfgToPdaSampleEvidence(
          input: input,
          outcome: matches
              ? (pda.accepted
                  ? CfgToPdaSampleOutcome.matchingAcceptance
                  : CfgToPdaSampleOutcome.matchingRejection)
              : CfgToPdaSampleOutcome.mismatch,
          grammarAccepted: grammarOutcome.$1,
          pdaAccepted: pda.accepted,
        ),
      );
    }
    return CfgToPdaDifferentialReport(samples: evidence);
  }

  static (bool?, String?) _grammarOutcome(
    Grammar grammar,
    CfgToPdaOrientation orientation,
    String input,
    Duration timeout,
  ) {
    if (orientation == CfgToPdaOrientation.ll) {
      final result = GrammarParser.parseLL1(
        grammar,
        input,
        timeout: timeout,
      );
      if (result.isFailure) return (null, 'll-parser-failed');
      return switch (result.data!.outcome) {
        GrammarParseOutcome.accepted => (true, null),
        GrammarParseOutcome.rejected ||
        GrammarParseOutcome.tokenizationFailure =>
          (false, null),
        final outcome => (null, 'll-${outcome.name}'),
      };
    }
    final result = LR1Parser.parse(grammar, input, timeout: timeout);
    return switch (result.outcome) {
      LR1ParseOutcome.accepted => (true, null),
      LR1ParseOutcome.rejected || LR1ParseOutcome.tokenizationFailure => (
          false,
          null
        ),
      final outcome => (null, 'lr-${outcome.name}'),
    };
  }
}
