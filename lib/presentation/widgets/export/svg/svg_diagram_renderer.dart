//
//  svg_diagram_renderer.dart
//  Turing Lab
//
//  Contract between SvgExporter, which owns the sheet (dimensions, header,
//  <defs>/<style> and the outer <svg>), and the domain renderers that draw
//  the diagram body.
//

import 'svg_export_options.dart';
import 'svg_primitives.dart';

/// What the sheet's `<defs>`/`<style>` block must contain for a diagram.
class SvgStyleRequest {
  const SvgStyleRequest({
    this.includeAcceptingMask = true,
    this.arrowColors = const <String>{SvgPrimitives.defaultStrokeHex},
  });

  final bool includeAcceptingMask;

  /// Stroke colours whose arrowhead markers the sheet defines.
  final Set<String> arrowColors;
}

abstract interface class SvgDiagramRenderer<T> {
  SvgStyleRequest styles(T document, SvgExportOptions options);

  /// Writes the diagram body between the sheet's header and closing tag.
  void render(
    StringBuffer buffer,
    T document, {
    required double width,
    required double height,
    required SvgExportOptions options,
  });
}
