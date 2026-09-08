import 'dart:ui';

import 'package:flutter_test/flutter_test.dart';
import 'package:turing_lab/core/algorithms/grammar/grammar_analyzer.dart';
import 'package:turing_lab/core/grammar/phrase_structure/phrase_structure.dart';
import 'package:turing_lab/core/models/grammar.dart';
import 'package:turing_lab/core/models/production.dart';
import 'package:turing_lab/l10n/app_localizations.dart';
import 'package:turing_lab/presentation/widgets/grammar_algorithm/chomsky_classification_section.dart';
import 'package:turing_lab/presentation/widgets/grammar_algorithm/grammar_analysis_result_formatter.dart';

void main() {
  final en = lookupAppLocalizations(const Locale('en'));
  final pt = lookupAppLocalizations(const Locale('pt'));
  final now = DateTime(2026);

  Grammar grammar(Iterable<Production> productions) => Grammar(
    id: 'g',
    name: 'G',
    terminals: {'a', 'b'},
    nonterminals: {'S', 'A'},
    startSymbol: 'S',
    productions: productions.toSet(),
    type: GrammarType.contextFree,
    created: now,
    modified: now,
  );

  group('GrammarAnalysisResultFormatter', () {
    final formatter = GrammarAnalysisResultFormatter(en);

    test('groups productions by nonterminal in order', () {
      final text = formatter.formatGrammar(
        grammar(const [
          Production(id: '1', leftSide: ['S'], rightSide: ['a', 'S'], order: 0),
          Production(
            id: '2',
            leftSide: ['S'],
            rightSide: [],
            isLambda: true,
            order: 1,
          ),
          Production(id: '3', leftSide: ['A'], rightSide: ['b'], order: 2),
        ]),
      );
      expect(text.split('\n'), ['A → b', 'S → a S | ε']);
    });

    test('renders FIRST sets and notes sections', () {
      final text = formatter.formatSets(
        title: en.firstSetsAnalysisTitle,
        setName: 'FIRST',
        sets: {
          'S': {'a', 'b'},
        },
        notes: const ['note'],
        derivations: const [],
      );
      expect(text, contains('FIRST(S) = {a, b}'));
      expect(text, contains('${en.notesSection}:\n- note'));
      expect(text, isNot(contains(en.derivationsSection)));
    });

    test('ambiguity result uses the localized classification', () {
      final text = formatter.formatAmbiguity(
        const GrammarAnalysisReport<bool>(value: true),
      );
      expect(text, contains(en.ll1NoConflicts));
    });

    test('error listing keeps one bullet per message', () {
      expect(
        formatter.formatError('Heading', const ['one', 'two']),
        'Heading\n\n- one\n- two\n',
      );
    });
  });

  group('GrammarClassificationFormatter', () {
    test('labels follow the locale', () {
      final english = GrammarClassificationFormatter(
        strings: en,
        locale: const Locale('en'),
      );
      final portuguese = GrammarClassificationFormatter(
        strings: pt,
        locale: const Locale('pt'),
      );
      expect(
        english.label(PhraseGrammarClassification.contextFree),
        'context-free',
      );
      expect(
        portuguese.label(PhraseGrammarClassification.contextFree),
        'livre de contexto',
      );
    });

    test('legacy type mapping has no value for invalid grammars', () {
      expect(
        GrammarClassificationFormatter.toLegacyType(
          PhraseGrammarClassification.regular,
        ),
        GrammarType.regular,
      );
      expect(
        GrammarClassificationFormatter.toLegacyType(
          PhraseGrammarClassification.invalid,
        ),
        isNull,
      );
    });

    test('formats a report with the inferred and declared types', () {
      final report = PhraseGrammarClassifier.classifyLegacy(
        grammar(const [
          Production(id: '1', leftSide: ['S'], rightSide: ['a', 'S']),
          Production(id: '2', leftSide: ['S'], rightSide: ['b']),
        ]),
      );
      final text = GrammarClassificationFormatter(
        strings: en,
        locale: const Locale('en'),
      ).format(report);
      expect(text, startsWith(en.classifyGrammarTitle));
      expect(text, contains('${en.inferredGrammarType}: regular'));
      expect(text, contains('${en.declaredGrammarType}: context-free'));
    });
  });
}
