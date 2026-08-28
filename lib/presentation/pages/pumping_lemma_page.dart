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
import '../../core/formal_systems/formal_systems.dart';
import '../../core/pumping_lemma/pumping_lemma.dart';
import '../../l10n/app_localizations.dart';
import '../providers/workspace_quick_actions_provider.dart';
import '../widgets/common/help_navigation.dart';
import '../widgets/automaton_workspace_scaffold.dart';
import '../widgets/pumping_lemma_progress.dart';
import '../widgets/pumping_lemma_workspace.dart';
import '../widgets/workspace_dock.dart';

/// Page for the Pumping Lemma Game
class PumpingLemmaPage extends ConsumerStatefulWidget {
  const PumpingLemmaPage({
    super.key,
    this.theorem = PumpingLemmaTheorem.regular,
  });

  final PumpingLemmaTheorem theorem;

  @override
  ConsumerState<PumpingLemmaPage> createState() => _PumpingLemmaPageState();
}

class _PumpingLemmaPageState extends ConsumerState<PumpingLemmaPage> {
  late final FocusNode _progressFocusNode;
  late final WorkspaceDockController _dockController;
  bool _isCompactLayout = false;

  FormalSystemKey get _workspaceKey =>
      widget.theorem == PumpingLemmaTheorem.regular
      ? DefaultFormalSystemIds.regularPumping
      : DefaultFormalSystemIds.contextFreePumping;

  @override
  void initState() {
    super.initState();
    _progressFocusNode = FocusNode(debugLabel: 'Pumping lemma progress action');
    _dockController = WorkspaceDockController();
  }

  @override
  void dispose() {
    _dockController.dispose();
    _progressFocusNode.dispose();
    super.dispose();
  }

  void _openHelp() {
    openHelp(context, topicId: HelpTopicIds.pumpingEditorGame);
  }

  void _toggleProgress() {
    if (_isCompactLayout) {
      _openProgressSheet();
      return;
    }
    _dockController.togglePanel('progress', returnFocusTo: _progressFocusNode);
  }

  /// Compact layouts open statistics in a bottom sheet like every other
  /// app-bar action; the game keeps its round because the sheet never
  /// unmounts the workspace beneath it.
  Future<void> _openProgressSheet() async {
    final l10n = AppLocalizations.of(context);
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (sheetContext) {
        return DraggableScrollableSheet(
          expand: false,
          initialChildSize: 0.72,
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
                          l10n.progressTitle,
                          style: Theme.of(context).textTheme.titleLarge,
                        ),
                      ),
                      IconButton(
                        tooltip: l10n.close,
                        onPressed: () => Navigator.of(sheetContext).pop(),
                        icon: const Icon(Icons.close),
                      ),
                    ],
                  ),
                ),
                const Divider(height: 1),
                Expanded(
                  child: SingleChildScrollView(
                    controller: scrollController,
                    padding: const EdgeInsets.all(16),
                    child: PumpingLemmaProgress(theorem: widget.theorem),
                  ),
                ),
              ],
            );
          },
        );
      },
    );
    _progressFocusNode.requestFocus();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // Reads the incoming constraints, not the window, so an embedded pane
      // picks the same band a same-sized window would.
      body: LayoutBuilder(
        builder: (context, constraints) {
          final width = constraints.maxWidth;
          final isCompactLayout =
              width < AutomatonWorkspaceScaffold.mobileBreakpoint;
          _isCompactLayout = isCompactLayout;
          publishWorkspaceQuickActionsForKey(
            ref,
            _workspaceKey,
            WorkspaceQuickActions(
              onHelp: _openHelp,
              onProgress: _toggleProgress,
              progressEnabled: true,
              progressFocusNode: _progressFocusNode,
            ),
          );

          if (isCompactLayout) {
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
    return SingleChildScrollView(
      child: Column(
        children: [
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 8),
            child: PumpingLemmaWorkspace(theorem: widget.theorem),
          ),
          const SizedBox(height: 8),
        ],
      ),
    );
  }

  /// Wide viewports give the game board the whole pane; progress stays
  /// collapsed behind the dock rail until the player asks for it.
  Widget _buildWideLayout({required double panelWidth}) {
    final l10n = AppLocalizations.of(context);

    return WorkspaceDock(
      controller: _dockController,
      initialPanelWidth: panelWidth,
      content: PumpingLemmaWorkspace(theorem: widget.theorem),
      panels: [
        WorkspaceDockPanel(
          id: 'progress',
          label: l10n.progressTitle,
          icon: Icons.bar_chart,
          child: PumpingLemmaProgress(theorem: widget.theorem),
        ),
      ],
    );
  }
}
