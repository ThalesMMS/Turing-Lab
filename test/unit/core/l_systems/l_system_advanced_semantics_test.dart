import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:turing_lab/core/l_systems/l_systems.dart';
import 'package:turing_lab/data/l_systems/l_system_examples.dart';

void main() {
  group('advanced parallel rewriting', () {
    test('stochastic choices are reproducible for a document seed', () {
      final system = _system(
        seed: 42,
        axiom: const ['A', 'A', 'A', 'A'],
        productions: [
          _production('left', 'A', const ['L']),
          _production('right', 'A', const ['R']),
        ],
      );

      final first =
          const LSystemExpander().expand(system) as LSystemExpansionCompleted;
      final second =
          const LSystemExpander().expand(system) as LSystemExpansionCompleted;

      expect(second.finalGeneration.word, first.finalGeneration.word);
      expect(
        first.finalGeneration.provenance.map((run) => run.productionId),
        hasLength(4),
      );
    });

    test('seeded stochastic selection approximates production weights', () {
      final result = const LSystemExpander().expand(
        _system(
          seed: 352,
          axiom: List.filled(10000, 'A'),
          productions: [
            _production('rare', 'A', const ['X'], weight: 1),
            _production('common', 'A', const ['Y'], weight: 3),
          ],
        ),
      ) as LSystemExpansionCompleted;
      final common = result.finalGeneration.word.symbols
          .where((symbol) => symbol == 'Y')
          .length;

      expect(common / result.finalGeneration.word.length, closeTo(0.75, 0.02));
    });

    test('contexts match boundaries and ignore configured drawing symbols', () {
      final result = const LSystemExpander().expand(
        _system(
          axiom: const ['L', '+', 'A', '-', 'R', 'A'],
          ignoredContextSymbols: const {'+', '-'},
          productions: [
            _production(
              'context',
              'A',
              const ['C'],
              leftContext: const ['L'],
              rightContext: const ['R'],
            ),
          ],
        ),
      ) as LSystemExpansionCompleted;

      expect(
          result.finalGeneration.word.symbols, ['L', '+', 'C', '-', 'R', 'A']);
      expect(result.finalGeneration.provenance[2].productionId, 'context');
      expect(result.finalGeneration.provenance.last.productionId, isNull);
    });

    test('overlapping contexts read the source generation simultaneously', () {
      final result = const LSystemExpander().expand(
        _system(
          axiom: const ['A', 'A', 'A'],
          productions: [
            _production(
              'middle',
              'A',
              const ['X'],
              leftContext: const ['A'],
              rightContext: const ['A'],
            ),
          ],
        ),
      ) as LSystemExpansionCompleted;

      expect(result.finalGeneration.word.symbols, ['A', 'X', 'A']);
    });

    test('parametric rewriting remains an explicit preserved boundary', () {
      final outcome = const LSystemExpander().expand(
        _system(
          unsupportedVariants: const [LSystemUnsupportedVariant.parametric],
        ),
      ) as LSystemExpansionInvalid;

      expect(
        outcome.diagnostics.map((diagnostic) => diagnostic.subject),
        contains('parametric'),
      );
    });

    test('advanced productions and seed round-trip through canonical JSON', () {
      final system = _system(
        seed: 17,
        ignoredContextSymbols: const {'+', '-'},
        productions: [
          _production(
            'advanced',
            'A',
            const ['B'],
            leftContext: const ['L'],
            rightContext: const ['R'],
            weight: 2.5,
          ),
        ],
      );

      final decoded = LSystemDocument.fromJson(
        (jsonDecode(jsonEncode(system.toJson())) as Map)
            .cast<String, Object?>(),
      );

      expect(decoded.toJson(), system.toJson());
    });
  });

  group('advanced turtle commands', () {
    test('bundled advanced example expands and renders deterministically', () {
      final document = LSystemExamples.values
          .singleWhere(
            (example) => example.id == 'l-system.seeded-context-turtle',
          )
          .document;
      final expansion =
          const LSystemExpander().expand(document) as LSystemExpansionCompleted;
      final rendering = const LSystemTurtleInterpreter().interpret(
        expansion.finalGeneration.word,
        settings: document.turtle,
        mapping: document.commandMapping,
      ) as LSystemTurtleCompleted;

      expect(expansion.finalGeneration.word.symbols.first, 'L');
      expect(rendering.geometry.segmentCount, greaterThan(0));
      expect(
        expansion.finalGeneration.word.symbols,
        contains(startsWith('color(')),
      );
    });

    test('pitch and roll produce deterministic projected 3D geometry', () {
      final result = const LSystemTurtleInterpreter().interpret(
        LSystemWord(const ['g', '&', 'g', '/', 'g']),
        settings: LSystemTurtleSettings(angleDegrees: 90, stepLength: 2),
        mapping: LSystemCommandMapping.jflap,
      ) as LSystemTurtleCompleted;

      expect(result.geometry.segmentCount, 3);
      expect(
          result.geometry.segmentCoordinates.every((value) => value.isFinite),
          isTrue);
      expect(
          result.geometry.segmentCoordinates, isNot(everyElement(equals(0))));
    });

    test('width, color, hue, and polygon commands retain render styles', () {
      final result = const LSystemTurtleInterpreter().interpret(
        LSystemWord(const [
          'g',
          '!',
          'color(#ff0000)',
          'g',
          '{',
          'g',
          '+',
          'g',
          '}',
          '#',
          'g',
        ]),
        settings: LSystemTurtleSettings(
          angleDegrees: 90,
          stepLength: 2,
          lineWidth: 1,
          lineWidthIncrement: 2,
          hueIncrementDegrees: 120,
        ),
        mapping: LSystemCommandMapping.jflap,
      ) as LSystemTurtleCompleted;

      expect(result.geometry.segmentWidths.take(2), [1, 3]);
      expect(result.geometry.segmentColorsArgb[1], 0xffff0000);
      expect(result.geometry.segmentColorsArgb.last, isNot(0xffff0000));
      expect(result.geometry.polygons, hasLength(1));
      expect(result.geometry.polygons.single.coordinates.length,
          greaterThanOrEqualTo(6));
    });

    test('SVG emits per-segment styles and polygon geometry', () {
      final interpreted = const LSystemTurtleInterpreter().interpret(
        LSystemWord(
            const ['color(#336699)', '!', 'g', '{', 'g', '+', 'g', '}']),
        settings: LSystemTurtleSettings(
          angleDegrees: 90,
          lineWidthIncrement: 1.5,
        ),
        mapping: LSystemCommandMapping.jflap,
      ) as LSystemTurtleCompleted;
      final exported = const LSystemSvgExporter().encode(
        interpreted.geometry,
        metadata: LSystemRenderMetadata(
          documentId: 'advanced',
          sourceRevision: 1,
          generation: 2,
          settings: LSystemTurtleSettings(),
        ),
      );
      final svg = utf8.decode(exported.bytes);

      expect(svg, contains('#336699'));
      expect(svg, contains('stroke-width="2.5"'));
      expect(svg, contains('<polygon'));
    });

    test('invalid numeric arguments fail with a typed diagnostic', () {
      final result = const LSystemTurtleInterpreter().interpret(
        LSystemWord(const ['g(not-a-number)']),
        settings: LSystemTurtleSettings(),
        mapping: LSystemCommandMapping.jflap,
      ) as LSystemTurtleInvalid;

      expect(result.diagnostics.single.code,
          LSystemTurtleDiagnosticCode.invalidCommandArgument);
      expect(result.diagnostics.single.symbolIndex, 0);
    });

    test('assignments require values and preserve positive length contracts',
        () {
      final outcomes = [
        const ['angle'],
        const ['distance=0'],
        const ['lineIncrement(-1)'],
      ].map(
        (symbols) => const LSystemTurtleInterpreter().interpret(
          LSystemWord(symbols),
          settings: LSystemTurtleSettings(),
          mapping: LSystemCommandMapping.jflap,
        ) as LSystemTurtleInvalid,
      );

      expect(
        outcomes.map((outcome) => outcome.diagnostics.single.code),
        [
          LSystemTurtleDiagnosticCode.invalidCommandArgument,
          LSystemTurtleDiagnosticCode.invalidCommandArgument,
          LSystemTurtleDiagnosticCode.invalidLineWidth,
        ],
      );
    });

    test('assignments update branch-local turtle state', () {
      final result = const LSystemTurtleInterpreter().interpret(
        LSystemWord(const [
          'distance=2',
          'g',
          '[',
          'distance(5)',
          'lineIncrement=3',
          '!',
          'g',
          ']',
          'g',
          'angle=90',
          '+',
          'hueChange=120',
          'color=red',
          '#',
          'g',
        ]),
        settings: LSystemTurtleSettings(),
        mapping: LSystemCommandMapping.jflap,
      ) as LSystemTurtleCompleted;

      expect(result.geometry.segmentWidths, [1, 4, 1, 1]);
      expect(result.geometry.segmentCoordinates, [
        0,
        0,
        0,
        -2,
        0,
        -2,
        0,
        -7,
        0,
        -2,
        0,
        -4,
        0,
        -4,
        2,
        -4,
      ]);
      expect(result.geometry.segmentColorsArgb.last, 0xff00ff00);
    });

    test('polygon drawing consumes the shared segment limit', () {
      final result = const LSystemTurtleInterpreter().interpret(
        LSystemWord(const ['{', 'g', 'g', 'g', '}']),
        settings: LSystemTurtleSettings(),
        mapping: LSystemCommandMapping.jflap,
        limits: const LSystemTurtleLimits(maximumSegments: 2),
      );

      expect(result, isA<LSystemTurtleBounded>());
      expect((result as LSystemTurtleBounded).processedSymbols, 3);
    });

    test('non-finite derived positions fail instead of completing', () {
      final result = const LSystemTurtleInterpreter().interpret(
        LSystemWord(const ['g(1e308)', 'g(1e308)']),
        settings: LSystemTurtleSettings(),
        mapping: LSystemCommandMapping.jflap,
      );

      expect(result, isA<LSystemTurtleInvalid>());
      expect(
        (result as LSystemTurtleInvalid).diagnostics.single.code,
        LSystemTurtleDiagnosticCode.nonFiniteGeometry,
      );
    });

    test('large finite angles are reduced before rotation', () {
      final result = const LSystemTurtleInterpreter().interpret(
        LSystemWord(const ['angle=1e308', '+', 'g']),
        settings: LSystemTurtleSettings(),
        mapping: LSystemCommandMapping.jflap,
      ) as LSystemTurtleCompleted;

      expect(
        result.geometry.segmentCoordinates.every((value) => value.isFinite),
        isTrue,
      );
    });

    test('supports Java AWT, JFLAP special, RGB, and HSB colors', () {
      final result = const LSystemTurtleInterpreter().interpret(
        LSystemWord(const [
          'color(darkGray)',
          'g',
          'color(dukeBlue)',
          'g',
          'color(255,200,0)',
          'g',
          'color(0.5,1,1)',
          'g',
        ]),
        settings: LSystemTurtleSettings(),
        mapping: LSystemCommandMapping.jflap,
      ) as LSystemTurtleCompleted;

      expect(result.geometry.segmentColorsArgb, [
        0xff404040,
        0xff00009c,
        0xffffc800,
        0xff00ffff,
      ]);
    });

    test('SVG preserves segment and polygon alpha', () {
      final geometry = LSystemGeometry(
        segmentCoordinates: const [0, 0, 1, 1],
        sourceTokenIndices: const [0],
        segmentColorsArgb: const [0x80112233],
        polygons: [
          LSystemPolygon(
            coordinates: const [0, 0, 1, 0, 0, 1],
            sourceTokenIndex: 0,
            colorArgb: 0x40445566,
          ),
        ],
        bounds: const LSystemBounds(minX: 0, minY: 0, maxX: 1, maxY: 1),
        maximumBranchDepth: 0,
      );
      final exported = const LSystemSvgExporter().encode(
        geometry,
        metadata: LSystemRenderMetadata(
          documentId: 'alpha',
          sourceRevision: 0,
          generation: 0,
          settings: LSystemTurtleSettings(),
        ),
      );
      final svg = utf8.decode(exported.bytes);

      expect(svg, contains('stroke="#112233"'));
      expect(svg, contains('stroke-opacity="0.501961"'));
      expect(svg, contains('fill="#445566"'));
      expect(svg, contains('fill-opacity="0.25098"'));
    });
  });
}

LSystemDocument _system({
  List<String> axiom = const ['A'],
  List<LSystemProduction> productions = const [],
  int seed = 0,
  Set<String> ignoredContextSymbols = const {},
  List<LSystemUnsupportedVariant> unsupportedVariants = const [],
}) =>
    LSystemDocument(
      id: 'advanced-system',
      name: 'Advanced system',
      revision: 0,
      axiom: LSystemWord(axiom),
      productions: productions,
      iterations: 1,
      randomSeed: seed,
      ignoredContextSymbols: ignoredContextSymbols,
      turtle: LSystemTurtleSettings(),
      commandMapping: LSystemCommandMapping.jflap,
      unsupportedVariants: unsupportedVariants,
    );

LSystemProduction _production(
  String id,
  String predecessor,
  List<String> successor, {
  List<String> leftContext = const [],
  List<String> rightContext = const [],
  double weight = 1,
}) =>
    LSystemProduction(
      id: id,
      predecessor: predecessor,
      successor: LSystemWord(successor),
      leftContext: LSystemWord(leftContext),
      rightContext: LSystemWord(rightContext),
      weight: weight,
    );
