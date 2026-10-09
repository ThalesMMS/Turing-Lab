from __future__ import annotations

import importlib.util
import json
import shutil
import subprocess
import sys
import tempfile
import unittest
from pathlib import Path


REPO_ROOT = Path(__file__).resolve().parents[2]
MODULE_PATH = REPO_ROOT / "tool" / "check_jflap_parity_matrix.py"
SPEC = importlib.util.spec_from_file_location("check_jflap_parity_matrix", MODULE_PATH)
assert SPEC is not None and SPEC.loader is not None
CHECKER = importlib.util.module_from_spec(SPEC)
SPEC.loader.exec_module(CHECKER)


class JflapParityMatrixValidatorTest(unittest.TestCase):
    def test_normal_validation_needs_no_external_sources(self) -> None:
        errors: list[str] = []
        _, rows = CHECKER.load_inventory(errors)
        self.assertEqual(errors, [])
        with tempfile.TemporaryDirectory() as temporary:
            checkout = Path(temporary) / "checkout"
            checkout.mkdir()
            shutil.copytree(REPO_ROOT / "docs/jflap-parity", checkout / "docs/jflap-parity")
            paths = {
                "tool/check_jflap_parity_matrix.py",
                "docs/JFLAP_PARITY_MATRIX.md",
                "docs/issue-roadmap.json",
            }
            for row in rows:
                for field in ("production", "tests"):
                    paths.update(item.rpartition(":")[0] for item in row["turingLab"][field])
            for relative in paths:
                source = REPO_ROOT / relative
                self.assertTrue(source.resolve().is_relative_to(REPO_ROOT))
                destination = checkout / relative
                destination.parent.mkdir(parents=True, exist_ok=True)
                shutil.copyfile(source, destination)

            def validate(*arguments: str) -> subprocess.CompletedProcess[str]:
                return subprocess.run(
                    [sys.executable, "tool/check_jflap_parity_matrix.py", *arguments],
                    cwd=checkout,
                    capture_output=True,
                    text=True,
                )

            with self.subTest("normal validation without Java sources"):
                result = validate()
                self.assertEqual(result.returncode, 0, result.stdout + result.stderr)
                self.assertIn(f"passed for {len(rows)} rows", result.stdout)

            with self.subTest("explicit source audit still requires its snapshot"):
                result = validate("--verify-jflap")
                self.assertEqual(result.returncode, 1)
                self.assertIn("JFLAP source root is unavailable", result.stderr)

            with self.subTest("malformed JFLAP citations still fail"):
                fragment = checkout / rows[0]["_source"]
                original = fragment.read_bytes()
                data = json.loads(original)
                data["rows"][0]["jflap"]["evidence"] = ["../JFLAP/file/XMLCodec.java"]
                fragment.write_text(json.dumps(data), encoding="utf-8")
                result = validate()
                self.assertEqual(result.returncode, 1)
                self.assertIn("evidence must end in a positive line number", result.stderr)
                fragment.write_bytes(original)

            with self.subTest("missing local production evidence still fails"):
                evidence = next(
                    item for row in rows for item in row["turingLab"]["production"]
                )
                relative = evidence.rpartition(":")[0]
                (checkout / relative).unlink()
                result = validate()
                self.assertEqual(result.returncode, 1)
                self.assertIn(f"evidence path does not exist: {relative}", result.stderr)

    def test_duplicate_json_keys_fail_closed(self) -> None:
        with tempfile.TemporaryDirectory(dir=REPO_ROOT) as temporary:
            path = Path(temporary) / "duplicate.json"
            path.write_text(
                '{"id": "first", "id": "second"}',
                encoding="utf-8",
            )
            errors: list[str] = []

            value = CHECKER.load_json(path, errors)

        self.assertIsNone(value)
        self.assertEqual(
            errors,
            [f"{path.relative_to(REPO_ROOT)}: duplicate JSON key: id"],
        )


if __name__ == "__main__":
    unittest.main()
