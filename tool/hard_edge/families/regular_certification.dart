import 'dart:convert';
import 'dart:io';
import 'dart:math' as math;

import 'package:turing_lab/core/algorithms/automaton_simulator.dart';
import 'package:turing_lab/core/algorithms/dfa_completer.dart';
import 'package:turing_lab/core/algorithms/dfa_minimizer.dart';
import 'package:turing_lab/core/algorithms/dfa_operations.dart';
import 'package:turing_lab/core/algorithms/equivalence_checker.dart';
import 'package:turing_lab/core/algorithms/fa_to_regex_converter.dart';
import 'package:turing_lab/core/algorithms/fsa_concatenator.dart';
import 'package:turing_lab/core/algorithms/fsa_determinizer.dart';
import 'package:turing_lab/core/algorithms/fsa_kleene_star.dart';
import 'package:turing_lab/core/algorithms/fsa_reverser.dart';
import 'package:turing_lab/core/algorithms/fsa_to_grammar_converter.dart';
import 'package:turing_lab/core/algorithms/grammar_to_fsa_converter.dart';
import 'package:turing_lab/core/algorithms/language_comparator.dart';
import 'package:turing_lab/core/algorithms/nfa_to_dfa_converter.dart';
import 'package:turing_lab/core/algorithms/regex_analyzer.dart';
import 'package:turing_lab/core/algorithms/regex_simplifier.dart';
import 'package:turing_lab/core/algorithms/regex_to_nfa_converter.dart';
import 'package:turing_lab/core/manual_conversions/fa_to_regex_manual.dart';
import 'package:turing_lab/core/manual_conversions/regex_to_fa_manual.dart';
import 'package:turing_lab/core/models/fsa.dart';
import 'package:turing_lab/core/models/fsa_transition.dart';
import 'package:turing_lab/core/models/regex_document.dart';
import 'package:turing_lab/core/models/state.dart';
import 'package:vector_math/vector_math_64.dart';

import '../domains.dart';
import '../generation.dart';
import '../models.dart';
import '../oracles.dart';
import '../resources.dart';
import '../shrinking.dart';
import 'regular_matrix.dart';
import 'regular_oracles.dart';

enum RegularCertificationStatus { passed, failed, incomplete }

final class RegularCertificationCheck {
  const RegularCertificationCheck({
    required this.id,
    required this.status,
    required this.message,
    this.evidence = const {},
  });

  final String id;
  final RegularCertificationStatus status;
  final String message;
  final Map<String, Object?> evidence;

  Map<String, Object?> toJson() => {
        'evidence': evidence,
        'id': id,
        'message': message,
        'status': status.name,
      };
}

final class RegularCertificationOptions {
  const RegularCertificationOptions({
    this.seed = 335,
    this.cases = 12,
    this.oracleBudget = const RegularOracleBudget(),
  });

  final int seed;
  final int cases;
  final RegularOracleBudget oracleBudget;

  void validate() {
    if (seed < 0 || seed > 0xffffffff) {
      throw RangeError.range(seed, 0, 0xffffffff, 'seed');
    }
    if (cases <= 0 || cases > 256) {
      throw RangeError.range(cases, 1, 256, 'cases');
    }
    oracleBudget.validate();
  }
}

final class RegularCertificationReport {
  RegularCertificationReport({
    required this.options,
    required Iterable<RegularCertificationCheck> checks,
  }) : checks = List.unmodifiable(checks);

  final RegularCertificationOptions options;
  final List<RegularCertificationCheck> checks;

  RegularCertificationStatus get status {
    if (checks.any(
      (check) => check.status == RegularCertificationStatus.failed,
    )) {
      return RegularCertificationStatus.failed;
    }
    if (checks.any(
      (check) => check.status == RegularCertificationStatus.incomplete,
    )) {
      return RegularCertificationStatus.incomplete;
    }
    return RegularCertificationStatus.passed;
  }

  Map<String, Object?> toJson() => {
        'checks': checks.map((check) => check.toJson()).toList(),
        'family': 'regular',
        'inventory': {
          'algorithms':
              regularAlgorithmInventory.map((entry) => entry.toJson()).toList(),
          'providers':
              regularProviderInventory.map((entry) => entry.toJson()).toList(),
        },
        'options': {
          'cases': options.cases,
          'maximumConfigurations': options.oracleBudget.maximumConfigurations,
          'maximumWordLength': options.oracleBudget.maximumWordLength,
          'maximumWords': options.oracleBudget.maximumWords,
          'seed': options.seed,
        },
        'remotelyVerified': false,
        'schemaVersion': 1,
        'status': status.name,
      };

  String toMarkdown() {
    final buffer = StringBuffer()
      ..writeln('# Regular-language hard-edge certification')
      ..writeln()
      ..writeln('- Status: `${status.name}`')
      ..writeln('- Seed: `${options.seed}`')
      ..writeln('- Generated cases: `${options.cases}`')
      ..writeln('- Remotely verified: `false`')
      ..writeln()
      ..writeln('| Check | Status | Evidence |')
      ..writeln('| --- | --- | --- |');
    for (final check in checks) {
      buffer.writeln(
        '| `${check.id}` | `${check.status.name}` | '
        '${check.message.replaceAll('|', r'\|')} |',
      );
    }
    buffer
      ..writeln()
      ..writeln('## Inventory')
      ..writeln()
      ..writeln('| Algorithm | Source | Properties |')
      ..writeln('| --- | --- | --- |');
    for (final entry in regularAlgorithmInventory) {
      buffer.writeln(
        '| `${entry.id}` | `${entry.sourcePath}` | '
        '${entry.properties.map((property) => '`$property`').join(', ')} |',
      );
    }
    return buffer.toString();
  }
}

final class RegularCertificationRunner {
  RegularCertificationRunner({required Directory repositoryRoot})
      : repositoryRoot = repositoryRoot.absolute;

  final Directory repositoryRoot;

  Future<RegularCertificationReport> run(
    RegularCertificationOptions options,
  ) async {
    options.validate();
    final checks = <RegularCertificationCheck>[];
    await _runCheck(checks, 'regular.inventory', () => _checkInventory());
    await _runCheck(
      checks,
      'regular.model-integrity',
      _checkModelIntegrity,
    );
    await _runCheck(
      checks,
      'regular.generated-oracle',
      () => _checkGeneratedCases(options),
    );
    await _runCheck(checks, 'regular.determinization', _checkDeterminization);
    await _runCheck(checks, 'regular.lambda-removal', _checkLambdaRemoval);
    await _runCheck(checks, 'regular.completion', _checkCompletion);
    await _runCheck(checks, 'regular.minimization', _checkMinimization);
    await _runCheck(checks, 'regular.boolean-algebra', _checkBooleanAlgebra);
    await _runCheck(checks, 'regular.prefix-suffix', _checkPrefixSuffix);
    await _runCheck(
      checks,
      'regular.structural-closures',
      _checkStructuralClosures,
    );
    await _runCheck(
      checks,
      'regular.equivalence-witness',
      _checkEquivalenceWitness,
    );
    await _runCheck(checks, 'regular.regex-oracle', _checkRegexOracle);
    await _runCheck(
      checks,
      'regular.regex-simplification',
      _checkRegexSimplification,
    );
    await _runCheck(checks, 'regular.regex-analysis', _checkRegexAnalysis);
    await _runCheck(
      checks,
      'regular.fa-regex-roundtrip',
      _checkFaRegexRoundTrip,
    );
    await _runCheck(
      checks,
      'regular.grammar-roundtrip',
      _checkGrammarRoundTrip,
    );
    await _runCheck(checks, 'regular.trace-replay', _checkTraceReplay);
    await _runCheck(
      checks,
      'regular.resource-outcomes',
      _checkResourceOutcomes,
    );
    await _runCheck(
      checks,
      'regular.generated-shrink',
      () => _checkGeneratedShrink(options),
    );
    await _runCheck(checks, 'regular.mutations', _checkMutations);
    return RegularCertificationReport(options: options, checks: checks);
  }

