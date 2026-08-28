import 'dart:convert';
import 'dart:io';

import 'package:turing_lab/core/algorithms/grammar_parser.dart';
import 'package:turing_lab/core/interoperability/interoperability.dart';
import 'package:turing_lab/core/models/fsa.dart';
import 'package:turing_lab/core/models/grammar.dart';
import 'package:turing_lab/core/models/grammar_parse_report.dart';
import 'package:turing_lab/core/models/production.dart';
import 'package:turing_lab/core/models/state.dart';
import 'package:vector_math/vector_math_64.dart';

import '../compatibility_corpus/catalog.dart';
import 'families/codec_parity.dart';
import 'families/codec_parity_vectors.dart';
import 'families/formal_systems_certification.dart';
import 'families/grammar_certification.dart';
import 'families/graph_family.dart';
import 'families/pda_family.dart';
import 'families/regular_certification.dart';
import 'families/regular_oracles.dart';
import 'families/tm_certification.dart';
import 'oracles.dart';

enum CrossFamilyEquivalence {
  exact,
  normalized,
  isomorphic,
  visual,
  bounded,
}

enum CrossFamilyOutcome { verified, different, boundedUnknown }

final class CrossFamilyObservation {
  const CrossFamilyObservation({
    required this.id,
    required this.families,
    required this.equivalence,
    required this.outcome,
    required this.properties,
    required this.evidence,
  });

  final String id;
  final List<String> families;
  final CrossFamilyEquivalence equivalence;
  final CrossFamilyOutcome outcome;
  final List<String> properties;
  final Map<String, Object?> evidence;

  bool get certified => outcome == CrossFamilyOutcome.verified;

  Map<String, Object?> toJson() => {
        'certified': certified,
        'equivalence': equivalence.name,
        'evidence': evidence,
        'families': families,
        'id': id,
        'outcome': outcome.name,
        'properties': properties,
      };
}

final class CrossFamilyCertificationReport {
  CrossFamilyCertificationReport(Iterable<CrossFamilyObservation> observations)
      : observations = List.unmodifiable(observations);

  final List<CrossFamilyObservation> observations;

  bool matchesExpectedOutcomes(Map<String, CrossFamilyOutcome> expected) =>
      observations.length == expected.length &&
      observations.every((item) => expected[item.id] == item.outcome);

  int get certificationCount =>
      observations.where((item) => item.certified).length;

  int get inconclusiveCount => observations
      .where((item) => item.outcome == CrossFamilyOutcome.boundedUnknown)
      .length;

  Map<String, Object?> toJson() => {
        'certificationCount': certificationCount,
        'inconclusiveCount': inconclusiveCount,
        'observations': observations.map((item) => item.toJson()).toList(),
        'status': inconclusiveCount == 0 ? 'certified' : 'incomplete',
      };
}

abstract final class CrossFamilyCertification {
  static Future<CrossFamilyCertificationReport> run({int seed = 342}) async {
    final observations = <CrossFamilyObservation>[
      await _regular(seed),
      _cfgParsers(),
      _cfgBoundedUnknown(),
      await _cfgPda(seed),
      await _tmGrammar(seed),
      await _tmRuntime(seed),
      await _transducers(seed),
      await _transducerBoundedUnknown(seed),
      _codecFsaSemantic(),
      _codecFsaIsomorphism(),
      _codecFsaVisual(),
      _pumpingSession(),
      _snapshotHistory(seed),
    ];
    return CrossFamilyCertificationReport(observations);
  }

