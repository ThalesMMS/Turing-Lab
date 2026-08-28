from __future__ import annotations

import importlib.util
import json
import sys
import tempfile
import unittest
from pathlib import Path


REPO_ROOT = Path(__file__).resolve().parents[2]
MODULE_PATH = REPO_ROOT / "tool" / "check_domain_message_prose.py"
SPEC = importlib.util.spec_from_file_location("check_domain_message_prose", MODULE_PATH)
assert SPEC is not None and SPEC.loader is not None
CHECKER = importlib.util.module_from_spec(SPEC)
sys.modules[SPEC.name] = CHECKER
SPEC.loader.exec_module(CHECKER)
FIXTURE_ROOT = REPO_ROOT / "test" / "fixtures" / "domain_message_prose"


class DomainMessageProseScannerTest(unittest.TestCase):
    def test_classifies_file_operation_compatibility_codes_as_protocol(self) -> None:
        source = """
Failure('codec.unsupported.${reason.name}');
Failure('codec.malformed.${reason.name}');
return 'codec.resource-limit.${limit.name}';
return 'codec.internal.${stage.name}';
Failure('The document could not be decoded.');
"""

        findings = CHECKER.scan_source(
            "lib/data/services/file_operations_payload_mixin.dart",
            source,
        )
        classifications = {
            item.literal: item.detected_classification for item in findings
        }

        self.assertEqual(
            classifications["codec.unsupported.${reason.name}"],
            "protocolDescription",
        )
        self.assertEqual(
            classifications["codec.malformed.${reason.name}"],
            "protocolDescription",
        )
        self.assertEqual(
            classifications["codec.resource-limit.${limit.name}"],
            "protocolDescription",
        )
        self.assertEqual(
            classifications["codec.internal.${stage.name}"],
            "protocolDescription",
        )
        self.assertEqual(
            classifications["The document could not be decoded."],
            "legacyUserVisible",
        )

    def test_reports_path_line_and_classification(self) -> None:
        findings = CHECKER.scan_source(
            "lib/core/services/example.dart",
            (FIXTURE_ROOT / "positive.dart.txt").read_text(encoding="utf-8"),
        )

        hardcoded = next(
            item for item in findings if item.literal.startswith("Still hardcoded")
        )
        self.assertEqual(hardcoded.line, 6)
        self.assertEqual(hardcoded.path, "lib/core/services/example.dart")
        self.assertEqual(hardcoded.detected_classification, "legacyUserVisible")
        self.assertEqual(hardcoded.surface, "message")
        self.assertTrue(hardcoded.is_violation)

    def test_distant_localization_context_does_not_absolve_literal(self) -> None:
        findings = CHECKER.scan_source(
            "lib/core/models/result.dart",
            (FIXTURE_ROOT / "positive.dart.txt").read_text(encoding="utf-8"),
        )

        self.assertTrue(
            any(item.literal.startswith("Still hardcoded") for item in findings)
        )

    def test_switch_arrow_list_and_intermediate_prose_are_detected(self) -> None:
        findings = CHECKER.scan_source(
            "lib/core/models/result.dart",
            (FIXTURE_ROOT / "positive.dart.txt").read_text(encoding="utf-8"),
        )
        literals = {item.literal for item in findings}

        self.assertIn("Create a symbol fragment", literals)
        self.assertIn("Create a fallback fragment", literals)
        self.assertIn("Read the current tape symbol.", literals)
        self.assertIn("Move the head one position.", literals)
        self.assertIn("Intermediate user-facing explanation.", literals)

    def test_known_repository_false_negatives_are_inventoried(self) -> None:
        expected = {
            "lib/core/manual_conversions/regex_to_fa_session_factory.dart": (
                "Create a symbol fragment"
            ),
            "lib/core/algorithms/pda_simulator_search.dart": (
                "Accepted by final state"
            ),
            "lib/core/algorithms/tm_time_profiler.dart": (
                "Time profiling was cancelled."
            ),
        }

        for path, literal in expected.items():
            findings = CHECKER.scan_source(
                path, (REPO_ROOT / path).read_text(encoding="utf-8")
            )
            self.assertIn(literal, {item.literal for item in findings})

    def test_protocol_tokens_and_notation_are_not_false_positives(self) -> None:
        findings = CHECKER.scan_source(
            "lib/core/messages/tokens.dart",
            (FIXTURE_ROOT / "negative.dart.txt").read_text(encoding="utf-8"),
        )

        self.assertEqual(findings, [])

    def test_raw_stable_code_in_programmer_error_is_inventoried(self) -> None:
        findings = CHECKER.scan_source(
            "lib/core/grammar/example.dart",
            "throw ArgumentError('grammar.example.invariant-required');\n",
        )

        self.assertEqual(len(findings), 1)
        self.assertEqual(
            findings[0].literal,
            "grammar.example.invariant-required",
        )
        self.assertEqual(
            findings[0].detected_classification,
            "developerDiagnostic",
        )

    def test_internal_model_diagnostics_use_semantic_context(self) -> None:
        source = """
String prettyPrint({int indent = 0}) {
  final buf = StringBuffer();
  buf.write('[$start,$end)');
  return buf.toString();
}

@override
String toString() {
  return 'NFAPathNode(stepNumber: $stepNumber, currentState: $currentState, '
      'remainingInput: $remainingInput, children: ${children.length}, '
      'isAccepting: $isAccepting, isDeadEnd: $isDeadEnd)';
}

List<String> validateStructure() {
  final messages = <String>[];
  messages.add('category nested below a category: ${category.id}');
  messages.add('duplicate node id: ${node.id}');
  messages.add(
    'topic ${topic.id} references missing related topic: $relatedId',
  );
  return messages;
}

void requirePayload() {
  throw ArgumentError.value(node.id, 'nodes', 'Duplicate node identity');
  throw ArgumentError.value(
    branch.id,
    'branches',
    'Duplicate branch identity',
  );
  throw ArgumentError.value(
    propertyKey,
    'propertyKey',
    'No payload of type $T found on algorithm step ${baseStep.id}',
  );
}
"""

        findings = CHECKER.scan_source("lib/core/models/example.dart", source)
        classifications = {
            item.literal: item.detected_classification for item in findings
        }

        self.assertEqual(
            classifications["[$start,$end)"],
            "protocolDescription",
        )
        for literal in (
            "NFAPathNode(stepNumber: $stepNumber, currentState: $currentState, ",
            "remainingInput: $remainingInput, children: ${children.length}, ",
            "isAccepting: $isAccepting, isDeadEnd: $isDeadEnd)",
            "category nested below a category: ${category.id}",
            "duplicate node id: ${node.id}",
            "topic ${topic.id} references missing related topic: $relatedId",
            "Duplicate node identity",
            "Duplicate branch identity",
            "No payload of type $T found on algorithm step ${baseStep.id}",
        ):
            self.assertEqual(
                classifications[literal],
                "developerDiagnostic",
                literal,
            )

    def test_same_model_words_remain_visible_outside_internal_context(self) -> None:
        source = """
final spanMessage = '[$start,$end)';
final nodeIdentityMessage = 'Duplicate node identity';
final branchIdentityMessage = 'Duplicate branch identity';
final grammarDiagnosticMessage =
    'GrammarDiagnostic(code: $code, severity: $severity, message: $message, symbols: $symbols, productionIds: $productionIds)';
final categoryMessage =
    'category nested below a category: ${category.id}';
final duplicateMessage = 'duplicate node id: ${node.id}';
final relatedTopicMessage =
    'topic ${topic.id} references missing related topic: $relatedId';
final pathStartMessage =
    'NFAPathNode(stepNumber: $stepNumber, currentState: $currentState, ';
final pathMiddleMessage =
    'remainingInput: $remainingInput, children: ${children.length}, ';
final pathEndMessage =
    'isAccepting: $isAccepting, isDeadEnd: $isDeadEnd)';
final payloadMessage =
    'No payload of type $T found on algorithm step ${baseStep.id}';
"""

        findings = CHECKER.scan_source("lib/core/models/example.dart", source)

        self.assertEqual(len(findings), 11)
        self.assertTrue(
            all(
                item.detected_classification == "legacyUserVisible"
                for item in findings
            )
        )

    def test_path_style_content_ids_are_not_user_visible_prose(self) -> None:
        findings = CHECKER.scan_source(
            "lib/core/educational_content/content_ids.dart",
            (
                "const teachingId = 'grammar-teaching/normalization/lambda';\n"
                "const conversionId = 'manual-conversion/fa-to-regex/complete';\n"
            ),
        )

        self.assertEqual(findings, [])

    def test_transducer_asset_references_are_protocol_but_copy_stays_visible(
        self,
    ) -> None:
        path = "lib/data/transducers/example_catalog.dart"
        source = (
            "const path = 'assets/examples/foo.json';\n"
            "const id = 'asset/foo';\n"
            "const title = 'Visible example title';\n"
            "const description = 'Visible example description.';\n"
        )
        raw_literals = CHECKER.extract_literals(source)
        classifications = {
            item.literal: CHECKER._detected_classification(path, item)
            for item in raw_literals
        }
        findings = CHECKER.scan_source(path, source)

        self.assertEqual(
            classifications["assets/examples/foo.json"], "protocolDescription"
        )
        self.assertEqual(classifications["asset/foo"], "protocolDescription")
        self.assertEqual(
            {item.literal: item.detected_classification for item in findings},
            {
                "Visible example title": "legacyUserVisible",
                "Visible example description.": "legacyUserVisible",
            },
        )

    def test_parser_wire_values_are_protocol_but_failure_copy_stays_visible(
        self,
    ) -> None:
        path = "lib/core/parsers/jflap_xml_codec.dart"
        source = (
            "builder.processing('xml', 'version=\"1.0\" encoding=\"UTF-8\"');\n"
            "final id = 'imported_${DateTime.now().millisecondsSinceEpoch}';\n"
            "final key = '$rawFrom|$symbol';\n"
            "return Failure('Visible parser failure.');\n"
        )
        raw_literals = CHECKER.extract_literals(source)
        classifications = {
            item.literal: CHECKER._detected_classification(path, item)
            for item in raw_literals
        }
        findings = CHECKER.scan_source(path, source)

        for literal in (
            'version="1.0" encoding="UTF-8"',
            "imported_${DateTime.now().millisecondsSinceEpoch}",
            "$rawFrom|$symbol",
        ):
            self.assertEqual(classifications[literal], "protocolDescription")
        self.assertEqual(
            {item.literal: item.detected_classification for item in findings},
            {
                'version="1.0" encoding="UTF-8"': "protocolDescription",
                "imported_${DateTime.now().millisecondsSinceEpoch}": (
                    "protocolDescription"
                ),
                "$rawFrom|$symbol": "protocolDescription",
                "Visible parser failure.": "legacyUserVisible",
            },
        )

    def test_interoperability_routing_fragments_are_protocol_data(self) -> None:
        path = "lib/core/interoperability/document_interoperability_registry.dart"
        source = (
            "final cacheKey = '${limits.maximumDepth}|${limits.maximumElements}|';\n"
            "final signature = '${owner.key.value}|${descriptor.formatId.value}|'\n"
            "    '${descriptor.schemas.minimum}-${descriptor.schemas.maximum}|'\n"
            "    '${directions.join(',')}|${descriptor.priority}';\n"
            "final message = 'Codec registration failed for this document.';\n"
        )
        raw_literals = CHECKER.extract_literals(source)
        classifications = {
            item.literal: CHECKER._detected_classification(path, item)
            for item in raw_literals
        }

        for literal in (
            "${limits.maximumDepth}|${limits.maximumElements}|",
            "${owner.key.value}|${descriptor.formatId.value}|",
            "${descriptor.schemas.minimum}-${descriptor.schemas.maximum}|",
            "${directions.join(',')}|${descriptor.priority}",
        ):
            self.assertEqual(classifications[literal], "protocolDescription")
        self.assertEqual(
            classifications["Codec registration failed for this document."],
            "legacyUserVisible",
        )

    def test_active_session_storage_keys_and_codec_failures_are_not_ui_copy(
        self,
    ) -> None:
        persistence_path = (
            "lib/data/services/active_session_persistence_service.dart"
        )
        for literal in (
            "active_editor_session",
            "settings_auto_save",
            "${sessionKey}_unsupported_v$version",
            "${sessionKey}_unsupported_${key.type.value}_${key.variant.value}_v$version",
            "backup_unsupported_version",
            "backup_unsupported_schema",
        ):
            with self.subTest(literal=literal):
                raw = CHECKER.RawLiteral(
                    literal=literal,
                    line=1,
                    column=1,
                    context=f"final value = '{literal}';",
                    is_directive=False,
                )
                self.assertEqual(
                    CHECKER._detected_classification(persistence_path, raw),
                    "protocolDescription",
                )

        codec_path = "lib/data/services/active_session_snapshot_codec.dart"
        for literal in (
            "Active session document envelope must be an object",
            "Active session document data must be an object",
            "Active session annotation collection must be an object",
        ):
            with self.subTest(literal=literal):
                raw = CHECKER.RawLiteral(
                    literal=literal,
                    line=1,
                    column=1,
                    context=f"throw FormatException('{literal}');",
                    is_directive=False,
                )
                self.assertEqual(
                    CHECKER._detected_classification(codec_path, raw),
                    "developerDiagnostic",
                )

    def test_file_operation_matching_tokens_and_payload_metadata_are_protocol(
        self,
    ) -> None:
        io_path = "lib/data/services/file_operations_service_io.dart"
        for literal in (
            "operation not permitted",
            "permission denied",
            "access is denied",
            "not permitted",
            "no such file",
            "cannot find the path",
            "does not exist",
            "${baseName}_$timestamp.$extension",
            "${directory.path}/$fileName",
        ):
            with self.subTest(literal=literal):
                raw = CHECKER.RawLiteral(
                    literal=literal,
                    line=1,
                    column=1,
                    context=f"final value = '{literal}';",
                    is_directive=False,
                )
                self.assertEqual(
                    CHECKER._detected_classification(io_path, raw),
                    "protocolDescription",
                )

        mime = CHECKER.RawLiteral(
            literal="image/svg+xml",
            line=1,
            column=1,
            context="const mimeType = 'image/svg+xml';",
            is_directive=False,
        )
        self.assertEqual(
            CHECKER._detected_classification(
                "lib/data/services/file_operations_service_web.dart",
                mime,
            ),
            "protocolDescription",
        )

    def test_tm_block_generated_identifiers_are_protocol(self) -> None:
        path = "lib/core/services/tm_block_project_editor.dart"
        for literal in (
            "$newId:${invocation.id}",
            "$base#$suffix",
            "$newId:machine",
        ):
            with self.subTest(literal=literal):
                raw = CHECKER.RawLiteral(
                    literal=literal,
                    line=1,
                    column=1,
                    context=f"final value = '{literal}';",
                    is_directive=False,
                )
                self.assertEqual(
                    CHECKER._detected_classification(path, raw),
                    "protocolDescription",
                )

    def test_teaching_conversion_and_trace_storage_keys_are_protocol(self) -> None:
        cases = {
            "lib/data/services/grammar_teaching_session_store.dart": (
                "grammar_teaching_session.v1",
                "parse.${session.kind.name}",
                "$_prefix.$kind.$grammarId.$revision",
            ),
            "lib/data/services/manual_conversion_session_store.dart": (
                "manual_conversion_session.",
                "$keyPrefix$workspaceKey",
            ),
            "lib/data/services/trace_persistence_service.dart": (
                "trace_history",
                "current_trace",
                "trace_metadata",
                "simulation_trace_history",
                "current_simulation_trace",
            ),
        }

        for path, literals in cases.items():
            for literal in literals:
                with self.subTest(path=path, literal=literal):
                    raw = CHECKER.RawLiteral(
                        literal=literal,
                        line=1,
                        column=1,
                        context=f"final value = '{literal}';",
                        is_directive=False,
                    )
                    self.assertEqual(
                        CHECKER._detected_classification(path, raw),
                        "protocolDescription",
                    )

    def test_grammar_wire_keys_and_formal_renderings_are_protocol_data(self) -> None:
        cases = {
            "lib/core/grammar/dependency_graph/variable_dependency_graph.dart": [
                "vdg-e$index",
            ],
            "lib/core/grammar/phrase_structure/phrase_structure_production.dart": [
                "${left.stableKey}->${right.stableKey}",
            ],
            "lib/core/grammar/phrase_structure/symbol_sequence.dart": [
                "${symbol.isTerminal ? 't' : 'n'}:${symbol.value.length}:${symbol.value}",
            ],
            "lib/core/grammar/teaching/grammar_teaching_sessions.dart": [
                "normalization diagnostic",
                "ll:$nonTerminal:$lookahead",
                "${production.leftSide.single} -> $right",
                "$left → ${right.isEmpty ? 'ε' : right.join(' ')}",
            ],
        }

        for path, literals in cases.items():
            with self.subTest(path=path):
                for literal in literals:
                    raw = CHECKER.RawLiteral(
                        literal=literal,
                        line=1,
                        column=1,
                        context=f"final value = '{literal}';",
                        is_directive=False,
                    )
                    self.assertEqual(
                        CHECKER._detected_classification(path, raw),
                        "protocolDescription",
                    )

    def test_ll1_production_display_is_protocol_only_in_display_getter(self) -> None:
        literal = "$leftSide → ${rightSide.isEmpty ? 'ε' : rightSide.join(' ')}"
        source = (
            "String get display =>\n"
            f"    '{literal}';\n"
            f"final description = '{literal}';\n"
        )

        findings = CHECKER.scan_source(
            "lib/core/algorithms/grammar_analysis/grammar_analysis_models.dart",
            source,
        )

        self.assertEqual(
            [item.detected_classification for item in findings],
            ["protocolDescription", "legacyUserVisible"],
        )

    def test_regex_step_identifiers_are_protocol_only_in_semantic_fields(
        self,
    ) -> None:
        source = (
            "final step = RegexSimplificationStep.applyRule(\n"
            "  id: 'step_$stepNumber',\n"
            "  matchedSubexpression: '$duplicateSegment|$duplicateSegment',\n"
            ");\n"
            "final title = 'step_$stepNumber';\n"
            "final message = '$duplicateSegment|$duplicateSegment';\n"
        )

        findings = CHECKER.scan_source(
            "lib/core/algorithms/regex_simplifier_steps.dart",
            source,
        )

        self.assertEqual(
            [item.detected_classification for item in findings],
            [
                "protocolDescription",
                "protocolDescription",
                "legacyUserVisible",
                "legacyUserVisible",
            ],
        )

    def test_regex_step_to_string_fragments_are_developer_diagnostics(
        self,
    ) -> None:
        source = (
            "String toString() {\n"
            "  return 'RegexSimplificationStep(stepNumber: ${baseStep.stepNumber}, '\n"
            "      'type: ${stepType.name}, title: ${baseStep.title})';\n"
            "}\n"
        )

        findings = CHECKER.scan_source(
            "lib/core/models/regex_simplification_step.dart",
            source,
        )

        self.assertEqual(
            [item.detected_classification for item in findings],
            ["developerDiagnostic", "developerDiagnostic"],
        )

    def test_regex_to_nfa_compatibility_and_formal_values_are_protocol_only(
        self,
    ) -> None:
        path = "lib/core/models/regex_to_nfa_step.dart"
        source = (
            "final arguments = {\n"
            "  'pattern': _regexToNfaLiteral(\n"
            "    '(${firstFragmentLabel ?? ''}|${secondFragmentLabel ?? ''})',\n"
            "    'regex-fragment',\n"
            "  ),\n"
            "};\n"
            "String _transitionPlan(Set<Transition>? transitions) {\n"
            "  return '${transition.fromState.label} → ${transition.toState.label} ';\n"
            "}\n"
            "String get legacyPropertyValue => switch (this) {\n"
            "  basicSymbol => 'Basic Symbol',\n"
            "  kleeneStar => 'Kleene Star',\n"
            "};\n"
            "final title = 'Basic Symbol';\n"
            "final message = 'Kleene Star';\n"
        )

        findings = CHECKER.scan_source(path, source)

        self.assertEqual(
            [item.detected_classification for item in findings],
            [
                "protocolDescription",
                "protocolDescription",
                "protocolDescription",
                "protocolDescription",
                "legacyUserVisible",
                "legacyUserVisible",
            ],
        )

    def test_fa_to_regex_message_code_is_protocol_only_in_message_factory(
        self,
    ) -> None:
        source = (
            "final explanationMessage = _faToRegexStepMessage(\n"
            "  '${_faToRegexStepCode(stepType)}-explanation',\n"
            ");\n"
            "final visible = '${_faToRegexStepCode(stepType)}-explanation';\n"
        )

        findings = CHECKER.scan_source(
            "lib/core/models/fa_to_regex_step.dart",
            source,
        )

        self.assertEqual(
            [item.detected_classification for item in findings],
            ["protocolDescription", "legacyUserVisible"],
        )

    def test_generated_identifiers_are_protocol_only_at_exact_producers(
        self,
    ) -> None:
        cases = {
            "lib/core/algorithms/state_renamer.dart": (
                "state.copyWith(label: 'q$i');\n"
                "final visible = 'State q$i';\n"
            ),
            "lib/core/formal_systems/conversion_capability.dart": (
                "String get stableKey => "
                "'${source.value}->${target.value}:${id.value}';\n"
                "final visible = '${source.value}->${target.value}:${id.value}';\n"
            ),
            "lib/core/algorithms/dfa_completer.dart": (
                "candidate = '${base}_${suffix++}';\n"
                "final visible = '${base}_${suffix++}';\n"
            ),
            "lib/core/formal_systems/formal_system_ids.dart": (
                "String get value => '${type.value}:${variant.value}';\n"
                "final visible = '${type.value}:${variant.value}';\n"
            ),
        }

        for path, source in cases.items():
            with self.subTest(path=path):
                findings = CHECKER.scan_source(path, source)
                self.assertEqual(
                    [item.detected_classification for item in findings],
                    ["protocolDescription", "legacyUserVisible"],
                )

        font_findings = CHECKER.scan_source(
            "lib/core/constants/monospace_typography.dart",
            (
                "const List<String> kMonospaceFontFamilyFallback = <String>[\n"
                "  'DejaVu Sans Mono', 'Courier New', 'Roboto Mono',\n"
                "];\n"
                "final visible = 'Use Courier New in the interface.';\n"
            ),
        )
        self.assertEqual(
            [item.detected_classification for item in font_findings],
            [
                "protocolDescription",
                "protocolDescription",
                "protocolDescription",
                "legacyUserVisible",
            ],
        )

    def test_ll1_conflict_formal_outputs_are_protocol_only_in_exact_getters(self) -> None:
        alternatives = "${entry.productionId} ${entry.display}"
        description = "$formalKind [$nonTerminal, $lookahead]: $alternativesDisplay"
        source = (
            "String get alternativesDisplay => entries\n"
            f"    .map((entry) => '{alternatives}')\n"
            "    .join(' | ');\n"
            "String get formalKind => switch (kind) {\n"
            "  firstFirst => 'FIRST/FIRST',\n"
            "  firstFollow => 'FIRST/FOLLOW',\n"
            "};\n"
            "String get formalDescription =>\n"
            f"    '{description}';\n"
            "final label = 'FIRST/FIRST';\n"
            f"final title = '{alternatives}';\n"
            f"final message = '{description}';\n"
        )

        findings = CHECKER.scan_source("lib/core/example.dart", source)

        self.assertEqual(
            [item.detected_classification for item in findings],
            [
                "protocolDescription",
                "protocolDescription",
                "protocolDescription",
                "protocolDescription",
                "legacyUserVisible",
                "legacyUserVisible",
                "legacyUserVisible",
            ],
        )

    def test_l_system_protocol_fragments_do_not_hide_new_visible_prose(self) -> None:
        cases = {
            "lib/core/l_systems/l_system_export.dart": [
                "<metadata>${_xml(encodedMetadata)}</metadata>",
                'viewBox="0 0 ${_number(width)} ${_number(height)}">',
            ],
            "lib/core/l_systems/l_system_model.dart": [
                "commandMapping.${entry.key}",
            ],
            "lib/data/l_systems/l_system_examples.dart": [
                "Koch curve",
                "A four-segment replacement with 60 degree turns.",
                "$id.${entry.key}",
            ],
        }
        for path, literals in cases.items():
            for literal in literals:
                with self.subTest(path=path, literal=literal):
                    raw = CHECKER.RawLiteral(
                        literal=literal,
                        line=1,
                        column=1,
                        context=f"final value = '{literal}';",
                        is_directive=False,
                    )
                    self.assertEqual(
                        CHECKER._detected_classification(path, raw),
                        "protocolDescription",
                    )

        visible = CHECKER.RawLiteral(
            literal="The L-system failed for the user.",
            line=1,
            column=1,
            context="return Failure('The L-system failed for the user.');",
            is_directive=False,
        )
        self.assertEqual(
            CHECKER._detected_classification(
                "lib/core/l_systems/l_system_export.dart",
                visible,
            ),
            "legacyUserVisible",
        )

    def test_batch_generated_ids_and_csv_schema_are_protocol_data(self) -> None:
        path = "lib/core/batch_execution/batch_report_encoder.dart"
        raw = CHECKER.RawLiteral(
            literal="modelId,modelRevision,strategyId,tokenizationMode,maxSteps,",
            line=1,
            column=1,
            context="buffer.write('modelId,modelRevision,strategyId,tokenizationMode,maxSteps,');",
            is_directive=False,
        )

        self.assertEqual(
            CHECKER._detected_classification(path, raw),
            "protocolDescription",
        )

    def test_directives_after_header_comments_are_not_candidates(self) -> None:
        for directive in ("import", "export", "part"):
            with self.subTest(directive=directive):
                findings = CHECKER.scan_source(
                    "lib/core/models/directive.dart",
                    (
                        "// Copyright header; additional text.\n"
                        "/* License block; additional text. */\n"
                        f"{directive} 'package:example/two_words.dart';\n"
                    ),
                )

                self.assertEqual(findings, [])

    def test_directive_does_not_mask_later_prose_on_the_same_line(self) -> None:
        findings = CHECKER.scan_source(
            "lib/core/models/directive.dart",
            (
                "import 'package:example/dependency.dart'; "
                "final value = Domain(message: 'Still hardcoded.');\n"
            ),
        )

        self.assertEqual([item.literal for item in findings], ["Still hardcoded."])

    def test_allowlist_is_exact_per_occurrence(self) -> None:
        source = "final a = Domain(message: 'Existing prose.');\n" * 2
        findings = CHECKER.scan_source("lib/core/models/result.dart", source)
        first = findings[0]
        allowance = CHECKER.Allowance(
            path=first.path,
            literal=first.literal,
            occurrence=1,
            classification="legacyUserVisible",
            rationale="Existing domain prose tracked for migration under #210.",
            owner="domain-models",
            target_namespace="model",
        )

        classified, stale = CHECKER.apply_allowlist(findings, {allowance.key: allowance})

        self.assertEqual(stale, [])
        self.assertFalse(classified[0].is_violation)
        self.assertTrue(classified[1].is_violation)

    def test_allowlist_classification_drift_is_a_violation(self) -> None:
        finding = CHECKER.scan_source(
            "lib/core/models/result.dart",
            "final value = Domain(message: 'Existing prose.');",
        )[0]
        allowance = CHECKER.Allowance(
            path=finding.path,
            literal=finding.literal,
            occurrence=finding.occurrence,
            classification="developerDiagnostic",
            rationale="Existing developer diagnostic tracked under #210.",
            owner="domain-models",
            target_namespace="model",
        )

        classified, stale = CHECKER.apply_allowlist(
            [finding], {allowance.key: allowance}
        )

        self.assertEqual(stale, [])
        self.assertTrue(classified[0].is_violation)
        self.assertIn("classification drift", classified[0].rationale)

    def test_supported_compatibility_override_is_exact_and_fail_closed(self) -> None:
        source = "final a = Domain(message: 'Compatibility prose.');\n" * 2
        findings = CHECKER.scan_source("lib/core/models/result.dart", source)
        first = findings[0]
        allowance = CHECKER.Allowance(
            path=first.path,
            literal=first.literal,
            occurrence=1,
            classification="supportedCompatibilityDescription",
            rationale=(
                "Supported compatibility description; the model StructuredMessage "
                "resolver supplies localized UI copy."
            ),
            owner="domain-models",
            target_namespace="model",
        )

        classified, stale = CHECKER.apply_allowlist(
            findings, {allowance.key: allowance}
        )

        self.assertEqual(stale, [])
        self.assertFalse(classified[0].is_violation)
        self.assertEqual(
            classified[0].classification, "supportedCompatibilityDescription"
        )
        self.assertTrue(classified[1].is_violation)
        self.assertEqual(classified[1].classification, "unapprovedUserVisible")

    def test_supported_compatibility_requires_structured_resolver_evidence(
        self,
    ) -> None:
        with tempfile.TemporaryDirectory() as temporary:
            root = Path(temporary)
            source_path = root / "lib" / "core" / "models" / "result.dart"
            source_path.parent.mkdir(parents=True)
            source_path.write_text(
                "final value = Domain(message: 'Compatibility prose.');\n",
                encoding="utf-8",
            )
            scope = root / "scope.json"
            allowlist = root / "allowlist.json"
            inventory = root / "inventory.json"
            scope.write_text(
                json.dumps(
                    {"schemaVersion": 1, "roots": ["lib/core/models"]}
                ),
                encoding="utf-8",
            )
            allowlist.write_text(
                json.dumps(
                    {
                        "schemaVersion": 1,
                        "entries": [
                            {
                                "path": "lib/core/models/result.dart",
                                "literal": "Compatibility prose.",
                                "occurrence": 1,
                                "classification": (
                                    "supportedCompatibilityDescription"
                                ),
                                "rationale": (
                                    "Supported compatibility description without "
                                    "production resolver evidence."
                                ),
                                "owner": "domain-models",
                                "targetNamespace": "model",
                            }
                        ],
                    }
                ),
                encoding="utf-8",
            )
            inventory.write_text("{}", encoding="utf-8")

            report, errors = CHECKER.validate_repository(
                root, scope, allowlist, inventory
            )

        self.assertEqual(report["violationCount"], 1)
        self.assertTrue(
            any("StructuredMessage resolver" in error for error in errors)
        )

    def test_inventory_accounts_for_every_source_occurrence(self) -> None:
        findings = CHECKER.scan_source(
            "lib/core/services/example.dart",
            (FIXTURE_ROOT / "positive.dart.txt").read_text(encoding="utf-8"),
        )
        inventory = CHECKER.build_inventory(findings)
        inventoried = sum(
            producer["occurrenceCount"]
            for family in inventory["families"]
            for producer in family["producers"]
        )

        self.assertEqual(inventoried, len(findings))
        self.assertFalse(inventory["zeroUserVisibleProseClaim"])
        self.assertEqual(inventory["status"], "migration-in-progress")

    def test_inventory_separates_structured_compatibility_from_unfinished_work(
        self,
    ) -> None:
        findings = CHECKER.scan_source(
            "lib/core/models/result.dart",
            "final value = Domain(message: 'Compatibility prose.');",
        )
        finding = findings[0]
        allowance = CHECKER.Allowance(
            path=finding.path,
            literal=finding.literal,
            occurrence=finding.occurrence,
            classification="supportedCompatibilityDescription",
            rationale=(
                "Supported compatibility description; the model StructuredMessage "
                "resolver supplies localized UI copy."
            ),
            owner="domain-models",
            target_namespace="model",
        )
        classified, _ = CHECKER.apply_allowlist(
            findings, {allowance.key: allowance}
        )

        inventory = CHECKER.build_inventory(classified)

        self.assertTrue(inventory["zeroUserVisibleProseClaim"])
        self.assertEqual(
            inventory["status"], "structured-with-compatibility-descriptions"
        )
        self.assertEqual(inventory["summary"]["migrationRequiredCount"], 0)
        self.assertEqual(
            inventory["summary"]["compatibilityDescriptionCount"], 1
        )
        self.assertEqual(
            inventory["families"][0]["producers"][0]["status"],
            "structured-compatibility",
        )

    def test_repository_gate_fails_when_allowlisted_migration_work_remains(
        self,
    ) -> None:
        with tempfile.TemporaryDirectory() as temporary:
            root = Path(temporary)
            source_path = root / "lib" / "core" / "models" / "result.dart"
            source_path.parent.mkdir(parents=True)
            source_path.write_text(
                "final value = Domain(message: 'Unfinished prose.');\n",
                encoding="utf-8",
            )
            scope = root / "scope.json"
            allowlist = root / "allowlist.json"
            inventory = root / "inventory.json"
            scope.write_text(
                json.dumps(
                    {"schemaVersion": 1, "roots": ["lib/core/models"]}
                ),
                encoding="utf-8",
            )
            finding = CHECKER.scan_source(
                "lib/core/models/result.dart",
                source_path.read_text(encoding="utf-8"),
            )[0]
            allowance = CHECKER.Allowance(
                path=finding.path,
                literal=finding.literal,
                occurrence=finding.occurrence,
                classification="legacyUserVisible",
                rationale="Existing domain prose still requires migration under #210.",
                owner="domain-models",
                target_namespace="model",
            )
            classified, _ = CHECKER.apply_allowlist(
                [finding], {allowance.key: allowance}
            )
            allowlist.write_text(
                json.dumps(
                    {
                        "schemaVersion": 1,
                        "entries": [
                            {
                                "path": allowance.path,
                                "literal": allowance.literal,
                                "occurrence": allowance.occurrence,
                                "classification": allowance.classification,
                                "rationale": allowance.rationale,
                                "owner": allowance.owner,
                                "targetNamespace": allowance.target_namespace,
                            }
                        ],
                    }
                ),
                encoding="utf-8",
            )
            inventory.write_text(
                json.dumps(CHECKER.build_inventory(classified)), encoding="utf-8"
            )

            _, errors = CHECKER.validate_repository(
                root, scope, allowlist, inventory
            )

        self.assertTrue(any("migration is incomplete" in error for error in errors))

    def test_missing_scope_fails_closed(self) -> None:
        with tempfile.TemporaryDirectory() as temporary:
            root = Path(temporary)
            scope = root / "scope.json"
            allowlist = root / "allowlist.json"
            inventory = root / "inventory.json"
            scope.write_text(
                json.dumps({"schemaVersion": 1, "roots": ["lib/missing"]}),
                encoding="utf-8",
            )
            allowlist.write_text(
                json.dumps({"schemaVersion": 1, "entries": []}),
                encoding="utf-8",
            )
            inventory.write_text("{}", encoding="utf-8")

            _, errors = CHECKER.validate_repository(
                root, scope, allowlist, inventory
            )

        self.assertTrue(any("scoped path is missing" in error for error in errors))


if __name__ == "__main__":
    unittest.main()