  /// Executes one registrable property without paying for the whole family.
  Future<RegularCertificationCheck> runProperty(
    String property,
    RegularCertificationOptions options,
  ) async {
    options.validate();
    final checks = <RegularCertificationCheck>[];
    final check = switch (property) {
      'regular.inventory' => _checkInventory,
      'regular.model-integrity' => _checkModelIntegrity,
      'regular.generated-oracle' => () => _checkGeneratedCases(options),
      'regular.determinization' => _checkDeterminization,
      'regular.lambda-removal' => _checkLambdaRemoval,
      'regular.completion' => _checkCompletion,
      'regular.minimization' => _checkMinimization,
      'regular.boolean-algebra' => _checkBooleanAlgebra,
      'regular.prefix-suffix' => _checkPrefixSuffix,
      'regular.structural-closures' => _checkStructuralClosures,
      'regular.equivalence-witness' => _checkEquivalenceWitness,
      'regular.regex-oracle' => _checkRegexOracle,
      'regular.regex-simplification' => _checkRegexSimplification,
      'regular.regex-analysis' => _checkRegexAnalysis,
      'regular.fa-regex-roundtrip' => _checkFaRegexRoundTrip,
      'regular.grammar-roundtrip' => _checkGrammarRoundTrip,
      'regular.trace-replay' => _checkTraceReplay,
      'regular.resource-outcomes' => _checkResourceOutcomes,
      'regular.generated-shrink' => () => _checkGeneratedShrink(options),
      'regular.mutations' => _checkMutations,
      _ => throw ArgumentError.value(
          property,
          'property',
          'is not a registered regular-language property',
        ),
    };
    await _runCheck(checks, property, check);
    return checks.single;
  }

  Future<void> _runCheck(
    List<RegularCertificationCheck> checks,
    String id,
    _FutureCheck check,
  ) async {
    try {
      final evidence = await check();
      checks.add(
        RegularCertificationCheck(
          id: id,
          status: RegularCertificationStatus.passed,
          message: evidence.message,
          evidence: evidence.values,
        ),
      );
    } on _RegularIncomplete catch (incomplete) {
      checks.add(
        RegularCertificationCheck(
          id: id,
          status: RegularCertificationStatus.incomplete,
          message: incomplete.message,
        ),
      );
    } catch (error) {
      checks.add(
        RegularCertificationCheck(
          id: id,
          status: RegularCertificationStatus.failed,
          message: error.toString(),
        ),
      );
    }
  }

  Future<_CheckEvidence> _checkInventory() async {
    final ids = <String>{};
    for (final entry in [
      ...regularAlgorithmInventory,
      ...regularProviderInventory,
    ]) {
      _require(ids.add(entry.id), 'Inventory repeats ${entry.id}.');
      _require(
        File('${repositoryRoot.path}${Platform.pathSeparator}'
                '${entry.sourcePath.replaceAll('/', Platform.pathSeparator)}')
            .existsSync(),
        'Inventory source does not exist: ${entry.sourcePath}.',
      );
      _require(
          entry.entryPoints.isNotEmpty, '${entry.id} has no entry points.');
      _require(entry.properties.isNotEmpty, '${entry.id} has no properties.');
    }
    return _CheckEvidence(
      'Audited ${regularAlgorithmInventory.length} core entries and '
      '${regularProviderInventory.length} providers.',
      {'coreEntries': regularAlgorithmInventory.length, 'providers': 3},
    );
  }

  Future<_CheckEvidence> _checkModelIntegrity() async {
    final epsilonCycle = _epsilonSymbolCycle();
    _require(
        !epsilonCycle.isFiniteLanguage, 'Mixed cycle was reported finite.');
    final epsilonOnly = _epsilonOnlyCycle();
    _require(epsilonOnly.isFiniteLanguage, 'Epsilon-only cycle was infinite.');
    _require(
      epsilonCycle.getEpsilonClosure(epsilonCycle.initialState!).length == 2,
      'Deep epsilon closure lost a reachable state.',
    );
    final deterministic = _exactWord(['a'], alphabet: const {'a'});
    final validationErrors = deterministic.validate();
    _require(
      validationErrors.isEmpty,
      'Valid DFA failed validation: ${validationErrors.join('; ')}.',
    );
    _require(deterministic.isDeterministic, 'DFA model was nondeterministic.');
    _require(!epsilonCycle.isDeterministic, 'Epsilon NFA reported as a DFA.');
    return const _CheckEvidence(
      'Mixed cycles, epsilon-only cycles, and closure chains agree.',
      {'regressionFixture': 'epsilon-symbol-cycle'},
    );
  }

  Future<_CheckEvidence> _checkGeneratedCases(
    RegularCertificationOptions options,
  ) async {
    const generationBudget = GenerationBudget(
      maxSymbols: 3,
      maxWordLength: 4,
      maxStates: 4,
      maxTransitions: 8,
      maxRegexNodes: 8,
    );
    var evaluatedWords = 0;
    for (var index = 0; index < options.cases; index++) {
      final generated = generateCase<GeneratedAutomaton>(
        family: 'regular',
        property: 'generated-oracle',
        generatorVersion: 'regular-v1',
        seed: options.seed,
        caseIndex: index,
        mode: GenerationMode.boundaryValid,
        budget: generationBudget,
        generator: const AutomatonGenerator(),
        encodeValue: (value) => value.toJson(),
      );
      final automaton = _fromGenerated(generated.value);
      final determinized = NFAToDFAConverter.convert(automaton);
      _require(determinized.isSuccess, determinized.error ?? 'DFA failed.');
      final comparison = _compareBounded(
        automaton,
        determinized.data!,
        automaton.alphabet,
        options.oracleBudget,
      );
      evaluatedWords += comparison;
    }
    return _CheckEvidence(
      '${options.cases} deterministic generated cases matched subset '
      'construction.',
      {'evaluatedWords': evaluatedWords, 'seed': options.seed},
    );
  }

