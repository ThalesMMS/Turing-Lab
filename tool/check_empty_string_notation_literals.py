#!/usr/bin/env python3
"""Inventory empty-string glyph literals in presentation-owned sources."""

from __future__ import annotations

import argparse
import json
from collections import Counter
from pathlib import Path
import sys

GLYPHS = ("ε", "ϵ", "λ")
DEFAULT_INVENTORY = "docs/empty_string_notation_literal_inventory.v1.json"


def _source_files(root: Path) -> list[Path]:
    files = [
        *root.glob("lib/presentation/**/*.dart"),
        *root.glob("lib/features/canvas/**/*.dart"),
        *root.glob("lib/l10n/app_*.arb"),
    ]
    return sorted(
        path
        for path in files
        if not path.name.startswith("app_localizations") and path.is_file()
    )


def _reason(relative: str, text: str) -> str:
    if relative.endswith("empty_string_notation.dart"):
        return "shared notation policy and supported glyph constants"
    if relative.endswith(("app_en.arb", "app_pt.arb")) and "ε" in text and "λ" in text:
        return "settings copy explicitly compares both supported conventions"
    if "settings" in relative and "ε" in text and "λ" in text:
        return "settings selector explicitly offers both supported conventions"
    if "/providers/" in relative or "step_projection" in relative:
        return "canonical presentation-state adapter; the render boundary formats it"
    if "/graphview/" in relative:
        return "canvas parsing or rendering boundary that recognizes empty transitions"
    if "/localization/" in relative or "/content/" in relative:
        return "canonical localized source copy formatted at its presentation boundary"
    if "lambda" in text.lower() and "ε" not in text and "ϵ" not in text:
        return "reviewed lambda identifier or genuine mathematical lambda reference"
    return "reviewed canonical presentation source; the owning widget formats display output"


def build_inventory(root: Path) -> dict[str, object]:
    records: list[dict[str, object]] = []
    totals: Counter[str] = Counter()
    for path in _source_files(root):
        relative = path.relative_to(root).as_posix()
        for raw_line in path.read_text(encoding="utf-8").splitlines():
            glyph_counts = {glyph: raw_line.count(glyph) for glyph in GLYPHS}
            glyph_counts = {glyph: count for glyph, count in glyph_counts.items() if count}
            if not glyph_counts:
                continue
            totals.update(glyph_counts)
            text = raw_line.strip()
            records.append(
                {
                    "path": relative,
                    "text": text,
                    "glyphs": glyph_counts,
                    "reason": _reason(relative, text),
                }
            )
    records.sort(key=lambda item: (item["path"], item["text"], json.dumps(item["glyphs"], ensure_ascii=False)))
    return {
        "schemaVersion": 1,
        "scope": [
            "lib/presentation/**/*.dart",
            "lib/features/canvas/**/*.dart",
            "lib/l10n/app_*.arb (generated localization files excluded)",
        ],
        "glyphTotals": {glyph: totals[glyph] for glyph in GLYPHS},
        "records": records,
    }


def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument("--root", type=Path, default=Path(__file__).resolve().parents[1])
    parser.add_argument("--inventory", default=DEFAULT_INVENTORY)
    parser.add_argument("--write-inventory", action="store_true")
    args = parser.parse_args()

    root = args.root.resolve()
    inventory_path = Path(args.inventory)
    if not inventory_path.is_absolute():
        inventory_path = root / inventory_path
    actual = build_inventory(root)

    if args.write_inventory:
        inventory_path.parent.mkdir(parents=True, exist_ok=True)
        inventory_path.write_text(
            json.dumps(actual, ensure_ascii=False, indent=2) + "\n",
            encoding="utf-8",
        )
        print(f"Wrote {len(actual['records'])} reviewed notation records to {inventory_path}")
        return 0

    try:
        expected = json.loads(inventory_path.read_text(encoding="utf-8"))
    except (OSError, json.JSONDecodeError) as error:
        print(f"Notation inventory is unavailable or invalid: {error}", file=sys.stderr)
        return 1
    if expected != actual:
        print(
            "Empty-string notation literal inventory is stale. Review every new or changed "
            f"glyph and run: python3 {Path(__file__).name} --write-inventory",
            file=sys.stderr,
        )
        return 1
    print(
        "Empty-string notation literal inventory is current: "
        f"{len(actual['records'])} reviewed source lines"
    )
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
