#!/usr/bin/env python3
"""Validate the shipped educational-content inventory and review readiness."""

from __future__ import annotations

import argparse
import hashlib
import json
import re
import sys
from collections import Counter
from datetime import date
from pathlib import Path
from typing import Any, Iterable


LOCALE_STATUSES = {"presentUnreviewed", "reviewed", "missing", "notApplicable"}
REVIEW_STATUSES = {"pending", "approved", "notApplicable"}
ACCESSIBILITY_STATUSES = {
    "pending",
    "presentUnreviewed",
    "approved",
    "missing",
    "notApplicable",
}
SHIPPING_STATUSES = {"shipped"}
STABLE_CONTENT_ID_PATTERN = re.compile(r"^[a-z0-9][a-z0-9._/-]*$")
INSTRUCTION_CONTENT_ID_PATTERN = re.compile(
    r"^[a-z0-9]+(?:-[a-z0-9]+)*(?:/[a-z0-9]+(?:-[a-z0-9]+)*)+$"
)
INSTRUCTION_ARGUMENT_KEY_PATTERN = re.compile(r"^[a-z][A-Za-z0-9]*$")
REVIEWER_TYPES = {
    "translator",
    "technical",
    "editorial",
    "accessibility",
    "provenance",
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


def _read_text(path: Path, errors: list[str]) -> str:
    try:
        return path.read_text(encoding="utf-8")
    except FileNotFoundError:
        errors.append(f"missing source file: {path}")
    except (OSError, UnicodeError) as error:
        errors.append(f"cannot read source file {path}: {error}")
    return ""


def _string_list(value: Any, label: str, errors: list[str]) -> list[str]:
    if not isinstance(value, list) or any(
        not isinstance(item, str) or not item for item in value
    ):
        errors.append(f"{label} must be a list of non-empty strings")
        return []
    return value


def _extract_calls(text: str, needle: str) -> list[str]:
    calls: list[str] = []
    cursor = 0
    while True:
        start = text.find(needle, cursor)
        if start < 0:
            return calls
        open_index = start + len(needle) - 1
        depth = 0
        quote = ""
        raw = False
        escaped = False
        for index in range(open_index, len(text)):
            character = text[index]
            if quote:
                if escaped:
                    escaped = False
                elif character == "\\" and not raw:
                    escaped = True
                elif character == quote:
                    quote = ""
                    raw = False
                continue
            if character in {"'", '"'}:
                quote = character
                raw = index > 0 and text[index - 1] in {"r", "R"}
            elif character == "(":
                depth += 1
            elif character == ")":
                depth -= 1
                if depth == 0:
                    calls.append(text[start : index + 1])
                    cursor = index + 1
                    break
        else:
            return calls


def _dart_string_at(text: str, start: int) -> tuple[str, int] | None:
    cursor = start
    while cursor < len(text) and text[cursor].isspace():
        cursor += 1
    raw = cursor < len(text) and text[cursor] in {"r", "R"}
    if raw:
        cursor += 1
    if cursor >= len(text) or text[cursor] not in {"'", '"'}:
        return None
    quote = text[cursor]
    cursor += 1
    value: list[str] = []
    while cursor < len(text):
        character = text[cursor]
        if character == quote:
            return "".join(value), cursor + 1
        if character == "\\" and not raw:
            cursor += 1
            if cursor >= len(text):
                return None
            escapes = {"n": "\n", "r": "\r", "t": "\t"}
            value.append(escapes.get(text[cursor], text[cursor]))
        else:
            value.append(character)
        cursor += 1
    return None


def _dart_string_list_at(text: str, start: int) -> tuple[list[str], int] | None:
    cursor = start
    while cursor < len(text) and text[cursor].isspace():
        cursor += 1
    if cursor >= len(text) or text[cursor] != "[":
        return None
    cursor += 1
    values: list[str] = []
    while cursor < len(text):
        while cursor < len(text) and text[cursor].isspace():
            cursor += 1
        if cursor < len(text) and text[cursor] == "]":
            return values, cursor + 1
        parsed = _dart_string_at(text, cursor)
        if parsed is None:
            return None
        value, cursor = parsed
        values.append(value)
        while cursor < len(text) and text[cursor].isspace():
            cursor += 1
        if cursor < len(text) and text[cursor] == ",":
            cursor += 1
            continue
        if cursor < len(text) and text[cursor] == "]":
            return values, cursor + 1
        return None
    return None


def _field(call: str, name: str) -> str | None:
    match = re.search(rf"\b{re.escape(name)}\s*:", call)
    if match is None:
        return None
    parsed = _dart_string_at(call, match.end())
    return parsed[0] if parsed is not None else None


def _list_field(call: str, name: str) -> list[str] | None:
    match = re.search(
        rf"\b{re.escape(name)}:\s*(?:const\s*)?(?:<[^>]+>)?\[([^\]]*)\]",
        call,
        re.S,
    )
    if match is None:
        return None
    values: list[str] = []
    cursor = 0
    body = match.group(1)
    while cursor < len(body):
        candidate = re.search(r"(?:[rR])?['\"]", body[cursor:])
        if candidate is None:
            break
        start = cursor + candidate.start()
        parsed = _dart_string_at(body, start)
        if parsed is None:
            return None
        values.append(parsed[0])
        cursor = parsed[1]
    return values


def _string_list_map(
    text: str, declaration: str, label: str, errors: list[str]
) -> dict[str, list[str]]:
    start = text.find(declaration)
    if start < 0:
        errors.append(f"{label} has no {declaration} declaration")
        return {}
    open_brace = text.find("{", start + len(declaration))
    close_brace = text.find("};", open_brace + 1)
    if open_brace < 0 or close_brace < 0:
        errors.append(f"{label} declaration is incomplete")
        return {}

    result: dict[str, list[str]] = {}
    body = text[open_brace + 1 : close_brace]
    cursor = 0
    while cursor < len(body):
        while cursor < len(body) and (body[cursor].isspace() or body[cursor] == ","):
            cursor += 1
        if cursor >= len(body):
            break
        parsed_key = _dart_string_at(body, cursor)
        if parsed_key is None:
            errors.append(f"{label} contains an unparseable map entry")
            break
        key, cursor = parsed_key
        while cursor < len(body) and body[cursor].isspace():
            cursor += 1
        if cursor >= len(body) or body[cursor] != ":":
            errors.append(f"{label} entry {key!r} has no value")
            break
        cursor += 1
        while cursor < len(body) and body[cursor].isspace():
            cursor += 1
        if body.startswith("const", cursor):
            cursor += len("const")
            while cursor < len(body) and body[cursor].isspace():
                cursor += 1
        parsed_values = _dart_string_list_at(body, cursor)
        if parsed_values is None:
            errors.append(f"{label} entry {key!r} must be a string list")
            break
        values, cursor = parsed_values
        if key in result:
            errors.append(f"duplicate {label} id: {key}")
        else:
            result[key] = values
    return result


def _constant_strings(text: str) -> dict[str, str]:
    result: dict[str, str] = {}
    for match in re.finditer(r"static\s+const\s+(\w+)\s*=", text):
        parsed = _dart_string_at(text, match.end())
        if parsed is not None:
            result[match.group(1)] = parsed[0]
    return result


def _id_argument(call: str, constants: dict[str, str]) -> str | None:
    match = re.search(r"\bid\s*:\s*", call)
    if match is None:
        return None
    parsed = _dart_string_at(call, match.end())
    if parsed is not None:
        return parsed[0]
    constant = re.match(r"HelpTopicIds\.(\w+)", call[match.end() :])
    return constants.get(constant.group(1)) if constant is not None else None


def _sha256_json(value: Any) -> str:
    encoded = json.dumps(
        value, ensure_ascii=False, sort_keys=True, separators=(",", ":")
    ).encode("utf-8")
    return hashlib.sha256(encoded).hexdigest()


def _formal_asset_digest(path: Path, errors: list[str]) -> str | None:
    document = _read_json(path, errors)
    if document is None:
        return None
    payload = dict(document)
    for metadata_key in ("name", "title", "description"):
        payload.pop(metadata_key, None)
    return _sha256_json(payload)


def _help_inventory(
    repo_root: Path, sources: dict[str, Any], errors: list[str]
) -> dict[str, dict[str, Any]]:
    help_sources = sources.get("help")
    if not isinstance(help_sources, dict):
        errors.append("sources.help must be an object")
        return {}
    ids_path = help_sources.get("ids")
    catalog_path = help_sources.get("catalog")
    copies = help_sources.get("copies")
    if not isinstance(ids_path, str) or not isinstance(catalog_path, str):
        errors.append("sources.help ids and catalog paths must be strings")
        return {}
    if not isinstance(copies, dict) or not all(
        isinstance(copies.get(locale), str) for locale in ("en", "pt")
    ):
        errors.append("sources.help.copies must contain en and pt paths")
        return {}
    ids_text = _read_text(repo_root / ids_path, errors)
    constants = _constant_strings(ids_text)
    catalog_text = _read_text(repo_root / catalog_path, errors)
    catalog_parse_text = re.sub(
        r"//[^\n]*|/\*.*?\*/", "", catalog_text, flags=re.S
    )
    result: dict[str, dict[str, Any]] = {}
    constructors = {
        "HelpCategoryDefinition(": "helpCategory",
        "HelpSubsectionDefinition(": "helpSubsection",
        "HelpTopicDefinition(": "helpTopic",
        "HelpTopicDefinition.structured(": "helpTopic",
    }
    expected_nodes = len(
        re.findall(
            r"\bHelp(?:Category|Subsection|Topic)Definition(?:\.structured)?\(",
            catalog_parse_text,
        )
    )
    parsed_nodes = 0
    for constructor, kind in constructors.items():
        for match in re.finditer(re.escape(constructor), catalog_parse_text):
            parsed_nodes += 1
            call = catalog_parse_text[match.start() : match.start() + 120]
            content_id = _id_argument(call, constants)
            if content_id is None:
                errors.append(f"cannot extract id from {constructor} in {catalog_path}")
                continue
            if content_id in result:
                errors.append(f"duplicate shipped help id: {content_id}")
                continue
            result[content_id] = {
                "kind": kind,
                "sourcePaths": [catalog_path, ids_path],
            }
    if parsed_nodes != expected_nodes:
        errors.append(
            f"help catalog parser extracted {parsed_nodes} of {expected_nodes} nodes"
        )
    declared = set(constants.values())
    missing_constants = declared - set(result)
    for content_id in sorted(missing_constants):
        errors.append(f"declared help id is not shipped in the catalog: {content_id}")
    for locale in ("en", "pt"):
        copy_path = copies[locale]
        copy_text = _read_text(repo_root / copy_path, errors)
        copy_ids: set[str] = set()
        expected_copies = copy_text.count("HelpNodeCopy(")
        for match in re.finditer(r"(?:HelpTopicIds\.(\w+)|(?:[rR])?['\"])", copy_text):
            tail = copy_text[match.start() :]
            separator = re.match(
                r"HelpTopicIds\.(\w+)\s*:\s*HelpNodeCopy\(", tail
            )
            if separator is not None:
                content_id = constants.get(separator.group(1))
                if content_id is None:
                    errors.append(
                        f"{locale} help copy references unknown HelpTopicIds."
                        f"{separator.group(1)}"
                    )
                else:
                    copy_ids.add(content_id)
                continue
            parsed = _dart_string_at(copy_text, match.start())
            if parsed is None:
                continue
            after = copy_text[parsed[1] :]
            if re.match(r"\s*:\s*HelpNodeCopy\(", after):
                copy_ids.add(parsed[0])
        if len(copy_ids) != expected_copies:
            errors.append(
                f"{locale} help copy parser extracted {len(copy_ids)} of "
                f"{expected_copies} entries"
            )
        for content_id in sorted(set(result) - copy_ids):
            errors.append(f"{locale} help copy is missing shipped id: {content_id}")
        for content_id in sorted(copy_ids - set(result)):
            errors.append(f"{locale} help copy has unshipped id: {content_id}")
    return result


def _example_inventory(
    repo_root: Path, sources: dict[str, Any], errors: list[str]
) -> dict[str, dict[str, Any]]:
    catalogs = sources.get("exampleCatalogs")
    if not isinstance(catalogs, list):
        errors.append("sources.exampleCatalogs must be a list")
        return {}
    result: dict[str, dict[str, Any]] = {}
    catalog_strategies: dict[str, str] = {}
    referenced_assets: set[str] = set()
    code_backed_hashes: dict[str, str] = {}
    code_backed_used: set[str] = set()
    code_backed_path = sources.get("codeBackedFormalPayloads")
    if isinstance(code_backed_path, str):
        code_backed = _read_json(repo_root / code_backed_path, errors)
        if code_backed is not None:
            if (
                code_backed.get("schemaVersion") != 1
                or code_backed.get("contract") != "canonicalRuntimeJsonV1"
            ):
                errors.append("code-backed formal payload contract is unsupported")
            hashes = code_backed.get("payloadSha256")
            if not isinstance(hashes, dict) or not all(
                isinstance(key, str)
                and isinstance(value, str)
                and re.fullmatch(r"[0-9a-f]{64}", value)
                for key, value in hashes.items()
            ):
                errors.append("code-backed formal payload hashes are invalid")
            else:
                code_backed_hashes = hashes

    def add(
        content_id: str,
        source_paths: list[str],
        asset_path: str | None,
        legacy_lookup_key: str | None = None,
        catalog_strategy: str = "",
    ) -> None:
        if content_id in result:
            errors.append(f"duplicate shipped example id: {content_id}")
            return
        record: dict[str, Any] = {"kind": "example", "sourcePaths": source_paths}
        if legacy_lookup_key is not None:
            record["legacyLookupKey"] = legacy_lookup_key
        if asset_path is not None:
            record["assetPath"] = asset_path
            referenced_assets.add(asset_path)
            digest = _formal_asset_digest(repo_root / asset_path, errors)
            if digest is not None:
                record["formalPayloadSha256"] = digest
        result[content_id] = record
        catalog_strategies[content_id] = catalog_strategy

    for index, catalog in enumerate(catalogs):
        if not isinstance(catalog, dict):
            errors.append(f"sources.exampleCatalogs[{index}] must be an object")
            continue
        strategy = catalog.get("strategy")
        relative = catalog.get("path")
        if not isinstance(strategy, str) or not isinstance(relative, str):
            errors.append(f"sources.exampleCatalogs[{index}] needs strategy and path")
            continue
        text = _read_text(repo_root / relative, errors)
        if strategy == "assetMetadata":
            copy_relative = catalog.get("copyPath")
            copy_ids: set[str] | None = None
            if copy_relative is not None:
                copy_ids = set()
                if not isinstance(copy_relative, str) or not copy_relative:
                    errors.append(
                        f"sources.exampleCatalogs[{index}].copyPath must be a "
                        "non-empty string for assetMetadata"
                    )
                else:
                    copy_text = _read_text(repo_root / copy_relative, errors)
                    copy_values = copy_text.split("static final _entries", 1)[-1].split(
                        "]);", 1
                    )[0]
                    copy_calls = _extract_calls(copy_values, "_entry(")
                    expected_copy_calls = copy_values.count("_entry(")
                    if len(copy_calls) != expected_copy_calls:
                        errors.append(
                            "assetMetadata copy parser extracted "
                            f"{len(copy_calls)} of {expected_copy_calls} entries"
                        )
                    required_copy_fields = {
                        "title",
                        "summary",
                        "learningObjective",
                        "limitation",
                        "accessibleDescription",
                    }
                    for copy_call in copy_calls:
                        copy_id = _field(copy_call, "id")
                        localized_calls = _extract_calls(
                            copy_call, "AssetExampleContentCopy("
                        )
                        if copy_id is None:
                            errors.append("assetMetadata copy entry has no stable id")
                            continue
                        if copy_id in copy_ids:
                            errors.append(f"duplicate assetMetadata copy id: {copy_id}")
                        copy_ids.add(copy_id)
                        if (
                            re.search(
                                r"\ben\s*:\s*const\s+AssetExampleContentCopy\(",
                                copy_call,
                            )
                            is None
                            or re.search(
                                r"\bpt\s*:\s*const\s+AssetExampleContentCopy\(",
                                copy_call,
                            )
                            is None
                            or len(localized_calls) != 2
                        ):
                            errors.append(
                                "assetMetadata copy entry is not bilingual: "
                                f"{copy_id}"
                            )
                            continue
                        for locale_index, localized_call in enumerate(localized_calls):
                            locale = "en" if locale_index == 0 else "pt"
                            for field in sorted(required_copy_fields):
                                if _field(localized_call, field) is None:
                                    errors.append(
                                        f"assetMetadata {locale} copy for {copy_id} "
                                        f"has no {field}"
                                    )
            matches = list(re.finditer(r"^\s*((?:[rR])?['\"])", text, re.M))
            matches = [
                match
                for match in matches
                if re.match(
                    r"\s*:\s*_ExampleMetadata\(",
                    text[_dart_string_at(text, match.start())[1] :]
                    if _dart_string_at(text, match.start()) is not None
                    else "",
                )
            ]
            expected = len(re.findall(r":\s*_ExampleMetadata\(", text))
            if len(matches) != expected:
                errors.append(
                    f"assetMetadata parser extracted {len(matches)} of "
                    f"{expected} entries"
                )
            asset_metadata_ids: set[str] = set()
            for match in matches:
                parsed_key = _dart_string_at(text, match.start())
                if parsed_key is None:
                    errors.append(f"cannot extract asset metadata key in {relative}")
                    continue
                call = _extract_calls(text[match.start() :], "_ExampleMetadata(")
                file_name = _field(call[0], "fileName") if call else None
                if file_name is None:
                    errors.append(f"example metadata has no fileName: {parsed_key[0]}")
                    continue
                asset_path = f"assets/examples/{file_name}"
                content_id = f"asset/{Path(file_name).stem.lower()}"
                asset_metadata_ids.add(content_id)
                add(
                    content_id,
                    [
                        relative,
                        asset_path,
                        *(
                            [copy_relative]
                            if copy_ids is not None and content_id in copy_ids
                            else []
                        ),
                    ],
                    asset_path,
                    legacy_lookup_key=parsed_key[0],
                    catalog_strategy=strategy,
                )
            if copy_ids is not None and not copy_ids.issubset(asset_metadata_ids):
                errors.append("assetMetadata localized copy coverage drifted")
        elif strategy in {"mealyDefinitions", "mooreDefinitions"}:
            class_name = (
                "_MealyExampleDefinition("
                if strategy == "mealyDefinitions"
                else "_MooreExampleDefinition("
            )
            definitions = text.split("static const _definitions", 1)[-1].split(
                "];", 1
            )[0]
            calls = _extract_calls(definitions, class_name)
            expected = definitions.count(class_name)
            if len(calls) != expected:
                errors.append(
                    f"{strategy} parser extracted {len(calls)} of {expected} entries"
                )
            for call in calls:
                asset_path = _field(call, "path")
                explicit_id = _field(call, "id")
                legacy_name = _field(call, "name")
                if asset_path is None or (explicit_id is None and legacy_name is None):
                    errors.append(f"incomplete {strategy} entry in {relative}")
                    continue
                content_id = explicit_id or f"asset/{Path(asset_path).stem.lower()}"
                add(
                    content_id,
                    [relative, asset_path],
                    asset_path,
                    legacy_lookup_key=(
                        legacy_name if strategy == "mooreDefinitions" else None
                    ),
                    catalog_strategy=strategy,
                )
        elif strategy == "lSystemValues":
            copy_relative = catalog.get("copyPath")
            copy_ids: set[str] = set()
            source_paths = [relative]
            if not isinstance(copy_relative, str) or not copy_relative:
                errors.append(
                    f"sources.exampleCatalogs[{index}].copyPath must be a "
                    "non-empty string for lSystemValues"
                )
            else:
                source_paths.append(copy_relative)
                copy_text = _read_text(repo_root / copy_relative, errors)
                copy_values = copy_text.split("static final _entries", 1)[-1].split(
                    "]);", 1
                )[0]
                copy_calls = _extract_calls(copy_values, "_entry(")
                expected_copy_calls = copy_values.count("_entry(")
                if len(copy_calls) != expected_copy_calls:
                    errors.append(
                        "lSystemValues copy parser extracted "
                        f"{len(copy_calls)} of {expected_copy_calls} entries"
                    )
                required_copy_fields = {
                    "title",
                    "summary",
                    "learningObjective",
                    "limitation",
                    "accessibleVisualizationDescription",
                }
                for copy_call in copy_calls:
                    copy_id = _field(copy_call, "id")
                    localized_calls = _extract_calls(
                        copy_call, "LSystemExampleContentCopy("
                    )
                    if copy_id is None:
                        errors.append("lSystemValues copy entry has no stable id")
                        continue
                    if copy_id in copy_ids:
                        errors.append(f"duplicate lSystemValues copy id: {copy_id}")
                    copy_ids.add(copy_id)
                    if (
                        re.search(
                            r"\ben\s*:\s*const\s+LSystemExampleContentCopy\(",
                            copy_call,
                        )
                        is None
                        or re.search(
                            r"\bpt\s*:\s*const\s+LSystemExampleContentCopy\(",
                            copy_call,
                        )
                        is None
                        or len(localized_calls) != 2
                    ):
                        errors.append(
                            f"lSystemValues copy entry is not bilingual: {copy_id}"
                        )
                        continue
                    for locale_index, localized_call in enumerate(localized_calls):
                        locale = "en" if locale_index == 0 else "pt"
                        for field in sorted(required_copy_fields):
                            if _field(localized_call, field) is None:
                                errors.append(
                                    f"lSystemValues {locale} copy for {copy_id} "
                                    f"has no {field}"
                                )
            values = text.split("static final values", 1)[-1].split("]);", 1)[0]
            calls = _extract_calls(values, "_example(") + _extract_calls(
                values, "LSystemExample("
            )
            expected = values.count("_example(") + values.count("LSystemExample(")
            if len(calls) != expected:
                errors.append(
                    f"{strategy} parser extracted {len(calls)} of {expected} entries"
                )
            for call in calls:
                content_id = _field(call, "id")
                if content_id is None:
                    errors.append(f"cannot extract id from {strategy} entry in {relative}")
                    continue
                add(content_id, source_paths, None, catalog_strategy=strategy)
                digest = code_backed_hashes.get(content_id)
                if digest is None:
                    errors.append(f"missing canonical runtime hash for {content_id}")
                else:
                    result[content_id]["formalPayloadSha256"] = digest
                    code_backed_used.add(content_id)
            l_system_ids = {
                content_id
                for content_id, record in result.items()
                if relative in record["sourcePaths"]
            }
            if copy_ids != l_system_ids:
                errors.append("lSystemValues localized copy coverage drifted")
        elif strategy == "unrestrictedCatalog":
            source_paths = [relative]
            copy_ids: set[str] | None = None
            if strategy == "unrestrictedCatalog":
                copy_relative = catalog.get("copyPath")
                copy_ids = set()
                if not isinstance(copy_relative, str) or not copy_relative:
                    errors.append(
                        f"sources.exampleCatalogs[{index}].copyPath must be a "
                        "non-empty string for unrestrictedCatalog"
                    )
                else:
                    source_paths.append(copy_relative)
                    copy_text = _read_text(repo_root / copy_relative, errors)
                    copy_values = copy_text.split("static final _entries", 1)[-1].split(
                        "]);", 1
                    )[0]
                    copy_calls = _extract_calls(copy_values, "_entry(")
                    expected_copy_calls = copy_values.count("_entry(")
                    if len(copy_calls) != expected_copy_calls:
                        errors.append(
                            "unrestrictedCatalog copy parser extracted "
                            f"{len(copy_calls)} of {expected_copy_calls} entries"
                        )
                    required_copy_fields = {
                        "title",
                        "summary",
                        "learningObjective",
                        "limitation",
                        "accessibleDescription",
                    }
                    for copy_call in copy_calls:
                        copy_id = _field(copy_call, "id")
                        localized_calls = _extract_calls(
                            copy_call, "UnrestrictedGrammarExampleContentCopy("
                        )
                        if copy_id is None:
                            errors.append(
                                "unrestrictedCatalog copy entry has no stable id"
                            )
                            continue
                        if copy_id in copy_ids:
                            errors.append(
                                f"duplicate unrestrictedCatalog copy id: {copy_id}"
                            )
                        copy_ids.add(copy_id)
                        if (
                            re.search(
                                r"\ben\s*:\s*const\s+"
                                r"UnrestrictedGrammarExampleContentCopy\(",
                                copy_call,
                            )
                            is None
                            or re.search(
                                r"\bpt\s*:\s*const\s+"
                                r"UnrestrictedGrammarExampleContentCopy\(",
                                copy_call,
                            )
                            is None
                            or len(localized_calls) != 2
                        ):
                            errors.append(
                                "unrestrictedCatalog copy entry is not bilingual: "
                                f"{copy_id}"
                            )
                            continue
                        for locale_index, localized_call in enumerate(localized_calls):
                            locale = "en" if locale_index == 0 else "pt"
                            for field in sorted(required_copy_fields):
                                if _field(localized_call, field) is None:
                                    errors.append(
                                        f"unrestrictedCatalog {locale} copy for "
                                        f"{copy_id} has no {field}"
                                    )
            load_section = text.split("loadExamples()", 1)[-1].split("];", 1)[0]
            calls = _extract_calls(load_section, "AssetExample<")
            expected = load_section.count("AssetExample<")
            if len(calls) != expected:
                errors.append(
                    f"{strategy} parser extracted {len(calls)} of {expected} entries"
                )
            for call in calls:
                content_id = _field(call, "id")
                if content_id is None:
                    errors.append(f"cannot extract id from {strategy} entry in {relative}")
                    continue
                add(content_id, source_paths, None, catalog_strategy=strategy)
                digest = code_backed_hashes.get(content_id)
                if digest is None:
                    errors.append(f"missing canonical runtime hash for {content_id}")
                else:
                    result[content_id]["formalPayloadSha256"] = digest
                    code_backed_used.add(content_id)
            if copy_ids is not None:
                unrestricted_ids = {
                    content_id
                    for content_id, record in result.items()
                    if relative in record["sourcePaths"]
                }
                if copy_ids != unrestricted_ids:
                    errors.append(
                        "unrestrictedCatalog localized copy coverage drifted"
                    )
        elif strategy == "tmBlockCatalog":
            source_paths = [relative]
            copy_relative = catalog.get("copyPath")
            copy_ids: set[str] = set()
            if not isinstance(copy_relative, str) or not copy_relative:
                errors.append(
                    f"sources.exampleCatalogs[{index}].copyPath must be a "
                    "non-empty string for tmBlockCatalog"
                )
            else:
                source_paths.append(copy_relative)
                copy_text = _read_text(repo_root / copy_relative, errors)
                copy_values = copy_text.split("static final _entries", 1)[-1].split(
                    "]);", 1
                )[0]
                copy_calls = _extract_calls(copy_values, "_entry(")
                expected_copy_calls = copy_values.count("_entry(")
                if len(copy_calls) != expected_copy_calls:
                    errors.append(
                        "tmBlockCatalog copy parser extracted "
                        f"{len(copy_calls)} of {expected_copy_calls} entries"
                    )
                required_copy_fields = {
                    "title",
                    "summary",
                    "learningObjective",
                    "limitation",
                    "accessibleDescription",
                }
                for copy_call in copy_calls:
                    copy_id = _field(copy_call, "id")
                    localized_calls = _extract_calls(
                        copy_call, "TMBlockExampleContentCopy("
                    )
                    if copy_id is None:
                        errors.append("tmBlockCatalog copy entry has no stable id")
                        continue
                    if copy_id in copy_ids:
                        errors.append(f"duplicate tmBlockCatalog copy id: {copy_id}")
                    copy_ids.add(copy_id)
                    if (
                        re.search(
                            r"\ben\s*:\s*const\s+TMBlockExampleContentCopy\(",
                            copy_call,
                        )
                        is None
                        or re.search(
                            r"\bpt\s*:\s*const\s+TMBlockExampleContentCopy\(",
                            copy_call,
                        )
                        is None
                        or len(localized_calls) != 2
                    ):
                        errors.append(
                            "tmBlockCatalog copy entry is not bilingual: "
                            f"{copy_id}"
                        )
                        continue
                    for locale_index, localized_call in enumerate(localized_calls):
                        locale = "en" if locale_index == 0 else "pt"
                        for field in sorted(required_copy_fields):
                            if _field(localized_call, field) is None:
                                errors.append(
                                    f"tmBlockCatalog {locale} copy for {copy_id} "
                                    f"has no {field}"
                                )
            load_section = text.split("loadExamples()", 1)[-1].split("];", 1)[0]
            calls = _extract_calls(load_section, "AssetExample<")
            expected = load_section.count("AssetExample<")
            if len(calls) != expected:
                errors.append(
                    f"{strategy} parser extracted {len(calls)} of {expected} entries"
                )
            for call in calls:
                content_id = _field(call, "id")
                if content_id is None:
                    errors.append(f"cannot extract id from {strategy} entry in {relative}")
                    continue
                add(content_id, source_paths, None, catalog_strategy=strategy)
                digest = code_backed_hashes.get(content_id)
                if digest is None:
                    errors.append(f"missing canonical runtime hash for {content_id}")
                else:
                    result[content_id]["formalPayloadSha256"] = digest
                    code_backed_used.add(content_id)
            catalog_ids = {
                content_id
                for content_id, record in result.items()
                if relative in record["sourcePaths"]
            }
            if copy_ids != catalog_ids:
                errors.append("tmBlockCatalog localized copy coverage drifted")
        else:
            errors.append(f"unknown example catalog strategy: {strategy}")

    if code_backed_used != set(code_backed_hashes):
        errors.append("code-backed formal payload fixture has unshipped or missing ids")

    suggestions = sources.get("exampleSuggestedSimulations")
    if suggestions is not None:
        if not isinstance(suggestions, dict):
            errors.append("sources.exampleSuggestedSimulations must be an object")
        else:
            suggestion_path = suggestions.get("path")
            excluded = suggestions.get("excludedCatalogStrategies")
            if not isinstance(suggestion_path, str) or not suggestion_path:
                errors.append(
                    "sources.exampleSuggestedSimulations.path must be a non-empty string"
                )
            if excluded != ["lSystemValues"]:
                errors.append(
                    "sources.exampleSuggestedSimulations.excludedCatalogStrategies "
                    "must contain only lSystemValues"
                )
            if isinstance(suggestion_path, str) and suggestion_path:
                suggestion_text = _read_text(repo_root / suggestion_path, errors)
                suggestion_values = _string_list_map(
                    suggestion_text,
                    "static const byExampleId",
                    "example suggested simulations",
                    errors,
                )
                expected_ids = {
                    content_id
                    for content_id, strategy in catalog_strategies.items()
                    if strategy != "lSystemValues"
                }
                suggestion_ids = set(suggestion_values)
                for content_id in sorted(expected_ids - suggestion_ids):
                    errors.append(
                        "example suggested simulations are missing shipped id: "
                        f"{content_id}"
                    )
                for content_id in sorted(suggestion_ids - expected_ids):
                    errors.append(
                        "example suggested simulations have excluded or unshipped id: "
                        f"{content_id}"
                    )
                for content_id, values in sorted(suggestion_values.items()):
                    if not values or any(not value for value in values):
                        errors.append(
                            "example suggested simulations for "
                            f"{content_id} contain no usable input"
                        )
                    elif len(values) != len(set(values)):
                        errors.append(
                            f"example suggested simulations for {content_id} are duplicated"
                        )

    assets_root = sources.get("assetExamplesRoot")
    if not isinstance(assets_root, str):
        errors.append("sources.assetExamplesRoot must be a string")
    else:
        actual_assets = {
            path.relative_to(repo_root).as_posix()
            for path in (repo_root / assets_root).glob("*.json")
        }
        for asset in sorted(actual_assets - referenced_assets):
            errors.append(f"example asset is not shipped by a catalog: {asset}")
        for asset in sorted(referenced_assets - actual_assets):
            errors.append(f"example catalog references missing asset: {asset}")
    return result


def _exercise_contract(call: str, source_revision: str) -> dict[str, Any] | None:
    content_id = _field(call, "id")
    language = _field(call, "language")
    representation = _field(call, "representation")
    theorem_match = re.search(r"theorem:\s*PumpingLemmaTheorem\.(\w+)", call)
    length_match = re.search(r"pumpingLength:\s*(\d+)", call)
    outcome_match = re.search(r"expectedOutcome:\s*PumpingChallengeOutcome\.(\w+)", call)
    witness = _list_field(call, "witness")
    rejected = _list_field(call, "rejectedExample")
    if (
        content_id is None
        or language is None
        or representation is None
        or theorem_match is None
        or length_match is None
        or outcome_match is None
        or witness is None
        or rejected is None
    ):
        return None
    return {
        "id": content_id,
        "sourceRevision": source_revision,
        "language": language,
        "constraints": {
            "theorem": theorem_match.group(1),
            "representationKind": "curatedPredicate",
            "representation": representation,
            "pumpingLength": int(length_match.group(1)),
        },
        "expectedAnswers": [
            {"tokens": witness, "expectedMembership": True},
            {"tokens": rejected, "expectedMembership": False},
        ],
        "expectedOutcome": outcome_match.group(1),
    }


def _exercise_inventory(
    repo_root: Path, sources: dict[str, Any], errors: list[str]
) -> dict[str, dict[str, Any]]:
    pumping_sources = sources.get("pumpingExercises")
    if not isinstance(pumping_sources, dict):
        errors.append("sources.pumpingExercises must be an object")
        return {}
    relative = pumping_sources.get("path")
    copy_relative = pumping_sources.get("copyPath")
    if not isinstance(relative, str) or not isinstance(copy_relative, str):
        errors.append("sources.pumpingExercises needs path and copyPath")
        return {}
    text = _read_text(repo_root / relative, errors)
    helper_start = text.find("PumpingLemmaProblem _problem(")
    calls_source = text if helper_start < 0 else text[:helper_start]
    revision_call = text[helper_start:] if helper_start >= 0 else text
    source_revision = _field(revision_call, "sourceRevision")
    if source_revision is None:
        errors.append("pumping exercise source has no sourceRevision")
        return {}
    content_version_match = re.search(r"contentVersion:\s*(\d+)", revision_call)
    if content_version_match is None:
        errors.append("pumping exercise source has no contentVersion")
        return {}
    content_version = int(content_version_match.group(1))
    if content_version < 1:
        errors.append("pumping exercise contentVersion must be positive")
        return {}
    result: dict[str, dict[str, Any]] = {}
    calls = _extract_calls(calls_source, "_problem(")
    expected = calls_source.count("_problem(")
    if len(calls) != expected:
        errors.append(
            f"pumping parser extracted {len(calls)} of {expected} exercise calls"
        )
    for call in calls:
        contract = _exercise_contract(call, source_revision)
        if contract is None:
            errors.append("cannot extract complete pumping exercise contract")
            continue
        content_id = contract["id"]
        if content_id in result:
            errors.append(f"duplicate shipped exercise id: {content_id}")
            continue
        result[content_id] = {
            "kind": "exercise",
            "sourcePaths": [relative],
            "formalPayloadSha256": _sha256_json(contract),
            "contentVersion": content_version,
        }
    if not result:
        errors.append("pumping exercise source yielded no shipped exercises")
        return result

    copy_text = _read_text(repo_root / copy_relative, errors)
    copy_values = copy_text.split("static final _entries", 1)[-1].split(
        "]);", 1
    )[0]
    copy_calls = _extract_calls(copy_values, "_entry(")
    expected_copy_calls = copy_values.count("_entry(")
    if len(copy_calls) != expected_copy_calls:
        errors.append(
            f"pumping copy parser extracted {len(copy_calls)} of "
            f"{expected_copy_calls} entries"
        )
    copy_ids: set[str] = set()
    for copy_call in copy_calls:
        copy_id = _field(copy_call, "id")
        localized_calls = _extract_calls(
            copy_call, "PumpingLemmaProblemContentCopy("
        )
        if copy_id is None:
            errors.append("pumping copy entry has no stable id")
            continue
        if copy_id in copy_ids:
            errors.append(f"duplicate pumping copy id: {copy_id}")
        copy_ids.add(copy_id)
        if (
            re.search(
                r"\ben\s*:\s*const\s+PumpingLemmaProblemContentCopy\(",
                copy_call,
            )
            is None
            or re.search(
                r"\bpt\s*:\s*const\s+PumpingLemmaProblemContentCopy\(",
                copy_call,
            )
            is None
            or len(localized_calls) != 2
        ):
            errors.append(f"pumping copy entry is not bilingual: {copy_id}")
            continue
        for locale_index, localized_call in enumerate(localized_calls):
            locale = "en" if locale_index == 0 else "pt"
            for field in ("title", "learningObjective", "explanation"):
                if _field(localized_call, field) is None:
                    errors.append(
                        f"pumping {locale} copy for {copy_id} has no {field}"
                    )
    if copy_ids != set(result):
        errors.append("pumping localized copy coverage drifted")
    for record in result.values():
        record["sourcePaths"].append(copy_relative)
    return result


def _instruction_inventory(
    repo_root: Path, sources: dict[str, Any], errors: list[str]
) -> dict[str, dict[str, Any]]:
    catalogs = sources.get("instructionCatalogs", [])
    if not isinstance(catalogs, list):
        errors.append("sources.instructionCatalogs must be a list")
        return {}
    result: dict[str, dict[str, Any]] = {}
    for index, catalog in enumerate(catalogs):
        label = f"sources.instructionCatalogs[{index}]"
        if not isinstance(catalog, dict):
            errors.append(f"{label} must be an object")
            continue
        relative = catalog.get("path")
        implementation_paths = catalog.get("implementationPaths")
        excluded_names = catalog.get("excludedReferences", [])
        copy_path = catalog.get("copyPath")
        copy_reference_owner = catalog.get("copyReferenceOwner")
        if not isinstance(relative, str) or not relative:
            errors.append(f"{label}.path must be a non-empty string")
            continue
        if not isinstance(implementation_paths, list) or any(
            not isinstance(path, str) or not path for path in implementation_paths
        ):
            errors.append(f"{label}.implementationPaths must be a string list")
            continue
        if not isinstance(excluded_names, list) or any(
            not isinstance(name, str) or not name for name in excluded_names
        ):
            errors.append(f"{label}.excludedReferences must be a string list")
            continue
        if copy_path is not None and (
            not isinstance(copy_path, str) or not copy_path
        ):
            errors.append(f"{label}.copyPath must be a non-empty string")
            continue
        if isinstance(copy_path, str) and (
            not isinstance(copy_reference_owner, str) or not copy_reference_owner
        ):
            errors.append(f"{label}.copyReferenceOwner must be a non-empty string")
            continue
        source_paths = [
            relative,
            *implementation_paths,
            *([copy_path] if isinstance(copy_path, str) else []),
        ]
        for source_path in source_paths:
            if not (repo_root / source_path).is_file():
                errors.append(f"{label} references missing source: {source_path}")
        text = _read_text(repo_root / relative, errors)
        declarations: dict[str, tuple[str, int, list[str]]] = {}
        declaration_pattern = re.compile(
            r"static\s+final\s+(\w+)\s*=\s*EducationalContentReference\("
        )
        for match in declaration_pattern.finditer(text):
            calls = _extract_calls(text[match.start() :], "EducationalContentReference(")
            if not calls:
                errors.append(f"cannot parse instruction reference {match.group(1)}")
                continue
            call = calls[0]
            content_id = _field(call, "id")
            version_match = re.search(r"\bversion\s*:\s*(\d+)", call)
            argument_keys = _list_field(call, "argumentKeys")
            if content_id is None or version_match is None:
                errors.append(f"incomplete instruction reference {match.group(1)}")
                continue
            version = int(version_match.group(1))
            declarations[match.group(1)] = (
                content_id,
                version,
                argument_keys if argument_keys is not None else [],
            )
        shipped_match = re.search(
            r"static\s+final\s+shipped\s*=\s*"
            r"List<EducationalContentReference>\.unmodifiable\(\s*"
            r"\[(.*?)\]\s*\);",
            text,
            re.S,
        )
        if shipped_match is None:
            errors.append(f"{label} has no parseable shipped reference list")
            continue
        shipped_names = re.findall(r"\b([a-zA-Z]\w*)\s*,", shipped_match.group(1))
        if len(shipped_names) != len(set(shipped_names)):
            errors.append(f"{label} shipped reference list has duplicates")
        expected_unshipped = set(excluded_names)
        actual_unshipped = set(declarations) - set(shipped_names)
        if actual_unshipped != expected_unshipped:
            errors.append(f"{label} excluded reference declarations drifted")
        if isinstance(copy_path, str):
            copy_text = _read_text(repo_root / copy_path, errors)
            copy_names = re.findall(
                rf"\breference:\s*{re.escape(copy_reference_owner)}\.(\w+)",
                copy_text,
            )
            if Counter(copy_names) != Counter(shipped_names):
                errors.append(f"{label} localized copy coverage drifted")
        for name in shipped_names:
            reference = declarations.get(name)
            if reference is None:
                errors.append(f"{label} ships unknown reference: {name}")
                continue
            content_id, version, argument_keys = reference
            valid = True
            if INSTRUCTION_CONTENT_ID_PATTERN.fullmatch(content_id) is None:
                errors.append(f"invalid instruction content id: {content_id!r}")
                valid = False
            if version < 1:
                errors.append(f"instruction version must be positive: {content_id}")
                valid = False
            if len(argument_keys) != len(set(argument_keys)):
                errors.append(f"instruction argument keys are duplicated: {content_id}")
                valid = False
            if any(
                INSTRUCTION_ARGUMENT_KEY_PATTERN.fullmatch(key) is None
                for key in argument_keys
            ):
                errors.append(f"instruction argument key is invalid: {content_id}")
                valid = False
            if content_id in result:
                errors.append(f"duplicate shipped instruction id: {content_id}")
                continue
            if not valid:
                continue
            contract = {
                "id": content_id,
                "version": version,
                "argumentKeys": argument_keys,
            }
            result[content_id] = {
                "kind": "instruction",
                "sourcePaths": source_paths,
                "contentVersion": version,
                "formalPayloadSha256": _sha256_json(contract),
            }
    return result


def _source_inventory(
    repo_root: Path, inventory: dict[str, Any], errors: list[str]
) -> dict[tuple[str, str], dict[str, Any]]:
    sources = inventory.get("sources")
    if not isinstance(sources, dict):
        errors.append("sources must be an object")
        return {}
    records: dict[tuple[str, str], dict[str, Any]] = {}
    for content_id, record in _help_inventory(repo_root, sources, errors).items():
        records[(record["kind"], content_id)] = record
    for content_id, record in _example_inventory(repo_root, sources, errors).items():
        records[("example", content_id)] = record
    for content_id, record in _exercise_inventory(repo_root, sources, errors).items():
        records[("exercise", content_id)] = record
    for content_id, record in _instruction_inventory(
        repo_root, sources, errors
    ).items():
        records[("instruction", content_id)] = record
    return records


def _validate_profile(
    repo_root: Path, name: str, profile: Any, errors: list[str]
) -> None:
    label = f"profiles.{name}"
    if not isinstance(profile, dict):
        errors.append(f"{label} must be an object")
        return
    if profile.get("shippingStatus") not in SHIPPING_STATUSES:
        errors.append(f"{label}.shippingStatus is invalid")
    if profile.get("ownerIssue") != 344:
        errors.append(f"{label}.ownerIssue must be #344")
    version = profile.get("contentVersion")
    if not isinstance(version, int) or isinstance(version, bool) or version < 1:
        errors.append(f"{label}.contentVersion must be a positive integer")
    locale_status = profile.get("localeStatus")
    if not isinstance(locale_status, dict):
        errors.append(f"{label}.localeStatus must be an object")
    else:
        for locale in ("en", "pt"):
            if locale_status.get(locale) not in LOCALE_STATUSES:
                errors.append(f"{label}.localeStatus.{locale} is invalid")
    if profile.get("technicalReviewStatus") not in REVIEW_STATUSES:
        errors.append(f"{label}.technicalReviewStatus is invalid")
    if profile.get("editorialReviewStatus") not in REVIEW_STATUSES:
        errors.append(f"{label}.editorialReviewStatus is invalid")
    if profile.get("accessibilityAlternativeStatus") not in ACCESSIBILITY_STATUSES:
        errors.append(f"{label}.accessibilityAlternativeStatus is invalid")
    provenance = profile.get("provenance")
    if not isinstance(provenance, dict):
        errors.append(f"{label}.provenance must be an object")
    else:
        for field in ("sourceKind", "license", "reviewStatus"):
            if not isinstance(provenance.get(field), str) or not provenance[field]:
                errors.append(f"{label}.provenance.{field} is required")
    evidence = profile.get("reviewEvidence")
    if not isinstance(evidence, list):
        errors.append(f"{label}.reviewEvidence must be a list")
        evidence = []
    scopes: set[str] = set()
    for index, record in enumerate(evidence):
        record_label = f"{label}.reviewEvidence[{index}]"
        if not isinstance(record, dict):
            errors.append(f"{record_label} must be an object")
            continue
        scope = record.get("scope")
        if scope not in {
            "locale.en",
            "locale.pt",
            "technical",
            "editorial",
            "accessibility",
            "provenance",
        }:
            errors.append(f"{record_label}.scope is invalid")
            continue
        scopes.add(scope)
        if not isinstance(record.get("reviewerId"), str) or not record["reviewerId"]:
            errors.append(f"{record_label}.reviewerId is required")
        if record.get("reviewerType") not in REVIEWER_TYPES:
            errors.append(f"{record_label}.reviewerType is invalid")
        if record.get("reviewedContentVersion") != version:
            errors.append(
                f"{record_label}.reviewedContentVersion must match contentVersion"
            )
        reviewed_at = record.get("reviewedAt")
        try:
            if not isinstance(reviewed_at, str):
                raise ValueError
            date.fromisoformat(reviewed_at)
        except ValueError:
            errors.append(f"{record_label}.reviewedAt must be an ISO date")
        evidence_path = record.get("evidencePath")
        if (
            not isinstance(evidence_path, str)
            or not evidence_path
            or not (repo_root / evidence_path).is_file()
        ):
            errors.append(f"{record_label}.evidencePath must reference a file")
    approved_scopes = {
        "locale.en": isinstance(locale_status, dict)
        and locale_status.get("en") == "reviewed",
        "locale.pt": isinstance(locale_status, dict)
        and locale_status.get("pt") == "reviewed",
        "technical": profile.get("technicalReviewStatus") == "approved",
        "editorial": profile.get("editorialReviewStatus") == "approved",
        "accessibility": profile.get("accessibilityAlternativeStatus") == "approved",
        "provenance": isinstance(provenance, dict)
        and provenance.get("reviewStatus") == "approved",
    }
    for scope, approved in approved_scopes.items():
        if approved and scope not in scopes:
            errors.append(f"{label} approves {scope} without linked review evidence")


def _evidence_contracts(
    repo_root: Path, inventory: dict[str, Any], errors: list[str]
) -> dict[str, dict[str, Any]]:
    value = inventory.get("evidenceContracts")
    if not isinstance(value, list) or not value:
        errors.append("evidenceContracts must be a non-empty list")
        return {}
    result: dict[str, dict[str, Any]] = {}
    for index, contract in enumerate(value):
        label = f"evidenceContracts[{index}]"
        if not isinstance(contract, dict):
            errors.append(f"{label} must be an object")
            continue
        contract_id = contract.get("id")
        test_path = contract.get("testPath")
        if (
            not isinstance(contract_id, str)
            or STABLE_CONTENT_ID_PATTERN.fullmatch(contract_id) is None
        ):
            errors.append(f"{label}.id is invalid")
            continue
        if contract_id in result:
            errors.append(f"duplicate evidence contract: {contract_id}")
            continue
        if (
            not isinstance(test_path, str)
            or not test_path.startswith("test/")
            or not (repo_root / test_path).is_file()
        ):
            errors.append(f"{label}.testPath must reference an existing test")
            continue
        test_text = _read_text(repo_root / test_path, errors)
        marker = f"educational-content-contract: {contract_id}"
        if marker not in test_text or "educational_content.v1.json" not in test_text:
            errors.append(f"{label}.testPath does not execute its manifest contract")
        if contract.get("coverage") != "allManifestEntries":
            errors.append(f"{label}.coverage must be allManifestEntries")
        result[contract_id] = contract
    return result


def validate_repository(
    repo_root: Path, inventory_path: Path
) -> tuple[list[str], list[str]]:
    """Return structural errors and separate final-certification blockers."""

    errors: list[str] = []
    blockers: list[str] = []
    inventory = _read_json(inventory_path, errors)
    if inventory is None:
        return errors, blockers
    if inventory.get("schemaVersion") != 1:
        errors.append("schemaVersion must be 1")
    if inventory.get("formalPayloadDigestContracts") != {
        "assetBacked": "canonicalJsonWithoutLocalizedMetadataV1",
        "codeBacked": "canonicalRuntimeJsonV1",
        "pumpingExercise": "pumpingLanguageConstraintsAnswersV1",
        "instructionReference": "localeNeutralContentReferenceV1",
    }:
        errors.append("formalPayloadDigestContracts is missing or unsupported")
    profiles = inventory.get("profiles")
    if not isinstance(profiles, dict) or not profiles:
        errors.append("profiles must be a non-empty object")
        profiles = {}
    for name, profile in profiles.items():
        _validate_profile(repo_root, name, profile, errors)

    evidence_contracts = _evidence_contracts(repo_root, inventory, errors)

    sources = inventory.get("sources")
    if isinstance(sources, dict) and "exampleSuggestedSimulations" not in sources:
        errors.append("sources.exampleSuggestedSimulations must be declared")
    if isinstance(sources, dict):
        terminology = sources.get("terminology")
        if not isinstance(terminology, dict):
            errors.append("sources.terminology must be declared")
        else:
            terminology_paths = {
                "catalog": terminology.get("catalog"),
                "styleGuide": terminology.get("styleGuide"),
                "maintainerGuide": terminology.get("maintainerGuide"),
            }
            for name, relative in terminology_paths.items():
                if (
                    not isinstance(relative, str)
                    or not (repo_root / relative).is_file()
                ):
                    errors.append(
                        f"sources.terminology.{name} must reference an existing file"
                    )
            if all(isinstance(path, str) for path in terminology_paths.values()):
                catalog = str(terminology_paths["catalog"])
                style_guide = str(terminology_paths["styleGuide"])
                maintainer_guide = str(terminology_paths["maintainerGuide"])
                style_text = _read_text(repo_root / style_guide, errors)
                maintainer_text = _read_text(repo_root / maintainer_guide, errors)
                catalog_name = Path(catalog).name
                style_name = Path(style_guide).name
                if (
                    catalog_name not in style_text
                    or catalog_name not in maintainer_text
                ):
                    errors.append(
                        "terminology catalog must be referenced by both localization guides"
                    )
                if style_name not in maintainer_text:
                    errors.append(
                        "educational-content guide must reference the terminology style guide"
                    )
    source_records = _source_inventory(repo_root, inventory, errors)
    entries = inventory.get("entries")
    if not isinstance(entries, list):
        errors.append("entries must be a list")
        entries = []
    manifest_ids: list[str] = []
    entry_keys: list[tuple[str, str]] = []
    for index, entry in enumerate(entries):
        label = f"entries[{index}]"
        if not isinstance(entry, dict):
            errors.append(f"{label} must be an object")
            continue
        manifest_id = entry.get("manifestId")
        content_id = entry.get("contentId")
        kind = entry.get("kind")
        profile_name = entry.get("profile")
        if not isinstance(manifest_id, str) or not manifest_id:
            errors.append(f"{label}.manifestId must be a non-empty string")
        else:
            manifest_ids.append(manifest_id)
        if not isinstance(content_id, str) or not content_id:
            errors.append(f"{label}.contentId must be a non-empty string")
            continue
        if STABLE_CONTENT_ID_PATTERN.fullmatch(content_id) is None:
            errors.append(
                f"{label}.contentId is not a stable locale-neutral identifier: "
                f"{content_id!r}"
            )
        if not isinstance(kind, str) or not kind:
            errors.append(f"{label}.kind must be a non-empty string")
            continue
        key = (kind, content_id)
        entry_keys.append(key)
        expected_manifest_id = f"{kind}/{content_id}"
        if manifest_id != expected_manifest_id:
            errors.append(
                f"{label}.manifestId must be {expected_manifest_id!r}, "
                f"found {manifest_id!r}"
            )
        if profile_name not in profiles:
            errors.append(f"{label} references unknown profile: {profile_name!r}")
            profile = None
        else:
            profile = profiles[profile_name]
        source_record = source_records.get(key)
        if source_record is None:
            errors.append(f"{label} does not match a shipped source id: {kind}/{content_id}")
        else:
            source_paths = _string_list(entry.get("sourcePaths"), f"{label}.sourcePaths", errors)
            if len(source_paths) != len(set(source_paths)):
                errors.append(f"{label}.sourcePaths contains duplicates")
            if set(source_paths) != set(source_record["sourcePaths"]):
                errors.append(f"{label}.sourcePaths drift from the shipped source")
            legacy_lookup_key = source_record.get("legacyLookupKey")
            if legacy_lookup_key is not None:
                if entry.get("legacyLookupKey") != legacy_lookup_key:
                    errors.append(f"{label}.legacyLookupKey drifted")
            elif "legacyLookupKey" in entry:
                errors.append(f"{label}.legacyLookupKey is not used by this source")
            digest = source_record.get("formalPayloadSha256")
            if digest is not None and entry.get("formalPayloadSha256") != digest:
                errors.append(f"{label}.formalPayloadSha256 drifted")
            content_version = source_record.get("contentVersion")
            if (
                content_version is not None
                and isinstance(profile, dict)
                and profile.get("contentVersion") != content_version
            ):
                errors.append(f"{label}.profile contentVersion drifted")
        evidence_paths = _string_list(
            entry.get("evidenceTests"), f"{label}.evidenceTests", errors
        )
        for relative in evidence_paths:
            if not relative.startswith("test/") or not (repo_root / relative).is_file():
                errors.append(f"{label} references missing evidence test: {relative}")
        contract_paths = {
            contract["testPath"] for contract in evidence_contracts.values()
        }
        if not contract_paths.intersection(evidence_paths):
            errors.append(f"{label} is not linked to an executable evidence contract")
        if isinstance(profile, dict) and profile.get("shippingStatus") == "shipped":
            locale_status = profile.get("localeStatus", {})
            if locale_status.get("en") != "reviewed":
                blockers.append(f"{manifest_id}: English content is not reviewed")
            if locale_status.get("pt") != "reviewed":
                blockers.append(f"{manifest_id}: Portuguese content is not reviewed")
            if profile.get("technicalReviewStatus") != "approved":
                blockers.append(f"{manifest_id}: technical review is not approved")
            if profile.get("editorialReviewStatus") != "approved":
                blockers.append(f"{manifest_id}: editorial review is not approved")
            accessibility_status = profile.get("accessibilityAlternativeStatus")
            if accessibility_status not in {
                "approved",
                "notApplicable",
            }:
                qualifier = (
                    "is not reviewed"
                    if accessibility_status == "presentUnreviewed"
                    else "is incomplete"
                )
                blockers.append(f"{manifest_id}: accessibility alternative {qualifier}")
            provenance = profile.get("provenance", {})
            if provenance.get("reviewStatus") != "approved":
                blockers.append(f"{manifest_id}: provenance review is not approved")

    for manifest_id, count in Counter(manifest_ids).items():
        if count > 1:
            errors.append(f"duplicate manifestId: {manifest_id}")
    for key, count in Counter(entry_keys).items():
        if count > 1:
            errors.append(f"duplicate content entry: {key[0]}/{key[1]}")
    manifest_key_set = set(entry_keys)
    for kind, content_id in sorted(source_records.keys() - manifest_key_set):
        errors.append(f"shipped source id is absent from manifest: {kind}/{content_id}")

    non_shipping = inventory.get("nonShippingEntries")
    if not isinstance(non_shipping, list):
        errors.append("nonShippingEntries must be a list")
    else:
        for index, entry in enumerate(non_shipping):
            label = f"nonShippingEntries[{index}]"
            if not isinstance(entry, dict):
                errors.append(f"{label} must be an object")
                continue
            if not all(
                isinstance(entry.get(field), str) and entry[field]
                for field in (
                    "contentId",
                    "kind",
                    "rationale",
                    "removedInVersion",
                )
            ):
                errors.append(
                    f"{label} needs contentId, kind, rationale, and removedInVersion"
                )
            if entry.get("ownerIssue") != 344:
                errors.append(f"{label}.ownerIssue must be #344")
            removal_evidence = _string_list(
                entry.get("removalEvidence"), f"{label}.removalEvidence", errors
            )
            if not removal_evidence:
                errors.append(f"{label}.removalEvidence must not be empty")
            for relative in removal_evidence:
                if not (repo_root / relative).is_file():
                    errors.append(f"{label} references missing removal evidence")
            key = (entry.get("kind"), entry.get("contentId"))
            if key in source_records or key in manifest_key_set:
                errors.append(f"{label} overlaps shipped/source-discovered content")

    pending_sources = inventory.get("sources", {}).get("pendingGapSources", [])
    pending_source_paths = set(
        _string_list(pending_sources, "sources.pendingGapSources", errors)
    )
    for relative in pending_source_paths:
        if not (repo_root / relative).is_file():
            errors.append(f"pending gap source does not exist: {relative}")
    covered_gap_paths: set[str] = set()
    gaps = inventory.get("pendingSourceGaps")
    if not isinstance(gaps, list):
        errors.append("pendingSourceGaps must be a list")
        gaps = []
    for index, gap in enumerate(gaps):
        label = f"pendingSourceGaps[{index}]"
        if not isinstance(gap, dict):
            errors.append(f"{label} must be an object")
            continue
        if (
            not isinstance(gap.get("gapId"), str)
            or STABLE_CONTENT_ID_PATTERN.fullmatch(gap["gapId"]) is None
        ):
            errors.append(f"{label}.gapId is invalid")
        if gap.get("ownerIssue") != 344 or gap.get("status") != "pending":
            errors.append(f"{label} must remain pending and owned by #344")
        if not isinstance(gap.get("rationale"), str) or not gap["rationale"]:
            errors.append(f"{label}.rationale is required")
        paths = set(_string_list(gap.get("sourcePaths"), f"{label}.sourcePaths", errors))
        covered_gap_paths.update(paths)
        blockers.append(f"pending source gap: {gap.get('gapId')}")
    if covered_gap_paths != pending_source_paths:
        errors.append("pendingSourceGaps do not exactly cover sources.pendingGapSources")
    return errors, blockers


def main(argv: list[str] | None = None) -> int:
    if hasattr(sys.stdout, "reconfigure"):
        sys.stdout.reconfigure(errors="backslashreplace")
    parser = argparse.ArgumentParser(description=__doc__)
    default_root = Path(__file__).resolve().parents[1]
    parser.add_argument("--repo-root", type=Path, default=default_root)
    parser.add_argument(
        "--inventory",
        type=Path,
        default=Path("docs/localization/educational_content.v1.json"),
    )
    parser.add_argument(
        "--certify",
        action="store_true",
        help="also fail when human review or accessibility work remains pending",
    )
    args = parser.parse_args(argv)
    repo_root = args.repo_root.resolve()
    inventory_path = args.inventory
    if not inventory_path.is_absolute():
        inventory_path = repo_root / inventory_path
    errors, blockers = validate_repository(repo_root, inventory_path)
    if errors:
        print(f"Educational content validation failed ({len(errors)} error(s)):")
        for error in errors:
            print(f"- {error}")
        return 1
    if args.certify and blockers:
        print(
            "Educational content is structurally valid but not ready for final "
            f"certification ({len(blockers)} blocker(s))."
        )
        displayed = blockers[:25]
        for blocker in displayed:
            print(f"- {blocker}")
        if len(blockers) > len(displayed):
            print(f"- ... {len(blockers) - len(displayed)} more blocker(s)")
        return 2
    print(
        "Educational content manifest is structurally valid; "
        f"final certification blockers: {len(blockers)}."
    )
    return 0


if __name__ == "__main__":
    sys.exit(main())
