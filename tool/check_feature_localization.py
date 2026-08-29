#!/usr/bin/env python3
"""Validate feature-localization ownership against registry, ARBs, and parity."""

from __future__ import annotations

import argparse
import json
import re
import sys
from collections import Counter
from pathlib import Path
from typing import Any

_TOOL_DIRECTORY = str(Path(__file__).resolve().parent)
if _TOOL_DIRECTORY not in sys.path:
    sys.path.insert(0, _TOOL_DIRECTORY)

from icu_message_parser import IcuMessageParser, IcuSyntaxError  # noqa: E402


EXPECTED_OWNERS = {
    "sharedChrome": 163,
    "structuredMessages": 210,
    "featureInterface": 343,
    "helpTutorialExamples": 344,
}
EXPECTED_ENTRY_OWNERS = {
    "featureOwnerIssue": 343,
    "helpContentOwnerIssue": 344,
    "sharedChromeOwnerIssue": 163,
    "structuredMessagesOwnerIssue": 210,
}
RESIDUAL_STATUSES = {"partial", "missing", "planned"}
COMPLETION_STATUSES = {"covered", "partial", "missing", "planned"}
PLACEHOLDER_PATTERN = re.compile(r"\{([A-Za-z_][A-Za-z0-9_]*)\s*(?:,|\})")
AUTHORITATIVE_RUNTIME_CAPABILITIES = {
    "transducer-mealy": frozenset(
        {
            "editing",
            "validation",
            "simulation",
            "comparison",
            "interoperability",
            "examples",
            "locale-state",
            "formal-content",
        }
    ),
    "transducer-moore": frozenset(
        {
            "editing",
            "validation",
            "simulation",
            "comparison",
            "interoperability",
            "examples",
            "locale-state",
            "formal-content",
        }
    ),
    "grammar-unrestricted": frozenset(
        {
            "editing",
            "validation",
            "simulation",
            "analysis",
            "trace",
            "interoperability",
            "examples",
            "help",
            "session",
            "locale-state",
            "formal-content",
        }
    ),
    "l-system-deterministic-context-free": frozenset(
        {
            "editing",
            "validation",
            "simulation",
            "interoperability",
            "examples",
            "locale-state",
            "formal-content",
            "deterministic-expansion",
            "turtle-rendering",
            "advanced-rewriting",
        }
    ),
    "l-system-workspace": frozenset(
        {
            "editing",
            "validation",
            "simulation",
            "interoperability",
            "examples",
            "locale-state",
            "formal-content",
            "deterministic-expansion",
            "turtle-rendering",
            "advanced-rewriting",
            "persistence",
        }
    ),
    "tm-acceptance-preference": frozenset(
        {
            "preference",
            "simulation",
            "persistence",
            "locale-state",
            "formal-content",
            "accessibility",
        }
    ),
    "automata-layout": frozenset(
        {
            "layout.constructive",
            "layout.transforms",
            "layout.restore",
            "validation",
            "locale-state",
            "formal-content",
            "accessibility",
        }
    ),
    "automata-diagnostics-and-equivalence": frozenset(
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
    ),
    "pumping-lemma-workspaces": frozenset(
        {
            "editing",
            "validation",
            "simulation",
            "interoperability",
            "examples",
            "locale-state",
            "formal-content",
            "accessibility",
        }
    ),
}


class DuplicateKeyError(ValueError):
    """Raised when a JSON object repeats a key."""


def _unique_object(pairs: list[tuple[str, Any]]) -> dict[str, Any]:
    result: dict[str, Any] = {}
    for key, value in pairs:
        if key in result:
            raise DuplicateKeyError(f"duplicate JSON key: {key}")
        result[key] = value
    return result


def _read_json(path: Path, errors: list[str]) -> dict[str, Any] | None:
    try:
        value = json.loads(
            path.read_text(encoding="utf-8"), object_pairs_hook=_unique_object
        )
    except FileNotFoundError:
        errors.append(f"missing JSON file: {path}")
        return None
    except (OSError, UnicodeError, json.JSONDecodeError, DuplicateKeyError) as error:
        errors.append(f"cannot read JSON file {path}: {error}")
        return None
    if not isinstance(value, dict):
        errors.append(f"JSON root must be an object: {path}")
        return None
    return value


