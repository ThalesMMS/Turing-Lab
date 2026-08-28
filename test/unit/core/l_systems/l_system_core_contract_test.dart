import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:turing_lab/core/l_systems/l_systems.dart';

void main() {
  group('parallel expansion', () {
    test('preserves token boundaries and applies every rule simultaneously',
        () {
      final outcome = const LSystemExpander().expand(
        _system(
          axiom: ['A', '🌱'],
          productions: [
            _production('a', 'A', ['A', '🌱']),
            _production('plant', '🌱', ['stem']),
          ],
          iterations: 1,
        ),
      ) as LSystemExpansionCompleted;

      expect(outcome.finalGeneration.word.symbols, ['A', '🌱', 'stem']);
      expect(outcome.finalGeneration.provenance, hasLength(2));
      expect(outcome.finalGeneration.provenance.first.productionId, 'a');
      expect(outcome.finalGeneration.provenance.last.outputStart, 2);
    });

    test('zero generations returns the exact axiom and missing rules persist',
        () {
      final system = _system(axiom: ['multi-character'], iterations: 0);
      final outcome =
          const LSystemExpander().expand(system) as LSystemExpansionCompleted;
      expect(outcome.finalGeneration.index, 0);
      expect(outcome.finalGeneration.word, system.axiom);
    });

    test('supports empty replacements without treating them as missing', () {
      final outcome = const LSystemExpander().expand(
        _system(
          axiom: ['A', 'B'],
          productions: [_production('erase', 'A', const [])],
          iterations: 1,
        ),
      ) as LSystemExpansionCompleted;
      expect(outcome.finalGeneration.word.symbols, ['B']);
      expect(outcome.finalGeneration.provenance.first.outputStart, 0);
      expect(outcome.finalGeneration.provenance.first.outputEnd, 0);
    });

    test('growth estimate returns a typed bound before allocating output', () {
      final outcome = const LSystemExpander().expand(
        _system(
          axiom: ['A'],
          productions: [
            _production('double', 'A', ['A', 'A'])
          ],
          iterations: 20,
        ),
        limits: const LSystemExpansionLimits(maximumSymbols: 100),
      );
      expect(outcome, isA<LSystemExpansionBounded>());
      final bounded = outcome as LSystemExpansionBounded;
      expect(bounded.kind, LSystemExpansionBoundKind.symbols);
      expect(bounded.finalGeneration.word.length, 64);
      expect(bounded.estimate, 128);
    });

    test('checks elapsed limit inside one large generation deterministically',
        () {
      var reads = 0;
      final outcome = const LSystemExpander().expand(
        _system(
          axiom: List.filled(2000, 'A'),
          productions: [
            _production('same', 'A', ['A'])
          ],
          iterations: 1,
        ),
        limits: LSystemExpansionLimits(
          maximumElapsed: const Duration(microseconds: 1),
          elapsedProvider: () => Duration(microseconds: reads++ < 2 ? 0 : 2),
        ),
      );
      expect(outcome, isA<LSystemExpansionBounded>());
      expect((outcome as LSystemExpansionBounded).kind,
          LSystemExpansionBoundKind.elapsedTime);
      expect(outcome.finalGeneration.index, 0);
    });

    test('bounded generation retention does not change the final word', () {
      final outcome = const LSystemExpander().expand(
        _system(
          axiom: ['A'],
          productions: [
            _production('double', 'A', ['A', 'A'])
          ],
          iterations: 12,
        ),
        limits: const LSystemExpansionLimits(
          maximumSymbols: 5000,
          maximumRetainedGenerations: 2,
        ),
      ) as LSystemExpansionCompleted;
      expect(outcome.finalGeneration.word.length, 4096);
      expect(outcome.retainedGenerations, hasLength(2));
      expect(outcome.retainedGenerations.last.index, 12);
    });

    test('cancellation and unsupported variants never report completion', () {
      final cancelled = const LSystemExpander().expand(
        _system(
          axiom: List.filled(20, 'A'),
          productions: [
            _production('same', 'A', ['A'])
          ],
          iterations: 1,
        ),
        limits: LSystemExpansionLimits(
          cancellationCheckpoint: (_, processed) => processed == 4,
        ),
      );
      expect(cancelled, isA<LSystemExpansionCancelled>());

      final unsupported = const LSystemExpander().expand(
        _system(
          unsupportedVariants: const [LSystemUnsupportedVariant.stochastic],
        ),
      );
      expect(unsupported, isA<LSystemExpansionInvalid>());
    });

    test('cooperative expansion observes cancellation between symbol chunks',
        () async {
      final token = LSystemCancellationToken();
      final future = const LSystemExpander().expandAsync(
        _system(
          axiom: List.filled(5000, 'A'),
          productions: [
            _production('same', 'A', ['A'])
          ],
          iterations: 2,
        ),
        limits: LSystemExpansionLimits(cancellationToken: token),
        yieldEverySymbols: 32,
      );
      await Future<void>.delayed(Duration.zero);
      token.cancel();
      expect(await future, isA<LSystemExpansionCancelled>());
    });

    test('duplicate predecessors form a reproducible stochastic choice', () {
      final outcome = const LSystemExpander().expand(
        _system(
          productions: [
            _production('one', 'A', ['B']),
            _production('two', 'A', ['C']),
          ],
        ),
      ) as LSystemExpansionCompleted;
      expect(outcome.finalGeneration.word.symbols.single, anyOf('B', 'C'));
      expect(outcome.finalGeneration.provenance.single.productionId, isNotNull);
    });
  });

  group('turtle geometry', () {
    test('draw, move, turn, nested branches, and negative bounds are stable',
        () {
      final outcome = const LSystemTurtleInterpreter().interpret(
        LSystemWord(['F', '+', 'F', '[', '-', 'F', ']', 'f', 'F']),
        settings: LSystemTurtleSettings(
          angleDegrees: 90,
          stepLength: 2,
          initialX: -3,
          initialY: -4,
        ),
        mapping: LSystemCommandMapping.standard,
      ) as LSystemTurtleCompleted;
      expect(outcome.geometry.segmentCount, 4);
      expect(outcome.geometry.maximumBranchDepth, 1);
      expect(outcome.geometry.bounds.minX, lessThan(0));
      expect(outcome.geometry.bounds.minY, lessThan(0));
      expect(outcome.geometry.segmentCoordinates, [
        -3,
        -4,
        -3,
        -6,
        -3,
        -6,
        -5,
        -6,
        -5,
        -6,
        -5,
        -8,
        -7,
        -6,
        -9,
        -6,
      ]);
    });

    test('reports stack underflow and unmatched pushes', () {
      const interpreter = LSystemTurtleInterpreter();
      final settings = LSystemTurtleSettings();
      final mapping = LSystemCommandMapping.standard;
      final underflow = interpreter.interpret(
        LSystemWord([']']),
        settings: settings,
        mapping: mapping,
      ) as LSystemTurtleInvalid;
      expect(underflow.diagnostics.single.code,
          LSystemTurtleDiagnosticCode.stackUnderflow);
      final unclosed = interpreter.interpret(
        LSystemWord(['[', 'F']),
        settings: settings,
        mapping: mapping,
      ) as LSystemTurtleInvalid;
      expect(unclosed.diagnostics.single.code,
          LSystemTurtleDiagnosticCode.unclosedBranch);
    });

    test('segment limits and fit handle degenerate and negative geometry', () {
      final bounded = const LSystemTurtleInterpreter().interpret(
        LSystemWord(['F', 'F']),
        settings: LSystemTurtleSettings(),
        mapping: LSystemCommandMapping.standard,
        limits: const LSystemTurtleLimits(maximumSegments: 1),
      );
      expect(bounded, isA<LSystemTurtleBounded>());

      final fit = LSystemFitTransform.contain(
        const LSystemBounds(minX: -10, minY: -5, maxX: -10, maxY: 5),
        viewportWidth: 320,
        viewportHeight: 200,
      );
      expect(fit.scale.isFinite, isTrue);
      expect(fit.translateX.isFinite, isTrue);
    });
  });

  group('model and vector export', () {
    test('JSON round trip is immutable, tokenized, and canonical', () {
      final originalAxiom = <String>['🌿', 'branch node'];
      final original = _system(
        axiom: originalAxiom,
        unsupportedVariants: const [LSystemUnsupportedVariant.parametric],
        unsupportedMetadata: const {'raw': 'F(x)'},
      );
      originalAxiom.add('mutated');
      final encoded = jsonEncode(original.toJson());
      final decoded = LSystemDocument.fromJson(
        (jsonDecode(encoded) as Map).cast<String, Object?>(),
      );
      expect(decoded.axiom.symbols, ['🌿', 'branch node']);
      expect(decoded.toJson(), original.toJson());
      expect(
        () => decoded.axiom.symbols.add('x'),
        throwsUnsupportedError,
      );
    });

    test('SVG uses geometry bounds and selected-generation metadata', () {
      final geometry = LSystemGeometry(
        segmentCoordinates: const [-2, -1, 3, 4],
        sourceTokenIndices: const [0],
        bounds: const LSystemBounds(minX: -2, minY: -1, maxX: 3, maxY: 4),
        maximumBranchDepth: 0,
      );
      final exported = const LSystemSvgExporter().encode(
        geometry,
        metadata: LSystemRenderMetadata(
          documentId: 'svg-test',
          sourceRevision: 7,
          generation: 3,
          settings: LSystemTurtleSettings(lineWidth: 2),
        ),
      );
      final source = utf8.decode(exported.bytes);
      expect(exported.width, 21);
      expect(exported.height, 21);
      expect(source, contains('&quot;generation&quot;:3'));
      expect(source, contains('M8 8L13 13'));
    });

    test('rejects invalid numeric settings and empty symbol identities', () {
      expect(
        () => LSystemTurtleSettings(stepLength: 0),
        throwsFormatException,
      );
      expect(() => LSystemWord(['']), throwsFormatException);
      expect(
        () => LSystemProduction(
          id: '',
          predecessor: 'A',
          successor: LSystemWord.empty,
        ),
        throwsFormatException,
      );
    });
  });
}

LSystemDocument _system({
  List<String> axiom = const ['A'],
  List<LSystemProduction> productions = const [],
  int iterations = 1,
  List<LSystemUnsupportedVariant> unsupportedVariants = const [],
  Map<String, Object?> unsupportedMetadata = const {},
}) =>
    LSystemDocument(
      id: 'system',
      name: 'System',
      revision: 0,
      axiom: LSystemWord(axiom),
      productions: productions,
      iterations: iterations,
      turtle: LSystemTurtleSettings(),
      commandMapping: LSystemCommandMapping.standard,
      unsupportedVariants: unsupportedVariants,
      unsupportedMetadata: unsupportedMetadata,
    );

LSystemProduction _production(
  String id,
  String predecessor,
  List<String> successor,
) =>
    LSystemProduction(
      id: id,
      predecessor: predecessor,
      successor: LSystemWord(successor),
    );
