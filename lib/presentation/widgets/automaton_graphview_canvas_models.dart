part of 'automaton_graphview_canvas.dart';

typedef AutomatonTransitionOverlayBuilder = Widget Function(
  BuildContext context,
  AutomatonTransitionOverlayData data,
  AutomatonTransitionOverlayController controller,
);

/// Payload used by the transition overlay to communicate user edits back to
/// the canvas.
sealed class AutomatonTransitionPayload {
  const AutomatonTransitionPayload();
}

/// Simple payload representing a raw transition label.
class AutomatonLabelTransitionPayload extends AutomatonTransitionPayload {
  const AutomatonLabelTransitionPayload(this.label);

  final String label;
}

/// Payload used by read-only canvases, which never open or persist edits.
class _AutomatonReadOnlyTransitionPayload extends AutomatonTransitionPayload {
  const _AutomatonReadOnlyTransitionPayload();
}

/// Payload describing a request to delete the currently edited transition.
class AutomatonDeleteTransitionPayload extends AutomatonTransitionPayload {
  const AutomatonDeleteTransitionPayload();
}

/// Payload describing TM tape operations (read/write/direction).
class AutomatonTmTransitionPayload extends AutomatonTransitionPayload {
  const AutomatonTmTransitionPayload({
    required this.readSymbol,
    required this.writeSymbol,
    required this.direction,
  });

  final String readSymbol;
  final String writeSymbol;
  final TapeDirection direction;
}

/// Payload describing PDA stack operations (read/pop/push and λ flags).
class AutomatonPdaTransitionPayload extends AutomatonTransitionPayload {
  const AutomatonPdaTransitionPayload({
    required this.readSymbol,
    required this.popSymbol,
    required this.pushSymbol,
    this.pushSymbols,
    required this.isLambdaInput,
    required this.isLambdaPop,
    required this.isLambdaPush,
  });

  final String readSymbol;
  final String popSymbol;
  final String pushSymbol;
  final List<String>? pushSymbols;
  final bool isLambdaInput;
  final bool isLambdaPop;
  final bool isLambdaPush;
}

/// Immutable description of the current transition overlay request.
class AutomatonTransitionOverlayData {
  const AutomatonTransitionOverlayData({
    required this.fromStateId,
    required this.toStateId,
    required this.worldAnchor,
    required this.payload,
    this.transitionId,
    this.edge,
  });

  final String fromStateId;
  final String toStateId;
  final Offset worldAnchor;
  final AutomatonTransitionPayload payload;
  final String? transitionId;
  final GraphViewCanvasEdge? edge;

  AutomatonTransitionOverlayData copyWith({
    AutomatonTransitionPayload? payload,
    Offset? worldAnchor,
    String? transitionId,
    GraphViewCanvasEdge? edge,
    bool clearTransitionId = false,
    bool clearEdge = false,
  }) {
    return AutomatonTransitionOverlayData(
      fromStateId: fromStateId,
      toStateId: toStateId,
      worldAnchor: worldAnchor ?? this.worldAnchor,
      payload: payload ?? this.payload,
      transitionId:
          clearTransitionId ? null : (transitionId ?? this.transitionId),
      edge: clearEdge ? null : (edge ?? this.edge),
    );
  }
}

/// Controller exposed to the overlay widget allowing it to submit or cancel
/// the edit flow.
class AutomatonTransitionOverlayController {
  AutomatonTransitionOverlayController({
    required this.onSubmit,
    required this.onCancel,
  });

  final void Function(AutomatonTransitionPayload payload) onSubmit;
  final VoidCallback onCancel;

  void submit(AutomatonTransitionPayload payload) => onSubmit(payload);
  void cancel() => onCancel();
}

/// Request emitted when the transition overlay is submitted.
class AutomatonTransitionPersistRequest {
  const AutomatonTransitionPersistRequest({
    required this.fromStateId,
    required this.toStateId,
    required this.payload,
    required this.worldAnchor,
    required this.controller,
    this.transitionId,
  });

