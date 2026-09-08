import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:shared_preferences_platform_interface/shared_preferences_platform_interface.dart';
import 'package:turing_lab/core/algorithms/grammar/grammar_analyzer.dart';
import 'package:turing_lab/core/algorithms/grammar/lr1_parser.dart';
import 'package:turing_lab/core/grammar/teaching/grammar_teaching_sessions.dart';
import 'package:turing_lab/core/models/grammar.dart';
import 'package:turing_lab/core/models/production.dart';
import 'package:turing_lab/data/services/grammar_teaching_session_store.dart';

void main() {
  test(
    'persists normalization and parse-table histories by grammar revision',
    () async {
      SharedPreferences.setMockInitialValues(const {});
      final preferences = await SharedPreferences.getInstance();
      final store = SharedPreferencesGrammarTeachingSessionStore(preferences);
      final grammar = _grammar();
      final normalization = NormalizationTeachingSession.start(
        grammar,
      ).updateDraft('S -> a').validateCurrent();
      final table = GrammarAnalyzer.buildLL1ParseTable(grammar).data!.value;
      final parse = ParseTableTeachingSession.fromLl1(grammar, table);
      final cell = parse.references.values.first;
      final edited = parse.editCell(cell.key, cell.alternatives.first.id);

      await store.saveNormalization(normalization);
      await store.saveParseTable(edited);

      final restoredNormalization = store.loadNormalization(grammar);
      final restoredParse = store.loadLl1(grammar, table);
      expect(
        restoredNormalization!.currentState.drafts,
        normalization.currentState.drafts,
      );
      expect(restoredNormalization.canUndo, isTrue);
      expect(restoredParse!.draftFor(cell.key), cell.alternatives.first.id);

      final changed = grammar.copyWith(
        productions: {
          ...grammar.productions,
          const Production(id: 'p1', leftSide: ['S'], rightSide: ['b']),
        },
      );
      expect(store.loadNormalization(changed), isNull);
    },
  );

  test('saving a session drops the sessions of superseded revisions', () async {
    SharedPreferences.setMockInitialValues(const {});
    final preferences = await SharedPreferences.getInstance();
    final store = SharedPreferencesGrammarTeachingSessionStore(preferences);
    final grammar = _grammar();
    final changed = grammar.copyWith(
      productions: {
        ...grammar.productions,
        const Production(id: 'p1', leftSide: ['S'], rightSide: ['b']),
      },
    );
    String keysFor(String kind) => preferences
        .getKeys()
        .where((key) => key.startsWith('grammar_teaching_session.v1.$kind.'))
        .join(',');

    await store.saveNormalization(NormalizationTeachingSession.start(grammar));
    await store.saveNormalization(NormalizationTeachingSession.start(changed));

    expect(keysFor('normalization').split(',').length, 1);
    expect(store.loadNormalization(grammar), isNull);
    expect(store.loadNormalization(changed), isNotNull);

    final table = GrammarAnalyzer.buildLL1ParseTable(grammar).data!.value;
    await store.saveParseTable(
      ParseTableTeachingSession.fromLl1(grammar, table),
    );
    final changedTable = GrammarAnalyzer.buildLL1ParseTable(
      changed,
    ).data!.value;
    await store.saveParseTable(
      ParseTableTeachingSession.fromLl1(changed, changedTable),
    );

    expect(keysFor('parse.ll1').split(',').length, 1);
    expect(store.loadLl1(grammar, table), isNull);
    expect(store.loadLl1(changed, changedTable), isNotNull);
  });

  test('grammar ids that share a prefix keep separate sessions', () async {
    SharedPreferences.setMockInitialValues(const {});
    final preferences = await SharedPreferences.getInstance();
    final store = SharedPreferencesGrammarTeachingSessionStore(preferences);
    final short = _grammar().copyWith(id: 'a');
    final dotted = _grammar().copyWith(id: 'a.1');

    await store.saveNormalization(NormalizationTeachingSession.start(dotted));
    await store.saveNormalization(NormalizationTeachingSession.start(short));

    expect(store.loadNormalization(dotted), isNotNull);
    expect(store.loadNormalization(short), isNotNull);
    expect(
      preferences.getKeys().where((key) => key.contains('normalization')),
      hasLength(2),
    );
  });

  for (final id in ['legacy.id', 'legacy%id']) {
    test('migrates all legacy session kinds for $id', () async {
      SharedPreferences.setMockInitialValues(const {});
      final preferences = await SharedPreferences.getInstance();
      final store = SharedPreferencesGrammarTeachingSessionStore(preferences);
      final grammar = _grammar().copyWith(id: id);
      final normal = NormalizationTeachingSession.start(grammar);
      final ll1 = GrammarAnalyzer.buildLL1ParseTable(grammar).data!.value;
      final lr1 = LR1Parser.build(grammar).construction!;
      final sessions = {
        'normalization': normal.toJson(),
        'parse.ll1': ParseTableTeachingSession.fromLl1(grammar, ll1).toJson(),
        'parse.lr1': ParseTableTeachingSession.fromLr1(grammar, lr1).toJson(),
      };
      for (final entry in sessions.entries) {
        await preferences.setString(
          'grammar_teaching_session.v1.${entry.key}.$id.${normal.sourceRevision}',
          jsonEncode(entry.value),
        );
      }
      expect(store.loadNormalization(grammar), isNotNull);
      expect(store.loadLl1(grammar, ll1), isNotNull);
      expect(store.loadLr1(grammar, lr1), isNotNull);
      await Future<void>.delayed(Duration.zero);
      final encoded = id.replaceAll('%', '%25').replaceAll('.', '%2E');
      for (final kind in sessions.keys) {
        expect(
          preferences.containsKey(
            'grammar_teaching_session.v1.$kind.$id.${normal.sourceRevision}',
          ),
          isFalse,
        );
        expect(
          preferences.containsKey(
            'grammar_teaching_session.v1.$kind.$encoded.${normal.sourceRevision}',
          ),
          isTrue,
        );
      }
    });
  }

  test(
    'legacy cleanup preserves dotted children and encoded ID collisions',
    () async {
      SharedPreferences.setMockInitialValues(const {});
      final preferences = await SharedPreferences.getInstance();
      final store = SharedPreferencesGrammarTeachingSessionStore(preferences);
      final grammar = _grammar().copyWith(id: 'a');
      final dotted = grammar.copyWith(id: 'a.1');
      final old = NormalizationTeachingSession.start(grammar);
      final child = NormalizationTeachingSession.start(dotted);
      const prefix = 'grammar_teaching_session.v1.normalization';
      await preferences.setString(
        '$prefix.a.1.${child.sourceRevision}',
        jsonEncode(child.toJson()),
      );
      await store.saveNormalization(old);
      expect(
        preferences.containsKey('$prefix.a.1.${child.sourceRevision}'),
        isTrue,
      );
      await store.saveNormalization(child);
      expect(
        preferences.containsKey('$prefix.a.1.${child.sourceRevision}'),
        isFalse,
      );
      expect(store.loadNormalization(dotted), isNotNull);
      final collision = grammar.copyWith(id: 'a%2E1');
      expect(store.loadNormalization(collision), isNull);
      await store.saveNormalization(
        NormalizationTeachingSession.start(collision),
      );
      expect(store.loadNormalization(dotted), isNotNull);
      expect(store.loadNormalization(collision), isNotNull);
    },
  );

  test('failed legacy migration retains the persisted raw key', () async {
    SharedPreferences.setMockInitialValues(const {});
    final platform = _FailingStore();
    SharedPreferencesStorePlatform.instance = platform;
    addTearDown(() => SharedPreferences.setMockInitialValues(const {}));
    final preferences = await SharedPreferences.getInstance();
    final store = SharedPreferencesGrammarTeachingSessionStore(preferences);
    final grammar = _grammar().copyWith(id: 'legacy.id');
    final session = NormalizationTeachingSession.start(grammar);
    final key =
        'grammar_teaching_session.v1.normalization.legacy.id.${session.sourceRevision}';
    await preferences.setString(key, jsonEncode(session.toJson()));
    platform.failWrites = true;
    expect(store.loadNormalization(grammar), isNotNull);
    await Future<void>.delayed(Duration.zero);
    expect(preferences.containsKey(key), isTrue);
  });

  test('a failed write keeps the previous revision loadable', () async {
    SharedPreferences.setMockInitialValues(const {});
    final platform = _FailingStore();
    SharedPreferencesStorePlatform.instance = platform;
    addTearDown(() => SharedPreferences.setMockInitialValues(const {}));
    final preferences = await SharedPreferences.getInstance();
    final store = SharedPreferencesGrammarTeachingSessionStore(preferences);
    final grammar = _grammar();
    final changed = grammar.copyWith(
      productions: {
        ...grammar.productions,
        const Production(id: 'p1', leftSide: ['S'], rightSide: ['b']),
      },
    );

    expect(
      await store.saveNormalization(
        NormalizationTeachingSession.start(grammar),
      ),
      isTrue,
    );
    platform.failWrites = true;
    expect(
      await store.saveNormalization(
        NormalizationTeachingSession.start(changed),
      ),
      isFalse,
    );

    // The previous revision is still stored; the plugin cache keeps the
    // rejected value in memory, so only the survivor is asserted.
    expect(store.loadNormalization(grammar), isNotNull);
  });
}

/// In-memory preferences whose writes can be made to report failure.
class _FailingStore extends InMemorySharedPreferencesStore {
  _FailingStore() : super.empty();

  bool failWrites = false;

  @override
  Future<bool> setValue(String valueType, String key, Object value) async {
    if (failWrites) return false;
    return super.setValue(valueType, key, value);
  }
}

Grammar _grammar() => Grammar(
  id: 'teaching-store',
  name: 'Teaching store',
  terminals: const {'a', 'b'},
  nonterminals: const {'S'},
  startSymbol: 'S',
  productions: {
    const Production(id: 'p0', leftSide: ['S'], rightSide: ['a']),
  },
  type: GrammarType.contextFree,
  created: DateTime.utc(2026),
  modified: DateTime.utc(2026),
);
