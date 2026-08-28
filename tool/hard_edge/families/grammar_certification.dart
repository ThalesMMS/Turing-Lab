import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:turing_lab/core/algorithms/brute_force_cfg_parser.dart';
import 'package:turing_lab/core/algorithms/cfg/cfg_toolkit.dart';
import 'package:turing_lab/core/algorithms/cfg/cyk_parser.dart';
import 'package:turing_lab/core/algorithms/fsa_to_grammar_converter.dart';
import 'package:turing_lab/core/algorithms/grammar_analyzer.dart';
import 'package:turing_lab/core/algorithms/grammar_cnf_transformer.dart';
import 'package:turing_lab/core/algorithms/grammar_gnf_transformer.dart';
import 'package:turing_lab/core/algorithms/grammar_input_tokenizer.dart';
import 'package:turing_lab/core/algorithms/grammar_parser.dart';
import 'package:turing_lab/core/algorithms/grammar_parser_earley.dart';
import 'package:turing_lab/core/algorithms/grammar_parser_simple_recursive.dart';
import 'package:turing_lab/core/algorithms/grammar_to_fsa_converter.dart';
import 'package:turing_lab/core/algorithms/grammar_to_pda/cfg_to_pda_converter.dart';
import 'package:turing_lab/core/algorithms/grammar_to_pda/cfg_to_pda_differential_checker.dart';
import 'package:turing_lab/core/algorithms/grammar_to_pda/cfg_to_pda_models.dart';
import 'package:turing_lab/core/algorithms/lr1_parser.dart';
import 'package:turing_lab/core/algorithms/pda_to_cfg_converter.dart';
import 'package:turing_lab/core/algorithms/tm_to_unrestricted_grammar/tm_to_unrestricted_grammar.dart';
import 'package:turing_lab/core/grammar/dependency_graph/variable_dependency_graph.dart';
import 'package:turing_lab/core/grammar/phrase_structure/bounded_derivation_search.dart';
import 'package:turing_lab/core/grammar/phrase_structure/grammar_classification.dart';
import 'package:turing_lab/core/grammar/phrase_structure/grammar_symbol.dart';
import 'package:turing_lab/core/grammar/phrase_structure/legacy_context_free_grammar_adapter.dart';
import 'package:turing_lab/core/grammar/phrase_structure/phrase_structure_grammar.dart';
import 'package:turing_lab/core/grammar/phrase_structure/phrase_structure_production.dart';
import 'package:turing_lab/core/grammar/phrase_structure/symbol_sequence.dart';
import 'package:turing_lab/core/grammar/phrase_structure/user_derivation_session.dart';
import 'package:turing_lab/core/grammar/phrase_structure/user_derivation_hint.dart';
import 'package:turing_lab/core/models/brute_force_parse_models.dart';
import 'package:turing_lab/core/models/derivation_tree_node.dart';
import 'package:turing_lab/core/models/grammar.dart';
import 'package:turing_lab/core/models/grammar_parse_report.dart';
import 'package:turing_lab/core/models/lr1_models.dart';
import 'package:turing_lab/core/models/pda.dart';
import 'package:turing_lab/core/models/production.dart';
import 'package:turing_lab/core/models/tm.dart';
import 'package:vector_math/vector_math_64.dart';

import '../generation.dart';
import '../models.dart';

const grammarCertificationSchemaVersion = 1;
const grammarCertificationGeneratorVersion = 'grammar-family-v1';
const grammarCertificationOracleVersion = 'bounded-enumerator-v1';

enum GrammarCertificationOutcome {
  verified,
  accepted,
  rejected,
  conflict,
  boundedUnknown,
  cancelled,
  invalid,
  stale,
  violation,
}
enum GrammarCertificationStatus { passed, failed, incomplete }

final class GrammarCertificationRecord {
  const GrammarCertificationRecord({
    required this.id,
    required this.algorithm,
    required this.property,
    required this.seed,
    required this.expected,
    required this.actual,
    this.definitive = true,
    required this.evidence,
  });

  final String id;
  final String algorithm;
  final String property;
  final int seed;
  final GrammarCertificationOutcome expected;
  final GrammarCertificationOutcome actual;
  final bool definitive;
  final Map<String, Object?> evidence;

  bool get passed => definitive && actual == expected;

  bool get incomplete => !definitive && actual == expected;

  bool get failed => actual != expected;

  Map<String, Object?> toJson() => {
        'actual': actual.name,
        'algorithm': algorithm,
        'definitive': definitive,
        'evidence': evidence,
        'expected': expected.name,
        'id': id,
        'passed': passed,
        'property': property,
        'provenance': {
          'generator': grammarCertificationGeneratorVersion,
          'independentlyAuthored': true,
          'issue': 336,
          'origin': 'Turing Lab grammar hard-edge certification',
          'sourceKind': 'generated',
        },
        'reproductionCommand':
            'dart run tool/hard_edge_grammar_cases.dart run --seed $seed --case $id',
        'seed': seed,
      };
}

final class GrammarCertificationReport {
  GrammarCertificationReport({
    required Iterable<GrammarCertificationRecord> records,
    required this.seedStart,
    required this.seedCount,
  }) : records = List<GrammarCertificationRecord>.unmodifiable(records);

  final List<GrammarCertificationRecord> records;
  final int seedStart;
  final int seedCount;

  GrammarCertificationStatus get status {
    if (records.any((record) => record.failed)) {
      return GrammarCertificationStatus.failed;
    }
    if (records.any((record) => record.incomplete)) {
      return GrammarCertificationStatus.incomplete;
    }
    return GrammarCertificationStatus.passed;
  }

  bool get passed => status == GrammarCertificationStatus.passed;

  Map<String, Object?> toJson() {
    final algorithms = <String, int>{};
    final properties = <String, int>{};
    for (final record in records) {
      algorithms.update(record.algorithm, (value) => value + 1,
          ifAbsent: () => 1);
      properties.update(record.property, (value) => value + 1,
          ifAbsent: () => 1);
    }
    return {
      'coverage': {
        'algorithms': _sortedCounts(algorithms),
        'properties': _sortedCounts(properties),
        'seeds': [
          for (var seed = seedStart; seed < seedStart + seedCount; seed++) seed
        ],
      },
      'generatorVersion': grammarCertificationGeneratorVersion,
      'oracleVersion': grammarCertificationOracleVersion,
      'records': records.map((record) => record.toJson()).toList(),
      'remotelyVerified': false,
      'schemaVersion': grammarCertificationSchemaVersion,
      'status': status.name,
    };
  }
}

final class GrammarCertificationOptions {
  const GrammarCertificationOptions({
    this.seedStart = 336,
    this.seedCount = 4,
    this.maximumWordLength = 3,
    this.caseFilter,
  });

  final int seedStart;
  final int seedCount;
  final int maximumWordLength;
  final String? caseFilter;

  void validate() {
    if (seedStart < 0 || seedStart > 0xffffffff) {
      throw RangeError.range(seedStart, 0, 0xffffffff, 'seedStart');
    }
    if (seedCount <= 0 || seedCount > 64) {
      throw RangeError.range(seedCount, 1, 64, 'seedCount');
    }
    if (seedStart + seedCount - 1 > 0xffffffff) {
      throw const FormatException('Seed range exceeds uint32.');
    }
    if (maximumWordLength < 0 || maximumWordLength > 6) {
      throw RangeError.range(maximumWordLength, 0, 6, 'maximumWordLength');
    }
  }
}

abstract final class GrammarFamilyCertification {
  static Future<GrammarCertificationReport> run(
    GrammarCertificationOptions options,
  ) async {
    options.validate();
    final records = <GrammarCertificationRecord>[];
    for (var offset = 0; offset < options.seedCount; offset++) {
      final seed = options.seedStart + offset;
      records.addAll(await _runSeed(seed, options.maximumWordLength));
    }
    final filtered = options.caseFilter == null
        ? records
        : records.where((record) => record.id == options.caseFilter).toList();
    if (filtered.isEmpty) {
      throw const FormatException('No grammar certification case matched.');
    }
    return GrammarCertificationReport(
      records: filtered,
      seedStart: options.seedStart,
      seedCount: options.seedCount,
    );
  }

