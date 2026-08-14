//
//  algorithm_button.dart
//  Turing Lab
//
//  Reusable button component for algorithm operations across automata panels.
//  Provides consistent visual feedback for execution states, progress tracking,
//  and destructive actions. Centralizes loading indicators, disabled states,
//  and accessibility semantics for all algorithm triggers.
//
//  Thales Matheus Mendonça Santos - January 2026
//

import 'package:flutter/material.dart';

import '../../../l10n/app_localizations_resolver.dart';
import '../../../l10n/app_localizations_workflows.dart';
import 'algorithm_button_config.dart';

/// Button for algorithm operations with consistent styling and state handling.
///
/// This widget standardizes algorithm action buttons across different automata
/// panels (FSA, PDA, TM, Grammar), providing unified visual feedback for
/// execution progress, loading states, and disabled conditions.
///
/// Features:
/// - Loading/executing state visualization with progress indicator
/// - Optional execution progress percentage display
/// - Destructive action styling (error color scheme)
/// - Dynamic status text override during execution
/// - Disabled state when operation is unavailable or another is running
/// - Accessibility semantics for screen readers
///
/// Example:
/// ```dart
/// AlgorithmButton(
///   title: 'NFA to DFA',
///   description: 'Convert non-deterministic to deterministic automaton',
///   icon: Icons.transform,
///   onPressed: () => convertNfaToDfa(),
///   isExecuting: _isConverting,
///   executionStatus: 'Building product construction...',
/// )
/// ```
class AlgorithmButton extends StatelessWidget {
  const AlgorithmButton({
    super.key,
    required this.title,
    required this.description,
    required this.icon,
    this.onPressed,
    this.isExecuting = false,
    this.isDestructive = false,
    this.isSelected = false,
    this.executionProgress,
    this.executionStatus,
  })  : assert(title != '', 'title must not be empty'),
        assert(description != '', 'description must not be empty'),
        assert(
          executionProgress == null ||
              (executionProgress >= 0.0 && executionProgress <= 1.0),
          'executionProgress must be between 0.0 and 1.0',
        );

  factory AlgorithmButton.fromConfig(
    AlgorithmButtonConfig config, {
    Key? key,
  }) {
    return AlgorithmButton(
      key: key,
      title: config.title,
      description: config.description,
      icon: config.icon,
      onPressed: config.effectiveOnPressed,
      isExecuting: config.isExecuting,
      isDestructive: config.isDestructive,
      isSelected: config.isSelected,
      executionProgress: config.executionProgress,
      executionStatus: config.executionStatus,
    );
  }

  /// Primary label displayed prominently at the top of the button.
  final String title;

  /// Secondary text explaining what the algorithm does.
  ///
  /// This is replaced by [executionStatus] when [isExecuting] is true and
  /// [executionStatus] is provided.
  final String description;

  /// Icon representing the algorithm operation.
  ///
  /// Replaced by a [CircularProgressIndicator] when [isExecuting] is true.
  final IconData icon;

  /// Callback executed when the user taps the button.
  ///
  /// If null, the button is disabled. If [isExecuting] is true, the button
  /// is also disabled to prevent concurrent operations.
  final VoidCallback? onPressed;

  /// Whether this algorithm is currently running.
  ///
  /// When true, displays a loading indicator instead of the icon and
  /// optionally shows [executionProgress] percentage.
  final bool isExecuting;

  /// Whether this action is destructive (e.g., Clear, Delete).
  ///
  /// Destructive actions use error color scheme to warn users.
  final bool isDestructive;

  /// Whether this button is currently selected.
  ///
  /// When true, displays with highlighted border and background to indicate
  /// the active/focused algorithm. Used in panels with multiple analysis modes
  /// (e.g., TM panel with different focus views).
  final bool isSelected;

  /// Current execution progress from 0.0 to 1.0.
  ///
  /// When provided during execution, displays a percentage indicator on the
  /// trailing edge of the button.
  final double? executionProgress;

