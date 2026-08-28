#!/usr/bin/env python3
"""Fail-closed inventory and literal gate for structured domain messages."""

from __future__ import annotations

import argparse
import fnmatch
import hashlib
import json
import re
import sys
from collections import Counter, defaultdict
from dataclasses import dataclass, replace
from pathlib import Path
from typing import Any, Iterable


SCHEMA_VERSION = 1
DEFAULT_SCOPE = "tool/localization/domain_message_scope.v1.json"
DEFAULT_ALLOWLIST = "tool/localization/domain_message_allowlist.v1.json"
DEFAULT_INVENTORY = "docs/localization/domain_message_inventory.v1.json"
ALLOWED_CLASSIFICATIONS = {
    "legacyUserVisible",
    "legacyWorkflowAdapter",
    "supportedCompatibilityDescription",
    "developerDiagnostic",
    "protocolDescription",
}
WORD_PATTERN = re.compile(r"[A-Za-zÀ-ÖØ-öø-ÿ]{2,}")
SINK_PATTERN = re.compile(
    r"\b(errorMessage|message|description|title|subtitle|explanation|"
    r"bullet|bullets|label|details|reason|warning|hint|statusMessage)\s*[:=]\s*$",
    re.DOTALL,
)
LIST_SINK_PATTERN = re.compile(
    r"\b(bullets|messages|warnings|errors|reasons|hints)\s*:\s*"
    r"(?:const\s*)?\[[^\]]*$",
    re.DOTALL,
)
POSITIONAL_PRODUCER_PATTERN = re.compile(
    r"\b(?:Result\.(?:failure|error)|Failure|Diagnostic|ValidationIssue|"
    r"Warning|CodecMalformed|CodecUnsupported|StepExplanation)\s*\([^;]*$",
    re.DOTALL,
)
DEVELOPER_CONTEXT_PATTERN = re.compile(
    r"\b(debugPrint|log|logger|assert|ArgumentError|StateError|FormatException|"
    r"UnsupportedError|Exception)\s*\(",
)


@dataclass(frozen=True)
class RawLiteral:
    line: int
    column: int
    literal: str
    context: str
    is_directive: bool
    declaration_context: str = ""


@dataclass(frozen=True)
class Finding:
    path: str
    line: int
    column: int
    literal: str
    occurrence: int
    surface: str
    detected_classification: str
    classification: str
    rationale: str
    allowlisted: bool

    @property
    def key(self) -> tuple[str, str, int]:
        return (self.path, self.literal, self.occurrence)

    @property
    def is_violation(self) -> bool:
        return not self.allowlisted

    def to_json(self) -> dict[str, Any]:
        return {
            "path": self.path,
            "line": self.line,
            "column": self.column,
            "literal": self.literal,
            "occurrence": self.occurrence,
            "surface": self.surface,
            "detectedClassification": self.detected_classification,
            "classification": self.classification,
            "allowlisted": self.allowlisted,
            "rationale": self.rationale,
        }


@dataclass(frozen=True)
class Allowance:
    path: str
    literal: str
    occurrence: int
    classification: str
    rationale: str
    owner: str
    target_namespace: str

    @property
    def key(self) -> tuple[str, str, int]:
        return (self.path, self.literal, self.occurrence)


def _line_and_column(source: str, offset: int) -> tuple[int, int]:
    line = source.count("\n", 0, offset) + 1
    line_start = source.rfind("\n", 0, offset)
    return line, offset - line_start


def _skip_line_comment(source: str, index: int) -> int:
    end = source.find("\n", index + 2)
    return len(source) if end == -1 else end


def _skip_block_comment(source: str, index: int) -> int:
    depth = 1
    cursor = index + 2
    while cursor < len(source) and depth:
        if source.startswith("/*", cursor):
            depth += 1
            cursor += 2
        elif source.startswith("*/", cursor):
            depth -= 1
            cursor += 2
        else:
            cursor += 1
    return cursor


def _string_start(source: str, index: int) -> tuple[int, str, bool] | None:
    raw = False
    quote_index = index
    if source[index : index + 1] in {"r", "R"}:
        if index > 0 and (source[index - 1].isalnum() or source[index - 1] == "_"):
            return None
        if source[index + 1 : index + 2] not in {"'", '"'}:
            return None
        raw = True
        quote_index += 1
    quote = source[quote_index : quote_index + 1]
    if quote not in {"'", '"'}:
        return None
    delimiter = quote * (3 if source.startswith(quote * 3, quote_index) else 1)
    return quote_index, delimiter, raw


def _skip_interpolation(source: str, index: int) -> int:
    depth = 1
    cursor = index
    while cursor < len(source) and depth:
        if source.startswith("//", cursor):
            cursor = _skip_line_comment(source, cursor)
            continue
        if source.startswith("/*", cursor):
            cursor = _skip_block_comment(source, cursor)
            continue
        string = _string_start(source, cursor)
        if string is not None:
            cursor, _, _ = _consume_string(source, cursor, include_literal=False)
            continue
        if source[cursor] == "{":
            depth += 1
        elif source[cursor] == "}":
            depth -= 1
        cursor += 1
    return cursor


def _consume_string(
    source: str, index: int, *, include_literal: bool = True
) -> tuple[int, str, tuple[int, int] | None]:
    start = _string_start(source, index)
    if start is None:
        raise ValueError("not a Dart string")
    quote_index, delimiter, raw = start
    body_start = quote_index + len(delimiter)
    cursor = body_start
    while cursor < len(source):
        if source.startswith(delimiter, cursor):
            body = source[body_start:cursor] if include_literal else ""
            return cursor + len(delimiter), body, (index, cursor + len(delimiter))
        if not raw and source[cursor] == "\\":
            cursor = min(cursor + 2, len(source))
            continue
        if not raw and source.startswith("${", cursor):
            cursor = _skip_interpolation(source, cursor + 2)
            continue
        cursor += 1
    body = source[body_start:]
    return len(source), body, (index, len(source))


