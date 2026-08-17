# Turing Lab Website Design

## Context

Turing Lab has a public GitHub Pages URL at
`https://thalesmms.github.io/Turing-Lab/`, but the deployed page still presents
the former JFlutter name. GitHub Pages currently publishes the root of the
legacy `gh-pages` branch, while the maintained `main` branch already contains
Turing Lab versions of the landing, support, and privacy pages under `docs/`.

The website must describe an in-progress technical project. Apple and Android
builds are undergoing testing. Web, Windows, and Linux are experimental
targets. The site must not imply that store releases or stable downloads are
available.

## Goals

- Publish a concise, English-language technical overview of Turing Lab.
- Describe supported formal-language models and the implemented workflows
  without promotional slogans or unsupported claims.
- Show current platform maturity explicitly.
- Reuse real application screenshots and the canonical project icon.
- Preserve direct access to support, privacy, source, documentation, and issue
  reporting.
- Make the maintained `docs/` directory the source of the public GitHub Pages
  site so the deployed content cannot continue drifting from `main`.

## Non-Goals

- Do not embed or deploy the Flutter web application as the landing page.
- Do not add a JavaScript framework, static-site generator, package manager, or
  build tool.
- Do not add analytics, cookies, forms, accounts, or network-backed features.
- Do not advertise App Store or Google Play availability while builds are in
  testing.
- Do not add a blog, tutorial system, download service, or API documentation
  portal.
- Do not delete the legacy `gh-pages` branch as part of this work.
- Do not rewrite the substantive support or privacy policy content.

## Technical Approach

Continue using static HTML and CSS in `docs/`. The homepage remains a single
document with internal section links. Assets required by GitHub Pages live
under `docs/assets/`; the page must not depend on repository files outside the
published `docs/` directory.

Use semantic HTML without a client-side application runtime. JavaScript is not
required for the approved scope. Responsive behavior, status labels, layout,
and decorative state-transition motifs are implemented in CSS. Support light
and dark system color schemes through `prefers-color-scheme`; do not add a
manual theme control or continuous animation.

The initial implementation is expected to touch:

- `docs/index.html` for the landing-page structure and metadata;
- `docs/assets/site.css` for shared landing-page styles;
- `docs/assets/` for an optimized project icon and selected screenshots;
- `docs/support.html` and `docs/privacy.html` only for canonical repository or
  Pages URL corrections;
- `README.md`, `pubspec.yaml`, and `docs/BRANDING.md` for canonical public URL
  migration;
- repository Pages settings, changing the publishing source to `main` and
  `/docs` after the content change is merged.

No repository workflow is required for the approved static site. Publishing
directly from `main/docs` is the simplest source-of-truth model. The settings
change is an explicit deployment step and must be verified separately from the
repository commit.

## Information Architecture

The homepage uses the following order.

### 1. Header

Display the project icon and `Turing Lab` name. Provide compact navigation to
`Overview`, `Capabilities`, `Platforms`, and `Screenshots`, followed by external
or secondary links to `Documentation` and `GitHub`.

The header must remain usable on narrow screens without a JavaScript menu. Its
navigation links wrap into additional rows as space decreases; do not add a
custom menu or disclosure control.

### 2. Project Overview

Use factual copy rather than a slogan:

> **Turing Lab**
>
> A Flutter-based toolkit for constructing, transforming, and simulating
> formal language models.
>
> It provides dedicated workspaces for finite-state automata, context-free
> grammars, pushdown automata, Turing machines, and regular expressions.

Show the status statement near the overview:

> **Development status:** Apple and Android builds are currently under testing.

Primary actions are `View source`, `Read documentation`, and `Report an issue`.
Do not use download or store buttons.

Pair the overview with one real application screenshot. The image must have
descriptive alternative text and must not be placed inside an artificial
device mockup.

### 3. Supported Models and Capabilities

Present a semantic table on wide screens and an equivalent readable stacked
layout on narrow screens. Use the columns `Workspace`, `Editing`, `Simulation`,
`Transformations`, and `Import/export`.

