//
//  settings_provider.dart
//  Turing Lab
//
//  Expõe um StateNotifier responsável por carregar, atualizar e persistir o
//  SettingsModel da aplicação, abstraindo o repositório subjacente baseado em
//  SharedPreferences e garantindo sincronização segura das preferências com a
//  árvore de widgets e seus testes.
//
//  Thales Matheus Mendonça Santos - October 2025
//
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/models/settings_model.dart';
import '../../core/repositories/settings_repository.dart';
import '../../injection/data_providers.dart';

/// Provider that exposes the persisted [SettingsModel] to the widget tree.
final settingsProvider = StateNotifierProvider<SettingsNotifier, SettingsModel>(
  (ref) {
    final repository = ref.watch(settingsRepositoryProvider);
    final notifier = SettingsNotifier(repository);
    return notifier;
  },
);

/// State notifier responsible for reading and persisting [SettingsModel].
class SettingsNotifier extends StateNotifier<SettingsModel> {
  SettingsNotifier(this._repository) : super(const SettingsModel()) {
    _loadFromRepository();
  }

  final SettingsRepository _repository;
  bool _disposed = false;

  Future<void> _loadFromRepository() async {
    try {
      final loaded = await _repository.loadSettings();
      if (_disposed) return;
      state = loaded;
    } catch (error, stackTrace) {
      debugPrint('Failed to load settings: $error');
      debugPrintStack(stackTrace: stackTrace);
    }
  }

  Future<void> refreshFromModel(SettingsModel settings) async {
    if (_disposed) return;
    state = settings;
  }

  Future<void> update(SettingsModel settings) async {
    if (_disposed) return;
    state = settings;
    try {
      await _repository.saveSettings(settings);
    } catch (error, stackTrace) {
      debugPrint('Failed to save settings: $error');
      debugPrintStack(stackTrace: stackTrace);
    }
  }

  Future<void> resetToDefaults() async {
    const defaults = SettingsModel();
    await update(defaults);
  }

  @override
  void dispose() {
    _disposed = true;
    super.dispose();
  }
}
