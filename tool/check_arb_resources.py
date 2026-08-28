#!/usr/bin/env python3
"""Validate the English and Portuguese ARB resource contracts."""

from __future__ import annotations

import argparse
import json
import re
import sys
from pathlib import Path
from typing import Any, NamedTuple


IDENTIFIER = re.compile(r"[A-Za-z_][A-Za-z0-9_]*")
RESOURCE_KEY = re.compile(r"[a-z$][A-Za-z0-9_$]*")
COMPLEX_ARGUMENT_TYPES = {"plural", "select", "selectordinal"}
SIMPLE_ARGUMENT_TYPES = {"date", "number", "time"}
NUMERIC_TYPES = {"int", "double", "num"}
NUMERIC_ARGUMENT_TYPES = {"number", "plural", "selectordinal"}
DATETIME_ARGUMENT_TYPES = {"date", "time"}
PLURAL_CATEGORY_SELECTORS = {"zero", "one", "two", "few", "many", "other"}


class DuplicateKeyError(ValueError):
    """Raised when a JSON object repeats a key."""


def _unique_object(pairs: list[tuple[str, Any]]) -> dict[str, Any]:
    result: dict[str, Any] = {}
    for key, value in pairs:
        if key in result:
            raise DuplicateKeyError(f"duplicate JSON key: {key}")
        result[key] = value
    return result


class ValidationIssue(NamedTuple):
    message: str
    category: str
    locale: str | None = None
    key: str | None = None


def _add_issue(
    issues: list[ValidationIssue],
    message: str,
    category: str,
    *,
    locale: str | None = None,
    key: str | None = None,
) -> None:
    issues.append(ValidationIssue(message, category, locale, key))


def _read_arb(
    path: Path, locale: str, issues: list[ValidationIssue]
) -> dict[str, Any] | None:
    try:
        text = path.read_text(encoding="utf-8")
        value = json.loads(text, object_pairs_hook=_unique_object)
    except FileNotFoundError:
        _add_issue(
            issues,
            f"missing ARB file: {path}",
            "resource",
            locale=locale,
        )
        return None
    except (OSError, UnicodeError, json.JSONDecodeError, DuplicateKeyError) as error:
        _add_issue(
            issues,
            f"cannot read ARB file {path}: {error}",
            "resource",
            locale=locale,
        )
        return None
    if not isinstance(value, dict):
        _add_issue(
            issues,
            f"ARB root must be an object: {path}",
            "resource",
            locale=locale,
        )
        return None
    return value


class ArgumentUse(NamedTuple):
    name: str
    argument_type: str | None
    selectors: tuple[str, ...]


class IcuSyntaxError(ValueError):
    """Raised when a message does not follow the supported ICU grammar."""


