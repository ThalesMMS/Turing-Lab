//
//  grammar_algorithm_panel.dart
//  Turing Lab
//
//  Panel that centralizes grammar algorithms, offering buttons for
//  conversions, left-recursion removal, factoring, FIRST and FOLLOW
//  computations, and parse-table construction. The widget wires multiple
//  providers to fire operations, manages loading states, and shows
//  textual results that guide the user's next action.
//
//  Thales Matheus Mendonça Santos - October 2025
//
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/algorithms/grammar_analyzer.dart';
import '../../core/algorithms/grammar_cnf_transformer.dart';
import '../../core/algorithms/grammar_gnf_transformer.dart';
import '../../core/models/grammar.dart';
import '../../core/models/asset_example.dart';
import '../../core/models/grammar_diagnostic_severity.dart';
import '../../core/models/grammar_transformation_step.dart';
import '../../core/models/pda.dart';
import '../../core/repositories/examples_repository.dart';
import '../../core/result.dart';
import '../../injection/data_providers.dart';
import '../../l10n/app_localizations_resolver.dart';
import '../../l10n/app_localizations_workflows.dart';
import 'algorithm_panel_scaffold.dart';
import 'base_simulation_panel.dart';
import 'common/algorithm_button.dart';
import 'common/algorithm_button_config.dart';
import 'grammar_transformation_history.dart';
import '../providers/automaton_state_provider.dart';
import '../providers/grammar_provider.dart';
import '../providers/home_navigation_provider.dart';
import '../providers/pda_editor_provider.dart';
import 'app_snackbar.dart';

/// Panel for grammar analysis algorithms
class GrammarAlgorithmPanel extends ConsumerStatefulWidget {
  const GrammarAlgorithmPanel({
    super.key,
    this.useExpanded = true,
    this.examplesDataSource,
  });

  final bool useExpanded;
  final ExamplesRepository? examplesDataSource;

  @override
  ConsumerState<GrammarAlgorithmPanel> createState() =>
      _GrammarAlgorithmPanelState();
}

class _GrammarAlgorithmPanelState extends ConsumerState<GrammarAlgorithmPanel> {
  bool _isAnalyzing = false;
  String? _loadingExampleName;
  String? _analysisResult;
  List<GrammarTransformationStep> _transformationSteps = const [];
  late final ExamplesRepository _examplesDataSource;
  late final Future<ListResult<AssetExample<Grammar>>> _grammarExamplesFuture;

  @override
  void initState() {
    super.initState();
    _examplesDataSource =
        widget.examplesDataSource ?? ref.read(examplesRepositoryProvider);
    _grammarExamplesFuture = _examplesDataSource.loadAllTypedCfgExamples();
  }

  @override
  Widget build(BuildContext context) {
    return AlgorithmPanelScaffold(
      title: 'Grammar Analysis',
      children: [
        _buildAlgorithmButtons(context),
        _buildResultsSection(context),
      ],
    );
  }

