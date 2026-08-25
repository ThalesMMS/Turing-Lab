//
//  pumping_lemma_page.dart
//  Turing Lab
//
//  Hosts the Pumping Lemma game with play and progress sections, adapting
//  the layout for mobile and desktop and routing pedagogical guidance to
//  the unified help tree.
//
//  Thales Matheus Mendonça Santos - October 2025
//
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/constants/help_topic_ids.dart';
import '../../l10n/app_localizations.dart';
import '../providers/workspace_quick_actions_provider.dart';
import '../widgets/common/help_navigation.dart';
import '../widgets/automaton_workspace_scaffold.dart';
import '../widgets/pumping_lemma_game/pumping_lemma_game.dart';
import '../widgets/pumping_lemma_progress.dart';
import '../widgets/workspace_dock.dart';

/// Page for the Pumping Lemma Game
class PumpingLemmaPage extends ConsumerStatefulWidget {
  const PumpingLemmaPage({super.key});

  @override
  ConsumerState<PumpingLemmaPage> createState() => _PumpingLemmaPageState();
}

class _PumpingLemmaPageState extends ConsumerState<PumpingLemmaPage> {
  bool _showGame = true;
  bool _showProgress = false;

  void _openHelp() {
    openHelp(context, topicId: HelpTopicIds.pumpingEditorGame);
  }

  @override
  Widget build(BuildContext context) {
    publishWorkspaceQuickActions(
      ref,
      WorkspaceTab.pumping,
      WorkspaceQuickActions(onHelp: _openHelp),
    );

    return Scaffold(
      // Reads the incoming constraints, not the window, so an embedded pane
      // picks the same band a same-sized window would.
      body: LayoutBuilder(
        builder: (context, constraints) {
          final width = constraints.maxWidth;
          if (width < AutomatonWorkspaceScaffold.mobileBreakpoint) {
            return _buildMobileLayout();
          }
          return _buildWideLayout(
            panelWidth: width < AutomatonWorkspaceScaffold.tabletBreakpoint
                ? AutomatonWorkspaceScaffold.tabletPanelWidth
                : AutomatonWorkspaceScaffold.desktopPanelWidth,
          );
        },
      ),
    );
  }

  Widget _buildMobileLayout() {
    final l10n = AppLocalizations.of(context);
    return SingleChildScrollView(
      child: Column(
        children: [
          // Mobile controls toggle
          Container(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: () => setState(() => _showGame = !_showGame),
                        icon: Icon(
                          _showGame ? Icons.visibility_off : Icons.games,
                        ),
                        label: Text(_showGame ? l10n.hideGame : l10n.showGame),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: _openHelp,
                        icon: const Icon(Icons.help_outline),
                        label: Text(l10n.showHelp),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: () =>
                        setState(() => _showProgress = !_showProgress),
                    icon: Icon(
                      _showProgress ? Icons.visibility_off : Icons.analytics,
                    ),
                    label: Text(
                      _showProgress ? l10n.hideProgress : l10n.showProgress,
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Game (collapsible on mobile)
          if (_showGame) ...[
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 8),
              child: const PumpingLemmaGame(),
            ),
            const SizedBox(height: 8),
          ],
          // Progress panel (collapsible on mobile)
          if (_showProgress) ...[
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 8),
              child: const PumpingLemmaProgress(),
            ),
            const SizedBox(height: 8),
          ],
        ],
      ),
    );
  }

  /// Wide viewports give the game board the whole pane; progress stays
  /// collapsed behind the dock rail until the player asks for it.
  Widget _buildWideLayout({required double panelWidth}) {
    final l10n = AppLocalizations.of(context);

    return WorkspaceDock(
      initialPanelWidth: panelWidth,
      content: const PumpingLemmaGame(),
      panels: [
        WorkspaceDockPanel(
          id: 'progress',
          label: l10n.progressTitle,
          icon: Icons.analytics,
          child: const PumpingLemmaProgress(),
        ),
      ],
    );
  }
}
