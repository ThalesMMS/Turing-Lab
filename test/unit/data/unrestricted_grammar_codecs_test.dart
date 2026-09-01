import 'dart:convert';
import 'dart:math' as math;
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:turing_lab/core/algorithms/tm_to_unrestricted_grammar/tm_to_unrestricted_grammar.dart';
import 'package:turing_lab/core/grammar/phrase_structure/phrase_structure.dart';
import 'package:turing_lab/core/interoperability/interoperability.dart';
import 'package:turing_lab/core/models/state.dart';
import 'package:turing_lab/core/models/tm.dart';
import 'package:turing_lab/data/codecs/unrestricted_grammar_jflap_codec.dart';
import 'package:turing_lab/data/codecs/unrestricted_grammar_json_codec.dart';
import 'package:vector_math/vector_math_64.dart';

void main() {
  const jsonCodec = UnrestrictedGrammarJsonCodec();
  const jflapCodec = UnrestrictedGrammarJflapCodec();

  test(
    'JSON round-trip preserves token boundaries, IDs, order, and extensions',
    () {
      final source = InteroperableDocument<Object>(
        document: _grammar(),
        systemKey: UnrestrictedGrammarCapabilities.systemKey,
        schema: UnrestrictedGrammarCapabilities.schema,
        extensions: DocumentExtensionBag({'future': 'preserved'}),
      );

      final encoded = jsonCodec.encode(source) as CodecSuccess<EncodedDocument>;
      expect(encoded.fidelity, DocumentFidelity.exact);
      final decoded =
          jsonCodec.decode(
                DocumentPayload(
                  bytes: encoded.value.bytes,
                  filename: 'grammar.json',
                ),
              )
              as CodecSuccess<InteroperableDocument<Object>>;
      final grammar = decoded.value.document as UnrestrictedGrammar;

      expect(grammar.toJson(), _grammar().toJson());
      expect(decoded.value.extensions.values['future'], 'preserved');
      expect(grammar.productions.first.left.symbols, const [
        TerminalGrammarSymbol('a,b'),
        NonterminalGrammarSymbol('Context'),
      ]);
    },
  );

  test('JFLAP extension round-trip is exact locally and warns on export', () {
    final source = InteroperableDocument<Object>(
      document: _grammar(),
      systemKey: UnrestrictedGrammarCapabilities.systemKey,
      schema: UnrestrictedGrammarCapabilities.schema,
    );

    final encoded = jflapCodec.encode(source) as CodecSuccess<EncodedDocument>;
    expect(encoded.fidelity, DocumentFidelity.lossy);
    expect(
      encoded.diagnostics.map((diagnostic) => diagnostic.code),
      contains('jflap.unrestricted-turing-lab-extension-portability'),
    );
    final decoded =
        jflapCodec.decode(
              DocumentPayload(
                bytes: encoded.value.bytes,
                filename: 'grammar.jff',
              ),
            )
            as CodecSuccess<InteroperableDocument<Object>>;

    expect(decoded.fidelity, DocumentFidelity.exact);
    expect(
      (decoded.value.document as UnrestrictedGrammar).toJson(),
      _grammar().toJson(),
    );
  });

  test('reordered native and JFLAP round-trips preserve exact order', () {
    final sourceGrammar = _grammar();
    final reordered = sourceGrammar.copyWith(
      revision: sourceGrammar.revision + 1,
      productions: [
        PhraseStructureProduction(
          id: sourceGrammar.productions[1].id,
          left: sourceGrammar.productions[1].left,
          right: sourceGrammar.productions[1].right,
          order: 0,
        ),
        PhraseStructureProduction(
          id: sourceGrammar.productions[0].id,
          left: sourceGrammar.productions[0].left,
          right: sourceGrammar.productions[0].right,
          order: 1,
        ),
      ],
    );
    final source = InteroperableDocument<Object>(
      document: reordered,
      systemKey: UnrestrictedGrammarCapabilities.systemKey,
      schema: UnrestrictedGrammarCapabilities.schema,
    );

    for (final codec in [jsonCodec, jflapCodec]) {
      final encoded = codec.encode(source) as CodecSuccess<EncodedDocument>;
      final decoded =
          codec.decode(
                DocumentPayload(
                  bytes: encoded.value.bytes,
                  filename: 'grammar',
                ),
              )
              as CodecSuccess<InteroperableDocument<Object>>;

      expect(
        (decoded.value.document as UnrestrictedGrammar).toJson(),
        reordered.toJson(),
      );
    }
  });

  test('standard JFLAP import normalizes text and is reorder-stable', () {
    final first = _jflap('''
      <production><left>S</left><right>aS</right></production>
      <production><left>S</left><right>b</right></production>
    ''');
    final reordered = _jflap('''
      <production><left>S</left><right>b</right></production>
      <production><left>S</left><right>aS</right></production>
    ''');

    final left =
        jflapCodec.decode(_payload(first))
            as CodecSuccess<InteroperableDocument<Object>>;
    final right =
        jflapCodec.decode(_payload(reordered))
            as CodecSuccess<InteroperableDocument<Object>>;
    final leftGrammar = left.value.document as UnrestrictedGrammar;
    final rightGrammar = right.value.document as UnrestrictedGrammar;

    expect(left.fidelity, DocumentFidelity.normalized);
    expect(
      left.diagnostics.map((diagnostic) => diagnostic.code),
      contains('jflap.unrestricted-tokenization-inferred'),
    );
    expect(
      leftGrammar.productions.map((production) => production.toJson()),
      rightGrammar.productions.map((production) => production.toJson()),
    );
  });

  test('malformed JSON and empty JFLAP LHS return typed failures', () {
    expect(
      jsonCodec.decode(_payload('{"schema":false}')),
      isA<CodecMalformed<InteroperableDocument<Object>>>(),
    );
    final outcome = jflapCodec.decode(
      _payload(
        _jflap('''
      <production><left></left><right>a</right></production>
    '''),
      ),
    );
    expect(outcome, isA<CodecMalformed<InteroperableDocument<Object>>>());
    final malformed = outcome as CodecMalformed<InteroperableDocument<Object>>;
    expect(malformed.location?.path, '/structure/production[0]/left');
  });

  test('future JSON schema is unsupported rather than malformed', () {
    final encoded =
        jsonCodec.encode(
              InteroperableDocument<Object>(
                document: _grammar(),
                systemKey: UnrestrictedGrammarCapabilities.systemKey,
                schema: UnrestrictedGrammarCapabilities.schema,
              ),
            )
            as CodecSuccess<EncodedDocument>;
    final future = jsonDecode(utf8.decode(encoded.value.bytes)) as Map;
    (future['schema'] as Map)['version'] = 2;

    final outcome = jsonCodec.decode(_payload(jsonEncode(future)));

    expect(outcome, isA<CodecUnsupported<InteroperableDocument<Object>>>());
    expect(
      (outcome as CodecUnsupported<InteroperableDocument<Object>>).reason,
      CodecUnsupportedReason.schema,
    );
  });

  test('TM construction survives JSON and JFLAP token round-trips', () {
    final state = State(
      id: 'q0',
      label: 'q0',
      position: Vector2.zero(),
      isInitial: true,
      isAccepting: true,
    );
    final tm = TM(
      id: 'tm-token-roundtrip',
      name: 'Token round-trip',
      states: {state},
      transitions: const {},
      alphabet: const {'token', 'Ω'},
      initialState: state,
      acceptingStates: {state},
      created: DateTime.utc(2026),
      modified: DateTime.utc(2026),
      bounds: const math.Rectangle(0, 0, 800, 600),
      tapeAlphabet: const {'token', 'Ω', 'B'},
    );
    final grammar = TMToGrammarConverter.build(tm, sourceRevision: 3).grammar!;
    final source = InteroperableDocument<Object>(
      document: grammar,
      systemKey: UnrestrictedGrammarCapabilities.systemKey,
      schema: UnrestrictedGrammarCapabilities.schema,
    );

    for (final codec in [jsonCodec, jflapCodec]) {
      final encoded = codec.encode(source) as CodecSuccess<EncodedDocument>;
      final decoded =
          codec.decode(
                DocumentPayload(
                  bytes: encoded.value.bytes,
                  filename: 'grammar',
                ),
              )
              as CodecSuccess<InteroperableDocument<Object>>;
      final roundTripped = decoded.value.document as UnrestrictedGrammar;

      expect(roundTripped.toJson(), grammar.toJson());
      expect(roundTripped.terminals.map((symbol) => symbol.value), {
        'token',
        'Ω',
      });
    }
  });
}