  static Future<List<GrammarCertificationRecord>> _runSeed(
    int seed,
    int maximumWordLength,
  ) async {
    final records = <GrammarCertificationRecord>[];
    final grammar = _expressionGrammar(seed);
    final sourceJson = canonicalJsonEncode(_semanticGrammarJson(grammar));

    void add({
      required String id,
      required String algorithm,
      required String property,
      required GrammarCertificationOutcome expected,
      required GrammarCertificationOutcome actual,
      bool definitive = true,
      Map<String, Object?> evidence = const {},
    }) {
      records.add(GrammarCertificationRecord(
        id: id,
        algorithm: algorithm,
        property: property,
        seed: seed,
        expected: expected,
        actual: actual,
        definitive: definitive,
        evidence: evidence,
      ));
    }

    final malformed = _malformedGrammar();
    final malformedReport =
        GrammarAnalyzer.validateMalformedProductions(malformed);
    add(
      id: 'analysis-malformed',
      algorithm: 'grammar-validation',
      property: 'diagnostics.non-crashing',
      expected: GrammarCertificationOutcome.invalid,
      actual: malformedReport.isSuccess &&
              malformedReport.data!.diagnostics.isNotEmpty
          ? GrammarCertificationOutcome.invalid
          : GrammarCertificationOutcome.violation,
      evidence: {
        'diagnostics': malformedReport.data?.diagnostics
                .map((diagnostic) => diagnostic.code)
                .toList() ??
            const [],
      },
    );

    final classification = PhraseGrammarClassifier.classifyLegacy(grammar);
    add(
      id: 'analysis-classification',
      algorithm: 'chomsky-classifier',
      property: 'classification.cfg',
      expected: GrammarCertificationOutcome.verified,
      actual: classification.isValid
          ? GrammarCertificationOutcome.verified
          : GrammarCertificationOutcome.violation,
      evidence: {'classification': classification.classification.name},
    );

    final structural = _structuralGrammar(seed);
    final unreachable =
        GrammarAnalyzer.detectUnreachableNonTerminals(structural).data!;
    final unproductive =
        GrammarAnalyzer.detectUnproductiveNonTerminals(structural).data!;
    final dependency = VariableDependencyGraphAnalyzer.analyzeContextFree(
      structural,
      sourceRevision: seed,
      mode: VariableDependencyMode.directOccurrence,
    );
    final structuralVerified = unreachable.diagnostics
            .any((diagnostic) => diagnostic.symbols.contains('U')) &&
        unproductive.diagnostics
            .any((diagnostic) => diagnostic.symbols.contains('U')) &&
        dependency.unreachableVariables.contains('U') &&
        dependency.nonproductiveVariables.contains('U') &&
        dependency.cycleWitnesses.isNotEmpty;
    add(
      id: 'analysis-structural-scc',
      algorithm: 'reachability-productivity-dependency-graph',
      property: 'analysis.scc-witnesses',
      expected: GrammarCertificationOutcome.verified,
      actual: structuralVerified
          ? GrammarCertificationOutcome.verified
          : GrammarCertificationOutcome.violation,
      evidence: {
        'cycles': dependency.cycleWitnesses
            .map((witness) => witness.variables)
            .toList(),
        'nonproductive': dependency.nonproductiveVariables.toList()..sort(),
        'unreachable': dependency.unreachableVariables.toList()..sort(),
      },
    );

    final first = GrammarAnalyzer.computeFirstSets(grammar);
    final follow = GrammarAnalyzer.computeFollowSets(grammar);
    final llTable = GrammarAnalyzer.buildLL1ParseTable(grammar);
    final predictiveVerified = first.isSuccess &&
        follow.isSuccess &&
        llTable.isSuccess &&
        llTable.data!.value.typedConflicts.isEmpty &&
        first.data!.value['S']!.contains('id') &&
        follow.data!.value['Tail']!.contains(r'$');
    add(
      id: 'analysis-first-follow-ll1',
      algorithm: 'nullable-first-follow-ll1',
      property: 'predictive.fixed-point',
      expected: GrammarCertificationOutcome.verified,
      actual: predictiveVerified
          ? GrammarCertificationOutcome.verified
          : GrammarCertificationOutcome.violation,
      evidence: {
        'firstS': _sortedNullable(first.data?.value['S']),
        'followTail': _sortedNullable(follow.data?.value['Tail']),
      },
    );

    final reordered = _expressionGrammar(seed ^ 0x9e3779b9);
    final renamed = _renameNonterminals(
      grammar,
      const {'S': 'Start', 'Tail': 'Suffix'},
    );
    add(
      id: 'metamorphic-order-renaming',
      algorithm: 'grammar-model-and-parsers',
      property: 'metamorphic.insertion-order-and-symbol-renaming',
      expected: GrammarCertificationOutcome.verified,
      actual: _sameBoundedLanguage(
                grammar,
                reordered,
                maximumWordLength,
              ) &&
              _sameBoundedLanguage(grammar, renamed, maximumWordLength)
          ? GrammarCertificationOutcome.verified
          : GrammarCertificationOutcome.violation,
      evidence: {
        'renamedStart': renamed.startSymbol,
        'sourceUnchanged':
            sourceJson == canonicalJsonEncode(_semanticGrammarJson(grammar)),
      },
    );

    final conflictGrammar = _ambiguousGrammar(seed);
    final llConflict = GrammarAnalyzer.buildLL1ParseTable(conflictGrammar);
    final lrConflict = LR1Parser.parse(conflictGrammar, 'aa');
    add(
      id: 'analysis-conflicts',
      algorithm: 'll1-lr1-conflict-analysis',
      property: 'conflicts.typed',
      expected: GrammarCertificationOutcome.conflict,
      actual: llConflict.isSuccess &&
              llConflict.data!.value.typedConflicts.isNotEmpty &&
              lrConflict.outcome == LR1ParseOutcome.conflict
          ? GrammarCertificationOutcome.conflict
          : GrammarCertificationOutcome.violation,
      evidence: {
        'llConflicts': llConflict.data?.value.typedConflicts.length ?? 0,
        'lrOutcome': lrConflict.outcome.name,
      },
    );

    final ambiguity = GrammarAnalyzer.detectAmbiguity(conflictGrammar);
    final ambiguityNotes = ambiguity.data?.structuredNotes ?? const [];
    add(
      id: 'analysis-ambiguity-incomplete',
      algorithm: 'ambiguity-heuristic',
      property: 'ambiguity.incompleteness-exposed',
      expected: GrammarCertificationOutcome.verified,
      actual: ambiguity.isSuccess &&
              ambiguity.data!.value == false &&
              ambiguityNotes.any(
                (note) =>
                    note.stableCode ==
                    'grammar.ambiguity.non-ll1-does-not-imply-ambiguity',
              )
          ? GrammarCertificationOutcome.verified
          : GrammarCertificationOutcome.violation,
      evidence: {
        'appearsLl1': ambiguity.data?.value,
        'structuredNotes': [
          for (final note in ambiguityNotes) note.toJson(),
        ],
      },
    );

    final recursive = _leftRecursiveGrammar(seed);
    final recursiveSourceJson =
        canonicalJsonEncode(_semanticGrammarJson(recursive));
    final recursionResult = GrammarAnalyzer.removeLeftRecursion(recursive);
    final factoringResult = GrammarAnalyzer.leftFactor(_factorGrammar(seed));
    final transformationsOkay = recursionResult.isSuccess &&
        factoringResult.isSuccess &&
        _sameBoundedLanguage(
          recursive,
          recursionResult.data!.value,
          maximumWordLength,
        ) &&
        _sameBoundedLanguage(
          _factorGrammar(seed),
          factoringResult.data!.value,
          maximumWordLength,
        ) &&
        canonicalJsonEncode(_semanticGrammarJson(recursive)) ==
            recursiveSourceJson;
    add(
      id: 'transform-left-recursion-factor',
      algorithm: 'left-recursion-removal-left-factoring',
      property: 'transformation.language-preservation',
      expected: GrammarCertificationOutcome.verified,
      actual: transformationsOkay
          ? GrammarCertificationOutcome.verified
          : GrammarCertificationOutcome.violation,
      evidence: {
        'factorSteps': factoringResult.data?.steps.length ?? 0,
        'recursionSteps': recursionResult.data?.steps.length ?? 0,
      },
    );

    final cnf = GrammarCnfTransformer.toCnf(_nullableGrammar(seed));
    final gnf = GrammarGnfTransformer.toGnf(grammar);
    final collisionSource = _generatedSymbolCollisionGrammar(seed);
    final collisionCnf = CFGToolkit.toCNF(collisionSource);
    final collisionReordered =
        _generatedSymbolCollisionGrammar(seed ^ 0x9e3779b9);
    final collisionCnfReordered = CFGToolkit.toCNF(collisionReordered);
    final normalFormsOkay = cnf.isSuccess &&
        CFGToolkit.isCNF(cnf.data!.grammar) &&
        CFGToolkit.isGNF(gnf.grammar) &&
        _sameBoundedLanguage(
          _nullableGrammar(seed),
          cnf.data!.grammar,
          maximumWordLength,
        ) &&
        _sameBoundedLanguage(grammar, gnf.grammar, maximumWordLength) &&
        collisionCnf.isSuccess &&
        collisionCnfReordered.isSuccess &&
        collisionCnf.data!.productions.map((item) => item.id).toSet().length ==
            collisionCnf.data!.productions.length &&
        collisionCnfReordered.data!.productions
                .map((item) => item.id)
                .toSet()
                .length ==
            collisionCnfReordered.data!.productions.length &&
        collisionCnf.data!.terminals
            .intersection(collisionCnf.data!.nonterminals)
            .isEmpty &&
        _sameBoundedLanguage(
          collisionSource,
          collisionCnf.data!,
          maximumWordLength,
        ) &&
        _sameBoundedLanguage(
          collisionCnf.data!,
          collisionCnfReordered.data!,
          maximumWordLength,
        ) &&
        sourceJson == canonicalJsonEncode(_semanticGrammarJson(grammar));
    add(
      id: 'transform-cnf-gnf',
      algorithm: 'cnf-gnf-transformers',
      property: 'normal-form.language-preservation',
      expected: GrammarCertificationOutcome.verified,
      actual: normalFormsOkay
          ? GrammarCertificationOutcome.verified
          : GrammarCertificationOutcome.violation,
      evidence: {
        'cnfIsNormal': cnf.isSuccess && CFGToolkit.isCNF(cnf.data!.grammar),
        'cnfPreservesLanguage': cnf.isSuccess &&
            _sameBoundedLanguage(
              _nullableGrammar(seed),
              cnf.data!.grammar,
              maximumWordLength,
            ),
        'cnfDiagnostics':
            cnf.data?.diagnostics.map((item) => item.code).toList() ?? const [],
        'gnfIsNormal': CFGToolkit.isGNF(gnf.grammar),
        'gnfPreservesLanguage':
            _sameBoundedLanguage(grammar, gnf.grammar, maximumWordLength),
        'gnfDiagnostics': gnf.diagnostics.map((item) => item.code).toList(),
        'collisionIdsUnique': collisionCnf.isSuccess &&
            collisionCnf.data!.productions
                    .map((item) => item.id)
                    .toSet()
                    .length ==
                collisionCnf.data!.productions.length,
        'reorderedTransformPreservesLanguage': collisionCnf.isSuccess &&
            collisionCnfReordered.isSuccess &&
            _sameBoundedLanguage(
              collisionCnf.data!,
              collisionCnfReordered.data!,
              maximumWordLength,
            ),
        'sourceUnchanged':
            sourceJson == canonicalJsonEncode(_semanticGrammarJson(grammar)),
      },
    );

    final reduced = CFGToolkit.reduce(structural);
    final reducedAgain =
        reduced.isSuccess ? CFGToolkit.reduce(reduced.data!) : null;
    add(
      id: 'transform-reduce-useless-idempotent',
      algorithm: 'cfg-reduction',
      property: 'reduction.useless-language-and-idempotence',
      expected: GrammarCertificationOutcome.verified,
      actual: reduced.isSuccess &&
              reducedAgain!.isSuccess &&
              !reduced.data!.nonterminals.contains('U') &&
              canonicalJsonEncode(_semanticGrammarJson(reduced.data!)) ==
                  canonicalJsonEncode(
                    _semanticGrammarJson(reducedAgain.data!),
                  ) &&
              _sameBoundedLanguage(
                structural,
                reduced.data!,
                maximumWordLength,
              )
          ? GrammarCertificationOutcome.verified
          : GrammarCertificationOutcome.violation,
      evidence: {
        'idempotent': reduced.isSuccess &&
            reducedAgain!.isSuccess &&
            canonicalJsonEncode(_semanticGrammarJson(reduced.data!)) ==
                canonicalJsonEncode(_semanticGrammarJson(reducedAgain.data!)),
        'languagePreserved': reduced.isSuccess &&
            _sameBoundedLanguage(
              structural,
              reduced.data!,
              maximumWordLength,
            ),
        'remainingNonterminals': _sortedNullable(reduced.data?.nonterminals),
      },
    );

    final tokenizerGrammar = _tokenizerHardGrammar(seed);
    final tokenized = GrammarInputTokenizer.tokenize(
      tokenizerGrammar,
      'id 🙂',
    );
    add(
      id: 'parser-tokenizer-unicode-overlap',
      algorithm: 'grammar-input-tokenizer',
      property: 'tokenization.maximal-munch-unicode-whitespace',
      expected: GrammarCertificationOutcome.verified,
      actual: tokenized.isSuccess &&
              tokenized.data!.map((token) => token.lexeme).toList().join('|') ==
                  'id |🙂'
          ? GrammarCertificationOutcome.verified
          : GrammarCertificationOutcome.violation,
      evidence: {
        'tokens': tokenized.data?.map((token) => token.lexeme).toList(),
        'offsets':
            tokenized.data?.map((token) => [token.start, token.end]).toList(),
      },
    );

    final replayShrinkCase = grammarReplayShrinkCounterexample(seed);
    add(
      id: 'parser-replay-shrink-fixture',
      algorithm: 'earley-independent-oracle',
      property: 'parser.replay-shrink',
      expected: GrammarCertificationOutcome.verified,
      actual: replayGrammarCounterexample(replayShrinkCase)
          ? GrammarCertificationOutcome.violation
          : GrammarCertificationOutcome.verified,
      evidence: {
        'grammarId': replayShrinkCase.grammar.id,
        'input': replayShrinkCase.input,
        'oracleOutcome': independentBoundedDerives(
          replayShrinkCase.grammar,
          replayShrinkCase.input,
        ).outcome.name,
        'shrinkDomain': 'grammar-and-input',
      },
    );

    final cykSteps = CYKParser.parseWithSteps(grammar, 'id+id');
    final cykInvalid = CYKParser.parseWithSteps(grammar, '#');
    final cykTimedOut = CYKParser.parseWithSteps(
      grammar,
      'id',
      timeout: Duration.zero,
    );
    add(
      id: 'parser-cyk-steps-typed',
      algorithm: 'cyk-parse-with-steps',
      property: 'parser.steps-and-failures-typed',
      expected: GrammarCertificationOutcome.verified,
      actual: cykSteps.isSuccess &&
              cykSteps.data!.accepted &&
              cykSteps.data!.steps.isNotEmpty &&
              cykInvalid.isSuccess &&
              cykInvalid.data!.outcome ==
                  GrammarParseOutcome.tokenizationFailure &&
              cykTimedOut.isSuccess &&
              cykTimedOut.data!.outcome == GrammarParseOutcome.timedOut
          ? GrammarCertificationOutcome.verified
          : GrammarCertificationOutcome.violation,
      evidence: {
        'invalidOutcome': cykInvalid.data?.outcome.name,
        'stepCount': cykSteps.data?.stepCount,
        'timeoutOutcome': cykTimedOut.data?.outcome.name,
      },
    );

    final autoParse = GrammarParser.parseWithReport(grammar, 'id+id');
    final bruteDispatch = GrammarParser.parseWithReport(
      grammar,
      'id+id',
      strategyHint: ParsingStrategyHint.bruteForce,
    );
    add(
      id: 'parser-dispatch-auto-fallback',
      algorithm: 'grammar-parser-dispatch',
      property: 'dispatch.auto-and-explicit-fallback',
      expected: GrammarCertificationOutcome.verified,
      actual: autoParse.isSuccess &&
              autoParse.data!.accepted &&
              bruteDispatch.isSuccess &&
              bruteDispatch.data!.accepted &&
              GrammarParser.capabilityFor(ParsingStrategyHint.auto).isAvailable
          ? GrammarCertificationOutcome.verified
          : GrammarCertificationOutcome.violation,
      evidence: {
        'auto': autoParse.data?.outcome.name,
        'explicitFallback': bruteDispatch.data?.outcome.name,
        'registeredStrategies': GrammarParser.capabilities
            .map((capability) => capability.strategy.name)
            .toList(),
      },
    );

    final malformedEarley =
        EarleyRecognizer(_emptyLeftSideGrammar()).recognizeWithReport('a');
    final timedOutEarley = EarleyRecognizer(grammar).recognizeWithReport(
      'id',
      timeout: Duration.zero,
    );
    add(
      id: 'parser-earley-malformed-timeout',
      algorithm: 'earley-recognizer',
      property: 'parser.malformed-and-timeout-typed',
      expected: GrammarCertificationOutcome.verified,
      actual: malformedEarley.outcome == GrammarParseOutcome.invalidInput &&
              timedOutEarley.outcome == GrammarParseOutcome.timedOut
          ? GrammarCertificationOutcome.verified
          : GrammarCertificationOutcome.violation,
      evidence: {
        'malformed': malformedEarley.outcome.name,
        'timeout': timedOutEarley.outcome.name,
      },
    );

    final lrOnly = _lr1NotLl1Grammar(seed);
    final lrOnlyLl = GrammarAnalyzer.buildLL1ParseTable(lrOnly);
    final lrOnlyParse = LR1Parser.parse(lrOnly, 'da');
    add(
      id: 'analysis-ll1-lr1-boundary',
      algorithm: 'll1-canonical-lr1-capability-boundary',
      property: 'classification.lr1-not-ll1',
      expected: GrammarCertificationOutcome.verified,
      actual: lrOnlyLl.isSuccess &&
              lrOnlyLl.data!.value.typedConflicts.isNotEmpty &&
              lrOnlyParse.outcome == LR1ParseOutcome.accepted
          ? GrammarCertificationOutcome.verified
          : GrammarCertificationOutcome.violation,
      evidence: {
        'll1Conflicts': lrOnlyLl.data?.value.typedConflicts.length,
        'lr1Outcome': lrOnlyParse.outcome.name,
        'slrRationale':
            'SLR is a serialized ParseType only; no SLR parser entrypoint exists.',
      },
    );

    final ambiguousBrute = BruteForceCFGParser.search(
      conflictGrammar,
      'aaa',
      mode: BruteForceDerivationMode.allPositions,
      limits: const BruteForceSearchLimits(resultCap: 3),
    );
    add(
      id: 'parser-ambiguity-multiple-trees',
      algorithm: 'brute-force-all-positions',
      property: 'ambiguity.multiple-derivation-witnesses',
      expected: GrammarCertificationOutcome.verified,
      actual: ambiguousBrute.accepted && ambiguousBrute.witnessCount > 1
          ? GrammarCertificationOutcome.verified
          : GrammarCertificationOutcome.violation,
      evidence: {
        'outcome': ambiguousBrute.outcome.name,
        'witnessCount': ambiguousBrute.witnessCount,
      },
    );

    // ignore: deprecated_member_use_from_same_package
    final directRecursion =
        GrammarAnalyzer.removeDirectLeftRecursion(recursive);
    add(
      id: 'transform-direct-left-recursion-entrypoint',
      algorithm: 'legacy-direct-left-recursion-entrypoint',
      property: 'transformation.deprecated-dispatch-equivalence',
      expected: GrammarCertificationOutcome.verified,
      actual: directRecursion.isSuccess &&
              recursionResult.isSuccess &&
              _sameBoundedLanguage(
                directRecursion.data!.value,
                recursionResult.data!.value,
                maximumWordLength,
              )
          ? GrammarCertificationOutcome.verified
          : GrammarCertificationOutcome.violation,
      evidence: {
        'directSteps': directRecursion.data?.steps.length,
        'replacement': 'GrammarAnalyzer.removeLeftRecursion',
      },
    );

    for (final input in ['', 'id', 'id+id', 'id+id+id', '+id']) {
      final oracle = independentBoundedDerives(grammar, input);
      final expected = switch (oracle.outcome) {
        IndependentDerivationOutcome.accepted =>
          GrammarCertificationOutcome.accepted,
        IndependentDerivationOutcome.rejected =>
          GrammarCertificationOutcome.rejected,
        IndependentDerivationOutcome.boundedUnknown =>
          GrammarCertificationOutcome.boundedUnknown,
        IndependentDerivationOutcome.tokenizationFailure =>
          GrammarCertificationOutcome.invalid,
      };
      final earley = EarleyRecognizer(grammar).recognizeWithReport(input);
      final cyk = CYKParser.parse(grammar, input);
      final ll = GrammarParser.parseWithReport(
        grammar,
        input,
        strategyHint: ParsingStrategyHint.ll,
      );
      final lr = LR1Parser.parse(grammar, input);
      final recursiveDescent =
          SimpleRecursiveDescentParser(grammar).parse(input);
      final brute = BruteForceCFGParser.search(
        grammar,
        input,
        limits: const BruteForceSearchLimits(
          maxDepth: 12,
          maxExploredNodes: 5000,
          maxRetainedStates: 5000,
          maxFrontierSize: 1000,
          maxSymbolCount: 24,
          timeLimit: Duration(seconds: 1),
        ),
      );
      final outcomes = <String, bool>{
        'earley': earley.accepted,
        'cyk': cyk.isSuccess && cyk.data!.accepted,
        'll1': ll.isSuccess && ll.data!.accepted,
        'lr1': lr.accepted,
        'recursive-descent':
            recursiveDescent.isSuccess && recursiveDescent.data!.accepted,
        'brute-force': brute.accepted,
      };
      for (final entry in outcomes.entries) {
        final assessment = assessGrammarParserDifferential(
          oracle,
          parserAccepted: entry.value,
        );
        add(
          id: 'parser-${entry.key}-${_safeWord(input)}',
          algorithm: entry.key,
          property: 'parser.differential-oracle',
          expected: expected,
          actual: assessment.outcome,
          definitive: assessment.definitive,
          evidence: {
            'input': input,
            'oracleExplored': oracle.exploredForms,
            'oracleOutcome': oracle.outcome.name,
            'parserAccepted': entry.value,
          },
        );
      }
      if (brute.accepted && brute.witnesses.isNotEmpty) {
        final terminalYield = _terminalTreeYield(
          brute.witnesses.first.tree.root,
          grammar.terminals,
        );
        add(
          id: 'trace-brute-${_safeWord(input)}',
          algorithm: 'brute-force-derivation-trace',
          property: 'trace.replay-yield',
          expected: GrammarCertificationOutcome.verified,
          actual: terminalYield == input
              ? GrammarCertificationOutcome.verified
              : GrammarCertificationOutcome.violation,
          evidence: {'input': input, 'yield': terminalYield},
        );
      }
    }

    final lrBuilt = LR1Parser.build(grammar).construction!;
    final stale = LR1Parser.parse(
      grammar.copyWith(name: '${grammar.name}-edited', productions: {
        ...grammar.productions,
        Production(
          id: 'seed-$seed-stale',
          leftSide: const ['Tail'],
          rightSide: const ['+', 'id'],
          order: 99,
        ),
      }),
      'id',
      construction: lrBuilt,
    );
    add(
      id: 'lr1-stale-result',
      algorithm: 'canonical-lr1',
      property: 'stale-result.rejected',
      expected: GrammarCertificationOutcome.stale,
      actual: stale.outcome == LR1ParseOutcome.tableConstructionFailure
          ? GrammarCertificationOutcome.stale
          : GrammarCertificationOutcome.violation,
      evidence: {'outcome': stale.outcome.name},
    );

    final phrase = LegacyContextFreeGrammarAdapter.adapt(
      grammar,
      revision: LegacyContextFreeGrammarAdapter.sourceRevision(grammar),
    );
    final target =
        LegacyContextFreeGrammarAdapter.tokenizeTarget(grammar, 'id').data!;
    final initialUserSession = UserDerivationSession.start(
      grammar: phrase,
      target: target,
      mode: UserDerivationMode.leftmost,
    ).session!;
    final hintCancellation = UserDerivationHintCancellationToken()..cancel();
    final hintCancelled = await UserDerivationHintSearch.run(
      session: initialUserSession,
      grammar: phrase,
      cancellationToken: hintCancellation,
    );
    final hintBounded = await UserDerivationHintSearch.run(
      session: initialUserSession,
      grammar: phrase,
      limits: const UserDerivationHintLimits(maxDepth: 0),
    );

    final llCancelled = GrammarParser.parseLL1(
      grammar,
      'id',
      isCancelled: () => true,
    );
    final llTimedOut = GrammarParser.parseLL1(
      grammar,
      'id',
      timeout: Duration.zero,
    );
    final llStepBounded = GrammarParser.parseLL1(
      grammar,
      'id',
      maxSteps: 0,
    );
    final lrCancelled = LR1Parser.parse(grammar, 'id', isCancelled: () => true);
    final lrConstructionTimedOut = LR1Parser.build(
      grammar,
      timeout: Duration.zero,
    );
    final lrConstructionItemBounded = LR1Parser.build(grammar, maxItems: 0);
    final lrConstructionStateBounded = LR1Parser.build(grammar, maxStates: 1);
    final lrParseTimedOut = LR1Parser.parse(
      grammar,
      'id',
      construction: lrBuilt,
      timeout: Duration.zero,
    );
    final lrParseStepBounded = LR1Parser.parse(
      grammar,
      'id',
      construction: lrBuilt,
      maxSteps: 0,
    );
    final recursiveTimedOut = SimpleRecursiveDescentParser(grammar)
        .parseWithReport('id+id', timeout: Duration.zero);
    final bruteCancellation = BruteForceCancellationToken()..cancel();
    final bruteCancelled = BruteForceCFGParser.search(
      grammar,
      'id',
      cancellationToken: bruteCancellation,
    );
    final bruteLimitGrammar = _bruteLimitGrammar(seed);
    BruteForceParseResult bruteLimit(BruteForceSearchLimits limits) =>
        BruteForceCFGParser.search(
          bruteLimitGrammar,
          'a',
          limits: limits,
        );
    final bruteLimits = <BruteForceSearchLimit, BruteForceParseResult>{
      BruteForceSearchLimit.depth:
          bruteLimit(const BruteForceSearchLimits(maxDepth: 1)),
      BruteForceSearchLimit.exploredNodes:
          bruteLimit(const BruteForceSearchLimits(maxExploredNodes: 1)),
      BruteForceSearchLimit.retainedStates:
          bruteLimit(const BruteForceSearchLimits(maxRetainedStates: 1)),
      BruteForceSearchLimit.symbolCount:
          bruteLimit(const BruteForceSearchLimits(maxSymbolCount: 0)),
      BruteForceSearchLimit.time:
          bruteLimit(const BruteForceSearchLimits(timeLimit: Duration.zero)),
      BruteForceSearchLimit.frontier: BruteForceCFGParser.search(
        _bruteBranchingLimitGrammar(seed),
        'b',
        limits: const BruteForceSearchLimits(maxFrontierSize: 1),
      ),
    };
    final bruteResultCapped = BruteForceCFGParser.search(
      _ambiguousGrammar(seed),
      'aaa',
      mode: BruteForceDerivationMode.allPositions,
      limits: const BruteForceSearchLimits(resultCap: 1),
    );
    final bruteBounded = BruteForceCFGParser.search(
      _growthGrammar(seed),
      'id',
      limits: const BruteForceSearchLimits(
        maxDepth: 0,
        maxExploredNodes: 1,
        maxRetainedStates: 2,
        maxFrontierSize: 1,
        maxSymbolCount: 4,
      ),
    );
    add(
      id: 'parser-cancellation',
      algorithm: 'lr1-brute-cancellation',
      property: 'limits.cancellation-typed',
      expected: GrammarCertificationOutcome.cancelled,
      actual: lrCancelled.outcome == LR1ParseOutcome.cancelled &&
              bruteCancelled.outcome == BruteForceParseOutcome.cancelled &&
              llCancelled.isSuccess &&
              llCancelled.data!.outcome == GrammarParseOutcome.cancelled &&
              hintCancelled.outcome == UserDerivationHintOutcome.cancelled
          ? GrammarCertificationOutcome.cancelled
          : GrammarCertificationOutcome.violation,
      evidence: {
        'brute': bruteCancelled.outcome.name,
        'hint': hintCancelled.outcome.name,
        'll1': llCancelled.data?.outcome.name,
        'lr1': lrCancelled.outcome.name,
      },
    );
    add(
      id: 'parser-bounds',
      algorithm: 'lr1-brute-resource-limits',
      property: 'limits.bounded-unknown-typed',
      expected: GrammarCertificationOutcome.boundedUnknown,
      actual: llTimedOut.isSuccess &&
              llTimedOut.data!.outcome == GrammarParseOutcome.timedOut &&
              llStepBounded.isSuccess &&
              llStepBounded.data!.outcome == GrammarParseOutcome.stepLimit &&
              lrConstructionTimedOut.outcome ==
                  LR1ConstructionOutcome.timeLimit &&
              lrConstructionItemBounded.outcome ==
                  LR1ConstructionOutcome.itemLimit &&
              lrConstructionStateBounded.outcome ==
                  LR1ConstructionOutcome.stateLimit &&
              lrParseTimedOut.outcome == LR1ParseOutcome.timedOut &&
              lrParseStepBounded.outcome == LR1ParseOutcome.resourceLimit &&
              bruteLimits.entries.every(
                (entry) =>
                    entry.value.outcome ==
                        BruteForceParseOutcome.boundedUnknown &&
                    entry.value.limit == entry.key,
              ) &&
              bruteResultCapped.accepted &&
              bruteResultCapped.witnessCount == 1 &&
              bruteBounded.outcome == BruteForceParseOutcome.boundedUnknown &&
              hintBounded.outcome == UserDerivationHintOutcome.boundedUnknown &&
              hintBounded.limit == UserDerivationHintLimit.depth
          ? GrammarCertificationOutcome.boundedUnknown
          : GrammarCertificationOutcome.violation,
      evidence: {
        'brute': bruteBounded.outcome.name,
        'bruteLimits': {
          for (final entry in bruteLimits.entries)
            entry.key.name: entry.value.outcome.name,
        },
        'bruteResultCap': bruteResultCapped.witnessCount,
        'hint': hintBounded.outcome.name,
        'hintLimit': hintBounded.limit?.name,
        'll1Steps': llStepBounded.data?.outcome.name,
        'll1Timeout': llTimedOut.data?.outcome.name,
        'lr1ConstructionItems': lrConstructionItemBounded.outcome.name,
        'lr1ConstructionStates': lrConstructionStateBounded.outcome.name,
        'lr1ConstructionTime': lrConstructionTimedOut.outcome.name,
        'lr1ParseSteps': lrParseStepBounded.outcome.name,
        'lr1ParseTime': lrParseTimedOut.outcome.name,
      },
    );
    add(
      id: 'parser-recursive-timeout',
      algorithm: 'recursive-descent',
      property: 'limits.timeout-typed',
      expected: GrammarCertificationOutcome.boundedUnknown,
      actual: recursiveTimedOut.isSuccess &&
              recursiveTimedOut.data!.outcome == GrammarParseOutcome.timedOut
          ? GrammarCertificationOutcome.boundedUnknown
          : GrammarCertificationOutcome.violation,
      evidence: {
        'outcome': recursiveTimedOut.data?.outcome.name,
      },
    );

    final derivationHint = await UserDerivationHintSearch.run(
      session: initialUserSession,
      grammar: phrase,
    );
    var userSession = initialUserSession;
    userSession = userSession
        .apply(grammar: phrase, productionId: 's-id-tail', startIndex: 0)
        .session;
    userSession = userSession
        .apply(grammar: phrase, productionId: 'tail-empty', startIndex: 1)
        .session;
    final editedPhrase = ContextFreeGrammar(
      id: phrase.id,
      name: phrase.name,
      revision: phrase.revision + 1,
      terminals: phrase.terminals,
      nonterminals: phrase.nonterminals,
      startSymbol: phrase.startSymbol,
      productions: phrase.productions,
    );
    final restored = UserDerivationSession.restore(
      userSession.toJson(),
      grammar: editedPhrase,
    );
    add(
      id: 'user-derivation-trace-stale',
      algorithm: 'user-controlled-derivation',
      property: 'derivation.trace-and-stale-revision',
      expected: GrammarCertificationOutcome.stale,
      actual: userSession.status == UserDerivationStatus.success &&
              derivationHint.outcome == UserDerivationHintOutcome.suggested &&
              derivationHint.suggestion?.production.id == 's-id-tail' &&
              restored.session?.status == UserDerivationStatus.invalidated
          ? GrammarCertificationOutcome.stale
          : GrammarCertificationOutcome.violation,
      evidence: {
        'steps': userSession.steps.map((step) => step.productionId).toList(),
        'hintOutcome': derivationHint.outcome.name,
        'hintProduction': derivationHint.suggestion?.production.id,
        'status': restored.session?.status.name,
      },
    );

    final unrestricted = _unrestrictedGrammar(seed);
    final bounded = await BoundedDerivationSearch.run(
      grammar: unrestricted,
      input: GrammarSymbolSequence(const [TerminalGrammarSymbol('a')]),
      limits: const DerivationSearchLimits(maxExpandedForms: 0),
    );
    final cancelledToken = DerivationCancellationToken()..cancel();
    final cancelled = await BoundedDerivationSearch.run(
      grammar: unrestricted,
      input: GrammarSymbolSequence(const [TerminalGrammarSymbol('a')]),
      cancellationToken: cancelledToken,
    );
    final unrestrictedAccepted = await BoundedDerivationSearch.run(
      grammar: unrestricted,
      input: GrammarSymbolSequence(const [
        TerminalGrammarSymbol('b'),
        TerminalGrammarSymbol('a'),
      ]),
    );
    add(
      id: 'unrestricted-bounds-cancellation',
      algorithm: 'unrestricted-bounded-derivation',
      property: 'unrestricted.typed-limits',
      expected: GrammarCertificationOutcome.verified,
      actual: bounded is DerivationBoundedUnknown &&
              cancelled is DerivationCancelled &&
              unrestrictedAccepted is DerivationAccepted &&
              unrestrictedAccepted.witness.any(
                (application) => application.production.id == 'swap-ab',
              )
          ? GrammarCertificationOutcome.verified
          : GrammarCertificationOutcome.violation,
      evidence: {
        'bounded': bounded.runtimeType.toString(),
        'cancelled': cancelled.runtimeType.toString(),
        'multiLhs': unrestrictedAccepted.runtimeType.toString(),
        'multiLhsWitness': unrestrictedAccepted is DerivationAccepted
            ? unrestrictedAccepted.witness
                .map((application) => application.production.id)
                .toList()
            : const [],
      },
    );

    final regular = _regularGrammar(seed);
    final fsaResult = GrammarToFSAConverter.convert(regular);
    final roundTrip = fsaResult.isSuccess
        ? FSAToGrammarConverter.convert(fsaResult.data!)
        : null;
    final conversionOkay = fsaResult.isSuccess &&
        roundTrip != null &&
        _sameBoundedLanguage(regular, roundTrip, maximumWordLength);
    add(
      id: 'conversion-regular-fsa-roundtrip',
      algorithm: 'grammar-fsa-conversions',
      property: 'conversion.bounded-language-roundtrip',
      expected: GrammarCertificationOutcome.verified,
      actual: conversionOkay
          ? GrammarCertificationOutcome.verified
          : GrammarCertificationOutcome.violation,
      evidence: {'states': fsaResult.data?.states.length ?? 0},
    );

    final llPda = CfgToPdaConverter.buildLl(grammar, sourceRevision: seed);
    final lrPda = CfgToPdaConverter.buildLr(grammar, sourceRevision: seed);
    final llDifferential = CfgToPdaDifferentialChecker.check(
      grammar,
      llPda,
      const ['', 'id', 'id+id', '+id'],
    );
    final lrDifferential = CfgToPdaDifferentialChecker.check(
      grammar,
      lrPda,
      const ['', 'id', 'id+id', '+id'],
    );
    add(
      id: 'conversion-cfg-pda',
      algorithm: 'cfg-to-pda-ll-lr',
      property: 'conversion.pda-valid-and-source-immutable',
      expected: GrammarCertificationOutcome.verified,
      actual: llPda.outcome == CfgToPdaConstructionOutcome.completed &&
              lrPda.outcome == CfgToPdaConstructionOutcome.completed &&
              llPda.pda!.validate().isEmpty &&
              lrPda.pda!.validate().isEmpty &&
              !llDifferential.hasMismatch &&
              !lrDifferential.hasMismatch &&
              sourceJson == canonicalJsonEncode(_semanticGrammarJson(grammar))
          ? GrammarCertificationOutcome.verified
          : GrammarCertificationOutcome.violation,
      evidence: {
        'll': llPda.outcome.name,
        'llDifferential': llDifferential.samples
            .map((sample) => sample.outcome.name)
            .toList(),
        'lr': lrPda.outcome.name,
        'lrDifferential': lrDifferential.samples
            .map((sample) => sample.outcome.name)
            .toList(),
      },
    );

    final pda = PDA.singleState(
      id: 'grammar-hard-edge-pda-$seed',
      name: 'Grammar hard-edge PDA',
      stateId: 'q0',
      stateLabel: 'q0',
      position: Vector2.zero(),
      isInitial: true,
      isAccepting: true,
    );
    final pdaCfg = PDAtoCFGConverter.convert(pda);
    final pdaCancelled = PDAtoCFGConverter.convert(
      pda,
      isCancelled: () => true,
    );
    add(
      id: 'conversion-pda-cfg',
      algorithm: 'pda-to-cfg',
      property: 'conversion.structure-and-cancellation',
      expected: GrammarCertificationOutcome.verified,
      actual: pdaCfg.isSuccess &&
              pdaCfg.data!.grammar.productions.isNotEmpty &&
              pdaCancelled.isFailure &&
              pdaCancelled.error == PDAtoCFGConverter.cancellationError
          ? GrammarCertificationOutcome.verified
          : GrammarCertificationOutcome.violation,
      evidence: {
        'cancelled': pdaCancelled.error,
        'productions': pdaCfg.data?.grammar.productions.length,
      },
    );

    final tm = TM.singleState(
      id: 'grammar-hard-edge-tm-$seed',
      name: 'Grammar hard-edge TM',
      stateId: 'q0',
      stateLabel: 'q0',
      position: Vector2.zero(),
      isInitial: true,
      isAccepting: true,
      tapeAlphabet: const {'B'},
    );
    final tmGrammar = TMToGrammarConverter.build(
      tm,
      sourceRevision: seed,
      maxProductions: 1,
    );
    final tmGrammarCompleted = TMToGrammarConverter.build(
      tm,
      sourceRevision: seed,
    );
    final tmDifferential = tmGrammarCompleted.isCompleted
        ? await TMToGrammarDifferentialChecker.check(
            tm,
            tmGrammarCompleted,
            const [<String>[]],
          )
        : null;
    add(
      id: 'conversion-tm-unrestricted-grammar',
      algorithm: 'tm-to-unrestricted-grammar',
      property: 'conversion.construction-limit-typed',
      expected: GrammarCertificationOutcome.boundedUnknown,
      actual: tmGrammar.outcome == TMToGrammarOutcome.constructionLimit &&
              tmGrammarCompleted.isCompleted &&
              tmDifferential != null &&
              !tmDifferential.hasMismatch
          ? GrammarCertificationOutcome.boundedUnknown
          : GrammarCertificationOutcome.violation,
      evidence: {
        'outcome': tmGrammar.outcome.name,
        'completedOutcome': tmGrammarCompleted.outcome.name,
        'differential': tmDifferential?.samples
            .map((sample) => sample.outcome.name)
            .toList(),
        'productions': tmGrammar.grammar?.productions.length,
        'provenance': tmGrammar.productionProvenance.length,
      },
    );

    return records;
  }
}

