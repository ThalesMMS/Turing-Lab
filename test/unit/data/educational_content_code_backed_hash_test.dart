import 'dart:convert';
import 'dart:io';

import 'package:crypto/crypto.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:turing_lab/core/grammar/phrase_structure/phrase_structure.dart';
import 'package:turing_lab/core/l_systems/l_systems.dart';
import 'package:turing_lab/core/models/tm.dart';
import 'package:turing_lab/data/grammar/unrestricted_grammar_example_catalog.dart';
import 'package:turing_lab/data/l_systems/l_system_examples.dart';
import 'package:turing_lab/data/tm/tm_block_example_catalog.dart';

Object? _canonicalize(Object? value) {
  if (value is Map) {
    final entries = value.entries.toList()
      ..sort(
        (left, right) => left.key.toString().compareTo(right.key.toString()),
      );
    return <String, Object?>{
      for (final entry in entries)
        entry.key.toString(): _canonicalize(entry.value),
    };
  }
  if (value is Iterable) {
    return value.map(_canonicalize).toList(growable: false);
  }
  return value;
}

String _digest(Object? payload) =>
    sha256.convert(utf8.encode(jsonEncode(_canonicalize(payload)))).toString();

Map<String, Object?> _formalJson(Object payload) {
  if (payload is LSystemDocument) return payload.toJson();
  if (payload is UnrestrictedGrammar) return payload.toJson();
  if (payload is TM) return payload.toJson();
  throw StateError('Unsupported code-backed payload: $payload');
}

void main() {
  test(
    'code-backed educational hashes cover canonical runtime payloads',
    () async {
      final examples = [
        ...await const LSystemExampleCatalog().loadExamples(),
        ...await const UnrestrictedGrammarExampleCatalog().loadExamples(),
        ...await const TMBlockExampleCatalog().loadExamples(),
      ];
      final actual = <String, String>{
        for (final example in examples)
          example.id: _digest(_formalJson(example.payload)),
      };
      final fixture =
          jsonDecode(
                File(
                  'test/fixtures/localization/educational_content/'
                  'code_backed_formal_payloads.v1.json',
                ).readAsStringSync(),
              )
              as Map<String, Object?>;
      final expected = (fixture['payloadSha256']! as Map)
          .cast<String, String>();

      expect(fixture['schemaVersion'], 1);
      expect(fixture['contract'], 'canonicalRuntimeJsonV1');
      expect(actual, expected);
    },
  );
}