def _statement_context(source: str, start: int, end: int) -> str:
    previous = max(
        source.rfind(";", max(0, start - 800), start),
        source.rfind("}", max(0, start - 800), start),
    )
    following = source.find(";", end, min(len(source), end + 800))
    if following == -1:
        following = min(len(source), end + 240)
    return source[previous + 1 : following + 1]


def extract_literals(source: str) -> list[RawLiteral]:
    literals: list[RawLiteral] = []
    cursor = 0
    while cursor < len(source):
        if source.startswith("//", cursor):
            cursor = _skip_line_comment(source, cursor)
            continue
        if source.startswith("/*", cursor):
            cursor = _skip_block_comment(source, cursor)
            continue
        start = _string_start(source, cursor)
        if start is None:
            cursor += 1
            continue
        end, literal, span = _consume_string(source, cursor)
        assert span is not None
        line, column = _line_and_column(source, span[0])
        line_start = source.rfind("\n", 0, span[0]) + 1
        line_prefix = source[line_start : span[0]]
        literals.append(
            RawLiteral(
                line=line,
                column=column,
                literal=literal,
                context=_statement_context(source, span[0], span[1]),
                declaration_context=source[max(0, span[0] - 2400) : span[0]],
                is_directive=(
                    ";" not in line_prefix
                    and re.match(r"\s*(?:import|export|part)\b", line_prefix)
                    is not None
                ),
            )
        )
        cursor = end
    return literals


def _plain_text(literal: str) -> str:
    value = re.sub(r"\$\{.*?\}", " value ", literal, flags=re.DOTALL)
    value = re.sub(r"\$[A-Za-z_][A-Za-z0-9_]*", " value ", value)
    return value.replace(r"\n", " ").replace("\n", " ")


def _without_leading_comments(source: str) -> str:
    cursor = 0
    while cursor < len(source):
        whitespace = re.match(r"\s*", source[cursor:])
        assert whitespace is not None
        cursor += whitespace.end()
        if source.startswith("//", cursor):
            cursor = _skip_line_comment(source, cursor)
            continue
        if source.startswith("/*", cursor):
            cursor = _skip_block_comment(source, cursor)
            continue
        break
    return source[cursor:]


def _sink_name(context: str, literal: str) -> str | None:
    marker = context.find(literal)
    prefix = context[:marker] if marker >= 0 else context
    prefix = _without_opening_delimiter(prefix)
    match = SINK_PATTERN.search(prefix[-240:])
    if match:
        return match.group(1)
    list_match = LIST_SINK_PATTERN.search(prefix[-240:])
    return list_match.group(1) if list_match else None


def _local_prefix(context: str, literal: str) -> str:
    marker = context.find(literal)
    prefix = context[:marker] if marker >= 0 else context
    return _without_opening_delimiter(prefix)[-320:]


def _without_opening_delimiter(prefix: str) -> str:
    trimmed = prefix.rstrip()
    for suffix in ("r'''", 'r"""', "R'''", 'R"""', "'''", '"""', "r'", 'r"', "R'", 'R"', "'", '"'):
        if trimmed.endswith(suffix):
            return trimmed[: -len(suffix)]
    return trimmed


def _is_candidate(literal: RawLiteral) -> bool:
    if literal.is_directive:
        return False
    context = _without_leading_comments(literal.context)
    if re.match(r"^(import|export|part)\b", context):
        return False
    plain = _plain_text(literal.literal)
    words = WORD_PATTERN.findall(plain)
    sink = _sink_name(literal.context, literal.literal)
    prefix = _local_prefix(literal.context, literal.literal)
    direct_developer_call = DEVELOPER_CONTEXT_PATTERN.search(prefix) is not None
    positional_producer = POSITIONAL_PRODUCER_PATTERN.search(prefix) is not None
    returned_message = bool(
        re.search(
            r"\b(?:message|description|explanation|reason|summary|warning|error)"
            r"\b[^;{}]{0,160}\breturn\s*$",
            prefix,
            re.DOTALL,
        )
    )
    if not words:
        return False
    if "://" in plain or re.fullmatch(r"[A-Za-z]:[\\/].*", plain.strip()):
        return False
    if re.fullmatch(r"[a-z][a-z0-9.-]*", plain.strip()):
        return False
    if re.fullmatch(r"[a-z][a-z0-9.-]*(?:/[a-z0-9.-]+)+", plain.strip()):
        return False
    if len(words) >= 2:
        return True
    return bool(sink or direct_developer_call or positional_producer or returned_message)


def _is_grammar_protocol_literal(path: str, literal: str) -> bool:
    exact_by_path = {
        "lib/core/grammar/dependency_graph/variable_dependency_graph.dart": {
            "vdg-e$index",
        },
        "lib/core/grammar/phrase_structure/legacy_context_free_grammar_adapter.dart": {
            "${production.id}:${production.leftSide.join('\\u001f')}:"
            "${production.isLambda ? '\\u0000' : production.rightSide.join('\\u001f')}",
        },
        "lib/core/grammar/phrase_structure/phrase_structure_production.dart": {
            "${left.stableKey}->${right.stableKey}",
        },
        "lib/core/grammar/phrase_structure/symbol_sequence.dart": {
            "${symbol.isTerminal ? 't' : 'n'}:${symbol.value.length}:${symbol.value}",
        },
        "lib/core/grammar/teaching/grammar_teaching_sessions.dart": {
            "normalization diagnostic",
            "normalization state",
            "normalization drafts",
            "normalization diagnostics",
            "normalization session",
            "ll:$nonTerminal:$lookahead",
            "lr:action:$state:$lookahead",
            "lr:goto:$state:$nonTerminal",
            "parse-table teaching state",
            "parse-table drafts",
            "parse-table teaching session",
            "cnf.start_symbol",
            "${production.leftSide.single} -> $right",
            "$left → ${right.isEmpty ? 'ε' : right.join(' ')}",
            "${entry.productionId}: ${entry.display}",
        },
    }
    return literal in exact_by_path.get(path, set())


