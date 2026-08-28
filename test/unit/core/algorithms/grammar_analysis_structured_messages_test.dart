import 'package:flutter_test/flutter_test.dart';
import 'package:turing_lab/core/algorithms/grammar_analysis_messages.dart';
import 'package:turing_lab/core/algorithms/grammar_analyzer.dart';
import 'package:turing_lab/core/messages/structured_message.dart';
import 'package:turing_lab/core/models/grammar.dart';
import 'package:turing_lab/core/models/production.dart';

void main() {
  final timestamp = DateTime(2026, 1, 1);

  Grammar grammar({
    required String id,
    required String start,
    required Set<String> nonTerminals,
    required Set<String> terminals,
    required Set<Production> productions,
  }) => Grammar(
    id: id,
    name: id,
    terminals: terminals,
    nonterminals: nonTerminals,
    startSymbol: start,
    productions: productions,
    type: GrammarType.contextFree,
    created: timestamp,
    modified: timestamp,
  );

  Production production(
    String id,
    int order,
    String left,
    List<String> right, {
    bool isLambda = false,
  }) => Production(
    id: id,
    order: order,
    leftSide: [left],
    rightSide: right,
    isLambda: isLambda,
  );

  void expectRoundTrip(StructuredMessage message) {
    expect(StructuredMessage.fromJson(message.toJson()), message);
  }

  test('grammar analysis message factories have stable typed payloads', () {
    final messages = <StructuredMessage>[
      GrammarAnalysisMessages.emptyProductions(),
      GrammarAnalysisMessages.noLeftRecursion(),
      GrammarAnalysisMessages.firstProductionLhsUndeclared('S'),
      GrammarAnalysisMessages.firstEpsilonFromEmptyProduction('S'),
      GrammarAnalysisMessages.firstEpsilonFromProduction('S', 'S → ε'),
      GrammarAnalysisMessages.firstTerminalFromProduction(
        left: 'S',
        symbol: 'a',
        production: 'S → a',
      ),
      GrammarAnalysisMessages.firstAbsorbsFirst(
        left: 'S',
        source: 'A',
        production: 'S → A b',
      ),
      GrammarAnalysisMessages.firstEpsilonFromNullableProduction(
        left: 'S',
        production: 'S → A',
      ),
      GrammarAnalysisMessages.firstSetsComputed(3),
      GrammarAnalysisMessages.followStartSymbolUndeclared('S'),
      GrammarAnalysisMessages.followStartSymbolMissingEntry('S'),
      GrammarAnalysisMessages.followStartIncludesEndMarker('S'),
      GrammarAnalysisMessages.followProductionLhsUndeclared('A'),
      GrammarAnalysisMessages.followGainsFromSuffix(
        symbol: 'A',
        gained: 'b',
        production: 'S → A b',
      ),
      GrammarAnalysisMessages.followAbsorbsFollow(
        symbol: 'A',
        source: 'S',
        production: 'S → A',
      ),
      GrammarAnalysisMessages.followSetsComputed(3),
      GrammarAnalysisMessages.processingOrder('S, A'),
      GrammarAnalysisMessages.substitutionNote(production: 'A → S c', via: 'S'),
      GrammarAnalysisMessages.substitutionDerivation(
        production: 'A → S c',
        replacements: 'A → b c | A → d c',
      ),
      GrammarAnalysisMessages.substitutionOperation(current: 'A', via: 'S'),
      GrammarAnalysisMessages.substitutionRationale(current: 'A', via: 'S'),
      GrammarAnalysisMessages.removeVacuousRecursionRationale('A'),
      GrammarAnalysisMessages.vacuousRecursionDerivation('A → A'),
      GrammarAnalysisMessages.recursiveOnlyRationale('A'),
      GrammarAnalysisMessages.recursiveOnlyDerivation('A'),
      GrammarAnalysisMessages.directRecursionIntroduced(
        introduced: "A'",
        nonTerminal: 'A',
      ),
      GrammarAnalysisMessages.moveRecursiveSuffixesRationale(
        nonTerminal: 'A',
        introduced: "A'",
      ),
      GrammarAnalysisMessages.directRecursionRewrittenDerivation(
        nonTerminal: 'A',
        introduced: "A'",
      ),
      GrammarAnalysisMessages.directRecursionOperation('A'),
      GrammarAnalysisMessages.leftCornerCycleRemains(),
      GrammarAnalysisMessages.leftRecursionRemoved(),
    ];

    expect(messages.map((message) => message.namespace).toSet(), {
      'grammar.analysis',
    });
    expect(messages.map((message) => message.code).toSet(), hasLength(31));
    for (final message in messages) {
      expectRoundTrip(message);
    }

    final terminal = GrammarAnalysisMessages.firstTerminalFromProduction(
      left: 'S',
      symbol: 'a',
      production: 'S → a',
    );
    expect(
      terminal.arguments['non-terminal']?.kind,
      StructuredMessageArgumentKind.symbol,
    );
    expect(terminal.arguments['non-terminal']?.role, 'grammar-nonterminal');
    expect(
      terminal.arguments['symbol']?.kind,
      StructuredMessageArgumentKind.symbol,
    );
    expect(
      terminal.arguments['production']?.kind,
      StructuredMessageArgumentKind.literal,
    );

    final count = GrammarAnalysisMessages.firstSetsComputed(3);
    expect(count.arguments['count']?.kind, StructuredMessageArgumentKind.count);
    expect(count.arguments['count']?.role, 'grammar-nonterminal-count');
  });

  test(
    'FIRST and FOLLOW reports retain legacy derivations and structured peers',
    () {
      final input = grammar(
        id: 'first-follow',
        start: 'S',
        nonTerminals: {'S', 'A', 'B'},
        terminals: {'a', 'b'},
        productions: {
          production('p0', 0, 'S', ['A', 'b']),
          production('p1', 1, 'S', ['A']),
          production('p2', 2, 'A', const [], isLambda: true),
          production('p3', 3, 'A', ['a']),
          production('p4', 4, 'B', ['ε', 'a']),
        },
      );

      final first = GrammarAnalyzer.computeFirstSets(input);
      expect(first.isSuccess, isTrue, reason: first.error);
      final firstReport = first.data!;
      expect(firstReport.structuredNotes.map((message) => message.stableCode), [
        'grammar.analysis.first-sets-computed',
      ]);
      expect(
        firstReport.structuredDerivations
            .map((message) => message.stableCode)
            .toSet(),
        containsAll(<String>[
          'grammar.analysis.first-epsilon-empty-production',
          'grammar.analysis.first-terminal-production',
          'grammar.analysis.first-absorbs-first',
          'grammar.analysis.first-epsilon-nullable-production',
          'grammar.analysis.first-epsilon-production',
        ]),
      );
      expect(firstReport.derivations, isNotEmpty);
      expect(
        firstReport.structuredDerivations.length,
        firstReport.derivations.length,
      );
      for (final message in firstReport.structuredDerivations) {
        expectRoundTrip(message);
      }

      final follow = GrammarAnalyzer.computeFollowSets(input);
      expect(follow.isSuccess, isTrue, reason: follow.error);
      final followReport = follow.data!;
      expect(
        followReport.structuredNotes.map((message) => message.stableCode),
        ['grammar.analysis.follow-sets-computed'],
      );
      expect(
        followReport.structuredDerivations.map((message) => message.stableCode),
        containsAll(<String>[
          'grammar.analysis.follow-start-includes-end-marker',
          'grammar.analysis.follow-gains-from-suffix',
          'grammar.analysis.follow-absorbs-follow',
        ]),
      );
      expect(followReport.derivations, isNotEmpty);
      expect(
        followReport.structuredDerivations.length,
        followReport.derivations.length,
      );
      for (final message in followReport.structuredDerivations) {
        expectRoundTrip(message);
      }
    },
  );

  test(
    'left-recursion reports retain legacy text beside structured notes and steps',
    () {
      final input = grammar(
        id: 'direct',
        start: 'A',
        nonTerminals: {'A'},
        terminals: {'a', 'b'},
        productions: {
          production('p0', 0, 'A', ['A', 'a']),
          production('p1', 1, 'A', ['b']),
        },
      );

      final result = GrammarAnalyzer.removeLeftRecursion(input);
      expect(result.isSuccess, isTrue, reason: result.error);
      final report = result.data!;
      expect(report.structuredNotes.map((message) => message.stableCode), [
        'grammar.analysis.processing-order',
        'grammar.analysis.direct-recursion-introduced',
        'grammar.analysis.left-recursion-removed',
      ]);
      expect(
        report.structuredDerivations.map((message) => message.stableCode),
        ['grammar.analysis.direct-recursion-rewritten'],
      );
      expect(report.structuredSteps, hasLength(report.steps.length));
      expect(
        report.structuredSteps.single.operationMessage.stableCode,
        'grammar.analysis.direct-recursion-operation',
      );
      expect(
        report.structuredSteps.single.rationaleMessage.stableCode,
        'grammar.analysis.move-recursive-suffixes-rationale',
      );
      expect(report.steps.single.operation, 'Direct recursion removal for A');
      expect(
        report.steps.single.rationale,
        contains("Move the recursive suffixes of A to A'"),
      );
      expect(
        report
            .structuredSteps
            .single
            .operationMessage
            .arguments['non-terminal']
            ?.value,
        'A',
      );
      for (final message in report.structuredNotes) {
        expectRoundTrip(message);
      }
      for (final message in report.structuredDerivations) {
        expectRoundTrip(message);
      }
      expectRoundTrip(report.structuredSteps.single.operationMessage);
      expectRoundTrip(report.structuredSteps.single.rationaleMessage);

      final invalid = grammar(
        id: 'invalid-cycle',
        start: 'A',
        nonTerminals: {'A', 'B'},
        terminals: {'a'},
        productions: {
          production('p0', 0, 'A', ['B', 'A', 'a']),
          production('p1', 1, 'B', const []),
        },
      );
      final failure = GrammarAnalyzer.removeLeftRecursion(invalid);
      expect(failure.isFailure, isTrue);
      expect(failure.error, contains('left-corner relation'));
      expect(
        failure.structuredError?.stableCode,
        'grammar.analysis.left-corner-cycle-remains',
      );
      expectRoundTrip(failure.structuredError!);
    },
  );
}
