part of 'turing_lab_adaptive_edge_renderer.dart';

class TuringLabEdgeRenderGeometry {
  const TuringLabEdgeRenderGeometry({
    required this.pathGeometry,
    required this.labelNormal,
    this.labelRect,
  });

  final EdgePathGeometry pathGeometry;
  final Offset labelNormal;
  final Rect? labelRect;

  Offset get editorAnchor => labelRect?.center ?? pathGeometry.pointAt(0.5);

  TuringLabEdgeRenderGeometry withLabelRect(Rect? value) =>
      TuringLabEdgeRenderGeometry(
        pathGeometry: pathGeometry,
        labelNormal: labelNormal,
        labelRect: value,
      );
}

class _VisibleRouteGroup {
  const _VisibleRouteGroup({
    required this.stableId,
    required this.sourceId,
    required this.destinationId,
    required this.representative,
    required this.members,
  });

  final String stableId;
  final String sourceId;
  final String destinationId;
  final Edge representative;
  final List<Edge> members;

  bool get isSelfLoop => sourceId == destinationId;
}

class _NodeGeometryStamp {
  const _NodeGeometryStamp({required this.position, required this.size});

  final Offset position;
  final Size size;

  Rect get bounds => Rect.fromLTWH(
        position.dx,
        position.dy,
        size.width,
        size.height,
      );

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is _NodeGeometryStamp &&
          other.position == position &&
          other.size == size;

  @override
  int get hashCode => Object.hash(position, size);
}

class _GroupedFsaRenderGeometry {
  const _GroupedFsaRenderGeometry({
    required this.geometry,
    required this.laneOffset,
  });

  final EdgePathGeometry geometry;
  final double laneOffset;
}

class _GroupedLabelEntry {
  const _GroupedLabelEntry({required this.painter});

  final TextPainter painter;
}

class _DirectedEdgePair {
  const _DirectedEdgePair({
    required this.sourceId,
    required this.destinationId,
  });

  final String sourceId;
  final String destinationId;

  _DirectedEdgePair get reversed =>
      _DirectedEdgePair(sourceId: destinationId, destinationId: sourceId);

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        other is _DirectedEdgePair &&
            other.sourceId == sourceId &&
            other.destinationId == destinationId;
  }

  @override
  int get hashCode => Object.hash(sourceId, destinationId);
}

class _LabelPainterCacheKey {
  _LabelPainterCacheKey({required this.text, required TextStyle style})
      : colorArgb = style.color?.toARGB32(),
        fontSize = style.fontSize,
        fontWeightValue = style.fontWeight?.value,
        fontStyle = style.fontStyle,
        fontFamily = style.fontFamily,
        fontFamilyFallback = style.fontFamilyFallback == null
            ? null
            : List<String>.unmodifiable(style.fontFamilyFallback!),
        letterSpacing = style.letterSpacing,
        height = style.height,
        wordSpacing = style.wordSpacing,
        decoration = style.decoration,
        decorationColorArgb = style.decorationColor?.toARGB32(),
        decorationStyle = style.decorationStyle;

  final String text;
  final int? colorArgb;
  final double? fontSize;
  final int? fontWeightValue;
  final FontStyle? fontStyle;
  final String? fontFamily;
  final List<String>? fontFamilyFallback;
  final double? letterSpacing;
  final double? height;
  final double? wordSpacing;
  final TextDecoration? decoration;
  final int? decorationColorArgb;
  final TextDecorationStyle? decorationStyle;

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        other is _LabelPainterCacheKey &&
            other.text == text &&
            other.colorArgb == colorArgb &&
            other.fontSize == fontSize &&
            other.fontWeightValue == fontWeightValue &&
            other.fontStyle == fontStyle &&
            other.fontFamily == fontFamily &&
            listEquals(other.fontFamilyFallback, fontFamilyFallback) &&
            other.letterSpacing == letterSpacing &&
            other.height == height &&
            other.wordSpacing == wordSpacing &&
            other.decoration == decoration &&
            other.decorationColorArgb == decorationColorArgb &&
            other.decorationStyle == decorationStyle;
  }

  @override
  int get hashCode => Object.hash(
        text,
        colorArgb,
        fontSize,
        fontWeightValue,
        fontStyle,
        fontFamily,
        Object.hashAll(fontFamilyFallback ?? const <String>[]),
        letterSpacing,
        height,
        wordSpacing,
        decoration,
        decorationColorArgb,
        decorationStyle,
      );
}
