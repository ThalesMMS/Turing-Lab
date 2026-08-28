import 'dart:convert';
import 'dart:io';

import 'package:test/test.dart';
import 'package:turing_lab/core/algorithms/cfg/cfg_toolkit.dart';
import 'package:turing_lab/core/algorithms/cfg/cyk_parser.dart';
import 'package:turing_lab/core/algorithms/grammar_cnf_transformer.dart';
import 'package:turing_lab/core/algorithms/grammar_parser_earley.dart';
import 'package:turing_lab/core/algorithms/grammar_parser_simple_recursive.dart';
import 'package:turing_lab/core/models/grammar.dart';
import 'package:turing_lab/core/models/grammar_parse_report.dart';
import 'package:turing_lab/core/models/production.dart';

import '../../../tool/hard_edge/catalog.dart';
import '../../../tool/hard_edge/families/grammar_adapter.dart';
import '../../../tool/hard_edge/families/grammar_certification.dart';
import '../../../tool/hard_edge/models.dart';
import '../../../tool/hard_edge/runner.dart';

void main() {
  group('grammar hard-edge family', () {
    test('matrix passes and every record has a central descriptor', () async {
      final report = await GrammarFamilyCertification.run(
        const GrammarCertificationOptions(
          seedStart: 336,
          seedCount: 1,
          maximumWordLength: 3,
        ),
      );

      expect(report.passed, isTrue);
      expect(
        grammarHardEdgeDescriptors.map((item) => item.caseId).toSet(),
        report.records.map((item) => item.id).toSet(),
      );
      expect(
        report.records.every(
          (record) => (record.toJson()['provenance']! as Map)['issue'] == 336,
        ),
        isTrue,
      );
      expect(
        grammarHardEdgeDescriptors
            .where(
              (item) => item.expectedOutcome != HardEdgeExpectedOutcome.pass,
            )
            .map((item) => item.caseId)
            .toSet(),
        {'analysis-malformed', 'analysis-conflicts'},
      );
    });

    test('reports are deterministic and mutation probes are killed', () async {
      const options = GrammarCertificationOptions(
        seedStart: 337,
        seedCount: 1,
        maximumWordLength: 2,
      );
      final first = await GrammarFamilyCertification.run(options);
      final second = await GrammarFamilyCertification.run(options);

      expect(
        canonicalJsonEncode(first.toJson()),
        canonicalJsonEncode(second.toJson()),
      );
      expect(runGrammarMutationProbes(), everyElement(_isKilled));
    });

    test('non-definitive oracle evidence remains incomplete', () {
      final oracle = independentBoundedDerives(
        _singleWordGrammar(),
        'a',
        maxDepth: 0,
      );
      final assessment = assessGrammarParserDifferential(
        oracle,
        parserAccepted: true,
      );
      final record = GrammarCertificationRecord(
        id: 'bounded-oracle',
        algorithm: 'test-parser',
        property: 'parser.differential-oracle',
        seed: 336,
        expected: GrammarCertificationOutcome.boundedUnknown,
        actual: assessment.outcome,
        definitive: assessment.definitive,
        evidence: const {},
      );
      final report = GrammarCertificationReport(
        records: [record],
        seedStart: 336,
        seedCount: 1,
      );

      expect(oracle.outcome, IndependentDerivationOutcome.boundedUnknown);
      expect(assessment.outcome, GrammarCertificationOutcome.boundedUnknown);
      expect(assessment.definitive, isFalse);
      expect(record.incomplete, isTrue);
      expect(record.passed, isFalse);
      expect(report.status, GrammarCertificationStatus.incomplete);
      expect(report.toJson()['status'], 'incomplete');
    });

    test('central adapter materializes seed and preserves typed outcomes',
        () async {
      const executor = GrammarHardEdgePropertyExecutor();
      final conflict = grammarHardEdgeDescriptors.singleWhere(
        (item) => item.caseId == 'analysis-conflicts',
      );
      final bounded = grammarHardEdgeDescriptors.singleWhere(
        (item) => item.caseId == 'parser-bounds',
      );
      final parser = grammarHardEdgeDescriptors.singleWhere(
        (item) => item.caseId == 'parser-recursive-descent-identifier',
      );
      final replayShrink = grammarHardEdgeDescriptors.singleWhere(
        (item) => item.caseId == 'parser-replay-shrink-fixture',
      );

      expect(
        await executor.execute(
            _catalogCase(conflict), conflict.fixture(seed: 336)),
        HardEdgeExecutionOutcome.conflict,
      );
      expect(
        await executor.execute(
            _catalogCase(bounded), bounded.fixture(seed: 336)),
        HardEdgeExecutionOutcome.pass,
      );
      expect(
        await executor.execute(_catalogCase(parser), parser.fixture(seed: 336)),
        HardEdgeExecutionOutcome.pass,
      );
      final materialized = await executor.materialize(
        _catalogCase(parser),
        parser.fixture(seed: 336),
        991,
      ) as Map;
      expect(materialized['seed'], 991);
      expect(materialized['expectedInternalOutcome'], 'accepted');

      final inconsistent = Map<String, Object?>.from(parser.fixture(seed: 336))
        ..['expectedInternalOutcome'] = 'rejected';
      expect(
        await executor.execute(_catalogCase(parser), inconsistent),
        HardEdgeExecutionOutcome.violation,
      );

      final replayFixture = replayShrink.fixture(seed: 336);
      final counterexample = replayFixture['counterexample']! as Map;
      expect(counterexample['input'], 'id+id');
      expect(counterexample['grammar'], isA<Map>());
      expect(grammarFailureFixtureIsValid(replayFixture), isTrue);
      expect(grammarFailureFixtureIsApplicable(replayFixture), isTrue);
      expect(
        await executor.execute(
          _catalogCase(replayShrink),
          replayFixture,
        ),
        HardEdgeExecutionOutcome.pass,
      );
      final candidates = const GrammarFailureFixtureShrinker()
          .candidates(replayFixture)
          .toList();
      expect(candidates, isNotEmpty);
      expect(candidates.every(grammarFailureFixtureIsValid), isTrue);
      expect(candidates.any(grammarFailureFixtureIsApplicable), isTrue);
      expect(candidates.any((item) => !grammarFailureFixtureIsApplicable(item)),
          isTrue);

      for (final descriptor in grammarHardEdgeDescriptors) {
        final fixture = descriptor.fixture(seed: 336);
        expect(
          grammarFailureFixtureIsValid(fixture),
          isTrue,
          reason: '${descriptor.caseId} must be a valid shrink artifact',
        );
        expect(
          grammarFailureFixtureIsApplicable(fixture),
          isTrue,
          reason: '${descriptor.caseId} must be applicable to its domain',
        );
        if (!fixture.containsKey('counterexample')) {
          expect(
            const GrammarFailureFixtureShrinker().candidates(fixture),
            isEmpty,
            reason: '${descriptor.caseId} is already a minimal fixed fixture',
          );
        }
      }
    });

    test('central shrink preserves valid fixed grammar failure artifacts',
        () async {
      final root = await Directory.systemTemp.createTemp('grammar-shrink-');
      addTearDown(() => root.delete(recursive: true));
      final descriptor = grammarHardEdgeDescriptors.singleWhere(
        (item) => item.caseId == 'parser-cyk-steps-typed',
      );
      final fixture = descriptor.fixture(seed: 336);
      final failureFile = File(
        '${root.path}${Platform.pathSeparator}failure.json',
      );
      await failureFile.writeAsString(
        canonicalJsonEncode(
          HardEdgeFailureArtifact(
            testCase: _catalogCase(
              descriptor,
              sha256: hardEdgeSha256(
                utf8.encode(canonicalJsonEncode(fixture)),
              ),
            ),
            fixture: fixture,
            minimalFixture: null,
            minimized: false,
          ).toJson(),
        ),
      );

      final output = await shrinkFailureArtifact(
        repositoryRoot: root,
        failureFile: failureFile,
        outputPath: 'minimized.json',
        executor: const _AlwaysViolatingExecutor(),
        shrinker: const GrammarFailureFixtureShrinker(),
        isValid: grammarFailureFixtureIsValid,
        isApplicable: grammarFailureFixtureIsApplicable,
      );
      final minimized = await readFailureArtifact(output);

      expect(minimized.minimized, isTrue);
      expect(minimized.fixture, fixture);
    });

    test('matrix exercises every public parser and hint limit class', () async {
      final report = await GrammarFamilyCertification.run(
        const GrammarCertificationOptions(
          seedStart: 336,
          seedCount: 1,
          maximumWordLength: 3,
        ),
      );
      final cancellation = report.records.singleWhere(
        (record) => record.id == 'parser-cancellation',
      );
      final bounds = report.records.singleWhere(
        (record) => record.id == 'parser-bounds',
      );
      final cancellationEvidence = cancellation.evidence;
      final boundsEvidence = bounds.evidence;

      expect(cancellation.actual, GrammarCertificationOutcome.cancelled);
      expect(cancellationEvidence['ll1'], 'cancelled');
      expect(cancellationEvidence['lr1'], 'cancelled');
      expect(cancellationEvidence['brute'], 'cancelled');
      expect(cancellationEvidence['hint'], 'cancelled');

      expect(bounds.actual, GrammarCertificationOutcome.boundedUnknown);
      expect(boundsEvidence['ll1Timeout'], 'timedOut');
      expect(boundsEvidence['ll1Steps'], 'stepLimit');
      expect(boundsEvidence['lr1ConstructionTime'], 'timeLimit');
      expect(boundsEvidence['lr1ConstructionItems'], 'itemLimit');
      expect(boundsEvidence['lr1ConstructionStates'], 'stateLimit');
      expect(boundsEvidence['lr1ParseTime'], 'timedOut');
      expect(boundsEvidence['lr1ParseSteps'], 'resourceLimit');
      expect(boundsEvidence['hint'], 'boundedUnknown');
      expect(boundsEvidence['hintLimit'], 'depth');
      expect(
        boundsEvidence['bruteLimits'],
        {
          'depth': 'boundedUnknown',
          'exploredNodes': 'boundedUnknown',
          'frontier': 'boundedUnknown',
          'retainedStates': 'boundedUnknown',
          'symbolCount': 'boundedUnknown',
          'time': 'boundedUnknown',
        },
      );
    });

    test('shared runner treats typed limit meta-tests as passed', () async {
      final root = await Directory.systemTemp.createTemp('grammar-runner-');
      addTearDown(() => root.delete(recursive: true));
      await File('${root.path}${Platform.pathSeparator}LICENSE.txt')
          .writeAsString('Apache License 2.0 test basis.\n');
      final descriptors = [
        for (final id in const [
          'parser-cancellation',
          'parser-bounds',
          'parser-recursive-timeout',
          'conversion-tm-unrestricted-grammar',
          'parser-replay-shrink-fixture',
        ])
          grammarHardEdgeDescriptors.singleWhere((item) => item.caseId == id),
      ];
      final cases = <HardEdgeCatalogCase>[];
      for (var index = 0; index < descriptors.length; index++) {
        final relative = 'fixture-$index.json';
        final fixtureSource =
            canonicalJsonEncode(descriptors[index].fixture(seed: 336));
        await File('${root.path}${Platform.pathSeparator}$relative')
            .writeAsString(fixtureSource);
        cases.add(_catalogCase(
          descriptors[index],
          fixture: relative,
          sha256: hardEdgeSha256(utf8.encode(fixtureSource)),
        ));
      }
      final manifest = HardEdgeManifest(
        schemaVersion: 1,
        catalogVersion: 'grammar-runner-test',
        cases: cases,
        mutations: const [],
      );
      final manifestFile =
          File('${root.path}${Platform.pathSeparator}manifest.json');
      await manifestFile.writeAsString(
        '${const JsonEncoder.withIndent('  ').convert(
          jsonDecode(canonicalJsonEncode(manifest.toJson())),
        )}\n',
      );
      final catalog = await HardEdgeCatalog.load(
        repositoryRoot: root,
        manifestFile: manifestFile,
      );
      expect(catalog.manifest.cases, hasLength(descriptors.length));
      expect(
        catalog.manifest.cases.map((item) => item.license).toSet(),
        {'Apache-2.0'},
      );

      final result = await HardEdgeRunner(
        catalog: catalog,
        executor: const GrammarHardEdgePropertyExecutor(),
      ).run(const HardEdgeRunOptions(
        family: 'grammar',
        jobs: 2,
        caseTimeout: Duration(seconds: 5),
      ));

      expect(result.status, HardEdgeRunStatus.passed);
      expect(
        result.cases,
        everyElement(
          isA<HardEdgeCaseResult>()
              .having(
                (item) => item.status,
                'status',
                HardEdgeCaseStatus.passed,
              )
              .having(
                (item) => item.outcome,
                'outcome',
                HardEdgeExecutionOutcome.pass,
              ),
        ),
      );
    });

    test('counterexample replay and shrink use the injected candidate', () {
      final source = GrammarCounterexample(
        grammar: _singleWordGrammar(),
        input: 'aaaa',
        seed: 336,
        property: 'parser.differential-oracle',
      );

      expect(
        replayGrammarCounterexample(source, candidate: (_, __) => true),
        isTrue,
      );
      final shrunk = shrinkGrammarCounterexample(
        source,
        candidate: (_, __) => true,
      );
      expect(shrunk.input, 'aa');
      expect(shrunk.grammar.productions, hasLength(1));
      expect(shrunk.property, source.property);
      expect(
        replayGrammarCounterexample(shrunk, candidate: (_, __) => true),
        isTrue,
      );
    });
  });

  group('issue 336 grammar regressions', () {
    test('recursive descent parses mixed RHS at maximal-munch boundaries', () {
      final parser = SimpleRecursiveDescentParser(_expressionGrammar());

      expect(parser.parseWithReport('id+id').data!.accepted, isTrue);
      expect(parser.parseWithReport('+id').data!.accepted, isFalse);
      expect(
        parser.parseWithReport('id+id', timeout: Duration.zero).data!.outcome,
        GrammarParseOutcome.timedOut,
      );
    });

    test('CNF transformer removes structurally duplicate productions', () {
      final result = GrammarCnfTransformer.toCnf(_nullableGrammar());

      expect(result.isSuccess, isTrue);
      final transformed = result.data!.grammar;
      expect(CFGToolkit.isCNF(transformed), isTrue);
      final shapes = transformed.productions
          .map((item) => '${item.leftSide}->${item.rightSide}/${item.isLambda}')
          .toSet();
      expect(shapes, hasLength(transformed.productions.length));
    });

    test('GNF conversion keeps start productions and bounded language', () {
      final source = _expressionGrammar();
      final result = CFGToolkit.toGNF(source);

      expect(result.isSuccess, isTrue);
      final transformed = result.data!;
      expect(CFGToolkit.isGNF(transformed), isTrue);
      expect(
        transformed.productions.any(
          (production) => production.leftSide.single == source.startSymbol,
        ),
        isTrue,
      );
      for (final input in ['', 'id', 'id+id', 'id+id+id', '+id']) {
        expect(
          EarleyRecognizer(transformed).recognizeWithReport(input).accepted,
          EarleyRecognizer(source).recognizeWithReport(input).accepted,
          reason: 'bounded language mismatch for "$input"',
        );
      }
    });

    test('CFG reduction terminates on unit cycles and is idempotent', () {
      final first = CFGToolkit.reduce(_unitCycleGrammar());

      expect(first.isSuccess, isTrue);
      expect(first.data!.nonterminals, {'S'});
      expect(first.data!.productions.single.rightSide, ['a']);
      final second = CFGToolkit.reduce(first.data!);
      expect(second.isSuccess, isTrue);
      expect(second.data!.productions, first.data!.productions);
    });

    test('unit lifting allocates collision-safe production IDs', () {
      final result = CFGToolkit.reduce(_unitIdCollisionGrammar());

      expect(result.isSuccess, isTrue);
      expect(
        result.data!.productions.map((production) => production.id).toSet(),
        hasLength(result.data!.productions.length),
      );
      expect(
        EarleyRecognizer(result.data!).recognizeWithReport('a').accepted,
        isTrue,
      );
      expect(
        EarleyRecognizer(result.data!).recognizeWithReport('b').accepted,
        isTrue,
      );
    });

    test('CNF helper symbols avoid existing N0 and T0 symbols', () {
      final source = _generatedSymbolCollisionGrammar();
      final result = CFGToolkit.toCNF(source);

      expect(result.isSuccess, isTrue);
      expect(CFGToolkit.isCNF(result.data!), isTrue);
      expect(result.data!.terminals.intersection(result.data!.nonterminals),
          isEmpty);
      expect(
        EarleyRecognizer(result.data!).recognizeWithReport('aab').accepted,
        isTrue,
      );
      expect(
        EarleyRecognizer(result.data!).recognizeWithReport('ab').accepted,
        isFalse,
      );
      expect(
        result.data!.productions.map((production) => production.id).toSet(),
        hasLength(result.data!.productions.length),
      );
    });

    test('Earley and CYK preserve malformed, tokenization, and timeout types',
        () {
      final malformed = _grammar(
        id: 'empty-left-side',
        terminals: {'a'},
        nonterminals: {'S'},
        start: 'S',
        productions: {
          const Production(id: 'bad', leftSide: [], rightSide: ['a']),
        },
      );
      expect(
        EarleyRecognizer(malformed).recognizeWithReport('a').outcome,
        GrammarParseOutcome.invalidInput,
      );
      expect(
        EarleyRecognizer(_expressionGrammar())
            .recognizeWithReport('id', timeout: Duration.zero)
            .outcome,
        GrammarParseOutcome.timedOut,
      );
      expect(
        CYKParser.parseWithSteps(_expressionGrammar(), '#').data!.outcome,
        GrammarParseOutcome.tokenizationFailure,
      );
      expect(
        CYKParser.parseWithSteps(
          _expressionGrammar(),
          'id',
          timeout: Duration.zero,
        ).data!.outcome,
        GrammarParseOutcome.timedOut,
      );
    });
  });
}

