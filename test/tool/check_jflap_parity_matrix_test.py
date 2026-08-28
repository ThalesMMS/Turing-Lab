from __future__ import annotations

import importlib.util
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
