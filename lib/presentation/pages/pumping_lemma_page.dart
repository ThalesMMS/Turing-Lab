//
//  pumping_lemma_page.dart
//  Turing Lab
//
//  Controla o módulo do jogo do Lema do Bombeamento com alternância de seções
//  para jogo, ajuda e progresso, adaptando o layout a telas móveis e desktop
//  enquanto mantém um fluxo pedagógico contínuo para explorar linguagens
//  regulares e não regulares.
//
//  Thales Matheus Mendonça Santos - October 2025
//
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../widgets/pumping_lemma_game/pumping_lemma_game.dart';
import '../widgets/pumping_lemma_help.dart';
import '../widgets/pumping_lemma_progress.dart';
import '../widgets/tablet_layout_container.dart';

/// Page for the Pumping Lemma Game
class PumpingLemmaPage extends ConsumerStatefulWidget {
  const PumpingLemmaPage({super.key});

  @override
  ConsumerState<PumpingLemmaPage> createState() => _PumpingLemmaPageState();
}

class _PumpingLemmaPageState extends ConsumerState<PumpingLemmaPage> {
  bool _showGame = true;
  bool _showHelp = false;
  bool _showProgress = false;

  @override
  Widget build(BuildContext context) {
    final screenSize = MediaQuery.of(context).size;
    final isMobile = screenSize.width < 1024;

    return Scaffold(
      body: isMobile
          ? _buildMobileLayout()
          : screenSize.width < 1400
              ? _buildTabletLayout()
              : _buildDesktopLayout(),
    );
  }

  Widget _buildTabletLayout() {
    return const TabletLayoutContainer(
      canvas: PumpingLemmaGame(),
      algorithmPanel: PumpingLemmaHelp(),
      simulationPanel: PumpingLemmaProgress(),
      algorithmTabTitle: 'Help',
      simulationTabTitle: 'Progress',
    );
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
                        onPressed: () => setState(() => _showHelp = !_showHelp),
                        icon: Icon(
                          _showHelp ? Icons.visibility_off : Icons.help,
                        ),
                        label: Text(_showHelp ? 'Hide Help' : 'Show Help'),
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

          // Help panel (collapsible on mobile)
          if (_showHelp) ...[
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 8),
              child: const PumpingLemmaHelp(),
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
    return Row(
      children: [
        // Left panel - Game
        Expanded(
          flex: 2,
          child: Container(
            margin: const EdgeInsets.all(8),
            child: const PumpingLemmaGame(),
          ),
        ),
        const SizedBox(width: 16),
        // Center panel - Help
        Expanded(
          flex: 1,
          child: Container(
            margin: const EdgeInsets.all(8),
            child: const PumpingLemmaHelp(),
          ),
        ),
        const SizedBox(width: 16),
        // Right panel - Progress
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
