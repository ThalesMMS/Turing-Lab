//
//  pda_page.dart
//  Turing Lab
//
//  Administra a página de Autômatos de Pilha integrando canvas GraphView,
//  painéis de simulação e algoritmos, monitorando métricas e mudanças para
//  manter o estado sincronizado entre controladores, provedores e dispositivos
//  móveis ou desktop.
//
//  Thales Matheus Mendonça Santos - October 2025
//
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/models/pda.dart';
import '../../core/models/pda_transition.dart';
import '../../core/models/state.dart' as automaton_state;
import '../providers/help_provider.dart';
import '../providers/pda_editor_provider.dart';
import '../widgets/app_snackbar.dart';
import '../widgets/automaton_workspace_scaffold.dart';
import '../widgets/context_aware_help_panel.dart';
import '../widgets/graphview_canvas_toolbar.dart';
import '../widgets/automaton_canvas_tool.dart';
import '../widgets/canvas_quick_actions.dart';
import '../widgets/mobile_automaton_controls.dart';
import '../widgets/pda_canvas_graphview.dart';
import '../widgets/pda_algorithm_panel.dart';
import '../widgets/pda_simulation_panel.dart';
import '../widgets/pda/stack_drawer.dart';
import '../widgets/common/workspace_helpers.dart';

import '../../core/models/step_explanation.dart';
import '../providers/pda_simulation_provider.dart';
import '../../core/services/simulation_highlight_service.dart';
import '../../features/canvas/graphview/graphview_highlight_channel.dart';
import '../../features/canvas/graphview/graphview_pda_canvas_controller.dart';

/// Page for working with Pushdown Automata
class PDAPage extends ConsumerStatefulWidget {
  const PDAPage({super.key});

  @override
  ConsumerState<PDAPage> createState() => _PDAPageState();
}