def _string_list(value: Any, label: str, errors: list[str]) -> list[str]:
    if not isinstance(value, list) or any(
        not isinstance(item, str) or not item for item in value
    ):
        errors.append(f"{label} must be a list of non-empty strings")
        return []
    return value


def _message_keys(arb: dict[str, Any]) -> set[str]:
    return {key for key in arb if not key.startswith("@")}


def _placeholder_contract(arb: dict[str, Any], key: str) -> dict[str, str]:
    metadata = arb.get(f"@{key}")
    if not isinstance(metadata, dict):
        return {}
    placeholders = metadata.get("placeholders")
    if not isinstance(placeholders, dict):
        return {}
    result: dict[str, str] = {}
    for name, attributes in placeholders.items():
        if not isinstance(name, str):
            continue
        placeholder_type = ""
        if isinstance(attributes, dict) and isinstance(attributes.get("type"), str):
            placeholder_type = attributes["type"]
        result[name] = placeholder_type
    return result


def _validate_arb_parity(
    en: dict[str, Any], pt: dict[str, Any], errors: list[str]
) -> tuple[set[str], set[str]]:
    en_keys = _message_keys(en)
    pt_keys = _message_keys(pt)
    for key in sorted(en_keys - pt_keys):
        errors.append(f"Portuguese ARB is missing key: {key}")
    for key in sorted(pt_keys - en_keys):
        errors.append(f"English ARB is missing key: {key}")
    for key in sorted(en_keys & pt_keys):
        en_message = en[key]
        pt_message = pt[key]
        if not isinstance(en_message, str) or not isinstance(pt_message, str):
            errors.append(f"ARB messages must be strings: {key}")
            continue
        en_contract = _placeholder_contract(en, key)
        pt_contract = _placeholder_contract(pt, key)
        if en_contract != pt_contract:
            errors.append(
                f"placeholder metadata differs for {key}: "
                f"en={en_contract}, pt={pt_contract}"
            )
        en_used = _icu_argument_names(en_message)
        pt_used = _icu_argument_names(pt_message)
        if en_used != pt_used:
            errors.append(
                f"message placeholders differ for {key}: "
                f"en={sorted(en_used)}, pt={sorted(pt_used)}"
            )
    return en_keys, pt_keys


def _icu_argument_names(message: str) -> set[str]:
    try:
        return {use.name for use in IcuMessageParser(message).parse()}
    except IcuSyntaxError:
        return set(PLACEHOLDER_PATTERN.findall(message))


def _load_parity_rows(parity_root: Path, errors: list[str]) -> dict[str, str]:
    if not parity_root.is_dir():
        errors.append(f"parity root is missing: {parity_root}")
        return {}
    rows: dict[str, str] = {}
    for path in sorted(parity_root.glob("*.json")):
        document = _read_json(path, errors)
        if document is None:
            continue
        raw_rows = document.get("rows", [])
        if not isinstance(raw_rows, list):
            errors.append(f"parity rows must be a list: {path}")
            continue
        for row in raw_rows:
            if not isinstance(row, dict) or not isinstance(row.get("id"), str):
                errors.append(f"parity row has no string id: {path}")
                continue
            row_id = row["id"]
            dimensions = row.get("dimensions")
            status = dimensions.get("localization") if isinstance(dimensions, dict) else None
            if not isinstance(status, str):
                errors.append(f"parity row has no localization status: {row_id}")
                continue
            if row_id in rows:
                errors.append(f"duplicate parity row id: {row_id}")
            rows[row_id] = status
    return rows


def _validate_arb_coverage(
    entry: dict[str, Any],
    label: str,
    en_keys: set[str],
    pt_keys: set[str],
    errors: list[str],
) -> None:
    coverage = entry.get("arbCoverage")
    if not isinstance(coverage, dict):
        errors.append(f"{label}.arbCoverage must be an object")
        return
    english = _string_list(coverage.get("englishKeys"), f"{label}.englishKeys", errors)
    portuguese = _string_list(
        coverage.get("portugueseKeys"), f"{label}.portugueseKeys", errors
    )
    prefixes = _string_list(coverage.get("keyPrefixes"), f"{label}.keyPrefixes", errors)
    if english != portuguese:
        errors.append(f"{label} must map the same stable keys in English and Portuguese")
    for key in english:
        if key not in en_keys:
            errors.append(f"{label} references missing English ARB key: {key}")
    for key in portuguese:
        if key not in pt_keys:
            errors.append(f"{label} references missing Portuguese ARB key: {key}")
    for prefix in prefixes:
        if not any(key.startswith(prefix) for key in en_keys):
            errors.append(f"{label} English ARB prefix matches no keys: {prefix}")
        if not any(key.startswith(prefix) for key in pt_keys):
            errors.append(f"{label} Portuguese ARB prefix matches no keys: {prefix}")
    status = entry.get("completionStatus")
    if status not in {"missing", "planned"} and not english and not prefixes:
        errors.append(f"{label} status {status!r} requires an existing ARB anchor")