enum IndependentDerivationOutcome {
  accepted,
  rejected,
  boundedUnknown,
  tokenizationFailure,
}

final class IndependentDerivationResult {
  const IndependentDerivationResult({
    required this.outcome,
    required this.exploredForms,
  });

  final IndependentDerivationOutcome outcome;
  final int exploredForms;

  bool get accepted => outcome == IndependentDerivationOutcome.accepted;

  bool get bounded => outcome == IndependentDerivationOutcome.boundedUnknown;

  bool get definitive =>
      outcome == IndependentDerivationOutcome.accepted ||
      outcome == IndependentDerivationOutcome.rejected;
}

final class GrammarParserDifferentialAssessment {
  const GrammarParserDifferentialAssessment({
    required this.outcome,
    required this.definitive,
  });

  final GrammarCertificationOutcome outcome;
  final bool definitive;
}

GrammarParserDifferentialAssessment assessGrammarParserDifferential(
  IndependentDerivationResult oracle, {
  required bool parserAccepted,
}) {
  return switch (oracle.outcome) {
    IndependentDerivationOutcome.accepted =>
      GrammarParserDifferentialAssessment(
        outcome: parserAccepted
            ? GrammarCertificationOutcome.accepted
            : GrammarCertificationOutcome.rejected,
        definitive: true,
      ),
    IndependentDerivationOutcome.rejected =>
      GrammarParserDifferentialAssessment(
        outcome: parserAccepted
            ? GrammarCertificationOutcome.accepted
            : GrammarCertificationOutcome.rejected,
        definitive: true,
      ),
    IndependentDerivationOutcome.boundedUnknown =>
      const GrammarParserDifferentialAssessment(
        outcome: GrammarCertificationOutcome.boundedUnknown,
        definitive: false,
      ),
    IndependentDerivationOutcome.tokenizationFailure =>
      const GrammarParserDifferentialAssessment(
        outcome: GrammarCertificationOutcome.invalid,
        definitive: false,
      ),
  };
}

