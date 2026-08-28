//
//  tm_page.dart
//  Turing Lab
//
//  Hosts the Turing Machines workspace with a GraphView canvas,
//  simulation and algorithm panels, tracking metrics, tools, and
//  highlights so the machine stays consistent across edits, simulations,
//  and responsive layouts.
//
//  Thales Matheus Mendonça Santos - October 2025
//
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/models/simulation_highlight.dart';
import '../../core/constants/help_topic_ids.dart';
import '../../core/formal_systems/formal_systems.dart';
import '../../core/models/simulation_step.dart';
import '../../core/models/tm.dart';
import '../../core/models/tm_transition.dart';
import '../../core/services/canvas_highlight_coordinator.dart';
import '../../l10n/app_localizations_resolver.dart';
import '../localization/locale_value_formatter.dart';
import '../widgets/automaton_workspace_scaffold.dart';
import '../widgets/automaton_diagnostic_highlight_bar.dart';
import '../providers/workspace_quick_actions_provider.dart';
import '../widgets/canvas_simulation_playback_bar.dart';
import '../widgets/canvas_simulation_step_projection.dart';
import '../widgets/collapsible_canvas_panel.dart';
import '../providers/tm_editor_provider.dart';
import '../providers/tm_block_library_provider.dart';
import '../widgets/tm_canvas_graphview.dart';
import '../widgets/tm_algorithm_panel.dart';
import '../widgets/tm_simulation_panel.dart';
import '../widgets/tm/tape_drawer.dart';
import '../widgets/tm/tm_block_library_panel.dart';
import '../widgets/common/workspace_helpers.dart';
import '../widgets/common/workspace_help.dart';
import '../widgets/graphview_canvas_toolbar.dart';
import '../widgets/automaton_canvas_tool.dart';
import '../widgets/automaton_canvas_document_actions.dart';
import '../../core/services/simulation_highlight_service.dart';
import '../../core/services/highlight_channel.dart';
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
  EdgeInsets _canvasToolbarInsets = EdgeInsets.zero;
  late final GraphViewTmCanvasController _canvasController;
  late final CanvasHighlightCoordinator _highlightCoordinator;
  late final CanvasHighlightSourceHandle _diagnosticHighlights;
  late final CanvasHighlightSourceHandle _simulationHighlights;
  late final SimulationHighlightService _highlightService;
  late final AutomatonCanvasToolController _toolController;
  final AutomatonCanvasDocumentActionsController _documentActions =
      AutomatonCanvasDocumentActionsController();
  late final Listenable _canvasListenable;
  int _highlightRevision = 0;
  AutomatonDiagnosticHighlightKind? _activeDiagnosticHighlight;

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
    _scheduleBlockLibrarySynchronization();
    _currentTape = TapeState.initial(
      blankSymbol: initialEditorState.tm?.blankSymbol ?? '□',
    );
    _syncMachineSummary(initialEditorState.tm);
    _canvasController = GraphViewTmCanvasController(
      editorNotifier: ref.read(tmEditorProvider.notifier),
    );
    _canvasController.synchronize(initialEditorState.tm);
    _highlightCoordinator = CanvasHighlightCoordinator(
      target: _highlightTarget(initialEditorState.tm),
      output: GraphViewSimulationHighlightChannel(_canvasController),
    );
    _diagnosticHighlights = _highlightCoordinator.source(
      CanvasHighlightSource.diagnostic,
    );
    _simulationHighlights = _highlightCoordinator.source(
      CanvasHighlightSource.simulation,
    );
    _highlightService = SimulationHighlightService(
      channel: InterceptingHighlightChannel(
        delegate: _simulationHighlights,
        beforeActivity: _handleSimulationHighlightActivity,
      ),
    );
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
        _scheduleBlockLibrarySynchronization();
        _highlightRevision++;
        _highlightCoordinator.retarget(_highlightTarget(next.tm));
        final target = _highlightCoordinator.target;
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted && target == _highlightCoordinator.target) {
            _canvasController.clearHighlight();
          }
        });
        if (_activeDiagnosticHighlight != null) {
          _activeDiagnosticHighlight = null;
        }
      }
      if (tmChanged || machineWasRemoved) {
        if (_canvasSimulationSteps != null) {
          _stopCanvasSimulation();
        }
        setState(() {
          if (tmChanged) {
            _currentTape = TapeState.initial(
              blankSymbol: next.tm?.blankSymbol ?? '□',
            );
            _syncMachineSummary(next.tm);
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

  int _blockLibrarySyncGeneration = 0;

  void _scheduleBlockLibrarySynchronization() {
    final generation = ++_blockLibrarySyncGeneration;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || generation != _blockLibrarySyncGeneration) return;
      ref
          .read(tmBlockLibraryProvider.notifier)
          .synchronize(ref.read(tmEditorProvider).tm);
    });
  }

  void _handleAddStatePressed() {
    // Pure placement toggle: states are added by tapping the canvas while
    // the tool is active, never as a side effect of pressing the button.
    _toolController.toggleTool(AutomatonCanvasTool.addState);
  }

  void _handleCanvasToolbarInsetsChanged(EdgeInsets insets) {
    if (!mounted || _canvasToolbarInsets == insets) return;
    setState(() {
      _canvasToolbarInsets = insets;
    });
  }

  void _showContextualHelp() {
    final tm = ref.read(tmEditorProvider).tm;

    String topicId;
    if (tm == null) {
      topicId = HelpTopicIds.tmEditorOverview;
    } else {
      topicId = HelpTopicIds.tmTheoryTm;
    }

    showWorkspaceHelp(context: context, topicId: topicId);
  }

  @override
  void dispose() {
    _tmEditorSub?.close();
    _simulationHighlights.clear();
    _diagnosticHighlights.dispose();
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
    canvasHighlightCoordinatorProvider.overrideWithValue(_highlightCoordinator),
  ];

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final tm = ref.watch(tmEditorProvider).tm;

    return ProviderScope(
      overrides: _canvasHighlightOverrides,
      child: AutomatonWorkspaceScaffold(
        canvasWithToolbar: _buildCanvasWithToolbar,
        algorithmPanel: const TMAlgorithmPanel(useExpanded: false),
        algorithmTabTitle: appLocalizationsOf(context).algorithmsAndExamples,
        simulationPanel: _buildSimulationPanel(),
        infoPanel: _buildInfoPanel(context),
        mobileFloatingPanelBuilder:
            (context, {required onDragDelta, required onPanelSizeChanged}) =>
                CollapsibleCanvasPanel(
                  label: appLocalizationsOf(context).traceTape,
                  icon: Icons.horizontal_rule,
                  onDragDelta: onDragDelta,
                  onPanelSizeChanged: onPanelSizeChanged,
                  child: TMTapePanel(
                    tapeState: _currentTape,
                    tapeAlphabet: tm?.tapeAlphabet ?? const <String>{},
                    onClear: () {
                      setState(() {
                        _currentTape = TapeState.initial(
                          blankSymbol: tm?.blankSymbol ?? '□',
                        );
                      });
                    },
                  ),
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

  void _setDiagnosticHighlight(bool selected, TMEditorState editorState) {
    if (!selected) {
      _clearDiagnosticHighlight();
      return;
    }

    _stopCanvasSimulation();
    setState(() {
      _activeDiagnosticHighlight = AutomatonDiagnosticHighlightKind.conflicts;
    });
    _diagnosticHighlights.send(
      SimulationHighlight(
        transitionIds: editorState.nondeterministicTransitionIds,
      ),
    );
  }

  void _clearDiagnosticHighlight() {
    if (_activeDiagnosticHighlight != null && mounted) {
      setState(() {
        _activeDiagnosticHighlight = null;
      });
    }
    _diagnosticHighlights.clear();
  }

  void _handleSimulationHighlightActivity() {
    _diagnosticHighlights.clear();
    if (_activeDiagnosticHighlight != null && mounted) {
      setState(() {
        _activeDiagnosticHighlight = null;
      });
    }
  }

  Widget _buildDiagnosticHighlightBar(
    TMEditorState editorState, {
    required bool isMobile,
  }) {
    return Align(
      alignment: Alignment.topCenter,
      child: SafeArea(
        minimum: EdgeInsets.fromLTRB(
          12,
          isMobile
              ? 12
              : (_canvasToolbarInsets.top > 0
                    ? _canvasToolbarInsets.top + 8
                    : 88),
          12,
          12,
        ),
        child: AutomatonDiagnosticHighlightBar(
          activeKind: _activeDiagnosticHighlight,
          conflictCount: editorState.nondeterministicTransitionIds.length,
          onConflictSelected: (selected) =>
              _setDiagnosticHighlight(selected, editorState),
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
      documentActionsController: _documentActions,
      onTmModified: _handleTMUpdate,
    );
    publishWorkspaceQuickActionsForKey(
      ref,
      DefaultFormalSystemIds.tm,
      WorkspaceQuickActions(
        onHelp: _showContextualHelp,
        onSimulate: _openSimulationSheet,
        onAlgorithms: _openAlgorithmSheet,
        algorithmsTooltip: appLocalizationsOf(
          context,
        ).workspaceAlgorithmsAndExamplesTooltip,
        onMetrics: _openMetricsSheet,
        simulateEnabled: hasMachine,
        metricsEnabled: hasMachine,
      ),
    );

    if (isMobile) {
      return Stack(
        children: [
          Positioned.fill(child: canvas),
          _buildDiagnosticHighlightBar(editorState, isMobile: true),
          if (_canvasSimulationSteps case final steps?)
            Positioned(
              left: 16,
              right: 16,
              bottom: _canvasToolbarInsets.bottom + 16,
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
                onAddTransition: () =>
                    _toolController.toggleTool(AutomatonCanvasTool.transition),
                onManageBlocks: _openBlockLibrarySheet,
                onArrangeAutomaton: _documentActions.arrange,
                onImportAutomaton: _documentActions.importAutomaton,
                onDocumentNotes: _documentActions.showDocumentNotes,
                documentActionsEnabled: editorState.tm != null,
                onHelp: _showContextualHelp,
                onClear: _clearCanvasMachine,
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
        _buildDiagnosticHighlightBar(editorState, isMobile: false),
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
              onManageBlocks: _openBlockLibrarySheet,
              onArrangeAutomaton: _documentActions.arrange,
              onImportAutomaton: _documentActions.importAutomaton,
              onDocumentNotes: _documentActions.showDocumentNotes,
              documentActionsEnabled: editorState.tm != null,
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
    setState(() {
      _syncMachineSummary(tm);
    });
  }

  void _syncMachineSummary(TM? tm) {
    final transitions = tm?.tmTransitions ?? const <TMTransition>{};
    _currentTM = tm;
    _stateCount = tm?.states.length ?? 0;
    _transitionCount = transitions.length;
    _tapeSymbols = Set<String>.unmodifiable(tm?.tapeAlphabet ?? const {});
    _moveDirections = Set<String>.unmodifiable(
      transitions
          .expand((transition) => transition.directions)
          .map((direction) => direction.name.toUpperCase()),
    );
    _nondeterministicTransitionIds = _findNondeterministicTransitions(
      transitions,
    );
    _hasInitialState = tm?.initialState != null;
    _hasAcceptingState = tm?.acceptingStates.isNotEmpty ?? false;
  }

  void _openSimulationSheet() {
    if (!_hasMachine) return;
    _clearDiagnosticHighlight();
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
      projectTmTapeStep(steps[stepIndex], blankSymbol: blankSymbol),
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

  void _openBlockLibrarySheet() {
    _showDraggableSheet(
      builder: (context, controller) =>
          TMBlockLibraryPanel(scrollController: controller),
      initialChildSize: 0.72,
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
    final tm = ref.watch(tmEditorProvider).tm;
    final formatter = LocaleValueFormatter.of(context);
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
            appLocalizationsOf(context).tmOverviewTitle,
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            appLocalizationsOf(context).tmOverviewBody,
            style: theme.textTheme.bodyMedium,
          ),
          const SizedBox(height: 12),
          _buildInfoRow(
            appLocalizationsOf(context).states,
            formatter.integer(_stateCount),
            theme,
          ),
          _buildInfoRow(
            appLocalizationsOf(context).transitions,
            formatter.integer(_transitionCount),
            theme,
          ),
          if (tm != null)
            Semantics(
              label: appLocalizationsOf(context).tmTapeCount,
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      appLocalizationsOf(context).tmTapeCount,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  IconButton(
                    key: const Key('tm-tape-count-decrease'),
                    tooltip: appLocalizationsOf(context).tmDecreaseTapeCount,
                    onPressed: tm.tapeCount == 1
                        ? null
                        : () => _changeTapeCount(tm.tapeCount - 1),
                    icon: const Icon(Icons.remove),
                  ),
                  Semantics(
                    liveRegion: true,
                    label:
                        '${appLocalizationsOf(context).tmTapeCount}: '
                        '${formatter.integer(tm.tapeCount)}',
                    child: Text(
                      formatter.integer(tm.tapeCount),
                      key: const Key('tm-tape-count-value'),
                      style: theme.textTheme.titleMedium,
                    ),
                  ),
                  IconButton(
                    key: const Key('tm-tape-count-increase'),
                    tooltip: appLocalizationsOf(context).tmIncreaseTapeCount,
                    onPressed: () => _changeTapeCount(tm.tapeCount + 1),
                    icon: const Icon(Icons.add),
                  ),
                ],
              ),
            ),
          _buildInfoRow(
            appLocalizationsOf(context).tapeSymbols,
            _formatSet(_tapeSymbols),
            theme,
          ),
          _buildInfoRow(
            appLocalizationsOf(context).moveDirections,
            _formatSet(_moveDirections),
            theme,
          ),
          _buildInfoRow(
            appLocalizationsOf(context).initialState,
            _hasInitialState
                ? appLocalizationsOf(context).yes
                : appLocalizationsOf(context).no,
            theme,
          ),
          _buildInfoRow(
            appLocalizationsOf(context).acceptingState,
            _hasAcceptingState
                ? appLocalizationsOf(context).yes
                : appLocalizationsOf(context).no,
            theme,
          ),
          _buildInfoRow(
            appLocalizationsOf(context).simulationReady,
            _isMachineReady
                ? appLocalizationsOf(context).yes
                : appLocalizationsOf(context).no,
            theme,
          ),
          _buildInfoRow(
            appLocalizationsOf(context).nondeterministicTransitions,
            formatter.integer(_nondeterministicTransitionIds.length),
            theme,
          ),
          if (_nondeterministicTransitionIds.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(
              appLocalizationsOf(context).resolveNondeterminism,
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

  void _changeTapeCount(int count) {
    final changed = ref.read(tmEditorProvider.notifier).setTapeCount(count);
    if (!changed && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(appLocalizationsOf(context).tmTapeCountShrinkBlocked),
        ),
      );
    }
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
        ...transition.readSymbols.map((symbol) => '${symbol.length}:$symbol'),
      ].join('|');

      grouped.putIfAbsent(key, () => <TMTransition>[]).add(transition);
    }

    return grouped.values
        .where((list) => list.length > 1)
        .expand((list) => list.map((transition) => transition.id))
        .toSet();
  }
}