  static Future<CrossFamilyObservation> _regular(int seed) async {
    final runner =
        RegularCertificationRunner(repositoryRoot: Directory.current);
    final options = RegularCertificationOptions(seed: seed, cases: 2);
    const properties = [
      'regular.determinization',
      'regular.completion',
      'regular.minimization',
      'regular.fa-regex-roundtrip',
      'regular.grammar-roundtrip',
      'regular.trace-replay',
      'regular.resource-outcomes',
    ];
    final checks = [
      for (final property in properties)
        await runner.runProperty(property, options),
    ];

    final codecFsa = _decodeVector<FSA>('fsa.turing-lab-json.v1');
    final withUnreachable = codecFsa.copyWith(
      states: {
        ...codecFsa.states,
        State(
          id: 'cross-family-unreachable',
          label: 'unreachable',
          position: Vector2(500, 500),
        ),
      },
    );
    final baseSignature = regularLanguageSignature(
      codecFsa,
      codecFsa.alphabet,
      const RegularOracleBudget(maximumWordLength: 4),
    );
    final unreachableSignature = regularLanguageSignature(
      withUnreachable,
      withUnreachable.alphabet,
      const RegularOracleBudget(maximumWordLength: 4),
    );
    final unreachablePreserved = baseSignature
            is OracleDefinitive<Map<String, bool>, RegularOracleEvidence> &&
        unreachableSignature
            is OracleDefinitive<Map<String, bool>, RegularOracleEvidence> &&
        _canonical(baseSignature.value) ==
            _canonical(unreachableSignature.value);
    final passed = checks.every(
          (check) => check.status == RegularCertificationStatus.passed,
        ) &&
        unreachablePreserved;
    return CrossFamilyObservation(
      id: 'regular-conversion-metamorphism',
      families: const ['regular', 'grammar', 'regex'],
      equivalence: CrossFamilyEquivalence.bounded,
      outcome:
          passed ? CrossFamilyOutcome.verified : CrossFamilyOutcome.different,
      properties: const [
        'renaming',
        'order',
        'roundtrip',
        'unreachable',
        'idempotence',
        'trace',
        'stale',
        'cancel',
      ],
      evidence: {
        'checks': checks.map((check) => check.toJson()).toList(),
        'unreachableStatePreservedBoundedLanguage': unreachablePreserved,
      },
    );
  }

  static CrossFamilyObservation _cfgParsers() {
    final grammar = _parserGrammar();
    const inputs = ['aab', 'aa'];
    final parserOutcomes = <String, Object?>{};
    var agrees = true;
    for (final input in inputs) {
      final oracle = independentBoundedDerives(grammar, input);
      if (!oracle.definitive) agrees = false;
      for (final strategy in ParsingStrategyHint.values) {
        final parsed = GrammarParser.parseWithReport(
          grammar,
          input,
          strategyHint: strategy,
          maxSteps: 10000,
          maxStates: 1000,
          maxItems: 10000,
        );
        final report = parsed.data;
        parserOutcomes['${strategy.name}:$input'] = report?.outcome.name;
        agrees = agrees &&
            report != null &&
            (report.outcome == GrammarParseOutcome.accepted ||
                report.outcome == GrammarParseOutcome.rejected) &&
            report.accepted == oracle.accepted;
      }
    }
    return CrossFamilyObservation(
      id: 'cfg-parser-differential',
      families: const ['cfg', 'earley', 'cyk', 'll1', 'lr1', 'brute-force'],
      equivalence: CrossFamilyEquivalence.exact,
      outcome:
          agrees ? CrossFamilyOutcome.verified : CrossFamilyOutcome.different,
      properties: const ['order', 'trace'],
      evidence: {'parserOutcomes': parserOutcomes},
    );
  }

  static CrossFamilyObservation _cfgBoundedUnknown() {
    final grammar = _parserGrammar();
    final parser = GrammarParser.parseWithReport(grammar, 'aab').data!;
    final oracle = independentBoundedDerives(
      grammar,
      'aab',
      maxDepth: 0,
      maxForms: 1,
    );
    final assessment = assessGrammarParserDifferential(
      oracle,
      parserAccepted: parser.accepted,
    );
    final preserved = !assessment.definitive &&
        assessment.outcome == GrammarCertificationOutcome.boundedUnknown;
    return CrossFamilyObservation(
      id: 'cfg-parser-bounded-oracle',
      families: const ['cfg', 'parser-oracle'],
      equivalence: CrossFamilyEquivalence.bounded,
      outcome: preserved
          ? CrossFamilyOutcome.boundedUnknown
          : CrossFamilyOutcome.different,
      properties: const ['bounded'],
      evidence: {
        'oracleOutcome': oracle.outcome.name,
        'parserOutcome': parser.outcome.name,
        'definitive': assessment.definitive,
      },
    );
  }

