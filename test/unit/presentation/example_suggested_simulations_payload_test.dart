import 'package:flutter_test/flutter_test.dart';
import 'package:turing_lab/core/algorithms/fsa/automaton_simulator.dart';
import 'package:turing_lab/core/algorithms/grammar/grammar_parser.dart';
import 'package:turing_lab/core/algorithms/pda/pda_simulator.dart';
import 'package:turing_lab/core/algorithms/regex/regex_to_nfa_converter.dart';
import 'package:turing_lab/core/algorithms/tm/tm_block_execution_engine.dart';
import 'package:turing_lab/core/algorithms/tm/tm_execution_analyzer.dart';
import 'package:turing_lab/core/grammar/phrase_structure/phrase_structure.dart';
import 'package:turing_lab/core/models/tm_building_blocks.dart';
import 'package:turing_lab/core/models/tm_execution_analysis.dart';
import 'package:turing_lab/core/transducers/transducers.dart';
import 'package:turing_lab/data/data_sources/examples_asset_data_source.dart';
import 'package:turing_lab/data/grammar/unrestricted_grammar_example_catalog.dart';
import 'package:turing_lab/data/transducers/mealy_example_catalog.dart';
import 'package:turing_lab/data/transducers/moore_example_catalog.dart';
import 'package:turing_lab/core/models/fsa.dart';
import 'package:turing_lab/core/models/pda.dart';
import 'package:turing_lab/presentation/content/example_suggested_simulations.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  final source = ExamplesAssetDataSource();

  test(
    'finite-automaton commented inputs produce their conclusive outcome',
    () async {
      final examples = (await source.loadAllTypedFsaExamples()).data!;
      final covered = <String>{};

      for (final example in examples) {
        final entries = ExampleCounterexamples.resolve(example.id);
        expect(
          entries,
          isNotEmpty,
          reason: '${example.id} needs a counterexample',
        );
        expect(
          entries.any(
            (entry) =>
                entry.expectation == ExampleSimulationExpectation.rejected,
          ),
          isTrue,
          reason: '${example.id} needs a rejected input',
        );
        covered.add(example.id);
        for (final entry in entries) {
          final reason = '${example.id}: "${entry.input}"';
          final usesAlphabet = _usesAlphabet(entry.input, example.payload);
          final result = await AutomatonSimulator.simulate(
            example.payload,
            entry.input,
          );
          switch (entry.expectation) {
            case ExampleSimulationExpectation.accepted:
              expect(usesAlphabet, isTrue, reason: reason);
              expect(result.isSuccess, isTrue, reason: reason);
              expect(result.data!.accepted, isTrue, reason: reason);
            case ExampleSimulationExpectation.rejected:
              expect(usesAlphabet, isTrue, reason: reason);
              expect(result.isSuccess, isTrue, reason: reason);
              expect(result.data!.accepted, isFalse, reason: reason);
              expect(result.data!.isTimeout, isFalse, reason: reason);
              expect(result.data!.isInfiniteLoop, isFalse, reason: reason);
            case ExampleSimulationExpectation.invalidSymbol:
              expect(usesAlphabet, isFalse, reason: reason);
              final accepted = result.isSuccess && result.data!.accepted;
              expect(accepted, isFalse, reason: reason);
          }
        }
      }
      expect(
        ExampleCounterexamples.byExampleId.keys.where(
          (id) => id.startsWith('asset/af'),
        ),
        unorderedEquals(covered),
      );
    },
  );

  test(
    'pushdown-automaton commented inputs produce their conclusive outcome',
    () async {
      final examples = (await source.loadAllTypedPdaExamples()).data!;
      final covered = <String>{};

      for (final example in examples) {
        final entries = ExampleCounterexamples.resolve(example.id);
        expect(
          entries,
          isNotEmpty,
          reason: '${example.id} needs a counterexample',
        );
        expect(
          entries.any(
            (entry) =>
                entry.expectation == ExampleSimulationExpectation.rejected,
          ),
          isTrue,
          reason: '${example.id} needs a rejected input',
        );
        covered.add(example.id);
        for (final entry in entries) {
          final reason = '${example.id}: "${entry.input}"';
          final usesAlphabet = _usesAlphabet(entry.input, example.payload);
          final result = PDASimulator.simulate(example.payload, entry.input);
          expect(result.isSuccess, isTrue, reason: reason);
          final outcome = result.data!.outcome;
          switch (entry.expectation) {
            case ExampleSimulationExpectation.accepted:
              expect(usesAlphabet, isTrue, reason: reason);
              expect(outcome, PDASimulationOutcome.accepted, reason: reason);
            case ExampleSimulationExpectation.rejected:
              expect(usesAlphabet, isTrue, reason: reason);
              // Timeouts and exploration limits are inconclusive, never
              // evidence of rejection.
              expect(outcome, PDASimulationOutcome.rejected, reason: reason);
            case ExampleSimulationExpectation.invalidSymbol:
              expect(usesAlphabet, isFalse, reason: reason);
              expect(outcome, PDASimulationOutcome.rejected, reason: reason);
          }
        }
      }
      expect(
        ExampleCounterexamples.byExampleId.keys.where(
          (id) => id.startsWith('asset/apda'),
        ),
        unorderedEquals(covered),
      );
    },
  );

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

bool _usesAlphabet(String input, Object payload) {
  final alphabet = switch (payload) {
    final FSA fsa => fsa.alphabet,
    final PDA pda => pda.alphabet,
    _ => throw StateError('Unsupported payload'),
  };
  return input.runes.every(
    (rune) => alphabet.contains(String.fromCharCode(rune)),
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
