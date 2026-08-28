import 'package:flutter/material.dart';

import '../../core/constants/help_topic_ids.dart';
import '../../core/formal_systems/formal_systems.dart';
import '../pages/fsa_page.dart';
import '../pages/grammar_page.dart';
import '../pages/mealy_page.dart';
import '../pages/moore_page.dart';
import '../pages/l_system_page.dart';
import '../pages/unrestricted_grammar_page.dart';
import '../pages/pda_page.dart';
import '../pages/pumping_lemma_page.dart';
import '../pages/regex_page.dart';
import '../pages/tm_page.dart';
import '../../core/transducers/transducers.dart';
import '../../core/l_systems/l_systems.dart';
import '../../core/grammar/phrase_structure/phrase_structure.dart';
import '../../core/pumping_lemma/pumping_lemma.dart';
import 'workspace_presentation_module.dart';
import 'workspace_quick_action.dart';

List<WorkspacePresentationModule> buildDefaultWorkspacePresentationModules(
  FormalSystemRegistry registry,
) {
  FormalSystemDescriptor descriptor(FormalSystemKey key) {
    final value = registry.descriptorFor(key);
    if (value == null) {
      throw StateError('Missing default formal-system descriptor: $key');
    }
    return value;
  }

  return List<WorkspacePresentationModule>.unmodifiable([
    WorkspacePresentationModule(
      descriptor: descriptor(DefaultFormalSystemIds.fsa),
      icon: Icons.account_tree,
      pageBuilder: (_) => const FSAPage(),
      helpTopicId: HelpTopicIds.fsaEditorOverview,
      navigationLabel: (l10n) => l10n.homeNavigationFsaLabel,
      navigationDescription: (l10n) => l10n.homeNavigationFsaDescription,
      quickActions: const {
        WorkspaceQuickAction.help,
        WorkspaceQuickAction.simulate,
        WorkspaceQuickAction.algorithms,
      },
      usesCanvasHighlight: true,
    ),
    WorkspacePresentationModule(
      descriptor: descriptor(DefaultFormalSystemIds.grammar),
      icon: Icons.text_fields,
      pageBuilder: (_) => const GrammarPage(),
      helpTopicId: HelpTopicIds.grammarEditorOverview,
      navigationLabel: (l10n) => l10n.homeNavigationGrammarLabel,
      navigationDescription: (l10n) => l10n.homeNavigationGrammarDescription,
      quickActions: const {
        WorkspaceQuickAction.help,
        WorkspaceQuickAction.simulate,
        WorkspaceQuickAction.algorithms,
        WorkspaceQuickAction.edit,
      },
    ),
    WorkspacePresentationModule(
      descriptor: descriptor(DefaultFormalSystemIds.pda),
      icon: Icons.storage,
      pageBuilder: (_) => const PDAPage(),
      helpTopicId: HelpTopicIds.pdaEditorOverview,
      navigationLabel: (l10n) => l10n.homeNavigationPdaLabel,
      navigationDescription: (l10n) => l10n.homeNavigationPdaDescription,
      quickActions: const {
        WorkspaceQuickAction.help,
        WorkspaceQuickAction.simulate,
        WorkspaceQuickAction.algorithms,
      },
      usesCanvasHighlight: true,
    ),
    WorkspacePresentationModule(
      descriptor: descriptor(DefaultFormalSystemIds.tm),
      icon: Icons.settings,
      pageBuilder: (_) => const TMPage(),
      helpTopicId: HelpTopicIds.tmEditorOverview,
      navigationLabel: (l10n) => l10n.homeNavigationTmLabel,
      navigationDescription: (l10n) => l10n.homeNavigationTmDescription,
      quickActions: const {
        WorkspaceQuickAction.help,
        WorkspaceQuickAction.simulate,
        WorkspaceQuickAction.algorithms,
        WorkspaceQuickAction.metrics,
      },
      usesCanvasHighlight: true,
    ),
    WorkspacePresentationModule(
      descriptor: descriptor(DefaultFormalSystemIds.regex),
      icon: Icons.pattern,
      pageBuilder: (_) => const RegexPage(),
      helpTopicId: HelpTopicIds.regexEditorOverview,
      navigationLabel: (l10n) => l10n.homeNavigationRegexLabel,
      navigationDescription: (l10n) => l10n.homeNavigationRegexDescription,
      quickActions: const {
        WorkspaceQuickAction.help,
        WorkspaceQuickAction.simulate,
        WorkspaceQuickAction.algorithms,
      },
    ),
    WorkspacePresentationModule(
      descriptor: descriptor(DefaultFormalSystemIds.regularPumping),
      icon: Icons.games,
      pageBuilder: (_) =>
          const PumpingLemmaPage(theorem: PumpingLemmaTheorem.regular),
      helpTopicId: HelpTopicIds.pumpingEditorOverview,
      navigationLabel: (l10n) => l10n.homeNavigationRegularPumpingLabel,
      navigationDescription: (l10n) =>
          l10n.homeNavigationRegularPumpingDescription,
      quickActions: const {
        WorkspaceQuickAction.help,
        WorkspaceQuickAction.progress,
      },
    ),
    WorkspacePresentationModule(
      descriptor: descriptor(DefaultFormalSystemIds.contextFreePumping),
      icon: Icons.schema_outlined,
      pageBuilder: (_) =>
          const PumpingLemmaPage(theorem: PumpingLemmaTheorem.contextFree),
      helpTopicId: HelpTopicIds.pumpingEditorOverview,
      navigationLabel: (l10n) => l10n.homeNavigationContextFreePumpingLabel,
      navigationDescription: (l10n) =>
          l10n.homeNavigationContextFreePumpingDescription,
      quickActions: const {
        WorkspaceQuickAction.help,
        WorkspaceQuickAction.progress,
      },
    ),
    if (registry.descriptorFor(TransducerFormalSystemIds.mealy) != null)
      WorkspacePresentationModule(
        descriptor: descriptor(TransducerFormalSystemIds.mealy),
        icon: Icons.swap_horiz,
        pageBuilder: (_) => const MealyPage(),
        helpTopicId: HelpTopicIds.mealyEditorOverview,
        navigationLabel: (l10n) => l10n.homeNavigationMealyLabel,
        navigationDescription: (l10n) => l10n.homeNavigationMealyDescription,
        quickActions: const {
          WorkspaceQuickAction.help,
          WorkspaceQuickAction.simulate,
          WorkspaceQuickAction.algorithms,
        },
        usesCanvasHighlight: true,
      ),
    if (registry.descriptorFor(TransducerFormalSystemIds.moore) != null)
      WorkspacePresentationModule(
        descriptor: descriptor(TransducerFormalSystemIds.moore),
        icon: Icons.multiline_chart,
        pageBuilder: (_) => const MoorePage(),
        helpTopicId: HelpTopicIds.mooreEditorOverview,
        navigationLabel: (l10n) => l10n.homeNavigationMooreLabel,
        navigationDescription: (l10n) => l10n.homeNavigationMooreDescription,
        quickActions: const {
          WorkspaceQuickAction.help,
          WorkspaceQuickAction.simulate,
          WorkspaceQuickAction.algorithms,
        },
        usesCanvasHighlight: true,
      ),
    if (registry.descriptorFor(UnrestrictedGrammarCapabilities.systemKey) !=
        null)
      WorkspacePresentationModule(
        descriptor: descriptor(UnrestrictedGrammarCapabilities.systemKey),
        icon: Icons.schema,
        pageBuilder: (_) => const UnrestrictedGrammarPage(),
        helpTopicId: HelpTopicIds.unrestrictedGrammarEditorOverview,
        navigationLabel: (l10n) => l10n.homeNavigationUnrestrictedGrammarLabel,
        navigationDescription: (l10n) =>
            l10n.homeNavigationUnrestrictedGrammarDescription,
        quickActions: const {
          WorkspaceQuickAction.help,
          WorkspaceQuickAction.edit,
          WorkspaceQuickAction.simulate,
          WorkspaceQuickAction.algorithms,
        },
      ),
    if (registry.descriptorFor(LSystemFormalSystemIds.key) != null)
      WorkspacePresentationModule(
        descriptor: descriptor(LSystemFormalSystemIds.key),
        icon: Icons.park_outlined,
        pageBuilder: (_) => const LSystemPage(),
        helpTopicId: HelpTopicIds.lSystemEditorOverview,
        navigationLabel: (l10n) => l10n.homeNavigationLSystemLabel,
        navigationDescription: (l10n) => l10n.homeNavigationLSystemDescription,
        quickActions: const {
          WorkspaceQuickAction.help,
          WorkspaceQuickAction.examples,
        },
      ),
  ]);
}