IndependentDerivationResult independentBoundedDerives(
  Grammar grammar,
  String input, {
  int maxDepth = 12,
  int maxForms = 10000,
}) {
  final targetResult = _tokenizeDeclaredTerminals(grammar, input);
  if (targetResult == null) {
    return const IndependentDerivationResult(
      outcome: IndependentDerivationOutcome.tokenizationFailure,
      exploredForms: 0,
    );
  }
  final productions = grammar.productions.toList()
    ..sort((left, right) {
      final order = left.order.compareTo(right.order);
      return order != 0 ? order : left.id.compareTo(right.id);
    });
  final queue = <(List<String>, int)>[
    ([grammar.startSymbol], 0)
  ];
  final visited = <String>{jsonEncode(queue.first.$1)};
  var cursor = 0;
  var explored = 0;
  var bounded = false;
  while (cursor < queue.length) {
    if (explored >= maxForms) {
      bounded = true;
      break;
    }
    final (form, depth) = queue[cursor++];
    explored++;
    if (_listEquals(form, targetResult)) {
      return IndependentDerivationResult(
        outcome: IndependentDerivationOutcome.accepted,
        exploredForms: explored,
      );
    }
    if (depth >= maxDepth) {
      if (form.any(grammar.nonterminals.contains)) bounded = true;
      continue;
    }
    final nonterminalIndex = form.indexWhere(grammar.nonterminals.contains);
    if (nonterminalIndex < 0) continue;
    final terminalCount = form.where(grammar.terminals.contains).length;
    if (terminalCount > targetResult.length) continue;
    for (final production in productions.where(
      (production) =>
          production.leftSide.length == 1 &&
          production.leftSide.single == form[nonterminalIndex],
    )) {
      final replacement =
          production.isLambda ? const <String>[] : production.rightSide;
      final next = <String>[
        ...form.take(nonterminalIndex),
        ...replacement,
        ...form.skip(nonterminalIndex + 1),
      ];
      if (next.length > targetResult.length + maxDepth) continue;
      final key = jsonEncode(next);
      if (visited.add(key)) queue.add((next, depth + 1));
    }
  }
  return IndependentDerivationResult(
    outcome: bounded
        ? IndependentDerivationOutcome.boundedUnknown
        : IndependentDerivationOutcome.rejected,
    exploredForms: explored,
  );
}

