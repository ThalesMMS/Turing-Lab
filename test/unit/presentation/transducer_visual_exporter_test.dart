import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:turing_lab/core/annotations/annotations.dart';
import 'package:turing_lab/core/formal_systems/formal_systems.dart';
import 'package:turing_lab/core/transducers/transducers.dart';
import 'package:turing_lab/data/transducers/default_transducer_registry.dart';
import 'package:turing_lab/presentation/widgets/export/transducer_visual_exporter.dart';
import 'package:turing_lab/presentation/widgets/visual_export_binding.dart';

void main() {
  test('registry declares SVG and PNG for both transducer workspaces', () {
    final registry = DefaultTransducerRegistry.registry;
    for (final key in const [
      TransducerFormalSystemIds.mealy,
      TransducerFormalSystemIds.moore,
    ]) {
      final descriptor = registry.descriptorFor(key)!;
      expect(
        descriptor
            .formatSupport(DefaultFormalSystemIds.svgFormat)!
            .supports(DocumentFormatDirection.exportDocument),
        isTrue,
      );
      expect(
        descriptor
            .formatSupport(DefaultFormalSystemIds.pngFormat)!
            .supports(DocumentFormatDirection.exportDocument),
        isTrue,
      );
    }
  });

  test('visual binding intersects producers with executable registry data', () {
    final binding = VisualExportBinding(
      systemKey: TransducerFormalSystemIds.mealy,
      producers: {
        DefaultFormalSystemIds.svgFormat: (
                {required includeAnnotations}) async =>
            TransducerVisualExporter.svg(_mealyMachine()),
        const DocumentFormatId('unsupported-image'): ({
          required includeAnnotations,
        }) async =>
            TransducerVisualExporter.svg(_mealyMachine()),
      },
    );

    expect(binding.supportedFormats(DefaultTransducerRegistry.registry), [
      DefaultFormalSystemIds.svgFormat,
    ]);
  });

  testWidgets(
    'Mealy exports have deterministic dimensions and preserve Unicode notes',
    (tester) async {
      final machine = _mealyMachine();
      final annotations = _annotations(machine.id.value);

      final svg = TransducerVisualExporter.svg(
        machine,
        annotations: annotations,
      );
      final text = utf8.decode(svg.bytes);
      expect(svg.width, 800);
      expect(svg.height, 600);
      expect(text, contains('width="800px" height="600px"'));
      expect(text, contains('entrada λ / saída 🧠'));
      expect(text, contains('Unicode λ, 漢字, 🧠'));
      expect(text, contains('class="annotations"'));

      await tester.runAsync(() async {
        final png = await TransducerVisualExporter.png(
          machine,
          annotations: annotations,
        );
        expect(png.bytes.take(8), [137, 80, 78, 71, 13, 10, 26, 10]);
        expect(_uint32(png.bytes, 16), 800);
        expect(_uint32(png.bytes, 20), 600);
      });
    },
  );

  test('Moore SVG renders output labels without accepting-state semantics', () {
    final artifact = TransducerVisualExporter.svg(_mooreMachine());
    final text = utf8.decode(artifact.bytes);

    expect(text, contains('estado β'));
    expect(text, contains('zero · 漢字'));
    expect(text, isNot(contains('accepting')));
  });

  testWidgets(
    'parallel reciprocal and loop transitions use distinct SVG and PNG routes',
    (tester) async {
      final machine = _routedMealyMachine();
      final first = TransducerVisualExporter.svg(machine);
      final second = TransducerVisualExporter.svg(machine);
      final text = utf8.decode(first.bytes);
      const labels = [
        'a / x',
        'b / x',
        'c / x',
        'd / x',
        'e / x',
        'f / x',
      ];

      expect(first.bytes, second.bytes);
      expect(RegExp(r'<path d="M [^"]+ Q ').allMatches(text), hasLength(2));
      expect(RegExp(r'<path d="M [^"]+ C ').allMatches(text), hasLength(3));
      expect(
        labels.map((label) => _svgTextPosition(text, label)).toSet(),
        hasLength(labels.length),
      );

      await tester.runAsync(() async {
        final png = await TransducerVisualExporter.png(machine);
        expect(png.bytes.take(8), [137, 80, 78, 71, 13, 10, 26, 10]);
        expect(_uint32(png.bytes, 16), 800);
        expect(_uint32(png.bytes, 20), 600);
      });
    },
  );
}

