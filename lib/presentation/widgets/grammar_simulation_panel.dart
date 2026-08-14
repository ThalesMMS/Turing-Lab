//
//  grammar_simulation_panel.dart
//  Turing Lab
//
//  Constrói painel interativo para testar cadeias em gramáticas aplicando algoritmos como CYK e LL. Gerencia seleção de estratégia, entradas do usuário, execução assíncrona e apresentação de resultados com métricas de tempo e passos.
//
//  Thales Matheus Mendonça Santos - October 2025
//

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/algorithms/grammar_parser.dart';
import '../../core/algorithms/cfg/cyk_parser.dart';
import '../../core/models/cyk_step.dart';
import '../../core/models/grammar.dart';
import '../../core/models/grammar_parse_report.dart';
import '../../core/models/typed_algorithm_step.dart';
import '../../core/result.dart';
import '../../l10n/app_localizations_resolver.dart';
import '../../l10n/app_localizations_workflows.dart';
import '../providers/grammar_provider.dart';
import 'algorithm_step_renderer_registry.dart';
import 'base_simulation_panel.dart';
import 'derivation_tree_view.dart';
import 'grammar_sentential_form_card.dart';
import 'step_explanation_card.dart';

/// Panel for grammar parsing and string testing
class GrammarSimulationPanel extends ConsumerStatefulWidget {
  const GrammarSimulationPanel({super.key, this.useExpanded = true});

  final bool useExpanded;

  @override
  ConsumerState<GrammarSimulationPanel> createState() =>
      _GrammarSimulationPanelState();
}

