//
//  tm_svg_renderer.dart
//  Turing Lab
//
//  Turing machine sheet: tape cells with the head marker, states laid out on
//  a ring, vector-labelled transitions, annotations and the optional legend.
//

import 'dart:math' as math;

import 'package:flutter/material.dart' hide Colors;
import 'package:vector_math/vector_math_64.dart';

import '../../../../core/entities/turing_machine_entity.dart';
import 'annotation_svg_renderer.dart';
import 'svg_diagram_renderer.dart';
import 'svg_export_options.dart';
import 'svg_primitives.dart';
import 'svg_transition_renderer.dart';

class TmSvgRenderer implements SvgDiagramRenderer<TuringMachineEntity> {
  const TmSvgRenderer();

  @override
  SvgStyleRequest styles(
    TuringMachineEntity document,
    SvgExportOptions options,
  ) {
    final tmStroke = SvgPrimitives.colorToHex(
      options.colorScheme?.outline ?? const Color(0xFF424242),
    );
    // Initial arrows take the accepting or rejecting stroke of their state,
    // so those colours need arrowhead markers too.
    final acceptingStroke = SvgPrimitives.colorToHex(
      options.colorScheme?.tertiary ?? const Color(0xFF2E7D32),
    );
    final rejectingStroke = SvgPrimitives.colorToHex(
      options.colorScheme?.error ?? const Color(0xFFD32F2F),
    );
    return SvgStyleRequest(
      arrowColors: <String>{
        SvgPrimitives.defaultStrokeHex,
        tmStroke,
        acceptingStroke,
        rejectingStroke,
      },
    );
  }

  @override
  void render(
    StringBuffer buffer,
    TuringMachineEntity tm, {
    required double width,
    required double height,
    required SvgExportOptions options,
  }) {
    buffer.writeln('  <g>');

    final tapeLayout = _buildTapeCells(buffer, tm, width, height, options);
    _drawHeadIndicator(buffer, tapeLayout, options);

    final statePositions = _layoutStatesForTm(tm.states, width, height);
    _drawTuringTransitions(buffer, tm, statePositions, options);
    _drawTuringStates(buffer, tm, statePositions, options);
    AnnotationSvgRenderer.render(
      buffer,
      options,
      width,
      height,
      statePositions,
    );

    if (options.includeLegend) {
      _drawTuringLegend(buffer, width, height, options);
    }

    if (options.includeTitle) {
      SvgPrimitives.addTitle(buffer, tm.name, width, height);
    }

    buffer.writeln('  </g>');
  }

  static _TapeLayout _buildTapeCells(
    StringBuffer buffer,
    TuringMachineEntity tm,
    double width,
    double height,
    SvgExportOptions options,
  ) {
    const tapeHeight = 60.0;
    const minCellWidth = 60.0;
    final tapeTop = math.max(40.0, height * 0.12);
    final availableWidth = width * 0.8;
    final cellsCount = math.max(7, (availableWidth / minCellWidth).floor());
    final cellWidth = cellsCount > 0
        ? availableWidth / cellsCount
        : minCellWidth;
    final tapeStartX = (width - cellWidth * cellsCount) / 2;

    final colorScheme = options.colorScheme;
    final tapeFill =
        colorScheme?.surfaceContainerHighest ?? const Color(0xFFF5F5F5);
    final tapeStroke =
        colorScheme?.outlineVariant ??
        colorScheme?.outline ??
        const Color(0xFF424242);
    final textColor = colorScheme?.onSurface ?? const Color(0xFF000000);

    final blankSymbol = tm.blankSymbol.isEmpty ? '□' : tm.blankSymbol;
    final alphabet = tm.inputAlphabet.toList()..sort();

    buffer.writeln('    <g class="tape">');
    final formattedTapeTop = SvgPrimitives.formatDimension(tapeTop);
    final formattedCellWidth = SvgPrimitives.formatDimension(cellWidth);
    final formattedTapeHeight = SvgPrimitives.formatDimension(tapeHeight);
    for (var i = 0; i < cellsCount; i++) {
      final x = tapeStartX + i * cellWidth;
      final formattedX = SvgPrimitives.formatDimension(x);
      final textX = SvgPrimitives.formatDimension(x + cellWidth / 2);
      final textY = SvgPrimitives.formatDimension(tapeTop + tapeHeight / 2);
      final symbolIndex = alphabet.isEmpty ? 0 : i % alphabet.length;
      final symbol = i == cellsCount ~/ 2
          ? blankSymbol
          : (alphabet.isEmpty ? blankSymbol : alphabet[symbolIndex]);

      buffer.writeln(
        '      <rect class="tape-cell" x="$formattedX" y="$formattedTapeTop" width="$formattedCellWidth" height="$formattedTapeHeight"',
      );
      buffer.writeln(
        '        fill="${SvgPrimitives.colorToHex(tapeFill)}" stroke="${SvgPrimitives.colorToHex(tapeStroke)}"/>',
      );
      buffer.writeln(
        '      <text x="$textX" y="$textY" class="tape-symbol" fill="${SvgPrimitives.colorToHex(textColor)}">${SvgPrimitives.escapeXml(symbol)}</text>',
      );
    }
    buffer.writeln('    </g>');

    final headCellX = tapeStartX + (cellsCount ~/ 2) * cellWidth;
    return _TapeLayout(
      top: tapeTop,
      height: tapeHeight,
      cellWidth: cellWidth,
      headCellX: headCellX,
    );
  }

