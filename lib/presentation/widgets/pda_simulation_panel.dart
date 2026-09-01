//
//  pda_simulation_panel.dart
//  Turing Lab
//
//  Handles pushdown-automaton simulation in the app, allowing input
//  string and initial stack symbol configuration, trace recording, and
//  accepted/rejected results with error messages.
//  Integrates with PDAEditorProvider and the highlight service to sync
//  the canvas, managing controllers and local state so interactions
//  survive across runs.
//
//  Thales Matheus Mendonça Santos - October 2025
//
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/algorithms/pda_simulator.dart' as pda_core;
import '../../core/batch_execution/batch_execution.dart';
import '../../core/models/computation_branch.dart';
import '../../core/models/simulation_step.dart';
import '../../core/models/step_explanation.dart';
import '../../core/services/simulation_highlight_service.dart';
import '../../core/services/simulation_runner.dart';
import '../../l10n/app_localizations_resolver.dart';
import '../../l10n/app_localizations_structured_messages.dart';
import '../../l10n/app_localizations_workflows.dart';
import '../../l10n/automata_diagnostics_localizations.dart';
import '../empty_string_notation.dart';
import '../providers/pda_editor_provider.dart';
import '../providers/pda_simulation_provider.dart';
import 'base_simulation_panel.dart';
import 'batch_execution/batch_execution_panel.dart';
import 'canvas_simulation_step_projection.dart';
import 'computation_branch_inspector.dart';
import 'trace_viewers/pda_trace_viewer.dart';
import 'pda/stack_drawer.dart';
import 'pda_acceptance_mode_control.dart';
import '../../core/constants/monospace_typography.dart';

/// Panel for PDA simulation and string testing
class PDASimulationPanel extends ConsumerStatefulWidget {
  final SimulationHighlightService? highlightService;
  final ValueChanged<StackState>? onStackChanged;
  final VoidCallback? onSimulationStart;
  final VoidCallback? onSimulationEnd;
  final SimulationRunner? simulationRunner;
  final ValueChanged<List<SimulationStep>>? onViewOnCanvas;

  const PDASimulationPanel({
    super.key,
    this.highlightService,
    this.onStackChanged,
    this.onSimulationStart,
    this.onSimulationEnd,
    this.simulationRunner,
    this.onViewOnCanvas,
  });

  @override
  ConsumerState<PDASimulationPanel> createState() => _PDASimulationPanelState();
}

class _PDASimulationPanelState extends ConsumerState<PDASimulationPanel> {
  final TextEditingController _inputController = TextEditingController();
  late final SimulationHighlightService _fallbackHighlightService;
  late final TextEditingController _initialStackController;
  ProviderSubscription<PDAEditorState>? _editorSubscription;

  bool _isSimulating = false;
  pda_core.PDASimulationResult? _simulationResult;
  SimulationOutcomeKind? _outcomeKind;
  String? _errorMessage;
  bool _stepByStep = true;
  late final SimulationRunner _simulationRunner;
  SimulationTask<pda_core.PDASimulationResult>? _activeTask;
  int _requestGeneration = 0;

  SimulationHighlightService get _highlightService =>
      widget.highlightService ?? _fallbackHighlightService;

  @override
  void initState() {
    super.initState();
    _initialStackController = TextEditingController(
      text: ref.read(pdaEditorProvider).pda?.initialStackSymbol ?? 'Z',
    );
    _editorSubscription = ref.listenManual<PDAEditorState>(
      pdaEditorProvider,
      _handleEditorStateChanged,
    );
    _fallbackHighlightService = SimulationHighlightService();
    _simulationRunner = widget.simulationRunner ?? SimulationRunner();
  }

