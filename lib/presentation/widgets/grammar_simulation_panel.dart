//
//  grammar_simulation_panel.dart
//  Turing Lab
//
//  Builds an interactive panel to test strings against grammars using
//  algorithms such as CYK and LL. Manages strategy selection, user input,
//  async execution, and result presentation with time and step metrics.
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
import '../../core/models/ll1_parse_step.dart';
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
import '../../core/constants/monospace_typography.dart';

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
            l10n.grammarParserExamplesHint,
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
          _isParsing ? l10n.parsingEllipsis : l10n.parseString,
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
    return SimulationEmptyResults(
      title: appLocalizationsOf(context).noParseResultsYet,
      message: appLocalizationsOf(context).enterAStringAndClickParse,
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
    final ll1Steps = report.ll1Steps;

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
                  isAccepted
                      ? appLocalizationsOf(context).accepted
                      : appLocalizationsOf(context).rejected,
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
            appLocalizationsOf(context).executionTimeLabel(
              _formatExecutionTime(report.executionTime),
            ),
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          if (cykSteps != null && cykSteps.isNotEmpty) ...[
            const SizedBox(height: 16),
            _buildCykStepsSection(context, cykSteps),
          ] else ...[
            if (ll1Steps.isNotEmpty) ...[
              const SizedBox(height: 16),
              _buildLl1StepsSection(context, ll1Steps),
            ],
            if (!isAccepted) ...[
              const SizedBox(height: 8),
              Text(
                appLocalizationsOf(context).farthestPositionLabel(
                  report.farthestPosition,
                  report.inputString.length,
                ),
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              if (report.expectedSymbols.isNotEmpty) ...[
                const SizedBox(height: 8),
                Text(
                  appLocalizationsOf(context).expectedColon,
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
                                ?.copyWith(
                                    fontFamilyFallback:
                                        kMonospaceFontFamilyFallback),
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
                      ? appLocalizationsOf(context).derivationTreesAmbiguous(
                          report.trees.length,
                        )
                      : appLocalizationsOf(context).derivationTree,
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
          _showError(
            cykOutcome.error ?? appLocalizationsOf(context).failedToParseString,
          );
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
        _showError(
          parseOutcome.error ?? appLocalizationsOf(context).failedToParseString,
        );
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

      _showError(
        appLocalizationsOf(context).failedToParseStringError('$e'),
      );
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
              appLocalizationsOf(context).cykSteps,
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

  Widget _buildLl1StepsSection(
    BuildContext context,
    List<LL1ParseStep> steps,
  ) {
    final l10n = appLocalizationsOf(context);
    final selectedStep = steps[_selectedStepIndex];
    final production = selectedStep.productionDisplay;
    final expected = selectedStep.expectedTerminals.toList()..sort();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(
              Icons.format_list_numbered,
              size: 18,
              color: Theme.of(context).colorScheme.primary,
            ),
            const SizedBox(width: 8),
            Text(
              l10n.localizeWorkflowText('LL(1) Steps'),
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
                tooltip: l10n.previousStepLower,
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
                        onChanged: (value) => setState(
                          () => _selectedStepIndex = value.round(),
                        ),
                      )
                    : const SizedBox.shrink(),
              ),
              IconButton(
                tooltip: l10n.nextStepLower,
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
          l10n.localizeWorkflowText(selectedStep.title),
          style: Theme.of(context)
              .textTheme
              .titleSmall
              ?.copyWith(fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 8),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Theme.of(context)
                .colorScheme
                .tertiaryContainer
                .withValues(alpha: 0.2),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color:
                  Theme.of(context).colorScheme.tertiary.withValues(alpha: 0.3),
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildLl1StepRow(
                context,
                label: l10n.localizeWorkflowText('Stack'),
                value: selectedStep.stack.join(' '),
              ),
              _buildLl1StepRow(
                context,
                label: l10n.localizeWorkflowText('Remaining input'),
                value: selectedStep.remainingInput.join(' '),
              ),
              _buildLl1StepRow(
                context,
                label: l10n.localizeWorkflowText('Lookahead'),
                value: selectedStep.lookahead,
              ),
              if (production != null)
                _buildLl1StepRow(
                  context,
                  label: l10n.localizeWorkflowText('Production'),
                  value: production,
                ),
              if (expected.isNotEmpty)
                _buildLl1StepRow(
                  context,
                  label: l10n.localizeWorkflowText('Expected'),
                  value: expected.join(', '),
                ),
              Text(
                l10n.localizeWorkflowText(selectedStep.message),
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildLl1StepRow(
    BuildContext context, {
    required String label,
    required String value,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              label,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              value,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    fontFamilyFallback: kMonospaceFontFamilyFallback,
                  ),
            ),
          ),
        ],
      ),
    );
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          appLocalizationsOf(context).localizeWorkflowText(message),
        ),
        backgroundColor: Theme.of(context).colorScheme.error,
      ),
    );
  }
}
