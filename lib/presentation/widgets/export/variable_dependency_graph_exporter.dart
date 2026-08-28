import 'dart:math' as math;

import '../../../core/grammar/dependency_graph/dependency_graph.dart';

enum VariableDependencyLayout { layered, circular, grid }

class VariableDependencyPoint {
  const VariableDependencyPoint(this.x, this.y);

  final double x;
  final double y;
}

abstract final class VariableDependencyGraphExporter {
  static const double canvasWidth = 960;
  static const double canvasHeight = 640;
  static const double nodeRadius = 28;

  static Map<String, VariableDependencyPoint> layout(
    VariableDependencyGraphReport report,
    VariableDependencyLayout mode, {
    double width = canvasWidth,
    double height = canvasHeight,
  }) {
    if (report.variables.isEmpty) return const {};
    return switch (mode) {
      VariableDependencyLayout.layered => _layered(
        report,
        width: width,
        height: height,
      ),
      VariableDependencyLayout.circular => _circular(
        report.variables,
        width: width,
        height: height,
      ),
      VariableDependencyLayout.grid => _grid(
        report.variables,
        width: width,
        height: height,
      ),
    };
  }

  static String toSvg(
    VariableDependencyGraphReport report, {
    required String title,
    required String description,
    VariableDependencyLayout layoutMode = VariableDependencyLayout.layered,
    double width = canvasWidth,
    double height = canvasHeight,
  }) {
    final positions = layout(report, layoutMode, width: width, height: height);
    final buffer = StringBuffer()
      ..writeln('<?xml version="1.0" encoding="UTF-8"?>')
      ..writeln(
        '<svg xmlns="http://www.w3.org/2000/svg" '
        'width="${_number(width)}px" height="${_number(height)}px" '
        'viewBox="0 0 ${_number(width)} ${_number(height)}" '
        'role="img" aria-labelledby="vdg-title vdg-description">',
      )
      ..writeln('<title id="vdg-title">${_escape(title)}</title>')
      ..writeln(
        '<desc id="vdg-description">'
        '${_escape(description)}</desc>',
      )
      ..writeln('<defs>')
      ..writeln(
        '<marker id="arrow" markerWidth="8" markerHeight="8" refX="7" '
        'refY="4" orient="auto"><path d="M0,0 L8,4 L0,8 z" '
        'fill="#455a64"/></marker>',
      )
      ..writeln('</defs>')
      ..writeln('<g fill="none" stroke="#455a64" stroke-width="2">');
    for (final edge in report.edges) {
      final from = positions[edge.from]!;
      final to = positions[edge.to]!;
      if (edge.from == edge.to) {
        buffer.writeln(
          '<path data-edge-id="${_escape(edge.id)}" '
          'data-production-ids="${_escape(edge.contributions.map((item) => item.productionId).join(','))}" '
          'd="M ${_number(from.x - 12)} ${_number(from.y - nodeRadius + 2)} '
          'C ${_number(from.x - 48)} ${_number(from.y - 72)}, '
          '${_number(from.x + 48)} ${_number(from.y - 72)}, '
          '${_number(from.x + 12)} ${_number(from.y - nodeRadius + 2)}" '
          'marker-end="url(#arrow)"/>',
        );
      } else {
        final segment = _trimmedSegment(from, to);
        buffer.writeln(
          '<line data-edge-id="${_escape(edge.id)}" '
          'data-production-ids="${_escape(edge.contributions.map((item) => item.productionId).join(','))}" '
          'x1="${_number(segment.$1.x)}" y1="${_number(segment.$1.y)}" '
          'x2="${_number(segment.$2.x)}" y2="${_number(segment.$2.y)}" '
          'marker-end="url(#arrow)"/>',
        );
      }
    }
    buffer.writeln('</g>');
    for (final variable in report.variables) {
      final position = positions[variable]!;
      final unreachable = report.unreachableVariables.contains(variable);
      final nonproductive = report.nonproductiveVariables.contains(variable);
      final fill = unreachable
          ? '#ffecb3'
          : nonproductive
          ? '#ffcdd2'
          : '#e3f2fd';
      buffer
        ..writeln('<g data-variable="${_escape(variable)}">')
        ..writeln(
          '<circle cx="${_number(position.x)}" cy="${_number(position.y)}" '
          'r="${_number(nodeRadius)}" fill="$fill" stroke="#263238" '
          'stroke-width="2"/>',
        )
        ..writeln(
          '<text x="${_number(position.x)}" y="${_number(position.y + 5)}" '
          'text-anchor="middle" font-family="sans-serif" font-size="14" '
          'fill="#102027">${_escape(variable)}</text>',
        )
        ..writeln('</g>');
    }
    buffer.writeln('</svg>');
    return buffer.toString();
  }

