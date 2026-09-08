//
//  grammar_transformation_section.dart
//  Turing Lab
//
//  Normal-form, recursion, factoring and LL(1) analysis actions of the grammar
//  editor. Presentational only: the panel runs the analyses and owns results.
//

import 'package:flutter/material.dart';

import '../../../l10n/app_localizations_resolver.dart';
import '../../../l10n/app_localizations_workflows.dart';
import '../common/algorithm_button.dart';
import '../common/algorithm_button_config.dart';

class GrammarTransformationSection extends StatelessWidget {
  const GrammarTransformationSection({
    super.key,
    required this.isAnalyzing,
    required this.hasProductions,
    required this.onConvertToCnf,
    required this.onOpenNormalizationTeaching,
    required this.onConvertToGnf,
    required this.onRemoveLeftRecursion,
    required this.onLeftFactor,
    required this.onFindFirstSets,
    required this.onFindFollowSets,
    required this.onBuildParseTable,
    required this.onCheckAmbiguity,
  });

  final bool isAnalyzing;
  final bool hasProductions;
  final VoidCallback onConvertToCnf;
  final VoidCallback onOpenNormalizationTeaching;
  final VoidCallback onConvertToGnf;
  final VoidCallback onRemoveLeftRecursion;
  final VoidCallback onLeftFactor;
  final VoidCallback onFindFirstSets;
  final VoidCallback onFindFollowSets;
  final VoidCallback onBuildParseTable;
  final VoidCallback onCheckAmbiguity;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        AlgorithmButton.fromConfig(
          AlgorithmButtonConfig(
            title: appLocalizationsOf(context).convertToCnfTitle,
            description: appLocalizationsOf(context).convertToCnfDescription,
            icon: Icons.filter_list,
            isEnabled: !isAnalyzing,
            isExecuting: isAnalyzing,
            onPressed: onConvertToCnf,
          ),
        ),
        const SizedBox(height: 12),
        AlgorithmButton.fromConfig(
          AlgorithmButtonConfig(
            title: appLocalizationsOf(
              context,
            ).localizeWorkflowText('Practice grammar normalization'),
            description: appLocalizationsOf(context).localizeWorkflowText(
              'Propose lambda, unit, useless-production, and CNF steps and check each hypothesis.',
            ),
            icon: Icons.school_outlined,
            isEnabled: !isAnalyzing && hasProductions,
            onPressed: onOpenNormalizationTeaching,
          ),
          key: const ValueKey('open-normalization-teaching'),
        ),
        const SizedBox(height: 12),
        AlgorithmButton.fromConfig(
          AlgorithmButtonConfig(
            title: appLocalizationsOf(context).convertToGnfTitle,
            description: appLocalizationsOf(context).convertToGnfDescription,
            icon: Icons.format_list_numbered,
            isEnabled: !isAnalyzing,
            isExecuting: isAnalyzing,
            onPressed: onConvertToGnf,
          ),
        ),
        const SizedBox(height: 12),
        AlgorithmButton.fromConfig(
          AlgorithmButtonConfig(
            title: appLocalizationsOf(context).removeLeftRecursionTitle,
            description: appLocalizationsOf(
              context,
            ).removeLeftRecursionDescription,
            icon: Icons.transform,
            isEnabled: !isAnalyzing,
            isExecuting: isAnalyzing,
            onPressed: onRemoveLeftRecursion,
          ),
        ),
        const SizedBox(height: 12),
        AlgorithmButton.fromConfig(
          AlgorithmButtonConfig(
            title: appLocalizationsOf(context).leftFactorTitle,
            description: appLocalizationsOf(context).leftFactorDescription,
            icon: Icons.account_tree,
            isEnabled: !isAnalyzing,
            isExecuting: isAnalyzing,
            onPressed: onLeftFactor,
          ),
        ),
        const SizedBox(height: 12),
        AlgorithmButton.fromConfig(
          AlgorithmButtonConfig(
            title: appLocalizationsOf(context).findFirstSetsTitle,
            description: appLocalizationsOf(context).findFirstSetsDescription,
            icon: Icons.first_page,
            isEnabled: !isAnalyzing,
            isExecuting: isAnalyzing,
            onPressed: onFindFirstSets,
          ),
        ),
        const SizedBox(height: 12),
        AlgorithmButton.fromConfig(
          AlgorithmButtonConfig(
            title: appLocalizationsOf(context).findFollowSetsTitle,
            description: appLocalizationsOf(context).findFollowSetsDescription,
            icon: Icons.last_page,
            isEnabled: !isAnalyzing,
            isExecuting: isAnalyzing,
            onPressed: onFindFollowSets,
          ),
        ),
        const SizedBox(height: 12),
        AlgorithmButton.fromConfig(
          AlgorithmButtonConfig(
            title: appLocalizationsOf(context).buildParseTableTitle,
            description: appLocalizationsOf(context).buildParseTableDescription,
            icon: Icons.table_chart,
            isEnabled: !isAnalyzing,
            isExecuting: isAnalyzing,
            onPressed: onBuildParseTable,
          ),
        ),
        const SizedBox(height: 12),
        AlgorithmButton.fromConfig(
          AlgorithmButtonConfig(
            title: appLocalizationsOf(context).checkAmbiguityTitle,
            description: appLocalizationsOf(context).checkAmbiguityDescription,
            icon: Icons.rule,
            isEnabled: !isAnalyzing,
            isExecuting: isAnalyzing,
            onPressed: onCheckAmbiguity,
          ),
        ),
      ],
    );
  }
}
