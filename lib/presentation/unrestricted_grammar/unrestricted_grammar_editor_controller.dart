import 'package:flutter/foundation.dart';

import '../../core/grammar/phrase_structure/phrase_structure.dart';

final class UnrestrictedGrammarEditorController extends ChangeNotifier {
  UnrestrictedGrammarEditorController(UnrestrictedGrammar initialGrammar)
    : _grammar = initialGrammar;

  UnrestrictedGrammar _grammar;
  final List<UnrestrictedGrammar> _undoStack = [];
  final List<UnrestrictedGrammar> _redoStack = [];

  UnrestrictedGrammar get grammar => _grammar;
  bool get canUndo => _undoStack.isNotEmpty;
  bool get canRedo => _redoStack.isNotEmpty;

  void updateGrammarDetails({
    required String name,
    required Iterable<TerminalGrammarSymbol> terminals,
    required Iterable<NonterminalGrammarSymbol> nonterminals,
    required NonterminalGrammarSymbol startSymbol,
  }) {
    _commit(
      _grammar.copyWith(
        name: name,
        revision: _grammar.revision + 1,
        terminals: terminals,
        nonterminals: nonterminals,
        startSymbol: startSymbol,
      ),
    );
  }

  void upsertProduction(PhraseStructureProduction production) {
    final productions = [..._grammar.productions];
    final index = productions.indexWhere((item) => item.id == production.id);
    if (index < 0) {
      productions.add(production);
    } else {
      productions[index] = production;
    }
    _commit(
      _grammar.copyWith(
        revision: _grammar.revision + 1,
        productions: productions,
      ),
    );
  }

  void removeProduction(String productionId) {
    final productions = _grammar.productions
        .where((production) => production.id != productionId)
        .toList(growable: false);
    if (productions.length == _grammar.productions.length) return;
    _commit(
      _grammar.copyWith(
        revision: _grammar.revision + 1,
        productions: productions,
      ),
    );
  }

  void replaceGrammar(
    UnrestrictedGrammar grammar, {
    bool recordHistory = true,
  }) {
    if (!recordHistory) {
      _grammar = grammar;
      _undoStack.clear();
      _redoStack.clear();
      notifyListeners();
      return;
    }
    _commit(grammar);
  }

  void undo() {
    if (!canUndo) return;
    _redoStack.add(_grammar);
    _grammar = _undoStack.removeLast();
    notifyListeners();
  }

  void redo() {
    if (!canRedo) return;
    _undoStack.add(_grammar);
    _grammar = _redoStack.removeLast();
    notifyListeners();
  }

  String nextProductionId() {
    var suffix = _grammar.productions.length + 1;
    while (_grammar.productions.any((item) => item.id == 'p$suffix')) {
      suffix++;
    }
    return 'p$suffix';
  }

  void _commit(UnrestrictedGrammar next) {
    _undoStack.add(_grammar);
    _redoStack.clear();
    _grammar = next;
    notifyListeners();
  }
}
