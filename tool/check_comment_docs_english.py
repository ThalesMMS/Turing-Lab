#!/usr/bin/env python3
"""Fail if comments or documentation still contain Portuguese prose.

Run locally (from the repository root):

  python3 tool/check_comment_docs_english.py

The scan covers comments in Dart/YAML/shell and Markdown documentation. It
does not rewrite runtime APIs, l10n, or UI strings.

Path exclusions: lib/l10n, generated Dart, vendored graphview, licenses,
build artifacts, and third-party/platform generated trees.

Allowlist (intentional leftovers are not failures):
  - Author names (Mendonça) and proper nouns (Sénizergues, Bézier, façade)
  - Runtime epsilon alias 'vazio'
  - Portuguese example titles/descriptions (examples data source / assets)
  - dfa_operations Portuguese operation names and error strings
  - Portuguese UI test fixtures and localization/help copy tests
"""

from __future__ import annotations

import os
import re
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]

SKIP_DIR_NAMES = {
    ".git",
    ".dart_tool",
    "build",
    "l10n",
    "graphview",
    "Pods",
    "node_modules",
    ".symlinks",
}

SKIP_DIR_PREFIXES = (
    "lib/l10n/",
    "graphview/",
    "ios/Pods/",
    "macos/Pods/",
)

SKIP_FILE_NAMES = {
    "LICENSE",
    "LICENSE.txt",
    "LICENSE_JFLAP.txt",
}

SKIP_SUFFIXES = (
    ".g.dart",
    ".freezed.dart",
    ".mocks.dart",
)

SCAN_SUFFIXES = {".dart", ".md", ".yml", ".yaml", ".sh"}

# Paths where Portuguese source/test content is intentional. Comments in these
# files are still scanned; matching lines are ignored when the path matches.
ALLOW_PATH_SUBSTRINGS = (
    "lib/core/algorithms/dfa_operations.dart",
    "lib/core/utils/epsilon_utils.dart",
    "lib/data/data_sources/examples_asset_data_source.dart",
    "assets/examples/",
    "workflow_localization_test.dart",
    "help_catalog_test.dart",
    "help_copy_corrections_test.dart",
    "help_localizations",
    "examples_test_helpers.dart",
    "examples_asset_data_source_test.dart",
    "examples_roundtrip_test.dart",
)

# Localization / Portuguese UI fixture tests (filename patterns).
ALLOW_TEST_NAME_RE = re.compile(
    r"(localization|localizations|_pt\.|help_page_|settings_page_test|"
    r"about_section_test|transition_editors_test|"
    r"transition_label_editor_form_cases|graphview_canvas_toolbar_test|"
    r"automaton_graphview_canvas_test|workspace_helpers_test|"
    r"fsa_page_controls_test|grammar_page_controls_test|"
    r"pda_page_controls_test|pda_algorithm_panel_test|"
    r"regex_page_derived_results_test|tm_page_mobile_controls_test|"
    r"home_page_test|interoperability_roundtrip|"
    r"epsilon_consolidation_test|app_store_screenshots_test)",
    re.I,
)

ALLOW_TOKEN_RE = re.compile(
    r"Mendonça|Sénizergues|Bézier|Bezier|façade|Gonçalves|Patrocínio|"
    r"Júnior|Junior|"
    r"\bvazio\b",
    re.I,
)

PORTUGUESE_CHAR_RE = re.compile(r"[àáâãéêíóôõúçÀÁÂÃÉÊÍÓÔÕÚÇ]")

# Distinctive Portuguese tokens (accents or unambiguous unaccented forms).
PORTUGUESE_WORD_RE = re.compile(
    r"\b("
    r"não|também|função|implementação|autômato|autômatos|gramática|"
    r"transição|transições|migração|referências|documentação|"
    r"cabeçalho|você|então|está|estão|são|não|arquivo|arquivos|"
    r"união|interseção|diferença|"
    r"nao|tambem|funcao|implementacao|automato|gramatica|"
    r"transicao|migracao|referencias|documentacao|cabecalho|voce|entao"
    r")\b",
    re.I,
)

OLD_ANCHOR_RE = re.compile(
    r"referências-para-a-migração|Referências para a Migração",
    re.I,
)

LINE_COMMENT_RE = re.compile(r"(?P<pre>^|\s)(?P<mark>///?|#)(?P<body>.*)$")


def rel_posix(path: Path) -> str:
    return path.relative_to(ROOT).as_posix()


def should_skip_dir(rel: str, name: str) -> bool:
    if name in SKIP_DIR_NAMES:
        return True
    prefix = rel if rel.endswith("/") else rel + "/"
    return any(prefix.startswith(p) or rel.startswith(p.rstrip("/")) for p in SKIP_DIR_PREFIXES)


def path_is_allowlisted(rel: str) -> bool:
    if any(token in rel for token in ALLOW_PATH_SUBSTRINGS):
        return True
    return bool(ALLOW_TEST_NAME_RE.search(Path(rel).name))


