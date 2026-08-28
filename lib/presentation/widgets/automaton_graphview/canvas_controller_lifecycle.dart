import 'package:flutter/foundation.dart';

import '../../../core/services/simulation_highlight_service.dart';
import '../../../features/canvas/graphview/base_graphview_canvas_controller.dart';
import '../../../features/canvas/graphview/graphview_highlight_channel.dart';
import '../automaton_canvas_tool.dart';

typedef CanvasControllerFactory
    = BaseGraphViewCanvasController<dynamic, dynamic> Function();

/// Owns the controller bindings used by one automaton canvas.
///
/// Ownership table:
///
/// | Resource | Supplied by caller | Created here |
/// | --- | --- | --- |
/// | Canvas controller | caller disposes | disposed on swap/teardown |
/// | Tool controller | caller disposes | disposed on swap/teardown |
/// | Transformation controller | canvas controller decides | canvas controller decides |
/// | GraphView attachment | GraphView attaches/detaches | GraphView attaches/detaches |
///
/// A canvas never disposes a caller-owned resource. Listener attachment to a
/// replacement happens before detachment from the old controller, so there is
/// no frame in which the canvas has no revision/highlight source.
class AutomatonGraphViewControllerLifecycle {
  AutomatonGraphViewControllerLifecycle({
    required BaseGraphViewCanvasController<dynamic, dynamic>?
        externalController,
    required AutomatonCanvasToolController? externalToolController,
    required CanvasControllerFactory createInternalController,
    required SimulationHighlightService Function() readHighlightService,
    required VoidCallback onGraphRevision,
    required VoidCallback onHighlight,
    required VoidCallback onToolChanged,
  })  : _createInternalController = createInternalController,
        _readHighlightService = readHighlightService,
        _onGraphRevision = onGraphRevision,
        _onHighlight = onHighlight,
        _onToolChanged = onToolChanged {
    final controllerBinding = _createControllerBinding(externalController);
    _controllerBinding = controllerBinding;
    _attachController(controllerBinding.controller);

    final toolBinding = _createToolBinding(externalToolController);
    _toolBinding = toolBinding;
    toolBinding.controller.addListener(_onToolChanged);
  }

  final CanvasControllerFactory _createInternalController;
  final SimulationHighlightService Function() _readHighlightService;
  final VoidCallback _onGraphRevision;
  final VoidCallback _onHighlight;
  final VoidCallback _onToolChanged;

  late _CanvasControllerBinding _controllerBinding;
  late _ToolControllerBinding _toolBinding;
  bool _disposed = false;

  BaseGraphViewCanvasController<dynamic, dynamic> get controller =>
      _controllerBinding.controller;

  AutomatonCanvasToolController get toolController => _toolBinding.controller;

  bool get ownsController => _controllerBinding.owned;

  bool get ownsToolController => _toolBinding.owned;

  bool replaceController(
    BaseGraphViewCanvasController<dynamic, dynamic>? externalController,
  ) {
    _assertActive();
    final current = _controllerBinding;
    if (externalController != null &&
        identical(current.controller, externalController)) {
      return false;
    }
    if (externalController == null && current.owned) {
      return false;
    }

    final next = _createControllerBinding(externalController);
    _attachController(next.controller);
    _controllerBinding = next;
    _releaseController(current);
    return true;
  }

  bool replaceToolController(
    AutomatonCanvasToolController? externalController,
  ) {
    _assertActive();
    final current = _toolBinding;
    if (externalController != null &&
        identical(current.controller, externalController)) {
      return false;
    }
    if (externalController == null && current.owned) {
      return false;
    }

    final next = _createToolBinding(externalController);
    next.controller.addListener(_onToolChanged);
    _toolBinding = next;
    current.controller.removeListener(_onToolChanged);
    if (current.owned) {
      current.controller.dispose();
    }
    return true;
  }

  void dispose() {
    if (_disposed) {
      return;
    }
    _disposed = true;
    _toolBinding.controller.removeListener(_onToolChanged);
    _detachController(_controllerBinding.controller);
    if (_toolBinding.owned) {
      _toolBinding.controller.dispose();
    }
    _unregisterHighlightChannel(_controllerBinding);
    if (_controllerBinding.owned) {
      _controllerBinding.controller.dispose();
    }
  }

  _CanvasControllerBinding _createControllerBinding(
    BaseGraphViewCanvasController<dynamic, dynamic>? externalController,
  ) {
    if (externalController != null) {
      return _CanvasControllerBinding(
        controller: externalController,
        owned: false,
      );
    }

    final controller = _createInternalController();
    final highlightRegistration = _readHighlightService().registerChannel(
      GraphViewSimulationHighlightChannel(controller),
    );
    return _CanvasControllerBinding(
      controller: controller,
      owned: true,
      highlightRegistration: highlightRegistration,
    );
  }

  _ToolControllerBinding _createToolBinding(
    AutomatonCanvasToolController? externalController,
  ) {
    return _ToolControllerBinding(
      controller: externalController ?? AutomatonCanvasToolController(),
      owned: externalController == null,
    );
  }

  void _attachController(
    BaseGraphViewCanvasController<dynamic, dynamic> controller,
  ) {
    controller.graphRevision.addListener(_onGraphRevision);
    controller.highlightNotifier.addListener(_onHighlight);
  }

  void _detachController(
    BaseGraphViewCanvasController<dynamic, dynamic> controller,
  ) {
    controller.graphRevision.removeListener(_onGraphRevision);
    controller.highlightNotifier.removeListener(_onHighlight);
  }

  void _releaseController(_CanvasControllerBinding binding) {
    _detachController(binding.controller);
    binding.highlightRegistration?.dispose();
    if (binding.owned) {
      binding.controller.dispose();
    }
  }

  void _unregisterHighlightChannel(_CanvasControllerBinding binding) {
    binding.highlightRegistration?.dispose();
  }

  void _assertActive() {
    assert(!_disposed, 'The canvas controller lifecycle is disposed.');
  }
}

class _CanvasControllerBinding {
  const _CanvasControllerBinding({
    required this.controller,
    required this.owned,
    this.highlightRegistration,
  });

  final BaseGraphViewCanvasController<dynamic, dynamic> controller;
  final bool owned;
  final SimulationHighlightChannelRegistration? highlightRegistration;
}

class _ToolControllerBinding {
  const _ToolControllerBinding({
    required this.controller,
    required this.owned,
  });

  final AutomatonCanvasToolController controller;
  final bool owned;
}
