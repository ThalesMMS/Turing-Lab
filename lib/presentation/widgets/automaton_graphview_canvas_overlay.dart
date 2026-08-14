part of 'automaton_graphview_canvas.dart';

void _logAutomatonGraphViewCanvasOverlay(String message) {
  if (kDebugMode) {
    debugPrint('[AutomatonGraphViewCanvas] $message');
  }
}

extension _AutomatonGraphViewCanvasOverlay on _AutomatonGraphViewCanvasState {
  List<GraphViewCanvasEdge> _findExistingEdgesExtracted(
    String fromId,
    String toId,
  ) {
    return _controller.edges
        .where((edge) => edge.fromStateId == fromId && edge.toStateId == toId)
        .toList(growable: false);
  }

  Future<void> _showTransitionEditorExtracted(
    String fromId,
    String toId,
  ) async {
    final existingEdges = _findExistingEdges(fromId, toId);
    _logAutomatonGraphViewCanvasOverlay(
      'Preparing transition editor '
      'from=$fromId to=$toId existing=${existingEdges.length}',
    );
    GraphViewCanvasEdge? existing;
    var createNew = existingEdges.isEmpty;

    if (!createNew) {
      existing = existingEdges.firstWhereOrNull(
        (edge) => _selectedTransitions.contains(edge.id),
      );

      if (existing == null) {
        final selection = await _promptTransitionEditChoice(existingEdges);
        if (!mounted || selection == null) {
          return;
        }
        if (selection.createNew) {
          createNew = true;
        } else {
          existing = selection.edge;
          if (existing == null) {
            createNew = true;
          }
        }
      }
    }

    final payload = _transitionConfig.initialPayloadBuilder(existing);
    final worldAnchor = !createNew && existing != null
        ? resolveLinkAnchorWorld(_controller, existing) ??
            Offset(existing.controlPointX ?? 0, existing.controlPointY ?? 0)
        : _deriveControlPoint(fromId, toId);
    final overlayData = AutomatonTransitionOverlayData(
      fromStateId: fromId,
      toStateId: toId,
      worldAnchor: worldAnchor,
      payload: payload,
      transitionId: createNew ? null : existing?.id,
      edge: existing,
    );

    final overlayDisplayed = _showTransitionOverlay(overlayData);

    if (overlayDisplayed) {
      _logAutomatonGraphViewCanvasOverlay(
        'Showing transition editor '
        'for $fromId → $toId (transitionId: ${existing?.id})',
      );
      _updateCanvasState(() {
        _selectedTransitions.clear();
        if (!createNew && existing?.id != null) {
          _selectedTransitions.add(existing!.id);
        }
      });
      return;
    }

    _logAutomatonGraphViewCanvasOverlay(
      'Fallback modal for $fromId → $toId (existing=${existing?.id})',
    );

    final result = await showDialog<AutomatonTransitionPayload?>(
      context: context,
      builder: (context) {
        final controller = AutomatonTransitionOverlayController(
          onSubmit: (value) => Navigator.of(context).pop(value),
          onCancel: () => Navigator.of(context).pop(null),
        );
        return Dialog(
          insetPadding: const EdgeInsets.all(24),
          child: _transitionConfig.overlayBuilder(
            context,
            overlayData,
            controller,
          ),
        );
      },
    );

    if (!mounted || result == null) {
      return;
    }

    _logAutomatonGraphViewCanvasOverlay(
      'Persisting transition '
      'for $fromId → $toId (transitionId: ${existing?.id})',
    );

    _transitionConfig.persistTransition(
      AutomatonTransitionPersistRequest(
        fromStateId: fromId,
        toStateId: toId,
        transitionId: createNew ? null : existing?.id,
        payload: result,
        worldAnchor: worldAnchor,
        controller: _controller,
      ),
    );
  }

