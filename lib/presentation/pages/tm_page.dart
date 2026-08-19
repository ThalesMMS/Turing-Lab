//
//  tm_page.dart
//  Turing Lab
//
//  Garante o workspace de Máquinas de Turing com canvas GraphView, painéis de
//  simulação e algoritmos, acompanhando métricas, ferramentas e destaques para
//  preservar a coerência da máquina entre edições, simulações e layouts
//  responsivos.
//
//  Thales Matheus Mendonça Santos - October 2025
//
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/models/simulation_highlight.dart';
import '../../core/models/simulation_step.dart';
import '../../core/models/tm.dart';
import '../../core/models/tm_transition.dart';
import '../../core/services/canvas_highlight_coordinator.dart';
import '../../l10n/app_localizations_resolver.dart';
import '../widgets/automaton_workspace_scaffold.dart';
import '../providers/workspace_quick_actions_provider.dart';
import '../widgets/canvas_simulation_playback_bar.dart';
import '../widgets/canvas_simulation_step_projection.dart';
import '../widgets/collapsible_canvas_panel.dart';
import '../providers/tm_editor_provider.dart';
import '../widgets/tm_canvas_graphview.dart';
import '../widgets/tm_algorithm_panel.dart';
import '../widgets/tm_simulation_panel.dart';
import '../widgets/tm/tape_drawer.dart';
import '../widgets/common/workspace_helpers.dart';
import '../widgets/common/workspace_help.dart';
import '../widgets/graphview_canvas_toolbar.dart';
import '../widgets/automaton_canvas_tool.dart';
import '../widgets/mobile_automaton_controls.dart';
import '../../core/services/simulation_highlight_service.dart';
import '../../features/canvas/graphview/graphview_highlight_channel.dart';
import '../../features/canvas/graphview/graphview_tm_canvas_controller.dart';

/// Page for working with Turing Machines
class TMPage extends ConsumerStatefulWidget {
  const TMPage({super.key});

  @override
  ConsumerState<TMPage> createState() => _TMPageState();
}

