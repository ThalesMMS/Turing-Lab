part of 'regex_page.dart';

extension _RegexPageComplexitySections on _RegexPageState {
  Widget _buildComplexityAnalysisSection() {
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
                Icon(
                  Icons.analytics_outlined,
                  color: colorScheme.primary,
                  size: 24,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    AppLocalizations.of(context).complexityAnalysisTitle,
                    style: textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                if (regexState.regexAnalysis != null)
                  IconButton(
                    onPressed: () => ref
                        .read(regexEditorProvider.notifier)
                        .toggleAnalysisDetails(),
                    icon: Icon(
                      regexState.showAnalysisDetails
                          ? Icons.expand_less
                          : Icons.expand_more,
                    ),
                    tooltip: regexState.showAnalysisDetails
                        ? AppLocalizations.of(context).hideDetails
                        : AppLocalizations.of(context).showDetails,
                  ),
              ],
            ),
            const SizedBox(height: 12),

            // Analyze button
            if (regexState.regexAnalysis == null)
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: _runComplexityAnalysis,
                  icon: const Icon(Icons.analytics_outlined),
                  label: Text(AppLocalizations.of(context).analyzeComplexity),
                ),
              )
            else ...[
              // Analysis summary with complexity level
              _buildComplexityLevelIndicator(),
              const SizedBox(height: 12),

              // Expandable details
              if (regexState.showAnalysisDetails) ...[
                const Divider(),
                const SizedBox(height: 8),
                _buildComplexityDetails(),
              ],

              // Actions
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton.icon(
                    onPressed: () => ref
                        .read(regexEditorProvider.notifier)
                        .clearComplexityAnalysis(),
                    icon: const Icon(Icons.refresh, size: 18),
                    label: Text(AppLocalizations.of(context).clear),
                  ),
                  const SizedBox(width: 8),
                  ElevatedButton.icon(
                    onPressed: _runComplexityAnalysis,
                    icon: const Icon(Icons.analytics_outlined, size: 18),
                    label: Text(AppLocalizations.of(context).reanalyze),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  /// Builds the complexity level indicator with color coding
  Widget _buildComplexityLevelIndicator() {
    final analysis = ref.watch(regexEditorProvider).regexAnalysis;
    if (analysis == null) return const SizedBox.shrink();

    final complexityColors = _getComplexityColors(
      context,
      analysis.complexityLevel,
    );
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    final levelIcon = _getComplexityIcon(analysis.complexityLevel);

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: complexityColors.background.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: complexityColors.background.withValues(alpha: 0.3),
        ),
      ),
      child: Row(
        children: [
          // Complexity level badge
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: complexityColors.background,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(levelIcon, size: 16, color: complexityColors.foreground),
                const SizedBox(width: 6),
                Text(
                  _complexityLevelName(
                    analysis.complexityLevel,
                    AppLocalizations.of(context),
                  ),
                  style: textTheme.labelMedium?.copyWith(
                    color: complexityColors.foreground,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 16),

          // Key metrics summary
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _complexityLevelDescription(
                    analysis.complexityLevel,
                    AppLocalizations.of(context),
                  ),
                  style: textTheme.bodySmall?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 4),
                Wrap(
                  spacing: 12,
                  runSpacing: 4,
                  children: [
                    _buildMiniMetric(
                      AppLocalizations.of(context).starHeight,
                      analysis.starHeight.toString(),
                      Icons.star_outline,
                    ),
                    _buildMiniMetric(
                      AppLocalizations.of(context).nestingShort,
                      analysis.nestingDepth.toString(),
                      Icons.layers_outlined,
                    ),
                    _buildMiniMetric(
                      AppLocalizations.of(context).alphabetLabel,
                      analysis.alphabetSize.toString(),
                      Icons.abc,
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// Builds a mini metric display
  Widget _buildMiniMetric(String label, String value, IconData icon) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Row(
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
    );
  }

  /// Builds the detailed complexity analysis view
  Widget _buildComplexityDetails() {
    final analysis = ref.watch(regexEditorProvider).regexAnalysis;
    if (analysis == null) return const SizedBox.shrink();

    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Complexity metrics section
        Text(
          AppLocalizations.of(context).complexityMetrics,
          style: textTheme.labelLarge?.copyWith(
            fontWeight: FontWeight.bold,
            color: colorScheme.onSurface,
          ),
        ),
        const SizedBox(height: 8),
        _buildMetricRow(
          AppLocalizations.of(context).starHeight,
          analysis.starHeight.toString(),
          AppLocalizations.of(context).starHeightDescription,
          Icons.star_outline,
          colorScheme.primary,
        ),
        const SizedBox(height: 8),
        _buildMetricRow(
          AppLocalizations.of(context).nestingDepth,
          analysis.nestingDepth.toString(),
          AppLocalizations.of(context).nestingDepthDescription,
          Icons.layers_outlined,
          colorScheme.secondary,
        ),
        const SizedBox(height: 8),
        _buildMetricRow(
          AppLocalizations.of(context).complexityScore,
          analysis.complexityScore.toString(),
          AppLocalizations.of(context).complexityScoreDescription,
          Icons.speed,
          colorScheme.tertiary,
        ),

        const SizedBox(height: 16),

        // Operator breakdown section
        Text(
          AppLocalizations.of(context).operatorBreakdown,
          style: textTheme.labelLarge?.copyWith(
            fontWeight: FontWeight.bold,
            color: colorScheme.onSurface,
          ),
        ),
        const SizedBox(height: 8),
        _buildOperatorBreakdown(analysis),

        const SizedBox(height: 16),

        // Alphabet section
        Text(
          AppLocalizations.of(context).alphabetLabel,
          style: textTheme.labelLarge?.copyWith(
            fontWeight: FontWeight.bold,
            color: colorScheme.onSurface,
          ),
        ),
        const SizedBox(height: 8),
        _buildAlphabetDisplay(analysis),
      ],
    );
  }

  /// Builds a metric row with label, value, description, and icon
  Widget _buildMetricRow(
    String label,
    String value,
    String description,
    IconData icon,
    Color color,
  ) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Text(
                  description,
                  style: textTheme.bodySmall?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              value,
              style: textTheme.titleMedium?.copyWith(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Builds the operator breakdown display
  Widget _buildOperatorBreakdown(RegexAnalysis analysis) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final structure = analysis.structureAnalysis;

    final l10n = AppLocalizations.of(context);
    final operators = [
      (l10n.operatorUnion, structure.unionCount, Icons.call_split),
      (l10n.operatorConcatenation, structure.concatenationCount, Icons.link),
      (l10n.operatorKleeneStar, structure.starCount, Icons.star),
      (l10n.operatorPlus, structure.plusCount, Icons.add),
      (l10n.operatorOptional, structure.questionCount, Icons.help_outline),
    ];

    // Filter to only show operators that are used
    final usedOperators = operators.where((op) => op.$2 > 0).toList();

    if (usedOperators.isEmpty) {
      return Text(
        AppLocalizations.of(context).noOperatorsUsed,
        style: textTheme.bodySmall?.copyWith(
          color: colorScheme.onSurfaceVariant,
          fontStyle: FontStyle.italic,
        ),
      );
    }

    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: usedOperators.map((op) {
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          decoration: BoxDecoration(
            color: colorScheme.surfaceContainerHighest,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(op.$3, size: 14, color: colorScheme.primary),
              const SizedBox(width: 6),
              Text(
                op.$1,
                style: textTheme.labelSmall?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(width: 4),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: colorScheme.primary,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  '${op.$2}',
                  style: textTheme.labelSmall?.copyWith(
                    color: colorScheme.onPrimary,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }

  /// Builds the alphabet display
  Widget _buildAlphabetDisplay(RegexAnalysis analysis) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final alphabet = analysis.structureAnalysis.alphabet;

    if (alphabet.isEmpty) {
      return Text(
        AppLocalizations.of(context).emptyAlphabetExpression,
        style: textTheme.bodySmall?.copyWith(
          color: colorScheme.onSurfaceVariant,
          fontStyle: FontStyle.italic,
        ),
      );
    }

    // Sort alphabet for consistent display
    final sortedAlphabet = alphabet.toList()..sort();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          AppLocalizations.of(context).alphabetSizeCount(alphabet.length),
          style: textTheme.bodySmall?.copyWith(
            color: colorScheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: colorScheme.surfaceContainerHighest,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Wrap(
            spacing: 6,
            runSpacing: 6,
            children: sortedAlphabet.map((symbol) {
              return Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: colorScheme.primary.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(4),
                  border: Border.all(
                    color: colorScheme.primary.withValues(alpha: 0.3),
                  ),
                ),
                child: Text(
                  symbol,
                  style: textTheme.bodyMedium?.copyWith(
                    fontFamilyFallback: kMonospaceFontFamilyFallback,
                    fontWeight: FontWeight.bold,
                    color: colorScheme.primary,
                  ),
                ),
              );
            }).toList(),
          ),
        ),
      ],
    );
  }

  /// Gets the color for a complexity level
  _ComplexityColors _getComplexityColors(
    BuildContext context,
    ComplexityLevel level,
  ) {
    final colorScheme = Theme.of(context).colorScheme;

    switch (level) {
      case ComplexityLevel.simple:
        return _ComplexityColors(
          background: colorScheme.primary,
          foreground: colorScheme.onPrimary,
        );
      case ComplexityLevel.moderate:
        return _ComplexityColors(
          background: colorScheme.secondary,
          foreground: colorScheme.onSecondary,
        );
      case ComplexityLevel.complex:
        return _ComplexityColors(
          background: colorScheme.error,
          foreground: colorScheme.onError,
        );
    }
  }

  String _complexityLevelName(ComplexityLevel level, AppLocalizations l10n) {
    switch (level) {
      case ComplexityLevel.simple:
        return l10n.complexitySimple;
      case ComplexityLevel.moderate:
        return l10n.complexityModerate;
      case ComplexityLevel.complex:
        return l10n.complexityComplex;
    }
  }

  String _complexityLevelDescription(
    ComplexityLevel level,
    AppLocalizations l10n,
  ) {
    switch (level) {
      case ComplexityLevel.simple:
        return l10n.complexitySimpleDescription;
      case ComplexityLevel.moderate:
        return l10n.complexityModerateDescription;
      case ComplexityLevel.complex:
        return l10n.complexityComplexDescription;
    }
  }

  /// Gets the icon for a complexity level
  IconData _getComplexityIcon(ComplexityLevel level) {
    switch (level) {
      case ComplexityLevel.simple:
        return Icons.check_circle;
      case ComplexityLevel.moderate:
        return Icons.warning;
      case ComplexityLevel.complex:
        return Icons.error;
    }
  }
}
