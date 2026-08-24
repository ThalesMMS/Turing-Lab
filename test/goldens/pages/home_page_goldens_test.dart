//
//  home_page_goldens_test.dart
//  Turing Lab
//
//  Visual regression golden tests for Home page components (navigation and
//  layout), capturing snapshots of critical states: desktop/mobile layouts,
//  rail/bottom-bar navigation, and different tab selections. Guards visual
//  consistency of the main navigation UI across changes and catches automatic
//  regressions.
//
//  Thales Matheus Mendonça Santos - January 2026
//

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:golden_toolkit/golden_toolkit.dart';

import 'package:turing_lab/presentation/widgets/desktop_navigation.dart';
import 'package:turing_lab/presentation/widgets/mobile_navigation.dart';

// Widget that composes navigation + content area like Home page does
class _HomePageTestWidget extends StatefulWidget {
  final bool isMobile;
  final int selectedIndex;
  final bool extendedNav;

  const _HomePageTestWidget({
    this.isMobile = false,
    this.selectedIndex = 0,
    this.extendedNav = false,
  });

  @override
  State<_HomePageTestWidget> createState() => _HomePageTestWidgetState();
}

class _HomePageTestWidgetState extends State<_HomePageTestWidget> {
  late int _currentIndex;

  final List<NavigationItem> _navigationItems = const [
    NavigationItem(
      label: 'FSA',
      icon: Icons.account_tree,
      description: 'Finite State Automata',
    ),
    NavigationItem(
      label: 'Grammar',
      icon: Icons.text_fields,
      description: 'Context-Free Grammars',
    ),
    NavigationItem(
      label: 'PDA',
      icon: Icons.storage,
      description: 'Pushdown Automata',
    ),
    NavigationItem(
      label: 'TM',
      icon: Icons.settings,
      description: 'Turing Machines',
    ),
    NavigationItem(
      label: 'Regex',
      icon: Icons.pattern,
      description: 'Regular Expressions',
    ),
  ];

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.selectedIndex;
  }

  String _getCurrentPageTitle() {
    return _navigationItems[_currentIndex].label;
  }

  String _getCurrentPageDescription() {
    return _navigationItems[_currentIndex].description;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    final contentArea = Container(
      color: theme.colorScheme.surface,
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              _navigationItems[_currentIndex].icon,
              size: 64,
              color: theme.colorScheme.primary.withValues(alpha: 0.3),
            ),
            const SizedBox(height: 16),
            Text(
              '${_navigationItems[_currentIndex].label} Page Content',
              style: theme.textTheme.headlineSmall?.copyWith(
                color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
              ),
            ),
          ],
        ),
      ),
    );

    return Scaffold(
      appBar: AppBar(
        title: widget.isMobile
            ? Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(_getCurrentPageTitle()),
                  Text(
                    _getCurrentPageDescription(),
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
                    ),
                  ),
                ],
              )
            : Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(_getCurrentPageTitle()),
                  const SizedBox(width: 16),
                  Flexible(
                    child: Text(
                      _getCurrentPageDescription(),
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
        actions: [
          IconButton(
            onPressed: () {},
            icon: const Icon(Icons.help_outline),
            tooltip: 'Help',
          ),
          IconButton(
            onPressed: () {},
            icon: const Icon(Icons.settings),
            tooltip: 'Settings',
          ),
        ],
      ),
      body: widget.isMobile
          ? contentArea
          : Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 12,
                  ),
                  child: DesktopNavigation(
                    currentIndex: _currentIndex,
                    onDestinationSelected: (index) {
                      setState(() {
                        _currentIndex = index;
                      });
                    },
                    items: _navigationItems,
                    extended: widget.extendedNav,
                  ),
                ),
                const VerticalDivider(width: 1, thickness: 1),
                Expanded(child: contentArea),
              ],
            ),
      bottomNavigationBar: widget.isMobile
          ? MobileNavigation(
              currentIndex: _currentIndex,
              onTap: (index) {
                setState(() {
                  _currentIndex = index;
                });
              },
              items: _navigationItems,
            )
          : null,
    );
  }
}

