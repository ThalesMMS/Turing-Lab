import 'package:flutter_test/flutter_test.dart';
import 'package:turing_lab/core/algorithms/grammar_analyzer.dart';
import 'package:turing_lab/core/messages/structured_message.dart';
import 'package:turing_lab/core/models/grammar.dart';
import 'package:turing_lab/core/models/production.dart';

void main() {
  final timestamp = DateTime(2026, 1, 1);

  Grammar grammar({
    required String id,
    String start = 'S',
    Set<String> nonTerminals = const {'S'},
    Set<String> terminals = const {},
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

  test(
    'predictive message factories preserve typed arguments and round-trip',
    () {
      final messages = <StructuredMessage>[
        GrammarPredictiveMessages.factoringIntroduced(
          nonTerminal: 'S',
          introduced: 'S_1',
          prefix: 'a b',
          productionCount: 2,
        ),
        GrammarPredictiveMessages.factoringDerivation(
          nonTerminal: 'S',
          introduced: 'S_1',
          prefix: 'a b',
          productionCount: 2,
        ),
        GrammarPredictiveMessages.factoringSuffix(
          introduced: 'S_1',
          suffix: 'c',
        ),
        GrammarPredictiveMessages.noFactoringNeeded(),
        GrammarPredictiveMessages.productionLhsUndeclared('A'),
        GrammarPredictiveMessages.missingTableRow('S'),
        GrammarPredictiveMessages.missingFollowOrTableEntry('S'),
        GrammarPredictiveMessages.tablePlacement(
          placement: LL1TablePlacement.first,
          nonTerminal: 'S',
          production: 'S → a',
          lookahead: 'a',
        ),
        GrammarPredictiveMessages.tablePlacement(
          placement: LL1TablePlacement.follow,
          nonTerminal: 'A',
          production: 'A → ε',
          lookahead: '\$',
        ),
        GrammarPredictiveMessages.tableConstructed(2),
        GrammarPredictiveMessages.tableNoConflicts(),
        GrammarPredictiveMessages.tableConflictsDetected(1),
      ];

      expect(messages.map((message) => message.namespace).toSet(), {
        'grammar.predictive',
      });
      expect(messages.map((message) => message.code).toSet(), hasLength(12));
      for (final message in messages) {
        expectRoundTrip(message);
      }

      final introduced = messages.first;
      expect(
        introduced.arguments['non-terminal']?.kind,
        StructuredMessageArgumentKind.symbol,
      );
      expect(introduced.arguments['introduced']?.role, 'grammar-nonterminal');
      expect(
        introduced.arguments['production-count']?.kind,
        StructuredMessageArgumentKind.count,
      );
      expect(
        introduced.arguments['production-count']?.role,
        'grammar-production-count',
      );

      final placement = messages[7];
      expect(
        placement.arguments['production']?.kind,
        StructuredMessageArgumentKind.literal,
      );
      expect(
        placement.arguments['lookahead']?.kind,
        StructuredMessageArgumentKind.symbol,
      );
    },
  );

  test('left factoring keeps legacy text beside structured derivations', () {
    final result = GrammarPredictiveAnalyzer(
      GrammarAnalysisContext(
        grammar(
          id: 'factoring',
          terminals: {'a', 'b', 'c', 'd', 'e'},
          productions: {
            production('p1', 1, 'S', ['a', 'b', 'c']),
            production('p2', 2, 'S', ['a', 'b', 'd']),
            production('p3', 3, 'S', ['a', 'e']),
          },
        ),
      ),
    ).leftFactor();

    expect(result.isSuccess, isTrue, reason: result.error);
    final report = result.data!;
    expect(report.notes, hasLength(2));
    expect(report.structuredNotes, hasLength(report.notes.length));
    expect(report.structuredNotes.map((message) => message.stableCode), [
      'grammar.predictive.factoring-introduced',
      'grammar.predictive.factoring-introduced',
    ]);
    expect(report.derivations, hasLength(report.structuredDerivations.length));
    expect(
      report.structuredDerivations.map((message) => message.code),
      containsAll(<String>['factoring-derivation', 'factoring-suffix']),
    );
    expect(
      report.structuredNotes.first.arguments['production-count']?.value,
      2,
    );
    expect(report.structuredNotes.last.arguments['production-count']?.value, 2);
    for (final message in report.structuredNotes) {
      expectRoundTrip(message);
    }
    for (final message in report.structuredDerivations) {
      expectRoundTrip(message);
    }
  });

  test('a grammar without common prefixes exposes a structured note', () {
    final result = GrammarPredictiveAnalyzer(
      GrammarAnalysisContext(
        grammar(
          id: 'already-factored',
          terminals: {'a', 'b'},
          productions: {
            production('p1', 1, 'S', ['a']),
            production('p2', 2, 'S', ['b']),
          },
        ),
      ),
    ).leftFactor();

    expect(result.isSuccess, isTrue, reason: result.error);
    final report = result.data!;
    expect(report.notes, [
      'No common prefixes requiring factoring were found.',
    ]);
    expect(report.structuredNotes.map((message) => message.stableCode), [
      'grammar.predictive.no-factoring-needed',
    ]);
    expect(report.derivations, isEmpty);
    expect(report.structuredDerivations, isEmpty);
    expectRoundTrip(report.structuredNotes.single);
  });

  test(
    'LL(1) placements and conflicts are paired with structured payloads',
    () {
      final result = GrammarPredictiveAnalyzer(
        GrammarAnalysisContext(
          grammar(
            id: 'll1-conflict',
            nonTerminals: {'S', 'A'},
            terminals: {'a'},
            productions: {
              production('p1', 1, 'S', ['A', 'a']),
              production('p2', 2, 'A', ['a']),
              production('p3', 3, 'A', const [], isLambda: true),
            },
          ),
        ),
      ).buildLL1ParseTable();

      expect(result.isSuccess, isTrue, reason: result.error);
      final report = result.data!;
      expect(report.notes, hasLength(2));
      expect(report.structuredNotes.map((message) => message.stableCode), [
        'grammar.predictive.table-constructed',
        'grammar.predictive.table-conflicts-detected',
      ]);
      expect(
        report.derivations,
        hasLength(report.structuredDerivations.length),
      );
      expect(
        report.structuredDerivations.map((message) => message.stableCode),
        containsAll(<String>[
          'grammar.predictive.table-placement-first',
          'grammar.predictive.table-placement-follow',
        ]),
      );
      expect(report.conflicts, hasLength(report.structuredConflicts.length));
      expect(
        report.structuredConflicts.single.stableCode,
        'grammar.ll1-conflict.detected',
      );
      expect(
        report.structuredConflicts.single.arguments['kind']?.value,
        'first-follow',
      );
      for (final message in report.structuredDerivations) {
        expectRoundTrip(message);
      }
      for (final message in report.structuredConflicts) {
        expectRoundTrip(message);
      }
    },
  );

  test(
    'ambiguity assessment carries table derivations and conflict payloads',
    () {
      final context = GrammarAnalysisContext(
        grammar(
          id: 'ambiguity',
          terminals: {'a'},
          productions: {
            production('p1', 1, 'S', ['a']),
            production('p2', 2, 'S', ['a', 'a']),
          },
        ),
      );

      final assessment = GrammarAmbiguityAnalyzer(context).assess();
      expect(assessment.isSuccess, isTrue, reason: assessment.error);
      final report = assessment.data!;
      expect(report.value.appearsLl1, isFalse);
      expect(report.conflicts, hasLength(report.structuredConflicts.length));
      expect(
        report.structuredConflicts.single.stableCode,
        'grammar.ll1-conflict.detected',
      );
      expect(
        report.derivations,
        hasLength(report.structuredDerivations.length),
      );
      expect(report.structuredNotes, hasLength(2));
      for (final message in report.structuredNotes) {
        expectRoundTrip(message);
      }

      final legacy = GrammarAmbiguityAnalyzer(context).legacyReport();
      expect(legacy.isSuccess, isTrue, reason: legacy.error);
      expect(legacy.data!.notes, hasLength(2));
      expect(legacy.data!.notes.first, contains('LL(1) conflict'));
      expect(
        legacy.data!.notes.last,
        contains('does not necessarily mean the grammar is ambiguous'),
      );
      expect(legacy.data!.structuredConflicts, report.structuredConflicts);
      expect(legacy.data!.structuredDerivations, report.structuredDerivations);
    },
  );
}
