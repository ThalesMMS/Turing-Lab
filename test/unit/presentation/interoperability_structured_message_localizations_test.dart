import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:turing_lab/core/messages/structured_message.dart';
import 'package:turing_lab/l10n/app_localizations.dart';
import 'package:turing_lab/l10n/app_localizations_structured_messages.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  final en = lookupAppLocalizations(const Locale('en'));
  final pt = lookupAppLocalizations(const Locale('pt'));

  test('every registry message resolves typed arguments in both locales', () {
    final messages = <StructuredMessage>[
      _message('document-unrecognized'),
      for (final code in [
        'sniff-identity-mismatch',
        'sniff-failed',
        'decoded-identity-mismatch',
        'decode-failed',
        'encoded-metadata-mismatch',
        'encode-failed',
      ])
        _message(
          code,
          arguments: {
            'codec': StructuredMessageArgument.identifier(
              'codec.test',
              role: 'codec',
            ),
          },
        ),
      _message(
        'schema-identity-unregistered',
        arguments: {
          'system': StructuredMessageArgument.identifier(
            'fsa',
            role: 'formal-system',
          ),
          'schema': StructuredMessageArgument.identifier(
            'turing-lab.fsa',
            role: 'schema',
          ),
        },
      ),
      _message(
        'export-route-unavailable',
        arguments: {
          'system': StructuredMessageArgument.identifier(
            'fsa',
            role: 'formal-system',
          ),
          'format': StructuredMessageArgument.identifier(
            'jflap-xml',
            role: 'document-format',
          ),
          'schema-version': StructuredMessageArgument.integer(
            7,
            role: 'schema-version',
          ),
        },
      ),
      _message(
        'export-schema-unavailable',
        arguments: {
          'schema-version': StructuredMessageArgument.integer(
            7,
            role: 'schema-version',
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

      final persisted = message.toJson();
      final restored = StructuredMessage.fromJson(persisted);
      expect(restored, message);
      expect(en.resolveStructuredMessage(restored), english);
      expect(pt.resolveStructuredMessage(restored), portuguese);
    }
  });

  test('unknown code and invalid argument contracts use a safe fallback', () {
    final messages = [
      _message('future-code'),
      _message(
        'encode-failed',
        arguments: {
          'codec': StructuredMessageArgument.literal(
            'codec.test',
            role: 'codec',
          ),
        },
      ),
    ];

    for (final message in messages) {
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

StructuredMessage _message(
  String code, {
  Map<String, StructuredMessageArgument> arguments = const {},
}) => StructuredMessage(
  namespace: 'interop.registry',
  code: code,
  category: StructuredMessageCategory.interoperability,
  severity: StructuredMessageSeverity.error,
  arguments: arguments,
);
