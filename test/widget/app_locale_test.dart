import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:turing_lab/app.dart';
import 'package:turing_lab/core/models/settings_model.dart';
import 'package:turing_lab/core/repositories/settings_repository.dart';
import 'package:turing_lab/injection/data_providers.dart';
import 'package:turing_lab/presentation/pages/home_page.dart';
import 'package:shared_preferences/shared_preferences.dart';

class _FakeSettingsRepository implements SettingsRepository {
  const _FakeSettingsRepository(this.settings);

  final SettingsModel settings;

  @override
  Future<SettingsModel> loadSettings() async => settings;

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

  testWidgets('TuringLabApp applies an explicit Portuguese locale', (
    tester,
  ) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          sharedPreferencesProvider.overrideWithValue(preferences),
          settingsRepositoryProvider.overrideWithValue(
            const _FakeSettingsRepository(
              SettingsModel(localeCode: 'pt'),
            ),
          ),
        ],
        child: const TuringLabApp(),
      ),
    );
    await tester.pumpAndSettle();

    final app = tester.widget<MaterialApp>(find.byType(MaterialApp));
    expect(app.locale, const Locale('pt'));
  });

  testWidgets('system locale falls back to English when unsupported', (
    tester,
  ) async {
    tester.platformDispatcher.localesTestValue = const [Locale('fr')];
    addTearDown(tester.platformDispatcher.clearLocalesTestValue);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          sharedPreferencesProvider.overrideWithValue(preferences),
          settingsRepositoryProvider.overrideWithValue(
            const _FakeSettingsRepository(SettingsModel()),
          ),
        ],
        child: const TuringLabApp(),
      ),
    );
    await tester.pumpAndSettle();

    final app = tester.widget<MaterialApp>(find.byType(MaterialApp));
    final homeContext = tester.element(find.byType(HomePage));
    expect(app.locale, isNull);
    expect(Localizations.localeOf(homeContext), const Locale('en'));
  });

  testWidgets('supported Portuguese system locale is preserved by default', (
    tester,
  ) async {
    tester.platformDispatcher.localesTestValue = const [Locale('pt', 'BR')];
    addTearDown(tester.platformDispatcher.clearLocalesTestValue);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          sharedPreferencesProvider.overrideWithValue(preferences),
          settingsRepositoryProvider.overrideWithValue(
            const _FakeSettingsRepository(SettingsModel()),
          ),
        ],
        child: const TuringLabApp(),
      ),
    );
    await tester.pumpAndSettle();

    final homeContext = tester.element(find.byType(HomePage));
    expect(Localizations.localeOf(homeContext).languageCode, 'pt');
  });
}
