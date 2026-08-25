//
//  before_after_comparison.dart
//  Turing Lab
//
//  Widget for side-by-side comparison of automata before and after
//  conversion algorithms. Shows the original automaton on the left and
//  the result on the right for educational views of NFA→DFA, DFA
//  minimization, and FA→Regex transformations.
//  Uses a GraphView canvas in read-only mode for non-interactive rendering.
//
//  Thales Matheus Mendonça Santos - January 2026
//
import 'package:flutter/material.dart';
import '../../core/models/fsa.dart';
import '../../features/canvas/graphview/turing_lab_adaptive_edge_renderer.dart';
import '../../l10n/app_localizations_resolver.dart';
import '../../l10n/app_localizations_workflows.dart';
import 'read_only_fsa_graphview_canvas.dart';

/// Widget for side-by-side comparison of automata before and after algorithm execution
///
/// Displays the original automaton on the left and the result automaton on the right,
/// enabling educational visualization of transformations applied by conversion algorithms.
class BeforeAfterComparison extends StatefulWidget {
  /// The original automaton before algorithm execution
  final FSA beforeAutomaton;

  /// The result automaton after algorithm execution
  final FSA afterAutomaton;

  /// Optional title for the before section (defaults to "Before")
  final String? beforeTitle;

  /// Optional title for the after section (defaults to "After")
  final String? afterTitle;

  /// Optional subtitle describing the transformation
  final String? transformationDescription;

  /// Whether to show statistics comparing the two automata
  final bool showStatistics;

  const BeforeAfterComparison({
    super.key,
    required this.beforeAutomaton,
    required this.afterAutomaton,
    this.beforeTitle,
    this.afterTitle,
    this.transformationDescription,
    this.showStatistics = true,
  });

  @override
  State<BeforeAfterComparison> createState() => _BeforeAfterComparisonState();
}

class _BeforeAfterComparisonState extends State<BeforeAfterComparison> {
  final GlobalKey _beforeCanvasKey = GlobalKey();
  final GlobalKey _afterCanvasKey = GlobalKey();

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
            // Header with transformation description
            if (widget.transformationDescription != null) ...[
              _buildHeader(colorScheme, textTheme),
              const SizedBox(height: 16),
            ],

            // Statistics comparison
            if (widget.showStatistics) ...[
              _buildStatistics(colorScheme, textTheme),
              const SizedBox(height: 16),
            ],

            // Side-by-side automaton comparison
            Expanded(
              child: Row(
                children: [
                  // Before automaton
                  Expanded(
                    child: _buildAutomatonSection(
                      context: context,
                      automaton: widget.beforeAutomaton,
                      title: widget.beforeTitle ?? 'Before',
                      canvasKey: _beforeCanvasKey,
                      colorScheme: colorScheme,
                      textTheme: textTheme,
                    ),
                  ),
                  const SizedBox(width: 16),

                  // After automaton
                  Expanded(
                    child: _buildAutomatonSection(
                      context: context,
                      automaton: widget.afterAutomaton,
                      title: widget.afterTitle ?? 'After',
                      canvasKey: _afterCanvasKey,
                      colorScheme: colorScheme,
                      textTheme: textTheme,
                      isResult: true,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(ColorScheme colorScheme, TextTheme textTheme) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: colorScheme.primaryContainer.withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: colorScheme.primary.withValues(alpha: 0.2),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          Icon(Icons.compare_arrows, color: colorScheme.primary, size: 20),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              widget.transformationDescription!,
              style: textTheme.titleSmall?.copyWith(
                color: colorScheme.onSurface,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatistics(ColorScheme colorScheme, TextTheme textTheme) {
    final beforeStates = widget.beforeAutomaton.states.length;
    final afterStates = widget.afterAutomaton.states.length;
    final beforeTransitions = widget.beforeAutomaton.transitions.length;
    final afterTransitions = widget.afterAutomaton.transitions.length;

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
            label: 'States',
            before: beforeStates,
            after: afterStates,
            colorScheme: colorScheme,
            textTheme: textTheme,
          ),
          Container(
            width: 1,
            height: 40,
            color: colorScheme.outline.withValues(alpha: 0.2),
          ),
          _buildStatItem(
            label: 'Transitions',
            before: beforeTransitions,
            after: afterTransitions,
            colorScheme: colorScheme,
            textTheme: textTheme,
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem({
    required String label,
    required int before,
    required int after,
    required ColorScheme colorScheme,
    required TextTheme textTheme,
  }) {
    final change = after - before;
    final changeText = change > 0 ? '+$change' : '$change';
    final changeColor = change > 0
        ? colorScheme.error
        : (change < 0 ? colorScheme.primary : colorScheme.onSurfaceVariant);

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          label,
          style: textTheme.labelSmall?.copyWith(
            color: colorScheme.onSurfaceVariant,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 4),
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              '$before',
              style: textTheme.bodyMedium?.copyWith(
                color: colorScheme.onSurface.withValues(alpha: 0.7),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4),
              child: Icon(
                Icons.arrow_forward,
                size: 14,
                color: colorScheme.onSurfaceVariant,
              ),
            ),
            Text(
              '$after',
              style: textTheme.bodyMedium?.copyWith(
                color: colorScheme.onSurface,
                fontWeight: FontWeight.w600,
              ),
            ),
            if (change != 0) ...[
              const SizedBox(width: 4),
              Text(
                '($changeText)',
                style: textTheme.bodySmall?.copyWith(
                  color: changeColor,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ],
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
    bool isResult = false,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Section title
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: isResult
                ? colorScheme.primaryContainer.withValues(alpha: 0.5)
                : colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: isResult
                  ? colorScheme.primary.withValues(alpha: 0.3)
                  : colorScheme.outline.withValues(alpha: 0.2),
              width: 1,
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (isResult) ...[
                Icon(
                  Icons.check_circle_outline,
                  color: colorScheme.primary,
                  size: 16,
                ),
                const SizedBox(width: 6),
              ],
              Text(
                title,
                style: textTheme.titleMedium?.copyWith(
                  color: colorScheme.onSurface,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),

        // Automaton canvas (read-only)
        Expanded(
          child: Container(
            decoration: BoxDecoration(
              color: colorScheme.surface,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: colorScheme.outline.withValues(alpha: 0.2),
                width: 1,
              ),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: ReadOnlyFsaGraphViewCanvas(
                automaton: automaton,
                canvasKey: canvasKey,
                edgeRenderMode: TuringLabEdgeRenderMode.standard,
              ),
            ),
          ),
        ),

        // Automaton name
        const SizedBox(height: 8),
        Text(
          appLocalizationsOf(context).localizedCanvasName(automaton.name),
          textAlign: TextAlign.center,
          style: textTheme.bodySmall?.copyWith(
            color: colorScheme.onSurfaceVariant,
            fontStyle: FontStyle.italic,
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
      ],
    );
  }
}
