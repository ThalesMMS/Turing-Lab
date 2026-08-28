import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:turing_lab/core/models/settings_model.dart';
import 'package:turing_lab/core/repositories/settings_repository.dart';
import 'package:turing_lab/injection/data_providers.dart';
import 'package:turing_lab/l10n/app_localizations.dart';
import 'package:turing_lab/presentation/pages/settings_page.dart';
import 'package:turing_lab/presentation/providers/settings_provider.dart';
import 'package:turing_lab/presentation/localization/app_locale_policy.dart';

class _FakeSettingsRepository implements SettingsRepository {
  _FakeSettingsRepository({
    SettingsModel? initialSettings,
    this.failOnSave = false,
  }) : _settings = initialSettings ?? const SettingsModel();

  SettingsModel _settings;
  final bool failOnSave;
  final List<SettingsModel> savedSettings = [];

  @override
  Future<SettingsModel> loadSettings() async => _settings;

  @override
  Future<void> saveSettings(SettingsModel settings) async {
    if (failOnSave) throw StateError('save failed');
    _settings = settings;
    savedSettings.add(settings);
  }
}

Future<void> _pumpSettingsPage(
  WidgetTester tester, {
  required _FakeSettingsRepository repository,
  Size size = const Size(430, 932),
  List<Locale> platformLocales = const [Locale('en', 'US')],
}) async {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1.0;
  tester.platformDispatcher.localesTestValue = platformLocales;

  addTearDown(() {
    tester.view.resetPhysicalSize();
    tester.view.resetDevicePixelRatio();
    tester.platformDispatcher.clearLocalesTestValue();
  });

  await tester.pumpWidget(
    ProviderScope(
      overrides: [settingsRepositoryProvider.overrideWithValue(repository)],
      child: Consumer(
        builder: (context, ref, child) {
          final localeCode = ref.watch(settingsProvider).localeCode;
          return MaterialApp(
            locale: AppLocalePolicy.resolve(
              persistedLocaleCode: localeCode,
              platformLocales: platformLocales,
            ),
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalePolicy.supportedLocales,
            home: MediaQuery(
              data: MediaQueryData(size: size),
              child: SettingsPage(repository: repository),
            ),
          );
        },
      ),
    ),
  );

  await tester.pumpAndSettle();
}

Future<void> _ensureVisibleAndTap(WidgetTester tester, Finder finder) async {
  await tester.ensureVisible(finder);
  await tester.pumpAndSettle();
  await tester.tap(finder);
  await tester.pumpAndSettle();
}

