//
//  examples_roundtrip_test.dart
//  Turing Lab
//
//  Realiza testes de integração de round-trip para os exemplos embarcados, percorrendo leitura de
//  assets, serviços de serialização e exportação gráfica. Valida autômatos, gramáticas e máquinas
//  de Turing para garantir consistência entre entidades e artefatos gerados.
//
//  Thales Matheus Mendonça Santos - October 2025
//

import 'package:flutter_test/flutter_test.dart';
import 'dart:math' as math;

import 'package:turing_lab/core/entities/grammar_entity.dart';
import 'package:turing_lab/core/entities/turing_machine_entity.dart';
import 'package:turing_lab/core/models/fsa.dart';
import 'package:turing_lab/core/models/fsa_transition.dart';
import 'package:turing_lab/core/models/state.dart' as automata;
import 'package:turing_lab/data/data_sources/examples_asset_data_source.dart';
import 'package:turing_lab/presentation/widgets/export/svg_exporter.dart';
import 'package:flutter/material.dart';
import 'package:vector_math/vector_math_64.dart';

RegExp _viewBoxPattern(num width, num height) => RegExp(
      'viewBox="0 0 ${width.toInt()}(?:\\\\.0+)? ${height.toInt()}(?:\\\\.0+)?"',
    );

FSA _buildTestFsa({
  String id = 'test',
  String name = 'Test',
  bool includeStates = true,
  bool includeEpsilonLoop = false,
}) {
  final q0 = automata.State(
    id: 'q0',
    label: 'q0',
    position: Vector2.zero(),
    isInitial: true,
  );
  final q1 = automata.State(
    id: 'q1',
    label: 'q1',
    position: Vector2(120, 60),
    isAccepting: true,
  );
  final states = includeStates ? {q0, q1} : <automata.State>{};
  final transitions = <FSATransition>{};
  if (includeStates) {
    transitions.add(
      FSATransition(
        id: 't0',
        fromState: q0,
        toState: q1,
        inputSymbols: const {'a'},
      ),
    );
    if (includeEpsilonLoop) {
      transitions.add(
        FSATransition(
          id: 't1',
          fromState: q1,
          toState: q1,
          lambdaSymbol: 'ε',
        ),
      );
    }
  }

  return FSA(
    id: id,
    name: name,
    states: states,
    transitions: transitions,
    alphabet: const {'a', 'b'},
    initialState: includeStates ? q0 : null,
    acceptingStates: includeStates ? {q1} : <automata.State>{},
    created: DateTime(2025),
    modified: DateTime(2025),
    bounds: const math.Rectangle<double>(0, 0, 800, 600),
  );
}

TuringMachineEntity _buildSimpleTuringMachine() {
  const initialStateId = 'q0';
  const acceptingStateId = 'qAccept';

  final states = <TuringStateEntity>[
    _tmState(initialStateId, isInitial: true),
    _tmState(acceptingStateId, isAccepting: true),
  ];

  final transitions = <TuringTransitionEntity>[
    _tmTransition(
      id: 't0',
      from: initialStateId,
      to: acceptingStateId,
      read: 'a',
      write: 'a',
      direction: TuringMoveDirection.right,
    ),
  ];

  return TuringMachineEntity(
    id: 'tm_test',
    name: 'Test TM',
    inputAlphabet: const {'a'},
    tapeAlphabet: const {'a', '_'},
    blankSymbol: '_',
    states: states,
    transitions: transitions,
    initialStateId: initialStateId,
    acceptingStateIds: const {acceptingStateId},
    rejectingStateIds: const <String>{},
    nextStateIndex: states.length,
  );
}

TuringStateEntity _tmState(
  String id, {
  bool isInitial = false,
  bool isAccepting = false,
  bool isRejecting = false,
}) {
  return TuringStateEntity(
    id: id,
    name: id,
    isInitial: isInitial,
    isAccepting: isAccepting,
    isRejecting: isRejecting,
  );
}

