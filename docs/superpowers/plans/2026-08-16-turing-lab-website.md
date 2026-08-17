# Turing Lab Website Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Replace the stale GitHub Pages landing page with a technical, English-language Turing Lab site that documents capabilities, platform maturity, offline behavior, screenshots, and canonical project links.

**Architecture:** Keep the public site as semantic static HTML and CSS under `docs/`, with no JavaScript runtime or external resources. Add a focused Dart contract test for content, assets, metadata, and link integrity; generate optimized local image assets from the repository's existing icon and controlled macOS screenshots.

**Tech Stack:** HTML5, CSS3, Dart `package:test`, Python Pillow for one-time image optimization, GitHub Pages publishing from `main/docs`.

**Spec:** `docs/superpowers/specs/2026-08-16-turing-lab-website-design.md`

## Global Constraints

- All public page content, navigation, metadata, image descriptions, and status labels are in English.
- Copy is technical and factual; do not add a promotional slogan or unsupported capability claim.
- Apple platforms and Android use the status `Testing`; Web, Windows, and Linux use `Experimental`.
- Include FSA, Grammar, PDA, TM, Regex, and Pumping Lemma as required by `V1_SCOPE.md`.
- Do not add JavaScript, analytics, cookies, forms, remote fonts, third-party embeds, download links, or store badges.
- Use `Turing Lab` as the product name and `Turing-Lab` only for the repository slug or URL.
- Preserve the existing JFLAP attribution and non-affiliation notice.
- Do not delete or modify the legacy `gh-pages` branch during repository implementation.
- Do not stage or commit the user's concurrent changes in `README.md`, `pubspec.yaml`, `.gitignore`, `PROJECT_STRUCTURE.md`, `.github/workflows/ci.yml`, `.project_doc_record/`, `output/`, `CONTRIBUTING.md`, or `SECURITY.md`.

## File Structure

- Create `test/website/site_contract_test.dart`: focused static-site contract tests for approved copy, statuses, metadata, asset locality, and canonical URLs.
- Modify `docs/index.html`: semantic landing-page content and metadata only; all styling moves to the site stylesheet.
- Create `docs/assets/site.css`: responsive light/dark layout, navigation, tables, screenshots, status labels, focus states, and decorative automaton geometry.
- Create `docs/assets/favicon.png`: 64 px optimized icon derived from `icon.png`.
- Create `docs/assets/icon-192.png`: 192 px site identity image derived from `icon.png`.
- Create `docs/assets/social-preview.png`: 1200×630 technical social preview derived from the icon and approved overview copy.
- Create `docs/assets/screenshots/fsa.webp`: web-optimized copy of `screenshots/app_store/macos/01-fsa.png`.
- Create `docs/assets/screenshots/grammar.webp`: web-optimized copy of `screenshots/app_store/macos/02-grammar.png`.
- Create `docs/assets/screenshots/tm.webp`: web-optimized copy of `screenshots/app_store/macos/04-tm.png`.
- Modify `docs/support.html`: replace obsolete repository links only.
- Modify `docs/privacy.html`: replace the obsolete GitHub Pages privacy-audit link only.
- Modify `docs/BRANDING.md`: remove migrated public repository and Pages locators from the compatibility-only list and record the canonical locations.

---

### Task 1: Add the Static-Site Contract Test

**Files:**
- Create: `test/website/site_contract_test.dart`
- Read: `docs/index.html`
- Read: `docs/support.html`
- Read: `docs/privacy.html`

**Interfaces:**
- Consumes: static files rooted at `docs/` and the canonical URLs in the approved spec.
- Produces: a focused `flutter test test/website/site_contract_test.dart` gate used by every later task.

- [ ] **Step 1: Write helpers for loading HTML and resolving local assets**

Create a Dart test using `dart:io` and `package:test/test.dart`. Resolve the repository from `Directory.current`, load `docs/index.html`, and define this helper for local targets:

```dart
Iterable<String> localTargets(String html) sync* {
  final attributePattern = RegExp(r'''(?:href|src)=["']([^"']+)["']''');
  for (final match in attributePattern.allMatches(html)) {
    final target = match.group(1)!;
    if (target.startsWith('#') ||
        target.startsWith('https://') ||
        target.startsWith('mailto:')) {
      continue;
    }
    yield target.split('#').first.split('?').first;
  }
}
```

