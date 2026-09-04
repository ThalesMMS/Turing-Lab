import '../core/constants/help_topic_ids.dart';
import 'help_catalog_copy.dart';

final _documentNotesBlocks = <HelpContentBlock>[
  const HelpHeadingBlock('Add and manage a document note'),
  HelpOrderedStepsBlock([
    'Open Document notes from the canvas document actions, or expand Document notes when the page shows that section. Select Add note.',
    'Enter Note text and choose a Style. Leave Attachment set to None for a free note. To follow an item, choose State, Transition, Production, or Table cell and enter its Target ID. Select Save changes.',
    'Use Search notes to find text or target IDs. Select a note to edit it. Note actions provides Duplicate and Delete. Undo note change and Redo note change apply only to note edits.',
    'Drag, collapse, or resize a note on an automaton canvas. Document exports always preserve notes. Turn on Include notes in visual exports to add them to SVG and PNG.',
  ]),
  const HelpCalloutBlock(
    'Notes do not change the formal model, simulation, conversion, or acceptance. Text such as ε, λ, q₀, and A → a remains literal note content. Links and HTML are not interpreted.',
  ),
];

final _multipleInputBatchBlocks = <HelpContentBlock>[
  const HelpHeadingBlock('Run several inputs against one model'),
  HelpOrderedStepsBlock([
    'Open Batch execution in the simulation area. In Inputs, one case per line, enter cases directly, select Import TXT/CSV, or set Max length and Max cases before Generate words. Use ε for the empty word.',
    'Open Limits and execution settings. Choose Tokenization and the required limits, then select Run batch. Select Cancel batch or press Escape to request cancellation.',
    'Filter or sort the results, open a retained trace when available, and use Compare model only to compare these cases. Export the finished report with Export JSON or Export CSV.',
  ]),
  const HelpCalloutBlock(
    'Cancelled, timed-out, and bounded cases without a decision are not acceptance or rejection. A comparison can expose a difference in the tested cases, but no difference in a finite batch does not prove equivalence. Keep formal symbols unchanged.',
  ),
];

final _suggestedSimulationBlocks = <HelpContentBlock>[
  const HelpHeadingBlock('Load an example and try its input'),
  HelpOrderedStepsBlock([
    'Open Algorithms & Examples. Find an example card that lists Suggested simulation or Suggested simulations, then review the available description, learning objective, and limitation.',
    'Keep the suggested input exactly as shown. Select the example card or Load example to replace the current formal model with the bundled example.',
    'Close the examples surface, enter the suggestion in the workspace simulation, test, or derivation input, and run it. Loading the example does not fill the input or start the run.',
  ]),
  const HelpCalloutBlock(
    'Each suggestion is checked against its bundled example and should be accepted, derived, or completed while that example remains unchanged. One successful run does not prove every property of the model or establish language equivalence. Spaces can mark token boundaries, and formal inputs are not translated. L-system examples do not show simulation suggestions.',
  ),
];

final _automatonFragmentImportBlocks = <HelpContentBlock>[
  const HelpHeadingBlock('Clone a compatible automaton fragment'),
  HelpOrderedStepsBlock([
    'In an FSA, PDA, or TM editor, select Import automaton in the canvas document actions and choose a file for the same graph model.',
    'In Preview automaton import, choose States to import. A transition is cloned only when both endpoint states are selected. Set the Insertion anchor, then resolve any initial-state or PDA configuration choice shown.',
    'Read Source fidelity and Exact changes. Select Apply only when no blocking diagnostic remains, or select Cancel to leave the current document unchanged.',
  ]),
  const HelpCalloutBlock(
    'This action makes a disconnected structural copy with new IDs. It does not connect the fragment, replace the document, perform an algebraic operation, or prove language equivalence. Symbols such as ε, q₀, Z₀, and □ remain formal data and are not translated.',
  ),
];

final _settingsBlocks = <HelpContentBlock>[
  const HelpHeadingBlock('Tune Turing Lab for your workspace'),
  HelpOrderedStepsBlock([
    'Open Settings from the Home app bar. Under Theme Mode, choose System, Light, or Dark. Under App Language, choose English or Português.',
    'In Canvas, toggle Show Grid and Show Coordinates, then adjust Grid Size, Node Size, and Font Size. In General, toggle Auto Save and Show Tooltips.',
    'Select Save Settings to persist the current choices. Select Reset to Defaults to write the default settings, or open About Turing Lab for product and credit information.',
  ]),
  const HelpCalloutBlock(
    'Changing App Language applies immediately and attempts to save the new choice. If persistence fails, the page restores the previous value and shows an error. Reset to Defaults restores automatic platform-language resolution. These preferences affect presentation and saving behavior only; they do not edit formal models, symbols, or inputs.',
  ),
];

final _interoperabilityReviewBlocks = <HelpContentBlock>[
  const HelpHeadingBlock('Review a file exchange before committing it'),
  HelpOrderedStepsBlock([
    'When a Load, Save, or Export action opens Review import or Review export, check File, Type, Format, Version, and Fidelity before continuing.',
    'Treat Exact as a fully supported representation, Normalized as a supported representation whose spelling or structure was canonicalized, and Data loss as a transaction that omits information. Expand Field-level report and read each preserved, normalized, or omitted field and its source location.',
    'Select Replace document or Export file only after the report matches your intent. Select Import with data loss or Export with data loss only when you accept the listed omissions; select Cancel to leave the current document unchanged.',
  ]),
  const HelpCalloutBlock(
    'A fidelity review describes the codec transaction, not the language recognized by the document. It does not translate formal symbols or establish language equivalence. If the operation fails, read whether the document is unsupported, ambiguous, malformed, over a resource limit, or affected by an internal failure before retrying with a supported file.',
  ),
];

final _manualConversionBlocks = <HelpContentBlock>[
  const HelpHeadingBlock('Practice a conversion step by step'),
  HelpOrderedStepsBlock([
    'Open Algorithms & Examples and select Practice FA to Regex, Practice FA to Regular Grammar, or Practice Regular Grammar to FA. In the Regex workspace, select Practice Regex to FA.',
    'Read Source and the numbered instruction under Learner construction. Build the requested item, then select Check step. A valid step advances the progress bar. Use Hint for guidance, Reveal step to insert the expected step, and Undo or Redo to move through accepted actions.',
    'Use Compare to read the evidence recorded for the latest validated step. Select Restart to clear the actions for the current source. If editing the source invalidates the session, select Restart from edited source or Branch from edited source; both start at step 1 for the edited revision, while Branch records the invalidated session as its parent.',
    'After Construction complete appears, select Open result. If the destination editor already has content, select Replace to load the result or Cancel to keep the current destination and return to the completed construction.',
  ]),
  const HelpCalloutBlock(
    'Close leaves the saved progress on this device; it is not a discard action. Structural validation checks the requested construction shape, and bounded evidence covers only its displayed bounds. Treat language equivalence as established only when Compare reports Exact equivalence. Formal symbols such as ε, λ, ∅, q₀, Z₀, and □ remain model data.',
  ),
];

final _pumpingEnvironmentChoiceBlocks = <HelpContentBlock>[
  const HelpHeadingBlock('Choose the proof environment'),
  HelpOrderedStepsBlock([
    'When the legacy Pumping Lemma route opens this screen, read the distinction between Regular pumping and Context-free pumping. Choose the environment that matches the theorem and language family you are studying.',
    'Choose Regular pumping for the regular-language game. It uses a pumping length p, a witness string, an xyz decomposition with |xy| ≤ p and |y| > 0, and a pumping exponent. Choose Context-free pumping for the context-free game; its decomposition and proof constraints differ: w = uvxyz, |vxy| ≤ p, and |vy| > 0.',
    'After you choose an environment, the app replaces this chooser with that workspace. Start the game, read the theorem panel, and use the Help and Progress controls in the selected workspace. Open the environment chooser again through app navigation when you need to switch theorem environments.',
  ]),
  const HelpCalloutBlock(
    'Each environment keeps its own session and progress. A regular decomposition cannot be submitted to the context-free environment, and neither game decides regularity or non-regularity automatically. Use the theorem and quantifier order as the proof boundary; game feedback is guided practice.',
  ),
];

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

