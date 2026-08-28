import 'package:flutter_test/flutter_test.dart';
import 'package:turing_lab/core/messages/structured_message.dart';
import 'package:turing_lab/core/models/grammar.dart';
import 'package:turing_lab/core/models/production.dart';
import 'package:turing_lab/core/parsers/grammar_xml_codec.dart';

void main() {
  group('GrammarXmlCodec', () {
    const codec = GrammarXmlCodec();

    test('round-trip preserves terminal and nonterminal sets', () {
      final now = DateTime.utc(2024, 1, 1);
      final grammar = Grammar(
        id: 'palindrome',
        name: 'Palindrome',
        terminals: const {'a', 'b'},
        nonterminals: const {'S'},
        startSymbol: 'S',
        productions: {
          const Production(
            id: 'p0',
            leftSide: ['S'],
            rightSide: ['a', 'S', 'b'],
            order: 0,
          ),
          const Production(
            id: 'p1',
            leftSide: ['S'],
            rightSide: [],
            isLambda: true,
            order: 1,
          ),
        },
        type: GrammarType.contextFree,
        created: now,
        modified: now,
      );

      final xml = codec.encodeGrammar(grammar);
      final result = codec.decodeGrammarXml(xml);

      expect(result.isSuccess, isTrue);
      final decoded = result.data!;
      expect(decoded.terminals, equals({'a', 'b'}));
      expect(decoded.nonterminals, equals({'S'}));
      expect(decoded.terminals, isNot(contains('S')));
    });

    test('round-trip preserves grammar type', () {
      final now = DateTime.utc(2024, 1, 1);
      final grammar = Grammar(
        id: 'regular',
        name: 'Regular',
        terminals: const {'a'},
        nonterminals: const {'S'},
        startSymbol: 'S',
        productions: {
          const Production(
            id: 'p0',
            leftSide: ['S'],
            rightSide: ['a'],
            order: 0,
          ),
        },
        type: GrammarType.regular,
        created: now,
        modified: now,
      );

      final xml = codec.encodeGrammar(grammar);
      final result = codec.decodeGrammarXml(xml);

      expect(result.isSuccess, isTrue);
      expect(result.data!.type, equals(GrammarType.regular));
    });

    test('decode includes the start symbol in nonterminals', () {
      const xml = '''<?xml version="1.0" encoding="UTF-8"?>
<structure type="grammar">
  <grammar type="contextFree">
    <start>S</start>
    <production>
      <left>A</left>
      <right>a</right>
    </production>
  </grammar>
</structure>''';

      final result = codec.decodeGrammarXml(xml);

      expect(result.isSuccess, isTrue);
      expect(result.data!.nonterminals, equals({'S', 'A'}));
      expect(result.data!.terminals, equals({'a'}));
    });

    test('returns stable structured failures with typed grammar evidence', () {
      final invalidStart = codec.decodeGrammarXml('''
<structure type="grammar">
  <grammar><start>S T</start></grammar>
</structure>''');
      final incompleteProduction = codec.decodeGrammarXml('''
<structure type="grammar">
  <grammar>
    <start>S</start>
    <production><left>S</left></production>
  </grammar>
</structure>''');

      expect(invalidStart.error, 'parser.grammar-xml.invalid-start-count');
      expect(
        invalidStart.structuredError?.arguments['count'],
        StructuredMessageArgument.count(2),
      );
      expect(
        incompleteProduction.error,
        'parser.grammar-xml.incomplete-production',
      );
      expect(
        incompleteProduction.structuredError?.arguments['index'],
        StructuredMessageArgument.index(0, role: 'production-index'),
      );
    });

    test('structured failures survive persistence without localized prose', () {
      final failure = codec.decodeGrammarXml('<not-xml');
      final message = failure.structuredError!;
      final restored = StructuredMessage.fromJson(message.toJson());

      expect(failure.error, 'parser.grammar-xml.malformed-document');
      expect(restored, message);
      expect(restored.toJson().toString(), isNot(contains('malformed XML')));
    });

    test('uses generated document identity as the imported name', () {
      const xml = '''
<structure type="grammar">
  <grammar><start>S</start></grammar>
</structure>''';

      final grammar = codec.decodeGrammarXml(xml).data!;

      expect(grammar.name, grammar.id);
      expect(grammar.name, startsWith('imported_grammar_'));
    });
  });
}