- [ ] **Step 2: Add the approved-content test**

Assert that `docs/index.html` contains:

```dart
expect(index, contains('A Flutter-based toolkit for constructing, transforming, and simulating formal language models.'));
expect(index, contains('Apple and Android builds are currently under testing.'));
for (final platform in ['iOS and iPadOS', 'macOS', 'Android']) {
  expect(index, contains(platform));
}
for (final platform in ['Web', 'Windows', 'Linux']) {
  expect(index, contains(platform));
}
for (final workspace in [
  'Finite-state automata',
  'Context-free grammars',
  'Pushdown automata',
  'Turing machines',
  'Regular expressions',
  'Pumping lemma',
]) {
  expect(index, contains(workspace));
}
expect(index, isNot(contains('JFlutter')));
expect(index, isNot(contains('<script')));
```

Also assert three `Testing` status cells and three `Experimental` status cells with a table-row regular expression rather than raw word counts.

- [ ] **Step 3: Add metadata, accessibility, and local-resource tests**

Assert the canonical URL, Open Graph title/description/image, favicon, stylesheet, skip link, `main` landmark, exactly one `<h1`, and descriptive `alt`, numeric `width`, and numeric `height` attributes on every image. Assert that below-fold screenshot images contain `loading="lazy"`.

Use these exact structural assertions:

```dart
expect(index, contains('<link rel="canonical" href="https://thalesmms.github.io/Turing-Lab/">'));
expect(index, contains('<meta property="og:image" content="https://thalesmms.github.io/Turing-Lab/assets/social-preview.png">'));
expect(index, contains('<a class="skip-link" href="#main-content">Skip to content</a>'));
expect(RegExp(r'<main\b').allMatches(index), hasLength(1));
expect(RegExp(r'<h1\b').allMatches(index), hasLength(1));

final images = RegExp(r'<img\b[^>]*>').allMatches(index).map((match) => match.group(0)!);
for (final image in images) {
  expect(image, matches(RegExp(r'''\balt=["'][^"']+["']''')));
  expect(image, matches(RegExp(r'''\bwidth=["']\d+["']''')));
  expect(image, matches(RegExp(r'''\bheight=["']\d+["']''')));
}
for (final screenshot in ['grammar.webp', 'tm.webp']) {
  expect(index, matches(RegExp('<img[^>]+$screenshot[^>]+loading="lazy"')));
}
```

For every value returned by `localTargets(index)`, resolve it below `docs/` and assert `File.existsSync()`. Assert that every `src` value is relative, preventing third-party resource loads.

- [ ] **Step 4: Add canonical-link tests across all public HTML**

Load `index.html`, `support.html`, and `privacy.html`. Assert none contains the obsolete Pages or repository locators and assert the support page contains:

```dart
expect(support, contains('https://github.com/ThalesMMS/Turing-Lab/issues'));
expect(support, contains('https://github.com/ThalesMMS/Turing-Lab#readme'));
expect(privacy, contains('https://thalesmms.github.io/Turing-Lab/APP_PRIVACY_APPLE.md'));
```

- [ ] **Step 5: Run the focused test and verify RED**

Run:

```powershell
flutter test test/website/site_contract_test.dart
```

Expected: FAIL because the current homepage lacks the approved overview, platform table, metadata, local assets, and canonical links.

---

### Task 2: Generate Local Web Assets

**Files:**
- Create: `docs/assets/favicon.png`
- Create: `docs/assets/icon-192.png`
- Create: `docs/assets/social-preview.png`
- Create: `docs/assets/screenshots/fsa.webp`
- Create: `docs/assets/screenshots/grammar.webp`
- Create: `docs/assets/screenshots/tm.webp`
- Source: `icon.png`
- Source: `screenshots/app_store/macos/01-fsa.png`
- Source: `screenshots/app_store/macos/02-grammar.png`
- Source: `screenshots/app_store/macos/04-tm.png`

**Interfaces:**
- Consumes: the canonical icon and three controlled macOS captures.
- Produces: stable relative asset paths and intrinsic image dimensions consumed by `docs/index.html` and the contract test.

