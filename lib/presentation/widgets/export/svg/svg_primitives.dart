//
//  svg_primitives.dart
//  Turing Lab
//
//  Sheet-level SVG vocabulary shared by every diagram renderer: geometry
//  constants, number formatting, the <defs>/<style> block with arrowhead
//  markers, and the title, initial-arrow and escaping helpers.
//

import 'package:flutter/material.dart' hide Colors;
import 'package:vector_math/vector_math_64.dart';

import '../../../../core/constants/automaton_canvas_constants.dart';

abstract final class SvgPrimitives {
  static const double defaultWidth = 800.0;

  static const double defaultHeight = 600.0;

  static const double stateRadius = 25.0;

  static const double strokeWidth = 2.0;

  /// Stroke used by diagrams that carry no colour scheme.
  static const String defaultStrokeHex = '#000000';

  /// Ratio between a canvas state and an exported one. Canvas positions are
  /// scaled by it so spacing reads the same on the sheet as on screen.
  static const double canvasToExportScale =
      stateRadius / (kAutomatonStateDiameter / 2);

  /// Free border, in state radii, kept around a layout mapped from the canvas.
  static const double layoutMarginFactor = 2.5;

  /// Font size of transition labels, the gap between a self-loop's ring and
  /// its own label, and the gap between a transition's curve and its label.
  static const double transitionFontSize = 12.0;

  static const double selfLoopLabelGap = 8.0;

  static const double transitionLabelGap = 10.0;

  /// Distance, in state radii, between the two lanes a pair of opposing
  /// transitions is split into.
  static const double laneSpacingFactor = 0.7;

  /// Arrowhead drawn at the end of a self-loop, scaled to the loop's ring
  /// rather than to a full-length transition.
  static const double loopArrowLength = stateRadius * 0.3;

  static const double loopArrowWidth = stateRadius * 0.22;

  static const String fontFamily = 'Arial, sans-serif';

  static String formatDimension(num value) {
    if (value.isNaN || value.isInfinite) {
      return '0';
    }

    // Use epsilon comparison for floating-point precision
    const epsilon = 1e-10;
    final isWholeNumber = (value - value.round()).abs() < epsilon;

    if (isWholeNumber) {
      return value.round().toString();
    }

    // Format with 2 decimal places and remove trailing zeros
    var text = value.toStringAsFixed(2);
    text = text.replaceFirst(RegExp(r'0+$'), '');
    if (text.endsWith('.')) {
      text = text.substring(0, text.length - 1);
    }
    return text;
  }

  /// Id of the arrowhead marker tinted [hex], so an arrow never contradicts
  /// the stroke it terminates.
  static String arrowMarkerId(String hex) =>
      'arrowhead-${hex.replaceAll('#', '')}';

  static String loopArrowMarkerId(String hex) =>
      'loop-arrowhead-${hex.replaceAll('#', '')}';