final class GrammarCounterexample {
  const GrammarCounterexample({
    required this.grammar,
    required this.input,
    required this.seed,
    required this.property,
  });

  final Grammar grammar;
  final String input;
  final int seed;
  final String property;

  Map<String, Object?> toJson() => {
        'grammar': grammar.toJson(),
        'input': input,
        'property': property,
        'schemaVersion': 1,
        'seed': seed,
      };

  factory GrammarCounterexample.fromJson(Map<String, Object?> json) {
    const keys = {'grammar', 'input', 'property', 'schemaVersion', 'seed'};
    if (json.keys.toSet().difference(keys).isNotEmpty ||
        keys.difference(json.keys.toSet()).isNotEmpty ||
        json['schemaVersion'] != 1 ||
        json['grammar'] is! Map ||
        json['input'] is! String ||
        json['property'] is! String ||
        json['seed'] is! int) {
      throw const FormatException('Invalid grammar counterexample schema.');
    }
    return GrammarCounterexample(
      grammar:
          Grammar.fromJson(Map<String, dynamic>.from(json['grammar']! as Map)),
      input: json['input']! as String,
      seed: json['seed']! as int,
      property: json['property']! as String,
    );
  }
}

GrammarCounterexample grammarReplayShrinkCounterexample(int seed) =>
    GrammarCounterexample(
      grammar: _expressionGrammar(seed),
      input: 'id+id',
      seed: seed,
      property: 'parser.replay-shrink',
    );

