//
//  examples_asset_data_source_test.dart
//  Turing Lab
//
//  Validates the typed examples catalog loaded from assets/examples.
//
//  Thales Matheus Mendonça Santos - October 2025
//

import 'dart:collection';

import 'package:flutter_test/flutter_test.dart';
import 'package:turing_lab/core/models/fsa.dart';
import 'package:turing_lab/core/models/grammar.dart';
import 'package:turing_lab/core/models/pda.dart';
import 'package:turing_lab/core/models/pda_transition.dart';
import 'package:turing_lab/core/models/tm.dart';
import 'package:turing_lab/core/result.dart';
import 'package:turing_lab/data/data_sources/examples_asset_data_source.dart';

class _PdaConfiguration {
  const _PdaConfiguration({
    required this.state,
    required this.index,
    required this.stack,
  });

  final String state;
  final int index;
  final List<String> stack;
}

Future<AssetExample<T>> _expectLoaded<T>(
  Future<Result<AssetExample<T>>> future,
) async {
  final result = await future;
  expect(result.isSuccess, isTrue, reason: result.error);
  return result.data!;
}

Future<List<AssetExample<T>>> _expectLoadedList<T>(
  Future<ListResult<AssetExample<T>>> future,
) async {
  final result = await future;
  expect(result.isSuccess, isTrue, reason: result.error);
  return result.data!;
}

bool _runPda(PDA pda, String input) {
  final transitionsByState = <String, List<PDATransition>>{};
  for (final transition in pda.pdaTransitions) {
    transitionsByState
        .putIfAbsent(transition.fromState.id, () => [])
        .add(transition);
  }

  final initialState = pda.initialState;
  expect(initialState, isNotNull);

  final acceptingStateIds =
      pda.acceptingStates.map((state) => state.id).toSet();
  final queue = ListQueue<_PdaConfiguration>()
    ..add(
      _PdaConfiguration(
        state: initialState!.id,
        index: 0,
        stack: [pda.initialStackSymbol],
      ),
    );
  final visited = <String>{};

  while (queue.isNotEmpty) {
    final config = queue.removeFirst();
    final signature =
        '${config.state}|${config.index}|${config.stack.join(',')}';
    if (!visited.add(signature)) {
      continue;
    }

    if (config.index == input.length &&
        acceptingStateIds.contains(config.state)) {
      return true;
    }

    for (final transition in transitionsByState[config.state] ?? const []) {
      final nextStack = List<String>.from(config.stack);

      if (!transition.isLambdaPop) {
        if (nextStack.isEmpty || nextStack.last != transition.popSymbol) {
          continue;
        }
        nextStack.removeLast();
      }

      if (!transition.isLambdaInput) {
        if (config.index >= input.length ||
            input[config.index] != transition.inputSymbol) {
          continue;
        }
      }

      if (!transition.isLambdaPush) {
        for (var i = transition.pushSymbol.length - 1; i >= 0; i--) {
          nextStack.add(transition.pushSymbol[i]);
        }
      }

      queue.add(
        _PdaConfiguration(
          state: transition.toState.id,
          index: transition.isLambdaInput ? config.index : config.index + 1,
          stack: nextStack,
        ),
      );
    }
  }

  return false;
}