class _IcuParser:
    def __init__(self, message: str) -> None:
        self.message = message
        self.position = 0
        self.arguments: list[ArgumentUse] = []

    def parse(self) -> list[ArgumentUse]:
        self._parse_message(expect_closing=False)
        return self.arguments

    def _parse_message(self, *, expect_closing: bool) -> None:
        while self.position < len(self.message):
            character = self.message[self.position]
            if character == "{":
                self._parse_argument()
                continue
            if character == "}":
                if not expect_closing:
                    raise IcuSyntaxError(f"unexpected '}}' at offset {self.position}")
                self.position += 1
                return
            self.position += 1
        if expect_closing:
            raise IcuSyntaxError("missing closing '}'")

    def _parse_argument(self) -> None:
        self.position += 1
        self._skip_whitespace()
        name = self._read_identifier("argument name")
        self._skip_whitespace()
        if self._consume("}"):
            self.arguments.append(ArgumentUse(name, None, ()))
            return
        self._expect(",", "after argument name")
        self._skip_whitespace()
        argument_type = self._read_identifier("argument type")
        self._skip_whitespace()
        if argument_type not in COMPLEX_ARGUMENT_TYPES:
            if argument_type not in SIMPLE_ARGUMENT_TYPES:
                raise IcuSyntaxError(
                    f"unsupported argument type: {argument_type}"
                )
            self._parse_simple_argument_style()
            self.arguments.append(ArgumentUse(name, argument_type, ()))
            return
        self._expect(",", f"after {argument_type} argument type")
        selectors = self._parse_complex_cases(argument_type)
        self.arguments.append(ArgumentUse(name, argument_type, selectors))

    def _parse_simple_argument_style(self) -> None:
        if self._consume("}"):
            return
        self._expect(",", "before argument style")
        while self.position < len(self.message):
            character = self.message[self.position]
            if character == "{":
                raise IcuSyntaxError(
                    f"nested '{{' in simple argument at offset {self.position}"
                )
            if character == "}":
                self.position += 1
                return
            self.position += 1
        raise IcuSyntaxError("missing closing '}'")

    def _parse_complex_cases(self, argument_type: str) -> tuple[str, ...]:
        cases: set[str] = set()
        while True:
            self._skip_whitespace()
            if argument_type in {"plural", "selectordinal"} and self.message.startswith(
                "offset:", self.position
            ):
                self.position += len("offset:")
                self._skip_whitespace()
                self._read_number("plural offset")
                continue
            if self._consume("}"):
                break
            selector_start = self.position
            while (
                self.position < len(self.message)
                and not self.message[self.position].isspace()
                and self.message[self.position] not in "{}"
            ):
                self.position += 1
            selector = self.message[selector_start : self.position]
            if not selector:
                raise IcuSyntaxError(
                    f"missing {argument_type} selector at offset {self.position}"
                )
            if (
                argument_type in {"plural", "selectordinal"}
                and selector not in PLURAL_CATEGORY_SELECTORS
                and re.fullmatch(r"=[0-9]+", selector) is None
            ):
                raise IcuSyntaxError(
                    f"{argument_type} selector is invalid: {selector}"
                )
            if selector in cases:
                raise IcuSyntaxError(f"duplicate {argument_type} selector: {selector}")
            cases.add(selector)
            self._skip_whitespace()
            self._expect("{", f"after {argument_type} selector {selector}")
            self._parse_message(expect_closing=True)
        if "other" not in cases:
            raise IcuSyntaxError(f"{argument_type} argument is missing an other case")
        return tuple(sorted(cases))

    def _read_identifier(self, label: str) -> str:
        match = IDENTIFIER.match(self.message, self.position)
        if match is None:
            raise IcuSyntaxError(f"missing {label} at offset {self.position}")
        self.position = match.end()
        return match.group(0)

    def _read_number(self, label: str) -> None:
        start = self.position
        if self.position < len(self.message) and self.message[self.position] in "+-":
            self.position += 1
        while (
            self.position < len(self.message)
            and self.message[self.position].isdigit()
        ):
            self.position += 1
        if self.position == start or (
            self.position == start + 1 and self.message[start] in "+-"
        ):
            raise IcuSyntaxError(f"missing {label} at offset {start}")

    def _skip_whitespace(self) -> None:
        while (
            self.position < len(self.message)
            and self.message[self.position].isspace()
        ):
            self.position += 1

    def _consume(self, expected: str) -> bool:
        if self.message.startswith(expected, self.position):
            self.position += len(expected)
            return True
        return False

    def _expect(self, expected: str, context: str) -> None:
        if not self._consume(expected):
            raise IcuSyntaxError(
                f"expected {expected!r} {context} at offset {self.position}"
            )


def _message_keys(arb: dict[str, Any]) -> set[str]:
    return {key for key in arb if not key.startswith("@")}


def _metadata_keys(arb: dict[str, Any]) -> set[str]:
    return {key[1:] for key in arb if key.startswith("@") and not key.startswith("@@")}


def _placeholder_contract(
    arb: dict[str, Any],
    key: str,
    locale_label: str,
    locale: str,
    issues: list[ValidationIssue],
) -> dict[str, dict[str, Any]]:
    metadata_key = f"@{key}"
    if metadata_key not in arb:
        return {}
    metadata = arb[metadata_key]
    if not isinstance(metadata, dict):
        _add_issue(
            issues,
            f"{locale_label} metadata must be an object: @{key}",
            "metadata",
            locale=locale,
            key=key,
        )
        return {}
    if "placeholders" not in metadata:
        return {}
    placeholders = metadata["placeholders"]
    if not isinstance(placeholders, dict):
        _add_issue(
            issues,
            f"{locale_label} placeholder metadata must be an object: {key}",
            "placeholder",
            locale=locale,
            key=key,
        )
        return {}
    contract: dict[str, dict[str, Any]] = {}
    for name, attributes in placeholders.items():
        if not IDENTIFIER.fullmatch(name):
            _add_issue(
                issues,
                f"{locale_label} placeholder name is invalid for {key}: {name!r}",
                "placeholder",
                locale=locale,
                key=key,
            )
            continue
        if not isinstance(attributes, dict):
            _add_issue(
                issues,
                f"{locale_label} placeholder contract must be an object: {key}.{name}",
                "placeholder",
                locale=locale,
                key=key,
            )
            continue
        placeholder_type = attributes.get("type")
        if not isinstance(placeholder_type, str) or not placeholder_type:
            _add_issue(
                issues,
                f"{locale_label} placeholder type is missing: {key}.{name}",
                "placeholder",
                locale=locale,
                key=key,
            )
        example = attributes.get("example")
        if "example" in attributes and (
            not isinstance(example, str) or not example
        ):
            _add_issue(
                issues,
                f"{locale_label} placeholder example must be a non-empty string: "
                f"{key}.{name}",
                "placeholder",
                locale=locale,
                key=key,
            )
        contract[name] = {
            attribute: value
            for attribute, value in attributes.items()
            if attribute != "example"
        }
        contract[name]["hasExample"] = "example" in attributes
    return contract


