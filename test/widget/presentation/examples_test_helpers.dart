import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:turing_lab/core/models/fsa.dart';
import 'package:turing_lab/core/models/grammar.dart';
import 'package:turing_lab/core/models/pda.dart';
import 'package:turing_lab/core/models/regex_preset.dart';
import 'package:turing_lab/core/models/tm.dart';
import 'package:turing_lab/core/result.dart';
import 'package:turing_lab/data/data_sources/examples_asset_data_source.dart';

class TestExamplesRepository extends ExamplesAssetDataSource {
  late final List<AssetExample<FSA>> _fsa = [
    for (final name in const [
      'AFD - Termina com A',
      'AFD - Binário divisível por 3',
      'AFD - Paridade AB',
      'AFD - Contém AB',
    ])
      _example(name, ExampleCategory.dfa, FSA.empty(id: name, name: name)),
    _example(
      'AFNλ - A ou AB',
      ExampleCategory.nfa,
      FSA.empty(id: 'AFNλ - A ou AB', name: 'AFNλ - A ou AB'),
    ),
  ];
  late final List<AssetExample<Grammar>> _grammar = [
    for (final name in const [
      'GLC - Palíndromo',
      'GLC - Parênteses balanceados',
      'GLC - a^n b^n',
      'GLC - Zeros em quantidade par',
      'GLC - Expressões aritméticas',
    ])
      _example(
        name,
        ExampleCategory.cfg,
        Grammar.empty(id: name, name: name, type: GrammarType.contextFree),
      ),
  ];
  late final List<AssetExample<PDA>> _pda = [
    for (final name in const [
      'APD - Parênteses Balanceados',
      'APD - a^n b^n',
      'APD - Palíndromo',
      'APD - a^n b^2n',
      'APD - w#reverse(w)',
    ])
      _example(name, ExampleCategory.pda, PDA.empty(id: name, name: name)),
  ];
  late final List<AssetExample<TM>> _tm = [
    for (final name in const [
      'MT - a^n b^n',
      'MT - Binário para unário',
      'MT - Cópia de string',
      'MT - Incremento binário',
      'MT - Verificador de palíndromo',
    ])
      _example(name, ExampleCategory.tm, TM.empty(id: name, name: name)),
  ];
  late final List<AssetExample<RegexPreset>> _regex = [
    _regexExample('Regex - Repetição de A', 'a*', 'a'),
    _regexExample('Regex - Termina com AB', '(a|b)*ab', 'ab'),
    _regexExample('Regex - Binário iniciado por 0', '0(0|1)*', '01'),
    _regexExample('Regex - Pares AB ou BA', '(ab|ba)*', 'ab'),
    _regexExample('Regex - Blocos de A e B', 'a*b*', 'ab'),
  ];

  @override
  Future<Result<AssetExample<FSA>>> loadTypedFsaExample(String name) =>
      Future.value(_find(_fsa, name));

  @override
  Future<Result<AssetExample<Grammar>>> loadTypedCfgExample(String name) =>
      Future.value(_find(_grammar, name));

  @override
  Future<Result<AssetExample<PDA>>> loadTypedPdaExample(String name) =>
      Future.value(_find(_pda, name));

  @override
  Future<Result<AssetExample<TM>>> loadTypedTmExample(String name) =>
      Future.value(_find(_tm, name));

  @override
  Future<Result<AssetExample<RegexPreset>>> loadTypedRegexExample(
    String name,
  ) =>
      Future.value(_find(_regex, name));

  @override
  Future<ListResult<AssetExample<FSA>>> loadAllTypedFsaExamples() =>
      Future.value(Success(_fsa));

  @override
  Future<ListResult<AssetExample<Grammar>>> loadAllTypedCfgExamples() =>
      Future.value(Success(_grammar));

  @override
  Future<ListResult<AssetExample<PDA>>> loadAllTypedPdaExamples() =>
      Future.value(Success(_pda));

  @override
  Future<ListResult<AssetExample<TM>>> loadAllTypedTmExamples() =>
      Future.value(Success(_tm));

  @override
  Future<ListResult<AssetExample<RegexPreset>>> loadAllTypedRegexExamples() =>
      Future.value(Success(_regex));

  static AssetExample<T> _example<T>(
    String name,
    ExampleCategory category,
    T payload,
  ) {
    return AssetExample<T>(
      name: name,
      description: name,
      category: category,
      difficultyLevel: DifficultyLevel.easy,
      complexityLevel: ExampleComplexityLevel.low,
      tags: const ['test'],
      payload: payload,
    );
  }

  static AssetExample<RegexPreset> _regexExample(
    String name,
    String expression,
    String alphabet,
  ) {
    return _example(
      name,
      ExampleCategory.regex,
      RegexPreset(
        id: name,
        name: name,
        expression: expression,
        alphabet: alphabet,
      ),
    );
  }

  static Result<AssetExample<T>> _find<T>(
    List<AssetExample<T>> examples,
    String name,
  ) {
    for (final example in examples) {
      if (example.name == name) {
        return Success(example);
      }
    }
    return Failure('Example not found: $name');
  }
}

Future<void> pumpUntilFound(WidgetTester tester, Finder finder) async {
  for (var attempt = 0; attempt < 80; attempt++) {
    if (finder.evaluate().isNotEmpty) {
      return;
    }
    await tester.runAsync(
      () => Future<void>.delayed(const Duration(milliseconds: 10)),
    );
    await tester.pump();
  }

  final visibleText = tester
      .widgetList<Text>(find.byType(Text))
      .map((text) => text.data)
      .whereType<String>()
      .join(' | ');
  fail('Timed out waiting for $finder. Visible text: $visibleText');
}
