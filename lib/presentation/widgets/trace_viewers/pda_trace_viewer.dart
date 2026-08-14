//
//  pda_trace_viewer.dart
//  Turing Lab
//
//  Apresenta os traços de simulação de autômatos de pilha traduzindo os dados
//  retornados pelo PDASimulator em SimulationResult genérico para reutilizar o
//  BaseTraceViewer, com destaque para entrada remanescente, conteúdo da pilha e
//  transições utilizadas.
//  Harmoniza mensagens de aceitação e rejeição, integra-se ao serviço de
//  destaque do canvas e reforça convenções teóricas como λ para representar
//  cadeia vazia e pilhas descarregadas.
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

class PDATraceViewer extends StatelessWidget {
  final PDASimulationResult result;
  final SimulationHighlightService? highlightService;

  const PDATraceViewer({
    super.key,
    required this.result,
    this.highlightService,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = appLocalizationsOf(context);
    return BaseTraceViewer(
      result: _asSimulationResult(),
      title: l10n.pdaTrace(result.steps.length),
      highlightService: highlightService,
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
                  ).textTheme.bodyMedium?.copyWith(fontFamily: 'monospace'),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  // Convert PDASimulationResult to the core SimulationResult used by BaseTraceViewer.
  SimulationResult _asSimulationResult() {
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
