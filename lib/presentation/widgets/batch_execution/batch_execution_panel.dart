import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../core/batch_execution/batch_execution.dart';
import '../../../core/messages/structured_message.dart';
import '../../../l10n/app_localizations.dart';
import '../../../l10n/app_localizations_resolver.dart';
import '../../../l10n/app_localizations_structured_messages.dart';
import '../../../l10n/app_localizations_workflows.dart';
import '../../empty_string_notation.dart';
import 'batch_file_service.dart';
import '../../localization/locale_value_formatter.dart';

enum BatchResultSort { inputOrder, outcome, elapsed }

final class BatchExecutionPanel extends StatefulWidget {
  BatchExecutionPanel({
    required this.executor,
    this.title = 'Batch execution',
    this.alphabet = const <String>{},
    this.strategyLabels = const <String, String>{},
    this.initialStrategyId,
    this.initialTokenizationMode = BatchTokenizationMode.unicodeScalar,
    this.comparisonExecutor,
    this.fileService,
    this.onOpenTrace,
    super.key,
  }) : assert(
         initialStrategyId == null ||
             executor.strategyIds.contains(initialStrategyId),
         'The initial strategy must be supported by the executor.',
       );

  final BatchCaseExecutor executor;
  final String title;
  final Set<String> alphabet;
  final Map<String, String> strategyLabels;
  final String? initialStrategyId;
  final BatchTokenizationMode initialTokenizationMode;
  final BatchCaseExecutor? comparisonExecutor;
  final BatchFileService? fileService;
  final ValueChanged<BatchCaseResult>? onOpenTrace;

  @override
  State<BatchExecutionPanel> createState() => _BatchExecutionPanelState();
}

class _BatchExecutionPanelState extends State<BatchExecutionPanel> {
  static const _caseLimit = BatchExecutionRequest.maxCaseCount;

  final _inputController = TextEditingController();
  final _filterController = TextEditingController();
  final _maxLengthController = TextEditingController(text: '4');
  final _maxCountController = TextEditingController(text: '256');
  final _stepLimitController = TextEditingController(text: '10000');
  final _configurationLimitController = TextEditingController(text: '100000');
  final _timeoutController = TextEditingController(text: '5');
  final _traceLimitController = TextEditingController(text: '1000');
  late final BatchFileService _fileService;

  late String _strategyId;
  late BatchTokenizationMode _tokenizationMode;
  BatchTraceRetention _traceRetention = BatchTraceRetention.none;
  BatchResultSort _sort = BatchResultSort.inputOrder;
  List<BatchInputCase>? _preparedCases;
  BatchRunHandle? _activeRun;
  StreamSubscription<BatchProgress>? _progressSubscription;
  BatchExecutionReport? _report;
  BatchComparisonReport? _comparison;
  final Map<String, BatchCaseResult> _partialResults = {};
  int _generation = 0;
  int _completed = 0;
  int _total = 0;
  int _maxConcurrency = 2;
  bool _stopOnFirstFailure = false;
  bool _isRunning = false;
  bool _isComparing = false;
  String? _message;
  List<int> _messageIntegers = const [];
  List<StructuredMessage> _structuredMessages = const [];

  @override
  void initState() {
    super.initState();
    _fileService = widget.fileService ?? createBatchFileService();
    _strategyId = _resolveInitialStrategy(widget);
    _tokenizationMode = widget.initialTokenizationMode;
    _filterController.addListener(_refreshFilter);
  }

  @override
  void didUpdateWidget(covariant BatchExecutionPanel oldWidget) {
    super.didUpdateWidget(oldWidget);
    final modelChanged =
        oldWidget.executor.modelId != widget.executor.modelId ||
        oldWidget.executor.modelRevision != widget.executor.modelRevision;
    if (modelChanged) {
      _cancelActiveRun();
      _strategyId = _resolveInitialStrategy(widget);
      _clearResults(message: 'Results cleared because the model changed.');
    } else if (!widget.executor.strategyIds.contains(_strategyId)) {
      _strategyId = _resolveInitialStrategy(widget);
    }
  }

