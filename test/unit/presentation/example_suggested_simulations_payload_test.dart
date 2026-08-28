import 'package:flutter_test/flutter_test.dart';
import 'package:turing_lab/core/algorithms/automaton_simulator.dart';
import 'package:turing_lab/core/algorithms/grammar_parser.dart';
import 'package:turing_lab/core/algorithms/pda_simulator.dart';
import 'package:turing_lab/core/algorithms/regex_to_nfa_converter.dart';
import 'package:turing_lab/core/algorithms/tm_block_execution_engine.dart';
import 'package:turing_lab/core/algorithms/tm_execution_analyzer.dart';
import 'package:turing_lab/core/grammar/phrase_structure/phrase_structure.dart';
import 'package:turing_lab/core/models/tm_building_blocks.dart';
import 'package:turing_lab/core/models/tm_execution_analysis.dart';
import 'package:turing_lab/core/transducers/transducers.dart';
import 'package:turing_lab/data/data_sources/examples_asset_data_source.dart';
import 'package:turing_lab/data/grammar/unrestricted_grammar_example_catalog.dart';
import 'package:turing_lab/data/transducers/mealy_example_catalog.dart';
import 'package:turing_lab/data/transducers/moore_example_catalog.dart';
import 'package:turing_lab/presentation/content/example_suggested_simulations.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  final source = ExamplesAssetDataSource();

  test('finite-automaton suggestions are accepted by their payloads', () async {
    final examples = (await source.loadAllTypedFsaExamples()).data!;

    for (final example in examples) {
      for (final input in _suggestionsFor(example)) {
        final result = await AutomatonSimulator.simulate(
          example.payload,
          input,
        );
        expect(result.isSuccess, isTrue, reason: '${example.id}: $input');
        expect(result.data!.accepted, isTrue, reason: '${example.id}: $input');
      }
    }
  });

  test(
    'pushdown-automaton suggestions are accepted by their payloads',
    () async {
      final examples = (await source.loadAllTypedPdaExamples()).data!;

      for (final example in examples) {
        for (final input in _suggestionsFor(example)) {
          final result = PDASimulator.simulate(example.payload, input);
          expect(result.isSuccess, isTrue, reason: '${example.id}: $input');
          expect(
            result.data!.accepted,
            isTrue,
            reason: '${example.id}: $input',
          );
        }
      }
    },
  );

  test(
    'context-free grammar suggestions are derived by their payloads',
    () async {
      final examples = (await source.loadAllTypedCfgExamples()).data!;

      for (final example in examples) {
        for (final input in _suggestionsFor(example)) {
          final result = GrammarParser.parseWithReport(example.payload, input);
          expect(result.isSuccess, isTrue, reason: '${example.id}: $input');
          expect(
            result.data!.accepted,
            isTrue,
            reason: '${example.id}: $input',
          );
        }
      }
    },
  );

  test(
    'regular-expression suggestions are accepted by their payloads',
    () async {
      final examples = (await source.loadAllTypedRegexExamples()).data!;

      for (final example in examples) {
        final conversion = RegexToNFAConverter.convert(
          example.payload.expression,
        );
        expect(conversion.isSuccess, isTrue, reason: example.id);
        for (final input in _suggestionsFor(example)) {
          final result = await AutomatonSimulator.simulateNFA(
            conversion.data!,
            input,
          );
          expect(result.isSuccess, isTrue, reason: '${example.id}: $input');
          expect(
            result.data!.accepted,
            isTrue,
            reason: '${example.id}: $input',
          );
        }
      }
    },
  );

  test('Turing-machine suggestions are accepted by their payloads', () async {
    final examples = (await source.loadAllTypedTmExamples()).data!;

    for (final example in examples) {
      for (final input in _suggestionsFor(example)) {
        final outcome = example.id == 'tm-building-blocks-composition'
            ? TMBlockExecutionEngine.execute(
                TMBlockProject.fromFlatMachine(example.payload),
                input,
              ).outcome
            : (await TMExecutionAnalyzer.analyze(
                example.payload,
                input,
                maxSteps: 1000,
                maxConfigurations: 10000,
                includeTrace: false,
              )).outcome;
        expect(
          outcome,
          TMExecutionOutcome.accepted,
          reason: '${example.id}: $input',
        );
      }
    }
  });

  test('transducer suggestions complete against their payloads', () async {
    final examples = <AssetExample<DeterministicFiniteStateTransducer>>[
      ...await MealyExampleCatalog().loadExamples(),
      ...await MooreExampleCatalog().loadExamples(),
    ];

    for (final example in examples) {
      for (final input in _suggestionsFor(example)) {
        final word = TransducerInputWord.fromValues(
          _transducerTokens(input, example.payload.inputAlphabet),
        );
        final simulator = switch (example.payload) {
          final MealyMachine machine => DeterministicTransducerSimulator.mealy(
            machine,
          ),
          final MooreMachine machine => DeterministicTransducerSimulator.moore(
            machine,
          ),
          _ => throw StateError('Unsupported transducer payload'),
        };
        expect(
          simulator.run(word),
          isA<TransducerSuccess>(),
          reason: '${example.id}: $input',
        );
      }
    }
  });

  test(
    'unrestricted-grammar suggestions are derived by their payloads',
    () async {
      final examples = await const UnrestrictedGrammarExampleCatalog()
          .loadExamples();

      for (final example in examples) {
        final grammar = example.payload as UnrestrictedGrammar;
        for (final input in _suggestionsFor(example)) {
          final outcome = await BoundedDerivationSearch.run(
            grammar: grammar,
            input: GrammarSymbolSequence(
              input.runes.map(
                (rune) => TerminalGrammarSymbol(String.fromCharCode(rune)),
              ),
            ),
          );
          expect(
            outcome,
            isA<DerivationAccepted>(),
            reason: '${example.id}: $input',
          );
        }
      }
    },
  );
}

List<String> _suggestionsFor(AssetExample<Object> example) {
  final suggestions = ExampleSuggestedSimulations.resolve(example.id);
  expect(suggestions, isNotEmpty, reason: example.id);
  return suggestions;
}

List<String> _transducerTokens(
  String suggestion,
  Set<TransducerInputSymbol> alphabet,
) {
  if (suggestion.contains(' ')) {
    return suggestion.split(' ').where((token) => token.isNotEmpty).toList();
  }
  final tokenization = TransducerInputTokenizer.tokenize(suggestion, alphabet);
  expect(tokenization, isA<TransducerTokenizationSuccess>());
  return (tokenization as TransducerTokenizationSuccess).word.values;
}
