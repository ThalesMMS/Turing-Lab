//
//  language_comparison_viewer.dart
//  Turing Lab
//
//  Widget para visualização de resultados de comparação de equivalência de
//  linguagens entre dois autômatos finitos. Exibe o resultado da comparação,
//  string distinguidora (contraexemplo), autômatos lado a lado, autômato produto
//  (opcional) e passos do algoritmo, permitindo análise educacional completa da
//  comparação de linguagens via construção do autômato produto e BFS.
//
//  Thales Matheus Mendonça Santos - January 2026
//
import 'package:flutter/material.dart';
import '../../core/models/equivalence_comparison_result.dart';
import '../../core/models/fsa.dart';
import '../../l10n/app_localizations_resolver.dart';
import '../../l10n/app_localizations_workflows.dart';
import '../../features/canvas/graphview/turing_lab_adaptive_edge_renderer.dart';
import 'read_only_fsa_graphview_canvas.dart';

/// Widget for visualizing language equivalence comparison results
///
/// Displays comparison outcome, distinguishing string (if not equivalent),
/// side-by-side automata comparison, optional product automaton visualization,
/// and algorithm steps for educational analysis of language comparison.
class LanguageComparisonViewer extends StatefulWidget {
  /// The comparison result to display
  final EquivalenceComparisonResult comparisonResult;

  /// Optional title for the first automaton (defaults to "Automaton A")
  final String? automatonATitle;

  /// Optional title for the second automaton (defaults to "Automaton B")
  final String? automatonBTitle;

  /// Whether to show the product automaton visualization
  final bool showProductAutomaton;

  /// Whether to show algorithm steps
  final bool showSteps;

  const LanguageComparisonViewer({
    super.key,
    required this.comparisonResult,
    this.automatonATitle,
    this.automatonBTitle,
    this.showProductAutomaton = false,
    this.showSteps = false,
  });

  @override
  State<LanguageComparisonViewer> createState() =>
      _LanguageComparisonViewerState();
}

class _LanguageComparisonViewerState extends State<LanguageComparisonViewer> {
  final GlobalKey _automatonACanvasKey = GlobalKey();
  final GlobalKey _automatonBCanvasKey = GlobalKey();
  final GlobalKey _productCanvasKey = GlobalKey();
  bool _showProductAutomatonSection = false;
  bool _showStepsSection = false;

