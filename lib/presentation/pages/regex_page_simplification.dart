part of 'regex_page.dart';

extension _RegexPageSimplificationSections on _RegexPageState {
  Widget _buildSimplificationStepsSection() {
    final l10n = AppLocalizations.of(context);
    final regexState = ref.watch(regexEditorProvider);
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header with title and action buttons
            Row(
              children: [
                Icon(Icons.auto_fix_high, color: colorScheme.primary, size: 24),
                const SizedBox(width: 8),
                Text(
                  l10n.simplificationSteps,
                  style: textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Spacer(),
                if (regexState.simplificationResult != null)
                  IconButton(
                    onPressed: () => ref
                        .read(regexEditorProvider.notifier)
                        .toggleSimplificationSteps(),
                    icon: Icon(
                      regexState.showSimplificationSteps
                          ? Icons.expand_less
                          : Icons.expand_more,
                    ),
                    tooltip: regexState.showSimplificationSteps
                        ? l10n.hideSteps
                        : l10n.showSteps,
                  ),
              ],
            ),
            const SizedBox(height: 12),

            // Simplify button
            if (regexState.simplificationResult == null)
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: _runSimplificationWithSteps,
                  icon: const Icon(Icons.auto_fix_high),
                  label: Text(l10n.simplifyWithSteps),
                ),
              )
            else ...[
              // Summary section
              _buildSimplificationSummary(),
              const SizedBox(height: 12),

              // Expandable steps list
              if (regexState.showSimplificationSteps) ...[
                const Divider(),
                const SizedBox(height: 8),
                _buildStepsList(),
              ],

              // Actions
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton.icon(
                    onPressed: () => ref
                        .read(regexEditorProvider.notifier)
                        .clearSimplification(),
                    icon: const Icon(Icons.refresh, size: 18),
                    label: Text(l10n.clear),
                  ),
                  const SizedBox(width: 8),
                  ElevatedButton.icon(
                    onPressed: _runSimplificationWithSteps,
                    icon: const Icon(Icons.auto_fix_high, size: 18),
                    label: Text(l10n.resimplify),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  /// Builds the simplification summary showing original vs simplified
  Widget _buildSimplificationSummary() {
    final result = ref.watch(regexEditorProvider).simplificationResult;
    if (result == null) return const SizedBox.shrink();

    final l10n = AppLocalizations.of(context);
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: colorScheme.outline.withValues(alpha: 0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Original regex
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(
                width: 80,
                child: Text(
                  l10n.originalLabel,
                  style: textTheme.bodySmall?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
              ),
              Expanded(
                child: SelectableText(
                  result.originalRegex,
                  style: textTheme.bodyMedium?.copyWith(
                    fontFamily: 'monospace',
                    color: colorScheme.onSurface,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),

          // Arrow indicating transformation
          Row(
            children: [
              const SizedBox(width: 80),
              Icon(Icons.arrow_downward, size: 16, color: colorScheme.primary),
              const SizedBox(width: 4),
              Text(
                '${result.totalRulesApplied} ${l10n.rulesAppliedLabel}',
                style: textTheme.bodySmall?.copyWith(
                  color: colorScheme.primary,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),

          // Simplified regex
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(
                width: 80,
                child: Text(
                  l10n.simplifiedLabel,
                  style: textTheme.bodySmall?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
              ),
              Expanded(
                child: SelectableText(
                  result.simplifiedRegex,
                  style: textTheme.bodyMedium?.copyWith(
                    fontFamily: 'monospace',
                    color: result.madeProgress
                        ? colorScheme.primary
                        : colorScheme.onSurface,
                    fontWeight: result.madeProgress
                        ? FontWeight.bold
                        : FontWeight.normal,
                  ),
                ),
              ),
              if (result.madeProgress)
                IconButton(
                  onPressed: () async {
                    try {
                      await Clipboard.setData(
                        ClipboardData(text: result.simplifiedRegex),
                      );
                    } catch (error) {
                      debugPrint('Failed to copy simplified regex: $error');
                      return;
                    }
                    if (!mounted) return;
                    _showFeedback(
                      l10n.simplifiedRegexCopiedToClipboard,
                      tone: AppSnackBarTone.success,
                    );
                  },
                  icon: const Icon(Icons.copy, size: 18),
                  tooltip: l10n.copySimplifiedRegex,
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                ),
            ],
          ),

          // Stats
          if (result.madeProgress) ...[
            const SizedBox(height: 12),
            Wrap(
              spacing: 16,
              runSpacing: 8,
              children: [
                _buildStatChip(
                  l10n.saved,
                  '${result.charactersSaved} ${l10n.charactersAbbreviation}',
                  Icons.compress,
                  colorScheme.tertiary,
                ),
                _buildStatChip(
                  l10n.reduction,
                  '${result.reductionPercentage.toStringAsFixed(1)}%',
                  Icons.trending_down,
                  colorScheme.secondary,
                ),
                _buildStatChip(
                  l10n.time,
                  '${result.executionTimeMs}ms',
                  Icons.timer_outlined,
                  colorScheme.primary,
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  /// Builds a small stat chip widget
  Widget _buildStatChip(
    String label,
    String value,
    IconData icon,
    Color color,
  ) {
    final textTheme = Theme.of(context).textTheme;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 4),
          Text(
            '$label: $value',
            style: textTheme.labelSmall?.copyWith(
              color: color,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  /// Builds the list of simplification steps
  Widget _buildStepsList() {
    final regexState = ref.watch(regexEditorProvider);
    final result = regexState.simplificationResult;
    if (result == null) return const SizedBox.shrink();

    final l10n = AppLocalizations.of(context);
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Step navigation
        if (result.steps.length > 1) ...[
          Row(
            children: [
              Text(
                '${l10n.stepLabel} ${regexState.selectedStepIndex + 1} '
                '${l10n.ofLabel} ${result.steps.length}',
                style: textTheme.labelMedium?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
              const Spacer(),
              IconButton(
                onPressed: regexState.selectedStepIndex > 0
                    ? () => ref
                        .read(regexEditorProvider.notifier)
                        .setSelectedStepIndex(regexState.selectedStepIndex - 1)
                    : null,
                icon: const Icon(Icons.chevron_left),
                tooltip: l10n.previousStep,
              ),
              IconButton(
                onPressed: regexState.selectedStepIndex <
                        result.steps.length - 1
                    ? () => ref
                        .read(regexEditorProvider.notifier)
                        .setSelectedStepIndex(regexState.selectedStepIndex + 1)
                    : null,
                icon: const Icon(Icons.chevron_right),
                tooltip: l10n.nextStep,
              ),
            ],
          ),
          const SizedBox(height: 8),
        ],

        // Current step detail
        if (result.steps.isNotEmpty)
          _buildStepCard(result.steps[regexState.selectedStepIndex]),

        const SizedBox(height: 12),

        // Step timeline
        Text(
          l10n.allSteps,
          style: textTheme.labelMedium?.copyWith(
            fontWeight: FontWeight.bold,
            color: colorScheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: 8),
        if (result.steps.isNotEmpty)
          SizedBox(
            height:
                result.steps.length <= 4 ? result.steps.length * 88.0 : 360.0,
            child: ListView.builder(
              itemCount: result.steps.length,
              itemBuilder: (context, index) {
                final step = result.steps[index];
                final isSelected = index == regexState.selectedStepIndex;
                return _buildStepTimelineItem(step, index, isSelected);
              },
            ),
          ),
      ],
    );
  }

  /// Builds a detailed card for a single step
  Widget _buildStepCard(RegexSimplificationStep step) {
    final l10n = AppLocalizations.of(context);
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: colorScheme.primaryContainer.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: colorScheme.primary.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Step header
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: colorScheme.primary,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  '${l10n.stepLabel} ${step.stepNumber}',
                  style: textTheme.labelSmall?.copyWith(
                    color: colorScheme.onPrimary,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  step.title,
                  style: textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              // Step type badge
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: colorScheme.secondaryContainer.withValues(alpha: 0.5),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  step.stepType.displayName,
                  style: textTheme.labelSmall?.copyWith(
                    color: colorScheme.onSecondaryContainer,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Explanation
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(Icons.info_outline, size: 16, color: colorScheme.primary),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    step.explanation,
                    style: textTheme.bodySmall?.copyWith(height: 1.4),
                  ),
                ),
              ],
            ),
          ),

          // Rule application details
          if (step.appliesRule && step.ruleApplied != null) ...[
            const SizedBox(height: 12),
            _buildRuleApplicationDetails(step),
          ],

          // Complexity metrics
          if (step.starHeight != null ||
              step.nestingDepth != null ||
              step.operatorCount != null) ...[
            const SizedBox(height: 12),
            _buildComplexityMetrics(step),
          ],
        ],
      ),
    );
  }

  /// Builds the rule application details section
  Widget _buildRuleApplicationDetails(RegexSimplificationStep step) {
    final l10n = AppLocalizations.of(context);
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: colorScheme.tertiaryContainer.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: colorScheme.tertiary.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.auto_fix_high, size: 16, color: colorScheme.tertiary),
              const SizedBox(width: 8),
              Text(
                l10n.transformation,
                style: textTheme.labelMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: colorScheme.tertiary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),

          // Before -> After display
          Row(
            children: [
              Expanded(
                child: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: colorScheme.errorContainer.withValues(alpha: 0.3),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        l10n.before,
                        style: textTheme.labelSmall?.copyWith(
                          color: colorScheme.onErrorContainer,
                        ),
                      ),
                      const SizedBox(height: 4),
                      SelectableText(
                        step.matchedSubexpression ?? step.originalRegex ?? '',
                        style: textTheme.bodySmall?.copyWith(
                          fontFamily: 'monospace',
                          color: colorScheme.onErrorContainer,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8),
                child: Icon(
                  Icons.arrow_forward,
                  size: 20,
                  color: colorScheme.tertiary,
                ),
              ),
              Expanded(
                child: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: colorScheme.primaryContainer.withValues(alpha: 0.5),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        l10n.after,
                        style: textTheme.labelSmall?.copyWith(
                          color: colorScheme.onPrimaryContainer,
                        ),
                      ),
                      const SizedBox(height: 4),
                      SelectableText(
                        step.replacementSubexpression ??
                            step.simplifiedRegex ??
                            '',
                        style: textTheme.bodySmall?.copyWith(
                          fontFamily: 'monospace',
                          color: colorScheme.onPrimaryContainer,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),

          // Rule formal notation
          if (step.ruleApplied != null) ...[
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: colorScheme.surface,
                borderRadius: BorderRadius.circular(4),
                border: Border.all(
                  color: colorScheme.outline.withValues(alpha: 0.2),
                ),
              ),
              child: Text(
                '${l10n.rule}: ${step.ruleApplied!.formalNotation}',
                style: textTheme.labelSmall?.copyWith(
                  fontFamily: 'monospace',
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  /// Builds the complexity metrics section
  Widget _buildComplexityMetrics(RegexSimplificationStep step) {
    final l10n = AppLocalizations.of(context);
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Wrap(
      spacing: 12,
      runSpacing: 8,
      children: [
        if (step.starHeight != null)
          _buildMetricBadge(
            l10n.starHeight,
            step.starHeight.toString(),
            Icons.star_outline,
            colorScheme,
            textTheme,
          ),
        if (step.nestingDepth != null)
          _buildMetricBadge(
            l10n.nestingDepth,
            step.nestingDepth.toString(),
            Icons.layers_outlined,
            colorScheme,
            textTheme,
          ),
        if (step.operatorCount != null)
          _buildMetricBadge(
            l10n.operators,
            step.operatorCount.toString(),
            Icons.functions,
            colorScheme,
            textTheme,
          ),
      ],
    );
  }

  /// Builds a metric badge widget
  Widget _buildMetricBadge(
    String label,
    String value,
    IconData icon,
    ColorScheme colorScheme,
    TextTheme textTheme,
  ) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: colorScheme.onSurfaceVariant),
          const SizedBox(width: 4),
          Text(
            '$label: ',
            style: textTheme.labelSmall?.copyWith(
              color: colorScheme.onSurfaceVariant,
            ),
          ),
          Text(
            value,
            style: textTheme.labelSmall?.copyWith(
              fontWeight: FontWeight.bold,
              color: colorScheme.onSurface,
            ),
          ),
        ],
      ),
    );
  }

  /// Builds a timeline item for a step
  Widget _buildStepTimelineItem(
    RegexSimplificationStep step,
    int index,
    bool isSelected,
  ) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return InkWell(
      onTap: () =>
          ref.read(regexEditorProvider.notifier).setSelectedStepIndex(index),
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        margin: const EdgeInsets.only(bottom: 4),
        decoration: BoxDecoration(
          color: isSelected
              ? colorScheme.primaryContainer.withValues(alpha: 0.3)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
          border: isSelected
              ? Border.all(color: colorScheme.primary.withValues(alpha: 0.5))
              : null,
        ),
        child: Row(
          children: [
            // Step number circle
            Container(
              width: 24,
              height: 24,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: isSelected
                    ? colorScheme.primary
                    : colorScheme.surfaceContainerHighest,
              ),
              child: Center(
                child: Text(
                  '${step.stepNumber}',
                  style: textTheme.labelSmall?.copyWith(
                    color: isSelected
                        ? colorScheme.onPrimary
                        : colorScheme.onSurfaceVariant,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),

            // Step title
            Expanded(
              child: Text(
                step.title,
                style: textTheme.bodySmall?.copyWith(
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                  color: isSelected
                      ? colorScheme.onSurface
                      : colorScheme.onSurfaceVariant,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),

            // Rule indicator for applyRule steps
            if (step.appliesRule && step.ruleApplied != null)
              Flexible(
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: colorScheme.tertiaryContainer.withValues(alpha: 0.5),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    step.ruleApplied!.formalNotation,
                    style: textTheme.labelSmall?.copyWith(
                      fontFamily: 'monospace',
                      fontSize: 10,
                      color: colorScheme.onTertiaryContainer,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
