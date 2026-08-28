import '../../algorithms/grammar_analyzer.dart';
import '../../models/grammar.dart';
import '../../models/lr1_models.dart';
import 'grammar_teaching_sessions.dart';

abstract interface class GrammarTeachingSessionStore {
  Future<bool> saveNormalization(NormalizationTeachingSession session);

  NormalizationTeachingSession? loadNormalization(Grammar grammar);

  Future<bool> saveParseTable(ParseTableTeachingSession session);

  ParseTableTeachingSession? loadLl1(Grammar grammar, LL1ParseTable table);

  ParseTableTeachingSession? loadLr1(
    Grammar grammar,
    LR1Construction construction,
  );
}