Matcher get _isKilled => isA<GrammarMutationResult>()
    .having((result) => result.killed, 'killed', isTrue);

final class _AlwaysViolatingExecutor implements HardEdgePropertyExecutor {
  const _AlwaysViolatingExecutor();

  @override
  Future<HardEdgeExecutionOutcome> execute(
    HardEdgeCatalogCase testCase,
    Object? fixture,
  ) async =>
      HardEdgeExecutionOutcome.violation;
}

HardEdgeCatalogCase _catalogCase(
  GrammarHardEdgeDescriptor descriptor, {
  String fixture = 'generated-by-family-catalog.json',
  String? sha256,
}) =>
    HardEdgeCatalogCase(
      id: 'grammar-${descriptor.caseId}',
      family: 'grammar',
      algorithm: descriptor.algorithm,
      sourceKind: HardEdgeSourceKind.generated,
      seed: 336,
      property: descriptor.property,
      provenance: const HardEdgeProvenance(
        origin: 'Turing Lab issue #336',
        independentlyAuthored: true,
        generator: grammarCertificationGeneratorVersion,
        licenseBasis: 'LICENSE.txt',
      ),
      license: 'Apache-2.0',
      regressionIssue: 336,
      platforms: const ['all'],
      sha256: sha256 ?? '0' * 64,
      generatorVersion: grammarCertificationGeneratorVersion,
      oracleVersion: grammarCertificationOracleVersion,
      budget: const GenerationBudget(maxWordLength: 3),
      fixture: fixture,
      expectedOutcome: descriptor.expectedOutcome,
      requiredTool: null,
    );

