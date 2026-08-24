//
//  algorithm_panel.dart
//  Turing Lab
//
//  Consolidates algorithm commands for finite automata, gathering
//  NFA→DFA conversion, minimization, complementation, language operations,
//  and regular-expression transforms in a single panel.
//  Controls progress, textual feedback, and loading of external automata
//  via FilePicker, running presentation-layer callbacks to orchestrate
//  specific algorithms.
//
//  Thales Matheus Mendonça Santos - October 2025
//
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/models/asset_example.dart';
import '../../core/models/fsa.dart';
import '../../core/repositories/examples_repository.dart';
import '../../core/result.dart';
import '../../core/services/file_operations_gateway.dart';
import '../../injection/data_providers.dart';
import '../../l10n/app_localizations_resolver.dart';
import '../../l10n/app_localizations_workflows.dart';
import '../providers/algorithm_step_provider.dart';
import '../providers/automaton_state_provider.dart';
import 'algorithm_panel_scaffold.dart';
import 'app_snackbar.dart';
import 'algorithm_step_navigator.dart';
import 'algorithm_step_renderer_registry.dart';
import 'algorithm_step_viewer.dart';
import 'common/algorithm_button.dart';
import 'utils/platform_file_loader.dart';
import '../../core/algorithms/language_comparator.dart';
import 'language_comparison_viewer.dart';

/// Panel for algorithm operations and controls
class AlgorithmPanel extends ConsumerStatefulWidget {
  final FSA? currentAutomaton;
  final VoidCallback? onNfaToDfa;
  final VoidCallback? onMinimizeDfa;
  final VoidCallback? onClear;
  final Function(String)? onRegexToNfa;
  final VoidCallback? onFaToRegex;
  final VoidCallback? onRemoveLambda;
  final VoidCallback? onCompleteDfa;
  final VoidCallback? onComplementDfa;
  final Future<void> Function(FSA other)? onUnionDfa;
  final Future<void> Function(FSA other)? onConcatenateFsa;
  final VoidCallback? onKleeneStarFsa;
  final VoidCallback? onReverseFsa;
  final Future<void> Function(FSA other)? onIntersectionDfa;
  final Future<void> Function(FSA other)? onDifferenceDfa;
  final VoidCallback? onPrefixClosure;
  final VoidCallback? onSuffixClosure;
  final VoidCallback? onFsaToGrammar;
  final VoidCallback? onAutoLayout;
  final Future<void> Function(FSA other)? onCompareEquivalence;
  final bool? equivalenceResult;
  final String? equivalenceDetails;
  final ValueChanged<bool>? onStepByStepModeChanged;
  final FileOperationsGateway? fileService;
  final AlgorithmStepRendererRegistry? rendererRegistry;
  final bool showExamples;
  final ExamplesRepository? examplesDataSource;

  const AlgorithmPanel({
    super.key,
    this.currentAutomaton,
    this.onNfaToDfa,
    this.onMinimizeDfa,
    this.onClear,
    this.onRegexToNfa,
    this.onFaToRegex,
    this.onRemoveLambda,
    this.onCompleteDfa,
    this.onComplementDfa,
    this.onUnionDfa,
    this.onConcatenateFsa,
    this.onKleeneStarFsa,
    this.onReverseFsa,
    this.onIntersectionDfa,
    this.onDifferenceDfa,
    this.onPrefixClosure,
    this.onSuffixClosure,
    this.onFsaToGrammar,
    this.onAutoLayout,
    this.onCompareEquivalence,
    this.equivalenceResult,
    this.equivalenceDetails,
    this.onStepByStepModeChanged,
    this.rendererRegistry,
    this.fileService,
    this.showExamples = false,
    this.examplesDataSource,
  });

  @override
  ConsumerState<AlgorithmPanel> createState() => _AlgorithmPanelState();
}

class _AlgorithmPanelState extends ConsumerState<AlgorithmPanel> {
  final TextEditingController _regexController = TextEditingController();
  late final FileOperationsGateway _fileService;
  bool _isExecuting = false;
  String? _currentAlgorithm;
  double _executionProgress = 0.0;
  String? _executionStatus;
  bool _stepByStepMode = false;
  String? _loadingExampleName;
  ExamplesRepository? _examplesDataSource;
  Future<ListResult<AssetExample<FSA>>>? _fsaExamplesFuture;

