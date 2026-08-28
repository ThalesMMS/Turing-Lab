//
//  fsa_page.dart
//  Turing Lab
//
//  Sets up the Finite Automata workspace with a GraphView canvas,
//  simulation and algorithm panels, coordinating controllers, highlights,
//  and tools for a full responsive edit-and-experiment flow.
//
//  Thales Matheus Mendonça Santos - October 2025
//
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/batch_execution/batch_execution.dart';
import '../../core/models/conversion_step_history.dart';
import '../../core/constants/help_topic_ids.dart';
import '../../core/formal_systems/formal_systems.dart';
import '../../core/models/fsa.dart';
import '../../core/manual_conversions/fa_to_regex_manual.dart';
import '../../core/manual_conversions/manual_conversion_factories.dart';
import '../../core/manual_conversions/manual_conversion_session.dart';
import '../../core/manual_conversions/fa_grammar_session_factory.dart';
import '../../core/models/grammar.dart';
import '../../core/models/simulation_highlight.dart';
import '../../core/models/simulation_step.dart';
import '../../core/models/validation_diagnostic.dart';
import '../../l10n/app_localizations_resolver.dart';
import '../../l10n/app_localizations_structured_messages.dart';
import '../../l10n/app_localizations_workflows.dart';
import '../providers/algorithm_step_provider.dart';
import '../providers/automaton_algorithm_provider.dart';
import '../providers/conversion_history_provider.dart';
import '../providers/automaton_layout_provider.dart';
import '../providers/automaton_simulation_provider.dart';
import '../providers/automaton_state_provider.dart';
import '../providers/grammar_provider.dart';
import '../providers/home_navigation_provider.dart';
import '../providers/regex_editor_provider.dart';
import '../widgets/algorithm_panel.dart';
import '../widgets/algorithm_step_navigator.dart';
import '../widgets/algorithm_step_viewer.dart';
import '../widgets/automaton_graphview_canvas.dart';
import '../widgets/automaton_canvas_document_actions.dart';
import '../widgets/automaton_canvas_tool.dart';
import '../widgets/automaton_workspace_scaffold.dart';
import '../providers/workspace_quick_actions_provider.dart';
import '../widgets/canvas_simulation_playback_bar.dart';
import '../widgets/canvas_simulation_step_projection.dart';
import '../widgets/graphview_canvas_toolbar.dart';
import '../widgets/simulation_panel.dart';
import '../widgets/step_navigation_controls.dart';
import '../widgets/app_snackbar.dart';
import '../widgets/fsa/determinism_badge.dart';
import '../widgets/common/workspace_helpers.dart';
import '../widgets/common/workspace_help.dart';
import '../widgets/conversion_replacement_dialog.dart';
import '../../core/services/simulation_highlight_service.dart';
import '../../core/services/highlight_channel.dart';
import '../../core/services/algorithm_step_highlight_service.dart';
import '../../core/services/automaton_diagnostic_highlight_service.dart';
import '../../core/services/canvas_highlight_coordinator.dart';
import '../../features/canvas/graphview/graphview_canvas_controller.dart';
import '../../features/canvas/graphview/graphview_highlight_channel.dart';
import '../../core/validators/input_validators.dart';
import '../../core/validators/validation_issue_to_diagnostic.dart';
import '../widgets/validation_diagnostic_card.dart';
import '../widgets/fsa_conversion_comparison_panel.dart';
import '../widgets/fa_grammar_requirement_editor.dart';
import '../widgets/fa_to_regex_requirement_editor.dart';
import '../widgets/manual_conversion_document_preview.dart';
import '../widgets/manual_conversion_workspace.dart';
import '../../core/models/step_explanation.dart';
import '../widgets/automaton_diagnostic_highlight_bar.dart';

part 'fsa_page/fsa_page_behavior.dart';

const double _kStepViewerNavigationControlsHeight = 88.0;
const double _kStepViewerMinHeight = 160.0;
const double _kStepViewerMaxHeight = 640.0;
const double _kStepViewerDefaultHeight = 360.0;
const double _kMobileStepViewerHeight = 400.0;
const double _kTabletStepViewerMinHeight = 240.0;
const double _kTabletStepViewerMaxHeight = 520.0;

/// Page for working with Finite State Automata
class FSAPage extends ConsumerStatefulWidget {
  const FSAPage({super.key});

  @override
  ConsumerState<FSAPage> createState() => _FSAPageState();
}

