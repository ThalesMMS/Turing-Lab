import 'package:flutter/material.dart';

import '../../core/models/fsa.dart';
import '../../features/canvas/graphview/graphview_canvas_controller.dart';
import '../../features/canvas/graphview/turing_lab_adaptive_edge_renderer.dart';
import '../providers/automaton_state_provider.dart';
import 'automaton_graphview_canvas.dart';

class ReadOnlyFsaGraphViewCanvas extends StatefulWidget {
  const ReadOnlyFsaGraphViewCanvas({
    super.key,
    required this.automaton,
    required this.canvasKey,
    this.edgeRenderMode = TuringLabEdgeRenderMode.standard,
  });

  final FSA automaton;
  final GlobalKey canvasKey;
  final TuringLabEdgeRenderMode edgeRenderMode;

  @override
  State<ReadOnlyFsaGraphViewCanvas> createState() =>
      _ReadOnlyFsaGraphViewCanvasState();
}

class _ReadOnlyFsaGraphViewCanvasState
    extends State<ReadOnlyFsaGraphViewCanvas> {
  late final AutomatonStateNotifier _automatonStateNotifier;
  late final GraphViewCanvasController _controller;

  @override
  void initState() {
    super.initState();
    _automatonStateNotifier = AutomatonStateNotifier()
      ..updateAutomaton(widget.automaton);
    _controller = GraphViewCanvasController(
      automatonStateNotifier: _automatonStateNotifier,
    );
  }

  @override
  void didUpdateWidget(covariant ReadOnlyFsaGraphViewCanvas oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!identical(oldWidget.automaton, widget.automaton)) {
      _automatonStateNotifier.updateAutomaton(widget.automaton);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    _automatonStateNotifier.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AutomatonGraphViewCanvas(
      automaton: widget.automaton,
      canvasKey: widget.canvasKey,
      controller: _controller,
      customization: AutomatonGraphViewCanvasCustomization.readOnly(
        edgeRenderMode: widget.edgeRenderMode,
      ),
    );
  }
}
