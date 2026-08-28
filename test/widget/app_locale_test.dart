import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:turing_lab/app.dart';
import 'package:turing_lab/core/models/settings_model.dart';
import 'package:turing_lab/core/repositories/settings_repository.dart';
import 'package:turing_lab/injection/data_providers.dart';
import 'package:turing_lab/presentation/pages/home_page.dart';
import 'package:turing_lab/presentation/providers/settings_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

class _FakeSettingsRepository implements SettingsRepository {
  const _FakeSettingsRepository(this.settings);

  final SettingsModel settings;

  @override
  Future<SettingsModel> loadSettings() async => settings;

  @override
  Future<void> saveSettings(SettingsModel settings) async {}
}

class _DelayedSettingsRepository implements SettingsRepository {
  _DelayedSettingsRepository(this._completer);

  final Completer<SettingsModel> _completer;

  @override
  Future<SettingsModel> loadSettings() => _completer.future;

  @override
  Future<void> saveSettings(SettingsModel settings) async {}
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late SharedPreferences preferences;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    preferences = await SharedPreferences.getInstance();
  });

  Future<void> pumpApp(
    WidgetTester tester, {
    SettingsModel settings = const SettingsModel(),
    List<Locale> platformLocales = const [Locale('en', 'US')],
  }) async {
    tester.platformDispatcher.localesTestValue = platformLocales;
    addTearDown(tester.platformDispatcher.clearLocalesTestValue);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          sharedPreferencesProvider.overrideWithValue(preferences),
          settingsRepositoryProvider.overrideWithValue(
            _FakeSettingsRepository(settings),
          ),
        ],
        child: const TuringLabApp(),
      ),
    );
    await tester.pumpAndSettle();
  }

  Locale materialAppLocale(WidgetTester tester) {
    return tester.widget<MaterialApp>(find.byType(MaterialApp)).locale!;
  }

  Locale localizedLocale(WidgetTester tester) {
    return Localizations.localeOf(tester.element(find.byType(HomePage)));
  }

  testWidgets('preloaded preferences apply on the first app frame', (
    tester,
  ) async {
    tester.platformDispatcher.localesTestValue = const [Locale('en', 'US')];
    addTearDown(tester.platformDispatcher.clearLocalesTestValue);
    final completer = Completer<SettingsModel>();
    final repository = _DelayedSettingsRepository(completer);
    const persisted = SettingsModel(themeMode: 'dark', localeCode: 'pt');

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          sharedPreferencesProvider.overrideWithValue(preferences),
          settingsRepositoryProvider.overrideWithValue(repository),
          settingsProvider.overrideWith(
            (ref) => SettingsNotifier(repository, initialSettings: persisted),
          ),
        ],
        child: const TuringLabApp(),
      ),
    );

    final app = tester.widget<MaterialApp>(find.byType(MaterialApp));
    expect(app.themeMode, ThemeMode.dark);
    expect(app.locale, const Locale('pt', 'BR'));
    expect(localizedLocale(tester), const Locale('pt', 'BR'));
    expect(completer.isCompleted, isFalse);
  });

  testWidgets('explicit Portuguese overrides device detection', (tester) async {
    await pumpApp(
      tester,
      settings: const SettingsModel(localeCode: 'pt'),
      platformLocales: const [Locale('en', 'GB')],
    );

    expect(materialAppLocale(tester), const Locale('pt', 'BR'));
    expect(localizedLocale(tester), const Locale('pt', 'BR'));
  });

  testWidgets('explicit English overrides a pt-BR device', (tester) async {
    await pumpApp(
      tester,
      settings: const SettingsModel(localeCode: 'en'),
      platformLocales: const [Locale('pt', 'BR')],
    );

    expect(materialAppLocale(tester), const Locale('en', 'US'));
    expect(localizedLocale(tester), const Locale('en', 'US'));
  });

  testWidgets('automatic mode uses Brazilian Portuguese only for pt-BR', (
    tester,
  ) async {
    await pumpApp(tester, platformLocales: const [Locale('pt', 'BR')]);

    expect(materialAppLocale(tester), const Locale('pt', 'BR'));
    expect(localizedLocale(tester), const Locale('pt', 'BR'));
  });

  for (final locale in const [
    Locale('pt', 'PT'),
    Locale('pt'),
    Locale('en', 'US'),
    Locale('en', 'GB'),
    Locale('fr', 'FR'),
    Locale('ja', 'JP'),
  ]) {
    testWidgets('automatic mode maps $locale to en-US', (tester) async {
      await pumpApp(tester, platformLocales: [locale]);

      expect(materialAppLocale(tester), const Locale('en', 'US'));
      expect(localizedLocale(tester), const Locale('en', 'US'));
    });
  }

  testWidgets('automatic mode considers only the primary device locale', (
    tester,
  ) async {
    await pumpApp(
      tester,
      platformLocales: const [Locale('en', 'GB'), Locale('pt', 'BR')],
    );

    expect(materialAppLocale(tester), const Locale('en', 'US'));
    expect(localizedLocale(tester), const Locale('en', 'US'));
  });

  testWidgets('fresh app uses light theme regardless of platform brightness', (
    tester,
  ) async {
    tester.platformDispatcher.platformBrightnessTestValue = Brightness.dark;
    addTearDown(tester.platformDispatcher.clearPlatformBrightnessTestValue);

    await pumpApp(tester);

    expect(
      tester.widget<MaterialApp>(find.byType(MaterialApp)).themeMode,
      ThemeMode.light,
    );
  });

  testWidgets('stored system and dark theme choices remain available', (
    tester,
  ) async {
    await pumpApp(tester, settings: const SettingsModel(themeMode: 'system'));
    expect(
      tester.widget<MaterialApp>(find.byType(MaterialApp)).themeMode,
      ThemeMode.system,
    );

    await tester.pumpWidget(const SizedBox.shrink());
    await pumpApp(tester, settings: const SettingsModel(themeMode: 'dark'));
    expect(
      tester.widget<MaterialApp>(find.byType(MaterialApp)).themeMode,
      ThemeMode.dark,
    );
  });

  testWidgets('invalid in-memory theme falls back to light', (tester) async {
    await pumpApp(tester, settings: const SettingsModel(themeMode: 'sepia'));

    expect(
      tester.widget<MaterialApp>(find.byType(MaterialApp)).themeMode,
      ThemeMode.light,
    );
  });
}