  Future<_CheckEvidence> _checkDeterminization() async {
    final source = _epsilonSymbolCycle();
    final converted = NFAToDFAConverter.convertWithSteps(source);
    _require(converted.isSuccess, converted.error ?? 'Conversion failed.');
    final dfa = converted.data!.resultDFA;
    _require(dfa.isDeterministic, 'Subset construction returned an NFA.');
    _require(!dfa.hasEpsilonTransitions, 'DFA retained epsilon transitions.');
    final adapter = FSADeterminizer.determinizeIfNeeded(source, 'regular');
    _require(adapter.isSuccess, adapter.error ?? 'Adapter failed.');
    final reference = regularReferenceSubsetConstruction(source);
    final renamed = _renamedAndReordered(source);
    final renamedResult = NFAToDFAConverter.convert(renamed);
    _require(renamedResult.isSuccess, renamedResult.error ?? 'Rename failed.');
    final words = _compareBounded(
      source,
      dfa,
      source.alphabet,
      const RegularOracleBudget(maximumWordLength: 5),
    );
    for (final word in regularTokenWords(const ['a'], 5)) {
      _require(
        _accepts(dfa, word) == reference.accepts(word),
        'Subset reference disagreed for $word.',
      );
      _require(
        _accepts(dfa, word) == _accepts(renamedResult.data!, word),
        'Renaming or insertion order changed determinization for $word.',
      );
      _require(
        _accepts(dfa, word) == _accepts(adapter.data!, word),
        'Determinizer adapter disagreed for $word.',
      );
    }
    return _CheckEvidence(
      'Subset construction preserved the epsilon-cycle language.',
      {'evaluatedWords': words, 'traceSteps': converted.data!.steps.length},
    );
  }

  Future<_CheckEvidence> _checkLambdaRemoval() async {
    final source = _epsilonSymbolCycle();
    final result = FSAOperations.removeLambdaTransitions(source);
    _require(result.isSuccess, result.error ?? 'Removal failed.');
    _require(
      !result.data!.hasEpsilonTransitions,
      'Lambda-removal retained an epsilon transition.',
    );
    final words = _compareBounded(
      source,
      result.data!,
      source.alphabet,
      const RegularOracleBudget(maximumWordLength: 5),
    );
    return _CheckEvidence(
      'Lambda removal preserved acceptance and final closure.',
      {'evaluatedWords': words},
    );
  }

  Future<_CheckEvidence> _checkCompletion() async {
    final source = _exactWord(['a'], alphabet: const {'a', 'b'});
    final once = DFACompleter.complete(source);
    final twice = DFACompleter.complete(once);
    _require(_isComplete(once), 'Completion left a missing transition.');
    _require(
      _automatonShape(once) == _automatonShape(twice),
      'Completion is not idempotent.',
    );
    final words = _compareBounded(
      source,
      once,
      source.alphabet,
      const RegularOracleBudget(maximumWordLength: 3),
    );
    return _CheckEvidence(
      'Completion is total, collision-safe, and idempotent.',
      {'evaluatedWords': words, 'states': once.states.length},
    );
  }

  Future<_CheckEvidence> _checkMinimization() async {
    final source = _redundantEndsWithA();
    final once = DFAMinimizer.minimizeWithSteps(source);
    _require(once.isSuccess, once.error ?? 'Minimization failed.');
    final minimized = once.data!.resultDFA;
    final twice = DFAMinimizer.minimize(minimized);
    _require(twice.isSuccess, twice.error ?? 'Second minimization failed.');
    final words = _compareBounded(
      source,
      minimized,
      source.alphabet,
      const RegularOracleBudget(maximumWordLength: 4),
    );
    _require(
      minimized.states.length == twice.data!.states.length,
      'Minimization is not idempotent by quotient size.',
    );
    _require(
      minimized.states.length < source.states.length,
      'Redundant states were not merged.',
    );
    final referenceCount = regularReferenceMinimumStateCount(
      DFACompleter.complete(source),
    );
    _require(
      minimized.states.length == referenceCount,
      'Minimizer returned ${minimized.states.length} states; independent '
      'refinement returned $referenceCount.',
    );
    final renamed = _renamedAndReordered(source);
    final renamedMinimum = DFAMinimizer.minimize(renamed);
    _require(
        renamedMinimum.isSuccess, renamedMinimum.error ?? 'Rename failed.');
    _require(
      renamedMinimum.data!.states.length == minimized.states.length,
      'Renaming or insertion order changed the minimal quotient size.',
    );
    return _CheckEvidence(
      'Hopcroft minimization preserved language and stabilized.',
      {'evaluatedWords': words, 'states': minimized.states.length},
    );
  }

  Future<_CheckEvidence> _checkBooleanAlgebra() async {
    final a = _endsWith('a');
    final b = _contains('b');
    final union = DFAOperations.union(a, b);
    final intersection = DFAOperations.intersection(a, b);
    final difference = DFAOperations.difference(a, b);
    final complement = DFAOperations.complement(a);
    for (final result in [union, intersection, difference, complement]) {
      _require(result.isSuccess, result.error ?? 'Boolean operation failed.');
    }
    var words = 0;
    for (final word in regularTokenWords(const ['a', 'b'], 4)) {
      final acceptsA = _accepts(a, word);
      final acceptsB = _accepts(b, word);
      _require(_accepts(union.data!, word) == (acceptsA || acceptsB), 'Union');
      _require(
        _accepts(intersection.data!, word) == (acceptsA && acceptsB),
        'Intersection',
      );
      _require(
        _accepts(difference.data!, word) == (acceptsA && !acceptsB),
        'Difference',
      );
      _require(_accepts(complement.data!, word) == !acceptsA, 'Complement');
      words++;
    }
    return _CheckEvidence(
      'Boolean products matched independent truth tables.',
      {'evaluatedWords': words, 'identities': 4},
    );
  }

  Future<_CheckEvidence> _checkPrefixSuffix() async {
    final exactAb = _exactWord(['a', 'b'], alphabet: const {'a', 'b'});
    final prefix = DFAOperations.prefixClosure(exactAb);
    final suffix = DFAOperations.suffixClosure(exactAb);
    _require(prefix.isSuccess, prefix.error ?? 'Prefix closure failed.');
    _require(suffix.isSuccess, suffix.error ?? 'Suffix closure failed.');
    const expectedPrefix = {'', 'a', 'ab'};
    const expectedSuffix = {'', 'b', 'ab'};
    var words = 0;
    for (final word in regularTokenWords(const ['a', 'b'], 3)) {
      final rendered = word.join();
      _require(
        _accepts(prefix.data!, word) == expectedPrefix.contains(rendered),
        'Prefix closure mismatch for $word.',
      );
      _require(
        _accepts(suffix.data!, word) == expectedSuffix.contains(rendered),
        'Suffix closure mismatch for $word.',
      );
      words++;
    }
    return _CheckEvidence(
      'Prefix and suffix closures matched exact finite sets.',
      {'evaluatedWords': words},
    );
  }