  static void _drawHeadIndicator(
    StringBuffer buffer,
    _TapeLayout layout,
    SvgExportOptions options,
  ) {
    final colorScheme = options.colorScheme;
    final headColor = colorScheme?.primary ?? const Color(0xFFD32F2F);
    final headTipX = layout.headCellX + layout.cellWidth / 2;
    final headTipY = layout.top - 18;
    final baseLeftX = headTipX - 12;
    final baseRightX = headTipX + 12;
    final baseY = layout.top - 2;
    final formattedBaseLeftX = SvgPrimitives.formatDimension(baseLeftX);
    final formattedBaseRightX = SvgPrimitives.formatDimension(baseRightX);
    final formattedBaseY = SvgPrimitives.formatDimension(baseY);
    final formattedHeadTipX = SvgPrimitives.formatDimension(headTipX);
    final formattedHeadTipY = SvgPrimitives.formatDimension(headTipY);

    buffer.writeln(
      '    <polygon class="head" points="$formattedBaseLeftX $formattedBaseY, $formattedBaseRightX $formattedBaseY, $formattedHeadTipX $formattedHeadTipY" fill="${SvgPrimitives.colorToHex(headColor)}"/>',
    );
  }

  static Map<String, Vector2> _layoutStatesForTm(
    List<TuringStateEntity> states,
    double width,
    double height,
  ) {
    final positions = <String, Vector2>{};
    if (states.isEmpty) {
      return positions;
    }

    if (states.length == 1) {
      positions[states.first.id] = Vector2(width / 2, height * 0.6);
      return positions;
    }

    final radius = math.min(width, height) * 0.3;
    final centerY = height * 0.62;
    final centerX = width / 2;

    // Start the ring at the initial state, on the west, so the machine reads
    // left to right and its marker does not land under an incoming
    // transition's arrowhead.
    final initialIndex = math.max(
      0,
      states.indexWhere((state) => state.isInitial),
    );
    for (var i = 0; i < states.length; i++) {
      final step = (i - initialIndex) % states.length;
      final angle = math.pi + ((2 * math.pi * step) / states.length);
      final x = centerX + radius * math.cos(angle);
      final y = centerY + radius * math.sin(angle);
      positions[states[i].id] = Vector2(x, y);
    }

    return positions;
  }

