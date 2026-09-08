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
    this.counterexamples = const [],
    this.exampleId,
    required this.isLoading,
    required this.onPressed,
    this.onUseInput,
  });

  final AssetExampleContentCopy copy;
  final List<String> suggestions;
  final List<ExampleSuggestedSimulation> counterexamples;
  final String? exampleId;
  final bool isLoading;
  final VoidCallback? onPressed;

  /// Fills the workspace simulation field with a suggested input. When set,
  /// suggestions render as actions below the button instead of plain text.
  final ValueChanged<String>? onUseInput;

  static Widget? maybeBuild<T>({
    required BuildContext context,
    required AssetExample<T> example,
    required bool isLoading,
    required VoidCallback? onPressed,
    ValueChanged<String>? onUseInput,
  }) {
    final copy = AssetExampleContentCopies.maybeResolve(
      id: example.id,
      languageCode: Localizations.localeOf(context).languageCode,
    );
    if (copy == null) return null;
    return AssetExampleContentButton(
      copy: copy,
      suggestions: ExampleSuggestedSimulations.resolve(example.id),
      counterexamples: ExampleCounterexamples.resolve(example.id),
      exampleId: example.id,
      isLoading: isLoading,
      onPressed: onPressed,
      onUseInput: onUseInput,
    );
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final onUseInput = this.onUseInput;
    final inlineSuggestions = onUseInput == null;

    final button = Semantics(
      button: true,
      enabled: onPressed != null,
      label: [
        copy.semanticLabel,
        if (inlineSuggestions && suggestions.isNotEmpty)
          ExampleSuggestedSimulationsText.semanticLabel(
            context,
            suggestions,
            counterexamples: counterexamples,
          ),
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
                      if (inlineSuggestions && suggestions.isNotEmpty) ...[
                        const SizedBox(height: 8),
                        ExampleSuggestedSimulationsText(
                          suggestions: suggestions,
                          counterexamples: counterexamples,
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
    if (inlineSuggestions || suggestions.isEmpty) return button;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        button,
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
          child: ExampleSuggestedSimulationsText(
            suggestions: suggestions,
            counterexamples: counterexamples,
            exampleId: exampleId,
            onUseInput: onPressed == null ? null : onUseInput,
          ),
        ),
      ],
    );
  }
}
