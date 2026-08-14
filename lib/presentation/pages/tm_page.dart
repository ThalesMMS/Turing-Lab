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

import '../../core/models/state.dart' as automaton_state;
import '../../core/models/tm.dart';
import '../../core/models/tm_transition.dart';
import '../widgets/automaton_workspace_scaffold.dart';
import '../providers/help_provider.dart';
import '../widgets/canvas_quick_actions.dart';
import '../providers/tm_editor_provider.dart';
import '../widgets/context_aware_help_panel.dart';
import '../widgets/tm_canvas_graphview.dart';
import '../widgets/tm_algorithm_panel.dart';
import '../widgets/tm_simulation_panel.dart';
import '../widgets/tm/tape_drawer.dart';
import '../widgets/common/workspace_helpers.dart';
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
  late final GraphViewTmCanvasController _canvasController;
  late final GraphViewSimulationHighlightChannel _highlightChannel;
  late final SimulationHighlightService _highlightService;
  late final AutomatonCanvasToolController _toolController;
  AutomatonCanvasTool _activeTool = AutomatonCanvasTool.selection;

  bool get _isMachineReady =>
      _currentTM != null && _hasInitialState && _hasAcceptingState;

  bool get _hasMachine => _currentTM != null && _stateCount > 0;

  void _clearCanvasMachine() {
    final blankSymbol = ref.read(tmEditorProvider).tm?.blankSymbol ?? '□';
    ref.read(tmEditorProvider.notifier).updateFromCanvas(
      states: const <automaton_state.State>[],
      transitions: const <TMTransition>[],
    );
    setState(() {
      _currentTape = TapeState.initial(blankSymbol: blankSymbol);
    });
  }

  @override
  void initState() {
    super.initState();
    _canvasController = GraphViewTmCanvasController(
      editorNotifier: ref.read(tmEditorProvider.notifier),
    );
    _canvasController.synchronize(ref.read(tmEditorProvider).tm);
    _highlightChannel = GraphViewSimulationHighlightChannel(_canvasController);
    _highlightService = SimulationHighlightService(channel: _highlightChannel);
    _toolController = AutomatonCanvasToolController();
    _toolController.addListener(_handleToolChanged);

    _tmEditorSub = ref.listenManual<TMEditorState>(tmEditorProvider, (
      previous,
      next,
    ) {
      if (!mounted) return;
      if (next.tm == null && _currentTM != null) {
        setState(() {
          _currentTM = null;
          _stateCount = 0;
          _transitionCount = 0;
          _tapeSymbols = const <String>{};
          _moveDirections = const <String>{};
          _nondeterministicTransitionIds = const <String>{};
          _hasInitialState = false;
          _hasAcceptingState = false;
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

  void _toggleCanvasTool(AutomatonCanvasTool tool) {
    final current = _toolController.activeTool;
    if (current == tool) {
      _toolController.setActiveTool(AutomatonCanvasTool.selection);
    } else {
      _toolController.setActiveTool(tool);
    }
  }

  void _showContextualHelp() {
    final helpNotifier = ref.read(helpProvider.notifier);
    final tm = ref.read(tmEditorProvider).tm;

    // Determine the most relevant help content based on current TM state
    String helpContextId;
    if (tm == null) {
      helpContextId = 'usage_getting_started';
    } else {
      helpContextId = 'concept_tm';
    }

    final helpContent = helpNotifier.getHelpByContext(helpContextId);
    if (helpContent != null) {
      ContextAwareHelpPanel.show(
        context,
        helpContent: helpContent,
      );
    }
  }

  @override
  void dispose() {
    _tmEditorSub?.close();
    _toolController.removeListener(_handleToolChanged);
    _toolController.dispose();
    _highlightService.clear();
    _canvasController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final tm = ref.watch(tmEditorProvider).tm;

    return ProviderScope(
      overrides: [
        canvasHighlightServiceProvider.overrideWithValue(_highlightService),
      ],
      child: AutomatonWorkspaceScaffold(
        canvasWithToolbar: _buildCanvasWithToolbar,
        algorithmPanel: const TMAlgorithmPanel(),
        tabletAlgorithmPanel: const TMAlgorithmPanel(useExpanded: false),
        simulationPanel: TMSimulationPanel(highlightService: _highlightService),
        infoPanel: _buildInfoPanel(context),
        mobileFloatingPanel: tm == null
            ? null
            : TMTapePanel(
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
        floatingActionButton: FloatingActionButton(
          heroTag: 'tm_context_help_fab',
          onPressed: _showContextualHelp,
          tooltip: 'Context-Aware Help',
          child: const Icon(Icons.help_outline),
        ),
      ),
    );
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
    final combinedListenable = _canvasController.graphRevision;
    final onSimulate = _isMachineReady ? _openSimulationSheet : null;
    final onAlgorithms = hasMachine ? _openAlgorithmSheet : null;
    final onMetrics = hasMachine ? _openMetricsSheet : null;

    if (isMobile) {
      return Stack(
        children: [
          Positioned.fill(child: canvas),
          if (onSimulate != null || onAlgorithms != null || onMetrics != null)
            Positioned(
              top: 16,
              left: 16,
              child: CanvasQuickActions(
                onHelp: _showContextualHelp,
                onSimulate: onSimulate,
                onAlgorithms: onAlgorithms,
                onMetrics: onMetrics,
              ),
            ),
          AnimatedBuilder(
            animation: combinedListenable,
            builder: (context, _) {
              return MobileAutomatonControls(
                onAddState: _canvasController.addStateAtCenter,
                onFitToContent: _canvasController.fitToContent,
                onResetView: _canvasController.resetView,
                onClear: _clearCanvasMachine,
                onUndo: _canvasController.undo,
                onRedo: _canvasController.redo,
                canUndo: _canvasController.canUndo,
                canRedo: _canvasController.canRedo,
                onSimulate: null,
                isSimulationEnabled: false,
                onAlgorithms: null,
                isAlgorithmsEnabled: false,
                onMetrics: null,
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
                  _toggleCanvasTool(AutomatonCanvasTool.transition),
              onClear: _clearCanvasMachine,
              statusMessage: statusMessage,
            );
          },
        ),
        Positioned(
          bottom: 16,
          right: 16,
          child: TMTapePanel(
            tapeState: _currentTape,
            tapeAlphabet:
                ref.read(tmEditorProvider).tm?.tapeAlphabet ?? const {},
            onClear: () {
              setState(() {
                _currentTape = TapeState.initial(
                  blankSymbol:
                      ref.read(tmEditorProvider).tm?.blankSymbol ?? '□',
                );
              });
            },
          ),
        ),
      ],
    );
  }

  String _buildToolbarStatusMessage(TMEditorState editorState) {
    final tm = editorState.tm;
    final stateCount = editorState.states.length;
    final transitionCount = editorState.transitions.length;

    final messageParts = <String>[];

    final warnings = <String>[];
    if (tm == null || tm.initialState == null) {
      warnings.add('Missing start state');
    }
    if (tm == null || tm.acceptingStates.isEmpty) {
      warnings.add('No accepting states');
    }
    if (editorState.nondeterministicTransitionIds.isNotEmpty) {
      warnings.add('Nondeterministic transitions');
    }

    if (warnings.isNotEmpty) {
      messageParts.add('⚠ ${warnings.join(' · ')}');
    }

    if (stateCount == 0 && transitionCount == 0) {
      messageParts.add('No machine defined');
    } else {
      messageParts.add(
        '${formatCount('state', 'states', stateCount)} · '
        '${formatCount('transition', 'transitions', transitionCount)}',
      );
    }

    return messageParts.join(' · ');
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
    if (!_isMachineReady) return;

    _showDraggableSheet(
      builder: (context, controller) {
        return ListView(
          controller: controller,
          padding: const EdgeInsets.all(16),
          children: [TMSimulationPanel(highlightService: _highlightService)],
        );
      },
      initialChildSize: 0.7,
    );
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
        return DraggableScrollableSheet(
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