  Future<_CheckEvidence> _checkStructuralClosures() async {
    final a = _exactWord(['a'], alphabet: const {'a', 'b'});
    final b = _exactWord(['b'], alphabet: const {'a', 'b'});
    final concatenated = FSAConcatenator.concatenate(a, b);
    final starred = FSAKleeneStar.apply(a);
    final reversed = FSAReverser.reverse(
      _exactWord(['a', 'b'], alphabet: const {'a', 'b'}),
    );
    _require(concatenated.isSuccess, concatenated.error ?? 'Concat failed.');
    _require(starred.isSuccess, starred.error ?? 'Star failed.');
    _require(reversed.isSuccess, reversed.error ?? 'Reverse failed.');
    var words = 0;
    for (final word in regularTokenWords(const ['a', 'b'], 4)) {
      _require(
        _accepts(concatenated.data!.resultNFA, word) == (word.join() == 'ab'),
        'Concatenation mismatch for $word.',
      );
      _require(
        _accepts(starred.data!.resultNFA, word) ==
            word.every((symbol) => symbol == 'a'),
        'Kleene star mismatch for $word.',
      );
      _require(
        _accepts(reversed.data!.resultNFA, word) == (word.join() == 'ba'),
        'Reversal mismatch for $word.',
      );
      words++;
    }
    return _CheckEvidence(
      'Concatenation, star, and reversal matched exact witnesses.',
      {'evaluatedWords': words},
    );
  }

  Future<_CheckEvidence> _checkEquivalenceWitness() async {
    final a = _exactWord(['a'], alphabet: const {'a', 'b'});
    final b = _exactWord(['b'], alphabet: const {'a', 'b'});
    final comparison = LanguageComparator.compareLanguages(a, b);
    _require(comparison.isSuccess, comparison.error ?? 'Comparison failed.');
    final detail = comparison.data!;
    _require(!detail.isEquivalent, 'Distinct singleton languages matched.');
    final witness = detail.distinguishingString;
    _require(witness != null, 'No distinguishing witness was returned.');
    final tokens = witness!.runes.map(String.fromCharCode).toList();
    _require(
      _accepts(a, tokens) != _accepts(b, tokens),
      'Reported witness does not distinguish the inputs.',
    );
    _require(
      EquivalenceChecker.areEquivalentResult(a, a).data == true,
      'Equivalence was not reflexive.',
    );
    _require(
      EquivalenceChecker.areEquivalent(a, a),
      'Legacy equivalence API was not reflexive.',
    );
    _require(
      EquivalenceChecker.areEquivalentResult(a, b).data ==
          EquivalenceChecker.areEquivalentResult(b, a).data,
      'Equivalence was not symmetric.',
    );
    return _CheckEvidence(
      'Exact comparison returned a valid shortest witness.',
      {'witness': witness, 'witnessLength': tokens.length},
    );
  }

  Future<_CheckEvidence> _checkRegexOracle() async {
    const alphabet = {'a', 'b', '😀', '😁'};
    const expressions = [
      '∅',
      'ε',
      'a|b',
      'a*',
      '(ab)+',
      'a?',
      '[😀-😁]',
      '.',
    ];
    var words = 0;
    for (final expression in expressions) {
      final validation = RegexToNFAConverter.validate(expression);
      final node = RegexToNFAConverter.parse(expression);
      final conversion = RegexToNFAConverter.convert(
        expression,
        contextAlphabet: alphabet,
      );
      _require(validation.isValid, '$expression failed validation.');
      _require(node != null, '$expression did not produce an AST.');
      _require(conversion.isSuccess, conversion.error ?? 'Regex failed.');
      for (final word in regularTokenWords(alphabet.toList(), 3)) {
        final expected = regularRegexOracleAccepts(
          node!,
          word,
          contextAlphabet: alphabet,
        );
        _require(
          _accepts(conversion.data!, word) == expected,
          '$expression disagreed with the AST oracle for $word.',
        );
        words++;
      }
    }
    final withSteps = RegexToNFAConverter.convertWithSteps(
      'a|b',
      contextAlphabet: alphabet,
    );
    _require(withSteps.isSuccess, withSteps.error ?? 'Trace failed.');
    final document = RegexDocument(
      id: 'regular-manual',
      name: 'Regular manual oracle',
      source: 'a',
      alphabet: const ['a', 'b'],
    );
    final started = RegexToFaManualSession.start(
      sourceDocument: document,
      sourceRevision: 1,
    );
    _require(started.isSuccess, 'Manual regex session did not start.');
    final session = started.session!;
    final expected = session.expectedFragment(session.ast.rootId);
    _require(expected.isSuccess, 'Manual regex fragment was unavailable.');
    final submitted = session.createBase(
      nodeId: session.ast.rootId,
      candidate: expected.fragment!,
    );
    _require(submitted.isSuccess, 'Manual regex base submission failed.');
    return _CheckEvidence(
      'Parser and Thompson construction matched an independent AST evaluator.',
      {'evaluatedWords': words, 'expressions': expressions.length},
    );
  }

  Future<_CheckEvidence> _checkRegexSimplification() async {
    const expressions = ['(a|∅)', '(a*)*', '(εa)', '(a|a)', '(ab)|(ab)'];
    var words = 0;
    for (final expression in expressions) {
      final simplified = RegexSimplifier.simplifyWithSteps(expression);
      _require(simplified.isSuccess, simplified.error ?? 'Simplify failed.');
      final simple = RegexSimplifier.simplify(expression);
      _require(simple.isSuccess, simple.error ?? 'Simple API failed.');
      _require(
        simple.data == simplified.data!.simplifiedRegex,
        'Simplifier entry points disagreed for $expression.',
      );
      final before = RegexToNFAConverter.convert(expression);
      final after = RegexToNFAConverter.convert(
        simplified.data!.simplifiedRegex,
      );
      _require(before.isSuccess && after.isSuccess, 'Conversion failed.');
      try {
        words += _compareBounded(
          before.data!,
          after.data!,
          const {'a', 'b'},
          const RegularOracleBudget(maximumWordLength: 4),
        );
      } on StateError catch (error) {
        throw StateError(
          '$expression -> ${simplified.data!.simplifiedRegex}: '
          '${error.message}',
        );
      }
    }
    return _CheckEvidence(
      'Simplification preserved bounded language and emitted steps.',
      {'evaluatedWords': words, 'expressions': expressions.length},
    );
  }

  Future<_CheckEvidence> _checkRegexAnalysis() async {
    final analysis = RegexAnalyzer.analyzeWithSamples(
      '(a|b)*abb',
      maxSamples: 5,
      maxLength: 12,
    );
    _require(analysis.isSuccess, analysis.error ?? 'Analysis failed.');
    final starHeight = RegexAnalyzer.computeStarHeight('(a|b)*abb');
    final nesting = RegexAnalyzer.computeNestingDepth('(a|b)*abb');
    final alphabet = RegexAnalyzer.extractAlphabet('(a|b)*abb');
    final plain = RegexAnalyzer.analyze('(a|b)*abb');
    final operators = RegexAnalyzer.countOperators('(a|b)*abb');
    final complexity = RegexAnalyzer.determineComplexity('(a|b)*abb');
    final samples = RegexAnalyzer.generateSampleStrings(
      '(a|b)*abb',
      maxSamples: 5,
      maxLength: 12,
    );
    _require(plain.isSuccess, plain.error ?? 'Plain analysis failed.');
    _require(operators.isSuccess, operators.error ?? 'Count failed.');
    _require(complexity.isSuccess, complexity.error ?? 'Complexity failed.');
    _require(samples.isSuccess, samples.error ?? 'Samples failed.');
    _require(starHeight.data == 1, 'Star height was ${starHeight.data}.');
    _require(nesting.data == 1, 'Nesting depth was ${nesting.data}.');
    _require(
        alphabet.data!.containsAll({'a', 'b'}), 'Alphabet was incomplete.');
    return _CheckEvidence(
      'Analysis, complexity, alphabet, and sample paths completed.',
      {'sampleCount': analysis.data!.sampleStrings.samples.length},
    );
  }

