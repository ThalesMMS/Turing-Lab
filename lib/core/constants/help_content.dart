//
//  help_content.dart
//  Turing Lab
//
//  Centraliza todo o conteúdo textual de ajuda contextual da aplicação,
//  incluindo tooltips de ferramentas, explicações de conceitos de autômatos,
//  atalhos de teclado e documentação de algoritmos. Estruturado em mapa de
//  HelpContentModel para busca eficiente, categorização temática e navegação
//  entre conceitos relacionados durante o estudo e uso do aplicativo.
//
//  Thales Matheus Mendonça Santos - January 2026
//

import '../models/help_content_model.dart';

/// All contextual help content for the application, indexed by unique ID.
const Map<String, HelpContentModel> kHelpContent = {
  // ============================================================================
  // Canvas Tools
  // ============================================================================
  'tool_select': HelpContentModel(
    id: 'tool_select',
    title: 'Selection Tool',
    content: 'Use this tool to select, move, and edit states and transitions. '
        'Click on a state to select it, drag to move it, or double-click to '
        'edit its properties. Click on a transition to select and edit its label.',
    category: 'canvas',
    keywords: ['select', 'move', 'edit', 'pan', 'drag'],
    relatedConcepts: ['tool_add_state', 'tool_add_transition'],
    icon: 'pan_tool',
  ),
  'tool_add_state': HelpContentModel(
    id: 'tool_add_state',
    title: 'Add State',
    content:
        'Click anywhere on the canvas to add a new state at that position. '
        'The first state you create is automatically set as the initial state. '
        'You can later change initial and final states by editing state properties.',
    category: 'canvas',
    keywords: ['add', 'state', 'create', 'node', 'initial', 'final'],
    relatedConcepts: ['tool_add_transition', 'concept_state', 'tool_select'],
    icon: 'add_circle',
  ),
  'tool_add_transition': HelpContentModel(
    id: 'tool_add_transition',
    title: 'Add Transition',
    content: 'Click on a source state, then click on a destination state to '
        'create a transition between them. After creating the transition, '
        'you\'ll be prompted to enter the transition label (symbols, epsilon, '
        'or stack operations depending on the automaton type).',
    category: 'canvas',
    keywords: ['add', 'transition', 'edge', 'arrow', 'connect'],
    relatedConcepts: [
      'tool_add_state',
      'concept_transition',
      'concept_epsilon'
    ],
    icon: 'arrow_forward',
  ),
  'tool_undo': HelpContentModel(
    id: 'tool_undo',
    title: 'Undo',
    content: 'Undo the last action performed on the canvas. You can undo '
        'multiple actions by clicking this button repeatedly. Common actions '
        'that can be undone include adding/deleting states, adding/deleting '
        'transitions, and moving states.',
    category: 'canvas',
    keywords: ['undo', 'revert', 'back', 'history'],
    relatedConcepts: ['tool_redo', 'tool_clear'],
    icon: 'undo',
  ),
  'tool_redo': HelpContentModel(
    id: 'tool_redo',
    title: 'Redo',
    content: 'Redo an action that was previously undone. This button is only '
        'available after you\'ve used the Undo function. Redo can restore '
        'multiple undone actions in sequence.',
    category: 'canvas',
    keywords: ['redo', 'restore', 'forward', 'history'],
    relatedConcepts: ['tool_undo'],
    icon: 'redo',
  ),
  'tool_fit_content': HelpContentModel(
    id: 'tool_fit_content',
    title: 'Fit to Content',
    content: 'Automatically zoom and pan the canvas to show all states and '
        'transitions in the optimal view. Use this when you\'ve lost track of '
        'your automaton or want to see the entire structure at once.',
    category: 'canvas',
    keywords: ['fit', 'zoom', 'view', 'center', 'focus'],
    relatedConcepts: ['tool_reset_view'],
    icon: 'fit_screen',
  ),
  'tool_reset_view': HelpContentModel(
    id: 'tool_reset_view',
    title: 'Reset View',
    content: 'Reset the canvas zoom and pan to the default view. This restores '
        'the canvas to 100% zoom level and centers the view at the origin. '
        'Use this to return to a standard viewing perspective.',
    category: 'canvas',
    keywords: ['reset', 'zoom', 'center', 'default', 'view'],
    relatedConcepts: ['tool_fit_content'],
    icon: 'center_focus_strong',
  ),
  'tool_clear': HelpContentModel(
    id: 'tool_clear',
    title: 'Clear Canvas',
    content: 'Remove all states and transitions from the canvas, creating a '
        'blank workspace. This action can be undone if needed. Use this when '
        'you want to start building a new automaton from scratch.',
    category: 'canvas',
    keywords: ['clear', 'delete', 'remove', 'reset', 'erase'],
    relatedConcepts: ['tool_undo', 'tool_add_state'],
    icon: 'delete',
  ),

  // ============================================================================
  // Automata Concepts - DFA/NFA
  // ============================================================================
  'concept_dfa': HelpContentModel(
    id: 'concept_dfa',
    title: 'Deterministic Finite Automaton (DFA)',
    content: 'A DFA is a finite state machine where for each state and input '
        'symbol, there is exactly one transition to a next state. DFAs are used '
        'to recognize regular languages. Key properties:\n'
        '• Exactly one transition per symbol from each state\n'
        '• No epsilon (ε) transitions\n'
        '• Accepts a string if it ends in a final state\n'
        '• Can be converted to an equivalent NFA or regular expression',
    category: 'automata',
    keywords: ['dfa', 'deterministic', 'finite', 'automaton', 'fsa'],
    relatedConcepts: [
      'concept_nfa',
      'concept_state',
      'concept_transition',
      'algo_dfa_minimize'
    ],
    icon: 'account_tree',
  ),
  'concept_nfa': HelpContentModel(
    id: 'concept_nfa',
    title: 'Nondeterministic Finite Automaton (NFA)',
    content:
        'An NFA is a finite state machine where a state can have zero, one, '
        'or multiple transitions for the same input symbol. NFAs can also have '
        'epsilon transitions. Key properties:\n'
        '• Multiple or zero transitions per symbol allowed\n'
        '• Epsilon (ε) transitions allowed\n'
        '• Accepts if any computation path reaches a final state\n'
        '• Can be converted to an equivalent DFA\n'
        '• Often more compact than equivalent DFA',
    category: 'automata',
    keywords: ['nfa', 'nondeterministic', 'finite', 'automaton', 'fsa'],
    relatedConcepts: ['concept_dfa', 'concept_epsilon', 'algo_nfa_to_dfa'],
    icon: 'account_tree',
  ),
  'concept_state': HelpContentModel(
    id: 'concept_state',
    title: 'States',
    content:
        'States represent the different configurations an automaton can be '
        'in during computation. Types of states:\n'
        '• Initial State: Where computation begins (marked with incoming arrow)\n'
        '• Final/Accept State: Ends computation successfully (double circle)\n'
        '• Regular State: Intermediate states during computation\n\n'
        'In Turing Lab, double-click a state to edit its properties, including '
        'marking it as initial or final.',
    category: 'automata',
    keywords: ['state', 'node', 'initial', 'final', 'accept', 'start'],
    relatedConcepts: ['concept_transition', 'concept_dfa', 'concept_nfa'],
    icon: 'circle',
  ),
  'concept_transition': HelpContentModel(
    id: 'concept_transition',
    title: 'Transitions',
    content: 'Transitions are edges that connect states and define how the '
        'automaton moves from one state to another based on input symbols. '
        'Each transition has:\n'
        '• Source State: Where the transition begins\n'
        '• Destination State: Where the transition ends\n'
        '• Label: The input symbol(s) that trigger this transition\n\n'
        'In DFAs, each state must have exactly one outgoing transition per '
        'alphabet symbol. In NFAs, states can have multiple transitions for '
        'the same symbol or epsilon transitions.',
    category: 'automata',
    keywords: ['transition', 'edge', 'arrow', 'label', 'symbol'],
    relatedConcepts: [
      'concept_state',
      'concept_epsilon',
      'concept_dfa',
      'concept_nfa'
    ],
    icon: 'arrow_forward',
  ),
  'concept_epsilon': HelpContentModel(
    id: 'concept_epsilon',
    title: 'Epsilon (ε) Transitions',
    content: 'An epsilon transition allows an NFA to change states without '
        'consuming any input symbol. Key points:\n'
        '• Represented by ε or λ in transition labels\n'
        '• Only allowed in NFAs, not in DFAs\n'
        '• Can create multiple simultaneous computation paths\n'
        '• Epsilon closure: set of all states reachable via ε-transitions\n\n'
        'In Turing Lab, use "ε" or "epsilon" when entering transition labels '
        'for epsilon transitions.',
    category: 'automata',
    keywords: ['epsilon', 'lambda', 'empty', 'null', 'transition'],
    relatedConcepts: [
      'concept_nfa',
      'concept_transition',
      'algo_epsilon_closure'
    ],
    icon: 'more_horiz',
  ),

  // ============================================================================
  // Automata Concepts - PDA
  // ============================================================================
  'concept_pda': HelpContentModel(
    id: 'concept_pda',
    title: 'Pushdown Automaton (PDA)',
    content: 'A PDA is a finite automaton extended with a stack memory. PDAs '
        'recognize context-free languages, which are more powerful than regular '
        'languages. Key features:\n'
        '• Stack operations: push, pop, and read\n'
        '• Transitions based on current state, input symbol, and stack top\n'
        '• Can accept by final state or empty stack\n'
        '• Equivalent to context-free grammars\n\n'
        'Transition format: input, stack_pop → stack_push',
    category: 'automata',
    keywords: ['pda', 'pushdown', 'stack', 'context-free', 'cfg'],
    relatedConcepts: ['concept_cfg', 'concept_stack'],
    icon: 'storage',
  ),
  'concept_stack': HelpContentModel(
    id: 'concept_stack',
    title: 'Stack Operations',
    content:
        'In a PDA, the stack is a last-in-first-out (LIFO) memory structure '
        'used to store and retrieve symbols. Operations:\n'
        '• Push: Add a symbol to the top of the stack\n'
        '• Pop: Remove and read the symbol at the top of the stack\n'
        '• Peek: Read the top symbol without removing it\n\n'
        'Stack symbols can represent nested structures, making PDAs more '
        'powerful than finite automata for language recognition.',
    category: 'automata',
    keywords: ['stack', 'push', 'pop', 'peek', 'lifo', 'memory'],
    relatedConcepts: ['concept_pda'],
    icon: 'view_agenda',
  ),

  // ============================================================================
  // Automata Concepts - Turing Machine
  // ============================================================================
  'concept_tm': HelpContentModel(
    id: 'concept_tm',
    title: 'Turing Machine (TM)',
    content: 'A Turing Machine is the most powerful computational model in '
        'automata theory. It consists of:\n'
        '• An infinite tape divided into cells\n'
        '• A read/write head that can move left or right\n'
        '• A finite set of states\n'
        '• A transition function defining behavior\n\n'
        'TMs can recognize recursively enumerable languages and perform any '
        'computation that can be algorithmically described.',
    category: 'automata',
    keywords: ['turing', 'machine', 'tape', 'tm', 'recursive'],
    relatedConcepts: ['concept_tape', 'concept_decidable'],
    icon: 'view_headline',
  ),
  'concept_decidable': HelpContentModel(
    id: 'concept_decidable',
    title: 'Decidable Languages',
    content: 'A language is decidable if there exists a Turing Machine that '
        'halts on every input and accepts exactly the strings in the language. '
        'Decidable languages are also called recursive languages. In contrast, '
        'recursively enumerable languages may have computations that never '
        'halt for some inputs.',
    category: 'automata',
    keywords: ['decidable', 'recursive', 'halt', 'turing', 'language'],
    relatedConcepts: ['concept_tm'],
    icon: 'info',
  ),
  'concept_tape': HelpContentModel(
    id: 'concept_tape',
    title: 'Turing Machine Tape',
    content: 'The tape is an infinite sequence of cells that serves as the '
        'memory for a Turing Machine. Properties:\n'
        '• Each cell contains a symbol from the tape alphabet\n'
        '• Initially contains the input string followed by blank symbols\n'
        '• The read/write head can read, write, and move left/right\n'
        '• Provides unlimited memory for computation\n\n'
        'Transition format: read_symbol → write_symbol, direction (L/R)',
    category: 'automata',
    keywords: ['tape', 'memory', 'cell', 'head', 'read', 'write'],
    relatedConcepts: ['concept_tm'],
    icon: 'linear_scale',
  ),

  // ============================================================================
  // Grammar Concepts
  // ============================================================================
  'concept_cfg': HelpContentModel(
    id: 'concept_cfg',
    title: 'Context-Free Grammar (CFG)',
    content: 'A CFG is a formal grammar consisting of:\n'
        '• Variables (non-terminals): symbols that can be replaced\n'
        '• Terminals: symbols in the language alphabet\n'
        '• Production rules: rules for replacing variables\n'
        '• Start symbol: the initial variable\n\n'
        'CFGs generate context-free languages and are equivalent to PDAs. '
        'They are widely used in programming language syntax and parsing.',
    category: 'grammar',
    keywords: ['cfg', 'context-free', 'grammar', 'production', 'derivation'],
    relatedConcepts: ['concept_pda', 'concept_derivation', 'algo_cfg_to_pda'],
    icon: 'code',
  ),
  'concept_derivation': HelpContentModel(
    id: 'concept_derivation',
    title: 'Derivations',
    content: 'A derivation is a sequence of rule applications that transforms '
        'the start symbol into a string of terminals. Types:\n'
        '• Leftmost derivation: Always replace the leftmost variable first\n'
        '• Rightmost derivation: Always replace the rightmost variable first\n'
        '• Parse tree: Visual representation of a derivation\n\n'
        'Ambiguous grammars have multiple derivations for the same string.',
    category: 'grammar',
    keywords: ['derivation', 'parse', 'tree', 'leftmost', 'rightmost'],
    relatedConcepts: ['concept_cfg', 'concept_ambiguity'],
    icon: 'account_tree',
  ),
  'concept_ambiguity': HelpContentModel(
    id: 'concept_ambiguity',
    title: 'Grammar Ambiguity',
    content: 'A grammar is ambiguous if there exists a string with two or more '
        'distinct parse trees (or leftmost/rightmost derivations). Ambiguity '
        'can cause problems in language parsing and compilation.\n\n'
        'Example: E → E + E | E * E | n\n'
        'The string "2 + 3 * 4" has multiple parse trees.\n\n'
        'Some ambiguous grammars can be rewritten to be unambiguous.',
    category: 'grammar',
    keywords: ['ambiguity', 'ambiguous', 'parse', 'tree', 'grammar'],
    relatedConcepts: ['concept_cfg', 'concept_derivation'],
    icon: 'call_split',
  ),

  // ============================================================================
  // Regular Expressions
  // ============================================================================
  'concept_regex': HelpContentModel(
    id: 'concept_regex',
    title: 'Regular Expressions',
    content: 'Regular expressions (regex) are patterns that describe regular '
        'languages using operators:\n'
        '• Concatenation (ab): Match a followed by b\n'
        '• Union (a|b): Match either a or b\n'
        '• Kleene star (a*): Match zero or more occurrences of a\n'
        '• Kleene plus (a+): Match one or more occurrences of a\n'
        '• Grouping (()): Control precedence\n'
        '• Empty string (ε): Match nothing\n\n'
        'Regular expressions are equivalent to DFAs and NFAs.',
    category: 'regex',
    keywords: ['regex', 'regular', 'expression', 'pattern', 'kleene'],
    relatedConcepts: ['concept_dfa', 'concept_nfa', 'algo_regex_to_nfa'],
    icon: 'text_fields',
  ),

  // ============================================================================
  // Algorithm Explanations
  // ============================================================================
  'algo_nfa_to_dfa': HelpContentModel(
    id: 'algo_nfa_to_dfa',
    title: 'NFA to DFA Conversion',
    content:
        'Convert an NFA to an equivalent DFA using the subset construction '
        'algorithm:\n'
        '1. Compute epsilon closures for all states\n'
        '2. Create DFA states from sets of NFA states\n'
        '3. For each DFA state and symbol, compute the next DFA state\n'
        '4. Mark DFA states as final if they contain any NFA final state\n\n'
        'The resulting DFA may have exponentially more states but is '
        'equivalent in accepting the same language.',
    category: 'algorithms',
    keywords: ['nfa', 'dfa', 'conversion', 'subset', 'construction'],
    relatedConcepts: ['concept_nfa', 'concept_dfa', 'algo_epsilon_closure'],
    icon: 'transform',
  ),
  'algo_dfa_minimize': HelpContentModel(
    id: 'algo_dfa_minimize',
    title: 'DFA Minimization',
    content: 'Reduce a DFA to the smallest equivalent DFA using Hopcroft\'s '
        'algorithm:\n'
        '1. Remove unreachable states\n'
        '2. Partition states into equivalence classes\n'
        '3. Initially: final states vs. non-final states\n'
        '4. Refine partitions until no more splits occur\n'
        '5. Merge equivalent states\n\n'
        'The minimal DFA has the fewest states and is unique (up to isomorphism).',
    category: 'algorithms',
    keywords: ['minimize', 'minimization', 'dfa', 'hopcroft', 'equivalence'],
    relatedConcepts: ['concept_dfa', 'algo_nfa_to_dfa'],
    icon: 'compress',
  ),
  'algo_epsilon_closure': HelpContentModel(
    id: 'algo_epsilon_closure',
    title: 'Epsilon Closure',
    content:
        'The epsilon closure of a state is the set of all states reachable '
        'from that state using only epsilon transitions. Algorithm:\n'
        '1. Start with the initial state\n'
        '2. Follow all epsilon transitions to find reachable states\n'
        '3. Recursively compute closure for newly found states\n'
        '4. Return the complete set of reachable states\n\n'
        'Epsilon closures are essential for NFA simulation and NFA-to-DFA conversion.',
    category: 'algorithms',
    keywords: ['epsilon', 'closure', 'nfa', 'reachable', 'transition'],
    relatedConcepts: ['concept_epsilon', 'concept_nfa', 'algo_nfa_to_dfa'],
    icon: 'all_inclusive',
  ),
  'algo_regex_to_nfa': HelpContentModel(
    id: 'algo_regex_to_nfa',
    title: 'Regular Expression to NFA',
    content:
        'Convert a regular expression to an equivalent NFA using Thompson\'s '
        'construction:\n'
        '• Base case: Single symbol → NFA with two states\n'
        '• Concatenation: Connect NFAs in sequence\n'
        '• Union: Add new start state with epsilon transitions\n'
        '• Kleene star: Add epsilon transitions for looping\n\n'
        'The resulting NFA has at most 2n states for a regex of size n.',
    category: 'algorithms',
    keywords: ['regex', 'nfa', 'thompson', 'conversion', 'construction'],
    relatedConcepts: ['concept_regex', 'concept_nfa', 'concept_epsilon'],
    icon: 'auto_awesome',
  ),
  'algo_cfg_to_pda': HelpContentModel(
    id: 'algo_cfg_to_pda',
    title: 'CFG to PDA Conversion',
    content: 'Convert a context-free grammar to an equivalent PDA:\n'
        '1. Create a single-state PDA with a stack\n'
        '2. Push the start symbol onto the stack\n'
        '3. For each variable on stack top, non-deterministically choose and '
        'apply a production rule\n'
        '4. For each terminal on stack top, match and consume input\n'
        '5. Accept when stack is empty and input consumed\n\n'
        'This construction proves CFGs and PDAs are equivalent.',
    category: 'algorithms',
    keywords: ['cfg', 'pda', 'conversion', 'grammar', 'pushdown'],
    relatedConcepts: ['concept_cfg', 'concept_pda'],
    icon: 'sync_alt',
  ),

  // ============================================================================
  // Keyboard Shortcuts
  // ============================================================================
  'shortcut_canvas_general': HelpContentModel(
    id: 'shortcut_canvas_general',
    title: 'Canvas Keyboard Shortcuts',
    content: 'General canvas shortcuts:\n'
        'A: Add a state at the canvas center\n'
        'T: Activate transition mode\n'
        'V: Activate selection mode\n'
        'Delete or Backspace: Delete selected transition\n'
        'Ctrl/Cmd + Z: Undo last canvas change\n'
        'Ctrl/Cmd + Y or Ctrl/Cmd + Shift + Z: Redo canvas change\n'
        '• Tab: Move focus between canvas toolbar actions\n'
        '• Shift + Tab: Move focus to the previous toolbar action\n'
        '• Enter or Space: Activate the focused toolbar action\n'
        '• Escape: Cancel the current dialog or editor',
    category: 'shortcuts',
    keywords: [
      'keyboard',
      'shortcut',
      'hotkey',
      'canvas',
      'tab',
      'shift',
      'enter',
      'space',
      'escape',
      'toolbar',
      'focus',
      'state',
      'transition',
      'delete',
      'backspace',
      'undo',
      'redo',
    ],
    relatedConcepts: ['tool_undo', 'tool_redo', 'tool_select'],
    icon: 'keyboard',
  ),
  'shortcut_simulation': HelpContentModel(
    id: 'shortcut_simulation',
    title: 'Simulation Shortcuts',
    content: 'Shortcuts during string simulation:\n'
        '• Enter: Submit the focused input field and run the simulation\n'
        '• Tab: Move focus between the input field, toggles, and controls\n'
        '• Shift + Tab: Move focus to the previous simulation control\n'
        '• Enter or Space: Activate the focused simulation button',
    category: 'shortcuts',
    keywords: ['keyboard', 'shortcut', 'simulation', 'test', 'run'],
    relatedConcepts: ['concept_dfa', 'concept_nfa'],
    icon: 'keyboard',
  ),
  'shortcut_dialogs': HelpContentModel(
    id: 'shortcut_dialogs',
    title: 'Dialog Shortcuts',
    content: 'Shortcuts in dialogs and editors:\n'
        '• Enter: Confirm/Submit\n'
        '• Escape: Cancel/Close\n'
        '• Tab: Move to next field\n'
        '• Shift + Tab: Move to previous field',
    category: 'shortcuts',
    keywords: ['keyboard', 'shortcut', 'dialog', 'editor', 'form'],
    relatedConcepts: [],
    icon: 'keyboard',
  ),

  // ============================================================================
  // General Usage
  // ============================================================================
  'usage_getting_started': HelpContentModel(
    id: 'usage_getting_started',
    title: 'Getting Started',
    content: 'Welcome to Turing Lab! To create your first automaton:\n'
        '1. Choose an automaton type from the home page (FSA, PDA, TM, etc.)\n'
        '2. Click "Add State" to create states on the canvas\n'
        '3. Click "Add Transition" to connect states\n'
        '4. Double-click states to mark them as initial or final\n'
        '5. Use the test input feature to simulate strings\n\n'
        'Hover over any tool for a tooltip explaining its function.',
    category: 'general',
    keywords: ['start', 'begin', 'introduction', 'tutorial', 'first'],
    relatedConcepts: ['tool_add_state', 'tool_add_transition', 'concept_state'],
    icon: 'info',
  ),
  'usage_test_input': HelpContentModel(
    id: 'usage_test_input',
    title: 'Testing Input Strings',
    content: 'To test if your automaton accepts a string:\n'
        '1. Build your automaton on the canvas\n'
        '2. Click the "Test Input" or "Run" button\n'
        '3. Enter the string you want to test\n'
        '4. Watch the simulation highlight the computation path\n'
        '5. See if the string is accepted or rejected\n\n'
        'For NFAs, you can view the computation tree to see all possible paths.',
    category: 'general',
    keywords: ['test', 'input', 'simulate', 'run', 'string', 'accept'],
    relatedConcepts: ['concept_dfa', 'concept_nfa', 'shortcut_simulation'],
    icon: 'play_arrow',
  ),
  'usage_import_export': HelpContentModel(
    id: 'usage_import_export',
    title: 'Import & Export',
    content: 'Save and load your work:\n'
        '• Export: Save your automaton as JSON or JFLAP format\n'
        '• Import: Load previously saved automata\n'
        '• Share: Export and share files with classmates\n'
        '• Backup: Regular exports prevent work loss\n\n'
        'Files can be opened in JFLAP for compatibility with course materials.',
    category: 'general',
    keywords: ['import', 'export', 'save', 'load', 'file', 'jflap'],
    relatedConcepts: [],
    icon: 'save',
  ),
};
