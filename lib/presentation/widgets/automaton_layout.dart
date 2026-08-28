import 'dart:async';

import 'package:collection/collection.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/annotations/annotations.dart';
import '../../core/graph_layout/graph_layout.dart';
import '../../core/formal_systems/formal_system_ids.dart';
import '../../features/canvas/graphview/base_graphview_canvas_controller.dart';
import '../../l10n/app_localizations_resolver.dart';
import '../../l10n/automaton_layout_localizations.dart';
import '../providers/document_annotations_provider.dart';
import 'automaton_canvas_document_actions.dart';

final class AutomatonLayoutCommit {
  const AutomatonLayoutCommit({
    required this.result,
    required this.previousPositions,
  });

  final GraphLayoutResult result;
  final Map<String, GraphLayoutPoint> previousPositions;
}

final class AutomatonLayoutButton extends ConsumerStatefulWidget {
  const AutomatonLayoutButton({
    super.key,
    required this.destination,
    required this.controller,
    required this.selectedNodeIds,
    required this.restorePositions,
    required this.onCommitted,
    this.annotationSystemKey,
    this.annotationDocumentId,
    this.documentRevision,
    this.actionsController,
    this.showButton = true,
  });

  final Object destination;
  final BaseGraphViewCanvasController<dynamic, dynamic> controller;
  final Set<String> selectedNodeIds;
  final Map<String, GraphLayoutPoint> restorePositions;
  final ValueChanged<AutomatonLayoutCommit> onCommitted;
  final FormalSystemKey? annotationSystemKey;
  final String? annotationDocumentId;
  final String? documentRevision;
  final AutomatonCanvasDocumentActionsController? actionsController;
  final bool showButton;

  @override
  ConsumerState<AutomatonLayoutButton> createState() =>
      _AutomatonLayoutButtonState();
}

