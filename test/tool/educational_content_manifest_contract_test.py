#!/usr/bin/env python3
"""Executable evidence that every manifest ID is tied to a shipped catalog ID."""

from __future__ import annotations

import importlib.util
import json
import unittest
from pathlib import Path


ROOT = Path(__file__).resolve().parents[2]
MANIFEST = ROOT / "docs/localization/educational_content.v1.json"
# educational-content-contract: shipped-catalog-ids-v1


def _load_checker():
    spec = importlib.util.spec_from_file_location(
        "check_educational_content", ROOT / "tool/check_educational_content.py"
    )
    assert spec is not None and spec.loader is not None
    module = importlib.util.module_from_spec(spec)
    spec.loader.exec_module(module)
    return module


class EducationalContentManifestContractTest(unittest.TestCase):
    def test_manifest_ids_equal_source_discovered_catalog_ids(self) -> None:
        checker = _load_checker()
        inventory = json.loads(MANIFEST.read_text(encoding="utf-8"))
        errors: list[str] = []
        source_records = checker._source_inventory(ROOT, inventory, errors)
        self.assertEqual(errors, [])

        manifest_keys = {
            (entry["kind"], entry["contentId"]) for entry in inventory["entries"]
        }
        self.assertEqual(manifest_keys, set(source_records))
        for entry in inventory["entries"]:
            source = source_records[(entry["kind"], entry["contentId"])]
            self.assertEqual(set(entry["sourcePaths"]), set(source["sourcePaths"]))
            if "formalPayloadSha256" in source:
                self.assertEqual(
                    entry.get("formalPayloadSha256"),
                    source["formalPayloadSha256"],
                )


if __name__ == "__main__":
    unittest.main()
