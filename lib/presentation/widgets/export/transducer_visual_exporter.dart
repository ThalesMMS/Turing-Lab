import 'dart:convert';
import 'dart:math' as math;
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';

import '../../../core/annotations/annotations.dart';
import '../../../core/transducers/transducers.dart';
import '../visual_export_binding.dart';

abstract final class TransducerVisualExporter {
  static const int width = 800;
  static const int height = 600;
  static const double _stateRadius = 30;

  static VisualExportArtifact svg(
    DeterministicFiniteStateTransducer machine, {
    DocumentAnnotationCollection? annotations,
  }) {
    final layout = _TransducerExportLayout(machine);
    final buffer = StringBuffer()
      ..writeln('<?xml version="1.0" encoding="UTF-8"?>')
      ..writeln(
        '<svg width="${width}px" height="${height}px" viewBox="0 0 $width $height" xmlns="http://www.w3.org/2000/svg">',
      )
      ..writeln('<rect width="$width" height="$height" fill="#ffffff"/>')
      ..writeln(
          '<defs><marker id="arrow" markerWidth="10" markerHeight="10" refX="9" refY="3" orient="auto"><path d="M0,0 L0,6 L9,3 z" fill="#374151"/></marker></defs>')
      ..writeln('<g class="transitions">');
    for (final edge in layout.edges) {
      final route = edge.route;
      if (edge.isLoop) {
        buffer.writeln(
          '<path d="M ${_n(route.start.dx)} ${_n(route.start.dy)} C ${_n(route.control1!.dx)} ${_n(route.control1!.dy)}, ${_n(route.control2!.dx)} ${_n(route.control2!.dy)}, ${_n(route.end.dx)} ${_n(route.end.dy)}" fill="none" stroke="#374151" stroke-width="2" marker-end="url(#arrow)"/>',
        );
      } else if (route.control1 case final control?) {
        buffer.writeln(
          '<path d="M ${_n(route.start.dx)} ${_n(route.start.dy)} Q ${_n(control.dx)} ${_n(control.dy)}, ${_n(route.end.dx)} ${_n(route.end.dy)}" fill="none" stroke="#374151" stroke-width="2" marker-end="url(#arrow)"/>',
        );
      } else {
        buffer.writeln(
          '<line x1="${_n(route.start.dx)}" y1="${_n(route.start.dy)}" x2="${_n(route.end.dx)}" y2="${_n(route.end.dy)}" stroke="#374151" stroke-width="2" marker-end="url(#arrow)"/>',
        );
      }
      buffer.writeln(
        '<text x="${_n(route.labelPosition.dx)}" y="${_n(route.labelPosition.dy)}" text-anchor="middle" font-family="Arial, sans-serif" font-size="14" fill="#111827">${_escape(edge.label)}</text>',
      );
    }
    buffer.writeln('</g><g class="states">');
    for (final node in layout.nodes) {
      if (node.state.isInitial) {
        buffer.writeln(
          '<line x1="${_n(node.position.dx - 58)}" y1="${_n(node.position.dy)}" x2="${_n(node.position.dx - _stateRadius)}" y2="${_n(node.position.dy)}" stroke="#2563eb" stroke-width="2" marker-end="url(#arrow)"/>',
        );
      }
      buffer
        ..writeln(
          '<circle cx="${_n(node.position.dx)}" cy="${_n(node.position.dy)}" r="$_stateRadius" fill="#ffffff" stroke="#1f2937" stroke-width="2"/>',
        )
        ..writeln(
          '<text x="${_n(node.position.dx)}" y="${_n(node.position.dy + (node.secondaryLabel == null ? 5 : -2))}" text-anchor="middle" font-family="Arial, sans-serif" font-size="14" fill="#111827">${_escape(node.state.label)}</text>',
        );
      if (node.secondaryLabel case final output?) {
        buffer.writeln(
          '<text x="${_n(node.position.dx)}" y="${_n(node.position.dy + 16)}" text-anchor="middle" font-family="Arial, sans-serif" font-size="11" fill="#4b5563">${_escape(output)}</text>',
        );
      }
    }
    buffer.writeln('</g>');
    if (annotations != null && annotations.annotations.isNotEmpty) {
      buffer.writeln('<g class="annotations">');
      for (final note in annotations.annotations) {
        final position = layout.annotationPosition(note);
        final noteWidth = math.min(note.width, width - position.dx - 8);
        final noteHeight = math.min(
          note.collapsed ? DocumentAnnotation.minimumHeight : note.height,
          height - position.dy - 8,
        );
        buffer
          ..writeln(
            '<rect x="${_n(position.dx)}" y="${_n(position.dy)}" width="${_n(noteWidth)}" height="${_n(noteHeight)}" rx="8" fill="${_noteColor(note.styleRole)}" stroke="#4b5563"/>',
          )
          ..writeln(
            '<text x="${_n(position.dx + 10)}" y="${_n(position.dy + 22)}" font-family="Arial, sans-serif" font-size="12" fill="#111827">${_escape(note.collapsed ? '' : note.text)}</text>',
          );
      }
      buffer.writeln('</g>');
    }
    buffer.writeln('</svg>');
    return VisualExportArtifact(
      bytes: Uint8List.fromList(utf8.encode(buffer.toString())),
      mimeType: 'image/svg+xml',
      filename: '${_safeName(machine.name)}.svg',
      width: width,
      height: height,
    );
  }

