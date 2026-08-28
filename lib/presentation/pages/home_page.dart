//
//  home_page.dart
//  Turing Lab
//
//  Orchestrates the home page with PageView navigation and a responsive
//  app-bar workspace selector, integrating automaton, grammar, and highlight
//  providers to coordinate the app's core modules on every platform.
//
//  Thales Matheus Mendonça Santos - October 2025
//
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../l10n/app_localizations.dart';
import '../../l10n/app_localizations_help.dart';
import '../providers/home_navigation_provider.dart';
import '../providers/workspace_quick_actions_provider.dart';
import '../providers/workspace_registry_provider.dart';
import '../widgets/navigation_item.dart';
import '../widgets/workspace_selector.dart';
import '../widgets/workspace_quick_actions_bar.dart';
import '../widgets/common/help_navigation.dart';
import '../workspaces/workspace_presentation_module.dart';
import '../workspaces/workspace_quick_action.dart';
import '../../core/formal_systems/formal_systems.dart';
import '../../core/services/simulation_highlight_service.dart';
import 'settings_page.dart';

/// Main home page with modern design and mobile-first approach
class HomePage extends ConsumerStatefulWidget {
  const HomePage({super.key});

  @override
  ConsumerState<HomePage> createState() => _HomePageState();
}

class _HomePageState extends ConsumerState<HomePage> {
  late final PageController _pageController;
  int? _lastNavigationIndex;
  final SimulationHighlightService _fallbackHighlightService =
      SimulationHighlightService();

  /// Keeps the PageView element identity stable when the layout moves it
  /// between the mobile and desktop subtrees, so its scroll position is
  /// reparented instead of re-attached to [_pageController].
  final GlobalKey _pageViewKey = GlobalKey(debugLabel: 'home-page-view');

  List<NavigationItem> _navigationItems(
    AppLocalizations l10n,
    List<WorkspacePresentationModule> modules,
  ) => [
    for (final module in modules)
      NavigationItem(
        label: module.navigationLabel(l10n),
        icon: module.icon,
        description: module.navigationDescription(l10n),
      ),
  ];

  Widget _buildAppBarAction({
    required String label,
    required IconData icon,
    required VoidCallback onPressed,
  }) {
    return Semantics(
      label: label,
      button: true,
      enabled: true,
      onTap: onPressed,
      excludeSemantics: true,
      child: IconButton(onPressed: onPressed, icon: Icon(icon), tooltip: label),
    );
  }

  int _sanitizeNavigationIndex(int index, int itemCount) {
    if (itemCount <= 0) {
      return 0;
    }
    if (index < 0) {
      return 0;
    }
    final lastIndex = itemCount - 1;
    if (index > lastIndex) {
      return lastIndex;
    }
    return index;
  }

  @override
  void initState() {
    super.initState();
    final registry = ref.read(workspacePresentationRegistryProvider);
    final initialIndex = _sanitizeNavigationIndex(
      ref.read(homeNavigationProvider),
      registry.modules.length,
    );
    _pageController = PageController(initialPage: initialIndex);
    _lastNavigationIndex = initialIndex;
  }

  @override
  void dispose() {
    _fallbackHighlightService.clear();
    _pageController.dispose();
    super.dispose();
  }

  void _onNavigationTap(int index) {
    ref.read(homeNavigationProvider.notifier).setIndex(index);
  }

  /// Reads the controller's current page only when exactly one PageView is
  /// attached. Returns the initial page before the first attach and null
  /// during a transient multi-attach (reading `page` would assert then).
  int? _readSolePage() {
    final positions = _pageController.positions;
    if (positions.isEmpty) {
      return _pageController.initialPage;
    }
    if (positions.length != 1) {
      return null;
    }
    return _pageController.page?.round() ?? _pageController.initialPage;
  }

  void _onPageChanged(int index) {
    ref.read(homeNavigationProvider.notifier).setIndex(index);
  }

  String _getCurrentPageDescription(
    int currentIndex,
    List<NavigationItem> navigationItems,
  ) {
    return navigationItems[currentIndex].description;
  }

