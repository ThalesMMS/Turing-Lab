//
//  tm_canvas_graphview.dart
//  Turing Lab
//
//  Widget that wraps the Turing-machine canvas on the shared automata
//  infrastructure, delegating gestures, highlights, and transition edits
//  to AutomatonGraphViewCanvas. The class connects the TM-specific
//  controller to Riverpod providers, exposes hooks to customize tools,
//  and enables inline forms for tape operations.
//
//  Thales Matheus Mendonça Santos - October 2025
//
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/formal_systems/formal_systems.dart';

import '../../core/models/tm.dart';
import '../../core/services/simulation_highlight_service.dart';
import '../../features/canvas/graphview/graphview_highlight_channel.dart';
import '../../features/canvas/graphview/graphview_tm_canvas_controller.dart';
import '../providers/tm_editor_provider.dart';
import 'automaton_canvas_tool.dart';
import 'automaton_canvas_document_actions.dart';
import 'automaton_graphview_canvas.dart';

class TMCanvasGraphView extends ConsumerStatefulWidget {
  const TMCanvasGraphView({
    super.key,
    required this.onTmModified,
    this.controller,
    this.toolController,
    this.documentActionsController,
  });

  final ValueChanged<TM> onTmModified;
  final GraphViewTmCanvasController? controller;
  final AutomatonCanvasToolController? toolController;
  final AutomatonCanvasDocumentActionsController? documentActionsController;

  @override
  ConsumerState<TMCanvasGraphView> createState() => _TMCanvasGraphViewState();
}

class _TMCanvasGraphViewState extends ConsumerState<TMCanvasGraphView> {
  final GlobalKey _canvasKey = GlobalKey();
  late GraphViewTmCanvasController _controller;
  late bool _ownsController;
  SimulationHighlightChannelRegistration? _highlightRegistration;
  ProviderSubscription<TMEditorState>? _subscription;
  TM? _lastDeliveredTm;

  late final AutomatonGraphViewCanvasCustomization _customization =
      AutomatonGraphViewCanvasCustomization.tm();

  @override
  void initState() {
    super.initState();
    final externalController = widget.controller;
    if (externalController != null) {
      _controller = externalController;
      _ownsController = false;
    } else {
      _controller = GraphViewTmCanvasController(
        editorNotifier: ref.read(tmEditorProvider.notifier),
      );
      _ownsController = true;
      final highlightService = ref.read(canvasHighlightServiceProvider);
      final highlightChannel = GraphViewSimulationHighlightChannel(_controller);
      _highlightRegistration = highlightService.registerChannel(
        highlightChannel,
      );
    }

    final initialState = ref.read(tmEditorProvider);
    _controller.synchronize(initialState.tm);

    _lastDeliveredTm = initialState.tm;
    if (initialState.tm != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        widget.onTmModified(initialState.tm!);
      });
    }

    _subscription = ref.listenManual<TMEditorState>(tmEditorProvider, (
      previous,
      next,
    ) {
      if (!mounted) return;
      final tm = next.tm;
      if (tm != null && !identical(tm, _lastDeliveredTm)) {
        _lastDeliveredTm = tm;
        widget.onTmModified(tm);
      } else if (tm == null) {
        _lastDeliveredTm = null;
      }
    });
  }

  @override
  void dispose() {
    _subscription?.close();
    _highlightRegistration?.dispose();
    if (_ownsController) {
      _controller.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(tmEditorProvider);
    return AutomatonGraphViewCanvas(
      automaton: state.tm,
      canvasKey: _canvasKey,
      controller: _controller,
      toolController: widget.toolController,
      customization: _customization,
      documentActionsController: widget.documentActionsController,
      annotationConfig: state.tm == null
          ? null
          : AutomatonCanvasAnnotationConfig(
              systemKey: DefaultFormalSystemIds.tm,
              documentId: state.tm!.id,
              documentRevision: '${state.documentGeneration}',
            ),
    );
  }
}
