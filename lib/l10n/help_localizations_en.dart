const enHelpUiCopy = {
  'grammarEmptyProductionEditInstruction':
      'Use Edit to add your first production rule',
  'unrestrictedGrammarExampleAnBnCn': 'a^n b^n c^n',
  'unrestrictedGrammarExampleContextCopying': 'Context copying pattern',
  'unrestrictedGrammarExampleTmGenerated': 'TM-generated unrestricted grammar',
  'lSystemExampleKochCurve': 'Koch curve',
  'lSystemExampleSierpinskiTriangle': 'Sierpiński triangle',
  'lSystemExampleDragonCurve': 'Dragon curve',
  'lSystemExampleFractalPlant': 'Fractal plant',
  'lSystemExampleBranchingTree': 'Branching tree',
  'lSystemExampleSeededContextTurtle': 'Seeded context turtle',
  'relatedConcepts': 'Related Concepts',
  'hideExamples': 'Hide examples',
  'viewExamples': 'View examples',
};

const enHelpArticleBodies = {
  'gettingStarted':
      'Turing Lab is an interactive learning app for students and educators studying formal languages and automata theory.\n\n'
      'Use the navigation rail or bottom tabs to switch between FSA, Grammar, PDA, TM, Regex, and Pumping Lemma workspaces. '
      'Create structures, edit them directly, run simulations, convert between representations, and save or load supported files.',
  'fsa':
      'Finite State Automata are computational models with a finite number of states. They recognize regular languages.\n\n'
      'Create states with the add-state tool, double-tap states to edit initial or final markers, and create transitions by selecting a source and target state. '
      'Use the simulation panel to test input strings, then run algorithms such as NFA to DFA, minimization, complement, product operations, FA to Regex, and FSA to Grammar.',
  'grammar':
      'Context-Free Grammars use variables, terminals, a start symbol, and production rules to describe context-free languages.\n\n'
      'Add productions with a left-hand nonterminal and a right-hand sequence of terminals or nonterminals. Use ε for the empty string. '
      'Parsing tools include LL parsing, LR parsing, and the CYK algorithm.',
  'pda':
      'Pushdown Automata extend finite automata with a stack and can recognize context-free languages.\n\n'
      'A PDA transition reads an input symbol, inspects or pops the stack top, pushes replacement symbols, and changes state. '
      'During simulation, Turing Lab shows how input, state, and stack evolve until the input is consumed or no valid transition remains.',
  'tm':
      'Turing Machines use a tape, a read/write head, and finite control states. They model general computation.\n\n'
      'Transitions read a symbol, write a symbol, move the head left, right, or stay, and enter a new state. '
      'Configure acceptance by final state or halt behavior in Settings when supported by the workspace.',
  'regex':
      'Regular expressions describe regular languages with literals, concatenation, union, grouping, Kleene star, plus, and optional operators.\n\n'
      'Validate a regex, test strings against it, compare equivalence, analyze complexity, simplify expressions, and convert regexes to equivalent NFA or DFA structures.',
  'pumping':
      'The Pumping Lemma game helps explain why some languages are not regular.\n\n'
      'Choose a language, find a pumping length, choose a sufficiently long string, decompose it into xyz, and show that pumping y leads outside the language.',
  'fileOperations':
      'Turing Lab supports file workflows by workspace.\n\n'
      'FSA supports JFLAP XML, JSON, SVG, and native PNG export. Grammar supports JFLAP grammar import/export and SVG export. '
      'PDA and Turing Machine currently support SVG export only. Regex workflows operate directly on entered expressions.',
  'troubleshooting':
      'If the app feels slow, reduce very large automata or simplify dense transition graphs.\n\n'
      'If simulation takes too long, check for loops or nondeterministic paths that grow quickly. '
      'If files fail to load, verify that the format is supported for the current workspace and that the file is not corrupted. '
      'Use zoom controls when canvas elements are too small to tap.',
};

const enHelpSearchSuggestions = {
  'canvasTools': 'Canvas Tools',
  'shortcuts': 'Shortcuts',
  'dfa': 'DFA',
  'nfa': 'NFA',
  'algorithms': 'Algorithms',
};

const enHelpCategories = {
  'canvas': 'canvas',
  'automata': 'automata',
  'grammar': 'grammar',
  'regex': 'regex',
  'algorithms': 'algorithms',
  'shortcuts': 'shortcuts',
  'general': 'general',
};
