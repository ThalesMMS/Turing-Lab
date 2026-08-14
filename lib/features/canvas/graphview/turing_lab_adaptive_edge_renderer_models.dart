part of 'turing_lab_adaptive_edge_renderer.dart';

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
