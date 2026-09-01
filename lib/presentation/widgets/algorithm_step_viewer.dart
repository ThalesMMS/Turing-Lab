//
//  algorithm_step_viewer.dart
//  Turing Lab
//
//  Widget that shows details and explanations for a specific step during
//  educational conversion algorithms (NFA→DFA, minimization, FA→Regex).
//  Renders the title, textual explanation, and algorithm-specific data
//  (subsets, partitions, transitions) in a didactic layout.
//
//  Thales Matheus Mendonça Santos - January 2026
//
import 'package:flutter/material.dart';

import '../empty_string_notation.dart';
import '../../core/algorithms/fsa_concatenation_messages.dart';
import '../../core/algorithms/fsa_kleene_star_messages.dart';
import '../../core/algorithms/fsa_reverser_messages.dart';
import '../../core/messages/structured_message.dart';
import '../../core/models/algorithm_step.dart';
import '../../core/models/cyk_step_messages.dart';
import '../../core/models/dfa_minimization_step_messages.dart';
import '../../core/models/nfa_to_dfa_step_messages.dart';
import '../../core/models/regex_to_nfa_step.dart';
import '../../l10n/app_localizations_resolver.dart';
import '../../l10n/app_localizations_structured_messages.dart';
import '../../l10n/app_localizations_workflows.dart';
import 'algorithm_step_renderer_registry.dart';

/// Widget for displaying algorithm step details and explanations
///
/// Shows step title, detailed explanation, and algorithm-specific data
/// in an educational format. Used in step-by-step algorithm visualization.
class AlgorithmStepViewer extends StatelessWidget {
  static const _faToRegexTitleMessageProperty = 'faToRegexTitleMessage';
  static const _faToRegexExplanationMessageProperty =
      'faToRegexExplanationMessage';
  static const _structuredMessageProperties = <String>{
    _faToRegexTitleMessageProperty,
    _faToRegexExplanationMessageProperty,
    regexToNfaTitleMessageProperty,
    regexToNfaExplanationMessageProperty,
    FsaKleeneStarMessages.FSA_KLEENE_STAR_TITLE_MESSAGE_PROPERTY,
    FsaKleeneStarMessages.FSA_KLEENE_STAR_EXPLANATION_MESSAGE_PROPERTY,
    FsaReversalMessages.FSA_REVERSAL_TITLE_MESSAGE_PROPERTY,
    FsaReversalMessages.FSA_REVERSAL_EXPLANATION_MESSAGE_PROPERTY,
    FsaConcatenationMessages.FSA_CONCATENATION_TITLE_MESSAGE_PROPERTY,
    FsaConcatenationMessages.FSA_CONCATENATION_EXPLANATION_MESSAGE_PROPERTY,
    dfaMinimizationTitleMessageProperty,
    dfaMinimizationExplanationMessageProperty,
    NfaToDfaStepMessages.NFA_TO_DFA_TITLE_MESSAGE_PROPERTY,
    NfaToDfaStepMessages.NFA_TO_DFA_EXPLANATION_MESSAGE_PROPERTY,
    CykStepMessages.stepTitleMessageProperty,
    CykStepMessages.stepExplanationMessageProperty,
  };

  /// The algorithm step to display
  final AlgorithmStep step;

  /// Optional callback when user wants to see more details
  final VoidCallback? onShowDetails;

  /// Whether to show expanded details by default
  final bool showExpandedDetails;

  /// Optional typed renderer registry for specialized step payloads.
  final AlgorithmStepRendererRegistry? rendererRegistry;