def _validate_locale(
    arb: dict[str, Any],
    locale_label: str,
    locale: str,
    issues: list[ValidationIssue],
) -> tuple[
    dict[str, dict[str, dict[str, Any]]],
    dict[str, dict[str, tuple[str, ...]]],
    dict[str, dict[str, tuple[str | None, ...]]],
]:
    declared_locale = arb.get("@@locale")
    if declared_locale != locale:
        _add_issue(
            issues,
            f"{locale_label} ARB @@locale must be {locale!r}, "
            f"found {declared_locale!r}",
            "resource",
            locale=locale,
        )
    message_keys = _message_keys(arb)
    metadata_keys = _metadata_keys(arb)
    for key in sorted(message_keys):
        if RESOURCE_KEY.fullmatch(key) is None:
            _add_issue(
                issues,
                f"{locale_label} ARB message key is not a supported "
                f"localization getter name: {key!r}",
                "resource",
                locale=locale,
                key=key,
            )
    for key in sorted(metadata_keys - message_keys):
        _add_issue(
            issues,
            f"{locale_label} metadata has no message: @{key}",
            "metadata",
            locale=locale,
            key=key,
        )

    contracts: dict[str, dict[str, dict[str, Any]]] = {}
    branches: dict[str, dict[str, tuple[str, ...]]] = {}
    argument_types: dict[str, dict[str, tuple[str | None, ...]]] = {}
    for key in sorted(message_keys):
        message = arb[key]
        if not isinstance(message, str):
            _add_issue(
                issues,
                f"{locale_label} ARB message must be a string: {key}",
                "message",
                locale=locale,
                key=key,
            )
            continue
        contract = _placeholder_contract(
            arb, key, locale_label, locale, issues
        )
        contracts[key] = contract
        try:
            uses = _IcuParser(message).parse()
        except IcuSyntaxError as error:
            _add_issue(
                issues,
                f"{locale_label} ICU syntax is invalid for {key}: {error}",
                "icu",
                locale=locale,
                key=key,
            )
            continue
        message_branches: dict[str, tuple[str, ...]] = {}
        message_argument_types: dict[str, list[str | None]] = {}
        used_names = {use.name for use in uses}
        contract_names = set(contract)
        for name in sorted(used_names - contract_names):
            _add_issue(
                issues,
                f"{locale_label} placeholder metadata is missing: {key}.{name}",
                "placeholder",
                locale=locale,
                key=key,
            )
        for name in sorted(contract_names - used_names):
            _add_issue(
                issues,
                f"{locale_label} placeholder metadata is unused: {key}.{name}",
                "placeholder",
                locale=locale,
                key=key,
            )
        for use in uses:
            argument_types_for_name = message_argument_types.setdefault(use.name, [])
            if use.argument_type not in argument_types_for_name:
                argument_types_for_name.append(use.argument_type)
            if use.argument_type in COMPLEX_ARGUMENT_TYPES:
                branch_key = f"{use.name}:{use.argument_type}"
                previous = message_branches.get(branch_key)
                if previous is not None and previous != use.selectors:
                    _add_issue(
                        issues,
                        f"{locale_label} ICU branches conflict within {key}: "
                        f"{branch_key}",
                        "icu",
                        locale=locale,
                        key=key,
                    )
                message_branches[branch_key] = use.selectors
            placeholder_type = contract.get(use.name, {}).get("type")
            if (
                use.argument_type in NUMERIC_ARGUMENT_TYPES
                and placeholder_type is not None
                and placeholder_type not in NUMERIC_TYPES
            ):
                _add_issue(
                    issues,
                    f"{locale_label} {use.argument_type} placeholder must be numeric: "
                    f"{key}.{use.name}",
                    "icu",
                    locale=locale,
                    key=key,
                )
            if (
                use.argument_type in DATETIME_ARGUMENT_TYPES
                and placeholder_type is not None
                and placeholder_type != "DateTime"
            ):
                _add_issue(
                    issues,
                    f"{locale_label} {use.argument_type} placeholder must be DateTime: "
                    f"{key}.{use.name}",
                    "icu",
                    locale=locale,
                    key=key,
                )
        branches[key] = message_branches
        argument_types[key] = {
            name: tuple(
                sorted(types, key=lambda argument_type: argument_type or "")
            )
            for name, types in message_argument_types.items()
        }
    return contracts, branches, argument_types