  final String fromStateId;
  final String toStateId;
  final String? transitionId;
  final AutomatonTransitionPayload payload;
  final Offset worldAnchor;
  final BaseGraphViewCanvasController<dynamic, dynamic> controller;
}

bool _handleDeleteRequest(AutomatonTransitionPersistRequest request) {
  if (request.payload is! AutomatonDeleteTransitionPayload) {
    return false;
  }
  final transitionId = request.transitionId;
  if (transitionId != null) {
    request.controller.removeTransition(transitionId);
  }
  return true;
}

/// Transition configuration describing how to build overlays and persist
/// updates for the current automaton type.
class AutomatonGraphViewTransitionConfig {
  const AutomatonGraphViewTransitionConfig({
    required this.initialPayloadBuilder,
    required this.overlayBuilder,
    required this.persistTransition,
  });

  final AutomatonTransitionPayload Function(GraphViewCanvasEdge? edge)
      initialPayloadBuilder;
  final AutomatonTransitionOverlayBuilder overlayBuilder;
  final void Function(AutomatonTransitionPersistRequest request)
      persistTransition;
}

/// Customisation options applied to the graph canvas behaviour.
class AutomatonGraphViewCanvasCustomization {
  const AutomatonGraphViewCanvasCustomization({
    required this.transitionConfigBuilder,
    this.enableStateDrag = true,
    this.enableToolSelection = true,
    this.edgeRenderMode = TuringLabEdgeRenderMode.standard,
  });

  final AutomatonGraphViewTransitionConfig Function(
    BaseGraphViewCanvasController<dynamic, dynamic> controller,
  ) transitionConfigBuilder;

  final bool enableStateDrag;
  final bool enableToolSelection;
  final TuringLabEdgeRenderMode edgeRenderMode;

  factory AutomatonGraphViewCanvasCustomization.readOnly({
    TuringLabEdgeRenderMode edgeRenderMode = TuringLabEdgeRenderMode.standard,
  }) {
    return _ReadOnlyAutomatonGraphViewCanvasCustomization(
      edgeRenderMode: edgeRenderMode,
    );
  }

  factory AutomatonGraphViewCanvasCustomization.fsa() {
    return AutomatonGraphViewCanvasCustomization(
      edgeRenderMode: TuringLabEdgeRenderMode.groupedFsa,
      transitionConfigBuilder: (controller) {
        return AutomatonGraphViewTransitionConfig(
          initialPayloadBuilder: (edge) =>
              AutomatonLabelTransitionPayload(edge?.label ?? ''),
          overlayBuilder: (context, data, overlayController) {
            final payload = data.payload as AutomatonLabelTransitionPayload;
            return GraphViewLabelFieldEditor(
              initialValue: payload.label,
              onSubmit: (value) => overlayController.submit(
                AutomatonLabelTransitionPayload(value),
              ),
              onCancel: overlayController.cancel,
              onDelete: data.transitionId == null
                  ? null
                  : () => overlayController.submit(
                        const AutomatonDeleteTransitionPayload(),
                      ),
            );
          },
          persistTransition: (request) {
            if (_handleDeleteRequest(request)) {
              return;
            }
            final controller = request.controller as GraphViewCanvasController;
            final payload = request.payload as AutomatonLabelTransitionPayload;
            controller.addOrUpdateTransition(
              fromStateId: request.fromStateId,
              toStateId: request.toStateId,
              label: payload.label,
              transitionId: request.transitionId,
              controlPointX: request.worldAnchor.dx,
              controlPointY: request.worldAnchor.dy,
            );
          },
        );
      },
    );
  }

