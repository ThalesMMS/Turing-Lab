//
//  tm_algorithm_panel.dart
//  Turing Lab
//
//  Provides the analysis panel for Turing Machines, gathering buttons for
//  termination, reachability, language, tape operations, and time/space
//  metrics with structured results.
//  Connects to TMEditorProvider and the typed service for each analysis,
//  discarding results when the edited machine is no longer the source of
//  the run.
//
//  Thales Matheus Mendonça Santos - October 2025
//
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/algorithms/tm_execution_analyzer.dart';
import '../../core/algorithms/tm_reachability_analyzer.dart';
import '../../core/algorithms/tm_language_explorer.dart';
import '../../core/algorithms/tm_space_profiler.dart';
import '../../core/algorithms/tm_time_profiler.dart';
import '../../core/models/simulation_highlight.dart';
import '../../core/models/simulation_step.dart';
import '../../core/models/tm.dart';
import '../../core/models/tm_execution_analysis.dart';
import '../../core/models/tm_reachability_report.dart';
import '../../core/models/tm_language_explorer_models.dart';
import '../../core/models/tm_space_profile.dart';
import '../../core/models/tm_time_profile.dart';
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
  termination,
  reachability,
  language,
  tape,
  time,
  space,
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
  static const _terminationMaxSteps = 10000;
  static const _terminationMaxConfigurations = 100000;
  static const _terminationTimeout = Duration(seconds: 5);
  static const _languageDefaultMaxLength = 2;
  static const _languageDefaultCandidateCap = 50;
  static const _spaceDefaultMaxLength = 2;
  static const _spaceDefaultCandidatesPerLength = 20;
  static const _profileMaxSteps = 50000;
  static const _profileMaxConfigurations = 100000;
  static const _profileTimeout = Duration(seconds: 5);

  bool _isAnalyzing = false;
  TMExecutionAnalysis? _terminationAnalysis;
  TMReachabilityReport? _reachabilityReport;
  TMLanguageExplorerReport? _languageReport;
  TMLanguageExplorerProgress? _languageProgress;
  TMLanguageWordResult? _selectedLanguageWord;
  TMExecutionAnalysis? _selectedLanguageTrace;
  TMSpaceProfileReport? _spaceProfileReport;
  TMSpaceProfileProgress? _spaceProfileProgress;
  TMTimeProfileReport? _timeProfile;
  String? _analysisError;
  TM? _analyzedTm;
  _TMAnalysisFocus? _currentFocus;
  String? _loadingExampleName;
  CanvasHighlightSourceHandle? _analysisHighlights;
  ProviderSubscription<TMEditorState>? _tmEditorSubscription;
  late final ExamplesRepository _examplesDataSource;
  late final Future<ListResult<AssetExample<TM>>> _tmExamplesFuture;
  final TextEditingController _terminationInputController =
      TextEditingController();
  final TextEditingController _reachabilityInputsController =
      TextEditingController();
  final TextEditingController _languageMaxLengthController =
      TextEditingController(text: '$_languageDefaultMaxLength');
  final TextEditingController _languageCandidateCapController =
      TextEditingController(text: '$_languageDefaultCandidateCap');
  final TextEditingController _languageMaxStepsController =
      TextEditingController(text: '10000');
  final TextEditingController _languageMaxConfigurationsController =
      TextEditingController(text: '100000');
  final TextEditingController _languageTimeoutMsController =
      TextEditingController(text: '5000');
  TMLanguageExplorerCancellationToken? _languageCancellation;
  bool _isLoadingLanguageTrace = false;
  final TextEditingController _spaceMaxLengthController =
      TextEditingController(text: '$_spaceDefaultMaxLength');
  final TextEditingController _spaceCandidateCapController =
      TextEditingController(text: '$_spaceDefaultCandidatesPerLength');
  final TextEditingController _spaceMaxStepsController =
      TextEditingController(text: '10000');
  final TextEditingController _spaceMaxConfigurationsController =
      TextEditingController(text: '100000');
  final TextEditingController _spaceTimeoutMsController =
      TextEditingController(text: '5000');
  final TextEditingController _profileMaxLengthController =
      TextEditingController(text: '4');
  final TextEditingController _profileCandidateCapController =
      TextEditingController(text: '64');
  bool _cancelRequested = false;
  double _profileProgress = 0;
  String? _profileProgressLabel;
  String? _operationProgressLabel;
  int _analysisGeneration = 0;
  TM? _observedTm;

  @override
  void initState() {
    super.initState();
    _examplesDataSource =
        widget.examplesDataSource ?? ref.read(examplesRepositoryProvider);
    _tmExamplesFuture = _examplesDataSource.loadAllTypedTmExamples();
    _analysisHighlights = ref
        .read(canvasHighlightCoordinatorProvider)
        ?.source(CanvasHighlightSource.analysis);
    _observedTm = ref.read(tmEditorProvider).tm;
    _tmEditorSubscription = ref.listenManual<TMEditorState>(
      tmEditorProvider,
      (previous, next) {
        if (identical(_observedTm, next.tm)) return;
        _observedTm = next.tm;
        _invalidateAnalysisForEditorChange();
      },
    );
  }

  @override
  void dispose() {
    _analysisGeneration++;
    _cancelRequested = true;
    _languageCancellation?.cancel();
    _tmEditorSubscription?.close();
    _analysisHighlights?.dispose();
    _terminationInputController.dispose();
    _reachabilityInputsController.dispose();
    _languageMaxLengthController.dispose();
    _languageCandidateCapController.dispose();
    _languageMaxStepsController.dispose();
    _languageMaxConfigurationsController.dispose();
    _languageTimeoutMsController.dispose();
    _spaceMaxLengthController.dispose();
    _spaceCandidateCapController.dispose();
    _spaceMaxStepsController.dispose();
    _spaceMaxConfigurationsController.dispose();
    _spaceTimeoutMsController.dispose();
    _profileMaxLengthController.dispose();
    _profileCandidateCapController.dispose();
    super.dispose();
  }

  void _invalidateAnalysisForEditorChange() {
    _analysisGeneration++;
    _cancelRequested = true;
    _languageCancellation?.cancel();
    _languageCancellation = null;
    final highlights = _analysisHighlights;
    if (highlights != null) {
      highlights.clearFor(highlights.target);
    }
    if (!mounted) return;
    setState(() {
      _isAnalyzing = false;
      _clearAnalysisOutputs();
    });
  }

  void _clearAnalysisOutputs() {
    _terminationAnalysis = null;
    _reachabilityReport = null;
    _languageReport = null;
    _languageProgress = null;
    _selectedLanguageWord = null;
    _selectedLanguageTrace = null;
    _isLoadingLanguageTrace = false;
    _spaceProfileReport = null;
    _spaceProfileProgress = null;
    _timeProfile = null;
    _analysisError = null;
    _analyzedTm = null;
    _currentFocus = null;
    _profileProgress = 0;
    _profileProgressLabel = null;
    _operationProgressLabel = null;
  }

  bool _isCurrentAnalysis(int generation, TM tm) {
    return mounted &&
        generation == _analysisGeneration &&
        identical(_observedTm, tm);
  }

  bool _isAnalysisCancelled(int generation, TM tm) {
    return _cancelRequested || !_isCurrentAnalysis(generation, tm);
  }

  @override
  Widget build(BuildContext context) {
    final tm = ref.watch(tmEditorProvider).tm;

    return AlgorithmPanelScaffold(
      title: 'TM Analysis',
      children: [
        _buildAlgorithmButtons(context, tm),
        _buildResultsSection(context),
        if (tm != null) ...[
          const Divider(),
          FileOperationsPanel(turingMachine: tm),
        ],
      ],
    );
  }

  Widget _buildAlgorithmButtons(BuildContext context, TM? tm) {
    final algorithmConfigs = _algorithmButtonConfigs();

    return Column(
      children: [
        _buildExamplesSection(context),
        const SizedBox(height: 16),
        const Divider(),
        const SizedBox(height: 16),
        _buildExecutionControls(context, tm),
        const SizedBox(height: 12),
        _buildLanguageExplorerControls(context, tm),
        const SizedBox(height: 12),
        _buildSpaceProfilerControls(context, tm),
        const SizedBox(height: 12),
        AlgorithmButtonList(configs: algorithmConfigs),
      ],
    );
  }

  List<AlgorithmButtonConfig> _algorithmButtonConfigs() {
    return [
      _algorithmButtonConfig(
        title: 'Termination and Cycles',
        description: 'Classify one input under explicit execution limits',
        icon: Icons.fact_check_outlined,
        focus: _TMAnalysisFocus.termination,
      ),
      _algorithmButtonConfig(
        title: 'Reachability',
        description: 'Compare structural reachability with bounded witnesses',
        icon: Icons.explore,
        focus: _TMAnalysisFocus.reachability,
      ),
      _algorithmButtonConfig(
        title: 'Language Explorer',
        description: 'Classify a bounded shortlex sample into four outcomes',
        icon: Icons.manage_search,
        focus: _TMAnalysisFocus.language,
      ),
      _algorithmButtonConfig(
        title: 'Tape Trace',
        description: 'Measure operations on one concrete execution branch',
        icon: Icons.storage,
        focus: _TMAnalysisFocus.tape,
      ),
      _algorithmButtonConfig(
        title: 'Time Profile',
        description: 'Measure transition steps by input length within bounds',
        icon: Icons.timer,
        focus: _TMAnalysisFocus.time,
      ),
      _algorithmButtonConfig(
        title: 'Space Profile',
        description: 'Measure bounded tape-cell usage by input length',
        icon: Icons.memory,
        focus: _TMAnalysisFocus.space,
      ),
    ];
  }

  Widget _buildExecutionControls(BuildContext context, TM? tm) {
    final localizations = appLocalizationsOf(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        TextField(
          key: const Key('tm-termination-input'),
          controller: _terminationInputController,
          enabled: !_isAnalyzing,
          decoration: InputDecoration(
            labelText: localizations.localizeWorkflowText(
              'Execution input for termination and tape analysis',
            ),
            helperText: localizations.localizeWorkflowText(
              'Leave empty to analyze the empty string.',
            ),
            border: const OutlineInputBorder(),
          ),
        ),
        const SizedBox(height: 12),
        TextField(
          key: const Key('tm-reachability-inputs'),
          controller: _reachabilityInputsController,
          enabled: !_isAnalyzing,
          decoration: InputDecoration(
            labelText: localizations.localizeWorkflowText(
              'Reachability input scope',
            ),
            helperText: localizations.localizeWorkflowText(
              'Separate inputs with commas; use ε for the empty string.',
            ),
            border: const OutlineInputBorder(),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          localizations.localizeWorkflowText(
            'Limits: 10,000 steps, 100,000 configurations, 5 seconds',
          ),
          style: Theme.of(context).textTheme.bodySmall,
        ),
        if (_isAnalyzing &&
            (_currentFocus == _TMAnalysisFocus.termination ||
                _currentFocus == _TMAnalysisFocus.tape ||
                _currentFocus == _TMAnalysisFocus.reachability) &&
            _operationProgressLabel != null) ...[
          const SizedBox(height: 4),
          Text(
            _operationProgressLabel!,
            key: const Key('tm-operation-progress'),
            style: Theme.of(context).textTheme.bodySmall,
          ),
        ],
        const SizedBox(height: 16),
        Text(
          localizations.localizeWorkflowText('Bounded time-profile scope'),
          style: Theme.of(context)
              .textTheme
              .titleSmall
              ?.copyWith(fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: TextField(
                key: const Key('tm-time-profile-max-length'),
                controller: _profileMaxLengthController,
                enabled: !_isAnalyzing,
                keyboardType: TextInputType.number,
                onChanged: (_) => setState(() {}),
                decoration: InputDecoration(
                  labelText: localizations.localizeWorkflowText(
                    'Maximum input length',
                  ),
                  border: const OutlineInputBorder(),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: TextField(
                key: const Key('tm-time-profile-candidate-cap'),
                controller: _profileCandidateCapController,
                enabled: !_isAnalyzing,
                keyboardType: TextInputType.number,
                onChanged: (_) => setState(() {}),
                decoration: InputDecoration(
                  labelText: localizations.localizeWorkflowText(
                    'Candidate limit per length',
                  ),
                  border: const OutlineInputBorder(),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        _buildProfilePlanSummary(context, tm),
        if (_isAnalyzing) ...[
          const SizedBox(height: 8),
          OutlinedButton.icon(
            key: const Key('tm-analysis-cancel'),
            onPressed: _cancelRequested
                ? null
                : () {
                    setState(() {
                      _cancelRequested = true;
                      _languageCancellation?.cancel();
                    });
                  },
            icon: const Icon(Icons.stop_circle_outlined),
            label: Text(
              localizations.localizeWorkflowText(
                _cancelRequested
                    ? 'Cancelling analysis…'
                    : _currentFocus == _TMAnalysisFocus.language
                        ? 'Cancel exploration'
                        : 'Cancel analysis',
              ),
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildLanguageExplorerControls(BuildContext context, TM? tm) {
    final maxLength = int.tryParse(_languageMaxLengthController.text);
    final candidateCap = int.tryParse(_languageCandidateCapController.text);
    BigInt? requested;
    if (maxLength != null && maxLength >= 0) {
      requested = TMLanguageExplorer.countCandidates(
        tm?.alphabet ?? const <String>{},
        maxLength,
      );
    }
    final planned =
        requested == null || candidateCap == null || candidateCap <= 0
            ? null
            : requested > BigInt.from(candidateCap)
                ? candidateCap
                : requested.toInt();
    final progress = _languageProgress;

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        border: Border.all(
          color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.4),
        ),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            appLocalizationsOf(context)
                .localizeWorkflowText('Language explorer limits'),
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _languageLimitField(
                key: const Key('tm-language-max-length'),
                controller: _languageMaxLengthController,
                label: 'Max input length',
              ),
              _languageLimitField(
                key: const Key('tm-language-candidate-cap'),
                controller: _languageCandidateCapController,
                label: 'Candidate cap',
              ),
              _languageLimitField(
                key: const Key('tm-language-max-steps'),
                controller: _languageMaxStepsController,
                label: 'Steps per input',
              ),
              _languageLimitField(
                key: const Key('tm-language-max-configurations'),
                controller: _languageMaxConfigurationsController,
                label: 'Configurations per input',
              ),
              _languageLimitField(
                key: const Key('tm-language-timeout-ms'),
                controller: _languageTimeoutMsController,
                label: 'Timeout per input (ms)',
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            requested == null || planned == null
                ? 'Estimated candidates: invalid limits'
                : 'Estimated candidates: $requested; scheduled: $planned',
            key: const Key('tm-language-candidate-estimate'),
            style: Theme.of(context).textTheme.bodySmall,
          ),
          if (_isAnalyzing &&
              _currentFocus == _TMAnalysisFocus.language &&
              progress != null) ...[
            const SizedBox(height: 8),
            LinearProgressIndicator(
              key: const Key('tm-language-progress'),
              value: progress.fraction.clamp(0, 1),
            ),
            const SizedBox(height: 4),
            Text(
              'Evaluated ${progress.evaluatedCandidates} of '
              '${progress.plannedCandidates}',
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ],
        ],
      ),
    );
  }

  Widget _languageLimitField({
    required Key key,
    required TextEditingController controller,
    required String label,
  }) {
    return SizedBox(
      width: 170,
      child: TextField(
        key: key,
        controller: controller,
        enabled: !_isAnalyzing,
        keyboardType: TextInputType.number,
        onChanged: (_) => setState(() {}),
        decoration: InputDecoration(
          labelText: appLocalizationsOf(context).localizeWorkflowText(label),
          border: const OutlineInputBorder(),
          isDense: true,
        ),
      ),
    );
  }

  Widget _buildSpaceProfilerControls(BuildContext context, TM? tm) {
    final maxLength = int.tryParse(_spaceMaxLengthController.text);
    final candidateCap = int.tryParse(_spaceCandidateCapController.text);
    BigInt? requested;
    int? scheduled;
    if (maxLength != null &&
        maxLength >= 0 &&
        candidateCap != null &&
        candidateCap > 0) {
      final alphabet = tm?.alphabet ?? const <String>{};
      requested = TMSpaceProfiler.countCandidatesThroughLength(
        alphabet,
        maxLength,
      );
      scheduled = TMSpaceProfiler.countScheduledCandidates(
        alphabet,
        TMSpaceProfileLimits(
          maxInputLength: maxLength,
          maxCandidatesPerLength: candidateCap,
        ),
      );
    }
    final progress = _spaceProfileProgress;
    final localizations = appLocalizationsOf(context);

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        border: Border.all(
          color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.4),
        ),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            localizations.localizeWorkflowText('Space profiler limits'),
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _spaceLimitField(
                key: const Key('tm-space-max-length'),
                controller: _spaceMaxLengthController,
                label: 'Max input length',
              ),
              _spaceLimitField(
                key: const Key('tm-space-candidate-cap'),
                controller: _spaceCandidateCapController,
                label: 'Candidates per length',
              ),
              _spaceLimitField(
                key: const Key('tm-space-max-steps'),
                controller: _spaceMaxStepsController,
                label: 'Steps per input',
              ),
              _spaceLimitField(
                key: const Key('tm-space-max-configurations'),
                controller: _spaceMaxConfigurationsController,
                label: 'Configurations per input',
              ),
              _spaceLimitField(
                key: const Key('tm-space-timeout-ms'),
                controller: _spaceTimeoutMsController,
                label: 'Timeout per input (ms)',
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            requested == null || scheduled == null
                ? 'Estimated candidates: invalid limits'
                : 'Estimated candidates: $requested; scheduled: $scheduled',
            key: const Key('tm-space-candidate-estimate'),
            style: Theme.of(context).textTheme.bodySmall,
          ),
          if (_isAnalyzing &&
              _currentFocus == _TMAnalysisFocus.space &&
              progress != null) ...[
            const SizedBox(height: 8),
            LinearProgressIndicator(
              key: const Key('tm-space-progress'),
              value: progress.fraction.clamp(0, 1),
            ),
            const SizedBox(height: 4),
            Text(
              'Evaluated ${progress.evaluatedCandidates} of '
              '${progress.scheduledCandidates}',
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ],
        ],
      ),
    );
  }

  Widget _spaceLimitField({
    required Key key,
    required TextEditingController controller,
    required String label,
  }) {
    return SizedBox(
      width: 170,
      child: TextField(
        key: key,
        controller: controller,
        enabled: !_isAnalyzing,
        keyboardType: TextInputType.number,
        onChanged: (_) => setState(() {}),
        decoration: InputDecoration(
          labelText: appLocalizationsOf(context).localizeWorkflowText(label),
          border: const OutlineInputBorder(),
          isDense: true,
        ),
      ),
    );
  }

  TMTimeProfileBounds? _profileBounds() {
    final maxLength = int.tryParse(_profileMaxLengthController.text.trim());
    final candidateCap = int.tryParse(
      _profileCandidateCapController.text.trim(),
    );
    if (maxLength == null || candidateCap == null) return null;
    return TMTimeProfileBounds(
      maxLength: maxLength,
      maxCandidatesPerLength: candidateCap,
      maxStepsPerCandidate: _profileMaxSteps,
      maxConfigurationsPerCandidate: _profileMaxConfigurations,
      timeoutPerCandidate: _profileTimeout,
    );
  }

  Widget _buildProfilePlanSummary(BuildContext context, TM? tm) {
    final localizations = appLocalizationsOf(context);
    final bounds = _profileBounds();
    if (bounds == null) {
      return Text(
        localizations.localizeWorkflowText(
          'Enter integer bounds to calculate the candidate plan.',
        ),
        style: Theme.of(context).textTheme.bodySmall,
      );
    }
    if (tm == null) {
      return Text(
        localizations.localizeWorkflowText(
          'Candidate counts appear after a Turing machine is available.',
        ),
        style: Theme.of(context).textTheme.bodySmall,
      );
    }
    final plan = TMTimeProfiler.plan(tm, bounds: bounds);
    if (!plan.isValid) {
      return Text(
        localizations.localizeWorkflowText(plan.validationError!),
        style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: Theme.of(context).colorScheme.error,
            ),
      );
    }
    final rows = plan.rows.map((row) {
      if (row.isSampled) {
        return 'n=${row.inputLength}: ${row.candidateCount}/'
            '${row.possibleCandidateCount} sampled';
      }
      return 'n=${row.inputLength}: ${row.candidateCount} exhaustive';
    }).join(' • ');
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '${localizations.localizeWorkflowText('Planned candidates')}: '
          '${plan.plannedCandidateCount}',
          key: const Key('tm-time-profile-planned-count'),
          style: Theme.of(context).textTheme.bodySmall,
        ),
        const SizedBox(height: 2),
        Text(
          rows,
          key: const Key('tm-time-profile-plan-rows'),
          style: Theme.of(context).textTheme.bodySmall,
        ),
        const SizedBox(height: 2),
        Text(
          localizations.localizeWorkflowText(
            'Per candidate: 50,000 transition steps, 100,000 configurations, 5 seconds',
          ),
          key: const Key('tm-time-profile-budgets'),
          style: Theme.of(context).textTheme.bodySmall,
        ),
      ],
    );
  }

  AlgorithmButtonConfig _algorithmButtonConfig({
    required String title,
    required String description,
    required IconData icon,
    required _TMAnalysisFocus focus,
  }) {
    final isActive = _isAnalyzing && _currentFocus == focus;
    final executionProgress = switch (focus) {
      _TMAnalysisFocus.language =>
        _languageProgress?.fraction.clamp(0, 1).toDouble(),
      _TMAnalysisFocus.time => _profileProgress,
      _TMAnalysisFocus.space =>
        _spaceProfileProgress?.fraction.clamp(0, 1).toDouble(),
      _TMAnalysisFocus.termination ||
      _TMAnalysisFocus.reachability ||
      _TMAnalysisFocus.tape =>
        null,
    };
    final executionStatus = switch (focus) {
      _TMAnalysisFocus.language when _languageProgress != null =>
        'Evaluated ${_languageProgress!.evaluatedCandidates} of '
            '${_languageProgress!.plannedCandidates}',
      _TMAnalysisFocus.space when _spaceProfileProgress != null =>
        'Evaluated ${_spaceProfileProgress!.evaluatedCandidates} of '
            '${_spaceProfileProgress!.scheduledCandidates}',
      _TMAnalysisFocus.time => _profileProgressLabel,
      _TMAnalysisFocus.termination ||
      _TMAnalysisFocus.reachability ||
      _TMAnalysisFocus.tape =>
        _operationProgressLabel,
      _ => null,
    };
    return AlgorithmButtonConfig(
      title: title,
      description: description,
      icon: icon,
      isEnabled: !_isAnalyzing,
      isExecuting: isActive,
      isSelected: _currentFocus == focus,
      executionProgress: isActive ? executionProgress : null,
      executionStatus: isActive ? executionStatus : null,
      onPressed: () => _performAnalysis(focus),
    );
  }

  Widget _buildResultsSection(BuildContext context) {
    final hasData = _terminationAnalysis != null ||
        _reachabilityReport != null ||
        _languageReport != null ||
        _spaceProfileReport != null ||
        _timeProfile != null ||
        _analysisError != null;
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

    final terminationAnalysis = _terminationAnalysis;
    if (_currentFocus == _TMAnalysisFocus.termination &&
        terminationAnalysis != null) {
      return _buildTerminationResults(context, terminationAnalysis);
    }
    if (_currentFocus == _TMAnalysisFocus.tape && terminationAnalysis != null) {
      return _buildTapeOperationResults(context, terminationAnalysis);
    }

    final spaceReport = _spaceProfileReport;
    if (_currentFocus == _TMAnalysisFocus.space && spaceReport != null) {
      return _buildSpaceProfileResults(context, spaceReport);
    }

    final reachabilityReport = _reachabilityReport;
    if (_currentFocus == _TMAnalysisFocus.reachability &&
        reachabilityReport != null) {
      return _buildReachabilityResults(context, reachabilityReport);
    }

    final languageReport = _languageReport;
    if (_currentFocus == _TMAnalysisFocus.language && languageReport != null) {
      return _buildLanguageResults(context, languageReport);
    }

    final timeProfile = _timeProfile;
    if (_currentFocus == _TMAnalysisFocus.time && timeProfile != null) {
      return _buildTimeProfileResults(context, timeProfile);
    }
    return _buildEmptyResults(context);
  }

  Widget _buildTerminationResults(
    BuildContext context,
    TMExecutionAnalysis analysis,
  ) {
    final colorScheme = Theme.of(context).colorScheme;
    final outcomeLabel = switch (analysis.outcome) {
      TMExecutionOutcome.accepted => 'Accepted',
      TMExecutionOutcome.haltedRejected => 'Halted and rejected',
      TMExecutionOutcome.provenCycle => 'Proven cycle',
      TMExecutionOutcome.boundedUnknown => 'Inconclusive within limits',
      TMExecutionOutcome.cancelled => 'Cancelled',
      TMExecutionOutcome.invalidMachine => 'Invalid machine or input',
    };
    final positive = analysis.outcome == TMExecutionOutcome.accepted;
    final warning = analysis.outcome == TMExecutionOutcome.provenCycle ||
        analysis.outcome == TMExecutionOutcome.boundedUnknown;
    final cycle = analysis.cycle;
    final cycleTrace = cycle == null
        ? const <SimulationStep>[]
        : analysis.trace
            .where(
              (step) =>
                  step.stepNumber >= cycle.startStep &&
                  step.stepNumber <= cycle.startStep + cycle.period,
            )
            .toList(growable: false);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: colorScheme.outline.withValues(alpha: 0.4)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildFocusBanner(context, _TMAnalysisFocus.termination),
          const SizedBox(height: 12),
          _buildStatusMessage(
            context,
            message: '$outcomeLabel. ${analysis.message}',
            isPositive: positive,
            isWarning: warning,
          ),
          const SizedBox(height: 8),
          _buildMetricRow(
            context,
            'Input',
            analysis.input.isEmpty ? 'ε' : analysis.input,
          ),
          _buildMetricRow(
            context,
            'Conclusion',
            analysis.isExact ? 'Exact for this input' : 'Bounded',
          ),
          _buildMetricRow(
            context,
            'Transitions executed',
            analysis.stepsExecuted.toString(),
          ),
          _buildMetricRow(
            context,
            'Configurations explored',
            analysis.configurationsExplored.toString(),
          ),
          _buildMetricRow(
            context,
            'Step limit',
            analysis.maxSteps.toString(),
          ),
          _buildMetricRow(
            context,
            'Configuration limit',
            analysis.maxConfigurations.toString(),
          ),
          _buildMetricRow(
            context,
            'Time limit',
            '${analysis.timeout.inSeconds} s',
          ),
          if (analysis.limit != null)
            _buildMetricRow(
              context,
              'Limit reached',
              analysis.limit!.name,
              isWarning: true,
            ),
          if (cycle != null) ...[
            _buildMetricRow(
              context,
              'Cycle start',
              'Step ${cycle.startStep}',
              isWarning: true,
            ),
            _buildMetricRow(
              context,
              'Cycle period',
              '${cycle.period} transition(s)',
              isWarning: true,
            ),
            _buildMetricRow(
              context,
              'Repeated state',
              cycle.configuration.stateId,
              isWarning: true,
            ),
            _buildMetricRow(
              context,
              'Repeated head position',
              cycle.configuration.headPosition.toString(),
              isWarning: true,
            ),
            _buildChipList(
              context,
              label: 'Repeated nonblank tape cells',
              values: [
                for (final entry in cycle.configuration.nonBlankCells.entries)
                  '${entry.key}: ${entry.value}',
              ],
              isWarning: true,
            ),
            if (cycleTrace.isNotEmpty)
              Material(
                color: Colors.transparent,
                child: ExpansionTile(
                  key: const Key('tm-cycle-trace'),
                  tilePadding: EdgeInsets.zero,
                  title: const Text('Repeated cycle trace'),
                  subtitle: Text(
                    '${cycleTrace.length} retained configuration(s)',
                  ),
                  children: [
                    for (final step in cycleTrace)
                      ListTile(
                        dense: true,
                        title: Text(
                          'Step ${step.stepNumber} • ${step.currentState}',
                        ),
                        subtitle: Text(
                          '${step.usedTransition ?? 'Initial configuration'}\n'
                          'head ${step.headPosition ?? 0} • tape '
                          '${step.tapeContents.isEmpty ? '∅' : step.tapeContents}',
                        ),
                      ),
                  ],
                ),
              ),
          ],
          if (analysis.repeatedConfigurationsObserved > 0)
            _buildMetricRow(
              context,
              'Repeated NTM configurations observed',
              analysis.repeatedConfigurationsObserved.toString(),
            ),
        ],
      ),
    );
  }

  Widget _buildTapeOperationResults(
    BuildContext context,
    TMExecutionAnalysis analysis,
  ) {
    final colorScheme = Theme.of(context).colorScheme;
    final metrics = analysis.traceMetrics;
    if (metrics == null) {
      return _buildStatusMessage(
        context,
        message: analysis.message,
        isWarning: true,
      );
    }

    List<String> counts(Map<String, int> values) {
      final entries = values.entries.toList()
        ..sort((left, right) => left.key.compareTo(right.key));
      return [for (final entry in entries) '${entry.key}: ${entry.value}'];
    }

    final branchLabel = switch (metrics.branchSelection) {
      TMExecutionBranchSelection.deterministic => 'Deterministic execution',
      TMExecutionBranchSelection.acceptingBranch => 'Accepting NTM branch',
      TMExecutionBranchSelection.rejectingBranch => 'Rejecting NTM branch',
      TMExecutionBranchSelection.cyclicBranch => 'Cyclic NTM branch',
      TMExecutionBranchSelection.longestBoundedBranch =>
        'Longest bounded NTM branch',
    };
    final diff = metrics.tapeDiff.values.toList()
      ..sort((left, right) => left.position.compareTo(right.position));
    final touches = metrics.cellTouchRanges.entries.toList()
      ..sort((left, right) => left.key.compareTo(right.key));
    final declaredTapeAlphabet =
        (_analyzedTm?.tapeAlphabet.toList() ?? <String>[])..sort();

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: colorScheme.outline.withValues(alpha: 0.4)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildFocusBanner(context, _TMAnalysisFocus.tape),
          const SizedBox(height: 12),
          _buildStatusMessage(
            context,
            message: analysis.message,
            isPositive: analysis.outcome == TMExecutionOutcome.accepted,
            isWarning: analysis.outcome == TMExecutionOutcome.provenCycle ||
                analysis.outcome == TMExecutionOutcome.boundedUnknown,
          ),
          const SizedBox(height: 8),
          _buildMetricRow(
            context,
            'Input',
            analysis.input.isEmpty ? 'ε' : analysis.input,
          ),
          _buildMetricRow(context, 'Selected branch', branchLabel),
          _buildMetricRow(
            context,
            'Conclusion',
            analysis.isExact ? 'Exact for this input' : 'Bounded',
          ),
          _buildMetricRow(
            context,
            'Executed transitions',
            analysis.stepsExecuted.toString(),
          ),
          _buildMetricRow(
            context,
            'Configurations explored',
            analysis.configurationsExplored.toString(),
          ),
          _buildMetricRow(
            context,
            'Step limit',
            analysis.maxSteps.toString(),
          ),
          _buildMetricRow(
            context,
            'Configuration limit',
            analysis.maxConfigurations.toString(),
          ),
          _buildMetricRow(
            context,
            'Time limit',
            '${analysis.timeout.inSeconds} s',
          ),
          if (analysis.limit != null)
            _buildMetricRow(
              context,
              'Limit reached',
              analysis.limit!.name,
              isWarning: true,
            ),
          _buildMetricRow(
            context,
            'Writes that changed a cell',
            metrics.changedWrites.toString(),
          ),
          _buildMetricRow(
            context,
            'Head reversals',
            metrics.headReversals.toString(),
          ),
          _buildMetricRow(
            context,
            'Visited head interval',
            '${metrics.minimumHeadPosition}…${metrics.maximumHeadPosition}',
          ),
          _buildMetricRow(
            context,
            'Distinct cells visited',
            metrics.distinctCellsVisited.toString(),
          ),
          _buildMetricRow(
            context,
            'Maximum simultaneous nonblank cells',
            metrics.maximumSimultaneousNonBlankCells.toString(),
          ),
          const SizedBox(height: 8),
          _buildChipList(
            context,
            label: 'Declared tape alphabet',
            values: declaredTapeAlphabet,
          ),
          _buildChipList(
            context,
            label: 'Reads by symbol',
            values: counts(metrics.readCounts),
          ),
          _buildChipList(
            context,
            label: 'Writes by old symbol',
            values: counts(metrics.writeCountsByOldSymbol),
          ),
          _buildChipList(
            context,
            label: 'Writes by new symbol',
            values: counts(metrics.writeCountsByNewSymbol),
          ),
          _buildChipList(
            context,
            label: 'Head movements',
            values: counts(metrics.movementCounts),
          ),
          _buildChipList(
            context,
            label: 'Transition execution counts',
            values: counts(metrics.transitionExecutionCounts),
          ),
          _buildChipList(
            context,
            label: 'Defined but not executed transitions',
            values: metrics.definedButNotExecutedTransitionIds.toList()..sort(),
            isWarning: metrics.definedButNotExecutedTransitionIds.isNotEmpty,
          ),
          _buildChipList(
            context,
            label: 'Sparse initial-to-final tape diff',
            values: [
              for (final change in diff)
                '${change.position}: ${change.initialSymbol} → ${change.finalSymbol}',
            ],
          ),
          _buildChipList(
            context,
            label: 'First and last step touching each cell',
            values: [
              for (final entry in touches)
                '${entry.key}: ${entry.value.firstStep}…${entry.value.lastStep}',
            ],
          ),
          if (analysis.trace.isNotEmpty) ...[
            const SizedBox(height: 8),
            Material(
              color: Colors.transparent,
              child: ExpansionTile(
                key: const Key('tm-tape-related-trace'),
                tilePadding: EdgeInsets.zero,
                title: const Text('Related execution trace'),
                subtitle: Text(
                  '${analysis.trace.length} retained configuration(s)',
                ),
                children: [
                  SizedBox(
                    height: 260,
                    child: ListView.builder(
                      itemCount: analysis.trace.length,
                      itemBuilder: (context, index) {
                        final step = analysis.trace[index];
                        return ListTile(
                          dense: true,
                          title: Text(
                            'Step ${step.stepNumber} • ${step.currentState}',
                          ),
                          subtitle: Text(
                            '${step.usedTransition ?? 'Initial configuration'}\n'
                            'head ${step.headPosition ?? 0} • tape ${step.tapeContents.isEmpty ? '∅' : step.tapeContents}',
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildSpaceProfileResults(
    BuildContext context,
    TMSpaceProfileReport report,
  ) {
    final colorScheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: colorScheme.outline.withValues(alpha: 0.4)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _buildFocusBanner(context, _TMAnalysisFocus.space),
          const SizedBox(height: 12),
          _buildStatusMessage(
            context,
            message: report.isIncomplete
                ? 'The profile is incomplete. Sampled or bounded rows remain labeled below.'
                : 'Every scheduled input completed and every row was exhaustively enumerated.',
            isPositive: !report.isIncomplete,
            isWarning: report.isIncomplete,
          ),
          const SizedBox(height: 8),
          _buildMetricRow(
            context,
            'Evaluated candidates',
            '${report.evaluatedCandidates} of ${report.scheduledCandidates}',
          ),
          _buildMetricRow(
            context,
            'Requested candidates',
            report.requestedCandidates.toString(),
          ),
          _buildMetricRow(
            context,
            'Step limit per input',
            report.limits.maxStepsPerInput.toString(),
          ),
          _buildMetricRow(
            context,
            'Configuration bound per input',
            report.limits.maxConfigurationsPerInput.toString(),
            isWarning: report.isNondeterministic,
          ),
          _buildMetricRow(
            context,
            'Time limit per input',
            '${report.limits.timeoutPerInput.inMilliseconds} ms',
          ),
          _buildMetricRow(
            context,
            'Profile time',
            _formatDuration(report.executionTime),
          ),
          const SizedBox(height: 8),
          Text(
            'The current single tape stores both the original input and work data.',
            style: Theme.of(context).textTheme.bodySmall,
          ),
          if (report.isNondeterministic)
            Text(
              'NTM maxima cover every explored branch configuration within the displayed configuration bound.',
              style: Theme.of(context).textTheme.bodySmall,
            ),
          Text(
            'These observed maxima are a bounded profile, not an asymptotic space-complexity proof.',
            style: Theme.of(context).textTheme.bodySmall,
          ),
          if (report.cancelled)
            _buildStatusMessage(
              context,
              message: 'Space profiling cancelled. Evaluated rows were kept.',
              isWarning: true,
            ),
          const SizedBox(height: 12),
          for (final row in report.rows) ...[
            _buildSpaceLengthCard(context, row),
            const SizedBox(height: 8),
          ],
          if (report.rows.isEmpty)
            const Text('No input-length group was evaluated.'),
        ],
      ),
    );
  }

  Widget _buildSpaceLengthCard(
    BuildContext context,
    TMSpaceLengthProfile row,
  ) {
    final colors = Theme.of(context).colorScheme;
    final sampled = row.enumerationMode == TMSpaceEnumerationMode.sampled;
    return Container(
      key: Key('tm-space-length-${row.inputLength}'),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: row.isIncomplete
              ? colors.tertiary.withValues(alpha: 0.7)
              : colors.outline.withValues(alpha: 0.4),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'Input length ${row.inputLength}',
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
          ),
          const SizedBox(height: 6),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: [
              Chip(label: Text(sampled ? 'Sampled' : 'Exhaustive')),
              Chip(label: Text(row.isIncomplete ? 'Incomplete' : 'Complete')),
            ],
          ),
          _buildMetricRow(
            context,
            'Candidate coverage',
            '${row.inputs.length} of ${row.requestedCandidates}',
          ),
          _buildMetricRow(
            context,
            'Visited span maximum',
            _formatSpaceMaximum(row.maximumVisitedSpan),
            highlight: row.maximumVisitedSpan != null,
          ),
          _buildMetricRow(
            context,
            'Maximum nonblank cells',
            _formatSpaceMaximum(row.maximumNonBlankCells),
            highlight: row.maximumNonBlankCells != null,
          ),
          if (row.inconclusiveInputs > 0)
            _buildMetricRow(
              context,
              'Inconclusive executions',
              row.inconclusiveInputs.toString(),
              isWarning: true,
            ),
          if (sampled)
            Text(
              'The deterministic shortlex prefix was sampled because this length exceeds the candidate cap.',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: colors.onSurfaceVariant,
                  ),
            ),
        ],
      ),
    );
  }

  String _formatSpaceMaximum(TMSpaceMaximum? maximum) {
    if (maximum == null) return 'Not observed';
    final witness = maximum.witnessInput.isEmpty ? 'ε' : maximum.witnessInput;
    return '${maximum.value} cell(s) • witness $witness';
  }

  Widget _buildReachabilityResults(
    BuildContext context,
    TMReachabilityReport report,
  ) {
    final colorScheme = Theme.of(context).colorScheme;
    final tm = _analyzedTm;
    String stateName(String id) {
      final state =
          tm?.states.where((candidate) => candidate.id == id).firstOrNull;
      if (state == null || state.label.isEmpty || state.label == id) return id;
      return '${state.label} ($id)';
    }

    List<String> names(Set<String> ids) =>
        (ids.map(stateName).toList()..sort());
    final witnesses = report.witnessesByStateId.values.toList()
      ..sort((left, right) {
        final byStep = left.step.compareTo(right.step);
        return byStep != 0 ? byStep : left.stateId.compareTo(right.stateId);
      });
    final incomplete = report.status == TMReachabilityStatus.boundedIncomplete;
    final invalid = report.status == TMReachabilityStatus.invalidMachine;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: colorScheme.outline.withValues(alpha: 0.4)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildFocusBanner(context, _TMAnalysisFocus.reachability),
          const SizedBox(height: 12),
          _buildStatusMessage(
            context,
            message: report.message,
            isPositive: report.isComplete,
            isWarning: incomplete,
          ),
          if (invalid) const SizedBox(height: 8),
          _buildMetricRow(
            context,
            'Input scope',
            report.inputs
                .map((input) => input.isEmpty ? 'ε' : input)
                .join(', '),
          ),
          _buildMetricRow(
            context,
            'Semantic exploration',
            report.isComplete ? 'Complete for this input scope' : 'Incomplete',
            isWarning: !report.isComplete,
          ),
          _buildMetricRow(
            context,
            'Configurations explored',
            report.configurationsExplored.toString(),
          ),
          _buildMetricRow(
            context,
            'Transitions explored',
            report.transitionsExplored.toString(),
          ),
          _buildMetricRow(context, 'Step limit', report.maxSteps.toString()),
          _buildMetricRow(
            context,
            'Configuration limit',
            report.maxConfigurations.toString(),
          ),
          _buildMetricRow(
            context,
            'Time limit',
            '${report.timeout.inSeconds} s',
          ),
          if (report.limit != null)
            _buildMetricRow(
              context,
              'Limit reached',
              report.limit!.name,
              isWarning: true,
            ),
          const SizedBox(height: 12),
          _buildChipList(
            context,
            label: 'Structurally reachable (exact over-approximation)',
            values: names(report.structurallyReachableStateIds),
          ),
          _buildChipList(
            context,
            label: 'Reached within bounds',
            values: names(report.reachedWithinBoundsStateIds),
          ),
          _buildChipList(
            context,
            label: incomplete
                ? 'Not observed before a bound stopped exploration'
                : 'Not observed for this input scope',
            values: names(report.notObservedWithinBoundsStateIds),
            isWarning: true,
          ),
          _buildChipList(
            context,
            label: 'Structurally unreachable (exact)',
            values: names(report.structurallyUnreachableStateIds),
            isWarning: true,
          ),
          if (witnesses.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(
              'Shortest witnesses',
              style: Theme.of(context)
                  .textTheme
                  .titleMedium
                  ?.copyWith(fontWeight: FontWeight.w600),
            ),
            for (final witness in witnesses)
              Material(
                color: Colors.transparent,
                child: ExpansionTile(
                  key: Key('tm-reachability-witness-${witness.stateId}'),
                  tilePadding: EdgeInsets.zero,
                  title: Text(stateName(witness.stateId)),
                  subtitle: Text(
                    'Input ${witness.input.isEmpty ? 'ε' : witness.input} • step ${witness.step}',
                  ),
                  children: [
                    _buildMetricRow(
                      context,
                      'Head position',
                      witness.headPosition.toString(),
                    ),
                    _buildMetricRow(
                      context,
                      'Read symbol',
                      witness.readSymbol,
                    ),
                    _buildMetricRow(
                      context,
                      'Incoming transition',
                      witness.incomingTransitionId ?? 'Initial configuration',
                    ),
                    _buildChipList(
                      context,
                      label: 'State trace',
                      values: witness.stateIds,
                    ),
                    _buildChipList(
                      context,
                      label: 'Transition trace',
                      values: witness.transitionIds,
                    ),
                  ],
                ),
              ),
          ],
        ],
      ),
    );
  }

  Widget _buildLanguageResults(
    BuildContext context,
    TMLanguageExplorerReport report,
  ) {
    final colorScheme = Theme.of(context).colorScheme;
    final alphabet = report.alphabet.isEmpty ? '∅' : report.alphabet.join(', ');
    final completeness = report.cancelled
        ? 'Cancelled • incomplete'
        : report.truncatedByCandidateCap
            ? 'Sampled • deterministic shortlex prefix'
            : report.count(TMLanguageOutcome.inconclusive) > 0
                ? 'Complete enumeration • bounded outcomes remain'
                : 'Complete';
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: colorScheme.outline.withValues(alpha: 0.4)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _buildFocusBanner(context, _TMAnalysisFocus.language),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final outcome in TMLanguageOutcome.values)
                _buildLanguageOutcomeCount(context, report, outcome),
            ],
          ),
          const SizedBox(height: 12),
          _buildMetricRow(
            context,
            'Evaluated candidates',
            '${report.results.length} of ${report.plannedCandidates}',
          ),
          _buildMetricRow(
            context,
            'Requested candidates',
            report.requestedCandidates.toString(),
          ),
          _buildMetricRow(context, 'Completeness', completeness),
          _buildMetricRow(context, 'Input alphabet', alphabet),
          _buildMetricRow(
            context,
            'Maximum input length',
            report.limits.maxInputLength.toString(),
          ),
          _buildMetricRow(
            context,
            'Candidate cap',
            report.limits.maxCandidates.toString(),
          ),
          _buildMetricRow(
            context,
            'Step limit per input',
            report.limits.maxStepsPerInput.toString(),
          ),
          _buildMetricRow(
            context,
            'Configuration limit per input',
            report.limits.maxConfigurationsPerInput.toString(),
          ),
          _buildMetricRow(
            context,
            'Time limit per input',
            '${report.limits.timeoutPerInput.inMilliseconds} ms',
          ),
          _buildMetricRow(
            context,
            'Exploration time',
            _formatDuration(report.executionTime),
          ),
          if (report.truncatedByCandidateCap)
            _buildStatusMessage(
              context,
              message:
                  'Candidate cap reached. This report contains the deterministic shortlex prefix only.',
              isWarning: true,
            ),
          if (report.cancelled)
            _buildStatusMessage(
              context,
              message: 'Exploration cancelled. Evaluated results were kept.',
              isWarning: true,
            ),
          if (report.count(TMLanguageOutcome.inconclusive) > 0)
            _buildStatusMessage(
              context,
              message:
                  'Some inputs are inconclusive; limits or cancellation do not imply rejection.',
              isWarning: true,
            ),
          const SizedBox(height: 8),
          Text(
            'Words',
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
          ),
          const SizedBox(height: 4),
          for (final result in report.results)
            _buildLanguageWordTile(context, result),
          if (report.results.isEmpty)
            const Text('No candidates were evaluated.'),
          if (_selectedLanguageWord != null) ...[
            const Divider(height: 24),
            _buildSelectedLanguageWord(context, _selectedLanguageWord!),
          ],
        ],
      ),
    );
  }

  Widget _buildLanguageOutcomeCount(
    BuildContext context,
    TMLanguageExplorerReport report,
    TMLanguageOutcome outcome,
  ) {
    final color = _languageOutcomeColor(context, outcome);
    final outcomeLabel = appLocalizationsOf(context).localizeWorkflowText(
      _languageOutcomeLabel(outcome),
    );
    return Container(
      key: Key('tm-language-count-${outcome.name}'),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        border: Border.all(color: color.withValues(alpha: 0.6)),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Text(
        '$outcomeLabel: ${report.count(outcome)}',
        style: Theme.of(context).textTheme.labelMedium?.copyWith(color: color),
      ),
    );
  }

  Widget _buildLanguageWordTile(
    BuildContext context,
    TMLanguageWordResult result,
  ) {
    final selected = _selectedLanguageWord?.input == result.input;
    final color = _languageOutcomeColor(context, result.outcome);
    final outcomeLabel = appLocalizationsOf(context).localizeWorkflowText(
      _languageOutcomeLabel(result.outcome),
    );
    return Card(
      key: ValueKey('tm-language-word-${result.input}'),
      color: selected
          ? Theme.of(context).colorScheme.primaryContainer
          : Theme.of(context).colorScheme.surface,
      child: ListTile(
        selected: selected,
        onTap: () => _selectLanguageWord(result),
        leading: Icon(_languageOutcomeIcon(result.outcome), color: color),
        title: Text(result.input.isEmpty ? 'ε' : result.input),
        subtitle: Text(
          '$outcomeLabel • '
          '${result.analysis.stepsExecuted} steps • '
          '${result.analysis.configurationsExplored} configurations',
        ),
        trailing: const Icon(Icons.chevron_right),
      ),
    );
  }

  Widget _buildSelectedLanguageWord(
    BuildContext context,
    TMLanguageWordResult result,
  ) {
    final analysis = result.analysis;
    final trace = _selectedLanguageTrace?.trace ?? const [];
    return Column(
      key: const Key('tm-language-selected-word'),
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          'Selected word: ${result.input.isEmpty ? 'ε' : result.input}',
          style: Theme.of(context).textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.w600,
              ),
        ),
        const SizedBox(height: 8),
        _buildMetricRow(
            context, 'Outcome', _languageOutcomeLabel(result.outcome)),
        _buildMetricRow(
          context,
          'Transitions executed',
          analysis.stepsExecuted.toString(),
        ),
        _buildMetricRow(
          context,
          'Configurations explored',
          analysis.configurationsExplored.toString(),
        ),
        _buildMetricRow(
          context,
          'Execution time',
          _formatDuration(analysis.executionTime),
        ),
        if (analysis.limit != null)
          _buildMetricRow(
            context,
            'Limit reached',
            analysis.limit!.name,
            isWarning: true,
          ),
        const SizedBox(height: 8),
        Text(
          'Trace',
          style: Theme.of(context).textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.w600,
              ),
        ),
        if (_isLoadingLanguageTrace)
          const Padding(
            padding: EdgeInsets.all(16),
            child: Center(child: CircularProgressIndicator()),
          )
        else if (trace.isEmpty)
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 8),
            child: Text('No trace was recorded for this bounded run.'),
          )
        else
          SizedBox(
            height: 220,
            child: ListView.separated(
              key: const Key('tm-language-trace'),
              itemCount: trace.length,
              separatorBuilder: (_, __) => const Divider(height: 1),
              itemBuilder: (context, index) {
                final step = trace[index];
                return ListTile(
                  dense: true,
                  title: Text('Step ${step.stepNumber} • ${step.currentState}'),
                  subtitle: Text(
                    step.usedTransition ??
                        'Initial configuration at head ${step.headPosition ?? 0}',
                  ),
                );
              },
            ),
          ),
      ],
    );
  }

  Future<void> _selectLanguageWord(TMLanguageWordResult result) async {
    final generation = _analysisGeneration;
    setState(() {
      _selectedLanguageWord = result;
      _selectedLanguageTrace = null;
      _isLoadingLanguageTrace = true;
    });

    final tm = _analyzedTm;
    final limits = _languageReport?.limits;
    if (tm == null || limits == null) {
      if (mounted) setState(() => _isLoadingLanguageTrace = false);
      return;
    }
    final trace = await TMExecutionAnalyzer.analyze(
      tm,
      result.input,
      maxSteps: limits.maxStepsPerInput,
      maxConfigurations: limits.maxConfigurationsPerInput,
      timeout: limits.timeoutPerInput,
      operationsPerBatch: limits.operationsPerBatch,
      includeTrace: true,
      isCancelled: () => !_isCurrentAnalysis(generation, tm),
    );
    if (!_isCurrentAnalysis(generation, tm) ||
        _selectedLanguageWord?.input != result.input) {
      return;
    }
    setState(() {
      _selectedLanguageTrace = trace;
      _isLoadingLanguageTrace = false;
    });
  }

  String _languageOutcomeLabel(TMLanguageOutcome outcome) => switch (outcome) {
        TMLanguageOutcome.accepted => 'Accepted',
        TMLanguageOutcome.rejected => 'Halted rejected',
        TMLanguageOutcome.provenCycle => 'Proven cycle',
        TMLanguageOutcome.inconclusive => 'Inconclusive',
      };

  IconData _languageOutcomeIcon(TMLanguageOutcome outcome) => switch (outcome) {
        TMLanguageOutcome.accepted => Icons.check_circle_outline,
        TMLanguageOutcome.rejected => Icons.cancel_outlined,
        TMLanguageOutcome.provenCycle => Icons.loop,
        TMLanguageOutcome.inconclusive => Icons.help_outline,
      };

  Color _languageOutcomeColor(
    BuildContext context,
    TMLanguageOutcome outcome,
  ) {
    final colors = Theme.of(context).colorScheme;
    return switch (outcome) {
      TMLanguageOutcome.accepted => colors.primary,
      TMLanguageOutcome.rejected => colors.error,
      TMLanguageOutcome.provenCycle => colors.tertiary,
      TMLanguageOutcome.inconclusive => colors.onSurfaceVariant,
    };
  }

  Widget _buildTimeProfileResults(
    BuildContext context,
    TMTimeProfileReport report,
  ) {
    final colorScheme = Theme.of(context).colorScheme;
    final incomplete = report.status == TMTimeProfileStatus.incomplete ||
        report.status == TMTimeProfileStatus.cancelled;
    final invalid = report.status == TMTimeProfileStatus.invalid;
    final kindLabel = report.kind == TMTimeProfileKind.deterministicTime
        ? 'DTM transition-step profile'
        : 'NTM exploration metrics (not deterministic time)';
    final alphabet =
        report.plan.alphabet.isEmpty ? '∅' : report.plan.alphabet.join(', ');

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: colorScheme.outline.withValues(alpha: 0.4)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildFocusBanner(context, _TMAnalysisFocus.time),
          const SizedBox(height: 12),
          _buildStatusMessage(
            context,
            message: report.message,
            isPositive: report.isComplete,
            isWarning: incomplete || invalid,
          ),
          const SizedBox(height: 8),
          _buildMetricRow(context, 'Profile kind', kindLabel),
          _buildMetricRow(context, 'Input alphabet', alphabet),
          _buildMetricRow(
            context,
            'Input lengths',
            '0…${report.plan.bounds.maxLength}',
          ),
          _buildMetricRow(
            context,
            'Planned candidates',
            report.plan.plannedCandidateCount.toString(),
          ),
          _buildMetricRow(
            context,
            'Transition-step budget per candidate',
            report.plan.bounds.maxStepsPerCandidate.toString(),
          ),
          _buildMetricRow(
            context,
            'Configuration budget per candidate',
            report.plan.bounds.maxConfigurationsPerCandidate.toString(),
          ),
          _buildMetricRow(
            context,
            'Time budget per candidate',
            '${report.plan.bounds.timeoutPerCandidate.inSeconds} s',
          ),
          _buildMetricRow(
            context,
            'Profiler device wall-clock (diagnostic)',
            _formatDuration(report.profilingWallClockTime),
          ),
          const SizedBox(height: 8),
          _buildStatusMessage(
            context,
            message:
                'Observed bounded measurements only; no Big-O class is inferred.',
          ),
          const SizedBox(height: 12),
          for (var index = 0; index < report.rows.length; index++) ...[
            _buildTimeProfileRow(context, report, report.rows[index]),
            if (index != report.rows.length - 1) const SizedBox(height: 10),
          ],
        ],
      ),
    );
  }

  Widget _buildTimeProfileRow(
    BuildContext context,
    TMTimeProfileReport report,
    TMTimeProfileRow row,
  ) {
    final colorScheme = Theme.of(context).colorScheme;
    final sampled = row.isSampled;
    final rowColor = sampled
        ? colorScheme.tertiary
        : row.isComplete
            ? colorScheme.primary
            : colorScheme.error;
    final status = sampled
        ? 'Sampled • incomplete'
        : row.isComplete
            ? 'Exhaustive • complete'
            : 'Exhaustive • incomplete';

    return Container(
      key: Key('tm-time-profile-row-${row.inputLength}'),
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: rowColor.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: rowColor.withValues(alpha: 0.75)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  'Input length ${row.inputLength}',
                  style: Theme.of(context)
                      .textTheme
                      .titleSmall
                      ?.copyWith(fontWeight: FontWeight.w600),
                ),
              ),
              Chip(
                key: Key('tm-time-profile-row-mode-${row.inputLength}'),
                label: Text(status),
                side: BorderSide(color: rowColor),
                backgroundColor: rowColor.withValues(alpha: 0.12),
              ),
            ],
          ),
          _buildMetricRow(
            context,
            'Candidates evaluated',
            '${row.evaluatedCandidateCount} of ${row.candidateCount}',
          ),
          if (row.isSampled)
            _buildMetricRow(
              context,
              'Possible candidates',
              row.possibleCandidateCount.toString(),
              isWarning: true,
            ),
          _buildMetricRow(
            context,
            report.kind == TMTimeProfileKind.deterministicTime
                ? 'Halting runs'
                : 'Resolved candidates',
            row.completedCount.toString(),
          ),
          if (row.provenCycleCount > 0)
            _buildMetricRow(
              context,
              'Proven non-halting cycles',
              row.provenCycleCount.toString(),
              isWarning: true,
            ),
          if (row.unknownCount > 0)
            _buildMetricRow(
              context,
              'Bounded unknown runs',
              row.unknownCount.toString(),
              isWarning: true,
            ),
          if (row.cancelledCount > 0)
            _buildMetricRow(
              context,
              'Cancelled runs',
              row.cancelledCount.toString(),
              isWarning: true,
            ),
          if (row.invalidCount > 0)
            _buildMetricRow(
              context,
              'Invalid runs',
              row.invalidCount.toString(),
              isError: true,
            ),
          if (report.kind == TMTimeProfileKind.deterministicTime) ...[
            _buildMetricRow(
              context,
              'Minimum halting transition steps',
              row.minimumTransitionSteps?.toString() ?? '—',
            ),
            _buildMetricRow(
              context,
              'Maximum halting transition steps',
              row.maximumTransitionSteps?.toString() ?? '—',
              highlight: row.maximumTransitionSteps != null,
            ),
            if (row.maximumTransitionWitness != null)
              _buildTimeProfileWitness(
                context,
                row.maximumTransitionWitness!,
                row.inputLength,
                metricKey: 'transitions',
                title: 'Maximum transition-step witness',
              ),
          ] else ...[
            _buildMetricRow(
              context,
              'Observed branch depth range',
              _metricRange(
                row.minimumExplorationDepth,
                row.maximumExplorationDepth,
              ),
            ),
            _buildMetricRow(
              context,
              'Observed configurations explored range',
              _metricRange(
                row.minimumConfigurationsExplored,
                row.maximumConfigurationsExplored,
              ),
            ),
            if (row.maximumDepthWitness != null)
              _buildTimeProfileWitness(
                context,
                row.maximumDepthWitness!,
                row.inputLength,
                metricKey: 'depth',
                title: 'Maximum exploration-depth witness',
              ),
            if (row.maximumConfigurationsWitness != null)
              _buildTimeProfileWitness(
                context,
                row.maximumConfigurationsWitness!,
                row.inputLength,
                metricKey: 'configurations',
                title: 'Maximum explored-configurations witness',
              ),
          ],
        ],
      ),
    );
  }

  String _metricRange(int? minimum, int? maximum) {
    if (minimum == null || maximum == null) return '—';
    return '$minimum…$maximum';
  }

  Widget _buildTimeProfileWitness(
    BuildContext context,
    TMTimeProfileWitness witness,
    int inputLength, {
    required String metricKey,
    required String title,
  }) {
    final input = witness.input.isEmpty ? 'ε' : witness.input;
    return Material(
      color: Colors.transparent,
      child: ExpansionTile(
        key: Key('tm-time-witness-$inputLength-$metricKey'),
        tilePadding: EdgeInsets.zero,
        title: Text(title),
        subtitle: Text(
          'Input $input • ${witness.execution.trace.length} retained configuration(s)',
        ),
        children: [
          SizedBox(
            height: 220,
            child: ListView.builder(
              itemCount: witness.execution.trace.length,
              itemBuilder: (context, index) {
                final step = witness.execution.trace[index];
                return ListTile(
                  dense: true,
                  title: Text(
                    'Step ${step.stepNumber} • ${step.currentState}',
                  ),
                  subtitle: Text(
                    step.usedTransition ?? 'Initial configuration',
                  ),
                );
              },
            ),
          ),
        ],
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
    final generation = ++_analysisGeneration;
    _languageCancellation?.cancel();
    _languageCancellation = null;
    final highlights = _analysisHighlights;
    final highlightTarget = highlights?.target;
    if (highlights != null && highlightTarget != null) {
      highlights.clearFor(highlightTarget);
    }
    setState(() {
      _isAnalyzing = true;
      _clearAnalysisOutputs();
      _currentFocus = focus;
      _cancelRequested = false;
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

    if (focus == _TMAnalysisFocus.time) {
      final bounds = _profileBounds();
      if (bounds == null) {
        setState(() {
          _isAnalyzing = false;
          _analysisError =
              'Enter integer bounds before starting the bounded time profile.';
        });
        return;
      }
      final report = await TMTimeProfiler.profile(
        tm,
        bounds: bounds,
        isCancelled: () => _isAnalysisCancelled(generation, tm),
        onProgress: (progress) {
          if (!_isCurrentAnalysis(generation, tm)) return;
          final input = progress.input.isEmpty ? 'ε' : progress.input;
          setState(() {
            _profileProgress = progress.fraction.clamp(0, 1);
            _profileProgressLabel = progress.isWitnessReplay
                ? 'Retaining witness trace for $input'
                : 'Profiling length ${progress.inputLength}: $input';
          });
        },
      );
      if (!_isCurrentAnalysis(generation, tm)) return;
      setState(() {
        _isAnalyzing = false;
        _timeProfile = report;
        _analyzedTm = tm;
        _profileProgress = 1;
        _profileProgressLabel = null;
      });
      return;
    }

    if (focus == _TMAnalysisFocus.termination ||
        focus == _TMAnalysisFocus.tape) {
      final result = await TMExecutionAnalyzer.analyze(
        tm,
        _terminationInputController.text,
        maxSteps: _terminationMaxSteps,
        maxConfigurations: _terminationMaxConfigurations,
        timeout: _terminationTimeout,
        isCancelled: () => _isAnalysisCancelled(generation, tm),
        onProgress: (steps, configurations) {
          if (!_isCurrentAnalysis(generation, tm)) return;
          setState(() {
            _operationProgressLabel = '$steps transition(s) • '
                '$configurations configuration(s) explored';
          });
        },
      );
      if (!_isCurrentAnalysis(generation, tm)) return;
      if (focus == _TMAnalysisFocus.tape &&
          highlights != null &&
          highlightTarget != null &&
          result.traceMetrics != null) {
        highlights.sendFor(
          highlightTarget,
          SimulationHighlight(
            stateIds: result.trace.map((step) => step.currentState).toSet(),
            transitionIds:
                result.traceMetrics!.transitionExecutionCounts.keys.toSet(),
          ),
        );
      }
      setState(() {
        _isAnalyzing = false;
        _terminationAnalysis = result;
        _analyzedTm = tm;
        _operationProgressLabel = null;
      });
      return;
    }

    if (focus == _TMAnalysisFocus.reachability) {
      final report = await TMReachabilityAnalyzer.analyze(
        tm,
        inputs: _reachabilityInputScope(),
        maxSteps: _terminationMaxSteps,
        maxConfigurations: _terminationMaxConfigurations,
        timeout: _terminationTimeout,
        isCancelled: () => _isAnalysisCancelled(generation, tm),
        onProgress: (transitions, configurations) {
          if (!_isCurrentAnalysis(generation, tm)) return;
          setState(() {
            _operationProgressLabel = '$transitions transition(s) • '
                '$configurations configuration(s) explored';
          });
        },
      );
      if (!_isCurrentAnalysis(generation, tm)) return;
      if (highlights != null &&
          highlightTarget != null &&
          report.status != TMReachabilityStatus.invalidMachine) {
        highlights.sendFor(
          highlightTarget,
          SimulationHighlight(
            stateIds: report.reachedWithinBoundsStateIds,
            warningStateIds: report.notObservedWithinBoundsStateIds,
            errorStateIds: report.structurallyUnreachableStateIds,
          ),
        );
      }
      setState(() {
        _isAnalyzing = false;
        _reachabilityReport = report;
        _analyzedTm = tm;
        _operationProgressLabel = null;
      });
      return;
    }

    if (focus == _TMAnalysisFocus.language) {
      final limits = _readLanguageLimits();
      if (limits == null) {
        setState(() {
          _isAnalyzing = false;
          _analysisError =
              'Maximum length must be 0 through 20, candidate cap 1 through 10,000, and execution limits positive whole numbers.';
        });
        return;
      }
      final cancellation = TMLanguageExplorerCancellationToken();
      _languageCancellation = cancellation;
      final result = await TMLanguageExplorer.explore(
        tm,
        limits: limits,
        cancellationToken: cancellation,
        onProgress: (progress) {
          if (!_isCurrentAnalysis(generation, tm)) return;
          setState(() {
            _languageProgress = progress;
          });
        },
      );
      if (!_isCurrentAnalysis(generation, tm)) return;
      setState(() {
        _isAnalyzing = false;
        _languageCancellation = null;
        _analyzedTm = tm;
        if (result.isSuccess) {
          _languageReport = result.data;
        } else {
          _analysisError = result.error ?? 'Language exploration failed.';
        }
      });
      return;
    }

    if (focus == _TMAnalysisFocus.space) {
      final limits = _readSpaceProfileLimits();
      if (limits == null) {
        setState(() {
          _isAnalyzing = false;
          _analysisError =
              'Maximum length must be 0 through 20, candidate cap 1 through 10,000, and execution limits positive whole numbers.';
        });
        return;
      }
      final result = await TMSpaceProfiler.profile(
        tm,
        limits: limits,
        isCancelled: () => _isAnalysisCancelled(generation, tm),
        onProgress: (progress) {
          if (!_isCurrentAnalysis(generation, tm)) return;
          setState(() {
            _spaceProfileProgress = progress;
          });
        },
      );
      if (!_isCurrentAnalysis(generation, tm)) return;
      setState(() {
        _isAnalyzing = false;
        _analyzedTm = tm;
        if (result.isSuccess) {
          _spaceProfileReport = result.data;
        } else {
          _analysisError = result.error ?? 'Space profiling failed.';
        }
      });
      return;
    }
  }

  List<String> _reachabilityInputScope() {
    final raw = _reachabilityInputsController.text;
    if (raw.trim().isEmpty) return const [''];
    return raw
        .split(',')
        .map((input) => input.trim())
        .map((input) => input == 'ε' || input == 'λ' ? '' : input)
        .toSet()
        .toList(growable: false);
  }

  TMLanguageExplorerLimits? _readLanguageLimits() {
    final maxLength = int.tryParse(_languageMaxLengthController.text);
    final candidateCap = int.tryParse(_languageCandidateCapController.text);
    final maxSteps = int.tryParse(_languageMaxStepsController.text);
    final maxConfigurations =
        int.tryParse(_languageMaxConfigurationsController.text);
    final timeoutMs = int.tryParse(_languageTimeoutMsController.text);
    if (maxLength == null ||
        maxLength < 0 ||
        maxLength > 20 ||
        candidateCap == null ||
        candidateCap <= 0 ||
        candidateCap > 10000 ||
        maxSteps == null ||
        maxSteps <= 0 ||
        maxConfigurations == null ||
        maxConfigurations <= 0 ||
        timeoutMs == null ||
        timeoutMs <= 0) {
      return null;
    }
    return TMLanguageExplorerLimits(
      maxInputLength: maxLength,
      maxCandidates: candidateCap,
      maxStepsPerInput: maxSteps,
      maxConfigurationsPerInput: maxConfigurations,
      timeoutPerInput: Duration(milliseconds: timeoutMs),
    );
  }

  TMSpaceProfileLimits? _readSpaceProfileLimits() {
    final maxLength = int.tryParse(_spaceMaxLengthController.text);
    final candidateCap = int.tryParse(_spaceCandidateCapController.text);
    final maxSteps = int.tryParse(_spaceMaxStepsController.text);
    final maxConfigurations =
        int.tryParse(_spaceMaxConfigurationsController.text);
    final timeoutMs = int.tryParse(_spaceTimeoutMsController.text);
    if (maxLength == null ||
        maxLength < 0 ||
        maxLength > 20 ||
        candidateCap == null ||
        candidateCap <= 0 ||
        candidateCap > 10000 ||
        maxSteps == null ||
        maxSteps <= 0 ||
        maxConfigurations == null ||
        maxConfigurations <= 0 ||
        timeoutMs == null ||
        timeoutMs <= 0) {
      return null;
    }
    return TMSpaceProfileLimits(
      maxInputLength: maxLength,
      maxCandidatesPerLength: candidateCap,
      maxStepsPerInput: maxSteps,
      maxConfigurationsPerInput: maxConfigurations,
      timeoutPerInput: Duration(milliseconds: timeoutMs),
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
      case _TMAnalysisFocus.termination:
        return 'Termination and Cycles';
      case _TMAnalysisFocus.reachability:
        return 'Structural and bounded semantic reachability';
      case _TMAnalysisFocus.language:
        return 'Language Explorer';
      case _TMAnalysisFocus.tape:
        return 'Tape Trace';
      case _TMAnalysisFocus.time:
        return 'Time Profile';
      case _TMAnalysisFocus.space:
        return 'Space Profile';
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
    final localizations = appLocalizationsOf(context);
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
            child: Text(
              localizations.localizeWorkflowText(label),
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ),
          Text(
            localizations.localizeWorkflowText(value),
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
    final localizations = appLocalizationsOf(context);

    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            localizations.localizeWorkflowText(label),
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
    final localizations = appLocalizationsOf(context);
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
              localizations.localizeWorkflowText(message),
              style: Theme.of(
                context,
              ).textTheme.bodySmall?.copyWith(color: textColor),
            ),
          ),
        ],
      ),
    );
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
}