  void _showSnack(String message, {bool isError = false}) {
    showAppSnackBar(
      context,
      message: appLocalizationsOf(context).localizeWorkflowText(message),
      tone: isError ? AppSnackBarTone.error : AppSnackBarTone.success,
    );
  }

  @override
  void dispose() {
    _regexController.dispose();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    _fileService = widget.fileService ?? ref.read(fileOperationsProvider);
    if (widget.showExamples) {
      _examplesDataSource =
          widget.examplesDataSource ?? ref.read(examplesRepositoryProvider);
      _fsaExamplesFuture = _examplesDataSource!.loadAllTypedFsaExamples();
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlgorithmPanelScaffold(
      title: 'Algorithms',
      showHeaderIcon: false,
      paddingInsideScroll: false,
      spacing: 0,
      children: [
        if (_fsaExamplesFuture case final examplesFuture?) ...[
          AlgorithmExamplesSection<FSA>(
            examplesFuture: examplesFuture,
            loadingExampleName: _loadingExampleName,
            onExampleSelected: _loadSelectedExample,
            failureMessage: 'Failed to load FSA examples.',
            emptyMessage: 'No FSA examples available.',
          ),
          const SizedBox(height: 16),
          const Divider(),
        ],
        const SizedBox(height: 16),

        // Step-by-Step Mode toggle
        _buildStepByStepModeToggle(context),

        // Step viewer - show current step details when in step-by-step mode
        if (_stepByStepMode) _buildStepViewer(context),

        const SizedBox(height: 16),

        // Regex to NFA conversion
        _buildRegexInput(context),

        const SizedBox(height: 12),

        // NFA to DFA conversion
        AlgorithmButton(
          title: 'NFA to DFA',
          description: 'Convert non-deterministic to deterministic automaton',
          icon: Icons.transform,
          onPressed: widget.onNfaToDfa == null
              ? null
              : () => _executeAlgorithm('NFA to DFA', widget.onNfaToDfa),
          isExecuting: _isExecuting && _currentAlgorithm == 'NFA to DFA',
          isSelected: _currentAlgorithm == 'NFA to DFA',
          executionProgress:
              _currentAlgorithm == 'NFA to DFA' ? _executionProgress : null,
          executionStatus:
              _currentAlgorithm == 'NFA to DFA' ? _executionStatus : null,
        ),

        const SizedBox(height: 12),

        // Remove lambda transitions
        AlgorithmButton(
          title: 'Remove λ-transitions',
          description: 'Eliminate epsilon transitions from the automaton',
          icon: Icons.highlight_off,
          onPressed: widget.onRemoveLambda == null
              ? null
              : () => _executeAlgorithm(
                    'Remove λ-transitions',
                    widget.onRemoveLambda,
                  ),
          isExecuting:
              _isExecuting && _currentAlgorithm == 'Remove λ-transitions',
          isSelected: _currentAlgorithm == 'Remove λ-transitions',
          executionProgress: _currentAlgorithm == 'Remove λ-transitions'
              ? _executionProgress
              : null,
          executionStatus: _currentAlgorithm == 'Remove λ-transitions'
              ? _executionStatus
              : null,
        ),

        const SizedBox(height: 12),

        // DFA minimization
        AlgorithmButton(
          title: 'Minimize DFA',
          description: 'Minimize deterministic finite automaton',
          icon: Icons.compress,
          onPressed: widget.onMinimizeDfa == null
              ? null
              : () => _executeAlgorithm(
                    'Minimize DFA',
                    widget.onMinimizeDfa,
                  ),
          isExecuting: _isExecuting && _currentAlgorithm == 'Minimize DFA',
          isSelected: _currentAlgorithm == 'Minimize DFA',
          executionProgress:
              _currentAlgorithm == 'Minimize DFA' ? _executionProgress : null,
          executionStatus:
              _currentAlgorithm == 'Minimize DFA' ? _executionStatus : null,
        ),

        const SizedBox(height: 12),

        // Complete DFA
        AlgorithmButton(
          title: 'Complete DFA',
          description: 'Add trap state to make DFA complete',
          icon: Icons.add_circle_outline,
          onPressed: widget.onCompleteDfa == null
              ? null
              : () => _executeAlgorithm(
                    'Complete DFA',
                    widget.onCompleteDfa,
                  ),
          isExecuting: _isExecuting && _currentAlgorithm == 'Complete DFA',
          isSelected: _currentAlgorithm == 'Complete DFA',
          executionProgress:
              _currentAlgorithm == 'Complete DFA' ? _executionProgress : null,
          executionStatus:
              _currentAlgorithm == 'Complete DFA' ? _executionStatus : null,
        ),

        const SizedBox(height: 12),

        // Complement DFA
        AlgorithmButton(
          title: 'Complement DFA',
          description: 'Flip accepting states after completion',
          icon: Icons.flip,
          onPressed: widget.onComplementDfa == null
              ? null
              : () => _executeAlgorithm(
                    'Complement DFA',
                    widget.onComplementDfa,
                  ),
          isExecuting: _isExecuting && _currentAlgorithm == 'Complement DFA',
          isSelected: _currentAlgorithm == 'Complement DFA',
          executionProgress:
              _currentAlgorithm == 'Complement DFA' ? _executionProgress : null,
          executionStatus:
              _currentAlgorithm == 'Complement DFA' ? _executionStatus : null,
        ),

        const SizedBox(height: 12),

        // Union of DFAs
        AlgorithmButton(
          title: 'Union of DFAs',
          description: 'Combine this DFA with another automaton from file',
          icon: Icons.merge_type,
          onPressed: () => _runBinaryOperation(
            algorithmName: 'Union of DFAs',
            callback: widget.onUnionDfa,
            dialogTitle: 'Select DFA for union',
            executingStatus: 'Building union automaton...',
            successStatus: 'Union complete',
            missingCallbackMessage: 'Load a DFA before computing the union.',
          ),
          isExecuting: _isExecuting && _currentAlgorithm == 'Union of DFAs',
          isSelected: _currentAlgorithm == 'Union of DFAs',
          executionProgress:
              _currentAlgorithm == 'Union of DFAs' ? _executionProgress : null,
          executionStatus:
              _currentAlgorithm == 'Union of DFAs' ? _executionStatus : null,
        ),

        const SizedBox(height: 12),

        // Concatenation of FSAs
        AlgorithmButton(
          title: 'Concatenation of FSAs',
          description: 'Append another automaton language using ε-transitions',
          icon: Icons.link,
          onPressed: () => _runBinaryOperation(
            algorithmName: 'Concatenation of FSAs',
            callback: widget.onConcatenateFsa,
            dialogTitle: 'Select FSA for concatenation',
            executingStatus: 'Building concatenation NFA...',
            successStatus: 'Concatenation complete',
            missingCallbackMessage:
                'Load an FSA before computing the concatenation.',
          ),
          isExecuting:
              _isExecuting && _currentAlgorithm == 'Concatenation of FSAs',
          isSelected: _currentAlgorithm == 'Concatenation of FSAs',
          executionProgress: _currentAlgorithm == 'Concatenation of FSAs'
              ? _executionProgress
              : null,
          executionStatus: _currentAlgorithm == 'Concatenation of FSAs'
              ? _executionStatus
              : null,
        ),

        const SizedBox(height: 12),

        // Kleene star of an FSA
        AlgorithmButton(
          title: 'Kleene Star',
          description: 'Accept zero or more repetitions of this FSA language',
          icon: Icons.all_inclusive,
          onPressed: widget.onKleeneStarFsa == null
              ? null
              : () => _executeAlgorithm(
                    'Kleene Star',
                    widget.onKleeneStarFsa,
                  ),
          isExecuting: _isExecuting && _currentAlgorithm == 'Kleene Star',
          isSelected: _currentAlgorithm == 'Kleene Star',
          executionProgress:
              _currentAlgorithm == 'Kleene Star' ? _executionProgress : null,
          executionStatus:
              _currentAlgorithm == 'Kleene Star' ? _executionStatus : null,
        ),

        const SizedBox(height: 12),

        // Reverse an FSA language
        AlgorithmButton(
          title: 'Reverse FSA',
          description: 'Accept the reverse of every word in this FSA language',
          icon: Icons.swap_horiz,
          onPressed: widget.onReverseFsa == null
              ? null
              : () => _executeAlgorithm(
                    'Reverse FSA',
                    widget.onReverseFsa,
                  ),
          isExecuting: _isExecuting && _currentAlgorithm == 'Reverse FSA',
          isSelected: _currentAlgorithm == 'Reverse FSA',
          executionProgress:
              _currentAlgorithm == 'Reverse FSA' ? _executionProgress : null,
          executionStatus:
              _currentAlgorithm == 'Reverse FSA' ? _executionStatus : null,
        ),

        const SizedBox(height: 12),

        // Intersection of DFAs
        AlgorithmButton(
          title: 'Intersection of DFAs',
          description: 'Intersect this DFA with another automaton from file',
          icon: Icons.call_merge,
          onPressed: () => _runBinaryOperation(
            algorithmName: 'Intersection of DFAs',
            callback: widget.onIntersectionDfa,
            dialogTitle: 'Select DFA for intersection',
            executingStatus: 'Building intersection automaton...',
            successStatus: 'Intersection complete',
            missingCallbackMessage:
                'Load a DFA before computing the intersection.',
          ),
          isExecuting:
              _isExecuting && _currentAlgorithm == 'Intersection of DFAs',
          isSelected: _currentAlgorithm == 'Intersection of DFAs',
          executionProgress: _currentAlgorithm == 'Intersection of DFAs'
              ? _executionProgress
              : null,
          executionStatus: _currentAlgorithm == 'Intersection of DFAs'
              ? _executionStatus
              : null,
        ),

        const SizedBox(height: 12),

        // Difference of DFAs
        AlgorithmButton(
          title: 'Difference of DFAs',
          description:
              'Compute the language difference with another DFA from file',
          icon: Icons.call_split,
          onPressed: () => _runBinaryOperation(
            algorithmName: 'Difference of DFAs',
            callback: widget.onDifferenceDfa,
            dialogTitle: 'Select DFA for difference',
            executingStatus: 'Building difference automaton...',
            successStatus: 'Difference complete',
            missingCallbackMessage:
                'Load a DFA before computing the difference.',
          ),
          isExecuting:
              _isExecuting && _currentAlgorithm == 'Difference of DFAs',
          isSelected: _currentAlgorithm == 'Difference of DFAs',
          executionProgress: _currentAlgorithm == 'Difference of DFAs'
              ? _executionProgress
              : null,
          executionStatus: _currentAlgorithm == 'Difference of DFAs'
              ? _executionStatus
              : null,
        ),

        const SizedBox(height: 12),

        // Prefix closure
        AlgorithmButton(
          title: 'Prefix Closure',
          description: 'Accept all prefixes of the DFA language',
          icon: Icons.vertical_align_top,
          onPressed: widget.onPrefixClosure == null
              ? null
              : () => _executeAlgorithm(
                    'Prefix Closure',
                    widget.onPrefixClosure,
                  ),
          isExecuting: _isExecuting && _currentAlgorithm == 'Prefix Closure',
          isSelected: _currentAlgorithm == 'Prefix Closure',
          executionProgress:
              _currentAlgorithm == 'Prefix Closure' ? _executionProgress : null,
          executionStatus:
              _currentAlgorithm == 'Prefix Closure' ? _executionStatus : null,
        ),

        const SizedBox(height: 12),

        // Suffix closure
        AlgorithmButton(
          title: 'Suffix Closure',
          description: 'Accept all suffixes of the DFA language',
          icon: Icons.vertical_align_bottom,
          onPressed: widget.onSuffixClosure == null
              ? null
              : () => _executeAlgorithm(
                    'Suffix Closure',
                    widget.onSuffixClosure,
                  ),
          isExecuting: _isExecuting && _currentAlgorithm == 'Suffix Closure',
          isSelected: _currentAlgorithm == 'Suffix Closure',
          executionProgress:
              _currentAlgorithm == 'Suffix Closure' ? _executionProgress : null,
          executionStatus:
              _currentAlgorithm == 'Suffix Closure' ? _executionStatus : null,
        ),

        const SizedBox(height: 12),

        // FA to Regex conversion
        AlgorithmButton(
          title: 'FA to Regex',
          description: 'Convert finite automaton to regular expression',
          icon: Icons.text_fields,
          onPressed: widget.onFaToRegex == null
              ? null
              : () => _executeAlgorithm('FA to Regex', widget.onFaToRegex),
          isExecuting: _isExecuting && _currentAlgorithm == 'FA to Regex',
          isSelected: _currentAlgorithm == 'FA to Regex',
          executionProgress:
              _currentAlgorithm == 'FA to Regex' ? _executionProgress : null,
          executionStatus:
              _currentAlgorithm == 'FA to Regex' ? _executionStatus : null,
        ),

        const SizedBox(height: 12),

        // FSA to Grammar conversion
        AlgorithmButton(
          title: 'FSA to Grammar',
          description: 'Convert finite automaton to regular grammar',
          icon: Icons.transform,
          onPressed: widget.onFsaToGrammar == null
              ? null
              : () => _executeAlgorithm(
                    'FSA to Grammar',
                    widget.onFsaToGrammar,
                  ),
          isExecuting: _isExecuting && _currentAlgorithm == 'FSA to Grammar',
          isSelected: _currentAlgorithm == 'FSA to Grammar',
          executionProgress:
              _currentAlgorithm == 'FSA to Grammar' ? _executionProgress : null,
          executionStatus:
              _currentAlgorithm == 'FSA to Grammar' ? _executionStatus : null,
        ),

        const SizedBox(height: 12),

        // Auto Layout
        AlgorithmButton(
          title: 'Auto Layout',
          description: 'Arrange states in a circle',
          icon: Icons.auto_awesome_motion,
          onPressed: widget.onAutoLayout,
        ),

        const SizedBox(height: 12),

        // Compare Equivalence
        AlgorithmButton(
          title: 'Compare Equivalence',
          description: 'Compare two DFAs for equivalence',
          icon: Icons.compare_arrows,
          onPressed: _onCompareEquivalencePressed,
          isExecuting:
              _isExecuting && _currentAlgorithm == 'Compare Equivalence',
          isSelected: _currentAlgorithm == 'Compare Equivalence',
          executionProgress: _currentAlgorithm == 'Compare Equivalence'
              ? _executionProgress
              : null,
          executionStatus: _currentAlgorithm == 'Compare Equivalence'
              ? _executionStatus
              : null,
        ),

        const SizedBox(height: 12),

        // Clear automaton
        AlgorithmButton(
          title: 'Clear',
          description: 'Clear current automaton',
          icon: Icons.clear,
          onPressed: widget.onClear,
          isDestructive: true,
        ),

        // Progress indicator
        if (_isExecuting) ...[
          const SizedBox(height: 16),
          _buildProgressIndicator(context),
        ],

        if (widget.equivalenceResult != null ||
            (widget.equivalenceDetails?.isNotEmpty ?? false)) ...[
          const SizedBox(height: 16),
          _buildEquivalenceResult(context),
        ],

        // Step navigator - show controls when in step-by-step mode
        if (_stepByStepMode) _buildStepNavigator(context),
      ],
    );
  }

  Future<void> _loadSelectedExample(String exampleName) async {
    setState(() {
      _loadingExampleName = exampleName;
    });

    try {
      final result =
          await _examplesDataSource!.loadTypedFsaExample(exampleName);
      if (!mounted) return;

      if (result.isFailure) {
        _showSnack('Failed to load example: ${result.error}', isError: true);
        return;
      }

      final automaton = result.data!.payload;
      ref.read(automatonStateProvider.notifier).updateAutomaton(automaton);
      _showSnack('Example loaded: ${automaton.name}');
    } catch (error) {
      if (!mounted) return;
      _showSnack('Failed to load example: $error', isError: true);
    } finally {
      if (mounted) {
        setState(() {
          _loadingExampleName = null;
        });
      }
    }
  }

  Widget _buildRegexInput(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Regex to NFA',
          style: Theme.of(
            context,
          ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: TextField(
                controller: _regexController,
                decoration: const InputDecoration(
                  labelText: 'Regular Expression',
                  hintText: 'e.g., (a|b)*',
                  border: OutlineInputBorder(),
                ),
                onSubmitted: (value) {
                  if (value.isNotEmpty && widget.onRegexToNfa != null) {
                    widget.onRegexToNfa!(value);
                  }
                },
              ),
            ),
            const SizedBox(width: 8),
            ElevatedButton(
              onPressed: () {
                if (_regexController.text.isNotEmpty &&
                    widget.onRegexToNfa != null) {
                  widget.onRegexToNfa!(_regexController.text);
                }
              },
              child: const Icon(Icons.arrow_forward),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildStepByStepModeToggle(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: _stepByStepMode
            ? theme.colorScheme.primaryContainer.withValues(alpha: 0.3)
            : theme.colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: _stepByStepMode
              ? theme.colorScheme.primary.withValues(alpha: 0.5)
              : theme.colorScheme.outline.withValues(alpha: 0.2),
        ),
      ),
      child: Row(
        children: [
          Icon(
            Icons.linear_scale,
            size: 20,
            color: _stepByStepMode
                ? theme.colorScheme.primary
                : theme.colorScheme.onSurfaceVariant,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Step-by-Step Mode',
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: _stepByStepMode
                        ? theme.colorScheme.primary
                        : theme.colorScheme.onSurface,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'Show detailed algorithm execution steps with explanations',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
          Switch(
            value: _stepByStepMode,
            onChanged: (value) {
              setState(() {
                _stepByStepMode = value;
              });
              widget.onStepByStepModeChanged?.call(value);
            },
          ),
        ],
      ),
    );
  }

  Widget _buildProgressIndicator(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
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
                Icons.auto_awesome,
                color: Theme.of(context).colorScheme.primary,
                size: 20,
              ),
              const SizedBox(width: 8),
              Text(
                'Executing $_currentAlgorithm',
                style: Theme.of(
                  context,
                ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600),
              ),
            ],
          ),
          const SizedBox(height: 12),
          LinearProgressIndicator(
            value: _executionProgress,
            backgroundColor: Theme.of(
              context,
            ).colorScheme.outline.withValues(alpha: 0.2),
            valueColor: AlwaysStoppedAnimation<Color>(
              Theme.of(context).colorScheme.primary,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            _executionStatus ?? 'Processing...',
            style: Theme.of(context).textTheme.bodySmall,
          ),
        ],
      ),
    );
  }

  Future<void> _runBinaryOperation({
    required String algorithmName,
    required Future<void> Function(FSA other)? callback,
    required String dialogTitle,
    required String executingStatus,
    required String successStatus,
    String? missingCallbackMessage,
  }) async {
    if (callback == null) {
      _showSnack(
        missingCallbackMessage ?? 'Load a DFA before executing $algorithmName.',
        isError: true,
      );
      return;
    }

    final selection = await FilePicker.platform.pickFiles(
      dialogTitle: dialogTitle,
      type: FileType.custom,
      allowedExtensions: const ['jff'],
      withData: true,
    );

    if (selection == null || selection.files.isEmpty) {
      return;
    }

    final file = selection.files.single;
    setState(() {
      _isExecuting = true;
      _currentAlgorithm = algorithmName;
      _executionStatus = 'Loading automaton...';
      _executionProgress = 0.0;
    });

    final loadResult = await loadAutomatonFromPlatformFile(_fileService, file);

    if (!mounted) return;

    if (!loadResult.isSuccess) {
      setState(() {
        _isExecuting = false;
        _executionStatus = 'Failed to load automaton';
      });
      _showSnack(
        loadResult.error ?? 'Selected file did not contain readable data.',
        isError: true,
      );
      return;
    }

    setState(() {
      _executionProgress = 0.5;
      _executionStatus = executingStatus;
    });

    try {
      await callback(loadResult.data!);
      if (!mounted) return;
      setState(() {
        _isExecuting = false;
        _executionStatus = successStatus;
        _executionProgress = 1.0;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isExecuting = false;
        _executionStatus = '$algorithmName failed';
      });
      _showSnack('$algorithmName failed: $e', isError: true);
    }
  }

  Future<void> _onCompareEquivalencePressed() async {
    // Check if current automaton is available
    if (widget.currentAutomaton == null) {
      _showSnack('Load a DFA before comparing equivalence.', isError: true);
      return;
    }

    // Pick a file to load the second automaton
    final selection = await FilePicker.platform.pickFiles(
      dialogTitle: 'Select DFA to compare',
      type: FileType.custom,
      allowedExtensions: const ['jff'],
      withData: true,
    );

    if (selection == null || selection.files.isEmpty) {
      return;
    }

    final file = selection.files.single;
    setState(() {
      _isExecuting = true;
      _currentAlgorithm = 'Compare Equivalence';
      _executionStatus = 'Loading automaton...';
      _executionProgress = 0.0;
    });

    // Load the second automaton
    final loadResult = await loadAutomatonFromPlatformFile(_fileService, file);

    if (!mounted) return;

    if (!loadResult.isSuccess) {
      setState(() {
        _isExecuting = false;
        _executionStatus = 'Failed to load automaton';
      });
      _showSnack(
        loadResult.error ?? 'Selected file did not contain readable data.',
        isError: true,
      );
      return;
    }

    setState(() {
      _executionProgress = 0.5;
      _executionStatus = 'Comparing automata...';
    });

    // Compare the automata using LanguageComparator
    final comparisonResult = LanguageComparator.compareLanguages(
      widget.currentAutomaton!,
      loadResult.data!,
    );

    if (!mounted) return;

    setState(() {
      _isExecuting = false;
      _executionProgress = 1.0;
      _executionStatus = 'Comparison complete';
    });

    if (!comparisonResult.isSuccess) {
      _showSnack(comparisonResult.error ?? 'Comparison failed', isError: true);
      return;
    }

    // Show the comparison result in a dialog
    if (!mounted) return;
    await showDialog(
      context: context,
      builder: (context) => Dialog(
        child: SizedBox(
          width: MediaQuery.of(context).size.width * 0.9,
          height: MediaQuery.of(context).size.height * 0.9,
          child: Column(
            children: [
              // Dialog header
              Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    Icon(
                      Icons.compare_arrows,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                    const SizedBox(width: 12),
                    Text(
                      'Language Comparison',
                      style: Theme.of(context).textTheme.headlineSmall,
                    ),
                    const Spacer(),
                    IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: () => Navigator.of(context).pop(),
                    ),
                  ],
                ),
              ),
              const Divider(height: 1),
              // Comparison viewer
              Expanded(
                child: SingleChildScrollView(
                  child: LanguageComparisonViewer(
                    comparisonResult: comparisonResult.data!,
                    automatonATitle: 'Current Automaton',
                    automatonBTitle: 'Compared Automaton',
                    showProductAutomaton: true,
                    showSteps: _stepByStepMode,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEquivalenceResult(BuildContext context) {
    final result = widget.equivalenceResult;
    final message = widget.equivalenceDetails ?? '';
    final theme = Theme.of(context);
    final Color accent;
    IconData icon;

    if (result == null) {
      accent = theme.colorScheme.secondary;
      icon = Icons.info_outline;
    } else if (result) {
      accent = Colors.green;
      icon = Icons.check_circle;
    } else {
      accent = Colors.red;
      icon = Icons.cancel;
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: accent.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: accent.withValues(alpha: 0.4)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: accent),
              const SizedBox(width: 8),
              Text(
                result == null
                    ? 'Equivalence comparison'
                    : result
                        ? 'Automata are equivalent'
                        : 'Automata are not equivalent',
                style: theme.textTheme.titleMedium?.copyWith(
                  color: accent,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          if (message.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(message, style: theme.textTheme.bodyMedium),
          ],
        ],
      ),
    );
  }

  void _executeAlgorithm(String algorithmName, VoidCallback? callback) {
    if (callback == null) return;

    setState(() {
      _isExecuting = true;
      _currentAlgorithm = algorithmName;
      _executionProgress = 0.0;
      _executionStatus = 'Executing...';
    });

    // Execute the algorithm
    callback();

    // Reset state after execution
    setState(() {
      _isExecuting = false;
      _executionProgress = 1.0;
      _executionStatus = 'Completed successfully';
    });
  }

  /// Builds the step viewer for displaying current step details
  Widget _buildStepViewer(BuildContext context) {
    final stepState = ref.watch(algorithmStepProvider);

    // Only show if there are steps and a current step
    if (!stepState.hasSteps || stepState.currentStep == null) {
      return const SizedBox.shrink();
    }

    return Column(
      children: [
        const SizedBox(height: 16),
        AlgorithmStepViewer(
          step: stepState.currentStep!,
          showExpandedDetails: false,
          rendererRegistry: widget.rendererRegistry,
        ),
      ],
    );
  }

  /// Builds the step navigator for controlling step navigation
  Widget _buildStepNavigator(BuildContext context) {
    final stepState = ref.watch(algorithmStepProvider);

    // Only show if there are steps
    if (!stepState.hasSteps) {
      return const SizedBox.shrink();
    }

    return Column(
      children: [
        const SizedBox(height: 16),
        AlgorithmStepNavigator(
          showStepCounter: true,
          showSlider: true,
          onStepChanged: (stepIndex) {
            // Optional: Add any additional handling when step changes
          },
        ),
      ],
    );
  }
}