def _is_formal_grammar_display(literal: RawLiteral) -> bool:
    prefix = _local_prefix(literal.context, literal.literal)
    if literal.literal == "$leftSide → ${rightSide.isEmpty ? 'ε' : rightSide.join(' ')}":
        return bool(re.search(r"\bString\s+get\s+display\s*=>\s*$", prefix))
    if literal.literal == "${entry.productionId} ${entry.display}":
        return bool(
            re.search(
                r"\bString\s+get\s+alternativesDisplay\s*=>\s*entries\s*"
                r"\.map\s*\(\s*\(\s*entry\s*\)\s*=>\s*$",
                prefix,
            )
        )
    if literal.literal in {"FIRST/FIRST", "FIRST/FOLLOW"}:
        return bool(
            re.search(
                r"\bString\s+get\s+formalKind\s*=>\s*switch\s*\(\s*kind\s*\)\s*"
                r"\{[\s\S]*=>\s*$",
                prefix,
            )
        )
    if (
        literal.literal
        == "$formalKind [$nonTerminal, $lookahead]: $alternativesDisplay"
    ):
        return bool(
            re.search(r"\bString\s+get\s+formalDescription\s*=>\s*$", prefix)
        )
    return False


def _is_batch_protocol_literal(path: str, literal: str) -> bool:
    if not path.startswith("lib/core/batch_execution/"):
        return False
    return literal in {
        "row-${(rowIndex + 1).toString().padLeft(6, '0')}",
        "generated-${serial.toString().padLeft(6, '0')}",
        "line-${(index + 1).toString().padLeft(6, '0')}",
        "modelId,modelRevision,strategyId,tokenizationMode,maxSteps,",
        "maxConfigurations,timeoutMicros,traceRetention,caseId,input,",
        "outcome,output,steps,configurations,elapsedMicros,diagnosticCode,",
        "tm.block.${result.diagnostics.first.code.name}",
        "grammar.brute.${result.diagnostic!.name}",
        "tm.${limit?.name ?? 'bounded-unknown'}",
        "grammar.${result.outcome.name}",
    }


def _is_pumping_protocol_literal(path: str, literal: str) -> bool:
    if path != "lib/core/pumping_lemma/pumping_lemma_problem.dart":
        return False
    return literal in {
        "L = {a^p | p is prime}",
        "L = {w in {a,b}* | w = reverse(w)}",
        "L = {ww | w in {a,b}*}",
        "L = {w in {a,b}* | w contains ab}",
        "L = {w in {a,b}* | w ends with a}",
        "L = {w#reverse(w) | w in {a,b}*}",
        "L = {well-balanced strings over ( and )}",
    }


def _is_l_system_protocol_literal(path: str, literal: str) -> bool:
    exact_by_path = {
        "lib/core/l_systems/l_system_export.dart": {
            "<polygon points=\"${points.join(' ')}\" fill=\"",
            "\" fill=\"none\" stroke=\"${_xml(segmentColor)}\" ",
            "stroke-width=\"${_number(geometry.segmentWidths[segment])}\" ",
            "stroke-linecap=\"round\" stroke-linejoin=\"round\"/>",
            "width=\"${_number(width)}\" height=\"${_number(height)}\" ",
            "viewBox=\"0 0 ${_number(width)} ${_number(height)}\">",
            "<metadata>${_xml(encodedMetadata)}</metadata>",
            " $name-opacity=\"${_number(alpha / 255)}\" ",
        },
        "lib/core/l_systems/l_system_model.dart": {
            "commandMapping.${entry.key}",
        },
        "lib/data/l_systems/l_system_examples.dart": {
            "Koch curve",
            "A four-segment replacement with 60 degree turns.",
            "Sierpiński triangle",
            "Mutually rewriting draw symbols form a triangle gasket.",
            "Dragon curve",
            "Two control symbols generate a right-angle dragon.",
            "Fractal plant",
            "Nested branches produce a compact botanical form.",
            "Branching tree",
            "Balanced push and pop commands create repeated branches.",
            "Seeded context turtle",
            "Seeded alternatives and a left/right context produce styled pitch and polygon commands.",
            "$id.${entry.key}",
        },
    }
    return literal in exact_by_path.get(path, set())


def _is_regex_simplification_protocol_literal(
    path: str, literal: RawLiteral
) -> bool:
    if path != "lib/core/algorithms/regex_simplifier_steps.dart":
        return False
    prefix = _local_prefix(literal.context, literal.literal)
    if literal.literal == "step_$stepNumber":
        return bool(re.search(r"\bid\s*:\s*$", prefix))
    if literal.literal == "$duplicateSegment|$duplicateSegment":
        return bool(re.search(r"\bmatchedSubexpression\s*:\s*$", prefix))
    return False


def _is_regex_to_nfa_protocol_literal(path: str, literal: RawLiteral) -> bool:
    if path != "lib/core/models/regex_to_nfa_step.dart":
        return False
    prefix = _local_prefix(literal.context, literal.literal)
    if literal.literal == "(${firstFragmentLabel ?? ''}|${secondFragmentLabel ?? ''})":
        return bool(re.search(r"'pattern'\s*:\s*_regexToNfaLiteral\s*\(\s*$", prefix))
    if literal.literal == "${transition.fromState.label} → ${transition.toState.label} ":
        return _inside_declaration(
            literal,
            re.compile(r"\bString\s+_transitionPlan\s*\([^)]*\)\s*\{"),
        )
    if literal.literal.startswith("${switch (type) {"):
        return bool(
            re.search(
                r"\bString\s+_regexToNfaStepCode\s*\([^)]*\)\s*=>\s*$",
                prefix,
            )
        )
    if literal.literal in {"Basic Symbol", "Kleene Star"}:
        return bool(
            re.search(
                r"\bString\s+get\s+legacyPropertyValue\s*=>\s*switch\s*"
                r"\(\s*this\s*\)\s*\{[\s\S]*=>\s*$",
                prefix,
            )
        )
    return False


