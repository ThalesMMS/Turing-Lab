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

import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/algorithms/grammar_parser.dart';
import '../../core/algorithms/grammar_analyzer.dart';
import '../../core/algorithms/brute_force_cfg_parser.dart';
import '../../core/algorithms/lr1_parser.dart';
import '../../core/batch_execution/batch_execution.dart';
import '../../core/algorithms/cfg/cyk_parser.dart';
import '../../core/models/cyk_step.dart';
import '../../core/models/brute_force_parse_models.dart';
import '../../core/models/grammar.dart';
import '../../core/models/grammar_parse_report.dart';
import '../../core/models/ll1_parse_step.dart';
import '../../core/models/lr1_models.dart';
import '../../core/models/typed_algorithm_step.dart';
import '../../core/messages/structured_message.dart';
import '../../core/grammar/phrase_structure/phrase_structure.dart';
import '../../core/grammar/teaching/grammar_teaching_session_store.dart';
import '../../core/result.dart';
import '../../injection/data_providers.dart';
import '../../l10n/app_localizations.dart';
import '../../l10n/app_localizations_resolver.dart';
import '../../l10n/app_localizations_structured_messages.dart';
import '../../l10n/app_localizations_workflows.dart';
import '../providers/grammar_provider.dart';
import '../localization/locale_value_formatter.dart';
import 'algorithm_step_renderer_registry.dart';
import 'base_simulation_panel.dart';
import 'batch_execution/batch_execution_panel.dart';
import 'brute_force_search_options.dart';
import 'brute_force_teaching_workspace.dart';
import 'derivation_tree_view.dart';
import 'grammar_sentential_form_card.dart';
import 'lr1_teaching_workspace.dart';
import 'parse_table_teaching_workspace.dart';
import 'step_explanation_card.dart';
import 'user_derivation_workspace.dart';
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
  final TextEditingController _bruteDepthController = TextEditingController(
    text: '32',
  );
  final TextEditingController _bruteFrontierController = TextEditingController(
    text: '5000',
  );
  final TextEditingController _bruteResultCapController = TextEditingController(
    text: '3',
  );
  final TextEditingController _bruteTimeLimitController = TextEditingController(
    text: '5000',
  );
  final AlgorithmStepRendererRegistry _cykStepRendererRegistry =
      AlgorithmStepRendererRegistry.withDefaults();

  bool _isParsing = false;
  GrammarParseReport? _parseReport;
  ParsingStrategyHint _selectedAlgorithm = ParsingStrategyHint.cyk;

  // Only used for CYK "with steps" mode.
  // Keeps UI changes surgical: other parsing strategies keep using GrammarParseReport.
  ({bool accepted, List<CYKStep> steps})? _cykStepsResult;

  int _selectedStepIndex = 0;
  int _parseRequestSerial = 0;
  bool _isPlaying = false;
  Timer? _playbackTimer;
  Grammar? _ll1Grammar;
  GrammarAnalysisReport<Map<String, Set<String>>>? _firstSetsReport;
  GrammarAnalysisReport<Map<String, Set<String>>>? _followSetsReport;
  GrammarAnalysisReport<LL1ParseTable>? _ll1TableReport;
  ({String nonTerminal, String lookahead})? _selectedTableCell;
  Grammar? _lr1Grammar;
  LR1Construction? _lr1Construction;
  LR1ParseResult? _lr1Result;
  BruteForceDerivationMode _bruteMode = BruteForceDerivationMode.leftmost;
  BruteForceCancellationToken? _bruteCancellationToken;
  BruteForceSearchProgress? _bruteProgress;
  ContextFreeGrammar? _manualGrammar;
  GrammarSymbolSequence? _manualTarget;
  UserDerivationDiagnosticCode? _manualInvalidationCode;
  int _manualSessionSerial = 0;

  static Result<GrammarParseReport> _parseWithReportInBackground(
    ({Grammar grammar, String inputString, ParsingStrategyHint strategyHint})
    request,
  ) {
    return GrammarParser.parseWithReport(
      request.grammar,
      request.inputString,
      strategyHint: request.strategyHint,
    );
  }

  static Result<CYKParseResult> _parseCykWithStepsInBackground(
    ({Grammar grammar, String inputString}) request,
  ) {
    return CYKParser.parseWithSteps(
      request.grammar,
      request.inputString,
      timeout: const Duration(seconds: 5),
    );
  }

  static _LL1TeachingWorkspace _parseLl1WorkspaceInBackground(
    ({Grammar grammar, String inputString}) request,
  ) {
    return _LL1TeachingWorkspace(
      grammar: request.grammar,
      firstSets: GrammarAnalyzer.computeFirstSets(request.grammar),
      followSets: GrammarAnalyzer.computeFollowSets(request.grammar),
      table: GrammarAnalyzer.buildLL1ParseTable(request.grammar),
      parse: GrammarParser.parseWithReport(
        request.grammar,
        request.inputString,
        strategyHint: ParsingStrategyHint.ll,
      ),
    );
  }

  static _LR1TeachingWorkspace _parseLr1WorkspaceInBackground(
    ({Grammar grammar, String inputString}) request,
  ) {
    final constructionResult = LR1Parser.build(request.grammar);
    final construction = constructionResult.construction;
    if (construction == null) {
      return _LR1TeachingWorkspace(
        error: constructionResult.message,
        structuredError: constructionResult.structuredMessage,
      );
    }
    final parse = LR1Parser.parse(
      request.grammar,
      request.inputString,
      construction: construction,
    );
    final outcome = switch (parse.outcome) {
      LR1ParseOutcome.accepted => GrammarParseOutcome.accepted,
      LR1ParseOutcome.rejected => GrammarParseOutcome.rejected,
      LR1ParseOutcome.invalidGrammar ||
      LR1ParseOutcome.tableConstructionFailure =>
        GrammarParseOutcome.invalidInput,
      LR1ParseOutcome.tokenizationFailure =>
        GrammarParseOutcome.tokenizationFailure,
      LR1ParseOutcome.conflict => GrammarParseOutcome.conflict,
      LR1ParseOutcome.cancelled => GrammarParseOutcome.cancelled,
      LR1ParseOutcome.timedOut => GrammarParseOutcome.timedOut,
      LR1ParseOutcome.resourceLimit => GrammarParseOutcome.stepLimit,
    };
    final report = parse.accepted
        ? GrammarParseReport.accepted(
            inputString: request.inputString,
            executionTime: parse.executionTime,
            trees: parse.tree == null ? const [] : [parse.tree!],
            lr1Steps: parse.steps,
          )
        : GrammarParseReport.rejected(
            inputString: request.inputString,
            farthestPosition: parse.farthestPosition,
            executionTime: parse.executionTime,
            expectedSymbols: parse.expectedTerminals,
            message: parse.message,
            structuredMessage: parse.structuredMessage,
            lr1Steps: parse.steps,
            outcome: outcome,
          );
    return _LR1TeachingWorkspace(
      grammar: request.grammar,
      construction: construction,
      parse: parse,
      report: report,
    );
  }

  @override
  void dispose() {
    _playbackTimer?.cancel();
    _bruteCancellationToken?.cancel();
    _parseRequestSerial++;
    _inputController.dispose();
    _bruteDepthController.dispose();
    _bruteFrontierController.dispose();
    _bruteResultCapController.dispose();
    _bruteTimeLimitController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final grammarState = ref.watch(grammarProvider);
    ref.listen<GrammarState>(grammarProvider, (previous, next) {
      if (previous == null || identical(previous, next)) return;
      _invalidateStaleResult(
        manualInvalidation: UserDerivationDiagnosticCode.sourceChanged,
      );
    });
    return Card(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeader(context),
            const SizedBox(height: 16),
            _buildAlgorithmSelector(context),
            if (_selectedAlgorithm == ParsingStrategyHint.bruteForce)
              BruteForceSearchOptions(
                mode: _bruteMode,
                onModeChanged: (value) {
                  _invalidateStaleResult();
                  setState(() => _bruteMode = value);
                },
                depthController: _bruteDepthController,
                frontierController: _bruteFrontierController,
                resultCapController: _bruteResultCapController,
                timeLimitController: _bruteTimeLimitController,
                onLimitsChanged: _invalidateStaleResult,
                progress: _bruteProgress,
              ),
            const SizedBox(height: 16),
            _buildInputSection(context),
            const SizedBox(height: 12),
            _buildManualDerivationAction(context),
            if (_manualGrammar != null && _manualTarget != null)
              UserDerivationWorkspace(
                key: ValueKey('cfg-manual-session-$_manualSessionSerial'),
                grammar: _manualGrammar!,
                target: _manualTarget!,
                invalidationCode: _manualInvalidationCode,
                onInvalidatedRestart: _startManualDerivation,
              ),
            const SizedBox(height: 16),
            _buildParseButton(context),
            const SizedBox(height: 16),
            _buildResultsSection(context),
            if (grammarState.productions.isNotEmpty) ...[
              const SizedBox(height: 16),
              ExpansionTile(
                key: const Key('grammar-batch-section'),
                tilePadding: EdgeInsets.zero,
                title: Text(
                  appLocalizationsOf(
                    context,
                  ).localizeWorkflowText('Batch parsing'),
                ),
                subtitle: Text(
                  appLocalizationsOf(context).localizeWorkflowText(
                    'Run ordered cases with Earley, CYK, LL(1), LR(1), or brute force',
                  ),
                ),
                children: [
                  Builder(
                    builder: (context) {
                      final l10n = appLocalizationsOf(context);
                      final grammar = ref
                          .read(grammarProvider.notifier)
                          .buildGrammar();
                      return BatchExecutionPanel(
                        executor: GrammarBatchExecutor(grammar),
                        alphabet: grammar.terminals,
                        title: l10n.localizeWorkflowText(
                          'Grammar batch execution',
                        ),
                        strategyLabels: {
                          'auto': l10n.localizeWorkflowText(
                            'Automatic (Earley)',
                          ),
                          'bruteForce': l10n.localizeWorkflowText(
                            'Brute force',
                          ),
                          'cyk': l10n.localizeWorkflowText('CYK'),
                          'll': l10n.localizeWorkflowText('LL(1)'),
                          'lr': l10n.localizeWorkflowText('LR(1)'),
                        },
                        initialStrategyId: 'auto',
                      );
                    },
                  ),
                ],
              ),
            ],
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
            isExpanded: true,
            decoration: const InputDecoration(
              border: OutlineInputBorder(),
              isDense: true,
            ),
            items: GrammarParser.capabilities
                .where((capability) => capability.isAvailable)
                .map(
                  (capability) => DropdownMenuItem(
                    value: capability.strategy,
                    child: Text(
                      l10n.localizeWorkflowText(capability.label),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                )
                .toList(growable: false),
            onChanged: (value) {
              if (value == null) {
                return;
              }
              setState(() {
                _stopPlayback();
                _selectedAlgorithm = value;
                _clearLl1Workspace();
                _clearLr1Workspace();
                _clearBruteWorkspace();
                _parseReport = null;
                _cykStepsResult = null;
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
            key: const ValueKey('grammar-parser-input'),
            controller: _inputController,
            decoration: InputDecoration(
              labelText: l10n.inputString,
              hintText: l10n.simulationInputHint,
              border: const OutlineInputBorder(),
            ),
            onChanged: (_) => _invalidateStaleResult(
              manualInvalidation: UserDerivationDiagnosticCode.targetChanged,
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

  Widget _buildManualDerivationAction(BuildContext context) {
    final l10n = appLocalizationsOf(context);
    return SizedBox(
      width: double.infinity,
      child: OutlinedButton.icon(
        key: const ValueKey('start-manual-derivation'),
        onPressed: _startManualDerivation,
        icon: const Icon(Icons.edit_note),
        label: Text(
          l10n.localizeWorkflowText(
            _manualGrammar == null
                ? 'Start user-controlled derivation'
                : 'Start a new user-controlled derivation',
          ),
        ),
      ),
    );
  }

  Widget _buildParseButton(BuildContext context) {
    final l10n = appLocalizationsOf(context);
    final canCancel =
        _isParsing && _selectedAlgorithm == ParsingStrategyHint.bruteForce;
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton.icon(
        onPressed: canCancel
            ? _cancelBruteSearch
            : _isParsing
            ? null
            : _parseString,
        icon: canCancel
            ? const Icon(Icons.stop)
            : _isParsing
            ? const SizedBox(
                width: 16,
                height: 16,
                child: CircularProgressIndicator(strokeWidth: 2),
              )
            : const Icon(Icons.play_arrow),
        label: Text(
          canCancel
              ? l10n.localizeWorkflowText('Cancel search')
              : _isParsing
              ? l10n.parsingEllipsis
              : l10n.parseString,
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
    final l10n = appLocalizationsOf(context);
    final formatter = LocaleValueFormatter.of(context);
    final isAccepted = report.accepted;
    final colorScheme = Theme.of(context).colorScheme;
    final isInconclusive =
        report.outcome == GrammarParseOutcome.boundedUnknown ||
        report.outcome == GrammarParseOutcome.cancelled;
    final color = isAccepted
        ? colorScheme.tertiary
        : isInconclusive
        ? colorScheme.secondary
        : colorScheme.error;
    final expectedSymbols = report.expectedSymbols.toList(growable: false)
      ..sort();
    final bruteForceMessage = report.bruteForceResult?.structuredMessage;
    final reportMessage = report.structuredMessage;

    final cykSteps = _cykStepsResult?.steps;
    final ll1Steps = report.ll1Steps;
    final status = switch (report.outcome) {
      GrammarParseOutcome.accepted => appLocalizationsOf(context).accepted,
      GrammarParseOutcome.conflict =>
        appLocalizationsOf(context).localizeWorkflowText(
          _selectedAlgorithm == ParsingStrategyHint.lr
              ? 'Canonical LR(1) conflict'
              : 'LL(1) conflict',
        ),
      GrammarParseOutcome.timedOut => appLocalizationsOf(
        context,
      ).localizeWorkflowText('Time limit reached'),
      GrammarParseOutcome.cancelled => appLocalizationsOf(
        context,
      ).localizeWorkflowText('Cancelled'),
      GrammarParseOutcome.stepLimit => appLocalizationsOf(
        context,
      ).localizeWorkflowText('Step limit reached'),
      GrammarParseOutcome.boundedUnknown => appLocalizationsOf(
        context,
      ).localizeWorkflowText('Inconclusive within limits'),
      GrammarParseOutcome.invalidInput => appLocalizationsOf(
        context,
      ).localizeWorkflowText('Invalid input'),
      GrammarParseOutcome.tokenizationFailure => appLocalizationsOf(
        context,
      ).localizeWorkflowText('Unable to tokenize input'),
      GrammarParseOutcome.rejected => appLocalizationsOf(context).rejected,
    };

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
                isAccepted
                    ? Icons.check_circle
                    : isInconclusive
                    ? Icons.info
                    : Icons.cancel,
                color: color,
                size: 24,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  status,
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
            appLocalizationsOf(
              context,
            ).executionTimeLabel(_formatExecutionTime(report.executionTime)),
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          if (cykSteps != null && cykSteps.isNotEmpty) ...[
            const SizedBox(height: 16),
            _buildCykStepsSection(context, cykSteps),
          ] else ...[
            if (_lr1Construction != null &&
                _lr1Result != null &&
                _lr1Grammar != null) ...[
              const SizedBox(height: 16),
              LR1TeachingWorkspace(
                grammar: _lr1Grammar!,
                construction: _lr1Construction!,
                parseResult: _lr1Result!,
                sessionStore: _teachingSessionStore(),
              ),
            ],
            if (_ll1TableReport != null && _ll1Grammar != null) ...[
              const SizedBox(height: 16),
              _buildLl1TeachingEnvironment(context),
            ],
            if (ll1Steps.isNotEmpty) ...[
              const SizedBox(height: 16),
              _buildLl1StepsSection(context, ll1Steps),
            ],
            if (report.bruteForceResult != null) ...[
              const SizedBox(height: 16),
              BruteForceTeachingWorkspace(result: report.bruteForceResult!),
            ],
            if (!isAccepted) ...[
              const SizedBox(height: 8),
              if (report.outcome == GrammarParseOutcome.rejected)
                Text(
                  _localizedFarthestPositionLabel(
                    l10n,
                    formatter,
                    report.farthestPosition,
                    report.inputString.length,
                  ),
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
              if (report.expectedSymbols.isNotEmpty) ...[
                const SizedBox(height: 8),
                Text(
                  appLocalizationsOf(context).expectedColon,
                  style: Theme.of(
                    context,
                  ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600),
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
                            style: Theme.of(context).textTheme.bodySmall
                                ?.copyWith(
                                  fontFamilyFallback:
                                      kMonospaceFontFamilyFallback,
                                ),
                          ),
                        ),
                      )
                      .toList(growable: false),
                ),
              ],
              if (report.message != null &&
                  !(report.outcome == GrammarParseOutcome.conflict &&
                      _ll1TableReport != null)) ...[
                const SizedBox(height: 8),
                Text(
                  reportMessage != null
                      ? appLocalizationsOf(
                          context,
                        ).resolveStructuredMessage(reportMessage)
                      : bruteForceMessage == null
                      ? report.message!
                      : appLocalizationsOf(
                          context,
                        ).resolveStructuredMessage(bruteForceMessage),
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Theme.of(context).colorScheme.onSurface,
                  ),
                ),
              ],
            ],
            if (isAccepted &&
                report.trees.isNotEmpty &&
                report.bruteForceResult == null) ...[
              const SizedBox(height: 16),
              Material(
                type: MaterialType.transparency,
                child: ExpansionTile(
                  initiallyExpanded: false,
                  tilePadding: EdgeInsets.zero,
                  title: Text(
                    report.isAmbiguous
                        ? appLocalizationsOf(
                            context,
                          ).derivationTreesAmbiguous(report.trees.length)
                        : appLocalizationsOf(context).derivationTree,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
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
              ),
            ],
          ],
        ],
      ),
    );
  }

  Future<void> _parseString() async {
    final inputString = _inputController.text;
    final grammarState = ref.read(grammarProvider);
    final grammar = _buildCurrentGrammar();
    final requestSerial = ++_parseRequestSerial;

    setState(() {
      _stopPlayback();
      _isParsing = true;
      _parseReport = null;
      _cykStepsResult = null;
      _selectedStepIndex = 0;
      _clearLl1Workspace();
      _clearLr1Workspace();
      _clearBruteWorkspace();
    });

    try {
      final strategyHint = _selectedAlgorithm;

      if (strategyHint == ParsingStrategyHint.bruteForce) {
        final limits = _readBruteForceLimits();
        if (limits == null) {
          if (mounted &&
              _isCurrentRequest(requestSerial, grammarState, inputString)) {
            setState(() => _isParsing = false);
          }
          return;
        }
        final cancellationToken = BruteForceCancellationToken();
        _bruteCancellationToken = cancellationToken;
        final result = await BruteForceCFGParser.searchAsync(
          grammar,
          inputString,
          mode: _bruteMode,
          limits: limits,
          cancellationToken: cancellationToken,
          onProgress: (progress) {
            if (!mounted ||
                !_isCurrentRequest(requestSerial, grammarState, inputString)) {
              return;
            }
            setState(() => _bruteProgress = progress);
          },
        );
        if (!mounted ||
            !_isCurrentRequest(requestSerial, grammarState, inputString)) {
          return;
        }
        setState(() {
          _isParsing = false;
          _bruteCancellationToken = null;
          _bruteProgress = null;
          _parseReport = _reportFromBruteForceResult(result);
        });
        return;
      }

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
        if (!_isCurrentRequest(requestSerial, grammarState, inputString)) {
          return;
        }

        if (!cykOutcome.isSuccess) {
          setState(() {
            _isParsing = false;
            _parseReport = null;
            _cykStepsResult = null;
          });
          _showError(
            _failureText(
              cykOutcome,
              appLocalizationsOf(context).failedToParseString,
            ),
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
            message: cyk.message,
            structuredMessage: cyk.structuredMessage,
            trees: const [],
            isAmbiguous: false,
            executionTime: cyk.executionTime,
          );
          _cykStepsResult = (accepted: cyk.accepted, steps: cyk.steps);
          _selectedStepIndex = 0;
        });
        return;
      }

      if (strategyHint == ParsingStrategyHint.ll) {
        final workspace = await compute(_parseLl1WorkspaceInBackground, (
          grammar: grammar,
          inputString: inputString,
        ));
        if (!mounted ||
            !_isCurrentRequest(requestSerial, grammarState, inputString)) {
          return;
        }

        final parseOutcome = workspace.parse;
        if (!parseOutcome.isSuccess) {
          setState(() => _isParsing = false);
          _showError(
            _failureText(
              parseOutcome,
              appLocalizationsOf(context).failedToParseString,
            ),
          );
          return;
        }
        setState(() {
          _isParsing = false;
          _parseReport = parseOutcome.data!;
          _cykStepsResult = null;
          _ll1Grammar = workspace.grammar;
          _firstSetsReport = workspace.firstSets.data;
          _followSetsReport = workspace.followSets.data;
          _ll1TableReport = workspace.table.data;
          _selectedStepIndex = 0;
          _syncTableCellToSelectedStep();
        });
        return;
      }

      if (strategyHint == ParsingStrategyHint.lr) {
        final workspace = await compute(_parseLr1WorkspaceInBackground, (
          grammar: grammar,
          inputString: inputString,
        ));
        if (!mounted ||
            !_isCurrentRequest(requestSerial, grammarState, inputString)) {
          return;
        }
        if (workspace.report == null ||
            workspace.grammar == null ||
            workspace.construction == null ||
            workspace.parse == null) {
          setState(() => _isParsing = false);
          final message = workspace.structuredError == null
              ? workspace.error ??
                    appLocalizationsOf(context).failedToParseString
              : appLocalizationsOf(
                  context,
                ).resolveStructuredMessage(workspace.structuredError!);
          _showError(message);
          return;
        }
        setState(() {
          _isParsing = false;
          _parseReport = workspace.report;
          _cykStepsResult = null;
          _lr1Grammar = workspace.grammar;
          _lr1Construction = workspace.construction;
          _lr1Result = workspace.parse;
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
      if (!_isCurrentRequest(requestSerial, grammarState, inputString)) return;

      if (!parseOutcome.isSuccess) {
        setState(() {
          _isParsing = false;
          _parseReport = null;
          _cykStepsResult = null;
        });
        _showError(
          _failureText(
            parseOutcome,
            appLocalizationsOf(context).failedToParseString,
          ),
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
      if (!mounted ||
          !_isCurrentRequest(requestSerial, grammarState, inputString)) {
        return;
      }

      setState(() {
        _isParsing = false;
        _parseReport = null;
        _cykStepsResult = null;
      });

      _showError(appLocalizationsOf(context).failedToParseStringError('$e'));
    }
  }

  Grammar _buildCurrentGrammar() {
    return ref.read(grammarProvider.notifier).buildGrammar();
  }

  bool _isCurrentRequest(int serial, GrammarState state, String inputString) =>
      serial == _parseRequestSerial &&
      identical(ref.read(grammarProvider), state) &&
      _inputController.text == inputString;

  void _invalidateStaleResult({
    UserDerivationDiagnosticCode? manualInvalidation,
  }) {
    if (!_isParsing &&
        _parseReport == null &&
        _ll1Grammar == null &&
        _lr1Grammar == null &&
        (manualInvalidation == null || _manualGrammar == null)) {
      return;
    }
    _parseRequestSerial++;
    _bruteCancellationToken?.cancel();
    _stopPlayback();
    if (!mounted) return;
    setState(() {
      _isParsing = false;
      _parseReport = null;
      _cykStepsResult = null;
      _selectedStepIndex = 0;
      _clearLl1Workspace();
      _clearLr1Workspace();
      _clearBruteWorkspace();
      if (manualInvalidation != null && _manualGrammar != null) {
        _manualInvalidationCode = manualInvalidation;
      }
    });
  }

  void _startManualDerivation() {
    final grammar = _buildCurrentGrammar();
    final target = LegacyContextFreeGrammarAdapter.tokenizeTarget(
      grammar,
      _inputController.text,
    );
    if (target.isFailure) {
      _showError(
        _failureText(
          target,
          appLocalizationsOf(
            context,
          ).localizeWorkflowText('The target is invalid.'),
        ),
      );
      return;
    }
    try {
      final adapted = LegacyContextFreeGrammarAdapter.adapt(
        grammar,
        revision: LegacyContextFreeGrammarAdapter.sourceRevision(grammar),
      );
      setState(() {
        _manualGrammar = adapted;
        _manualTarget = target.data!;
        _manualInvalidationCode = null;
        _manualSessionSerial++;
      });
    } on FormatException catch (error) {
      _showError(error.message);
    }
  }

  void _clearLl1Workspace() {
    _ll1Grammar = null;
    _firstSetsReport = null;
    _followSetsReport = null;
    _ll1TableReport = null;
    _selectedTableCell = null;
  }

  void _clearLr1Workspace() {
    _lr1Grammar = null;
    _lr1Construction = null;
    _lr1Result = null;
  }

  void _clearBruteWorkspace() {
    _bruteCancellationToken?.cancel();
    _bruteCancellationToken = null;
    _bruteProgress = null;
  }

  void _cancelBruteSearch() {
    _bruteCancellationToken?.cancel();
  }

  BruteForceSearchLimits? _readBruteForceLimits() {
    final depth = int.tryParse(_bruteDepthController.text.trim());
    final frontier = int.tryParse(_bruteFrontierController.text.trim());
    final resultCap = int.tryParse(_bruteResultCapController.text.trim());
    final timeLimit = int.tryParse(_bruteTimeLimitController.text.trim());
    if (depth == null ||
        frontier == null ||
        resultCap == null ||
        timeLimit == null) {
      _showError(
        appLocalizationsOf(
          context,
        ).localizeWorkflowText('Search limits must be whole numbers.'),
      );
      return null;
    }
    final limits = BruteForceSearchLimits(
      maxDepth: depth,
      maxFrontierSize: frontier,
      resultCap: resultCap,
      timeLimit: Duration(milliseconds: timeLimit),
    );
    final error = limits.structuredValidationMessage;
    if (error != null) {
      _showError(appLocalizationsOf(context).resolveStructuredMessage(error));
      return null;
    }
    return limits;
  }

  GrammarParseReport _reportFromBruteForceResult(BruteForceParseResult result) {
    if (result.accepted) {
      return GrammarParseReport.accepted(
        inputString: result.inputString,
        executionTime: result.statistics.executionTime,
        trees: result.witnesses.map((witness) => witness.tree).toList(),
        isAmbiguous: result.witnessCount > 1,
        bruteForceResult: result,
      );
    }
    final outcome = switch (result.outcome) {
      BruteForceParseOutcome.accepted => GrammarParseOutcome.accepted,
      BruteForceParseOutcome.rejected => GrammarParseOutcome.rejected,
      BruteForceParseOutcome.boundedUnknown =>
        GrammarParseOutcome.boundedUnknown,
      BruteForceParseOutcome.cancelled => GrammarParseOutcome.cancelled,
      BruteForceParseOutcome.invalidGrammar ||
      BruteForceParseOutcome.invalidInput => GrammarParseOutcome.invalidInput,
    };
    return GrammarParseReport.rejected(
      inputString: result.inputString,
      farthestPosition: 0,
      executionTime: result.statistics.executionTime,
      message: result.message,
      outcome: outcome,
      bruteForceResult: result,
    );
  }

  String _formatExecutionTime(Duration duration) {
    final formatter = LocaleValueFormatter.of(context);
    if (duration.inMicroseconds < 1000) {
      return '${formatter.integer(duration.inMicroseconds)} μs';
    }
    if (duration.inMilliseconds < 1000) {
      return '${formatter.integer(duration.inMilliseconds)} ms';
    }
    return '${formatter.decimal(duration.inMilliseconds / 1000, decimalDigits: 3)} s';
  }

  Widget _buildCykStepsSection(BuildContext context, List<CYKStep> steps) {
    final l10n = appLocalizationsOf(context);
    final formatter = LocaleValueFormatter.of(context);
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
            Icon(
              Icons.format_list_numbered,
              size: 18,
              color: Theme.of(context).colorScheme.primary,
            ),
            const SizedBox(width: 8),
            Text(
              appLocalizationsOf(context).cykSteps,
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
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
                        label:
                            '${formatter.integer(_selectedStepIndex + 1)} / '
                            '${formatter.integer(steps.length)}',
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
          l10n.localizeWorkflowText(selectedStep.baseStep.title),
          style: Theme.of(
            context,
          ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600),
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

  Widget _buildLl1StepsSection(BuildContext context, List<LL1ParseStep> steps) {
    final l10n = appLocalizationsOf(context);
    final formatter = LocaleValueFormatter.of(context);
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
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
            ),
          ],
        ),
        const SizedBox(height: 10),
        Wrap(
          spacing: 4,
          runSpacing: 4,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            IconButton(
              tooltip: l10n.previousStepLower,
              onPressed: _selectedStepIndex > 0
                  ? () => _selectLl1Step(_selectedStepIndex - 1)
                  : null,
              icon: const Icon(Icons.chevron_left),
            ),
            IconButton(
              tooltip: l10n.localizeWorkflowText(_isPlaying ? 'Pause' : 'Play'),
              onPressed: steps.length > 1
                  ? () => _isPlaying
                        ? setState(_stopPlayback)
                        : _startPlayback(steps)
                  : null,
              icon: Icon(_isPlaying ? Icons.pause : Icons.play_arrow),
            ),
            IconButton(
              tooltip: l10n.localizeWorkflowText('Reset'),
              onPressed: _selectedStepIndex > 0 || _isPlaying
                  ? () => _selectLl1Step(0)
                  : null,
              icon: const Icon(Icons.replay),
            ),
            IconButton(
              tooltip: l10n.nextStepLower,
              onPressed: _selectedStepIndex < steps.length - 1
                  ? () => _selectLl1Step(_selectedStepIndex + 1)
                  : null,
              icon: const Icon(Icons.chevron_right),
            ),
            Text(
              '${formatter.integer(_selectedStepIndex + 1)} / '
              '${formatter.integer(steps.length)}',
            ),
          ],
        ),
        if (steps.length > 1)
          Semantics(
            label: l10n.localizeWorkflowText('LL(1) step timeline'),
            value:
                '${formatter.integer(_selectedStepIndex + 1)} / '
                '${formatter.integer(steps.length)}',
            child: Slider(
              value: _selectedStepIndex.toDouble(),
              min: 0,
              max: (steps.length - 1).toDouble(),
              divisions: steps.length - 1,
              label:
                  '${formatter.integer(_selectedStepIndex + 1)} / '
                  '${formatter.integer(steps.length)}',
              onChanged: (value) => _selectLl1Step(value.round()),
            ),
          ),
        const SizedBox(height: 8),
        Text(
          l10n.localizeWorkflowText(selectedStep.title),
          style: Theme.of(
            context,
          ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 8),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Theme.of(
              context,
            ).colorScheme.tertiaryContainer.withValues(alpha: 0.2),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: Theme.of(
                context,
              ).colorScheme.tertiary.withValues(alpha: 0.3),
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
              if (selectedStep.productionId != null)
                _buildLl1StepRow(
                  context,
                  label: l10n.localizeWorkflowText('Production ID'),
                  value: selectedStep.productionId!,
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

  Widget _buildLl1TeachingEnvironment(BuildContext context) {
    final grammar = _ll1Grammar!;
    final first = _firstSetsReport?.value ?? const <String, Set<String>>{};
    final follow = _followSetsReport?.value ?? const <String, Set<String>>{};
    final conflicts = _ll1TableReport!.value.typedConflicts;
    final l10n = appLocalizationsOf(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          l10n.localizeWorkflowText('LL(1) teaching workspace'),
          style: Theme.of(
            context,
          ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: 8),
        LayoutBuilder(
          builder: (context, constraints) {
            final grammarCard = _buildGrammarOverview(context, grammar);
            final setsCard = _buildFirstFollowOverview(context, first, follow);
            if (constraints.maxWidth >= 720) {
              return Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(child: grammarCard),
                  const SizedBox(width: 12),
                  Expanded(child: setsCard),
                ],
              );
            }
            return Column(
              children: [grammarCard, const SizedBox(height: 12), setsCard],
            );
          },
        ),
        const SizedBox(height: 12),
        _buildLl1Table(context),
        const SizedBox(height: 12),
        ParseTableTeachingWorkspace.ll1(
          grammar: grammar,
          table: _ll1TableReport!.value,
          store: _teachingSessionStore(),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            TextButton.icon(
              onPressed: () => _showTransformationPreview(
                title: l10n.localizeWorkflowText(
                  'Left-recursion removal preview',
                ),
                result: GrammarAnalyzer.removeLeftRecursion(grammar),
              ),
              icon: const Icon(Icons.call_split),
              label: Text(
                l10n.localizeWorkflowText('Preview left-recursion removal'),
              ),
            ),
            TextButton.icon(
              onPressed: () => _showTransformationPreview(
                title: l10n.localizeWorkflowText('Left-factoring preview'),
                result: GrammarAnalyzer.leftFactor(grammar),
              ),
              icon: const Icon(Icons.account_tree_outlined),
              label: Text(l10n.localizeWorkflowText('Preview left factoring')),
            ),
          ],
        ),
        if (conflicts.isNotEmpty) ...[
          const SizedBox(height: 12),
          _buildLl1Conflicts(context, conflicts),
        ],
      ],
    );
  }

  Widget _buildGrammarOverview(BuildContext context, Grammar grammar) {
    final productions = grammar.productions.toList()
      ..sort((left, right) {
        final byOrder = left.order.compareTo(right.order);
        return byOrder != 0 ? byOrder : left.id.compareTo(right.id);
      });
    final currentId = _parseReport?.ll1Steps.isEmpty ?? true
        ? null
        : _parseReport!.ll1Steps[_selectedStepIndex].productionId;
    return _ll1OverviewCard(
      context,
      title: appLocalizationsOf(context).localizeWorkflowText('Grammar'),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          for (final production in productions)
            Container(
              key: ValueKey('ll1-production-${production.id}'),
              margin: const EdgeInsets.only(bottom: 4),
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
              decoration: BoxDecoration(
                color: production.id == currentId
                    ? Theme.of(context).colorScheme.primaryContainer
                    : null,
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(
                '${production.id}: ${production.leftSide.join(' ')} → '
                '${production.isLambda || production.rightSide.isEmpty ? 'ε' : production.rightSide.join(' ')}',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  fontFamilyFallback: kMonospaceFontFamilyFallback,
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildFirstFollowOverview(
    BuildContext context,
    Map<String, Set<String>> first,
    Map<String, Set<String>> follow,
  ) {
    final symbols = {...first.keys, ...follow.keys}.toList()..sort();
    return _ll1OverviewCard(
      context,
      title: appLocalizationsOf(
        context,
      ).localizeWorkflowText('FIRST and FOLLOW'),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          for (final symbol in symbols) ...[
            _buildLl1StepRow(
              context,
              label: 'FIRST($symbol)',
              value: _formatSymbolSet(first[symbol]),
            ),
            _buildLl1StepRow(
              context,
              label: 'FOLLOW($symbol)',
              value: _formatSymbolSet(follow[symbol]),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildLl1Table(BuildContext context) {
    final table = _ll1TableReport!.value;
    final terminals = table.terminals.toList()..sort();
    final nonTerminals = table.nonTerminals.toList()..sort();
    final l10n = appLocalizationsOf(context);
    return _ll1OverviewCard(
      context,
      title: l10n.localizeWorkflowText('Predictive parse table'),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            l10n.localizeWorkflowText(
              'Select a cell to inspect its production and provenance.',
            ),
            style: Theme.of(context).textTheme.bodySmall,
          ),
          const SizedBox(height: 8),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: DataTable(
              columnSpacing: 16,
              horizontalMargin: 8,
              columns: [
                const DataColumn(label: Text('NT')),
                for (final terminal in terminals)
                  DataColumn(label: Text(terminal)),
              ],
              rows: [
                for (final nonTerminal in nonTerminals)
                  DataRow(
                    cells: [
                      DataCell(Text(nonTerminal)),
                      for (final terminal in terminals)
                        _buildLl1TableCell(
                          context,
                          nonTerminal,
                          terminal,
                          table.entriesAt(nonTerminal, terminal),
                        ),
                    ],
                  ),
              ],
            ),
          ),
          if (_selectedTableCell != null) ...[
            const SizedBox(height: 8),
            _buildSelectedCellDetails(context, table),
          ],
        ],
      ),
    );
  }

  DataCell _buildLl1TableCell(
    BuildContext context,
    String nonTerminal,
    String terminal,
    List<LL1ParseTableEntry> entries,
  ) {
    final selected =
        _selectedTableCell == (nonTerminal: nonTerminal, lookahead: terminal);
    final value = entries.isEmpty
        ? '—'
        : entries.map((entry) => entry.productionId).join(' / ');
    final l10n = appLocalizationsOf(context);
    final semantics = entries.isEmpty
        ? '${l10n.localizeWorkflowText('Empty table cell')} '
              '$nonTerminal, $terminal'
        : '${l10n.localizeWorkflowText('Table cell')} '
              '$nonTerminal, $terminal: $value';
    return DataCell(
      Semantics(
        button: true,
        selected: selected,
        label: semantics,
        child: InkWell(
          onTap: () => _selectTableCell(nonTerminal, terminal),
          borderRadius: BorderRadius.circular(6),
          child: Container(
            key: ValueKey('ll1-cell-$nonTerminal-$terminal'),
            constraints: const BoxConstraints(minWidth: 56, minHeight: 48),
            alignment: Alignment.center,
            padding: const EdgeInsets.symmetric(horizontal: 8),
            decoration: BoxDecoration(
              color: selected
                  ? Theme.of(context).colorScheme.primaryContainer
                  : null,
              borderRadius: BorderRadius.circular(6),
            ),
            child: Text(value),
          ),
        ),
      ),
    );
  }

  Widget _buildSelectedCellDetails(BuildContext context, LL1ParseTable table) {
    final cell = _selectedTableCell!;
    final entries = table.entriesAt(cell.nonTerminal, cell.lookahead);
    final title = '[${cell.nonTerminal}, ${cell.lookahead}]';
    final details = entries.isEmpty
        ? appLocalizationsOf(context).localizeWorkflowText('Empty cell')
        : entries
              .map((entry) {
                final sources = entry.placements
                    .map((placement) => placement.name.toUpperCase())
                    .join(' + ');
                return '${entry.productionId}: ${entry.display} — $sources';
              })
              .join('\n');
    return Semantics(liveRegion: true, child: Text('$title\n$details'));
  }

  Widget _buildLl1Conflicts(
    BuildContext context,
    List<LL1ParseTableConflict> conflicts,
  ) {
    return _ll1OverviewCard(
      context,
      title: appLocalizationsOf(context).localizeWorkflowText('Conflicts'),
      child: Wrap(
        spacing: 8,
        runSpacing: 8,
        children: [
          for (final conflict in conflicts)
            OutlinedButton.icon(
              onPressed: () =>
                  _selectTableCell(conflict.nonTerminal, conflict.lookahead),
              icon: const Icon(Icons.warning_amber),
              label: Text(
                appLocalizationsOf(
                  context,
                ).resolveStructuredMessage(conflict.descriptionMessage),
              ),
            ),
        ],
      ),
    );
  }

  Widget _ll1OverviewCard(
    BuildContext context, {
    required String title,
    required Widget child,
  }) {
    return Card.outlined(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              title,
              style: Theme.of(
                context,
              ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 8),
            child,
          ],
        ),
      ),
    );
  }

  String _formatSymbolSet(Set<String>? symbols) {
    final values = (symbols ?? const <String>{}).toList()..sort();
    return '{${values.join(', ')}}';
  }

  GrammarTeachingSessionStore? _teachingSessionStore() {
    try {
      return ref.read(grammarTeachingSessionStoreProvider);
    } on StateError {
      return null;
    }
  }

  void _showTransformationPreview({
    required String title,
    required Result<GrammarAnalysisReport<Grammar>> result,
  }) {
    final l10n = appLocalizationsOf(context);
    if (!result.isSuccess) {
      _showError(result.error ?? 'Unable to preview this transformation.');
      return;
    }
    final report = result.data!;
    final productions = report.value.productions.toList()
      ..sort((left, right) {
        final byOrder = left.order.compareTo(right.order);
        return byOrder != 0 ? byOrder : left.id.compareTo(right.id);
      });
    showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(title),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                l10n.localizeWorkflowText(
                  'Preview only. The source grammar will not change.',
                ),
              ),
              const SizedBox(height: 12),
              for (final production in productions)
                Padding(
                  padding: const EdgeInsets.only(bottom: 4),
                  child: Text(
                    '${production.leftSide.join(' ')} → '
                    '${production.isLambda || production.rightSide.isEmpty ? 'ε' : production.rightSide.join(' ')}',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      fontFamilyFallback: kMonospaceFontFamilyFallback,
                    ),
                  ),
                ),
              if (report.notes.isNotEmpty) ...[
                const SizedBox(height: 12),
                for (final note in report.notes)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 4),
                    child: Text(l10n.localizeWorkflowText(note)),
                  ),
              ],
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: Text(MaterialLocalizations.of(context).closeButtonLabel),
          ),
        ],
      ),
    );
  }

  Widget _buildLl1StepRow(
    BuildContext context, {
    required String label,
    required String value,
  }) {
    final labelWidget = Text(
      label,
      style: Theme.of(context).textTheme.bodySmall?.copyWith(
        fontWeight: FontWeight.w600,
        color: Theme.of(context).colorScheme.onSurfaceVariant,
      ),
    );
    final valueWidget = Text(
      value,
      style: Theme.of(context).textTheme.bodySmall?.copyWith(
        fontFamilyFallback: kMonospaceFontFamilyFallback,
      ),
    );
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: LayoutBuilder(
        builder: (context, constraints) {
          if (constraints.maxWidth < 360) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [labelWidget, const SizedBox(height: 2), valueWidget],
            );
          }
          return Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(width: 120, child: labelWidget),
              const SizedBox(width: 8),
              Expanded(child: valueWidget),
            ],
          );
        },
      ),
    );
  }

  void _selectLl1Step(int index) {
    _stopPlayback();
    setState(() {
      _selectedStepIndex = index;
      _syncTableCellToSelectedStep();
    });
  }

  void _startPlayback(List<LL1ParseStep> steps) {
    if (_selectedStepIndex >= steps.length - 1) {
      _selectedStepIndex = 0;
    }
    _playbackTimer?.cancel();
    setState(() {
      _isPlaying = true;
      _syncTableCellToSelectedStep();
    });
    _playbackTimer = Timer.periodic(const Duration(milliseconds: 700), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }
      if (_selectedStepIndex >= steps.length - 1) {
        setState(_stopPlayback);
        return;
      }
      setState(() {
        _selectedStepIndex++;
        _syncTableCellToSelectedStep();
      });
    });
  }

  void _stopPlayback() {
    _playbackTimer?.cancel();
    _playbackTimer = null;
    _isPlaying = false;
  }

  void _syncTableCellToSelectedStep() {
    final steps = _parseReport?.ll1Steps;
    if (steps == null || steps.isEmpty || _selectedStepIndex >= steps.length) {
      _selectedTableCell = null;
      return;
    }
    final step = steps[_selectedStepIndex];
    final nonTerminal = step.tableNonTerminal;
    final lookahead = step.tableLookahead;
    _selectedTableCell = nonTerminal == null || lookahead == null
        ? null
        : (nonTerminal: nonTerminal, lookahead: lookahead);
  }

  void _selectTableCell(String nonTerminal, String lookahead) {
    _stopPlayback();
    final steps = _parseReport?.ll1Steps ?? const <LL1ParseStep>[];
    final matchingStep = steps.indexWhere(
      (step) =>
          step.tableNonTerminal == nonTerminal &&
          step.tableLookahead == lookahead,
    );
    setState(() {
      _selectedTableCell = (nonTerminal: nonTerminal, lookahead: lookahead);
      if (matchingStep >= 0) _selectedStepIndex = matchingStep;
    });
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

  String _failureText<T>(Result<T> result, String fallback) {
    final message = result.structuredError;
    if (message != null) {
      return appLocalizationsOf(context).resolveStructuredMessage(message);
    }
    return result.error ?? fallback;
  }
}

