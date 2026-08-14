# Turing Lab Legal Distribution Determination

This document is the authoritative project record for Turing Lab distribution
rights and constraints. It adopts the conservative position that Turing Lab is a
derivative work of JFLAP where it includes JFLAP-derived behavior, structures,
file compatibility, algorithms, or user-facing educational concepts.

## JFLAP-Derived Content Analysis

Turing Lab includes original Flutter implementation work and JFLAP-derived
content. The following shipped components are treated as JFLAP-derived or
JFLAP-compatible for license compliance purposes:

- JFLAP XML automaton compatibility handled by `JflapXmlCodec`.
- JFLAP grammar DTOs, including `JflapGrammarDto`,
  `JflapGrammarStructureDto`, and `JflapProductionDto` (`grammar_dto`).
- JFLAP Turing machine DTOs, including `JflapTuringMachineDto`,
  `JflapTuringStructureDto`, and `JflapTuringTransitionDto`
  (`turing_machine_dto`).
- The JFLAP XML parser (`jflap_xml_parser`).
- Serialization and import/export services that read or write JFLAP-compatible
  XML, including `serialization_service`, `file_operations_service_io`, and
  `file_operations_service_web`.
- JFLAP `.jff` file format compatibility, including support for JFLAP
  `<structure>`, `<type>`, `<automaton>`, state, transition, epsilon, grammar,
  and Turing machine representations.
- Algorithm concepts, workflows, and educational behavior derived from or
  intentionally compatible with JFLAP, including automata construction,
  simulation, transformations, grammar workflows, PDA workflows, Turing machine
  workflows, and help/documentation structure.
- Offline examples and interoperability tests that validate compatibility with
  JFLAP-style data and user workflows.

Because these components are central to the shipped product, Turing Lab must be
distributed as a product that includes modified JFLAP-derived material for
purposes of the JFLAP 7.1 License.

## App Store Distribution Determination (Apple and Google)

Free Apple App Store and Google Play Store distribution is compatible with the
JFLAP 7.1 License under the project's conservative legal posture.

The JFLAP 7.1 License permits distribution of modified copies when the license
text is included, no fee is charged for any product that includes JFLAP-derived
material, and maintainer disclosure obligations are honored. For Turing Lab, the
"no fee" clause is interpreted as targeting end-user product pricing and
product monetization, not platform hosting costs, developer program costs, or
store infrastructure costs that are not charged to users as a condition of
accessing Turing Lab.

Therefore:

- Turing Lab may be distributed on the Apple App Store and Google Play Store only
  as a free app.
- Store listing price must be zero.
- App access must not require a purchase, subscription, paid entitlement, or
  other user-paid fee.
- The release must continue to include and expose the JFLAP 7.1 License text.

## Legal Disclaimer

This document reflects the Turing Lab project's non-legal interpretation of the
JFLAP 7.1 License and is not legal advice. Contributors should consult
qualified legal counsel for license compliance, distribution strategy, and
monetization questions.

## Monetization Constraints

Turing Lab must not generate revenue from the product while it includes
JFLAP-derived material.

The following are prohibited:

- Paid App Store pricing or paid downloads.
- In-app purchases.
- Subscriptions.
- Advertising, sponsorship placements, affiliate links, tracking-based ad
  monetization, or other ad-supported distribution.
- Paid feature unlocks, paid exports, paid example packs, paid cloud sync, paid
  support tiers attached to app functionality, or any other revenue generation
  tied to the product.
- Bundling Turing Lab with another paid product where access to Turing Lab is part
  of the paid value.

Any future monetization plan requires either removal of all JFLAP-derived
material or separate written permission from the JFLAP maintainer or other
appropriate rights holder before release.

## License Compliance Requirements

Every distributed binary or package must comply with both license tracks:

- Turing Lab's original Flutter code remains under the Apache License 2.0 in
  `LICENSE.txt`.
- JFLAP-derived portions remain subject to the JFLAP 7.1 License in
  `LICENSE_JFLAP.txt`.
- `LICENSE_JFLAP.txt` must be bundled with all distributed binaries and remain
  accessible to users.
- `LICENSE.txt` must also be bundled or otherwise accessible to users.
- Source distributions and release archives must include both license files.
- App Store metadata must not imply JFLAP, Susan H. Rodger, Duke University, or
  the JFLAP team endorses Turing Lab.
- Any release notes or marketing copy must preserve the distinction between
  Turing Lab and the original JFLAP project.

## Vendored Graphview Fork

Turing Lab also distributes a vendored fork of `graphview` from `graphview/`.

- License: MIT, preserved in `graphview/LICENSE`.
- Current vendored package version: `1.5.2` from the in-repo path dependency.
- In-app attribution is provided through the Licenses section in
  `lib/presentation/pages/licenses_help_content.dart`, with the bundled asset
  `assets/LICENSE_GRAPHVIEW.txt`.
- The MIT license terms are compatible with Turing Lab's free, non-monetized App
  Store distribution posture.
- The vendored graphview fork does not add a conflicting copyleft,
  attribution, or monetization restriction beyond preserving the MIT notice in
  shipped copies and substantial portions of the fork.

## JFLAP Maintainer Contact

The JFLAP 7.1 License requires modified distributions to clearly describe how
to contact the modifier and to provide modified source to the maintainer without
fee when requested.

Current JFLAP maintainer contact from `LICENSE_JFLAP.txt`:

- Susan H. Rodger
- Email: jflap@cs.duke.edu

Current Turing Lab modifier contact from `README.md`:

- Thales Matheus Mendonca Santos
- Email: thalesmmsradio@gmail.com

If Susan H. Rodger or the current JFLAP maintainer requests the modified JFLAP
materials distributed in Turing Lab, the project must provide the relevant source
code and modifications without fee.

## In-App License Attribution Requirements

Before distribution, the app must make license and attribution information
visible to users:

- The app's About, Settings, Help, or equivalent license screen must display
  both the Apache License 2.0 text and the JFLAP 7.1 License text, or provide
  direct in-app access to both bundled texts.
- JFLAP attribution must be visible in acknowledgments:
  - Susan H. Rodger, Duke University.
  - JFLAP team contributors listed in `LICENSE_JFLAP.txt`.
  - The original JFLAP project website, `http://www.jflap.org`.
- The app must state that Turing Lab is a Flutter reimplementation inspired by
  and compatible with JFLAP, not an official JFLAP release.
- The current in-app attribution location is
  `lib/presentation/pages/help_page.dart`, with content implemented in
  `lib/presentation/pages/help_page_content.dart`.

These requirements are release-blocking for App Store distribution.