UnrestrictedGrammar _grammar() => UnrestrictedGrammar(
  id: 'unrestricted',
  name: 'Token-safe grammar',
  revision: 7,
  terminals: const [TerminalGrammarSymbol('a,b'), TerminalGrammarSymbol('🙂')],
  nonterminals: const [
    NonterminalGrammarSymbol('S'),
    NonterminalGrammarSymbol('Context'),
  ],
  startSymbol: const NonterminalGrammarSymbol('S'),
  productions: [
    PhraseStructureProduction(
      id: 'context-rule',
      order: 0,
      left: GrammarSymbolSequence(const [
        TerminalGrammarSymbol('a,b'),
        NonterminalGrammarSymbol('Context'),
      ]),
      right: GrammarSymbolSequence(const [
        NonterminalGrammarSymbol('Context'),
        TerminalGrammarSymbol('🙂'),
      ]),
    ),
    PhraseStructureProduction(
      id: 'start-rule',
      order: 1,
      left: GrammarSymbolSequence(const [NonterminalGrammarSymbol('S')]),
      right: GrammarSymbolSequence(const [
        TerminalGrammarSymbol('a,b'),
        NonterminalGrammarSymbol('Context'),
      ]),
    ),
  ],
);

String _jflap(String productions) =>
    '''
<?xml version="1.0" encoding="UTF-8"?>
<structure>
  <type>grammar</type>
  $productions
</structure>
''';

DocumentPayload _payload(String value) =>
    DocumentPayload(bytes: Uint8List.fromList(utf8.encode(value)));
