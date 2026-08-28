import 'package:flutter/material.dart';

import '../../core/result.dart';
import '../../core/models/asset_example.dart';
import '../../l10n/app_localizations_resolver.dart';
import '../../l10n/app_localizations_workflows.dart';
import 'algorithm_example_button.dart';

class AlgorithmExamplesSection<T> extends StatelessWidget {
  const AlgorithmExamplesSection({
    super.key,
    required this.examplesFuture,
    required this.loadingExampleName,
    required this.onExampleSelected,
    required this.failureMessage,
    required this.emptyMessage,
    this.title = 'Load Examples',
    this.exampleBuilder,
  });

  final Future<ListResult<AssetExample<T>>> examplesFuture;
  final String? loadingExampleName;
  final ValueChanged<String> onExampleSelected;
  final String failureMessage;
  final String emptyMessage;
  final String title;
  final Widget? Function(
    BuildContext context,
    AssetExample<T> example,
    bool isLoading,
    VoidCallback? onPressed,
  )?
  exampleBuilder;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = appLocalizationsOf(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(Icons.lightbulb_outline, color: theme.colorScheme.secondary),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                l10n.localizeWorkflowText(title),
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        FutureBuilder<ListResult<AssetExample<T>>>(
          future: examplesFuture,
          builder: (context, snapshot) {
            if (snapshot.connectionState != ConnectionState.done) {
              return Semantics(
                liveRegion: true,
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  child: Row(
                    children: [
                      const Icon(Icons.hourglass_top, size: 20),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          l10n.localizeWorkflowText('Loading examples...'),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }

            final result = snapshot.data;
            if (result == null || result.isFailure) {
              return Text(
                l10n.localizeWorkflowText(result?.error ?? failureMessage),
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.error,
                ),
              );
            }

            final examples = result.data!;
            if (examples.isEmpty) {
              return Text(
                l10n.localizeWorkflowText(emptyMessage),
                style: theme.textTheme.bodySmall,
              );
            }

            return Column(
              children: examples.map((example) {
                final isLoading = loadingExampleName == example.name;
                final onPressed = loadingExampleName == null
                    ? () => onExampleSelected(example.name)
                    : null;
                return Padding(
                  key: ValueKey<String>('algorithm-example-${example.name}'),
                  padding: const EdgeInsets.only(bottom: 8),
                  child:
                      exampleBuilder?.call(
                        context,
                        example,
                        isLoading,
                        onPressed,
                      ) ??
                      AlgorithmExampleButton(
                        title: l10n.localizedExampleName(example.name),
                        isLoading: isLoading,
                        onPressed: onPressed,
                      ),
                );
              }).toList(),
            );
          },
        ),
      ],
    );
  }
}