Grammar _expressionGrammar() => _grammar(
      id: 'recursive-token-regression',
      terminals: {'id', '+'},
      nonterminals: {'S', 'Tail'},
      start: 'S',
      productions: {
        const Production(
          id: 's-id-tail',
          leftSide: ['S'],
          rightSide: ['id', 'Tail'],
        ),
        const Production(
          id: 'tail-more',
          leftSide: ['Tail'],
          rightSide: ['+', 'id', 'Tail'],
        ),
        const Production(
          id: 'tail-empty',
          leftSide: ['Tail'],
          rightSide: [],
          isLambda: true,
        ),
      },
    );

Grammar _nullableGrammar() => _grammar(
      id: 'cnf-duplicate-regression',
      terminals: {'a', 'b'},
      nonterminals: {'S', 'A', 'B'},
      start: 'S',
      productions: {
        const Production(
          id: 's-ab',
          leftSide: ['S'],
          rightSide: ['A', 'B'],
        ),
        const Production(id: 'a-a', leftSide: ['A'], rightSide: ['a']),
        const Production(
          id: 'a-empty',
          leftSide: ['A'],
          rightSide: [],
          isLambda: true,
        ),
        const Production(id: 'b-b', leftSide: ['B'], rightSide: ['b']),
      },
    );