class _AutomatonLayoutButtonState extends ConsumerState<AutomatonLayoutButton> {
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    widget.actionsController?.bindArrange(this, _open);
  }

  @override
  void didUpdateWidget(covariant AutomatonLayoutButton oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.actionsController != widget.actionsController) {
      oldWidget.actionsController?.unbind(this);
      widget.actionsController?.bindArrange(this, _open);
    }
  }

  @override
  void dispose() {
    widget.actionsController?.unbind(this);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!widget.showButton) return const SizedBox.shrink();
    final l10n = appLocalizationsOf(context);
    return Semantics(
      button: true,
      label: l10n.automatonLayoutButtonSemantics,
      hint: l10n.automatonLayoutButtonHint,
      child: IconButton.filledTonal(
        key: const ValueKey('automaton-layout-button'),
        constraints: const BoxConstraints.tightFor(width: 48, height: 48),
        tooltip: l10n.automatonLayoutButtonTooltip,
        onPressed: _busy ? null : _open,
        icon: _busy
            ? const SizedBox.square(
                dimension: 22,
                child: CircularProgressIndicator(strokeWidth: 2.5),
              )
            : const Icon(Icons.auto_fix_high_outlined),
      ),
    );
  }

  Future<void> _open() async {
    setState(() => _busy = true);
    final openedRevision =
        widget.documentRevision ??
        GraphLayoutDocumentAdapter.documentRevision(widget.destination);
    final originalPositions = _positions;
    try {
      final graph = GraphLayoutGraph(
        revision: openedRevision ?? '',
        nodes: widget.controller.nodes.map(
          (node) => GraphLayoutNode(
            id: node.id,
            label: node.label,
            position: GraphLayoutPoint(node.x, node.y),
            isInitial: node.isInitial,
          ),
        ),
        edges: widget.controller.edges.map(
          (edge) => GraphLayoutEdge(
            id: edge.id,
            fromNodeId: edge.fromStateId,
            toNodeId: edge.toStateId,
          ),
        ),
      );
      final annotationCollection = _annotationCollection;
      if (!mounted) return;
      final decision = await showDialog<_LayoutDecision>(
        context: context,
        barrierDismissible: false,
        builder: (context) => _AutomatonLayoutDialog(
          graph: graph,
          selectedNodeIds: widget.selectedNodeIds,
          restorePositions: widget.restorePositions,
          targetBounds: _targetBounds,
          hasFreeAnnotations:
              annotationCollection?.annotations.any(
                (annotation) => annotation.attachment == null,
              ) ??
              false,
          onPreview: _preview,
        ),
      );
      if (!mounted) return;
      if (decision == null) {
        widget.controller.synchronize(widget.destination);
        return;
      }
      final currentRevision =
          widget.documentRevision ??
          GraphLayoutDocumentAdapter.documentRevision(widget.destination);
      if (openedRevision != currentRevision) {
        throw _LayoutCommitConflict.document;
      }
      if (annotationCollection != _annotationCollection) {
        throw _LayoutCommitConflict.annotations;
      }
      _commit(decision, originalPositions, annotationCollection);
    } catch (error) {
      widget.controller.synchronize(widget.destination);
      if (mounted) {
        await showDialog<void>(
          context: context,
          builder: (context) {
            final l10n = appLocalizationsOf(context);
            final message = switch (error) {
              _LayoutCommitConflict.document =>
                l10n.automatonLayoutDocumentChanged,
              _LayoutCommitConflict.annotations =>
                l10n.automatonLayoutAnnotationsChanged,
              _ => l10n.automatonLayoutApplyFailed,
            };
            return AlertDialog(
              title: Text(l10n.automatonLayoutCannotArrange),
              content: Text(message),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: Text(MaterialLocalizations.of(context).okButtonLabel),
                ),
              ],
            );
          },
        );
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Map<String, GraphLayoutPoint> get _positions => {
    for (final node in widget.controller.nodes)
      node.id: GraphLayoutPoint(node.x, node.y),
  };

  GraphLayoutBounds get _targetBounds {
    final safeRect = widget.controller.safeViewportWorldRect;
    if (safeRect == null || safeRect.width < 160 || safeRect.height < 160) {
      final center = widget.controller.viewportCenterWorld;
      return GraphLayoutBounds(
        left: center.dx - 360,
        top: center.dy - 260,
        width: 720,
        height: 520,
      );
    }
    final target = safeRect.deflate(72);
    return GraphLayoutBounds(
      left: target.left,
      top: target.top,
      width: target.width,
      height: target.height,
    );
  }

  DocumentAnnotationCollection? get _annotationCollection {
    final key = widget.annotationSystemKey;
    final documentId = widget.annotationDocumentId;
    if (key == null || documentId == null) return null;
    return annotationsForDocument(
      ref.read(documentAnnotationsProvider),
      key,
      documentId,
    );
  }

  void _preview(GraphLayoutResult result) {
    if (!mounted) return;
    for (final entry in result.positions.entries) {
      widget.controller.previewStatePosition(
        entry.key,
        Offset(entry.value.x, entry.value.y),
      );
    }
  }

  void _commit(
    _LayoutDecision decision,
    Map<String, GraphLayoutPoint> originalPositions,
    DocumentAnnotationCollection? annotationCollection,
  ) {
    final document = GraphLayoutDocumentAdapter.applyPositions(
      widget.destination,
      decision.result.positions,
    );
    final key = widget.annotationSystemKey;
    final annotationsNotifier = ref.read(documentAnnotationsProvider.notifier);
    var annotationCommitted = false;
    if (key != null && annotationCollection != null) {
      final updated = GraphLayoutDocumentAdapter.applyFreeAnnotationTransform(
        annotationCollection,
        decision.result,
        transformFreeAnnotations: decision.transformFreeAnnotations,
      );
      annotationCommitted = annotationsNotifier.replaceAsMutation(key, updated);
    }
    try {
      widget.controller.replaceDocumentAsMutation(
        document,
        companion: annotationCommitted
            ? CallbackGraphViewHistoryCompanion(
                onUndo: () => annotationsNotifier.undo(key!),
                onRedo: () => annotationsNotifier.redo(key!),
              )
            : null,
      );
    } catch (_) {
      if (annotationCommitted) annotationsNotifier.undo(key!);
      rethrow;
    }
    widget.onCommitted(
      AutomatonLayoutCommit(
        result: decision.result,
        previousPositions: originalPositions,
      ),
    );
    ScaffoldMessenger.maybeOf(context)?.showSnackBar(
      SnackBar(
        content: Text(
          appLocalizationsOf(context).automatonLayoutArrangedCount(
            decision.result.affectedNodeIds.length,
          ),
        ),
      ),
    );
  }
}

