import 'package:flutter/material.dart';

import '../../core/constants/monospace_typography.dart';
import '../../l10n/app_localizations_resolver.dart';

final class ExampleSuggestedSimulationsText extends StatelessWidget {
  const ExampleSuggestedSimulationsText({super.key, required this.suggestions});

  final List<String> suggestions;

  static String semanticLabel(BuildContext context, List<String> suggestions) =>
      appLocalizationsOf(context).exampleSuggestedSimulationSemantics(
        suggestions.length,
        suggestions.join(', '),
      );

  @override
  Widget build(BuildContext context) {
    final l10n = appLocalizationsOf(context);
    final textTheme = Theme.of(context).textTheme;
    return Text.rich(
      TextSpan(
        children: [
          TextSpan(
            text:
                '${l10n.exampleSuggestedSimulationLabel(suggestions.length)}: ',
            style: textTheme.bodySmall,
          ),
          TextSpan(
            text: suggestions.join(', '),
            style: textTheme.bodySmall?.copyWith(
              fontFamilyFallback: kMonospaceFontFamilyFallback,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
      semanticsLabel: semanticLabel(context, suggestions),
    );
  }
}
