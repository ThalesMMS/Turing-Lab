//
//  pda_page.dart
//  Turing Lab
//
//  Hosts the Pushdown Automata page, integrating a GraphView canvas with
//  simulation and algorithm panels, and tracking metrics and changes to
//  keep state in sync across controllers, providers, and mobile or
//  desktop devices.
//
//  Thales Matheus Mendonça Santos - October 2025
//
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/models/pda.dart';
import '../../core/constants/help_topic_ids.dart';
import '../../core/models/simulation_highlight.dart';
import '../../core/models/simulation_step.dart';
import '../../core/services/canvas_highlight_coordinator.dart';
import '../../l10n/app_localizations_resolver.dart';
import '../providers/pda_editor_provider.dart';
import '../widgets/automaton_workspace_scaffold.dart';
import '../widgets/graphview_canvas_toolbar.dart';
import '../widgets/automaton_canvas_tool.dart';
import '../providers/workspace_quick_actions_provider.dart';
import '../widgets/canvas_simulation_playback_bar.dart';
import '../widgets/canvas_simulation_step_projection.dart';
import '../widgets/collapsible_canvas_panel.dart';
import '../widgets/pda_canvas_graphview.dart';
import '../widgets/pda_algorithm_panel.dart';
import '../widgets/pda_simulation_panel.dart';
import '../widgets/pda/stack_drawer.dart';
import '../widgets/common/workspace_helpers.dart';
import '../widgets/common/workspace_help.dart';

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
  ProviderSubscription<PDAEditorState>? _pdaEditorSub;
  StackState _currentStack = const StackState.empty();
  bool _isSimulating = false;
  bool _canvasPlaybackSupported = false;
  List<SimulationStep>? _canvasSimulationSteps;
  EdgeInsets _canvasToolbarInsets = EdgeInsets.zero;
  late final GraphViewPdaCanvasController _canvasController;
  late final CanvasHighlightCoordinator _highlightCoordinator;
  late final CanvasHighlightSourceHandle _validationHighlights;
  late final CanvasHighlightSourceHandle _simulationHighlights;
  late final SimulationHighlightService _highlightService;
  late final AutomatonCanvasToolController _toolController;
  late final List<Override> _canvasHighlightOverrides;
  late final Listenable _canvasListenable;
  int _highlightRevision = 0;
  int _highlightSyncGeneration = 0;

  @override
  void initState() {
    super.initState();
    _canvasController = GraphViewPdaCanvasController(
      editorNotifier: ref.read(pdaEditorProvider.notifier),
    );
    final initialEditorState = ref.read(pdaEditorProvider);
    _canvasController.synchronize(initialEditorState.pda);
    _highlightCoordinator = CanvasHighlightCoordinator(
      target: _highlightTarget(initialEditorState.pda),
      output: GraphViewSimulationHighlightChannel(_canvasController),
    );
    _validationHighlights =
        _highlightCoordinator.source(CanvasHighlightSource.validation);
    _simulationHighlights =
        _highlightCoordinator.source(CanvasHighlightSource.simulation);
    _highlightService = SimulationHighlightService(
      channel: _simulationHighlights,
    );
    _scheduleEditorHighlights(initialEditorState);
    _toolController = AutomatonCanvasToolController(
      AutomatonCanvasTool.selection,
    );
    _canvasHighlightOverrides = [
      canvasHighlightServiceProvider.overrideWithValue(_highlightService),
      canvasHighlightCoordinatorProvider.overrideWithValue(
        _highlightCoordinator,
      ),
    ];
    _canvasListenable = Listenable.merge([
      _toolController,
      _canvasController.graphRevision,
    ]);
    _pdaEditorSub = ref.listenManual<PDAEditorState>(pdaEditorProvider, (
      previous,
      next,
    ) {
      if (!mounted) return;
      if (!identical(previous?.pda, next.pda)) {
        _highlightRevision++;
        _highlightCoordinator.retarget(_highlightTarget(next.pda));
        if (_canvasSimulationSteps != null) {
          _stopCanvasSimulation();
          _handleStackChanged(const StackState.empty());
          final simulationNotifier = ref.read(pdaSimulationProvider.notifier);
          if (next.pda case final pda?) {
            simulationNotifier.setPda(pda);
          } else {
            simulationNotifier.clear();
          }
        }
      }
      _scheduleEditorHighlights(next);
      if (next.pda == null && _latestPda != null) {
        setState(() {
          _latestPda = null;
        });
      }
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final isSupported = supportsCanvasSimulationPlayback(context);
    if (_canvasPlaybackSupported &&
        !isSupported &&
        _canvasSimulationSteps != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted && !supportsCanvasSimulationPlayback(context)) {
          _stopCanvasSimulation();
        }
      });
    }
    _canvasPlaybackSupported = isSupported;
  }

  void _handleAddStatePressed() {
    if (_toolController.activeTool != AutomatonCanvasTool.addState) {
      _toolController.setActiveTool(AutomatonCanvasTool.addState);
    }
    _canvasController.addStateAtCenter();
  }

  void _handleCanvasToolbarInsetsChanged(EdgeInsets insets) {
    if (!mounted || _canvasToolbarInsets == insets) return;
    setState(() {
      _canvasToolbarInsets = insets;
    });
  }

  @override
  void dispose() {
    _pdaEditorSub?.close();
    _highlightService.clear();
    _validationHighlights.dispose();
    _simulationHighlights.dispose();
    _highlightCoordinator.dispose();
    _canvasController.dispose();
    _toolController.dispose();
    super.dispose();
  }

  void _handlePdaModified(PDA pda) {
    setState(() {
      _latestPda = pda;
    });
  }

  void _handleStackChanged(StackState stackState) {
    if (!mounted) return;
    setState(() {
      _currentStack = stackState;
    });
  }

  void _clearCanvasPda() {
    _stopCanvasSimulation();
    _canvasController.clearCanvas();
    setState(() {
      _currentStack = const StackState.empty();
      _isSimulating = false;
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
    final editorState = ref.read(pdaEditorProvider);
    final pda = editorState.pda;

    String topicId;
    if (pda == null || pda.states.isEmpty) {
      topicId = HelpTopicIds.pdaEditorOverview;
    } else if (_isSimulating || _currentStack.symbols.isNotEmpty) {
      topicId = HelpTopicIds.pdaEditorSimulation;
    } else {
      topicId = HelpTopicIds.pdaTheoryPda;
    }

    showWorkspaceHelp(
      context: context,
      topicId: topicId,
    );
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final editorState = ref.watch(pdaEditorProvider);
    final pda = editorState.pda;

    return ProviderScope(
      overrides: _canvasHighlightOverrides,
      child: AutomatonWorkspaceScaffold(
        canvasWithToolbar: _buildCanvasWithToolbar,
        algorithmPanel: PDAAlgorithmPanel(
          useExpanded: false,
          onApplyPda: _canvasController.replacePda,
        ),
        simulationPanel: PDASimulationPanel(
          highlightService: _highlightService,
          onStackChanged: _handleStackChanged,
          onSimulationStart: _handleSimulationStart,
          onSimulationEnd: _handleSimulationEnd,
        ),
        mobileFloatingPanelBuilder: (
          context, {
          required onDragDelta,
          required onPanelSizeChanged,
        }) =>
            CollapsibleCanvasPanel(
          label: appLocalizationsOf(context).pdaStackPanelLabel,
          icon: Icons.layers,
          onDragDelta: onDragDelta,
          onPanelSizeChanged: onPanelSizeChanged,
          child: PDAStackPanel(
            stackState: _currentStack,
            initialStackSymbol: pda?.initialStackSymbol ?? 'Z',
            stackAlphabet: pda?.stackAlphabet ?? const <String>{},
            isSimulating: _isSimulating,
            highlightedIndex: _inferHighlightedStackIndex(),
            onClear: () {
              setState(() {
                _currentStack = const StackState.empty();
              });
            },
          ),
        ),
      ),
    );
  }

  CanvasHighlightTarget _highlightTarget(PDA? pda) {
    return CanvasHighlightTarget(
      kind: AutomatonSurfaceKind.pda,
      surface: _canvasController,
      documentId: pda?.id,
      revision: _highlightRevision,
    );
  }

  void _scheduleEditorHighlights(PDAEditorState editorState) {
    final generation = ++_highlightSyncGeneration;
    final target = _highlightCoordinator.target;
    final highlight = SimulationHighlight(
      transitionIds: editorState.nondeterministicTransitionIds,
    );
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted ||
          generation != _highlightSyncGeneration ||
          target != _highlightCoordinator.target) {
        return;
      }
      _validationHighlights.sendFor(target, highlight);
    });
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
        // Modal routes are built by the Navigator, above this page's
        // ProviderScope, so the canvas highlight overrides have to be repeated
        // here or panels inside the sheet resolve the null root coordinator.
        return ProviderScope(
          overrides: _canvasHighlightOverrides,
          child: DraggableScrollableSheet(
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
                          color:
                              theme.colorScheme.outline.withValues(alpha: 0.4),
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
          ),
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
      currentStack: _currentStack,
      onPdaModified: _handlePdaModified,
    );

    publishWorkspaceQuickActions(
      ref,
      WorkspaceTab.pda,
      WorkspaceQuickActions(
        onHelp: _showContextualHelp,
        onSimulate: _openSimulationSheet,
        onAlgorithms: _openAlgorithmSheet,
        simulateEnabled: hasPda,
      ),
    );

    if (isMobile) {
      return Stack(
        children: [
          Positioned.fill(child: canvas),
          if (_canvasSimulationSteps case final steps?)
            Positioned(
              left: 16,
              right: 16,
              bottom: _canvasToolbarInsets.bottom + 16,
              child: CanvasSimulationPlaybackBar(
                key: ValueKey(steps),
                stepCount: steps.length,
                words: projectInputWordSteps(steps),
                onStepChanged: _handleCanvasSimulationStep,
                onClose: _stopCanvasSimulation,
              ),
            ),
          AnimatedBuilder(
            animation: _canvasListenable,
            builder: (context, _) {
              return GraphViewCanvasToolbar(
                controller: _canvasController,
                placement: CanvasToolbarPlacement.bottomCenter,
                onViewportInsetsChanged: _handleCanvasToolbarInsetsChanged,
                enableToolSelection: true,
                showSelectionTool: true,
                activeTool: _toolController.activeTool,
                onSelectTool: () => _toolController.setActiveTool(
                  AutomatonCanvasTool.selection,
                ),
                onAddState: _handleAddStatePressed,
                onAddTransition: () => _toolController.toggleTool(
                  AutomatonCanvasTool.transition,
                ),
                onHelp: _showContextualHelp,
                onClear: _clearCanvasPda,
                statusMessage: statusMessage,
              );
            },
          ),
        ],
      );
    }

    final canvasWithChrome = Stack(
      children: [
        Positioned.fill(child: canvas),
        AnimatedBuilder(
          animation: _canvasListenable,
          builder: (context, _) {
            return GraphViewCanvasToolbar(
              controller: _canvasController,
              onViewportInsetsChanged: _handleCanvasToolbarInsetsChanged,
              enableToolSelection: true,
              showSelectionTool: true,
              activeTool: _toolController.activeTool,
              onSelectTool: () =>
                  _toolController.setActiveTool(AutomatonCanvasTool.selection),
              onAddState: _handleAddStatePressed,
              onHelp: _showContextualHelp,
              onAddTransition: () =>
                  _toolController.toggleTool(AutomatonCanvasTool.transition),
              onClear: _clearCanvasPda,
              statusMessage: statusMessage,
            );
          },
        ),
      ],
    );
    final inspector = PDAStackPanel(
      stackState: _currentStack,
      initialStackSymbol: editorState.pda?.initialStackSymbol ?? 'Z',
      stackAlphabet: editorState.pda?.stackAlphabet ?? const {},
      isSimulating: _isSimulating,
      highlightedIndex: _inferHighlightedStackIndex(),
      onClear: () {
        setState(() {
          _currentStack = const StackState.empty();
        });
      },
    );

    return Column(
      children: [
        Expanded(child: canvasWithChrome),
        Padding(
          padding: const EdgeInsets.fromLTRB(0, 8, 0, 16),
          child: inspector,
        ),
      ],
    );
  }

  void _openSimulationSheet() {
    _stopCanvasSimulation();
    _showPanelSheet(
      context: context,
      title: 'PDA Simulation',
      icon: Icons.play_arrow,
      child: PDASimulationPanel(
        highlightService: _highlightService,
        onStackChanged: _handleStackChanged,
        onSimulationStart: _handleSimulationStart,
        onSimulationEnd: _handleSimulationEnd,
        onViewOnCanvas: supportsCanvasSimulationPlayback(context)
            ? _startCanvasSimulation
            : null,
      ),
    );
  }

  void _openAlgorithmSheet() {
    _showPanelSheet(
      context: context,
      title: 'PDA Algorithms',
      icon: Icons.auto_awesome,
      child: PDAAlgorithmPanel(
        onApplyPda: _canvasController.replacePda,
      ),
    );
  }

  void _startCanvasSimulation(List<SimulationStep> steps) {
    if (steps.isEmpty || !supportsCanvasSimulationPlayback(context)) return;
    final recordedSteps = List<SimulationStep>.unmodifiable(steps);
    setState(() {
      _canvasSimulationSteps = recordedSteps;
      _isSimulating = true;
    });
    _handleCanvasSimulationStep(0);
    Navigator.of(context).pop();
  }

  void _handleCanvasSimulationStep(int stepIndex) {
    final steps = _canvasSimulationSteps;
    if (steps == null || stepIndex < 0 || stepIndex >= steps.length) return;
    ref.read(pdaSimulationProvider.notifier).goToStep(stepIndex);
    _highlightService.emitFromSteps(steps, stepIndex);
    _handleStackChanged(projectPdaStackStep(steps[stepIndex]));
  }

  void _stopCanvasSimulation() {
    if (_canvasSimulationSteps != null && mounted) {
      setState(() {
        _canvasSimulationSteps = null;
        _isSimulating = false;
      });
    }
    _highlightService.clear();
  }

  String _buildToolbarStatusMessage(PDAEditorState editorState) {
    final pda = editorState.pda;
    return buildAutomatonWorkspaceStatus(
      l10n: appLocalizationsOf(context),
      stateCount: pda?.states.length ?? 0,
      transitionCount: pda?.pdaTransitions.length ?? 0,
      hasInitialState: pda?.initialState != null,
      hasAcceptingState: pda?.acceptingStates.isNotEmpty ?? false,
      hasNondeterministicTransitions:
          editorState.nondeterministicTransitionIds.isNotEmpty,
      hasLambdaTransitions: editorState.lambdaTransitionIds.isNotEmpty,
    );
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
