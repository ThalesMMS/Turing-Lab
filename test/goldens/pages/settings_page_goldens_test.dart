//
//  settings_page_goldens_test.dart
//  Turing Lab
//
//  Visual regression golden tests for the production Settings page. Captures
//  responsive layouts, themes, and representative persisted preferences.
//
//  Thales Matheus Mendonça Santos - January 2026
//

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:golden_toolkit/golden_toolkit.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:turing_lab/core/models/settings_model.dart';
import 'package:turing_lab/core/repositories/settings_repository.dart';
import 'package:turing_lab/injection/data_providers.dart';
import 'package:turing_lab/l10n/app_localizations.dart';
import 'package:turing_lab/presentation/pages/settings_page.dart';

class _GoldenSettingsRepository implements SettingsRepository {
  _GoldenSettingsRepository(this._settings);

  SettingsModel _settings;

  @override
  Future<SettingsModel> loadSettings() async => _settings;

  @override
  Future<void> saveSettings(SettingsModel settings) async {
    _settings = settings;
  }
}

Future<void> _pumpSettingsPage(
  WidgetTester tester, {
  String themeMode = 'light',
  bool showGrid = true,
  bool showCoordinates = false,
  bool autoSave = true,
  bool showTooltips = true,
  double gridSize = 20.0,
  double nodeSize = 30.0,
  double fontSize = 14.0,
  Size size = const Size(1400, 900),
}) async {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1.0;

  final settings = SettingsModel(
    themeMode: themeMode,
    showGrid: showGrid,
    showCoordinates: showCoordinates,
    autoSave: autoSave,
    showTooltips: showTooltips,
    gridSize: gridSize,
    nodeSize: nodeSize,
    fontSize: fontSize,
  );
  final repository = _GoldenSettingsRepository(settings);
  final resolvedThemeMode = switch (themeMode) {
    'light' => ThemeMode.light,
    'dark' => ThemeMode.dark,
    'system' => ThemeMode.system,
    _ => ThemeMode.light,
  };

  await tester.pumpWidget(
    ProviderScope(
      overrides: [settingsRepositoryProvider.overrideWithValue(repository)],
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        theme: ThemeData(),
        darkTheme: ThemeData.dark(),
        themeMode: resolvedThemeMode,
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: MediaQuery(
          data: MediaQueryData(size: size),
          child: SettingsPage(repository: repository),
        ),
      ),
    ),
  );

  await tester.pumpAndSettle();
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
  });

  group('Settings Page golden tests', () {
    testGoldens('renders settings page with defaults in desktop layout', (
      tester,
    ) async {
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      await _pumpSettingsPage(tester, size: const Size(1400, 900));

      await screenMatchesGolden(tester, 'settings_page_defaults_desktop');
    });

    testGoldens('renders settings page with defaults in tablet layout', (
      tester,
    ) async {
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      await _pumpSettingsPage(tester, size: const Size(1200, 800));

      await screenMatchesGolden(tester, 'settings_page_defaults_tablet');
    });

    testGoldens('renders settings page with defaults in mobile layout', (
      tester,
    ) async {
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      await _pumpSettingsPage(tester, size: const Size(430, 932));

      await screenMatchesGolden(tester, 'settings_page_defaults_mobile');
    });

    testGoldens('renders settings page with dark theme selected', (
      tester,
    ) async {
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      await _pumpSettingsPage(
        tester,
        themeMode: 'dark',
        size: const Size(1400, 900),
      );

      await screenMatchesGolden(tester, 'settings_page_dark_theme_desktop');
    });

    testGoldens('renders settings page with light theme selected', (
      tester,
    ) async {
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      await _pumpSettingsPage(
        tester,
        themeMode: 'light',
        size: const Size(1400, 900),
      );

      await screenMatchesGolden(tester, 'settings_page_light_theme_desktop');
    });

    testGoldens('renders settings page with custom canvas settings', (
      tester,
    ) async {
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      await _pumpSettingsPage(
        tester,
        showGrid: false,
        showCoordinates: true,
        gridSize: 40.0,
        nodeSize: 50.0,
        fontSize: 18.0,
        size: const Size(1400, 900),
      );

      await screenMatchesGolden(tester, 'settings_page_custom_canvas_desktop');
    });

    testGoldens('renders settings page with custom general settings', (
      tester,
    ) async {
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      await _pumpSettingsPage(
        tester,
        autoSave: false,
        showTooltips: false,
        size: const Size(1400, 900),
      );

      await screenMatchesGolden(tester, 'settings_page_custom_general_desktop');
    });

    testGoldens('renders settings page with all custom settings', (
      tester,
    ) async {
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      await _pumpSettingsPage(
        tester,
        themeMode: 'dark',
        showGrid: false,
        showCoordinates: true,
        autoSave: false,
        showTooltips: false,
        gridSize: 45.0,
        nodeSize: 55.0,
        fontSize: 16.0,
        size: const Size(1400, 900),
      );

      await screenMatchesGolden(tester, 'settings_page_fully_custom_desktop');
    });

    testGoldens('renders settings page with minimum slider values', (
      tester,
    ) async {
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      await _pumpSettingsPage(
        tester,
        gridSize: 10.0,
        nodeSize: 20.0,
        fontSize: 12.0,
        size: const Size(1400, 900),
      );

      await screenMatchesGolden(tester, 'settings_page_min_sliders_desktop');
    });

    testGoldens('renders settings page with maximum slider values', (
      tester,
    ) async {
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      await _pumpSettingsPage(
        tester,
        gridSize: 50.0,
        nodeSize: 60.0,
        fontSize: 20.0,
        size: const Size(1400, 900),
      );

      await screenMatchesGolden(tester, 'settings_page_max_sliders_desktop');
    });

    testGoldens('renders settings page in mobile layout with custom settings', (
      tester,
    ) async {
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      await _pumpSettingsPage(
        tester,
        themeMode: 'dark',
        showGrid: false,
        autoSave: false,
        size: const Size(430, 932),
      );

      await screenMatchesGolden(tester, 'settings_page_custom_mobile');
    });

    testGoldens('renders settings page in tablet layout with custom settings', (
      tester,
    ) async {
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      await _pumpSettingsPage(
        tester,
        themeMode: 'light',
        showCoordinates: true,
        gridSize: 35.0,
        size: const Size(1200, 800),
      );

      await screenMatchesGolden(tester, 'settings_page_custom_tablet');
    });
  });
}
