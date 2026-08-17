//
//  pda_simulation_panel.dart
//  Turing Lab
//
//  Responsável pela simulação de autômatos de pilha no aplicativo, permitindo
//  configurar cadeia de entrada, símbolo inicial da pilha, gravação de traço e
//  visualizar resultados aceitos ou rejeitados com mensagens de erro.
//  Integra-se ao PDAEditorProvider e ao serviço de destaque para sincronizar o
//  canvas, administrando controladores e estado local a fim de preservar
//  interações entre execuções.
//
//  Thales Matheus Mendonça Santos - October 2025
//
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/algorithms/pda_simulator.dart' as pda_core;
import '../../core/models/simulation_step.dart';
import '../../core/models/step_explanation.dart';
import '../../core/services/simulation_highlight_service.dart';
import '../../core/services/simulation_runner.dart';
import '../../l10n/app_localizations_resolver.dart';
import '../../l10n/app_localizations_workflows.dart';
import '../providers/pda_editor_provider.dart';
import '../providers/pda_simulation_provider.dart';
import 'base_simulation_panel.dart';
import 'trace_viewers/pda_trace_viewer.dart';
import 'pda/stack_drawer.dart';

/// Panel for PDA simulation and string testing
class PDASimulationPanel extends ConsumerStatefulWidget {
  final SimulationHighlightService? highlightService;
  final ValueChanged<StackState>? onStackChanged;
  final VoidCallback? onSimulationStart;
  final VoidCallback? onSimulationEnd;
  final SimulationRunner? simulationRunner;

  const PDASimulationPanel({
    super.key,
    this.highlightService,
    this.onStackChanged,
    this.onSimulationStart,
    this.onSimulationEnd,
    this.simulationRunner,
  });

  @override
  ConsumerState<PDASimulationPanel> createState() => _PDASimulationPanelState();
}

class _PDASimulationPanelState extends ConsumerState<PDASimulationPanel> {
  final TextEditingController _inputController = TextEditingController();
  late final SimulationHighlightService _fallbackHighlightService;
  final TextEditingController _initialStackController = TextEditingController(
    text: 'Z',
  );