  static Future<CrossFamilyObservation> _cfgPda(int seed) async {
    final fixture = materializePdaPropertyFixture(
      property: 'compound-conversions',
      seed: seed,
    );
    final check = await const PdaCertificationRunner().runProperty(
      property: 'compound-conversions',
      fixture: fixture,
    );
    return CrossFamilyObservation(
      id: 'cfg-pda-conversion-chain',
      families: const ['cfg', 'pda'],
      equivalence: CrossFamilyEquivalence.bounded,
      outcome: check.status == PdaCertificationStatus.passed
          ? CrossFamilyOutcome.verified
          : CrossFamilyOutcome.different,
      properties: const ['roundtrip', 'cancel', 'bounded'],
      evidence: check.toJson(),
    );
  }

  static Future<CrossFamilyObservation> _tmGrammar(int seed) async {
    final check = await TmCertificationRunner(repositoryRoot: Directory.current)
        .runProperty(
      'tm.grammar-conversion',
      TmCertificationOptions(seed: seed, cases: 1),
    );
    return CrossFamilyObservation(
      id: 'tm-unrestricted-grammar-chain',
      families: const ['tm', 'unrestricted-grammar'],
      equivalence: CrossFamilyEquivalence.bounded,
      outcome: check.status == TmCertificationStatus.passed
          ? CrossFamilyOutcome.verified
          : CrossFamilyOutcome.different,
      properties: const ['roundtrip', 'bounded'],
      evidence: check.toJson(),
    );
  }

  static Future<CrossFamilyObservation> _tmRuntime(int seed) async {
    final check = await TmCertificationRunner(repositoryRoot: Directory.current)
        .runProperty(
      'tm.runner-parity',
      TmCertificationOptions(seed: seed, cases: 1),
    );
    return CrossFamilyObservation(
      id: 'tm-native-sync-web-parity',
      families: const ['tm-sync', 'tm-native', 'tm-web'],
      equivalence: CrossFamilyEquivalence.exact,
      outcome: check.status == TmCertificationStatus.passed
          ? CrossFamilyOutcome.verified
          : CrossFamilyOutcome.different,
      properties: const ['trace', 'cancel', 'batch'],
      evidence: check.toJson(),
    );
  }

  static Future<CrossFamilyObservation> _transducers(int seed) async {
    final report = await FormalSystemsCertification.run(
      FormalSystemsCertificationOptions(seedStart: seed, seedCount: 1),
    );
    const selected = {
      'transducer-mealy-oracle',
      'transducer-moore-oracle',
      'transducer-trace-async',
      'transducer-batch',
      'transducer-equivalence-exact',
      'transducer-resource-outcomes',
    };
    final records = report.records
        .where((record) => selected.contains(record.id))
        .toList(growable: false);
    final passed = records.length == selected.length &&
        records.every((record) =>
            record.passed &&
            record.actual == FormalSystemsCertificationOutcome.verified);
    return CrossFamilyObservation(
      id: 'transducer-differential-metamorphism',
      families: const ['mealy', 'moore', 'transducer-sync', 'transducer-async'],
      equivalence: CrossFamilyEquivalence.exact,
      outcome:
          passed ? CrossFamilyOutcome.verified : CrossFamilyOutcome.different,
      properties: const ['renaming', 'order', 'trace', 'batch', 'cancel'],
      evidence: {'records': records.map((record) => record.toJson()).toList()},
    );
  }

  static Future<CrossFamilyObservation> _transducerBoundedUnknown(
    int seed,
  ) async {
    final report = await FormalSystemsCertification.run(
      FormalSystemsCertificationOptions(
        seedStart: seed,
        seedCount: 1,
        caseFilter: 'transducer-equivalence-bounded',
      ),
    );
    final record = report.records.single;
    final preserved = record.passed &&
        record.actual == FormalSystemsCertificationOutcome.inconclusive;
    return CrossFamilyObservation(
      id: 'transducer-finite-evidence',
      families: const ['transducer-equivalence'],
      equivalence: CrossFamilyEquivalence.bounded,
      outcome: preserved
          ? CrossFamilyOutcome.boundedUnknown
          : CrossFamilyOutcome.different,
      properties: const ['bounded'],
      evidence: record.toJson(),
    );
  }

