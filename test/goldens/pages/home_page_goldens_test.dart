//
//  home_page_goldens_test.dart
//  Turing Lab
//
//  Visual regression golden tests for Home page components (navigation and
//  layout), capturing snapshots of critical states: wide/mobile layouts, the
//  app-bar workspace selector, the bottom bar, and different tab selections.
//  Guards visual consistency of the main navigation UI across changes and
//  catches automatic regressions.
//
//  Thales Matheus Mendonça Santos - January 2026
//

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:golden_toolkit/golden_toolkit.dart';

import 'package:turing_lab/presentation/widgets/mobile_navigation.dart';
import 'package:turing_lab/presentation/widgets/workspace_selector.dart';

// Widget that composes navigation + content area like Home page does
class _HomePageTestWidget extends StatefulWidget {
  final bool isMobile;
  final int selectedIndex;

  const _HomePageTestWidget({
    this.isMobile = false,
    this.selectedIndex = 0,
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
        leadingWidth: widget.isMobile ? null : WorkspaceSelector.leadingWidth,
        leading: widget.isMobile
            ? null
            : WorkspaceSelector(
                items: _navigationItems,
                currentIndex: _currentIndex,
                onSelected: (index) {
                  setState(() {
                    _currentIndex = index;
                  });
                },
              ),
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
            // The selector already names the workspace, so the title only
            // carries the longer description.
            : Text(
                _getCurrentPageDescription(),
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
                overflow: TextOverflow.ellipsis,
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
      body: contentArea,
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
}) async {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1.0;

  await tester.pumpWidgetBuilder(
    MaterialApp(
      home: _HomePageTestWidget(
        isMobile: isMobile,
        selectedIndex: selectedIndex,
      ),
    ),
  );

  await tester.pumpAndSettle();
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Home Page Components golden tests', () {
    testGoldens('renders wide layout with workspace selector - FSA selected', (
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
      );

      await screenMatchesGolden(tester, 'home_page_desktop_fsa');
    });

    testGoldens(
      'renders wide layout with workspace selector - Grammar selected',
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
        );

        await screenMatchesGolden(tester, 'home_page_desktop_grammar');
      },
    );

    testGoldens('renders wide layout with workspace selector - PDA selected', (
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
      );

      await screenMatchesGolden(tester, 'home_page_desktop_pda');
    });

    testGoldens('renders wide layout on a large desktop window', (
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
      );

      await screenMatchesGolden(tester, 'home_page_desktop_wide');
    });

    testGoldens('renders tablet layout with workspace selector', (
      tester,
    ) async {
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      await _pumpHomePageComponents(
        tester,
        size: const Size(1024, 768),
        isMobile: false,
        selectedIndex: 0,
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
