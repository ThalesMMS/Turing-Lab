from __future__ import annotations

import importlib.util
import json
import shutil
import tempfile
import unittest
from contextlib import redirect_stderr, redirect_stdout
from io import StringIO
from pathlib import Path
from typing import Any, Callable


REPO_ROOT = Path(__file__).resolve().parents[2]
MODULE_PATH = REPO_ROOT / "tool" / "check_arb_resources.py"
SPEC = importlib.util.spec_from_file_location("check_arb_resources", MODULE_PATH)
assert SPEC is not None and SPEC.loader is not None
CHECKER = importlib.util.module_from_spec(SPEC)
SPEC.loader.exec_module(CHECKER)
FIXTURE_ROOT = (
    REPO_ROOT / "test" / "fixtures" / "localization" / "arb_resources" / "valid"
)


class ArbResourceValidatorTest(unittest.TestCase):
    def _copy_fixture(self, destination: Path) -> Path:
        root = destination / "fixture"
        shutil.copytree(FIXTURE_ROOT, root)
        return root

    def _validate(self, root: Path) -> list[str]:
        return CHECKER.validate_resources(
            root / "app_en.arb",
            root / "app_pt.arb",
        )

    def _mutate_json(
        self,
        root: Path,
        locale: str,
        mutation: Callable[[dict[str, Any]], None],
    ) -> None:
        path = root / f"app_{locale}.arb"
        document = json.loads(path.read_text(encoding="utf-8"))
        mutation(document)
        path.write_text(json.dumps(document, ensure_ascii=False), encoding="utf-8")

    def _run_main(self, root: Path, report_format: str) -> tuple[int, str]:
        output = StringIO()
        with redirect_stdout(output):
            exit_code = CHECKER.main(
                [
                    "--repo-root",
                    str(root),
                    "--english",
                    "app_en.arb",
                    "--portuguese",
                    "app_pt.arb",
                    "--ownership",
                    "missing-ownership.json",
                    "--format",
                    report_format,
                ]
            )
        return exit_code, output.getvalue()

    def _run_main_with_output(
        self,
        root: Path,
        output_path: Path,
    ) -> tuple[int, str, str]:
        output = StringIO()
        error_output = StringIO()
        with redirect_stdout(output), redirect_stderr(error_output):
            exit_code = CHECKER.main(
                [
                    "--repo-root",
                    str(root),
                    "--english",
                    "app_en.arb",
                    "--portuguese",
                    "app_pt.arb",
                    "--ownership",
                    "missing-ownership.json",
                    "--json-output",
                    str(output_path),
                ]
            )
        return exit_code, output.getvalue(), error_output.getvalue()

    def test_valid_fixture_passes(self) -> None:
        self.assertEqual(self._validate(FIXTURE_ROOT), [])

    def test_json_report_is_machine_readable_and_deterministic(self) -> None:
        first_exit_code, first_output = self._run_main(FIXTURE_ROOT, "json")
        second_exit_code, second_output = self._run_main(FIXTURE_ROOT, "json")

        self.assertEqual(first_exit_code, 0)
        self.assertEqual(second_exit_code, 0)
        self.assertEqual(first_output, second_output)
        report = json.loads(first_output)
        self.assertEqual(report["schemaVersion"], 1)
        self.assertEqual(report["status"], "passed")
        self.assertEqual(report["summary"]["errorCount"], 0)
        self.assertEqual(
            [resource["locale"] for resource in report["resources"]],
            ["en", "pt"],
        )

    def test_json_output_preserves_text_stdout_and_is_deterministic(self) -> None:
        with tempfile.TemporaryDirectory() as temporary:
            root = self._copy_fixture(Path(temporary))
            first_path = root / "reports" / "first.json"
            second_path = root / "reports" / "second.json"

            first_exit, first_stdout, first_stderr = self._run_main_with_output(
                root,
                first_path,
            )
            second_exit, second_stdout, second_stderr = self._run_main_with_output(
                root,
                second_path,
            )

            first_json = first_path.read_text(encoding="utf-8")
            second_json = second_path.read_text(encoding="utf-8")

        self.assertEqual(first_exit, 0)
        self.assertEqual(second_exit, 0)
        self.assertEqual(first_stderr, "")
        self.assertEqual(second_stderr, "")
        self.assertEqual(first_stdout, second_stdout)
        self.assertIn("ARB resources are valid.", first_stdout)
        self.assertEqual(first_json, second_json)
        self.assertTrue(first_json.endswith("\n"))
        report = json.loads(first_json)
        self.assertEqual(report["status"], "passed")
        self.assertEqual(report["summary"]["errorsByLocale"], {})
        self.assertEqual(report["summary"]["errorsByNamespace"], {})

    def test_json_output_is_written_for_validation_failure(self) -> None:
        with tempfile.TemporaryDirectory() as temporary:
            root = self._copy_fixture(Path(temporary))
            self._mutate_json(root, "pt", lambda document: document.pop("summary"))
            output_path = root / "report.json"

            exit_code, stdout, stderr = self._run_main_with_output(
                root,
                output_path,
            )
            report = json.loads(output_path.read_text(encoding="utf-8"))

        self.assertEqual(exit_code, 1)
        self.assertEqual(stderr, "")
        self.assertIn("ARB resource validation failed", stdout)
        self.assertEqual(report["status"], "failed")
        self.assertEqual(report["summary"]["errorsByLocale"], {"pt": 2})
        self.assertEqual(len(report["errors"]), 2)

    def test_json_output_write_failure_fails_closed(self) -> None:
        with tempfile.TemporaryDirectory() as temporary:
            root = self._copy_fixture(Path(temporary))

            exit_code, stdout, stderr = self._run_main_with_output(
                root,
                Path("."),
            )

        self.assertEqual(exit_code, 1)
        self.assertIn("ARB resources are valid.", stdout)
        self.assertIn("cannot write JSON report", stderr)

    def test_text_report_groups_failures_by_locale_and_namespace(self) -> None:
        with tempfile.TemporaryDirectory() as temporary:
            root = self._copy_fixture(Path(temporary))
            self._mutate_json(root, "pt", lambda document: document.pop("summary"))
            issues = CHECKER.validate_resource_issues(
                root / "app_en.arb",
                root / "app_pt.arb",
            )
            report = CHECKER.build_report(
                root / "app_en.arb",
                root / "app_pt.arb",
                issues,
                repo_root=root,
                namespace_rules={"summary": ("formal.grammar",)},
            )
            output = StringIO()
            with redirect_stdout(output):
                CHECKER._print_text_report(report)

        self.assertEqual(report["summary"]["errorsByLocale"], {"pt": 2})
        self.assertEqual(
            report["summary"]["errorsByNamespace"],
            {"formal.grammar": 2},
        )
        self.assertIn("- pt / formal.grammar: 2", output.getvalue())
        self.assertIn(
            "Portuguese ARB is missing message key: summary",
            output.getvalue(),
        )

    def test_duplicate_keys_fail_closed_at_any_object_depth(self) -> None:
        with tempfile.TemporaryDirectory() as temporary:
            root = self._copy_fixture(Path(temporary))
            path = root / "app_en.arb"
            text = path.read_text(encoding="utf-8").replace(
                '"type": "String",',
                '"type": "String", "type": "int",',
                1,
            )
            path.write_text(text, encoding="utf-8")

            errors = self._validate(root)

        self.assertTrue(any("duplicate JSON key: type" in error for error in errors))

    def test_invalid_json_escape_fails_closed(self) -> None:
        with tempfile.TemporaryDirectory() as temporary:
            root = self._copy_fixture(Path(temporary))
            path = root / "app_pt.arb"
            path.write_text('{"title": "bad\\q escape"}', encoding="utf-8")

            errors = self._validate(root)

        self.assertTrue(any("Invalid \\escape" in error for error in errors))

    def test_message_and_metadata_key_parity_are_required(self) -> None:
        with tempfile.TemporaryDirectory() as temporary:
            root = self._copy_fixture(Path(temporary))
            self._mutate_json(root, "pt", lambda document: document.pop("title"))
            self._mutate_json(root, "pt", lambda document: document.pop("@role"))

            errors = self._validate(root)

        self.assertIn("Portuguese ARB is missing message key: title", errors)
        self.assertIn("Portuguese ARB is missing metadata key: @role", errors)

    def test_message_keys_must_be_supported_localization_getter_names(self) -> None:
        with tempfile.TemporaryDirectory() as temporary:
            root = self._copy_fixture(Path(temporary))
            for locale in ("en", "pt"):
                self._mutate_json(
                    root,
                    locale,
                    lambda document: document.update(
                        {
                            "obsolete-key": "No generated getter can reach this.",
                            "@obsolete-key": {},
                            "9title": "A getter cannot start with a digit.",
                            "@9title": {},
                            "Title": "A getter must start with lowercase.",
                            "@Title": {},
                            "_private": "A generated getter must be public.",
                            "@_private": {},
                        }
                    ),
                )

            errors = self._validate(root)

        self.assertIn(
            "English ARB message key is not a supported localization getter "
            "name: '9title'",
            errors,
        )
        self.assertIn(
            "English ARB message key is not a supported localization getter "
            "name: 'obsolete-key'",
            errors,
        )
        self.assertIn(
            "English ARB message key is not a supported localization getter "
            "name: 'Title'",
            errors,
        )
        self.assertIn(
            "English ARB message key is not a supported localization getter "
            "name: '_private'",
            errors,
        )
        self.assertIn(
            "Portuguese ARB message key is not a supported localization getter "
            "name: '9title'",
            errors,
        )
        self.assertIn(
            "Portuguese ARB message key is not a supported localization getter "
            "name: 'obsolete-key'",
            errors,
        )
        self.assertIn(
            "Portuguese ARB message key is not a supported localization getter "
            "name: 'Title'",
            errors,
        )
        self.assertIn(
            "Portuguese ARB message key is not a supported localization getter "
            "name: '_private'",
            errors,
        )

    def test_declared_locale_must_match_the_resource(self) -> None:
        with tempfile.TemporaryDirectory() as temporary:
            root = self._copy_fixture(Path(temporary))
            self._mutate_json(
                root,
                "pt",
                lambda document: document.__setitem__("@@locale", "en"),
            )
            self._mutate_json(
                root,
                "en",
                lambda document: document.pop("@@locale"),
            )
            output_path = root / "report.json"

            exit_code, stdout, stderr = self._run_main_with_output(
                root,
                output_path,
            )
            report = json.loads(output_path.read_text(encoding="utf-8"))

        self.assertEqual(exit_code, 1)
        self.assertEqual(stderr, "")
        self.assertIn("ARB resource validation failed", stdout)
        self.assertEqual(
            report["summary"]["errorsByLocale"],
            {"en": 1, "pt": 1},
        )
        self.assertEqual(
            [error["category"] for error in report["errors"]],
            ["resource", "resource"],
        )
        self.assertIn(
            "English ARB @@locale must be 'en', found None",
            [error["message"] for error in report["errors"]],
        )
        self.assertIn(
            "Portuguese ARB @@locale must be 'pt', found 'en'",
            [error["message"] for error in report["errors"]],
        )

    def test_every_used_placeholder_needs_metadata(self) -> None:
        with tempfile.TemporaryDirectory() as temporary:
            root = self._copy_fixture(Path(temporary))
            self._mutate_json(
                root,
                "en",
                lambda document: document["@summary"]["placeholders"].pop("name"),
            )

            errors = self._validate(root)

        self.assertIn("English placeholder metadata is missing: summary.name", errors)

    def test_unused_placeholder_metadata_is_rejected(self) -> None:
        with tempfile.TemporaryDirectory() as temporary:
            root = self._copy_fixture(Path(temporary))
            self._mutate_json(
                root,
                "pt",
                lambda document: document.__setitem__("greeting", "Olá."),
            )

            errors = self._validate(root)

        self.assertIn(
            "Portuguese placeholder metadata is unused: greeting.name",
            errors,
        )

    def test_placeholder_contract_must_match_across_locales(self) -> None:
        with tempfile.TemporaryDirectory() as temporary:
            root = self._copy_fixture(Path(temporary))
            self._mutate_json(
                root,
                "pt",
                lambda document: document["@summary"]["placeholders"][
                    "count"
                ].__setitem__("type", "double"),
            )

            errors = self._validate(root)

        self.assertTrue(
            any("placeholder contract differs for summary" in error for error in errors)
        )

    def test_placeholder_example_and_description_presence_must_match(self) -> None:
        with tempfile.TemporaryDirectory() as temporary:
            root = self._copy_fixture(Path(temporary))
            self._mutate_json(
                root,
                "pt",
                lambda document: document["@greeting"]["placeholders"][
                    "name"
                ].pop("example"),
            )
            self._mutate_json(
                root,
                "pt",
                lambda document: document["@greeting"].pop("description"),
            )

            errors = self._validate(root)

        self.assertTrue(
            any("placeholder contract differs for greeting" in error for error in errors)
        )
        self.assertIn("description presence differs for greeting", errors)

    def test_placeholder_examples_must_be_non_empty_strings(self) -> None:
        with tempfile.TemporaryDirectory() as temporary:
            root = self._copy_fixture(Path(temporary))
            for locale, example in (("en", 42), ("pt", "")):
                self._mutate_json(
                    root,
                    locale,
                    lambda document, example=example: document["@greeting"][
                        "placeholders"
                    ]["name"].__setitem__("example", example),
                )

            errors = self._validate(root)

        self.assertIn(
            "English placeholder example must be a non-empty string: greeting.name",
            errors,
        )
        self.assertIn(
            "Portuguese placeholder example must be a non-empty string: greeting.name",
            errors,
        )

    def test_plural_and_select_arguments_require_other(self) -> None:
        with tempfile.TemporaryDirectory() as temporary:
            root = self._copy_fixture(Path(temporary))
            self._mutate_json(
                root,
                "en",
                lambda document: document.__setitem__(
                    "summary", "{count, plural, =0{None} =1{One}}"
                ),
            )
            self._mutate_json(
                root,
                "pt",
                lambda document: document.__setitem__(
                    "role", "{role, select, admin{Administrador}}"
                ),
            )

            errors = self._validate(root)

        self.assertTrue(
            any(
                "plural argument is missing an other case" in error
                for error in errors
            )
        )
        self.assertTrue(
            any(
                "select argument is missing an other case" in error
                for error in errors
            )
        )

    def test_plural_selector_must_be_supported(self) -> None:
        with tempfile.TemporaryDirectory() as temporary:
            root = self._copy_fixture(Path(temporary))
            for locale in ("en", "pt"):
                self._mutate_json(
                    root,
                    locale,
                    lambda document: document.__setitem__(
                        "summary",
                        "{count, plural, banana{Invalid} other{{count} files}}",
                    ),
                )

            errors = self._validate(root)

        self.assertTrue(
            any("plural selector is invalid: banana" in error for error in errors)
        )

    def test_number_argument_requires_numeric_placeholder_metadata(self) -> None:
        with tempfile.TemporaryDirectory() as temporary:
            root = self._copy_fixture(Path(temporary))
            for locale in ("en", "pt"):
                self._mutate_json(
                    root,
                    locale,
                    lambda document: document.__setitem__(
                        "greeting",
                        "Total: {name, number}",
                    ),
                )

            errors = self._validate(root)

        self.assertIn(
            "English number placeholder must be numeric: greeting.name",
            errors,
        )
        self.assertIn(
            "Portuguese number placeholder must be numeric: greeting.name",
            errors,
        )

    def test_datetime_arguments_require_datetime_placeholder_metadata(self) -> None:
        with tempfile.TemporaryDirectory() as temporary:
            root = self._copy_fixture(Path(temporary))
            for locale, argument_type in (("en", "date"), ("pt", "time")):
                self._mutate_json(
                    root,
                    locale,
                    lambda document, argument_type=argument_type: document.__setitem__(
                        "greeting",
                        f"Created on {{name, {argument_type}}}.",
                    ),
                )

            errors = self._validate(root)

        self.assertIn(
            "English date placeholder must be DateTime: greeting.name",
            errors,
        )
        self.assertIn(
            "Portuguese time placeholder must be DateTime: greeting.name",
            errors,
        )

    def test_unknown_argument_type_fails_closed(self) -> None:
        with tempfile.TemporaryDirectory() as temporary:
            root = self._copy_fixture(Path(temporary))
            for locale in ("en", "pt"):
                self._mutate_json(
                    root,
                    locale,
                    lambda document: document.__setitem__(
                        "greeting",
                        "Hello, {name, banana}.",
                    ),
                )

            errors = self._validate(root)

        self.assertIn(
            "English ICU syntax is invalid for greeting: "
            "unsupported argument type: banana",
            errors,
        )
        self.assertIn(
            "Portuguese ICU syntax is invalid for greeting: "
            "unsupported argument type: banana",
            errors,
        )

    def test_icu_branch_sets_must_match_across_locales(self) -> None:
        with tempfile.TemporaryDirectory() as temporary:
            root = self._copy_fixture(Path(temporary))
            self._mutate_json(
                root,
                "pt",
                lambda document: document.__setitem__(
                    "summary",
                    "{count, plural, =0{Nenhum} =1{Um} few{Poucos} "
                    "other{{count} arquivos}}",
                ),
            )

            errors = self._validate(root)

        self.assertTrue(
            any("ICU branches differ for summary" in error for error in errors)
        )

    def test_icu_argument_types_must_match_across_locales(self) -> None:
        with tempfile.TemporaryDirectory() as temporary:
            root = self._copy_fixture(Path(temporary))
            self._mutate_json(
                root,
                "en",
                lambda document: document.__setitem__(
                    "greeting", "Hello, {name, number}."
                ),
            )
            self._mutate_json(
                root,
                "pt",
                lambda document: document.__setitem__(
                    "greeting", "Olá, {name}."
                ),
            )
            for locale in ("en", "pt"):
                self._mutate_json(
                    root,
                    locale,
                    lambda document: document["@greeting"]["placeholders"][
                        "name"
                    ].__setitem__("type", "int"),
                )

            errors = self._validate(root)

        self.assertTrue(
            any("ICU argument types differ for greeting" in error for error in errors)
        )

    def test_unbalanced_icu_message_fails_closed(self) -> None:
        with tempfile.TemporaryDirectory() as temporary:
            root = self._copy_fixture(Path(temporary))
            self._mutate_json(
                root,
                "en",
                lambda document: document.__setitem__("greeting", "Hello, {name."),
            )

            errors = self._validate(root)

        self.assertTrue(
            any("ICU syntax is invalid for greeting" in error for error in errors)
        )


if __name__ == "__main__":
    unittest.main()