  Future<_CheckEvidence> _checkFaRegexRoundTrip() async {
    final source = _exactWord(['a', 'b'], alphabet: const {'a', 'b'});
    final regex = FAToRegexConverter.convertWithSteps(source);
    _require(regex.isSuccess, regex.error ?? 'FA to regex failed.');
    final plain = FAToRegexConverter.convert(source);
    _require(plain.isSuccess, plain.error ?? 'Plain FA to regex failed.');
    final restored = RegexToNFAConverter.convert(regex.data!.resultRegex);
    _require(restored.isSuccess, restored.error ?? 'Regex to FA failed.');
    final words = _compareBounded(
      source,
      restored.data!,
      source.alphabet,
      const RegularOracleBudget(maximumWordLength: 4),
    );
    var manual = FaToRegexManualOracle.normalize(source);
    while (manual.removableStateIds.isNotEmpty) {
      final stateId = manual.removableStateIds.first;
      final inspection = FaToRegexManualOracle.inspectElimination(
        manual,
        stateId,
      );
      final labels = <FaToRegexStatePair, String>{};
      for (final formula in inspection.formulas) {
        final validation = FaToRegexManualOracle.validatePairLabel(
          gnfa: manual,
          inspection: inspection,
          pair: formula.pair,
          learnerExpression: formula.expectedExpression,
        );
        _require(validation.isValid, 'Manual pair validation failed.');
        labels[formula.pair] = formula.expectedExpression;
      }
      manual = FaToRegexManualOracle.applyElimination(
        gnfa: manual,
        inspection: inspection,
        pairLabels: labels,
      );
    }
    final manualRegex = FaToRegexManualOracle.finalRegex(manual);
    final manualNfa = RegexToNFAConverter.convert(manualRegex);
    _require(manualNfa.isSuccess, manualNfa.error ?? 'Manual regex failed.');
    _compareBounded(
      source,
      manualNfa.data!,
      source.alphabet,
      const RegularOracleBudget(maximumWordLength: 4),
    );
    return _CheckEvidence(
      'State elimination round-tripped through the supported regex dialect.',
      {'evaluatedWords': words, 'traceSteps': regex.data!.steps.length},
    );
  }

  Future<_CheckEvidence> _checkGrammarRoundTrip() async {
    final source = _exactWord(['a', 'b'], alphabet: const {'a', 'b'});
    final grammar = FSAToGrammarConverter.tryConvert(source);
    _require(grammar.isSuccess, grammar.error ?? 'FSA to grammar failed.');
    final directGrammar = FSAToGrammarConverter.convert(source);
    _require(
      directGrammar.productions.isNotEmpty,
      'Direct grammar conversion returned no productions.',
    );
    final restored = GrammarToFSAConverter.convert(grammar.data!);
    _require(restored.isSuccess, restored.error ?? 'Grammar to FSA failed.');
    final words = _compareBounded(
      source,
      restored.data!,
      source.alphabet,
      const RegularOracleBudget(maximumWordLength: 4),
    );
    return _CheckEvidence(
      'Right-linear grammar conversion preserved the language.',
      {
        'evaluatedWords': words,
        'productions': grammar.data!.productions.length
      },
    );
  }

  Future<_CheckEvidence> _checkTraceReplay() async {
    final source = _exactWord(['a', 'b'], alphabet: const {'a', 'b'});
    final simulation = await AutomatonSimulator.simulateDFA(
      source,
      'ab',
      stepByStep: true,
    );
    _require(simulation.isSuccess, simulation.error ?? 'Simulation failed.');
    final result = simulation.data!;
    var state = source.initialState!;
    var replayed = 0;
    for (final step in result.steps) {
      if (step.consumedInput.isEmpty) continue;
      final transitions = source.getTransitionsFromStateOnSymbol(
        state,
        step.consumedInput,
      );
      _require(transitions.length == 1, 'Trace action was not deterministic.');
      state = transitions.single.toState;
      _require(
        step.activeStateIds?.contains(state.id) ?? false,
        'Trace destination does not match replay.',
      );
      replayed++;
    }
    _require(
      result.isAccepted == source.acceptingStates.contains(state),
      'Trace final state disagrees with the reported result.',
    );
    final generic = await AutomatonSimulator.simulate(source, 'ab');
    final nfa = await AutomatonSimulator.simulateNFA(
      _epsilonSymbolCycle(),
      'a',
    );
    final accepts = await AutomatonSimulator.accepts(source, 'ab');
    final rejects = await AutomatonSimulator.rejects(source, 'aa');
    final accepted = await AutomatonSimulator.findAcceptedStrings(source, 2);
    final rejected = await AutomatonSimulator.findRejectedStrings(source, 2);
    _require(generic.isSuccess && generic.data!.accepted, 'simulate failed.');
    _require(nfa.isSuccess && nfa.data!.accepted, 'simulateNFA failed.');
    _require(accepts.isSuccess && accepts.data!, 'accepts failed.');
    _require(rejects.isSuccess && rejects.data!, 'rejects failed.');
    _require(
      accepted.isSuccess && accepted.data!.contains('ab'),
      'findAcceptedStrings failed.',
    );
    _require(
      rejected.isSuccess && rejected.data!.contains('aa'),
      'findRejectedStrings failed.',
    );
    return _CheckEvidence(
      'Every consuming trace step replayed to the reported result.',
      {'replayedSteps': replayed},
    );
  }

  Future<_CheckEvidence> _checkResourceOutcomes() async {
    final bounded = regularOracleAccepts(
      _epsilonSymbolCycle(),
      const ['a'],
      maximumConfigurations: 1,
    );
    _require(
      bounded is OracleBoundedUnknown<bool, RegularOracleEvidence>,
      'Oracle bound was coerced into a verdict.',
    );
    final timed = await AutomatonSimulator.simulateDFA(
      _endsWith('a'),
      'a',
      timeout: Duration.zero,
    );
    _require(
        timed.isSuccess && timed.data!.isTimeout, 'Timeout was not typed.');
    final cancelled = MutableCancellationToken()..cancel();
    final cancellation = ResourceAssertions(
      budget: ResourceBudget(),
      clock: StopwatchElapsedClock(),
      cancellation: cancelled,
    ).evaluate(const ResourceSnapshot());
    _require(cancellation is ResourceCancelled, 'Cancellation was not typed.');
    var generation = 2;
    final stale = ResourceAssertions(
      budget: ResourceBudget(),
      clock: StopwatchElapsedClock(),
      freshness: GenerationFreshnessProbe(
        expectedGeneration: 1,
        currentGeneration: () => generation,
      ),
    ).evaluate(const ResourceSnapshot());
    generation++;
    _require(stale is ResourceStaleRequest, 'Stale request was not typed.');
    return const _CheckEvidence(
      'Bounds, timeout, cancellation, and stale requests stayed distinct.',
      {'outcomes': 4},
    );
  }