  static Future<VisualExportArtifact> png(
    DeterministicFiniteStateTransducer machine, {
    DocumentAnnotationCollection? annotations,
  }) async {
    final layout = _TransducerExportLayout(machine);
    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder);
    canvas.drawColor(const Color(0xffffffff), BlendMode.src);
    final linePaint = Paint()
      ..color = const Color(0xff374151)
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke;
    for (final edge in layout.edges) {
      final route = edge.route;
      if (edge.isLoop) {
        final path = Path()
          ..moveTo(route.start.dx, route.start.dy)
          ..cubicTo(
            route.control1!.dx,
            route.control1!.dy,
            route.control2!.dx,
            route.control2!.dy,
            route.end.dx,
            route.end.dy,
          );
        canvas.drawPath(path, linePaint);
        _paintArrow(
          canvas,
          route.control2!,
          route.end,
          linePaint.color,
        );
      } else if (route.control1 case final control?) {
        final path = Path()
          ..moveTo(route.start.dx, route.start.dy)
          ..quadraticBezierTo(
            control.dx,
            control.dy,
            route.end.dx,
            route.end.dy,
          );
        canvas.drawPath(path, linePaint);
        _paintArrow(canvas, control, route.end, linePaint.color);
      } else {
        canvas.drawLine(route.start, route.end, linePaint);
        _paintArrow(canvas, route.start, route.end, linePaint.color);
      }
      _paintText(canvas, edge.label, route.labelPosition, 14);
    }
    for (final node in layout.nodes) {
      if (node.state.isInitial) {
        final start = Offset(node.position.dx - 58, node.position.dy);
        final end = Offset(node.position.dx - _stateRadius, node.position.dy);
        canvas.drawLine(start, end, linePaint);
        _paintArrow(canvas, start, end, const Color(0xff2563eb));
      }
      canvas
        ..drawCircle(
          node.position,
          _stateRadius,
          Paint()..color = const Color(0xffffffff),
        )
        ..drawCircle(node.position, _stateRadius, linePaint);
      _paintText(
        canvas,
        node.state.label,
        Offset(
          node.position.dx,
          node.position.dy + (node.secondaryLabel == null ? 0 : -7),
        ),
        14,
      );
      if (node.secondaryLabel case final output?) {
        _paintText(
          canvas,
          output,
          Offset(node.position.dx, node.position.dy + 11),
          11,
          color: const Color(0xff4b5563),
        );
      }
    }
    if (annotations != null) {
      for (final note in annotations.annotations) {
        final position = layout.annotationPosition(note);
        final noteWidth = math.min(note.width, width - position.dx - 8);
        final noteHeight = math.min(
          note.collapsed ? DocumentAnnotation.minimumHeight : note.height,
          height - position.dy - 8,
        );
        final rect = RRect.fromRectAndRadius(
          Rect.fromLTWH(position.dx, position.dy, noteWidth, noteHeight),
          const Radius.circular(8),
        );
        canvas
          ..drawRRect(rect, Paint()..color = _notePaint(note.styleRole))
          ..drawRRect(rect, linePaint);
        if (!note.collapsed) {
          _paintText(
            canvas,
            note.text,
            Offset(position.dx + 10, position.dy + 10),
            12,
            centered: false,
            maxWidth: math.max(1, noteWidth - 20),
          );
        }
      }
    }
    final picture = recorder.endRecording();
    final image = await picture.toImage(width, height);
    picture.dispose();
    try {
      final data = await image.toByteData(format: ui.ImageByteFormat.png);
      if (data == null) throw StateError('PNG encoding returned no data.');
      return VisualExportArtifact(
        bytes: data.buffer.asUint8List(data.offsetInBytes, data.lengthInBytes),
        mimeType: 'image/png',
        filename: '${_safeName(machine.name)}.png',
        width: width,
        height: height,
      );
    } finally {
      image.dispose();
    }
  }

  static void _paintText(
    Canvas canvas,
    String text,
    Offset position,
    double fontSize, {
    Color color = const Color(0xff111827),
    bool centered = true,
    double maxWidth = 300,
  }) {
    final painter = TextPainter(
      text: TextSpan(
        text: text,
        style: TextStyle(fontSize: fontSize, color: color),
      ),
      textDirection: TextDirection.ltr,
      maxLines: 4,
      ellipsis: '…',
    )..layout(maxWidth: maxWidth);
    painter.paint(
      canvas,
      centered
          ? Offset(
              position.dx - painter.width / 2, position.dy - painter.height / 2)
          : position,
    );
  }

  static void _paintArrow(
      Canvas canvas, Offset start, Offset end, Color color) {
    final angle = math.atan2(end.dy - start.dy, end.dx - start.dx);
    const length = 10.0;
    final path = Path()
      ..moveTo(end.dx, end.dy)
      ..lineTo(
        end.dx - length * math.cos(angle - math.pi / 6),
        end.dy - length * math.sin(angle - math.pi / 6),
      )
      ..lineTo(
        end.dx - length * math.cos(angle + math.pi / 6),
        end.dy - length * math.sin(angle + math.pi / 6),
      )
      ..close();
    canvas.drawPath(path, Paint()..color = color);
  }

  static ({Offset start, Offset end}) _shortenedSegment(
    Offset from,
    Offset to,
  ) {
    final delta = to - from;
    final distance = delta.distance;
    if (distance <= _stateRadius * 2) return (start: from, end: to);
    final unit = delta / distance;
    return (
      start: from + unit * _stateRadius,
      end: to - unit * (_stateRadius + 4),
    );
  }

  static String _escape(String value) =>
      const HtmlEscape(HtmlEscapeMode.element).convert(value);
  static String _n(num value) => value.toStringAsFixed(2).replaceFirst(
        RegExp(r'\.00$'),
        '',
      );
  static String _safeName(String value) {
    final sanitized = value.trim().replaceAll(RegExp(r'[^\w.-]+'), '-');
    return sanitized.isEmpty ? 'transducer' : sanitized;
  }

  static String _noteColor(AnnotationStyleRole role) => switch (role) {
        AnnotationStyleRole.note => '#fff3b0',
        AnnotationStyleRole.information => '#dbeafe',
        AnnotationStyleRole.warning => '#fee2e2',
        AnnotationStyleRole.question => '#ede9fe',
        AnnotationStyleRole.todo => '#e5e7eb',
      };

  static Color _notePaint(AnnotationStyleRole role) => switch (role) {
        AnnotationStyleRole.note => const Color(0xfffff3b0),
        AnnotationStyleRole.information => const Color(0xffdbeafe),
        AnnotationStyleRole.warning => const Color(0xfffee2e2),
        AnnotationStyleRole.question => const Color(0xffede9fe),
        AnnotationStyleRole.todo => const Color(0xffe5e7eb),
      };
}

