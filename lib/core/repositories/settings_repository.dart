//
//  settings_repository.dart
//  Turing Lab
//
//  Defines the access interface for saved user settings, standardizing how
//  preferences are loaded and persisted across sessions. Serves as an
//  extension point for concrete local or remote storage providers.
//
//  Thales Matheus Mendonça Santos - October 2025
//

import '../models/settings_model.dart';

/// Repository contract for persisting and retrieving user settings.
abstract class SettingsRepository {
  /// Loads previously saved settings or returns defaults when unavailable.
  Future<SettingsModel> loadSettings();

  /// Persists the provided [settings].
  Future<void> saveSettings(SettingsModel settings);
}
