import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../core/utils/epsilon_utils.dart';
import '../../injection/data_providers.dart';
import '../empty_string_notation.dart';

const String kEmptyStringSymbolPreferenceKey = 'settings_empty_string_symbol';
const String kLegacyEpsilonSymbolPreferenceKey = 'settings_epsilon_symbol';

final emptyStringSymbolProvider =
    StateNotifierProvider<EmptyStringSymbolNotifier, String>((ref) {
      return EmptyStringSymbolNotifier(
        SharedPreferencesEmptyStringSymbolStore(
          ref.watch(sharedPreferencesProvider),
        ),
      );
    });

abstract interface class EmptyStringSymbolStore {
  String? getString(String key);
  Future<bool> setString(String key, String value);
  Future<bool> remove(String key);
}

class SharedPreferencesEmptyStringSymbolStore
    implements EmptyStringSymbolStore {
  const SharedPreferencesEmptyStringSymbolStore(this._preferences);

  final SharedPreferences _preferences;

  @override
  String? getString(String key) => _preferences.getString(key);

  @override
  Future<bool> remove(String key) => _preferences.remove(key);

  @override
  Future<bool> setString(String key, String value) =>
      _preferences.setString(key, value);
}

String readEmptyStringSymbolPreference(EmptyStringSymbolStore store) {
  final current = store.getString(kEmptyStringSymbolPreferenceKey);
  if (kSupportedEmptyStringSymbols.contains(current)) {
    return current!;
  }
  final legacy = store.getString(kLegacyEpsilonSymbolPreferenceKey);
  return kSupportedEmptyStringSymbols.contains(legacy)
      ? legacy!
      : kEpsilonSymbol;
}

/// Migrates the legacy preference without removing the only valid value first.
Future<String> migrateEmptyStringSymbolPreferences(
  EmptyStringSymbolStore store,
) async {
  final current = store.getString(kEmptyStringSymbolPreferenceKey);
  final legacy = store.getString(kLegacyEpsilonSymbolPreferenceKey);
  final resolved = kSupportedEmptyStringSymbols.contains(current)
      ? current!
      : kSupportedEmptyStringSymbols.contains(legacy)
      ? legacy!
      : kEpsilonSymbol;

  if (current != resolved) {
    try {
      if (!await store.setString(kEmptyStringSymbolPreferenceKey, resolved)) {
        return resolved;
      }
    } catch (_) {
      return resolved;
    }
  }

  if (legacy != null) {
    try {
      await store.remove(kLegacyEpsilonSymbolPreferenceKey);
    } catch (_) {
      // The valid current key has precedence; stale-key cleanup is best effort.
    }
  }
  return resolved;
}

class EmptyStringSymbolNotifier extends StateNotifier<String> {
  EmptyStringSymbolNotifier(this._store)
    : super(readEmptyStringSymbolPreference(_store));

  final EmptyStringSymbolStore _store;
  Future<void> _saveQueue = Future<void>.value();

  Future<void> setSymbol(String symbol) {
    final resolved = normalizeEmptyStringDisplaySymbol(symbol);
    final operation = _saveQueue.then((_) async {
      final saved = await _store.setString(
        kEmptyStringSymbolPreferenceKey,
        resolved,
      );
      if (!saved) {
        throw StateError('Unable to persist empty-string notation.');
      }
      state = resolved;
      try {
        await _store.remove(kLegacyEpsilonSymbolPreferenceKey);
      } catch (_) {
        // The current key is valid and wins over a stale legacy key.
      }
    });
    _saveQueue = operation.then<void>((_) {}, onError: (_, _) {});
    return operation;
  }

  Future<void> reset() => setSymbol(kEpsilonSymbol);
}
