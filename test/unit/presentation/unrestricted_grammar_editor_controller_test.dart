import 'package:flutter_test/flutter_test.dart';
import 'package:turing_lab/core/grammar/phrase_structure/phrase_structure.dart';
import 'package:turing_lab/presentation/unrestricted_grammar/unrestricted_grammar_editor_controller.dart';

void main() {
  group('UnrestrictedGrammarEditorController production order', () {
    test('reorders once with sequential order and stable contents', () {
      final controller = UnrestrictedGrammarEditorController(_grammar());
      final original = {
        for (final production in controller.grammar.productions)
          production.id: (production.left, production.right),
      };
      var notifications = 0;
      controller.addListener(() => notifications++);

      expect(controller.reorderProduction(2, 1), isTrue);

      expect(notifications, 1);
      expect(controller.grammar.revision, 8);
      expect(
        controller.grammar.productions.map((production) => production.id),
        ['p1', 'p3', 'p2'],
      );
      expect(
        controller.grammar.productions.map((production) => production.order),
        [0, 1, 2],
      );
      for (final production in controller.grammar.productions) {
        expect((production.left, production.right), original[production.id]);
      }
    });

    test('undo and redo restore and reapply one reorder', () {
      final controller = UnrestrictedGrammarEditorController(_grammar());

      controller.reorderProduction(2, 0);
      expect(
        controller.grammar.productions.map((production) => production.id),
        ['p3', 'p1', 'p2'],
      );

      controller.undo();
      expect(controller.grammar.revision, 7);
      expect(
        controller.grammar.productions.map((production) => production.id),
        ['p1', 'p2', 'p3'],
      );

      controller.redo();
      expect(controller.grammar.revision, 8);
      expect(
        controller.grammar.productions.map((production) => production.id),
        ['p3', 'p1', 'p2'],
      );
    });

    test('invalid and no-op moves do not mutate or add history', () {
      final controller = UnrestrictedGrammarEditorController(_grammar());
      final before = controller.grammar;
      var notifications = 0;
      controller.addListener(() => notifications++);

      expect(controller.reorderProduction(1, 1), isFalse);
      expect(controller.reorderProduction(-1, 0), isFalse);
      expect(controller.reorderProduction(0, 3), isFalse);

      expect(identical(controller.grammar, before), isTrue);
      expect(controller.canUndo, isFalse);
      expect(notifications, 0);
    });

    test('delete and add keep canonical order sequential', () {
      final controller = UnrestrictedGrammarEditorController(_grammar());

      controller.removeProduction('p2');
      expect(
        controller.grammar.productions.map((production) => production.order),
        [0, 1],
      );
      controller.upsertProduction(
        _production('p4', 99, const TerminalGrammarSymbol('d')),
      );

      expect(
        controller.grammar.productions.map((production) => production.id),
        ['p1', 'p3', 'p4'],
      );
      expect(
        controller.grammar.productions.map((production) => production.order),
        [0, 1, 2],
      );
    });
  });
}

UnrestrictedGrammar _grammar() => UnrestrictedGrammar(
  id: 'ordered',
  name: 'Ordered grammar',
  revision: 7,
  terminals: const [
    TerminalGrammarSymbol('a'),
    TerminalGrammarSymbol('b'),
    TerminalGrammarSymbol('c'),
    TerminalGrammarSymbol('d'),
  ],
  nonterminals: const [NonterminalGrammarSymbol('S')],
  startSymbol: const NonterminalGrammarSymbol('S'),
  productions: [
    _production('p1', 0, const TerminalGrammarSymbol('a')),
    _production('p2', 1, const TerminalGrammarSymbol('b')),
    _production('p3', 2, const TerminalGrammarSymbol('c')),
  ],
);

PhraseStructureProduction _production(
  String id,
  int order,
  TerminalGrammarSymbol terminal,
) => PhraseStructureProduction(
  id: id,
  order: order,
  left: GrammarSymbolSequence(const [NonterminalGrammarSymbol('S')]),
  right: GrammarSymbolSequence([terminal]),
);