TuringTransitionEntity _tmTransition({
  required String id,
  required String from,
  required String to,
  required String read,
  required String write,
  required TuringMoveDirection direction,
}) {
  return TuringTransitionEntity(
    id: id,
    fromStateId: from,
    toStateId: to,
    readSymbol: read,
    writeSymbol: write,
    moveDirection: direction,
  );
}

void main() {
  group('Examples v1 Library Tests', () {
    late ExamplesAssetDataSource dataSource;

    setUp(() {
      dataSource = ExamplesAssetDataSource();
    });

    group('Metadata and Structure', () {
      test('Provides correct category information', () {
        final categories = dataSource.getAvailableCategories();

        expect(categories, contains(ExampleCategory.dfa));
        expect(categories, contains(ExampleCategory.nfa));
        expect(categories, contains(ExampleCategory.cfg));
        expect(categories, contains(ExampleCategory.pda));
        expect(categories, contains(ExampleCategory.tm));
      });

      test('Provides example counts by category', () {
        final counts = dataSource.getExamplesCountByCategory();

        expect(counts[ExampleCategory.dfa], greaterThan(0));
        expect(counts.containsKey(ExampleCategory.cfg), isTrue);
        expect(counts[ExampleCategory.nfa], greaterThanOrEqualTo(0));
        expect(counts[ExampleCategory.tm], equals(5));
      });

      test('Search functionality works correctly', () {
        final searchResults = dataSource.searchExamples('dfa');

        expect(searchResults, isNotEmpty);
        expect(searchResults, contains('AFD - Termina com A'));
      });

      test('Example metadata is properly structured', () async {
        final result = await dataSource.loadTypedFsaExample(
          'AFD - Termina com A',
        );

        expect(result.isSuccess, isTrue, reason: result.error);
        final example = result.data!;
        expect(example.name, equals('AFD - Termina com A'));
        expect(example.category, ExampleCategory.dfa);
        expect(example.difficultyLevel, DifficultyLevel.easy);
        expect(example.complexityLevel, ExampleComplexityLevel.low);
        expect(example.tags, contains('dfa'));
      });
    });

    group('Metadata Logic', () {
      test('Difficulty level enum works correctly', () {
        expect(
          DifficultyLevel.values.map((value) => value.name),
          ['easy', 'medium', 'hard'],
        );
      });

      test('Complexity level enum works correctly', () {
        expect(
          ExampleComplexityLevel.values.map((value) => value.name),
          ['low', 'medium', 'high'],
        );
      });

      test('Example category enum works correctly', () {
        expect(
          ExampleCategory.values.map((value) => value.name),
          ['dfa', 'nfa', 'cfg', 'pda', 'tm'],
        );
      });

      test('Data source provides category information', () {
        final categories = dataSource.getAvailableCategories();

        expect(categories, contains(ExampleCategory.dfa));
        expect(categories, contains(ExampleCategory.cfg));
        expect(categories, contains(ExampleCategory.pda));
        expect(categories, contains(ExampleCategory.tm));
      });

      test('Data source provides category counts', () {
        final counts = dataSource.getExamplesCountByCategory();

        expect(counts[ExampleCategory.dfa], greaterThan(0));
        expect(counts.containsKey(ExampleCategory.cfg), isTrue);
        expect(counts.containsKey(ExampleCategory.pda), isTrue);
      });
    });

    group('Data Structure Tests', () {
      test('AssetExample exposes required metadata and typed payload',
          () async {
        final result = await dataSource.loadTypedCfgExample('GLC - Palíndromo');

        expect(result.isSuccess, isTrue, reason: result.error);
        final example = result.data!;
        expect(example.name, isNotEmpty);
        expect(example.description, isNotEmpty);
        expect(example.category, ExampleCategory.cfg);
        expect(example.difficultyLevel, isNotNull);
        expect(example.tags, isNotEmpty);
        expect(example.complexityLevel, isNotNull);
        expect(example.payload.productions, isNotEmpty);
      });

      test('example metadata enums remain locale-neutral', () {
        expect(DifficultyLevel.easy.name, 'easy');
        expect(ExampleComplexityLevel.low.name, 'low');
        expect(ExampleCategory.dfa.name, 'dfa');
      });

      test('ExamplesAssetDataSource provides metadata correctly', () {
        final dataSource = ExamplesAssetDataSource();

        final categories = dataSource.getAvailableCategories();
        expect(categories.length, equals(5)); // DFA, NFA, CFG, PDA, TM

        final counts = dataSource.getExamplesCountByCategory();
        expect(counts.isNotEmpty, isTrue);

        final searchResults = dataSource.searchExamples('dfa');
        expect(searchResults, isNotEmpty);
      });

      test('ExamplesAssetDataSource loads all TM examples from assets',
          () async {
        final result = await dataSource.loadAllTypedTmExamples();

        expect(result.isSuccess, isTrue);
        expect(result.data, isNotNull);
        expect(result.data!, hasLength(5));
        expect(
          result.data!.map((example) => example.name),
          containsAll(<String>[
            'MT - a^n b^n',
            'MT - Binário para unário',
            'MT - Cópia de string',
            'MT - Incremento binário',
            'MT - Verificador de palíndromo',
          ]),
        );
      });

      test('ExamplesAssetDataSource provides query methods correctly', () {
        final categories = dataSource.getAvailableCategories();
        expect(categories, contains(ExampleCategory.dfa));

        final counts = dataSource.getExamplesCountByCategory();
        expect(counts.isNotEmpty, isTrue);
      });
    });

    group('Typed Asset Catalog', () {
      test('Loads current model payloads from bundled JSON examples', () async {
        final fsaResult = await dataSource.loadAllTypedFsaExamples();
        final cfgResult = await dataSource.loadAllTypedCfgExamples();
        final pdaResult = await dataSource.loadAllTypedPdaExamples();
        final tmResult = await dataSource.loadAllTypedTmExamples();

        expect(fsaResult.isSuccess, isTrue);
        expect(cfgResult.isSuccess, isTrue);
        expect(pdaResult.isSuccess, isTrue);
        expect(tmResult.isSuccess, isTrue);

        expect(fsaResult.data, hasLength(4));
        expect(cfgResult.data, hasLength(2));
        expect(pdaResult.data, hasLength(3));
        expect(tmResult.data, hasLength(5));

        expect(
          fsaResult.data!.every((example) => example.payload.states.isNotEmpty),
          isTrue,
        );
        expect(
          cfgResult.data!.every(
            (example) => example.payload.productions.isNotEmpty,
          ),
          isTrue,
        );
        expect(
          pdaResult.data!.every(
            (example) => example.payload.transitions.isNotEmpty,
          ),
          isTrue,
        );
        expect(
          tmResult.data!.every(
            (example) => example.payload.transitions.isNotEmpty,
          ),
          isTrue,
        );

        final lambdaFsa = await dataSource.loadTypedFsaExample(
          'AFNλ - A ou AB',
        );
        expect(lambdaFsa.isSuccess, isTrue);
        expect(lambdaFsa.data!.category, ExampleCategory.nfa);
        expect(lambdaFsa.data!.payload.epsilonTransitions, isNotEmpty);
        expect(lambdaFsa.data!.payload.validate(), isEmpty);

        final palindromeGrammar = cfgResult.data!.firstWhere(
          (example) => example.name == 'GLC - Palíndromo',
        );
        expect(
          palindromeGrammar.payload.productions.any(
            (production) =>
                production.leftSide.single == 'S' &&
                production.rightSide.length == 3 &&
                production.rightSide[0] == 'a' &&
                production.rightSide[1] == 'S' &&
                production.rightSide[2] == 'a',
          ),
          isTrue,
        );
        expect(palindromeGrammar.payload.validate(), isEmpty);

        final pda = pdaResult.data!
            .firstWhere((example) => example.name == 'APD - Palíndromo')
            .payload;
        expect(pda.initialStackSymbol, equals('Z'));
        expect(
          pda.pdaTransitions.any((transition) => transition.pushSymbol == 'aZ'),
          isTrue,
        );
        expect(
          pda.pdaTransitions.any((transition) => transition.isLambdaInput),
          isTrue,
        );

        expect(
          tmResult.data!.every((example) => example.payload.validate().isEmpty),
          isTrue,
        );
        expect(
          tmResult.data!.any(
            (example) => example.payload.rightMovingTransitions.isNotEmpty,
          ),
          isTrue,
        );
      });

      test('Typed loaders reject category mismatches', () async {
        final result = await dataSource.loadTypedTmExample('GLC - Palíndromo');

        expect(result.isFailure, isTrue);
        expect(result.error, contains('belongs to CFG'));
      });
    });

    group('SVG Export Tests', () {
      test('Automaton SVG export produces valid SVG structure', () {
        final svg = SvgExporter.exportFsaToSvg(_buildTestFsa());

        // Verify SVG structure
        expect(svg, contains('<?xml'));
        expect(svg, contains('<svg'));
        expect(svg, contains('viewBox'));
        expect(svg, contains('</svg>'));

        // Verify SVG content
        expect(svg, contains('<circle')); // State circles
        expect(svg, contains('<line')); // Transitions
        expect(svg, contains('<text')); // Labels

        // Verify styles are included
        expect(svg, contains('<defs>'));
        expect(svg, contains('<marker'));
        expect(svg, contains('<style>'));
      });

      test('Turing machine SVG export produces detailed TM diagram', () {
        final svg = SvgExporter.exportTuringMachineToSvg(
          _buildSimpleTuringMachine(),
          options: const SvgExportOptions(includeLegend: true),
        );

        // Structural scaffolding
        expect(svg, contains('<?xml'));
        expect(svg, contains('<svg'));
        expect(svg, contains('</svg>'));
        expect(svg, contains(_viewBoxPattern(800, 600)));

        // Tape layout
        expect(
          svg,
          contains(
            RegExp(
              r'<g class="tape">[\s\S]*<rect class="tape-cell"[\s\S]*</g>',
            ),
          ),
        );
        expect(
          svg,
          contains(
            RegExp(
              r'<text x="[^"]+" y="[^"]+" class="tape-symbol" fill="#000000">a</text>',
            ),
          ),
        );
        expect(
          svg,
          contains(
            RegExp(
              r'<text x="[^"]+" y="[^"]+" class="tape-symbol" fill="#000000">_</text>',
            ),
          ),
        );

        // Head indicator pointing to the central tape cell
        expect(svg, contains('<polygon class="head"'));
        expect(
          svg,
          contains(
            RegExp(
              r'points="[\d.]+ [\d.]+, [\d.]+ [\d.]+, [\d.]+ [\d.]+"',
            ),
          ),
        );

        // State layout and labelling
        expect(svg, contains('<g class="state">'));
        expect(svg, contains('>q0<'));
        expect(svg, contains('>qAccept<'));
        expect(svg, contains('marker-end="url(#arrowhead)"'));

        // Transition labelling and legend description
        expect(svg, contains('a/a, R'));
        expect(svg, contains('<g class="legend">'));
        expect(
          svg,
          contains('δ(q, s) = (q′, w, d) — leitura/escrita/movimento'),
        );
      });

      test('Grammar SVG export produces valid structure', () {
        final svg = SvgExporter.exportGrammarToSvg(
          // Mock grammar entity for testing
          const GrammarEntity(
            id: 'test',
            name: 'Test Grammar',
            terminals: {'a'},
            nonTerminals: {'S'},
            startSymbol: 'S',
            productions: [],
          ),
        );

        // Verify SVG structure
        expect(svg, contains('<?xml'));
        expect(svg, contains('<svg'));
        expect(svg, contains('</svg>'));

        // Verify content (should contain automaton visualization)
        expect(svg, contains('<circle')); // State circles
        expect(svg, contains('<line')); // Transitions
      });

      test('SVG export options work correctly', () {
        const options = SvgExportOptions(
          includeTitle: true,
          includeLegend: false,
          scale: 1.5,
        );

        final svg = SvgExporter.exportFsaToSvg(
          _buildTestFsa(name: 'Test with Options', includeStates: false),
          options: options,
        );

        // Verify options are applied
        expect(svg, contains('Test with Options')); // Title included
        expect(svg, contains('class="title"')); // Title styling
        expect(svg, contains('No states defined'));
      });

      test('SVG export handles different sizes correctly', () {
        const smallSize = Size(400, 300);
        const largeSize = Size(1200, 900);

        final emptyFsa = _buildTestFsa(includeStates: false);

        final smallSvg = SvgExporter.exportFsaToSvg(
          emptyFsa,
          width: smallSize.width,
          height: smallSize.height,
        );

        final largeSvg = SvgExporter.exportFsaToSvg(
          emptyFsa,
          width: largeSize.width,
          height: largeSize.height,
        );

        // Verify viewBox is set correctly
        expect(smallSvg, contains(_viewBoxPattern(400, 300)));
        expect(largeSvg, contains(_viewBoxPattern(1200, 900)));

        // Both should be valid SVG
        expect(smallSvg, contains('<?xml'));
        expect(largeSvg, contains('<?xml'));
        expect(smallSvg, contains('No states defined'));
        expect(largeSvg, contains('No states defined'));
      });

      test('SVG export handles complex automata correctly', () {
        final svg = SvgExporter.exportFsaToSvg(
          _buildTestFsa(
            id: 'complex',
            name: 'Complex',
            includeEpsilonLoop: true,
          ),
        );

        // Verify complex structure is handled
        expect(svg, contains('<circle')); // Multiple states
        expect(svg, contains('<line')); // Multiple transitions
        expect(svg, contains('<text')); // Labels
        expect(svg, contains('>ε<'));

        // Should still be valid SVG
        expect(svg, contains('<?xml'));
        expect(svg, contains('<svg'));
        expect(svg, contains('</svg>'));
      });

      test('SVG export validates input parameters', () {
        // Test with zero size (should handle gracefully)
        final emptyFsa = _buildTestFsa(includeStates: false);

        final zeroSizeSvg = SvgExporter.exportFsaToSvg(
          emptyFsa,
          width: 0,
          height: 0,
        );

        // Should still produce valid SVG structure even with zero size
        expect(zeroSizeSvg, contains('<?xml'));
        expect(zeroSizeSvg, contains('<svg'));
        expect(zeroSizeSvg, contains('No states defined'));

        // Test with very large size
        final largeSizeSvg = SvgExporter.exportFsaToSvg(
          emptyFsa,
          width: 10000,
          height: 10000,
        );

        expect(largeSizeSvg, contains(_viewBoxPattern(10000, 10000)));
        expect(largeSizeSvg, contains('No states defined'));
      });

      test('SVG export includes proper styling and markers', () {
        final svg = SvgExporter.exportFsaToSvg(
          _buildTestFsa(includeStates: false),
        );

        // Verify SVG styling elements
        expect(svg, contains('<defs>'));
        expect(svg, contains('<marker')); // Arrow markers
        expect(svg, contains('<style>')); // CSS styles
        expect(svg, contains('class=')); // CSS classes

        // Verify specific styling
        expect(svg, contains('font-family'));
        expect(svg, contains('text-anchor'));
        expect(svg, contains('fill='));
        expect(svg, contains('stroke='));
        expect(svg, contains('No states defined'));
      });
    });
  });
}