def _is_fa_to_regex_protocol_literal(path: str, literal: RawLiteral) -> bool:
    if path != "lib/core/models/fa_to_regex_step.dart":
        return False
    if literal.literal != "${_faToRegexStepCode(stepType)}-explanation":
        return False
    prefix = _local_prefix(literal.context, literal.literal)
    return bool(
        re.search(
            r"\bfinal\s+explanationMessage\s*=\s*_faToRegexStepMessage\s*\(\s*$",
            prefix,
        )
    )


def _is_generated_identifier_protocol_literal(
    path: str, literal: RawLiteral
) -> bool:
    prefix = _local_prefix(literal.context, literal.literal)
    if (
        path == "lib/core/algorithms/state_renamer.dart"
        and literal.literal == "q$i"
    ):
        return bool(re.search(r"\blabel\s*:\s*$", prefix))
    if (
        path == "lib/core/formal_systems/conversion_capability.dart"
        and literal.literal == "${source.value}->${target.value}:${id.value}"
    ):
        return bool(re.search(r"\bString\s+get\s+stableKey\s*=>\s*$", prefix))
    if (
        path == "lib/core/algorithms/dfa_completer.dart"
        and literal.literal == "${base}_${suffix++}"
    ):
        return bool(re.search(r"\bcandidate\s*=\s*$", prefix))
    if (
        path == "lib/core/formal_systems/formal_system_ids.dart"
        and literal.literal == "${type.value}:${variant.value}"
    ):
        return bool(re.search(r"\bString\s+get\s+value\s*=>\s*$", prefix))
    if (
        path == "lib/core/constants/monospace_typography.dart"
        and literal.literal
        in {"DejaVu Sans Mono", "Courier New", "Roboto Mono"}
    ):
        return "kMonospaceFontFamilyFallback" in literal.declaration_context
    return False


def _brace_depth(source: str) -> int:
    depth = 0
    cursor = 0
    while cursor < len(source):
        if source.startswith("//", cursor):
            cursor = _skip_line_comment(source, cursor)
            continue
        if source.startswith("/*", cursor):
            cursor = _skip_block_comment(source, cursor)
            continue
        if _string_start(source, cursor) is not None:
            cursor, _, _ = _consume_string(source, cursor, include_literal=False)
            continue
        if source[cursor] == "{":
            depth += 1
        elif source[cursor] == "}":
            depth -= 1
        cursor += 1
    return depth


def _inside_declaration(literal: RawLiteral, signature: re.Pattern[str]) -> bool:
    matches = list(signature.finditer(literal.declaration_context))
    return bool(
        matches
        and _brace_depth(literal.declaration_context[matches[-1].start() :]) > 0
    )


def _is_internal_inspection_literal(path: str, literal: RawLiteral) -> bool:
    to_string_fragments = {
        "GrammarDiagnostic(code: $code, severity: $severity, message: $message, symbols: $symbols, productionIds: $productionIds)",
        "NFAPathNode(stepNumber: $stepNumber, currentState: $currentState, ",
        "remainingInput: $remainingInput, children: ${children.length}, ",
        "isAccepting: $isAccepting, isDeadEnd: $isDeadEnd)",
    }
    regex_to_string_fragments = {
        "RegexSimplificationStep(stepNumber: ${baseStep.stepNumber}, ",
        "FAToRegexStep(stepNumber: ${baseStep.stepNumber}, ",
        "type: ${stepType.name}, title: ${baseStep.title})",
    }
    if (
        literal.literal in to_string_fragments
        or (
            path
            in {
                "lib/core/models/regex_simplification_step.dart",
                "lib/core/models/fa_to_regex_step.dart",
            }
            and literal.literal in regex_to_string_fragments
        )
    ) and _inside_declaration(
        literal,
        re.compile(r"\bString\s+toString\s*\(\s*\)\s*\{"),
    ):
        return True
    return bool(
        _inside_declaration(
            literal,
            re.compile(
                r"\bList\s*<\s*String\s*>\s+validateStructure\s*"
                r"\(\s*\)\s*\{"
            ),
        )
        and re.search(r"\bmessages\.add\s*\(", literal.context)
    )


def _is_argument_error_detail(literal: RawLiteral) -> bool:
    return bool(
        literal.literal
        in {
            "Duplicate node identity",
            "Duplicate branch identity",
            "No payload of type $T found on algorithm step ${baseStep.id}",
        }
        and re.search(r"\bArgumentError\.value\s*\(", literal.context)
    )


def _is_formal_span_literal(literal: RawLiteral) -> bool:
    return bool(
        re.fullmatch(
            r"\[\$[A-Za-z_][A-Za-z0-9_]*,\$[A-Za-z_][A-Za-z0-9_]*\)",
            literal.literal,
        )
        and _inside_declaration(
            literal,
            re.compile(r"\bString\s+prettyPrint\s*\([^)]*\)\s*\{"),
        )
        and re.search(r"\bbuf\.write\s*\(", literal.context)
    )