class _GrammarSimulationPanelState
    extends ConsumerState<GrammarSimulationPanel> {
  final TextEditingController _inputController = TextEditingController();
  final AlgorithmStepRendererRegistry _cykStepRendererRegistry =
      AlgorithmStepRendererRegistry.withDefaults();

  bool _isParsing = false;
  GrammarParseReport? _parseReport;
  ParsingStrategyHint _selectedAlgorithm = ParsingStrategyHint.cyk;

  // Only used for CYK "with steps" mode.
  // Keeps UI changes surgical: other parsing strategies keep using GrammarParseReport.
  ({
    bool accepted,
    List<CYKStep> steps,
  })? _cykStepsResult;

  int _selectedStepIndex = 0;

  static Result<GrammarParseReport> _parseWithReportInBackground(
    ({
      Grammar grammar,
      String inputString,
      ParsingStrategyHint strategyHint,
    }) request,
  ) {
    return GrammarParser.parseWithReport(
      request.grammar,
      request.inputString,
      strategyHint: request.strategyHint,
    );
  }

  static Result<CYKParseResult> _parseCykWithStepsInBackground(
    ({
      Grammar grammar,
      String inputString,
    }) request,
  ) {
    return CYKParser.parseWithSteps(
      request.grammar,
      request.inputString,
      timeout: const Duration(seconds: 5),
    );
  }

  @override
  void dispose() {
    _inputController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeader(context),
            const SizedBox(height: 16),
            _buildAlgorithmSelector(context),
            const SizedBox(height: 16),
            _buildInputSection(context),
            const SizedBox(height: 16),
            _buildParseButton(context),
            const SizedBox(height: 16),
            _buildResultsSection(context),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    final l10n = appLocalizationsOf(context);
    return Row(
      children: [
        Icon(Icons.play_arrow, color: Theme.of(context).colorScheme.primary),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            l10n.localizeWorkflowText('Grammar Parser'),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: Theme.of(
              context,
            ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
          ),
        ),
      ],
    );
  }

  Widget _buildAlgorithmSelector(BuildContext context) {
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
          Text(
            l10n.localizeWorkflowText('Parsing Algorithm'),
            style: Theme.of(
              context,
            ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 8),
          DropdownButtonFormField<ParsingStrategyHint>(
            initialValue: _selectedAlgorithm,
            decoration: const InputDecoration(
              border: OutlineInputBorder(),
              isDense: true,
            ),
            items: GrammarParser.capabilities
                .where((capability) => capability.isAvailable)
                .map(
                  (capability) => DropdownMenuItem(
                    value: capability.strategy,
                    child: Text(l10n.localizeWorkflowText(capability.label)),
                  ),
                )
                .toList(growable: false),
            onChanged: (value) {
              if (value == null) {
                return;
              }
              setState(() {
                _selectedAlgorithm = value;
              });
            },
          ),
        ],
      ),
    );
  }

  Widget _buildInputSection(BuildContext context) {
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
          Text(
            l10n.localizeWorkflowText('Test String'),
            style: Theme.of(
              context,
            ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 8),
          TextField(
            controller: _inputController,
            decoration: InputDecoration(
              labelText: l10n.inputString,
              hintText: l10n.simulationInputHint,
              border: const OutlineInputBorder(),
            ),
            onSubmitted: (_) => _parseString(),
          ),
          const SizedBox(height: 8),
          Text(
            l10n.localizeWorkflowText(
              'Examples: aabb, abab, aabbb (for S → aSb | ab)',
            ),
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Theme.of(
                    context,
                  ).colorScheme.onSurface.withValues(alpha: 0.7),
                ),
          ),
        ],
      ),
    );
  }

  Widget _buildParseButton(BuildContext context) {
    final l10n = appLocalizationsOf(context);
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton.icon(
        onPressed: _isParsing ? null : _parseString,
        icon: _isParsing
            ? const SizedBox(
                width: 16,
                height: 16,
                child: CircularProgressIndicator(strokeWidth: 2),
              )
            : const Icon(Icons.play_arrow),
        label: Text(
          l10n.localizeWorkflowText(
            _isParsing ? 'Parsing...' : 'Parse String',
          ),
        ),
      ),
    );
  }

  Widget _buildResultsSection(BuildContext context) {
    final l10n = appLocalizationsOf(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          l10n.localizeWorkflowText('Parse Results'),
          style: Theme.of(
            context,
          ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 8),
        if (_parseReport == null)
          _buildEmptyResults(context)
        else
          _buildResults(context),
      ],
    );
  }

  Widget _buildEmptyResults(BuildContext context) {
    return const SimulationEmptyResults(
      title: 'No parse results yet',
      message: 'Enter a string and click Parse to see results',
    );
  }

  Widget _buildResults(BuildContext context) {
    final report = _parseReport!;
    final isAccepted = report.accepted;
    final colorScheme = Theme.of(context).colorScheme;
    final color = isAccepted ? colorScheme.tertiary : colorScheme.error;
    final expectedSymbols = report.expectedSymbols.toList(growable: false)
      ..sort();

    final cykSteps = _cykStepsResult?.steps;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        border: Border.all(color: color.withValues(alpha: 0.3)),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                isAccepted ? Icons.check_circle : Icons.cancel,
                color: color,
                size: 24,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  isAccepted ? 'Accepted' : 'Rejected',
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        color: color,
                        fontWeight: FontWeight.bold,
                      ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            'Execution time: ${_formatExecutionTime(report.executionTime)}',
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          if (cykSteps != null && cykSteps.isNotEmpty) ...[
            const SizedBox(height: 16),
            _buildCykStepsSection(context, cykSteps),
          ] else ...[
            if (!isAccepted) ...[
              const SizedBox(height: 8),
              Text(
                'Farthest position: ${report.farthestPosition} / ${report.inputString.length}',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              if (report.expectedSymbols.isNotEmpty) ...[
                const SizedBox(height: 8),
                Text(
                  'Expected:',
                  style: Theme.of(context)
                      .textTheme
                      .titleSmall
                      ?.copyWith(fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 4),
                Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: expectedSymbols
                      .map(
                        (s) => Chip(
                          visualDensity: VisualDensity.compact,
                          label: Text(
                            s,
                            style: Theme.of(context)
                                .textTheme
                                .bodySmall
                                ?.copyWith(fontFamily: 'monospace'),
                          ),
                        ),
                      )
                      .toList(growable: false),
                ),
              ],
              if (report.message != null) ...[
                const SizedBox(height: 8),
                Text(
                  report.message!,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Theme.of(context).colorScheme.onSurface,
                      ),
                ),
              ],
            ],
            if (isAccepted && report.trees.isNotEmpty) ...[
              const SizedBox(height: 16),
              ExpansionTile(
                initiallyExpanded: false,
                tilePadding: EdgeInsets.zero,
                title: Text(
                  report.isAmbiguous
                      ? 'Derivation Trees (showing first ${report.trees.length}; ambiguous)'
                      : 'Derivation Tree',
                  style: Theme.of(context)
                      .textTheme
                      .titleMedium
                      ?.copyWith(fontWeight: FontWeight.w600),
                ),
                children: [
                  for (final tree in report.trees)
                    Card(
                      margin: const EdgeInsets.only(top: 8),
                      child: DerivationTreeView(
                        tree: tree,
                        initiallyExpanded: true,
                      ),
                    ),
                ],
              ),
            ],
          ],
        ],
      ),
    );
  }

  Future<void> _parseString() async {
    final inputString = _inputController.text;

    final grammar = _buildCurrentGrammar();

    setState(() {
      _isParsing = true;
      _parseReport = null;
      _cykStepsResult = null;
      _selectedStepIndex = 0;
    });

    try {
      final strategyHint = _selectedAlgorithm;

      // When the user explicitly selects CYK, run the step-producing parser so we
      // can show per-step explanations and before/after highlights.
      if (strategyHint == ParsingStrategyHint.cyk) {
        final cykOutcome = await compute(_parseCykWithStepsInBackground, (
          grammar: grammar,
          inputString: inputString,
        ));

        if (!mounted) {
          return;
        }

        if (!cykOutcome.isSuccess) {
          setState(() {
            _isParsing = false;
            _parseReport = null;
            _cykStepsResult = null;
          });
          _showError(cykOutcome.error ?? 'Failed to parse string');
          return;
        }

        final cyk = cykOutcome.data!;
        setState(() {
          _isParsing = false;
          _parseReport = GrammarParseReport(
            inputString: inputString,
            accepted: cyk.accepted,
            farthestPosition: cyk.accepted ? inputString.length : 0,
            expectedSymbols: const <String>{},
            message: null,
            trees: const [],
            isAmbiguous: false,
            executionTime: cyk.executionTime,
          );
          _cykStepsResult = (accepted: cyk.accepted, steps: cyk.steps);
          _selectedStepIndex = 0;
        });
        return;
      }

      final parseOutcome = await compute(_parseWithReportInBackground, (
        grammar: grammar,
        inputString: inputString,
        strategyHint: strategyHint,
      ));

      if (!mounted) {
        return;
      }

      if (!parseOutcome.isSuccess) {
        setState(() {
          _isParsing = false;
          _parseReport = null;
          _cykStepsResult = null;
        });
        _showError(parseOutcome.error ?? 'Failed to parse string');
        return;
      }

      final report = parseOutcome.data!;

      setState(() {
        _isParsing = false;
        _parseReport = report;
        _cykStepsResult = null;
      });

      // Rejected reports render their message inline in the results panel.
    } catch (e) {
      if (!mounted) {
        return;
      }

      setState(() {
        _isParsing = false;
        _parseReport = null;
        _cykStepsResult = null;
      });

      _showError('Failed to parse string: $e');
    }
  }

  Grammar _buildCurrentGrammar() {
    return ref.read(grammarProvider.notifier).buildGrammar();
  }

  String _formatExecutionTime(Duration duration) {
    if (duration.inMicroseconds < 1000) {
      return '${duration.inMicroseconds} μs';
    }
    if (duration.inMilliseconds < 1000) {
      return '${duration.inMilliseconds} ms';
    }
    return '${duration.inSeconds}.${(duration.inMilliseconds % 1000).toString().padLeft(3, '0')} s';
  }

  Widget _buildCykStepsSection(BuildContext context, List<CYKStep> steps) {
    final selectedStep = steps[_selectedStepIndex];
    final stepExplanation = selectedStep.baseStep.stepExplanation;
    final renderedStep = _cykStepRendererRegistry.render(
      context,
      selectedStep.baseStep.copyWith(
        properties: {
          ...selectedStep.baseStep.properties,
          kCykStepKey: selectedStep,
        },
      ),
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(Icons.format_list_numbered,
                size: 18, color: Theme.of(context).colorScheme.primary),
            const SizedBox(width: 8),
            Text(
              'CYK Steps',
              style: Theme.of(context)
                  .textTheme
                  .titleMedium
                  ?.copyWith(fontWeight: FontWeight.w700),
            ),
          ],
        ),
        const SizedBox(height: 10),
        SizedBox(
          height: 44,
          child: Row(
            children: [
              IconButton(
                tooltip: appLocalizationsOf(context).previousStepLower,
                onPressed: _selectedStepIndex > 0
                    ? () => setState(() => _selectedStepIndex--)
                    : null,
                icon: const Icon(Icons.chevron_left),
              ),
              Expanded(
                child: steps.length > 1
                    ? Slider(
                        value: _selectedStepIndex.toDouble(),
                        min: 0,
                        max: (steps.length - 1).toDouble(),
                        divisions: steps.length - 1,
                        label: '${_selectedStepIndex + 1} / ${steps.length}',
                        onChanged: (v) =>
                            setState(() => _selectedStepIndex = v.round()),
                      )
                    : const SizedBox.shrink(),
              ),
              IconButton(
                tooltip: appLocalizationsOf(context).nextStepLower,
                onPressed: _selectedStepIndex < steps.length - 1
                    ? () => setState(() => _selectedStepIndex++)
                    : null,
                icon: const Icon(Icons.chevron_right),
              ),
            ],
          ),
        ),
        const SizedBox(height: 8),
        Text(
          selectedStep.baseStep.title,
          style: Theme.of(context)
              .textTheme
              .titleSmall
              ?.copyWith(fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 8),
        if (renderedStep != null)
          renderedStep
        else if (stepExplanation != null && !stepExplanation.isEmpty) ...[
          GrammarSententialFormCard(explanation: stepExplanation),
          const SizedBox(height: 8),
          StepExplanationCard(explanation: stepExplanation),
        ],
      ],
    );
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Theme.of(context).colorScheme.error,
      ),
    );
  }
}
