const enHelpUiCopy = {
  'homeHelpTooltip': 'Help',
  'homeSettingsTooltip': 'Settings',
  'helpPageTitle': 'Help & Documentation',
  'helpSearchTooltip': 'Search Help',
  'helpQuickStartTitle': 'Quick Start Guide',
  'helpQuickStartBody': 'Welcome to Turing Lab. Here is a quick way to get started:\n\n'
      '1. Choose a workspace such as FSA, Grammar, PDA, TM, or Regex.\n'
      '2. Start with a blank workspace or open a supported example or file.\n'
      '3. Use the editor to build your machine or grammar. Double-tap a state for quick actions.\n'
      '4. Run simulations to test your work.\n'
      '5. Use algorithms to transform structures.\n\n'
      'Tips:\n'
      '• Use navigation tabs or section chips to switch workspaces quickly.\n'
      '• Double-tap a state to open its quick action menu.\n'
      '• Pinch to zoom on the canvas.\n'
      '• Tap the Quick Start icon whenever you need a refresher.',
  'helpGotIt': 'Got it!',
  'helpSearchFieldLabel': 'Search help...',
  'helpSearchClear': 'Clear search',
  'helpSearchClose': 'Close search',
  'helpSearchTitle': 'Search Help',
  'helpSearchSubtitle': 'Find tutorials, shortcuts, and theory explanations',
  'helpSearchNoResults': 'No results found',
  'helpSearchNoResultsDescription':
      'Try different keywords or check your spelling',
  'contextualHelpPanelLabel': 'Contextual help panel',
  'closeHelpPanel': 'Close help panel',
  'close': 'Close',
  'viewAllRelatedHelp': 'View all related help',
  'moreHelp': 'More Help',
  'relatedConcepts': 'Related Concepts',
  'hideExamples': 'Hide examples',
  'viewExamples': 'View examples',
  'keyboardShortcutsDialogLabel': 'Keyboard shortcuts dialog',
  'keyboardShortcutsTitle': 'Keyboard Shortcuts',
  'keyboardShortcutsCanvasOperations': 'Canvas Operations',
  'keyboardShortcutsSimulationControls': 'Simulation Controls',
  'keyboardShortcutsDialogShortcuts': 'Dialog Shortcuts',
  'closeShortcutsDialog': 'Close shortcuts dialog',
  'shortcutAlternativeSeparator': 'or',
  'aboutDeveloperLabel': 'Developer',
  'aboutProjectRepositoryLabel': 'Project repository',
  'aboutProjectOpenError': 'Could not open the project repository.',
  'aboutOpenSourceLicenses': 'Open Source Licenses',
  'aboutLicensesIntro':
      'Turing Lab is a Flutter reimplementation inspired by and compatible with JFLAP. It is not an official JFLAP release.',
  'aboutTuringLabLicenseSummary':
      'Turing Lab original Flutter code is licensed under Apache 2.0.',
  'aboutJflapLicenseSummary':
      'JFLAP-derived portions remain under the JFLAP 7.1 License.',
  'aboutGraphViewLicenseSummary':
      'Graph visualization library, forked and modified for Turing Lab. Original work by Nabil Mosharraf.',
  'aboutAppleNoticesSummary':
      'Bundled notices for the vendored GraphView fork and Apple-platform plugin dependencies.',
  'aboutAppleNoticesTitle': 'Apple Platform Third-Party Notices',
  'aboutPackageLicenses': 'Package licenses',
  'aboutPackageLicensesDescription':
      'Licenses reported by Flutter for bundled Dart and Flutter packages.',
  'aboutAcknowledgments': 'JFLAP Acknowledgments',
  'aboutJflapCreator':
      'Original JFLAP creator and maintainer, Duke University.',
  'aboutJflapTeam':
      'Thomas Finley, Ryan Cavalcante, Stephen Reading, Bart Bressler, Jinghui Lim, Chris Morgan, Kyung Min (Jason) Lee, Jonathan Su, and Henry Qin.',
  'aboutOriginalProject': 'JFLAP website: http://www.jflap.org',
  'aboutOriginalProjectTitle': 'Original Project',
  'aboutGraphViewFork':
      'Turing Lab vendors a maintained fork of GraphView under the MIT license; Apple-platform third-party notices are bundled here.',
  'aboutGraphViewForkTitle': 'GraphView Fork',
  'aboutDistribution': 'Distribution',
  'aboutDistributionDescription':
      'Turing Lab is distributed as a free, non-monetized educational app while it includes JFLAP-derived material.',
  'aboutLicenseExpandPrompt': 'Expand to load bundled license text.',
  'aboutLicenseLoading': 'Loading bundled license text...',
  'aboutLicenseLoadFailed': 'Failed to load license',
};

const enHelpArticleBodies = {
  'gettingStarted':
      'Turing Lab is an interactive learning app for students and educators studying formal languages and automata theory.\n\n'
          'Use the navigation rail or bottom tabs to switch between FSA, Grammar, PDA, TM, Regex, and Pumping Lemma workspaces. '
          'Create structures, edit them directly, run simulations, convert between representations, and save or load supported files.',
  'fsa': 'Finite State Automata are computational models with a finite number of states. They recognize regular languages.\n\n'
      'Create states with the add-state tool, double-tap states to edit initial or final markers, and create transitions by selecting a source and target state. '
      'Use the simulation panel to test input strings, then run algorithms such as NFA to DFA, minimization, complement, product operations, FA to Regex, and FSA to Grammar.',
  'grammar':
      'Context-Free Grammars use variables, terminals, a start symbol, and production rules to describe context-free languages.\n\n'
          'Add productions with a left-hand nonterminal and a right-hand sequence of terminals or nonterminals. Use λ or ε for the empty string. '
          'Parsing tools include LL parsing, LR parsing, and the CYK algorithm.',
  'pda': 'Pushdown Automata extend finite automata with a stack and can recognize context-free languages.\n\n'
      'A PDA transition reads an input symbol, inspects or pops the stack top, pushes replacement symbols, and changes state. '
      'During simulation, Turing Lab shows how input, state, and stack evolve until the input is consumed or no valid transition remains.',
  'tm': 'Turing Machines use a tape, a read/write head, and finite control states. They model general computation.\n\n'
      'Transitions read a symbol, write a symbol, move the head left, right, or stay, and enter a new state. '
      'Configure acceptance by final state or halt behavior in Settings when supported by the workspace.',
  'regex':
      'Regular expressions describe regular languages with literals, concatenation, union, grouping, Kleene star, plus, and optional operators.\n\n'
          'Validate a regex, test strings against it, compare equivalence, analyze complexity, simplify expressions, and convert regexes to equivalent NFA or DFA structures.',
  'pumping':
      'The Pumping Lemma game helps explain why some languages are not regular.\n\n'
          'Choose a language, find a pumping length, choose a sufficiently long string, decompose it into xyz, and show that pumping y leads outside the language.',
  'fileOperations': 'Turing Lab supports file workflows by workspace.\n\n'
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