  factory AutomatonGraphViewCanvasCustomization.pda({
    StackState? currentStack,
  }) {
    return AutomatonGraphViewCanvasCustomization(
      enableToolSelection: true,
      edgeRenderMode: TuringLabEdgeRenderMode.groupedFsa,
      transitionConfigBuilder: (controller) {
        return AutomatonGraphViewTransitionConfig(
          initialPayloadBuilder: (edge) {
            final read = edge?.readSymbol ?? '';
            final pop = edge?.popSymbol ?? '';
            final push = edge?.pushSymbol ?? '';
            return AutomatonPdaTransitionPayload(
              readSymbol: read,
              popSymbol: pop,
              pushSymbol: push,
              pushSymbols: edge?.pushSymbols,
              isLambdaInput: edge?.isLambdaInput ?? false,
              isLambdaPop: edge?.isLambdaPop ?? false,
              isLambdaPush: edge?.isLambdaPush ?? false,
            );
          },
          overlayBuilder: (context, data, overlayController) {
            final payload = data.payload as AutomatonPdaTransitionPayload;
            return PdaTransitionEditor(
              initialRead: payload.readSymbol,
              initialPop: payload.popSymbol,
              initialPush: payload.pushSymbol,
              isLambdaInput: payload.isLambdaInput,
              isLambdaPop: payload.isLambdaPop,
              isLambdaPush: payload.isLambdaPush,
              currentStack: currentStack,
              onSubmit: ({
                required String readSymbol,
                required String popSymbol,
                required String pushSymbol,
                required bool lambdaInput,
                required bool lambdaPop,
                required bool lambdaPush,
              }) {
                overlayController.submit(
                  AutomatonPdaTransitionPayload(
                    readSymbol: readSymbol,
                    popSymbol: popSymbol,
                    pushSymbol: pushSymbol,
                    // Retain atom boundaries only when the push is unchanged.
                    pushSymbols: !lambdaPush &&
                            lambdaPush == payload.isLambdaPush &&
                            pushSymbol == payload.pushSymbol
                        ? payload.pushSymbols
                        : null,
                    isLambdaInput: lambdaInput,
                    isLambdaPop: lambdaPop,
                    isLambdaPush: lambdaPush,
                  ),
                );
              },
              onCancel: overlayController.cancel,
              onDelete: data.transitionId == null
                  ? null
                  : () => overlayController.submit(
                        const AutomatonDeleteTransitionPayload(),
                      ),
            );
          },
          persistTransition: (request) {
            if (_handleDeleteRequest(request)) {
              return;
            }
            final pdaController =
                request.controller as GraphViewPdaCanvasController;
            final payload = request.payload as AutomatonPdaTransitionPayload;
            pdaController.addOrUpdateTransition(
              fromStateId: request.fromStateId,
              toStateId: request.toStateId,
              readSymbol: payload.readSymbol,
              popSymbol: payload.popSymbol,
              pushSymbol: payload.pushSymbol,
              pushSymbols: payload.pushSymbols,
              isLambdaInput: payload.isLambdaInput,
              isLambdaPop: payload.isLambdaPop,
              isLambdaPush: payload.isLambdaPush,
              transitionId: request.transitionId,
              controlPointX: request.worldAnchor.dx,
              controlPointY: request.worldAnchor.dy,
            );
          },
        );
      },
    );
  }

  factory AutomatonGraphViewCanvasCustomization.tm() {
    return AutomatonGraphViewCanvasCustomization(
      edgeRenderMode: TuringLabEdgeRenderMode.groupedFsa,
      transitionConfigBuilder: (controller) {
        return AutomatonGraphViewTransitionConfig(
          initialPayloadBuilder: (edge) => AutomatonTmTransitionPayload(
            readSymbol: edge?.readSymbol ?? '',
            writeSymbol: edge?.writeSymbol ?? '',
            direction: edge?.direction ?? TapeDirection.right,
          ),
          overlayBuilder: (context, data, overlayController) {
            final payload = data.payload as AutomatonTmTransitionPayload;
            return TmTransitionOperationsEditor(
              initialRead: payload.readSymbol,
              initialWrite: payload.writeSymbol,
              initialDirection: payload.direction,
              onSubmit: ({
                required String readSymbol,
                required String writeSymbol,
                required TapeDirection direction,
              }) {
                overlayController.submit(
                  AutomatonTmTransitionPayload(
                    readSymbol: readSymbol,
                    writeSymbol: writeSymbol,
                    direction: direction,
                  ),
                );
              },
              onCancel: overlayController.cancel,
              onDelete: data.transitionId == null
                  ? null
                  : () => overlayController.submit(
                        const AutomatonDeleteTransitionPayload(),
                      ),
            );
          },
          persistTransition: (request) {
            if (_handleDeleteRequest(request)) {
              return;
            }
            final tmController =
                request.controller as GraphViewTmCanvasController;
            final payload = request.payload as AutomatonTmTransitionPayload;
            tmController.addOrUpdateTransition(
              fromStateId: request.fromStateId,
              toStateId: request.toStateId,
              readSymbol: payload.readSymbol,
              writeSymbol: payload.writeSymbol,
              direction: payload.direction,
              transitionId: request.transitionId,
              controlPointX: request.worldAnchor.dx,
              controlPointY: request.worldAnchor.dy,
            );
          },
        );
      },
    );
  }
}