  @override
  void initState() {
    super.initState();
    _showProductAutomatonSection = widget.showProductAutomaton;
    _showStepsSection = widget.showSteps;
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Card(
      elevation: 2,
      margin: const EdgeInsets.all(12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Header with equivalence result badge
            _buildHeader(colorScheme, textTheme),
            const SizedBox(height: 16),

            // Counterexample section (if not equivalent)
            if (!widget.comparisonResult.isEquivalent) ...[
              _buildCounterexampleSection(colorScheme, textTheme),
              const SizedBox(height: 16),
            ],

            // Statistics comparison
            _buildStatistics(colorScheme, textTheme),
            const SizedBox(height: 16),

            // Side-by-side automaton comparison
            Expanded(
              child: Column(
                children: [
                  // Main comparison section
                  Expanded(
                    child: Row(
                      children: [
                        // Automaton A
                        Expanded(
                          child: _buildAutomatonSection(
                            context: context,
                            automaton:
                                widget.comparisonResult.originalAutomaton,
                            title: widget.automatonATitle ?? 'Automaton A',
                            canvasKey: _automatonACanvasKey,
                            colorScheme: colorScheme,
                            textTheme: textTheme,
                          ),
                        ),
                        const SizedBox(width: 16),

                        // Automaton B
                        Expanded(
                          child: _buildAutomatonSection(
                            context: context,
                            automaton:
                                widget.comparisonResult.comparedAutomaton,
                            title: widget.automatonBTitle ?? 'Automaton B',
                            canvasKey: _automatonBCanvasKey,
                            colorScheme: colorScheme,
                            textTheme: textTheme,
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Product automaton section (collapsible)
                  if (widget.comparisonResult.productAutomaton != null) ...[
                    const SizedBox(height: 16),
                    _buildProductAutomatonSection(colorScheme, textTheme),
                  ],

                  // Algorithm steps section (collapsible)
                  if (widget.comparisonResult.steps.isNotEmpty) ...[
                    const SizedBox(height: 16),
                    _buildStepsSection(colorScheme, textTheme),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(ColorScheme colorScheme, TextTheme textTheme) {
    final isEquivalent = widget.comparisonResult.isEquivalent;
    final badgeColor = isEquivalent ? colorScheme.primary : colorScheme.error;
    final badgeIcon = isEquivalent ? Icons.check_circle : Icons.cancel;
    final badgeText = isEquivalent ? 'EQUIVALENT' : 'NOT EQUIVALENT';

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: badgeColor.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: badgeColor.withValues(alpha: 0.3), width: 2),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(badgeIcon, color: badgeColor, size: 24),
          const SizedBox(width: 8),
          Text(
            badgeText,
            style: textTheme.titleLarge?.copyWith(
              color: badgeColor,
              fontWeight: FontWeight.bold,
            ),
          ),
          const Spacer(),
          Icon(Icons.access_time, color: colorScheme.onSurface, size: 16),
          const SizedBox(width: 4),
          Text(
            '${widget.comparisonResult.executionTimeMs}ms',
            style: textTheme.bodySmall?.copyWith(
              color: colorScheme.onSurface.withValues(alpha: 0.7),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCounterexampleSection(
    ColorScheme colorScheme,
    TextTheme textTheme,
  ) {
    final distinguishingString = widget.comparisonResult.distinguishingString;
    if (distinguishingString == null) return const SizedBox.shrink();

    final displayString = distinguishingString.isEmpty
        ? 'ε (empty string)'
        : '"$distinguishingString"';

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colorScheme.errorContainer.withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: colorScheme.error.withValues(alpha: 0.3),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.warning_amber, color: colorScheme.error, size: 20),
              const SizedBox(width: 8),
              Text(
                'Distinguishing String Found',
                style: textTheme.titleMedium?.copyWith(
                  color: colorScheme.onErrorContainer,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: colorScheme.surface,
              borderRadius: BorderRadius.circular(6),
              border: Border.all(
                color: colorScheme.outline.withValues(alpha: 0.2),
              ),
            ),
            child: Row(
              children: [
                Icon(Icons.text_fields, color: colorScheme.primary, size: 18),
                const SizedBox(width: 8),
                Text(
                  displayString,
                  style: textTheme.bodyLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                    fontFamily: 'monospace',
                    color: colorScheme.onSurface,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'This string is accepted by one automaton but rejected by the other, '
            'proving that the two automata recognize different languages.',
            style: textTheme.bodyMedium?.copyWith(
              color: colorScheme.onErrorContainer.withValues(alpha: 0.8),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatistics(ColorScheme colorScheme, TextTheme textTheme) {
    final automatonA = widget.comparisonResult.originalAutomaton;
    final automatonB = widget.comparisonResult.comparedAutomaton;
    final statesA = automatonA.states.length;
    final statesB = automatonB.states.length;
    final transitionsA = automatonA.transitions.length;
    final transitionsB = automatonB.transitions.length;

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: colorScheme.outline.withValues(alpha: 0.2),
          width: 1,
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildStatItem(
            label: 'States (A)',
            value: statesA,
            colorScheme: colorScheme,
            textTheme: textTheme,
          ),
          Container(
            width: 1,
            height: 40,
            color: colorScheme.outline.withValues(alpha: 0.2),
          ),
          _buildStatItem(
            label: 'States (B)',
            value: statesB,
            colorScheme: colorScheme,
            textTheme: textTheme,
          ),
          Container(
            width: 1,
            height: 40,
            color: colorScheme.outline.withValues(alpha: 0.2),
          ),
          _buildStatItem(
            label: 'Transitions (A)',
            value: transitionsA,
            colorScheme: colorScheme,
            textTheme: textTheme,
          ),
          Container(
            width: 1,
            height: 40,
            color: colorScheme.outline.withValues(alpha: 0.2),
          ),
          _buildStatItem(
            label: 'Transitions (B)',
            value: transitionsB,
            colorScheme: colorScheme,
            textTheme: textTheme,
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem({
    required String label,
    required int value,
    required ColorScheme colorScheme,
    required TextTheme textTheme,
  }) {
    return Column(
      children: [
        Text(
          label,
          style: textTheme.labelSmall?.copyWith(
            color: colorScheme.onSurface.withValues(alpha: 0.6),
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          value.toString(),
          style: textTheme.titleLarge?.copyWith(
            color: colorScheme.primary,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  Widget _buildAutomatonSection({
    required BuildContext context,
    required FSA automaton,
    required String title,
    required GlobalKey canvasKey,
    required ColorScheme colorScheme,
    required TextTheme textTheme,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Section title
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: colorScheme.secondaryContainer.withValues(alpha: 0.3),
            borderRadius: const BorderRadius.vertical(top: Radius.circular(8)),
            border: Border.all(
              color: colorScheme.outline.withValues(alpha: 0.2),
            ),
          ),
          child: Row(
            children: [
              Icon(Icons.account_tree, color: colorScheme.primary, size: 18),
              const SizedBox(width: 8),
              Text(
                title,
                style: textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: colorScheme.onSurface,
                ),
              ),
            ],
          ),
        ),

        // Canvas
        Expanded(
          child: Container(
            decoration: BoxDecoration(
              color: colorScheme.surface,
              borderRadius: const BorderRadius.vertical(
                bottom: Radius.circular(8),
              ),
              border: Border.all(
                color: colorScheme.outline.withValues(alpha: 0.2),
              ),
            ),
            child: ClipRRect(
              borderRadius: const BorderRadius.vertical(
                bottom: Radius.circular(8),
              ),
              child: ReadOnlyFsaGraphViewCanvas(
                automaton: automaton,
                canvasKey: canvasKey,
                edgeRenderMode: TuringLabEdgeRenderMode.groupedFsa,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildProductAutomatonSection(
    ColorScheme colorScheme,
    TextTheme textTheme,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        InkWell(
          onTap: () {
            setState(() {
              _showProductAutomatonSection = !_showProductAutomatonSection;
            });
          },
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: colorScheme.tertiaryContainer.withValues(alpha: 0.3),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: colorScheme.outline.withValues(alpha: 0.2),
              ),
            ),
            child: Row(
              children: [
                Icon(
                  _showProductAutomatonSection
                      ? Icons.expand_more
                      : Icons.chevron_right,
                  color: colorScheme.onSurface,
                  size: 20,
                ),
                const SizedBox(width: 8),
                Icon(Icons.grid_on, color: colorScheme.tertiary, size: 18),
                const SizedBox(width: 8),
                Text(
                  'Product Automaton',
                  style: textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: colorScheme.onSurface,
                  ),
                ),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: colorScheme.tertiary.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    'Optional',
                    style: textTheme.labelSmall?.copyWith(
                      color: colorScheme.tertiary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        if (_showProductAutomatonSection) ...[
          const SizedBox(height: 8),
          SizedBox(
            height: 300,
            child: Container(
              decoration: BoxDecoration(
                color: colorScheme.surface,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: colorScheme.outline.withValues(alpha: 0.2),
                ),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: ReadOnlyFsaGraphViewCanvas(
                  automaton: widget.comparisonResult.productAutomaton!,
                  canvasKey: _productCanvasKey,
                  edgeRenderMode: TuringLabEdgeRenderMode.groupedFsa,
                ),
              ),
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildStepsSection(ColorScheme colorScheme, TextTheme textTheme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        InkWell(
          onTap: () {
            setState(() {
              _showStepsSection = !_showStepsSection;
            });
          },
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: colorScheme.primaryContainer.withValues(alpha: 0.3),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: colorScheme.outline.withValues(alpha: 0.2),
              ),
            ),
            child: Row(
              children: [
                Icon(
                  _showStepsSection ? Icons.expand_more : Icons.chevron_right,
                  color: colorScheme.onSurface,
                  size: 20,
                ),
                const SizedBox(width: 8),
                Icon(Icons.list_alt, color: colorScheme.primary, size: 18),
                const SizedBox(width: 8),
                Text(
                  'Algorithm Steps',
                  style: textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: colorScheme.onSurface,
                  ),
                ),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: colorScheme.primary.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    '${widget.comparisonResult.steps.length} steps',
                    style: textTheme.labelSmall?.copyWith(
                      color: colorScheme.primary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        if (_showStepsSection) ...[
          const SizedBox(height: 8),
          SizedBox(
            height: 300,
            child: ListView.builder(
              itemCount: widget.comparisonResult.steps.length,
              itemBuilder: (context, index) {
                final step = _LanguageComparisonStepViewModel.fromMap(
                  widget.comparisonResult.steps[index],
                  fallbackStepNumber: index + 1,
                );
                return _buildStepCard(step, colorScheme, textTheme);
              },
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildStepCard(
    _LanguageComparisonStepViewModel step,
    ColorScheme colorScheme,
    TextTheme textTheme,
  ) {
    final accentColor = step.accentColor(colorScheme);

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 4),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            CircleAvatar(
              radius: 16,
              backgroundColor: accentColor,
              child: Text(
                '${step.stepNumber}',
                style: textTheme.labelMedium?.copyWith(
                  color: colorScheme.onPrimary,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(step.icon, color: accentColor, size: 18),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          appLocalizationsOf(context)
                              .localizeWorkflowText(step.title),
                          style: textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ],
                  ),
                  if (step.description.isNotEmpty) ...[
                    const SizedBox(height: 6),
                    Text(
                      appLocalizationsOf(context)
                          .localizeWorkflowText(step.description),
                      style: textTheme.bodySmall,
                    ),
                  ],
                  if (step.details.isNotEmpty) ...[
                    const SizedBox(height: 10),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        for (final detail in step.details)
                          _buildStepDetailChip(
                            detail,
                            colorScheme,
                            textTheme,
                          ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStepDetailChip(
    _LanguageComparisonStepDetail detail,
    ColorScheme colorScheme,
    TextTheme textTheme,
  ) {
    return Container(
      constraints: const BoxConstraints(minWidth: 96, maxWidth: 220),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.55),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: colorScheme.outline.withValues(alpha: 0.18),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            detail.label,
            style: textTheme.labelSmall?.copyWith(
              color: colorScheme.onSurfaceVariant,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            detail.value,
            style: textTheme.bodySmall?.copyWith(
              color: colorScheme.onSurface,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}

class _LanguageComparisonStepViewModel {
  final int stepNumber;
  final _LanguageComparisonStepKind kind;
  final String title;
  final String description;
  final List<_LanguageComparisonStepDetail> details;

  const _LanguageComparisonStepViewModel({
    required this.stepNumber,
    required this.kind,
    required this.title,
    required this.description,
    required this.details,
  });

  factory _LanguageComparisonStepViewModel.fromMap(
    Map<String, dynamic> stepData, {
    required int fallbackStepNumber,
  }) {
    final rawType = stepData['type']?.toString() ?? '';
    final data = _stepDataMap(stepData['data']);
    final stepNumber = _stepNumber(stepData['stepNumber'], fallbackStepNumber);
    final description = stepData['description']?.toString() ?? '';

    switch (rawType) {
      case 'validation':
        return _LanguageComparisonStepViewModel(
          stepNumber: stepNumber,
          kind: _LanguageComparisonStepKind.validation,
          title: 'Validation',
          description: description,
          details: [
            if (data['automatonA'] != null)
              _LanguageComparisonStepDetail(
                'Automaton A',
                _formatStepValue(data['automatonA']),
              ),
            if (data['automatonB'] != null)
              _LanguageComparisonStepDetail(
                'Automaton B',
                _formatStepValue(data['automatonB']),
              ),
          ],
        );
      case 'initialization':
        return _LanguageComparisonStepViewModel(
          stepNumber: stepNumber,
          kind: _LanguageComparisonStepKind.validation,
          title: 'Initialization',
          description: description,
          details: const [],
        );
      case 'alphabet_normalization':
        return _LanguageComparisonStepViewModel(
          stepNumber: stepNumber,
          kind: _LanguageComparisonStepKind.alphabet,
          title: 'Alphabet Normalization',
          description: description,
          details: [
            _LanguageComparisonStepDetail(
              'Automaton A alphabet',
              _formatStepValue(data['alphabetA']),
            ),
            _LanguageComparisonStepDetail(
              'Automaton B alphabet',
              _formatStepValue(data['alphabetB']),
            ),
            _LanguageComparisonStepDetail(
              'Shared alphabet',
              _formatStepValue(data['sharedAlphabet']),
            ),
          ],
        );
      case 'nfa_to_dfa':
        return _LanguageComparisonStepViewModel(
          stepNumber: stepNumber,
          kind: _LanguageComparisonStepKind.conversion,
          title: 'DFA Conversion',
          description: description,
          details: [
            if (data['automaton'] != null)
              _LanguageComparisonStepDetail(
                'Automaton',
                _formatStepValue(data['automaton']),
              ),
            _LanguageComparisonStepDetail(
              'States',
              _formatBeforeAfter(data['statesBefore'], data['statesAfter']),
            ),
          ],
        );
      case 'dfa_completion':
        return _LanguageComparisonStepViewModel(
          stepNumber: stepNumber,
          kind: _LanguageComparisonStepKind.conversion,
          title: 'DFA Completion',
          description: description,
          details: [
            if (data['automaton'] != null)
              _LanguageComparisonStepDetail(
                'Automaton',
                _formatStepValue(data['automaton']),
              ),
            _LanguageComparisonStepDetail(
              'States',
              _formatBeforeAfter(data['statesBefore'], data['statesAfter']),
            ),
            if (data['wasCompleted'] != null)
              _LanguageComparisonStepDetail(
                'Sink state',
                data['wasCompleted'] == true ? 'added' : 'not needed',
              ),
          ],
        );
      case 'product_construction_start':
        return _LanguageComparisonStepViewModel(
          stepNumber: stepNumber,
          kind: _LanguageComparisonStepKind.product,
          title: 'Product Construction',
          description: description,
          details: [
            if (data['alphabetSize'] != null)
              _LanguageComparisonStepDetail(
                'Alphabet size',
                _formatStepValue(data['alphabetSize']),
              ),
          ],
        );
      case 'product_state_created':
        return _LanguageComparisonStepViewModel(
          stepNumber: stepNumber,
          kind: _LanguageComparisonStepKind.product,
          title: 'Product State Created',
          description: description,
          details: [
            _LanguageComparisonStepDetail(
              'State pair',
              _formatStatePair(data['stateA'], data['stateB']),
            ),
            if (data['productState'] != null)
              _LanguageComparisonStepDetail(
                'Product state',
                _formatStepValue(data['productState']),
              ),
            if (data['isAccepting'] != null)
              _LanguageComparisonStepDetail(
                'Accepting',
                _formatBoolean(data['isAccepting']),
              ),
          ],
        );
      case 'product_transition_created':
        return _LanguageComparisonStepViewModel(
          stepNumber: stepNumber,
          kind: _LanguageComparisonStepKind.product,
          title: 'Product Transition',
          description: description,
          details: [
            _LanguageComparisonStepDetail(
              'Transition',
              '${_formatStepValue(data['fromState'])} -> '
                  '${_formatStepValue(data['toState'])}',
            ),
            if (data['symbol'] != null)
              _LanguageComparisonStepDetail(
                'Symbol',
                _formatSymbol(data['symbol']),
              ),
            if (data['targetIsNew'] != null)
              _LanguageComparisonStepDetail(
                'Target',
                data['targetIsNew'] == true ? 'new' : 'existing',
              ),
          ],
        );
      case 'product_construction_complete':
        return _LanguageComparisonStepViewModel(
          stepNumber: stepNumber,
          kind: _LanguageComparisonStepKind.product,
          title: 'Product Construction Complete',
          description: description,
          details: [
            _LanguageComparisonStepDetail(
              'States',
              _formatStepValue(data['totalStates']),
            ),
            _LanguageComparisonStepDetail(
              'Transitions',
              _formatStepValue(data['totalTransitions']),
            ),
            _LanguageComparisonStepDetail(
              'Accepting states',
              _formatStepValue(data['acceptingStates']),
            ),
          ],
        );
      case 'bfs_search_start':
        return _LanguageComparisonStepViewModel(
          stepNumber: stepNumber,
          kind: _LanguageComparisonStepKind.search,
          title: 'BFS Search',
          description: description,
          details: [
            _LanguageComparisonStepDetail(
              'Initial pair',
              _formatStatePair(data['initialStateA'], data['initialStateB']),
            ),
          ],
        );
      case 'bfs_initial_check':
        return _LanguageComparisonStepViewModel(
          stepNumber: stepNumber,
          kind: _LanguageComparisonStepKind.search,
          title: 'Initial Pair Check',
          description: description,
          details: [
            _LanguageComparisonStepDetail(
              'State pair',
              _formatStatePair(data['stateA'], data['stateB']),
            ),
            _LanguageComparisonStepDetail(
              'Acceptance',
              _formatAcceptance(data['acceptsA'], data['acceptsB']),
            ),
          ],
        );
      case 'bfs_explore_pair':
      case 'bfs_exploration':
        return _LanguageComparisonStepViewModel(
          stepNumber: stepNumber,
          kind: _LanguageComparisonStepKind.search,
          title: 'State Pair Visit',
          description: description,
          details: [
            if (data['stateA'] != null || data['stateB'] != null)
              _LanguageComparisonStepDetail(
                'State pair',
                _formatStatePair(data['stateA'], data['stateB']),
              ),
            if (data['currentPath'] != null)
              _LanguageComparisonStepDetail(
                'Path',
                _formatPath(data['currentPath']),
              ),
            if (data['pathLength'] != null)
              _LanguageComparisonStepDetail(
                'Path length',
                _formatStepValue(data['pathLength']),
              ),
          ],
        );
      case 'bfs_distinguishing_found':
      case 'counterexample_found':
        return _LanguageComparisonStepViewModel(
          stepNumber: stepNumber,
          kind: _LanguageComparisonStepKind.counterexample,
          title: 'Counterexample Found',
          description: description,
          details: [
            if (data['distinguishingString'] != null)
              _LanguageComparisonStepDetail(
                'Distinguishing string',
                _formatDisplayString(data['distinguishingString']),
              ),
            if (data['stateA'] != null || data['stateB'] != null)
              _LanguageComparisonStepDetail(
                'State pair',
                _formatStatePair(data['stateA'], data['stateB']),
              ),
            if (data['acceptsA'] != null || data['acceptsB'] != null)
              _LanguageComparisonStepDetail(
                'Acceptance',
                _formatAcceptance(data['acceptsA'], data['acceptsB']),
              ),
            if (data['symbol'] != null)
              _LanguageComparisonStepDetail(
                'Symbol',
                _formatSymbol(data['symbol']),
              ),
          ],
        );
      case 'bfs_complete':
        return _LanguageComparisonStepViewModel(
          stepNumber: stepNumber,
          kind: _LanguageComparisonStepKind.search,
          title: 'BFS Complete',
          description: description,
          details: [
            if (data['totalPairsExplored'] != null)
              _LanguageComparisonStepDetail(
                'Pairs explored',
                _formatStepValue(data['totalPairsExplored']),
              ),
          ],
        );
      case 'result':
        return _LanguageComparisonStepViewModel(
          stepNumber: stepNumber,
          kind: data['isEquivalent'] == true
              ? _LanguageComparisonStepKind.result
              : _LanguageComparisonStepKind.counterexample,
          title: 'Comparison Result',
          description: description,
          details: [
            if (data['isEquivalent'] != null)
              _LanguageComparisonStepDetail(
                'Equivalent',
                _formatBoolean(data['isEquivalent']),
              ),
            if (data['distinguishingString'] != null)
              _LanguageComparisonStepDetail(
                'Distinguishing string',
                _formatDisplayString(data['distinguishingString']),
              ),
          ],
        );
      default:
        return _LanguageComparisonStepViewModel(
          stepNumber: stepNumber,
          kind: _LanguageComparisonStepKind.unknown,
          title: 'Unknown Step',
          description: description,
          details: [
            _LanguageComparisonStepDetail(
              'Raw type',
              rawType.isEmpty ? 'untyped' : rawType,
            ),
            for (final entry in data.entries)
              _LanguageComparisonStepDetail(
                entry.key,
                _formatStepValue(entry.value),
              ),
          ],
        );
    }
  }

  IconData get icon {
    return switch (kind) {
      _LanguageComparisonStepKind.validation => Icons.rule,
      _LanguageComparisonStepKind.alphabet => Icons.sort_by_alpha,
      _LanguageComparisonStepKind.conversion => Icons.transform,
      _LanguageComparisonStepKind.product => Icons.grid_on,
      _LanguageComparisonStepKind.search => Icons.manage_search,
      _LanguageComparisonStepKind.counterexample => Icons.warning_amber,
      _LanguageComparisonStepKind.result => Icons.check_circle,
      _LanguageComparisonStepKind.unknown => Icons.help_outline,
    };
  }

  Color accentColor(ColorScheme colorScheme) {
    return switch (kind) {
      _LanguageComparisonStepKind.validation => colorScheme.primary,
      _LanguageComparisonStepKind.alphabet => colorScheme.secondary,
      _LanguageComparisonStepKind.conversion => colorScheme.tertiary,
      _LanguageComparisonStepKind.product => colorScheme.tertiary,
      _LanguageComparisonStepKind.search => colorScheme.primary,
      _LanguageComparisonStepKind.counterexample => colorScheme.error,
      _LanguageComparisonStepKind.result => colorScheme.primary,
      _LanguageComparisonStepKind.unknown => colorScheme.outline,
    };
  }
}

class _LanguageComparisonStepDetail {
  final String label;
  final String value;

  const _LanguageComparisonStepDetail(this.label, this.value);
}

enum _LanguageComparisonStepKind {
  validation,
  alphabet,
  conversion,
  product,
  search,
  counterexample,
  result,
  unknown,
}

Map<String, dynamic> _stepDataMap(Object? rawData) {
  if (rawData is Map) {
    return rawData.map((key, value) => MapEntry(key.toString(), value));
  }
  return const {};
}

int _stepNumber(Object? rawStepNumber, int fallbackStepNumber) {
  if (rawStepNumber is int) return rawStepNumber;
  if (rawStepNumber is num) return rawStepNumber.toInt();
  if (rawStepNumber is String) {
    return int.tryParse(rawStepNumber) ?? fallbackStepNumber;
  }
  return fallbackStepNumber;
}

String _formatBeforeAfter(Object? before, Object? after) {
  if (before == null && after == null) return 'unknown';
  return '${_formatStepValue(before)} -> ${_formatStepValue(after)}';
}

String _formatStatePair(Object? stateA, Object? stateB) {
  if (stateA == null && stateB == null) return 'unknown';
  return '${_formatStepValue(stateA)} / ${_formatStepValue(stateB)}';
}

String _formatAcceptance(Object? acceptsA, Object? acceptsB) {
  if (acceptsA is bool && acceptsB is bool) {
    final a = acceptsA ? 'accepts' : 'rejects';
    final b = acceptsB ? 'accepts' : 'rejects';
    return 'A $a, B $b';
  }
  return 'unknown';
}

String _formatBoolean(Object? value) {
  if (value is bool) return value ? 'yes' : 'no';
  return _formatStepValue(value);
}

String _formatSymbol(Object? value) {
  final symbol = _formatStepValue(value);
  return symbol.isEmpty ? 'ε' : symbol;
}

String _formatPath(Object? value) {
  final path = _formatStepValue(value);
  return path.isEmpty ? 'ε' : path;
}

String _formatDisplayString(Object? value) {
  final string = _formatStepValue(value);
  return string.isEmpty ? 'ε (empty string)' : '"$string"';
}

String _formatStepValue(Object? value) {
  if (value == null) return 'unknown';
  if (value is Iterable) {
    return value.map(_formatStepValue).join(', ');
  }
  if (value is Map) {
    return value.entries
        .map((entry) => '${entry.key}: ${_formatStepValue(entry.value)}')
        .join(', ');
  }
  return value.toString();
}