enum _LayoutCommitConflict { document, annotations }

final class _LayoutDecision {
  const _LayoutDecision({
    required this.result,
    required this.transformFreeAnnotations,
  });

  final GraphLayoutResult result;
  final bool transformFreeAnnotations;
}

class _AutomatonLayoutDialog extends StatefulWidget {
  const _AutomatonLayoutDialog({
    required this.graph,
    required this.selectedNodeIds,
    required this.restorePositions,
    required this.targetBounds,
    required this.hasFreeAnnotations,
    required this.onPreview,
  });

  final GraphLayoutGraph graph;
  final Set<String> selectedNodeIds;
  final Map<String, GraphLayoutPoint> restorePositions;
  final GraphLayoutBounds targetBounds;
  final bool hasFreeAnnotations;
  final ValueChanged<GraphLayoutResult> onPreview;

  @override
  State<_AutomatonLayoutDialog> createState() => _AutomatonLayoutDialogState();
}

class _AutomatonLayoutDialogState extends State<_AutomatonLayoutDialog> {
  GraphLayoutAlgorithmId _algorithm = GraphLayoutAlgorithmId.sugiyama;
  GraphLayoutScope _scope = GraphLayoutScope.all;
  late String? _rootNodeId = widget.graph.nodes
      .where((node) => node.isInitial)
      .map((node) => node.id)
      .firstOrNull;
  bool _pinSelected = false;
  bool _transformFreeAnnotations = false;
  double _nodeSpacing = 120;
  double _layerSpacing = 160;
  int _seed = 0;
  int _generation = 0;
  GraphLayoutTask? _task;
  GraphLayoutResult? _result;
  GraphLayoutProgress? _progress;
  Object? _error;

  @override
  void initState() {
    super.initState();
    unawaited(_compute());
  }

  @override
  void dispose() {
    _generation++;
    _task?.cancel();
    super.dispose();
  }

  bool get _isSeeded =>
      _algorithm == GraphLayoutAlgorithmId.seededForce ||
      _algorithm == GraphLayoutAlgorithmId.seededRandom;

  bool get _isLayered =>
      _algorithm == GraphLayoutAlgorithmId.hierarchical ||
      _algorithm == GraphLayoutAlgorithmId.sugiyama;

  bool get _canTransformFreeAnnotations =>
      widget.hasFreeAnnotations &&
      _result?.transform != null &&
      _scope == GraphLayoutScope.all &&
      (!_pinSelected || widget.selectedNodeIds.isEmpty);

  Future<void> _compute() async {
    final generation = ++_generation;
    _task?.cancel();
    setState(() {
      _result = null;
      _progress = const GraphLayoutProgress(
        fraction: 0,
        stage: GraphLayoutProgressStage.preparingPreview,
      );
      _error = null;
      if (!_canTransformFreeAnnotations) _transformFreeAnnotations = false;
    });
    try {
      final task = await GraphLayoutTask.start(
        GraphLayoutRequest(
          algorithmId: _algorithm,
          graph: widget.graph,
          settings: GraphLayoutSettings(
            scope: _scope,
            selectedNodeIds: widget.selectedNodeIds,
            pinnedNodeIds: _pinSelected
                ? widget.selectedNodeIds
                : const <String>{},
            rootNodeId: _rootNodeId,
            seed: _seed,
            nodeSpacing: _nodeSpacing,
            layerSpacing: _layerSpacing,
            targetBounds: widget.targetBounds,
            restorePositions: widget.restorePositions,
          ),
        ),
      );
      if (!mounted || generation != _generation) {
        unawaited(task.result.then<void>((_) {}, onError: (_, __) {}));
        task.cancel();
        return;
      }
      _task = task;
      final progressSubscription = task.progress.listen((progress) {
        if (mounted && generation == _generation) {
          setState(() => _progress = progress);
        }
      });
      try {
        final result = await task.result;
        if (!mounted || generation != _generation) return;
        setState(() {
          _result = result;
          _progress = null;
          if (!_canTransformFreeAnnotations) {
            _transformFreeAnnotations = false;
          }
        });
        widget.onPreview(result);
      } finally {
        await progressSubscription.cancel();
      }
    } on GraphLayoutCancelledException {
      // Replaced by a newer preview or closed by the user.
    } catch (error) {
      if (mounted && generation == _generation) {
        setState(() {
          _error = error;
          _progress = null;
        });
      }
    }
  }