  Widget _buildAlgorithmButtons(BuildContext context) {
    final grammarState = ref.watch(grammarProvider);
    return Column(
      children: [
        AlgorithmExamplesSection<Grammar>(
          examplesFuture: _grammarExamplesFuture,
          loadingExampleName: _loadingExampleName,
          onExampleSelected: _loadSelectedExample,
          failureMessage: 'Failed to load grammar examples.',
          emptyMessage: 'No grammar examples available.',
        ),
        const SizedBox(height: 16),
        const Divider(),
        const SizedBox(height: 16),
        _buildConversionSection(context, grammarState),
        const SizedBox(height: 24),
        AlgorithmButton.fromConfig(
          AlgorithmButtonConfig(
            title: 'Convert to CNF',
            description: 'Convert grammar to Chomsky Normal Form',
            icon: Icons.filter_list,
            isEnabled: !_isAnalyzing,
            isExecuting: _isAnalyzing,
            onPressed: _convertToCnf,
          ),
        ),
        const SizedBox(height: 12),
        AlgorithmButton.fromConfig(
          AlgorithmButtonConfig(
            title: 'Convert to GNF',
            description: 'Convert grammar to Greibach Normal Form',
            icon: Icons.format_list_numbered,
            isEnabled: !_isAnalyzing,
            isExecuting: _isAnalyzing,
            onPressed: _convertToGnf,
          ),
        ),
        const SizedBox(height: 12),
        AlgorithmButton.fromConfig(
          AlgorithmButtonConfig(
            title: 'Remove Left Recursion',
            description: 'Eliminate direct and indirect left recursion',
            icon: Icons.transform,
            isEnabled: !_isAnalyzing,
            isExecuting: _isAnalyzing,
            onPressed: _removeLeftRecursion,
          ),
        ),
        const SizedBox(height: 12),
        AlgorithmButton.fromConfig(
          AlgorithmButtonConfig(
            title: 'Left Factor',
            description: 'Apply left factoring to grammar',
            icon: Icons.account_tree,
            isEnabled: !_isAnalyzing,
            isExecuting: _isAnalyzing,
            onPressed: _leftFactor,
          ),
        ),
        const SizedBox(height: 12),
        AlgorithmButton.fromConfig(
          AlgorithmButtonConfig(
            title: 'Find First Sets',
            description: 'Calculate FIRST sets for all variables',
            icon: Icons.first_page,
            isEnabled: !_isAnalyzing,
            isExecuting: _isAnalyzing,
            onPressed: _findFirstSets,
          ),
        ),
        const SizedBox(height: 12),
        AlgorithmButton.fromConfig(
          AlgorithmButtonConfig(
            title: 'Find Follow Sets',
            description: 'Calculate FOLLOW sets for all variables',
            icon: Icons.last_page,
            isEnabled: !_isAnalyzing,
            isExecuting: _isAnalyzing,
            onPressed: _findFollowSets,
          ),
        ),
        const SizedBox(height: 12),
        AlgorithmButton.fromConfig(
          AlgorithmButtonConfig(
            title: 'Build Parse Table',
            description: 'Generate LL(1) or LR(1) parse table',
            icon: Icons.table_chart,
            isEnabled: !_isAnalyzing,
            isExecuting: _isAnalyzing,
            onPressed: _buildParseTable,
          ),
        ),
        const SizedBox(height: 12),
        AlgorithmButton.fromConfig(
          AlgorithmButtonConfig(
            title: 'Check Ambiguity',
            description: 'Detect if grammar is ambiguous',
            icon: Icons.rule,
            isEnabled: !_isAnalyzing,
            isExecuting: _isAnalyzing,
            onPressed: _checkAmbiguity,
          ),
        ),
      ],
    );
  }

