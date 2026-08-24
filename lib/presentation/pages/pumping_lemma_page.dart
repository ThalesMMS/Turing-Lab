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
import '../widgets/help_action_button.dart';
import '../widgets/pumping_lemma_game/pumping_lemma_game.dart';
import '../widgets/pumping_lemma_progress.dart';

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
    final screenSize = MediaQuery.of(context).size;
    final isMobile = screenSize.width < 1024;
    publishWorkspaceQuickActions(
      ref,
      WorkspaceTab.pumping,
      WorkspaceQuickActions(onHelp: _openHelp),
    );

    return Scaffold(
      body: isMobile
          ? _buildMobileLayout()
          : screenSize.width < 1400
              ? _buildTabletLayout()
              : _buildDesktopLayout(),
      floatingActionButton: isMobile ? null : _buildWideHelpButton(),
    );
  }

  Widget _buildWideHelpButton() {
    final tooltip = AppLocalizations.of(context).contextAwareHelp;

    return HelpActionButton(
      topicId: HelpTopicIds.pumpingEditorGame,
      tooltip: tooltip,
      filled: true,
    );
  }

  Widget _buildTabletLayout() {
    return _buildWideLayout(gap: 8);
  }

  Widget _buildMobileLayout() {
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
                        label: Text(_showGame ? 'Hide Game' : 'Show Game'),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: _openHelp,
                        icon: const Icon(Icons.help_outline),
                        label: const Text('Show Help'),
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
                      _showProgress ? 'Hide Progress' : 'Show Progress',
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

  Widget _buildDesktopLayout() {
    return _buildWideLayout(gap: 16);
  }

  Widget _buildWideLayout({required double gap}) {
    return Row(
      children: [
        Expanded(
          flex: 2,
          child: Container(
            margin: const EdgeInsets.all(8),
            child: const PumpingLemmaGame(),
          ),
        ),
        SizedBox(width: gap),
        Expanded(
          flex: 1,
          child: Container(
            margin: const EdgeInsets.all(8),
            child: const PumpingLemmaProgress(),
          ),
        ),
      ],
    );
  }
}
