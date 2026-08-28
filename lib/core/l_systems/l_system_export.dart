import 'dart:convert';
import 'dart:typed_data';

import 'l_system_model.dart';
import 'l_system_turtle.dart';

final class LSystemRenderMetadata {
  const LSystemRenderMetadata({
    required this.documentId,
    required this.sourceRevision,
    required this.generation,
    required this.settings,
  });

  final String documentId;
  final int sourceRevision;
  final int generation;
  final LSystemTurtleSettings settings;
}

final class LSystemVectorExport {
  LSystemVectorExport({
    required Uint8List bytes,
    required this.width,
    required this.height,
  }) : bytes = Uint8List.fromList(bytes).asUnmodifiableView();

  final Uint8List bytes;
  final double width;
  final double height;
}

final class LSystemSvgExporter {
  const LSystemSvgExporter();

  LSystemVectorExport encode(
    LSystemGeometry geometry, {
    required LSystemRenderMetadata metadata,
    double padding = 8,
    String stroke = '#111827',
  }) {
    if (padding < 0 || stroke.isEmpty) {
      throw ArgumentError('SVG padding and stroke must be valid.');
    }
    final width =
        (geometry.bounds.width + padding * 2).clamp(1.0, double.infinity);
    final height =
        (geometry.bounds.height + padding * 2).clamp(1.0, double.infinity);
    final translateX = padding - geometry.bounds.minX;
    final translateY = padding - geometry.bounds.minY;
    final drawing = StringBuffer();
    for (final polygon in geometry.polygons) {
      final points = <String>[];
      for (var index = 0; index < polygon.coordinates.length; index += 2) {
        points.add(
          '${_number(polygon.coordinates[index] + translateX)},'
          '${_number(polygon.coordinates[index + 1] + translateY)}',
        );
      }
      drawing
        ..write('<polygon points="${points.join(' ')}" fill="')
        ..write(_color(polygon.colorArgb))
        ..write('"')
        ..write(_opacityAttribute('fill', polygon.colorArgb))
        ..write('/>');
    }
    for (var segment = 0; segment < geometry.segmentCount; segment++) {
      final index = segment * 4;
      final segmentColor = geometry.segmentColorsArgb[segment] == 0xff111827
          ? stroke
          : _color(geometry.segmentColorsArgb[segment]);
      final opacity = geometry.segmentColorsArgb[segment] == 0xff111827
          ? ''
          : _opacityAttribute(
              'stroke',
              geometry.segmentColorsArgb[segment],
            );
      drawing
        ..write('<path d="M')
        ..write(_number(geometry.segmentCoordinates[index] + translateX))
        ..write(' ')
        ..write(_number(geometry.segmentCoordinates[index + 1] + translateY))
        ..write('L')
        ..write(_number(geometry.segmentCoordinates[index + 2] + translateX))
        ..write(' ')
        ..write(_number(geometry.segmentCoordinates[index + 3] + translateY))
        ..write('" fill="none" stroke="${_xml(segmentColor)}" ')
        ..write(opacity)
        ..write('stroke-width="${_number(geometry.segmentWidths[segment])}" ')
        ..write('stroke-linecap="round" stroke-linejoin="round"/>');
    }
    final encodedMetadata = const JsonEncoder().convert({
      'documentId': metadata.documentId,
      'sourceRevision': metadata.sourceRevision,
      'generation': metadata.generation,
      'turtle': metadata.settings.toJson(),
    });
    final svg = '<svg xmlns="http://www.w3.org/2000/svg" '
        'width="${_number(width)}" height="${_number(height)}" '
        'viewBox="0 0 ${_number(width)} ${_number(height)}">'
        '<metadata>${_xml(encodedMetadata)}</metadata>'
        '$drawing'
        '</svg>';
    return LSystemVectorExport(
      bytes: Uint8List.fromList(utf8.encode(svg)),
      width: width,
      height: height,
    );
  }
}

abstract interface class LSystemPngRasterizer {
  Future<Uint8List> encode(
    LSystemGeometry geometry, {
    required LSystemRenderMetadata metadata,
    int width = 1024,
    int height = 1024,
    double padding = 24,
  });
}

String _number(double value) {
  final fixed = value.toStringAsFixed(6);
  return fixed.replaceFirst(RegExp(r'\.?0+$'), '');
}

String _color(int argb) =>
    '#${(argb & 0xffffff).toRadixString(16).padLeft(6, '0')}';

String _opacityAttribute(String name, int argb) {
  final alpha = (argb >> 24) & 0xff;
  return alpha == 0xff ? '' : ' $name-opacity="${_number(alpha / 255)}" ';
}

String _xml(String value) => value
    .replaceAll('&', '&amp;')
    .replaceAll('<', '&lt;')
    .replaceAll('>', '&gt;')
    .replaceAll('"', '&quot;')
    .replaceAll("'", '&apos;');
