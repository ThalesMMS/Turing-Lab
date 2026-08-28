import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:turing_lab/core/algorithms/grammar_analyzer.dart';
import 'package:turing_lab/core/grammar/teaching/grammar_teaching_sessions.dart';
import 'package:turing_lab/core/models/grammar.dart';
import 'package:turing_lab/core/models/production.dart';
import 'package:turing_lab/data/services/grammar_teaching_session_store.dart';

void main() {
  test('persists normalization and parse-table histories by grammar revision',
      () async {
    SharedPreferences.setMockInitialValues(const {});
    final preferences = await SharedPreferences.getInstance();
    final store = SharedPreferencesGrammarTeachingSessionStore(preferences);
    final grammar = _grammar();
    final normalization = NormalizationTeachingSession.start(grammar)
        .updateDraft('S -> a')
        .validateCurrent();
    final table = GrammarAnalyzer.buildLL1ParseTable(grammar).data!.value;
    final parse = ParseTableTeachingSession.fromLl1(grammar, table);
    final cell = parse.references.values.first;
    final edited = parse.editCell(cell.key, cell.alternatives.first.id);

    await store.saveNormalization(normalization);
    await store.saveParseTable(edited);

    final restoredNormalization = store.loadNormalization(grammar);
    final restoredParse = store.loadLl1(grammar, table);
    expect(restoredNormalization!.currentState.drafts,
        normalization.currentState.drafts);
    expect(restoredNormalization.canUndo, isTrue);
    expect(restoredParse!.draftFor(cell.key), cell.alternatives.first.id);

    final changed = grammar.copyWith(
      productions: {
        ...grammar.productions,
        const Production(
          id: 'p1',
          leftSide: ['S'],
          rightSide: ['b'],
        ),
      },
    );
    expect(store.loadNormalization(changed), isNull);
  });
}

Grammar _grammar() => Grammar(
      id: 'teaching-store',
      name: 'Teaching store',
      terminals: const {'a', 'b'},
      nonterminals: const {'S'},
      startSymbol: 'S',
      productions: {
        const Production(
          id: 'p0',
          leftSide: ['S'],
          rightSide: ['a'],
        ),
      },
      type: GrammarType.contextFree,
      created: DateTime.utc(2026),
      modified: DateTime.utc(2026),
    );
