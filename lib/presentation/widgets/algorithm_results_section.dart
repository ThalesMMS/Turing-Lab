import 'package:flutter/material.dart';

import '../../l10n/app_localizations_resolver.dart';
import '../../l10n/app_localizations_workflows.dart';

class AlgorithmResultsSection extends StatelessWidget {
  const AlgorithmResultsSection({
    super.key,
    required this.hasResults,
    required this.emptyBuilder,
    required this.resultsBuilder,
    this.title = 'Analysis Results',
  });

  final bool hasResults;
  final WidgetBuilder emptyBuilder;
  final WidgetBuilder resultsBuilder;
  final String title;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          appLocalizationsOf(context).localizeWorkflowText(title),
          style: Theme.of(
            context,
          ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 8),
        if (hasResults) resultsBuilder(context) else emptyBuilder(context),
      ],
    );
  }
}