class _FSAPageState extends ConsumerState<FSAPage>
    with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;

  final GlobalKey _canvasKey = GlobalKey();
  late final GraphViewCanvasController _canvasController;
  late final CanvasHighlightCoordinator _highlightCoordinator;
  late final CanvasHighlightSourceHandle _validationHighlights;
  late final CanvasHighlightSourceHandle _diagnosticHighlights;
  late final CanvasHighlightSourceHandle _analysisHighlights;
  late final CanvasHighlightSourceHandle _simulationHighlights;
  late final SimulationHighlightService _highlightService;
  late final AlgorithmStepHighlightService _algorithmStepHighlightService;
  late final AutomatonCanvasToolController _toolController;
  final AutomatonCanvasDocumentActionsController _documentActions =
      AutomatonCanvasDocumentActionsController();
  ProviderSubscription<AutomatonStateProviderState>? _automatonStateSub;
  bool _stepByStepMode = false;
  bool _canvasPlaybackSupported = false;
  List<SimulationStep>? _canvasSimulationSteps;
  EdgeInsets _canvasToolbarInsets = EdgeInsets.zero;
  SimulationHighlight? _lastValidationHighlight;
  String? _lastValidationHighlightKey;
  String? _cachedValidationAutomatonKey;
  List<ValidationDiagnostic> _cachedValidationDiagnostics = const [];
  final AutomatonDiagnosticHighlightService _diagnosticHighlightService =
      const AutomatonDiagnosticHighlightService();
  AutomatonDiagnosticHighlightKind? _activeDiagnosticHighlight;
  int _highlightRevision = 0;

  @override
  void initState() {
    super.initState();
    _canvasController = GraphViewCanvasController(
      automatonStateNotifier: ref.read(automatonStateProvider.notifier),
    );
    _canvasController.synchronize(
      ref.read(automatonStateProvider).currentAutomaton,
    );
    final initialState = ref.read(automatonStateProvider);
    _highlightCoordinator = CanvasHighlightCoordinator(
      target: _highlightTarget(initialState.currentAutomaton),
      output: GraphViewSimulationHighlightChannel(_canvasController),
    );
    _validationHighlights = _highlightCoordinator.source(
      CanvasHighlightSource.validation,
    );
    _diagnosticHighlights = _highlightCoordinator.source(
      CanvasHighlightSource.diagnostic,
    );
    _analysisHighlights = _highlightCoordinator.source(
      CanvasHighlightSource.analysis,
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
    _algorithmStepHighlightService = AlgorithmStepHighlightService(
      channel: _analysisHighlights,
    );
    _canvasController.algorithmStepHighlightService =
        _algorithmStepHighlightService;
    _toolController = AutomatonCanvasToolController(
      AutomatonCanvasTool.selection,
    );
    _automatonStateSub = ref.listenManual<AutomatonStateProviderState>(
      automatonStateProvider,
      (previous, next) {
        if (!mounted ||
            identical(previous?.currentAutomaton, next.currentAutomaton)) {
          return;
        }
        _highlightRevision++;
        _highlightCoordinator.retarget(_highlightTarget(next.currentAutomaton));
        final target = _highlightCoordinator.target;
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted && target == _highlightCoordinator.target) {
            _canvasController.clearHighlight();
          }
        });
        if (_activeDiagnosticHighlight != null) {
          setState(() {
            _activeDiagnosticHighlight = null;
          });
        }
        if (_canvasSimulationSteps != null) {
          _stopCanvasSimulation();
        }
      },
    );
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

  @override
  void dispose() {
    _automatonStateSub?.close();
    _simulationHighlights.clear();
    _algorithmStepHighlightService.clear();
    _validationHighlights.dispose();
    _diagnosticHighlights.dispose();
    _analysisHighlights.dispose();
    _simulationHighlights.dispose();
    _highlightCoordinator.dispose();
    _canvasController.dispose();
    _toolController.dispose();
    super.dispose();
  }

  void _updatePageState(VoidCallback callback) => setState(callback);

  void _handleCanvasToolbarInsetsChanged(EdgeInsets insets) {
    if (!mounted || _canvasToolbarInsets == insets) return;
    setState(() {
      _canvasToolbarInsets = insets;
    });
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final state = ref.watch(automatonStateProvider);
    _syncValidationHighlight(_validationDiagnosticsFor(state.currentAutomaton));

    // Listen for algorithm step changes and apply highlights to canvas
    ref.listen<AlgorithmStepState>(algorithmStepProvider, (previous, next) {
      if (next.hasSteps && next.currentStep != null) {
        _algorithmStepHighlightService.emitFromMetadata(
          next.currentStep!.properties,
        );
      } else {
        _algorithmStepHighlightService.clear();
      }
    });

    return ProviderScope(
      overrides: [
        canvasHighlightServiceProvider.overrideWithValue(_highlightService),
        canvasHighlightCoordinatorProvider.overrideWithValue(
          _highlightCoordinator,
        ),
      ],
      child: AutomatonWorkspaceScaffold(
        canvasWithToolbar: ({required isMobile}) =>
            _buildCanvasArea(state: state, isMobile: isMobile),
        algorithmPanel: _buildAlgorithmWorkspacePanel(state: state),
        algorithmTabTitle: appLocalizationsOf(context).algorithmsAndExamples,
        simulationPanel: _buildSimulationWorkspacePanel(),
      ),
    );
  }
}
