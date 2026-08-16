//
//  tm_trace_viewer.dart
//  Turing Lab
//
//  Renderiza os traços de simulação de Máquinas de Turing convertendo o
//  resultado especializado do simulador em um SimulationResult genérico para o
//  BaseTraceViewer, com suporte a destaques de fita, transições e estados.
//  Normaliza mensagens de erro para diferenciar rejeições, timeouts e laços
//  infinitos, oferecendo uma apresentação consistente reaproveitável em qualquer
//  tela que consuma execuções de TM.
//
//  Thales Matheus Mendonça Santos - October 2025
//
import 'package:flutter/material.dart';

import '../../../core/algorithms/tm_simulator.dart';
import '../../../core/models/simulation_result.dart';
import '../../../core/models/simulation_step.dart';
import '../../../core/services/simulation_highlight_service.dart';
import '../../../l10n/app_localizations_resolver.dart';
import 'base_trace_viewer.dart';

class TMTraceViewer extends StatefulWidget {
  final TMSimulationResult result;
  final SimulationHighlightService? highlightService;
  final void Function(int stepIndex)? onStepChanged;

  const TMTraceViewer({
    super.key,
    required this.result,
    this.highlightService,
    this.onStepChanged,
  });

  @override
  State<TMTraceViewer> createState() => _TMTraceViewerState();
}

class _TMTraceViewerState extends State<TMTraceViewer> {
  SimulationResult? _adaptedResult;
  String? _adaptedRejectedLabel;

  @override
  void didUpdateWidget(covariant TMTraceViewer oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!identical(widget.result, oldWidget.result)) {
      _adaptedResult = null;
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = appLocalizationsOf(context);
    // The adapted result bakes in the localized fallback, so a locale change
    // has to invalidate the cache even when the result itself is unchanged.
    if (_adaptedRejectedLabel != l10n.rejected) {
      _adaptedResult = null;
      _adaptedRejectedLabel = l10n.rejected;
    }
    _adaptedResult ??= _asSimulationResult(
      widget.result,
      l10n.rejected,
    );
    return BaseTraceViewer(
      result: _adaptedResult!,
      title: l10n.tmTrace(widget.result.steps.length),
      highlightService: widget.highlightService,
      onStepChanged: widget.onStepChanged,
      buildStepLine: (SimulationStep step, int index) {
        final tape = step.tapeContents.isEmpty ? '□' : step.tapeContents;
        final transition =
            step.usedTransition != null ? ' | δ: ${step.usedTransition}' : '';
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
                  'q=${step.currentState} | ${l10n.traceTape}=$tape$transition',
                  style: Theme.of(
                    context,
                  ).textTheme.bodyMedium?.copyWith(fontFamily: 'monospace'),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  SimulationResult _asSimulationResult(
    TMSimulationResult result,
    String rejectedMessage,
  ) {
    final errorMessage = result.errorMessage ?? '';

    if (result.accepted) {
      return SimulationResult.success(
        inputString: result.inputString,
        steps: result.steps,
        executionTime: result.executionTime,
      );
    }

    final normalizedMessage = errorMessage.toLowerCase();
    if (normalizedMessage.contains('timeout')) {
      return SimulationResult.timeout(
        inputString: result.inputString,
        steps: result.steps,
        executionTime: result.executionTime,
      );
    }

    if (normalizedMessage.contains('infinite')) {
      return SimulationResult.infiniteLoop(
        inputString: result.inputString,
        steps: result.steps,
        executionTime: result.executionTime,
      );
    }

    final failureMessage =
        errorMessage.isNotEmpty ? errorMessage : rejectedMessage;

    return SimulationResult.failure(
      inputString: result.inputString,
      steps: result.steps,
      errorMessage: failureMessage,
      executionTime: result.executionTime,
    );
  }
}