def _detected_classification(path: str, literal: RawLiteral) -> str:
    context = literal.context
    plain = _plain_text(literal.literal).strip()
    if (
        path == "lib/core/algorithms/grammar_analyzer.dart"
        and literal.literal
        == "Use removeLeftRecursion, which also handles indirect cycles."
    ):
        return "developerDiagnostic"
    if (path, literal.literal) in {
        (
            "lib/core/grammar/dependency_graph/variable_dependency_graph.dart",
            "Left-corner modes are defined only for context-free grammars.",
        ),
        (
            "lib/core/models/regex_to_nfa_step.dart",
            "must not be empty",
        ),
        (
            "lib/core/grammar/phrase_structure/user_derivation_session.dart",
            "A challenge must enforce a concrete occurrence mode.",
        ),
    }:
        return "developerDiagnostic"
    if path.startswith("lib/core/batch_execution/") and literal.literal in {
        "Batch request validation failed.",
        "Batch input file is invalid.",
        "must be positive",
        "must be non-negative",
    }:
        return "developerDiagnostic"
    if (
        path == "lib/core/l_systems/l_system_expander.dart"
        and literal.literal == "Must be positive."
    ):
        return "developerDiagnostic"
    if "localizeWorkflowText(" in context:
        return "legacyWorkflowAdapter"
    if DEVELOPER_CONTEXT_PATTERN.search(context):
        return "developerDiagnostic"
    if _is_argument_error_detail(literal):
        return "developerDiagnostic"
    if _is_internal_inspection_literal(path, literal):
        return "developerDiagnostic"
    if _is_formal_span_literal(literal):
        return "protocolDescription"
    if _is_formal_grammar_display(literal):
        return "protocolDescription"
    if _is_grammar_protocol_literal(path, literal.literal):
        return "protocolDescription"
    if _is_batch_protocol_literal(path, literal.literal):
        return "protocolDescription"
    if _is_pumping_protocol_literal(path, literal.literal):
        return "protocolDescription"
    if _is_l_system_protocol_literal(path, literal.literal):
        return "protocolDescription"
    if _is_regex_simplification_protocol_literal(path, literal):
        return "protocolDescription"
    if _is_regex_to_nfa_protocol_literal(path, literal):
        return "protocolDescription"
    if _is_fa_to_regex_protocol_literal(path, literal):
        return "protocolDescription"
    if _is_generated_identifier_protocol_literal(path, literal):
        return "protocolDescription"
    if "/transducers/" in f"/{path}" and (
        re.fullmatch(r"assets/examples/[a-z0-9._-]+\.json", plain)
        or re.fullmatch(r"asset/[a-z0-9._-]+", plain)
    ):
        return "protocolDescription"
    if path == "lib/core/interoperability/document_interoperability_registry.dart" and literal.literal in {
        "${limits.maximumDepth}|${limits.maximumElements}|",
        "${owner.key.value}|${descriptor.formatId.value}|",
        "${descriptor.schemas.minimum}-${descriptor.schemas.maximum}|",
        "${directions.join(',')}|${descriptor.priority}",
    }:
        return "protocolDescription"
    if path in {
        "lib/core/parsers/grammar_xml_codec.dart",
        "lib/core/parsers/jflap_xml_codec.dart",
    } and (
        plain == 'version="1.0" encoding="UTF-8"'
        or re.fullmatch(
            r"imported(?:_grammar)?_\$\{[^}]+\}", literal.literal
        )
        or literal.literal == "$rawFrom|$symbol"
    ):
        return "protocolDescription"
    if path == "lib/data/services/active_session_persistence_service.dart" and (
        literal.literal
        in {
            "active_editor_session",
            "settings_auto_save",
            "${sessionKey}_unsupported_v$version",
            "${sessionKey}_unsupported_${key.type.value}_${key.variant.value}_v$version",
            "backup_unsupported_version",
            "backup_unsupported_schema",
        }
    ):
        return "protocolDescription"
    if path == "lib/data/services/active_session_snapshot_codec.dart" and (
        literal.literal
        in {
            "Active session document envelope must be an object",
            "Active session document data must be an object",
            "Active session annotation collection must be an object",
        }
    ):
        return "developerDiagnostic"
    if plain == "image/svg+xml":
        return "protocolDescription"
    if path == "lib/data/services/file_operations_service_io.dart" and (
        literal.literal
        in {
            "operation not permitted",
            "permission denied",
            "access is denied",
            "not permitted",
            "no such file",
            "cannot find the path",
            "does not exist",
            "${baseName}_$timestamp.$extension",
            "${directory.path}/$fileName",
        }
    ):
        return "protocolDescription"
    if path == "lib/data/services/file_operations_payload_mixin.dart" and (
        literal.literal
        in {
            "codec.unsupported.${reason.name}",
            "codec.malformed.${reason.name}",
            "codec.resource-limit.${limit.name}",
            "codec.internal.${stage.name}",
        }
    ):
        return "protocolDescription"
    if path == "lib/core/services/tm_block_project_editor.dart" and (
        literal.literal
        in {
            "$newId:${invocation.id}",
            "$base#$suffix",
            "$newId:machine",
        }
    ):
        return "protocolDescription"
    if path == "lib/data/services/grammar_teaching_session_store.dart" and (
        literal.literal
        in {
            "grammar_teaching_session.v1",
            "parse.${session.kind.name}",
            "$_prefix.$kind.$grammarId.$revision",
        }
    ):
        return "protocolDescription"
    if path == "lib/data/services/manual_conversion_session_store.dart" and (
        literal.literal
        in {
            "manual_conversion_session.",
            "$keyPrefix$workspaceKey",
        }
    ):
        return "protocolDescription"
    if path == "lib/data/services/trace_persistence_service.dart" and (
        literal.literal
        in {
            "trace_history",
            "current_trace",
            "trace_metadata",
            "simulation_trace_history",
            "current_simulation_trace",
        }
    ):
        return "protocolDescription"
    if any(part in path for part in ("example", "catalog", "asset")):
        return "legacyUserVisible"
    if _sink_name(context, literal.literal) is not None:
        return "legacyUserVisible"
    if any(token in context for token in ("RegExp(", "schema", "protocol")):
        return "protocolDescription"
    return "legacyUserVisible"


def _surface(literal: RawLiteral) -> str:
    sink = _sink_name(literal.context, literal.literal)
    if sink is not None:
        return sink
    context = literal.context
    if "localizeWorkflowText(" in context:
        return "localizeWorkflowText"
    prefix = _local_prefix(context, literal.literal)
    if DEVELOPER_CONTEXT_PATTERN.search(prefix):
        return "developerDiagnostic"
    if POSITIONAL_PRODUCER_PATTERN.search(prefix):
        return "positionalProducer"
    return "returnedMessage"


