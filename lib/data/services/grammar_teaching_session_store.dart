import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../../core/algorithms/grammar_analyzer.dart';
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
  Future<bool> saveNormalization(NormalizationTeachingSession session) =>
      _preferences.setString(
        _key(
          'normalization',
          session.sourceGrammarId,
          session.sourceRevision,
        ),
        jsonEncode(session.toJson()),
      );

  @override
  NormalizationTeachingSession? loadNormalization(Grammar grammar) {
    final encoded = _read(
      _key('normalization', grammar.id, _revision(grammar)),
    );
    if (encoded == null) return null;
    return NormalizationTeachingSession.restore(
      encoded,
      grammar: grammar,
    ).session;
  }

  @override
  Future<bool> saveParseTable(ParseTableTeachingSession session) =>
      _preferences.setString(
        _key(
          'parse.${session.kind.name}',
          session.sourceGrammarId,
          session.sourceRevision,
        ),
        jsonEncode(session.toJson()),
      );

  @override
  ParseTableTeachingSession? loadLl1(
    Grammar grammar,
    LL1ParseTable table,
  ) {
    final encoded = _read(_key('parse.ll1', grammar.id, _revision(grammar)));
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
    final encoded = _read(_key('parse.lr1', grammar.id, _revision(grammar)));
    if (encoded == null) return null;
    return ParseTableTeachingSession.restoreLr1(
      encoded,
      grammar: grammar,
      construction: construction,
    ).session;
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

  static String _key(String kind, String grammarId, int revision) =>
      '$_prefix.$kind.$grammarId.$revision';
}