def validate_resource_issues(
    english_path: Path, portuguese_path: Path
) -> list[ValidationIssue]:
    """Return structured resource issues without changing either ARB file."""

    issues: list[ValidationIssue] = []
    english = _read_arb(english_path, "en", issues)
    portuguese = _read_arb(portuguese_path, "pt", issues)
    if english is None or portuguese is None:
        return issues

    english_keys = _message_keys(english)
    portuguese_keys = _message_keys(portuguese)
    for key in sorted(english_keys - portuguese_keys):
        _add_issue(
            issues,
            f"Portuguese ARB is missing message key: {key}",
            "parity",
            locale="pt",
            key=key,
        )
    for key in sorted(portuguese_keys - english_keys):
        _add_issue(
            issues,
            f"English ARB is missing message key: {key}",
            "parity",
            locale="en",
            key=key,
        )

    english_metadata = _metadata_keys(english)
    portuguese_metadata = _metadata_keys(portuguese)
    for key in sorted(english_metadata - portuguese_metadata):
        _add_issue(
            issues,
            f"Portuguese ARB is missing metadata key: @{key}",
            "parity",
            locale="pt",
            key=key,
        )
    for key in sorted(portuguese_metadata - english_metadata):
        _add_issue(
            issues,
            f"English ARB is missing metadata key: @{key}",
            "parity",
            locale="en",
            key=key,
        )

    english_contracts, english_branches, english_argument_types = _validate_locale(
        english, "English", "en", issues
    )
    portuguese_contracts, portuguese_branches, portuguese_argument_types = _validate_locale(
        portuguese, "Portuguese", "pt", issues
    )
    for key in sorted(english_keys & portuguese_keys):
        english_meta = english.get(f"@{key}")
        portuguese_meta = portuguese.get(f"@{key}")
        if isinstance(english_meta, dict) and isinstance(portuguese_meta, dict):
            if ("description" in english_meta) != ("description" in portuguese_meta):
                _add_issue(
                    issues,
                    f"description presence differs for {key}",
                    "parity",
                    locale="cross-locale",
                    key=key,
                )
        english_contract = english_contracts.get(key)
        portuguese_contract = portuguese_contracts.get(key)
        if (
            english_contract is not None
            and portuguese_contract is not None
            and english_contract != portuguese_contract
        ):
            _add_issue(
                issues,
                f"placeholder contract differs for {key}: "
                f"en={english_contract}, pt={portuguese_contract}",
                "parity",
                locale="cross-locale",
                key=key,
            )
        if english_branches.get(key) != portuguese_branches.get(key):
            _add_issue(
                issues,
                f"ICU branches differ for {key}: "
                f"en={english_branches.get(key)}, pt={portuguese_branches.get(key)}",
                "parity",
                locale="cross-locale",
                key=key,
            )
        if (
            key in english_argument_types
            and key in portuguese_argument_types
            and english_argument_types[key] != portuguese_argument_types[key]
        ):
            _add_issue(
                issues,
                f"ICU argument types differ for {key}: "
                f"en={english_argument_types[key]}, "
                f"pt={portuguese_argument_types[key]}",
                "icu",
                locale="cross-locale",
                key=key,
            )
    return issues


def validate_resources(english_path: Path, portuguese_path: Path) -> list[str]:
    """Return resource error messages without changing either ARB file."""

    return [
        issue.message
        for issue in validate_resource_issues(english_path, portuguese_path)
    ]


