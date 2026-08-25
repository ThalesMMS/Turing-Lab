//
//  pda_trace_viewer.dart
//  Turing Lab
//
//  Presents PDA simulation traces by translating PDASimulator data into a
//  generic SimulationResult so BaseTraceViewer can be reused, highlighting
//  remaining input, stack contents, and used transitions.
//  Harmonizes accept/reject messages, integrates with the canvas
//  highlight service, and reinforces theoretical conventions such as λ
//  for the empty string and emptied stacks.
//
//  Thales Matheus Mendonça Santos - October 2025
//
import 'package:flutter/material.dart';

import '../../../core/algorithms/pda_simulator.dart';
import '../../../core/models/simulation_result.dart';
import '../../../core/models/simulation_step.dart';
import '../../../core/services/simulation_highlight_service.dart';
import '../../../l10n/app_localizations_resolver.dart';
import 'base_trace_viewer.dart';
import '../../../core/constants/monospace_typography.dart';

class PDATraceViewer extends StatefulWidget {
  final PDASimulationResult result;
  final SimulationHighlightService? highlightService;
  final ValueChanged<int>? onStepChanged;

  const PDATraceViewer({
    super.key,
    required this.result,
    this.highlightService,
    this.onStepChanged,
  });

  @override
  State<PDATraceViewer> createState() => _PDATraceViewerState();
}

class _PDATraceViewerState extends State<PDATraceViewer> {
  late SimulationResult _adaptedResult;

  @override
  void initState() {
    super.initState();
    _adaptedResult = _asSimulationResult(widget.result);
  }

  @override
  void didUpdateWidget(covariant PDATraceViewer oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!identical(widget.result, oldWidget.result)) {
      _adaptedResult = _asSimulationResult(widget.result);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = appLocalizationsOf(context);
    return BaseTraceViewer(
      result: _adaptedResult,
      title: l10n.pdaTrace(widget.result.steps.length),
      highlightService: widget.highlightService,
      onStepChanged: widget.onStepChanged,
      buildStepLine: (SimulationStep step, int index) {
        final remaining =
            step.remainingInput.isEmpty ? 'λ' : step.remainingInput;
        final stack = step.stackContents.isEmpty ? 'λ' : step.stackContents;
        final transition =
            step.usedTransition != null ? ' | ${step.usedTransition}' : '';
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surface,
            borderRadius: BorderRadius.circular(4),
          ),
          child: Row(
            children: [
              Text(
                '${index + 1}.',
                style: Theme.of(
                  context,
                ).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.bold),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'q=${step.currentState} | ${l10n.traceRemaining}=$remaining | '
                  '${l10n.traceStack}=$stack$transition',
                  style: Theme.of(
                    context,
                  ).textTheme.bodyMedium?.copyWith(
                      fontFamilyFallback: kMonospaceFontFamilyFallback),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  // Convert PDASimulationResult to the core SimulationResult used by BaseTraceViewer.
  SimulationResult _asSimulationResult(PDASimulationResult result) {
    if (result.accepted) {
      return SimulationResult.success(
        inputString: result.inputString,
        steps: result.steps,
        executionTime: result.executionTime,
      );
    }

    return SimulationResult.failure(
      inputString: result.inputString,
      steps: result.steps,
      errorMessage: result.errorMessage ?? '',
      executionTime: result.executionTime,
    );
  }
}