  static CrossFamilyObservation _codecFsaSemantic() {
    final jflap = _decodeVector<FSA>('fsa.jflap-xml.v1');
    final json = _decodeVector<FSA>('fsa.turing-lab-json.v1');
    final alphabet = {...jflap.alphabet, ...json.alphabet};
    final left = regularLanguageSignature(
      jflap,
      alphabet,
      const RegularOracleBudget(maximumWordLength: 4),
    );
    final right = regularLanguageSignature(
      json,
      alphabet,
      const RegularOracleBudget(maximumWordLength: 4),
    );
    final equal = left
            is OracleDefinitive<Map<String, bool>, RegularOracleEvidence> &&
        right is OracleDefinitive<Map<String, bool>, RegularOracleEvidence> &&
        _canonical(left.value) == _canonical(right.value);
    return CrossFamilyObservation(
      id: 'codec-jflap-json-normalized',
      families: const ['codec', 'jflap', 'turing-lab-json', 'regular'],
      equivalence: CrossFamilyEquivalence.normalized,
      outcome:
          equal ? CrossFamilyOutcome.verified : CrossFamilyOutcome.different,
      properties: const ['roundtrip'],
      evidence: {'boundedWordLength': 4, 'semanticSignaturesEqual': equal},
    );
  }

  static CrossFamilyObservation _codecFsaIsomorphism() {
    final jflap = _decodeVector<FSA>('fsa.jflap-xml.v1');
    final json = _decodeVector<FSA>('fsa.turing-lab-json.v1');
    final equal = _fsaTopology(jflap) == _fsaTopology(json);
    return CrossFamilyObservation(
      id: 'codec-jflap-json-isomorphic',
      families: const ['codec', 'jflap', 'turing-lab-json', 'regular'],
      equivalence: CrossFamilyEquivalence.isomorphic,
      outcome:
          equal ? CrossFamilyOutcome.verified : CrossFamilyOutcome.different,
      properties: const ['renaming', 'order'],
      evidence: {'topologyEqualIgnoringIdsAndOrder': equal},
    );
  }

  static CrossFamilyObservation _codecFsaVisual() {
    final jflap = _decodeVector<FSA>('fsa.jflap-xml.v1');
    final json = _decodeVector<FSA>('fsa.turing-lab-json.v1');
    final equal = _fsaVisual(jflap) == _fsaVisual(json);
    return CrossFamilyObservation(
      id: 'codec-jflap-json-visual',
      families: const ['codec', 'jflap', 'turing-lab-json', 'graph'],
      equivalence: CrossFamilyEquivalence.visual,
      outcome:
          equal ? CrossFamilyOutcome.verified : CrossFamilyOutcome.different,
      properties: const ['roundtrip'],
      evidence: {'labeledCoordinatesEqual': equal},
    );
  }

  static CrossFamilyObservation _pumpingSession() {
    const jsonCodecId = 'pumping-lemma.regular.turing-lab-json.v1';
    const jflapCodecId = 'pumping-lemma.regular.jflap.v1';
    final source = _decodeInteroperable(jsonCodecId);
    final jflapCodec = CompatibilityCodecCatalog.create().codecs[jflapCodecId]!;
    final encoded = jflapCodec.encode(source, filename: 'session.jff');
    InteroperableDocument<Object>? replay;
    if (encoded case CodecSuccess<EncodedDocument>()) {
      final decoded = jflapCodec.decode(
        DocumentPayload(
          bytes: encoded.value.bytes,
          filename: encoded.value.filename,
        ),
      );
      if (decoded case CodecSuccess<InteroperableDocument<Object>>()) {
        replay = decoded.value;
      }
    }
    final equal = replay != null &&
        _canonical(_jsonValue(source.document)) ==
            _canonical(_jsonValue(replay.document));
    return CrossFamilyObservation(
      id: 'codec-pumping-session-roundtrip',
      families: const ['codec', 'session', 'jflap', 'turing-lab-json'],
      equivalence: CrossFamilyEquivalence.normalized,
      outcome:
          equal ? CrossFamilyOutcome.verified : CrossFamilyOutcome.different,
      properties: const ['roundtrip', 'idempotence'],
      evidence: {
        'conversion': '$jsonCodecId->$jflapCodecId',
        'normalizedSessionEqual': equal,
      },
    );
  }