def _load_namespace_rules(path: Path) -> dict[str, tuple[str, ...]]:
    """Load the reviewed feature prefixes used to label report findings."""

    try:
        document = json.loads(path.read_text(encoding="utf-8"))
    except (OSError, UnicodeError, json.JSONDecodeError):
        return {}
    if not isinstance(document, dict):
        return {}

    namespaces_by_prefix: dict[str, set[str]] = {}
    entries: list[Any] = []
    for section in ("descriptorEntries", "workflowEntries"):
        section_entries = document.get(section)
        if isinstance(section_entries, list):
            entries.extend(section_entries)
    for entry in entries:
        if not isinstance(entry, dict):
            continue
        raw_namespaces = entry.get("localizationNamespaces")
        if isinstance(raw_namespaces, list):
            namespaces = {
                value for value in raw_namespaces if isinstance(value, str) and value
            }
        else:
            namespace = entry.get("localizationNamespace")
            namespaces = (
                {namespace} if isinstance(namespace, str) and namespace else set()
            )
        coverage = entry.get("arbCoverage")
        if not isinstance(coverage, dict):
            continue
        prefixes = coverage.get("keyPrefixes")
        if not isinstance(prefixes, list):
            continue
        for prefix in prefixes:
            if isinstance(prefix, str) and prefix:
                namespaces_by_prefix.setdefault(prefix, set()).update(namespaces)
    return {
        prefix: tuple(sorted(namespaces))
        for prefix, namespaces in sorted(namespaces_by_prefix.items())
    }


def _namespace_for_key(
    key: str | None, namespace_rules: dict[str, tuple[str, ...]]
) -> str | None:
    if key is None:
        return None
    matching_prefixes = [prefix for prefix in namespace_rules if key.startswith(prefix)]
    if not matching_prefixes:
        return None
    longest_length = max(len(prefix) for prefix in matching_prefixes)
    namespaces = {
        namespace
        for prefix in matching_prefixes
        if len(prefix) == longest_length
        for namespace in namespace_rules[prefix]
    }
    if len(namespaces) != 1:
        return None
    return next(iter(namespaces))


def _display_path(path: Path, repo_root: Path) -> str:
    try:
        return path.resolve().relative_to(repo_root.resolve()).as_posix()
    except ValueError:
        return path.resolve().as_posix()


def _resource_statistics(
    path: Path,
    locale: str,
    repo_root: Path,
    namespace_rules: dict[str, tuple[str, ...]],
) -> dict[str, Any]:
    result: dict[str, Any] = {
        "locale": locale,
        "path": _display_path(path, repo_root),
        "readable": False,
    }
    try:
        value = json.loads(
            path.read_text(encoding="utf-8"), object_pairs_hook=_unique_object
        )
    except (OSError, UnicodeError, json.JSONDecodeError, DuplicateKeyError):
        return result
    if not isinstance(value, dict):
        return result

    message_keys = sorted(_message_keys(value))
    metadata_keys = _metadata_keys(value)
    placeholder_count = 0
    icu_message_count = 0
    namespace_counts: dict[str, int] = {}
    for key in message_keys:
        metadata = value.get(f"@{key}")
        if isinstance(metadata, dict) and isinstance(
            metadata.get("placeholders"), dict
        ):
            placeholder_count += len(metadata["placeholders"])
        message = value[key]
        if isinstance(message, str):
            try:
                uses = _IcuParser(message).parse()
            except IcuSyntaxError:
                uses = []
            if any(use.argument_type in COMPLEX_ARGUMENT_TYPES for use in uses):
                icu_message_count += 1
        namespace = _namespace_for_key(key, namespace_rules)
        if namespace is not None:
            namespace_counts[namespace] = namespace_counts.get(namespace, 0) + 1
    result.update(
        {
            "readable": True,
            "messageCount": len(message_keys),
            "metadataCount": len(metadata_keys),
            "placeholderCount": placeholder_count,
            "icuMessageCount": icu_message_count,
            "namespaceMessageCounts": dict(sorted(namespace_counts.items())),
        }
    )
    return result