void main() {
  group('ExamplesAssetDataSource typed catalog', () {
    late ExamplesAssetDataSource dataSource;

    setUp(() {
      dataSource = ExamplesAssetDataSource();
    });

    test('loads DFA examples as typed FSA payloads with metadata', () async {
      final example = await _expectLoaded<FSA>(
        dataSource.loadTypedFsaExample('AFD - Termina com A'),
      );

      expect(example.name, 'AFD - Termina com A');
      expect(example.category, ExampleCategory.dfa);
      expect(example.difficultyLevel, DifficultyLevel.easy);
      expect(example.complexityLevel, ExampleComplexityLevel.low);
      expect(example.tags, containsAll(['dfa', 'basic']));

      final fsa = example.payload;
      expect(fsa.id, 'example_afd_ends_with_a');
      expect(fsa.name, example.name);
      expect(fsa.alphabet, {'a', 'b'});
      expect(fsa.states, hasLength(2));
      expect(fsa.fsaTransitions, hasLength(4));
      expect(fsa.initialState?.id, 'q0');
      expect(fsa.acceptingStates.map((state) => state.id), contains('q1'));
      expect(fsa.isDeterministic, isTrue);
      expect(fsa.validate(), isEmpty);
    });

    test('loads lambda NFA examples as typed FSA payloads', () async {
      final example = await _expectLoaded<FSA>(
        dataSource.loadTypedFsaExample('AFNλ - A ou AB'),
      );

      expect(example.category, ExampleCategory.nfa);
      expect(example.difficultyLevel, DifficultyLevel.medium);
      expect(example.payload.states, hasLength(5));
      expect(example.payload.epsilonTransitions, isNotEmpty);
      expect(example.payload.isDeterministic, isFalse);
      expect(example.payload.validate(), isEmpty);
    });

    test('loads CFG examples as typed Grammar payloads', () async {
      final example = await _expectLoaded<Grammar>(
        dataSource.loadTypedCfgExample('GLC - Parênteses balanceados'),
      );

      expect(example.category, ExampleCategory.cfg);
      expect(example.payload.terminals, {'(', ')'});
      expect(example.payload.nonterminals, {'S'});
      expect(example.payload.startSymbol, 'S');
      expect(example.payload.productionCount, 3);
      expect(
        example.payload.productions.any(
          (production) =>
              production.leftSide.single == 'S' &&
              production.rightSide.join() == '(S)',
        ),
        isTrue,
      );
      expect(
        example.payload.productions.any((production) => production.isLambda),
        isTrue,
      );
      expect(example.payload.validate(), isEmpty);
    });

    test('loads all registered PDA examples as typed PDA payloads', () async {
      final examples = await _expectLoadedList<PDA>(
        dataSource.loadAllTypedPdaExamples(),
      );

      expect(examples, hasLength(3));
      expect(
        examples.map((example) => example.name),
        containsAll([
          'APD - Parênteses Balanceados',
          'APD - a^n b^n',
          'APD - Palíndromo',
        ]),
      );

      for (final example in examples) {
        final pda = example.payload;
        expect(example.category, ExampleCategory.pda);
        expect(pda.states, isNotEmpty);
        expect(pda.pdaTransitions, isNotEmpty);
        expect(pda.stackAlphabet, contains(pda.initialStackSymbol));
        expect(pda.acceptingStates, isNotEmpty);
      }
    });

    test(
      'APD palindrome typed example accepts palindromes and rejects others',
      () async {
        final example = await _expectLoaded<PDA>(
          dataSource.loadTypedPdaExample('APD - Palíndromo'),
        );
        final pda = example.payload;

        expect(pda.initialStackSymbol, 'Z');
        expect(
          pda.pdaTransitions.any((transition) => transition.pushSymbol == 'aZ'),
          isTrue,
        );
        expect(
          pda.pdaTransitions.any((transition) => transition.isLambdaInput),
          isTrue,
        );

        const accepted = [
          '',
          'a',
          'b',
          'aa',
          'bb',
          'aba',
          'bab',
          'abba',
          'baab',
          'abbba',
          'ababa',
        ];
        const rejected = ['ab', 'ba', 'abb', 'aab', 'abbabb'];

        for (final word in accepted) {
          expect(
            _runPda(pda, word),
            isTrue,
            reason: 'Expected palindrome "$word" to be accepted.',
          );
        }

        for (final word in rejected) {
          expect(
            _runPda(pda, word),
            isFalse,
            reason: 'Expected non-palindrome "$word" to be rejected.',
          );
        }
      },
    );

    test('loads all registered TM examples as typed TM payloads', () async {
      final examples = await _expectLoadedList<TM>(
        dataSource.loadAllTypedTmExamples(),
      );

      expect(examples, hasLength(5));
      expect(
        examples.map((example) => example.name),
        containsAll([
          'MT - a^n b^n',
          'MT - Binário para unário',
          'MT - Cópia de string',
          'MT - Incremento binário',
          'MT - Verificador de palíndromo',
        ]),
      );

      final binaryToUnary = examples.firstWhere(
        (example) => example.name == 'MT - Binário para unário',
      );
      final tm = binaryToUnary.payload;
      expect(binaryToUnary.category, ExampleCategory.tm);
      expect(tm.tapeAlphabet, containsAll(['0', '1', 'X', 'B']));
      expect(tm.blankSymbol, 'B');
      expect(tm.states, hasLength(3));
      expect(tm.acceptingStates.map((state) => state.id), contains('q2'));
      expect(tm.tmTransitions, hasLength(6));
      expect(
        tm.tmTransitions.any(
          (transition) =>
              transition.readSymbol == '1' &&
              transition.writeSymbol == 'X' &&
              transition.movesRight,
        ),
        isTrue,
      );

      expect(
        examples.every((example) => example.payload.validate().isEmpty),
        isTrue,
      );
    });
  });
}
