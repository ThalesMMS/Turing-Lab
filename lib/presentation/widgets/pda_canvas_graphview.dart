//
//  pda_canvas_graphview.dart
//  Turing Lab
//
//  Implements the specialized PDA canvas on the shared GraphView
//  infrastructure, syncing providers and highlights. Owns the controller
//  lifecycle, wires the highlight channel, and emits callbacks whenever
//  the automaton changes.
//
//  Thales Matheus Mendonça Santos - October 2025
//

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/models/pda.dart';
import '../../core/services/highlight_channel.dart';
import '../../core/services/simulation_highlight_service.dart';
import '../../features/canvas/graphview/graphview_highlight_channel.dart';
import '../../features/canvas/graphview/graphview_pda_canvas_controller.dart';
import '../providers/pda_editor_provider.dart';
import 'automaton_canvas_tool.dart';
import 'automaton_graphview_canvas.dart';
import 'pda/stack_drawer.dart';

class PDACanvasGraphView extends ConsumerStatefulWidget {
  const PDACanvasGraphView({
    super.key,
    required this.onPdaModified,
    this.controller,
    this.toolController,
    this.currentStack,
  });

  final ValueChanged<PDA> onPdaModified;
  final GraphViewPdaCanvasController? controller;
  final AutomatonCanvasToolController? toolController;
  final StackState? currentStack;

  @override
  ConsumerState<PDACanvasGraphView> createState() => _PDACanvasGraphViewState();
}

class _PDACanvasGraphViewState extends ConsumerState<PDACanvasGraphView> {
  final GlobalKey _canvasKey = GlobalKey();
  late GraphViewPdaCanvasController _controller;
  late bool _ownsController;
  SimulationHighlightService? _highlightService;
  HighlightChannel? _previousHighlightChannel;
  ProviderSubscription<PDAEditorState>? _subscription;
  PDA? _lastDeliveredPda;
  StackState? _customizationStack;
  AutomatonGraphViewCanvasCustomization? _cachedCustomization;

  AutomatonGraphViewCanvasCustomization get _customization {
    if (_cachedCustomization == null ||
        _customizationStack != widget.currentStack) {
      _customizationStack = widget.currentStack;
      _cachedCustomization = AutomatonGraphViewCanvasCustomization.pda(
        currentStack: widget.currentStack,
      );
    }
    return _cachedCustomization!;
  }

  @override
  void initState() {
    super.initState();
    final externalController = widget.controller;
    if (externalController != null) {
      _controller = externalController;
      _ownsController = false;
    } else {
      _controller = GraphViewPdaCanvasController(
        editorNotifier: ref.read(pdaEditorProvider.notifier),
      );
      _ownsController = true;
      final highlightService = ref.read(canvasHighlightServiceProvider);
      _highlightService = highlightService;
      _previousHighlightChannel = highlightService.channel;
      final highlightChannel = GraphViewSimulationHighlightChannel(_controller);
      highlightService.channel = highlightChannel;
    }

    final initialState = ref.read(pdaEditorProvider);
    _controller.synchronize(initialState.pda);

    _lastDeliveredPda = initialState.pda;
    if (initialState.pda != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        widget.onPdaModified(initialState.pda!);
      });
    }

    _subscription = ref.listenManual<PDAEditorState>(pdaEditorProvider, (
      previous,
      next,
    ) {
      if (!mounted) return;
      final pda = next.pda;
      if (pda != null && !identical(pda, _lastDeliveredPda)) {
        _lastDeliveredPda = pda;
        widget.onPdaModified(pda);
      } else if (pda == null) {
        _lastDeliveredPda = null;
      }
    });
  }

  @override
  void dispose() {
    _subscription?.close();
    if (_ownsController) {
      _controller.dispose();
    }
    if (_highlightService != null) {
      _highlightService!.channel = _previousHighlightChannel;
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final editorState = ref.watch(pdaEditorProvider);
    return AutomatonGraphViewCanvas(
      automaton: editorState.pda,
      canvasKey: _canvasKey,
      controller: _controller,
      toolController: widget.toolController,
      customization: _customization,
    );
  }
}