def scan_source(path: str, source: str) -> list[Finding]:
    normalized_path = path.replace("\\", "/")
    counts: Counter[str] = Counter()
    findings: list[Finding] = []
    for literal in extract_literals(source):
        raw_grammar_error_code = bool(
            "/grammar/" in f"/{normalized_path}"
            and re.fullmatch(
                r"grammar\.[a-z0-9.-]+", _plain_text(literal.literal).strip()
            )
            and DEVELOPER_CONTEXT_PATTERN.search(literal.context)
        )
        if not _is_candidate(literal) and not raw_grammar_error_code:
            continue
        counts[literal.literal] += 1
        classification = _detected_classification(normalized_path, literal)
        findings.append(
            Finding(
                path=normalized_path,
                line=literal.line,
                column=literal.column,
                literal=literal.literal,
                occurrence=counts[literal.literal],
                surface=_surface(literal),
                detected_classification=classification,
                classification="unapprovedUserVisible",
                rationale="No exact domain-message allowlist entry.",
                allowlisted=False,
            )
        )
    return findings


def _read_object(path: Path, errors: list[str]) -> dict[str, Any] | None:
    try:
        value = json.loads(path.read_text(encoding="utf-8"))
    except (FileNotFoundError, OSError, UnicodeError, json.JSONDecodeError) as error:
        errors.append(f"cannot read {path}: {error}")
        return None
    if not isinstance(value, dict):
        errors.append(f"JSON root must be an object: {path}")
        return None
    return value


def _load_scope(root: Path, path: Path, errors: list[str]) -> list[str]:
    document = _read_object(path, errors)
    if document is None:
        return []
    roots = document.get("roots")
    exclusions = document.get("exclude", [])
    if document.get("schemaVersion") != SCHEMA_VERSION:
        errors.append(f"unsupported scope schema: {path}")
    if not isinstance(roots, list) or not roots or not all(isinstance(v, str) for v in roots):
        errors.append("scope roots must be a non-empty string list")
        return []
    if not isinstance(exclusions, list) or not all(isinstance(v, str) for v in exclusions):
        errors.append("scope exclude must be a string list")
        return []
    files: set[str] = set()
    for relative in roots:
        scoped = root / relative
        if not scoped.exists():
            errors.append(f"scoped path is missing: {relative}")
            continue
        candidates = [scoped] if scoped.is_file() else scoped.rglob("*.dart")
        for candidate in candidates:
            path_value = candidate.relative_to(root).as_posix()
            if any(fnmatch.fnmatch(path_value, pattern) for pattern in exclusions):
                continue
            files.add(path_value)
    if not files:
        errors.append("scope discovered no Dart source files")
    return sorted(files)


def _load_allowlist(path: Path, errors: list[str]) -> dict[tuple[str, str, int], Allowance]:
    document = _read_object(path, errors)
    if document is None:
        return {}
    if document.get("schemaVersion") != SCHEMA_VERSION:
        errors.append(f"unsupported allowlist schema: {path}")
    entries = document.get("entries")
    if not isinstance(entries, list):
        errors.append("allowlist entries must be a list")
        return {}
    result: dict[tuple[str, str, int], Allowance] = {}
    for index, raw in enumerate(entries):
        if not isinstance(raw, dict):
            errors.append(f"allowlist entry {index} must be an object")
            continue
        try:
            allowance = Allowance(
                path=raw["path"],
                literal=raw["literal"],
                occurrence=raw["occurrence"],
                classification=raw["classification"],
                rationale=raw["rationale"],
                owner=raw["owner"],
                target_namespace=raw["targetNamespace"],
            )
        except KeyError as error:
            errors.append(f"allowlist entry {index} misses {error.args[0]}")
            continue
        if (
            not isinstance(allowance.path, str)
            or not isinstance(allowance.literal, str)
            or not isinstance(allowance.occurrence, int)
            or allowance.occurrence < 1
            or allowance.classification not in ALLOWED_CLASSIFICATIONS
            or not isinstance(allowance.rationale, str)
            or len(allowance.rationale.strip()) < 20
            or not isinstance(allowance.owner, str)
            or not allowance.owner
            or not isinstance(allowance.target_namespace, str)
            or not re.fullmatch(r"[a-z][a-z0-9.-]*", allowance.target_namespace)
        ):
            errors.append(f"malformed allowlist entry {index}")
            continue
        if allowance.classification == "supportedCompatibilityDescription" and not (
            "StructuredMessage" in allowance.rationale
            and re.search(r"\bresolver\b", allowance.rationale, re.IGNORECASE)
        ):
            errors.append(
                f"supported compatibility entry {index} must identify the "
                "StructuredMessage resolver used by the UI"
            )
            continue
        if allowance.key in result:
            errors.append(f"duplicate allowlist occurrence: {allowance.key}")
            continue
        _, expected_namespace, expected_owner = _family(allowance.path)
        if (
            allowance.target_namespace != expected_namespace
            or allowance.owner != expected_owner
        ):
            errors.append(
                f"allowlist ownership drift for {allowance.key}: expected "
                f"owner={expected_owner}, namespace={expected_namespace}"
            )
            continue
        result[allowance.key] = allowance
    return result


