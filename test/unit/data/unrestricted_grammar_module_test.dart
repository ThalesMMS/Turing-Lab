import 'package:flutter_test/flutter_test.dart';
import 'package:turing_lab/core/formal_systems/formal_systems.dart';
import 'package:turing_lab/core/grammar/phrase_structure/phrase_structure.dart';
import 'package:turing_lab/data/grammar/unrestricted_grammar_module.dart';

void main() {
  test('module contributes codecs, examples, and typed session round-trip',
      () async {
    final module = createUnrestrictedGrammarModule();

    expect(module.descriptor.key, UnrestrictedGrammarCapabilities.systemKey);
    expect(module.descriptor.route,
        const WorkspaceRouteId('/unrestricted-grammar'));
    expect(module.codecs, hasLength(2));
    final examples = await module.examples!.loadExamples();
    expect(examples, hasLength(3));
    expect(examples.map((example) => example.id), [
      'an-bn-cn',
      'context-copying',
      'tm-generated',
    ]);
    expect(
      examples.map((example) => example.payload),
      everyElement(isA<UnrestrictedGrammar>()),
    );
    final grammar = examples.first.payload as UnrestrictedGrammar;
    final encoded = module.session!.encodeSession(grammar);
    final decoded = module.session!.decodeSession(
      encoded,
      schema: UnrestrictedGrammarCapabilities.schema,
    ) as UnrestrictedGrammar;
    expect(decoded.toJson(), grammar.toJson());
  });

  test('CFG-only actions have no conversion capability on unrestricted module',
      () {
    final module = createUnrestrictedGrammarModule();

    expect(module.conversions, isEmpty);
    expect(
      module.descriptor.capabilities.supports(FormalSystemCapability.analysis),
      isTrue,
    );
  });
}
