import 'package:flutter_test/flutter_test.dart';
import 'package:turing_lab/core/algorithms/grammar/brute_force_cfg_parser.dart';
import 'package:turing_lab/core/algorithms/grammar/grammar_parser.dart';
import 'package:turing_lab/core/models/brute_force_parse_models.dart';
import 'package:turing_lab/core/models/grammar.dart';
import 'package:turing_lab/core/models/grammar_parse_report.dart';
import 'package:turing_lab/core/models/production.dart';
import 'package:turing_lab/presentation/widgets/grammar/grammar_simulation_runner.dart';

void main() {
  final now = DateTime(2026);

  Grammar grammar(Iterable<Production> productions, {String name = 'G'}) =>
      Grammar(
        id: 'runner-test',
        name: name,
        terminals: {'a', 'b'},
        nonterminals: {'S', 'A', 'B'},
        startSymbol: 'S',
        productions: productions.toSet(),
        type: GrammarType.contextFree,
        created: now,
        modified: now,
      );

  // S -> A B ; A -> a ; B -> b  (already in CNF so CYK can run directly).
  final cnf = grammar(const [
    Production(id: 'p1', leftSide: ['S'], rightSide: ['A', 'B']),
    Production(id: 'p2', leftSide: ['A'], rightSide: ['a']),
    Production(id: 'p3', leftSide: ['B'], rightSide: ['b']),
  ]);

  // Left-recursive grammar that LL(1) cannot handle: S -> S a | b.
  final leftRecursive = grammar(const [
    Production(id: 'p1', leftSide: ['S'], rightSide: ['S', 'a']),
    Production(id: 'p2', leftSide: ['S'], rightSide: ['b']),
  ]);

  group('background entrypoints', () {
    test('CYK returns the table steps and a derivation tree on acceptance', () {
      final outcome = GrammarSimulationRunner.parseCykWithSteps((
        grammar: cnf,
        inputString: 'ab',
      ));
      expect(outcome.outcome.isSuccess, isTrue);
      expect(outcome.outcome.data!.accepted, isTrue);
      expect(outcome.outcome.data!.steps, isNotEmpty);
      expect(outcome.tree, isNotNull);

      final report = GrammarSimulationRunner.reportFromCykResult(
        'ab',
        outcome.outcome.data!,
        outcome.tree,
      );
      expect(report.accepted, isTrue);
      expect(report.farthestPosition, 2);
      expect(report.trees, hasLength(1));

      final rejected = GrammarSimulationRunner.parseCykWithSteps((
        grammar: cnf,
        inputString: 'ba',
      ));
      expect(rejected.outcome.data!.accepted, isFalse);
      expect(rejected.tree, isNull);
    });

    test('LL(1) run bundles first/follow sets, the table and the parse', () {
      final run = GrammarSimulationRunner.parseLl1Workspace((
        grammar: cnf,
        inputString: 'ab',
      ));
      expect(run.firstSets.isSuccess, isTrue);
      expect(run.followSets.isSuccess, isTrue);
      expect(run.table.isSuccess, isTrue);
      expect(run.parse.isSuccess, isTrue);
      expect(run.parse.data!.accepted, isTrue);
      expect(run.parse.data!.ll1Steps, isNotEmpty);
    });

    test('LR(1) run reports acceptance and conflicts through the report', () {
      final accepted = GrammarSimulationRunner.parseLr1Workspace((
        grammar: leftRecursive,
        inputString: 'baa',
      ));
      expect(accepted.isComplete, isTrue);
      expect(accepted.report!.accepted, isTrue);
      expect(accepted.report!.lr1Steps, isNotEmpty);

      final rejected = GrammarSimulationRunner.parseLr1Workspace((
        grammar: leftRecursive,
        inputString: 'ab',
      ));
      expect(rejected.isComplete, isTrue);
      expect(rejected.report!.accepted, isFalse);
      expect(rejected.report!.outcome, GrammarParseOutcome.rejected);
    });

    test('generic parse honours the strategy hint', () {
      final result = GrammarSimulationRunner.parseWithReport((
        grammar: leftRecursive,
        inputString: 'ba',
        strategyHint: ParsingStrategyHint.auto,
      ));
      expect(result.isSuccess, isTrue);
      expect(result.data!.accepted, isTrue);
    });
  });

  group('report adapters', () {
    test('brute-force acceptance keeps witnesses and ambiguity', () async {
      final ambiguous = grammar(const [
        Production(id: 'p1', leftSide: ['S'], rightSide: ['A']),
        Production(id: 'p2', leftSide: ['S'], rightSide: ['B']),
        Production(id: 'p3', leftSide: ['A'], rightSide: ['a']),
        Production(id: 'p4', leftSide: ['B'], rightSide: ['a']),
      ]);
      final progress = <BruteForceSearchProgress>[];
      final report = await const GrammarSimulationRunner().runBruteForce(
        (grammar: ambiguous, inputString: 'a'),
        mode: BruteForceDerivationMode.leftmost,
        limits: const BruteForceSearchLimits(resultCap: 3),
        cancellationToken: BruteForceCancellationToken(),
        onProgress: progress.add,
      );
      expect(report.accepted, isTrue);
      expect(report.isAmbiguous, isTrue);
      expect(report.trees, hasLength(2));
      expect(report.bruteForceResult, isNotNull);
    });

    test('brute-force rejection maps the outcome', () {
      final result = BruteForceCFGParser.search(
        cnf,
        'aa',
        mode: BruteForceDerivationMode.leftmost,
        limits: const BruteForceSearchLimits(resultCap: 1),
      );
      final report = GrammarSimulationRunner.reportFromBruteForceResult(result);
      expect(report.accepted, isFalse);
      expect(report.outcome, isNot(GrammarParseOutcome.accepted));
      expect(report.bruteForceResult, same(result));
    });
  });

  test('async runs go through compute and return the same results', () async {
    const runner = GrammarSimulationRunner();
    final cyk = await runner.runCyk((grammar: cnf, inputString: 'ab'));
    expect(cyk.outcome.data!.accepted, isTrue);
    final ll1 = await runner.runLl1((grammar: cnf, inputString: 'ab'));
    expect(ll1.parse.data!.accepted, isTrue);
    final lr1 = await runner.runLr1((grammar: cnf, inputString: 'ab'));
    expect(lr1.report!.accepted, isTrue);
    final parse = await runner.runParse((
      grammar: cnf,
      inputString: 'ab',
      strategyHint: ParsingStrategyHint.auto,
    ));
    expect(parse.data!.accepted, isTrue);
  });
}