  static Map<String, VariableDependencyPoint> _layered(
    VariableDependencyGraphReport report, {
    required double width,
    required double height,
  }) {
    final components = report.componentTopologicalOrder.isEmpty
        ? report.variables.map((variable) => [variable]).toList()
        : report.componentTopologicalOrder;
    final columns = components.length;
    final result = <String, VariableDependencyPoint>{};
    for (var column = 0; column < columns; column++) {
      final component = components[column];
      final x = columns == 1
          ? width / 2
          : 70 + column * ((width - 140) / (columns - 1));
      for (var row = 0; row < component.length; row++) {
        final y = component.length == 1
            ? height / 2
            : 70 + row * ((height - 140) / (component.length - 1));
        result[component[row]] = VariableDependencyPoint(x, y);
      }
    }
    return result;
  }

  static Map<String, VariableDependencyPoint> _circular(
    List<String> variables, {
    required double width,
    required double height,
  }) {
    final radius = math.max(40.0, math.min(width, height) / 2 - 70);
    return {
      for (var index = 0; index < variables.length; index++)
        variables[index]: VariableDependencyPoint(
          width / 2 +
              radius *
                  math.cos(
                    (2 * math.pi * index / variables.length) - math.pi / 2,
                  ),
          height / 2 +
              radius *
                  math.sin(
                    (2 * math.pi * index / variables.length) - math.pi / 2,
                  ),
        ),
    };
  }

  static Map<String, VariableDependencyPoint> _grid(
    List<String> variables, {
    required double width,
    required double height,
  }) {
    final columns = math.max(1, math.sqrt(variables.length).ceil());
    final rows = (variables.length / columns).ceil();
    return {
      for (var index = 0; index < variables.length; index++)
        variables[index]: VariableDependencyPoint(
          columns == 1
              ? width / 2
              : 70 + (index % columns) * ((width - 140) / (columns - 1)),
          rows == 1
              ? height / 2
              : 70 + (index ~/ columns) * ((height - 140) / (rows - 1)),
        ),
    };
  }

  static (VariableDependencyPoint, VariableDependencyPoint) _trimmedSegment(
    VariableDependencyPoint from,
    VariableDependencyPoint to,
  ) {
    final dx = to.x - from.x;
    final dy = to.y - from.y;
    final distance = math.sqrt(dx * dx + dy * dy);
    if (distance == 0) return (from, to);
    final xOffset = dx / distance * nodeRadius;
    final yOffset = dy / distance * nodeRadius;
    return (
      VariableDependencyPoint(from.x + xOffset, from.y + yOffset),
      VariableDependencyPoint(to.x - xOffset, to.y - yOffset),
    );
  }

  static String _escape(String value) => value
      .replaceAll('&', '&amp;')
      .replaceAll('<', '&lt;')
      .replaceAll('>', '&gt;')
      .replaceAll('"', '&quot;')
      .replaceAll("'", '&apos;');

  static String _number(double value) => value == value.roundToDouble()
      ? value.round().toString()
      : value.toStringAsFixed(2);
}
