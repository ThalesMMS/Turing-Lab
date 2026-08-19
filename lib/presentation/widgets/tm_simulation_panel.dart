//
//  tm_simulation_panel.dart
//  Turing Lab
//
//  Realiza a simulação de Máquinas de Turing para o autômato ativo, oferecendo
//  campos de entrada, controles de execução e apresentação de resultados com
//  histórico de passos e mensagens de aceitação.
//  Dialoga com o TMEditorProvider e com o SimulationHighlightService para manter
//  sincronização com o canvas, limpando controladores e destaques conforme o
//  ciclo de vida do widget.
//
//  Thales Matheus Mendonça Santos - October 2025
//
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/algorithms/tm_simulator.dart';
import '../../core/models/simulation_step.dart';
import '../../core/services/simulation_highlight_service.dart';
import '../../core/services/simulation_runner.dart';
import '../../l10n/app_localizations_resolver.dart';
import '../../l10n/app_localizations_workflows.dart';
import '../providers/tm_editor_provider.dart';
import 'base_simulation_panel.dart';
import 'canvas_simulation_step_projection.dart';
import 'tm/tape_drawer.dart';
import 'trace_viewers/tm_trace_viewer.dart';

/// Panel for Turing Machine simulation and string testing
class TMSimulationPanel extends ConsumerStatefulWidget {
  final SimulationHighlightService? highlightService;
  final SimulationRunner? simulationRunner;
  final ValueChanged<TapeState>? onTapeChanged;
  final ValueChanged<List<SimulationStep>>? onViewOnCanvas;

  const TMSimulationPanel({
    super.key,
    this.highlightService,
    this.simulationRunner,
    this.onTapeChanged,
    this.onViewOnCanvas,
  });

  @override
  ConsumerState<TMSimulationPanel> createState() => _TMSimulationPanelState();
}