  @override
  void didUpdateWidget(covariant PDASimulationPanel oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.highlightService != widget.highlightService) {
      _fallbackHighlightService.clear();
    }
  }

  @override
  void dispose() {
    _activeTask?.cancel();
    _editorSubscription?.close();
    _inputController.dispose();
    _initialStackController.dispose();
    _fallbackHighlightService.clear();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final simState = ref.watch(pdaSimulationProvider);
    final pda = ref.watch(pdaEditorProvider).pda;
    final hasSteps = simState.result?.steps.isNotEmpty == true;

    return SimulationPanelShell(
      children: [
        _buildHeader(context),
        const SizedBox(height: 16),
        _buildInputSection(context),
        const SizedBox(height: 16),
        _buildSimulateButton(context),
        if (hasSteps) ...[
          const SizedBox(height: 16),
          _buildStackPreview(context, simState),
        ],
        const SizedBox(height: 16),
        _buildResultsSection(context),
        if (pda != null) ...[
          const SizedBox(height: 16),
          ExpansionTile(
            key: const Key('pda-batch-section'),
            tilePadding: EdgeInsets.zero,
            title: const Text('Batch testing'),
            subtitle: const Text('Run ordered, bounded PDA simulations'),
            children: [
              BatchExecutionPanel(
                executor: PdaBatchExecutor(pda),
                alphabet: pda.alphabet,
                title: 'PDA batch execution',
                initialStrategyId: 'simulate',
              ),
            ],
          ),
        ],
      ],
    );
  }

  Widget _buildHeader(BuildContext context) {
    return const SimulationPanelHeader(
      title: 'PDA Simulation',
      icon: Icons.play_arrow,
    );
  }

  Widget _buildInputSection(BuildContext context) {
    final pda = ref.watch(pdaEditorProvider).pda;
    return LayoutBuilder(
      builder: (context, constraints) {
        final useDenseFields =
            constraints.maxWidth < PdaAcceptanceModeControl.narrowBreakpoint;
        return SimulationInputSection(
          title: 'Simulation Input',
          children: [
            if (pda != null) ...[
              PdaAcceptanceModeControl(
                value: pda.acceptanceMode,
                enabled: !_isSimulating,
                onChanged: _setAcceptanceMode,
              ),
              const SizedBox(height: 16),
            ],
            SimulationTextField(
              controller: _inputController,
              labelText: 'Input String',
              hintText: EmptyStringNotation.formatTerminology(
                context,
                'Leave blank for ε; whitespace is preserved',
              ),
              isDense: useDenseFields,
            ),
            const SizedBox(height: 12),
            SimulationTextField(
              controller: _initialStackController,
              labelText: 'Initial Stack Symbol',
              hintText: appLocalizationsOf(context).egInitialStack,
              isDense: useDenseFields,
            ),
            const SizedBox(height: 8),
            Material(
              type: MaterialType.transparency,
              child: SwitchListTile.adaptive(
                contentPadding: EdgeInsets.zero,
                title: Text(
                  appLocalizationsOf(
                    context,
                  ).localizeWorkflowText('Record step-by-step trace'),
                ),
                value: _stepByStep,
                onChanged: (value) {
                  setState(() {
                    _stepByStep = value;
                  });
                },
              ),
            ),
            const SizedBox(height: 8),
            Text(
              appLocalizationsOf(context).pdaExamplesHint,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Theme.of(
                  context,
                ).colorScheme.onSurface.withValues(alpha: 0.7),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildSimulateButton(BuildContext context) {
    return SimulationRunButton(
      isSimulating: _isSimulating,
      label: 'Simulate PDA',
      onPressed: _simulatePDA,
      onCancel: _cancelSimulation,
    );
  }

  Widget _buildStackPreview(BuildContext context, PDASimulationState simState) {
    final stackContents = simState.currentStackContents;
    final remainingInput = simState.currentRemainingInput ?? '';
    final highlightedIndex = _inferHighlightedStackIndex(simState.currentStep);

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            appLocalizationsOf(context).currentStackState,
            style: Theme.of(
              context,
            ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.surface,
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(
                      color: Theme.of(
                        context,
                      ).colorScheme.outline.withValues(alpha: 0.2),
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '${appLocalizationsOf(context).pdaStackPanelLabel}:',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Theme.of(
                            context,
                          ).colorScheme.onSurface.withValues(alpha: 0.6),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        stackContents.isEmpty
                            ? appLocalizationsOf(context).emptyParen
                            : stackContents,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                          fontFamilyFallback: kMonospaceFontFamilyFallback,
                          fontWeight: FontWeight.bold,
                          color: Theme.of(context).colorScheme.primary,
                        ),
                      ),
                      if (highlightedIndex != null) ...[
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            Icon(
                              Icons.highlight,
                              size: 16,
                              color: Theme.of(context).colorScheme.tertiary,
                            ),
                            const SizedBox(width: 6),
                            Expanded(
                              child: Text(
                                appLocalizationsOf(
                                  context,
                                ).highlightingStackCell(highlightedIndex + 1),
                                style: Theme.of(context).textTheme.bodySmall
                                    ?.copyWith(
                                      color: Theme.of(context)
                                          .colorScheme
                                          .onSurface
                                          .withValues(alpha: 0.7),
                                    ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.surface,
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(
                      color: Theme.of(
                        context,
                      ).colorScheme.outline.withValues(alpha: 0.2),
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        appLocalizationsOf(context).remainingInputColon,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Theme.of(
                            context,
                          ).colorScheme.onSurface.withValues(alpha: 0.6),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        remainingInput.isEmpty
                            ? appLocalizationsOf(context).emptyParen
                            : remainingInput,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                          fontFamilyFallback: kMonospaceFontFamilyFallback,
                          fontWeight: FontWeight.bold,
                          color: Theme.of(context).colorScheme.secondary,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  int? _inferHighlightedStackIndex(SimulationStep? step) {
    if (step == null) return null;
    final explanation = step.explanation;
    if (explanation == null) return null;

    final highlight = explanation.highlights.firstWhere(
      (h) => h.type == HighlightTargetType.pdaStack,
      orElse: () => const HighlightTarget(type: HighlightTargetType.none),
    );

    final data = highlight.data;
    if (data.isEmpty) return null;
    final index = data['index'];
    if (index is int) return index;
    return null;
  }

  Widget _buildResultsSection(BuildContext context) {
    return SimulationResultsSection(
      title: 'Simulation Results',
      child: _simulationResult == null && _errorMessage == null
          ? _buildEmptyResults(context)
          : _buildResults(context),
    );
  }

  Widget _buildEmptyResults(BuildContext context) {
    return const SimulationEmptyResults();
  }

  Widget _buildResults(BuildContext context) {
    final result = _simulationResult;
    final acceptanceMode = ref.read(pdaSimulationProvider).mode;
    final l10n = appLocalizationsOf(context);
    final isAccepted = result?.accepted ?? false;
    final hasResult = result != null;
    final semanticResult = switch (_outcomeKind) {
      SimulationOutcomeKind.accepted => true,
      SimulationOutcomeKind.rejected => false,
      _ => null,
    };
    final colorScheme = Theme.of(context).colorScheme;
    final color = isAccepted ? colorScheme.tertiary : colorScheme.error;
    final message = hasResult
        ? switch (_outcomeKind) {
            SimulationOutcomeKind.accepted => 'Accepted',
            SimulationOutcomeKind.rejected => 'Rejected',
            SimulationOutcomeKind.provenCycle => 'Cycle detected',
            SimulationOutcomeKind.boundedUnknown ||
            SimulationOutcomeKind.timeout ||
            SimulationOutcomeKind.configurationLimit => 'Inconclusive',
            SimulationOutcomeKind.cancelled => 'Simulation cancelled',
            SimulationOutcomeKind.failed || null => 'Simulation failed',
          }
        : appLocalizationsOf(context).simulationFailed;
    final errorText = _errorMessage ?? result?.errorMessage;

    return SimulationStatusCard(
      isAccepted: hasResult ? semanticResult : false,
      message: message,
      children: [
        if (result != null)
          Padding(
            padding: const EdgeInsets.only(bottom: 4),
            child: Text(
              '${l10n.acceptanceModeLabel(pdaAcceptanceModeLabel(context, acceptanceMode))}\n'
              '${pdaAcceptanceModeExplanation(context, acceptanceMode)}',
              key: const ValueKey('pda-simulation-acceptance-rule'),
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ),
        if (result case final simulationResult?)
          Text(
            appLocalizationsOf(
              context,
            ).timeMs(simulationResult.executionTime.inMilliseconds),
            style: Theme.of(context).textTheme.bodySmall,
          ),
        if (errorText != null && errorText.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(top: 4.0),
            child: Text(
              errorText,
              style: Theme.of(
                context,
              ).textTheme.bodyMedium?.copyWith(color: color),
            ),
          ),
        if (result != null) ...[
          const SizedBox(height: 12),
          ComputationBranchesUnavailableNotice(
            key: const ValueKey('pda-computation-branches-unavailable'),
            reason:
                ref
                    .read(pdaEditorProvider)
                    .nondeterministicTransitionIds
                    .isEmpty
                ? ComputationBranchesUnavailableReason.deterministicExecution
                : ComputationBranchesUnavailableReason.branchesNotRecorded,
            labels: appLocalizationsOf(
              context,
            ).computationBranchInspectorLabels,
          ),
        ],
        if (result case final simulationResult?
            when simulationResult.steps.isNotEmpty) ...[
          const SizedBox(height: 12),
          Text(
            appLocalizationsOf(context).simulationSteps,
            style: Theme.of(
              context,
            ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 8),
          PDATraceViewer(
            result: simulationResult,
            highlightService: _highlightService,
            onStepChanged: _handleTraceStepChanged,
          ),
          if (_stepByStep && widget.onViewOnCanvas != null) ...[
            const SizedBox(height: 12),
            SimulationViewOnCanvasButton(
              onPressed: () => widget.onViewOnCanvas!(
                List<SimulationStep>.unmodifiable(simulationResult.steps),
              ),
            ),
          ],
        ],
      ],
    );
  }

  Future<void> _simulatePDA() async {
    final inputString = _inputController.text;
    final initialStack = _initialStackController.text.trim();

    if (initialStack.isEmpty) {
      _showError(appLocalizationsOf(context).pleaseEnterInitialStackSymbol);
      return;
    }

    final editorState = ref.read(pdaEditorProvider);
    final currentPda = editorState.pda;

    if (currentPda == null) {
      _showError(appLocalizationsOf(context).createPdaBeforeSimulating);
      return;
    }

    setState(() {
      _isSimulating = true;
      _simulationResult = null;
      _outcomeKind = null;
      _errorMessage = null;
    });

    _highlightService.clear();
    widget.onSimulationStart?.call();
    _activeTask?.cancel();
    final generation = ++_requestGeneration;

    // Initialize stack with initial symbol
    _updateStackState(
      StackState(
        symbols: [initialStack],
        lastOperation: 'initialize',
        operationType: StackOperationType.push,
      ),
    );

    final stackAlphabet = {...currentPda.stackAlphabet};
    stackAlphabet.add(initialStack);

    final simulationPda = currentPda.copyWith(
      stackAlphabet: stackAlphabet,
      initialStackSymbol: initialStack,
    );

    final task = _simulationRunner.runPda(
      simulationPda,
      inputString,
      stepByStep: _stepByStep,
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
    if (simulation != null) {
      setState(() {
        _isSimulating = false;
        _simulationResult = simulation;
        _outcomeKind = outcome.kind;
        _errorMessage = simulation.errorMessage?.isNotEmpty == true
            ? simulation.errorMessage
            : null;
      });
      if (simulation.steps.isNotEmpty) {
        // Sync with simulation provider for step controls
        final simNotifier = ref.read(pdaSimulationProvider.notifier);
        simNotifier.setPda(simulationPda);
        simNotifier.setStepByStep(_stepByStep);
        simNotifier.setResult(simulation);

        _highlightService.emitFromSteps(simulation.steps, 0);
        _updateStackFromStep(simulation.steps.first);
      } else {
        _highlightService.clear();
      }
    } else {
      setState(() {
        _isSimulating = false;
        _simulationResult = null;
        _outcomeKind = SimulationOutcomeKind.failed;
        _errorMessage = outcome.structuredMessage == null
            ? outcome.message ?? appLocalizationsOf(context).simulationFailed
            : appLocalizationsOf(
                context,
              ).resolveStructuredMessage(outcome.structuredMessage!);
      });
      _highlightService.clear();
    }

    widget.onSimulationEnd?.call();
  }

  void _setAcceptanceMode(PDAAcceptanceMode mode) {
    ref.read(pdaEditorProvider.notifier).setAcceptanceMode(mode);
  }

  void _handleEditorStateChanged(
    PDAEditorState? previous,
    PDAEditorState next,
  ) {
    if (!mounted || identical(previous?.pda, next.pda)) return;

    _initialStackController.text = next.pda?.initialStackSymbol ?? 'Z';
    final wasSimulating = _isSimulating;
    _requestGeneration++;
    _activeTask?.cancel();
    _activeTask = null;
    setState(() {
      _isSimulating = false;
      _simulationResult = null;
      _outcomeKind = null;
      _errorMessage = null;
    });
    final simulationNotifier = ref.read(pdaSimulationProvider.notifier);
    final pda = next.pda;
    if (pda == null) {
      simulationNotifier.clear();
    } else {
      simulationNotifier.setPda(pda);
    }
    _highlightService.clear();
    _updateStackState(const StackState.empty());
    if (wasSimulating) widget.onSimulationEnd?.call();
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
      _simulationResult = null;
      _outcomeKind = SimulationOutcomeKind.cancelled;
      _errorMessage = appLocalizationsOf(context).simulationCancelled;
    });
    _highlightService.clear();
    widget.onSimulationEnd?.call();
  }

  void _updateStackState(StackState stackState) {
    widget.onStackChanged?.call(stackState);
  }

  void _updateStackFromStep(SimulationStep step) {
    _updateStackState(projectPdaStackStep(step));
  }

  void _handleTraceStepChanged(int stepIndex) {
    final result = _simulationResult;
    if (result == null || stepIndex < 0 || stepIndex >= result.steps.length) {
      return;
    }

    final simState = ref.read(pdaSimulationProvider);
    if (!identical(simState.result, result)) return;
    if (simState.currentStepIndex != stepIndex) {
      ref.read(pdaSimulationProvider.notifier).goToStep(stepIndex);
    }
    _updateStackFromStep(result.steps[stepIndex]);
  }

  void _showError(String message) {
    setState(() {
      _errorMessage = message;
      _simulationResult = null;
    });
    _highlightService.clear();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Theme.of(context).colorScheme.error,
      ),
    );
  }
}
