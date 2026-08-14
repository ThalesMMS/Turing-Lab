//
//  graphview_link_overlay_utils.dart
//  Turing Lab
//
//  Conjunto de utilitários que calcula âncoras e posições para sobreposições de
//  arestas no GraphView, normalizando pontos de controle e loops para manter o
//  alinhamento visual do canvas. As funções auxiliam widgets a posicionar
//  indicadores e editores diretamente sobre as ligações renderizadas.
//
//  Thales Matheus Mendonça Santos - October 2025
//
import 'package:flutter/material.dart';

import '../../../core/constants/automaton_canvas_constants.dart';
import 'base_graphview_canvas_controller.dart';
import 'grouped_fsa_geometry.dart';
import 'graphview_canvas_models.dart';

const double _kNodeDiameter = kAutomatonStateDiameter;
const double _kNodeRadius = _kNodeDiameter / 2;

/// Computes the preferred world anchor for the provided [edge].
Offset? resolveLinkAnchorWorld(
  BaseGraphViewCanvasController<dynamic, dynamic> controller,
  GraphViewCanvasEdge edge,
) {
  final from = controller.nodeById(edge.fromStateId);
  final to = controller.nodeById(edge.toStateId);
  if (from == null || to == null) {
    return null;
  }

  if (_isGroupedFsaEdge(edge)) {
    if (edge.fromStateId == edge.toStateId) {
      final groupedLoops = controller.edges
          .where(
            (candidate) =>
                candidate.fromStateId == edge.fromStateId &&
                candidate.toStateId == edge.toStateId,
          )
          .length;
      final extraOffset = resolveGroupedFsaLoopExtraOffset(groupedLoops);
      final center = resolveNodeCenter(from);
      return center.translate(0, -(_kNodeDiameter + extraOffset));
    }

    final fromCenter = resolveNodeCenter(from);
    final toCenter = resolveNodeCenter(to);
    final hasOpposingEdge = controller.edges.any(
      (candidate) =>
          candidate.fromStateId == edge.toStateId &&
          candidate.toStateId == edge.fromStateId,
    );
    return resolveGroupedFsaControlPoint(
      fromId: edge.fromStateId,
      toId: edge.toStateId,
      fromCenter: fromCenter,
      toCenter: toCenter,
      hasOpposingTraffic: hasOpposingEdge,
    );
  }

  if (edge.controlPointX != null && edge.controlPointY != null) {
    final raw = Offset(edge.controlPointX!, edge.controlPointY!);
    return _normalizeControlPoint(raw, from, to);
  }

  if (edge.fromStateId == edge.toStateId) {
    return _resolveLoopAnchor(from);
  }

  final fromCenter = resolveNodeCenter(from);
  final toCenter = resolveNodeCenter(to);
  return Offset(
    (fromCenter.dx + toCenter.dx) / 2,
    (fromCenter.dy + toCenter.dy) / 2,
  );
}

/// Returns the node center in world coordinates.
Offset resolveNodeCenter(GraphViewCanvasNode node) {
  return Offset(node.x + _kNodeRadius, node.y + _kNodeRadius);
}

Offset _resolveLoopAnchor(GraphViewCanvasNode node) {
  final center = resolveNodeCenter(node);
  return center.translate(0, -_kNodeRadius * 2);
}

Offset _normalizeControlPoint(
  Offset raw,
  GraphViewCanvasNode from,
  GraphViewCanvasNode to,
) {
  final fromCenter = resolveNodeCenter(from);
  final toCenter = resolveNodeCenter(to);
  final averageCenter = Offset(
    (fromCenter.dx + toCenter.dx) / 2,
    (fromCenter.dy + toCenter.dy) / 2,
  );

  const legacyOffset = Offset(_kNodeRadius, _kNodeRadius);
  final legacyCandidate = raw + legacyOffset;

  final rawDistance = (raw - averageCenter).distance;
  final legacyDistance = (legacyCandidate - averageCenter).distance;

  return legacyDistance < rawDistance ? legacyCandidate : raw;
}

bool _isGroupedFsaEdge(GraphViewCanvasEdge edge) {
  final hasPdaMetadata = edge.popSymbol != null ||
      edge.pushSymbol != null ||
      edge.isLambdaInput != null ||
      edge.isLambdaPop != null ||
      edge.isLambdaPush != null;
  final hasTmMetadata = edge.readSymbol != null ||
      edge.writeSymbol != null ||
      edge.direction != null;
  return !hasPdaMetadata && !hasTmMetadata;
}
