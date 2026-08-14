//
//  settings_repository_impl.dart
//  Turing Lab
//
//  Persiste preferências de interface e símbolos no SharedPreferences por meio de uma camada de repositório que aplica padrões e sincroniza o modelo de configurações.
//
//  Thales Matheus Mendonça Santos - October 2025
//
import 'package:shared_preferences/shared_preferences.dart'
    show SharedPreferences;

import '../../core/models/settings_model.dart';
import '../../core/repositories/settings_repository.dart';
import '../storage/settings_storage.dart';

/// Settings repository backed by [SharedPreferences].
class SharedPreferencesSettingsRepository implements SettingsRepository {
  SharedPreferencesSettingsRepository({SettingsStorage? storage})
      : _storage = storage ?? const SharedPreferencesSettingsStorage();

  static const String _emptyStringSymbolKey = 'settings_empty_string_symbol';
  static const String _legacyEpsilonSymbolKey = 'settings_epsilon_symbol';
  static const String _themeModeKey = 'settings_theme_mode';
  static const String _localeCodeKey = 'settings_locale_code';
  static const String _showGridKey = 'settings_show_grid';
  static const String _showCoordinatesKey = 'settings_show_coordinates';
  static const String _autoSaveKey = 'settings_auto_save';
  static const String _showTooltipsKey = 'settings_show_tooltips';
  static const String _gridSizeKey = 'settings_grid_size';
  static const String _nodeSizeKey = 'settings_node_size';
  static const String _fontSizeKey = 'settings_font_size';
  static const String _animationSpeedKey = 'settings_animation_speed';
  static const Set<String> _supportedThemeModes = {'system', 'light', 'dark'};
  static const Set<String> _supportedLocaleCodes = {'en', 'pt'};
  final SettingsStorage _storage;
  Future<void> _saveQueue = Future<void>.value();

  @override
  Future<SettingsModel> loadSettings() async {
    const defaults = SettingsModel();
    await _discardLegacyEpsilonSymbol();

    final settings = SettingsModel(
      emptyStringSymbol: await _readStringSetting(
        _emptyStringSymbolKey,
        defaults.emptyStringSymbol,
      ),
      themeMode: await _readStringSetting(
        _themeModeKey,
        defaults.themeMode,
        isValid: _supportedThemeModes.contains,
      ),
      localeCode: await _readNullableStringSetting(
        _localeCodeKey,
        isValid: _supportedLocaleCodes.contains,
      ),
      showGrid: await _readBoolSetting(_showGridKey, defaults.showGrid),
      showCoordinates: await _readBoolSetting(
        _showCoordinatesKey,
        defaults.showCoordinates,
      ),
      autoSave: await _readBoolSetting(_autoSaveKey, defaults.autoSave),
      showTooltips: await _readBoolSetting(
        _showTooltipsKey,
        defaults.showTooltips,
      ),
      gridSize: await _readDoubleSetting(_gridSizeKey, defaults.gridSize),
      nodeSize: await _readDoubleSetting(_nodeSizeKey, defaults.nodeSize),
      fontSize: await _readDoubleSetting(_fontSizeKey, defaults.fontSize),
      animationSpeed: await _readDoubleSetting(
        _animationSpeedKey,
        defaults.animationSpeed,
      ),
    );
    return settings;
  }

  Future<void> _discardLegacyEpsilonSymbol() async {
    try {
      await _storage.remove(_legacyEpsilonSymbolKey);
    } catch (_) {
      // A stale, unused preference must not make settings loading fail.
    }
  }

  @override
  Future<void> saveSettings(SettingsModel settings) {
    final pendingSave = _saveQueue.then(
      (_) => _saveSettingsAtomically(settings),
    );
    _saveQueue = pendingSave.then<void>(
      (_) {},
      onError: (Object _, StackTrace __) {},
    );
    return pendingSave;
  }

  Future<void> _saveSettingsAtomically(SettingsModel settings) async {
    final previousValues = await _snapshotPersistedSettings();
    var saved = false;

    try {
      saved = await _writeSettings(settings);
    } catch (_) {
      saved = false;
    }

    if (!saved) {
      try {
        await _restorePersistedSettings(previousValues);
      } catch (_) {
        // Preserve the original save failure even if rollback also fails.
      }
      throw Exception('Failed to save settings');
    }
  }

