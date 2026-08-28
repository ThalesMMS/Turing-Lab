import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/grammar/phrase_structure/phrase_structure.dart';
import '../../core/l_systems/l_systems.dart';
import '../l_systems/l_system_editor_controller.dart';
import '../unrestricted_grammar/unrestricted_grammar_editor_controller.dart';

final unrestrictedGrammarEditorProvider =
    ChangeNotifierProvider<UnrestrictedGrammarEditorController>((ref) {
  return UnrestrictedGrammarEditorController(
    UnrestrictedGrammar(
      id: 'unrestricted-grammar',
      name: 'Unrestricted grammar',
      revision: 0,
      terminals: const [
        TerminalGrammarSymbol('a'),
        TerminalGrammarSymbol('b'),
      ],
      nonterminals: const [NonterminalGrammarSymbol('S')],
      startSymbol: const NonterminalGrammarSymbol('S'),
      productions: const [],
    ),
  );
});

final lSystemEditorProvider = ChangeNotifierProvider<LSystemEditorController>(
  (ref) => LSystemEditorController(
    document: LSystemDocument(
      id: 'l-system',
      name: 'L-system',
      revision: 0,
      axiom: LSystemWord(const ['F']),
      productions: const [],
      iterations: 0,
      turtle: LSystemTurtleSettings(),
      commandMapping: LSystemCommandMapping.standard,
    ),
  ),
);
