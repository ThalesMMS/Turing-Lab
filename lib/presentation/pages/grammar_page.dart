//
//  grammar_page.dart
//  Turing Lab
//
//  Builds the context-free grammar page with adaptive layouts, showing
//  productions as the main area and moving editing, parsing, and
//  algorithms onto the workspace's responsive surfaces.
//
//  Thales Matheus Mendonça Santos - October 2025
//
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/constants/help_topic_ids.dart';
import '../../core/formal_systems/formal_systems.dart';
import '../../core/models/production.dart';
import '../../l10n/app_localizations_help.dart';
import '../providers/grammar_provider.dart';
import '../providers/workspace_quick_actions_provider.dart';
import '../widgets/automaton_workspace_scaffold.dart';
import '../widgets/common/help_navigation.dart';
import '../widgets/grammar_algorithm_panel.dart';
import '../widgets/grammar_editor.dart';
import '../widgets/grammar_editor_section.dart';
import '../widgets/grammar_simulation_panel.dart';

/// Page for working with Context-Free Grammars.
class GrammarPage extends ConsumerStatefulWidget {
  const GrammarPage({super.key});

  @override
  ConsumerState<GrammarPage> createState() => _GrammarPageState();
}

class _GrammarPageState extends ConsumerState<GrammarPage> {
  void _showContextualHelp() {
    final grammarState = ref.read(grammarProvider);
    final topicId = grammarState.isConverting
        ? HelpTopicIds.grammarEditorAlgorithms
        : grammarState.productions.isEmpty
        ? HelpTopicIds.grammarEditorOverview
        : HelpTopicIds.grammarTheoryCfg;

    openHelp(context, topicId: topicId);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = jflapLocalizationsOf(context);
    return AutomatonWorkspaceScaffold(
      canvasWithToolbar: _buildProductionsEditor,
      algorithmPanel: const GrammarAlgorithmPanel(useExpanded: false),
      algorithmTabTitle: l10n.algorithmsAndExamples,
      simulationPanel: const GrammarSimulationPanel(),
      simulationTabTitle: l10n.parser,
    );
  }

  Widget _buildProductionsEditor({required bool isMobile}) {
    final grammarState = ref.watch(grammarProvider);
    final l10n = jflapLocalizationsOf(context);
    final hasProductions = grammarState.productions.isNotEmpty;

    publishWorkspaceQuickActionsForKey(
      ref,
      DefaultFormalSystemIds.grammar,
      WorkspaceQuickActions(
        onHelp: _showContextualHelp,
        onSimulate: _openParserSheet,
        onAlgorithms: _openAlgorithmSheet,
        onEdit: _openGrammarEditorSheet,
        simulateTooltip: l10n.workspaceParserTooltip,
        algorithmsTooltip: l10n.workspaceAlgorithmsAndExamplesTooltip,
        editTooltip: l10n.workspaceEditTooltip,
        simulateEnabled: hasProductions,
      ),
    );

    return GrammarEditor(
      section: GrammarEditorSection.productions,
      onEditGrammar: isMobile ? null : _openGrammarEditorSheet,
      onEditProduction: _openProductionEditorSheet,
    );
  }

  Future<void> _openAlgorithmSheet() {
    return _showWorkspaceSheet(
      title: jflapLocalizationsOf(context).algorithmsAndExamples,
      helpTopicId: HelpTopicIds.grammarEditorAlgorithms,
      child: const GrammarAlgorithmPanel(useExpanded: false),
    );
  }

  Future<void> _openParserSheet() {
    return _showWorkspaceSheet(
      title: jflapLocalizationsOf(context).parser,
      helpTopicId: HelpTopicIds.grammarEditorParserWorkflow,
      child: const GrammarSimulationPanel(useExpanded: false),
    );
  }

  Future<void> _openGrammarEditorSheet() => _openEditSheet();

  Future<void> _openProductionEditorSheet(Production production) {
    return _openEditSheet(production);
  }

  Future<void> _openEditSheet([Production? production]) {
    return _showWorkspaceSheet(
      title: jflapLocalizationsOf(context).editGrammar,
      helpTopicId: production == null
          ? HelpTopicIds.grammarEditorOverview
          : HelpTopicIds.grammarEditorProductionRowsAndAlternatives,
      initialChildSize: 0.85,
      child: GrammarEditor(
        section: GrammarEditorSection.details,
        productionToEdit: production,
      ),
    );
  }

  Future<void> _showWorkspaceSheet({
    required String title,
    required String helpTopicId,
    required Widget child,
    double initialChildSize = 0.72,
  }) {
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (sheetContext) {
        return DraggableScrollableSheet(
          expand: false,
          initialChildSize: initialChildSize,
          minChildSize: 0.4,
          maxChildSize: 0.95,
          builder: (context, scrollController) {
            return Column(
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 8, 8, 8),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          title,
                          style: Theme.of(context).textTheme.titleLarge,
                        ),
                      ),
                      IconButton(
                        tooltip: jflapLocalizationsOf(context).homeHelpTooltip,
                        onPressed: () =>
                            openHelp(sheetContext, topicId: helpTopicId),
                        icon: const Icon(Icons.help_outline),
                      ),
                      IconButton(
                        tooltip: jflapLocalizationsOf(context).close,
                        onPressed: () => Navigator.of(sheetContext).pop(),
                        icon: const Icon(Icons.close),
                      ),
                    ],
                  ),
                ),
                const Divider(height: 1),
                Expanded(
                  child: ListView(
                    controller: scrollController,
                    padding: const EdgeInsets.all(16),
                    children: [child],
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }
}