bool replayGrammarCounterexample(
  GrammarCounterexample counterexample, {
  bool Function(Grammar grammar, String input)? candidate,
}) {
  final oracle = independentBoundedDerives(
    counterexample.grammar,
    counterexample.input,
  );
  if (!oracle.definitive) return false;
  final observed = candidate?.call(
        counterexample.grammar,
        counterexample.input,
      ) ??
      EarleyRecognizer(counterexample.grammar)
          .recognizeWithReport(counterexample.input)
          .accepted;
  return observed != oracle.accepted;
}

GrammarCounterexample shrinkGrammarCounterexample(
  GrammarCounterexample source, {
  required bool Function(Grammar grammar, String input) candidate,
}) {
  if (!replayGrammarCounterexample(source, candidate: candidate)) {
    throw const FormatException('Counterexample no longer reproduces.');
  }
  var current = source;
  var changed = true;
  while (changed) {
    changed = false;
    final runes = current.input.runes.toList();
    for (var index = runes.length - 1; index >= 0; index--) {
      final candidateInput = String.fromCharCodes([...runes]..removeAt(index));
      final attempt = GrammarCounterexample(
        grammar: current.grammar,
        input: candidateInput,
        seed: source.seed,
        property: source.property,
      );
      if (replayGrammarCounterexample(attempt, candidate: candidate)) {
        current = attempt;
        changed = true;
        break;
      }
    }
    if (changed) continue;

    final productions = current.grammar.productions.toList()
      ..sort((left, right) => right.id.compareTo(left.id));
    if (productions.length <= 1) continue;
    for (final production in productions) {
      final reduced = productions.toSet()..remove(production);
      final attempt = GrammarCounterexample(
        grammar: current.grammar.copyWith(
          productions: reduced,
          modified: current.grammar.modified,
        ),
        input: current.input,
        seed: source.seed,
        property: source.property,
      );
      if (replayGrammarCounterexample(attempt, candidate: candidate)) {
        current = attempt;
        changed = true;
        break;
      }
    }
  }
  return current;
}