  bool _isSimulating = false;
  pda_core.PDASimulationResult? _simulationResult;
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
    _inputController.dispose();
    _initialStackController.dispose();
    _fallbackHighlightService.clear();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final simState = ref.watch(pdaSimulationProvider);
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
    return SimulationInputSection(
      title: 'Simulation Input',
      children: [
        SimulationTextField(
          controller: _inputController,
          labelText: 'Input String',
          hintText: 'Leave blank for ε; whitespace is preserved',
          isDense: false,
        ),
        const SizedBox(height: 12),
        SimulationTextField(
          controller: _initialStackController,
          labelText: 'Initial Stack Symbol',
          hintText: 'e.g., Z',
          isDense: false,
        ),
        const SizedBox(height: 8),
        Material(
          type: MaterialType.transparency,
          child: SwitchListTile.adaptive(
            contentPadding: EdgeInsets.zero,
            title: Text(
              appLocalizationsOf(context)
                  .localizeWorkflowText('Record step-by-step trace'),
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
          appLocalizationsOf(context).localizeWorkflowText(
            'Examples: aabb (for balanced parentheses), abab (for palindromes)',
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
            'Current Stack State',
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
                        'Stack:',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: Theme.of(
                                context,
                              ).colorScheme.onSurface.withValues(alpha: 0.6),
                            ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        stackContents.isEmpty ? '(empty)' : stackContents,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                              fontFamily: 'monospace',
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
                                'Highlighting stack cell ${highlightedIndex + 1} (from bottom)',
                                style: Theme.of(context)
                                    .textTheme
                                    .bodySmall
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
                        'Remaining Input:',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: Theme.of(
                                context,
                              ).colorScheme.onSurface.withValues(alpha: 0.6),
                            ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        remainingInput.isEmpty ? '(empty)' : remainingInput,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                              fontFamily: 'monospace',
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
    final isAccepted = result?.accepted ?? false;
    final hasResult = result != null;
    final colorScheme = Theme.of(context).colorScheme;
    final color = isAccepted ? colorScheme.tertiary : colorScheme.error;
    final message = hasResult
        ? (isAccepted ? 'Accepted' : 'Rejected')
        : 'Simulation failed';
    final errorText = _errorMessage ?? result?.errorMessage;

    return SimulationStatusCard(
      isAccepted: hasResult ? isAccepted : false,
      message: message,
      children: [
        if (result case final simulationResult?)
          Text(
            'Time: ${simulationResult.executionTime.inMilliseconds} ms',
            style: Theme.of(context).textTheme.bodySmall,
          ),
        if (errorText != null && errorText.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(top: 4.0),
            child: Text(
              errorText,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: color,
                  ),
            ),
          ),
        if (result case final simulationResult?
            when simulationResult.steps.isNotEmpty) ...[
          const SizedBox(height: 12),
          Text(
            'Simulation Steps:',
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
        ],
      ],
    );
  }

  Future<void> _simulatePDA() async {
    final inputString = _inputController.text;
    final initialStack = _initialStackController.text.trim();

    if (initialStack.isEmpty) {
      _showError('Please enter an initial stack symbol');
      return;
    }

    final editorState = ref.read(pdaEditorProvider);
    final currentPda = editorState.pda;

    if (currentPda == null) {
      _showError('Create a PDA on the canvas before simulating.');
      return;
    }

    setState(() {
      _isSimulating = true;
      _simulationResult = null;
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
        _errorMessage = outcome.message ?? 'Simulation failed';
      });
      _highlightService.clear();
    }

    widget.onSimulationEnd?.call();
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
      _errorMessage = 'Simulation cancelled';
    });
    _highlightService.clear();
    widget.onSimulationEnd?.call();
  }

  void _updateStackState(StackState stackState) {
    widget.onStackChanged?.call(stackState);
  }

  void _updateStackFromStep(SimulationStep step) {
    final stackContents = step.stackContents;
    final symbols =
        stackContents.isEmpty ? <String>[] : stackContents.split('').toList();

    final operation = step.usedTransition ?? 'step ${step.stepNumber}';
    final operationType = _determineOperationType(step.usedTransition);

    _updateStackState(
      StackState(
        symbols: symbols,
        lastOperation: operation,
        operationType: operationType,
      ),
    );
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

  /// Determines the stack operation type from a PDA transition label
  /// Format: "input,pop→push" where ε represents epsilon
  StackOperationType _determineOperationType(String? transitionLabel) {
    if (transitionLabel == null || transitionLabel.isEmpty) {
      return StackOperationType.none;
    }

    // Parse transition label: "input,pop→push"
    final parts = transitionLabel.split(',');
    if (parts.length < 2) {
      return StackOperationType.none;
    }

    final stackPart = parts[1]; // "pop→push"
    final stackParts = stackPart.split('→');
    if (stackParts.length < 2) {
      return StackOperationType.none;
    }

    final pop = stackParts[0].trim();
    final push = stackParts[1].trim();

    // Determine operation type based on pop and push symbols
    final isPopEpsilon = pop == 'ε' || pop.isEmpty;
    final isPushEpsilon = push == 'ε' || push.isEmpty;

    if (!isPopEpsilon && !isPushEpsilon) {
      // Both pop and push - replace operation
      return StackOperationType.replace;
    } else if (!isPopEpsilon && isPushEpsilon) {
      // Only pop, no push
      return StackOperationType.pop;
    } else if (isPopEpsilon && !isPushEpsilon) {
      // Only push, no pop
      return StackOperationType.push;
    } else {
      // Both epsilon - no stack operation
      return StackOperationType.none;
    }
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