The rows cover:

- finite-state automata;
- context-free grammars;
- pushdown automata;
- Turing machines;
- regular expressions.

Every cell must be derived from implemented repository behavior. Unsupported
or inapplicable capabilities are shown as `Not applicable` rather than an
ambiguous dash. The implementation pass must cross-check exact transformation
and format names against `README.md`, `V1_SCOPE.md`, and the corresponding
workspace code before publishing the table.

### 4. Algorithms and Simulation

Describe the available algorithm and simulation workflows as technical
capabilities. Organize them under descriptive headings such as finite-automata
transformations, grammar analysis, and execution traces. Avoid adjectives such
as `powerful`, `advanced`, `intuitive`, or `revolutionary`.

Claims must name observable behavior. Examples include step-by-step execution,
state or transition highlighting, stack traces, tape traces, and supported
automata conversions. Do not publish algorithm counts unless the count is
generated from or manually verified against the current implementation.

### 5. File Formats and Offline Operation

State that supported workflows operate locally and do not require an account
or developer-operated backend. List only verified import and export formats.
Describe `.jff` behavior as compatibility with supported JFLAP structures, not
as universal compatibility with every JFLAP file or feature.

Link to the privacy policy and the repository data-flow documentation for the
full data-handling description.

### 6. Platform Status

Use an explicit status table:

| Platform | Status |
| --- | --- |
| iOS and iPadOS | Testing |
| macOS | Testing |
| Android | Testing |
| Web | Experimental |
| Windows | Experimental |
| Linux | Experimental |

Follow it with this qualification:

> Testing builds are undergoing platform validation and release preparation.
> Experimental targets may have incomplete platform integration and are not
> part of the current release scope.

Status must be text, not color alone. The page must not display version numbers,
store badges, or download links until those values have a maintained source of
truth.

### 7. Screenshots

Use a small responsive gallery of real application captures. Derive the images
from `screenshots/app_store/macos/01-fsa.png`,
`screenshots/app_store/macos/02-grammar.png`, and
`screenshots/app_store/macos/04-tm.png`. This App Store set uses a controlled
viewport size and consistent content.

Create web-optimized copies inside `docs/assets/screenshots/`. Preserve useful
detail in the canvas and side panels, provide intrinsic width and height, and
use lazy loading for images below the fold. Do not publish golden-test output
or screenshots that expose debugging artifacts.

### 8. Project Links and Footer

Provide links to:

- the canonical GitHub repository;
- the README and project documentation;
- GitHub Issues;
- support information;
- the privacy policy;
- license and citation information.

Retain the existing statement that Turing Lab is inspired by JFLAP and is not
affiliated with or endorsed by JFLAP, Duke University, or Susan H. Rodger.

## Visual Direction

Use a restrained technical presentation derived from the application rather
than a separate marketing identity:

- neutral system or locally available sans-serif typography;
- a navy header and overview area derived from the project icon in light mode;
- near-white content surfaces with the application's blue accent in light mode;
- near-black page surfaces and muted dark panels in dark system mode;
- cyan used sparingly for focus, status, and diagram accents;
- square or modestly rounded panels consistent with Material 3;
- subtle automaton-state or transition-line decoration implemented as
  non-semantic CSS or SVG imagery.

Avoid gradients behind body copy, oversized slogans, glowing text, simulated
device frames, testimonial blocks, animated counters, carousels, and stock
illustrations. Screenshots and capability tables carry the visual hierarchy.

## Content Rules

- All public page content, navigation, metadata, image descriptions, and status
  labels are in English.
- Prefer precise nouns and verbs over promotional adjectives.
- Treat testing and experimental status as product facts, not badges implying
  availability.
- Keep terminology consistent with the application and repository.
- Use `Turing Lab` as the product name and `Turing-Lab` only where the repository
  slug or URL requires it.
- Preserve required legal attribution and derivative-work notices.

## Metadata and Link Integrity