class _TMPageState extends ConsumerState<TMPage>
    with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;

  TM? _currentTM;
  int _stateCount = 0;
  int _transitionCount = 0;
  Set<String> _tapeSymbols = const <String>{};
  Set<String> _moveDirections = const <String>{};
  Set<String> _nondeterministicTransitionIds = const <String>{};
  bool _hasInitialState = false;
  bool _hasAcceptingState = false;
  ProviderSubscription<TMEditorState>? _tmEditorSub;
  TapeState _currentTape = TapeState.initial();
  bool _canvasPlaybackSupported = false;
  List<SimulationStep>? _canvasSimulationSteps;
  late final GraphViewTmCanvasController _canvasController;
  late final CanvasHighlightCoordinator _highlightCoordinator;
  late final CanvasHighlightSourceHandle _validationHighlights;
  late final CanvasHighlightSourceHandle _simulationHighlights;
  late final SimulationHighlightService _highlightService;
  late final AutomatonCanvasToolController _toolController;
  late final Listenable _canvasListenable;
  int _highlightRevision = 0;
  int _highlightSyncGeneration = 0;

  bool get _isMachineReady =>
      _currentTM != null && _hasInitialState && _hasAcceptingState;

  bool get _hasMachine => _currentTM != null && _stateCount > 0;

  void _handleTapeChanged(TapeState tapeState) {
    if (!mounted) return;
    setState(() {
      _currentTape = tapeState;
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

  void _clearCanvasMachine() {
    _stopCanvasSimulation();
    final blankSymbol = ref.read(tmEditorProvider).tm?.blankSymbol ?? '□';
    _canvasController.clearCanvas();
    setState(() {
      _currentTape = TapeState.initial(blankSymbol: blankSymbol);
    });
  }

  @override
  void initState() {
    super.initState();
    final initialEditorState = ref.read(tmEditorProvider);
    _currentTape = TapeState.initial(
      blankSymbol: initialEditorState.tm?.blankSymbol ?? '□',
    );
    _canvasController = GraphViewTmCanvasController(
      editorNotifier: ref.read(tmEditorProvider.notifier),
    );
    _canvasController.synchronize(initialEditorState.tm);
    _highlightCoordinator = CanvasHighlightCoordinator(
      target: _highlightTarget(initialEditorState.tm),
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
    _toolController = AutomatonCanvasToolController();
    _canvasListenable = Listenable.merge([
      _toolController,
      _canvasController.graphRevision,
    ]);

    _tmEditorSub = ref.listenManual<TMEditorState>(tmEditorProvider, (
      previous,
      next,
    ) {
      if (!mounted) return;
      final tmChanged = !identical(previous?.tm, next.tm);
      final machineWasRemoved = next.tm == null && _currentTM != null;
      if (tmChanged) {
        _highlightRevision++;
        _highlightCoordinator.retarget(_highlightTarget(next.tm));
      }
      _scheduleEditorHighlights(next);
      if (tmChanged || machineWasRemoved) {
        if (_canvasSimulationSteps != null) {
          _stopCanvasSimulation();
        }
        setState(() {
          if (tmChanged) {
            _currentTape = TapeState.initial(
              blankSymbol: next.tm?.blankSymbol ?? '□',
            );
          }
          if (machineWasRemoved) {
            _currentTM = null;
            _stateCount = 0;
            _transitionCount = 0;
            _tapeSymbols = const <String>{};
            _moveDirections = const <String>{};
            _nondeterministicTransitionIds = const <String>{};
            _hasInitialState = false;
            _hasAcceptingState = false;
          }
        });
      }
    });
  }

  void _handleAddStatePressed() {
    if (_toolController.activeTool != AutomatonCanvasTool.addState) {
      _toolController.setActiveTool(AutomatonCanvasTool.addState);
    }
    _canvasController.addStateAtCenter();
  }

  void _showContextualHelp() {
    final tm = ref.read(tmEditorProvider).tm;

    // Determine the most relevant help content based on current TM state
    String helpContextId;
    if (tm == null) {
      helpContextId = 'usage_getting_started';
    } else {
      helpContextId = 'concept_tm';
    }

    showWorkspaceHelp(
      context: context,
      ref: ref,
      contextId: helpContextId,
    );
  }

  @override
  void dispose() {
    _tmEditorSub?.close();
    _highlightService.clear();
    _validationHighlights.dispose();
    _simulationHighlights.dispose();
    _highlightCoordinator.dispose();
    _canvasController.dispose();
    _toolController.dispose();
    super.dispose();
  }

  /// Overrides that bind this page's canvas to the highlight pipeline.
  ///
  /// Applied both to the page subtree and to every modal sheet, since sheets
  /// are hosted by the Navigator and would otherwise miss them.
  List<Override> get _canvasHighlightOverrides => [
        canvasHighlightServiceProvider.overrideWithValue(_highlightService),
        canvasHighlightCoordinatorProvider.overrideWithValue(
          _highlightCoordinator,
        ),
      ];

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final tm = ref.watch(tmEditorProvider).tm;

    return ProviderScope(
      overrides: _canvasHighlightOverrides,
      child: AutomatonWorkspaceScaffold(
        canvasWithToolbar: _buildCanvasWithToolbar,
        algorithmPanel: const TMAlgorithmPanel(),
        tabletAlgorithmPanel: const TMAlgorithmPanel(useExpanded: false),
        simulationPanel: _buildSimulationPanel(),
        infoPanel: _buildInfoPanel(context),
        mobileFloatingPanelBuilder: tm == null
            ? null
            : (
                context, {
                required onDragDelta,
                required onPanelSizeChanged,
              }) =>
                CollapsibleCanvasPanel(
                  label: appLocalizationsOf(context).traceTape,
                  icon: Icons.horizontal_rule,
                  onDragDelta: onDragDelta,
                  onPanelSizeChanged: onPanelSizeChanged,
                  child: TMTapePanel(
                    tapeState: _currentTape,
                    tapeAlphabet: tm.tapeAlphabet,
                    onClear: () {
                      setState(() {
                        _currentTape = TapeState.initial(
                          blankSymbol: tm.blankSymbol,
                        );
                      });
                    },
                  ),
                ),
        floatingActionButton: FloatingActionButton(
          heroTag: 'tm_context_help_fab',
          onPressed: _showContextualHelp,
          tooltip: 'Context-Aware Help',
          child: const Icon(Icons.help_outline),
        ),
      ),
    );
  }

  CanvasHighlightTarget _highlightTarget(TM? tm) {
    return CanvasHighlightTarget(
      kind: AutomatonSurfaceKind.tm,
      surface: _canvasController,
      documentId: tm?.id,
      revision: _highlightRevision,
    );
  }

  void _scheduleEditorHighlights(TMEditorState editorState) {
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

  Widget _buildCanvasWithToolbar({required bool isMobile}) {
    final editorState = ref.watch(tmEditorProvider);
    final statusMessage = _buildToolbarStatusMessage(editorState);
    final hasMachine = _hasMachine;
    final canvas = TMCanvasGraphView(
      controller: _canvasController,
      toolController: _toolController,
      onTmModified: _handleTMUpdate,
    );
    final onSimulate = hasMachine ? _openSimulationSheet : null;
    final onAlgorithms = hasMachine ? _openAlgorithmSheet : null;
    final onMetrics = hasMachine ? _openMetricsSheet : null;
    publishWorkspaceQuickActions(
      ref,
      WorkspaceTab.tm,
      WorkspaceQuickActions(
        onHelp: _showContextualHelp,
        onSimulate: onSimulate,
        onAlgorithms: onAlgorithms,
        onMetrics: onMetrics,
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
              bottom: 144,
              child: CanvasSimulationPlaybackBar(
                key: ValueKey(steps),
                stepCount: steps.length,
                words: projectTapeWordSteps(steps),
                onStepChanged: _handleCanvasSimulationStep,
                onClose: _stopCanvasSimulation,
              ),
            ),
          AnimatedBuilder(
            animation: _canvasListenable,
            builder: (context, _) {
              return MobileAutomatonControls(
                onHelp: _showContextualHelp,
                enableToolSelection: true,
                showSelectionTool: true,
                activeTool: _toolController.activeTool,
                onSelectTool: () => _toolController
                    .setActiveTool(AutomatonCanvasTool.selection),
                onAddState: _handleAddStatePressed,
                onAddTransition: () =>
                    _toolController.toggleTool(AutomatonCanvasTool.transition),
                onZoomIn: _canvasController.zoomIn,
                onZoomOut: _canvasController.zoomOut,
                onFitToContent: _canvasController.fitToContent,
                onResetView: _canvasController.resetView,
                onClear: _clearCanvasMachine,
                onUndo: _canvasController.undo,
                onRedo: _canvasController.redo,
                canUndo: _canvasController.canUndo,
                canRedo: _canvasController.canRedo,
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
              enableToolSelection: true,
              showSelectionTool: true,
              activeTool: _toolController.activeTool,
              onSelectTool: () =>
                  _toolController.setActiveTool(AutomatonCanvasTool.selection),
              onAddState: _handleAddStatePressed,
              onHelp: _showContextualHelp,
              onAddTransition: () =>
                  _toolController.toggleTool(AutomatonCanvasTool.transition),
              onClear: _clearCanvasMachine,
              statusMessage: statusMessage,
            );
          },
        ),
      ],
    );
    final inspector = TMTapePanel(
      tapeState: _currentTape,
      tapeAlphabet: editorState.tm?.tapeAlphabet ?? const {},
      onClear: () {
        setState(() {
          _currentTape = TapeState.initial(
            blankSymbol: ref.read(tmEditorProvider).tm?.blankSymbol ?? '□',
          );
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

  String _buildToolbarStatusMessage(TMEditorState editorState) {
    final tm = editorState.tm;
    return buildAutomatonWorkspaceStatus(
      l10n: appLocalizationsOf(context),
      // All four values come from the built machine so the counts and the
      // flags can never describe two different revisions.
      stateCount: tm?.states.length ?? 0,
      transitionCount: tm?.tmTransitions.length ?? 0,
      hasInitialState: tm?.initialState != null,
      hasAcceptingState: tm?.acceptingStates.isNotEmpty ?? false,
      hasNondeterministicTransitions:
          editorState.nondeterministicTransitionIds.isNotEmpty,
    );
  }

  void _handleTMUpdate(TM tm) {
    final transitions = tm.tmTransitions;
    final nondeterministic = _findNondeterministicTransitions(transitions);
    final hasInitial = tm.initialState != null;
    final hasAccepting = tm.acceptingStates.isNotEmpty;

    setState(() {
      _currentTM = tm;
      _stateCount = tm.states.length;
      _transitionCount = transitions.length;
      _tapeSymbols = Set<String>.unmodifiable(tm.tapeAlphabet);
      _moveDirections = Set<String>.unmodifiable(
        transitions.map((t) => t.direction.name.toUpperCase()),
      );
      _nondeterministicTransitionIds = nondeterministic;
      _hasInitialState = hasInitial;
      _hasAcceptingState = hasAccepting;
    });
  }

  void _openSimulationSheet() {
    if (!_hasMachine) return;
    _stopCanvasSimulation();

    _showDraggableSheet(
      builder: (context, controller) {
        return ListView(
          controller: controller,
          padding: const EdgeInsets.all(16),
          children: [_buildSimulationPanel(allowCanvasPlayback: true)],
        );
      },
      initialChildSize: 0.7,
    );
  }

  TMSimulationPanel _buildSimulationPanel({bool allowCanvasPlayback = false}) {
    return TMSimulationPanel(
      highlightService: _highlightService,
      onTapeChanged: _handleTapeChanged,
      onViewOnCanvas:
          allowCanvasPlayback && supportsCanvasSimulationPlayback(context)
              ? _startCanvasSimulation
              : null,
    );
  }

  void _startCanvasSimulation(List<SimulationStep> steps) {
    if (steps.isEmpty || !supportsCanvasSimulationPlayback(context)) return;
    final recordedSteps = List<SimulationStep>.unmodifiable(steps);
    setState(() {
      _canvasSimulationSteps = recordedSteps;
    });
    _handleCanvasSimulationStep(0);
    Navigator.of(context).pop();
  }

  void _handleCanvasSimulationStep(int stepIndex) {
    final steps = _canvasSimulationSteps;
    if (steps == null || stepIndex < 0 || stepIndex >= steps.length) return;
    final blankSymbol = ref.read(tmEditorProvider).tm?.blankSymbol ?? '□';
    _highlightService.emitFromSteps(steps, stepIndex);
    _handleTapeChanged(
      projectTmTapeStep(
        steps[stepIndex],
        blankSymbol: blankSymbol,
      ),
    );
  }

  void _stopCanvasSimulation() {
    if (_canvasSimulationSteps != null && mounted) {
      setState(() {
        _canvasSimulationSteps = null;
      });
    }
    _highlightService.clear();
  }

  void _openAlgorithmSheet() {
    if (!_hasMachine) return;

    _showDraggableSheet(
      builder: (context, controller) {
        return ListView(
          controller: controller,
          padding: const EdgeInsets.all(16),
          children: const [TMAlgorithmPanel()],
        );
      },
      initialChildSize: 0.6,
    );
  }

  void _openMetricsSheet() {
    _showDraggableSheet(
      builder: (context, controller) {
        return ListView(
          controller: controller,
          padding: const EdgeInsets.all(16),
          children: [_buildInfoPanel(context)],
        );
      },
      initialChildSize: 0.45,
      maxChildSize: 0.75,
    );
  }

  Future<void> _showDraggableSheet({
    required Widget Function(BuildContext context, ScrollController controller)
        builder,
    double initialChildSize = 0.6,
    double minChildSize = 0.3,
    double maxChildSize = 0.9,
  }) {
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        // Modal routes are built by the Navigator, above this page's
        // ProviderScope, so the canvas highlight overrides have to be repeated
        // here or panels inside the sheet resolve the null root coordinator.
        return ProviderScope(
          overrides: _canvasHighlightOverrides,
          child: DraggableScrollableSheet(
            expand: false,
            initialChildSize: initialChildSize,
            minChildSize: minChildSize,
            maxChildSize: maxChildSize,
            builder: (sheetContext, controller) {
              final color = Theme.of(sheetContext).colorScheme.surface;
              return Padding(
                padding: const EdgeInsets.only(top: 8),
                child: ClipRRect(
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(16),
                  ),
                  child: Material(
                    color: color,
                    child: SafeArea(
                      top: false,
                      child: builder(sheetContext, controller),
                    ),
                  ),
                ),
              );
            },
          ),
        );
      },
    );
  }

  Widget _buildInfoPanel(BuildContext context, {EdgeInsetsGeometry? margin}) {
    final theme = Theme.of(context);
    return Container(
      margin: margin,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Turing Machine Overview',
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Monitor the structure of your machine and resolve issues before running simulations or algorithms.',
            style: theme.textTheme.bodyMedium,
          ),
          const SizedBox(height: 12),
          _buildInfoRow('States', '$_stateCount', theme),
          _buildInfoRow('Transitions', '$_transitionCount', theme),
          _buildInfoRow('Tape Symbols', _formatSet(_tapeSymbols), theme),
          _buildInfoRow('Move Directions', _formatSet(_moveDirections), theme),
          _buildInfoRow(
            'Initial State',
            _hasInitialState ? 'Yes' : 'No',
            theme,
          ),
          _buildInfoRow(
            'Accepting State',
            _hasAcceptingState ? 'Yes' : 'No',
            theme,
          ),
          _buildInfoRow(
            'Simulation Ready',
            _isMachineReady ? 'Yes' : 'No',
            theme,
          ),
          _buildInfoRow(
            'Nondeterministic Transitions',
            _nondeterministicTransitionIds.isEmpty
                ? '0'
                : '${_nondeterministicTransitionIds.length}',
            theme,
          ),
          if (_nondeterministicTransitionIds.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(
              'Resolve nondeterminism before running deterministic algorithms.',
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.error,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String value, ThemeData theme) {
    final textStyle = theme.textTheme.bodyMedium;
    final emphasizedStyle = textStyle?.copyWith(fontWeight: FontWeight.w600);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Text('$label: $value', style: emphasizedStyle),
    );
  }

  String _formatSet(Set<String> values) {
    if (values.isEmpty) {
      return '-';
    }
    final sorted = values.toList()..sort();
    return sorted.join(', ');
  }

  Set<String> _findNondeterministicTransitions(Set<TMTransition> transitions) {
    final grouped = <String, List<TMTransition>>{};

    for (final transition in transitions) {
      final key = [
        transition.fromState.id,
        transition.readSymbol,
        transition.tapeNumber.toString(),
      ].join('|');

      grouped.putIfAbsent(key, () => <TMTransition>[]).add(transition);
    }

    return grouped.values
        .where((list) => list.length > 1)
        .expand((list) => list.map((transition) => transition.id))
        .toSet();
  }
}