final class GrammarMutationResult {
  const GrammarMutationResult({
    required this.id,
    required this.killed,
    required this.witness,
  });

  final String id;
  final bool killed;
  final String witness;

  Map<String, Object?> toJson() => {
        'id': id,
        'status': killed ? 'killed' : 'survived',
        'witness': witness,
      };
}

List<GrammarMutationResult> runGrammarMutationProbes({int seed = 336}) {
  final expression = _expressionGrammar(seed);
  final withoutEpsilon = expression.copyWith(
    productions: expression.productions
        .where((production) => !production.isLambda)
        .toSet(),
    modified: expression.modified,
  );
  final wrongStart = expression.copyWith(
    startSymbol: 'Tail',
    modified: expression.modified,
  );
  final tokenGrammar = _tokenizerHardGrammar(seed);
  final normalTokens = GrammarInputTokenizer.tokenize(tokenGrammar, 'id').data!;
  final shortestTokens = _shortestMatchTokens(tokenGrammar, 'id');
  return [
    GrammarMutationResult(
      id: 'drop-epsilon-production',
      killed:
          EarleyRecognizer(withoutEpsilon).recognizeWithReport('id').accepted !=
              independentBoundedDerives(expression, 'id').accepted,
      witness: 'id',
    ),
    GrammarMutationResult(
      id: 'substitute-start-symbol',
      killed: EarleyRecognizer(wrongStart).recognizeWithReport('id').accepted !=
          independentBoundedDerives(expression, 'id').accepted,
      witness: 'id',
    ),
    GrammarMutationResult(
      id: 'shortest-match-tokenizer',
      killed: normalTokens.map((token) => token.lexeme).join('|') !=
          shortestTokens.join('|'),
      witness: 'id',
    ),
  ];
}

List<String> _shortestMatchTokens(Grammar grammar, String input) {
  final terminals =
      grammar.terminals.where((terminal) => terminal.isNotEmpty).toList()
        ..sort((left, right) {
          final length = left.length.compareTo(right.length);
          return length != 0 ? length : left.compareTo(right);
        });
  final result = <String>[];
  var offset = 0;
  while (offset < input.length) {
    final match = terminals.cast<String?>().firstWhere(
          (terminal) => input.startsWith(terminal!, offset),
          orElse: () => null,
        );
    if (match == null) return const [];
    result.add(match);
    offset += match.length;
  }
  return result;
}

Grammar _expressionGrammar(int seed) => _grammar(
      id: 'grammar-expression-$seed',
      terminals: const {'id', '+'},
      nonterminals: const {'S', 'Tail'},
      start: 'S',
      productions: _shuffledProductions(seed, const [
        Production(
          id: 's-id-tail',
          leftSide: ['S'],
          rightSide: ['id', 'Tail'],
          order: 0,
        ),
        Production(
          id: 'tail-more',
          leftSide: ['Tail'],
          rightSide: ['+', 'id', 'Tail'],
          order: 1,
        ),
        Production(
          id: 'tail-empty',
          leftSide: ['Tail'],
          rightSide: [],
          isLambda: true,
          order: 2,
        ),
      ]),
    );

Grammar _nullableGrammar(int seed) => _grammar(
      id: 'grammar-nullable-$seed',
      terminals: const {'a', 'b'},
      nonterminals: const {'S', 'A', 'B'},
      start: 'S',
      productions: _shuffledProductions(seed, const [
        Production(id: 's-ab', leftSide: ['S'], rightSide: ['A', 'B']),
        Production(id: 'a-a', leftSide: ['A'], rightSide: ['a']),
        Production(
          id: 'a-empty',
          leftSide: ['A'],
          rightSide: [],
          isLambda: true,
        ),
        Production(id: 'b-b', leftSide: ['B'], rightSide: ['b']),
      ]),
    );

Grammar _leftRecursiveGrammar(int seed) => _grammar(
      id: 'grammar-left-recursive-$seed',
      terminals: const {'id', 'plus'},
      nonterminals: const {'E'},
      start: 'E',
      productions: _shuffledProductions(seed, const [
        Production(
            id: 'e-plus', leftSide: ['E'], rightSide: ['E', 'plus', 'id']),
        Production(id: 'e-id', leftSide: ['E'], rightSide: ['id']),
      ]),
    );

Grammar _factorGrammar(int seed) => _grammar(
      id: 'grammar-factor-$seed',
      terminals: const {'a', 'b', 'c'},
      nonterminals: const {'S'},
      start: 'S',
      productions: _shuffledProductions(seed, const [
        Production(id: 's-ab', leftSide: ['S'], rightSide: ['a', 'b']),
        Production(id: 's-ac', leftSide: ['S'], rightSide: ['a', 'c']),
      ]),
    );

Grammar _tokenizerHardGrammar(int seed) => _grammar(
      id: 'grammar-tokenizer-hard-$seed',
      terminals: const {'i', 'id', 'id ', '🙂'},
      nonterminals: const {'S'},
      start: 'S',
      productions: _shuffledProductions(seed, const [
        Production(
          id: 'unicode-sequence',
          leftSide: ['S'],
          rightSide: ['id ', '🙂'],
        ),
        Production(id: 'short-overlap', leftSide: ['S'], rightSide: ['i']),
      ]),
    );

Grammar _emptyLeftSideGrammar() => _grammar(
      id: 'grammar-empty-left-side',
      terminals: const {'a'},
      nonterminals: const {'S'},
      start: 'S',
      productions: {
        const Production(id: 'empty-left', leftSide: [], rightSide: ['a']),
      },
    );

Grammar _lr1NotLl1Grammar(int seed) => _grammar(
      id: 'grammar-lr1-not-ll1-$seed',
      terminals: const {'a', 'b', 'c', 'd'},
      nonterminals: const {'S', 'A', 'B'},
      start: 'S',
      productions: _shuffledProductions(seed, const [
        Production(id: 's-aa', leftSide: ['S'], rightSide: ['A', 'a']),
        Production(id: 's-bac', leftSide: ['S'], rightSide: ['b', 'A', 'c']),
        Production(id: 's-bc', leftSide: ['S'], rightSide: ['B', 'c']),
        Production(id: 's-bba', leftSide: ['S'], rightSide: ['b', 'B', 'a']),
        Production(id: 'a-d', leftSide: ['A'], rightSide: ['d']),
        Production(id: 'b-d', leftSide: ['B'], rightSide: ['d']),
      ]),
    );

Grammar _ambiguousGrammar(int seed) => _grammar(
      id: 'grammar-ambiguous-$seed',
      terminals: {'a'},
      nonterminals: {'S'},
      start: 'S',
      productions: _shuffledProductions(seed, const [
        Production(id: 's-pair', leftSide: ['S'], rightSide: ['S', 'S']),
        Production(id: 's-a', leftSide: ['S'], rightSide: ['a']),
      ]),
    );

Grammar _structuralGrammar(int seed) => _grammar(
      id: 'grammar-structural-$seed',
      terminals: const {'a'},
      nonterminals: const {'S', 'A', 'U', 'V'},
      start: 'S',
      productions: _shuffledProductions(seed, const [
        Production(id: 's-a', leftSide: ['S'], rightSide: ['A']),
        Production(id: 'a-leaf', leftSide: ['A'], rightSide: ['a']),
        Production(id: 'u-v', leftSide: ['U'], rightSide: ['V']),
        Production(id: 'v-u', leftSide: ['V'], rightSide: ['U']),
      ]),
    );

Grammar _generatedSymbolCollisionGrammar(int seed) => _grammar(
      id: 'grammar-generated-symbol-collision-$seed',
      terminals: const {'a', 'b'},
      nonterminals: const {'S', 'N0', 'T0'},
      start: 'S',
      productions: _shuffledProductions(seed, const [
        Production(
          id: 's-mixed',
          leftSide: ['S'],
          rightSide: ['a', 'N0', 'T0'],
        ),
        Production(id: 'm_a', leftSide: ['N0'], rightSide: ['a']),
        Production(
          id: 's-mixed_b_end',
          leftSide: ['T0'],
          rightSide: ['b'],
        ),
      ]),
    );

Grammar _growthGrammar(int seed) => _grammar(
      id: 'grammar-growth-$seed',
      terminals: const {'id'},
      nonterminals: const {'S'},
      start: 'S',
      productions: _shuffledProductions(seed, const [
        Production(id: 's-grow', leftSide: ['S'], rightSide: ['S', 'S']),
        Production(id: 's-id', leftSide: ['S'], rightSide: ['id']),
      ]),
    );

Grammar _bruteLimitGrammar(int seed) => _grammar(
      id: 'grammar-brute-limits-$seed',
      terminals: const {'a'},
      nonterminals: const {'S', 'A'},
      start: 'S',
      productions: _shuffledProductions(seed, const [
        Production(id: 'to-a', leftSide: ['S'], rightSide: ['A']),
        Production(id: 'leaf', leftSide: ['A'], rightSide: ['a']),
      ]),
    );