int _uint32(Uint8List bytes, int offset) =>
    ByteData.sublistView(bytes).getUint32(offset);

String _svgTextPosition(String source, String label) {
  final match = RegExp(
    '<text x="([^"]+)" y="([^"]+)"[^>]*>${RegExp.escape(label)}</text>',
  ).firstMatch(source);
  expect(match, isNotNull, reason: label);
  return '${match!.group(1)},${match.group(2)}';
}

DocumentAnnotationCollection _annotations(String documentId) {
  final epoch = DateTime.fromMillisecondsSinceEpoch(0, isUtc: true);
  return DocumentAnnotationCollection(
    documentId: documentId,
    documentRevision: '1',
    annotations: [
      DocumentAnnotation(
        id: 'note',
        documentId: documentId,
        documentRevision: '1',
        text: 'Unicode λ, 漢字, 🧠',
        x: 30,
        y: 40,
        createdAt: epoch,
        updatedAt: epoch,
      ),
    ],
  );
}

MealyMachine _mealyMachine() => MealyMachine(
      id: const TransducerMachineId('mealy-unicode'),
      name: 'Mealy Unicode',
      revision: const TransducerRevision(1),
      inputAlphabet: {const TransducerInputSymbol('entrada λ')},
      outputAlphabet: {const TransducerOutputSymbol('saída 🧠')},
      states: const [
        MealyState(
          id: TransducerStateId('q0'),
          label: 'início',
          position: TransducerPoint(20, 30),
          isInitial: true,
        ),
        MealyState(
          id: TransducerStateId('q1'),
          label: 'fim 漢字',
          position: TransducerPoint(220, 130),
        ),
      ],
      transitions: [
        MealyTransition(
          id: const TransducerTransitionId('t0'),
          from: const TransducerStateId('q0'),
          to: const TransducerStateId('q1'),
          input: const TransducerInputSymbol('entrada λ'),
          output: TransducerOutputWord.fromValues(const ['saída 🧠']),
        ),
      ],
    );

MooreMachine _mooreMachine() => MooreMachine(
      id: const TransducerMachineId('moore-unicode'),
      name: 'Moore Unicode',
      revision: const TransducerRevision(1),
      inputAlphabet: {const TransducerInputSymbol('a')},
      outputAlphabet: {
        const TransducerOutputSymbol('zero'),
        const TransducerOutputSymbol('漢字'),
      },
      states: [
        MooreState(
          id: const TransducerStateId('q0'),
          label: 'estado β',
          position: const TransducerPoint(20, 30),
          isInitial: true,
          output: TransducerOutputWord.fromValues(const ['zero', '漢字']),
        ),
      ],
      transitions: const [
        MooreTransition(
          id: TransducerTransitionId('t0'),
          from: TransducerStateId('q0'),
          to: TransducerStateId('q0'),
          input: TransducerInputSymbol('a'),
        ),
      ],
    );

MealyMachine _routedMealyMachine() => MealyMachine(
      id: const TransducerMachineId('routed-mealy'),
      name: 'Routed Mealy',
      revision: const TransducerRevision(1),
      inputAlphabet: {
        for (final value in const ['a', 'b', 'c', 'd', 'e', 'f'])
          TransducerInputSymbol(value),
      },
      outputAlphabet: {const TransducerOutputSymbol('x')},
      states: const [
        MealyState(
          id: TransducerStateId('q0'),
          label: 'q0',
          position: TransducerPoint(80, 120),
          isInitial: true,
        ),
        MealyState(
          id: TransducerStateId('q1'),
          label: 'q1',
          position: TransducerPoint(320, 120),
        ),
      ],
      transitions: [
        for (final transition in const [
          ('forward-a', 'q0', 'q1', 'a'),
          ('forward-b', 'q0', 'q1', 'b'),
          ('reverse-c', 'q1', 'q0', 'c'),
          ('loop-d', 'q0', 'q0', 'd'),
          ('loop-e', 'q0', 'q0', 'e'),
          ('loop-f', 'q0', 'q0', 'f'),
        ])
          MealyTransition(
            id: TransducerTransitionId(transition.$1),
            from: TransducerStateId(transition.$2),
            to: TransducerStateId(transition.$3),
            input: TransducerInputSymbol(transition.$4),
            output: TransducerOutputWord.fromValues(const ['x']),
          ),
      ],
    );
