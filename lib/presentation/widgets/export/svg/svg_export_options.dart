//
//  svg_export_options.dart
//  Turing Lab
//
//  Options and colour scheme accepted by the SVG exporter and its renderers.
//

import 'package:flutter/material.dart' hide Colors;

import '../../../../core/annotations/annotations.dart';
import '../../../../core/constants/svg_export_defaults.dart';
import '../../../../core/utils/epsilon_utils.dart';

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
  final String emptyStringSymbol;

  const SvgExportOptions({
    this.includeTitle = true,
    this.includeLegend = false,
    this.scale = 1.0,
    this.colorScheme,
    this.emptyAutomatonLabel = kDefaultSvgEmptyAutomatonLabel,
    this.tmLegendLabel = kDefaultSvgTmLegendLabel,
    this.includeAnnotations = false,
    this.annotations,
    this.emptyStringSymbol = kEpsilonSymbol,
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
