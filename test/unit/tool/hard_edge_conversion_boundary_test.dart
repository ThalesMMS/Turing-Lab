import 'dart:convert';
import 'dart:io';

import 'package:test/test.dart';
import 'package:turing_lab/core/algorithms/automaton_simulator.dart';
import 'package:turing_lab/core/algorithms/fa_to_regex_converter.dart';
import 'package:turing_lab/core/algorithms/fsa_to_grammar_converter.dart';
import 'package:turing_lab/core/algorithms/grammar_to_fsa_converter.dart';
import 'package:turing_lab/core/algorithms/grammar_to_pda/cfg_to_pda.dart';
import 'package:turing_lab/core/algorithms/grammar_to_pda_converter.dart';
import 'package:turing_lab/core/algorithms/pda_to_cfg_converter.dart';
import 'package:turing_lab/core/algorithms/regex_to_nfa_converter.dart';
import 'package:turing_lab/core/interoperability/interoperability.dart';
import 'package:turing_lab/core/models/fsa.dart';
import 'package:turing_lab/core/models/grammar.dart';

import '../../../tool/compatibility_corpus/catalog.dart';

void main() {
  late FSA fsa;
  late Grammar grammar;

  setUpAll(() {
    final catalog = CompatibilityCodecCatalog.create();
    fsa = _decode<FSA>(catalog, 'fsa.turing-lab-json.v1');
    grammar = _decode<Grammar>(catalog, 'grammar.turing-lab-json.v1');
  });

  test('FSA/regex composition is deterministic and bounded-equivalent',
      () async {
    final sourceBefore = jsonEncode(fsa.toJson());
    final first = FAToRegexConverter.convert(fsa);
    final second = FAToRegexConverter.convert(fsa);
    expect(first.isSuccess, isTrue);
    expect(second.data, first.data);
    expect(jsonEncode(fsa.toJson()), sourceBefore);

    final converted = RegexToNFAConverter.convert(first.data!);
    expect(converted.isSuccess, isTrue);
    expect(converted.data!.validate(), isEmpty);
    for (final input in const ['', 'a', 'aa']) {
      final source = await AutomatonSimulator.accepts(fsa, input);
      final target = await AutomatonSimulator.accepts(converted.data!, input);
      expect(source.isSuccess, isTrue);
      expect(target.data, source.data, reason: 'input=$input');
    }
  });

  test('FSA/regular-grammar composition preserves bounded behavior', () async {
    final sourceBefore = jsonEncode(fsa.toJson());
    final convertedGrammar = FSAToGrammarConverter.convert(fsa);
    expect(convertedGrammar.validate(), isEmpty);
    final convertedFsa = GrammarToFSAConverter.convert(convertedGrammar);
    expect(convertedFsa.isSuccess, isTrue);
    expect(convertedFsa.data!.validate(), isEmpty);
    expect(jsonEncode(fsa.toJson()), sourceBefore);
    for (final input in const ['', 'a', 'aa']) {
      final source = await AutomatonSimulator.accepts(fsa, input);
      final target =
          await AutomatonSimulator.accepts(convertedFsa.data!, input);
      expect(target.data, source.data, reason: 'input=$input');
    }
  });

  test('all CFG to PDA routes validate, preserve source, and expose provenance',
      () {
    final sourceBefore = jsonEncode(grammar.toJson());
    final general = GrammarToPDAConverter.convertGrammarToPDA(grammar);
    final standard = GrammarToPDAConverter.convertGrammarToPDAStandard(grammar);
    final greibach = GrammarToPDAConverter.convertGrammarToPDAGreibach(grammar);
    for (final result in [general, standard, greibach]) {
      expect(result.isSuccess, isTrue, reason: result.error);
      expect(result.data!.validate(), isEmpty);
    }

    final ll = CfgToPdaConverter.buildLl(grammar, sourceRevision: 7);
    final lr = CfgToPdaConverter.buildLr(grammar, sourceRevision: 7);
    for (final report in [ll, lr]) {
      expect(report.isCompleted, isTrue, reason: report.diagnostics.toString());
      expect(report.pda!.validate(), isEmpty);
      expect(report.steps, isNotEmpty);
      expect(report.transitionProvenance, isNotEmpty);
      expect(report.sourceRevision, 7);
    }
    expect(jsonEncode(grammar.toJson()), sourceBefore);

    final cancelled = PDAtoCFGConverter.convert(
      standard.data!,
      isCancelled: () => true,
    );
    expect(cancelled.isFailure, isTrue);
    expect(cancelled.error, PDAtoCFGConverter.cancellationError);
  });
}

T _decode<T extends Object>(
  CompatibilityCodecCatalog catalog,
  String codecId,
) {
  final codec = catalog.codecs[codecId]!;
  final fixture = File(codec.descriptor.canonicalFixtures.first);
  final outcome = codec.decode(
    DocumentPayload(
      bytes: fixture.readAsBytesSync(),
      filename: fixture.uri.pathSegments.last,
    ),
  );
  expect(outcome, isA<CodecSuccess<InteroperableDocument<Object>>>());
  return (outcome as CodecSuccess<InteroperableDocument<Object>>).value.document
      as T;
}
