import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:turing_lab/injection/dependency_injection.dart';
import 'package:turing_lab/main.dart' as app;
import 'package:turing_lab/presentation/widgets/desktop_navigation.dart';
import 'package:turing_lab/presentation/widgets/mobile_navigation.dart';

typedef _NavigationDestination = ({
  String label,
  String desktopTooltip,
  String expectedHeading,
});

const _navigationDestinations = <_NavigationDestination>[
  (
    label: 'Grammar',
    desktopTooltip: 'Context-Free Grammars',
    expectedHeading: 'Context-Free Grammars',
  ),
  (
    label: 'PDA',
    desktopTooltip: 'Pushdown Automata',
    expectedHeading: 'Pushdown Automata',
  ),
  (
    label: 'TM',
    desktopTooltip: 'Turing Machines',
    expectedHeading: 'Turing Machines',
  ),
  (
    label: 'Regex',
    desktopTooltip: 'Regular Expressions',
    expectedHeading: 'Regular Expressions',
  ),
];

Future<void> _launchApp(
  WidgetTester tester, {
  required Size size,
}) async {
  await resetDependencies();
  SharedPreferences.setMockInitialValues(const {});

  await tester.binding.setSurfaceSize(size);
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1.0;
  addTearDown(() async {
    await tester.binding.setSurfaceSize(null);
    tester.view.resetPhysicalSize();
    tester.view.resetDevicePixelRatio();
  });

  app.main();
  await _pumpForTransition(tester);
}

Future<void> _pumpForTransition(WidgetTester tester) async {
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 400));
  await tester.pump(const Duration(milliseconds: 400));
}

void _expectNoException(WidgetTester tester, String context) {
  expect(
    tester.takeException(),
    isNull,
    reason: 'Unexpected exception while $context.',
  );
}

Finder _appBarAction(IconData icon) {
  return find.descendant(
    of: find.byType(AppBar),
    matching: find.widgetWithIcon(IconButton, icon),
  );
}

Future<void> _invokeAppBarAction(WidgetTester tester, IconData icon) async {
  final buttonFinder = _appBarAction(icon);
  final buttons = tester.widgetList<IconButton>(buttonFinder).toList();
  final enabledButtonIndex = buttons.indexWhere(
    (candidate) => candidate.onPressed != null,
  );

  expect(enabledButtonIndex, isNonNegative);

  await tester.ensureVisible(buttonFinder.at(enabledButtonIndex));
  await tester.tap(buttonFinder.at(enabledButtonIndex));
  await tester.pumpAndSettle();
}

Future<void> _tapNavigationDestination(
  WidgetTester tester, {
  required bool isMobile,
  required _NavigationDestination destination,
}) async {
  final finder = isMobile
      ? find.descendant(
          of: find.byType(MobileNavigation),
          matching: find.text(destination.label),
        )
      : find.byTooltip(destination.desktopTooltip);

  await tester.ensureVisible(finder.first);
  await tester.tap(finder.first);
  await _pumpForTransition(tester);
}

Future<void> _openSettingsPage(WidgetTester tester) async {
  await _invokeAppBarAction(tester, Icons.settings);
}

Future<void> _openHelpPage(WidgetTester tester) async {
  await _invokeAppBarAction(tester, Icons.help_outline);
}

Future<void> _tapHelpSection(
  WidgetTester tester, {
  required String label,
}) async {
  final finder = find.widgetWithText(ListTile, label);
  await tester.ensureVisible(finder.first);
  await tester.tap(finder.first);
  await _pumpForTransition(tester);
}

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  tearDown(() async {
    await resetDependencies();
  });

  testWidgets('mobile smoke: launch app and navigate release-critical pages', (
    tester,
  ) async {
    await _launchApp(tester, size: const Size(430, 932));

    expect(find.byType(MobileNavigation), findsOneWidget);
    expect(find.text('Finite State Automata'), findsWidgets);
    _expectNoException(tester, 'loading the initial FSA page');

    for (final destination in _navigationDestinations) {
      await _tapNavigationDestination(
        tester,
        isMobile: true,
        destination: destination,
      );

      expect(find.text(destination.expectedHeading), findsWidgets);
      _expectNoException(
          tester, 'navigating to ${destination.expectedHeading}');
    }
  });

  testWidgets(
    'desktop smoke: navigate, save settings, open help, and keep using the app',
    (tester) async {
      await _launchApp(tester, size: const Size(1440, 900));

      expect(find.byType(DesktopNavigation), findsOneWidget);
      expect(find.text('Finite State Automata'), findsWidgets);
      _expectNoException(tester, 'loading the desktop home page');

      await _tapNavigationDestination(
        tester,
        isMobile: false,
        destination: _navigationDestinations.first,
      );
      expect(find.text('Context-Free Grammars'), findsWidgets);
      _expectNoException(tester, 'navigating with the desktop rail');

      await _openSettingsPage(tester);
      expect(find.text('Settings'), findsWidgets);
      expect(find.text('Theme Mode'), findsOneWidget);
      _expectNoException(tester, 'opening the settings page');

      await tester
          .ensureVisible(find.byKey(const ValueKey('settings_theme_dark')));
      await tester.tap(find.byKey(const ValueKey('settings_theme_dark')));
      await _pumpForTransition(tester);
      expect(
        tester
            .widget<FilterChip>(
                find.byKey(const ValueKey('settings_theme_dark')))
            .selected,
        isTrue,
      );

      await tester
          .ensureVisible(find.byKey(const ValueKey('settings_save_button')));
      await tester.tap(find.byKey(const ValueKey('settings_save_button')));
      await _pumpForTransition(tester);

      expect(find.text('Settings saved.'), findsOneWidget);
      _expectNoException(tester, 'saving settings');

      await tester.pageBack();
      await _pumpForTransition(tester);
      expect(find.text('Context-Free Grammars'), findsWidgets);
      _expectNoException(tester, 'returning from settings');

      await _openHelpPage(tester);
      expect(find.text('Help & Documentation'), findsOneWidget);
      expect(find.text('Getting Started'), findsWidgets);
      _expectNoException(tester, 'opening the help page');

      await _tapHelpSection(tester, label: 'Grammar');
      expect(find.text('Context-Free Grammars'), findsWidgets);
      _expectNoException(tester, 'navigating a help section');

      await tester.pageBack();
      await _pumpForTransition(tester);

      await _tapNavigationDestination(
        tester,
        isMobile: false,
        destination: _navigationDestinations[1],
      );
      expect(find.text('Pushdown Automata'), findsWidgets);
      _expectNoException(tester, 'continuing to use the app after help');
    },
  );
}