Grammar _singleWordGrammar() => _grammar(
      id: 'single-word',
      terminals: {'a'},
      nonterminals: {'S', 'U'},
      start: 'S',
      productions: {
        const Production(id: 's-a', leftSide: ['S'], rightSide: ['a']),
        const Production(id: 'u-a', leftSide: ['U'], rightSide: ['a']),
      },
    );

Grammar _unitCycleGrammar() => _grammar(
      id: 'unit-cycle-regression',
      terminals: {'a'},
      nonterminals: {'S', 'A', 'U', 'V'},
      start: 'S',
      productions: {
        const Production(id: 's-a', leftSide: ['S'], rightSide: ['A']),
        const Production(id: 'a-leaf', leftSide: ['A'], rightSide: ['a']),
        const Production(id: 'u-v', leftSide: ['U'], rightSide: ['V']),
        const Production(id: 'v-u', leftSide: ['V'], rightSide: ['U']),
      },
    );

Grammar _unitIdCollisionGrammar() => _grammar(
      id: 'unit-id-collision-regression',
      terminals: {'a', 'b'},
      nonterminals: {'S', 'A', 'B'},
      start: 'S',
      productions: {
        const Production(id: 's-a', leftSide: ['S'], rightSide: ['A']),
        const Production(id: 'a-b', leftSide: ['A'], rightSide: ['B']),
        const Production(id: 'b-leaf', leftSide: ['B'], rightSide: ['b']),
        const Production(
          id: 'b-leaf_unit_A',
          leftSide: ['A'],
          rightSide: ['a'],
        ),
      },
    );

Grammar _generatedSymbolCollisionGrammar() => _grammar(
      id: 'generated-symbol-collision-regression',
      terminals: {'a', 'b'},
      nonterminals: {'S', 'N0', 'T0'},
      start: 'S',
      productions: {
        const Production(
          id: 's-mixed',
          leftSide: ['S'],
          rightSide: ['a', 'N0', 'T0'],
        ),
        const Production(
          id: 's-mixed_b_end',
          leftSide: ['T0'],
          rightSide: ['b'],
        ),
        const Production(id: 'm_a', leftSide: ['N0'], rightSide: ['a']),
      },
    );

Grammar _grammar({
  required String id,
  required Set<String> terminals,
  required Set<String> nonterminals,
  required String start,
  required Set<Production> productions,
}) =>
    Grammar(
      id: id,
      name: id,
      terminals: terminals,
      nonterminals: nonterminals,
      startSymbol: start,
      productions: productions,
      type: GrammarType.contextFree,
      created: DateTime.utc(2026, 8, 26),
      modified: DateTime.utc(2026, 8, 26),
    );
