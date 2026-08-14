//
//  grammar_page.dart
//  Turing Lab
//
//  Monta a página de gramáticas livres de contexto com layouts adaptáveis,
//  exibindo editor, simulação e algoritmos em painéis configuráveis para
//  desktop e mobile, além de controles que alternam seções conforme o espaço
//  disponível.
//
//  Thales Matheus Mendonça Santos - October 2025
//
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/grammar_provider.dart';
import '../providers/help_provider.dart';
import '../widgets/context_aware_help_panel.dart';
import '../widgets/grammar_editor.dart';
import '../widgets/grammar_simulation_panel.dart';
import '../widgets/grammar_algorithm_panel.dart';
import '../widgets/tablet_layout_container.dart';

/// Page for working with Context-Free Grammars
class GrammarPage extends ConsumerStatefulWidget {
  const GrammarPage({super.key});

  @override
  ConsumerState<GrammarPage> createState() => _GrammarPageState();
}

class _GrammarPageState extends ConsumerState<GrammarPage> {
  bool _showControls = true;
  bool _showSimulation = false;
  bool _showAlgorithms = false;

  void _showContextualHelp() {
    final helpNotifier = ref.read(helpProvider.notifier);
    final grammarState = ref.read(grammarProvider);

    // Determine the most relevant help content based on current grammar state
    String helpContextId;
    if (grammarState.productions.isEmpty) {
      helpContextId = 'usage_getting_started';
    } else if (grammarState.isConverting || _showAlgorithms) {
      helpContextId = 'concept_parsing';
    } else {
      helpContextId = 'concept_cfg';
    }

    final helpContent = helpNotifier.getHelpByContext(helpContextId);
    if (helpContent != null) {
      ContextAwareHelpPanel.show(
        context,
        helpContent: helpContent,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenSize = MediaQuery.of(context).size;
    final isMobile = screenSize.width < 1024;

    return FocusTraversalGroup(
      policy: ReadingOrderTraversalPolicy(),
      child: Scaffold(
        body: isMobile
            ? _buildMobileLayout()
            : screenSize.width < 1400
                ? _buildTabletLayout()
                : _buildDesktopLayout(),
        floatingActionButton: !isMobile
            ? FloatingActionButton(
                heroTag: 'grammar_context_help_fab',
                onPressed: _showContextualHelp,
                tooltip: 'Context-Aware Help',
                child: const Icon(Icons.help_outline),
              )
            : null,
      ),
    );
  }

  Widget _buildMobileLayout() {
    return SafeArea(
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: LayoutBuilder(
              builder: (context, constraints) {
                final buttonWidth = (constraints.maxWidth - 8) / 2;
                return Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    SizedBox(
                      width: buttonWidth,
                      child: _buildToggleButton(
                        icon: Icons.edit,
                        label: 'Editor',
                        isActive: _showControls,
                        onPressed: () =>
                            setState(() => _showControls = !_showControls),
                      ),
                    ),
                    SizedBox(
                      width: buttonWidth,
                      child: _buildToggleButton(
                        icon: Icons.play_arrow,
                        label: 'Parse',
                        isActive: _showSimulation,
                        onPressed: () =>
                            setState(() => _showSimulation = !_showSimulation),
                      ),
                    ),
                    SizedBox(
                      width: buttonWidth,
                      child: _buildToggleButton(
                        icon: Icons.auto_awesome,
                        label: 'Algorithms',
                        isActive: _showAlgorithms,
                        onPressed: () =>
                            setState(() => _showAlgorithms = !_showAlgorithms),
                      ),
                    ),
                    SizedBox(
                      width: buttonWidth,
                      child: _buildToggleButton(
                        icon: Icons.help_outline,
                        label: 'Help',
                        isActive: false,
                        onPressed: _showContextualHelp,
                      ),
                    ),
                  ],
                );
              },
            ),
          ),

          // Content area with proper scrolling
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.only(bottom: 16),
              child: Column(
                children: [
                  // Collapsible panels with better space management
                  if (_showControls || _showSimulation || _showAlgorithms) ...[
                    Container(
                      margin: const EdgeInsets.symmetric(horizontal: 8),
                      child: _buildPanelsColumn(),
                    ),
                  ] else
                    const SizedBox(height: 8),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDesktopLayout() {
    return Row(
      children: [
        // Left panel - Grammar Editor
        Expanded(
          flex: 2,
          child: Container(
            margin: const EdgeInsets.all(8),
            child: const GrammarEditor(),
          ),
        ),
        const SizedBox(width: 16),
        // Center panel - Simulation
        Expanded(
          flex: 1,
          child: Container(
            margin: const EdgeInsets.all(8),
            child: const GrammarSimulationPanel(),
          ),
        ),
        const SizedBox(width: 16),
        // Right panel - Algorithms
        Expanded(
          flex: 1,
          child: Container(
            margin: const EdgeInsets.all(8),
            child: const GrammarAlgorithmPanel(),
          ),
        ),
      ],
    );
  }

  Widget _buildToggleButton({
    required IconData icon,
    required String label,
    required bool isActive,
    required VoidCallback onPressed,
  }) {
    return ElevatedButton.icon(
      onPressed: onPressed,
      icon: Icon(icon, size: 16),
      label: Text(
        label,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: const TextStyle(fontSize: 12),
      ),
      style: ElevatedButton.styleFrom(
        backgroundColor: isActive
            ? Theme.of(context).colorScheme.primary
            : Theme.of(context).colorScheme.surface,
        foregroundColor: isActive
            ? Theme.of(context).colorScheme.onPrimary
            : Theme.of(context).colorScheme.onSurface,
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 12),
        minimumSize: Size.zero,
      ),
    );
  }

  Widget _buildPanelsColumn() {
    final panelMaxHeight =
        (MediaQuery.sizeOf(context).height * 0.35).clamp(220.0, 360.0);

    return Column(
      children: [
        // Grammar editor
        if (_showControls) ...[
          const GrammarEditor(),
          const SizedBox(height: 8),
        ],

        // Simulation panel
        if (_showSimulation) ...[
          Container(
            constraints: BoxConstraints(maxHeight: panelMaxHeight),
            child: const GrammarSimulationPanel(),
          ),
          const SizedBox(height: 8),
        ],

        // Algorithm panel
        if (_showAlgorithms) ...[
          Container(
            constraints: BoxConstraints(maxHeight: panelMaxHeight),
            child: const GrammarAlgorithmPanel(),
          ),
        ],
      ],
    );
  }

  Widget _buildTabletLayout() {
    return const TabletLayoutContainer(
      canvas: GrammarEditor(),
      algorithmPanel: GrammarAlgorithmPanel(useExpanded: false),
      simulationPanel: GrammarSimulationPanel(useExpanded: false),
    );
  }
}
