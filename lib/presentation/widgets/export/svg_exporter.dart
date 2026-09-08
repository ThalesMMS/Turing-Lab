//
//  svg_exporter.dart
//  Turing Lab
//
//  Entry point for SVG export. The exporter owns the sheet: dimensions and
//  scale, the XML/SVG header, the <defs>/<style> block and the closing tag.
//  Each domain draws its body through an SvgDiagramRenderer under
//  export/svg/, so adding a diagram type never touches this coordinator.
//
//  Thales Matheus Mendonça Santos - October 2025
//
import '../../../core/entities/grammar_entity.dart';
import '../../../core/entities/turing_machine_entity.dart';
import '../../../core/models/fsa.dart';
import '../../../core/models/pda.dart';
import 'svg/automaton_svg_renderer.dart';
import 'svg/grammar_svg_renderer.dart';
import 'svg/pda_svg_renderer.dart';
import 'svg/svg_diagram_renderer.dart';
import 'svg/svg_export_options.dart';
import 'svg/svg_primitives.dart';
import 'svg/tm_svg_renderer.dart';

export 'svg/svg_export_options.dart';

/// Enhanced SVG exporter for automata visualizations
class SvgExporter {
  static const double _defaultWidth = 800.0;
  static const double _defaultHeight = 600.0;

  /// Exports an FSA to SVG format.
  static String exportFsaToSvg(
    FSA automaton, {
    double width = _defaultWidth,
    double height = _defaultHeight,
    SvgExportOptions? options,
  }) => exportDiagram(
    const FsaSvgRenderer(),
    automaton,
    width: width,
    height: height,
    options: options,
  );

  /// Exports a PDA to SVG format.
  static String exportPdaToSvg(
    PDA pda, {
    double width = _defaultWidth,
    double height = _defaultHeight,
    SvgExportOptions? options,
  }) => exportDiagram(
    const PdaSvgRenderer(),
    pda,
    width: width,
    height: height,
    options: options,
  );

  /// Exports grammar to SVG format (as state diagram)
  static String exportGrammarToSvg(
    GrammarEntity grammar, {
    double width = _defaultWidth,
    double height = _defaultHeight,
    SvgExportOptions? options,
  }) => exportDiagram(
    const GrammarSvgRenderer(),
    grammar,
    width: width,
    height: height,
    options: options,
  );

  /// Exports a Turing machine SVG with tape cells, head marker, states,
  /// transitions, and optional legend/title content.
  static String exportTuringMachineToSvg(
    TuringMachineEntity tm, {
    double width = _defaultWidth,
    double height = _defaultHeight,
    SvgExportOptions? options,
  }) => exportDiagram(
    const TmSvgRenderer(),
    tm,
    width: width,
    height: height,
    options: options,
  );

  /// Renders [document] onto a sheet of [width] by [height] user units,
  /// scaled by the options' factor, with [renderer] drawing the body.
  static String exportDiagram<T>(
    SvgDiagramRenderer<T> renderer,
    T document, {
    double width = _defaultWidth,
    double height = _defaultHeight,
    SvgExportOptions? options,
  }) {
    final opts = options ?? const SvgExportOptions();
    final buffer = StringBuffer();
    final scaledWidth = width * opts.scale;
    final scaledHeight = height * opts.scale;

    // SVG header
    buffer.writeln('<?xml version="1.0" encoding="UTF-8" standalone="no"?>');
    buffer.writeln('<!DOCTYPE svg PUBLIC "-//W3C//DTD SVG 1.1//EN"');
    buffer.writeln('  "http://www.w3.org/Graphics/SVG/1.1/DTD/svg11.dtd">');
    buffer.writeln(
      '<svg width="${SvgPrimitives.formatDimension(scaledWidth)}px" height="${SvgPrimitives.formatDimension(scaledHeight)}px"',
    );
    buffer.writeln(
      '  viewBox="0 0 ${SvgPrimitives.formatDimension(width)} ${SvgPrimitives.formatDimension(height)}"',
    );
    buffer.writeln('  xmlns="http://www.w3.org/2000/svg"');
    buffer.writeln('  xmlns:xlink="http://www.w3.org/1999/xlink">');

    final styles = renderer.styles(document, opts);
    SvgPrimitives.addStyles(
      buffer,
      includeAcceptingMask: styles.includeAcceptingMask,
      arrowColors: styles.arrowColors,
    );

    renderer.render(
      buffer,
      document,
      width: width,
      height: height,
      options: opts,
    );

    buffer.writeln('</svg>');
    return buffer.toString();
  }
}