final _languageComparisonResultsBlocks = <HelpContentBlock>[
  const HelpHeadingBlock('Read a language comparison result'),
  HelpOrderedStepsBlock([
    'Open Algorithms & Examples. Turn on Step-by-Step Mode if you want the comparison trace, then select Compare Equivalence and choose the second automaton file.',
    'Read the status first. If it is NOT EQUIVALENT, read Distinguishing String Found; ε means that the empty string is accepted by only one automaton.',
    'Use Statistics and the read-only Current Automaton and Compared Automaton diagrams to confirm which models were compared. Expand Product Automaton when it is available.',
    'If you enabled Step-by-Step Mode, expand Algorithm Steps and use Previous step and Next step to follow alphabet normalization, determinization, product construction, and the search for a distinguishing string.',
  ]),
  const HelpCalloutBlock(
    'EQUIVALENT and NOT EQUIVALENT are completed verdicts. Inconclusive within limits and Analysis failed do not decide equivalence. Closing the result does not change either automaton.',
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

final _lr1TeachingBlocks = <HelpContentBlock>[
  const HelpHeadingBlock('Study a canonical LR(1) parse'),
  HelpOrderedStepsBlock([
    'Start with a valid grammar and a Test String. Select Canonical LR(1) and Parse String. A conflict-free table is required for a completed shift-reduce execution; invalid grammar, tokenization failure, conflicts, and resource bounds are reported in the result.',
    'In Canonical collection, choose a state chip. Compare Grammar with its LR(1) items, viable prefix, and outgoing transitions. The selected state follows the cell and step you inspect.',
    'Read the ACTION / GOTO table and select a cell. In Shift-reduce execution, use Reset execution, Previous step, Play execution, Pause execution, and Next step to follow state and symbol stacks, remaining input, lookahead, reductions, explanations, and the partial derivation tree.',
  ]),
  const HelpCalloutBlock(
    'Construction and execution are read-only views of the current grammar and parser result. Conflicts keep all actions and source items and show a witness prefix, but block parsing. A completed parse decides only the entered string; it does not prove language equivalence. If the grammar or input changes, parse again to replace stale workspace state.',
  ),
];

final _parseTableTeachingBlocks = <HelpContentBlock>[
  const HelpHeadingBlock('Practice a generated parse table'),
  HelpOrderedStepsBlock([
    'Open the parse-table teaching workspace after Grammar Analysis builds an LL(1) table or the parser produces a canonical LR(1) table. Read the row and column shown for each cell before entering an answer.',
    'Turn on Teaching mode and edit Your entry. Type a production ID, shift/reduce action, or GOTO state. In a conflict cell, use a generated action chip when you want to choose one of the competing actions. Keep generated answers visible for comparison, or hide them before attempting the cell.',
    'Use Undo and Redo while revising. Read the live message under each cell: a correct entry is accepted, a conflict choice identifies the selected action, an empty generated cell stays empty, and an incorrect entry remains a diagnostic.',
  ]),
  const HelpCalloutBlock(
    'The generated table is a read-only reference. Teaching edits do not change the grammar, parser, or generated answers. A changed source grammar invalidates the session, and an invalid saved exercise must be restarted from the current table.',
  ),
];

final _grammarBatchParsingBlocks = <HelpContentBlock>[
  const HelpHeadingBlock('Run several grammar parses'),
  HelpOrderedStepsBlock([
    'Expand Batch parsing below Parse Results. Enter one case per line, use Add case or Import TXT/CSV, or set Max length and Max cases and select Generate words. Use ε for the empty word; in Explicit tokens mode, separate declared terminal tokens with spaces.',
    'Open Limits and execution settings. Choose Strategy and Tokenization, set the step, configuration, timeout, and trace limits, choose trace retention and concurrency, and decide whether to stop after the first non-success outcome. Select Run batch or press Ctrl+Enter; Escape requests cancellation.',
    'Filter or sort the results, rerun a case with trace, inspect a retained trace, remove cases, and export the completed report as JSON or CSV. The same panel can run Automatic (Earley), Brute force, CYK, LL(1), or LR(1), so keep the selected strategy with the report when comparing runs.',
  ]),
  const HelpCalloutBlock(
    'Each case receives its own outcome: accepted and rejected are decisions, while conflicts, invalid input or grammar, cancellation, timeouts, and step or configuration bounds remain diagnostics or inconclusive. A finite batch does not prove language equivalence. The runner accepts at most 10,000 cases and caps retained traces at 10,000 steps; changing the grammar clears stale results. Reports preserve formal inputs, the strategy, limits, and model revision.',
  ),
];

final _userControlledDerivationBlocks = <HelpContentBlock>[
  const HelpHeadingBlock('Build a derivation yourself'),
  HelpOrderedStepsBlock([
    'Enter Test String, then select Start user-controlled derivation.',
    'Before the first move, choose Leftmost, Rightmost, or Any occurrence. Select an applicable production and its exact Position, inspect Move preview, then select Apply this move.',
    'Use Undo move, Redo move, Branch here, or Restart to revise the history. Request bounded hint can preview a suggested move, and Current derivation tree shows the partial tree.',
  ]),
  const HelpCalloutBlock(
    'A local dead end or a bounded hint with no suggestion does not prove non-membership. Changing the grammar or target invalidates the session; start a new session for the current source.',
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

final _variableDependencyGraphBlocks = <HelpContentBlock>[
  const HelpHeadingBlock('Inspect dependencies and recursion'),
  HelpOrderedStepsBlock([
    'Open Grammar Analysis and select Variable dependency graph.',
    'Choose Direct occurrence, Left corner, or Nullable-aware left corner under Dependency mode. Change Graph layout or use the fit and zoom controls as needed.',
    'Select a variable, dependency edge, or recursion witness to inspect reachability and exact production provenance. Use Export SVG or Export PNG to save the current graph.',
  ]),
  const HelpCalloutBlock(
    'Reachability, productivity, and recursion witnesses describe variable dependencies; they do not prove that the grammar is ambiguous. If the source grammar changes, reopen the graph to analyze the current revision.',
  ),
];

final _cfgToPdaLlLrBlocks = <HelpContentBlock>[
  const HelpHeadingBlock('Preview an LL or LR stack construction'),
  HelpOrderedStepsBlock([
    'Open Algorithms. Under Conversions, select CFG to PDA (LL) construction or CFG to PDA (LR) construction.',
    'Review Construction assumptions, then select Construction steps to highlight the source productions, generated states and transitions, and LR cells when applicable.',
    'Optionally select Run sampled check under Bounded differential evidence. Select Open in PDA editor only when you want to replace the current PDA with the preview.',
  ]),
  const HelpCalloutBlock(
    'LL(1) conflicts block the LL construction, and canonical LR(1) conflicts block the LR construction. Finite samples can find a mismatch but cannot prove language equivalence. A source edit invalidates the preview.',
  ),
];

final _grammarNormalizationPracticeBlocks = <HelpContentBlock>[
  const HelpHeadingBlock('Practice the canonical CNF stages'),
  HelpOrderedStepsBlock([
    'Open Algorithms, then Practice grammar normalization for a grammar with productions.',
    'Work through Remove lambda, Remove unit productions, Remove useless productions, and Finish CNF. Enter one production per line as A -> symbol symbol, using ε for an empty right side.',
    'Select Check step, revise the reported missing or unexpected productions, and use Compare with reference only after making your own attempt.',
  ]),
  const HelpCalloutBlock(
    'The checker matches the canonical production set generated for each stage. A mismatch does not prove that your grammar is not language-equivalent, and a result from a later stage is reported as out of order.',
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

final _tmMultiTapeBlocks = <HelpContentBlock>[
  const HelpHeadingBlock('Inspect one synchronized multi-tape run'),
  HelpOrderedStepsBlock([
    'Set the tape count above one and give every transition one read, write, and direction operation for each tape.',
    'Simulate an input. In Synchronized multi-tape trace, select a step to inspect the single atomic transition and its recorded configuration.',
    'Expand each tape to compare its head, operation, and nearby cells. Then read the maximum visited span and nonblank-cell metrics for each tape and for the simultaneous total.',
  ]),
  const HelpCalloutBlock(
    'All operations in one trace row happen in the same machine step. The reported maxima describe only this bounded run; they do not prove space complexity or behavior for other inputs.',
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

final _tmBuildingBlockBlocks = <HelpContentBlock>[
  const HelpHeadingBlock('Compose a machine from reusable blocks'),
  HelpOrderedStepsBlock([
    'Open Building blocks, then create a named definition or load the reusable-block example to inspect a complete project.',
    'Use Insert to place an invocation on the root canvas; rename or duplicate definitions in the library and use the breadcrumbs to inspect nested references.',
    'Run the TM, then inspect Enter, Transition, and Return steps together with the call stack and shared tape state.',
  ]),
  const HelpCalloutBlock(
    'Every block shares the root machine tape count, blank symbol, and tapes. Missing references or direct or indirect recursion make the project invalid, and deleting a referenced definition requires explicitly detaching its invocations.',
  ),
];

final _tmBuildingBlockLibraryBlocks = <HelpContentBlock>[
  const HelpHeadingBlock('Manage the building-block library'),
  HelpOrderedStepsBlock([
    'Open Building block library and select Create block. Enter a name and confirm with Create block. A new definition starts with one initial state and inherits the root machine\'s tape count, tape alphabet, and blank symbol.',
    'Select a block to open its details. Use Insert on root canvas to add an invocation anchor to the root graph, Rename to change its display name, or Duplicate to create an independent definition. Use the Root machine breadcrumb or a nested block breadcrumb to return to an earlier level.',
    'Use Undo and Redo for library edits. If a block is referenced, Delete opens an explicit resolution dialog. Choose Detach and delete only when you want each invocation converted to an ordinary state; cancel leaves the definition and its references unchanged.',
  ]),
  const HelpCalloutBlock(
    'The library stores versioned definitions and invocation references, not translated copies of a machine. A block keeps the project tape contract, and diagnostics such as missing references, revision mismatches, tape-count differences, or recursive dependencies must be resolved before trusting a run.',
  ),
];

final _mealyEditingBlocks = <HelpContentBlock>[
  const HelpHeadingBlock('Build a Mealy machine'),
  HelpOrderedStepsBlock([
    'Add states on the canvas, then edit one state and mark it as the initial state.',
    'Add a transition and enter one input symbol from the input alphabet.',
    'Enter each output token on its own line, or leave the output empty, then save the transition.',
  ]),
  const HelpCalloutBlock(
    'Mealy output belongs to transitions. States are never final or accepting, and a complete deterministic machine needs one transition for every state and input symbol.',
  ),
];

final _mooreEditingBlocks = <HelpContentBlock>[
  const HelpHeadingBlock('Build a Moore machine'),
  HelpOrderedStepsBlock([
    'Add states on the canvas, then edit one state and mark it as the initial state.',
    'Enter each state output token on its own line, or leave the state output empty.',
    'Add transitions with one input symbol each; Moore transitions do not have output fields.',
  ]),
  const HelpCalloutBlock(
    'Moore output belongs to states. A run emits the initial state output before reading input, and states are never final or accepting.',
  ),
];

final _transducerCanvasBlocks = <HelpContentBlock>[
  const HelpHeadingBlock('Prepare the machine and edit the canvas'),
  HelpOrderedStepsBlock([
    'Open Machine details and enter one input or output symbol per line.',
    'Select Apply alphabets before using those symbols in states or transitions.',
    'Use the canvas tools to select, add, move, connect, or edit states and transitions; use the viewport controls to zoom, fit, or rearrange the graph.',
  ]),
  const HelpCalloutBlock(
    'Machine details reports invalid, nondeterministic, or partial structures. Resolve its diagnostics before relying on simulation or exact comparison.',
  ),
];

final _transducerCanvasEditingGestureBlocks = <HelpContentBlock>[
  const HelpHeadingBlock('Place and edit graph elements'),
  HelpOrderedStepsBlock([
    'Select Add state, then select an empty point on the canvas. The toolbar action only turns placement mode on or off; each selection on the empty canvas places one state.',
    'Select Add transition, then select the source state and the target state. Select the same state twice for a self-loop. Complete the Mealy or Moore transition editor and select Save.',
    'Select Select to drag a state. Double-tap a state to edit it. In any tool, you can also long-press or use the secondary pointer button on a state, transition label, or transition curve to open its editor.',
  ]),
  const HelpCalloutBlock(
    'Add state and Add transition stay active so you can repeat the action. Select the active tool again or select Select to leave that mode. Panning, pinch zoom, state dragging, and context gestures remain available while a placement tool is active.',
  ),
];

final _transducerSimulationBlocks = <HelpContentBlock>[
  const HelpHeadingBlock('Run and inspect a transducer'),
  HelpOrderedStepsBlock([
    'Open Simulation, enter one input token per line, and set a nonnegative maximum step count.',
    'Select Run and read the execution result and accumulated output.',
    'Select trace steps to inspect consumed input and emitted output; use View on Canvas when that action is available.',
  ]),
  const HelpCalloutBlock(
    'A bounded, cancelled, invalid, or incomplete run is not a successful result. Editing or replacing the machine clears playback that belongs to the previous revision.',
  ),
];

final _transducerCompactCanvasPlaybackBlocks = <HelpContentBlock>[
  const HelpHeadingBlock('Move a compact trace onto the canvas'),
  HelpOrderedStepsBlock([
    'On a compact layout, open Simulation, enter one input token per line, and select Run. View on Canvas appears after a result records at least one trace step.',
    'Select View on Canvas. The simulation sheet closes and the playback bar opens on the first step. The canvas highlights that step\'s target state and transition, while the input strip marks consumed, current, and pending tokens.',
    'Use Previous Step, Play, Pause, or Next Step to move through the same retained trace. Select Close to remove the playback bar and its highlights.',
  ]),
  const HelpCalloutBlock(
    'View on Canvas is available only in compact layouts; wide layouts keep the trace in the Simulation panel. Clearing, editing, or replacing the machine discards stale playback. Changing to a wide layout also closes the compact playback bar.',
  ),
];

final _transducerBatchBlocks = <HelpContentBlock>[
  const HelpHeadingBlock('Run a batch or compare outputs'),
  HelpOrderedStepsBlock([
    'Open Algorithms & Examples, then Batch, and enter one JSON token array per line.',
    'Run the batch and inspect the status and output recorded for each input.',
    'To compare machines, choose an example, select Exact or Bounded mode, and review any witness and differing outputs.',
  ]),
  const HelpCalloutBlock(
    'Exact comparison requires compatible, complete deterministic machines. A bounded comparison can find a difference, but no difference within the chosen limit remains inconclusive.',
  ),
];

final _transducerFilesBlocks = <HelpContentBlock>[
  const HelpHeadingBlock('Load examples and exchange files'),
  HelpOrderedStepsBlock([
    'Open Examples and review the description and suggested simulations before loading a machine.',
    'Open Machine details, then Files, to import or export JFLAP XML or versioned Turing Lab JSON.',
    'Review fidelity information before replacing the current machine, or export the canvas as SVG or PNG when you need an image.',
  ]),
  const HelpCalloutBlock(
    'Loading an example or importing a file replaces the current machine. Formal symbols, token boundaries, and user-authored labels are preserved rather than translated.',
  ),
];

final _unrestrictedGrammarEditingBlocks = <HelpContentBlock>[
  const HelpHeadingBlock('Edit and classify the grammar'),
  HelpOrderedStepsBlock([
    'Open Edit grammar. Enter the terminal and nonterminal sets as JSON string arrays, then choose a declared nonterminal as the start symbol.',
    'Enter each production side as a JSON array. Prefix nonterminals with n: and terminals with t: so token boundaries stay explicit.',
    'Add or save the production, use Undo or Redo when needed, and read the classification and production diagnostics.',
  ]),
  const HelpCalloutBlock(
    'Classification describes the productions as written. It does not prove the smallest grammar class that can generate the same language.',
  ),
];

final _unrestrictedGrammarDerivationBlocks = <HelpContentBlock>[
  const HelpHeadingBlock('Explore derivations and dependencies'),
  HelpOrderedStepsBlock([
    'Open Bounded derivation. Enter the target word as a JSON array of terminal symbols and set the maximum expanded forms.',
    'Search for a derivation, cancel if needed, and inspect the outcome and recorded production positions.',
    'Start a manual derivation to choose each replacement, or open the variable dependency graph under Algorithms & Examples.',
  ]),
  const HelpCalloutBlock(
    'A derivation witness proves that the grammar generates that word. Reaching a bound is inconclusive and does not prove that the word is outside the language.',
  ),
];

final _unrestrictedGrammarFilesBlocks = <HelpContentBlock>[
  const HelpHeadingBlock('Load examples and exchange grammars'),
  HelpOrderedStepsBlock([
    'Open Algorithms & Examples and review an example before loading it into the editor.',
    'Open Information, then Files, to import or export JFLAP XML or versioned Turing Lab JSON.',
    'When the grammar came from a Turing machine conversion, inspect the mapped production provenance in Information.',
  ]),
  const HelpCalloutBlock(
    'Loading an example or importing a file replaces the current grammar. Review fidelity information first, and keep formal symbols and user-authored names unchanged across locales.',
  ),
];

final _tmToUnrestrictedGrammarBlocks = <HelpContentBlock>[
  const HelpHeadingBlock('Review a TM-to-unrestricted-grammar construction'),
  HelpOrderedStepsBlock([
    'Open Algorithms and choose TM to unrestricted grammar construction. Wait for the preview to finish, then read Construction assumptions and every diagnostic before using the generated grammar.',
    'Use a single-tape TM with a valid initial state, a tape alphabet that contains each input symbol, a blank symbol that is not an input symbol, and no inline building blocks. The construction assumes a two-way-infinite tape and immediate acceptance on entering a final state; a machine without a final state produces an empty-language warning, while multi-tape or building-block models are blocked.',
    'Filter generated rules by Production family. Select a production to inspect its formal rule, invariant, source state or transition, and exact tape operation. Run the sampled check for finite-sample evidence, then select Copy report to preserve the structured report or Open in unrestricted grammar editor to replace the destination grammar.',
  ]),
  const HelpCalloutBlock(
    'The preview stops at the default limit of 50,000 unique productions. A completed result keeps formal tape and grammar symbols as atomic tokens and records production provenance in the structured report; an unsupported model, invalid output, construction limit, or changed source revision leaves the preview blocked. Matching finite samples are evidence, not a proof of language equivalence. Opening the result replaces the current unrestricted grammar and can be undone.',
  ),
];

final _lSystemDefinitionBlocks = <HelpContentBlock>[
  const HelpHeadingBlock('Define the rewriting system'),
  HelpOrderedStepsBlock([
    'Enter the axiom as space-separated tokens and write one parallel production per line.',
    'Use X -> Y for a basic rule, or add left and right contexts with < and > and a numeric weight with @.',
    'Map tokens to turtle commands, set the iteration and drawing values, then select Apply and expand.',
  ]),
  const HelpCalloutBlock(
    'Every production step reads the same source generation. A random seed makes weighted choices repeatable, while parametric expressions remain unsupported.',
  ),
];

final _lSystemGenerationBlocks = <HelpContentBlock>[
  const HelpHeadingBlock('Inspect generations and turtle geometry'),
  HelpOrderedStepsBlock([
    'Apply the definition and read the expansion status, generated tokens, and localized geometry description.',
    'Use the generation slider or playback control to inspect earlier generations.',
    'Zoom or reset the turtle view, then export the current geometry as SVG or PNG when those controls are enabled.',
  ]),
  const HelpCalloutBlock(
    'Growth, memory, elapsed-time, and segment limits can stop expansion or rendering. A bounded result is incomplete, and reduced-motion settings disable automatic playback.',
  ),
];

final _lSystemFilesBlocks = <HelpContentBlock>[
  const HelpHeadingBlock('Load examples and exchange L-systems'),
  HelpOrderedStepsBlock([
    'Open Algorithms & Examples and read an example summary, objective, limitation, and visual description before selecting it.',
    'Open Files to import or export JFLAP XML or versioned Turing Lab JSON.',
    'After loading or importing, apply the definition and check the generated tokens and turtle view before exporting an image.',
  ]),
  const HelpCalloutBlock(
    'Loading an example or importing a file replaces the current document. Review fidelity information, and do not translate formal tokens or command names.',
  ),
];

final enHelpCatalogCopy = HelpCatalogCopy({
  HelpTopicIds.gettingStarted: HelpNodeCopy(
    title: 'Getting started',
    keywords: ['start', 'guide', 'navigation'],
  ),
  HelpTopicIds.gettingStartedQuickStart: HelpNodeCopy(
    title: 'Quick start',
    body:
        'Quick start is the shortest path from the Home page to a tested '
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
    body:
        'The main navigation switches among FSA, Grammar, PDA, TM, Regex, '
        'Regular pumping, Context-free pumping, Mealy, Moore, Unrestricted '
        'grammar, and L-system workspaces. Use it when you want to change the '
        'kind of language model you are editing or studying. Select a '
        'destination in the Home page navigation, bottom navigation, or the '
        'available section control for your screen size. Turing Lab opens that '
        'workspace and keeps its editing tools close to the canvas or input '
        'area. Labels and placement adapt to phone, tablet, and desktop '
        'layouts, so use the visible label rather than a fixed position. Read '
        'Choosing a workspace before creating a new model.',
    keywords: [
      'navigation',
      'FSA',
      'Grammar',
      'PDA',
      'TM',
      'Regex',
      'Regular pumping',
      'Context-free pumping',
      'Mealy',
      'Moore',
      'Unrestricted grammar',
      'L-system',
    ],
  ),
  HelpTopicIds.gettingStartedChooseWorkspace: HelpNodeCopy(
    title: 'Choose a workspace',
    body:
        'Each workspace represents a different formal-language model or '
        'learning activity. Use FSA for regular languages and finite memory, '
        'Grammar for production rules, PDA for stack memory, TM for tape '
        'computation, Regex for regular-expression work, and Regular or '
        'Context-free pumping for proof practice. Choose Mealy when output '
        'belongs to transitions, Moore when output belongs to states, '
        'Unrestricted grammar for phrase-structure productions, or L-system '
        'for parallel rewriting and turtle rendering. Select the matching card '
        'or navigation label on the Home page. The chosen editor opens with '
        'its own controls, simulation, algorithms, and theory help. '
        'Conversions can move a result to another workspace, but unsupported '
        'structures cannot be represented in a weaker model. Continue with the '
        'editor overview for the workspace you selected.',
    keywords: [
      'workspace',
      'formal language',
      'automaton',
      'grammar',
      'regex',
      'Mealy',
      'Moore',
      'Unrestricted grammar',
      'L-system',
    ],
  ),
  HelpTopicIds.gettingStartedSettings: HelpNodeCopy(
    blocks: _settingsBlocks,
    title: 'Configure settings',
    body:
        'Settings is the Home app bar route for appearance, language, canvas, '
        'and general preferences. Use it to tune the interface without '
        'changing a formal document. Choose a theme and app language, adjust '
        'canvas controls and sizes, manage autosave and tooltips, then save '
        'the choices or restore defaults. Continue with Navigate Turing Lab '
        'to find the route again.',
    keywords: [
      'settings',
      'theme',
      'language',
      'canvas',
      'grid',
      'coordinates',
      'auto save',
      'tooltips',
    ],
  ),
  HelpTopicIds.gettingStartedFilesAndExamples: HelpNodeCopy(
    title: 'Files and examples',
    body:
        'Files and examples let you begin from saved or bundled material '
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
  HelpTopicIds.gettingStartedSuggestedSimulations: HelpNodeCopy(
    blocks: _suggestedSimulationBlocks,
    title: 'Try a suggested simulation',
    body:
        'Simulation-capable example cards show a verified input under '
        'Suggested simulation or Suggested simulations. Open Algorithms & '
        'Examples, review the example description and limits, and preserve the '
        'input exactly as shown. Select the card or Load example to load its '
        'bundled model, which replaces the current formal model. Then enter the '
        'suggestion in the workspace simulation, test, or derivation input and '
        'run it. Loading an example does not fill the input or start the run. '
        'The unchanged example should accept, derive, or complete its suggestion, '
        'but one successful run does not prove every property or language '
        'equivalence. Spaces can mark token boundaries, and changing the '
        'interface language does not translate formal input. L-system examples '
        'do not show simulation suggestions.',
    keywords: [
      'Suggested simulation',
      'Suggested simulations',
      'Algorithms & Examples',
      'Load example',
      'verified input',
    ],
  ),
  HelpTopicIds.gettingStartedImportAutomatonFragments: HelpNodeCopy(
    blocks: _automatonFragmentImportBlocks,
    title: 'Import and clone automaton fragments',
    body:
        'Import automaton copies part or all of a compatible automaton into '
        'the current FSA, PDA, or TM document. It does not replace the current '
        'document. Select Import automaton in the canvas document actions and '
        'choose a file that decodes as the same graph model. In Preview '
        'automaton import, read Source fidelity and any decoder diagnostics. '
        'Under States to import, keep only the states you need. A source '
        'transition is cloned only when both of its endpoint states are '
        'selected. Insertion anchor X and Y place the cloned states, shifting '
        'them further when needed to avoid overlap. If both documents have an '
        'initial state, choose Keep current initial state or Use imported '
        'initial state. For a PDA, differing acceptance modes or initial stack '
        'symbols block Apply until you explicitly choose the destination '
        'setting. TMs with different tape counts or blank symbols cannot be '
        'combined by this action. Exact changes lists the states, transitions, '
        'notes, reusable TM blocks, alphabet additions, and configuration '
        'effects that will be applied. Each destination input, stack, or tape '
        'alphabet absorbs the complete corresponding source set, even '
        'when you select only some states. Select Apply to commit one '
        'structural import. Before Apply, Cancel leaves both documents '
        'unchanged; applying never changes the source file. The imported '
        'elements receive new IDs and remain disconnected from the existing '
        'graph unless their own selected transitions connect them. This flow '
        'does not open or replace a document, create connector transitions, or '
        'run union, intersection, or another algebraic operation. The result '
        'can recognize a different language. Import success does not establish '
        'equivalence between the source, destination, or combined automata. '
        'Formal symbols and labels such as ε, q₀, Z₀, and □ are cloned as model '
        'data and are not translated with the interface.',
    keywords: [
      'Import automaton',
      'Preview automaton import',
      'States to import',
      'Insertion anchor',
      'Exact changes',
      'clone fragment',
    ],
  ),
  HelpTopicIds.gettingStartedManualConversions: HelpNodeCopy(
    blocks: _manualConversionBlocks,
    title: 'Practice manual conversions',
    body:
        'Manual construction lets you build a conversion beside its source. '
        'Start it with Practice FA to Regex, Practice FA to Regular Grammar, '
        'Practice Regular Grammar to FA, or Practice Regex to FA. The Source '
        'pane stays visible while Learner construction presents one numbered '
        'requirement at a time. Build the requested state, transition, '
        'production, or expression and select Check step. The workspace '
        'advances only after that requirement passes its implemented '
        'validation. Hint shows guidance and source provenance. Reveal step '
        'applies the expected payload, marks the action as revealed, and '
        'advances the session. Undo and Redo move through accepted or revealed '
        'actions. Restart clears those actions for the same source revision. '
        'Progress is saved on this device, so Close exits the full-screen '
        'workspace without discarding it. Editing the source changes its '
        'revision and invalidates the open or restored session. While it is '
        'invalidated, step controls are unavailable. Restart from edited '
        'source starts the same session again at step 1 using the edited '
        'document. Branch from edited source also starts at step 1, with a new '
        'session whose parent points to the invalidated session and cursor; it '
        'does not carry accepted actions into the edited revision. Compare '
        'shows the latest recorded evidence as Exact equivalence, Structural '
        'validation, or Bounded evidence. Structural validation checks the '
        'requested correspondence or construction shape. Bounded evidence '
        'covers only the reported bounds. Neither label is a general language-'
        'equivalence proof. Rely on language equivalence only when Compare '
        'explicitly reports Exact equivalence. Construction complete means '
        'that every required step has passed or been revealed. Select Open '
        'result to load the learner artifact into its destination editor. If '
        'that editor already contains a document, Replace confirms the '
        'replacement. Cancel keeps the current destination and returns to the '
        'completed construction. Symbols such as ε, λ, ∅, q₀, Z₀, and □ stay '
        'formal model data and are not translated.',
    keywords: [
      'manual construction',
      'Practice FA to Regex',
      'Practice Regex to FA',
      'Check step',
      'Branch from edited source',
      'Open result',
    ],
  ),
  HelpTopicIds.gettingStartedDocumentNotes: HelpNodeCopy(
    blocks: _documentNotesBlocks,
    title: 'Work with document notes',
    body:
        'Document notes are non-semantic annotations stored with the current '
        'document. Open Document notes and select Add note. In Edit note, enter '
        'Note text. You can use **bold**, _italic_, or `code`; links and HTML are '
        'not interpreted. Choose a Style: Note, Information, Warning, Question, '
        'or To do. Leave Attachment set to None for a free note, or choose State, '
        'Transition, Production, or Table cell and enter its Target ID. Select '
        'Save changes. Search notes matches note text and target IDs. Select a '
        'note to edit it, or open Note actions to Duplicate or '
        'Delete it. Undo note change and Redo note change keep a separate note '
        'history. On an automaton canvas, drag, collapse, or resize a note card. '
        'Document exports always preserve notes. Turn on Include notes in visual '
        'exports to add them to SVG and PNG. Notes do not change the formal model, '
        'simulation, conversion, or acceptance. Formal content such as ε, λ, q₀, '
        'and A → a remains literal note text and is not translated.',
    keywords: [
      'Document notes',
      'Add note',
      'Search notes',
      'Attachment',
      'Target ID',
      'Include notes in visual exports',
    ],
  ),
  HelpTopicIds.gettingStartedFirstInput: HelpNodeCopy(
    title: 'Test your first input',
    body:
        'A simulation checks how the current model processes one input '
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
  HelpTopicIds.gettingStartedMultipleInputBatches: HelpNodeCopy(
    blocks: _multipleInputBatchBlocks,
    title: 'Run multiple-input batches',
    body:
        'Multiple-input batches run the current formal model against a list '
        'while keeping each case and result separate. Open Batch execution in '
        'the simulation area and add one case per line. Raw string preserves '
        'the entered text, Unicode symbols reads Unicode scalar values, and '
        'Explicit tokens uses spaces as token boundaries. Use ε for the empty '
        'word. Import TXT/CSV or Generate words can fill the list. Max length '
        'and Max cases bound generated inputs. The Limits and execution '
        'settings panel controls the strategy, step, configuration and time '
        'limits, trace retention, and concurrency. Select Run batch to start. '
        'Selecting Cancel batch or pressing Escape requests cancellation, so '
        'a cancelled or bounded outcome is '
        'not an acceptance or rejection result. Each result records its '
        'outcome and available metrics. Compare model checks only the finite '
        'cases in the current report. Finding no difference does not prove '
        'general equivalence. Export JSON and Export CSV preserve the report. '
        'Changing an input or execution setting invalidates finished results. '
        'Formal strings and tokens are model data; changing the interface '
        'language does not translate or rewrite them. Continue with Test your '
        'first input, Simulation limits, or Batch, comparison, and examples.',
    keywords: [
      'Batch execution',
      'multiple inputs',
      'Run batch',
      'Cancel batch',
      'Tokenization',
      'Compare model',
      'Export JSON',
      'Export CSV',
    ],
  ),
  HelpTopicIds.gettingStartedFindHelp: HelpNodeCopy(
    title: 'Find help and shortcuts',
    body:
        'Help combines instructions, current-screen guidance, theory, and '
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
    body:
        'The finite automata workspace combines the state canvas, simulation '
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
    body:
        'Select mode lets you inspect, move, edit, or delete existing canvas '
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
    body:
        'States represent the finite memory positions of an automaton. Use '
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
      'delete',
    ],
  ),
  HelpTopicIds.fsaEditorTransitions: HelpNodeCopy(
    title: 'Add and edit transitions',
    body:
        'Transitions describe which state follows for an input symbol. Use '
        'them to define the behavior of the automaton for every relevant '
        'symbol. Choose Add transition, select the source and target states, '
        'then enter a symbol or choose the ε option; select an edge to edit or '
        'delete it. The canvas draws a directed labeled edge and validation '
        'recalculates the alphabet and determinism. A DFA cannot have ε '
        'transitions or two destinations for the same state and symbol, while '
        'an NFA can. Continue with Determinism and validation.',
    keywords: ['transition', 'Add transition', 'symbol', 'lambda', 'edge'],
  ),
  HelpTopicIds.fsaEditorDeterminism: HelpNodeCopy(
    title: 'Determinism and validation',
    body:
        'The determinism badge and validation status summarize whether the '
        'current automaton satisfies key structural rules. Use them before '
        'simulation and before running an algorithm that requires a DFA. '
        'Inspect the status text and open the determinism details to locate '
        'missing initial or accepting states, ε transitions, or competing '
        'transitions. The indicators update as you edit and distinguish a DFA '
        'from an NFA. A badge is diagnostic rather than a repair command, and '
        'some algorithms remain disabled or report an error until the model is '
        'valid. Continue with DFA, NFA, or transition editing.',
    keywords: ['determinism', 'validation', 'DFA', 'NFA', 'diagnostics'],
  ),
  HelpTopicIds.fsaEditorHistoryAndClear: HelpNodeCopy(
    title: 'Undo, redo, and clear',
    body:
        'History controls reverse or restore canvas edits, while Clear '
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
    body:
        'Zoom and pan change the view without changing the automaton. Use '
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
    body:
        'Fit to content frames the complete automaton, while Reset view '
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
    body:
        'Auto Layout rearranges the current states into a circular layout. '
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
    body:
        'The simulation input is the string the automaton will try to '
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
      'epsilon',
    ],
  ),
  HelpTopicIds.fsaEditorSimulationResultsAndPlayback: HelpNodeCopy(
    blocks: _fsaSimulationBlocks,
    title: 'Read results and play back steps',
    body:
        'Simulation results explain whether the input was Accepted or '
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
    body:
        'The Algorithms panel converts, combines, simplifies, and analyzes '
        'finite automata. Use it after building or loading an automaton when '
        'you need an equivalent form or a derived language. Open Algorithms '
        'and select Regex to NFA, NFA to DFA, Remove ε-transitions, Minimize '
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
    body:
        'Regex to NFA builds a nondeterministic automaton for a regular '
        'expression. Use it when an expression is easier to write than the '
        'equivalent state graph. In Algorithms, enter a valid value in Regular '
        'Expression and activate the arrow beside Regex to NFA. The generated '
        'NFA becomes available on the canvas with states and transitions for '
        'the same language. Invalid syntax or an empty expression prevents '
        'conversion, and the result may contain ε transitions. Continue with '
        'NFA to DFA or the NFA theory topic.',
    keywords: ['Regex to NFA', 'regular expression', 'conversion', 'lambda'],
  ),
  HelpTopicIds.fsaEditorAlgorithmsNfaToDfa: HelpNodeCopy(
    blocks: _fsaAlgorithmBlocks,
    title: 'NFA to DFA',
    body:
        'NFA to DFA applies subset construction to create a deterministic '
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
    title: 'Remove ε-transitions',
    body:
        'Remove ε-transitions creates an equivalent automaton without '
        'epsilon moves. Use it before operations that require every transition '
        'to consume a symbol. Open Algorithms and select Remove ε-transitions '
        'for the current automaton. The result propagates reachability and '
        'acceptance through epsilon closures while removing ε edges. The '
        'automaton needs a valid initial structure, and the transformed graph '
        'can contain more symbol transitions. Continue with Epsilon closure or '
        'NFA to DFA.',
    keywords: ['Remove lambda', 'epsilon', 'lambda transition', 'closure'],
  ),
  HelpTopicIds.fsaEditorAlgorithmsMinimizeDfa: HelpNodeCopy(
    blocks: _fsaAlgorithmBlocks,
    title: 'Minimize DFA',
    body:
        'Minimize DFA merges indistinguishable states in a deterministic '
        'automaton. Use it to obtain a smaller DFA that accepts the same '
        'language. Make the current automaton deterministic, open Algorithms, '
        'and select Minimize DFA. The result removes unreachable distinctions '
        'and combines equivalent state classes. ε transitions, nondeterminism, '
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
        'and free of ε transitions, and an already complete DFA may change '
        'little or not at all. Continue with Complement DFA.',
    keywords: ['Complete DFA', 'trap state', 'total transition', 'alphabet'],
  ),
  HelpTopicIds.fsaEditorAlgorithmsComplementDfa: HelpNodeCopy(
    blocks: _fsaAlgorithmBlocks,
    title: 'Complement DFA',
    body:
        'Complement DFA builds an automaton that accepts exactly the strings '
        'the original DFA rejects over its alphabet. Use it to negate a regular '
        'language. Open Algorithms and select Complement DFA; the command '
        'completes missing transitions internally before changing acceptance. '
        'The result swaps accepting and non-accepting states without leaving '
        'undefined input cases. The source must be deterministic and free of ε '
        'transitions, but it does not need manual completion first. Continue '
        'with Complete DFA or Equivalence.',
    keywords: [
      'Complement DFA',
      'negation',
      'accepting states',
      'complete DFA',
    ],
  ),
  HelpTopicIds.fsaEditorAlgorithmsUnion: HelpNodeCopy(
    blocks: _fsaAlgorithmBlocks,
    title: 'Union of DFAs',
    body:
        'Union of DFAs accepts strings accepted by either of two automata. '
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
    body:
        'Intersection of DFAs accepts strings accepted by both of two '
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
    body:
        'Difference of DFAs accepts strings in the current DFA but not in a '
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
    body:
        'Prefix Closure creates an automaton that accepts every prefix of a '
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
    body:
        'Suffix Closure creates an automaton that accepts every suffix of a '
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
    body:
        'FA to Regex derives a regular expression for the language of the '
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
    body:
        'FSA to Grammar converts the automaton into an equivalent '
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
    body:
        'Compare Equivalence checks whether two finite automata accept the '
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
      'file',
    ],
  ),
  HelpTopicIds.fsaEditorAlgorithmsComparisonResults: HelpNodeCopy(
    blocks: _languageComparisonResultsBlocks,
    title: 'Read Language Comparison Results',
    body:
        'The Language Comparison result separates a completed equivalence '
        'verdict from an inconclusive or failed analysis. It also records the '
        'exact automata used, a distinguishing string when the languages '
        'differ, and optional product and algorithm-step views.',
    keywords: [
      'Language Comparison',
      'Distinguishing String Found',
      'Product Automaton',
      'Algorithm Steps',
      'inconclusive',
    ],
  ),
  HelpTopicIds.fsaEditorAlgorithmsStepMode: HelpNodeCopy(
    blocks: _fsaAlgorithmBlocks,
    title: 'Step-by-Step Mode',
    body:
        'Step-by-Step Mode records intermediate stages of supported '
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
    body:
        'FSA file actions import, save, or render automata, while bundled '
        'examples provide ready-made models. Open Algorithms and select AFD - '
        'Termina com A, AFD - Binário divisível por 3, AFD - Paridade AB, '
        'AFD - Contém AB, or AFNε - A ou AB. The selected example replaces the '
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
    body:
        'A DFA is a finite automaton with exactly one next state for each '
        'state and input symbol. Use the model for regular languages whose next '
        'step is unambiguous. In the FSA editor, create one initial state, mark '
        'accepting states, and give each state at most one transition per '
        'symbol with no ε transitions. A run follows one path and accepts only '
        'if it ends in an accepting state after consuming all input. Missing '
        'transitions make a DFA incomplete, while duplicate symbol choices make '
        'it nondeterministic. Continue with NFA or Complete DFA.',
    keywords: [
      'DFA',
      'deterministic',
      'regular language',
      'transition function',
    ],
  ),
  HelpTopicIds.fsaTheoryNfa: HelpNodeCopy(
    title: 'Nondeterministic finite automata (NFA)',
    body:
        'An NFA may have several next states for one symbol and may include '
        'epsilon moves. Use it when branching or a compact construction makes '
        'a regular language easier to express. In the editor, add competing '
        'transitions or ε transitions and simulate an input across the '
        'available paths. The NFA accepts when at least one path consumes the '
        'whole input and reaches an accepting state. Branching can enlarge '
        'traces and searches, but it does not make the recognized language more '
        'powerful than a DFA. Continue with NFA to DFA or Epsilon transitions.',
    keywords: ['NFA', 'nondeterministic', 'branching', 'epsilon'],
  ),
  HelpTopicIds.fsaTheoryStates: HelpNodeCopy(
    title: 'States',
    body:
        'A state records the finite amount of history the automaton needs at '
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
    body:
        'A transition is a directed rule from one state to another, normally '
        'labeled by the input it consumes. Use transitions to define every '
        'legal next step of a run. Connect source and target states and assign '
        'a symbol, or assign ε for an epsilon move in an NFA. Simulation follows '
        'matching edges and changes the active state. A symbol transition '
        'cannot match a different input symbol, and competing matches introduce '
        'nondeterminism. Continue with Alphabet and acceptance or Epsilon '
        'transitions.',
    keywords: ['transitions', 'edge', 'symbol', 'next state'],
  ),
  HelpTopicIds.fsaTheoryAlphabetAndAcceptance: HelpNodeCopy(
    title: 'Alphabet and acceptance',
    body:
        'The alphabet is the set of input symbols on consuming transitions, '
        'and acceptance is the condition for membership in the automaton language. '
        'Use both concepts to define what inputs are meaningful and which are '
        'successful. Label transitions with alphabet symbols, start at the '
        'initial state, consume the full string, and check whether a path ends '
        'in an accepting state. Accepted means at least one valid complete path '
        'exists; Rejected means none does. ε is not an alphabet symbol, and '
        'stopping early in an accepting state does not accept unconsumed input. '
        'Continue with DFA, NFA, or simulation results.',
    keywords: ['alphabet', 'acceptance', 'Accepted', 'Rejected', 'language'],
  ),
  HelpTopicIds.fsaTheoryEpsilon: HelpNodeCopy(
    title: 'Epsilon and ε-transitions',
    body:
        'Epsilon, shown as ε, represents the empty string, and an '
        'ε-transition changes state without consuming input. Use epsilon moves '
        'in an NFA when a construction needs optional or spontaneous branching. '
        'Choose the ε option while editing a transition and follow those edges '
        'before or between symbol moves during analysis. All states reachable '
        'through such moves become possible current states. A DFA cannot '
        'contain ε transitions, and cycles of epsilon moves must not be treated '
        'as consumed input. Continue with Epsilon closure or Remove '
        'ε-transitions.',
    keywords: ['epsilon', 'lambda', 'empty string', 'lambda transition'],
  ),
  HelpTopicIds.fsaTheoryEpsilonClosure: HelpNodeCopy(
    title: 'Epsilon closure',
    body:
        'The epsilon closure of a state or state set contains every state '
        'reachable using only ε transitions, including the starting states. Use '
        'it to understand NFA simulation, epsilon removal, and subset '
        'construction. Begin with the current set and repeatedly follow all '
        'outgoing ε edges until no new state appears. The complete reached set '
        'participates before the next symbol is consumed. Forgetting the '
        'starting state or stopping after one ε edge produces an incorrect '
        'closure. Continue with Remove ε-transitions or NFA to DFA.',
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
    body:
        'Regular languages remain regular under operations such as union, '
        'intersection, difference, complement, prefix closure, and suffix '
        'closure. Use this fact to build a finite automaton for a language '
        'derived from existing regular languages. Choose the corresponding '
        'Algorithms command and provide a second DFA when the operation is '
        'binary. The generated automaton recognizes the mathematically derived '
        'language. Binary operations depend on operand order where applicable '
        'and require valid deterministic inputs. Mathematical complement '
        'assumes a total transition function, but the current Complement DFA '
        'command completes missing transitions internally and requires only a '
        'valid deterministic input without ε transitions. Continue with the '
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
    body:
        'The Grammar workspace combines a production editor, the Grammar '
        'Parser, and Grammar Analysis. Use it to define a grammar, test a '
        'string, transform rules, or convert the model. Enter Grammar Name and '
        'Start Symbol, add rules with Variable and Production, '
        'then open Parse or Algorithms. The provider infers '
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
    body:
        'Grammar symbols are classified as non-terminals or terminals, and '
        'Start Symbol identifies where derivations begin. Use these fields '
        'before adding rules that the parser or analyzers must interpret. Enter '
        'a Grammar Name, set Start Symbol, and use one symbol such as S on each '
        'Variable; uppercase single letters on right sides are '
        'inferred as non-terminals. The built grammar collects left-side '
        'symbols as non-terminals and the remaining right-side symbols as '
        'terminals. An empty start-symbol edit is ignored, while a start symbol '
        'must ultimately belong to the non-terminal set; continue with '
        'Production rows and alternatives.',
    keywords: ['Start Symbol', 'terminal', 'non-terminal', 'Grammar Name'],
  ),
  HelpTopicIds.grammarEditorProductionRowsAndAlternatives: HelpNodeCopy(
    title: 'Production rows and alternatives',
    body:
        'Enter one left side and one or more right-side alternatives separated '
        'by |, such as S with aS | b. Select Add once; the grammar stores each '
        'alternative as an independent production and groups rules with the '
        'same left side in the workspace. Use the group menu to Edit '
        'alternatives, Delete group, Move up, or Move down. Drag only the '
        'group handle to reorder with a pointer or touch; the complete group '
        'moves while its alternative order stays unchanged. The menu actions '
        'provide the keyboard and screen-reader path. Editing replaces the '
        'complete group, and deletion asks for confirmation. A compact value such as aA is '
        'split into characters, while whitespace separates multi-character '
        'symbols; when any alternative uses spaces the whole field is read '
        'that way, so num | id | ( Expr ) keeps num and id whole. To remove '
        'ambiguity, type a symbol in the Symbol field and press Nonterminal '
        'or Terminal; the chips below show nonterminals in yellow and '
        'terminals in green, and tapping a chip switches its kind. '
        'Type \\| to enter a literal pipe terminal. Native files '
        'preserve this order; JFLAP export may move start-symbol rules first '
        'and reports that interoperability normalization. Continue with '
        'Empty productions using ε.',
    keywords: [
      'Add',
      'Edit alternatives',
      'Delete group',
      'Move up',
      'drag',
      '|',
      '\\|',
    ],
  ),
  HelpTopicIds.grammarEditorProductionLambda: HelpNodeCopy(
    title: 'Empty productions with ε',
    body:
        'An ε-production derives the empty string. Use it when a '
        'non-terminal may disappear or the grammar must accept the empty '
        'input. In Production, select Insert ε or type ε, then '
        'add the rule. The editor stores the right '
        'side as empty and displays it as ε. The empty marker must be the only '
        'right-side symbol, so mixing it with another symbol or entering more '
        'than one marker produces a validation message. Continue with '
        'Production validation.',
    keywords: ['lambda', 'epsilon', 'Insert ε', 'empty string'],
  ),
  HelpTopicIds.grammarEditorProductionValidation: HelpNodeCopy(
    title: 'Production validation and clearing',
    body:
        'Production validation keeps malformed editor rows from entering the '
        'grammar. Use it when Add or Update does nothing or a later analysis '
        'reports validation errors. Supply both sides, put exactly one symbol '
        'on the left, and give every | separator a non-empty alternative on '
        'the right. Each alternative must contain ordinary symbols or one '
        'empty-string marker. The complete batch is validated before anything '
        'is added; existing alternatives are skipped with feedback. Use Clear '
        'to remove every production after confirming. Inline messages identify '
        'the failing side, and Clear offers Undo in its confirmation feedback. '
        'The editor validates rule shape rather than proving language '
        'properties. Continue with Parser workflow.',
    keywords: ['validation', 'Clear', 'Undo', 'error', 'rule shape'],
  ),
  'grammar.editor.parser': HelpNodeCopy(
    title: 'Grammar parser',
    keywords: ['parser', 'string', 'Earley', 'CYK'],
  ),
  HelpTopicIds.grammarEditorParserWorkflow: HelpNodeCopy(
    blocks: _grammarParserBlocks,
    title: 'Parse a string',
    body:
        'The Grammar Parser tests whether the current grammar derives a Test '
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
  HelpTopicIds.grammarEditorParserUserControlledDerivation: HelpNodeCopy(
    blocks: _userControlledDerivationBlocks,
    title: 'User-controlled derivation',
    body:
        'Start user-controlled derivation opens a manual derivation session '
        'for the current grammar and Test String. Before applying a move, '
        'choose Leftmost, Rightmost, or Any occurrence; the mode cannot change '
        'after the first move unless you restart. Select a production and its '
        'exact Position, inspect Move preview, and select Apply this move. The '
        'workspace records the sentential form and derivation history, supports '
        'Undo move, Redo move, Branch here, Restart, a bounded hint search, and '
        'Copy structured derivation, and shows the current derivation tree when '
        'one is available. A local dead end and a hint search that reaches a '
        'limit are inconclusive. Changing the grammar or target invalidates '
        'the session and requires Start a new session.',
    keywords: [
      'user-controlled derivation',
      'Leftmost',
      'Rightmost',
      'Any occurrence',
      'bounded hint',
    ],
  ),
  HelpTopicIds.grammarEditorParserAutomaticEarley: HelpNodeCopy(
    blocks: _grammarParserBlocks,
    title: 'Automatic parsing with Earley',
    body:
        'Automatic (Earley) is the available general CFG recognition option. '
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
    title: 'Bounded brute-force parsing',
    body:
        'Brute force performs deterministic breadth-first derivation search '
        'for a context-free grammar. Choose leftmost, rightmost, or all-position '
        'expansion, set depth, frontier, witness, and time limits, then enter a '
        'Test String and activate Parse String. Accepted runs retain shortest '
        'production-ID witnesses and derivation trees; ambiguous grammars may '
        'show several witnesses. Rejected means the finite frontier was '
        'exhausted, while Inconclusive within limits means a bound stopped the '
        'search. Use the statistics, derivation steps, cancellation, and JSON '
        'report to inspect the run. Unrestricted grammars use their separate '
        'search semantics and do not receive CFG pruning rules.',
    keywords: [
      'Brute force',
      'breadth-first search',
      'bounded search',
      'derivation tree',
      'witness',
    ],
  ),
  HelpTopicIds.grammarEditorParserCyk: HelpNodeCopy(
    blocks: _grammarParserBlocks,
    title: 'CYK parsing',
    body:
        'CYK (Cocke-Younger-Kasami) recognizes a string with a dynamic '
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
    body:
        'LL(1) parsing chooses one production from the current non-terminal '
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
    title: 'Canonical LR(1) parser',
    body:
        'Canonical LR(1) analyzes a context-free grammar from the bottom up. '
        'Select Canonical LR(1), enter a Test String, and select Parse String. '
        'The workspace synchronizes productions, canonical item sets, GOTO '
        'transitions, the ACTION/GOTO table, state and symbol stacks, remaining '
        'input, reductions, and the partial parse tree. Select a state or table '
        'cell to inspect it, or use the execution controls to step, play, pause, '
        'and reset. A cell keeps every competing action and its source items; '
        'shift/reduce or reduce/reduce conflicts include a viable-prefix witness '
        'and prevent execution. Construction and execution have time and '
        'resource bounds. Build Parse Table in Grammar Analysis remains the '
        'separate LL(1) predictive-table action.',
    keywords: ['LR', 'LR(1)', 'canonical', 'bottom-up', 'ACTION', 'GOTO'],
  ),
  HelpTopicIds.grammarEditorParserLr1Teaching: HelpNodeCopy(
    blocks: _lr1TeachingBlocks,
    title: 'LR(1) teaching workspace',
    body:
        'The canonical LR(1) teaching workspace combines the grammar, '
        'canonical item sets, ACTION / GOTO table, and one shift-reduce trace '
        'for the parsed input. Open Grammar Parser, choose Canonical LR(1), '
        'enter Test String, and select Parse String. After a result appears, '
        'use the workspace below Parse Results to inspect the construction and '
        'playback.',
    keywords: [
      'LR(1) teaching workspace',
      'canonical item sets',
      'ACTION / GOTO',
      'shift-reduce execution',
      'viable prefix',
      'partial derivation tree',
    ],
  ),
  HelpTopicIds.grammarEditorParserParseTableTeaching: HelpNodeCopy(
    blocks: _parseTableTeachingBlocks,
    title: 'Parse-table teaching workspace',
    body:
        'The parse-table teaching workspace lets you practice entries in a '
        'generated LL(1) predictive table or canonical LR(1) ACTION/GOTO table. '
        'Turn on Teaching mode to edit Your entry for a row and column. Enter '
        'a production ID, shift/reduce action, or GOTO state; conflict cells '
        'offer every generated action as a choice chip. Keep generated answers '
        'visible to compare your attempt, or hide them before editing. Undo and '
        'Redo revise the exercise history, and each cell reports a valid entry, '
        'valid conflict choice, empty generated cell, or incorrect entry. The '
        'generated table stays read-only, so the exercise does not change the '
        'grammar, parser, or reference answers. A source edit invalidates the '
        'session, and an invalid saved exercise must restart from the current '
        'table.',
    keywords: [
      'parse-table teaching workspace',
      'Teaching mode',
      'Your entry',
      'generated answers',
      'conflict cell',
      'ACTION/GOTO',
    ],
  ),
  HelpTopicIds.grammarEditorParserResultsAndSteps: HelpNodeCopy(
    blocks: _grammarParserBlocks,
    title: 'Results, trees, and parser steps',
    body:
        'Parse Results explains the outcome and any recorded structure from '
        'the selected parser. Use it to inspect why an input was accepted or '
        'where a rejected run stopped. Read Accepted or Rejected and Execution '
        'time; non-CYK rejection may show Farthest position, Expected symbols, '
        'and a message, while an accepted automatic or brute-force run may '
        'expand Derivation Tree. CYK Steps provides previous and next buttons, '
        'a slider, the selected step title, table highlights, and an '
        'explanation card. LL(1) Steps uses the same navigation to show stack, '
        'remaining input, lookahead, and production snapshots. Canonical LR(1) '
        'shows synchronized item sets, ACTION/GOTO cells, both stacks, and a '
        'partial parse tree. Trees are best-effort for legacy strategies; '
        'continue with Parse trees, CYK, LL(1), or LR(1).',
    keywords: [
      'Parse Results',
      'Derivation Tree',
      'CYK Steps',
      'LL(1) Steps',
      'LR(1)',
    ],
  ),
  HelpTopicIds.grammarEditorParserMultipleRuns: HelpNodeCopy(
    blocks: _grammarBatchParsingBlocks,
    title: 'Batch parsing',
    body:
        'The grammar parser batch workspace runs one selected strategy over '
        'multiple inputs while keeping each case, outcome, metric, and optional '
        'trace separate. It supports Automatic (Earley), Brute force, CYK, '
        'LL(1), and LR(1) through one bounded runner. Start with Batch parsing '
        'after opening Parser.',
    keywords: [
      'batch parsing',
      'multiple inputs',
      'Automatic (Earley)',
      'Brute force',
      'CYK',
      'LL(1)',
      'LR(1)',
      'trace retention',
    ],
  ),
  'grammar.editor.algorithms': HelpNodeCopy(
    title: 'Analysis and transformations',
    keywords: ['analysis', 'transformation', 'FIRST', 'FOLLOW'],
  ),
  HelpTopicIds.grammarEditorAlgorithms: HelpNodeCopy(
    blocks: _grammarAlgorithmBlocks,
    title: 'Grammar algorithms overview',
    body:
        'Grammar Analysis transforms rules and computes predictive-parsing '
        'data. Use it after editing a valid grammar when you need a normal '
        'form, structural rewrite, set calculation, table, or LL(1) conflict '
        'check. Choose Convert to CNF, Convert to GNF, Remove Left Recursion, '
        'Left Factor, Find First Sets, Find Follow Sets, Build Parse Table, '
        'Check Ambiguity, or Variable Dependency Graph. The graph keeps exact '
        'production and token-position provenance, switches between direct and '
        'left-corner relations, and reports reachability, productivity, SCCs, '
        'and recursion witnesses without inferring ambiguity. The panel shows a '
        'textual analysis, and CNF/GNF also '
        'show Transformation steps whose Apply action replaces the editor '
        'grammar with that step result. Actions are disabled while an analysis '
        'runs, and invalid grammars produce a validation report; open the '
        'specific algorithm topic next.',
    keywords: [
      'Grammar Analysis',
      'normal form',
      'Variable Dependency Graph',
      'SCC',
      'results',
    ],
  ),
  HelpTopicIds.grammarEditorAlgorithmsCnf: HelpNodeCopy(
    blocks: _grammarAlgorithmBlocks,
    title: 'Convert to Chomsky Normal Form',
    body:
        'Convert to CNF rewrites a CFG into Chomsky Normal Form. Use it for '
        'CYK study or when rules should have the forms A→BC or A→a, subject to '
        'the start-symbol empty-string exception. Select Convert to CNF in '
        'Grammar Analysis and inspect Transformation steps, Original Grammar, '
        'Transformed Grammar, notes, derivations, and diagnostics. Apply on a '
        'step replaces the current editor grammar with that intermediate '
        'result. Validation errors or error-severity conversion diagnostics '
        'stop the operation; continue with CNF theory or CYK.',
    keywords: ['Convert to CNF', 'Chomsky', 'A BC', 'Transformation steps'],
  ),
  HelpTopicIds.grammarEditorAlgorithmsNormalizationPractice: HelpNodeCopy(
    blocks: _grammarNormalizationPracticeBlocks,
    title: 'Practice grammar normalization',
    body:
        'Practice grammar normalization is a guided exercise for the four '
        'canonical stages used before and during CNF construction. Use it when '
        'you want to write each intermediate grammar yourself instead of only '
        'reading an automatic transformation. Open Algorithms and select '
        'Practice grammar normalization. Choose Remove lambda, Remove unit '
        'productions, Remove useless productions, or Finish CNF. Edit one '
        'production per line with -> or →, separate symbols with spaces, and '
        'use ε or an empty right side for an empty production. Check step '
        'reports syntax errors, unknown symbols, duplicates, missing rules, '
        'unexpected rules, or a later-stage answer. Undo and Redo keep the '
        'exercise history, and each stage keeps its own draft. Compare with '
        'reference reveals the read-only generated grammar. The checker '
        'compares exact production shapes with that canonical reference. It '
        'does not decide whether a different grammar generates the same '
        'language, so a failed check is not a proof of inequivalence. Continue '
        'with Convert to CNF or Chomsky Normal Form.',
    keywords: [
      'grammar normalization',
      'Practice grammar normalization',
      'Remove lambda',
      'unit productions',
      'useless productions',
      'CNF',
      'canonical reference',
    ],
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
    body:
        'Remove Left Recursion handles direct rules such as A→Aα and '
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
      'prime symbol',
    ],
  ),
  HelpTopicIds.grammarEditorAlgorithmsLeftFactor: HelpNodeCopy(
    blocks: _grammarAlgorithmBlocks,
    title: 'Left-factor productions',
    body:
        'Left Factor extracts common prefixes into new non-terminals. Use it '
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
    body:
        'FIRST(X) contains terminals that can begin strings derived from X, '
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
    body:
        'FOLLOW(A) contains terminals that may immediately follow A, with \$ '
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
    body:
        'Build Parse Table constructs the current LL(1) predictive table. '
        'Use it after checking FIRST and FOLLOW to see which production is '
        'chosen for a non-terminal and lookahead. Select Build Parse Table and '
        'read the tab-separated rows, Notes, Conflicts, and Derivations in '
        'LL(1) Parse Table Analysis. Empty cells appear as -, ε rules use '
        'FOLLOW, and multiple entries identify a conflict. Despite the button '
        'This action is LL(1) only; canonical LR(1) tables are built in the '
        'parser workspace after selecting Canonical LR(1). Continue with Check '
        'Ambiguity or predictive-parsing theory.',
    keywords: ['Build Parse Table', 'LL(1)', 'lookahead', 'conflict'],
  ),
  HelpTopicIds.grammarEditorAlgorithmsAmbiguity: HelpNodeCopy(
    blocks: _grammarAlgorithmBlocks,
    title: 'Interpret the ambiguity check',
    body:
        'Check Ambiguity is an educational LL(1) conflict check, not a '
        'general proof of ambiguity. Use it to classify whether the current '
        'predictive table has competing entries. Select Check Ambiguity and '
        'read LL(1) Classification, Notes, Conflicts, and Derivations. No '
        'conflicts yields LL(1) (no conflicts); conflicts yield Not LL(1) '
        '(conflicts). A non-LL(1) grammar can still be unambiguous and may need '
        'LR or Earley, so continue with Ambiguity theory and parse trees.',
    keywords: ['Check Ambiguity', 'LL(1)', 'conflict', 'classification'],
  ),
  HelpTopicIds.grammarEditorAlgorithmsDependencyGraph: HelpNodeCopy(
    blocks: _variableDependencyGraphBlocks,
    title: 'Variable dependency graph',
    body:
        'Variable dependency graph opens an interactive analysis of how grammar '
        'variables depend on one another. Choose Direct occurrence, Left '
        'corner, or Nullable-aware left corner under Dependency mode, then '
        'select Layered, Circular, or Grid layout and use Fit graph or the zoom '
        'controls. Summary chips identify reachable, unreachable, '
        'nonproductive, source, and sink variables and count recursive '
        'components. Select a variable for a reachability witness, an edge for '
        'the contributing production IDs and token positions, or a recursion '
        'witness for its variables, productions, and edges. Export SVG and '
        'Export PNG save the current graph. These dependency results do not '
        'prove ambiguity, and a source edit invalidates the open analysis until '
        'you reopen it.',
    keywords: [
      'Variable dependency graph',
      'left corner',
      'reachability',
      'provenance',
      'recursion witness',
    ],
  ),
  'grammar.editor.conversions': HelpNodeCopy(
    title: 'Conversions',
    keywords: ['conversion', 'FSA', 'PDA', 'Greibach'],
  ),
  HelpTopicIds.grammarEditorConversionsRightLinearToFsa: HelpNodeCopy(
    title: 'Right-linear grammar to FSA',
    body:
        'Convert Right-Linear Grammar to FSA builds an equivalent finite '
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
    body:
        'Convert Grammar to PDA (General) builds a three-state PDA from the '
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
    body:
        'Convert Grammar to PDA (Standard) applies the standard CFG-to-PDA '
        'stack construction. Use it when you want the explicitly named '
        'standard route for comparison with the other conversion controls. Add '
        'productions and select Convert Grammar to PDA (Standard). The current '
        'implementation produces the same three-state construction as General, '
        'loads it, and switches to the PDA workspace. No productions or any '
        'conversion already running disables this control. An invalid start '
        'symbol or another conversion failure does not disable a non-empty '
        'grammar in advance; it returns an error after activation. The '
        'conversion has a ten-second limit. The separate CFG to PDA (LL) and '
        'CFG to PDA (LR) actions open guided previews: LL requires a '
        'conflict-free predictive table, while LR requires a conflict-free '
        'canonical LR(1) table and shows shift/reduce provenance. Their sampled '
        'language checks are bounded evidence, not proofs. Opening the preview '
        'does not alter either editor; Open in PDA editor replaces the current '
        'PDA in one undoable action. Continue with General or Greibach '
        'conversion.',
    keywords: [
      'Convert Grammar to PDA (Standard)',
      'CFG to PDA (LL)',
      'CFG to PDA (LR)',
      'standard',
      'PDA',
    ],
  ),
  HelpTopicIds.grammarEditorConversionsPdaGreibach: HelpNodeCopy(
    title: 'Grammar to PDA through Greibach form',
    body:
        'Convert Grammar to PDA (Greibach) first converts the CFG to GNF and '
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
  HelpTopicIds.grammarEditorConversionsPdaLlLr: HelpNodeCopy(
    blocks: _cfgToPdaLlLrBlocks,
    title: 'Guided CFG to PDA construction',
    body:
        'CFG to PDA (LL) construction and CFG to PDA (LR) construction open '
        'read-only previews tied to the current grammar revision. LL builds a '
        'top-down stack machine from a conflict-free predictive table; LR '
        'builds bottom-up shift and reduction transitions from a conflict-free '
        'canonical LR(1) table. Construction assumptions and Construction '
        'steps connect source productions, generated states and transitions, '
        'and LR cells when applicable. Run sampled check compares finite inputs '
        'under displayed bounds; a mismatch is evidence of a problem, while '
        'matching samples do not prove language equivalence. Opening or '
        'canceling the preview does not change either editor. Open in PDA '
        'editor replaces the current PDA in one undoable action. LL(1) or LR(1) '
        'conflicts block the corresponding construction, and a grammar edit '
        'invalidates the open preview.',
    keywords: [
      'CFG to PDA (LL)',
      'CFG to PDA (LR)',
      'Construction steps',
      'Run sampled check',
      'Open in PDA editor',
    ],
  ),
  HelpTopicIds.grammarEditorFilesAndExamples: HelpNodeCopy(
    title: 'Grammar files and examples',
    body:
        'Grammar file actions preserve rules or produce a shareable diagram, '
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
    body:
        'A context-free grammar is a tuple of terminals, non-terminals, '
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
    body:
        'A production A→α permits non-terminal A to be replaced by symbol '
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
    body:
        'A derivation repeatedly applies productions from the start symbol '
        'until a terminal string is reached. Use it to justify membership and '
        'compare how parsers construct a result. In the parser panel, start a '
        'user-controlled derivation, choose leftmost, rightmost, or any '
        'occurrence mode, then select both a production and its exact token '
        'occurrence. Preview the replacement before applying it; undo, redo, '
        'restart, branch from history, or request a bounded search-derived '
        'hint. A reached target demonstrates membership. A local dead end or '
        'an exhausted hint limit does not prove non-membership. CFG sessions '
        'show a derivation tree; unrestricted sessions keep a token sequence '
        'instead of fabricating one. Continue with Parse trees and ambiguity.',
    keywords: [
      'derivation',
      'sentential form',
      'user controlled',
      'occurrence',
      'hint',
    ],
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
    body:
        'A grammar is ambiguous when at least one string has two distinct '
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
    body:
        'Direct left recursion begins an alternative with its own '
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
    body:
        'FIRST predicts which terminals can begin a derivation, while FOLLOW '
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
    body:
        'An LL(1) parser chooses a production from one non-terminal and one '
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
    body:
        'Chomsky Normal Form restricts ordinary CFG rules to A→BC or A→a, '
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
    body:
        'Greibach Normal Form makes each ordinary production begin with a '
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
    body:
        'Right-linear grammars and finite automata describe regular '
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
    body:
        'The PDA workspace combines a state canvas, a live stack inspector, '
        'simulation, analysis, examples, and SVG export. Use it to build or '
        'inspect a deterministic or nondeterministic pushdown automaton. Add '
        'states, mark the initial and accepting states, connect them with '
        'input/pop/push transitions, and test an input string. The canvas '
        'status reports state and transition counts plus missing markers, '
        'epsilon use, and detected conflicts. A simulation needs an initial '
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
    body:
        'Select mode is the canvas tool for moving and opening PDA states. '
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
      'accepting state',
    ],
  ),
  HelpTopicIds.pdaEditorTransitions: HelpNodeCopy(
    title: 'Add and edit PDA transitions',
    body:
        'A PDA transition combines an input symbol, a pop symbol, and a push '
        'symbol on one directed edge. Use it to say when the machine may move '
        'and how that move changes the stack. Choose Add transition, select '
        'source and target states, fill Input symbol, Pop symbol, and Push '
        'symbol, then Save; select an existing edge to edit or delete it. The '
        'canvas shows the canonical input, pop/push label and updates both '
        'alphabets. Every non-epsilon field is required, and a changed '
        'multi-character push is treated as ordered characters rather than one '
        'atomic symbol. Continue with Epsilon input, pop, and push.',
    keywords: ['PDA', 'input symbol', 'pop symbol', 'push symbol', 'edge'],
  ),
  HelpTopicIds.pdaEditorLambdaSwitches: HelpNodeCopy(
    title: 'Epsilon input, pop, and push',
    body:
        'The three epsilon switches independently make the input, pop, or push '
        'part of a PDA transition empty. Use ε-input for a move that consumes '
        'no input, ε-pop for a move that neither checks nor removes the stack '
        'top, and ε-push for a move that adds nothing. Enable ε-input, ε-pop, '
        'or ε-push beside its field and save the transition. The disabled '
        'field is cleared and the edge displays ε in that position. Leaving a '
        'non-epsilon field blank blocks Save, while epsilon moves can branch or '
        'cycle and therefore consume search limits. Continue with PDA '
        'transitions or Nondeterminism.',
    keywords: ['PDA', 'lambda', 'epsilon', 'ε-input', 'ε-pop', 'ε-push'],
  ),
  HelpTopicIds.pdaEditorHistoryAndClear: HelpNodeCopy(
    title: 'Undo, redo, and clear',
    body:
        'History controls reverse or restore recorded PDA canvas edits, '
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
    body:
        'Fit to content frames all PDA states, while Reset view restores the '
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
    body:
        'Auto Layout would rearrange state coordinates without changing PDA '
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
    body:
        'The stack inspector is the compact live view of the PDA stack. Use '
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
    body:
        'The initial stack symbol is the bottom marker placed in the PDA '
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
    body:
        'Operation Preview illustrates the stack effect of the transition '
        'currently being edited. Use it before saving a pop/push rule whose '
        'order is hard to visualize. Enter the input, pop, and push values or '
        'their epsilon switches and inspect Input, Pop, Push, and Result below '
        'the fields. A non-epsilon pop removes the displayed top, and a '
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
    body:
        'PDA Simulation searches the current automaton for a path that '
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
    body:
        'The trace records PDA configurations so you can inspect state, '
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
    body:
        'Simulation Results summarizes whether the PDA run was Accepted, '
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
    body:
        'PDA Analysis groups six controls for conversion, simplification, '
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
    body:
        'Convert to CFG constructs a context-free grammar from the current '
        'PDA. Use it to study or reuse an equivalent language in production '
        'form. Select Convert to CFG in PDA Analysis and inspect the generated '
        'start symbol, non-terminals, terminals, productions, and conversion '
        'description in the result card. Variables of the form [p,A,q] encode '
        'a state-to-state stack obligation. The PDA needs states, an initial '
        'state, at least one accepting state, and every transition must pop '
        'exactly one non-epsilon stack symbol; failure leaves the PDA unchanged. '
        'The result is displayed here rather than opening the Grammar editor. '
        'Continue with PDA and CFG.',
    keywords: ['PDA', 'Convert to CFG', 'context-free grammar', '[p,A,q]'],
  ),
  HelpTopicIds.pdaEditorAlgorithmsMinimize: HelpNodeCopy(
    blocks: _pdaAlgorithmBlocks,
    title: 'Simplify a PDA safely',
    body:
        'Simplify PDA applies reductions that preserve the active acceptance '
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
    body:
        'Check Determinism reports transition conflicts detected by the PDA '
        'editor. Use it to locate branches that share a source, input '
        'condition, and pop condition. Select Check Determinism and inspect the '
        'deterministic or NON-deterministic result, conflicting transition '
        'labels, canvas highlights, total transition count, and epsilon count. '
        'No model change is applied. The current check groups exact '
        'source/input/pop keys; it does not perform a complete formal DPDA test '
        'for every interaction between epsilon-input and consuming moves. A PDA '
        'must exist, but accepting states are not required for this report. '
        'Continue with Nondeterminism.',
    keywords: ['PDA', 'Check Determinism', 'DPDA', 'conflict', 'lambda'],
  ),
  HelpTopicIds.pdaEditorAlgorithmsReachableStates: HelpNodeCopy(
    blocks: _pdaAlgorithmBlocks,
    title: 'Find reachable states',
    body:
        'Find Reachable States classifies PDA states by graph reachability '
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
    body:
        'Language Analysis formally decides whether the language recognized '
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
      'shortest witness',
    ],
  ),
  HelpTopicIds.pdaEditorAlgorithmsStackOperations: HelpNodeCopy(
    blocks: _pdaAlgorithmBlocks,
    title: 'Analyze stack operations',
    body:
        'Stack Operations summarizes the stack labels used by PDA '
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
    body:
        'The examples and file areas provide ready-made PDAs and a visual '
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
    body:
        'A pushdown automaton is a finite-state machine augmented by an '
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
    body:
        'A PDA stack is last-in-first-out memory whose top controls which '
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
        'input symbol, pop symbol, and push symbol, and use the three epsilon '
        'switches for omitted actions. A matching move consumes its input when '
        'present, removes the required top when present, and pushes its ordered '
        'replacement. A transition cannot run when its non-epsilon input or pop '
        'condition does not match, and multiple available moves introduce '
        'nondeterminism. Continue with Epsilon switches or Nondeterminism.',
    keywords: ['PDA', 'transition', 'input', 'pop', 'push'],
  ),
  HelpTopicIds.pdaTheoryAcceptance: HelpNodeCopy(
    title: 'Acceptance criteria',
    body:
        'Acceptance defines which complete PDA configurations place an input '
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
    body:
        'A nondeterministic PDA may have several applicable moves for one '
        'configuration, including moves that consume no input. Use branching '
        'when the machine must guess a split point or choose among stack '
        'strategies, as in a palindrome recognizer. Create competing '
        'input/pop rules or epsilon paths and simulate; the search explores '
        'configurations until one accepts or all bounded alternatives end. One '
        'accepting branch makes the input Accepted. Cycles and branching can '
        'reach the five-second, 1,000-depth, or 100,000-configuration limits, '
        'and the editor\'s Check Determinism is a narrower conflict diagnostic. '
        'Continue with Check Determinism or Context-free languages.',
    keywords: ['PDA', 'NPDA', 'nondeterminism', 'branch', 'lambda'],
  ),
  HelpTopicIds.pdaTheoryContextFreeLanguages: HelpNodeCopy(
    title: 'Context-free languages',
    body:
        'Context-free languages are exactly the languages recognized by '
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
    body:
        'Nondeterministic PDAs and context-free grammars are two equivalent '
        'ways to describe context-free languages. Use conversion to relate '
        'stack behavior to productions or to inspect a generated formal model. '
        'Run Convert to CFG for a suitable PDA, or use a grammar-to-PDA command '
        'from the Grammar workspace. The PDA converter produces [p,A,q] '
        'variables and displays the generated grammar without changing '
        'workspaces. This implementation requires final-state structure and '
        'exactly one non-epsilon pop per transition, so a mathematically '
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
    body:
        'The TM workspace combines a state canvas, synchronized tape '
        'inspectors, '
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
    body:
        'States record the finite-control part of a TM, and Select lets you '
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
      'accepting state',
    ],
  ),
  HelpTopicIds.tmEditorTransitions: HelpNodeCopy(
    title: 'Add and edit transitions',
    body:
        'A TM transition chooses the next state and one atomic operation per '
        'tape. Use transitions to define what the machine does for the complete '
        'vector of symbols under its heads. Choose Add transition, select '
        'source and target states, complete '
        'the operation editor, and save; select an existing edge to edit or '
        'delete it. The canvas displays a read/write,direction label and '
        'recalculates tape symbols and nondeterministic conflicts. Empty read '
        'or write fields are rejected, and competing rules for the same state '
        'and read vector make the machine nondeterministic. Continue with Read, '
        'write, and direction.',
    keywords: [
      'TM',
      'MT',
      'Add transition',
      'edge',
      'operation',
      'nondeterminism',
    ],
  ),
  HelpTopicIds.tmEditorReadWriteAndDirection: HelpNodeCopy(
    title: 'Read, write, and direction',
    body:
        'Read symbol, Write symbol, and Direction define one operation for '
        'each tape in a TM rule. The transition matches every current cell, '
        'then writes and moves every head atomically. Enter non-empty symbols '
        'and choose Left, Right, or Stay for each tape, then select Save or '
        'press Enter; Escape cancels. The edge label shows each '
        'read/write,direction tuple and the rule is '
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
      'Right',
    ],
  ),
  HelpTopicIds.tmEditorHistoryAndClear: HelpNodeCopy(
    title: 'Undo, redo, and clear',
    body:
        'Undo and Redo restore recorded TM canvas edits, while Clear canvas '
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
    body:
        'Zoom and pan change the visible area of the TM without changing its '
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
    body:
        'The tape inspector shows visible cells and the current head '
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
      'Clear',
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
        'Simulation expands every tape with blanks as its head moves. Use the '
        'tape-count controls to add or remove tapes; every transition then has '
        'one explicit operation per tape. Removing a tape is refused while its '
        'operations contain nonblank symbols or movement. Continue with Tape '
        'and head theory.',
    keywords: [
      'TM',
      'MT',
      'tape count',
      'multi-tape',
      'blank symbol',
      'tape alphabet',
    ],
  ),
  HelpTopicIds.tmEditorTapeHeadAndCurrentCell: HelpNodeCopy(
    title: 'Head and current cell',
    body:
        'The head identifies the tape cell read by the next transition. Use '
        'the centered marker and Head position label to follow movement during '
        'editing or trace review. Select a trace step or use Previous step, '
        'Next step, Play, Pause, or Reset; the inspector projects that step and '
        'marks reads, writes, and the active cell. Left may extend the tape at '
        'its front, Right may append a blank, and Stay keeps the same index. '
        'For a multi-tape run, each collapsible inspector keeps its own head '
        'position and active operation visible. Continue with Trace and tape.',
    keywords: [
      'TM',
      'MT',
      'head position',
      'current cell',
      'Left',
      'Right',
      'Stay',
    ],
  ),
  HelpTopicIds.tmEditorMultiTapeTraceAndMetrics: HelpNodeCopy(
    blocks: _tmMultiTapeBlocks,
    title: 'Synchronized multi-tape trace and metrics',
    body:
        'A multi-tape TM reads one symbol from every tape, chooses a transition '
        'from that complete read vector, then writes and moves every head in '
        'one atomic step. Use Synchronized multi-tape trace after simulating an '
        'input to inspect that shared step without treating each tape as a '
        'separate execution. Select a trace row to see its source state, target '
        'state, transition ID, and operation count. The selected configuration '
        'has one expandable Tape section per tape. Each section shows its head '
        'position, read-to-write operation, direction, and nearby cells with '
        'the active head cell marked. Multi-tape space metrics reports the '
        'maximum visited span and maximum nonblank cells for each tape, plus '
        'the maximum simultaneous nonblank total across all tapes. Per-tape '
        'maxima may come from different configurations, so adding them does '
        'not recover the simultaneous total. An empty trace means no '
        'transition step was recorded. These values describe the selected '
        'bounded run, not asymptotic space or every input. Continue with Read '
        'the trace and tape or Space profile.',
    keywords: [
      'TM',
      'MT',
      'multi-tape',
      'Synchronized multi-tape trace',
      'atomic transition',
      'head position',
      'space metrics',
      'nonblank cells',
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
      'timeout',
    ],
  ),
  HelpTopicIds.tmEditorSimulationTraceAndTape: HelpNodeCopy(
    blocks: _tmSimulationBlocks,
    title: 'Read the trace and tape',
    body:
        'The TM trace records the state, tape contents, applied transition, '
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
      'Reset',
    ],
  ),
  HelpTopicIds.tmEditorSimulationResultsAndCanvas: HelpNodeCopy(
    blocks: _tmSimulationBlocks,
    title: 'Results and canvas playback',
    body:
        'Simulation results distinguish acceptance from rejection and expose '
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
    body:
        'TM Analysis combines bounded execution tools with structural '
        'reports for the current machine. Use it after drawing or loading an '
        'example when you want a focused view of states, transitions, tape '
        'use, reachability, timing, or warnings. Termination and Cycles '
        'classifies one concrete input with visible resource bounds. '
        'Reachability compares exact graph reachability with bounded concrete '
        'execution. Language Explorer classifies a bounded shortlex sample. '
        'Select Termination and Cycles, Reachability, Language Explorer, Tape '
        'Trace, Time Profile, Space Profile, or TM to unrestricted grammar. '
        'The conversion preview supports single-tape machines, preserves '
        'atomic symbol tokens, maps every production to its source transition, '
        'and opens the result as one undoable grammar-editor change. Its '
        'finite differential samples are evidence, not an equivalence proof. '
        'Controls are disabled only '
        'while an analysis is running; an absent or invalid machine reports an '
        'error after activation. Open the topic for the chosen focus.',
    keywords: [
      'TM',
      'MT',
      'TM Analysis',
      'structural analysis',
      'unrestricted grammar',
      'conversion',
      'results',
    ],
  ),
  HelpTopicIds.tmEditorAlgorithmsDecidability: HelpNodeCopy(
    blocks: _tmAlgorithmBlocks,
    title: 'Termination and Cycles',
    body:
        'Termination and Cycles classifies one concrete input under the '
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
    body:
        'Reachability keeps two claims separate. Structural '
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
    body:
        'Language Explorer enumerates the empty word first, then words in '
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
    body:
        'Tape Trace executes the machine on the shared concrete input '
        'and measures one real branch. It reports symbol reads and writes, '
        'changed cells, movements, reversals, stable logical cell positions, '
        'visited interval, peak nonblank cells, transition counts, and a sparse '
        'initial-to-final tape diff. Defined but unexecuted transitions remain '
        'visible as static coverage. For an NTM, the report labels the selected '
        'accepting, rejecting, cyclic, or longest bounded branch instead of '
        'combining unrelated branches. Open Related execution trace to inspect '
        'the retained trace produced by the same run. Empty input means epsilon; '
        'step, configuration, and time bounds still apply. Multi-tape runs '
        'report synchronized snapshots and per-tape metrics. Continue with '
        'Tape and head.',
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
    body:
        'Time Profile groups candidate inputs from length zero '
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
    body:
        'Space Profile groups bounded executions by input length. It reports '
        'the largest visited head span and the largest simultaneous nonblank '
        'cell count, with a witness input for each maximum. Configure the '
        'candidate cap and per-input execution limits before running it. The '
        'span uses stable logical tape coordinates for every head movement. An '
        'exhaustive row covers every word of that length. A sampled row is the '
        'deterministic shortlex prefix, and an incomplete row encountered an '
        'enumeration, execution, or cancellation bound. NTM maxima cover all '
        'explored branch configurations under the displayed configuration '
        'limit. Multi-tape runs report each tape span and nonblank-cell maximum '
        'as well as their combined maximum. Declared tape '
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
  'tm.editor.building-blocks': HelpNodeCopy(
    title: 'Reusable building blocks',
    keywords: [
      'TM',
      'MT',
      'building blocks',
      'submachine',
      'library',
      'call stack',
    ],
  ),
  HelpTopicIds.tmEditorBuildingBlocks: HelpNodeCopy(
    blocks: _tmBuildingBlockBlocks,
    title: 'Build and run reusable TM blocks',
    body:
        'Building blocks let one TM invoke named, revisioned submachines while '
        'all calls continue on the same tapes. Use them to inspect or compose '
        'a project from reusable operations without flattening every operation '
        'into the root graph. Open Building blocks, create or select a '
        'definition, and use Insert to add its invocation anchor to the root '
        'canvas. Rename and Duplicate manage definitions; breadcrumbs open '
        'nested references, while Undo and Redo apply to library edits. During '
        'simulation, Enter, Transition, and Return trace steps show the call '
        'stack and shared tape state. Recursive or unresolved dependencies '
        'stop execution. Deleting a referenced definition requires Detach and '
        'delete, which removes its invocations. The TM - Reusable building '
        'blocks example demonstrates nested composition. Turing Lab JSON and '
        'the dedicated JFLAP TM codec preserve block structure, but review '
        'reported compatibility losses for unknown optional metadata. Continue '
        'with Simulation or Files and examples.',
    keywords: [
      'TM',
      'MT',
      'Building blocks',
      'submachine',
      'Insert',
      'call stack',
      'shared tapes',
    ],
  ),
  HelpTopicIds.tmEditorBuildingBlocksManageLibrary: HelpNodeCopy(
    blocks: _tmBuildingBlockLibraryBlocks,
    title: 'Manage the building-block library',
    body:
        'The Building block library manages named, versioned TM definitions '
        'and their invocation anchors. Use it to prepare a reusable project '
        'before running the root machine.',
    keywords: [
      'TM',
      'MT',
      'building block library',
      'Create block',
      'Insert on root canvas',
      'Rename',
      'Duplicate',
      'Detach and delete',
      'breadcrumbs',
    ],
  ),
  HelpTopicIds.tmEditorFilesAndExamples: HelpNodeCopy(
    title: 'Files and examples',
    body:
        'Bundled TM examples provide ready-made single-tape and multi-tape '
        'machines: MT - a^n b^n, MT - Binário para unário, MT - Cópia de '
        'string, MT - Incremento binário, MT - Verificador de palíndromo, MT '
        'multifitas - Comparação, MT multifitas - Cópia em duas fitas, MT '
        'multifitas - Palíndromo, and MT multifitas - Fita de trabalho. Open TM '
        'Analysis to select an example or use the file panel '
        'to import and export JFLAP XML and Turing Lab JSON. These formats '
        'preserve the tape count and the read, write, and movement operation '
        'for every tape. Export SVG on native platforms becomes Download SVG '
        'on the web. Loading an example or importing a document replaces the '
        'current TM only after validation; canceling an operation leaves the '
        'model unchanged. Continue with the editor overview.',
    keywords: [
      'TM',
      'MT',
      'examples',
      'Export SVG',
      'Download SVG',
      'JFLAP',
      'JSON',
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
        'executes single-tape and multi-tape models with bounded runtime, so a '
        'timeout is not '
        'a mathematical rejection. Continue with Tape and head.',
    keywords: [
      'TM',
      'MT',
      'Turing machine',
      'finite control',
      'tape',
      'computation',
    ],
  ),
  HelpTopicIds.tmTheoryTapeAndHead: HelpNodeCopy(
    title: 'Tape and head',
    body:
        'Each tape supplies unbounded conceptual storage, and its head reads '
        'and writes the current cell. Use these concepts to interpret every TM '
        'transition. At each step, match the complete read vector, apply every '
        'write and Left, Right, or Stay movement atomically, and enter the '
        'target state. The next configuration reflects the new tapes, head '
        'positions, and state; unwritten cells contain the blank symbol. The '
        'app grows finite lists as needed and presents one synchronized '
        'inspector per tape. Continue with Configurations.',
    keywords: [
      'TM',
      'MT',
      'tape',
      'head',
      'blank symbol',
      'Left',
      'Right',
      'Stay',
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
      'head position',
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
    body:
        'A language is decidable when some TM halts on every input and '
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
      'halting',
    ],
  ),
  HelpTopicIds.tmTheoryRecursivelyEnumerable: HelpNodeCopy(
    title: 'Recursively enumerable languages',
    body:
        'A recursively enumerable language has a TM recognizer that accepts '
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
      'nontermination',
    ],
  ),
  HelpTopicIds.tmTheoryTimeAndSpace: HelpNodeCopy(
    title: 'Time and space complexity',
    body:
        'TM time counts computation steps as a function of input length, and '
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
      'tape cells',
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
    body:
        'Regular Expression is the pattern field, and its banner reports '
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
    body:
        'Alphabet is the set of individual characters available as the '
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
    body:
        'Test String checks whether the whole input belongs to the language '
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
    body:
        'Conversions connect the Regex workspace to equivalent finite '
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
    body:
        'Convert to NFA applies Thompson construction to the current regex '
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
    body:
        'Convert to DFA builds the regex NFA, determinizes it, and completes '
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
    body:
        'FA to Regex eliminates states from the current finite automaton and '
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
    body:
        'Simplification applies supported regular-algebra identities while '
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
    body:
        'Complexity Analysis summarizes the pattern structure rather than '
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
    body:
        'Sample Strings generates distinct examples accepted by the current '
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
    body:
        'Compare Equivalence checks whether two regexes describe the same '
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
    body:
        'Desktop and tablet Regex layouts reuse the FSA Algorithm Panel and '
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
    body:
        'A regular expression denotes a regular language by combining atomic '
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
    body:
        'A literal matches itself, while grouping ( ) makes a subexpression '
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
    body:
        'Concatenation places expressions next to each other, while union | '
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
    body:
        'Kleene star * repeats its preceding expression zero or more times, '
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
    body:
        'The optional ? operator allows zero or one copy of its preceding '
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
    body:
        'Precedence decides which operands each regex operator controls when '
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
    body:
        'Lambda and epsilon are common names for the empty word, which has '
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
    body:
        'A regular language is any language denoted by a regex or recognized '
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
    body:
        'Regexes and finite automata have the same expressive power over '
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
  HelpTopicIds.pumpingEditorEnvironmentChoice: HelpNodeCopy(
    blocks: _pumpingEnvironmentChoiceBlocks,
    title: 'Choose a pumping lemma environment',
    body:
        'The compatibility chooser separates the regular and context-free '
        'pumping lemma games. Choose the theorem environment before starting '
        'so the game uses the right decomposition, constraints, examples, and '
        'progress.',
    keywords: [
      'pumping lemma environment',
      'Regular pumping',
      'Context-free pumping',
      'decomposition',
      'proof constraints',
    ],
  ),
  HelpTopicIds.pumpingEditorOverview: HelpNodeCopy(
    title: 'Pumping workspace overview',
    body:
        'The Pumping workspace combines a classification game, a three-tab '
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
    body:
        'Pumping Lemma Game presents eight fixed language-classification '
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
    body:
        'Challenges are grouped into levels 1 through 4 and labeled EASY, '
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
    body:
        'The game asks Is this language regular? and offers Yes, it is '
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
    body:
        'A pumping-lemma proof normally chooses a witness string and reasons '
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
    body:
        'A contradiction proof chooses a pumping exponent only after the '
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
    body:
        'Feedback reveals Correct! or Incorrect, an explanation, and hints '
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
      'Practice Again',
    ],
  ),
  HelpTopicIds.pumpingEditorProgress: HelpNodeCopy(
    title: 'Progress and statistics',
    body:
        'Progress summarizes completed challenges and the chronological '
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
    body:
        'The Pumping workspace rearranges Game, Help, and Progress according '
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
    body:
        'The Pumping Lemma gives a necessary repeatability property of every '
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
    body:
        'Quantifier order determines who chooses each object in the Pumping '
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
      'non-regular',
    ],
  ),
  HelpTopicIds.pumpingTheoryChooseWitness: HelpNodeCopy(
    title: 'Choose a witness',
    body:
        'The witness is a string s in L whose structure exposes the memory '
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
    body:
        'The regular-language claim may choose any split s = xyz satisfying '
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
    body:
        'A contradiction is an exponent k ≥ 0 for which xyᵏz is not in L. '
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
    body:
        'The Pumping Lemma is a necessary condition for regular languages, '
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
    body:
        'The language L = {aⁿ | n ≥ 0} is regular and is denoted by a*. Use '
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
    body:
        'The language L = {aⁿbⁿ | n ≥ 0} is not regular because it requires '
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
    body:
        'The language L = {ww | w ∈ {a,b}*} contains two identical '
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
    body:
        'Canvas shortcuts operate the focused editable automaton canvas. Use '
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
    body:
        'Simulation shortcuts operate the input and controls in the current '
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
    body:
        'Dialog and form shortcuts confirm, cancel, or move through an '
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
    body:
        'Keyboard focus identifies which control receives the next keyboard '
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
    body:
        'Modifier shortcuts have equivalent Control and Command variants '
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
    body:
        'Escape cancels the keyboard context that currently owns the key. '
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
    body:
        'An invalid automaton is missing required structure or contains a '
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
    body:
        'Grammar input errors identify a production or grammar field that '
        'cannot form the requested grammar. Use this topic when a production '
        'row shows an error or parsing and conversions reject the model. Keep '
        'one nonterminal on the left, enter valid symbols or alternatives on '
        'the right, use ε for the empty word, and select a start symbol '
        'that the grammar declares. Correct rows remain in the editor and the '
        'status or command result reports whether the grammar can proceed. '
        'Empty productions, undeclared symbols, and algorithm-specific forms '
        'such as CNF can still require another correction. Continue with '
        'Production validation or Parser strategies.',
    keywords: ['grammar error', 'production', 'start symbol', 'lambda'],
  ),
  HelpTopicIds.troubleshootingRegexInput: HelpNodeCopy(
    title: 'Regular-expression input errors',
    body:
        'A regular-expression diagnostic points to syntax that the current '
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
    body:
        'Simulation limits stop a search that takes too long or explores too '
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
    body:
        'Parser strategies use different algorithms and grammar '
        'requirements to test a string. Use this topic when one strategy is '
        'unavailable, times out, or disagrees with an assumption about the '
        'grammar form. Start with Automatic (Earley) for general parsing, try '
        'Brute force for a small grammar, or choose CYK '
        '(Cocke-Younger-Kasami) when its table and steps are useful. The panel '
        'returns acceptance, diagnostics, and any available derivation or '
        'steps. LL(1) is available for conflict-free predictive grammars, and '
        'Canonical LR(1) is available for conflict-free canonical LR grammars. '
        'Every strategy still has a five-second bound. '
        'Continue with the parser topic for the selected strategy.',
    keywords: [
      'parser',
      'Automatic (Earley)',
      'Brute force',
      'CYK',
      'LL',
      'LR',
    ],
  ),
  HelpTopicIds.troubleshootingFileImportExport: HelpNodeCopy(
    title: 'File import and export',
    body:
        'File errors occur when a chosen file or action does not match the '
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
  HelpTopicIds.troubleshootingInteroperabilityReview: HelpNodeCopy(
    blocks: _interoperabilityReviewBlocks,
    title: 'Review interoperability fidelity',
    body:
        'The interoperability review dialog makes codec changes visible before '
        'an import or export is committed. Use it to distinguish exact, '
        'normalized, and lossy representations, inspect field-level '
        'diagnostics, and decide whether to continue or cancel.',
    keywords: [
      'interoperability',
      'fidelity',
      'normalized',
      'data loss',
      'field-level report',
    ],
  ),
  HelpTopicIds.troubleshootingMissingStateMarkers: HelpNodeCopy(
    title: 'Missing state markers',
    body:
        'State markers tell an automaton where execution starts and which '
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
    body:
        'Nondeterminism means more than one next configuration can apply '
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
    body:
        'A lost canvas view means the model still exists but zoom or pan has '
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
    body:
        'Turing Lab is developed by Thales Matheus Mendonça Santos. '
        'Source code: https://github.com/ThalesMMS/Turing-Lab.',
    keywords: ['developer', 'Thales', 'repository', 'GitHub', 'Turing-Lab'],
  ),
  HelpTopicIds.aboutLicenses: HelpNodeCopy(
    title: 'Licenses',
    body:
        'Turing Lab is a Flutter reimplementation inspired by and compatible '
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
    body:
        'The acknowledgments credit the people and projects whose work is '
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
    body:
        'Distribution describes how this build is offered while it contains '
        'JFLAP-derived material. Consult it before describing or redistributing '
        'the application. Turing Lab is distributed as a free, non-monetized '
        'educational app while it includes that material, alongside the '
        'licenses and notices named in this Help catalog. Users receive the '
        'application under those stated project and third-party terms. Free '
        'distribution does not replace any Apache, JFLAP, MIT, package, or '
        'platform notice. Continue with Licenses.',
    keywords: ['distribution', 'free', 'non-monetized', 'educational app'],
  ),
  HelpTopicIds.mealyEditorOverview: HelpNodeCopy(
    title: 'Mealy transducers',
    body:
        'A Mealy machine emits output while taking a transition. Its workspace '
        'combines a graph editor, explicit input and output alphabets, trace '
        'playback, batch execution, output comparison, examples, and file or '
        'image export. Start with States and transitions for the Mealy-specific '
        'editing rules, then follow the shared workspace topics.',
    keywords: ['Mealy', 'transducer', 'transition output', 'workspace'],
  ),
  HelpTopicIds.mealyEditorStatesAndTransitions: HelpNodeCopy(
    title: 'Mealy states and transitions',
    body:
        'A Mealy state stores identity, label, position, and whether it is the '
        'initial state. Each transition consumes one input symbol and emits an '
        'ordered sequence of output tokens.',
    keywords: ['Mealy', 'state', 'transition', 'output tokens'],
    blocks: _mealyEditingBlocks,
  ),
  HelpTopicIds.mooreEditorOverview: HelpNodeCopy(
    title: 'Moore transducers',
    body:
        'A Moore machine emits output from states, including the initial '
        'state before any input is consumed. Its workspace combines a graph '
        'editor, explicit alphabets, trace playback, batch execution, output '
        'comparison, examples, and file or image export. Start with States and '
        'transitions for the Moore-specific editing rules.',
    keywords: ['Moore', 'transducer', 'state output', 'workspace'],
  ),
  HelpTopicIds.mooreEditorStatesAndTransitions: HelpNodeCopy(
    title: 'Moore states and transitions',
    body:
        'A Moore state stores its ordered output tokens. Each transition only '
        'consumes one input symbol, and entering a state determines the output '
        'emitted for that step.',
    keywords: ['Moore', 'state', 'transition', 'initial output'],
    blocks: _mooreEditingBlocks,
  ),
  HelpTopicIds.transducerEditorCanvasAndAlphabets: HelpNodeCopy(
    title: 'Canvas and alphabets',
    body:
        'Mealy and Moore share the same responsive canvas and Machine details '
        'surface. Define token boundaries in the alphabets before building the '
        'graph, then use diagnostics to check the resulting machine.',
    keywords: ['canvas', 'alphabet', 'machine details', 'diagnostics'],
    blocks: _transducerCanvasBlocks,
  ),
  HelpTopicIds.transducerEditorCanvasEditingGestures: HelpNodeCopy(
    title: 'Canvas editing gestures',
    body:
        'Mealy and Moore use persistent Add state and Add transition modes. '
        'Add state places a state only after you select an empty canvas point. '
        'Add transition waits for a source and target before opening the '
        'machine-specific transition editor. Select mode moves states, while '
        'double-tap, long-press, secondary-pointer, and transition-label '
        'gestures open the matching editor. Panning and zoom remain available '
        'while a placement mode is active.',
    keywords: [
      'Add state',
      'Add transition',
      'Select',
      'tap to place',
      'self-loop',
      'transition label',
    ],
    blocks: _transducerCanvasEditingGestureBlocks,
  ),
  HelpTopicIds.transducerEditorSimulationAndPlayback: HelpNodeCopy(
    title: 'Simulation and playback',
    body:
        'Simulation consumes an ordered list of input tokens and records the '
        'output and transition trace. The panel and canvas playback show the '
        'same retained execution steps.',
    keywords: ['simulation', 'trace', 'playback', 'output'],
    blocks: _transducerSimulationBlocks,
  ),
  HelpTopicIds.transducerEditorCompactCanvasPlayback: HelpNodeCopy(
    title: 'Compact canvas playback',
    body:
        'A Mealy or Moore result with a retained trace offers View on Canvas '
        'in compact layouts. The action closes the Simulation sheet and '
        'opens a playback bar over the canvas. Its controls move through the '
        'same trace, update the input-token strip, and highlight the target '
        'state and transition for the selected step. Wide layouts keep the '
        'trace in the Simulation panel instead. Close removes the bar and '
        'highlights. Editing, clearing, replacing, or widening the machine '
        'view discards compact playback that no longer applies.',
    keywords: [
      'View on Canvas',
      'compact layout',
      'playback bar',
      'Previous Step',
      'Play',
      'Next Step',
      'trace highlight',
    ],
    blocks: _transducerCompactCanvasPlaybackBlocks,
  ),
  HelpTopicIds.transducerEditorBatchComparisonAndExamples: HelpNodeCopy(
    title: 'Batch, comparison, and examples',
    body:
        'Batch execution runs several token arrays against the current machine. '
        'Comparison checks the current machine against a selected example '
        'using exact or explicitly bounded semantics.',
    keywords: ['batch', 'comparison', 'examples', 'witness'],
    blocks: _transducerBatchBlocks,
  ),
  HelpTopicIds.transducerEditorFilesAndExport: HelpNodeCopy(
    title: 'Files and export',
    body:
        'The workspace can load its offline examples, exchange supported '
        'machine documents, and export a visual snapshot. Document operations '
        'remain separate from image export.',
    keywords: ['files', 'JFLAP XML', 'JSON', 'SVG', 'PNG', 'examples'],
    blocks: _transducerFilesBlocks,
  ),
  HelpTopicIds.unrestrictedGrammarEditorOverview: HelpNodeCopy(
    title: 'Unrestricted grammars',
    body:
        'The unrestricted-grammar workspace edits phrase-structure productions '
        'whose two sides are ordered symbol sequences. It also classifies the '
        'written rules, searches or constructs derivations, shows variable '
        'dependencies, loads examples, and exchanges supported files. Start '
        'with Editing and classification for the input format.',
    keywords: ['unrestricted grammar', 'phrase structure', 'workspace'],
  ),
  HelpTopicIds.unrestrictedGrammarEditingAndClassification: HelpNodeCopy(
    title: 'Editing and classification',
    body:
        'The editor keeps terminals, nonterminals, and production sides as '
        'explicit token sequences. Drag a production only from its handle to '
        'reorder it, or use Move up and Move down from the production menu '
        'with a keyboard or screen reader. Native JSON and the Turing Lab '
        'JFLAP token extension preserve the exact order. The classifier '
        'reports the strongest class satisfied by the current production set '
        'and names violated rules.',
    keywords: [
      'production',
      'classification',
      'nonterminal',
      'JSON',
      'Move up',
      'drag',
    ],
    blocks: _unrestrictedGrammarEditingBlocks,
  ),
  HelpTopicIds.unrestrictedGrammarDerivationAndDependencyGraph: HelpNodeCopy(
    title: 'Derivations and variable dependencies',
    body:
        'The workspace can search for a derivation within a configured budget '
        'or let you choose each production occurrence manually. Its dependency '
        'graph summarizes which variables can introduce other variables.',
    keywords: ['derivation', 'bounded search', 'dependency graph', 'witness'],
    blocks: _unrestrictedGrammarDerivationBlocks,
  ),
  HelpTopicIds.unrestrictedGrammarExamplesFilesAndLimits: HelpNodeCopy(
    title: 'Examples, files, and limits',
    body:
        'Offline examples provide complete grammars and suggested inputs. The '
        'Information panel contains file exchange and, when available, the '
        'provenance of a Turing-machine conversion.',
    keywords: ['examples', 'JFLAP XML', 'JSON', 'limits', 'provenance'],
    blocks: _unrestrictedGrammarFilesBlocks,
  ),
  HelpTopicIds.unrestrictedGrammarTmToGrammarConstruction: HelpNodeCopy(
    title: 'TM to unrestricted grammar construction',
    body:
        'The TM-to-unrestricted-grammar workspace turns a supported single-tape '
        'Turing machine into an unrestricted grammar preview with production '
        'provenance, token-safe symbols, and a bounded differential check. '
        'Start with the construction preview before editing the generated '
        'grammar.',
    keywords: [
      'TM',
      'Turing machine',
      'unrestricted grammar',
      'construction',
      'provenance',
      'single-tape',
      '50,000',
    ],
    blocks: _tmToUnrestrictedGrammarBlocks,
  ),
  HelpTopicIds.lSystemEditorOverview: HelpNodeCopy(
    title: 'L-systems',
    body:
        'The L-system workspace applies parallel rewriting to an axiom and '
        'renders the chosen generation as tokens and turtle geometry. It '
        'supports contextual and weighted rules, seeded choices, playback, '
        'offline examples, file exchange, and SVG or PNG export. Start with '
        'Definition and rules to learn the editor syntax.',
    keywords: [
      'L-system',
      'parallel rewriting',
      'turtle graphics',
      'workspace',
    ],
  ),
  HelpTopicIds.lSystemDefinitionAndRules: HelpNodeCopy(
    title: 'Definition and rules',
    body:
        'An L-system document stores an axiom, parallel productions, iteration '
        'count, turtle command mapping, drawing settings, and a random seed. '
        'Spaces preserve token boundaries in the editor.',
    keywords: ['axiom', 'production', 'context', 'weight', 'random seed'],
    blocks: _lSystemDefinitionBlocks,
  ),
  HelpTopicIds.lSystemGenerationsAndTurtleView: HelpNodeCopy(
    title: 'Generations and turtle view',
    body:
        'Expansion produces an ordered generation of tokens. The turtle '
        'interpreter maps those tokens to geometry, while the generation '
        'controls keep the text result and drawing on the same step.',
    keywords: ['generation', 'turtle', 'playback', 'SVG', 'PNG'],
    blocks: _lSystemGenerationBlocks,
  ),
  HelpTopicIds.lSystemExamplesFilesAndLimits: HelpNodeCopy(
    title: 'Examples, files, and limits',
    body:
        'Offline examples combine a formal L-system with a learning objective, '
        'limitation, and visual description. The Files panel exchanges '
        'supported documents separately from image export.',
    keywords: ['examples', 'JFLAP XML', 'JSON', 'limits', 'fidelity'],
    blocks: _lSystemFilesBlocks,
  ),
  'extended-formal-systems': HelpNodeCopy(
    title: 'Extended formal systems',
    body: 'Explore unrestricted grammars and parallel L-system rewriting.',
    keywords: ['grammar', 'L-system', 'rewriting'],
  ),
  'transducers': HelpNodeCopy(
    title: 'Transducers',
    body:
        'Build deterministic machines that emit output while consuming '
        'input. Choose Mealy for transition-owned output or Moore for '
        'state-owned output, including the initial state output.',
    keywords: ['transducer', 'Mealy', 'Moore', 'output'],
  ),
});
