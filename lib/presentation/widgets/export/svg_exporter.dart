//
//  svg_exporter.dart
//  Turing Lab
//
//  Utility that generates SVG representations of automata, grammars, and
//  Turing machines, converting domain entities into vector diagrams with
//  consistent styles. The class offers customization options, builds
//  headers and graphic definitions, and encapsulates layout routines for
//  states, transitions, and tapes.
//
//  Thales Matheus Mendonça Santos - October 2025
//
import 'dart:math' as math;
import 'package:flutter/material.dart' hide Colors;
import 'package:graphview/graphview_turing_lab.dart'
    show resolveCircularConnectionPoint, resolveSelfLoopArc;
import 'package:vector_math/vector_math_64.dart';

import '../../../core/constants/automaton_canvas_constants.dart';
import '../../../core/annotations/annotations.dart';
import '../../../core/constants/svg_export_defaults.dart';
import '../../../core/entities/grammar_entity.dart';
import '../../../core/entities/turing_machine_entity.dart';
import '../../../core/models/fsa.dart';
import '../../../core/models/pda.dart';
import '../../../core/models/pda_transition.dart';
import '../../../core/utils/epsilon_utils.dart';
import '../../../features/canvas/graphview/automatic_transition_route_planner.dart';

/// Enhanced SVG exporter for automata visualizations
class SvgExporter {
  static const double _defaultWidth = 800.0;
  static const double _defaultHeight = 600.0;
  static const double _stateRadius = 25.0;
  static const double _strokeWidth = 2.0;

  /// Stroke used by diagrams that carry no colour scheme.
  static const String _defaultStrokeHex = '#000000';

  /// Ratio between a canvas state and an exported one. Canvas positions are
  /// scaled by it so spacing reads the same on the sheet as on screen.
  static const double _canvasToExportScale =
      _stateRadius / (kAutomatonStateDiameter / 2);

  /// Free border, in state radii, kept around a layout mapped from the canvas.
  static const double _layoutMarginFactor = 2.5;

  /// Font size of transition labels, the gap between a self-loop's ring and
  /// its own label, and the gap between a transition's curve and its label.
  static const double _transitionFontSize = 12.0;
  static const double _selfLoopLabelGap = 8.0;
  static const double _transitionLabelGap = 10.0;

  /// Distance, in state radii, between the two lanes a pair of opposing
  /// transitions is split into.
  static const double _laneSpacingFactor = 0.7;

  /// Arrowhead drawn at the end of a self-loop, scaled to the loop's ring
  /// rather than to a full-length transition.
  static const double _loopArrowLength = _stateRadius * 0.3;
  static const double _loopArrowWidth = _stateRadius * 0.22;
  static const String _fontFamily = 'Arial, sans-serif';

