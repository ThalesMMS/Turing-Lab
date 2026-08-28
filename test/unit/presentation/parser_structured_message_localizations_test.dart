import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:turing_lab/core/messages/structured_message.dart';
import 'package:turing_lab/l10n/app_localizations.dart';
import 'package:turing_lab/l10n/app_localizations_structured_messages.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  final en = lookupAppLocalizations(const Locale('en'));
  final pt = lookupAppLocalizations(const Locale('pt'));

  test('every parser code resolves in English and Portuguese', () {
    final messages = [
      for (final code in [
        'malformed-document',
        'missing-grammar-element',
        'missing-start-element',
        'empty-start-element',
      ])
        _grammarMessage(code),
      _grammarMessage(
        'invalid-start-count',
        arguments: {'count': StructuredMessageArgument.count(2)},
      ),
      _grammarMessage(
        'incomplete-production',
        arguments: {
          'index': StructuredMessageArgument.index(0, role: 'production-index'),
        },
      ),
      for (final code in [
        'malformed-document',
        'missing-automaton-element',
        'empty-automaton',
      ])
        _jflapMessage(code),
      _jflapMessage(
        'incomplete-transition',
        arguments: {
          'index': StructuredMessageArgument.index(1, role: 'transition-index'),
        },
      ),
      _jflapMessage(
        'unknown-transition-endpoints',
        arguments: {
          'from': StructuredMessageArgument.identifier(
            'q0',
            role: 'source-state',
          ),
          'to': StructuredMessageArgument.identifier(
            'q9',
            role: 'target-state',
          ),
        },
      ),
      _jflapMessage(
        'unexpected-root-element',
        arguments: {
          'actual': StructuredMessageArgument.identifier(
            'automaton',
            role: 'xml-element',
          ),
        },
      ),
    ];

    for (final message in messages) {
      final english = en.resolveStructuredMessage(message);
      final portuguese = pt.resolveStructuredMessage(message);
      expect(english, isNotEmpty, reason: message.stableCode);
      expect(portuguese, isNotEmpty, reason: message.stableCode);
      expect(english, isNot(portuguese), reason: message.stableCode);
      expect(english, isNot(contains(message.stableCode)));
      expect(portuguese, isNot(contains(message.stableCode)));
    }

    final endpoints = messages[10];
    expect(en.resolveStructuredMessage(endpoints), contains('q0'));
    expect(en.resolveStructuredMessage(endpoints), contains('q9'));
    expect(pt.resolveStructuredMessage(endpoints), contains('q0'));
    expect(pt.resolveStructuredMessage(endpoints), contains('q9'));
  });

  test('missing, extra, wrong-type, and future payloads use safe fallback', () {
    final malformed = [
      _grammarMessage('invalid-start-count'),
      _grammarMessage(
        'invalid-start-count',
        arguments: {
          'count': StructuredMessageArgument.count(2),
          'extra': StructuredMessageArgument.count(1),
        },
      ),
      _grammarMessage(
        'invalid-start-count',
        arguments: {'count': StructuredMessageArgument.integer(2)},
      ),
      _jflapMessage('future-code'),
    ];

    for (final message in malformed) {
      expect(
        en.resolveStructuredMessage(message),
        'Message unavailable (${message.stableCode}).',
      );
      expect(
        pt.resolveStructuredMessage(message),
        'Mensagem indisponível (${message.stableCode}).',
      );
    }
  });
}

StructuredMessage _grammarMessage(
  String code, {
  Map<String, StructuredMessageArgument> arguments = const {},
}) => StructuredMessage(
  namespace: 'parser.grammar-xml',
  code: code,
  category: StructuredMessageCategory.interoperability,
  severity: StructuredMessageSeverity.error,
  arguments: arguments,
);

StructuredMessage _jflapMessage(
  String code, {
  Map<String, StructuredMessageArgument> arguments = const {},
}) => StructuredMessage(
  namespace: 'parser.jflap-xml',
  code: code,
  category: StructuredMessageCategory.interoperability,
  severity: StructuredMessageSeverity.error,
  arguments: arguments,
);
