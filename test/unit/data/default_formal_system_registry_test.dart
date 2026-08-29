import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:turing_lab/core/grammar/phrase_structure/phrase_structure.dart';
import 'package:turing_lab/core/interoperability/interoperability.dart';
import 'package:turing_lab/core/l_systems/l_systems.dart';
import 'package:turing_lab/core/models/asset_example.dart';
import 'package:turing_lab/data/formal_systems/default_formal_system_registry.dart';
import 'package:turing_lab/presentation/workspaces/default_workspace_presentation_modules.dart';

void main() {
  test('registers unrestricted grammar and L-system end to end', () async {
    final registry = DefaultFormalSystemRegistry.registry;
    final unrestricted = registry.moduleFor(
      UnrestrictedGrammarCapabilities.systemKey,
    );
    final lSystem = registry.moduleFor(LSystemFormalSystemIds.key);

    expect(unrestricted, isNotNull);
    expect(lSystem, isNotNull);
    expect(unrestricted!.codecs, hasLength(2));
    expect(lSystem!.codecs, hasLength(2));
    expect(unrestricted.session, isNotNull);
    expect(lSystem.session, isNotNull);

    final unrestrictedExamples = await unrestricted.examples!.loadExamples();
    final lSystemExamples = await lSystem.examples!.loadExamples();
    expect(unrestrictedExamples, hasLength(3));
    expect(unrestrictedExamples.map((example) => example.category).toSet(), {
      ExampleCategory.unrestrictedGrammar,
    });
    expect(lSystemExamples, hasLength(6));
    expect(lSystemExamples.map((example) => example.category).toSet(), {
      ExampleCategory.lSystem,
    });

    final presentation = buildDefaultWorkspacePresentationModules(registry);
    expect(
      presentation.map((module) => module.key),
      containsAllInOrder([
        UnrestrictedGrammarCapabilities.systemKey,
        LSystemFormalSystemIds.key,
      ]),
    );
  });

  test('erased codecs preserve structured malformed messages', () {
    final lSystem = DefaultFormalSystemRegistry.registry.moduleFor(
      LSystemFormalSystemIds.key,
    )!;
    final codec = lSystem.codecs.singleWhere(
      (candidate) =>
          candidate.descriptor.codecId.value == 'l-system.jflap-xml.v1',
    );
    const source = '''<structure><type>lsystem</type><axiom>F</axiom>
<parameter><name>color</name><value>not-a-color</value></parameter>
</structure>''';

    final outcome =
        codec.decode(
              DocumentPayload(bytes: Uint8List.fromList(utf8.encode(source))),
            )
            as CodecMalformed<InteroperableDocument<Object>>;

    expect(
      outcome.structuredMessage?.stableCode,
      'codec.l-system-jflap.invalid-parameter',
    );
    expect(outcome.structuredMessage?.arguments['parameter']?.value, 'color');
  });
}