  Future<_CheckEvidence> _checkGeneratedShrink(
    RegularCertificationOptions options,
  ) async {
    final sourceValue = GeneratedAutomaton(
      id: 'regular-shrink',
      alphabet: const ['a', 'b'],
      states: const [
        GeneratedState(id: 'q0', initial: true, accepting: false),
        GeneratedState(id: 'q1', initial: false, accepting: true),
        GeneratedState(id: 'unused', initial: false, accepting: false),
      ],
      transitions: [
        GeneratedTransition(
          id: 't0',
          fromId: 'q0',
          toId: 'q1',
          readTokens: const ['a'],
        ),
        GeneratedTransition(
          id: 'unused-loop',
          fromId: 'unused',
          toId: 'unused',
          readTokens: const ['b'],
        ),
      ],
    );
    final generated = GeneratedCase<GeneratedAutomaton>(
      family: 'regular',
      property: 'mutation.skip-dfa-completion',
      generatorVersion: 'regular-v1',
      streamId: 'regular/mutation.flip-accepting/regular-v1',
      seed: options.seed,
      caseIndex: 0,
      mode: GenerationMode.valid,
      budget: const GenerationBudget(),
      value: sourceValue,
      encodeValue: (value) => value.toJson(),
    );
    bool exposesMutant(GeneratedAutomaton value) {
      final automaton = _fromGenerated(value);
      if (automaton.initialState == null || !automaton.isDeterministic) {
        return false;
      }
      final canonical = DFACompleter.complete(automaton);
      final mutant = automaton;
      return _isComplete(canonical) && !_isComplete(mutant);
    }

    final shrunk = shrinkFailure(
      source: generated,
      shrinker: const AutomatonShrinker(),
      stillFails: exposesMutant,
      isValid: (candidate) =>
          candidate.alphabet.isNotEmpty &&
          candidate.states.any((state) => state.initial) &&
          candidate.transitions.every(
            (transition) =>
                candidate.states
                    .any((state) => state.id == transition.fromId) &&
                candidate.states.any((state) => state.id == transition.toId),
          ),
      maxAttempts: 128,
    );
    _require(shrunk.acceptedCandidates > 0, 'Shrinker accepted no reduction.');
    _require(
      shrunk.minimalValue.states.length < sourceValue.states.length ||
          shrunk.minimalValue.transitions.length <
              sourceValue.transitions.length,
      'Shrinker did not reduce the generated fixture.',
    );
    return _CheckEvidence(
      'A generated mutation witness shrank deterministically.',
      {
        'acceptedCandidates': shrunk.acceptedCandidates,
        'attempts': shrunk.attempts,
        'minimalStates': shrunk.minimalValue.states.length,
        'minimalTransitions': shrunk.minimalValue.transitions.length,
      },
    );
  }

  Future<_CheckEvidence> _checkMutations() async {
    const operators = [
      'flip-initial-acceptance',
      'ignore-epsilon-reachability',
      'skip-dfa-completion',
    ];
    final killed = operators.where(regularMutationProbeKilled).toList();
    final score = killed.length / operators.length;
    _require(
      score >= regularMutationMinimumScore,
      'Mutation score $score is below $regularMutationMinimumScore: $killed.',
    );
    return _CheckEvidence(
      'All registered pure-Dart mutation operators were killed.',
      {
        'killed': killed.length,
        'registered': operators.length,
        'minimumScore': regularMutationMinimumScore,
        'score': score,
      },
    );
  }
}

/// All focused semantic variants must be distinguished before this family is
/// certified. A survivor is reported individually by the mutation executor.
const regularMutationMinimumScore = 1.0;

/// Applies one registered mutant and returns whether its targeted property
/// distinguishes the mutant from the canonical implementation.
bool regularMutationProbeKilled(String operatorId) => switch (operatorId) {
      'flip-initial-acceptance' => _flipInitialAcceptanceIsKilled(),
      'ignore-epsilon-reachability' => _ignoredEpsilonIsKilled(),
      'skip-dfa-completion' => _skippedCompletionIsKilled(),
      _ => throw ArgumentError.value(
          operatorId,
          'operatorId',
          'is not a registered regular mutation operator',
        ),
    };

/// Validates property-specific fixture data before a catalog case is run.
///
/// This intentionally uses the independent oracle for acceptance expectations;
/// changing a fixture word, seed, or expected outcome therefore changes replay.
bool regularFixturePayloadMatches(
  String property,
  Map<String, Object?> fixture,
) {
  if (property == 'regular.regex-oracle' && fixture['regex'] is String) {
    final expression = fixture['regex']! as String;
    final conversion = RegexToNFAConverter.convert(expression);
    if (!conversion.isSuccess) return false;
    bool acceptsFixtureWord(Object? value, bool expected) {
      if (value is! String) return false;
      final tokens = value.runes.map(String.fromCharCode).toList();
      final result = regularOracleAccepts(conversion.data!, tokens);
      return result is OracleDefinitive<bool, RegularOracleEvidence> &&
          result.value == expected;
    }

    final accepted = fixture['accepted'];
    final rejected = fixture['rejected'];
    return accepted is List &&
        rejected is List &&
        accepted.every((word) => acceptsFixtureWord(word, true)) &&
        rejected.every((word) => acceptsFixtureWord(word, false));
  }
  if ((property == 'regular.model-integrity' ||
          property == 'regular.determinization') &&
      fixture['states'] is List) {
    final automaton = _automatonFromFixture(fixture);
    final expectedFinite = fixture['expectedFinite'];
    return expectedFinite is bool &&
        automaton.isFiniteLanguage == expectedFinite;
  }
  if (property == 'regular.resource-outcomes') {
    final outcomes = fixture['outcomes'];
    const expected = {'bounded', 'timeout', 'cancelled', 'stale'};
    return outcomes is List &&
        outcomes.toSet().length == expected.length &&
        outcomes.toSet().containsAll(expected);
  }
  if (property == 'regular.generated-shrink') {
    return fixture['shrinker'] == 'AutomatonShrinker' &&
        fixture['maxAttempts'] is int &&
        (fixture['maxAttempts']! as int) > 0;
  }
  return true;
}

FSA _automatonFromFixture(Map<String, Object?> fixture) {
  final stateIds = (fixture['states']! as List).cast<String>();
  final initialId = fixture['initialState'] as String?;
  final acceptingIds =
      (fixture['acceptingStates'] as List? ?? const []).cast<String>().toSet();
  final states = <String, State>{
    for (var index = 0; index < stateIds.length; index++)
      stateIds[index]: State(
        id: stateIds[index],
        label: stateIds[index],
        position: Vector2(index * 40, 0),
        isInitial: stateIds[index] == initialId,
        isAccepting: acceptingIds.contains(stateIds[index]),
      ),
  };
  final transitions = <FSATransition>{};
  final encodedTransitions = fixture['transitions'];
  if (encodedTransitions is! List) {
    throw const FormatException('Regular fixture transitions must be a list.');
  }
  for (var index = 0; index < encodedTransitions.length; index++) {
    final encoded = encodedTransitions[index];
    if (encoded is! Map) {
      throw const FormatException(
          'Regular fixture transition must be an object.');
    }
    final from = states[encoded['from']];
    final to = states[encoded['to']];
    final read = encoded['read'];
    if (from == null || to == null || read is! List) {
      throw const FormatException('Regular fixture transition is malformed.');
    }
    final symbols = read.cast<String>().toSet();
    transitions.add(
      symbols.isEmpty
          ? FSATransition.epsilon(
              id: 'fixture_$index',
              fromState: from,
              toState: to,
            )
          : FSATransition(
              id: 'fixture_$index',
              fromState: from,
              toState: to,
              inputSymbols: symbols,
            ),
    );
  }
  return _fsa(
    id: 'fixture-automaton',
    states: states.values.toSet(),
    transitions: transitions,
    alphabet: (fixture['alphabet'] as List? ?? const []).cast<String>().toSet(),
    initial: states[initialId]!,
    accepting: acceptingIds.map((id) => states[id]!).toSet(),
  );
}