Grammar _bruteBranchingLimitGrammar(int seed) => _grammar(
      id: 'grammar-brute-frontier-$seed',
      terminals: const {'a', 'b'},
      nonterminals: const {'S', 'A', 'B'},
      start: 'S',
      productions: _shuffledProductions(seed, const [
        Production(id: 'one', leftSide: ['S'], rightSide: ['A']),
        Production(id: 'two', leftSide: ['S'], rightSide: ['B']),
        Production(id: 'a-leaf', leftSide: ['A'], rightSide: ['a']),
        Production(id: 'b-leaf', leftSide: ['B'], rightSide: ['a']),
      ]),
    );

Grammar _regularGrammar(int seed) => _grammar(
      id: 'grammar-regular-$seed',
      terminals: const {'a'},
      nonterminals: const {'S'},
      start: 'S',
      type: GrammarType.regular,
      productions: _shuffledProductions(seed, const [
        Production(id: 's-loop', leftSide: ['S'], rightSide: ['a', 'S']),
        Production(
          id: 's-empty',
          leftSide: ['S'],
          rightSide: [],
          isLambda: true,
        ),
      ]),
    );

Grammar _malformedGrammar() => _grammar(
      id: 'grammar-malformed',
      terminals: const {'a'},
      nonterminals: const {'A'},
      start: 'S',
      productions: {
        const Production(id: 'bad', leftSide: ['A'], rightSide: ['missing']),
      },
    );

UnrestrictedGrammar _unrestrictedGrammar(int seed) => UnrestrictedGrammar(
      id: 'grammar-unrestricted-$seed',
      name: 'Unrestricted hard edge',
      revision: seed,
      terminals: {
        const TerminalGrammarSymbol('a'),
        const TerminalGrammarSymbol('b'),
      },
      nonterminals: {
        const NonterminalGrammarSymbol('S'),
        const NonterminalGrammarSymbol('A'),
        const NonterminalGrammarSymbol('B'),
      },
      startSymbol: const NonterminalGrammarSymbol('S'),
      productions: {
        PhraseStructureProduction(
          id: 'start-ab',
          left: GrammarSymbolSequence(const [NonterminalGrammarSymbol('S')]),
          right: GrammarSymbolSequence(const [
            NonterminalGrammarSymbol('A'),
            NonterminalGrammarSymbol('B'),
          ]),
          order: 0,
        ),
        PhraseStructureProduction(
          id: 'swap-ab',
          left: GrammarSymbolSequence(const [
            NonterminalGrammarSymbol('A'),
            NonterminalGrammarSymbol('B'),
          ]),
          right: GrammarSymbolSequence(const [
            NonterminalGrammarSymbol('B'),
            NonterminalGrammarSymbol('A'),
          ]),
          order: 1,
        ),
        PhraseStructureProduction(
          id: 'a-leaf',
          left: GrammarSymbolSequence(const [NonterminalGrammarSymbol('A')]),
          right: GrammarSymbolSequence(const [TerminalGrammarSymbol('a')]),
          order: 2,
        ),
        PhraseStructureProduction(
          id: 'b-leaf',
          left: GrammarSymbolSequence(const [NonterminalGrammarSymbol('B')]),
          right: GrammarSymbolSequence(const [TerminalGrammarSymbol('b')]),
          order: 3,
        ),
      },
    );

Grammar _grammar({
  required String id,
  required Set<String> terminals,
  required Set<String> nonterminals,
  required String start,
  required Iterable<Production> productions,
  GrammarType type = GrammarType.contextFree,
}) =>
    Grammar(
      id: id,
      name: id,
      terminals: terminals,
      nonterminals: nonterminals,
      startSymbol: start,
      productions: productions.toSet(),
      type: type,
      created: DateTime.utc(2026, 8, 26),
      modified: DateTime.utc(2026, 8, 26),
    );

Grammar _renameNonterminals(
  Grammar source,
  Map<String, String> replacements,
) {
  String rename(String symbol) => replacements[symbol] ?? symbol;
  return source.copyWith(
    id: '${source.id}-renamed',
    startSymbol: rename(source.startSymbol),
    nonterminals: source.nonterminals.map(rename).toSet(),
    productions: {
      for (final production in source.productions)
        production.copyWith(
          leftSide: production.leftSide.map(rename).toList(),
          rightSide: production.rightSide.map(rename).toList(),
        ),
    },
    modified: source.modified,
  );
}

List<Production> _shuffledProductions(int seed, List<Production> productions) =>
    StableRandom.forCase(seed, 0, streamId: 'grammar/production-order')
        .shuffled(productions);

bool _sameBoundedLanguage(Grammar left, Grammar right, int maximumLength) {
  final terminals = left.terminals.union(right.terminals).toList()..sort();
  for (final word in _words(terminals, maximumLength)) {
    final raw = word.join();
    final leftResult = independentBoundedDerives(left, raw);
    final rightResult = independentBoundedDerives(right, raw);
    if (leftResult.bounded || rightResult.bounded) return false;
    if (leftResult.accepted != rightResult.accepted) return false;
  }
  return true;
}

Iterable<List<String>> _words(List<String> alphabet, int maximumLength) sync* {
  yield const <String>[];
  var frontier = <List<String>>[const []];
  for (var length = 1; length <= maximumLength; length++) {
    final next = <List<String>>[];
    for (final prefix in frontier) {
      for (final symbol in alphabet) {
        final word = [...prefix, symbol];
        next.add(word);
        yield word;
      }
    }
    frontier = next;
  }
}

List<String>? _tokenizeDeclaredTerminals(Grammar grammar, String input) {
  if (input.isEmpty) return const [];
  final terminals = grammar.terminals.toList()
    ..sort((left, right) {
      final length = right.length.compareTo(left.length);
      return length != 0 ? length : left.compareTo(right);
    });
  final result = <String>[];
  var offset = 0;
  while (offset < input.length) {
    String? matched;
    for (final terminal in terminals) {
      if (input.startsWith(terminal, offset)) {
        matched = terminal;
        break;
      }
    }
    if (matched == null) return null;
    result.add(matched);
    offset += matched.length;
  }
  return result;
}

String _terminalTreeYield(DerivationTreeNode node, Set<String> terminals) {
  final children = node.children;
  if (children.isEmpty) {
    final lexeme = node.lexeme;
    final symbol = node.symbol;
    return lexeme ?? (terminals.contains(symbol) ? symbol : '');
  }
  return children.map((child) => _terminalTreeYield(child, terminals)).join();
}

Map<String, Object?> _semanticGrammarJson(Grammar grammar) => {
      'nonterminals': grammar.nonterminals.toList()..sort(),
      'productions': grammar.productions
          .map((production) => {
                'id': production.id,
                'isLambda': production.isLambda,
                'left': production.leftSide,
                'order': production.order,
                'right': production.rightSide,
              })
          .toList()
        ..sort((left, right) =>
            (left['id']! as String).compareTo(right['id']! as String)),
      'start': grammar.startSymbol,
      'terminals': grammar.terminals.toList()..sort(),
      'type': grammar.type.name,
    };

bool _listEquals(List<String> left, List<String> right) {
  if (left.length != right.length) return false;
  for (var index = 0; index < left.length; index++) {
    if (left[index] != right[index]) return false;
  }
  return true;
}

String _safeWord(String input) => input.isEmpty
    ? 'empty'
    : input
        .replaceAll('id', 'identifier')
        .replaceAll(RegExp('[^a-zA-Z0-9]+'), '-');

List<String>? _sortedNullable(Set<String>? values) =>
    values == null ? null : (values.toList()..sort());

Map<String, int> _sortedCounts(Map<String, int> counts) => {
      for (final key in counts.keys.toList()..sort()) key: counts[key]!,
    };

Future<void> writeGrammarCertificationReport(
  GrammarCertificationReport report,
  Directory output,
) async {
  await output.create(recursive: true);
  final jsonFile =
      File('${output.path}${Platform.pathSeparator}grammar-report.json');
  await jsonFile.writeAsString(
    '${const JsonEncoder.withIndent('  ').convert(jsonDecode(canonicalJsonEncode(report.toJson())))}\n',
    flush: true,
  );
  final buffer = StringBuffer()
    ..writeln('<!-- Generated by tool/hard_edge_grammar_cases.dart. -->')
    ..writeln('# Grammar hard-edge certification')
    ..writeln()
    ..writeln('- Local result: `${report.status.name}`')
    ..writeln('- Remotely verified: `false`')
    ..writeln(
        '- Seed range: `${report.seedStart}..${report.seedStart + report.seedCount - 1}`')
    ..writeln()
    ..writeln('| Case | Algorithm | Property | Seed | Expected | Actual |')
    ..writeln('| --- | --- | --- | ---: | --- | --- |');
  for (final record in report.records) {
    buffer.writeln(
        '| `${record.id}` | `${record.algorithm}` | `${record.property}` '
        '| ${record.seed} | `${record.expected.name}` | '
        '`${record.actual.name}${record.definitive ? '' : ' (incomplete)'}` |');
  }
  buffer
    ..writeln()
    ..writeln('Results are local only and were not remotely verified.');
  await File('${output.path}${Platform.pathSeparator}grammar-report.md')
      .writeAsString(buffer.toString(), flush: true);
}