final class _TransducerExportLayout {
  _TransducerExportLayout(this.machine) {
    final states = machine.states.toList()
      ..sort((left, right) => left.id.compareTo(right.id));
    final positions = _fitPositions(states);
    nodes = [
      for (final state in states)
        _ExportNode(
          state: state,
          position: positions[state.id]!,
          secondaryLabel: state is MooreState
              ? (state.output.values.isEmpty
                  ? '[]'
                  : state.output.values.join(' · '))
              : null,
        ),
    ];
    final byId = {for (final node in nodes) node.state.id: node.position};
    final transitions = machine.transitions.toList()
      ..sort((left, right) => left.id.compareTo(right.id));
    final transitionGroups = <(String, String), List<TransducerTransition>>{};
    for (final transition in transitions) {
      final from = transition.from.value;
      final to = transition.to.value;
      final key = from.compareTo(to) <= 0 ? (from, to) : (to, from);
      transitionGroups.putIfAbsent(key, () => []).add(transition);
    }
    final routeOffsets = <TransducerTransitionId, double>{};
    final loopIndices = <TransducerTransitionId, int>{};
    for (final entry in transitionGroups.entries) {
      final grouped = entry.value
        ..sort((left, right) => left.id.compareTo(right.id));
      if (entry.key.$1 == entry.key.$2) {
        for (var index = 0; index < grouped.length; index++) {
          loopIndices[grouped[index].id] = index;
        }
      } else {
        final center = (grouped.length - 1) / 2;
        for (var index = 0; index < grouped.length; index++) {
          routeOffsets[grouped[index].id] = (index - center) * 36;
        }
      }
    }
    edges = [
      for (final transition in transitions)
        _ExportEdge(
          id: transition.id.value,
          fromId: transition.from.value,
          toId: transition.to.value,
          from: byId[transition.from]!,
          to: byId[transition.to]!,
          routeOffset: routeOffsets[transition.id] ?? 0,
          loopIndex: loopIndices[transition.id] ?? 0,
          label: switch (transition) {
            MealyTransition(:final input, :final output) =>
              '${input.value} / ${output.values.isEmpty ? '[]' : output.values.join(' · ')}',
            MooreTransition(:final input) => input.value,
          },
        ),
    ];
    _positionsByState = byId;
    _positionsByTransition = {
      for (final edge in edges) edge.id: edge.route.labelPosition,
    };
  }

