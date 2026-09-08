//
//  automaton_svg_renderer.dart
//  Turing Lab
//
//  State-diagram rendering shared by FSA, PDA and grammar exports: layout
//  (canvas positions or a grid), states with accepting rings and initial
//  arrows, routed transitions and the empty placeholder. FsaSvgRenderer maps
//  a finite automaton onto that diagram.
//

import 'dart:math' as math;

import 'package:vector_math/vector_math_64.dart';

import '../../../../core/models/fsa.dart';
import '../../../../core/utils/epsilon_utils.dart';
import 'annotation_svg_renderer.dart';
import 'svg_diagram_renderer.dart';
import 'svg_export_options.dart';
import 'svg_primitives.dart';
import 'svg_transition_renderer.dart';

class SvgAutomatonDiagram {
  final String name;
  final List<SvgDiagramState> states;
  final Map<String, List<String>> transitions;

  const SvgAutomatonDiagram({
    required this.name,
    required this.states,
    required this.transitions,
  });
}

class SvgDiagramState {
  final String id;
  final String name;
  final bool isInitial;
  final bool isFinal;

  /// Where the state sits on the canvas, when the source has a layout. Null
  /// for diagrams synthesised from a grammar, which are laid out on a grid.
  final Vector2? position;

  const SvgDiagramState({
    required this.id,
    required this.name,
    required this.isInitial,
    required this.isFinal,
    this.position,
  });
}