bool _flipInitialAcceptanceIsKilled() {
  final source = _exactWord(['a'], alphabet: const {'a', 'b'});
  final initial = source.initialState!;
  final mutantAccepting = {...source.acceptingStates};
  if (!mutantAccepting.remove(initial)) mutantAccepting.add(initial);
  final mutant = source.copyWith(acceptingStates: mutantAccepting);
  return _accepts(mutant, const []) != _accepts(source, const []);
}

bool _ignoredEpsilonIsKilled() {
  final source = _epsilonSymbolCycle();
  return _isFiniteIgnoringEpsilon(source) != source.isFiniteLanguage;
}

bool _skippedCompletionIsKilled() {
  final source = _exactWord(['a'], alphabet: const {'a', 'b'});
  return _isComplete(source) != _isComplete(DFACompleter.complete(source));
}

bool _isFiniteIgnoringEpsilon(FSA automaton) {
  final initial = automaton.initialState;
  if (initial == null) return true;
  final adjacency = <State, Set<State>>{
    for (final state in automaton.states) state: <State>{},
  };
  final reverse = <State, Set<State>>{
    for (final state in automaton.states) state: <State>{},
  };
  for (final transition in automaton.fsaTransitions) {
    if (transition.isEpsilonTransition) continue;
    adjacency[transition.fromState]?.add(transition.toState);
    reverse[transition.toState]?.add(transition.fromState);
  }
  Set<State> reach(Set<State> seeds, Map<State, Set<State>> graph) {
    final reached = <State>{...seeds};
    final pending = <State>[...seeds];
    while (pending.isNotEmpty) {
      final state = pending.removeLast();
      for (final next in graph[state] ?? const <State>{}) {
        if (reached.add(next)) pending.add(next);
      }
    }
    return reached;
  }

  final useful = reach({initial}, adjacency)
      .intersection(reach(automaton.acceptingStates, reverse));
  final visiting = <State>{};
  final visited = <State>{};
  bool hasCycle(State state) {
    if (visiting.contains(state)) return true;
    if (!visited.add(state)) return false;
    visiting.add(state);
    for (final next in adjacency[state] ?? const <State>{}) {
      if (useful.contains(next) && hasCycle(next)) return true;
    }
    visiting.remove(state);
    return false;
  }

  return !useful.any(hasCycle);
}

typedef _FutureCheck = Future<_CheckEvidence> Function();

final class _CheckEvidence {
  const _CheckEvidence(this.message, [this.values = const {}]);

  final String message;
  final Map<String, Object?> values;
}

final class _RegularIncomplete implements Exception {
  const _RegularIncomplete(this.message);

  final String message;
}

void _require(bool condition, String message) {
  if (!condition) throw StateError(message);
}

int _compareBounded(
  FSA left,
  FSA right,
  Iterable<String> alphabet,
  RegularOracleBudget budget,
) {
  final leftResult = regularLanguageSignature(left, alphabet, budget);
  final rightResult = regularLanguageSignature(right, alphabet, budget);
  if (leftResult is OracleBoundedUnknown ||
      rightResult is OracleBoundedUnknown) {
    throw const _RegularIncomplete('The exhaustive oracle reached its bound.');
  }
  _require(
    leftResult is OracleDefinitive<Map<String, bool>, RegularOracleEvidence> &&
        rightResult
            is OracleDefinitive<Map<String, bool>, RegularOracleEvidence>,
    'The exhaustive oracle was not applicable.',
  );
  final leftDefinitive =
      leftResult as OracleDefinitive<Map<String, bool>, RegularOracleEvidence>;
  final rightDefinitive =
      rightResult as OracleDefinitive<Map<String, bool>, RegularOracleEvidence>;
  if (!const MapEquality<String, bool>().equals(
    leftDefinitive.value,
    rightDefinitive.value,
  )) {
    final witness = leftDefinitive.value.keys.firstWhere(
      (word) => leftDefinitive.value[word] != rightDefinitive.value[word],
    );
    throw StateError(
      'Bounded language signatures differ at "$witness": '
      '${leftDefinitive.value[witness]} != '
      '${rightDefinitive.value[witness]}.',
    );
  }
  return leftDefinitive.evidence.evaluatedWords;
}

bool _accepts(FSA automaton, List<String> word) {
  final result = regularOracleAccepts(automaton, word);
  _require(
    result is OracleDefinitive<bool, RegularOracleEvidence>,
    'Oracle was not definitive for $word.',
  );
  return (result as OracleDefinitive<bool, RegularOracleEvidence>).value;
}

FSA _fromGenerated(GeneratedAutomaton generated) {
  final states = <String, State>{
    for (var index = 0; index < generated.states.length; index++)
      generated.states[index].id: State(
        id: generated.states[index].id,
        label: generated.states[index].id,
        position: Vector2(index * 40, 0),
        isInitial: generated.states[index].initial,
        isAccepting: generated.states[index].accepting,
      ),
  };
  final transitions = <FSATransition>{};
  for (final transition in generated.transitions) {
    final from = states[transition.fromId];
    final to = states[transition.toId];
    if (from == null || to == null) continue;
    transitions.add(
      transition.readTokens.isEmpty
          ? FSATransition.epsilon(
              id: transition.id,
              fromState: from,
              toState: to,
            )
          : FSATransition(
              id: transition.id,
              fromState: from,
              toState: to,
              inputSymbols: transition.readTokens.toSet(),
            ),
    );
  }
  final initial = states.values.where((state) => state.isInitial).firstOrNull;
  return FSA(
    id: generated.id,
    name: generated.id,
    states: states.values.toSet(),
    transitions: transitions,
    alphabet: generated.alphabet.toSet(),
    initialState: initial,
    acceptingStates: states.values.where((state) => state.isAccepting).toSet(),
    created: DateTime.utc(2026),
    modified: DateTime.utc(2026),
    bounds: const math.Rectangle(0, 0, 400, 300),
  );
}