class _PDAPageState extends ConsumerState<PDAPage>
    with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;

  PDA? _latestPda;
  bool _hasUnsavedChanges = false;
  ProviderSubscription<PDAEditorState>? _pdaEditorSub;
  StackState _currentStack = const StackState.empty();
  bool _isSimulating = false;
  late final GraphViewPdaCanvasController _canvasController;
  late final GraphViewSimulationHighlightChannel _highlightChannel;
  late final SimulationHighlightService _highlightService;
  late final AutomatonCanvasToolController _toolController;
  AutomatonCanvasTool _activeTool = AutomatonCanvasTool.selection;

  @override
  void initState() {
    super.initState();
    _canvasController = GraphViewPdaCanvasController(
      editorNotifier: ref.read(pdaEditorProvider.notifier),
    );
    _canvasController.synchronize(ref.read(pdaEditorProvider).pda);
    _highlightChannel = GraphViewSimulationHighlightChannel(_canvasController);
    _highlightService = SimulationHighlightService(channel: _highlightChannel);
    _toolController = AutomatonCanvasToolController();
    _toolController.addListener(_handleToolChanged);
    _pdaEditorSub = ref.listenManual<PDAEditorState>(pdaEditorProvider, (
      previous,
      next,
    ) {
      if (!mounted) return;
      if (next.pda == null && _latestPda != null) {
        setState(() {
          _latestPda = null;
          _hasUnsavedChanges = false;
        });
      }
    });
  }

  void _handleToolChanged() {
    if (!mounted) {
      return;
    }
    setState(() {
      _activeTool = _toolController.activeTool;
    });
  }

  void _handleAddStatePressed() {
    if (_toolController.activeTool != AutomatonCanvasTool.addState) {
      _toolController.setActiveTool(AutomatonCanvasTool.addState);
    }
    _canvasController.addStateAtCenter();
  }

  @override
  void dispose() {
    _pdaEditorSub?.close();
    _toolController.removeListener(_handleToolChanged);
    _toolController.dispose();
    _highlightService.clear();
    _canvasController.dispose();
    super.dispose();
  }

  void _handlePdaModified(PDA pda) {
    setState(() {
      _latestPda = pda;
      _hasUnsavedChanges = true;
    });
  }

  void _handleStackChanged(StackState stackState) {
    if (!mounted) return;
    setState(() {
      _currentStack = stackState;
    });
  }

  void _handleSimulationStart() {
    if (!mounted) return;
    setState(() {
      _isSimulating = true;
    });
  }

  void _handleSimulationEnd() {
    if (!mounted) return;
    setState(() {
      _isSimulating = false;
    });
  }

  void _showContextualHelp() {
    final helpNotifier = ref.read(helpProvider.notifier);
    final editorState = ref.read(pdaEditorProvider);
    final pda = editorState.pda;

    // Determine the most relevant help content based on current PDA state
    String helpContextId;
    if (pda == null || pda.states.isEmpty) {
      helpContextId = 'usage_getting_started';
    } else if (_isSimulating || _currentStack.symbols.isNotEmpty) {
      helpContextId = 'concept_stack';
    } else {
      helpContextId = 'concept_pda';
    }

    final helpContent = helpNotifier.getHelpByContext(helpContextId);
    if (helpContent != null) {
      ContextAwareHelpPanel.show(context, helpContent: helpContent);
    } else {
      showAppSnackBar(
        context,
        message: 'Help content is not available right now.',
        tone: AppSnackBarTone.error,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final editorState = ref.watch(pdaEditorProvider);
    final pda = editorState.pda;

    return ProviderScope(
      overrides: [
        canvasHighlightServiceProvider.overrideWithValue(_highlightService),
      ],
      child: AutomatonWorkspaceScaffold(
        canvasWithToolbar: _buildCanvasWithToolbar,
        algorithmPanel: const PDAAlgorithmPanel(),
        tabletAlgorithmPanel: const PDAAlgorithmPanel(useExpanded: false),
        simulationPanel: PDASimulationPanel(
          highlightService: _highlightService,
          onStackChanged: _handleStackChanged,
          onSimulationStart: _handleSimulationStart,
          onSimulationEnd: _handleSimulationEnd,
        ),
        mobileFloatingPanel: pda == null
            ? null
            : PDAStackPanel(
                stackState: _currentStack,
                initialStackSymbol: pda.initialStackSymbol,
                stackAlphabet: pda.stackAlphabet,
                isSimulating: _isSimulating,
                highlightedIndex: _inferHighlightedStackIndex(),
                onClear: () {
                  setState(() {
                    _currentStack = const StackState.empty();
                  });
                },
              ),
        floatingActionButton: FloatingActionButton(
          heroTag: 'pda_context_help_fab',
          onPressed: _showContextualHelp,
          tooltip: 'Context-Aware Help',
          child: const Icon(Icons.help_outline),
        ),
      ),
    );
  }

  Future<void> _showPanelSheet({
    required BuildContext context,
    required String title,
    required Widget child,
    IconData? icon,
  }) async {
    final theme = Theme.of(context);

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) {
        return DraggableScrollableSheet(
          expand: false,
          initialChildSize: 0.7,
          minChildSize: 0.4,
          maxChildSize: 0.95,
          builder: (context, scrollController) {
            return SafeArea(
              top: false,
              child: Container(
                decoration: BoxDecoration(
                  color: theme.colorScheme.surface,
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(24),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.1),
                      blurRadius: 12,
                      offset: const Offset(0, -4),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    const SizedBox(height: 12),
                    Container(
                      width: 36,
                      height: 4,
                      decoration: BoxDecoration(
                        color: theme.colorScheme.outline.withValues(alpha: 0.4),
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 16, 8, 12),
                      child: Row(
                        children: [
                          if (icon != null) ...[
                            Icon(icon, color: theme.colorScheme.primary),
                            const SizedBox(width: 12),
                          ],
                          Expanded(
                            child: Text(
                              title,
                              style: theme.textTheme.titleLarge?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.close),
                            onPressed: () => Navigator.of(sheetContext).pop(),
                          ),
                        ],
                      ),
                    ),
                    const Divider(height: 1),
                    Expanded(
                      child: ListView(
                        controller: scrollController,
                        padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
                        children: [child],
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildCanvasWithToolbar({required bool isMobile}) {
    final editorState = ref.watch(pdaEditorProvider);
    final statusMessage = _buildToolbarStatusMessage(editorState);
    final hasPda =
        editorState.pda != null && editorState.pda!.states.isNotEmpty;
    final canvas = PDACanvasGraphView(
      controller: _canvasController,
      toolController: _toolController,
      onPdaModified: _handlePdaModified,
    );

    final combinedListenable = _canvasController.graphRevision;

    final onHelp = _showContextualHelp;
    final onSimulate = hasPda
        ? () => _showPanelSheet(
              context: context,
              title: 'PDA Simulation',
              icon: Icons.play_arrow,
              child: PDASimulationPanel(
                highlightService: _highlightService,
                onStackChanged: _handleStackChanged,
                onSimulationStart: _handleSimulationStart,
                onSimulationEnd: _handleSimulationEnd,
              ),
            )
        : null;
    final onAlgorithms = hasPda
        ? () => _showPanelSheet(
              context: context,
              title: 'PDA Algorithms',
              icon: Icons.auto_awesome,
              child: const PDAAlgorithmPanel(),
            )
        : null;

    if (isMobile) {
      return Stack(
        children: [
          Positioned.fill(child: canvas),
          if (onSimulate != null || onAlgorithms != null)
            Positioned(
              top: 16,
              left: 16,
              child: CanvasQuickActions(
                onHelp: onHelp,
                onSimulate: onSimulate,
                onAlgorithms: onAlgorithms,
              ),
            ),
          AnimatedBuilder(
            animation: combinedListenable,
            builder: (context, _) {
              return MobileAutomatonControls(
                enableToolSelection: true,
                showSelectionTool: true,
                activeTool: _activeTool,
                onSelectTool: () => _toolController.setActiveTool(
                  AutomatonCanvasTool.selection,
                ),
                onAddState: _handleAddStatePressed,
                onAddTransition: () => _toolController.setActiveTool(
                  AutomatonCanvasTool.transition,
                ),
                onFitToContent: _canvasController.fitToContent,
                onResetView: _canvasController.resetView,
                onClear: () =>
                    ref.read(pdaEditorProvider.notifier).updateFromCanvas(
                  states: const <automaton_state.State>[],
                  transitions: const <PDATransition>[],
                ),
                onUndo: _canvasController.undo,
                onRedo: _canvasController.redo,
                canUndo: _canvasController.canUndo,
                canRedo: _canvasController.canRedo,
                onSimulate: null,
                isSimulationEnabled: false,
                onAlgorithms: null,
                isAlgorithmsEnabled: false,
                statusMessage: statusMessage,
              );
            },
          ),
        ],
      );
    }

    return Stack(
      children: [
        Positioned.fill(child: canvas),
        AnimatedBuilder(
          animation: combinedListenable,
          builder: (context, _) {
            return GraphViewCanvasToolbar(
              layout: GraphViewCanvasToolbarLayout.desktop,
              controller: _canvasController,
              enableToolSelection: true,
              showSelectionTool: true,
              activeTool: _activeTool,
              onSelectTool: () =>
                  _toolController.setActiveTool(AutomatonCanvasTool.selection),
              onAddState: _handleAddStatePressed,
              onAddTransition: () =>
                  _toolController.setActiveTool(AutomatonCanvasTool.transition),
              onClear: () =>
                  ref.read(pdaEditorProvider.notifier).updateFromCanvas(
                states: const <automaton_state.State>[],
                transitions: const <PDATransition>[],
              ),
              statusMessage: statusMessage,
            );
          },
        ),
        Positioned(
          bottom: 16,
          right: 16,
          child: PDAStackPanel(
            stackState: _currentStack,
            initialStackSymbol:
                ref.read(pdaEditorProvider).pda?.initialStackSymbol ?? 'Z',
            stackAlphabet:
                ref.read(pdaEditorProvider).pda?.stackAlphabet ?? const {},
            isSimulating: _isSimulating,
            highlightedIndex: _inferHighlightedStackIndex(),
            onClear: () {
              setState(() {
                _currentStack = const StackState.empty();
              });
            },
          ),
        ),
      ],
    );
  }

  String _buildToolbarStatusMessage(PDAEditorState editorState) {
    final pda = editorState.pda;
    final hasPda = pda != null && pda.states.isNotEmpty;
    final stateCount = pda?.states.length ?? 0;
    final transitionCount = pda?.pdaTransitions.length ?? 0;

    final messageParts = <String>[];

    if (_hasUnsavedChanges) {
      messageParts.add('Unsaved changes');
    }

    final warnings = <String>[];
    if (editorState.nondeterministicTransitionIds.isNotEmpty) {
      warnings.add('Nondeterministic transitions');
    }
    if (editorState.lambdaTransitionIds.isNotEmpty) {
      warnings.add('λ-transitions present');
    }

    if (warnings.isNotEmpty) {
      messageParts.add('⚠ ${warnings.join(' · ')}');
    }

    if (hasPda) {
      messageParts.add(
        '${formatCount('state', 'states', stateCount)} · '
        '${formatCount('transition', 'transitions', transitionCount)}',
      );
    } else {
      messageParts.add('No PDA loaded');
    }

    return messageParts.join(' · ');
  }

  int? _inferHighlightedStackIndex() {
    final step = ref.watch(pdaSimulationProvider).currentStep;
    final explanation = step?.explanation;
    if (explanation == null) return null;

    for (final highlight in explanation.highlights) {
      if (highlight.type != HighlightTargetType.pdaStack) continue;
      final data = highlight.data;
      if (data.isEmpty) return null;
      final index = data['index'];
      if (index is int) return index;
    }

    return null;
  }
}