- [ ] **Step 1: Generate the icon and screenshot derivatives**

Use the bundled Python runtime and Pillow. Create directories with
`New-Item -ItemType Directory -Force`, then run Python with these exact output rules:

```python
from pathlib import Path
from PIL import Image, ImageDraw, ImageFont

root = Path.cwd()
assets = root / "docs" / "assets"
(assets / "screenshots").mkdir(parents=True, exist_ok=True)

icon = Image.open(root / "icon.png").convert("RGBA")
icon.resize((64, 64), Image.Resampling.LANCZOS).save(assets / "favicon.png", optimize=True)
icon.resize((192, 192), Image.Resampling.LANCZOS).save(assets / "icon-192.png", optimize=True)

sources = {
    "fsa.webp": root / "screenshots" / "app_store" / "macos" / "01-fsa.png",
    "grammar.webp": root / "screenshots" / "app_store" / "macos" / "02-grammar.png",
    "tm.webp": root / "screenshots" / "app_store" / "macos" / "04-tm.png",
}
for output_name, source in sources.items():
    image = Image.open(source).convert("RGB")
    image.thumbnail((1600, 1000), Image.Resampling.LANCZOS)
    image.save(assets / "screenshots" / output_name, "WEBP", quality=84, method=6)
```

- [ ] **Step 2: Generate the 1200×630 social preview**

Extend the Pillow command with:

```python
preview = Image.new("RGB", (1200, 630), "#081722")
preview.paste(icon.resize((300, 300), Image.Resampling.LANCZOS), (72, 165), icon.resize((300, 300), Image.Resampling.LANCZOS))
draw = ImageDraw.Draw(preview)
title_font = ImageFont.truetype(r"C:\Windows\Fonts\segoeuib.ttf", 72)
body_font = ImageFont.truetype(r"C:\Windows\Fonts\segoeui.ttf", 36)
draw.text((430, 210), "Turing Lab", fill="#FFFFFF", font=title_font)
draw.text((434, 310), "Formal language and automata toolkit", fill="#9DD7E5", font=body_font)
draw.text((434, 380), "Apple and Android: testing", fill="#C8D4DC", font=body_font)
preview.save(assets / "social-preview.png", optimize=True)
```

Keep all text inside the central 1080×510 safe area.

- [ ] **Step 3: Verify asset format, dimensions, and size**

Use Pillow to print each output's format, dimensions, and byte size. Require:

- favicon: 64×64 PNG;
- identity icon: 192×192 PNG;
- social preview: 1200×630 PNG;
- screenshots: no wider than 1600 px, WebP format, and under 350 KB each.

---

### Task 3: Implement the Technical Landing Page

**Files:**
- Modify: `docs/index.html`
- Create: `docs/assets/site.css`
- Test: `test/website/site_contract_test.dart`

**Interfaces:**
- Consumes: the relative asset paths from Task 2 and canonical project URLs.
- Produces: section anchors `overview`, `capabilities`, `formats`, `platforms`, and `screenshots`; accessible navigation and HTML metadata.

- [ ] **Step 1: Replace inline styles with metadata and the local stylesheet**

Set:

```html
<title>Turing Lab | Formal Language and Automata Toolkit</title>
<meta name="description" content="Technical overview of Turing Lab, a Flutter toolkit for formal languages, automata construction, transformations, and simulation.">
<link rel="canonical" href="https://thalesmms.github.io/Turing-Lab/">
<meta property="og:type" content="website">
<meta property="og:title" content="Turing Lab | Formal Language and Automata Toolkit">
<meta property="og:description" content="A Flutter-based toolkit for constructing, transforming, and simulating formal language models.">
<meta property="og:url" content="https://thalesmms.github.io/Turing-Lab/">
<meta property="og:image" content="https://thalesmms.github.io/Turing-Lab/assets/social-preview.png">
<link rel="icon" type="image/png" href="assets/favicon.png">
<link rel="stylesheet" href="assets/site.css">
```

Do not add a script element or remote stylesheet.

- [ ] **Step 2: Build the header and overview**