  @override
  void dispose() {
    _activeRun?.cancel();
    unawaited(_progressSubscription?.cancel());
    _inputController.dispose();
    _filterController
      ..removeListener(_refreshFilter)
      ..dispose();
    _maxLengthController.dispose();
    _maxCountController.dispose();
    _stepLimitController.dispose();
    _configurationLimitController.dispose();
    _timeoutController.dispose();
    _traceLimitController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = appLocalizationsOf(context);
    final formatter = LocaleValueFormatter.of(context);
    final rawResolvedMessage = _message == null
        ? (_structuredMessages.isEmpty
              ? null
              : _structuredMessages
                    .map(l10n.resolveStructuredMessage)
                    .join('\n'))
        : formatter.integersInLocalizedText(
            l10n.localizeWorkflowText(_message!),
            _messageIntegers,
          );
    final resolvedMessage = rawResolvedMessage == null
        ? null
        : _usesEmptyStringTerminology(_message)
        ? EmptyStringNotation.formatTerminology(context, rawResolvedMessage)
        : rawResolvedMessage;
    return FocusTraversalGroup(
      child: CallbackShortcuts(
        bindings: {
          const SingleActivator(LogicalKeyboardKey.enter, control: true):
              _isRunning ? _cancelActiveRun : _run,
          const SingleActivator(LogicalKeyboardKey.escape): _cancelActiveRun,
        },
        child: Card(
          margin: EdgeInsets.zero,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              mainAxisSize: MainAxisSize.min,
              children: [
                _buildHeader(context),
                const SizedBox(height: 12),
                _buildInputs(context),
                const SizedBox(height: 12),
                _buildActions(context),
                _buildConfiguration(context),
                if (resolvedMessage case final message?) ...[
                  const SizedBox(height: 12),
                  Semantics(
                    liveRegion: true,
                    child: Text(message, key: const Key('batch-message')),
                  ),
                ],
                if (_isRunning || _total > 0) ...[
                  const SizedBox(height: 12),
                  _buildProgress(context),
                ],
                if (_report != null || _partialResults.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  _buildResults(context),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    final l10n = appLocalizationsOf(context);
    final title = widget.title == 'Batch execution'
        ? l10n.localizeWorkflowText(widget.title)
        : widget.title;
    return Row(
      children: [
        Icon(Icons.playlist_play, color: Theme.of(context).colorScheme.primary),
        const SizedBox(width: 8),
        Expanded(
          child: Text(title, style: Theme.of(context).textTheme.titleLarge),
        ),
        Tooltip(
          message: l10n.batchExecutionKeyboardShortcuts,
          child: Icon(
            Icons.keyboard,
            semanticLabel: l10n.keyboardShortcutsTitle,
          ),
        ),
      ],
    );
  }

  Widget _buildInputs(BuildContext context) {
    final l10n = appLocalizationsOf(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        TextField(
          key: const Key('batch-inputs'),
          controller: _inputController,
          minLines: 4,
          maxLines: 9,
          onChanged: (_) {
            _preparedCases = null;
            _invalidateFinishedResults();
          },
          decoration:
              InputDecoration(
                border: const OutlineInputBorder(),
                labelText: l10n.localizeWorkflowText(
                  'Inputs, one case per line',
                ),
                alignLabelWithHint: true,
              ).copyWith(
                helperText:
                    _tokenizationMode == BatchTokenizationMode.explicitTokens
                    ? EmptyStringNotation.formatTerminology(
                        context,
                        l10n.localizeWorkflowText(
                          'Use spaces between tokens and ε for the empty word.',
                        ),
                      )
                    : EmptyStringNotation.formatTerminology(
                        context,
                        l10n.localizeWorkflowText(
                          'Use ε for the empty word. Whitespace is preserved.',
                        ),
                      ),
              ),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            OutlinedButton.icon(
              key: const Key('batch-add-case'),
              onPressed: _isRunning ? null : _addCase,
              icon: const Icon(Icons.add),
              label: Text(l10n.localizeWorkflowText('Add case')),
            ),
            OutlinedButton.icon(
              key: const Key('batch-import'),
              onPressed: _isRunning ? null : _importInputs,
              icon: const Icon(Icons.upload_file),
              label: Text(l10n.localizeWorkflowText('Import TXT/CSV')),
            ),
            SizedBox(
              width: 112,
              child: TextField(
                key: const Key('batch-max-length'),
                controller: _maxLengthController,
                keyboardType: TextInputType.number,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                decoration: InputDecoration(
                  labelText: l10n.localizeWorkflowText('Max length'),
                  isDense: true,
                ),
              ),
            ),
            SizedBox(
              width: 112,
              child: TextField(
                key: const Key('batch-max-count'),
                controller: _maxCountController,
                keyboardType: TextInputType.number,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                decoration: InputDecoration(
                  labelText: l10n.localizeWorkflowText('Max cases'),
                  isDense: true,
                ),
              ),
            ),
            OutlinedButton.icon(
              key: const Key('batch-generate'),
              onPressed: _isRunning ? null : _generateInputs,
              icon: const Icon(Icons.auto_awesome),
              label: Text(l10n.localizeWorkflowText('Generate words')),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildActions(BuildContext context) {
    final l10n = appLocalizationsOf(context);
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        FilledButton.icon(
          key: const Key('batch-run'),
          onPressed: _isRunning ? _cancelActiveRun : _run,
          icon: Icon(_isRunning ? Icons.stop : Icons.play_arrow),
          label: Text(
            l10n.localizeWorkflowText(
              _isRunning ? 'Cancel batch' : 'Run batch',
            ),
          ),
        ),
        if (widget.comparisonExecutor != null)
          OutlinedButton.icon(
            key: const Key('batch-compare'),
            onPressed: _isRunning || _isComparing || _report == null
                ? null
                : _compare,
            icon: const Icon(Icons.compare_arrows),
            label: Text(
              l10n.localizeWorkflowText(
                _isComparing ? 'Comparing…' : 'Compare model',
              ),
            ),
          ),
        OutlinedButton.icon(
          key: const Key('batch-export-json'),
          onPressed: _report == null ? null : () => _export(json: true),
          icon: const Icon(Icons.data_object),
          label: Text(l10n.localizeWorkflowText('Export JSON')),
        ),
        OutlinedButton.icon(
          key: const Key('batch-export-csv'),
          onPressed: _report == null ? null : () => _export(json: false),
          icon: const Icon(Icons.table_view),
          label: Text(l10n.localizeWorkflowText('Export CSV')),
        ),
      ],
    );
  }

  Widget _buildConfiguration(BuildContext context) {
    final l10n = appLocalizationsOf(context);
    final formatter = LocaleValueFormatter.of(context);
    final strategies = widget.executor.strategyIds.toList()..sort();
    return ExpansionTile(
      key: const Key('batch-configuration'),
      tilePadding: EdgeInsets.zero,
      childrenPadding: const EdgeInsets.only(bottom: 8),
      title: Text(l10n.localizeWorkflowText('Limits and execution settings')),
      subtitle: Text(
        '${_strategyLabel(_strategyId)} · '
        '${l10n.localizeWorkflowText('Concurrency')} $_maxConcurrency · '
        '${l10n.localizeWorkflowText(_traceLabel(_traceRetention))}',
      ),
      children: [
        Wrap(
          spacing: 12,
          runSpacing: 12,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            SizedBox(
              width: 210,
              child: DropdownButtonFormField<String>(
                key: const Key('batch-strategy'),
                initialValue: _strategyId,
                isExpanded: true,
                decoration: InputDecoration(
                  labelText: l10n.localizeWorkflowText('Strategy'),
                ),
                items: [
                  for (final strategy in strategies)
                    DropdownMenuItem(
                      value: strategy,
                      child: Text(
                        _strategyLabel(strategy),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                ],
                onChanged: _isRunning
                    ? null
                    : (value) {
                        if (value == null) return;
                        setState(() {
                          _strategyId = value;
                          _invalidateFinishedResults();
                        });
                      },
              ),
            ),
            SizedBox(
              width: 210,
              child: DropdownButtonFormField<BatchTokenizationMode>(
                key: const Key('batch-tokenization'),
                initialValue: _tokenizationMode,
                isExpanded: true,
                decoration: InputDecoration(
                  labelText: l10n.localizeWorkflowText('Tokenization'),
                ),
                items: [
                  for (final mode in BatchTokenizationMode.values)
                    DropdownMenuItem(
                      value: mode,
                      child: Text(
                        l10n.localizeWorkflowText(_tokenizationLabel(mode)),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                ],
                onChanged: _isRunning
                    ? null
                    : (value) {
                        if (value == null) return;
                        setState(() {
                          _tokenizationMode = value;
                          _invalidateFinishedResults();
                        });
                      },
              ),
            ),
            _numberField(l10n, _stepLimitController, 'Step limit'),
            _numberField(
              l10n,
              _configurationLimitController,
              'Configuration limit',
            ),
            _numberField(l10n, _timeoutController, 'Timeout (s)'),
            _numberField(l10n, _traceLimitController, 'Trace steps'),
            SizedBox(
              width: 210,
              child: DropdownButtonFormField<BatchTraceRetention>(
                key: const Key('batch-trace-retention'),
                initialValue: _traceRetention,
                isExpanded: true,
                decoration: InputDecoration(
                  labelText: l10n.localizeWorkflowText('Retain traces'),
                ),
                items: [
                  for (final policy in const [
                    BatchTraceRetention.none,
                    BatchTraceRetention.failuresOnly,
                    BatchTraceRetention.all,
                  ])
                    DropdownMenuItem(
                      value: policy,
                      child: Text(
                        l10n.localizeWorkflowText(_traceLabel(policy)),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                ],
                onChanged: _isRunning
                    ? null
                    : (value) => setState(() {
                        _traceRetention = value ?? BatchTraceRetention.none;
                        _invalidateFinishedResults();
                      }),
              ),
            ),
            SizedBox(
              width: 190,
              child: DropdownButtonFormField<int>(
                key: const Key('batch-concurrency'),
                initialValue: _maxConcurrency,
                isExpanded: true,
                decoration: InputDecoration(
                  labelText: l10n.localizeWorkflowText('Concurrency'),
                ),
                items: [
                  for (final count in const [1, 2, 4, 8])
                    DropdownMenuItem(
                      value: count,
                      child: Text(formatter.integer(count)),
                    ),
                ],
                onChanged: _isRunning
                    ? null
                    : (value) => setState(() {
                        _maxConcurrency = value ?? 2;
                        _invalidateFinishedResults();
                      }),
              ),
            ),
            ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 320),
              child: CheckboxListTile(
                contentPadding: EdgeInsets.zero,
                title: Text(
                  l10n.localizeWorkflowText(
                    'Stop after first non-success outcome',
                  ),
                ),
                value: _stopOnFirstFailure,
                onChanged: _isRunning
                    ? null
                    : (value) => setState(() {
                        _stopOnFirstFailure = value ?? false;
                        _invalidateFinishedResults();
                      }),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _numberField(
    AppLocalizations l10n,
    TextEditingController controller,
    String label,
  ) {
    return SizedBox(
      width: 170,
      child: TextField(
        controller: controller,
        keyboardType: TextInputType.number,
        inputFormatters: [FilteringTextInputFormatter.digitsOnly],
        decoration: InputDecoration(
          labelText: l10n.localizeWorkflowText(label),
        ),
        onChanged: (_) => _invalidateFinishedResults(),
      ),
    );
  }

  Widget _buildProgress(BuildContext context) {
    final l10n = appLocalizationsOf(context);
    final formatter = LocaleValueFormatter.of(context);
    final completed = formatter.integer(_completed);
    final total = formatter.integer(_total);
    final value = _total == 0 ? null : _completed / _total;
    return Semantics(
      liveRegion: true,
      label: l10n.localizeWorkflowText(
        'Batch progress: $completed of $total cases complete',
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          LinearProgressIndicator(value: _isRunning ? value : 1),
          const SizedBox(height: 4),
          Text(
            l10n.localizeWorkflowText('$completed of $total cases complete'),
          ),
        ],
      ),
    );
  }

  Widget _buildResults(BuildContext context) {
    final l10n = appLocalizationsOf(context);
    final formatter = LocaleValueFormatter.of(context);
    final results = _visibleResults(context);
    final counts = _report?.outcomeCounts;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Wrap(
          spacing: 8,
          runSpacing: 8,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            Text(
              counts == null
                  ? l10n.localizeWorkflowText('Partial results')
                  : counts.entries
                        .map(
                          (entry) =>
                              '${_localizedOutcomeName(l10n, entry.key)}: '
                              '${formatter.integer(entry.value)}',
                        )
                        .join(' · '),
              style: Theme.of(context).textTheme.titleSmall,
            ),
            SizedBox(
              width: 220,
              child: TextField(
                key: const Key('batch-filter'),
                controller: _filterController,
                decoration: InputDecoration(
                  labelText: l10n.localizeWorkflowText(
                    'Filter input, status, or diagnostic',
                  ),
                  prefixIcon: const Icon(Icons.search),
                  isDense: true,
                ),
              ),
            ),
            SizedBox(
              width: 170,
              child: DropdownButtonFormField<BatchResultSort>(
                key: const Key('batch-sort'),
                initialValue: _sort,
                isExpanded: true,
                decoration: InputDecoration(
                  labelText: l10n.localizeWorkflowText('Sort'),
                ),
                items: [
                  DropdownMenuItem(
                    value: BatchResultSort.inputOrder,
                    child: Text(
                      l10n.localizeWorkflowText('Input order'),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  DropdownMenuItem(
                    value: BatchResultSort.outcome,
                    child: Text(
                      l10n.localizeWorkflowText('Outcome'),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  DropdownMenuItem(
                    value: BatchResultSort.elapsed,
                    child: Text(
                      l10n.localizeWorkflowText('Elapsed time'),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
                onChanged: (value) => setState(() {
                  _sort = value ?? BatchResultSort.inputOrder;
                }),
              ),
            ),
          ],
        ),
        if (_comparison case final comparison?) ...[
          const SizedBox(height: 8),
          Semantics(
            liveRegion: true,
            child: Text(
              comparison.hasDifferences
                  ? formatter.integersInLocalizedText(
                      l10n.localizeWorkflowText(
                        '${comparison.cases.where((item) => item.differs).length} '
                        'differences found in these finite cases.',
                      ),
                      [comparison.cases.where((item) => item.differs).length],
                    )
                  : l10n.localizeWorkflowText(
                      'No differences found in these finite cases. This is not '
                      'a proof of general equivalence.',
                    ),
              key: const Key('batch-comparison-summary'),
            ),
          ),
        ],
        const SizedBox(height: 8),
        if (results.isEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 16),
            child: Text(
              l10n.localizeWorkflowText('No results match the current filter.'),
            ),
          )
        else
          ConstrainedBox(
            constraints: const BoxConstraints(maxHeight: 480),
            child: Scrollbar(
              child: ListView.builder(
                key: const Key('batch-results'),
                shrinkWrap: true,
                itemCount: results.length,
                itemBuilder: (context, index) =>
                    _resultTile(context, results[index]),
              ),
            ),
          ),
      ],
    );
  }

  Widget _resultTile(BuildContext context, BatchCaseResult result) {
    final l10n = appLocalizationsOf(context);
    final formatter = LocaleValueFormatter.of(context);
    final comparison = _comparison?.cases
        .where((item) => item.caseId == result.inputCase.id)
        .firstOrNull;
    final differs = comparison?.differs ?? false;
    final metrics = <String>[
      if (result.metrics['steps'] case final steps?)
        l10n.localizeWorkflowText('steps ${formatter.number(steps)}'),
      if (result.metrics['configurations'] case final count?)
        l10n.localizeWorkflowText('configurations ${formatter.number(count)}'),
      l10n.localizeWorkflowText(
        '${formatter.compactDuration(result.elapsed)} elapsed',
      ),
    ].join(' · ');
    final input = result.inputCase.input.isEmpty
        ? EmptyStringNotation.symbolOf(context)
        : result.inputCase.input;
    final outcome = _localizedOutcomeName(l10n, result.outcome);
    final comparisonText = comparison == null
        ? null
        : l10n.localizeWorkflowText(
            'Comparison differs: '
            '${_localizedOutcomeName(l10n, comparison.right.outcome)}'
            '${comparison.right.output.isEmpty ? '' : ' · ${comparison.right.output.join(' ')}'}',
          );
    final details = [
      if (result.output.isNotEmpty)
        l10n.localizeWorkflowText('Output: ${result.output.join(' ')}'),
      metrics,
      if (result.diagnosticCode case final code?)
        l10n.localizeWorkflowText('Code: $code'),
      ..._localizedResultMessages(context, result),
      if (differs) comparisonText!,
    ].join('\n');
    final actions = <Widget>[
      IconButton(
        tooltip: l10n.localizeWorkflowText(
          result.trace.isEmpty ? 'Rerun with trace' : 'Open trace',
        ),
        onPressed: _isRunning
            ? null
            : () => result.trace.isEmpty
                  ? _rerunWithTrace(result)
                  : _openTrace(result),
        icon: Icon(result.trace.isEmpty ? Icons.replay : Icons.route),
      ),
      IconButton(
        tooltip: l10n.localizeWorkflowText('Rerun this case'),
        onPressed: _isRunning ? null : () => _rerunCase(result),
        icon: const Icon(Icons.refresh),
      ),
      IconButton(
        tooltip: l10n.localizeWorkflowText('Remove this case'),
        onPressed: _isRunning ? null : () => _removeCase(result),
        icon: const Icon(Icons.delete_outline),
      ),
    ];
    return LayoutBuilder(
      builder: (context, constraints) {
        final compact =
            constraints.maxWidth < 520 ||
            MediaQuery.textScalerOf(context).scale(1) > 1.5;
        return Semantics(
          container: true,
          label: l10n.localizeWorkflowText(
            'Case ${result.inputCase.id}, input $input, outcome $outcome',
          ),
          child: ListTile(
            key: Key('batch-result-${result.inputCase.id}'),
            leading: Icon(
              _outcomeIcon(result.outcome),
              color: _outcomeColor(context, result.outcome),
              semanticLabel: outcome,
            ),
            title: Text('$input — $outcome'),
            subtitle: compact
                ? Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(details),
                      Wrap(spacing: 0, children: actions),
                    ],
                  )
                : Text(details),
            isThreeLine: true,
            trailing: compact ? null : Wrap(spacing: 0, children: actions),
          ),
        );
      },
    );
  }

  List<BatchCaseResult> _visibleResults(BuildContext context) {
    final ordered = _report?.results ?? _partialResults.values.toList();
    final query = _filterController.text.toLowerCase();
    final l10n = appLocalizationsOf(context);
    final results = ordered.where((result) {
      if (query.isEmpty) return true;
      return result.inputCase.input.toLowerCase().contains(query) ||
          result.inputCase.id.toLowerCase().contains(query) ||
          result.outcome.name.toLowerCase().contains(query) ||
          _localizedOutcomeName(
            l10n,
            result.outcome,
          ).toLowerCase().contains(query) ||
          (result.diagnosticCode?.toLowerCase().contains(query) ?? false) ||
          _localizedResultMessages(
            context,
            result,
          ).any((message) => message.toLowerCase().contains(query));
    }).toList();
    switch (_sort) {
      case BatchResultSort.inputOrder:
        break;
      case BatchResultSort.outcome:
        results.sort(
          (left, right) => left.outcome.name.compareTo(right.outcome.name),
        );
      case BatchResultSort.elapsed:
        results.sort((left, right) => left.elapsed.compareTo(right.elapsed));
    }
    return results;
  }

  Future<void> _run() async {
    final cases = _currentCases();
    if (cases.isEmpty) {
      _setMessage('Add at least one case. Use ε for the empty word.');
      return;
    }
    if (cases.length > _caseLimit) {
      _setMessage('The batch limit is $_caseLimit cases.', [_caseLimit]);
      return;
    }
    final limits = _readLimits();
    if (limits == null) return;
    _cancelActiveRun();
    final generation = ++_generation;
    final request = _request(
      executor: widget.executor,
      cases: cases,
      limits: limits,
      generation: generation,
    );
    late final BatchRunHandle handle;
    try {
      handle = const BatchExecutionRunner().start(request, widget.executor);
    } on BatchValidationException catch (error) {
      _setStructuredMessages(error.messages);
      return;
    }
    final priorProgressSubscription = _progressSubscription;
    if (priorProgressSubscription != null) {
      unawaited(priorProgressSubscription.cancel());
    }
    _activeRun = handle;
    _progressSubscription = handle.progress.listen((progress) {
      if (!mounted || progress.generation != _generation) return;
      setState(() {
        _partialResults[progress.result.inputCase.id] = progress.result;
        _completed = progress.completed;
        _total = progress.total;
      });
    });
    setState(() {
      _isRunning = true;
      _report = null;
      _comparison = null;
      _partialResults.clear();
      _completed = 0;
      _total = cases.length;
      _replaceMessage('Batch started for ${cases.length} cases.', [
        cases.length,
      ]);
    });
    final report = await handle.report;
    if (!mounted || generation != _generation) return;
    final completedProgressSubscription = _progressSubscription;
    if (completedProgressSubscription != null) {
      unawaited(completedProgressSubscription.cancel());
    }
    _progressSubscription = null;
    setState(() {
      _activeRun = null;
      _isRunning = false;
      _report = report;
      _partialResults
        ..clear()
        ..addEntries(
          report.results.map((result) => MapEntry(result.inputCase.id, result)),
        );
      _completed = report.results.length;
      _replaceMessage(
        report.wasCancelled
            ? 'Batch cancelled; completed and cancelled cases are retained.'
            : 'Batch complete in ${_formatDuration(report.elapsed)}.',
        report.wasCancelled ? const [] : [_durationMagnitude(report.elapsed)],
      );
    });
  }

  Future<void> _compare() async {
    final primary = _report;
    final executor = widget.comparisonExecutor;
    if (primary == null || executor == null) return;
    if (!executor.strategyIds.contains(_strategyId)) {
      _setMessage('The comparison model does not support $_strategyId.');
      return;
    }
    final generation = ++_generation;
    setState(() {
      _isComparing = true;
      _replaceMessage('Comparing the same finite input cases…');
    });
    try {
      final request = _request(
        executor: executor,
        cases: primary.request.cases,
        limits: primary.request.sharedLimits,
        generation: generation,
      );
      final handle = const BatchExecutionRunner().start(request, executor);
      _activeRun = handle;
      final right = await handle.report;
      if (!mounted || generation != _generation) return;
      setState(() {
        _activeRun = null;
        _comparison = BatchReportComparator.compare(primary, right);
        _replaceMessage(
          'Finite comparison complete. It does not prove general '
          'equivalence.',
        );
      });
    } catch (error) {
      if (mounted && generation == _generation) {
        _setMessage('Comparison failed: $error');
      }
    } finally {
      if (mounted && generation == _generation) {
        setState(() {
          _activeRun = null;
          _isComparing = false;
        });
      }
    }
  }

  Future<void> _rerunCase(BatchCaseResult result) async {
    final limits = _readLimits();
    if (limits == null) return;
    _cancelActiveRun();
    final generation = ++_generation;
    final request = _request(
      executor: widget.executor,
      cases: [result.inputCase],
      limits: limits,
      generation: generation,
    );
    setState(() {
      _isRunning = true;
      _replaceMessage('Rerunning ${result.inputCase.id}…');
    });
    final handle = const BatchExecutionRunner().start(request, widget.executor);
    _activeRun = handle;
    final report = await handle.report;
    if (!mounted || generation != _generation) return;
    setState(() {
      _activeRun = null;
      _isRunning = false;
      _partialResults[result.inputCase.id] = report.results.single;
      final prior = _report;
      if (prior != null) {
        _report = BatchExecutionReport(
          request: prior.request,
          results: [
            for (final item in prior.results)
              if (item.inputCase.id == result.inputCase.id)
                report.results.single
              else
                item,
          ],
          startedAt: prior.startedAt,
          elapsed: prior.elapsed + report.elapsed,
        );
      }
      _comparison = null;
      _replaceMessage('Case ${result.inputCase.id} rerun complete.');
    });
  }

  Future<void> _rerunWithTrace(BatchCaseResult result) async {
    final limits = _readLimits();
    if (limits == null) return;
    _cancelActiveRun();
    final generation = ++_generation;
    final request = BatchExecutionRequest(
      modelId: widget.executor.modelId,
      modelRevision: widget.executor.modelRevision,
      strategyId: _strategyId,
      tokenizationMode: _tokenizationMode,
      cases: [result.inputCase],
      sharedLimits: limits,
      traceRetention: BatchTraceRetention.selectedCase,
      selectedTraceCaseId: result.inputCase.id,
      maxConcurrency: 1,
      generation: generation,
    );
    setState(() {
      _isRunning = true;
      _replaceMessage('Rerunning ${result.inputCase.id} with trace…');
    });
    final handle = const BatchExecutionRunner().start(request, widget.executor);
    _activeRun = handle;
    final traced = await handle.report;
    if (!mounted || generation != _generation) return;
    setState(() {
      _activeRun = null;
      _isRunning = false;
      _replaceMessage(
        traced.wasCancelled
            ? 'Trace rerun cancelled.'
            : 'Trace rerun complete.',
      );
    });
    if (traced.wasCancelled) return;
    _openTrace(traced.results.single);
  }

  void _openTrace(BatchCaseResult result) {
    final l10n = appLocalizationsOf(context);
    if (widget.onOpenTrace case final callback?) {
      callback(result);
      return;
    }
    showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          l10n.localizeWorkflowText('Trace · ${result.inputCase.id}'),
        ),
        content: SizedBox(
          width: 640,
          child: result.trace.isEmpty
              ? Text(
                  l10n.localizeWorkflowText(
                    'The executor returned no trace for this case.',
                  ),
                )
              : SingleChildScrollView(
                  child: SelectableText(
                    const JsonEncoder.withIndent('  ').convert(result.trace),
                  ),
                ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(l10n.localizeWorkflowText('Close')),
          ),
        ],
      ),
    );
  }

  Future<void> _importInputs() async {
    try {
      final selection = await _fileService.pickInputs(
        dialogTitle: appLocalizationsOf(
          context,
        ).localizeWorkflowText('Import TXT/CSV'),
      );
      if (selection == null || !mounted) return;
      final cases = BatchInputFileParser.parseUtf8(
        selection.bytes,
        filename: selection.filename,
        maxCases: _caseLimit,
      );
      setState(() {
        _preparedCases = cases;
        _inputController.text = cases
            .map(
              (inputCase) => inputCase.input.isEmpty
                  ? EmptyStringNotation.symbolOf(context)
                  : inputCase.input,
            )
            .join('\n');
        _clearResults(
          message: 'Imported ${cases.length} cases from ${selection.filename}.',
          messageIntegers: [cases.length],
          notify: false,
        );
      });
    } on BatchInputFormatException catch (error) {
      _setStructuredMessages([error.structuredMessage]);
    } on FormatException catch (error) {
      _setMessage('Could not import inputs: ${error.message}');
    } catch (error) {
      _setMessage('Could not import inputs: $error');
    }
  }

  void _addCase() {
    final cases = _currentCases().toList();
    if (cases.length >= _caseLimit) {
      _setMessage('The batch limit is $_caseLimit cases.', [_caseLimit]);
      return;
    }
    var serial = cases.length + 1;
    var id = 'manual-${serial.toString().padLeft(6, '0')}';
    final existingIds = cases.map((inputCase) => inputCase.id).toSet();
    while (existingIds.contains(id)) {
      serial++;
      id = 'manual-${serial.toString().padLeft(6, '0')}';
    }
    cases.add(BatchInputCase(id: id, input: ''));
    _replaceCases(cases, message: 'Added an empty-word case.');
  }

  void _removeCase(BatchCaseResult result) {
    final cases = _currentCases()
        .where((inputCase) => inputCase.id != result.inputCase.id)
        .toList();
    _replaceCases(cases, message: 'Removed case ${result.inputCase.id}.');
  }

  void _replaceCases(List<BatchInputCase> cases, {required String message}) {
    setState(() {
      _preparedCases = List<BatchInputCase>.unmodifiable(cases);
      _inputController.text = cases
          .map(
            (inputCase) => inputCase.input.isEmpty
                ? EmptyStringNotation.symbolOf(context)
                : inputCase.input,
          )
          .join('\n');
      _clearResults(message: message, notify: false);
    });
  }

  void _generateInputs() {
    final maxLength = int.tryParse(_maxLengthController.text);
    final maxCount = int.tryParse(_maxCountController.text);
    if (maxLength == null ||
        maxLength < 0 ||
        maxCount == null ||
        maxCount <= 0) {
      _setMessage('Generation length must be non-negative and count positive.');
      return;
    }
    if (maxCount > _caseLimit) {
      _setMessage('Generated case count cannot exceed $_caseLimit.', [
        _caseLimit,
      ]);
      return;
    }
    if (widget.alphabet.isEmpty && maxLength > 0) {
      _setMessage('The model has no alphabet; only ε can be generated.');
    }
    final cases = BatchInputGenerator.boundedWords(
      alphabet: widget.alphabet,
      maxLength: maxLength,
      maxCount: maxCount,
    );
    setState(() {
      _preparedCases = cases;
      _inputController.text = cases
          .map(
            (inputCase) => inputCase.input.isEmpty
                ? EmptyStringNotation.symbolOf(context)
                : inputCase.input,
          )
          .join('\n');
      _clearResults(
        message: 'Generated ${cases.length} ordered cases.',
        messageIntegers: [cases.length],
        notify: false,
      );
    });
  }

  Future<void> _export({required bool json}) async {
    final report = _report;
    if (report == null) return;
    final extension = json ? 'json' : 'csv';
    final contents = json
        ? BatchReportEncoder.json(report)
        : BatchReportEncoder.csv(report);
    try {
      final path = await _fileService.saveReport(
        filename: 'batch-${_safeFilename(report.request.modelId)}.$extension',
        contents: contents,
        dialogTitle: appLocalizationsOf(
          context,
        ).localizeWorkflowText(json ? 'Export JSON' : 'Export CSV'),
      );
      if (!mounted || path == null) return;
      _setMessage('Report exported to $path.');
    } catch (error) {
      _setMessage('Could not export report: $error');
    }
  }

  BatchExecutionRequest _request({
    required BatchCaseExecutor executor,
    required List<BatchInputCase> cases,
    required BatchExecutionLimits limits,
    required int generation,
  }) {
    return BatchExecutionRequest(
      modelId: executor.modelId,
      modelRevision: executor.modelRevision,
      strategyId: _strategyId,
      tokenizationMode: _tokenizationMode,
      cases: cases,
      sharedLimits: limits,
      traceRetention: _traceRetention,
      stopOnFirstFailure: _stopOnFirstFailure,
      maxConcurrency: _maxConcurrency,
      generation: generation,
    );
  }

  List<BatchInputCase> _currentCases() {
    final prepared = _preparedCases;
    if (prepared != null) return _applyTokenization(prepared);
    if (_inputController.text.isEmpty) return const [];
    return _applyTokenization(
      BatchInputGenerator.multiline(_inputController.text),
    );
  }

  List<BatchInputCase> _applyTokenization(List<BatchInputCase> cases) {
    if (_tokenizationMode != BatchTokenizationMode.explicitTokens) return cases;
    return [
      for (final inputCase in cases)
        if (inputCase.tokens != null)
          inputCase
        else
          BatchInputCase(
            id: inputCase.id,
            input: inputCase.input,
            tokens: inputCase.input.trim().isEmpty
                ? const []
                : inputCase.input.trim().split(RegExp(r'\s+')),
          ),
    ];
  }

  BatchExecutionLimits? _readLimits() {
    final steps = int.tryParse(_stepLimitController.text);
    final configurations = int.tryParse(_configurationLimitController.text);
    final timeoutSeconds = int.tryParse(_timeoutController.text);
    final traceSteps = int.tryParse(_traceLimitController.text);
    if (steps == null ||
        steps <= 0 ||
        configurations == null ||
        configurations <= 0 ||
        timeoutSeconds == null ||
        timeoutSeconds <= 0 ||
        traceSteps == null ||
        traceSteps < 0 ||
        traceSteps > BatchExecutionLimits.maxRetainedTraceStepsHardCap) {
      _setMessage(
        'Step, configuration, and timeout limits must be positive; the trace '
        'limit must be between 0 and '
        '${BatchExecutionLimits.maxRetainedTraceStepsHardCap}.',
        [0, BatchExecutionLimits.maxRetainedTraceStepsHardCap],
      );
      return null;
    }
    return BatchExecutionLimits(
      maxSteps: steps,
      maxConfigurations: configurations,
      timeout: Duration(seconds: timeoutSeconds),
      maxRetainedTraceSteps: traceSteps,
    );
  }

  void _cancelActiveRun() {
    if (!_isRunning && _activeRun == null) return;
    _activeRun?.cancel();
    setState(() {
      _replaceMessage('Cancelling batch…');
    });
  }

  void _invalidateFinishedResults() {
    if (_isRunning || _report == null) return;
    _activeRun?.cancel();
    setState(() {
      _generation++;
      _activeRun = null;
      _report = null;
      _comparison = null;
      _partialResults.clear();
      _completed = 0;
      _total = 0;
      _isComparing = false;
      _replaceMessage('Settings changed; run the batch again.');
    });
  }

  void _clearResults({
    String? message,
    List<int> messageIntegers = const [],
    bool notify = true,
  }) {
    void clear() {
      _activeRun?.cancel();
      _activeRun = null;
      final progressSubscription = _progressSubscription;
      if (progressSubscription != null) {
        unawaited(progressSubscription.cancel());
      }
      _progressSubscription = null;
      _generation++;
      _report = null;
      _comparison = null;
      _partialResults.clear();
      _completed = 0;
      _total = 0;
      _isRunning = false;
      _isComparing = false;
      _replaceMessage(message, messageIntegers);
    }

    if (notify) {
      setState(clear);
    } else {
      clear();
    }
  }

  void _setMessage(String message, [List<int> integers = const []]) {
    if (!mounted) return;
    setState(() => _replaceMessage(message, integers));
  }

  void _setStructuredMessages(Iterable<StructuredMessage> messages) {
    if (!mounted) return;
    setState(() {
      _message = null;
      _messageIntegers = const [];
      _structuredMessages = List<StructuredMessage>.unmodifiable(messages);
    });
  }

  void _replaceMessage(String? message, [List<int> integers = const []]) {
    _message = message;
    _messageIntegers = List<int>.unmodifiable(integers);
    _structuredMessages = const [];
  }

  void _refreshFilter() {
    if (mounted) setState(() {});
  }

  String _strategyLabel(String strategy) =>
      widget.strategyLabels[strategy] ?? strategy;
}

List<String> _localizedResultMessages(
  BuildContext context,
  BatchCaseResult result,
) {
  final l10n = appLocalizationsOf(context);
  return [
    if (result.message case final message?) l10n.localizeWorkflowText(message),
    if (result.structuredMessage case final message?)
      l10n.resolveStructuredMessage(message),
  ];
}

String _localizedOutcomeName(AppLocalizations l10n, BatchOutcomeCode outcome) {
  if (!l10n.localeName.startsWith('pt')) return outcome.name;
  return l10n.localizeWorkflowText(switch (outcome) {
    BatchOutcomeCode.accepted => 'Accepted',
    BatchOutcomeCode.rejected => 'Rejected',
    BatchOutcomeCode.output => 'Output',
    BatchOutcomeCode.undefinedTransition => 'Undefined transition',
    BatchOutcomeCode.conflict => 'Conflict',
    BatchOutcomeCode.invalidInput => 'Invalid input',
    BatchOutcomeCode.boundedUnknown => 'Bounded unknown',
    BatchOutcomeCode.timeout => 'Timeout',
    BatchOutcomeCode.configurationLimit => 'Configuration limit',
    BatchOutcomeCode.provenCycle => 'Proven cycle',
    BatchOutcomeCode.cancelled => 'Cancelled',
    BatchOutcomeCode.modelError => 'Model error',
    BatchOutcomeCode.staleRequest => 'Stale request',
  });
}

String _resolveInitialStrategy(BatchExecutionPanel widget) {
  final strategies = widget.executor.strategyIds.toList()..sort();
  if (strategies.isEmpty) {
    throw ArgumentError('A batch executor must support at least one strategy.');
  }
  return widget.initialStrategyId ?? strategies.first;
}

bool _usesEmptyStringTerminology(String? message) =>
    message == 'Add at least one case. Use ε for the empty word.' ||
    message == 'The model has no alphabet; only ε can be generated.';

String _tokenizationLabel(BatchTokenizationMode mode) => switch (mode) {
  BatchTokenizationMode.rawString => 'Raw string',
  BatchTokenizationMode.unicodeScalar => 'Unicode symbols',
  BatchTokenizationMode.explicitTokens => 'Explicit tokens',
};

String _traceLabel(BatchTraceRetention retention) => switch (retention) {
  BatchTraceRetention.none => 'No traces',
  BatchTraceRetention.failuresOnly => 'Failures only',
  BatchTraceRetention.selectedCase => 'Selected case',
  BatchTraceRetention.all => 'All cases',
};

String _formatDuration(Duration duration) {
  if (duration.inMilliseconds > 0) return '${duration.inMilliseconds} ms';
  return '${duration.inMicroseconds} µs';
}

int _durationMagnitude(Duration duration) => duration.inMilliseconds > 0
    ? duration.inMilliseconds
    : duration.inMicroseconds;

String _safeFilename(String source) {
  final safe = source.replaceAll(RegExp(r'[^A-Za-z0-9._-]+'), '-');
  return safe.isEmpty ? 'model' : safe;
}

IconData _outcomeIcon(BatchOutcomeCode outcome) => switch (outcome) {
  BatchOutcomeCode.accepted || BatchOutcomeCode.output => Icons.check_circle,
  BatchOutcomeCode.rejected ||
  BatchOutcomeCode.undefinedTransition => Icons.cancel,
  BatchOutcomeCode.cancelled || BatchOutcomeCode.staleRequest => Icons.stop,
  BatchOutcomeCode.boundedUnknown ||
  BatchOutcomeCode.timeout ||
  BatchOutcomeCode.configurationLimit => Icons.help,
  BatchOutcomeCode.conflict ||
  BatchOutcomeCode.invalidInput ||
  BatchOutcomeCode.modelError ||
  BatchOutcomeCode.provenCycle => Icons.warning,
};

Color _outcomeColor(BuildContext context, BatchOutcomeCode outcome) {
  final colors = Theme.of(context).colorScheme;
  if (outcome.isSuccessful) return colors.primary;
  if (outcome.isInconclusive) return colors.tertiary;
  return colors.error;
}
