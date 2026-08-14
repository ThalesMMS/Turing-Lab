//
//  svg_exporter.dart
//  Turing Lab
//
//  Utilitário responsável por gerar representações SVG de autômatos, gramáticas
//  e máquinas de Turing, convertendo entidades do domínio em diagramas vetoriais
//  com estilos consistentes. A classe oferece opções de personalização, monta
//  cabeçalhos e definições gráficas e encapsula rotinas de layout para estados,
//  transições e fitas.
//
//  Thales Matheus Mendonça Santos - October 2025
//
import 'dart:math' as math;
import 'package:flutter/material.dart' hide Colors;
import 'package:vector_math/vector_math_64.dart';

import '../../../core/entities/grammar_entity.dart';
import '../../../core/entities/turing_machine_entity.dart';
import '../../../core/models/fsa.dart';
import '../../../core/models/pda.dart';
import '../../../core/models/pda_transition.dart';
import '../../../core/utils/epsilon_utils.dart';

/// Enhanced SVG exporter for automata visualizations
class SvgExporter {
  static const double _defaultWidth = 800.0;
  static const double _defaultHeight = 600.0;
  static const double _stateRadius = 25.0;
  static const double _strokeWidth = 2.0;
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

    _addSvgStyles(buffer);

    buffer.writeln('  <g>');

    final tapeLayout = _buildTapeCells(buffer, tm, width, height, opts);
    _drawHeadIndicator(buffer, tapeLayout, opts);

    final statePositions = _layoutStatesForTm(tm.states, width, height);
    _drawTuringTransitions(buffer, tm, statePositions, opts);
    _drawTuringStates(buffer, tm, statePositions, opts);

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