Add a skip link, a wrapping semantic navigation row, and `main`. Render `assets/icon-192.png` as the 40×40 header identity image with alt text `Turing Lab`. Use the approved factual overview copy verbatim. Add actions for GitHub source, README documentation, and Issues. Place `fsa.webp` beside the overview with descriptive alt text and intrinsic dimensions from Task 2.

- [ ] **Step 3: Build the capability matrix**

Create the six-row table with these exact capability boundaries:

| Workspace | Editing | Simulation | Transformations | Import/export |
| --- | --- | --- | --- | --- |
| Finite-state automata | State and transition canvas | Step-by-step acceptance traces | NFA/DFA/regex conversion and DFA minimisation | JFLAP XML, JSON, SVG, and native PNG |
| Context-free grammars | Grammar and production editor | Parsing and validation | FIRST/FOLLOW analysis, LL(1) diagnostics, and CNF conversion | JFLAP grammar and SVG |
| Pushdown automata | State and transition canvas | Input and stack traces | Not applicable | SVG export |
| Turing machines | State and transition canvas | Tape and transition traces | Not applicable | SVG export |
| Regular expressions | Expression editor | Match testing and comparison | Simplification and automaton conversion | Not applicable |
| Pumping lemma | Guided case workflow | Decomposition validation | Not applicable | Not applicable |

Add `data-label` attributes to table cells so CSS can present a readable stacked layout below 760 px without horizontal page scrolling.

- [ ] **Step 4: Add algorithm, file, offline, and platform sections**

Use compact technical prose and lists. Include the approved platform table and qualification verbatim. State the web PNG limitation and the PDA/TM file-support boundary. Link `privacy.html` and the repository `docs/DATA_FLOW.md` page on GitHub.

- [ ] **Step 5: Add screenshots and footer links**

Render the three Task 2 screenshots with figures and English captions. Add `loading="lazy"` to the gallery images, intrinsic sizes, and descriptive alternative text. Provide footer links to Support, Privacy, README, Issues, `LICENSE.txt`, `LICENSE_JFLAP.txt`, and `CITATION.cff`, followed by the existing JFLAP non-affiliation statement.

- [ ] **Step 6: Implement the responsive visual system**

In `site.css`, define a light palette and an automatic dark palette with `prefers-color-scheme`. Implement:

- navy overview/header surface and restrained cyan accents;
- a maximum 1180 px content width;
- wrapping 44 px navigation and action targets;
- visible `:focus-visible` outlines;
- responsive overview and screenshot grids;
- capability and platform table styling;
- stacked capability rows below 760 px;
- a non-semantic automaton-state decoration using pseudo-elements only;
- no continuous animation, gradients behind body copy, carousels, or hidden mobile navigation.

Begin from these exact tokens and breakpoints:

```css
:root {
  color-scheme: light dark;
  --page: #f4f7f9;
  --surface: #ffffff;
  --surface-muted: #eaf0f4;
  --text: #17212b;
  --muted: #536472;
  --navy: #081722;
  --accent: #226184;
  --cyan: #9dd7e5;
  --border: #ccd8df;
  --focus: #efb83f;
  --radius: 12px;
}

@media (prefers-color-scheme: dark) {
  :root {
    --page: #0c1217;
    --surface: #131c23;
    --surface-muted: #1a2730;
    --text: #edf3f6;
    --muted: #b4c2cb;
    --accent: #8dcde0;
    --border: #33434e;
  }
}

@media (max-width: 760px) {
  .capability-table thead { display: none; }
  .capability-table,
  .capability-table tbody,
  .capability-table tr,
  .capability-table td { display: block; width: 100%; }
  .capability-table td::before { content: attr(data-label); }
}
```

- [ ] **Step 7: Run the focused test and verify GREEN**

Run:

```powershell
flutter test test/website/site_contract_test.dart
```

Expected: PASS for overview copy, six modules, six platform statuses, metadata, local assets, and no script runtime.

- [ ] **Step 8: Commit the landing page and contract test**

Stage only:

```powershell
git add -f -- docs/index.html docs/assets test/website/site_contract_test.dart
git commit -m "web: add technical project landing page"
```

---

### Task 4: Migrate Public Links and Branding Records

**Files:**
- Modify: `docs/support.html`
- Modify: `docs/privacy.html`
- Modify: `docs/BRANDING.md`
- Test: `test/website/site_contract_test.dart`

