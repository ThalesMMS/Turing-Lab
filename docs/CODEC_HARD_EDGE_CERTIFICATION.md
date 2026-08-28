# Codec and conversion hard-edge certification

Issue #340 is certified locally by the `codec` hard-edge family. The family is
offline, deterministic, and never reports remote verification.

## Inventory and properties

The runtime registry currently exposes 22 codecs. The stable list lives in
`tool/hard_edge/families/codec_matrix.dart`; its test compares it with the live
registry and fails when a codec is added without certification. Every codec is
checked for approved corpus fidelity, malformed and resource-limited input,
wrong-extension handling, and deterministic transport round trips. Each JSON
codec also checks its committed historical/raw shape, unknown fields, future
schema rejection, and idempotent re-encoding. Pumping Lemma JSON preserves
unknown top-level fields in its extension sidecar and re-emits them exactly.

The same matrix records these non-registry boundaries and their focused
evidence. The codec runner executes one command per boundary with a bounded
timeout. Cancellation or timeout terminates the whole subprocess tree and is a
typed failure; evidence is never copied from an aggregate command:

- active-session snapshots and provider persistence;
- FSA, PDA, and TM GraphView endpoint rebinding;
- FSA, PDA, TM, grammar, and regex example/file mappers;
- automaton fragment preparation;
- SVG, transducer SVG/PNG, and variable-dependency graph export;
- FSA↔regex and FSA↔regular-grammar conversions;
- CFG→PDA general, standard, Greibach, LL, and LR constructions plus PDA→CFG;
- TM→unrestricted-grammar construction.

The approved 59-case compatibility corpus supplies field-level exact,
normalized, lossy, malformed, resource, and unsupported expectations. Generated
cases use their seed to select corpus order, nesting and collection excess,
malformed markers, transport copy count, and extension tokens. Every generated
fixture also materializes the actual canonical XML or JSON bytes that the
property executes. The structure-aware shrinker reduces those bytes and accepts
a candidate only when the exact codec/property/message failure signature is
unchanged. An empty payload is the verified minimum for the committed transport
failure shape.

## Mutation threshold

Four executable adapter mutations run production decode paths through the same
properties as the canonical codec: normalizing a future schema before decode,
discarding the decoded extension sidecar, corrupting transported bytes, and
rebuilding a successful outcome with escalated fidelity. A
mutation is killed only when the canonical property passes and the mutated
observation fails it. The threshold is 4/4 killed with zero survivors.
Production codec APIs do not expose mutation switches.
The independently authored operator corpus and license are under
`test/fixtures/hard_edge/codec/`.

## Resource and fidelity behavior

The central registry enforces descriptor byte, JSON depth/collection, and XML
DTD/depth/element budgets before invoking any codec sniffer. Codecs repeat the
relevant checks before model construction. Malformed, unsupported, and
resource-limited inputs
remain distinct typed outcomes; bounded semantic comparisons remain unknown and
are never rewritten as rejection. Imports and conversions are exercised through
immutable snapshots so a failed decode or conversion cannot partially update a
provider document.

Native/web parity uses all 22 canonical codec inputs. The committed vectors in
`tool/hard_edge/families/codec_parity_vectors.dart` contain the input bytes and
a SHA-256 digest of the canonical VM decode/encode/replay outcome. The Chrome
test executes every codec and compares its semantic outcome with that VM
snapshot. JSON numeric spellings such as `1` and `1.0` are normalized before
comparison. Codec-generated FNV-1a IDs use exact modulo-2^32 multiplication.
Canonical identity version 1 remains byte-compatible for integers representable
exactly by JavaScript. Inputs containing larger VM integers use the typed
version 2 envelope, preserving their decimal value instead of collapsing
through a `double`; compatibility and collision vectors cover both forms.

JFLAP 7.1 is a behavioral reference, not a byte oracle. Relevant anchors are
`../JFLAP/file/XMLCodec.java`, the transducers under `../JFLAP/file/xml/`,
`../JFLAP/grammar/convert/`, `../JFLAP/pda/PDAToCFGConverter.java`,
`../JFLAP/grammar/parse/`, and `../JFLAP/gui/action/CombineAutomaton.java`.
Turing Lab intentionally adds typed fidelity reports, explicit security limits,
stable IDs, token vectors, cancellation, and bounded-unknown outcomes.

## Local commands

```text
dart run tool/hard_edge/families/codec_cases.dart matrix
dart run tool/hard_edge/families/codec_cases.dart run --seed 340 --output build/hard-edge/codec
dart run tool/hard_edge/families/codec_cases.dart mutate
flutter test test/unit/tool/hard_edge_codec_family_test.dart
dart test -p chrome test/unit/tool/hard_edge_codec_web_parity_test.dart
dart run tool/hard_edge/generate_codec_parity_vectors.dart
```

The Chrome command is a separate browser-platform result. A missing or stalled
browser is `not_run`, never a pass. Generated reports include codec, property,
seed, fidelity coverage, mutation threshold, survivor count, and
`remotelyVerified: false`.
