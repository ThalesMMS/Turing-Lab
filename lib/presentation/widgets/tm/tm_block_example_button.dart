import 'package:flutter/material.dart';

import '../../content/example_suggested_simulations.dart';
import '../../content/tm_block_example_content_copy.dart';
import '../example_suggested_simulations_text.dart';

final class TMBlockExampleButton extends StatelessWidget {
  const TMBlockExampleButton({
    super.key,
    required this.copy,
    required this.isLoading,
    required this.onPressed,
    this.onUseInput,
  });

  final TMBlockExampleContentCopy copy;
  final bool isLoading;
  final VoidCallback? onPressed;

  /// Fills the TM simulation field with a suggested input.
  final ValueChanged<String>? onUseInput;

  @override
  Widget build(BuildContext context) {
    final suggestions = ExampleSuggestedSimulations.resolve(
      TMBlockExampleContentCopies.id,
    );
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final onUseInput = this.onUseInput;
    final inlineSuggestions = onUseInput == null;

    final button = Semantics(
      button: true,
      enabled: onPressed != null,
      label: [
        copy.semanticLabel,
        if (inlineSuggestions)
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
                  const Icon(Icons.account_tree_outlined, size: 20),
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
                      if (inlineSuggestions) ...[
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
    if (inlineSuggestions || suggestions.isEmpty) return button;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        button,
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
          child: ExampleSuggestedSimulationsText(
            suggestions: suggestions,
            exampleId: TMBlockExampleContentCopies.id,
            onUseInput: onPressed == null ? null : onUseInput,
          ),
        ),
      ],
    );
  }
}