def _validate_capability_evidence(
    entry: dict[str, Any],
    label: str,
    repo_root: Path,
    capability_ids: set[str],
    errors: list[str],
) -> None:
    if "capabilityEvidence" not in entry:
        return
    raw_evidence = entry.get("capabilityEvidence")
    if not isinstance(raw_evidence, dict):
        errors.append(f"{label}.capabilityEvidence must be an object")
        return
    listed_tests = set(
        _string_list(
            entry.get("representativeBilingualTests"),
            f"{label}.representativeBilingualTests",
            errors,
        )
    ) | set(
        _string_list(
            entry.get("evidenceTests", []),
            f"{label}.evidenceTests",
            errors,
        )
    )
    for capability_id, raw_contract in raw_evidence.items():
        evidence_label = f"{label}.capabilityEvidence[{capability_id!r}]"
        if not isinstance(capability_id, str) or not capability_id:
            errors.append(f"{label}.capabilityEvidence keys must be non-empty strings")
            continue
        if capability_id not in capability_ids:
            errors.append(
                f"{evidence_label} references an undeclared capability: "
                f"{capability_id}"
            )
        if not isinstance(raw_contract, dict):
            errors.append(f"{evidence_label} must be an object")
            continue
        test_path = raw_contract.get("testPath")
        if not isinstance(test_path, str) or not test_path:
            errors.append(f"{evidence_label}.testPath must be a non-empty string")
            continue
        if not test_path.startswith("test/"):
            errors.append(f"{evidence_label}.testPath must point under test/: {test_path}")
            continue
        if test_path not in listed_tests:
            errors.append(
                f"{evidence_label}.testPath must be listed in representativeBilingualTests "
                f"or evidenceTests: {test_path}"
            )
        test_file = repo_root / test_path
        if not test_file.is_file():
            errors.append(f"{evidence_label}.testPath path is missing: {test_path}")
            continue
        assertions = _string_list(
            raw_contract.get("assertions"),
            f"{evidence_label}.assertions",
            errors,
        )
        if not assertions:
            errors.append(f"{evidence_label}.assertions must not be empty")
            continue
        try:
            test_text = test_file.read_text(encoding="utf-8")
        except (OSError, UnicodeError) as error:
            errors.append(f"cannot read capability evidence {test_path}: {error}")
            continue
        for assertion in assertions:
            marker = f"feature-localization-surface: {assertion}"
            if marker not in test_text:
                errors.append(
                    f"{evidence_label}.assertions has no executable marker for "
                    f"{assertion}"
                )