  static void addStyles(
    StringBuffer buffer, {
    bool includeAcceptingMask = true,
    Set<String> arrowColors = const <String>{defaultStrokeHex},
  }) {
    buffer.writeln('<defs>');
    for (final hex in arrowColors) {
      // Arrow markers for transitions
      buffer.writeln(
        '  <marker id="${arrowMarkerId(hex)}" markerWidth="10"'
        ' markerHeight="7"',
      );
      buffer.writeln('    refX="9" refY="3.5" orient="auto">');
      buffer.writeln(
        '    <polygon points="0 0, 10 3.5, 0 7" fill="$hex" stroke="$hex"/>',
      );
      buffer.writeln('  </marker>');

      // Self-loops are small rings, so they get an arrowhead scaled to them
      // instead of the one sized for full-length transitions.
      buffer.writeln(
        '  <marker id="${loopArrowMarkerId(hex)}"'
        ' markerUnits="userSpaceOnUse"'
        ' markerWidth="${formatDimension(loopArrowLength)}"'
        ' markerHeight="${formatDimension(loopArrowWidth)}"',
      );
      buffer.writeln(
        '    refX="${formatDimension(loopArrowLength)}"'
        ' refY="${formatDimension(loopArrowWidth / 2)}" orient="auto">',
      );
      buffer.writeln(
        '    <polygon points="0 0, ${formatDimension(loopArrowLength)}'
        ' ${formatDimension(loopArrowWidth / 2)},'
        ' 0 ${formatDimension(loopArrowWidth)}" fill="$hex" stroke="$hex"/>',
      );
      buffer.writeln('  </marker>');
    }

    // State masks for double circles (accepting states)
    if (includeAcceptingMask) {
      buffer.writeln('  <mask id="accepting-state-mask">');
      buffer.writeln('    <rect width="100%" height="100%" fill="white"/>');
      buffer.writeln(
        '    <circle cx="0" cy="0" r="${formatDimension(stateRadius)}" fill="transparent"',
      );
      buffer.writeln('      stroke="black" stroke-width="3"/>');
      buffer.writeln('  </mask>');
    }

    buffer.writeln('</defs>');
    buffer.writeln('<style>');
    buffer.writeln(
      '  .state { font-family: $fontFamily; font-size: 14px; text-anchor: middle; }',
    );
    buffer.writeln(
      '  .transition { font-family: $fontFamily; '
      'font-size: ${formatDimension(transitionFontSize)}px; '
      'text-anchor: middle; }',
    );
    buffer.writeln('  .tape { font-family: monospace; font-size: 16px; }');
    buffer.writeln(
      '  .tape-cell { fill: #f5f5f5; stroke: #424242; stroke-width: 1; }',
    );
    buffer.writeln(
      '  .tape-symbol { font-family: monospace; font-size: 16px; text-anchor: middle; dominant-baseline: middle; }',
    );
    buffer.writeln('  .head { fill: #d32f2f; }');
    buffer.writeln(
      '  .legend { font-family: $fontFamily; font-size: 12px; fill: #424242; }',
    );
    buffer.writeln(
      '  .annotation { font-family: $fontFamily; font-size: 12px; }',
    );
    buffer.writeln('</style>');
  }

  static String colorToHex(Color color) {
    final value = color.toARGB32() & 0x00FFFFFF;
    return '#${value.toRadixString(16).padLeft(6, '0')}';
  }

  static String escapeXml(String value) {
    return value
        .replaceAll('&', '&amp;')
        .replaceAll('<', '&lt;')
        .replaceAll('>', '&gt;')
        .replaceAll('"', '&quot;');
  }

  static void addInitialArrow(
    StringBuffer buffer,
    Vector2 position, {
    String strokeColor = defaultStrokeHex,
  }) {
    // Draw arrow pointing to initial state
    final arrowStartX = position.x - stateRadius - 20;
    final arrowStartY = position.y;
    final arrowEndX = position.x - stateRadius;

    buffer.writeln(
      '    <line x1="${formatDimension(arrowStartX)}" y1="${formatDimension(arrowStartY)}"',
    );
    buffer.writeln(
      '      x2="${formatDimension(arrowEndX)}" y2="${formatDimension(arrowStartY)}"',
    );
    buffer.writeln(
      '      stroke="$strokeColor" stroke-width="${formatDimension(strokeWidth)}"',
    );
    buffer.writeln('      marker-end="url(#${arrowMarkerId(strokeColor)})"/>');
  }

  static void addTitle(
    StringBuffer buffer,
    String title,
    double width,
    double height,
  ) {
    buffer.writeln('  <g class="title">');
    buffer.writeln(
      '    <text x="${formatDimension(width / 2)}" y="${formatDimension(30)}" font-size="18" font-weight="bold"',
    );
    buffer.writeln('      text-anchor="middle">${escapeXml(title)}</text>');
    buffer.writeln('  </g>');
  }

  static Offset toOffset(Vector2 value) => Offset(value.x, value.y);
}
