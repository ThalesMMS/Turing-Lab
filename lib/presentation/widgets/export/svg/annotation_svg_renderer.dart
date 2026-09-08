//
//  annotation_svg_renderer.dart
//  Turing Lab
//
//  Renders sticky notes and free annotations of a document onto the SVG
//  sheet, clamped to the sheet and anchored to state positions when attached.
//

import 'dart:math' as math;

import 'package:vector_math/vector_math_64.dart';

import '../../../../core/annotations/annotations.dart';
import 'svg_export_options.dart';
import 'svg_primitives.dart';

abstract final class AnnotationSvgRenderer {
  static void render(
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
      final noteHeight =
          (annotation.collapsed
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
        '    <g class="annotation" data-id="${SvgPrimitives.escapeXml(annotation.id)}">',
      );
      buffer.writeln(
        '      <rect x="${SvgPrimitives.formatDimension(x)}" y="${SvgPrimitives.formatDimension(y)}" '
        'width="${SvgPrimitives.formatDimension(noteWidth)}" height="${SvgPrimitives.formatDimension(noteHeight)}" '
        'rx="8" fill="$fill" stroke="$stroke"/>',
      );
      if (!annotation.collapsed) {
        final lines = annotation.text.split('\n').take(8);
        var line = 0;
        for (final value in lines) {
          buffer.writeln(
            '      <text x="${SvgPrimitives.formatDimension(x + 10)}" '
            'y="${SvgPrimitives.formatDimension(y + 22 + line * 16)}" fill="$stroke">'
            '${SvgPrimitives.escapeXml(value)}</text>',
          );
          line++;
        }
      }
      buffer.writeln('    </g>');
    }
    buffer.writeln('  </g>');
  }
}