  @override
  Widget build(BuildContext context) {
    final l10n = jflapLocalizationsOf(context);
    final workspaceRegistry = ref.watch(workspacePresentationRegistryProvider);
    final modules = workspaceRegistry.modules;
    final visibleNavigationItems = _navigationItems(l10n, modules);
    final visiblePages = [
      for (final module in modules) module.pageBuilder(context),
    ];
    final navigationCount = modules.length;
    final screenSize = MediaQuery.of(context).size;
    final currentIndex = ref.watch(homeNavigationProvider);
    final visibleCurrentIndex = _sanitizeNavigationIndex(
      currentIndex,
      navigationCount,
    );
    final isMobile =
        screenSize.width < 1024; // Better breakpoint for modern devices
    final currentModule = workspaceRegistry.moduleAt(visibleCurrentIndex);
    final currentWorkspaceKey = currentModule.key;
    final hasCanvasHighlight = currentModule.usesCanvasHighlight;

    if (_lastNavigationIndex != visibleCurrentIndex) {
      _lastNavigationIndex = visibleCurrentIndex;
    }

    // Handle navigation changes
    if (currentIndex != visibleCurrentIndex) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) {
          return;
        }
        ref.read(homeNavigationProvider.notifier).setIndex(visibleCurrentIndex);
      });
    }

    if (_readSolePage() != visibleCurrentIndex) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) {
          return;
        }

        final currentPage = _readSolePage();
        if (currentPage == null || currentPage == visibleCurrentIndex) {
          return;
        }

        _pageController.jumpToPage(visibleCurrentIndex);
      });
    }

    final publishedQuickActions = ref.watch(
      workspaceQuickActionsProvider(currentWorkspaceKey),
    );
    final quickActions = publishedQuickActions?.constrainedTo(
      capabilities: currentModule.descriptor.capabilities,
      supportedActions: currentModule.quickActions,
    );
    final supportsContextualHelp =
        currentModule.quickActions.contains(WorkspaceQuickAction.help) &&
        currentModule.descriptor.capabilities.supports(
          FormalSystemCapability.help,
        );
    final compactQuickActionCount = [
      quickActions?.onSimulate,
      quickActions?.onAlgorithms,
      quickActions?.onEdit,
      quickActions?.onMetrics,
      quickActions?.onProgress,
      quickActions?.onExamples,
    ].whereType<VoidCallback>().length;
    // Three left slots is the app-wide maximum; the reservation below relies
    // on it so the workspace dropdown never moves between workspaces.
    assert(
      compactQuickActionCount <= 3,
      'Workspaces publish at most 3 compact quick actions, '
      'got $compactQuickActionCount.',
    );
    final collapseCompactQuickActions =
        isMobile && screenSize.width < 430 && compactQuickActionCount > 1;
    // The dropdown sits right after the leading slots, so the reserved width
    // must not depend on how many actions the active workspace publishes:
    // narrow phones always resolve to one slot (single button or the
    // overflow), everything else reserves the full three slots.
    const quickActionSlotWidth = 48.0;
    final mobileLeadingWidth = compactQuickActionCount == 0
        ? 0.0
        : (collapseCompactQuickActions || screenSize.width < 430)
        ? quickActionSlotWidth
        : quickActionSlotWidth * 3;
    final wideQuickActions = <WorkspaceQuickAction>{
      if (quickActions?.onSimulate != null) WorkspaceQuickAction.simulate,
      if (quickActions?.onAlgorithms != null) WorkspaceQuickAction.algorithms,
      if (quickActions?.onEdit != null) WorkspaceQuickAction.edit,
      if (quickActions?.onExamples != null) WorkspaceQuickAction.examples,
    };

    final theme = Theme.of(context);
    final pageView = PageView(
      key: _pageViewKey,
      controller: _pageController,
      onPageChanged: _onPageChanged,
      physics: const NeverScrollableScrollPhysics(), // Disable swipe gestures
      children: visiblePages,
    );

    final scaffold = FocusTraversalGroup(
      policy: ReadingOrderTraversalPolicy(),
      child: Scaffold(
        appBar: AppBar(
          // Compact viewports keep shortcuts on the left and switch workspaces
          // from the title. Wide viewports keep the same selector at the
          // leading edge instead of a permanent side rail.
          leading: isMobile
              ? WorkspaceQuickActionsBar(
                  workspaceKey: currentWorkspaceKey,
                  collapseMultiple: collapseCompactQuickActions,
                )
              : WorkspaceSelector(
                  items: visibleNavigationItems,
                  currentIndex: visibleCurrentIndex,
                  onSelected: _onNavigationTap,
                ),
          leadingWidth: isMobile
              ? mobileLeadingWidth
              : WorkspaceSelector.leadingWidth,
          titleSpacing: isMobile ? 0 : NavigationToolbar.kMiddleSpacing,
          title: isMobile
              ? WorkspaceSelector(
                  items: visibleNavigationItems,
                  currentIndex: visibleCurrentIndex,
                  onSelected: _onNavigationTap,
                  compact: true,
                )
              // Keep contextual commands reachable on wide layouts without
              // displacing the workspace selector from the leading edge.
              : Row(
                  children: [
                    if (wideQuickActions.contains(
                      WorkspaceQuickAction.examples,
                    )) ...[
                      WorkspaceQuickActionsBar(
                        workspaceKey: currentWorkspaceKey,
                        visibleActions: wideQuickActions,
                      ),
                      const SizedBox(width: 8),
                    ],
                    Expanded(
                      child: Text(
                        _getCurrentPageDescription(
                          visibleCurrentIndex,
                          visibleNavigationItems,
                        ),
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
          actions: [
            if (supportsContextualHelp)
              _buildAppBarAction(
                label: l10n.homeHelpTooltip,
                icon: Icons.help_outline,
                onPressed:
                    quickActions?.onHelp ??
                    () => openHelp(context, topicId: currentModule.helpTopicId),
              ),
            _buildAppBarAction(
              label: l10n.homeSettingsTooltip,
              icon: Icons.settings,
              onPressed: () => _showSettingsDialog(context),
            ),
          ],
        ),
        body: pageView,
      ),
    );

    if (!hasCanvasHighlight) {
      _fallbackHighlightService.clear();
    }

    // Always keep the ProviderScope in the tree: swapping it in and out
    // rebuilt the entire subtree (destroying every page and transiently
    // attaching two PageViews to _pageController, which crashes the `page`
    // getter). Only the injected value changes between canvas and
    // non-canvas tabs.
    return ProviderScope(
      overrides: [
        canvasHighlightServiceProvider.overrideWithValue(
          hasCanvasHighlight
              ? ref.watch(canvasHighlightServiceProvider)
              : _fallbackHighlightService,
        ),
      ],
      child: scaffold,
    );
  }

  void _showSettingsDialog(BuildContext context) {
    Navigator.of(
      context,
    ).push(MaterialPageRoute(builder: (context) => const SettingsPage()));
  }
}