  Future<_TransitionEditChoice?> _promptTransitionEditChoiceExtracted(
    List<GraphViewCanvasEdge> edges,
  ) {
    return showDialog<_TransitionEditChoice>(
      context: context,
      builder: (context) {
        final localizations =
            Localizations.of<AppLocalizations>(context, AppLocalizations) ??
                lookupAppLocalizations(
                  Localizations.maybeLocaleOf(context) ??
                      WidgetsBinding.instance.platformDispatcher.locale,
                );
        return AlertDialog(
          title: Text(localizations.selectTransition),
          content: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 360),
            child: SingleChildScrollView(
              child: ListBody(
                children: [
                  for (final edge in edges)
                    ListTile(
                      key: ValueKey('automaton-transition-choice-${edge.id}'),
                      leading: const Icon(Icons.edit_outlined),
                      title: Text(edge.label.isEmpty ? edge.id : edge.label),
                      subtitle: Text('${edge.fromStateId} → ${edge.toStateId}'),
                      onTap: () => Navigator.of(
                        context,
                      ).pop(_TransitionEditChoice.edit(edge)),
                    ),
                  ListTile(
                    key: const ValueKey(
                      'automaton-transition-choice-create-new',
                    ),
                    leading: const Icon(Icons.add_outlined),
                    title: Text(localizations.createNewTransition),
                    onTap: () => Navigator.of(
                      context,
                    ).pop(const _TransitionEditChoice.createNew()),
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text(MaterialLocalizations.of(context).cancelButtonLabel),
            ),
          ],
        );
      },
    );
  }

  Offset _deriveControlPointExtracted(String fromId, String toId) {
    final fromNode = _controller.nodeById(fromId);
    final toNode = _controller.nodeById(toId);
    if (fromNode == null || toNode == null) {
      return Offset.zero;
    }

    final fromCenter = Offset(
      fromNode.x + _kNodeRadius,
      fromNode.y + _kNodeRadius,
    );
    final toCenter = Offset(toNode.x + _kNodeRadius, toNode.y + _kNodeRadius);

    if (fromId == toId) {
      if (_customization.edgeRenderMode == TuringLabEdgeRenderMode.groupedFsa) {
        final groupedLoops = _findExistingEdges(fromId, toId).length;
        final extraOffset = resolveGroupedFsaLoopExtraOffset(groupedLoops);
        return fromCenter.translate(0, -(_kNodeDiameter + extraOffset));
      }
      return fromCenter.translate(0, -_kNodeDiameter);
    }

    if (_customization.edgeRenderMode == TuringLabEdgeRenderMode.groupedFsa) {
      final hasOpposingEdge = _findExistingEdges(toId, fromId).isNotEmpty;
      return resolveGroupedFsaControlPoint(
        fromId: fromId,
        toId: toId,
        fromCenter: fromCenter,
        toCenter: toCenter,
        hasOpposingTraffic: hasOpposingEdge,
      );
    }

    final midpoint = Offset(
      (fromCenter.dx + toCenter.dx) / 2,
      (fromCenter.dy + toCenter.dy) / 2,
    );

    final dx = toCenter.dx - fromCenter.dx;
    final dy = toCenter.dy - fromCenter.dy;
    var normal = Offset(-dy, dx);
    if (normal.distanceSquared == 0) {
      normal = const Offset(0, -1);
    }
    final existing = _findExistingEdges(fromId, toId).length;
    final direction = existing.isEven ? 1.0 : -1.0;
    final magnitude = (_kNodeDiameter * 0.8) + existing * 12;
    final normalized = normal / normal.distance * magnitude * direction;
    return midpoint + normalized;
  }

  void _handleGraphRevisionChangedExtracted() {
    if (!mounted) {
      return;
    }
    _invalidateEdgeRendererCachesIfNeeded();
    _refreshTransitionOverlayFromGraph();
    _updateTransitionOverlayPosition();
  }

  void _refreshTransitionOverlayFromGraphExtracted() {
    final state = _transitionOverlayState.value;
    if (state == null) {
      return;
    }

    final data = state.data;
    final transitionId = data.transitionId;
    if (transitionId != null) {
      final edge = _controller.edgeById(transitionId);
      if (edge == null) {
        _hideTransitionOverlay();
        return;
      }
      final anchor =
          resolveLinkAnchorWorld(_controller, edge) ?? data.worldAnchor;
      final payload = _transitionConfig.initialPayloadBuilder(edge);
      _transitionOverlayState.value = state.copyWith(
        data: data.copyWith(payload: payload, worldAnchor: anchor, edge: edge),
      );
      final shouldUpdateSelection = _selectedTransitions.length != 1 ||
          !_selectedTransitions.contains(transitionId);
      if (shouldUpdateSelection) {
        _updateCanvasState(() {
          _selectedTransitions
            ..clear()
            ..add(transitionId);
        });
      }
    } else {
      final anchor = _deriveControlPoint(data.fromStateId, data.toStateId);
      _transitionOverlayState.value = state.copyWith(
        data: data.copyWith(worldAnchor: anchor),
      );
    }
  }

  void _updateTransitionOverlayPositionExtracted() {
    final state = _transitionOverlayState.value;
    if (state == null) {
      return;
    }
    final overlay = Overlay.maybeOf(context);
    if (overlay == null) {
      return;
    }
    final overlayBox = overlay.context.findRenderObject() as RenderBox?;
    if (overlayBox == null || !overlayBox.hasSize) {
      return;
    }
    final overlayPosition = overlayBox.size.center(Offset.zero);
    if ((overlayPosition - state.overlayPosition).distance <= 0.5) {
      return;
    }
    _transitionOverlayState.value = state.copyWith(
      overlayPosition: overlayPosition,
    );
  }

  bool _showTransitionOverlayExtracted(AutomatonTransitionOverlayData data) {
    final overlayState = Overlay.maybeOf(context);
    if (overlayState == null) {
      return false;
    }
    final overlayBox = overlayState.context.findRenderObject() as RenderBox?;
    if (overlayBox == null || !overlayBox.hasSize) {
      return false;
    }
    final overlayPosition = overlayBox.size.center(Offset.zero);
    _ensureTransitionOverlay(overlayState);
    _transitionOverlayState.value = _GraphViewTransitionOverlayState(
      data: data,
      overlayPosition: overlayPosition,
    );
    return true;
  }

  void _ensureTransitionOverlayExtracted(OverlayState overlayState) {
    if (_transitionOverlayEntry != null) {
      return;
    }
    _transitionOverlayEntry = OverlayEntry(
      builder: (context) {
        return Material(
          type: MaterialType.transparency,
          child: ValueListenableBuilder<_GraphViewTransitionOverlayState?>(
            valueListenable: _transitionOverlayState,
            builder: (context, state, _) {
              if (state == null) {
                return const SizedBox.shrink();
              }
              final overlayController = AutomatonTransitionOverlayController(
                onSubmit: (payload) => _handleOverlaySubmit(state, payload),
                onCancel: _hideTransitionOverlay,
              );
              final overlayChild = _transitionConfig.overlayBuilder(
                context,
                state.data,
                overlayController,
              );
              return Stack(
                children: [
                  Positioned(
                    left: state.overlayPosition.dx,
                    top: state.overlayPosition.dy,
                    child: FractionalTranslation(
                      translation: const Offset(-0.5, -0.5),
                      child: overlayChild,
                    ),
                  ),
                ],
              );
            },
          ),
        );
      },
    );
    overlayState.insert(_transitionOverlayEntry!);
  }

  void _handleOverlaySubmitExtracted(
    _GraphViewTransitionOverlayState state,
    AutomatonTransitionPayload payload,
  ) {
    final data = state.data;
    _logAutomatonGraphViewCanvasOverlay(
      'Persisting transition '
      'for ${data.fromStateId} → ${data.toStateId} '
      '(transitionId: ${data.transitionId})',
    );
    _transitionConfig.persistTransition(
      AutomatonTransitionPersistRequest(
        fromStateId: data.fromStateId,
        toStateId: data.toStateId,
        transitionId: data.transitionId,
        payload: payload,
        worldAnchor: data.worldAnchor,
        controller: _controller,
      ),
    );
    _hideTransitionOverlay();
  }

  void _hideTransitionOverlayExtracted() {
    final hadOverlay = _transitionOverlayState.value != null;
    final hadSelection = _selectedTransitions.isNotEmpty;
    if (hadOverlay) {
      _transitionOverlayState.value = null;
    }
    if (hadOverlay || hadSelection) {
      if (!mounted) {
        return;
      }
      _updateCanvasState(() {
        _selectedTransitions.clear();
      });
    }
  }

  bool _isNodeHighlightedExtracted(
    GraphViewCanvasNode node,
    SimulationHighlight highlight,
  ) {
    return highlight.stateIds.contains(node.id) ||
        node.id == _transitionSourceId;
  }
}
