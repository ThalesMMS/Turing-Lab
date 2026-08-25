//
//  app_store_capture_settings_repository.dart
//  Turing Lab
//
//  In-memory settings repository that pins locale, theme and canvas options
//  for a capture, replacing the SharedPreferences-backed implementation so no
//  persisted state from a previous slot can leak into the screenshot.
//
//  Thales Matheus Mendonça Santos - August 2026
//
import 'package:turing_lab/core/models/settings_model.dart';
import 'package:turing_lab/core/repositories/settings_repository.dart';

/// Fixed settings source used while a screenshot is being captured.
class AppStoreCaptureSettingsRepository implements SettingsRepository {
  AppStoreCaptureSettingsRepository({
    required String localeCode,
    required String themeMode,
  }) : _settings = SettingsModel(
          themeMode: themeMode,
          localeCode: localeCode,
        );

  SettingsModel _settings;

  @override
  Future<SettingsModel> loadSettings() async => _settings;

  @override
  Future<void> saveSettings(SettingsModel settings) async {
    _settings = settings;
  }
}