  static CrossFamilyObservation _snapshotHistory(int seed) {
    final fixture = graphHardEdgeFixture(
      property: 'graph.event-history-replay',
      seed: seed,
    );
    final first = graphEventHistoryReplay(fixture);
    final second = graphEventHistoryReplay(fixture);
    final equal = first.failureSignature == null &&
        _canonical(first.toJson()) == _canonical(second.toJson());
    return CrossFamilyObservation(
      id: 'snapshot-history-replay',
      families: const ['snapshot', 'session-history', 'graph'],
      equivalence: CrossFamilyEquivalence.exact,
      outcome:
          equal ? CrossFamilyOutcome.verified : CrossFamilyOutcome.different,
      properties: const ['roundtrip', 'trace', 'idempotence'],
      evidence: first.toJson(),
    );
  }
}

T _decodeVector<T>(String codecId) {
  final document = _decodeInteroperable(codecId).document;
  if (document is T) return document as T;
  throw StateError('$codecId decoded ${document.runtimeType}, not $T.');
}

InteroperableDocument<Object> _decodeInteroperable(String codecId) {
  final vector = codecParityVectors.singleWhere(
    (candidate) => candidate.codecId == codecId,
  );
  final codec = CompatibilityCodecCatalog.create().codecs[codecId]!;
  final payload =
      DocumentPayload(bytes: vector.payload, filename: vector.filename);
  if (codecCanonicalOutcomeSha256(codec, payload) !=
      vector.nativeOutcomeSha256) {
    throw StateError('$codecId diverged from its native canonical outcome.');
  }
  final decoded = codec.decode(payload);
  if (decoded case CodecSuccess<InteroperableDocument<Object>>()) {
    return decoded.value;
  }
  throw StateError('$codecId returned ${decoded.runtimeType}.');
}

Grammar _parserGrammar() => Grammar(
      id: 'cross-family-parser',
      name: 'Cross-family parser grammar',
      terminals: const {'a', 'b'},
      nonterminals: const {'S', 'U'},
      startSymbol: 'S',
      productions: {
        const Production(
          id: 's-recursive',
          leftSide: ['S'],
          rightSide: ['a', 'S'],
        ),
        const Production(id: 's-end', leftSide: ['S'], rightSide: ['b']),
        const Production(
          id: 'u-unreachable',
          leftSide: ['U'],
          rightSide: ['a'],
        ),
      },
      type: GrammarType.contextFree,
      created: DateTime.utc(2026, 8, 26),
      modified: DateTime.utc(2026, 8, 26),
    );

String _fsaTopology(FSA fsa) {
  final states = fsa.states
      .map((state) => '${state.label}:${state.isInitial}:${state.isAccepting}')
      .toList()
    ..sort();
  final transitions = fsa.fsaTransitions
      .map((transition) =>
          '${transition.fromState.label}->${transition.toState.label}:'
          '${(transition.inputSymbols.toList()..sort()).join(',')}')
      .toList()
    ..sort();
  return jsonEncode({'states': states, 'transitions': transitions});
}

String _fsaVisual(FSA fsa) {
  final states = fsa.states
      .map((state) => '${state.label}:${state.position.x}:${state.position.y}:'
          '${state.isInitial}:${state.isAccepting}')
      .toList()
    ..sort();
  return jsonEncode(states);
}

Object? _jsonValue(Object value) {
  try {
    return (value as dynamic).toJson();
  } on NoSuchMethodError {
    return value.toString();
  }
}

String _canonical(Object? value) => jsonEncode(_canonicalize(value));

Object? _canonicalize(Object? value) {
  if (value is Map) {
    final entries = value.entries.toList()
      ..sort(
          (left, right) => left.key.toString().compareTo(right.key.toString()));
    return {
      for (final entry in entries)
        entry.key.toString(): _canonicalize(entry.value),
    };
  }
  if (value is Set) {
    final result = value.map(_canonicalize).toList()
      ..sort((left, right) => jsonEncode(left).compareTo(jsonEncode(right)));
    return result;
  }
  if (value is Iterable) return value.map(_canonicalize).toList();
  return value;
}