def apply_allowlist(
    findings: Iterable[Finding], allowances: dict[tuple[str, str, int], Allowance]
) -> tuple[list[Finding], list[tuple[str, str, int]]]:
    matched: set[tuple[str, str, int]] = set()
    classified: list[Finding] = []
    for finding in findings:
        allowance = allowances.get(finding.key)
        if allowance is None:
            classified.append(finding)
            continue
        matched.add(finding.key)
        classification_matches = (
            allowance.classification == finding.detected_classification
            or (
                allowance.classification == "supportedCompatibilityDescription"
                and finding.detected_classification == "legacyUserVisible"
            )
        )
        if not classification_matches:
            classified.append(
                replace(
                    finding,
                    rationale=(
                        "Allowlist classification drift: expected "
                        f"{allowance.classification}, detected "
                        f"{finding.detected_classification}."
                    ),
                )
            )
            continue
        classified.append(
            replace(
                finding,
                classification=allowance.classification,
                rationale=allowance.rationale,
                allowlisted=True,
            )
        )
    return classified, sorted(set(allowances) - matched)


def _family(path: str) -> tuple[str, str, str]:
    mappings = (
        ("/algorithms/", "algorithms", "algorithm", "core-algorithms"),
        ("/grammar/", "grammar", "grammar", "grammar-and-parsing"),
        ("/parsers/", "parsers", "parser", "grammar-and-parsing"),
        ("/validators/", "validation", "validation", "domain-validation"),
        ("/interoperability/", "interoperability", "interop", "interoperability"),
        ("/codecs/", "codecs", "codec", "interoperability"),
        ("/transducers/", "transducers", "transducer", "transducers"),
        ("/l_systems/", "l-systems", "l-system", "formal-systems"),
        ("/pumping_lemma/", "pumping-lemma", "pumping", "formal-systems"),
        ("/batch_execution/", "batch", "batch", "simulation-runtime"),
        ("/services/", "services", "service", "domain-services"),
        ("/models/", "models", "model", "domain-models"),
    )
    normalized = f"/{path}"
    for marker, family, namespace, owner in mappings:
        if marker in normalized:
            return family, namespace, owner
    return "domain-support", "domain", "domain-core-data"


def build_inventory(findings: Iterable[Finding]) -> dict[str, Any]:
    by_family: dict[str, dict[str, list[Finding]]] = defaultdict(lambda: defaultdict(list))
    metadata: dict[str, tuple[str, str]] = {}
    all_findings = sorted(findings, key=lambda item: (item.path, item.line, item.column))
    for finding in all_findings:
        family, namespace, owner = _family(finding.path)
        metadata[family] = (namespace, owner)
        by_family[family][finding.path].append(finding)
    families: list[dict[str, Any]] = []
    for family in sorted(by_family):
        namespace, owner = metadata[family]
        producers: list[dict[str, Any]] = []
        family_requires_migration = False
        family_has_compatibility_descriptions = False
        for path in sorted(by_family[family]):
            occurrences = by_family[family][path]
            counts = Counter(item.classification for item in occurrences)
            surfaces = Counter(item.surface for item in occurrences)
            requires_migration = any(
                item.classification in {"legacyUserVisible", "legacyWorkflowAdapter"}
                or item.is_violation
                for item in occurrences
            )
            has_compatibility_descriptions = any(
                item.classification == "supportedCompatibilityDescription"
                for item in occurrences
            )
            family_requires_migration |= requires_migration
            family_has_compatibility_descriptions |= has_compatibility_descriptions
            producer_digest = hashlib.sha256(
                "\n".join(
                    f"{item.line}:{item.column}:{item.literal}:{item.surface}:"
                    f"{item.classification}"
                    for item in occurrences
                ).encode("utf-8")
            ).hexdigest()
            producers.append(
                {
                    "path": path,
                    "owner": owner,
                    "targetNamespace": namespace,
                    "status": (
                        "migration-required"
                        if requires_migration
                        else (
                            "structured-compatibility"
                            if has_compatibility_descriptions
                            else "allowlisted-non-ui"
                        )
                    ),
                    "occurrenceCount": len(occurrences),
                    "firstLine": min(item.line for item in occurrences),
                    "lastLine": max(item.line for item in occurrences),
                    "sourceDigestSha256": producer_digest,
                    "classificationCounts": dict(sorted(counts.items())),
                    "surfaces": dict(sorted(surfaces.items())),
                }
            )
        families.append(
            {
                "id": family,
                "owner": owner,
                "targetNamespace": namespace,
                "status": (
                    "migration-required"
                    if family_requires_migration
                    else (
                        "structured-compatibility"
                        if family_has_compatibility_descriptions
                        else "allowlisted-non-ui"
                    )
                ),
                "producers": producers,
            }
        )
    migration_required_count = sum(
        item.classification in {"legacyUserVisible", "legacyWorkflowAdapter"}
        or item.is_violation
        for item in all_findings
    )
    compatibility_description_count = sum(
        item.classification == "supportedCompatibilityDescription"
        for item in all_findings
    )
    source_digest = hashlib.sha256(
        "\n".join(
            f"{item.path}:{item.line}:{item.column}:{item.literal}:"
            f"{item.surface}:{item.classification}"
            for item in all_findings
        ).encode("utf-8")
    ).hexdigest()
    return {
        "schemaVersion": SCHEMA_VERSION,
        "ownerIssue": 210,
        "status": (
            "migration-in-progress"
            if migration_required_count
            else (
                "structured-with-compatibility-descriptions"
                if compatibility_description_count
                else "no-legacy-prose"
            )
        ),
        "zeroUserVisibleProseClaim": migration_required_count == 0,
        "sourceDigestSha256": source_digest,
        "summary": {
            "familyCount": len(families),
            "producerCount": sum(len(value) for value in by_family.values()),
            "occurrenceCount": len(all_findings),
            "migrationRequiredCount": migration_required_count,
            "compatibilityDescriptionCount": compatibility_description_count,
        },
        "families": families,
    }


