part of '../interoperability_roundtrip_test.dart';

void _runSvgExportTests() {
  group('SVG Export/Import Tests', () {
    test('SVG export produces valid structure', () {
      final testAutomaton = _createTestDFA();

      final svg = SvgExporter.exportFsaToSvg(_fsaFromData(testAutomaton));
      expect(svg, isNotEmpty);
      expect(svg, contains('<?xml'));
      expect(svg, contains('<svg'));
      expect(svg, contains('</svg>'));

      // Validate SVG structure
      expect(svg, contains('viewBox'));
      expect(svg, contains('<defs>'));
      expect(svg, contains('<style>'));
    });

    test('SVG export handles different automaton types', () {
      final testCases = [
        _createTestDFA(),
        _createTestNFA(),
        _createEpsilonNFA(),
      ];

      for (final automaton in testCases) {
        final svg = SvgExporter.exportFsaToSvg(_fsaFromData(automaton));
        expect(svg, isNotEmpty);
        expect(svg, contains('<?xml'));
        expect(svg, contains('<svg'));
        expect(svg, contains('</svg>'));
      }
    });

    test('SVG export handles different sizes', () {
      final testAutomaton = _createTestDFA();

      final smallSvg = SvgExporter.exportFsaToSvg(
        _fsaFromData(testAutomaton),
        width: 400,
        height: 300,
      );
      expect(smallSvg, contains(_viewBoxPattern(400, 300)));
      expect(smallSvg, contains('<svg width="400px" height="300px"'));

      final largeSvg = SvgExporter.exportFsaToSvg(
        _fsaFromData(testAutomaton),
        width: 1200,
        height: 900,
      );
      expect(largeSvg, contains(_viewBoxPattern(1200, 900)));
      expect(largeSvg, contains('<svg width="1200px" height="900px"'));
    });

    test('SVG export formats dimensions without trailing decimals', () {
      final testAutomaton = _createTestDFA();

      final svg = SvgExporter.exportFsaToSvg(
        _fsaFromData(testAutomaton),
        width: 640.0,
        height: 480.0,
      );

      expect(svg, contains('<svg width="640px" height="480px"'));
      expect(svg, contains(_viewBoxPattern(640, 480)));
      expect(svg, isNot(contains('640.0px')));
      expect(svg, isNot(contains('480.0px')));
    });

    test('SVG export includes proper styling', () {
      final testAutomaton = _createTestDFA();

      final svg = SvgExporter.exportFsaToSvg(_fsaFromData(testAutomaton));

      // Validate styling elements
      expect(svg, contains('<defs>'));
      expect(svg, contains('<marker'));
      expect(svg, contains('<style>'));
      expect(svg, contains('class='));
      expect(svg, contains('font-family'));
      expect(svg, contains('text-anchor'));
    });

    test('SVG export renders placeholders for empty automatons', () {
      final emptyAutomaton = _createEmptyAutomaton();

      final svg = SvgExporter.exportFsaToSvg(_fsaFromData(emptyAutomaton));

      expect(svg, contains('No states defined'));
      expect(svg, contains('<svg'));
      expect(svg, isNot(contains('<circle')));
    });

    test('SVG export draws self-loop transitions without degenerating', () {
      final loopAutomaton = _automatonData(
        id: 'loop',
        name: 'Loop',
        type: 'nfa',
        alphabet: const ['a'],
        states: [
          _stateData('q0', isInitial: true, isFinal: true),
        ],
        transitions: const {
          'q0|λ': ['q0'],
        },
        initialId: 'q0',
        nextId: 1,
      );

      final svg = SvgExporter.exportFsaToSvg(_fsaFromData(loopAutomaton));

      expect(svg, contains('<path'));
      expect(svg, contains('>ε<'));
      expect(svg, isNot(contains('NaN')));
    });

    test('SVG export draws self-loops as the canvas ring', () {
      final loopAutomaton = _automatonData(
        id: 'loop-shape',
        name: 'Loop shape',
        type: 'nfa',
        alphabet: const ['a', 'b'],
        states: [
          _stateData('q0', isInitial: true),
          _stateData('q1', isFinal: true),
        ],
        transitions: const {
          'q0|a': ['q0'],
          'q0|b': ['q0'],
          'q1|a': ['q1'],
          'q0|': ['q1'],
        },
        initialId: 'q0',
        nextId: 2,
      );

      final svg = SvgExporter.exportFsaToSvg(_fsaFromData(loopAutomaton));
      final arcs = RegExp(r'<path d="M [\d.-]+ [\d.-]+ A ([\d.]+) ')
          .allMatches(svg)
          .map((match) => double.parse(match.group(1)!))
          .toList();

      // One ring per looping state: q0's two symbols share a single loop the
      // way the canvas merges them, and every loop is a circular arc.
      expect(arcs, hasLength(2));
      for (final radius in arcs) {
        expect(radius, closeTo(25 * kSelfLoopRadiusFactor, 0.01));
      }
      expect(svg, contains('>a, b<'));

      // The q0 -> q1 transition is routed as a curve too, so the document
      // holds exactly the two loops plus that transition.
      expect(RegExp('<path').allMatches(svg), hasLength(3));
    });

    test('SVG export keeps a self-loop clear of the state\'s traffic', () {
      // q0 is initial (marker to the west) and its only transition leaves
      // east, so the loop has to take the top or the bottom of the border.
      final automaton = _automatonData(
        id: 'loop-placement',
        name: 'Loop placement',
        type: 'nfa',
        alphabet: const ['a', 'b'],
        states: [
          _stateData('q0', isInitial: true),
          _stateData('q1', isFinal: true),
        ],
        transitions: const {
          'q0|a': ['q0'],
          'q0|b': ['q1'],
        },
        initialId: 'q0',
        nextId: 2,
      );

      final svg = SvgExporter.exportFsaToSvg(_fsaFromData(automaton));
      final loop = RegExp(
        r'<path d="M ([\d.-]+) ([\d.-]+) A [\d.]+ [\d.]+ 0 \d \d '
        r'([\d.-]+) ([\d.-]+)"',
      ).firstMatch(svg)!;

      // The loop's anchors straddle its heading, so the chord between them
      // turned a quarter turn gives the direction the loop points in.
      final chordX =
          double.parse(loop.group(1)!) - double.parse(loop.group(3)!);
      final chordY =
          double.parse(loop.group(2)!) - double.parse(loop.group(4)!);
      final outwardX = chordY;
      final outwardY = -chordX;

      expect(outwardY, lessThan(0), reason: 'loop should point upwards');
      expect(outwardY.abs(), greaterThan(outwardX.abs()));
    });

    test('SVG export handles complex automatons', () {
      final complexAutomaton = _createComplexDFA();

      final svg = SvgExporter.exportFsaToSvg(_fsaFromData(complexAutomaton));
      expect(svg, isNotEmpty);
      expect(svg, contains('<?xml'));
      expect(svg, contains('<svg'));
      expect(svg, contains('</svg>'));

      // Should contain multiple states and transitions
      expect(svg, contains('<circle')); // States
      expect(svg, contains('<path')); // Transitions, routed as curves
      expect(svg, contains('<text')); // Labels
    });

    test('Turing machine SVG export formats dimensions consistently', () {
      final tm = _createTestTuringMachine();

      final svg = SvgExporter.exportTuringMachineToSvg(
        tm,
        width: 512.0,
        height: 256.0,
      );

      expect(svg, contains('<svg width="512px" height="256px"'));
      expect(svg, contains(_viewBoxPattern(512, 256)));
      expect(svg, isNot(contains('512.0px')));
      expect(svg, isNot(contains('256.0px')));
    });
  });
}