  final DeterministicFiniteStateTransducer machine;
  late final List<_ExportNode> nodes;
  late final List<_ExportEdge> edges;
  late final Map<TransducerStateId, Offset> _positionsByState;
  late final Map<String, Offset> _positionsByTransition;

  Offset annotationPosition(DocumentAnnotation annotation) {
    final attachment = annotation.attachment;
    final anchor = switch (attachment?.type) {
      AnnotationTargetType.state =>
        _positionsByState[TransducerStateId(attachment!.targetId)],
      AnnotationTargetType.transition =>
        _positionsByTransition[attachment!.targetId],
      _ => null,
    };
    final raw = anchor == null
        ? _fitPoint(annotation.x, annotation.y)
        : anchor + Offset(attachment!.offsetX, attachment.offsetY);
    return Offset(
      raw.dx.clamp(8, TransducerVisualExporter.width - 128),
      raw.dy.clamp(8, TransducerVisualExporter.height - 64),
    );
  }

  Map<TransducerStateId, Offset> _fitPositions(List<TransducerState> states) {
    if (states.isEmpty) return const {};
    if (states.length == 1) {
      _sourceTransform = (
        states.single.position.x,
        states.single.position.y,
        1,
        400,
        300,
      );
      return {states.single.id: const Offset(400, 300)};
    }
    final minX = states.map((state) => state.position.x).reduce(math.min);
    final maxX = states.map((state) => state.position.x).reduce(math.max);
    final minY = states.map((state) => state.position.y).reduce(math.min);
    final maxY = states.map((state) => state.position.y).reduce(math.max);
    final sourceWidth = math.max(1.0, maxX - minX);
    final sourceHeight = math.max(1.0, maxY - minY);
    final scale = math.min(660 / sourceWidth, 460 / sourceHeight);
    final offsetX = (TransducerVisualExporter.width - sourceWidth * scale) / 2;
    final offsetY =
        (TransducerVisualExporter.height - sourceHeight * scale) / 2;
    _sourceTransform = (minX, minY, scale, offsetX, offsetY);
    return {
      for (final state in states)
        state.id: Offset(
          (state.position.x - minX) * scale + offsetX,
          (state.position.y - minY) * scale + offsetY,
        ),
    };
  }