class _ReadOnlyAutomatonGraphViewCanvasCustomization
    extends AutomatonGraphViewCanvasCustomization {
  const _ReadOnlyAutomatonGraphViewCanvasCustomization({
    required super.edgeRenderMode,
  }) : super(
          enableStateDrag: false,
          enableToolSelection: false,
          transitionConfigBuilder: _buildReadOnlyTransitionConfig,
        );
}

AutomatonGraphViewTransitionConfig _buildReadOnlyTransitionConfig(
  BaseGraphViewCanvasController<dynamic, dynamic> controller,
) {
  return AutomatonGraphViewTransitionConfig(
    initialPayloadBuilder: (edge) =>
        const _AutomatonReadOnlyTransitionPayload(),
    overlayBuilder: (context, data, overlayController) =>
        const SizedBox.shrink(),
    persistTransition: (request) {},
  );
}

const double _kNodeDiameter = kAutomatonStateDiameter;
const double _kNodeRadius = _kNodeDiameter / 2;
const Size _kInitialArrowSize = Size(24, 12);

class _CanvasOrganicCurve extends Curve {
  const _CanvasOrganicCurve(this.overshoot);

  final double overshoot;

  @override
  double transformInternal(double t) {
    final shifted = t - 1.0;
    return 1.0 +
        (overshoot + 1.0) * shifted * shifted * shifted +
        overshoot * shifted * shifted;
  }
}

class _CanvasMotionPreset {
  const _CanvasMotionPreset({
    required this.nodeDuration,
    required this.viewportDuration,
    required this.highlightDuration,
    required this.nodeCurve,
    required this.viewportCurve,
    required this.highlightCurve,
    required this.highlightScale,
    required this.graphAnimationEnabled,
  });

  final Duration nodeDuration;
  final Duration viewportDuration;
  final Duration highlightDuration;
  final Curve nodeCurve;
  final Curve viewportCurve;
  final Curve highlightCurve;
  final double highlightScale;
  final bool graphAnimationEnabled;

  static const _CanvasMotionPreset organic = _CanvasMotionPreset(
    nodeDuration: Duration(milliseconds: 280),
    viewportDuration: Duration(milliseconds: 420),
    highlightDuration: Duration(milliseconds: 200),
    nodeCurve: _CanvasOrganicCurve(1.0),
    viewportCurve: _CanvasOrganicCurve(0.9),
    highlightCurve: _CanvasOrganicCurve(1.0),
    highlightScale: 1.04,
    graphAnimationEnabled: true,
  );

  static const _CanvasMotionPreset reduced = _CanvasMotionPreset(
    nodeDuration: Duration.zero,
    viewportDuration: Duration.zero,
    highlightDuration: Duration.zero,
    nodeCurve: Curves.linear,
    viewportCurve: Curves.linear,
    highlightCurve: Curves.linear,
    highlightScale: 1.0,
    graphAnimationEnabled: false,
  );
}

/// GraphView-based canvas used to render and edit automatons.
