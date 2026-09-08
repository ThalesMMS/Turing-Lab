import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:turing_lab/core/interoperability/interoperability.dart';
import 'package:turing_lab/data/codecs/tm_jflap_document_codec.dart';
import 'package:turing_lab/l10n/app_localizations_en.dart';
import 'package:turing_lab/l10n/app_localizations_pt.dart';
import 'package:turing_lab/l10n/app_localizations_structured_messages.dart';

void main() {
  for (final nested in [false, true]) {
    test(
      'duplicate block identity names its ID and both tags (nested: $nested)',
      () {
        const leaf =
            '<state id="0" name="q0"><x>0</x><y>0</y><initial/><final/></state>';
        const child =
            '<block id="0" name="Second"><x>0</x><y>0</y><initial/><final/><tag>second</tag></block>';
        final result = _decode('''
<structure><type>turing</type><automaton>
  <block id="0" name="First"><x>0</x><y>0</y><initial/><tag>first</tag></block>
  <block id="1" name="Second"><x>100</x><y>0</y><final/><tag>second</tag></block>
  <first turingLabBlockId="shared">${nested ? child : leaf}</first>
  <second turingLabBlockId="shared">$leaf</second>
</automaton></structure>''');
        expect(result.reason, CodecMalformedReason.duplicateIdentity);
        expect(result.location?.path, '/structure/automaton/second');
        expect(
          result.message,
          'JFLAP blocks first and second reuse block id shared.',
        );
        final message = result.structuredMessage!;
        expect(message.stableCode, 'codec.tm-jflap.duplicate-block-identity');
        expect(
          message.arguments.map((key, value) => MapEntry(key, value.value)),
          {'id': 'shared', 'first-tag': 'first', 'second-tag': 'second'},
        );
        for (final text in [
          AppLocalizationsEn().resolveStructuredMessage(message),
          AppLocalizationsPt().resolveStructuredMessage(message),
        ]) {
          expect(text, isNotNull);
          for (final value in ['shared', 'first', 'second']) {
            expect(text, contains(value));
          }
        }
      },
    );
  }

  test('multiple definitions for one tag retain the ambiguous diagnostic', () {
    final result = _decode('''
<structure><type>turing</type><automaton>
  <block id="0" name="First"><x>0</x><y>0</y><initial/><tag>first</tag></block>
  <first turingLabBlockId="a"/>
  <first turingLabBlockId="b"/>
</automaton></structure>''');
    expect(result.reason, CodecMalformedReason.duplicateIdentity);
    expect(result.message, 'JFLAP block first has ambiguous definitions.');
    expect(
      result.structuredMessage?.stableCode,
      'codec.tm-jflap.ambiguous-block-definition',
    );
  });
}

CodecMalformed<InteroperableDocument<Object>> _decode(String source) =>
    const TmJflapDocumentCodec().decode(
          DocumentPayload(
            bytes: Uint8List.fromList(utf8.encode(source)),
            filename: 'block-identities.jff',
          ),
        )
        as CodecMalformed<InteroperableDocument<Object>>;