Future<void> _pumpHomePageComponents(
  WidgetTester tester, {
  Size size = const Size(1400, 900),
  bool isMobile = false,
  int selectedIndex = 0,
  bool extendedNav = false,
}) async {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1.0;

  await tester.pumpWidgetBuilder(
    MaterialApp(
      home: _HomePageTestWidget(
        isMobile: isMobile,
        selectedIndex: selectedIndex,
        extendedNav: extendedNav,
      ),
    ),
  );

  await tester.pumpAndSettle();
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Home Page Components golden tests', () {
    testGoldens('renders desktop layout with navigation rail - FSA selected', (
      tester,
    ) async {
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      await _pumpHomePageComponents(
        tester,
        size: const Size(1400, 900),
        isMobile: false,
        selectedIndex: 0,
        extendedNav: false,
      );

      await screenMatchesGolden(tester, 'home_page_desktop_fsa');
    });

    testGoldens(
      'renders desktop layout with navigation rail - Grammar selected',
      (tester) async {
        addTearDown(() {
          tester.view.resetPhysicalSize();
          tester.view.resetDevicePixelRatio();
        });

        await _pumpHomePageComponents(
          tester,
          size: const Size(1400, 900),
          isMobile: false,
          selectedIndex: 1,
          extendedNav: false,
        );

        await screenMatchesGolden(tester, 'home_page_desktop_grammar');
      },
    );

    testGoldens('renders desktop layout with navigation rail - PDA selected', (
      tester,
    ) async {
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      await _pumpHomePageComponents(
        tester,
        size: const Size(1400, 900),
        isMobile: false,
        selectedIndex: 2,
        extendedNav: false,
      );

      await screenMatchesGolden(tester, 'home_page_desktop_pda');
    });

    testGoldens('renders desktop layout with extended navigation rail', (
      tester,
    ) async {
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      await _pumpHomePageComponents(
        tester,
        size: const Size(1600, 900),
        isMobile: false,
        selectedIndex: 0,
        extendedNav: true,
      );

      await screenMatchesGolden(tester, 'home_page_desktop_extended_nav');
    });

    testGoldens('renders tablet layout with navigation rail', (tester) async {
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      await _pumpHomePageComponents(
        tester,
        size: const Size(1024, 768),
        isMobile: false,
        selectedIndex: 0,
        extendedNav: false,
      );

      await screenMatchesGolden(tester, 'home_page_tablet');
    });

    testGoldens('renders mobile layout with bottom navigation - FSA selected', (
      tester,
    ) async {
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      await _pumpHomePageComponents(
        tester,
        size: const Size(430, 932),
        isMobile: true,
        selectedIndex: 0,
      );

      await screenMatchesGolden(tester, 'home_page_mobile_fsa');
    });

    testGoldens(
      'renders mobile layout with bottom navigation - Grammar selected',
      (tester) async {
        addTearDown(() {
          tester.view.resetPhysicalSize();
          tester.view.resetDevicePixelRatio();
        });

        await _pumpHomePageComponents(
          tester,
          size: const Size(430, 932),
          isMobile: true,
          selectedIndex: 1,
        );

        await screenMatchesGolden(tester, 'home_page_mobile_grammar');
      },
    );

    testGoldens(
      'renders mobile layout with bottom navigation - Regex selected',
      (tester) async {
        addTearDown(() {
          tester.view.resetPhysicalSize();
          tester.view.resetDevicePixelRatio();
        });

        await _pumpHomePageComponents(
          tester,
          size: const Size(430, 932),
          isMobile: true,
          selectedIndex: 4,
        );

        await screenMatchesGolden(tester, 'home_page_mobile_regex');
      },
    );
  });
}