def _validate_entry_common(
    entry: Any,
    label: str,
    repo_root: Path,
    en_keys: set[str],
    pt_keys: set[str],
    errors: list[str],
) -> dict[str, Any] | None:
    if not isinstance(entry, dict):
        errors.append(f"{label} must be an object")
        return None
    if not isinstance(entry.get("id"), str) or not entry["id"]:
        errors.append(f"{label}.id must be a non-empty string")
    completion_status = entry.get("completionStatus")
    if completion_status not in COMPLETION_STATUSES:
        errors.append(
            f"{label}.completionStatus is invalid: {completion_status!r}"
        )
    for field, issue in EXPECTED_ENTRY_OWNERS.items():
        if entry.get(field) != issue:
            errors.append(f"{label}.{field} must be #{issue}")
    _validate_arb_coverage(entry, label, en_keys, pt_keys, errors)
    for field in ("representativeBilingualTests", "evidenceTests"):
        if field not in entry:
            if field == "evidenceTests":
                continue
            errors.append(f"{label}.{field} is required")
            continue
        for relative in _string_list(entry[field], f"{label}.{field}", errors):
            if not relative.startswith("test/"):
                errors.append(f"{label}.{field} must point under test/: {relative}")
            elif not (repo_root / relative).is_file():
                errors.append(f"{label}.{field} path is missing: {relative}")
    parity = entry.get("parityCoverage")
    if not isinstance(parity, dict) or any(
        not isinstance(key, str) or not isinstance(value, str)
        for key, value in parity.items()
    ):
        errors.append(f"{label}.parityCoverage must map ids to statuses")
    else:
        for row_id, parity_status in parity.items():
            if not row_id:
                errors.append(f"{label}.parityCoverage contains an empty id")
            if parity_status not in COMPLETION_STATUSES | {"notApplicable"}:
                errors.append(
                    f"{label}.parityCoverage has invalid status for {row_id}: "
                    f"{parity_status}"
                )
        if any(status == "covered" for status in parity.values()) and not entry.get(
            "representativeBilingualTests"
        ):
            errors.append(
                f"{label} claims covered parity without representative bilingual evidence"
            )
    scope = entry.get("scope")
    if (
        completion_status == "covered"
        and isinstance(scope, str)
        and "workspace" in scope
    ):
        evidence = entry.get("runtimeEvidence")
        if not isinstance(evidence, dict):
            errors.append(f"{label}.runtimeEvidence is required for a covered workspace")
        else:
            contract_id = evidence.get("contractId")
            test_path = evidence.get("testPath")
            evidence_text: str | None = None
            if contract_id != entry.get("id"):
                errors.append(f"{label}.runtimeEvidence.contractId must match entry id")
            if (
                not isinstance(test_path, str)
                or test_path not in entry.get("representativeBilingualTests", [])
                or not (repo_root / test_path).is_file()
            ):
                errors.append(
                    f"{label}.runtimeEvidence.testPath must be linked bilingual evidence"
                )
            else:
                try:
                    evidence_text = (repo_root / test_path).read_text(encoding="utf-8")
                except (OSError, UnicodeError) as error:
                    errors.append(f"cannot read runtime evidence {test_path}: {error}")
                else:
                    marker = f"feature-localization-contract: {contract_id}"
                    if marker not in evidence_text:
                        errors.append(f"{label}.runtimeEvidence marker is missing")
                    for locale in ("en", "pt"):
                        if f"Locale('{locale}')" not in evidence_text:
                            errors.append(
                                f"{label}.runtimeEvidence does not execute locale {locale}"
                            )
            if evidence.get("locales") != ["en", "pt"]:
                errors.append(f"{label}.runtimeEvidence.locales must be [en, pt]")
            profiles = _string_list(
                evidence.get("viewportProfiles"),
                f"{label}.runtimeEvidence.viewportProfiles",
                errors,
            )
            if not profiles:
                errors.append(
                    f"{label}.runtimeEvidence.viewportProfiles must not be empty"
                )
            capabilities = set(
                _string_list(
                    evidence.get("capabilities"),
                    f"{label}.runtimeEvidence.capabilities",
                    errors,
                )
            )
            if not capabilities:
                errors.append(
                    f"{label}.runtimeEvidence.capabilities must not be empty"
                )
            authoritative_capabilities = AUTHORITATIVE_RUNTIME_CAPABILITIES.get(
                entry.get("id")
            )
            if authoritative_capabilities is None:
                errors.append(
                    f"{label} has no authoritative runtime capability profile"
                )
            else:
                missing_capabilities = authoritative_capabilities - capabilities
                if missing_capabilities:
                    errors.append(
                        f"{label}.runtimeEvidence.capabilities omits authoritative "
                        f"capabilities: {', '.join(sorted(missing_capabilities))}"
                    )
            assertions = set(
                _string_list(
                    evidence.get("assertions"),
                    f"{label}.runtimeEvidence.assertions",
                    errors,
                )
            )
            capability_assertions = {
                "editing": "localized-editor-fields",
                "validation": "localized-error",
                "simulation": "localized-valid-simulation",
                "comparison": "localized-comparison-result",
                "interoperability": "localized-import-export",
                "examples": "localized-example-metadata",
                "locale-state": "locale-switch-state-preservation",
                "formal-content": "formal-content-preservation",
                "preference": "localized-preference-control",
                "accessibility": "responsive-accessibility",
                "layout.constructive": "localized-layout-constructive",
                "layout.transforms": "localized-layout-transforms",
                "layout.restore": "localized-layout-restore",
                "simulation.computation-tree": "localized-computation-tree",
                "simulation.nondeterminism-highlight": "localized-nondeterminism-highlight",
                "simulation.epsilon-highlight": "localized-epsilon-highlight",
                "analysis.dfa-equivalence": "localized-dfa-equivalence",
                "bounded-results": "localized-bounded-result",
            }
            required_assertions = {
                assertion
                for capability, assertion in capability_assertions.items()
                if capability in capabilities
            }
            if (
                "comparison" not in capabilities
                and "localized-comparison-result" in assertions
            ):
                errors.append(
                    f"{label}.runtimeEvidence claims comparison evidence "
                    "without the comparison capability"
                )
            if not required_assertions.issubset(assertions):
                errors.append(
                    f"{label}.runtimeEvidence.assertions misses required coverage"
                )
            if evidence_text is not None:
                for assertion in sorted(assertions):
                    marker = f"feature-localization-surface: {assertion}"
                    if marker not in evidence_text:
                        errors.append(
                            f"{label}.runtimeEvidence has no executable marker for "
                            f"{assertion}"
                        )
    return entry