  /// Status message to display during execution.
  ///
  /// Overrides [description] when [isExecuting] is true and this is non-null.
  final String? executionStatus;

  bool get _isDisabled => onPressed == null || isExecuting;

  @override
  Widget build(BuildContext context) {
    final l10n = appLocalizationsOf(context);
    final localizedTitle = l10n.localizeWorkflowText(title);
    final localizedDescription = l10n.localizeWorkflowText(description);
    final colorScheme = Theme.of(context).colorScheme;
    final color = isDestructive ? colorScheme.error : colorScheme.primary;

    return Semantics(
      label: l10n.algorithmAction(localizedTitle),
      hint: _isDisabled
          ? l10n.algorithmUnavailableHint(localizedDescription)
          : l10n.algorithmStartHint(localizedDescription),
      value: isExecuting
          ? l10n.executing
          : isSelected
              ? l10n.selected
              : null,
      button: true,
      enabled: !_isDisabled,
      excludeSemantics: true,
      child: InkWell(
        onTap: _isDisabled ? null : onPressed,
        borderRadius: BorderRadius.circular(8),
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            border: Border.all(
              color: _isDisabled
                  ? colorScheme.outline.withValues(alpha: 0.3)
                  : isSelected
                      ? color
                      : color.withValues(alpha: 0.3),
              width: isExecuting ? 2 : 1,
            ),
            borderRadius: BorderRadius.circular(8),
            color: _isDisabled
                ? colorScheme.surfaceContainerHighest.withValues(alpha: 0.5)
                : isSelected
                    ? colorScheme.primaryContainer.withValues(alpha: 0.35)
                    : isExecuting
                        ? color.withValues(alpha: 0.1)
                        : null,
          ),
          child: Row(
            children: [
              _buildLeadingIcon(context, color, colorScheme),
              const SizedBox(width: 12),
              Expanded(child: _buildContent(context, color, colorScheme)),
              _buildTrailingIcon(context, color, colorScheme),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLeadingIcon(
    BuildContext context,
    Color color,
    ColorScheme colorScheme,
  ) {
    if (isExecuting) {
      return SizedBox(
        width: 24,
        height: 24,
        child: CircularProgressIndicator(
          strokeWidth: 2,
          valueColor: AlwaysStoppedAnimation<Color>(color),
        ),
      );
    }

    return Icon(
      icon,
      color: _isDisabled ? colorScheme.outline.withValues(alpha: 0.5) : color,
      size: 24,
    );
  }

  Widget _buildContent(
    BuildContext context,
    Color color,
    ColorScheme colorScheme,
  ) {
    final l10n = appLocalizationsOf(context);
    final displayDescription = l10n.localizeWorkflowText(
      isExecuting && executionStatus != null ? executionStatus! : description,
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          l10n.localizeWorkflowText(title),
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                color: _isDisabled
                    ? colorScheme.outline.withValues(alpha: 0.5)
                    : color,
                fontWeight: FontWeight.w600,
              ),
        ),
        const SizedBox(height: 4),
        Text(
          displayDescription,
          maxLines: 3,
          overflow: TextOverflow.ellipsis,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: _isDisabled
                    ? colorScheme.outline.withValues(alpha: 0.5)
                    : colorScheme.onSurface.withValues(alpha: 0.7),
              ),
        ),
      ],
    );
  }

  Widget _buildTrailingIcon(
    BuildContext context,
    Color color,
    ColorScheme colorScheme,
  ) {
    if (isExecuting && executionProgress != null) {
      return Text(
        '${(executionProgress! * 100).toInt()}%',
        style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: color,
              fontWeight: FontWeight.bold,
            ),
      );
    }

    return Icon(
      Icons.arrow_forward_ios,
      color: _isDisabled
          ? colorScheme.outline.withValues(alpha: 0.5)
          : color.withValues(alpha: 0.5),
      size: 16,
    );
  }
}