def line_is_allowlisted(line: str) -> bool:
    stripped = ALLOW_TOKEN_RE.sub(" ", line)
    if OLD_ANCHOR_RE.search(stripped):
        return False
    return not PORTUGUESE_CHAR_RE.search(stripped) and not PORTUGUESE_WORD_RE.search(
        stripped
    )


def extract_dart_comment_spans(text: str) -> list[tuple[int, str]]:
    """Return (1-based line number, comment text) for Dart comments."""
    spans: list[tuple[int, str]] = []
    i = 0
    line_no = 1
    n = len(text)
    in_block = False
    block_start_line = 1

    while i < n:
        ch = text[i]
        nxt = text[i + 1] if i + 1 < n else ""

        if in_block:
            if ch == "*" and nxt == "/":
                in_block = False
                i += 2
                continue
            if ch == "\n":
                line_no += 1
            i += 1
            continue

        if ch == "/" and nxt == "*":
            in_block = True
            block_start_line = line_no
            # Capture the block by scanning to close, recording each line.
            i += 2
            buf = ["/*"]
            start_line = line_no
            while i < n:
                c = text[i]
                buf.append(c)
                if c == "\n":
                    spans.append((start_line, "".join(buf).rstrip("\n")))
                    buf = []
                    start_line += 1
                    line_no += 1
                if c == "*" and i + 1 < n and text[i + 1] == "/":
                    buf.append("/")
                    spans.append((start_line, "".join(buf)))
                    i += 2
                    in_block = False
                    break
                i += 1
            continue

        if ch == "/" and nxt == "/":
            end = text.find("\n", i)
            body = text[i:] if end < 0 else text[i:end]
            spans.append((line_no, body))
            if end < 0:
                break
            i = end
            continue

        if ch in {"'", '"'}:
            quote = ch
            raw = False
            # Skip string literals (including raw and interpolation-unaware scan).
            if i > 0 and text[i - 1] == "r":
                raw = True
            i += 1
            while i < n:
                c = text[i]
                if c == "\n":
                    line_no += 1
                    # Unterminated string; stop this skip.
                    break
                if not raw and c == "\\" and i + 1 < n:
                    i += 2
                    continue
                if c == quote:
                    i += 1
                    break
                i += 1
            continue

        if ch == "\n":
            line_no += 1
        i += 1

    return spans


def iter_comment_or_doc_lines(path: Path, text: str) -> list[tuple[int, str]]:
    suffix = path.suffix
    if suffix == ".dart":
        return extract_dart_comment_spans(text)
    if suffix == ".md":
        return [(i, line) for i, line in enumerate(text.splitlines(), 1)]
    lines = []
    for i, line in enumerate(text.splitlines(), 1):
        match = LINE_COMMENT_RE.search(line)
        if match:
            lines.append((i, match.group("mark") + match.group("body")))
    return lines


def main() -> int:
    os.chdir(ROOT)
    violations: list[str] = []

    for dirpath, dirnames, filenames in os.walk(ROOT):
        rel_dir = os.path.relpath(dirpath, ROOT)
        if rel_dir == ".":
            rel_dir = ""
        dirnames[:] = [
            name
            for name in dirnames
            if not should_skip_dir(
                (rel_dir + "/" + name).lstrip("./").replace("\\", "/"),
                name,
            )
        ]
        for filename in filenames:
            path = Path(dirpath) / filename
            rel = rel_posix(path)
            if filename in SKIP_FILE_NAMES or filename.startswith("LICENSE"):
                continue
            if path.suffix not in SCAN_SUFFIXES:
                continue
            if filename.endswith(SKIP_SUFFIXES):
                continue
            if any(rel.startswith(prefix) for prefix in SKIP_DIR_PREFIXES):
                continue
            try:
                text = path.read_text(encoding="utf-8")
            except (OSError, UnicodeDecodeError):
                continue

            allow_file = path_is_allowlisted(rel)
            for line_no, snippet in iter_comment_or_doc_lines(path, text):
                combined = snippet
                if OLD_ANCHOR_RE.search(combined):
                    violations.append(
                        f"{rel}:{line_no}: use #migration-references instead of "
                        f"the old Portuguese heading anchor"
                    )
                    continue
                if allow_file:
                    continue
                if line_is_allowlisted(combined):
                    continue
                if PORTUGUESE_CHAR_RE.search(combined) or PORTUGUESE_WORD_RE.search(
                    combined
                ):
                    preview = snippet.strip().replace("\t", " ")
                    if len(preview) > 160:
                        preview = preview[:157] + "..."
                    violations.append(f"{rel}:{line_no}: {preview}")

    if violations:
        print("Portuguese prose found in comments or documentation:", file=sys.stderr)
        for item in violations:
            print(item, file=sys.stderr)
        print(
            f"\n{len(violations)} hit(s). Translate the comment/doc, or extend "
            "the documented allowlist in tool/check_comment_docs_english.py "
            "if the leftover is intentional.",
            file=sys.stderr,
        )
        return 1

    print("Comments and documentation English check passed.")
    return 0


if __name__ == "__main__":
    sys.exit(main())