  Future<bool> _writeSettings(SettingsModel settings) async {
    final writes = <Future<bool> Function()>[
      () => _storage.writeString(
            _emptyStringSymbolKey,
            settings.emptyStringSymbol,
          ),
      () => _storage.writeString(_themeModeKey, settings.themeMode),
      () => settings.localeCode == null
          ? _storage.remove(_localeCodeKey)
          : _storage.writeString(_localeCodeKey, settings.localeCode!),
      () => _storage.writeBool(_showGridKey, settings.showGrid),
      () => _storage.writeBool(_showCoordinatesKey, settings.showCoordinates),
      () => _storage.writeBool(_autoSaveKey, settings.autoSave),
      () => _storage.writeBool(_showTooltipsKey, settings.showTooltips),
      () => _storage.writeDouble(_gridSizeKey, settings.gridSize),
      () => _storage.writeDouble(_nodeSizeKey, settings.nodeSize),
      () => _storage.writeDouble(_fontSizeKey, settings.fontSize),
      () => _storage.writeDouble(
            _animationSpeedKey,
            settings.animationSpeed,
          ),
    ];

    for (final write in writes) {
      if (!await write()) {
        return false;
      }
    }
    return true;
  }

  Future<Map<String, Object?>> _snapshotPersistedSettings() async {
    return <String, Object?>{
      _emptyStringSymbolKey: await _snapshotString(_emptyStringSymbolKey),
      _themeModeKey: await _snapshotString(_themeModeKey),
      _localeCodeKey: await _snapshotString(_localeCodeKey),
      _showGridKey: await _snapshotBool(_showGridKey),
      _showCoordinatesKey: await _snapshotBool(_showCoordinatesKey),
      _autoSaveKey: await _snapshotBool(_autoSaveKey),
      _showTooltipsKey: await _snapshotBool(_showTooltipsKey),
      _gridSizeKey: await _snapshotDouble(_gridSizeKey),
      _nodeSizeKey: await _snapshotDouble(_nodeSizeKey),
      _fontSizeKey: await _snapshotDouble(_fontSizeKey),
      _animationSpeedKey: await _snapshotDouble(_animationSpeedKey),
    };
  }

  Future<String?> _snapshotString(String key) async {
    try {
      return await _storage.readString(key);
    } catch (_) {
      return null;
    }
  }

  Future<bool?> _snapshotBool(String key) async {
    try {
      return await _storage.readBool(key);
    } catch (_) {
      return null;
    }
  }

  Future<double?> _snapshotDouble(String key) async {
    try {
      return await _storage.readDouble(key);
    } catch (_) {
      return null;
    }
  }

  Future<void> _restorePersistedSettings(
    Map<String, Object?> previousValues,
  ) async {
    await Future.wait<bool>([
      _restoreString(_emptyStringSymbolKey, previousValues),
      _restoreString(_themeModeKey, previousValues),
      _restoreString(_localeCodeKey, previousValues),
      _restoreBool(_showGridKey, previousValues),
      _restoreBool(_showCoordinatesKey, previousValues),
      _restoreBool(_autoSaveKey, previousValues),
      _restoreBool(_showTooltipsKey, previousValues),
      _restoreDouble(_gridSizeKey, previousValues),
      _restoreDouble(_nodeSizeKey, previousValues),
      _restoreDouble(_fontSizeKey, previousValues),
      _restoreDouble(_animationSpeedKey, previousValues),
    ]);
  }

  Future<bool> _restoreString(
    String key,
    Map<String, Object?> previousValues,
  ) {
    final value = previousValues[key] as String?;
    return value == null
        ? _storage.remove(key)
        : _storage.writeString(key, value);
  }

  Future<bool> _restoreBool(
    String key,
    Map<String, Object?> previousValues,
  ) {
    final value = previousValues[key] as bool?;
    return value == null
        ? _storage.remove(key)
        : _storage.writeBool(key, value);
  }

  Future<bool> _restoreDouble(
    String key,
    Map<String, Object?> previousValues,
  ) {
    final value = previousValues[key] as double?;
    return value == null
        ? _storage.remove(key)
        : _storage.writeDouble(key, value);
  }

  Future<String> _readStringSetting(
    String key,
    String fallback, {
    bool Function(String value)? isValid,
  }) async {
    try {
      final value = await _storage.readString(key);
      if (value == null) {
        return fallback;
      }
      if (isValid != null && !isValid(value)) {
        return fallback;
      }
      return value;
    } catch (_) {
      return fallback;
    }
  }

  Future<String?> _readNullableStringSetting(
    String key, {
    required bool Function(String value) isValid,
  }) async {
    try {
      final value = await _storage.readString(key);
      return value != null && isValid(value) ? value : null;
    } catch (_) {
      return null;
    }
  }

  Future<bool> _readBoolSetting(String key, bool fallback) async {
    try {
      return await _storage.readBool(key) ?? fallback;
    } catch (_) {
      return fallback;
    }
  }

  Future<double> _readDoubleSetting(String key, double fallback) async {
    try {
      return await _storage.readDouble(key) ?? fallback;
    } catch (_) {
      return fallback;
    }
  }
}