def validate_repository(
    repo_root: Path,
    inventory_path: Path,
    *,
    expected_descriptor_count: int = 11,
) -> list[str]:
    """Return all validation errors without mutating the repository."""

    errors: list[str] = []
    inventory = _read_json(inventory_path, errors)
    if inventory is None:
        return errors
    if inventory.get("schemaVersion") != 1:
        errors.append("schemaVersion must be 1")
    if inventory.get("ownerIssues") != EXPECTED_OWNERS:
        errors.append(f"ownerIssues must be exactly {EXPECTED_OWNERS}")

    arb_files = inventory.get("arbFiles")
    if not isinstance(arb_files, dict):
        errors.append("arbFiles must be an object with en and pt paths")
        return errors
    en_relative = arb_files.get("en")
    pt_relative = arb_files.get("pt")
    if not isinstance(en_relative, str) or not isinstance(pt_relative, str):
        errors.append("arbFiles.en and arbFiles.pt must be strings")
        return errors
    en = _read_json(repo_root / en_relative, errors)
    pt = _read_json(repo_root / pt_relative, errors)
    if en is None or pt is None:
        return errors
    en_keys, pt_keys = _validate_arb_parity(en, pt, errors)

    assembly = inventory.get("registryAssembly")
    if not isinstance(assembly, str) or not (repo_root / assembly).is_file():
        errors.append(f"registryAssembly path is missing: {assembly!r}")
    parity_relative = inventory.get("parityRoot")
    if not isinstance(parity_relative, str):
        errors.append("parityRoot must be a string")
        parity_rows: dict[str, str] = {}
    else:
        parity_rows = _load_parity_rows(repo_root / parity_relative, errors)

    descriptors = inventory.get("descriptorEntries")
    if not isinstance(descriptors, list):
        errors.append("descriptorEntries must be a list")
        descriptors = []
    if len(descriptors) != expected_descriptor_count:
        errors.append(
            "descriptorEntries must contain "
            f"{expected_descriptor_count} entries, found {len(descriptors)}"
        )

    entry_ids: list[str] = []
    formal_keys: list[str] = []
    namespaces: list[str] = []
    parity_claims: Counter[str] = Counter()
    for index, raw_entry in enumerate(descriptors):
        label = f"descriptorEntries[{index}]"
        entry = _validate_entry_common(
            raw_entry, label, repo_root, en_keys, pt_keys, errors
        )
        if entry is None:
            continue
        entry_ids.append(entry.get("id", ""))
        formal_key = entry.get("formalSystemKey")
        namespace = entry.get("localizationNamespace")
        if not isinstance(formal_key, str) or formal_key.count(":") != 1:
            errors.append(f"{label}.formalSystemKey must use type:variant")
        else:
            formal_keys.append(formal_key)
        if not isinstance(namespace, str) or not namespace:
            errors.append(f"{label}.localizationNamespace must be a string")
        else:
            namespaces.append(namespace)
        sources = _string_list(entry.get("sourcePaths"), f"{label}.sourcePaths", errors)
        if not sources:
            errors.append(f"{label}.sourcePaths must not be empty")
        source_text = ""
        for relative in sources:
            path = repo_root / relative
            if not path.is_file():
                errors.append(f"{label}.sourcePaths path is missing: {relative}")
                continue
            try:
                source_text += path.read_text(encoding="utf-8")
            except (OSError, UnicodeError) as error:
                errors.append(f"cannot read registry source {relative}: {error}")
        if isinstance(namespace, str) and f"'{namespace}'" not in source_text:
            errors.append(f"{label} namespace is absent from declared registry sources: {namespace}")
        if isinstance(formal_key, str) and formal_key.count(":") == 1:
            system_type, variant = formal_key.split(":")
            if f"FormalSystemTypeId('{system_type}')" not in source_text:
                errors.append(f"{label} type is absent from declared registry sources: {system_type}")
            if f"FormalSystemVariantId('{variant}')" not in source_text:
                errors.append(f"{label} variant is absent from declared registry sources: {variant}")
        entry_parity = entry.get("parityCoverage")
        if isinstance(entry_parity, dict):
            for row_id in entry_parity:
                parity_claims[row_id] += 1

    workflows = inventory.get("workflowEntries")
    if not isinstance(workflows, list) or not workflows:
        errors.append("workflowEntries must be a non-empty list")
        workflows = []
    descriptor_namespace_set = set(namespaces)
    for index, raw_entry in enumerate(workflows):
        label = f"workflowEntries[{index}]"
        entry = _validate_entry_common(
            raw_entry, label, repo_root, en_keys, pt_keys, errors
        )
        if entry is None:
            continue
        entry_ids.append(entry.get("id", ""))
        capability_ids = _string_list(
            entry.get("capabilityIds"), f"{label}.capabilityIds", errors
        )
        if not capability_ids:
            errors.append(f"{label}.capabilityIds must not be empty")
        workflow_namespaces = _string_list(
            entry.get("localizationNamespaces"),
            f"{label}.localizationNamespaces",
            errors,
        )
        if not workflow_namespaces:
            errors.append(f"{label}.localizationNamespaces must not be empty")
        for namespace in workflow_namespaces:
            if namespace not in descriptor_namespace_set:
                errors.append(f"{label} references unregistered namespace: {namespace}")
        _validate_capability_evidence(
            entry,
            label,
            repo_root,
            set(capability_ids),
            errors,
        )
        entry_parity = entry.get("parityCoverage")
        if isinstance(entry_parity, dict):
            for row_id in entry_parity:
                parity_claims[row_id] += 1

    for label, values in (
        ("entry id", entry_ids),
        ("formal system key", formal_keys),
        ("localization namespace", namespaces),
    ):
        for value, count in Counter(values).items():
            if value and count > 1:
                errors.append(f"duplicate {label}: {value}")

    for row_id, count in sorted(parity_claims.items()):
        if row_id not in parity_rows:
            errors.append(f"ownership references unknown parity row: {row_id}")
            continue
        claimed_status = next(
            entry["parityCoverage"][row_id]
            for entry in [*descriptors, *workflows]
            if isinstance(entry, dict)
            and isinstance(entry.get("parityCoverage"), dict)
            and row_id in entry["parityCoverage"]
        )
        if claimed_status != parity_rows[row_id]:
            errors.append(
                f"localization status drift for {row_id}: "
                f"ownership={claimed_status}, parity={parity_rows[row_id]}"
            )
        if count != 1:
            errors.append(f"parity row must have one ownership entry: {row_id} ({count})")

    residual_rows = {
        row_id for row_id, status in parity_rows.items() if status in RESIDUAL_STATUSES
    }
    claimed_residual = {
        row_id for row_id in parity_claims if row_id in residual_rows
    }
    for row_id in sorted(residual_rows - claimed_residual):
        errors.append(f"residual localization parity row has no owner: {row_id}")
    return errors


def main(argv: list[str] | None = None) -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    default_root = Path(__file__).resolve().parents[1]
    parser.add_argument("--repo-root", type=Path, default=default_root)
    parser.add_argument(
        "--inventory",
        type=Path,
        default=Path("docs/localization/feature_ownership.v1.json"),
    )
    args = parser.parse_args(argv)
    repo_root = args.repo_root.resolve()
    inventory = args.inventory
    if not inventory.is_absolute():
        inventory = repo_root / inventory
    errors = validate_repository(repo_root, inventory)
    if errors:
        print(f"Feature localization validation failed ({len(errors)} error(s)):")
        for error in errors:
            print(f"- {error}")
        return 1
    print("Feature localization ownership is valid.")
    return 0


if __name__ == "__main__":
    sys.exit(main())
