//
//  simulation_panel.dart
//  Turing Lab
//
//  Constrói o painel de simulação de autômatos com entrada textual, botões de
//  execução e modos passo a passo que descrevem cada transição realizada e o
//  restante da cadeia processada.
//  Gerencia timers, destaques compartilhados com o canvas e renderização de
//  resultados aceitos ou rejeitados, permitindo alternar entre reprodução
//  automática e navegação manual pelas etapas.
//
//  Thales Matheus Mendonça Santos - October 2025
//
import 'dart:async';

import 'package:flutter/material.dart';
import '../../core/models/simulation_result.dart';
import '../../core/services/simulation_highlight_service.dart';
import '../../l10n/app_localizations_resolver.dart';
import 'base_simulation_panel.dart';
import 'common/simulation_speed_control.dart';
import 'common/simulation_result_card.dart';
import 'trace_viewers/fsa_trace_viewer.dart';

/// Panel for automaton simulation
class SimulationPanel extends StatefulWidget {
  final FutureOr<void> Function(String) onSimulate;
  final SimulationResult? simulationResult;
  final String? regexResult;
  final SimulationHighlightService? highlightService;
  final double animationSpeed;
  final ValueChanged<double>? onAnimationSpeedChanged;

  const SimulationPanel({
    super.key,
    required this.onSimulate,
    this.simulationResult,
    this.regexResult,
    this.highlightService,
    this.animationSpeed = 1.0,
    this.onAnimationSpeedChanged,
  });

  @override
  State<SimulationPanel> createState() => _SimulationPanelState();
}

class _SimulationPanelState extends State<SimulationPanel> {
  final TextEditingController _inputController = TextEditingController();
  late final SimulationHighlightService _fallbackHighlightService;
  bool _isSimulating = false;
  bool _isStepByStep = false;
  int _simulationGeneration = 0;

  SimulationHighlightService get _highlightService =>
      widget.highlightService ?? _fallbackHighlightService;

  @override
  void initState() {
    super.initState();
    _fallbackHighlightService = SimulationHighlightService();
  }

  @override
  void didUpdateWidget(covariant SimulationPanel oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.highlightService != widget.highlightService) {
      (oldWidget.highlightService ?? _fallbackHighlightService).clear();
    }
  }

  @override
  void dispose() {
    _simulationGeneration++;
    _inputController.dispose();
    _fallbackHighlightService.clear();
    super.dispose();
  }

  Future<void> _simulate() async {
    final inputString = _inputController.text;
    final generation = ++_simulationGeneration;
    setState(() {
      _isSimulating = true;
    });

    _highlightService.clear();

    try {
      await widget.onSimulate(inputString);
    } catch (_) {
      // The owning workflow surfaces its own error state. Loading still belongs
      // to this request and must finish when its callback fails.
    } finally {
      if (mounted && generation == _simulationGeneration) {
        setState(() {
          _isSimulating = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = appLocalizationsOf(context);
    return SimulationPanelShell(
      focusTraversal: true,
      children: [
        SimulationPanelHeader(title: l10n.simulation),
        const SizedBox(height: 16),
        SimulationTextField(
          controller: _inputController,
          labelText: l10n.inputString,
          hintText: l10n.simulationInputHint,
          semanticsLabel: l10n.simulationInputString,
          excludeSemantics: true,
          onSubmitted: _simulate,
        ),
        const SizedBox(height: 12),
        SimulationRunButton(
          isSimulating: _isSimulating,
          label: l10n.simulate,
          onPressed: _simulate,
          iconSize: 18,
          padding: const EdgeInsets.symmetric(vertical: 12),
          excludeSemantics: true,
          semanticsLabel: l10n.runSimulation,
        ),
        const SizedBox(height: 12),
        _buildStepByStepControls(context),
        if (widget.simulationResult != null)
          SimulationResultsSection(
            title: l10n.simulationResult,
            child: SimulationResultCard(result: widget.simulationResult!),
          ),
        if (_isStepByStep &&
            !_isSimulating &&
            widget.simulationResult != null &&
            widget.simulationResult!.steps.isNotEmpty) ...[
          const SizedBox(height: 16),
          FsaTraceViewer(
            result: widget.simulationResult!,
            highlightService: _highlightService,
            animationSpeed: widget.animationSpeed,
          ),
        ],
        if (widget.regexResult != null) ...[
          const SizedBox(height: 16),
          SimulationResultsSection(
            title: l10n.regexResult,
            child: _buildRegexResultCard(context, widget.regexResult!),
          ),
        ],
      ],
    );
  }

  Widget _buildRegexResultCard(BuildContext context, String regex) {
    final colorScheme = Theme.of(context).colorScheme;
    final l10n = appLocalizationsOf(context);

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: colorScheme.primary.withValues(alpha: 0.1),
        border: Border.all(color: colorScheme.primary.withValues(alpha: 0.3)),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.text_fields, color: colorScheme.primary, size: 20),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  l10n.regularExpression,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        color: colorScheme.primary,
                        fontWeight: FontWeight.bold,
                      ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: colorScheme.surface,
              borderRadius: BorderRadius.circular(4),
              border: Border.all(color: colorScheme.outline),
            ),
            child: Text(
              regex,
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    fontFamily: 'monospace',
                    fontWeight: FontWeight.bold,
                  ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStepByStepControls(BuildContext context) {
    final l10n = appLocalizationsOf(context);
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.play_circle_outline,
                color: Theme.of(context).colorScheme.primary,
                size: 20,
              ),
              const SizedBox(width: 8),
              Flexible(
                child: Text(
                  l10n.stepByStepMode,
                  style: Theme.of(
                    context,
                  ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: 8),
              Semantics(
                label: l10n.stepByStepModeSemantics,
                hint: l10n.stepByStepToggleHint,
                value: _isStepByStep ? l10n.on : l10n.off,
                enabled: true,
                excludeSemantics: true,
                child: Switch(
                  value: _isStepByStep,
                  onChanged: (value) {
                    setState(() {
                      _isStepByStep = value;
                    });
                    if (!value) _highlightService.clear();
                  },
                ),
              ),
            ],
          ),
          if (_isStepByStep && widget.onAnimationSpeedChanged != null) ...[
            const SizedBox(height: 12),
            SimulationSpeedControl(
              currentSpeed: widget.animationSpeed,
              onSpeedChanged: widget.onAnimationSpeedChanged!,
            ),
          ],
        ],
      ),
    );
  }
}
