//
//  tm_simulation_panel.dart
//  Turing Lab
//
//  Runs Turing-machine simulation for the active automaton, offering
//  input fields, run controls, and results with step history and
//  acceptance messages.
//  Talks to TMEditorProvider and SimulationHighlightService to stay in
//  sync with the canvas, clearing controllers and highlights with the
//  widget lifecycle.
//
//  Thales Matheus Mendonça Santos - October 2025
//
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../empty_string_notation.dart';

import '../../core/algorithms/tm_block_execution_engine.dart';
import '../../core/algorithms/tm_simulator.dart';
import '../../core/algorithms/tm_execution_analyzer.dart';
import '../../core/batch_execution/batch_execution.dart';
import '../../core/models/computation_branch.dart';
import '../../core/models/simulation_step.dart';
import '../../core/models/tm.dart';
import '../../core/models/tm_acceptance.dart';
import '../../core/models/tm_block_execution.dart';
import '../../core/models/tm_building_blocks.dart';
import '../../core/models/tm_execution_analysis.dart';
import '../../core/services/simulation_highlight_service.dart';
import '../../core/services/simulation_runner.dart';
import '../../l10n/app_localizations_resolver.dart';
import '../../l10n/app_localizations_structured_messages.dart';
import '../../l10n/app_localizations_workflows.dart';
import '../../l10n/tm_advanced_localizations.dart';
import '../../l10n/automata_diagnostics_localizations.dart';
import '../localization/locale_value_formatter.dart';
import '../providers/tm_editor_provider.dart';
import 'base_simulation_panel.dart';
import 'batch_execution/batch_execution_panel.dart';
import 'canvas_simulation_step_projection.dart';
import 'computation_branch_inspector.dart';
import 'tm/tape_drawer.dart';
import 'tm/multi_tape_inspector.dart';
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
  TMBlockExecutionResult? _blockResult;
  TMExecutionAnalysis? _multiTapeAnalysis;
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
    _currentTapeState = TapeState.initial(blankSymbol: tm?.blankSymbol ?? '□');
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
    final l10n = appLocalizationsOf(context);
    final tm = ref.watch(tmEditorProvider).tm;
    return SimulationPanelShell(
      children: [
        _buildHeader(context),
        const SizedBox(height: 16),
        _buildInputSection(context),
        if (tm != null) ...[
          const SizedBox(height: 12),
          _buildAcceptancePolicyControl(context, tm),
        ],
        const SizedBox(height: 16),
        _buildSimulateButton(context),
        const SizedBox(height: 16),
        _buildResultsSection(context),
        if (tm != null) ...[
          const SizedBox(height: 16),
          ExpansionTile(
            key: const Key('tm-batch-section'),
            tilePadding: EdgeInsets.zero,
            title: Text(l10n.tmAdvancedText('Batch testing')),
            subtitle: Text(
              l10n.tmAdvancedText('Run ordered, bounded TM simulations'),
            ),
            children: [
              BatchExecutionPanel(
                executor: TmBatchExecutor(
                  tm,
                  blockProject:
                      tm.blockDefinitions.isEmpty && tm.blockInvocations.isEmpty
                      ? null
                      : TMBlockProject.fromFlatMachine(tm),
                ),
                alphabet: tm.tapeAlphabet
                    .where((symbol) => symbol != tm.blankSymbol)
                    .toSet(),
                title: l10n.tmAdvancedText('TM batch execution'),
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
          hintText: EmptyStringNotation.formatTerminology(
            context,
            'Leave blank for ε; whitespace is preserved',
          ),
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

  Widget _buildAcceptancePolicyControl(BuildContext context, TM tm) {
    final l10n = appLocalizationsOf(context);
    final policy = tm.acceptancePolicy;
    return Semantics(
      label: l10n.localizeWorkflowText('Turing machine acceptance policy'),
      value: l10n.localizeWorkflowText(_policySource(policy)),
      child: DropdownButtonFormField<TMAcceptancePolicy>(
        key: const Key('tm-acceptance-policy-control'),
        initialValue: policy,
        isExpanded: true,
        decoration: InputDecoration(
          labelText: l10n.localizeWorkflowText('Acceptance policy'),
          helperText:
              '${l10n.localizeWorkflowText(_policyExplanationSource(policy))}\n'
              '${l10n.localizeWorkflowText('Saved with this TM document')}',
          helperMaxLines: 4,
          border: const OutlineInputBorder(),
        ),
        items: [
          for (final value in TMAcceptancePolicy.values)
            DropdownMenuItem(
              value: value,
              child: Text(l10n.localizeWorkflowText(_policySource(value))),
            ),
        ],
        onChanged: _isSimulating
            ? null
            : (value) {
                if (value == null) return;
                ref.read(tmEditorProvider.notifier).setAcceptancePolicy(value);
              },
      ),
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
          if (_hasSimulationResult &&
              (_result != null || _blockResult != null)) ...[
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
        children: [
          if (_resultPolicy case final policy?) ...[
            Text(
              appLocalizationsOf(context).localizeWorkflowText(
                'Policy: ${_policySource(policy)}. '
                'Reason: ${_reasonSource(_resultReason!)}.',
              ),
              key: const Key('tm-acceptance-explanation'),
            ),
            const SizedBox(height: 12),
          ],
          if (_multiTapeAnalysis case final analysis?)
            TMMultiTapeInspector(
              analysis: analysis,
              blankSymbol: ref.read(tmEditorProvider).tm?.blankSymbol ?? 'B',
            ),
          if (_hasRecordedTmResult) ...[
            const SizedBox(height: 12),
            _buildBranchAvailability(),
          ],
        ],
      );
    }

    final isAccepted = _isAccepted!;
    final message = _statusMessage ?? (isAccepted ? 'Accepted' : 'Rejected');

    return SimulationStatusCard(
      isAccepted: isAccepted,
      message: message,
      children: [
        if (_resultPolicy case final policy?) ...[
          Text(
            appLocalizationsOf(context).localizeWorkflowText(
              'Policy: ${_policySource(policy)}. '
              'Reason: ${_reasonSource(_resultReason!)}.',
            ),
            key: const Key('tm-acceptance-explanation'),
          ),
          const SizedBox(height: 12),
        ],
        if (_simulationSteps.isNotEmpty) ...[
          const SizedBox(height: 12),
          Text(
            appLocalizationsOf(
              context,
            ).localizeWorkflowText('Simulation Steps:'),
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
        if (_multiTapeAnalysis case final analysis?)
          TMMultiTapeInspector(
            analysis: analysis,
            blankSymbol: ref.read(tmEditorProvider).tm?.blankSymbol ?? 'B',
          ),
        if (_blockResult case final result?) ...[
          const SizedBox(height: 12),
          _TMBlockTrace(result: result),
        ],
        if (_hasRecordedTmResult) ...[
          const SizedBox(height: 12),
          _buildBranchAvailability(),
        ],
      ],
    );
  }

  bool get _hasRecordedTmResult =>
      _result != null || _blockResult != null || _multiTapeAnalysis != null;

  Widget _buildBranchAvailability() {
    final hasNondeterministicTransitions = ref
        .read(tmEditorProvider)
        .nondeterministicTransitionIds
        .isNotEmpty;
    return ComputationBranchesUnavailableNotice(
      key: const ValueKey('tm-computation-branches-unavailable'),
      reason: hasNondeterministicTransitions
          ? ComputationBranchesUnavailableReason.branchesNotRecorded
          : ComputationBranchesUnavailableReason.deterministicExecution,
      labels: appLocalizationsOf(context).computationBranchInspectorLabels,
    );
  }

  TMAcceptancePolicy? get _resultPolicy =>
      _result?.acceptancePolicy ??
      _blockResult?.acceptancePolicy ??
      _multiTapeAnalysis?.acceptancePolicy;

  TMAcceptanceReason? get _resultReason =>
      _result?.acceptanceReason ??
      _blockResult?.acceptanceReason ??
      _multiTapeAnalysis?.acceptanceReason;

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
      _blockResult = null;
      _multiTapeAnalysis = null;
    });
    _replaceTapeState(TapeState.initial(blankSymbol: tm.blankSymbol));

    _highlightService.clear();
    _activeTask?.cancel();
    final generation = ++_requestGeneration;

    if (tm.blockDefinitions.isNotEmpty || tm.blockInvocations.isNotEmpty) {
      await _simulateBlocks(tm, inputString, generation);
      return;
    }

    if (tm.tapeCount > 1) {
      await _simulateMultiTape(tm, inputString, generation);
      return;
    }

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
      final message = outcome.structuredMessage == null
          ? outcome.message ?? appLocalizationsOf(context).simulationFailed
          : appLocalizationsOf(
              context,
            ).resolveStructuredMessage(outcome.structuredMessage!);
      setState(() {
        _isSimulating = false;
        _hasSimulationResult = true;
        _isAccepted = null;
        _statusMessage = message;
        _simulationSteps = const [];
        _result = null;
        _blockResult = null;
        _multiTapeAnalysis = null;
      });
      _highlightService.clear();
      _showError(message);
      return;
    }

    final nextTapeState = simulation.steps.isNotEmpty
        ? projectTmTapeStep(simulation.steps[0], blankSymbol: tm.blankSymbol)
        : TapeState.initial(blankSymbol: tm.blankSymbol);
    setState(() {
      _isSimulating = false;
      _hasSimulationResult = true;
      _isAccepted = _acceptanceState(simulation.outcome);
      _statusMessage = _simulationStatus(context, simulation);
      _simulationSteps = simulation.steps;
      _result = simulation;
      _blockResult = null;
      _multiTapeAnalysis = null;
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

  Future<void> _simulateBlocks(
    TM tm,
    String inputString,
    int generation,
  ) async {
    final result = await compute(
      _executeBlockProject,
      _TMBlockSimulationRequest(tm.toJson(), inputString),
    );
    if (!mounted || generation != _requestGeneration) return;

    final accepted = _acceptanceState(result.outcome);
    setState(() {
      _isSimulating = false;
      _hasSimulationResult = true;
      _isAccepted = accepted;
      _statusMessage = result.message;
      _simulationSteps = const [];
      _result = null;
      _blockResult = result;
      _multiTapeAnalysis = null;
    });
    _highlightService.clear();
    if (result.finalTapes.isNotEmpty) {
      _replaceTapeState(
        _projectBlockTape(
          result.finalTapes.first,
          result.finalHeadPositions.first,
          tm.blankSymbol,
        ),
      );
    }
  }

  Future<void> _simulateMultiTape(
    TM tm,
    String inputString,
    int generation,
  ) async {
    final analysis = await TMExecutionAnalyzer.analyze(
      tm,
      inputString,
      includeTrace: true,
      isCancelled: () => !mounted || generation != _requestGeneration,
    );
    if (!mounted || generation != _requestGeneration) return;

    final accepted = _acceptanceState(analysis.outcome);
    setState(() {
      _isSimulating = false;
      _hasSimulationResult = true;
      _isAccepted = accepted;
      _statusMessage = _localizedExecutionMessage(context, analysis);
      _simulationSteps = const [];
      _result = null;
      _blockResult = null;
      _multiTapeAnalysis = analysis;
    });
    _highlightService.clear();
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
      _blockResult = null;
      _multiTapeAnalysis = null;
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
      projectTmTapeStep(result.steps[stepIndex], blankSymbol: blankSymbol),
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

  void _handleEditorStateChanged(TMEditorState? previous, TMEditorState next) {
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
      _blockResult = null;
      _multiTapeAnalysis = null;
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
        constraints: const BoxConstraints(minHeight: 136),
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

TMBlockExecutionResult _executeBlockProject(_TMBlockSimulationRequest request) {
  final tm = TM.fromJson(request.tmJson);
  return TMBlockExecutionEngine.execute(
    TMBlockProject.fromFlatMachine(tm),
    request.input,
  );
}

class _TMBlockSimulationRequest {
  const _TMBlockSimulationRequest(this.tmJson, this.input);

  final Map<String, dynamic> tmJson;
  final String input;
}

TapeState _projectBlockTape(
  Map<int, String> tape,
  int head,
  String blankSymbol,
) {
  final positions = <int>{head, ...tape.keys};
  final first = positions.reduce((a, b) => a < b ? a : b);
  final last = positions.reduce((a, b) => a > b ? a : b);
  return TapeState(
    cells: [
      for (var position = first; position <= last; position++)
        tape[position] ?? blankSymbol,
    ],
    headPosition: head - first,
    blankSymbol: blankSymbol,
  );
}

class _TMBlockTrace extends StatelessWidget {
  const _TMBlockTrace({required this.result});

  final TMBlockExecutionResult result;

  @override
  Widget build(BuildContext context) {
    final l10n = appLocalizationsOf(context);
    final formatter = LocaleValueFormatter.of(context);
    return Material(
      type: MaterialType.transparency,
      child: ExpansionTile(
        tilePadding: EdgeInsets.zero,
        childrenPadding: const EdgeInsetsDirectional.only(start: 12),
        title: Text(l10n.tmAdvancedText('Nested call trace')),
        subtitle: Text(
          formatter.inLocalizedTemplate(
            (entries) => formatter.inLocalizedTemplate(
              (depth) => l10n.tmBlockTraceSummary(entries, depth),
              result.metrics.maximumCallDepth,
            ),
            result.metrics.blockEntries,
          ),
        ),
        children: [
          for (final step in result.trace)
            ListTile(
              dense: true,
              leading: Icon(_blockTraceIcon(step.action)),
              title: Text(l10n.tmBlockTraceAction(_blockTraceAction(step))),
              subtitle: Text(
                '${step.machineId} · ${step.stateId}\n'
                '${l10n.tmBlockCallStackLabel(step.callStack.map((frame) => frame.invocationNodeId))}',
              ),
            ),
        ],
      ),
    );
  }
}

IconData _blockTraceIcon(TMBlockTraceAction action) => switch (action) {
  TMBlockTraceAction.enterBlock => Icons.call_made,
  TMBlockTraceAction.transition => Icons.arrow_forward,
  TMBlockTraceAction.returnFromBlock => Icons.call_received,
};

String _blockTraceAction(TMBlockTraceStep step) => switch (step.action) {
  TMBlockTraceAction.enterBlock => 'Enter ${step.targetMachineId}',
  TMBlockTraceAction.transition => 'Transition ${step.transitionId}',
  TMBlockTraceAction.returnFromBlock => 'Return to ${step.targetMachineId}',
};

bool? _acceptanceState(TMExecutionOutcome outcome) => switch (outcome) {
  TMExecutionOutcome.accepted => true,
  TMExecutionOutcome.haltedRejected || TMExecutionOutcome.provenCycle => false,
  TMExecutionOutcome.boundedUnknown ||
  TMExecutionOutcome.cancelled ||
  TMExecutionOutcome.invalidMachine => null,
};

String _simulationStatus(BuildContext context, TMSimulationResult result) {
  final l10n = appLocalizationsOf(context);
  final detail = result.structuredMessage == null
      ? result.errorMessage
      : l10n.resolveStructuredMessage(result.structuredMessage!);
  return switch (result.outcome) {
    TMExecutionOutcome.accepted => l10n.accepted,
    TMExecutionOutcome.haltedRejected =>
      detail == null || detail.isEmpty
          ? l10n.rejected
          : l10n.localizeWorkflowText('Rejected: $detail'),
    TMExecutionOutcome.provenCycle =>
      detail == null || detail.isEmpty
          ? l10n.localizeWorkflowText('Infinite loop detected')
          : detail,
    TMExecutionOutcome.boundedUnknown =>
      detail == null || detail.isEmpty
          ? l10n.localizeWorkflowText('Simulation inconclusive')
          : detail,
    TMExecutionOutcome.cancelled =>
      detail == null || detail.isEmpty
          ? l10n.localizeWorkflowText('Simulation cancelled')
          : detail,
    TMExecutionOutcome.invalidMachine =>
      detail == null || detail.isEmpty
          ? l10n.localizeWorkflowText('Invalid machine')
          : detail,
  };
}

String _localizedExecutionMessage(
  BuildContext context,
  TMExecutionAnalysis analysis,
) {
  final l10n = appLocalizationsOf(context);
  return analysis.structuredMessage == null
      ? analysis.message
      : l10n.resolveStructuredMessage(analysis.structuredMessage!);
}

String _policySource(TMAcceptancePolicy policy) => switch (policy) {
  TMAcceptancePolicy.finalState => 'Final state',
  TMAcceptancePolicy.halting => 'Halting',
  TMAcceptancePolicy.finalStateOrHalting => 'Final state or halting',
};

String _policyExplanationSource(TMAcceptancePolicy policy) => switch (policy) {
  TMAcceptancePolicy.finalState => 'Accept when a final state is entered.',
  TMAcceptancePolicy.halting =>
    'Accept when execution halts, even outside a final state.',
  TMAcceptancePolicy.finalStateOrHalting =>
    'Accept when a final state is entered or execution halts.',
};

String _reasonSource(TMAcceptanceReason reason) => switch (reason) {
  TMAcceptanceReason.enteredFinalState => 'entered a final state',
  TMAcceptanceReason.haltedInFinalState => 'halted in a final state',
  TMAcceptanceReason.haltedOutsideFinalState => 'halted outside a final state',
  TMAcceptanceReason.reachableConfigurationsExhausted =>
    'reachable configurations were exhausted',
  TMAcceptanceReason.deterministicCycle => 'an exact configuration repeated',
  TMAcceptanceReason.stepLimit => 'the step limit was reached',
  TMAcceptanceReason.configurationLimit =>
    'the configuration limit was reached',
  TMAcceptanceReason.timeout => 'the timeout was reached',
  TMAcceptanceReason.cancelled => 'the simulation was cancelled',
  TMAcceptanceReason.invalidMachine => 'the machine is invalid',
};