  void _update(VoidCallback mutation) {
    setState(mutation);
    unawaited(_compute());
  }

  @override
  Widget build(BuildContext context) {
    final result = _result;
    final theme = Theme.of(context);
    final l10n = appLocalizationsOf(context);
    final status = _statusText(context);
    return AlertDialog(
      key: const ValueKey('automaton-layout-dialog'),
      title: Text(l10n.automatonLayoutButtonSemantics),
      content: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 660, maxHeight: 640),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                l10n.automatonLayoutChoosePreview,
                style: theme.textTheme.bodyMedium,
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<GraphLayoutAlgorithmId>(
                key: const ValueKey('layout-algorithm-field'),
                initialValue: _algorithm,
                isExpanded: true,
                decoration: InputDecoration(
                  labelText: l10n.automatonLayoutLabel,
                  border: const OutlineInputBorder(),
                ),
                items: [
                  for (final algorithm in GraphLayoutAlgorithmId.values)
                    DropdownMenuItem(
                      key: ValueKey('layout-algorithm-${algorithm.name}'),
                      value: algorithm,
                      enabled:
                          algorithm != GraphLayoutAlgorithmId.restore ||
                          widget.restorePositions.isNotEmpty,
                      child: Text(
                        l10n.automatonLayoutAlgorithmLabel(algorithm),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                ],
                onChanged: (value) {
                  if (value != null) _update(() => _algorithm = value);
                },
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<GraphLayoutScope>(
                key: const ValueKey('layout-scope-field'),
                initialValue: _scope,
                isExpanded: true,
                decoration: InputDecoration(
                  labelText: l10n.automatonLayoutApplyTo,
                  border: const OutlineInputBorder(),
                ),
                items: [
                  for (final scope in GraphLayoutScope.values)
                    DropdownMenuItem(
                      key: ValueKey('layout-scope-${scope.name}'),
                      value: scope,
                      child: Text(
                        l10n.automatonLayoutScopeLabel(scope),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                ],
                onChanged: (value) {
                  if (value != null) _update(() => _scope = value);
                },
              ),
              if (widget.selectedNodeIds.isNotEmpty) ...[
                const SizedBox(height: 4),
                CheckboxListTile(
                  key: const ValueKey('layout-pin-selected'),
                  contentPadding: EdgeInsets.zero,
                  title: Text(l10n.automatonLayoutKeepSelected),
                  subtitle: Text(
                    l10n.automatonLayoutSelectedCount(
                      widget.selectedNodeIds.length,
                    ),
                  ),
                  value: _pinSelected,
                  onChanged: (value) =>
                      _update(() => _pinSelected = value ?? false),
                ),
              ],
              if (_isLayered) ...[
                const SizedBox(height: 8),
                DropdownButtonFormField<String?>(
                  key: const ValueKey('layout-root-field'),
                  initialValue: _rootNodeId,
                  isExpanded: true,
                  decoration: InputDecoration(
                    labelText: l10n.automatonLayoutRootState,
                    border: const OutlineInputBorder(),
                  ),
                  items: [
                    DropdownMenuItem<String?>(
                      value: null,
                      child: Text(
                        l10n.automatonLayoutAutomatic,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    for (final node in widget.graph.nodes)
                      DropdownMenuItem<String?>(
                        value: node.id,
                        child: Text(
                          node.label.isEmpty ? node.id : node.label,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                  ],
                  onChanged: (value) => _update(() => _rootNodeId = value),
                ),
              ],
              if (_isSeeded) ...[
                const SizedBox(height: 12),
                TextFormField(
                  key: const ValueKey('layout-seed-field'),
                  initialValue: '$_seed',
                  decoration: InputDecoration(
                    labelText: l10n.automatonLayoutSeed,
                    helperText: l10n.automatonLayoutSeedHelp,
                    border: const OutlineInputBorder(),
                  ),
                  keyboardType: TextInputType.number,
                  onFieldSubmitted: (value) {
                    final seed = int.tryParse(value);
                    if (seed != null) _update(() => _seed = seed);
                  },
                ),
              ],
              if (!_algorithm.isTransform) ...[
                const SizedBox(height: 12),
                Text(l10n.automatonLayoutStateSpacing(_nodeSpacing.round())),
                Slider(
                  key: const ValueKey('layout-node-spacing'),
                  value: _nodeSpacing,
                  min: 72,
                  max: 240,
                  divisions: 14,
                  label: '${_nodeSpacing.round()}',
                  onChanged: (value) => setState(() => _nodeSpacing = value),
                  onChangeEnd: (_) => unawaited(_compute()),
                ),
              ],
              if (_isLayered) ...[
                Text(l10n.automatonLayoutLayerSpacing(_layerSpacing.round())),
                Slider(
                  key: const ValueKey('layout-layer-spacing'),
                  value: _layerSpacing,
                  min: 96,
                  max: 280,
                  divisions: 16,
                  label: '${_layerSpacing.round()}',
                  onChanged: (value) => setState(() => _layerSpacing = value),
                  onChangeEnd: (_) => unawaited(_compute()),
                ),
              ],
              const SizedBox(height: 12),
              Container(
                height: 190,
                decoration: BoxDecoration(
                  color: theme.colorScheme.surfaceContainerLowest,
                  border: Border.all(color: theme.colorScheme.outlineVariant),
                  borderRadius: BorderRadius.circular(12),
                ),
                clipBehavior: Clip.antiAlias,
                child: result == null
                    ? Center(
                        child: _progress == null
                            ? const SizedBox.shrink()
                            : Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  CircularProgressIndicator(
                                    value: _progress!.fraction == 0
                                        ? null
                                        : _progress!.fraction,
                                  ),
                                  const SizedBox(height: 12),
                                  Text(
                                    l10n.automatonLayoutProgressStageLabel(
                                      _progress!,
                                    ),
                                  ),
                                ],
                              ),
                      )
                    : Semantics(
                        container: true,
                        image: true,
                        label: status,
                        excludeSemantics: true,
                        child: CustomPaint(
                          painter: _LayoutPreviewPainter(
                            graph: widget.graph,
                            result: result,
                            colorScheme: theme.colorScheme,
                          ),
                          child: const SizedBox.expand(),
                        ),
                      ),
              ),
              const SizedBox(height: 12),
              Semantics(
                container: true,
                liveRegion: true,
                label: status,
                child: Text(status),
              ),
              if (result != null && result.diagnostics.isNotEmpty) ...[
                const SizedBox(height: 8),
                for (final diagnostic in result.diagnostics)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 4),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(
                          diagnostic.isBlocking
                              ? Icons.error_outline
                              : Icons.info_outline,
                          size: 18,
                          color: diagnostic.isBlocking
                              ? theme.colorScheme.error
                              : theme.colorScheme.onSurfaceVariant,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            l10n.automatonLayoutDiagnosticMessage(diagnostic),
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
              if (_canTransformFreeAnnotations) ...[
                const SizedBox(height: 4),
                CheckboxListTile(
                  key: const ValueKey('layout-transform-free-notes'),
                  contentPadding: EdgeInsets.zero,
                  title: Text(l10n.automatonLayoutTransformFreeNotes),
                  subtitle: Text(l10n.automatonLayoutAttachedNotesHelp),
                  value: _transformFreeAnnotations,
                  onChanged: (value) => setState(
                    () => _transformFreeAnnotations = value ?? false,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          key: const ValueKey('layout-cancel-button'),
          onPressed: () => Navigator.of(context).pop(),
          child: Text(l10n.cancel),
        ),
        FilledButton(
          key: const ValueKey('layout-apply-button'),
          onPressed: result?.canApply == true
              ? () => Navigator.of(context).pop(
                  _LayoutDecision(
                    result: result!,
                    transformFreeAnnotations: _transformFreeAnnotations,
                  ),
                )
              : null,
          child: Text(l10n.automatonLayoutApply),
        ),
      ],
    );
  }

  String _statusText(BuildContext context) {
    final l10n = appLocalizationsOf(context);
    if (_error != null) {
      return l10n.automatonLayoutPreviewFailed;
    }
    final progress = _progress;
    if (progress != null) {
      return l10n.automatonLayoutProgressStatus(
        l10n.automatonLayoutProgressStageLabel(progress),
        (progress.fraction * 100).round(),
      );
    }
    final result = _result;
    if (result == null) {
      return l10n.automatonLayoutPreparingPreview;
    }
    return l10n.automatonLayoutResultSummary(
      result.metrics.nodeCount,
      result.metrics.componentCount,
      result.metrics.overlapCount,
      result.metrics.edgeCrossingCount < 0 ? 'notMeasured' : 'measured',
      result.metrics.edgeCrossingCount,
    );
  }
}

extension on GraphLayoutAlgorithmId {
  bool get isTransform => switch (this) {
    GraphLayoutAlgorithmId.reflectHorizontal ||
    GraphLayoutAlgorithmId.reflectVertical ||
    GraphLayoutAlgorithmId.rotate90 ||
    GraphLayoutAlgorithmId.rotate180 ||
    GraphLayoutAlgorithmId.rotate270 ||
    GraphLayoutAlgorithmId.fit ||
    GraphLayoutAlgorithmId.fill => true,
    _ => false,
  };
}

final class _LayoutPreviewPainter extends CustomPainter {
  const _LayoutPreviewPainter({
    required this.graph,
    required this.result,
    required this.colorScheme,
  });

  final GraphLayoutGraph graph;
  final GraphLayoutResult result;
  final ColorScheme colorScheme;

  @override
  void paint(Canvas canvas, Size size) {
    if (result.positions.isEmpty) return;
    final source = GraphLayoutBounds.fromPoints(result.positions.values);
    final width = source.width == 0 ? 1.0 : source.width;
    final height = source.height == 0 ? 1.0 : source.height;
    const inset = 18.0;
    final scale = ((size.width - inset * 2) / width)
        .clamp(0.01, (size.height - inset * 2) / height)
        .toDouble();
    final drawnWidth = width * scale;
    final drawnHeight = height * scale;
    final origin = Offset(
      (size.width - drawnWidth) / 2 - source.left * scale,
      (size.height - drawnHeight) / 2 - source.top * scale,
    );
    Offset project(GraphLayoutPoint point) =>
        Offset(point.x * scale, point.y * scale) + origin;

    final edgePaint = Paint()
      ..color = colorScheme.outlineVariant
      ..strokeWidth = 1.5;
    for (final edge in graph.edges) {
      final from = result.positions[edge.fromNodeId];
      final to = result.positions[edge.toNodeId];
      if (from != null && to != null) {
        canvas.drawLine(project(from), project(to), edgePaint);
      }
    }
    final affectedPaint = Paint()..color = colorScheme.primary;
    final unaffectedPaint = Paint()..color = colorScheme.secondaryContainer;
    for (final entry in result.positions.entries) {
      canvas.drawCircle(
        project(entry.value),
        5,
        result.affectedNodeIds.contains(entry.key)
            ? affectedPaint
            : unaffectedPaint,
      );
    }
  }

  @override
  bool shouldRepaint(_LayoutPreviewPainter oldDelegate) =>
      oldDelegate.result != result || oldDelegate.colorScheme != colorScheme;
}