  const AlgorithmStepViewer({
    super.key,
    required this.step,
    this.onShowDetails,
    this.showExpandedDetails = false,
    this.rendererRegistry,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final typedStepData = rendererRegistry?.render(context, step);
    final visibleProperties = Map<String, dynamic>.fromEntries(
      step.properties.entries.where(
        (entry) => !_structuredMessageProperties.contains(entry.key),
      ),
    );

    return Card(
      elevation: 2,
      margin: const EdgeInsets.all(12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Step header with number and title
            _buildStepHeader(context, colorScheme, textTheme),
            const SizedBox(height: 16),

            // Step explanation
            _buildExplanationSection(context, textTheme),
            const SizedBox(height: 16),

            // Algorithm-specific data
            if (typedStepData != null || visibleProperties.isNotEmpty) ...[
              typedStepData ??
                  _buildPropertiesSection(
                    context,
                    colorScheme,
                    textTheme,
                    visibleProperties,
                  ),
              const SizedBox(height: 12),
            ],

            // Additional details button
            if (onShowDetails != null) ...[
              const SizedBox(height: 8),
              _buildDetailsButton(context, colorScheme),
            ],
          ],
        ),
      ),
    );
  }

  /// Builds the step header with step number and title
  Widget _buildStepHeader(
    BuildContext context,
    ColorScheme colorScheme,
    TextTheme textTheme,
  ) {
    final l10n = appLocalizationsOf(context);
    final titleMessage =
        _structuredMessageProperty(step, _faToRegexTitleMessageProperty) ??
        _structuredMessageProperty(step, regexToNfaTitleMessageProperty) ??
        _structuredMessageProperty(
          step,
          FsaKleeneStarMessages.FSA_KLEENE_STAR_TITLE_MESSAGE_PROPERTY,
        ) ??
        _structuredMessageProperty(
          step,
          FsaReversalMessages.FSA_REVERSAL_TITLE_MESSAGE_PROPERTY,
        ) ??
        _structuredMessageProperty(
          step,
          FsaConcatenationMessages.FSA_CONCATENATION_TITLE_MESSAGE_PROPERTY,
        ) ??
        _structuredMessageProperty(step, dfaMinimizationTitleMessageProperty) ??
        _structuredMessageProperty(
          step,
          NfaToDfaStepMessages.NFA_TO_DFA_TITLE_MESSAGE_PROPERTY,
        ) ??
        _structuredMessageProperty(
          step,
          CykStepMessages.stepTitleMessageProperty,
        );
    final stepBadge = Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: colorScheme.primary,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Text(
        '${l10n.stepLabel} ${step.displayNumber}',
        style: textTheme.labelMedium?.copyWith(
          color: colorScheme.onPrimary,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
    final title = Text(
      titleMessage == null
          ? l10n.localizeWorkflowText(step.title)
          : l10n.resolveStructuredMessage(titleMessage),
      style: textTheme.titleLarge?.copyWith(
        fontWeight: FontWeight.bold,
        color: colorScheme.onSurface,
      ),
    );
    final algorithmBadge = Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: colorScheme.secondaryContainer.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: colorScheme.secondary.withValues(alpha: 0.3)),
      ),
      child: Text(
        l10n.localizeWorkflowText(_getAlgorithmTypeLabel(step.type)),
        style: textTheme.labelSmall?.copyWith(
          color: colorScheme.onSecondaryContainer,
          fontWeight: FontWeight.w600,
        ),
      ),
    );

    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth < 480) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [stepBadge, algorithmBadge],
              ),
              const SizedBox(height: 8),
              title,
            ],
          );
        }
        return Row(
          children: [
            stepBadge,
            const SizedBox(width: 12),
            Expanded(child: title),
            algorithmBadge,
          ],
        );
      },
    );
  }

  /// Builds the explanation section
  Widget _buildExplanationSection(BuildContext context, TextTheme textTheme) {
    final l10n = appLocalizationsOf(context);
    final explanationMessage =
        _structuredMessageProperty(
          step,
          _faToRegexExplanationMessageProperty,
        ) ??
        _structuredMessageProperty(
          step,
          regexToNfaExplanationMessageProperty,
        ) ??
        _structuredMessageProperty(
          step,
          FsaKleeneStarMessages.FSA_KLEENE_STAR_EXPLANATION_MESSAGE_PROPERTY,
        ) ??
        _structuredMessageProperty(
          step,
          FsaReversalMessages.FSA_REVERSAL_EXPLANATION_MESSAGE_PROPERTY,
        ) ??
        _structuredMessageProperty(
          step,
          FsaConcatenationMessages
              .FSA_CONCATENATION_EXPLANATION_MESSAGE_PROPERTY,
        ) ??
        _structuredMessageProperty(
          step,
          dfaMinimizationExplanationMessageProperty,
        ) ??
        _structuredMessageProperty(
          step,
          NfaToDfaStepMessages.NFA_TO_DFA_EXPLANATION_MESSAGE_PROPERTY,
        ) ??
        _structuredMessageProperty(
          step,
          CykStepMessages.stepExplanationMessageProperty,
        );
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Theme.of(
          context,
        ).colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.2),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.info_outline,
                size: 18,
                color: Theme.of(context).colorScheme.primary,
              ),
              const SizedBox(width: 8),
              Text(
                l10n.localizeWorkflowText('Explanation'),
                style: textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).colorScheme.primary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            explanationMessage == null
                ? l10n.localizeWorkflowText(step.explanation)
                : l10n.resolveStructuredMessage(explanationMessage),
            style: textTheme.bodyMedium?.copyWith(
              height: 1.5,
              color: Theme.of(context).colorScheme.onSurface,
            ),
          ),
        ],
      ),
    );
  }

  /// Builds the algorithm-specific properties section
  Widget _buildPropertiesSection(
    BuildContext context,
    ColorScheme colorScheme,
    TextTheme textTheme,
    Map<String, dynamic> properties,
  ) {
    final l10n = appLocalizationsOf(context);
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: colorScheme.tertiaryContainer.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: colorScheme.tertiary.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.data_object, size: 18, color: colorScheme.tertiary),
              const SizedBox(width: 8),
              Text(
                l10n.localizeWorkflowText('Step Data'),
                style: textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: colorScheme.tertiary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          ...properties.entries.map((entry) {
            return Padding(
              padding: const EdgeInsets.only(bottom: 6),
              child: _buildPropertyRow(
                context,
                entry.key,
                entry.value,
                textTheme,
              ),
            );
          }),
        ],
      ),
    );
  }

  /// Builds a single property row
  Widget _buildPropertyRow(
    BuildContext context,
    String key,
    dynamic value,
    TextTheme textTheme,
  ) {
    final l10n = appLocalizationsOf(context);
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Property key
        SizedBox(
          width: 140,
          child: Text(
            l10n.localizeWorkflowText(_formatPropertyKey(key)),
            style: textTheme.bodySmall?.copyWith(
              fontWeight: FontWeight.w600,
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
        ),
        const SizedBox(width: 8),

        // Property value
        Expanded(child: _buildPropertyValue(context, value, textTheme)),
      ],
    );
  }

  /// Builds the property value widget based on type
  Widget _buildPropertyValue(
    BuildContext context,
    dynamic value,
    TextTheme textTheme,
  ) {
    final colorScheme = Theme.of(context).colorScheme;
    final l10n = appLocalizationsOf(context);

    // Handle different value types
    if (value is List) {
      if (value.isEmpty) {
        return Text(
          '(empty)',
          style: textTheme.bodySmall?.copyWith(
            fontStyle: FontStyle.italic,
            color: colorScheme.onSurfaceVariant.withValues(alpha: 0.6),
          ),
        );
      }
      return Wrap(
        spacing: 4,
        runSpacing: 4,
        children: value.map((item) {
          return Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(
              color: colorScheme.primaryContainer.withValues(alpha: 0.5),
              borderRadius: BorderRadius.circular(4),
            ),
            child: Text(
              _formatValue(context, item),
              style: textTheme.bodySmall?.copyWith(
                color: colorScheme.onPrimaryContainer,
              ),
            ),
          );
        }).toList(),
      );
    } else if (value is Set) {
      if (value.isEmpty) {
        return Text(
          '∅',
          style: textTheme.bodySmall?.copyWith(
            fontWeight: FontWeight.bold,
            color: colorScheme.onSurfaceVariant.withValues(alpha: 0.6),
          ),
        );
      }
      return Wrap(
        spacing: 4,
        runSpacing: 4,
        children: value.map((item) {
          return Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(
              color: colorScheme.secondaryContainer.withValues(alpha: 0.5),
              borderRadius: BorderRadius.circular(4),
            ),
            child: Text(
              _formatValue(context, item),
              style: textTheme.bodySmall?.copyWith(
                color: colorScheme.onSecondaryContainer,
              ),
            ),
          );
        }).toList(),
      );
    } else if (value is Map) {
      return Text(
        '{${value.length} items}',
        style: textTheme.bodySmall?.copyWith(
          color: colorScheme.onSurfaceVariant,
        ),
      );
    } else if (value is bool) {
      return Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            value ? Icons.check_circle : Icons.cancel,
            size: 16,
            color: value ? colorScheme.tertiary : colorScheme.error,
          ),
          const SizedBox(width: 4),
          Text(
            value ? l10n.yes : l10n.no,
            style: textTheme.bodySmall?.copyWith(
              color: value ? colorScheme.tertiary : colorScheme.error,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      );
    } else {
      return Text(
        _formatValue(context, value),
        style: textTheme.bodySmall?.copyWith(color: colorScheme.onSurface),
      );
    }
  }

  /// Builds the details button
  Widget _buildDetailsButton(BuildContext context, ColorScheme colorScheme) {
    return Center(
      child: TextButton.icon(
        onPressed: onShowDetails,
        icon: Icon(
          showExpandedDetails ? Icons.expand_less : Icons.expand_more,
          size: 18,
        ),
        label: Text(
          showExpandedDetails
              ? appLocalizationsOf(context).hideDetails
              : appLocalizationsOf(context).showDetails,
        ),
        style: TextButton.styleFrom(foregroundColor: colorScheme.primary),
      ),
    );
  }

  /// Formats a property key for display
  String _formatPropertyKey(String key) {
    // Convert camelCase to Title Case
    final result = key.replaceAllMapped(
      RegExp(r'([A-Z])'),
      (match) => ' ${match.group(1)}',
    );
    return result[0].toUpperCase() + result.substring(1);
  }

  /// Formats a value for display
  String _formatValue(BuildContext context, dynamic value) {
    if (value == null) {
      return 'null';
    } else if (value is String) {
      return value.isEmpty
          ? EmptyStringNotation.symbolOf(context)
          : EmptyStringNotation.formatMarkers(context, value);
    } else {
      return value.toString();
    }
  }

  /// Gets a short label for the algorithm type
  String _getAlgorithmTypeLabel(AlgorithmType type) {
    switch (type) {
      case AlgorithmType.nfaToDfa:
        return 'NFA→DFA';
      case AlgorithmType.dfaMinimization:
        return 'Minimize';
      case AlgorithmType.faToRegex:
        return 'FA→Regex';
      case AlgorithmType.regexToNfa:
        return 'Regex→NFA';
      case AlgorithmType.cykParsing:
        return 'CYK Parse';
      case AlgorithmType.regexSimplification:
        return 'Simplify';
      case AlgorithmType.fsaConcatenation:
        return 'Concatenate';
      case AlgorithmType.fsaKleeneStar:
        return 'Kleene Star';
      case AlgorithmType.fsaReversal:
        return 'Reverse';
    }
  }
}

StructuredMessage? _structuredMessageProperty(AlgorithmStep step, String key) {
  final raw = step.properties[key];
  if (raw is! Map) return null;
  try {
    return StructuredMessage.fromJson(Map<String, Object?>.from(raw));
  } on FormatException {
    return null;
  } on ArgumentError {
    return null;
  }
}