class _TMSimulationPanelState extends ConsumerState<TMSimulationPanel>
    with TickerProviderStateMixin {
  final TextEditingController _inputController = TextEditingController();
  late final SimulationHighlightService _fallbackHighlightService;

  bool _isSimulating = false;
  bool _hasSimulationResult = false;
  bool? _isAccepted;
  String? _statusMessage;
  List<SimulationStep> _simulationSteps = const [];
  TMSimulationResult? _result;
  late final SimulationRunner _simulationRunner;
  SimulationTask<TMSimulationResult>? _activeTask;
  ProviderSubscription<TMEditorState>? _tmEditorSubscription;
  int _requestGeneration = 0;
  TapeState _currentTapeState = TapeState.initial();

  // Animation controllers for smooth transitions
  late AnimationController _stepTransitionController;
  late Animation<double> _stepFadeAnimation;
  bool _isTransitioning = false;
  int? _pendingStepIndex;

  SimulationHighlightService get _highlightService =>
      widget.highlightService ?? _fallbackHighlightService;

  @override
  void initState() {
    super.initState();
    _fallbackHighlightService = SimulationHighlightService();
    _simulationRunner = widget.simulationRunner ?? SimulationRunner();
    final tm = ref.read(tmEditorProvider).tm;
    _currentTapeState = TapeState.initial(
      blankSymbol: tm?.blankSymbol ?? '□',
    );
    _tmEditorSubscription = ref.listenManual<TMEditorState>(
      tmEditorProvider,
      _handleEditorStateChanged,
    );
    _stepTransitionController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    _stepFadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _stepTransitionController,
        curve: Curves.easeInOut,
      ),
    );
    _stepTransitionController.value = 1.0;
  }

  @override
  void didUpdateWidget(covariant TMSimulationPanel oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.highlightService != widget.highlightService) {
      (oldWidget.highlightService ?? _fallbackHighlightService).clear();
    }
  }

  @override
  void dispose() {
    _tmEditorSubscription?.close();
    _activeTask?.cancel();
    _stepTransitionController.dispose();
    _inputController.dispose();
    _fallbackHighlightService.clear();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SimulationPanelShell(
      children: [
        _buildHeader(context),
        const SizedBox(height: 16),
        _buildInputSection(context),
        const SizedBox(height: 16),
        _buildSimulateButton(context),
        const SizedBox(height: 16),
        _buildResultsSection(context),
      ],
    );
  }

  Widget _buildHeader(BuildContext context) {
    return const SimulationPanelHeader(
      title: 'TM Simulation',
      icon: Icons.play_arrow,
    );
  }

  Widget _buildInputSection(BuildContext context) {
    return SimulationInputSection(
      title: 'Simulation Input',
      children: [
        SimulationTextField(
          controller: _inputController,
          labelText: 'Input String',
          hintText: 'Leave blank for ε; whitespace is preserved',
          isDense: false,
        ),
        const SizedBox(height: 8),
        Text(
          appLocalizationsOf(context).localizeWorkflowText(
            'Examples: 101 (binary), 1100 (palindrome), 111 (counting)',
          ),
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Theme.of(
                  context,
                ).colorScheme.onSurface.withValues(alpha: 0.7),
              ),
        ),
      ],
    );
  }

  Widget _buildSimulateButton(BuildContext context) {
    return SimulationRunButton(
      isSimulating: _isSimulating,
      label: 'Simulate TM',
      onPressed: _simulateTM,
      onCancel: _cancelSimulation,
    );
  }

  Widget _buildResultsSection(BuildContext context) {
    return SimulationResultsSection(
      title: 'Simulation Results',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          if (_hasSimulationResult)
            _buildResults(context)
          else
            _buildEmptyResults(context),
          if (_hasSimulationResult && _result != null) ...[
            const SizedBox(height: 12),
            _buildTapePanel(context),
          ],
        ],
      ),
    );
  }

  Widget _buildEmptyResults(BuildContext context) {
    return const SimulationEmptyResults();
  }

  Widget _buildResults(BuildContext context) {
    if (_isAccepted == null) {
      return SimulationStatusCard(
        isAccepted: null,
        message: _statusMessage ?? 'Simulation error',
      );
    }

    final isAccepted = _isAccepted!;
    final message = _statusMessage ?? (isAccepted ? 'Accepted' : 'Rejected');

    return SimulationStatusCard(
      isAccepted: isAccepted,
      message: message,
      children: [
        if (_simulationSteps.isNotEmpty) ...[
          const SizedBox(height: 12),
          Text(
            'Simulation Steps:',
            style: Theme.of(
              context,
            ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 8),
          if (_hasSimulationResult && _result != null)
            FadeTransition(
              opacity: _stepFadeAnimation,
              child: TMTraceViewer(
                result: _result!,
                highlightService: _highlightService,
                onStepChanged: _handleStepChanged,
              ),
            ),
          if (widget.onViewOnCanvas != null) ...[
            const SizedBox(height: 12),
            SimulationViewOnCanvasButton(
              onPressed: () => widget.onViewOnCanvas!(
                List<SimulationStep>.unmodifiable(_simulationSteps),
              ),
            ),
          ],
        ],
      ],
    );
  }

  Future<void> _simulateTM() async {
    final inputString = _inputController.text;

    final tm = ref.read(tmEditorProvider).tm;
    if (tm == null) {
      _showError('Create a Turing machine on the canvas before simulating');
      return;
    }

    setState(() {
      _isSimulating = true;
      _hasSimulationResult = false;
      _isAccepted = null;
      _statusMessage = null;
      _simulationSteps = const [];
      _result = null;
    });
    _replaceTapeState(TapeState.initial(blankSymbol: tm.blankSymbol));

    _highlightService.clear();
    _activeTask?.cancel();
    final generation = ++_requestGeneration;

    final task = _simulationRunner.runTm(
      tm,
      inputString,
      stepByStep: true,
      timeout: const Duration(seconds: 5),
    );
    _activeTask = task;
    final outcome = await task.outcome;

    if (!mounted || generation != _requestGeneration) {
      return;
    }
    _activeTask = null;

    if (outcome.kind == SimulationOutcomeKind.cancelled) {
      _finishCancelledSimulation();
      return;
    }

    final simulation = outcome.result;
    if (simulation == null) {
      final message = outcome.message ?? 'Simulation failed';
      setState(() {
        _isSimulating = false;
        _hasSimulationResult = true;
        _isAccepted = null;
        _statusMessage = message;
        _simulationSteps = const [];
        _result = null;
      });
      _highlightService.clear();
      _showError(message);
      return;
    }

    final nextTapeState = simulation.steps.isNotEmpty
        ? projectTmTapeStep(
            simulation.steps[0],
            blankSymbol: tm.blankSymbol,
          )
        : TapeState.initial(blankSymbol: tm.blankSymbol);
    setState(() {
      _isSimulating = false;
      _hasSimulationResult = true;
      _isAccepted = simulation.accepted;
      _statusMessage = simulation.accepted
          ? 'Accepted'
          : (simulation.errorMessage?.isNotEmpty ?? false
              ? 'Rejected: ${simulation.errorMessage}'
              : 'Rejected');
      _simulationSteps = simulation.steps;
      _result = simulation;
    });
    _replaceTapeState(nextTapeState);

    if (simulation.steps.isNotEmpty) {
      _highlightService.emitFromSteps(simulation.steps, 0);
    } else {
      _highlightService.clear();
    }
  }

  void _cancelSimulation() {
    if (!_isSimulating) return;
    _requestGeneration++;
    _activeTask?.cancel();
    _activeTask = null;
    _finishCancelledSimulation();
  }

  void _finishCancelledSimulation() {
    if (!mounted) return;
    setState(() {
      _isSimulating = false;
      _hasSimulationResult = true;
      _isAccepted = null;
      _statusMessage = 'Simulation cancelled';
      _simulationSteps = const [];
      _result = null;
    });
    _highlightService.clear();
  }

  void _showError(String message) {
    _highlightService.clear();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Theme.of(context).colorScheme.error,
      ),
    );
  }

  Future<void> _handleStepChanged(int stepIndex) async {
    final result = _result;
    if (result == null || stepIndex < 0 || stepIndex >= result.steps.length) {
      return;
    }
    if (_isTransitioning) {
      _pendingStepIndex = stepIndex;
      return;
    }
    _pendingStepIndex = null;
    final generation = _requestGeneration;

    setState(() {
      _isTransitioning = true;
    });

    // Fade out current step
    await _stepTransitionController.reverse();

    if (!mounted ||
        generation != _requestGeneration ||
        !identical(_result, result)) {
      _pendingStepIndex = null;
      if (mounted) {
        await _stepTransitionController.forward();
        if (mounted) {
          setState(() {
            _isTransitioning = false;
          });
        }
      }
      return;
    }

    // Update state with new step
    final blankSymbol = ref.read(tmEditorProvider).tm?.blankSymbol ?? '□';
    _replaceTapeState(
      projectTmTapeStep(
        result.steps[stepIndex],
        blankSymbol: blankSymbol,
      ),
    );

    // Fade in new step
    await _stepTransitionController.forward();

    if (mounted) {
      final pendingStepIndex = _pendingStepIndex;
      _pendingStepIndex = null;
      setState(() {
        _isTransitioning = false;
      });
      if (pendingStepIndex != null && pendingStepIndex != stepIndex) {
        await _handleStepChanged(pendingStepIndex);
      }
    }
  }

  void _replaceTapeState(TapeState tapeState) {
    if (!mounted) return;
    setState(() {
      _currentTapeState = tapeState;
    });
    widget.onTapeChanged?.call(tapeState);
  }

  void _handleEditorStateChanged(
    TMEditorState? previous,
    TMEditorState next,
  ) {
    if (!mounted || identical(previous?.tm, next.tm)) return;

    _requestGeneration++;
    _activeTask?.cancel();
    _activeTask = null;
    setState(() {
      _isSimulating = false;
      _hasSimulationResult = false;
      _isAccepted = null;
      _statusMessage = null;
      _simulationSteps = const [];
      _result = null;
      _isTransitioning = false;
      _pendingStepIndex = null;
    });
    _highlightService.clear();
    _replaceTapeState(
      TapeState.initial(blankSymbol: next.tm?.blankSymbol ?? '□'),
    );
  }

  Widget _buildTapePanel(BuildContext context) {
    final editorState = ref.watch(tmEditorProvider);
    final tapeAlphabet = editorState.tapeSymbols;

    return FadeTransition(
      opacity: _stepFadeAnimation,
      child: Container(
        height: 136,
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.2),
          ),
        ),
        child: TMTapePanel(
          tapeState: _currentTapeState,
          tapeAlphabet: tapeAlphabet,
          isSimulating: true,
        ),
      ),
    );
  }
}
