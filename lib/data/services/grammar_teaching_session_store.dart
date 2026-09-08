import 'dart:async';
import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../../core/algorithms/grammar/grammar_analyzer.dart';
import '../../core/grammar/phrase_structure/legacy_context_free_grammar_adapter.dart';
import '../../core/grammar/teaching/grammar_teaching_session_store.dart';
import '../../core/grammar/teaching/grammar_teaching_sessions.dart';
import '../../core/models/grammar.dart';
import '../../core/models/lr1_models.dart';

class SharedPreferencesGrammarTeachingSessionStore
    implements GrammarTeachingSessionStore {
  const SharedPreferencesGrammarTeachingSessionStore(this._preferences);

  static const _prefix = 'grammar_teaching_session.v1';
  final SharedPreferences _preferences;

  @override
  Future<bool> saveNormalization(NormalizationTeachingSession session) => _save(
    'normalization',
    session.sourceGrammarId,
    session.sourceRevision,
    session.toJson(),
  );

  @override
  NormalizationTeachingSession? loadNormalization(Grammar grammar) {
    final encoded = _load('normalization', grammar);
    if (encoded == null) return null;
    return NormalizationTeachingSession.restore(
      encoded,
      grammar: grammar,
    ).session;
  }

  @override
  Future<bool> saveParseTable(ParseTableTeachingSession session) => _save(
    'parse.${session.kind.name}',
    session.sourceGrammarId,
    session.sourceRevision,
    session.toJson(),
  );

  @override
  ParseTableTeachingSession? loadLl1(Grammar grammar, LL1ParseTable table) {
    final encoded = _load('parse.ll1', grammar);
    if (encoded == null) return null;
    return ParseTableTeachingSession.restoreLl1(
      encoded,
      grammar: grammar,
      table: table,
    ).session;
  }

  @override
  ParseTableTeachingSession? loadLr1(
    Grammar grammar,
    LR1Construction construction,
  ) {
    final encoded = _load('parse.lr1', grammar);
    if (encoded == null) return null;
    return ParseTableTeachingSession.restoreLr1(
      encoded,
      grammar: grammar,
      construction: construction,
    ).session;
  }

  /// Writes the session under its revision key and drops the sessions this
  /// grammar stored under earlier revisions, so edits never accumulate
  /// unreachable entries.
  Future<bool> _save(
    String kind,
    String grammarId,
    int revision,
    Map<String, Object?> json,
  ) async {
    final key = _key(kind, grammarId, revision);
    // The new revision is written first, so a failed write keeps the previous
    // session loadable instead of leaving the grammar with none.
    if (!await _preferences.setString(key, jsonEncode(json))) return false;
    final legacyKey = _rawKey(kind, grammarId, revision);
    final encodedPrefix = key.substring(0, key.lastIndexOf('.') + 1);
    final legacyPrefix = legacyKey.substring(0, legacyKey.lastIndexOf('.') + 1);
    final superseded = _preferences.getKeys().where((other) {
      if (other == key) return false;
      // Match the complete revision segment, not a dotted child grammar ID.
      final matches = [encodedPrefix, legacyPrefix].any(
        (prefix) =>
            other.startsWith(prefix) &&
            int.tryParse(other.substring(prefix.length)) != null,
      );
      if (!matches) return false;
      final value = _read(other);
      return value is Map && value['sourceGrammarId'] == grammarId;
    }).toList();
    for (final other in superseded) {
      await _preferences.remove(other);
    }
    return true;
  }

  Object? _load(String kind, Grammar grammar) {
    final revision = _revision(grammar);
    final key = _key(kind, grammar.id, revision);
    final current = _read(key);
    if (current != null) return current;
    final legacyKey = _rawKey(kind, grammar.id, revision);
    if (legacyKey == key) return null;
    final legacy = _read(legacyKey);
    // A raw percent-containing ID can coincide with another ID's encoded key.
    if (legacy is! Map || legacy['sourceGrammarId'] != grammar.id) return null;
    unawaited(_migrate(key, legacyKey, _preferences.getString(legacyKey)!));
    return legacy;
  }

  Future<void> _migrate(String key, String legacyKey, String value) async {
    try {
      if (await _preferences.setString(key, value) &&
          _preferences.getString(legacyKey) == value) {
        await _preferences.remove(legacyKey);
      }
    } catch (_) {
      // Loading remains synchronous; a failed migration retains the old value.
    }
  }

  Object? _read(String key) {
    final raw = _preferences.getString(key);
    if (raw == null) return null;
    try {
      return jsonDecode(raw);
    } on FormatException {
      return null;
    }
  }

  static int _revision(Grammar grammar) =>
      LegacyContextFreeGrammarAdapter.sourceRevision(grammar);

  static String _key(String kind, String rawGrammarId, int revision) =>
      _rawKey(kind, _encodeGrammarId(rawGrammarId), revision);

  static String _rawKey(String kind, String grammarId, int revision) =>
      '$_prefix.$kind.$grammarId.$revision';

  /// Escapes the key delimiter so grammar ids that contain `.` occupy their
  /// own key space; ids without it keep the keys stored before this encoding.
  static String _encodeGrammarId(String grammarId) =>
      grammarId.replaceAll('%', '%25').replaceAll('.', '%2E');
}
