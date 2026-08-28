import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../../core/repositories/active_session_repository.dart';
import '../../core/formal_systems/formal_systems.dart';
import 'active_session_snapshot_codec.dart';

export '../../core/repositories/active_session_repository.dart'
    show
        ActiveSessionPersistenceException,
        ActiveSessionRepository,
        ActiveSessionSnapshot,
        RegexSessionSnapshot,
        UnsupportedActiveSessionSchemaVersionException,
        UnsupportedActiveSessionVersionException;

class ActiveSessionPersistenceService implements ActiveSessionRepository {
  ActiveSessionPersistenceService(
    this._prefs, {
    FormalSystemRegistry? registry,
  }) : _codec = ActiveSessionSnapshotCodec(registry: registry);

  static const String sessionKey = 'active_editor_session';
  static const String autoSaveKey = 'settings_auto_save';

  static String unsupportedSessionBackupKey(int version) =>
      '${sessionKey}_unsupported_v$version';

  static String unsupportedSchemaBackupKey(
    FormalSystemKey key,
    int version,
  ) =>
      '${sessionKey}_unsupported_${key.type.value}_${key.variant.value}_v$version';

  final SharedPreferences _prefs;
  final ActiveSessionSnapshotCodec _codec;

  @override
  bool get autoSaveEnabled => _prefs.getBool(autoSaveKey) ?? true;

  @override
  Future<void> saveSession(ActiveSessionSnapshot session) async {
    final succeeded =
        await _prefs.setString(sessionKey, jsonEncode(_codec.encode(session)));
    if (!succeeded) {
      throw const ActiveSessionPersistenceException('save');
    }
  }

  @override
  Future<ActiveSessionSnapshot?> loadSession() async {
    final payload = _prefs.getString(sessionKey);
    if (payload == null || payload.isEmpty) {
      return null;
    }

    try {
      final decoded = jsonDecode(payload);
      if (decoded is! Map) {
        await clearSession();
        return null;
      }
      final sessionJson = decoded.cast<String, dynamic>();
      final storedVersion = sessionJson['version'] as int? ?? 0;
      final session = _codec.decode(sessionJson);
      if (storedVersion != ActiveSessionSnapshot.currentVersion) {
        await saveSession(session);
      }
      return session;
    } on UnsupportedActiveSessionVersionException catch (error) {
      final succeeded = await _prefs.setString(
        unsupportedSessionBackupKey(error.version),
        payload,
      );
      if (!succeeded) {
        throw const ActiveSessionPersistenceException(
          'backup_unsupported_version',
        );
      }
      rethrow;
    } on UnsupportedActiveSessionSchemaVersionException catch (error) {
      final succeeded = await _prefs.setString(
        unsupportedSchemaBackupKey(error.systemKey, error.version),
        payload,
      );
      if (!succeeded) {
        throw const ActiveSessionPersistenceException(
          'backup_unsupported_schema',
        );
      }
      rethrow;
    } on ActiveSessionPersistenceException {
      rethrow;
    } catch (_) {
      await clearSession();
      return null;
    }
  }

  @override
  Future<void> clearSession() async {
    final succeeded = await _prefs.remove(sessionKey);
    if (!succeeded) {
      throw const ActiveSessionPersistenceException('clear');
    }
  }
}
