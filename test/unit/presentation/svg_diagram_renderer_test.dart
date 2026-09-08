import 'dart:math' as math;
import 'package:turing_lab/core/entities/grammar_entity.dart';
import 'package:turing_lab/presentation/widgets/export/svg/grammar_svg_renderer.dart';
import 'dart:ui' show Color;

import 'package:flutter_test/flutter_test.dart';
import 'package:turing_lab/core/models/fsa.dart';
import 'package:turing_lab/core/models/fsa_transition.dart';
import 'package:turing_lab/core/models/state.dart';
import 'package:turing_lab/core/entities/turing_machine_entity.dart';
import 'package:turing_lab/presentation/widgets/export/svg/svg_primitives.dart';
import 'package:vector_math/vector_math_64.dart';
import 'package:xml/xml.dart';
import 'package:turing_lab/presentation/widgets/export/svg/svg_diagram_renderer.dart';
import 'package:turing_lab/presentation/widgets/export/svg_exporter.dart';

class _StubRenderer implements SvgDiagramRenderer<String> {
  const _StubRenderer();

  @override
  SvgStyleRequest styles(String document, SvgExportOptions options) =>
      const SvgStyleRequest(
        includeAcceptingMask: false,
        arrowColors: {'#000000', '#123456'},
      );

  @override
  void render(
    StringBuffer buffer,
    String document, {
    required double width,
    required double height,
    required SvgExportOptions options,
  }) {
    buffer.writeln(
      '  <text>$document ${width}x$height ${options.scale}</text>',
    );
  }
}

void main() {
  test('grammar diagram keys retain each production symbol', () {
    const grammar = GrammarEntity(
      id: 'grammar',
      name: 'Grammar',
      terminals: {'a'},
      nonTerminals: {'S', 'A', 'B'},
      startSymbol: 'S',
      productions: [
        ProductionEntity(id: 'p0', leftSide: ['S'], rightSide: ['A', 'B', 'a']),
      ],
    );
    expect(GrammarSvgRenderer.toDiagram(grammar).transitions, {
      'S|A': ['A'],
      'S|B': ['B'],
      'S|a': ['terminal'],
    });
    final svg = XmlDocument.parse(
      SvgExporter.exportDiagram(
        const GrammarSvgRenderer(),
        grammar,
        options: const SvgExportOptions(includeTitle: false),
      ),
    );
    final edgeLabels = svg
        .findAllElements('text')
        .where((e) => e.getAttribute('class') == 'transition')
        .map((e) => e.innerText)
        .toList();
    expect(edgeLabels, containsAll(['A', 'B']));
    expect(edgeLabels, isNot(contains('ε')));
  });

  test('the exporter owns the sheet and the renderer draws the body', () {
    final svg = SvgExporter.exportDiagram(
      const _StubRenderer(),
      'body',
      width: 300,
      height: 200,
      options: const SvgExportOptions(scale: 2),
    );
    expect(svg, startsWith('<?xml version="1.0"'));
    expect(svg, contains('<svg width="600px" height="400px"'));
    expect(svg, contains('viewBox="0 0 300 200"'));
    expect(svg, contains('id="arrowhead-123456"'));
    expect(svg, contains('id="loop-arrowhead-000000"'));
    expect(svg, isNot(contains('accepting-state-mask')));
    expect(svg, contains('<text>body 300.0x200.0 2.0</text>'));
    expect(svg.trimRight(), endsWith('</svg>'));
  });

  test('state labels, transition labels and titles are XML-escaped', () {
    final q0 = State(
      id: 'q0',
      label: 'a<b',
      position: Vector2(40, 40),
      isInitial: true,
    );
    final q1 = State(
      id: 'q1',
      label: 'c&d',
      position: Vector2(200, 80),
      isAccepting: true,
    );
    final svg = SvgExporter.exportFsaToSvg(
      FSA(
        id: 'escape',
        name: 'Title "quoted" & <tagged>',
        states: {q0, q1},
        transitions: {
          FSATransition(
            id: 't0',
            fromState: q0,
            toState: q1,
            inputSymbols: const {'<x>'},
          ),
        },
        alphabet: const {'<x>'},
        initialState: q0,
        acceptingStates: {q1},
        created: DateTime.utc(2026),
        modified: DateTime.utc(2026),
        bounds: const math.Rectangle(0, 0, 400, 300),
      ),
    );
    expect(svg, contains('>a&lt;b</text>'));
    expect(svg, contains('>c&amp;d</text>'));
    expect(svg, contains('>&lt;x&gt;</text>'));
    expect(svg, contains('Title &quot;quoted&quot; &amp; &lt;tagged&gt;'));
    expect(svg, isNot(contains('<x></text>')));
    expect(() => XmlDocument.parse(svg), returnsNormally);
  });

  test('TM tape symbols are XML-escaped and coloured initial arrows have '
      'markers', () {
    final svg = SvgExporter.exportTuringMachineToSvg(
      const TuringMachineEntity(
        id: 'escape-tm',
        name: 'Escaped tape',
        inputAlphabet: {'<'},
        tapeAlphabet: {'<', '&', 'B'},
        blankSymbol: 'B',
        states: [
          TuringStateEntity(
            id: 'q0',
            name: 'q0',
            isInitial: true,
            isAccepting: true,
          ),
          TuringStateEntity(
            id: 'q1',
            name: 'q1',
            isInitial: false,
            isAccepting: false,
          ),
        ],
        transitions: [
          TuringTransitionEntity(
            id: 't0',
            fromStateId: 'q0',
            toStateId: 'q1',
            readSymbol: '<',
            writeSymbol: '&',
            moveDirection: TuringMoveDirection.right,
          ),
        ],
        initialStateId: 'q0',
        acceptingStateIds: {'q0'},
        rejectingStateIds: {},
      ),
    );
    final acceptingHex = SvgPrimitives.colorToHex(const Color(0xFF2E7D32));
    expect(svg, contains('class="tape-symbol"'));
    expect(svg, isNot(contains('><</text>')));
    expect(svg, isNot(contains('>&</text>')));
    expect(
      svg,
      contains(
        'marker-end="url(#${SvgPrimitives.arrowMarkerId(acceptingHex)})"',
      ),
    );
    expect(
      svg,
      contains('<marker id="${SvgPrimitives.arrowMarkerId(acceptingHex)}"'),
    );
    expect(() => XmlDocument.parse(svg), returnsNormally);
  });
}
