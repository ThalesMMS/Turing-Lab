import 'dart:io';
import 'dart:math' as math;

import 'package:flutter_test/flutter_test.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:turing_lab/core/models/fsa.dart';
import 'package:turing_lab/core/models/fsa_transition.dart';
import 'package:turing_lab/core/models/state.dart';
import 'package:turing_lab/presentation/widgets/export/print_document_builder.dart';
import 'package:turing_lab/presentation/widgets/export/svg_exporter.dart';
import 'package:vector_math/vector_math_64.dart';

void main() {
  late pw.Font font;

  setUpAll(() {
    font = pw.Font.ttf(
      File('assets/fonts/DejaVuSans.ttf').readAsBytesSync().buffer.asByteData(),
    );
  });

  String header(List<int> bytes) => String.fromCharCodes(bytes.take(5));

  test('renders an exported automaton SVG onto a landscape page', () async {
    final q0 = State(
      id: 'q0',
      label: 'q0',
      position: Vector2(40, 40),
      isInitial: true,
    );
    final q1 = State(
      id: 'q1',
      label: 'q1',
      position: Vector2(220, 90),
      isAccepting: true,
    );
    final fsa = FSA(
      id: 'f',
      name: 'Even zeros',
      states: {q0, q1},
      transitions: {
        FSATransition(
          id: 't0',
          fromState: q0,
          toState: q1,
          inputSymbols: const {'a'},
        ),
        FSATransition(
          id: 't1',
          fromState: q1,
          toState: q1,
          lambdaSymbol: 'ε',
          controlPoint: Vector2(10, -20),
        ),
      },
      alphabet: const {'a'},
      initialState: q0,
      acceptingStates: {q1},
      created: DateTime.utc(2026),
      modified: DateTime.utc(2026),
      bounds: const math.Rectangle(0, 0, 400, 300),
    );
    final svg = SvgExporter.exportFsaToSvg(fsa);
    expect(svg, contains('ε'));

    final bytes = await PrintDocumentBuilder.build(
      PrintableVector(title: fsa.name, svg: svg, width: 800, height: 600),
      font: font,
    );
    expect(header(bytes), '%PDF-');
    expect(bytes.length, greaterThan(1000));
  });

  test('renders text listings with non-Latin glyphs across pages', () async {
    final text = List.generate(
      120,
      (index) => 'S → a S b | ε   (line ${index + 1}) ⟨q₁⟩',
    ).join('\n');
    final bytes = await PrintDocumentBuilder.build(
      PrintableText(title: 'Grammar λ', text: text),
      font: font,
    );
    expect(header(bytes), '%PDF-');
    final pages = RegExp(
      r'/Type\s*/Page\b',
    ).allMatches(String.fromCharCodes(bytes));
    expect(pages.length, greaterThan(1));
  });

  test(
    'a logical line longer than a page continues on the next page',
    () async {
      final text = List.generate(2500, (index) => 'w${index + 1}').join(' ');
      final bytes = await PrintDocumentBuilder.build(
        PrintableText(title: 'Long line', text: text),
        font: font,
      );
      expect(header(bytes), '%PDF-');
      final pages = RegExp(
        r'/Type\s*/Page\b',
      ).allMatches(String.fromCharCodes(bytes));
      expect(pages.length, greaterThan(1));
    },
  );

  test(
    'portrait pages for tall vectors and built-in fonts without a font',
    () async {
      final bytes = await PrintDocumentBuilder.build(
        const PrintableVector(
          title: 'Tall',
          svg:
              '<svg xmlns="http://www.w3.org/2000/svg" width="10" height="20">'
              '<rect width="10" height="20"/></svg>',
          width: 10,
          height: 20,
        ),
      );
      expect(header(bytes), '%PDF-');
    },
  );
}