def _bootstrap_allowlist(findings: Iterable[Finding]) -> dict[str, Any]:
    entries: list[dict[str, Any]] = []
    for finding in sorted(findings, key=lambda item: (item.path, item.line, item.column)):
        _, namespace, owner = _family(finding.path)
        classification = finding.detected_classification
        if classification == "developerDiagnostic":
            rationale = (
                "Existing developer-only diagnostic; explicitly bounded while #210 "
                "keeps the core/data prose gate fail-closed."
            )
        else:
            rationale = (
                f"Existing domain prose tracked by #210 for migration to the "
                f"{namespace} structured-message namespace."
            )
        entries.append(
            {
                "path": finding.path,
                "literal": finding.literal,
                "occurrence": finding.occurrence,
                "classification": classification,
                "rationale": rationale,
                "owner": owner,
                "targetNamespace": namespace,
            }
        )
    return {"schemaVersion": SCHEMA_VERSION, "ownerIssue": 210, "entries": entries}


def validate_repository(
    root: Path,
    scope_path: Path,
    allowlist_path: Path,
    inventory_path: Path,
) -> tuple[dict[str, Any], list[str]]:
    errors: list[str] = []
    files = _load_scope(root, scope_path, errors)
    allowances = _load_allowlist(allowlist_path, errors)
    raw_findings: list[Finding] = []
    for path in files:
        try:
            source = (root / path).read_text(encoding="utf-8")
        except (OSError, UnicodeError) as error:
            errors.append(f"cannot read scoped source {path}: {error}")
            continue
        raw_findings.extend(scan_source(path, source))
    findings, stale_allowances = apply_allowlist(raw_findings, allowances)
    for key in stale_allowances:
        errors.append(f"stale allowlist occurrence: {key}")
    for finding in findings:
        if finding.is_violation:
            errors.append(
                f"{finding.path}:{finding.line}:{finding.column}: "
                f"unapproved domain prose: {finding.literal!r}"
            )
    inventory = build_inventory(findings)
    migration_required_count = inventory["summary"]["migrationRequiredCount"]
    if migration_required_count:
        errors.append(
            "domain-message migration is incomplete: "
            f"{migration_required_count} legacy, transitional, or unapproved "
            "user-visible occurrences remain"
        )
    expected = _read_object(inventory_path, errors)
    if expected is not None and expected != inventory:
        errors.append(
            f"domain-message inventory is stale: {inventory_path.relative_to(root)}"
        )
    report = {
        "schemaVersion": SCHEMA_VERSION,
        "filesScanned": len(files),
        "findingCount": len(findings),
        "violationCount": sum(item.is_violation for item in findings),
        "staleAllowanceCount": len(stale_allowances),
        "inventoryStatus": inventory["status"],
        "zeroUserVisibleProseClaim": inventory["zeroUserVisibleProseClaim"],
        "migrationRequiredCount": migration_required_count,
        "compatibilityDescriptionCount": inventory["summary"][
            "compatibilityDescriptionCount"
        ],
        "findings": [item.to_json() for item in findings],
    }
    return report, errors


def _relative(root: Path, value: str) -> Path:
    path = Path(value)
    return path if path.is_absolute() else root / path


def _emit_json(value: object) -> None:
    sys.stdout.buffer.write(
        (json.dumps(value, indent=2, ensure_ascii=False) + "\n").encode("utf-8")
    )


def _emit_allowlist(value: dict[str, Any]) -> None:
    entries = value["entries"]
    lines = [
        "{",
        f'  "schemaVersion": {value["schemaVersion"]},',
        f'  "ownerIssue": {value["ownerIssue"]},',
        '  "entries": [',
    ]
    for index, entry in enumerate(entries):
        suffix = "," if index + 1 < len(entries) else ""
        lines.append(
            "    "
            + json.dumps(entry, ensure_ascii=False, separators=(", ", ": "))
            + suffix
        )
    lines.extend(["  ]", "}"])
    sys.stdout.buffer.write(("\n".join(lines) + "\n").encode("utf-8"))


def main(arguments: list[str] | None = None) -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--root", default=".")
    parser.add_argument("--scope", default=DEFAULT_SCOPE)
    parser.add_argument("--allowlist", default=DEFAULT_ALLOWLIST)
    parser.add_argument("--inventory", default=DEFAULT_INVENTORY)
    parser.add_argument("--json", action="store_true", help="Print the scan report.")
    parser.add_argument("--print-inventory", action="store_true")
    parser.add_argument("--print-allowlist-bootstrap", action="store_true")
    options = parser.parse_args(arguments)
    root = Path(options.root).resolve()
    scope_path = _relative(root, options.scope)
    allowlist_path = _relative(root, options.allowlist)
    inventory_path = _relative(root, options.inventory)

    if options.print_allowlist_bootstrap:
        errors: list[str] = []
        files = _load_scope(root, scope_path, errors)
        findings = [
            finding
            for path in files
            for finding in scan_source(path, (root / path).read_text(encoding="utf-8"))
        ]
        if errors:
            print("\n".join(errors), file=sys.stderr)
            return 2
        _emit_allowlist(_bootstrap_allowlist(findings))
        return 0

    if options.print_inventory:
        errors: list[str] = []
        files = _load_scope(root, scope_path, errors)
        allowances = _load_allowlist(allowlist_path, errors)
        findings = [
            finding
            for path in files
            for finding in scan_source(path, (root / path).read_text(encoding="utf-8"))
        ]
        classified, stale = apply_allowlist(findings, allowances)
        errors.extend(f"stale allowlist occurrence: {key}" for key in stale)
        if errors or any(item.is_violation for item in classified):
            print("\n".join(errors), file=sys.stderr)
            return 1
        _emit_json(build_inventory(classified))
        return 0

    report, errors = validate_repository(root, scope_path, allowlist_path, inventory_path)
    if options.json:
        _emit_json(report)
    elif not errors:
        print(
            "Domain-message prose inventory is current: "
            f"{report['filesScanned']} files, {report['findingCount']} "
            "allowlisted occurrences, 0 migration-required occurrences, "
            f"{report['compatibilityDescriptionCount']} supported compatibility "
            "descriptions."
        )
    for error in errors:
        print(error, file=sys.stderr)
    return 1 if errors else 0


if __name__ == "__main__":
    raise SystemExit(main())
