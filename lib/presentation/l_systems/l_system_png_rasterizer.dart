import 'dart:typed_data';
import 'dart:ui' as ui;

import '../../core/l_systems/l_systems.dart';

/// Rasterizes the same immutable geometry used by the canvas and SVG exporter.
final class FlutterLSystemPngRasterizer implements LSystemPngRasterizer {
  const FlutterLSystemPngRasterizer({
    this.strokeColor = const ui.Color(0xff111827),
    this.backgroundColor = const ui.Color(0x00000000),
  });

  final ui.Color strokeColor;
  final ui.Color backgroundColor;

  @override
  Future<Uint8List> encode(
    LSystemGeometry geometry, {
    required LSystemRenderMetadata metadata,
    int width = 1024,
    int height = 1024,
    double padding = 24,
  }) async {
    if (width <= 0 || height <= 0 || padding < 0) {
      throw ArgumentError('PNG dimensions must be positive.');
    }
    final recorder = ui.PictureRecorder();
    final canvas = ui.Canvas(recorder);
    canvas.drawColor(backgroundColor, ui.BlendMode.src);
    final transform = LSystemFitTransform.contain(
      geometry.bounds,
      viewportWidth: width.toDouble(),
      viewportHeight: height.toDouble(),
      padding: padding,
    );
    for (final polygon in geometry.polygons) {
      final path = ui.Path();
      for (var index = 0; index < polygon.coordinates.length; index += 2) {
        final x =
            polygon.coordinates[index] * transform.scale + transform.translateX;
        final y = polygon.coordinates[index + 1] * transform.scale +
            transform.translateY;
        if (index == 0) {
          path.moveTo(x, y);
        } else {
          path.lineTo(x, y);
        }
      }
      path.close();
      canvas.drawPath(
        path,
        ui.Paint()
          ..color = ui.Color(polygon.colorArgb)
          ..style = ui.PaintingStyle.fill,
      );
    }
    for (var segment = 0; segment < geometry.segmentCount; segment++) {
      final index = segment * 4;
      final color = geometry.segmentColorsArgb[segment] == 0xff111827
          ? strokeColor
          : ui.Color(geometry.segmentColorsArgb[segment]);
      canvas.drawLine(
        ui.Offset(
          geometry.segmentCoordinates[index] * transform.scale +
              transform.translateX,
          geometry.segmentCoordinates[index + 1] * transform.scale +
              transform.translateY,
        ),
        ui.Offset(
          geometry.segmentCoordinates[index + 2] * transform.scale +
              transform.translateX,
          geometry.segmentCoordinates[index + 3] * transform.scale +
              transform.translateY,
        ),
        ui.Paint()
          ..color = color
          ..style = ui.PaintingStyle.stroke
          ..strokeCap = ui.StrokeCap.round
          ..strokeWidth = geometry.segmentWidths[segment],
      );
    }
    final picture = recorder.endRecording();
    final image = await picture.toImage(width, height);
    picture.dispose();
    try {
      final data = await image.toByteData(format: ui.ImageByteFormat.png);
      if (data == null) {
        throw StateError('The Flutter image encoder returned no PNG data.');
      }
      return data.buffer.asUint8List(
        data.offsetInBytes,
        data.lengthInBytes,
      );
    } finally {
      image.dispose();
    }
  }
}