def build_report(
    english_path: Path,
    portuguese_path: Path,
    issues: list[ValidationIssue],
    *,
    repo_root: Path,
    namespace_rules: dict[str, tuple[str, ...]] | None = None,
) -> dict[str, Any]:
    """Build the stable report shared by text and JSON output."""

    rules = namespace_rules or {}
    errors: list[dict[str, Any]] = []
    locale_counts: dict[str, int] = {}
    namespace_counts: dict[str, int] = {}
    for issue in issues:
        locale = issue.locale or "global"
        namespace = _namespace_for_key(issue.key, rules)
        namespace_label = namespace or "unclassified"
        locale_counts[locale] = locale_counts.get(locale, 0) + 1
        namespace_counts[namespace_label] = namespace_counts.get(namespace_label, 0) + 1
        errors.append(
            {
                "category": issue.category,
                "key": issue.key,
                "locale": issue.locale,
                "message": issue.message,
                "namespace": namespace,
            }
        )
    return {
        "schemaVersion": 1,
        "tool": "check_arb_resources",
        "status": "failed" if issues else "passed",
        "summary": {
            "errorCount": len(issues),
            "errorsByLocale": dict(sorted(locale_counts.items())),
            "errorsByNamespace": dict(sorted(namespace_counts.items())),
        },
        "resources": [
            _resource_statistics(english_path, "en", repo_root, rules),
            _resource_statistics(portuguese_path, "pt", repo_root, rules),
        ],
        "errors": errors,
    }


def _print_text_report(report: dict[str, Any]) -> None:
    summary = report["summary"]
    if report["status"] == "passed":
        print("ARB resources are valid.")
        for resource in report["resources"]:
            if not resource["readable"]:
                continue
            print(
                f"- {resource['locale']}: {resource['messageCount']} messages, "
                f"{resource['metadataCount']} metadata entries, "
                f"{resource['placeholderCount']} placeholders, "
                f"{resource['icuMessageCount']} ICU messages"
            )
        return

    error_count = summary["errorCount"]
    print(f"ARB resource validation failed ({error_count} error(s)):")
    grouped_counts: dict[tuple[str, str], int] = {}
    for error in report["errors"]:
        locale = error["locale"] or "global"
        namespace = error["namespace"] or "unclassified"
        group = (locale, namespace)
        grouped_counts[group] = grouped_counts.get(group, 0) + 1
    for (locale, namespace), count in sorted(grouped_counts.items()):
        print(f"- {locale} / {namespace}: {count}")
    for error in report["errors"]:
        print(f"- {error['message']}")


def _write_json_report(path: Path, report: dict[str, Any]) -> None:
    path.parent.mkdir(parents=True, exist_ok=True)
    path.write_text(
        json.dumps(report, ensure_ascii=False, indent=2, sort_keys=True) + "\n",
        encoding="utf-8",
    )


def main(argv: list[str] | None = None) -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    default_root = Path(__file__).resolve().parents[1]
    parser.add_argument("--repo-root", type=Path, default=default_root)
    parser.add_argument("--english", type=Path, default=Path("lib/l10n/app_en.arb"))
    parser.add_argument("--portuguese", type=Path, default=Path("lib/l10n/app_pt.arb"))
    parser.add_argument(
        "--ownership",
        type=Path,
        default=Path("docs/localization/feature_ownership.v1.json"),
        help="optional feature ownership file used to label localization namespaces",
    )
    parser.add_argument(
        "--format",
        choices=("text", "json"),
        default="text",
        help="report format written to standard output",
    )
    parser.add_argument(
        "--json-output",
        type=Path,
        help="also write the deterministic JSON report to this path",
    )
    args = parser.parse_args(argv)
    repo_root = args.repo_root.resolve()
    english_path = (
        args.english if args.english.is_absolute() else repo_root / args.english
    )
    portuguese_path = (
        args.portuguese
        if args.portuguese.is_absolute()
        else repo_root / args.portuguese
    )
    ownership_path = (
        args.ownership if args.ownership.is_absolute() else repo_root / args.ownership
    )
    issues = validate_resource_issues(english_path, portuguese_path)
    report = build_report(
        english_path,
        portuguese_path,
        issues,
        repo_root=repo_root,
        namespace_rules=_load_namespace_rules(ownership_path),
    )
    output_failed = False
    if args.json_output is not None:
        output_path = (
            args.json_output
            if args.json_output.is_absolute()
            else repo_root / args.json_output
        )
        try:
            _write_json_report(output_path, report)
        except (OSError, UnicodeError) as error:
            print(f"cannot write JSON report {output_path}: {error}", file=sys.stderr)
            output_failed = True
    if args.format == "json":
        print(json.dumps(report, ensure_ascii=False, indent=2, sort_keys=True))
    else:
        _print_text_report(report)
    return 1 if issues or output_failed else 0


if __name__ == "__main__":
    sys.exit(main())