FSA _renamedAndReordered(FSA source) {
  final originalStates = source.states.toList()
    ..sort((left, right) => right.id.compareTo(left.id));
  final renamed = <State, State>{};
  for (var index = 0; index < originalStates.length; index++) {
    final original = originalStates[index];
    renamed[original] = State(
      id: 'renamed_$index',
      label: 'r$index',
      position: Vector2(index * 40, 0),
      isInitial: original == source.initialState,
      isAccepting: source.acceptingStates.contains(original),
    );
  }
  final originalTransitions = source.fsaTransitions.toList()
    ..sort((left, right) => right.id.compareTo(left.id));
  final transitions = <FSATransition>{};
  for (var index = 0; index < originalTransitions.length; index++) {
    final original = originalTransitions[index];
    transitions.add(
      original.isEpsilonTransition && !original.consumesInput
          ? FSATransition.epsilon(
              id: 'renamed_transition_$index',
              fromState: renamed[original.fromState]!,
              toState: renamed[original.toState]!,
            )
          : FSATransition(
              id: 'renamed_transition_$index',
              fromState: renamed[original.fromState]!,
              toState: renamed[original.toState]!,
              inputSymbols: {...original.inputSymbols},
            ),
    );
  }
  return FSA(
    id: '${source.id}-renamed',
    name: '${source.name} renamed',
    states: renamed.values.toSet(),
    transitions: transitions,
    alphabet: {...source.alphabet},
    initialState:
        source.initialState == null ? null : renamed[source.initialState],
    acceptingStates: {
      for (final state in source.acceptingStates) renamed[state]!,
    },
    created: DateTime.utc(2026),
    modified: DateTime.utc(2026),
    bounds: source.bounds,
  );
}

FSA _epsilonSymbolCycle() {
  final q0 = _state('q0', initial: true);
  final q1 = _state('q1', accepting: true);
  final q2 = _state('q2');
  return _fsa(
    id: 'epsilon-symbol-cycle',
    states: {q0, q1, q2},
    transitions: {
      FSATransition.epsilon(id: 'e0', fromState: q0, toState: q1),
      FSATransition.deterministic(
        id: 'a0',
        fromState: q1,
        toState: q2,
        symbol: 'a',
      ),
      FSATransition.epsilon(id: 'e1', fromState: q2, toState: q1),
    },
    alphabet: {'a'},
    initial: q0,
    accepting: {q1},
  );
}

FSA _epsilonOnlyCycle() {
  final q0 = _state('q0', initial: true, accepting: true);
  final q1 = _state('q1');
  return _fsa(
    id: 'epsilon-only-cycle',
    states: {q0, q1},
    transitions: {
      FSATransition.epsilon(id: 'e0', fromState: q0, toState: q1),
      FSATransition.epsilon(id: 'e1', fromState: q1, toState: q0),
    },
    alphabet: const {},
    initial: q0,
    accepting: {q0},
  );
}

FSA _exactWord(List<String> word, {required Set<String> alphabet}) {
  final states = <State>[
    for (var index = 0; index <= word.length; index++)
      _state(
        'q$index',
        initial: index == 0,
        accepting: index == word.length,
      ),
  ];
  return _fsa(
    id: 'exact-${word.join('-')}',
    states: states.toSet(),
    transitions: {
      for (var index = 0; index < word.length; index++)
        FSATransition.deterministic(
          id: 't$index',
          fromState: states[index],
          toState: states[index + 1],
          symbol: word[index],
        ),
    },
    alphabet: alphabet,
    initial: states.first,
    accepting: {states.last},
  );
}

FSA _endsWith(String symbol) {
  final other = symbol == 'a' ? 'b' : 'a';
  final q0 = _state('q0', initial: true);
  final q1 = _state('q1', accepting: true);
  return _fsa(
    id: 'ends-with-$symbol',
    states: {q0, q1},
    transitions: {
      _transition('t0', q0, q1, symbol),
      _transition('t1', q0, q0, other),
      _transition('t2', q1, q1, symbol),
      _transition('t3', q1, q0, other),
    },
    alphabet: {'a', 'b'},
    initial: q0,
    accepting: {q1},
  );
}

FSA _contains(String symbol) {
  final other = symbol == 'a' ? 'b' : 'a';
  final q0 = _state('q0', initial: true);
  final q1 = _state('q1', accepting: true);
  return _fsa(
    id: 'contains-$symbol',
    states: {q0, q1},
    transitions: {
      _transition('t0', q0, q1, symbol),
      _transition('t1', q0, q0, other),
      _transition('t2', q1, q1, symbol),
      _transition('t3', q1, q1, other),
    },
    alphabet: {'a', 'b'},
    initial: q0,
    accepting: {q1},
  );
}

FSA _redundantEndsWithA() {
  final q0 = _state('q0', initial: true);
  final q1 = _state('q1', accepting: true);
  final q2 = _state('q2');
  return _fsa(
    id: 'redundant-ends-a',
    states: {q0, q1, q2},
    transitions: {
      _transition('t0', q0, q1, 'a'),
      _transition('t1', q0, q2, 'b'),
      _transition('t2', q2, q1, 'a'),
      _transition('t3', q2, q2, 'b'),
      _transition('t4', q1, q1, 'a'),
      _transition('t5', q1, q2, 'b'),
    },
    alphabet: {'a', 'b'},
    initial: q0,
    accepting: {q1},
  );
}

bool _isComplete(FSA automaton) => automaton.states.every(
      (state) => automaton.alphabet.every(
        (symbol) =>
            automaton.getTransitionsFromStateOnSymbol(state, symbol).length ==
            1,
      ),
    );

String _automatonShape(FSA automaton) {
  final transitions = automaton.fsaTransitions
      .map(
        (transition) =>
            '${transition.fromState.id}:${transition.inputSymbols.toList()..sort()}:'
            '${transition.toState.id}',
      )
      .toList()
    ..sort();
  return jsonEncode({
    'accepting': automaton.acceptingStates.map((state) => state.id).toList()
      ..sort(),
    'initial': automaton.initialState?.id,
    'states': automaton.states.map((state) => state.id).toList()..sort(),
    'transitions': transitions,
  });
}

State _state(
  String id, {
  bool initial = false,
  bool accepting = false,
}) =>
    State(
      id: id,
      label: id,
      position: Vector2.zero(),
      isInitial: initial,
      isAccepting: accepting,
    );

FSATransition _transition(
  String id,
  State from,
  State to,
  String symbol,
) =>
    FSATransition.deterministic(
      id: id,
      fromState: from,
      toState: to,
      symbol: symbol,
    );

FSA _fsa({
  required String id,
  required Set<State> states,
  required Set<FSATransition> transitions,
  required Set<String> alphabet,
  required State initial,
  required Set<State> accepting,
}) =>
    FSA(
      id: id,
      name: id,
      states: states,
      transitions: transitions,
      alphabet: alphabet,
      initialState: initial,
      acceptingStates: accepting,
      created: DateTime.utc(2026),
      modified: DateTime.utc(2026),
      bounds: const math.Rectangle(0, 0, 400, 300),
    );

extension<T> on Iterable<T> {
  T? get firstOrNull {
    final iterator = this.iterator;
    return iterator.moveNext() ? iterator.current : null;
  }
}

final class MapEquality<K, V> {
  const MapEquality();

  bool equals(Map<K, V> left, Map<K, V> right) {
    if (left.length != right.length) return false;
    for (final entry in left.entries) {
      if (!right.containsKey(entry.key) || right[entry.key] != entry.value) {
        return false;
      }
    }
    return true;
  }
}