  (double, double, double, double, double)? _sourceTransform;

  Offset _fitPoint(double x, double y) {
    final transform = _sourceTransform;
    if (transform == null) return Offset(x, y);
    return Offset(
      (x - transform.$1) * transform.$3 + transform.$4,
      (y - transform.$2) * transform.$3 + transform.$5,
    );
  }
}

final class _ExportNode {
  const _ExportNode({
    required this.state,
    required this.position,
    required this.secondaryLabel,
  });

  final TransducerState state;
  final Offset position;
  final String? secondaryLabel;
}

final class _ExportEdge {
  const _ExportEdge({
    required this.id,
    required this.fromId,
    required this.toId,
    required this.from,
    required this.to,
    required this.routeOffset,
    required this.loopIndex,
    required this.label,
  });

  final String id;
  final String fromId;
  final String toId;
  final Offset from;
  final Offset to;
  final double routeOffset;
  final int loopIndex;
  final String label;
  bool get isLoop => fromId == toId;

  _EdgeRoute get route {
    if (isLoop) {
      final direction = loopIndex.isEven ? -1.0 : 1.0;
      final level = loopIndex ~/ 2;
      final halfWidth = 18.0 + level * 10;
      final reach = 54.0 + level * 22;
      return _EdgeRoute(
        start: from + Offset(-halfWidth, direction * 24),
        end: from + Offset(halfWidth, direction * 24),
        control1: from + Offset(-halfWidth - 24, direction * reach),
        control2: from + Offset(halfWidth + 24, direction * reach),
        labelPosition: from + Offset(0, direction * (reach + 10)),
      );
    }
    if (routeOffset.abs() < 0.001) {
      final segment = TransducerVisualExporter._shortenedSegment(from, to);
      return _EdgeRoute(
        start: segment.start,
        end: segment.end,
        labelPosition: Offset(
          (segment.start.dx + segment.end.dx) / 2,
          (segment.start.dy + segment.end.dy) / 2 - 10,
        ),
      );
    }
    final canonicalDelta = fromId.compareTo(toId) <= 0 ? to - from : from - to;
    final distance = canonicalDelta.distance;
    if (distance == 0) {
      return _EdgeRoute(
        start: from,
        end: to,
        labelPosition: from + Offset(routeOffset, -10),
      );
    }
    final normal = Offset(
      -canonicalDelta.dy / distance,
      canonicalDelta.dx / distance,
    );
    final control = Offset(
          (from.dx + to.dx) / 2,
          (from.dy + to.dy) / 2,
        ) +
        normal * routeOffset;
    final fromDirection = control - from;
    final toDirection = control - to;
    final start = from +
        fromDirection /
            fromDirection.distance *
            TransducerVisualExporter._stateRadius;
    final end = to +
        toDirection /
            toDirection.distance *
            TransducerVisualExporter._stateRadius;
    final curveMidpoint = _quadraticPoint(start, control, end, 0.5);
    return _EdgeRoute(
      start: start,
      end: end,
      control1: control,
      labelPosition:
          curveMidpoint + normal * (routeOffset.isNegative ? -10 : 10),
    );
  }
}

final class _EdgeRoute {
  const _EdgeRoute({
    required this.start,
    required this.end,
    required this.labelPosition,
    this.control1,
    this.control2,
  });

  final Offset start;
  final Offset end;
  final Offset labelPosition;
  final Offset? control1;
  final Offset? control2;
}

Offset _quadraticPoint(Offset start, Offset control, Offset end, double t) {
  final inverse = 1 - t;
  return start * (inverse * inverse) +
      control * (2 * inverse * t) +
      end * (t * t);
}
