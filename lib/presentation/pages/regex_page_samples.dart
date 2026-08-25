part of 'regex_page.dart';

extension _RegexPageSampleSections on _RegexPageState {
  Widget _buildSampleStringsSection() {
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
                  Icons.text_snippet_outlined,
                  color: colorScheme.primary,
                  size: 24,
                ),
                const SizedBox(width: 8),
                Text(
                  AppLocalizations.of(context).sampleStringsTitle,
                  style: textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Spacer(),
                if (regexState.sampleStrings != null)
                  IconButton(
                    onPressed: () => ref
                        .read(regexEditorProvider.notifier)
                        .toggleSampleStringsDetails(),
                    icon: Icon(
                      regexState.showSampleStringsDetails
                          ? Icons.expand_less
                          : Icons.expand_more,
                    ),
                    tooltip: regexState.showSampleStringsDetails
                        ? AppLocalizations.of(context).hideSamples
                        : AppLocalizations.of(context).showSamples,
                  ),
              ],
            ),
            const SizedBox(height: 12),

            // Generate button
            if (regexState.sampleStrings == null)
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: _runSampleGeneration,
                  icon: const Icon(Icons.text_snippet_outlined),
                  label:
                      Text(AppLocalizations.of(context).generateSampleStrings),
                ),
              )
            else ...[
              // Sample strings summary
              _buildSampleStringsSummary(),
              const SizedBox(height: 12),

              // Expandable samples list
              if (regexState.showSampleStringsDetails) ...[
                const Divider(),
                const SizedBox(height: 8),
                _buildSampleStringsList(),
              ],

              // Actions
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton.icon(
                    onPressed: () => ref
                        .read(regexEditorProvider.notifier)
                        .clearSampleStrings(),
                    icon: const Icon(Icons.refresh, size: 18),
                    label: Text(AppLocalizations.of(context).clear),
                  ),
                  const SizedBox(width: 8),
                  ElevatedButton.icon(
                    onPressed: () => _runSampleGeneration(maxSamples: 15),
                    icon: const Icon(Icons.add, size: 18),
                    label: Text(AppLocalizations.of(context).generateMore),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  /// Builds the sample strings summary showing key info
  Widget _buildSampleStringsSummary() {
    final samples = ref.watch(regexEditorProvider).sampleStrings;
    if (samples == null) return const SizedBox.shrink();

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
          // Summary row
          Row(
            children: [
              Icon(
                Icons.check_circle_outline,
                size: 20,
                color: colorScheme.primary,
              ),
              const SizedBox(width: 8),
              Text(
                AppLocalizations.of(context)
                    .sampleStringsGeneratedCount(samples.count),
                style: textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),

          // Info chips
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              if (samples.acceptsEmptyString)
                _buildInfoChip(
                  AppLocalizations.of(context).acceptsEpsilon,
                  Icons.check,
                  colorScheme.tertiary,
                ),
              if (samples.shortestString != null)
                _buildInfoChip(
                  AppLocalizations.of(context)
                      .shortestSample(_displayString(samples.shortestString!)),
                  Icons.short_text,
                  colorScheme.secondary,
                ),
            ],
          ),
        ],
      ),
    );
  }

  /// Builds an info chip widget
  Widget _buildInfoChip(String label, IconData icon, Color color) {
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
            label,
            style: textTheme.labelSmall?.copyWith(
              color: color,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  /// Builds the list of sample strings
  Widget _buildSampleStringsList() {
    final samples = ref.watch(regexEditorProvider).sampleStrings;
    if (samples == null || samples.samples.isEmpty) {
      return Center(
        child: Text(
          AppLocalizations.of(context).noSampleStringsGenerated,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
                fontStyle: FontStyle.italic,
              ),
        ),
      );
    }

    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          AppLocalizations.of(context).generatedSamples,
          style: textTheme.labelMedium?.copyWith(
            fontWeight: FontWeight.bold,
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
            spacing: 8,
            runSpacing: 8,
            children: samples.samples.map((sample) {
              return _buildSampleChip(sample);
            }).toList(),
          ),
        ),
        const SizedBox(height: 12),

        // Copy all button
        Align(
          alignment: Alignment.centerRight,
          child: TextButton.icon(
            onPressed: () async {
              final allSamples = samples.samples.join('\n');
              await _copyToClipboardExtracted(
                allSamples,
                AppLocalizations.of(context).allSamplesCopied,
              );
            },
            icon: const Icon(Icons.copy_all, size: 16),
            label: Text(AppLocalizations.of(context).copyAll),
          ),
        ),
      ],
    );
  }

  /// Builds a single sample string chip
  Widget _buildSampleChip(String sample) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final displayText = _displayString(sample);

    return InkWell(
      onTap: () async {
        await _copyToClipboardExtracted(
          sample,
          AppLocalizations.of(context).copiedQuoted(displayText),
        );
      },
      borderRadius: BorderRadius.circular(6),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: colorScheme.primaryContainer.withValues(alpha: 0.3),
          borderRadius: BorderRadius.circular(6),
          border: Border.all(color: colorScheme.primary.withValues(alpha: 0.3)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              '"$displayText"',
              style: textTheme.bodySmall?.copyWith(
                fontFamilyFallback: kMonospaceFontFamilyFallback,
                fontWeight: FontWeight.w500,
                color: colorScheme.onSurface,
              ),
            ),
            const SizedBox(width: 4),
            Icon(
              Icons.content_copy,
              size: 12,
              color: colorScheme.onSurfaceVariant.withValues(alpha: 0.6),
            ),
          ],
        ),
      ),
    );
  }

  /// Formats a string for display, showing special representations for empty/epsilon
  String _displayString(String s) {
    if (s.isEmpty) return 'ε';
    if (s.length > 20) return '${s.substring(0, 17)}...';
    return s;
  }

  Future<void> _copyToClipboardExtracted(
    String text,
    String successMessage,
  ) async {
    try {
      await Clipboard.setData(ClipboardData(text: text));
    } catch (error) {
      debugPrint('Failed to copy to clipboard: $error');
      if (!mounted) return;
      _showFeedback(
        AppLocalizations.of(context).failedToCopyClipboard,
        tone: AppSnackBarTone.error,
      );
      return;
    }
    if (!mounted) return;
    _showFeedback(
      successMessage,
      tone: AppSnackBarTone.success,
    );
  }
}