String _localizedFarthestPositionLabel(
  AppLocalizations l10n,
  LocaleValueFormatter formatter,
  int position,
  int length,
) {
  final localizedPosition = formatter.inLocalizedTemplate(
    (value) => l10n.farthestPositionLabel(value, length),
    position,
  );
  return localizedPosition.replaceFirst(
    length.toString(),
    formatter.integer(length),
  );
}

class _LL1TeachingWorkspace {
  const _LL1TeachingWorkspace({
    required this.grammar,
    required this.firstSets,
    required this.followSets,
    required this.table,
    required this.parse,
  });

  final Grammar grammar;
  final Result<GrammarAnalysisReport<Map<String, Set<String>>>> firstSets;
  final Result<GrammarAnalysisReport<Map<String, Set<String>>>> followSets;
  final Result<GrammarAnalysisReport<LL1ParseTable>> table;
  final Result<GrammarParseReport> parse;
}

class _LR1TeachingWorkspace {
  const _LR1TeachingWorkspace({
    this.grammar,
    this.construction,
    this.parse,
    this.report,
    this.error,
    this.structuredError,
  });

  final Grammar? grammar;
  final LR1Construction? construction;
  final LR1ParseResult? parse;
  final GrammarParseReport? report;
  final String? error;
  final StructuredMessage? structuredError;
}