void _updateSlider(WidgetTester tester, Key key, double value) {
  final slider = tester.widget<Slider>(find.byKey(key));
  expect(slider.onChanged, isNotNull);
  slider.onChanged!(value);
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
  });

  group('SettingsPage interactions', () {
    testWidgets('selecting Portuguese applies and persists the locale', (
      tester,
    ) async {
      final repository = _FakeSettingsRepository();
      await _pumpSettingsPage(tester, repository: repository);

      final portugueseOption = find.byKey(
        const ValueKey('settings_language_pt'),
      );
      await _ensureVisibleAndTap(tester, portugueseOption);

      expect(repository.savedSettings.last.localeCode, 'pt');
      expect(find.text('Configurações'), findsOneWidget);
      expect(tester.widget<FilterChip>(portugueseOption).selected, isTrue);
    });

    testWidgets('selecting English applies and persists the locale', (
      tester,
    ) async {
      final repository = _FakeSettingsRepository(
        initialSettings: const SettingsModel(localeCode: 'pt'),
      );
      await _pumpSettingsPage(tester, repository: repository);

      final englishOption = find.byKey(const ValueKey('settings_language_en'));
      await _ensureVisibleAndTap(tester, englishOption);

      expect(repository.savedSettings.last.localeCode, 'en');
      expect(find.text('Settings'), findsOneWidget);
      expect(tester.widget<FilterChip>(englishOption).selected, isTrue);
    });

    testWidgets('Portuguese locale localizes the Settings surface', (
      tester,
    ) async {
      await _pumpSettingsPage(
        tester,
        repository: _FakeSettingsRepository(
          initialSettings: const SettingsModel(localeCode: 'pt'),
        ),
      );

      for (final text in [
        'Configurações',
        'Tema',
        'Idioma',
        'Modo do tema',
        'Idioma do aplicativo',
        'Mostrar grade',
        'Salvamento automático',
        'Salvar configurações',
        'Restaurar padrões',
      ]) {
        expect(find.text(text), findsAtLeastNWidgets(1));
      }
    });

    testWidgets('does not advertise an empty-string symbol preference', (
      tester,
    ) async {
      await _pumpSettingsPage(tester, repository: _FakeSettingsRepository());

      expect(find.text('Symbols'), findsNothing);
      expect(find.text('Empty String Symbol'), findsNothing);
      expect(
        find.byKey(const ValueKey('settings_empty_string_lambda')),
        findsNothing,
      );
      expect(
        find.byKey(const ValueKey('settings_empty_string_epsilon')),
        findsNothing,
      );
    });

    testWidgets('save settings button persists the current settings', (
      tester,
    ) async {
      final repository = _FakeSettingsRepository();

      await _pumpSettingsPage(tester, repository: repository);

      await _ensureVisibleAndTap(
        tester,
        find.byKey(const ValueKey('settings_theme_dark')),
      );
      await _ensureVisibleAndTap(
        tester,
        find.byKey(const ValueKey('settings_show_tooltips_switch')),
      );
      await _ensureVisibleAndTap(
        tester,
        find.byKey(const ValueKey('settings_save_button')),
      );

      expect(repository.savedSettings, hasLength(1));
      expect(
        repository.savedSettings.single,
        const SettingsModel(themeMode: 'dark', showTooltips: false),
      );
      expect(find.text('Settings saved.'), findsOneWidget);
    });

    testWidgets('save error snackbar has no no-op dismiss action', (
      tester,
    ) async {
      await _pumpSettingsPage(
        tester,
        repository: _FakeSettingsRepository(failOnSave: true),
      );

      await _ensureVisibleAndTap(
        tester,
        find.byKey(const ValueKey('settings_save_button')),
      );

      expect(
        find.text('Failed to save settings. Please try again.'),
        findsOneWidget,
      );
      expect(find.text('Dismiss'), findsNothing);
    });

    testWidgets('reset to defaults reverts state and persists defaults', (
      tester,
    ) async {
      final repository = _FakeSettingsRepository(
        initialSettings: const SettingsModel(
          themeMode: 'dark',
          localeCode: 'pt',
          showGrid: false,
          showCoordinates: true,
          autoSave: false,
          showTooltips: false,
          gridSize: 35,
          nodeSize: 50,
          fontSize: 20,
        ),
      );

      await _pumpSettingsPage(tester, repository: repository);

      await _ensureVisibleAndTap(
        tester,
        find.byKey(const ValueKey('settings_reset_button')),
      );

      expect(repository.savedSettings, hasLength(1));
      expect(repository.savedSettings.single, const SettingsModel());

      expect(
        tester
            .widget<Switch>(
              find.byKey(const ValueKey('settings_show_grid_switch')),
            )
            .value,
        isTrue,
      );
      expect(
        tester
            .widget<FilterChip>(
              find.byKey(const ValueKey('settings_language_en')),
            )
            .selected,
        isTrue,
      );
      expect(
        tester
            .widget<Switch>(
              find.byKey(const ValueKey('settings_show_coordinates_switch')),
            )
            .value,
        isFalse,
      );
      expect(
        tester
            .widget<Switch>(
              find.byKey(const ValueKey('settings_auto_save_switch')),
            )
            .value,
        isTrue,
      );
      expect(
        tester
            .widget<Switch>(
              find.byKey(const ValueKey('settings_show_tooltips_switch')),
            )
            .value,
        isTrue,
      );
      expect(
        tester
            .widget<FilterChip>(
              find.byKey(const ValueKey('settings_theme_light')),
            )
            .selected,
        isTrue,
      );
    });

    testWidgets('reset returns language selection to automatic resolution', (
      tester,
    ) async {
      final repository = _FakeSettingsRepository(
        initialSettings: const SettingsModel(localeCode: 'en'),
      );
      await _pumpSettingsPage(
        tester,
        repository: repository,
        platformLocales: const [Locale('pt', 'BR')],
      );

      expect(
        tester
            .widget<FilterChip>(
              find.byKey(const ValueKey('settings_language_en')),
            )
            .selected,
        isTrue,
      );

      await _ensureVisibleAndTap(
        tester,
        find.byKey(const ValueKey('settings_reset_button')),
      );

      expect(repository.savedSettings.single.localeCode, isNull);
      expect(
        Localizations.localeOf(tester.element(find.byType(SettingsPage))),
        const Locale('pt', 'BR'),
      );
      expect(
        tester
            .widget<FilterChip>(
              find.byKey(const ValueKey('settings_language_pt')),
            )
            .selected,
        isTrue,
      );
    });

    testWidgets('failed reset restores the previous settings', (tester) async {
      final repository = _FakeSettingsRepository(
        initialSettings: const SettingsModel(
          themeMode: 'dark',
          localeCode: 'pt',
          showGrid: false,
        ),
        failOnSave: true,
      );
      await _pumpSettingsPage(tester, repository: repository);

      await _ensureVisibleAndTap(
        tester,
        find.byKey(const ValueKey('settings_reset_button')),
      );

      expect(
        tester
            .widget<FilterChip>(
              find.byKey(const ValueKey('settings_language_pt')),
            )
            .selected,
        isTrue,
      );
      expect(
        tester
            .widget<FilterChip>(
              find.byKey(const ValueKey('settings_theme_dark')),
            )
            .selected,
        isTrue,
      );
      expect(
        tester
            .widget<Switch>(
              find.byKey(const ValueKey('settings_show_grid_switch')),
            )
            .value,
        isFalse,
      );
      expect(
        find.text('Não foi possível salvar as configurações. Tente novamente.'),
        findsOneWidget,
      );
    });

    testWidgets('toggle switches update their selected values', (tester) async {
      final repository = _FakeSettingsRepository();

      await _pumpSettingsPage(tester, repository: repository);

      for (final key in const [
        ValueKey('settings_show_grid_switch'),
        ValueKey('settings_show_coordinates_switch'),
        ValueKey('settings_auto_save_switch'),
        ValueKey('settings_show_tooltips_switch'),
      ]) {
        await _ensureVisibleAndTap(tester, find.byKey(key));
      }

      expect(
        tester
            .widget<Switch>(
              find.byKey(const ValueKey('settings_show_grid_switch')),
            )
            .value,
        isFalse,
      );
      expect(
        tester
            .widget<Switch>(
              find.byKey(const ValueKey('settings_show_coordinates_switch')),
            )
            .value,
        isTrue,
      );
      expect(
        tester
            .widget<Switch>(
              find.byKey(const ValueKey('settings_auto_save_switch')),
            )
            .value,
        isFalse,
      );
      expect(
        tester
            .widget<Switch>(
              find.byKey(const ValueKey('settings_show_tooltips_switch')),
            )
            .value,
        isFalse,
      );
    });

    testWidgets('sliders reflect updated values', (tester) async {
      final repository = _FakeSettingsRepository();

      await _pumpSettingsPage(tester, repository: repository);

      await tester.ensureVisible(
        find.byKey(const ValueKey('settings_grid_size_slider')),
      );
      await tester.pumpAndSettle();

      _updateSlider(tester, const ValueKey('settings_grid_size_slider'), 40);
      await tester.pumpAndSettle();
      _updateSlider(tester, const ValueKey('settings_node_size_slider'), 55);
      await tester.pumpAndSettle();
      _updateSlider(tester, const ValueKey('settings_font_size_slider'), 18);
      await tester.pumpAndSettle();

      expect(
        tester
            .widget<Slider>(
              find.byKey(const ValueKey('settings_grid_size_slider')),
            )
            .value,
        40,
      );
      expect(
        tester
            .widget<Slider>(
              find.byKey(const ValueKey('settings_node_size_slider')),
            )
            .value,
        55,
      );
      expect(
        tester
            .widget<Slider>(
              find.byKey(const ValueKey('settings_font_size_slider')),
            )
            .value,
        18,
      );
    });

    testWidgets('theme filter chips update the active option', (tester) async {
      final repository = _FakeSettingsRepository();

      await _pumpSettingsPage(tester, repository: repository);

      await _ensureVisibleAndTap(
        tester,
        find.byKey(const ValueKey('settings_theme_dark')),
      );

      expect(
        tester
            .widget<FilterChip>(
              find.byKey(const ValueKey('settings_theme_dark')),
            )
            .selected,
        isTrue,
      );
      expect(
        tester
            .widget<FilterChip>(
              find.byKey(const ValueKey('settings_theme_system')),
            )
            .selected,
        isFalse,
      );
    });

    testWidgets('about tile opens the product overview page', (tester) async {
      final repository = _FakeSettingsRepository();
      await _pumpSettingsPage(tester, repository: repository);

      await _ensureVisibleAndTap(
        tester,
        find.byKey(const ValueKey('settings_about_tile')),
      );

      expect(find.byKey(const ValueKey('about_page')), findsOneWidget);
      expect(find.byKey(const ValueKey('about_open_licenses')), findsOneWidget);
    });
  });
}
