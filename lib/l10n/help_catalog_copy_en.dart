import '../core/constants/help_topic_ids.dart';
import 'help_catalog_copy.dart';

final _fsaSimulationBlocks = <HelpContentBlock>[
  const HelpHeadingBlock('Run and inspect a simulation'),
  HelpOrderedStepsBlock([
    'Confirm the automaton has a valid initial state, then enter Input String.',
    'Select Simulate and wait for the current run to finish.',
    'Read Accepted or Rejected, inspect the trace, and use View on Canvas when it is available.',
  ]),
  const HelpCalloutBlock(
    'Missing state markers, invalid transitions, or computation limits can prevent a reliable result; follow the message shown by the workspace.',
  ),
];

final _fsaAlgorithmBlocks = <HelpContentBlock>[
  const HelpHeadingBlock('Run a finite-automata algorithm'),
  HelpOrderedStepsBlock([
    'Open Algorithms and confirm the current automaton satisfies the action requirements.',
    'Select the required algorithm and provide any second automaton or option it requests.',
    'Review the result, step viewer, and View on Canvas or conversion action when offered.',
  ]),
  const HelpCalloutBlock(
    'A disabled action or validation message means its requirements are not satisfied; the source automaton changes only when the result flow explicitly applies or replaces it.',
  ),
];

final _grammarParserBlocks = <HelpContentBlock>[
  const HelpHeadingBlock('Parse an input string'),
  HelpOrderedStepsBlock([
    'Check that the grammar has productions and a valid start symbol, then enter Test String.',
    'Choose an available Parsing Algorithm and select Parse String.',
    'Read Accepted or Rejected and inspect the derivation, diagnostics, or CYK Steps that the strategy records.',
  ]),
  const HelpCalloutBlock(
    'Unavailable strategies do not appear in the menu, and invalid symbols or a timeout can end a run without a parse result.',
  ),
];

final _grammarAlgorithmBlocks = <HelpContentBlock>[
  const HelpHeadingBlock('Run a grammar analysis or transformation'),
  HelpOrderedStepsBlock([
    'Resolve production diagnostics and confirm the grammar has a valid start symbol.',
    'Open Grammar Analysis and select the named analysis or transformation.',
    'Inspect the reported sets, table, grammar, or steps; use Apply only when that control is present.',
  ]),
  const HelpCalloutBlock(
    'Disabled controls, validation reports, and error-severity diagnostics leave the editor grammar unchanged.',
  ),
];

final _pdaSimulationBlocks = <HelpContentBlock>[
  const HelpHeadingBlock('Run and inspect a PDA simulation'),
  HelpOrderedStepsBlock([
    'Validate the initial state and stack symbol, then enter the simulation input.',
    'Start the run and use Cancel when a recorded computation must stop.',
    'Inspect the current stack, remaining input, result, and View on Canvas trace.',
  ]),
  const HelpCalloutBlock(
    'Nondeterministic branches and stack limits can stop or reject a run; read the recorded trace before changing the PDA.',
  ),
];

final _pdaAlgorithmBlocks = <HelpContentBlock>[
  const HelpHeadingBlock('Run a PDA analysis'),
  HelpOrderedStepsBlock([
    'Open Algorithms and check the PDA state, transition, and stack requirements.',
    'Select the named conversion or analysis control.',
    'Review the generated CFG, state result, language report, or stack-operation metrics.',
  ]),
  const HelpCalloutBlock(
    'An unavailable or failed analysis leaves the PDA unchanged and reports the requirement that must be resolved.',
  ),
];

final _tmSimulationBlocks = <HelpContentBlock>[
  const HelpHeadingBlock('Run and inspect a Turing-machine simulation'),
  HelpOrderedStepsBlock([
    'Validate the initial state, blank symbol, and transition fields, then enter the tape input.',
    'Start the run and use Cancel when the computation must stop.',
    'Inspect the tape projection, head position, result, and View on Canvas trace.',
  ]),
  const HelpCalloutBlock(
    'A machine can run until its configured step or resource limit; a limit is not the same as a halting acceptance result.',
  ),
];

final _tmAlgorithmBlocks = <HelpContentBlock>[
  const HelpHeadingBlock('Run a Turing-machine analysis'),
  HelpOrderedStepsBlock([
    'Open Algorithms and confirm the machine has the states and transitions required by the analysis.',
    'Configure the input and execution limits when the selected action requests them, then select the named control.',
    'Review the reachability, language, tape-operation, bounded time, or bounded space report that appears.',
  ]),
  const HelpCalloutBlock(
    'Bounded analysis describes only the displayed input scope and budgets; it does not prove termination or complexity for every possible input.',
  ),
];

