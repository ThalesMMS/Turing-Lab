//
//  grammar_to_automata_section.dart
//  Turing Lab
//
//  Conversion actions from the grammar editor to finite and pushdown automata,
//  including the manual and LL/LR construction workspaces. Purely
//  presentational: the panel owns the conversions and their state.
//

import 'package:flutter/material.dart';

import '../../../core/algorithms/grammar_to_pda/cfg_to_pda.dart';
import '../../../core/models/grammar.dart';
import '../../../l10n/app_localizations_resolver.dart';
import '../../../l10n/app_localizations_structured_messages.dart';
import '../../../l10n/app_localizations_workflows.dart';
import '../../providers/grammar_provider.dart';
import '../common/algorithm_button.dart';
import '../common/algorithm_button_config.dart';

class GrammarToAutomataSection extends StatelessWidget {
  const GrammarToAutomataSection({
    super.key,
    required this.grammarState,
    required this.onConvertToFsa,
    required this.onOpenManualGrammarToFa,
    required this.onConvertToPdaGeneral,
    required this.onConvertToPdaStandard,
    required this.onConvertToPdaGreibach,
    required this.onOpenCfgToPdaConstruction,
  });

  final GrammarState grammarState;
  final VoidCallback onConvertToFsa;
  final VoidCallback onOpenManualGrammarToFa;
  final VoidCallback onConvertToPdaGeneral;
  final VoidCallback onConvertToPdaStandard;
  final VoidCallback onConvertToPdaGreibach;
  final void Function(CfgToPdaOrientation orientation)
  onOpenCfgToPdaConstruction;

  @override
  Widget build(BuildContext context) {
    final strings = appLocalizationsOf(context);
    final hasProductions = grammarState.productions.isNotEmpty;
    final isBusy = grammarState.isConverting;
    final isDisabled = isBusy || !hasProductions;
    final activeConversion = grammarState.activeConversion;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          appLocalizationsOf(context).localizeWorkflowText('Conversions'),
          style: Theme.of(
            context,
          ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 8),
        AlgorithmButton.fromConfig(
          AlgorithmButtonConfig(
            title: appLocalizationsOf(context).convertRightLinearToFsaTitle,
            description: appLocalizationsOf(
              context,
            ).convertRightLinearToFsaDescription,
            icon: Icons.sync_alt,
            isExecuting:
                isBusy &&
                activeConversion == GrammarConversionKind.grammarToFsa,
            isEnabled: !isDisabled,
            executionStatus: appLocalizationsOf(context).convertingToFsa,
            onPressed: onConvertToFsa,
          ),
        ),
        const SizedBox(height: 12),
        AlgorithmButton.fromConfig(
          AlgorithmButtonConfig(
            title: appLocalizationsOf(
              context,
            ).localizeWorkflowText('Practice Regular Grammar to FA'),
            description: appLocalizationsOf(context).localizeWorkflowText(
              'Map nonterminals and productions to an automaton with source provenance.',
            ),
            icon: Icons.school_outlined,
            isEnabled: !isBusy && grammarState.type == GrammarType.regular,
            onPressed: onOpenManualGrammarToFa,
          ),
        ),
        const SizedBox(height: 12),
        AlgorithmButton.fromConfig(
          AlgorithmButtonConfig(
            title: appLocalizationsOf(context).convertGrammarToPdaGeneralTitle,
            description: appLocalizationsOf(
              context,
            ).convertGrammarToPdaGeneralDescription,
            icon: Icons.auto_fix_high,
            isExecuting:
                isBusy &&
                activeConversion == GrammarConversionKind.grammarToPda,
            isEnabled: !isDisabled,
            executionStatus: appLocalizationsOf(context).convertingToPda,
            onPressed: onConvertToPdaGeneral,
          ),
        ),
        const SizedBox(height: 12),
        AlgorithmButton.fromConfig(
          AlgorithmButtonConfig(
            title: appLocalizationsOf(context).convertGrammarToPdaStandardTitle,
            description: appLocalizationsOf(
              context,
            ).convertGrammarToPdaStandardDescription,
            icon: Icons.layers,
            isExecuting:
                isBusy &&
                activeConversion == GrammarConversionKind.grammarToPdaStandard,
            isEnabled: !isDisabled,
            executionStatus: appLocalizationsOf(context).convertingStandard,
            onPressed: onConvertToPdaStandard,
          ),
        ),
        const SizedBox(height: 12),
        AlgorithmButton.fromConfig(
          AlgorithmButtonConfig(
            title: appLocalizationsOf(context).convertGrammarToPdaGreibachTitle,
            description: appLocalizationsOf(
              context,
            ).convertGrammarToPdaGreibachDescription,
            icon: Icons.stacked_bar_chart,
            isExecuting:
                isBusy &&
                activeConversion == GrammarConversionKind.grammarToPdaGreibach,
            isEnabled: !isDisabled,
            executionStatus: appLocalizationsOf(context).convertingGreibach,
            onPressed: onConvertToPdaGreibach,
          ),
        ),
        const SizedBox(height: 12),
        AlgorithmButton.fromConfig(
          AlgorithmButtonConfig(
            title: appLocalizationsOf(
              context,
            ).localizeWorkflowText('CFG to PDA (LL) construction'),
            description: appLocalizationsOf(context).localizeWorkflowText(
              'Preview a conflict-free top-down LL stack construction with provenance.',
            ),
            icon: Icons.vertical_align_bottom,
            isEnabled: !isDisabled,
            onPressed: () => onOpenCfgToPdaConstruction(CfgToPdaOrientation.ll),
          ),
          key: const ValueKey('open-cfg-to-pda-ll'),
        ),
        const SizedBox(height: 12),
        AlgorithmButton.fromConfig(
          AlgorithmButtonConfig(
            title: appLocalizationsOf(
              context,
            ).localizeWorkflowText('CFG to PDA (LR) construction'),
            description: appLocalizationsOf(context).localizeWorkflowText(
              'Preview conflict-free bottom-up shifts and reductions with LR item provenance.',
            ),
            icon: Icons.vertical_align_top,
            isEnabled: !isDisabled,
            onPressed: () => onOpenCfgToPdaConstruction(CfgToPdaOrientation.lr),
          ),
          key: const ValueKey('open-cfg-to-pda-lr'),
        ),
        if (!hasProductions)
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Text(
              appLocalizationsOf(context).addAtLeastOneProductionRule,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Theme.of(
                  context,
                ).colorScheme.onSurface.withValues(alpha: 0.7),
              ),
            ),
          ),
        if (grammarState.error != null)
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Text(
              grammarState.structuredError == null
                  ? strings.localizeWorkflowText(grammarState.error!)
                  : strings.resolveStructuredMessage(
                      grammarState.structuredError!,
                    ),
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Theme.of(context).colorScheme.error,
              ),
            ),
          ),
      ],
    );
  }
}