**Interfaces:**
- Consumes: canonical repository `https://github.com/ThalesMMS/Turing-Lab` and Pages root `https://thalesmms.github.io/Turing-Lab/`.
- Produces: consistent public links across the maintained Pages content and branding record.

- [ ] **Step 1: Update support links**

Replace only:

```text
https://github.com/ThalesMMS/jflutter/issues
https://github.com/ThalesMMS/jflutter#readme
```

with:

```text
https://github.com/ThalesMMS/Turing-Lab/issues
https://github.com/ThalesMMS/Turing-Lab#readme
```

- [ ] **Step 2: Update the privacy audit link**

Replace `https://thalesmms.github.io/JFlutter/APP_PRIVACY_APPLE.md` with
`https://thalesmms.github.io/Turing-Lab/APP_PRIVACY_APPLE.md`. Do not change privacy-policy claims or dates.

- [ ] **Step 3: Update the branding compatibility record**

Add canonical rows for the public repository and Pages URL to the identifier table. Remove the two migrated locator bullets from `Compatibility-only legacy references`. Retain the development repository, historical release records, dated QA records, and immutable certificate identity exceptions.

- [ ] **Step 4: Run focused website and branding checks**

Run:

```powershell
flutter test test/website/site_contract_test.dart
& 'C:\Program Files\Git\usr\bin\bash.exe' ./tool/check_branding.sh
git diff --check
```

Expected: focused test PASS, `Turing Lab branding audit passed`, and no whitespace errors.

- [ ] **Step 5: Commit only maintained Pages link changes**

Stage only:

```powershell
git add -f -- docs/support.html docs/privacy.html docs/BRANDING.md
git commit -m "docs: migrate public Turing Lab links"
```

Do not stage concurrent URL updates already present in `README.md` or `pubspec.yaml`.

---

### Task 5: Local Browser and Repository Verification

**Files:**
- Verify: `docs/index.html`
- Verify: `docs/assets/site.css`
- Verify: `docs/assets/`
- Verify: `test/website/site_contract_test.dart`

**Interfaces:**
- Consumes: the complete local static site and focused contract test.
- Produces: evidence for responsive layout, accessibility, resource locality, link integrity, and commit isolation.

- [ ] **Step 1: Start a local static server**

Run from the repository root:

```powershell
& 'C:\Users\user\.cache\codex-runtimes\codex-primary-runtime\dependencies\python\python.exe' -m http.server 4173 --directory docs
```

Open `http://127.0.0.1:4173/` only after the server reports that it is serving.

- [ ] **Step 2: Inspect responsive layouts**

Capture and inspect the page at widths 390, 768, and 1440 CSS pixels. At each width verify:

- navigation remains visible and wraps without overlap;
- overview copy and image remain legible;
- capability rows require no page-level horizontal scrolling;
- platform statuses include visible text;
- screenshot figures preserve aspect ratio;
- focus indicators remain visible.

Inspect light and dark system modes. Confirm the page remains readable with CSS disabled and that JavaScript is unnecessary.

- [ ] **Step 3: Verify page resources are first-party and local**

Inspect the page's loaded resources. Require only the local HTML, `assets/site.css`, favicon, icon/social image when requested by metadata clients, and the three screenshot files. Confirm there are no analytics, remote fonts, scripts, or third-party embeds.

- [ ] **Step 4: Run final automated checks**

Run fresh:

```powershell
flutter test test/website/site_contract_test.dart
& 'C:\Program Files\Git\usr\bin\bash.exe' ./tool/check_branding.sh
git diff --check HEAD~2 HEAD
git show --stat --oneline HEAD~2..HEAD
git status --short
```

Expected: focused test PASS; branding audit PASS; no whitespace errors; the two implementation commits contain only the planned website/test files; unrelated user changes remain unstaged and uncommitted.

- [ ] **Step 5: Record deployment handoff**

Report that repository implementation is complete but public deployment still requires the GitHub Pages setting to change from the root of `gh-pages` to branch `main`, folder `/docs`, after the implementation commits are pushed or merged. Do not change repository settings, delete `gh-pages`, push, or merge without separate authorization.