  static void _drawTuringStates(
    StringBuffer buffer,
    TuringMachineEntity tm,
    Map<String, Vector2> positions,
    SvgExportOptions options,
  ) {
    final colorScheme = options.colorScheme;
    final baseFill = colorScheme?.surface ?? const Color(0xFFFFFFFF);
    final baseStroke = colorScheme?.outline ?? const Color(0xFF424242);
    final acceptingStroke = colorScheme?.tertiary ?? const Color(0xFF2E7D32);
    final rejectingStroke = colorScheme?.error ?? const Color(0xFFD32F2F);
    final initialFill = colorScheme?.primaryContainer ?? baseFill;
    final textColor = colorScheme?.onSurface ?? const Color(0xFF000000);

    for (final state in tm.states) {
      final position = positions[state.id];
      if (position == null) {
        continue;
      }

      final strokeColor = state.isRejecting
          ? rejectingStroke
          : (state.isAccepting ? acceptingStroke : baseStroke);
      final fillColor = state.isInitial ? initialFill : baseFill;

      buffer.writeln('    <g class="state">');

      if (state.isAccepting) {
        final cx = SvgPrimitives.formatDimension(position.x);
        final cy = SvgPrimitives.formatDimension(position.y);
        final outerRadius = SvgPrimitives.formatDimension(
          SvgPrimitives.stateRadius + 5,
        );
        buffer.writeln('      <circle cx="$cx" cy="$cy" r="$outerRadius"');
        buffer.writeln(
          '        fill="none" stroke="${SvgPrimitives.colorToHex(strokeColor)}" stroke-width="3"/>',
        );
      }

      final mainCx = SvgPrimitives.formatDimension(position.x);
      final mainCy = SvgPrimitives.formatDimension(position.y);
      final radius = SvgPrimitives.formatDimension(SvgPrimitives.stateRadius);
      buffer.writeln('      <circle cx="$mainCx" cy="$mainCy" r="$radius"');
      buffer.writeln(
        '        fill="${SvgPrimitives.colorToHex(fillColor)}" stroke="${SvgPrimitives.colorToHex(strokeColor)}" stroke-width="${SvgPrimitives.formatDimension(SvgPrimitives.strokeWidth)}"/>',
      );

      if (state.isRejecting) {
        const lineOffset = SvgPrimitives.stateRadius * 0.6;
        final lineStartX1 = SvgPrimitives.formatDimension(
          position.x - lineOffset,
        );
        final lineStartY1 = SvgPrimitives.formatDimension(
          position.y - lineOffset,
        );
        final lineEndX1 = SvgPrimitives.formatDimension(
          position.x + lineOffset,
        );
        final lineEndY1 = SvgPrimitives.formatDimension(
          position.y + lineOffset,
        );
        final lineStartX2 = SvgPrimitives.formatDimension(
          position.x - lineOffset,
        );
        final lineStartY2 = SvgPrimitives.formatDimension(
          position.y + lineOffset,
        );
        final lineEndX2 = SvgPrimitives.formatDimension(
          position.x + lineOffset,
        );
        final lineEndY2 = SvgPrimitives.formatDimension(
          position.y - lineOffset,
        );
        buffer.writeln(
          '      <line x1="$lineStartX1" y1="$lineStartY1" x2="$lineEndX1" y2="$lineEndY1" stroke="${SvgPrimitives.colorToHex(strokeColor)}" stroke-width="1.5"/>',
        );
        buffer.writeln(
          '      <line x1="$lineStartX2" y1="$lineStartY2" x2="$lineEndX2" y2="$lineEndY2" stroke="${SvgPrimitives.colorToHex(strokeColor)}" stroke-width="1.5"/>',
        );
      }

      buffer.writeln(
        '      <text x="$mainCx" y="${SvgPrimitives.formatDimension(position.y + 5)}" class="state" fill="${SvgPrimitives.colorToHex(textColor)}">${SvgPrimitives.escapeXml(state.name)}</text>',
      );

      if (state.isInitial) {
        SvgPrimitives.addInitialArrow(
          buffer,
          position,
          strokeColor: SvgPrimitives.colorToHex(strokeColor),
        );
      }

      buffer.writeln('    </g>');
    }
  }

  static void _drawTuringTransitions(
    StringBuffer buffer,
    TuringMachineEntity tm,
    Map<String, Vector2> positions,
    SvgExportOptions options,
  ) {
    final colorScheme = options.colorScheme;
    final strokeColor = colorScheme?.outline ?? const Color(0xFF424242);
    final textColor = colorScheme?.onSurface ?? const Color(0xFF000000);

    final edges = <(String, String, String)>[
      for (final transition in tm.transitions)
        if (positions.containsKey(transition.fromStateId) &&
            positions.containsKey(transition.toStateId))
          (
            transition.fromStateId,
            transition.toStateId,
            '${transition.readSymbol}/${transition.writeSymbol}, '
                '${_directionLabel(transition.moveDirection)}',
          ),
    ];

    SvgTransitionRenderer.writeRouted(
      buffer,
      groups: SvgTransitionRenderer.groupEdges(edges),
      positions: positions,
      initialStateIds: <String>{
        for (final state in tm.states)
          if (state.isInitial) state.id,
      },
      indent: '    ',
      strokeColor: SvgPrimitives.colorToHex(strokeColor),
      textColor: SvgPrimitives.colorToHex(textColor),
      emptyStringSymbol: options.emptyStringSymbol,
    );
  }

  static void _drawTuringLegend(
    StringBuffer buffer,
    double width,
    double height,
    SvgExportOptions options,
  ) {
    final colorScheme = options.colorScheme;
    final textColor =
        colorScheme?.onSurfaceVariant ??
        colorScheme?.onSurface ??
        const Color(0xFF424242);
    final legendY = height - 30;
    final legendYText = SvgPrimitives.formatDimension(legendY);
    final legendXText = SvgPrimitives.formatDimension(width / 2);

    buffer.writeln('    <g class="legend">');
    buffer.writeln(
      '      <text x="$legendXText" y="$legendYText" text-anchor="middle" fill="${SvgPrimitives.colorToHex(textColor)}">',
    );
    buffer.writeln('        ${SvgPrimitives.escapeXml(options.tmLegendLabel)}');
    buffer.writeln('      </text>');
    buffer.writeln('    </g>');
  }

  static String _directionLabel(TuringMoveDirection direction) {
    switch (direction) {
      case TuringMoveDirection.left:
        return 'L';
      case TuringMoveDirection.right:
        return 'R';
      case TuringMoveDirection.stay:
        return 'S';
    }
  }
}

class _TapeLayout {
  final double top;
  final double height;
  final double cellWidth;
  final double headCellX;

  const _TapeLayout({
    required this.top,
    required this.height,
    required this.cellWidth,
    required this.headCellX,
  });
}
