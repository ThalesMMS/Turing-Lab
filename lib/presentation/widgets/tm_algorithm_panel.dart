//
//  tm_algorithm_panel.dart
//  Turing Lab
//
//  Disponibiliza o painel de análises para Máquinas de Turing, reunindo botões
//  para verificações de decidibilidade, alcançabilidade, linguagem, operações de
//  fita e métricas temporais e espaciais com resultados estruturados.
//  Conecta-se ao TMEditorProvider e ao TMSimulator para executar
//  diagnósticos, mantendo estado local de foco e evitando recomputações
//  desnecessárias entre execuções.
//
//  Thales Matheus Mendonça Santos - October 2025
//
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/algorithms/tm_simulator.dart';
import '../../core/models/state.dart' as automaton_models;
import '../../core/models/simulation_highlight.dart';
import '../../core/models/tm.dart';
import '../../core/models/tm_analysis.dart';
import '../../core/models/tm_transition.dart';
import '../../core/models/asset_example.dart';
import '../../core/repositories/examples_repository.dart';
import '../../core/result.dart';
import '../../core/services/canvas_highlight_coordinator.dart';
import '../../injection/data_providers.dart';
import '../../l10n/app_localizations_resolver.dart';
import '../../l10n/app_localizations_workflows.dart';
import '../providers/tm_editor_provider.dart';
import 'algorithm_panel_scaffold.dart';
import 'app_snackbar.dart';
import 'base_simulation_panel.dart';
import 'common/algorithm_button_config.dart';
import 'file_operations_panel.dart';

enum _TMAnalysisFocus {
  decidability,
  reachability,
  language,
  tape,
  time,
  space,
}

enum _TMAnalysisSection {
  state,
  transition,
  tape,
  reachability,
  timing,
  issues,
}

/// Panel for Turing Machine analysis algorithms
class TMAlgorithmPanel extends ConsumerStatefulWidget {
  const TMAlgorithmPanel({
    super.key,
    this.useExpanded = true,
    this.examplesDataSource,
  });

  final bool useExpanded;
  final ExamplesRepository? examplesDataSource;

  @override
  ConsumerState<TMAlgorithmPanel> createState() => _TMAlgorithmPanelState();
}

class _TMAlgorithmPanelState extends ConsumerState<TMAlgorithmPanel> {
  bool _isAnalyzing = false;
  TMAnalysis? _analysis;
  String? _analysisError;
  TM? _analyzedTm;
  _TMAnalysisFocus? _currentFocus;
  String? _loadingExampleName;
  CanvasHighlightSourceHandle? _analysisHighlights;
  late final ExamplesRepository _examplesDataSource;
  late final Future<ListResult<AssetExample<TM>>> _tmExamplesFuture;

  @override
  void initState() {
    super.initState();
    _examplesDataSource =
        widget.examplesDataSource ?? ref.read(examplesRepositoryProvider);
    _tmExamplesFuture = _examplesDataSource.loadAllTypedTmExamples();
    _analysisHighlights = ref
        .read(canvasHighlightCoordinatorProvider)
        ?.source(CanvasHighlightSource.analysis);
  }

  @override
  void dispose() {
    _analysisHighlights?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final tm = ref.watch(tmEditorProvider).tm;

    return AlgorithmPanelScaffold(
      title: 'TM Analysis',
      children: [
        _buildAlgorithmButtons(context),
        _buildResultsSection(context),
        if (tm != null) ...[
          const Divider(),
          FileOperationsPanel(turingMachine: tm),
        ],
      ],
    );
  }

  Widget _buildAlgorithmButtons(BuildContext context) {
    final algorithmConfigs = _algorithmButtonConfigs();

    return Column(
      children: [
        _buildExamplesSection(context),
        const SizedBox(height: 16),
        const Divider(),
        const SizedBox(height: 16),
        AlgorithmButtonList(configs: algorithmConfigs),
      ],
    );
  }