final enHelpCatalogCopy = HelpCatalogCopy({
  HelpTopicIds.gettingStarted: HelpNodeCopy(
    title: 'Getting started',
    keywords: ['start', 'guide', 'navigation'],
  ),
  HelpTopicIds.gettingStartedQuickStart: HelpNodeCopy(
    title: 'Quick start',
    body: 'Quick start is the shortest path from the Home page to a tested '
        'formal-language model. Use it when you are opening Turing Lab for the '
        'first time or need a workflow reminder. Use navigation tabs or section '
        'chips to choose a workspace, start with a blank document or example, '
        'or open a supported file, and build the model. Double-tap a state for '
        'quick actions. Pinch to '
        'zoom the canvas, then enter a sample input and run it; the Quick Start '
        'icon opens this reminder again. Use algorithms to transform structures '
        'after the first run. The editor then shows the model, '
        'validation status, and simulation result. A model normally needs an '
        'initial state and, '
        'for acceptance, at least one accepting state; fix any status message '
        'before relying on a result. Continue with Choosing a workspace or '
        'Testing your first input.',
    keywords: ['quick start', 'first model', 'workflow', 'home'],
  ),
  HelpTopicIds.gettingStartedNavigation: HelpNodeCopy(
    title: 'Navigate Turing Lab',
    body: 'The main navigation switches among FSA, Grammar, PDA, TM, Regex, '
        'and Pumping workspaces. Use it when you want to change the kind of '
        'language model you are editing or studying. Select a destination in '
        'the Home page navigation, bottom navigation, or the available section '
        'control for your screen size. Turing Lab opens that workspace and '
        'keeps its editing tools close to the canvas or input area. Labels and '
        'placement adapt to phone, tablet, and desktop layouts, so use the '
        'visible label rather than a fixed position. Read Choosing a workspace '
        'before creating a new model.',
    keywords: ['navigation', 'FSA', 'Grammar', 'PDA', 'TM', 'Regex', 'Pumping'],
  ),
  HelpTopicIds.gettingStartedChooseWorkspace: HelpNodeCopy(
    title: 'Choose a workspace',
    body: 'Each workspace represents a different formal-language model or '
        'learning activity. Use FSA for regular languages and finite memory, '
        'Grammar for production rules, PDA for stack memory, TM for tape '
        'computation, Regex for regular-expression work, and Pumping for proof '
        'practice. Select the matching card or navigation label on the Home '
        'page. The chosen editor opens with its own controls, simulation, '
        'algorithms, and theory help. Conversions can move a result to another '
        'workspace, but unsupported structures cannot be represented in a '
        'weaker model. Continue with the editor overview for the workspace you '
        'selected.',
    keywords: ['workspace', 'formal language', 'automaton', 'grammar', 'regex'],
  ),
  HelpTopicIds.gettingStartedFilesAndExamples: HelpNodeCopy(
    title: 'Files and examples',
    body: 'Files and examples let you begin from saved or bundled material '
        'instead of an empty editor. Use an example to learn a feature and use '
        'import or export to continue your own work. Open the examples panel or '
        'a file action, then select the requested file when the platform file '
        'picker appears; on the web, downloads replace native save dialogs. A '
        'successful import replaces or loads the current model, while export '
        'creates the format named by the action. Only formats offered by the '
        'current workspace are supported, and canceling file selection leaves '
        'the model unchanged. Read the workspace-specific Files and examples '
        'topic for exact formats.',
    keywords: ['files', 'examples', 'import', 'export', 'file picker'],
  ),
  HelpTopicIds.gettingStartedFirstInput: HelpNodeCopy(
    title: 'Test your first input',
    body: 'A simulation checks how the current model processes one input '
        'string. Use it after the editor reports a usable model and whenever '
        'you want to test membership in its language. Enter the string in '
        'Input String, leave it blank for ε when supported, and select '
        'Simulate or Run simulation. The result reports Accepted or Rejected '
        'and may include a step trace. Missing initial states, invalid '
        'transitions, or computation limits can prevent a reliable run; follow '
        'the displayed message. Continue with the simulation topic for your '
        'workspace.',
    keywords: ['input', 'simulation', 'accepted', 'rejected', 'epsilon'],
  ),
  HelpTopicIds.gettingStartedFindHelp: HelpNodeCopy(
    title: 'Find help and shortcuts',
    body: 'Help combines instructions, current-screen guidance, theory, and '
        'keyboard references in one searchable tree. Use it when a control, '
        'result, requirement, or concept is unclear. Select a question-mark '
        'Help action for the current topic, open Help from the app bar for the '
        'full tree, or search by a label or concept. The matching topic opens '
        'with its ancestors visible and related next steps nearby. Short '
        'tooltips only identify controls, and shortcuts vary by platform and '
        'hardware keyboard availability. Continue with Navigate Turing Lab or '
        'the relevant editor overview.',
    keywords: ['help', 'search', 'shortcuts', 'question mark', 'tooltip'],
  ),
  'fsa': HelpNodeCopy(
    title: 'Finite automata',
    keywords: ['FSA', 'finite automata', 'DFA', 'NFA'],
  ),
  'fsa.editor': HelpNodeCopy(
    title: 'Editor and canvas',
    keywords: ['editor', 'canvas', 'simulation', 'algorithms'],
  ),
  HelpTopicIds.fsaEditorOverview: HelpNodeCopy(
    title: 'Finite automata editor overview',
    body: 'The finite automata workspace combines the state canvas, simulation '
        'panel, algorithm panel, validation status, and file actions. Use it '
        'when you need to build or inspect a DFA, NFA, or epsilon-NFA. Start '
        'with Add state, connect states with Add transition, mark the initial '
        'and accepting states, then run a sample input. The status area reports '
        'missing markers and nondeterminism. A simulation or DFA-only algorithm '
        'may be unavailable until its structural requirements are satisfied. '
        'Open Editing, Simulation, or Algorithms for the next step.',
    keywords: ['FSA', 'editor', 'canvas', 'DFA', 'NFA'],
  ),
  'fsa.editor.editing': HelpNodeCopy(
    title: 'Edit an automaton',
    keywords: ['edit', 'state', 'transition', 'history'],
  ),
  HelpTopicIds.fsaEditorSelection: HelpNodeCopy(
    title: 'Select and move items',
    body: 'Select mode lets you inspect, move, edit, or delete existing canvas '
        'items. Use it after creating states or whenever another editing tool '
        'is active. Choose Select, then select a state or transition; drag a '
        'state with a pointer or one-finger touch, and double-tap a state for '
        'quick actions. The selected item gains its active appearance and '
        'moving a state updates its connected edges. A pinch uses two fingers '
        'for canvas zoom rather than moving a state, and read-only result '
        'canvases do not allow edits. Continue with States or Transitions.',
    keywords: ['select', 'move', 'drag', 'double tap', 'touch'],
  ),
  HelpTopicIds.fsaEditorStates: HelpNodeCopy(
    title: 'Add and edit states',
    body: 'States represent the finite memory positions of an automaton. Use '
        'them to mark where processing starts, which situations can occur, and '
        'where input is accepted. Choose Add state and place a state, then '
        'select it to edit its label, Initial state, or Accepting state and to '
        'delete it. The canvas updates the marker and every connected '
        'transition when the state changes. State labels should be clear, only '
        'one state can be initial, and deleting a state also removes its '
        'transitions. Continue with Add and edit transitions.',
    keywords: [
      'state',
      'Add state',
      'initial state',
      'accepting state',
      'delete'
    ],
  ),
  HelpTopicIds.fsaEditorTransitions: HelpNodeCopy(
    title: 'Add and edit transitions',
    body: 'Transitions describe which state follows for an input symbol. Use '
        'them to define the behavior of the automaton for every relevant '
        'symbol. Choose Add transition, select the source and target states, '
        'then enter a symbol or choose the λ option; select an edge to edit or '
        'delete it. The canvas draws a directed labeled edge and validation '
        'recalculates the alphabet and determinism. A DFA cannot have λ '
        'transitions or two destinations for the same state and symbol, while '
        'an NFA can. Continue with Determinism and validation.',
    keywords: ['transition', 'Add transition', 'symbol', 'lambda', 'edge'],
  ),
  HelpTopicIds.fsaEditorDeterminism: HelpNodeCopy(
    title: 'Determinism and validation',
    body: 'The determinism badge and validation status summarize whether the '
        'current automaton satisfies key structural rules. Use them before '
        'simulation and before running an algorithm that requires a DFA. '
        'Inspect the status text and open the determinism details to locate '
        'missing initial or accepting states, λ transitions, or competing '
        'transitions. The indicators update as you edit and distinguish a DFA '
        'from an NFA. A badge is diagnostic rather than a repair command, and '
        'some algorithms remain disabled or report an error until the model is '
        'valid. Continue with DFA, NFA, or transition editing.',
    keywords: ['determinism', 'validation', 'DFA', 'NFA', 'diagnostics'],
  ),
  HelpTopicIds.fsaEditorHistoryAndClear: HelpNodeCopy(
    title: 'Undo, redo, and clear',
    body: 'History controls reverse or restore canvas edits, while Clear '
        'canvas removes the current automaton. Use Undo after an unwanted edit, '
        'Redo after reversing too far, and Clear canvas only when you want to '
        'start over. Select Undo or press Ctrl+Z; on Apple platforms with a '
        'physical keyboard, Cmd+Z works too. For Redo, use Ctrl+Y or '
        'Ctrl+Shift+Z, or use Cmd+Y or Cmd+Shift+Z on Apple platforms with a '
        'physical keyboard. The canvas and validation return to the saved '
        'editing state. History is limited to recorded canvas changes, and '
        'Clear canvas is destructive even though it can be undone while '
        'history remains available. Continue with Selection or Files and '
        'examples before replacing substantial work.',
    keywords: ['undo', 'redo', 'clear canvas', 'Ctrl Z', 'Cmd Z'],
  ),
  'fsa.editor.viewport': HelpNodeCopy(
    title: 'Canvas view',
    keywords: ['viewport', 'zoom', 'fit', 'layout'],
  ),
  HelpTopicIds.fsaEditorViewportZoom: HelpNodeCopy(
    title: 'Zoom and pan',
    body: 'Zoom and pan change the view without changing the automaton. Use '
        'them to inspect dense transitions or move across a larger canvas. '
        'Select Zoom in or Zoom out, use the pointer zoom gesture where '
        'available, pinch with two fingers on touch screens, and drag empty '
        'canvas space to pan. States and transitions keep their model positions '
        'while the viewport scale and offset change. A one-finger drag on a '
        'state moves that state in Select mode, so start a pan on empty space. '
        'Continue with Fit to content and Reset view.',
    keywords: ['zoom', 'pan', 'pinch', 'touch', 'viewport'],
  ),
  HelpTopicIds.fsaEditorViewportFitAndReset: HelpNodeCopy(
    title: 'Fit to content and reset view',
    body: 'Fit to content frames the complete automaton, while Reset view '
        'restores the default zoom and pan. Use Fit to content after states '
        'move off-screen and Reset view when you want a neutral viewport. '
        'Select Fit to content or Reset view in the canvas controls. Only the '
        'viewport changes; the positions stored for states remain unchanged. '
        'An empty canvas has no content to fit, and neither action repairs an '
        'overlapping layout. Continue with Auto Layout when state positions '
        'need rearranging.',
    keywords: ['Fit to content', 'Reset view', 'frame', 'viewport'],
  ),
  HelpTopicIds.fsaEditorViewportAutoLayout: HelpNodeCopy(
    title: 'Auto Layout',
    body: 'Auto Layout rearranges the current states into a circular layout. '
        'Use it when manual positions overlap or make transitions difficult to '
        'read. Open Algorithms and select Auto Layout. State coordinates '
        'change and connected transitions redraw around the new arrangement. '
        'The command does not change labels, markers, transitions, or language, '
        'and a complex graph may still need manual adjustments. Continue with '
        'Select and move items to refine the result.',
    keywords: ['Auto Layout', 'arrange', 'circle', 'overlap'],
  ),
  'fsa.editor.simulation': HelpNodeCopy(
    title: 'Simulation',
    keywords: ['simulation', 'input', 'result', 'trace'],
  ),
  HelpTopicIds.fsaEditorSimulationInputAndRun: HelpNodeCopy(
    blocks: _fsaSimulationBlocks,
    title: 'Enter input and run a simulation',
    body: 'The simulation input is the string the automaton will try to '
        'consume. Use it to check whether a particular string belongs to the '
        'modeled language. Enter text in Input String, leave it blank for ε, '
        'enable Step-by-Step Mode if you want a trace, and select Simulate; '
        'while the run is active, Simulating... replaces and disables the '
        'action because the FSA panel has no cancel command. The panel reports '
        'progress and then produces a simulation result. The automaton needs a '
        'usable initial state, spaces are '
        'preserved, and search limits can stop paths in highly branching NFAs. '
        'Continue with Results and playback.',
    keywords: [
      'Input String',
      'Simulate',
      'Run simulation',
      'cancel',
      'epsilon'
    ],
  ),
  HelpTopicIds.fsaEditorSimulationResultsAndPlayback: HelpNodeCopy(
    blocks: _fsaSimulationBlocks,
    title: 'Read results and play back steps',
    body: 'Simulation results explain whether the input was Accepted or '
        'Rejected and can show the path taken through the automaton. Use the '
        'trace to study a run or diagnose an unexpected result. Enable '
        'Step-by-Step Mode before running, then use Previous step, Next step, '
        'Play, Pause, Reset, the timeline, playback speed, or View on Canvas. '
        'The selected step highlights its active state and transition and '
        'annotates consumed and remaining input. A rejected NFA may represent '
        'exhausted alternatives rather than one single failed path, and no '
        'trace exists when recording was disabled. Continue with Alphabet and '
        'acceptance or edit the reported transition.',
    keywords: ['Accepted', 'Rejected', 'View on Canvas', 'playback', 'trace'],
  ),
  'fsa.editor.algorithms': HelpNodeCopy(
    title: 'Algorithms',
    keywords: ['algorithms', 'conversion', 'operations', 'steps'],
  ),
  HelpTopicIds.fsaEditorAlgorithmsOverview: HelpNodeCopy(
    blocks: _fsaAlgorithmBlocks,
    title: 'Finite automata algorithms overview',
    body: 'The Algorithms panel converts, combines, simplifies, and analyzes '
        'finite automata. Use it after building or loading an automaton when '
        'you need an equivalent form or a derived language. Open Algorithms '
        'and select Regex to NFA, NFA to DFA, Remove λ-transitions, Minimize '
        'DFA, Complete DFA, Complement DFA, Union of DFAs, Intersection of '
        'DFAs, Difference of DFAs, Prefix Closure, Suffix Closure, FA to Regex, '
        'FSA to Grammar, or Compare Equivalence. The panel shows progress, '
        'status, and the generated result or comparison. Each command enforces '
        'its own DFA, NFA, file, or structural requirements and leaves an error '
        'message when they are not met. Open the topic for the chosen '
        'algorithm or Step-by-Step Mode.',
    keywords: ['Algorithms', 'DFA operations', 'conversion', 'comparison'],
  ),
  HelpTopicIds.fsaEditorAlgorithmsRegexToNfa: HelpNodeCopy(
    blocks: _fsaAlgorithmBlocks,
    title: 'Regex to NFA',
    body: 'Regex to NFA builds a nondeterministic automaton for a regular '
        'expression. Use it when an expression is easier to write than the '
        'equivalent state graph. In Algorithms, enter a valid value in Regular '
        'Expression and activate the arrow beside Regex to NFA. The generated '
        'NFA becomes available on the canvas with states and transitions for '
        'the same language. Invalid syntax or an empty expression prevents '
        'conversion, and the result may contain λ transitions. Continue with '
        'NFA to DFA or the NFA theory topic.',
    keywords: ['Regex to NFA', 'regular expression', 'conversion', 'lambda'],
  ),
  HelpTopicIds.fsaEditorAlgorithmsNfaToDfa: HelpNodeCopy(
    blocks: _fsaAlgorithmBlocks,
    title: 'NFA to DFA',
    body: 'NFA to DFA applies subset construction to create a deterministic '
        'automaton for the same language. Use it when simulation or another '
        'operation requires a DFA. Build or load an NFA, open Algorithms, and '
        'select NFA to DFA. The result represents NFA state sets as DFA states '
        'and preserves acceptance. A missing initial state or malformed '
        'transition prevents conversion, and the number of reachable subsets '
        'can grow quickly. Continue with Minimize DFA or DFA theory.',
    keywords: ['NFA to DFA', 'subset construction', 'determinize', 'DFA'],
  ),
  HelpTopicIds.fsaEditorAlgorithmsRemoveLambda: HelpNodeCopy(
    blocks: _fsaAlgorithmBlocks,
    title: 'Remove λ-transitions',
    body: 'Remove λ-transitions creates an equivalent automaton without '
        'epsilon moves. Use it before operations that require every transition '
        'to consume a symbol. Open Algorithms and select Remove λ-transitions '
        'for the current automaton. The result propagates reachability and '
        'acceptance through epsilon closures while removing λ edges. The '
        'automaton needs a valid initial structure, and the transformed graph '
        'can contain more symbol transitions. Continue with Epsilon closure or '
        'NFA to DFA.',
    keywords: ['Remove lambda', 'epsilon', 'lambda transition', 'closure'],
  ),
  HelpTopicIds.fsaEditorAlgorithmsMinimizeDfa: HelpNodeCopy(
    blocks: _fsaAlgorithmBlocks,
    title: 'Minimize DFA',
    body: 'Minimize DFA merges indistinguishable states in a deterministic '
        'automaton. Use it to obtain a smaller DFA that accepts the same '
        'language. Make the current automaton deterministic, open Algorithms, '
        'and select Minimize DFA. The result removes unreachable distinctions '
        'and combines equivalent state classes. λ transitions, nondeterminism, '
        'or an invalid initial structure prevent minimization, and state labels '
        'can change. Continue with Equivalence to compare the languages.',
    keywords: ['Minimize DFA', 'state reduction', 'equivalent states', 'DFA'],
  ),
  HelpTopicIds.fsaEditorAlgorithmsCompleteDfa: HelpNodeCopy(
    blocks: _fsaAlgorithmBlocks,
    title: 'Complete DFA',
    body:
        'Complete DFA adds the missing transitions needed for every state and '
        'alphabet symbol. Use it when a total transition function is required '
        'or when you want to inspect the form used for complement. Open '
        'Algorithms and select Complete DFA. The result adds a trap state and '
        'routes previously missing cases to it. The input must be deterministic '
        'and free of λ transitions, and an already complete DFA may change '
        'little or not at all. Continue with Complement DFA.',
    keywords: ['Complete DFA', 'trap state', 'total transition', 'alphabet'],
  ),
  HelpTopicIds.fsaEditorAlgorithmsComplementDfa: HelpNodeCopy(
    blocks: _fsaAlgorithmBlocks,
    title: 'Complement DFA',
    body: 'Complement DFA builds an automaton that accepts exactly the strings '
        'the original DFA rejects over its alphabet. Use it to negate a regular '
        'language. Open Algorithms and select Complement DFA; the command '
        'completes missing transitions internally before changing acceptance. '
        'The result swaps accepting and non-accepting states without leaving '
        'undefined input cases. The source must be deterministic and free of λ '
        'transitions, but it does not need manual completion first. Continue '
        'with Complete DFA or Equivalence.',
    keywords: [
      'Complement DFA',
      'negation',
      'accepting states',
      'complete DFA'
    ],
  ),
  HelpTopicIds.fsaEditorAlgorithmsUnion: HelpNodeCopy(
    blocks: _fsaAlgorithmBlocks,
    title: 'Union of DFAs',
    body: 'Union of DFAs accepts strings accepted by either of two automata. '
        'Use it to combine two regular languages with logical OR. Open '
        'Algorithms, select Union of DFAs, and choose the second DFA in the '
        'platform file picker. The product result marks a pair accepting when '
        'either component is accepting. Both inputs must be loadable DFAs; the '
        'operation combines their alphabets and completes missing cases, while '
        'canceling file selection leaves the current automaton unchanged. '
        'Continue with Closure operations or Equivalence.',
    keywords: ['Union of DFAs', 'union', 'OR', 'file picker', 'product'],
  ),
  HelpTopicIds.fsaEditorAlgorithmsIntersection: HelpNodeCopy(
    blocks: _fsaAlgorithmBlocks,
    title: 'Intersection of DFAs',
    body: 'Intersection of DFAs accepts strings accepted by both of two '
        'automata. Use it to combine regular-language requirements with logical '
        'AND. Open Algorithms, select Intersection of DFAs, and choose the '
        'second DFA in the platform file picker. The product result marks a '
        'pair accepting only when both components are accepting. Both inputs '
        'must be loadable DFAs; the operation combines their alphabets and '
        'completes missing cases, while canceling selection does not alter the '
        'current model. Continue with Closure operations or Equivalence.',
    keywords: ['Intersection of DFAs', 'intersection', 'AND', 'file picker'],
  ),
  HelpTopicIds.fsaEditorAlgorithmsDifference: HelpNodeCopy(
    blocks: _fsaAlgorithmBlocks,
    title: 'Difference of DFAs',
    body: 'Difference of DFAs accepts strings in the current DFA but not in a '
        'second DFA. Use it to subtract one regular language from another. Open '
        'Algorithms, select Difference of DFAs, and choose the DFA to subtract '
        'in the platform file picker. The product result combines acceptance '
        'from the first automaton with rejection from the second. Both files '
        'must describe valid DFAs; their alphabets are combined, and operand '
        'order changes the result. Continue with Closure operations or '
        'Equivalence.',
    keywords: ['Difference of DFAs', 'difference', 'subtract', 'file picker'],
  ),
  HelpTopicIds.fsaEditorAlgorithmsPrefixClosure: HelpNodeCopy(
    blocks: _fsaAlgorithmBlocks,
    title: 'Prefix Closure',
    body: 'Prefix Closure creates an automaton that accepts every prefix of a '
        'string in the current DFA language. Use it when any valid beginning '
        'of an accepted word should also be accepted. Open Algorithms and '
        'select Prefix Closure. The result updates acceptance so states that '
        'can still reach an accepting state recognize valid prefixes. The '
        'operation expects a valid DFA, and a prefix includes the complete word '
        'and may include ε. Continue with Closure operations or Suffix Closure.',
    keywords: ['Prefix Closure', 'prefix', 'regular language', 'acceptance'],
  ),
  HelpTopicIds.fsaEditorAlgorithmsSuffixClosure: HelpNodeCopy(
    blocks: _fsaAlgorithmBlocks,
    title: 'Suffix Closure',
    body: 'Suffix Closure creates an automaton that accepts every suffix of a '
        'string in the current DFA language. Use it when valid endings of '
        'accepted words should become the language. Open Algorithms and select '
        'Suffix Closure. The result introduces nondeterministic starting '
        'possibilities and then constructs the derived automaton. The current '
        'model must be valid, and the result can need more states after '
        'determinization. Continue with Closure operations or NFA to DFA.',
    keywords: ['Suffix Closure', 'suffix', 'regular language', 'NFA'],
  ),
  HelpTopicIds.fsaEditorAlgorithmsFaToRegex: HelpNodeCopy(
    blocks: _fsaAlgorithmBlocks,
    title: 'FA to Regex',
    body: 'FA to Regex derives a regular expression for the language of the '
        'current finite automaton. Use it when you need a textual equivalent '
        'of a state graph. Open Algorithms and select FA to Regex. The panel '
        'returns a regular expression produced by eliminating states while '
        'preserving accepted paths. A valid initial state and acceptance '
        'structure are required, and equivalent expressions can look very '
        'different or become large. Continue with Equivalence or Regex to NFA.',
    keywords: ['FA to Regex', 'regular expression', 'state elimination'],
  ),
  HelpTopicIds.fsaEditorAlgorithmsFsaToGrammar: HelpNodeCopy(
    blocks: _fsaAlgorithmBlocks,
    title: 'FSA to Grammar',
    body: 'FSA to Grammar converts the automaton into an equivalent '
        'right-linear grammar. Use it to study the connection between regular '
        'grammars and finite automata. Open Algorithms and select FSA to '
        'Grammar. The result maps states to variables, labeled transitions to '
        'productions, and acceptance to terminating productions. The current '
        'automaton needs a valid initial state, and generated variable names '
        'may differ from state labels. Continue in the Grammar workspace or '
        'read Equivalence.',
    keywords: ['FSA to Grammar', 'regular grammar', 'production', 'conversion'],
  ),
  HelpTopicIds.fsaEditorAlgorithmsEquivalence: HelpNodeCopy(
    blocks: _fsaAlgorithmBlocks,
    title: 'Compare Equivalence',
    body: 'Compare Equivalence checks whether two finite automata accept the '
        'same language. Use it to verify a conversion, simplification, or '
        'independently built model. Open Algorithms, select Compare '
        'Equivalence, and choose the other automaton in the platform file '
        'picker. The comparison reports equivalent or not equivalent and can '
        'show details or a distinguishing input. Both automata must load with '
        'initial states; the comparison combines different alphabets and '
        'determinizes when needed, while malformed structures block the run. '
        'Continue with the theory of Equivalence.',
    keywords: [
      'Compare Equivalence',
      'same language',
      'counterexample',
      'file'
    ],
  ),
  HelpTopicIds.fsaEditorAlgorithmsStepMode: HelpNodeCopy(
    blocks: _fsaAlgorithmBlocks,
    title: 'Step-by-Step Mode',
    body: 'Step-by-Step Mode records intermediate stages of supported '
        'algorithms. Use it when learning a transformation or checking how a '
        'result was produced. Turn on Step-by-Step Mode before selecting an '
        'algorithm, then use Previous Step, Next Step, Play, Pause, Reset, or '
        'the step navigator. The viewer shows the active explanation and '
        'snapshot for each recorded stage. Some commands do not emit detailed '
        'steps, and changing or rerunning the algorithm replaces the previous '
        'sequence. Continue with the specific algorithm topic.',
    keywords: ['Step-by-Step Mode', 'steps', 'navigator', 'playback'],
  ),
  HelpTopicIds.fsaEditorFilesAndExamples: HelpNodeCopy(
    title: 'FSA files and examples',
    body: 'FSA file actions import, save, or render automata, while bundled '
        'examples provide ready-made models. Open Algorithms and select AFD - '
        'Termina com A, AFD - Binário divisível por 3, AFD - Paridade AB, '
        'AFD - Contém AB, or AFNλ - A ou AB. The selected example replaces the '
        'current FSA and is available even when the canvas is empty. Use JFLAP '
        'or JSON to continue editing and SVG or PNG to share a visual result. '
        'In File Operations, '
        'select Load JFLAP or Load JSON and choose a file; on native platforms '
        'use Save as JFLAP, Save as JSON, Export SVG, or Export PNG, while Web '
        'shows Download JFLAP, Download JSON, and Download SVG. A successful '
        'import loads the chosen automaton and a successful export confirms the '
        'created file. JFLAP uses .jff, malformed files show an import error, '
        'canceling selection changes nothing, and native PNG export is not '
        'offered on Web. Continue with Files and examples or the editor overview.',
    keywords: ['JFLAP', 'JSON', 'SVG', 'PNG', 'examples', 'import', 'export'],
  ),
  'fsa.theory': HelpNodeCopy(
    title: 'Theory',
    keywords: ['theory', 'regular language', 'DFA', 'NFA'],
  ),
  HelpTopicIds.fsaTheoryDfa: HelpNodeCopy(
    title: 'Deterministic finite automata (DFA)',
    body: 'A DFA is a finite automaton with exactly one next state for each '
        'state and input symbol. Use the model for regular languages whose next '
        'step is unambiguous. In the FSA editor, create one initial state, mark '
        'accepting states, and give each state at most one transition per '
        'symbol with no λ transitions. A run follows one path and accepts only '
        'if it ends in an accepting state after consuming all input. Missing '
        'transitions make a DFA incomplete, while duplicate symbol choices make '
        'it nondeterministic. Continue with NFA or Complete DFA.',
    keywords: [
      'DFA',
      'deterministic',
      'regular language',
      'transition function'
    ],
  ),
  HelpTopicIds.fsaTheoryNfa: HelpNodeCopy(
    title: 'Nondeterministic finite automata (NFA)',
    body: 'An NFA may have several next states for one symbol and may include '
        'epsilon moves. Use it when branching or a compact construction makes '
        'a regular language easier to express. In the editor, add competing '
        'transitions or λ transitions and simulate an input across the '
        'available paths. The NFA accepts when at least one path consumes the '
        'whole input and reaches an accepting state. Branching can enlarge '
        'traces and searches, but it does not make the recognized language more '
        'powerful than a DFA. Continue with NFA to DFA or Epsilon transitions.',
    keywords: ['NFA', 'nondeterministic', 'branching', 'epsilon'],
  ),
  HelpTopicIds.fsaTheoryStates: HelpNodeCopy(
    title: 'States',
    body: 'A state records the finite amount of history the automaton needs at '
        'one point in a run. Use distinct states for situations that require '
        'different future behavior. Add and label states on the canvas, choose '
        'one initial state, and mark every accepting condition as accepting. '
        'Simulation moves the active marker among these states as it consumes '
        'input. Labels are descriptive rather than semantic, and acceptance '
        'depends on the marker and completed input, not the state name. '
        'Continue with Transitions or Alphabet and acceptance.',
    keywords: ['states', 'initial', 'accepting', 'finite memory'],
  ),
  HelpTopicIds.fsaTheoryTransitions: HelpNodeCopy(
    title: 'Transitions',
    body: 'A transition is a directed rule from one state to another, normally '
        'labeled by the input it consumes. Use transitions to define every '
        'legal next step of a run. Connect source and target states and assign '
        'a symbol, or assign λ for an epsilon move in an NFA. Simulation follows '
        'matching edges and changes the active state. A symbol transition '
        'cannot match a different input symbol, and competing matches introduce '
        'nondeterminism. Continue with Alphabet and acceptance or Epsilon '
        'transitions.',
    keywords: ['transitions', 'edge', 'symbol', 'next state'],
  ),
  HelpTopicIds.fsaTheoryAlphabetAndAcceptance: HelpNodeCopy(
    title: 'Alphabet and acceptance',
    body: 'The alphabet is the set of input symbols on consuming transitions, '
        'and acceptance is the condition for membership in the automaton language. '
        'Use both concepts to define what inputs are meaningful and which are '
        'successful. Label transitions with alphabet symbols, start at the '
        'initial state, consume the full string, and check whether a path ends '
        'in an accepting state. Accepted means at least one valid complete path '
        'exists; Rejected means none does. λ is not an alphabet symbol, and '
        'stopping early in an accepting state does not accept unconsumed input. '
        'Continue with DFA, NFA, or simulation results.',
    keywords: ['alphabet', 'acceptance', 'Accepted', 'Rejected', 'language'],
  ),
  HelpTopicIds.fsaTheoryEpsilon: HelpNodeCopy(
    title: 'Epsilon and λ-transitions',
    body: 'Epsilon, shown as ε or λ, represents the empty string, and a '
        'λ-transition changes state without consuming input. Use epsilon moves '
        'in an NFA when a construction needs optional or spontaneous branching. '
        'Choose the λ option while editing a transition and follow those edges '
        'before or between symbol moves during analysis. All states reachable '
        'through such moves become possible current states. A DFA cannot '
        'contain λ transitions, and cycles of epsilon moves must not be treated '
        'as consumed input. Continue with Epsilon closure or Remove '
        'λ-transitions.',
    keywords: ['epsilon', 'lambda', 'empty string', 'lambda transition'],
  ),
  HelpTopicIds.fsaTheoryEpsilonClosure: HelpNodeCopy(
    title: 'Epsilon closure',
    body: 'The epsilon closure of a state or state set contains every state '
        'reachable using only λ transitions, including the starting states. Use '
        'it to understand NFA simulation, lambda removal, and subset '
        'construction. Begin with the current set and repeatedly follow all '
        'outgoing λ edges until no new state appears. The complete reached set '
        'participates before the next symbol is consumed. Forgetting the '
        'starting state or stopping after one λ edge produces an incorrect '
        'closure. Continue with Remove λ-transitions or NFA to DFA.',
    keywords: ['epsilon closure', 'lambda closure', 'reachable', 'NFA'],
  ),
  HelpTopicIds.fsaTheoryEquivalence: HelpNodeCopy(
    title: 'Language equivalence',
    body:
        'Two finite automata are equivalent when they accept exactly the same '
        'set of strings. Use equivalence to validate conversions, minimization, '
        'or two different designs. Compare their behavior through Compare '
        'Equivalence or reason over a product construction that searches for '
        'different acceptance. An equivalent result means no distinguishing '
        'input was found; a non-equivalent result can identify a counterexample. '
        'Matching diagrams or state names are unnecessary, while one differing '
        'string is enough to disprove equivalence. Continue with Compare '
        'Equivalence or Minimize DFA.',
    keywords: ['equivalence', 'same language', 'counterexample', 'comparison'],
  ),
  HelpTopicIds.fsaTheoryClosureOperations: HelpNodeCopy(
    title: 'Closure operations',
    body: 'Regular languages remain regular under operations such as union, '
        'intersection, difference, complement, prefix closure, and suffix '
        'closure. Use this fact to build a finite automaton for a language '
        'derived from existing regular languages. Choose the corresponding '
        'Algorithms command and provide a second DFA when the operation is '
        'binary. The generated automaton recognizes the mathematically derived '
        'language. Binary operations depend on operand order where applicable '
        'and require valid deterministic inputs. Mathematical complement '
        'assumes a total transition function, but the current Complement DFA '
        'command completes missing transitions internally and requires only a '
        'valid deterministic input without λ transitions. Continue with the '
        'specific operation or Equivalence.',
    keywords: ['closure', 'union', 'intersection', 'difference', 'complement'],
  ),
  'grammar': HelpNodeCopy(
    title: 'Grammars',
    keywords: ['grammar', 'CFG', 'productions', 'parsing'],
  ),
  'grammar.editor': HelpNodeCopy(
    title: 'Editor and parser',
    keywords: ['editor', 'parser', 'algorithms', 'conversions'],
  ),
  HelpTopicIds.grammarEditorOverview: HelpNodeCopy(
    title: 'Grammar editor overview',
    body: 'The Grammar workspace combines a production editor, the Grammar '
        'Parser, and Grammar Analysis. Use it to define a grammar, test a '
        'string, transform rules, or convert the model. Enter Grammar Name and '
        'Start Symbol, add rules with Left Side (Variable) and Right Side '
        '(Production), then open Parse or Algorithms. The provider infers '
        'uppercase single-letter non-terminals and other symbols as terminals '
        'when it builds the model. Invalid or empty rules block later work, so '
        'continue with Symbols and the start symbol before parsing.',
    keywords: ['Grammar Editor', 'Grammar Name', 'Start Symbol', 'Parse'],
  ),
  'grammar.editor.productions': HelpNodeCopy(
    title: 'Productions',
    keywords: ['production', 'rule', 'left side', 'right side'],
  ),
  HelpTopicIds.grammarEditorProductionSymbols: HelpNodeCopy(
    title: 'Symbols and the start symbol',
    body: 'Grammar symbols are classified as non-terminals or terminals, and '
        'Start Symbol identifies where derivations begin. Use these fields '
        'before adding rules that the parser or analyzers must interpret. Enter '
        'a Grammar Name, set Start Symbol, and use one symbol such as S on each '
        'Left Side (Variable); uppercase single letters on right sides are '
        'inferred as non-terminals. The built grammar collects left-side '
        'symbols as non-terminals and the remaining right-side symbols as '
        'terminals. An empty start-symbol edit is ignored, while a start symbol '
        'must ultimately belong to the non-terminal set; continue with '
        'Production rows and alternatives.',
    keywords: ['Start Symbol', 'terminal', 'non-terminal', 'Grammar Name'],
  ),
  HelpTopicIds.grammarEditorProductionRowsAndAlternatives: HelpNodeCopy(
    title: 'Production rows and alternatives',
    body: 'Each production row stores one left side and one right-side '
        'alternative. Use multiple rows when a variable has alternatives such '
        'as S → aS and S → b. Fill Left Side (Variable) and Right Side '
        '(Production), select Add, and use a row menu for Edit or Delete; '
        'Update and Cancel appear while editing. Production Rules shows the '
        'numbered rules in source order. A compact value such as aA is split '
        'into characters, while whitespace separates multi-character symbols; '
        'do not type the vertical bar as an alternative separator. Continue '
        'with Empty productions for λ and ε.',
    keywords: ['Add', 'Edit', 'Delete', 'Update', 'Production Rules'],
  ),
  HelpTopicIds.grammarEditorProductionLambda: HelpNodeCopy(
    title: 'Empty productions with λ and ε',
    body: 'A λ- or ε-production derives the empty string. Use it when a '
        'non-terminal may disappear or the grammar must accept the empty '
        'input. In Right Side (Production), select Insert λ or Insert ε, or '
        'type λ, ε, or lambda, then add the rule. The editor stores the right '
        'side as empty and displays it as ε. The empty marker must be the only '
        'right-side symbol, so mixing it with another symbol or entering more '
        'than one marker produces a validation message. Continue with '
        'Production validation.',
    keywords: ['lambda', 'epsilon', 'Insert λ', 'Insert ε', 'empty string'],
  ),
  HelpTopicIds.grammarEditorProductionValidation: HelpNodeCopy(
    title: 'Production validation and clearing',
    body: 'Production validation keeps malformed editor rows from entering the '
        'grammar. Use it when Add or Update does nothing or a later analysis '
        'reports validation errors. Supply both sides, put exactly one symbol '
        'on the left, and put at least one ordinary symbol or one λ/ε marker on '
        'the right; use Clear to remove every production after confirming. '
        'Inline messages identify the failing side, and Clear offers Undo in '
        'its confirmation feedback. The editor validates row shape rather than '
        'proving language properties, and analysis also requires a non-empty '
        'grammar with a declared start symbol. Continue with Parser workflow.',
    keywords: ['validation', 'Clear', 'Undo', 'error', 'rule shape'],
  ),
  'grammar.editor.parser': HelpNodeCopy(
    title: 'Grammar parser',
    keywords: ['parser', 'string', 'Earley', 'CYK'],
  ),
  HelpTopicIds.grammarEditorParserWorkflow: HelpNodeCopy(
    blocks: _grammarParserBlocks,
    title: 'Parse a string',
    body: 'The Grammar Parser tests whether the current grammar derives a Test '
        'String. Use it after the grammar has at least one production and a '
        'valid Start Symbol. Open Parse, choose an available Parsing Algorithm, '
        'enter only symbols in the inferred terminal alphabet, and select Parse '
        'String; the button reads Parsing... and is disabled while work runs. '
        'Parse Results reports Accepted or Rejected with execution time and '
        'strategy-specific details. Empty grammars, invalid start symbols, '
        'unknown input characters, timeouts, or parser errors produce messages; '
        'continue with Automatic (Earley) or CYK.',
    keywords: ['Grammar Parser', 'Test String', 'Parse String', 'Accepted'],
  ),
  HelpTopicIds.grammarEditorParserAutomaticEarley: HelpNodeCopy(
    blocks: _grammarParserBlocks,
    title: 'Automatic parsing with Earley',
    body: 'Automatic (Earley) is the available general CFG recognition option. '
        'Use it when the grammar is not known to suit a specialized parser or '
        'when robust acceptance matters more than a detailed CYK trace. Select '
        'Automatic (Earley), enter the string, and select Parse String; a '
        'balanced-parentheses grammar may take a fast path before Earley runs. '
        'The result gives acceptance and may add a best-effort derivation tree '
        'when recursive descent can reconstruct one. Recognition uses a '
        'five-second timeout and an accepted result can legitimately have no '
        'tree; continue with Results, trees, and CYK steps.',
    keywords: ['Automatic (Earley)', 'Earley', 'CFG', 'recognition', 'timeout'],
  ),
  HelpTopicIds.grammarEditorParserBruteForce: HelpNodeCopy(
    blocks: _grammarParserBlocks,
    title: 'Brute-force parsing',
    body: 'Brute force searches productions recursively for a derivation. Use '
        'it for small teaching examples where seeing a simple derivation is '
        'more useful than broad grammar coverage. Select Brute force, enter a '
        'short Test String, and activate Parse String. An accepted run may '
        'produce a shallow derivation tree, while exhausted search reports '
        'Rejected. The recursive strategy is limited, can grow rapidly, and '
        'shares the five-second parsing timeout, so use Automatic (Earley) for '
        'general recognition or continue with Derivations.',
    keywords: ['Brute force', 'recursive descent', 'derivation', 'timeout'],
  ),
  HelpTopicIds.grammarEditorParserCyk: HelpNodeCopy(
    blocks: _grammarParserBlocks,
    title: 'CYK parsing',
    body: 'CYK (Cocke-Younger-Kasami) recognizes a string with a dynamic '
        'programming table. Use it when you want a deterministic table-filling '
        'explanation or to study parsing through Chomsky Normal Form. Select '
        'CYK (Cocke-Younger-Kasami), enter Test String, and select Parse String; '
        'the parser converts a copy to CNF internally without changing the '
        'editor grammar. Parse Results shows acceptance, execution time, and a '
        'navigable CYK Steps sequence. Conversion or parsing can fail and the '
        'five-second limit returns CYK parsing timed out; continue with CNF or '
        'Results, trees, and CYK steps.',
    keywords: ['CYK', 'Cocke-Younger-Kasami', 'CNF', 'table', 'steps'],
  ),
  HelpTopicIds.grammarEditorParserLl1: HelpNodeCopy(
    blocks: _grammarParserBlocks,
    title: 'LL(1) predictive parser',
    body: 'LL(1) parsing chooses one production from the current non-terminal '
        'and one lookahead token. Select LL(1), enter a Test String, and select '
        'Parse String. The parser builds the FIRST/FOLLOW table, rejects the '
        'run if any cell conflicts, and otherwise records each expansion, '
        'terminal match, acceptance, or error. LL(1) Steps shows the stack, '
        'remaining input, lookahead, and selected production. Input is split '
        'into declared terminals by longest match, with lexical order breaking '
        'equal-length ties. Remove left recursion or factor the grammar before '
        'parsing when required; continue with Predictive parsing and LL(1) tables.',
    keywords: ['LL(1)', 'predictive parser', 'lookahead', 'stack', 'steps'],
  ),
  HelpTopicIds.grammarEditorParserLr: HelpNodeCopy(
    blocks: _grammarParserBlocks,
    title: 'LR parser availability',
    body:
        'LR is a bottom-up parsing family for context-free grammars. Use this '
        'topic to distinguish the theory from the current executable parser '
        'choices. LR is unavailable because the parser is not implemented, so '
        'it is filtered out of the Parsing Algorithm menu. No LR state '
        'machine, table, or parse result is '
        'generated by the current workspace. Build Parse Table currently '
        'produces an LL(1) table despite its description mentioning LR(1); '
        'continue with Predictive parsing or Automatic (Earley).',
    keywords: ['LR', 'LR(1)', 'unavailable', 'bottom-up', 'parse table'],
  ),
  HelpTopicIds.grammarEditorParserResultsAndSteps: HelpNodeCopy(
    blocks: _grammarParserBlocks,
    title: 'Results, trees, and parser steps',
    body: 'Parse Results explains the outcome and any recorded structure from '
        'the selected parser. Use it to inspect why an input was accepted or '
        'where a rejected run stopped. Read Accepted or Rejected and Execution '
        'time; non-CYK rejection may show Farthest position, Expected symbols, '
        'and a message, while an accepted automatic or brute-force run may '
        'expand Derivation Tree. CYK Steps provides previous and next buttons, '
        'a slider, the selected step title, table highlights, and an '
        'explanation card. LL(1) Steps uses the same navigation to show stack, '
        'remaining input, lookahead, and production snapshots. Trees are '
        'best-effort; continue with Parse trees, CYK, or LL(1).',
    keywords: ['Parse Results', 'Derivation Tree', 'CYK Steps', 'LL(1) Steps'],
  ),
  'grammar.editor.algorithms': HelpNodeCopy(
    title: 'Analysis and transformations',
    keywords: ['analysis', 'transformation', 'FIRST', 'FOLLOW'],
  ),
  HelpTopicIds.grammarEditorAlgorithms: HelpNodeCopy(
    blocks: _grammarAlgorithmBlocks,
    title: 'Grammar algorithms overview',
    body: 'Grammar Analysis transforms rules and computes predictive-parsing '
        'data. Use it after editing a valid grammar when you need a normal '
        'form, structural rewrite, set calculation, table, or LL(1) conflict '
        'check. Choose Convert to CNF, Convert to GNF, Remove Left Recursion, '
        'Left Factor, Find First Sets, Find Follow Sets, Build Parse Table, or '
        'Check Ambiguity. The panel shows a textual analysis, and CNF/GNF also '
        'show Transformation steps whose Apply action replaces the editor '
        'grammar with that step result. Actions are disabled while an analysis '
        'runs, and invalid grammars produce a validation report; open the '
        'specific algorithm topic next.',
    keywords: ['Grammar Analysis', 'normal form', 'Apply', 'results'],
  ),
  HelpTopicIds.grammarEditorAlgorithmsCnf: HelpNodeCopy(
    blocks: _grammarAlgorithmBlocks,
    title: 'Convert to Chomsky Normal Form',
    body: 'Convert to CNF rewrites a CFG into Chomsky Normal Form. Use it for '
        'CYK study or when rules should have the forms A→BC or A→a, subject to '
        'the start-symbol empty-string exception. Select Convert to CNF in '
        'Grammar Analysis and inspect Transformation steps, Original Grammar, '
        'Transformed Grammar, notes, derivations, and diagnostics. Apply on a '
        'step replaces the current editor grammar with that intermediate '
        'result. Validation errors or error-severity conversion diagnostics '
        'stop the operation; continue with CNF theory or CYK.',
    keywords: ['Convert to CNF', 'Chomsky', 'A BC', 'Transformation steps'],
  ),
  HelpTopicIds.grammarEditorAlgorithmsGnf: HelpNodeCopy(
    blocks: _grammarAlgorithmBlocks,
    title: 'Convert to Greibach Normal Form',
    body:
        'Convert to GNF rewrites productions so each right side begins with a '
        'terminal followed by non-terminals. Use it to study Greibach Normal '
        'Form or prepare the Greibach PDA construction. Select Convert to GNF '
        'and inspect the transformation history, formatted grammars, notes, '
        'derivations, and diagnostics. Apply on a step loads that produced '
        'grammar into the editor. Invalid input or error diagnostics make the '
        'conversion fail instead of applying a partial result; continue with '
        'GNF theory or Convert Grammar to PDA (Greibach).',
    keywords: ['Convert to GNF', 'Greibach', 'terminal first', 'Apply'],
  ),
  HelpTopicIds.grammarEditorAlgorithmsRemoveLeftRecursion: HelpNodeCopy(
    blocks: _grammarAlgorithmBlocks,
    title: 'Remove direct and indirect left recursion',
    body: 'Remove Left Recursion handles direct rules such as A→Aα and '
        'indirect cycles such as A→Bα, B→Aβ. It processes the start symbol '
        'first, then uses production order and lexical ties for a stable '
        'ordered substitution. Inspect each substitution and direct-recursion '
        'step, including the primed non-terminals. Apply can load the grammar '
        'from any step into the editor. The action requires a valid non-empty '
        'grammar and does not perform left factoring or guarantee LL(1).',
    keywords: [
      'Remove Left Recursion',
      'direct recursion',
      'indirect recursion',
      'ordered substitution',
      'prime symbol'
    ],
  ),
  HelpTopicIds.grammarEditorAlgorithmsLeftFactor: HelpNodeCopy(
    blocks: _grammarAlgorithmBlocks,
    title: 'Left-factor productions',
    body: 'Left Factor extracts common prefixes into new non-terminals. Use it '
        'when alternatives begin the same way and a predictive parser cannot '
        'choose immediately. Select Left Factor and review Left Factoring '
        'Analysis, including the original grammar, transformed grammar, notes, '
        'and derived replacement rules. The analysis displays the result but '
        'does not automatically apply it to the editor. A valid non-empty '
        'grammar is required, and factoring does not by itself guarantee an '
        'LL(1) grammar; continue with FIRST, FOLLOW, and parse tables.',
    keywords: ['Left Factor', 'left factoring', 'common prefix', 'LL(1)'],
  ),
  HelpTopicIds.grammarEditorAlgorithmsFirst: HelpNodeCopy(
    blocks: _grammarAlgorithmBlocks,
    title: 'Compute FIRST sets',
    body: 'FIRST(X) contains terminals that can begin strings derived from X, '
        'including ε when X is nullable. Use it to analyze predictive choices '
        'and prepare an LL(1) table. Select Find First Sets and read each '
        'FIRST(non-terminal) set plus notes and derivation explanations in the '
        'analysis result. The grammar in the editor remains unchanged. Invalid '
        'symbols or productions stop the analysis, and FIRST alone does not '
        'resolve nullable continuations; continue with FOLLOW sets.',
    keywords: ['Find First Sets', 'FIRST', 'nullable', 'terminal'],
  ),
  HelpTopicIds.grammarEditorAlgorithmsFollow: HelpNodeCopy(
    blocks: _grammarAlgorithmBlocks,
    title: 'Compute FOLLOW sets',
    body: 'FOLLOW(A) contains terminals that may immediately follow A, with \$ '
        'marking end of input for the start symbol. Use it after FIRST when '
        'nullable alternatives or an LL(1) table need context. Select Find '
        'Follow Sets and inspect each FOLLOW(non-terminal) set, notes, and '
        'derivation explanations. The analysis computes FIRST internally and '
        'does not modify the grammar. A valid grammar and declared start symbol '
        'are required; continue with Build Parse Table.',
    keywords: ['Find Follow Sets', 'FOLLOW', 'end marker', 'nullable'],
  ),
  HelpTopicIds.grammarEditorAlgorithmsParseTable: HelpNodeCopy(
    blocks: _grammarAlgorithmBlocks,
    title: 'Build an LL(1) parse table',
    body: 'Build Parse Table constructs the current LL(1) predictive table. '
        'Use it after checking FIRST and FOLLOW to see which production is '
        'chosen for a non-terminal and lookahead. Select Build Parse Table and '
        'read the tab-separated rows, Notes, Conflicts, and Derivations in '
        'LL(1) Parse Table Analysis. Empty cells appear as -, ε rules use '
        'FOLLOW, and multiple entries identify a conflict. Despite the button '
        'description mentioning LL(1) or LR(1), the current result is LL(1) '
        'only; continue with Check Ambiguity or predictive-parsing theory.',
    keywords: ['Build Parse Table', 'LL(1)', 'lookahead', 'conflict'],
  ),
  HelpTopicIds.grammarEditorAlgorithmsAmbiguity: HelpNodeCopy(
    blocks: _grammarAlgorithmBlocks,
    title: 'Interpret the ambiguity check',
    body: 'Check Ambiguity is an educational LL(1) conflict check, not a '
        'general proof of ambiguity. Use it to classify whether the current '
        'predictive table has competing entries. Select Check Ambiguity and '
        'read LL(1) Classification, Notes, Conflicts, and Derivations. No '
        'conflicts yields LL(1) (no conflicts); conflicts yield Not LL(1) '
        '(conflicts). A non-LL(1) grammar can still be unambiguous and may need '
        'LR or Earley, so continue with Ambiguity theory and parse trees.',
    keywords: ['Check Ambiguity', 'LL(1)', 'conflict', 'classification'],
  ),
  'grammar.editor.conversions': HelpNodeCopy(
    title: 'Conversions',
    keywords: ['conversion', 'FSA', 'PDA', 'Greibach'],
  ),
  HelpTopicIds.grammarEditorConversionsRightLinearToFsa: HelpNodeCopy(
    title: 'Right-linear grammar to FSA',
    body: 'Convert Right-Linear Grammar to FSA builds an equivalent finite '
        'automaton. Use it only for rules A→aB, A→a, or A→ε. Add at least one '
        'production and select Convert Right-Linear Grammar to FSA under '
        'Conversions. Success loads the generated automaton and switches to '
        'the FSA workspace. No productions or any conversion already running '
        'disables this control. An invalid start symbol or another conversion '
        'failure does not disable a non-empty grammar in advance; it returns '
        'an error after activation. Non-right-linear or undefined symbols are '
        'reported then instead of switching workspaces; continue with Grammar, '
        'FSA, and PDA relationships.',
    keywords: ['Convert Right-Linear Grammar to FSA', 'right-linear', 'FSA'],
  ),
  HelpTopicIds.grammarEditorConversionsPdaGeneral: HelpNodeCopy(
    title: 'Grammar to PDA: general construction',
    body: 'Convert Grammar to PDA (General) builds a three-state PDA from the '
        'current CFG by expanding variables on the stack. Use it when you want '
        'an automaton that recognizes the grammar language. Add productions '
        'and select Convert Grammar to PDA (General). Success loads the PDA, '
        'switches to the PDA workspace, and reports that the general conversion '
        'completed. No productions or any conversion already running disables '
        'this control. An invalid start symbol or another conversion failure '
        'does not disable a non-empty grammar in advance; it returns an error '
        'after activation. The conversion requires a start symbol that is a '
        'non-terminal and has a ten-second limit; continue with the PDA '
        'relationship theory.',
    keywords: ['Convert Grammar to PDA (General)', 'stack', 'CFG', 'PDA'],
  ),
  HelpTopicIds.grammarEditorConversionsPdaStandard: HelpNodeCopy(
    title: 'Grammar to PDA: standard construction',
    body: 'Convert Grammar to PDA (Standard) applies the standard CFG-to-PDA '
        'stack construction. Use it when you want the explicitly named '
        'standard route for comparison with the other conversion controls. Add '
        'productions and select Convert Grammar to PDA (Standard). The current '
        'implementation produces the same three-state construction as General, '
        'loads it, and switches to the PDA workspace. No productions or any '
        'conversion already running disables this control. An invalid start '
        'symbol or another conversion failure does not disable a non-empty '
        'grammar in advance; it returns an error after activation. The '
        'conversion has a ten-second limit; continue with General or Greibach '
        'conversion.',
    keywords: ['Convert Grammar to PDA (Standard)', 'standard', 'PDA'],
  ),
  HelpTopicIds.grammarEditorConversionsPdaGreibach: HelpNodeCopy(
    title: 'Grammar to PDA through Greibach form',
    body: 'Convert Grammar to PDA (Greibach) first converts the CFG to GNF and '
        'then builds input-consuming production transitions. Use it to connect '
        'Greibach rules with a PDA construction. Add productions and select '
        'Convert Grammar to PDA (Greibach). Success loads a PDA from the GNF '
        'grammar and switches to the PDA workspace. No productions or any '
        'conversion already running disables this control. An invalid start '
        'symbol or another conversion failure does not disable a non-empty '
        'grammar in advance; it returns an error after activation. Failed GNF '
        'conversion or the ten-second limit also keeps the current workspace; '
        'continue with Convert to GNF and GNF theory.',
    keywords: ['Convert Grammar to PDA (Greibach)', 'GNF', 'PDA'],
  ),
  HelpTopicIds.grammarEditorFilesAndExamples: HelpNodeCopy(
    title: 'Grammar files and examples',
    body: 'Grammar file actions preserve rules or produce a shareable diagram, '
        'while five bundled CFG examples provide starting models. Open '
        'Algorithms and select GLC - Palíndromo, GLC - Parênteses balanceados, '
        'GLC - a^n b^n, GLC - Zeros em quantidade par, or GLC - Expressões '
        'aritméticas; the selection replaces the current grammar, including '
        'when the editor is empty. Use examples for study and files for '
        'round-tripping your own grammar. When a host supplies the '
        'grammar-capable file panel, Load JFLAP is available on every platform '
        'when the panel is mounted. Export labels change from Save as JFLAP and '
        'Export SVG on native platforms to Download JFLAP and Download SVG on '
        'the web; JFLAP grammar files use the .cfg extension. A successful load '
        'replaces the supplied grammar, exports create XML or SVG, and '
        'canceling leaves it unchanged. Malformed XML, missing grammar/start/'
        'production elements, inaccessible data, or write failures show an '
        'error. Import failures offer Retry with Cancel in the dialog or Retry '
        'with Dismiss in the banner; there is no Report action. Continue with '
        'the editor overview after loading.',
    keywords: ['JFLAP', 'SVG', 'cfg', 'examples', 'file error'],
  ),
  'grammar.theory': HelpNodeCopy(
    title: 'Grammar theory',
    keywords: ['theory', 'CFG', 'derivation', 'normal form'],
  ),
  HelpTopicIds.grammarTheoryCfg: HelpNodeCopy(
    title: 'Context-free grammars',
    body: 'A context-free grammar is a tuple of terminals, non-terminals, '
        'productions, and a start symbol whose rules have one non-terminal on '
        'the left. Use CFGs to describe nested or recursive languages that may '
        'not be regular. Define variables and terminals, choose S or another '
        'start symbol, and add each production in the Grammar editor. The '
        'grammar denotes every terminal string derivable from the start symbol. '
        'A CFG description does not itself choose a parsing strategy or prove '
        'that rules are unambiguous; continue with Productions and derivations.',
    keywords: ['CFG', 'context-free grammar', 'terminal', 'non-terminal'],
  ),
  HelpTopicIds.grammarTheoryProductions: HelpNodeCopy(
    title: 'Production rules',
    body: 'A production A→α permits non-terminal A to be replaced by symbol '
        'sequence α. Use productions to encode every legal expansion of a '
        'derivation. Add one editor row per alternative and use ε for the empty '
        'sequence. Together the rows define the grammar relation used by '
        'parsers and transformations. An editor row accepts exactly one '
        'left-side symbol even though the underlying model can represent '
        'broader grammar forms; continue with Derivations.',
    keywords: ['production', 'rule', 'alternative', 'replacement'],
  ),
  HelpTopicIds.grammarTheoryDerivations: HelpNodeCopy(
    title: 'Derivations',
    body: 'A derivation repeatedly applies productions from the start symbol '
        'until a terminal string is reached. Use it to justify membership and '
        'compare how parsers construct a result. Choose a non-terminal in the '
        'current sentential form, apply one matching alternative, and repeat '
        'until no variables remain. A successful sequence demonstrates that '
        'the final string belongs to the language. Different rule orders may '
        'lead to the same tree or to genuinely different trees, so continue '
        'with Parse trees and ambiguity.',
    keywords: ['derivation', 'sentential form', 'membership', 'production'],
  ),
  HelpTopicIds.grammarTheoryParseTrees: HelpNodeCopy(
    title: 'Parse trees',
    body:
        'A parse tree places the start symbol at the root, production symbols '
        'under expanded non-terminals, and the derived string at the leaves. '
        'Use it to see grammatical structure rather than only acceptance. Run '
        'Automatic (Earley) or Brute force and expand Derivation Tree when the '
        'best-effort reconstruction is available; CYK instead exposes its '
        'table steps in the current panel. Reading leaves left to right gives '
        'the input string. A missing displayed tree does not negate an Accepted '
        'Earley result, and shallow trees may omit detailed spans; continue '
        'with Ambiguity.',
    keywords: ['parse tree', 'Derivation Tree', 'root', 'leaves'],
  ),
  HelpTopicIds.grammarTheoryAmbiguity: HelpNodeCopy(
    title: 'Ambiguity',
    body: 'A grammar is ambiguous when at least one string has two distinct '
        'parse trees. Use the concept when alternative structures change '
        'meaning or parser choice. Compare derivations and trees for the same '
        'input, and use Check Ambiguity only as an LL(1) conflict indicator. '
        'Two distinct trees prove ambiguity. An LL(1) conflict proves only '
        'that the grammar is not LL(1), not that it is ambiguous; continue with '
        'Left recursion and factoring or parser results.',
    keywords: ['ambiguity', 'two parse trees', 'LL(1) conflict'],
  ),
  HelpTopicIds.grammarTheoryLeftRecursionAndFactoring: HelpNodeCopy(
    title: 'Left recursion and left factoring',
    body: 'Direct left recursion begins an alternative with its own '
        'non-terminal. Indirect left recursion returns through one or more '
        'other non-terminals. Remove Left Recursion uses ordered substitution '
        'and direct-recursion rewrites for both cases. Left Factor extracts a '
        'shared prefix. Inspect the generated primed variables and '
        'transformation steps. Both rewrites preserve the intended language, '
        'but neither one guarantees LL(1); continue with FIRST and FOLLOW.',
    keywords: ['left recursion', 'left factoring', 'common prefix', 'rewrite'],
  ),
  HelpTopicIds.grammarTheoryFirstAndFollow: HelpNodeCopy(
    title: 'FIRST and FOLLOW',
    body: 'FIRST predicts which terminals can begin a derivation, while FOLLOW '
        'predicts which terminals can appear after a non-terminal. Use both to '
        'construct and diagnose a predictive parse table. Compute FIRST for '
        'each symbol and sequence, propagate ε through nullable prefixes, then '
        'compute FOLLOW from the start-symbol end marker and production '
        'contexts. The resulting sets determine table cells for ordinary and '
        'empty productions. Missing nullable propagation gives incorrect '
        'choices, so continue with Predictive parsing and LL(1) tables.',
    keywords: ['FIRST', 'FOLLOW', 'nullable', 'predictive'],
  ),
  HelpTopicIds.grammarTheoryPredictiveParsing: HelpNodeCopy(
    title: 'Predictive parsing and LL(1) tables',
    body: 'An LL(1) parser chooses a production from one non-terminal and one '
        'lookahead symbol. Use its table to identify deterministic top-down '
        'choices. Turing Lab also executes that table from the LL(1) parser '
        'strategy and stops before parsing if a cell conflicts. Run Find First '
        'Sets, Find Follow Sets, and Build Parse Table, then '
        'inspect each row and terminal column. A cell with one production is a '
        'choice and a cell with multiple productions is a conflict. Removing '
        'recursion or factoring may help but does not guarantee success, and '
        'the current table is not LR(1); continue with the parse-table topic.',
    keywords: ['predictive parsing', 'LL(1)', 'lookahead', 'parse table'],
  ),
  HelpTopicIds.grammarTheoryCnf: HelpNodeCopy(
    title: 'Chomsky Normal Form',
    body: 'Chomsky Normal Form restricts ordinary CFG rules to A→BC or A→a, '
        'with a controlled start-symbol exception for ε. Use CNF for CYK and '
        'for reasoning about binary derivation structure. Run Convert to CNF '
        'and inspect each transformation step before applying a result. The '
        'converted grammar preserves the language under the transformer\'s '
        'documented empty-string handling. Auxiliary symbols and more rules '
        'are expected, while diagnostics can stop an unsafe conversion; '
        'continue with CYK parsing.',
    keywords: ['CNF', 'Chomsky Normal Form', 'A BC', 'CYK'],
  ),
  HelpTopicIds.grammarTheoryGnf: HelpNodeCopy(
    title: 'Greibach Normal Form',
    body: 'Greibach Normal Form makes each ordinary production begin with a '
        'terminal followed by zero or more non-terminals. Use GNF to relate '
        'derivation steps to consumed input and to prepare the Greibach PDA '
        'conversion. Run Convert to GNF, review diagnostics and steps, and '
        'apply only the result you intend. A valid result begins each '
        'applicable right side with a terminal. Conversion can introduce new '
        'symbols or fail on unsupported structure; continue with Convert '
        'Grammar to PDA (Greibach).',
    keywords: ['GNF', 'Greibach Normal Form', 'terminal first', 'PDA'],
  ),
  HelpTopicIds.grammarTheoryGrammarFsaPda: HelpNodeCopy(
    title: 'Relationships among grammars, FSA, and PDA',
    body: 'Right-linear grammars and finite automata describe regular '
        'languages, while CFGs and PDAs describe context-free languages. Use '
        'these relationships to choose a conversion without losing expressive '
        'structure. Convert a right-linear grammar to FSA, or use General, '
        'Standard, or Greibach grammar-to-PDA construction for a valid CFG. '
        'Success opens the destination workspace with a generated model. A '
        'general CFG cannot always become an FSA, and each converter enforces '
        'its own structural requirements; continue with the matching '
        'conversion topic.',
    keywords: ['grammar', 'FSA', 'PDA', 'regular', 'context-free'],
  ),
  'pda': HelpNodeCopy(
    title: 'Pushdown automata',
    keywords: ['PDA', 'pushdown automaton', 'stack', 'context-free'],
  ),
  'pda.editor': HelpNodeCopy(
    title: 'Editor and canvas',
    keywords: ['PDA', 'editor', 'canvas', 'simulation', 'algorithms'],
  ),
  HelpTopicIds.pdaEditorOverview: HelpNodeCopy(
    title: 'PDA editor overview',
    body: 'The PDA workspace combines a state canvas, a live stack inspector, '
        'simulation, analysis, examples, and SVG export. Use it to build or '
        'inspect a deterministic or nondeterministic pushdown automaton. Add '
        'states, mark the initial and accepting states, connect them with '
        'input/pop/push transitions, and test an input string. The canvas '
        'status reports state and transition counts plus missing markers, '
        'lambda use, and detected conflicts. A simulation needs an initial '
        'state, while several analyses also need accepting states or normalized '
        'transitions; follow the visible error rather than assuming a partial '
        'PDA is valid. Continue with Select and edit states or Simulation '
        'workflow.',
    keywords: ['PDA', 'workspace', 'editor', 'canvas', 'stack'],
  ),
  'pda.editor.editing': HelpNodeCopy(
    title: 'Edit a PDA',
    keywords: ['PDA', 'edit', 'state', 'transition', 'lambda'],
  ),
  HelpTopicIds.pdaEditorSelectionAndStates: HelpNodeCopy(
    title: 'Select and edit states',
    body: 'Select mode is the canvas tool for moving and opening PDA states. '
        'Use it after creating a state or whenever Add transition is active. '
        'Choose Add state to create one, return to Select, drag a state to move '
        'it, and double-tap it to edit State label, Initial state, Accepting '
        'state, or Delete state. Saving updates the markers and every connected '
        'edge, and deleting a state removes its transitions. The editor keeps '
        'at most one initial state; a usable final-state simulation still '
        'requires an initial state and the intended accepting markers. Continue '
        'with Add and edit PDA transitions.',
    keywords: [
      'PDA',
      'Select',
      'Add state',
      'initial state',
      'accepting state'
    ],
  ),
  HelpTopicIds.pdaEditorTransitions: HelpNodeCopy(
    title: 'Add and edit PDA transitions',
    body: 'A PDA transition combines an input symbol, a pop symbol, and a push '
        'symbol on one directed edge. Use it to say when the machine may move '
        'and how that move changes the stack. Choose Add transition, select '
        'source and target states, fill Input symbol, Pop symbol, and Push '
        'symbol, then Save; select an existing edge to edit or delete it. The '
        'canvas shows the canonical input, pop/push label and updates both '
        'alphabets. Every non-lambda field is required, and a changed '
        'multi-character push is treated as ordered characters rather than one '
        'atomic symbol. Continue with Lambda input, pop, and push.',
    keywords: ['PDA', 'input symbol', 'pop symbol', 'push symbol', 'edge'],
  ),
  HelpTopicIds.pdaEditorLambdaSwitches: HelpNodeCopy(
    title: 'Lambda input, pop, and push',
    body:
        'The three lambda switches independently make the input, pop, or push '
        'part of a PDA transition empty. Use λ-input for a move that consumes '
        'no input, λ-pop for a move that neither checks nor removes the stack '
        'top, and λ-push for a move that adds nothing. Enable λ-input, λ-pop, '
        'or λ-push beside its field and save the transition. The disabled '
        'field is cleared and the edge displays λ in that position. Leaving a '
        'non-lambda field blank blocks Save, while lambda moves can branch or '
        'cycle and therefore consume search limits. Continue with PDA '
        'transitions or Nondeterminism.',
    keywords: ['PDA', 'lambda', 'epsilon', 'λ-input', 'λ-pop', 'λ-push'],
  ),
  HelpTopicIds.pdaEditorHistoryAndClear: HelpNodeCopy(
    title: 'Undo, redo, and clear',
    body: 'History controls reverse or restore recorded PDA canvas edits, '
        'while Clear canvas removes the current graph. Use Undo after an '
        'unwanted state or transition change, Redo after reversing too far, '
        'and Clear canvas only to start over. Activate the toolbar controls; '
        'the mobile control surface exposes the same actions when available. '
        'Undo and Redo restore the PDA graph and refresh validation. A model '
        'edit during canvas playback stops that playback. The displayed stack '
        'is not part of Undo or Redo history and can remain as the previous '
        'snapshot after playback stops. Only Clear canvas explicitly stops '
        'playback and clears the displayed stack together with the graph. Undo '
        'and Redo are disabled when their history direction is empty, and '
        'clearing the stack inspector is separate from clearing the PDA. '
        'Continue with Files and examples before replacing work you need to '
        'keep.',
    keywords: ['PDA', 'Undo', 'Redo', 'Clear canvas', 'history'],
  ),
  'pda.editor.viewport': HelpNodeCopy(
    title: 'Canvas view',
    keywords: ['PDA', 'viewport', 'zoom', 'fit', 'layout'],
  ),
  HelpTopicIds.pdaEditorViewportZoom: HelpNodeCopy(
    title: 'Zoom and pan',
    body:
        'Zoom and pan change the PDA viewport without changing the automaton. '
        'Use them to inspect crowded state and transition labels. Select Zoom '
        'in or Zoom out, pinch with two fingers on touch screens, and drag '
        'empty canvas space to pan. The graph keeps the same states, edges, '
        'language, and stored positions while its scale or offset changes. A '
        'one-finger drag beginning on a state moves that state in Select mode, '
        'so begin a pan on empty space; zoom is also capped by the canvas scale '
        'limits. Continue with Fit to content and Reset view.',
    keywords: ['PDA', 'zoom', 'pan', 'pinch', 'viewport'],
  ),
  HelpTopicIds.pdaEditorViewportFitAndReset: HelpNodeCopy(
    title: 'Fit to content and reset view',
    body: 'Fit to content frames all PDA states, while Reset view restores the '
        'default viewport transform. Use Fit to content after nodes leave the '
        'visible area and Reset view when you want the neutral zoom and pan. '
        'Select the matching toolbar action on the desktop or mobile canvas. '
        'Only the view changes; model coordinates, transitions, and stack '
        'behavior stay intact. An empty canvas has nothing to fit, and neither '
        'command rearranges overlapping states. Continue with Auto Layout '
        'availability or Select and edit states.',
    keywords: ['PDA', 'Fit to content', 'Reset view', 'viewport'],
  ),
  HelpTopicIds.pdaEditorViewportAutoLayout: HelpNodeCopy(
    title: 'Auto Layout availability',
    body: 'Auto Layout would rearrange state coordinates without changing PDA '
        'behavior. Look for it when a loaded graph is difficult to read, but '
        'the current PDA workspace does not expose Auto Layout in its canvas '
        'or analysis controls. Use Select to drag states manually, then Fit to '
        'content to frame the result. Manual movement updates the visible '
        'edges while preserving transition rules and language. There is no PDA '
        'Auto Layout result to apply on this screen; the similarly named '
        'layout support used elsewhere is not a hidden PDA command. Continue '
        'with Zoom and pan or Select and edit states.',
    keywords: ['PDA', 'Auto Layout', 'unavailable', 'manual layout'],
  ),
  'pda.editor.stack': HelpNodeCopy(
    title: 'Stack',
    keywords: ['PDA', 'stack', 'inspector', 'alphabet', 'preview'],
  ),
  HelpTopicIds.pdaEditorStackInspector: HelpNodeCopy(
    title: 'Use the stack inspector',
    body: 'The stack inspector is the compact live view of the PDA stack. Use '
        'it during transition editing or trace playback to see the top symbol, '
        'size, last operation, and highlighted cell. On desktop it sits below '
        'the canvas; on mobile, move or resize the floating Stack panel, tap a '
        'cell to toggle its highlight, or swipe right to highlight and left to '
        'remove that highlight. The panel shows the top first and animates push '
        'and pop changes. Clear empties only this displayed stack state, not '
        'the PDA definition, and an idle empty panel shows the initial marker '
        'instead of a simulated stack. Continue with Initial stack symbol and '
        'stack alphabet.',
    keywords: ['PDA', 'stack inspector', 'mobile', 'top', 'Clear stack'],
  ),
  HelpTopicIds.pdaEditorStackInitialSymbolAndAlphabet: HelpNodeCopy(
    title: 'Initial stack symbol and stack alphabet',
    body: 'The initial stack symbol is the bottom marker placed in the PDA '
        'stack at the start of a run, and the stack alphabet lists symbols '
        'used by pop and push operations. Use them to keep transition rules '
        'consistent. The canvas model starts with Z, derives additional stack '
        'symbols from transition fields, and lets you enter an Initial Stack '
        'Symbol in the simulation panel. A run starts its current stack with '
        'that value and adds it to a simulation-only copy of the alphabet. The '
        'current screen has no separate alphabet editor, and changing the '
        'simulation field does not rewrite the editor PDA. Continue with Stack '
        'operation preview or Stack theory.',
    keywords: ['PDA', 'initial stack symbol', 'stack alphabet', 'Z', 'bottom'],
  ),
  HelpTopicIds.pdaEditorStackOperationPreview: HelpNodeCopy(
    title: 'Preview stack operations',
    body: 'Operation Preview illustrates the stack effect of the transition '
        'currently being edited. Use it before saving a pop/push rule whose '
        'order is hard to visualize. Enter the input, pop, and push values or '
        'their lambda switches and inspect Input, Pop, Push, and Result below '
        'the fields. A non-lambda pop removes the displayed top, and a '
        'multi-character push is added from right to left so its first '
        'character becomes the new top; the preview shows at most five cells. '
        'This preview is illustrative and does not verify that the requested '
        'pop symbol matches the current top; simulation enforces that match. '
        'Continue with Add and edit PDA transitions.',
    keywords: ['PDA', 'Operation Preview', 'pop', 'push', 'stack order'],
  ),
  'pda.editor.simulation': HelpNodeCopy(
    title: 'Simulation',
    keywords: ['PDA', 'simulation', 'input', 'trace', 'result'],
  ),
  HelpTopicIds.pdaEditorSimulation: HelpNodeCopy(
    blocks: _pdaSimulationBlocks,
    title: 'Run or cancel a PDA simulation',
    body: 'PDA Simulation searches the current automaton for a path that '
        'accepts one input. Use it after defining the graph and whenever you '
        'want to test language membership. Enter Input String, leave it blank '
        'for ε, enter a nonempty Initial Stack Symbol, choose whether to Record '
        'step-by-step trace, and select Simulate PDA; the running button lets '
        'you cancel. The panel initializes the stack and then reports a result '
        'or Simulation cancelled. The current workflow accepts only after all '
        'input is consumed in an accepting state, preserves whitespace, and '
        'stops after five seconds or its search limits. Continue with Trace, '
        'current stack, and remaining input.',
    keywords: ['PDA', 'Simulate PDA', 'cancel', 'Input String', 'epsilon'],
  ),
  HelpTopicIds.pdaEditorSimulationTraceAndStack: HelpNodeCopy(
    blocks: _pdaSimulationBlocks,
    title: 'Trace, current stack, and remaining input',
    body: 'The trace records PDA configurations so you can inspect state, '
        'current stack, remaining input, and the transition used at each step. '
        'Use it to explain an accepted path or diagnose where all branches '
        'stop. Enable Record step-by-step trace before Simulate PDA, then '
        'select a row, scrub the timeline, or use Previous Step, Play, Pause, '
        'Next Step, and Reset. The selected configuration updates canvas '
        'highlights and the stack inspector. Without detailed recording only '
        'the final snapshot is retained, and concatenated stack text does not '
        'show boundaries between imported multi-character atomic symbols. '
        'Continue with Results and canvas playback.',
    keywords: ['PDA', 'trace', 'current stack', 'remaining input', 'Pause'],
  ),
  HelpTopicIds.pdaEditorSimulationResultsAndCanvas: HelpNodeCopy(
    blocks: _pdaSimulationBlocks,
    title: 'Read results and use canvas playback',
    body: 'Simulation Results summarizes whether the PDA run was Accepted, '
        'Rejected, cancelled, timed out, or otherwise failed. Use it to confirm '
        'the membership result and replay a recorded accepting or rejecting '
        'trace. Read the status, execution time, and error text; when Record '
        'step-by-step trace was enabled, View on Canvas is available only in a '
        'narrow iOS layout below 1024 logical pixels and opens previous, '
        'play/pause, next, input-word, and close controls over the canvas. '
        'Playback projects the '
        'selected state, transition, input progress, and stack. Other '
        'platforms retain trace controls inside the panel, and closing playback '
        'clears its highlights without editing the PDA. Continue with '
        'Acceptance criteria or transition editing.',
    keywords: ['PDA', 'Accepted', 'Rejected', 'View on Canvas', 'iOS'],
  ),
  'pda.editor.algorithms': HelpNodeCopy(
    title: 'Algorithms',
    keywords: ['PDA', 'algorithms', 'analysis', 'conversion', 'results'],
  ),
  HelpTopicIds.pdaEditorAlgorithmsOverview: HelpNodeCopy(
    blocks: _pdaAlgorithmBlocks,
    title: 'PDA algorithms overview',
    body: 'PDA Analysis groups six controls for conversion, simplification, '
        'and diagnostics. Use it after drawing or loading a PDA when you need '
        'more than one simulation. Select Convert to CFG, Simplify PDA, Check '
        'Determinism, Find Reachable States, Language Analysis, or Stack '
        'Operations. The panel disables every control while one analysis runs '
        'and replaces the result card with that operation\'s textual output or '
        'generated grammar. The buttons remain enabled when no PDA exists and '
        'then report that prerequisite, while individual algorithms impose '
        'additional structure and limits. Continue with the topic for the '
        'control you intend to use.',
    keywords: ['PDA', 'PDA Analysis', 'six controls', 'analysis'],
  ),
  HelpTopicIds.pdaEditorAlgorithmsToCfg: HelpNodeCopy(
    blocks: _pdaAlgorithmBlocks,
    title: 'Convert a PDA to CFG',
    body: 'Convert to CFG constructs a context-free grammar from the current '
        'PDA. Use it to study or reuse an equivalent language in production '
        'form. Select Convert to CFG in PDA Analysis and inspect the generated '
        'start symbol, non-terminals, terminals, productions, and conversion '
        'description in the result card. Variables of the form [p,A,q] encode '
        'a state-to-state stack obligation. The PDA needs states, an initial '
        'state, at least one accepting state, and every transition must pop '
        'exactly one non-lambda stack symbol; failure leaves the PDA unchanged. '
        'The result is displayed here rather than opening the Grammar editor. '
        'Continue with PDA and CFG.',
    keywords: ['PDA', 'Convert to CFG', 'context-free grammar', '[p,A,q]'],
  ),
  HelpTopicIds.pdaEditorAlgorithmsMinimize: HelpNodeCopy(
    blocks: _pdaAlgorithmBlocks,
    title: 'Simplify a PDA safely',
    body: 'Simplify PDA applies reductions that preserve the active acceptance '
        'mode. It removes structurally unreachable control states, computes a '
        'fixed-point strong-bisimulation quotient, and removes exact duplicate '
        'transitions. Exact semantic usefulness is currently skipped; states '
        'whose stack-feasible usefulness is uncertain are retained and the '
        'preview shows that warning. Final-state and combined acceptance '
        'require a final state, while empty-stack acceptance does not; combined '
        'acceptance continues to mean final state AND empty stack. Review the '
        'mode, counts, and reasons, then cancel without changes or apply as one '
        'undoable operation. This conservative simplifier does not compute or '
        'claim a globally minimum NPDA. Continue with Find Reachable States.',
    keywords: [
      'PDA',
      'Simplify PDA',
      'strong bisimulation',
      'unreachable',
      'acceptance mode',
    ],
  ),
  HelpTopicIds.pdaEditorAlgorithmsDeterminism: HelpNodeCopy(
    blocks: _pdaAlgorithmBlocks,
    title: 'Check determinism',
    body: 'Check Determinism reports transition conflicts detected by the PDA '
        'editor. Use it to locate branches that share a source, input '
        'condition, and pop condition. Select Check Determinism and inspect the '
        'deterministic or NON-deterministic result, conflicting transition '
        'labels, canvas highlights, total transition count, and lambda count. '
        'No model change is applied. The current check groups exact '
        'source/input/pop keys; it does not perform a complete formal DPDA test '
        'for every interaction between lambda-input and consuming moves. A PDA '
        'must exist, but accepting states are not required for this report. '
        'Continue with Nondeterminism.',
    keywords: ['PDA', 'Check Determinism', 'DPDA', 'conflict', 'lambda'],
  ),
  HelpTopicIds.pdaEditorAlgorithmsReachableStates: HelpNodeCopy(
    blocks: _pdaAlgorithmBlocks,
    title: 'Find reachable states',
    body: 'Find Reachable States classifies PDA states by graph reachability '
        'from the initial state. Use it to locate disconnected portions before '
        'simplification. Select Find Reachable States and read the initial '
        'state plus sorted reachable and unreachable sets; reachable states '
        'are also highlighted on the canvas. The command does not change the '
        'PDA. It requires an initial state and follows transition edges within '
        'the analysis input-length limit without proving that each path has a '
        'feasible stack configuration, so reachability here is structural. '
        'Continue with Simplify PDA or Stack Operations.',
    keywords: ['PDA', 'Find Reachable States', 'reachable', 'unreachable'],
  ),
  HelpTopicIds.pdaEditorAlgorithmsLanguage: HelpNodeCopy(
    blocks: _pdaAlgorithmBlocks,
    title: 'Analyze the language',
    body: 'Language Analysis formally decides whether the language recognized '
        'by the PDA is empty under the active acceptance mode. It normalizes '
        'the PDA, converts it to a context-free grammar, and computes productive '
        'nonterminals by fixed point. A non-empty result includes a shortest '
        'accepted word, a leftmost CFG derivation, and an action that opens the '
        'verified run in the Simulator panel. Equal-length candidates use '
        'deterministic shortlex order. Length counts grammar terminal symbols, '
        'so a multi-character terminal contributes one. A cancellation, '
        'resource limit, conversion error, or replay inconsistency is reported '
        'as proof unavailable and never as an empty language. Continue with '
        'Context-free languages or run a specific simulation.',
    keywords: [
      'PDA',
      'Language Analysis',
      'language emptiness',
      'shortest witness'
    ],
  ),
  HelpTopicIds.pdaEditorAlgorithmsStackOperations: HelpNodeCopy(
    blocks: _pdaAlgorithmBlocks,
    title: 'Analyze stack operations',
    body: 'Stack Operations summarizes the stack labels used by PDA '
        'transitions. Use it to audit which rules push, pop, or mention a stack '
        'symbol. Select Stack Operations and inspect the initial stack symbol, '
        'unique push operations, unique pop operations, touched stack symbols, '
        'and PDA versus FSA transition counts. The report is textual and '
        'leaves the model unchanged. A PDA with an initial state is required; '
        'the current output treats each stored push string as one reported '
        'operation and does not calculate a maximum runtime stack depth despite '
        'the button description. Continue with Stack theory or transition '
        'editing.',
    keywords: ['PDA', 'Stack Operations', 'push', 'pop', 'stack symbols'],
  ),
  HelpTopicIds.pdaEditorFilesAndExamples: HelpNodeCopy(
    title: 'PDA files, SVG, and examples',
    body: 'The examples and file areas provide ready-made PDAs and a visual '
        'export of the current graph. Use APD - Parênteses Balanceados, APD - '
        'a^n b^n, APD - Palíndromo, APD - a^n b^2n, or APD - w#reverse(w) to '
        'explore stack patterns, and use SVG for sharing a diagram. Open '
        'Algorithms and select an example; once a PDA '
        'exists, select Export SVG on native platforms or Download SVG on the '
        'web. Loading an example replaces the editor model, while export '
        'creates an image and reports success or an error. The current panel '
        'does not offer PDA JFLAP or JSON import or save actions, and SVG is '
        'not an editable PDA file; canceling native export leaves files '
        'unchanged. Continue with the editor overview or the example\'s '
        'simulation.',
    keywords: ['PDA', 'examples', 'SVG', 'Export SVG', 'Download SVG'],
  ),
  'pda.theory': HelpNodeCopy(
    title: 'Theory',
    keywords: ['PDA', 'theory', 'stack', 'acceptance', 'context-free'],
  ),
  HelpTopicIds.pdaTheoryPda: HelpNodeCopy(
    title: 'Pushdown automata',
    body: 'A pushdown automaton is a finite-state machine augmented by an '
        'unbounded last-in-first-out stack. Use a PDA when finite state alone '
        'cannot remember the nesting or matching count needed by a '
        'context-free language. Define states, input and stack alphabets, an '
        'initial state and stack symbol, accepting states, and input/pop/push '
        'transitions. A run follows one valid configuration path and updates '
        'state, remaining input, and stack together. The mathematical model can '
        'have infinitely many configurations even though the editor and '
        'simulator impose finite time and search bounds. Continue with Stack '
        'memory or PDA transitions.',
    keywords: ['PDA', 'pushdown automaton', 'formal model', 'configuration'],
  ),
  HelpTopicIds.pdaTheoryStack: HelpNodeCopy(
    title: 'Stack memory',
    body: 'A PDA stack is last-in-first-out memory whose top controls which '
        'pop transitions are available. Use it to remember nested openings, '
        'counts, or a guessed prefix until matching input arrives. Start with '
        'the initial stack symbol, test and optionally remove the top with pop, '
        'then add zero or more symbols with push. The current stack after each '
        'move becomes part of the next configuration. Only the top can be '
        'removed directly, push order matters, and an impossible pop disables '
        'that path rather than producing an arbitrary result. Continue with '
        'PDA transitions or the stack inspector.',
    keywords: ['PDA', 'stack', 'LIFO', 'top', 'initial symbol'],
  ),
  HelpTopicIds.pdaTheoryTransitions: HelpNodeCopy(
    title: 'PDA transitions',
    body:
        'A PDA transition maps a state, optional input, and optional stack-top '
        'test to a new state and stack replacement. Use it to encode one legal '
        'computation step. In the editor, choose source and target, set the '
        'input symbol, pop symbol, and push symbol, and use the three lambda '
        'switches for omitted actions. A matching move consumes its input when '
        'present, removes the required top when present, and pushes its ordered '
        'replacement. A transition cannot run when its non-lambda input or pop '
        'condition does not match, and multiple available moves introduce '
        'nondeterminism. Continue with Lambda switches or Nondeterminism.',
    keywords: ['PDA', 'transition', 'input', 'pop', 'push'],
  ),
  HelpTopicIds.pdaTheoryAcceptance: HelpNodeCopy(
    title: 'Acceptance criteria',
    body: 'Acceptance defines which complete PDA configurations place an input '
        'in the language. Use the criterion chosen by the tool when comparing '
        'a hand construction with a simulation result. The current PDA screen '
        'starts at its initial state and initial stack symbol and searches '
        'until all input is consumed in an accepting state. Accepted means at '
        'least one such path exists; Rejected means none was found within a '
        'completed search. Empty-stack and combined criteria exist in the core '
        'model but are not selectable in this screen, and timeout or search '
        'limit results are not mathematical rejection proofs. Continue with '
        'Simulation workflow or Nondeterminism.',
    keywords: ['PDA', 'acceptance', 'final state', 'empty stack', 'Accepted'],
  ),
  HelpTopicIds.pdaTheoryNondeterminism: HelpNodeCopy(
    title: 'Nondeterminism in PDAs',
    body: 'A nondeterministic PDA may have several applicable moves for one '
        'configuration, including moves that consume no input. Use branching '
        'when the machine must guess a split point or choose among stack '
        'strategies, as in a palindrome recognizer. Create competing '
        'input/pop rules or lambda paths and simulate; the search explores '
        'configurations until one accepts or all bounded alternatives end. One '
        'accepting branch makes the input Accepted. Cycles and branching can '
        'reach the five-second, 1,000-depth, or 100,000-configuration limits, '
        'and the editor\'s Check Determinism is a narrower conflict diagnostic. '
        'Continue with Check Determinism or Context-free languages.',
    keywords: ['PDA', 'NPDA', 'nondeterminism', 'branch', 'lambda'],
  ),
  HelpTopicIds.pdaTheoryContextFreeLanguages: HelpNodeCopy(
    title: 'Context-free languages',
    body: 'Context-free languages are exactly the languages recognized by '
        'nondeterministic PDAs under the standard equivalences. Use this class '
        'for nested or recursively balanced structure such as parentheses and '
        'a^n b^n. Build stack rules or derive a CFG, then test representative '
        'positive and negative strings. Language Analysis can decide emptiness '
        'and return one shortest witness, but it does not decide universality '
        'or equivalence between arbitrary PDAs. Deterministic PDAs recognize a '
        'proper subset of context-free languages. Continue with PDA and CFG or '
        'the bundled examples.',
    keywords: ['PDA', 'context-free language', 'CFL', 'nesting', 'a^n b^n'],
  ),
  HelpTopicIds.pdaTheoryPdaAndCfg: HelpNodeCopy(
    title: 'PDA and context-free grammars',
    body: 'Nondeterministic PDAs and context-free grammars are two equivalent '
        'ways to describe context-free languages. Use conversion to relate '
        'stack behavior to productions or to inspect a generated formal model. '
        'Run Convert to CFG for a suitable PDA, or use a grammar-to-PDA command '
        'from the Grammar workspace. The PDA converter produces [p,A,q] '
        'variables and displays the generated grammar without changing '
        'workspaces. This implementation requires final-state structure and '
        'exactly one non-lambda pop per transition, so a mathematically '
        'convertible PDA may need normalization first. Continue with Convert '
        'to CFG or Grammar relationships.',
    keywords: ['PDA', 'CFG', 'conversion', 'equivalence', 'normalization'],
  ),
  'tm': HelpNodeCopy(
    title: 'Turing machines',
    keywords: ['TM', 'MT', 'Turing machine', 'tape', 'computation'],
  ),
  'tm.editor': HelpNodeCopy(
    title: 'Editor and canvas',
    keywords: ['TM', 'MT', 'Turing machine', 'editor', 'canvas'],
  ),
  HelpTopicIds.tmEditorOverview: HelpNodeCopy(
    title: 'Turing machine editor overview',
    body: 'The TM workspace combines a state canvas, a single-tape inspector, '
        'simulation, structural analysis, metrics, examples, and SVG export. '
        'Use it to build and test a machine whose transitions read, write, and '
        'move a tape head. Add states, mark initial and accepting states, add '
        'transitions, enter an input string, and select Simulate TM. The canvas '
        'and status summarize the machine while the panels show its trace and '
        'analysis. Simulation and analysis controls require at least one state, '
        'and malformed machines return a message instead of a result. Continue '
        'with Select and edit states or Simulation workflow.',
    keywords: ['TM', 'MT', 'Turing machine', 'editor', 'canvas', 'Simulate TM'],
  ),
  'tm.editor.editing': HelpNodeCopy(
    title: 'Edit a Turing machine',
    keywords: ['TM', 'MT', 'edit', 'state', 'transition', 'history'],
  ),
  HelpTopicIds.tmEditorSelectionAndStates: HelpNodeCopy(
    title: 'Select and edit states',
    body: 'States record the finite-control part of a TM, and Select lets you '
        'move or edit them. Use these controls to define where computation '
        'starts, halts successfully, or changes behavior. Choose Add state, '
        'place or create a state, then select it to edit its label and Initial '
        'state or Accepting state markers; drag it to reposition it. The '
        'machine, connected edges, counts, and validation refresh after each '
        'change. Only one state is initial, and deleting a state also deletes '
        'its incident transitions. Continue with Add and edit transitions.',
    keywords: [
      'TM',
      'MT',
      'Select',
      'Add state',
      'initial state',
      'accepting state'
    ],
  ),
  HelpTopicIds.tmEditorTransitions: HelpNodeCopy(
    title: 'Add and edit transitions',
    body: 'A TM transition chooses the next state and one tape operation. Use '
        'transitions to define what the machine does for each symbol under the '
        'head. Choose Add transition, select source and target states, complete '
        'the operation editor, and save; select an existing edge to edit or '
        'delete it. The canvas displays a read/write,direction label and '
        'recalculates tape symbols and nondeterministic conflicts. Empty read '
        'or write fields are rejected, and competing rules for the same state '
        'and read symbol make the machine nondeterministic. Continue with Read, '
        'write, and direction.',
    keywords: [
      'TM',
      'MT',
      'Add transition',
      'edge',
      'operation',
      'nondeterminism'
    ],
  ),
  HelpTopicIds.tmEditorReadWriteAndDirection: HelpNodeCopy(
    title: 'Read, write, and direction',
    body: 'Read symbol, Write symbol, and Direction define one TM rule. Use '
        'them whenever a transition must match the current cell, replace it, '
        'and move the head. Enter a non-empty read symbol and write symbol, '
        'choose Left, Right, or Stay, then select Save or press Enter; Escape '
        'cancels. The edge label becomes read/write,direction and the rule is '
        'available to simulation. Whitespace is trimmed, an empty field is '
        'invalid, and blank is an actual configured symbol rather than an '
        'empty value. Continue with Blank symbol and tape alphabet.',
    keywords: [
      'TM',
      'MT',
      'Read symbol',
      'Write symbol',
      'Direction',
      'Left',
      'Right'
    ],
  ),
  HelpTopicIds.tmEditorHistoryAndClear: HelpNodeCopy(
    title: 'Undo, redo, and clear',
    body: 'Undo and Redo restore recorded TM canvas edits, while Clear canvas '
        'removes the graph. Use history after an unwanted edit and Clear only '
        'when you intend to start over. Select the toolbar controls or use the '
        'available keyboard shortcuts, then inspect the restored states and '
        'transitions. Any model change stops canvas playback and resets the '
        'displayed tape to the current blank symbol; Clear does this explicitly '
        'with the graph. History concerns the model, not manual tape-cell edits '
        'in the inspector, and it is bounded. Continue with Files and examples '
        'before discarding substantial work.',
    keywords: ['TM', 'MT', 'Undo', 'Redo', 'Clear canvas', 'history'],
  ),
  'tm.editor.viewport': HelpNodeCopy(
    title: 'Canvas view',
    keywords: ['TM', 'MT', 'viewport', 'zoom', 'fit', 'reset'],
  ),
  HelpTopicIds.tmEditorViewportZoom: HelpNodeCopy(
    title: 'Zoom and pan',
    body: 'Zoom and pan change the visible area of the TM without changing its '
        'formal structure. Use them to inspect a dense graph or reach states '
        'outside the current view. Use Zoom in or Zoom out, a mouse wheel or '
        'trackpad, or a two-finger pinch, and drag the background to pan. The '
        'canvas scale and offset change while state coordinates and transitions '
        'remain part of the same machine. Gesture availability depends on the '
        'device, and zoom cannot repair overlapping nodes. Continue with Fit '
        'to content and Reset view.',
    keywords: ['TM', 'MT', 'Zoom in', 'Zoom out', 'pan', 'pinch'],
  ),
  HelpTopicIds.tmEditorViewportFitAndReset: HelpNodeCopy(
    title: 'Fit to content and reset view',
    body:
        'Fit to content frames the current TM graph, while Reset view returns '
        'to the default scale and offset. Use Fit when states have moved off '
        'screen and Reset when you want a neutral viewport. Select the matching '
        'canvas toolbar action. Only the viewport changes; the stored state '
        'positions, transitions, tape, and language do not. On an empty canvas, '
        'Fit falls back to the reset view, and neither action rearranges '
        'overlapping states. Continue with Auto Layout availability.',
    keywords: ['TM', 'MT', 'Fit to content', 'Reset view', 'viewport'],
  ),
  HelpTopicIds.tmEditorViewportAutoLayout: HelpNodeCopy(
    title: 'Auto Layout availability',
    body:
        'Auto Layout would reposition graph states automatically. Look for it '
        'when a manually arranged machine becomes hard to read. The current TM '
        'workspace does not expose Auto Layout, so move states with Select and '
        'use Fit to content to frame them. Manual dragging changes the saved '
        'state coordinates and connected edges redraw around the new positions. '
        'The similarly named FSA algorithm is not available for TM and no TM '
        'analysis button changes layout. Continue with Select and edit states.',
    keywords: ['TM', 'MT', 'Auto Layout', 'unavailable', 'manual layout'],
  ),
  'tm.editor.tape': HelpNodeCopy(
    title: 'Tape and head',
    keywords: ['TM', 'MT', 'tape', 'head', 'blank symbol', 'alphabet'],
  ),
  HelpTopicIds.tmEditorTapeInspector: HelpNodeCopy(
    title: 'Use the tape inspector',
    body: 'The tape inspector shows visible cells and the current head '
        'position for the active TM. Use it to inspect or prepare tape contents '
        'and to follow a simulation step. Expand the tape panel, select an '
        'editable cell, choose a tape-alphabet symbol or type one character, '
        'and confirm; use Clear to reset the displayed tape. The chosen cell '
        'updates, while trace selection replaces the display with that recorded '
        'step. Manual inspector edits do not rewrite the TM graph or its input '
        'alphabet, and simulation starts from Input String. Continue with Head '
        'and current cell.',
    keywords: [
      'TM',
      'MT',
      'tape inspector',
      'Edit Cell',
      'Tape Alphabet',
      'Clear'
    ],
  ),
  HelpTopicIds.tmEditorTapeBlankAndAlphabet: HelpNodeCopy(
    title: 'Blank symbol and tape alphabet',
    body:
        'The tape alphabet contains every symbol that may appear on the tape, '
        'including the blank symbol used beyond written input. Use it when '
        'reading transition labels or editing inspector cells. Enter the '
        'configured blank symbol, commonly B or □, explicitly in read and write '
        'rules; the editor derives additional tape symbols from those rules. '
        'Simulation expands the tape with blanks as the head moves. This is a '
        'single-tape editor and does not expose multi-tape editing, tape-number '
        'selection, or separate heads even though serialized models retain '
        'compatibility fields. Continue with Tape and head theory.',
    keywords: [
      'TM',
      'MT',
      'single tape',
      'multi-tape',
      'blank symbol',
      'tape alphabet'
    ],
  ),
  HelpTopicIds.tmEditorTapeHeadAndCurrentCell: HelpNodeCopy(
    title: 'Head and current cell',
    body: 'The head identifies the tape cell read by the next transition. Use '
        'the centered marker and Head position label to follow movement during '
        'editing or trace review. Select a trace step or use Previous step, '
        'Next step, Play, Pause, or Reset; the inspector projects that step and '
        'marks reads, writes, and the active cell. Left may extend the tape at '
        'its front, Right may append a blank, and Stay keeps the same index. '
        'The visible strip is a window over one tape, not a set of multiple '
        'heads. Continue with Trace and tape.',
    keywords: [
      'TM',
      'MT',
      'head position',
      'current cell',
      'Left',
      'Right',
      'Stay'
    ],
  ),
  'tm.editor.simulation': HelpNodeCopy(
    title: 'Simulation',
    keywords: ['TM', 'MT', 'simulation', 'input', 'trace', 'playback'],
  ),
  HelpTopicIds.tmEditorSimulation: HelpNodeCopy(
    blocks: _tmSimulationBlocks,
    title: 'Enter input and simulate',
    body:
        'TM simulation runs the current machine from its initial state on one '
        'input string. Use it to test whether an accepting state is reachable '
        'for that particular input. Enter text in Input String, leave it blank '
        'for ε, preserve any intended whitespace, and select Simulate TM; while '
        'running, use Cancel simulation if needed. The result is Accepted, '
        'Rejected, cancelled, timed out, or an error, with a recorded trace '
        'when execution starts. Input symbols must belong to the input alphabet, '
        'and the UI run has a five-second timeout plus bounds of 10,000 '
        'deterministic steps or 100,000 nondeterministic configurations; '
        'cancellation returns no partial trace. Continue with Trace and tape.',
    keywords: [
      'TM',
      'MT',
      'Input String',
      'Simulate TM',
      'Cancel simulation',
      'timeout'
    ],
  ),
  HelpTopicIds.tmEditorSimulationTraceAndTape: HelpNodeCopy(
    blocks: _tmSimulationBlocks,
    title: 'Read the trace and tape',
    body: 'The TM trace records the state, tape contents, applied transition, '
        'and head position at each available step. Use it to explain a result '
        'or locate the first unexpected tape operation. Select a row or '
        'timeline position, use Previous step and Next step, or use Play, Pause, '
        'and Reset. The selected state, transition, tape cell, and tape snapshot '
        'are synchronized, and long traces fold after the first visible block. '
        'A cancelled run has no trace, and a timeout or rejected branch may end '
        'before an accepting configuration. Continue with Results and canvas '
        'playback.',
    keywords: [
      'TM',
      'MT',
      'trace',
      'Previous step',
      'Next step',
      'Play',
      'Pause',
      'Reset'
    ],
  ),
  HelpTopicIds.tmEditorSimulationResultsAndCanvas: HelpNodeCopy(
    blocks: _tmSimulationBlocks,
    title: 'Results and canvas playback',
    body: 'Simulation results distinguish acceptance from rejection and expose '
        'the recorded path for playback. Use View on Canvas when you want the '
        'graph and tape to replay together. After a run, inspect Accepted or '
        'Rejected, then activate View on Canvas and use Previous step, Play or '
        'Pause, Next step, and Close. Playback highlights the active graph '
        'elements and projects each tape snapshot without changing the machine. '
        'View on Canvas is offered only in the narrow iOS layout below 1024 '
        'logical pixels; other layouts keep playback inside the trace panel. '
        'Continue with Halting and acceptance.',
    keywords: [
      'TM',
      'MT',
      'Accepted',
      'Rejected',
      'View on Canvas',
      'playback',
      'iOS',
    ],
  ),
  'tm.editor.algorithms': HelpNodeCopy(
    title: 'Analysis',
    keywords: ['TM', 'MT', 'analysis', 'bounded', 'trace', 'profile'],
  ),
  HelpTopicIds.tmEditorAlgorithmsOverview: HelpNodeCopy(
    blocks: _tmAlgorithmBlocks,
    title: 'Turing machine analysis overview',
    body: 'TM Analysis combines bounded execution tools with structural '
        'reports for the current machine. Use it after drawing or loading an '
        'example when you want a focused view of states, transitions, tape '
        'use, reachability, timing, or warnings. Termination and Cycles '
        'classifies one concrete input with visible resource bounds. '
        'Reachability compares exact graph reachability with bounded concrete '
        'execution. Language Explorer classifies a bounded shortlex sample. '
        'Select Termination and Cycles, Reachability, Language Explorer, Tape '
        'Trace, Time Profile, or Space Profile. Controls are disabled only '
        'while an analysis is running; an absent or invalid machine reports an '
        'error after activation. Open the topic for the chosen focus.',
    keywords: ['TM', 'MT', 'TM Analysis', 'structural analysis', 'results'],
  ),
  HelpTopicIds.tmEditorAlgorithmsDecidability: HelpNodeCopy(
    blocks: _tmAlgorithmBlocks,
    title: 'Termination and Cycles',
    body: 'Termination and Cycles classifies one concrete input under the '
        'displayed step, configuration, and time limits. A halted run is '
        'accepted or rejected. A repeated deterministic configuration proves '
        'a cycle and includes its start and period. Reaching a limit is '
        'inconclusive, not rejection or proof of a loop. Nondeterministic '
        'exploration accepts if one branch accepts and rejects only after its '
        'finite reachable configuration graph is exhausted. This per-input '
        'result makes no claim about termination on every input.',
    keywords: [
      'TM',
      'MT',
      'Termination and Cycles',
      'halting',
      'cycle',
      'bounded',
    ],
  ),
  HelpTopicIds.tmEditorAlgorithmsReachableStates: HelpNodeCopy(
    blocks: _tmAlgorithmBlocks,
    title: 'Reachability',
    body: 'Reachability keeps two claims separate. Structural '
        'reachability iteratively follows control edges and proves disconnected '
        'states exactly. Bounded semantic reachability explores canonical '
        'configurations for the comma-separated input scope and records the '
        'shortest witness trace for every observed state. The panel shows step, '
        'configuration, and time limits. Reaching a limit makes the report '
        'incomplete; states not yet observed are not called unreachable. Canvas '
        'colors distinguish observed states, bounded not-observed states, and '
        'proven structural disconnection. Continue with Configurations.',
    keywords: ['TM', 'MT', 'Reachability', 'reachable', 'unreachable'],
  ),
  HelpTopicIds.tmEditorAlgorithmsLanguage: HelpNodeCopy(
    blocks: _tmAlgorithmBlocks,
    title: 'Language Explorer',
    body: 'Language Explorer enumerates the empty word first, then words in '
        'deterministic shortlex order up to the configured length and candidate '
        'cap. Set the per-input step, configuration, and time limits, check the '
        'estimated candidate count, then select Language Explorer. The report '
        'keeps four separate groups: accepted, halted rejected, proven cycle, '
        'and inconclusive. A timeout, step bound, configuration-memory bound, '
        'or cancellation is never listed as rejection. Capping or cancelling '
        'keeps the evaluated prefix. Select a word to load its bounded trace '
        'and metrics. This sample does not infer the complete language or prove '
        'equivalence. Continue with Recursively enumerable languages.',
    keywords: [
      'TM',
      'MT',
      'Language Explorer',
      'shortlex',
      'candidate cap',
      'inconclusive',
    ],
  ),
  HelpTopicIds.tmEditorAlgorithmsTapeOperations: HelpNodeCopy(
    blocks: _tmAlgorithmBlocks,
    title: 'Tape Trace',
    body: 'Tape Trace executes the machine on the shared concrete input '
        'and measures one real branch. It reports symbol reads and writes, '
        'changed cells, movements, reversals, stable logical cell positions, '
        'visited interval, peak nonblank cells, transition counts, and a sparse '
        'initial-to-final tape diff. Defined but unexecuted transitions remain '
        'visible as static coverage. For an NTM, the report labels the selected '
        'accepting, rejecting, cyclic, or longest bounded branch instead of '
        'combining unrelated branches. Open Related execution trace to inspect '
        'the retained trace produced by the same run. Empty input means epsilon; '
        'step, configuration, and time bounds still apply. Only one tape is '
        'executed. Continue with Tape and head.',
    keywords: [
      'TM',
      'MT',
      'Tape Trace',
      'read symbol',
      'write symbol',
      'head movement',
    ],
  ),
  HelpTopicIds.tmEditorAlgorithmsTime: HelpNodeCopy(
    blocks: _tmAlgorithmBlocks,
    title: 'Time Profile',
    body: 'Time Profile groups candidate inputs from length zero '
        'through the displayed maximum and runs each candidate with explicit '
        'transition-step, configuration, and time budgets. Candidate counts '
        'are visible before execution. Exhaustive DTM rows report halting-run '
        'minimum and maximum transition steps, and the observed maximum opens '
        'its witness input and retained trace. Sampled rows and rows containing '
        'unknown or cancelled runs remain visibly incomplete. For an NTM, the '
        'same action reports observed exploration depth and configurations '
        'explored as operational metrics, never deterministic time complexity. '
        'Device wall-clock is labeled as a profiler diagnostic. The bounded '
        'points do not infer a Big-O class. Continue with Time and space '
        'complexity.',
    keywords: [
      'TM',
      'MT',
      'Time Profile',
      'transition steps',
      'input length',
      'witness',
    ],
  ),
  HelpTopicIds.tmEditorAlgorithmsSpace: HelpNodeCopy(
    blocks: _tmAlgorithmBlocks,
    title: 'Space Profile',
    body: 'Space Profile groups bounded executions by input length. It reports '
        'the largest visited head span and the largest simultaneous nonblank '
        'cell count, with a witness input for each maximum. Configure the '
        'candidate cap and per-input execution limits before running it. The '
        'span uses stable logical tape coordinates for every head movement. An '
        'exhaustive row covers every word of that length. A sampled row is the '
        'deterministic shortlex prefix, and an incomplete row encountered an '
        'enumeration, execution, or cancellation bound. NTM maxima cover all '
        'explored branch configurations under the displayed configuration '
        'limit. The single tape stores both input and work data. Declared tape '
        'alphabet size is not used as space. This bounded profile does not '
        'establish asymptotic space complexity. '
        'Continue with Time and space complexity.',
    keywords: [
      'TM',
      'MT',
      'Space Profile',
      'visited span',
      'nonblank cells',
      'space',
      'metrics',
    ],
  ),
  HelpTopicIds.tmEditorFilesAndExamples: HelpNodeCopy(
    title: 'Files and examples',
    body: 'Bundled TM examples provide ready-made machines, and the file panel '
        'exports the current diagram as SVG. Use MT - a^n b^n, MT - Binário '
        'para unário, MT - Cópia de string, MT - Incremento binário, or MT - '
        'Verificador de palíndromo to study a working machine. Open TM Analysis '
        'and select an example, or choose Export SVG on native platforms and '
        'Download SVG on the web. Loading an example replaces the current TM; '
        'SVG includes the tape, head, states, transitions, and legend. The '
        'workspace does not offer TM JFLAP or JSON import or save actions, and '
        'canceling an export leaves the model unchanged. Continue with the '
        'editor overview.',
    keywords: [
      'TM',
      'MT',
      'examples',
      'Export SVG',
      'Download SVG',
      'JFLAP',
      'JSON'
    ],
  ),
  'tm.theory': HelpNodeCopy(
    title: 'Theory',
    keywords: ['TM', 'MT', 'Turing machine', 'theory', 'computability'],
  ),
  HelpTopicIds.tmTheoryTm: HelpNodeCopy(
    title: 'Turing machines',
    body:
        'A Turing machine combines finite control with a tape whose cells can '
        'be read and rewritten. Use this model for algorithms and languages '
        'that need memory beyond finite states or one stack. Define states, an '
        'initial state, accepting states, a tape alphabet with a blank symbol, '
        'and read/write/move transitions. A run produces a sequence of '
        'configurations and accepts when it reaches an accepting state. The app '
        'executes a single-tape model with bounded runtime, so a timeout is not '
        'a mathematical rejection. Continue with Tape and head.',
    keywords: [
      'TM',
      'MT',
      'Turing machine',
      'finite control',
      'tape',
      'computation'
    ],
  ),
  HelpTopicIds.tmTheoryTapeAndHead: HelpNodeCopy(
    title: 'Tape and head',
    body: 'The tape supplies unbounded conceptual storage, and one head reads '
        'and writes its current cell. Use these concepts to interpret every TM '
        'transition. At each step, match the read symbol, write the replacement, '
        'move Left, Right, or Stay, and enter the target state. The next '
        'configuration reflects the new tape, head position, and state; '
        'unwritten cells contain the blank symbol. The app grows a finite list '
        'as needed and presents one tape, while multi-tape TMs would coordinate '
        'several tapes and heads in each step. Continue with Configurations.',
    keywords: [
      'TM',
      'MT',
      'tape',
      'head',
      'blank symbol',
      'Left',
      'Right',
      'Stay'
    ],
  ),
  HelpTopicIds.tmTheoryConfigurations: HelpNodeCopy(
    title: 'Configurations',
    body:
        'A configuration is the complete instantaneous state of a TM: control '
        'state, tape contents, and head position. Use configurations to reason '
        'about one transition or compare consecutive trace rows. Start from '
        'the initial state with the input on the tape and the head at position '
        'zero, then apply one matching rule at a time. Each trace step records '
        'the resulting state, tape, transition, and head. A graph-reachable '
        'state need not occur in a realizable configuration because symbols '
        'constrain rules. Continue with Halting and acceptance.',
    keywords: [
      'TM',
      'MT',
      'configuration',
      'state',
      'tape contents',
      'head position'
    ],
  ),
  HelpTopicIds.tmTheoryHaltingAndAcceptance: HelpNodeCopy(
    title: 'Halting and acceptance',
    body:
        'A run accepts when it reaches an accepting state; it rejects when it '
        'halts elsewhere because no matching transition remains. Use this '
        'distinction when reading accepted, rejected, proven-cycle, or '
        'bounded-unknown results. Follow the trace from the initial '
        'configuration until an accepting state, a missing rule, or a '
        'computation limit ends the app '
        'run. The result identifies the observed outcome and preserves the '
        'available trace. A repeated deterministic configuration proves a '
        'cycle; timeout and other resource limits remain bounded unknown, not '
        'proofs that the mathematical machine rejects or never halts. Continue '
        'with Decidable languages.',
    keywords: ['TM', 'MT', 'halting', 'acceptance', 'rejection', 'timeout'],
  ),
  HelpTopicIds.tmTheoryDecidableLanguages: HelpNodeCopy(
    title: 'Decidable languages',
    body: 'A language is decidable when some TM halts on every input and '
        'accepts exactly its members. Use the definition to separate total '
        'decision procedures from recognizers that may run forever. Argue both '
        'membership correctness and termination for every possible input. A '
        'valid decider returns acceptance or rejection after finitely many '
        'steps. Testing examples or running Termination and Cycles cannot '
        'establish that universal property; the app only reports structural '
        'warnings. Continue with Recursively enumerable languages.',
    keywords: [
      'TM',
      'MT',
      'decidable language',
      'decider',
      'termination',
      'halting'
    ],
  ),
  HelpTopicIds.tmTheoryRecursivelyEnumerable: HelpNodeCopy(
    title: 'Recursively enumerable languages',
    body: 'A recursively enumerable language has a TM recognizer that accepts '
        'members but may run forever on nonmembers. Use this class when '
        'acceptance can be witnessed even though total rejection is not '
        'guaranteed. Describe the recognizing machine and show that members '
        'eventually reach acceptance. Successful runs demonstrate individual '
        'members, while a timeout leaves a nonmember or nontermination '
        'undetermined. A bounded simulator cannot distinguish those cases or '
        'prove that a whole language is recursively enumerable. Continue with '
        'Halting and acceptance.',
    keywords: [
      'TM',
      'MT',
      'recursively enumerable',
      'recognizer',
      'nontermination'
    ],
  ),
  HelpTopicIds.tmTheoryTimeAndSpace: HelpNodeCopy(
    title: 'Time and space complexity',
    body: 'TM time counts computation steps as a function of input length, and '
        'space counts distinct tape cells used. Use these measures to compare '
        'algorithms independently of one device run. Choose an input-size '
        'parameter, derive upper or lower bounds over all relevant runs, and '
        'state whether the machine is deterministic or nondeterministic. The '
        'result is an asymptotic argument such as O(f(n)), not one finite set '
        'of observed panel values. Time Profile supplies empirical DTM '
        'transition counts or explicitly labeled NTM exploration metrics; it '
        'does not infer the asymptotic class. Space Profile supplies observed '
        'cell maxima and witnesses for the same kind of finite input scope; '
        'it does not treat alphabet size as used space. Continue by tracing '
        'representative inputs without treating them as a proof.',
    keywords: [
      'TM',
      'MT',
      'time complexity',
      'space complexity',
      'steps',
      'tape cells'
    ],
  ),
  'regex': HelpNodeCopy(
    title: 'Regular expressions',
    keywords: ['regex', 'regular expression', 'pattern', 'regular language'],
  ),
  'regex.editor': HelpNodeCopy(
    title: 'Editor and tools',
    keywords: ['regex', 'editor', 'validation', 'conversion', 'analysis'],
  ),
  HelpTopicIds.regexEditorOverview: HelpNodeCopy(
    title: 'Regex editor overview',
    body:
        'The Regex workspace keeps pattern input, an alphabet, and live string '
        'testing in the editor. Its Algorithms action opens the five examples '
        'Regex - Repetição de A, Regex - Termina com AB, Regex - Binário '
        'iniciado por 0, Regex - Pares AB ou BA, and Regex - Blocos de A e B, '
        'together with conversions, simplification, structural analysis, '
        'samples, and equivalence comparison. Use it to explore a regular expression '
        'or move between regex and finite-automaton representations. Enter a '
        'pattern, keep a non-empty Alphabet, follow the validation banner, and '
        'then choose the operation you need. Results appear in their cards or '
        'in the shared FSA state used by conversion panels. Invalid or empty '
        'input blocks operations, and some alphabet-dependent constructs need '
        'the listed universe. Continue with Input and validation.',
    keywords: ['regex', 'editor', 'Alphabet', 'validation', 'FSA'],
  ),
  HelpTopicIds.regexEditorInput: HelpNodeCopy(
    title: 'Input and validation',
    body: 'Regular Expression is the pattern field, and its banner reports '
        'whether the current syntax is usable. Use validation before testing, '
        'converting, simplifying, analyzing, or generating samples. Type in '
        'the field or select Validate Regex; validation runs after every '
        'change and reports a position for malformed escapes, delimiters, '
        'character classes, unions, or quantifiers. A valid pattern produces '
        'Valid regex and enables the provider operations. Empty patterns, '
        'unbalanced parentheses, empty classes, descending ranges, missing '
        'union operands, and consecutive quantifiers remain invalid. Continue '
        'with Alphabet.',
    keywords: ['regex', 'Regular Expression', 'Validate Regex', 'invalid'],
  ),
  HelpTopicIds.regexEditorAlphabet: HelpNodeCopy(
    title: 'Alphabet',
    body: 'Alphabet is the set of individual characters available as the '
        'universe for alphabet-dependent regex constructs. Edit it when a '
        'wildcard . or complemented shortcut must know which symbols it may '
        'represent. Enter the characters directly; every Unicode rune becomes '
        'one symbol, duplicates collapse in the resolved set, and spaces '
        'count. Conversion, matching, analysis, and sample generation then '
        'expand ., \\D, \\W, and \\S against that set. An empty Alphabet '
        'disables testing, conversion, simplification, analysis, and sample '
        'generation; comparison can still handle two expressions that do not '
        'need a universe. Continue with Test strings.',
    keywords: ['regex', 'Alphabet', 'wildcard', r'\D', r'\W', r'\S'],
  ),
  HelpTopicIds.regexEditorTestStrings: HelpNodeCopy(
    title: 'Test strings',
    body: 'Test String checks whether the whole input belongs to the language '
        'of the current regex. Use it for quick membership examples after the '
        'pattern and Alphabet are valid. Type in Test String or select its play '
        'action; every edit starts a fresh NFA simulation, and an empty test '
        'string represents the empty word. The banner changes to Matches! or '
        'Does not match when the latest simulation finishes. Conversion or '
        'simulation errors replace a reliable result, and stale asynchronous '
        'requests are ignored. Continue with Conversions.',
    keywords: ['regex', 'Test String', 'Matches', 'Does not match', 'empty'],
  ),
  'regex.editor.conversions': HelpNodeCopy(
    title: 'Conversions',
    keywords: ['regex', 'conversion', 'NFA', 'DFA', 'FA to Regex'],
  ),
  HelpTopicIds.regexEditorConversions: HelpNodeCopy(
    title: 'Conversion overview',
    body: 'Conversions connect the Regex workspace to equivalent finite '
        'automata. Use them to inspect operational models or receive a pattern '
        'produced from the current FSA workspace. With a valid pattern and '
        'non-empty Alphabet, open Algorithms and select Convert to NFA or '
        'Convert to DFA; an '
        'FA-to-Regex result appears here after that command runs from FSA. The '
        'created automaton is stored in the shared FSA provider, while DFA '
        'conversion also opens the FSA workspace. Syntax, alphabet expansion, '
        'or downstream conversion failures are reported instead of a partial '
        'result. Continue with Convert to NFA.',
    keywords: ['regex', 'Convert to NFA', 'Convert to DFA', 'FA-to-Regex'],
  ),
  HelpTopicIds.regexEditorConversionsToNfa: HelpNodeCopy(
    title: 'Convert to NFA',
    body: 'Convert to NFA applies Thompson construction to the current regex '
        'and produces an equivalent nondeterministic finite automaton. Use it '
        'when you want to see how union, concatenation, or repetition becomes '
        'states and epsilon transitions. Validate the pattern, keep Alphabet '
        'non-empty, and select Convert to NFA. A success message confirms the '
        'new NFA is available in the FSA workspace provider. Invalid syntax or '
        'an alphabet-dependent token without a usable universe stops the '
        'conversion. Continue with the FSA Regex to NFA topic or Convert to DFA.',
    keywords: ['regex', 'Convert to NFA', 'Thompson', 'epsilon transition'],
  ),
  HelpTopicIds.regexEditorConversionsToDfa: HelpNodeCopy(
    title: 'Convert to DFA',
    body: 'Convert to DFA builds the regex NFA, determinizes it, and completes '
        'missing transitions. Use it when simulation or comparison needs a '
        'total deterministic automaton. Validate the regex, keep Alphabet '
        'non-empty, and select Convert to DFA. The result replaces the shared '
        'FSA model and the app opens the FSA workspace. A failure at either '
        'regex-to-NFA or NFA-to-DFA conversion is shown and leaves no promised '
        'DFA result. Continue with DFA theory or Equivalence.',
    keywords: ['regex', 'Convert to DFA', 'determinize', 'complete DFA'],
  ),
  HelpTopicIds.regexEditorConversionsFaToRegex: HelpNodeCopy(
    title: 'FA to regex result',
    body: 'FA to Regex eliminates states from the current finite automaton and '
        'sends its resulting expression to this workspace. Use it after the '
        'FSA conversion command when you want a textual description of that '
        'automaton language. Run FA to Regex in FSA, return to Regex if needed, '
        'and use Simplify Output to choose the simplified or raw value when '
        'both exist. The result card offers selectable text and Copy to '
        'clipboard. No card appears until the shared algorithm provider '
        'contains a conversion result. Continue with Simplification.',
    keywords: ['regex', 'FA to Regex', 'state elimination', 'Simplify Output'],
  ),
  HelpTopicIds.regexEditorSimplification: HelpNodeCopy(
    title: 'Simplification steps',
    body: 'Simplification applies supported regular-algebra identities while '
        'recording each transformation. Use Simplify with Steps to study why a '
        'valid expression can be shortened. Run the action, expand the result, '
        'and move with Previous Step, Next Step, or a timeline item. The card '
        'shows original and simplified regexes, rules, before/after fragments, '
        'character savings, reduction, and execution time when progress was '
        'made. A valid non-empty regex is required, and equivalent expressions '
        'may have no simplifying rule. Continue with Complexity analysis.',
    keywords: ['regex', 'Simplify with Steps', 'Previous Step', 'reduction'],
  ),
  HelpTopicIds.regexEditorComplexity: HelpNodeCopy(
    title: 'Complexity analysis',
    body: 'Complexity Analysis summarizes the pattern structure rather than '
        'the runtime complexity of a matching engine. Use Analyze Complexity '
        'to compare expression shapes. Run the action and expand details to '
        'see Star Height, Nesting Depth, Complexity Score, operator counts, '
        'and the resolved Alphabet. The card classifies the pattern as Simple, '
        'Moderate, or Complex from weighted structural metrics. Counts reflect '
        'the parsed expression and are not asymptotic time or space guarantees. '
        'Continue with Sample strings.',
    keywords: ['regex', 'Analyze Complexity', 'Star Height', 'operator counts'],
  ),
  HelpTopicIds.regexEditorSampleStrings: HelpNodeCopy(
    title: 'Sample strings',
    body: 'Sample Strings generates distinct examples accepted by the current '
        'regex. Use it to explore a language before entering your own Test '
        'String. Select Generate Sample Strings for up to 10 examples or '
        'Generate More for up to 15, then expand, select a chip, or use Copy '
        'All. The summary reports the count, whether ε is accepted, and the '
        'shortest generated string when available. Generation caps each sample '
        'at 30 characters and may return fewer unique values than requested. '
        'Continue with Test strings or Equivalence.',
    keywords: ['regex', 'Sample Strings', 'Generate More', 'Copy All', '30'],
  ),
  HelpTopicIds.regexEditorEquivalence: HelpNodeCopy(
    title: 'Compare equivalence',
    body: 'Compare Equivalence checks whether two regexes describe the same '
        'language over the current Alphabet. Use it when different patterns '
        'should accept exactly the same strings. Keep the primary expression '
        'in Regular Expression, enter the other in the comparison field, and '
        'select Compare Equivalence. Each expression is converted to a '
        'completed DFA and the banner reports equivalent or not equivalent. '
        'Both expression fields are required; Alphabet must be non-empty only '
        'when either expression uses . or a complemented shortcut, and '
        'conversion errors are shown as a failed comparison message. Continue '
        'with Equivalence with FSA.',
    keywords: ['regex', 'Compare Equivalence', 'equivalent', 'completed DFA'],
  ),
  HelpTopicIds.regexEditorEmbeddedFsaPanels: HelpNodeCopy(
    title: 'Embedded FSA panels',
    body: 'Desktop and tablet Regex layouts reuse the FSA Algorithm Panel and '
        'Simulation Panel beside the regex form. Use them as shortcuts for '
        'Regex to NFA, NFA to DFA, clearing inputs, or simulating a test string. '
        'Activate a supported panel command and it delegates to the same regex '
        'handlers and shared automaton state as the main controls. The panels '
        'show their normal FSA results and disabled actions where no Regex '
        'handler is supplied. Mobile keeps the regex form in one scrolling '
        'column and does not embed these side panels. Continue with the FSA '
        'editor overview.',
    keywords: ['regex', 'Algorithm Panel', 'Simulation Panel', 'desktop'],
  ),
  'regex.theory': HelpNodeCopy(
    title: 'Theory',
    keywords: ['regex', 'theory', 'operators', 'regular language', 'FSA'],
  ),
  HelpTopicIds.regexTheoryRegex: HelpNodeCopy(
    title: 'Regular expressions',
    body: 'A regular expression denotes a regular language by combining atomic '
        'symbols with finite choice, sequence, and repetition. Use this model '
        'to describe exactly the languages recognizable by finite automata. '
        'Build a pattern from a literal, grouping ( ), concatenation, union |, '
        'Kleene star *, plus +, optional ?, wildcard ., character class [ ], '
        'shortcuts \\d, \\D, \\s, \\S, \\w, and \\W, and epsilon ε. The '
        'result denotes a set of complete strings, not a substring search in '
        'the editor. Syntax validity alone does not show that a sample belongs '
        'to the language. Continue with Literals and grouping.',
    keywords: ['regex', 'regular language', 'operator', 'finite automaton'],
  ),
  HelpTopicIds.regexTheoryLiteralsAndGrouping: HelpNodeCopy(
    title: 'Literals, sets, and grouping',
    body: 'A literal matches itself, while grouping ( ) makes a subexpression '
        'act as one operand. Use groups to control scope and use a character '
        'class [ ] or range such as [a-c] for one symbol from a set. Type '
        'metacharacters after a backslash when they must be literal; wildcard . '
        'uses the Alphabet, and the shortcuts \\d, \\D, \\s, \\S, \\w, and '
        '\\W provide predefined or complemented sets. A match consumes one '
        'symbol for each literal, wildcard, class, or shortcut. Classes cannot '
        'be empty or contain descending ranges, and complemented forms need a '
        'non-empty universe. Continue with Concatenation and union.',
    keywords: ['regex', 'literal', 'grouping', 'character class', 'wildcard'],
  ),
  HelpTopicIds.regexTheoryConcatenationAndUnion: HelpNodeCopy(
    title: 'Concatenation and union',
    body: 'Concatenation places expressions next to each other, while union | '
        'chooses either operand. Use concatenation for ordered pieces such as '
        'ab and union for alternatives such as a|b. Write concatenation '
        'without an operator and put | between complete left and right '
        'expressions. The language of ab contains joined strings; the language '
        'of a|b contains strings from either side. A leading, trailing, or '
        'operand-free | is invalid, and grouping may be needed to define its '
        'scope. Continue with Kleene star and plus.',
    keywords: ['regex', 'concatenation', 'union', '|', 'alternative'],
  ),
  HelpTopicIds.regexTheoryKleeneStarAndPlus: HelpNodeCopy(
    title: 'Kleene star and plus',
    body: 'Kleene star * repeats its preceding expression zero or more times, '
        'and plus + repeats it one or more times. Use * when the empty word is '
        'allowed and + when at least one copy is required. Place the postfix '
        'operator immediately after a literal, class, shortcut, or grouped '
        'expression, as in a* or (ab)+. The resulting language contains every '
        'finite permitted repetition. A quantifier cannot start an expression '
        'or directly follow another quantifier in this editor. Continue with '
        'Optional.',
    keywords: ['regex', 'Kleene star', '*', 'plus', '+', 'repetition'],
  ),
  HelpTopicIds.regexTheoryOptional: HelpNodeCopy(
    title: 'Optional operator',
    body: 'The optional ? operator allows zero or one copy of its preceding '
        'expression. Use it for an optional symbol or grouped segment such as '
        'a? or (ab)?. Type the literal ? after the operand; the question-mark '
        'icon shown beside Optional (?) in Complexity Analysis is decorative '
        'and is not a Help action. The language includes both the operand and '
        'the empty choice. A leading ? or consecutive quantifiers are invalid. '
        'Continue with Precedence.',
    keywords: ['regex', 'optional', '?', 'zero or one', 'decorative icon'],
  ),
  HelpTopicIds.regexTheoryPrecedence: HelpNodeCopy(
    title: 'Operator precedence',
    body: 'Precedence decides which operands each regex operator controls when '
        'parentheses are absent. Use it to read or write compact expressions '
        'without changing their language accidentally. The editor applies '
        'postfix *, +, and ? first, then implicit concatenation, then union |; '
        'grouping ( ) overrides that order. Thus ab|c means (ab)|c, while '
        'a(b|c) concatenates a with either choice. Ambiguous intent is not a '
        'syntax error, so add parentheses when the desired structure is not '
        'obvious. Continue with Lambda and epsilon.',
    keywords: ['regex', 'precedence', 'postfix', 'concatenation', 'union'],
  ),
  HelpTopicIds.regexTheoryLambda: HelpNodeCopy(
    title: 'Lambda and epsilon',
    body: 'Lambda and epsilon are common names for the empty word, which has '
        'length zero. Use the empty word when a language contains a string with '
        'no symbols or when an automaton moves without consuming input. In the '
        'Regex field, enter epsilon ε to create the supported empty-word node; '
        'an empty Test String tests that word. Conversion represents the '
        'necessary moves as epsilon transitions in the resulting NFA. The '
        'character λ is not an empty-word token in this regex parser and is '
        'treated as a literal symbol if typed. Continue with Regular languages.',
    keywords: ['regex', 'lambda', 'epsilon', 'ε', 'empty word'],
  ),
  HelpTopicIds.regexTheoryRegularLanguages: HelpNodeCopy(
    title: 'Regular languages',
    body: 'A regular language is any language denoted by a regex or recognized '
        'by a finite automaton. Use this class for patterns that need only '
        'finite-state memory. Construct a regex, FSA, or both, then reason about '
        'all strings accepted by the representation. Conversion and '
        'equivalence checks preserve the represented regular language when '
        'they succeed. Testing many strings is evidence about those examples, '
        'not a proof about every string. Continue with Equivalence with FSA.',
    keywords: ['regex', 'regular language', 'finite-state memory', 'FSA'],
  ),
  HelpTopicIds.regexTheoryEquivalenceWithFsa: HelpNodeCopy(
    title: 'Equivalence with finite automata',
    body: 'Regexes and finite automata have the same expressive power over '
        'regular languages. Use that equivalence to switch between compact '
        'algebraic notation and an operational state graph. Thompson '
        'construction maps regex to NFA, subset construction maps NFA to DFA, '
        'and state elimination maps FA to regex. A successful conversion '
        'accepts the same language even though its shape may differ. Conversion '
        'errors or a few matching samples do not establish equivalence by '
        'themselves. Continue with Conversion overview or Compare equivalence.',
    keywords: ['regex', 'FSA', 'NFA', 'DFA', 'state elimination'],
  ),
  'pumping': HelpNodeCopy(
    title: 'Pumping Lemma',
    keywords: ['pumping lemma', 'regularity', 'non-regular', 'proof'],
  ),
  'pumping.editor': HelpNodeCopy(
    title: 'Game and progress',
    keywords: ['pumping lemma', 'game', 'challenge', 'progress'],
  ),
  HelpTopicIds.pumpingEditorOverview: HelpNodeCopy(
    title: 'Pumping workspace overview',
    body: 'The Pumping workspace combines a classification game, a three-tab '
        'theory panel, and a progress panel. Use it to practice recognizing '
        'regular and non-regular languages while reviewing the proof method. '
        'Start the game, answer each challenge, read its feedback, and consult '
        'Theory, Steps, or Examples when needed. The workspace updates game '
        'points and the separate attempt history as you proceed. It is guided '
        'practice rather than a proof editor or automatic regularity decision '
        'procedure. Continue with Game workflow.',
    keywords: ['pumping lemma', 'game', 'Theory', 'Steps', 'Examples'],
  ),
  HelpTopicIds.pumpingEditorGame: HelpNodeCopy(
    title: 'Game workflow',
    body: 'Pumping Lemma Game presents eight fixed language-classification '
        'challenges in sequence. Use it to test your understanding after '
        'reading the theorem or to rehearse common examples. Select Start Game, '
        'inspect Language, description, and Examples, choose one regularity '
        'answer, and select Submit Answer. Feedback explains the stored answer '
        'and offers the next available action. Submit Answer stays disabled '
        'until a choice is selected, and the game does not ask for a formal '
        'proof. Continue with Difficulty and challenges.',
    keywords: ['pumping lemma', 'Start Game', 'Submit Answer', 'challenge'],
  ),
  HelpTopicIds.pumpingEditorDifficultyAndChallenges: HelpNodeCopy(
    title: 'Difficulty and challenges',
    body: 'Challenges are grouped into levels 1 through 4 and labeled EASY, '
        'MEDIUM, or HARD. Use the badge and examples to calibrate how much '
        'counting, duplication, parity, or closure reasoning is involved. Move '
        'through the eight bundled challenges with Next Challenge after '
        'submitting each answer. The header shows the current level, difficulty, '
        'challenge number, point score, and any correct-answer streak. Correct '
        'answers start at 10, 20, or 30 points for Easy, Medium, or Hard, add '
        'twice the level, and gain a 50% base-point bonus after two consecutive '
        'correct answers; an incorrect Hard attempt receives 5 points. These '
        'scores do not supply a witness or prove the displayed classification. '
        'Continue with Regularity choice.',
    keywords: ['pumping lemma', 'EASY', 'MEDIUM', 'HARD', 'streak'],
  ),
  HelpTopicIds.pumpingEditorRegularityChoice: HelpNodeCopy(
    title: 'Choose regular or not regular',
    body: 'The game asks Is this language regular? and offers Yes, it is '
        'regular or No, it is not regular. Use the choice to classify the '
        'whole displayed language, not only its listed examples. Select one '
        'card and then Submit Answer; the selected card gains its active '
        'appearance. The submitted value is compared with the challenge data '
        'and records a correct or wrong attempt. Examples alone cannot prove '
        'the classification, and a non-regular subset alone does not make an '
        'arbitrary union non-regular. Continue with Witness and decomposition.',
    keywords: ['pumping lemma', 'regular', 'not regular', 'classification'],
  ),
  HelpTopicIds.pumpingEditorWitnessAndDecomposition: HelpNodeCopy(
    title: 'Witness and decomposition in the game',
    body: 'A pumping-lemma proof normally chooses a witness string and reasons '
        'about every allowed decomposition s = xyz. Use those ideas mentally '
        'when deciding a non-regular challenge. Read the language, examples, '
        'and Help Steps, then identify a witness of length at least p and how y '
        'could be placed. The feedback may show a representative witness and '
        'decomposition after submission. The current game has no witness, x, y, '
        'or z input fields and does not validate a decomposition supplied by '
        'the player. Continue with Pumping choice and submit.',
    keywords: ['pumping lemma', 'witness', 'decomposition', 'xyz', 'p'],
  ),
  HelpTopicIds.pumpingEditorPumpingChoiceAndSubmit: HelpNodeCopy(
    title: 'Pumping choice and submit',
    body: 'A contradiction proof chooses a pumping exponent only after the '
        'opponent decomposition is considered. Use that reasoning before '
        'submitting a non-regular classification. In the current game, choose '
        'only the regularity card and select Submit Answer; there is no control '
        'for k, pumping up, pumping down, or a constructed string. Submission '
        'records the attempt and opens Correct! or Incorrect feedback. Without '
        'a selected classification the button remains disabled, and the UI '
        'cannot check your quantifier reasoning. Continue with Feedback, retry, '
        'and practice.',
    keywords: ['pumping lemma', 'Submit Answer', 'pumping exponent', 'k'],
  ),
  HelpTopicIds.pumpingEditorFeedbackRetryAndPractice: HelpNodeCopy(
    title: 'Feedback, retry, and practice',
    body: 'Feedback reveals Correct! or Incorrect, an explanation, and hints '
        'for a wrong answer when the challenge provides them. Use it to compare '
        'your reasoning with the stored lesson before moving on. Select Next '
        'Challenge or Finish Game; for a wrong non-final challenge, Retry '
        'clears the choice and records a retry event. Completion reports a '
        'performance level, final point score, percentage, learning messages, '
        'and Practice Again; the thresholds are Expert at 90%, Advanced at 75%, '
        'Intermediate at 60%, and Beginner below 60%. Retry is unavailable on '
        'the final challenge and '
        'does not erase the earlier attempt from history. Continue with Progress.',
    keywords: [
      'pumping lemma',
      'Correct',
      'Incorrect',
      'Retry',
      'Practice Again'
    ],
  ),
  HelpTopicIds.pumpingEditorProgress: HelpNodeCopy(
    title: 'Progress and statistics',
    body: 'Progress summarizes completed challenges and the chronological '
        'attempt/retry history for the current game session. Use it to review '
        'results separately from the point total in the game header. Read '
        'Overall Progress, Accuracy, Correct answers, Attempts, and Score; '
        'accuracy is correct divided by attempts, while this Score is correct '
        'answers divided by total challenges. Submitted answers add attempts '
        'and history, and Next Challenge marks a challenge completed. Mounting '
        'a fresh game session or selecting Practice Again resets these metrics, '
        'and retry events do not add an attempt by themselves. Continue with '
        'Limitations.',
    keywords: ['pumping lemma', 'Accuracy', 'Correct', 'Attempts', 'Score'],
  ),
  HelpTopicIds.pumpingEditorResponsiveLayout: HelpNodeCopy(
    title: 'Responsive layout',
    body: 'The Pumping workspace rearranges Game, Help, and Progress according '
        'to available width. Use the visible controls rather than expecting a '
        'panel at one fixed location. Below 1024 logical pixels, Show or Hide '
        'Game, Help, and Progress controls reveal stacked sections; from 1024 '
        'to below 1400, the game remains primary and Help and Progress use '
        'tablet tabs; at 1400 or wider, all three appear as columns. Content and '
        'progress state remain the same while layout changes. A hidden mobile '
        'section is not cleared or submitted. Continue with the workspace '
        'overview.',
    keywords: ['pumping lemma', 'mobile', 'tablet', 'desktop', 'Show Progress'],
  ),
  'pumping.theory': HelpNodeCopy(
    title: 'Theory',
    keywords: ['pumping lemma', 'theorem', 'quantifiers', 'proof'],
  ),
  HelpTopicIds.pumpingTheoryStatement: HelpNodeCopy(
    title: 'Pumping Lemma statement',
    body: 'The Pumping Lemma gives a necessary repeatability property of every '
        'regular language. Use it mainly to derive a contradiction when a '
        'language cannot be regular. Assume L regular, obtain a pumping length '
        'p, take a sufficiently long s in L, and require an allowed split '
        's = xyz whose middle part can be repeated any number of times. A '
        'regular language must have such a split for every sufficiently long '
        'member. The theorem does not identify p or a split for a language '
        'merely claimed to be regular. Continue with Quantifier order.',
    keywords: ['pumping lemma', 'statement', 'regular language', 'xyz'],
  ),
  HelpTopicIds.pumpingTheoryQuantifiers: HelpNodeCopy(
    title: 'Quantifier order',
    body: 'Quantifier order determines who chooses each object in the Pumping '
        'Lemma and cannot be rearranged. Use the order to avoid proving only '
        'one favorable split. For every regular language L, there exists p ≥ 1 '
        'such that for every s ∈ L with |s| ≥ p, there exists a decomposition '
        's = xyz such that |xy| ≤ p, |y| > 0, and for every k ≥ 0, xyᵏz ∈ L. '
        'A non-regularity proof negates this by answering every proposed p with '
        'a witness s and defeating every allowed decomposition with some k. '
        'Choosing y yourself is insufficient because the regular-language side '
        'owns that existential choice. Continue with Proof strategy.',
    keywords: ['pumping lemma', 'quantifiers', 'for every', 'there exists'],
  ),
  HelpTopicIds.pumpingTheoryProofStrategy: HelpNodeCopy(
    title: 'Proof strategy',
    body:
        'The standard strategy is proof by contradiction against the lemma\'s '
        'necessary condition. Use it when a language appears to require '
        'unbounded counting, copying, or symmetry. Assume L is regular, let p '
        'be its pumping length, choose s ∈ L with |s| ≥ p, cover every valid '
        's = xyz, and choose k that sends xyᵏz outside L. That contradiction '
        'shows the regularity assumption was false. Failure to find a witness '
        'or exponent does not show that L is regular. Continue with Choose a '
        'witness.',
    keywords: [
      'pumping lemma',
      'contradiction',
      'proof strategy',
      'non-regular'
    ],
  ),
  HelpTopicIds.pumpingTheoryChooseWitness: HelpNodeCopy(
    title: 'Choose a witness',
    body: 'The witness is a string s in L whose structure exposes the memory '
        'the language requires. Use it after an arbitrary pumping length p has '
        'been supplied. Define s in terms of p, verify s ∈ L and |s| ≥ p, and '
        'place its first p symbols so every legal y is constrained. A useful '
        'witness makes pumping alter a required count, boundary, copy, or '
        'symmetry. Picking a fixed short string or one outside L cannot '
        'contradict the theorem. Continue with All decompositions.',
    keywords: ['pumping lemma', 'witness', 'string s', 'pumping length'],
  ),
  HelpTopicIds.pumpingTheoryAllDecompositions: HelpNodeCopy(
    title: 'Cover all decompositions',
    body: 'The regular-language claim may choose any split s = xyz satisfying '
        '|xy| ≤ p and |y| > 0. Use case analysis when y can occupy different '
        'parts of the witness. Let an arbitrary valid split be given, derive '
        'what its constraints force about y, and handle every remaining '
        'position or content case. The proof succeeds only if each allowed '
        'split has some damaging pumping exponent. Demonstrating one convenient '
        'decomposition leaves the existential claim intact. Continue with Find '
        'a contradiction.',
    keywords: ['pumping lemma', 'all decompositions', '|xy|', '|y|'],
  ),
  HelpTopicIds.pumpingTheoryContradiction: HelpNodeCopy(
    title: 'Find a contradiction',
    body: 'A contradiction is an exponent k ≥ 0 for which xyᵏz is not in L. '
        'Use pumping down with k = 0 or pumping up with k = 2 when either breaks '
        'the defining property. For an arbitrary legal decomposition, compute '
        'the pumped string and show precisely which membership condition fails. '
        'The result violates the lemma\'s requirement that every k preserve '
        'membership. The exponent may depend on the decomposition, but the '
        'argument must not skip any allowed decomposition. Continue with '
        'Limitations.',
    keywords: ['pumping lemma', 'contradiction', 'pump down', 'pump up', 'k'],
  ),
  HelpTopicIds.pumpingTheoryLimitations: HelpNodeCopy(
    title: 'What the lemma cannot prove',
    body: 'The Pumping Lemma is a necessary condition for regular languages, '
        'not a complete characterization usable in both directions. Use a '
        'successful contradiction to prove a language non-regular. If every '
        'tested witness pumps, or if one decomposition works, look for a '
        'stronger witness or another theorem instead. The lemma proves '
        'non-regularity; it does not prove regularity. A DFA, regular expression, '
        'regular grammar, or closure argument can establish regularity, while '
        'failure of one attempted pumping proof establishes nothing. Continue '
        'with the regular example.',
    keywords: ['pumping lemma', 'limitation', 'proves non-regularity', 'DFA'],
  ),
  HelpTopicIds.pumpingTheoryRegularExample: HelpNodeCopy(
    title: 'Regular example: a*',
    body: 'The language L = {aⁿ | n ≥ 0} is regular and is denoted by a*. Use '
        'it to see how a regular language satisfies the pumping condition, '
        'without mistaking that demonstration for a regularity proof. For any '
        'p and sufficiently long aⁿ, one possible split is x = ε, y = a, and '
        'z = aⁿ⁻¹, so xyᵏz remains a string of a symbols for every k ≥ 0. A '
        'one-state accepting automaton with an a-loop independently proves '
        'regularity. Exhibiting only this favorable split would not prove an '
        'unknown language regular. Continue with the aⁿbⁿ example.',
    keywords: ['pumping lemma', 'regular example', 'a*', 'automaton'],
  ),
  HelpTopicIds.pumpingTheoryNonregularAnbn: HelpNodeCopy(
    title: 'Non-regular example: aⁿbⁿ',
    body: 'The language L = {aⁿbⁿ | n ≥ 0} is not regular because it requires '
        'equal unbounded counts in two blocks. Use it as the standard witness '
        'and decomposition pattern. Given p, choose s = aᵖbᵖ; every split with '
        '|xy| ≤ p and |y| > 0 places a nonempty y entirely among the first a '
        'symbols. Pumping with k = 2 adds a symbols but no b symbols, so xy²z '
        'is outside L. The argument must say every legal y has this form, not '
        'choose y = a without justification. Continue with the ww example.',
    keywords: ['pumping lemma', 'non-regular', 'a^n b^n', 'equal counts'],
  ),
  HelpTopicIds.pumpingTheoryNonregularWw: HelpNodeCopy(
    title: 'Non-regular example: ww',
    body: 'The language L = {ww | w ∈ {a,b}*} contains two identical '
        'consecutive copies and is not the palindrome language. Use a structured '
        'witness such as s = aᵖbaᵖb, where w = aᵖb. Every legal y within the '
        'first p positions consists only of a symbols from the first copy; '
        'pumping changes that copy without changing the second. The pumped '
        'string can no longer be divided into the same two copies, producing a '
        'contradiction. A complete proof must justify that conclusion for every '
        'allowed length of y rather than rely only on an example. Continue with '
        'Proof strategy.',
    keywords: ['pumping lemma', 'non-regular', 'ww', 'duplicate strings'],
  ),
  'shortcuts': HelpNodeCopy(
    title: 'Keyboard shortcuts',
    keywords: ['keyboard', 'shortcuts', 'focus', 'physical keyboard'],
  ),
  HelpTopicIds.shortcutsCanvas: HelpNodeCopy(
    title: 'Canvas shortcuts',
    body: 'Canvas shortcuts operate the focused editable automaton canvas. Use '
        'them when a physical keyboard is available and focus is outside a '
        'text field. Press A to add a state at the visible viewport center and '
        'keep add-state mode active, T for transition mode, V for selection '
        'mode, Delete or Backspace to remove the selected state or transition, '
        'Ctrl+Z or Cmd+Z to undo, and Ctrl+Y, Cmd+Y, '
        'Ctrl+Shift+Z, or Cmd+Shift+Z to redo. The active tool, graph, and '
        'history update just as they do with the visible controls. Editing '
        'shortcuts do nothing on read-only canvases, and letter or history '
        'shortcuts are ignored while a text field owns focus. Escape returns '
        'to selection mode or cancels the current dialog or editor. Continue '
        'with Platform modifiers or Focus navigation.',
    keywords: ['canvas', 'A', 'T', 'V', 'Delete', 'undo', 'redo'],
  ),
  HelpTopicIds.shortcutsSimulation: HelpNodeCopy(
    title: 'Simulation shortcuts',
    body: 'Simulation shortcuts operate the input and controls in the current '
        'simulation panel. Use them with a physical keyboard when entering a '
        'test string or moving between controls. Press Enter while the input '
        'field is focused to submit it, use Tab and Shift+Tab to move through '
        'the input, options, and actions, and press Enter or Space on a '
        'focused button. The same simulation or focused action runs and its '
        'result appears in the panel. Enter does not bypass validation or an '
        'unavailable control, and FSA simulation has no cancel shortcut while '
        'it is running. Continue with Focus navigation or Simulation limits.',
    keywords: ['simulation', 'Enter', 'Space', 'Tab', 'input'],
  ),
  HelpTopicIds.shortcutsDialogsAndForms: HelpNodeCopy(
    title: 'Dialogs and forms',
    body: 'Dialog and form shortcuts confirm, cancel, or move through an '
        'active editor. Use them in transition editors, the keyboard-shortcuts '
        'dialog, and other controls that expose standard keyboard actions. '
        'Press Enter or Numpad Enter to submit or activate, Escape to cancel, '
        'Tab for the next field, and Shift+Tab for the previous field. A valid '
        'form submits and a canceled overlay closes without applying its '
        'pending edit. Required fields still block an invalid transition, and '
        'the exact Enter action belongs to the focused control. Continue with '
        'Cancel and close or Focus navigation.',
    keywords: ['dialog', 'form', 'Enter', 'Escape', 'Tab', 'submit'],
  ),
  HelpTopicIds.shortcutsFocusNavigation: HelpNodeCopy(
    title: 'Focus navigation',
    body: 'Keyboard focus identifies which control receives the next keyboard '
        'action. Use focus navigation when a pointer or touch gesture is not '
        'convenient. Press Tab to follow the current reading or explicit form '
        'order, Shift+Tab to move backward, and Enter or Space to activate the '
        'focused button. The focus indicator moves between available actions '
        'and fields without changing the automaton by itself. Hidden or '
        'disabled controls are not useful destinations, and canvas letter '
        'shortcuts pause while an editable text field has focus. Continue with '
        'Dialogs and forms or Canvas shortcuts.',
    keywords: ['focus', 'Tab', 'Shift Tab', 'Enter', 'Space', 'keyboard'],
  ),
  HelpTopicIds.shortcutsPlatformModifiers: HelpNodeCopy(
    title: 'Platform modifiers',
    body: 'Modifier shortcuts have equivalent Control and Command variants '
        'where the canvas registers both. Check this topic when moving between '
        'Windows, Linux, the web, macOS, iPadOS, or iOS with a physical '
        'keyboard. Use Ctrl+Z, Ctrl+Y, or Ctrl+Shift+Z on Control-oriented '
        'keyboards and Cmd+Z, Cmd+Y, or Cmd+Shift+Z on Apple platforms. The '
        'matching canvas history command runs without changing the command '
        'meaning. These shortcuts require a physical keyboard, the editable '
        'canvas to own the action, and no text field to be consuming the key. '
        'Continue with Canvas shortcuts.',
    keywords: ['Ctrl', 'Cmd', 'Command', 'Apple', 'physical keyboard'],
  ),
  HelpTopicIds.shortcutsCancelAndClose: HelpNodeCopy(
    title: 'Cancel and close',
    body: 'Escape cancels the keyboard context that currently owns the key. '
        'Use it to leave a transition editor, close a shortcuts dialog, or '
        'return an editable canvas to selection mode. Press Escape once while '
        'focus remains inside that editor, dialog, or canvas. Pending editor '
        'changes are discarded, the shortcuts dialog closes, or the canvas '
        'clears its transition source and selects the selection tool. Escape '
        'does not promise to leave the Help page or cancel every running '
        'algorithm, because those surfaces have their own actions. Continue '
        'with Dialogs and forms.',
    keywords: ['Escape', 'cancel', 'close', 'selection mode', 'dialog'],
  ),
  'troubleshooting': HelpNodeCopy(
    title: 'Troubleshooting',
    keywords: ['troubleshooting', 'error', 'recovery', 'validation'],
  ),
  HelpTopicIds.troubleshootingInvalidAutomata: HelpNodeCopy(
    title: 'Invalid automata',
    body: 'An invalid automaton is missing required structure or contains a '
        'transition the current operation cannot use. Open this topic when a '
        'simulation or algorithm is disabled or returns a validation message. '
        'Read the workspace status, add one initial state, add an accepting '
        'state when the operation requires one, and repair incomplete or '
        'conflicting transitions. Validation updates as the graph changes and '
        'the command becomes usable when its own requirements are met. Some '
        'analyses impose stricter conditions than editing, so follow the '
        'specific message instead of assuming every nonempty graph is valid. '
        'Continue with Missing state markers or Nondeterminism.',
    keywords: ['invalid automaton', 'validation', 'initial state', 'error'],
  ),
  HelpTopicIds.troubleshootingGrammarInput: HelpNodeCopy(
    title: 'Grammar input errors',
    body: 'Grammar input errors identify a production or grammar field that '
        'cannot form the requested grammar. Use this topic when a production '
        'row shows an error or parsing and conversions reject the model. Keep '
        'one nonterminal on the left, enter valid symbols or alternatives on '
        'the right, use λ or ε for the empty word, and select a start symbol '
        'that the grammar declares. Correct rows remain in the editor and the '
        'status or command result reports whether the grammar can proceed. '
        'Empty productions, undeclared symbols, and algorithm-specific forms '
        'such as CNF can still require another correction. Continue with '
        'Production validation or Parser strategies.',
    keywords: ['grammar error', 'production', 'start symbol', 'lambda'],
  ),
  HelpTopicIds.troubleshootingRegexInput: HelpNodeCopy(
    title: 'Regular-expression input errors',
    body: 'A regular-expression diagnostic points to syntax that the current '
        'parser cannot accept. Use this topic when validation marks the '
        'expression invalid or conversion and testing controls stay '
        'unavailable. Read the diagnostic position, close groups and character '
        'classes, complete escapes, and remove misplaced binary or postfix '
        'operators; supply an alphabet when a wildcard or complemented '
        'shortcut needs one. A corrected expression becomes valid and enables '
        'the operations whose other inputs are ready. An empty expression is '
        'invalid, while ε represents the empty word and a typed λ is a literal '
        'symbol. Continue with Regex input and validation.',
    keywords: ['regex error', 'diagnostic', 'syntax', 'alphabet', 'epsilon'],
  ),
  HelpTopicIds.troubleshootingSimulationLimits: HelpNodeCopy(
    title: 'Simulation limits',
    body: 'Simulation limits stop a search that takes too long or explores too '
        'many configurations. Use this topic after a timeout, configuration '
        'limit, or loop-like result. Shorten the input, remove unnecessary '
        'branches or loops, and try a deterministic equivalent when the '
        'language permits it; if the app itself is slow, reduce very large '
        'automata or simplify dense transition graphs. FSA, grammar, PDA, and '
        'TM screen runs use a '
        '5-second timeout; PDA and nondeterministic TM searches also cap '
        'exploration at 100,000 configurations, and deterministic TM execution '
        'stops after 10,000 steps. The app returns a bounded failure instead of '
        'continuing indefinitely. A timeout does not prove rejection, so '
        'inspect the model before changing the expected language. Continue '
        'with Nondeterminism or the current workspace simulation topic.',
    keywords: ['timeout', '5 seconds', 'configuration limit', 'loop'],
  ),
  HelpTopicIds.troubleshootingParserStrategies: HelpNodeCopy(
    title: 'Parser strategies',
    body: 'Parser strategies use different algorithms and grammar '
        'requirements to test a string. Use this topic when one strategy is '
        'unavailable, times out, or disagrees with an assumption about the '
        'grammar form. Start with Automatic (Earley) for general parsing, try '
        'Brute force for a small grammar, or choose CYK '
        '(Cocke-Younger-Kasami) when its table and steps are useful. The panel '
        'returns acceptance, diagnostics, and any available derivation or '
        'steps. LL(1) is available for conflict-free predictive grammars; LR '
        'remains unavailable. Every strategy still has a five-second bound. '
        'Continue with the parser topic for the selected strategy.',
    keywords: [
      'parser',
      'Automatic (Earley)',
      'Brute force',
      'CYK',
      'LL',
      'LR'
    ],
  ),
  HelpTopicIds.troubleshootingFileImportExport: HelpNodeCopy(
    title: 'File import and export',
    body: 'File errors occur when a chosen file or action does not match the '
        'current workspace and platform. Use this topic when loading fails, an '
        'export action is absent, or the platform picker returns no file. Open '
        'the matching workspace, choose one of its visible Load, Save, Export, '
        'or Download actions, and retry with a supported file that is not '
        'corrupted. A '
        'successful import replaces the current model and a successful export '
        'creates the format named by the action. PDA and TM currently expose '
        'SVG export rather than JFLAP or JSON load/save, web actions download '
        'files, and canceling a picker leaves the model unchanged. Continue '
        'with Files and examples for the current workspace.',
    keywords: ['file error', 'import', 'export', 'JFLAP', 'SVG', 'download'],
  ),
  HelpTopicIds.troubleshootingMissingStateMarkers: HelpNodeCopy(
    title: 'Missing state markers',
    body: 'State markers tell an automaton where execution starts and which '
        'states accept. Use this topic when validation reports no initial '
        'state, no accepting state, or more than one start marker. Select a '
        'state, enable Initial state on exactly one state, and enable Accepting '
        'state on each intended final state. The canvas draws the markers and '
        'validation recalculates immediately. Some analyses do not require an '
        'accepting state, but simulations always need a usable initial state '
        'and acceptance results depend on the workspace semantics. Continue '
        'with Invalid automata or States.',
    keywords: ['initial state', 'accepting state', 'marker', 'validation'],
  ),
  HelpTopicIds.troubleshootingNondeterminism: HelpNodeCopy(
    title: 'Unexpected nondeterminism',
    body: 'Nondeterminism means more than one next configuration can apply '
        'from the same current situation. Use this topic when an operation '
        'requires a DFA or when the determinism indicator reports conflicts. '
        'Inspect highlighted or reported transitions, remove an unintended ε '
        'move or duplicate input choice, or convert an NFA to a DFA when '
        'appropriate. The indicator updates and deterministic-only commands '
        'become available after all relevant conflicts are removed. PDA and TM '
        'transitions include stack or read conditions, so equal-looking graph '
        'edges are not the only possible source of branching. Continue with '
        'Determinism and validation or the workspace determinism analysis.',
    keywords: ['nondeterminism', 'DFA', 'NFA', 'epsilon', 'conflict'],
  ),
  HelpTopicIds.troubleshootingLostCanvasView: HelpNodeCopy(
    title: 'Lost canvas view',
    body: 'A lost canvas view means the model still exists but zoom or pan has '
        'moved it outside the useful viewport. Use this topic when the canvas '
        'looks empty or states are too small to select. Choose Fit to content '
        'to frame all current states, then use Reset view if you want the '
        'default zoom and origin; zoom buttons and pinch gestures can refine '
        'the result. Only the viewport changes and the graph data remains '
        'untouched. An empty graph has nothing to fit, and fitting does not '
        'rearrange overlapping states. Continue with the workspace viewport '
        'topic.',
    keywords: ['Fit to content', 'Reset view', 'zoom', 'pan', 'empty canvas'],
  ),
  'about': HelpNodeCopy(
    title: 'About',
    keywords: ['about', 'project', 'licenses', 'credits'],
  ),
  HelpTopicIds.aboutDeveloperAndProject: HelpNodeCopy(
    title: 'Developer and project',
    body: 'Turing Lab is developed by Thales Matheus Mendonça Santos. Use this '
        'topic to identify the project and find its public source repository. '
        'Open Licenses, then use the Project repository control to open '
        'https://github.com/ThalesMMS/Turing-Lab. The link leaves the app for '
        'the platform browser when the platform can open it. Network access or '
        'a missing browser association '
        'can prevent the repository from opening without changing local work. '
        'Continue with Licenses or Acknowledgments.',
    keywords: ['developer', 'Thales', 'repository', 'GitHub', 'Turing-Lab'],
  ),
  HelpTopicIds.aboutLicenses: HelpNodeCopy(
    title: 'Licenses',
    body: 'Turing Lab is a Flutter reimplementation inspired by and compatible '
        'with JFLAP, not an official JFLAP release. Use this topic to inspect '
        'the terms and notices bundled with the app. Expand Apache License '
        '2.0 for original Turing Lab Flutter code, JFLAP 7.1 License for '
        'JFLAP-derived portions, GraphView (MIT License), Apple Platform '
        'Third-Party Notices for the vendored GraphView fork and Apple plugin '
        'dependencies, or Package licenses reported by Flutter. Each '
        'control loads or opens the corresponding included license source. '
        'Bundled text can report a load error, and package licenses are '
        'separate from the four included text assets. Continue with '
        'Acknowledgments or Distribution.',
    keywords: ['license', 'Apache License 2.0', 'JFLAP 7.1 License', 'MIT'],
  ),
  HelpTopicIds.aboutAcknowledgments: HelpNodeCopy(
    title: 'Acknowledgments',
    body: 'The acknowledgments credit the people and projects whose work is '
        'represented in Turing Lab. Use this topic for the JFLAP and GraphView '
        'attributions that accompany the license notices. It names Susan H. '
        'Rodger of Duke University; Thomas Finley, Ryan Cavalcante, Stephen '
        'Reading, Bart Bressler, Jinghui Lim, Chris Morgan, Kyung Min (Jason) '
        'Lee, Jonathan Su, and Henry Qin; and GraphView author Nabil Mosharraf. '
        'The original project is linked as http://www.jflap.org and the '
        'maintained GraphView fork remains under the MIT license. These credits '
        'do not make Turing Lab an official JFLAP release. Continue with '
        'Licenses or Distribution.',
    keywords: ['Susan Rodger', 'Duke University', 'JFLAP Team', 'GraphView'],
  ),
  HelpTopicIds.aboutDistribution: HelpNodeCopy(
    title: 'Distribution',
    body: 'Distribution describes how this build is offered while it contains '
        'JFLAP-derived material. Consult it before describing or redistributing '
        'the application. Turing Lab is distributed as a free, non-monetized '
        'educational app while it includes that material, alongside the '
        'licenses and notices named in this Help catalog. Users receive the '
        'application under those stated project and third-party terms. Free '
        'distribution does not replace any Apache, JFLAP, MIT, package, or '
        'platform notice. Continue with Licenses.',
    keywords: ['distribution', 'free', 'non-monetized', 'educational app'],
  ),
});
