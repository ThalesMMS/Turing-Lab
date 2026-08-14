//
//  settings_repository.dart
//  Turing Lab
//
//  Define a interface de acesso às configurações salvas do usuário,
//  padronizando como preferências são carregadas e persistidas entre sessões.
//  Serve como ponto de extensão para provedores concretos de armazenamento
//  local ou remoto.
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