  List<AlgorithmButtonConfig> _algorithmButtonConfigs() {
    return [
      _algorithmButtonConfig(
        title: 'Check Decidability',
        description: 'Verify halting states and potential infinite loops',
        icon: Icons.help_outline,
        focus: _TMAnalysisFocus.decidability,
      ),
      _algorithmButtonConfig(
        title: 'Find Reachable States',
        description: 'Identify which states can be reached from the start',
        icon: Icons.explore,
        focus: _TMAnalysisFocus.reachability,
      ),
      _algorithmButtonConfig(
        title: 'Language Analysis',
        description: 'Inspect accepting structure and transition coverage',
        icon: Icons.analytics,
        focus: _TMAnalysisFocus.language,
      ),
      _algorithmButtonConfig(
        title: 'Tape Operations',
        description: 'Review read/write symbols and head movements',
        icon: Icons.storage,
        focus: _TMAnalysisFocus.tape,
      ),
      _algorithmButtonConfig(
        title: 'Time Characteristics',
        description: 'Understand analysis runtime and processed elements',
        icon: Icons.timer,
        focus: _TMAnalysisFocus.time,
      ),
      _algorithmButtonConfig(
        title: 'Space Characteristics',
        description: 'Assess tape alphabet and movement coverage',
        icon: Icons.memory,
        focus: _TMAnalysisFocus.space,
      ),
    ];
  }

  AlgorithmButtonConfig _algorithmButtonConfig({
    required String title,
    required String description,
    required IconData icon,
    required _TMAnalysisFocus focus,
  }) {
    return AlgorithmButtonConfig(
      title: title,
      description: description,
      icon: icon,
      isEnabled: !_isAnalyzing,
      isExecuting: _isAnalyzing,
      isSelected: _currentFocus == focus,
      onPressed: () => _performAnalysis(focus),
    );
  }

  Widget _buildResultsSection(BuildContext context) {
    final hasData = _analysis != null || _analysisError != null;
    return AlgorithmResultsSection(
      hasResults: hasData,
      emptyBuilder: _buildEmptyResults,
      resultsBuilder: _buildResults,
    );
  }

  Widget _buildEmptyResults(BuildContext context) {
    return const SimulationEmptyResults(
      icon: Icons.analytics_outlined,
      title: 'No analysis results yet',
      message: 'Select an algorithm above to analyze your TM.',
    );
  }

