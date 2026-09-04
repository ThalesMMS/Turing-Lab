#!/usr/bin/env python3
"""Reject stale JFlutter branding in maintained text files."""

from __future__ import annotations

import sys
from pathlib import Path


REPO_ROOT = Path(__file__).resolve().parents[1]
LEGACY_TERMS = ("J" + "Flutter", "j" + "flutter")
EXCLUDED_DIRECTORIES = {
    ".dart_tool",
    ".git",
    ".idea",
    ".vscode",
    "build",
    "release",
}
TEXT_SUFFIXES = {
    ".dart",
    ".html",
    ".json",
    ".md",
    ".plist",
    ".ps1",
    ".sh",
    ".txt",
    ".xcconfig",
    ".xml",
    ".yaml",
    ".yml",
}


def is_scannable(path: Path) -> bool:
    relative = path.relative_to(REPO_ROOT)
    return not any(part in EXCLUDED_DIRECTORIES for part in relative.parts) and (
        path.suffix.lower() in TEXT_SUFFIXES or path.name in {"Podfile", "Gemfile"}
    )


def main() -> int:
    unexpected: list[str] = []
    for path in sorted(REPO_ROOT.rglob("*")):
        if not path.is_file() or not is_scannable(path):
            continue
        relative = path.relative_to(REPO_ROOT).as_posix()
        try:
            lines = path.read_text(encoding="utf-8").splitlines()
        except UnicodeDecodeError:
            continue

        for line_number, line in enumerate(lines, start=1):
            matches = sum(line.count(term) for term in LEGACY_TERMS)
            if matches == 0:
                continue
            unexpected.append(f"{relative}:{line_number}:{line.strip()}")

    if unexpected:
        print("Stale branding check failed:", file=sys.stderr)
        for finding in unexpected:
            print(f"  {finding}", file=sys.stderr)
        return 1

    print("Stale branding check passed.")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