  static void _addSvgStyles(
    StringBuffer buffer, {
    bool includeAcceptingMask = true,
  }) {
    buffer.writeln('<defs>');
    // Arrow markers for transitions
    buffer.writeln(
      '  <marker id="arrowhead" markerWidth="10" markerHeight="7"',
    );
    buffer.writeln('    refX="9" refY="3.5" orient="auto">');
    buffer.writeln(
      '    <polygon points="0 0, 10 3.5, 0 7" fill="#000" stroke="#000"/>',
    );
    buffer.writeln('  </marker>');

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
      '  .transition { font-family: $_fontFamily; font-size: 12px; text-anchor: middle; }',
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

    for (var i = 0; i < states.length; i++) {
      final angle = (2 * math.pi * i) / states.length;
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
        _addInitialArrow(buffer, position);
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

    for (final transition in tm.transitions) {
      final from = positions[transition.fromStateId];
      final to = positions[transition.toStateId];
      if (from == null || to == null) {
        continue;
      }

      final label = '${transition.readSymbol}/${transition.writeSymbol}, '
          '${_directionLabel(transition.moveDirection)}';

      if (from == to) {
        const loopRadius = _stateRadius + 20;
        final startX = from.x;
        final startY = from.y - _stateRadius;
        const controlOffset = loopRadius * 1.2;
        final formattedStartX = _formatDimension(startX);
        final formattedStartY = _formatDimension(startY);
        final formattedControlX1 = _formatDimension(startX + controlOffset);
        final formattedControlY1 = _formatDimension(startY - controlOffset);
        final formattedControlX2 = _formatDimension(startX - controlOffset);
        final formattedControlY2 = _formatDimension(startY - controlOffset);
        final formattedLoopStartY = _formatDimension(startY - loopRadius);

        buffer.writeln('    <g class="transition">');
        buffer.writeln(
          '      <path d="M $formattedStartX $formattedStartY C $formattedControlX1 $formattedControlY1, $formattedControlX2 $formattedControlY2, $formattedStartX $formattedStartY"',
        );
        buffer.writeln(
          '        fill="none" stroke="${_colorToHex(strokeColor)}" stroke-width="${_formatDimension(_strokeWidth)}" marker-end="url(#arrowhead)"/>',
        );
        buffer.writeln(
          '      <text x="$formattedStartX" y="$formattedLoopStartY" class="transition" fill="${_colorToHex(textColor)}">$label</text>',
        );
        buffer.writeln('    </g>');
        continue;
      }

      final midX = (from.x + to.x) / 2;
      final midY = (from.y + to.y) / 2;
      final formattedFromX = _formatDimension(from.x);
      final formattedFromY = _formatDimension(from.y);
      final formattedToX = _formatDimension(to.x);
      final formattedToY = _formatDimension(to.y);
      final formattedMidX = _formatDimension(midX);
      final formattedMidY = _formatDimension(midY);

      buffer.writeln('    <g class="transition">');
      buffer.writeln(
        '      <line x1="$formattedFromX" y1="$formattedFromY" x2="$formattedToX" y2="$formattedToY" stroke="${_colorToHex(strokeColor)}" stroke-width="${_formatDimension(_strokeWidth)}" marker-end="url(#arrowhead)"/>',
      );
      buffer.writeln(
        '      <text x="$formattedMidX" y="$formattedMidY" class="transition" fill="${_colorToHex(textColor)}">$label</text>',
      );
      buffer.writeln('    </g>');
    }
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
    buffer.writeln('        δ(q, s) = (q′, w, d) — leitura/escrita/movimento');
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
      _addEmptyAutomatonPlaceholder(buffer, width, height);
      if (options.includeTitle) {
        _addTitle(buffer, automaton.name, width, height);
      }
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

        if (_pointsAreClose(fromPos, toPos)) {
          _drawSelfLoop(buffer, fromPos, symbol);
        } else {
          _drawTransitionEdge(buffer, fromPos, toPos, symbol);
        }
      }
    }
  }

  static bool _pointsAreClose(Vector2 a, Vector2 b) {
    return (a - b).length2 < 1e-6;
  }

  static void _drawTransitionEdge(
    StringBuffer buffer,
    Vector2 from,
    Vector2 to,
    String label,
  ) {
    final delta = to - from;
    final distance = delta.length;
    if (distance == 0) {
      _drawSelfLoop(buffer, from, label);
      return;
    }

    final direction = delta / distance;
    final start = from + direction * _stateRadius;
    final end = to - direction * _stateRadius;

    buffer.writeln('  <g class="transition">');
    buffer.writeln(
      '    <line x1="${_formatDimension(start.x)}" y1="${_formatDimension(start.y)}"',
    );
    buffer.writeln(
      '      x2="${_formatDimension(end.x)}" y2="${_formatDimension(end.y)}"',
    );
    buffer.writeln(
      '      stroke="#000" stroke-width="${_formatDimension(_strokeWidth)}"',
    );
    buffer.writeln('      marker-end="url(#arrowhead)"/>');

    final midPoint = (start + end) / 2;
    buffer.writeln(
      '    <text x="${_formatDimension(midPoint.x)}" y="${_formatDimension(midPoint.y - 5)}" class="transition">$label</text>',
    );
    buffer.writeln('  </g>');
  }

  static void _drawSelfLoop(StringBuffer buffer, Vector2 center, String label) {
    const loopOffset = 24.0;
    final startX = center.x;
    final startY = center.y - _stateRadius;
    const controlOffset = _stateRadius + loopOffset;

    final control1 = Vector2(
      center.x - controlOffset,
      center.y - controlOffset,
    );
    final control2 = Vector2(
      center.x + controlOffset,
      center.y - controlOffset,
    );
    final endPoint = Vector2(startX + 0.01, startY - 0.01);

    buffer.writeln('  <g class="transition">');
    buffer.writeln(
      '    <path d="M ${_formatDimension(startX)} ${_formatDimension(startY)} '
      'C ${_formatDimension(control1.x)} ${_formatDimension(control1.y)} '
      '${_formatDimension(control2.x)} ${_formatDimension(control2.y)} '
      '${_formatDimension(endPoint.x)} ${_formatDimension(endPoint.y)}"',
    );
    buffer.writeln(
      '      fill="none" stroke="#000" stroke-width="${_formatDimension(_strokeWidth)}"',
    );
    buffer.writeln('      marker-end="url(#arrowhead)"/>');

    final labelPosition = Vector2(center.x, center.y - controlOffset - 6);
    buffer.writeln(
      '    <text x="${_formatDimension(labelPosition.x)}" y="${_formatDimension(labelPosition.y)}" class="transition">$label</text>',
    );
    buffer.writeln('  </g>');
  }

  static void _addEmptyAutomatonPlaceholder(
    StringBuffer buffer,
    double width,
    double height,
  ) {
    buffer.writeln('  <g class="empty-automaton">');
    buffer.writeln(
      '    <text x="${_formatDimension(width / 2)}" y="${_formatDimension(height / 2)}"'
      ' class="transition" text-anchor="middle">No states defined</text>',
    );
    buffer.writeln('  </g>');
  }

  static void _addInitialArrow(StringBuffer buffer, Vector2 position) {
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
      '      stroke="#000" stroke-width="${_formatDimension(_strokeWidth)}"',
    );
    buffer.writeln('      marker-end="url(#arrowhead)"/>');
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

  const _SvgState({
    required this.id,
    required this.name,
    required this.isInitial,
    required this.isFinal,
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

  const SvgExportOptions({
    this.includeTitle = true,
    this.includeLegend = false,
    this.scale = 1.0,
    this.colorScheme,
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
