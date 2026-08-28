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
import 'package:turing_lab/core/algorithms/tm_block_dependency_analyzer.dart';
import 'package:turing_lab/core/algorithms/tm_block_execution_engine.dart';
import 'package:turing_lab/core/algorithms/tm_execution_analyzer.dart';
import 'package:turing_lab/core/formal_systems/formal_systems.dart';
import 'package:turing_lab/core/models/fsa.dart';
import 'package:turing_lab/core/models/grammar.dart';
import 'package:turing_lab/core/models/pda.dart';
import 'package:turing_lab/core/models/pda_transition.dart';
import 'package:turing_lab/core/models/regex_preset.dart';
import 'package:turing_lab/core/models/tm.dart';
import 'package:turing_lab/core/models/tm_building_blocks.dart';
import 'package:turing_lab/core/models/tm_execution_analysis.dart';
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

  final acceptingStateIds = pda.acceptingStates
      .map((state) => state.id)
      .toSet();
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
      expect(example.id, 'asset/afd_ends_with_a');
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

    test(
      'stable asset id and legacy display-name lookups are compatible',
      () async {
        final byLegacyName = await _expectLoaded<FSA>(
          dataSource.loadTypedFsaExample('AFD - Termina com A'),
        );
        final byStableId = await _expectLoaded<FSA>(
          dataSource.loadTypedFsaExample('asset/afd_ends_with_a'),
        );

        expect(byStableId.id, byLegacyName.id);
        expect(byStableId.name, byLegacyName.name);
        expect(byStableId.payload.id, byLegacyName.payload.id);
        expect(
          byStableId.payload.states.map((state) => state.id).toSet(),
          byLegacyName.payload.states.map((state) => state.id).toSet(),
        );
        expect(
          byStableId.payload.transitions
              .map((transition) => transition.id)
              .toSet(),
          byLegacyName.payload.transitions
              .map((transition) => transition.id)
              .toSet(),
        );
      },
    );

    test(
      'all legacy asset examples publish unique locale-neutral ids',
      () async {
        final examples = <AssetExample<Object>>[
          ...(await _expectLoadedList<FSA>(
            dataSource.loadAllTypedFsaExamples(),
          )).cast<AssetExample<Object>>(),
          ...(await _expectLoadedList<Grammar>(
            dataSource.loadAllTypedCfgExamples(),
          )).cast<AssetExample<Object>>(),
          ...(await _expectLoadedList<PDA>(
            dataSource.loadAllTypedPdaExamples(),
          )).cast<AssetExample<Object>>(),
          ...(await _expectLoadedList<TM>(dataSource.loadAllTypedTmExamples()))
              .where((example) => example.id.startsWith('asset/'))
              .cast<AssetExample<Object>>(),
          ...(await _expectLoadedList<RegexPreset>(
            dataSource.loadAllTypedRegexExamples(),
          )).cast<AssetExample<Object>>(),
        ];

        expect(examples, hasLength(29));
        expect(examples.map((example) => example.id).toSet(), hasLength(29));
        expect(
          examples.every((example) => example.id.startsWith('asset/')),
          isTrue,
        );
        expect(examples.every((example) => example.id != example.name), isTrue);
      },
    );

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

    test('loads five registered FSA examples', () async {
      final examples = await _expectLoadedList<FSA>(
        dataSource.loadAllTypedFsaExamples(),
      );

      expect(examples, hasLength(5));
      expect(
        examples.map((example) => example.name),
        contains('AFD - Contém AB'),
      );
      expect(
        examples.every((example) => example.payload.validate().isEmpty),
        isTrue,
      );
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

    test('loads five registered Grammar examples', () async {
      final examples = await _expectLoadedList<Grammar>(
        dataSource.loadAllTypedCfgExamples(),
      );

      expect(examples, hasLength(5));
      expect(
        examples.map((example) => example.name),
        containsAll([
          'GLC - a^n b^n',
          'GLC - Zeros em quantidade par',
          'GLC - Expressões aritméticas',
        ]),
      );
      expect(
        examples.every((example) => example.payload.validate().isEmpty),
        isTrue,
      );
    });

    test('loads all registered PDA examples as typed PDA payloads', () async {
      final examples = await _expectLoadedList<PDA>(
        dataSource.loadAllTypedPdaExamples(),
      );

      expect(examples, hasLength(5));
      expect(
        examples.map((example) => example.name),
        containsAll([
          'APD - Parênteses Balanceados',
          'APD - a^n b^n',
          'APD - Palíndromo',
          'APD - a^n b^2n',
          'APD - w#reverse(w)',
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

    test('new PDA examples recognize their intended languages', () async {
      final anb2n = (await _expectLoaded<PDA>(
        dataSource.loadTypedPdaExample('APD - a^n b^2n'),
      )).payload;
      final mirrored = (await _expectLoaded<PDA>(
        dataSource.loadTypedPdaExample('APD - w#reverse(w)'),
      )).payload;

      for (final word in ['', 'abb', 'aabbbb', 'aaabbbbbb']) {
        expect(_runPda(anb2n, word), isTrue, reason: word);
      }
      for (final word in ['a', 'ab', 'aabb', 'abbb']) {
        expect(_runPda(anb2n, word), isFalse, reason: word);
      }

      for (final word in ['#', 'a#a', 'ab#ba', 'aab#baa']) {
        expect(_runPda(mirrored, word), isTrue, reason: word);
      }
      for (final word in ['', 'a#b', 'ab#ab', 'ab#baa']) {
        expect(_runPda(mirrored, word), isFalse, reason: word);
      }
    });

    test('loads all registered Regex examples as typed presets', () async {
      final examples = await _expectLoadedList<RegexPreset>(
        dataSource.loadAllTypedRegexExamples(),
      );

      expect(examples, hasLength(5));
      expect(
        examples.map((example) => example.name),
        containsAll([
          'Regex - Repetição de A',
          'Regex - Termina com AB',
          'Regex - Binário iniciado por 0',
          'Regex - Pares AB ou BA',
          'Regex - Blocos de A e B',
        ]),
      );
      expect(
        examples.every(
          (example) =>
              example.category == ExampleCategory.regex &&
              example.payload.expression.isNotEmpty &&
              example.payload.alphabet.isNotEmpty,
        ),
        isTrue,
      );
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

      expect(examples, hasLength(10));
      expect(
        examples.map((example) => example.name),
        containsAll([
          'MT - a^n b^n',
          'MT - Binário para unário',
          'MT - Cópia de string',
          'MT - Incremento binário',
          'MT - Verificador de palíndromo',
          'MT multifitas - Cópia em duas fitas',
          'MT multifitas - Comparação',
          'MT multifitas - Palíndromo',
          'MT multifitas - Fita de trabalho',
          'TM - Reusable building blocks',
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

      final blocks = examples
          .firstWhere(
            (example) => example.name == 'TM - Reusable building blocks',
          )
          .payload;
      expect(
        blocks.blockDefinitions.keys,
        containsAll(['scan', 'rewind', 'copy', 'compare', 'composition']),
      );
      final project = TMBlockProject.fromFlatMachine(blocks);
      expect(TMBlockDependencyAnalyzer.analyze(project).isValid, isTrue);
      final execution = TMBlockExecutionEngine.execute(project, '010');
      expect(execution.outcome, TMExecutionOutcome.accepted);
      expect(execution.metrics.maximumCallDepth, 2);
    });

    test('multi-tape examples recognize representative inputs', () async {
      final examples = await _expectLoadedList<TM>(
        dataSource.loadAllTypedTmExamples(),
      );
      TM named(String name) =>
          examples.firstWhere((example) => example.name == name).payload;
      Future<TMExecutionOutcome> run(String name, String input) async =>
          (await TMExecutionAnalyzer.analyze(
            named(name),
            input,
            maxSteps: 200,
            maxConfigurations: 1000,
          )).outcome;

      expect(
        await run('MT multifitas - Cópia em duas fitas', '0101'),
        TMExecutionOutcome.accepted,
      );
      expect(
        await run('MT multifitas - Comparação', '01#01'),
        TMExecutionOutcome.accepted,
      );
      expect(
        await run('MT multifitas - Comparação', '01#10'),
        TMExecutionOutcome.haltedRejected,
      );
      expect(
        await run('MT multifitas - Palíndromo', '0110'),
        TMExecutionOutcome.accepted,
      );
      expect(
        await run('MT multifitas - Palíndromo', '0100'),
        TMExecutionOutcome.haltedRejected,
      );
      expect(
        await run('MT multifitas - Fita de trabalho', '111'),
        TMExecutionOutcome.accepted,
      );
    });

    test(
      'loads a test-only module example catalog without central dispatch',
      () async {
        final registry = FormalSystemRegistry(
          modules: const [_ExampleSampleModule()],
          formats: const [],
        );
        final examples = await ExamplesAssetDataSource(
          registry: registry,
        ).loadRegisteredExamples(_exampleSampleKey);

        expect(examples, hasLength(1));
        expect(examples.single.name, 'Registered sample');
        expect(examples.single.payload, 'sample payload');
      },
    );
  });
}

const _exampleSampleKey = FormalSystemKey(
  type: FormalSystemTypeId('example-sample'),
  variant: FormalSystemVariantId('standard'),
);

class _ExampleSampleModule implements FormalSystemModule<Object> {
  const _ExampleSampleModule();

  @override
  FormalSystemDescriptor get descriptor => FormalSystemDescriptor(
    key: _exampleSampleKey,
    schema: const DocumentSchemaDescriptor(
      id: DocumentSchemaId('test.example-sample'),
      version: DocumentSchemaVersion(1),
    ),
    route: const WorkspaceRouteId('/example-sample'),
    category: FormalSystemCategory.learning,
    localizationNamespace: const CapabilityNamespaceId('test.example-sample'),
    semanticsNamespace: const CapabilityNamespaceId(
      'semantics.test.example-sample',
    ),
    capabilities: const FormalSystemCapabilities(
      examples: SupportedCapability(),
    ),
  );

  @override
  List<DocumentCodecCapability<Object>> get codecs => const [];

  @override
  List<ConversionCapability<Object, Object>> get conversions => const [];

  @override
  ExampleCatalogCapability<Object> get examples =>
      const _ExampleSampleCatalog();

  @override
  SessionCapability<Object>? get session => null;
}

class _ExampleSampleCatalog implements ExampleCatalogCapability<Object> {
  const _ExampleSampleCatalog();

  @override
  CapabilityNamespaceId get namespace =>
      const CapabilityNamespaceId('examples.test.example-sample');

  @override
  Future<List<AssetExample<Object>>> loadExamples() async => [
    AssetExample<Object>(
      name: 'Registered sample',
      description: 'A test-only registered example.',
      category: ExampleCategory.regex,
      difficultyLevel: DifficultyLevel.easy,
      complexityLevel: ExampleComplexityLevel.low,
      tags: ['test'],
      payload: 'sample payload',
    ),
  ];
}
