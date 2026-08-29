from __future__ import annotations

import importlib.util
import json
import shutil
import tempfile
import unittest
from pathlib import Path


REPO_ROOT = Path(__file__).resolve().parents[2]
MODULE_PATH = REPO_ROOT / "tool" / "check_feature_localization.py"
SPEC = importlib.util.spec_from_file_location("check_feature_localization", MODULE_PATH)
assert SPEC is not None and SPEC.loader is not None
CHECKER = importlib.util.module_from_spec(SPEC)
SPEC.loader.exec_module(CHECKER)
FIXTURE_ROOT = (
    REPO_ROOT / "test" / "fixtures" / "localization" / "feature_ownership" / "valid"
)


class FeatureLocalizationValidatorTest(unittest.TestCase):
    _standard_capabilities = frozenset(
        {
            "editing",
            "validation",
            "simulation",
            "interoperability",
            "examples",
            "locale-state",
            "formal-content",
        }
    )

    def setUp(self) -> None:
        CHECKER.AUTHORITATIVE_RUNTIME_CAPABILITIES["fixture-standard"] = (
            self._standard_capabilities
        )
        self.addCleanup(
            CHECKER.AUTHORITATIVE_RUNTIME_CAPABILITIES.pop,
            "fixture-standard",
            None,
        )

    def _validate(self, root: Path) -> list[str]:
        return CHECKER.validate_repository(
            root,
            root / "feature_ownership.v1.json",
            expected_descriptor_count=1,
        )

    def _copy_fixture(self, destination: Path) -> Path:
        root = destination / "fixture"
        shutil.copytree(FIXTURE_ROOT, root)
        return root

    def test_valid_fixture_passes(self) -> None:
        self.assertEqual(self._validate(FIXTURE_ROOT), [])

    def test_duplicate_json_keys_fail_closed(self) -> None:
        with tempfile.TemporaryDirectory() as temporary:
            root = self._copy_fixture(Path(temporary))
            inventory_path = root / "feature_ownership.v1.json"
            inventory_text = inventory_path.read_text(encoding="utf-8")
            inventory_path.write_text(
                inventory_text.replace(
                    '"schemaVersion": 1,',
                    '"schemaVersion": 1,\n  "schemaVersion": 1,',
                    1,
                ),
                encoding="utf-8",
            )

            errors = self._validate(root)

        self.assertTrue(
            any("duplicate JSON key: schemaVersion" in error for error in errors)
        )

    def test_placeholder_drift_fails_closed(self) -> None:
        with tempfile.TemporaryDirectory() as temporary:
            root = self._copy_fixture(Path(temporary))
            pt_path = root / "app_pt.arb"
            pt = json.loads(pt_path.read_text(encoding="utf-8"))
            pt["@featureLabel"]["placeholders"]["count"]["type"] = "String"
            pt_path.write_text(json.dumps(pt), encoding="utf-8")

            errors = self._validate(root)

        self.assertTrue(any("placeholder metadata differs" in error for error in errors))

    def test_icu_select_branch_labels_are_not_placeholders(self) -> None:
        with tempfile.TemporaryDirectory() as temporary:
            root = self._copy_fixture(Path(temporary))
            messages = {
                "app_en.arb": "{type, select, start{Start} analyze{Analyze} other{Unknown}}",
                "app_pt.arb": "{type, select, start{Início} analyze{Análise} other{Desconhecido}}",
            }
            for filename, message in messages.items():
                path = root / filename
                arb = json.loads(path.read_text(encoding="utf-8"))
                arb["featureLabel"] = message
                arb["@featureLabel"]["placeholders"] = {
                    "type": {"type": "String"}
                }
                path.write_text(json.dumps(arb), encoding="utf-8")

            errors = self._validate(root)

        self.assertEqual(errors, [])

    def test_undeclared_message_placeholder_drift_fails_closed(self) -> None:
        with tempfile.TemporaryDirectory() as temporary:
            root = self._copy_fixture(Path(temporary))
            messages = {
                "app_en.arb": "Feature {undeclared}",
                "app_pt.arb": "Recurso",
            }
            for filename, message in messages.items():
                path = root / filename
                arb = json.loads(path.read_text(encoding="utf-8"))
                arb["featureLabel"] = message
                path.write_text(json.dumps(arb), encoding="utf-8")

            errors = self._validate(root)

        self.assertTrue(
            any("message placeholders differ for featureLabel" in error for error in errors)
        )

    def test_unowned_residual_parity_row_fails_closed(self) -> None:
        with tempfile.TemporaryDirectory() as temporary:
            root = self._copy_fixture(Path(temporary))
            inventory_path = root / "feature_ownership.v1.json"
            inventory = json.loads(inventory_path.read_text(encoding="utf-8"))
            inventory["workflowEntries"][0]["parityCoverage"] = {}
            inventory_path.write_text(json.dumps(inventory), encoding="utf-8")

            errors = self._validate(root)

        self.assertIn(
            "residual localization parity row has no owner: workflow-fixture",
            errors,
        )

    def test_registry_namespace_and_evidence_paths_are_required(self) -> None:
        with tempfile.TemporaryDirectory() as temporary:
            root = self._copy_fixture(Path(temporary))
            (root / "registry.dart.txt").write_text(
                "// Missing declaration.\n", encoding="utf-8"
            )
            (root / "test" / "evidence_test.dart.txt").unlink()

            errors = self._validate(root)

        self.assertTrue(any("namespace is absent" in error for error in errors))
        self.assertTrue(any("path is missing" in error for error in errors))

    def test_capability_evidence_cannot_reference_stale_tests(self) -> None:
        with tempfile.TemporaryDirectory() as temporary:
            root = self._copy_fixture(Path(temporary))
            inventory_path = root / "feature_ownership.v1.json"
            inventory = json.loads(inventory_path.read_text(encoding="utf-8"))
            inventory["workflowEntries"][0]["capabilityEvidence"] = {
                "workflow-fixture": {
                    "testPath": "test/stale_evidence.dart.txt",
                    "assertions": ["localized-editor-fields"],
                }
            }
            inventory_path.write_text(json.dumps(inventory), encoding="utf-8")

            errors = self._validate(root)

        self.assertIn(
            "workflowEntries[0].capabilityEvidence['workflow-fixture'].testPath "
            "path is missing: test/stale_evidence.dart.txt",
            errors,
        )

    def test_covered_workspace_requires_executable_runtime_evidence(self) -> None:
        with tempfile.TemporaryDirectory() as temporary:
            root = self._copy_fixture(Path(temporary))
            inventory_path = root / "feature_ownership.v1.json"
            inventory = json.loads(inventory_path.read_text(encoding="utf-8"))
            inventory["descriptorEntries"][0]["scope"] = (
                "descriptor-registration-and-workspace"
            )
            inventory_path.write_text(json.dumps(inventory), encoding="utf-8")

            errors = self._validate(root)

        self.assertTrue(
            any("runtimeEvidence is required" in error for error in errors)
        )

    def test_covered_workspace_requires_all_runtime_surfaces(self) -> None:
        with tempfile.TemporaryDirectory() as temporary:
            root = self._copy_fixture(Path(temporary))
            inventory_path = root / "feature_ownership.v1.json"
            inventory = json.loads(inventory_path.read_text(encoding="utf-8"))
            entry = inventory["descriptorEntries"][0]
            entry["scope"] = "descriptor-registration-and-workspace"
            entry["runtimeEvidence"] = {
                "contractId": "fixture-standard",
                "testPath": "test/evidence_test.dart.txt",
                "locales": ["en", "pt"],
                "viewportProfiles": ["phone-320x700-text-200"],
                "capabilities": [
                    "editing",
                    "validation",
                    "simulation",
                    "interoperability",
                    "examples",
                    "locale-state",
                    "formal-content",
                ],
                "assertions": ["localized-error"],
            }
            (root / "test" / "evidence_test.dart.txt").write_text(
                "// feature-localization-contract: fixture-standard\n"
                "const Locale('en');\nconst Locale('pt');\n",
                encoding="utf-8",
            )
            inventory_path.write_text(json.dumps(inventory), encoding="utf-8")

            errors = self._validate(root)

        self.assertTrue(
            any("assertions misses required coverage" in error for error in errors)
        )
        self.assertTrue(
            any(
                "no executable marker for localized-error" in error
                for error in errors
            )
        )

    def test_covered_workspace_does_not_require_comparison_capability(self) -> None:
        with tempfile.TemporaryDirectory() as temporary:
            root = self._copy_fixture(Path(temporary))
            inventory_path = root / "feature_ownership.v1.json"
            inventory = json.loads(inventory_path.read_text(encoding="utf-8"))
            entry = inventory["descriptorEntries"][0]
            assertions = [
                "localized-editor-fields",
                "localized-error",
                "localized-valid-simulation",
                "localized-import-export",
                "locale-switch-state-preservation",
                "localized-example-metadata",
                "formal-content-preservation",
            ]
            entry["scope"] = "descriptor-registration-and-workspace"
            entry["runtimeEvidence"] = {
                "contractId": "fixture-standard",
                "testPath": "test/evidence_test.dart.txt",
                "locales": ["en", "pt"],
                "viewportProfiles": ["phone-320x700-text-200"],
                "capabilities": sorted(self._standard_capabilities),
                "assertions": assertions,
            }
            (root / "test" / "evidence_test.dart.txt").write_text(
                "// feature-localization-contract: fixture-standard\n"
                "const Locale('en');\nconst Locale('pt');\n"
                + "".join(
                    f"// feature-localization-surface: {assertion}\n"
                    for assertion in assertions
                ),
                encoding="utf-8",
            )
            inventory_path.write_text(json.dumps(inventory), encoding="utf-8")

            errors = self._validate(root)

        self.assertEqual(errors, [])

    def test_covered_comparison_workspace_requires_comparison_evidence(self) -> None:
        with tempfile.TemporaryDirectory() as temporary:
            root = self._copy_fixture(Path(temporary))
            inventory_path = root / "feature_ownership.v1.json"
            inventory = json.loads(inventory_path.read_text(encoding="utf-8"))
            entry = inventory["descriptorEntries"][0]
            assertions = [
                "localized-editor-fields",
                "localized-error",
                "localized-valid-simulation",
                "localized-import-export",
                "locale-switch-state-preservation",
                "localized-example-metadata",
                "formal-content-preservation",
            ]
            entry["scope"] = "descriptor-registration-and-workspace"
            entry["runtimeEvidence"] = {
                "contractId": "fixture-standard",
                "testPath": "test/evidence_test.dart.txt",
                "locales": ["en", "pt"],
                "viewportProfiles": ["phone-320x700-text-200"],
                "capabilities": [
                    "editing",
                    "validation",
                    "simulation",
                    "comparison",
                    "interoperability",
                    "examples",
                    "locale-state",
                    "formal-content",
                ],
                "assertions": assertions,
            }
            (root / "test" / "evidence_test.dart.txt").write_text(
                "// feature-localization-contract: fixture-standard\n"
                "const Locale('en');\nconst Locale('pt');\n"
                + "".join(
                    f"// feature-localization-surface: {assertion}\n"
                    for assertion in assertions
                ),
                encoding="utf-8",
            )
            inventory_path.write_text(json.dumps(inventory), encoding="utf-8")

            errors = self._validate(root)

        self.assertTrue(
            any("assertions misses required coverage" in error for error in errors)
        )

    def test_preference_workspace_requires_only_declared_capability_surfaces(
        self,
    ) -> None:
        preference_capabilities = frozenset(
            {
                "preference",
                "validation",
                "simulation",
                "persistence",
                "locale-state",
                "formal-content",
            }
        )
        CHECKER.AUTHORITATIVE_RUNTIME_CAPABILITIES["fixture-standard"] = (
            preference_capabilities
        )
        with tempfile.TemporaryDirectory() as temporary:
            root = self._copy_fixture(Path(temporary))
            inventory_path = root / "feature_ownership.v1.json"
            inventory = json.loads(inventory_path.read_text(encoding="utf-8"))
            entry = inventory["descriptorEntries"][0]
            assertions = [
                "localized-preference-control",
                "localized-error",
                "localized-valid-simulation",
                "production-session-persistence",
                "locale-switch-state-preservation",
                "formal-content-preservation",
            ]
            entry["scope"] = "workspace"
            entry["runtimeEvidence"] = {
                "contractId": "fixture-standard",
                "testPath": "test/evidence_test.dart.txt",
                "locales": ["en", "pt"],
                "viewportProfiles": ["phone-320x700-text-200"],
                "capabilities": sorted(preference_capabilities),
                "assertions": assertions,
            }
            (root / "test" / "evidence_test.dart.txt").write_text(
                "// feature-localization-contract: fixture-standard\n"
                "const Locale('en');\nconst Locale('pt');\n"
                + "".join(
                    f"// feature-localization-surface: {assertion}\n"
                    for assertion in assertions
                ),
                encoding="utf-8",
            )
            inventory_path.write_text(json.dumps(inventory), encoding="utf-8")

            errors = self._validate(root)

        self.assertEqual(errors, [])

    def test_preference_workspace_fails_without_preference_evidence(self) -> None:
        CHECKER.AUTHORITATIVE_RUNTIME_CAPABILITIES["fixture-standard"] = frozenset(
            {"preference"}
        )
        with tempfile.TemporaryDirectory() as temporary:
            root = self._copy_fixture(Path(temporary))
            inventory_path = root / "feature_ownership.v1.json"
            inventory = json.loads(inventory_path.read_text(encoding="utf-8"))
            entry = inventory["descriptorEntries"][0]
            entry["scope"] = "workspace"
            entry["runtimeEvidence"] = {
                "contractId": "fixture-standard",
                "testPath": "test/evidence_test.dart.txt",
                "locales": ["en", "pt"],
                "viewportProfiles": ["phone-320x700-text-200"],
                "capabilities": ["preference"],
                "assertions": [],
            }
            (root / "test" / "evidence_test.dart.txt").write_text(
                "// feature-localization-contract: fixture-standard\n"
                "const Locale('en');\nconst Locale('pt');\n",
                encoding="utf-8",
            )
            inventory_path.write_text(json.dumps(inventory), encoding="utf-8")

            errors = self._validate(root)

        self.assertTrue(
            any("assertions misses required coverage" in error for error in errors)
        )

    def test_layout_workspace_accepts_complete_capability_evidence(self) -> None:
        layout_capabilities = frozenset(
            {
                "layout.constructive",
                "layout.transforms",
                "layout.restore",
                "validation",
                "locale-state",
                "formal-content",
                "accessibility",
            }
        )
        CHECKER.AUTHORITATIVE_RUNTIME_CAPABILITIES["fixture-standard"] = (
            layout_capabilities
        )
        assertions = [
            "localized-layout-constructive",
            "localized-layout-transforms",
            "localized-layout-restore",
            "localized-error",
            "locale-switch-state-preservation",
            "formal-content-preservation",
            "responsive-accessibility",
        ]
        with tempfile.TemporaryDirectory() as temporary:
            root = self._copy_fixture(Path(temporary))
            inventory_path = root / "feature_ownership.v1.json"
            inventory = json.loads(inventory_path.read_text(encoding="utf-8"))
            entry = inventory["descriptorEntries"][0]
            entry["scope"] = "workspace"
            entry["runtimeEvidence"] = {
                "contractId": "fixture-standard",
                "testPath": "test/evidence_test.dart.txt",
                "locales": ["en", "pt"],
                "viewportProfiles": ["phone-320x700-text-200"],
                "capabilities": sorted(layout_capabilities),
                "assertions": assertions,
            }
            (root / "test" / "evidence_test.dart.txt").write_text(
                "// feature-localization-contract: fixture-standard\n"
                "const Locale('en');\nconst Locale('pt');\n"
                + "".join(
                    f"// feature-localization-surface: {assertion}\n"
                    for assertion in assertions
                ),
                encoding="utf-8",
            )
            inventory_path.write_text(json.dumps(inventory), encoding="utf-8")

            errors = self._validate(root)

        self.assertEqual(errors, [])

    def test_layout_workspace_cannot_omit_transform_capability(self) -> None:
        layout_capabilities = frozenset(
            {
                "layout.constructive",
                "layout.transforms",
                "layout.restore",
            }
        )
        CHECKER.AUTHORITATIVE_RUNTIME_CAPABILITIES["fixture-standard"] = (
            layout_capabilities
        )
        with tempfile.TemporaryDirectory() as temporary:
            root = self._copy_fixture(Path(temporary))
            inventory_path = root / "feature_ownership.v1.json"
            inventory = json.loads(inventory_path.read_text(encoding="utf-8"))
            entry = inventory["descriptorEntries"][0]
            entry["scope"] = "workspace"
            entry["runtimeEvidence"] = {
                "contractId": "fixture-standard",
                "testPath": "test/evidence_test.dart.txt",
                "locales": ["en", "pt"],
                "viewportProfiles": ["phone-320x700-text-200"],
                "capabilities": ["layout.constructive", "layout.restore"],
                "assertions": [
                    "localized-layout-constructive",
                    "localized-layout-restore",
                ],
            }
            (root / "test" / "evidence_test.dart.txt").write_text(
                "// feature-localization-contract: fixture-standard\n"
                "const Locale('en');\nconst Locale('pt');\n"
                "// feature-localization-surface: localized-layout-constructive\n"
                "// feature-localization-surface: localized-layout-restore\n",
                encoding="utf-8",
            )
            inventory_path.write_text(json.dumps(inventory), encoding="utf-8")

            errors = self._validate(root)

        self.assertTrue(
            any(
                "omits authoritative capabilities: layout.transforms" in error
                for error in errors
            )
        )

    def test_automata_diagnostics_accepts_complete_capability_evidence(self) -> None:
        capabilities = frozenset(
            {
                "simulation.computation-tree",
                "simulation.nondeterminism-highlight",
                "simulation.epsilon-highlight",
                "analysis.dfa-equivalence",
                "validation",
                "bounded-results",
                "locale-state",
                "formal-content",
                "accessibility",
            }
        )
        CHECKER.AUTHORITATIVE_RUNTIME_CAPABILITIES["fixture-standard"] = capabilities
        assertions = [
            "localized-computation-tree",
            "localized-nondeterminism-highlight",
            "localized-epsilon-highlight",
            "localized-dfa-equivalence",
            "localized-error",
            "localized-bounded-result",
            "locale-switch-state-preservation",
            "formal-content-preservation",
            "responsive-accessibility",
        ]
        with tempfile.TemporaryDirectory() as temporary:
            root = self._copy_fixture(Path(temporary))
            inventory_path = root / "feature_ownership.v1.json"
            inventory = json.loads(inventory_path.read_text(encoding="utf-8"))
            entry = inventory["descriptorEntries"][0]
            entry["scope"] = "workspace"
            entry["runtimeEvidence"] = {
                "contractId": "fixture-standard",
                "testPath": "test/evidence_test.dart.txt",
                "locales": ["en", "pt"],
                "viewportProfiles": ["phone-320x700-text-200"],
                "capabilities": sorted(capabilities),
                "assertions": assertions,
            }
            (root / "test" / "evidence_test.dart.txt").write_text(
                "// feature-localization-contract: fixture-standard\n"
                "const Locale('en');\nconst Locale('pt');\n"
                + "".join(
                    f"// feature-localization-surface: {assertion}\n"
                    for assertion in assertions
                ),
                encoding="utf-8",
            )
            inventory_path.write_text(json.dumps(inventory), encoding="utf-8")

            errors = self._validate(root)

        self.assertEqual(errors, [])

    def test_automata_diagnostics_cannot_omit_epsilon_capability(self) -> None:
        capabilities = frozenset(
            {
                "simulation.computation-tree",
                "simulation.nondeterminism-highlight",
                "simulation.epsilon-highlight",
                "analysis.dfa-equivalence",
            }
        )
        CHECKER.AUTHORITATIVE_RUNTIME_CAPABILITIES["fixture-standard"] = capabilities
        with tempfile.TemporaryDirectory() as temporary:
            root = self._copy_fixture(Path(temporary))
            inventory_path = root / "feature_ownership.v1.json"
            inventory = json.loads(inventory_path.read_text(encoding="utf-8"))
            entry = inventory["descriptorEntries"][0]
            entry["scope"] = "workspace"
            entry["runtimeEvidence"] = {
                "contractId": "fixture-standard",
                "testPath": "test/evidence_test.dart.txt",
                "locales": ["en", "pt"],
                "viewportProfiles": ["phone-320x700-text-200"],
                "capabilities": [
                    "simulation.computation-tree",
                    "simulation.nondeterminism-highlight",
                    "analysis.dfa-equivalence",
                ],
                "assertions": [
                    "localized-computation-tree",
                    "localized-nondeterminism-highlight",
                    "localized-dfa-equivalence",
                ],
            }
            (root / "test" / "evidence_test.dart.txt").write_text(
                "// feature-localization-contract: fixture-standard\n"
                "const Locale('en');\nconst Locale('pt');\n"
                "// feature-localization-surface: localized-computation-tree\n"
                "// feature-localization-surface: localized-nondeterminism-highlight\n"
                "// feature-localization-surface: localized-dfa-equivalence\n",
                encoding="utf-8",
            )
            inventory_path.write_text(json.dumps(inventory), encoding="utf-8")

            errors = self._validate(root)

        self.assertTrue(
            any(
                "omits authoritative capabilities: simulation.epsilon-highlight"
                in error
                for error in errors
            )
        )

    def test_covered_workspace_cannot_omit_authoritative_capability(self) -> None:
        with tempfile.TemporaryDirectory() as temporary:
            root = self._copy_fixture(Path(temporary))
            inventory_path = root / "feature_ownership.v1.json"
            inventory = json.loads(inventory_path.read_text(encoding="utf-8"))
            entry = inventory["descriptorEntries"][0]
            capabilities = sorted(self._standard_capabilities - {"formal-content"})
            assertions = [
                "localized-editor-fields",
                "localized-error",
                "localized-valid-simulation",
                "localized-import-export",
                "locale-switch-state-preservation",
                "localized-example-metadata",
                "formal-content-preservation",
            ]
            entry["scope"] = "workspace"
            entry["runtimeEvidence"] = {
                "contractId": "fixture-standard",
                "testPath": "test/evidence_test.dart.txt",
                "locales": ["en", "pt"],
                "viewportProfiles": ["phone-320x700-text-200"],
                "capabilities": capabilities,
                "assertions": assertions,
            }
            (root / "test" / "evidence_test.dart.txt").write_text(
                "// feature-localization-contract: fixture-standard\n"
                "const Locale('en');\nconst Locale('pt');\n"
                + "".join(
                    f"// feature-localization-surface: {assertion}\n"
                    for assertion in assertions
                ),
                encoding="utf-8",
            )
            inventory_path.write_text(json.dumps(inventory), encoding="utf-8")

            errors = self._validate(root)

        self.assertTrue(
            any(
                "omits authoritative capabilities: formal-content" in error
                for error in errors
            )
        )


if __name__ == "__main__":
    unittest.main()
