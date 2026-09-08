# Turing Lab User Guide

Turing Lab is an interactive environment for studying formal languages and
automata. This manual is written for students meeting the theory for the first
time and for educators preparing classes. Each chapter pairs the theory behind
a formal system with the concrete workflow in the app: how to build the object
on screen, how to run it, how to read the trace, which algorithms are
available, and where the app deliberately stops.

Every workspace also ships an in-app Help catalog (the `?` action in the app
bar) with the same topics in English and Portuguese, searchable by keyword.
This guide follows the same structure so the two can be read side by side.

## Table of contents

1. [Getting around](#1-getting-around)
2. [Finite automata (DFA and NFA)](#2-finite-automata-dfa-and-nfa)
3. [Pushdown automata](#3-pushdown-automata)
4. [Turing machines](#4-turing-machines)
5. [Context-free grammars and parsing](#5-context-free-grammars-and-parsing)
6. [Unrestricted grammars and guided derivations](#6-unrestricted-grammars-and-guided-derivations)
7. [Regular expressions and equivalence](#7-regular-expressions-and-equivalence)
8. [Mealy and Moore transducers](#8-mealy-and-moore-transducers)
9. [L-systems and turtle geometry](#9-l-systems-and-turtle-geometry)
10. [The Pumping Lemma game](#10-the-pumping-lemma-game)
11. [Manual conversion practice](#11-manual-conversion-practice)
12. [Interoperability and file formats](#12-interoperability-and-file-formats)
13. [Traces, history, and batch runs](#13-traces-history-and-batch-runs)
14. [Keyboard shortcuts and accessibility](#14-keyboard-shortcuts-and-accessibility)
15. [Troubleshooting](#15-troubleshooting)
16. [Suggested classroom sequences](#16-suggested-classroom-sequences)
17. [Further reading in this repository](#17-further-reading-in-this-repository)

---

## 1. Getting around

### 1.1 Workspaces

Turing Lab is organized in workspaces, one per formal system. Switch between
them with the workspace selector at the leading edge of the app bar. The
registered workspaces are:

| Workspace | What you build | Runs inputs? |
| --- | --- | --- |
| FSA | Deterministic and nondeterministic finite automata | Yes |
| Grammar | Context-free grammars | Yes (parsers) |
| Unrestricted grammar | Phrase-structure grammars of any Chomsky type | Yes (bounded derivation search) |
| PDA | Pushdown automata with one stack | Yes |
| TM | Single-tape, multi-tape, and building-block Turing machines | Yes |
| Regex | Regular expressions | Yes (test strings) |
| Mealy / Moore | Finite-state transducers | Yes |
| L-systems | Deterministic context-free Lindenmayer systems | Yes (generations) |
| Pumping Lemma | Regular and context-free adversarial games | Game |

### 1.2 Layouts

The interface adapts to the screen:

- **Phones** show the canvas or editor full screen. The bottom tray holds
  canvas tools (select, add state, add transition, undo, redo, zoom). The app
  bar exposes quick actions: Help, Simulate, Algorithms & Examples, and, for
  Turing machines, Metrics. Panels open as bottom sheets that you can drag to
  resize and swipe down to dismiss.
- **Tablets, desktops, and the web** are canvas-first. Panels live in the
  dock at the trailing edge: tap a rail icon to open Simulation, Algorithms &
  Examples, or Info; tap it again or use the close button to give the width
  back to the canvas; drag the divider to resize.

Whatever the layout, the same providers hold the document, so switching a
window size never loses work.

### 1.3 The canvas

All automaton and transducer workspaces share the GraphView canvas.

- **Select tool (V):** tap a state to select it; double-tap, long-press, or
  secondary-click to open its properties (label, initial, accepting). Tap a
  transition to edit its label; overlapping transitions open a chooser.
- **Add state tool (A):** tap empty canvas to create a state at that point.
  The first state becomes initial automatically; each state receives a unique
  id and label.
- **Add transition tool (T):** tap the source state, then the destination
  state. Tapping the same state twice creates a self-loop. The transition
  editor opens for the label (symbols, stack operations, or tape operations
  depending on the workspace).
- **Move:** drag a state. Positions are stored in the document and survive
  export.
- **Viewport:** pinch or scroll to zoom, drag empty space to pan, use fit to
  content and reset view when the machine drifts out of sight. Auto Layout
  rearranges states of FSA and PDA machines.
- **History:** undo and redo cover every edit, including algorithm results
  that replaced the document.

### 1.4 Settings

Settings hold the empty-string symbol (ε or λ), theme, grid and coordinates
visibility, tooltips, node and font sizes, animation speed, and Auto Save.
When Auto Save is on, the latest document of every workspace, its notes, and
the active workspace are restored on the next launch (see
[docs/PERSISTENCE.md](docs/PERSISTENCE.md)).

### 1.5 Examples and suggested simulations

Every workspace ships offline examples. Open Algorithms & Examples and tap an
example card to load it. Cards describe the language, the learning objective,
and the limitation of the example. Below the card:

- **Suggested simulations** list accepted words. Tap **Use input** on a word to
  send it to the simulation field without retyping; on phones the simulation
  sheet opens automatically. If the example is not the active document it is
  loaded first, and if the field already holds text you edited, the app asks
  whether to keep or replace it.
- **Commented inputs** (finite automata and pushdown automata) add a rejected
  word, boundary cases such as the empty word, and inputs with symbols outside
  the alphabet, each with the expected outcome and a short justification.

### 1.6 Document notes

Every workspace supports sticky notes attached to the document. Notes travel
with JSON and JFLAP exports and can optionally be drawn into SVG and PNG
exports ("Include notes in visual exports" in the file panel).

---

## 2. Finite automata (DFA and NFA)

### 2.1 Theory in brief

A finite automaton reads a word one symbol at a time and moves between
finitely many states. A **DFA** has exactly one move per state and symbol. An
**NFA** may have several moves for the same symbol, none at all, or
ε-transitions that move without reading. A word is accepted when at least one
run ends in an accepting state after the whole input is consumed. DFAs and
NFAs accept exactly the **regular languages**, the same class described by
regular expressions.

Key notions the app makes visible:

- **Alphabet:** the set of symbols the machine reads. Turing Lab derives it
  from the transition labels and reports symbols outside the alphabet as
  invalid input rather than as a rejected word.
- **ε-closure:** the set of states reachable through ε-transitions alone.
  Subset construction (NFA → DFA) is built on it.
- **Determinism:** the editor shows conflict and ε counters in the header so
  you always know whether the current machine is a DFA.

### 2.2 Building a finite automaton

1. Add states with the Add state tool; mark initial and accepting states in
   the state properties.
2. Add transitions. Labels accept single symbols, comma-separated symbol
   lists (`a,b`), and the empty-string symbol for ε-moves.
3. Watch the header counters: **Conflicts** counts states with more than one
   move on the same symbol, **Epsilon** counts ε-transitions.

### 2.3 Simulating

Open Simulation, type the input, and press Simulate. The result card shows the
verdict, the number of steps, the execution path, and the transitions taken.

- **Step-by-Step Mode** turns on the trace viewer: previous, play/pause, next,
  reset, a timeline slider, and a step counter. Tap the counter to jump to a
  step number.
- For NFAs the **branch inspector** shows the computation tree: every
  configuration, which branches died, and which reached acceptance.
- **View on canvas** replays the accepted path on the diagram.

### 2.4 Algorithms

All FSA algorithms live in Algorithms & Examples. Results that produce a new
machine ask before replacing the document.

| Algorithm | What it does | Notes |
| --- | --- | --- |
| Regex to NFA | Thompson construction with visible steps | Input field in the panel |
| NFA to DFA | Subset construction with step report | Step viewer lists state sets and ε-closures |
| Remove ε-transitions | Eliminates ε-moves keeping the language | |
| Minimize DFA | Partition refinement with step report | Requires a DFA |
| Complete DFA | Adds a trap state and every missing transition | |
| Practice DFA completion | Guided exercise: you add the trap state and transitions on the canvas while the checker lists open (state, symbol) pairs and hints the next step; "Complete automatically" reveals the answer | |
| Complement DFA | Completes, then flips accepting states | |
| Union, Intersection, Difference | Product constructions with a second automaton loaded from a file | |
| Concatenation, Kleene star, Reverse | Closure constructions through ε-bridges | |
| Prefix closure, Suffix closure | Accept all prefixes or suffixes | |
| FA to Regex | State elimination with visible steps | |
| FSA to Grammar | Right-linear grammar | Opens the grammar workspace |
| Compare equivalence | Language equivalence with a shortest distinguishing witness | Second automaton loaded from a file |

### 2.5 Reading a conversion step

Conversion steps show a title, a didactic explanation, and a typed data
section: the operation, current and next state sets, the processed symbol,
ε-closures, partitions, or created fragments. Playing the steps highlights the
involved states on the canvas.

---

## 3. Pushdown automata

### 3.1 Theory in brief

A pushdown automaton extends a finite automaton with a stack. Each transition
reads an input symbol (or ε), pops one stack symbol (or ε), and pushes a string
(or ε). PDAs recognize exactly the **context-free languages**. Turing Lab
models the single-stack PDA and supports both acceptance policies:

- **Final state:** accept when the input is consumed in an accepting state.
- **Empty stack:** accept when the input is consumed and the stack is empty.

Nondeterminism is natural for PDAs; a palindrome recognizer, for instance, has
to guess the middle of the word. The simulator explores branches with explicit
limits.

### 3.2 Building a PDA

Transitions use the form `input, pop → push`. In the editor each part has its
own field; the empty-string symbol stands for ε in any of them. The initial
stack symbol (`Z` by default) and the stack alphabet are document properties
shown in the Stack inspector, which also previews what a transition will do to
the current stack.

### 3.3 Simulating

Simulation shows the trace as a list of configurations with the current state,
the remaining input, and the stack. Outcomes are explicit: accepted, rejected,
timeout, configuration limit, depth limit, memory limit, or proven cycle. A
timeout or limit is inconclusive, never a rejection. Long runs can be
cancelled; canvas playback replays the accepted path.

### 3.4 Algorithms and analysis

| Feature | Description |
| --- | --- |
| Convert PDA to CFG | Standard triple construction, opened in the grammar workspace |
| Simplify PDA | Removes unreachable states and unusable transitions with a review dialog |
| Check determinism | Reports conflicting transitions |
| Find reachable states | Reachability from the initial state |
| Analyze the language | Bounded exploration of accepted words |
| Analyze stack operations | Push/pop statistics per transition |

---

## 4. Turing machines

### 4.1 Theory in brief

A Turing machine has a tape that extends without bound, a head that reads and
writes one cell, and a finite control. A transition reads a symbol, writes a
symbol, and moves the head left, right, or stays. Turing machines recognize the
**recursively enumerable languages**; those that halt on every input decide the
**decidable languages**. Because a machine may run forever, every execution in
Turing Lab is bounded by steps and configurations.

Turing Lab offers three variants:

- **Single-tape** machines, the classroom default.
- **Multi-tape** machines, where each transition reads, writes, and moves on
  every tape at once. The tape inspector shows all tapes and heads
  synchronized with the trace.
- **Building blocks:** reusable sub-machines composed into a larger project.
  Blocks are created, renamed, and managed in the block library; execution
  enters and leaves blocks with a synchronized trace.

### 4.2 Building a Turing machine

Transitions use `read → write, direction` (`L`, `R`, or `S`). The blank symbol
(`□` by default) and the tape alphabet are document properties. The tape
inspector lets you set the initial tape content and shows the head position.

### 4.3 Simulating

The trace lists each step with the state, the tape around the head, and the
transition taken. Multi-tape runs show every tape side by side. Canvas
playback highlights the states visited. When a machine exceeds its limits the
outcome is reported as inconclusive.

### 4.4 Analysis

The Metrics action (Analysis panel on wide layouts) provides:

- **Termination and cycles:** detects proven cycles and halting behaviour.
- **Reachability:** which states can be reached from the initial state.
- **Language explorer:** enumerates accepted words within bounds and lets you
  select one as simulation input.
- **Tape trace:** the head trajectory and written cells.
- **Time profile and space profile:** step counts and cells used across sample
  inputs.

### 4.5 Conversion to unrestricted grammar

Single-tape machines can be converted to an unrestricted grammar that derives
exactly the accepted words. The result opens in the unrestricted grammar
workspace with the construction report. A multi-tape machine without building
blocks is first reduced to a single-tape machine over composite cells (one
symbol and one head marker per track, see `docs/TM_MULTI_TAPE_REDUCTION.md`);
the report says so, keeps the provenance pointing at your original states and
transitions, and fails closed with a budget diagnostic when the reduced
machine or the grammar would grow past its limits. Building-block machines and
machines that accept by halting still report an unsupported-machine diagnostic
instead of guessing.

---

## 5. Context-free grammars and parsing

### 5.1 Theory in brief

A context-free grammar has variables (nonterminals), terminals, productions of
the form `A → α`, and a start symbol. A derivation rewrites the start symbol
step by step until only terminals remain; the derivation tree records the
structure. A grammar is **ambiguous** when some word has two different trees.
Context-free grammars generate exactly the context-free languages, which are
also the languages of PDAs.

Normal forms simplify proofs and algorithms:

- **Chomsky Normal Form (CNF):** every production is `A → BC` or `A → a`.
- **Greibach Normal Form (GNF):** every production starts with a terminal.

Predictive parsing needs FIRST and FOLLOW sets; LL(1) grammars admit a
conflict-free predictive table; LR(1) parsers use states of items and a
lookahead.

### 5.2 Editing a grammar

The editor lists productions as rows. Type alternatives separated by `|`; the
empty-string symbol writes an ε-production. The editor validates symbols,
marks unused variables, and lets you set the start symbol. Grammar metadata
records the declared type; the classification report tells you when the
declared type does not match the productions.

### 5.3 Parsing a word

Open the parser and choose a strategy:

| Strategy | When to use it | Result |
| --- | --- | --- |
| Earley | Any context-free grammar | Acceptance and derivation |
| Brute force | Small grammars, teaching derivations | Bounded search with depth, frontier, result cap and time limit |
| CYK | Grammars in CNF | Table with step-by-step filling |
| LL(1) | Grammars with a conflict-free table | Predictive parse with the table and stack |
| LR(1) | Canonical LR grammars | Item sets and shift/reduce steps |
| User-controlled derivation | Learning derivations | You choose the production at each step; the app validates it |

Results show the verdict, the derivation or parse tree, and the parser steps
with playback. The LR(1) and parse-table teaching workspaces let you build the
tables yourself with checks and hints.

### 5.4 Analysis and transformations

Algorithms & Examples offers classification (Chomsky hierarchy with
diagnostics), useless, unit and ε-production removal, left-recursion removal,
left factoring, CNF and GNF conversion, FIRST and FOLLOW sets, LL(1) table
construction with an ambiguity check, and the variable dependency graph. Each
transformation records its steps in the **Transformation steps** history:
expand a step to see the grammar before and after, and apply that intermediate
grammar to the editor when you want to continue from there.

**Practice grammar normalization** is a guided workspace in which you propose
each normalization step and the app audits it.

### 5.5 Conversions

- **Right-linear grammar to FSA.**
- **Grammar to PDA:** general construction, standard construction, and the
  construction through Greibach form; a guided CFG-to-PDA workspace explains
  every transition.
- **PDA to CFG** is available from the PDA workspace.

---

## 6. Unrestricted grammars and guided derivations

### 6.1 Theory in brief

Unrestricted (type 0) grammars allow any nonempty string of symbols on the
left side of a production. They generate the recursively enumerable languages,
the same class Turing machines recognize. Context-sensitive grammars are the
subclass whose productions never shrink.

### 6.2 Workflow

- Edit productions with symbol lists on both sides; the classification tells
  you the Chomsky type of what you wrote and why.
- **Derivations** run a bounded search for a derivation of the input word.
  Limits on expanded sentential forms keep the search finite; hitting a limit
  is inconclusive.
- The **variable dependency graph** shows which variables can produce which
  and can be exported as SVG or PNG.
- Examples include classic non-context-free languages such as `aⁿbⁿcⁿ` and a
  grammar generated from a Turing machine.

---

## 7. Regular expressions and equivalence

### 7.1 Theory in brief

Regular expressions describe regular languages with union (`|`),
concatenation, Kleene star (`*`), plus (`+`), the optional operator (`?`),
grouping, and the empty string. Every regular expression converts to an NFA
(Thompson construction) and every finite automaton converts back to a regular
expression (state elimination), which is why the two formalisms are
equivalent.

### 7.2 Workflow

- **Input and validation:** the editor validates the expression as you type
  and derives the alphabet; you can also declare the alphabet explicitly.
- **Test strings:** enter a word and see immediately whether it matches.
  Suggested inputs from examples fill this field.
- **Convert to NFA / DFA:** results open in the FSA workspace with the
  construction steps.
- **FA to regex:** convert the current finite automaton and inspect the
  simplification steps.
- **Simplification and complexity:** algebraic simplification rules with
  step-by-step justification and a complexity summary.
- **Sample strings:** generate words of the language.
- **Compare equivalence:** compare two expressions and see a distinguishing
  witness when they differ.
- **Batch testing:** run many words at once.

---

## 8. Mealy and Moore transducers

### 8.1 Theory in brief

Transducers produce output while reading input. A **Mealy machine** attaches
an output to each transition; a **Moore machine** attaches an output to each
state, so the output of the initial state is emitted before any input is read.
The two models are close but not identical: for the empty word a Moore machine
emits its initial output while a Mealy machine emits nothing.

### 8.2 Workflow

- Build the machine on the canvas; the transition editor asks for the input
  symbol and, for Mealy machines, the output. Moore outputs are edited in the
  state properties.
- **Simulation** takes one input token per line (single symbols or whole
  words such as `coin`), applies a maximum-steps limit, and shows the trace
  and output word. Undefined transitions stop the run with an explicit
  outcome; partial machines are supported deliberately.
- **Batch and comparison** run several inputs and compare two machines on the
  same words.
- Files: JFLAP XML, Turing Lab JSON, SVG, and PNG.

---

## 9. L-systems and turtle geometry

### 9.1 Theory in brief

A Lindenmayer system rewrites every symbol of a string in parallel according
to production rules, generation after generation. Interpreting the resulting
string as turtle commands (move forward, turn, push and pop the turtle state)
draws plants and fractals. Turing Lab implements deterministic context-free
L-systems (D0L).

### 9.2 Workflow

- Define the axiom, the rules, the angle, the step length, and the number of
  generations. Generation and drawing are bounded so large systems stay
  responsive.
- The turtle view renders the current generation; export it as SVG or PNG.
- Parametric rules such as `A(x) → F(x*2) A(x-1)` are executed: the
  predecessor binds its identifiers and each successor argument is evaluated
  with a deterministic arithmetic evaluator. Stochastic and context-sensitive
  rules imported from JFLAP are preserved in the file but are not executed.

---

## 10. The Pumping Lemma game

### 10.1 Theory in brief

The pumping lemma gives a necessary condition for regularity: every regular
language has a pumping length `p` such that any word `w` with `|w| ≥ p` splits
as `xyz` with `|xy| ≤ p`, `|y| ≥ 1`, and `xyⁱz` in the language for every
`i ≥ 0`. To prove a language is **not** regular you play against an adversary:
the adversary picks `p`, you pick a witness `w`, the adversary picks the
decomposition, and you pick a pumping count `i` that leaves the language. The
context-free version splits `w` as `uvxyz`. The lemma cannot prove that a
language is regular.

### 10.2 Workflow

- Choose the **regular** or **context-free** environment.
- Each challenge presents a language; decide whether it is regular (or
  context-free) and, when it is not, provide the witness, review all
  decompositions the adversary can choose, and select the pumping count that
  breaks membership.
- Feedback explains mistakes; retry and practice modes keep scores per
  challenge. Progress is stored with the document and restored on relaunch.
- The theory topics in Help walk through `a*`, `aⁿbⁿ`, and `ww`.

---

## 11. Manual conversion practice

Some conversions can be practiced by hand with validation:

| Practice | Where | What you do |
| --- | --- | --- |
| DFA completion | FSA workspace, Algorithms & Examples | Add the trap state and each missing transition on the canvas; the checker lists open pairs and hints |
| FA to regex | FSA workspace | Perform state elimination step by step with validated intermediate expressions |
| FA to regular grammar | FSA workspace | Map states and transitions to right-linear productions with provenance |
| Regex to FA | Regex workspace | Build the Thompson fragments yourself |
| CFG to PDA | Grammar workspace | Guided construction of the PDA transitions |
| Grammar normalization | Grammar workspace | Propose each normalization step and have it audited |
| LR(1) and parse tables | Grammar workspace | Build item sets and tables with checks |
| TM to unrestricted grammar | TM workspace | Follow the construction report |

Manual sessions are saved per document revision; editing the source document
invalidates the saved session so you never continue from a stale start.

---

## 12. Interoperability and file formats

The file panel of every workspace is registry driven: it shows only the
formats the workspace supports.

| Formal system | Import | Export |
| --- | --- | --- |
| Finite automaton | `.jff`, `.json` | `.jff`, `.json`, `.svg`, `.png` |
| Context-free grammar | `.cfg`, `.json` | `.cfg`, `.json`, `.svg` |
| Unrestricted grammar | `.jff`, `.json` | `.jff`, `.json` |
| Pushdown automaton | `.jff`, `.json` | `.jff`, `.json`, `.svg`, `.png` |
| Turing machine | `.jff`, `.json` | `.jff`, `.json`, `.svg`, `.png` |
| Regular expression | `.jff`, `.json` | `.jff`, `.json` |
| Pumping Lemma | `.jff`, `.json` | `.jff`, `.json` |
| Mealy / Moore | `.jff`, `.json` | `.jff`, `.json`, `.svg`, `.png` |
| L-system | `.jff`, `.json` | `.jff`, `.json`, `.svg`, `.png` |

- **JFLAP XML** (`.jff`, `.cfg`) keeps state identity, positions, labels, and
  notes. Importing shows a preview with fidelity diagnostics; features the app
  cannot represent are listed explicitly and require consent before a lossy
  import.
- **Turing Lab JSON** is the versioned native format and round-trips every
  document feature, including document extensions and notes. Manual
  conversion drafts are not part of the file: they are kept locally in the
  app's preferences store, keyed by workspace, and are not restored from JSON.
- **SVG** is a vector rendering of the diagram or derivation; **PNG** is a
  raster rendering available on native platforms (on the web use SVG).
- Imports are transactional: the current document is replaced only after the
  file decodes successfully, and undo restores the previous document.
- On Apple platforms, files are read and written only where you choose them in
  the system picker; nothing leaves the device (see
  [docs/DATA_FLOW.md](docs/DATA_FLOW.md)).

---

### 12.3 Printing

Every workspace's file operations panel has a **Print** command. Diagram
workspaces (finite automata, pushdown automata, Turing machines, context-free
grammars, Mealy and Moore machines) send the same vector drawing the SVG export
produces to the system print sheet as a clean page with only the document
title and the diagram. Regular expressions, pumping lemma problems,
unrestricted grammars and L-systems print a text listing of the document. The
"include notes" switch applies to the printed diagram as well. Printing uses
the operating system's print dialog (or the browser's on the web); if it
cannot open, export the document as SVG or PNG and print from another
application.

## 13. Traces, history, and batch runs

- Every simulation produces a trace with the input, the verdict, the steps,
  and metadata. The last fifty traces are kept per device and the current
  trace, including the selected step, is restored on relaunch.
- The trace viewer folds long traces; expand to see every step. The step
  counter opens a dialog to jump to a step number; invalid numbers are
  rejected without changing the selection.
- **Batch execution** runs many inputs against the current automaton,
  grammar, or transducer with configurable concurrency, progress, stop on first
  failure, and a results table that can be exported.
- Trace history can be exported and imported as JSON for backups or for
  sharing between devices.

---

## 14. Keyboard shortcuts and accessibility

With a physical keyboard and focus outside a text field:

| Shortcut | Action |
| --- | --- |
| `A` | Add state mode |
| `T` | Transition mode |
| `V` | Selection mode |
| `Delete` / `Backspace` | Remove the selected state or transition |
| `Ctrl+Z` / `Cmd+Z` | Undo |
| `Ctrl+Y`, `Cmd+Y`, `Ctrl+Shift+Z`, `Cmd+Shift+Z` | Redo |
| `Escape` | Back to selection mode, or close the current dialog |
| `Enter` in a simulation field | Run the simulation |
| `Tab` / `Shift+Tab` | Move through controls |

Screen readers receive labelled controls, live announcements for step changes
and new results, and grouped before/after snapshots in transformation
histories. Every layout is verified at 320 px width and 200 percent text
scale. Tooltips identify controls; they are never the only way to learn a
shortcut.

---

## 15. Troubleshooting

| Symptom | What it means | What to do |
| --- | --- | --- |
| "Invalid input symbol" | The word uses a symbol outside the alphabet | Check the transition labels or the declared alphabet |
| Simulation reports timeout or a limit | The run is inconclusive, not rejected | Simplify the machine, shorten the input, or raise the limit where the panel allows it |
| Conflicts counter is not zero | The automaton is nondeterministic | Use NFA to DFA, or keep it as an NFA and inspect branches |
| Grammar parser rejects the strategy | The grammar lacks the required form | Convert to CNF for CYK; check the LL(1) table for conflicts |
| Import preview lists compatibility changes | The file uses features the app maps differently | Read the fidelity notes before confirming |
| Canvas seems empty | The view drifted | Use fit to content or reset view |
| Example does not load | The asset failed to decode | Reinstall the app or report the example name |

---

## 16. Suggested classroom sequences

1. **Regular languages (two sessions):** build a DFA from an example, run
   the suggested and commented inputs, convert an NFA with subset
   construction and read the step report, then finish with the pumping lemma
   game on `aⁿbⁿ`.
2. **Context-free languages:** write a grammar, parse with Earley, watch a
   user-controlled derivation, convert to CNF and parse with CYK, then build
   the PDA through the guided construction.
3. **Computability:** run the single-tape examples, compare time and space
   profiles, compose building blocks, and convert a machine to an unrestricted
   grammar.
4. **Machines with output:** contrast the Mealy and Moore sequence detectors
   on the same inputs and discuss the empty-word difference.

---

## 17. Further reading in this repository

- [docs/FORMAL_SYSTEM_MODULES.md](docs/FORMAL_SYSTEM_MODULES.md): how
  workspaces, codecs, and examples are registered.
- [docs/JFLAP_PARITY_MATRIX.md](docs/JFLAP_PARITY_MATRIX.md): capability by
  capability comparison with JFLAP, including intentional deviations.
- [docs/JFLAP_COMPATIBILITY.md](docs/JFLAP_COMPATIBILITY.md): file-format
  details.
- [docs/reference-deviations.md](docs/reference-deviations.md): where an
  algorithm intentionally differs from its reference implementation.
- [docs/PERSISTENCE.md](docs/PERSISTENCE.md) and
  [docs/DATA_FLOW.md](docs/DATA_FLOW.md): what is stored on the device.
- [docs/GRAPHVIEW_PERFORMANCE.md](docs/GRAPHVIEW_PERFORMANCE.md): canvas
  rendering budgets.
- [AGENTS.md](AGENTS.md) and [CONTRIBUTING.md](CONTRIBUTING.md): how the
  project is tested and how to contribute.
