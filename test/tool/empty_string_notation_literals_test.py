import json
from pathlib import Path
import subprocess
import sys
import tempfile
import unittest


SCRIPT = Path(__file__).resolve().parents[2] / "tool" / "check_empty_string_notation_literals.py"


class EmptyStringNotationLiteralInventoryTest(unittest.TestCase):
    def test_written_inventory_verifies_clean(self) -> None:
        with tempfile.TemporaryDirectory() as directory:
            root = Path(directory)
            source = root / "lib" / "presentation" / "new_widget.dart"
            source.parent.mkdir(parents=True)
            source.write_text("const label = 'ε';\n", encoding="utf-8")
            inventory = root / "inventory.json"
            command = [
                sys.executable,
                str(SCRIPT),
                "--root",
                str(root),
                "--inventory",
                str(inventory),
            ]

            write = subprocess.run(
                [*command, "--write-inventory"],
                capture_output=True,
                text=True,
                check=False,
            )
            self.assertEqual(write.returncode, 0, write.stderr)

            verify = subprocess.run(
                command,
                capture_output=True,
                text=True,
                check=False,
            )
            self.assertEqual(verify.returncode, 0, verify.stderr)
            self.assertIn("inventory is current", verify.stdout)

    def test_new_user_facing_glyph_fails_until_reviewed(self) -> None:
        with tempfile.TemporaryDirectory() as directory:
            root = Path(directory)
            source = root / "lib" / "presentation" / "new_widget.dart"
            source.parent.mkdir(parents=True)
            source.write_text("const label = 'ε';\n", encoding="utf-8")
            inventory = root / "inventory.json"
            inventory.write_text(
                json.dumps(
                    {
                        "schemaVersion": 1,
                        "scope": [
                            "lib/presentation/**/*.dart",
                            "lib/features/canvas/**/*.dart",
                            "lib/l10n/app_*.arb (generated localization files excluded)",
                        ],
                        "glyphTotals": {"ε": 0, "ϵ": 0, "λ": 0},
                        "records": [],
                    }
                ),
                encoding="utf-8",
            )

            result = subprocess.run(
                [
                    sys.executable,
                    str(SCRIPT),
                    "--root",
                    str(root),
                    "--inventory",
                    str(inventory),
                ],
                capture_output=True,
                text=True,
                check=False,
            )

            self.assertEqual(result.returncode, 1)
            self.assertIn("inventory is stale", result.stderr)


if __name__ == "__main__":
    unittest.main()