  static String _formatDimension(num value) {
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

  /// Exports an FSA to SVG format.
  static String exportFsaToSvg(
    FSA automaton, {
    double width = _defaultWidth,
    double height = _defaultHeight,
    SvgExportOptions? options,
  }) {
    return _exportAutomatonDiagramToSvg(
      _fsaToDiagram(automaton),
      width: width,
      height: height,
      options: options,
    );
  }

  /// Exports a PDA to SVG format.
  static String exportPdaToSvg(
    PDA pda, {
    double width = _defaultWidth,
    double height = _defaultHeight,
    SvgExportOptions? options,
  }) {
    return _exportAutomatonDiagramToSvg(
      _pdaToDiagram(pda),
      width: width,
      height: height,
      options: options,
    );
  }

  static String _exportAutomatonDiagramToSvg(
    _SvgAutomaton automaton, {
    double width = _defaultWidth,
    double height = _defaultHeight,
    SvgExportOptions? options,
  }) {
    final opts = options ?? const SvgExportOptions();
    final buffer = StringBuffer();
    final scaledWidth = width * opts.scale;
    final scaledHeight = height * opts.scale;
    final hasStates = automaton.states.isNotEmpty;

    // SVG header
    buffer.writeln('<?xml version="1.0" encoding="UTF-8" standalone="no"?>');
    buffer.writeln('<!DOCTYPE svg PUBLIC "-//W3C//DTD SVG 1.1//EN"');
    buffer.writeln('  "http://www.w3.org/Graphics/SVG/1.1/DTD/svg11.dtd">');
    buffer.writeln(
      '<svg width="${_formatDimension(scaledWidth)}px" height="${_formatDimension(scaledHeight)}px"',
    );
    buffer.writeln(
      '  viewBox="0 0 ${_formatDimension(width)} ${_formatDimension(height)}"',
    );
    buffer.writeln('  xmlns="http://www.w3.org/2000/svg"');
    buffer.writeln('  xmlns:xlink="http://www.w3.org/1999/xlink">');

    // Add styles
    _addSvgStyles(buffer, includeAcceptingMask: hasStates);

    // Add automaton content
    _addAutomatonContent(buffer, automaton, width, height, opts);

    buffer.writeln('</svg>');
    return buffer.toString();
  }

  /// Exports grammar to SVG format (as state diagram)
  static String exportGrammarToSvg(
    GrammarEntity grammar, {
    double width = _defaultWidth,
    double height = _defaultHeight,
    SvgExportOptions? options,
  }) {
    // Convert grammar to automaton for visualization
    final automaton = _grammarToDiagram(grammar);
    return _exportAutomatonDiagramToSvg(
      automaton,
      width: width,
      height: height,
      options: options,
    );
  }

  /// Exports a Turing machine SVG with tape cells, head marker, states,
  /// transitions, and optional legend/title content.
  static String exportTuringMachineToSvg(
    TuringMachineEntity tm, {
    double width = _defaultWidth,
    double height = _defaultHeight,
    SvgExportOptions? options,
  }) {
    final opts = options ?? const SvgExportOptions();
    final buffer = StringBuffer();
    final scaledWidth = width * opts.scale;
    final scaledHeight = height * opts.scale;

    buffer.writeln('<?xml version="1.0" encoding="UTF-8" standalone="no"?>');
    buffer.writeln('<!DOCTYPE svg PUBLIC "-//W3C//DTD SVG 1.1//EN"');
    buffer.writeln('  "http://www.w3.org/Graphics/SVG/1.1/DTD/svg11.dtd">');
    buffer.writeln(
      '<svg width="${_formatDimension(scaledWidth)}px" height="${_formatDimension(scaledHeight)}px"',
    );
    buffer.writeln(
      '  viewBox="0 0 ${_formatDimension(width)} ${_formatDimension(height)}"',
    );
    buffer.writeln('  xmlns="http://www.w3.org/2000/svg"');
    buffer.writeln('  xmlns:xlink="http://www.w3.org/1999/xlink">');

    final tmStroke = _colorToHex(
      opts.colorScheme?.outline ?? const Color(0xFF424242),
    );
    _addSvgStyles(buffer, arrowColors: <String>{_defaultStrokeHex, tmStroke});

    buffer.writeln('  <g>');

    final tapeLayout = _buildTapeCells(buffer, tm, width, height, opts);
    _drawHeadIndicator(buffer, tapeLayout, opts);

    final statePositions = _layoutStatesForTm(tm.states, width, height);
    _drawTuringTransitions(buffer, tm, statePositions, opts);
    _drawTuringStates(buffer, tm, statePositions, opts);
    _addAnnotations(buffer, opts, width, height, statePositions);

    if (opts.includeLegend) {
      _drawTuringLegend(buffer, width, height, opts);
    }

    if (opts.includeTitle) {
      _addTitle(buffer, tm.name, width, height);
    }

    buffer.writeln('  </g>');
    buffer.writeln('</svg>');
    return buffer.toString();
  }

  /// Id of the arrowhead marker tinted [hex], so an arrow never contradicts
  /// the stroke it terminates.
  static String _arrowMarkerId(String hex) =>
      'arrowhead-${hex.replaceAll('#', '')}';

  static String _loopArrowMarkerId(String hex) =>
      'loop-arrowhead-${hex.replaceAll('#', '')}';

  static void _addSvgStyles(
    StringBuffer buffer, {
    bool includeAcceptingMask = true,
    Set<String> arrowColors = const <String>{_defaultStrokeHex},
  }) {
    buffer.writeln('<defs>');
    for (final hex in arrowColors) {
      // Arrow markers for transitions
      buffer.writeln(
        '  <marker id="${_arrowMarkerId(hex)}" markerWidth="10"'
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
        '  <marker id="${_loopArrowMarkerId(hex)}"'
        ' markerUnits="userSpaceOnUse"'
        ' markerWidth="${_formatDimension(_loopArrowLength)}"'
        ' markerHeight="${_formatDimension(_loopArrowWidth)}"',
      );
      buffer.writeln(
        '    refX="${_formatDimension(_loopArrowLength)}"'
        ' refY="${_formatDimension(_loopArrowWidth / 2)}" orient="auto">',
      );
      buffer.writeln(
        '    <polygon points="0 0, ${_formatDimension(_loopArrowLength)}'
        ' ${_formatDimension(_loopArrowWidth / 2)},'
        ' 0 ${_formatDimension(_loopArrowWidth)}" fill="$hex" stroke="$hex"/>',
      );
      buffer.writeln('  </marker>');
    }

    // State masks for double circles (accepting states)
    if (includeAcceptingMask) {
      buffer.writeln('  <mask id="accepting-state-mask">');
      buffer.writeln('    <rect width="100%" height="100%" fill="white"/>');
      buffer.writeln(
        '    <circle cx="0" cy="0" r="${_formatDimension(_stateRadius)}" fill="transparent"',
      );
      buffer.writeln('      stroke="black" stroke-width="3"/>');
      buffer.writeln('  </mask>');
    }

    buffer.writeln('</defs>');
    buffer.writeln('<style>');
    buffer.writeln(
      '  .state { font-family: $_fontFamily; font-size: 14px; text-anchor: middle; }',
    );
    buffer.writeln(
      '  .transition { font-family: $_fontFamily; '
      'font-size: ${_formatDimension(_transitionFontSize)}px; '
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
      '  .legend { font-family: $_fontFamily; font-size: 12px; fill: #424242; }',
    );
    buffer.writeln(
      '  .annotation { font-family: $_fontFamily; font-size: 12px; }',
    );
    buffer.writeln('</style>');
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
    final cellWidth =
        cellsCount > 0 ? availableWidth / cellsCount : minCellWidth;
    final tapeStartX = (width - cellWidth * cellsCount) / 2;

    final colorScheme = options.colorScheme;
    final tapeFill =
        colorScheme?.surfaceContainerHighest ?? const Color(0xFFF5F5F5);
    final tapeStroke = colorScheme?.outlineVariant ??
        colorScheme?.outline ??
        const Color(0xFF424242);
    final textColor = colorScheme?.onSurface ?? const Color(0xFF000000);

    final blankSymbol = tm.blankSymbol.isEmpty ? '□' : tm.blankSymbol;
    final alphabet = tm.inputAlphabet.toList()..sort();

    buffer.writeln('    <g class="tape">');
    final formattedTapeTop = _formatDimension(tapeTop);
    final formattedCellWidth = _formatDimension(cellWidth);
    final formattedTapeHeight = _formatDimension(tapeHeight);
    for (var i = 0; i < cellsCount; i++) {
      final x = tapeStartX + i * cellWidth;
      final formattedX = _formatDimension(x);
      final textX = _formatDimension(x + cellWidth / 2);
      final textY = _formatDimension(tapeTop + tapeHeight / 2);
      final symbolIndex = alphabet.isEmpty ? 0 : i % alphabet.length;
      final symbol = i == cellsCount ~/ 2
          ? blankSymbol
          : (alphabet.isEmpty ? blankSymbol : alphabet[symbolIndex]);

      buffer.writeln(
        '      <rect class="tape-cell" x="$formattedX" y="$formattedTapeTop" width="$formattedCellWidth" height="$formattedTapeHeight"',
      );
      buffer.writeln(
        '        fill="${_colorToHex(tapeFill)}" stroke="${_colorToHex(tapeStroke)}"/>',
      );
      buffer.writeln(
        '      <text x="$textX" y="$textY" class="tape-symbol" fill="${_colorToHex(textColor)}">$symbol</text>',
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
    final formattedBaseLeftX = _formatDimension(baseLeftX);
    final formattedBaseRightX = _formatDimension(baseRightX);
    final formattedBaseY = _formatDimension(baseY);
    final formattedHeadTipX = _formatDimension(headTipX);
    final formattedHeadTipY = _formatDimension(headTipY);

    buffer.writeln(
      '    <polygon class="head" points="$formattedBaseLeftX $formattedBaseY, $formattedBaseRightX $formattedBaseY, $formattedHeadTipX $formattedHeadTipY" fill="${_colorToHex(headColor)}"/>',
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
        final cx = _formatDimension(position.x);
        final cy = _formatDimension(position.y);
        final outerRadius = _formatDimension(_stateRadius + 5);
        buffer.writeln('      <circle cx="$cx" cy="$cy" r="$outerRadius"');
        buffer.writeln(
          '        fill="none" stroke="${_colorToHex(strokeColor)}" stroke-width="3"/>',
        );
      }

      final mainCx = _formatDimension(position.x);
      final mainCy = _formatDimension(position.y);
      final radius = _formatDimension(_stateRadius);
      buffer.writeln('      <circle cx="$mainCx" cy="$mainCy" r="$radius"');
      buffer.writeln(
        '        fill="${_colorToHex(fillColor)}" stroke="${_colorToHex(strokeColor)}" stroke-width="${_formatDimension(_strokeWidth)}"/>',
      );

      if (state.isRejecting) {
        const lineOffset = _stateRadius * 0.6;
        final lineStartX1 = _formatDimension(position.x - lineOffset);
        final lineStartY1 = _formatDimension(position.y - lineOffset);
        final lineEndX1 = _formatDimension(position.x + lineOffset);
        final lineEndY1 = _formatDimension(position.y + lineOffset);
        final lineStartX2 = _formatDimension(position.x - lineOffset);
        final lineStartY2 = _formatDimension(position.y + lineOffset);
        final lineEndX2 = _formatDimension(position.x + lineOffset);
        final lineEndY2 = _formatDimension(position.y - lineOffset);
        buffer.writeln(
          '      <line x1="$lineStartX1" y1="$lineStartY1" x2="$lineEndX1" y2="$lineEndY1" stroke="${_colorToHex(strokeColor)}" stroke-width="1.5"/>',
        );
        buffer.writeln(
          '      <line x1="$lineStartX2" y1="$lineStartY2" x2="$lineEndX2" y2="$lineEndY2" stroke="${_colorToHex(strokeColor)}" stroke-width="1.5"/>',
        );
      }

      buffer.writeln(
        '      <text x="$mainCx" y="${_formatDimension(position.y + 5)}" class="state" fill="${_colorToHex(textColor)}">${state.name}</text>',
      );

      if (state.isInitial) {
        _addInitialArrow(buffer, position,
            strokeColor: _colorToHex(strokeColor));
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

    _writeRoutedTransitions(
      buffer,
      groups: _groupEdges(edges),
      positions: positions,
      initialStateIds: <String>{
        for (final state in tm.states)
          if (state.isInitial) state.id,
      },
      indent: '    ',
      strokeColor: _colorToHex(strokeColor),
      textColor: _colorToHex(textColor),
    );
  }

  static void _drawTuringLegend(
    StringBuffer buffer,
    double width,
    double height,
    SvgExportOptions options,
  ) {
    final colorScheme = options.colorScheme;
    final textColor = colorScheme?.onSurfaceVariant ??
        colorScheme?.onSurface ??
        const Color(0xFF424242);
    final legendY = height - 30;
    final legendYText = _formatDimension(legendY);
    final legendXText = _formatDimension(width / 2);

    buffer.writeln('    <g class="legend">');
    buffer.writeln(
      '      <text x="$legendXText" y="$legendYText" text-anchor="middle" fill="${_colorToHex(textColor)}">',
    );
    buffer.writeln(
      '        ${_escapeXml(options.tmLegendLabel)}',
    );
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

  static String _colorToHex(Color color) {
    final value = color.toARGB32() & 0x00FFFFFF;
    return '#${value.toRadixString(16).padLeft(6, '0')}';
  }

  static void _addAutomatonContent(
    StringBuffer buffer,
    _SvgAutomaton automaton,
    double width,
    double height,
    SvgExportOptions options,
  ) {
    if (automaton.states.isEmpty) {
      _addEmptyAutomatonPlaceholder(
        buffer,
        width,
        height,
        options.emptyAutomatonLabel,
      );
      if (options.includeTitle) {
        _addTitle(buffer, automaton.name, width, height);
      }
      _addAnnotations(buffer, options, width, height, const {});
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
    _addAnnotations(buffer, options, width, height, statePositions);

    // Add title if requested
    if (options.includeTitle) {
      _addTitle(buffer, automaton.name, width, height);
    }
  }

  static Map<String, Vector2> _calculateStatePositions(
    List<_SvgState> states,
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
    List<_SvgState> states,
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
    const margin = _stateRadius * _layoutMarginFactor;
    final usableWidth = math.max(width - (margin * 2), 1.0);
    final usableHeight = math.max(height - (margin * 2), 1.0);
    // Never magnify: at [_canvasToExportScale] a state keeps the same size
    // relative to its neighbours as it has on the canvas.
    final scale = math.min(
      _canvasToExportScale,
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
    _SvgAutomaton automaton,
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
      final cx = _formatDimension(pos.x);
      final cy = _formatDimension(pos.y);
      if (isAccepting) {
        final outerRadius = _formatDimension(_stateRadius + 5);
        // Draw double circle for accepting states
        buffer.writeln('    <circle cx="$cx" cy="$cy" r="$outerRadius"');
        buffer.writeln(
          '      fill="none" stroke="$strokeColor" stroke-width="${_formatDimension(strokeWidth)}"/>',
        );
      }
      final radius = _formatDimension(_stateRadius);
      buffer.writeln('    <circle cx="$cx" cy="$cy" r="$radius"');
      buffer.writeln('      fill="${isInitial ? '#e3f2fd' : '#fff'}"');
      buffer.writeln(
        '      stroke="$strokeColor" stroke-width="${_formatDimension(strokeWidth)}"/>',
      );

      // Add state label
      buffer.writeln(
        '    <text x="$cx" y="${_formatDimension(pos.y + 5)}" class="state">${state.name}</text>',
      );

      // Add initial arrow if needed
      if (isInitial) {
        _addInitialArrow(buffer, pos);
      }

      buffer.writeln('  </g>');
    }
  }

  static void _addTransitions(
    StringBuffer buffer,
    _SvgAutomaton automaton,
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

    _writeRoutedTransitions(
      buffer,
      groups: _groupEdges(edges),
      positions: positions,
      initialStateIds: <String>{
        for (final state in automaton.states)
          if (state.isInitial) state.id,
      },
      indent: '  ',
      strokeColor: _defaultStrokeHex,
      textColor: _defaultStrokeHex,
    );
  }

  static bool _pointsAreClose(Vector2 a, Vector2 b) {
    return (a - b).length2 < 1e-6;
  }

  /// Merges every transition running between the same ordered pair of states
  /// into one drawn path, the way the canvas does, so parallel symbols share
  /// a curve instead of stacking identical lines on top of each other.
  static List<_SvgEdgeGroup> _groupEdges(
    Iterable<(String, String, String)> edges,
  ) {
    final grouped = <String, _SvgEdgeGroup>{};
    for (final (fromId, toId, label) in edges) {
      final group = grouped.putIfAbsent(
        '$fromId->$toId',
        () => _SvgEdgeGroup(fromId: fromId, toId: toId),
      );
      if (label.isNotEmpty && !group.labels.contains(label)) {
        group.labels.add(label);
      }
    }
    return grouped.values.toList(growable: false);
  }

  /// Draws every transition through the planner the canvas routes with, so an
  /// exported diagram carries the same lanes, curves and loop placements.
  static void _writeRoutedTransitions(
    StringBuffer buffer, {
    required List<_SvgEdgeGroup> groups,
    required Map<String, Vector2> positions,
    required Set<String> initialStateIds,
    required String indent,
    required String strokeColor,
    required String textColor,
  }) {
    if (groups.isEmpty) {
      return;
    }

    final directed = <String>{
      for (final group in groups) '${group.fromId}->${group.toId}',
    };
    final borderTraffic = <String, List<double>>{};
    for (final group in groups) {
      if (group.isSelfLoop) {
        continue;
      }
      final delta = positions[group.toId]! - positions[group.fromId]!;
      if (delta.length < 0.001) {
        continue;
      }
      final outgoing = math.atan2(delta.y, delta.x);
      (borderTraffic[group.fromId] ??= <double>[]).add(outgoing);
      (borderTraffic[group.toId] ??= <double>[]).add(outgoing + math.pi);
    }

    final requests = <AutomaticTransitionRouteRequest>[
      for (var index = 0; index < groups.length; index++)
        _routeRequestFor(
          groups[index],
          index: index,
          positions: positions,
          initialStateIds: initialStateIds,
          borderTraffic: borderTraffic,
          directedPairs: directed,
        ),
    ];
    final plans = const AutomaticTransitionRoutePlanner().plan(
      requests: requests,
      obstacles: <AutomaticTransitionObstacle>[
        for (final entry in positions.entries)
          AutomaticTransitionObstacle(
            id: entry.key,
            center: _toOffset(entry.value),
            radius: _stateRadius,
          ),
      ],
    );

    for (var index = 0; index < groups.length; index++) {
      final group = groups[index];
      final plan = plans[requests[index].stableId];
      if (plan == null) {
        continue;
      }
      final label = group.labels.join(', ');
      if (group.isSelfLoop) {
        _writeSelfLoop(
          buffer,
          center: requests[index].sourceCenter,
          angle: plan.loopAngle ?? -math.pi / 2,
          padding: plan.loopPadding,
          label: label,
          indent: indent,
          strokeColor: strokeColor,
          textColor: textColor,
        );
      } else {
        _writeCurvedTransition(
          buffer,
          source: requests[index].sourceCenter,
          destination: requests[index].destinationCenter,
          plan: plan,
          label: label,
          indent: indent,
          strokeColor: strokeColor,
          textColor: textColor,
        );
      }
    }
  }

  static AutomaticTransitionRouteRequest _routeRequestFor(
    _SvgEdgeGroup group, {
    required int index,
    required Map<String, Vector2> positions,
    required Set<String> initialStateIds,
    required Map<String, List<double>> borderTraffic,
    required Set<String> directedPairs,
  }) {
    // Opposing traffic takes one lane each side of the straight line, the
    // same split the canvas applies to a two-way pair.
    final hasOpposing =
        directedPairs.contains('${group.toId}->${group.fromId}');
    final laneOffset = !hasOpposing || group.isSelfLoop
        ? 0.0
        : (group.fromId.compareTo(group.toId) <= 0 ? -1 : 1) *
            (_stateRadius * _laneSpacingFactor / 2);

    return AutomaticTransitionRouteRequest(
      // Index-keyed so the planner's ordering follows the drawing order.
      stableId: '${index.toString().padLeft(4, '0')}:'
          '${group.fromId}->${group.toId}',
      sourceId: group.fromId,
      destinationId: group.toId,
      sourceCenter: _toOffset(positions[group.fromId]!),
      destinationCenter: _toOffset(positions[group.toId]!),
      sourceRadius: _stateRadius,
      destinationRadius: _stateRadius,
      laneOffset: laneOffset,
      repulsionOffset: Offset.zero,
      loopRepulsors: group.isSelfLoop
          ? buildSelfLoopRepulsors(
              hasInitialMarker: initialStateIds.contains(group.fromId),
              borderTrafficDirections:
                  borderTraffic[group.fromId] ?? const <double>[],
            )
          : const <AutomaticTransitionLoopRepulsor>[],
    );
  }

  /// Emits the quadratic the canvas routes a transition along, trimmed to
  /// both states' borders.
  static void _writeCurvedTransition(
    StringBuffer buffer, {
    required Offset source,
    required Offset destination,
    required AutomaticTransitionRoutePlan plan,
    required String label,
    required String indent,
    required String strokeColor,
    required String textColor,
  }) {
    final start = resolveCircularConnectionPoint(
      center: source,
      radius: _stateRadius,
      toward: plan.controlPoint,
      fallbackDirection: destination - source,
    );
    final end = resolveCircularConnectionPoint(
      center: destination,
      radius: _stateRadius,
      toward: plan.controlPoint,
      fallbackDirection: source - destination,
    );

    buffer.writeln('$indent<g class="transition">');
    buffer.writeln(
      '$indent  <path d="M ${_formatDimension(start.dx)} '
      '${_formatDimension(start.dy)} '
      'Q ${_formatDimension(plan.controlPoint.dx)} '
      '${_formatDimension(plan.controlPoint.dy)} '
      '${_formatDimension(end.dx)} ${_formatDimension(end.dy)}"',
    );
    buffer.writeln(
      '$indent    fill="none" stroke="$strokeColor" '
      'stroke-width="${_formatDimension(_strokeWidth)}"',
    );
    buffer.writeln(
      '$indent    marker-end="url(#${_arrowMarkerId(strokeColor)})"/>',
    );

    if (label.isEmpty) {
      buffer.writeln('$indent</g>');
      return;
    }
    // Midpoint of the quadratic, pushed clear of the curve along the same
    // normal the canvas offsets the label card by.
    final midpoint = (start * 0.25) + (plan.controlPoint * 0.5) + (end * 0.25);
    _writeTransitionLabel(
      buffer,
      anchor: midpoint + plan.labelNormal * _transitionLabelGap,
      normal: plan.labelNormal,
      label: label,
      indent: indent,
      textColor: textColor,
    );
    buffer.writeln('$indent</g>');
  }

  /// Emits the compact circular loop the canvas draws, plus its label just
  /// outside the ring, along the loop's own heading.
  static void _writeSelfLoop(
    StringBuffer buffer, {
    required Offset center,
    required double angle,
    required double padding,
    required String label,
    required String indent,
    required String strokeColor,
    required String textColor,
  }) {
    final arc = resolveSelfLoopArc(
      nodeCenter: center,
      nodeRadius: _stateRadius,
      angle: angle,
      padding: padding,
    );
    final outward = Offset(math.cos(angle), math.sin(angle));

    buffer.writeln('$indent<g class="transition">');
    buffer.writeln(
      '$indent  <path d="M ${_formatDimension(arc.start.dx)} '
      '${_formatDimension(arc.start.dy)} '
      'A ${_formatDimension(arc.radius)} ${_formatDimension(arc.radius)} '
      '0 ${arc.isLargeArc ? 1 : 0} ${arc.sweep > 0 ? 1 : 0} '
      '${_formatDimension(arc.end.dx)} ${_formatDimension(arc.end.dy)}"',
    );
    buffer.writeln(
      '$indent    fill="none" stroke="$strokeColor" '
      'stroke-width="${_formatDimension(_strokeWidth)}"',
    );
    buffer.writeln(
      '$indent    marker-end="url(#${_loopArrowMarkerId(strokeColor)})"/>',
    );
    if (label.isNotEmpty) {
      _writeTransitionLabel(
        buffer,
        anchor: arc.center + outward * (arc.radius + _selfLoopLabelGap),
        normal: outward,
        label: label,
        indent: indent,
        textColor: textColor,
      );
    }
    buffer.writeln('$indent</g>');
  }

  static void _writeTransitionLabel(
    StringBuffer buffer, {
    required Offset anchor,
    required Offset normal,
    required String label,
    required String indent,
    required String textColor,
  }) {
    // SVG text grows upwards from its baseline: centre it on the anchor, and
    // drop it a full line more when the anchor sits below what it labels, so
    // the text never prints back over the path.
    final baselineY = anchor.dy +
        _transitionFontSize * (0.36 + 0.44 * math.max(0.0, normal.dy));
    buffer.writeln(
      '$indent  <text x="${_formatDimension(anchor.dx)}" '
      'y="${_formatDimension(baselineY)}" class="transition" '
      'fill="$textColor">$label</text>',
    );
  }

  static Offset _toOffset(Vector2 value) => Offset(value.x, value.y);

  static void _addEmptyAutomatonPlaceholder(
    StringBuffer buffer,
    double width,
    double height,
    String label,
  ) {
    buffer.writeln('  <g class="empty-automaton">');
    buffer.writeln(
      '    <text x="${_formatDimension(width / 2)}" y="${_formatDimension(height / 2)}"'
      ' class="transition" text-anchor="middle">${_escapeXml(label)}</text>',
    );
    buffer.writeln('  </g>');
  }

  static String _escapeXml(String value) {
    return value
        .replaceAll('&', '&amp;')
        .replaceAll('<', '&lt;')
        .replaceAll('>', '&gt;')
        .replaceAll('"', '&quot;');
  }

  static void _addAnnotations(
    StringBuffer buffer,
    SvgExportOptions options,
    double width,
    double height,
    Map<String, Vector2> statePositions,
  ) {
    final collection = options.annotations;
    if (!options.includeAnnotations || collection == null) return;
    buffer.writeln('  <g class="annotations">');
    for (final annotation in collection.annotations) {
      final attached = annotation.attachment;
      final statePosition = attached?.type == AnnotationTargetType.state
          ? statePositions[attached!.targetId]
          : null;
      final rawX = statePosition?.x ?? annotation.x;
      final rawY = statePosition?.y ?? annotation.y;
      final x = (rawX + (statePosition == null ? 0 : attached!.offsetX))
          .clamp(0, math.max(0, width - DocumentAnnotation.minimumWidth))
          .toDouble();
      final y = (rawY + (statePosition == null ? 0 : attached!.offsetY))
          .clamp(0, math.max(0, height - DocumentAnnotation.minimumHeight))
          .toDouble();
      final noteWidth = annotation.width
          .clamp(
            DocumentAnnotation.minimumWidth,
            math.max(DocumentAnnotation.minimumWidth, width - x),
          )
          .toDouble();
      final noteHeight = (annotation.collapsed
              ? DocumentAnnotation.minimumHeight
              : annotation.height)
          .clamp(
            DocumentAnnotation.minimumHeight,
            math.max(DocumentAnnotation.minimumHeight, height - y),
          )
          .toDouble();
      final (fill, stroke) = switch (annotation.styleRole) {
        AnnotationStyleRole.note => ('#fff3b0', '#8a6d00'),
        AnnotationStyleRole.information => ('#dbeafe', '#1d4ed8'),
        AnnotationStyleRole.warning => ('#fee2e2', '#b91c1c'),
        AnnotationStyleRole.question => ('#ede9fe', '#6d28d9'),
        AnnotationStyleRole.todo => ('#e5e7eb', '#374151'),
      };
      buffer.writeln(
          '    <g class="annotation" data-id="${_escapeXml(annotation.id)}">');
      buffer.writeln(
        '      <rect x="${_formatDimension(x)}" y="${_formatDimension(y)}" '
        'width="${_formatDimension(noteWidth)}" height="${_formatDimension(noteHeight)}" '
        'rx="8" fill="$fill" stroke="$stroke"/>',
      );
      if (!annotation.collapsed) {
        final lines = annotation.text.split('\n').take(8);
        var line = 0;
        for (final value in lines) {
          buffer.writeln(
            '      <text x="${_formatDimension(x + 10)}" '
            'y="${_formatDimension(y + 22 + line * 16)}" fill="$stroke">'
            '${_escapeXml(value)}</text>',
          );
          line++;
        }
      }
      buffer.writeln('    </g>');
    }
    buffer.writeln('  </g>');
  }

  static void _addInitialArrow(
    StringBuffer buffer,
    Vector2 position, {
    String strokeColor = _defaultStrokeHex,
  }) {
    // Draw arrow pointing to initial state
    final arrowStartX = position.x - _stateRadius - 20;
    final arrowStartY = position.y;
    final arrowEndX = position.x - _stateRadius;

    buffer.writeln(
      '    <line x1="${_formatDimension(arrowStartX)}" y1="${_formatDimension(arrowStartY)}"',
    );
    buffer.writeln(
      '      x2="${_formatDimension(arrowEndX)}" y2="${_formatDimension(arrowStartY)}"',
    );
    buffer.writeln(
      '      stroke="$strokeColor" stroke-width="${_formatDimension(_strokeWidth)}"',
    );
    buffer.writeln(
      '      marker-end="url(#${_arrowMarkerId(strokeColor)})"/>',
    );
  }

  static void _addTitle(
    StringBuffer buffer,
    String title,
    double width,
    double height,
  ) {
    buffer.writeln('  <g class="title">');
    buffer.writeln(
      '    <text x="${_formatDimension(width / 2)}" y="${_formatDimension(30)}" font-size="18" font-weight="bold"',
    );
    buffer.writeln('      text-anchor="middle">$title</text>');
    buffer.writeln('  </g>');
  }

  static _SvgAutomaton _fsaToDiagram(FSA automaton) {
    final transitions = <String, List<String>>{};

    for (final transition in automaton.fsaTransitions) {
      final symbols = transition.lambdaSymbol != null
          ? <String>{transition.lambdaSymbol!}
          : transition.inputSymbols;

      for (final symbol in symbols) {
        final label = normalizeToEpsilon(symbol);
        final key = '${transition.fromState.id}|$label';
        transitions.putIfAbsent(key, () => <String>[]).add(
              transition.toState.id,
            );
      }
    }

    return _SvgAutomaton(
      name: automaton.name,
      states: automaton.states
          .map(
            (state) => _SvgState(
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

  static _SvgAutomaton _pdaToDiagram(PDA pda) {
    final transitions = <String, List<String>>{};

    for (final transition in pda.pdaTransitions) {
      final label = _formatPdaTransitionLabel(transition);
      final key = '${transition.fromState.id}|$label';
      transitions.putIfAbsent(key, () => <String>[]).add(transition.toState.id);
    }

    return _SvgAutomaton(
      name: pda.name,
      states: pda.states
          .map(
            (state) => _SvgState(
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

  static String _formatPdaTransitionLabel(PDATransition transition) {
    final read = normalizeToEpsilon(
      transition.isLambdaInput ? '' : transition.inputSymbol,
    );
    final pop = normalizeToEpsilon(
      transition.isLambdaPop ? '' : transition.popSymbol,
    );
    final push = normalizeToEpsilon(
      transition.isLambdaPush ? '' : transition.pushSymbol,
    );
    return '$read,$pop->$push';
  }

  /// Converts grammar to automaton for visualization (simplified).
  static _SvgAutomaton _grammarToDiagram(GrammarEntity grammar) {
    // This is a simplified conversion for visualization purposes
    final states = <_SvgState>[];
    final transitions = <String, List<String>>{};

    // Create states for each non-terminal
    for (final variable in grammar.nonTerminals) {
      states.add(
        _SvgState(
          id: variable,
          name: variable,
          isInitial: variable == grammar.startSymbol,
          isFinal: false,
        ),
      );
    }

    // Create transitions based on productions (simplified)
    for (final production in grammar.productions) {
      final from =
          production.leftSide.isNotEmpty ? production.leftSide.first : '';
      for (final symbol in production.rightSide) {
        if (symbol.isNotEmpty) {
          final to =
              grammar.nonTerminals.contains(symbol) ? symbol : 'terminal';
          transitions.putIfAbsent(from, () => []);
          transitions[from]!.add(to);
        }
      }
    }

    return _SvgAutomaton(
      name: '${grammar.name} (Visualization)',
      states: states,
      transitions: transitions,
    );
  }
}

/// Every transition running between one ordered pair of states, merged into
/// the single path the canvas draws for them.
class _SvgEdgeGroup {
  _SvgEdgeGroup({required this.fromId, required this.toId});

  final String fromId;
  final String toId;
  final List<String> labels = <String>[];

  bool get isSelfLoop => fromId == toId;
}

class _SvgAutomaton {
  final String name;
  final List<_SvgState> states;
  final Map<String, List<String>> transitions;

  const _SvgAutomaton({
    required this.name,
    required this.states,
    required this.transitions,
  });
}

class _SvgState {
  final String id;
  final String name;
  final bool isInitial;
  final bool isFinal;

  /// Where the state sits on the canvas, when the source has a layout. Null
  /// for diagrams synthesised from a grammar, which are laid out on a grid.
  final Vector2? position;

  const _SvgState({
    required this.id,
    required this.name,
    required this.isInitial,
    required this.isFinal,
    this.position,
  });
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

/// Configuration options for SVG export
class SvgExportOptions {
  final bool includeTitle;
  final bool includeLegend;
  final double scale;
  final ColorScheme? colorScheme;
  final String emptyAutomatonLabel;
  final String tmLegendLabel;
  final bool includeAnnotations;
  final DocumentAnnotationCollection? annotations;

  const SvgExportOptions({
    this.includeTitle = true,
    this.includeLegend = false,
    this.scale = 1.0,
    this.colorScheme,
    this.emptyAutomatonLabel = kDefaultSvgEmptyAutomatonLabel,
    this.tmLegendLabel = kDefaultSvgTmLegendLabel,
    this.includeAnnotations = false,
    this.annotations,
  });
}

/// Color scheme for SVG export
class SvgColorScheme {
  final Color stateFill;
  final Color stateStroke;
  final Color acceptingStateFill;
  final Color acceptingStateStroke;
  final Color transitionStroke;
  final Color textColor;
  final Color backgroundColor;

  const SvgColorScheme({
    this.stateFill = const Color(0xFFFFFFFF),
    this.stateStroke = const Color(0xFF000000),
    this.acceptingStateFill = const Color(0xFFFFFFFF),
    this.acceptingStateStroke = const Color(0xFF000000),
    this.transitionStroke = const Color(0xFF000000),
    this.textColor = const Color(0xFF000000),
    this.backgroundColor = const Color(0xFFFFFFFF),
  });

  factory SvgColorScheme.dark() {
    return const SvgColorScheme(
      stateFill: Color(0xFF2D2D2D),
      stateStroke: Color(0xFFFFFFFF),
      acceptingStateFill: Color(0xFF2D2D2D),
      acceptingStateStroke: Color(0xFFFFFFFF),
      transitionStroke: Color(0xFFFFFFFF),
      textColor: Color(0xFFFFFFFF),
      backgroundColor: Color(0xFF1A1A1A),
    );
  }
}