Add a descriptive page title, meta description, canonical URL, Open Graph
metadata, favicon, and social-preview image. Metadata must use the canonical
Turing Lab name and the `/Turing-Lab/` Pages path.

Replace obsolete public locators after the external migration is active:

- `https://thalesmms.github.io/JFlutter/` becomes
  `https://thalesmms.github.io/Turing-Lab/`;
- `https://github.com/ThalesMMS/jflutter` becomes
  `https://github.com/ThalesMMS/Turing-Lab`.

Relative links are preferred for pages and assets within `docs/` so the site
continues to work under the repository subpath. External links use the current
canonical repository URL.

## Data Flow and Failure Behavior

The landing page is read-only and has no application data flow. It loads static
HTML, CSS, and image assets from GitHub Pages and sends no visitor data to a
developer-operated service. There are no forms, analytics scripts, remote
fonts, third-party embeds, or cookies.

If an image fails to load, its alternative text still identifies the depicted
workspace. If CSS fails, semantic document order and native links remain
usable. External links are ordinary anchors and do not require client-side
error handling.

## Accessibility and Responsive Requirements

- Meet WCAG AA contrast for body text, links, focus indicators, and status
  labels.
- Provide a visible keyboard focus state and a skip link.
- Use landmarks and one logical `h1` hierarchy.
- Give informative screenshots descriptive alternative text and mark purely
  decorative diagrams as hidden from assistive technology.
- Preserve readable tables on narrow screens without requiring two-dimensional
  page scrolling.
- Keep interactive targets at least 44 CSS pixels high where layout permits.
- Verify the page at phone, tablet, and desktop widths and in light and dark
  system modes.

## Verification

Before changing Pages settings:

- validate HTML structure and inspect the page with JavaScript disabled;
- check all internal and external links;
- verify every capability and format claim against current repository behavior;
- inspect responsive layouts at representative phone, tablet, and desktop
  widths;
- test keyboard navigation, focus visibility, heading order, alternative text,
  and contrast;
- confirm no network requests are made beyond the GitHub Pages origin;
- run `./tool/check_branding.sh` and `git diff --check`;
- confirm obsolete JFlutter URLs remain only in permitted historical records.

Flutter QA is not required for static HTML and metadata changes unless the
implementation also changes Flutter application code or bundled application
assets.

After merging, configure GitHub Pages to publish `main` and `/docs`, then verify:

- `https://thalesmms.github.io/Turing-Lab/` serves the new English homepage;
- the page title and visible product name are `Turing Lab`;
- support and privacy URLs return successfully;
- the repository, issue, privacy, support, and documentation links resolve to
  their canonical targets;
- the deployed source no longer depends on the stale `gh-pages` content.

## Alternatives Considered

### Flutter Web landing page

Rejected. The marketing and project-overview surface does not need the Flutter
runtime, and using it would increase load cost and complicate semantic HTML,
metadata, and no-JavaScript resilience. A future Flutter web build can be
published as a separate experimental application target.

### Static-site generator

Deferred. Astro or a documentation-oriented generator would be reasonable if
the site later grows into tutorials, release notes, or a large documentation
hierarchy. The approved scope is three existing static pages and does not
justify another toolchain.

### Continue publishing the legacy `gh-pages` branch

Rejected. It has already drifted from the maintained product name and duplicates
content outside the default branch. Publishing `main/docs` makes review and
deployment source alignment explicit.

## Success Criteria

- The public homepage is a technically written English overview with no
  promotional slogan.
- Apple platforms and Android are labeled `Testing`; Web, Windows, and Linux
  are labeled `Experimental`.
- Supported workspaces, algorithms, simulations, and formats are described only
  with repository-verified claims.
- The page uses real optimized application screenshots and remains usable
  without JavaScript.
- Support, privacy, source, documentation, issue, license, and citation links
  are present and correct.
- The page introduces no analytics, cookies, forms, remote fonts, or third-party
  embeds.
- GitHub Pages publishes the maintained `main/docs` content at the canonical
  `/Turing-Lab/` URL.
- Branding and link-integrity checks find no unintended legacy public locator.
