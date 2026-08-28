import 'package:flutter/material.dart';

import '../../core/models/asset_example.dart';
import '../content/asset_example_content_copy.dart';
import '../content/example_suggested_simulations.dart';
import 'example_suggested_simulations_text.dart';

final class AssetExampleContentButton extends StatelessWidget {
  const AssetExampleContentButton({
    super.key,
    required this.copy,
    required this.suggestions,
    required this.isLoading,
    required this.onPressed,
  });

  final AssetExampleContentCopy copy;
  final List<String> suggestions;
  final bool isLoading;
  final VoidCallback? onPressed;

  static Widget? maybeBuild<T>({
    required BuildContext context,
    required AssetExample<T> example,
    required bool isLoading,
    required VoidCallback? onPressed,
  }) {
    final copy = AssetExampleContentCopies.maybeResolve(
      id: example.id,
      languageCode: Localizations.localeOf(context).languageCode,
    );
    if (copy == null) return null;
    return AssetExampleContentButton(
      copy: copy,
      suggestions: ExampleSuggestedSimulations.resolve(example.id),
      isLoading: isLoading,
      onPressed: onPressed,
    );
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Semantics(
      button: true,
      enabled: onPressed != null,
      label: [
        copy.semanticLabel,
        if (suggestions.isNotEmpty)
          ExampleSuggestedSimulationsText.semanticLabel(context, suggestions),
      ].join(' '),
      onTap: onPressed,
      child: ExcludeSemantics(
        child: SizedBox(
          width: double.infinity,
          child: OutlinedButton(
            onPressed: onPressed,
            style: OutlinedButton.styleFrom(
              foregroundColor: colorScheme.secondary,
              side: BorderSide(
                color: colorScheme.secondary.withValues(alpha: 0.5),
              ),
              padding: const EdgeInsets.all(16),
              alignment: AlignmentDirectional.centerStart,
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (isLoading)
                  const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                else
                  const Icon(Icons.school_outlined, size: 20),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        copy.title,
                        style: textTheme.titleSmall?.copyWith(
                          color: colorScheme.secondary,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        [
                          copy.summary,
                          copy.learningObjective,
                          copy.limitation,
                        ].join('\n'),
                        style: textTheme.bodySmall,
                      ),
                      if (suggestions.isNotEmpty) ...[
                        const SizedBox(height: 8),
                        ExampleSuggestedSimulationsText(
                          suggestions: suggestions,
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