class AutomatonDiagramSvgRenderer
    implements SvgDiagramRenderer<SvgAutomatonDiagram> {
  const AutomatonDiagramSvgRenderer();

  @override
  SvgStyleRequest styles(
    SvgAutomatonDiagram document,
    SvgExportOptions options,
  ) => SvgStyleRequest(includeAcceptingMask: document.states.isNotEmpty);

  @override
  void render(
    StringBuffer buffer,
    SvgAutomatonDiagram automaton, {
    required double width,
    required double height,
    required SvgExportOptions options,
  }) {
    if (automaton.states.isEmpty) {
      _addEmptyAutomatonPlaceholder(
        buffer,
        width,
        height,
        options.emptyAutomatonLabel,
      );
      if (options.includeTitle) {
        SvgPrimitives.addTitle(buffer, automaton.name, width, height);
      }
      AnnotationSvgRenderer.render(buffer, options, width, height, const {});
      return;
    }

    // Calculate positions for states (simple grid layout)
    final statePositions = _calculateStatePositions(
      automaton.states,
      width,
      height,
    );

    // Draw transitions first (behind states)
    _addTransitions(buffer, automaton, statePositions, options);

    // Draw states
    _addStates(buffer, automaton, statePositions, options);
    AnnotationSvgRenderer.render(
      buffer,
      options,
      width,
      height,
      statePositions,
    );

    // Add title if requested
    if (options.includeTitle) {
      SvgPrimitives.addTitle(buffer, automaton.name, width, height);
    }
  }

  static Map<String, Vector2> _calculateStatePositions(
    List<SvgDiagramState> states,
    double width,
    double height,
  ) {
    final positions = <String, Vector2>{};

    // Handle edge case of no states
    if (states.isEmpty) {
      return positions;
    }

    final fromCanvas = _canvasStatePositions(states, width, height);
    if (fromCanvas != null) {
      return fromCanvas;
    }

    final cols = math.max(1, math.sqrt(states.length).ceil());
    final rows = math.max(1, (states.length / cols).ceil());

    final cellWidth = width / math.max(1, cols + 1);
    final cellHeight = height / math.max(1, rows + 1);

    for (var i = 0; i < states.length; i++) {
      final col = i % cols;
      final row = i ~/ cols;

      final x = (col + 1) * cellWidth;
      final y = (row + 1) * cellHeight;

      positions[states[i].id] = Vector2(x, y);
    }

    return positions;
  }

  /// Maps the canvas layout onto the export sheet, so a diagram is exported
  /// the way it was arranged rather than re-flowed onto a grid.
  ///
  /// Returns null when the source carries no usable layout — a grammar
  /// diagram, or states that all sit on the same spot — leaving the caller to
  /// fall back to the grid.
  static Map<String, Vector2>? _canvasStatePositions(
    List<SvgDiagramState> states,
    double width,
    double height,
  ) {
    final placed = <String, Vector2>{
      for (final state in states)
        if (state.position != null &&
            state.position!.x.isFinite &&
            state.position!.y.isFinite)
          state.id: state.position!,
    };
    if (placed.length != states.length) {
      return null;
    }

    var minX = double.infinity;
    var minY = double.infinity;
    var maxX = double.negativeInfinity;
    var maxY = double.negativeInfinity;
    for (final position in placed.values) {
      minX = math.min(minX, position.x);
      minY = math.min(minY, position.y);
      maxX = math.max(maxX, position.x);
      maxY = math.max(maxY, position.y);
    }
    final spanX = maxX - minX;
    final spanY = maxY - minY;
    if (states.length > 1 && spanX < 1 && spanY < 1) {
      return null;
    }

    // Leave room for the states themselves, their loops and their labels.
    const margin = SvgPrimitives.stateRadius * SvgPrimitives.layoutMarginFactor;
    final usableWidth = math.max(width - (margin * 2), 1.0);
    final usableHeight = math.max(height - (margin * 2), 1.0);
    // Never magnify: at [SvgPrimitives.canvasToExportScale] a state keeps the same size
    // relative to its neighbours as it has on the canvas.
    final scale = math.min(
      SvgPrimitives.canvasToExportScale,
      math.min(
        spanX < 1 ? double.infinity : usableWidth / spanX,
        spanY < 1 ? double.infinity : usableHeight / spanY,
      ),
    );

    final offsetX = (width - (spanX * scale)) / 2;
    final offsetY = (height - (spanY * scale)) / 2;
    return <String, Vector2>{
      for (final entry in placed.entries)
        entry.key: Vector2(
          offsetX + ((entry.value.x - minX) * scale),
          offsetY + ((entry.value.y - minY) * scale),
        ),
    };
  }

  static void _addStates(
    StringBuffer buffer,
    SvgAutomatonDiagram automaton,
    Map<String, Vector2> positions,
    SvgExportOptions options,
  ) {
    for (final state in automaton.states) {
      final pos = positions[state.id]!;
      final isInitial = state.isInitial;
      final isAccepting = state.isFinal;

      // Draw state circle
      final strokeColor = isAccepting ? '#000' : '#666';
      final strokeWidth = isAccepting ? 3.0 : 2.0;

      buffer.writeln('  <g class="state">');
      final cx = SvgPrimitives.formatDimension(pos.x);
      final cy = SvgPrimitives.formatDimension(pos.y);
      if (isAccepting) {
        final outerRadius = SvgPrimitives.formatDimension(
          SvgPrimitives.stateRadius + 5,
        );
        // Draw double circle for accepting states
        buffer.writeln('    <circle cx="$cx" cy="$cy" r="$outerRadius"');
        buffer.writeln(
          '      fill="none" stroke="$strokeColor" stroke-width="${SvgPrimitives.formatDimension(strokeWidth)}"/>',
        );
      }
      final radius = SvgPrimitives.formatDimension(SvgPrimitives.stateRadius);
      buffer.writeln('    <circle cx="$cx" cy="$cy" r="$radius"');
      buffer.writeln('      fill="${isInitial ? '#e3f2fd' : '#fff'}"');
      buffer.writeln(
        '      stroke="$strokeColor" stroke-width="${SvgPrimitives.formatDimension(strokeWidth)}"/>',
      );

      // Add state label
      buffer.writeln(
        '    <text x="$cx" y="${SvgPrimitives.formatDimension(pos.y + 5)}" class="state">${SvgPrimitives.escapeXml(state.name)}</text>',
      );

      // Add initial arrow if needed
      if (isInitial) {
        SvgPrimitives.addInitialArrow(buffer, pos);
      }

      buffer.writeln('  </g>');
    }
  }

  static void _addTransitions(
    StringBuffer buffer,
    SvgAutomatonDiagram automaton,
    Map<String, Vector2> positions,
    SvgExportOptions options,
  ) {
    if (automaton.transitions.isEmpty) {
      return;
    }

    final edges = <(String, String, String)>[];
    for (final entry in automaton.transitions.entries) {
      final fromStateId = extractStateIdFromTransitionKey(entry.key);
      final fromPos = positions[fromStateId];
      if (fromPos == null) {
        continue;
      }

      final symbol = normalizeToEpsilon(
        extractSymbolFromTransitionKey(entry.key),
      );

      for (final targetStateId in entry.value) {
        final toPos = positions[targetStateId];
        if (toPos == null) {
          continue;
        }
        // Two states landing on the same spot cannot be told apart on the
        // sheet, so their transition reads as a loop.
        final isLoop =
            fromStateId == targetStateId || _pointsAreClose(fromPos, toPos);
        edges.add((fromStateId, isLoop ? fromStateId : targetStateId, symbol));
      }
    }

    SvgTransitionRenderer.writeRouted(
      buffer,
      groups: SvgTransitionRenderer.groupEdges(edges),
      positions: positions,
      initialStateIds: <String>{
        for (final state in automaton.states)
          if (state.isInitial) state.id,
      },
      indent: '  ',
      strokeColor: SvgPrimitives.defaultStrokeHex,
      textColor: SvgPrimitives.defaultStrokeHex,
      emptyStringSymbol: options.emptyStringSymbol,
    );
  }

  static bool _pointsAreClose(Vector2 a, Vector2 b) {
    return (a - b).length2 < 1e-6;
  }

  static void _addEmptyAutomatonPlaceholder(
    StringBuffer buffer,
    double width,
    double height,
    String label,
  ) {
    buffer.writeln('  <g class="empty-automaton">');
    buffer.writeln(
      '    <text x="${SvgPrimitives.formatDimension(width / 2)}" y="${SvgPrimitives.formatDimension(height / 2)}"'
      ' class="transition" text-anchor="middle">${SvgPrimitives.escapeXml(label)}</text>',
    );
    buffer.writeln('  </g>');
  }
}

class FsaSvgRenderer implements SvgDiagramRenderer<FSA> {
  const FsaSvgRenderer();

  static const _diagram = AutomatonDiagramSvgRenderer();

  @override
  SvgStyleRequest styles(FSA document, SvgExportOptions options) =>
      _diagram.styles(toDiagram(document), options);

  @override
  void render(
    StringBuffer buffer,
    FSA automaton, {
    required double width,
    required double height,
    required SvgExportOptions options,
  }) => _diagram.render(
    buffer,
    toDiagram(automaton),
    width: width,
    height: height,
    options: options,
  );

  static SvgAutomatonDiagram toDiagram(FSA automaton) {
    final transitions = <String, List<String>>{};

    for (final transition in automaton.fsaTransitions) {
      final symbols = transition.lambdaSymbol != null
          ? <String>{transition.lambdaSymbol!}
          : transition.inputSymbols;

      for (final symbol in symbols) {
        final label = normalizeToEpsilon(symbol);
        final key = '${transition.fromState.id}|$label';
        transitions
            .putIfAbsent(key, () => <String>[])
            .add(transition.toState.id);
      }
    }

    return SvgAutomatonDiagram(
      name: automaton.name,
      states: automaton.states
          .map(
            (state) => SvgDiagramState(
              id: state.id,
              name: state.label,
              isInitial: state.isInitial,
              isFinal: state.isAccepting,
              position: state.position,
            ),
          )
          .toList(),
      transitions: transitions,
    );
  }
}
