//
//  home_page.dart
//  Turing Lab
//
//  Orquestra a página inicial com navegação por PageView e bottom navigation
//  responsiva, integrando provedores de autômatos, gramáticas e destaques para
//  coordenar os módulos centrais do aplicativo em todas as plataformas.
//
//  Thales Matheus Mendonça Santos - October 2025
//
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../l10n/app_localizations.dart';
import '../../l10n/app_localizations_help.dart';
import '../providers/home_navigation_provider.dart';
import '../widgets/mobile_navigation.dart';
import '../widgets/desktop_navigation.dart';
import '../../core/services/simulation_highlight_service.dart';
import 'fsa_page.dart';
import 'grammar_page.dart';
import 'pda_page.dart';
import 'tm_page.dart';
import 'regex_page.dart';
import 'pumping_lemma_page.dart';
import 'settings_page.dart';
import 'help_page.dart';

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

  List<NavigationItem> _navigationItems(AppLocalizations l10n) => [
        NavigationItem(
          label: l10n.homeNavigationLabel('fsa'),
          icon: Icons.account_tree,
          description: l10n.homeNavigationDescription('fsa'),
        ),
        NavigationItem(
          label: l10n.homeNavigationLabel('grammar'),
          icon: Icons.text_fields,
          description: l10n.homeNavigationDescription('grammar'),
        ),
        NavigationItem(
          label: l10n.homeNavigationLabel('pda'),
          icon: Icons.storage,
          description: l10n.homeNavigationDescription('pda'),
        ),
        NavigationItem(
          label: l10n.homeNavigationLabel('tm'),
          icon: Icons.settings,
          description: l10n.homeNavigationDescription('tm'),
        ),
        NavigationItem(
          label: l10n.homeNavigationLabel('regex'),
          icon: Icons.pattern,
          description: l10n.homeNavigationDescription('regex'),
        ),
        NavigationItem(
          label: l10n.homeNavigationLabel('pumping'),
          icon: Icons.games,
          description: l10n.homeNavigationDescription('pumping'),
        ),
      ];

  List<Widget> get _pages => const [
        FSAPage(),
        GrammarPage(),
        PDAPage(),
        TMPage(),
        RegexPage(),
        PumpingLemmaPage(),
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
      child: IconButton(
        onPressed: onPressed,
        icon: Icon(icon),
        tooltip: label,
      ),
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
    final initialIndex = _sanitizeNavigationIndex(
      ref.read(homeNavigationProvider),
      _pages.length,
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

  String _getCurrentPageTitle(
    int currentIndex,
    List<NavigationItem> navigationItems,
  ) {
    return navigationItems[currentIndex].label;
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
    final navigationItems = _navigationItems(l10n);
    final pages = _pages;
    final navigationCount = navigationItems.length < pages.length
        ? navigationItems.length
        : pages.length;
    final visibleNavigationItems =
        navigationItems.take(navigationCount).toList();
    final visiblePages = pages.take(navigationCount).toList();
    final screenSize = MediaQuery.of(context).size;
    final currentIndex = ref.watch(homeNavigationProvider);
    final visibleCurrentIndex = _sanitizeNavigationIndex(
      currentIndex,
      navigationCount,
    );
    final isMobile =
        screenSize.width < 1024; // Better breakpoint for modern devices
    final hasCanvasHighlight = visibleCurrentIndex == 0 ||
        visibleCurrentIndex == 2 ||
        visibleCurrentIndex == 3;

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
          title: isMobile
              ? Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _getCurrentPageTitle(
                        visibleCurrentIndex,
                        visibleNavigationItems,
                      ),
                    ),
                    Text(
                      _getCurrentPageDescription(
                        visibleCurrentIndex,
                        visibleNavigationItems,
                      ),
                      style: theme.textTheme.bodySmall?.copyWith(
                        color:
                            theme.colorScheme.onSurface.withValues(alpha: 0.7),
                      ),
                    ),
                  ],
                )
              : Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      _getCurrentPageTitle(
                        visibleCurrentIndex,
                        visibleNavigationItems,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Flexible(
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
            _buildAppBarAction(
              label: l10n.homeHelpTooltip,
              icon: Icons.help_outline,
              onPressed: () => _showHelpDialog(context),
            ),
            _buildAppBarAction(
              label: l10n.homeSettingsTooltip,
              icon: Icons.settings,
              onPressed: () => _showSettingsDialog(context),
            ),
          ],
        ),
        body: isMobile
            ? pageView
            : Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 12,
                    ),
                    child: DesktopNavigation(
                      currentIndex: visibleCurrentIndex,
                      onDestinationSelected: _onNavigationTap,
                      items: visibleNavigationItems,
                      extended: screenSize.width >= 1440,
                    ),
                  ),
                  const VerticalDivider(width: 1, thickness: 1),
                  Expanded(child: pageView),
                ],
              ),
        bottomNavigationBar: isMobile
            ? MobileNavigation(
                currentIndex: visibleCurrentIndex,
                onTap: _onNavigationTap,
                items: visibleNavigationItems,
              )
            : null,
        floatingActionButton: _buildFloatingActionButton(
          context,
          visibleCurrentIndex,
        ),
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

  Widget? _buildFloatingActionButton(BuildContext context, int currentIndex) {
    // Show different FABs based on current page
    switch (currentIndex) {
      case 0: // FSA – redundant, handled via canvas toolbar
        return null;
      default:
        return null;
    }
  }

  void _showHelpDialog(BuildContext context) {
    Navigator.of(
      context,
    ).push(MaterialPageRoute(builder: (context) => const HelpPage()));
  }

  void _showSettingsDialog(BuildContext context) {
    Navigator.of(
      context,
    ).push(MaterialPageRoute(builder: (context) => const SettingsPage()));
  }
}