  Widget _buildResults(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    if (_analysisError != null) {
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: colorScheme.error.withValues(alpha: 0.2)),
          color: colorScheme.errorContainer.withValues(alpha: 0.4),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(Icons.error_outline, color: colorScheme.error),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                appLocalizationsOf(context)
                    .localizeWorkflowText(_analysisError!),
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: colorScheme.onErrorContainer,
                    ),
              ),
            ),
          ],
        ),
      );
    }

    final analysis = _analysis;
    final tm = _analyzedTm;
    if (analysis == null || tm == null) {
      return _buildEmptyResults(context);
    }

    final reachability = analysis.reachabilityAnalysis;
    final unreachableStates = reachability.unreachableStates;
    final haltingStates = tm.acceptingStates;
    final reachableHaltingStates = haltingStates
        .where((state) => reachability.reachableStates.contains(state))
        .toSet();
    final unreachableHaltingStates = haltingStates
        .where((state) => !reachability.reachableStates.contains(state))
        .toSet();
    final potentialInfinite = _findPotentialInfiniteLoops(tm);

    final children = <Widget>[
      if (_currentFocus != null) ...[
        _buildFocusBanner(context, _currentFocus!),
        const SizedBox(height: 12),
      ],
      _buildSectionCard(
        context,
        title: 'State Analysis',
        section: _TMAnalysisSection.state,
        children: [
          _buildMetricRow(
            context,
            'Total states',
            analysis.stateAnalysis.totalStates.toString(),
          ),
          _buildMetricRow(
            context,
            'Accepting states',
            analysis.stateAnalysis.acceptingStates.toString(),
          ),
          _buildMetricRow(
            context,
            'Non-accepting states',
            analysis.stateAnalysis.nonAcceptingStates.toString(),
          ),
          _buildMetricRow(
            context,
            'Reachable halting states',
            '${reachableHaltingStates.length} of ${haltingStates.length}',
            highlight: unreachableHaltingStates.isEmpty,
            isWarning: unreachableHaltingStates.isNotEmpty,
          ),
          if (unreachableHaltingStates.isNotEmpty)
            _buildChipList(
              context,
              label: 'Halting states not reached',
              values: _formatStates(unreachableHaltingStates),
              isWarning: true,
            ),
        ],
      ),
      const SizedBox(height: 12),
      _buildSectionCard(
        context,
        title: 'Transition Analysis',
        section: _TMAnalysisSection.transition,
        children: [
          _buildMetricRow(
            context,
            'Total transitions',
            analysis.transitionAnalysis.totalTransitions.toString(),
          ),
          _buildMetricRow(
            context,
            'TM transitions',
            analysis.transitionAnalysis.tmTransitions.toString(),
          ),
          _buildMetricRow(
            context,
            'Non-TM transitions',
            analysis.transitionAnalysis.fsaTransitions.toString(),
            isError: analysis.transitionAnalysis.fsaTransitions > 0,
          ),
        ],
      ),
      const SizedBox(height: 12),
      _buildSectionCard(
        context,
        title: 'Tape Operations',
        section: _TMAnalysisSection.tape,
        children: [
          _buildChipList(
            context,
            label: 'Read symbols',
            values: _sorted(analysis.tapeAnalysis.readOperations),
          ),
          _buildChipList(
            context,
            label: 'Write symbols',
            values: _sorted(analysis.tapeAnalysis.writeOperations),
          ),
          _buildChipList(
            context,
            label: 'Move directions',
            values: _sorted(analysis.tapeAnalysis.moveDirections),
          ),
          _buildChipList(
            context,
            label: 'Tape alphabet',
            values: _sorted(analysis.tapeAnalysis.tapeSymbols),
          ),
        ],
      ),
      const SizedBox(height: 12),
      _buildSectionCard(
        context,
        title: 'Reachability',
        section: _TMAnalysisSection.reachability,
        children: [
          _buildMetricRow(
            context,
            'Reachable states',
            reachability.reachableStates.length.toString(),
          ),
          _buildChipList(
            context,
            label: 'Reachable',
            values: _formatStates(reachability.reachableStates),
          ),
          _buildMetricRow(
            context,
            'Unreachable states',
            unreachableStates.length.toString(),
            isWarning: unreachableStates.isNotEmpty,
          ),
          if (unreachableStates.isNotEmpty)
            _buildChipList(
              context,
              label: 'Unreachable',
              values: _formatStates(unreachableStates),
              isWarning: true,
            ),
        ],
      ),
      const SizedBox(height: 12),
      _buildSectionCard(
        context,
        title: 'Execution Timing',
        section: _TMAnalysisSection.timing,
        children: [
          _buildMetricRow(
            context,
            'Analysis time',
            _formatDuration(analysis.executionTime),
          ),
          _buildMetricRow(
            context,
            'States processed',
            analysis.stateAnalysis.totalStates.toString(),
          ),
          _buildMetricRow(
            context,
            'Transitions inspected',
            analysis.transitionAnalysis.totalTransitions.toString(),
          ),
        ],
      ),
      const SizedBox(height: 12),
      _buildSectionCard(
        context,
        title: 'Potential Issues',
        section: _TMAnalysisSection.issues,
        children: [
          if (unreachableStates.isEmpty && potentialInfinite.isEmpty)
            _buildStatusMessage(
              context,
              message: 'No structural issues detected.',
              isPositive: true,
            ),
          if (unreachableStates.isNotEmpty)
            _buildStatusMessage(
              context,
              message:
                  '${unreachableStates.length} state(s) cannot be reached from the initial state.',
              isWarning: true,
            ),
          if (potentialInfinite.isNotEmpty)
            _buildStatusMessage(
              context,
              message:
                  'Detected ${potentialInfinite.length} self-loop transition(s) that do not move the head.',
              isWarning: true,
            ),
          if (potentialInfinite.isNotEmpty)
            _buildChipList(
              context,
              label: 'Potentially non-halting transitions',
              values: potentialInfinite
                  .map(
                    (t) =>
                        '${t.fromState.label.isNotEmpty ? t.fromState.label : t.fromState.id} • ${t.readSymbol}→${t.writeSymbol} (${t.direction.name})',
                  )
                  .toList(),
              isWarning: true,
            ),
        ],
      ),
    ];

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: colorScheme.outline.withValues(alpha: 0.4)),
      ),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: children,
        ),
      ),
    );
  }

  Widget _buildExamplesSection(BuildContext context) {
    return AlgorithmExamplesSection<TM>(
      examplesFuture: _tmExamplesFuture,
      loadingExampleName: _loadingExampleName,
      onExampleSelected: (name) => _loadSelectedExample(name),
      failureMessage: 'Failed to load TM examples.',
      emptyMessage: 'No TM examples available.',
    );
  }

  Future<void> _loadSelectedExample(String exampleName) async {
    setState(() {
      _loadingExampleName = exampleName;
    });

    try {
      final result = await _examplesDataSource.loadTypedTmExample(exampleName);
      if (!mounted) return;

      if (result.isFailure) {
        showAppSnackBar(
          context,
          message: appLocalizationsOf(context).localizeWorkflowText(
            'Failed to load example: ${result.error}',
          ),
          tone: AppSnackBarTone.error,
        );
        return;
      }

      final tm = result.data!.payload;
      ref.read(tmEditorProvider.notifier).setTm(tm);
      showAppSnackBar(
        context,
        message: appLocalizationsOf(context)
            .localizeWorkflowText('Example loaded: ${tm.name}'),
        tone: AppSnackBarTone.success,
      );
    } catch (error) {
      showAppSnackBar(
        context,
        message: appLocalizationsOf(context)
            .localizeWorkflowText('Failed to load example: $error'),
        tone: AppSnackBarTone.error,
      );
    } finally {
      if (mounted) {
        setState(() {
          _loadingExampleName = null;
        });
      }
    }
  }

  Future<void> _performAnalysis(_TMAnalysisFocus focus) async {
    final highlights = _analysisHighlights;
    if (highlights != null) {
      highlights.clearFor(highlights.target);
    }
    setState(() {
      _isAnalyzing = true;
      _analysis = null;
      _analysisError = null;
      _currentFocus = focus;
    });

    final tm = ref.read(tmEditorProvider).tm;
    if (tm == null) {
      setState(() {
        _isAnalyzing = false;
        _analysisError =
            'No Turing machine available. Draw states and transitions on the canvas to analyze.';
      });
      return;
    }

    final Result<TMAnalysis> result;
    try {
      result = TMSimulator.analyzeTM(tm);
    } catch (error) {
      setState(() {
        _isAnalyzing = false;
        _analysisError = 'Failed to analyze the Turing machine: $error';
      });
      return;
    }

    if (!mounted) return;

    if (result.isSuccess && highlights != null) {
      highlights.sendFor(
        highlights.target,
        _highlightForAnalysis(focus, result.data!),
      );
    }

    setState(() {
      _isAnalyzing = false;
      if (result.isSuccess) {
        _analysis = result.data;
        _analyzedTm = tm;
      } else {
        _analysisError = result.error ??
            'Analysis failed due to an unknown error. Please verify the machine configuration.';
      }
    });
  }

  SimulationHighlight _highlightForAnalysis(
    _TMAnalysisFocus focus,
    TMAnalysis analysis,
  ) {
    if (focus != _TMAnalysisFocus.reachability) {
      return SimulationHighlight.empty;
    }
    return SimulationHighlight(
      stateIds: analysis.reachabilityAnalysis.reachableStates
          .map((state) => state.id)
          .toSet(),
    );
  }

  Widget _buildFocusBanner(BuildContext context, _TMAnalysisFocus focus) {
    final colorScheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: colorScheme.primaryContainer.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Icon(Icons.auto_awesome, color: colorScheme.primary),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              appLocalizationsOf(context).localizeWorkflowText(
                'Analysis focus: ${_focusLabel(focus)}',
              ),
              style: Theme.of(
                context,
              ).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }

  String _focusLabel(_TMAnalysisFocus focus) {
    switch (focus) {
      case _TMAnalysisFocus.decidability:
        return 'Decidability';
      case _TMAnalysisFocus.reachability:
        return 'Reachability';
      case _TMAnalysisFocus.language:
        return 'Language structure';
      case _TMAnalysisFocus.tape:
        return 'Tape operations';
      case _TMAnalysisFocus.time:
        return 'Time characteristics';
      case _TMAnalysisFocus.space:
        return 'Space characteristics';
    }
  }

  Widget _buildSectionCard(
    BuildContext context, {
    required String title,
    required _TMAnalysisSection section,
    required List<Widget> children,
  }) {
    final colorScheme = Theme.of(context).colorScheme;
    final highlight = _shouldHighlight(section);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: highlight
              ? colorScheme.primary
              : colorScheme.outline.withValues(alpha: 0.4),
        ),
        color: highlight
            ? colorScheme.primaryContainer.withValues(alpha: 0.35)
            : colorScheme.surface,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: Theme.of(
              context,
            ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 8),
          ...children,
        ],
      ),
    );
  }

  bool _shouldHighlight(_TMAnalysisSection section) {
    final focus = _currentFocus;
    if (focus == null) return false;

    switch (focus) {
      case _TMAnalysisFocus.decidability:
        return {
          _TMAnalysisSection.state,
          _TMAnalysisSection.reachability,
          _TMAnalysisSection.issues,
        }.contains(section);
      case _TMAnalysisFocus.reachability:
        return section == _TMAnalysisSection.reachability;
      case _TMAnalysisFocus.language:
        return {
          _TMAnalysisSection.state,
          _TMAnalysisSection.transition,
        }.contains(section);
      case _TMAnalysisFocus.tape:
        return section == _TMAnalysisSection.tape;
      case _TMAnalysisFocus.time:
        return section == _TMAnalysisSection.timing;
      case _TMAnalysisFocus.space:
        return section == _TMAnalysisSection.tape;
    }
  }

  Widget _buildMetricRow(
    BuildContext context,
    String label,
    String value, {
    bool highlight = false,
    bool isWarning = false,
    bool isError = false,
  }) {
    final colorScheme = Theme.of(context).colorScheme;
    Color? valueColor;
    if (isError) {
      valueColor = colorScheme.error;
    } else if (isWarning) {
      valueColor = colorScheme.tertiary;
    } else if (highlight) {
      valueColor = colorScheme.primary;
    }

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        children: [
          Expanded(
            child: Text(label, style: Theme.of(context).textTheme.bodyMedium),
          ),
          Text(
            value,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: valueColor,
                  fontWeight: highlight ? FontWeight.bold : null,
                ),
          ),
        ],
      ),
    );
  }

  Widget _buildChipList(
    BuildContext context, {
    required String label,
    required List<String> values,
    bool isWarning = false,
  }) {
    if (values.isEmpty) {
      return const SizedBox.shrink();
    }

    final colorScheme = Theme.of(context).colorScheme;

    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                  fontWeight: FontWeight.w600,
                ),
          ),
          const SizedBox(height: 4),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: values
                .map(
                  (value) => Chip(
                    label: Text(value),
                    backgroundColor: isWarning
                        ? colorScheme.errorContainer.withValues(alpha: 0.5)
                        : colorScheme.secondaryContainer.withValues(alpha: 0.4),
                    side: BorderSide(
                      color: isWarning
                          ? colorScheme.error
                          : colorScheme.secondary.withValues(alpha: 0.5),
                    ),
                  ),
                )
                .toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusMessage(
    BuildContext context, {
    required String message,
    bool isWarning = false,
    bool isPositive = false,
  }) {
    final colorScheme = Theme.of(context).colorScheme;
    Color? textColor;
    IconData icon;
    if (isPositive) {
      textColor = colorScheme.primary;
      icon = Icons.check_circle_outline;
    } else if (isWarning) {
      textColor = colorScheme.error;
      icon = Icons.warning_amber_outlined;
    } else {
      textColor = colorScheme.onSurfaceVariant;
      icon = Icons.info_outline;
    }

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 18, color: textColor),
          const SizedBox(width: 6),
          Expanded(
            child: Text(
              message,
              style: Theme.of(
                context,
              ).textTheme.bodySmall?.copyWith(color: textColor),
            ),
          ),
        ],
      ),
    );
  }

  List<String> _formatStates(Set<automaton_models.State> states) {
    final List<String> labels = states
        .map((state) => state.label.isNotEmpty ? state.label : state.id)
        .toList();
    labels.sort();
    return labels;
  }

  List<String> _sorted(Set<String> values) {
    final list = values.toList();
    list.sort();
    return list;
  }

  String _formatDuration(Duration duration) {
    if (duration.inMilliseconds >= 1) {
      return '${duration.inMilliseconds} ms';
    }
    if (duration.inMicroseconds >= 1) {
      return '${duration.inMicroseconds} μs';
    }
    final nanoseconds = duration.inMicroseconds * 1000;
    return '$nanoseconds ns';
  }

  List<TMTransition> _findPotentialInfiniteLoops(TM tm) {
    final transitions = tm.transitions.whereType<TMTransition>();
    return transitions
        .where(
          (transition) =>
              transition.fromState == transition.toState &&
              transition.readSymbol == transition.writeSymbol &&
              transition.direction == TapeDirection.stay,
        )
        .toList();
  }
}
