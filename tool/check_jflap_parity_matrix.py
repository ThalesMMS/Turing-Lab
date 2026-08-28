#!/usr/bin/env python3
"""Validate and generate the source-backed JFLAP parity matrix."""

from __future__ import annotations

import argparse
import hashlib
import json
import subprocess
import sys
from collections import Counter
from pathlib import Path
from typing import Any


REPO_ROOT = Path(__file__).resolve().parents[1]
DATA_ROOT = REPO_ROOT / "docs" / "jflap-parity"
METADATA_PATH = DATA_ROOT / "metadata.json"
MATRIX_PATH = REPO_ROOT / "docs" / "JFLAP_PARITY_MATRIX.md"
ROADMAP_PATH = REPO_ROOT / "docs" / "issue-roadmap.json"

ROW_STATUSES = {
    "complete",
    "missingEducationalUi",
    "missingInteroperability",
    "partial",
    "intentionalDeviation",
    "planned",
    "outOfScope",
}
DIMENSION_STATUSES = {
    "covered",
    "partial",
    "missing",
    "planned",
    "notApplicable",
}
DIMENSIONS = (
    "domain",
    "userReachable",
    "teaching",
    "interoperability",
    "examplesHelp",
    "persistenceUndo",
    "responsiveAccessibility",
    "testsEdgeCases",
    "localization",
    "platform",
)
REGISTRY_CAPABILITY_PREFIXES = (
    "workspace:",
    "capability:",
    "format:",
    "conversion:",
    "codec:",
    "adapter:",
)
EVIDENCE_LINE_COUNTS: dict[Path, int] = {}
ROW_KEYS = {
    "id",
    "area",
    "capability",
    "jflap",
    "turingLab",
    "dimensions",
    "notes",
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


def fail(messages: list[str]) -> int:
    print("JFLAP parity matrix check failed:", file=sys.stderr)
    for message in messages:
        print(f"  {message}", file=sys.stderr)
    return 1


def load_json(path: Path, errors: list[str]) -> Any:
    try:
        return json.loads(
            path.read_text(encoding="utf-8"), object_pairs_hook=_unique_object
        )
    except (OSError, json.JSONDecodeError, DuplicateKeyError) as error:
        errors.append(f"{path.relative_to(REPO_ROOT)}: {error}")
        return None


def load_inventory(errors: list[str]) -> tuple[dict[str, Any], list[dict[str, Any]]]:
    metadata = load_json(METADATA_PATH, errors)
    if not isinstance(metadata, dict):
        return {}, []

    rows: list[dict[str, Any]] = []
    for path in sorted(DATA_ROOT.glob("*.json")):
        if path == METADATA_PATH:
            continue
        fragment = load_json(path, errors)
        if not isinstance(fragment, dict):
            continue
        if not isinstance(fragment.get("fragment"), str):
            errors.append(f"{path.relative_to(REPO_ROOT)}: missing fragment ID")
        fragment_rows = fragment.get("rows")
        if not isinstance(fragment_rows, list):
            errors.append(f"{path.relative_to(REPO_ROOT)}: rows must be a list")
            continue
        for index, row in enumerate(fragment_rows):
            if not isinstance(row, dict):
                errors.append(
                    f"{path.relative_to(REPO_ROOT)}: row {index} must be an object"
                )
                continue
            row["_source"] = str(path.relative_to(REPO_ROOT))
            rows.append(row)
    if not rows:
        errors.append("no parity rows were found")
    return metadata, rows


def string_list(value: Any, label: str, errors: list[str]) -> list[str]:
    if not isinstance(value, list) or not all(isinstance(item, str) for item in value):
        errors.append(f"{label} must be a list of strings")
        return []
    return value


def validate_evidence(
    values: Any,
    label: str,
    errors: list[str],
    *,
    required: bool,
) -> list[str]:
    evidence = string_list(values, label, errors)
    if required and not evidence:
        errors.append(f"{label} must not be empty")
    for item in evidence:
        path_text, separator, line_text = item.rpartition(":")
        if not separator or not line_text.isdigit() or int(line_text) <= 0:
            errors.append(f"{label}: evidence must end in a positive line number: {item}")
            continue
        target = (REPO_ROOT / path_text).resolve()
        if not target.is_file():
            errors.append(f"{label}: evidence path does not exist: {path_text}")
            continue
        line_number = int(line_text)
        try:
            line_count = EVIDENCE_LINE_COUNTS.get(target)
            if line_count is None:
                line_count = sum(
                    1
                    for _ in target.open(
                        "r",
                        encoding="utf-8",
                        errors="replace",
                    )
                )
                EVIDENCE_LINE_COUNTS[target] = line_count
        except OSError as error:
            errors.append(f"{label}: could not read evidence path {path_text}: {error}")
            continue
        if line_number > line_count:
            errors.append(
                f"{label}: evidence line {line_number} exceeds "
                f"{path_text}'s {line_count} lines"
            )
    return evidence


def validate_rows(
    metadata: dict[str, Any],
    rows: list[dict[str, Any]],
    roadmap: dict[str, Any],
) -> list[str]:
    errors: list[str] = []
    seen_ids: set[str] = set()
    covered_new_types: set[str] = set()
    covered_xml_families: set[str] = set()
    covered_groups: set[str] = set()
    covered_registry_capabilities: set[str] = set()
    roadmap_issues = roadmap.get("issues", {}) if isinstance(roadmap, dict) else {}

    for row in rows:
        source = row.get("_source", "parity fragment")
        row_id = row.get("id")
        label = f"{source}:{row_id or '<missing-id>'}"
        missing = ROW_KEYS - row.keys()
        if missing:
            errors.append(f"{label}: missing fields {sorted(missing)}")
        if not isinstance(row_id, str) or not row_id.strip():
            errors.append(f"{label}: id must be a non-empty string")
        elif row_id in seen_ids:
            errors.append(f"{label}: duplicate row id")
        else:
            seen_ids.add(row_id)
        for field in ("area", "capability", "notes"):
            if not isinstance(row.get(field), str):
                errors.append(f"{label}: {field} must be a string")

        jflap = row.get("jflap")
        if not isinstance(jflap, dict):
            errors.append(f"{label}: jflap must be an object")
        else:
            if not isinstance(jflap.get("summary"), str) or not jflap["summary"].strip():
                errors.append(f"{label}: jflap.summary must be non-empty")
            validate_evidence(
                jflap.get("evidence"),
                f"{label}.jflap.evidence",
                errors,
                required=True,
            )

        turing = row.get("turingLab")
        if not isinstance(turing, dict):
            errors.append(f"{label}: turingLab must be an object")
            continue
        status = turing.get("status")
        if status not in ROW_STATUSES:
            errors.append(f"{label}: invalid status {status!r}")
        production = validate_evidence(
            turing.get("production"),
            f"{label}.turingLab.production",
            errors,
            required=status == "complete",
        )
        tests = validate_evidence(
            turing.get("tests"),
            f"{label}.turingLab.tests",
            errors,
            required=status == "complete",
        )
        issues = turing.get("issues")
        if not isinstance(issues, list) or not all(
            isinstance(issue, int) and issue > 0 for issue in issues
        ):
            errors.append(f"{label}: turingLab.issues must contain positive integers")
            issues = []
        decision = turing.get("decision")
        if not isinstance(decision, str):
            errors.append(f"{label}: turingLab.decision must be a string")
            decision = ""
        if status == "complete" and (not production or not tests):
            errors.append(f"{label}: complete rows require production and test evidence")
        if status == "planned" and not any(issue != 333 for issue in issues):
            errors.append(f"{label}: planned rows require an owning issue other than #333")
        if status == "planned":
            for issue in (issue for issue in issues if issue != 333):
                roadmap_entry = roadmap_issues.get(str(issue))
                if not isinstance(roadmap_entry, dict):
                    errors.append(
                        f"{label}: planned owner #{issue} is absent from the issue roadmap"
                    )
                elif not isinstance(roadmap_entry.get("phase"), int):
                    errors.append(
                        f"{label}: planned owner #{issue} has no roadmap phase"
                    )
        if status in {"intentionalDeviation", "outOfScope"} and not decision.strip():
            errors.append(f"{label}: {status} requires a product decision")
        if "material_unowned" in str(row.get("notes", "")).lower():
            errors.append(f"{label}: material gap still lacks an owning issue")

        dimensions = row.get("dimensions")
        if not isinstance(dimensions, dict):
            errors.append(f"{label}: dimensions must be an object")
        else:
            if set(dimensions) != set(DIMENSIONS):
                errors.append(
                    f"{label}: dimensions must be exactly {list(DIMENSIONS)}"
                )
            for dimension, value in dimensions.items():
                if value not in DIMENSION_STATUSES:
                    errors.append(
                        f"{label}: invalid {dimension} dimension status {value!r}"
                    )

        for field, aggregate in (
            ("jflapNewTypes", covered_new_types),
            ("jflapXmlFamilies", covered_xml_families),
            ("groups", covered_groups),
        ):
            value = row.get(field, [])
            aggregate.update(string_list(value, f"{label}.{field}", errors))
        if "registryCapabilities" in row:
            registry_capabilities = string_list(
                row["registryCapabilities"],
                f"{label}.registryCapabilities",
                errors,
            )
            for capability in registry_capabilities:
                if not capability.startswith(REGISTRY_CAPABILITY_PREFIXES):
                    errors.append(
                        f"{label}: invalid live registry capability ID {capability!r}"
                    )
                if capability in covered_registry_capabilities:
                    errors.append(
                        f"{label}: duplicate live registry capability ID {capability!r}"
                    )
                covered_registry_capabilities.add(capability)

    for metadata_field, covered, description in (
        ("requiredJflapNewTypes", covered_new_types, "JFLAP New-document types"),
        ("requiredJflapXmlFamilies", covered_xml_families, "JFLAP XML families"),
        ("requiredGroups", covered_groups, "capability groups"),
    ):
        required = set(string_list(metadata.get(metadata_field), metadata_field, errors))
        missing = sorted(required - covered)
        extra = sorted(covered - required) if metadata_field != "requiredGroups" else []
        if missing:
            errors.append(f"missing {description}: {missing}")
        if extra:
            errors.append(f"unregistered {description}: {extra}")
    return errors


def verify_baseline(metadata: dict[str, Any]) -> list[str]:
    errors: list[str] = []
    baseline = metadata.get("baseline")
    if not isinstance(baseline, dict):
        return ["metadata.baseline must be an object"]
    root_value = baseline.get("jflapSourceRoot")
    if not isinstance(root_value, str):
        return ["metadata.baseline.jflapSourceRoot must be a string"]
    root = (REPO_ROOT / root_value).resolve()
    if not root.is_dir():
        return [f"JFLAP source root is unavailable: {root}"]
    files = sorted(path for path in root.rglob("*") if path.is_file())
    entries = []
    for path in files:
        relative = path.relative_to(root).as_posix()
        digest = hashlib.sha256(path.read_bytes()).hexdigest()
        entries.append(f"{relative}:{digest}")
    fingerprint = hashlib.sha256("\n".join(entries).encode("utf-8")).hexdigest()
    if len(files) != baseline.get("jflapSourceFiles"):
        errors.append(
            "JFLAP source file count differs from the recorded baseline: "
            f"{len(files)} != {baseline.get('jflapSourceFiles')}"
        )
    if fingerprint != baseline.get("jflapSourceSha256"):
        errors.append(
            "JFLAP source fingerprint differs from the recorded baseline: "
            f"{fingerprint}"
        )
    return errors


def github_open_issues() -> set[int]:
    result = subprocess.run(
        ["gh", "issue", "list", "--state", "open", "--limit", "200", "--json", "number"],
        cwd=REPO_ROOT,
        check=True,
        capture_output=True,
        text=True,
    )
    return {entry["number"] for entry in json.loads(result.stdout)}


def validate_residual_issues(rows: list[dict[str, Any]]) -> list[str]:
    try:
        open_issues = github_open_issues()
    except (OSError, subprocess.CalledProcessError, json.JSONDecodeError) as error:
        return [f"could not read open GitHub issues: {error}"]
    errors: list[str] = []
    for row in rows:
        turing = row.get("turingLab", {})
        if turing.get("status") not in {
            "missingEducationalUi",
            "missingInteroperability",
            "partial",
            "planned",
        }:
            continue
        owners = set(turing.get("issues", []))
        if not owners.intersection(open_issues):
            errors.append(
                f"{row.get('id')}: residual {turing.get('status')} gap has no open owning issue"
            )
    return errors


def cell(value: Any) -> str:
    text = str(value).replace("\n", " ").replace("|", "\\|")
    return text if text else "—"


def evidence_cell(values: list[str]) -> str:
    return "<br>".join(f"`{cell(value)}`" for value in values) or "—"


def generated_markdown(
    metadata: dict[str, Any],
    rows: list[dict[str, Any]],
    roadmap: dict[str, Any],
) -> str:
    baseline = metadata["baseline"]
    status_counts = Counter(row["turingLab"]["status"] for row in rows)
    roadmap_issues = roadmap.get("issues", {})
    lines = [
        "<!-- Generated by tool/check_jflap_parity_matrix.py. -->",
        "# JFLAP 7.1 parity matrix",
        "",
        f"- Baseline date: `{baseline['date']}`",
        f"- JFLAP source: `{baseline['jflapVersion']}` with `{baseline['jflapSourceFiles']}` files and SHA-256 `{baseline['jflapSourceSha256']}`",
        f"- Turing Lab baseline commit: `{baseline['turingLabCommit']}`",
        f"- Capability rows: `{len(rows)}`",
        "",
        "This inventory requires a user-reachable path and meaningful tests before it labels a capability complete. A class name alone is not evidence.",
        "",
        "## Status summary",
        "",
        "| Status | Rows |",
        "| --- | ---: |",
    ]
    for status in sorted(ROW_STATUSES):
        lines.append(f"| `{status}` | {status_counts[status]} |")

    for area in sorted({row["area"] for row in rows}):
        lines.extend(
            [
                "",
                f"## {area}",
                "",
                "| Capability | Status | JFLAP evidence | Turing Lab production | Tests | Issues | Notes |",
                "| --- | --- | --- | --- | --- | --- | --- |",
            ]
        )
        for row in sorted(
            (candidate for candidate in rows if candidate["area"] == area),
            key=lambda candidate: candidate["id"],
        ):
            turing = row["turingLab"]
            issues = ", ".join(
                f"#{issue} (phase {roadmap_issues[str(issue)]['phase']})"
                if str(issue) in roadmap_issues
                else f"#{issue} (historical)"
                for issue in turing["issues"]
            )
            note_parts = [row["notes"]]
            if turing["decision"]:
                note_parts.append(f"Decision: {turing['decision']}")
            lines.append(
                "| "
                + " | ".join(
                    [
                        cell(row["capability"]),
                        f"`{turing['status']}`",
                        evidence_cell(row["jflap"]["evidence"]),
                        evidence_cell(turing["production"]),
                        evidence_cell(turing["tests"]),
                        cell(issues),
                        cell(" ".join(part for part in note_parts if part)),
                    ]
                )
                + " |"
            )

    lines.extend(
        [
            "",
            "## Required dimensions",
            "",
            "| Dimension | Covered | Partial | Missing | Planned | Not applicable |",
            "| --- | ---: | ---: | ---: | ---: | ---: |",
        ]
    )
    for dimension in DIMENSIONS:
        counts = Counter(row["dimensions"][dimension] for row in rows)
        lines.append(
            f"| `{dimension}` | {counts['covered']} | {counts['partial']} | {counts['missing']} | {counts['planned']} | {counts['notApplicable']} |"
        )

    deviations = [
        row for row in rows if row["turingLab"]["status"] in {"intentionalDeviation", "outOfScope"}
    ]
    lines.extend(["", "## Intentional deviations and scope decisions", ""])
    for row in sorted(deviations, key=lambda candidate: candidate["id"]):
        lines.append(
            f"- `{row['id']}`: {row['turingLab']['decision']} User-visible consequence: {row['notes']}"
        )
    if not deviations:
        lines.append("- None recorded.")

    license_data = metadata["license"]
    lines.extend(
        [
            "",
            "## Licensing constraint",
            "",
            license_data["summary"],
            "",
            license_data["consequence"],
            "",
            "## Validation",
            "",
            "```bash",
            "python3 tool/check_jflap_parity_matrix.py --verify-jflap --github",
            "flutter test test/unit/data/jflap_parity_registry_coverage_test.dart",
            "```",
            "",
            "The first command validates row schemas, evidence paths, required JFLAP document/action coverage, source fingerprint, generated Markdown drift, and open ownership for planned gaps. The Flutter test compares the matrix with the live formal-system registry.",
            "",
        ]
    )
    return "\n".join(lines)


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--write", action="store_true", help="regenerate the Markdown matrix")
    parser.add_argument("--verify-jflap", action="store_true", help="verify the adjacent JFLAP source fingerprint")
    parser.add_argument("--github", action="store_true", help="verify that planned owning issues are open")
    args = parser.parse_args()

    errors: list[str] = []
    metadata, rows = load_inventory(errors)
    roadmap = load_json(ROADMAP_PATH, errors)
    if not isinstance(roadmap, dict):
        roadmap = {}
    if metadata:
        errors.extend(validate_rows(metadata, rows, roadmap))
        if args.verify_jflap:
            errors.extend(verify_baseline(metadata))
        if args.github:
            errors.extend(validate_residual_issues(rows))
    if errors:
        return fail(errors)

    rendered = generated_markdown(metadata, rows, roadmap)
    if args.write:
        MATRIX_PATH.write_text(rendered, encoding="utf-8", newline="\n")
    elif not MATRIX_PATH.is_file():
        return fail([f"missing generated matrix: {MATRIX_PATH.relative_to(REPO_ROOT)}"])
    elif MATRIX_PATH.read_text(encoding="utf-8") != rendered:
        return fail(["docs/JFLAP_PARITY_MATRIX.md is stale; run with --write"])

    print(f"JFLAP parity matrix check passed for {len(rows)} rows.")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
