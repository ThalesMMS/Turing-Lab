part of 'automaton_graphview_canvas.dart';

void _logAutomatonGraphViewCanvasInteraction(String message) {
  if (kDebugMode) {
    debugPrint('[AutomatonGraphViewCanvas] $message');
  }
}

extension _AutomatonGraphViewCanvasInteractions
    on _AutomatonGraphViewCanvasState {
  Offset _screenToWorld(Offset localPosition) =>
      _viewportAdapter.screenToWorld(localPosition);

  Offset _globalToCanvasLocal(Offset globalPosition) =>
      _viewportAdapter.globalToLocal(widget.canvasKey, globalPosition);

  GraphViewCanvasNode? _hitTestNode(
    Offset localPosition, {
    bool logDetails = true,
  }) {
    // Keep hit testing in world coordinates so it remains stable under zoom.
    final world = _screenToWorld(localPosition);

    // A small hit slop keeps slow-start drags and near-edge touches anchored to
    // the intended node instead of falling through to the canvas pan gesture.
    const dragHitSlop = 8.0;
    const hitRadius = _kNodeRadius + dragHitSlop;
    const hitRadiusSquared = hitRadius * hitRadius;

    GraphViewCanvasNode? closest;
    var closestDistanceSquared = double.infinity;
    var candidateCount = 0;

    // PERF: avoid per-node sqrt by staying in squared distance space.
    // Timeline events are assert-only, so there is zero overhead in release.
    assert(() {
      Timeline.startSync('GraphViewCanvas.hitTestNode');
      return true;
    }());
    var iterations = 0;
    try {
      for (final node in _controller.nodes) {
        iterations++;

        // Coarse early-out: skip nodes whose bounding box cannot intersect the
        // circular hit area.
        final left = node.x;
        final top = node.y;
        final right = left + _kNodeRadius * 2;
        final bottom = top + _kNodeRadius * 2;
        if (world.dx < left - hitRadius ||
            world.dx > right + hitRadius ||
            world.dy < top - hitRadius ||
            world.dy > bottom + hitRadius) {
          continue;
        }

        candidateCount++;
        final center = Offset(left + _kNodeRadius, top + _kNodeRadius);
        final dx = world.dx - center.dx;
        final dy = world.dy - center.dy;
        final distanceSquared = dx * dx + dy * dy;
        if (distanceSquared <= hitRadiusSquared &&
            distanceSquared < closestDistanceSquared) {
          closest = node;
          closestDistanceSquared = distanceSquared;
        }
      }
    } finally {
      assert(() {
        Timeline.finishSync();
        return true;
      }());
    }

    assert(() {
      Timeline.instantSync(
        'GraphViewCanvas.hitTestNode.result',
        arguments: {
          'iterations': iterations,
          'candidates': candidateCount,
          'hit': closest != null,
          'tool': _activeTool.name,
        },
      );
      return true;
    }());

    if (logDetails) {
      if (closest != null) {
        _logAutomatonGraphViewCanvasInteraction(
          'Hit node ${closest.id} '
          '(tool=${_activeTool.name}) local=$localPosition world=$world '
          'candidates=$candidateCount',
        );
      } else if (_activeTool == AutomatonCanvasTool.transition) {
        _logAutomatonGraphViewCanvasInteraction(
          'Transition tool miss local=$localPosition world=$world '
          'candidates=$candidateCount',
        );
      }
    }
    return closest;
  }

  List<_CanvasEdgeHit> _hitTestEdges(Offset localPosition) {
    final world = _screenToWorld(localPosition);
    final transformation =
        _controller.graphController.transformationController?.value;
    final scale = transformation?.getMaxScaleOnAxis() ?? 1.0;
    final tolerance = 14.0 / math.max(scale.abs(), 0.001);
    // A rendered label is a first-class hit target; inflate it to at least a
    // 44x44 logical touch area (world units shrink as the zoom grows).
    final minLabelSide = 44.0 / math.max(scale.abs(), 0.001);
    final labelHits = <_CanvasEdgeHit>[];
    final pathHits = <_CanvasEdgeHit>[];

    for (final edge in _controller.edges) {
      final graphEdge = _controller.graphEdgeById(edge.id);
      final geometry =
          graphEdge == null ? null : _edgeRenderer.geometryForEdge(graphEdge);
      if (geometry == null) {
        continue;
      }
      final labelRect = geometry.labelRect;
      if (labelRect != null) {
        final inflated = Rect.fromCenter(
          center: labelRect.center,
          width: math.max(labelRect.width, minLabelSide),
          height: math.max(labelRect.height, minLabelSide),
        );
        if (inflated.contains(world)) {
          labelHits.add(
            _CanvasEdgeHit(
              edge: edge,
              distance: (world - labelRect.center).distance,
            ),
          );
          continue;
        }
      }
      final distance = geometry.pathGeometry.distanceTo(
        world,
        sampleSpacing: math.max(4, tolerance * 0.5),
      );
      if (distance <= tolerance) {
        pathHits.add(_CanvasEdgeHit(edge: edge, distance: distance));
      }
    }

    labelHits.sort((left, right) => left.distance.compareTo(right.distance));
    pathHits.sort((left, right) => left.distance.compareTo(right.distance));
    // Label hits win over proximity hits so tapping a label that was laid
    // out away from its curve still edits the right transition.
    return [...labelHits, ...pathHits];
  }

  Future<void> _editHitEdge(List<_CanvasEdgeHit> hits) async {
    if (!_customization.enableToolSelection) {
      return;
    }
    if (hits.isEmpty) {
      return;
    }
    final closest = hits.first.edge;
    final matchingEndpointHits = hits
        .where(
          (hit) =>
              hit.edge.fromStateId == closest.fromStateId &&
              hit.edge.toStateId == closest.toStateId,
        )
        .toList(growable: false);
    _updateCanvasState(() {
      _selectedNodeId = null;
      _selectedTransitions.clear();
      if (matchingEndpointHits.length == 1) {
        _selectedTransitions.add(closest.id);
      }
    });
    await _showTransitionEditor(closest.fromStateId, closest.toStateId);
  }

  void _logCanvasTapFromLocal({
    required String source,
    required Offset localPosition,
  }) {
    final node = _hitTestNode(localPosition, logDetails: false);
    final world = _screenToWorld(localPosition);
    final target = node?.id ?? 'canvas-background';
    _logAutomatonGraphViewCanvasInteraction(
      'Tap source=$source target=$target '
      'tool=${_activeTool.name} local=$localPosition world=$world',
    );
  }

  void _logCanvasTapFromGlobal({
    required String source,
    required Offset globalPosition,
  }) {
    final local = _globalToCanvasLocal(globalPosition);
    _logCanvasTapFromLocal(source: source, localPosition: local);
  }

  void _handleCanvasTapDown(TapDownDetails details) {
    final global = details.globalPosition;
    final local = _globalToCanvasLocal(global);
    _logCanvasTapFromLocal(source: 'tap-down', localPosition: local);
  }

  void _handleCanvasLongPressStart(LongPressStartDetails details) {
    _handleCanvasContextGesture(details.globalPosition);
  }

  void _handleCanvasSecondaryTapUp(TapUpDetails details) {
    _handleCanvasContextGesture(details.globalPosition);
  }

  Future<void> _handleCanvasContextGesture(
    Offset globalPosition,
  ) async {
    // Long-press and secondary tap open the state options or transition
    // editor in every tool, so add-state and transition modes never freeze
    // the editing affordances.
    if (!_customization.enableToolSelection) {
      return;
    }
    _canvasFocusNode.requestFocus();
    final local = _globalToCanvasLocal(globalPosition);
    final node = _hitTestNode(local, logDetails: false);
    if (node != null) {
      _setSelectedNodeId(node.id);
      _handleNodeContextTap(node.id);
      return;
    }
    await _editHitEdge(_hitTestEdges(local));
  }

  void _handleNodePointerDown(Offset globalPosition) {
    _logCanvasTapFromGlobal(
      source: 'pan-pointer',
      globalPosition: globalPosition,
    );
    _doubleTapCandidateNodeId = null;
    if (_activeTool != AutomatonCanvasTool.selection) {
      return;
    }

    final local = _globalToCanvasLocal(globalPosition);
    final node = _hitTestNode(local, logDetails: false);
    final previousTap = _lastTapTimestamp;
    if (node == null || node.id != _lastTapNodeId || previousTap == null) {
      return;
    }

    final elapsed = _monotonicStopwatch.elapsed - previousTap;
    if (elapsed >= kDoubleTapMinTime && elapsed <= kDoubleTapTimeout) {
      _doubleTapCandidateNodeId = node.id;
    }
  }

  void _beginNodeDrag(GraphViewCanvasNode node, Offset localPosition) {
    _logAutomatonGraphViewCanvasInteraction('Begin drag for ${node.id}');
    _hideTransitionOverlay();
    _draggingNodeId = node.id;
    _dragStartWorldPosition = _screenToWorld(localPosition);
    final current = _controller.nodeById(node.id) ?? node;
    _dragStartNodePosition = Offset(current.x, current.y);
    _dragCurrentNodePosition = _dragStartNodePosition;
    _isDraggingNode = true;
    _didMoveDraggedNode = false;
  }

  void _updateNodeDrag(Offset localPosition) {
    final nodeId = _draggingNodeId;
    final dragStartWorld = _dragStartWorldPosition;
    final dragStartNodePosition = _dragStartNodePosition;
    if (nodeId == null ||
        dragStartWorld == null ||
        dragStartNodePosition == null) {
      return;
    }
    final currentWorld = _screenToWorld(localPosition);
    final delta = currentWorld - dragStartWorld;
    final nextPosition = dragStartNodePosition + delta;
    _controller.previewStatePosition(nodeId, nextPosition);
    _dragCurrentNodePosition = nextPosition;
    _didMoveDraggedNode = true;
  }

  void _endNodeDrag() {
    _draggingNodeId = null;
    _dragStartWorldPosition = null;
    _dragStartNodePosition = null;
    _dragCurrentNodePosition = null;
    _dragPointerStartLocalPosition = null;
    _dragPointerCurrentLocalPosition = null;
    _dragHitSlop = null;
    _setCanvasPanSuppressed(false, reason: 'drag ended');
    _isDraggingNode = false;
    _didMoveDraggedNode = false;
  }

  Future<void> _handleCanvasTapUp(TapUpDetails details) async {
    final global = details.globalPosition;
    final local = _globalToCanvasLocal(global);
    _logAutomatonGraphViewCanvasInteraction(
      'Tap up with active tool ${_activeTool.name} local=$local',
    );
    final node = _hitTestNode(local, logDetails: false);

    if (_activeTool == AutomatonCanvasTool.addState) {
      if (_isDraggingNode || _didMoveDraggedNode || node != null) {
        return;
      }
      final world = _screenToWorld(local);
      _controller.addStateAt(world);
      return;
    }

    if (_activeTool == AutomatonCanvasTool.transition) {
      if (node != null) {
        _handleNodeTap(node.id);
      }
      return;
    }

    if (_activeTool != AutomatonCanvasTool.selection) {
      _doubleTapCandidateNodeId = null;
      return;
    }

    if (_isDraggingNode || _didMoveDraggedNode) {
      _lastTapNodeId = null;
      _lastTapTimestamp = null;
      _doubleTapCandidateNodeId = null;
      return;
    }

    if (node == null) {
      final edgeHits = _hitTestEdges(local);
      if (edgeHits.isNotEmpty) {
        _lastTapNodeId = null;
        _lastTapTimestamp = null;
        _doubleTapCandidateNodeId = null;
        await _editHitEdge(edgeHits);
        return;
      }
      _setSelectedNodeId(null);
      _lastTapNodeId = null;
      _lastTapTimestamp = null;
      _doubleTapCandidateNodeId = null;
      return;
    }

    _registerNodeTap(node.id);
  }

  void _handleNodePanStart(DragStartDetails details) {
    if (!_customization.enableStateDrag) {
      return;
    }
    final localPosition = _globalToCanvasLocal(details.globalPosition);
    final node = _hitTestNode(localPosition);
    if (node == null) {
      return;
    }
    _logAutomatonGraphViewCanvasInteraction(
      'pan start gesture -> ${node.id} '
      'local=$localPosition',
    );
    _setCanvasPanSuppressed(true, reason: 'node drag start ${node.id}');
    _beginNodeDrag(node, localPosition);
    _dragPointerStartLocalPosition = localPosition;
    _dragPointerCurrentLocalPosition = localPosition;
    _dragHitSlop = computeHitSlop(
      details.kind ?? PointerDeviceKind.touch,
      MediaQuery.maybeGestureSettingsOf(context),
    );
  }

  void _handleNodePanUpdate(DragUpdateDetails details) {
    _logAutomatonGraphViewCanvasInteraction(
      'pan update delta=${details.delta}',
    );
    final localPosition = _globalToCanvasLocal(details.globalPosition);
    _dragPointerCurrentLocalPosition = localPosition;
    _updateNodeDrag(localPosition);
  }

  void _handleNodePanEnd(DragEndDetails details) {
    final nodeId = _draggingNodeId;
    final didMove = _didMoveDraggedNode;
    final finalPosition = _dragCurrentNodePosition;
    final startPosition = _dragStartNodePosition;
    final pointerStart = _dragPointerStartLocalPosition;
    final pointerCurrent = _dragPointerCurrentLocalPosition;
    final hitSlop = _dragHitSlop;
    final shouldCommit = didMove &&
        pointerStart != null &&
        pointerCurrent != null &&
        hitSlop != null &&
        (pointerCurrent - pointerStart).distance > hitSlop;
    _logAutomatonGraphViewCanvasInteraction(
      'pan end velocity=${details.velocity}',
    );
    _endNodeDrag();
    if (nodeId != null) {
      _lastTapNodeId = null;
      _lastTapTimestamp = null;
      _doubleTapCandidateNodeId = null;
    }
    if (shouldCommit && nodeId != null && finalPosition != null) {
      _controller.moveState(nodeId, finalPosition);
      return;
    }
    if (didMove && nodeId != null && startPosition != null) {
      _controller.previewStatePosition(nodeId, startPosition);
    }
  }

  void _handleNodePanCancel() {
    _logAutomatonGraphViewCanvasInteraction('pan cancel');
    final nodeId = _draggingNodeId;
    final startPosition = _dragStartNodePosition;
    if (nodeId != null && startPosition != null) {
      _controller.previewStatePosition(nodeId, startPosition);
      _lastTapNodeId = null;
      _lastTapTimestamp = null;
      _doubleTapCandidateNodeId = null;
    }
    _endNodeDrag();
  }

  void _handleNodeTap(String nodeId) {
    _logAutomatonGraphViewCanvasInteraction(
      'Node tapped $nodeId with active tool ${_activeTool.name}',
    );
    if (_activeTool == AutomatonCanvasTool.selection) {
      _setSelectedNodeId(nodeId);
      return;
    }
    if (_activeTool != AutomatonCanvasTool.transition) {
      return;
    }

    if (_transitionSourceId == null) {
      _logAutomatonGraphViewCanvasInteraction(
        'Transition source selected -> $nodeId',
      );
      _setTransitionSourceId(nodeId);
      return;
    }

    final sourceId = _transitionSourceId!;
    _setTransitionSourceId(null);
    _logAutomatonGraphViewCanvasInteraction(
      'Transition target selected -> $nodeId (source: $sourceId)',
    );
    _showTransitionEditor(sourceId, nodeId);
  }

  void _handleNodeContextTap(String nodeId) {
    if (!_customization.enableToolSelection) {
      return;
    }
    final node = _controller.nodeById(nodeId);
    if (node == null) {
      return;
    }
    _logAutomatonGraphViewCanvasInteraction(
      'opening state options for $nodeId',
    );
    _showStateOptions(node);
  }

  void _registerNodeTap(String nodeId) {
    _setSelectedNodeId(nodeId);
    if (_doubleTapCandidateNodeId == nodeId) {
      _handleNodeContextTap(nodeId);
      _lastTapNodeId = null;
      _lastTapTimestamp = null;
      _doubleTapCandidateNodeId = null;
    } else {
      _lastTapNodeId = nodeId;
      _lastTapTimestamp = _monotonicStopwatch.elapsed;
      _doubleTapCandidateNodeId = null;
    }
  }

  Future<void> _showStateOptions(GraphViewCanvasNode node) async {
    final customHandler = _customization.stateOptionsHandler;
    if (customHandler != null) {
      await customHandler(context, node, _controller);
      return;
    }
    final l10n = appLocalizationsOf(context);
    final labelController = TextEditingController(text: node.label);
    var isInitial = node.isInitial;
    var isAccepting = node.isAccepting;

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (context) {
        final theme = Theme.of(context);
        return Padding(
          padding: EdgeInsets.only(
            left: 24,
            right: 24,
            top: 24,
            bottom: MediaQuery.of(context).viewInsets.bottom + 24,
          ),
          child: StatefulBuilder(
            builder: (context, setModalState) {
              return Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    node.label.isEmpty ? node.id : node.label,
                    style: theme.textTheme.titleMedium,
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: labelController,
                    decoration: InputDecoration(labelText: l10n.stateLabel),
                    textInputAction: TextInputAction.done,
                    onSubmitted: (value) {
                      final resolved = value.trim();
                      if (resolved != node.label) {
                        _controller.updateStateLabel(node.id, resolved);
                      }
                      Navigator.of(context).pop();
                    },
                  ),
                  const SizedBox(height: 12),
                  SwitchListTile.adaptive(
                    value: isInitial,
                    title: Text(l10n.initialState),
                    onChanged: (value) {
                      setModalState(() => isInitial = value);
                    },
                  ),
                  if (_customization.supportsAcceptingStates)
                    SwitchListTile.adaptive(
                      value: isAccepting,
                      title: Text(l10n.acceptingState),
                      onChanged: (value) {
                        setModalState(() => isAccepting = value);
                      },
                    ),
                  const SizedBox(height: 16),
                  OutlinedButton.icon(
                    key: ValueKey('automaton-state-delete-${node.id}'),
                    onPressed: () async {
                      if (!await _confirmStateAnnotationDeletion(node.id) ||
                          !context.mounted) {
                        return;
                      }
                      _controller.removeState(node.id);
                      _setSelectedNodeId(null);
                      Navigator.of(context).pop();
                    },
                    icon: const Icon(Icons.delete_outline),
                    label: Text(l10n.deleteState),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: theme.colorScheme.error,
                    ),
                  ),
                  FilledButton(
                    onPressed: () {
                      final resolved = labelController.text.trim();
                      if (resolved != node.label) {
                        _controller.updateStateLabel(node.id, resolved);
                      }
                      _controller.updateStateFlags(
                        node.id,
                        isInitial: isInitial,
                        isAccepting: _customization.supportsAcceptingStates
                            ? isAccepting
                            : null,
                      );
                      Navigator.of(context).pop();
                    },
                    child: Text(l10n.saveChanges),
                  ),
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: Text(l10n.close),
                  ),
                ],
              );
            },
          ),
        );
      },
    );

    labelController.dispose();
  }
}
