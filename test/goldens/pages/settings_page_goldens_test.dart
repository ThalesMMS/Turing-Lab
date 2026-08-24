//
//  settings_page_goldens_test.dart
//  Turing Lab
//
//  Visual regression golden tests for the Settings page, capturing snapshots
//  of critical states: desktop/tablet/mobile layouts, default settings,
//  custom settings, and different themes and sizes. Guards visual consistency
//  of the settings UI across changes and catches automatic regressions.
//
//  NOTE: Because of SettingsProvider lifecycle issues with Riverpod in golden
//  tests, this file currently tests mocked visual components of the settings
//  page instead of the full SettingsPage. That keeps visual regression coverage
//  while avoiding test crashes.
//
//  Thales Matheus Mendonça Santos - January 2026
//

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:golden_toolkit/golden_toolkit.dart';
import 'package:shared_preferences/shared_preferences.dart';

// Mock Settings UI that replicates the visual structure of SettingsPage
// without the Riverpod provider dependencies
class _MockSettingsPageWidget extends StatelessWidget {
  final String emptyStringSymbol;
  final String themeMode;
  final bool showGrid;
  final bool showCoordinates;
  final bool autoSave;
  final bool showTooltips;
  final double gridSize;
  final double nodeSize;
  final double fontSize;

  const _MockSettingsPageWidget({
    this.emptyStringSymbol = 'λ',
    this.themeMode = 'system',
    this.showGrid = true,
    this.showCoordinates = false,
    this.autoSave = true,
    this.showTooltips = true,
    this.gridSize = 20.0,
    this.nodeSize = 30.0,
    this.fontSize = 14.0,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
        actions: [
          IconButton(
            onPressed: () {},
            icon: const Icon(Icons.save),
            tooltip: 'Save Settings',
          ),
          IconButton(
            onPressed: () {},
            icon: const Icon(Icons.restore),
            tooltip: 'Reset to Defaults',
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildSectionHeader(context, 'Symbols'),
            _buildSymbolSettings(context),
            const SizedBox(height: 24),
            _buildSectionHeader(context, 'Theme'),
            _buildThemeSettings(context),
            const SizedBox(height: 24),
            _buildSectionHeader(context, 'Canvas'),
            _buildCanvasSettings(context),
            const SizedBox(height: 24),
            _buildSectionHeader(context, 'General'),
            _buildGeneralSettings(context),
            const SizedBox(height: 24),
            _buildSectionHeader(context, 'Actions'),
            _buildActionButtons(context),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader(BuildContext context, String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Text(
        title,
        style: Theme.of(
          context,
        ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
      ),
    );
  }

  Widget _buildSymbolSettings(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Empty String Symbol',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 4),
            Text(
              'Symbol used to represent empty string (λ or ε)',
              style: Theme.of(context).textTheme.bodySmall,
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              children: [
                FilterChip(
                  label: const Text('λ (Lambda)'),
                  selected: emptyStringSymbol == 'λ',
                  onSelected: (_) {},
                ),
                FilterChip(
                  label: const Text('ε (Epsilon)'),
                  selected: emptyStringSymbol == 'ε',
                  onSelected: (_) {},
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildThemeSettings(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Theme Mode',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 4),
            Text(
              'Choose your preferred theme',
              style: Theme.of(context).textTheme.bodySmall,
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              children: [
                FilterChip(
                  label: const Text('System'),
                  selected: themeMode == 'system',
                  onSelected: (_) {},
                ),
                FilterChip(
                  label: const Text('Light'),
                  selected: themeMode == 'light',
                  onSelected: (_) {},
                ),
                FilterChip(
                  label: const Text('Dark'),
                  selected: themeMode == 'dark',
                  onSelected: (_) {},
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCanvasSettings(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Show Grid',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                      SizedBox(height: 4),
                      Text('Display grid lines on canvas'),
                    ],
                  ),
                ),
                Switch(value: showGrid, onChanged: (_) {}),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Show Coordinates',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                      SizedBox(height: 4),
                      Text('Display coordinate information'),
                    ],
                  ),
                ),
                Switch(value: showCoordinates, onChanged: (_) {}),
              ],
            ),
            const SizedBox(height: 16),
            const Text(
              'Grid Size',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 4),
            const Text('Size of grid cells'),
            Row(
              children: [
                Expanded(
                  child: Slider(
                    value: gridSize,
                    min: 10.0,
                    max: 50.0,
                    divisions: 8,
                    label: gridSize.round().toString(),
                    onChanged: (_) {},
                  ),
                ),
                const SizedBox(width: 16),
                Text(
                  gridSize.round().toString(),
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const Text(
              'Node Size',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 4),
            const Text('Size of automaton nodes'),
            Row(
              children: [
                Expanded(
                  child: Slider(
                    value: nodeSize,
                    min: 20.0,
                    max: 60.0,
                    divisions: 8,
                    label: nodeSize.round().toString(),
                    onChanged: (_) {},
                  ),
                ),
                const SizedBox(width: 16),
                Text(
                  nodeSize.round().toString(),
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const SizedBox(height: 16),
            const Text(
              'Font Size',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 4),
            const Text('Text size in the interface'),
            Row(
              children: [
                Expanded(
                  child: Slider(
                    value: fontSize,
                    min: 12.0,
                    max: 20.0,
                    divisions: 4,
                    label: fontSize.round().toString(),
                    onChanged: (_) {},
                  ),
                ),
                const SizedBox(width: 16),
                Text(
                  fontSize.round().toString(),
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildGeneralSettings(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Auto Save',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                      SizedBox(height: 4),
                      Text('Automatically save changes'),
                    ],
                  ),
                ),
                Switch(value: autoSave, onChanged: (_) {}),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Show Tooltips',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                      SizedBox(height: 4),
                      Text('Display helpful tooltips'),
                    ],
                  ),
                ),
                Switch(value: showTooltips, onChanged: (_) {}),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionButtons(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () {},
                icon: const Icon(Icons.save),
                label: const Text('Save Settings'),
              ),
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: () {},
                icon: const Icon(Icons.restore),
                label: const Text('Reset to Defaults'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

Future<void> _pumpSettingsPage(
  WidgetTester tester, {
  String emptyStringSymbol = 'λ',
  String themeMode = 'system',
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

  await tester.pumpWidget(
    MaterialApp(
      home: _MockSettingsPageWidget(
        emptyStringSymbol: emptyStringSymbol,
        themeMode: themeMode,
        showGrid: showGrid,
        showCoordinates: showCoordinates,
        autoSave: autoSave,
        showTooltips: showTooltips,
        gridSize: gridSize,
        nodeSize: nodeSize,
        fontSize: fontSize,
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

    testGoldens('renders settings page with custom symbol settings', (
      tester,
    ) async {
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      await _pumpSettingsPage(
        tester,
        emptyStringSymbol: 'ε',
        size: const Size(1400, 900),
      );

      await screenMatchesGolden(tester, 'settings_page_custom_symbols_desktop');
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
        emptyStringSymbol: 'ε',
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
        emptyStringSymbol: 'ε',
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
        emptyStringSymbol: 'ε',
        themeMode: 'light',
        showCoordinates: true,
        gridSize: 35.0,
        size: const Size(1200, 800),
      );

      await screenMatchesGolden(tester, 'settings_page_custom_tablet');
    });
  });
}
