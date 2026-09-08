# Mealy and Moore Conversions

Date: 2026-09-06 (#437)

Turing Lab converts between Mealy and Moore machines as a product extension:
JFLAP 7.1 edits and simulates both but registers no conversion action, so
this capability is recorded in the parity matrix as an addition, not as
parity.

## Equivalence contract

Two deterministic transducers are equivalent when they produce the same
output word for every input word over the same input alphabet, under the
emission rules the simulators already use:

- A **Mealy machine** emits the output of each transition it takes. For the
  empty word it emits nothing.
- A **Moore machine** emits the output of its initial state before reading
  any symbol, then the output of every target state it enters. For the empty
  word it emits the initial state's output.

This is exactly the relation `TransducerEquivalenceComparator` checks, so a
conversion is "exact" when the comparator would report the machines as
equivalent for every word, including the empty one.

Consequences of the contract:

| Case | Mealy → Moore | Moore → Mealy |
| --- | --- | --- |
| Empty word | Exact: the constructed Moore initial state has empty output. | Exact only when the Moore initial output is empty. |
| Non-empty Moore initial output | n/a | Not expressible: a Mealy machine cannot emit before reading. The converter still builds the Mealy machine that agrees on every input after the initial output and reports `conventionDifference` with the dropped prefix, so nothing is discarded silently. |
| Missing transitions (partial machines) | Kept missing; the converted machine is undefined on the same input prefixes. Exact on the defined domain. | Same. |
| Several transitions into one state with different outputs | Handled by splitting the state into one copy per distinct incoming output word. | n/a: the Moore state output moves onto every incoming transition. |
| Empty outputs on transitions or states (the empty word, written `λ` here and shown with the configured empty-string glyph in the app) | Preserved as empty words. | Preserved. |
| Nondeterministic or structurally invalid machine | Refused with the analyzer's diagnostics. | Refused likewise. |

## Constructions

**Mealy → Moore.** For every state `q` create the copy `(q, λ)` and one copy
`(q, o)` for every distinct output word `o` carried by a transition into
`q`. Copy `(q, o)` has Moore output `o`. Every Mealy transition
`p --a/o--> q` becomes, for every existing copy `(p, o')`, the Moore
transition `(p, o') --a--> (q, o)`. The initial state is `(q0, λ)`; copies
that no transition reaches are dropped. The result has at most
`|Q| + |T|` states and at most `|T| × (1 + max incoming outputs)`
transitions, and its output on every word equals the Mealy output because
each Moore state is entered only through transitions carrying its output and
the initial output is empty.

**Moore → Mealy.** States are kept one to one (without their outputs) and
every Moore transition `p --a--> q` becomes `p --a/out(q)--> q`. The output
on any word `w = a1…an` is `out(q1)…out(qn)`, which is the Moore output minus
the initial `out(q0)`; the conversion is exact when `out(q0)` is empty and
otherwise reports the dropped prefix as a convention difference.

## Evidence

Unit tests cover the empty word, a non-empty initial output, missing
transitions, several incoming outputs, and empty outputs, and compare the
converted machine with the source through the exact comparator when both
are complete and through the bounded comparator (all words up to length 4)
otherwise. Bounded comparisons are evidence for the tested words, not a
proof for every word; the constructions above carry the proof.

The conversion panel checks words up to length 4 with a limit of 2,000 words,
generated lazily. It yields to the UI between batches and cancels pending
checks when the source document changes or the panel closes. If the word
limit stops the check, the panel explicitly reports partial coverage; it does
not imply that every word through length 4 was checked.
