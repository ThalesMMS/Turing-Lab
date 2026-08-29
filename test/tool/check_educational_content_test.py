from __future__ import annotations

import contextlib
import importlib.util
import io
import json
import shutil
import tempfile
import unittest
from pathlib import Path


REPO_ROOT = Path(__file__).resolve().parents[2]
MODULE_PATH = REPO_ROOT / "tool" / "check_educational_content.py"
SPEC = importlib.util.spec_from_file_location("check_educational_content", MODULE_PATH)
assert SPEC is not None and SPEC.loader is not None
CHECKER = importlib.util.module_from_spec(SPEC)
SPEC.loader.exec_module(CHECKER)
FIXTURE_ROOT = (
    REPO_ROOT / "test" / "fixtures" / "localization" / "educational_content" / "valid"
)


class EducationalContentValidatorTest(unittest.TestCase):
    def _validate(self, root: Path) -> tuple[list[str], list[str]]:
        return CHECKER.validate_repository(
            root,
            root / "educational_content.v1.json",
        )

    def _copy_fixture(self, destination: Path) -> Path:
        root = destination / "fixture"
        shutil.copytree(FIXTURE_ROOT, root)
        return root

    def _load_inventory(self, root: Path) -> tuple[Path, dict]:
        path = root / "educational_content.v1.json"
        return path, json.loads(path.read_text(encoding="utf-8"))

    def test_valid_fixture_is_structural_only(self) -> None:
        errors, blockers = self._validate(FIXTURE_ROOT)

        self.assertEqual(errors, [])
        self.assertTrue(blockers)
        self.assertTrue(any("technical review" in blocker for blocker in blockers))

    def test_certification_mode_fails_for_pending_review(self) -> None:
        output = io.StringIO()
        with contextlib.redirect_stdout(output):
            exit_code = CHECKER.main(
                [
                    "--repo-root",
                    str(FIXTURE_ROOT),
                    "--inventory",
                    "educational_content.v1.json",
                    "--certify",
                ]
            )

        self.assertEqual(exit_code, 2)
        self.assertIn("not ready for final certification", output.getvalue())

    def test_missing_and_duplicate_ids_fail_closed(self) -> None:
        with tempfile.TemporaryDirectory() as temporary:
            root = self._copy_fixture(Path(temporary))
            path, inventory = self._load_inventory(root)
            removed = inventory["entries"].pop()
            inventory["entries"].append(dict(inventory["entries"][0]))
            path.write_text(json.dumps(inventory), encoding="utf-8")

            errors, _ = self._validate(root)

        self.assertTrue(
            any(removed["contentId"] in error and "absent" in error for error in errors)
        )
        self.assertTrue(any("duplicate manifestId" in error for error in errors))
        self.assertTrue(any("duplicate content entry" in error for error in errors))

    def test_duplicate_json_keys_fail_closed(self) -> None:
        with tempfile.TemporaryDirectory() as temporary:
            root = self._copy_fixture(Path(temporary))
            path = root / "educational_content.v1.json"
            inventory_text = path.read_text(encoding="utf-8")
            path.write_text(
                inventory_text.replace(
                    '"schemaVersion": 1,',
                    '"schemaVersion": 1,\n  "schemaVersion": 1,',
                    1,
                ),
                encoding="utf-8",
            )

            errors, _ = self._validate(root)

        self.assertTrue(
            any("duplicate JSON key: schemaVersion" in error for error in errors)
        )

    def test_versions_and_evidence_links_are_validated(self) -> None:
        with tempfile.TemporaryDirectory() as temporary:
            root = self._copy_fixture(Path(temporary))
            path, inventory = self._load_inventory(root)
            inventory["profiles"]["pending"]["contentVersion"] = 0
            inventory["entries"][0]["evidenceTests"] = ["test/missing_test.dart"]
            path.write_text(json.dumps(inventory), encoding="utf-8")

            errors, _ = self._validate(root)

        self.assertTrue(any("contentVersion" in error for error in errors))
        self.assertTrue(any("missing evidence test" in error for error in errors))

    def test_entry_source_paths_reject_duplicates(self) -> None:
        with tempfile.TemporaryDirectory() as temporary:
            root = self._copy_fixture(Path(temporary))
            path, inventory = self._load_inventory(root)
            source_paths = inventory["entries"][0]["sourcePaths"]
            source_paths.append(source_paths[0])
            path.write_text(json.dumps(inventory), encoding="utf-8")

            errors, _ = self._validate(root)

        self.assertIn("entries[0].sourcePaths contains duplicates", errors)

    def test_manifest_ids_reject_localized_titles(self) -> None:
        with tempfile.TemporaryDirectory() as temporary:
            root = self._copy_fixture(Path(temporary))
            path, inventory = self._load_inventory(root)
            example = next(
                entry for entry in inventory["entries"] if entry["kind"] == "example"
            )
            example["contentId"] = "Exemplo com acento e espaços"
            example["manifestId"] = "example/Exemplo com acento e espaços"
            path.write_text(json.dumps(inventory), encoding="utf-8")

            errors, _ = self._validate(root)

        self.assertTrue(
            any("stable locale-neutral identifier" in error for error in errors)
        )

    def test_asset_formal_payload_drift_is_detected(self) -> None:
        with tempfile.TemporaryDirectory() as temporary:
            root = self._copy_fixture(Path(temporary))
            asset_path = root / "assets" / "examples" / "fixture.json"
            asset = json.loads(asset_path.read_text(encoding="utf-8"))
            asset["acceptsEmpty"] = False
            asset_path.write_text(json.dumps(asset), encoding="utf-8")

            errors, _ = self._validate(root)

        self.assertTrue(any("formalPayloadSha256 drifted" in error for error in errors))

    def test_suggested_simulation_coverage_drift_is_detected(self) -> None:
        with tempfile.TemporaryDirectory() as temporary:
            root = self._copy_fixture(Path(temporary))
            suggestion_path = root / "example_suggested_simulations.dart.txt"
            source = suggestion_path.read_text(encoding="utf-8")
            suggestion_path.write_text(
                source.replace("'asset/fixture': ['a'],", "'asset/orphan': [''],"),
                encoding="utf-8",
            )

            errors, _ = self._validate(root)

        self.assertTrue(
            any(
                "missing shipped id: asset/fixture" in error
                for error in errors
            )
        )
        self.assertTrue(
            any(
                "excluded or unshipped id: asset/orphan" in error
                for error in errors
            )
        )
        self.assertTrue(
            any(
                "for asset/orphan contain no usable input" in error
                for error in errors
            )
        )

    def test_duplicate_suggested_inputs_are_detected(self) -> None:
        with tempfile.TemporaryDirectory() as temporary:
            root = self._copy_fixture(Path(temporary))
            suggestion_path = root / "example_suggested_simulations.dart.txt"
            source = suggestion_path.read_text(encoding="utf-8")
            suggestion_path.write_text(
                source.replace("['a']", "['a', 'a']"),
                encoding="utf-8",
            )

            errors, _ = self._validate(root)

        self.assertTrue(
            any("for asset/fixture are duplicated" in error for error in errors)
        )

    def test_duplicate_suggested_example_ids_are_detected(self) -> None:
        with tempfile.TemporaryDirectory() as temporary:
            root = self._copy_fixture(Path(temporary))
            suggestion_path = root / "example_suggested_simulations.dart.txt"
            source = suggestion_path.read_text(encoding="utf-8")
            suggestion_path.write_text(
                source.replace(
                    "'asset/fixture': ['a'],",
                    "'asset/fixture': ['a'],\n    'asset/fixture': ['aa'],",
                ),
                encoding="utf-8",
            )

            errors, _ = self._validate(root)

        self.assertTrue(
            any(
                "duplicate example suggested simulations id: asset/fixture" in error
                for error in errors
            )
        )

    def test_string_list_map_requires_entry_separators(self) -> None:
        errors: list[str] = []

        result = CHECKER._string_list_map(
            "const fixture = {'a': ['x'] 'b': ['y']};",
            "const fixture =",
            "fixture",
            errors,
        )

        self.assertEqual(result, {"a": ["x"]})
        self.assertEqual(errors, ["fixture entry 'a' has no separator"])

    def test_suggested_simulations_exclude_only_l_system_catalogs(self) -> None:
        with tempfile.TemporaryDirectory() as temporary:
            root = self._copy_fixture(Path(temporary))
            path, inventory = self._load_inventory(root)
            inventory["sources"]["exampleSuggestedSimulations"][
                "excludedCatalogStrategies"
            ] = ["assetMetadata"]
            path.write_text(json.dumps(inventory), encoding="utf-8")

            errors, _ = self._validate(root)

        self.assertTrue(
            any("must contain only lSystemValues" in error for error in errors)
        )

    def test_suggested_simulation_inventory_cannot_be_removed(self) -> None:
        with tempfile.TemporaryDirectory() as temporary:
            root = self._copy_fixture(Path(temporary))
            path, inventory = self._load_inventory(root)
            del inventory["sources"]["exampleSuggestedSimulations"]
            path.write_text(json.dumps(inventory), encoding="utf-8")

            errors, _ = self._validate(root)

        self.assertTrue(
            any(
                "sources.exampleSuggestedSimulations must be declared" in error
                for error in errors
            )
        )

    def test_terminology_contract_cannot_be_removed(self) -> None:
        with tempfile.TemporaryDirectory() as temporary:
            root = self._copy_fixture(Path(temporary))
            path, inventory = self._load_inventory(root)
            del inventory["sources"]["terminology"]
            path.write_text(json.dumps(inventory), encoding="utf-8")

            errors, _ = self._validate(root)

        self.assertIn("sources.terminology must be declared", errors)

    def test_exercise_expected_answer_drift_is_detected(self) -> None:
        with tempfile.TemporaryDirectory() as temporary:
            root = self._copy_fixture(Path(temporary))
            source_path = root / "pumping_problem.dart.txt"
            source = source_path.read_text(encoding="utf-8").replace(
                "PumpingChallengeOutcome.noCounterexampleExpected",
                "PumpingChallengeOutcome.counterexampleExpected",
            )
            source_path.write_text(source, encoding="utf-8")

            errors, _ = self._validate(root)

        self.assertTrue(any("formalPayloadSha256 drifted" in error for error in errors))

    def test_exercise_language_drift_is_detected(self) -> None:
        with tempfile.TemporaryDirectory() as temporary:
            root = self._copy_fixture(Path(temporary))
            source_path = root / "pumping_problem.dart.txt"
            source = source_path.read_text(encoding="utf-8").replace(
                "L = {a^n}", "L = {a^(2n)}"
            )
            source_path.write_text(source, encoding="utf-8")

            errors, _ = self._validate(root)

        self.assertTrue(any("formalPayloadSha256 drifted" in error for error in errors))

    def test_exercise_content_version_drift_is_detected(self) -> None:
        with tempfile.TemporaryDirectory() as temporary:
            root = self._copy_fixture(Path(temporary))
            source_path = root / "pumping_problem.dart.txt"
            source_path.write_text(
                source_path.read_text(encoding="utf-8").replace(
                    "contentVersion: 1", "contentVersion: 2"
                ),
                encoding="utf-8",
            )

            errors, _ = self._validate(root)

        self.assertTrue(
            any("profile contentVersion drifted" in error for error in errors)
        )

    def test_exercise_content_version_is_required(self) -> None:
        with tempfile.TemporaryDirectory() as temporary:
            root = self._copy_fixture(Path(temporary))
            source_path = root / "pumping_problem.dart.txt"
            source_path.write_text(
                source_path.read_text(encoding="utf-8").replace(
                    "  contentVersion: 1,\n", ""
                ),
                encoding="utf-8",
            )

            errors, _ = self._validate(root)

        self.assertIn("pumping exercise source has no contentVersion", errors)

    def test_double_quoted_and_raw_asset_literals_are_extracted(self) -> None:
        with tempfile.TemporaryDirectory() as temporary:
            root = self._copy_fixture(Path(temporary))
            source_path = root / "example_catalog.dart.txt"
            source = source_path.read_text(encoding="utf-8")
            source = source.replace("'Fixture example'", 'r"Fixture example"')
            source = source.replace("'fixture.json'", '"fixture.json"')
            source_path.write_text(source, encoding="utf-8")
            ids_path = root / "help_topic_ids.dart.txt"
            ids_path.write_text(
                ids_path.read_text(encoding="utf-8").replace(
                    "'fixture.help'", 'r"fixture.help"'
                ),
                encoding="utf-8",
            )

            errors, _ = self._validate(root)

        self.assertEqual(errors, [])

    def test_unextractable_expected_constructor_fails_closed(self) -> None:
        with tempfile.TemporaryDirectory() as temporary:
            root = self._copy_fixture(Path(temporary))
            source_path = root / "example_catalog.dart.txt"
            source = source_path.read_text(encoding="utf-8").replace(
                "fileName: 'fixture.json',", "fileName: computeFixtureName(),"
            )
            source_path.write_text(source, encoding="utf-8")

            errors, _ = self._validate(root)

        self.assertTrue(any("has no fileName" in error for error in errors))

    def test_asset_copy_requires_complete_bilingual_stable_id_coverage(
        self,
    ) -> None:
        with tempfile.TemporaryDirectory() as temporary:
            root = Path(temporary)
            assets = root / "assets" / "examples"
            assets.mkdir(parents=True)
            (assets / "localized.json").write_text(
                '{"id":"localized","type":"regex","expression":"a*"}',
                encoding="utf-8",
            )
            (assets / "legacy.json").write_text(
                '{"id":"legacy","type":"regex","expression":"b*"}',
                encoding="utf-8",
            )
            (root / "example_catalog.dart").write_text(
                """
const metadata = {
  'Localized': _ExampleMetadata(fileName: 'localized.json'),
  'Legacy': _ExampleMetadata(fileName: 'legacy.json'),
};
""",
                encoding="utf-8",
            )
            copy_path = root / "asset_copy.dart"
            copy_path.write_text(
                """
abstract final class FixtureCopies {
  static final _entries = List<Object>.unmodifiable([
    _entry(
      id: 'asset/localized',
      en: const AssetExampleContentCopy(
        title: 'Fixture',
        summary: 'Summary',
        learningObjective: 'Objective',
        limitation: 'Limitation',
        accessibleDescription: 'Accessible description',
      ),
      pt: const AssetExampleContentCopy(
        title: 'Exemplo',
        summary: 'Resumo',
        learningObjective: 'Objetivo',
        limitation: 'Limitação',
        accessibleDescription: 'Descrição acessível',
      ),
    ),
  ]);
}
""",
                encoding="utf-8",
            )
            sources = {
                "assetExamplesRoot": "assets/examples",
                "exampleCatalogs": [
                    {
                        "strategy": "assetMetadata",
                        "path": "example_catalog.dart",
                        "copyPath": "asset_copy.dart",
                    }
                ],
            }
            errors: list[str] = []
            records = CHECKER._example_inventory(root, sources, errors)

            self.assertEqual(errors, [])
            self.assertEqual(
                records["asset/localized"]["sourcePaths"],
                [
                    "example_catalog.dart",
                    "assets/examples/localized.json",
                    "asset_copy.dart",
                ],
            )
            self.assertEqual(
                records["asset/legacy"]["sourcePaths"],
                ["example_catalog.dart", "assets/examples/legacy.json"],
            )

            copy_path.write_text(
                copy_path.read_text(encoding="utf-8").replace(
                    "accessibleDescription: 'Descrição acessível',",
                    "",
                ),
                encoding="utf-8",
            )
            errors = []
            CHECKER._example_inventory(root, sources, errors)

        self.assertTrue(
            any(
                "assetMetadata pt copy for asset/localized "
                "has no accessibleDescription" in error
                for error in errors
            )
        )

    def test_l_system_copy_requires_complete_bilingual_stable_id_coverage(self) -> None:
        with tempfile.TemporaryDirectory() as temporary:
            root = Path(temporary)
            (root / "assets" / "examples").mkdir(parents=True)
            (root / "l_system_examples.dart").write_text(
                """
abstract final class LSystemExamples {
  static final values = List<Object>.unmodifiable([
    _example(id: 'l-system.fixture'),
  ]);
}
""",
                encoding="utf-8",
            )
            copy_path = root / "l_system_example_content_copy.dart"
            copy_path.write_text(
                """
abstract final class LSystemExampleContentCopies {
  static final _entries = List<Object>.unmodifiable([
    _entry(
      id: 'l-system.fixture',
      en: const LSystemExampleContentCopy(
        title: 'Fixture',
        summary: 'Summary',
        learningObjective: 'Objective',
        limitation: 'Limitation',
        accessibleVisualizationDescription: 'Accessible drawing',
      ),
      pt: const LSystemExampleContentCopy(
        title: 'Exemplo',
        summary: 'Resumo',
        learningObjective: 'Objetivo',
        limitation: 'Limitação',
        accessibleVisualizationDescription: 'Desenho acessível',
      ),
    ),
  ]);
}
""",
                encoding="utf-8",
            )
            (root / "payloads.json").write_text(
                json.dumps(
                    {
                        "schemaVersion": 1,
                        "contract": "canonicalRuntimeJsonV1",
                        "payloadSha256": {"l-system.fixture": "0" * 64},
                    }
                ),
                encoding="utf-8",
            )
            sources = {
                "assetExamplesRoot": "assets/examples",
                "codeBackedFormalPayloads": "payloads.json",
                "exampleCatalogs": [
                    {
                        "strategy": "lSystemValues",
                        "path": "l_system_examples.dart",
                        "copyPath": "l_system_example_content_copy.dart",
                    }
                ],
            }
            errors: list[str] = []
            records = CHECKER._example_inventory(root, sources, errors)

            self.assertEqual(errors, [])
            self.assertEqual(set(records), {"l-system.fixture"})
            self.assertEqual(
                records["l-system.fixture"]["sourcePaths"],
                [
                    "l_system_examples.dart",
                    "l_system_example_content_copy.dart",
                ],
            )

            copy_path.write_text(
                copy_path.read_text(encoding="utf-8").replace(
                    "accessibleVisualizationDescription: 'Desenho acessível',",
                    "",
                ),
                encoding="utf-8",
            )
            errors = []
            CHECKER._example_inventory(root, sources, errors)

        self.assertTrue(
            any(
                "pt copy for l-system.fixture has no "
                "accessibleVisualizationDescription" in error
                for error in errors
            )
        )

    def test_unrestricted_copy_requires_complete_bilingual_stable_id_coverage(
        self,
    ) -> None:
        with tempfile.TemporaryDirectory() as temporary:
            root = Path(temporary)
            (root / "assets" / "examples").mkdir(parents=True)
            catalog_path = root / "unrestricted_catalog.dart"
            catalog_path.write_text(
                """
final class FixtureCatalog {
  Future<List<Object>> loadExamples() async => [
    AssetExample<Object>(
      id: 'an-bn-cn',
      name: 'an-bn-cn',
      description: 'an-bn-cn',
    ),
  ];
}
""",
                encoding="utf-8",
            )
            copy_path = root / "unrestricted_copy.dart"
            copy_path.write_text(
                """
abstract final class FixtureCopies {
  static final _entries = List<Object>.unmodifiable([
    _entry(
      id: 'an-bn-cn',
      en: const UnrestrictedGrammarExampleContentCopy(
        title: 'Fixture',
        summary: 'Summary',
        learningObjective: 'Objective',
        limitation: 'Limitation',
        accessibleDescription: 'Accessible production description',
      ),
      pt: const UnrestrictedGrammarExampleContentCopy(
        title: 'Exemplo',
        summary: 'Resumo',
        learningObjective: 'Objetivo',
        limitation: 'Limitação',
        accessibleDescription: 'Descrição acessível das produções',
      ),
    ),
  ]);
}
""",
                encoding="utf-8",
            )
            (root / "payloads.json").write_text(
                json.dumps(
                    {
                        "schemaVersion": 1,
                        "contract": "canonicalRuntimeJsonV1",
                        "payloadSha256": {"an-bn-cn": "0" * 64},
                    }
                ),
                encoding="utf-8",
            )
            sources = {
                "assetExamplesRoot": "assets/examples",
                "codeBackedFormalPayloads": "payloads.json",
                "exampleCatalogs": [
                    {
                        "strategy": "unrestrictedCatalog",
                        "path": "unrestricted_catalog.dart",
                        "copyPath": "unrestricted_copy.dart",
                    }
                ],
            }
            errors: list[str] = []
            records = CHECKER._example_inventory(root, sources, errors)

            self.assertEqual(errors, [])
            self.assertEqual(set(records), {"an-bn-cn"})
            self.assertEqual(
                records["an-bn-cn"]["sourcePaths"],
                ["unrestricted_catalog.dart", "unrestricted_copy.dart"],
            )

            copy_path.write_text(
                copy_path.read_text(encoding="utf-8").replace(
                    "accessibleDescription: 'Descrição acessível das produções',",
                    "",
                ),
                encoding="utf-8",
            )
            errors = []
            CHECKER._example_inventory(root, sources, errors)

        self.assertTrue(
            any(
                "pt copy for an-bn-cn has no accessibleDescription" in error
                for error in errors
            )
        )

    def test_tm_block_copy_requires_complete_bilingual_stable_id_coverage(
        self,
    ) -> None:
        with tempfile.TemporaryDirectory() as temporary:
            root = Path(temporary)
            (root / "assets" / "examples").mkdir(parents=True)
            (root / "tm_block_catalog.dart").write_text(
                """
final class FixtureCatalog {
  Future<List<Object>> loadExamples() async => [
    AssetExample<Object>(
      id: 'tm-building-blocks-composition',
      name: 'TM blocks',
      description: 'TM blocks',
    ),
  ];
}
""",
                encoding="utf-8",
            )
            copy_path = root / "tm_block_copy.dart"
            copy_path.write_text(
                """
abstract final class FixtureCopies {
  static final _entries = List<Object>.unmodifiable([
    _entry(
      id: 'tm-building-blocks-composition',
      en: const TMBlockExampleContentCopy(
        title: 'Fixture',
        summary: 'Summary',
        learningObjective: 'Objective',
        limitation: 'Limitation',
        accessibleDescription: 'Accessible machine description',
      ),
      pt: const TMBlockExampleContentCopy(
        title: 'Exemplo',
        summary: 'Resumo',
        learningObjective: 'Objetivo',
        limitation: 'Limitação',
        accessibleDescription: 'Descrição acessível da máquina',
      ),
    ),
  ]);
}
""",
                encoding="utf-8",
            )
            (root / "payloads.json").write_text(
                json.dumps(
                    {
                        "schemaVersion": 1,
                        "contract": "canonicalRuntimeJsonV1",
                        "payloadSha256": {
                            "tm-building-blocks-composition": "0" * 64
                        },
                    }
                ),
                encoding="utf-8",
            )
            sources = {
                "assetExamplesRoot": "assets/examples",
                "codeBackedFormalPayloads": "payloads.json",
                "exampleCatalogs": [
                    {
                        "strategy": "tmBlockCatalog",
                        "path": "tm_block_catalog.dart",
                        "copyPath": "tm_block_copy.dart",
                    }
                ],
            }
            errors: list[str] = []
            records = CHECKER._example_inventory(root, sources, errors)

            self.assertEqual(errors, [])
            self.assertEqual(set(records), {"tm-building-blocks-composition"})
            self.assertEqual(
                records["tm-building-blocks-composition"]["sourcePaths"],
                ["tm_block_catalog.dart", "tm_block_copy.dart"],
            )

            copy_path.write_text(
                copy_path.read_text(encoding="utf-8").replace(
                    "accessibleDescription: 'Descrição acessível da máquina',",
                    "",
                ),
                encoding="utf-8",
            )
            errors = []
            CHECKER._example_inventory(root, sources, errors)

        self.assertTrue(
            any(
                "tmBlockCatalog pt copy for tm-building-blocks-composition "
                "has no accessibleDescription" in error
                for error in errors
            )
        )

    def test_instruction_catalog_validates_stable_reference_contracts(self) -> None:
        with tempfile.TemporaryDirectory() as temporary:
            root = Path(temporary)
            (root / "implementation.dart").write_text("void use() {}\n", encoding="utf-8")
            catalog_path = root / "instruction_catalog.dart"
            catalog_path.write_text(
                """
abstract final class FixtureContent {
  static final sample = EducationalContentReference(
    id: 'fixture-teaching/sample',
    version: 1,
    argumentKeys: <String>['stateId'],
  );
  static final shipped = List<EducationalContentReference>.unmodifiable([
    sample,
  ]);
}
""",
                encoding="utf-8",
            )
            copy_path = root / "instruction_copy.dart"
            copy_path.write_text(
                "reference: ManualConversionContent.sample,\n",
                encoding="utf-8",
            )
            sources = {
                "instructionCatalogs": [
                    {
                        "path": "instruction_catalog.dart",
                        "copyPath": "instruction_copy.dart",
                        "copyReferenceOwner": "ManualConversionContent",
                        "implementationPaths": ["implementation.dart"],
                    }
                ]
            }
            errors: list[str] = []

            records = CHECKER._instruction_inventory(root, sources, errors)

            self.assertEqual(errors, [])
            self.assertEqual(set(records), {"fixture-teaching/sample"})
            self.assertEqual(records["fixture-teaching/sample"]["contentVersion"], 1)

            copy_path.write_text(
                "reference: ManualConversionContent.unknown,\n",
                encoding="utf-8",
            )
            copy_errors: list[str] = []
            CHECKER._instruction_inventory(root, sources, copy_errors)
            self.assertTrue(
                any("localized copy coverage drifted" in error for error in copy_errors)
            )
            copy_path.write_text(
                "reference: ManualConversionContent.sample,\n",
                encoding="utf-8",
            )

            catalog_path.write_text(
                catalog_path.read_text(encoding="utf-8")
                .replace("fixture-teaching/sample", "unnamespaced")
                .replace("['stateId']", "['stateId', 'stateId']"),
                encoding="utf-8",
            )
            errors = []
            CHECKER._instruction_inventory(root, sources, errors)

        self.assertTrue(any("invalid instruction content id" in error for error in errors))
        self.assertTrue(any("argument keys are duplicated" in error for error in errors))

    def test_shipping_and_approved_review_bypasses_fail_closed(self) -> None:
        with tempfile.TemporaryDirectory() as temporary:
            root = self._copy_fixture(Path(temporary))
            path, inventory = self._load_inventory(root)
            profile = inventory["profiles"]["pending"]
            profile["shippingStatus"] = "notShipping"
            profile["localeStatus"] = {"en": "reviewed", "pt": "reviewed"}
            profile["technicalReviewStatus"] = "approved"
            profile["editorialReviewStatus"] = "approved"
            profile["accessibilityAlternativeStatus"] = "approved"
            profile["provenance"]["reviewStatus"] = "approved"
            path.write_text(json.dumps(inventory), encoding="utf-8")

            errors, _ = self._validate(root)

        self.assertTrue(any("shippingStatus is invalid" in error for error in errors))
        self.assertTrue(any("without linked review evidence" in error for error in errors))

    def test_approved_review_evidence_validates_identity_version_date_and_path(self) -> None:
        with tempfile.TemporaryDirectory() as temporary:
            root = self._copy_fixture(Path(temporary))
            path, inventory = self._load_inventory(root)
            profile = inventory["profiles"]["pending"]
            profile["technicalReviewStatus"] = "approved"
            profile["reviewEvidence"] = [
                {
                    "scope": "technical",
                    "reviewerId": "reviewer-1",
                    "reviewerType": "unknown-role",
                    "reviewedContentVersion": 2,
                    "reviewedAt": "not-a-date",
                    "evidencePath": "test/missing-review.md",
                }
            ]
            path.write_text(json.dumps(inventory), encoding="utf-8")

            errors, _ = self._validate(root)

        self.assertTrue(any("reviewerType is invalid" in error for error in errors))
        self.assertTrue(any("reviewedContentVersion" in error for error in errors))
        self.assertTrue(any("reviewedAt must be an ISO date" in error for error in errors))
        self.assertTrue(any("evidencePath must reference a file" in error for error in errors))

    def test_non_shipping_collection_requires_removal_evidence_and_no_overlap(self) -> None:
        with tempfile.TemporaryDirectory() as temporary:
            root = self._copy_fixture(Path(temporary))
            path, inventory = self._load_inventory(root)
            inventory["nonShippingEntries"] = [
                {
                    "contentId": "asset/fixture",
                    "kind": "example",
                    "rationale": "Removed fixture.",
                    "removedInVersion": "2",
                    "ownerIssue": 344,
                    "removalEvidence": ["test/missing-removal-evidence.txt"],
                }
            ]
            path.write_text(json.dumps(inventory), encoding="utf-8")

            errors, _ = self._validate(root)

        self.assertTrue(any("missing removal evidence" in error for error in errors))
        self.assertTrue(any("overlaps shipped/source-discovered" in error for error in errors))

if __name__ == "__main__":
    unittest.main()
