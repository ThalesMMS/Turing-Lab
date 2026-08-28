part of 'graphview_canvas_toolbar.dart';

/// Shared canvas toolbar for FSA, PDA, TM, Mealy, and Moore editors.
class GraphViewCanvasToolbar extends StatefulWidget {
  const GraphViewCanvasToolbar({
    super.key,
    required this.controller,
    this.placement = CanvasToolbarPlacement.topRight,
    this.onViewportInsetsChanged,
    this.enableToolSelection = false,
    this.showSelectionTool = false,
    this.activeTool = AutomatonCanvasTool.selection,
    this.onSelectTool,
    required this.onAddState,
    this.onAddTransition,
    this.onManageBlocks,
    this.onArrangeAutomaton,
    this.onImportAutomaton,
    this.onDocumentNotes,
    this.documentActionsEnabled = true,
    this.onHelp,
    this.onClear,
    this.statusMessage,
  }) : assert(
         !(enableToolSelection && showSelectionTool) || onSelectTool != null,
         'onSelectTool must be provided when the selection tool is visible.',
       ),
       assert(
         !enableToolSelection || onAddTransition != null,
         'onAddTransition must be provided when tool selection is enabled.',
       );

  final BaseGraphViewCanvasController<dynamic, dynamic> controller;
  final CanvasToolbarPlacement placement;
  final ValueChanged<EdgeInsets>? onViewportInsetsChanged;
  final bool enableToolSelection;
  final bool showSelectionTool;
  final AutomatonCanvasTool activeTool;
  final VoidCallback? onSelectTool;
  final VoidCallback onAddState;
  final VoidCallback? onAddTransition;
  final VoidCallback? onManageBlocks;
  final VoidCallback? onArrangeAutomaton;
  final VoidCallback? onImportAutomaton;
  final VoidCallback? onDocumentNotes;
  final bool documentActionsEnabled;
  final VoidCallback? onHelp;
  final VoidCallback? onClear;
  final String? statusMessage;

  @override
  State<GraphViewCanvasToolbar> createState() => _GraphViewCanvasToolbarState();
}
