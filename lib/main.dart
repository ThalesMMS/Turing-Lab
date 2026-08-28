//
//  main.dart
//  Turing Lab
//
//  Entry point that initializes the Flutter binding, configures shared
//  dependencies through the injector, and runs TuringLabApp as the root
//  application to start the cross-platform experience.
//
//  Thales Matheus Mendonça Santos - October 2025
//
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'data/repositories/settings_repository_impl.dart';
import 'data/storage/settings_storage.dart';
import 'injection/dependency_injection.dart';
import 'injection/data_providers.dart';
import 'app.dart';
import 'l10n/app_localizations.dart';
import 'presentation/localization/app_locale_policy.dart';
import 'presentation/providers/settings_provider.dart';

part 'startup_error_helpers.dart';
part 'initialization_error_app.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  _installGlobalErrorHandler();

  try {
    final prefs = await initializeSharedPreferences();
    final settingsRepository = SharedPreferencesSettingsRepository(
      storage: SharedPreferencesSettingsStorage(
        preferencesProvider: () async => prefs,
      ),
    );
    final initialSettings = await settingsRepository.loadSettings();

    runApp(
      ProviderScope(
        overrides: [
          sharedPreferencesProvider.overrideWithValue(prefs),
          settingsRepositoryProvider.overrideWithValue(settingsRepository),
          settingsProvider.overrideWith(
            (ref) => SettingsNotifier(
              settingsRepository,
              initialSettings: initialSettings,
            ),
          ),
        ],
        child: const TuringLabApp(),
      ),
    );
  } catch (error, stackTrace) {
    _reportInitializationFailure(error, stackTrace);
    runApp(const _InitializationErrorApp());
  }
}
