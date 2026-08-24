//
//  settings_storage.dart
//  Turing Lab
//
//  Declares the application preferences storage interface and concrete
//  implementations using SharedPreferences and in-memory maps to persist
//  symbols, themes, and other user-controlled settings.
//  The abstraction supports dependency injection, simplifies unit tests, and
//  hides platform-specific details when handling key-value storage.
//
//  Thales Matheus Mendonça Santos - October 2025
//
import 'package:shared_preferences/shared_preferences.dart';

/// Key-value storage interface used by the settings repository.
abstract class SettingsStorage {
  Future<String?> readString(String key);
  Future<bool?> readBool(String key);
  Future<double?> readDouble(String key);

  Future<bool> writeString(String key, String value);
  Future<bool> writeBool(String key, bool value);
  Future<bool> writeDouble(String key, double value);
  Future<bool> remove(String key);
}

/// [SettingsStorage] backed by [SharedPreferences].
class SharedPreferencesSettingsStorage implements SettingsStorage {
  const SharedPreferencesSettingsStorage({
    Future<SharedPreferences> Function()? preferencesProvider,
  }) : _preferencesProvider = preferencesProvider;

  final Future<SharedPreferences> Function()? _preferencesProvider;

  Future<SharedPreferences> _getPreferences() {
    final provider = _preferencesProvider;
    if (provider != null) {
      return provider();
    }
    return SharedPreferences.getInstance();
  }

  @override
  Future<String?> readString(String key) async {
    final prefs = await _getPreferences();
    return prefs.getString(key);
  }

  @override
  Future<bool?> readBool(String key) async {
    final prefs = await _getPreferences();
    return prefs.getBool(key);
  }

  @override
  Future<double?> readDouble(String key) async {
    final prefs = await _getPreferences();
    return prefs.getDouble(key);
  }

  @override
  Future<bool> writeString(String key, String value) async {
    final prefs = await _getPreferences();
    return prefs.setString(key, value);
  }

  @override
  Future<bool> writeBool(String key, bool value) async {
    final prefs = await _getPreferences();
    return prefs.setBool(key, value);
  }

  @override
  Future<bool> writeDouble(String key, double value) async {
    final prefs = await _getPreferences();
    return prefs.setDouble(key, value);
  }

  @override
  Future<bool> remove(String key) async {
    final prefs = await _getPreferences();
    return prefs.remove(key);
  }
}