  Future<void> _loadSelectedExample(String exampleName) async {
    setState(() {
      _loadingExampleName = exampleName;
    });

    try {
      final result = await _examplesDataSource.loadTypedCfgExample(exampleName);
      if (!mounted) return;

      if (result.isFailure) {
        _showExampleFeedback(
          'Failed to load example: ${result.error}',
          tone: AppSnackBarTone.error,
        );
        return;
      }

      final grammar = result.data!.payload;
      ref.read(grammarProvider.notifier).applyGrammar(grammar);
      _showExampleFeedback('Example loaded: ${grammar.name}');
    } catch (error) {
      if (!mounted) return;
      _showExampleFeedback(
        'Failed to load example: $error',
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

  void _showExampleFeedback(
    String message, {
    AppSnackBarTone tone = AppSnackBarTone.success,
  }) {
    showAppSnackBar(
      context,
      message: appLocalizationsOf(context).localizeWorkflowText(message),
      tone: tone,
    );
  }

  Widget _buildConversionSection(
    BuildContext context,
    GrammarState grammarState,
  ) {
    final hasProductions = grammarState.productions.isNotEmpty;
    final isBusy = grammarState.isConverting;
    final isDisabled = isBusy || !hasProductions;
    final activeConversion = grammarState.activeConversion;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          appLocalizationsOf(context).localizeWorkflowText('Conversions'),
          style: Theme.of(
            context,
          ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 8),
        AlgorithmButton.fromConfig(
          AlgorithmButtonConfig(
            title: 'Convert Right-Linear Grammar to FSA',
            description: 'Build an FSA from a right-linear grammar',
            icon: Icons.sync_alt,
            isExecuting: isBusy &&
                activeConversion == GrammarConversionKind.grammarToFsa,
            isEnabled: !isDisabled,
            executionStatus: 'Converting to FSA...',
            onPressed: _convertToAutomaton,
          ),
        ),
        const SizedBox(height: 12),
        AlgorithmButton.fromConfig(
          AlgorithmButtonConfig(
            title: 'Convert Grammar to PDA (General)',
            description: 'Build an equivalent PDA from the grammar',
            icon: Icons.auto_fix_high,
            isExecuting: isBusy &&
                activeConversion == GrammarConversionKind.grammarToPda,
            isEnabled: !isDisabled,
            executionStatus: 'Converting to PDA...',
            onPressed: _convertToPdaGeneral,
          ),
        ),
        const SizedBox(height: 12),
        AlgorithmButton.fromConfig(
          AlgorithmButtonConfig(
            title: 'Convert Grammar to PDA (Standard)',
            description: 'Build a standard-form PDA from the grammar',
            icon: Icons.layers,
            isExecuting: isBusy &&
                activeConversion == GrammarConversionKind.grammarToPdaStandard,
            isEnabled: !isDisabled,
            executionStatus: 'Converting (Standard)...',
            onPressed: _convertToPdaStandard,
          ),
        ),
        const SizedBox(height: 12),
        AlgorithmButton.fromConfig(
          AlgorithmButtonConfig(
            title: 'Convert Grammar to PDA (Greibach)',
            description: 'Build a Greibach-form PDA from the grammar',
            icon: Icons.stacked_bar_chart,
            isExecuting: isBusy &&
                activeConversion == GrammarConversionKind.grammarToPdaGreibach,
            isEnabled: !isDisabled,
            executionStatus: 'Converting (Greibach)...',
            onPressed: _convertToPdaGreibach,
          ),
        ),
        if (!hasProductions)
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Text(
              'Add at least one production rule to enable conversions.',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(
                      context,
                    ).colorScheme.onSurface.withValues(alpha: 0.7),
                  ),
            ),
          ),
        if (grammarState.error != null)
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Text(
              grammarState.error!,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(context).colorScheme.error,
                  ),
            ),
          ),
      ],
    );
  }

  Future<void> _convertToAutomaton() async {
    final result =
        await ref.read(grammarProvider.notifier).convertToAutomaton();

    if (!mounted) return;

    if (result.isSuccess) {
      final automaton = result.data!;
      ref.read(automatonStateProvider.notifier).updateAutomaton(automaton);

      if (!mounted) return;

      ref.read(homeNavigationProvider.notifier).goToFsa();

      showAppSnackBar(
        context,
        message: appLocalizationsOf(context).localizeWorkflowText(
          'Grammar converted to automaton. Switched to FSA workspace.',
        ),
        tone: AppSnackBarTone.success,
      );
    } else {
      final message = result.error ?? 'Failed to convert grammar to automaton.';
      showAppSnackBar(
        context,
        message: appLocalizationsOf(context).localizeWorkflowText(message),
        tone: AppSnackBarTone.error,
      );
    }
  }

  Future<void> _convertToPdaGeneral() {
    return _handlePdaConversion(
      convert: () => ref.read(grammarProvider.notifier).convertToPda(),
      successMessage:
          'Grammar converted to PDA (general). Switched to PDA workspace.',
    );
  }

  Future<void> _convertToPdaStandard() {
    return _handlePdaConversion(
      convert: () => ref.read(grammarProvider.notifier).convertToPdaStandard(),
      successMessage:
          'Grammar converted to PDA (standard). Switched to PDA workspace.',
    );
  }

  Future<void> _convertToPdaGreibach() {
    return _handlePdaConversion(
      convert: () => ref.read(grammarProvider.notifier).convertToPdaGreibach(),
      successMessage:
          'Grammar converted to PDA (Greibach). Switched to PDA workspace.',
    );
  }

  Future<void> _handlePdaConversion({
    required Future<Result<PDA>> Function() convert,
    required String successMessage,
  }) async {
    final result = await convert();

    if (!mounted) return;

    if (result.isSuccess) {
      final pda = result.data!;
      ref.read(pdaEditorProvider.notifier).setPda(pda);
      ref.read(homeNavigationProvider.notifier).goToPda();

      showAppSnackBar(
        context,
        message:
            appLocalizationsOf(context).localizeWorkflowText(successMessage),
        tone: AppSnackBarTone.success,
      );
    } else {
      final message = result.error ?? 'Failed to convert grammar to PDA.';
      showAppSnackBar(
        context,
        message: appLocalizationsOf(context).localizeWorkflowText(message),
        tone: AppSnackBarTone.error,
      );
    }
  }

  Widget _buildResultsSection(BuildContext context) {
    return AlgorithmResultsSection(
      hasResults: _transformationSteps.isNotEmpty || _analysisResult != null,
      emptyBuilder: _buildEmptyResults,
      resultsBuilder: (context) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (_transformationSteps.isNotEmpty) ...[
            GrammarTransformationHistory(
              steps: _transformationSteps,
              onApplyGrammar: (grammar) {
                ref.read(grammarProvider.notifier).applyGrammar(grammar);
                showAppSnackBar(
                  context,
                  message: appLocalizationsOf(context)
                      .localizeWorkflowText('Grammar applied to editor.'),
                  tone: AppSnackBarTone.success,
                );
              },
            ),
            const SizedBox(height: 12),
          ],
          if (_analysisResult == null)
            _buildEmptyResults(context)
          else
            _buildResults(context),
        ],
      ),
    );
  }

  Widget _buildEmptyResults(BuildContext context) {
    return const SimulationEmptyResults(
      icon: Icons.analytics_outlined,
      title: 'No analysis results yet',
      message: 'Select an algorithm above to analyze your grammar',
    );
  }

  Widget _buildResults(BuildContext context) {
    return AlgorithmResultsCard(
      child: SingleChildScrollView(
        child: Text(
          appLocalizationsOf(context).localizeWorkflowText(_analysisResult!),
          style: Theme.of(
            context,
          ).textTheme.bodyMedium?.copyWith(fontFamily: 'monospace'),
        ),
      ),
    );
  }

  void _removeLeftRecursion() {
    _performAnalysis<Grammar>(
      'Remove Left Recursion',
      (grammar) async => GrammarAnalyzer.removeLeftRecursion(grammar),
      (original, report) {
        _transformationSteps = report.steps;
        return _formatTransformationResult(
          title: 'Direct and Indirect Left Recursion Removal',
          original: original,
          transformed: report.value,
          notes: report.notes,
          derivations: report.derivations,
        );
      },
    );
  }

  void _leftFactor() {
    _performAnalysis<Grammar>(
      'Left Factoring',
      (grammar) async => GrammarAnalyzer.leftFactor(grammar),
      (original, report) => _formatTransformationResult(
        title: 'Left Factoring Analysis',
        original: original,
        transformed: report.value,
        notes: report.notes,
        derivations: report.derivations,
      ),
    );
  }

  void _findFirstSets() {
    _performAnalysis<Map<String, Set<String>>>(
      'FIRST Sets',
      (grammar) async => GrammarAnalyzer.computeFirstSets(grammar),
      (original, report) => _formatSetResult(
        title: 'FIRST Sets Analysis',
        sets: report.value,
        notes: report.notes,
        derivations: report.derivations,
      ),
    );
  }

  void _findFollowSets() {
    _performAnalysis<Map<String, Set<String>>>(
      'FOLLOW Sets',
      (grammar) async => GrammarAnalyzer.computeFollowSets(grammar),
      (original, report) => _formatSetResult(
        title: 'FOLLOW Sets Analysis',
        sets: report.value,
        notes: report.notes,
        derivations: report.derivations,
      ),
    );
  }

  void _buildParseTable() {
    _performAnalysis<LL1ParseTable>(
      'LL(1) Parse Table',
      (grammar) async => GrammarAnalyzer.buildLL1ParseTable(grammar),
      (original, report) => _formatParseTableResult(report),
    );
  }

  void _checkAmbiguity() {
    _performAnalysis<bool>(
      'Ambiguity Check',
      (grammar) async => GrammarAnalyzer.detectAmbiguity(grammar),
      (original, report) => _formatAmbiguityResult(report),
    );
  }

  void _convertToCnf() {
    _performAnalysis<GrammarCnfTransformationReport>(
      'Convert to CNF',
      (grammar) async {
        final result = GrammarCnfTransformer.toCnf(grammar);
        if (result.isSuccess && result.data != null) {
          final errors = result.data!.diagnostics
              .where((d) => d.severity == GrammarDiagnosticSeverity.error)
              .map((d) => d.message)
              .toList();
          if (errors.isNotEmpty) {
            return ResultFactory.failure(errors.join('\n'));
          }

          return ResultFactory.success(
            GrammarAnalysisReport<GrammarCnfTransformationReport>(
              value: result.data!,
              notes: const [
                'Converted grammar to Chomsky Normal Form (CNF) using a step pipeline.',
                'CNF rules: A→BC (two nonterminals) or A→a (single terminal).',
              ],
            ),
          );
        }

        return ResultFactory.failure(
          result.error ?? 'CNF conversion failed.',
        );
      },
      (original, report) {
        setState(() {
          _transformationSteps = report.value.steps;
        });

        final diagnosticsText = report.value.diagnostics.isEmpty
            ? ''
            : '\nDiagnostics:\n${report.value.diagnostics.map((d) => '- [${d.severity.name}] ${d.message}').join('\n')}';

        return _formatTransformationResult(
          title: 'Chomsky Normal Form (CNF) Conversion',
          original: original,
          transformed: report.value.grammar,
          notes: [...report.notes, diagnosticsText]
              .where((s) => s.trim().isNotEmpty)
              .toList(),
          derivations: report.derivations,
        );
      },
    );
  }

  void _convertToGnf() {
    _performAnalysis<GrammarGnfTransformationReport>(
      'Convert to GNF',
      (grammar) async {
        final report = GrammarGnfTransformer.toGnf(grammar);
        final hasError = report.diagnostics.any(
          (d) => d.severity == GrammarDiagnosticSeverity.error,
        );

        if (hasError) {
          return ResultFactory.failure(
            report.diagnostics
                .where((d) => d.severity == GrammarDiagnosticSeverity.error)
                .map((d) => d.message)
                .join('\n'),
          );
        }

        return ResultFactory.success(
          GrammarAnalysisReport<GrammarGnfTransformationReport>(
            value: report,
            notes: const [
              'Converted grammar to Greibach Normal Form (GNF).',
              'GNF rules: A→aα (terminal followed by nonterminals).',
            ],
          ),
        );
      },
      (original, report) {
        setState(() {
          _transformationSteps = report.value.steps;
        });

        final diagnosticsText = report.value.diagnostics.isEmpty
            ? ''
            : '\nDiagnostics:\n${report.value.diagnostics.map((d) => '- [${d.severity.name}] ${d.message}').join('\n')}';

        return _formatTransformationResult(
          title: 'Greibach Normal Form (GNF) Conversion',
          original: original,
          transformed: report.value.grammar,
          notes: [...report.notes, diagnosticsText]
              .where((s) => s.trim().isNotEmpty)
              .toList(),
          derivations: report.derivations,
        );
      },
    );
  }

  Future<void> _performAnalysis<T>(
    String algorithmName,
    Future<Result<GrammarAnalysisReport<T>>> Function(Grammar grammar)
        runAnalysis,
    String Function(Grammar original, GrammarAnalysisReport<T> report)
        formatter,
  ) async {
    setState(() {
      _isAnalyzing = true;
      _analysisResult = null;
      _transformationSteps = const [];
    });

    final grammar = ref.read(grammarProvider.notifier).buildGrammar();
    final validationErrors = grammar.validate();

    if (validationErrors.isNotEmpty) {
      if (!mounted) return;
      setState(() {
        _isAnalyzing = false;
        _analysisResult = _formatError(
          'Cannot run $algorithmName due to grammar validation errors',
          validationErrors,
        );
      });
      return;
    }

    try {
      final result = await runAnalysis(grammar);
      if (!mounted) {
        return;
      }

      setState(() {
        _isAnalyzing = false;
        _analysisResult = result.isSuccess
            ? formatter(grammar, result.data!)
            : '$algorithmName failed: ${result.error}';
      });
    } catch (error) {
      if (!mounted) {
        return;
      }

      setState(() {
        _isAnalyzing = false;
        _analysisResult = '$algorithmName failed: $error';
      });
    }
  }

  String _formatTransformationResult({
    required String title,
    required Grammar original,
    required Grammar transformed,
    required List<String> notes,
    required List<String> derivations,
  }) {
    final buffer = StringBuffer()
      ..writeln(title)
      ..writeln('')
      ..writeln('Original Grammar:')
      ..writeln(_formatGrammar(original))
      ..writeln('')
      ..writeln('Transformed Grammar:')
      ..writeln(_formatGrammar(transformed));

    _appendSection(buffer, 'Notes', notes);
    _appendSection(buffer, 'Derivations', derivations);

    return buffer.toString();
  }

  String _formatSetResult({
    required String title,
    required Map<String, Set<String>> sets,
    required List<String> notes,
    required List<String> derivations,
  }) {
    final entries = sets.entries.toList()
      ..sort((a, b) => a.key.compareTo(b.key));
    final buffer = StringBuffer()
      ..writeln(title)
      ..writeln('');

    for (final entry in entries) {
      final values = entry.value.toList()..sort(_symbolComparator);
      final label = title.contains('FOLLOW') ? 'FOLLOW' : 'FIRST';
      buffer.writeln('$label(${entry.key}) = {${values.join(', ')}}');
    }

    _appendSection(buffer, 'Notes', notes);
    _appendSection(buffer, 'Derivations', derivations);

    return buffer.toString();
  }

  String _formatParseTableResult(GrammarAnalysisReport<LL1ParseTable> report) {
    final table = report.value;
    final terminals = table.terminals.toList()..sort(_symbolComparator);
    final nonTerminals = table.nonTerminals.toList()..sort(_symbolComparator);
    final buffer = StringBuffer()
      ..writeln('LL(1) Parse Table Analysis')
      ..writeln('');

    buffer.writeln(['NT', ...terminals].join('\t'));
    for (final nt in nonTerminals) {
      final row = <String>[nt];
      for (final terminal in terminals) {
        final entries = table.table[nt]?[terminal] ?? const <List<String>>[];
        if (entries.isEmpty) {
          row.add('-');
        } else {
          row.add(
            entries
                .map((symbols) => symbols.isEmpty ? 'ε' : symbols.join(' '))
                .join(' | '),
          );
        }
      }
      buffer.writeln(row.join('\t'));
    }

    _appendSection(buffer, 'Notes', report.notes);
    _appendSection(buffer, 'Conflicts', report.conflicts);
    _appendSection(buffer, 'Derivations', report.derivations);

    return buffer.toString();
  }

  String _formatAmbiguityResult(GrammarAnalysisReport<bool> report) {
    final status =
        report.value ? 'LL(1) (no conflicts)' : 'Not LL(1) (conflicts)';
    final buffer = StringBuffer()
      ..writeln('LL(1) Classification')
      ..writeln('')
      ..writeln('Classification: $status');

    _appendSection(buffer, 'Notes', report.notes);
    _appendSection(buffer, 'Conflicts', report.conflicts);
    _appendSection(buffer, 'Derivations', report.derivations);

    return buffer.toString();
  }

  String _formatGrammar(Grammar grammar) {
    final productions = grammar.productions.toList()
      ..sort((a, b) => a.order.compareTo(b.order));
    final grouped = <String, List<String>>{};

    for (final production in productions) {
      if (production.leftSide.isEmpty) {
        continue;
      }
      final left = production.leftSide.first;
      final right = production.isLambda || production.rightSide.isEmpty
          ? 'ε'
          : production.rightSide.join(' ');
      grouped.putIfAbsent(left, () => <String>[]).add(right);
    }

    final nonTerminals = grouped.keys.toList()..sort(_symbolComparator);
    return nonTerminals
        .map((nt) => '$nt → ${grouped[nt]!.join(' | ')}')
        .join('\n');
  }

  void _appendSection(StringBuffer buffer, String title, List<String> entries) {
    if (entries.isEmpty) {
      return;
    }

    buffer
      ..writeln('')
      ..writeln('$title:');
    for (final entry in entries) {
      buffer.writeln('- $entry');
    }
  }

  String _formatError(String heading, List<String> messages) {
    final buffer = StringBuffer()
      ..writeln(heading)
      ..writeln('');

    for (final message in messages) {
      buffer.writeln('- $message');
    }

    return buffer.toString();
  }

  int _symbolComparator(String a, String b) {
    if (a == b) {
      return 0;
    }
    return a.compareTo(b);
  }
}
